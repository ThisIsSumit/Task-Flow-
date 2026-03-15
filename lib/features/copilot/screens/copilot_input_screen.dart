import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/copilot_controller.dart';

class CopilotInputScreen extends GetView<CopilotController> {
  const CopilotInputScreen({super.key});

  static const List<String> _suggestions = [
    'Prepare weekly report every Friday',
    'Plan my study schedule for tomorrow',
    'Remind me to call mom every Sunday evening',
    'Submit assignment tomorrow and email professor if incomplete',
  ];

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    if (args is Map && controller.instructionController.text.trim().isEmpty) {
      final prefill = (args['prefill'] ?? '').toString().trim();
      if (prefill.isNotEmpty) {
        controller.instructionController.text = prefill;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('AI Copilot Automation')),
      body: Obx(
        () => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'What would you like to plan?',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Describe your task or goal in natural language and Copilot will generate tasks, subtasks, reminders, and automation rules.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller.instructionController,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Describe your task or goal...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Example suggestions',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _suggestions
                      .map(
                        (item) => ActionChip(
                          label: Text(item),
                          onPressed: () => controller.applySuggestion(item),
                        ),
                      )
                      .toList(),
            ),
            if (controller.errorMessage.value.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                controller.errorMessage.value,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    controller.isGenerating.value
                        ? null
                        : controller.generatePlan,
                icon:
                    controller.isGenerating.value
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.auto_awesome),
                label: Text(
                  controller.isGenerating.value
                      ? 'Generating...'
                      : 'Generate Plan',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
