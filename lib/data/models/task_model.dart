import 'package:cloud_firestore/cloud_firestore.dart';

enum RecurrenceType { none, daily, weekly, monthly }

enum AttachmentType { image, file, link }

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

class TaskAttachment {
  final String id;
  final String label;
  final String url;
  final AttachmentType type;

  TaskAttachment({
    required this.id,
    required this.label,
    required this.url,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'label': label, 'url': url, 'type': type.name};
  }

  factory TaskAttachment.fromMap(Map<String, dynamic> map) {
    return TaskAttachment(
      id: map['id'] ?? '',
      label: map['label'] ?? '',
      url: map['url'] ?? '',
      type: AttachmentType.values.firstWhere(
        (value) => value.name == map['type'],
        orElse: () => AttachmentType.link,
      ),
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
  final List<TaskAttachment> attachments;

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
    this.attachments = const [],
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    int? priority,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? createdAt,
    String? userId,
    String? notes,
    bool? reminderEnabled,
    DateTime? reminderAt,
    RecurrenceType? recurrence,
    DateTime? lastRecurrenceAt,
    List<SubTask>? subtasks,
    List<TaskAttachment>? attachments,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      notes: notes ?? this.notes,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderAt: reminderAt ?? this.reminderAt,
      recurrence: recurrence ?? this.recurrence,
      lastRecurrenceAt: lastRecurrenceAt ?? this.lastRecurrenceAt,
      subtasks: subtasks ?? this.subtasks,
      attachments: attachments ?? this.attachments,
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
      'attachments': attachments.map((item) => item.toMap()).toList(),
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
      isCompleted: map['isCompleted'] ?? false,
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
      attachments:
          ((map['attachments'] as List?) ?? [])
              .whereType<Map>()
              .map(
                (item) =>
                    TaskAttachment.fromMap(Map<String, dynamic>.from(item)),
              )
              .toList(),
    );
  }
}
