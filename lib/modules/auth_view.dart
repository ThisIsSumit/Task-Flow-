import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../controllers/auth_controller.dart';

class AuthView extends GetView<AuthController> {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final inputFillColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.12) : Colors.white;
    final inputTextColor = isDarkMode ? Colors.white : Colors.black87;
    final inputLabelColor = isDarkMode ? Colors.white70 : Colors.black54;
    final inputIconColor = isDarkMode ? Colors.white70 : Colors.black54;
    final inputBorderColor = isDarkMode ? Colors.white70 : Colors.black26;

    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.check_circle_outline,
                              size: 50,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'TaskFlow',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    controller.isLogin.value
                        ? 'Welcome Back'
                        : 'Create Account',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.isLogin.value
                        ? 'Sign in to continue'
                        : 'Get started with TaskFlow',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Toggle Auth Method
                  Center(
                    child: TextButton(
                      onPressed: controller.toggleAuthMethod,
                      child: Text(
                        controller.isPhoneAuth.value
                            ? 'Use Email & Password'
                            : 'Use Phone Number',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Phone Auth Fields
                  Obx(
                    () =>
                        controller.isPhoneAuth.value
                            ? Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: inputFillColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: inputBorderColor),
                                  ),
                                  child: IntlPhoneField(
                                    controller: controller.phoneController,
                                    keyboardType: TextInputType.phone,
                                    disableLengthCheck: true,
                                    dropdownIcon: Icon(
                                      Icons.arrow_drop_down,
                                      color: inputIconColor,
                                    ),
                                    style: TextStyle(color: inputTextColor),
                                    decoration: InputDecoration(
                                      labelText: 'Phone Number',
                                      labelStyle: TextStyle(
                                        color: inputLabelColor,
                                      ),
                                      filled: true,
                                      fillColor: Colors.transparent,
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 15,
                                          ),
                                    ),
                                    initialCountryCode: 'IN',
                                    onChanged: (phone) {
                                      controller.countryCode.value =
                                          phone.countryCode;
                                      controller.phoneNumber.value =
                                          phone.number;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Obx(
                                  () =>
                                      controller.isOtpSent.value
                                          ? TextFormField(
                                            controller:
                                                controller.otpController,
                                            keyboardType: TextInputType.number,
                                            style: TextStyle(
                                              color: inputTextColor,
                                            ),
                                            decoration: InputDecoration(
                                              labelText: 'OTP',
                                              filled: true,
                                              fillColor: inputFillColor,
                                              labelStyle: TextStyle(
                                                color: inputLabelColor,
                                              ),
                                              prefixIcon: Icon(
                                                Icons.lock,
                                                color: inputIconColor,
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: inputBorderColor,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color:
                                                      theme.colorScheme.primary,
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          )
                                          : const SizedBox.shrink(),
                                ),
                              ],
                            )
                            : Column(
                              children: [
                                // Name Field (only visible in sign up)
                                Obx(
                                  () =>
                                      !controller.isLogin.value
                                          ? Column(
                                            children: [
                                              TextFormField(
                                                controller:
                                                    controller.nameController,
                                                style: TextStyle(
                                                  color: inputTextColor,
                                                ),
                                                decoration: InputDecoration(
                                                  labelText: 'Full Name',
                                                  filled: true,
                                                  fillColor: inputFillColor,
                                                  labelStyle: TextStyle(
                                                    color: inputLabelColor,
                                                  ),
                                                  prefixIcon: Icon(
                                                    Icons.person,
                                                    color: inputIconColor,
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color:
                                                              inputBorderColor,
                                                        ),
                                                      ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color:
                                                              theme
                                                                  .colorScheme
                                                                  .primary,
                                                          width: 2,
                                                        ),
                                                      ),
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                            ],
                                          )
                                          : const SizedBox.shrink(),
                                ),
                                // Email Field
                                TextFormField(
                                  controller: controller.emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: TextStyle(color: inputTextColor),
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    filled: true,
                                    fillColor: inputFillColor,
                                    labelStyle: TextStyle(
                                      color: inputLabelColor,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.email,
                                      color: inputIconColor,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: inputBorderColor,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: theme.colorScheme.primary,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Password Field
                                Obx(
                                  () => TextFormField(
                                    controller: controller.passwordController,
                                    obscureText:
                                        controller.obscurePassword.value,
                                    style: TextStyle(color: inputTextColor),
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      filled: true,
                                      fillColor: inputFillColor,
                                      labelStyle: TextStyle(
                                        color: inputLabelColor,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.lock,
                                        color: inputIconColor,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          controller.obscurePassword.value
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: inputIconColor,
                                        ),
                                        onPressed:
                                            controller.togglePasswordVisibility,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: inputBorderColor,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: theme.colorScheme.primary,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Obx(
                                  () =>
                                      controller.isLogin.value
                                          ? Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton(
                                              onPressed:
                                                  controller.isLoading.value
                                                      ? null
                                                      : controller
                                                          .forgotPassword,
                                              child: const Text(
                                                'Forgot Password?',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          )
                                          : const SizedBox.shrink(),
                                ),
                              ],
                            ),
                  ),
                  const SizedBox(height: 40),
                  // Submit Button
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            controller.isLoading.value
                                ? null
                                : controller.handleAuth,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.white,
                          foregroundColor: theme.colorScheme.primary,
                          elevation: 0,
                        ),
                        child:
                            controller.isLoading.value
                                ? CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.colorScheme.primary,
                                  ),
                                )
                                : Text(
                                  controller.isPhoneAuth.value
                                      ? (controller.isOtpSent.value
                                          ? 'Verify OTP'
                                          : 'Send OTP')
                                      : (controller.isLogin.value
                                          ? 'Sign In'
                                          : 'Sign Up'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Toggle Auth Mode
                  Obx(
                    () =>
                        !controller.isPhoneAuth.value
                            ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  controller.isLogin.value
                                      ? "Don't have an account?"
                                      : "Already have an account?",
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                                TextButton(
                                  onPressed: controller.toggleAuthMode,
                                  child: Text(
                                    controller.isLogin.value
                                        ? 'Sign Up'
                                        : 'Sign In',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            )
                            : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
