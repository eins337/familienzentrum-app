import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Initials circle used throughout the app for people/group avatars —
/// shows an uploaded photo instead when [imageUrl] is set, falling back to
/// the initials while it loads or if it fails.
class NAvatar extends StatelessWidget {
  const NAvatar({
    super.key,
    required this.initials,
    this.imageUrl,
    this.size = 32,
    this.background = AppColors.soft,
    this.foreground = AppColors.ink,
    this.borderColor,
    this.shape = BoxShape.circle,
    this.radius,
  });

  final String initials;
  final String? imageUrl;
  final double size;
  final Color background;
  final Color foreground;
  final Color? borderColor;
  final BoxShape shape;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final borderRadius = shape == BoxShape.rectangle ? BorderRadius.circular(radius ?? size * 0.32) : BorderRadius.circular(size / 2);
    final initialsWidget = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle ? borderRadius : null,
        border: borderColor != null ? Border.all(color: borderColor!) : null,
      ),
      child: Text(
        initials,
        style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: size * 0.34, color: foreground),
      ),
    );

    if (imageUrl == null || imageUrl!.isEmpty) return initialsWidget;

    return ClipRRect(
      borderRadius: borderRadius,
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => initialsWidget,
        errorWidget: (context, url, error) => initialsWidget,
      ),
    );
  }
}
