import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/achievement.dart';
import '../services/achievement_service.dart';
import '../theme/app_theme.dart';
import 'celebration_overlay.dart';

/// Present a celebration overlay for each freshly-unlocked badge, one after
/// another. Call this after [AchievementService.evaluateAndUnlock] returns a
/// non-empty list so the user actually sees what they earned.
Future<void> presentNewAchievements(
    BuildContext context, List<Achievement> earned) async {
  for (final a in earned) {
    if (!context.mounted) return;
    await showCelebration(
      context,
      title: 'Badge Unlocked!',
      message: '${a.title} — ${a.description}',
      icon: a.icon,
      color: a.tint,
      buttonLabel: 'Nice!',
    );
  }
}

/// Bottom sheet showing the full badge catalog: earned ones in colour,
/// locked ones dimmed with a padlock and the unlock hint.
Future<void> showAchievementsSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AchievementsSheet(),
  );
}

class _AchievementsSheet extends StatelessWidget {
  const _AchievementsSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D2010),
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: FutureBuilder<Map<String, DateTime>>(
          future: AchievementService.loadUnlocked(),
          builder: (ctx, snap) {
            final unlocked = snap.data ?? const {};
            final earnedCount = unlocked.length;
            final total = AchievementCatalog.all.length;
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.mossGreen.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Badges',
                    style: GoogleFonts.fredoka(
                        fontWeight: FontWeight.w600,
                        color: AppColors.stoneBeigeColor,
                        fontSize: 22)),
                const SizedBox(height: 2),
                Text('$earnedCount of $total earned',
                    style: GoogleFonts.nunito(
                        color: AppColors.mossGreen, fontSize: 13)),
                const SizedBox(height: 14),
                Expanded(
                  child: GridView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.45,
                    ),
                    itemCount: AchievementCatalog.all.length,
                    itemBuilder: (ctx, i) {
                      final a = AchievementCatalog.all[i];
                      return _BadgeTile(
                        achievement: a,
                        earned: unlocked.containsKey(a.id),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final Achievement achievement;
  final bool earned;
  const _BadgeTile({required this.achievement, required this.earned});

  @override
  Widget build(BuildContext context) {
    final tint = achievement.tint;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: earned
            ? tint.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: earned
              ? tint.withValues(alpha: 0.55)
              : AppColors.mossGreen.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: earned
                      ? tint.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.2),
                ),
                child: Icon(
                  earned ? achievement.icon : Icons.lock_outline,
                  color: earned
                      ? tint
                      : AppColors.mossGreen.withValues(alpha: 0.5),
                  size: 20,
                ),
              ),
              const Spacer(),
              if (earned)
                Icon(Icons.check_circle, color: tint, size: 16),
            ],
          ),
          const Spacer(),
          Text(
            achievement.title,
            style: GoogleFonts.nunito(
              color: earned
                  ? AppColors.stoneBeigeColor
                  : AppColors.mossGreen.withValues(alpha: 0.7),
              fontWeight: FontWeight.bold,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            achievement.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
              color: AppColors.mossGreen.withValues(alpha: earned ? 0.85 : 0.55),
              fontSize: 11,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
