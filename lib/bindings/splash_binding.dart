import 'package:get/get.dart';
import '../controllers/splash_controller.dart';
import '../data/services/auth_service.dart';
import '../data/services/firestore_service.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(FirestoreService());
    Get.put(AuthService());
    Get.put(SplashController());
  }
}