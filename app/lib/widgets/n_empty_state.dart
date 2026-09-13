import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// v2 EmptyState — centered icon backplate + muted text, for "Noch keine …"
/// placeholders across list screens.
class NEmptyState extends StatelessWidget {
  const NEmptyState({super.key, required this.icon, required this.text, this.padding = const EdgeInsets.symmetric(vertical: 40)});

  final IconData icon;
  final String text;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, size: 22, color: AppColors.mutedAlt),
            ),
            const SizedBox(height: 10),
            Text(text, textAlign: TextAlign.center, style: AppText.nunito(size: 13, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
