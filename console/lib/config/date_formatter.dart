import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormatter _instance = DateFormatter._internal();

  DateFormatter._internal();

  factory DateFormatter() => _instance;

  //created once: the app never changes Intl.defaultLocale, and the logs grid formats every visible cell

  ///dd/M/yy
  final DateFormat xs = DateFormat('dd/M/yy');

  ///dd/MM/yy
  final DateFormat xss = DateFormat('dd/MM/yy');

  ///dd/MM/yyyy
  final DateFormat s = DateFormat('dd/MM/yyyy');

  ///dd/MMM/yyyy
  final DateFormat m = DateFormat('dd/MMM/yyyy');

  ///yyyy-MM-dd
  final DateFormat api = DateFormat('yyyy-MM-dd');

  ///dd MMM yyyy, HH:mm:ss (24 h)
  final DateFormat logsTime = DateFormat('dd MMM yyyy, HH:mm:ss');

  ///HH:mm
  final DateFormat clock = DateFormat('HH:mm');

  ///January 2026
  final DateFormat month = DateFormat('MMMM yyyy');

  ///yyyy-MM-dd_HH_mm_ss.SSS, the timestamp in the backup and export file names
  final DateFormat fileStamp = DateFormat('yyyy-MM-dd_HH_mm_ss.SSS');

  ///dd MMM yyyy
  final DateFormat logsTimeS = DateFormat('dd MMM yyyy');
}

extension DateOnlyCompare on DateTime {
  DateTime get startOfDay => DateTime(year, month, day);

  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999, 999);

  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}
