import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/providers.dart';
import '../theme/tokens.dart';
import '../widgets/app_logo.dart';
import '../widgets/widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  bool _codeVisible = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    if (_emailCtrl.text.trim().isEmpty || _codeCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Bitte E-Mail und Zugangscode eingeben.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).signInWithAccessCode(_emailCtrl.text, _codeCtrl.text);
      // Router's redirect (watching authStateProvider) navigates on to
      // /feed automatically once the session becomes signed-in.
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
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
                  child: const AppLogo(size: 108),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Willkommen im\nFamilienzentrum Lank',
                style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 27, height: 1.15, color: AppColors.ink),
              ),
              const SizedBox(height: 6),
              const SizedBox(
                width: 250,
                child: Text(
                  'Der geschützte Treffpunkt für Eltern, Kinder und das Kita-Team. Melde dich mit dem Code aus deinem Elternbrief an.',
                  style: TextStyle(fontSize: 13.5, color: AppColors.muted, height: 1.4),
                ),
              ),
              const SizedBox(height: 26),
              NField(label: 'E-Mail', controller: _emailCtrl, hintText: 'name@familie.de', keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 10),
              NField(
                label: 'Zugangscode',
                controller: _codeCtrl,
                hintText: 'Zugangscode oder Passwort',
                obscureText: !_codeVisible,
                suffixIcon: IconButton(
                  icon: Icon(_codeVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 19, color: AppColors.muted),
                  onPressed: () => setState(() => _codeVisible = !_codeVisible),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(fontSize: 12.5, color: AppColors.error)),
              ],
              const SizedBox(height: 16),
              NButton(label: 'Anmelden', variant: NButtonVariant.primary, block: true, loading: _loading, onPressed: _doLogin),
              const SizedBox(height: 2),
              const NButton(label: 'Code vergessen?', variant: NButtonVariant.ghost, block: true, small: true),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(AppRadius.input)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Geschlossener Bereich. Nur angemeldete Familien und Mitarbeitende sehen Inhalte und Fotos.',
                        style: TextStyle(fontSize: 11, height: 1.45, color: AppColors.muted),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
