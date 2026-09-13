import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../../utils/time_format.dart';
import '../../widgets/n_button.dart';
import '../../widgets/n_card.dart';
import '../../widgets/n_field.dart';
import '../../widgets/n_header.dart';
import '../../widgets/n_segmented.dart';

class AdminContentScreen extends ConsumerStatefulWidget {
  const AdminContentScreen({super.key});
  @override
  ConsumerState<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends ConsumerState<AdminContentScreen> {
  String _tab = 'termine';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NHeader(title: 'Inhalte', showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          NSegmented<String>(
            expand: true,
            value: _tab,
            options: const [('termine', 'Termine'), ('schliesstage', 'Schließtage'), ('dokumente', 'Dokumente'), ('speiseplan', 'Speiseplan')],
            onChanged: (v) => setState(() => _tab = v),
          ),
          const SizedBox(height: 12),
          switch (_tab) {
            'termine' => const _EventsTab(),
            'schliesstage' => const _ClosuresTab(),
            'dokumente' => const _DocumentsTab(),
            _ => const _SpeiseplanTab(),
          },
        ],
      ),
    );
  }
}

class _EventsTab extends ConsumerStatefulWidget {
  const _EventsTab();
  @override
  ConsumerState<_EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends ConsumerState<_EventsTab> {
  final _titleCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  DateTime? _date;

  Future<void> _add() async {
    if (_titleCtrl.text.trim().isEmpty || _date == null) return;
    await ref.read(adminServiceProvider).createEvent(title: _titleCtrl.text.trim(), eventDate: _date!, timeLabel: _timeCtrl.text.trim(), location: _locationCtrl.text.trim());
    _titleCtrl.clear();
    _timeCtrl.clear();
    _locationCtrl.clear();
    setState(() => _date = null);
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(adminServiceProvider).streamAllEvents();
    return Column(
      children: [
        NCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NField(label: 'Titel', controller: _titleCtrl, hintText: 'z.B. Laternenfest'),
              const SizedBox(height: 8),
              NButton(
                label: _date == null ? 'Datum wählen' : formatDateLong(_date!),
                variant: NButtonVariant.secondary,
                small: true,
                onPressed: () async {
                  final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              const SizedBox(height: 8),
              Row(children: [Expanded(child: NField(label: 'Zeit', controller: _timeCtrl, hintText: '17:00')), const SizedBox(width: 8), Expanded(child: NField(label: 'Ort', controller: _locationCtrl, hintText: 'Innenhof'))]),
              const SizedBox(height: 10),
              NButton(label: 'Termin hinzufügen', variant: NButtonVariant.primary, block: true, small: true, onPressed: _add),
            ],
          ),
        ),
        const SizedBox(height: 10),
        StreamBuilder<List<KitaEvent>>(
          stream: eventsAsync,
          builder: (context, snap) {
            final events = snap.data ?? [];
            return Column(
              children: [
                for (final e in events)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _EventRsvpCard(event: e),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _EventRsvpCard extends ConsumerStatefulWidget {
  const _EventRsvpCard({required this.event});
  final KitaEvent event;

  @override
  ConsumerState<_EventRsvpCard> createState() => _EventRsvpCardState();
}

class _EventRsvpCardState extends ConsumerState<_EventRsvpCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(allProfilesProvider).valueOrNull ?? {};
    final e = widget.event;
    return NCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(e.title, style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 13.5, color: AppColors.ink)),
                    Text(formatDateLong(e.eventDate), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.muted), onPressed: () => ref.read(adminServiceProvider).deleteEvent(e.id)),
            ],
          ),
          InkWell(
            onTap: e.rsvpUids.isEmpty ? null : () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(e.rsvpUids.isEmpty ? Icons.person_off_outlined : Icons.people_outline_rounded, size: 14, color: AppColors.muted),
                  const SizedBox(width: 6),
                  Text('${e.rsvpUids.length} Zusage${e.rsvpUids.length == 1 ? '' : 'n'}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  if (e.rsvpUids.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 16, color: AppColors.muted),
                  ],
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final uid in e.rsvpUids)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(profiles[uid]?.displayName ?? uid, style: const TextStyle(fontSize: 12.5, color: AppColors.ink)),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ClosuresTab extends ConsumerStatefulWidget {
  const _ClosuresTab();
  @override
  ConsumerState<_ClosuresTab> createState() => _ClosuresTabState();
}

class _ClosuresTabState extends ConsumerState<_ClosuresTab> {
  final _titleCtrl = TextEditingController();
  DateTime? _start;
  DateTime? _end;

  Future<void> _add() async {
    if (_titleCtrl.text.trim().isEmpty || _start == null || _end == null) return;
    await ref.read(adminServiceProvider).createClosure(title: _titleCtrl.text.trim(), startDate: _start!, endDate: _end!);
    _titleCtrl.clear();
    setState(() {
      _start = null;
      _end = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final closuresAsync = ref.watch(adminServiceProvider).streamClosures();
    return Column(
      children: [
        NCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NField(label: 'Titel', controller: _titleCtrl, hintText: 'z.B. Herbstferien'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: NButton(
                      label: _start == null ? 'Start' : formatDateShort(_start!),
                      variant: NButtonVariant.secondary,
                      small: true,
                      onPressed: () async {
                        final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
                        if (picked != null) setState(() => _start = picked);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: NButton(
                      label: _end == null ? 'Ende' : formatDateShort(_end!),
                      variant: NButtonVariant.secondary,
                      small: true,
                      onPressed: () async {
                        final picked = await showDatePicker(context: context, initialDate: _start ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
                        if (picked != null) setState(() => _end = picked);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              NButton(label: 'Schließtag hinzufügen', variant: NButtonVariant.primary, block: true, small: true, onPressed: _add),
            ],
          ),
        ),
        const SizedBox(height: 10),
        StreamBuilder<List<Closure>>(
          stream: closuresAsync,
          builder: (context, snap) {
            final closures = snap.data ?? [];
            return Column(
              children: [
                for (final c in closures)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: NCard(
                      child: Row(
                        children: [
                          Expanded(child: Text(c.title, style: const TextStyle(fontSize: 13, color: AppColors.ink))),
                          Text('${formatDateShort(c.startDate)}–${formatDateShort(c.endDate)}', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                          IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.muted), onPressed: () => ref.read(adminServiceProvider).deleteClosure(c.id)),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _DocumentsTab extends ConsumerStatefulWidget {
  const _DocumentsTab();
  @override
  ConsumerState<_DocumentsTab> createState() => _DocumentsTabState();
}

class _DocumentsTabState extends ConsumerState<_DocumentsTab> {
  final _titleCtrl = TextEditingController();
  PlatformFile? _picked;
  bool _uploading = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null && result.files.isNotEmpty) {
      setState(() => _picked = result.files.first);
    }
  }

  Future<void> _add() async {
    if (_titleCtrl.text.trim().isEmpty || _picked?.bytes == null) return;
    setState(() => _uploading = true);
    try {
      final path = '${DateTime.now().microsecondsSinceEpoch}_${_picked!.name}';
      await supa.storage.from('documents').uploadBinary(path, _picked!.bytes!);
      final signedUrl = await supa.storage.from('documents').createSignedUrl(path, 60 * 60 * 24 * 365 * 5);
      final sizeLabel = _picked!.size > 0 ? '${(_picked!.size / 1024).round()} KB' : null;
      await ref.read(adminServiceProvider).createDocument(title: _titleCtrl.text.trim(), fileUrl: signedUrl, sizeLabel: sizeLabel);
      _titleCtrl.clear();
      setState(() => _picked = null);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final documentsAsync = ref.watch(adminServiceProvider).streamDocuments();
    return Column(
      children: [
        NCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NField(label: 'Titel', controller: _titleCtrl, hintText: 'z.B. Elternbrief September'),
              const SizedBox(height: 8),
              NButton(
                label: _picked?.name ?? 'Datei auswählen',
                variant: NButtonVariant.secondary,
                small: true,
                icon: const Icon(Icons.attach_file_rounded),
                onPressed: _pickFile,
              ),
              const SizedBox(height: 10),
              NButton(label: 'Dokument hochladen', variant: NButtonVariant.primary, block: true, small: true, loading: _uploading, onPressed: _add),
            ],
          ),
        ),
        const SizedBox(height: 10),
        StreamBuilder<List<DocumentItem>>(
          stream: documentsAsync,
          builder: (context, snap) {
            final docs = snap.data ?? [];
            return Column(
              children: [
                for (final d in docs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: NCard(
                      onTap: () => launchUrl(Uri.parse(d.fileUrl), mode: LaunchMode.externalApplication),
                      child: Row(
                        children: [
                          const Icon(Icons.description_outlined, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(child: Text(d.title, style: const TextStyle(fontSize: 13, color: AppColors.ink))),
                          IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.muted), onPressed: () => ref.read(adminServiceProvider).deleteDocument(d.id)),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SpeiseplanTab extends ConsumerStatefulWidget {
  const _SpeiseplanTab();
  @override
  ConsumerState<_SpeiseplanTab> createState() => _SpeiseplanTabState();
}

class _SpeiseplanTabState extends ConsumerState<_SpeiseplanTab> {
  final _days = ['Mo', 'Di', 'Mi', 'Do', 'Fr'];
  late List<TextEditingController> _ctrls;
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(_days.length, (_) => TextEditingController());
  }

  @override
  Widget build(BuildContext context) {
    final speiseplanAsync = ref.watch(speiseplanProvider);
    speiseplanAsync.whenData((sp) {
      if (!_loaded && sp != null) {
        for (var i = 0; i < _days.length && i < sp.items.length; i++) {
          _ctrls[i].text = sp.items[i].text;
        }
        _loaded = true;
      }
    });

    return NCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _days.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(width: 30, child: Text(_days[i], style: const TextStyle(fontSize: 12.5, color: AppColors.muted))),
                  Expanded(child: NInput(controller: _ctrls[i])),
                ],
              ),
            ),
          NButton(
            label: 'Speiseplan speichern',
            variant: NButtonVariant.primary,
            block: true,
            small: true,
            loading: _saving,
            onPressed: () async {
              setState(() => _saving = true);
              final items = [for (var i = 0; i < _days.length; i++) SpeiseplanItem(day: _days[i], text: _ctrls[i].text.trim())];
              await ref.read(adminServiceProvider).saveSpeiseplan(items);
              if (mounted) setState(() => _saving = false);
            },
          ),
        ],
      ),
    );
  }
}
