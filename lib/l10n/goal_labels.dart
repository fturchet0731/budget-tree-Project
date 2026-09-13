import '../models/goal_model.dart';
import 'app_localizations.dart';

/// Localized display names for a goal's growth stage / tier. The model's own
/// `Goal.stageName` / `Goal.tierName` getters return English (used in tests and
/// any non-UI context); these helpers give the translated label for the UI.
extension GoalLabels on Goal {
  /// Localized name for the capped goal's stage (0..5), or the uncapped tier
  /// name when the goal grows forever — mirrors [Goal.stageName].
  String localizedStageName(AppLocalizations l) {
    if (isUncapped) return localizedTierName(l);
    switch (stage) {
      case 1:
        return l.stageSprout;
      case 2:
        return l.stageYoungSapling;
      case 3:
        return l.stageSapling;
      case 4:
        return l.stageGrowingTree;
      case 5:
        return l.stageMature;
      case 0:
      default:
        return l.stageSeed;
    }
  }

  /// Localized name for the uncapped goal's tier (1..6) — mirrors [Goal.tierName].
  String localizedTierName(AppLocalizations l) {
    switch (tier) {
      case 2:
        return l.tierSapling;
      case 3:
        return l.tierYoungOak;
      case 4:
        return l.tierMatureOak;
      case 5:
        return l.tierToweringOak;
      case 6:
        return l.tierAncientOak;
      case 1:
      default:
        return l.tierSeedling;
    }
  }
}
