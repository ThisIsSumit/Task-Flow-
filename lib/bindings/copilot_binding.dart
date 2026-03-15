import 'package:get/get.dart';

import '../features/copilot/controllers/copilot_controller.dart';
import '../features/copilot/services/copilot_service.dart';

class CopilotBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CopilotService(), fenix: true);
    Get.lazyPut(() => CopilotController(), fenix: true);
  }
}
