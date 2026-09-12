import '../models/models.dart';

/// Children (from any of `groupIds`) with a birth_date whose next birthday
/// falls within `withinDays`, soonest first.
List<Child> upcomingBirthdays(Iterable<Child> children, {required Set<String?> groupIds, int withinDays = 30}) {
  final matches = children.where((c) => groupIds.contains(c.groupId) && c.daysUntilNextBirthday != null && c.daysUntilNextBirthday! <= withinDays).toList();
  matches.sort((a, b) => a.daysUntilNextBirthday!.compareTo(b.daysUntilNextBirthday!));
  return matches;
}
