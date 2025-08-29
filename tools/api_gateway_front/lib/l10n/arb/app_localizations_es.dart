// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get es => 'Español';

  @override
  String get en => 'Inglés';

  @override
  String get section_general => '--------- GENERAL ---------';

  @override
  String get loading => 'Cargando';

  @override
  String get noAccess => 'Usted no tiene acceso a esta funcionalidad';

  @override
  String get section_login => '--------- LOGIN ---------';

  @override
  String get usernameLabel => 'Nombre de usuario';

  @override
  String get usernameHint => 'admin';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get passwordHint => 'admin123**';

  @override
  String get login => 'Login';

  @override
  String get rememberMe => 'Recordarme';

  @override
  String get section_validations => '--------- VALIDATIONS ---------';

  @override
  String get requiredField => 'Campo requerido';

  @override
  String get section_actions => '--------- ACTIONS ---------';

  @override
  String get backup => 'Backup';

  @override
  String get restore => 'Restaurar';

  @override
  String get create => 'Crear';

  @override
  String get edit => 'Editar';

  @override
  String get duplicate => 'Duplicar';

  @override
  String get delete => 'Eliminar';

  @override
  String get tryAgain => 'Intentar nuevamente';

  @override
  String get back => 'Regresar';

  @override
  String get section_routes => '--------- ROUTES ---------';

  @override
  String get routes => 'Rutas';

  @override
  String get requestTo => 'Cualquier petición a:';

  @override
  String get redirectedTo => 'Es redirigida a:';

  @override
  String get nameLabel => 'Nombre';

  @override
  String get nameHint => 'Service-A';

  @override
  String get pathLabel => 'Path';

  @override
  String get pathHint => '/test-service/**';

  @override
  String get uriLabel => 'URI';

  @override
  String get uriHint => 'http://localhost:8080';

  @override
  String get rewritePathFromLabel => 'Reescribie Path de';

  @override
  String get rewritePathFromHint => '/some-path/';

  @override
  String get rewritePathToLabel => 'Reescribie Path a';

  @override
  String get rewritePathToHint => '/';

  @override
  String get preview => 'Previsualizar';

  @override
  String get section_logs => '--------- LOGS ---------';

  @override
  String get logs => 'Logs http';

  @override
  String get columnTimestamp => 'Timestamp';

  @override
  String get columnMethod => 'Método';

  @override
  String get columnPath => 'Path';

  @override
  String get columnRoute => 'Ruta';

  @override
  String get columnHttpStatus => 'Estado HTTP';

  @override
  String get columnRequestDuration => 'Duración';

  @override
  String get section_errors => '--------- ERRORS ---------';

  @override
  String get noData => 'No hay datos';

  @override
  String get genericError => 'Algo ha salido mal';

  @override
  String get section_restore => '--------- RESTORE ---------';

  @override
  String get selectFile => 'Select file';

  @override
  String get dropFileHere => 'Arrastre un fichero aquí';

  @override
  String get errorLoadingFile => 'Error cargando archivo';

  @override
  String get errorDecodingFile =>
      'Error decodificando el archivo (No es el archivo correcto)';
}
