import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class NNavItem {
  const NNavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

/// The 5-tab (or 6 for Kita-Team) bottom bar from the prototype's footer.
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
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
        decoration: const BoxDecoration(
          color: AppColors.bg,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(items[i].icon, size: 19, color: i == currentIndex ? AppColors.accent : AppColors.neutral600),
                        const SizedBox(height: 3),
                        Text(
                          items[i].label,
                          style: TextStyle(fontSize: 9.5, color: i == currentIndex ? AppColors.accent : AppColors.neutral600),
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
