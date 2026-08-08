import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../l10n/tree_health_labels.dart';
import '../models/reflection_report.dart';
import '../services/app_settings.dart';
import '../services/reflection_service.dart';
import '../services/reflection_stats.dart';
import '../theme/app_dims.dart';
import '../theme/app_tokens.dart';
import '../widgets/acorn_mascot.dart';
import '../widgets/acorn_says.dart';
import '../widgets/charts/hub_charts.dart';
import '../widgets/health_tree_view.dart';
import '../widgets/skeleton.dart';
import '../widgets/ui/app_buttons.dart';
import '../widgets/ui/app_progress_bar.dart';
import '../widgets/ui/pressable.dart';
import 'acorn_chat_screen.dart';

/// The reflection as a short presentation, in the order a person can follow:
/// here is the period, here is how consistent you were, here is what went
/// well, here is what did not, here is what to try next.
///
/// Acorn narrates every slide and the charts sit under his line, so the numbers
/// and the words arrive together. Slides with nothing behind them are dropped
/// rather than shown empty, which matters most for the overspend slide: the
/// only plan-versus-actual data in the app is what the user optionally typed
/// into a check-in, so for many people that slide will not exist yet.
class ReflectionStoryScreen extends StatefulWidget {
  const ReflectionStoryScreen({super.key});

  @override
  State<ReflectionStoryScreen> createState() => _ReflectionStoryScreenState();
}

class _ReflectionStoryScreenState extends State<ReflectionStoryScreen> {
  final _pages = PageController();
  ReflectionStats? _stats;
  ReflectionReport? _report;
  Reflection? _reflection;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final stats = await ReflectionStats.load();
    final report = await ReflectionService.instance.loadLatestReport();
    final reflection = await ReflectionService.instance.latest();
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _report = report;
      _reflection = reflection;
    });
  }

  void _go(int to) {
    final m = AppSettings.instance.motionMultiplier;
    if (m == 0) {
      _pages.jumpToPage(to);
    } else {
      _pages.animateToPage(
        to,
        duration: Duration(milliseconds: (320 * m).round()),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _ask(String about) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AcornChatScreen(opener: about)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = AppTokens.of(context);
    final stats = _stats;

    if (stats == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.hubReflectionTitle)),
        body: const Padding(
          padding: EdgeInsets.all(AppDims.s20),
          child: ProfileSkeleton(),
        ),
      );
    }

    final slides = _buildSlides(l, stats);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.hubReflectionTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.close),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Position dots: a presentation should say how long it is.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  for (var i = 0; i < slides.length; i++)
                    Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(
                          right: i == slides.length - 1 ? 0 : 5,
                        ),
                        decoration: BoxDecoration(
                          color: i <= _index ? t.accent : t.accentSoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => _index = i),
                children: slides,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  if (_index > 0)
                    Expanded(
                      child: AppSecondaryButton(
                        label: l.back,
                        onPressed: () => _go(_index - 1),
                      ),
                    ),
                  if (_index > 0) const SizedBox(width: AppDims.s12),
                  Expanded(
                    flex: 2,
                    child: AppPrimaryButton(
                      label: _index == slides.length - 1
                          ? l.hubStoryDone
                          : l.next,
                      onPressed: _index == slides.length - 1
                          ? () => Navigator.of(context).pop()
                          : () => _go(_index + 1),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSlides(AppLocalizations l, ReflectionStats stats) {
    final report = _report;
    final health = stats.health;

    return [
      // 1. Where you stand.
      _Slide(
        line: report?.headline.isNotEmpty == true
            ? report!.headline
            : (_reflection?.text ?? l.hubStoryIntroFallback),
        title: l.hubStoryIntroTitle,
        child: Column(
          children: [
            HealthTreeView(health: health.fraction, size: 150),
            const SizedBox(height: AppDims.s12),
            Text(
              health.isEmpty ? l.hubTreeFresh : health.tier.label(l),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppDims.s8),
            AppProgressBar(value: health.fraction),
          ],
        ),
      ),

      // 2. How consistent you were.
      if (stats.hasCheckIns)
        _Slide(
          line: l.hubStoryConsistencyLine(
            stats.answered,
            stats.total,
          ),
          title: l.hubConsistencyTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConsistencyStrip(points: stats.consistency),
              if (stats.healthTrail.length > 1) ...[
                const SizedBox(height: AppDims.s24),
                TrendLine(
                  values: stats.healthTrail,
                  minValue: 0,
                  maxValue: 100,
                  height: 110,
                ),
              ],
            ],
          ),
        ),

      // 3. What went well.
      if (report != null && report.strengths.isNotEmpty)
        _Slide(
          line: report.strengths.first.detail,
          title: l.hubStoryStrengthsTitle,
          child: _PointList(points: report.strengths, positive: true),
        ),

      // 4. Where it slipped. Skipped entirely when there is nothing measured,
      // rather than drawing an axis over no data.
      if (stats.hasActuals)
        _Slide(
          line: report != null && report.weaknesses.isNotEmpty
              ? report.weaknesses.first.detail
              : l.hubStoryOverspendFallback,
          title: l.hubOverspendTitle,
          child: PlannedVsActualBars(rows: stats.overspend),
        )
      else if (report != null && report.weaknesses.isNotEmpty)
        _Slide(
          line: report.weaknesses.first.detail,
          title: l.hubStoryWeaknessesTitle,
          child: _PointList(points: report.weaknesses, positive: false),
        ),

      // 5. What to try next.
      if (report != null && report.suggestions.isNotEmpty)
        _Slide(
          line: report.closing.isNotEmpty
              ? report.closing
              : l.hubStorySuggestionsLine,
          title: l.hubStorySuggestionsTitle,
          child: Column(
            children: [
              for (final s in report.suggestions)
                _SuggestionTile(
                  point: s,
                  onAsk: () => _ask(s.title),
                ),
            ],
          ),
        )
      else
        _Slide(
          line: l.hubStoryNoAdviceLine,
          title: l.hubStorySuggestionsTitle,
          child: AppPrimaryButton(
            label: l.hubTalkAction,
            icon: Icons.chat_bubble_outline,
            onPressed: () => _ask(''),
          ),
        ),
    ];
  }
}

/// One beat of the presentation: Acorn's line on top, the evidence below it.
class _Slide extends StatelessWidget {
  final String line;
  final String title;
  final Widget child;

  const _Slide({
    required this.line,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const AcornMascot(size: 64),
              const SizedBox(width: 6),
              Expanded(child: AcornSays(text: line, title: title)),
            ],
          ),
          const SizedBox(height: AppDims.s20),
          child,
        ],
      ),
    );
  }
}

class _PointList extends StatelessWidget {
  final List<ReflectionPoint> points;
  final bool positive;

  const _PointList({required this.points, required this.positive});

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Column(
      children: [
        for (final p in points)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: AppDims.s12),
            padding: const EdgeInsets.all(AppDims.s16),
            decoration: BoxDecoration(
              color: t.canvasSoft,
              borderRadius: BorderRadius.circular(AppDims.rInner),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  positive ? Icons.trending_up : Icons.trending_down,
                  size: 18,
                  color: positive ? t.success : t.warning,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.title,
                        style: GoogleFonts.nunito(
                          color: t.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (p.detail.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          p.detail,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final ReflectionPoint point;
  final VoidCallback onAsk;

  const _SuggestionTile({required this.point, required this.onAsk});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = AppTokens.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppDims.s12),
      padding: const EdgeInsets.all(AppDims.s16),
      decoration: BoxDecoration(
        color: t.accentTint,
        borderRadius: BorderRadius.circular(AppDims.rInner),
        border: Border.all(color: t.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            point.title,
            style: GoogleFonts.nunito(
              color: t.textPrimary,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (point.detail.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              point.detail,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: AppDims.s12),
          PressableScale(
            onTap: onAsk,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 15,
                  color: t.accentStrong,
                ),
                const SizedBox(width: 6),
                Text(
                  l.hubAskAboutThis,
                  style: GoogleFonts.nunito(
                    color: t.accentStrong,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
