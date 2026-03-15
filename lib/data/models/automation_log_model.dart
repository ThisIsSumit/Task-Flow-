import 'package:cloud_firestore/cloud_firestore.dart';

class AutomationLog {
  final String id;
  final String taskId;
  final String userId;
  final String executionType;
  final String generatedContent;
  final DateTime executionTime;
  final String status;

  const AutomationLog({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.executionType,
    required this.generatedContent,
    required this.executionTime,
    required this.status,
  });

  factory AutomationLog.fromMap(Map<String, dynamic> map) {
    final executionTime = map['executionTime'];

    return AutomationLog(
      id: map['id'] ?? '',
      taskId: map['taskId'] ?? '',
      userId: map['userId'] ?? '',
      executionType:
          (map['executionType'] ?? map['actionType'] ?? '').toString(),
      generatedContent:
          (map['generatedContent'] ?? map['summary'] ?? '').toString(),
      executionTime:
          executionTime is Timestamp
              ? executionTime.toDate()
              : DateTime.tryParse(executionTime?.toString() ?? '') ??
                  DateTime.now(),
      status: map['status'] ?? 'failed',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'userId': userId,
      'executionType': executionType,
      'generatedContent': generatedContent,
      'executionTime': Timestamp.fromDate(executionTime),
      'status': status,
    };
  }
}
