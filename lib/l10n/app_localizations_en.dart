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
      'How friends find you. 3 to 20 letters, numbers or _';

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
  String get onboardingUsernameHelper => '3 to 20 letters, numbers or _';

  @override
  String get onboardingEnterForest => 'Enter the forest';

  @override
  String get onboardingAcornWelcome =>
      'Hi, I\'m Acorn! 🌰 Welcome to Budget Tree. Pick a username to finish setting up. It\'s how friends find you, but you can grow your forest with or without them.';

  @override
  String get onboardingAcornBusy => 'Planting your account… one sec! 🌱';

  @override
  String get onboardingAcornError =>
      'Hmm, that didn\'t take. Let\'s try a different name!';

  @override
  String get chooseUsername => 'Choose a username';

  @override
  String get usernameRule => '3 to 20 letters, numbers or underscore';

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
  String get noFriendsYet => 'No friends yet. Add someone by their username.';

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
      other: '$count week saving streak',
      one: '1 week saving streak',
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
      'Featured on your profile. Friends will see this first.';

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
    return '\"$name\" reached Tier $tier, now a $tierName.';
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
  String get privateOnlyYou => 'Private to you';

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
  String get quickPick => 'Quick pick';

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

  @override
  String get settingsTitle => 'Settings';

  @override
  String get signOutQuestion => 'Sign out?';

  @override
  String get signOutBody =>
      'Your forest is saved in the cloud. Sign back in any time to bring it back.';

  @override
  String get signOut => 'Sign out';

  @override
  String get eraseAllTitle => 'Erase all data?';

  @override
  String get eraseAllBody =>
      'This will permanently remove every budget tree and goal sapling. Your app preferences will remain. This cannot be undone.';

  @override
  String get eraseEverything => 'Erase Everything';

  @override
  String get absolutelySure => 'Are you absolutely sure?';

  @override
  String get lastChanceBody =>
      'Last chance. After this, every saved tree and goal will be gone.';

  @override
  String get keepMyData => 'Keep my data';

  @override
  String get yesErase => 'Yes, erase';

  @override
  String get appearanceUpper => 'APPEARANCE';

  @override
  String get textSize => 'Text size';

  @override
  String get scaleCompact => 'Compact';

  @override
  String get scaleDefault => 'Default';

  @override
  String get scaleLarge => 'Large';

  @override
  String get themePalette => 'Theme palette';

  @override
  String get paletteForest => 'Forest';

  @override
  String get paletteMidnight => 'Midnight';

  @override
  String get paletteTwilight => 'Twilight';

  @override
  String get motion => 'Motion';

  @override
  String get fullAnimations => 'Full animations';

  @override
  String get fullAnimationsSub => 'Turn off for snappier, calmer screens';

  @override
  String get soundHaptics => 'Sound & haptics';

  @override
  String get feedbackCues => 'Feedback cues';

  @override
  String get feedbackCuesSub =>
      'Taps and chimes when you plant, set goals, and save';

  @override
  String get notificationsUpper => 'NOTIFICATIONS';

  @override
  String get guideUpper => 'GUIDE';

  @override
  String get replayTutorial => 'Replay tutorial';

  @override
  String get replayTutorialSub => 'Let Acorn walk you through the app again.';

  @override
  String get accountUpper => 'ACCOUNT';

  @override
  String get signedInAs => 'Signed in as';

  @override
  String get signOutSub => 'Your data stays safe in the cloud.';

  @override
  String get unknown => 'Unknown';

  @override
  String get dataUpper => 'DATA';

  @override
  String get eraseAllData => 'Erase all data';

  @override
  String get eraseAllDataSub =>
      'Removes every saved budget tree and goal sapling.';

  @override
  String get aboutUpper => 'ABOUT';

  @override
  String get builtWith => 'Built with';

  @override
  String get budgetWarnings => 'Budget warnings';

  @override
  String get budgetWarningsSub => 'When a budget nears or passes your income';

  @override
  String get streakReminders => 'Streak reminders';

  @override
  String get streakRemindersSub =>
      'A daily nudge to keep your saving streak alive';

  @override
  String get remindMeAt => 'Remind me at';

  @override
  String get weeklySummary => 'Weekly summary';

  @override
  String get weeklySummarySub => 'A weekly recap of your progress';

  @override
  String get dayLabel => 'Day';

  @override
  String get timeLabel => 'Time';

  @override
  String get weekdayMon => 'Monday';

  @override
  String get weekdayTue => 'Tuesday';

  @override
  String get weekdayWed => 'Wednesday';

  @override
  String get weekdayThu => 'Thursday';

  @override
  String get weekdayFri => 'Friday';

  @override
  String get weekdaySat => 'Saturday';

  @override
  String get weekdaySun => 'Sunday';

  @override
  String get done => 'Done';

  @override
  String get saveBudgetTreeQuestion => 'Save Budget Tree?';

  @override
  String saveBudgetTreeBody(String name) {
    return 'Save \"$name\" to your forest. You can view and edit it anytime from the Modify leaf.';
  }

  @override
  String get groupOptionalUpper => 'GROUP (OPTIONAL)';

  @override
  String get autoLinkBranches => 'Automatically link branches to goals';

  @override
  String get autoLinkBranchesDesc =>
      'Matches expense names to existing goal names. Linked branches feed those goals during pay cycles.';

  @override
  String autoLinkedSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count branches',
      one: '1 branch',
    );
    return 'Linked $_temp0 to matching goals automatically.';
  }

  @override
  String get treePlantedSnack => 'Tree planted in your forest!';

  @override
  String get processPay => 'Process Pay';

  @override
  String get saveMyTree => 'Save My Tree';

  @override
  String get updateTree => 'Update Tree';

  @override
  String get gardenersTips => 'Gardener\'s Tips';

  @override
  String get gardenersTipsSub => 'How to allocate your money better';

  @override
  String get tapALeaf => 'Tap a leaf to see its budget';

  @override
  String payProcessed(int periods, String amount, int goals, String when) {
    return 'Processed $periods pay period(s) · $amount → $goals goal(s). Next pay $when.';
  }

  @override
  String noPayPeriods(String when) {
    return 'No pay periods elapsed yet. Next pay $when.';
  }

  @override
  String get linkBranchToGoals => 'Link this branch to goals';

  @override
  String selectGoalsBranch(String name) {
    return 'Select goals that this \"$name\" branch supports.';
  }

  @override
  String get noGoalsPlanted => 'No goals planted yet';

  @override
  String get createGoalComeBack =>
      'Create a goal sapling in the Grove and come back to link it.';

  @override
  String percentOfIncome(String pct) {
    return '$pct% of your income';
  }

  @override
  String get allocated => 'Allocated';

  @override
  String ofIncome(String amount) {
    return 'of $amount income';
  }

  @override
  String get linkedGoalsUpper => 'LINKED GOALS';

  @override
  String get linkEllipsis => 'Link…';

  @override
  String get notFundingGoals =>
      'This branch isn\'t funding any goals yet. Tap \"Link…\" to connect it to saplings in the Grove.';

  @override
  String get totalIncome => 'Total Income';

  @override
  String overBudgetAmount(String amount) {
    return 'Over budget: $amount';
  }

  @override
  String unallocatedAmount(String amount) {
    return 'Unallocated: $amount';
  }

  @override
  String get timeNow => 'now';

  @override
  String timeToday(String time) {
    return 'today $time';
  }

  @override
  String get timeTomorrow => 'tomorrow';

  @override
  String timeInDays(int count) {
    return 'in $count days';
  }

  @override
  String nextPayLine(String when) {
    return 'next pay $when';
  }

  @override
  String get todayShort => 'today';

  @override
  String onDate(String date) {
    return 'on $date';
  }

  @override
  String get stageSeed => 'Seed';

  @override
  String get stageSprout => 'Sprout';

  @override
  String get stageYoungSapling => 'Young Sapling';

  @override
  String get stageSapling => 'Sapling';

  @override
  String get stageGrowingTree => 'Growing Tree';

  @override
  String get stageMature => 'Mature';

  @override
  String get tierSeedling => 'Seedling';

  @override
  String get tierSapling => 'Sapling';

  @override
  String get tierYoungOak => 'Young Oak';

  @override
  String get tierMatureOak => 'Mature Oak';

  @override
  String get tierToweringOak => 'Towering Oak';

  @override
  String get tierAncientOak => 'Ancient Oak';

  @override
  String get badgesTitle => 'Badges';

  @override
  String badgesEarned(int earned, int total) {
    return '$earned of $total earned';
  }

  @override
  String get badgeUnlocked => 'Badge Unlocked!';

  @override
  String get niceExcl => 'Nice!';

  @override
  String badgeMessage(String title, String desc) {
    return '$title. $desc';
  }

  @override
  String get achFirstSproutTitle => 'First Sprout';

  @override
  String get achFirstSproutDesc => 'Plant your first budget tree.';

  @override
  String get achFirstSaplingTitle => 'First Sapling';

  @override
  String get achFirstSaplingDesc => 'Create your first savings goal.';

  @override
  String get achFirstDropTitle => 'First Drop';

  @override
  String get achFirstDropDesc => 'Make your first deposit toward a goal.';

  @override
  String get achOrchardKeeperTitle => 'Orchard Keeper';

  @override
  String get achOrchardKeeperDesc => 'Tend three goals at once.';

  @override
  String get achGreenThumbTitle => 'Green Thumb';

  @override
  String get achGreenThumbDesc => 'Save \$1,000 across your grove.';

  @override
  String get achConsistentTitle => 'Consistent';

  @override
  String get achConsistentDesc => 'Reach a 3 week saving streak.';

  @override
  String get achFirstHarvestTitle => 'First Harvest';

  @override
  String get achFirstHarvestDesc => 'Complete a savings goal.';

  @override
  String get achDevotedTitle => 'Devoted';

  @override
  String get achDevotedDesc => 'Reach an 8 week saving streak.';

  @override
  String get achMightyOakTitle => 'Mighty Oak';

  @override
  String get achMightyOakDesc => 'Grow a goal to Tier 5 or beyond.';

  @override
  String get achOldGrowthTitle => 'Old Growth Forest';

  @override
  String get achOldGrowthDesc => 'Save \$10,000 across your grove.';

  @override
  String get sugAddIncomeTitle => 'Add your income first';

  @override
  String get sugAddIncomeReason =>
      'A tree needs roots. Add an income source so we can suggest how to split it between branches and goals.';

  @override
  String get sugOverAllocTitle => 'Branches outgrow the trunk';

  @override
  String sugOverAllocReason(String amount) {
    return 'You\'ve assigned $amount more than you earn. Trim a branch or two so the tree can actually support them.';
  }

  @override
  String get sugIdleTitle => 'Put idle money to work';

  @override
  String sugIdleReason(String amount, int pct) {
    return '$amount ($pct%) of your income isn\'t assigned yet. Add a savings branch and link it to a goal so it grows instead of drifting away.';
  }

  @override
  String sugPruneTitle(String name) {
    return 'Prune \"$name\"';
  }

  @override
  String get sugPruneReason =>
      'This branch has no money flowing to it. Fund it or prune it to keep your tree focused.';

  @override
  String sugHeavyTitle(String name) {
    return '\"$name\" is a heavy branch';
  }

  @override
  String sugHeavyReason(int pct) {
    return 'It takes $pct% of your income. If you can trim it, that money could feed a savings goal instead.';
  }

  @override
  String get sugFedTitle => 'Goals are being fed';

  @override
  String sugFedReason(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count branches send',
      one: '1 branch sends',
    );
    return '$_temp0 money to a goal every pay cycle. Keep it up. That\'s how saplings grow.';
  }

  @override
  String get sugLinkTitle => 'Link a branch to a goal';

  @override
  String get sugLinkReason =>
      'None of your branches feed a savings goal yet. Linking one means every pay cycle automatically waters a sapling for you.';

  @override
  String get sugHealthyTitle => 'Healthy, balanced tree';

  @override
  String get sugHealthyReason =>
      'Your branches are well proportioned and within your income. Nothing to change. Just keep watering your goals.';

  @override
  String get giconSavings => 'Savings';

  @override
  String get giconTravel => 'Travel';

  @override
  String get giconVehicle => 'Vehicle';

  @override
  String get giconHome => 'Home';

  @override
  String get giconEducation => 'Education';

  @override
  String get giconWedding => 'Wedding';

  @override
  String get giconEmergency => 'Emergency';

  @override
  String get giconTech => 'Tech';

  @override
  String get giconGift => 'Gift';

  @override
  String get giconOther => 'Other';

  @override
  String get expHousing => 'Housing';

  @override
  String get expFood => 'Food';

  @override
  String get expTransport => 'Transport';

  @override
  String get expSavings => 'Savings';

  @override
  String get expEntertainment => 'Entertainment';

  @override
  String get expSubscriptions => 'Subscriptions';

  @override
  String get expHealthcare => 'Healthcare';

  @override
  String get expPersonal => 'Personal';

  @override
  String get expOther => 'Other';

  @override
  String get incSalary => 'Salary';

  @override
  String get incWages => 'Wages';

  @override
  String get incPartTime => 'Part time Job';

  @override
  String get incFreelance => 'Freelance';

  @override
  String get incInvestments => 'Investments';

  @override
  String get incDividends => 'Dividends';

  @override
  String get incRental => 'Rental Income';

  @override
  String get incBusiness => 'Business Income';

  @override
  String get incBenefits => 'Government Benefits';

  @override
  String get incScholarship => 'Scholarship';

  @override
  String get incPension => 'Pension';

  @override
  String get monJan => 'Jan';

  @override
  String get monFeb => 'Feb';

  @override
  String get monMar => 'Mar';

  @override
  String get monApr => 'Apr';

  @override
  String get monMay => 'May';

  @override
  String get monJun => 'Jun';

  @override
  String get monJul => 'Jul';

  @override
  String get monAug => 'Aug';

  @override
  String get monSep => 'Sep';

  @override
  String get monOct => 'Oct';

  @override
  String get monNov => 'Nov';

  @override
  String get monDec => 'Dec';

  @override
  String budgetCardCounts(int expenses, int sources) {
    String _temp0 = intl.Intl.pluralLogic(
      expenses,
      locale: localeName,
      other: '$expenses expenses',
      one: '1 expense',
    );
    String _temp1 = intl.Intl.pluralLogic(
      sources,
      locale: localeName,
      other: '$sources sources',
      one: '1 source',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get tutIntro1 =>
      'Hi there! I\'m Acorn, your little guide here at Budget Tree!';

  @override
  String get tutIntro2 =>
      'Instead of just telling you how things work, we\'ll do them together. You\'ll try each part yourself as we go.';

  @override
  String get tutIntro3 =>
      'Take your time; I\'ll wait at every step. Ready? First stop, the Budget patch!';

  @override
  String get tutClosing1 =>
      'And that\'s the whole forest! Tap the info button on any screen and I\'ll explain that part again.';

  @override
  String get tutClosing2 =>
      'Now let\'s grow something wonderful together. See you out there!';

  @override
  String get tutCreate1 =>
      'Here we are. This is the Create screen, where you plant a brand new budget tree.';

  @override
  String get tutCreate2 =>
      'You\'ll add what you earn, then where it goes, and a few personal details. The steps run along the vine up top.';

  @override
  String get tutCreate3 =>
      'Set your pay schedule and watch your budget sprout into a tree!';

  @override
  String get tutForest1 =>
      'This is Your Forest, where every budget you\'ve planted grows together.';

  @override
  String get tutForest2 =>
      'Switch between a leafy tree view and a tidy grid up top, and filter them by category.';

  @override
  String get tutForest3 =>
      'Tap any tree to tend it: review the breakdown, edit it, or clear it away.';

  @override
  String get tutGoals1 =>
      'Now we\'re in The Grove, where your savings goals sprout as little saplings.';

  @override
  String get tutGoals2 =>
      'Set a target amount, then water it with deposits over time.';

  @override
  String get tutGoals3 =>
      'Each contribution helps your sapling stretch a little closer to full bloom!';

  @override
  String get tutSettings1 =>
      'Last stop: Settings, where you make the app your own.';

  @override
  String get tutSettings2 =>
      'Switch the theme between Forest, Midnight and Twilight, adjust the text size, or ease the motion.';

  @override
  String get tutSettings3 =>
      'And you can replay this whole tour from here anytime you like.';

  @override
  String get tutOpenCreate => 'Open Create →';

  @override
  String get tutOpenForest => 'Open Forest →';

  @override
  String get tutOpenGoals => 'Open the Grove →';

  @override
  String get tutOpenSettings => 'Open Settings →';

  @override
  String get tutTaskCreate1 =>
      'Let\'s plant your very first budget tree, together!';

  @override
  String get tutTaskCreate2 =>
      'I\'ll open the Create screen and stay right beside you, guiding each phase: the Seed, the Branches, and the Roots.';

  @override
  String get tutTaskCreate3 => 'Tap below and we\'ll get our hands dirty!';

  @override
  String get tutTaskForest1 =>
      'Now let\'s wander into Your Forest, where your budgets grow.';

  @override
  String get tutTaskForest2 =>
      'Tap your tree to peek inside, and try the tree and grid toggle up top.';

  @override
  String get tutTaskForest3 =>
      'Have a good look around, then tap the back arrow to come find me.';

  @override
  String get tutTaskGoals1 => 'Time for a savings goal! This is The Grove.';

  @override
  String get tutTaskGoals2 =>
      'Tap the + to plant a sapling, give it a name and a target, and save it.';

  @override
  String get tutTaskGoals3 =>
      'Then head back to me with the arrow. Off you go!';

  @override
  String get tutTaskSettings1 =>
      'Last stop. Let\'s make the app yours, in Settings.';

  @override
  String get tutTaskSettings2 =>
      'Try tapping a different theme and watch the whole forest change colour.';

  @override
  String get tutTaskSettings3 =>
      'Come back whenever you\'re happy with the look.';

  @override
  String get tutSuccessCreate1 =>
      'Look at that! Your very first tree is planted! 🌳';

  @override
  String get tutSuccessCreate2 =>
      'Wonderfully done. That budget now lives in your forest.';

  @override
  String get tutSuccessForest1 =>
      'That\'s your forest taking shape. Every budget you make plants another tree here.';

  @override
  String get tutSuccessGoals1 =>
      'Marvellous! Your first sapling is reaching for the sky! 🌱';

  @override
  String get tutSuccessGoals2 =>
      'Feed it with deposits and it\'ll grow toward your target.';

  @override
  String get tutSuccessSettings1 =>
      'Looking good! You can fine tune all of that anytime.';

  @override
  String get tutRetryCreate1 =>
      'Hmm, I don\'t see a new tree yet! Want to give it another go?';

  @override
  String get tutRetryCreate2 =>
      'Add an income and an expense, then Plant and Save your tree. Or skip this step for now.';

  @override
  String get tutRetryGoals1 =>
      'No sapling planted yet. Shall we try once more?';

  @override
  String get tutRetryGoals2 =>
      'Tap the + and save a goal, or skip this step and come back later.';

  @override
  String get tutSkipCreate1 =>
      'No worries! You can plant a budget anytime from the Create leaf.';

  @override
  String get tutSkipGoals1 =>
      'That\'s okay! Plant a goal whenever you\'re ready from the Goals leaf.';

  @override
  String get tutStep0a =>
      '🌱 The Seed phase. Every tree starts with what feeds it: your income.';

  @override
  String get tutStep0b =>
      'Type a source like \"Salary\", enter the amount, and tap the + to add it.';

  @override
  String get tutStep0c =>
      'Add each way you earn. When you\'re ready, tap Next down below.';

  @override
  String get tutStep1a =>
      '🌿 The Branches. This is where your money reaches out: your expenses.';

  @override
  String get tutStep1b =>
      'Pick a category, name it, set an amount, and add it. Watch how much is left to allocate up top.';

  @override
  String get tutStep1c =>
      'Add your main costs, then tap Next to set your roots.';

  @override
  String get tutStep2a => '🪵 The Roots: the details that ground your tree.';

  @override
  String get tutStep2b =>
      'Name your budget and choose your pay schedule, which is how often money flows into your goals.';

  @override
  String get tutStep2c =>
      'All filled in? Tap \"Plant My Budget Tree\" below to grow it!';

  @override
  String get tutSaveTree1 =>
      'Look at it grow, that\'s your budget as a living tree! 🌳';

  @override
  String get tutSaveTree2 =>
      'Tap \"Save My Tree\" at the bottom right to plant it in your forest for keeps.';

  @override
  String get tourLetsGo => 'Let\'s go!';

  @override
  String get tourSkipTour => 'Skip tour';

  @override
  String get tourLetsGrow => 'Let\'s grow!';

  @override
  String get tourClose => 'Close';

  @override
  String get tourTryAgain => 'Try again';

  @override
  String get tourSkipStep => 'Skip step';

  @override
  String get tourNextStop => 'Next stop →';

  @override
  String get tourTapContinue => 'Tap to continue';

  @override
  String get tourSkip => 'Skip';

  @override
  String get tourTapFinish => 'Tap to finish';
}
