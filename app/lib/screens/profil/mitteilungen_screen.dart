import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../../utils/group_colors.dart';
import '../../utils/time_format.dart';
import '../../widgets/n_card.dart';
import '../../widgets/n_header.dart';

/// A read-only activity feed synthesized from real data (recent posts,
/// playdate updates, sick-report acknowledgements) rather than a separate
/// stored notifications table — keeps things simple while staying live.
class MitteilungenScreen extends ConsumerWidget {
  const MitteilungenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(feedPostsProvider).valueOrNull ?? [];
    final playdates = ref.watch(myPlaydatesProvider).valueOrNull ?? [];

    final items = <_Item>[
      for (final p in posts)
        _Item(
          time: p.createdAt,
          icon: p.kind == 'foto' ? Icons.photo_camera_outlined : Icons.description_outlined,
          text: p.groupId != null
              ? 'Neuer Beitrag in Gruppe ${groupName(p.groupId)}: ${p.title ?? p.body}'
              : (p.title ?? p.body),
        ),
      for (final pd in playdates.where((p) => p.status != 'pending'))
        _Item(
          time: pd.createdAt,
          icon: Icons.chat_bubble_outline_rounded,
          text: pd.status == 'confirmed' ? 'Eine Spielanfrage wurde bestätigt.' : 'Eine Spielanfrage wurde abgesagt.',
        ),
    ]..sort((a, b) => b.time.compareTo(a.time));

    final now = DateTime.now();
    final neu = items.where((i) => now.difference(i.time).inHours < 24).toList();
    final aelter = items.where((i) => now.difference(i.time).inHours >= 24).toList();

    return Scaffold(
      appBar: const NHeader(title: 'Mitteilungen', showBack: true),
      body: items.isEmpty
          ? const Center(child: Text('Keine Mitteilungen.', style: TextStyle(color: AppColors.neutral500)))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                if (neu.isNotEmpty) ...[
                  const Text('NEU', style: TextStyle(fontSize: 10, letterSpacing: 1.1, color: AppColors.accent, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  for (final i in neu) ...[_Row(item: i, accent: true), const SizedBox(height: 8)],
                ],
                if (aelter.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  const Text('ÄLTER', style: TextStyle(fontSize: 10, letterSpacing: 1.1, color: AppColors.neutral500, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  for (final i in aelter) ...[_Row(item: i, accent: false), const SizedBox(height: 8)],
                ],
              ],
            ),
    );
  }
}

class _Item {
  _Item({required this.time, required this.icon, required this.text});
  final DateTime time;
  final IconData icon;
  final String text;
}

class _Row extends StatelessWidget {
  const _Row({required this.item, required this.accent});
  final _Item item;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: accent ? 1 : 0.8,
      child: NCard(
        borderColor: accent ? AppColors.accent : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(item.icon, size: 16, color: accent ? AppColors.accent : AppColors.text),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item.text, style: const TextStyle(fontSize: 13, height: 1.45, color: AppColors.text)),
                  const SizedBox(height: 2),
                  Text(formatRelative(item.time), style: const TextStyle(fontSize: 10.5, color: AppColors.neutral500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
