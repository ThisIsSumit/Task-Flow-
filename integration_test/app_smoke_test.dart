import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:todo_app/modules/splash_view.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App smoke: splash screen loads correctly', (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: SplashView()));

    await tester.pumpAndSettle();

    expect(find.text('TaskFlow'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });
}
