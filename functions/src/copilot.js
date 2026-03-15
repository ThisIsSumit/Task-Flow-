const { onCall, HttpsError } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const logger = require('firebase-functions/logger');

function getDb() {
  return admin.firestore();
}

const GEMINI_API_URL =
  'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';
const OPENAI_API_URL = 'https://api.openai.com/v1/chat/completions';

exports.generateTasksWithAI = onCall(async (request) => {
  const db = getDb();
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError('unauthenticated', 'Authentication required.');
  }

  const instruction = String(request.data?.instruction || '').trim();
  if (!instruction) {
    throw new HttpsError('invalid-argument', 'Instruction is required.');
  }

  const userSnapshot = await db.collection('users').doc(uid).get();
  if (!userSnapshot.exists) {
    throw new HttpsError('not-found', 'User profile not found.');
  }

  const user = userSnapshot.data();
  if (!isPremiumUserActive(user)) {
    return {
      success: false,
      requiresUpgrade: true,
      message:
        'AI Copilot Automation is a premium feature. Upgrade to continue.',
      tasks: [],
    };
  }

  await enforceDailyLimit(uid);

  const prompt = buildPrompt(instruction);
  const aiText = await runAiPrompt(prompt);
  const parsed = parseAiJson(aiText);
  const tasks = sanitizeTaskArray(parsed.tasks || []);

  if (tasks.length === 0) {
    return {
      success: false,
      requiresUpgrade: false,
      message:
        'Copilot could not generate a valid task plan. Try a clearer instruction.',
      tasks: [],
    };
  }

  return {
    success: true,
    requiresUpgrade: false,
    message: 'Plan generated successfully.',
    tasks,
  };
});

function isPremiumUserActive(user) {
  const subscriptionType = String(user?.subscriptionType || 'free');
  if (subscriptionType !== 'premium') {
    return false;
  }

  const endRaw = user?.subscriptionEndDate;
  if (!endRaw) {
    return true;
  }

  const endDate =
    typeof endRaw.toDate === 'function' ? endRaw.toDate() : new Date(endRaw);

  if (Number.isNaN(endDate.getTime())) {
    return false;
  }

  return endDate >= new Date();
}

async function enforceDailyLimit(uid) {
  const db = getDb();
  const today = new Date();
  const dayKey = `${today.getUTCFullYear()}-${String(today.getUTCMonth() + 1).padStart(2, '0')}-${String(today.getUTCDate()).padStart(2, '0')}`;
  const limit = Number(process.env.COPILOT_DAILY_LIMIT || 20);

  const usageRef = db
    .collection('users')
    .doc(uid)
    .collection('usage')
    .doc('copilot_daily');

  await db.runTransaction(async (transaction) => {
    const usageSnapshot = await transaction.get(usageRef);
    const data = usageSnapshot.exists ? usageSnapshot.data() : {};
    const lastDay = String(data?.dayKey || '');
    const currentCount = Number(data?.count || 0);

    const nextCount = lastDay === dayKey ? currentCount + 1 : 1;
    if (nextCount > limit) {
      throw new HttpsError(
        'resource-exhausted',
        `Daily AI Copilot limit reached (${limit}). Try again tomorrow.`,
      );
    }

    transaction.set(
      usageRef,
      {
        dayKey,
        count: nextCount,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });
}

function buildPrompt(instruction) {
  return [
    'You are a productivity assistant for TaskFlow.',
    'Convert user instruction into structured task data.',
    'Return JSON only. No markdown and no explanation.',
    'Output format:',
    '{"tasks":[{"title":"","description":"","deadline":"ISO-8601 datetime","repeat":"none|daily|weekly|monthly","reminderMinutesBefore":30,"subtasks":[""],"automation":{"enabled":true,"executionType":"email|report|message|meeting","triggerBeforeDeadline":10,"config":{}}}] }',
    'Rules:',
    '- Include 1..5 tasks only.',
    '- deadline should be realistic and explicit.',
    '- reminderMinutesBefore must be integer 5..1440.',
    '- triggerBeforeDeadline must be integer 1..180.',
    '- Use executionType=email for cases like "email if incomplete".',
    '- For meeting automation include meetingTitle and participants in config.',
    `Instruction: ${instruction}`,
  ].join('\n');
}

async function runAiPrompt(prompt) {
  const provider = String(process.env.AI_PROVIDER || 'gemini').toLowerCase();
  if (provider === 'openai') {
    return runOpenAiPrompt(prompt);
  }

  return runGeminiPrompt(prompt);
}

async function runGeminiPrompt(prompt) {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    throw new HttpsError(
      'failed-precondition',
      'Missing GEMINI_API_KEY for AI Copilot.',
    );
  }

  const response = await fetch(`${GEMINI_API_URL}?key=${encodeURIComponent(apiKey)}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      contents: [{ role: 'user', parts: [{ text: prompt }] }],
      generationConfig: { temperature: 0.2 },
    }),
  });

  if (!response.ok) {
    logger.error('Gemini request failed', { status: response.status });
    throw new HttpsError('internal', 'AI provider request failed.');
  }

  const data = await response.json();
  const text =
    data?.candidates?.[0]?.content?.parts
      ?.map((item) => item?.text || '')
      .join('')
      .trim() || '';

  if (!text) {
    throw new HttpsError('internal', 'AI provider returned empty response.');
  }

  return text;
}

async function runOpenAiPrompt(prompt) {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    throw new HttpsError(
      'failed-precondition',
      'Missing OPENAI_API_KEY for AI Copilot.',
    );
  }

  const response = await fetch(OPENAI_API_URL, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: process.env.OPENAI_MODEL || 'gpt-4o-mini',
      temperature: 0.2,
      messages: [{ role: 'user', content: prompt }],
    }),
  });

  if (!response.ok) {
    logger.error('OpenAI request failed', { status: response.status });
    throw new HttpsError('internal', 'AI provider request failed.');
  }

  const data = await response.json();
  const text = data?.choices?.[0]?.message?.content?.trim() || '';
  if (!text) {
    throw new HttpsError('internal', 'AI provider returned empty response.');
  }

  return text;
}

function parseAiJson(text) {
  const cleaned = text.replaceAll(/```json|```/gi, '').trim();
  try {
    return JSON.parse(cleaned);
  } catch (parseError) {
    const first = cleaned.indexOf('{');
    const last = cleaned.lastIndexOf('}');
    if (first >= 0 && last > first) {
      try {
        return JSON.parse(cleaned.slice(first, last + 1));
      } catch (fallbackError) {
        logger.error('AI JSON parsing failed after fallback', {
          parseError: parseError instanceof Error ? parseError.message : String(parseError),
          fallbackError:
            fallbackError instanceof Error ? fallbackError.message : String(fallbackError),
        });
      }
    }
    throw new HttpsError('internal', 'AI JSON parsing failed.');
  }
}

function sanitizeTaskArray(items) {
  if (!Array.isArray(items)) {
    return [];
  }

  return items
    .map((item) => sanitizeTask(item))
    .filter((item) => item.title.length > 0);
}

function sanitizeTask(item) {
  const map = item && typeof item === 'object' ? item : {};
  const automation =
    map.automation && typeof map.automation === 'object' ? map.automation : {};
  const config =
    automation.config && typeof automation.config === 'object'
      ? automation.config
      : {};

  const reminderMinutesBefore = clampInt(map.reminderMinutesBefore, 30, 5, 1440);
  const triggerBeforeDeadline = clampInt(
    automation.triggerBeforeDeadline,
    10,
    1,
    180,
  );

  return {
    title: String(map.title || '').trim(),
    description: String(map.description || '').trim(),
    deadline: String(map.deadline || '').trim(),
    repeat: normalizeRepeat(map.repeat),
    reminderMinutesBefore,
    subtasks: Array.isArray(map.subtasks)
      ? map.subtasks.map((x) => String(x || '').trim()).filter(Boolean)
      : [],
    automation: {
      enabled: automation.enabled === true,
      executionType: normalizeExecutionType(automation.executionType),
      triggerBeforeDeadline,
      config: sanitizeConfig(config),
    },
  };
}

function clampInt(value, fallback, min, max) {
  const n = Number(value);
  if (!Number.isFinite(n)) {
    return fallback;
  }
  return Math.max(min, Math.min(max, Math.round(n)));
}

function normalizeRepeat(value) {
  const normalized = String(value || 'none').toLowerCase();
  if (['daily', 'weekly', 'monthly'].includes(normalized)) {
    return normalized;
  }
  return 'none';
}

function normalizeExecutionType(value) {
  const normalized = String(value || 'email').toLowerCase();
  if (['email', 'report', 'message', 'meeting'].includes(normalized)) {
    return normalized;
  }
  return 'email';
}

function sanitizeConfig(config) {
  const output = {};
  for (const [key, value] of Object.entries(config)) {
    if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean') {
      output[key] = value;
    } else if (Array.isArray(value)) {
      output[key] = value.map(String);
    }
  }
  return output;
}
