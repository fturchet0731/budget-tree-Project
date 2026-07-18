import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../services/reflection_service.dart';
import '../theme/app_dims.dart';
import '../theme/app_tokens.dart';
import 'ui/pressable.dart';

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
        title: Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: AppTokens.current.accentStrong,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                r.period == 'monthly'
                    ? l.reflectionMonthlyTitle
                    : l.reflectionWeeklyTitle,
              ),
            ),
          ],
        ),
        content: Text(r.text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.close),
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
    final t = AppTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: PressableScale(
        onTap: _open,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: t.accentTint,
            borderRadius: BorderRadius.circular(AppDims.rInner),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: t.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.auto_awesome,
                    color: t.accentStrong, size: 17),
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
                        color: t.accentStrong,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      r.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        color: t.textPrimary,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: t.textTertiary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
