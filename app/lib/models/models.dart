// Data models — one row per Postgres table (see supabase/migrations/0001_init.sql).
// Kept as plain Dart classes with fromMap/toMap rather than code-gen, since
// the schema is small and stable enough that codegen would be overhead.

typedef Json = Map<String, dynamic>;

List<String> _strList(dynamic v) => (v as List?)?.map((e) => e.toString()).toList() ?? const [];

class Profile {
  Profile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.familyId,
    this.isAdmin = false,
    this.groupIds = const [],
    this.staffTitle,
    this.disabled = false,
    this.kitaLeitung = false,
    this.mustChangePassword = false,
    this.pushToken,
    this.avatarUrl,
    required this.createdAt,
    Map<String, dynamic>? notificationSettings,
    Map<String, dynamic>? privacySettings,
  })  : notificationSettings = notificationSettings ?? const {'posts': true, 'chat': true, 'playdates': true, 'quietHours': false},
        privacySettings = privacySettings ?? const {'contactVisibleInChat': true, 'playdateRequestsScope': 'group', 'photoConsentAppOnly': true};

  final String id;
  final String email;
  final String displayName;
  final String role; // 'parent' | 'team'
  final String? familyId;
  final bool isAdmin;
  final List<String> groupIds;
  final String? staffTitle;
  final bool disabled;
  final bool kitaLeitung;
  final bool mustChangePassword;
  final String? pushToken;
  final String? avatarUrl;
  final DateTime createdAt;
  final Map<String, dynamic> notificationSettings;
  final Map<String, dynamic> privacySettings;

  bool get isTeam => role == 'team';

  factory Profile.fromMap(Json m) => Profile(
        id: m['id'] as String,
        email: m['email'] as String,
        displayName: m['display_name'] as String,
        role: m['role'] as String,
        familyId: m['family_id'] as String?,
        isAdmin: m['is_admin'] as bool? ?? false,
        groupIds: _strList(m['group_ids']),
        staffTitle: m['staff_title'] as String?,
        disabled: m['disabled'] as bool? ?? false,
        kitaLeitung: m['kita_leitung'] as bool? ?? false,
        mustChangePassword: m['must_change_password'] as bool? ?? false,
        pushToken: m['push_token'] as String?,
        avatarUrl: m['avatar_url'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
        notificationSettings: (m['notification_settings'] as Json?)?.cast<String, dynamic>(),
        privacySettings: (m['privacy_settings'] as Json?)?.cast<String, dynamic>(),
      );
}

class Family {
  Family({required this.id, required this.name, required this.createdAt});
  final String id;
  final String name;
  final DateTime createdAt;

  factory Family.fromMap(Json m) =>
      Family(id: m['id'] as String, name: m['name'] as String, createdAt: DateTime.parse(m['created_at'] as String));
}

class FamilyMember {
  FamilyMember({required this.familyId, required this.userId, required this.relation});
  final String familyId;
  final String userId;
  final String relation;

  factory FamilyMember.fromMap(Json m) =>
      FamilyMember(familyId: m['family_id'] as String, userId: m['user_id'] as String, relation: m['relation'] as String);
}

class Child {
  Child({
    required this.id,
    required this.familyId,
    this.groupId,
    required this.name,
    this.birthYear,
    this.birthDate,
    this.avatarUrl,
    this.tags = const [],
    this.photoConsentGroup = true,
    this.photoConsentWebsite = false,
    this.bringTime,
    this.bringTimeNote,
    this.bringTimeUpdatedAt,
    this.bringTimeUpdatedBy,
    this.pickupTime,
    this.pickupTimeNote,
    this.pickupTimeUpdatedAt,
    this.pickupTimeUpdatedBy,
    required this.createdAt,
  });

  final String id;
  final String familyId;
  final String? groupId;
  final String name;
  final int? birthYear;
  final DateTime? birthDate;
  final String? avatarUrl;
  final List<String> tags;
  final bool photoConsentGroup;
  final bool photoConsentWebsite;

  /// The time the family drops this child off, e.g. "08:00" — free text so
  /// families can note something like "08:00 (montags 08:30)" rather than
  /// being forced into a single fixed slot.
  final String? bringTime;
  final String? bringTimeNote;
  final DateTime? bringTimeUpdatedAt;
  final String? bringTimeUpdatedBy;

  /// The time the family collects this child, mirroring bringTime.
  final String? pickupTime;
  final String? pickupTimeNote;
  final DateTime? pickupTimeUpdatedAt;
  final String? pickupTimeUpdatedBy;
  final DateTime createdAt;

  int get age {
    if (birthDate != null) {
      final now = DateTime.now();
      var years = now.year - birthDate!.year;
      if (now.month < birthDate!.month || (now.month == birthDate!.month && now.day < birthDate!.day)) years--;
      return years;
    }
    return birthYear == null ? 0 : DateTime.now().year - birthYear!;
  }

  /// Days until the next birthday (0 if today), or null if no birth_date
  /// is on file.
  int? get daysUntilNextBirthday {
    if (birthDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var next = DateTime(today.year, birthDate!.month, birthDate!.day);
    if (next.isBefore(today)) next = DateTime(today.year + 1, birthDate!.month, birthDate!.day);
    return next.difference(today).inDays;
  }

  factory Child.fromMap(Json m) => Child(
        id: m['id'] as String,
        familyId: m['family_id'] as String,
        groupId: m['group_id'] as String?,
        name: m['name'] as String,
        birthYear: m['birth_year'] as int?,
        birthDate: m['birth_date'] != null ? DateTime.parse(m['birth_date'] as String) : null,
        avatarUrl: m['avatar_url'] as String?,
        tags: _strList(m['tags']),
        photoConsentGroup: m['photo_consent_group'] as bool? ?? true,
        photoConsentWebsite: m['photo_consent_website'] as bool? ?? false,
        bringTime: m['bring_time'] as String?,
        bringTimeNote: m['bring_time_note'] as String?,
        bringTimeUpdatedAt: m['bring_time_updated_at'] != null ? DateTime.parse(m['bring_time_updated_at'] as String) : null,
        bringTimeUpdatedBy: m['bring_time_updated_by'] as String?,
        pickupTime: m['pickup_time'] as String?,
        pickupTimeNote: m['pickup_time_note'] as String?,
        pickupTimeUpdatedAt: m['pickup_time_updated_at'] != null ? DateTime.parse(m['pickup_time_updated_at'] as String) : null,
        pickupTimeUpdatedBy: m['pickup_time_updated_by'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}

class Group {
  Group({required this.id, required this.name, required this.color, this.childCount = 0, this.leadProfileId});
  final String id;
  final String name;
  final String color;
  final int childCount;
  final String? leadProfileId;

  factory Group.fromMap(Json m) => Group(
        id: m['id'] as String,
        name: m['name'] as String,
        color: m['color'] as String,
        childCount: m['child_count'] as int? ?? 0,
        leadProfileId: m['lead_profile_id'] as String?,
      );
}

class PostPoll {
  PostPoll({required this.options, this.voterIds = const []});
  final List<PostPollOption> options;
  final List<String> voterIds;

  factory PostPoll.fromMap(Json m) => PostPoll(
        options: (m['options'] as List? ?? []).map((o) => PostPollOption.fromMap(o as Json)).toList(),
        voterIds: _strList(m['voter_ids']),
      );
}

class PostPollOption {
  PostPollOption({required this.label, this.votes = 0});
  final String label;
  final int votes;

  factory PostPollOption.fromMap(Json m) => PostPollOption(label: m['label'] as String, votes: m['votes'] as int? ?? 0);
}

class Post {
  Post({
    required this.id,
    required this.authorId,
    this.groupId,
    required this.kind,
    required this.visibility,
    this.title,
    this.body = '',
    this.pinned = false,
    this.photoUrls = const [],
    this.fileName,
    this.fileSizeLabel,
    this.fileUrl,
    this.eventDate,
    this.eventLocation,
    this.poll,
    this.likes = const [],
    this.rsvps = const [],
    this.commentCount = 0,
    required this.createdAt,
    this.authorName,
  });

  final String id;
  final String authorId;
  final String? groupId;
  final String kind; // 'foto' | 'info' | 'termin' | 'umfrage'
  final String visibility; // 'all' | 'group' | 'beirat'
  final String? title;
  final String body;
  final bool pinned;
  final List<String> photoUrls;
  final String? fileName;
  final String? fileSizeLabel;
  final String? fileUrl;
  final DateTime? eventDate;
  final String? eventLocation;
  final PostPoll? poll;
  final List<String> likes;
  final List<String> rsvps;
  final int commentCount;
  final DateTime createdAt;
  final String? authorName; // joined convenience field, not a DB column

  factory Post.fromMap(Json m) => Post(
        id: m['id'] as String,
        authorId: m['author_id'] as String,
        groupId: m['group_id'] as String?,
        kind: m['kind'] as String,
        visibility: m['visibility'] as String,
        title: m['title'] as String?,
        body: m['body'] as String? ?? '',
        pinned: m['pinned'] as bool? ?? false,
        photoUrls: _strList(m['photo_urls']),
        fileName: m['file_name'] as String?,
        fileSizeLabel: m['file_size_label'] as String?,
        fileUrl: m['file_url'] as String?,
        eventDate: m['event_date'] != null ? DateTime.parse(m['event_date'] as String) : null,
        eventLocation: m['event_location'] as String?,
        poll: m['poll'] != null ? PostPoll.fromMap(m['poll'] as Json) : null,
        likes: _strList(m['likes']),
        rsvps: _strList(m['rsvps']),
        commentCount: m['comment_count'] as int? ?? 0,
        createdAt: DateTime.parse(m['created_at'] as String),
        authorName: (m['profiles'] as Json?)?['display_name'] as String?,
      );
}

class PostComment {
  PostComment({required this.id, required this.postId, required this.authorId, required this.body, required this.createdAt, this.authorName});
  final String id;
  final String postId;
  final String authorId;
  final String body;
  final DateTime createdAt;
  final String? authorName;

  factory PostComment.fromMap(Json m) => PostComment(
        id: m['id'] as String,
        postId: m['post_id'] as String,
        authorId: m['author_id'] as String,
        body: m['body'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
        authorName: (m['profiles'] as Json?)?['display_name'] as String?,
      );
}

class Chat {
  Chat({
    required this.id,
    this.isGroup = false,
    this.name,
    this.groupId,
    this.channel,
    this.participantIds = const [],
    required this.createdAt,
    required this.lastMessageAt,
  });

  final String id;
  final bool isGroup;
  final String? name;
  final String? groupId;
  /// 'eltern' | 'team' for a group channel; null for a direct 1:1 chat.
  final String? channel;
  final List<String> participantIds;
  final DateTime createdAt;
  final DateTime lastMessageAt;

  factory Chat.fromMap(Json m) => Chat(
        id: m['id'] as String,
        isGroup: m['is_group'] as bool? ?? false,
        name: m['name'] as String?,
        groupId: m['group_id'] as String?,
        channel: m['channel'] as String?,
        participantIds: _strList(m['participant_ids']),
        createdAt: DateTime.parse(m['created_at'] as String),
        lastMessageAt: DateTime.parse(m['last_message_at'] as String),
      );
}

class Message {
  Message({required this.id, required this.chatId, required this.senderId, required this.body, required this.createdAt});
  final String id;
  final String chatId;
  final String senderId;
  final String body;
  final DateTime createdAt;

  factory Message.fromMap(Json m) => Message(
        id: m['id'] as String,
        chatId: m['chat_id'] as String,
        senderId: m['sender_id'] as String,
        body: m['body'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}

class PlaydateSlot {
  PlaydateSlot({required this.date, required this.timeRange, this.location});
  final String date;
  final String timeRange;
  final String? location;

  Json toMap() => {'date': date, 'time_range': timeRange, 'location': location};
  factory PlaydateSlot.fromMap(Json m) =>
      PlaydateSlot(date: m['date'] as String, timeRange: m['time_range'] as String, location: m['location'] as String?);
}

class PlaydateRequest {
  PlaydateRequest({
    required this.id,
    required this.fromUid,
    required this.fromFamilyId,
    required this.fromChildId,
    required this.toFamilyId,
    required this.toChildId,
    this.proposedSlots = const [],
    this.status = 'pending',
    this.confirmedSlotIndex,
    this.message,
    this.chatId,
    required this.createdAt,
    this.fromChildName,
    this.toChildName,
    this.toFamilyName,
    this.fromFamilyName,
  });

  final String id;
  final String fromUid;
  final String fromFamilyId;
  final String fromChildId;
  final String toFamilyId;
  final String toChildId;
  final List<PlaydateSlot> proposedSlots;
  final String status; // 'pending' | 'confirmed' | 'declined'
  final int? confirmedSlotIndex;
  final String? message;
  final String? chatId;
  final DateTime createdAt;
  final String? fromChildName;
  final String? toChildName;
  final String? toFamilyName;
  final String? fromFamilyName;

  factory PlaydateRequest.fromMap(Json m) => PlaydateRequest(
        id: m['id'] as String,
        fromUid: m['from_uid'] as String,
        fromFamilyId: m['from_family_id'] as String,
        fromChildId: m['from_child_id'] as String,
        toFamilyId: m['to_family_id'] as String,
        toChildId: m['to_child_id'] as String,
        proposedSlots: (m['proposed_slots'] as List? ?? []).map((s) => PlaydateSlot.fromMap(s as Json)).toList(),
        status: m['status'] as String? ?? 'pending',
        confirmedSlotIndex: m['confirmed_slot_index'] as int?,
        message: m['message'] as String?,
        chatId: m['chat_id'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
        fromChildName: (m['from_child'] as Json?)?['name'] as String?,
        toChildName: (m['to_child'] as Json?)?['name'] as String?,
        toFamilyName: (m['to_family'] as Json?)?['name'] as String?,
        fromFamilyName: (m['from_family'] as Json?)?['name'] as String?,
      );
}

class SickReport {
  SickReport({
    required this.id,
    required this.childId,
    required this.familyId,
    this.groupId,
    required this.dateLabel,
    required this.startDate,
    required this.endDate,
    this.reason,
    this.acknowledged = false,
    this.cancelled = false,
    required this.createdAt,
    this.childName,
  });

  final String id;
  final String childId;
  final String familyId;
  final String? groupId;
  final String dateLabel;
  final DateTime startDate;
  final DateTime endDate;
  final String? reason;
  final bool acknowledged;
  final bool cancelled;
  final DateTime createdAt;
  final String? childName;

  int get days => endDate.difference(startDate).inDays + 1;

  /// The date range to display, computed from `startDate`/`endDate` rather
  /// than trusting the stored `dateLabel` text — older reports had that
  /// column populated by a since-removed "Heute, DD.MM." format, which then
  /// stayed frozen in the row forever and confusingly kept saying "Heute"
  /// long after the day had passed.
  String get plainDateLabel {
    String fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.';
    if (startDate.isAtSameMomentAs(endDate)) return fmt(startDate);
    return '${fmt(startDate)} – ${fmt(endDate)} · $days Tage';
  }

  /// Today falls within the reported range and it hasn't been withdrawn.
  bool get isActive {
    if (cancelled) return false;
    final today = DateTime.now();
    final d = DateTime(today.year, today.month, today.day);
    return !d.isBefore(startDate) && !d.isAfter(endDate);
  }

  factory SickReport.fromMap(Json m) => SickReport(
        id: m['id'] as String,
        childId: m['child_id'] as String,
        familyId: m['family_id'] as String,
        groupId: m['group_id'] as String?,
        dateLabel: m['date_label'] as String,
        startDate: DateTime.parse(m['start_date'] as String),
        endDate: DateTime.parse(m['end_date'] as String),
        reason: m['reason'] as String?,
        acknowledged: m['acknowledged'] as bool? ?? false,
        cancelled: m['cancelled'] as bool? ?? false,
        createdAt: DateTime.parse(m['created_at'] as String),
        childName: (m['children'] as Json?)?['name'] as String?,
      );
}

class KitaEvent {
  KitaEvent({
    required this.id,
    required this.title,
    required this.eventDate,
    this.timeLabel,
    this.location,
    this.groupId,
    this.rsvpUids = const [],
    required this.createdAt,
  });

  final String id;
  final String title;
  final DateTime eventDate;
  final String? timeLabel;
  final String? location;
  final String? groupId;
  final List<String> rsvpUids;
  final DateTime createdAt;

  factory KitaEvent.fromMap(Json m) => KitaEvent(
        id: m['id'] as String,
        title: m['title'] as String,
        eventDate: DateTime.parse(m['event_date'] as String),
        timeLabel: m['time_label'] as String?,
        location: m['location'] as String?,
        groupId: m['group_id'] as String?,
        rsvpUids: _strList(m['rsvp_uids']),
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}

class Closure {
  Closure({required this.id, required this.title, required this.startDate, required this.endDate});
  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;

  factory Closure.fromMap(Json m) => Closure(
        id: m['id'] as String,
        title: m['title'] as String,
        startDate: DateTime.parse(m['start_date'] as String),
        endDate: DateTime.parse(m['end_date'] as String),
      );
}

class DocumentItem {
  DocumentItem({required this.id, required this.title, required this.fileUrl, this.sizeLabel, this.groupId, this.pinned = false, required this.createdAt});
  final String id;
  final String title;
  final String fileUrl;
  final String? sizeLabel;
  final String? groupId;
  final bool pinned;
  final DateTime createdAt;

  factory DocumentItem.fromMap(Json m) => DocumentItem(
        id: m['id'] as String,
        title: m['title'] as String,
        fileUrl: m['file_url'] as String,
        sizeLabel: m['size_label'] as String?,
        groupId: m['group_id'] as String?,
        pinned: m['pinned'] as bool? ?? false,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}

class SpeiseplanItem {
  SpeiseplanItem({required this.day, required this.text});
  final String day;
  final String text;
  factory SpeiseplanItem.fromMap(Json m) => SpeiseplanItem(day: m['day'] as String, text: m['text'] as String);
  Json toMap() => {'day': day, 'text': text};
}

class Speiseplan {
  Speiseplan({required this.items, this.fileUrl, this.fileName, this.kw});
  final List<SpeiseplanItem> items;
  final String? fileUrl;
  final String? fileName;
  final int? kw;

  factory Speiseplan.fromMap(Json m) => Speiseplan(
        items: (m['items'] as List? ?? []).map((i) => SpeiseplanItem.fromMap(i as Json)).toList(),
        fileUrl: m['file_url'] as String?,
        fileName: m['file_name'] as String?,
        kw: m['kw'] as int?,
      );
}

class Invite {
  Invite({
    required this.email,
    required this.code,
    required this.role,
    required this.displayName,
    this.familyId,
    this.isAdmin = false,
    this.groupIds,
    this.staffTitle,
    this.createdBy,
    this.redeemedAt,
    required this.createdAt,
    this.familyName,
  });

  final String email;
  final String code;
  final String role;
  final String displayName;
  final String? familyId;
  final bool isAdmin;
  final List<String>? groupIds;
  final String? staffTitle;
  final String? createdBy;
  final DateTime? redeemedAt;
  final DateTime createdAt;
  final String? familyName;

  factory Invite.fromMap(Json m) => Invite(
        email: m['email'] as String,
        code: m['code'] as String,
        role: m['role'] as String,
        displayName: m['display_name'] as String,
        familyId: m['family_id'] as String?,
        isAdmin: m['is_admin'] as bool? ?? false,
        groupIds: m['group_ids'] != null ? _strList(m['group_ids']) : null,
        staffTitle: m['staff_title'] as String?,
        createdBy: m['created_by'] as String?,
        redeemedAt: m['redeemed_at'] != null ? DateTime.parse(m['redeemed_at'] as String) : null,
        createdAt: DateTime.parse(m['created_at'] as String),
        familyName: (m['families'] as Json?)?['name'] as String?,
      );
}

class MarketplaceItem {
  MarketplaceItem({
    required this.id,
    required this.authorId,
    this.familyId,
    required this.title,
    this.description,
    this.status = 'available',
    required this.createdAt,
    this.authorName,
  });

  final String id;
  final String authorId;
  final String? familyId;
  final String title;
  final String? description;
  final String status; // 'available' | 'reserved' | 'given_away'
  final DateTime createdAt;
  final String? authorName; // joined convenience field, not a DB column

  factory MarketplaceItem.fromMap(Json m) => MarketplaceItem(
        id: m['id'] as String,
        authorId: m['author_id'] as String,
        familyId: m['family_id'] as String?,
        title: m['title'] as String,
        description: m['description'] as String?,
        status: m['status'] as String? ?? 'available',
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}
