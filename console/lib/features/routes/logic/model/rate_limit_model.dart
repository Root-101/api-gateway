///rate limit add-on of a route or of the whole gateway: past [limit] requests per [period] per
///client IP, a 429. The api answers exactly what was saved (no read-only fields)
class RateLimitModel {
  static const List<String> periods = ['second', 'minute', 'hour'];

  final bool enabled;
  final int limit;

  ///`second`, `minute` or `hour`
  final String period;

  ///the most requests at once; null = [limit]
  final int? burst;

  RateLimitModel({
    required this.enabled,
    required this.limit,
    required this.period,
    this.burst,
  });

  RateLimitModel copyWith({bool? enabled}) => RateLimitModel(
    enabled: enabled ?? this.enabled,
    limit: limit,
    period: period,
    burst: burst,
  );
}

///"100/min", "20/s", "5000/h"
String rateShort(RateLimitModel rate) =>
    '${rate.limit}/${switch (rate.period) {
      'second' => 's',
      'hour' => 'h',
      _ => 'min',
    }}';
