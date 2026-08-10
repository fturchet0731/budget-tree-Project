import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../models/budget_model.dart';
import '../models/check_in.dart';
import '../services/budget_repository.dart';
import '../services/check_in_service.dart';
import '../services/sound_service.dart';
import '../theme/app_dims.dart';
import '../theme/app_tokens.dart';
import 'acorn_mascot.dart';
import 'ui/app_buttons.dart';
import 'ui/pressable.dart';

/// Answering a check-in.
///
/// The whole design rests on the verdict costing exactly one tap. That's what
/// keeps a streak survivable, and a streak is what tree health is made of. The
/// per-branch amounts underneath are genuinely optional and stay collapsed
/// until asked for, but they are also the only plan-versus-actual data the app
/// will ever have, so the affordance is a real invitation rather than a
/// footnote.
///
/// Returns true when the user confirmed.
Future<bool> showCheckInSheet(BuildContext context, CheckIn checkIn) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CheckInSheet(checkIn: checkIn),
  );
  return result ?? false;
}

class _CheckInSheet extends StatefulWidget {
  final CheckIn checkIn;
  const _CheckInSheet({required this.checkIn});

  @override
  State<_CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends State<_CheckInSheet> {
  CheckInVerdict? _verdict;
  bool _showActuals = false;
  bool _saving = false;

  /// Branch name to planned per-cycle amount, in the budget's own order.
  final List<({String name, double planned})> _branches = [];
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    if (widget.checkIn.kind == CheckInKind.payday) _loadBranches();
  }

  Future<void> _loadBranches() async {
    final budgets = await BudgetRepository.loadCached();
    BudgetModel? budget;
    for (final b in budgets) {
      if (b.id == widget.checkIn.subjectId) budget = b;
    }
    if (budget == null || !mounted) return;
    final cycle = budget.payFrequency;
    setState(() {
      for (final e in budget!.expenses) {
        _branches.add((name: e.name, planned: e.allocatedPerCycle(cycle)));
        _controllers[e.name] = TextEditingController();
      }
    });
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Only branches the user actually typed a number into. A blank field means
  /// "I'd rather not say", never zero.
  List<BranchActual> _collectActuals() {
    final out = <BranchActual>[];
    for (final b in _branches) {
      final raw = _controllers[b.name]?.text.trim() ?? '';
      if (raw.isEmpty) continue;
      final value = double.tryParse(raw);
      if (value == null) continue;
      out.add(BranchActual(name: b.name, planned: b.planned, actual: value));
    }
    return out;
  }

  Future<void> _confirm() async {
    final verdict = _verdict;
    if (verdict == null || _saving) return;
    setState(() => _saving = true);
    await CheckInService.confirm(
      widget.checkIn,
      verdict: verdict,
      actuals: _collectActuals(),
    );
    SoundService.fundsAllocated();
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = AppTokens.of(context);
    final isPayday = widget.checkIn.kind == CheckInKind.payday;

    return Padding(
      // Lift the sheet clear of the keyboard while an amount is being typed.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: t.cardBorder,
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const AcornMascot(size: 52, sway: false),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPayday
                              ? l.checkInPaydayTitle(widget.checkIn.subjectName)
                              : l.checkInWateringTitle(
                                  widget.checkIn.subjectName),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDue(context, widget.checkIn.dueAt),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDims.s20),
              Text(
                isPayday ? l.checkInQuestion : l.checkInWateringQuestion,
                style: GoogleFonts.nunito(
                  color: t.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppDims.s12),
              _VerdictRow(
                current: _verdict,
                onChanged: (v) => setState(() => _verdict = v),
              ),
              if (isPayday && _branches.isNotEmpty) ...[
                const SizedBox(height: AppDims.s20),
                PressableScale(
                  onTap: () => setState(() => _showActuals = !_showActuals),
                  child: Row(
                    children: [
                      Icon(
                        _showActuals
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_right,
                        color: t.accentStrong,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          l.checkInAddActuals,
                          style: GoogleFonts.nunito(
                            color: t.accentStrong,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Text(
                    l.checkInActualsHelp,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (_showActuals) ...[
                  const SizedBox(height: AppDims.s12),
                  for (final b in _branches)
                    _BranchRow(
                      name: b.name,
                      planned: b.planned,
                      controller: _controllers[b.name]!,
                    ),
                ],
              ],
              const SizedBox(height: AppDims.s24),
              AppPrimaryButton(
                label: l.checkInConfirm,
                onPressed: _verdict == null || _saving ? null : _confirm,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDue(BuildContext context, DateTime due) =>
      MaterialLocalizations.of(context).formatFullDate(due);
}

/// Three verdicts, each in its own colour. A [SegmentedChoice] can't carry the
/// green-to-red reading, and there is deliberately no default selection: the
/// user has to say something, so a mis-tap can't be recorded as an answer.
class _VerdictRow extends StatelessWidget {
  final CheckInVerdict? current;
  final ValueChanged<CheckInVerdict> onChanged;

  const _VerdictRow({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = AppTokens.of(context);
    final options = <(CheckInVerdict, String, Color, IconData)>[
      (CheckInVerdict.onTrack, l.checkInOnTrack, t.success,
          Icons.sentiment_satisfied_alt),
      (CheckInVerdict.slipped, l.checkInSlipped, t.warning,
          Icons.sentiment_neutral),
      (CheckInVerdict.offPlan, l.checkInOffPlan, t.danger,
          Icons.sentiment_dissatisfied),
    ];

    return Row(
      children: [
        for (final (verdict, label, colour, icon) in options) ...[
          Expanded(
            child: PressableScale(
              onTap: () => onChanged(verdict),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: current == verdict
                      ? colour.withValues(alpha: 0.16)
                      : t.canvasSoft,
                  borderRadius: BorderRadius.circular(AppDims.rInner),
                  border: Border.all(
                    color: current == verdict ? colour : t.cardBorder,
                    width: current == verdict ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color: current == verdict ? colour : t.textTertiary,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        color:
                            current == verdict ? colour : t.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (verdict != CheckInVerdict.offPlan)
            const SizedBox(width: AppDims.s8),
        ],
      ],
    );
  }
}

class _BranchRow extends StatelessWidget {
  final String name;
  final double planned;
  final TextEditingController controller;

  const _BranchRow({
    required this.name,
    required this.planned,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = AppTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDims.s8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    color: t.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  l.checkInPlanned('\$${planned.toStringAsFixed(0)}'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDims.s12),
          SizedBox(
            width: 104,
            child: TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                hintText: l.checkInActualHint,
                prefixText: '\$',
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
