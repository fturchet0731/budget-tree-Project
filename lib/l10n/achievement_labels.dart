import '../models/achievement.dart';
import 'app_localizations.dart';

/// Localized title/description for a badge. The catalog stores English text
/// (used as a fallback and in tests); the UI shows these translations, keyed by
/// the badge id.
extension AchievementLabels on Achievement {
  String localizedTitle(AppLocalizations l) {
    switch (id) {
      case 'first_sprout':
        return l.achFirstSproutTitle;
      case 'first_sapling':
        return l.achFirstSaplingTitle;
      case 'first_drop':
        return l.achFirstDropTitle;
      case 'orchard_keeper':
        return l.achOrchardKeeperTitle;
      case 'green_thumb':
        return l.achGreenThumbTitle;
      case 'consistent':
        return l.achConsistentTitle;
      case 'first_harvest':
        return l.achFirstHarvestTitle;
      case 'devoted':
        return l.achDevotedTitle;
      case 'mighty_oak':
        return l.achMightyOakTitle;
      case 'old_growth':
        return l.achOldGrowthTitle;
      default:
        return title;
    }
  }

  String localizedDescription(AppLocalizations l) {
    switch (id) {
      case 'first_sprout':
        return l.achFirstSproutDesc;
      case 'first_sapling':
        return l.achFirstSaplingDesc;
      case 'first_drop':
        return l.achFirstDropDesc;
      case 'orchard_keeper':
        return l.achOrchardKeeperDesc;
      case 'green_thumb':
        return l.achGreenThumbDesc;
      case 'consistent':
        return l.achConsistentDesc;
      case 'first_harvest':
        return l.achFirstHarvestDesc;
      case 'devoted':
        return l.achDevotedDesc;
      case 'mighty_oak':
        return l.achMightyOakDesc;
      case 'old_growth':
        return l.achOldGrowthDesc;
      default:
        return description;
    }
  }
}
