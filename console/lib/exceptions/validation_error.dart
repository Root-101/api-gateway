///one entry of `errors` in a 422 problem json
class ValidationError {
  ///JSON Pointer to the field, e.g. `#/rewrite_path/replace_from`; `#/0/name` for a list body
  final String pointer;

  ///stable code of the broken rule: `not-blank`, `size`, `route.invalid-path`...
  final String code;

  ///the problem, in the request's language
  final String message;

  ValidationError({
    required this.pointer,
    required this.code,
    required this.message,
  });

  ///the field as the forms name it: `rewrite_path.replace_from`, `allowed_origins[1]`, `[0].name`
  String get fieldName => pointer
      .replaceFirst(RegExp(r'^#/?'), '')
      .split('/')
      .where((part) => part.isNotEmpty)
      .fold(
        '',
        (path, part) => int.tryParse(part) != null
            ? '$path[$part]'
            : path.isEmpty
            ? part
            : '$path.$part',
      );

  factory ValidationError.fromJson(Map<String, dynamic> json) =>
      ValidationError(
        pointer: json['pointer']?.toString() ?? '',
        code: json['code']?.toString() ?? '',
        message: json['detail']?.toString() ?? '',
      );

  @override
  String toString() {
    return 'ValidationError{pointer: $pointer, code: $code, message: $message}';
  }
}

extension ValidationErrorConverter on List<ValidationError> {
  Map<String, String> asFailedValidations() =>
      Map.fromEntries(map((e) => MapEntry(e.fieldName, e.message)));
}
