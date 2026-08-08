import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../services/acorn_chat_service.dart';
import '../services/ai_coach_service.dart';
import '../theme/app_dims.dart';
import '../theme/app_shadows.dart';
import '../theme/app_tokens.dart';
import '../widgets/acorn_mascot.dart';
import '../widgets/skeleton.dart';
import '../widgets/ui/pressable.dart';

/// Talking to Acorn.
///
/// Deliberately shaped like [FriendChatScreen] rather than a chatbot panel:
/// Acorn is a character in this app, and a conversation with him should feel
/// like the ones with friends. No polling, because the only other participant
/// answers synchronously.
class AcornChatScreen extends StatefulWidget {
  /// Pre-fills the composer, used by the reflection story's "ask about this"
  /// buttons so a suggestion carries its own context into the conversation.
  final String opener;

  const AcornChatScreen({super.key, this.opener = ''});

  @override
  State<AcornChatScreen> createState() => _AcornChatScreenState();
}

class _AcornChatScreenState extends State<AcornChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  List<AcornMessage>? _messages;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final thread = await AcornChatService.instance.thread();
      if (!mounted) return;
      setState(() => _messages = thread);
      _toBottom();
    } catch (_) {
      if (mounted) setState(() => _messages = const []);
    }
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
      // Show the user's own turn straight away. The authoritative rows are
      // written server-side, so this optimistic one is replaced on reload.
      _messages = [
        ...?_messages,
        AcornMessage(
          id: -DateTime.now().millisecondsSinceEpoch,
          fromUser: true,
          body: text,
          sentAt: DateTime.now(),
        ),
      ];
      _input.clear();
    });
    _toBottom();

    try {
      await AcornChatService.instance.send(text);
      await _load();
    } on AiUnavailable {
      if (!mounted) return;
      setState(() => _error = AppLocalizations.of(context).hubChatFailed);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = AppTokens.of(context);
    final messages = _messages;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.hubTalkTitle),
        actions: [
          if (messages != null && messages.isNotEmpty)
            IconButton(
              tooltip: l.hubChatClear,
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                await AcornChatService.instance.clear();
                await _load();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: messages == null
                  ? const Padding(
                      padding: EdgeInsets.all(AppDims.s20),
                      child: FriendsSkeleton(),
                    )
                  : messages.isEmpty
                      ? _Opening(onPick: _send)
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          itemCount: messages.length,
                          itemBuilder: (_, i) => _Bubble(message: messages[i]),
                        ),
            ),
            if (_sending)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AcornMascot(size: 32, speaking: true),
                    const SizedBox(width: 8),
                    Text(
                      l.hubChatThinking,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                child: Text(
                  _error!,
                  style: GoogleFonts.nunito(color: t.danger, fontSize: 13),
                ),
              ),
            _Composer(
              controller: _input,
              enabled: !_sending,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

/// The empty state: suggested openers, because a blank composer next to a
/// mascot is a hard thing to start.
class _Opening extends StatelessWidget {
  final ValueChanged<String> onPick;
  const _Opening({required this.onPick});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = AppTokens.of(context);
    final prompts = [
      l.hubChatPrompt1,
      l.hubChatPrompt2,
      l.hubChatPrompt3,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDims.s24),
      child: Column(
        children: [
          const AcornMascot(size: 96),
          const SizedBox(height: AppDims.s12),
          Text(
            l.hubChatGreeting,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            l.hubChatGreetingSub,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppDims.s24),
          for (final p in prompts)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDims.s8),
              child: PressableScale(
                onTap: () => onPick(p),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: t.accentTint,
                    borderRadius: BorderRadius.circular(AppDims.rInner),
                    border: Border.all(color: t.cardBorder),
                  ),
                  child: Text(
                    p,
                    style: GoogleFonts.nunito(
                      color: t.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final AcornMessage message;
  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final mine = message.fromUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDims.s8),
      child: Row(
        mainAxisAlignment:
            mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!mine) ...[
            const AcornMascot(size: 30, sway: false),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: mine ? t.accent : t.card,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(mine ? 16 : 4),
                  bottomRight: Radius.circular(mine ? 4 : 16),
                ),
                border: mine ? null : Border.all(color: t.cardBorder),
                boxShadow: mine ? null : AppShadows.card,
              ),
              child: Text(
                message.body,
                style: GoogleFonts.nunito(
                  color: mine ? t.onAccent : t.textPrimary,
                  fontSize: 14.5,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String?> onSend;

  const _Composer({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = AppTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              minLines: 1,
              maxLines: 4,
              maxLength: AcornChatService.maxLength,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(null),
              decoration: InputDecoration(
                hintText: l.hubChatHint,
                counterText: '',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: AppDims.s8),
          PressableScale(
            onTap: enabled ? () => onSend(null) : null,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: enabled ? t.accent : t.accentSoft,
                shape: BoxShape.circle,
                boxShadow: enabled ? AppShadows.pill : null,
              ),
              child: Icon(
                Icons.arrow_upward,
                color: enabled ? t.onAccent : t.textTertiary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
