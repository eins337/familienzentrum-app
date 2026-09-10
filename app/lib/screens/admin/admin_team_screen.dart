import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../../widgets/n_avatar.dart';
import '../../widgets/n_card.dart';
import '../../widgets/n_header.dart';
import '../../widgets/n_radio.dart';
import '../../widgets/n_tag.dart';

class AdminTeamScreen extends ConsumerWidget {
  const AdminTeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminServiceProvider).streamAllUsers();
    final myId = ref.watch(profileProvider).valueOrNull?.id;

    return Scaffold(
      appBar: const NHeader(title: 'Team & Rollen', showBack: true),
      body: StreamBuilder<List<Profile>>(
        stream: usersAsync,
        builder: (context, snap) {
          final users = snap.data ?? [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              for (final u in users) ...[
                _UserRow(user: u, isSelf: u.id == myId),
                const SizedBox(height: 8),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _UserRow extends ConsumerWidget {
  const _UserRow({required this.user, required this.isSelf});
  final Profile user;
  final bool isSelf;

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final groups = await ref.read(groupsProvider.future);
    if (!context.mounted) return;
    String role = user.role;
    bool isAdmin = user.isAdmin;
    final groupIds = user.groupIds.toSet();
    final staffTitleCtrl = TextEditingController(text: user.staffTitle);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(user.displayName, style: const TextStyle(color: AppColors.text)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NRadioRow(label: 'Familie (Eltern)', selected: role == 'parent', onTap: () => setState(() => role = 'parent')),
                NRadioRow(label: 'Kita-Team', selected: role == 'team', onTap: () => setState(() => role = 'team')),
                const SizedBox(height: 8),
                NRadioRow(label: 'Admin-Rechte', selected: isAdmin, onTap: () => setState(() => isAdmin = !isAdmin)),
                if (role == 'team') ...[
                  const SizedBox(height: 8),
                  TextField(controller: staffTitleCtrl, style: const TextStyle(color: AppColors.text), decoration: const InputDecoration(hintText: 'Titel, z.B. Gruppenleitung')),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final g in groups)
                        FilterChip(
                          label: Text('Gruppe ${g.name}'),
                          selected: groupIds.contains(g.id),
                          onSelected: (sel) => setState(() => sel ? groupIds.add(g.id) : groupIds.remove(g.id)),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
            TextButton(
              onPressed: () async {
                await ref.read(adminServiceProvider).updateUserAdmin(
                      user.id,
                      role: role,
                      isAdmin: isAdmin,
                      groupIds: role == 'team' ? groupIds.toList() : [],
                      staffTitle: staffTitleCtrl.text.trim(),
                    );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NCard(
      child: Row(
        children: [
          NAvatar(initials: user.displayName.isEmpty ? '?' : user.displayName[0].toUpperCase(), size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(user.displayName, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 13.5, color: AppColors.text), overflow: TextOverflow.ellipsis)),
                    if (user.isAdmin) ...[const SizedBox(width: 6), const NTag('Admin', variant: NTagVariant.accent)],
                    if (user.disabled) ...[const SizedBox(width: 6), const NTag('Gesperrt', variant: NTagVariant.outline)],
                  ],
                ),
                Text(user.email, style: const TextStyle(fontSize: 11, color: AppColors.neutral500)),
                Text(user.isTeam ? (user.staffTitle ?? 'Kita-Team') : 'Familie', style: const TextStyle(fontSize: 11, color: AppColors.neutral400)),
              ],
            ),
          ),
          if (!isSelf) ...[
            IconButton(
              icon: Icon(user.disabled ? Icons.lock_open_rounded : Icons.lock_outline_rounded, size: 18, color: AppColors.neutral500),
              onPressed: () => ref.read(adminServiceProvider).setUserAccountDisabled(user.id, !user.disabled),
            ),
            IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.neutral500), onPressed: () => _edit(context, ref)),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.neutral500),
              onPressed: () => ref.read(adminServiceProvider).deleteUserAccount(user.id),
            ),
          ] else
            IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.neutral500), onPressed: () => _edit(context, ref)),
        ],
      ),
    );
  }
}
