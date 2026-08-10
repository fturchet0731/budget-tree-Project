import 'package:flutter/material.dart';
import '../theme/leaf_palette.dart';
import 'status_tree_view.dart';

/// Renders a growing goal tree whose stage is driven by [progress] (0..1).
///
/// In the pixel skin a sapling is drawn with the **authored status-tree
/// sprites** rather than the procedural pixel engine: the same 4-frame sheets
/// the health tree uses, picked by growth stage. That is the handoff's explicit
/// choice, and it means a goal and the consistency tree share one visual
/// language — the player reads "my tree got further along" the same way in both
/// places, and every sapling gets the canopy sway for free.
///
/// Growth is still **derived, never stored**: the stage comes from [progress],
/// which comes from the goal's contribution ledger.
class SaplingView extends StatelessWidget {
  /// Design box kept from the painted version so every call site lays out
  /// unchanged.
  static const _designSize = Size(216, 264);

  /// Growth stages, gentlest to fullest. Six bands across 0..1.
  static const _stages = <String>[
    'barren',
    'sparse',
    'wilting',
    'leafing',
    'full',
    'flourishing',
  ];

  final double progress;
  final Size size;
  final bool showGround;

  /// Accepted for API compatibility. The authored sprites carry their own
  /// palette, so a goal's category tint no longer recolours the tree — the
  /// category colour still shows on the goal's card and chips.
  final LeafPalette leafPalette;

  const SaplingView({
    super.key,
    required this.progress,
    this.size = _designSize,
    this.showGround = true,
    this.leafPalette = LeafPalette.defaultGreen,
  });

  /// The sprite key for a 0..1 growth value.
  static String spriteFor(double progress) {
    final p = progress.clamp(0.0, 1.0);
    final i = (p * _stages.length).floor().clamp(0, _stages.length - 1);
    return _stages[i];
  }

  @override
  Widget build(BuildContext context) {
    final key = spriteFor(progress);
    // Size.infinite means "fill whatever the parent gives us".
    if (!size.isFinite) {
      return LayoutBuilder(
        builder: (context, c) {
          final side = c.biggest.shortestSide;
          return Center(
            child: StatusTreeView(spriteKey: key, size: side.isFinite ? side : 120),
          );
        },
      );
    }
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Center(
        child: StatusTreeView(
          spriteKey: key,
          size: size.shortestSide,
        ),
      ),
    );
  }
}
