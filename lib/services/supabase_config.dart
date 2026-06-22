import 'package:supabase_flutter/supabase_flutter.dart';

/// Holds the Supabase connection details and initializes the client once at
/// boot. Credentials are passed at run/build time via `--dart-define` so they
/// never get committed:
///
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi...
///
/// (Or keep them in a gitignored `env.json` and pass
/// `--dart-define-from-file=env.json`.)
///
/// The anon key is *public-safe* — it only grants what Row Level Security
/// allows — so shipping it in the app binary is the intended design.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// True when both values were provided. When false we skip Supabase entirely
  /// and the app runs in pure local-cache mode (handy for tests / first run
  /// before the project is set up).
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  /// Convenience accessor for the singleton client.
  static SupabaseClient get client => Supabase.instance.client;

  /// Initialize the SDK. Safe to call when unconfigured — it just no-ops so
  /// the rest of the app can run offline-only.
  static Future<void> init() async {
    if (!isConfigured) return;
    // `publishableKey` is the current name for what the dashboard historically
    // called the "anon" key; either value works here.
    await Supabase.initialize(url: url, publishableKey: anonKey);
  }
}
