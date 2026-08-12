import 'package:flutter/material.dart';

import '../models/profile_model.dart';
import '../services/tree_health_service.dart';
import '../theme/app_dims.dart';
import '../theme/app_tokens.dart';
import 'status_tree_view.dart';

/// A user's avatar: **their status tree**.
///
/// Uploaded photos are gone. Identity in this app is the tree you have grown,
/// which means an avatar carries real information — how consistently that
/// person has been checking in — instead of being decoration. It also removes
/// a whole class of problem (photo permissions, moderation, base64 blobs on
/// every profile row) for free.
///
/// The tier comes from the `health_score` the user publishes
/// (`TreeHealthService.tierFor`); friends only ever publish a 0-100 score, so
/// this is always a score tier, never a prestige one. A profile that has not
/// published a score yet shows the baseline tree rather than an empty box.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.profile,
    this.size = 52,
    this.online = false,
    this.framed = true,
  });

  final Profile? profile;
  final double size;

  /// Ring the well in accent green — used by the friends list for presence.
  final bool online;

  /// Draw the inset well around the tree. Off for spots that supply their own
  /// container.
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final score = profile?.healthScore;
    final tier = TreeHealthService.tierFor((score ?? 50).toDouble());

    final tree = StatusTreeView(spriteKey: tier.name, size: size);
    if (!framed) return tree;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: t.accentTint,
        border: Border.all(
          color: online ? t.accent : t.cardBorder,
          width: AppDims.borderThin,
        ),
      ),
      alignment: Alignment.center,
      child: StatusTreeView(spriteKey: tier.name, size: size - 4),
    );
  }
}
