import '../data/rhythm.dart';

class IncomeSource {
  String name;
  double amount;

  /// How often this income arrives (e.g. a bi-weekly salary, or a custom
  /// "every 3 weeks"). Null means it simply arrives once per budget cycle —
  /// the legacy behaviour, and what old persisted records decode to.
  Rhythm? frequency;

  IncomeSource({required this.name, required this.amount, this.frequency});

  /// This income expressed per one budget [cycle]: a $2000 salary arriving
  /// every 2 weeks counts as ~$4333 in a monthly budget. When either side is
  /// unknown (or they match) the raw amount passes through unchanged.
  double amountPerCycle(Rhythm? cycle) {
    final f = frequency;
    if (f == null || cycle == null || f == cycle) return amount;
    return amount * f.periodsPerMonth / cycle.periodsPerMonth;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': amount,
        'frequency': frequency?.toJson(),
      };

  factory IncomeSource.fromJson(Map<String, dynamic> j) => IncomeSource(
        name: j['name'] as String,
        amount: (j['amount'] as num).toDouble(),
        frequency: rhythmFromJson(j['frequency']),
      );
}

class ExpenseCategory {
  String name;
  double allocated;
  String emoji;
  List<String> linkedGoalIds;

  /// How often this expense is charged (e.g. monthly rent, or a custom
  /// "every 3 weeks"). Null means it simply recurs once per budget cycle —
  /// the legacy behaviour, and what old persisted records decode to.
  Rhythm? frequency;

  ExpenseCategory({
    required this.name,
    required this.allocated,
    required this.emoji,
    List<String>? linkedGoalIds,
    this.frequency,
  }) : linkedGoalIds = linkedGoalIds ?? [];

  /// This expense expressed per one budget [cycle]: $1200 rent charged
  /// monthly asks for ~$277 in a weekly budget — the amount to set aside
  /// each cycle so the bill is covered when it lands. When either side is
  /// unknown (or they match) the raw amount passes through unchanged.
  double allocatedPerCycle(Rhythm? cycle) {
    final f = frequency;
    if (f == null || cycle == null || f == cycle) return allocated;
    return allocated * f.periodsPerMonth / cycle.periodsPerMonth;
  }

  /// Set the allocation from a per-[cycle] figure (the inverse of
  /// [allocatedPerCycle]) — used when an AI plan hands back per-cycle
  /// amounts for an expense that carries its own rhythm.
  void setAllocatedPerCycle(double perCycle, Rhythm? cycle) {
    final f = frequency;
    if (f == null || cycle == null || f == cycle) {
      allocated = perCycle;
    } else {
      allocated = perCycle * cycle.periodsPerMonth / f.periodsPerMonth;
    }
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'allocated': allocated,
        'emoji': emoji,
        'linkedGoalIds': linkedGoalIds,
        'frequency': frequency?.toJson(),
      };

  factory ExpenseCategory.fromJson(Map<String, dynamic> j) => ExpenseCategory(
        name: j['name'] as String,
        allocated: (j['allocated'] as num).toDouble(),
        emoji: j['emoji'] as String,
        linkedGoalIds: (j['linkedGoalIds'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        frequency: rhythmFromJson(j['frequency']),
      );
}

class BudgetModel {
  String budgetName;
  List<IncomeSource> incomeSources;
  List<ExpenseCategory> expenses;
  int age;
  String location;
  final String id;
  DateTime? savedAt;
  String? categoryId;

  /// The budget's own cycle: every allocation and income figure is expressed
  /// per one of these periods. May be a preset or a custom interval.
  Rhythm? payFrequency;
  DateTime? firstPayDate;
  DateTime? lastProcessedAt;

  BudgetModel({
    required this.budgetName,
    required this.incomeSources,
    required this.expenses,
    this.age = 0,
    this.location = '',
    String? id,
    this.savedAt,
    this.categoryId,
    this.payFrequency,
    this.firstPayDate,
    this.lastProcessedAt,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  /// Total income per budget cycle: each source is normalised from its own
  /// arrival rhythm into [payFrequency], so allocations (which are per cycle)
  /// always compare against a like-for-like number.
  double get totalIncome =>
      incomeSources.fold(0.0, (s, e) => s + e.amountPerCycle(payFrequency));

  /// Total allocated per budget cycle: each expense is normalised from its
  /// own charge rhythm into [payFrequency], mirroring [totalIncome], so the
  /// two always compare like-for-like.
  double get totalAllocated =>
      expenses.fold(0.0, (s, e) => s + e.allocatedPerCycle(payFrequency));
  double get remaining => totalIncome - totalAllocated;

  double percentageFor(ExpenseCategory category) {
    if (totalIncome == 0) return 0;
    return (category.allocatedPerCycle(payFrequency) / totalIncome)
        .clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
        'budgetName': budgetName,
        'incomeSources': incomeSources.map((e) => e.toJson()).toList(),
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'age': age,
        'location': location,
        'id': id,
        'savedAt': savedAt?.millisecondsSinceEpoch,
        'categoryId': categoryId,
        'payFrequency': payFrequency?.toJson(),
        'firstPayDate': firstPayDate?.millisecondsSinceEpoch,
        'lastProcessedAt': lastProcessedAt?.millisecondsSinceEpoch,
      };

  factory BudgetModel.fromJson(Map<String, dynamic> json) => BudgetModel(
        budgetName: json['budgetName'] as String,
        incomeSources: (json['incomeSources'] as List)
            .map((e) => IncomeSource.fromJson(e as Map<String, dynamic>))
            .toList(),
        expenses: (json['expenses'] as List)
            .map((e) => ExpenseCategory.fromJson(e as Map<String, dynamic>))
            .toList(),
        age: (json['age'] as int?) ?? 0,
        location: (json['location'] as String?) ?? '',
        id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        savedAt: json['savedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['savedAt'] as int)
            : null,
        categoryId: json['categoryId'] as String?,
        payFrequency: rhythmFromJson(json['payFrequency']),
        firstPayDate: json['firstPayDate'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['firstPayDate'] as int)
            : null,
        lastProcessedAt: json['lastProcessedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                json['lastProcessedAt'] as int)
            : null,
      );
}
