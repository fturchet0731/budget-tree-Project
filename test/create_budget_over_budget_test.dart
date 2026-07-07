// The create-budget wizard must never let the user move past the Expenses
// step while their branches ask for more than their income brings in: the
// always-visible allocation meter tracks what's left, and tapping Next while
// over budget summons Acorn's warning instead of advancing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budget_app_project/l10n/app_localizations.dart';
import 'package:budget_app_project/screens/createbudget_screen.dart';
import 'package:budget_app_project/services/app_settings.dart';

void main() {
  testWidgets('expenses step pins the meter and blocks Next when over budget',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      // Reduced motion: the acorn dialog types instantly and nothing loops,
      // so plain pumps are enough to settle each interaction.
      'settings_motion_v1': false,
    });
    await AppSettings.instance.load();

    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    // Lets step transitions fully finish: one frame past the switcher's
    // duration to complete the animation, one more to drop the outgoing step.
    Future<void> settle() async {
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
    }

    // Next is gated on having scrolled through everything on the step, so
    // reaching the end (like a user would) is part of advancing.
    Future<void> scrollToEnd() async {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -1600));
      await settle();
    }

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CreateBudgetScreen(),
      ),
    );
    await settle();

    // ── Income step: add a $100 source, confirm, move on. ──
    await tester.enterText(find.byType(TextField).at(0), 'Salary');
    await tester.enterText(find.byType(TextField).at(1), '100');
    await tester.tap(find.byIcon(Icons.add).first);
    await settle();

    await tester.scrollUntilVisible(
      find.text("That's all my income"),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text("That's all my income"));
    await tester.pump();
    await tester.tap(find.text("That's all my income"));
    await settle();
    // Confirming reveals the budget-cycle card below; scroll through it so
    // the scroll-through gate opens Next.
    await scrollToEnd();
    await tester.tap(find.text('Next'));
    await settle();

    // ── Expenses step: the meter is visible before anything is added. ──
    expect(find.text('Remaining: \$100'), findsOneWidget);

    // Add a $250 branch: the pinned meter flips to "over budget" live.
    await tester.enterText(find.byType(TextField).at(0), 'Rent');
    await tester.enterText(find.byType(TextField).at(1), '250');
    await tester.tap(find.byIcon(Icons.add).first);
    await settle();
    expect(find.text('Over by \$150'), findsOneWidget);

    // Confirm the list, then try to advance: Acorn warns and blocks.
    await tester.scrollUntilVisible(
      find.text("That's all my expenses"),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text("That's all my expenses"));
    await tester.pump();
    await tester.tap(find.text("That's all my expenses"));
    await settle();
    await scrollToEnd();
    await tester.tap(find.text('Next'));
    await settle();

    final l = AppLocalizations.of(
      tester.element(find.byType(CreateBudgetScreen)),
    );
    expect(find.text(l.tutOverBudget1), findsOneWidget);
    // Still on the Expenses step: its meter is still in the tree behind the
    // warning; the survey never appeared.
    expect(find.text('Over by \$150'), findsOneWidget);
    expect(find.text(l.surveyDoneTitle), findsNothing);
  });
}
