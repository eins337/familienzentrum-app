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
import '../../widgets/n_tag.dart';

class ProfilScreen extends ConsumerStatefulWidget {
  const ProfilScreen({super.key});
  @override
  ConsumerState<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends ConsumerState<ProfilScreen> {
  String? _selectedChildId;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).valueOrNull;
    if (profile == null) return const Scaffold(body: SizedBox());
    if (profile.isTeam) return _TeamProfil(profile: profile);

    final childrenAsync = ref.watch(myChildrenProvider);
    final familyMembers = ref.watch(kitaServiceProvider).streamFamilyMembers();
    final profiles = ref.watch(allProfilesProvider).valueOrNull ?? {};

    return Scaffold(
      appBar: NHeader(title: 'Profil', subtitle: 'Familie', hasUnread: true, onBell: () => context.push('/mitteilungen')),
      body: childrenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (children) {
          if (children.isEmpty) {
            return const Center(child: Text('Noch kein Kind hinterlegt.', style: TextStyle(color: AppColors.neutral500)));
          }
          final child = children.firstWhere((c) => c.id == _selectedChildId, orElse: () => children.first);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              if (children.length > 1) ...[
                Wrap(
                  spacing: 6,
                  children: [
                    for (final c in children)
                      ChoiceChip(
                        label: Text(c.name),
                        selected: c.id == child.id,
                        onSelected: (_) => setState(() => _selectedChildId = c.id),
                        backgroundColor: AppColors.surface,
                        selectedColor: AppColors.accent800,
                        labelStyle: TextStyle(color: c.id == child.id ? AppColors.accent100 : AppColors.text, fontSize: 12),
                        side: BorderSide.none,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  NAvatar(initials: child.name.isEmpty ? '?' : child.name[0].toUpperCase(), size: 56, shape: BoxShape.rectangle, radius: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(child.name, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 20, color: AppColors.text)),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(color: groupColor(child.groupId), borderRadius: BorderRadius.circular(6)),
                              child: Text('Gruppe ${groupName(child.groupId)}', style: const TextStyle(fontSize: 11, color: AppColors.bg)),
                            ),
                            if (child.birthYear != null) ...[
                              const SizedBox(width: 6),
                              Text('${child.age} Jahre', style: const TextStyle(fontSize: 11, color: AppColors.neutral500)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              StreamBuilder<List<FamilyMember>>(
                stream: familyMembers,
                builder: (context, snap) {
                  final members = (snap.data ?? []).where((m) => m.familyId == child.familyId).toList();
                  return NCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Kicker('Familie'),
                        for (final m in members)
                          Padding(
                            padding: const EdgeInsets.only(top: 9),
                            child: Row(
                              children: [
                                NAvatar(initials: _initials(profiles[m.userId]?.displayName ?? '?'), size: 28),
                                const SizedBox(width: 9),
                                Text(profiles[m.userId]?.displayName ?? '…', style: const TextStyle(fontSize: 13, color: AppColors.text)),
                                const Spacer(),
                                Text(
                                  m.userId == profile.id ? '${m.relation} · du' : m.relation,
                                  style: const TextStyle(fontSize: 11, color: AppColors.neutral500),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              NCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Kicker('Wichtig für die Kita'),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [for (final t in child.tags) NTag(t, variant: NTagVariant.neutral)],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              NCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Kicker('Freigaben'),
                    _ToggleRow(
                      label: 'Fotofreigabe für Gruppen-Feed',
                      active: child.photoConsentGroup,
                      onTap: () => ref.read(kitaServiceProvider).updateChildConsent(child.id, photoConsentGroup: !child.photoConsentGroup),
                    ),
                    _ToggleRow(
                      label: 'Fotos auf der Kita-Website',
                      active: child.photoConsentWebsite,
                      onTap: () => ref.read(kitaServiceProvider).updateChildConsent(child.id, photoConsentWebsite: !child.photoConsentWebsite),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              NButton(label: '${child.name.split(' ').first} krankmelden', variant: NButtonVariant.secondary, block: true, small: true, onPressed: () => context.push('/krankmelden/${child.id}')),
              const SizedBox(height: 8),
              NButton(label: 'Infos & Termine', variant: NButtonVariant.secondary, block: true, small: true, onPressed: () => context.push('/infos')),
              const SizedBox(height: 8),
              NButton(label: 'Einstellungen', variant: NButtonVariant.secondary, block: true, small: true, onPressed: () => context.push('/einstellungen')),
            ],
          );
        },
      ),
    );
  }

  String _initials(String name) => name.trim().isEmpty ? '?' : name.trim().split(' ').map((p) => p[0]).take(2).join().toUpperCase();
}

class _TeamProfil extends StatelessWidget {
  const _TeamProfil({required this.profile});
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NHeader(title: 'Profil', subtitle: 'Kita-Team'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Row(
            children: [
              NAvatar(initials: profile.displayName.isEmpty ? '?' : profile.displayName[0].toUpperCase(), size: 56, borderColor: AppColors.accent, foreground: AppColors.accent, background: Colors.transparent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(profile.displayName, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 20, color: AppColors.text)),
                    Text(profile.staffTitle ?? 'Kita-Team', style: const TextStyle(fontSize: 12, color: AppColors.neutral400)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          NCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Kicker('Gruppen'),
                const SizedBox(height: 7),
                Wrap(spacing: 6, children: [for (final g in profile.groupIds) NTag('Gruppe ${groupName(g)}', variant: NTagVariant.neutral)]),
              ],
            ),
          ),
          const SizedBox(height: 10),
          NButton(label: 'Einstellungen', variant: NButtonVariant.secondary, block: true, small: true, onPressed: () => context.push('/einstellungen')),
        ],
      ),
    );
  }
}

class _Kicker extends StatelessWidget {
  const _Kicker(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: const TextStyle(fontSize: 10, letterSpacing: 1.1, color: AppColors.accent, fontWeight: FontWeight.w500));
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.text))),
          InkWell(
            onTap: onTap,
            child: NTag(active ? 'Aktiv' : 'Aus', variant: active ? NTagVariant.accent : NTagVariant.neutral),
          ),
        ],
      ),
    );
  }
}
