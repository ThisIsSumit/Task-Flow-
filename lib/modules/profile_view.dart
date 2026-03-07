import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todo_app/data/services/auth_service.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(
            () => TextButton.icon(
              onPressed:
                  controller.isLoading.value
                      ? null
                      : () {
                        if (controller.isEditMode.value) {
                          controller.cancelEditing();
                        } else {
                          controller.startEditing();
                        }
                      },
              icon: Icon(
                controller.isEditMode.value ? Icons.close : Icons.edit,
                size: 18,
              ),
              label: Text(controller.isEditMode.value ? 'Cancel' : 'Edit'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(() {
              final user = Get.find<AuthService>().userModel.value;
              if (user == null) {
                return const SizedBox.shrink();
              }

              return Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: theme.colorScheme.primary,
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user.email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            }),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile Details',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: controller.nameController,
                        enabled:
                            controller.isEditMode.value &&
                            !controller.isLoading.value,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue:
                            Get.find<AuthService>().userModel.value?.email ??
                            '',
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: controller.phoneController,
                        enabled:
                            controller.isEditMode.value &&
                            !controller.isLoading.value,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: controller.photoUrlController,
                        enabled:
                            controller.isEditMode.value &&
                            !controller.isLoading.value,
                        decoration: const InputDecoration(
                          labelText: 'Photo URL',
                          prefixIcon: Icon(Icons.link),
                        ),
                      ),
                      if (controller.isEditMode.value) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                controller.isLoading.value
                                    ? null
                                    : controller.saveProfile,
                            icon: const Icon(Icons.save),
                            label:
                                controller.isLoading.value
                                    ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Text('Save Changes'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Obx(
                  () => SwitchListTile(
                    value: controller.themeMode.value == ThemeMode.dark,
                    onChanged: controller.toggleTheme,
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Toggle between light and dark theme'),
                    secondary: const Icon(Icons.dark_mode_outlined),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Obx(
              () => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      controller.isLoading.value ? null : controller.signOut,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child:
                      controller.isLoading.value
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text('Sign Out'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
