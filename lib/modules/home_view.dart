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
        title: Text('My Tasks'),
        actions: [
          IconButton(
            icon: Icon(Icons.analytics),
            onPressed: () => Get.toNamed(Routes.ANALYTICS),
          ),
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () => Get.toNamed(Routes.PROFILE),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showAddTaskDialog(context),
      ),
      body: Column(
        children: [
          _buildFilterControls(),
          Expanded(child: _buildTaskList()),
        ],
      ),
    );
  }
  
  Widget _buildFilterControls() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Obx(() => Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: controller.selectedCategory.value,
                  items: controller.categories.map((category) {
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
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Switch(
                value: controller.showCompleted.value,
                onChanged: (value) {
                  controller.showCompleted.value = value;
                  controller.filterTasks();
                },
              ),
              Text('Completed'),
            ],
          )),
        ],
      ),
    );
  }
  
  Widget _buildTaskList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(child: CircularProgressIndicator());
      }
      
      if (controller.filteredTasks.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No tasks found',
                  style: TextStyle(fontSize: 18, color: Colors.grey)),
              SizedBox(height: 8),
              Text('Tap the + button to add a new task',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        );
      }
      
      return ListView.builder(
        padding: EdgeInsets.only(bottom: 80),
        itemCount: controller.filteredTasks.length,
        itemBuilder: (context, index) {
          final task = controller.filteredTasks[index];
          return _buildTaskItem(task,context);
        },
      );
    });
  }
  
  Widget _buildTaskItem(Task task, context) {
    final isOverdue = !task.isCompleted && task.dueDate.isBefore(DateTime.now());
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Slidable(
        key: Key(task.id),
        endActionPane: ActionPane(
          motion: ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => controller.deleteTask(task.id),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
            ),
          ],
        ),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showTaskDetails(task,context),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            decoration: task.isCompleted 
                                ? TextDecoration.lineThrough 
                                : null,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: controller.getPriorityColor(task.priority),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          controller.getPriorityText(task.priority),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  if (task.description.isNotEmpty) ...[
                    Text(
                      task.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        decoration: task.isCompleted 
                            ? TextDecoration.lineThrough 
                            : null,
                      ),
                    ),
                    SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: isOverdue ? Colors.red : Colors.grey,
                      ),
                      SizedBox(width: 4),
                      Text(
                        controller.formatDate(task.dueDate),
                        style: TextStyle(
                          color: isOverdue ? Colors.red : Colors.grey,
                          decoration: task.isCompleted 
                              ? TextDecoration.lineThrough 
                              : null,
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(
                          task.isCompleted 
                              ? Icons.check_circle 
                              : Icons.radio_button_unchecked,
                          color: task.isCompleted ? Colors.green : Colors.grey,
                        ),
                        onPressed: () => controller.toggleTaskStatus(task as Task),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  void _showAddTaskDialog(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add New Task',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              TextField(
                controller: controller.taskTitleController,
                decoration: InputDecoration(
                  labelText: 'Title*',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: controller.taskDescController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: controller.taskCategoryController,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final selected = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (selected != null) {
                          controller.selectedDate = selected;
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Due Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 20),
                            SizedBox(width: 8),
                            Text(
                              controller.selectedDate != null
                                  ? controller.formatDate(controller.selectedDate!)
                                  : 'Select a date',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: controller.selectedPriority,
                      items: [
                        DropdownMenuItem(
                          value: 1,
                          child: Text('High Priority'),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text('Medium Priority'),
                        ),
                        DropdownMenuItem(
                          value: 3,
                          child: Text('Low Priority'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          controller.selectedPriority = value;
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.addTask,
                  child: Obx(() => controller.isLoading.value
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Add Task')),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
  
  void _showTaskDetails(Task task, context) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 60,
                height: 4,
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              task.title,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            if (task.description.isNotEmpty) ...[
              Text(
                task.description,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
            ],
            Row(
              children: [
                Icon(Icons.category, size: 20, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'Category: ${task.category}',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'Due: ${controller.formatDate(task.dueDate)}',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.priority_high, size: 20, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'Priority: ${controller.getPriorityText(task.priority)}',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle, size: 20, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'Status: ${task.isCompleted ? 'Completed' : 'Pending'}',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            if (task.completedAt != null) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.done_all, size: 20, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    'Completed on: ${controller.formatDate(task.completedAt!)}',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                  controller.toggleTaskStatus(task);
                },
                child: Text(task.isCompleted ? 'Mark as Pending' : 'Mark as Completed'),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}