import 'package:flutter/material.dart';
import '../theme/tokens.dart';

enum NTagVariant { accent, neutral, outline }

/// v2 Badge/Pill — soft-colored, matches the README badge scale
/// (10–10.5px/800).
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
          NTagVariant.accent => AppColors.primarySoft,
          NTagVariant.neutral => AppColors.soft,
          NTagVariant.outline => Colors.transparent,
        };
    final fg = textColor ??
        switch (variant) {
          NTagVariant.accent => AppColors.primaryInk,
          NTagVariant.neutral => AppColors.ink2,
          NTagVariant.outline => AppColors.primary,
        };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: variant == NTagVariant.outline ? Border.all(color: AppColors.primary) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[IconTheme(data: IconThemeData(color: fg, size: 9), child: icon!), const SizedBox(width: 4)],
          Text(label, style: AppText.sectionLabel(color: fg, size: 10.5)),
        ],
      ),
    );
  }
}
