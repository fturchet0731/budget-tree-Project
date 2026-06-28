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
  /// **'How friends find you. 3 to 20 letters, numbers or _'**
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
  /// **'3 to 20 letters, numbers or _'**
  String get onboardingUsernameHelper;

  /// No description provided for @onboardingEnterForest.
  ///
  /// In en, this message translates to:
  /// **'Enter the forest'**
  String get onboardingEnterForest;

  /// No description provided for @onboardingAcornWelcome.
  ///
  /// In en, this message translates to:
  /// **'Hi, I\'m Acorn! 🌰 Welcome to Budget Tree. Pick a username to finish setting up. It\'s how friends find you, but you can grow your forest with or without them.'**
  String get onboardingAcornWelcome;

  /// No description provided for @onboardingAcornBusy.
  ///
  /// In en, this message translates to:
  /// **'Planting your account… one sec! 🌱'**
  String get onboardingAcornBusy;

  /// No description provided for @onboardingAcornError.
  ///
  /// In en, this message translates to:
  /// **'Hmm, that didn\'t take. Let\'s try a different name!'**
  String get onboardingAcornError;

  /// No description provided for @chooseUsername.
  ///
  /// In en, this message translates to:
  /// **'Choose a username'**
  String get chooseUsername;

  /// No description provided for @usernameRule.
  ///
  /// In en, this message translates to:
  /// **'3 to 20 letters, numbers or underscore'**
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
  /// **'No friends yet. Add someone by their username.'**
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
  /// **'{count, plural, =1{1 week saving streak} other{{count} week saving streak}}'**
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

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @featuredOnProfileSnack.
  ///
  /// In en, this message translates to:
  /// **'Featured on your profile. Friends will see this first.'**
  String get featuredOnProfileSnack;

  /// No description provided for @removedFromProfile.
  ///
  /// In en, this message translates to:
  /// **'Removed from your profile.'**
  String get removedFromProfile;

  /// No description provided for @couldntUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update your profile.'**
  String get couldntUpdateProfile;

  /// No description provided for @waterTheSapling.
  ///
  /// In en, this message translates to:
  /// **'Water the Sapling'**
  String get waterTheSapling;

  /// No description provided for @depositToward.
  ///
  /// In en, this message translates to:
  /// **'Deposit toward \"{name}\"'**
  String depositToward(String name);

  /// No description provided for @deposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get deposit;

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @goalReachedTitle.
  ///
  /// In en, this message translates to:
  /// **'Goal Reached!'**
  String get goalReachedTitle;

  /// No description provided for @goalReachedMsg.
  ///
  /// In en, this message translates to:
  /// **'Your \"{name}\" sapling has grown into a mature tree. Well done!'**
  String goalReachedMsg(String name);

  /// No description provided for @newGrowthTitle.
  ///
  /// In en, this message translates to:
  /// **'New Growth!'**
  String get newGrowthTitle;

  /// No description provided for @newGrowthMsg.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" reached Tier {tier}, now a {tierName}.'**
  String newGrowthMsg(String name, int tier, String tierName);

  /// No description provided for @keepGrowing.
  ///
  /// In en, this message translates to:
  /// **'Keep growing'**
  String get keepGrowing;

  /// No description provided for @milestoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Milestone!'**
  String get milestoneTitle;

  /// No description provided for @milestoneMsg.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" grew to {stage} ({pct}%).'**
  String milestoneMsg(String name, String stage, int pct);

  /// No description provided for @nice.
  ///
  /// In en, this message translates to:
  /// **'Nice'**
  String get nice;

  /// No description provided for @removeSaplingTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove sapling?'**
  String get removeSaplingTitle;

  /// No description provided for @removeSaplingBody.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be permanently removed from your grove.'**
  String removeSaplingBody(String name);

  /// No description provided for @editGoal.
  ///
  /// In en, this message translates to:
  /// **'Edit Goal'**
  String get editGoal;

  /// No description provided for @target.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get target;

  /// No description provided for @growForeverTiers.
  ///
  /// In en, this message translates to:
  /// **'Grow forever (no target, uses tiers)'**
  String get growForeverTiers;

  /// No description provided for @groupUpper.
  ///
  /// In en, this message translates to:
  /// **'GROUP'**
  String get groupUpper;

  /// No description provided for @savedUpper.
  ///
  /// In en, this message translates to:
  /// **'SAVED'**
  String get savedUpper;

  /// No description provided for @tierUpper.
  ///
  /// In en, this message translates to:
  /// **'TIER'**
  String get tierUpper;

  /// No description provided for @targetUpper.
  ///
  /// In en, this message translates to:
  /// **'TARGET'**
  String get targetUpper;

  /// No description provided for @percentGrown.
  ///
  /// In en, this message translates to:
  /// **'{pct}% grown'**
  String percentGrown(int pct);

  /// No description provided for @noCapKeepsGrowing.
  ///
  /// In en, this message translates to:
  /// **'No cap · keeps growing'**
  String get noCapKeepsGrowing;

  /// No description provided for @goalReachedShort.
  ///
  /// In en, this message translates to:
  /// **'Goal reached'**
  String get goalReachedShort;

  /// No description provided for @amountToGo.
  ///
  /// In en, this message translates to:
  /// **'{amount} to go'**
  String amountToGo(String amount);

  /// No description provided for @visibleToFriends.
  ///
  /// In en, this message translates to:
  /// **'Visible to friends'**
  String get visibleToFriends;

  /// No description provided for @privateOnlyYou.
  ///
  /// In en, this message translates to:
  /// **'Private to you'**
  String get privateOnlyYou;

  /// No description provided for @featuredOnYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Featured on your profile'**
  String get featuredOnYourProfile;

  /// No description provided for @featureOnYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Feature on your profile'**
  String get featureOnYourProfile;

  /// No description provided for @fundedByUpper.
  ///
  /// In en, this message translates to:
  /// **'FUNDED BY'**
  String get fundedByUpper;

  /// No description provided for @adjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust'**
  String get adjust;

  /// No description provided for @milestoneSeed.
  ///
  /// In en, this message translates to:
  /// **'Seed'**
  String get milestoneSeed;

  /// No description provided for @milestoneMature.
  ///
  /// In en, this message translates to:
  /// **'Mature'**
  String get milestoneMature;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @walkThroughForest.
  ///
  /// In en, this message translates to:
  /// **'Walk through your forest'**
  String get walkThroughForest;

  /// No description provided for @gridList.
  ///
  /// In en, this message translates to:
  /// **'Grid list'**
  String get gridList;

  /// No description provided for @removeTreeTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this tree?'**
  String get removeTreeTitle;

  /// No description provided for @removeTreeBody.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be permanently removed from your forest.'**
  String removeTreeBody(String name);

  /// No description provided for @yourForest.
  ///
  /// In en, this message translates to:
  /// **'Your Forest'**
  String get yourForest;

  /// No description provided for @budgetTreesPlanted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 budget tree planted} other{{count} budget trees planted}}'**
  String budgetTreesPlanted(int count);

  /// No description provided for @viewFullTree.
  ///
  /// In en, this message translates to:
  /// **'View Full Tree'**
  String get viewFullTree;

  /// No description provided for @noTreesCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'No trees in this category yet'**
  String get noTreesCategoryTitle;

  /// No description provided for @noTreesCategoryBody.
  ///
  /// In en, this message translates to:
  /// **'Either plant a new tree in this category or clear the filter to see everything.'**
  String get noTreesCategoryBody;

  /// No description provided for @forestEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your forest is empty'**
  String get forestEmptyTitle;

  /// No description provided for @forestEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Plant your first budget tree by going back and creating a new budget.'**
  String get forestEmptyBody;

  /// No description provided for @goPlantATree.
  ///
  /// In en, this message translates to:
  /// **'Go Plant a Tree'**
  String get goPlantATree;

  /// No description provided for @editBudget.
  ///
  /// In en, this message translates to:
  /// **'Edit Budget'**
  String get editBudget;

  /// No description provided for @budgetName.
  ///
  /// In en, this message translates to:
  /// **'Budget name'**
  String get budgetName;

  /// No description provided for @categoryUpper.
  ///
  /// In en, this message translates to:
  /// **'CATEGORY'**
  String get categoryUpper;

  /// No description provided for @incomeAmount.
  ///
  /// In en, this message translates to:
  /// **'Income: {amount}'**
  String incomeAmount(String amount);

  /// No description provided for @overAmount.
  ///
  /// In en, this message translates to:
  /// **'⚠ Over: {amount}'**
  String overAmount(String amount);

  /// No description provided for @leftAmount.
  ///
  /// In en, this message translates to:
  /// **'Left: {amount}'**
  String leftAmount(String amount);

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @stepIncomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Income Sources'**
  String get stepIncomeTitle;

  /// No description provided for @stepExpensesTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense Branches'**
  String get stepExpensesTitle;

  /// No description provided for @stepNamePayTitle.
  ///
  /// In en, this message translates to:
  /// **'Name & Pay Schedule'**
  String get stepNamePayTitle;

  /// No description provided for @stepIncomeSub.
  ///
  /// In en, this message translates to:
  /// **'What flows into your tree?'**
  String get stepIncomeSub;

  /// No description provided for @stepExpensesSub.
  ///
  /// In en, this message translates to:
  /// **'Where do the branches reach?'**
  String get stepExpensesSub;

  /// No description provided for @stepNamePaySub.
  ///
  /// In en, this message translates to:
  /// **'Name your tree and set how often you\'re paid'**
  String get stepNamePaySub;

  /// No description provided for @vineSeed.
  ///
  /// In en, this message translates to:
  /// **'Seed'**
  String get vineSeed;

  /// No description provided for @vineBranches.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get vineBranches;

  /// No description provided for @vineRoots.
  ///
  /// In en, this message translates to:
  /// **'Roots'**
  String get vineRoots;

  /// No description provided for @quickPick.
  ///
  /// In en, this message translates to:
  /// **'Quick pick'**
  String get quickPick;

  /// No description provided for @addASource.
  ///
  /// In en, this message translates to:
  /// **'Add a source'**
  String get addASource;

  /// No description provided for @sourceName.
  ///
  /// In en, this message translates to:
  /// **'Source name'**
  String get sourceName;

  /// No description provided for @sourceNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Salary'**
  String get sourceNameHint;

  /// No description provided for @amountDollar.
  ///
  /// In en, this message translates to:
  /// **'Amount \$'**
  String get amountDollar;

  /// No description provided for @rootsFeedingTree.
  ///
  /// In en, this message translates to:
  /// **'Roots feeding the tree'**
  String get rootsFeedingTree;

  /// No description provided for @totalMonthlyIncome.
  ///
  /// In en, this message translates to:
  /// **'Total monthly income'**
  String get totalMonthlyIncome;

  /// No description provided for @canopyMeter.
  ///
  /// In en, this message translates to:
  /// **'Canopy meter'**
  String get canopyMeter;

  /// No description provided for @allocatedAmount.
  ///
  /// In en, this message translates to:
  /// **'Allocated: {amount}'**
  String allocatedAmount(String amount);

  /// No description provided for @overByAmount.
  ///
  /// In en, this message translates to:
  /// **'Over by {amount}'**
  String overByAmount(String amount);

  /// No description provided for @remainingAmount.
  ///
  /// In en, this message translates to:
  /// **'Remaining: {amount}'**
  String remainingAmount(String amount);

  /// No description provided for @pickABranch.
  ///
  /// In en, this message translates to:
  /// **'Pick a branch'**
  String get pickABranch;

  /// No description provided for @addABranch.
  ///
  /// In en, this message translates to:
  /// **'Add a branch'**
  String get addABranch;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryName;

  /// No description provided for @branchesReachingOut.
  ///
  /// In en, this message translates to:
  /// **'Branches reaching out'**
  String get branchesReachingOut;

  /// No description provided for @nameYourTree.
  ///
  /// In en, this message translates to:
  /// **'Name your tree'**
  String get nameYourTree;

  /// No description provided for @budgetNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. January Budget'**
  String get budgetNameHint;

  /// No description provided for @payScheduleLabel.
  ///
  /// In en, this message translates to:
  /// **'Pay schedule'**
  String get payScheduleLabel;

  /// No description provided for @payFrequencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Pay frequency'**
  String get payFrequencyLabel;

  /// No description provided for @firstPayDate.
  ///
  /// In en, this message translates to:
  /// **'First pay date'**
  String get firstPayDate;

  /// No description provided for @firstPayOn.
  ///
  /// In en, this message translates to:
  /// **'First pay: {date}'**
  String firstPayOn(String date);

  /// No description provided for @payScheduleInfo.
  ///
  /// In en, this message translates to:
  /// **'Your pay schedule lets the budget tree process pay cycles and feed money into your linked goals automatically.'**
  String get payScheduleInfo;

  /// No description provided for @plantMyBudgetTree.
  ///
  /// In en, this message translates to:
  /// **'Plant My Budget Tree'**
  String get plantMyBudgetTree;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @signOutQuestion.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutQuestion;

  /// No description provided for @signOutBody.
  ///
  /// In en, this message translates to:
  /// **'Your forest is saved in the cloud. Sign back in any time to bring it back.'**
  String get signOutBody;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @eraseAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Erase all data?'**
  String get eraseAllTitle;

  /// No description provided for @eraseAllBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove every budget tree and goal sapling. Your app preferences will remain. This cannot be undone.'**
  String get eraseAllBody;

  /// No description provided for @eraseEverything.
  ///
  /// In en, this message translates to:
  /// **'Erase Everything'**
  String get eraseEverything;

  /// No description provided for @absolutelySure.
  ///
  /// In en, this message translates to:
  /// **'Are you absolutely sure?'**
  String get absolutelySure;

  /// No description provided for @lastChanceBody.
  ///
  /// In en, this message translates to:
  /// **'Last chance. After this, every saved tree and goal will be gone.'**
  String get lastChanceBody;

  /// No description provided for @keepMyData.
  ///
  /// In en, this message translates to:
  /// **'Keep my data'**
  String get keepMyData;

  /// No description provided for @yesErase.
  ///
  /// In en, this message translates to:
  /// **'Yes, erase'**
  String get yesErase;

  /// No description provided for @appearanceUpper.
  ///
  /// In en, this message translates to:
  /// **'APPEARANCE'**
  String get appearanceUpper;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSize;

  /// No description provided for @scaleCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get scaleCompact;

  /// No description provided for @scaleDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get scaleDefault;

  /// No description provided for @scaleLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get scaleLarge;

  /// No description provided for @themePalette.
  ///
  /// In en, this message translates to:
  /// **'Theme palette'**
  String get themePalette;

  /// No description provided for @paletteForest.
  ///
  /// In en, this message translates to:
  /// **'Forest'**
  String get paletteForest;

  /// No description provided for @paletteMidnight.
  ///
  /// In en, this message translates to:
  /// **'Midnight'**
  String get paletteMidnight;

  /// No description provided for @paletteTwilight.
  ///
  /// In en, this message translates to:
  /// **'Twilight'**
  String get paletteTwilight;

  /// No description provided for @motion.
  ///
  /// In en, this message translates to:
  /// **'Motion'**
  String get motion;

  /// No description provided for @fullAnimations.
  ///
  /// In en, this message translates to:
  /// **'Full animations'**
  String get fullAnimations;

  /// No description provided for @fullAnimationsSub.
  ///
  /// In en, this message translates to:
  /// **'Turn off for snappier, calmer screens'**
  String get fullAnimationsSub;

  /// No description provided for @soundHaptics.
  ///
  /// In en, this message translates to:
  /// **'Sound & haptics'**
  String get soundHaptics;

  /// No description provided for @feedbackCues.
  ///
  /// In en, this message translates to:
  /// **'Feedback cues'**
  String get feedbackCues;

  /// No description provided for @feedbackCuesSub.
  ///
  /// In en, this message translates to:
  /// **'Taps and chimes when you plant, set goals, and save'**
  String get feedbackCuesSub;

  /// No description provided for @notificationsUpper.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get notificationsUpper;

  /// No description provided for @guideUpper.
  ///
  /// In en, this message translates to:
  /// **'GUIDE'**
  String get guideUpper;

  /// No description provided for @replayTutorial.
  ///
  /// In en, this message translates to:
  /// **'Replay tutorial'**
  String get replayTutorial;

  /// No description provided for @replayTutorialSub.
  ///
  /// In en, this message translates to:
  /// **'Let Acorn walk you through the app again.'**
  String get replayTutorialSub;

  /// No description provided for @accountUpper.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get accountUpper;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as'**
  String get signedInAs;

  /// No description provided for @signOutSub.
  ///
  /// In en, this message translates to:
  /// **'Your data stays safe in the cloud.'**
  String get signOutSub;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @dataUpper.
  ///
  /// In en, this message translates to:
  /// **'DATA'**
  String get dataUpper;

  /// No description provided for @eraseAllData.
  ///
  /// In en, this message translates to:
  /// **'Erase all data'**
  String get eraseAllData;

  /// No description provided for @eraseAllDataSub.
  ///
  /// In en, this message translates to:
  /// **'Removes every saved budget tree and goal sapling.'**
  String get eraseAllDataSub;

  /// No description provided for @aboutUpper.
  ///
  /// In en, this message translates to:
  /// **'ABOUT'**
  String get aboutUpper;

  /// No description provided for @builtWith.
  ///
  /// In en, this message translates to:
  /// **'Built with'**
  String get builtWith;

  /// No description provided for @budgetWarnings.
  ///
  /// In en, this message translates to:
  /// **'Budget warnings'**
  String get budgetWarnings;

  /// No description provided for @budgetWarningsSub.
  ///
  /// In en, this message translates to:
  /// **'When a budget nears or passes your income'**
  String get budgetWarningsSub;

  /// No description provided for @streakReminders.
  ///
  /// In en, this message translates to:
  /// **'Streak reminders'**
  String get streakReminders;

  /// No description provided for @streakRemindersSub.
  ///
  /// In en, this message translates to:
  /// **'A daily nudge to keep your saving streak alive'**
  String get streakRemindersSub;

  /// No description provided for @remindMeAt.
  ///
  /// In en, this message translates to:
  /// **'Remind me at'**
  String get remindMeAt;

  /// No description provided for @weeklySummary.
  ///
  /// In en, this message translates to:
  /// **'Weekly summary'**
  String get weeklySummary;

  /// No description provided for @weeklySummarySub.
  ///
  /// In en, this message translates to:
  /// **'A weekly recap of your progress'**
  String get weeklySummarySub;

  /// No description provided for @dayLabel.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get dayLabel;

  /// No description provided for @timeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeLabel;

  /// No description provided for @weekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get weekdaySun;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @saveBudgetTreeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Save Budget Tree?'**
  String get saveBudgetTreeQuestion;

  /// No description provided for @saveBudgetTreeBody.
  ///
  /// In en, this message translates to:
  /// **'Save \"{name}\" to your forest. You can view and edit it anytime from the Modify leaf.'**
  String saveBudgetTreeBody(String name);

  /// No description provided for @groupOptionalUpper.
  ///
  /// In en, this message translates to:
  /// **'GROUP (OPTIONAL)'**
  String get groupOptionalUpper;

  /// No description provided for @autoLinkBranches.
  ///
  /// In en, this message translates to:
  /// **'Automatically link branches to goals'**
  String get autoLinkBranches;

  /// No description provided for @autoLinkBranchesDesc.
  ///
  /// In en, this message translates to:
  /// **'Matches expense names to existing goal names. Linked branches feed those goals during pay cycles.'**
  String get autoLinkBranchesDesc;

  /// No description provided for @autoLinkedSnack.
  ///
  /// In en, this message translates to:
  /// **'Linked {count, plural, =1{1 branch} other{{count} branches}} to matching goals automatically.'**
  String autoLinkedSnack(int count);

  /// No description provided for @treePlantedSnack.
  ///
  /// In en, this message translates to:
  /// **'Tree planted in your forest!'**
  String get treePlantedSnack;

  /// No description provided for @processPay.
  ///
  /// In en, this message translates to:
  /// **'Process Pay'**
  String get processPay;

  /// No description provided for @saveMyTree.
  ///
  /// In en, this message translates to:
  /// **'Save My Tree'**
  String get saveMyTree;

  /// No description provided for @updateTree.
  ///
  /// In en, this message translates to:
  /// **'Update Tree'**
  String get updateTree;

  /// No description provided for @gardenersTips.
  ///
  /// In en, this message translates to:
  /// **'Gardener\'s Tips'**
  String get gardenersTips;

  /// No description provided for @gardenersTipsSub.
  ///
  /// In en, this message translates to:
  /// **'How to allocate your money better'**
  String get gardenersTipsSub;

  /// No description provided for @tapALeaf.
  ///
  /// In en, this message translates to:
  /// **'Tap a leaf to see its budget'**
  String get tapALeaf;

  /// No description provided for @payProcessed.
  ///
  /// In en, this message translates to:
  /// **'Processed {periods} pay period(s) · {amount} → {goals} goal(s). Next pay {when}.'**
  String payProcessed(int periods, String amount, int goals, String when);

  /// No description provided for @noPayPeriods.
  ///
  /// In en, this message translates to:
  /// **'No pay periods elapsed yet. Next pay {when}.'**
  String noPayPeriods(String when);

  /// No description provided for @linkBranchToGoals.
  ///
  /// In en, this message translates to:
  /// **'Link this branch to goals'**
  String get linkBranchToGoals;

  /// No description provided for @selectGoalsBranch.
  ///
  /// In en, this message translates to:
  /// **'Select goals that this \"{name}\" branch supports.'**
  String selectGoalsBranch(String name);

  /// No description provided for @noGoalsPlanted.
  ///
  /// In en, this message translates to:
  /// **'No goals planted yet'**
  String get noGoalsPlanted;

  /// No description provided for @createGoalComeBack.
  ///
  /// In en, this message translates to:
  /// **'Create a goal sapling in the Grove and come back to link it.'**
  String get createGoalComeBack;

  /// No description provided for @percentOfIncome.
  ///
  /// In en, this message translates to:
  /// **'{pct}% of your income'**
  String percentOfIncome(String pct);

  /// No description provided for @allocated.
  ///
  /// In en, this message translates to:
  /// **'Allocated'**
  String get allocated;

  /// No description provided for @ofIncome.
  ///
  /// In en, this message translates to:
  /// **'of {amount} income'**
  String ofIncome(String amount);

  /// No description provided for @linkedGoalsUpper.
  ///
  /// In en, this message translates to:
  /// **'LINKED GOALS'**
  String get linkedGoalsUpper;

  /// No description provided for @linkEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Link…'**
  String get linkEllipsis;

  /// No description provided for @notFundingGoals.
  ///
  /// In en, this message translates to:
  /// **'This branch isn\'t funding any goals yet. Tap \"Link…\" to connect it to saplings in the Grove.'**
  String get notFundingGoals;

  /// No description provided for @totalIncome.
  ///
  /// In en, this message translates to:
  /// **'Total Income'**
  String get totalIncome;

  /// No description provided for @overBudgetAmount.
  ///
  /// In en, this message translates to:
  /// **'Over budget: {amount}'**
  String overBudgetAmount(String amount);

  /// No description provided for @unallocatedAmount.
  ///
  /// In en, this message translates to:
  /// **'Unallocated: {amount}'**
  String unallocatedAmount(String amount);

  /// No description provided for @timeNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get timeNow;

  /// No description provided for @timeToday.
  ///
  /// In en, this message translates to:
  /// **'today {time}'**
  String timeToday(String time);

  /// No description provided for @timeTomorrow.
  ///
  /// In en, this message translates to:
  /// **'tomorrow'**
  String get timeTomorrow;

  /// No description provided for @timeInDays.
  ///
  /// In en, this message translates to:
  /// **'in {count} days'**
  String timeInDays(int count);

  /// No description provided for @nextPayLine.
  ///
  /// In en, this message translates to:
  /// **'next pay {when}'**
  String nextPayLine(String when);

  /// No description provided for @todayShort.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get todayShort;

  /// No description provided for @onDate.
  ///
  /// In en, this message translates to:
  /// **'on {date}'**
  String onDate(String date);

  /// No description provided for @stageSeed.
  ///
  /// In en, this message translates to:
  /// **'Seed'**
  String get stageSeed;

  /// No description provided for @stageSprout.
  ///
  /// In en, this message translates to:
  /// **'Sprout'**
  String get stageSprout;

  /// No description provided for @stageYoungSapling.
  ///
  /// In en, this message translates to:
  /// **'Young Sapling'**
  String get stageYoungSapling;

  /// No description provided for @stageSapling.
  ///
  /// In en, this message translates to:
  /// **'Sapling'**
  String get stageSapling;

  /// No description provided for @stageGrowingTree.
  ///
  /// In en, this message translates to:
  /// **'Growing Tree'**
  String get stageGrowingTree;

  /// No description provided for @stageMature.
  ///
  /// In en, this message translates to:
  /// **'Mature'**
  String get stageMature;

  /// No description provided for @tierSeedling.
  ///
  /// In en, this message translates to:
  /// **'Seedling'**
  String get tierSeedling;

  /// No description provided for @tierSapling.
  ///
  /// In en, this message translates to:
  /// **'Sapling'**
  String get tierSapling;

  /// No description provided for @tierYoungOak.
  ///
  /// In en, this message translates to:
  /// **'Young Oak'**
  String get tierYoungOak;

  /// No description provided for @tierMatureOak.
  ///
  /// In en, this message translates to:
  /// **'Mature Oak'**
  String get tierMatureOak;

  /// No description provided for @tierToweringOak.
  ///
  /// In en, this message translates to:
  /// **'Towering Oak'**
  String get tierToweringOak;

  /// No description provided for @tierAncientOak.
  ///
  /// In en, this message translates to:
  /// **'Ancient Oak'**
  String get tierAncientOak;

  /// No description provided for @badgesTitle.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get badgesTitle;

  /// No description provided for @badgesEarned.
  ///
  /// In en, this message translates to:
  /// **'{earned} of {total} earned'**
  String badgesEarned(int earned, int total);

  /// No description provided for @badgeUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Badge Unlocked!'**
  String get badgeUnlocked;

  /// No description provided for @niceExcl.
  ///
  /// In en, this message translates to:
  /// **'Nice!'**
  String get niceExcl;

  /// No description provided for @badgeMessage.
  ///
  /// In en, this message translates to:
  /// **'{title}. {desc}'**
  String badgeMessage(String title, String desc);

  /// No description provided for @achFirstSproutTitle.
  ///
  /// In en, this message translates to:
  /// **'First Sprout'**
  String get achFirstSproutTitle;

  /// No description provided for @achFirstSproutDesc.
  ///
  /// In en, this message translates to:
  /// **'Plant your first budget tree.'**
  String get achFirstSproutDesc;

  /// No description provided for @achFirstSaplingTitle.
  ///
  /// In en, this message translates to:
  /// **'First Sapling'**
  String get achFirstSaplingTitle;

  /// No description provided for @achFirstSaplingDesc.
  ///
  /// In en, this message translates to:
  /// **'Create your first savings goal.'**
  String get achFirstSaplingDesc;

  /// No description provided for @achFirstDropTitle.
  ///
  /// In en, this message translates to:
  /// **'First Drop'**
  String get achFirstDropTitle;

  /// No description provided for @achFirstDropDesc.
  ///
  /// In en, this message translates to:
  /// **'Make your first deposit toward a goal.'**
  String get achFirstDropDesc;

  /// No description provided for @achOrchardKeeperTitle.
  ///
  /// In en, this message translates to:
  /// **'Orchard Keeper'**
  String get achOrchardKeeperTitle;

  /// No description provided for @achOrchardKeeperDesc.
  ///
  /// In en, this message translates to:
  /// **'Tend three goals at once.'**
  String get achOrchardKeeperDesc;

  /// No description provided for @achGreenThumbTitle.
  ///
  /// In en, this message translates to:
  /// **'Green Thumb'**
  String get achGreenThumbTitle;

  /// No description provided for @achGreenThumbDesc.
  ///
  /// In en, this message translates to:
  /// **'Save \$1,000 across your grove.'**
  String get achGreenThumbDesc;

  /// No description provided for @achConsistentTitle.
  ///
  /// In en, this message translates to:
  /// **'Consistent'**
  String get achConsistentTitle;

  /// No description provided for @achConsistentDesc.
  ///
  /// In en, this message translates to:
  /// **'Reach a 3 week saving streak.'**
  String get achConsistentDesc;

  /// No description provided for @achFirstHarvestTitle.
  ///
  /// In en, this message translates to:
  /// **'First Harvest'**
  String get achFirstHarvestTitle;

  /// No description provided for @achFirstHarvestDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete a savings goal.'**
  String get achFirstHarvestDesc;

  /// No description provided for @achDevotedTitle.
  ///
  /// In en, this message translates to:
  /// **'Devoted'**
  String get achDevotedTitle;

  /// No description provided for @achDevotedDesc.
  ///
  /// In en, this message translates to:
  /// **'Reach an 8 week saving streak.'**
  String get achDevotedDesc;

  /// No description provided for @achMightyOakTitle.
  ///
  /// In en, this message translates to:
  /// **'Mighty Oak'**
  String get achMightyOakTitle;

  /// No description provided for @achMightyOakDesc.
  ///
  /// In en, this message translates to:
  /// **'Grow a goal to Tier 5 or beyond.'**
  String get achMightyOakDesc;

  /// No description provided for @achOldGrowthTitle.
  ///
  /// In en, this message translates to:
  /// **'Old Growth Forest'**
  String get achOldGrowthTitle;

  /// No description provided for @achOldGrowthDesc.
  ///
  /// In en, this message translates to:
  /// **'Save \$10,000 across your grove.'**
  String get achOldGrowthDesc;

  /// No description provided for @sugAddIncomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your income first'**
  String get sugAddIncomeTitle;

  /// No description provided for @sugAddIncomeReason.
  ///
  /// In en, this message translates to:
  /// **'A tree needs roots. Add an income source so we can suggest how to split it between branches and goals.'**
  String get sugAddIncomeReason;

  /// No description provided for @sugOverAllocTitle.
  ///
  /// In en, this message translates to:
  /// **'Branches outgrow the trunk'**
  String get sugOverAllocTitle;

  /// No description provided for @sugOverAllocReason.
  ///
  /// In en, this message translates to:
  /// **'You\'ve assigned {amount} more than you earn. Trim a branch or two so the tree can actually support them.'**
  String sugOverAllocReason(String amount);

  /// No description provided for @sugIdleTitle.
  ///
  /// In en, this message translates to:
  /// **'Put idle money to work'**
  String get sugIdleTitle;

  /// No description provided for @sugIdleReason.
  ///
  /// In en, this message translates to:
  /// **'{amount} ({pct}%) of your income isn\'t assigned yet. Add a savings branch and link it to a goal so it grows instead of drifting away.'**
  String sugIdleReason(String amount, int pct);

  /// No description provided for @sugPruneTitle.
  ///
  /// In en, this message translates to:
  /// **'Prune \"{name}\"'**
  String sugPruneTitle(String name);

  /// No description provided for @sugPruneReason.
  ///
  /// In en, this message translates to:
  /// **'This branch has no money flowing to it. Fund it or prune it to keep your tree focused.'**
  String get sugPruneReason;

  /// No description provided for @sugHeavyTitle.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" is a heavy branch'**
  String sugHeavyTitle(String name);

  /// No description provided for @sugHeavyReason.
  ///
  /// In en, this message translates to:
  /// **'It takes {pct}% of your income. If you can trim it, that money could feed a savings goal instead.'**
  String sugHeavyReason(int pct);

  /// No description provided for @sugFedTitle.
  ///
  /// In en, this message translates to:
  /// **'Goals are being fed'**
  String get sugFedTitle;

  /// No description provided for @sugFedReason.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 branch sends} other{{count} branches send}} money to a goal every pay cycle. Keep it up. That\'s how saplings grow.'**
  String sugFedReason(int count);

  /// No description provided for @sugLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Link a branch to a goal'**
  String get sugLinkTitle;

  /// No description provided for @sugLinkReason.
  ///
  /// In en, this message translates to:
  /// **'None of your branches feed a savings goal yet. Linking one means every pay cycle automatically waters a sapling for you.'**
  String get sugLinkReason;

  /// No description provided for @sugHealthyTitle.
  ///
  /// In en, this message translates to:
  /// **'Healthy, balanced tree'**
  String get sugHealthyTitle;

  /// No description provided for @sugHealthyReason.
  ///
  /// In en, this message translates to:
  /// **'Your branches are well proportioned and within your income. Nothing to change. Just keep watering your goals.'**
  String get sugHealthyReason;

  /// No description provided for @giconSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get giconSavings;

  /// No description provided for @giconTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get giconTravel;

  /// No description provided for @giconVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get giconVehicle;

  /// No description provided for @giconHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get giconHome;

  /// No description provided for @giconEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get giconEducation;

  /// No description provided for @giconWedding.
  ///
  /// In en, this message translates to:
  /// **'Wedding'**
  String get giconWedding;

  /// No description provided for @giconEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get giconEmergency;

  /// No description provided for @giconTech.
  ///
  /// In en, this message translates to:
  /// **'Tech'**
  String get giconTech;

  /// No description provided for @giconGift.
  ///
  /// In en, this message translates to:
  /// **'Gift'**
  String get giconGift;

  /// No description provided for @giconOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get giconOther;

  /// No description provided for @expHousing.
  ///
  /// In en, this message translates to:
  /// **'Housing'**
  String get expHousing;

  /// No description provided for @expFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get expFood;

  /// No description provided for @expTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get expTransport;

  /// No description provided for @expSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get expSavings;

  /// No description provided for @expEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get expEntertainment;

  /// No description provided for @expSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get expSubscriptions;

  /// No description provided for @expHealthcare.
  ///
  /// In en, this message translates to:
  /// **'Healthcare'**
  String get expHealthcare;

  /// No description provided for @expPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get expPersonal;

  /// No description provided for @expOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get expOther;

  /// No description provided for @incSalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get incSalary;

  /// No description provided for @incWages.
  ///
  /// In en, this message translates to:
  /// **'Wages'**
  String get incWages;

  /// No description provided for @incPartTime.
  ///
  /// In en, this message translates to:
  /// **'Part time Job'**
  String get incPartTime;

  /// No description provided for @incFreelance.
  ///
  /// In en, this message translates to:
  /// **'Freelance'**
  String get incFreelance;

  /// No description provided for @incInvestments.
  ///
  /// In en, this message translates to:
  /// **'Investments'**
  String get incInvestments;

  /// No description provided for @incDividends.
  ///
  /// In en, this message translates to:
  /// **'Dividends'**
  String get incDividends;

  /// No description provided for @incRental.
  ///
  /// In en, this message translates to:
  /// **'Rental Income'**
  String get incRental;

  /// No description provided for @incBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business Income'**
  String get incBusiness;

  /// No description provided for @incBenefits.
  ///
  /// In en, this message translates to:
  /// **'Government Benefits'**
  String get incBenefits;

  /// No description provided for @incScholarship.
  ///
  /// In en, this message translates to:
  /// **'Scholarship'**
  String get incScholarship;

  /// No description provided for @incPension.
  ///
  /// In en, this message translates to:
  /// **'Pension'**
  String get incPension;

  /// No description provided for @monJan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get monJan;

  /// No description provided for @monFeb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get monFeb;

  /// No description provided for @monMar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get monMar;

  /// No description provided for @monApr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get monApr;

  /// No description provided for @monMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monMay;

  /// No description provided for @monJun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get monJun;

  /// No description provided for @monJul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get monJul;

  /// No description provided for @monAug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get monAug;

  /// No description provided for @monSep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get monSep;

  /// No description provided for @monOct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get monOct;

  /// No description provided for @monNov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get monNov;

  /// No description provided for @monDec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get monDec;

  /// No description provided for @budgetCardCounts.
  ///
  /// In en, this message translates to:
  /// **'{expenses, plural, =1{1 expense} other{{expenses} expenses}} · {sources, plural, =1{1 source} other{{sources} sources}}'**
  String budgetCardCounts(int expenses, int sources);

  /// No description provided for @tutIntro1.
  ///
  /// In en, this message translates to:
  /// **'Hi there! I\'m Acorn, your little guide here at Budget Tree!'**
  String get tutIntro1;

  /// No description provided for @tutIntro2.
  ///
  /// In en, this message translates to:
  /// **'Instead of just telling you how things work, we\'ll do them together. You\'ll try each part yourself as we go.'**
  String get tutIntro2;

  /// No description provided for @tutIntro3.
  ///
  /// In en, this message translates to:
  /// **'Take your time; I\'ll wait at every step. Ready? First stop, the Budget patch!'**
  String get tutIntro3;

  /// No description provided for @tutClosing1.
  ///
  /// In en, this message translates to:
  /// **'And that\'s the whole forest! Tap the info button on any screen and I\'ll explain that part again.'**
  String get tutClosing1;

  /// No description provided for @tutClosing2.
  ///
  /// In en, this message translates to:
  /// **'Now let\'s grow something wonderful together. See you out there!'**
  String get tutClosing2;

  /// No description provided for @tutCreate1.
  ///
  /// In en, this message translates to:
  /// **'Here we are. This is the Create screen, where you plant a brand new budget tree.'**
  String get tutCreate1;

  /// No description provided for @tutCreate2.
  ///
  /// In en, this message translates to:
  /// **'You\'ll add what you earn, then where it goes, and a few personal details. The steps run along the vine up top.'**
  String get tutCreate2;

  /// No description provided for @tutCreate3.
  ///
  /// In en, this message translates to:
  /// **'Set your pay schedule and watch your budget sprout into a tree!'**
  String get tutCreate3;

  /// No description provided for @tutForest1.
  ///
  /// In en, this message translates to:
  /// **'This is Your Forest, where every budget you\'ve planted grows together.'**
  String get tutForest1;

  /// No description provided for @tutForest2.
  ///
  /// In en, this message translates to:
  /// **'Switch between a leafy tree view and a tidy grid up top, and filter them by category.'**
  String get tutForest2;

  /// No description provided for @tutForest3.
  ///
  /// In en, this message translates to:
  /// **'Tap any tree to tend it: review the breakdown, edit it, or clear it away.'**
  String get tutForest3;

  /// No description provided for @tutGoals1.
  ///
  /// In en, this message translates to:
  /// **'Now we\'re in The Grove, where your savings goals sprout as little saplings.'**
  String get tutGoals1;

  /// No description provided for @tutGoals2.
  ///
  /// In en, this message translates to:
  /// **'Set a target amount, then water it with deposits over time.'**
  String get tutGoals2;

  /// No description provided for @tutGoals3.
  ///
  /// In en, this message translates to:
  /// **'Each contribution helps your sapling stretch a little closer to full bloom!'**
  String get tutGoals3;

  /// No description provided for @tutSettings1.
  ///
  /// In en, this message translates to:
  /// **'Last stop: Settings, where you make the app your own.'**
  String get tutSettings1;

  /// No description provided for @tutSettings2.
  ///
  /// In en, this message translates to:
  /// **'Switch the theme between Forest, Midnight and Twilight, adjust the text size, or ease the motion.'**
  String get tutSettings2;

  /// No description provided for @tutSettings3.
  ///
  /// In en, this message translates to:
  /// **'And you can replay this whole tour from here anytime you like.'**
  String get tutSettings3;

  /// No description provided for @tutOpenCreate.
  ///
  /// In en, this message translates to:
  /// **'Open Create →'**
  String get tutOpenCreate;

  /// No description provided for @tutOpenForest.
  ///
  /// In en, this message translates to:
  /// **'Open Forest →'**
  String get tutOpenForest;

  /// No description provided for @tutOpenGoals.
  ///
  /// In en, this message translates to:
  /// **'Open the Grove →'**
  String get tutOpenGoals;

  /// No description provided for @tutOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings →'**
  String get tutOpenSettings;

  /// No description provided for @tutTaskCreate1.
  ///
  /// In en, this message translates to:
  /// **'Let\'s plant your very first budget tree, together!'**
  String get tutTaskCreate1;

  /// No description provided for @tutTaskCreate2.
  ///
  /// In en, this message translates to:
  /// **'I\'ll open the Create screen and stay right beside you, guiding each phase: the Seed, the Branches, and the Roots.'**
  String get tutTaskCreate2;

  /// No description provided for @tutTaskCreate3.
  ///
  /// In en, this message translates to:
  /// **'Tap below and we\'ll get our hands dirty!'**
  String get tutTaskCreate3;

  /// No description provided for @tutTaskForest1.
  ///
  /// In en, this message translates to:
  /// **'Now let\'s wander into Your Forest, where your budgets grow.'**
  String get tutTaskForest1;

  /// No description provided for @tutTaskForest2.
  ///
  /// In en, this message translates to:
  /// **'Tap your tree to peek inside, and try the tree and grid toggle up top.'**
  String get tutTaskForest2;

  /// No description provided for @tutTaskForest3.
  ///
  /// In en, this message translates to:
  /// **'Have a good look around, then tap the back arrow to come find me.'**
  String get tutTaskForest3;

  /// No description provided for @tutTaskGoals1.
  ///
  /// In en, this message translates to:
  /// **'Time for a savings goal! This is The Grove.'**
  String get tutTaskGoals1;

  /// No description provided for @tutTaskGoals2.
  ///
  /// In en, this message translates to:
  /// **'Tap the + to plant a sapling, give it a name and a target, and save it.'**
  String get tutTaskGoals2;

  /// No description provided for @tutTaskGoals3.
  ///
  /// In en, this message translates to:
  /// **'Then head back to me with the arrow. Off you go!'**
  String get tutTaskGoals3;

  /// No description provided for @tutTaskSettings1.
  ///
  /// In en, this message translates to:
  /// **'Last stop. Let\'s make the app yours, in Settings.'**
  String get tutTaskSettings1;

  /// No description provided for @tutTaskSettings2.
  ///
  /// In en, this message translates to:
  /// **'Try tapping a different theme and watch the whole forest change colour.'**
  String get tutTaskSettings2;

  /// No description provided for @tutTaskSettings3.
  ///
  /// In en, this message translates to:
  /// **'Come back whenever you\'re happy with the look.'**
  String get tutTaskSettings3;

  /// No description provided for @tutSuccessCreate1.
  ///
  /// In en, this message translates to:
  /// **'Look at that! Your very first tree is planted! 🌳'**
  String get tutSuccessCreate1;

  /// No description provided for @tutSuccessCreate2.
  ///
  /// In en, this message translates to:
  /// **'Wonderfully done. That budget now lives in your forest.'**
  String get tutSuccessCreate2;

  /// No description provided for @tutSuccessForest1.
  ///
  /// In en, this message translates to:
  /// **'That\'s your forest taking shape. Every budget you make plants another tree here.'**
  String get tutSuccessForest1;

  /// No description provided for @tutSuccessGoals1.
  ///
  /// In en, this message translates to:
  /// **'Marvellous! Your first sapling is reaching for the sky! 🌱'**
  String get tutSuccessGoals1;

  /// No description provided for @tutSuccessGoals2.
  ///
  /// In en, this message translates to:
  /// **'Feed it with deposits and it\'ll grow toward your target.'**
  String get tutSuccessGoals2;

  /// No description provided for @tutSuccessSettings1.
  ///
  /// In en, this message translates to:
  /// **'Looking good! You can fine tune all of that anytime.'**
  String get tutSuccessSettings1;

  /// No description provided for @tutRetryCreate1.
  ///
  /// In en, this message translates to:
  /// **'Hmm, I don\'t see a new tree yet! Want to give it another go?'**
  String get tutRetryCreate1;

  /// No description provided for @tutRetryCreate2.
  ///
  /// In en, this message translates to:
  /// **'Add an income and an expense, then Plant and Save your tree. Or skip this step for now.'**
  String get tutRetryCreate2;

  /// No description provided for @tutRetryGoals1.
  ///
  /// In en, this message translates to:
  /// **'No sapling planted yet. Shall we try once more?'**
  String get tutRetryGoals1;

  /// No description provided for @tutRetryGoals2.
  ///
  /// In en, this message translates to:
  /// **'Tap the + and save a goal, or skip this step and come back later.'**
  String get tutRetryGoals2;

  /// No description provided for @tutSkipCreate1.
  ///
  /// In en, this message translates to:
  /// **'No worries! You can plant a budget anytime from the Create leaf.'**
  String get tutSkipCreate1;

  /// No description provided for @tutSkipGoals1.
  ///
  /// In en, this message translates to:
  /// **'That\'s okay! Plant a goal whenever you\'re ready from the Goals leaf.'**
  String get tutSkipGoals1;

  /// No description provided for @tutStep0a.
  ///
  /// In en, this message translates to:
  /// **'🌱 The Seed phase. Every tree starts with what feeds it: your income.'**
  String get tutStep0a;

  /// No description provided for @tutStep0b.
  ///
  /// In en, this message translates to:
  /// **'Type a source like \"Salary\", enter the amount, and tap the + to add it.'**
  String get tutStep0b;

  /// No description provided for @tutStep0c.
  ///
  /// In en, this message translates to:
  /// **'Add each way you earn. When you\'re ready, tap Next down below.'**
  String get tutStep0c;

  /// No description provided for @tutStep1a.
  ///
  /// In en, this message translates to:
  /// **'🌿 The Branches. This is where your money reaches out: your expenses.'**
  String get tutStep1a;

  /// No description provided for @tutStep1b.
  ///
  /// In en, this message translates to:
  /// **'Pick a category, name it, set an amount, and add it. Watch how much is left to allocate up top.'**
  String get tutStep1b;

  /// No description provided for @tutStep1c.
  ///
  /// In en, this message translates to:
  /// **'Add your main costs, then tap Next to set your roots.'**
  String get tutStep1c;

  /// No description provided for @tutStep2a.
  ///
  /// In en, this message translates to:
  /// **'🪵 The Roots: the details that ground your tree.'**
  String get tutStep2a;

  /// No description provided for @tutStep2b.
  ///
  /// In en, this message translates to:
  /// **'Name your budget and choose your pay schedule, which is how often money flows into your goals.'**
  String get tutStep2b;

  /// No description provided for @tutStep2c.
  ///
  /// In en, this message translates to:
  /// **'All filled in? Tap \"Plant My Budget Tree\" below to grow it!'**
  String get tutStep2c;

  /// No description provided for @tutSaveTree1.
  ///
  /// In en, this message translates to:
  /// **'Look at it grow, that\'s your budget as a living tree! 🌳'**
  String get tutSaveTree1;

  /// No description provided for @tutSaveTree2.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Save My Tree\" at the bottom right to plant it in your forest for keeps.'**
  String get tutSaveTree2;

  /// No description provided for @tourLetsGo.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go!'**
  String get tourLetsGo;

  /// No description provided for @tourSkipTour.
  ///
  /// In en, this message translates to:
  /// **'Skip tour'**
  String get tourSkipTour;

  /// No description provided for @tourLetsGrow.
  ///
  /// In en, this message translates to:
  /// **'Let\'s grow!'**
  String get tourLetsGrow;

  /// No description provided for @tourClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get tourClose;

  /// No description provided for @tourTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tourTryAgain;

  /// No description provided for @tourSkipStep.
  ///
  /// In en, this message translates to:
  /// **'Skip step'**
  String get tourSkipStep;

  /// No description provided for @tourNextStop.
  ///
  /// In en, this message translates to:
  /// **'Next stop →'**
  String get tourNextStop;

  /// No description provided for @tourTapContinue.
  ///
  /// In en, this message translates to:
  /// **'Tap to continue'**
  String get tourTapContinue;

  /// No description provided for @tourSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get tourSkip;

  /// No description provided for @tourTapFinish.
  ///
  /// In en, this message translates to:
  /// **'Tap to finish'**
  String get tourTapFinish;
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
