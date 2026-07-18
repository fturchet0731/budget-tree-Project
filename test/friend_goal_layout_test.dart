// Layout confirmation for FriendGoalScreen (the read-only friend view): at a
// real phone size the header, the sapling hero, and the stats panel must all
// be fully on screen and stacked in that order — regression guard for the old
// absolute-Positioned layout where the header/panel overlapped the sapling so
// only its lower half was visible.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budget_app_project/l10n/app_localizations.dart';
import 'package:budget_app_project/models/goal_model.dart';
import 'package:budget_app_project/screens/friend_goal_screen.dart';
import 'package:budget_app_project/widgets/sapling_view.dart';

void main() {
  testWidgets('friend goal shows the whole sapling between header and panel', (
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
        home: FriendGoalScreen(goal: goal, ownerLabel: '@friend'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);

    final screen = tester.getSize(find.byType(FriendGoalScreen));

    Rect rectOf(Finder f) => tester.getRect(f);
    bool onScreen(Rect r) =>
        r.top >= 0 &&
        r.bottom <= screen.height + 0.5 &&
        r.left >= 0 &&
        r.right <= screen.width + 0.5;

    final back = rectOf(find.byIcon(Icons.arrow_back));
    final hero = rectOf(find.byType(SaplingView));
    final saved = rectOf(find.text('\$750.00'));

    // The whole sapling is inside the viewport (the old layout clipped it).
    expect(onScreen(back), isTrue, reason: 'back button off screen: $back');
    expect(onScreen(hero), isTrue, reason: 'sapling off screen: $hero');
    expect(onScreen(saved), isTrue, reason: 'saved amount off screen: $saved');

    // Stacked header -> hero -> stats panel, top to bottom, hero centred.
    expect(back.center.dy, lessThan(hero.center.dy));
    expect(hero.center.dy, lessThan(saved.center.dy));
    expect((hero.center.dx - screen.width / 2).abs(), lessThan(40));

    // The hero doesn't collide with the header or the bottom panel.
    expect(hero.top, greaterThan(back.bottom));
    expect(hero.bottom, lessThan(saved.top));
  });
}
