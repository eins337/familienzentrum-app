import 'package:flutter/material.dart';
import '../theme/tokens.dart';

enum NCardElevation { none, sm, md, lg }

/// Nocturne `.card` (+ `.elev-sm/md/lg`).
class NCard extends StatelessWidget {
  const NCard({
    super.key,
    required this.child,
    this.elevation = NCardElevation.sm,
    this.padding = const EdgeInsets.all(AppSpace.s3),
    this.borderColor,
    this.background = AppColors.surface,
    this.onTap,
    this.row = false,
  });

  final Widget child;
  final NCardElevation elevation;
  final EdgeInsets padding;
  final Color? borderColor;
  final Color background;
  final VoidCallback? onTap;
  final bool row;

  List<BoxShadow>? get _shadow => switch (elevation) {
        NCardElevation.none => null,
        NCardElevation.sm => AppShadows.sm,
        NCardElevation.md => AppShadows.md,
        NCardElevation.lg => AppShadows.lg,
      };

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: _shadow,
        border: borderColor != null ? Border(left: BorderSide(color: borderColor!, width: 2)) : null,
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: content,
      ),
    );
  }
}

/// `.card-kicker` — small uppercase accent label used inside cards.
class NCardKicker extends StatelessWidget {
  const NCardKicker(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(fontSize: 10, letterSpacing: 1.1, color: AppColors.accent, fontWeight: FontWeight.w500),
    );
  }
}
