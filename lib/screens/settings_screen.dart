import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_shadows.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../services/app_settings.dart';
import '../services/auth_service.dart';
import '../services/notification_scheduler.dart';
import '../services/notification_service.dart';
import '../services/supabase_config.dart';
import '../services/sync_engine.dart';
import '../tutorial/tutorial_content.dart';
import '../tutorial/tutorial_tour.dart';
import '../widgets/app_scrollbar.dart';
import '../widgets/info_button.dart';
import '../widgets/ui/segmented_choice.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final settings = AppSettings.instance;

  @override
  void initState() {
    super.initState();
    settings.addListener(_onChange);
  }

  @override
  void dispose() {
    settings.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Future<void> _signOut() async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.signOutQuestion),
        content: Text(l.signOutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.signOut),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await AuthService.instance.signOut();
    // AuthGate listens to AuthService and will swap back to the login screen.
  }

  /// Apply a new scheduling zone, then move every pending reminder onto it.
  /// Without the reschedule the change wouldn't take effect until the next
  /// boot, since the reminders already sitting with the OS keep their old
  /// absolute firing times.
  Future<void> _setTimeZone(String? name) async {
    await AppSettings.instance.setTimeZone(name);
    await NotificationService.applyTimeZone();
    await NotificationScheduler.rescheduleAll();
  }

  Future<void> _confirmEraseAllData() async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppTokens.current.danger,
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(l.eraseAllTitle)),
          ],
        ),
        content: Text(l.eraseAllBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTokens.current.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.eraseEverything),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;

    // Double confirm
    final reallyOk = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.absolutelySure),
        content: Text(l.lastChanceBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.keepMyData),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTokens.current.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.yesErase),
          ),
        ],
      ),
    );
    if (reallyOk != true) return;

    // Wipe the signed-in user's rows remotely, then drop every local data
    // cache (budgets, goals, categories, achievements). App preferences are
    // intentionally left intact.
    await SyncEngine.deleteAllRemote();
    await SyncEngine.clearLocalCaches();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).dataErased),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
          child: AppScrollbar(
            builder: (controller) => CustomScrollView(
              controller: controller,
              slivers: [
                SliverAppBar(
                  backgroundColor: AppTokens.current.canvas,
                  elevation: 0,
                  pinned: true,
                  leading: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: AppColors.stoneBeigeColor,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    l.settingsTitle,
                    style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.w600,
                      color: AppColors.stoneBeigeColor,
                      fontSize: 22,
                    ),
                  ),
                  actions: const [
                    Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: SectionInfoButton(
                        section: TutorialSection.settings,
                      ),
                    ),
                  ],
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _SectionHeader(
                        icon: Icons.brush_outlined,
                        label: l.appearanceUpper,
                      ),
                      _SettingsCard(
                        children: [
                          _TileLabel(text: l.textSize),
                          const SizedBox(height: 10),
                          SegmentedChoice<AppTextScale>(
                            current: settings.textScale,
                            options: [
                              (AppTextScale.compact, l.scaleCompact),
                              (AppTextScale.normal, l.scaleDefault),
                              (AppTextScale.large, l.scaleLarge),
                            ],
                            onChanged: settings.setTextScale,
                          ),
                          const SizedBox(height: 18),
                          _TileLabel(text: l.themePalette),
                          const SizedBox(height: 10),
                          SegmentedChoice<AppPalette>(
                            current: settings.palette,
                            options: [
                              (AppPalette.light, l.themeLight),
                              (AppPalette.dark, l.themeDark),
                            ],
                            onChanged: settings.setPalette,
                          ),
                          const SizedBox(height: 18),
                          _TileLabel(text: l.motion),
                          const SizedBox(height: 6),
                          PixelSwitchTile(
                            title: l.fullAnimations,
                            subtitle: l.fullAnimationsSub,
                            value: settings.motionFull,
                            onChanged: settings.setMotionFull,
                          ),
                          const SizedBox(height: 12),
                          _TileLabel(text: l.soundHaptics),
                          const SizedBox(height: 6),
                          PixelSwitchTile(
                            title: l.feedbackCues,
                            subtitle: l.feedbackCuesSub,
                            value: settings.soundEnabled,
                            onChanged: settings.setSoundEnabled,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _SectionHeader(
                        icon: Icons.language,
                        label: l.settingsLanguageTitle.toUpperCase(),
                      ),
                      _SettingsCard(
                        children: [
                          _TileLabel(text: l.settingsLanguageSubtitle),
                          const SizedBox(height: 8),
                          _LanguagePicker(
                            current: settings.languageSelection,
                            systemLabel: l.systemDefault,
                            onChanged: settings.setLocale,
                          ),
                          const SizedBox(height: 16),
                          _TileLabel(text: l.settingsTimeZoneSubtitle),
                          const SizedBox(height: 8),
                          _TimeZoneTile(
                            current: settings.timeZone,
                            onChanged: _setTimeZone,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _SectionHeader(
                        icon: Icons.auto_awesome,
                        label: l.aiCoachUpper,
                      ),
                      _SettingsCard(
                        children: [
                          PixelSwitchTile(
                            title: l.aiCoach,
                            subtitle: l.aiCoachSub,
                            value: settings.aiCoachEnabled,
                            onChanged: settings.setAiCoachEnabled,
                          ),
                          if (settings.aiCoachEnabled &&
                              !(SupabaseConfig.isConfigured &&
                                  AuthService.instance.isSignedIn))
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                l.aiCoachNeedsOnline,
                                style: GoogleFonts.nunito(
                                  color: AppColors.warningAmber,
                                  fontSize: 11,
                                  height: 1.4,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _SectionHeader(
                        icon: Icons.notifications_outlined,
                        label: l.notificationsUpper,
                      ),
                      const _NotificationsCard(),
                      const SizedBox(height: 22),
                      _SectionHeader(
                        icon: Icons.menu_book_outlined,
                        label: l.guideUpper,
                      ),
                      _SettingsCard(
                        children: [
                          _ActionTile(
                            icon: Icons.school_outlined,
                            iconColor: AppTokens.current.accentStrong,
                            title: l.replayTutorial,
                            subtitle: l.replayTutorialSub,
                            onTap: () => GuidedTour.start(context),
                          ),
                        ],
                      ),
                      if (AuthService.instance.isSignedIn) ...[
                        const SizedBox(height: 22),
                        _SectionHeader(
                          icon: Icons.person_outline,
                          label: l.accountUpper,
                        ),
                        _SettingsCard(
                          children: [
                            _InfoRow(
                              label: l.signedInAs,
                              value:
                                  AuthService.instance.currentUser?.email ??
                                  l.unknown,
                            ),
                            const SizedBox(height: 6),
                            _ActionTile(
                              icon: Icons.logout,
                              iconColor: AppColors.warningAmber,
                              title: l.signOut,
                              subtitle: l.signOutSub,
                              onTap: _signOut,
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 22),
                      _SectionHeader(
                        icon: Icons.storage_outlined,
                        label: l.dataUpper,
                      ),
                      _SettingsCard(
                        children: [
                          _ActionTile(
                            icon: Icons.delete_forever_outlined,
                            iconColor: AppColors.dangerRed,
                            title: l.eraseAllData,
                            subtitle: l.eraseAllDataSub,
                            onTap: _confirmEraseAllData,
                            danger: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _SectionHeader(
                        icon: Icons.info_outline,
                        label: l.aboutUpper,
                      ),
                      _SettingsCard(
                        children: [
                          _InfoRow(label: 'Budget Tree', value: 'v1.0.0'),
                          _InfoRow(label: l.builtWith, value: 'Flutter / Dart'),
                        ],
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}

// ──────────────────────────────────────────────
// Section header
// ──────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColors.mossGreen.withValues(alpha: 0.75),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.nunito(
              color: AppColors.mossGreen.withValues(alpha: 0.75),
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppTokens.current.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTokens.current.cardBorder),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _TileLabel extends StatelessWidget {
  final String text;
  const _TileLabel({required this.text});
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.nunito(
        color: AppColors.stoneBeigeColor,
        fontWeight: FontWeight.bold,
        fontSize: 13.5,
      ),
    );
  }
}

/// Vertical language selector: System default + each shipped language shown in
/// its own native name. Tapping a row calls [onChanged] (null = follow device).
class _LanguagePicker extends StatelessWidget {
  final String current; // 'system' | 'en' | 'fr' | 'es'
  final String systemLabel;
  final void Function(Locale?) onChanged;
  const _LanguagePicker({
    required this.current,
    required this.systemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final options = <(String, String, Locale?)>[
      ('system', systemLabel, null),
      ('en', 'English', const Locale('en')),
      ('fr', 'Français', const Locale('fr')),
      ('es', 'Español', const Locale('es')),
    ];
    return Column(
      children: options.map((opt) {
        final (code, label, locale) = opt;
        final selected = code == current;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => onChanged(locale),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: selected
                    ? AppTokens.current.accentSoft
                    : AppTokens.current.canvasSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected
                      ? AppTokens.current.accentStrong
                      : AppTokens.current.cardBorder,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.nunito(
                        color: selected
                            ? AppTokens.current.accentStrong
                            : AppTokens.current.textPrimary,
                        fontSize: 14,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(
                      Icons.check_circle,
                      color: AppTokens.current.accentStrong,
                      size: 18,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;
  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.nunito(
                      color: danger
                          ? AppColors.dangerRed
                          : AppColors.stoneBeigeColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.nunito(
                      color: AppColors.mossGreen,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.mossGreen.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(color: AppColors.mossGreen, fontSize: 13),
          ),
          Text(
            value,
            style: GoogleFonts.nunito(
              color: AppColors.stoneBeigeColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Notifications: three opt-out types with customizable timing.
// ──────────────────────────────────────────────

class _NotificationsCard extends StatelessWidget {
  const _NotificationsCard();

  static List<String> _weekdayNames(AppLocalizations l) => [
    l.weekdayMon,
    l.weekdayTue,
    l.weekdayWed,
    l.weekdayThu,
    l.weekdayFri,
    l.weekdaySat,
    l.weekdaySun,
  ];

  Future<void> _apply(Future<void> Function() change) async {
    await change();
    // Touching any notification setting is the user opting in — from here on
    // the scheduler may show the OS permission dialog (it prompts only once).
    await AppSettings.instance.markNotifPermissionAsked();
    await NotificationScheduler.rescheduleAll();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppSettings.instance;
    final l = AppLocalizations.of(context);
    final weekdayNames = _weekdayNames(l);
    return _SettingsCard(
      children: [
        _NotifSwitch(
          title: l.budgetWarnings,
          subtitle: l.budgetWarningsSub,
          value: s.notifBudgetWarnings,
          onChanged: (v) => _apply(() => s.setNotifBudgetWarnings(v)),
        ),
        const SizedBox(height: 6),
        _NotifSwitch(
          title: l.streakReminders,
          subtitle: l.streakRemindersSub,
          value: s.notifStreakReminders,
          onChanged: (v) => _apply(() => s.setNotifStreakReminders(v)),
        ),
        if (s.notifStreakReminders)
          _TapRow(
            label: l.remindMeAt,
            value: TimeOfDay(
              hour: s.streakHour,
              minute: s.streakMinute,
            ).format(context),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: s.streakHour,
                  minute: s.streakMinute,
                ),
              );
              if (picked != null) {
                await _apply(() => s.setStreakTime(picked.hour, picked.minute));
              }
            },
          ),
        const SizedBox(height: 6),
        _NotifSwitch(
          title: l.weeklySummary,
          subtitle: l.weeklySummarySub,
          value: s.notifWeeklySummary,
          onChanged: (v) => _apply(() => s.setNotifWeeklySummary(v)),
        ),
        if (s.notifWeeklySummary) ...[
          _TapRow(
            label: l.dayLabel,
            value: weekdayNames[(s.weeklyWeekday - 1).clamp(0, 6)],
            onTap: () async {
              final picked = await showModalBottomSheet<int>(
                context: context,
                builder: (ctx) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(7, (i) {
                      final weekday = i + 1;
                      return ListTile(
                        title: Text(
                          weekdayNames[i],
                          style: GoogleFonts.nunito(
                            color: AppColors.stoneBeigeColor,
                          ),
                        ),
                        trailing: s.weeklyWeekday == weekday
                            ? Icon(
                                Icons.check,
                                color: AppTokens.current.accentStrong,
                                size: 18,
                              )
                            : null,
                        onTap: () => Navigator.pop(ctx, weekday),
                      );
                    }),
                  ),
                ),
              );
              if (picked != null) {
                await _apply(() => s.setWeeklySchedule(picked, s.weeklyHour));
              }
            },
          ),
          _TapRow(
            label: l.timeLabel,
            value: TimeOfDay(hour: s.weeklyHour, minute: 0).format(context),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: s.weeklyHour, minute: 0),
              );
              if (picked != null) {
                await _apply(
                  () => s.setWeeklySchedule(s.weeklyWeekday, picked.hour),
                );
              }
            },
          ),
        ],
        const SizedBox(height: 6),
        _NotifSwitch(
          title: l.wateringReminders,
          subtitle: l.wateringRemindersSub,
          value: s.notifGoalWatering,
          onChanged: (v) => _apply(() => s.setNotifGoalWatering(v)),
        ),
        if (s.notifGoalWatering)
          _TapRow(
            label: l.remindMeAt,
            value: TimeOfDay(hour: s.waterHour, minute: 0).format(context),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: s.waterHour, minute: 0),
              );
              if (picked != null) {
                await _apply(() => s.setWaterHour(picked.hour));
              }
            },
          ),
        const SizedBox(height: 6),
        _NotifSwitch(
          title: l.payDayReminders,
          subtitle: l.payDayRemindersSub,
          value: s.notifPayCheckIn,
          onChanged: (v) => _apply(() => s.setNotifPayCheckIn(v)),
        ),
        if (s.notifPayCheckIn)
          _TapRow(
            label: l.remindMeAt,
            value: TimeOfDay(hour: s.checkInHour, minute: 0).format(context),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: s.checkInHour, minute: 0),
              );
              if (picked != null) {
                await _apply(() => s.setCheckInHour(picked.hour));
              }
            },
          ),
      ],
    );
  }
}

class _NotifSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _NotifSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PixelSwitchTile(
      title: title,
      subtitle: subtitle,
      value: value,
      onChanged: onChanged,
    );
  }
}

class _TapRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _TapRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.nunito(
                color: AppColors.mossGreen,
                fontSize: 12.5,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTokens.current.accentSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                value,
                style: GoogleFonts.nunito(
                  color: AppColors.stoneBeigeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              color: AppColors.mossGreen,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the active scheduling zone and opens a searchable list of every zone
/// the timezone database knows about.
///
/// Reminders are wall-clock times, so a device reporting the wrong zone fires
/// them hours out; this is the escape hatch. "System default" keeps following
/// the device, which is right for nearly everyone.
class _TimeZoneTile extends StatelessWidget {
  const _TimeZoneTile({required this.current, required this.onChanged});

  final String? current;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = AppTokens.current;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final picked = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _TimeZoneSheet(current: current),
        );
        // The sheet pops the sentinel for "follow the device".
        if (picked == null) return;
        onChanged(picked == _TimeZoneSheet.systemSentinel ? null : picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: t.canvasSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.cardBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.public, size: 18, color: t.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                current ?? l.systemDefault,
                style: GoogleFonts.nunito(
                  color: t.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: t.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _TimeZoneSheet extends StatefulWidget {
  const _TimeZoneSheet({required this.current});

  final String? current;

  /// Popped in place of a zone name to mean "follow the device".
  static const systemSentinel = '__system__';

  @override
  State<_TimeZoneSheet> createState() => _TimeZoneSheetState();
}

class _TimeZoneSheetState extends State<_TimeZoneSheet> {
  final _searchCtrl = TextEditingController();
  late final List<String> _all = NotificationService.availableTimeZones();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<String> get _filtered {
    if (_query.isEmpty) return _all;
    // Match on any part of the path so "paris", "europe" and "eur/par" all work.
    final q = _query.toLowerCase().replaceAll(' ', '_');
    return _all.where((z) => z.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = AppTokens.current;
    final zones = _filtered;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 14,
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: t.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l.settingsTimeZoneTitle,
              style: GoogleFonts.fredoka(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: t.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                isDense: true,
                hintText: l.searchTimeZones,
                prefixIcon: const Icon(Icons.search, size: 18),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                controller: controller,
                // One extra leading row for the "follow the device" option.
                itemCount: zones.length + 1,
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return _ZoneRow(
                      label: l.systemDefault,
                      selected: widget.current == null,
                      onTap: () => Navigator.pop(
                        context,
                        _TimeZoneSheet.systemSentinel,
                      ),
                    );
                  }
                  final zone = zones[i - 1];
                  return _ZoneRow(
                    label: zone,
                    selected: widget.current == zone,
                    onTap: () => Navigator.pop(context, zone),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoneRow extends StatelessWidget {
  const _ZoneRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.current;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      title: Text(
        label,
        style: GoogleFonts.nunito(
          color: selected ? t.accentStrong : t.textPrimary,
          fontSize: 13,
          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      trailing: selected
          ? Icon(Icons.check, size: 18, color: t.accentStrong)
          : null,
    );
  }
}
