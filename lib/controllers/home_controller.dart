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
  final RxBool isLoading = false.obs;
  final RxBool showCompleted = false.obs;
  
  final TextEditingController taskTitleController = TextEditingController();
  final TextEditingController taskDescController = TextEditingController();
  final TextEditingController taskCategoryController = TextEditingController();
  
  DateTime? selectedDate;
  int selectedPriority = 2; // Medium by default
  
  @override
  void onInit() {
    super.onInit();
    fetchTasks();
  }
  
  Future<void> fetchTasks() async {
    try {
      isLoading.value = true;
      final userId = _authService.getUserId();
      if (userId != null) {
        final taskList = await _firestoreService.getTasks(userId);
        tasks.assignAll(taskList);
        filterTasks();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch tasks',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }
  
  void filterTasks() {
    if (selectedCategory.value == 'All') {
      filteredTasks.assignAll(tasks.where((task) => showCompleted.value ? true : !task.isCompleted));
    } else {
      filteredTasks.assignAll(tasks.where((task) => 
          task.category == selectedCategory.value && 
          (showCompleted.value ? true : !task.isCompleted)));
    }
    
    // Sort by priority and due date
    filteredTasks.sort((a, b) {
      if (a.priority != b.priority) {
        return a.priority.compareTo(b.priority); // Lower number = higher priority
      }
      return a.dueDate.compareTo(b.dueDate);
    });
  }
  
  List<String> get categories {
    final allCategories = tasks.map((task) => task.category).toSet().toList();
    return ['All', ...allCategories];
  }
  
  Future<void> addTask() async {
    if (taskTitleController.text.isEmpty) {
      Get.snackbar('Error', 'Title is required',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }
    
    try {
      isLoading.value = true;
      final userId = _authService.getUserId();
      if (userId != null) {
        final newTask = Task(
          title: taskTitleController.text,
          description: taskDescController.text,
          dueDate: selectedDate ?? DateTime.now().add(Duration(days: 1)),
          category: taskCategoryController.text.isEmpty 
              ? 'General' 
              : taskCategoryController.text,
          priority: selectedPriority,
        );
        
        await _firestoreService.addTask(userId, newTask);
        await fetchTasks();
        
        Get.back(); // Close the add task dialog
        Get.snackbar('Success', 'Task added successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white);
        
        // Reset form
        taskTitleController.clear();
        taskDescController.clear();
        taskCategoryController.clear();
        selectedDate = null;
        selectedPriority = 2;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to add task',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> toggleTaskStatus(Task task) async {
    try {
      isLoading.value = true;
      final userId = _authService.getUserId();
      if (userId != null) {
        final updatedTask = task.copyWith(
          isCompleted: !task.isCompleted,
          completedAt: !task.isCompleted ? DateTime.now() : null,
        );
        
        await _firestoreService.updateTask(userId, updatedTask);
        await fetchTasks();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update task',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> deleteTask(String taskId) async {
    try {
      isLoading.value = true;
      final userId = _authService.getUserId();
      if (userId != null) {
        await _firestoreService.deleteTask(userId, taskId);
        await fetchTasks();
        
        Get.snackbar('Success', 'Task deleted successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete task',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }
  
  String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }
  
  Color getPriorityColor(int priority) {
    switch (priority) {
      case 1: return Colors.red;
      case 2: return Colors.orange;
      case 3: return Colors.green;
      default: return Colors.grey;
    }
  }
  
  String getPriorityText(int priority) {
    switch (priority) {
      case 1: return 'High';
      case 2: return 'Medium';
      case 3: return 'Low';
      default: return 'Unknown';
    }
  }
  
  @override
  void onClose() {
    taskTitleController.dispose();
    taskDescController.dispose();
    taskCategoryController.dispose();
    super.onClose();
  }
}