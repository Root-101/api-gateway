///one entry of `violations` in a 422 problem json
class ValidationError {
  ///the json name of the field, e.g. `rewrite_path.replace_from`; `[0].name` for a list body
  final String fieldName;
  final String message;

  ValidationError({required this.fieldName, required this.message});

  factory ValidationError.fromJson(Map<String, dynamic> json) =>
      ValidationError(
        fieldName: json['fieldName']?.toString() ?? '',
        message: json['message']?.toString() ?? '',
      );

  @override
  String toString() {
    return 'ValidationError{fieldName: $fieldName, message: $message}';
  }
}

extension ValidationErrorConverter on List<ValidationError> {
  Map<String, String> asFailedValidations() =>
      Map.fromEntries(map((e) => MapEntry(e.fieldName, e.message)));
}
