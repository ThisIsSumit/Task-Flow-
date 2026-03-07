import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todo_app/controllers/theme_controller.dart';
import '../data/services/auth_service.dart';

class ProfileController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final ThemeController _themeController = Get.find<ThemeController>();

  final RxBool isLoading = false.obs;
  final RxBool isEditMode = false.obs;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final photoUrlController = TextEditingController();

  Rx<ThemeMode> get themeMode => _themeController.themeMode;
  bool get isDarkMode => _themeController.isDarkMode;

  @override
  void onInit() {
    super.onInit();
    _fillFormFromCurrentUser();
  }

  void _fillFormFromCurrentUser() {
    final user = _authService.userModel.value;
    if (user == null) {
      nameController.clear();
      phoneController.clear();
      photoUrlController.clear();
      return;
    }

    nameController.text = user.name;
    phoneController.text = user.phoneNumber ?? '';
    photoUrlController.text = user.photoUrl ?? '';
  }

  void startEditing() {
    _fillFormFromCurrentUser();
    isEditMode.value = true;
  }

  void cancelEditing() {
    _fillFormFromCurrentUser();
    isEditMode.value = false;
  }

  Future<void> saveProfile() async {
    final user = _authService.userModel.value;
    if (user == null) {
      Get.snackbar(
        'Error',
        'User not found',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final photoUrl = photoUrlController.text.trim();

    if (name.isEmpty) {
      Get.snackbar(
        'Error',
        'Name cannot be empty',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;
      await _authService.updateProfile(
        name: name,
        phoneNumber: phone.isEmpty ? null : phone,
        photoUrl: photoUrl.isEmpty ? null : photoUrl,
      );
      isEditMode.value = false;
      Get.snackbar(
        'Success',
        'Profile updated',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (_) {
      Get.snackbar(
        'Error',
        'Failed to update profile',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleTheme(bool isDark) async {
    await _themeController.setDarkMode(isDark);
  }

  Future<void> signOut() async {
    try {
      isLoading.value = true;
      await _authService.signOut();
    } catch (_) {
      Get.snackbar(
        'Error',
        'Failed to sign out',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    photoUrlController.dispose();
    super.onClose();
  }
}
