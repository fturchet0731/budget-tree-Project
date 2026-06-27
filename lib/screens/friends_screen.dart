import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/friendship_model.dart';
import '../models/profile_model.dart';
import '../services/friends_service.dart';
import '../services/goal_repository.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import 'friend_garden_screen.dart';

/// The social hub: claim a username (first time), set how your status emoji is
/// computed, add friends by username, respond to requests, and open a friend's
/// garden. Online-only — when the social layer is unavailable it shows a
/// sign-in / connectivity notice instead of crashing.
class FriendsScreen extends StatefulWidget {
  /// When hosted in the dashboard's swipe-in sidebar, [onClose] closes the
  /// drawer (and replaces the AppBar's automatic back button with an X). Null
  /// when shown as a standalone screen.
  const FriendsScreen({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _search = TextEditingController();

  bool _loading = true;
  Profile? _me;
  List<FriendSummary> _friends = const [];
  List<Profile> _incoming = const [];
  List<Profile> _results = const [];
  bool _searching = false;

  /// Non-null when the last load failed — shown as a retry notice instead of
  /// an endless spinner.
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!ProfileService.instance.isAvailable) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      final me = await ProfileService.instance.myProfile();
      if (me == null) {
        if (mounted) {
          setState(() {
            _me = null;
            _loading = false;
          });
        }
        return;
      }
      final friends = await FriendsService.instance.friendSummaries();
      final incoming = await FriendsService.instance.incomingRequests();
      if (!mounted) return;
      setState(() {
        _me = me;
        _friends = friends;
        _incoming = incoming;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMsg = _messageFor(e);
        });
      }
    }
  }

  /// Turn a thrown error into a friendly line. Postgres `42P01`
  /// (undefined_table) means the social migration hasn't been applied yet —
  /// worth calling out explicitly since this is a dev build.
  String _messageFor(Object e) {
    if (e is PostgrestException && e.code == '42P01') {
      return 'The friends tables aren\'t set up yet. Apply the database '
          'migration with `supabase db push`, then retry.';
    }
    return 'Couldn\'t reach friends. Check your connection and try again.';
  }

  /// Run a mutating action, surfacing failures as a snackbar instead of an
  /// unhandled exception. Returns whether it succeeded.
  Future<bool> _guard(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_messageFor(e))),
        );
      }
      return false;
    }
  }

  Future<void> _runSearch() async {
    final q = _search.text.trim();
    if (q.isEmpty) {
      setState(() => _results = const []);
      return;
    }
    setState(() => _searching = true);
    List<Profile> results = const [];
    final ok = await _guard(
        () async => results = await ProfileService.instance.searchByUsername(q));
    if (!mounted) return;
    setState(() {
      _results = ok ? results : const [];
      _searching = false;
    });
  }

  Future<void> _add(Profile p) async {
    final ok =
        await _guard(() => FriendsService.instance.sendRequest(p.id));
    if (!ok) return;
    _search.clear();
    setState(() => _results = const []);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request sent to @${p.username}')),
      );
    }
    await _load();
  }

  Future<void> _accept(Profile p) async {
    if (await _guard(() => FriendsService.instance.acceptRequest(p.id))) {
      await _load();
    }
  }

  Future<void> _decline(Profile p) async {
    if (await _guard(() => FriendsService.instance.removeFriend(p.id))) {
      await _load();
    }
  }

  Future<void> _openGarden(FriendSummary f) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FriendGardenScreen(
          profile: f.profile,
          statusEmoji: f.statusEmoji,
          sharedGoals: f.sharedGoals,
        ),
      ),
    );
  }

  // -------------------------------------------------- status-mode controls

  Future<void> _changeStatusMode(FriendStatusMode mode) async {
    String? goalId;
    if (mode == FriendStatusMode.goal) {
      goalId = await _pickStatusGoal();
      if (goalId == null) return; // cancelled / no shared goal
    }
    final ok = await _guard(
        () => ProfileService.instance.setStatusMode(mode, goalId: goalId));
    if (ok) await _load();
  }

  Future<String?> _pickStatusGoal() async {
    final goals = (await GoalRepository.loadAll())
        .where((g) => g.sharedWithFriends)
        .toList();
    if (!mounted) return null;
    if (goals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Share a goal with friends first to pin it as your '
              'status.'),
        ),
      );
      return null;
    }
    return showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Pin which goal?'),
        children: [
          for (final g in goals)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, g.id),
              child: Text(g.name),
            ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: widget.onClose == null,
        leading: widget.onClose == null
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onClose,
              ),
        title: const Text('Friends'),
        foregroundColor: AppColors.stoneBeigeColor,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(gradient: AppPalettes.deepForest()),
        child: SafeArea(child: _body()),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.lightLeaf));
    }
    if (!ProfileService.instance.isAvailable) {
      return _notice(
        Icons.cloud_off,
        'Friends need an account',
        'Sign in with an internet connection to add friends and share goals.',
      );
    }
    if (_errorMsg != null) {
      return _notice(
        Icons.wifi_off,
        'Couldn\'t load friends',
        _errorMsg!,
        onRetry: _load,
      );
    }
    if (_me == null) {
      return _ClaimUsername(onClaimed: _load);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _statusCard(),
          const SizedBox(height: 20),
          _addCard(),
          if (_incoming.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionTitle('Requests'),
            for (final p in _incoming) _requestTile(p),
          ],
          const SizedBox(height: 20),
          _sectionTitle('Friends'),
          if (_friends.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No friends yet — add someone by their username.',
                  style: TextStyle(color: AppColors.mossGreen)),
            ),
          for (final f in _friends) _friendTile(f),
        ],
      ),
    );
  }

  Widget _statusCard() {
    return _card(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('You are @${_me!.username}',
                    style: const TextStyle(
                        color: AppColors.stoneBeigeColor,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                const Text('How friends see your status:',
                    style:
                        TextStyle(color: AppColors.mossGreen, fontSize: 12)),
              ],
            ),
          ),
          DropdownButton<FriendStatusMode>(
            value: _me!.statusMode,
            dropdownColor: AppColors.barkBrown,
            iconEnabledColor: AppColors.lightLeaf,
            underline: const SizedBox.shrink(),
            style: const TextStyle(color: AppColors.stoneBeigeColor),
            items: [
              for (final m in FriendStatusMode.values)
                DropdownMenuItem(value: m, child: Text(m.label)),
            ],
            onChanged: (m) {
              if (m != null) _changeStatusMode(m);
            },
          ),
        ],
      ),
    );
  }

  Widget _addCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Add a friend'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  style: const TextStyle(color: AppColors.stoneBeigeColor),
                  decoration: const InputDecoration(
                    hintText: 'Search by username',
                    hintStyle: TextStyle(color: AppColors.mossGreen),
                    prefixIcon: Icon(Icons.alternate_email,
                        color: AppColors.mossGreen),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _runSearch(),
                ),
              ),
              IconButton(
                onPressed: _runSearch,
                icon: const Icon(Icons.search, color: AppColors.lightLeaf),
              ),
            ],
          ),
          if (_searching)
            const Padding(
              padding: EdgeInsets.all(8),
              child: LinearProgressIndicator(color: AppColors.lightLeaf),
            ),
          for (final p in _results)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline,
                  color: AppColors.mossGreen),
              title: Text(p.label,
                  style: const TextStyle(color: AppColors.stoneBeigeColor)),
              subtitle: Text('@${p.username}',
                  style: const TextStyle(color: AppColors.mossGreen)),
              trailing: TextButton(
                onPressed: () => _add(p),
                child: const Text('Add',
                    style: TextStyle(color: AppColors.lightLeaf)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _requestTile(Profile p) {
    return _card(
      child: Row(
        children: [
          const Icon(Icons.person_add_alt, color: AppColors.lightLeaf),
          const SizedBox(width: 12),
          Expanded(
            child: Text('@${p.username}',
                style: const TextStyle(color: AppColors.stoneBeigeColor)),
          ),
          TextButton(
            onPressed: () => _accept(p),
            child: const Text('Accept',
                style: TextStyle(color: AppColors.lightLeaf)),
          ),
          TextButton(
            onPressed: () => _decline(p),
            child: const Text('Decline',
                style: TextStyle(color: AppColors.dangerRed)),
          ),
        ],
      ),
    );
  }

  Widget _friendTile(FriendSummary f) {
    return _card(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Text(f.statusEmoji, style: const TextStyle(fontSize: 26)),
        title: Text(f.profile.label,
            style: const TextStyle(
                color: AppColors.stoneBeigeColor,
                fontWeight: FontWeight.bold)),
        subtitle: Text(
          f.sharedGoals.isEmpty
              ? '@${f.profile.username} · no shared goals'
              : '@${f.profile.username} · ${f.sharedGoals.length} shared goal'
                  '${f.sharedGoals.length == 1 ? '' : 's'}',
          style: const TextStyle(color: AppColors.mossGreen),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.mossGreen),
        onTap: () => _openGarden(f),
      ),
    );
  }

  // ------------------------------------------------------------- small bits

  Widget _sectionTitle(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(s,
            style: const TextStyle(
                color: AppColors.lightLeaf,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
      );

  Widget _card({required Widget child}) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppColors.mossGreen.withValues(alpha: 0.3)),
        ),
        child: child,
      );

  Widget _notice(IconData icon, String title, String body,
          {Future<void> Function()? onRetry}) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.mossGreen, size: 48),
              const SizedBox(height: 16),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.stoneBeigeColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.mossGreen)),
              if (onRetry != null) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      );
}

/// First-run inline form: a signed-in user with no profile claims a username.
class _ClaimUsername extends StatefulWidget {
  const _ClaimUsername({required this.onClaimed});
  final Future<void> Function() onClaimed;

  @override
  State<_ClaimUsername> createState() => _ClaimUsernameState();
}

class _ClaimUsernameState extends State<_ClaimUsername> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _claim() async {
    final name = _controller.text.trim();
    if (!ProfileService.usernamePattern.hasMatch(name)) {
      setState(() => _error = '3-20 letters, numbers or underscore');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!await ProfileService.instance.isUsernameAvailable(name)) {
        setState(() => _error = 'That username is taken.');
        return;
      }
      await ProfileService.instance.claimUsername(name);
      await widget.onClaimed();
    } on UsernameTakenException {
      if (mounted) setState(() => _error = 'That username is taken.');
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.alternate_email,
                color: AppColors.lightLeaf, size: 48),
            const SizedBox(height: 16),
            const Text('Pick a username',
                style: TextStyle(
                    color: AppColors.stoneBeigeColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('This is how friends find and add you.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.mossGreen)),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              enabled: !_busy,
              autocorrect: false,
              enableSuggestions: false,
              style: const TextStyle(color: AppColors.stoneBeigeColor),
              decoration: InputDecoration(
                hintText: 'username',
                hintStyle: const TextStyle(color: AppColors.mossGreen),
                errorText: _error,
                prefixIcon: const Icon(Icons.alternate_email,
                    color: AppColors.mossGreen),
              ),
              onSubmitted: (_) => _claim(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _busy ? null : _claim,
              child: _busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Claim username'),
            ),
          ],
        ),
      ),
    );
  }
}
