///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import

import 'messages.g.dart';

import 'package:intl/intl.dart';
import 'package:slang/generated.dart';

// Path: <root>
class AppMessagesEs
    with BaseTranslations<AppMessagesLocale, AppMessages>
    implements AppMessages {
  /// You can call this constructor and build your own translation instance of this locale.
  /// Constructing via the enum [AppMessagesLocale.build] is preferred.
  AppMessagesEs({
    Map<String, Node>? overrides,
    PluralResolver? cardinalResolver,
    PluralResolver? ordinalResolver,
    TranslationMetadata<AppMessagesLocale, AppMessages>? meta,
  }) : assert(
         overrides == null,
         'Set "translation_overrides: true" in order to enable this feature.',
       ),
       _meta =
           meta ??
           TranslationMetadata(
             locale: AppMessagesLocale.es,
             overrides: overrides ?? {},
             cardinalResolver: cardinalResolver,
             ordinalResolver: ordinalResolver,
           ) {
    _meta.setFlatMapFunction(_flatMapFunction);
  }

  /// Metadata for the translations of <es>.
  final TranslationMetadata<AppMessagesLocale, AppMessages> _meta;
  @override
  TranslationMetadata<AppMessagesLocale, AppMessages> get $meta => _meta;

  /// Access flat map
  @override
  dynamic operator [](String key) => _meta.getTranslation(key);

  late final AppMessagesEs _root = this; // ignore: unused_field

  @override
  AppMessagesEs $copyWith({
    TranslationMetadata<AppMessagesLocale, AppMessages>? meta,
  }) => AppMessagesEs(meta: meta ?? this.$meta);

  // Translations
  @override
  late final AppMessages$app$es app = AppMessages$app$es._(_root);
  @override
  late final AppMessages$common$es common = AppMessages$common$es._(_root);
  @override
  late final AppMessages$actions$es actions = AppMessages$actions$es._(_root);
  @override
  late final AppMessages$validations$es validations =
      AppMessages$validations$es._(_root);
  @override
  late final AppMessages$errors$es errors = AppMessages$errors$es._(_root);
  @override
  late final AppMessages$login$es login = AppMessages$login$es._(_root);
  @override
  late final AppMessages$session$es session = AppMessages$session$es._(_root);
  @override
  late final AppMessages$offline$es offline = AppMessages$offline$es._(_root);
  @override
  late final AppMessages$notFound$es notFound = AppMessages$notFound$es._(
    _root,
  );
  @override
  late final AppMessages$routes$es routes = AppMessages$routes$es._(_root);
  @override
  late final AppMessages$form$es form = AppMessages$form$es._(_root);
  @override
  late final AppMessages$delete$es delete = AppMessages$delete$es._(_root);
  @override
  late final AppMessages$restore$es restore = AppMessages$restore$es._(_root);
  @override
  late final AppMessages$logs$es logs = AppMessages$logs$es._(_root);
  @override
  late final AppMessages$logDetails$es logDetails = AppMessages$logDetails$es._(
    _root,
  );
  @override
  late final AppMessages$logFilters$es logFilters = AppMessages$logFilters$es._(
    _root,
  );
  @override
  late final AppMessages$calendar$es calendar = AppMessages$calendar$es._(
    _root,
  );
}

// Path: app
class AppMessages$app$es implements AppMessages$app$en {
  AppMessages$app$es._(this._root);

  final AppMessagesEs _root; // ignore: unused_field

  // Translations
  @override
  String get name => 'api-gateway';
  @override
  String get needMoreSpace => 'Se necesita más espacio';
  @override
  String get taglineStart => 'One route to';
  @override
  String get taglineEnd => 'rule them all';
  @override
  String get connecting => 'Conectando con el gateway…';
  @override
  String languageLabel({required Object name}) => 'Idioma: ${name}';
  @override
  String get logout => 'Cerrar sesión';
  @override
  String get expandMenu => 'Expandir menú';
  @override
  String get collapseMenu => 'Contraer menú';
}

// Path: common
class AppMessages$common$es implements AppMessages$common$en {
  AppMessages$common$es._(this._root);

  final AppMessagesEs _root; // ignore: unused_field

  // Translations
  @override
  String get loading => 'Cargando';
  @override
  String get noAccess => 'No tienes acceso a esta funcionalidad';
}

// Path: actions
class AppMessages$actions$es implements AppMessages$actions$en {
  AppMessages$actions$es._(this._root);

  final AppMessagesEs _root; // ignore: unused_field

  // Translations
  @override
  String get tryAgain => 'Reintentar';
  @override
  String get cancel => 'Cancelar';
  @override
  String get close => 'Cerrar';
  @override
  String get dismiss => 'Descartar';
  @override
  String get back => 'Atrás';
  @override
  String get copiedToClipboard => 'Copiado al portapapeles';
  @override
  String get copy => 'Copiar';
  @override
  String get refresh => 'Actualizar';
  @override
  String get clearSearch => 'Limpiar búsqueda';
}

// Path: validations
class AppMessages$validations$es implements AppMessages$validations$en {
  AppMessages$validations$es._(this._root);

  final AppMessagesEs _root; // ignore: unused_field

  // Translations
  @override
  String get requiredField => 'Campo requerido';
}

// Path: errors
class AppMessages$errors$es implements AppMessages$errors$en {
  AppMessages$errors$es._(this._root);

  final AppMessagesEs _root; // ignore: unused_field

  // Translations
  @override
  String get requestCancelled => 'La petición al servidor fue cancelada';
  @override
  String get connectionTimeout =>
      'Tiempo de conexión agotado con el servidor. Revisa tu conexión a internet';
  @override
  String get noConnection =>
      'Falló la conexión con el servidor. Revisa tu conexión a internet';
  @override
  String get receiveTimeout => 'Tiempo de recepción agotado con el servidor';
  @override
  String get sendTimeout => 'Tiempo de envío agotado con el servidor';
  @override
  String get transformTimeout =>
      'Tiempo agotado procesando la respuesta del servidor';
  @override
  String get badCertificate => 'Certificado inválido';
  @override
  String get connection => 'Error de conexión';
  @override
  String get validation => 'Error de validación';
  @override
  String get auth => 'Error de autenticación';
  @override
  String get server => 'Error del servidor';
  @override
  String get unknown => 'Error desconocido';
  @override
  String status({required Object status}) => 'Error ${status}';
  @override
  String get noData => 'No hay nada por aquí';
  @override
  String get genericError => 'Ha ocurrido un error';
  @override
  String get errorWrongRouteId => 'Id de ruta incorrecto';
  @override
  String errorLoadingRoute({required Object message}) =>
      'Error cargando la ruta. ${message}';
  @override
  String get errorUnsupportedAction => 'Acción no soportada';
}

// Path: login
class AppMessages$login$es implements AppMessages$login$en {
  AppMessages$login$es._(this._root);

  final AppMessagesEs _root; // ignore: unused_field

  // Translations
  @override
  String get usernameLabel => 'Usuario';
  @override
  String get passwordLabel => 'Contraseña';
  @override
  String get login => 'Entrar';
  @override
  String get signingIn => 'Entrando…';
  @override
  String get subtitle => 'Gestiona tus rutas y logs HTTP.';
  @override
  String get showPassword => 'Mostrar contraseña';
  @override
  String get hidePassword => 'Ocultar contraseña';
  @override
  String get rememberMe => 'Recordarme';
  @override
  String get rememberMeWarning =>
      'Tu sesión seguirá abierta en este navegador hasta que expire. Úsalo solo en un dispositivo de confianza.';
  @override
  String get gatewayReachable => 'Gateway disponible';
  @override
  String get gatewayUnreachable => 'Gateway no disponible';
  @override
  String get wrongCredentials => 'Usuario o contraseña incorrectos';
  @override
  String get credentialsHintStart =>
      'Las credenciales se definen con las variables de entorno';
  @override
  String get credentialsHintAnd => 'y';
  @override
  String get credentialsHintEnd => '';
  @override
  String get signedOut => 'Sesión cerrada';
  @override
  String get featureRedirections => 'Redirecciones fáciles';
  @override
  String get featureLogs => 'Logs HTTP';
  @override
  String get featureBackup => 'Backup y restore';
}

// Path: session
class AppMessages$session$es implements AppMessages$session$en {
  AppMessages$session$es._(this._root);

  final AppMessagesEs _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'Tu sesión expiró';
  @override
  String get description =>
      'Tu sesión ha terminado. Entra de nuevo para continuar donde lo dejaste.';
  @override
  String get passwordHint => 'Escribe tu contraseña';
  @override
  String get wrongPassword => 'Contraseña incorrecta, inténtalo de nuevo.';
  @override
  String get signIn => 'Entrar';
  @override
  String get goToLogin => 'Ir a la página de login';
}

// Path: offline
class AppMessages$offline$es implements AppMessages$offline$en {
  AppMessages$offline$es._(this._root);

  final AppMessagesEs _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'No se puede conectar con el gateway.';
  @override
  String detail({required Object time}) =>
      'Mostrando lo cargado a las ${time}. El enrutado sigue funcionando en el servidor.';
  @override
  String get retryAuto => 'Reintentando automáticamente cada 10 s.';
  @override
  String get retrying => 'Intentando reconectar…';
  @override
  String get retryNow => 'Reintentar ahora';
  @override
  String get retryingButton => 'Reintentando…';
  @override
  String get restored => 'Conexión restablecida';
}

// Path: notFound
class AppMessages$notFound$es implements AppMessages$notFound$en {
  AppMessages$notFound$es._(this._root);

  final AppMessagesEs _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'Esta página no existe';
  @override
  String get description =>
      'La ruta o el log pueden haberse borrado, o el enlace es incorrecto.';
  @override
  String get goToRoutes => 'Ir a Rutas';
  @override
  String get openLogs => 'Abrir Http logs';
}

// Path: routes
class AppMessages$routes$es implements AppMessages$routes$en {
  AppMessages$routes$es._(this._root);

  final AppMessagesEs _root; // ignore: unused_field

  // Translations
  @override
  String get routes => 'Rutas';
  @override
  String get oneRoute => '1 ruta';
  @override
  String manyRoutes({required Object count}) => '${count} rutas';
  @override
  String get backup => 'Backup';
  @override
  String get restore => 'Restaurar';
  @override
  String get createRoute => 'Crear ruta';
  @override
  String get editRoute => 'Editar ruta';
  @override
  String get duplicateRoute => 'Duplicar ruta';
  @override
  String get edit => 'Editar';
  @override
  String get duplicate => 'Duplicar';
  @override
  String get delete => 'Eliminar';
  @override
  String get search => 'Buscar por nombre, path o URI';
  @override
  String get noDescription => 'Sin descripción';
  @override
  String noMatches({required Object query}) =>
      'Ninguna ruta coincide con "${query}"';
  @override
  String get noRoutesYet => 'Aún no hay rutas';
  @override
  String get noMatchesHint => 'Prueba otra búsqueda o crea una ruta nueva.';
  @override
  String get from => 'DESDE';
  @override
  String get to => 'HACIA';
  @override
  String get copyFrom => 'Copiar URL de origen';
  @override
  String get copyTo => 'Copiar URL de destino';
  @override
  String backupSaved({required Object count}) =>
      'Backup guardado · ${count} rutas';
  @override
  String created({required Object name}) => 'Ruta "${name}" creada';
  @override
  String updated({required Object name}) => 'Ruta "${name}" actualizada';
  @override
  String deleted({required Object name}) => 'Ruta "${name}" eliminada';
}

// Path: form
class AppMessages$form$es implements AppMessages$form$en {
  AppMessages$form$es._(this._root);

  final AppMessagesEs _root; // ignore: unused_field

  // Translations
  @override
  String get createSubtitle =>
      'Reenvía las peticiones que coincidan a otro servicio';
  @override
  String get editSubtitle =>
      'Los cambios se aplican de inmediato a las nuevas peticiones';
  @override
  String get duplicateSubtitle => 'Se crea una ruta nueva a partir de la copia';
  @override
  String get saveChanges => 'Guardar cambios';
  @override
  String get duplicatingStart => 'Estás duplicando';
  @override
  String get duplicatingEnd =>
      '. Revisa el nombre, el path y la URI antes de guardar: dos rutas con el mismo path competirán por las mismas peticiones.';
  @override
  String get nameLabel => 'Nombre';
  @override
  String get nameHint => 'p. ej. auth';
  @override
  String get pathLabel => 'Path';
  @override
  String get pathHint => '/service/**';
  @override
  String get uriLabel => 'URI';
  @override
  String get uriHint => 'https://service.example.com';
  @override
  String get rewritePathFromLabel => 'Reescribir path desde';
  @override
  String get rewritePathFromHint => '/service/';
  @override
  String get rewritePathToLabel => 'Reescribir path a';
  @override
  String get rewritePathToHint => '/';
  @override
  String get descriptionLabel => 'Descripción';
  @override
  String get descriptionHint => 'Para qué sirve esta ruta (opcional)';
  @override
  String get preview => 'VISTA PREVIA';
  @override
  String get previewName => 'Nombre de la ruta';
  @override
  String get rewrite => 'Reescritura';
  @override
  String aboutDuplicating({required String name}) => 'Sobre duplicar ${name}';
  @override
  String get editName => 'Editar el nombre';
  @override
  String get editDescription => 'Editar la descripción';
  @override
  String get editPath => 'Editar el path';
  @override
  String get editUri => 'Editar la URI';
  @override
  String get editRewrite => 'Editar la reescritura del path';
  @override
  String get next => 'Siguiente';
  @override
  String stepOf({required int step, required String name}) =>
      'Paso ${step} de 3 · ${name}';
  @override
  String get stepGeneral => 'General';
  @override
  String get stepGeneralHint => 'Cómo se ve la ruta en la consola.';
  @override
  String get stepForwarding => 'Reenvío';
  @override
  String get stepForwardingHint =>
      'Las peticiones que coinciden con el path se envían a la URI.';
  @override
  String get stepRewrite => 'Reescritura del path';
  @override
  String get stepRewriteHint =>
      'Opcional. Cambia un prefijo del path antes de reenviar.';
  @override
  String get nameTaken => 'Ya existe una ruta con este nombre';
}

// Path: delete
class AppMessages$delete$es implements AppMessages$delete$en {
  AppMessages$delete$es._(this._root);

  final AppMessagesEs _root; // ignore: unused_field

  // Translations
  @override
  String get title => '¿Eliminar esta ruta?';
  @override
  String get descriptionStart => 'Las peticiones a';
  @override
  String get descriptionEnd =>
      'dejarán de reenviarse. Esto no se puede deshacer.';
  @override
  String get confirm => 'Eliminar ruta';
}

// Path: restore
class AppMessages$restore$es implements AppMessages$restore$en {
  AppMessages$restore$es._(this._root);

  final AppMessagesEs _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'Restaurar rutas';
  @override
  String get subtitle =>
      'Reemplaza todas las rutas actuales por las del backup';
  @override
  String get selectFile => 'Seleccionar archivo';
  @override
  String get dropFileHere => 'Arrastra aquí un archivo de backup';
  @override
  String get releaseFile => 'Suelta para cargar el archivo';
  @override
  String get hint => 'Un archivo .json creado con Backup';
  @override
  String ready({required Object count}) =>
      '${count} rutas listas para restaurar';
  @override
  String get invalidFile =>
      'No es un backup de rutas válido: usa una lista .json de rutas con name, path y uri.';
  @override
  String duplicatedNames({required Object names}) =>
      'Nombres duplicados en el archivo: ${names}';
  @override
  String confirmTitle({required Object current, required Object next}) =>
      '¿Reemplazar ${current} rutas por ${next}?';
  @override
  String get confirmStart =>
      'Todas las rutas actuales se eliminan y se reemplazan por las de';
  @override
  String get confirmEnd => '. Esto no se puede deshacer.';
  @override
  String current({required Object count}) => 'ACTUALES · ${count}';
  @override
  String fromBackup({required Object count}) => 'DEL BACKUP · ${count}';
  @override
  String get replace => 'Reemplazar rutas';
  @override
  String restored({required Object count}) => 'Restauradas ${count} rutas';
}

// Path: logs
class AppMessages$logs$es implements AppMessages$logs$en {
  AppMessages$logs$es._(this._root);

  final AppMessagesEs _root; // ignore: unused_field

  // Translations
  @override
  String get logs => 'Http logs';
  @override
  String captured({required Object count}) =>
      '${count} peticiones capturadas · las más recientes primero';
  @override
  String get search => 'Buscar por user agent, IP de origen, path o ruta';
  @override
  String get export => 'Exportar';
  @override
  String get filters => 'Filtros';
  @override
  String filtersActive({required Object count}) => 'Filtros, ${count} activos';
  @override
  String removeFilter({required Object label}) => 'Quitar filtro ${label}';
  @override
  String get columnTimestamp => 'FECHA';
  @override
  String get columnMethod => 'MÉTODO';
  @override
  String get columnPath => 'PATH';
  @override
  String get columnRoute => 'RUTA';
  @override
  String get columnHttpStatus => 'ESTADO';
  @override
  String get columnRequestDuration => 'DURACIÓN';
  @override
  String durationMs({required Object ms}) => '${ms} ms';
  @override
  String get noMatches => 'Ningún log coincide con tu búsqueda o filtros';
  @override
  String get clearAll => 'Limpiar búsqueda y filtros';
  @override
  String get loading => 'Cargando peticiones…';
  @override
  String get filtering => 'Filtrando…';
  @override
  String get oneRequest => '1 petición';
  @override
  String manyRequests({required Object count}) => '${count} peticiones';
  @override
  String get matchSuffix => ' coinciden con tu búsqueda y filtros';
  @override
  String get rowHint => ' · haz clic en una fila para ver sus detalles';
  @override
  String get rowsPerPage => 'Filas por página';
  @override
  String range({
    required Object start,
    required Object end,
    required Object total,
  }) => '${start}–${end} de ${total}';
  @override
  String get emptyRange => '0 de 0';
  @override
  String get previousPage => 'Página anterior';
  @override
  String get nextPage => 'Página siguiente';
  @override
  String page({required Object page}) => 'Página ${page}';
  @override
  String get noNewRequests => 'No hay peticiones nuevas';
  @override
  String get refreshed => 'Mostrando las peticiones más recientes';
  @override
  String get oneNewRequest => '1 petición nueva';
  @override
  String manyNewRequests({required Object count}) =>
      '${count} peticiones nuevas';
  @override
  String exported({required Object count}) =>
      'Exportados ${count} logs como JSON';
  @override
  String exportedCapped({required Object count}) =>
      'Exportados los ${count} logs más recientes como JSON (el límite de exportación). Acota los filtros para exportar el resto';
}

// Path: logDetails
class AppMessages$logDetails$es implements AppMessages$logDetails$en {
  AppMessages$logDetails$es._(this._root);

  final AppMessagesEs _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'Detalles de la petición';
  @override
  String get request => 'PETICIÓN';
  @override
  String get route => 'RUTA';
  @override
  String get timestamp => 'Fecha';
  @override
  String get sourceIp => 'IP de origen';
  @override
  String get userAgent => 'User agent';
  @override
  String get routeName => 'Nombre';
  @override
  String get routePath => 'Path';
  @override
  String get routeId => 'Id';
  @override
  String openRoute({required Object name}) => 'Abrir ruta ${name}';
}

// Path: logFilters
class AppMessages$logFilters$es implements AppMessages$logFilters$en {
  AppMessages$logFilters$es._(this._root);

  final AppMessagesEs _root; // ignore: unused_field

  // Translations
  @override
  String get filter => 'Filtrar logs';
  @override
  String get applyFilters => 'Aplicar filtros';
  @override
  String get clearAll => 'Limpiar todo';
  @override
  String get status => 'Estado HTTP';
  @override
  String get exactCode => 'Código HTTP exacto';
  @override
  String get exactCodeHint => 'Otro';
  @override
  String get method => 'Método HTTP';
  @override
  String get anyMethod => 'Todos';
  @override
  String get route => 'Ruta';
  @override
  String get anyRoute => 'Todas las rutas';
  @override
  String get filterNoRouteName => 'Sin-Ruta';
  @override
  String get dateRange => 'Rango de fechas';
  @override
  String get anyDate => 'Cualquier fecha';
  @override
  String chipFrom({required Object date}) => 'Desde ${date}';
  @override
  String chipUntil({required Object date}) => 'Hasta ${date}';
}

// Path: calendar
class AppMessages$calendar$es implements AppMessages$calendar$en {
  AppMessages$calendar$es._(this._root);

  final AppMessagesEs _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'Selecciona un rango de fechas';
  @override
  String get previousMonth => 'Mes anterior';
  @override
  String get nextMonth => 'Mes siguiente';
  @override
  String get today => 'Hoy';
  @override
  String get last7 => 'Últimos 7 días';
  @override
  String get last30 => 'Últimos 30 días';
  @override
  String get thisMonth => 'Este mes';
  @override
  String get clear => 'Limpiar';
  @override
  String get done => 'Listo';
  @override
  String get weekdays => 'Lu,Ma,Mi,Ju,Vi,Sa,Do';
  @override
  String get hintStart => 'Elige una fecha de inicio';
  @override
  String get hintEnd => 'Ahora elige la fecha de fin';
  @override
  String get hintRestart => 'Haz clic en un día para empezar un rango nuevo';
}

/// The flat map containing all translations for locale <es>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on AppMessagesEs {
  dynamic _flatMapFunction(String path) {
    return switch (path) {
      'app.name' => 'api-gateway',
      'app.needMoreSpace' => 'Se necesita más espacio',
      'app.taglineStart' => 'One route to',
      'app.taglineEnd' => 'rule them all',
      'app.connecting' => 'Conectando con el gateway…',
      'app.languageLabel' => ({required Object name}) => 'Idioma: ${name}',
      'app.logout' => 'Cerrar sesión',
      'app.expandMenu' => 'Expandir menú',
      'app.collapseMenu' => 'Contraer menú',
      'common.loading' => 'Cargando',
      'common.noAccess' => 'No tienes acceso a esta funcionalidad',
      'actions.tryAgain' => 'Reintentar',
      'actions.cancel' => 'Cancelar',
      'actions.close' => 'Cerrar',
      'actions.dismiss' => 'Descartar',
      'actions.back' => 'Atrás',
      'actions.copiedToClipboard' => 'Copiado al portapapeles',
      'actions.copy' => 'Copiar',
      'actions.refresh' => 'Actualizar',
      'actions.clearSearch' => 'Limpiar búsqueda',
      'validations.requiredField' => 'Campo requerido',
      'errors.requestCancelled' => 'La petición al servidor fue cancelada',
      'errors.connectionTimeout' => 'Tiempo de conexión agotado con el servidor. Revisa tu conexión a internet',
      'errors.noConnection' =>
        'Falló la conexión con el servidor. Revisa tu conexión a internet',
      'errors.receiveTimeout' => 'Tiempo de recepción agotado con el servidor',
      'errors.sendTimeout' => 'Tiempo de envío agotado con el servidor',
      'errors.transformTimeout' =>
        'Tiempo agotado procesando la respuesta del servidor',
      'errors.badCertificate' => 'Certificado inválido',
      'errors.connection' => 'Error de conexión',
      'errors.validation' => 'Error de validación',
      'errors.auth' => 'Error de autenticación',
      'errors.server' => 'Error del servidor',
      'errors.unknown' => 'Error desconocido',
      'errors.status' => ({required Object status}) => 'Error ${status}',
      'errors.noData' => 'No hay nada por aquí',
      'errors.genericError' => 'Ha ocurrido un error',
      'errors.errorWrongRouteId' => 'Id de ruta incorrecto',
      'errors.errorLoadingRoute' => ({
        required Object message,
      }) => 'Error cargando la ruta. ${message}',
      'errors.errorUnsupportedAction' => 'Acción no soportada',
      'login.usernameLabel' => 'Usuario',
      'login.passwordLabel' => 'Contraseña',
      'login.login' => 'Entrar',
      'login.signingIn' => 'Entrando…',
      'login.subtitle' => 'Gestiona tus rutas y logs HTTP.',
      'login.showPassword' => 'Mostrar contraseña',
      'login.hidePassword' => 'Ocultar contraseña',
      'login.rememberMe' => 'Recordarme',
      'login.rememberMeWarning' => 'Tu sesión seguirá abierta en este navegador hasta que expire. Úsalo solo en un dispositivo de confianza.',
      'login.gatewayReachable' => 'Gateway disponible',
      'login.gatewayUnreachable' => 'Gateway no disponible',
      'login.wrongCredentials' => 'Usuario o contraseña incorrectos',
      'login.credentialsHintStart' =>
        'Las credenciales se definen con las variables de entorno',
      'login.credentialsHintAnd' => 'y',
      'login.credentialsHintEnd' => '',
      'login.signedOut' => 'Sesión cerrada',
      'login.featureRedirections' => 'Redirecciones fáciles',
      'login.featureLogs' => 'Logs HTTP',
      'login.featureBackup' => 'Backup y restore',
      'session.title' => 'Tu sesión expiró',
      'session.description' => 'Tu sesión ha terminado. Entra de nuevo para continuar donde lo dejaste.',
      'session.passwordHint' => 'Escribe tu contraseña',
      'session.wrongPassword' => 'Contraseña incorrecta, inténtalo de nuevo.',
      'session.signIn' => 'Entrar',
      'session.goToLogin' => 'Ir a la página de login',
      'offline.title' => 'No se puede conectar con el gateway.',
      'offline.detail' => ({
        required Object time,
      }) => 'Mostrando lo cargado a las ${time}. El enrutado sigue funcionando en el servidor.',
      'offline.retryAuto' => 'Reintentando automáticamente cada 10 s.',
      'offline.retrying' => 'Intentando reconectar…',
      'offline.retryNow' => 'Reintentar ahora',
      'offline.retryingButton' => 'Reintentando…',
      'offline.restored' => 'Conexión restablecida',
      'notFound.title' => 'Esta página no existe',
      'notFound.description' =>
        'La ruta o el log pueden haberse borrado, o el enlace es incorrecto.',
      'notFound.goToRoutes' => 'Ir a Rutas',
      'notFound.openLogs' => 'Abrir Http logs',
      'routes.routes' => 'Rutas',
      'routes.oneRoute' => '1 ruta',
      'routes.manyRoutes' => ({required Object count}) => '${count} rutas',
      'routes.backup' => 'Backup',
      'routes.restore' => 'Restaurar',
      'routes.createRoute' => 'Crear ruta',
      'routes.editRoute' => 'Editar ruta',
      'routes.duplicateRoute' => 'Duplicar ruta',
      'routes.edit' => 'Editar',
      'routes.duplicate' => 'Duplicar',
      'routes.delete' => 'Eliminar',
      'routes.search' => 'Buscar por nombre, path o URI',
      'routes.noDescription' => 'Sin descripción',
      'routes.noMatches' => ({
        required Object query,
      }) => 'Ninguna ruta coincide con "${query}"',
      'routes.noRoutesYet' => 'Aún no hay rutas',
      'routes.noMatchesHint' => 'Prueba otra búsqueda o crea una ruta nueva.',
      'routes.from' => 'DESDE',
      'routes.to' => 'HACIA',
      'routes.copyFrom' => 'Copiar URL de origen',
      'routes.copyTo' => 'Copiar URL de destino',
      'routes.backupSaved' => ({
        required Object count,
      }) => 'Backup guardado · ${count} rutas',
      'routes.created' => ({required Object name}) => 'Ruta "${name}" creada',
      'routes.updated' => ({
        required Object name,
      }) => 'Ruta "${name}" actualizada',
      'routes.deleted' => ({
        required Object name,
      }) => 'Ruta "${name}" eliminada',
      'form.createSubtitle' =>
        'Reenvía las peticiones que coincidan a otro servicio',
      'form.editSubtitle' =>
        'Los cambios se aplican de inmediato a las nuevas peticiones',
      'form.duplicateSubtitle' => 'Se crea una ruta nueva a partir de la copia',
      'form.saveChanges' => 'Guardar cambios',
      'form.duplicatingStart' => 'Estás duplicando',
      'form.duplicatingEnd' => '. Revisa el nombre, el path y la URI antes de guardar: dos rutas con el mismo path competirán por las mismas peticiones.',
      'form.nameLabel' => 'Nombre',
      'form.nameHint' => 'p. ej. auth',
      'form.pathLabel' => 'Path',
      'form.pathHint' => '/service/**',
      'form.uriLabel' => 'URI',
      'form.uriHint' => 'https://service.example.com',
      'form.rewritePathFromLabel' => 'Reescribir path desde',
      'form.rewritePathFromHint' => '/service/',
      'form.rewritePathToLabel' => 'Reescribir path a',
      'form.rewritePathToHint' => '/',
      'form.descriptionLabel' => 'Descripción',
      'form.descriptionHint' => 'Para qué sirve esta ruta (opcional)',
      'form.preview' => 'VISTA PREVIA',
      'form.previewName' => 'Nombre de la ruta',
      'form.rewrite' => 'Reescritura',
      'form.aboutDuplicating' => ({
        required String name,
      }) => 'Sobre duplicar ${name}',
      'form.editName' => 'Editar el nombre',
      'form.editDescription' => 'Editar la descripción',
      'form.editPath' => 'Editar el path',
      'form.editUri' => 'Editar la URI',
      'form.editRewrite' => 'Editar la reescritura del path',
      'form.next' => 'Siguiente',
      'form.stepOf' => ({
        required int step,
        required String name,
      }) => 'Paso ${step} de 3 · ${name}',
      'form.stepGeneral' => 'General',
      'form.stepGeneralHint' => 'Cómo se ve la ruta en la consola.',
      'form.stepForwarding' => 'Reenvío',
      'form.stepForwardingHint' =>
        'Las peticiones que coinciden con el path se envían a la URI.',
      'form.stepRewrite' => 'Reescritura del path',
      'form.stepRewriteHint' =>
        'Opcional. Cambia un prefijo del path antes de reenviar.',
      'form.nameTaken' => 'Ya existe una ruta con este nombre',
      'delete.title' => '¿Eliminar esta ruta?',
      'delete.descriptionStart' => 'Las peticiones a',
      'delete.descriptionEnd' =>
        'dejarán de reenviarse. Esto no se puede deshacer.',
      'delete.confirm' => 'Eliminar ruta',
      'restore.title' => 'Restaurar rutas',
      'restore.subtitle' =>
        'Reemplaza todas las rutas actuales por las del backup',
      'restore.selectFile' => 'Seleccionar archivo',
      'restore.dropFileHere' => 'Arrastra aquí un archivo de backup',
      'restore.releaseFile' => 'Suelta para cargar el archivo',
      'restore.hint' => 'Un archivo .json creado con Backup',
      'restore.ready' => ({
        required Object count,
      }) => '${count} rutas listas para restaurar',
      'restore.invalidFile' => 'No es un backup de rutas válido: usa una lista .json de rutas con name, path y uri.',
      'restore.duplicatedNames' => ({
        required Object names,
      }) => 'Nombres duplicados en el archivo: ${names}',
      'restore.confirmTitle' => ({
        required Object current,
        required Object next,
      }) => '¿Reemplazar ${current} rutas por ${next}?',
      'restore.confirmStart' =>
        'Todas las rutas actuales se eliminan y se reemplazan por las de',
      'restore.confirmEnd' => '. Esto no se puede deshacer.',
      'restore.current' => ({required Object count}) => 'ACTUALES · ${count}',
      'restore.fromBackup' => ({
        required Object count,
      }) => 'DEL BACKUP · ${count}',
      'restore.replace' => 'Reemplazar rutas',
      'restore.restored' => ({
        required Object count,
      }) => 'Restauradas ${count} rutas',
      'logs.logs' => 'Http logs',
      'logs.captured' => ({
        required Object count,
      }) => '${count} peticiones capturadas · las más recientes primero',
      'logs.search' => 'Buscar por user agent, IP de origen, path o ruta',
      'logs.export' => 'Exportar',
      'logs.filters' => 'Filtros',
      'logs.filtersActive' => ({
        required Object count,
      }) => 'Filtros, ${count} activos',
      'logs.removeFilter' => ({
        required Object label,
      }) => 'Quitar filtro ${label}',
      'logs.columnTimestamp' => 'FECHA',
      'logs.columnMethod' => 'MÉTODO',
      'logs.columnPath' => 'PATH',
      'logs.columnRoute' => 'RUTA',
      'logs.columnHttpStatus' => 'ESTADO',
      'logs.columnRequestDuration' => 'DURACIÓN',
      'logs.durationMs' => ({required Object ms}) => '${ms} ms',
      'logs.noMatches' => 'Ningún log coincide con tu búsqueda o filtros',
      'logs.clearAll' => 'Limpiar búsqueda y filtros',
      'logs.loading' => 'Cargando peticiones…',
      'logs.filtering' => 'Filtrando…',
      'logs.oneRequest' => '1 petición',
      'logs.manyRequests' => ({required Object count}) => '${count} peticiones',
      'logs.matchSuffix' => ' coinciden con tu búsqueda y filtros',
      'logs.rowHint' => ' · haz clic en una fila para ver sus detalles',
      'logs.rowsPerPage' => 'Filas por página',
      'logs.range' => ({
        required Object start,
        required Object end,
        required Object total,
      }) => '${start}–${end} de ${total}',
      'logs.emptyRange' => '0 de 0',
      'logs.previousPage' => 'Página anterior',
      'logs.nextPage' => 'Página siguiente',
      'logs.page' => ({required Object page}) => 'Página ${page}',
      'logs.noNewRequests' => 'No hay peticiones nuevas',
      'logs.refreshed' => 'Mostrando las peticiones más recientes',
      'logs.oneNewRequest' => '1 petición nueva',
      'logs.manyNewRequests' => ({
        required Object count,
      }) => '${count} peticiones nuevas',
      'logs.exported' => ({
        required Object count,
      }) => 'Exportados ${count} logs como JSON',
      'logs.exportedCapped' => ({
        required Object count,
      }) => 'Exportados los ${count} logs más recientes como JSON (el límite de exportación). Acota los filtros para exportar el resto',
      'logDetails.title' => 'Detalles de la petición',
      'logDetails.request' => 'PETICIÓN',
      'logDetails.route' => 'RUTA',
      'logDetails.timestamp' => 'Fecha',
      'logDetails.sourceIp' => 'IP de origen',
      'logDetails.userAgent' => 'User agent',
      'logDetails.routeName' => 'Nombre',
      'logDetails.routePath' => 'Path',
      'logDetails.routeId' => 'Id',
      'logDetails.openRoute' => ({
        required Object name,
      }) => 'Abrir ruta ${name}',
      'logFilters.filter' => 'Filtrar logs',
      'logFilters.applyFilters' => 'Aplicar filtros',
      'logFilters.clearAll' => 'Limpiar todo',
      'logFilters.status' => 'Estado HTTP',
      'logFilters.exactCode' => 'Código HTTP exacto',
      'logFilters.exactCodeHint' => 'Otro',
      'logFilters.method' => 'Método HTTP',
      'logFilters.anyMethod' => 'Todos',
      'logFilters.route' => 'Ruta',
      'logFilters.anyRoute' => 'Todas las rutas',
      'logFilters.filterNoRouteName' => 'Sin-Ruta',
      'logFilters.dateRange' => 'Rango de fechas',
      'logFilters.anyDate' => 'Cualquier fecha',
      'logFilters.chipFrom' => ({required Object date}) => 'Desde ${date}',
      'logFilters.chipUntil' => ({required Object date}) => 'Hasta ${date}',
      'calendar.title' => 'Selecciona un rango de fechas',
      'calendar.previousMonth' => 'Mes anterior',
      'calendar.nextMonth' => 'Mes siguiente',
      'calendar.today' => 'Hoy',
      'calendar.last7' => 'Últimos 7 días',
      'calendar.last30' => 'Últimos 30 días',
      'calendar.thisMonth' => 'Este mes',
      'calendar.clear' => 'Limpiar',
      'calendar.done' => 'Listo',
      'calendar.weekdays' => 'Lu,Ma,Mi,Ju,Vi,Sa,Do',
      'calendar.hintStart' => 'Elige una fecha de inicio',
      'calendar.hintEnd' => 'Ahora elige la fecha de fin',
      'calendar.hintRestart' =>
        'Haz clic en un día para empezar un rango nuevo',
      _ => null,
    };
  }
}
