import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../../utils/group_colors.dart';
import '../../utils/time_format.dart';
import '../../widgets/n_avatar.dart';
import '../../widgets/n_card.dart';
import '../../widgets/n_field.dart';
import '../../widgets/n_header.dart';

class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(myChatsProvider);
    final myId = ref.watch(profileProvider).valueOrNull?.id;
    final profiles = ref.watch(allProfilesProvider).valueOrNull ?? {};

    return Scaffold(
      appBar: NHeader(title: 'Nachrichten', subtitle: 'Eltern & Team', hasUnread: true, onBell: () => context.push('/mitteilungen')),
      body: chatsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (chats) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              const NInput(hintText: 'Familien oder Chats suchen'),
              const SizedBox(height: 8),
              for (final c in chats) ...[
                _ChatRow(chat: c, myId: myId, profiles: profiles),
                const SizedBox(height: 8),
              ],
              if (chats.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: Text('Noch keine Chats.', style: TextStyle(color: AppColors.neutral500))),
                ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: BoxDecoration(color: AppColors.neutral900, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 13, color: AppColors.accent),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Du siehst nur Familien, die ihre Kontaktdaten für den Elternchat freigegeben haben.',
                        style: TextStyle(fontSize: 11, color: AppColors.neutral400, height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChatRow extends ConsumerWidget {
  const _ChatRow({required this.chat, required this.myId, required this.profiles});
  final Chat chat;
  final String? myId;
  final Map<String, Profile> profiles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastMessage = ref.watch(lastMessageProvider(chat.id)).valueOrNull;

    String title;
    String? subtitle;
    Widget avatar;

    if (chat.isGroup) {
      title = chat.name ?? 'Gruppe';
      subtitle = null;
      avatar = NAvatar(
        initials: groupInitial(chat.groupId),
        background: chat.groupId != null ? groupColor(chat.groupId) : AppColors.accent.withValues(alpha: 0.15),
        foreground: chat.groupId != null ? AppColors.bg : AppColors.accent,
        borderColor: chat.groupId == null ? AppColors.accent : null,
      );
    } else {
      final otherId = chat.participantIds.firstWhere((id) => id != myId, orElse: () => chat.participantIds.firstOrNull ?? '');
      final other = profiles[otherId];
      title = other?.displayName ?? '…';
      subtitle = null;
      final initials = title.trim().isEmpty ? '?' : title.trim().split(' ').map((p) => p[0]).take(2).join().toUpperCase();
      avatar = NAvatar(initials: initials);
    }

    return NCard(
      onTap: () => context.push('/chats/${chat.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          avatar,
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.text), overflow: TextOverflow.ellipsis),
                    ),
                    Text(formatRelative(chat.lastMessageAt), style: const TextStyle(fontSize: 10, color: AppColors.neutral500)),
                  ],
                ),
                if (subtitle != null) Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.groupBlau)),
                if (lastMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(lastMessage.body, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: AppColors.neutral400)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
