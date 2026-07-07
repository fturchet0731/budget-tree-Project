// The tutorial coach on the Create screen: every line shows the localized
// tap-to-continue hint, and a line with a highlightId draws the ring around
// its registered target widget (the income add box on the Seed step).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budget_app_project/l10n/app_localizations.dart';
import 'package:budget_app_project/screens/createbudget_screen.dart';
import 'package:budget_app_project/services/app_settings.dart';
import 'package:budget_app_project/widgets/acorn_coach.dart';

void main() {
  testWidgets('tutorial coach shows continue hint and highlight ring',
      (tester) async {
    SharedPreferences.setMockInitialValues({'settings_motion_v1': false});
    await AppSettings.instance.load();

    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CreateBudgetScreen(tutorial: true),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));

    // The coach is riding along, its first line typed out, with the same
    // localized tap-to-continue hint the full-screen tutorial uses.
    expect(find.byType(AcornCoach), findsOneWidget);
    expect(find.text('Tap to continue'), findsOneWidget);
    expect(find.byType(TargetHighlightRing), findsNothing);

    // Advance to the second line, which points at the income add box.
    await tester.tap(find.text('Tap to continue'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(TargetHighlightRing), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
