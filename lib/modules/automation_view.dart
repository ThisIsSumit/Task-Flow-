import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:todo_app/controllers/home_controller.dart';
import 'package:todo_app/data/models/automation_log_model.dart';
import 'package:todo_app/data/models/task_model.dart';
import 'package:todo_app/data/services/auth_service.dart';
import 'package:todo_app/data/services/firestore_service.dart';
import 'package:todo_app/data/services/subscription_service.dart';
import 'package:todo_app/routes/app_pages.dart';

class AutomationView extends GetView<HomeController> {
  const AutomationView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subscriptionService = Get.find<SubscriptionService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Task Automation')),
      body: Obx(() {
        final ctrl = controller;
        final tasks = ctrl.tasks.toList();
        final automatedTasks = tasks.where((task) => task.autoExecute).toList();

        return Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.tertiaryContainer,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Smart Task Assistant',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Configure optional automation for any pending task and track each execution result.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Automation enabled on ${automatedTasks.length} task(s)',
                    style: theme.textTheme.labelLarge,
                  ),
                ],
              ),
            ),
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: TabBar(
                        tabs: [
                          Tab(text: 'Task Settings'),
                          Tab(text: 'History'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          subscriptionService.isPremium.value
                              ? _TaskAutomationSettings(
                                tasks: tasks,
                                controller: ctrl,
                              )
                              : _PremiumAutomationUpsell(theme: theme),
                          _AutomationHistory(tasks: tasks),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _TaskAutomationSettings extends StatelessWidget {
  final List<Task> tasks;
  final HomeController controller;

  const _TaskAutomationSettings({
    required this.tasks,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Center(child: Text('No tasks yet. Create a task first.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        return _TaskAutomationCard(task: tasks[index], controller: controller);
      },
    );
  }
}

class _TaskAutomationCard extends StatelessWidget {
  final Task task;
  final HomeController controller;

  const _TaskAutomationCard({required this.task, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color:
                        task.autoExecute
                            ? Colors.green.withValues(alpha: 0.16)
                            : theme.colorScheme.surfaceContainerHighest,
                  ),
                  child: Text(
                    task.autoExecute ? 'Automation Enabled' : 'Automation Off',
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Deadline: ${DateFormat('MMM dd, yyyy hh:mm a').format(task.dueDate)}',
              style: theme.textTheme.bodySmall,
            ),
            if (task.autoExecute) ...[
              const SizedBox(height: 6),
              Text(
                'Action: ${_executionTypeLabel(task.executionType)}',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                'Trigger: ${task.triggerBeforeDeadline} minutes before deadline',
                style: theme.textTheme.bodySmall,
              ),
              if (task.recipient.trim().isNotEmpty)
                Text(
                  'Recipient: ${task.recipient}',
                  style: theme.textTheme.bodySmall,
                ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showAutomationEditor(context),
                icon: const Icon(Icons.tune),
                label: const Text('Configure Automation'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAutomationEditor(BuildContext context) {
    final subscriptionService = Get.find<SubscriptionService>();
    if (!subscriptionService.isPremium.value) {
      Get.toNamed(Routes.SUBSCRIPTION);
      Get.snackbar(
        'Premium Required',
        'Automation is a premium feature. Upgrade to enable automated task execution.',
      );
      return;
    }

    Get.bottomSheet(
      _AutomationEditorSheet(task: task, controller: controller),
      isScrollControlled: true,
    );
  }

  String _executionTypeLabel(AutomationExecutionType type) {
    switch (type) {
      case AutomationExecutionType.email:
        return 'Send Email';
      case AutomationExecutionType.report:
        return 'Generate Report';
      case AutomationExecutionType.message:
        return 'Send Message';
      case AutomationExecutionType.meeting:
        return 'Schedule Meeting';
    }
  }
}

class _PremiumAutomationUpsell extends StatelessWidget {
  final ThemeData theme;

  const _PremiumAutomationUpsell({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.workspace_premium,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Automation is a premium feature.',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Upgrade to Premium to auto-send emails, generate reports, send messages, and schedule meetings before deadlines.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () => Get.toNamed(Routes.SUBSCRIPTION),
              icon: const Icon(Icons.upgrade),
              label: const Text('Upgrade to Premium'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AutomationEditorSheet extends StatefulWidget {
  final Task task;
  final HomeController controller;

  const _AutomationEditorSheet({required this.task, required this.controller});

  @override
  State<_AutomationEditorSheet> createState() => _AutomationEditorSheetState();
}

class _AutomationEditorSheetState extends State<_AutomationEditorSheet> {
  late final TextEditingController _recipientController;
  late bool _enabled;
  late int _triggerMinutes;
  late AutomationExecutionType _executionType;

  @override
  void initState() {
    super.initState();
    _enabled = widget.task.autoExecute;
    _triggerMinutes = widget.task.triggerBeforeDeadline;
    _executionType = widget.task.executionType;
    _recipientController = TextEditingController(text: widget.task.recipient);
  }

  @override
  void dispose() {
    _recipientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.task.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable Automation'),
                value: _enabled,
                onChanged: (value) => setState(() => _enabled = value),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<AutomationExecutionType>(
                initialValue: _executionType,
                decoration: const InputDecoration(
                  labelText: 'Automation Action',
                ),
                items: const [
                  DropdownMenuItem(
                    value: AutomationExecutionType.email,
                    child: Text('Send Email'),
                  ),
                  DropdownMenuItem(
                    value: AutomationExecutionType.report,
                    child: Text('Generate Report'),
                  ),
                  DropdownMenuItem(
                    value: AutomationExecutionType.message,
                    child: Text('Send Message'),
                  ),
                  DropdownMenuItem(
                    value: AutomationExecutionType.meeting,
                    child: Text('Schedule Meeting'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _executionType = value);
                  }
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                initialValue: _triggerMinutes,
                decoration: const InputDecoration(labelText: 'Trigger Time'),
                items: const [
                  DropdownMenuItem(
                    value: 5,
                    child: Text('5 minutes before deadline'),
                  ),
                  DropdownMenuItem(
                    value: 10,
                    child: Text('10 minutes before deadline'),
                  ),
                  DropdownMenuItem(
                    value: 30,
                    child: Text('30 minutes before deadline'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _triggerMinutes = value);
                  }
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _recipientController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Recipient (optional)',
                  hintText: 'Email address or contact',
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save Automation Settings'),
                  onPressed: () async {
                    await widget.controller.updateTaskAutomation(
                      widget.task,
                      enabled: _enabled,
                      executionType: _executionType,
                      recipient: _recipientController.text,
                      triggerMinutes: _triggerMinutes,
                    );
                    if (!context.mounted) {
                      return;
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AutomationHistory extends StatelessWidget {
  final List<Task> tasks;

  const _AutomationHistory({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final firestore = Get.find<FirestoreService>();
    final auth = Get.find<AuthService>();
    final userId = auth.getUserId();

    if (userId == null) {
      return const Center(
        child: Text('Please sign in to view automation history.'),
      );
    }

    final taskTitleById = <String, String>{
      for (final task in tasks) task.id: task.title,
    };

    return StreamBuilder<List<AutomationLog>>(
      stream: firestore.watchAutomationLogs(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final logs = snapshot.data ?? const <AutomationLog>[];
        if (logs.isEmpty) {
          return const Center(
            child: Text(
              'No automation runs yet. Completed executions appear here.',
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          itemBuilder: (context, index) {
            final log = logs[index];
            final isSuccess = log.status.toLowerCase() == 'success';
            final taskTitle = taskTitleById[log.taskId] ?? 'Task ${log.taskId}';

            return ListTile(
              tileColor: Theme.of(context).colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(taskTitle),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Action: ${_executionLabel(log.executionType)}'),
                  Text(
                    'Execution: ${DateFormat('MMM dd, yyyy hh:mm a').format(log.executionTime)}',
                  ),
                  Text(
                    'Result: ${isSuccess ? 'Success' : 'Failed'}',
                    style: TextStyle(
                      color: isSuccess ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              trailing: Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? Colors.green : Colors.red,
              ),
            );
          },
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemCount: logs.length,
        );
      },
    );
  }

  String _executionLabel(String value) {
    switch (value) {
      case 'email':
        return 'Email Sent';
      case 'report':
        return 'Report Generated';
      case 'message':
        return 'Message Sent';
      case 'meeting':
        return 'Meeting Scheduled';
      default:
        return value;
    }
  }
}
