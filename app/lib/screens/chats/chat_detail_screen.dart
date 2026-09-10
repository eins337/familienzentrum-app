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
    await ref.read(chatsServiceProvider).sendMessage(widget.chatId, myId, text);
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
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
              error: (e, _) => Center(child: Text('Fehler: $e')),
              data: (messages) {
                final playdate = playdateAsync.valueOrNull;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  children: [
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Text('Heute', style: TextStyle(fontSize: 10.5, color: AppColors.neutral500)),
                      ),
                    ),
                    for (final m in messages) _MessageBubble(message: m, mine: m.senderId == myId),
                    if (playdate != null && playdate.status == 'pending') ...[
                      const SizedBox(height: 8),
                      Align(alignment: Alignment.centerLeft, child: _PlaydateInlineCard(playdate: playdate)),
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
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.text),
                      decoration: InputDecoration(
                        hintText: 'Nachricht schreiben',
                        hintStyle: const TextStyle(color: AppColors.neutral600),
                        filled: true,
                        fillColor: AppColors.surface,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.divider)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.divider)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.accent)),
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
  const _MessageBubble({required this.message, required this.mine});
  final Message message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: mine ? const Color(0xFF2B2741) : AppColors.surface,
          border: Border.all(color: mine ? AppColors.accent.withValues(alpha: 0.45) : AppColors.divider),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(message.body, style: const TextStyle(fontSize: 13, height: 1.45, color: AppColors.text)),
            const SizedBox(height: 3),
            Text(_timeLabel(message.createdAt), style: const TextStyle(fontSize: 9.5, color: AppColors.neutral500)),
          ],
        ),
      ),
    );
  }

  String _timeLabel(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _PlaydateInlineCard extends ConsumerWidget {
  const _PlaydateInlineCard({required this.playdate});
  final PlaydateRequest playdate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = ref.watch(allChildrenProvider).valueOrNull ?? {};
    final fromChild = children[playdate.fromChildId]?.name ?? '…';
    final toChild = children[playdate.toChildId]?.name ?? '…';
    final slot = playdate.proposedSlots.firstOrNull;

    return NCard(
      borderColor: AppColors.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SPIELANFRAGE', style: TextStyle(fontSize: 10, letterSpacing: 1.1, color: AppColors.accent, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text('$fromChild & $toChild${slot != null ? ' · ${slot.date} ${slot.timeRange}' : ''}',
              style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 14.5, color: AppColors.text)),
          if (slot?.location != null) Text(slot!.location!, style: const TextStyle(fontSize: 12, color: AppColors.neutral400)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: NButton(
                  label: 'Zusagen',
                  variant: NButtonVariant.primary,
                  small: true,
                  onPressed: () => ref.read(playdatesServiceProvider).confirmSlot(playdate.id, 0),
                ),
              ),
              const SizedBox(width: 6),
              NButton(label: 'Anderer Termin', variant: NButtonVariant.secondary, small: true, onPressed: () {}),
            ],
          ),
        ],
      ),
    );
  }
}
