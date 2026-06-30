import '../data/water_cadence.dart';

// Data shapes exchanged with the `ai-coach` edge function. The function
// returns strict JSON; these parse it defensively so a malformed field never
// crashes the UI (callers degrade to the manual flow on a thrown error).

/// An expense the user declared, with an optional fixed amount. Amount 0 means
/// "the user hasn't decided, let the coach choose"; a positive amount is a fixed
/// value the coach must keep. Sent to the `budget_plans` action.
class BudgetExpenseInput {
  final String name;
  final double amount;
  const BudgetExpenseInput({required this.name, this.amount = 0});

  Map<String, dynamic> toJson() => {'name': name, 'amount': amount};
}

/// One line of an allocation plan: a category and the dollars assigned to it.
class PlanItem {
  final String name;
  final double amount;
  const PlanItem({required this.name, required this.amount});

  factory PlanItem.fromJson(Map<String, dynamic> j) => PlanItem(
    name: (j['name'] as String?) ?? '',
    amount: ((j['amount'] as num?) ?? 0).toDouble(),
  );
}

/// A complete way to split income across the declared expenses, with whatever
/// is left over earmarked for savings/goals, plus a one-line rationale.
class AllocationPlan {
  final String name;
  final List<PlanItem> items;
  final double leftover;
  final String rationale;

  const AllocationPlan({
    required this.name,
    required this.items,
    required this.leftover,
    required this.rationale,
  });

  factory AllocationPlan.fromJson(Map<String, dynamic> j) => AllocationPlan(
    name: (j['name'] as String?) ?? '',
    items: ((j['items'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(PlanItem.fromJson)
        .toList(),
    leftover: ((j['leftover'] as num?) ?? 0).toDouble(),
    rationale: (j['rationale'] as String?) ?? '',
  );

  static List<AllocationPlan> listFrom(Map<String, dynamic> j) =>
      ((j['plans'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AllocationPlan.fromJson)
          .toList();
}

/// One "watering" plan for a goal: contribute [perWatering] every [cadence]
/// (e.g. $100 every two weeks) for roughly [monthsToTarget] months. The AI may
/// return either a [perWatering] + cadence directly or just a legacy monthly
/// figure; parsing fills in whichever is missing so older responses still work.
class GoalPlanOption {
  final WaterCadence cadence;
  final double perWatering;
  final int monthsToTarget;
  final String rationale;

  const GoalPlanOption({
    required this.cadence,
    required this.perWatering,
    required this.monthsToTarget,
    required this.rationale,
  });

  /// Equivalent monthly contribution this plan implies.
  double get monthly => perWatering * cadence.perMonth;

  factory GoalPlanOption.fromJson(Map<String, dynamic> j) {
    final cadence = waterCadenceFromWire(j['cadence'] as String?);
    final per = (j['perWatering'] as num?)?.toDouble();
    final monthly = (j['monthly'] as num?)?.toDouble();
    // Prefer an explicit per-watering amount; otherwise split the monthly
    // figure across the cadence's waterings-per-month.
    final perWatering = per ??
        (monthly != null ? monthly / cadence.perMonth : 0.0);
    return GoalPlanOption(
      cadence: cadence,
      perWatering: perWatering,
      monthsToTarget: ((j['monthsToTarget'] as num?) ?? 0).round(),
      rationale: (j['rationale'] as String?) ?? '',
    );
  }
}

/// An alternative completion date the AI suggests because it fits the user's
/// free income better than their requested date.
class AltDate {
  final DateTime date;
  final double monthly;
  final String note;

  const AltDate({
    required this.date,
    required this.monthly,
    required this.note,
  });

  factory AltDate.fromJson(Map<String, dynamic> j) {
    final monthly = (j['monthly'] as num?)?.toDouble();
    final per = (j['perWatering'] as num?)?.toDouble();
    final cadence = waterCadenceFromWire(j['cadence'] as String?);
    return AltDate(
      date:
          DateTime.tryParse((j['isoDate'] as String?) ?? '') ?? DateTime.now(),
      monthly: monthly ?? (per != null ? per * cadence.perMonth : 0.0),
      note: (j['note'] as String?) ?? '',
    );
  }
}

/// Combined result of the `goal_plans` action.
class GoalPlanResult {
  final List<GoalPlanOption> plans;
  final List<AltDate> alternativeDates;

  const GoalPlanResult({required this.plans, required this.alternativeDates});

  factory GoalPlanResult.fromJson(Map<String, dynamic> j) => GoalPlanResult(
    plans: ((j['plans'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(GoalPlanOption.fromJson)
        .toList(),
    alternativeDates: ((j['alternativeDates'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(AltDate.fromJson)
        .toList(),
  );
}
