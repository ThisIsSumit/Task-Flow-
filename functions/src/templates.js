function buildReportContent(task, user) {
  return [
    `Automation Report`,
    `Task: ${task.title}`,
    `Owner: ${user.name || user.email || task.userId}`,
    `Deadline: ${task.dueDate.toISOString()}`,
    `Summary: ${task.description || 'No description provided.'}`,
    `Notes: ${task.notes || 'No notes added.'}`,
  ].join('\n');
}

function buildMessageContent(task, user) {
  return `Automated message for ${user.name || user.email || task.userId}: "${task.title}" reached its automation trigger and was processed by Task Flow.`;
}

function buildMeetingLink(task) {
  const endDate = new Date(task.dueDate.getTime() + 30 * 60 * 1000);
  const params = new URLSearchParams({
    action: 'TEMPLATE',
    text: `Automation: ${task.title}`,
    details: task.description || 'Scheduled automatically by Task Flow.',
    dates: `${formatCalendarDate(task.dueDate)}/${formatCalendarDate(endDate)}`,
  });

  return `https://calendar.google.com/calendar/render?${params.toString()}`;
}

function formatCalendarDate(value) {
  return value.toISOString().replace(/[-:]/g, '').split('.')[0] + 'Z';
}

module.exports = {
  buildMeetingLink,
  buildMessageContent,
  buildReportContent,
};