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
      .where('automationStatus', '==', 'enabled')
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

  if (task.isCompleted || task.status == 'completed') {
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
    await writeAutomationLog(task, 'failed', 'User record not found');
    await disableAutomation(taskDoc.ref);
    return;
  }

  const user = userSnapshot.data();
  if (!isPremiumActive(user, now)) {
    logger.info('Skipping non-premium task automation', { taskId: task.id });
    return;
  }

  try {
    const result = await executeAutomationAction(task, user);
    await completeTaskAutomation(taskDoc.ref, result);
    await writeAutomationLog(task, 'success', result);
  } catch (error) {
    logger.error('Task automation failed', {
      taskId: task.id,
      error: error instanceof Error ? error.message : String(error),
    });
    await disableAutomation(taskDoc.ref);
    await writeAutomationLog(task, 'failed', {
      actionType: 'error',
      generatedContent: error.message || String(error),
      summary: 'Automation execution failed.',
      shouldMarkComplete: false,
    });
  }
}

function normalizeTask(taskDoc) {
  const data = taskDoc.data();

  return {
    id: taskDoc.id,
    userId: data.userId,
    title: data.title || '',
    description: data.description || '',
    notes: data.notes || '',
    isCompleted: Boolean(data.isCompleted),
    status: data.status || 'pending',
    dueDate:
      data.dueDate && typeof data.dueDate.toDate === 'function'
        ? data.dueDate.toDate()
        : null,
    triggerBeforeDeadline: Number(data.triggerBeforeDeadline || 0),
    automationInstruction: String(data.automationInstruction || ''),
    automationMode: data.automationMode === 'suggest' ? 'suggest' : 'execute',
  };
}

function isPremiumActive(user, now) {
  if (user?.subscriptionType !== 'premium') {
    return false;
  }

  if (!user?.subscriptionEndDate) {
    return true;
  }

  const endDate =
    typeof user.subscriptionEndDate?.toDate === 'function'
      ? user.subscriptionEndDate.toDate()
      : new Date(user.subscriptionEndDate);

  return endDate > now;
}

async function completeTaskAutomation(taskRef, result) {
  const update = {
    autoExecute: false,
    automationStatus: 'disabled',
    automationLastExecutedAt: admin.firestore.FieldValue.serverTimestamp(),
    generatedAutomationContent: result.generatedContent,
    generatedAutomationSummary: result.summary,
  };

  if (result.shouldMarkComplete) {
    update.isCompleted = true;
    update.status = 'completed';
    update.completedAt = admin.firestore.FieldValue.serverTimestamp();
  }

  await taskRef.set(update, { merge: true });
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

async function writeAutomationLog(task, status, result) {
  await db.collection('automation_logs').add({
    taskId: task.id,
    userId: task.userId,
    actionType: result.actionType || 'note',
    generatedContent: result.generatedContent || '',
    summary: result.summary || '',
    mode: task.automationMode || 'execute',
    executionTime: admin.firestore.FieldValue.serverTimestamp(),
    status,
  });
}