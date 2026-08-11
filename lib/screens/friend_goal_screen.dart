import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../l10n/goal_labels.dart';
import '../models/goal_model.dart';
import '../services/app_settings.dart';
import '../services/goal_likes_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/category_icons.dart';
import '../theme/leaf_palette.dart';
import '../widgets/sapling_view.dart';
import '../widgets/savings_thermometer.dart';
import '../widgets/ui/pressable.dart';

/// Read-only view of a friend's shared goal. It mirrors the layout of the
/// owner's [GoalDetailScreen] but has no deposit, edit, delete, or sharing
/// controls — a friend can watch the tree grow, never change it. (The Supabase
/// RLS policy also blocks writes server-side; this screen just never offers
/// them.) The sapling is drawn in the goal's saved tree colour. The one thing
/// a friend CAN do is cheer: the heart pill on the hero toggles their like and
/// shows the goal's like tally.
class FriendGoalScreen extends StatefulWidget {
  const FriendGoalScreen({
    super.key,
    required this.goal,
    required this.ownerLabel,
    this.ownerId,
  });

  final Goal goal;

  /// The friend's display name / username, shown in the header subtitle.
  final String ownerLabel;

  /// The goal owner's user id — needed for likes. Null (legacy caller) just
  /// hides the heart.
  final String? ownerId;

  @override
  State<FriendGoalScreen> createState() => _FriendGoalScreenState();
}

class _FriendGoalScreenState extends State<FriendGoalScreen> {
  Goal get goal => widget.goal;

  int _likeCount = 0;
  bool _liked = false;
  bool _likesReady = false;

  @override
  void initState() {
    super.initState();
    _loadLikes();
  }

  Future<void> _loadLikes() async {
    final owner = widget.ownerId;
    if (owner == null || !GoalLikesService.instance.isAvailable) return;
    try {
      final s = await GoalLikesService.instance.summary(owner, goal.id);
      if (!mounted) return;
      setState(() {
        _likeCount = s.count;
        _liked = s.mine;
        _likesReady = true;
      });
    } catch (_) {
      // Likes stay hidden; the goal view still works offline.
    }
  }

  /// Optimistic toggle: flip the heart instantly, then let the server catch
  /// up; reload (or roll back) if the write fails.
  Future<void> _toggleLike() async {
    final owner = widget.ownerId;
    if (owner == null || !_likesReady) return;
    final wasLiked = _liked;
    setState(() {
      _liked = !wasLiked;
      _likeCount += wasLiked ? -1 : 1;
    });
    try {
      if (wasLiked) {
        await GoalLikesService.instance.unlike(owner, goal.id);
      } else {
        await GoalLikesService.instance.like(owner, goal.id);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _liked = wasLiked;
          _likeCount += wasLiked ? 1 : -1;
        });
      }
    }
  }

  LeafPalette get _leafPalette => goal.leafColorValue != null
      ? LeafPalette.fromAccent(Color(goal.leafColorValue!))
      : LeafPalette.defaultGreen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final progress = goal.progress;
    final complete = goal.isCompleted;
    final ownerLabel = widget.ownerLabel;
    return Scaffold(
      // Laid out as a Column (mirroring the owner's GoalDetailScreen): header,
      // then the hero fills whatever space is left, then the info panel. No
      // absolute offsets — the old Positioned layout let the header/panel
      // overlap the sapling on smaller screens so only its lower half showed.
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header — back button + name + owner, no action icons.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTokens.current.canvasSoft,
                        border:
                            Border.all(color: AppTokens.current.cardBorder),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: AppTokens.current.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTokens.current.accentSoft,
                    ),
                    child: Icon(
                      GoalIcons.forKey(goal.iconKey),
                      color: AppTokens.current.accentStrong,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          goal.name,
                          style: GoogleFonts.pixelifySans(
                            fontWeight: FontWeight.w600,
                            color: AppTokens.current.textPrimary,
                            fontSize: 20,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          l.sharedByName(ownerLabel),
                          style: GoogleFonts.nunito(
                            color: AppTokens.current.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Hero: sapling centered in the clipped tinted card, thermometer
            // overlaid, exactly like the owner's view.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTokens.current.accentTint,
                          borderRadius: BorderRadius.zero,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Transform.scale(
                            scale: goal.isUncapped ? goal.tierScale : 1.0,
                            child: SaplingView(
                              progress: progress,
                              size: Size.infinite,
                              leafPalette: _leafPalette,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Heart pill: like toggle + tally, top-left of the hero.
                    if (_likesReady)
                      Positioned(
                        left: 12,
                        top: 16,
                        child: _LikePill(
                          liked: _liked,
                          count: _likeCount,
                          onTap: _toggleLike,
                        ),
                      ),
                    Positioned(
                      right: 12,
                      top: 16,
                      child: Column(
                        children: [
                          SavingsThermometer(
                            fill: progress,
                            color: complete
                                ? const Color(0xFFBA8514)
                                : (goal.leafColorValue != null
                                      ? Color(goal.leafColorValue!)
                                      : AppColors.forestGreen),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTokens.current.card,
                              borderRadius: BorderRadius.zero,
                              border: Border.all(
                                color: AppTokens.current.cardBorder,
                              ),
                            ),
                            child: Text(
                              goal.isUncapped
                                  ? 'T${goal.tier}'
                                  : '${(progress * 100).round()}%',
                              style: GoogleFonts.nunito(
                                color: AppTokens.current.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
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
            // Bottom info panel — read-only stats, no buttons.
            Container(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
              decoration: BoxDecoration(
                color: AppTokens.current.card,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.zero,
                ),
                border: Border.all(color: AppTokens.current.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 0,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.savedUpper,
                            style: GoogleFonts.nunito(
                              color: AppColors.mossGreen.withValues(alpha: 0.7),
                              fontSize: 10,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '\$${goal.currentAmount.toStringAsFixed(2)}',
                            style: GoogleFonts.pixelifySans(
                              fontWeight: FontWeight.w600,
                              color: complete
                                  ? const Color(0xFFBA8514)
                                  : AppColors.forestGreen,
                              fontSize: 30,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            goal.isUncapped ? l.tierUpper : l.targetUpper,
                            style: GoogleFonts.nunito(
                              color: AppColors.mossGreen.withValues(alpha: 0.7),
                              fontSize: 10,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            goal.isUncapped
                                ? '${goal.tier} · ${goal.localizedTierName(l)}'
                                : '\$${goal.targetAmount.toStringAsFixed(0)}',
                            style: GoogleFonts.nunito(
                              color: AppTokens.current.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.zero,
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 12,
                      backgroundColor: AppColors.soilMid,
                      valueColor: AlwaysStoppedAnimation(
                        complete
                            ? const Color(0xFFBA8514)
                            : AppColors.forestGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        goal.isUncapped
                            ? goal.localizedTierName(l)
                            : l.percentGrown((progress * 100).round()),
                        style: GoogleFonts.nunito(
                          color: AppColors.mossGreen,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        goal.isUncapped
                            ? l.noCapKeepsGrowing
                            : complete
                            ? l.goalReachedShort
                            : l.amountToGo(
                                '\$${goal.remaining.toStringAsFixed(2)}',
                              ),
                        style: GoogleFonts.nunito(
                          color: complete
                              ? const Color(0xFFBA8514)
                              : AppColors.mossGreen,
                          fontSize: 11,
                          fontWeight: complete
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The heart button + like tally. The heart pops (scale bounce) when toggled,
/// gated on reduced motion like every other micro-animation.
class _LikePill extends StatelessWidget {
  const _LikePill({
    required this.liked,
    required this.count,
    required this.onTap,
  });

  final bool liked;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = AppTokens.of(context);
    final motion = AppSettings.instance.motionFull;
    return Semantics(
      button: true,
      label: liked ? l.unlikeGoal : l.likeGoal,
      child: PressableScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: t.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: liked ? 1.15 : 1.0,
                duration: Duration(milliseconds: motion ? 240 : 0),
                curve: Curves.elasticOut,
                child: Icon(
                  liked ? Icons.favorite : Icons.favorite_border,
                  color: liked ? const Color(0xFFE0524D) : t.textSecondary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$count',
                style: GoogleFonts.nunito(
                  color: t.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
