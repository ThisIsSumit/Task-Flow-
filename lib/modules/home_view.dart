import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:todo_app/data/models/task_model.dart';
import 'package:todo_app/routes/app_pages.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => Get.toNamed(Routes.CALENDAR),
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => Get.toNamed(Routes.ANALYTICS),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Get.toNamed(Routes.PROFILE),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'automation_fab',
            onPressed: () => Get.toNamed(Routes.AUTOMATION),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Automation'),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'add_task_fab',
            onPressed: () {
              controller.resetTaskForm();
              _showTaskForm(context);
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [_buildTopControls(), Expanded(child: _buildTaskList())],
      ),
    );
  }

  Widget _buildTopControls() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            onChanged: (value) {
              controller.searchQuery.value = value;
              controller.filterTasks();
            },
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search title, notes, category...',
            ),
          ),
          const SizedBox(height: 10),
          Obx(
            () => Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: controller.selectedCategory.value,
                    items:
                        controller.categories
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      controller.selectedCategory.value = value;
                      controller.filterTasks();
                    },
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<TaskSortOption>(
                    initialValue: controller.sortOption.value,
                    items: const [
                      DropdownMenuItem(
                        value: TaskSortOption.dueDate,
                        child: Text('Due Date'),
                      ),
                      DropdownMenuItem(
                        value: TaskSortOption.priority,
                        child: Text('Priority'),
                      ),
                      DropdownMenuItem(
                        value: TaskSortOption.recent,
                        child: Text('Recent'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      controller.sortOption.value = value;
                      controller.filterTasks();
                    },
                    decoration: const InputDecoration(labelText: 'Sort By'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: controller.quickFilter.value == QuickFilter.all,
                      onSelected: (_) {
                        controller.quickFilter.value = QuickFilter.all;
                        controller.filterTasks();
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Today'),
                      selected:
                          controller.quickFilter.value == QuickFilter.today,
                      onSelected: (_) {
                        controller.quickFilter.value = QuickFilter.today;
                        controller.filterTasks();
                      },
                    ),
                    ChoiceChip(
                      label: const Text('This Week'),
                      selected:
                          controller.quickFilter.value == QuickFilter.thisWeek,
                      onSelected: (_) {
                        controller.quickFilter.value = QuickFilter.thisWeek;
                        controller.filterTasks();
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text('Completed'),
                    Switch(
                      value: controller.showCompleted.value,
                      onChanged: (value) {
                        controller.showCompleted.value = value;
                        controller.filterTasks();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.filteredTasks.isEmpty) {
        return const Center(child: Text('No tasks found'));
      }

      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: controller.filteredTasks.length,
        itemBuilder: (context, index) {
          final task = controller.filteredTasks[index];
          return _buildTaskItem(task, context);
        },
      );
    });
  }

  Widget _buildTaskItem(Task task, BuildContext context) {
    final isOverdue =
        !task.isCompleted && task.dueDate.isBefore(DateTime.now());
    final completedSubtasks = task.subtasks.where((item) => item.isDone).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Slidable(
        key: ValueKey(task.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (_) {
                controller.prepareTaskForm(task);
                _showTaskForm(context, existingTask: task);
              },
              backgroundColor: Colors.blue,
              icon: Icons.edit,
              label: 'Edit',
            ),
            SlidableAction(
              onPressed: (_) => controller.deleteTask(task.id),
              backgroundColor: Colors.red,
              icon: Icons.delete,
              label: 'Delete',
            ),
          ],
        ),
        child: Card(
          child: ListTile(
            onTap: () => _showTaskDetails(task, context),
            leading: IconButton(
              icon: Icon(
                task.isCompleted
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: task.isCompleted ? Colors.green : Colors.grey,
              ),
              onPressed: () => controller.toggleTaskStatus(task),
            ),
            title: Text(
              task.title,
              style: TextStyle(
                decoration:
                    task.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${task.category} • ${controller.formatDate(task.dueDate)}',
                  style: TextStyle(color: isOverdue ? Colors.red : null),
                ),
                if (task.autoExecute) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Automation Enabled',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Action: ${_executionTypeLabel(task.executionType)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (task.recurrence != RecurrenceType.none)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(Icons.repeat, size: 16),
                      ),
                    if (task.reminderEnabled)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(Icons.notifications_active, size: 16),
                      ),
                    if (task.subtasks.isNotEmpty)
                      Text(
                        'Checklist: $completedSubtasks/${task.subtasks.length}',
                      ),
                  ],
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: controller.getPriorityColor(task.priority),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                controller.getPriorityText(task.priority),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showTaskDetails(Task task, BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (task.description.isNotEmpty) Text(task.description),
              const SizedBox(height: 10),
              Text('Due: ${controller.formatDate(task.dueDate)}'),
              Text('Priority: ${controller.getPriorityText(task.priority)}'),
              Text('Recurrence: ${task.recurrence.name}'),
              if (task.notes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('Notes: ${task.notes}'),
              ],
              if (task.autoExecute ||
                  task.automationInstruction.isNotEmpty ||
                  task.generatedAutomationSummary.isNotEmpty ||
                  task.generatedAutomationContent.isNotEmpty ||
                  task.automationLastExecutedAt != null) ...[
                const SizedBox(height: 10),
                const Text(
                  'Automation',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Action: ${_executionTypeLabel(task.executionType)}'),
                Text('Mode: ${_automationModeLabel(task.automationMode)}'),
                Text('Status: ${task.autoExecute ? 'Enabled' : 'Disabled'}'),
                if (task.recipient.trim().isNotEmpty)
                  Text('Recipient: ${task.recipient.trim()}'),
                Text(
                  task.automationInstruction.isEmpty
                      ? 'Instruction: (none)'
                      : 'Instruction: ${task.automationInstruction}',
                ),
                Text(
                  'Trigger: ${task.triggerBeforeDeadline} minutes before deadline',
                ),
                if (task.automationLastExecutedAt != null)
                  Text(
                    'Last executed: ${controller.formatDate(task.automationLastExecutedAt!)}',
                  ),
                if (task.generatedAutomationSummary.isNotEmpty ||
                    task.generatedAutomationContent.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Last Agent Output',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (task.generatedAutomationSummary.isNotEmpty)
                    Text('Summary: ${task.generatedAutomationSummary}'),
                  if (task.generatedAutomationContent.isNotEmpty)
                    Text(
                      task.generatedAutomationContent,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ],
              if (task.subtasks.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'Checklist',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...task.subtasks.map(
                  (item) => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: item.isDone,
                    title: Text(item.title),
                    onChanged: (_) => controller.toggleSubtask(task, item),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Get.back();
                        controller.prepareTaskForm(task);
                        _showTaskForm(context, existingTask: task);
                      },
                      child: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        controller.toggleTaskStatus(task);
                      },
                      child: Text(
                        task.isCompleted ? 'Mark Pending' : 'Mark Complete',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showTaskForm(BuildContext context, {Task? existingTask}) {
    Get.bottomSheet(
      GetBuilder<HomeController>(
        builder: (ctrl) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text(
                      existingTask == null ? 'Add Task' : 'Edit Task',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Section 1 — Task Details',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: ctrl.taskTitleController,
                      decoration: const InputDecoration(labelText: 'Title*'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: ctrl.taskDescController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: ctrl.taskCategoryController,
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: ctrl.taskNotesController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Notes'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: ctrl.selectedPriority,
                            items: const [
                              DropdownMenuItem(value: 1, child: Text('High')),
                              DropdownMenuItem(value: 2, child: Text('Medium')),
                              DropdownMenuItem(value: 3, child: Text('Low')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                ctrl.selectedPriority = value;
                                ctrl.update();
                              }
                            },
                            decoration: const InputDecoration(
                              labelText: 'Priority',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<RecurrenceType>(
                            initialValue: ctrl.selectedRecurrence.value,
                            items:
                                RecurrenceType.values
                                    .map(
                                      (item) => DropdownMenuItem(
                                        value: item,
                                        child: Text(item.name),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                ctrl.selectedRecurrence.value = value;
                                ctrl.update();
                              }
                            },
                            decoration: const InputDecoration(
                              labelText: 'Recurring',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              ctrl.selectedDate == null
                                  ? 'Pick Due Date'
                                  : '${ctrl.formatDate(ctrl.selectedDate!)} ${TimeOfDay.fromDateTime(ctrl.selectedDate!).format(context)}',
                            ),
                            onPressed: () async {
                              final selected = await showDatePicker(
                                context: context,
                                initialDate:
                                    ctrl.selectedDate ?? DateTime.now(),
                                firstDate: DateTime.now().subtract(
                                  const Duration(days: 365),
                                ),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 3650),
                                ),
                              );
                              if (selected != null) {
                                if (!context.mounted) {
                                  return;
                                }
                                final selectedTime = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.fromDateTime(
                                    ctrl.selectedDate ?? DateTime.now(),
                                  ),
                                );
                                if (selectedTime == null) {
                                  return;
                                }
                                ctrl.selectedDate = DateTime(
                                  selected.year,
                                  selected.month,
                                  selected.day,
                                  selectedTime.hour,
                                  selectedTime.minute,
                                );
                                ctrl.update();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Section 2 — Automation Settings',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable Automation'),
                      value: ctrl.autoExecute.value,
                      onChanged:
                          (value) => ctrl.onAutomationToggleChanged(value),
                    ),
                    if (ctrl.autoExecute.value) ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<AutomationExecutionType>(
                        initialValue: ctrl.selectedExecutionType.value,
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
                            value: AutomationExecutionType.notification,
                            child: Text('Create Reminder Notification'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          ctrl.selectedExecutionType.value = value;
                          ctrl.update();
                        },
                        decoration: const InputDecoration(
                          labelText: 'Automation Action',
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        initialValue: ctrl.triggerBeforeDeadline.value,
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
                          if (value == null) {
                            return;
                          }
                          ctrl.triggerBeforeDeadline.value = value;
                          ctrl.update();
                        },
                        decoration: const InputDecoration(
                          labelText: 'Trigger Time',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: ctrl.automationRecipientController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Recipient (optional)',
                          hintText: 'Email address or contact',
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Reminder'),
                            value: ctrl.reminderEnabled.value,
                            onChanged: (value) {
                              ctrl.reminderEnabled.value = value;
                              ctrl.update();
                            },
                          ),
                        ),
                      ],
                    ),
                    if (ctrl.reminderEnabled.value)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.notifications),
                              label: Text(
                                ctrl.selectedReminderDate == null
                                    ? 'Pick Reminder Time'
                                    : '${ctrl.formatDate(ctrl.selectedReminderDate!)} ${TimeOfDay.fromDateTime(ctrl.selectedReminderDate!).format(context)}',
                              ),
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      ctrl.selectedReminderDate ??
                                      DateTime.now(),
                                  firstDate: DateTime.now().subtract(
                                    const Duration(days: 30),
                                  ),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 3650),
                                  ),
                                );
                                if (date == null) {
                                  return;
                                }
                                if (!context.mounted) {
                                  return;
                                }
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.fromDateTime(
                                    ctrl.selectedReminderDate ?? DateTime.now(),
                                  ),
                                );
                                if (time == null) {
                                  return;
                                }
                                ctrl.selectedReminderDate = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                                ctrl.update();
                              },
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: ctrl.subtaskController,
                            decoration: const InputDecoration(
                              labelText: 'Add checklist item',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: ctrl.addDraftSubtask,
                          icon: const Icon(Icons.add_circle),
                        ),
                      ],
                    ),
                    if (ctrl.draftSubtasks.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        children:
                            ctrl.draftSubtasks
                                .map(
                                  (item) => Chip(
                                    label: Text(item.title),
                                    onDeleted:
                                        () => ctrl.removeDraftSubtask(item.id),
                                  ),
                                )
                                .toList(),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            ctrl.isLoading.value
                                ? null
                                : () {
                                  if (existingTask == null) {
                                    ctrl.addTask();
                                  } else {
                                    ctrl.updateTask(existingTask);
                                  }
                                },
                        child:
                            ctrl.isLoading.value
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : Text(
                                  existingTask == null
                                      ? 'Add Task'
                                      : 'Update Task',
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  String _automationModeLabel(AutomationMode mode) {
    switch (mode) {
      case AutomationMode.execute:
        return 'Execute and complete task';
      case AutomationMode.suggest:
        return 'Suggest only (review first)';
    }
  }

  String _executionTypeLabel(AutomationExecutionType type) {
    switch (type) {
      case AutomationExecutionType.email:
        return 'Send Email';
      case AutomationExecutionType.report:
        return 'Generate Report';
      case AutomationExecutionType.message:
        return 'Send Message';
      case AutomationExecutionType.notification:
        return 'Create Reminder Notification';
    }
  }
}
