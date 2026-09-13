import 'ai_coach_service.dart';
import 'app_settings.dart';
import 'auth_service.dart';
import 'reflection_stats.dart';
import 'supabase_config.dart';

/// One turn of the conversation with Acorn.
class AcornMessage {
  final int id;
  final bool fromUser;
  final String body;
  final DateTime sentAt;

  const AcornMessage({
    required this.id,
    required this.fromUser,
    required this.body,
    required this.sentAt,
  });

  factory AcornMessage.fromRow(Map<String, dynamic> r) => AcornMessage(
        id: r['id'] as int,
        fromUser: (r['role'] as String?) != 'assistant',
        body: (r['body'] as String?) ?? '',
        sentAt: DateTime.tryParse(r['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// The saved conversation with Acorn.
///
/// **This service never writes a message.** Both turns are inserted by the
/// `ai-coach` edge function under the service role, and the table's RLS has no
/// client insert policy at all. That is what makes the stored transcript
/// trustworthy as prompt context: the function reads the history back from the
/// database rather than accepting it from the request body, so a client cannot
/// forge an assistant turn to steer the model. Sending is therefore just the
/// function call; the rows appear as a side effect of it succeeding.
///
/// Online-only and gated exactly like the rest of the AI layer.
class AcornChatService {
  AcornChatService._();
  static final AcornChatService instance = AcornChatService._();

  static const _table = 'acorn_messages';

  /// Mirrored by the `acorn_messages_body_len` check constraint. The edge
  /// function truncates to a smaller bound before the model sees it.
  static const maxLength = 2000;

  bool get isAvailable =>
      SupabaseConfig.isConfigured &&
      AuthService.instance.isSignedIn &&
      AppSettings.instance.aiCoachEnabled;

  /// The conversation so far, oldest first.
  Future<List<AcornMessage>> thread({int limit = 100}) async {
    if (!isAvailable) return const [];
    final rows = await SupabaseConfig.client
        .from(_table)
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    final list = rows.map<AcornMessage>(AcornMessage.fromRow).toList();
    return list.reversed.toList();
  }

  /// Ask Acorn something. Throws [AiUnavailable] on any failure, like every
  /// other coach call, so the screen can fall back rather than hang.
  Future<String> send(String message) async {
    if (!isAvailable) throw AiUnavailable('Acorn chat unavailable');
    return AiCoachService.instance.acornChat(
      message: message,
      context: await _context(),
    );
  }

  /// Wipe the conversation. The delete policy is the one write a client is
  /// allowed on this table.
  Future<void> clear() async {
    if (!isAvailable) return;
    final uid = AuthService.instance.userId;
    if (uid == null) return;
    await SupabaseConfig.client.from(_table).delete().eq('user_id', uid);
  }

  /// A compact snapshot of the user's own figures, so Acorn answers about
  /// their budget rather than in generalities. Already summarised, and bounded
  /// on the server as well.
  Future<Map<String, dynamic>> _context() async {
    final stats = await ReflectionStats.load();
    return {
      'health': stats.health.score.round(),
      'healthTier': stats.health.tier.name,
      'streakWeeks': stats.streak.currentWeeks,
      'checkInsAnswered': stats.answered,
      'checkInsMissed': stats.missed,
      'overspend': [
        for (final o in stats.overspend.take(8))
          {
            'name': o.name,
            'planned': o.planned.round(),
            'actual': o.actual.round(),
          },
      ],
    };
  }
}
