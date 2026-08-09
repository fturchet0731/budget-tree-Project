import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../l10n/tree_health_labels.dart';
import '../models/check_in.dart';
import '../services/check_in_service.dart';
import '../services/reflection_service.dart';
import '../services/reflection_stats.dart';
import '../theme/app_dims.dart';
import '../theme/app_tokens.dart';
import '../tutorial/tutorial_content.dart';
import '../tutorial/tutorial_overlay.dart';
import '../widgets/acorn_mascot.dart';
import '../widgets/app_scrollbar.dart';
import '../widgets/charts/hub_charts.dart';
import '../widgets/check_in_sheet.dart';
import '../widgets/status_tree_view.dart';
import '../widgets/skeleton.dart';
import '../widgets/ui/app_buttons.dart';
import '../widgets/ui/app_card.dart';
import '../widgets/ui/app_progress_bar.dart';
import '../widgets/ui/entrance.dart';
import '../widgets/ui/pressable.dart';
import '../widgets/ui/section_header.dart';
import 'acorn_chat_screen.dart';
import 'reflection_story_screen.dart';
import 'status_trees_screen.dart';

/// Acorn's Hub: the backbone of the AI layer.
///
/// Everything the coach knows about the user lives behind this one screen, in
/// the order a person actually asks it. How am I doing (the tree and the
/// score), what has my record been (the consistency strip and trend), where is
/// the money going wrong (planned against actual), and then the two ways
/// forward: watch Acorn present the period, or just ask.
class AcornHubScreen extends StatefulWidget {
  const AcornHubScreen({super.key});

  @override
  State<AcornHubScreen> createState() => _AcornHubScreenState();
}

class _AcornHubScreenState extends State<AcornHubScreen> {
  ReflectionStats? _stats;
  List<CheckIn> _pending = const [];
  Reflection? _reflection;

  static const _introSeenKey = 'hub_tutorial_seen_v1';

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowIntro());
  }

  Future<void> _load() async {
    final stats = await ReflectionStats.load();
    final pending = await CheckInService.pending();
    final reflection = await ReflectionService.instance.latest();
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _pending = pending;
      _reflection = reflection;
    });
  }

  /// First time the user opens the hub, Acorn explains what it all means. After
  /// that it's on demand via the help button.
  Future<void> _maybeShowIntro() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_introSeenKey) ?? false) return;
    await prefs.setBool(_introSeenKey, true);
    if (!mounted) return;
    await _showTutorial();
  }

  Future<void> _showTutorial() async {
    final l = AppLocalizations.of(context);
    await showTutorialDialog(
      context,
      steps: [
        TutorialStep(l.tutHub1, expression: AcornExpression.happy),
        TutorialStep(l.tutHub2),
        TutorialStep(l.tutHub3),
        TutorialStep(l.tutHub4),
        TutorialStep(l.tutHub5),
        TutorialStep(l.tutHub6, expression: AcornExpression.happy),
      ],
      sectionTitle: l.hubTitle,
      lastStepHint: l.tourTapFinish,
      cancelLabel: l.tourClose,
    );
  }

  void _openTrees() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StatusTreesScreen()),
    );
  }

  Future<void> _answer(CheckIn checkIn) async {
    final saved = await showCheckInSheet(context, checkIn);
    if (saved && mounted) {
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.checkInSaved)));
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final stats = _stats;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.hubTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: l.hubHowItWorks,
            onPressed: _showTutorial,
          ),
        ],
      ),
      body: stats == null
          ? const Padding(
              padding: EdgeInsets.all(AppDims.s20),
              child: ProfileSkeleton(),
            )
          : AppScrollbar(
              builder: (controller) => SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Entrance(child: _HealthCard(stats: stats)),
                        Entrance(
                          delay: const Duration(milliseconds: 30),
                          child: Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppDims.s12),
                            child: AppSecondaryButton(
                              label: l.hubSeeAllTrees,
                              icon: Icons.forest_outlined,
                              onPressed: _openTrees,
                            ),
                          ),
                        ),
                        if (_pending.isNotEmpty)
                          Entrance(
                            delay: const Duration(milliseconds: 60),
                            child: _PendingCard(
                              pending: _pending,
                              onAnswer: _answer,
                            ),
                          ),
                        Entrance(
                          delay: const Duration(milliseconds: 120),
                          child: _ReflectionCard(
                            reflection: _reflection,
                            stats: stats,
                          ),
                        ),
                        Entrance(
                          delay: const Duration(milliseconds: 180),
                          child: _ConsistencyCard(stats: stats),
                        ),
                        Entrance(
                          delay: const Duration(milliseconds: 240),
                          child: _OverspendCard(stats: stats),
                        ),
                        Entrance(
                          delay: const Duration(milliseconds: 300),
                          child: _TalkCard(
                            onOpen: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AcornChatScreen(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

// ── Cards ───────────────────────────────────────────────────────

class _HealthCard extends StatelessWidget {
  final ReflectionStats stats;
  const _HealthCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = AppTokens.of(context);
    final health = stats.health;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppDims.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusTreeView(spriteKey: health.spriteKey, size: 96),
              const SizedBox(width: AppDims.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      health.isEmpty
                          ? l.hubTreeFresh
                          : health.statusLabel(l),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      health.isEmpty
                          ? l.hubTreeFreshSub
                          : l.hubScoreSub(health.score.round()),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (health.showsPrestige && health.prestigeDays >= 1) ...[
                      const SizedBox(height: 4),
                      Text(
                        l.hubPrestigeDays(health.prestigeDays.floor()),
                        style: GoogleFonts.nunito(
                          color: t.accentStrong,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                    if (!health.isEmpty) ...[
                      const SizedBox(height: AppDims.s8),
                      AppProgressBar(value: health.fraction),
                      if (health.delta.abs() >= 1) ...[
                        const SizedBox(height: 6),
                        Text(
                          health.delta > 0
                              ? l.hubDeltaUp(health.delta.round())
                              : l.hubDeltaDown(health.delta.abs().round()),
                          style: GoogleFonts.nunito(
                            color: health.delta > 0 ? t.success : t.warning,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (stats.hasCheckIns) ...[
            const SizedBox(height: AppDims.s16),
            Row(
              children: [
                _Stat(
                  value: '${health.currentStreak}',
                  label: l.hubStatStreak,
                ),
                _Stat(
                  value: '${(stats.answerRate * 100).round()}%',
                  label: l.hubStatAnswered,
                ),
                _Stat(
                  value: '${health.bestStreak}',
                  label: l.hubStatBest,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.fredoka(
              color: t.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: t.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final List<CheckIn> pending;
  final ValueChanged<CheckIn> onAnswer;
  const _PendingCard({required this.pending, required this.onAnswer});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = AppTokens.of(context);
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppDims.s12),
      accent: t.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.hubPendingTitle(pending.length),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            l.hubPendingSub,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppDims.s12),
          for (final c in pending.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: AppDims.s8),
              child: PressableScale(
                onTap: () => onAnswer(c),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: t.canvasSoft,
                    borderRadius: BorderRadius.circular(AppDims.rInner),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        c.kind == CheckInKind.payday
                            ? Icons.event_available
                            : Icons.water_drop,
                        size: 17,
                        color: t.accentStrong,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          c.subjectName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            color: t.textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        MaterialLocalizations.of(context)
                            .formatShortDate(c.dueAt),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: t.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReflectionCard extends StatelessWidget {
  final Reflection? reflection;
  final ReflectionStats stats;
  const _ReflectionCard({required this.reflection, required this.stats});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = AppTokens.of(context);
    final report = ReflectionService.instance.latestReport();
    final ready = reflection != null || stats.hasCheckIns;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppDims.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AcornMascot(size: 54, sway: false),
              const SizedBox(width: AppDims.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.hubReflectionTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      report?.headline ??
                          reflection?.text ??
                          (ready ? l.hubReflectionReady : l.hubReflectionEmpty),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (ready) ...[
            const SizedBox(height: AppDims.s16),
            AppPrimaryButton(
              label: l.hubReflectionPlay,
              icon: Icons.play_arrow_rounded,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ReflectionStoryScreen(),
                ),
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: AppDims.s8),
              child: Text(
                l.hubReflectionEmptySub,
                style: GoogleFonts.nunito(
                  color: t.textTertiary,
                  fontSize: 12.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ConsistencyCard extends StatelessWidget {
  final ReflectionStats stats;
  const _ConsistencyCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (!stats.hasCheckIns) return const SizedBox.shrink();

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppDims.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            label: l.hubConsistencyTitle,
            padding: const EdgeInsets.only(bottom: AppDims.s8),
          ),
          ConsistencyStrip(points: stats.consistency),
          if (stats.healthTrail.length > 1) ...[
            const SizedBox(height: AppDims.s20),
            SectionHeader(
              label: l.hubTrendTitle,
              padding: const EdgeInsets.only(bottom: AppDims.s8),
            ),
            TrendLine(
              values: stats.healthTrail,
              minValue: 0,
              maxValue: 100,
            ),
          ],
        ],
      ),
    );
  }
}

class _OverspendCard extends StatelessWidget {
  final ReflectionStats stats;
  const _OverspendCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = AppTokens.of(context);

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppDims.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            label: l.hubOverspendTitle,
            padding: const EdgeInsets.only(bottom: AppDims.s8),
          ),
          // No spend log exists anywhere else in the app, so this chart is
          // empty until the user has volunteered amounts on a check-in. Say so
          // plainly rather than drawing an axis with nothing on it.
          if (!stats.hasActuals)
            Text(
              l.hubOverspendEmpty,
              style: GoogleFonts.nunito(
                color: t.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            )
          else
            PlannedVsActualBars(rows: stats.overspend),
        ],
      ),
    );
  }
}

class _TalkCard extends StatelessWidget {
  final VoidCallback onOpen;
  const _TalkCard({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.hubTalkTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            l.hubTalkSub,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppDims.s16),
          AppPrimaryButton(
            label: l.hubTalkAction,
            icon: Icons.chat_bubble_outline,
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}
