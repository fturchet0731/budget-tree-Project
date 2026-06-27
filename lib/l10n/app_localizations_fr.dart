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
}
