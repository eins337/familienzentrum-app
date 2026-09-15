import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'kita_icons.dart';

class NNavItem {
  const NNavItem(this.icon, this.label);
  final KitaIcon icon;
  final String label;
}

/// The 5-tab bottom bar — white surface, 28px active-icon pill in
/// `primarySoft`, Outfit 10px/600 labels, per the README.
class NBottomNav extends StatelessWidget {
  const NBottomNav({super.key, required this.items, required this.currentIndex, required this.onTap});

  final List<NNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: AppMotion.tabPill,
                          curve: Curves.easeOut,
                          width: 46,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: i == currentIndex ? AppColors.primarySoft : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: KitaIconWidget(items[i].icon, size: 19, color: i == currentIndex ? AppColors.primary : AppColors.mutedAlt),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          items[i].label,
                          style: AppText.outfit(size: 10, weight: FontWeight.w600, color: i == currentIndex ? AppColors.primary : AppColors.mutedAlt),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
