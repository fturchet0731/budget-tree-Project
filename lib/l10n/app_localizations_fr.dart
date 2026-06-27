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
      'Comment vos amis vous trouvent — 3 à 20 lettres, chiffres ou _';

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
      'Salut, je suis Acorn ! 🌰 Bienvenue dans Budget Tree. Choisissez un nom d\'utilisateur pour terminer la configuration — c\'est ainsi que vos amis vous trouvent, mais vous pouvez faire grandir votre forêt avec ou sans eux.';

  @override
  String get onboardingAcornBusy => 'Je plante votre compte… une seconde ! 🌱';

  @override
  String get onboardingAcornError =>
      'Hmm, ça n\'a pas marché — essayons un autre nom !';

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
      'Aucun ami pour l\'instant — ajoutez quelqu\'un par son nom d\'utilisateur.';

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
}
