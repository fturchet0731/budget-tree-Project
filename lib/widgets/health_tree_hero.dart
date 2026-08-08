import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../l10n/tree_health_labels.dart';
import '../models/check_in.dart';
import '../services/check_in_service.dart';
import '../services/profile_service.dart';
import '../services/tree_health_service.dart';
import '../theme/app_dims.dart';
import '../theme/app_shadows.dart';
import '../theme/app_tokens.dart';
import 'check_in_sheet.dart';
import 'health_tree_view.dart';
import 'ui/pressable.dart';

/// The dashboard's living tree: how consistent the user has been, at a glance,
/// and the way into Acorn's Hub.
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

    return PressableScale(
      onTap: widget.onOpenHub,
      pressedScale: 0.985,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: t.accentTint,
          borderRadius: BorderRadius.circular(AppDims.rCard),
          border: Border.all(color: t.cardBorder),
          boxShadow: AppShadows.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  const SizedBox(width: AppDims.s8),
                  HealthTreeView(
                    health: _health.fraction,
                    size: treeSize,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: AppDims.s16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.hubTitle.toUpperCase(),
                            style: GoogleFonts.nunito(
                              color: t.accentStrong,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _health.isEmpty
                                ? l.hubTreeFresh
                                : _health.tier.label(l),
                            // One line each: on a small phone the hero is only
                            // ~130px tall, and a two-line tier name plus a
                            // two-line subtitle overflows the slot.
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(height: 1.15),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _subtitle(l),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: AppDims.s12),
                    child: Icon(
                      Icons.chevron_right,
                      color: t.textTertiary,
                      size: 20,
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
      ),
    );
  }

  String _subtitle(AppLocalizations l) {
    if (_health.isEmpty) return l.hubTreeFreshSub;
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

    return PressableScale(
      onTap: waiting ? onAnswer : onOpenHub,
      pressedScale: 0.99,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        color: waiting ? t.accent : t.canvasSoft,
        child: Row(
          children: [
            Icon(
              waiting ? Icons.event_available : Icons.auto_awesome,
              size: 15,
              color: waiting ? t.onAccent : t.accentStrong,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                waiting
                    ? (pending > 1
                        ? l.hubAnswerMany(pending)
                        : l.hubAnswerOne(subject ?? ''))
                    : l.hubOpenPrompt,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                  color: waiting ? t.onAccent : t.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
