import 'package:cloud_firestore/cloud_firestore.dart';

class AutomationLog {
  final String id;
  final String taskId;
  final String userId;
  final String actionType;
  final String summary;
  final String mode;
  final String generatedContent;
  final DateTime executionTime;
  final String status;

  const AutomationLog({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.actionType,
    required this.summary,
    required this.mode,
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
      actionType: map['actionType'] ?? '',
      summary: map['summary'] ?? '',
      mode: map['mode'] ?? 'execute',
      generatedContent: map['generatedContent'] ?? '',
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
      'actionType': actionType,
      'summary': summary,
      'mode': mode,
      'generatedContent': generatedContent,
      'executionTime': Timestamp.fromDate(executionTime),
      'status': status,
    };
  }
}
