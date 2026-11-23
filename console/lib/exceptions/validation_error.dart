/// One item of `errors` in a 422 problem json: `{pointer, code, detail, params}`
class ValidationError {
  /// The field, the `pointer` without `#/`: `name`, `rewrite_path/replace_from`, `allowed_origins/1`, `0/name`
  final String source;

  /// Stable code of the broken rule: `not-blank`, `size`, `route.invalid-path`...
  final String code;

  /// The problem, in the request's language
  final String message;

  ValidationError({
    required this.source,
    required this.code,
    required this.message,
  });

  factory ValidationError.fromJson(Map<String, dynamic> json) =>
      ValidationError(
        source: '${json['pointer'] ?? ''}'.replaceFirst('#/', ''),
        code: '${json['code'] ?? ''}',
        message: '${json['detail'] ?? ''}',
      );

  @override
  String toString() {
    return 'ValidationError{source: $source, code: $code, message: $message}';
  }
}

extension ValidationErrorConverter on List<ValidationError> {
  /// By field; the gateway sends a field's errors in a fixed order (not-blank first): the first one wins
  Map<String, String> asFailedValidations() {
    final result = <String, String>{};
    for (final e in this) {
      result.putIfAbsent(e.source, () => e.message);
    }
    return result;
  }
}
