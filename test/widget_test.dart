// Smoke test: the app boots to its launch screen without throwing.
//
// (The previous default "counter increments" template test was left over
// from `flutter create` and never matched this app — it has been removed.)

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budget_app_project/main.dart';
import 'package:budget_app_project/services/app_settings.dart';

void main() {
  testWidgets('App boots without errors', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await AppSettings.instance.load();

    await tester.pumpWidget(const BudgetTreeApp());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(WidgetsApp), findsOneWidget);
  });
}
