
class AppDateUtils {
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
  }

  static String getWeekdayName(int weekday, {bool capitalize = true}) {
    const weekdays = [
      'понедельник',
      'вторник',
      'среду',
      'четверг',
      'пятницу',
      'субботу',
      'воскресенье'
    ];
    
    final name = weekdays[weekday - 1];
    return capitalize ? name : name.toLowerCase();
  }

  static String getWeekdayNameForSchedule(int weekday, {bool capitalize = true}) {
    const weekdays = [
      'понедельник',
      'вторник',
      'среда',
      'четверг',
      'пятница',
      'суббота',
      'воскресенье'
    ];
    
    final name = weekdays[weekday - 1];
    return capitalize ? name.substring(0, 1).toUpperCase() + name.substring(1) : name;
  }

  static String getShortWeekdayName(int weekday) {
    const weekdays = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
    return weekdays[weekday - 1];
  }

  static String getWeekdayNameWithPreposition(DateTime date) {
    final weekday = date.weekday;
    return getWeekdayName(weekday, capitalize: false);
  }

  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  static String formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  static DateTime parseTime(String time) {
    final parts = time.split(':');
    return DateTime(0, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
  }
}