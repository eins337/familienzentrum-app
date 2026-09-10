import '../models/models.dart';
import 'chats_service.dart';
import 'supabase_service.dart';

class PlaydatesService {
  final _chats = ChatsService();

  /// Postgres can OR across different-field equality filters in one query
  /// (unlike Firestore, which needed two merged listeners for this).
  Stream<List<PlaydateRequest>> streamMyPlaydates(String familyId) {
    return supa
        .from('playdate_requests')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows
            .map(PlaydateRequest.fromMap)
            .where((p) => p.fromFamilyId == familyId || p.toFamilyId == familyId)
            .toList());
  }

  Future<PlaydateRequest> createRequest({
    required String fromUid,
    required String fromFamilyId,
    required String fromChildId,
    required String toFamilyId,
    required String toChildId,
    required String toUid,
    required List<PlaydateSlot> proposedSlots,
    String? message,
  }) async {
    final chat = await _chats.findOrCreateDirectChat(fromUid, toUid);
    if (message != null && message.trim().isNotEmpty) {
      await _chats.sendMessage(chat.id, fromUid, message.trim());
    }
    final row = await supa
        .from('playdate_requests')
        .insert({
          'from_uid': fromUid,
          'from_family_id': fromFamilyId,
          'from_child_id': fromChildId,
          'to_family_id': toFamilyId,
          'to_child_id': toChildId,
          'proposed_slots': proposedSlots.map((s) => s.toMap()).toList(),
          'message': message,
          'chat_id': chat.id,
        })
        .select()
        .single();
    return PlaydateRequest.fromMap(row);
  }

  Future<PlaydateRequest?> fetchByChatId(String chatId) async {
    final row = await supa.from('playdate_requests').select().eq('chat_id', chatId).maybeSingle();
    return row == null ? null : PlaydateRequest.fromMap(row);
  }

  Future<void> confirmSlot(String requestId, int slotIndex) => supa
      .from('playdate_requests')
      .update({'status': 'confirmed', 'confirmed_slot_index': slotIndex}).eq('id', requestId);

  Future<void> declineRequest(String requestId) =>
      supa.from('playdate_requests').update({'status': 'declined'}).eq('id', requestId);
}
