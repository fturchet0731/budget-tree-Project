import '../models/budget_model.dart';
import 'budget_repository.dart';

/// Income sources and expense branches the user has already entered on an
/// earlier tree, offered for one-tap reuse when planting the next one.
///
/// Derived from the saved budgets rather than stored separately: there's no
/// new table, no sync path and nothing to keep in step — if a tree exists, its
/// roots and branches are reusable. Entries are de-duplicated by name (case
/// insensitive), most recently saved first, so the list stays short and the
/// newest amount wins.
class SavedEntries {
  SavedEntries._();

  /// Distinct income sources from previous trees, newest first.
  static Future<List<IncomeSource>> incomes({int limit = 12}) async {
    final budgets = await _savedNewestFirst();
    final seen = <String>{};
    final out = <IncomeSource>[];
    for (final b in budgets) {
      for (final s in b.incomeSources) {
        final key = s.name.trim().toLowerCase();
        if (key.isEmpty || !seen.add(key)) continue;
        // Copy: the wizard mutates what the user picks, and these objects are
        // still owned by the saved budget.
        out.add(IncomeSource(
          name: s.name,
          amount: s.amount,
          frequency: s.frequency,
        ));
        if (out.length >= limit) return out;
      }
    }
    return out;
  }

  /// Distinct expense branches from previous trees, newest first. Linked goal
  /// ids are deliberately dropped — those belong to the tree they came from.
  static Future<List<ExpenseCategory>> expenses({int limit = 12}) async {
    final budgets = await _savedNewestFirst();
    final seen = <String>{};
    final out = <ExpenseCategory>[];
    for (final b in budgets) {
      for (final e in b.expenses) {
        final key = e.name.trim().toLowerCase();
        if (key.isEmpty || !seen.add(key)) continue;
        out.add(ExpenseCategory(
          name: e.name,
          allocated: e.allocated,
          emoji: e.emoji,
          frequency: e.frequency,
        ));
        if (out.length >= limit) return out;
      }
    }
    return out;
  }

  static Future<List<BudgetModel>> _savedNewestFirst() async {
    final budgets = await BudgetRepository.loadAll();
    final saved = budgets.where((b) => b.savedAt != null).toList()
      ..sort((a, b) => b.savedAt!.compareTo(a.savedAt!));
    return saved;
  }
}
