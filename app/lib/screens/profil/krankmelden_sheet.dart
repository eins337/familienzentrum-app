import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../../utils/group_colors.dart';
import '../../utils/time_format.dart';
import '../../widgets/n_button.dart';
import '../../widgets/n_field.dart';

class KrankmeldenSheet extends ConsumerStatefulWidget {
  const KrankmeldenSheet({super.key, required this.childId});
  final String childId;

  @override
  ConsumerState<KrankmeldenSheet> createState() => _KrankmeldenSheetState();
}

class _KrankmeldenSheetState extends ConsumerState<KrankmeldenSheet> {
  late final TextEditingController _dateCtrl;
  final _reasonCtrl = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _dateCtrl = TextEditingController(text: 'Heute, ${formatDateShort(DateTime.now())}');
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(Child child) async {
    final profile = ref.read(profileProvider).valueOrNull;
    if (profile?.familyId == null) return;
    setState(() => _sending = true);
    try {
      await ref.read(kitaServiceProvider).createSickReport(
            childId: child.id,
            familyId: profile!.familyId!,
            groupId: child.groupId,
            dateLabel: _dateCtrl.text.trim(),
            reason: _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final children = ref.watch(allChildrenProvider).valueOrNull ?? {};
    final child = children[widget.childId];

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.neutral700, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 14),
          Text('${child?.name.split(' ').first ?? 'Kind'} krankmelden',
              style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 17, color: AppColors.text)),
          const SizedBox(height: 4),
          Text('Das Team der Gruppe ${groupName(child?.groupId)} wird direkt informiert.',
              style: const TextStyle(fontSize: 12.5, color: AppColors.neutral400)),
          const SizedBox(height: 12),
          NField(label: 'Zeitraum', controller: _dateCtrl),
          const SizedBox(height: 10),
          NField(label: 'Grund (optional)', controller: _reasonCtrl, hintText: 'z.B. Fieber'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: NButton(label: 'Abbrechen', variant: NButtonVariant.secondary, onPressed: () => Navigator.of(context).pop())),
              const SizedBox(width: 7),
              Expanded(
                flex: 2,
                child: NButton(
                  label: 'Abmeldung senden',
                  variant: NButtonVariant.primary,
                  loading: _sending,
                  onPressed: child == null ? null : () => _submit(child),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
