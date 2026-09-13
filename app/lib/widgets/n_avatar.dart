import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Initials circle used throughout the app for people/group avatars.
class NAvatar extends StatelessWidget {
  const NAvatar({
    super.key,
    required this.initials,
    this.size = 32,
    this.background = AppColors.soft,
    this.foreground = AppColors.ink,
    this.borderColor,
    this.shape = BoxShape.circle,
    this.radius,
  });

  final String initials;
  final double size;
  final Color background;
  final Color foreground;
  final Color? borderColor;
  final BoxShape shape;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle ? BorderRadius.circular(radius ?? size * 0.32) : null,
        border: borderColor != null ? Border.all(color: borderColor!) : null,
      ),
      child: Text(
        initials,
        style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: size * 0.34, color: foreground),
      ),
    );
  }
}
