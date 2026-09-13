// Status-bar guard for the scene screens.
//
// PixelScene deliberately bleeds its sky up behind the status bar — that is
// what makes the header read as scenery rather than chrome. Its *controls*
// must not: on a notched phone the back chevron and the level badge used to
// sit under the clock, wifi, and battery.
//
// These tests pin the rule at a real iPhone-style inset: every interactive
// control in a scene starts below the top inset, while the scene band itself
// still reaches y = 0.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budget_app_project/l10n/app_localizations.dart';
import 'package:budget_app_project/services/app_settings.dart';
import 'package:budget_app_project/theme/app_theme.dart';
import 'package:budget_app_project/widgets/pixel/pixel.dart';

const _topInset = 59.0; // iPhone 14 Pro-ish
const _bottomInset = 34.0;

Future<void> pumpScene(WidgetTester tester, Widget scene) async {
  SharedPreferences.setMockInitialValues({'settings_motion_v1': false});
  await AppSettings.instance.load();

  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(390, 844);
  tester.view.padding = const FakeViewPadding(
    top: _topInset,
    bottom: _bottomInset,
  );
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Column(children: [scene])),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('scene controls clear the status bar', (tester) async {
    await pumpScene(
      tester,
      PixelScene(
        height: 212,
        subject: const SizedBox(width: 100, height: 100),
        onBack: () {},
        backLabel: 'Back',
        topRight: const PixelBadge(label: 'LV.12'),
      ),
    );

    // The band itself still reaches the very top — the sky is meant to bleed.
    final band = tester.getRect(find.byType(PixelScene));
    expect(band.top, 0);
    // ...and it grew by the inset so the body below is unaffected.
    expect(band.height, 212 + _topInset);

    // Every control sits below the status bar.
    final back = tester.getRect(find.byType(PixelIconButton));
    expect(
      back.top,
      greaterThanOrEqualTo(_topInset),
      reason: 'back chevron overlaps the status bar',
    );

    final badge = tester.getRect(find.byType(PixelBadge));
    expect(
      badge.top,
      greaterThanOrEqualTo(_topInset),
      reason: 'level badge overlaps the status bar',
    );
  });

  testWidgets('scene without insets keeps its declared height', (tester) async {
    SharedPreferences.setMockInitialValues({'settings_motion_v1': false});
    await AppSettings.instance.load();
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.padding = const FakeViewPadding(top: 0, bottom: 0);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Column(
            children: [
              PixelScene(
                height: 212,
                subject: const SizedBox(width: 100, height: 100),
                onBack: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.getRect(find.byType(PixelScene)).height, 212);
  });
}
