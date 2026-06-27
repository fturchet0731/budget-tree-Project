import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
  ];

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @friends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friends;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get settingsLanguageSubtitle;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemDefault;

  /// No description provided for @dashboardChooseBranch.
  ///
  /// In en, this message translates to:
  /// **'Choose a branch'**
  String get dashboardChooseBranch;

  /// No description provided for @dashboardCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get dashboardCreate;

  /// No description provided for @dashboardCreateSub.
  ///
  /// In en, this message translates to:
  /// **'New budget'**
  String get dashboardCreateSub;

  /// No description provided for @dashboardModify.
  ///
  /// In en, this message translates to:
  /// **'Modify'**
  String get dashboardModify;

  /// No description provided for @dashboardModifySub.
  ///
  /// In en, this message translates to:
  /// **'Your forest'**
  String get dashboardModifySub;

  /// No description provided for @dashboardGoals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get dashboardGoals;

  /// No description provided for @dashboardGoalsSub.
  ///
  /// In en, this message translates to:
  /// **'Savings targets'**
  String get dashboardGoalsSub;

  /// No description provided for @dashboardSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get dashboardSettings;

  /// No description provided for @dashboardSettingsSub.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get dashboardSettingsSub;

  /// No description provided for @dashboardBackToGround.
  ///
  /// In en, this message translates to:
  /// **'Back to ground'**
  String get dashboardBackToGround;

  /// No description provided for @loginWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back to your grove'**
  String get loginWelcomeBack;

  /// No description provided for @loginPlantForest.
  ///
  /// In en, this message translates to:
  /// **'Plant your forest in the cloud'**
  String get loginPlantForest;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @usernameHelper.
  ///
  /// In en, this message translates to:
  /// **'How friends find you — 3-20 letters, numbers or _'**
  String get usernameHelper;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @newHereCreate.
  ///
  /// In en, this message translates to:
  /// **'New here? Create an account'**
  String get newHereCreate;

  /// No description provided for @haveAccountSignIn.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get haveAccountSignIn;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @accountCreatedConfirm.
  ///
  /// In en, this message translates to:
  /// **'Account created. Check your email to confirm, then sign in.'**
  String get accountCreatedConfirm;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get somethingWentWrong;

  /// No description provided for @onboardingDisplayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display name (optional)'**
  String get onboardingDisplayNameLabel;

  /// No description provided for @onboardingDisplayNameHelper.
  ///
  /// In en, this message translates to:
  /// **'Shown to friends instead of @username'**
  String get onboardingDisplayNameHelper;

  /// No description provided for @onboardingUsernameHelper.
  ///
  /// In en, this message translates to:
  /// **'3-20 letters, numbers or _'**
  String get onboardingUsernameHelper;

  /// No description provided for @onboardingEnterForest.
  ///
  /// In en, this message translates to:
  /// **'Enter the forest'**
  String get onboardingEnterForest;

  /// No description provided for @onboardingAcornWelcome.
  ///
  /// In en, this message translates to:
  /// **'Hi, I\'m Acorn! 🌰 Welcome to Budget Tree. Pick a username to finish setting up — it\'s how friends find you, but you can grow your forest with or without them.'**
  String get onboardingAcornWelcome;

  /// No description provided for @onboardingAcornBusy.
  ///
  /// In en, this message translates to:
  /// **'Planting your account… one sec! 🌱'**
  String get onboardingAcornBusy;

  /// No description provided for @onboardingAcornError.
  ///
  /// In en, this message translates to:
  /// **'Hmm, that didn\'t take — let\'s try a different name!'**
  String get onboardingAcornError;

  /// No description provided for @chooseUsername.
  ///
  /// In en, this message translates to:
  /// **'Choose a username'**
  String get chooseUsername;

  /// No description provided for @usernameRule.
  ///
  /// In en, this message translates to:
  /// **'3-20 letters, numbers or underscore'**
  String get usernameRule;

  /// No description provided for @usernameTaken.
  ///
  /// In en, this message translates to:
  /// **'That username is taken. Try another.'**
  String get usernameTaken;

  /// No description provided for @onboardingSaveError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your profile. Check your connection and try again.'**
  String get onboardingSaveError;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @completedCheck.
  ///
  /// In en, this message translates to:
  /// **'Completed ✓'**
  String get completedCheck;

  /// No description provided for @featured.
  ///
  /// In en, this message translates to:
  /// **'FEATURED'**
  String get featured;

  /// No description provided for @myBudgets.
  ///
  /// In en, this message translates to:
  /// **'My Budgets'**
  String get myBudgets;

  /// No description provided for @noBudgetsTitle.
  ///
  /// In en, this message translates to:
  /// **'No saved budgets yet'**
  String get noBudgetsTitle;

  /// No description provided for @noBudgetsBody.
  ///
  /// In en, this message translates to:
  /// **'Create one from the dashboard'**
  String get noBudgetsBody;

  /// No description provided for @noSharedGoalsYet.
  ///
  /// In en, this message translates to:
  /// **'{name} hasn\'t shared any goals yet.'**
  String noSharedGoalsYet(String name);

  /// No description provided for @percentThere.
  ///
  /// In en, this message translates to:
  /// **'{pct}% there'**
  String percentThere(int pct);

  /// No description provided for @friendsNeedAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Friends need an account'**
  String get friendsNeedAccountTitle;

  /// No description provided for @friendsNeedAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in with an internet connection to add friends and share goals.'**
  String get friendsNeedAccountBody;

  /// No description provided for @couldntLoadFriends.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load friends'**
  String get couldntLoadFriends;

  /// No description provided for @friendsTablesMissing.
  ///
  /// In en, this message translates to:
  /// **'The friends tables aren\'t set up yet. Apply the database migration with `supabase db push`, then retry.'**
  String get friendsTablesMissing;

  /// No description provided for @couldntReachFriends.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach friends. Check your connection and try again.'**
  String get couldntReachFriends;

  /// No description provided for @requestSentTo.
  ///
  /// In en, this message translates to:
  /// **'Request sent to @{username}'**
  String requestSentTo(String username);

  /// No description provided for @youAreUsername.
  ///
  /// In en, this message translates to:
  /// **'You are @{username}'**
  String youAreUsername(String username);

  /// No description provided for @howFriendsSeeStatus.
  ///
  /// In en, this message translates to:
  /// **'How friends see your status:'**
  String get howFriendsSeeStatus;

  /// No description provided for @addAFriend.
  ///
  /// In en, this message translates to:
  /// **'Add a friend'**
  String get addAFriend;

  /// No description provided for @searchByUsername.
  ///
  /// In en, this message translates to:
  /// **'Search by username'**
  String get searchByUsername;

  /// No description provided for @requests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requests;

  /// No description provided for @noFriendsYet.
  ///
  /// In en, this message translates to:
  /// **'No friends yet — add someone by their username.'**
  String get noFriendsYet;

  /// No description provided for @sharedGoalsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no shared goals} =1{1 shared goal} other{{count} shared goals}}'**
  String sharedGoalsCount(int count);

  /// No description provided for @pinWhichGoal.
  ///
  /// In en, this message translates to:
  /// **'Pin which goal?'**
  String get pinWhichGoal;

  /// No description provided for @shareGoalFirstToPin.
  ///
  /// In en, this message translates to:
  /// **'Share a goal with friends first to pin it as your status.'**
  String get shareGoalFirstToPin;

  /// No description provided for @statusModeBest.
  ///
  /// In en, this message translates to:
  /// **'Best goal'**
  String get statusModeBest;

  /// No description provided for @statusModeAverage.
  ///
  /// In en, this message translates to:
  /// **'Average of goals'**
  String get statusModeAverage;

  /// No description provided for @statusModeWorst.
  ///
  /// In en, this message translates to:
  /// **'Worst goal'**
  String get statusModeWorst;

  /// No description provided for @statusModeGoal.
  ///
  /// In en, this message translates to:
  /// **'A chosen goal'**
  String get statusModeGoal;

  /// No description provided for @groveTitle.
  ///
  /// In en, this message translates to:
  /// **'The Grove'**
  String get groveTitle;

  /// No description provided for @loadingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loadingEllipsis;

  /// No description provided for @plantAGoal.
  ///
  /// In en, this message translates to:
  /// **'Plant a Goal'**
  String get plantAGoal;

  /// No description provided for @goalReached.
  ///
  /// In en, this message translates to:
  /// **'Goal reached!'**
  String get goalReached;

  /// No description provided for @goalsGrowing.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 goal is growing} other{{count} goals are growing}}'**
  String goalsGrowing(int count);

  /// No description provided for @completedFilter.
  ///
  /// In en, this message translates to:
  /// **'Completed · {count}'**
  String completedFilter(int count);

  /// No description provided for @savingStreakWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1-week saving streak} other{{count}-week saving streak}}'**
  String savingStreakWeeks(int count);

  /// No description provided for @startSavingStreak.
  ///
  /// In en, this message translates to:
  /// **'Start a saving streak'**
  String get startSavingStreak;

  /// No description provided for @streakAtRisk.
  ///
  /// In en, this message translates to:
  /// **'Add to a goal this week to keep it alive'**
  String get streakAtRisk;

  /// No description provided for @streakBest.
  ///
  /// In en, this message translates to:
  /// **'Best: {count, plural, =1{1 week} other{{count} weeks}} · nice work!'**
  String streakBest(int count);

  /// No description provided for @depositEachWeek.
  ///
  /// In en, this message translates to:
  /// **'Deposit each week to grow a streak'**
  String get depositEachWeek;

  /// No description provided for @monthThisAmount.
  ///
  /// In en, this message translates to:
  /// **'{amount} this month'**
  String monthThisAmount(String amount);

  /// No description provided for @monthVsLastUp.
  ///
  /// In en, this message translates to:
  /// **'+{pct}% vs last month'**
  String monthVsLastUp(int pct);

  /// No description provided for @monthVsLastDown.
  ///
  /// In en, this message translates to:
  /// **'{pct}% vs last month'**
  String monthVsLastDown(int pct);

  /// No description provided for @noSaplingsTitle.
  ///
  /// In en, this message translates to:
  /// **'No saplings yet'**
  String get noSaplingsTitle;

  /// No description provided for @noSaplingsBody.
  ///
  /// In en, this message translates to:
  /// **'Plant a goal sapling and watch it grow as you save toward it.'**
  String get noSaplingsBody;

  /// No description provided for @plantFirstSapling.
  ///
  /// In en, this message translates to:
  /// **'Plant Your First Sapling'**
  String get plantFirstSapling;

  /// No description provided for @noSaplingsCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'No saplings in this category yet'**
  String get noSaplingsCategoryTitle;

  /// No description provided for @noSaplingsCategoryBody.
  ///
  /// In en, this message translates to:
  /// **'Plant a goal in this category or clear the filter to see all saplings.'**
  String get noSaplingsCategoryBody;

  /// No description provided for @showAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get showAll;

  /// No description provided for @shareThisGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Share this goal?'**
  String get shareThisGoalTitle;

  /// No description provided for @shareThisGoalBody.
  ///
  /// In en, this message translates to:
  /// **'Do you want your friends to see this goal and its plant in their friends list? You can change this anytime on the goal.'**
  String get shareThisGoalBody;

  /// No description provided for @keepPrivate.
  ///
  /// In en, this message translates to:
  /// **'Keep private'**
  String get keepPrivate;

  /// No description provided for @shareWithFriends.
  ///
  /// In en, this message translates to:
  /// **'Share with friends'**
  String get shareWithFriends;

  /// No description provided for @newSapling.
  ///
  /// In en, this message translates to:
  /// **'New Sapling'**
  String get newSapling;

  /// No description provided for @aboutThisGoal.
  ///
  /// In en, this message translates to:
  /// **'About this goal'**
  String get aboutThisGoal;

  /// No description provided for @goalName.
  ///
  /// In en, this message translates to:
  /// **'Goal name'**
  String get goalName;

  /// No description provided for @goalNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Trip to Japan'**
  String get goalNameHint;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'Why does this matter to you?'**
  String get notesHint;

  /// No description provided for @howMuch.
  ///
  /// In en, this message translates to:
  /// **'How much?'**
  String get howMuch;

  /// No description provided for @targetAmount.
  ///
  /// In en, this message translates to:
  /// **'Target amount'**
  String get targetAmount;

  /// No description provided for @targetHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 3500'**
  String get targetHint;

  /// No description provided for @growForever.
  ///
  /// In en, this message translates to:
  /// **'Grow forever (no target)'**
  String get growForever;

  /// No description provided for @growForeverDesc.
  ///
  /// In en, this message translates to:
  /// **'Sapling grows through tiers (Seedling → Ancient Oak) instead of capping.'**
  String get growForeverDesc;

  /// No description provided for @iconLabel.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get iconLabel;

  /// No description provided for @groupOptional.
  ///
  /// In en, this message translates to:
  /// **'Group (optional)'**
  String get groupOptional;

  /// No description provided for @groupNote.
  ///
  /// In en, this message translates to:
  /// **'Assigning a group tints this sapling with the group colour.'**
  String get groupNote;

  /// No description provided for @plantASaplingTitle.
  ///
  /// In en, this message translates to:
  /// **'Plant a Sapling'**
  String get plantASaplingTitle;

  /// No description provided for @plantASaplingSub.
  ///
  /// In en, this message translates to:
  /// **'A new goal begins as a single seed'**
  String get plantASaplingSub;

  /// No description provided for @plantSapling.
  ///
  /// In en, this message translates to:
  /// **'Plant Sapling'**
  String get plantSapling;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
