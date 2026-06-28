import 'package:flutter/material.dart';

import '../widgets/social_tab_bar.dart';
import 'friends_screen.dart';
import 'profile_screen.dart';

/// Hosts the dashboard's swipe-in social sidebar, flipping between the user's
/// own [ProfileScreen] and their [FriendsScreen] via the in-app-bar
/// [SocialTabBar]. Both children stay alive (IndexedStack) so switching tabs
/// keeps their loaded state and scroll position.
class SocialDrawer extends StatefulWidget {
  const SocialDrawer({super.key, required this.onClose});

  /// Closes the drawer (passed down so each tab shows an X).
  final VoidCallback onClose;

  @override
  State<SocialDrawer> createState() => _SocialDrawerState();
}

class _SocialDrawerState extends State<SocialDrawer> {
  SocialTab _tab = SocialTab.profile;

  void _select(SocialTab tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _tab == SocialTab.profile ? 0 : 1,
      children: [
        ProfileScreen(onClose: widget.onClose, onSelectTab: _select),
        FriendsScreen(onClose: widget.onClose, onSelectTab: _select),
      ],
    );
  }
}
