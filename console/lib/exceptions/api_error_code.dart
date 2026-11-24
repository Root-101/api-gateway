/// The stable `code`s of the gateway's errors ([GlobalException.errorCode], [ValidationError.code] in a 422) that a
/// view decides on. The same in every language: compare the code, never the text. The full list is in
/// `docs/api.md`, "Error codes"
class ApiErrorCode {
  ApiErrorCode._();

  /// 401 of the login: the user or the password is wrong
  static const String wrongCredentials = 'auth.wrong-credentials';
}
