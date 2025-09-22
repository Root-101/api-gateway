import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormatter _instance = DateFormatter._internal();

  DateFormatter._internal();

  factory DateFormatter() => _instance;

  ///dd/M/yy
  DateFormat get xs => DateFormat('dd/M/yy');

  ///dd/MM/yy
  DateFormat get xss => DateFormat('dd/MM/yy');

  ///dd/MM/yyyy
  DateFormat get s => DateFormat('dd/MM/yyyy');

  ///dd/MMM/yyyy
  DateFormat get m => DateFormat('dd/MMM/yyyy');

  ///yyyy-MM-dd
  DateFormat get api => DateFormat('yyyy-MM-dd');

  ///dd MMM yyyy hh:mm:ss
  DateFormat get logsTime => DateFormat('dd MMM yyyy hh:mm:ss a');

  ///dd MMM yyyy
  DateFormat get logsTimeS => DateFormat('dd MMM yyyy');
}

extension DateOnlyCompare on DateTime {
  DateTime get startOfDay => DateTime(year, month, day);

  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999, 999);

  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}
