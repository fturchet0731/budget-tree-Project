import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_tokens.dart';

class ViewBudgetsScreen extends StatelessWidget {
  const ViewBudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(l.myBudgets)),
      body: Container(
        color: AppTokens.current.canvas,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🌳', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 16),
              Text(
                l.noBudgetsTitle,
                style: TextStyle(
                  color: AppTokens.current.textPrimary,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.noBudgetsBody,
                style: TextStyle(
                    color: AppTokens.current.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
