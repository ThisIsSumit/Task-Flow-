const admin = require('firebase-admin');
const nodemailer = require('nodemailer');
const {
  buildEmailTemplate,
  buildMeetingContent,
  buildMeetingNotificationPayload,
  buildMessageContent,
  buildReportContent,
} = require('./templates');

const GEMINI_API_URL =
  'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

async function executeAutomationAction(task, user) {
  switch (task.executionType) {
    case 'email':
      return executeEmailAutomation(task, user);
    case 'report':
      return executeReportAutomation(task);
    case 'message':
      return executeMessageAutomation(task, user);
    case 'meeting':
    case 'notification':
      return executeMeetingAutomation(task, user);
    default:
      return {
        executionType: task.executionType,
        generatedContent: `Unsupported execution type: ${task.executionType}`,
      };
  }
}

async function executeEmailAutomation(task, user) {
  const template = buildEmailTemplate(task);
  const generatedBody = await maybeGenerateAiContent(task, 'email', template.body);
  const to = resolveRecipient(task, user);

  if (!to) {
    throw new Error('No email recipient available for automation email action');
  }

  await sendEmail(to, template.subject, generatedBody);

  return {
    executionType: 'email',
    generatedContent: generatedBody,
  };
}

async function executeReportAutomation(task) {
  const content = await maybeGenerateAiContent(
    task,
    'report',
    buildReportContent(task),
  );

  return {
    executionType: 'report',
    generatedContent: content,
  };
}

async function executeMessageAutomation(task, user) {
  const content = await maybeGenerateAiContent(
    task,
    'message',
    buildMessageContent(task, user),
  );

  return {
    executionType: 'message',
    generatedContent: content,
  };
}

async function executeMeetingAutomation(task, user) {
  const generatedContent = await maybeGenerateAiContent(
    task,
    'meeting',
    buildMeetingContent(task),
  );
  const payload = buildMeetingNotificationPayload(task);
  const token = resolvePushToken(task, user);

  if (!token) {
    return {
      executionType: 'meeting',
      generatedContent,
    };
  }

  await admin.messaging().send({
    token,
    notification: payload,
    data: {
      taskId: task.id,
      executionType: 'meeting',
    },
  });

  return {
    executionType: 'meeting',
    generatedContent,
  };
}

function resolveRecipient(task, user) {
  const direct = String(task.recipient || '').trim();
  if (direct) {
    return direct;
  }

  const userEmail = String(user?.email || '').trim();
  return userEmail || null;
}

function resolvePushToken(task, user) {
  const fromTask = String(task.recipient || '').trim();
  const fromUser = String(user?.fcmToken || user?.deviceToken || '').trim();

  return fromTask || fromUser || null;
}

async function maybeGenerateAiContent(task, kind, fallback) {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    return fallback;
  }

  try {
    const prompt = [
      'You are writing concise automation output for Task Flow.',
      `Action kind: ${kind}`,
      `Task title: ${task.title}`,
      `Task description: ${task.description || 'None'}`,
      `Task deadline: ${task.dueDate?.toISOString?.() || ''}`,
      'Return plain text only. No markdown.',
    ].join('\n');

    const body = {
      contents: [{ role: 'user', parts: [{ text: prompt }] }],
      generationConfig: {
        temperature: 0.2,
      },
    };

    const response = await fetch(
      `${GEMINI_API_URL}?key=${encodeURIComponent(apiKey)}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      },
    );

    if (!response.ok) {
      return fallback;
    }

    const data = await response.json();
    const text =
      data?.candidates?.[0]?.content?.parts
        ?.map((part) => part?.text || '')
        .join('')
        .trim() || '';

    return text || fallback;
  } catch (_) {
    return fallback;
  }
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
    throw new Error(`Missing email configuration: ${missing.join(', ')}`);
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
