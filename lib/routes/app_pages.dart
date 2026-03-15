import 'package:get/get.dart';
import '../bindings/analytics_binding.dart';
import '../bindings/copilot_binding.dart';
import '../modules/analytics_view.dart';
import '../bindings/auth_binding.dart';
import '../modules/auth_view.dart';
import '../bindings/home_binding.dart';
import '../features/copilot/screens/copilot_input_screen.dart';
import '../features/copilot/screens/copilot_preview_screen.dart';
import '../modules/home_view.dart';
import '../bindings/calendar_binding.dart';
import '../modules/calendar_view.dart';
import '../bindings/profile_binding.dart';
import '../modules/profile_view.dart';
import '../bindings/splash_binding.dart';
import '../modules/splash_view.dart';
import '../modules/subscription_view.dart';
import '../modules/automation_view.dart';

part 'app_routes.dart';

class AppPages {
  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: Routes.SPLASH,
      page: () => SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(name: Routes.AUTH, page: () => AuthView(), binding: AuthBinding()),
    GetPage(name: Routes.HOME, page: () => HomeView(), binding: HomeBinding()),
    GetPage(
      name: Routes.CALENDAR,
      page: () => CalendarView(),
      binding: CalendarBinding(),
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
    GetPage(name: Routes.SUBSCRIPTION, page: () => const SubscriptionView()),
    GetPage(name: Routes.AUTOMATION, page: () => const AutomationView()),
    GetPage(
      name: Routes.COPILOT_INPUT,
      page: () => const CopilotInputScreen(),
      binding: CopilotBinding(),
    ),
    GetPage(
      name: Routes.COPILOT_PREVIEW,
      page: () => const CopilotPreviewScreen(),
      binding: CopilotBinding(),
    ),
  ];
}
