import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../data/models/task_model.dart';
import '../data/services/firestore_service.dart';
import '../data/services/auth_service.dart';

class HomeController extends GetxController {
  final FirestoreService _firestoreService = Get.find<FirestoreService>();
  final AuthService _authService = Get.find<AuthService>();

  final RxList<Task> tasks = <Task>[].obs;
  final RxList<Task> filteredTasks = <Task>[].obs;
  final RxString selectedCategory = 'All'.obs;
  final RxList<String> categories = <String>['All'].obs;
  final RxBool isLoading = false.obs;
  final RxBool showCompleted = true.obs;

  final TextEditingController taskTitleController = TextEditingController();
  final TextEditingController taskDescController = TextEditingController();
  final TextEditingController taskCategoryController = TextEditingController();

  DateTime? selectedDate;
  int selectedPriority = 2;

  @override
  void onInit() {
    super.onInit();
    fetchTasks();
  }

  // @override
  // void onClose() {
  //   taskTitleController.dispose();
  //   taskDescController.dispose();
  //   taskCategoryController.dispose();
  //   super.onClose();
  // }

  Future<void> fetchTasks() async {
    try {
      isLoading.value = true;
      final userId = _authService.getUserId();
      if (userId == null) {
        Get.snackbar('Error', 'User not authenticated');
        return;
      }

      final List<Task> fetchedTasks = await _firestoreService.getTasks(userId);
      tasks.value = fetchedTasks;

      // Extract unique categories
      final Set<String> uniqueCategories = {'All'};
      for (var task in tasks) {
        if (task.category.isNotEmpty) {
          uniqueCategories.add(task.category);
        }
      }
      categories.value = uniqueCategories.toList();

      filterTasks();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch tasks: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void filterTasks() {
    if (selectedCategory.value == 'All') {
      filteredTasks.value =
          tasks
              .where((task) => showCompleted.value ? true : !task.isCompleted)
              .toList();
    } else {
      filteredTasks.value =
          tasks
              .where(
                (task) =>
                    task.category == selectedCategory.value &&
                    (showCompleted.value ? true : !task.isCompleted),
              )
              .toList();
    }

    filteredTasks.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      return a.dueDate.compareTo(b.dueDate);
    });
  }

  Future<void> addTask() async {
    if (taskTitleController.text.isEmpty) {
      Get.snackbar('Error', 'Task title cannot be empty');
      return;
    }

    if (selectedDate == null) {
      Get.snackbar('Error', 'Please select a due date');
      return;
    }

    isLoading.value = true;
    try {
      final userId = _authService.getUserId();
      if (userId == null) {
        Get.snackbar('Error', 'User not authenticated');
        return;
      }
      final newTask = Task(
        id: '',
        title: taskTitleController.text,
        description: taskDescController.text,
        category:
            taskCategoryController.text.isEmpty
                ? 'Personal'
                : taskCategoryController.text,
        priority: selectedPriority,
        dueDate: selectedDate!,
        isCompleted: false,
        createdAt: DateTime.now(),
        userId: userId,
      );

      await _firestoreService.addTask(userId, newTask);
      tasks.add(newTask);

      if (!categories.contains(newTask.category)) {
        categories.add(newTask.category);
      }

      taskTitleController.clear();
      taskDescController.clear();
      taskCategoryController.clear();
      selectedDate = null;
      selectedPriority = 2;

      filterTasks();
      Get.back();
      Get.snackbar('Success', 'Task added successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to add task: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateTask(Task oldTask) async {
    if (taskTitleController.text.isEmpty) {
      Get.snackbar('Error', 'Task title cannot be empty');
      return;
    }

    if (selectedDate == null) {
      Get.snackbar('Error', 'Please select a due date');
      return;
    }

    isLoading.value = true;
    try {
      final userId = _authService.getUserId();
      if (userId == null) {
        Get.snackbar('Error', 'User not authenticated');
        return;
      }
      final updatedTask = Task(
        id: oldTask.id,
        title: taskTitleController.text,
        description: taskDescController.text,
        category: taskCategoryController.text,
        priority: selectedPriority,
        dueDate: selectedDate!,
        isCompleted: oldTask.isCompleted,
        completedAt: oldTask.completedAt,
        createdAt: oldTask.createdAt,
        userId: oldTask.userId,
      );

      await _firestoreService.updateTask(userId, updatedTask);

      final index = tasks.indexWhere((task) => task.id == oldTask.id);
      if (index != -1) {
        tasks[index] = updatedTask;
      }

      if (!categories.contains(updatedTask.category)) {
        categories.add(updatedTask.category);
      }

      filterTasks();
      Get.back();
      Get.snackbar('Success', 'Task updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update task: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteTask(String taskId) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Delete Task'),
        content: Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    isLoading.value = true;
    try {
      final userId = _authService.getUserId();
      if (userId == null) {
        Get.snackbar('Error', 'User not authenticated');
        return;
      }
      await _firestoreService.deleteTask(userId, taskId);
      tasks.removeWhere((task) => task.id == taskId);

      final Set<String> uniqueCategories = {'All'};
      for (var task in tasks) {
        if (task.category.isNotEmpty) {
          uniqueCategories.add(task.category);
        }
      }
      categories.value = uniqueCategories.toList();

      filterTasks();
      Get.snackbar('Success', 'Task deleted successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete task: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleTaskStatus(Task task) async {
    isLoading.value = true;
    try {
      final userId = _authService.getUserId();
      if (userId == null) {
        Get.snackbar('Error', 'User not authenticated');
        return;
      }
      final updatedTask = task.copyWith(
        isCompleted: !task.isCompleted,
        completedAt: !task.isCompleted ? DateTime.now() : null,
      );

      await _firestoreService.updateTask(userId, updatedTask);

      final index = tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        tasks[index] = updatedTask;
      }

      filterTasks();
      Get.snackbar(
        'Success',
        'Task marked as ${updatedTask.isCompleted ? 'completed' : 'pending'}',
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to update task status: $e');
    } finally {
      isLoading.value = false;
    }
  }

  String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String getPriorityText(int priority) {
    switch (priority) {
      case 1:
        return 'High';
      case 2:
        return 'Medium';
      case 3:
        return 'Low';
      default:
        return 'Medium';
    }
  }

  Color getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.green;
      default:
        return Colors.orange;
    }
  }
}
