import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import '../../models/models.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../../utils/group_colors.dart';
import '../../widgets/n_button.dart';
import '../../widgets/n_card.dart';
import '../../widgets/n_header.dart';

class AdminFamiliesScreen extends ConsumerStatefulWidget {
  const AdminFamiliesScreen({super.key});
  @override
  ConsumerState<AdminFamiliesScreen> createState() => _AdminFamiliesScreenState();
}

class _AdminFamiliesScreenState extends ConsumerState<AdminFamiliesScreen> {
  String? _expandedFamilyId;

  Future<void> _createFamily() async {
    final name = await _promptText(context, title: 'Neue Familie', hint: 'Familie Mustermann');
    if (name != null && name.trim().isNotEmpty) {
      await ref.read(adminServiceProvider).createFamily(name.trim());
    }
  }

  Future<void> _renameFamily(Family f) async {
    final name = await _promptText(context, title: 'Familie umbenennen', hint: f.name, initial: f.name);
    if (name != null && name.trim().isNotEmpty) {
      await ref.read(adminServiceProvider).updateFamilyName(f.id, name.trim());
    }
  }

  Future<void> _addChild(String familyId) async {
    final name = await _promptText(context, title: 'Neues Kind', hint: 'Vorname Nachname');
    if (name == null || name.trim().isEmpty) return;
    final groups = await ref.read(groupsProvider.future);
    if (!mounted) return;
    final groupId = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Gruppe wählen', style: TextStyle(color: AppColors.text)),
        children: [
          for (final g in groups)
            SimpleDialogOption(onPressed: () => Navigator.pop(context, g.id), child: Text('Gruppe ${g.name}', style: const TextStyle(color: AppColors.text))),
        ],
      ),
    );
    if (!mounted) return;
    final birthDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 4)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
      lastDate: DateTime.now(),
      helpText: 'Geburtsdatum (optional, Abbrechen zum Überspringen)',
    );
    await ref.read(adminServiceProvider).createChild(familyId: familyId, name: name.trim(), groupId: groupId, birthDate: birthDate);
  }

  Future<void> _editChild(Child child) async {
    final name = await _promptText(context, title: 'Kind bearbeiten', hint: child.name, initial: child.name);
    if (name == null || name.trim().isEmpty) return;
    final groups = await ref.read(groupsProvider.future);
    if (!mounted) return;
    final groupId = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Gruppe wählen', style: TextStyle(color: AppColors.text)),
        children: [
          for (final g in groups)
            SimpleDialogOption(onPressed: () => Navigator.pop(context, g.id), child: Text('Gruppe ${g.name}', style: const TextStyle(color: AppColors.text))),
        ],
      ),
    );
    if (!mounted) return;
    final birthDate = await showDatePicker(
      context: context,
      initialDate: child.birthDate ?? DateTime.now().subtract(const Duration(days: 365 * 4)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
      lastDate: DateTime.now(),
      helpText: 'Geburtsdatum (optional, Abbrechen zum Überspringen)',
    );
    await ref.read(adminServiceProvider).updateChildAdmin(child.id, name: name.trim(), groupId: groupId, birthDate: birthDate);
  }

  @override
  Widget build(BuildContext context) {
    final familiesAsync = ref.watch(adminServiceProvider).streamFamilies();
    final children = ref.watch(allChildrenProvider).valueOrNull ?? {};

    return Scaffold(
      appBar: const NHeader(title: 'Familien', showBack: true),
      body: StreamBuilder<List<Family>>(
        stream: familiesAsync,
        builder: (context, snap) {
          final families = snap.data ?? [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              NButton(label: 'Neue Familie', variant: NButtonVariant.primary, block: true, icon: const Icon(Icons.add_rounded), onPressed: _createFamily),
              const SizedBox(height: 10),
              for (final f in families) ...[
                _FamilyTile(
                  family: f,
                  children: children.values.where((c) => c.familyId == f.id).toList(),
                  expanded: _expandedFamilyId == f.id,
                  onToggle: () => setState(() => _expandedFamilyId = _expandedFamilyId == f.id ? null : f.id),
                  onRename: () => _renameFamily(f),
                  onDelete: () => ref.read(adminServiceProvider).deleteFamily(f.id),
                  onAddChild: () => _addChild(f.id),
                  onEditChild: _editChild,
                ),
                const SizedBox(height: 8),
              ],
            ],
          );
        },
      ),
    );
  }
}

Future<String?> _promptText(BuildContext context, {required String title, String? hint, String? initial}) {
  final ctrl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(title, style: const TextStyle(color: AppColors.text)),
      content: TextField(controller: ctrl, autofocus: true, style: const TextStyle(color: AppColors.text), decoration: InputDecoration(hintText: hint)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
        TextButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('Speichern')),
      ],
    ),
  );
}

class _FamilyTile extends ConsumerWidget {
  const _FamilyTile({
    required this.family,
    required this.children,
    required this.expanded,
    required this.onToggle,
    required this.onRename,
    required this.onDelete,
    required this.onAddChild,
    required this.onEditChild,
  });

  final Family family;
  final List<Child> children;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onAddChild;
  final ValueChanged<Child> onEditChild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            child: Row(
              children: [
                Expanded(
                  child: Text(family.name, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 15, color: AppColors.text)),
                ),
                Text('${children.length} Kinder', style: const TextStyle(fontSize: 11, color: AppColors.neutral500)),
                Icon(expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: AppColors.neutral500),
              ],
            ),
          ),
          if (expanded) ...[
            const Divider(height: 20),
            for (final c in children)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: groupColor(c.groupId))),
                    const SizedBox(width: 8),
                    Expanded(child: Text(c.name, style: const TextStyle(fontSize: 13, color: AppColors.text))),
                    Text('Gruppe ${groupName(c.groupId)}', style: const TextStyle(fontSize: 11, color: AppColors.neutral500)),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.neutral600),
                      onPressed: () => onEditChild(c),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.neutral600),
                      onPressed: () => ref.read(adminServiceProvider).deleteChild(c.id),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(child: NButton(label: 'Kind hinzufügen', variant: NButtonVariant.secondary, small: true, onPressed: onAddChild)),
                const SizedBox(width: 6),
                Expanded(child: NButton(label: 'Umbenennen', variant: NButtonVariant.secondary, small: true, onPressed: onRename)),
              ],
            ),
            const SizedBox(height: 6),
            NButton(label: 'Familie löschen', variant: NButtonVariant.ghost, small: true, onPressed: onDelete),
          ],
        ],
      ),
    );
  }
}
