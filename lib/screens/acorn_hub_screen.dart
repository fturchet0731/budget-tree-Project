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
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../tutorial/tutorial_content.dart';
import '../tutorial/tutorial_overlay.dart';
import '../widgets/acorn_mascot.dart';
import '../widgets/pixel/pixel.dart';
import '../widgets/app_scrollbar.dart';
import '../widgets/charts/hub_charts.dart';
import '../widgets/check_in_sheet.dart';
import '../widgets/status_tree_view.dart';
import '../widgets/skeleton.dart';
import '../widgets/ui/app_card.dart';
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

    if (stats == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.hubTitle)),
        body: const Padding(
          padding: EdgeInsets.all(AppDims.s20),
          child: ProfileSkeleton(),
        ),
      );
    }

    final health = stats.health;
    // The sixteen trees are the progression, so the level is which one you are
    // standing on: 1..8 across the score tiers, 9..16 through prestige.
    final level = health.showsPrestige && health.earnedPrestige != null
        ? 8 + health.earnedPrestige!.index + 1
        : health.tier.index + 1;

    return Scaffold(
      body: Column(
        children: [
          // Diegetic hero: you arrive at the hub and your tree is standing
          // there, rather than reading a title bar about it.
          PixelScene(
            height: 212,
            subject: StatusTreeView(spriteKey: health.spriteKey, size: 158),
            showAcorn: true,
            onBack: () => Navigator.of(context).maybePop(),
            backLabel: MaterialLocalizations.of(context).backButtonTooltip,
            topRight: Row(
              children: [
                PixelBadge(
                  label: l.hubLevel(level),
                  fill: AppTokens.of(context).panelDark,
                  ink: AppTokens.of(context).gold,
                ),
                const SizedBox(width: 6),
                PixelIconButton(
                  icon: PixelIcons.scroll,
                  onPressed: _showTutorial,
                  semanticLabel: l.hubHowItWorks,
                ),
              ],
            ),
          ),
          Expanded(
            child: AppScrollbar(
              builder: (controller) => SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Entrance(child: _HealthCard(stats: stats)),
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
                        // The two ways forward, side by side as in the handoff.
                        Entrance(
                          delay: const Duration(milliseconds: 300),
                          child: Row(
                            children: [
                              Expanded(
                                child: PixelButton(
                                  label: l.hubSeeAllTrees,
                                  tone: PixelTone.neutral,
                                  onPressed: _openTrees,
                                ),
                              ),
                              const SizedBox(width: AppDims.s8),
                              Expanded(
                                child: PixelButton(
                                  label: l.hubTalkAction,
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const AcornChatScreen(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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

    // The tier name is the headline — you read where you stand before you read
    // a number — with the score sitting quietly beside it.
    return PixelBox(
      margin: const EdgeInsets.only(bottom: AppDims.s12),
      padding: const EdgeInsets.all(11),
      drop: AppDims.dropButton,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  health.isEmpty ? l.hubTreeFresh : health.statusLabel(l),
                  style: AppTheme.display(24, t.textPrimary),
                ),
              ),
              if (!health.isEmpty)
                Text(
                  '${health.score.round()}/100',
                  style: AppTheme.label(9, t.accentStrong),
                ),
            ],
          ),
          if (!health.isEmpty) ...[
            const SizedBox(height: 9),
            PixelBar(value: health.fraction, height: 16),
          ],
          const SizedBox(height: 9),
          Text(
            health.isEmpty ? l.hubTreeFreshSub : l.hubScoreSub(health.score.round()),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (health.showsPrestige && health.prestigeDays >= 1) ...[
            const SizedBox(height: 4),
            Text(
              l.hubPrestigeDays(health.prestigeDays.floor()),
              style: AppTheme.label(9, t.gold),
            ),
          ],
          if (health.delta.abs() >= 1) ...[
            const SizedBox(height: 4),
            Text(
              health.delta > 0
                  ? l.hubDeltaUp(health.delta.round())
                  : l.hubDeltaDown(health.delta.abs().round()),
              style: AppTheme.label(
                  9, health.delta > 0 ? t.success : t.warning),
            ),
          ],
          if (stats.hasCheckIns) ...[
            const SizedBox(height: 11),
            // Streak row: flame, weeks, and a seven-pip week meter.
            Row(
              children: [
                const PixelSprite(asset: PixelIcons.flame, size: 18),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    l.hubStreakWeeks(health.currentStreak),
                    style: AppTheme.label(9, t.textSecondary),
                  ),
                ),
                for (var i = 0; i < 7; i++)
                  Padding(
                    padding: const EdgeInsets.only(left: 3),
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: i < health.currentStreak ? t.gold : t.track,
                        border: Border.all(color: t.cardBorder, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ],
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

    // Acorn delivers the reflection from her dark NPC panel, the same box she
    // speaks from on the dashboard.
    return PixelBox(
      margin: const EdgeInsets.only(bottom: AppDims.s12),
      padding: const EdgeInsets.all(10),
      drop: AppDims.dropButton,
      fill: t.panelDark,
      border: t.panelDarkBorder,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AcornPortrait(size: 44),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.hubReflectionTitle.toUpperCase(),
                  style: AppTheme.label(9, Conifer.c300),
                ),
                const SizedBox(height: 6),
                Text(
                  report?.headline ??
                      reflection?.text ??
                      (ready ? l.hubReflectionReady : l.hubReflectionEmpty),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.display(13, t.panelDarkText,
                          weight: FontWeight.w400)
                      .copyWith(height: 1.3),
                ),
                const SizedBox(height: 8),
                if (ready)
                  PixelButton(
                    label: l.hubReflectionPlay,
                    tone: PixelTone.gold,
                    expand: false,
                    fontSize: 10,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ReflectionStoryScreen(),
                      ),
                    ),
                  )
                else
                  Text(
                    l.hubReflectionEmptySub,
                    style: AppTheme.label(9, t.textTertiary),
                  ),
              ],
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

