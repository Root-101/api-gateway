///health check add-on of a route: the gateway calls [path] on the route's service every
///[intervalSeconds] while [enabled] and keeps the last result. It never changes the routing
class HealthCheckModel {
  ///the choices of the editor (the api takes any value from 10 to 3600)
  static const List<int> intervals = [10, 30, 60, 300, 900, 3600];

  final bool enabled;
  final String path;
  final int intervalSeconds;

  ///last result (read-only, written by the gateway): all null until the first call
  final DateTime? checkedAt;

  ///answered a 2xx
  final bool? up;

  ///null = no answer (unreachable, or nothing in 5 s)
  final int? status;
  final int? millis;

  HealthCheckModel({
    required this.enabled,
    required this.path,
    required this.intervalSeconds,
    this.checkedAt,
    this.up,
    this.status,
    this.millis,
  });

  bool get live => enabled && up == true;

  bool get down => enabled && up == false;
}

///"30 s", "5 min", "1 h"
String intervalText(int seconds) => seconds % 3600 == 0
    ? '${seconds ~/ 3600} h'
    : seconds % 60 == 0
    ? '${seconds ~/ 60} min'
    : '$seconds s';
