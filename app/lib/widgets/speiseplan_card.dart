import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/tokens.dart';
import 'n_card.dart';

class SpeiseplanCard extends StatelessWidget {
  const SpeiseplanCard({super.key, required this.speiseplan});
  final Speiseplan speiseplan;

  @override
  Widget build(BuildContext context) {
    return NCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SPEISEPLAN · DIESE WOCHE',
              style: TextStyle(fontSize: 10, letterSpacing: 1.1, color: AppColors.accent, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          for (final item in speiseplan.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 24, child: Text(item.day, style: const TextStyle(fontSize: 12.5, color: AppColors.neutral500))),
                  Expanded(child: Text(item.text, style: const TextStyle(fontSize: 12.5, color: AppColors.text))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
