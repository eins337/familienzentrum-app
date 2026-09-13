import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../../utils/time_format.dart';
import '../../widgets/widgets.dart';

class PostCreateScreen extends ConsumerStatefulWidget {
  const PostCreateScreen({super.key, this.preselectedGroupId, this.preselectedKind});
  final String? preselectedGroupId;
  final String? preselectedKind;

  @override
  ConsumerState<PostCreateScreen> createState() => _PostCreateScreenState();
}

class _PostCreateScreenState extends ConsumerState<PostCreateScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  late String _kind;
  String _visibility = 'all';
  String? _selectedGroupId;
  DateTime? _eventDate;
  final _eventLocationCtrl = TextEditingController();
  PlatformFile? _attachedFile;
  PlatformFile? _speiseplanFile;
  late int _speiseplanKw;
  final List<XFile> _photos = [];
  final List<TextEditingController> _pollOptions = [TextEditingController(), TextEditingController()];
  bool _publishing = false;
  late int _currentKw;

  @override
  void initState() {
    super.initState();
    _kind = widget.preselectedKind ?? 'foto';
    _currentKw = isoWeekNumber(DateTime.now());
    _speiseplanKw = _currentKw;
    if (widget.preselectedGroupId != null) {
      _visibility = 'group';
      _selectedGroupId = widget.preselectedGroupId;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _eventLocationCtrl.dispose();
    for (final c in _pollOptions) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final picked = await ImagePicker().pickMultiImage(limit: 4);
    if (picked.isNotEmpty) setState(() => _photos.addAll(picked));
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null && result.files.isNotEmpty) {
      setState(() => _attachedFile = result.files.first);
    }
  }

  Future<void> _pickSpeiseplanFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true, type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.isNotEmpty) {
      setState(() => _speiseplanFile = result.files.first);
    }
  }

  Future<void> _publishSpeiseplan(String authorId) async {
    final file = _speiseplanFile!;
    final path = '$authorId/${DateTime.now().microsecondsSinceEpoch}_${file.name}';
    await supa.storage.from('documents').uploadBinary(path, file.bytes!);
    final fileUrl = await supa.storage.from('documents').createSignedUrl(path, 60 * 60 * 24 * 365 * 5);
    await ref.read(kitaServiceProvider).publishSpeiseplan(fileUrl: fileUrl, fileName: file.name, kw: _speiseplanKw);
    await ref.read(adminServiceProvider).createDocument(title: 'Speiseplan KW $_speiseplanKw', fileUrl: fileUrl, sizeLabel: file.size > 0 ? '${(file.size / 1024).round()} KB' : null);
  }

  Future<void> _publish() async {
    final profile = ref.read(profileProvider).valueOrNull;
    if (profile == null) return;
    setState(() => _publishing = true);
    try {
      if (_kind == 'speiseplan') {
        await _publishSpeiseplan(profile.id);
        if (mounted) Navigator.of(context).maybePop();
        return;
      }

      String? fileUrl;
      String? fileName;
      String? fileSizeLabel;
      if (_kind == 'info' && _attachedFile?.bytes != null) {
        final file = _attachedFile!;
        final path = '${profile.id}/${DateTime.now().microsecondsSinceEpoch}_${file.name}';
        await supa.storage.from('documents').uploadBinary(path, file.bytes!);
        fileUrl = await supa.storage.from('documents').createSignedUrl(path, 60 * 60 * 24 * 365 * 5);
        fileName = file.name;
        fileSizeLabel = file.size > 0 ? '${(file.size / 1024).round()} KB' : null;
      }

      final photoUrls = <String>[];
      for (final photo in _photos) {
        final bytes = await photo.readAsBytes();
        final path = '${profile.id}/${DateTime.now().microsecondsSinceEpoch}_${photo.name}';
        await supa.storage.from('post-photos').uploadBinary(path, bytes);
        // The bucket is private (RLS-gated to signed-in users), so a plain
        // getPublicUrl() would 403 — this was actually broken until caught
        // in an audit pass. A long-lived signed URL is the practical
        // middle ground: not publicly discoverable, but doesn't need
        // regenerating on every fetch for a small Kita's worth of traffic.
        final signedUrl = await supa.storage.from('post-photos').createSignedUrl(path, 60 * 60 * 24 * 365 * 5);
        photoUrls.add(signedUrl);
      }

      PostPoll? poll;
      if (_kind == 'umfrage') {
        final labels = _pollOptions.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
        if (labels.isNotEmpty) poll = PostPoll(options: labels.map((l) => PostPollOption(label: l)).toList());
      }

      final isWochenrueckblick = _kind == 'wochenrueckblick';
      await ref.read(postsServiceProvider).createPost(
            authorId: profile.id,
            groupId: (isWochenrueckblick || _visibility == 'group') ? _selectedGroupId : null,
            kind: _kind,
            visibility: isWochenrueckblick ? 'group' : (_visibility == 'group' ? 'group' : _visibility),
            title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
            body: _bodyCtrl.text.trim(),
            photoUrls: photoUrls,
            fileName: fileName,
            fileSizeLabel: fileSizeLabel,
            fileUrl: fileUrl,
            eventDate: _kind == 'termin' ? _eventDate : null,
            eventLocation: _kind == 'termin' && _eventLocationCtrl.text.trim().isNotEmpty ? _eventLocationCtrl.text.trim() : null,
            initialPoll: poll,
          );
      if (mounted) Navigator.of(context).maybePop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e')));
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  bool get _canPublish {
    if (_kind == 'speiseplan') return _speiseplanFile != null;
    if (_kind == 'wochenrueckblick') return _selectedGroupId != null;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final myGroups = profile?.groupIds ?? const [];
    final isWochenrueckblick = _kind == 'wochenrueckblick';
    final isSpeiseplan = _kind == 'speiseplan';

    return Scaffold(
      appBar: const NHeader(title: 'Beitrag erstellen', subtitle: 'Kita-Team', showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          if (!isSpeiseplan) ...[
            NField(label: 'Titel', controller: _titleCtrl, hintText: 'z.B. Unser Waldtag'),
            const SizedBox(height: 10),
            NField(label: 'Text', controller: _bodyCtrl, hintText: 'Schreib den Eltern, was heute los war …', minLines: 4, maxLines: 8),
            const SizedBox(height: 10),
          ],
          const Text('Art des Beitrags', style: TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 5),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _KindChip(label: 'Foto-Beitrag', selected: _kind == 'foto', onTap: () => setState(() => _kind = 'foto')),
              _KindChip(label: 'Info / Elternbrief', selected: _kind == 'info', onTap: () => setState(() => _kind = 'info')),
              _KindChip(label: 'Termin', selected: _kind == 'termin', onTap: () => setState(() => _kind = 'termin')),
              _KindChip(label: 'Umfrage', selected: _kind == 'umfrage', onTap: () => setState(() => _kind = 'umfrage')),
              _KindChip(label: 'Speiseplan (PDF)', selected: _kind == 'speiseplan', onTap: () => setState(() => _kind = 'speiseplan')),
              _KindChip(label: 'Wochenrückblick', selected: _kind == 'wochenrueckblick', onTap: () => setState(() => _kind = 'wochenrueckblick')),
            ],
          ),
          if (isWochenrueckblick) ...[
            const SizedBox(height: 12),
            const Text('Gruppe', style: TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.input)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final g in myGroups)
                    NRadioRow(
                      label: 'Gruppe ${g[0].toUpperCase()}${g.substring(1)}',
                      selected: _selectedGroupId == g,
                      onTap: () => setState(() => _selectedGroupId = g),
                    ),
                ],
              ),
            ),
          ] else if (!isSpeiseplan) ...[
            const SizedBox(height: 12),
            const Text('Sichtbar für', style: TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.input)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NRadioRow(label: 'Alle Familien', selected: _visibility == 'all', onTap: () => setState(() => _visibility = 'all')),
                  for (final g in myGroups)
                    NRadioRow(
                      label: 'Nur Gruppe ${g[0].toUpperCase()}${g.substring(1)}',
                      selected: _visibility == 'group' && _selectedGroupId == g,
                      onTap: () => setState(() {
                        _visibility = 'group';
                        _selectedGroupId = g;
                      }),
                    ),
                  NRadioRow(label: 'Nur Elternbeirat', selected: _visibility == 'beirat', onTap: () => setState(() => _visibility = 'beirat')),
                ],
              ),
            ),
          ],
          if (isSpeiseplan) ...[
            const SizedBox(height: 12),
            const Text('Kalenderwoche', style: TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 5),
            Row(
              children: [
                _KindChip(label: 'KW $_currentKw', selected: _speiseplanKw == _currentKw, onTap: () => setState(() => _speiseplanKw = _currentKw)),
                const SizedBox(width: 6),
                _KindChip(label: 'KW ${_currentKw + 1}', selected: _speiseplanKw == _currentKw + 1, onTap: () => setState(() => _speiseplanKw = _currentKw + 1)),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Datei', style: TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 5),
            InkWell(
              onTap: _pickSpeiseplanFile,
              borderRadius: BorderRadius.circular(AppRadius.input),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  border: Border.all(color: _speiseplanFile == null ? AppColors.border : AppColors.success, strokeAlign: BorderSide.strokeAlignInside),
                ),
                child: _speiseplanFile == null
                    ? const Column(
                        children: [
                          Icon(Icons.upload_file_rounded, color: AppColors.mutedAlt, size: 22),
                          SizedBox(height: 6),
                          Text('PDF auswählen', style: TextStyle(fontSize: 12.5, color: AppColors.muted)),
                        ],
                      )
                    : Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_speiseplanFile!.name, style: const TextStyle(fontSize: 13, color: AppColors.ink), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Erscheint im Feed, ersetzt den alten Plan und wird automatisch unter Infos → Dokumente abgelegt.',
              style: TextStyle(fontSize: 11, color: AppColors.muted, height: 1.4),
            ),
          ],
          if (_kind == 'info') ...[
            const SizedBox(height: 12),
            const Text('Anhang (optional)', style: TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 5),
            NButton(
              label: _attachedFile?.name ?? 'Datei anhängen',
              variant: NButtonVariant.secondary,
              small: true,
              icon: const Icon(Icons.attach_file_rounded),
              onPressed: _pickFile,
            ),
          ],
          if (_kind == 'foto' || isWochenrueckblick) ...[
            const SizedBox(height: 12),
            Text(isWochenrueckblick ? 'Fotos der Woche' : 'Fotos', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 5),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 7,
              crossAxisSpacing: 7,
              children: [
                for (final p in _photos)
                  ClipRRect(borderRadius: BorderRadius.circular(12), child: kIsWebSafeImage(p)),
                InkWell(
                  onTap: _pickPhotos,
                  child: Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                    child: const Icon(Icons.add_rounded, color: AppColors.mutedAlt),
                  ),
                ),
              ],
            ),
            if (_kind == 'foto' && _visibility == 'group' && _selectedGroupId != null) _ConsentWarning(groupId: _selectedGroupId!),
            if (isWochenrueckblick) ...[
              const SizedBox(height: 8),
              const Text('Der Wochenrückblick läuft bis Sonntag 20:00 und wird dann durch den nächsten ersetzt.', style: TextStyle(fontSize: 11, color: AppColors.muted, height: 1.4)),
            ],
          ],
          if (_kind == 'termin') ...[
            const SizedBox(height: 12),
            const Text('Termin', style: TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 5),
            NButton(
              label: _eventDate == null ? 'Datum & Uhrzeit wählen' : '${_eventDate!.day.toString().padLeft(2, '0')}.${_eventDate!.month.toString().padLeft(2, '0')}.${_eventDate!.year} · ${_eventDate!.hour.toString().padLeft(2, '0')}:${_eventDate!.minute.toString().padLeft(2, '0')}',
              variant: NButtonVariant.secondary,
              small: true,
              onPressed: () async {
                final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100));
                if (date == null || !context.mounted) return;
                final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                if (time == null) return;
                setState(() => _eventDate = DateTime(date.year, date.month, date.day, time.hour, time.minute));
              },
            ),
            const SizedBox(height: 8),
            NField(label: 'Ort (optional)', controller: _eventLocationCtrl, hintText: 'z.B. Innenhof'),
          ],
          if (_kind == 'umfrage') ...[
            const SizedBox(height: 12),
            const Text('Antwortoptionen', style: TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 5),
            for (var i = 0; i < _pollOptions.length; i++) ...[
              NInput(controller: _pollOptions[i], hintText: 'Option ${i + 1}'),
              const SizedBox(height: 6),
            ],
            NButton(
              label: 'Option hinzufügen',
              variant: NButtonVariant.secondary,
              small: true,
              icon: const Icon(Icons.add_rounded),
              onPressed: () => setState(() => _pollOptions.add(TextEditingController())),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: NButton(label: 'Verwerfen', variant: NButtonVariant.secondary, onPressed: () => Navigator.of(context).maybePop())),
              const SizedBox(width: 7),
              Expanded(
                flex: 2,
                child: NButton(label: 'Veröffentlichen', variant: NButtonVariant.primary, loading: _publishing, onPressed: _canPublish ? _publish : null),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConsentWarning extends ConsumerWidget {
  const _ConsentWarning({required this.groupId});
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = ref.watch(childrenInGroupProvider(groupId)).valueOrNull ?? [];
    final withoutConsent = children.where((c) => !c.photoConsentGroup).length;
    if (withoutConsent == 0) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.warningSoft, borderRadius: BorderRadius.circular(AppRadius.input)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 15, color: AppColors.warningInk),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$withoutConsent Kind${withoutConsent == 1 ? '' : 'er'} in dieser Gruppe ${withoutConsent == 1 ? 'hat' : 'haben'} keine Fotofreigabe — bitte darauf achten, wer auf den Fotos zu sehen ist.',
                style: const TextStyle(fontSize: 11.5, color: AppColors.warningInk2, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.buttonSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
          borderRadius: BorderRadius.circular(AppRadius.buttonSm),
          color: selected ? AppColors.primarySoft : null,
        ),
        child: Text(label, style: TextStyle(fontSize: 12, color: selected ? AppColors.primaryInk : AppColors.ink)),
      ),
    );
  }
}

Widget kIsWebSafeImage(XFile file) {
  return SizedBox(
    width: 78,
    height: 78,
    child: kIsWeb
        ? Image.network(file.path, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.soft))
        : Image.file(File(file.path), fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.soft)),
  );
}
