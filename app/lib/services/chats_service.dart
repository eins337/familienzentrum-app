import '../models/models.dart';
import 'supabase_service.dart';

class ChatsService {
  Stream<List<Chat>> streamMyChats(String uid) {
    return supa
        .from('chats')
        .stream(primaryKey: ['id'])
        .order('last_message_at', ascending: false)
        .map((rows) => rows.map(Chat.fromMap).where((c) => c.participantIds.contains(uid)).toList());
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
}
