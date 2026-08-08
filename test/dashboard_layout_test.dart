// Overflow guard for the dashboard: at real phone sizes the header, the health
// tree hero, the friends strip, and the four-leaf menu grid must all lay out
// without any RenderFlex overflow (regression: the strip + grid block once
// overflowed the bottom by a fraction of a pixel on iPhone-sized screens).
//
// The hero makes this guard matter more than it used to. As a sibling of the
// Expanded it would take its height off the flex child and overflow a short
// screen outright, so it lives inside the scroll view and sizes off the
// viewport. The small-screen case below is what pins that.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budget_app_project/l10n/app_localizations.dart';
import 'package:budget_app_project/screens/dashboard_screen.dart';
import 'package:budget_app_project/services/app_settings.dart';
import 'package:budget_app_project/widgets/friends_strip.dart';
import 'package:budget_app_project/widgets/health_tree_hero.dart';

Future<void> pumpDashboard(
  WidgetTester tester, {
  required Size size,
  EdgeInsets padding = EdgeInsets.zero,
}) async {
  SharedPreferences.setMockInitialValues({'settings_motion_v1': false});
  await AppSettings.instance.load();

  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  tester.view.padding = FakeViewPadding(
    top: padding.top,
    bottom: padding.bottom,
  );
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
}

void main() {
  testWidgets('dashboard fits an iPhone screen without overflow', (
    tester,
  ) async {
    await pumpDashboard(tester, size: const Size(390, 844));

    // No RenderFlex overflow or other layout exceptions fired.
    expect(tester.takeException(), isNull);

    // The pillars are all present: the hero, friends strip and four tiles.
    expect(find.byType(HealthTreeHero), findsOneWidget);
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
    // Acorn's Hub is the full-width fifth tile *under* the four pillars, not
    // above them: the four-leaf menu stays the first thing the user sees.
    expect(
      tester.getRect(find.byType(HealthTreeHero)).top,
      greaterThan(tester.getRect(find.text(l.dashboardSettings)).bottom),
    );

    // Back to ground stays pinned at the bottom, on screen.
    final back = find.text(l.dashboardBackToGround);
    expect(back, findsOneWidget);
    expect(tester.getRect(back).bottom, lessThanOrEqualTo(844));
  });

  testWidgets('dashboard survives a small phone with device insets', (
    tester,
  ) async {
    // 360x640 with a notch and a home indicator: the tightest realistic case,
    // and the one a fixed-height hero above the Expanded would overflow.
    await pumpDashboard(
      tester,
      size: const Size(360, 640),
      padding: const EdgeInsets.only(top: 44, bottom: 34),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(HealthTreeHero), findsOneWidget);

    final l = AppLocalizations.of(
      tester.element(find.byType(DashboardScreen)),
    );
    final back = find.text(l.dashboardBackToGround);
    expect(back, findsOneWidget);
    expect(tester.getRect(back).bottom, lessThanOrEqualTo(640));
  });
}
