/// The player's own calendar day, `2026-10-29`: today's scores live under
/// it, so the board resets at each player's local midnight.
String localDayKey(DateTime time) {
  final day = time.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');

  return '${day.year}-${two(day.month)}-${two(day.day)}';
}

/// How long until the board resets at the next local midnight.
Duration untilMidnight(DateTime now) {
  final local = now.toLocal();
  final midnight = DateTime(local.year, local.month, local.day + 1);

  return midnight.difference(local);
}
