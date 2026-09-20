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

class ChatsScreen extends ConsumerStatefulWidget {
  const ChatsScreen({super.key});

  @override
  ConsumerState<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends ConsumerState<ChatsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatsAsync = ref.watch(myChatsProvider);
    final myId = ref.watch(profileProvider).valueOrNull?.id;
    final profiles = ref.watch(allProfilesProvider).valueOrNull ?? {};

    return Scaffold(
      appBar: NHeader(title: 'Nachrichten', subtitle: 'Eltern & Team', hasUnread: true, onBell: () => context.push('/mitteilungen')),
      body: chatsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (allChats) {
          final query = _query.trim().toLowerCase();
          final chats = query.isEmpty
              ? allChats
              : allChats.where((c) => _chatTitle(c, myId, profiles).toLowerCase().contains(query)).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              NInput(controller: _searchCtrl, hintText: 'Familien oder Chats suchen', onChanged: (v) => setState(() => _query = v)),
              const SizedBox(height: 8),
              for (final c in chats) ...[
                _ChatRow(chat: c, myId: myId, profiles: profiles),
                const SizedBox(height: 8),
              ],
              if (chats.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(child: Text(query.isEmpty ? 'Noch keine Chats.' : 'Keine Treffer für „$_query“.', style: const TextStyle(color: AppColors.muted))),
                ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 13, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Du siehst nur Familien, die ihre Kontaktdaten für den Elternchat freigegeben haben.',
                        style: TextStyle(fontSize: 11, color: AppColors.muted, height: 1.45),
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

String _chatTitle(Chat chat, String? myId, Map<String, Profile> profiles) {
  if (chat.isGroup) return chat.name ?? 'Gruppe';
  final otherId = chat.participantIds.firstWhere((id) => id != myId, orElse: () => chat.participantIds.firstOrNull ?? '');
  return profiles[otherId]?.displayName ?? '…';
}

class _ChatRow extends ConsumerWidget {
  const _ChatRow({required this.chat, required this.myId, required this.profiles});
  final Chat chat;
  final String? myId;
  final Map<String, Profile> profiles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastMessage = ref.watch(lastMessageProvider(chat.id)).valueOrNull;

    final title = _chatTitle(chat, myId, profiles);
    String? subtitle;
    Widget avatar;

    if (chat.isGroup) {
      subtitle = null;
      avatar = NAvatar(
        initials: groupInitial(chat.groupId),
        background: chat.groupId != null ? groupColor(chat.groupId) : AppColors.primary.withValues(alpha: 0.15),
        foreground: chat.groupId != null ? AppColors.background : AppColors.primary,
        borderColor: chat.groupId == null ? AppColors.primary : null,
      );
    } else {
      subtitle = null;
      final initials = title.trim().isEmpty ? '?' : title.trim().split(' ').map((p) => p[0]).take(2).join().toUpperCase();
      final otherId = chat.participantIds.firstWhere((id) => id != myId, orElse: () => chat.participantIds.firstOrNull ?? '');
      avatar = NAvatar(initials: initials, imageUrl: profiles[otherId]?.avatarUrl);
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
                      child: Text(title, style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.ink), overflow: TextOverflow.ellipsis),
                    ),
                    Text(formatRelative(chat.lastMessageAt), style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                  ],
                ),
                if (subtitle != null) Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.groupBlau)),
                if (lastMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(lastMessage.body, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
