import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../screens/createbudget_screen.dart';
import '../screens/forest_screen.dart';
import '../screens/goals_screen.dart';
import '../screens/settings_screen.dart';
import '../services/budget_repository.dart';
import '../services/goal_repository.dart';
import 'tutorial_content.dart';
import 'tutorial_overlay.dart';

/// Drives the hands-on guided walkthrough.
///
/// Acorn doesn't just narrate — for each section he explains the task, then
/// hands the user the *real* screen and waits for them to actually do it
/// (plant a budget, plant a goal, explore the forest, change a theme) before
/// moving on. Action steps watch the repositories to know when the task is
/// genuinely done, and gently offer a retry if it isn't.
///
/// "Skip tour" leaves at any point; "Skip step" skips just the current task.
class GuidedTour {
  GuidedTour._();

  static Future<void> start(BuildContext context) async {
    final l = AppLocalizations.of(context);
    // 1. Brief self-introduction.
    if (await _say(context, introSteps(l),
        hint: l.tourLetsGo, skip: l.tourSkipTour)) {
      return;
    }

    // 2. Walk through each section, hands-on.
    for (final section in tourOrder) {
      if (!context.mounted) return;
      final keepGoing = await _runSection(context, section, l);
      if (!keepGoing) return; // user skipped the whole tour
    }

    // 3. Friendly sign-off.
    if (!context.mounted) return;
    await _say(context, closingSteps(l),
        hint: l.tourLetsGrow, skip: l.tourClose);
  }

  /// Runs one section. Returns false if the user skipped the entire tour.
  static Future<bool> _runSection(
      BuildContext context, TutorialSection section, AppLocalizations l) async {
    // Set up the task.
    if (await _say(context, taskSteps(section, l),
        title: section.label(l),
        hint: openHint(section, l),
        skip: l.tourSkipTour)) {
      return false;
    }

    if (sectionRequiresAction(section)) {
      var completed = false;
      while (true) {
        if (!context.mounted) return false;
        final before = await _count(section);
        if (!context.mounted) return false;
        // Hand over the real screen. The Create flow pops back a `true` signal
        // the moment a tree is planted, which is authoritative — counting the
        // repository afterwards can race with the background Supabase pull and
        // briefly miss the new row, which used to make this step restart.
        final result = await _open(context, section);
        if (!context.mounted) return false;
        final after = await _count(section);
        if (result == true || after > before) {
          completed = true;
          break;
        }
        // Not done — offer a retry, or let them skip just this step.
        if (!context.mounted) return false;
        final skipStep = await _say(context, retrySteps(section, l),
            title: section.label(l), hint: l.tourTryAgain, skip: l.tourSkipStep);
        if (skipStep) break;
      }
      if (!context.mounted) return false;
      final skipped = await _say(
        context,
        completed ? successSteps(section, l) : skippedSteps(section, l),
        title: section.label(l),
        hint: l.tourNextStop,
        skip: l.tourSkipTour,
      );
      return !skipped;
    }

    // Explore-only section: open it, let them roam, then react.
    if (!context.mounted) return false;
    await _open(context, section);
    if (!context.mounted) return false;
    final skipped = await _say(context, successSteps(section, l),
        title: section.label(l), hint: l.tourNextStop, skip: l.tourSkipTour);
    return !skipped;
  }

  /// Shows an Acorn dialog. Returns true if the user pressed the skip button.
  static Future<bool> _say(
    BuildContext context,
    List<TutorialStep> steps, {
    String? title,
    String hint = 'Tap to continue',
    String skip = 'Skip',
  }) {
    return showTutorialDialog(
      context,
      steps: steps,
      sectionTitle: title,
      lastStepHint: hint,
      skipLabel: skip,
    );
  }

  /// Pushes the genuine, fully-interactive screen for a section. Returns
  /// whatever that screen pops with (the Create flow returns `true` once a
  /// tree is actually planted).
  static Future<Object?> _open(BuildContext context, TutorialSection section) {
    return Navigator.of(context).push<Object?>(
      MaterialPageRoute(builder: (_) => _screenFor(section)),
    );
  }

  static Widget _screenFor(TutorialSection section) {
    switch (section) {
      case TutorialSection.create:
        // Acorn rides along inside the Create flow, coaching each phase.
        return const CreateBudgetScreen(tutorial: true);
      case TutorialSection.forest:
        return const ForestScreen();
      case TutorialSection.goals:
        return const GoalsScreen();
      case TutorialSection.settings:
        return const SettingsScreen();
    }
  }

  /// How many items currently exist for an action section — used to detect
  /// that the user actually finished the task.
  static Future<int> _count(TutorialSection section) async {
    switch (section) {
      case TutorialSection.create:
        return (await BudgetRepository.loadAll()).length;
      case TutorialSection.goals:
        return (await GoalRepository.loadAll()).length;
      default:
        return 0;
    }
  }
}
