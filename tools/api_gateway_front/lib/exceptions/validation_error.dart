class ValidationError {
  final String source;
  final String invalidValue;
  final String message;

  ValidationError({
    required this.source,
    required this.invalidValue,
    required this.message,
  });

  factory ValidationError.fromJson(Map<String, dynamic> json) =>
      ValidationError(
        source: json['source'],
        invalidValue: json['invalid_value'],
        message: json['message'],
      );

  @override
  String toString() {
    return 'ValidationError{source: $source, invalidValue: $invalidValue, message: $message}';
  }
}

extension ValidationErrorConverter on List<ValidationError> {
  Map<String, String> asFailedValidations() =>
      Map.fromEntries(map((e) => MapEntry(e.source, e.message)));
}
