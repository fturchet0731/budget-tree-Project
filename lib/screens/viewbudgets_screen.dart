import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ViewBudgetsScreen extends StatelessWidget {
  const ViewBudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Budgets')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🌳', style: TextStyle(fontSize: 60)),
            SizedBox(height: 16),
            Text(
              'No saved budgets yet',
              style: TextStyle(
                color: AppColors.stoneBeigeColor,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Create one from the dashboard',
              style: TextStyle(color: AppColors.mossGreen, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
