import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../../utils/group_colors.dart';
import '../../widgets/n_card.dart';
import '../../widgets/n_header.dart';

class GruppenScreen extends ConsumerWidget {
  const GruppenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsProvider);

    return Scaffold(
      appBar: NHeader(title: 'Gruppen', subtitle: 'Blau · Gelb · Rot', hasUnread: true, onBell: () => context.push('/mitteilungen')),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (groups) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              const Text('Jede Gruppe hat einen eigenen Feed, eigene Termine und einen Elternchat.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted)),
              const SizedBox(height: 8),
              for (final g in groups) ...[
                _GroupRow(groupId: g.id, name: g.name, childCount: g.childCount, onTap: () => context.push('/gruppen/${g.id}')),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 4),
              NCard(
                background: Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ÜBERGREIFEND', style: TextStyle(fontFamily: 'Outfit', fontSize: 10, letterSpacing: 1.3, color: AppColors.primary, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 9),
                    for (final t in const ['Elternbeirat', 'Vorschulkinder 2026', 'Familientreff am Samstag'])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: Row(
                          children: [
                            Container(width: 5, height: 5, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary)),
                            const SizedBox(width: 9),
                            Text(t, style: const TextStyle(fontSize: 13, color: AppColors.ink)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GroupRow extends ConsumerWidget {
  const _GroupRow({required this.groupId, required this.name, required this.childCount, required this.onTap});
  final String groupId;
  final String name;
  final int childCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team = ref.watch(groupTeamProvider(groupId)).valueOrNull ?? [];
    final teamLabel = team.isEmpty ? '' : ' · ${team.map((t) => t.name).join(', ')}';
    return NCard(
      onTap: onTap,
      borderColor: groupColor(groupId),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: groupColor(groupId), borderRadius: BorderRadius.circular(11)),
            child: Text(groupInitial(groupId), style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.background)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name, style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.ink)),
                Text('$childCount Kinder$teamLabel', style: const TextStyle(fontSize: 11.5, color: AppColors.muted), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
