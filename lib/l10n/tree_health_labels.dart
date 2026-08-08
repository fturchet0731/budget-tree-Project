import '../services/tree_health_service.dart';
import 'app_localizations.dart';

/// Localized names for the five tree-health tiers, kept out of the service so
/// the scale itself stays pure and testable without a BuildContext. Same shape
/// as the other label extensions in this folder.
extension TreeHealthTierLabel on TreeHealthTier {
  String label(AppLocalizations l) {
    switch (this) {
      case TreeHealthTier.barren:
        return l.treeHealthBarren;
      case TreeHealthTier.wilting:
        return l.treeHealthWilting;
      case TreeHealthTier.steady:
        return l.treeHealthSteady;
      case TreeHealthTier.flourishing:
        return l.treeHealthFlourishing;
      case TreeHealthTier.radiant:
        return l.treeHealthRadiant;
    }
  }
}
