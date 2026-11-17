///maintenance add-on of the whole gateway or of one route; `null` (not configured) is not the same as off:
///turning it off keeps [message] and [retryAfter] for next time, and it never ends by itself
class MaintenanceModel {
  ///the most the gateway accepts in [message]
  static const int maxMessage = 500;

  final bool enabled;
  final String? message;
  final DateTime? retryAfter;

  ///what callers get when [message] is empty, in the console's language (read-only)
  final String? defaultMessage;

  ///last time it really turned on / off (read-only, written by the gateway)
  final DateTime? enabledAt;
  final DateTime? disabledAt;

  MaintenanceModel({
    required this.enabled,
    this.message,
    this.retryAfter,
    this.defaultMessage,
    this.enabledAt,
    this.disabledAt,
  });

  MaintenanceModel copyWith({bool? enabled}) => MaintenanceModel(
    enabled: enabled ?? this.enabled,
    message: message,
    retryAfter: retryAfter,
    defaultMessage: defaultMessage,
    enabledAt: enabledAt,
    disabledAt: disabledAt,
  );

  ///what callers get: the admin's message or the gateway's default ([fallback] before it exists)
  String shownMessage(String fallback) {
    final own = message?.trim() ?? '';
    if (own.isNotEmpty) return own;
    return defaultMessage ?? fallback;
  }

  bool get hasOwnMessage => (message?.trim() ?? '').isNotEmpty;

  ///how long it has been on, while on
  Duration? get onFor => enabled && enabledAt != null
      ? DateTime.now().difference(enabledAt!)
      : null;

  ///the last window, while off: from turning on to turning off
  Duration? get lastWindow =>
      !enabled &&
          enabledAt != null &&
          disabledAt != null &&
          disabledAt!.isAfter(enabledAt!)
      ? disabledAt!.difference(enabledAt!)
      : null;

  ///the Retry-After the gateway sends now: 0 (no header) without a time or once it passed
  int get retrySeconds => retrySecondsOf(retryAfter);

  static int retrySecondsOf(DateTime? retryAfter) {
    if (retryAfter == null) return 0;
    final seconds =
        (retryAfter.difference(DateTime.now()).inMilliseconds / 1000).round();
    return seconds > 0 ? seconds : 0;
  }
}

///"3 d 4 h", "2 h 5 min", "40 min": how long until a maintenance's return time, or how long it lasted
String durationText(int seconds) {
  final d = seconds ~/ 86400;
  if (d > 0) {
    final dh = (seconds % 86400) ~/ 3600;
    return dh == 0 ? '$d d' : '$d d $dh h';
  }
  final h = seconds ~/ 3600;
  final m = ((seconds % 3600) / 60).round();
  if (h == 0) return '${m < 1 ? 1 : m} min';
  return m == 0 ? '$h h' : '$h h $m min';
}
