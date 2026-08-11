/// The 16-bit pixel chrome kit.
///
/// One import gives a screen the whole vocabulary: hard-edged boxes and
/// buttons that depress on press, striped meters, square chips and badges,
/// nearest-neighbour sprites, and Acorn's NPC dialogue panel.
///
/// Rules that keep the look coherent:
/// * No border radius, anywhere. [PixelBox] is the only card recipe.
/// * Shadows are solid offsets, never blurred (see `AppShadows`).
/// * Pixel art always renders through [PixelSprite]/[PixelSpriteSheet] so it
///   scales nearest-neighbour.
/// * Interactive controls are at least `AppDims.tap` (44px).
library;

export 'acorn_dialogue.dart';
export 'pixel_bar.dart';
export 'pixel_box.dart';
export 'pixel_button.dart';
export 'pixel_chip.dart';
export 'pixel_header.dart';
export 'pixel_scene.dart';
export 'pixel_sprite.dart';
