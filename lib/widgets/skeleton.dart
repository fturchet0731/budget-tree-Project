import 'package:flutter/material.dart';

import '../services/app_settings.dart';
import '../theme/app_tokens.dart';

/// Skeleton placeholders for the online-only screens: instead of a bare
/// spinner, the loading state sketches the layout that's about to appear so
/// the wait reads as "content coming" rather than "app stuck". The whole
/// group breathes with a soft opacity pulse (static under reduced motion).
class SkeletonPulse extends StatefulWidget {
  const SkeletonPulse({super.key, required this.child});
  final Widget child;

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    if (AppSettings.instance.motionFull) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 0.9).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut),
      ),
      child: widget.child,
    );
  }
}

/// One soft neutral block of the sketched layout.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 0,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTokens.current.cardBorder.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Loading sketch for the Friends tab: status card then a few friend rows.
class FriendsSkeleton extends StatelessWidget {
  const FriendsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: const [
          SkeletonBox(height: 96),
          SizedBox(height: 14),
          SkeletonBox(height: 52),
          SizedBox(height: 14),
          SkeletonBox(height: 64),
          SizedBox(height: 10),
          SkeletonBox(height: 64),
          SizedBox(height: 10),
          SkeletonBox(height: 64),
        ],
      ),
    );
  }
}

/// Loading sketch for the Profile tab: name + bio header, then the shared-goal
/// sapling grid.
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: const [
          SkeletonBox(height: 120),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: SkeletonBox(height: 150)),
              SizedBox(width: 12),
              Expanded(child: SkeletonBox(height: 150)),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: SkeletonBox(height: 150)),
              SizedBox(width: 12),
              Expanded(child: SkeletonBox(height: 150)),
            ],
          ),
        ],
      ),
    );
  }
}
