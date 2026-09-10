import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import '../services/chats_service.dart';
import '../services/kita_service.dart';
import '../services/playdates_service.dart';
import '../services/posts_service.dart';
import '../services/supabase_service.dart';

final authServiceProvider = Provider((ref) => AuthService());
final postsServiceProvider = Provider((ref) => PostsService());
final chatsServiceProvider = Provider((ref) => ChatsService());
final playdatesServiceProvider = Provider((ref) => PlaydatesService());
final kitaServiceProvider = Provider((ref) => KitaService());
final adminServiceProvider = Provider((ref) => AdminService());

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

final myChildrenProvider = FutureProvider<List<Child>>((ref) async {
  final profile = ref.watch(profileProvider).valueOrNull;
  if (profile?.familyId == null) return [];
  return ref.watch(kitaServiceProvider).fetchChildrenForFamily(profile!.familyId!);
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

final allFamiliesProvider = StreamProvider<Map<String, Family>>((ref) {
  return supa.from('families').stream(primaryKey: ['id']).map(
        (rows) => {for (final r in rows) r['id'] as String: Family.fromMap(r)},
      );
});
