// The tutorial overlay's two exits must stay distinct: the red top-right
// button abandons the whole tour, the blue one beside the bubble skips only the
// current section. They used to be one overloaded "Skip" whose meaning depended
// on where in the tour it appeared.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budget_app_project/l10n/app_localizations.dart';
import 'package:budget_app_project/tutorial/tutorial_content.dart';
import 'package:budget_app_project/services/app_settings.dart';
import 'package:budget_app_project/tutorial/tutorial_overlay.dart';

Widget _host({required Widget child}) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

void main() {
  // Acorn sways forever with motion on, which would hang pumpAndSettle, so the
  // suite runs with reduced motion (the same trick acorn_coach_highlight uses).
  setUp(() async {
    SharedPreferences.setMockInitialValues({'settings_motion_v1': false});
    await AppSettings.instance.load();
  });

  final steps = [
    const TutorialStep('First line'),
    const TutorialStep('Second line'),
  ];

  testWidgets('a tour dialog offers both exits', (tester) async {
    await tester.pumpWidget(_host(
      child: TutorialOverlay(
        steps: steps,
        cancelLabel: 'Cancel tour',
        skipSectionLabel: 'Skip this section',
        allowSkipSection: true,
        redCancel: true,
        onCancelTour: () {},
        onSkipSection: () {},
        onComplete: () {},
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Cancel tour'), findsOneWidget);
    expect(find.text('Skip this section'), findsOneWidget);
  });

  testWidgets('an explainer offers only the close button', (tester) async {
    await tester.pumpWidget(_host(
      child: TutorialOverlay(
        steps: steps,
        cancelLabel: 'Close',
        skipSectionLabel: 'Skip this section',
        onCancelTour: () {},
        onSkipSection: () {},
        onComplete: () {},
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Close'), findsOneWidget);
    expect(find.text('Skip this section'), findsNothing);
  });

  testWidgets('each button reports its own outcome', (tester) async {
    var cancelled = 0;
    var skipped = 0;

    await tester.pumpWidget(_host(
      child: TutorialOverlay(
        steps: steps,
        cancelLabel: 'Cancel tour',
        skipSectionLabel: 'Skip this section',
        allowSkipSection: true,
        redCancel: true,
        onCancelTour: () => cancelled++,
        onSkipSection: () => skipped++,
        onComplete: () {},
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip this section'));
    await tester.pumpAndSettle();
    expect(skipped, 1);
    expect(cancelled, 0, reason: 'skipping a section must not end the tour');

    await tester.tap(find.text('Cancel tour'));
    await tester.pumpAndSettle();
    expect(cancelled, 1);
    expect(skipped, 1, reason: 'cancelling is not a section skip');
  });

  testWidgets('tapping the exits does not advance the dialogue',
      (tester) async {
    var completed = 0;

    await tester.pumpWidget(_host(
      child: TutorialOverlay(
        steps: steps,
        cancelLabel: 'Cancel tour',
        skipSectionLabel: 'Skip this section',
        allowSkipSection: true,
        redCancel: true,
        onCancelTour: () {},
        onSkipSection: () {},
        onComplete: () => completed++,
      ),
    ));
    await tester.pumpAndSettle();

    // The overlay advances on a tap anywhere, so the buttons have to swallow
    // their own taps or pressing them would also step the dialogue on.
    expect(find.text('1 / 2'), findsOneWidget);
    await tester.tap(find.text('Skip this section'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
    expect(completed, 0);
  });
}
