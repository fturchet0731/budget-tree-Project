import 'package:flutter/material.dart';

/// Aggregate facts about the user's progress, fed to each achievement's
/// unlock test. Computed once per evaluation pass by the AchievementService.
class AchievementStats {
  final int budgetCount;
  final int goalCount;
  final int depositCount;
  final int completedGoals;
  final double totalSaved;
  final int maxTier;
  final int bestStreakWeeks;

  const AchievementStats({
    required this.budgetCount,
    required this.goalCount,
    required this.depositCount,
    required this.completedGoals,
    required this.totalSaved,
    required this.maxTier,
    required this.bestStreakWeeks,
  });
}

/// A badge the user can earn. [test] decides whether the current
/// [AchievementStats] qualify; once true it never re-locks.
class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color tint;
  final bool Function(AchievementStats) test;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.tint,
    required this.test,
  });
}

/// The full badge catalog, ordered from easiest to hardest. Add new badges
/// here — the service and UI pick them up automatically.
class AchievementCatalog {
  AchievementCatalog._();

  static const _bronze = Color(0xFFCD8B5E);
  static const _green = Color(0xFF8BC34A);
  static const _gold = Color(0xFFFFD54F);

  static final List<Achievement> all = [
    Achievement(
      id: 'first_sprout',
      title: 'First Sprout',
      description: 'Plant your first budget tree.',
      icon: Icons.park,
      tint: _green,
      test: (s) => s.budgetCount >= 1,
    ),
    Achievement(
      id: 'first_sapling',
      title: 'First Sapling',
      description: 'Create your first savings goal.',
      icon: Icons.eco,
      tint: _green,
      test: (s) => s.goalCount >= 1,
    ),
    Achievement(
      id: 'first_drop',
      title: 'First Drop',
      description: 'Make your first deposit toward a goal.',
      icon: Icons.water_drop,
      tint: _bronze,
      test: (s) => s.depositCount >= 1,
    ),
    Achievement(
      id: 'orchard_keeper',
      title: 'Orchard Keeper',
      description: 'Tend three goals at once.',
      icon: Icons.forest,
      tint: _green,
      test: (s) => s.goalCount >= 3,
    ),
    Achievement(
      id: 'green_thumb',
      title: 'Green Thumb',
      description: 'Save \$1,000 across your grove.',
      icon: Icons.savings,
      tint: _bronze,
      test: (s) => s.totalSaved >= 1000,
    ),
    Achievement(
      id: 'consistent',
      title: 'Consistent',
      description: 'Reach a 3-week saving streak.',
      icon: Icons.local_fire_department,
      tint: _bronze,
      test: (s) => s.bestStreakWeeks >= 3,
    ),
    Achievement(
      id: 'first_harvest',
      title: 'First Harvest',
      description: 'Complete a savings goal.',
      icon: Icons.emoji_events,
      tint: _gold,
      test: (s) => s.completedGoals >= 1,
    ),
    Achievement(
      id: 'devoted',
      title: 'Devoted',
      description: 'Reach an 8-week saving streak.',
      icon: Icons.whatshot,
      tint: _gold,
      test: (s) => s.bestStreakWeeks >= 8,
    ),
    Achievement(
      id: 'mighty_oak',
      title: 'Mighty Oak',
      description: 'Grow a goal to Tier 5 or beyond.',
      icon: Icons.nature,
      tint: _gold,
      test: (s) => s.maxTier >= 5,
    ),
    Achievement(
      id: 'old_growth',
      title: 'Old-Growth Forest',
      description: 'Save \$10,000 across your grove.',
      icon: Icons.workspace_premium,
      tint: _gold,
      test: (s) => s.totalSaved >= 10000,
    ),
  ];

  static Achievement? byId(String id) {
    for (final a in all) {
      if (a.id == id) return a;
    }
    return null;
  }
}
