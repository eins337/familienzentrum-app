import 'package:flutter/material.dart';
import '../theme/tokens.dart';

enum NTagVariant { accent, neutral, outline }

/// Nocturne `.tag` / `.tag-accent` / `.tag-neutral` / `.tag-outline`.
class NTag extends StatelessWidget {
  const NTag(this.label, {super.key, this.variant = NTagVariant.neutral, this.icon, this.color, this.textColor});

  final String label;
  final NTagVariant variant;
  final Widget? icon;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final bg = color ??
        switch (variant) {
          NTagVariant.accent => AppColors.accent800,
          NTagVariant.neutral => AppColors.neutral800,
          NTagVariant.outline => Colors.transparent,
        };
    final fg = textColor ??
        switch (variant) {
          NTagVariant.accent => AppColors.accent100,
          NTagVariant.neutral => AppColors.neutral100,
          NTagVariant.outline => AppColors.accent,
        };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md * 0.75),
        border: variant == NTagVariant.outline ? Border.all(color: AppColors.accent) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[IconTheme(data: IconThemeData(color: fg, size: 9), child: icon!), const SizedBox(width: 4)],
          Text(label, style: TextStyle(fontSize: 11, letterSpacing: 0.02, color: fg)),
        ],
      ),
    );
  }
}
