import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../models/friendship_model.dart';
import '../screens/friend_garden_screen.dart';
import '../screens/friends_screen.dart';
import '../services/friends_service.dart';
import '../theme/app_tokens.dart';
import 'profile_avatar.dart';
import 'ui/entrance.dart';
import 'ui/pressable.dart';

/// The dashboard's horizontal friends row: a swipeable strip of avatar
/// circles, Roblox style. The first circle is always "Add friends" (opens
/// [FriendsScreen]) and carries a tally badge — "active/total" when any
/// friend is active now, else just the total. Each friend circle opens their
/// garden; under the circle sits a green "active now" dot to the LEFT of the
/// name and their goal status emoji to the RIGHT. Collapses to just the Add
/// circle while loading, offline, or signed out, so the row is always a
/// stable entry point into the social layer.
class FriendsStrip extends StatefulWidget {
  const FriendsStrip({super.key});

  @override
  State<FriendsStrip> createState() => FriendsStripState();
}

class FriendsStripState extends State<FriendsStrip> {
  List<FriendSummary> _friends = const [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  /// Reload friend summaries. The dashboard calls this after navigations that
  /// could change friendships (and on first build). Silent on failure — the
  /// strip just keeps showing what it had.
  Future<void> refresh() async {
    if (!FriendsService.instance.isAvailable) {
      if (mounted && !_loaded) setState(() => _loaded = true);
      return;
    }
    try {
      final friends = await FriendsService.instance.friendSummaries();
      if (!mounted) return;
      setState(() {
        _friends = friends;
        _loaded = true;
      });
    } catch (_) {
      if (mounted && !_loaded) setState(() => _loaded = true);
    }
  }

  Future<void> _openFriends() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FriendsScreen()),
    );
    await refresh();
  }

  Future<void> _openGarden(FriendSummary f) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FriendGardenScreen(
          profile: f.profile,
          statusEmoji: f.statusEmoji,
          sharedGoals: f.sharedGoals,
        ),
      ),
    );
    await refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final active = _friends.where((f) => f.profile.isActive).length;
    final total = _friends.length;
    final bubbles = [
      Entrance(
        child: _AddFriendsBubble(
          label: l.addFriends,
          badge: total == 0 ? null : (active > 0 ? '$active/$total' : '$total'),
          badgeIsActive: active > 0,
          onTap: _openFriends,
        ),
      ),
      for (var i = 0; i < _friends.length; i++)
        Entrance(
          delay: Duration(milliseconds: 60 * (i + 1)),
          child: _FriendBubble(
            summary: _friends[i],
            onTap: () => _openGarden(_friends[i]),
          ),
        ),
    ];
    // Centered while the circles fit the row; swipeable once they overflow.
    return SizedBox(
      height: 118,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth - 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: bubbles,
            ),
          ),
        ),
      ),
    );
  }
}

const double _circle = 72;

/// The leading "Add friends" circle with the tally badge over its top right.
class _AddFriendsBubble extends StatelessWidget {
  const _AddFriendsBubble({
    required this.label,
    required this.onTap,
    this.badge,
    this.badgeIsActive = false,
  });

  final String label;
  final VoidCallback onTap;
  final String? badge;
  final bool badgeIsActive;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return _Bubble(
      onTap: onTap,
      circle: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: _circle,
            height: _circle,
            decoration: BoxDecoration(
              color: t.canvasSoft,
              border: Border.all(color: t.cardBorder, width: 1.5),
            ),
            child: Icon(Icons.person_add_alt_1, color: t.textSecondary, size: 30),
          ),
          if (badge != null)
            Positioned(
              top: -4,
              right: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeIsActive ? const Color(0xFF3BA55D) : t.accent,
                  borderRadius: BorderRadius.zero,
                  border: Border.all(color: t.canvas, width: 2),
                ),
                child: Text(
                  badge!,
                  style: GoogleFonts.nunito(
                    color: t.onAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
      caption: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.nunito(
          color: AppTokens.of(context).textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// One friend: ringed avatar circle, then [active dot] name [status emoji].
class _FriendBubble extends StatelessWidget {
  const _FriendBubble({required this.summary, required this.onTap});

  final FriendSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final active = summary.profile.isActive;
    return _Bubble(
      onTap: onTap,
      circle: Container(
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          border: Border.all(
            color: active ? const Color(0xFF3BA55D) : t.accentSoft,
            width: 2,
          ),
        ),
        child: ProfileAvatar(profile: summary.profile, size: _circle - 9),
      ),
      caption: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (active) ...[
            Semantics(
              label: AppLocalizations.of(context).activeNow,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF3BA55D),
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              summary.profile.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                color: t.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (summary.statusEmoji.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(summary.statusEmoji, style: const TextStyle(fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

/// Shared circle+caption column with the press micro-animation.
class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.circle,
    required this.caption,
    required this.onTap,
  });

  final Widget circle;
  final Widget caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: PressableScale(
        onTap: onTap,
        child: SizedBox(
          width: 86,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              circle,
              const SizedBox(height: 6),
              caption,
            ],
          ),
        ),
      ),
    );
  }
}
