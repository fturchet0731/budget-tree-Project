// Leaf labels on the budget tree have to be readable, which means the leaves
// they sit on must not overlap. Every branch used to leave the trunk at one of
// only two angles, so the leaves stacked into two vertical columns and their
// labels ran into each other.
//
// StaticBudgetTreeView reports where it put each leaf via `leafHits`, so this
// renders the real widget and measures the gaps.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app_project/data/rhythm.dart';
import 'package:budget_app_project/models/budget_model.dart';
import 'package:budget_app_project/theme/leaf_palette.dart';
import 'package:budget_app_project/widgets/static_tree_view.dart';

BudgetModel budgetWith(List<(String, double)> expenses) => BudgetModel(
      budgetName: 'Test',
      incomeSources: [IncomeSource(name: 'Salary', amount: 2000)],
      expenses: [
        for (final (name, amount) in expenses)
          ExpenseCategory(name: name, allocated: amount, emoji: 'other'),
      ],
      savedAt: DateTime(2026, 1, 1),
      payFrequency: Rhythm.monthly,
    );

Future<List<Offset>> leafCentres(
  WidgetTester tester,
  BudgetModel budget,
) async {
  final hits = <TreeLeafHit>[];
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 360,
          height: 560,
          child: StaticBudgetTreeView(
            budget: budget,
            scale: 0.7,
            leafPalette: LeafPalette.defaultGreen,
            leafHits: hits,
          ),
        ),
      ),
    ),
  ));
  await tester.pump();
  return hits.map((h) => h.rect.center).toList();
}

/// Smallest gap between any two leaves.
double closestPair(List<Offset> centres) {
  var min = double.infinity;
  for (var i = 0; i < centres.length; i++) {
    for (var j = i + 1; j < centres.length; j++) {
      final d = (centres[i] - centres[j]).distance;
      if (d < min) min = d;
    }
  }
  return min;
}

/// The label block drawn on a leaf: the painter lays the name out to a
/// `64 * scale` box with the icon above it, centred on the leaf.
Rect labelRect(Offset centre, {double scale = 0.7}) =>
    Rect.fromCenter(center: centre, width: 64 * scale, height: 40 * scale);

/// Pairs of labels that visibly run into one another.
int overlappingLabels(List<Offset> centres) {
  var n = 0;
  for (var i = 0; i < centres.length; i++) {
    for (var j = i + 1; j < centres.length; j++) {
      if (labelRect(centres[i]).overlaps(labelRect(centres[j]))) n++;
    }
  }
  return n;
}

void main() {
  testWidgets('a leaf is drawn for every expense', (tester) async {
    final centres = await leafCentres(
      tester,
      budgetWith([
        ('Housing', 700),
        ('Food', 300),
        ('Utilities', 200),
        ('Savings', 200),
        ('Transport', 150),
        ('Entertainment', 100),
        ('Claude', 50),
      ]),
    );
    expect(centres, hasLength(7));
  });

  testWidgets('leaves stay far enough apart for their labels', (tester) async {
    final centres = await leafCentres(
      tester,
      budgetWith([
        ('Housing', 700),
        ('Food', 300),
        ('Utilities', 200),
        ('Savings', 200),
        ('Transport', 150),
        ('Entertainment', 100),
        ('Claude', 50),
      ]),
    );

    // What the user actually sees colliding is the labels, not the leaf
    // shapes: names wrap to a 64pt box, so two leaves can sit a comfortable
    // distance apart and still have "Transport" run through "Savings".
    expect(
      overlappingLabels(centres),
      0,
      reason: 'label blocks are running into each other',
    );
    expect(
      closestPair(centres),
      greaterThan(34.0),
      reason: 'leaves are crowding: closest pair ${closestPair(centres)}',
    );
  });

  testWidgets('branches with identical shares still separate', (tester) async {
    // The old layout gave these the same angle and the same length, so they
    // landed on top of each other.
    final centres = await leafCentres(
      tester,
      budgetWith([
        ('One', 200),
        ('Two', 200),
        ('Three', 200),
        ('Four', 200),
        ('Five', 200),
        ('Six', 200),
      ]),
    );
    expect(overlappingLabels(centres), 0);
    expect(closestPair(centres), greaterThan(34.0));
  });

  testWidgets('the canopy fans out instead of forming two columns',
      (tester) async {
    final centres = await leafCentres(
      tester,
      budgetWith([
        ('One', 300),
        ('Two', 300),
        ('Three', 250),
        ('Four', 250),
        ('Five', 200),
        ('Six', 200),
      ]),
    );

    // Leaves on one side used to share an x within a pixel or two of each
    // other. Fanned branches spread them across a real horizontal range.
    final left = centres.where((c) => c.dx < 180).map((c) => c.dx).toList();
    expect(left.length, greaterThan(1));
    final spreadX = left.reduce(math.max) - left.reduce(math.min);
    expect(
      spreadX,
      greaterThan(20.0),
      reason: 'one side is still a vertical column (x spread $spreadX)',
    );
  });

  testWidgets('a single expense still renders', (tester) async {
    final centres = await leafCentres(tester, budgetWith([('Only', 500)]));
    expect(centres, hasLength(1));
  });

  testWidgets('a budget with no expenses draws no leaves', (tester) async {
    final centres = await leafCentres(tester, budgetWith([]));
    expect(centres, isEmpty);
  });
}
