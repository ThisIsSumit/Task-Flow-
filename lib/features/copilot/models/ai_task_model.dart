class CopilotAutomationConfig {
  final bool enabled;
  final String executionType;
  final int triggerBeforeDeadline;
  final Map<String, dynamic> config;

  const CopilotAutomationConfig({
    required this.enabled,
    required this.executionType,
    required this.triggerBeforeDeadline,
    required this.config,
  });

  factory CopilotAutomationConfig.fromMap(Map<String, dynamic> map) {
    return CopilotAutomationConfig(
      enabled: map['enabled'] == true,
      executionType: (map['executionType'] ?? 'email').toString(),
      triggerBeforeDeadline: (map['triggerBeforeDeadline'] ?? 10) as int,
      config: Map<String, dynamic>.from((map['config'] as Map?) ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'executionType': executionType,
      'triggerBeforeDeadline': triggerBeforeDeadline,
      'config': config,
    };
  }

  CopilotAutomationConfig copyWith({
    bool? enabled,
    String? executionType,
    int? triggerBeforeDeadline,
    Map<String, dynamic>? config,
  }) {
    return CopilotAutomationConfig(
      enabled: enabled ?? this.enabled,
      executionType: executionType ?? this.executionType,
      triggerBeforeDeadline:
          triggerBeforeDeadline ?? this.triggerBeforeDeadline,
      config: config ?? this.config,
    );
  }
}

class CopilotTaskPlan {
  final String title;
  final String description;
  final String deadline;
  final String repeat;
  final int reminderMinutesBefore;
  final List<String> subtasks;
  final CopilotAutomationConfig automation;

  const CopilotTaskPlan({
    required this.title,
    required this.description,
    required this.deadline,
    required this.repeat,
    required this.reminderMinutesBefore,
    required this.subtasks,
    required this.automation,
  });

  factory CopilotTaskPlan.fromMap(Map<String, dynamic> map) {
    return CopilotTaskPlan(
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      deadline: (map['deadline'] ?? '').toString(),
      repeat: (map['repeat'] ?? 'none').toString(),
      reminderMinutesBefore: (map['reminderMinutesBefore'] ?? 30) as int,
      subtasks:
          ((map['subtasks'] as List?) ?? const [])
              .map((item) => item.toString())
              .toList(),
      automation: CopilotAutomationConfig.fromMap(
        Map<String, dynamic>.from((map['automation'] as Map?) ?? {}),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'deadline': deadline,
      'repeat': repeat,
      'reminderMinutesBefore': reminderMinutesBefore,
      'subtasks': subtasks,
      'automation': automation.toMap(),
    };
  }

  CopilotTaskPlan copyWith({
    String? title,
    String? description,
    String? deadline,
    String? repeat,
    int? reminderMinutesBefore,
    List<String>? subtasks,
    CopilotAutomationConfig? automation,
  }) {
    return CopilotTaskPlan(
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      repeat: repeat ?? this.repeat,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      subtasks: subtasks ?? this.subtasks,
      automation: automation ?? this.automation,
    );
  }
}

class CopilotPlanResponse {
  final bool success;
  final bool requiresUpgrade;
  final String message;
  final List<CopilotTaskPlan> tasks;

  const CopilotPlanResponse({
    required this.success,
    required this.requiresUpgrade,
    required this.message,
    required this.tasks,
  });

  factory CopilotPlanResponse.fromMap(Map<String, dynamic> map) {
    return CopilotPlanResponse(
      success: map['success'] == true,
      requiresUpgrade: map['requiresUpgrade'] == true,
      message: (map['message'] ?? '').toString(),
      tasks:
          ((map['tasks'] as List?) ?? const [])
              .whereType<Map>()
              .map(
                (item) =>
                    CopilotTaskPlan.fromMap(Map<String, dynamic>.from(item)),
              )
              .toList(),
    );
  }
}
