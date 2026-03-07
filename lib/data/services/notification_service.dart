import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/task_model.dart';

class NotificationService extends GetxService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
  }

  Future<void> scheduleReminder(Task task) async {
    if (!task.reminderEnabled || task.reminderAt == null) {
      return;
    }

    final scheduledAt = task.reminderAt!;
    if (scheduledAt.isBefore(DateTime.now())) {
      return;
    }

    await _plugin.zonedSchedule(
      task.id.hashCode,
      'Task Reminder',
      task.title,
      tz.TZDateTime.from(scheduledAt, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'taskflow_reminders',
          'Task reminders',
          channelDescription: 'Task due and reminder notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelReminder(Task task) async {
    await _plugin.cancel(task.id.hashCode);
  }

  Future<void> showOverdue(List<Task> tasks) async {
    final overdue =
        tasks
            .where(
              (task) =>
                  !task.isCompleted && task.dueDate.isBefore(DateTime.now()),
            )
            .toList();

    if (overdue.isEmpty) {
      return;
    }

    await _plugin.show(
      999999,
      'Overdue tasks',
      'You have ${overdue.length} overdue task(s).',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'taskflow_overdue',
          'Overdue tasks',
          channelDescription: 'Notifications for overdue tasks',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
