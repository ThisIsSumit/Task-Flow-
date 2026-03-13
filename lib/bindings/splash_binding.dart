import 'package:get/get.dart';
import '../controllers/splash_controller.dart';
import '../data/services/auth_service.dart';
import '../data/services/cloudinary_service.dart';
import '../data/services/firestore_service.dart';
import '../data/services/local_cache_service.dart';
import '../data/services/notification_service.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(LocalCacheService());
    Get.put(FirestoreService());
    Get.put(AuthService());
    Get.put(CloudinaryService());
    Get.put(NotificationService());
    Get.put(SplashController());
  }
}
