import 'dart:async';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/app_settings.dart';
import 'services/notification_scheduler.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.instance.load();
  await NotificationService.init();
  // Refresh the recurring reminders in the background so they reflect the
  // latest streak/summary without delaying first paint.
  unawaited(NotificationScheduler.rescheduleAll());
  runApp(const BudgetTreeApp());
}

class BudgetTreeApp extends StatelessWidget {
  const BudgetTreeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppSettings.instance,
      builder: (ctx, _) {
        final settings = AppSettings.instance;
        return MaterialApp(
          title: 'Budget Tree',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme,
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(settings.textScaleFactor),
              ),
              child: child!,
            );
          },
          home: const HomeScreen(),
        );
      },
    );
  }
}
