import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'supabase_service.dart';

/// The prototype's login screen collects an email + a "Zugangscode" — no
/// separate sign-up screen exists. We model that with Supabase Auth
/// email/password where the access code doubles as the password: a
/// returning family signs in normally; a first-time login redeems a
/// one-time invite (written by Kita staff ahead of time, via the admin
/// panel) through the `redeem-invite` Edge Function, which creates the
/// account server-side with the service role key.
class AuthService {
  Future<User> signInWithAccessCode(String email, String code) async {
    final normalizedEmail = email.trim().toLowerCase();
    try {
      final res = await supa.auth.signInWithPassword(email: normalizedEmail, password: code);
      if (res.user != null) return res.user!;
    } on AuthException catch (e) {
      if (e.statusCode != '400' && e.statusCode != '401') rethrow;
      // fall through to invite redemption below
    }

    final result = await supa.functions.invoke('redeem-invite', body: {'email': normalizedEmail, 'code': code});
    if (result.status != 200) {
      final err = (result.data is Map) ? result.data['error'] as String? : null;
      throw Exception(err ?? 'Anmeldung fehlgeschlagen.');
    }

    final res = await supa.auth.signInWithPassword(email: normalizedEmail, password: code);
    if (res.user == null) throw Exception('Konto wurde erstellt, Anmeldung ist aber fehlgeschlagen. Bitte erneut versuchen.');
    return res.user!;
  }

  Future<void> signOut() => supa.auth.signOut();

  Future<Profile?> fetchProfile(String uid) async {
    final row = await supa.from('profiles').select().eq('id', uid).maybeSingle();
    return row == null ? null : Profile.fromMap(row);
  }

  /// Realtime, not one-shot: an admin flipping the caller's role, groupIds,
  /// or `disabled` flag should take effect immediately, not just on next
  /// login.
  Stream<Profile?> subscribeProfile(String uid) {
    return supa.from('profiles').stream(primaryKey: ['id']).eq('id', uid).map(
          (rows) => rows.isEmpty ? null : Profile.fromMap(rows.first),
        );
  }

  Future<void> updateNotificationSettings(String uid, Map<String, dynamic> settings) =>
      supa.from('profiles').update({'notification_settings': settings}).eq('id', uid);

  Future<void> updatePrivacySettings(String uid, Map<String, dynamic> settings) =>
      supa.from('profiles').update({'privacy_settings': settings}).eq('id', uid);

  Future<Family?> fetchFamily(String familyId) async {
    final row = await supa.from('families').select().eq('id', familyId).maybeSingle();
    return row == null ? null : Family.fromMap(row);
  }

  User? get currentUser => supa.auth.currentUser;
  Stream<AuthState> get onAuthStateChange => supa.auth.onAuthStateChange;
}
