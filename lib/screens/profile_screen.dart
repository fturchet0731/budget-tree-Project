import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/category_model.dart';
import '../models/goal_model.dart';
import '../models/achievement.dart';
import '../models/profile_model.dart';
import '../services/achievement_service.dart';
import '../services/auth_service.dart';
import '../services/budget_repository.dart';
import '../services/category_repository.dart';
import '../services/goal_repository.dart';
import '../services/profile_service.dart';
import '../services/tree_health_service.dart';
import '../theme/app_dims.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_scrollbar.dart';
import '../widgets/goal_sapling_card.dart';
import '../widgets/pixel/pixel.dart';
import '../widgets/status_tree_view.dart';
import '../widgets/skeleton.dart';
import 'auth/login_screen.dart';
import 'goal_detail_screen.dart';

/// The signed-in user's own profile, opened from the dashboard's top-right
/// avatar button: their username, an editable bio, and the goals they've
/// shared drawn as saplings in a grid. The shared goals here are exactly what
/// a friend sees when they open this user's profile, so the user controls
/// visibility per goal via each goal's "visible to friends" toggle.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.onClose});

  /// Optional close callback (shows an X instead of a back button).
  final VoidCallback? onClose;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  Profile? _me;
  List<Goal> _sharedGoals = const [];
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _load();
  }

  TreeHealth _health = TreeHealth.fresh;
  int _treeCount = 0;
  double _totalSaved = 0;
  Map<String, DateTime> _unlocked = const {};

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
      // Own goals come from the offline-first repository; only the shared ones
      // appear on the profile (the same ones friends can read).
      final shared = (await GoalRepository.loadAll())
          .where((g) => g.sharedWithFriends)
          .toList();
      // Backfill each shared goal's denormalised tree colour from the local
      // category so the sapling renders in the right colour AND that colour
      // gets pushed to Supabase for friends to see. Persist only when it
      // actually changed (e.g. legacy goals saved before this field existed).
      final cats = await CategoryRepository.loadAll();
      final colorById = {for (final TreeCategory c in cats) c.id: c.colorValue};
      for (final g in shared) {
        final resolved = g.categoryId == null ? null : colorById[g.categoryId];
        if (g.leafColorValue != resolved) {
          g.leafColorValue = resolved;
          await GoalRepository.update(g);
        }
      }
      // Save-file stats for the hero and the trophy shelf.
      final health = await TreeHealthService.current();
      final budgets = await BudgetRepository.loadAll();
      final allGoals = await GoalRepository.loadAll();
      final unlocked = await AchievementService.loadUnlocked();
      final saved = allGoals.fold<double>(0, (a, g) => a + g.currentAmount);
      if (!mounted) return;
      setState(() {
        _health = health;
        _treeCount = budgets.where((b) => b.savedAt != null).length;
        _totalSaved = saved;
        _unlocked = unlocked;
      });
      if (!mounted) return;
      setState(() {
        _me = me;
        _sharedGoals = shared;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMsg = AppLocalizations.of(context).couldntReachFriends;
        });
      }
    }
  }

  Future<void> _editBio() async {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController(text: _me?.bio ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.bio),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          maxLength: 280,
          decoration: InputDecoration(hintText: l.bioHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel, style: TextStyle(color: AppColors.mossGreen)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forestGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(
              l.save,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (result == null) return; // cancelled
    final trimmed = result.trim();
    try {
      await ProfileService.instance.setBio(trimmed);
      if (mounted) {
        setState(
          () => _me = _me == null
              ? null
              : Profile(
                  id: _me!.id,
                  username: _me!.username,
                  displayName: _me!.displayName,
                  bio: trimmed.isEmpty ? null : trimmed,
                  statusMode: _me!.statusMode,
                  statusGoalId: _me!.statusGoalId,
                ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.somethingWentWrong)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // No AppBar: the reference opens straight onto the scene, with the back
    // chevron sitting *on* it. A Material title bar above the hero was what
    // made this screen read as a form rather than a place. States that never
    // reach the hero (loading / signed out / error) keep a plain bar so they
    // still have a way back.
    final ready = !_loading &&
        ProfileService.instance.isAvailable &&
        _errorMsg == null &&
        _me != null;
    if (!ready) {
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
          title: Text(l.profile),
          centerTitle: true,
        ),
        body: SafeArea(child: _body(l)),
      );
    }
    return Scaffold(body: _body(l));
  }

  Widget _body(AppLocalizations l) {
    if (_loading) {
      return const ProfileSkeleton();
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
      // Onboarding normally guarantees a username; nudge to the Friends tab
      // (which carries the claim fallback) if somehow missing.
      return _notice(
        Icons.alternate_email,
        l.claimUsernameTitle,
        l.claimUsernameBody,
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      // top:false — PixelScene handles the status bar itself so the sky can
      // bleed to the top edge; this only keeps the badge grid clear of the
      // home indicator.
      child: SafeArea(
        top: false,
        child: AppScrollbar(
        builder: (controller) => CustomScrollView(
          controller: controller,
          slivers: [
            SliverToBoxAdapter(child: _header(l)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
              sliver: SliverToBoxAdapter(child: _statBlocks(l)),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
              sliver: SliverToBoxAdapter(
                child: PixelSectionRule(label: l.profileSharedSaplings),
              ),
            ),
            if (_sharedGoals.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
                  child: Text(
                    l.shareGoalsToShowOnProfile,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                GoalDetailScreen(goal: _sharedGoals[i]),
                          ),
                        );
                        // A goal may have been edited, unshared, or deleted.
                        if (mounted) _load();
                      },
                      child: GoalSaplingCard(goal: _sharedGoals[i]),
                    ),
                    childCount: _sharedGoals.length,
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
              sliver: SliverToBoxAdapter(
                child: PixelSectionRule(
                  label: l.badgesTitle,
                  trailing:
                      '${_unlocked.length}/${AchievementCatalog.all.length}',
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
              sliver: SliverToBoxAdapter(child: _badgeGrid()),
            ),
          ],
        ),
        ),
      ),
    );
  }

  /// TREES / STREAK / SAVED, the three numbers that say how the save file is
  /// going at a glance.
  Widget _statBlocks(AppLocalizations l) {
    final t = AppTokens.of(context);
    Widget block(String label, String value) => Expanded(
      child: PixelBox(
        padding: const EdgeInsets.all(9),
        drop: AppDims.dropButton,
        child: Column(
          children: [
            Text(label, style: AppTheme.label(9, t.textSecondary)),
            const SizedBox(height: 5),
            Text(value, style: AppTheme.display(22, t.textPrimary)),
          ],
        ),
      ),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        block(l.profileStatTrees, '$_treeCount'),
        const SizedBox(width: AppDims.s8),
        block(l.profileStatStreak, '${_health.currentStreak}'),
        const SizedBox(width: AppDims.s8),
        block(l.profileStatSaved, _shortMoney(_totalSaved)),
      ],
    );
  }

  static String _shortMoney(double v) =>
      v >= 1000 ? '\$${(v / 1000).toStringAsFixed(1)}k' : '\$${v.round()}';

  /// The trophy shelf: every badge in the catalogue, locked ones dimmed, so
  /// there is always something visibly left to earn.
  Widget _badgeGrid() {
    final t = AppTokens.of(context);
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 9,
      crossAxisSpacing: 9,
      children: [
        for (final a in AchievementCatalog.all)
          Opacity(
            opacity: _unlocked.containsKey(a.id) ? 1 : 0.42,
            child: PixelBox(
              drop: AppDims.dropSmall,
              fill: _unlocked.containsKey(a.id) ? t.accentTint : t.canvasSoft,
              alignment: Alignment.center,
              semanticLabel: a.title,
              child: Icon(a.icon, size: 26, color: t.textPrimary),
            ),
          ),
      ],
    );
  }

  /// The diegetic hero: your status tree stands on the left, your name plate
  /// on the right, exactly like the handoff's profile scene.
  Widget _header(AppLocalizations l) {
    final t = AppTokens.of(context);
    final bio = _me!.bio?.trim();
    final hasBio = bio != null && bio.isNotEmpty;
    final level = _health.showsPrestige && _health.earnedPrestige != null
        ? 8 + _health.earnedPrestige!.index + 1
        : _health.tier.index + 1;
    final name =
        (_me!.displayName != null && _me!.displayName!.trim().isNotEmpty)
        ? _me!.displayName!
        : _me!.username;

    return Column(
      children: [
        PixelScene(
          height: 196,
          groundHeight: 42,
          subjectX: -0.72,
          subject: StatusTreeView(spriteKey: _health.spriteKey, size: 132),
          // Pushed from the dashboard there is no onClose, so fall back to a
          // plain pop — otherwise removing the AppBar would strand the user.
          onBack: widget.onClose ?? () => Navigator.of(context).maybePop(),
          backLabel: l.close,
          bottomRight: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.display(26, t.textPrimary),
                ),
                const SizedBox(height: 5),
                Text(
                  '@${_me!.username} \u00b7 ${l.hubLevel(level)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.label(9, t.accentStrong),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _editBio,
                  child: Text(
                    hasBio ? bio : l.addABio,
                    textAlign: TextAlign.right,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

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
            style: TextStyle(
              color: AppColors.stoneBeigeColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mossGreen),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context).retry),
            ),
          ],
          if (action != null) ...[const SizedBox(height: 20), action],
        ],
      ),
    ),
  );
}
