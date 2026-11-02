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
        //invalid_value can be null or a non-string (number, bool...)
        source: json['source']?.toString() ?? '',
        invalidValue: json['invalid_value']?.toString() ?? '',
        message: json['message']?.toString() ?? '',
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
