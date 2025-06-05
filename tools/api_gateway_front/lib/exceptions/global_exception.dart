enum GlobalExceptionType { general, auth, validation }

class GlobalException<T> implements Exception {
  final GlobalExceptionType type;
  final String message;
  final T? data;

  GlobalException({required this.type, required this.message, this.data});

  @override
  String toString() {
    return 'GlobalException{=type: $type, message: $message, data: $data}';
  }
}
