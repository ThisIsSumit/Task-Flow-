import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/services/auth_service.dart';

class ProfileController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  
  final RxBool isLoading = false.obs;
  
  Future<void> signOut() async {
    try {
      isLoading.value = true;
      await _authService.signOut();
    } catch (e) {
      Get.snackbar('Error', 'Failed to sign out',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }
}