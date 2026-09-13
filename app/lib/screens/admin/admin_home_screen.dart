import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/tokens.dart';
import '../../widgets/n_card.dart';
import '../../widgets/n_header.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Einladungen', 'Zugangscodes für neue Familien & Team-Mitglieder', Icons.mail_outline_rounded, '/admin/invites'),
      ('Familien', 'Familien, Kinder, Gruppenzuordnung', Icons.family_restroom_rounded, '/admin/families'),
      ('Team & Rollen', 'Rollen, Admin-Rechte, Konten sperren', Icons.badge_outlined, '/admin/team'),
      ('Inhalte', 'Termine, Schließtage, Dokumente, Speiseplan', Icons.article_outlined, '/admin/content'),
      ('Krankmeldungen', 'Alle Krankmeldungen im Überblick', Icons.medical_information_outlined, '/admin/sickreports'),
    ];

    return Scaffold(
      appBar: const NHeader(title: 'Admin-Bereich', subtitle: 'Familienzentrum Lank', showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          for (final item in items) ...[
            NCard(
              onTap: () => context.push(item.$4),
              child: Row(
                children: [
                  Icon(item.$3, size: 20, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(item.$1, style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 14.5, color: AppColors.ink)),
                        Text(item.$2, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.mutedAlt),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
