import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'app_settings.dart';

import '../l10n/app_localizations_resolver.dart';

/// Thin wrapper around `flutter_local_notifications`. Every method is wrapped
/// so a failure (unsupported platform, denied permission, web limitations)
/// degrades to a no-op instead of crashing the app. Higher layers
/// ([NotificationScheduler]) decide *what* to schedule; this only knows *how*.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _ready = false;
  static bool get isReady => _ready;

  /// Per-feature Android channels so users can tune them in system settings.
  static const _budgetChannel = 'budget_warnings';
  static const _streakChannel = 'streak_reminders';
  static const _weeklyChannel = 'weekly_summary';
  static const _wateringChannel = 'goal_watering';

  /// Stable notification ids — reusing an id replaces the prior schedule.
  static const int idStreak = 1001;
  static const int idWeekly = 1002;
  static const int idReflection = 1003;
  static const int budgetIdBase = 2000; // + hash of budget id
  static const int waterIdBase = 3000; // + hash of goal id (due today)
  static const int waterSoonIdBase = 4000; // + hash of goal id (due in 2 days)

  static Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      await applyTimeZone();

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const linux = LinuxInitializationSettings(defaultActionName: 'Open');
      const settings = InitializationSettings(
        android: android,
        iOS: darwin,
        macOS: darwin,
        linux: linux,
      );
      await _plugin.initialize(settings: settings);
      _ready = true;
    } catch (e) {
      debugPrint('NotificationService.init failed: $e');
      _ready = false;
    }
  }

  /// Point the scheduler at the right zone: the user's override from Settings
  /// if they set one, otherwise whatever the device reports.
  ///
  /// Reminders are wall-clock times ("water at 9am"), so the zone decides when
  /// they actually fire. UTC is the last resort rather than the fallback it
  /// used to be, since silently scheduling in UTC moves every reminder by the
  /// user's whole offset. Call again after changing the setting, then reschedule.
  static Future<void> applyTimeZone() async {
    final chosen = AppSettings.instance.timeZone;
    if (chosen != null) {
      try {
        tz.setLocalLocation(tz.getLocation(chosen));
        return;
      } catch (e) {
        // A stored name the database doesn't know: fall through to the device.
        debugPrint('NotificationService: unknown time zone "$chosen": $e');
      }
    }
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      debugPrint('NotificationService: device time zone unavailable: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  /// Every zone the bundled database knows about, sorted. Backs the Settings
  /// picker, so the user can correct a device that reports the wrong one.
  static List<String> availableTimeZones() {
    final names = tz.timeZoneDatabase.locations.keys.toList()..sort();
    return names;
  }

  /// Ask the user for OS permission (Android 13+, iOS, macOS). Safe to call
  /// repeatedly; the OS only prompts once.
  static Future<void> requestPermissions() async {
    if (!_ready) return;
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      await _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (e) {
      debugPrint('NotificationService.requestPermissions failed: $e');
    }
  }

  /// Localized name + description for a channel. Android shows these in the
  /// system notification settings, so they follow the app language like every
  /// other piece of copy. Resolved through [appLocalizations] because this runs
  /// with no BuildContext.
  static (String, String) _channelCopy(String channelId) {
    final l = appLocalizations();
    switch (channelId) {
      case _streakChannel:
        return (l.notifChannelStreakName, l.notifChannelStreakDesc);
      case _weeklyChannel:
        return (l.notifChannelWeeklyName, l.notifChannelWeeklyDesc);
      case _wateringChannel:
        return (l.notifChannelWateringName, l.notifChannelWateringDesc);
      case _budgetChannel:
      default:
        return (l.notifChannelBudgetName, l.notifChannelBudgetDesc);
    }
  }

  static NotificationDetails _details(String channelId) {
    final (channelName, channelDesc) = _channelCopy(channelId);
    final android = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.high,
      priority: Priority.high,
    );
    const darwin = DarwinNotificationDetails();
    return NotificationDetails(android: android, iOS: darwin, macOS: darwin);
  }

  /// Fire an immediate notification (used for event-driven budget warnings).
  static Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _details(_budgetChannel),
      );
    } catch (e) {
      debugPrint('NotificationService.showNow failed: $e');
    }
  }

  /// Fire an immediate notification on the weekly-summary channel (used for the
  /// freshly generated AI reflection).
  static Future<void> showReflectionNow({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _details(_weeklyChannel),
      );
    } catch (e) {
      debugPrint('NotificationService.showReflectionNow failed: $e');
    }
  }

  /// Schedule a one-shot watering reminder at the exact moment [when]. No
  /// `matchDateTimeComponents`, so it fires once; the [NotificationScheduler]
  /// re-seeds the next occurrence on boot/resume/after deposits. A [when] in the
  /// past is ignored.
  static Future<void> scheduleGoalWateringOnce({
    required int id,
    required DateTime when,
    required String title,
    required String body,
  }) async {
    if (!_ready) return;
    final scheduled = tz.TZDateTime.from(when, tz.local);
    if (!scheduled.isAfter(tz.TZDateTime.now(tz.local))) return;
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduled,
        notificationDetails: _details(_wateringChannel),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('NotificationService.scheduleGoalWatering($id) failed: $e');
    }
  }

  /// Schedule a notification that repeats every day at [hour]:[minute].
  static Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await _scheduleRepeating(
      id: id,
      scheduledDate: _nextDailyInstance(hour, minute),
      match: DateTimeComponents.time,
      title: title,
      body: body,
      channelId: _streakChannel,
    );
  }

  /// Schedule a notification that repeats weekly on [weekday] (1=Mon … 7=Sun)
  /// at [hour]:00.
  static Future<void> scheduleWeekly({
    required int id,
    required int weekday,
    required int hour,
    required String title,
    required String body,
  }) async {
    await _scheduleRepeating(
      id: id,
      scheduledDate: _nextWeeklyInstance(weekday, hour),
      match: DateTimeComponents.dayOfWeekAndTime,
      title: title,
      body: body,
      channelId: _weeklyChannel,
    );
  }

  static Future<void> _scheduleRepeating({
    required int id,
    required tz.TZDateTime scheduledDate,
    required DateTimeComponents match,
    required String title,
    required String body,
    required String channelId,
  }) async {
    if (!_ready) return;
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: _details(channelId),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: match,
      );
    } catch (e) {
      debugPrint('NotificationService.schedule($id) failed: $e');
    }
  }

  static Future<void> cancel(int id) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint('NotificationService.cancel failed: $e');
    }
  }

  static tz.TZDateTime _nextDailyInstance(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    return next;
  }

  static tz.TZDateTime _nextWeeklyInstance(int weekday, int hour) {
    var next = _nextDailyInstance(hour, 0);
    while (next.weekday != weekday) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }
}
