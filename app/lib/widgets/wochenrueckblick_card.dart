import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/tokens.dart';
import '../utils/time_format.dart';
import 'n_card.dart';
import 'n_tag.dart';

/// The group-specific "Wochenrückblick" card: pinned to the top of a
/// Gruppe's detail screen (not mixed into the regular post list), a 2x2
/// photo grid, and a footer noting it expires Sunday 20:00.
class WochenrueckblickCard extends StatelessWidget {
  const WochenrueckblickCard({super.key, required this.post});
  final Post post;

  @override
  Widget build(BuildContext context) {
    final week = isoWeekNumber(post.createdAt);
    final nextWeek = week + 1;
    final photos = post.photoUrls.take(4).toList();

    return NCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const NTag('Wochenrückblick', variant: NTagVariant.accent),
              const Spacer(),
              Text('KW $week', style: AppText.outfit(size: 12, weight: FontWeight.w600, color: AppColors.muted)),
            ],
          ),
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1,
              children: [
                for (final url in photos)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Text(post.body, style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.ink)),
          const SizedBox(height: 8),
          Text('Wird Sonntag 20:00 durch KW $nextWeek ersetzt', style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
        ],
      ),
    );
  }
}
