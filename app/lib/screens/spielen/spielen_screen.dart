import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../../widgets/n_button.dart';
import '../../widgets/n_card.dart';
import '../../widgets/n_header.dart';
import '../../widgets/n_tag.dart';

class SpielenScreen extends ConsumerWidget {
  const SpielenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myFamilyId = ref.watch(profileProvider).valueOrNull?.familyId;
    final playdatesAsync = ref.watch(myPlaydatesProvider);

    return Scaffold(
      appBar: NHeader(title: 'Spielen', subtitle: 'Verabredungen der Kinder', hasUnread: true, onBell: () => context.push('/mitteilungen')),
      body: playdatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (all) {
          final waiting = all.where((p) => p.status == 'pending' && p.toFamilyId == myFamilyId).toList();
          final confirmed = all.where((p) => p.status == 'confirmed').toList();
          final sent = all.where((p) => p.status == 'pending' && p.fromFamilyId == myFamilyId).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              NButton(
                label: 'Neue Spielanfrage',
                variant: NButtonVariant.primary,
                block: true,
                alignStart: true,
                icon: const Icon(Icons.add_rounded),
                onPressed: () => context.push('/spielanfrage-neu'),
              ),
              if (waiting.isNotEmpty) ...[
                const SizedBox(height: 10),
                const _SectionLabel('Warten auf dich'),
                for (final p in waiting) ...[_WaitingCard(playdate: p), const SizedBox(height: 8)],
              ],
              if (confirmed.isNotEmpty) ...[
                const SizedBox(height: 4),
                const _SectionLabel('Bestätigt'),
                for (final p in confirmed) ...[_ConfirmedRow(playdate: p), const SizedBox(height: 8)],
              ],
              if (sent.isNotEmpty) ...[
                const SizedBox(height: 4),
                _SectionLabel('Gesendet', accent: false),
                for (final p in sent) ...[_SentCard(playdate: p), const SizedBox(height: 8)],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.accent = true});
  final String text;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text.toUpperCase(),
          style: TextStyle(fontSize: 10, letterSpacing: 1.1, color: accent ? AppColors.accent : AppColors.neutral500, fontWeight: FontWeight.w500)),
    );
  }
}

class _WaitingCard extends ConsumerStatefulWidget {
  const _WaitingCard({required this.playdate});
  final PlaydateRequest playdate;

  @override
  ConsumerState<_WaitingCard> createState() => _WaitingCardState();
}

class _WaitingCardState extends ConsumerState<_WaitingCard> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final children = ref.watch(allChildrenProvider).valueOrNull ?? {};
    final families = ref.watch(allFamiliesProvider).valueOrNull ?? {};
    final p = widget.playdate;
    final fromFamily = families[p.fromFamilyId]?.name ?? '…';
    final fromChild = children[p.fromChildId]?.name ?? '…';
    final toChild = children[p.toChildId]?.name ?? '…';

    return NCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 30, height: 30, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.neutral800)),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$fromFamily fragt an', style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 13.5, color: AppColors.text)),
                    Text('$fromChild möchte mit $toChild spielen', style: const TextStyle(fontSize: 11, color: AppColors.neutral500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          const Text('Vorgeschlagene Termine — wähle, was passt:', style: TextStyle(fontSize: 11.5, color: AppColors.neutral400)),
          const SizedBox(height: 6),
          for (var i = 0; i < p.proposedSlots.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                onTap: () => setState(() => _selected = i),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: _selected == i ? AppColors.accent : AppColors.divider),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      Text('${p.proposedSlots[i].date} · ${p.proposedSlots[i].timeRange}',
                          style: TextStyle(fontSize: 12.5, color: _selected == i ? AppColors.accent : AppColors.text)),
                      const Spacer(),
                      if (p.proposedSlots[i].location != null)
                        Text(p.proposedSlots[i].location!, style: const TextStyle(fontSize: 11, color: AppColors.neutral400)),
                    ],
                  ),
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: NButton(
                  label: 'Termin bestätigen',
                  variant: NButtonVariant.primary,
                  small: true,
                  onPressed: _selected == null ? null : () => ref.read(playdatesServiceProvider).confirmSlot(p.id, _selected!),
                ),
              ),
              const SizedBox(width: 6),
              NButton(label: 'Absagen', variant: NButtonVariant.secondary, small: true, onPressed: () => ref.read(playdatesServiceProvider).declineRequest(p.id)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _selected == null ? 'Wähle einen Termin, oder schlage einen eigenen vor.' : 'Tippe auf bestätigen — die Familie wird dann benachrichtigt.',
            style: const TextStyle(fontSize: 10.5, color: AppColors.neutral500),
          ),
        ],
      ),
    );
  }
}

class _ConfirmedRow extends ConsumerWidget {
  const _ConfirmedRow({required this.playdate});
  final PlaydateRequest playdate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = ref.watch(allChildrenProvider).valueOrNull ?? {};
    final fromChild = children[playdate.fromChildId]?.name ?? '…';
    final toChild = children[playdate.toChildId]?.name ?? '…';
    final slot = playdate.confirmedSlotIndex != null && playdate.confirmedSlotIndex! < playdate.proposedSlots.length
        ? playdate.proposedSlots[playdate.confirmedSlotIndex!]
        : null;

    return NCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$fromChild & $toChild', style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 14.5, color: AppColors.text)),
                if (slot != null)
                  Text('${slot.date} · ${slot.timeRange}${slot.location != null ? ' · ${slot.location}' : ''}',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.neutral400)),
              ],
            ),
          ),
          if (playdate.chatId != null)
            NButton(label: 'Chat', variant: NButtonVariant.ghost, small: true, onPressed: () => context.push('/chats/${playdate.chatId}')),
        ],
      ),
    );
  }
}

class _SentCard extends ConsumerWidget {
  const _SentCard({required this.playdate});
  final PlaydateRequest playdate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final families = ref.watch(allFamiliesProvider).valueOrNull ?? {};
    final children = ref.watch(allChildrenProvider).valueOrNull ?? {};
    final toFamily = families[playdate.toFamilyId]?.name ?? '…';
    final fromChild = children[playdate.fromChildId]?.name ?? '…';

    return NCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const NTag('Wartet auf Antwort', variant: NTagVariant.neutral),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 6),
          Text('Anfrage an $toFamily', style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 14.5, color: AppColors.text)),
          Text('${playdate.proposedSlots.length} Terminvorschläge · $fromChild', style: const TextStyle(fontSize: 11.5, color: AppColors.neutral400)),
        ],
      ),
    );
  }
}
