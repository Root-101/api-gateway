class CredentialsModel {
  String username;
  String password;

  CredentialsModel({required this.username, required this.password});

  @override
  String toString() {
    return 'CredentialsModel{username: $username, password: $password}';
  }
}
