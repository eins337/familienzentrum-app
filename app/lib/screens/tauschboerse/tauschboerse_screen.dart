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

/// The Tauschbörse — a cross-group exchange board any parent can browse
/// and post to, independent of which Gruppe their child is in. Reachable
/// from the Gruppen screen's "ÜBERGREIFEND" card.
class TauschboerseScreen extends ConsumerWidget {
  const TauschboerseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(marketplaceItemsProvider);
    final myId = ref.watch(profileProvider).valueOrNull?.id;

    return Scaffold(
      appBar: NHeader(title: 'Tauschbörse', subtitle: 'Für alle Eltern der Kita', showBack: true),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (items) {
          final available = items.where((i) => i.status == 'available').toList();
          final gone = items.where((i) => i.status != 'available').toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              const Text(
                'Biete oder suche Kleidung, Spielzeug und andere Kita-Sachen. Alle Eltern sehen deinen Vornamen und können dir schreiben.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 10),
              NButton(
                label: 'Neuer Artikel',
                variant: NButtonVariant.primary,
                block: true,
                alignStart: true,
                icon: const Icon(Icons.add_rounded),
                onPressed: () => context.push('/tauschboerse-neu'),
              ),
              const SizedBox(height: 10),
              if (available.isEmpty && gone.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('Noch keine Artikel — sei die erste Familie!', style: TextStyle(color: AppColors.muted))),
                ),
              for (final item in available) ...[_ItemCard(item: item, mine: item.authorId == myId), const SizedBox(height: 8)],
              if (gone.isNotEmpty) ...[
                const SizedBox(height: 6),
                const Text('VERGEBEN', style: TextStyle(fontFamily: 'Outfit', fontSize: 10, letterSpacing: 1.3, color: AppColors.muted, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                for (final item in gone) ...[_ItemCard(item: item, mine: item.authorId == myId), const SizedBox(height: 8)],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ItemCard extends ConsumerStatefulWidget {
  const _ItemCard({required this.item, required this.mine});
  final MarketplaceItem item;
  final bool mine;

  @override
  ConsumerState<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends ConsumerState<_ItemCard> {
  bool _busy = false;

  Future<void> _writeMessage() async {
    final myId = ref.read(profileProvider).valueOrNull?.id;
    if (myId == null) return;
    setState(() => _busy = true);
    try {
      final chat = await ref.read(chatsServiceProvider).findOrCreateDirectChat(myId, widget.item.authorId);
      await ref.read(chatsServiceProvider).sendMessage(chat.id, myId, 'Hallo! Ist "${widget.item.title}" noch verfügbar?');
      if (mounted) context.push('/chats/${chat.id}');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _markGiven() async {
    setState(() => _busy = true);
    try {
      await ref.read(marketplaceServiceProvider).updateStatus(widget.item.id, 'given_away');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    setState(() => _busy = true);
    try {
      await ref.read(marketplaceServiceProvider).deleteItem(widget.item.id);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e')));
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(allProfilesProvider).valueOrNull ?? {};
    final authorName = profiles[widget.item.authorId]?.displayName.split(' ').first ?? '…';
    final item = widget.item;

    return Opacity(
      opacity: item.status == 'available' ? 1 : 0.6,
      child: NCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(item.title, style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 14.5, color: AppColors.ink)),
                ),
                if (item.status == 'given_away') const NTag('Vergeben', variant: NTagVariant.neutral) else if (item.status == 'reserved') const NTag('Reserviert', variant: NTagVariant.accent),
              ],
            ),
            if (item.description != null && item.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(item.description!, style: const TextStyle(fontSize: 12.5, color: AppColors.ink2, height: 1.4)),
            ],
            const SizedBox(height: 6),
            Text('von $authorName', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            if (item.status == 'available') ...[
              const SizedBox(height: 9),
              if (widget.mine)
                Row(
                  children: [
                    Expanded(child: NButton(label: 'Als vergeben markieren', variant: NButtonVariant.secondary, small: true, loading: _busy, onPressed: _markGiven)),
                    const SizedBox(width: 6),
                    NButton(icon: const Icon(Icons.delete_outline_rounded), variant: NButtonVariant.secondary, iconOnly: true, onPressed: _busy ? null : _delete),
                  ],
                )
              else
                NButton(label: 'Nachricht schreiben', variant: NButtonVariant.secondary, small: true, block: true, loading: _busy, onPressed: _writeMessage),
            ],
          ],
        ),
      ),
    );
  }
}
