// Overflow guard for the dashboard: at a real phone size the header, the
// friends strip, and the four-leaf menu grid must all lay out without any
// RenderFlex overflow (regression: the strip + grid block once overflowed
// the bottom by a fraction of a pixel on iPhone-sized screens).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budget_app_project/l10n/app_localizations.dart';
import 'package:budget_app_project/screens/dashboard_screen.dart';
import 'package:budget_app_project/services/app_settings.dart';
import 'package:budget_app_project/widgets/friends_strip.dart';

void main() {
  testWidgets('dashboard fits an iPhone screen without overflow', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'settings_motion_v1': false,
    });
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
        home: const DashboardScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // No RenderFlex overflow or other layout exceptions fired.
    expect(tester.takeException(), isNull);

    // The pillars are all present: friends strip and the four menu tiles.
    expect(find.byType(FriendsStrip), findsOneWidget);
    final l = AppLocalizations.of(
      tester.element(find.byType(DashboardScreen)),
    );
    expect(find.text(l.dashboardCreate), findsOneWidget);
    expect(find.text(l.dashboardModify), findsOneWidget);
    expect(find.text(l.dashboardGoals), findsOneWidget);
    expect(find.text(l.dashboardSettings), findsOneWidget);
    expect(find.text(l.addFriends), findsOneWidget);
    expect(find.text(l.profile), findsOneWidget);
    // Back to ground stays pinned at the bottom, on screen.
    final back = find.text(l.dashboardBackToGround);
    expect(back, findsOneWidget);
    expect(tester.getRect(back).bottom, lessThanOrEqualTo(844));
  });
}
