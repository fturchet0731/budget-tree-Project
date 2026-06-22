import '../widgets/acorn_mascot.dart';

/// The core areas of the app the acorn can guide you through. Each maps to
/// one of the four leaves on the dashboard menu.
enum TutorialSection { create, forest, goals, settings }

extension TutorialSectionLabel on TutorialSection {
  /// Short tag shown in the speech-bubble header, e.g. "Acorn • Create".
  String get label {
    switch (this) {
      case TutorialSection.create:
        return 'Create';
      case TutorialSection.forest:
        return 'Your Forest';
      case TutorialSection.goals:
        return 'The Grove';
      case TutorialSection.settings:
        return 'Settings';
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

const _intro = <TutorialStep>[
  TutorialStep("Hi there! I'm Acorn — your little guide here at Budget Tree!",
      expression: AcornExpression.happy),
  TutorialStep(
      "Instead of just telling you how things work, we'll do them together — you'll try each part yourself as we go."),
  TutorialStep("Take your time; I'll wait at every step. Ready? First stop, the Budget patch!",
      expression: AcornExpression.happy),
];

const _closing = <TutorialStep>[
  TutorialStep(
      "And that's the whole forest! Tap the info button on any screen and I'll explain that part again."),
  TutorialStep("Now let's grow something wonderful together. See you out there!",
      expression: AcornExpression.happy),
];

const Map<TutorialSection, List<TutorialStep>> _sectionLines = {
  TutorialSection.create: [
    TutorialStep(
        "Here we are — this is the Create screen, where you plant a brand-new budget tree."),
    TutorialStep(
        "You'll add what you earn, then where it goes, and a few personal details — the steps run along the vine up top."),
    TutorialStep(
        "I'll even work out your taxes and pay schedule, then watch your budget sprout into a tree!",
        expression: AcornExpression.happy),
  ],
  TutorialSection.forest: [
    TutorialStep(
        "This is Your Forest — every budget you've planted grows here together."),
    TutorialStep(
        "Switch between a leafy tree view and a tidy grid up top, and filter them by category."),
    TutorialStep(
        "Tap any tree to tend it: review the breakdown, edit it, or clear it away."),
  ],
  TutorialSection.goals: [
    TutorialStep(
        "Now we're in The Grove — your savings goals sprout here as little saplings."),
    TutorialStep(
        "Set a target amount, then water it with deposits over time."),
    TutorialStep(
        "Each contribution helps your sapling stretch a little closer to full bloom!",
        expression: AcornExpression.happy),
  ],
  TutorialSection.settings: [
    TutorialStep(
        "Last stop: Settings, where you make the app your own."),
    TutorialStep(
        "Switch the theme between Forest, Midnight and Twilight, adjust the text size, or ease the motion."),
    TutorialStep(
        "And you can replay this whole tour from here anytime you like."),
  ],
};

/// Acorn's brief self-introduction on the title screen, before the tour.
List<TutorialStep> introSteps() => List.of(_intro);

/// Acorn's friendly sign-off once the tour has visited every section.
List<TutorialStep> closingSteps() => List.of(_closing);

/// Just the lines for one section — used by the per-section info buttons as
/// a quick recap while the user is already on that screen.
List<TutorialStep> sectionSteps(TutorialSection section) =>
    List.of(_sectionLines[section]!);

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
String openHint(TutorialSection section) {
  switch (section) {
    case TutorialSection.create:
      return 'Open Create →';
    case TutorialSection.forest:
      return 'Open Forest →';
    case TutorialSection.goals:
      return 'Open the Grove →';
    case TutorialSection.settings:
      return 'Open Settings →';
  }
}

/// What Acorn says to set up the task, ending on a call to action.
List<TutorialStep> taskSteps(TutorialSection section) {
  switch (section) {
    case TutorialSection.create:
      return const [
        TutorialStep("Let's plant your very first budget tree — together!",
            expression: AcornExpression.happy),
        TutorialStep(
            "I'll open the Create screen and stay right beside you, guiding each phase: the Seed, the Branches, and the Roots."),
        TutorialStep("Tap below and we'll get our hands dirty!",
            expression: AcornExpression.happy),
      ];
    case TutorialSection.forest:
      return const [
        TutorialStep("Now let's wander into Your Forest, where your budgets grow."),
        TutorialStep(
            "Tap your tree to peek inside, and try the tree/grid toggle up top."),
        TutorialStep(
            "Have a good look around, then tap the back arrow to come find me."),
      ];
    case TutorialSection.goals:
      return const [
        TutorialStep("Time for a savings goal! This is The Grove."),
        TutorialStep(
            "Tap the + to plant a sapling, give it a name and a target, and save it."),
        TutorialStep("Then head back to me with the arrow. Off you go!",
            expression: AcornExpression.happy),
      ];
    case TutorialSection.settings:
      return const [
        TutorialStep("Last stop — let's make the app yours, in Settings."),
        TutorialStep(
            "Try tapping a different theme and watch the whole forest change colour."),
        TutorialStep("Come back whenever you're happy with the look."),
      ];
  }
}

/// Acorn's reaction when the user completed (or explored) the section.
List<TutorialStep> successSteps(TutorialSection section) {
  switch (section) {
    case TutorialSection.create:
      return const [
        TutorialStep("Look at that — your very first tree is planted! 🌳",
            expression: AcornExpression.happy),
        TutorialStep("Wonderfully done. That budget now lives in your forest."),
      ];
    case TutorialSection.forest:
      return const [
        TutorialStep(
            "That's your forest taking shape. Every budget you make plants another tree here.",
            expression: AcornExpression.happy),
      ];
    case TutorialSection.goals:
      return const [
        TutorialStep("Marvellous — your first sapling is reaching for the sky! 🌱",
            expression: AcornExpression.happy),
        TutorialStep("Feed it with deposits and it'll grow toward your target."),
      ];
    case TutorialSection.settings:
      return const [
        TutorialStep("Looking good! You can fine-tune all of that anytime.",
            expression: AcornExpression.happy),
      ];
  }
}

/// Shown when an action section wasn't finished — gentle nudge to retry.
List<TutorialStep> retrySteps(TutorialSection section) {
  switch (section) {
    case TutorialSection.create:
      return const [
        TutorialStep(
            "Hmm, I don't see a new tree yet! Want to give it another go?"),
        TutorialStep(
            "Add an income and an expense, then Plant and Save your tree. Or skip this step for now."),
      ];
    case TutorialSection.goals:
      return const [
        TutorialStep("No sapling planted yet — shall we try once more?"),
        TutorialStep(
            "Tap the + and save a goal, or skip this step and come back later."),
      ];
    default:
      return const [];
  }
}

/// Shown when the user chooses to skip an action step.
List<TutorialStep> skippedSteps(TutorialSection section) {
  switch (section) {
    case TutorialSection.create:
      return const [
        TutorialStep(
            "No worries! You can plant a budget anytime from the Create leaf."),
      ];
    case TutorialSection.goals:
      return const [
        TutorialStep(
            "That's okay! Plant a goal whenever you're ready from the Goals leaf."),
      ];
    default:
      return const [];
  }
}

// ──────────────────────────────────────────────
// In-screen step coaching for the Create budget flow.
// ──────────────────────────────────────────────

/// The three phases of building a budget, matching the Create screen's steps:
/// 0 = Seed (income), 1 = Branches (expenses), 2 = Roots (personal details).
List<TutorialStep> createStepSteps(int step) {
  switch (step) {
    case 0:
      return const [
        TutorialStep(
            "🌱 The Seed phase. Every tree starts with what feeds it — your income.",
            expression: AcornExpression.happy),
        TutorialStep(
            "Type a source like “Salary”, enter the amount, and tap the + to add it."),
        TutorialStep(
            "Add each way you earn. When you're ready, tap Next down below."),
      ];
    case 1:
      return const [
        TutorialStep(
            "🌿 The Branches. This is where your money reaches out — your expenses."),
        TutorialStep(
            "Pick a category, name it, set an amount, and add it. Watch how much is left to allocate up top."),
        TutorialStep("Add your main costs, then tap Next to set your roots."),
      ];
    case 2:
    default:
      return const [
        TutorialStep("🪵 The Roots — the details that ground your tree."),
        TutorialStep(
            "Name your budget, add your age, and choose your region and pay schedule. I use these to work out your taxes!"),
        TutorialStep(
            "All filled in? Tap “Plant My Budget Tree” below to grow it!",
            expression: AcornExpression.happy),
      ];
  }
}

/// Shown on the grown-tree screen, nudging the user to save it for good.
List<TutorialStep> saveTreeSteps() => const [
      TutorialStep("Look at it grow — that's your budget as a living tree! 🌳",
          expression: AcornExpression.happy),
      TutorialStep(
          "Tap “Save My Tree” (bottom-right) to plant it in your forest for keeps."),
    ];
