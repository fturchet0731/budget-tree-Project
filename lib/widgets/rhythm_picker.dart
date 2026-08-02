import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/rhythm.dart';
import '../l10n/app_localizations.dart';
import '../l10n/rhythm_labels.dart';
import '../services/app_settings.dart';
import '../theme/app_tokens.dart';

/// The four preset rhythm chips plus a **Custom** chip that reveals a
/// "every [N] [days/weeks/months]" row.
///
/// Used wherever a pay/charge rhythm is chosen: the income and expense steps of
/// the create-budget wizard, the budget's own cycle, and the forest edit sheet.
/// Selecting Custom keeps whatever count/unit the user last typed, so toggling
/// between a preset and back doesn't wipe their entry.
class RhythmPicker extends StatefulWidget {
  const RhythmPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.compact = false,
  });

  final Rhythm value;
  final ValueChanged<Rhythm> onChanged;

  /// Tighter spacing for dense contexts like the forest edit sheet.
  final bool compact;

  @override
  State<RhythmPicker> createState() => _RhythmPickerState();
}

class _RhythmPickerState extends State<RhythmPicker> {
  late final TextEditingController _countCtrl;

  /// Remembered so flipping to a preset and back restores the user's interval
  /// instead of resetting to the default.
  late int _count;
  late CadenceUnit _unit;

  @override
  void initState() {
    super.initState();
    _count = widget.value.isCustom && widget.value.count > 0
        ? widget.value.count
        : 3;
    _unit = widget.value.isCustom ? widget.value.unit : CadenceUnit.weeks;
    _countCtrl = TextEditingController(text: '$_count');
  }

  @override
  void dispose() {
    _countCtrl.dispose();
    super.dispose();
  }

  void _emitCustom() => widget.onChanged(Rhythm.every(_count, _unit));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = AppTokens.current;
    final isCustom = widget.value.isCustom;
    final gap = widget.compact ? 6.0 : 8.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final r in Rhythm.presets)
              _Chip(
                label: r.localizedLabel(l),
                selected: !isCustom && widget.value == r,
                onTap: () => widget.onChanged(r),
              ),
            _Chip(
              label: l.rhythmCustom,
              selected: isCustom,
              onTap: _emitCustom,
            ),
          ],
        ),
        // The interval row only exists while Custom is the active choice.
        AnimatedSize(
          duration: Duration(
            milliseconds:
                (180 * AppSettings.instance.motionMultiplier).round(),
          ),
          curve: Curves.easeOut,
          alignment: Alignment.topLeft,
          child: !isCustom
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: EdgeInsets.only(top: gap + 2),
                  child: Row(
                    children: [
                      Text(
                        l.rhythmEvery,
                        style: GoogleFonts.nunito(
                          color: t.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 64,
                        child: TextField(
                          controller: _countCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: l.rhythmCustomHint,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                          ),
                          style: GoogleFonts.nunito(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                          onChanged: (v) {
                            final n = int.tryParse(v) ?? 0;
                            // Keep an invalid entry out of the model: the
                            // conversions would divide by it.
                            if (n <= 0) return;
                            _count = n;
                            _emitCustom();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<CadenceUnit>(
                            value: _unit,
                            isDense: true,
                            borderRadius: BorderRadius.circular(14),
                            style: GoogleFonts.nunito(
                              color: t.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            items: [
                              for (final u in CadenceUnit.values)
                                DropdownMenuItem(
                                  value: u,
                                  child: Text(u.localizedLabel(l)),
                                ),
                            ],
                            onChanged: (u) {
                              if (u == null) return;
                              setState(() => _unit = u);
                              _emitCustom();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

/// Compact rhythm chooser for dense surfaces (the forest edit sheet's popup
/// rows) where the inline [RhythmPicker] doesn't fit. Returns the chosen
/// rhythm, or null when the user backs out.
Future<Rhythm?> showRhythmDialog(BuildContext context, Rhythm current) {
  return showDialog<Rhythm>(
    context: context,
    builder: (ctx) {
      final l = AppLocalizations.of(ctx);
      var picked = current;
      return AlertDialog(
        title: Text(l.rhythmCustom),
        content: StatefulBuilder(
          builder: (ctx, setLocal) => RhythmPicker(
            value: picked,
            onChanged: (r) => setLocal(() => picked = r),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, picked),
            child: Text(l.save),
          ),
        ],
      );
    },
  );
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.current;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(
          milliseconds: (160 * AppSettings.instance.motionMultiplier).round(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? t.accentSoft : t.canvasSoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? t.accentStrong : t.cardBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            color: selected ? t.accentStrong : t.textPrimary,
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
