const _weekdaysShort = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
const _monthsShort = ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'];

/// "jetzt" / "vor 3 Std." / "vor 2 Tagen" / "Mo" / "Mo, 07.09." — matches
/// the prototype's relative-time labels.
String formatRelative(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);

  if (diff.inMinutes < 1) return 'jetzt';
  if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min.';
  if (diff.inHours < 24 && dt.day == now.day) return 'vor ${diff.inHours} Std.';
  if (diff.inDays == 1) return 'Gestern';
  if (diff.inDays < 7) return _weekdaysShort[dt.weekday - 1];
  return '${_weekdaysShort[dt.weekday - 1]}, ${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.';
}

String formatDateShort(DateTime dt) => '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.';

String formatDateLong(DateTime dt) => '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';

String monthNameShort(int month) => _monthsShort[month - 1];

String weekdayShort(int weekday) => _weekdaysShort[weekday - 1];
