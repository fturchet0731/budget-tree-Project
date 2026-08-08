// Layout guards for the new AI surfaces.
//
// Each of these renders in the state a brand-new user actually meets first:
// no check-ins, no reflection, no chat history. That empty path is the one
// most likely to break, because every chart on these screens has to decide
// whether it has anything to draw. In particular the overspend chart must show
// its written empty state rather than an axis over no data, since the only
// plan-versus-actual figures in the app are ones the user optionally typed.
//
// Supabase is unconfigured in tests, so the AI services report unavailable and
// the screens take their offline paths.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budget_app_project/l10n/app_localizations.dart';
import 'package:budget_app_project/screens/acorn_chat_screen.dart';
import 'package:budget_app_project/screens/acorn_hub_screen.dart';
import 'package:budget_app_project/screens/reflection_story_screen.dart';
import 'package:budget_app_project/services/app_settings.dart';
import 'package:budget_app_project/widgets/health_tree_view.dart';

Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  Size size = const Size(390, 844),
}) async {
  SharedPreferences.setMockInitialValues({'settings_motion_v1': false});
  await AppSettings.instance.load();

  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
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
      home: screen,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('Acorn hub lays out with no data at all', (tester) async {
    await pumpScreen(tester, const AcornHubScreen());

    expect(tester.takeException(), isNull);
    final l = AppLocalizations.of(tester.element(find.byType(AcornHubScreen)));

    // The tree is always drawn, even at the baseline.
    expect(find.byType(HealthTreeView), findsWidgets);
    expect(find.text(l.hubTreeFresh), findsWidgets);

    // The overspend card says plainly that there is nothing to compare yet.
    expect(find.text(l.hubOverspendEmpty), findsOneWidget);

    // Talking to Acorn is offered regardless of how much data exists.
    expect(find.text(l.hubTalkAction), findsOneWidget);
  });

  testWidgets('Acorn hub survives a small phone', (tester) async {
    await pumpScreen(tester, const AcornHubScreen(),
        size: const Size(360, 640));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reflection story renders and can be paged', (tester) async {
    await pumpScreen(tester, const ReflectionStoryScreen());

    expect(tester.takeException(), isNull);
    final l = AppLocalizations.of(
      tester.element(find.byType(ReflectionStoryScreen)),
    );

    // Slide one is always the tree, and with no coach output the closing
    // slide falls back to inviting a conversation.
    expect(find.text(l.hubStoryIntroTitle), findsOneWidget);

    await tester.tap(find.text(l.next));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text(l.hubStorySuggestionsTitle), findsOneWidget);
  });

  testWidgets('Acorn chat shows its openers when the thread is empty', (
    tester,
  ) async {
    await pumpScreen(tester, const AcornChatScreen());

    expect(tester.takeException(), isNull);
    final l = AppLocalizations.of(tester.element(find.byType(AcornChatScreen)));
    expect(find.text(l.hubChatGreeting), findsOneWidget);
    expect(find.text(l.hubChatPrompt1), findsOneWidget);
  });
}
