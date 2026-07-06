// Layout confirmation for GoalDetailScreen: at a real phone size the header,
// the sapling hero, and the "Water the Sapling" button must all be fully on
// screen and stacked in that vertical order — regression guard for the old
// absolute-Positioned layout that pushed content off-screen / uncentered.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budget_app_project/l10n/app_localizations.dart';
import 'package:budget_app_project/models/goal_model.dart';
import 'package:budget_app_project/screens/goal_detail_screen.dart';
import 'package:budget_app_project/widgets/sapling_view.dart';

void main() {
  testWidgets('goal detail lays out header, hero and button on screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    // iPhone-12-ish logical size.
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    final goal = Goal(name: 'New Car', targetAmount: 1000, currentAmount: 750);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: GoalDetailScreen(goal: goal),
      ),
    );
    await tester.pump(); // let the grow animation + async loads settle a frame
    await tester.pump(const Duration(seconds: 2));

    // No overflow / layout assertions fired.
    expect(tester.takeException(), isNull);

    final screen = tester.getSize(find.byType(GoalDetailScreen));

    Rect rectOf(Finder f) => tester.getRect(f);
    bool onScreen(Rect r) =>
        r.top >= 0 &&
        r.bottom <= screen.height + 0.5 &&
        r.left >= 0 &&
        r.right <= screen.width + 0.5;

    final back = rectOf(find.byIcon(Icons.arrow_back));
    final hero = rectOf(find.byType(SaplingView));
    final button = rectOf(find.text('Water the Sapling'));

    // Everything is inside the viewport.
    expect(onScreen(back), isTrue, reason: 'back button off screen: $back');
    expect(onScreen(hero), isTrue, reason: 'sapling off screen: $hero');
    expect(onScreen(button), isTrue, reason: 'water button off screen: $button');

    // Stacked header -> hero -> button, top to bottom.
    expect(back.center.dy, lessThan(hero.center.dy));
    expect(hero.center.dy, lessThan(button.center.dy));

    // The button sits in the lower panel, not floating mid-screen, and the
    // hero occupies the centre band (horizontally centred).
    expect(button.center.dy, greaterThan(screen.height * 0.7));
    expect((hero.center.dx - screen.width / 2).abs(), lessThan(40));
  });
}
