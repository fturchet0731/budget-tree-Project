import 'package:flutter/services.dart';
import 'app_settings.dart';

/// Lightweight audible/tactile feedback for the app's key moments.
///
/// This intentionally uses only Flutter's built-in [SystemSound] and
/// [HapticFeedback] so it needs no audio packages or asset files and works
/// on every platform out of the box. Each cue layers a haptic with a system
/// tone so the moments feel distinct even without custom samples.
///
/// To upgrade to bespoke sounds later: add an audio package (e.g.
/// `audioplayers`), drop files in `assets/sounds/`, and play them from the
/// matching method below — every call site already routes through here, so
/// nothing else has to change. All cues respect
/// [AppSettings.soundEnabled].
class SoundService {
  SoundService._();

  static bool get _on => AppSettings.instance.soundEnabled;

  /// A new budget tree is planted — a weighty, grounded "thunk".
  static void treePlanted() {
    if (!_on) return;
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
  }

  /// A savings goal (sapling) is created.
  static void goalSet() {
    if (!_on) return;
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
  }

  /// Money is deposited toward a goal — a light "water drop" tap.
  static void fundsAllocated() {
    if (!_on) return;
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);
  }

  /// A growth milestone (new stage/tier) was crossed.
  static void milestone() {
    if (!_on) return;
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.click);
  }

  /// A goal was completed or an achievement unlocked — the biggest cue.
  static void celebrate() {
    if (!_on) return;
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
  }
}
