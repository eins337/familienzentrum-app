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

/// ISO-8601 week number (Kalenderwoche), matching the "KW 38" labels used
/// for the Speiseplan and Wochenrückblick.
int isoWeekNumber(DateTime date) {
  final d = DateTime.utc(date.year, date.month, date.day);
  final thursday = d.add(Duration(days: 3 - ((d.weekday + 6) % 7)));
  final firstThursday = DateTime.utc(thursday.year, 1, 4);
  final firstThursdayWeekStart = firstThursday.subtract(Duration(days: (firstThursday.weekday + 6) % 7));
  return (thursday.difference(firstThursdayWeekStart).inDays / 7).floor() + 1;
}

/// The Sunday-20:00 cutoff after which a Wochenrückblick posted in [postedAt]'s
/// ISO week is considered expired.
bool isWochenrueckblickExpired(DateTime postedAt) {
  final weekday = postedAt.weekday; // Monday = 1 ... Sunday = 7
  final sundayOfWeek = DateTime(postedAt.year, postedAt.month, postedAt.day).add(Duration(days: 7 - weekday));
  final cutoff = DateTime(sundayOfWeek.year, sundayOfWeek.month, sundayOfWeek.day, 20);
  return DateTime.now().isAfter(cutoff);
}
