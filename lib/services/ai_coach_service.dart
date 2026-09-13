import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import '../data/water_cadence.dart';
import '../models/ai_plan.dart';
import '../models/goal_model.dart';
import '../models/reflection_report.dart';
import 'app_settings.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

/// Thrown when an AI call can't be served (offline, unconfigured, signed out,
/// timed out, or the function returned an error). Callers catch this and fall
/// back to the manual flow / rule-based suggestions.
class AiUnavailable implements Exception {
  final String message;
  AiUnavailable(this.message);
  @override
  String toString() => 'AiUnavailable: $message';
}

/// Client for the `ai-coach` Supabase edge function. Online-only and gated like
/// the social services: it no-ops (throws [AiUnavailable]) when Supabase is
/// unconfigured, the user is signed out, or the AI coach is switched off in
/// settings. The Anthropic key lives only in the edge function.
class AiCoachService {
  AiCoachService._();
  static final AiCoachService instance = AiCoachService._();

  static const _timeout = Duration(seconds: 30);

  /// True when AI features can run: Supabase configured, signed in, and the
  /// user hasn't disabled the coach in settings.
  bool get isAvailable =>
      SupabaseConfig.isConfigured &&
      AuthService.instance.isSignedIn &&
      AppSettings.instance.aiCoachEnabled;

  /// BCP-47-ish language code the AI should write its prose in. Follows the
  /// app's selected locale, falling back to the device locale, then English.
  String get _locale =>
      AppSettings.instance.locale?.languageCode ??
      PlatformDispatcher.instance.locale.languageCode;

  Future<Map<String, dynamic>> _invoke(Map<String, dynamic> body) async {
    if (!isAvailable) throw AiUnavailable('AI coach unavailable');
    try {
      final res = await SupabaseConfig.client.functions
          .invoke('ai-coach', body: body)
          .timeout(_timeout);
      final data = res.data;
      if (data is Map && data['error'] != null) {
        throw AiUnavailable(data['error'].toString());
      }
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      throw AiUnavailable('Unexpected AI response');
    } on AiUnavailable {
      rethrow;
    } catch (e) {
      throw AiUnavailable(e.toString());
    }
  }

  /// Ask for 2-3 allocation plans for [income] across [expenses], shaped by the
  /// user's free-text [synopsis] of how they want their budget to feel. Any
  /// expense with a fixed amount is kept; the rest are chosen by the coach.
  Future<List<AllocationPlan>> budgetPlans({
    required double income,
    required List<BudgetExpenseInput> expenses,
    String synopsis = '',
    Map<String, String> survey = const {},
    String currency = '\$',
    // The budget's cycle (Rhythm.wire): income and every amount are per
    // this period, so the coach scales estimates (a weekly food budget is not
    // a monthly one).
    String cycle = 'monthly',
  }) async {
    final data = await _invoke({
      'action': 'budget_plans',
      'income': income,
      'currency': currency,
      'locale': _locale,
      'synopsis': synopsis,
      'survey': survey,
      'cycle': cycle,
      'expenses': expenses.map((e) => e.toJson()).toList(),
    });
    final plans = AllocationPlan.listFrom(data);
    if (plans.isEmpty) throw AiUnavailable('No plans returned');
    return plans;
  }

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> _goalJson(Goal goal) => {
        'name': goal.name,
        'target': goal.targetAmount,
        'current': goal.currentAmount,
        'uncapped': goal.isUncapped,
      };

  /// Plans for a goal the user has given a **deadline**.
  ///
  /// The per-watering amounts are worked out here by [GoalPlanMath] so the
  /// chosen date is hit exactly; the coach is sent those figures and asked only
  /// to explain each one and to flag whether the pace is realistic against
  /// [freeMonthly]. That split is deliberate — letting the model do the
  /// arithmetic is what used to make a set date drift.
  Future<GoalPlanResult> goalPlansByDate({
    required Goal goal,
    required DateTime targetDate,
    required double freeMonthly,
    required List<GoalPlanOption> computed,
  }) async {
    final data = await _invoke({
      'action': 'goal_plans',
      'mode': 'byDate',
      'locale': _locale,
      'goal': _goalJson(goal),
      'targetDate': _iso(targetDate),
      'freeMonthly': freeMonthly,
      'options': [
        for (final o in computed)
          {'cadence': o.cadence.wire, 'perWatering': o.perWatering.round()},
      ],
    });
    return GoalPlanResult.fromJson(data);
  }

  /// Plans for a goal with **no deadline**: the user picks a pace and we tell
  /// them when it lands. [candidates] are the locally computed options (from
  /// the user's own figure when they gave one, otherwise a spread from
  /// [GoalPlanMath.suggestedPerWatering]); the coach explains them.
  Future<GoalPlanResult> goalPlansByAmount({
    required Goal goal,
    required double freeMonthly,
    required List<GoalPlanOption> candidates,
  }) async {
    final data = await _invoke({
      'action': 'goal_plans',
      'mode': 'byAmount',
      'locale': _locale,
      'goal': _goalJson(goal),
      'freeMonthly': freeMonthly,
      'options': [
        for (final o in candidates)
          {
            'cadence': o.cadence.wire,
            'perWatering': o.perWatering.round(),
            if (o.completionDate != null) 'isoDate': _iso(o.completionDate!),
          },
      ],
    });
    return GoalPlanResult.fromJson(data);
  }

  /// Ask for a reflection. [input] is the compact, already computed summary
  /// built by the [ReflectionService].
  ///
  /// Returns both halves: the prose, which the notification and any older
  /// surface still use, and the structured report the hub presents. A function
  /// deployment older than this app build returns only the prose, so an empty
  /// report is a supported outcome rather than a failure.
  Future<ReflectionResult> reflection(Map<String, dynamic> input) async {
    final data = await _invoke({
      'action': 'reflection',
      'locale': _locale,
      ...input,
    });
    final text = (data['text'] as String?)?.trim() ?? '';
    final report = ReflectionReport.fromJson(data);
    if (text.isEmpty && report.isEmpty) throw AiUnavailable('Empty reflection');
    return ReflectionResult(text: text, report: report);
  }

  /// Ask Acorn a question. [context] is the allow-listed snapshot of the user's
  /// own figures; the conversation history is read server-side, never sent
  /// from here, so a forged assistant turn is not expressible.
  Future<String> acornChat({
    required String message,
    required Map<String, dynamic> context,
  }) async {
    final data = await _invoke({
      'action': 'acorn_chat',
      'locale': _locale,
      'message': message,
      ...context,
    });
    final reply = (data['reply'] as String?)?.trim() ?? '';
    if (reply.isEmpty) throw AiUnavailable('Empty reply');
    return reply;
  }
}

/// Both halves of a reflection response.
class ReflectionResult {
  final String text;
  final ReflectionReport report;
  const ReflectionResult({required this.text, required this.report});
}
