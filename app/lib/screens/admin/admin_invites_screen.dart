import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import '../../models/models.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../../widgets/n_button.dart';
import '../../widgets/n_card.dart';
import '../../widgets/n_field.dart';
import '../../widgets/n_header.dart';
import '../../widgets/n_radio.dart';
import '../../widgets/n_tag.dart';
import '../../widgets/n_toast.dart';

class AdminInvitesScreen extends ConsumerStatefulWidget {
  const AdminInvitesScreen({super.key});
  @override
  ConsumerState<AdminInvitesScreen> createState() => _AdminInvitesScreenState();
}

class _AdminInvitesScreenState extends ConsumerState<AdminInvitesScreen> {
  String _role = 'parent';
  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _staffTitleCtrl = TextEditingController();
  String? _familyChoice; // null = neue Familie, else existing family id
  final _newFamilyNameCtrl = TextEditingController();
  final Set<String> _groupIds = {};
  bool _creating = false;
  Invite? _justCreated;
  String? _emailWarning;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    _staffTitleCtrl.dispose();
    _newFamilyNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final profile = ref.read(profileProvider).valueOrNull;
    if (profile == null || _emailCtrl.text.trim().isEmpty || _nameCtrl.text.trim().isEmpty) return;
    setState(() => _creating = true);
    try {
      String? familyId = _familyChoice;
      if (_role == 'parent' && familyId == null && _newFamilyNameCtrl.text.trim().isNotEmpty) {
        final fam = await ref.read(adminServiceProvider).createFamily(_newFamilyNameCtrl.text.trim());
        familyId = fam.id;
      }
      final invite = await ref.read(adminServiceProvider).createInvite(
            email: _emailCtrl.text.trim(),
            role: _role,
            displayName: _nameCtrl.text.trim(),
            familyId: _role == 'parent' ? familyId : null,
            groupIds: _role == 'team' ? _groupIds.toList() : null,
            staffTitle: _role == 'team' ? _staffTitleCtrl.text.trim() : null,
            createdBy: profile.id,
          );
      String? emailWarning;
      try {
        await ref.read(adminServiceProvider).sendInviteEmail(email: invite.email, displayName: invite.displayName, code: invite.code);
      } catch (e) {
        emailWarning = 'Einladung wurde erstellt, die E-Mail konnte aber nicht gesendet werden: $e';
      }
      setState(() {
        _justCreated = invite;
        _emailWarning = emailWarning;
        _emailCtrl.clear();
        _nameCtrl.clear();
        _staffTitleCtrl.clear();
        _newFamilyNameCtrl.clear();
        _familyChoice = null;
        _groupIds.clear();
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e')));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final familiesAsync = ref.watch(adminServiceProvider).streamFamilies();
    final invitesAsync = ref.watch(adminServiceProvider).streamInvites();
    final groupsAsync = ref.watch(groupsProvider);

    return Scaffold(
      appBar: const NHeader(title: 'Einladungen', showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (_justCreated != null) ...[
            NCard(
              borderColor: AppColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('EINLADUNG ERSTELLT', style: TextStyle(fontFamily: 'Outfit', fontSize: 10, letterSpacing: 1.3, color: AppColors.primary, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text('${_justCreated!.displayName} (${_justCreated!.email}) meldet sich mit diesem Code an:', style: const TextStyle(fontSize: 13, color: AppColors.ink)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: Text(_justCreated!.code, style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 22, letterSpacing: 3, color: AppColors.primary)),
                  ),
                  const SizedBox(height: 8),
                  if (_emailWarning != null)
                    Text(_emailWarning!, style: const TextStyle(fontSize: 12, color: AppColors.error))
                  else
                    const Text('Einladungscode wurde per E-Mail verschickt.', style: TextStyle(fontSize: 12, color: AppColors.success)),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          const Text('Rolle', style: TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Column(
              children: [
                NRadioRow(label: 'Familie (Eltern)', selected: _role == 'parent', onTap: () => setState(() => _role = 'parent')),
                NRadioRow(label: 'Kita-Team', selected: _role == 'team', onTap: () => setState(() => _role = 'team')),
              ],
            ),
          ),
          const SizedBox(height: 10),
          NField(label: 'E-Mail', controller: _emailCtrl, hintText: 'familie@example.de', keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 10),
          NField(label: 'Name (z.B. Elternteil)', controller: _nameCtrl, hintText: 'Sandra Weber'),
          if (_role == 'parent') ...[
            const SizedBox(height: 10),
            const Text('Familie', style: TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 5),
            StreamBuilder<List<Family>>(
              stream: familiesAsync,
              builder: (context, snap) {
                final families = snap.data ?? [];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: Column(
                    children: [
                      NRadioRow(label: 'Neue Familie anlegen', selected: _familyChoice == null, onTap: () => setState(() => _familyChoice = null)),
                      for (final f in families) NRadioRow(label: f.name, selected: _familyChoice == f.id, onTap: () => setState(() => _familyChoice = f.id)),
                    ],
                  ),
                );
              },
            ),
            if (_familyChoice == null) ...[
              const SizedBox(height: 8),
              NField(label: 'Name der neuen Familie', controller: _newFamilyNameCtrl, hintText: 'Familie Weber'),
            ],
          ],
          if (_role == 'team') ...[
            const SizedBox(height: 10),
            NField(label: 'Titel (optional)', controller: _staffTitleCtrl, hintText: 'z.B. Gruppenleitung'),
            const SizedBox(height: 10),
            const Text('Gruppen', style: TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 5),
            groupsAsync.when(
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
              data: (groups) => Wrap(
                spacing: 6,
                children: [
                  for (final g in groups)
                    FilterChip(
                      label: Text('Gruppe ${g.name}'),
                      selected: _groupIds.contains(g.id),
                      onSelected: (sel) => setState(() => sel ? _groupIds.add(g.id) : _groupIds.remove(g.id)),
                      backgroundColor: AppColors.surface,
                      selectedColor: AppColors.primarySoft,
                      labelStyle: TextStyle(fontSize: 12, color: _groupIds.contains(g.id) ? AppColors.primaryInk : AppColors.ink),
                      side: BorderSide.none,
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          NButton(label: 'Einladung erstellen', variant: NButtonVariant.primary, block: true, loading: _creating, onPressed: _create),
          const SizedBox(height: 18),
          const Text('BISHERIGE EINLADUNGEN', style: TextStyle(fontFamily: 'Outfit', fontSize: 10, letterSpacing: 1.3, color: AppColors.primary, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          StreamBuilder<List<Invite>>(
            stream: invitesAsync,
            builder: (context, snap) {
              final invites = snap.data ?? [];
              if (invites.isEmpty) return const Text('Noch keine Einladungen.', style: TextStyle(fontSize: 12.5, color: AppColors.muted));
              return Column(
                children: [
                  for (final inv in invites)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: NCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(inv.displayName, style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 13.5, color: AppColors.ink)),
                                  Text(inv.email, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                                ],
                              ),
                            ),
                            NTag(inv.redeemedAt != null ? 'eingelöst' : 'offen', variant: inv.redeemedAt != null ? NTagVariant.accent : NTagVariant.neutral),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.muted),
                              onPressed: () => runOrShowError(context, () => ref.read(adminServiceProvider).deleteInvite(inv.email)),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
