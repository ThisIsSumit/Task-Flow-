import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todo_app/routes/app_pages.dart';
import '../data/services/auth_service.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  final RxBool isLogin = true.obs;
  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;
  final RxBool isPhoneAuth = false.obs;
  final RxBool isOtpSent = false.obs;
  final RxString verificationId = ''.obs;
  final RxString countryCode = '+1'.obs; // Default country code
  final RxString phoneNumber = ''.obs; // Just the number part

  void toggleAuthMode() {
    isLogin.toggle();
    clearControllers();
  }

  void togglePasswordVisibility() {
    obscurePassword.toggle();
  }

  void toggleAuthMethod() {
    isPhoneAuth.toggle();
    isOtpSent.value = false; // Reset OTP state when switching auth methods
    clearControllers();
  }

  void updateCountryCode(String code) {
    countryCode.value = code;
  }

  void updatePhoneNumber(String number) {
    phoneNumber.value = number;
  }

  void clearControllers() {
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    phoneController.clear();
    otpController.clear();
    phoneNumber.value = '';
  }

  Future<void> sendOtp() async {
    if (phoneNumber.value.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your phone number',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;
      final fullPhoneNumber = '${countryCode.value}${phoneNumber.value}';
      await _authService.sendOtp(fullPhoneNumber);
      isOtpSent.value = true;
      Get.snackbar(
        'Success',
        'OTP sent successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send OTP. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOtp() async {
    if (otpController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter the OTP',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;
      final otp = otpController.text.trim();
      await _authService.verifyOtp(otp);
      Get.snackbar(
        'Success',
        'Phone number verified successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Get.offAllNamed(Routes.HOME);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Invalid OTP. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> handleAuth() async {
    if (isPhoneAuth.value) {
      if (!isOtpSent.value) {
        await sendOtp();
      } else {
        await verifyOtp();
      }
      return;
    }

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // Basic validation
    if (email.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill all the required fields',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (!isLogin.value && nameController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your name',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;

      if (isLogin.value) {
        await _authService.signIn(email, password);
      } else {
        final name = nameController.text.trim();
        await _authService.signUp(name, email, password);
      }

      clearControllers();
      Get.offAllNamed(Routes.HOME);
    } catch (e) {
      String errorMessage = 'An error occurred. Please try again.';

      if (e.toString().contains('user-not-found')) {
        errorMessage = 'No user found with this email.';
      } else if (e.toString().contains('wrong-password')) {
        errorMessage = 'Invalid password.';
      } else if (e.toString().contains('email-already-in-use')) {
        errorMessage = 'This email is already registered.';
      } else if (e.toString().contains('weak-password')) {
        errorMessage = 'Password is too weak.';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Invalid email format.';
      }

      Get.snackbar(
        'Error',
        errorMessage,
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
    // Commented out to let GetX handle disposal
    // nameController.dispose();
    // emailController.dispose();
    // passwordController.dispose();
    // phoneController.dispose();
    // otpController.dispose();
    super.onClose();
  }
}
