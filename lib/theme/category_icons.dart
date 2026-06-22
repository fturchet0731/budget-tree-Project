import 'package:flutter/material.dart';

/// Maps expense category icon keys (stored in ExpenseCategory.emoji) to
/// Material icon data. Keys are plain strings like 'home', 'food', etc.
class CategoryIcons {
  CategoryIcons._();

  static const Map<String, IconData> _map = {
    'home': Icons.home_outlined,
    'food': Icons.restaurant_outlined,
    'transport': Icons.directions_car_outlined,
    'savings': Icons.savings_outlined,
    'entertainment': Icons.movie_outlined,
    'subscriptions': Icons.receipt_long_outlined,
    'healthcare': Icons.local_hospital_outlined,
    'personal': Icons.person_outlined,
    'other': Icons.category_outlined,
  };

  static IconData forKey(String key) => _map[key] ?? Icons.category_outlined;
}

/// Icons for goal categories (used in Goals/Grove screens).
class GoalIcons {
  GoalIcons._();

  static const List<(String, String, IconData)> presets = [
    ('savings', 'Savings', Icons.savings_outlined),
    ('travel', 'Travel', Icons.flight_takeoff_outlined),
    ('vehicle', 'Vehicle', Icons.directions_car_outlined),
    ('home', 'Home', Icons.home_outlined),
    ('education', 'Education', Icons.school_outlined),
    ('wedding', 'Wedding', Icons.favorite_outline),
    ('emergency', 'Emergency', Icons.health_and_safety_outlined),
    ('tech', 'Tech', Icons.devices_outlined),
    ('gift', 'Gift', Icons.card_giftcard_outlined),
    ('other', 'Other', Icons.stars_outlined),
  ];

  static IconData forKey(String key) {
    for (final p in presets) {
      if (p.$1 == key) return p.$3;
    }
    return Icons.stars_outlined;
  }
}
