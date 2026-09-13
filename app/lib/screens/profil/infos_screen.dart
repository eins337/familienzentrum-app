import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../../utils/time_format.dart';
import '../../widgets/n_button.dart';
import '../../widgets/n_card.dart';
import '../../widgets/n_header.dart';
import '../../widgets/n_segmented.dart';

class InfosScreen extends ConsumerStatefulWidget {
  const InfosScreen({super.key});
  @override
  ConsumerState<InfosScreen> createState() => _InfosScreenState();
}

class _InfosScreenState extends ConsumerState<InfosScreen> {
  String _tab = 'termine';

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(upcomingEventsProvider);
    final closuresAsync = ref.watch(closuresProvider);
    final documentsAsync = ref.watch(documentsProvider);

    return Scaffold(
      appBar: const NHeader(title: 'Infos & Termine', subtitle: 'Familienzentrum Lank', showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          NSegmented<String>(
            expand: true,
            value: _tab,
            options: const [('termine', 'Termine'), ('dokumente', 'Dokumente')],
            onChanged: (v) => setState(() => _tab = v),
          ),
          const SizedBox(height: 12),
          if (_tab == 'termine') ...[
            eventsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Text('Fehler: $e'),
              data: (events) {
                if (events.isEmpty) return const Text('Keine anstehenden Termine.', style: TextStyle(color: AppColors.muted));
                final grouped = <String, List<KitaEvent>>{};
                for (final e in events) {
                  final key = '${_monthName(e.eventDate.month)} ${e.eventDate.year}';
                  grouped.putIfAbsent(key, () => []).add(e);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final entry in grouped.entries) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6, top: 4),
                        child: Text(entry.key.toUpperCase(),
                            style: const TextStyle(fontFamily: 'Outfit', fontSize: 10, letterSpacing: 1.3, color: AppColors.primary, fontWeight: FontWeight.w800)),
                      ),
                      for (final e in entry.value) ...[_EventRow(event: e), const SizedBox(height: 8)],
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 6),
            closuresAsync.when(
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
              data: (closures) => closures.isEmpty
                  ? const SizedBox()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 6, top: 4),
                          child: Text('FERIEN & SCHLIESSTAGE',
                              style: TextStyle(fontFamily: 'Outfit', fontSize: 10, letterSpacing: 1.3, color: AppColors.primary, fontWeight: FontWeight.w800)),
                        ),
                        NCard(
                          child: Column(
                            children: [
                              for (final c in closures)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 5),
                                  child: Row(
                                    children: [
                                      Text(c.title, style: const TextStyle(fontSize: 12.5, color: AppColors.ink)),
                                      const Spacer(),
                                      Text('${formatDateShort(c.startDate)}–${formatDateShort(c.endDate)}',
                                          style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 8),
            const NCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('KONTAKT', style: TextStyle(fontFamily: 'Outfit', fontSize: 10, letterSpacing: 1.3, color: AppColors.primary, fontWeight: FontWeight.w800)),
                  SizedBox(height: 8),
                  Text('Ev. Familienzentrum Lank\nLeitung: Frau Petersen', style: TextStyle(fontSize: 13, height: 1.6, color: AppColors.ink)),
                  Text('02150 · 12 34 56', style: TextStyle(fontSize: 13, height: 1.6, color: AppColors.primary)),
                ],
              ),
            ),
          ] else
            documentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Text('Fehler: $e'),
              data: (docs) {
                if (docs.isEmpty) return const Text('Keine Dokumente.', style: TextStyle(color: AppColors.muted));
                final speiseplaene = docs.where((d) => d.title.toLowerCase().startsWith('speiseplan')).toList();
                final rest = docs.where((d) => !d.title.toLowerCase().startsWith('speiseplan')).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (speiseplaene.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Text('SPEISEPLÄNE', style: TextStyle(fontFamily: 'Outfit', fontSize: 10, letterSpacing: 1.3, color: AppColors.primary, fontWeight: FontWeight.w800)),
                      ),
                      for (final d in speiseplaene) ...[_DocRow(doc: d), const SizedBox(height: 8)],
                      if (rest.isNotEmpty) const SizedBox(height: 4),
                    ],
                    if (rest.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Text('ELTERNBRIEFE & FORMULARE', style: TextStyle(fontFamily: 'Outfit', fontSize: 10, letterSpacing: 1.3, color: AppColors.primary, fontWeight: FontWeight.w800)),
                      ),
                      for (final d in rest) ...[_DocRow(doc: d), const SizedBox(height: 8)],
                    ],
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  String _monthName(int m) => const [
        'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'
      ][m - 1];
}

class _EventRow extends ConsumerWidget {
  const _EventRow({required this.event});
  final KitaEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = ref.watch(profileProvider).valueOrNull?.id;
    final rsvped = myId != null && event.rsvpUids.contains(myId);
    return NCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 38,
            child: Column(
              children: [
                Text(weekdayShort(event.eventDate.weekday), style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                Text('${event.eventDate.day}', style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 20, color: AppColors.ink)),
              ],
            ),
          ),
          Container(width: 1, height: 30, color: AppColors.divider, margin: const EdgeInsets.symmetric(horizontal: 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(event.title, style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.ink)),
                Text([event.timeLabel, event.location].whereType<String>().join(' · '), style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
              ],
            ),
          ),
          NButton(
            label: rsvped ? 'Dabei ✓' : 'Zusagen',
            variant: rsvped ? NButtonVariant.success : NButtonVariant.primary,
            small: true,
            onPressed: () => ref.read(kitaServiceProvider).toggleRsvp(event.id),
          ),
        ],
      ),
    );
  }
}

class _DocRow extends StatelessWidget {
  const _DocRow({required this.doc});
  final DocumentItem doc;

  @override
  Widget build(BuildContext context) {
    return NCard(
      onTap: () => launchUrl(Uri.parse(doc.fileUrl), mode: LaunchMode.externalApplication),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(doc.title, style: const TextStyle(fontSize: 13, color: AppColors.ink)),
                if (doc.sizeLabel != null) Text(doc.sizeLabel!, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
              ],
            ),
          ),
          const Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.muted),
        ],
      ),
    );
  }
}
