import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../data/models/task_model.dart';
import '../data/services/firestore_service.dart';
import '../data/services/auth_service.dart';
import '../data/services/notification_service.dart';

enum TaskSortOption { dueDate, priority, recent }

enum QuickFilter { all, today, thisWeek }

class HomeController extends GetxController {
  final FirestoreService _firestoreService = Get.find<FirestoreService>();
  final AuthService _authService = Get.find<AuthService>();
  final NotificationService _notificationService =
      Get.find<NotificationService>();
  final Uuid _uuid = const Uuid();

  final RxList<Task> tasks = <Task>[].obs;
  final RxList<Task> filteredTasks = <Task>[].obs;
  final RxString selectedCategory = 'All'.obs;
  final RxList<String> categories = <String>['All'].obs;
  final RxBool isLoading = false.obs;
  final RxBool showCompleted = false.obs;

  final RxString searchQuery = ''.obs;
  final Rx<TaskSortOption> sortOption = TaskSortOption.dueDate.obs;
  final Rx<QuickFilter> quickFilter = QuickFilter.all.obs;

  final TextEditingController taskTitleController = TextEditingController();
  final TextEditingController taskDescController = TextEditingController();
  final TextEditingController taskCategoryController = TextEditingController();
  final TextEditingController taskNotesController = TextEditingController();
  final TextEditingController subtaskController = TextEditingController();
  final TextEditingController attachmentLabelController =
      TextEditingController();
  final TextEditingController attachmentUrlController = TextEditingController();

  final RxList<SubTask> draftSubtasks = <SubTask>[].obs;
  final RxList<TaskAttachment> draftAttachments = <TaskAttachment>[].obs;

  final Rx<AttachmentType> selectedAttachmentType = AttachmentType.link.obs;
  final Rx<RecurrenceType> selectedRecurrence = RecurrenceType.none.obs;
  final RxBool reminderEnabled = false.obs;

  DateTime? selectedDate;
  DateTime? selectedReminderDate;
  int selectedPriority = 2;

  @override
  void onInit() {
    super.onInit();
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    try {
      isLoading.value = true;
      final userId = _authService.getUserId();
      if (userId == null) {
        Get.snackbar('Error', 'User not authenticated');
        return;
      }

      await _firestoreService.recoverSync();
      final fetchedTasks = await _firestoreService.getTasks(userId);
      tasks.assignAll(fetchedTasks);

      await _processRecurringTasks(userId);
      _refreshCategoryList();
      filterTasks();
      await _syncUserStats(userId);
      await _notificationService.showOverdue(tasks);
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch tasks: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _refreshCategoryList() {
    final uniqueCategories = <String>{'All'};
    for (final task in tasks) {
      if (task.category.isNotEmpty) {
        uniqueCategories.add(task.category);
      }
    }
    categories.assignAll(uniqueCategories.toList());
  }

  Future<void> _syncUserStats(String userId) async {
    final now = DateTime.now();
    final completed = tasks.where((task) => task.isCompleted).length;
    final pending = tasks.where((task) => !task.isCompleted).length;
    final overdue =
        tasks
            .where((task) => !task.isCompleted && task.dueDate.isBefore(now))
            .length;

    await _firestoreService.updateUserStats(userId, {
      'completed': completed,
      'pending': pending,
      'overdue': overdue,
    });
  }

  void filterTasks() {
    List<Task> result = tasks.toList();

    if (showCompleted.value) {
      result = result.where((task) => task.isCompleted).toList();
    }

    if (selectedCategory.value != 'All') {
      result =
          result
              .where((task) => task.category == selectedCategory.value)
              .toList();
    }

    final query = searchQuery.value.trim().toLowerCase();
    if (query.isNotEmpty) {
      result =
          result
              .where(
                (task) =>
                    task.title.toLowerCase().contains(query) ||
                    task.description.toLowerCase().contains(query) ||
                    task.category.toLowerCase().contains(query) ||
                    task.notes.toLowerCase().contains(query),
              )
              .toList();
    }

    final now = DateTime.now();
    if (quickFilter.value == QuickFilter.today) {
      result =
          result
              .where(
                (task) =>
                    task.dueDate.year == now.year &&
                    task.dueDate.month == now.month &&
                    task.dueDate.day == now.day,
              )
              .toList();
    } else if (quickFilter.value == QuickFilter.thisWeek) {
      final start = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));
      final end = start.add(const Duration(days: 7));
      result =
          result
              .where(
                (task) =>
                    !task.dueDate.isBefore(start) && task.dueDate.isBefore(end),
              )
              .toList();
    }

    if (sortOption.value == TaskSortOption.priority) {
      result.sort((a, b) => a.priority.compareTo(b.priority));
    } else if (sortOption.value == TaskSortOption.recent) {
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      result.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    }

    filteredTasks.assignAll(result);
  }

  void resetTaskForm() {
    taskTitleController.clear();
    taskDescController.clear();
    taskCategoryController.clear();
    taskNotesController.clear();
    subtaskController.clear();
    attachmentLabelController.clear();
    attachmentUrlController.clear();
    draftSubtasks.clear();
    draftAttachments.clear();

    selectedDate = DateTime.now().add(const Duration(days: 1));
    selectedPriority = 2;
    selectedRecurrence.value = RecurrenceType.none;
    reminderEnabled.value = false;
    selectedReminderDate = null;
    selectedAttachmentType.value = AttachmentType.link;
    update();
  }

  void prepareTaskForm(Task task) {
    taskTitleController.text = task.title;
    taskDescController.text = task.description;
    taskCategoryController.text = task.category;
    taskNotesController.text = task.notes;
    draftSubtasks.assignAll(task.subtasks);
    draftAttachments.assignAll(task.attachments);

    selectedDate = task.dueDate;
    selectedPriority = task.priority;
    selectedRecurrence.value = task.recurrence;
    reminderEnabled.value = task.reminderEnabled;
    selectedReminderDate = task.reminderAt;
    selectedAttachmentType.value = AttachmentType.link;
    update();
  }

  void addDraftSubtask() {
    final title = subtaskController.text.trim();
    if (title.isEmpty) {
      return;
    }

    draftSubtasks.add(SubTask(id: _uuid.v4(), title: title));
    subtaskController.clear();
    update();
  }

  void removeDraftSubtask(String subtaskId) {
    draftSubtasks.removeWhere((item) => item.id == subtaskId);
    update();
  }

  void addDraftAttachment() {
    final label = attachmentLabelController.text.trim();
    final url = attachmentUrlController.text.trim();
    if (url.isEmpty) {
      return;
    }

    draftAttachments.add(
      TaskAttachment(
        id: _uuid.v4(),
        label: label.isEmpty ? 'Attachment' : label,
        url: url,
        type: selectedAttachmentType.value,
      ),
    );

    attachmentLabelController.clear();
    attachmentUrlController.clear();
    update();
  }

  void removeDraftAttachment(String attachmentId) {
    draftAttachments.removeWhere((item) => item.id == attachmentId);
    update();
  }

  Future<void> addTask() async {
    if (taskTitleController.text.trim().isEmpty) {
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

      final task = Task(
        id: '',
        title: taskTitleController.text.trim(),
        description: taskDescController.text.trim(),
        category:
            taskCategoryController.text.trim().isEmpty
                ? 'Personal'
                : taskCategoryController.text.trim(),
        priority: selectedPriority,
        dueDate: selectedDate!,
        isCompleted: false,
        createdAt: DateTime.now(),
        userId: userId,
        notes: taskNotesController.text.trim(),
        recurrence: selectedRecurrence.value,
        reminderEnabled: reminderEnabled.value,
        reminderAt: selectedReminderDate,
        subtasks: draftSubtasks.toList(),
        attachments: draftAttachments.toList(),
      );

      final saved = await _firestoreService.addTask(userId, task);
      tasks.add(saved);
      _refreshCategoryList();
      filterTasks();

      if (saved.reminderEnabled) {
        await _notificationService.scheduleReminder(saved);
      }

      await _syncUserStats(userId);

      Get.back();
      resetTaskForm();
      Get.snackbar('Success', 'Task added successfully');
    } catch (e) {
      Get.log(
        'Error'
        'Failed to add task: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateTask(Task existingTask) async {
    if (taskTitleController.text.trim().isEmpty || selectedDate == null) {
      Get.snackbar('Error', 'Title and due date are required');
      return;
    }

    isLoading.value = true;
    try {
      final userId = _authService.getUserId();
      if (userId == null) {
        Get.snackbar('Error', 'User not authenticated');
        return;
      }

      final updated = existingTask.copyWith(
        title: taskTitleController.text.trim(),
        description: taskDescController.text.trim(),
        category: taskCategoryController.text.trim(),
        priority: selectedPriority,
        dueDate: selectedDate,
        notes: taskNotesController.text.trim(),
        recurrence: selectedRecurrence.value,
        reminderEnabled: reminderEnabled.value,
        reminderAt: selectedReminderDate,
        subtasks: draftSubtasks.toList(),
        attachments: draftAttachments.toList(),
      );

      await _firestoreService.updateTask(userId, updated);
      final index = tasks.indexWhere((task) => task.id == existingTask.id);
      if (index != -1) {
        tasks[index] = updated;
      }

      if (updated.reminderEnabled) {
        await _notificationService.scheduleReminder(updated);
      } else {
        await _notificationService.cancelReminder(updated);
      }

      _refreshCategoryList();
      filterTasks();
      await _syncUserStats(userId);
      Get.back();
      Get.snackbar('Success', 'Task updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update task: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteTask(String taskId) async {
    isLoading.value = true;
    try {
      final userId = _authService.getUserId();
      if (userId == null) {
        Get.snackbar('Error', 'User not authenticated');
        return;
      }

      final task = tasks.firstWhereOrNull((item) => item.id == taskId);
      await _firestoreService.deleteTask(userId, taskId);
      tasks.removeWhere((item) => item.id == taskId);

      if (task != null) {
        await _notificationService.cancelReminder(task);
      }

      _refreshCategoryList();
      filterTasks();
      await _syncUserStats(userId);
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

      final updated = task.copyWith(
        isCompleted: !task.isCompleted,
        completedAt: !task.isCompleted ? DateTime.now() : null,
        lastRecurrenceAt:
            !task.isCompleted ? DateTime.now() : task.lastRecurrenceAt,
      );

      await _firestoreService.updateTask(userId, updated);
      final index = tasks.indexWhere((item) => item.id == task.id);
      if (index != -1) {
        tasks[index] = updated;
      }

      if (updated.isCompleted) {
        await _createNextRecurringTaskIfNeeded(userId, updated);
      }

      filterTasks();
      await _syncUserStats(userId);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update task status: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleSubtask(Task task, SubTask subTask) async {
    try {
      final userId = _authService.getUserId();
      if (userId == null) {
        return;
      }

      final updatedSubtasks =
          task.subtasks
              .map(
                (item) =>
                    item.id == subTask.id
                        ? item.copyWith(isDone: !item.isDone)
                        : item,
              )
              .toList();

      final updated = task.copyWith(subtasks: updatedSubtasks);
      await _firestoreService.updateTask(userId, updated);

      final index = tasks.indexWhere((item) => item.id == task.id);
      if (index != -1) {
        tasks[index] = updated;
      }
      filterTasks();
    } catch (e) {
      Get.snackbar('Error', 'Failed to update checklist: $e');
    }
  }

  Future<void> rescheduleTask(Task task, DateTime newDate) async {
    try {
      final userId = _authService.getUserId();
      if (userId == null) {
        return;
      }

      final updated = task.copyWith(dueDate: newDate);
      await _firestoreService.updateTask(userId, updated);
      final index = tasks.indexWhere((item) => item.id == task.id);
      if (index != -1) {
        tasks[index] = updated;
      }

      if (updated.reminderEnabled) {
        await _notificationService.scheduleReminder(updated);
      }

      filterTasks();
      await _syncUserStats(userId);
      Get.snackbar('Success', 'Task rescheduled');
    } catch (e) {
      Get.snackbar('Error', 'Failed to reschedule task: $e');
    }
  }

  Future<void> _processRecurringTasks(String userId) async {
    for (final task in tasks) {
      if (task.isCompleted && task.recurrence != RecurrenceType.none) {
        await _createNextRecurringTaskIfNeeded(userId, task);
      }
    }
  }

  Future<void> _createNextRecurringTaskIfNeeded(
    String userId,
    Task source,
  ) async {
    if (source.recurrence == RecurrenceType.none || !source.isCompleted) {
      return;
    }

    final nextDueDate = _nextDateForRecurrence(
      source.dueDate,
      source.recurrence,
    );
    final alreadyExists = tasks.any(
      (task) =>
          task.title == source.title &&
          task.category == source.category &&
          !task.isCompleted &&
          task.dueDate.year == nextDueDate.year &&
          task.dueDate.month == nextDueDate.month &&
          task.dueDate.day == nextDueDate.day,
    );

    if (alreadyExists) {
      return;
    }

    final nextTask = source.copyWith(
      id: '',
      isCompleted: false,
      completedAt: null,
      dueDate: nextDueDate,
      createdAt: DateTime.now(),
      lastRecurrenceAt: DateTime.now(),
      subtasks:
          source.subtasks.map((item) => item.copyWith(isDone: false)).toList(),
    );

    final saved = await _firestoreService.addTask(userId, nextTask);
    tasks.add(saved);
  }

  DateTime _nextDateForRecurrence(
    DateTime fromDate,
    RecurrenceType recurrenceType,
  ) {
    switch (recurrenceType) {
      case RecurrenceType.daily:
        return fromDate.add(const Duration(days: 1));
      case RecurrenceType.weekly:
        return fromDate.add(const Duration(days: 7));
      case RecurrenceType.monthly:
        return DateTime(fromDate.year, fromDate.month + 1, fromDate.day);
      case RecurrenceType.none:
        return fromDate;
    }
  }

  String formatDate(DateTime date) => DateFormat('MMM dd, yyyy').format(date);

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
