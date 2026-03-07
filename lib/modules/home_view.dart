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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.resetTaskForm();
          _showTaskForm(context);
        },
        child: const Icon(Icons.add),
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
              if (task.attachments.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'Attachments',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...task.attachments.map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(
                      item.type == AttachmentType.image
                          ? Icons.image
                          : item.type == AttachmentType.file
                          ? Icons.insert_drive_file
                          : Icons.link,
                    ),
                    title: Text(item.label),
                    subtitle: Text(
                      item.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
                  TextField(
                    controller: ctrl.taskTitleController,
                    decoration: const InputDecoration(labelText: 'Title*'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: ctrl.taskDescController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Description'),
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
                                : ctrl.formatDate(ctrl.selectedDate!),
                          ),
                          onPressed: () async {
                            final selected = await showDatePicker(
                              context: context,
                              initialDate: ctrl.selectedDate ?? DateTime.now(),
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 365),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 3650),
                              ),
                            );
                            if (selected != null) {
                              ctrl.selectedDate = selected;
                              ctrl.update();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
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
                                    ctrl.selectedReminderDate ?? DateTime.now(),
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: ctrl.attachmentLabelController,
                          decoration: const InputDecoration(
                            labelText: 'Attachment label',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: ctrl.attachmentUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Image/File/Link URL',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<AttachmentType>(
                          initialValue: ctrl.selectedAttachmentType.value,
                          items:
                              AttachmentType.values
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(item.name),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              ctrl.selectedAttachmentType.value = value;
                              ctrl.update();
                            }
                          },
                          decoration: const InputDecoration(
                            labelText: 'Attachment Type',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: ctrl.addDraftAttachment,
                        icon: const Icon(Icons.attach_file),
                      ),
                    ],
                  ),
                  if (ctrl.draftAttachments.isNotEmpty)
                    Column(
                      children:
                          ctrl.draftAttachments
                              .map(
                                (item) => ListTile(
                                  dense: true,
                                  title: Text(item.label),
                                  subtitle: Text(
                                    item.url,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed:
                                        () =>
                                            ctrl.removeDraftAttachment(item.id),
                                  ),
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
          );
        },
      ),
      isScrollControlled: true,
    );
  }
}
