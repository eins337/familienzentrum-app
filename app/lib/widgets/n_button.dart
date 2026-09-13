import 'package:flutter/material.dart';
import '../theme/tokens.dart';

enum NButtonVariant { primary, secondary, ghost, success, danger }

/// v2 Button — primary (filled `primary` + shadow), secondary (`soft` fill +
/// `border`), ghost (transparent, primary-colored label). Press feedback is
/// a scale-down per the README microinteractions spec, not a ripple.
class NButton extends StatefulWidget {
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
    this.textColor,
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
  /// Overrides the variant's default label/icon color — e.g. a coral
  /// "Abmelden" ghost button without needing a whole new boxed variant.
  final Color? textColor;

  @override
  State<NButton> createState() => _NButtonState();
}

class _NButtonState extends State<NButton> {
  bool _pressed = false;

  Color get _bg => switch (widget.variant) {
        NButtonVariant.primary => AppColors.primary,
        NButtonVariant.secondary => AppColors.soft,
        NButtonVariant.ghost => Colors.transparent,
        NButtonVariant.success => AppColors.successSoft,
        NButtonVariant.danger => AppColors.errorSoft,
      };

  Color get _fg => widget.textColor ?? switch (widget.variant) {
        NButtonVariant.primary => AppColors.surface,
        NButtonVariant.secondary => AppColors.ink,
        NButtonVariant.ghost => AppColors.primary,
        NButtonVariant.success => AppColors.successInk,
        NButtonVariant.danger => AppColors.errorInk,
      };

  Border? get _border => switch (widget.variant) {
        NButtonVariant.primary => null,
        NButtonVariant.secondary => Border.all(color: AppColors.border),
        NButtonVariant.ghost => null,
        NButtonVariant.success => null,
        NButtonVariant.danger => Border.all(color: AppColors.errorBorder),
      };

  List<BoxShadow>? get _shadow => widget.variant == NButtonVariant.primary ? AppShadows.primaryButton : null;

  double get _radius => widget.small ? AppRadius.buttonSm : AppRadius.buttonLg;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null || widget.loading;
    final content = widget.loading
        ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: _fg),
          )
        : Row(
            mainAxisSize: widget.block ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: widget.alignStart ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              if (widget.icon != null) IconTheme(data: IconThemeData(color: _fg, size: widget.small ? 14 : 16), child: widget.icon!),
              if (widget.icon != null && (widget.label != null || widget.child != null)) const SizedBox(width: 7),
              if (widget.child != null)
                widget.child!
              else if (widget.label != null)
                Flexible(
                  child: Text(
                    widget.label!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.outfit(size: widget.small ? 12.5 : 14, weight: FontWeight.w600, color: _fg),
                  ),
                ),
            ],
          );

    final button = AnimatedScale(
      scale: _pressed && !disabled ? AppMotion.pressScale : 1,
      duration: AppMotion.press,
      curve: Curves.easeOut,
      child: Opacity(
        opacity: disabled && !widget.loading ? 0.45 : 1,
        child: GestureDetector(
          onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: disabled ? null : widget.onPressed,
          child: Container(
            width: widget.iconOnly ? (widget.small ? 32 : 38) : null,
            height: widget.iconOnly ? (widget.small ? 32 : 38) : null,
            padding: widget.iconOnly
                ? EdgeInsets.zero
                : EdgeInsets.symmetric(
                    horizontal: widget.variant == NButtonVariant.ghost ? 4 : 15,
                    vertical: widget.small ? 11 : 13,
                  ),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: _bg, border: _border, borderRadius: BorderRadius.circular(_radius), boxShadow: _shadow),
            child: content,
          ),
        ),
      ),
    );

    if (widget.block) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
