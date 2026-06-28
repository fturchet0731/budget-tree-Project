import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../services/reflection_service.dart';
import '../theme/app_theme.dart';

/// Compact banner shown on the dashboard surfacing the latest AI reflection
/// ("Your week in the forest"). Tapping it opens the full text. Renders nothing
/// when there's no cached reflection, so it stays invisible until the coach has
/// something to say. Self-contained: it reads [ReflectionService.latest].
class ReflectionBanner extends StatefulWidget {
  const ReflectionBanner({super.key});

  @override
  State<ReflectionBanner> createState() => _ReflectionBannerState();
}

class _ReflectionBannerState extends State<ReflectionBanner> {
  Reflection? _reflection;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await ReflectionService.instance.latest();
    if (mounted) setState(() => _reflection = r);
  }

  void _open() {
    final r = _reflection;
    if (r == null) return;
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D2410),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(
              Icons.auto_awesome,
              color: AppColors.lightLeaf,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                r.period == 'monthly'
                    ? l.reflectionMonthlyTitle
                    : l.reflectionWeeklyTitle,
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.w600,
                  color: AppColors.stoneBeigeColor,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          r.text,
          style: GoogleFonts.nunito(
            color: AppColors.stoneBeigeColor,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l.close,
              style: const TextStyle(color: AppColors.lightLeaf),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = _reflection;
    if (r == null) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: GestureDetector(
        onTap: _open,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.lightLeaf.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: AppColors.lightLeaf,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.period == 'monthly'
                          ? l.reflectionMonthlyTitle
                          : l.reflectionWeeklyTitle,
                      style: GoogleFonts.nunito(
                        color: AppColors.lightLeaf,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      r.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        color: AppColors.stoneBeigeColor,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.mossGreen,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
