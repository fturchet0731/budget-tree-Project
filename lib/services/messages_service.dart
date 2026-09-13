import 'auth_service.dart';
import 'supabase_config.dart';

/// One chat message between two friends.
class ChatMessage {
  final int id;
  final String senderId;
  final String body;
  final DateTime sentAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.body,
    required this.sentAt,
  });

  bool get isMine => senderId == AuthService.instance.userId;

  factory ChatMessage.fromRow(Map<String, dynamic> r) => ChatMessage(
        id: r['id'] as int,
        senderId: r['sender'] as String,
        body: r['body'] as String,
        sentAt: DateTime.tryParse(r['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// Minimal 1:1 messaging between accepted friends. Online-only like the rest
/// of the social layer. RLS guarantees a user only ever reads their own
/// conversations and can only send to accepted friends; bodies are capped at
/// [maxLength] chars both here and by a database check constraint.
class MessagesService {
  MessagesService._();
  static final MessagesService instance = MessagesService._();

  static const _table = 'messages';

  /// Mirrored by the `messages_body_len` check constraint.
  static const maxLength = 500;

  bool get isAvailable =>
      SupabaseConfig.isConfigured && AuthService.instance.isSignedIn;

  String? get _uid => AuthService.instance.userId;

  /// The latest [limit] messages between me and [otherUserId], oldest first
  /// (ready for a chat column).
  Future<List<ChatMessage>> thread(String otherUserId, {int limit = 100}) async {
    if (!isAvailable) return const [];
    final me = _uid!;
    final rows = await SupabaseConfig.client
        .from(_table)
        .select()
        .or('and(sender.eq.$me,recipient.eq.$otherUserId),'
            'and(sender.eq.$otherUserId,recipient.eq.$me)')
        .order('created_at', ascending: false)
        .limit(limit);
    final list =
        rows.map<ChatMessage>((r) => ChatMessage.fromRow(r)).toList();
    return list.reversed.toList();
  }

  /// Send [body] to [otherUserId]. Blank bodies are dropped; long ones are
  /// trimmed to [maxLength] before the DB constraint would reject them.
  Future<void> send(String otherUserId, String body) async {
    final text = body.trim();
    if (!isAvailable || text.isEmpty) return;
    await SupabaseConfig.client.from(_table).insert({
      'sender': _uid,
      'recipient': otherUserId,
      'body': text.length > maxLength ? text.substring(0, maxLength) : text,
    });
  }
}
