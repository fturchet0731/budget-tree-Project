import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/budget_model.dart';
import '../models/goal_model.dart';

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
  static List<BudgetSuggestion> forBudget(
      BudgetModel budget, AppLocalizations l,
      {int limit = 4, List<Goal> goals = const []}) {
    final income = budget.totalIncome;
    if (income <= 0) {
      return [
        BudgetSuggestion(
          tone: SuggestionTone.info,
          icon: Icons.wb_sunny_outlined,
          title: l.sugAddIncomeTitle,
          reason: l.sugAddIncomeReason,
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
        title: l.sugOverAllocTitle,
        reason:
            l.sugOverAllocReason('\$${(-remaining).toStringAsFixed(0)}'),
      ));
    } else if (remaining > income * 0.25 || remaining > 200) {
      // A lot of income left unassigned: money that could be growing.
      final pct = (remaining / income * 100).round();
      infos.add(BudgetSuggestion(
        tone: SuggestionTone.info,
        icon: Icons.eco_outlined,
        title: l.sugIdleTitle,
        reason: l.sugIdleReason('\$${remaining.toStringAsFixed(0)}', pct),
      ));
    }

    // Per-branch checks.
    for (final cat in budget.expenses) {
      if (cat.allocated <= 0) {
        infos.add(BudgetSuggestion(
          tone: SuggestionTone.info,
          icon: Icons.cut,
          title: l.sugPruneTitle(cat.name),
          reason: l.sugPruneReason,
        ));
      } else {
        final share = cat.allocatedPerCycle(budget.payFrequency) / income;
        if (share > 0.35) {
          warns.add(BudgetSuggestion(
            tone: SuggestionTone.warn,
            icon: Icons.content_cut,
            title: l.sugHeavyTitle(cat.name),
            reason: l.sugHeavyReason((share * 100).round()),
          ));
        }
      }
    }

    // Goals this budget doesn't water yet: suggest a branch per goal (the
    // most concrete advice we can give, so it goes ahead of generic info).
    final linkedIds = <String>{
      for (final c in budget.expenses) ...c.linkedGoalIds,
    };
    for (final goal in goals) {
      if (goal.isCompleted || linkedIds.contains(goal.id)) continue;
      infos.add(BudgetSuggestion(
        tone: SuggestionTone.info,
        icon: Icons.spa_outlined,
        title: l.sugGoalBranchTitle(goal.name),
        reason: l.sugGoalBranchReason,
      ));
    }

    // Positive reinforcement: any branch feeding a goal is a win worth noting.
    final linked =
        budget.expenses.where((c) => c.linkedGoalIds.isNotEmpty).toList();
    if (linked.isNotEmpty) {
      goods.add(BudgetSuggestion(
        tone: SuggestionTone.good,
        icon: Icons.check_circle_outline,
        title: l.sugFedTitle,
        reason: l.sugFedReason(linked.length),
      ));
    } else if (budget.expenses.isNotEmpty) {
      infos.add(BudgetSuggestion(
        tone: SuggestionTone.info,
        icon: Icons.link,
        title: l.sugLinkTitle,
        reason: l.sugLinkReason,
      ));
    }

    // Warnings first (most actionable), then info, then encouragement.
    final ordered = [...warns, ...infos, ...goods];
    if (ordered.isEmpty) {
      return [
        BudgetSuggestion(
          tone: SuggestionTone.good,
          icon: Icons.spa_outlined,
          title: l.sugHealthyTitle,
          reason: l.sugHealthyReason,
        ),
      ];
    }
    return ordered.take(limit).toList();
  }
}
