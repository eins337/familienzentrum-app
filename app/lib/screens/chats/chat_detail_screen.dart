import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../../widgets/n_button.dart';
import '../../widgets/n_card.dart';
import '../../widgets/n_header.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  const ChatDetailScreen({super.key, required this.chatId});
  final String chatId;

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _draftCtrl = TextEditingController();

  @override
  void dispose() {
    _draftCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _draftCtrl.text.trim();
    final myId = ref.read(profileProvider).valueOrNull?.id;
    if (text.isEmpty || myId == null) return;
    _draftCtrl.clear();
    try {
      await ref.read(chatsServiceProvider).sendMessage(widget.chatId, myId, text);
    } catch (e) {
      if (mounted) {
        _draftCtrl.text = text;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Nachricht konnte nicht gesendet werden: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chats = ref.watch(myChatsProvider).valueOrNull ?? [];
    final chat = chats.where((c) => c.id == widget.chatId).firstOrNull;
    final profiles = ref.watch(allProfilesProvider).valueOrNull ?? {};
    final myId = ref.watch(profileProvider).valueOrNull?.id;
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));
    final playdateAsync = ref.watch(playdateForChatProvider(widget.chatId));

    String title = chat?.name ?? '…';
    if (chat != null && !chat.isGroup) {
      final otherId = chat.participantIds.firstWhere((id) => id != myId, orElse: () => '');
      title = profiles[otherId]?.displayName ?? '…';
    }

    return Scaffold(
      appBar: NHeader(title: title, showBack: true),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(child: Text('Fehler: $e')),
              data: (messages) {
                final playdate = playdateAsync.valueOrNull;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  children: [
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Text('Heute', style: TextStyle(fontSize: 10.5, color: AppColors.muted)),
                      ),
                    ),
                    for (final m in messages)
                      _MessageBubble(
                        message: m,
                        mine: m.senderId == myId,
                        senderName: m.senderId != myId ? profiles[m.senderId]?.displayName : null,
                      ),
                    if (playdate != null) ...[
                      const SizedBox(height: 8),
                      Align(alignment: Alignment.centerLeft, child: _PlaydateInlineCard(playdate: playdate, chatId: widget.chatId)),
                    ],
                  ],
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _draftCtrl,
                      style: const TextStyle(fontFamily: 'Nunito Sans', fontSize: 14, color: AppColors.ink),
                      decoration: InputDecoration(
                        hintText: 'Nachricht schreiben',
                        hintStyle: const TextStyle(color: AppColors.mutedAlt),
                        filled: true,
                        fillColor: AppColors.surface,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.divider)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.divider)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.primary)),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 7),
                  NButton(icon: const Icon(Icons.send_rounded), variant: NButtonVariant.primary, iconOnly: true, onPressed: _send),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.mine, this.senderName});
  final Message message;
  final bool mine;
  final String? senderName;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(AppRadius.chatBubble),
      topRight: const Radius.circular(AppRadius.chatBubble),
      bottomLeft: Radius.circular(mine ? AppRadius.chatBubble : AppRadius.chatBubbleTail),
      bottomRight: Radius.circular(mine ? AppRadius.chatBubbleTail : AppRadius.chatBubble),
    );

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: mine ? AppColors.primary : AppColors.surface,
          border: mine ? null : Border.all(color: AppColors.cardBorder),
          borderRadius: radius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (senderName != null) ...[
              Text(senderName!, style: AppText.outfit(size: 10.5, weight: FontWeight.w800, color: AppColors.primary)),
              const SizedBox(height: 2),
            ],
            Text(message.body, style: TextStyle(fontSize: 13, height: 1.45, color: mine ? AppColors.surface : AppColors.ink)),
            const SizedBox(height: 3),
            Align(
              alignment: Alignment.centerRight,
              child: Text(_timeLabel(message.createdAt), style: TextStyle(fontSize: 9.5, color: mine ? AppColors.surface.withValues(alpha: 0.75) : AppColors.muted)),
            ),
          ],
        ),
      ),
    );
  }

  String _timeLabel(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _PlaydateInlineCard extends ConsumerStatefulWidget {
  const _PlaydateInlineCard({required this.playdate, required this.chatId});
  final PlaydateRequest playdate;
  final String chatId;

  @override
  ConsumerState<_PlaydateInlineCard> createState() => _PlaydateInlineCardState();
}

class _PlaydateInlineCardState extends ConsumerState<_PlaydateInlineCard> {
  int? _selected;
  bool _busy = false;

  // playdateForChatProvider is a one-shot FutureProvider, not a stream — it
  // never notices a confirm/decline on its own, so without this the card
  // kept showing "pending" with live buttons even after a successful action.
  Future<void> _confirm() async {
    if (_selected == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(playdatesServiceProvider).confirmSlot(widget.playdate.id, _selected!);
      ref.invalidate(playdateForChatProvider(widget.chatId));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decline() async {
    setState(() => _busy = true);
    try {
      await ref.read(playdatesServiceProvider).declineRequest(widget.playdate.id);
      ref.invalidate(playdateForChatProvider(widget.chatId));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final children = ref.watch(allChildrenProvider).valueOrNull ?? {};
    final p = widget.playdate;
    final fromChild = children[p.fromChildId]?.name ?? '…';
    final toChild = children[p.toChildId]?.name ?? '…';

    final statusLabel = switch (p.status) {
      'confirmed' => 'TERMIN BESTÄTIGT',
      'declined' => 'SPIELANFRAGE ABGESAGT',
      _ => 'SPIELANFRAGE',
    };
    final statusColor = switch (p.status) {
      'confirmed' => AppColors.success,
      'declined' => AppColors.muted,
      _ => AppColors.primary,
    };

    return NCard(
      borderColor: statusColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(statusLabel, style: TextStyle(fontFamily: 'Outfit', fontSize: 10, letterSpacing: 1.3, color: statusColor, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('$fromChild & $toChild', style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 14.5, color: AppColors.ink)),
          const SizedBox(height: 8),
          if (p.status == 'confirmed' && p.confirmedSlotIndex != null && p.confirmedSlotIndex! < p.proposedSlots.length) ...[
            _SlotRow(slot: p.proposedSlots[p.confirmedSlotIndex!], highlighted: true),
            const SizedBox(height: 8),
            NButton(label: 'Termin absagen', variant: NButtonVariant.secondary, small: true, loading: _busy, onPressed: _busy ? null : _decline),
          ] else if (p.status == 'declined') ...[
            const Text('Diese Spielanfrage wurde abgesagt.', style: TextStyle(fontSize: 12.5, color: AppColors.muted)),
          ] else ...[
            for (var i = 0; i < p.proposedSlots.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  onTap: () => setState(() => _selected = i),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: _SlotRow(slot: p.proposedSlots[i], highlighted: _selected == i),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: NButton(
                    label: 'Termin bestätigen',
                    variant: NButtonVariant.primary,
                    small: true,
                    loading: _busy,
                    onPressed: (_selected == null || _busy) ? null : _confirm,
                  ),
                ),
                const SizedBox(width: 6),
                NButton(label: 'Absagen', variant: NButtonVariant.secondary, small: true, onPressed: _busy ? null : _decline),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({required this.slot, required this.highlighted});
  final PlaydateSlot slot;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: highlighted ? AppColors.primary : AppColors.divider),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Text('${slot.date} · ${slot.timeRange}', style: TextStyle(fontSize: 12.5, color: highlighted ? AppColors.primary : AppColors.ink)),
          const Spacer(),
          if (slot.location != null) Text(slot.location!, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        ],
      ),
    );
  }
}
