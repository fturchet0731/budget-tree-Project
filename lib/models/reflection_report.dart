/// The structured half of a reflection.
///
/// The coach used to return two to four sentences of prose, which a banner
/// showed and nobody read. A reflection is now a short presentation Acorn walks
/// the user through, and that needs the parts separated: what went well, what
/// did not, and what to do next, each as its own beat.
///
/// **The model writes only words.** Every number and every chart series comes
/// from [ReflectionStats], computed locally. Same split as [GoalPlanMath]
/// against the `goal_plans` action, and for the same reason: a reflection that
/// misreports the user's own figures back to them is worse than none.
///
/// Parsing is defensive throughout, in the [AiPlan] house style, so a partial
/// or older response degrades to fewer slides rather than an exception. The
/// plain-text [Reflection] is still stored alongside this, so an app build
/// newer than the deployed edge function keeps working.
library;

class ReflectionPoint {
  /// A few words, used as the slide's heading.
  final String title;

  /// One or two sentences underneath.
  final String detail;

  const ReflectionPoint({required this.title, required this.detail});

  factory ReflectionPoint.fromJson(Map<String, dynamic> j) => ReflectionPoint(
        title: (j['title'] as String?) ?? '',
        detail: (j['detail'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {'title': title, 'detail': detail};

  bool get isEmpty => title.trim().isEmpty && detail.trim().isEmpty;

  static List<ReflectionPoint> listFrom(dynamic raw) =>
      ((raw as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ReflectionPoint.fromJson)
          .where((p) => !p.isEmpty)
          .toList();
}

class ReflectionReport {
  /// One sentence: the whole period in a line.
  final String headline;
  final List<ReflectionPoint> strengths;
  final List<ReflectionPoint> weaknesses;
  final List<ReflectionPoint> suggestions;

  /// A closing word from Acorn.
  final String closing;

  const ReflectionReport({
    required this.headline,
    required this.strengths,
    required this.weaknesses,
    required this.suggestions,
    required this.closing,
  });

  static const empty = ReflectionReport(
    headline: '',
    strengths: [],
    weaknesses: [],
    suggestions: [],
    closing: '',
  );

  /// True when there is nothing worth presenting, so the caller falls back to
  /// the plain-text reflection.
  bool get isEmpty =>
      headline.trim().isEmpty &&
      strengths.isEmpty &&
      weaknesses.isEmpty &&
      suggestions.isEmpty;

  factory ReflectionReport.fromJson(Map<String, dynamic> j) => ReflectionReport(
        headline: (j['headline'] as String?) ?? '',
        strengths: ReflectionPoint.listFrom(j['strengths']),
        weaknesses: ReflectionPoint.listFrom(j['weaknesses']),
        suggestions: ReflectionPoint.listFrom(j['suggestions']),
        closing: (j['closing'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {
        'headline': headline,
        'strengths': [for (final p in strengths) p.toJson()],
        'weaknesses': [for (final p in weaknesses) p.toJson()],
        'suggestions': [for (final p in suggestions) p.toJson()],
        'closing': closing,
      };
}
