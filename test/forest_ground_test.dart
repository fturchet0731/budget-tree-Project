// The immersive forest must read as one field: the background ground band, the
// distant trees and the budget tree all standing on the same horizon. They used
// to be laid out independently (the tree filled an Expanded box, the background
// hardcoded 78% of the full height, the distant trees another fraction again),
// so they drifted onto visibly different tiers.
//
// This pins the geometry that keeps them together, by rendering the real widget
// and reading back the box the tree was given.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budget_app_project/data/rhythm.dart';
import 'package:budget_app_project/l10n/app_localizations.dart';
import 'package:budget_app_project/models/budget_model.dart';
import 'package:budget_app_project/services/app_settings.dart';
import 'package:budget_app_project/widgets/immersive_forest_view.dart';
import 'package:budget_app_project/widgets/static_tree_view.dart';

/// Mirrors the constants the view lays itself out with.
const double kStageTop = 40;
const double kStageBottom = 110;
const double kPlaqueRoom = 132;
const double kTreeGroundFraction = 0.78;

/// The horizon the view derives: the tree's own ground line, which the
/// background is then drawn to meet.
double horizonFor(double viewHeight) {
  final box = (viewHeight - kStageTop - kStageBottom - kPlaqueRoom)
      .clamp(120.0, viewHeight);
  return kStageTop + box * kTreeGroundFraction;
}

BudgetModel _budget() => BudgetModel(
      budgetName: 'Budget Tree Test',
      incomeSources: [IncomeSource(name: 'Salary', amount: 1409)],
      expenses: [
        ExpenseCategory(name: 'Housing', allocated: 700, emoji: 'home'),
        ExpenseCategory(name: 'Food', allocated: 709, emoji: 'food'),
      ],
      savedAt: DateTime(2026, 1, 1),
      payFrequency: Rhythm.monthly,
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'settings_motion_v1': false});
    await AppSettings.instance.load();
  });

  Future<Size> pumpAndMeasureTreeBox(WidgetTester tester, Size view) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = view;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ImmersiveForestView(
          budgets: [_budget()],
          categoriesById: const {},
          onTapTree: (_) {},
          onEdit: (_) {},
          onDelete: (_) {},
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 400));

    // The plaque and footer captions overflow horizontally by a few pixels in
    // the test harness only: Google Fonts can't be fetched here, so the
    // fallback face measures wider than the real one. Verified pre-existing by
    // running this against the unmodified widget. Cleared so it doesn't mask
    // the vertical geometry these tests are actually about.
    tester.takeException();

    return tester.getSize(find.byType(StaticBudgetTreeView).first);
  }

  testWidgets('the tree box is sized to put its ground on the horizon',
      (tester) async {
    const view = Size(390, 844);
    final box = await pumpAndMeasureTreeBox(tester, view);

    // The painter draws its ground at 78% of its box, offset by the stage's
    // top padding. That has to land on the scene horizon.
    final treeGround = kStageTop + box.height * kTreeGroundFraction;
    final horizon = horizonFor(view.height);

    expect(
      treeGround,
      closeTo(horizon, 0.5),
      reason: 'tree ground $treeGround should sit on the horizon $horizon',
    );
  });

  testWidgets('the horizon holds across screen sizes', (tester) async {
    for (final view in const [
      Size(360, 640), // small
      Size(390, 844), // typical phone
      Size(430, 932), // large phone
    ]) {
      final box = await pumpAndMeasureTreeBox(tester, view);
      final treeGround = kStageTop + box.height * kTreeGroundFraction;
      final horizon = horizonFor(view.height);

      expect(
        treeGround,
        closeTo(horizon, 0.5),
        reason: 'at $view the tree left the horizon',
      );
      // And the horizon stays in the upper-middle of the scene rather than
      // drifting to an edge, which is what keeps sky above and ground below.
      expect(horizon / view.height, greaterThan(0.35), reason: '$view');
      expect(horizon / view.height, lessThan(0.75), reason: '$view');
    }
  });

  testWidgets('the tree still gets a usable box on a very short screen',
      (tester) async {
    final box = await pumpAndMeasureTreeBox(tester, const Size(320, 568));
    // The clamp keeps the tree from collapsing to nothing when there isn't
    // room for both it and the plaque.
    expect(box.height, greaterThanOrEqualTo(120));
  });
}
