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
}

extension DateOnlyCompare on DateTime {
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}
