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
}
