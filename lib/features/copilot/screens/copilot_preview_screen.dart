import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/copilot_controller.dart';

class CopilotPreviewScreen extends GetView<CopilotController> {
  const CopilotPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generated Plan')),
      body: Obx(() {
        if (controller.generatedTasks.isEmpty) {
          return const Center(
            child: Text('No generated tasks. Return to Copilot and try again.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.generatedTasks.length,
          itemBuilder: (context, index) {
            final task = controller.generatedTasks[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Deadline: ${task.deadline}'),
                    Text('Repeat: ${task.repeat}'),
                    Text(
                      'Reminder: ${task.reminderMinutesBefore} minutes before',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Automation: ${task.automation.enabled ? task.automation.executionType : 'disabled'}',
                    ),
                    if (task.subtasks.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Subtasks',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      ...task.subtasks.map((item) => Text('• $item')),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _showEditDialog(context, index),
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Obx(
            () => Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        controller.isSaving.value ? null : () => Get.back(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        controller.isSaving.value
                            ? null
                            : controller.saveGeneratedTasks,
                    child:
                        controller.isSaving.value
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text('Save Tasks'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, int index) async {
    final original = controller.generatedTasks[index];
    final titleController = TextEditingController(text: original.title);
    final descriptionController = TextEditingController(
      text: original.description,
    );
    final deadlineController = TextEditingController(text: original.deadline);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: deadlineController,
                  decoration: const InputDecoration(
                    labelText: 'Deadline (ISO or natural text)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await controller.updateTaskAt(
                  index,
                  title: titleController.text,
                  description: descriptionController.text,
                  deadline: deadlineController.text,
                );
                if (!context.mounted) {
                  return;
                }
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();
    deadlineController.dispose();
  }
}
