import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
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
        child: const Icon(Icons.add),
        onPressed: () => _showAddTaskDialog(context),
      ),
      body: Column(
        children: [_buildFilterControls(), Expanded(child: _buildTaskList())],
      ),
    );
  }

  Widget _buildFilterControls() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Obx(() {
            // First access all observable values
            final selectedCategory = controller.selectedCategory.value;
            final categories = controller.categories;
            final showCompleted = controller.showCompleted.value;

            return Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedCategory,
                    items:
                        categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        controller.selectedCategory.value = value;
                        controller.filterTasks();
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Switch(
                  value: showCompleted,
                  onChanged: (value) {
                    controller.showCompleted.value = value;
                    controller.filterTasks();
                  },
                ),
                const Text('Completed'),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    return Obx(() {
      // Access observable variables FIRST in the builder
      final isLoading = controller.isLoading.value;
      final filteredTasks = controller.filteredTasks;

      if (isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      if (filteredTasks.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'No tasks found',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap the + button to add a new task',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: filteredTasks.length,
        itemBuilder: (context, index) {
          final task = filteredTasks[index];
          return _buildTaskItem(task, context, index);
        },
      );
    });
  }

  Widget _buildTaskItem(Task task, BuildContext context, int index) {
    final isOverdue =
        !task.isCompleted && task.dueDate.isBefore(DateTime.now());

    return Padding(
      key: ValueKey(task.id),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Slidable(
        key: Key(task.id),
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => controller.toggleTaskStatus(task),
              backgroundColor: task.isCompleted ? Colors.orange : Colors.green,
              foregroundColor: Colors.white,
              icon: task.isCompleted ? Icons.refresh : Icons.check,
              label: task.isCompleted ? 'Pending' : 'Complete',
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => _showEditTaskDialog(task, context),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: 'Edit',
            ),
            SlidableAction(
              onPressed: (_) => _confirmDeleteTask(task),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: 80,
            maxWidth: MediaQuery.of(context).size.width - 32,
          ),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showTaskDetails(task, context),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              decoration:
                                  task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: controller.getPriorityColor(task.priority),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            controller.getPriorityText(task.priority),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (task.description.isNotEmpty) ...[
                      Text(
                        task.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[600],
                          decoration:
                              task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${task.category} • ${controller.formatDate(task.dueDate)}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isOverdue ? Colors.red : Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            task.isCompleted
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color:
                                task.isCompleted ? Colors.green : Colors.grey,
                          ),
                          onPressed: () => controller.toggleTaskStatus(task),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    // Reset controllers
    controller.taskTitleController.clear();
    controller.taskDescController.clear();
    controller.taskCategoryController.clear();
    controller.selectedDate = DateTime.now().add(const Duration(days: 1));
    controller.selectedPriority = 2;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add New Task',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.taskTitleController,
                decoration: const InputDecoration(
                  labelText: 'Title*',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.taskDescController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.taskCategoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Work, Personal, Shopping',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final selected = await showDatePicker(
                          context: context,
                          initialDate:
                              controller.selectedDate ??
                              DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (selected != null) {
                          controller.selectedDate = selected;
                          // Force UI update by calling this:
                          controller.update();
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Due Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 20),
                            const SizedBox(width: 8),
                            // Instead of Obx, use GetBuilder
                            GetBuilder<HomeController>(
                              builder:
                                  (ctrl) => Text(
                                    ctrl.selectedDate != null
                                        ? ctrl.formatDate(ctrl.selectedDate!)
                                        : 'Select a date',
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GetBuilder<HomeController>(
                      builder:
                          (ctrl) => DropdownButtonFormField<int>(
                            value: ctrl.selectedPriority,
                            items: [
                              const DropdownMenuItem(
                                value: 1,
                                child: Text('High Priority'),
                              ),
                              const DropdownMenuItem(
                                value: 2,
                                child: Text('Medium Priority'),
                              ),
                              const DropdownMenuItem(
                                value: 3,
                                child: Text('Low Priority'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                ctrl.selectedPriority = value;
                                ctrl.update();
                              }
                            },
                            decoration: const InputDecoration(
                              labelText: 'Priority',
                              border: OutlineInputBorder(),
                            ),
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: controller.addTask,
                  child: Obx(
                    () =>
                        controller.isLoading.value
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text(
                              'Add Task',
                              style: TextStyle(fontSize: 16),
                            ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showTaskDetails(Task task, BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 60,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              task.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (task.description.isNotEmpty) ...[
              Text(task.description, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
            ],
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.category, size: 20, color: Colors.grey[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Category: ${task.category}',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Due: ${controller.formatDate(task.dueDate)}',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.priority_high,
                        size: 20,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Priority: ${controller.getPriorityText(task.priority)}',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 20,
                        color:
                            task.isCompleted ? Colors.green : Colors.grey[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Status: ${task.isCompleted ? 'Completed' : 'Pending'}',
                        style: TextStyle(
                          color:
                              task.isCompleted
                                  ? Colors.green
                                  : Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (task.completedAt != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.done_all, size: 20, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Completed on: ${controller.formatDate(task.completedAt!)}',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(
                      task.isCompleted ? Icons.refresh : Icons.check_circle,
                      color: Colors.white,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          task.isCompleted ? Colors.orange : Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Get.back();
                      controller.toggleTaskStatus(task);
                    },
                    label: Text(
                      task.isCompleted
                          ? 'Mark as Pending'
                          : 'Mark as Completed',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Get.back();
                      _showEditTaskDialog(task, context);
                    },
                    label: const Text('Edit Task'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: Colors.red,
                    ),
                    onPressed: () {
                      Get.back();
                      _confirmDeleteTask(task);
                    },
                    label: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showEditTaskDialog(Task task, BuildContext context) {
    // Set the current task values in the controllers
    controller.taskTitleController.text = task.title;
    controller.taskDescController.text = task.description;
    controller.taskCategoryController.text = task.category;
    controller.selectedDate = task.dueDate;
    controller.selectedPriority = task.priority;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Edit Task',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.taskTitleController,
                decoration: const InputDecoration(
                  labelText: 'Title*',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.taskDescController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.taskCategoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final selected = await showDatePicker(
                          context: context,
                          initialDate:
                              controller.selectedDate ??
                              DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (selected != null) {
                          controller.selectedDate = selected;
                          // Force UI update by calling this:
                          controller.update();
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Due Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 20),
                            const SizedBox(width: 8),
                            // Instead of Obx, use GetBuilder
                            GetBuilder<HomeController>(
                              builder:
                                  (ctrl) => Text(
                                    ctrl.selectedDate != null
                                        ? ctrl.formatDate(ctrl.selectedDate!)
                                        : 'Select a date',
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GetBuilder<HomeController>(
                      builder:
                          (ctrl) => DropdownButtonFormField<int>(
                            value: ctrl.selectedPriority,
                            items: [
                              const DropdownMenuItem(
                                value: 1,
                                child: Text('High Priority'),
                              ),
                              const DropdownMenuItem(
                                value: 2,
                                child: Text('Medium Priority'),
                              ),
                              const DropdownMenuItem(
                                value: 3,
                                child: Text('Low Priority'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                ctrl.selectedPriority = value;
                                ctrl.update();
                              }
                            },
                            decoration: const InputDecoration(
                              labelText: 'Priority',
                              border: OutlineInputBorder(),
                            ),
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => controller.updateTask(task),
                      child: Obx(
                        () =>
                            controller.isLoading.value
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : const Text(
                                  'Update Task',
                                  style: TextStyle(fontSize: 16),
                                ),
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

  Future<bool?> _showDeleteConfirmationDialog(
    BuildContext context,
    Task task,
  ) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Task'),
          content: Text('Are you sure you want to delete "${task.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteTask(Task task) async {
    final confirmed = await _showDeleteConfirmationDialog(Get.context!, task);
    if (confirmed == true) {
      controller.deleteTask(task.id);
    }
  }

  void _showQuickActionMenu(BuildContext context, Task task) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(
          overlay.localToGlobal(const Offset(0, 0)),
          overlay.localToGlobal(overlay.size.bottomRight(Offset.zero)),
        ),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          child: ListTile(
            leading: Icon(
              task.isCompleted ? Icons.refresh : Icons.check_circle,
              color: task.isCompleted ? Colors.orange : Colors.green,
            ),
            title: Text(
              task.isCompleted ? 'Mark as Pending' : 'Mark as Completed',
            ),
            contentPadding: EdgeInsets.zero,
          ),
          onTap: () => controller.toggleTaskStatus(task),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit, color: Colors.blue),
            title: Text('Edit Task'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Delete Task'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    ).then((value) {
      if (value == 'edit') {
        _showEditTaskDialog(task, context);
      } else if (value == 'delete') {
        _confirmDeleteTask(task);
      }
    });
  }
}
