import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../../utils/group_colors.dart';
import '../../utils/time_format.dart';
import '../../widgets/n_avatar.dart';
import '../../widgets/n_button.dart';
import '../../widgets/n_card.dart';
import '../../widgets/n_header.dart';
import '../../widgets/n_radio.dart';
import '../../widgets/post_card.dart';
import '../../widgets/wochenrueckblick_card.dart';
import 'gruppe_gallery.dart';

Future<void> _openChannel(BuildContext context, WidgetRef ref, String groupId, String channel) async {
  try {
    final label = channel == 'eltern' ? 'Eltern Gruppe ${groupName(groupId)}' : 'Team Gruppe ${groupName(groupId)}';
    final chat = await ref.read(chatsServiceProvider).findOrCreateGroupChat(groupId: groupId, channel: channel, name: label);
    if (context.mounted) context.push('/chats/${chat.id}');
  } catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e')));
  }
}

/// Admin-only editor: which Erzieher (team profiles) belong to this group,
/// and which one of them is the Gruppenleitung.
Future<void> _editGroupTeam(BuildContext context, WidgetRef ref, String groupId, List<Profile> currentTeam, Profile? currentLead) async {
  final allProfiles = ref.read(allProfilesProvider).valueOrNull ?? {};
  final allTeamProfiles = allProfiles.values.where((p) => p.isTeam).toList()..sort((a, b) => a.displayName.compareTo(b.displayName));
  final memberIds = currentTeam.map((t) => t.id).toSet();
  String? leadId = currentLead?.id;

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Erzieher & Gruppenleitung', style: TextStyle(color: AppColors.ink)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Erzieher in dieser Gruppe', style: TextStyle(fontSize: 12, color: AppColors.muted)),
              const SizedBox(height: 6),
              for (final p in allTeamProfiles)
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.primary,
                  title: Text(p.displayName, style: const TextStyle(fontSize: 13.5, color: AppColors.ink)),
                  value: memberIds.contains(p.id),
                  onChanged: (sel) => setState(() {
                    if (sel ?? false) {
                      memberIds.add(p.id);
                    } else {
                      memberIds.remove(p.id);
                      if (leadId == p.id) leadId = null;
                    }
                  }),
                ),
              const SizedBox(height: 10),
              const Text('Gruppenleitung', style: TextStyle(fontSize: 12, color: AppColors.muted)),
              const SizedBox(height: 6),
              if (memberIds.isEmpty) const Text('Erst Erzieher zuordnen.', style: TextStyle(fontSize: 12.5, color: AppColors.muted)),
              for (final p in allTeamProfiles.where((p) => memberIds.contains(p.id)))
                NRadioRow(label: p.displayName, selected: leadId == p.id, onTap: () => setState(() => leadId = p.id)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          TextButton(
            onPressed: () async {
              try {
                await ref.read(adminServiceProvider).setGroupMembers(groupId, allTeamProfiles, memberIds);
                await ref.read(adminServiceProvider).updateGroupLead(groupId, leadId);
                ref.invalidate(groupsProvider);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e')));
              }
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    ),
  );
}

class GruppeDetailScreen extends ConsumerWidget {
  const GruppeDetailScreen({super.key, required this.groupId});
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsProvider).valueOrNull ?? [];
    final group = groups.where((g) => g.id == groupId).firstOrNull;
    final allProfiles = ref.watch(allProfilesProvider).valueOrNull ?? {};
    // Real Erzieher assignment lives on profiles.group_ids — the old
    // `group_team_members` table (below via groupTeamProvider) was a
    // display-only roster with no link to an actual login, so admins had
    // no way to edit who it showed. This is the real, editable source.
    final team = allProfiles.values.where((p) => p.isTeam && p.groupIds.contains(groupId)).toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    final lead = group?.leadProfileId != null ? allProfiles[group!.leadProfileId] : null;
    final postsAsync = ref.watch(groupPostsProvider(groupId));
    final childrenAsync = ref.watch(childrenInGroupProvider(groupId));
    final profile = ref.watch(profileProvider).valueOrNull;

    return Scaffold(
      appBar: NHeader(
        title: 'Gruppe ${groupName(groupId)}',
        subtitle: group == null ? null : '${group.childCount} Kinder · ${team.map((t) => t.displayName).join(', ')}',
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
                      Text('${group.childCount} Kinder · ${team.map((t) => t.displayName).join(', ')}',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: NButton(label: 'Elternchat', variant: NButtonVariant.secondary, small: true, onPressed: () => _openChannel(context, ref, groupId, 'eltern'))),
              const SizedBox(width: 6),
              Expanded(child: NButton(label: 'Erzieher', variant: NButtonVariant.secondary, small: true, onPressed: () => _openChannel(context, ref, groupId, 'team'))),
              const SizedBox(width: 6),
              Expanded(child: NButton(label: 'Spielanfrage', variant: NButtonVariant.secondary, small: true, onPressed: () => context.push('/spielanfrage-neu'))),
            ],
          ),
          const SizedBox(height: 10),
          postsAsync.when(
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
            data: (posts) {
              final rueckblicke = posts.where((p) => p.kind == 'wochenrueckblick' && !isWochenrueckblickExpired(p.createdAt)).toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
              final current = rueckblicke.firstOrNull;
              if (current == null && !(profile?.isTeam ?? false)) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  children: [
                    if (current != null) WochenrueckblickCard(post: current),
                    if (profile?.isTeam ?? false) ...[
                      const SizedBox(height: 8),
                      NButton(
                        label: 'Neuen Wochenrückblick erstellen',
                        variant: NButtonVariant.primary,
                        small: true,
                        block: true,
                        onPressed: () => context.push('/post-erstellen?groupId=$groupId&kind=wochenrueckblick'),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          if (profile?.isTeam ?? false)
            childrenAsync.when(
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
              data: (children) {
                final withHints = children.where((c) => c.tags.isNotEmpty).toList();
                if (withHints.isEmpty) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: NCard(
                    background: AppColors.warningSoft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 15, color: AppColors.warningInk),
                            const SizedBox(width: 7),
                            Text('Wichtige Hinweise der Familien', style: AppText.outfit(size: 14, weight: FontWeight.w600, color: AppColors.warningInk)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        for (final c in withHints)
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.input)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.name, style: AppText.outfit(size: 13.5, weight: FontWeight.w600, color: AppColors.ink)),
                                const SizedBox(height: 3),
                                Text(c.tags.join(' · '), style: AppText.nunito(size: 12, color: AppColors.ink2)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
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
                      for (final c in visible) _ChildRow(child: c, isTeam: profile?.isTeam ?? false, isAdmin: profile?.isAdmin ?? false),
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
              final visiblePosts = posts.where((p) => p.kind != 'wochenrueckblick').toList();
              final galleryUrls = [for (final p in visiblePosts) if (p.kind == 'foto') ...p.photoUrls];
              return Column(
                children: [
                  for (final p in visiblePosts) ...[PostCard(post: p, showGroupHeader: false), const SizedBox(height: 10)],
                  if (galleryUrls.isNotEmpty) ...[GruppeGallery(photoUrls: galleryUrls), const SizedBox(height: 10)],
                ],
              );
            },
          ),
          NCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('TEAM DER GRUPPE', style: TextStyle(fontFamily: 'Outfit', fontSize: 10, letterSpacing: 1.3, color: AppColors.primary, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    if (profile?.isAdmin ?? false)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.mutedAlt),
                        onPressed: () => _editGroupTeam(context, ref, groupId, team, lead),
                        tooltip: 'Erzieher & Gruppenleitung bearbeiten',
                      ),
                  ],
                ),
                if (team.isEmpty) const Text('Noch kein Team zugeordnet.', style: TextStyle(fontSize: 12.5, color: AppColors.muted)),
                for (final t in team)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Row(
                      children: [
                        NAvatar(initials: t.displayName.isEmpty ? '?' : t.displayName[0].toUpperCase(), size: 28),
                        const SizedBox(width: 9),
                        Expanded(child: Text(t.displayName, style: const TextStyle(fontSize: 13, color: AppColors.ink))),
                        if (lead?.id == t.id) ...[
                          const Icon(Icons.star_rounded, size: 15, color: AppColors.primary),
                          const SizedBox(width: 4),
                          const Text('Gruppenleitung', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ] else
                          Text(t.staffTitle ?? 'Fachkraft', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
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
  const _ChildRow({required this.child, required this.isTeam, this.isAdmin = false});
  final Child child;
  final bool isTeam;
  final bool isAdmin;

  @override
  ConsumerState<_ChildRow> createState() => _ChildRowState();
}

class _ChildRowState extends ConsumerState<_ChildRow> {
  bool _loading = false;

  Future<void> _changeGroup() async {
    final groups = await ref.read(groupsProvider.future);
    if (!mounted) return;
    final newGroupId = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: AppColors.surface,
        title: Text('${widget.child.name} — Gruppe wählen', style: const TextStyle(color: AppColors.ink)),
        children: [
          for (final g in groups)
            SimpleDialogOption(onPressed: () => Navigator.pop(context, g.id), child: Text('Gruppe ${g.name}', style: const TextStyle(color: AppColors.ink))),
        ],
      ),
    );
    if (newGroupId == null || newGroupId == widget.child.groupId) return;
    try {
      await ref.read(adminServiceProvider).updateChildAdmin(widget.child.id, groupId: newGroupId);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e')));
    }
  }

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
                if (widget.isTeam && ((widget.child.bringTime?.isNotEmpty ?? false) || (widget.child.pickupTime?.isNotEmpty ?? false)))
                  Text(
                    [
                      if (widget.child.bringTime?.isNotEmpty ?? false) 'Bringen: ${widget.child.bringTime}',
                      if (widget.child.pickupTime?.isNotEmpty ?? false) 'Abholen: ${widget.child.pickupTime}',
                    ].join(' · '),
                    style: const TextStyle(fontSize: 10.5, color: AppColors.primaryInk),
                  ),
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
            if (widget.isAdmin)
              IconButton(
                icon: const Icon(Icons.swap_horiz_rounded, size: 18, color: AppColors.mutedAlt),
                tooltip: 'Gruppe wechseln',
                onPressed: _changeGroup,
              ),
          ],
        ],
      ),
    );
  }
}
