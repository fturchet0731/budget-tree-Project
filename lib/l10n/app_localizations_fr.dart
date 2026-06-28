// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get retry => 'Réessayer';

  @override
  String get close => 'Fermer';

  @override
  String get next => 'Suivant';

  @override
  String get friends => 'Amis';

  @override
  String get settingsLanguageTitle => 'Langue';

  @override
  String get settingsLanguageSubtitle => 'Choisissez votre langue';

  @override
  String get systemDefault => 'Paramètre du système';

  @override
  String get dashboardChooseBranch => 'Choisissez une branche';

  @override
  String get dashboardCreate => 'Créer';

  @override
  String get dashboardCreateSub => 'Nouveau budget';

  @override
  String get dashboardModify => 'Modifier';

  @override
  String get dashboardModifySub => 'Votre forêt';

  @override
  String get dashboardGoals => 'Objectifs';

  @override
  String get dashboardGoalsSub => 'Objectifs d\'épargne';

  @override
  String get dashboardSettings => 'Réglages';

  @override
  String get dashboardSettingsSub => 'Préférences';

  @override
  String get dashboardBackToGround => 'Retour au sol';

  @override
  String get loginWelcomeBack => 'Bon retour dans votre bosquet';

  @override
  String get loginPlantForest => 'Plantez votre forêt dans le nuage';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get username => 'Nom d\'utilisateur';

  @override
  String get usernameHelper =>
      'Comment vos amis vous trouvent. 3 à 20 lettres, chiffres ou _';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get signIn => 'Se connecter';

  @override
  String get newHereCreate => 'Nouveau ici ? Créez un compte';

  @override
  String get haveAccountSignIn => 'Vous avez déjà un compte ? Connectez-vous';

  @override
  String get enterEmail => 'Saisissez votre e-mail';

  @override
  String get enterValidEmail => 'Saisissez un e-mail valide';

  @override
  String get passwordTooShort => 'Au moins 6 caractères';

  @override
  String get accountCreatedConfirm =>
      'Compte créé. Vérifiez votre e-mail pour confirmer, puis connectez-vous.';

  @override
  String get somethingWentWrong =>
      'Une erreur s\'est produite. Veuillez réessayer.';

  @override
  String get onboardingDisplayNameLabel => 'Nom affiché (facultatif)';

  @override
  String get onboardingDisplayNameHelper =>
      'Affiché à vos amis au lieu de @nomdutilisateur';

  @override
  String get onboardingUsernameHelper => '3 à 20 lettres, chiffres ou _';

  @override
  String get onboardingEnterForest => 'Entrer dans la forêt';

  @override
  String get onboardingAcornWelcome =>
      'Salut, je suis Acorn ! 🌰 Bienvenue dans Budget Tree. Choisissez un nom d\'utilisateur pour terminer la configuration. C\'est ainsi que vos amis vous trouvent, mais vous pouvez faire grandir votre forêt avec ou sans eux.';

  @override
  String get onboardingAcornBusy => 'Je plante votre compte… une seconde ! 🌱';

  @override
  String get onboardingAcornError =>
      'Hmm, ça n\'a pas marché. Essayons un autre nom !';

  @override
  String get chooseUsername => 'Choisissez un nom d\'utilisateur';

  @override
  String get usernameRule =>
      '3 à 20 lettres, chiffres ou trait de soulignement';

  @override
  String get usernameTaken =>
      'Ce nom d\'utilisateur est déjà pris. Essayez-en un autre.';

  @override
  String get onboardingSaveError =>
      'Impossible d\'enregistrer votre profil. Vérifiez votre connexion et réessayez.';

  @override
  String get add => 'Ajouter';

  @override
  String get accept => 'Accepter';

  @override
  String get decline => 'Refuser';

  @override
  String get completedCheck => 'Terminé ✓';

  @override
  String get featured => 'EN VEDETTE';

  @override
  String get myBudgets => 'Mes budgets';

  @override
  String get noBudgetsTitle => 'Aucun budget enregistré';

  @override
  String get noBudgetsBody => 'Créez-en un depuis le tableau de bord';

  @override
  String noSharedGoalsYet(String name) {
    return '$name n\'a encore partagé aucun objectif.';
  }

  @override
  String percentThere(int pct) {
    return '$pct % atteint';
  }

  @override
  String get friendsNeedAccountTitle => 'Les amis nécessitent un compte';

  @override
  String get friendsNeedAccountBody =>
      'Connectez-vous avec une connexion Internet pour ajouter des amis et partager des objectifs.';

  @override
  String get couldntLoadFriends => 'Impossible de charger les amis';

  @override
  String get friendsTablesMissing =>
      'Les tables des amis ne sont pas encore configurées. Appliquez la migration de base de données avec `supabase db push`, puis réessayez.';

  @override
  String get couldntReachFriends =>
      'Impossible de joindre les amis. Vérifiez votre connexion et réessayez.';

  @override
  String requestSentTo(String username) {
    return 'Demande envoyée à @$username';
  }

  @override
  String youAreUsername(String username) {
    return 'Vous êtes @$username';
  }

  @override
  String get howFriendsSeeStatus => 'Comment vos amis voient votre statut :';

  @override
  String get addAFriend => 'Ajouter un ami';

  @override
  String get searchByUsername => 'Rechercher par nom d\'utilisateur';

  @override
  String get requests => 'Demandes';

  @override
  String get noFriendsYet =>
      'Aucun ami pour l\'instant. Ajoutez quelqu\'un par son nom d\'utilisateur.';

  @override
  String sharedGoalsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count objectifs partagés',
      one: '1 objectif partagé',
      zero: 'aucun objectif partagé',
    );
    return '$_temp0';
  }

  @override
  String get pinWhichGoal => 'Épingler quel objectif ?';

  @override
  String get shareGoalFirstToPin =>
      'Partagez d\'abord un objectif avec vos amis pour l\'épingler comme statut.';

  @override
  String get statusModeBest => 'Meilleur objectif';

  @override
  String get statusModeAverage => 'Moyenne des objectifs';

  @override
  String get statusModeWorst => 'Pire objectif';

  @override
  String get statusModeGoal => 'Un objectif choisi';

  @override
  String get groveTitle => 'Le Bosquet';

  @override
  String get loadingEllipsis => 'Chargement…';

  @override
  String get plantAGoal => 'Planter un objectif';

  @override
  String get goalReached => 'Objectif atteint !';

  @override
  String goalsGrowing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count objectifs grandissent',
      one: '1 objectif grandit',
    );
    return '$_temp0';
  }

  @override
  String completedFilter(int count) {
    return 'Terminés · $count';
  }

  @override
  String savingStreakWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'série d\'épargne de $count semaines',
      one: 'série d\'épargne de 1 semaine',
    );
    return '$_temp0';
  }

  @override
  String get startSavingStreak => 'Commencez une série d\'épargne';

  @override
  String get streakAtRisk =>
      'Ajoutez à un objectif cette semaine pour la garder active';

  @override
  String streakBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semaines',
      one: '1 semaine',
    );
    return 'Record : $_temp0 · bravo !';
  }

  @override
  String get depositEachWeek => 'Déposez chaque semaine pour bâtir une série';

  @override
  String monthThisAmount(String amount) {
    return '$amount ce mois-ci';
  }

  @override
  String monthVsLastUp(int pct) {
    return '+$pct % vs le mois dernier';
  }

  @override
  String monthVsLastDown(int pct) {
    return '$pct % vs le mois dernier';
  }

  @override
  String get noSaplingsTitle => 'Aucun jeune arbre pour l\'instant';

  @override
  String get noSaplingsBody =>
      'Plantez un objectif et regardez-le grandir à mesure que vous épargnez.';

  @override
  String get plantFirstSapling => 'Plantez votre premier arbre';

  @override
  String get noSaplingsCategoryTitle => 'Aucun arbre dans cette catégorie';

  @override
  String get noSaplingsCategoryBody =>
      'Plantez un objectif dans cette catégorie ou effacez le filtre pour voir tous les arbres.';

  @override
  String get showAll => 'Tout afficher';

  @override
  String get shareThisGoalTitle => 'Partager cet objectif ?';

  @override
  String get shareThisGoalBody =>
      'Voulez-vous que vos amis voient cet objectif et sa plante dans leur liste d\'amis ? Vous pouvez changer cela à tout moment sur l\'objectif.';

  @override
  String get keepPrivate => 'Garder privé';

  @override
  String get shareWithFriends => 'Partager avec les amis';

  @override
  String get newSapling => 'Nouvel arbre';

  @override
  String get aboutThisGoal => 'À propos de cet objectif';

  @override
  String get goalName => 'Nom de l\'objectif';

  @override
  String get goalNameHint => 'ex. Voyage au Japon';

  @override
  String get notesOptional => 'Notes (facultatif)';

  @override
  String get notesHint => 'Pourquoi est-ce important pour vous ?';

  @override
  String get howMuch => 'Combien ?';

  @override
  String get targetAmount => 'Montant cible';

  @override
  String get targetHint => 'ex. 3500';

  @override
  String get growForever => 'Grandir sans fin (sans cible)';

  @override
  String get growForeverDesc =>
      'L\'arbre grandit par paliers (Jeune pousse → Chêne ancien) au lieu d\'être plafonné.';

  @override
  String get iconLabel => 'Icône';

  @override
  String get groupOptional => 'Groupe (facultatif)';

  @override
  String get groupNote =>
      'Attribuer un groupe colore cet arbre avec la couleur du groupe.';

  @override
  String get plantASaplingTitle => 'Planter un arbre';

  @override
  String get plantASaplingSub =>
      'Un nouvel objectif commence par une simple graine';

  @override
  String get plantSapling => 'Planter l\'arbre';

  @override
  String get delete => 'Supprimer';

  @override
  String get name => 'Nom';

  @override
  String get featuredOnProfileSnack =>
      'Mis en vedette sur votre profil. Vos amis le verront en premier.';

  @override
  String get removedFromProfile => 'Retiré de votre profil.';

  @override
  String get couldntUpdateProfile =>
      'Impossible de mettre à jour votre profil.';

  @override
  String get waterTheSapling => 'Arroser l\'arbre';

  @override
  String depositToward(String name) {
    return 'Déposer pour « $name »';
  }

  @override
  String get deposit => 'Déposer';

  @override
  String get withdraw => 'Retirer';

  @override
  String get goalReachedTitle => 'Objectif atteint !';

  @override
  String goalReachedMsg(String name) {
    return 'Votre arbre « $name » est devenu un arbre adulte. Bravo !';
  }

  @override
  String get newGrowthTitle => 'Nouvelle pousse !';

  @override
  String newGrowthMsg(String name, int tier, String tierName) {
    return '« $name » a atteint le palier $tier, désormais un $tierName.';
  }

  @override
  String get keepGrowing => 'Continuer à grandir';

  @override
  String get milestoneTitle => 'Étape franchie !';

  @override
  String milestoneMsg(String name, String stage, int pct) {
    return '« $name » a grandi jusqu\'à $stage ($pct %).';
  }

  @override
  String get nice => 'Super';

  @override
  String get removeSaplingTitle => 'Supprimer l\'arbre ?';

  @override
  String removeSaplingBody(String name) {
    return '« $name » sera définitivement retiré de votre bosquet.';
  }

  @override
  String get editGoal => 'Modifier l\'objectif';

  @override
  String get target => 'Cible';

  @override
  String get growForeverTiers => 'Grandir sans fin (sans cible, par paliers)';

  @override
  String get groupUpper => 'GROUPE';

  @override
  String get savedUpper => 'ÉPARGNÉ';

  @override
  String get tierUpper => 'PALIER';

  @override
  String get targetUpper => 'CIBLE';

  @override
  String percentGrown(int pct) {
    return '$pct % de croissance';
  }

  @override
  String get noCapKeepsGrowing => 'Sans limite · continue de grandir';

  @override
  String get goalReachedShort => 'Objectif atteint';

  @override
  String amountToGo(String amount) {
    return '$amount restants';
  }

  @override
  String get visibleToFriends => 'Visible par les amis';

  @override
  String get privateOnlyYou => 'Privé, pour vous seul';

  @override
  String get featuredOnYourProfile => 'En vedette sur votre profil';

  @override
  String get featureOnYourProfile => 'Mettre en vedette sur votre profil';

  @override
  String get fundedByUpper => 'FINANCÉ PAR';

  @override
  String get adjust => 'Ajuster';

  @override
  String get milestoneSeed => 'Graine';

  @override
  String get milestoneMature => 'Adulte';

  @override
  String get edit => 'Modifier';

  @override
  String get walkThroughForest => 'Parcourir votre forêt';

  @override
  String get gridList => 'Liste en grille';

  @override
  String get removeTreeTitle => 'Supprimer cet arbre ?';

  @override
  String removeTreeBody(String name) {
    return '« $name » sera définitivement retiré de votre forêt.';
  }

  @override
  String get yourForest => 'Votre forêt';

  @override
  String budgetTreesPlanted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arbres budgétaires plantés',
      one: '1 arbre budgétaire planté',
    );
    return '$_temp0';
  }

  @override
  String get viewFullTree => 'Voir l\'arbre complet';

  @override
  String get noTreesCategoryTitle => 'Aucun arbre dans cette catégorie';

  @override
  String get noTreesCategoryBody =>
      'Plantez un nouvel arbre dans cette catégorie ou effacez le filtre pour tout voir.';

  @override
  String get forestEmptyTitle => 'Votre forêt est vide';

  @override
  String get forestEmptyBody =>
      'Plantez votre premier arbre budgétaire en revenant en arrière et en créant un budget.';

  @override
  String get goPlantATree => 'Aller planter un arbre';

  @override
  String get editBudget => 'Modifier le budget';

  @override
  String get budgetName => 'Nom du budget';

  @override
  String get categoryUpper => 'CATÉGORIE';

  @override
  String incomeAmount(String amount) {
    return 'Revenu : $amount';
  }

  @override
  String overAmount(String amount) {
    return '⚠ Dépassement : $amount';
  }

  @override
  String leftAmount(String amount) {
    return 'Restant : $amount';
  }

  @override
  String get saveChanges => 'Enregistrer les modifications';

  @override
  String get stepIncomeTitle => 'Sources de revenu';

  @override
  String get stepExpensesTitle => 'Branches de dépenses';

  @override
  String get stepNamePayTitle => 'Nom et calendrier de paie';

  @override
  String get stepIncomeSub => 'Qu\'est-ce qui alimente votre arbre ?';

  @override
  String get stepExpensesSub => 'Où s\'étendent les branches ?';

  @override
  String get stepNamePaySub =>
      'Nommez votre arbre et indiquez votre fréquence de paie';

  @override
  String get vineSeed => 'Graine';

  @override
  String get vineBranches => 'Branches';

  @override
  String get vineRoots => 'Racines';

  @override
  String get quickPick => 'Choix rapide';

  @override
  String get addASource => 'Ajouter une source';

  @override
  String get sourceName => 'Nom de la source';

  @override
  String get sourceNameHint => 'ex. Salaire';

  @override
  String get amountDollar => 'Montant \$';

  @override
  String get rootsFeedingTree => 'Racines nourrissant l\'arbre';

  @override
  String get totalMonthlyIncome => 'Revenu mensuel total';

  @override
  String get canopyMeter => 'Jauge de la canopée';

  @override
  String allocatedAmount(String amount) {
    return 'Alloué : $amount';
  }

  @override
  String overByAmount(String amount) {
    return 'Dépassé de $amount';
  }

  @override
  String remainingAmount(String amount) {
    return 'Restant : $amount';
  }

  @override
  String get pickABranch => 'Choisir une branche';

  @override
  String get addABranch => 'Ajouter une branche';

  @override
  String get categoryName => 'Nom de la catégorie';

  @override
  String get branchesReachingOut => 'Branches qui s\'étendent';

  @override
  String get nameYourTree => 'Nommez votre arbre';

  @override
  String get budgetNameHint => 'ex. Budget de janvier';

  @override
  String get payScheduleLabel => 'Calendrier de paie';

  @override
  String get payFrequencyLabel => 'Fréquence de paie';

  @override
  String get firstPayDate => 'Date de première paie';

  @override
  String firstPayOn(String date) {
    return 'Première paie : $date';
  }

  @override
  String get payScheduleInfo =>
      'Votre calendrier de paie permet à l\'arbre budgétaire de traiter les cycles de paie et d\'alimenter automatiquement vos objectifs liés.';

  @override
  String get plantMyBudgetTree => 'Planter mon arbre budgétaire';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get signOutQuestion => 'Se déconnecter ?';

  @override
  String get signOutBody =>
      'Votre forêt est enregistrée dans le nuage. Reconnectez-vous à tout moment pour la récupérer.';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get eraseAllTitle => 'Effacer toutes les données ?';

  @override
  String get eraseAllBody =>
      'Cela supprimera définitivement chaque arbre budgétaire et chaque objectif. Vos préférences seront conservées. Cette action est irréversible.';

  @override
  String get eraseEverything => 'Tout effacer';

  @override
  String get absolutelySure => 'Êtes-vous absolument sûr ?';

  @override
  String get lastChanceBody =>
      'Dernière chance. Après cela, chaque arbre et objectif enregistré sera perdu.';

  @override
  String get keepMyData => 'Conserver mes données';

  @override
  String get yesErase => 'Oui, effacer';

  @override
  String get appearanceUpper => 'APPARENCE';

  @override
  String get textSize => 'Taille du texte';

  @override
  String get scaleCompact => 'Compact';

  @override
  String get scaleDefault => 'Par défaut';

  @override
  String get scaleLarge => 'Grand';

  @override
  String get themePalette => 'Palette de thème';

  @override
  String get paletteForest => 'Forêt';

  @override
  String get paletteMidnight => 'Minuit';

  @override
  String get paletteTwilight => 'Crépuscule';

  @override
  String get motion => 'Animations';

  @override
  String get fullAnimations => 'Animations complètes';

  @override
  String get fullAnimationsSub =>
      'Désactivez pour des écrans plus rapides et moins animés';

  @override
  String get soundHaptics => 'Son et vibrations';

  @override
  String get feedbackCues => 'Retours sonores';

  @override
  String get feedbackCuesSub =>
      'Sons et tapotements quand vous plantez, fixez des objectifs et épargnez';

  @override
  String get notificationsUpper => 'NOTIFICATIONS';

  @override
  String get guideUpper => 'GUIDE';

  @override
  String get replayTutorial => 'Revoir le tutoriel';

  @override
  String get replayTutorialSub =>
      'Laissez Acorn vous guider à nouveau dans l\'application.';

  @override
  String get accountUpper => 'COMPTE';

  @override
  String get signedInAs => 'Connecté en tant que';

  @override
  String get signOutSub => 'Vos données restent en sécurité dans le nuage.';

  @override
  String get unknown => 'Inconnu';

  @override
  String get dataUpper => 'DONNÉES';

  @override
  String get eraseAllData => 'Effacer toutes les données';

  @override
  String get eraseAllDataSub =>
      'Supprime chaque arbre budgétaire et objectif enregistré.';

  @override
  String get aboutUpper => 'À PROPOS';

  @override
  String get builtWith => 'Conçu avec';

  @override
  String get budgetWarnings => 'Alertes de budget';

  @override
  String get budgetWarningsSub =>
      'Quand un budget approche ou dépasse votre revenu';

  @override
  String get streakReminders => 'Rappels de série';

  @override
  String get streakRemindersSub =>
      'Un rappel quotidien pour garder votre série d\'épargne active';

  @override
  String get remindMeAt => 'Me rappeler à';

  @override
  String get weeklySummary => 'Résumé hebdomadaire';

  @override
  String get weeklySummarySub => 'Un récapitulatif hebdomadaire de vos progrès';

  @override
  String get dayLabel => 'Jour';

  @override
  String get timeLabel => 'Heure';

  @override
  String get weekdayMon => 'Lundi';

  @override
  String get weekdayTue => 'Mardi';

  @override
  String get weekdayWed => 'Mercredi';

  @override
  String get weekdayThu => 'Jeudi';

  @override
  String get weekdayFri => 'Vendredi';

  @override
  String get weekdaySat => 'Samedi';

  @override
  String get weekdaySun => 'Dimanche';

  @override
  String get done => 'Terminé';

  @override
  String get saveBudgetTreeQuestion => 'Enregistrer l\'arbre budgétaire ?';

  @override
  String saveBudgetTreeBody(String name) {
    return 'Enregistrez « $name » dans votre forêt. Vous pouvez le consulter et le modifier à tout moment depuis la feuille Modifier.';
  }

  @override
  String get groupOptionalUpper => 'GROUPE (FACULTATIF)';

  @override
  String get autoLinkBranches =>
      'Lier automatiquement les branches aux objectifs';

  @override
  String get autoLinkBranchesDesc =>
      'Associe les noms de dépenses aux noms d\'objectifs existants. Les branches liées alimentent ces objectifs pendant les cycles de paie.';

  @override
  String autoLinkedSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count branches liées',
      one: '1 branche liée',
    );
    return '$_temp0 automatiquement aux objectifs correspondants.';
  }

  @override
  String get treePlantedSnack => 'Arbre planté dans votre forêt !';

  @override
  String get processPay => 'Traiter la paie';

  @override
  String get saveMyTree => 'Enregistrer mon arbre';

  @override
  String get updateTree => 'Mettre à jour l\'arbre';

  @override
  String get gardenersTips => 'Conseils du jardinier';

  @override
  String get gardenersTipsSub => 'Comment mieux répartir votre argent';

  @override
  String get tapALeaf => 'Touchez une feuille pour voir son budget';

  @override
  String payProcessed(int periods, String amount, int goals, String when) {
    return '$periods période(s) de paie traitée(s) · $amount → $goals objectif(s). Prochaine paie $when.';
  }

  @override
  String noPayPeriods(String when) {
    return 'Aucune période de paie écoulée pour l\'instant. Prochaine paie $when.';
  }

  @override
  String get linkBranchToGoals => 'Lier cette branche aux objectifs';

  @override
  String selectGoalsBranch(String name) {
    return 'Sélectionnez les objectifs que cette branche « $name » soutient.';
  }

  @override
  String get noGoalsPlanted => 'Aucun objectif planté pour l\'instant';

  @override
  String get createGoalComeBack =>
      'Créez un objectif dans le Bosquet, puis revenez le lier.';

  @override
  String percentOfIncome(String pct) {
    return '$pct % de votre revenu';
  }

  @override
  String get allocated => 'Alloué';

  @override
  String ofIncome(String amount) {
    return 'sur $amount de revenu';
  }

  @override
  String get linkedGoalsUpper => 'OBJECTIFS LIÉS';

  @override
  String get linkEllipsis => 'Lier…';

  @override
  String get notFundingGoals =>
      'Cette branche ne finance encore aucun objectif. Touchez « Lier… » pour la connecter à des arbres du Bosquet.';

  @override
  String get totalIncome => 'Revenu total';

  @override
  String overBudgetAmount(String amount) {
    return 'Dépassement : $amount';
  }

  @override
  String unallocatedAmount(String amount) {
    return 'Non alloué : $amount';
  }

  @override
  String get timeNow => 'maintenant';

  @override
  String timeToday(String time) {
    return 'aujourd\'hui $time';
  }

  @override
  String get timeTomorrow => 'demain';

  @override
  String timeInDays(int count) {
    return 'dans $count jours';
  }

  @override
  String nextPayLine(String when) {
    return 'prochaine paie $when';
  }

  @override
  String get todayShort => 'aujourd\'hui';

  @override
  String onDate(String date) {
    return 'le $date';
  }

  @override
  String get stageSeed => 'Graine';

  @override
  String get stageSprout => 'Pousse';

  @override
  String get stageYoungSapling => 'Jeune arbre';

  @override
  String get stageSapling => 'Arbre';

  @override
  String get stageGrowingTree => 'Arbre en croissance';

  @override
  String get stageMature => 'Adulte';

  @override
  String get tierSeedling => 'Jeune pousse';

  @override
  String get tierSapling => 'Arbre';

  @override
  String get tierYoungOak => 'Jeune chêne';

  @override
  String get tierMatureOak => 'Chêne adulte';

  @override
  String get tierToweringOak => 'Chêne imposant';

  @override
  String get tierAncientOak => 'Chêne ancien';

  @override
  String get badgesTitle => 'Badges';

  @override
  String badgesEarned(int earned, int total) {
    return '$earned sur $total obtenus';
  }

  @override
  String get badgeUnlocked => 'Badge débloqué !';

  @override
  String get niceExcl => 'Super !';

  @override
  String badgeMessage(String title, String desc) {
    return '$title. $desc';
  }

  @override
  String get achFirstSproutTitle => 'Première pousse';

  @override
  String get achFirstSproutDesc => 'Plantez votre premier arbre budgétaire.';

  @override
  String get achFirstSaplingTitle => 'Premier arbre';

  @override
  String get achFirstSaplingDesc => 'Créez votre premier objectif d\'épargne.';

  @override
  String get achFirstDropTitle => 'Première goutte';

  @override
  String get achFirstDropDesc => 'Faites votre premier dépôt vers un objectif.';

  @override
  String get achOrchardKeeperTitle => 'Gardien du verger';

  @override
  String get achOrchardKeeperDesc => 'Entretenez trois objectifs à la fois.';

  @override
  String get achGreenThumbTitle => 'Main verte';

  @override
  String get achGreenThumbDesc => 'Épargnez 1 000 \$ dans votre bosquet.';

  @override
  String get achConsistentTitle => 'Régulier';

  @override
  String get achConsistentDesc =>
      'Atteignez une série d\'épargne de 3 semaines.';

  @override
  String get achFirstHarvestTitle => 'Première récolte';

  @override
  String get achFirstHarvestDesc => 'Terminez un objectif d\'épargne.';

  @override
  String get achDevotedTitle => 'Dévoué';

  @override
  String get achDevotedDesc => 'Atteignez une série d\'épargne de 8 semaines.';

  @override
  String get achMightyOakTitle => 'Chêne puissant';

  @override
  String get achMightyOakDesc =>
      'Faites grandir un objectif jusqu\'au palier 5 ou plus.';

  @override
  String get achOldGrowthTitle => 'Forêt ancienne';

  @override
  String get achOldGrowthDesc => 'Épargnez 10 000 \$ dans votre bosquet.';

  @override
  String get sugAddIncomeTitle => 'Ajoutez d\'abord vos revenus';

  @override
  String get sugAddIncomeReason =>
      'Un arbre a besoin de racines. Ajoutez une source de revenu pour que nous puissions suggérer comment la répartir entre branches et objectifs.';

  @override
  String get sugOverAllocTitle => 'Les branches dépassent le tronc';

  @override
  String sugOverAllocReason(String amount) {
    return 'Vous avez attribué $amount de plus que vos revenus. Coupez une branche ou deux pour que l\'arbre puisse les soutenir.';
  }

  @override
  String get sugIdleTitle => 'Faites travailler l\'argent inactif';

  @override
  String sugIdleReason(String amount, int pct) {
    return '$amount ($pct %) de vos revenus ne sont pas encore attribués. Ajoutez une branche d\'épargne et liez-la à un objectif pour qu\'ils grandissent au lieu de partir à la dérive.';
  }

  @override
  String sugPruneTitle(String name) {
    return 'Tailler « $name »';
  }

  @override
  String get sugPruneReason =>
      'Cette branche ne reçoit aucun argent. Financez-la ou taillez-la pour garder votre arbre concentré.';

  @override
  String sugHeavyTitle(String name) {
    return '« $name » est une branche lourde';
  }

  @override
  String sugHeavyReason(int pct) {
    return 'Elle prend $pct % de vos revenus. Si vous pouvez la réduire, cet argent pourrait plutôt nourrir un objectif d\'épargne.';
  }

  @override
  String get sugFedTitle => 'Vos objectifs sont nourris';

  @override
  String sugFedReason(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count branches envoient',
      one: '1 branche envoie',
    );
    return '$_temp0 de l\'argent à un objectif à chaque cycle de paie. Continuez. C\'est ainsi que poussent les arbres.';
  }

  @override
  String get sugLinkTitle => 'Liez une branche à un objectif';

  @override
  String get sugLinkReason =>
      'Aucune de vos branches n\'alimente encore un objectif d\'épargne. En lier une signifie que chaque cycle de paie arrose automatiquement un arbre pour vous.';

  @override
  String get sugHealthyTitle => 'Arbre sain et équilibré';

  @override
  String get sugHealthyReason =>
      'Vos branches sont bien proportionnées et dans les limites de vos revenus. Rien à changer. Continuez simplement d\'arroser vos objectifs.';

  @override
  String get giconSavings => 'Épargne';

  @override
  String get giconTravel => 'Voyage';

  @override
  String get giconVehicle => 'Véhicule';

  @override
  String get giconHome => 'Maison';

  @override
  String get giconEducation => 'Études';

  @override
  String get giconWedding => 'Mariage';

  @override
  String get giconEmergency => 'Urgence';

  @override
  String get giconTech => 'Tech';

  @override
  String get giconGift => 'Cadeau';

  @override
  String get giconOther => 'Autre';

  @override
  String get expHousing => 'Logement';

  @override
  String get expFood => 'Nourriture';

  @override
  String get expTransport => 'Transport';

  @override
  String get expSavings => 'Épargne';

  @override
  String get expEntertainment => 'Loisirs';

  @override
  String get expSubscriptions => 'Abonnements';

  @override
  String get expHealthcare => 'Santé';

  @override
  String get expPersonal => 'Personnel';

  @override
  String get expOther => 'Autre';

  @override
  String get incSalary => 'Salaire';

  @override
  String get incWages => 'Paie';

  @override
  String get incPartTime => 'Emploi à temps partiel';

  @override
  String get incFreelance => 'Travail indépendant';

  @override
  String get incInvestments => 'Investissements';

  @override
  String get incDividends => 'Dividendes';

  @override
  String get incRental => 'Revenu locatif';

  @override
  String get incBusiness => 'Revenu d\'entreprise';

  @override
  String get incBenefits => 'Prestations sociales';

  @override
  String get incScholarship => 'Bourse';

  @override
  String get incPension => 'Pension';

  @override
  String get monJan => 'janv.';

  @override
  String get monFeb => 'févr.';

  @override
  String get monMar => 'mars';

  @override
  String get monApr => 'avr.';

  @override
  String get monMay => 'mai';

  @override
  String get monJun => 'juin';

  @override
  String get monJul => 'juil.';

  @override
  String get monAug => 'août';

  @override
  String get monSep => 'sept.';

  @override
  String get monOct => 'oct.';

  @override
  String get monNov => 'nov.';

  @override
  String get monDec => 'déc.';

  @override
  String budgetCardCounts(int expenses, int sources) {
    String _temp0 = intl.Intl.pluralLogic(
      expenses,
      locale: localeName,
      other: '$expenses dépenses',
      one: '1 dépense',
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
      'Bonjour ! Je suis Acorn, votre petit guide ici à Budget Tree !';

  @override
  String get tutIntro2 =>
      'Au lieu de simplement vous expliquer comment ça marche, nous le ferons ensemble. Vous essaierez chaque partie vous-même au fur et à mesure.';

  @override
  String get tutIntro3 =>
      'Prenez votre temps ; j\'attends à chaque étape. Prêt ? Premier arrêt, le coin Budget !';

  @override
  String get tutClosing1 =>
      'Et voilà toute la forêt ! Touchez le bouton d\'info sur n\'importe quel écran et je vous réexpliquerai cette partie.';

  @override
  String get tutClosing2 =>
      'Faisons maintenant pousser quelque chose de merveilleux ensemble. À bientôt là dehors !';

  @override
  String get tutCreate1 =>
      'Nous y voilà. Voici l\'écran Créer, où vous plantez un tout nouvel arbre budgétaire.';

  @override
  String get tutCreate2 =>
      'Vous ajouterez ce que vous gagnez, puis où ça va, et quelques détails personnels. Les étapes suivent la vigne en haut.';

  @override
  String get tutCreate3 =>
      'Définissez votre calendrier de paie et regardez votre budget se transformer en arbre !';

  @override
  String get tutForest1 =>
      'Voici Votre forêt, où chaque budget que vous avez planté pousse ensemble.';

  @override
  String get tutForest2 =>
      'Basculez entre une vue arbre feuillue et une grille soignée en haut, et filtrez par catégorie.';

  @override
  String get tutForest3 =>
      'Touchez un arbre pour l\'entretenir : examinez le détail, modifiez-le ou retirez-le.';

  @override
  String get tutGoals1 =>
      'Nous voici dans Le Bosquet, où vos objectifs d\'épargne poussent comme de petits arbres.';

  @override
  String get tutGoals2 =>
      'Fixez un montant cible, puis arrosez-le avec des dépôts au fil du temps.';

  @override
  String get tutGoals3 =>
      'Chaque contribution aide votre arbre à se rapprocher un peu plus de sa pleine floraison !';

  @override
  String get tutSettings1 =>
      'Dernier arrêt : Réglages, où vous personnalisez l\'application.';

  @override
  String get tutSettings2 =>
      'Changez le thème entre Forêt, Minuit et Crépuscule, ajustez la taille du texte ou réduisez les animations.';

  @override
  String get tutSettings3 =>
      'Et vous pouvez rejouer toute cette visite d\'ici quand vous voulez.';

  @override
  String get tutOpenCreate => 'Ouvrir Créer →';

  @override
  String get tutOpenForest => 'Ouvrir la Forêt →';

  @override
  String get tutOpenGoals => 'Ouvrir le Bosquet →';

  @override
  String get tutOpenSettings => 'Ouvrir les Réglages →';

  @override
  String get tutTaskCreate1 =>
      'Plantons votre tout premier arbre budgétaire, ensemble !';

  @override
  String get tutTaskCreate2 =>
      'Je vais ouvrir l\'écran Créer et rester juste à côté de vous, guidant chaque phase : la Graine, les Branches et les Racines.';

  @override
  String get tutTaskCreate3 =>
      'Touchez ci-dessous et mettons les mains à la terre !';

  @override
  String get tutTaskForest1 =>
      'Promenons-nous maintenant dans Votre forêt, où poussent vos budgets.';

  @override
  String get tutTaskForest2 =>
      'Touchez votre arbre pour regarder à l\'intérieur, et essayez le bouton arbre et grille en haut.';

  @override
  String get tutTaskForest3 =>
      'Regardez bien autour de vous, puis touchez la flèche de retour pour me retrouver.';

  @override
  String get tutTaskGoals1 =>
      'C\'est l\'heure d\'un objectif d\'épargne ! Voici Le Bosquet.';

  @override
  String get tutTaskGoals2 =>
      'Touchez le + pour planter un arbre, donnez-lui un nom et une cible, puis enregistrez-le.';

  @override
  String get tutTaskGoals3 =>
      'Revenez ensuite vers moi avec la flèche. C\'est parti !';

  @override
  String get tutTaskSettings1 =>
      'Dernier arrêt. Personnalisons l\'application, dans les Réglages.';

  @override
  String get tutTaskSettings2 =>
      'Essayez de toucher un thème différent et regardez toute la forêt changer de couleur.';

  @override
  String get tutTaskSettings3 => 'Revenez quand l\'apparence vous plaît.';

  @override
  String get tutSuccessCreate1 =>
      'Regardez ça ! Votre tout premier arbre est planté ! 🌳';

  @override
  String get tutSuccessCreate2 =>
      'Merveilleusement fait. Ce budget vit maintenant dans votre forêt.';

  @override
  String get tutSuccessForest1 =>
      'Votre forêt prend forme. Chaque budget que vous créez plante un autre arbre ici.';

  @override
  String get tutSuccessGoals1 =>
      'Magnifique ! Votre premier arbre s\'élance vers le ciel ! 🌱';

  @override
  String get tutSuccessGoals2 =>
      'Nourrissez-le avec des dépôts et il grandira vers votre cible.';

  @override
  String get tutSuccessSettings1 =>
      'Très bien ! Vous pouvez tout peaufiner à tout moment.';

  @override
  String get tutRetryCreate1 =>
      'Hmm, je ne vois pas encore de nouvel arbre ! Voulez-vous réessayer ?';

  @override
  String get tutRetryCreate2 =>
      'Ajoutez un revenu et une dépense, puis plantez et enregistrez votre arbre. Ou passez cette étape pour l\'instant.';

  @override
  String get tutRetryGoals1 =>
      'Aucun arbre planté pour l\'instant. On réessaie ?';

  @override
  String get tutRetryGoals2 =>
      'Touchez le + et enregistrez un objectif, ou passez cette étape et revenez plus tard.';

  @override
  String get tutSkipCreate1 =>
      'Pas de souci ! Vous pouvez planter un budget à tout moment depuis la feuille Créer.';

  @override
  String get tutSkipGoals1 =>
      'C\'est bon ! Plantez un objectif quand vous êtes prêt depuis la feuille Objectifs.';

  @override
  String get tutStep0a =>
      '🌱 La phase de la Graine. Chaque arbre commence par ce qui le nourrit : vos revenus.';

  @override
  String get tutStep0b =>
      'Saisissez une source comme « Salaire », entrez le montant, et touchez le + pour l\'ajouter.';

  @override
  String get tutStep0c =>
      'Ajoutez chaque façon dont vous gagnez de l\'argent. Quand vous êtes prêt, touchez Suivant en bas.';

  @override
  String get tutStep1a =>
      '🌿 Les Branches. C\'est là que votre argent s\'étend : vos dépenses.';

  @override
  String get tutStep1b =>
      'Choisissez une catégorie, nommez-la, fixez un montant et ajoutez-la. Regardez ce qu\'il reste à répartir en haut.';

  @override
  String get tutStep1c =>
      'Ajoutez vos principaux frais, puis touchez Suivant pour fixer vos racines.';

  @override
  String get tutStep2a =>
      '🪵 Les Racines : les détails qui ancrent votre arbre.';

  @override
  String get tutStep2b =>
      'Nommez votre budget et choisissez votre calendrier de paie, c\'est la fréquence à laquelle l\'argent va vers vos objectifs.';

  @override
  String get tutStep2c =>
      'Tout est rempli ? Touchez « Planter mon arbre budgétaire » en bas pour le faire pousser !';

  @override
  String get tutSaveTree1 =>
      'Regardez-le grandir, c\'est votre budget sous forme d\'arbre vivant ! 🌳';

  @override
  String get tutSaveTree2 =>
      'Touchez « Enregistrer mon arbre » en bas à droite pour le planter durablement dans votre forêt.';

  @override
  String get tourLetsGo => 'C\'est parti !';

  @override
  String get tourSkipTour => 'Passer la visite';

  @override
  String get tourLetsGrow => 'Faisons pousser !';

  @override
  String get tourClose => 'Fermer';

  @override
  String get tourTryAgain => 'Réessayer';

  @override
  String get tourSkipStep => 'Passer l\'étape';

  @override
  String get tourNextStop => 'Étape suivante →';

  @override
  String get tourTapContinue => 'Touchez pour continuer';

  @override
  String get tourSkip => 'Passer';

  @override
  String get tourTapFinish => 'Touchez pour terminer';

  @override
  String notifOverBudgetTitle(String name) {
    return '🌳 « $name » dépasse le budget';
  }

  @override
  String notifOverBudgetMsg(String allocated, String income, String over) {
    return 'Vous avez attribué $allocated de vos $income de revenu, soit $over de trop. Coupez une branche pour rétablir l\'équilibre.';
  }

  @override
  String notifFillingTitle(String name) {
    return '⚠️ « $name » se remplit';
  }

  @override
  String notifFillingMsg(String allocated, String income, String remaining) {
    return 'Vous avez attribué $allocated sur $income. Il ne reste que $remaining à budgéter ce cycle.';
  }

  @override
  String notifStreakTitleActive(int count) {
    return '🔥 série de $count semaines';
  }

  @override
  String get notifStreakTitleNone => '🌱 Lancez une série';

  @override
  String notifStreakActive(int count) {
    return 'Vous êtes sur une série d\'épargne de $count semaines ! Ajoutez à un objectif aujourd\'hui pour la faire durer.';
  }

  @override
  String get notifStreakNone =>
      'Arrosez un objectif aujourd\'hui, même un peu, pour démarrer une série d\'épargne.';

  @override
  String get notifWeeklyTitle => '📊 Votre semaine dans le bosquet';

  @override
  String get notifWeeklyNone =>
      'Aucun dépôt cette semaine pour l\'instant. Un petit montant garde vos arbres en croissance, et votre série en vie.';

  @override
  String notifWeeklyChange(String amount, String arrow, int pct) {
    return 'Cette semaine vous avez épargné $amount ($arrow $pct % vs la semaine dernière). Continuez à faire grandir vos objectifs !';
  }

  @override
  String notifWeeklyPlain(String amount) {
    return 'Cette semaine vous avez épargné $amount. Continuez à faire grandir vos objectifs !';
  }

  @override
  String get gateErrorTitle => 'Impossible de terminer la configuration';

  @override
  String get gateErrorBody =>
      'Nous n\'avons pas pu joindre le serveur pour configurer votre compte. Vérifiez votre connexion et réessayez.';

  @override
  String get claimUsernameTitle => 'Choisissez un nom d\'utilisateur';

  @override
  String get claimUsernameBody =>
      'C\'est ainsi que vos amis vous trouvent et vous ajoutent.';

  @override
  String get usernameHint => 'nom d\'utilisateur';

  @override
  String get claimUsernameButton => 'Réserver le nom';

  @override
  String get usernameTakenShort => 'Ce nom d\'utilisateur est déjà pris.';

  @override
  String get signedOut => 'Déconnecté 🌱';

  @override
  String get expenseBreakdownUpper => 'RÉPARTITION DES DÉPENSES';

  @override
  String get categoryNameTripsHint => 'ex. Voyages';

  @override
  String get createButton => 'Créer';

  @override
  String get register => 'S\'inscrire';

  @override
  String get startButton => 'Commencer';

  @override
  String get swipeToWalk =>
      'Glissez pour vous promener · touchez un arbre pour les détails';

  @override
  String get tapForDetails => 'Touchez pour les détails';

  @override
  String get newCategoryTitle => 'Nouvelle catégorie';

  @override
  String get newCategoryBody =>
      'Nommez votre catégorie. Les arbres et objectifs de cette catégorie seront teintés avec la couleur choisie.';

  @override
  String get colourUpper => 'COULEUR';
}
