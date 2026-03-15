function buildEmailTemplate(task) {
  return {
    subject: 'Task Update',
    body: [
      `This is an automated message regarding the task "${task.title}".`,
      '',
      'The report has been generated automatically.',
    ].join('\n'),
  };
}

function buildReportContent(task) {
  return [
    'Task Report',
    '',
    `Task: ${task.title}`,
    `Status: ${task.status || 'pending'}`,
    `Deadline: ${task.dueDate.toISOString()}`,
    '',
    'Summary generated automatically.',
  ].join('\n');
}

function buildMessageContent(task) {
  return `Automated task update: "${task.title}" is still pending and reached its trigger window.`;
}

function buildNotificationPayload(task) {
  return {
    title: 'Task Flow Reminder',
    body: `Task "${task.title}" is still pending and automation was triggered.`,
  };
}

module.exports = {
  buildEmailTemplate,
  buildMessageContent,
  buildNotificationPayload,
  buildReportContent,
};