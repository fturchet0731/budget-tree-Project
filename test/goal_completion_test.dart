import 'package:budget_app_project/models/goal_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('durable goal completion', () {
    test('a fresh capped goal is not completed', () {
      final g = Goal(name: 'g', targetAmount: 100);
      expect(g.isComplete, isFalse);
      expect(g.isCompleted, isFalse);
      expect(g.completedAt, isNull);
    });

    test('reaching the target stamps completion once', () {
      final g = Goal(name: 'g', targetAmount: 100);
      g.applyContribution(100);
      expect(g.isComplete, isTrue);

      expect(g.stampCompletionIfReached(), isTrue); // newly completed
      expect(g.isCompleted, isTrue);
      final firstStamp = g.completedAt;
      expect(firstStamp, isNotNull);

      // Idempotent: a second call doesn't re-stamp or report a new completion.
      expect(g.stampCompletionIfReached(), isFalse);
      expect(g.completedAt, firstStamp);
    });

    test('completion is permanent — withdrawing below target keeps it', () {
      final g = Goal(name: 'g', targetAmount: 100);
      g.applyContribution(100);
      g.stampCompletionIfReached();

      g.applyContribution(-80); // balance now 20, below target
      expect(g.isComplete, isFalse); // not currently full
      expect(g.isCompleted, isTrue); // but still a completed trophy
      expect(g.completedAt, isNotNull);
    });

    test('uncapped goals never complete', () {
      final g = Goal(name: 'forever', targetAmount: 0);
      g.applyContribution(999999);
      expect(g.isUncapped, isTrue);
      expect(g.isComplete, isFalse);
      expect(g.stampCompletionIfReached(), isFalse);
      expect(g.isCompleted, isFalse);
    });
  });
}
