import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';

class LocalCacheService extends GetxService {
  static const String _tasksKeyPrefix = 'cached_tasks_';

  Future<void> saveTasks(String userId, List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = tasks.map(_taskToCacheMap).toList();
    await prefs.setString('$_tasksKeyPrefix$userId', jsonEncode(payload));
  }

  Future<List<Task>> readTasks(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_tasksKeyPrefix$userId');
    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .whereType<Map>()
        .map(
          (item) =>
              Task.fromMap(_cacheMapToTaskMap(Map<String, dynamic>.from(item))),
        )
        .toList();
  }

  Map<String, dynamic> _taskToCacheMap(Task task) {
    return {
      'id': task.id,
      'title': task.title,
      'description': task.description,
      'category': task.category,
      'priority': task.priority,
      'dueDate': task.dueDate.toIso8601String(),
      'isCompleted': task.isCompleted,
      'completedAt': task.completedAt?.toIso8601String(),
      'createdAt': task.createdAt.toIso8601String(),
      'userId': task.userId,
      'notes': task.notes,
      'reminderEnabled': task.reminderEnabled,
      'reminderAt': task.reminderAt?.toIso8601String(),
      'recurrence': task.recurrence.name,
      'lastRecurrenceAt': task.lastRecurrenceAt?.toIso8601String(),
      'autoExecute': task.autoExecute,
      'executionType': task.executionType.name,
      'recipient': task.recipient,
      'automationInstruction': task.automationInstruction,
      'automationMode': task.automationMode.name,
      'triggerBeforeDeadline': task.triggerBeforeDeadline,
      'automationStatus': task.automationStatus.name,
      'automationLastExecutedAt':
          task.automationLastExecutedAt?.toIso8601String(),
      'generatedAutomationSummary': task.generatedAutomationSummary,
      'generatedAutomationContent': task.generatedAutomationContent,
      'subtasks':
          task.subtasks
              .map(
                (item) => {
                  'id': item.id,
                  'title': item.title,
                  'isDone': item.isDone,
                },
              )
              .toList(),
    };
  }

  Map<String, dynamic> _cacheMapToTaskMap(Map<String, dynamic> map) {
    DateTime? parseDate(String? value) {
      if (value == null || value.isEmpty) {
        return null;
      }
      return DateTime.tryParse(value);
    }

    return {
      ...map,
      'dueDate': parseDate(map['dueDate']) ?? DateTime.now(),
      'completedAt': parseDate(map['completedAt']),
      'createdAt': parseDate(map['createdAt']) ?? DateTime.now(),
      'reminderAt': parseDate(map['reminderAt']),
      'lastRecurrenceAt': parseDate(map['lastRecurrenceAt']),
      'automationLastExecutedAt': parseDate(map['automationLastExecutedAt']),
    };
  }
}
