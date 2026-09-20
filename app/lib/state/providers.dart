import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import '../services/chats_service.dart';
import '../services/kita_service.dart';
import '../services/marketplace_service.dart';
import '../services/playdates_service.dart';
import '../services/posts_service.dart';
import '../services/supabase_service.dart';

final authServiceProvider = Provider((ref) => AuthService());
final postsServiceProvider = Provider((ref) => PostsService());
final chatsServiceProvider = Provider((ref) => ChatsService());
final playdatesServiceProvider = Provider((ref) => PlaydatesService());
final kitaServiceProvider = Provider((ref) => KitaService());
final adminServiceProvider = Provider((ref) => AdminService());
final marketplaceServiceProvider = Provider((ref) => MarketplaceService());

/// Raw Supabase auth state (SIGNED_IN / SIGNED_OUT / ...).
final authStateProvider = StreamProvider<AuthState>((ref) => supa.auth.onAuthStateChange);

/// The current user's profile row, kept live via realtime — so an admin
/// flipping someone's role/groupIds/disabled flag takes effect immediately.
final profileProvider = StreamProvider<Profile?>((ref) {
  final authState = ref.watch(authStateProvider).valueOrNull;
  final uid = authState?.session?.user.id ?? supa.auth.currentUser?.id;
  if (uid == null) return Stream.value(null);
  return ref.watch(authServiceProvider).subscribeProfile(uid);
});

final familyProvider = FutureProvider<Family?>((ref) async {
  final profile = ref.watch(profileProvider).valueOrNull;
  if (profile?.familyId == null) return null;
  return ref.watch(authServiceProvider).fetchFamily(profile!.familyId!);
});

final groupsProvider = FutureProvider<List<Group>>((ref) => ref.watch(kitaServiceProvider).fetchGroups());

final childrenInGroupProvider = FutureProvider.family<List<Child>, String>(
  (ref, groupId) => ref.watch(kitaServiceProvider).fetchChildrenInGroup(groupId),
);

final groupTeamProvider = FutureProvider.family<List<GroupTeamMember>, String>(
  (ref, groupId) => ref.watch(kitaServiceProvider).fetchGroupTeam(groupId),
);

/// A plain one-shot fetch (not derived from the `allChildrenProvider`
/// realtime stream — that was tried and reverted: it made this provider,
/// which nearly every screen depends on, hang forever if the realtime
/// websocket didn't connect cleanly, breaking Profil and the Spielanfrage
/// child pickers). Staleness after a consent/tags/Bringzeit edit is fixed
/// by explicitly invalidating this provider at each call site instead —
/// see profil_screen.dart.
final myChildrenProvider = FutureProvider<List<Child>>((ref) async {
  final profile = ref.watch(profileProvider).valueOrNull;
  if (profile?.familyId == null) return [];
  final rows = await supa.from('children').select().eq('family_id', profile!.familyId!);
  return rows.map(Child.fromMap).toList();
});

/// Cheap id→displayName / id→profile lookup for the whole app (author
/// names on posts/comments, chat participant names, etc.) since our
/// realtime `.stream()` queries can't express joins.
final allProfilesProvider = StreamProvider<Map<String, Profile>>((ref) {
  return supa.from('profiles').stream(primaryKey: ['id']).map(
        (rows) => {for (final r in rows) r['id'] as String: Profile.fromMap(r)},
      );
});

final allChildrenProvider = StreamProvider<Map<String, Child>>((ref) {
  return supa.from('children').stream(primaryKey: ['id']).map(
        (rows) => {for (final r in rows) r['id'] as String: Child.fromMap(r)},
      );
});

/// Scoped to the caller's own groups — the `posts` table's RLS is
/// intentionally open ("readable by signed-in") the same way `children`/
/// `groups` are, with group-visibility meant to be enforced client-side
/// (matching this provider's sibling filters like `streamMyPlaydates`).
/// This provider previously returned every post unfiltered, so a parent
/// saw every other group's posts too.
final feedPostsProvider = StreamProvider<List<Post>>((ref) {
  final profile = ref.watch(profileProvider).valueOrNull;
  final myChildren = ref.watch(myChildrenProvider).valueOrNull ?? [];
  final relevantGroups = profile?.isTeam ?? false
      ? profile!.groupIds.toSet()
      : myChildren.map((c) => c.groupId).whereType<String>().toSet();
  return ref.watch(postsServiceProvider).streamFeed().map(
        (posts) => posts.where((p) => p.groupId == null || relevantGroups.contains(p.groupId)).toList(),
      );
});

final groupPostsProvider = StreamProvider.family<List<Post>, String>(
  (ref, groupId) => ref.watch(postsServiceProvider).streamGroupPosts(groupId),
);

final upcomingEventsProvider = StreamProvider<List<KitaEvent>>((ref) => ref.watch(kitaServiceProvider).streamUpcomingEvents());

final speiseplanProvider = FutureProvider<Speiseplan?>((ref) => ref.watch(kitaServiceProvider).fetchSpeiseplan());

final closuresProvider = FutureProvider<List<Closure>>((ref) => ref.watch(kitaServiceProvider).fetchClosures());

final documentsProvider = FutureProvider<List<DocumentItem>>((ref) => ref.watch(kitaServiceProvider).fetchDocuments());

final myChatsProvider = StreamProvider<List<Chat>>((ref) {
  final profile = ref.watch(profileProvider).valueOrNull;
  if (profile == null) return Stream.value(const []);
  final relevantGroupIds = profile.isTeam ? profile.groupIds.toSet() : ref.watch(myChildrenProvider).valueOrNull?.map((c) => c.groupId).whereType<String>().toSet() ?? {};
  return ref.watch(chatsServiceProvider).streamMyChats(profile.id, relevantGroupIds: relevantGroupIds);
});

final chatMessagesProvider = StreamProvider.family<List<Message>, String>(
  (ref, chatId) => ref.watch(chatsServiceProvider).streamMessages(chatId),
);

final lastMessageProvider = FutureProvider.family<Message?, String>(
  (ref, chatId) => ref.watch(chatsServiceProvider).fetchLastMessage(chatId),
);

final playdateForChatProvider = FutureProvider.family<PlaydateRequest?, String>(
  (ref, chatId) => ref.watch(playdatesServiceProvider).fetchByChatId(chatId),
);

final myPlaydatesProvider = StreamProvider<List<PlaydateRequest>>((ref) {
  final familyId = ref.watch(profileProvider).valueOrNull?.familyId;
  if (familyId == null) return Stream.value(const []);
  return ref.watch(playdatesServiceProvider).streamMyPlaydates(familyId);
});

final mySickReportsProvider = StreamProvider<List<SickReport>>((ref) {
  final familyId = ref.watch(profileProvider).valueOrNull?.familyId;
  if (familyId == null) return Stream.value(const []);
  return ref.watch(kitaServiceProvider).streamSickReportsForFamily(familyId);
});

final allFamiliesProvider = StreamProvider<Map<String, Family>>((ref) {
  return supa.from('families').stream(primaryKey: ['id']).map(
        (rows) => {for (final r in rows) r['id'] as String: Family.fromMap(r)},
      );
});

final marketplaceItemsProvider = StreamProvider<List<MarketplaceItem>>((ref) => ref.watch(marketplaceServiceProvider).streamItems());
