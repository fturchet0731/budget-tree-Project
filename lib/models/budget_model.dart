import '../data/pay_frequency.dart';

class IncomeSource {
  String name;
  double amount;

  IncomeSource({required this.name, required this.amount});

  Map<String, dynamic> toJson() => {'name': name, 'amount': amount};

  factory IncomeSource.fromJson(Map<String, dynamic> j) =>
      IncomeSource(name: j['name'] as String, amount: (j['amount'] as num).toDouble());
}

class ExpenseCategory {
  String name;
  double allocated;
  String emoji;
  List<String> linkedGoalIds;

  ExpenseCategory({
    required this.name,
    required this.allocated,
    required this.emoji,
    List<String>? linkedGoalIds,
  }) : linkedGoalIds = linkedGoalIds ?? [];

  Map<String, dynamic> toJson() => {
        'name': name,
        'allocated': allocated,
        'emoji': emoji,
        'linkedGoalIds': linkedGoalIds,
      };

  factory ExpenseCategory.fromJson(Map<String, dynamic> j) => ExpenseCategory(
        name: j['name'] as String,
        allocated: (j['allocated'] as num).toDouble(),
        emoji: j['emoji'] as String,
        linkedGoalIds: (j['linkedGoalIds'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
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
  PayFrequency? payFrequency;
  DateTime? firstPayDate;
  DateTime? lastProcessedAt;

  BudgetModel({
    required this.budgetName,
    required this.incomeSources,
    required this.expenses,
    required this.age,
    required this.location,
    String? id,
    this.savedAt,
    this.categoryId,
    this.payFrequency,
    this.firstPayDate,
    this.lastProcessedAt,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  double get totalIncome => incomeSources.fold(0.0, (s, e) => s + e.amount);
  double get totalAllocated => expenses.fold(0.0, (s, e) => s + e.allocated);
  double get remaining => totalIncome - totalAllocated;

  double percentageFor(ExpenseCategory category) {
    if (totalIncome == 0) return 0;
    return (category.allocated / totalIncome).clamp(0.0, 1.0);
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
        'payFrequency': payFrequency?.index,
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
        age: json['age'] as int,
        location: json['location'] as String,
        id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        savedAt: json['savedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['savedAt'] as int)
            : null,
        categoryId: json['categoryId'] as String?,
        payFrequency: payFrequencyFromIndex(json['payFrequency'] as int?),
        firstPayDate: json['firstPayDate'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['firstPayDate'] as int)
            : null,
        lastProcessedAt: json['lastProcessedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                json['lastProcessedAt'] as int)
            : null,
      );
}
