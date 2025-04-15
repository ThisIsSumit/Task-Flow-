import 'package:get/get.dart';
import '../bindings/analytics_binding.dart';
import '../modules/analytics_view.dart';
import '../bindings/auth_binding.dart';
import '../modules/auth_view.dart';
import '../bindings/home_binding.dart';
import '../modules/home_view.dart';
import '../bindings/profile_binding.dart';
import '../modules/profile_view.dart';
import '../bindings/splash_binding.dart';
import '../modules/splash_view.dart';

part 'app_routes.dart';

class AppPages {
  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: Routes.SPLASH,
      page: () => SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: Routes.AUTH,
      page: () => AuthView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.HOME,
      page: () => HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: Routes.PROFILE,
      page: () => ProfileView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: Routes.ANALYTICS,
      page: () => AnalyticsView(),
      binding: AnalyticsBinding(),
    ),
  ];
}