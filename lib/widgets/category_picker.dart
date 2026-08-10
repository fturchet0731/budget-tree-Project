import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../models/category_model.dart';
import '../services/category_repository.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

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
    if (mounted) {
      setState(() {
        _cats = c;
        _loaded = true;
      });
    }
  }

  Future<void> _openCreateDialog() async {
    final created = await showCreateCategoryDialog(context);
    if (created != null) {
      await _load();
      widget.onChanged(created.id);
    }
  }

  /// Long-pressing a category chip offers to delete it. Budgets/goals that
  /// referenced it simply lose their tint (their categoryId no longer resolves),
  /// so no cascading cleanup is needed. If the deleted one was selected, the
  /// selection falls back to "None".
  Future<void> _confirmDelete(TreeCategory cat) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteCategoryTitle),
        content: Text(l.deleteCategoryBody(cat.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTokens.current.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await CategoryRepository.delete(cat.id);
    if (widget.selectedCategoryId == cat.id) widget.onChanged(null);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const SizedBox(
        height: 32,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final chips = <Widget>[];

    if (widget.showAllOption) {
      chips.add(
        _PickerChip(
          label: 'All',
          color: AppColors.mossGreen,
          selected: widget.selectedCategoryId == null,
          onTap: () => widget.onChanged(null),
        ),
      );
    } else {
      chips.add(
        _PickerChip(
          label: 'None',
          color: AppColors.mossGreen,
          selected: widget.selectedCategoryId == null,
          onTap: () => widget.onChanged(null),
        ),
      );
    }

    for (final c in _cats) {
      chips.add(
        _PickerChip(
          label: c.name,
          color: Color(c.colorValue),
          selected: widget.selectedCategoryId == c.id,
          onTap: () => widget.onChanged(c.id),
          onLongPress: () => _confirmDelete(c),
        ),
      );
    }

    chips.add(
      GestureDetector(
        onTap: _openCreateDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppTokens.current.accentSoft,
            borderRadius: BorderRadius.zero,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 14, color: AppTokens.current.accentStrong),
              const SizedBox(width: 5),
              Text(
                'New',
                style: GoogleFonts.nunito(
                  color: AppTokens.current.accentStrong,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: 8, runSpacing: 8, children: chips),
        if (_cats.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).longPressToDeleteGroup,
            style: GoogleFonts.nunito(
              color: AppColors.mossGreen.withValues(alpha: 0.7),
              fontSize: 10.5,
            ),
          ),
        ],
      ],
    );
  }
}

class _PickerChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  const _PickerChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.18)
              : AppTokens.current.canvasSoft,
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: selected ? color : AppTokens.current.cardBorder,
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
        title: Row(
          children: [
            Icon(
              Icons.label_outline,
              color: AppTokens.current.accentStrong,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(l.newCategoryTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.newCategoryBody,
              style: GoogleFonts.nunito(
                color: AppTokens.current.textSecondary,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              autofocus: true,
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
                      border: Border.all(
                        color: isSel
                            ? AppTokens.current.textPrimary
                            : Colors.transparent,
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
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
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
            child: Text(l.cancel),
          ),
          ElevatedButton(
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
            child: Text(l.createButton),
          ),
        ],
      ),
    ),
  );
}
