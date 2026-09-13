import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../theme/tokens.dart';
import 'n_card.dart';
import 'n_tag.dart';

class SpeiseplanCard extends StatelessWidget {
  const SpeiseplanCard({super.key, required this.speiseplan});
  final Speiseplan speiseplan;

  @override
  Widget build(BuildContext context) {
    if (speiseplan.fileUrl == null) return const SizedBox();
    return NCard(
      onTap: () => launchUrl(Uri.parse(speiseplan.fileUrl!), mode: LaunchMode.externalApplication),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(AppRadius.iconBackplate)),
            child: const Icon(Icons.restaurant_menu_rounded, size: 17, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text('Speiseplan KW ${speiseplan.kw}', style: AppText.outfit(size: 14, weight: FontWeight.w600, color: AppColors.ink)),
                    const SizedBox(width: 6),
                    const NTag('Aktuell', variant: NTagVariant.accent),
                  ],
                ),
                if (speiseplan.fileName != null) Text(speiseplan.fileName!, style: AppText.nunito(size: 11.5, color: AppColors.muted)),
              ],
            ),
          ),
          const Icon(Icons.open_in_new_rounded, size: 15, color: AppColors.muted),
        ],
      ),
    );
  }
}
