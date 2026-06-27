import 'dart:math' as math;

/// Where a contribution came from. [manual] = the user tapped Deposit,
/// [auto] = credited by the [PayScheduler] pay cycle, [adjustment] =
/// a withdrawal or correction.
enum ContributionSource { manual, auto, adjustment }

/// A single dated money event against a goal. The ledger of these powers
/// streaks, achievements, and week/month comparisons — none of which can be
/// derived from a bare running balance.
class Contribution {
  final DateTime at;

  /// Positive for a deposit, negative for a withdrawal.
  final double amount;
  final ContributionSource source;

  Contribution({
    DateTime? at,
    required this.amount,
    this.source = ContributionSource.manual,
  }) : at = at ?? DateTime.now();

  bool get isDeposit => amount > 0;

  Map<String, dynamic> toJson() => {
        'at': at.millisecondsSinceEpoch,
        'amount': amount,
        'source': source.index,
      };

  factory Contribution.fromJson(Map<String, dynamic> j) => Contribution(
        at: DateTime.fromMillisecondsSinceEpoch(j['at'] as int),
        amount: (j['amount'] as num).toDouble(),
        source: ContributionSource.values[((j['source'] as int?) ?? 0)
            .clamp(0, ContributionSource.values.length - 1)],
      );
}

class Goal {
  String id;
  String name;
  String description;
  double targetAmount;
  double currentAmount;
  String iconKey;
  DateTime createdAt;
  DateTime? completedAt;
  DateTime? targetDate;
  String? categoryId;

  /// When true, accepted friends may view this goal (its sapling + progress)
  /// in their friends list. Defaults to false — sharing is always opt-in, and
  /// this exact field is what the Supabase "friends read shared goals" RLS
  /// policy reads (`data->>'sharedWithFriends'`). Budgets are never shared.
  bool sharedWithFriends;

  /// Dated history of every deposit/withdrawal. Source of truth for
  /// [currentAmount] is still the running field (so legacy records load
  /// unchanged), but new money always also lands here.
  List<Contribution> contributions;

  Goal({
    String? id,
    required this.name,
    this.description = '',
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.iconKey = 'savings',
    DateTime? createdAt,
    this.completedAt,
    this.targetDate,
    this.categoryId,
    this.sharedWithFriends = false,
    List<Contribution>? contributions,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now(),
        contributions = contributions ?? [];

  /// Record a deposit (positive) or withdrawal (negative) and keep
  /// [currentAmount] in sync. Returns the actual amount applied after
  /// clamping the balance at zero. Always go through this so the ledger
  /// stays authoritative for streaks/comparisons.
  double applyContribution(double amount,
      {ContributionSource source = ContributionSource.manual, DateTime? at}) {
    if (amount == 0) return 0;
    final before = currentAmount;
    currentAmount = (currentAmount + amount).clamp(0.0, double.infinity);
    final applied = currentAmount - before;
    if (applied == 0) return 0;
    contributions.add(Contribution(amount: applied, source: source, at: at));
    return applied;
  }

  /// A goal with [targetAmount] <= 0 is treated as uncapped: it grows
  /// indefinitely through size tiers instead of progressing toward a finite
  /// target. The user can set this via the "Grow forever" toggle.
  bool get isUncapped => targetAmount <= 0;

  /// Visual growth value in 0..1. For capped goals this is the simple
  /// currentAmount / targetAmount ratio. For uncapped goals it uses a
  /// logarithmic curve so the sapling keeps growing meaningfully across
  /// many orders of magnitude without ever quite reaching 1.0.
  double get progress {
    if (isUncapped) {
      if (currentAmount <= 0) return 0.0;
      final logAmt = math.log(currentAmount + 1);
      const logMax = 10.82; // ln(50_000)
      return (logAmt / logMax).clamp(0.0, 1.0);
    }
    return targetAmount > 0
        ? (currentAmount / targetAmount).clamp(0.0, 1.0)
        : 0.0;
  }

  bool get isComplete => !isUncapped && currentAmount >= targetAmount;
  double get remaining => isUncapped
      ? 0
      : (targetAmount - currentAmount).clamp(0.0, double.infinity);

  /// 0 = seed, 5 = mature/golden (uses progress under the hood).
  int get stage {
    final p = progress;
    if (p >= 1.0) return 5;
    if (p >= 0.75) return 4;
    if (p >= 0.50) return 3;
    if (p >= 0.25) return 2;
    if (p > 0) return 1;
    return 0;
  }

  /// Tier 1..6 for uncapped goals — used for the "size of the tree" growth.
  /// Each tier corresponds to a money milestone:
  /// 1 (<\$100), 2 (<\$500), 3 (<\$1.5k), 4 (<\$5k), 5 (<\$15k), 6 (\$15k+).
  int get tier {
    if (currentAmount < 100) return 1;
    if (currentAmount < 500) return 2;
    if (currentAmount < 1500) return 3;
    if (currentAmount < 5000) return 4;
    if (currentAmount < 15000) return 5;
    return 6;
  }

  String get tierName {
    switch (tier) {
      case 1:
        return 'Seedling';
      case 2:
        return 'Sapling';
      case 3:
        return 'Young Oak';
      case 4:
        return 'Mature Oak';
      case 5:
        return 'Towering Oak';
      case 6:
        return 'Ancient Oak';
      default:
        return 'Seedling';
    }
  }

  /// Visual scale multiplier applied to the sapling for uncapped goals.
  double get tierScale => 0.70 + (tier - 1) * 0.16;

  String get stageName {
    if (isUncapped) return tierName;
    switch (stage) {
      case 0:
        return 'Seed';
      case 1:
        return 'Sprout';
      case 2:
        return 'Young Sapling';
      case 3:
        return 'Sapling';
      case 4:
        return 'Growing Tree';
      case 5:
        return 'Mature';
      default:
        return 'Seed';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'iconKey': iconKey,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'completedAt': completedAt?.millisecondsSinceEpoch,
        'targetDate': targetDate?.millisecondsSinceEpoch,
        'categoryId': categoryId,
        'sharedWithFriends': sharedWithFriends,
        'contributions': contributions.map((c) => c.toJson()).toList(),
      };

  factory Goal.fromJson(Map<String, dynamic> j) => Goal(
        id: j['id'] as String,
        name: j['name'] as String,
        description: (j['description'] as String?) ?? '',
        targetAmount: (j['targetAmount'] as num).toDouble(),
        currentAmount: (j['currentAmount'] as num).toDouble(),
        iconKey: (j['iconKey'] as String?) ?? 'savings',
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(j['createdAt'] as int),
        completedAt: j['completedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(j['completedAt'] as int)
            : null,
        targetDate: j['targetDate'] != null
            ? DateTime.fromMillisecondsSinceEpoch(j['targetDate'] as int)
            : null,
        categoryId: j['categoryId'] as String?,
        sharedWithFriends: (j['sharedWithFriends'] as bool?) ?? false,
        contributions: (j['contributions'] as List?)
                ?.map((e) =>
                    Contribution.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
