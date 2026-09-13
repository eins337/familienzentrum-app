import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/tokens.dart';
import '../utils/group_colors.dart';
import 'n_card.dart';

/// "🎂 Bald Geburtstag" — a small, warm touch: upcoming birthdays for
/// children in the groups the viewer cares about.
class BirthdayCard extends StatelessWidget {
  const BirthdayCard({super.key, required this.children});
  final List<Child> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox();
    return NCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🎂', style: TextStyle(fontSize: 14)),
              SizedBox(width: 6),
              Text('BALD GEBURTSTAG', style: TextStyle(fontFamily: 'Outfit', fontSize: 10, letterSpacing: 1.3, color: AppColors.primary, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          for (final c in children)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: groupColor(c.groupId))),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      _label(c),
                      style: const TextStyle(fontSize: 13, color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _label(Child c) {
    final days = c.daysUntilNextBirthday!;
    final turningAge = DateTime.now().add(Duration(days: days)).year - c.birthDate!.year;
    final ageLabel = ' wird $turningAge Jahre alt';
    if (days == 0) return '${c.name} hat heute Geburtstag! 🎉$ageLabel';
    if (days == 1) return '${c.name} hat morgen Geburtstag$ageLabel';
    return '${c.name} hat in $days Tagen Geburtstag$ageLabel';
  }
}
