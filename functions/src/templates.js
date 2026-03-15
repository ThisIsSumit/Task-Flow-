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

function buildMeetingContent(task) {
  const encodedTitle = encodeURIComponent(`Task Flow: ${task.title}`);
  const encodedDescription = encodeURIComponent(
    `Auto-scheduled from Task Flow automation.\n\nTask: ${task.title}\nDescription: ${task.description || 'N/A'}`,
  );
  const start = new Date(task.dueDate.getTime() + 5 * 60 * 1000);
  const end = new Date(start.getTime() + 30 * 60 * 1000);
  const startUtc = start.toISOString().replace(/[-:]|\.\d{3}/g, '');
  const endUtc = end.toISOString().replace(/[-:]|\.\d{3}/g, '');

  const meetingLink =
    `https://calendar.google.com/calendar/render?action=TEMPLATE` +
    `&text=${encodedTitle}` +
    `&details=${encodedDescription}` +
    `&dates=${startUtc}/${endUtc}`;

  return [
    `Meeting auto-scheduled for task \"${task.title}\".`,
    `Suggested link: ${meetingLink}`,
  ].join('\n');
}

function buildMeetingNotificationPayload(task) {
  return {
    title: 'Task Flow Meeting Scheduled',
    body: `A meeting link was generated for task "${task.title}".`,
  };
}

module.exports = {
  buildEmailTemplate,
  buildMeetingContent,
  buildMeetingNotificationPayload,
  buildMessageContent,
  buildReportContent,
};