import 'dart:ui' show Locale;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppPalette { light, dark }

enum AppTextScale { compact, normal, large }

class AppSettings extends ChangeNotifier {
  // Light/dark theme choice. The old key 'settings_palette_v1' indexed the
  // retired forestDark/midnight/twilight palettes and is deliberately ignored:
  // the redesign gives everyone the new light look by default, and dark is a
  // fresh opt-in rather than a migration of the old dark palettes.
  static const _kThemeMode = 'settings_theme_mode_v1';
  static const _kScale = 'settings_text_scale_v1';
  static const _kMotion = 'settings_motion_v1';
  static const _kSound = 'settings_sound_v1';
  static const _kTutorialSeen = 'settings_tutorial_seen_v1';
  static const _kNotifBudget = 'settings_notif_budget_v1';
  static const _kNotifStreak = 'settings_notif_streak_v1';
  static const _kStreakHour = 'settings_streak_hour_v1';
  static const _kStreakMinute = 'settings_streak_minute_v1';
  static const _kNotifWeekly = 'settings_notif_weekly_v1';
  static const _kWeeklyWeekday = 'settings_weekly_weekday_v1';
  static const _kWeeklyHour = 'settings_weekly_hour_v1';
  static const _kNotifWatering = 'settings_notif_watering_v1';
  static const _kWaterHour = 'settings_water_hour_v1';
  static const _kLocale = 'settings_locale_v1';
  static const _kTimeZone = 'settings_timezone_v1';
  static const _kAiCoach = 'settings_ai_coach_v1';
  static const _kNotifPermissionAsked = 'settings_notif_perm_asked_v1';

  /// Languages the app ships translations for. `null` locale = follow device.
  static const supportedLanguageCodes = ['en', 'fr', 'es'];

  AppPalette _palette = AppPalette.light;
  AppTextScale _scale = AppTextScale.normal;
  Locale? _locale;
  String? _timeZone; // null = follow the device time zone
  bool _motionFull = true;
  bool _soundEnabled = true;
  bool _tutorialSeen = false;

  // Notification preferences. We launch with exactly three opt-out types to
  // avoid overload: budget warnings, a daily streak reminder, and a weekly
  // summary — each with a strategically-timed default the user can change.
  bool _notifBudgetWarnings = true;
  bool _notifStreakReminders = true;
  int _streakHour = 9; // morning nudge to log/save
  int _streakMinute = 0;
  bool _notifWeeklySummary = true;
  int _weeklyWeekday = DateTime.sunday; // 1=Mon … 7=Sun
  int _weeklyHour = 18; // Sunday evening recap
  // Per-goal watering reminders ("water due in 2 days" / "water due today").
  bool _notifGoalWatering = true;
  int _waterHour = 9; // morning nudge to water due goals

  // Master switch for the Claude-powered coach (smart budget/goal plans and
  // weekly reflections). On by default; the features still only run when
  // Supabase is configured and the user is signed in.
  bool _aiCoachEnabled = true;

  bool _notifPermissionAsked = false;

  AppPalette get palette => _palette;
  bool get isDark => _palette == AppPalette.dark;
  AppTextScale get textScale => _scale;
  bool get motionFull => _motionFull;

  /// The user's chosen app language, or null to follow the device setting.
  Locale? get locale => _locale;

  /// IANA zone name the app schedules reminders in (e.g. `Europe/Paris`), or
  /// null to follow whatever the device reports. Overriding matters when the
  /// device zone is wrong or unavailable: reminders are wall-clock times, so a
  /// mis-detected zone fires them hours out.
  String? get timeZone => _timeZone;

  /// The two-letter code of the active choice, or 'system' when following the
  /// device. Used by the Settings language picker.
  String get languageSelection => _locale?.languageCode ?? 'system';

  /// Whether tactile/audible feedback (taps, chimes) plays on actions.
  bool get soundEnabled => _soundEnabled;

  bool get notifBudgetWarnings => _notifBudgetWarnings;
  bool get notifStreakReminders => _notifStreakReminders;
  int get streakHour => _streakHour;
  int get streakMinute => _streakMinute;
  bool get notifWeeklySummary => _notifWeeklySummary;

  /// Day the weekly summary fires, 1=Mon … 7=Sun (matches [DateTime.weekday]).
  int get weeklyWeekday => _weeklyWeekday;
  int get weeklyHour => _weeklyHour;

  /// Whether per-goal watering reminders fire, and the hour of day they do.
  bool get notifGoalWatering => _notifGoalWatering;
  int get waterHour => _waterHour;

  /// Whether the AI coach (smart plans + reflections) is allowed to run.
  bool get aiCoachEnabled => _aiCoachEnabled;

  /// True when at least one notification type is on (used to decide whether to
  /// bother requesting OS permission).
  bool get anyNotificationsEnabled =>
      _notifBudgetWarnings ||
      _notifStreakReminders ||
      _notifWeeklySummary ||
      _notifGoalWatering;

  /// True once the user has taken a notification-related action (touched the
  /// notification settings, or asked to be reminded to water a goal). The OS
  /// permission dialog is held back until then, so the very first launch never
  /// opens with a permission request the user has no context for.
  bool get notifPermissionAsked => _notifPermissionAsked;

  /// Record that the user opted into notifications somewhere; from now on the
  /// scheduler may surface the OS permission prompt.
  Future<void> markNotifPermissionAsked() async {
    if (_notifPermissionAsked) return;
    _notifPermissionAsked = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifPermissionAsked, true);
  }

  /// Whether the first-run acorn walkthrough has already played.
  bool get tutorialSeen => _tutorialSeen;

  /// MediaQuery textScaler scale value for the chosen size.
  double get textScaleFactor {
    switch (_scale) {
      case AppTextScale.compact:
        return 0.88;
      case AppTextScale.normal:
        return 1.0;
      case AppTextScale.large:
        return 1.18;
    }
  }

  /// Animation duration multiplier — 0 for reduced motion, 1 for full.
  double get motionMultiplier => _motionFull ? 1.0 : 0.0;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final pi = prefs.getInt(_kThemeMode) ?? 0;
    _palette = AppPalette.values[pi.clamp(0, AppPalette.values.length - 1)];
    final si = prefs.getInt(_kScale) ?? 1;
    _scale = AppTextScale.values[si.clamp(0, AppTextScale.values.length - 1)];
    _motionFull = prefs.getBool(_kMotion) ?? true;
    _soundEnabled = prefs.getBool(_kSound) ?? true;
    _tutorialSeen = prefs.getBool(_kTutorialSeen) ?? false;
    _notifBudgetWarnings = prefs.getBool(_kNotifBudget) ?? true;
    _notifStreakReminders = prefs.getBool(_kNotifStreak) ?? true;
    _streakHour = prefs.getInt(_kStreakHour) ?? 9;
    _streakMinute = prefs.getInt(_kStreakMinute) ?? 0;
    _notifWeeklySummary = prefs.getBool(_kNotifWeekly) ?? true;
    _weeklyWeekday = prefs.getInt(_kWeeklyWeekday) ?? DateTime.sunday;
    _weeklyHour = prefs.getInt(_kWeeklyHour) ?? 18;
    _notifGoalWatering = prefs.getBool(_kNotifWatering) ?? true;
    _waterHour = prefs.getInt(_kWaterHour) ?? 9;
    _aiCoachEnabled = prefs.getBool(_kAiCoach) ?? true;
    _notifPermissionAsked = prefs.getBool(_kNotifPermissionAsked) ?? false;
    _timeZone = prefs.getString(_kTimeZone);
    final lc = prefs.getString(_kLocale);
    _locale = (lc != null && supportedLanguageCodes.contains(lc))
        ? Locale(lc)
        : null;
  }

  /// Set the app language. Pass null to follow the device language. Persists
  /// as the language code (or clears the key for "system").
  Future<void> setLocale(Locale? locale) async {
    if (_locale?.languageCode == locale?.languageCode) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_kLocale);
    } else {
      await prefs.setString(_kLocale, locale.languageCode);
    }
  }

  /// Set the scheduling time zone. Pass null to follow the device. Callers
  /// should re-run `NotificationScheduler.rescheduleAll()` afterwards so the
  /// pending reminders move with it.
  Future<void> setTimeZone(String? name) async {
    if (_timeZone == name) return;
    _timeZone = name;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (name == null) {
      await prefs.remove(_kTimeZone);
    } else {
      await prefs.setString(_kTimeZone, name);
    }
  }

  Future<void> setNotifBudgetWarnings(bool v) async {
    if (_notifBudgetWarnings == v) return;
    _notifBudgetWarnings = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifBudget, v);
  }

  Future<void> setNotifStreakReminders(bool v) async {
    if (_notifStreakReminders == v) return;
    _notifStreakReminders = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifStreak, v);
  }

  Future<void> setStreakTime(int hour, int minute) async {
    if (_streakHour == hour && _streakMinute == minute) return;
    _streakHour = hour;
    _streakMinute = minute;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kStreakHour, hour);
    await prefs.setInt(_kStreakMinute, minute);
  }

  Future<void> setNotifWeeklySummary(bool v) async {
    if (_notifWeeklySummary == v) return;
    _notifWeeklySummary = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifWeekly, v);
  }

  Future<void> setWeeklySchedule(int weekday, int hour) async {
    if (_weeklyWeekday == weekday && _weeklyHour == hour) return;
    _weeklyWeekday = weekday;
    _weeklyHour = hour;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kWeeklyWeekday, weekday);
    await prefs.setInt(_kWeeklyHour, hour);
  }

  Future<void> setNotifGoalWatering(bool v) async {
    if (_notifGoalWatering == v) return;
    _notifGoalWatering = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifWatering, v);
  }

  Future<void> setWaterHour(int hour) async {
    if (_waterHour == hour) return;
    _waterHour = hour;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kWaterHour, hour);
  }

  Future<void> setAiCoachEnabled(bool v) async {
    if (_aiCoachEnabled == v) return;
    _aiCoachEnabled = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAiCoach, v);
  }

  Future<void> setSoundEnabled(bool v) async {
    if (_soundEnabled == v) return;
    _soundEnabled = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSound, v);
  }

  Future<void> setTutorialSeen(bool v) async {
    if (_tutorialSeen == v) return;
    _tutorialSeen = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kTutorialSeen, v);
  }

  Future<void> setPalette(AppPalette p) async {
    if (_palette == p) return;
    _palette = p;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kThemeMode, p.index);
  }

  Future<void> setTextScale(AppTextScale s) async {
    if (_scale == s) return;
    _scale = s;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kScale, s.index);
  }

  Future<void> setMotionFull(bool v) async {
    if (_motionFull == v) return;
    _motionFull = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kMotion, v);
  }

  static final AppSettings instance = AppSettings();
}
