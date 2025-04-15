import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/services/firestore_service.dart';
import '../data/services/auth_service.dart';

class AnalyticsController extends GetxController {
  final FirestoreService _firestoreService = Get.find<FirestoreService>();
  final AuthService _authService = Get.find<AuthService>();
  
  final RxMap<String, dynamic> analyticsData = <String, dynamic>{}.obs;
  final RxBool isLoading = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    fetchAnalytics();
  }
  
  Future<void> fetchAnalytics() async {
    try {
      isLoading.value = true;
      final userId = _authService.getUserId();
      if (userId != null) {
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        
        final data = await _firestoreService.getTaskAnalytics(
          userId,
          startDate: startOfWeek,
          endDate: now,
        );
        
        analyticsData.value = data;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch analytics',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }
}