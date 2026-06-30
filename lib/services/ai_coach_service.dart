import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import '../models/ai_plan.dart';
import '../models/goal_model.dart';
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
  }) async {
    final data = await _invoke({
      'action': 'budget_plans',
      'income': income,
      'currency': currency,
      'locale': _locale,
      'synopsis': synopsis,
      'survey': survey,
      'expenses': expenses.map((e) => e.toJson()).toList(),
    });
    final plans = AllocationPlan.listFrom(data);
    if (plans.isEmpty) throw AiUnavailable('No plans returned');
    return plans;
  }

  /// Ask for contribution plans + alternative dates to reach [goal] by
  /// [targetDate], given the user's estimated [freeMonthly] income.
  Future<GoalPlanResult> goalPlans({
    required Goal goal,
    required DateTime targetDate,
    required double freeMonthly,
  }) async {
    final data = await _invoke({
      'action': 'goal_plans',
      'locale': _locale,
      'goal': {
        'name': goal.name,
        'target': goal.targetAmount,
        'current': goal.currentAmount,
        'uncapped': goal.isUncapped,
      },
      'targetDate':
          '${targetDate.year.toString().padLeft(4, '0')}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}',
      'freeMonthly': freeMonthly,
    });
    return GoalPlanResult.fromJson(data);
  }

  /// Ask for a short reflection summary. [input] is the compact, already
  /// computed summary built by the [ReflectionService].
  Future<String> reflection(Map<String, dynamic> input) async {
    final data = await _invoke({
      'action': 'reflection',
      'locale': _locale,
      ...input,
    });
    final text = (data['text'] as String?)?.trim() ?? '';
    if (text.isEmpty) throw AiUnavailable('Empty reflection');
    return text;
  }
}
