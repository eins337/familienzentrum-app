import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../../utils/group_colors.dart';
import '../../utils/time_format.dart';
import '../../widgets/n_button.dart';
import '../../widgets/n_card.dart';
import '../../widgets/n_header.dart';
import '../../widgets/n_segmented.dart';
import '../../widgets/n_tag.dart';

class AdminSickReportsScreen extends ConsumerStatefulWidget {
  const AdminSickReportsScreen({super.key});
  @override
  ConsumerState<AdminSickReportsScreen> createState() => _AdminSickReportsScreenState();
}

class _AdminSickReportsScreenState extends ConsumerState<AdminSickReportsScreen> {
  String _tab = 'offen';

  @override
  Widget build(BuildContext context) {
    final children = ref.watch(allChildrenProvider).valueOrNull ?? {};
    final reportsAsync = ref.watch(kitaServiceProvider).streamSickReports(onlyOpen: _tab == 'offen');

    return Scaffold(
      appBar: const NHeader(title: 'Krankmeldungen', showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          NSegmented<String>(
            expand: true,
            value: _tab,
            options: const [('offen', 'Offen'), ('alle', 'Alle')],
            onChanged: (v) => setState(() => _tab = v),
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<SickReport>>(
            stream: reportsAsync,
            builder: (context, snap) {
              final reports = snap.data ?? [];
              if (reports.isEmpty) return const Padding(padding: EdgeInsets.only(top: 20), child: Text('Keine Krankmeldungen.', style: TextStyle(color: AppColors.muted)));
              return Column(
                children: [
                  for (final r in reports)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: NCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (r.groupId != null) NTag('Gruppe ${groupName(r.groupId)}', variant: NTagVariant.neutral),
                                const Spacer(),
                                Text(formatRelative(r.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(children[r.childId]?.name ?? r.childName ?? '…', style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.ink)),
                            Text(r.dateLabel, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                            if (r.reason != null) Text(r.reason!, style: const TextStyle(fontSize: 12.5, color: AppColors.ink)),
                            if (!r.acknowledged) ...[
                              const SizedBox(height: 8),
                              NButton(label: 'Als erledigt markieren', variant: NButtonVariant.secondary, small: true, onPressed: () => ref.read(kitaServiceProvider).acknowledgeSickReport(r.id)),
                            ],
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
