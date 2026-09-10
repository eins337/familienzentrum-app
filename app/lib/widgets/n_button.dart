import 'package:flutter/material.dart';
import '../theme/tokens.dart';

enum NButtonVariant { primary, secondary, ghost }

/// Nocturne `.btn` / `.btn-primary` / `.btn-secondary` / `.btn-ghost`.
class NButton extends StatelessWidget {
  const NButton({
    super.key,
    this.label,
    this.child,
    this.onPressed,
    this.variant = NButtonVariant.secondary,
    this.block = false,
    this.small = false,
    this.icon,
    this.loading = false,
    this.iconOnly = false,
    this.alignStart = false,
  });

  final String? label;
  final Widget? child;
  final VoidCallback? onPressed;
  final NButtonVariant variant;
  final bool block;
  final bool small;
  final Widget? icon;
  final bool loading;
  final bool iconOnly;
  final bool alignStart;

  Color get _fg => switch (variant) {
        NButtonVariant.primary => AppColors.accent,
        NButtonVariant.secondary => AppColors.text,
        NButtonVariant.ghost => AppColors.accent,
      };

  Color get _borderColor => switch (variant) {
        NButtonVariant.primary => AppColors.accent,
        NButtonVariant.secondary => AppColors.divider,
        NButtonVariant.ghost => Colors.transparent,
      };

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    final content = loading
        ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: _fg),
          )
        : Row(
            mainAxisSize: block ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: alignStart ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              if (icon != null) IconTheme(data: IconThemeData(color: _fg, size: small ? 14 : 16), child: icon!),
              if (icon != null && (label != null || child != null)) const SizedBox(width: 6),
              if (child != null)
                child!
              else if (label != null)
                Flexible(
                  child: Text(
                    label!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      fontSize: small ? 12.5 : 14,
                      color: _fg,
                    ),
                  ),
                ),
            ],
          );

    final button = Opacity(
      opacity: disabled && !loading ? 0.45 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            width: iconOnly ? (small ? 30 : 36) : null,
            height: iconOnly ? (small ? 30 : 36) : null,
            padding: iconOnly
                ? EdgeInsets.zero
                : EdgeInsets.symmetric(
                    horizontal: variant == NButtonVariant.ghost ? AppSpace.s1 : AppSpace.s3 * 1.2,
                    vertical: small ? 7 : AppSpace.s2,
                  ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: _borderColor),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: content,
          ),
        ),
      ),
    );

    if (block) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
