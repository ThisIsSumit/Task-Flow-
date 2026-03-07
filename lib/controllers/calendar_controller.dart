import 'package:get/get.dart';
import '../data/models/task_model.dart';
import '../data/services/auth_service.dart';
import '../data/services/firestore_service.dart';

class CalendarController extends GetxController {
  final FirestoreService _firestoreService = Get.find<FirestoreService>();
  final AuthService _authService = Get.find<AuthService>();

  final RxBool isLoading = false.obs;
  final RxList<Task> tasks = <Task>[].obs;
  final Rx<DateTime> selectedDay = DateTime.now().obs;
  final Rx<DateTime> focusedDay = DateTime.now().obs;

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
        return;
      }

      final fetched = await _firestoreService.getTasks(userId);
      tasks.assignAll(fetched);
    } finally {
      isLoading.value = false;
    }
  }

  List<Task> tasksForDay(DateTime day) {
    return tasks
        .where(
          (task) =>
              task.dueDate.year == day.year &&
              task.dueDate.month == day.month &&
              task.dueDate.day == day.day,
        )
        .toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
  }

  Future<void> moveTask(Task task, DateTime toDay) async {
    final userId = _authService.getUserId();
    if (userId == null) {
      return;
    }

    final updated = task.copyWith(
      dueDate: DateTime(
        toDay.year,
        toDay.month,
        toDay.day,
        task.dueDate.hour,
        task.dueDate.minute,
      ),
    );

    await _firestoreService.updateTask(userId, updated);
    final index = tasks.indexWhere((item) => item.id == task.id);
    if (index != -1) {
      tasks[index] = updated;
    }
    tasks.refresh();
    Get.snackbar('Updated', 'Task moved to selected date');
  }
}
