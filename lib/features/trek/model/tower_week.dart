/// The ISO week [day] falls in, like `2026-W45`: the tower's weekly best
/// starts over every Monday.
String towerWeekOf(DateTime day) {
  final date = DateTime.utc(day.year, day.month, day.day);
  // The Thursday of this week decides the year it belongs to.
  final thursday = date.add(Duration(days: DateTime.thursday - date.weekday));
  final firstDay = DateTime.utc(thursday.year);
  final week = thursday.difference(firstDay).inDays ~/ 7 + 1;

  return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
}
