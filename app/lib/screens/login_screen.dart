import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/providers.dart';
import '../theme/tokens.dart';
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 56, 26, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(border: Border.all(color: AppColors.accent), borderRadius: BorderRadius.circular(16)),
                child: const Text('FZ', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 17, color: AppColors.accent)),
              ),
              const SizedBox(height: 22),
              const Text(
                'Willkommen im\nFamilienzentrum Lank',
                style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 27, height: 1.15, color: AppColors.text),
              ),
              const SizedBox(height: 6),
              const SizedBox(
                width: 250,
                child: Text(
                  'Der geschützte Treffpunkt für Eltern, Kinder und das Kita-Team. Melde dich mit dem Code aus deinem Elternbrief an.',
                  style: TextStyle(fontSize: 13.5, color: AppColors.neutral400, height: 1.4),
                ),
              ),
              const SizedBox(height: 26),
              NField(label: 'E-Mail', controller: _emailCtrl, hintText: 'sandra.weber@example.de', keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 10),
              NField(label: 'Zugangscode', controller: _codeCtrl, hintText: 'LANK-2026'),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(fontSize: 12.5, color: AppColors.groupRot)),
              ],
              const SizedBox(height: 16),
              NButton(label: 'Anmelden', variant: NButtonVariant.primary, block: true, loading: _loading, onPressed: _doLogin),
              const SizedBox(height: 2),
              const NButton(label: 'Code vergessen?', variant: NButtonVariant.ghost, block: true, small: true),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Geschlossener Bereich. Nur angemeldete Familien und Mitarbeitende sehen Inhalte und Fotos.',
                      style: TextStyle(fontSize: 11, height: 1.45, color: AppColors.neutral500),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
