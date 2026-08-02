// The questionnaire holds ~20 questions but only asks the ones that apply.
// These pin the branching rules so a follow-up can't start showing up for
// people it makes no sense for (childcare with no children, property upkeep
// for a renter).

import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app_project/l10n/survey_labels.dart';

Set<String> keysFor(Map<String, String> answers) =>
    visibleSurveyQuestions(answers).map((q) => q.key).toSet();

void main() {
  test('the bank holds about twenty questions', () {
    expect(budgetSurveyQuestions().length, greaterThanOrEqualTo(20));
  });

  test('every question key is unique', () {
    final keys = budgetSurveyQuestions().map((q) => q.key).toList();
    expect(keys.toSet().length, keys.length);
  });

  test('every question has at least two options with unique keys', () {
    for (final q in budgetSurveyQuestions()) {
      expect(q.options.length, greaterThanOrEqualTo(2), reason: q.key);
      final optKeys = q.options.map((o) => o.key).toList();
      expect(optKeys.toSet().length, optKeys.length, reason: q.key);
    }
  });

  group('a fresh survey', () {
    test('opens with only the unconditional questions', () {
      final keys = keysFor({});
      // The openers that apply to everyone.
      expect(keys, contains('household'));
      expect(keys, contains('kids'));
      expect(keys, contains('housing'));
      expect(keys, contains('commute'));
      expect(keys, contains('priority'));
      // Nothing conditional has been triggered yet.
      expect(keys, isNot(contains('childcare')));
      expect(keys, isNot(contains('rentShare')));
      expect(keys, isNot(contains('homeUpkeep')));
      expect(keys, isNot(contains('carCosts')));
      expect(keys, isNot(contains('debtType')));
      expect(keys, isNot(contains('incomeFloor')));
    });

    test('asks meaningfully fewer than the full bank', () {
      expect(
        keysFor({}).length,
        lessThan(budgetSurveyQuestions().length),
      );
    });
  });

  group('children', () {
    test('having children reveals childcare', () {
      expect(keysFor({'kids': 'one'}), contains('childcare'));
      expect(keysFor({'kids': 'twoThree'}), contains('childcare'));
    });

    test('no children keeps it hidden', () {
      expect(keysFor({'kids': 'none'}), isNot(contains('childcare')));
    });

    test('changing back to none retires it again', () {
      expect(
        keysFor({'kids': 'one', 'childcare': 'daycare'}),
        contains('childcare'),
      );
      expect(
        keysFor({'kids': 'none', 'childcare': 'daycare'}),
        isNot(contains('childcare')),
      );
    });
  });

  group('housing', () {
    test('renting asks about splitting rent, not upkeep', () {
      final keys = keysFor({'housing': 'rent'});
      expect(keys, contains('rentShare'));
      expect(keys, isNot(contains('homeUpkeep')));
    });

    test('owning asks about upkeep, not splitting rent', () {
      for (final mode in ['mortgage', 'owned']) {
        final keys = keysFor({'housing': mode});
        expect(keys, contains('homeUpkeep'), reason: mode);
        expect(keys, isNot(contains('rentShare')), reason: mode);
      }
    });

    test('living with family asks neither', () {
      final keys = keysFor({'housing': 'family'});
      expect(keys, isNot(contains('rentShare')));
      expect(keys, isNot(contains('homeUpkeep')));
    });
  });

  test('driving reveals the car cost follow-up', () {
    expect(keysFor({'commute': 'car'}), contains('carCosts'));
    expect(keysFor({'commute': 'transit'}), isNot(contains('carCosts')));
    expect(keysFor({'commute': 'remote'}), isNot(contains('carCosts')));
  });

  test('pets reveal the pet cost follow-up', () {
    expect(keysFor({'pets': 'one'}), contains('petCosts'));
    expect(keysFor({'pets': 'none'}), isNot(contains('petCosts')));
  });

  test('debt reveals what kind it is', () {
    expect(keysFor({'debt': 'some'}), contains('debtType'));
    expect(keysFor({'debt': 'lots'}), contains('debtType'));
    expect(keysFor({'debt': 'none'}), isNot(contains('debtType')));
  });

  test('unsteady income reveals how far it swings', () {
    expect(keysFor({'stability': 'varies'}), contains('incomeFloor'));
    expect(keysFor({'stability': 'unpredictable'}), contains('incomeFloor'));
    expect(keysFor({'stability': 'steady'}), isNot(contains('incomeFloor')));
  });

  test('health costs are asked once the household is big or has children', () {
    expect(keysFor({'kids': 'one'}), contains('healthCosts'));
    expect(keysFor({'household': 'threeFour'}), contains('healthCosts'));
    expect(keysFor({'household': 'fivePlus'}), contains('healthCosts'));
    expect(
      keysFor({'household': 'justMe', 'kids': 'none'}),
      isNot(contains('healthCosts')),
    );
  });

  test('a busy household sees more questions than someone living alone', () {
    final simple = keysFor({
      'household': 'justMe',
      'kids': 'none',
      'pets': 'none',
      'housing': 'family',
      'commute': 'remote',
      'debt': 'none',
      'stability': 'steady',
    });
    final busy = keysFor({
      'household': 'fivePlus',
      'kids': 'twoThree',
      'pets': 'several',
      'housing': 'mortgage',
      'commute': 'car',
      'debt': 'lots',
      'stability': 'unpredictable',
    });
    expect(busy.length, greaterThan(simple.length));
    // Even the busiest path stays inside the bank.
    expect(busy.length, lessThanOrEqualTo(budgetSurveyQuestions().length));
  });
}
