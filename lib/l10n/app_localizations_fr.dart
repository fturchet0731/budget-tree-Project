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
}
