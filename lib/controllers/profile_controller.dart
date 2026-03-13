import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:todo_app/controllers/theme_controller.dart';
import '../data/services/auth_service.dart';
import '../data/services/cloudinary_service.dart';

class ProfileController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final ThemeController _themeController = Get.find<ThemeController>();
  final CloudinaryService _cloudinaryService = Get.find<CloudinaryService>();
  final ImagePicker _imagePicker = ImagePicker();

  final RxBool isLoading = false.obs;
  final RxBool isEditMode = false.obs;
  final RxBool isUploadingPhoto = false.obs;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  Rx<ThemeMode> get themeMode => _themeController.themeMode;
  bool get isDarkMode => _themeController.isDarkMode;
  bool get isProfileComplete {
    final photoUrl = _authService.userModel.value?.photoUrl;
    return photoUrl != null && photoUrl.trim().isNotEmpty;
  }

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
      return;
    }

    nameController.text = user.name;
    phoneController.text = user.phoneNumber ?? '';
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
        photoUrl: user.photoUrl,
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

  Future<void> pickAndUploadProfilePhoto() async {
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

    try {
      isUploadingPhoto.value = true;
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (picked == null) {
        return;
      }

      final bytes = await picked.readAsBytes();
      final uploadedUrl = await _cloudinaryService.uploadProfileImage(
        bytes: bytes,
        fileName: picked.name,
      );

      await _authService.updateProfile(
        name: user.name,
        phoneNumber: user.phoneNumber,
        photoUrl: uploadedUrl,
      );
      update();

      Get.snackbar(
        'Success',
        'Profile photo updated',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to upload photo: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isUploadingPhoto.value = false;
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
    super.onClose();
  }
}
