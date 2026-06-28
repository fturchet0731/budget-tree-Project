import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../models/category_model.dart';
import '../services/category_repository.dart';
import '../theme/app_theme.dart';

/// Palette of colours offered when the user creates a new category.
const List<Color> categoryColorChoices = [
  Color(0xFF66BB6A), // green
  Color(0xFF42A5F5), // blue
  Color(0xFFEF5350), // red
  Color(0xFFFFA726), // orange
  Color(0xFFFFEB3B), // yellow
  Color(0xFF26C6DA), // cyan
  Color(0xFFAB47BC), // purple
  Color(0xFFEC407A), // pink
  Color(0xFF8D6E63), // brown
  Color(0xFF78909C), // grey-blue
];

/// Inline category picker. Shows all categories as chips + an "Add" chip.
/// Tap a chip to select; tap "Add" to open the create dialog.
class CategoryPicker extends StatefulWidget {
  final String? selectedCategoryId;
  final ValueChanged<String?> onChanged;
  final bool showAllOption;
  const CategoryPicker({
    super.key,
    required this.selectedCategoryId,
    required this.onChanged,
    this.showAllOption = false,
  });

  @override
  State<CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<CategoryPicker> {
  List<TreeCategory> _cats = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await CategoryRepository.loadAll();
    if (mounted) setState(() { _cats = c; _loaded = true; });
  }

  Future<void> _openCreateDialog() async {
    final created = await showCreateCategoryDialog(context);
    if (created != null) {
      await _load();
      widget.onChanged(created.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const SizedBox(
        height: 32,
        child: Center(
            child: CircularProgressIndicator(
                color: AppColors.lightLeaf, strokeWidth: 2)),
      );
    }

    final chips = <Widget>[];

    if (widget.showAllOption) {
      chips.add(_PickerChip(
        label: 'All',
        color: AppColors.mossGreen,
        selected: widget.selectedCategoryId == null,
        onTap: () => widget.onChanged(null),
      ));
    } else {
      chips.add(_PickerChip(
        label: 'None',
        color: AppColors.mossGreen,
        selected: widget.selectedCategoryId == null,
        onTap: () => widget.onChanged(null),
      ));
    }

    for (final c in _cats) {
      chips.add(_PickerChip(
        label: c.name,
        color: Color(c.colorValue),
        selected: widget.selectedCategoryId == c.id,
        onTap: () => widget.onChanged(c.id),
      ));
    }

    chips.add(GestureDetector(
      onTap: _openCreateDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.darkBark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.mossGreen.withValues(alpha: 0.45),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add,
                size: 14, color: AppColors.lightLeaf),
            const SizedBox(width: 5),
            Text(
              'New',
              style: GoogleFonts.nunito(
                color: AppColors.lightLeaf,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ));

    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }
}

class _PickerChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _PickerChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.35) : AppColors.darkBark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.45),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 9,
              height: 9,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.7),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.nunito(
                color: AppColors.stoneBeigeColor,
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens a dialog to create a new category. Returns the saved category
/// on success, or null on cancel.
Future<TreeCategory?> showCreateCategoryDialog(BuildContext context) async {
  final l = AppLocalizations.of(context);
  final nameCtrl = TextEditingController();
  Color selectedColor = categoryColorChoices.first;

  return showDialog<TreeCategory>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (sbCtx, setSBState) => AlertDialog(
        backgroundColor: const Color(0xFF122B0F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.label_outline,
                color: AppColors.lightLeaf, size: 22),
            const SizedBox(width: 10),
            Text(
              l.newCategoryTitle,
              style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.w600,
                  color: AppColors.stoneBeigeColor,
                  fontSize: 20),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.newCategoryBody,
              style: GoogleFonts.nunito(
                  color: AppColors.mossGreen, fontSize: 12.5, height: 1.45),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              style: const TextStyle(color: AppColors.stoneBeigeColor),
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l.categoryName,
                hintText: l.categoryNameTripsHint,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l.colourUpper,
              style: GoogleFonts.nunito(
                color: AppColors.mossGreen.withValues(alpha: 0.75),
                fontSize: 10.5,
                letterSpacing: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categoryColorChoices.map((c) {
                final isSel = c.toARGB32() == selectedColor.toARGB32();
                return GestureDetector(
                  onTap: () => setSBState(() => selectedColor = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSel ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: isSel
                          ? [
                              BoxShadow(
                                color: c.withValues(alpha: 0.7),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSel
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel,
                style: GoogleFonts.nunito(color: AppColors.mossGreen)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forestGreen,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final created = TreeCategory(
                name: name,
                colorValue: selectedColor.toARGB32(),
              );
              await CategoryRepository.saveNew(created);
              if (ctx.mounted) Navigator.pop(ctx, created);
            },
            child: Text(l.createButton,
                style: GoogleFonts.nunito(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ),
  );
}
