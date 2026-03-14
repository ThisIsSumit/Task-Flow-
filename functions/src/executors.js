const nodemailer = require('nodemailer');
const { buildMeetingLink, buildMessageContent, buildReportContent } = require('./templates');

const GEMINI_API_URL =
  'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

async function executeAutomationAction(task, user) {
  const result = await runAgent(task, user);

  // In execute mode the agent can perform side-effects (currently email).
  if (task.automationMode === 'execute' && result.actionType === 'email' && user.email) {
    await sendEmail(user.email, result.subject || `Task Flow: ${task.title}`, result.output);
  }

  return {
    actionType: result.actionType,
    generatedContent: result.output,
    shouldMarkComplete: task.automationMode === 'execute',
    summary: result.summary || '',
  };
}

async function runAgent(task, user) {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    throw new Error('Missing GEMINI_API_KEY in environment');
  }

  const fallbackOutput = buildFallbackOutput(task, user);
  const prompt = [
    'You are an automation agent for a task manager app.',
    'Return ONLY valid JSON with this exact shape:',
    '{"actionType":"email|report|message|calendarLink|note","summary":"string","subject":"string","output":"string"}',
    'Keep output concise and practical. No markdown fences.',
    '',
    `Automation mode: ${task.automationMode}`,
    `Task title: ${task.title}`,
    `Task description: ${task.description || 'None'}`,
    `Task notes: ${task.notes || 'None'}`,
    `Task due date: ${task.dueDate?.toISOString?.() || ''}`,
    `User name: ${user?.name || ''}`,
    `User email: ${user?.email || ''}`,
    `User instruction: ${task.automationInstruction || 'No custom instruction provided.'}`,
    '',
    'If you cannot infer a strong action, use actionType="note" and provide helpful output.',
  ].join('\n');

  const body = {
    contents: [{ role: 'user', parts: [{ text: prompt }] }],
    generationConfig: {
      temperature: 0.2,
      responseMimeType: 'application/json',
    },
  };

  const response = await fetch(`${GEMINI_API_URL}?key=${encodeURIComponent(apiKey)}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Gemini request failed (${response.status}): ${text}`);
  }

  const data = await response.json();
  const text =
    data?.candidates?.[0]?.content?.parts
      ?.map((part) => part?.text || '')
      .join('')
      .trim() || '';

  if (!text) {
    return {
      actionType: 'note',
      summary: 'No model output; using fallback content.',
      subject: `Task Flow: ${task.title}`,
      output: fallbackOutput,
    };
  }

  const parsed = parseJsonPayload(text);
  if (!parsed) {
    return {
      actionType: 'note',
      summary: 'Model response was not valid JSON; using fallback content.',
      subject: `Task Flow: ${task.title}`,
      output: fallbackOutput,
    };
  }

  const actionType = normalizeActionType(parsed.actionType);
  const subject = String(parsed.subject || `Task Flow: ${task.title}`);
  let output = String(parsed.output || '').trim();

  if (!output) {
    output = fallbackOutput;
  }

  if (actionType === 'calendarLink' && !isHttpUrl(output)) {
    output = buildMeetingLink(task);
  }

  if (actionType === 'report' && output.length < 20) {
    output = buildReportContent(task, user);
  }

  if (actionType === 'message' && output.length < 20) {
    output = buildMessageContent(task, user);
  }

  return {
    actionType,
    summary: String(parsed.summary || ''),
    subject,
    output,
  };
}

function parseJsonPayload(text) {
  try {
    return JSON.parse(text);
  } catch (_) {
    const start = text.indexOf('{');
    const end = text.lastIndexOf('}');
    if (start === -1 || end === -1 || end <= start) {
      return null;
    }
    try {
      return JSON.parse(text.slice(start, end + 1));
    } catch (_) {
      return null;
    }
  }
}

function normalizeActionType(value) {
  const normalized = String(value || 'note').trim();
  const allowed = new Set(['email', 'report', 'message', 'calendarLink', 'note']);
  return allowed.has(normalized) ? normalized : 'note';
}

function buildFallbackOutput(task, user) {
  return buildReportContent(
    {
      ...task,
      description:
        task.description ||
        `Automation goal: ${task.automationInstruction || 'No explicit goal provided.'}`,
    },
    user,
  );
}

function isHttpUrl(value) {
  return /^https?:\/\//i.test(String(value || '').trim());
}

async function sendEmail(to, subject, text) {
  const transporter = createTransporter();
  await transporter.sendMail({
    from: process.env.EMAIL_FROM,
    to,
    subject,
    text,
  });
}

function createTransporter() {
  const required = [
    'EMAIL_SMTP_HOST',
    'EMAIL_SMTP_PORT',
    'EMAIL_SMTP_USER',
    'EMAIL_SMTP_PASSWORD',
    'EMAIL_FROM',
  ];

  const missing = required.filter((key) => !process.env[key]);
  if (missing.length > 0) {
    throw new Error(
      `Missing email configuration: ${missing.join(', ')}`,
    );
  }

  return nodemailer.createTransport({
    host: process.env.EMAIL_SMTP_HOST,
    port: Number(process.env.EMAIL_SMTP_PORT),
    secure: Number(process.env.EMAIL_SMTP_PORT) === 465,
    auth: {
      user: process.env.EMAIL_SMTP_USER,
      pass: process.env.EMAIL_SMTP_PASSWORD,
    },
  });
}

module.exports = {
  executeAutomationAction,
};