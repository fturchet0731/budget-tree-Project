import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../l10n/goal_labels.dart';
import '../models/goal_model.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
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
          Positioned(
            left: 16,
            right: 16,
            top: 88,
            bottom: 250,
            child: Container(
              decoration: BoxDecoration(
                color: AppTokens.current.accentTint,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
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
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTokens.current.cardBorder),
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
                        color: AppTokens.current.canvasSoft,
                        shape: BoxShape.circle,
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
                      shape: BoxShape.circle,
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
                          style: GoogleFonts.fredoka(
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
          ),
          // Bottom info panel — read-only stats, no buttons.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
              decoration: BoxDecoration(
                color: AppTokens.current.card,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border.all(color: AppTokens.current.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
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
                            style: GoogleFonts.fredoka(
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
                    borderRadius: BorderRadius.circular(8),
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
          ),
        ],
      ),
    );
  }
}
