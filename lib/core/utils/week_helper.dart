String getCurrentWeekKey() {
  final now = DateTime.now();

  final firstDayOfYear = DateTime(now.year, 1, 1);
  final days = now.difference(firstDayOfYear).inDays;

  final week = ((days + firstDayOfYear.weekday) / 7).ceil();

  return "${now.year}-W${week.toString().padLeft(2, '0')}";
}
