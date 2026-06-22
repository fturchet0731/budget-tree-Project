import 'package:flutter/material.dart';
import '../models/budget_model.dart';

enum SuggestionTone { good, info, warn }

/// One piece of allocation advice with a plain-language explanation of *why*.
class BudgetSuggestion {
  final SuggestionTone tone;
  final IconData icon;
  final String title;
  final String reason;

  const BudgetSuggestion({
    required this.tone,
    required this.icon,
    required this.title,
    required this.reason,
  });

  Color get color {
    switch (tone) {
      case SuggestionTone.good:
        return const Color(0xFF8BC34A);
      case SuggestionTone.info:
        return const Color(0xFF64B5F6);
      case SuggestionTone.warn:
        return const Color(0xFFFFB74D);
    }
  }
}

/// Inspects a budget and produces friendly, explained suggestions for how to
/// allocate money better — when to add a savings branch, prune an empty one,
/// or trim a branch that's grown too heavy. Pure and side-effect free so it's
/// trivial to unit-test and cheap to call on every rebuild.
class SuggestionService {
  SuggestionService._();

  /// At most [limit] suggestions, most important first, so the card never
  /// overwhelms the user (respecting the app's "keep it simple" surface area).
  static List<BudgetSuggestion> forBudget(BudgetModel budget, {int limit = 4}) {
    final income = budget.totalIncome;
    if (income <= 0) {
      return const [
        BudgetSuggestion(
          tone: SuggestionTone.info,
          icon: Icons.wb_sunny_outlined,
          title: 'Add your income first',
          reason:
              'A tree needs roots. Add an income source so we can suggest how '
              'to split it between branches and goals.',
        ),
      ];
    }

    final warns = <BudgetSuggestion>[];
    final infos = <BudgetSuggestion>[];
    final goods = <BudgetSuggestion>[];

    final remaining = budget.remaining;

    // Over-allocated: branches draw more than the trunk provides.
    if (remaining < -0.01) {
      warns.add(BudgetSuggestion(
        tone: SuggestionTone.warn,
        icon: Icons.warning_amber_rounded,
        title: 'Branches outgrow the trunk',
        reason:
            'You\'ve assigned \$${(-remaining).toStringAsFixed(0)} more than you '
            'earn. Trim a branch or two so the tree can actually support them.',
      ));
    } else if (remaining > income * 0.25) {
      // A lot of income left unassigned — money that could be growing.
      final pct = (remaining / income * 100).round();
      infos.add(BudgetSuggestion(
        tone: SuggestionTone.info,
        icon: Icons.eco_outlined,
        title: 'Put idle money to work',
        reason:
            '\$${remaining.toStringAsFixed(0)} ($pct%) of your income isn\'t '
            'assigned yet. Add a savings branch and link it to a goal so it '
            'grows instead of drifting away.',
      ));
    }

    // Per-branch checks.
    for (final cat in budget.expenses) {
      if (cat.allocated <= 0) {
        infos.add(BudgetSuggestion(
          tone: SuggestionTone.info,
          icon: Icons.cut,
          title: 'Prune "${cat.name}"',
          reason:
              'This branch has no money flowing to it. Fund it or prune it to '
              'keep your tree focused.',
        ));
      } else {
        final share = cat.allocated / income;
        if (share > 0.35) {
          warns.add(BudgetSuggestion(
            tone: SuggestionTone.warn,
            icon: Icons.content_cut,
            title: '"${cat.name}" is a heavy branch',
            reason:
                'It takes ${(share * 100).round()}% of your income. If you can '
                'trim it, that money could feed a savings goal instead.',
          ));
        }
      }
    }

    // Positive reinforcement: any branch feeding a goal is a win worth noting.
    final linked =
        budget.expenses.where((c) => c.linkedGoalIds.isNotEmpty).toList();
    if (linked.isNotEmpty) {
      goods.add(BudgetSuggestion(
        tone: SuggestionTone.good,
        icon: Icons.check_circle_outline,
        title: 'Goals are being fed',
        reason:
            '${linked.length} branch${linked.length == 1 ? '' : 'es'} send money '
            'to a goal every pay cycle. Keep it up — that\'s how saplings grow.',
      ));
    } else if (budget.expenses.isNotEmpty) {
      infos.add(const BudgetSuggestion(
        tone: SuggestionTone.info,
        icon: Icons.link,
        title: 'Link a branch to a goal',
        reason:
            'None of your branches feed a savings goal yet. Linking one means '
            'every pay cycle automatically waters a sapling for you.',
      ));
    }

    // Warnings first (most actionable), then info, then encouragement.
    final ordered = [...warns, ...infos, ...goods];
    if (ordered.isEmpty) {
      return const [
        BudgetSuggestion(
          tone: SuggestionTone.good,
          icon: Icons.spa_outlined,
          title: 'Healthy, balanced tree',
          reason:
              'Your branches are well proportioned and within your income. '
              'Nothing to change — just keep watering your goals.',
        ),
      ];
    }
    return ordered.take(limit).toList();
  }
}
