import '../services/tree_health_service.dart';
import 'app_localizations.dart';

/// Localized names for the sixteen status-tree tiers, kept out of the service so
/// the scale itself stays pure and testable without a BuildContext. Same shape
/// as the other label extensions in this folder.
extension TreeHealthTierLabel on TreeHealthTier {
  String label(AppLocalizations l) {
    switch (this) {
      case TreeHealthTier.barren:
        return l.treeHealthBarren;
      case TreeHealthTier.sparse:
        return l.treeHealthSparse;
      case TreeHealthTier.wilting:
        return l.treeHealthWilting;
      case TreeHealthTier.holding:
        return l.treeHealthHolding;
      case TreeHealthTier.leafing:
        return l.treeHealthLeafing;
      case TreeHealthTier.full:
        return l.treeHealthFull;
      case TreeHealthTier.flourishing:
        return l.treeHealthFlourishing;
      case TreeHealthTier.radiant:
        return l.treeHealthRadiant;
    }
  }
}

extension PrestigeTierLabel on PrestigeTier {
  String label(AppLocalizations l) {
    switch (this) {
      case PrestigeTier.blossoming:
        return l.treeHealthBlossoming;
      case PrestigeTier.fruiting:
        return l.treeHealthFruiting;
      case PrestigeTier.ancient:
        return l.treeHealthAncient;
      case PrestigeTier.silver:
        return l.treeHealthSilver;
      case PrestigeTier.gilded:
        return l.treeHealthGilded;
      case PrestigeTier.diamond:
        return l.treeHealthDiamond;
      case PrestigeTier.amethyst:
        return l.treeHealthAmethyst;
      case PrestigeTier.ruby:
        return l.treeHealthRuby;
    }
  }
}

/// The name to show for a tree's current state: its prestige rank while it is
/// on show, otherwise its score tier.
extension TreeHealthStatusLabel on TreeHealth {
  String statusLabel(AppLocalizations l) =>
      showsPrestige ? earnedPrestige!.label(l) : tier.label(l);
}

/// The caption beside the status EXP bar: how close the next tree is.
/// "12 XP TO RADIANT" / "5 DAYS TO BLOSSOMING" / "MAX LEVEL".
extension LevelProgressLabel on LevelProgress {
  String toNextLabel(AppLocalizations l) {
    if (atMax) return l.statusMaxLevel;
    final name = nextPrestige?.label(l) ?? nextTier!.label(l);
    return inDays
        ? l.statusDaysToNext(toNext, name)
        : l.statusXpToNext(toNext, name);
  }
}
