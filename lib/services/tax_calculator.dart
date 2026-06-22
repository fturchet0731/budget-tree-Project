import 'dart:math' as math;
import '../data/tax_data.dart';

/// Aggregated estimate returned by [TaxCalculator.estimate].
class TaxEstimate {
  final Jurisdiction? jurisdiction;
  final double annualGross;
  final double annualNet;
  final double annualTax;
  final double monthlyGross;
  final double monthlyNet;
  final double effectiveRate;
  final double marginalRate;

  const TaxEstimate({
    required this.jurisdiction,
    required this.annualGross,
    required this.annualNet,
    required this.annualTax,
    required this.monthlyGross,
    required this.monthlyNet,
    required this.effectiveRate,
    required this.marginalRate,
  });

  bool get hasData => jurisdiction != null && annualGross > 0;
}

class TaxCalculator {
  TaxCalculator._();

  /// Returns a [TaxEstimate] for the given monthly gross income and
  /// location string (province name, state name, or code).
  static TaxEstimate estimate({
    required double monthlyGross,
    required String? location,
  }) {
    final j = findJurisdiction(location);
    final annual = monthlyGross * 12;
    if (j == null || annual <= 0) {
      return TaxEstimate(
        jurisdiction: j,
        annualGross: annual,
        annualNet: annual,
        annualTax: 0,
        monthlyGross: monthlyGross,
        monthlyNet: monthlyGross,
        effectiveRate: 0,
        marginalRate: 0,
      );
    }
    final fed = _bracketTax(annual, j.nationalBrackets);
    final sub = _bracketTax(annual, j.subnationalBrackets);
    final totalTax = fed + sub;
    final net = annual - totalTax;
    final eff = annual > 0 ? totalTax / annual : 0.0;
    final marg = _marginalRate(annual, j);
    return TaxEstimate(
      jurisdiction: j,
      annualGross: annual,
      annualNet: net,
      annualTax: totalTax,
      monthlyGross: monthlyGross,
      monthlyNet: net / 12,
      effectiveRate: eff,
      marginalRate: marg,
    );
  }

  static double _bracketTax(double income, List<TaxBracket> brackets) {
    double tax = 0;
    double remaining = income;
    double prev = 0;
    for (final b in brackets) {
      final span = math.min(remaining, b.upTo - prev);
      if (span <= 0) break;
      tax += span * b.rate;
      remaining -= span;
      prev = b.upTo;
      if (remaining <= 0) break;
    }
    return tax;
  }

  /// Marginal rate is the sum of the national + subnational rates at the
  /// bracket that the next dollar of income would fall into.
  static double _marginalRate(double income, Jurisdiction j) {
    double rateFor(double i, List<TaxBracket> brackets) {
      for (final b in brackets) {
        if (i < b.upTo) return b.rate;
      }
      return brackets.isNotEmpty ? brackets.last.rate : 0;
    }

    return rateFor(income, j.nationalBrackets) +
        rateFor(income, j.subnationalBrackets);
  }
}
