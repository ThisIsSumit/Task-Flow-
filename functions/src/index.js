const admin = require('firebase-admin');
const logger = require('firebase-functions/logger');
const { onSchedule } = require('firebase-functions/v2/scheduler');
require('dotenv').config();

const { executeAutomationAction } = require('./executors');

admin.initializeApp();

const db = admin.firestore();

exports.runTaskAutomation = onSchedule(
  {
    schedule: 'every 5 minutes',
    timeZone: 'UTC',
  },
  async () => {
    const now = new Date();
    logger.info('Running Task Flow automation sweep', {
      timestamp: now.toISOString(),
    });

    const tasksSnapshot = await db
      .collectionGroup('tasks')
      .where('autoExecute', '==', true)
      .where('status', '==', 'pending')
      .get();

    for (const taskDoc of tasksSnapshot.docs) {
      await processTask(taskDoc, now);
    }
  },
);

async function processTask(taskDoc, now) {
  const task = normalizeTask(taskDoc);
  if (!task.userId || !task.dueDate) {
    return;
  }

  if (task.isCompleted || task.status === 'completed') {
    return;
  }

  const triggerAt = new Date(
    task.dueDate.getTime() - task.triggerBeforeDeadline * 60 * 1000,
  );

  if (now < triggerAt) {
    return;
  }

  const userRef = db.collection('users').doc(task.userId);
  const userSnapshot = await userRef.get();
  if (!userSnapshot.exists) {
    await writeAutomationLog(task, {
      status: 'failed',
      generatedContent: 'User record not found',
    });
    await disableAutomation(taskDoc.ref);
    return;
  }

  const user = userSnapshot.data();

  try {
    const result = await executeAutomationAction(task, user);

    await completeTaskAutomation(taskDoc.ref, result);
    await writeAutomationLog(task, {
      status: 'success',
      generatedContent: result.generatedContent,
    });
  } catch (error) {
    logger.error('Task automation failed', {
      taskId: task.id,
      error: error instanceof Error ? error.message : String(error),
    });

    await disableAutomation(taskDoc.ref);
    await writeAutomationLog(task, {
      status: 'failed',
      generatedContent:
        error instanceof Error ? error.message : String(error),
    });
  }
}

function normalizeTask(taskDoc) {
  const data = taskDoc.data();

  return {
    id: taskDoc.id,
    userId: data.userId,
    title: String(data.title || ''),
    description: String(data.description || ''),
    dueDate:
      data.dueDate && typeof data.dueDate.toDate === 'function'
        ? data.dueDate.toDate()
        : null,
    isCompleted: Boolean(data.isCompleted),
    status: String(data.status || 'pending'),
    autoExecute: Boolean(data.autoExecute),
    executionType: String(data.executionType || 'email'),
    triggerBeforeDeadline: Number(data.triggerBeforeDeadline || 10),
    recipient: String(data.recipient || ''),
  };
}

async function completeTaskAutomation(taskRef, result) {
  await taskRef.set(
    {
      autoExecute: false,
      automationStatus: 'disabled',
      automationLastExecutedAt: admin.firestore.FieldValue.serverTimestamp(),
      generatedAutomationContent: result.generatedContent || '',
      generatedAutomationSummary: `${result.executionType || 'automation'} executed`,
      status: 'completed',
      isCompleted: true,
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

async function disableAutomation(taskRef) {
  await taskRef.set(
    {
      autoExecute: false,
      automationStatus: 'disabled',
      automationLastExecutedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

async function writeAutomationLog(task, result) {
  await db.collection('automation_logs').add({
    taskId: task.id,
    userId: task.userId,
    executionType: task.executionType,
    generatedContent: result.generatedContent || '',
    executionTime: admin.firestore.FieldValue.serverTimestamp(),
    status: result.status,
  });
}
