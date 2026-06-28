import 'dart:ui';

import '../services/app_settings.dart';
import 'app_localizations.dart';

/// Resolve an [AppLocalizations] instance **without a BuildContext**, for code
/// that runs outside the widget tree (notifications fired from the background).
///
/// Uses the user's chosen app language, falling back to the device language,
/// and finally to English if neither is one we ship translations for.
AppLocalizations appLocalizations() {
  final chosen = AppSettings.instance.locale?.languageCode ??
      PlatformDispatcher.instance.locale.languageCode;
  final code =
      AppSettings.supportedLanguageCodes.contains(chosen) ? chosen : 'en';
  return lookupAppLocalizations(Locale(code));
}
