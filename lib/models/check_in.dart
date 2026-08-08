/// Check-ins: the app's only record of what the user actually *did*.
///
/// Everything else in Budget Tree describes a plan — what a branch is allocated,
/// what a goal is scheduled to receive. Nothing observed spending, so the coach
/// could never say more than "you allocated more than you earn". A check-in
/// closes that gap: on pay day (or when a goal's watering comes due) the user
/// confirms in one tap how the period went, and may optionally type what they
/// really spent on each branch.
///
/// **Only *resolved* check-ins are ever persisted.** A pending one is derived in
/// memory from the budget's pay schedule every time it's needed, so a device
/// that re-derives the same slot can never overwrite another device's answer.
/// See [CheckInService] for why that matters.
library;

/// What kind of moment a check-in covers.
enum CheckInKind { payday, watering }

/// How the user says the period went. Deliberately three coarse buckets rather
/// than a number: the point is that it costs one tap, so the streak survives.
enum CheckInVerdict { onTrack, slipped, offPlan }

/// What a branch was planned to take versus what the user says it actually took.
///
/// Optional, per branch. This is the **only** plan-versus-actual data anywhere
/// in the app, so it's what the overspend chart and the coach's "what went over"
/// talk are built on. A branch the user skipped simply has no entry.
class BranchActual {
  final String name;
  final double planned;
  final double actual;

  const BranchActual({
    required this.name,
    required this.planned,
    required this.actual,
  });

  /// Positive when the branch went over its plan.
  double get overspend => actual - planned;

  Map<String, dynamic> toJson() => {
        'name': name,
        'planned': planned,
        'actual': actual,
      };

  factory BranchActual.fromJson(Map<String, dynamic> j) => BranchActual(
        name: (j['name'] as String?) ?? '',
        planned: ((j['planned'] as num?) ?? 0).toDouble(),
        actual: ((j['actual'] as num?) ?? 0).toDouble(),
      );
}

class CheckIn {
  /// Deterministic: `<kind>:<subjectId>:<yyyy-MM-dd of dueAt>`. Re-deriving the
  /// same slot yields the same id, which is what makes generation idempotent
  /// and lets a resolved row shadow the pending one it came from.
  final String id;
  final CheckInKind kind;

  /// The budget id (payday) or goal id (watering) this covers.
  final String subjectId;

  /// Denormalised so history still reads properly after the budget is renamed
  /// or deleted.
  final String subjectName;

  /// The pay date or watering date this check-in is asking about.
  final DateTime dueAt;

  DateTime? confirmedAt;
  CheckInVerdict? verdict;
  List<BranchActual> actuals;

  /// Stamped once the grace window lapses with no answer. Never cleared: a
  /// missed check-in is exactly the signal tree health is built to notice.
  bool missed;

  CheckIn({
    String? id,
    required this.kind,
    required this.subjectId,
    required this.subjectName,
    required this.dueAt,
    this.confirmedAt,
    this.verdict,
    List<BranchActual>? actuals,
    this.missed = false,
  })  : id = id ?? idFor(kind, subjectId, dueAt),
        actuals = actuals ?? [];

  static String idFor(CheckInKind kind, String subjectId, DateTime dueAt) =>
      '${kind.name}:$subjectId:${dayKey(dueAt)}';

  /// `yyyy-MM-dd` in local time — the slot's identity, so two runs on the same
  /// day agree regardless of the time of day they happen to run at.
  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  bool get isConfirmed => confirmedAt != null;

  /// Resolved check-ins are the only ones that get stored, and the only ones
  /// tree health scores.
  bool get isResolved => confirmedAt != null || missed;

  /// Branches the user reported going over on, worst first.
  List<BranchActual> get overspentBranches {
    final over = actuals.where((a) => a.overspend > 0).toList();
    over.sort((a, b) => b.overspend.compareTo(a.overspend));
    return over;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.index,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'dueAt': dueAt.millisecondsSinceEpoch,
        'confirmedAt': confirmedAt?.millisecondsSinceEpoch,
        'verdict': verdict?.index,
        'actuals': actuals.map((a) => a.toJson()).toList(),
        'missed': missed,
      };

  factory CheckIn.fromJson(Map<String, dynamic> j) => CheckIn(
        id: j['id'] as String,
        kind: CheckInKind.values[((j['kind'] as num?)?.toInt() ?? 0)
            .clamp(0, CheckInKind.values.length - 1)],
        subjectId: (j['subjectId'] as String?) ?? '',
        subjectName: (j['subjectName'] as String?) ?? '',
        dueAt: DateTime.fromMillisecondsSinceEpoch(j['dueAt'] as int),
        confirmedAt: j['confirmedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(j['confirmedAt'] as int)
            : null,
        verdict: j['verdict'] != null
            ? CheckInVerdict.values[(j['verdict'] as num)
                .toInt()
                .clamp(0, CheckInVerdict.values.length - 1)]
            : null,
        actuals: (j['actuals'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(BranchActual.fromJson)
                .toList() ??
            const [],
        missed: (j['missed'] as bool?) ?? false,
      );
}
