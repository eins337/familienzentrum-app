import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../../utils/group_colors.dart';
import '../../widgets/n_avatar.dart';
import '../../widgets/n_button.dart';
import '../../widgets/n_card.dart';
import '../../widgets/n_header.dart';
import '../../widgets/post_card.dart';
import 'gruppe_gallery.dart';

class GruppeDetailScreen extends ConsumerWidget {
  const GruppeDetailScreen({super.key, required this.groupId});
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsProvider).valueOrNull ?? [];
    final group = groups.where((g) => g.id == groupId).firstOrNull;
    final team = ref.watch(groupTeamProvider(groupId)).valueOrNull ?? [];
    final postsAsync = ref.watch(groupPostsProvider(groupId));
    final childrenAsync = ref.watch(childrenInGroupProvider(groupId));
    final profile = ref.watch(profileProvider).valueOrNull;

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
                    style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.background)),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Gruppe ${groupName(groupId)}', style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 19, color: AppColors.ink)),
                    if (group != null)
                      Text('${group.childCount} Kinder · ${team.map((t) => t.name).join(', ')}',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
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
          childrenAsync.when(
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
            data: (children) {
              final visible = profile != null && !profile.isTeam
                  ? children.where((c) => c.familyId != profile.familyId).toList()
                  : children;
              if (visible.isEmpty) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: NCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('KINDER DER GRUPPE', style: TextStyle(fontFamily: 'Outfit', fontSize: 10, letterSpacing: 1.3, color: AppColors.primary, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      if (profile != null && !profile.isTeam)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 6),
                          child: Text('Zum Spielen einladen oder eine Nachricht schreiben.', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                        ),
                      for (final c in visible) _ChildRow(child: c, isTeam: profile?.isTeam ?? false),
                    ],
                  ),
                ),
              );
            },
          ),
          postsAsync.when(
            loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: AppColors.primary))),
            error: (e, _) => Text('Fehler: $e'),
            data: (posts) {
              final galleryUrls = [for (final p in posts) if (p.kind == 'foto') ...p.photoUrls];
              return Column(
                children: [
                  for (final p in posts) ...[PostCard(post: p, showGroupHeader: false), const SizedBox(height: 10)],
                  if (galleryUrls.isNotEmpty) ...[GruppeGallery(photoUrls: galleryUrls), const SizedBox(height: 10)],
                ],
              );
            },
          ),
          NCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TEAM DER GRUPPE', style: TextStyle(fontFamily: 'Outfit', fontSize: 10, letterSpacing: 1.3, color: AppColors.primary, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                for (final t in team)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Row(
                      children: [
                        Container(width: 28, height: 28, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.soft)),
                        const SizedBox(width: 9),
                        Text(t.name, style: const TextStyle(fontSize: 13, color: AppColors.ink)),
                        const Spacer(),
                        Text(t.title, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
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

class _ChildRow extends ConsumerStatefulWidget {
  const _ChildRow({required this.child, required this.isTeam});
  final Child child;
  final bool isTeam;

  @override
  ConsumerState<_ChildRow> createState() => _ChildRowState();
}

class _ChildRowState extends ConsumerState<_ChildRow> {
  bool _loading = false;

  Future<void> _startChat() async {
    final myId = ref.read(profileProvider).valueOrNull?.id;
    if (myId == null) return;
    setState(() => _loading = true);
    try {
      final toUid = await ref.read(kitaServiceProvider).fetchPrimaryFamilyMemberUid(widget.child.familyId);
      if (toUid == null || toUid == myId) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Für diese Familie ist noch kein Elternteil registriert.')));
        return;
      }
      final chat = await ref.read(chatsServiceProvider).findOrCreateDirectChat(myId, toUid);
      if (mounted) context.push('/chats/${chat.id}');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final families = ref.watch(allFamiliesProvider).valueOrNull ?? {};
    final familyName = families[widget.child.familyId]?.name;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          NAvatar(initials: widget.child.name.isEmpty ? '?' : widget.child.name[0].toUpperCase(), size: 28),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.child.name, style: const TextStyle(fontSize: 13, color: AppColors.ink)),
                if (familyName != null) Text(familyName, style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
              ],
            ),
          ),
          if (_loading)
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
          else ...[
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17, color: AppColors.primary),
              tooltip: 'Chat',
              onPressed: _startChat,
            ),
            if (!widget.isTeam)
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: AppColors.primary),
                tooltip: 'Spielanfrage',
                onPressed: () => context.push('/spielanfrage-neu?childId=${widget.child.id}'),
              ),
          ],
        ],
      ),
    );
  }
}
