import 'package:cloud_firestore/cloud_firestore.dart';

enum RecurrenceType { none, daily, weekly, monthly }

enum AutomationMode { suggest, execute }

enum AutomationStatus { enabled, disabled }

enum AutomationExecutionType { email, report, message, meeting }

const Object _taskNoChange = Object();

class SubTask {
  final String id;
  final String title;
  final bool isDone;

  SubTask({required this.id, required this.title, this.isDone = false});

  SubTask copyWith({String? id, String? title, bool? isDone}) {
    return SubTask(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'isDone': isDone};
  }

  factory SubTask.fromMap(Map<String, dynamic> map) {
    return SubTask(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      isDone: map['isDone'] ?? false,
    );
  }
}

class Task {
  final String id;
  final String title;
  final String description;
  final String category;
  final int priority;
  final DateTime dueDate;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final String userId;
  final String notes;
  final bool reminderEnabled;
  final DateTime? reminderAt;
  final RecurrenceType recurrence;
  final DateTime? lastRecurrenceAt;
  final List<SubTask> subtasks;
  final bool autoExecute;
  final AutomationExecutionType executionType;
  final String recipient;
  final String automationInstruction;
  final AutomationMode automationMode;
  final int triggerBeforeDeadline;
  final AutomationStatus automationStatus;
  final DateTime? automationLastExecutedAt;
  final String generatedAutomationSummary;
  final String generatedAutomationContent;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.dueDate,
    required this.isCompleted,
    this.completedAt,
    required this.createdAt,
    required this.userId,
    this.notes = '',
    this.reminderEnabled = false,
    this.reminderAt,
    this.recurrence = RecurrenceType.none,
    this.lastRecurrenceAt,
    this.subtasks = const [],
    this.autoExecute = false,
    this.executionType = AutomationExecutionType.email,
    this.recipient = '',
    this.automationInstruction = '',
    this.automationMode = AutomationMode.execute,
    this.triggerBeforeDeadline = 10,
    this.automationStatus = AutomationStatus.disabled,
    this.automationLastExecutedAt,
    this.generatedAutomationSummary = '',
    this.generatedAutomationContent = '',
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    int? priority,
    DateTime? dueDate,
    bool? isCompleted,
    Object? completedAt = _taskNoChange,
    DateTime? createdAt,
    String? userId,
    String? notes,
    bool? reminderEnabled,
    Object? reminderAt = _taskNoChange,
    RecurrenceType? recurrence,
    Object? lastRecurrenceAt = _taskNoChange,
    List<SubTask>? subtasks,
    bool? autoExecute,
    AutomationExecutionType? executionType,
    String? recipient,
    String? automationInstruction,
    AutomationMode? automationMode,
    int? triggerBeforeDeadline,
    AutomationStatus? automationStatus,
    Object? automationLastExecutedAt = _taskNoChange,
    String? generatedAutomationSummary,
    String? generatedAutomationContent,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt:
          identical(completedAt, _taskNoChange)
              ? this.completedAt
              : completedAt as DateTime?,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      notes: notes ?? this.notes,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderAt:
          identical(reminderAt, _taskNoChange)
              ? this.reminderAt
              : reminderAt as DateTime?,
      recurrence: recurrence ?? this.recurrence,
      lastRecurrenceAt:
          identical(lastRecurrenceAt, _taskNoChange)
              ? this.lastRecurrenceAt
              : lastRecurrenceAt as DateTime?,
      subtasks: subtasks ?? this.subtasks,
      autoExecute: autoExecute ?? this.autoExecute,
      executionType: executionType ?? this.executionType,
      recipient: recipient ?? this.recipient,
      automationInstruction:
          automationInstruction ?? this.automationInstruction,
      automationMode: automationMode ?? this.automationMode,
      triggerBeforeDeadline:
          triggerBeforeDeadline ?? this.triggerBeforeDeadline,
      automationStatus: automationStatus ?? this.automationStatus,
      automationLastExecutedAt:
          identical(automationLastExecutedAt, _taskNoChange)
              ? this.automationLastExecutedAt
              : automationLastExecutedAt as DateTime?,
      generatedAutomationSummary:
          generatedAutomationSummary ?? this.generatedAutomationSummary,
      generatedAutomationContent:
          generatedAutomationContent ?? this.generatedAutomationContent,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'dueDate': Timestamp.fromDate(dueDate),
      'isCompleted': isCompleted,
      'status': isCompleted ? 'completed' : 'pending',
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
      'notes': notes,
      'reminderEnabled': reminderEnabled,
      'reminderAt': reminderAt != null ? Timestamp.fromDate(reminderAt!) : null,
      'recurrence': recurrence.name,
      'lastRecurrenceAt':
          lastRecurrenceAt != null
              ? Timestamp.fromDate(lastRecurrenceAt!)
              : null,
      'subtasks': subtasks.map((item) => item.toMap()).toList(),
      'autoExecute': autoExecute,
      'executionType': executionType.name,
      'recipient': recipient,
      'automationInstruction': automationInstruction,
      'automationMode': automationMode.name,
      'triggerBeforeDeadline': triggerBeforeDeadline,
      'automationStatus': automationStatus.name,
      'automationLastExecutedAt':
          automationLastExecutedAt != null
              ? Timestamp.fromDate(automationLastExecutedAt!)
              : null,
      'generatedAutomationSummary': generatedAutomationSummary,
      'generatedAutomationContent': generatedAutomationContent,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is DateTime) {
        return value;
      }
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic value) {
      if (value == null) {
        return null;
      }
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is DateTime) {
        return value;
      }
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return Task(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      priority: map['priority'] ?? 2,
      dueDate: parseDate(map['dueDate']),
      isCompleted: map['isCompleted'] ?? (map['status'] == 'completed'),
      completedAt: parseNullableDate(map['completedAt']),
      createdAt: parseDate(map['createdAt']),
      userId: map['userId'] ?? '',
      notes: map['notes'] ?? '',
      reminderEnabled: map['reminderEnabled'] ?? false,
      reminderAt: parseNullableDate(map['reminderAt']),
      recurrence: RecurrenceType.values.firstWhere(
        (value) => value.name == map['recurrence'],
        orElse: () => RecurrenceType.none,
      ),
      lastRecurrenceAt: parseNullableDate(map['lastRecurrenceAt']),
      subtasks:
          ((map['subtasks'] as List?) ?? [])
              .whereType<Map>()
              .map((item) => SubTask.fromMap(Map<String, dynamic>.from(item)))
              .toList(),
      autoExecute: map['autoExecute'] ?? false,
      executionType: AutomationExecutionType.values.firstWhere(
        (value) =>
            value.name == map['executionType'] ||
            (map['executionType'] == 'notification' &&
                value == AutomationExecutionType.meeting),
        orElse: () => AutomationExecutionType.email,
      ),
      recipient: (map['recipient'] ?? '').toString(),
      automationInstruction: (map['automationInstruction'] ?? '').toString(),
      automationMode: AutomationMode.values.firstWhere(
        (value) => value.name == map['automationMode'],
        orElse: () => AutomationMode.execute,
      ),
      triggerBeforeDeadline: map['triggerBeforeDeadline'] ?? 10,
      automationStatus: AutomationStatus.values.firstWhere(
        (value) => value.name == map['automationStatus'],
        orElse: () => AutomationStatus.disabled,
      ),
      automationLastExecutedAt: parseNullableDate(
        map['automationLastExecutedAt'],
      ),
      generatedAutomationSummary:
          (map['generatedAutomationSummary'] ?? '').toString(),
      generatedAutomationContent:
          (map['generatedAutomationContent'] ?? '').toString(),
    );
  }
}
