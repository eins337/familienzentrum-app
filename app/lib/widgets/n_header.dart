import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// The app's header bar — title + subtitle, optional back button, and a
/// notifications bell with an unread dot. Matches the prototype's header
/// (which faked the status-bar inset with hardcoded padding); here we rely
/// on the real device's SafeArea instead.
class NHeader extends StatelessWidget implements PreferredSizeWidget {
  const NHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = false,
    this.onBack,
    this.hasUnread = false,
    this.onBell,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  final bool hasUnread;
  final VoidCallback? onBell;
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
        child: Row(
          children: [
            if (showBack) ...[
              _IconBtn(
                onTap: onBack ?? () => Navigator.of(context).maybePop(),
                icon: Icons.arrow_back_ios_new_rounded,
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 15, color: AppColors.text),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: AppColors.neutral500),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (onBell != null)
              _IconBtn(
                onTap: onBell,
                icon: Icons.notifications_none_rounded,
                dot: hasUnread,
              ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.onTap, required this.icon, this.dot = false});
  final VoidCallback? onTap;
  final IconData icon;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(border: Border.all(color: AppColors.divider), borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, size: 17, color: AppColors.text),
              if (dot)
                Positioned(
                  top: -1,
                  right: -1,
                  child: Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.accent)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
