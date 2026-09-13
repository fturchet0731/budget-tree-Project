import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/tree_health_labels.dart';
import '../services/tree_health_service.dart';
import '../theme/app_dims.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_scrollbar.dart';
import '../widgets/pixel/pixel.dart';
import '../widgets/ui/entrance.dart';

/// The tree collection: every status tree the player can reach, so they can
/// see what staying consistent grows into and what lapsing walks back toward.
///
/// Eight score tiers (driven by the 0 to 100 consistency score) then eight
/// prestige tiers (earned by holding a radiant tree over time). Locked
/// prestige tiers are dimmed rather than hidden — the point of the screen is
/// showing what is still out there.
class StatusTreesScreen extends StatefulWidget {
  const StatusTreesScreen({super.key});

  @override
  State<StatusTreesScreen> createState() => _StatusTreesScreenState();
}

class _StatusTreesScreenState extends State<StatusTreesScreen> {
  TreeHealth _health = TreeHealth.fresh;

  // Score bands aligned to TreeHealthTier order (see TreeHealthService.tierFor).
  static const _bands = <(int, int)>[
    (0, 12), // barren
    (13, 25), // sparse
    (26, 38), // wilting
    (39, 51), // holding
    (52, 64), // leafing
    (65, 77), // full
    (78, 89), // flourishing
    (90, 100), // radiant
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final h = await TreeHealthService.current();
    if (!mounted) return;
    setState(() => _health = h);
  }

  /// Score tiers count as seen up to the one currently shown, plus whatever
  /// prestige has actually been earned (prestige is never lost).
  int get _unlocked {
    final score = _health.isEmpty ? 0 : _health.tier.index + 1;
    final prestige =
        _health.earnedPrestige == null ? 0 : _health.earnedPrestige!.index + 1;
    return score + prestige;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final total = TreeHealthTier.values.length + PrestigeTier.values.length;
    final currentScoreTier = _health.isEmpty ? null : _health.tier;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PixelHeader(
              title: l.statusTreesTitle,
              strapline: l.statusTreesUnlocked(_unlocked, total),
            ),
            Expanded(
              child: AppScrollbar(
                builder: (controller) => SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l.statusTreesIntro,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppDims.s16),
                      _SectionLabel(
                        title: l.statusTreesScoreHeader,
                        subtitle: l.statusTreesScoreSub,
                      ),
                      const SizedBox(height: AppDims.s8),
                      _TierGrid(
                        cells: [
                          for (var i = 0;
                              i < TreeHealthTier.values.length;
                              i++)
                            _TierCell(
                              spriteKey: TreeHealthTier.values[i].name,
                              name: TreeHealthTier.values[i].label(l),
                              detail: l.statusTreeScoreBand(
                                  _bands[i].$1, _bands[i].$2),
                              current: !_health.showsPrestige &&
                                  currentScoreTier == TreeHealthTier.values[i],
                              locked: false,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppDims.s20),
                      _SectionLabel(
                        title: l.statusTreesPrestigeHeader,
                        subtitle: l.statusTreesPrestigeSub,
                      ),
                      const SizedBox(height: AppDims.s8),
                      _TierGrid(
                        cells: [
                          for (final p in PrestigeTier.values)
                            _TierCell(
                              spriteKey: p.name,
                              name: p.label(l),
                              detail: l.hubPrestigeDays(p.days),
                              current: _health.showsPrestige &&
                                  _health.earnedPrestige == p,
                              locked: _health.earnedPrestige == null ||
                                  p.index > _health.earnedPrestige!.index,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppDims.s16),
                      AcornDialogue(
                        speaker: l.acornName.toUpperCase(),
                        text: l.statusTreesAcornHint,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionLabel({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 3),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// A three-column collection grid, the way a game shows a bestiary.
class _TierGrid extends StatelessWidget {
  final List<_TierCell> cells;
  const _TierGrid({required this.cells});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppDims.s8,
      crossAxisSpacing: AppDims.s8,
      childAspectRatio: 0.78,
      children: [
        for (var i = 0; i < cells.length; i++)
          Entrance(delay: Duration(milliseconds: 30 * i), child: cells[i]),
      ],
    );
  }
}

class _TierCell extends StatelessWidget {
  final String spriteKey;
  final String name;
  final String detail;
  final bool current;
  final bool locked;

  const _TierCell({
    required this.spriteKey,
    required this.name,
    required this.detail,
    required this.current,
    required this.locked,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = AppTokens.of(context);
    return PixelBox(
      fill: current ? t.accentTint : t.card,
      border: current ? t.accent : t.cardBorder,
      drop: AppDims.dropSmall,
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Opacity(
              // Locked tiers are shown, not hidden: the point is seeing what
              // is still ahead.
              opacity: locked ? 0.42 : 1,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  LayoutBuilder(
                    builder: (context, c) => PixelSpriteSheet(
                      asset: 'assets/status_trees/$spriteKey.png',
                      size: c.biggest.shortestSide,
                      staticFrame: 0,
                    ),
                  ),
                  if (locked)
                    const PixelSprite(asset: PixelIcons.lock, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTheme.label(
              9,
              locked ? t.textTertiary : t.textPrimary,
              spacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            current ? l.statusTreeYouAreHere.toUpperCase() : detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTheme.label(
              9,
              current ? t.accentStrong : t.textTertiary,
              spacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
