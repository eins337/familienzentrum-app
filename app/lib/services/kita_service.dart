import '../models/models.dart';
import 'supabase_service.dart';

/// General Kita content that isn't posts/chat/playdates: groups, children,
/// events, closures, documents, Speiseplan, sick reports.
class KitaService {
  Future<List<Group>> fetchGroups() async {
    final rows = await supa.from('groups').select().order('id');
    return rows.map(Group.fromMap).toList();
  }

  Future<List<GroupTeamMember>> fetchGroupTeam(String groupId) async {
    final rows = await supa.from('group_team_members').select().eq('group_id', groupId).order('sort_order');
    return rows.map(GroupTeamMember.fromMap).toList();
  }

  Future<List<Child>> fetchChildrenForFamily(String familyId) async {
    final rows = await supa.from('children').select().eq('family_id', familyId);
    return rows.map(Child.fromMap).toList();
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

  Future<void> createSickReport({
    required String childId,
    required String familyId,
    String? groupId,
    required String dateLabel,
    String? reason,
  }) =>
      supa.from('sick_reports').insert({
        'child_id': childId,
        'family_id': familyId,
        'group_id': groupId,
        'date_label': dateLabel,
        'reason': reason,
      });

  Stream<List<SickReport>> streamSickReports({bool onlyOpen = true}) {
    final base = supa.from('sick_reports').stream(primaryKey: ['id']).order('created_at', ascending: false);
    return base.map((rows) {
      final all = rows.map(SickReport.fromMap).toList();
      return onlyOpen ? all.where((r) => !r.acknowledged).toList() : all;
    });
  }

  Future<void> acknowledgeSickReport(String id) => supa.from('sick_reports').update({'acknowledged': true}).eq('id', id);
}
