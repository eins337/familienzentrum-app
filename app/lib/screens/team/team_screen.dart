import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../../utils/group_colors.dart';
import '../../widgets/n_button.dart';
import '../../widgets/n_card.dart';
import '../../widgets/n_header.dart';
import '../../widgets/n_toast.dart';

class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    if (profile == null) return const Scaffold(body: SizedBox());
    final sickReportsAsync = ref.watch(kitaServiceProvider).streamSickReports(onlyOpen: true);
    final children = ref.watch(allChildrenProvider).valueOrNull ?? {};

    return Scaffold(
      appBar: NHeader(title: 'Team', subtitle: profile.staffTitle ?? 'Kita-Team', hasUnread: true, onBell: () => context.push('/mitteilungen')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          NButton(
            label: 'Beitrag oder Info erstellen',
            variant: NButtonVariant.primary,
            block: true,
            alignStart: true,
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/post-erstellen'),
          ),
          const SizedBox(height: 10),
          NButton(
            label: 'Termine, Speiseplan & Dokumente',
            variant: NButtonVariant.secondary,
            block: true,
            alignStart: true,
            icon: const Icon(Icons.article_outlined),
            onPressed: () => context.push('/admin/content'),
          ),
          const SizedBox(height: 8),
          if (profile.isAdmin) ...[
            NButton(
              label: 'Admin-Bereich',
              variant: NButtonVariant.secondary,
              block: true,
              alignStart: true,
              icon: const Icon(Icons.admin_panel_settings_outlined),
              onPressed: () => context.push('/admin'),
            ),
            const SizedBox(height: 14),
          ],
          if (profile.groupIds.isNotEmpty) ...[
            const _Kicker('Deine Gruppen'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final g in profile.groupIds)
                  InkWell(
                    onTap: () => context.push('/gruppen/$g'),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(border: Border.all(color: groupColor(g)), borderRadius: BorderRadius.circular(AppRadius.md)),
                      child: Text('Gruppe ${groupName(g)}', style: TextStyle(fontSize: 12.5, color: groupColor(g))),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          const _Kicker('Offene Krankmeldungen'),
          const SizedBox(height: 8),
          StreamBuilder(
            stream: sickReportsAsync,
            builder: (context, snap) {
              var reports = snap.data ?? [];
              if (profile.groupIds.isNotEmpty) {
                reports = reports.where((r) => r.groupId == null || profile.groupIds.contains(r.groupId)).toList();
              }
              if (reports.isEmpty) {
                return const Text('Keine offenen Krankmeldungen.', style: TextStyle(fontSize: 12.5, color: AppColors.muted));
              }
              return Column(
                children: [
                  for (final r in reports)
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
                                  Text(children[r.childId]?.name ?? r.childName ?? '…',
                                      style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.ink)),
                                  Text(
                                    [r.dateLabel, r.reason].whereType<String>().join(' · '),
                                    style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
                                  ),
                                ],
                              ),
                            ),
                            NButton(
                              label: 'Erledigt',
                              variant: NButtonVariant.secondary,
                              small: true,
                              onPressed: () => runOrShowError(context, () => ref.read(kitaServiceProvider).acknowledgeSickReport(r.id)),
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

class _Kicker extends StatelessWidget {
  const _Kicker(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: const TextStyle(fontFamily: 'Outfit', fontSize: 10, letterSpacing: 1.3, color: AppColors.primary, fontWeight: FontWeight.w800));
}
