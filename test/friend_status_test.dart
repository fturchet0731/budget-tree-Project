import 'package:budget_app_project/models/goal_model.dart';
import 'package:budget_app_project/models/profile_model.dart';
import 'package:budget_app_project/services/friend_status.dart';
import 'package:flutter_test/flutter_test.dart';

/// A capped goal whose `progress` is exactly [p] (currentAmount / targetAmount).
Goal goalAt(double p, {String? id}) =>
    Goal(id: id, name: 'g', targetAmount: 100, currentAmount: p * 100);

void main() {
  group('emojiForScore ramp', () {
    test('barely-funded reads as a skull', () {
      expect(FriendStatus.emojiForScore(0.0), '💀');
      expect(FriendStatus.emojiForScore(0.24), '💀');
    });
    test('mid ranges', () {
      expect(FriendStatus.emojiForScore(0.25), '😬');
      expect(FriendStatus.emojiForScore(0.49), '😬');
      expect(FriendStatus.emojiForScore(0.50), '🙂');
      expect(FriendStatus.emojiForScore(0.74), '🙂');
    });
    test('75% or more is cool', () {
      expect(FriendStatus.emojiForScore(0.75), '😎');
      expect(FriendStatus.emojiForScore(1.0), '😎');
    });
  });

  group('scoreFor reduces by mode', () {
    final goals = [goalAt(0.1, id: 'a'), goalAt(0.8, id: 'b')];

    test('best takes the most-complete goal', () {
      expect(FriendStatus.scoreFor(goals, FriendStatusMode.best), 0.8);
    });
    test('worst takes the least-complete goal', () {
      expect(FriendStatus.scoreFor(goals, FriendStatusMode.worst), 0.1);
    });
    test('average blends them', () {
      expect(
        FriendStatus.scoreFor(goals, FriendStatusMode.average),
        closeTo(0.45, 1e-9),
      );
    });
    test('goal mode pins to the chosen shared goal', () {
      expect(
        FriendStatus.scoreFor(goals, FriendStatusMode.goal, goalId: 'b'),
        0.8,
      );
    });
    test('goal mode returns null when the pinned goal is not shared', () {
      expect(
        FriendStatus.scoreFor(goals, FriendStatusMode.goal, goalId: 'missing'),
        isNull,
      );
    });
  });

  group('emojiFor end to end', () {
    test('no shared goals reads as the sleeping face', () {
      expect(FriendStatus.emojiFor(const [], FriendStatusMode.best),
          FriendStatus.noGoalsEmoji);
    });
    test('best of a thriving goal is cool', () {
      final goals = [goalAt(0.2), goalAt(0.9)];
      expect(FriendStatus.emojiFor(goals, FriendStatusMode.best), '😎');
    });
    test('worst of a struggling goal is a skull', () {
      final goals = [goalAt(0.05), goalAt(0.9)];
      expect(FriendStatus.emojiFor(goals, FriendStatusMode.worst), '💀');
    });
  });
}
