import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../l10n/tree_health_labels.dart';
import '../services/tree_health_service.dart';
import '../theme/app_dims.dart';
import '../theme/app_shadows.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_scrollbar.dart';
import '../widgets/status_tree_view.dart';
import '../widgets/ui/entrance.dart';
import '../widgets/ui/section_header.dart';

/// The full progression: every status tree the user can reach, so they can see
/// what staying consistent grows into and what lapsing walks them back toward.
///
/// Eight score tiers (driven by the 0 to 100 consistency score) then eight
/// prestige tiers (earned by holding a radiant tree over time). The user's
/// current score tier and any earned prestige are marked.
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;

    // The current score tier is only "where you are" while not showing a
    // prestige tree; when a prestige tree is on show we mark the prestige row.
    final currentScoreTier = _health.isEmpty ? null : _health.tier;

    return Scaffold(
      appBar: AppBar(title: Text(l.statusTreesTitle)),
      body: AppScrollbar(
        builder: (controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Entrance(
                    child: Text(
                      l.statusTreesIntro,
                      style: text.bodyMedium?.copyWith(color: t.textSecondary),
                    ),
                  ),
                  const SizedBox(height: AppDims.s16),
                  SectionHeader(label: l.statusTreesScoreHeader),
                  Text(
                    l.statusTreesScoreSub,
                    style: text.bodySmall?.copyWith(color: t.textSecondary),
                  ),
                  const SizedBox(height: AppDims.s8),
                  for (var i = 0; i < TreeHealthTier.values.length; i++)
                    Entrance(
                      delay: Duration(milliseconds: 40 * i),
                      child: _TierRow(
                        spriteKey: TreeHealthTier.values[i].name,
                        name: TreeHealthTier.values[i].label(l),
                        detail: l.statusTreeScoreBand(_bands[i].$1, _bands[i].$2),
                        isCurrent: !_health.showsPrestige &&
                            currentScoreTier == TreeHealthTier.values[i],
                        earned: false,
                      ),
                    ),
                  const SizedBox(height: AppDims.s20),
                  SectionHeader(label: l.statusTreesPrestigeHeader),
                  Text(
                    l.statusTreesPrestigeSub,
                    style: text.bodySmall?.copyWith(color: t.textSecondary),
                  ),
                  const SizedBox(height: AppDims.s8),
                  for (final p in PrestigeTier.values)
                    _TierRow(
                      spriteKey: p.name,
                      name: p.label(l),
                      detail: l.hubPrestigeDays(p.days),
                      isCurrent: _health.showsPrestige &&
                          _health.earnedPrestige == p,
                      earned: _health.earnedPrestige != null &&
                          p.index <= _health.earnedPrestige!.index,
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

class _TierRow extends StatelessWidget {
  final String spriteKey;
  final String name;
  final String detail;
  final bool isCurrent;
  final bool earned;

  const _TierRow({
    required this.spriteKey,
    required this.name,
    required this.detail,
    required this.isCurrent,
    required this.earned,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDims.s8),
      padding: const EdgeInsets.all(AppDims.s12),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(AppDims.rCard),
        // The current tier gets an accent ring so "you are here" stands out.
        border: Border.all(
          color: isCurrent ? t.accent : t.cardBorder,
          width: isCurrent ? 2 : 1,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: StatusTreeView(spriteKey: spriteKey, size: 56),
          ),
          const SizedBox(width: AppDims.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: text.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (earned && !isCurrent) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.check_circle,
                          size: 15, color: t.success),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: text.bodySmall?.copyWith(color: t.textSecondary),
                ),
              ],
            ),
          ),
          if (isCurrent)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: t.accentSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                l.statusTreeYouAreHere,
                style: GoogleFonts.nunito(
                  color: t.accentStrong,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
