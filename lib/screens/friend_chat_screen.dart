import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../models/profile_model.dart';
import '../services/messages_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/ui/pressable.dart';

/// 1:1 chat with an accepted friend. Deliberately simple: the latest slice of
/// the thread, newest at the bottom, with a composer. While the screen is
/// open it polls every few seconds so replies appear without a manual
/// refresh (no realtime socket needed for a two-person thread).
class FriendChatScreen extends StatefulWidget {
  const FriendChatScreen({super.key, required this.friend});

  final Profile friend;

  @override
  State<FriendChatScreen> createState() => _FriendChatScreenState();
}

class _FriendChatScreenState extends State<FriendChatScreen> {
  final _composer = TextEditingController();
  final _scroll = ScrollController();
  List<ChatMessage> _messages = const [];
  bool _loaded = false;
  bool _sending = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _refresh();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final msgs = await MessagesService.instance.thread(widget.friend.id);
      if (!mounted) return;
      final grew = msgs.length > _messages.length;
      setState(() {
        _messages = msgs;
        _loaded = true;
      });
      if (grew) _jumpToEnd();
    } catch (_) {
      if (mounted && !_loaded) setState(() => _loaded = true);
    }
  }

  void _jumpToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final text = _composer.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await MessagesService.instance.send(widget.friend.id, text);
      _composer.clear();
      await _refresh();
    } catch (_) {
      // Leave the text in the composer so the user can retry.
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = AppTokens.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProfileAvatar(profile: widget.friend, size: 32),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                widget.friend.label,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        foregroundColor: AppColors.stoneBeigeColor,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: !_loaded
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              l.chatEmpty,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunito(
                                color: t.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          itemCount: _messages.length,
                          itemBuilder: (ctx, i) =>
                              _MessageBubble(message: _messages[i]),
                        ),
            ),
            // Composer.
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _composer,
                      maxLength: MessagesService.maxLength,
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: l.chatHint,
                        counterText: '',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    button: true,
                    label: l.chatSend,
                    child: PressableScale(
                      onTap: _send,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: t.accent,
                          shape: BoxShape.circle,
                        ),
                        child: _sending
                            ? Padding(
                                padding: const EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: t.onAccent,
                                ),
                              )
                            : Icon(Icons.send_rounded,
                                color: t.onAccent, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final mine = message.isMine;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.74,
        ),
        decoration: BoxDecoration(
          color: mine ? t.accent : t.card,
          border: mine ? null : Border.all(color: t.cardBorder),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 6),
            bottomRight: Radius.circular(mine ? 6 : 18),
          ),
        ),
        child: Text(
          message.body,
          style: GoogleFonts.nunito(
            color: mine ? t.onAccent : t.textPrimary,
            fontSize: 14,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}
