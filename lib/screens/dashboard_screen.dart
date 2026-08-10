import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/profile_model.dart';
import '../services/app_settings.dart';
import '../services/auth_service.dart';
import '../services/budget_repository.dart';
import '../services/goal_repository.dart';
import '../services/profile_service.dart';
import '../theme/app_dims.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../tutorial/tutorial_tour.dart';
import '../widgets/friends_strip.dart';
import '../widgets/pixel/pixel.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/health_tree_hero.dart';
import '../widgets/pulse_strip.dart';
import '../widgets/ui/app_buttons.dart';
import '../widgets/ui/entrance.dart';
import 'acorn_hub_screen.dart';
import 'auth/login_screen.dart';
import 'createbudget_screen.dart';
import 'forest_screen.dart';
import 'goals_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  /// First launch only: play the guided tour once this menu appears, so Acorn
  /// greets the user at the four-leaf area before handing them the Create flow,
  /// and every section pops back here.
  final bool runTour;
  const DashboardScreen({super.key, this.runTour = false});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _pulseKey = GlobalKey<PulseStripState>();
  final _friendsKey = GlobalKey<FriendsStripState>();
  final _heroKey = GlobalKey<HealthTreeHeroState>();

  /// The signed-in user's profile, for the top-right avatar button. Null while
  /// loading, signed out, or offline (the button falls back to a glyph).
  Profile? _me;

  /// How many trees and saplings the player has, shown as "x4"/"x3" counters
  /// on the menu tiles so the collection reads as something that grows.
  int _trees = 0;
  int _saplings = 0;

  @override
  void initState() {
    super.initState();
    if (widget.runTour) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runTour());
    }
    _loadMe();
    _loadCounts();
    // Best-effort presence heartbeat so friends see the active dot.
    ProfileService.instance.touchPresence();
  }

  Future<void> _loadMe() async {
    final me = await ProfileService.instance.myProfile().catchError((_) => null);
    if (mounted) setState(() => _me = me);
  }

  Future<void> _loadCounts() async {
    final budgets = await BudgetRepository.loadAll();
    final goals = await GoalRepository.loadAll();
    if (!mounted) return;
    setState(() {
      _trees = budgets.where((b) => b.savedAt != null).length;
      _saplings = goals.length;
    });
  }

  /// Opens the user's own profile from the top-right avatar button.
  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
    // Avatar or shared goals may have changed in there.
    await _loadMe();
    _friendsKey.currentState?.refresh();
  }

  /// Plays the guided tour over the four-leaf menu on first launch, then marks
  /// it seen so it never auto-plays again.
  Future<void> _runTour() async {
    if (!mounted) return;
    await GuidedTour.start(context);
    await AppSettings.instance.setTutorialSeen(true);
  }

  Future<void> _navigate(BuildContext context, Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    // Anything the user did in there may change what the pulse strip says
    // (and shared goals feed the friends strip's status emojis). Returning
    // here also proves the user is still around, so re-stamp presence
    // (throttled inside the service).
    _pulseKey.currentState?.refresh();
    _friendsKey.currentState?.refresh();
    _heroKey.currentState?.refresh();
    ProfileService.instance.touchPresence();
  }

  /// Opens the Create flow. When a tree is actually planted the flow pops back
  /// here with `true`, so we land on the four-leaf menu and announce the new
  /// tree growing in the forest.
  Future<void> _openCreate() async {
    final planted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateBudgetScreen()),
    );
    if (!mounted) return;
    _pulseKey.currentState?.refresh();
    if (planted == true) {
      // Peak-motivation moment for a guest: their tree is in the ground, so
      // offer (once) to keep it safe with an account instead of the snackbar.
      if (await AuthService.instance.shouldOfferAccountUpgrade()) {
        await AuthService.instance.markAccountUpgradeOffered();
        if (mounted) await _offerAccountUpgrade();
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.park, color: Conifer.c300, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(AppLocalizations.of(context).newTreeInForest),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Bottom sheet celebrating a guest's first planted tree and inviting them
  /// to create an account so the forest is backed up. Shown at most once.
  Future<void> _offerAccountUpgrade() async {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTokens.current.accentTint,
                ),
                child: const Icon(Icons.park, color: Conifer.c500, size: 36),
              ),
              const SizedBox(height: AppDims.s12),
              Text(
                l.guestUpgradeTitle,
                textAlign: TextAlign.center,
                style: text.headlineSmall,
              ),
              const SizedBox(height: AppDims.s8),
              Text(
                l.guestUpgradeBody,
                textAlign: TextAlign.center,
                style: text.bodyMedium,
              ),
              const SizedBox(height: AppDims.s20),
              AppPrimaryButton(
                label: l.createAccount,
                icon: Icons.cloud_done_outlined,
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(startInSignUp: true),
                    ),
                  );
                },
              ),
              Center(
                child: AppTextButton(
                  label: l.guestUpgradeLater,
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Entrance(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('BUDGET TREE',
                              style: text.displaySmall),
                          const SizedBox(height: 5),
                          Text(
                            l.dashboardChooseBranch.toUpperCase(),
                            style: AppTheme.label(
                                9, AppTokens.of(context).textTertiary,
                                spacing: 1.5),
                          ),
                        ],
                      ),
                    ),
                    // Top-right profile button: the user's avatar with a
                    // clear "Profile" label so there's no guessing.
                    _ProfileButton(profile: _me, onTap: _openProfile),
                  ],
                ),
              ),
            ),
            PulseStrip(key: _pulseKey, onPlantTree: _openCreate),
            // The friends strip, the four pillars and Acorn's Hub travel as
            // one scrolling block. The hero must live *inside* the scroll
            // view: as a sibling of this Expanded it would take its height off
            // the flex child, and a short screen (360x640) overflows by
            // roughly the hero's own height.
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Swipeable Roblox-style friends row; first circle
                        // adds friends.
                        FriendsStrip(key: _friendsKey),
                        const SizedBox(height: AppDims.s12),
                        _MenuGrid(
                          trees: _trees,
                          saplings: _saplings,
                          onTapCreate: _openCreate,
                          onTapModify: () =>
                              _navigate(context, const ForestScreen()),
                          onTapGoals: () =>
                              _navigate(context, const GoalsScreen()),
                          onTapSettings: () =>
                              _navigate(context, const SettingsScreen()),
                        ),
                        const SizedBox(height: AppDims.s12),
                        // Acorn's Hub as a full-width fifth tile under the
                        // four pillars: the living tree, how consistent the
                        // user has been, and the door into the hub.
                        //
                        // A fixed height rather than a fraction of the
                        // viewport, because sizing off the viewport only
                        // earned its keep while the hero sat above the fold
                        // competing for space. Down here it is scrolled to,
                        // so a consistent size reads better than one that
                        // shifts with the screen.
                        HealthTreeHero(
                          key: _heroKey,
                          height: 156,
                          onOpenHub: () => _navigate(
                            context,
                            const AcornHubScreen(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Pinned under the scrollable block so it's always reachable.
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 10),
                child: AppTextButton(
                  icon: Icons.arrow_downward,
                  label: l.dashboardBackToGround,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Top-right profile button (avatar + label)
// ──────────────────────────────────────────────

class _ProfileButton extends StatelessWidget {
  final Profile? profile;
  final VoidCallback onTap;
  const _ProfileButton({required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = AppTokens.of(context);
    // A square save-file portrait rather than a round avatar: the pixel skin
    // has no circles.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PixelBox(
          onTap: onTap,
          semanticLabel: l.profile,
          fill: t.accent,
          drop: AppDims.dropSmall,
          width: AppDims.tap,
          height: AppDims.tap,
          alignment: Alignment.center,
          child: profile == null
              ? const PixelSprite(asset: PixelIcons.sprout, size: 26)
              : ClipRect(child: ProfileAvatar(profile: profile, size: 36)),
        ),
        const SizedBox(height: 4),
        Text(
          (profile?.username ?? l.profile).toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.label(9, t.textSecondary, spacing: 0.5),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// 2×2 menu grid — pixel tiles with sprite art and collection counters
// ──────────────────────────────────────────────

class _MenuGrid extends StatelessWidget {
  final int trees;
  final int saplings;
  final VoidCallback onTapCreate;
  final VoidCallback onTapModify;
  final VoidCallback onTapGoals;
  final VoidCallback onTapSettings;

  const _MenuGrid({
    required this.trees,
    required this.saplings,
    required this.onTapCreate,
    required this.onTapModify,
    required this.onTapGoals,
    required this.onTapSettings,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = AppTokens.of(context);
    final dark = t.brightness == Brightness.dark;

    final tiles = <_TileSpec>[
      _TileSpec(
        label: l.dashboardCreate,
        sublabel: l.dashboardCreateSub,
        sprite: PixelIcons.plus,
        tint: dark ? t.accentTint : Conifer.c100,
        onTap: onTapCreate,
      ),
      _TileSpec(
        label: l.dashboardModify,
        sublabel: l.dashboardModifySub,
        sprite: PixelIcons.forest,
        tint: dark ? t.accentTint : Conifer.c200,
        count: trees,
        onTap: onTapModify,
      ),
      _TileSpec(
        label: l.dashboardGoals,
        sublabel: l.dashboardGoalsSub,
        sprite: PixelIcons.star,
        tint: t.skyTint,
        count: saplings,
        onTap: onTapGoals,
      ),
      _TileSpec(
        label: l.dashboardSettings,
        sublabel: l.dashboardSettingsSub,
        sprite: PixelIcons.gear,
        tint: t.soilTint,
        onTap: onTapSettings,
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < 2; row++) ...[
          if (row > 0) const SizedBox(height: AppDims.s12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var col = 0; col < 2; col++) ...[
                  if (col > 0) const SizedBox(width: AppDims.s12),
                  Expanded(
                    child: Entrance(
                      delay: Duration(milliseconds: 70 * (row * 2 + col)),
                      child: _MenuTile(spec: tiles[row * 2 + col]),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// One menu tile's content — kept as a record-ish class so the grid reads
/// cleanly and the tile takes a single argument.
class _TileSpec {
  final String label;
  final String sublabel;
  final String sprite;
  final Color tint;
  final VoidCallback onTap;

  /// Collection counter drawn as an "xN" badge; 0 hides it.
  final int count;

  const _TileSpec({
    required this.label,
    required this.sublabel,
    required this.sprite,
    required this.tint,
    required this.onTap,
    this.count = 0,
  });
}

class _MenuTile extends StatelessWidget {
  final _TileSpec spec;
  const _MenuTile({required this.spec});

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    return PixelBox(
      onTap: spec.onTap,
      semanticLabel: spec.label,
      padding: const EdgeInsets.all(9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sunken art well: 2px inner border on a tinted panel.
          SizedBox(
            height: 74,
            width: double.infinity,
            child: PixelBox(
              fill: spec.tint,
              borderWidth: AppDims.borderThin,
              drop: 0,
              child: Stack(
                children: [
                  Center(child: PixelSprite(asset: spec.sprite, size: 40)),
                  if (spec.count > 0)
                    Positioned(
                      top: 3,
                      right: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        color: t.textPrimary,
                        child: Text(
                          'x${spec.count}',
                          style: AppTheme.label(9, Conifer.c300, spacing: 0.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            spec.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.titleMedium,
          ),
          const SizedBox(height: 3),
          Text(
            spec.sublabel,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}
