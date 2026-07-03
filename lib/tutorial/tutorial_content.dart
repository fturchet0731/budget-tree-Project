import '../l10n/app_localizations.dart';
import '../widgets/acorn_mascot.dart';

/// The core areas of the app the acorn can guide you through. Each maps to
/// one of the four leaves on the dashboard menu.
enum TutorialSection { create, forest, goals, settings }

extension TutorialSectionLabel on TutorialSection {
  /// Short tag shown in the speech-bubble header, e.g. "Acorn • Create".
  String label(AppLocalizations l) {
    switch (this) {
      case TutorialSection.create:
        return l.dashboardCreate;
      case TutorialSection.forest:
        return l.yourForest;
      case TutorialSection.goals:
        return l.groveTitle;
      case TutorialSection.settings:
        return l.dashboardSettings;
    }
  }
}

/// One line of dialogue from the acorn, plus the face it should pull while
/// the line is on screen.
class TutorialStep {
  final String text;
  final String speaker;
  final AcornExpression expression;
  const TutorialStep(
    this.text, {
    this.speaker = 'Acorn',
    this.expression = AcornExpression.idle,
  });
}

/// Acorn's brief self-introduction on the title screen, before the tour.
List<TutorialStep> introSteps(AppLocalizations l) => [
  TutorialStep(l.tutIntro1, expression: AcornExpression.happy),
  TutorialStep(l.tutIntro2),
  TutorialStep(l.tutIntro3, expression: AcornExpression.happy),
];

/// Acorn's friendly sign-off once the tour has visited every section.
List<TutorialStep> closingSteps(AppLocalizations l) => [
  TutorialStep(l.tutClosing1),
  TutorialStep(l.tutClosing2, expression: AcornExpression.happy),
];

/// Just the lines for one section — used by the per-section info buttons as
/// a quick recap while the user is already on that screen.
List<TutorialStep> sectionSteps(TutorialSection section, AppLocalizations l) {
  switch (section) {
    case TutorialSection.create:
      return [
        TutorialStep(l.tutCreate1),
        TutorialStep(l.tutCreate2),
        TutorialStep(l.tutCreate3, expression: AcornExpression.happy),
      ];
    case TutorialSection.forest:
      return [
        TutorialStep(l.tutForest1),
        TutorialStep(l.tutForest2),
        TutorialStep(l.tutForest3),
      ];
    case TutorialSection.goals:
      return [
        TutorialStep(l.tutGoals1),
        TutorialStep(l.tutGoals2),
        TutorialStep(l.tutGoals3, expression: AcornExpression.happy),
      ];
    case TutorialSection.settings:
      return [
        TutorialStep(l.tutSettings1),
        TutorialStep(l.tutSettings2),
        TutorialStep(l.tutSettings3),
      ];
  }
}

/// The sections the guided tour visits, in order.
const tourOrder = <TutorialSection>[
  TutorialSection.create,
  TutorialSection.forest,
  TutorialSection.goals,
  TutorialSection.settings,
];

// ──────────────────────────────────────────────
// Hands-on tour: what Acorn says before, after, and if a task is skipped.
// ──────────────────────────────────────────────

/// Sections that ask the user to actually finish something (and whose
/// completion we can detect) before the tour moves on.
bool sectionRequiresAction(TutorialSection section) =>
    section == TutorialSection.create || section == TutorialSection.goals;

/// The label on the button that hands the real screen over to the user.
String openHint(TutorialSection section, AppLocalizations l) {
  switch (section) {
    case TutorialSection.create:
      return l.tutOpenCreate;
    case TutorialSection.forest:
      return l.tutOpenForest;
    case TutorialSection.goals:
      return l.tutOpenGoals;
    case TutorialSection.settings:
      return l.tutOpenSettings;
  }
}

/// What Acorn says to set up the task, ending on a call to action.
List<TutorialStep> taskSteps(TutorialSection section, AppLocalizations l) {
  switch (section) {
    case TutorialSection.create:
      return [
        TutorialStep(l.tutTaskCreate1, expression: AcornExpression.happy),
        TutorialStep(l.tutTaskCreate2),
        TutorialStep(l.tutTaskCreate3, expression: AcornExpression.happy),
      ];
    case TutorialSection.forest:
      return [
        TutorialStep(l.tutTaskForest1),
        TutorialStep(l.tutTaskForest2),
        TutorialStep(l.tutTaskForest3),
      ];
    case TutorialSection.goals:
      return [
        TutorialStep(l.tutTaskGoals1),
        TutorialStep(l.tutTaskGoals2),
        TutorialStep(l.tutTaskGoals3, expression: AcornExpression.happy),
      ];
    case TutorialSection.settings:
      return [
        TutorialStep(l.tutTaskSettings1),
        TutorialStep(l.tutTaskSettings2),
        TutorialStep(l.tutTaskSettings3),
      ];
  }
}

/// Acorn's reaction when the user completed (or explored) the section.
List<TutorialStep> successSteps(TutorialSection section, AppLocalizations l) {
  switch (section) {
    case TutorialSection.create:
      return [
        TutorialStep(l.tutSuccessCreate1, expression: AcornExpression.happy),
        TutorialStep(l.tutSuccessCreate2),
      ];
    case TutorialSection.forest:
      return [
        TutorialStep(l.tutSuccessForest1, expression: AcornExpression.happy),
      ];
    case TutorialSection.goals:
      return [
        TutorialStep(l.tutSuccessGoals1, expression: AcornExpression.happy),
        TutorialStep(l.tutSuccessGoals2),
      ];
    case TutorialSection.settings:
      return [
        TutorialStep(l.tutSuccessSettings1, expression: AcornExpression.happy),
      ];
  }
}

/// Shown when an action section wasn't finished — gentle nudge to retry.
List<TutorialStep> retrySteps(TutorialSection section, AppLocalizations l) {
  switch (section) {
    case TutorialSection.create:
      return [TutorialStep(l.tutRetryCreate1), TutorialStep(l.tutRetryCreate2)];
    case TutorialSection.goals:
      return [TutorialStep(l.tutRetryGoals1), TutorialStep(l.tutRetryGoals2)];
    default:
      return const [];
  }
}

/// Shown when the user chooses to skip an action step.
List<TutorialStep> skippedSteps(TutorialSection section, AppLocalizations l) {
  switch (section) {
    case TutorialSection.create:
      return [TutorialStep(l.tutSkipCreate1)];
    case TutorialSection.goals:
      return [TutorialStep(l.tutSkipGoals1)];
    default:
      return const [];
  }
}

// ──────────────────────────────────────────────
// In-screen step coaching for the Create budget flow.
// ──────────────────────────────────────────────

/// The three phases of building a budget, matching the Create screen's steps:
/// 0 = Seed (income), 1 = Branches (expenses), 2 = Survey, 3 = Plan (which
/// also carries the finishing touches: name + pay schedule + plant).
List<TutorialStep> createStepSteps(int step, AppLocalizations l) {
  switch (step) {
    case 0:
      return [
        TutorialStep(l.tutStep0a, expression: AcornExpression.happy),
        TutorialStep(l.tutStep0b),
        TutorialStep(l.tutStep0c),
      ];
    case 1:
      return [
        TutorialStep(l.tutStep1a),
        TutorialStep(l.tutStep1b),
        TutorialStep(l.tutStep1c),
      ];
    case 2:
      return [
        TutorialStep(l.tutStepSurveyA, expression: AcornExpression.happy),
        TutorialStep(l.tutStepSurveyB),
        TutorialStep(l.tutStepSurveyC),
      ];
    case 3:
    default:
      return [
        TutorialStep(l.tutStepPlanA, expression: AcornExpression.happy),
        TutorialStep(l.tutStepPlanB),
        TutorialStep(l.tutStepPlanC),
        TutorialStep(l.tutStep2b),
        TutorialStep(l.tutStep2c, expression: AcornExpression.happy),
      ];
  }
}

/// Shown on the grown-tree screen, nudging the user to save it for good.
List<TutorialStep> saveTreeSteps(AppLocalizations l) => [
  TutorialStep(l.tutSaveTree1, expression: AcornExpression.happy),
  TutorialStep(l.tutSaveTree2),
];
