import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../services/app_settings.dart';
import '../services/auth_service.dart';
import '../services/notification_scheduler.dart';
import '../services/sync_engine.dart';
import '../tutorial/tutorial_content.dart';
import '../tutorial/tutorial_tour.dart';
import '../widgets/info_button.dart';

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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14210C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sign out?',
          style: GoogleFonts.fredoka(
              fontWeight: FontWeight.w600,
              color: AppColors.stoneBeigeColor,
              fontSize: 20),
        ),
        content: Text(
          'Your forest is saved in the cloud — sign back in any time to bring it back.',
          style: GoogleFonts.nunito(
              color: AppColors.mossGreen, fontSize: 14, height: 1.55),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.nunito(color: AppColors.mossGreen)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sign out',
                style: GoogleFonts.nunito(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await AuthService.instance.signOut();
    // AuthGate listens to AuthService and will swap back to the login screen.
  }

  Future<void> _confirmEraseAllData() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0808),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.dangerRed, size: 24),
            const SizedBox(width: 10),
            Text(
              'Erase all data?',
              style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.w600,
                  color: AppColors.stoneBeigeColor,
                  fontSize: 20),
            ),
          ],
        ),
        content: Text(
          'This will permanently remove every budget tree and goal sapling. Your app preferences will remain. This cannot be undone.',
          style: GoogleFonts.nunito(
              color: AppColors.mossGreen, fontSize: 14, height: 1.55),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.nunito(color: AppColors.mossGreen)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerRed,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Erase Everything',
                style: GoogleFonts.nunito(
                    color: Colors.white, fontWeight: FontWeight.bold)),
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
        backgroundColor: const Color(0xFF1A0808),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Are you absolutely sure?',
          style: GoogleFonts.fredoka(
              fontWeight: FontWeight.w600,
              color: AppColors.stoneBeigeColor,
              fontSize: 19),
        ),
        content: Text(
          'Last chance. After this, every saved tree and goal will be gone.',
          style: GoogleFonts.nunito(
              color: AppColors.mossGreen, fontSize: 14, height: 1.55),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep my data',
                style: GoogleFonts.nunito(color: AppColors.mossGreen)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerRed,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Yes, erase',
                style: GoogleFonts.nunito(
                    color: Colors.white, fontWeight: FontWeight.bold)),
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
        backgroundColor: const Color(0xFF1A0808),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.delete_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(
              'All data erased.',
              style: GoogleFonts.nunito(
                  color: AppColors.stoneBeigeColor, fontSize: 14),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppPalettes.deepForest()),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios,
                      color: AppColors.stoneBeigeColor),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'Settings',
                  style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.w600,
                      color: AppColors.stoneBeigeColor,
                      fontSize: 22),
                ),
                actions: const [
                  Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: SectionInfoButton(section: TutorialSection.settings),
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _SectionHeader(
                        icon: Icons.brush_outlined, label: 'APPEARANCE'),
                    _SettingsCard(
                      children: [
                        _TileLabel(text: 'Text size'),
                        const SizedBox(height: 10),
                        _ChoiceRow<AppTextScale>(
                          current: settings.textScale,
                          options: const [
                            (AppTextScale.compact, 'Compact'),
                            (AppTextScale.normal, 'Default'),
                            (AppTextScale.large, 'Large'),
                          ],
                          onChanged: settings.setTextScale,
                        ),
                        const SizedBox(height: 18),
                        _TileLabel(text: 'Theme palette'),
                        const SizedBox(height: 10),
                        _ChoiceRow<AppPalette>(
                          current: settings.palette,
                          options: const [
                            (AppPalette.forestDark, 'Forest'),
                            (AppPalette.midnight, 'Midnight'),
                            (AppPalette.twilight, 'Twilight'),
                          ],
                          onChanged: settings.setPalette,
                        ),
                        const SizedBox(height: 18),
                        _TileLabel(text: 'Motion'),
                        const SizedBox(height: 6),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(
                            'Full animations',
                            style: GoogleFonts.nunito(
                                color: AppColors.stoneBeigeColor,
                                fontSize: 13),
                          ),
                          subtitle: Text(
                            'Disable for snappier, less-animated screens',
                            style: GoogleFonts.nunito(
                                color: AppColors.mossGreen.withValues(alpha: 0.7),
                                fontSize: 11),
                          ),
                          value: settings.motionFull,
                          activeThumbColor: AppColors.lightLeaf,
                          onChanged: settings.setMotionFull,
                        ),
                        const SizedBox(height: 12),
                        _TileLabel(text: 'Sound & haptics'),
                        const SizedBox(height: 6),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(
                            'Feedback cues',
                            style: GoogleFonts.nunito(
                                color: AppColors.stoneBeigeColor,
                                fontSize: 13),
                          ),
                          subtitle: Text(
                            'Taps and chimes when you plant, set goals, and save',
                            style: GoogleFonts.nunito(
                                color: AppColors.mossGreen.withValues(alpha: 0.7),
                                fontSize: 11),
                          ),
                          value: settings.soundEnabled,
                          activeThumbColor: AppColors.lightLeaf,
                          onChanged: settings.setSoundEnabled,
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _SectionHeader(
                        icon: Icons.language,
                        label: l.settingsLanguageTitle.toUpperCase()),
                    _SettingsCard(
                      children: [
                        _TileLabel(text: l.settingsLanguageSubtitle),
                        const SizedBox(height: 8),
                        _LanguagePicker(
                          current: settings.languageSelection,
                          systemLabel: l.systemDefault,
                          onChanged: settings.setLocale,
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _SectionHeader(
                        icon: Icons.notifications_outlined,
                        label: 'NOTIFICATIONS'),
                    const _NotificationsCard(),
                    const SizedBox(height: 22),
                    _SectionHeader(
                        icon: Icons.menu_book_outlined, label: 'GUIDE'),
                    _SettingsCard(
                      children: [
                        _ActionTile(
                          icon: Icons.school_outlined,
                          iconColor: AppColors.lightLeaf,
                          title: 'Replay tutorial',
                          subtitle:
                              'Let Acorn walk you through the app again.',
                          onTap: () => GuidedTour.start(context),
                        ),
                      ],
                    ),
                    if (AuthService.instance.isSignedIn) ...[
                      const SizedBox(height: 22),
                      _SectionHeader(
                          icon: Icons.person_outline, label: 'ACCOUNT'),
                      _SettingsCard(
                        children: [
                          _InfoRow(
                            label: 'Signed in as',
                            value: AuthService.instance.currentUser?.email ??
                                'Unknown',
                          ),
                          const SizedBox(height: 6),
                          _ActionTile(
                            icon: Icons.logout,
                            iconColor: AppColors.warningAmber,
                            title: 'Sign out',
                            subtitle:
                                'Your data stays safe in the cloud.',
                            onTap: _signOut,
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 22),
                    _SectionHeader(
                        icon: Icons.storage_outlined, label: 'DATA'),
                    _SettingsCard(
                      children: [
                        _ActionTile(
                          icon: Icons.delete_forever_outlined,
                          iconColor: AppColors.dangerRed,
                          title: 'Erase all data',
                          subtitle:
                              'Removes every saved budget tree and goal sapling.',
                          onTap: _confirmEraseAllData,
                          danger: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _SectionHeader(
                        icon: Icons.info_outline, label: 'ABOUT'),
                    _SettingsCard(
                      children: [
                        _InfoRow(
                            label: 'Budget Tree',
                            value: 'v1.0.0'),
                        _InfoRow(
                            label: 'Built with', value: 'Flutter / Dart'),
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
          Icon(icon,
              size: 14,
              color: AppColors.mossGreen.withValues(alpha: 0.75)),
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF152B12).withValues(alpha: 0.95),
            const Color(0xFF0B1A09).withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: AppColors.forestGreen.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
          fontSize: 13.5),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.forestGreen.withValues(alpha: 0.45)
                    : AppColors.soilMid,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected
                      ? AppColors.lightLeaf.withValues(alpha: 0.75)
                      : AppColors.mossGreen.withValues(alpha: 0.25),
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
                            ? AppColors.lightLeaf
                            : AppColors.stoneBeigeColor,
                        fontSize: 14,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (selected)
                    const Icon(Icons.check_circle,
                        color: AppColors.lightLeaf, size: 18),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ChoiceRow<T> extends StatelessWidget {
  final T current;
  final List<(T, String)> options;
  final void Function(T) onChanged;
  const _ChoiceRow({
    required this.current,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((opt) {
        final (value, label) = opt;
        final selected = value == current;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.forestGreen.withValues(alpha: 0.45)
                    : AppColors.soilMid,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected
                      ? AppColors.lightLeaf.withValues(alpha: 0.75)
                      : AppColors.mossGreen.withValues(alpha: 0.25),
                  width: selected ? 1.5 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: GoogleFonts.nunito(
                  color: selected
                      ? AppColors.lightLeaf
                      : AppColors.stoneBeigeColor,
                  fontSize: 12.5,
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.w500,
                ),
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
                        color: AppColors.mossGreen, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: AppColors.mossGreen.withValues(alpha: 0.6)),
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
          Text(label,
              style: GoogleFonts.nunito(
                  color: AppColors.mossGreen, fontSize: 13)),
          Text(value,
              style: GoogleFonts.nunito(
                  color: AppColors.stoneBeigeColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
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

  static const _weekdayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];

  Future<void> _apply(Future<void> Function() change) async {
    await change();
    await NotificationScheduler.rescheduleAll();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppSettings.instance;
    return _SettingsCard(
      children: [
        _NotifSwitch(
          title: 'Budget warnings',
          subtitle: 'When a budget nears or passes your income',
          value: s.notifBudgetWarnings,
          onChanged: (v) => _apply(() => s.setNotifBudgetWarnings(v)),
        ),
        const SizedBox(height: 6),
        _NotifSwitch(
          title: 'Streak reminders',
          subtitle: 'A daily nudge to keep your saving streak alive',
          value: s.notifStreakReminders,
          onChanged: (v) => _apply(() => s.setNotifStreakReminders(v)),
        ),
        if (s.notifStreakReminders)
          _TapRow(
            label: 'Remind me at',
            value: TimeOfDay(hour: s.streakHour, minute: s.streakMinute)
                .format(context),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime:
                    TimeOfDay(hour: s.streakHour, minute: s.streakMinute),
              );
              if (picked != null) {
                await _apply(() => s.setStreakTime(picked.hour, picked.minute));
              }
            },
          ),
        const SizedBox(height: 6),
        _NotifSwitch(
          title: 'Weekly summary',
          subtitle: 'A once-a-week recap of your progress',
          value: s.notifWeeklySummary,
          onChanged: (v) => _apply(() => s.setNotifWeeklySummary(v)),
        ),
        if (s.notifWeeklySummary) ...[
          _TapRow(
            label: 'Day',
            value: _weekdayNames[(s.weeklyWeekday - 1).clamp(0, 6)],
            onTap: () async {
              final picked = await showModalBottomSheet<int>(
                context: context,
                backgroundColor: const Color(0xFF0D2010),
                builder: (ctx) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(7, (i) {
                      final weekday = i + 1;
                      return ListTile(
                        title: Text(
                          _weekdayNames[i],
                          style: GoogleFonts.nunito(
                              color: AppColors.stoneBeigeColor),
                        ),
                        trailing: s.weeklyWeekday == weekday
                            ? const Icon(Icons.check,
                                color: AppColors.lightLeaf, size: 18)
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
            label: 'Time',
            value: TimeOfDay(hour: s.weeklyHour, minute: 0).format(context),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: s.weeklyHour, minute: 0),
              );
              if (picked != null) {
                await _apply(
                    () => s.setWeeklySchedule(s.weeklyWeekday, picked.hour));
              }
            },
          ),
        ],
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
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(
        title,
        style: GoogleFonts.nunito(
            color: AppColors.stoneBeigeColor, fontSize: 13),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.nunito(
            color: AppColors.mossGreen.withValues(alpha: 0.7), fontSize: 11),
      ),
      value: value,
      activeThumbColor: AppColors.lightLeaf,
      onChanged: onChanged,
    );
  }
}

class _TapRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _TapRow(
      {required this.label, required this.value, required this.onTap});

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
                  color: AppColors.mossGreen, fontSize: 12.5),
            ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.forestGreen.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.lightLeaf.withValues(alpha: 0.4)),
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
            const Icon(Icons.chevron_right,
                color: AppColors.mossGreen, size: 18),
          ],
        ),
      ),
    );
  }
}
