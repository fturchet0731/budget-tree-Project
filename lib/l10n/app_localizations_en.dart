// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get retry => 'Retry';

  @override
  String get close => 'Close';

  @override
  String get next => 'Next';

  @override
  String get friends => 'Friends';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageSubtitle => 'Choose your language';

  @override
  String get systemDefault => 'System default';

  @override
  String get dashboardChooseBranch => 'Choose a branch';

  @override
  String get dashboardCreate => 'Create';

  @override
  String get dashboardCreateSub => 'New budget';

  @override
  String get dashboardModify => 'Modify';

  @override
  String get dashboardModifySub => 'Your forest';

  @override
  String get dashboardGoals => 'Goals';

  @override
  String get dashboardGoalsSub => 'Savings targets';

  @override
  String get dashboardSettings => 'Settings';

  @override
  String get dashboardSettingsSub => 'Preferences';

  @override
  String get dashboardBackToGround => 'Back to ground';

  @override
  String get loginWelcomeBack => 'Welcome back to your grove';

  @override
  String get loginPlantForest => 'Plant your forest in the cloud';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get username => 'Username';

  @override
  String get usernameHelper =>
      'How friends find you — 3-20 letters, numbers or _';

  @override
  String get createAccount => 'Create account';

  @override
  String get signIn => 'Sign in';

  @override
  String get newHereCreate => 'New here? Create an account';

  @override
  String get haveAccountSignIn => 'Already have an account? Sign in';

  @override
  String get enterEmail => 'Enter your email';

  @override
  String get enterValidEmail => 'Enter a valid email';

  @override
  String get passwordTooShort => 'At least 6 characters';

  @override
  String get accountCreatedConfirm =>
      'Account created. Check your email to confirm, then sign in.';

  @override
  String get somethingWentWrong => 'Something went wrong. Please try again.';

  @override
  String get onboardingDisplayNameLabel => 'Display name (optional)';

  @override
  String get onboardingDisplayNameHelper =>
      'Shown to friends instead of @username';

  @override
  String get onboardingUsernameHelper => '3-20 letters, numbers or _';

  @override
  String get onboardingEnterForest => 'Enter the forest';

  @override
  String get onboardingAcornWelcome =>
      'Hi, I\'m Acorn! 🌰 Welcome to Budget Tree. Pick a username to finish setting up — it\'s how friends find you, but you can grow your forest with or without them.';

  @override
  String get onboardingAcornBusy => 'Planting your account… one sec! 🌱';

  @override
  String get onboardingAcornError =>
      'Hmm, that didn\'t take — let\'s try a different name!';

  @override
  String get chooseUsername => 'Choose a username';

  @override
  String get usernameRule => '3-20 letters, numbers or underscore';

  @override
  String get usernameTaken => 'That username is taken. Try another.';

  @override
  String get onboardingSaveError =>
      'Couldn\'t save your profile. Check your connection and try again.';

  @override
  String get add => 'Add';

  @override
  String get accept => 'Accept';

  @override
  String get decline => 'Decline';

  @override
  String get completedCheck => 'Completed ✓';

  @override
  String get featured => 'FEATURED';

  @override
  String get myBudgets => 'My Budgets';

  @override
  String get noBudgetsTitle => 'No saved budgets yet';

  @override
  String get noBudgetsBody => 'Create one from the dashboard';

  @override
  String noSharedGoalsYet(String name) {
    return '$name hasn\'t shared any goals yet.';
  }

  @override
  String percentThere(int pct) {
    return '$pct% there';
  }

  @override
  String get friendsNeedAccountTitle => 'Friends need an account';

  @override
  String get friendsNeedAccountBody =>
      'Sign in with an internet connection to add friends and share goals.';

  @override
  String get couldntLoadFriends => 'Couldn\'t load friends';

  @override
  String get friendsTablesMissing =>
      'The friends tables aren\'t set up yet. Apply the database migration with `supabase db push`, then retry.';

  @override
  String get couldntReachFriends =>
      'Couldn\'t reach friends. Check your connection and try again.';

  @override
  String requestSentTo(String username) {
    return 'Request sent to @$username';
  }

  @override
  String youAreUsername(String username) {
    return 'You are @$username';
  }

  @override
  String get howFriendsSeeStatus => 'How friends see your status:';

  @override
  String get addAFriend => 'Add a friend';

  @override
  String get searchByUsername => 'Search by username';

  @override
  String get requests => 'Requests';

  @override
  String get noFriendsYet => 'No friends yet — add someone by their username.';

  @override
  String sharedGoalsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shared goals',
      one: '1 shared goal',
      zero: 'no shared goals',
    );
    return '$_temp0';
  }

  @override
  String get pinWhichGoal => 'Pin which goal?';

  @override
  String get shareGoalFirstToPin =>
      'Share a goal with friends first to pin it as your status.';

  @override
  String get statusModeBest => 'Best goal';

  @override
  String get statusModeAverage => 'Average of goals';

  @override
  String get statusModeWorst => 'Worst goal';

  @override
  String get statusModeGoal => 'A chosen goal';

  @override
  String get groveTitle => 'The Grove';

  @override
  String get loadingEllipsis => 'Loading…';

  @override
  String get plantAGoal => 'Plant a Goal';

  @override
  String get goalReached => 'Goal reached!';

  @override
  String goalsGrowing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count goals are growing',
      one: '1 goal is growing',
    );
    return '$_temp0';
  }

  @override
  String completedFilter(int count) {
    return 'Completed · $count';
  }

  @override
  String savingStreakWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-week saving streak',
      one: '1-week saving streak',
    );
    return '$_temp0';
  }

  @override
  String get startSavingStreak => 'Start a saving streak';

  @override
  String get streakAtRisk => 'Add to a goal this week to keep it alive';

  @override
  String streakBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks',
      one: '1 week',
    );
    return 'Best: $_temp0 · nice work!';
  }

  @override
  String get depositEachWeek => 'Deposit each week to grow a streak';

  @override
  String monthThisAmount(String amount) {
    return '$amount this month';
  }

  @override
  String monthVsLastUp(int pct) {
    return '+$pct% vs last month';
  }

  @override
  String monthVsLastDown(int pct) {
    return '$pct% vs last month';
  }

  @override
  String get noSaplingsTitle => 'No saplings yet';

  @override
  String get noSaplingsBody =>
      'Plant a goal sapling and watch it grow as you save toward it.';

  @override
  String get plantFirstSapling => 'Plant Your First Sapling';

  @override
  String get noSaplingsCategoryTitle => 'No saplings in this category yet';

  @override
  String get noSaplingsCategoryBody =>
      'Plant a goal in this category or clear the filter to see all saplings.';

  @override
  String get showAll => 'Show all';

  @override
  String get shareThisGoalTitle => 'Share this goal?';

  @override
  String get shareThisGoalBody =>
      'Do you want your friends to see this goal and its plant in their friends list? You can change this anytime on the goal.';

  @override
  String get keepPrivate => 'Keep private';

  @override
  String get shareWithFriends => 'Share with friends';

  @override
  String get newSapling => 'New Sapling';

  @override
  String get aboutThisGoal => 'About this goal';

  @override
  String get goalName => 'Goal name';

  @override
  String get goalNameHint => 'e.g. Trip to Japan';

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String get notesHint => 'Why does this matter to you?';

  @override
  String get howMuch => 'How much?';

  @override
  String get targetAmount => 'Target amount';

  @override
  String get targetHint => 'e.g. 3500';

  @override
  String get growForever => 'Grow forever (no target)';

  @override
  String get growForeverDesc =>
      'Sapling grows through tiers (Seedling → Ancient Oak) instead of capping.';

  @override
  String get iconLabel => 'Icon';

  @override
  String get groupOptional => 'Group (optional)';

  @override
  String get groupNote =>
      'Assigning a group tints this sapling with the group colour.';

  @override
  String get plantASaplingTitle => 'Plant a Sapling';

  @override
  String get plantASaplingSub => 'A new goal begins as a single seed';

  @override
  String get plantSapling => 'Plant Sapling';

  @override
  String get delete => 'Delete';

  @override
  String get name => 'Name';

  @override
  String get featuredOnProfileSnack =>
      'Featured on your profile — friends will see this first.';

  @override
  String get removedFromProfile => 'Removed from your profile.';

  @override
  String get couldntUpdateProfile => 'Couldn\'t update your profile.';

  @override
  String get waterTheSapling => 'Water the Sapling';

  @override
  String depositToward(String name) {
    return 'Deposit toward \"$name\"';
  }

  @override
  String get deposit => 'Deposit';

  @override
  String get withdraw => 'Withdraw';

  @override
  String get goalReachedTitle => 'Goal Reached!';

  @override
  String goalReachedMsg(String name) {
    return 'Your \"$name\" sapling has grown into a mature tree. Well done!';
  }

  @override
  String get newGrowthTitle => 'New Growth!';

  @override
  String newGrowthMsg(String name, int tier, String tierName) {
    return '\"$name\" reached Tier $tier — $tierName.';
  }

  @override
  String get keepGrowing => 'Keep growing';

  @override
  String get milestoneTitle => 'Milestone!';

  @override
  String milestoneMsg(String name, String stage, int pct) {
    return '\"$name\" grew to $stage ($pct%).';
  }

  @override
  String get nice => 'Nice';

  @override
  String get removeSaplingTitle => 'Remove sapling?';

  @override
  String removeSaplingBody(String name) {
    return '\"$name\" will be permanently removed from your grove.';
  }

  @override
  String get editGoal => 'Edit Goal';

  @override
  String get target => 'Target';

  @override
  String get growForeverTiers => 'Grow forever (no target, uses tiers)';

  @override
  String get groupUpper => 'GROUP';

  @override
  String get savedUpper => 'SAVED';

  @override
  String get tierUpper => 'TIER';

  @override
  String get targetUpper => 'TARGET';

  @override
  String percentGrown(int pct) {
    return '$pct% grown';
  }

  @override
  String get noCapKeepsGrowing => 'No cap · keeps growing';

  @override
  String get goalReachedShort => 'Goal reached';

  @override
  String amountToGo(String amount) {
    return '$amount to go';
  }

  @override
  String get visibleToFriends => 'Visible to friends';

  @override
  String get privateOnlyYou => 'Private — only you';

  @override
  String get featuredOnYourProfile => 'Featured on your profile';

  @override
  String get featureOnYourProfile => 'Feature on your profile';

  @override
  String get fundedByUpper => 'FUNDED BY';

  @override
  String get adjust => 'Adjust';

  @override
  String get milestoneSeed => 'Seed';

  @override
  String get milestoneMature => 'Mature';

  @override
  String get edit => 'Edit';

  @override
  String get walkThroughForest => 'Walk through your forest';

  @override
  String get gridList => 'Grid list';

  @override
  String get removeTreeTitle => 'Remove this tree?';

  @override
  String removeTreeBody(String name) {
    return '\"$name\" will be permanently removed from your forest.';
  }

  @override
  String get yourForest => 'Your Forest';

  @override
  String budgetTreesPlanted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count budget trees planted',
      one: '1 budget tree planted',
    );
    return '$_temp0';
  }

  @override
  String get viewFullTree => 'View Full Tree';

  @override
  String get noTreesCategoryTitle => 'No trees in this category yet';

  @override
  String get noTreesCategoryBody =>
      'Either plant a new tree in this category or clear the filter to see everything.';

  @override
  String get forestEmptyTitle => 'Your forest is empty';

  @override
  String get forestEmptyBody =>
      'Plant your first budget tree by going back and creating a new budget.';

  @override
  String get goPlantATree => 'Go Plant a Tree';

  @override
  String get editBudget => 'Edit Budget';

  @override
  String get budgetName => 'Budget name';

  @override
  String get categoryUpper => 'CATEGORY';

  @override
  String incomeAmount(String amount) {
    return 'Income: $amount';
  }

  @override
  String overAmount(String amount) {
    return '⚠ Over: $amount';
  }

  @override
  String leftAmount(String amount) {
    return 'Left: $amount';
  }

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get stepIncomeTitle => 'Income Sources';

  @override
  String get stepExpensesTitle => 'Expense Branches';

  @override
  String get stepNamePayTitle => 'Name & Pay Schedule';

  @override
  String get stepIncomeSub => 'What flows into your tree?';

  @override
  String get stepExpensesSub => 'Where do the branches reach?';

  @override
  String get stepNamePaySub => 'Name your tree and set how often you\'re paid';

  @override
  String get vineSeed => 'Seed';

  @override
  String get vineBranches => 'Branches';

  @override
  String get vineRoots => 'Roots';

  @override
  String get quickPick => 'Quick-pick';

  @override
  String get addASource => 'Add a source';

  @override
  String get sourceName => 'Source name';

  @override
  String get sourceNameHint => 'e.g. Salary';

  @override
  String get amountDollar => 'Amount \$';

  @override
  String get rootsFeedingTree => 'Roots feeding the tree';

  @override
  String get totalMonthlyIncome => 'Total monthly income';

  @override
  String get canopyMeter => 'Canopy meter';

  @override
  String allocatedAmount(String amount) {
    return 'Allocated: $amount';
  }

  @override
  String overByAmount(String amount) {
    return 'Over by $amount';
  }

  @override
  String remainingAmount(String amount) {
    return 'Remaining: $amount';
  }

  @override
  String get pickABranch => 'Pick a branch';

  @override
  String get addABranch => 'Add a branch';

  @override
  String get categoryName => 'Category name';

  @override
  String get branchesReachingOut => 'Branches reaching out';

  @override
  String get nameYourTree => 'Name your tree';

  @override
  String get budgetNameHint => 'e.g. January Budget';

  @override
  String get payScheduleLabel => 'Pay schedule';

  @override
  String get payFrequencyLabel => 'Pay frequency';

  @override
  String get firstPayDate => 'First pay date';

  @override
  String firstPayOn(String date) {
    return 'First pay: $date';
  }

  @override
  String get payScheduleInfo =>
      'Your pay schedule lets the budget tree process pay cycles and feed money into your linked goals automatically.';

  @override
  String get plantMyBudgetTree => 'Plant My Budget Tree';
}
