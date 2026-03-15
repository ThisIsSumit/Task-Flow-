import 'package:cloud_functions/cloud_functions.dart';
import 'package:get/get.dart';

import '../models/ai_task_model.dart';

class CopilotService extends GetxService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<CopilotPlanResponse> generatePlan(String instruction) async {
    final callable = _functions.httpsCallable('generateTasksWithAI');
    final response = await callable.call({'instruction': instruction});
    final data = Map<String, dynamic>.from((response.data as Map?) ?? {});

    return CopilotPlanResponse.fromMap(data);
  }
}
