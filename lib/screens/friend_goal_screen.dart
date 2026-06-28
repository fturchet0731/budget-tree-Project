import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../l10n/goal_labels.dart';
import '../models/goal_model.dart';
import '../theme/app_theme.dart';
import '../theme/category_icons.dart';
import '../theme/leaf_palette.dart';
import '../widgets/sapling_view.dart';
import '../widgets/savings_thermometer.dart';

/// Read-only view of a friend's shared goal. It mirrors the layout of the
/// owner's [GoalDetailScreen] but has no deposit, edit, delete, or sharing
/// controls — a friend can watch the tree grow, never change it. (The Supabase
/// RLS policy also blocks writes server-side; this screen just never offers
/// them.) The sapling is drawn in the goal's saved tree colour.
class FriendGoalScreen extends StatelessWidget {
  const FriendGoalScreen({
    super.key,
    required this.goal,
    required this.ownerLabel,
  });

  final Goal goal;

  /// The friend's display name / username, shown in the header subtitle.
  final String ownerLabel;

  LeafPalette get _leafPalette => goal.leafColorValue != null
      ? LeafPalette.fromAccent(Color(goal.leafColorValue!))
      : LeafPalette.defaultGreen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final progress = goal.progress;
    final complete = goal.isCompleted;
    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: BoxDecoration(gradient: AppPalettes.sky())),
          // Sapling — uncapped goals scale up per tier, matching the owner view.
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 96, 0, 230),
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
          // Thermometer gauge mirroring the sapling growth.
          Positioned(
            right: 16,
            top: 150,
            child: Column(
              children: [
                SavingsThermometer(
                  fill: progress,
                  color: complete
                      ? const Color(0xFFFFD54F)
                      : (goal.leafColorValue != null
                            ? Color(goal.leafColorValue!)
                            : AppColors.lightLeaf),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    goal.isUncapped
                        ? 'T${goal.tier}'
                        : '${(progress * 100).round()}%',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Header — back button + name + owner, no action icons.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      GoalIcons.forKey(goal.iconKey),
                      color: Colors.white,
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
                          style: GoogleFonts.fredoka(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontSize: 20,
                            shadows: const [
                              Shadow(
                                color: Colors.black54,
                                offset: Offset(1, 2),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          l.sharedByName(ownerLabel),
                          style: GoogleFonts.nunito(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
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
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF0D2010).withValues(alpha: 0.85),
                    const Color(0xFF0D2010),
                  ],
                  stops: const [0.0, 0.3, 1.0],
                ),
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
                            style: GoogleFonts.fredoka(
                              fontWeight: FontWeight.w600,
                              color: complete
                                  ? const Color(0xFFFFD54F)
                                  : AppColors.lightLeaf,
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
                              color: Colors.white.withValues(alpha: 0.85),
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
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 12,
                      backgroundColor: AppColors.soilMid,
                      valueColor: AlwaysStoppedAnimation(
                        complete
                            ? const Color(0xFFFFD54F)
                            : AppColors.lightLeaf,
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
                              ? const Color(0xFFFFD54F)
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
          ),
        ],
      ),
    );
  }
}
