import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/providers.dart';
import '../theme/tokens.dart';
import '../widgets/app_logo.dart';
import '../widgets/widgets.dart';

/// Shown instead of the app once a profile's `must_change_password` flag is
/// set — forced onto anyone signing in for the first time with an invite
/// code, so that code (used as the initial password) is replaced with
/// something only the family/staff member knows and then stops working.
/// The router's redirect (app_router.dart) is what routes here and away
/// again; this screen has no back/skip button on purpose.
class ForcePasswordChangeScreen extends ConsumerStatefulWidget {
  const ForcePasswordChangeScreen({super.key});

  @override
  ConsumerState<ForcePasswordChangeScreen> createState() => _ForcePasswordChangeScreenState();
}

class _ForcePasswordChangeScreenState extends ConsumerState<ForcePasswordChangeScreen> {
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final uid = ref.read(profileProvider).valueOrNull?.id;
    if (uid == null) return;
    if (_newCtrl.text.length < 6) {
      setState(() => _error = 'Mindestens 6 Zeichen.');
      return;
    }
    if (_newCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Passwörter stimmen nicht überein.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).updatePassword(_newCtrl.text);
      await ref.read(authServiceProvider).clearMustChangePassword(uid);
      // No manual navigation needed: clearing the flag updates profileProvider
      // (a realtime stream), which the router's redirect reacts to.
    } catch (e) {
      if (mounted) setState(() => _error = 'Fehler: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(color: AppColors.soft, shape: BoxShape.circle),
                child: const AppLogo(size: 96),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Passwort festlegen',
              style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 24, color: AppColors.ink),
            ),
            const SizedBox(height: 6),
            const Text(
              'Du hast dich mit deinem Einladungscode angemeldet. Bevor es weitergeht, lege bitte ein eigenes Passwort fest — der Einladungscode funktioniert danach nicht mehr.',
              style: TextStyle(fontSize: 13.5, color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 26),
            NField(label: 'Neues Passwort', controller: _newCtrl, obscureText: true),
            const SizedBox(height: 10),
            NField(label: 'Passwort bestätigen', controller: _confirmCtrl, obscureText: true),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(fontSize: 12.5, color: AppColors.error)),
            ],
            const SizedBox(height: 16),
            NButton(label: 'Passwort speichern', variant: NButtonVariant.primary, block: true, loading: _saving, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
