import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/budget_model.dart';
import '../models/goal_model.dart';
import 'budget_repository.dart';
import 'goal_repository.dart';

/// Routes a saved budget's leftover money into a goal: the user picks an
/// existing goal (or quick-creates one), and the budget gains a funding
/// branch linked to it so [PayScheduler] waters that goal each cycle.
/// Returns true when the budget was changed and persisted.
Future<bool> routeLeftoverToGoal(
  BuildContext context,
  BudgetModel budget,
) async {
  final l = AppLocalizations.of(context);
  final leftover = budget.remaining;
  if (leftover <= 0.5) return false;

  final goals = await GoalRepository.loadAll();
  if (!context.mounted) return false;

  final choice = await showDialog<Goal>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text(l.leftoverPickGoalTitle),
      children: [
        for (final g in goals)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, g),
            child: Text(g.name),
          ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, Goal(name: '', targetAmount: 0)),
          child: Text(l.leftoverNewGoal),
        ),
      ],
    ),
  );
  if (choice == null || !context.mounted) return false;

  Goal goal = choice;
  // The "new goal" sentinel has an empty name — prompt for one and save it.
  if (goal.name.isEmpty) {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.leftoverNewGoalTitle),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(hintText: l.goalNameHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: Text(l.save),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty || !context.mounted) return false;
    goal = Goal(name: name.trim(), targetAmount: 0);
    await GoalRepository.saveNew(goal);
  }

  budget.expenses.add(
    ExpenseCategory(
      name: goal.name,
      allocated: leftover,
      emoji: 'savings',
      linkedGoalIds: [goal.id],
    ),
  );
  await BudgetRepository.update(budget);
  return true;
}
