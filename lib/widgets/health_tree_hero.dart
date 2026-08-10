import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/tree_health_labels.dart';
import '../models/check_in.dart';
import '../services/check_in_service.dart';
import '../services/profile_service.dart';
import '../services/tree_health_service.dart';
import '../theme/app_dims.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import 'check_in_sheet.dart';
import 'pixel/pixel.dart';
import 'status_tree_view.dart';

/// The dashboard's living tree: how consistent the user has been, at a glance,
/// and the way into Acorn's Hub.
///
/// Sits as a full-width fifth tile under the four-leaf menu.
///
/// Two nested tap targets. The scene itself opens the hub; the strip along the
/// bottom opens whatever needs doing right now, which is usually a check-in.
/// The inner target is nested inside the outer one rather than sitting beside
/// it, so a tap on the strip is never swallowed by the card.
class HealthTreeHero extends StatefulWidget {
  final double height;
  final VoidCallback onOpenHub;

  const HealthTreeHero({
    super.key,
    required this.height,
    required this.onOpenHub,
  });

  @override
  State<HealthTreeHero> createState() => HealthTreeHeroState();
}

class HealthTreeHeroState extends State<HealthTreeHero> {
  TreeHealth _health = TreeHealth.fresh;
  List<CheckIn> _pending = const [];

  @override
  void initState() {
    super.initState();
    refresh();
  }

  /// Reload from the ledger. The dashboard calls this after any navigation that
  /// could have answered a check-in.
  Future<void> refresh() async {
    final health = await TreeHealthService.current();
    final pending = await CheckInService.pending();
    if (!mounted) return;
    setState(() {
      _health = health;
      _pending = pending;
    });
    // Publish it so friends see the same tree in your garden. Throttled and
    // change-gated inside the service, and best-effort throughout.
    if (!health.isEmpty) {
      ProfileService.instance.publishHealthScore(health.score.round());
    }
  }

  Future<void> _answer() async {
    if (_pending.isEmpty) return;
    final saved = await showCheckInSheet(context, _pending.first);
    if (!mounted) return;
    if (saved) {
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.checkInSaved)));
    }
    await refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = AppTokens.of(context);
    // The tree takes the room left over once the caption strip has its share.
    final treeSize = (widget.height - 62).clamp(70.0, 150.0);

    // The save-file summary tile: the living tree, an HP-style score meter,
    // and the check-in call to action along the bottom edge.
    return PixelBox(
      onTap: widget.onOpenHub,
      fill: t.accentTint,
      padding: EdgeInsets.zero,
      height: widget.height,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                const SizedBox(width: AppDims.s8),
                StatusTreeView(
                  spriteKey: _health.spriteKey,
                  size: treeSize,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 11, 0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _health.isEmpty
                              ? l.hubTitle.toUpperCase()
                              : '${l.hubTitle.toUpperCase()} · '
                                  'LV.${_health.score.round()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              AppTheme.label(9, t.accentStrong, spacing: 1.5),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          (_health.isEmpty
                                  ? l.hubTreeFresh
                                  : _health.statusLabel(l))
                              .toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 5),
                        // The HP bar: consistency score out of 100.
                        PixelBar(
                          value: _health.isEmpty ? 0 : _health.score / 100,
                          height: 12,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _subtitle(l),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _HeroStrip(
            pending: _pending.length,
            subject: _pending.isEmpty ? null : _pending.first.subjectName,
            onAnswer: _answer,
            onOpenHub: widget.onOpenHub,
          ),
        ],
      ),
    );
  }

  String _subtitle(AppLocalizations l) {
    if (_health.isEmpty) return l.hubTreeFreshSub;
    if (_health.showsPrestige && _health.prestigeDays >= 1) {
      return l.hubPrestigeDays(_health.prestigeDays.floor());
    }
    if (_health.currentStreak > 0) {
      return l.hubStreakSub(_health.currentStreak);
    }
    if (_health.missedRecent > 0) return l.hubMissedSub(_health.missedRecent);
    return l.hubScoreSub(_health.score.round());
  }
}

/// The call to action along the bottom edge: answer a waiting check-in, or,
/// when there is nothing owing, an invitation into the hub.
class _HeroStrip extends StatelessWidget {
  final int pending;
  final String? subject;
  final VoidCallback onAnswer;
  final VoidCallback onOpenHub;

  const _HeroStrip({
    required this.pending,
    required this.subject,
    required this.onAnswer,
    required this.onOpenHub,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = AppTokens.of(context);
    final waiting = pending > 0;

    // A green quest strip along the bottom edge, separated from the tile body
    // by a hard ink rule. Nested inside the tile's own tap target, so the
    // strip answers the check-in and the card opens the hub.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: waiting ? onAnswer : onOpenHub,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: waiting ? t.accent : t.canvasSoft,
          border: Border(top: BorderSide(color: t.cardBorder, width: 3)),
        ),
        child: Row(
          children: [
            PixelSprite(
              asset: waiting ? PixelIcons.scroll : PixelIcons.star,
              size: 16,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                (waiting
                        ? (pending > 1
                            ? l.hubAnswerMany(pending)
                            : l.hubAnswerOne(subject ?? ''))
                        : l.hubOpenPrompt)
                    .toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.label(
                  9,
                  waiting ? t.inkDeep : t.textSecondary,
                  spacing: 0.5,
                ),
              ),
            ),
            Text(
              '▶',
              style: AppTheme.label(
                  10, waiting ? t.inkDeep : t.textTertiary, spacing: 0),
            ),
          ],
        ),
      ),
    );
  }
}
