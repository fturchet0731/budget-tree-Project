import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_localizations.dart';
import '../models/friendship_model.dart';
import '../models/profile_model.dart';
import '../services/auth_service.dart';
import '../services/friends_service.dart';
import '../services/goal_repository.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scrollbar.dart';
import '../widgets/skeleton.dart';
import '../widgets/social_tab_bar.dart';
import 'auth/login_screen.dart';
import 'friend_garden_screen.dart';

/// The social hub: claim a username (first time), set how your status emoji is
/// computed, add friends by username, respond to requests, and open a friend's
/// garden. Online-only — when the social layer is unavailable it shows a
/// sign-in / connectivity notice instead of crashing.
class FriendsScreen extends StatefulWidget {
  /// When hosted in the dashboard's swipe-in sidebar, [onClose] closes the
  /// drawer (and replaces the AppBar's automatic back button with an X). Null
  /// when shown as a standalone screen.
  const FriendsScreen({super.key, this.onClose, this.onSelectTab});

  final VoidCallback? onClose;

  /// When hosted in the social sidebar, switches to another tab (e.g. Profile).
  /// Null when shown standalone, in which case the app bar shows a plain title.
  final ValueChanged<SocialTab>? onSelectTab;

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
    final l = AppLocalizations.of(context);
    if (e is PostgrestException && e.code == '42P01') {
      return l.friendsTablesMissing;
    }
    return l.couldntReachFriends;
  }

  /// Localized label for a friend-status mode (the model's own label is English).
  String _statusModeLabel(AppLocalizations l, FriendStatusMode m) {
    switch (m) {
      case FriendStatusMode.best:
        return l.statusModeBest;
      case FriendStatusMode.average:
        return l.statusModeAverage;
      case FriendStatusMode.worst:
        return l.statusModeWorst;
      case FriendStatusMode.goal:
        return l.statusModeGoal;
    }
  }

  /// Run a mutating action, surfacing failures as a snackbar instead of an
  /// unhandled exception. Returns whether it succeeded.
  Future<bool> _guard(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_messageFor(e))));
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
      () async => results = await ProfileService.instance.searchByUsername(q),
    );
    if (!mounted) return;
    setState(() {
      _results = ok ? results : const [];
      _searching = false;
    });
  }

  Future<void> _add(Profile p) async {
    final ok = await _guard(() => FriendsService.instance.sendRequest(p.id));
    if (!ok) return;
    _search.clear();
    setState(() => _results = const []);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).requestSentTo(p.username)),
        ),
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
      () => ProfileService.instance.setStatusMode(mode, goalId: goalId),
    );
    if (ok) await _load();
  }

  Future<String?> _pickStatusGoal() async {
    final goals = (await GoalRepository.loadAll())
        .where((g) => g.sharedWithFriends)
        .toList();
    if (!mounted) return null;
    if (goals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).shareGoalFirstToPin),
        ),
      );
      return null;
    }
    return showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(AppLocalizations.of(context).pinWhichGoal),
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
        centerTitle: widget.onSelectTab != null,
        title: widget.onSelectTab == null
            ? Text(AppLocalizations.of(context).friends)
            : SocialTabBar(
                active: SocialTab.friends,
                onSelect: widget.onSelectTab!,
              ),
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
    final l = AppLocalizations.of(context);
    if (_loading) {
      return const FriendsSkeleton();
    }
    if (!ProfileService.instance.isAvailable) {
      // A guest can fix this on the spot: offer sign-up instead of a dead end.
      return _notice(
        Icons.cloud_off,
        l.friendsNeedAccountTitle,
        l.friendsNeedAccountBody,
        action: AuthService.instance.isConfigured
            ? ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(startInSignUp: true),
                    ),
                  );
                  if (mounted) await _load();
                },
                icon: const Icon(Icons.person_add_alt),
                label: Text(l.createAccount),
              )
            : null,
      );
    }
    if (_errorMsg != null) {
      return _notice(
        Icons.wifi_off,
        l.couldntLoadFriends,
        _errorMsg!,
        onRetry: _load,
      );
    }
    if (_me == null) {
      return _ClaimUsername(onClaimed: _load);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: AppScrollbar(
        builder: (controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _statusCard(),
            const SizedBox(height: 20),
            _addCard(),
            if (_incoming.isNotEmpty) ...[
              const SizedBox(height: 20),
              _sectionTitle(l.requests),
              for (final p in _incoming) _requestTile(p),
            ],
            const SizedBox(height: 20),
            _sectionTitle(l.friends),
            if (_friends.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  l.noFriendsYet,
                  style: const TextStyle(color: AppColors.mossGreen),
                ),
              ),
            for (final f in _friends) _friendTile(f),
          ],
        ),
      ),
    );
  }

  Widget _statusCard() {
    final l = AppLocalizations.of(context);
    return _card(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.youAreUsername(_me!.username),
                  style: const TextStyle(
                    color: AppColors.stoneBeigeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l.howFriendsSeeStatus,
                  style: const TextStyle(
                    color: AppColors.mossGreen,
                    fontSize: 12,
                  ),
                ),
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
                DropdownMenuItem(value: m, child: Text(_statusModeLabel(l, m))),
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
    final l = AppLocalizations.of(context);
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(l.addAFriend),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  style: const TextStyle(color: AppColors.stoneBeigeColor),
                  decoration: InputDecoration(
                    hintText: l.searchByUsername,
                    hintStyle: const TextStyle(color: AppColors.mossGreen),
                    prefixIcon: const Icon(
                      Icons.alternate_email,
                      color: AppColors.mossGreen,
                    ),
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
              leading: const Icon(
                Icons.person_outline,
                color: AppColors.mossGreen,
              ),
              title: Text(
                p.label,
                style: const TextStyle(color: AppColors.stoneBeigeColor),
              ),
              subtitle: Text(
                '@${p.username}',
                style: const TextStyle(color: AppColors.mossGreen),
              ),
              trailing: TextButton(
                onPressed: () => _add(p),
                child: Text(
                  l.add,
                  style: const TextStyle(color: AppColors.lightLeaf),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _requestTile(Profile p) {
    final l = AppLocalizations.of(context);
    return _card(
      child: Row(
        children: [
          const Icon(Icons.person_add_alt, color: AppColors.lightLeaf),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '@${p.username}',
              style: const TextStyle(color: AppColors.stoneBeigeColor),
            ),
          ),
          TextButton(
            onPressed: () => _accept(p),
            child: Text(
              l.accept,
              style: const TextStyle(color: AppColors.lightLeaf),
            ),
          ),
          TextButton(
            onPressed: () => _decline(p),
            child: Text(
              l.decline,
              style: const TextStyle(color: AppColors.dangerRed),
            ),
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
        title: Text(
          f.profile.label,
          style: const TextStyle(
            color: AppColors.stoneBeigeColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '@${f.profile.username} · '
          '${AppLocalizations.of(context).sharedGoalsCount(f.sharedGoals.length)}',
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
    child: Text(
      s,
      style: const TextStyle(
        color: AppColors.lightLeaf,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    ),
  );

  Widget _card({required Widget child}) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.mossGreen.withValues(alpha: 0.3)),
    ),
    child: child,
  );

  Widget _notice(
    IconData icon,
    String title,
    String body, {
    Future<void> Function()? onRetry,
    Widget? action,
  }) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.mossGreen, size: 48),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.stoneBeigeColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.mossGreen),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context).retry),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 20),
            action,
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
    final l = AppLocalizations.of(context);
    final name = _controller.text.trim();
    if (!ProfileService.usernamePattern.hasMatch(name)) {
      setState(() => _error = l.usernameRule);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!await ProfileService.instance.isUsernameAvailable(name)) {
        setState(() => _error = l.usernameTakenShort);
        return;
      }
      await ProfileService.instance.claimUsername(name);
      await widget.onClaimed();
    } on UsernameTakenException {
      if (mounted) setState(() => _error = l.usernameTakenShort);
    } catch (_) {
      if (mounted) setState(() => _error = l.somethingWentWrong);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.alternate_email,
              color: AppColors.lightLeaf,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              l.claimUsernameTitle,
              style: const TextStyle(
                color: AppColors.stoneBeigeColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.claimUsernameBody,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mossGreen),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              enabled: !_busy,
              autocorrect: false,
              enableSuggestions: false,
              style: const TextStyle(color: AppColors.stoneBeigeColor),
              decoration: InputDecoration(
                hintText: l.usernameHint,
                hintStyle: const TextStyle(color: AppColors.mossGreen),
                errorText: _error,
                prefixIcon: const Icon(
                  Icons.alternate_email,
                  color: AppColors.mossGreen,
                ),
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
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l.claimUsernameButton),
            ),
          ],
        ),
      ),
    );
  }
}
