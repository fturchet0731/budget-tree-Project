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
  String get addFriends => 'Add friends';

  @override
  String get activeNow => 'Active now';

  @override
  String get likeGoal => 'Like this goal';

  @override
  String get unlikeGoal => 'Remove your like';

  @override
  String get messageAction => 'Message';

  @override
  String get chatEmpty => 'Say hi to start the conversation.';

  @override
  String get chatHint => 'Write a message';

  @override
  String get chatSend => 'Send';

  @override
  String get social => 'Social';

  @override
  String get profile => 'Profile';

  @override
  String get bio => 'Bio';

  @override
  String get bioHint => 'Tell friends a bit about yourself';

  @override
  String get addABio => 'Add a bio';

  @override
  String get sharedGoals => 'Shared goals';

  @override
  String get shareGoalsToShowOnProfile =>
      'Goals you share will appear here for friends to see.';

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
  String get passwordTooShort => 'Use 8+ characters with a letter and a number';

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
  String get incomeAddAnother => 'Add another source';

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
  String get themePalette => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

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
  String sugGoalBranchTitle(String name) {
    return 'Add a branch for \"$name\"';
  }

  @override
  String get sugGoalBranchReason =>
      'This goal is not fed by any branch here. Link one and it gets watered every pay cycle.';

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
  String get tutStep1d =>
      'This meter always shows how much is left to allocate. If it turns red you are promising more than you earn, so trim a branch before moving on.';

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

  @override
  String get coachAcornTip => 'Acorn\'s tip';

  @override
  String get coachGotIt => 'Got it!';

  @override
  String get howThisWorks => 'How this works';

  @override
  String get tutIntroHelp =>
      'One more thing: see the little question mark near the top of a screen? Tap it any time and I will explain that part again.';

  @override
  String get tutOverBudget1 =>
      'Hold on! Your branches are asking for more money than your income brings in.';

  @override
  String tutOverBudget2(String amount) {
    return 'You are over budget by $amount. Trim some expense amounts until they fit, then we can keep going.';
  }

  @override
  String get overBudgetFixHint => 'I will fix it';

  @override
  String notifOverBudgetTitle(String name) {
    return '🌳 \"$name\" is over budget';
  }

  @override
  String notifOverBudgetMsg(String allocated, String income, String over) {
    return 'You\'ve assigned $allocated of your $income income, $over too much. Trim a branch to get back in balance.';
  }

  @override
  String notifFillingTitle(String name) {
    return '⚠️ \"$name\" is filling up';
  }

  @override
  String notifFillingMsg(String allocated, String income, String remaining) {
    return 'You\'ve assigned $allocated of $income. Only $remaining left to budget this cycle.';
  }

  @override
  String notifStreakTitleActive(int count) {
    return '🔥 $count week streak';
  }

  @override
  String get notifStreakTitleNone => '🌱 Grow a streak';

  @override
  String notifStreakActive(int count) {
    return 'You\'re on a $count week saving streak! Add to a goal today to keep it growing.';
  }

  @override
  String get notifStreakNone =>
      'Water a goal today, even a little, to start a saving streak.';

  @override
  String get notifWeeklyTitle => '📊 Your week in the grove';

  @override
  String get notifWeeklyNone =>
      'No deposits this week yet. A small amount keeps your saplings growing, and your streak alive.';

  @override
  String notifWeeklyChange(String amount, String arrow, int pct) {
    return 'This week you saved $amount ($arrow $pct% vs last week). Keep your goals growing!';
  }

  @override
  String notifWeeklyPlain(String amount) {
    return 'This week you saved $amount. Keep your goals growing!';
  }

  @override
  String get gateErrorTitle => 'Couldn\'t finish setup';

  @override
  String get gateErrorBody =>
      'We couldn\'t reach the server to set up your account. Check your connection and try again.';

  @override
  String get claimUsernameTitle => 'Pick a username';

  @override
  String get claimUsernameBody => 'This is how friends find and add you.';

  @override
  String get usernameHint => 'username';

  @override
  String get claimUsernameButton => 'Claim username';

  @override
  String get usernameTakenShort => 'That username is taken.';

  @override
  String get signedOut => 'Signed out 🌱';

  @override
  String get expenseBreakdownUpper => 'EXPENSE BREAKDOWN';

  @override
  String get categoryNameTripsHint => 'e.g. Trips';

  @override
  String get createButton => 'Create';

  @override
  String get register => 'Register';

  @override
  String get startButton => 'Start';

  @override
  String get swipeToWalk => 'Swipe to walk · tap a tree for details';

  @override
  String get tapForDetails => 'Tap for details';

  @override
  String get newCategoryTitle => 'New Category';

  @override
  String get newCategoryBody =>
      'Name your category. Trees and saplings in this category will be tinted with the chosen colour.';

  @override
  String get colourUpper => 'COLOUR';

  @override
  String get homeSlogan => 'Grow your Forest, Grow your Savings';

  @override
  String get newTreeInForest => 'A new tree is growing in your forest!';

  @override
  String get deleteCategoryTitle => 'Delete group?';

  @override
  String deleteCategoryBody(String name) {
    return 'Delete the group \"$name\"? Trees and saplings in it will simply lose their colour tag.';
  }

  @override
  String get longPressToDeleteGroup => 'Long press a group to delete it';

  @override
  String sharedByName(String name) {
    return 'Shared by $name';
  }

  @override
  String get savingsAndGoals => 'Savings and goals';

  @override
  String get stepPlanTitle => 'Smart Plan';

  @override
  String get stepPlanSub => 'Let the coach split your income';

  @override
  String get vinePlan => 'Plan';

  @override
  String leaveBlankForSuggested(String amount) {
    return 'Leave blank and the coach uses $amount each time.';
  }

  @override
  String sameMonthlyAs(String amount) {
    return 'about $amount a month';
  }

  @override
  String get tourCancelTour => 'Cancel tour';

  @override
  String get tourSkipSection => 'Skip this section';

  @override
  String get stepFinishTitle => 'Finishing Touches';

  @override
  String get stepFinishSub => 'Name your tree and set its pay schedule';

  @override
  String get vineFinish => 'Finish';

  @override
  String get yourExpenses => 'Your Expenses';

  @override
  String get describeYourBudget => 'Describe Your Budget';

  @override
  String get describeYourBudgetHint =>
      'Tell the coach how you want your money to work. For example, save hard for a trip, keep some fun money, or cover the essentials first.';

  @override
  String get budgetIdeaSaveHard => 'Save as much as possible';

  @override
  String get budgetIdeaBalanced => 'Balanced lifestyle';

  @override
  String get budgetIdeaEssentials => 'Cover the essentials first';

  @override
  String get budgetIdeaDebt => 'Pay off debt fast';

  @override
  String get amountOptionalLabel => 'Amount (optional)';

  @override
  String get amountOptionalHint =>
      'Not sure how much? Leave it blank and let the coach decide.';

  @override
  String get pickAPlan => 'Pick a plan';

  @override
  String get regeneratePlans => 'Regenerate plans';

  @override
  String get setAmountsMyself => 'Set amounts myself';

  @override
  String get setAmounts => 'Set Amounts';

  @override
  String get aiUnavailableManual =>
      'The coach is not reachable right now, so set your amounts here instead.';

  @override
  String get useTheseAmounts => 'Use these amounts';

  @override
  String get useAiPlansInstead => 'Use AI plans instead';

  @override
  String get allocationsReady => 'Allocations ready';

  @override
  String get thinkingUp => 'Thinking up plans...';

  @override
  String get generatePlans => 'Generate plans with AI';

  @override
  String get tutStepPlanA =>
      'Now the fun part. Tell me what you want your budget to feel like.';

  @override
  String get tutStepPlanB =>
      'I will suggest a few ways to split your income that fit what you said.';

  @override
  String get tutStepPlanC =>
      'Pick the one you like, or tweak the amounts yourself.';

  @override
  String get fundFromBranchTitle => 'Fund this goal?';

  @override
  String get fundFromBranchBody =>
      'Link a budget branch so this goal is watered automatically each pay cycle.';

  @override
  String get notNow => 'Not now';

  @override
  String get targetDateLabel => 'Target Date';

  @override
  String get pickATargetDate => 'Pick a target date';

  @override
  String get planWithAi => 'Plan with AI';

  @override
  String get calculateMonthly => 'Calculate monthly';

  @override
  String recommendedMonthly(String amount) {
    return 'Save $amount per month to reach it';
  }

  @override
  String planMonthsLine(String amount, int months) {
    return '$amount per month finishes in about $months months';
  }

  @override
  String get alternativeDates => 'ALTERNATIVE DATES';

  @override
  String get aiUnavailableSimple =>
      'The coach is not reachable, so here is the simple monthly figure.';

  @override
  String get reflectionWeeklyTitle => 'Your week in the forest';

  @override
  String get reflectionMonthlyTitle => 'Your month in the forest';

  @override
  String get notifReflectionTitle => 'Your reflection is ready';

  @override
  String get aiCoachUpper => 'AI COACH';

  @override
  String get aiCoach => 'AI coach';

  @override
  String get aiCoachSub =>
      'Smart budget and goal plans, plus weekly reflections';

  @override
  String get aiCoachNeedsOnline => 'Sign in and connect to use the AI coach.';

  @override
  String get goalStepName => 'Name';

  @override
  String get goalStepAmount => 'Amount';

  @override
  String get aiPlanPromptTitle => 'Want help planning?';

  @override
  String get aiPlanPromptBody =>
      'The coach can suggest how much to save each month and dates that fit your income. Or set it up yourself.';

  @override
  String get setItUpMyself => 'I will set it up myself';

  @override
  String get goalStepWhen => 'Timeframe';

  @override
  String get timeframeNote =>
      'When would you like to reach this goal? We will shape a watering plan around it.';

  @override
  String get timeframeUncappedNote =>
      'Grow forever goals have no deadline. Pick a date if you want a target, or skip ahead.';

  @override
  String get wateringPlanTitle => 'Watering plan';

  @override
  String get wateringPlanIntro =>
      'Choose how often and how much to water this goal. We will remind you so you stay on schedule.';

  @override
  String get remindToWaterTitle => 'Remind me to water';

  @override
  String get remindToWaterSub =>
      'Get a heads up before each watering is due, and a nudge on the day.';

  @override
  String planAboutMonths(int months) {
    return 'About $months months to reach it';
  }

  @override
  String get customWaterTitle => 'Set your own';

  @override
  String get amountPerWatering => 'Amount per watering';

  @override
  String get cadenceWeekly => 'Weekly';

  @override
  String get cadenceBiweekly => 'Biweekly';

  @override
  String get cadenceMonthly => 'Monthly';

  @override
  String get cadenceEveryWeekly => 'every week';

  @override
  String get cadenceEveryBiweekly => 'every 2 weeks';

  @override
  String get cadenceEveryMonthly => 'every month';

  @override
  String get wateringReminders => 'Watering reminders';

  @override
  String get wateringRemindersSub =>
      'Reminders to water your goals on schedule';

  @override
  String notifWaterDueTitle(String name) {
    return '💧 Time to water $name';
  }

  @override
  String notifWaterDueMsg(String name, String amount) {
    return 'Your $name sapling is due for $amount. Water it to stay on track.';
  }

  @override
  String notifWaterSoonTitle(String name) {
    return '🌱 $name watering coming up';
  }

  @override
  String notifWaterSoonMsg(String name, String amount) {
    return 'Heads up: $name is due for $amount in 2 days.';
  }

  @override
  String get stepSurveyTitle => 'A few quick questions';

  @override
  String get stepSurveySub => 'Help the coach size your budget';

  @override
  String get vineSurvey => 'Survey';

  @override
  String get surveyIntroTitle => 'Tell us about you';

  @override
  String get surveyIntroBody =>
      'Answer a few quick questions and the coach will estimate amounts for any expense you left blank. Every question is optional.';

  @override
  String get budgetNoteTitle => 'Anything else? (optional)';

  @override
  String get budgetNoteHint =>
      'For example: I want to save hard for a house, or keep some fun money.';

  @override
  String get leftoverGoalTitle => 'Grow a goal with your leftover';

  @override
  String leftoverGoalBody(String amount) {
    return 'You have $amount left over. Send it to a goal and it becomes a branch that funds the goal each pay cycle.';
  }

  @override
  String get growAGoalWithIt => 'Grow a goal with it';

  @override
  String get leftoverPickGoalTitle => 'Send leftover to';

  @override
  String get leftoverNewGoal => 'Create a new goal';

  @override
  String get leftoverNewGoalTitle => 'Name your goal';

  @override
  String get surveyHousehold => 'How many people are in your household?';

  @override
  String get surveyHouseholdJustMe => 'Just me';

  @override
  String get surveyHouseholdTwo => 'Two';

  @override
  String get surveyHouseholdThreeFour => '3 to 4';

  @override
  String get surveyHouseholdFivePlus => '5 or more';

  @override
  String get surveyDining => 'How often do you eat out?';

  @override
  String get surveyDiningRarely => 'Rarely';

  @override
  String get surveyDiningSometimes => 'Sometimes';

  @override
  String get surveyDiningOften => 'Often';

  @override
  String get surveyHousing => 'What is your housing like?';

  @override
  String get surveyHousingRent => 'I rent';

  @override
  String get surveyHousingFamily => 'With family';

  @override
  String get surveyCommute => 'How do you get around?';

  @override
  String get surveyCommuteCar => 'Car';

  @override
  String get surveyCommuteTransit => 'Transit';

  @override
  String get surveyCommuteActive => 'Bike or walk';

  @override
  String get surveyCommuteRemote => 'I work from home';

  @override
  String get surveyPriority => 'What matters most right now?';

  @override
  String get surveyPrioritySave => 'Saving hard';

  @override
  String get surveyPriorityBalanced => 'A balance';

  @override
  String get surveyPriorityEnjoy => 'Enjoying now';

  @override
  String get surveyDebt => 'Any debt payments?';

  @override
  String get surveyDebtNone => 'None';

  @override
  String get surveyDebtSome => 'Some';

  @override
  String get surveyDebtLots => 'A lot';

  @override
  String get surveyKids => 'Any children or dependents at home?';

  @override
  String get surveyKidsNone => 'None';

  @override
  String get surveyKidsOne => 'One';

  @override
  String get surveyKidsTwoThree => '2 to 3';

  @override
  String get surveyKidsFourPlus => '4 or more';

  @override
  String get surveyChildcare => 'What does their care or schooling cost you?';

  @override
  String get surveyChildcareDaycare => 'Paid daycare';

  @override
  String get surveyChildcareSchool => 'School fees or activities';

  @override
  String get surveyChildcareFamily => 'Family helps out';

  @override
  String get surveyChildcareNone => 'Nothing regular';

  @override
  String get surveyHousingMortgage => 'I own with a mortgage';

  @override
  String get surveyHousingOwned => 'I own outright';

  @override
  String get surveyRentShare => 'Do you split the rent with anyone?';

  @override
  String get surveyRentShareAlone => 'I pay it all';

  @override
  String get surveyRentShareSplit => 'We split it';

  @override
  String get surveyHomeUpkeep =>
      'Are property tax and upkeep part of your payment?';

  @override
  String get surveyHomeUpkeepIncluded => 'Included in it';

  @override
  String get surveyHomeUpkeepSeparate => 'I pay those separately';

  @override
  String get surveyHomeUpkeepUnsure => 'Not sure';

  @override
  String get surveyCarCosts => 'What does the car cost you right now?';

  @override
  String get surveyCarCostsPaying => 'Still paying it off';

  @override
  String get surveyCarCostsOwned => 'Owned, just fuel and upkeep';

  @override
  String get surveyCarCostsShared => 'I share or borrow one';

  @override
  String get surveyGroceries => 'How do you shop for groceries?';

  @override
  String get surveyGroceriesBudget => 'I hunt for deals';

  @override
  String get surveyGroceriesMiddle => 'Whatever is convenient';

  @override
  String get surveyGroceriesPremium => 'Quality over price';

  @override
  String get surveySubscriptions =>
      'How many subscriptions are you paying for?';

  @override
  String get surveySubscriptionsNone => 'Barely any';

  @override
  String get surveySubscriptionsFew => 'A few';

  @override
  String get surveySubscriptionsMany => 'Quite a lot';

  @override
  String get surveyPets => 'Any pets?';

  @override
  String get surveyPetsNone => 'None';

  @override
  String get surveyPetsOne => 'One';

  @override
  String get surveyPetsSeveral => 'Several';

  @override
  String get surveyPetCosts => 'What do they usually cost you?';

  @override
  String get surveyPetCostsBasic => 'Just food and litter';

  @override
  String get surveyPetCostsRegular => 'Food plus regular vet visits';

  @override
  String get surveyPetCostsMedical => 'Ongoing medication or care';

  @override
  String get surveyHealth => 'Any regular health costs?';

  @override
  String get surveyHealthMinimal => 'Rarely anything';

  @override
  String get surveyHealthRegular => 'Routine visits';

  @override
  String get surveyHealthOngoing => 'Ongoing treatment or prescriptions';

  @override
  String get surveyStability => 'How steady is your income?';

  @override
  String get surveyStabilitySteady => 'The same every time';

  @override
  String get surveyStabilityVaries => 'It moves a little';

  @override
  String get surveyStabilityUnpredictable => 'It is hard to predict';

  @override
  String get surveyIncomeFloor => 'How far does it swing?';

  @override
  String get surveyIncomeFloorClose => 'A small dip at worst';

  @override
  String get surveyIncomeFloorSome => 'Some months are noticeably thinner';

  @override
  String get surveyIncomeFloorWide => 'A quiet month can be half of a good one';

  @override
  String get surveyDebtType => 'What kind of debt is it?';

  @override
  String get surveyDebtTypeCards => 'Credit cards';

  @override
  String get surveyDebtTypeStudent => 'Student loans';

  @override
  String get surveyDebtTypeVehicle => 'A vehicle loan';

  @override
  String get surveyDebtTypeMixed => 'A mix of things';

  @override
  String get surveyEmergency => 'How much of a cushion do you have saved?';

  @override
  String get surveyEmergencyNone => 'Nothing yet';

  @override
  String get surveyEmergencyUnderOne => 'Less than a month';

  @override
  String get surveyEmergencyOneToThree => '1 to 3 months';

  @override
  String get surveyEmergencyThreePlus => 'More than 3 months';

  @override
  String get surveyBudgetFor => 'What do you most want this budget to do?';

  @override
  String get surveyBudgetForCushion => 'Build a safety cushion';

  @override
  String get surveyBudgetForDebt => 'Clear my debt faster';

  @override
  String get surveyBudgetForBigGoal => 'Save for something specific';

  @override
  String get surveyBudgetForControl => 'Just see where it all goes';

  @override
  String get tutStepSurveyA => 'Now a few quick questions about your life.';

  @override
  String get tutStepSurveyB =>
      'Your answers help me size the expenses you were not sure about.';

  @override
  String get tutStepSurveyC =>
      'Answer what you like, then we will build your plans.';

  @override
  String get verifyTitle => 'Check your email';

  @override
  String verifyBody(String email) {
    return 'We sent a 6 digit code to $email. Enter it below to confirm your account.';
  }

  @override
  String get verifyCodeLabel => 'Verification code';

  @override
  String get enterCode => 'Enter the 6 digit code';

  @override
  String get verifyButton => 'Verify email';

  @override
  String get resendCode => 'Resend code';

  @override
  String get codeResent => 'We sent you a new code.';

  @override
  String get verifyBadCode =>
      'That code is wrong or expired. Try again or resend.';

  @override
  String get loginExploreFirst => 'Try it first, no account needed';

  @override
  String get pulseWaterTitle => 'Time to water';

  @override
  String pulseWaterBody(String name, String amount) {
    return 'Give $name $amount to keep it growing.';
  }

  @override
  String pulseWaterOverdueBody(String name) {
    return '$name missed its last watering. A quick deposit catches it up.';
  }

  @override
  String get pulseStreakAtRiskTitle => 'Streak at risk';

  @override
  String pulseStreakAtRiskBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count week streak',
      one: '1 week streak',
    );
    return 'Water a goal before the week ends to keep your $_temp0.';
  }

  @override
  String get pulseStreakTitle => 'Saving streak';

  @override
  String pulseStreakBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks in a row.',
      one: '1 week in a row.',
    );
    return '$_temp0 Keep it growing!';
  }

  @override
  String get pulsePlantTitle => 'Start here';

  @override
  String get pulsePlantBody =>
      'Plant your first tree and watch your budget grow.';

  @override
  String surveyProgress(int current, int total) {
    return 'Question $current of $total';
  }

  @override
  String get surveyDoneTitle => 'That is everything';

  @override
  String get surveyDoneBody =>
      'Tap an answer to change it, or add a note for the coach below.';

  @override
  String get surveySkippedLabel => 'Skipped';

  @override
  String get guestUpgradeTitle => 'Your first tree is planted!';

  @override
  String get guestUpgradeBody =>
      'Create a free account and your forest is saved to the cloud, safe even if you switch phones. Everything you made stays with you.';

  @override
  String get guestUpgradeLater => 'Maybe later';

  @override
  String get payFreqWeekly => 'Weekly';

  @override
  String get payFreqBiWeekly => 'Every 2 weeks';

  @override
  String get payFreqSemiMonthly => 'Twice a month';

  @override
  String get payFreqMonthly => 'Monthly';

  @override
  String get budgetCycleTitle => 'How often do you budget?';

  @override
  String get budgetCycleBody =>
      'Everything below counts per cycle. Income that arrives on a different rhythm is converted for you.';

  @override
  String get incomeArrives => 'How often does it arrive?';

  @override
  String approxEachCycle(String amount) {
    return '≈ $amount each cycle';
  }

  @override
  String get expenseCharged => 'How often is it charged?';

  @override
  String setAsideEachCycle(String amount) {
    return 'Set aside about $amount each cycle so the money is ready when this bill lands.';
  }

  @override
  String get scrollToContinue => 'Scroll to the end to continue';

  @override
  String totalIncomeCycle(String cycle) {
    return 'Total income ($cycle)';
  }

  @override
  String get incomeDoneAdding => 'That\'s all my income';

  @override
  String get expensesDoneAdding => 'That\'s all my expenses';

  @override
  String get expenseSummaryTitle => 'Where you stand';

  @override
  String get dataErased => 'All data erased.';

  @override
  String get defaultBudgetName => 'My Budget';

  @override
  String get notifChannelBudgetName => 'Budget warnings';

  @override
  String get notifChannelBudgetDesc =>
      'Alerts when a budget nears or exceeds your income';

  @override
  String get notifChannelStreakName => 'Streak reminders';

  @override
  String get notifChannelStreakDesc =>
      'Daily nudge to keep your saving streak alive';

  @override
  String get notifChannelWeeklyName => 'Weekly summary';

  @override
  String get notifChannelWeeklyDesc =>
      'A weekly recap of how your forest is growing';

  @override
  String get notifChannelWateringName => 'Goal watering';

  @override
  String get notifChannelWateringDesc =>
      'Reminders to water your savings goals on schedule';

  @override
  String get rhythmCustom => 'Custom';

  @override
  String get rhythmEvery => 'Every';

  @override
  String rhythmEveryDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count days',
      one: 'Every day',
    );
    return '$_temp0';
  }

  @override
  String rhythmEveryWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count weeks',
      one: 'Every week',
    );
    return '$_temp0';
  }

  @override
  String rhythmEveryMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count months',
      one: 'Every month',
    );
    return '$_temp0';
  }

  @override
  String get rhythmUnitDays => 'days';

  @override
  String get rhythmUnitWeeks => 'weeks';

  @override
  String get rhythmUnitMonths => 'months';

  @override
  String get rhythmCustomHint => 'How many?';

  @override
  String get haveADateInMind => 'Do you have a date in mind?';

  @override
  String get haveADateYes => 'Yes, by a date';

  @override
  String get haveADateYesDetail =>
      'We work out what to put in each time to land on it.';

  @override
  String get haveADateNo => 'No, just saving';

  @override
  String get haveADateNoDetail =>
      'We work out when you would reach it at your pace.';

  @override
  String get noDateExplainer =>
      'Pick a rhythm and an amount on the next step and the coach will tell you when the goal lands.';

  @override
  String reachesGoalBy(String date) {
    return 'reaches it by $date';
  }

  @override
  String get willingToPut => 'What are you willing to put in each time?';

  @override
  String get willingToPutHint =>
      'Leave blank and the coach suggests a few paces.';

  @override
  String get viewSuggestions => 'View suggestions';

  @override
  String get hideSuggestions => 'Hide suggestions';

  @override
  String get addThisSource => 'Add this source';

  @override
  String get addThisExpense => 'Add this branch';

  @override
  String get savedIncomeSources => 'Saved income sources';

  @override
  String get savedIncomeSourcesHint =>
      'Tap one to reuse it from an earlier tree.';

  @override
  String get expenseBelongsTo => 'Which branch does it belong to?';

  @override
  String get savedExpenseBranches => 'Saved branches';

  @override
  String get savedExpenseBranchesHint =>
      'Tap one to reuse it from an earlier tree.';

  @override
  String get chooseBranchToContinue => 'Pick a branch to add this expense.';
}
