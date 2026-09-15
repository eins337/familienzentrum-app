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
import '../../widgets/n_field.dart';
import '../../widgets/n_header.dart';
import '../../widgets/n_tag.dart';
import '../../widgets/n_toast.dart';

const _hinweisPresets = [
  'Nussallergie',
  'Laktoseintoleranz',
  'Vegetarisch',
  'Kein Schweinefleisch',
  'Schläft mittags',
  'Asthma-Spray',
  'Pollenallergie',
  'Sonnencreme nötig',
];

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
    final sickReports = ref.watch(mySickReportsProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: NHeader(title: 'Profil', subtitle: 'Familie', hasUnread: true, onBell: () => context.push('/mitteilungen')),
      body: childrenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (children) {
          if (children.isEmpty) {
            return const Center(child: Text('Noch kein Kind hinterlegt.', style: TextStyle(color: AppColors.muted)));
          }
          final child = children.firstWhere((c) => c.id == _selectedChildId, orElse: () => children.first);
          final activeSickReport = sickReports.where((r) => r.childId == child.id && r.isActive).firstOrNull;

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
                        selectedColor: AppColors.primarySoft,
                        labelStyle: TextStyle(color: c.id == child.id ? AppColors.primaryInk : AppColors.ink, fontSize: 12),
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
                        Text(child.name, style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 20, color: AppColors.ink)),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(color: groupColor(child.groupId), borderRadius: BorderRadius.circular(6)),
                              child: Text('Gruppe ${groupName(child.groupId)}', style: const TextStyle(fontSize: 11, color: AppColors.background)),
                            ),
                            if (child.birthYear != null) ...[
                              const SizedBox(width: 6),
                              Text('${child.age} Jahre', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (activeSickReport != null) ...[
                _SickActiveCard(report: activeSickReport, childFirstName: child.name.split(' ').first),
                const SizedBox(height: 10),
              ],
              NCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(child: _Kicker('Wichtig für die Kita')),
                        InkWell(
                          onTap: () => _editHinweise(context, ref, child),
                          child: const Text('Bearbeiten', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.primary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    if (child.tags.isEmpty)
                      const Text('Noch keine Hinweise hinterlegt.', style: TextStyle(fontSize: 12.5, color: AppColors.muted))
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [for (final t in child.tags) NTag(t, variant: NTagVariant.neutral)],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
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
                                Text(profiles[m.userId]?.displayName ?? '…', style: const TextStyle(fontSize: 13, color: AppColors.ink)),
                                const Spacer(),
                                Text(
                                  m.userId == profile.id ? '${m.relation} · du' : m.relation,
                                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
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
                    const _Kicker('Freigaben'),
                    _ToggleRow(
                      label: 'Fotofreigabe für Gruppen-Feed',
                      active: child.photoConsentGroup,
                      onTap: () async {
                        try {
                          await ref.read(kitaServiceProvider).updateChildConsent(child.id, photoConsentGroup: !child.photoConsentGroup);
                        } catch (e) {
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e')));
                        }
                      },
                    ),
                    _ToggleRow(
                      label: 'Fotos auf der Kita-Website',
                      active: child.photoConsentWebsite,
                      onTap: () async {
                        try {
                          await ref.read(kitaServiceProvider).updateChildConsent(child.id, photoConsentWebsite: !child.photoConsentWebsite);
                        } catch (e) {
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e')));
                        }
                      },
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
              NAvatar(initials: profile.displayName.isEmpty ? '?' : profile.displayName[0].toUpperCase(), size: 56, borderColor: AppColors.primary, foreground: AppColors.primary, background: Colors.transparent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(profile.displayName, style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 20, color: AppColors.ink)),
                    Text(profile.staffTitle ?? 'Kita-Team', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
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
      Text(text.toUpperCase(), style: const TextStyle(fontFamily: 'Outfit', fontSize: 10, letterSpacing: 1.3, color: AppColors.primary, fontWeight: FontWeight.w800));
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
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.ink))),
          InkWell(
            onTap: onTap,
            child: NTag(active ? 'Aktiv' : 'Aus', variant: active ? NTagVariant.accent : NTagVariant.neutral),
          ),
        ],
      ),
    );
  }
}

class _SickActiveCard extends ConsumerWidget {
  const _SickActiveCard({required this.report, required this.childFirstName});
  final SickReport report;
  final String childFirstName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NCard(
      background: AppColors.successSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.successInk),
              const SizedBox(width: 7),
              Text('$childFirstName krankgemeldet', style: AppText.outfit(size: 14.5, weight: FontWeight.w600, color: AppColors.successInk)),
            ],
          ),
          const SizedBox(height: 4),
          Text(report.dateLabel, style: AppText.nunito(size: 12.5, weight: FontWeight.w600, color: AppColors.successInk2)),
          if (report.reason != null) ...[
            const SizedBox(height: 2),
            Text(report.reason!, style: AppText.nunito(size: 12, color: AppColors.successInk2)),
          ],
          const SizedBox(height: 6),
          const Text('Das Team der Gruppe wurde informiert.', style: TextStyle(fontSize: 11, color: AppColors.successInk2)),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              try {
                await ref.read(kitaServiceProvider).cancelSickReport(report.id);
                if (context.mounted) showNToast(context, 'Krankmeldung zurückgenommen.');
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e')));
              }
            },
            child: const Text('Zurücknehmen', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 12.5, color: AppColors.successInk)),
          ),
        ],
      ),
    );
  }
}

Future<void> _editHinweise(BuildContext context, WidgetRef ref, Child child) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheetTop))),
    builder: (context) => _HinweiseSheet(child: child),
  );
  if (saved == true && context.mounted) {
    showNToast(context, 'Hinweise gespeichert — für das Team der Gruppe ${groupName(child.groupId)} sichtbar.');
  }
}

class _HinweiseSheet extends ConsumerStatefulWidget {
  const _HinweiseSheet({required this.child});
  final Child child;

  @override
  ConsumerState<_HinweiseSheet> createState() => _HinweiseSheetState();
}

class _HinweiseSheetState extends ConsumerState<_HinweiseSheet> {
  late List<String> _tags;
  final _freetextCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tags = [...widget.child.tags];
  }

  @override
  void dispose() {
    _freetextCtrl.dispose();
    super.dispose();
  }

  void _toggle(String tag) {
    setState(() => _tags.contains(tag) ? _tags.remove(tag) : _tags.add(tag));
  }

  void _addFreetext() {
    final text = _freetextCtrl.text.trim();
    if (text.isEmpty || _tags.contains(text)) return;
    setState(() {
      _tags.add(text);
      _freetextCtrl.clear();
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(kitaServiceProvider).updateChildTags(widget.child.id, _tags);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 14),
          const Text('Wichtig für die Kita', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 17, color: AppColors.ink)),
          const SizedBox(height: 4),
          const Text('Diese Hinweise sieht das Team der Gruppe deines Kindes.', style: TextStyle(fontSize: 12.5, color: AppColors.muted)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final preset in _hinweisPresets)
                _SelectableChip(label: preset, selected: _tags.contains(preset), onTap: () => _toggle(preset)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: NInput(controller: _freetextCtrl, hintText: 'Eigener Hinweis')),
              const SizedBox(width: 7),
              NButton(icon: const Icon(Icons.add_rounded), variant: NButtonVariant.secondary, iconOnly: true, onPressed: _addFreetext),
            ],
          ),
          if (_tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Aktuell hinterlegt — tippen zum Entfernen', style: TextStyle(fontSize: 11, color: AppColors.muted)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final t in _tags) _SelectableChip(label: t, selected: true, onTap: () => _toggle(t))],
            ),
          ],
          const SizedBox(height: 16),
          NButton(label: 'Speichern', variant: NButtonVariant.primary, block: true, loading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}

class _SelectableChip extends StatelessWidget {
  const _SelectableChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.warningSoft : AppColors.surface,
          border: Border.all(color: selected ? AppColors.warning : AppColors.cardBorder),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(label, style: TextStyle(fontSize: 12.5, color: selected ? AppColors.warningInk : AppColors.ink)),
      ),
    );
  }
}
