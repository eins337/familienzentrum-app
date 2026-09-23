import '../models/models.dart';
import 'supabase_service.dart';

/// General Kita content that isn't posts/chat/playdates: groups, children,
/// events, closures, documents, Speiseplan, sick reports.
class KitaService {
  Future<List<Group>> fetchGroups() async {
    final rows = await supa.from('groups').select().order('id');
    return rows.map(Group.fromMap).toList();
  }

  Stream<List<FamilyMember>> streamFamilyMembers() {
    return supa.from('family_members').stream(primaryKey: ['family_id', 'user_id']).map((rows) => rows.map(FamilyMember.fromMap).toList());
  }

  /// Every child except the caller's own family's — used by the
  /// Spielanfrage "Anfrage an" family picker.
  Future<List<Child>> fetchOtherChildren(String excludeFamilyId) async {
    final rows = await supa.from('children').select().neq('family_id', excludeFamilyId);
    return rows.map(Child.fromMap).toList();
  }

  Future<String?> fetchPrimaryFamilyMemberUid(String familyId) async {
    final row = await supa.from('family_members').select('user_id').eq('family_id', familyId).limit(1).maybeSingle();
    return row?['user_id'] as String?;
  }

  /// A real team account assigned to [groupId] — used by the "Erzieher
  /// schreiben" quick action, since `group_team_members` is a display-only
  /// roster with no link to an actual login.
  Future<String?> fetchPrimaryTeamMemberUid(String groupId) async {
    final rows = await supa.from('profiles').select('id').eq('role', 'team').contains('group_ids', [groupId]).limit(1);
    return rows.isEmpty ? null : rows.first['id'] as String?;
  }

  Future<List<Child>> fetchChildrenInGroup(String groupId) async {
    final rows = await supa.from('children').select().eq('group_id', groupId);
    return rows.map(Child.fromMap).toList();
  }

  Future<void> updateChildConsent(String childId, {bool? photoConsentGroup, bool? photoConsentWebsite}) => supa
      .from('children')
      .update({
        if (photoConsentGroup != null) 'photo_consent_group': photoConsentGroup,
        if (photoConsentWebsite != null) 'photo_consent_website': photoConsentWebsite,
      })
      .eq('id', childId);

  /// Parents maintain their own child's "Wichtig für die Kita" hints —
  /// these surface live in the team's Gruppe view.
  Future<void> updateChildTags(String childId, List<String> tags) => supa.from('children').update({'tags': tags}).eq('id', childId);

  /// Parents update their own child's Bringzeit (drop-off time) — the
  /// *_updated_at/_by stamp lets the team-facing Mitteilungen feed
  /// synthesize a "changed" notice without a separate notifications table.
  Future<void> updateBringTime(String childId, {required String bringTime, String? note, required String updatedByUid}) => supa
      .from('children')
      .update({
        'bring_time': bringTime,
        'bring_time_note': note,
        'bring_time_updated_at': DateTime.now().toIso8601String(),
        'bring_time_updated_by': updatedByUid,
      })
      .eq('id', childId);

  /// Mirrors updateBringTime for the pick-up time.
  Future<void> updatePickupTime(String childId, {required String pickupTime, String? note, required String updatedByUid}) => supa
      .from('children')
      .update({
        'pickup_time': pickupTime,
        'pickup_time_note': note,
        'pickup_time_updated_at': DateTime.now().toIso8601String(),
        'pickup_time_updated_by': updatedByUid,
      })
      .eq('id', childId);

  Stream<List<KitaEvent>> streamUpcomingEvents() {
    final today = DateTime.now();
    final todayStr = '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return supa
        .from('events')
        .stream(primaryKey: ['id'])
        .order('event_date')
        .map((rows) => rows.map(KitaEvent.fromMap).where((e) => !e.eventDate.isBefore(DateTime.parse(todayStr))).toList());
  }

  Future<void> toggleRsvp(String eventId) => supa.rpc('toggle_event_rsvp', params: {'p_event_id': eventId});

  Future<List<Closure>> fetchClosures() async {
    final rows = await supa.from('closures').select().order('start_date');
    return rows.map(Closure.fromMap).toList();
  }

  Future<List<DocumentItem>> fetchDocuments() async {
    final rows = await supa.from('documents').select().order('created_at', ascending: false);
    return rows.map(DocumentItem.fromMap).toList();
  }

  Future<Speiseplan?> fetchSpeiseplan() async {
    final row = await supa.from('speiseplan').select().eq('id', 'current').maybeSingle();
    return row == null ? null : Speiseplan.fromMap(row);
  }

  /// Replaces the current Speiseplan with a new PDF — the singleton row
  /// under `speiseplan.id = 'current'` powers the Feed card and Infos tab.
  Future<void> publishSpeiseplan({required String fileUrl, required String fileName, required int kw}) => supa.from('speiseplan').upsert({
        'id': 'current',
        'file_url': fileUrl,
        'file_name': fileName,
        'kw': kw,
        'updated_at': DateTime.now().toIso8601String(),
      });

  Future<void> createSickReport({
    required String childId,
    required String familyId,
    String? groupId,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) {
    final days = endDate.difference(startDate).inDays + 1;
    final dateLabel = startDate.isAtSameMomentAs(endDate)
        ? '${_short(startDate)} · 1 Tag'
        : '${_short(startDate)} – ${_short(endDate)} · $days Tage';
    return supa.from('sick_reports').insert({
      'child_id': childId,
      'family_id': familyId,
      'group_id': groupId,
      'date_label': dateLabel,
      'start_date': _iso(startDate),
      'end_date': _iso(endDate),
      'reason': reason,
    });
  }

  String _short(DateTime d) => '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.';
  String _iso(DateTime d) => d.toIso8601String().split('T').first;

  Stream<List<SickReport>> streamSickReports({bool onlyOpen = true}) {
    final base = supa.from('sick_reports').stream(primaryKey: ['id']).order('created_at', ascending: false);
    return base.map((rows) {
      final all = rows.map(SickReport.fromMap).toList();
      return onlyOpen ? all.where((r) => !r.acknowledged).toList() : all;
    });
  }

  /// Sick reports for one family — used to show the parent-facing "active
  /// Krankmeldung" status card on Feed/Profil.
  Stream<List<SickReport>> streamSickReportsForFamily(String familyId) {
    return supa
        .from('sick_reports')
        .stream(primaryKey: ['id'])
        .eq('family_id', familyId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(SickReport.fromMap).toList());
  }

  Future<void> acknowledgeSickReport(String id) => supa.from('sick_reports').update({'acknowledged': true}).eq('id', id);

  /// The "Zurücknehmen" action a parent can take on their own family's
  /// still-open Krankmeldung.
  Future<void> cancelSickReport(String id) => supa.from('sick_reports').update({'cancelled': true}).eq('id', id);
}
