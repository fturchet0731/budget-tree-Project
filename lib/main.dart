import 'dart:async';
import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'services/app_settings.dart';
import 'services/auth_service.dart';
import 'services/notification_scheduler.dart';
import 'services/notification_service.dart';
import 'services/supabase_config.dart';
import 'services/sync_engine.dart';
import 'theme/app_theme.dart';
import 'widgets/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init();
  AuthService.instance.start();
  SyncEngine.init();
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
          // Language: follow the user's choice from Settings, or the device
          // language when they haven't picked one (locale == null).
          locale: settings.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(settings.textScaleFactor),
              ),
              child: child!,
            );
          },
          home: const AuthGate(),
        );
      },
    );
  }
}
