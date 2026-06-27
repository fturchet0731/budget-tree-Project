import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class ViewBudgetsScreen extends StatelessWidget {
  const ViewBudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.stoneBeigeColor,
        title: Text(l.myBudgets),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppPalettes.deepForest()),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🌳', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 16),
              Text(
                l.noBudgetsTitle,
                style: const TextStyle(
                  color: AppColors.stoneBeigeColor,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.noBudgetsBody,
                style: const TextStyle(
                    color: AppColors.mossGreen, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
