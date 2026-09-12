import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../../utils/group_colors.dart';
import '../../widgets/n_button.dart';
import '../../widgets/n_card.dart';
import '../../widgets/n_field.dart';
import '../../widgets/n_header.dart';

class SpielanfrageNeuScreen extends ConsumerStatefulWidget {
  const SpielanfrageNeuScreen({super.key, this.preselectedChildId});
  final String? preselectedChildId;
  @override
  ConsumerState<SpielanfrageNeuScreen> createState() => _SpielanfrageNeuScreenState();
}

class _SpielanfrageNeuScreenState extends ConsumerState<SpielanfrageNeuScreen> {
  String? _myChildId;
  Child? _targetChild;
  final _slots = <(TextEditingController date, TextEditingController time)>[];
  final _locationCtrl = TextEditingController(text: 'Spielplatz Nierster Straße');
  final _messageCtrl = TextEditingController(text: 'Hallo! Passt einer der Termine bei euch?');
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _slots.add((TextEditingController(), TextEditingController()));
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    _messageCtrl.dispose();
    for (final s in _slots) {
      s.$1.dispose();
      s.$2.dispose();
    }
    super.dispose();
  }

  Future<void> _send() async {
    final profile = ref.read(profileProvider).valueOrNull;
    final myChildId = _myChildId;
    final target = _targetChild;
    if (profile?.familyId == null || myChildId == null || target == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bitte Kind und Familie auswählen.')));
      return;
    }
    final slots = _slots
        .where((s) => s.$1.text.trim().isNotEmpty)
        .map((s) => PlaydateSlot(date: s.$1.text.trim(), timeRange: s.$2.text.trim(), location: _locationCtrl.text.trim()))
        .toList();
    if (slots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bitte mindestens einen Termin vorschlagen.')));
      return;
    }
    setState(() => _sending = true);
    try {
      final toUid = await ref.read(kitaServiceProvider).fetchPrimaryFamilyMemberUid(target.familyId);
      if (toUid == null) throw Exception('Für diese Familie ist noch kein Elternteil registriert.');
      await ref.read(playdatesServiceProvider).createRequest(
            fromUid: profile!.id,
            fromFamilyId: profile.familyId!,
            fromChildId: myChildId,
            toFamilyId: target.familyId,
            toChildId: target.id,
            toUid: toUid,
            proposedSlots: slots,
            message: _messageCtrl.text.trim(),
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
    final myChildrenAsync = ref.watch(myChildrenProvider);
    final myFamilyId = ref.watch(profileProvider).valueOrNull?.familyId;
    final familiesAsync = ref.watch(allFamiliesProvider);

    return Scaffold(
      appBar: const NHeader(title: 'Neue Spielanfrage', subtitle: 'Termine vorschlagen', showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          const Text('Wer möchte spielen?', style: TextStyle(fontSize: 12, color: AppColors.neutral400)),
          const SizedBox(height: 6),
          myChildrenAsync.when(
            loading: () => const SizedBox(),
            error: (e, _) => Text('Fehler: $e'),
            data: (myChildren) => Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final c in myChildren)
                  _ChoiceChip(
                    label: '${c.name} · ${groupName(c.groupId)}',
                    selected: _myChildId == c.id,
                    onTap: () => setState(() => _myChildId = c.id),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text('Anfrage an', style: TextStyle(fontSize: 12, color: AppColors.neutral400)),
          const SizedBox(height: 6),
          if (myFamilyId != null)
            FutureBuilder<List<Child>>(
              future: ref.read(kitaServiceProvider).fetchOtherChildren(myFamilyId),
              builder: (context, snap) {
                final others = snap.data ?? [];
                final families = familiesAsync.valueOrNull ?? {};
                if (_targetChild == null && widget.preselectedChildId != null) {
                  final match = others.where((c) => c.id == widget.preselectedChildId).firstOrNull;
                  if (match != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _targetChild = match);
                    });
                  }
                }
                return Column(
                  children: [
                    for (final c in others)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: NCard(
                          borderColor: _targetChild?.id == c.id ? AppColors.accent : null,
                          onTap: () => setState(() => _targetChild = c),
                          child: Row(
                            children: [
                              Container(width: 28, height: 28, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.neutral800)),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(c.name, style: const TextStyle(fontSize: 13, color: AppColors.text)),
                                    Text('Gruppe ${groupName(c.groupId)} · ${families[c.familyId]?.name ?? ''}',
                                        style: const TextStyle(fontSize: 10.5, color: AppColors.neutral500)),
                                  ],
                                ),
                              ),
                              if (_targetChild?.id == c.id) const Icon(Icons.check_rounded, size: 16, color: AppColors.accent),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          const SizedBox(height: 14),
          const Text('Terminvorschläge', style: TextStyle(fontSize: 12, color: AppColors.neutral400)),
          const SizedBox(height: 6),
          for (var i = 0; i < _slots.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  Expanded(child: NInput(controller: _slots[i].$1, hintText: 'z.B. Do 11.09.')),
                  const SizedBox(width: 6),
                  Expanded(child: NInput(controller: _slots[i].$2, hintText: '15:00–17:00')),
                ],
              ),
            ),
          NButton(
            label: 'Termin hinzufügen',
            variant: NButtonVariant.secondary,
            small: true,
            icon: const Icon(Icons.add_rounded),
            onPressed: () => setState(() => _slots.add((TextEditingController(), TextEditingController()))),
          ),
          const SizedBox(height: 12),
          NField(label: 'Ort', controller: _locationCtrl),
          const SizedBox(height: 10),
          NField(label: 'Nachricht (optional)', controller: _messageCtrl, minLines: 3, maxLines: 5),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: NButton(label: 'Abbrechen', variant: NButtonVariant.secondary, onPressed: () => Navigator.of(context).maybePop())),
              const SizedBox(width: 7),
              Expanded(flex: 2, child: NButton(label: 'Anfrage senden', variant: NButtonVariant.primary, loading: _sending, onPressed: _send)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Die Familie sieht nur deinen Vornamen und die Gruppe deines Kindes.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5, color: AppColors.neutral500)),
        ],
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(border: Border.all(color: selected ? AppColors.accent : AppColors.divider), borderRadius: BorderRadius.circular(AppRadius.md)),
        child: Text(label, style: TextStyle(fontSize: 13, color: selected ? AppColors.accent : AppColors.text)),
      ),
    );
  }
}
