import 'dart:math';
import '../models/models.dart';
import 'supabase_service.dart';

/// Everything the admin panel can do. RLS restricts all of this to
/// is_admin() (or is_team() for a few group/content tables) server-side —
/// these methods are thin wrappers, not the security boundary.
class AdminService {
  String _randomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    return List.generate(8, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  // ── Invites ────────────────────────────────────────────────────────
  Future<Invite> createInvite({
    required String email,
    required String role,
    required String displayName,
    String? familyId,
    bool isAdmin = false,
    List<String>? groupIds,
    String? staffTitle,
    required String createdBy,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final code = _randomCode();
    final row = await supa
        .from('invites')
        .insert({
          'email': normalizedEmail,
          'code': code,
          'role': role,
          'display_name': displayName,
          'family_id': familyId,
          'is_admin': isAdmin,
          'group_ids': groupIds,
          'staff_title': staffTitle,
          'created_by': createdBy,
        })
        .select()
        .single();
    return Invite.fromMap(row);
  }

  Stream<List<Invite>> streamInvites() {
    return supa
        .from('invites')
        .stream(primaryKey: ['email'])
        .order('created_at', ascending: false)
        .map((rows) => rows.map(Invite.fromMap).toList());
  }

  Future<void> deleteInvite(String email) => supa.from('invites').delete().eq('email', email);

  // ── Families ───────────────────────────────────────────────────────
  Future<Family> createFamily(String name) async {
    final row = await supa.from('families').insert({'name': name}).select().single();
    return Family.fromMap(row);
  }

  Future<void> updateFamilyName(String id, String name) => supa.from('families').update({'name': name}).eq('id', id);

  Future<void> deleteFamily(String id) => supa.from('families').delete().eq('id', id);

  Stream<List<Family>> streamFamilies() {
    return supa.from('families').stream(primaryKey: ['id']).order('name').map((rows) => rows.map(Family.fromMap).toList());
  }

  // ── Children ───────────────────────────────────────────────────────
  Future<Child> createChild({required String familyId, required String name, String? groupId, int? birthYear, DateTime? birthDate}) async {
    final row = await supa
        .from('children')
        .insert({
          'family_id': familyId,
          'name': name,
          'group_id': groupId,
          'birth_year': birthYear,
          'birth_date': birthDate?.toIso8601String().split('T').first,
        })
        .select()
        .single();
    return Child.fromMap(row);
  }

  Future<void> updateChildAdmin(String id, {String? name, String? groupId, int? birthYear, DateTime? birthDate, List<String>? tags}) => supa
      .from('children')
      .update({
        if (name != null) 'name': name,
        if (groupId != null) 'group_id': groupId,
        if (birthYear != null) 'birth_year': birthYear,
        if (birthDate != null) 'birth_date': birthDate.toIso8601String().split('T').first,
        if (tags != null) 'tags': tags,
      })
      .eq('id', id);

  Future<void> deleteChild(String id) => supa.from('children').delete().eq('id', id);

  Stream<List<Child>> streamAllChildren() {
    return supa.from('children').stream(primaryKey: ['id']).order('name').map((rows) => rows.map(Child.fromMap).toList());
  }

  // ── Users / team & roles ──────────────────────────────────────────
  Stream<List<Profile>> streamAllUsers() {
    return supa.from('profiles').stream(primaryKey: ['id']).order('display_name').map((rows) => rows.map(Profile.fromMap).toList());
  }

  Future<void> updateUserAdmin(String uid, {String? role, bool? isAdmin, List<String>? groupIds, String? staffTitle}) => supa
      .from('profiles')
      .update({
        if (role != null) 'role': role,
        if (isAdmin != null) 'is_admin': isAdmin,
        if (groupIds != null) 'group_ids': groupIds,
        if (staffTitle != null) 'staff_title': staffTitle,
      })
      .eq('id', uid);

  /// Bans the Auth account (not just a client flag) via the
  /// `admin-set-user-disabled` Edge Function, which needs the service role.
  Future<void> setUserAccountDisabled(String uid, bool disabled) async {
    final result = await supa.functions.invoke('admin-set-user-disabled', body: {'targetUserId': uid, 'disabled': disabled});
    if (result.status != 200) {
      final err = (result.data is Map) ? result.data['error'] as String? : null;
      throw Exception(err ?? 'Aktion fehlgeschlagen.');
    }
  }

  Future<void> deleteUserAccount(String uid) async {
    final result = await supa.functions.invoke('admin-delete-user', body: {'targetUserId': uid});
    if (result.status != 200) {
      final err = (result.data is Map) ? result.data['error'] as String? : null;
      throw Exception(err ?? 'Löschen fehlgeschlagen.');
    }
  }

  // ── Groups ─────────────────────────────────────────────────────────
  Future<void> updateGroupTeam(String groupId, List<(String name, String title)> members) async {
    await supa.from('group_team_members').delete().eq('group_id', groupId);
    if (members.isEmpty) return;
    await supa.from('group_team_members').insert([
      for (var i = 0; i < members.length; i++)
        {'group_id': groupId, 'name': members[i].$1, 'title': members[i].$2, 'sort_order': i},
    ]);
  }

  Future<void> updateGroupChildCount(String groupId, int count) =>
      supa.from('groups').update({'child_count': count}).eq('id', groupId);

  // ── Content: events / closures / documents / speiseplan ───────────
  Stream<List<KitaEvent>> streamAllEvents() {
    return supa.from('events').stream(primaryKey: ['id']).order('event_date').map((rows) => rows.map(KitaEvent.fromMap).toList());
  }

  Stream<List<Closure>> streamClosures() {
    return supa.from('closures').stream(primaryKey: ['id']).order('start_date').map((rows) => rows.map(Closure.fromMap).toList());
  }

  Stream<List<DocumentItem>> streamDocuments() {
    return supa.from('documents').stream(primaryKey: ['id']).order('created_at', ascending: false).map((rows) => rows.map(DocumentItem.fromMap).toList());
  }

  Future<void> createEvent({required String title, required DateTime eventDate, String? timeLabel, String? location, String? groupId}) =>
      supa.from('events').insert({
        'title': title,
        'event_date': eventDate.toIso8601String().split('T').first,
        'time_label': timeLabel,
        'location': location,
        'group_id': groupId,
      });

  Future<void> deleteEvent(String id) => supa.from('events').delete().eq('id', id);

  Future<void> createClosure({required String title, required DateTime startDate, required DateTime endDate}) =>
      supa.from('closures').insert({
        'title': title,
        'start_date': startDate.toIso8601String().split('T').first,
        'end_date': endDate.toIso8601String().split('T').first,
      });

  Future<void> deleteClosure(String id) => supa.from('closures').delete().eq('id', id);

  Future<void> createDocument({required String title, required String fileUrl, String? sizeLabel, String? groupId}) =>
      supa.from('documents').insert({'title': title, 'file_url': fileUrl, 'size_label': sizeLabel, 'group_id': groupId});

  Future<void> deleteDocument(String id) => supa.from('documents').delete().eq('id', id);

  Future<void> saveSpeiseplan(List<SpeiseplanItem> items) =>
      supa.from('speiseplan').upsert({'id': 'current', 'items': items.map((i) => i.toMap()).toList()});
}
