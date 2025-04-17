import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

  // Create a copy of the task with the specified fields updated
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
    );
  }

  // Convert Task to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'dueDate': Timestamp.fromDate(dueDate),
      'isCompleted': isCompleted,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
    };
  }

  // Create Task from Firestore document
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      priority: map['priority'] ?? 2,
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      isCompleted: map['isCompleted'] ?? false,
      completedAt: map['completedAt'] != null 
          ? (map['completedAt'] as Timestamp).toDate() 
          : null,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      userId: map['userId'] ?? '',
    );
  }
}