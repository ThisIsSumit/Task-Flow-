import 'package:get/get.dart';
import 'package:todo_app/routes/app_pages.dart';
import '../data/services/auth_service.dart';
import '../data/services/notification_service.dart';

class SplashController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final NotificationService _notificationService =
      Get.find<NotificationService>();

  @override
  void onInit() {
    super.onInit();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await _notificationService.init();
    await Future.delayed(Duration(seconds: 3));
    if (_authService.isLoggedIn()) {
      Get.offAllNamed(Routes.HOME);
    } else {
      Get.offAllNamed(Routes.AUTH);
    }
  }
}
