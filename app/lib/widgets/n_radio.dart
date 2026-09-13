import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Nocturne `.radio` — a labeled radio dot row.
class NRadioRow extends StatelessWidget {
  const NRadioRow({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? AppColors.primary : AppColors.divider, width: 1.5),
                color: selected ? AppColors.primary : Colors.transparent,
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.surface),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 14, color: AppColors.ink)),
          ],
        ),
      ),
    );
  }
}
