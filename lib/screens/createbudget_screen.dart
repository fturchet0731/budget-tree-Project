import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/pay_frequency.dart';
import '../data/tax_data.dart';
import '../models/budget_model.dart';
import '../services/tax_calculator.dart';
import '../theme/app_theme.dart';
import '../theme/category_icons.dart';
import '../widgets/acorn_coach.dart';
import '../widgets/bark_card.dart';
import '../widgets/info_button.dart';
import '../widgets/vine_step_indicator.dart';
import '../tutorial/tutorial_content.dart';
import 'budget_tree_screen.dart';

class CreateBudgetScreen extends StatefulWidget {
  /// When true, Acorn rides along and coaches each phase (used by the tour).
  final bool tutorial;
  const CreateBudgetScreen({super.key, this.tutorial = false});

  @override
  State<CreateBudgetScreen> createState() => _CreateBudgetScreenState();
}

class _CreateBudgetScreenState extends State<CreateBudgetScreen> {
  int _step = 0;

  // Step 1 – Income
  final List<IncomeSource> _incomeSources = [];
  final _incomeNameCtrl = TextEditingController();
  final _incomeAmountCtrl = TextEditingController();

  // Step 2 – Expenses
  final List<ExpenseCategory> _expenses = [];
  final _expNameCtrl = TextEditingController();
  final _expAmountCtrl = TextEditingController();
  String _selectedIconKey = 'other';

  // Step 3 – Personal info
  final _budgetNameCtrl = TextEditingController(text: 'My Budget');
  final _ageCtrl = TextEditingController();
  String? _jurisdictionCode;
  PayFrequency? _payFrequency;
  DateTime? _firstPayDate;

  // icon key + display name
  static const _presets = [
    ('home', 'Housing'),
    ('food', 'Food'),
    ('transport', 'Transport'),
    ('savings', 'Savings'),
    ('entertainment', 'Entertainment'),
    ('subscriptions', 'Subscriptions'),
    ('healthcare', 'Healthcare'),
    ('personal', 'Personal'),
    ('other', 'Other'),
  ];

  static const _incomeSuggestions = [
    'Salary', 'Wages', 'Part-time Job', 'Freelance',
    'Investments', 'Dividends', 'Rental Income',
    'Business Income', 'Government Benefits', 'Scholarship', 'Pension',
  ];

  @override
  void dispose() {
    _incomeNameCtrl.dispose();
    _incomeAmountCtrl.dispose();
    _expNameCtrl.dispose();
    _expAmountCtrl.dispose();
    _budgetNameCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  double get _totalIncome => _incomeSources.fold(0.0, (s, e) => s + e.amount);
  double get _totalAllocated => _expenses.fold(0.0, (s, e) => s + e.allocated);

  void _addIncome() {
    final name = _incomeNameCtrl.text.trim();
    final amount = double.tryParse(_incomeAmountCtrl.text) ?? 0;
    if (name.isEmpty || amount <= 0) return;
    setState(() {
      _incomeSources.add(IncomeSource(name: name, amount: amount));
      _incomeNameCtrl.clear();
      _incomeAmountCtrl.clear();
    });
  }

  void _addExpense() {
    final name = _expNameCtrl.text.trim();
    final amount = double.tryParse(_expAmountCtrl.text) ?? 0;
    if (name.isEmpty || amount <= 0) return;
    setState(() {
      _expenses.add(ExpenseCategory(
          name: name, allocated: amount, emoji: _selectedIconKey));
      _expNameCtrl.clear();
      _expAmountCtrl.clear();
    });
  }

  void _plantTree() {
    final age = int.tryParse(_ageCtrl.text) ?? 0;
    final j = _jurisdictionCode != null ? findJurisdiction(_jurisdictionCode) : null;
    final model = BudgetModel(
      budgetName: _budgetNameCtrl.text.trim().isEmpty
          ? 'My Budget'
          : _budgetNameCtrl.text.trim(),
      incomeSources: _incomeSources,
      expenses: _expenses,
      age: age,
      location: j?.name ?? '',
      payFrequency: _payFrequency,
      firstPayDate: _firstPayDate,
    );
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, anim, secondaryAnim) =>
            BudgetTreeScreen(budget: model, tutorial: widget.tutorial),
        transitionsBuilder: (_, anim, secondaryAnim, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stepTitle = _step == 0
        ? 'Income Sources'
        : _step == 1
            ? 'Expense Branches'
            : 'About Your Roots';
    final stepSubtitle = _step == 0
        ? 'What flows into your tree?'
        : _step == 1
            ? 'Where do the branches reach?'
            : 'A few details to personalise your forest';

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF050B05),
      body: Stack(
        children: [
          // ── Atmospheric background ───────────────
          Positioned.fill(
            child: CustomPaint(painter: _NatureBgPainter()),
          ),
          // ── Foreground content ───────────────────
          SafeArea(
            child: Column(
              children: [
                _CreateHeader(
                  step: _step,
                  title: stepTitle,
                  subtitle: stepSubtitle,
                  onBack: _step == 0
                      ? () => Navigator.pop(context)
                      : () => setState(() => _step--),
                ),
                VineStepIndicator(
                  currentStep: _step,
                  steps: const [
                    VineStep(label: 'Seed', icon: Icons.eco),
                    VineStep(label: 'Branches', icon: Icons.account_tree_outlined),
                    VineStep(label: 'Roots', icon: Icons.park_outlined),
                  ],
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 380),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, anim) {
                      final slide = Tween<Offset>(
                        begin: const Offset(0.06, 0),
                        end: Offset.zero,
                      ).animate(anim);
                      return FadeTransition(
                        opacity: anim,
                        child: SlideTransition(position: slide, child: child),
                      );
                    },
                    child: _step == 0
                        ? _IncomeStep(
                            key: const ValueKey(0),
                            sources: _incomeSources,
                            nameCtrl: _incomeNameCtrl,
                            amountCtrl: _incomeAmountCtrl,
                            suggestions: _incomeSuggestions,
                            onAdd: _addIncome,
                            onRemove: (i) =>
                                setState(() => _incomeSources.removeAt(i)),
                          )
                        : _step == 1
                            ? _ExpenseStep(
                                key: const ValueKey(1),
                                expenses: _expenses,
                                nameCtrl: _expNameCtrl,
                                amountCtrl: _expAmountCtrl,
                                selectedIconKey: _selectedIconKey,
                                totalIncome: _totalIncome,
                                totalAllocated: _totalAllocated,
                                presets: _presets,
                                onAdd: _addExpense,
                                onRemove: (i) =>
                                    setState(() => _expenses.removeAt(i)),
                                onPresetTap: (name, iconKey) => setState(() {
                                  _expNameCtrl.text =
                                      name == 'Other' ? '' : name;
                                  _selectedIconKey = iconKey;
                                }),
                              )
                            : _PersonalStep(
                                key: const ValueKey(2),
                                nameCtrl: _budgetNameCtrl,
                                ageCtrl: _ageCtrl,
                                jurisdictionCode: _jurisdictionCode,
                                payFrequency: _payFrequency,
                                firstPayDate: _firstPayDate,
                                monthlyGross: _totalIncome,
                                onJurisdictionChanged: (code) =>
                                    setState(() => _jurisdictionCode = code),
                                onFrequencyChanged: (f) =>
                                    setState(() => _payFrequency = f),
                                onFirstPayDateChanged: (d) =>
                                    setState(() => _firstPayDate = d),
                              ),
                  ),
                ),
                _BottomBar(
                  step: _step,
                  canAdvance: _step == 0
                      ? _incomeSources.isNotEmpty
                      : _step == 1
                          ? _expenses.isNotEmpty
                          : true,
                  onNext: () {
                    if (_step < 2) {
                      setState(() => _step++);
                    } else {
                      _plantTree();
                    }
                  },
                ),
              ],
            ),
          ),
          // ── Acorn coach for the current phase (tutorial only) ──
          // Fills the screen so the user can drag Acorn's tip anywhere.
          if (widget.tutorial)
            Positioned.fill(
              child: SafeArea(
                child: AcornCoach(
                  lessonKey: _step,
                  lines: createStepSteps(_step),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Atmospheric background painter (sky → forest)
// ──────────────────────────────────────────────

class _NatureBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Vertical gradient: night sky → deep forest → soil
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0A1F1A),
            Color(0xFF0E2818),
            Color(0xFF112B14),
            Color(0xFF09140A),
          ],
          stops: [0.0, 0.35, 0.7, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Soft moon-like glow upper right
    canvas.drawCircle(
      Offset(w * 0.85, h * 0.08),
      120,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFFFFE0B2).withValues(alpha: 0.18),
          Colors.transparent,
        ]).createShader(
            Rect.fromCircle(center: Offset(w * 0.85, h * 0.08), radius: 120)),
    );

    // Distant tree silhouettes near the bottom (fading into bg)
    final silhouette = const Color(0xFF050D04).withValues(alpha: 0.75);
    final treeY = h * 0.86;
    for (int i = 0; i < 12; i++) {
      final t = (i / 11);
      final x = t * w;
      // Three overlapping ovals per tree forming a simple silhouette
      final cR = 22.0 + ((i * 7) % 4) * 4;
      canvas.drawCircle(Offset(x, treeY - 6), cR, Paint()..color = silhouette);
      canvas.drawCircle(
          Offset(x - 14, treeY + 6), cR * 0.8, Paint()..color = silhouette);
      canvas.drawCircle(
          Offset(x + 12, treeY + 6), cR * 0.7, Paint()..color = silhouette);
      // Tiny trunk
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset(x, treeY + 18), width: 5, height: 16),
        Paint()..color = silhouette,
      );
    }

    // Foreground vignette darkening the very bottom
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
  bool shouldRepaint(_NatureBgPainter old) => false;
}

// ──────────────────────────────────────────────
// Header bar — back button + step title plaque
// ──────────────────────────────────────────────

class _CreateHeader extends StatelessWidget {
  final int step;
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  const _CreateHeader({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.mossGreen.withValues(alpha: 0.35)),
              ),
              child: Icon(
                step == 0 ? Icons.arrow_back : Icons.chevron_left,
                color: AppColors.stoneBeigeColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                          begin: const Offset(0, 0.2), end: Offset.zero)
                      .animate(anim),
                  child: child,
                ),
              ),
              child: Column(
                key: ValueKey(step),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.w600,
                      color: AppColors.stoneBeigeColor,
                      fontSize: 22,
                      shadows: const [
                        Shadow(
                            color: Colors.black54,
                            offset: Offset(0, 2),
                            blurRadius: 6),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.nunito(
                      color: AppColors.mossGreen,
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SectionInfoButton(section: TutorialSection.create),
          const SizedBox(width: 10),
          // Decorative small leaf badge
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF66BB6A),
                  Color(0xFF2E7D32),
                ],
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
            child: Text(
              '${step + 1}',
              style: GoogleFonts.fredoka(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Step 1 – Income
// ──────────────────────────────────────────────

class _IncomeStep extends StatelessWidget {
  final List<IncomeSource> sources;
  final TextEditingController nameCtrl;
  final TextEditingController amountCtrl;
  final List<String> suggestions;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  const _IncomeStep({
    super.key,
    required this.sources,
    required this.nameCtrl,
    required this.amountCtrl,
    required this.suggestions,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final total = sources.fold(0.0, (s, e) => s + e.amount);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        // Quick-picks card
        BarkCard(
          label: 'Quick-pick',
          icon: Icons.bolt,
          accent: AppColors.riverBlue,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions
                .map((s) => GestureDetector(
                      onTap: () => nameCtrl.text = s,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.soilMid,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.riverBlue
                                  .withValues(alpha: 0.45)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.water_drop_outlined,
                                size: 12, color: AppColors.riverBlue),
                            const SizedBox(width: 5),
                            Text(s,
                                style: GoogleFonts.nunito(
                                    color: AppColors.stoneBeigeColor,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 14),
        // Add a source card
        BarkCard(
          label: 'Add a source',
          icon: Icons.add_circle_outline,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: AppColors.stoneBeigeColor),
                  decoration: const InputDecoration(
                      labelText: 'Source name', hintText: 'e.g. Salary'),
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: amountCtrl,
                  style: const TextStyle(color: AppColors.stoneBeigeColor),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                  ],
                  decoration: const InputDecoration(
                      labelText: 'Amount \$', hintText: '0.00'),
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ElevatedButton(
                  onPressed: onAdd,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(15),
                      backgroundColor: AppColors.forestGreen,
                      shape: const CircleBorder()),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (sources.isNotEmpty)
          BarkCard(
            label: 'Roots feeding the tree',
            icon: Icons.water_drop,
            accent: AppColors.lightLeaf,
            child: Column(
              children: [
                ...sources.asMap().entries.map((entry) {
                  final i = entry.key;
                  final s = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.riverBlue
                                .withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.water_drop_outlined,
                              color: AppColors.riverBlue, size: 14),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(s.name,
                              style: GoogleFonts.nunito(
                                  color: AppColors.stoneBeigeColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                        ),
                        Text(
                          '\$${s.amount.toStringAsFixed(2)}',
                          style: GoogleFonts.nunito(
                            color: AppColors.lightLeaf,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close,
                              size: 16,
                              color: AppColors.stoneBeigeColor
                                  .withValues(alpha: 0.45)),
                          onPressed: () => onRemove(i),
                        ),
                      ],
                    ),
                  );
                }),
                Divider(
                    color: AppColors.mossGreen.withValues(alpha: 0.3),
                    height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total monthly income',
                        style: GoogleFonts.nunito(
                            color: AppColors.mossGreen, fontSize: 12.5)),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: GoogleFonts.fredoka(
                        fontWeight: FontWeight.w600,
                        color: AppColors.lightLeaf,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// Step 2 – Expenses
// ──────────────────────────────────────────────

class _ExpenseStep extends StatelessWidget {
  final List<ExpenseCategory> expenses;
  final TextEditingController nameCtrl;
  final TextEditingController amountCtrl;
  final String selectedIconKey;
  final double totalIncome;
  final double totalAllocated;
  final List<(String, String)> presets;
  final VoidCallback onAdd;
  final void Function(int) onRemove;
  final void Function(String name, String iconKey) onPresetTap;

  const _ExpenseStep({
    super.key,
    required this.expenses,
    required this.nameCtrl,
    required this.amountCtrl,
    required this.selectedIconKey,
    required this.totalIncome,
    required this.totalAllocated,
    required this.presets,
    required this.onAdd,
    required this.onRemove,
    required this.onPresetTap,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = totalIncome - totalAllocated;
    final overBudget = remaining < 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        // Budget meter
        BarkCard(
          label: 'Canopy meter',
          icon: Icons.donut_large,
          accent: overBudget ? AppColors.dangerRed : AppColors.lightLeaf,
          child: Column(
            children: [
              _BudgetBar(
                  totalIncome: totalIncome, totalAllocated: totalAllocated),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Allocated: \$${totalAllocated.toStringAsFixed(2)}',
                      style: GoogleFonts.nunito(
                          color: AppColors.stoneBeigeColor, fontSize: 12)),
                  Text(
                    overBudget
                        ? 'Over by \$${(-remaining).toStringAsFixed(2)}'
                        : 'Remaining: \$${remaining.toStringAsFixed(2)}',
                    style: GoogleFonts.nunito(
                      color: overBudget
                          ? AppColors.dangerRed
                          : AppColors.lightLeaf,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Presets card
        BarkCard(
          label: 'Pick a branch',
          icon: Icons.account_tree_outlined,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: presets.map((p) {
              final (iconKey, name) = p;
              final isSelected = selectedIconKey == iconKey;
              return GestureDetector(
                onTap: () => onPresetTap(name, iconKey),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.forestGreen.withValues(alpha: 0.45)
                        : AppColors.soilMid,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.lightLeaf
                          : AppColors.mossGreen.withValues(alpha: 0.4),
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.lightLeaf
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CategoryIcons.forKey(iconKey),
                          size: 15,
                          color: isSelected
                              ? AppColors.lightLeaf
                              : AppColors.mossGreen),
                      const SizedBox(width: 6),
                      Text(
                        name,
                        style: GoogleFonts.nunito(
                          color: isSelected
                              ? AppColors.lightLeaf
                              : AppColors.stoneBeigeColor,
                          fontSize: 12.5,
                          fontWeight: isSelected
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
        // Add a branch card
        BarkCard(
          label: 'Add a branch',
          icon: Icons.add_circle_outline,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: AppColors.stoneBeigeColor),
                  decoration:
                      const InputDecoration(labelText: 'Category name'),
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: amountCtrl,
                  style: const TextStyle(color: AppColors.stoneBeigeColor),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                  ],
                  decoration: const InputDecoration(labelText: 'Amount \$'),
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ElevatedButton(
                  onPressed: onAdd,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(15),
                      backgroundColor: AppColors.forestGreen,
                      shape: const CircleBorder()),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (expenses.isNotEmpty)
          BarkCard(
            label: 'Branches reaching out',
            icon: Icons.spa_outlined,
            child: Column(
              children: expenses.asMap().entries.map((entry) {
                final i = entry.key;
                final exp = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.forestGreen
                              .withValues(alpha: 0.20),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(CategoryIcons.forKey(exp.emoji),
                            color: AppColors.lightLeaf, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(exp.name,
                            style: GoogleFonts.nunito(
                              color: AppColors.stoneBeigeColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                      Text(
                        '\$${exp.allocated.toStringAsFixed(2)}',
                        style: GoogleFonts.nunito(
                            color: AppColors.lightLeaf,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                      IconButton(
                        icon: Icon(Icons.close,
                            size: 16,
                            color: AppColors.stoneBeigeColor
                                .withValues(alpha: 0.45)),
                        onPressed: () => onRemove(i),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _BudgetBar extends StatelessWidget {
  final double totalIncome;
  final double totalAllocated;
  const _BudgetBar(
      {required this.totalIncome, required this.totalAllocated});

  @override
  Widget build(BuildContext context) {
    final pct = totalIncome > 0
        ? (totalAllocated / totalIncome).clamp(0.0, 1.0)
        : 0.0;
    final overBudget = totalAllocated > totalIncome;
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(
        value: pct,
        minHeight: 10,
        backgroundColor: AppColors.darkBark,
        valueColor: AlwaysStoppedAnimation(
          overBudget
              ? AppColors.dangerRed
              : pct > 0.85
                  ? AppColors.warningAmber
                  : AppColors.forestGreen,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Step 3 – Personal info
// ──────────────────────────────────────────────

class _PersonalStep extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController ageCtrl;
  final String? jurisdictionCode;
  final PayFrequency? payFrequency;
  final DateTime? firstPayDate;
  final double monthlyGross;
  final ValueChanged<String?> onJurisdictionChanged;
  final ValueChanged<PayFrequency?> onFrequencyChanged;
  final ValueChanged<DateTime?> onFirstPayDateChanged;

  const _PersonalStep({
    super.key,
    required this.nameCtrl,
    required this.ageCtrl,
    required this.jurisdictionCode,
    required this.payFrequency,
    required this.firstPayDate,
    required this.monthlyGross,
    required this.onJurisdictionChanged,
    required this.onFrequencyChanged,
    required this.onFirstPayDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final jur = jurisdictionCode != null ? findJurisdiction(jurisdictionCode) : null;
    final taxEstimate = TaxCalculator.estimate(
      monthlyGross: monthlyGross,
      location: jur?.code,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        // Identity card
        BarkCard(
          label: 'Identity',
          icon: Icons.fingerprint,
          child: Column(
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: AppColors.stoneBeigeColor),
                decoration: const InputDecoration(
                  labelText: 'Budget name',
                  hintText: 'e.g. January Budget',
                  prefixIcon: Icon(Icons.park, color: AppColors.mossGreen),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: ageCtrl,
                style: const TextStyle(color: AppColors.stoneBeigeColor),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Age',
                  hintText: 'e.g. 25',
                  prefixIcon: Icon(Icons.person_outline,
                      color: AppColors.mossGreen),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: jurisdictionCode,
                isExpanded: true,
                dropdownColor: AppColors.darkBark,
                style: const TextStyle(color: AppColors.stoneBeigeColor),
                decoration: const InputDecoration(
                  labelText: 'Province / State',
                  prefixIcon: Icon(Icons.location_on_outlined,
                      color: AppColors.mossGreen),
                ),
                items: jurisdictions.map((j) {
                  final flag = j.country == 'CA' ? 'CA' : 'US';
                  return DropdownMenuItem(
                    value: j.code,
                    child: Text('$flag · ${j.name}',
                        style: const TextStyle(
                            color: AppColors.stoneBeigeColor, fontSize: 13)),
                  );
                }).toList(),
                onChanged: onJurisdictionChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (taxEstimate.hasData)
          BarkCard(
            label: 'Tax estimate',
            icon: Icons.calculate_outlined,
            accent: AppColors.warningAmber,
            child: _TaxEstimateCard(estimate: taxEstimate),
          ),
        if (taxEstimate.hasData) const SizedBox(height: 14),
        // Pay schedule card
        BarkCard(
          label: 'Pay schedule',
          icon: Icons.event_repeat_outlined,
          accent: AppColors.riverBlue,
          child: Column(
            children: [
              DropdownButtonFormField<PayFrequency>(
                initialValue: payFrequency,
                isExpanded: true,
                dropdownColor: AppColors.darkBark,
                style: const TextStyle(color: AppColors.stoneBeigeColor),
                decoration: const InputDecoration(
                  labelText: 'Pay frequency',
                  prefixIcon: Icon(Icons.event_repeat_outlined,
                      color: AppColors.mossGreen),
                ),
                items: PayFrequency.values
                    .map((f) => DropdownMenuItem(
                          value: f,
                          child: Text(f.label,
                              style: const TextStyle(
                                  color: AppColors.stoneBeigeColor,
                                  fontSize: 13)),
                        ))
                    .toList(),
                onChanged: onFrequencyChanged,
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: firstPayDate ?? now,
                    firstDate: DateTime(now.year - 2),
                    lastDate: DateTime(now.year + 2),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppColors.lightLeaf,
                          onPrimary: Colors.white,
                          surface: AppColors.darkBark,
                          onSurface: AppColors.stoneBeigeColor,
                        ),
                        dialogTheme: const DialogThemeData(
                            backgroundColor: AppColors.darkBark),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) onFirstPayDateChanged(picked);
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.soilMid,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color:
                            AppColors.mossGreen.withValues(alpha: 0.40)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: AppColors.mossGreen, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          firstPayDate == null
                              ? 'First pay date'
                              : 'First pay: ${_formatDate(firstPayDate!)}',
                          style: TextStyle(
                            color: firstPayDate == null
                                ? AppColors.stoneBeigeColor
                                    .withValues(alpha: 0.5)
                                : AppColors.stoneBeigeColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (firstPayDate != null)
                        IconButton(
                          onPressed: () => onFirstPayDateChanged(null),
                          icon: Icon(Icons.close,
                              size: 16,
                              color: AppColors.mossGreen
                                  .withValues(alpha: 0.6)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        BarkCard(
          accent: AppColors.riverBlue,
          padding: const EdgeInsets.all(14),
          showAccentStrip: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline,
                  color: AppColors.riverBlue, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tax brackets are bundled into the app (2024 data) so they work offline. After saving, the budget tree lets you process pay cycles to feed linked goals.',
                  style: GoogleFonts.nunito(
                      color: AppColors.stoneBeigeColor,
                      fontSize: 12,
                      height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _formatDate(DateTime d) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _TaxEstimateCard extends StatelessWidget {
  final TaxEstimate estimate;
  const _TaxEstimateCard({required this.estimate});

  @override
  Widget build(BuildContext context) {
    final pct = (estimate.effectiveRate * 100).toStringAsFixed(1);
    final marg = (estimate.marginalRate * 100).toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row('Annual gross', '\$${estimate.annualGross.toStringAsFixed(0)}'),
        _row('Annual tax', '\$${estimate.annualTax.toStringAsFixed(0)}'),
        _row('Annual net', '\$${estimate.annualNet.toStringAsFixed(0)}',
            accent: true),
        Divider(
            color: AppColors.mossGreen.withValues(alpha: 0.30), height: 18),
        _row('Monthly net', '\$${estimate.monthlyNet.toStringAsFixed(2)}',
            accent: true),
        const SizedBox(height: 8),
        Text(
          'Effective $pct%  ·  Marginal $marg%',
          style: GoogleFonts.nunito(
              color: AppColors.mossGreen, fontSize: 11),
        ),
      ],
    );
  }

  Widget _row(String label, String value, {bool accent = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.nunito(
                  color: AppColors.mossGreen, fontSize: 12.5)),
          Text(value,
              style: GoogleFonts.nunito(
                  color: accent
                      ? AppColors.lightLeaf
                      : AppColors.stoneBeigeColor,
                  fontSize: 13.5,
                  fontWeight:
                      accent ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Bottom navigation bar
// ──────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final int step;
  final bool canAdvance;
  final VoidCallback onNext;

  const _BottomBar(
      {required this.step,
      required this.canAdvance,
      required this.onNext});

  @override
  Widget build(BuildContext context) {
    final isLast = step == 2;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: canAdvance
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
            color: canAdvance
                ? Colors.white.withValues(alpha: 0.5)
                : AppColors.mossGreen.withValues(alpha: 0.2),
            width: canAdvance ? 1.6 : 1,
          ),
          boxShadow: canAdvance
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
            onTap: canAdvance ? onNext : null,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isLast ? Icons.park : Icons.arrow_forward,
                    color: canAdvance
                        ? Colors.white
                        : AppColors.stoneBeigeColor.withValues(alpha: 0.5),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isLast ? 'Plant My Budget Tree' : 'Next',
                    style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.w600,
                      color: canAdvance
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
