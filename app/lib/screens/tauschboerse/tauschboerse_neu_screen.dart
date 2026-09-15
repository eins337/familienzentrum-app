import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../../widgets/n_button.dart';
import '../../widgets/n_field.dart';
import '../../widgets/n_header.dart';

class TauschboerseNeuScreen extends ConsumerStatefulWidget {
  const TauschboerseNeuScreen({super.key});

  @override
  ConsumerState<TauschboerseNeuScreen> createState() => _TauschboerseNeuScreenState();
}

class _TauschboerseNeuScreenState extends ConsumerState<TauschboerseNeuScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bitte einen Titel angeben.')));
      return;
    }
    final profile = ref.read(profileProvider).valueOrNull;
    if (profile == null) return;
    setState(() => _sending = true);
    try {
      await ref.read(marketplaceServiceProvider).createItem(
            authorId: profile.id,
            familyId: profile.familyId,
            title: title,
            description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          );
      if (mounted) Navigator.of(context).maybePop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NHeader(title: 'Neuer Artikel', subtitle: 'Für die Tauschbörse', showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          NField(label: 'Titel', controller: _titleCtrl, hintText: 'z.B. Matschhose Gr. 98, blau'),
          const SizedBox(height: 10),
          NField(label: 'Beschreibung (optional)', controller: _descCtrl, hintText: 'Zustand, Abholung, Tausch gegen…', minLines: 3, maxLines: 6),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: NButton(label: 'Abbrechen', variant: NButtonVariant.secondary, onPressed: () => Navigator.of(context).maybePop())),
              const SizedBox(width: 7),
              Expanded(flex: 2, child: NButton(label: 'Veröffentlichen', variant: NButtonVariant.primary, loading: _sending, onPressed: _send)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Sichtbar für alle Eltern und das Team der Kita.', textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5, color: AppColors.muted)),
        ],
      ),
    );
  }
}
