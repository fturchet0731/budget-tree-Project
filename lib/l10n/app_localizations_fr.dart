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
  String get addFriends => 'Ajouter des amis';

  @override
  String get activeNow => 'En ligne';

  @override
  String get likeGoal => 'Aimer cet objectif';

  @override
  String get unlikeGoal => 'Retirer votre mention J\'aime';

  @override
  String get messageAction => 'Message';

  @override
  String get chatEmpty => 'Dites bonjour pour lancer la conversation.';

  @override
  String get chatHint => 'Écrivez un message';

  @override
  String get chatSend => 'Envoyer';

  @override
  String get social => 'Social';

  @override
  String get profile => 'Profil';

  @override
  String get bio => 'Bio';

  @override
  String get bioHint => 'Parlez un peu de vous à vos amis';

  @override
  String get addABio => 'Ajoutez une bio';

  @override
  String get sharedGoals => 'Objectifs partagés';

  @override
  String get shareGoalsToShowOnProfile =>
      'Les objectifs que vous partagez apparaîtront ici pour vos amis.';

  @override
  String get settingsLanguageTitle => 'Langue';

  @override
  String get settingsLanguageSubtitle => 'Choisissez votre langue';

  @override
  String get settingsTimeZoneTitle => 'Fuseau horaire';

  @override
  String get settingsTimeZoneSubtitle => 'Quand vos rappels se déclenchent';

  @override
  String get searchTimeZones => 'Rechercher un fuseau horaire';

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
  String get passwordTooShort =>
      '8 caractères ou plus, avec une lettre et un chiffre';

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
  String get incomeAddAnother => 'Ajouter une autre source';

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
  String get themePalette => 'Thème';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

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
  String sugGoalBranchTitle(String name) {
    return 'Ajoutez une branche pour « $name »';
  }

  @override
  String get sugGoalBranchReason =>
      'Cet objectif n\'est nourri par aucune branche ici. Reliez en une et il sera arrosé à chaque cycle de paie.';

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
  String get tutStep1d =>
      'Cette jauge montre en permanence ce qu\'il reste à répartir. Si elle devient rouge, vous promettez plus que vous ne gagnez : réduisez une branche avant de continuer.';

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
  String get coachAcornTip => 'Le conseil d\'Acorn';

  @override
  String get acornName => 'Acorn';

  @override
  String get pulseAccept => 'Accepter';

  @override
  String get coachGotIt => 'Compris !';

  @override
  String get howThisWorks => 'Comment ça marche';

  @override
  String get tutIntroHelp =>
      'Encore une chose : vous voyez le petit point d\'interrogation en haut de l\'écran ? Touchez-le à tout moment et je vous réexpliquerai cette partie.';

  @override
  String get tutOverBudget1 =>
      'Attendez ! Vos branches demandent plus d\'argent que vos revenus n\'en apportent.';

  @override
  String tutOverBudget2(String amount) {
    return 'Vous dépassez le budget de $amount. Réduisez certaines dépenses pour rétablir l\'équilibre, puis nous pourrons continuer.';
  }

  @override
  String get overBudgetFixHint => 'Je corrige ça';

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

  @override
  String get homeSlogan =>
      'Faites pousser votre forêt, faites grandir votre épargne';

  @override
  String get newTreeInForest => 'Un nouvel arbre pousse dans votre forêt !';

  @override
  String get deleteCategoryTitle => 'Supprimer le groupe ?';

  @override
  String deleteCategoryBody(String name) {
    return 'Supprimer le groupe « $name » ? Les arbres et arbustes qui en font partie perdront simplement leur étiquette de couleur.';
  }

  @override
  String get longPressToDeleteGroup =>
      'Appuyez longuement sur un groupe pour le supprimer';

  @override
  String sharedByName(String name) {
    return 'Partagé par $name';
  }

  @override
  String get savingsAndGoals => 'Épargne et objectifs';

  @override
  String get stepPlanTitle => 'Plan intelligent';

  @override
  String get stepPlanSub => 'Laissez le coach répartir vos revenus';

  @override
  String get vinePlan => 'Plan';

  @override
  String leaveBlankForSuggested(String amount) {
    return 'Laissez vide et le coach utilisera $amount à chaque fois.';
  }

  @override
  String sameMonthlyAs(String amount) {
    return 'environ $amount par mois';
  }

  @override
  String get tourCancelTour => 'Annuler la visite';

  @override
  String get tourSkipSection => 'Passer cette section';

  @override
  String get stepFinishTitle => 'Touches finales';

  @override
  String get stepFinishSub =>
      'Nommez votre arbre et fixez son calendrier de paie';

  @override
  String get vineFinish => 'Finir';

  @override
  String get yourExpenses => 'Vos dépenses';

  @override
  String get describeYourBudget => 'Décrivez votre budget';

  @override
  String get describeYourBudgetHint =>
      'Dites au coach comment vous voulez gérer votre argent. Par exemple, épargner fort pour un voyage, garder de l\'argent pour les loisirs, ou couvrir d\'abord l\'essentiel.';

  @override
  String get budgetIdeaSaveHard => 'Épargner le plus possible';

  @override
  String get budgetIdeaBalanced => 'Mode de vie équilibré';

  @override
  String get budgetIdeaEssentials => 'Couvrir d\'abord l\'essentiel';

  @override
  String get budgetIdeaDebt => 'Rembourser vite mes dettes';

  @override
  String get amountOptionalLabel => 'Montant (facultatif)';

  @override
  String get amountOptionalHint =>
      'Vous ne savez pas combien ? Laissez vide et le coach décidera.';

  @override
  String get pickAPlan => 'Choisissez un plan';

  @override
  String get regeneratePlans => 'Régénérer les plans';

  @override
  String get setAmountsMyself => 'Définir les montants moi-même';

  @override
  String get setAmounts => 'Définir les montants';

  @override
  String get aiUnavailableManual =>
      'Le coach n\'est pas joignable pour le moment, définissez donc vos montants ici.';

  @override
  String get useTheseAmounts => 'Utiliser ces montants';

  @override
  String get useAiPlansInstead => 'Utiliser plutôt les plans IA';

  @override
  String get allocationsReady => 'Répartition prête';

  @override
  String get thinkingUp => 'Préparation des plans...';

  @override
  String get generatePlans => 'Générer des plans avec l\'IA';

  @override
  String get tutStepPlanA =>
      'Voici la partie amusante. Dites-moi à quoi vous voulez que votre budget ressemble.';

  @override
  String get tutStepPlanB =>
      'Je vais proposer quelques façons de répartir vos revenus selon ce que vous avez dit.';

  @override
  String get tutStepPlanC =>
      'Choisissez celle que vous préférez, ou ajustez les montants vous-même.';

  @override
  String get fundFromBranchTitle => 'Financer cet objectif ?';

  @override
  String get fundFromBranchBody =>
      'Reliez une branche du budget pour arroser cet objectif automatiquement à chaque paie.';

  @override
  String get notNow => 'Pas maintenant';

  @override
  String get targetDateLabel => 'Date cible';

  @override
  String get pickATargetDate => 'Choisir une date cible';

  @override
  String get planWithAi => 'Planifier avec l\'IA';

  @override
  String get calculateMonthly => 'Calculer le mensuel';

  @override
  String recommendedMonthly(String amount) {
    return 'Épargnez $amount par mois pour y arriver';
  }

  @override
  String planMonthsLine(String amount, int months) {
    return '$amount par mois termine en environ $months mois';
  }

  @override
  String get alternativeDates => 'AUTRES DATES';

  @override
  String get aiUnavailableSimple =>
      'Le coach n\'est pas joignable, voici donc le montant mensuel simple.';

  @override
  String get reflectionWeeklyTitle => 'Votre semaine dans la forêt';

  @override
  String get reflectionMonthlyTitle => 'Votre mois dans la forêt';

  @override
  String get notifReflectionTitle => 'Votre bilan est prêt';

  @override
  String get aiCoachUpper => 'COACH IA';

  @override
  String get aiCoach => 'Coach IA';

  @override
  String get aiCoachSub =>
      'Plans intelligents de budget et d\'objectifs, plus des bilans hebdomadaires';

  @override
  String get aiCoachNeedsOnline => 'Connectez-vous pour utiliser le coach IA.';

  @override
  String get goalStepName => 'Nom';

  @override
  String get goalStepAmount => 'Montant';

  @override
  String get aiPlanPromptTitle => 'Besoin d\'aide pour planifier ?';

  @override
  String get aiPlanPromptBody =>
      'Le coach peut suggérer combien épargner chaque mois et des dates adaptées à vos revenus. Ou faites-le vous-même.';

  @override
  String get setItUpMyself => 'Je vais le configurer moi-même';

  @override
  String get goalStepWhen => 'Échéance';

  @override
  String get timeframeNote =>
      'Quand voulez-vous atteindre cet objectif ? Nous adapterons un plan d\'arrosage en conséquence.';

  @override
  String get timeframeUncappedNote =>
      'Les objectifs sans limite n\'ont pas de date butoir. Choisissez une date pour viser une cible, ou passez à la suite.';

  @override
  String get wateringPlanTitle => 'Plan d\'arrosage';

  @override
  String get wateringPlanIntro =>
      'Choisissez à quelle fréquence et combien arroser cet objectif. Nous vous le rappellerons pour rester sur la bonne voie.';

  @override
  String get remindToWaterTitle => 'Me rappeler d\'arroser';

  @override
  String get remindToWaterSub =>
      'Recevez un rappel avant chaque arrosage, et un signal le jour même.';

  @override
  String planAboutMonths(int months) {
    return 'Environ $months mois pour l\'atteindre';
  }

  @override
  String get customWaterTitle => 'Personnaliser';

  @override
  String get amountPerWatering => 'Montant par arrosage';

  @override
  String get cadenceWeekly => 'Hebdo';

  @override
  String get cadenceBiweekly => '2 semaines';

  @override
  String get cadenceMonthly => 'Mensuel';

  @override
  String get cadenceEveryWeekly => 'chaque semaine';

  @override
  String get cadenceEveryBiweekly => 'toutes les 2 semaines';

  @override
  String get cadenceEveryMonthly => 'chaque mois';

  @override
  String get wateringReminders => 'Rappels d\'arrosage';

  @override
  String get wateringRemindersSub =>
      'Des rappels pour arroser vos objectifs à temps';

  @override
  String notifWaterDueTitle(String name) {
    return '💧 Il est temps d\'arroser $name';
  }

  @override
  String notifWaterDueMsg(String name, String amount) {
    return 'Votre pousse $name attend $amount. Arrosez-la pour rester sur la bonne voie.';
  }

  @override
  String notifWaterSoonTitle(String name) {
    return '🌱 Arrosage de $name bientôt';
  }

  @override
  String notifWaterSoonMsg(String name, String amount) {
    return 'Rappel : $name attend $amount dans 2 jours.';
  }

  @override
  String get stepSurveyTitle => 'Quelques questions rapides';

  @override
  String get stepSurveySub => 'Aidez le coach à dimensionner votre budget';

  @override
  String get vineSurvey => 'Sondage';

  @override
  String get surveyIntroTitle => 'Parlez-nous de vous';

  @override
  String get surveyIntroBody =>
      'Répondez à quelques questions et le coach estimera les montants des dépenses laissées vides. Chaque question est facultative.';

  @override
  String get budgetNoteTitle => 'Autre chose ? (facultatif)';

  @override
  String get budgetNoteHint =>
      'Par exemple : je veux épargner fort pour une maison, ou garder un peu d\'argent plaisir.';

  @override
  String get leftoverGoalTitle => 'Faites pousser un objectif avec votre reste';

  @override
  String leftoverGoalBody(String amount) {
    return 'Il vous reste $amount. Envoyez ce montant vers un objectif et il devient une branche qui le finance à chaque cycle de paie.';
  }

  @override
  String get growAGoalWithIt => 'Faire pousser un objectif';

  @override
  String get leftoverPickGoalTitle => 'Envoyer le reste vers';

  @override
  String get leftoverNewGoal => 'Créer un nouvel objectif';

  @override
  String get leftoverNewGoalTitle => 'Nommez votre objectif';

  @override
  String get surveyHousehold => 'Combien de personnes dans votre foyer ?';

  @override
  String get surveyHouseholdJustMe => 'Juste moi';

  @override
  String get surveyHouseholdTwo => 'Deux';

  @override
  String get surveyHouseholdThreeFour => '3 à 4';

  @override
  String get surveyHouseholdFivePlus => '5 ou plus';

  @override
  String get surveyDining => 'À quelle fréquence mangez-vous au restaurant ?';

  @override
  String get surveyDiningRarely => 'Rarement';

  @override
  String get surveyDiningSometimes => 'Parfois';

  @override
  String get surveyDiningOften => 'Souvent';

  @override
  String get surveyHousing => 'Quel est votre logement ?';

  @override
  String get surveyHousingRent => 'Je loue';

  @override
  String get surveyHousingFamily => 'En famille';

  @override
  String get surveyCommute => 'Comment vous déplacez-vous ?';

  @override
  String get surveyCommuteCar => 'Voiture';

  @override
  String get surveyCommuteTransit => 'Transports';

  @override
  String get surveyCommuteActive => 'Vélo ou marche';

  @override
  String get surveyCommuteRemote => 'Je travaille de chez moi';

  @override
  String get surveyPriority => 'Qu\'est-ce qui compte le plus maintenant ?';

  @override
  String get surveyPrioritySave => 'Épargner fort';

  @override
  String get surveyPriorityBalanced => 'Un équilibre';

  @override
  String get surveyPriorityEnjoy => 'Profiter maintenant';

  @override
  String get surveyDebt => 'Des remboursements de dettes ?';

  @override
  String get surveyDebtNone => 'Aucun';

  @override
  String get surveyDebtSome => 'Quelques-uns';

  @override
  String get surveyDebtLots => 'Beaucoup';

  @override
  String get surveyKids => 'Des enfants ou des personnes à charge chez vous ?';

  @override
  String get surveyKidsNone => 'Aucun';

  @override
  String get surveyKidsOne => 'Un';

  @override
  String get surveyKidsTwoThree => '2 à 3';

  @override
  String get surveyKidsFourPlus => '4 ou plus';

  @override
  String get surveyChildcare =>
      'Que vous coûtent leur garde ou leur scolarité ?';

  @override
  String get surveyChildcareDaycare => 'Garderie payante';

  @override
  String get surveyChildcareSchool => 'Frais de scolarité ou activités';

  @override
  String get surveyChildcareFamily => 'La famille aide';

  @override
  String get surveyChildcareNone => 'Rien de régulier';

  @override
  String get surveyHousingMortgage => 'Je suis propriétaire avec un prêt';

  @override
  String get surveyHousingOwned => 'Je suis propriétaire sans prêt';

  @override
  String get surveyRentShare => 'Partagez-vous le loyer avec quelqu\'un ?';

  @override
  String get surveyRentShareAlone => 'Je paie tout';

  @override
  String get surveyRentShareSplit => 'Nous le partageons';

  @override
  String get surveyHomeUpkeep =>
      'La taxe foncière et l\'entretien sont-ils compris ?';

  @override
  String get surveyHomeUpkeepIncluded => 'Compris dedans';

  @override
  String get surveyHomeUpkeepSeparate => 'Je les paie à part';

  @override
  String get surveyHomeUpkeepUnsure => 'Je ne sais pas';

  @override
  String get surveyCarCosts => 'Que vous coûte la voiture en ce moment ?';

  @override
  String get surveyCarCostsPaying => 'Je la rembourse encore';

  @override
  String get surveyCarCostsOwned => 'Payée, juste carburant et entretien';

  @override
  String get surveyCarCostsShared => 'Je la partage ou l\'emprunte';

  @override
  String get surveyGroceries => 'Comment faites-vous vos courses ?';

  @override
  String get surveyGroceriesBudget => 'Je cherche les bonnes affaires';

  @override
  String get surveyGroceriesMiddle => 'Ce qui est pratique';

  @override
  String get surveyGroceriesPremium => 'La qualité avant le prix';

  @override
  String get surveySubscriptions => 'Combien d\'abonnements payez-vous ?';

  @override
  String get surveySubscriptionsNone => 'Presque aucun';

  @override
  String get surveySubscriptionsFew => 'Quelques-uns';

  @override
  String get surveySubscriptionsMany => 'Pas mal';

  @override
  String get surveyPets => 'Des animaux ?';

  @override
  String get surveyPetsNone => 'Aucun';

  @override
  String get surveyPetsOne => 'Un';

  @override
  String get surveyPetsSeveral => 'Plusieurs';

  @override
  String get surveyPetCosts => 'Que vous coûtent-ils habituellement ?';

  @override
  String get surveyPetCostsBasic => 'Juste la nourriture et la litière';

  @override
  String get surveyPetCostsRegular =>
      'Nourriture et visites vétérinaires régulières';

  @override
  String get surveyPetCostsMedical => 'Traitement ou soins continus';

  @override
  String get surveyHealth => 'Des frais de santé réguliers ?';

  @override
  String get surveyHealthMinimal => 'Presque jamais';

  @override
  String get surveyHealthRegular => 'Consultations de routine';

  @override
  String get surveyHealthOngoing => 'Traitement ou ordonnances en cours';

  @override
  String get surveyStability => 'Votre revenu est-il stable ?';

  @override
  String get surveyStabilitySteady => 'Toujours le même';

  @override
  String get surveyStabilityVaries => 'Il bouge un peu';

  @override
  String get surveyStabilityUnpredictable => 'Difficile à prévoir';

  @override
  String get surveyIncomeFloor => 'De combien varie-t-il ?';

  @override
  String get surveyIncomeFloorClose => 'Une petite baisse au pire';

  @override
  String get surveyIncomeFloorSome =>
      'Certains mois sont nettement plus maigres';

  @override
  String get surveyIncomeFloorWide =>
      'Un mois creux peut valoir la moitié d\'un bon mois';

  @override
  String get surveyDebtType => 'De quel type de dette s\'agit-il ?';

  @override
  String get surveyDebtTypeCards => 'Cartes de crédit';

  @override
  String get surveyDebtTypeStudent => 'Prêts étudiants';

  @override
  String get surveyDebtTypeVehicle => 'Un prêt auto';

  @override
  String get surveyDebtTypeMixed => 'Un peu de tout';

  @override
  String get surveyEmergency => 'Quelle réserve avez-vous de côté ?';

  @override
  String get surveyEmergencyNone => 'Rien pour l\'instant';

  @override
  String get surveyEmergencyUnderOne => 'Moins d\'un mois';

  @override
  String get surveyEmergencyOneToThree => '1 à 3 mois';

  @override
  String get surveyEmergencyThreePlus => 'Plus de 3 mois';

  @override
  String get surveyBudgetFor => 'Que voulez-vous surtout que ce budget fasse ?';

  @override
  String get surveyBudgetForCushion => 'Constituer une réserve de sécurité';

  @override
  String get surveyBudgetForDebt => 'Rembourser mes dettes plus vite';

  @override
  String get surveyBudgetForBigGoal => 'Épargner pour un projet précis';

  @override
  String get surveyBudgetForControl => 'Simplement voir où tout passe';

  @override
  String get tutStepSurveyA =>
      'Maintenant quelques questions rapides sur votre vie.';

  @override
  String get tutStepSurveyB =>
      'Vos réponses m\'aident à estimer les dépenses dont vous n\'étiez pas sûr.';

  @override
  String get tutStepSurveyC =>
      'Répondez à votre guise, puis nous construirons vos plans.';

  @override
  String get verifyTitle => 'Vérifiez votre boîte mail';

  @override
  String verifyBody(String email) {
    return 'Nous avons envoyé un code à 6 chiffres à $email. Saisissez-le ci-dessous pour confirmer votre compte.';
  }

  @override
  String get verifyCodeLabel => 'Code de vérification';

  @override
  String get enterCode => 'Saisissez le code à 6 chiffres';

  @override
  String get verifyButton => 'Vérifier l\'e-mail';

  @override
  String get resendCode => 'Renvoyer le code';

  @override
  String get codeResent => 'Nous vous avons envoyé un nouveau code.';

  @override
  String get verifyBadCode =>
      'Ce code est incorrect ou expiré. Réessayez ou renvoyez-le.';

  @override
  String get loginExploreFirst => 'Essayez d\'abord, sans compte';

  @override
  String get pulseWaterTitle => 'C\'est l\'heure d\'arroser';

  @override
  String pulseWaterBody(String name, String amount) {
    return 'Donnez $amount à $name pour qu\'il continue de pousser.';
  }

  @override
  String pulseWaterOverdueBody(String name) {
    return '$name a manqué son dernier arrosage. Un petit dépôt le rattrape.';
  }

  @override
  String get pulseStreakAtRiskTitle => 'Série en danger';

  @override
  String pulseStreakAtRiskBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'série de $count semaines',
      one: 'série de 1 semaine',
    );
    return 'Arrosez un objectif avant la fin de la semaine pour garder votre $_temp0.';
  }

  @override
  String get pulseStreakTitle => 'Série d\'épargne';

  @override
  String pulseStreakBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semaines d\'affilée.',
      one: '1 semaine d\'affilée.',
    );
    return '$_temp0 Continuez comme ça !';
  }

  @override
  String get pulsePlantTitle => 'Commencez ici';

  @override
  String get pulsePlantBody =>
      'Plantez votre premier arbre et regardez votre budget grandir.';

  @override
  String get pulseCheckInTitle => 'Le moment de faire le point';

  @override
  String pulseCheckInBody(String name) {
    return '$name a atteint son jour de paie. Dites à Acorn comment cela s\'est passé.';
  }

  @override
  String pulseCheckInOverdueBody(String name) {
    return '$name attend toujours votre réponse. Répondez avant la fermeture.';
  }

  @override
  String pulseCheckInManyBody(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count réponses sont en attente.',
      one: '1 réponse est en attente.',
    );
    return '$_temp0 Commencez par $name.';
  }

  @override
  String checkInPaydayTitle(String name) {
    return 'Jour de paie de $name';
  }

  @override
  String checkInWateringTitle(String name) {
    return 'Arrosage de $name';
  }

  @override
  String get checkInQuestion => 'Avez-vous suivi votre plan ?';

  @override
  String get checkInWateringQuestion => 'L\'avez-vous arrosé comme prévu ?';

  @override
  String get checkInOnTrack => 'Dans les clous';

  @override
  String get checkInSlipped => 'Un peu dépassé';

  @override
  String get checkInOffPlan => 'Hors plan';

  @override
  String get checkInAddActuals => 'Ajouter ce que vous avez vraiment dépensé';

  @override
  String get checkInActualsHelp =>
      'Facultatif. C\'est ainsi qu\'Acorn repère les branches qui débordent.';

  @override
  String checkInPlanned(String amount) {
    return 'Prévu $amount';
  }

  @override
  String get checkInActualHint => 'Réel';

  @override
  String get checkInConfirm => 'Enregistrer ma réponse';

  @override
  String get checkInSaved => 'Enregistré. Votre arbre l\'a remarqué.';

  @override
  String get hubTitle => 'Le coin d\'Acorn';

  @override
  String get hubOpenPrompt => 'Voyez comment vous vous en sortez';

  @override
  String get hubTreeFresh => 'Un nouveau départ';

  @override
  String get hubTreeFreshSub =>
      'Votre arbre grandit à mesure que vous faites le point.';

  @override
  String hubScoreSub(int score) {
    return 'Santé $score sur 100';
  }

  @override
  String hubStreakSub(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count points d\'affilée',
      one: '1 point d\'affilée',
    );
    return '$_temp0';
  }

  @override
  String hubMissedSub(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count manqués récemment',
      one: '1 manqué récemment',
    );
    return '$_temp0';
  }

  @override
  String hubPrestigeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours au sommet',
      one: '1 jour au sommet',
    );
    return '$_temp0';
  }

  @override
  String hubDeltaUp(int points) {
    return '$points de plus récemment';
  }

  @override
  String hubDeltaDown(int points) {
    return '$points de moins récemment';
  }

  @override
  String hubAnswerOne(String name) {
    return 'Dites à Acorn comment $name a évolué';
  }

  @override
  String hubAnswerMany(int count) {
    return '$count réponses en attente';
  }

  @override
  String get hubStatStreak => 'D\'affilée';

  @override
  String get hubStatAnswered => 'Répondu';

  @override
  String get hubStatBest => 'Meilleure série';

  @override
  String hubPendingTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count choses auxquelles répondre',
      one: 'Une chose à laquelle répondre',
    );
    return '$_temp0';
  }

  @override
  String get hubPendingSub =>
      'Chaque réponse nourrit votre arbre. En sauter une le fait reculer.';

  @override
  String get hubReflectionTitle => 'Votre bilan';

  @override
  String get hubReflectionReady =>
      'Acorn a tout observé. Laissez-le vous guider.';

  @override
  String get hubReflectionEmpty => 'Rien à analyser pour l\'instant.';

  @override
  String get hubReflectionEmptySub =>
      'Répondez à un point ou deux et Acorn aura de quoi vous montrer.';

  @override
  String get hubReflectionPlay => 'Laisser Acorn présenter';

  @override
  String get hubConsistencyTitle => 'Votre parcours';

  @override
  String get hubTrendTitle => 'La santé dans le temps';

  @override
  String get hubOverspendTitle => 'Le plan face à la réalité';

  @override
  String get hubOverspendEmpty =>
      'Rien à comparer pour l\'instant. Quand vous faites le point, indiquez ce que vous avez vraiment dépensé sur une branche ou deux et cela se remplira.';

  @override
  String get hubTalkTitle => 'En parler';

  @override
  String get hubTalkSub =>
      'Demandez à Acorn quoi changer, il répondra avec vos propres chiffres sous les yeux.';

  @override
  String get hubTalkAction => 'Discuter avec Acorn';

  @override
  String get back => 'Retour';

  @override
  String get hubStoryDone => 'Terminé';

  @override
  String get hubStoryIntroTitle => 'Voici comment vous grandissez';

  @override
  String get hubStoryIntroFallback =>
      'Regardons comment s\'est passée cette période.';

  @override
  String hubStoryConsistencyLine(int answered, int total) {
    return 'Vous avez répondu $answered fois sur $total. Chaque réponse est un jour où votre arbre a poussé au lieu de s\'éclaircir.';
  }

  @override
  String get hubStoryStrengthsTitle => 'Ce qui a bien marché';

  @override
  String get hubStoryWeaknessesTitle => 'Là où ça a glissé';

  @override
  String get hubStoryOverspendFallback =>
      'Voici où le plan et les dépenses se sont séparés.';

  @override
  String get hubStorySuggestionsTitle => 'À essayer maintenant';

  @override
  String get hubStorySuggestionsLine =>
      'Choisissez une seule chose. Un changement qui tient vaut mieux que trois qui échouent.';

  @override
  String get hubStoryNoAdviceLine =>
      'Je n\'ai pas encore assez d\'éléments. Posez-moi une question et voyons cela ensemble.';

  @override
  String get hubAskAboutThis => 'Parlez-m\'en davantage';

  @override
  String get hubChatGreeting => 'Qu\'est-ce qui vous préoccupe ?';

  @override
  String get hubChatGreetingSub =>
      'Je vois vos budgets, vos objectifs et comment vos points se sont passés.';

  @override
  String get hubChatPrompt1 => 'Où part vraiment mon argent ?';

  @override
  String get hubChatPrompt2 => 'Comment relancer ma série ?';

  @override
  String get hubChatPrompt3 => 'Mon budget est-il réaliste ?';

  @override
  String get hubChatHint => 'Posez une question à Acorn';

  @override
  String get hubChatThinking => 'Acorn réfléchit';

  @override
  String get hubChatFailed =>
      'Acorn n\'a pas pu répondre. Réessayez dans un instant.';

  @override
  String get hubChatClear => 'Effacer cette conversation';

  @override
  String get treeHealthBarren => 'Dénudé';

  @override
  String get treeHealthSparse => 'Clairsemé';

  @override
  String get treeHealthWilting => 'Qui se fane';

  @override
  String get treeHealthHolding => 'Tient bon';

  @override
  String get treeHealthLeafing => 'Se garnit';

  @override
  String get treeHealthFull => 'Fourni';

  @override
  String get treeHealthFlourishing => 'Florissant';

  @override
  String get treeHealthRadiant => 'Éclatant';

  @override
  String get treeHealthBlossoming => 'En fleurs';

  @override
  String get treeHealthFruiting => 'En fruits';

  @override
  String get treeHealthAncient => 'Ancestral';

  @override
  String get treeHealthSilver => 'Argent';

  @override
  String get treeHealthGilded => 'Doré';

  @override
  String get treeHealthDiamond => 'Diamant';

  @override
  String get treeHealthAmethyst => 'Améthyste';

  @override
  String get treeHealthRuby => 'Rubis';

  @override
  String get hubHowItWorks => 'Comment fonctionne le Hub d\'Acorn';

  @override
  String get hubSeeAllTrees => 'Voir tous les arbres';

  @override
  String statusTreesUnlocked(int count, int total) {
    return '$count sur $total debloques';
  }

  @override
  String get statusTreesAcornHint =>
      'Chaque point fait avancer votre arbre. Manquez en quelques uns et il recule, alors gardez la serie vivante.';

  @override
  String get statusTreesTitle => 'Arbres de statut';

  @override
  String get statusTreesIntro =>
      'Votre arbre montre votre régularité. Restez régulier pour le faire grandir; relâchez et il recule.';

  @override
  String get statusTreesScoreHeader => 'Grandit avec la régularité';

  @override
  String get statusTreesScoreSub =>
      'Votre score va de 0 à 100 à chaque point. Ces huit niveaux le suivent.';

  @override
  String get statusTreesPrestigeHeader => 'Prestige, gagné avec le temps';

  @override
  String get statusTreesPrestigeSub =>
      'Gardez un arbre éclatant à 90 ou plus et ceux ci se débloquent selon la durée. Une fois gagnés, ils restent.';

  @override
  String get statusTreeYouAreHere => 'Vous êtes ici';

  @override
  String statusTreeScoreBand(int from, int to) {
    return 'Score $from à $to';
  }

  @override
  String get tutHub1 =>
      'Bienvenue dans le Hub d\'Acorn. C\'est ici que je suis vos progrès.';

  @override
  String get tutHub2 =>
      'L\'arbre en haut est votre arbre de statut. Il grandit quand vous faites le point et tenez le plan, et il recule quand vous manquez.';

  @override
  String get tutHub3 =>
      'Votre score va de 0 à 100. Chaque stade de l\'arbre est une tranche de ce score, du plus dénudé au plus éclatant.';

  @override
  String get tutHub4 =>
      'Gardez un arbre éclatant dans le temps et vous gagnez des niveaux de prestige. Ils sont acquis pour de bon, même si vous baissez ensuite.';

  @override
  String get tutHub5 =>
      'Sous l\'arbre je montre votre série, vos points et où votre plan a rencontré la réalité. Touchez Voir tous les arbres pour voir chaque niveau à atteindre.';

  @override
  String get tutHub6 =>
      'Continuez à faire le point et votre arbre prospérera. Je serai juste là.';

  @override
  String get checkInMissed => 'Manqué';

  @override
  String hubOverBy(String amount) {
    return '$amount de trop';
  }

  @override
  String get hubWithinPlan => 'Dans le plan';

  @override
  String get payDayReminders => 'Points de jour de paie';

  @override
  String get payDayRemindersSub =>
      'Demander comment le cycle s\'est passé à chaque paie';

  @override
  String get notifChannelCheckInName => 'Rappels de jour de paie';

  @override
  String get notifChannelCheckInDesc =>
      'Un rappel à chaque jour de paie pour dire comment le cycle s\'est passé';

  @override
  String get notifCheckInTitle => 'Jour de paie';

  @override
  String notifCheckInBody(String name) {
    return '$name a atteint son jour de paie. Ouvrez Budget Tree et dites à Acorn comment cela s\'est passé.';
  }

  @override
  String surveyProgress(int current, int total) {
    return 'Question $current sur $total';
  }

  @override
  String get surveyDoneTitle => 'C\'est tout';

  @override
  String get surveyDoneBody =>
      'Touchez une réponse pour la modifier, ou ajoutez une note pour le coach ci-dessous.';

  @override
  String get surveySkippedLabel => 'Passée';

  @override
  String get guestUpgradeTitle => 'Votre premier arbre est planté !';

  @override
  String get guestUpgradeBody =>
      'Créez un compte gratuit et votre forêt sera sauvegardée dans le cloud, en sécurité même si vous changez de téléphone. Tout ce que vous avez créé vous suit.';

  @override
  String get guestUpgradeLater => 'Plus tard';

  @override
  String get payFreqWeekly => 'Chaque semaine';

  @override
  String get payFreqBiWeekly => 'Toutes les 2 semaines';

  @override
  String get payFreqSemiMonthly => 'Deux fois par mois';

  @override
  String get payFreqMonthly => 'Chaque mois';

  @override
  String get budgetCycleTitle => 'À quel rythme faites-vous votre budget ?';

  @override
  String get budgetCycleBody =>
      'Tout ce qui suit compte par cycle. Un revenu qui arrive à un autre rythme est converti pour vous.';

  @override
  String get incomeArrives => 'À quelle fréquence arrive-t-il ?';

  @override
  String approxEachCycle(String amount) {
    return '≈ $amount par cycle';
  }

  @override
  String get expenseCharged => 'À quelle fréquence est-elle facturée ?';

  @override
  String setAsideEachCycle(String amount) {
    return 'Mettez de côté environ $amount par cycle pour que l\'argent soit prêt quand cette facture arrive.';
  }

  @override
  String get scrollToContinue =>
      'Faites défiler jusqu\'à la fin pour continuer';

  @override
  String totalIncomeCycle(String cycle) {
    return 'Revenu total ($cycle)';
  }

  @override
  String get incomeDoneAdding => 'C\'est tout mon revenu';

  @override
  String get expensesDoneAdding => 'Ce sont toutes mes dépenses';

  @override
  String get expenseSummaryTitle => 'Votre situation';

  @override
  String get dataErased => 'Toutes les données ont été effacées.';

  @override
  String get defaultBudgetName => 'Mon budget';

  @override
  String get notifChannelBudgetName => 'Alertes de budget';

  @override
  String get notifChannelBudgetDesc =>
      'Alertes quand un budget approche ou dépasse votre revenu';

  @override
  String get notifChannelStreakName => 'Rappels de série';

  @override
  String get notifChannelStreakDesc =>
      'Rappel quotidien pour garder votre série d\'épargne en vie';

  @override
  String get notifChannelWeeklyName => 'Bilan hebdomadaire';

  @override
  String get notifChannelWeeklyDesc =>
      'Un récapitulatif hebdomadaire de la croissance de votre forêt';

  @override
  String get notifChannelWateringName => 'Arrosage des objectifs';

  @override
  String get notifChannelWateringDesc =>
      'Rappels pour arroser vos objectifs d\'épargne à temps';

  @override
  String get rhythmCustom => 'Personnalisé';

  @override
  String get rhythmEvery => 'Tous les';

  @override
  String rhythmEveryDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tous les $count jours',
      one: 'Chaque jour',
    );
    return '$_temp0';
  }

  @override
  String rhythmEveryWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Toutes les $count semaines',
      one: 'Chaque semaine',
    );
    return '$_temp0';
  }

  @override
  String rhythmEveryMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tous les $count mois',
      one: 'Chaque mois',
    );
    return '$_temp0';
  }

  @override
  String get rhythmUnitDays => 'jours';

  @override
  String get rhythmUnitWeeks => 'semaines';

  @override
  String get rhythmUnitMonths => 'mois';

  @override
  String get rhythmCustomHint => 'Combien ?';

  @override
  String get willingRangeTitle => 'Combien êtes-vous prêt à verser ?';

  @override
  String get willingRangeSub =>
      'Le minimum et le maximum que vous mettriez à chaque fois. Les plans sont construits entre les deux.';

  @override
  String get willingRangeMin => 'Minimum';

  @override
  String get willingRangeMax => 'Maximum';

  @override
  String get paceEasy => 'Rythme tranquille';

  @override
  String get paceSteady => 'Rythme régulier';

  @override
  String get paceFast => 'Rythme rapide';

  @override
  String get haveADateInMind => 'Avez-vous une date en tête ?';

  @override
  String get haveADateYes => 'Oui, pour une date';

  @override
  String get haveADateYesDetail =>
      'Nous calculons le montant à verser pour y arriver.';

  @override
  String get haveADateNo => 'Non, j\'épargne simplement';

  @override
  String get haveADateNoDetail =>
      'Nous calculons quand vous y arriverez à votre rythme.';

  @override
  String get noDateExplainer =>
      'Choisissez un rythme et un montant à l\'étape suivante et le coach vous dira quand l\'objectif sera atteint.';

  @override
  String reachesGoalBy(String date) {
    return 'atteint le $date';
  }

  @override
  String get willingToPut => 'Combien êtes-vous prêt à verser à chaque fois ?';

  @override
  String get willingToPutHint =>
      'Laissez vide et le coach proposera plusieurs rythmes.';

  @override
  String get viewSuggestions => 'Voir des suggestions';

  @override
  String get hideSuggestions => 'Masquer les suggestions';

  @override
  String get addThisSource => 'Ajouter cette source';

  @override
  String get addThisExpense => 'Ajouter cette branche';

  @override
  String get savedIncomeSources => 'Sources de revenu enregistrées';

  @override
  String get savedIncomeSourcesHint =>
      'Touchez-en une pour la réutiliser d\'un arbre précédent.';

  @override
  String get expenseBelongsTo => 'À quelle branche appartient cette dépense ?';

  @override
  String get savedExpenseBranches => 'Branches enregistrées';

  @override
  String get savedExpenseBranchesHint =>
      'Touchez-en une pour la réutiliser d\'un arbre précédent.';

  @override
  String get chooseBranchToContinue =>
      'Choisissez une branche pour ajouter cette dépense.';

  @override
  String hubLevel(int n) {
    return 'NIV.$n';
  }

  @override
  String hubStreakWeeks(int n) {
    return 'SERIE DE $n SEM';
  }

  @override
  String get profileStatTrees => 'ARBRES';

  @override
  String get profileStatStreak => 'SERIE';

  @override
  String get profileStatSaved => 'EPARGNE';

  @override
  String get profileSharedSaplings => 'POUSSES PARTAGEES';
}
