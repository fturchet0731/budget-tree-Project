import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../models/ai_plan.dart';
import '../theme/app_shadows.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import 'ui/pressable.dart';

/// One AI-proposed allocation plan, rendered as a selectable card: the plan
/// name, a one-line rationale, each branch with its dollar amount, and the
/// leftover earmarked for savings/goals. Selected plans get a leafy highlight.
class AllocationPlanCard extends StatelessWidget {
  const AllocationPlanCard({
    super.key,
    required this.plan,
    required this.selected,
    required this.onSelect,
  });

  final AllocationPlan plan;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = AppTokens.of(context);
    return PressableScale(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? t.accentTint : t.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? t.accentStrong : t.cardBorder,
            width: selected ? 2 : 1,
          ),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: selected ? t.accentStrong : t.textTertiary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    plan.name,
                    style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.w600,
                      color: AppColors.stoneBeigeColor,
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),
            if (plan.rationale.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                plan.rationale,
                style: GoogleFonts.nunito(
                  color: AppColors.mossGreen,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 12),
            for (final item in plan.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          color: AppColors.stoneBeigeColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      '\$${item.amount.toStringAsFixed(0)}',
                      style: GoogleFonts.nunito(
                        color: AppColors.forestGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            Divider(
              color: AppColors.mossGreen.withValues(alpha: 0.25),
              height: 18,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.savings_outlined,
                      color: Color(0xFFBA8514),
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l.savingsAndGoals,
                      style: GoogleFonts.nunito(
                        color: AppColors.mossGreen,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
                Text(
                  '\$${plan.leftover.toStringAsFixed(0)}',
                  style: GoogleFonts.fredoka(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFBA8514),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
