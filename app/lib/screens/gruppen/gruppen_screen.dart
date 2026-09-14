import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../../utils/group_colors.dart';
import '../../widgets/n_button.dart';
import '../../widgets/n_card.dart';
import '../../widgets/n_header.dart';

class GruppenScreen extends ConsumerWidget {
  const GruppenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsProvider);
    final profile = ref.watch(profileProvider).valueOrNull;
    final myChildrenAsync = ref.watch(myChildrenProvider);
    final isTeam = profile?.isTeam ?? false;

    return Scaffold(
      appBar: NHeader(title: 'Gruppen', subtitle: 'Blau · Gelb · Rot', hasUnread: true, onBell: () => context.push('/mitteilungen')),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (groups) {
          // Surface myChildrenProvider's own loading/error state instead of
          // silently defaulting to an empty list — a parent whose child
          // list hadn't loaded yet (or failed to) saw a blank "no groups"
          // screen with no explanation of why.
          if (!isTeam && myChildrenAsync.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (!isTeam && myChildrenAsync.hasError) {
            return Center(child: Text('Fehler: ${myChildrenAsync.error}'));
          }
          final myChildren = myChildrenAsync.valueOrNull ?? [];
          final myGroupIds = myChildren.map((c) => c.groupId).whereType<String>().toSet();
          final visibleGroups = isTeam ? groups : groups.where((g) => myGroupIds.contains(g.id)).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Text(
                isTeam ? 'Jede Gruppe hat einen eigenen Feed, eigene Termine und einen Elternchat.' : 'Der Feed, die Termine und der Elternchat deiner Gruppe.',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 8),
              if (!isTeam && visibleGroups.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: NCard(
                    child: Text(
                      myChildren.isEmpty
                          ? 'Für dein Konto ist noch kein Kind hinterlegt. Bitte wende dich an das Team, damit dein Kind einer Familie zugeordnet wird.'
                          : 'Deinem Kind ist noch keine Gruppe zugeordnet. Bitte wende dich an das Team.',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                    ),
                  ),
                ),
              for (final g in visibleGroups) ...[
                _GroupRow(groupId: g.id, name: g.name, childCount: g.childCount, onTap: () => context.push('/gruppen/${g.id}')),
                const SizedBox(height: 8),
              ],
              if (!isTeam && visibleGroups.isNotEmpty) ...[
                const SizedBox(height: 2),
                _ShortcutRow(groupId: visibleGroups.first.id),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 4),
              NCard(
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

class _ShortcutRow extends ConsumerWidget {
  const _ShortcutRow({required this.groupId});
  final String groupId;

  Future<void> _openChannel(BuildContext context, WidgetRef ref, String channel) async {
    try {
      final label = channel == 'eltern' ? 'Eltern Gruppe ${groupName(groupId)}' : 'Team Gruppe ${groupName(groupId)}';
      final chat = await ref.read(chatsServiceProvider).findOrCreateGroupChat(groupId: groupId, channel: channel, name: label);
      if (context.mounted) context.push('/chats/${chat.id}');
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: NButton(
            label: 'Elternchat',
            variant: NButtonVariant.secondary,
            small: true,
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            onPressed: () => _openChannel(context, ref, 'eltern'),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: NButton(
            label: 'An alle Erzieher',
            variant: NButtonVariant.secondary,
            small: true,
            icon: const Icon(Icons.groups_2_outlined),
            onPressed: () => _openChannel(context, ref, 'team'),
          ),
        ),
      ],
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
