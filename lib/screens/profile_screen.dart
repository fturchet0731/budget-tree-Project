import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_localizations.dart';
import '../models/category_model.dart';
import '../models/goal_model.dart';
import '../models/profile_model.dart';
import '../services/auth_service.dart';
import '../services/category_repository.dart';
import '../services/goal_repository.dart';
import '../services/profile_service.dart';
import '../theme/app_shadows.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_scrollbar.dart';
import '../widgets/goal_sapling_card.dart';
import '../widgets/skeleton.dart';
import '../widgets/profile_avatar.dart';
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

  /// Let the user pick a profile photo from the device gallery. The image is
  /// resized/compressed on device (~256px JPEG) and stored inline on the
  /// profile row, so friends see it with no extra infrastructure.
  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 256,
      maxHeight: 256,
      imageQuality: 70,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    await ProfileService.instance.setAvatar(base64Encode(bytes));
    await _load();
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
          decoration: InputDecoration(
            hintText: l.bioHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l.cancel,
              style: TextStyle(color: AppColors.mossGreen),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forestGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
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
        foregroundColor: AppColors.stoneBeigeColor,
      ),
      body: SafeArea(child: _body(l)),
    );
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
      child: AppScrollbar(
        builder: (controller) => CustomScrollView(
          controller: controller,
          slivers: [
            SliverToBoxAdapter(child: _header(l)),
            if (_sharedGoals.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 30, 28, 30),
                  child: Text(
                    l.shareGoalsToShowOnProfile,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.mossGreen),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
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
          ],
        ),
      ),
    );
  }

  Widget _header(AppLocalizations l) {
    final bio = _me!.bio?.trim();
    final hasBio = bio != null && bio.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  children: [
                    ProfileAvatar(profile: _me, size: 56),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppTokens.current.accent,
                          border: Border.all(
                              color: AppTokens.current.card, width: 1.5),
                        ),
                        child: Icon(Icons.photo_camera,
                            size: 10, color: AppTokens.current.onAccent),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_me!.displayName != null &&
                        _me!.displayName!.trim().isNotEmpty)
                      Text(
                        _me!.displayName!,
                        style: TextStyle(
                          color: AppColors.stoneBeigeColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    Text(
                      '@${_me!.username}',
                      style: TextStyle(
                        color: AppColors.mossGreen,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Bio block — tap to edit.
          InkWell(
            onTap: _editBio,
            borderRadius: BorderRadius.zero,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTokens.current.card,
                borderRadius: BorderRadius.zero,
                border: Border.all(color: AppTokens.current.cardBorder),
                boxShadow: AppShadows.card,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      hasBio ? bio : l.addABio,
                      style: TextStyle(
                        color: hasBio
                            ? AppColors.stoneBeigeColor
                            : AppColors.mossGreen,
                        fontSize: 14,
                        height: 1.4,
                        fontStyle: hasBio ? FontStyle.normal : FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.edit_outlined,
                    color: AppColors.mossGreen,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l.sharedGoals,
            style: TextStyle(
              color: AppColors.lightLeaf,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
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
          if (action != null) ...[
            const SizedBox(height: 20),
            action,
          ],
        ],
      ),
    ),
  );
}
