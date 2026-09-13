import 'package:flutter/material.dart';
import '../../theme/app_dims.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';

/// Hard-edged segmented control — theme and text-size pickers, cadence and
/// frequency choices.
///
/// The sliding thumb is gone on purpose: a gliding highlight is a modern
/// affordance and fights the pixel skin. Segments instead snap between an
/// ink-filled selected state and a parchment unselected one, sharing one
/// outline so the row reads as a single control.
class SegmentedChoice<T> extends StatelessWidget {
  final T current;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  const SegmentedChoice({
    super.key,
    required this.current,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Container(
      height: AppDims.tap,
      decoration: BoxDecoration(
        color: t.card,
        border: Border.all(color: t.cardBorder, width: AppDims.borderThick),
        boxShadow: [
          BoxShadow(color: t.boxShadow, offset: const Offset(0, AppDims.dropSmall)),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0)
              Container(width: 2, color: t.cardBorder),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(options[i].$1),
                child: Semantics(
                  button: true,
                  selected: options[i].$1 == current,
                  label: options[i].$2,
                  child: Container(
                    color: options[i].$1 == current ? t.accent : t.card,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      options[i].$2.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTheme.label(
                        9,
                        options[i].$1 == current
                            ? t.onAccent
                            : t.textSecondary,
                        spacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A chunky pixel toggle — the 48px switch from the handoff's options screen.
///
/// Material's `Switch` is an inherently rounded pill, so the settings rows use
/// this instead: a square track with a square knob that slides between two
/// hard positions.
class PixelSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  const PixelSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final enabled = onChanged != null;
    return Semantics(
      toggled: value,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged!(!value) : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: Container(
            width: 52,
            height: 28,
            decoration: BoxDecoration(
              color: value ? t.accent : t.track,
              border: Border.all(color: t.cardBorder, width: 2),
            ),
            child: Align(
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 22,
                height: 24,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: t.card,
                  border: Border.all(color: t.cardBorder, width: 2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A settings row: label + optional helper line on the left, [PixelSwitch] on
/// the right. Drop-in replacement for `SwitchListTile` in the pixel skin.
class PixelSwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const PixelSwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? () => onChanged!(!value) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppDims.s12),
            PixelSwitch(
              value: value,
              onChanged: onChanged,
              semanticLabel: title,
            ),
          ],
        ),
      ),
    );
  }
}
