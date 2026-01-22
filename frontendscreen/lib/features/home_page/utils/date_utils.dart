class DateUtilsCustom {
  static String getDayName(DateTime date) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  static DateTime getLastSunday(DateTime date) {
    final dayOfWeek = date.weekday;
    final daysSinceSunday = dayOfWeek % 7;
    final sundayDate = date.subtract(Duration(days: daysSinceSunday));
    return DateTime(sundayDate.year, sundayDate.month, sundayDate.day);
  }

  static bool isSameWeek(DateTime date1, DateTime date2) {
    final sunday1 = getLastSunday(date1);
    final sunday2 = getLastSunday(date2);
    return sunday1.isAtSameMomentAs(sunday2);
  }
}
