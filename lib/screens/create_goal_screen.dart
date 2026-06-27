import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../models/category_model.dart';
import '../models/goal_model.dart';
import '../services/achievement_service.dart';
import '../services/category_repository.dart';
import '../services/goal_repository.dart';
import '../services/profile_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../theme/category_icons.dart';
import '../theme/leaf_palette.dart';
import '../widgets/bark_card.dart';
import '../widgets/category_picker.dart';
import '../widgets/sapling_view.dart';

class CreateGoalScreen extends StatefulWidget {
  const CreateGoalScreen({super.key});

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen> {
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _iconKey = 'savings';
  String? _categoryId;
  TreeCategory? _pickedCategory;
  bool _uncapped = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  bool get _canSave {
    if (_nameCtrl.text.trim().isEmpty) return false;
    if (_uncapped) return true;
    return (double.tryParse(_targetCtrl.text) ?? 0) > 0;
  }

  /// Preview progress derived from the target amount entered: gives the
  /// user a sense of how the sapling will look once they're partway there.
  double get _previewProgress {
    if (_uncapped) return 0.45; // mid-tier feel
    final amt = double.tryParse(_targetCtrl.text) ?? 0;
    if (amt <= 0) return 0.10; // seedling
    // Use a gentle curve so a $500 target doesn't look identical to $50k.
    final v = (amt / 5000).clamp(0.0, 1.0);
    return 0.15 + v * 0.55;
  }

  LeafPalette get _previewPalette => _pickedCategory != null
      ? LeafPalette.fromAccent(Color(_pickedCategory!.colorValue))
      : LeafPalette.defaultGreen;

  /// Ask, at creation time, whether this goal should be visible to friends.
  /// Only shown when the social layer is available (signed in + online-capable)
  /// — otherwise there's nothing to share to, so it stays private.
  Future<bool> _askVisibility() async {
    if (!ProfileService.instance.isAvailable) return false;
    final l = AppLocalizations.of(context);
    final share = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l.shareThisGoalTitle),
        content: Text(l.shareThisGoalBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.keepPrivate),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.shareWithFriends),
          ),
        ],
      ),
    );
    return share ?? false;
  }

  Future<void> _save() async {
    if (_saving || !_canSave) return;
    final share = await _askVisibility();
    if (!mounted) return;
    setState(() => _saving = true);
    final goal = Goal(
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      targetAmount: _uncapped ? 0 : double.parse(_targetCtrl.text),
      iconKey: _iconKey,
      categoryId: _categoryId,
      sharedWithFriends: share,
    );
    await GoalRepository.saveNew(goal);
    SoundService.goalSet();
    await AchievementService.evaluateAndUnlock();
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _resolveCategory(String? id) async {
    setState(() => _categoryId = id);
    if (id == null) {
      setState(() => _pickedCategory = null);
      return;
    }
    final cats = await CategoryRepository.loadAll();
    if (!mounted) return;
    setState(() {
      _pickedCategory = cats.cast<TreeCategory?>().firstWhere(
            (c) => c?.id == id,
            orElse: () => null,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final hasName = _nameCtrl.text.trim().isNotEmpty;
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ── Palette-driven background scene ───────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(gradient: AppPalettes.deepForest()),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _GoalSkyPainter()),
          ),
          SafeArea(
            child: Column(
              children: [
                _Header(onBack: () => Navigator.pop(context)),
                // Live sapling preview
                _SaplingPreviewBanner(
                  progress: _previewProgress,
                  palette: _previewPalette,
                  iconKey: _iconKey,
                  goalName:
                      hasName ? _nameCtrl.text.trim() : l.newSapling,
                  category: _pickedCategory,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    children: [
                      // ── About this goal ──────────
                      BarkCard(
                        label: l.aboutThisGoal,
                        icon: Icons.spa,
                        child: Column(
                          children: [
                            TextField(
                              controller: _nameCtrl,
                              style: const TextStyle(
                                  color: AppColors.stoneBeigeColor),
                              decoration: InputDecoration(
                                labelText: l.goalName,
                                hintText: l.goalNameHint,
                                prefixIcon: const Icon(Icons.spa,
                                    color: AppColors.mossGreen),
                              ),
                              textCapitalization:
                                  TextCapitalization.words,
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _descCtrl,
                              style: const TextStyle(
                                  color: AppColors.stoneBeigeColor),
                              maxLines: 2,
                              decoration: InputDecoration(
                                labelText: l.notesOptional,
                                hintText: l.notesHint,
                                prefixIcon: const Icon(Icons.notes_outlined,
                                    color: AppColors.mossGreen),
                              ),
                              textCapitalization:
                                  TextCapitalization.sentences,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Target ─────────────────────
                      BarkCard(
                        label: l.howMuch,
                        icon: Icons.flag_outlined,
                        accent: AppColors.leafYellow,
                        child: Column(
                          children: [
                            AnimatedOpacity(
                              duration:
                                  const Duration(milliseconds: 200),
                              opacity: _uncapped ? 0.4 : 1.0,
                              child: TextField(
                                controller: _targetCtrl,
                                enabled: !_uncapped,
                                style: const TextStyle(
                                    color: AppColors.stoneBeigeColor),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9.]')),
                                ],
                                decoration: InputDecoration(
                                  labelText: l.targetAmount,
                                  hintText: l.targetHint,
                                  prefixIcon: const Icon(Icons.flag_outlined,
                                      color: AppColors.mossGreen),
                                  prefixText: '\$ ',
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Grow-forever toggle styled as a leafy switch
                            InkWell(
                              onTap: () => setState(
                                  () => _uncapped = !_uncapped),
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: _uncapped
                                      ? LinearGradient(
                                          colors: [
                                            AppColors.forestGreen
                                                .withValues(alpha: 0.50),
                                            AppColors.darkBark,
                                          ],
                                        )
                                      : null,
                                  color: _uncapped
                                      ? null
                                      : AppColors.soilMid,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _uncapped
                                        ? AppColors.lightLeaf
                                            .withValues(alpha: 0.8)
                                        : AppColors.mossGreen
                                            .withValues(alpha: 0.35),
                                    width: _uncapped ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 220),
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _uncapped
                                            ? AppColors.lightLeaf
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: _uncapped
                                              ? AppColors.lightLeaf
                                              : AppColors.mossGreen
                                                  .withValues(alpha: 0.6),
                                          width: 1.6,
                                        ),
                                      ),
                                      child: _uncapped
                                          ? const Icon(Icons.all_inclusive,
                                              color: Colors.white,
                                              size: 14)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l.growForever,
                                            style: GoogleFonts.nunito(
                                              color: AppColors
                                                  .stoneBeigeColor,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            l.growForeverDesc,
                                            style: GoogleFonts.nunito(
                                                color: AppColors.mossGreen,
                                                fontSize: 11,
                                                height: 1.45),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Icon ───────────────────────
                      BarkCard(
                        label: l.iconLabel,
                        icon: Icons.local_florist_outlined,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: GoalIcons.presets.map((p) {
                            final (key, name, icon) = p;
                            final selected = _iconKey == key;
                            return GestureDetector(
                              onTap: () => setState(() => _iconKey = key),
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 160),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.forestGreen
                                          .withValues(alpha: 0.45)
                                      : AppColors.soilMid,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.lightLeaf
                                        : AppColors.mossGreen
                                            .withValues(alpha: 0.4),
                                    width: selected ? 1.5 : 1,
                                  ),
                                  boxShadow: selected
                                      ? [
                                          BoxShadow(
                                            color: AppColors.lightLeaf
                                                .withValues(alpha: 0.30),
                                            blurRadius: 8,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(icon,
                                        size: 15,
                                        color: selected
                                            ? AppColors.lightLeaf
                                            : AppColors.mossGreen),
                                    const SizedBox(width: 6),
                                    Text(
                                      name,
                                      style: GoogleFonts.nunito(
                                        color: selected
                                            ? AppColors.lightLeaf
                                            : AppColors.stoneBeigeColor,
                                        fontSize: 12.5,
                                        fontWeight: selected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Group ──────────────────────
                      BarkCard(
                        label: l.groupOptional,
                        icon: Icons.label_outline,
                        accent: AppColors.riverBlue,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.groupNote,
                              style: GoogleFonts.nunito(
                                  color: AppColors.mossGreen
                                      .withValues(alpha: 0.85),
                                  fontSize: 11.5,
                                  height: 1.4),
                            ),
                            const SizedBox(height: 10),
                            CategoryPicker(
                              selectedCategoryId: _categoryId,
                              onChanged: _resolveCategory,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _PlantButton(
                  canSave: _canSave,
                  saving: _saving,
                  onTap: _save,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Header with back button + title
// ──────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                    color:
                        AppColors.mossGreen.withValues(alpha: 0.35)),
              ),
              child: const Icon(Icons.arrow_back,
                  color: AppColors.stoneBeigeColor, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).plantASaplingTitle,
                  style: GoogleFonts.fredoka(
                    fontWeight: FontWeight.w600,
                    color: AppColors.stoneBeigeColor,
                    fontSize: 22,
                    shadows: const [
                      Shadow(
                          color: Colors.black54,
                          offset: Offset(0, 2),
                          blurRadius: 6)
                    ],
                  ),
                ),
                Text(
                  AppLocalizations.of(context).plantASaplingSub,
                  style: GoogleFonts.nunito(
                    color: AppColors.mossGreen,
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          // Decorative leaf badge
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.forestGreen.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(Icons.eco, color: Colors.white, size: 14),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Live sapling preview banner (sky + ground + growing sapling)
// ──────────────────────────────────────────────

class _SaplingPreviewBanner extends StatelessWidget {
  final double progress;
  final LeafPalette palette;
  final String iconKey;
  final String goalName;
  final TreeCategory? category;

  const _SaplingPreviewBanner({
    required this.progress,
    required this.palette,
    required this.iconKey,
    required this.goalName,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      height: 170,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF7EC8E3),
            Color(0xFFB6D7A8),
            Color(0xFF7CB342),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Sun glow upper-right
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFF59D).withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // The animated sapling
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                child: SaplingView(
                  key: ValueKey('$progress-${palette.mid.toARGB32()}'),
                  progress: progress,
                  size: Size.infinite,
                  leafPalette: palette,
                ),
              ),
            ),
            // Goal name + icon overlay
            Positioned(
              top: 12,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.38),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(GoalIcons.forKey(iconKey),
                        color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: Text(
                        goalName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.fredoka(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Optional category dot
            if (category != null)
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Color(category!.colorValue),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                        width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Color(category!.colorValue)
                            .withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Plant Sapling button — chunky, glowing wooden button
// ──────────────────────────────────────────────

class _PlantButton extends StatelessWidget {
  final bool canSave;
  final bool saving;
  final VoidCallback onTap;
  const _PlantButton({
    required this.canSave,
    required this.saving,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: canSave
              ? const LinearGradient(
                  colors: [
                    Color(0xFF66BB6A),
                    Color(0xFF2E7D32),
                    Color(0xFF1B5E20),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    AppColors.forestGreen.withValues(alpha: 0.35),
                    AppColors.darkBark,
                  ],
                ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: canSave
                ? Colors.white.withValues(alpha: 0.5)
                : AppColors.mossGreen.withValues(alpha: 0.2),
            width: canSave ? 1.6 : 1,
          ),
          boxShadow: canSave
              ? [
                  BoxShadow(
                    color: AppColors.forestGreen.withValues(alpha: 0.5),
                    blurRadius: 24,
                    spreadRadius: 1,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: canSave && !saving ? onTap : null,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Icon(
                          Icons.spa,
                          color: canSave
                              ? Colors.white
                              : AppColors.stoneBeigeColor
                                  .withValues(alpha: 0.5),
                          size: 18,
                        ),
                  const SizedBox(width: 10),
                  Text(
                    AppLocalizations.of(context).plantSapling,
                    style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.w600,
                      color: canSave
                          ? Colors.white
                          : AppColors.stoneBeigeColor
                              .withValues(alpha: 0.5),
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Sky → forest background painter
// ──────────────────────────────────────────────

class _GoalSkyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // The base gradient is painted behind us from AppPalettes.deepForest();
    // here we only add the glow + silhouettes so the scene follows the palette.

    // Soft glow upper right, tinted to the active palette.
    canvas.drawCircle(
      Offset(w * 0.86, h * 0.06),
      130,
      Paint()
        ..shader = RadialGradient(colors: [
          AppPalettes.celestialGlow().withValues(alpha: 0.18),
          Colors.transparent,
        ]).createShader(
            Rect.fromCircle(center: Offset(w * 0.86, h * 0.06), radius: 130)),
    );

    // Tree silhouettes near the bottom
    final silhouette = const Color(0xFF050D04).withValues(alpha: 0.78);
    final treeY = h * 0.88;
    for (int i = 0; i < 14; i++) {
      final t = (i / 13);
      final x = t * w;
      final cR = 22.0 + ((i * 7) % 4) * 4;
      canvas.drawCircle(Offset(x, treeY - 6), cR, Paint()..color = silhouette);
      canvas.drawCircle(
          Offset(x - 14, treeY + 6), cR * 0.8, Paint()..color = silhouette);
      canvas.drawCircle(
          Offset(x + 12, treeY + 6), cR * 0.7, Paint()..color = silhouette);
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset(x, treeY + 18), width: 5, height: 16),
        Paint()..color = silhouette,
      );
    }

    // Bottom vignette
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.8, w, h * 0.2),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Color(0xFF050905)],
        ).createShader(Rect.fromLTWH(0, h * 0.8, w, h * 0.2)),
    );
  }

  @override
  bool shouldRepaint(_GoalSkyPainter old) => false;
}
