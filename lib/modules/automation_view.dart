import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todo_app/controllers/home_controller.dart';
import 'package:todo_app/data/models/task_model.dart';
import 'package:todo_app/routes/app_pages.dart';

class AutomationView extends GetView<HomeController> {
  const AutomationView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Agent Automation')),
      body: Obx(() {
        // Read controller once here; pass it down so child cards
        // never need an independent Get.find call (avoids null-check
        // crash when SmartManagement disposes the controller during
        // navigation).
        final ctrl = controller;
        final tasks = ctrl.tasks.toList();

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
                    theme.colorScheme.secondaryContainer,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Automation Control Center',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pick a task and configure how the agent should run before its deadline.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            if (!ctrl.canConfigureAutomation)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.workspace_premium),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Automation is a premium feature. Upgrade to enable agent execution.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Get.toNamed(Routes.SUBSCRIPTION),
                      child: const Text('Upgrade'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child:
                  tasks.isEmpty
                      ? const Center(
                        child: Text('No tasks yet. Add one first!'),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          return _TaskAutomationCard(
                            task: tasks[index],
                            controller: ctrl,
                          );
                        },
                      ),
            ),
          ],
        );
      }),
    );
  }
}

/// Card for a single task's automation settings.
///
/// Receives [controller] from the parent [AutomationView] instead of using
/// GetView so there is one single Get.find call per screen (preventing null
/// check crashes when GetX smart management interacts with navigation).
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
                    task.autoExecute ? 'Enabled' : 'Disabled',
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Due: ${controller.formatDate(task.dueDate)}',
              style: theme.textTheme.bodySmall,
            ),
            if (task.automationInstruction.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Agent goal: ${task.automationInstruction}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (task.generatedAutomationSummary.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Last output: ${task.generatedAutomationSummary}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.tune),
                    onPressed: () => _showAutomationEditor(context, task),
                    label: const Text('Configure Agent'),
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: task.autoExecute,
                  onChanged: (value) {
                    if (!controller.canConfigureAutomation && value) {
                      Get.toNamed(Routes.SUBSCRIPTION);
                      return;
                    }
                    controller.updateTaskAutomation(
                      task,
                      enabled: value,
                      instruction: task.automationInstruction,
                      mode: task.automationMode,
                      triggerMinutes: task.triggerBeforeDeadline,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAutomationEditor(BuildContext context, Task task) {
    Get.bottomSheet(
      _AutomationEditorSheet(task: task, controller: controller),
      isScrollControlled: true,
    );
  }
}

/// Bottom-sheet content for configuring a task's automation.
///
/// Uses [StatefulWidget] so [TextEditingController] and local form state are
/// properly tied to the widget lifecycle (created in [initState], disposed in
/// [dispose]). This eliminates the race condition where an [Obx]-based sheet
/// could receive a reactive rebuild after the controller had already been
/// disposed by the outer async caller.
class _AutomationEditorSheet extends StatefulWidget {
  final Task task;
  final HomeController controller;

  const _AutomationEditorSheet({required this.task, required this.controller});

  @override
  State<_AutomationEditorSheet> createState() => _AutomationEditorSheetState();
}

class _AutomationEditorSheetState extends State<_AutomationEditorSheet> {
  late final TextEditingController _instructionController;
  late AutomationMode _mode;
  late int _triggerMinutes;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _instructionController = TextEditingController(
      text: widget.task.automationInstruction,
    );
    _mode = widget.task.automationMode;
    _triggerMinutes = widget.task.triggerBeforeDeadline;
    _enabled = widget.task.autoExecute;
  }

  @override
  void dispose() {
    _instructionController.dispose();
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
                title: const Text('Enable automation'),
                value: _enabled,
                onChanged: (value) {
                  if (!widget.controller.canConfigureAutomation && value) {
                    Get.toNamed(Routes.SUBSCRIPTION);
                    return;
                  }
                  setState(() => _enabled = value);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _instructionController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Agent instruction',
                  hintText:
                      'Example: Draft a concise status update and summarize blockers.',
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<AutomationMode>(
                value: _mode,
                decoration: const InputDecoration(labelText: 'Run mode'),
                items:
                    AutomationMode.values
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(
                              item == AutomationMode.execute
                                  ? 'Execute and complete task'
                                  : 'Suggest only',
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _mode = value);
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: _triggerMinutes,
                decoration: const InputDecoration(labelText: 'Trigger time'),
                items:
                    const [5, 10, 30, 60]
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text('$item minutes before deadline'),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _triggerMinutes = value);
                },
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
                      instruction: _instructionController.text,
                      mode: _mode,
                      triggerMinutes: _triggerMinutes,
                    );
                    if (mounted) Navigator.of(context).pop();
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
