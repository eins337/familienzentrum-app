import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../../utils/group_colors.dart';
import '../../widgets/n_button.dart';
import '../../widgets/n_card.dart';
import '../../widgets/n_header.dart';
import '../../widgets/post_card.dart';

class GruppeDetailScreen extends ConsumerWidget {
  const GruppeDetailScreen({super.key, required this.groupId});
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsProvider).valueOrNull ?? [];
    final group = groups.where((g) => g.id == groupId).firstOrNull;
    final team = ref.watch(groupTeamProvider(groupId)).valueOrNull ?? [];
    final postsAsync = ref.watch(groupPostsProvider(groupId));

    return Scaffold(
      appBar: NHeader(
        title: 'Gruppe ${groupName(groupId)}',
        subtitle: group == null ? null : '${group.childCount} Kinder · ${team.map((t) => t.name).join(', ')}',
        showBack: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: groupColor(groupId), borderRadius: BorderRadius.circular(13)),
                child: Text(groupInitial(groupId),
                    style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 16, color: AppColors.bg)),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Gruppe ${groupName(groupId)}', style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 19, color: AppColors.text)),
                    if (group != null)
                      Text('${group.childCount} Kinder · ${team.map((t) => t.name).join(', ')}',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.neutral400)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: NButton(label: 'Elternchat', variant: NButtonVariant.secondary, small: true, onPressed: () => context.push('/chats'))),
              const SizedBox(width: 6),
              Expanded(child: NButton(label: 'Spielanfrage', variant: NButtonVariant.secondary, small: true, onPressed: () => context.push('/spielanfrage-neu'))),
            ],
          ),
          const SizedBox(height: 10),
          postsAsync.when(
            loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: AppColors.accent))),
            error: (e, _) => Text('Fehler: $e'),
            data: (posts) => Column(
              children: [for (final p in posts) ...[PostCard(post: p, showGroupHeader: false), const SizedBox(height: 10)]],
            ),
          ),
          NCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TEAM DER GRUPPE', style: TextStyle(fontSize: 10, letterSpacing: 1.1, color: AppColors.accent, fontWeight: FontWeight.w500)),
                const SizedBox(height: 10),
                for (final t in team)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Row(
                      children: [
                        Container(width: 28, height: 28, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.neutral800)),
                        const SizedBox(width: 9),
                        Text(t.name, style: const TextStyle(fontSize: 13, color: AppColors.text)),
                        const Spacer(),
                        Text(t.title, style: const TextStyle(fontSize: 11, color: AppColors.neutral500)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
