import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormatter _instance = DateFormatter._internal();

  DateFormatter._internal() {
    _build();
  }

  factory DateFormatter() => _instance;

  //created once per language: the logs grid formats every visible cell

  ///dd/M/yy
  late DateFormat xs;

  ///dd/MM/yy
  late DateFormat xss;

  ///dd/MM/yyyy
  late DateFormat s;

  ///dd/MMM/yyyy
  late DateFormat m;

  ///yyyy-MM-dd
  late DateFormat api;

  ///dd MMM yyyy, HH:mm:ss (24 h)
  late DateFormat logsTime;

  ///HH:mm
  late DateFormat clock;

  ///January 2026
  late DateFormat month;

  ///yyyy-MM-dd_HH_mm_ss.SSS, the timestamp in the backup and export file names
  late DateFormat fileStamp;

  ///dd MMM yyyy
  late DateFormat logsTimeS;

  ///month and day names, and number separators, follow the language of the app
  Future<void> setLocale(String languageKey) async {
    await initializeDateFormatting(languageKey);
    Intl.defaultLocale = languageKey;
    _build();
  }

  void _build() {
    xs = DateFormat('dd/M/yy');
    xss = DateFormat('dd/MM/yy');
    s = DateFormat('dd/MM/yyyy');
    m = DateFormat('dd/MMM/yyyy');
    api = DateFormat('yyyy-MM-dd', 'en');
    logsTime = DateFormat('dd MMM yyyy, HH:mm:ss');
    clock = DateFormat('HH:mm');
    month = DateFormat('MMMM yyyy');
    fileStamp = DateFormat('yyyy-MM-dd_HH_mm_ss.SSS', 'en');
    logsTimeS = DateFormat('dd MMM yyyy');
  }
}

extension DateOnlyCompare on DateTime {
  DateTime get startOfDay => DateTime(year, month, day);

  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999, 999);

  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}
