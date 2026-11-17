///maintenance of the whole gateway or of one route; only "on" when it exists and [enabled]:
///turning it off keeps [message] and [retryAfter] for next time, and it never ends by itself
class MaintenanceModel {
  ///the most the gateway accepts in [message]
  static const int maxMessage = 500;

  final bool enabled;
  final String? message;
  final DateTime? retryAfter;

  MaintenanceModel({required this.enabled, this.message, this.retryAfter});

  ///the Retry-After the gateway sends now: 0 (no header) without a time or once it passed
  int get retrySeconds => retrySecondsOf(retryAfter);

  static int retrySecondsOf(DateTime? retryAfter) {
    if (retryAfter == null) return 0;
    final seconds =
        (retryAfter.difference(DateTime.now()).inMilliseconds / 1000).round();
    return seconds > 0 ? seconds : 0;
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'message': message,
    'retry_after': retryAfter?.toUtc().toIso8601String(),
  };
}

///"3 d 4 h", "2 h 5 min", "40 min": how long until a maintenance's return time
String durationText(int seconds) {
  final d = seconds ~/ 86400;
  if (d > 0) {
    final dh = (seconds % 86400) ~/ 3600;
    return dh == 0 ? '$d d' : '$d d $dh h';
  }
  final h = seconds ~/ 3600;
  final m = ((seconds % 3600) / 60).round();
  if (h == 0) return '$m min';
  return m == 0 ? '$h h' : '$h h $m min';
}
