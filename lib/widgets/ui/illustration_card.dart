import 'package:flutter/material.dart';
import '../../theme/app_dims.dart';
import '../../theme/app_tokens.dart';

/// A soft tinted container that carries an illustration — the redesign's way
/// of bringing color onto the neutral canvas (hero scenes, goal saplings,
/// empty states). Optionally stacks a title and subtitle under the art.
class IllustrationCard extends StatelessWidget {
  final Widget illustration;
  final double? height;
  final Color? tint;
  final String? title;
  final String? subtitle;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  const IllustrationCard({
    super.key,
    required this.illustration,
    this.height,
    this.tint,
    this.title,
    this.subtitle,
    this.margin = EdgeInsets.zero,
    this.padding = const EdgeInsets.all(AppDims.s16),
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    Widget art = Padding(padding: padding, child: illustration);
    if (height != null) {
      art = SizedBox(height: height, width: double.infinity, child: art);
    }
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: tint ?? t.accentTint,
        borderRadius: BorderRadius.circular(AppDims.rCard),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          art,
          if (title != null || subtitle != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppDims.s20, 0, AppDims.s20, AppDims.s20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(title!, style: text.headlineSmall),
                  if (title != null && subtitle != null)
                    const SizedBox(height: AppDims.s4),
                  if (subtitle != null)
                    Text(subtitle!, style: text.bodyMedium),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
