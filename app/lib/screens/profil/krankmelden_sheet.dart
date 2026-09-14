import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../../utils/group_colors.dart';
import '../../widgets/illustrations.dart';
import '../../widgets/n_button.dart';
import '../../widgets/n_field.dart';

class KrankmeldenSheet extends ConsumerStatefulWidget {
  const KrankmeldenSheet({super.key, required this.childId});
  final String childId;

  @override
  ConsumerState<KrankmeldenSheet> createState() => _KrankmeldenSheetState();
}

class _KrankmeldenSheetState extends ConsumerState<KrankmeldenSheet> {
  final _reasonCtrl = TextEditingController();
  DateTime? _start;
  DateTime? _end;
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _sending = false;
  String _step = 'form'; // 'form' | 'ok'

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  void _tapDay(DateTime day) {
    setState(() {
      if (_start == null || (_end != null) || day.isBefore(_start!)) {
        _start = day;
        _end = null;
      } else {
        _end = day;
      }
    });
  }

  Future<void> _submit(Child child) async {
    final profile = ref.read(profileProvider).valueOrNull;
    if (profile?.familyId == null || _start == null) return;
    setState(() => _sending = true);
    try {
      await ref.read(kitaServiceProvider).createSickReport(
            childId: child.id,
            familyId: profile!.familyId!,
            groupId: child.groupId,
            startDate: _start!,
            endDate: _end ?? _start!,
            reason: _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
          );
      if (mounted) setState(() => _step = 'ok');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String get _rangeLabel {
    if (_start == null) return 'Noch kein Tag gewählt';
    const weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    String fmt(DateTime d) => '${weekdays[d.weekday - 1]} ${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.';
    if (_end == null || _end!.isAtSameMomentAs(_start!)) return fmt(_start!);
    final days = _end!.difference(_start!).inDays + 1;
    return '${fmt(_start!)} – ${fmt(_end!)} · $days Tage';
  }

  @override
  Widget build(BuildContext context) {
    final children = ref.watch(allChildrenProvider).valueOrNull ?? {};
    final child = children[widget.childId];
    final firstName = child?.name.split(' ').first ?? 'Kind';

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 14),
            if (_step == 'form') ..._buildForm(child, firstName) else ..._buildSuccess(child, firstName),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildForm(Child? child, String firstName) {
    return [
      Text('$firstName krankmelden', style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 17, color: AppColors.ink)),
      const SizedBox(height: 4),
      Text('Das Team der Gruppe ${groupName(child?.groupId)} wird direkt informiert.', style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
      const SizedBox(height: 14),
      _MonthCalendar(
        month: _visibleMonth,
        start: _start,
        end: _end,
        onPrevMonth: () => setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1)),
        onNextMonth: () => setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1)),
        onTapDay: _tapDay,
      ),
      const SizedBox(height: 8),
      Text(_rangeLabel, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _start == null ? AppColors.muted : AppColors.primaryInk)),
      const SizedBox(height: 12),
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
              onPressed: (child == null || _start == null) ? null : () => _submit(child),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildSuccess(Child? child, String firstName) {
    return [
      Center(child: const SleepingChildIllustration()),
      const SizedBox(height: 14),
      const Text('Abmeldung gesendet', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 17, color: AppColors.ink)),
      const SizedBox(height: 6),
      Text.rich(
        TextSpan(
          style: const TextStyle(fontSize: 13, color: AppColors.ink2, height: 1.5),
          children: [
            TextSpan(text: '$firstName ist für '),
            TextSpan(text: _rangeLabel, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
            const TextSpan(text: ' krankgemeldet. Das Team der Gruppe '),
            TextSpan(text: groupName(child?.groupId), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
            const TextSpan(text: ' wurde informiert.'),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.successSoft, borderRadius: BorderRadius.circular(AppRadius.input)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.successInk),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Den Status siehst du jederzeit in deinem Profil — dort kannst du die Meldung auch zurücknehmen.',
                  style: TextStyle(fontSize: 12, color: AppColors.successInk2, height: 1.4)),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      NButton(label: 'Fertig', variant: NButtonVariant.primary, block: true, onPressed: () => Navigator.of(context).pop()),
    ];
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.month,
    required this.start,
    required this.end,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onTapDay,
  });

  final DateTime month;
  final DateTime? start;
  final DateTime? end;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onTapDay;

  static const _monthNames = [
    'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'
  ];

  bool _inRange(DateTime d) {
    if (start == null) return false;
    final e = end ?? start!;
    return !d.isBefore(start!) && !d.isAfter(e);
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = firstOfMonth.weekday - 1; // Monday-first
    final cells = <Widget>[];

    for (var i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
      final isStart = start != null && date.isAtSameMomentAs(start!);
      final isEnd = (end ?? start) != null && date.isAtSameMomentAs(end ?? start!);
      final inRange = _inRange(date);
      final isEdge = isStart || isEnd;

      cells.add(
        GestureDetector(
          onTap: () => onTapDay(date),
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isEdge ? AppColors.primary : (inRange ? AppColors.primarySoft : Colors.transparent),
              borderRadius: BorderRadius.circular(12),
              border: isToday && !isEdge ? Border.all(color: AppColors.primary, width: 1) : null,
            ),
            child: Text(
              '$day',
              style: AppText.nunito(size: 13, weight: FontWeight.w600, color: isEdge ? AppColors.surface : AppColors.ink),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(onPressed: onPrevMonth, icon: const Icon(Icons.chevron_left_rounded, color: AppColors.ink2)),
            Expanded(
              child: Text(
                '${_monthNames[month.month - 1]} ${month.year}',
                textAlign: TextAlign.center,
                style: AppText.outfit(size: 14, weight: FontWeight.w600, color: AppColors.ink),
              ),
            ),
            IconButton(onPressed: onNextMonth, icon: const Icon(Icons.chevron_right_rounded, color: AppColors.ink2)),
          ],
        ),
        Row(
          children: [for (final w in ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So']) Expanded(child: Center(child: Text(w, style: AppText.nunito(size: 10.5, weight: FontWeight.w700, color: AppColors.muted))))],
        ),
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: cells,
        ),
      ],
    );
  }
}
