import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'supabase_service.dart';

class ChatsService {
  /// [relevantGroupIds] surfaces the open "Eltern/Team Gruppe X" channels
  /// for the caller's own groups (parent: their children's groups; team:
  /// their assigned groups) alongside their direct 1:1 chats.
  Stream<List<Chat>> streamMyChats(String uid, {Set<String> relevantGroupIds = const {}}) {
    return supa
        .from('chats')
        .stream(primaryKey: ['id'])
        .order('last_message_at', ascending: false)
        .map((rows) => rows
            .map(Chat.fromMap)
            .where((c) => c.participantIds.contains(uid) || (c.channel != null && relevantGroupIds.contains(c.groupId)))
            .toList());
  }

  Stream<List<Message>> streamMessages(String chatId) {
    return supa
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at')
        .map((rows) => rows.map(Message.fromMap).toList());
  }

  Future<Message?> fetchLastMessage(String chatId) async {
    final rows = await supa.from('messages').select().eq('chat_id', chatId).order('created_at', ascending: false).limit(1);
    return rows.isEmpty ? null : Message.fromMap(rows.first);
  }

  Future<void> sendMessage(String chatId, String senderId, String body) =>
      supa.from('messages').insert({'chat_id': chatId, 'sender_id': senderId, 'body': body});

  /// Finds an existing 1:1 chat between the two users, or creates one.
  Future<Chat> findOrCreateDirectChat(String uidA, String uidB) async {
    final existing = await supa.from('chats').select().eq('is_group', false).contains('participant_ids', [uidA, uidB]);
    for (final row in existing) {
      final ids = (row['participant_ids'] as List).map((e) => e.toString()).toSet();
      if (ids.length == 2 && ids.containsAll([uidA, uidB])) {
        return Chat.fromMap(row);
      }
    }
    final row = await supa
        .from('chats')
        .insert({'is_group': false, 'participant_ids': [uidA, uidB]})
        .select()
        .single();
    return Chat.fromMap(row);
  }

  /// The persistent "Eltern Gruppe X" / "Team Gruppe X" channel — an open
  /// group chat scoped by `group_id` + `channel`, not by participant_ids
  /// (see migration 0014 for why: these read/write as any signed-in user,
  /// matching how `posts` group-visibility already works in this app).
  Future<Chat> findOrCreateGroupChat({required String groupId, required String channel, required String name}) async {
    final existing = await supa.from('chats').select().eq('is_group', true).eq('group_id', groupId).eq('channel', channel).maybeSingle();
    if (existing != null) return Chat.fromMap(existing);
    try {
      final row = await supa
          .from('chats')
          .insert({'is_group': true, 'group_id': groupId, 'channel': channel, 'name': name, 'participant_ids': <String>[]})
          .select()
          .single();
      return Chat.fromMap(row);
    } on PostgrestException catch (e) {
      // Someone else created the same channel a moment ago (unique index) — fetch theirs.
      if (e.code == '23505') {
        final row = await supa.from('chats').select().eq('is_group', true).eq('group_id', groupId).eq('channel', channel).single();
        return Chat.fromMap(row);
      }
      rethrow;
    }
  }
}
