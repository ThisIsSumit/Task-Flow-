import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:todo_app/data/models/user_models.dart';
import '../models/task_model.dart';
import 'local_cache_service.dart';

class FirestoreService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalCacheService _cacheService = Get.find<LocalCacheService>();

  @override
  void onInit() {
    super.onInit();
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // User Methods
  Future<void> createUser(UserModel user) async {
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(user.toMap(), SetOptions(merge: true));
  }

  Future<UserModel> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    } else {
      throw Exception('User not found');
    }
  }

  Future<void> updateUserData(UserModel user) async {
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(user.toMap(), SetOptions(merge: true));
  }

  Future<void> updateUserStats(String uid, Map<String, int> stats) async {
    await _firestore.collection('users').doc(uid).update({'taskStats': stats});
  }

  // Task Methods
  Future<List<Task>> getTasks(String uid) async {
    try {
      final snapshot =
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('tasks')
              .orderBy('dueDate')
              .get();

      final tasks =
          snapshot.docs
              .map((doc) => Task.fromMap({...doc.data(), 'id': doc.id}))
              .toList();
      await _cacheService.saveTasks(uid, tasks);
      return tasks;
    } catch (_) {
      return _cacheService.readTasks(uid);
    }
  }

  Future<Task> addTask(String uid, Task task) async {
    final tasksRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('tasks');
    final docRef = task.id.isEmpty ? tasksRef.doc() : tasksRef.doc(task.id);
    final normalized = task.copyWith(id: docRef.id);

    await docRef.set(normalized.toMap());
    return normalized;
  }

  Future<void> updateTask(String uid, Task task) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .doc(task.id)
        .update(task.toMap());
  }

  Future<void> recoverSync() async {
    await _firestore.enableNetwork();
  }

  Future<void> deleteTask(String uid, String taskId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }

  Future<Map<String, dynamic>> getTaskAnalytics(
    String uid, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Get completed tasks for date range
    Query<Map<String, dynamic>> query = _firestore
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .where('isCompleted', isEqualTo: true);

    if (startDate != null) {
      query = query.where(
        'completedAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }

    if (endDate != null) {
      query = query.where(
        'completedAt',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }

    final completedSnapshot = await query.get();
    final completedTasks =
        completedSnapshot.docs.map((doc) => Task.fromMap(doc.data())).toList();

    // Get all tasks
    final allTasksSnapshot =
        await _firestore.collection('users').doc(uid).collection('tasks').get();

    final allTasks =
        allTasksSnapshot.docs.map((doc) => Task.fromMap(doc.data())).toList();

    // Calculate stats
    final totalTasks = allTasks.length;
    final completedCount = completedTasks.length;
    final pendingCount = allTasks.where((task) => !task.isCompleted).length;
    final overdueCount =
        allTasks
            .where(
              (task) =>
                  !task.isCompleted && task.dueDate.isBefore(DateTime.now()),
            )
            .length;

    // Group completed tasks by day
    Map<String, int> completionByDay = {};
    for (var task in completedTasks) {
      final day =
          '${task.completedAt!.day}-${task.completedAt!.month}-${task.completedAt!.year}';
      completionByDay[day] = (completionByDay[day] ?? 0) + 1;
    }

    // Group by category
    Map<String, int> tasksByCategory = {};
    for (var task in allTasks) {
      tasksByCategory[task.category] =
          (tasksByCategory[task.category] ?? 0) + 1;
    }

    return {
      'totalTasks': totalTasks,
      'completed': completedCount,
      'pending': pendingCount,
      'overdue': overdueCount,
      'completionByDay': completionByDay,
      'tasksByCategory': tasksByCategory,
    };
  }
}
