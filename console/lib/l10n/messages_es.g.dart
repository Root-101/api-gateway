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
  late final AppMessages$routes$es routes = AppMessages$routes$es._(_root);
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
}

// Path: app
class AppMessages$app$es implements AppMessages$app$en {
  AppMessages$app$es._(this._root);

  final AppMessagesEs _root; // ignore: unused_field

  // Translations
  @override
  String get name => 'Api Gateway';
  @override
  String get needMoreSpace => 'Se necesita más espacio';
  @override
  String consoleVersion({required Object version}) => 'Consola v${version}';
}

// Path: common
class AppMessages$common$es implements AppMessages$common$en {
  AppMessages$common$es._(this._root);

  final AppMessagesEs _root; // ignore: unused_field

  // Translations
  @override
  String get loading => 'Cargando';
  @override
  String get noAccess => 'Usted no tiene acceso a esta funcionalidad';
}

// Path: actions
class AppMessages$actions$es implements AppMessages$actions$en {
  AppMessages$actions$es._(this._root);

  final AppMessagesEs _root; // ignore: unused_field

  // Translations
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
  String get cancel => 'Cancelar';
  @override
  String deleteRouteConfirm({required Object name}) =>
      '¿Eliminar la ruta "${name}"? Esta acción no se puede deshacer.';
  @override
  String get back => 'Regresar';
  @override
  String get copiedToClipboard => 'Copiado al portapapeles';
  @override
  String get copy => 'Copiar';
  @override
  String get refresh => 'Refrescar';
}

// Path: validations
class AppMessages$validations$es implements AppMessages$validations$en {
  AppMessages$validations$es._(this._root);

  final AppMessagesEs _root; // ignore: unused_field

  // Translations
  @override
  String get requiredField => 'Campo requerido';
  @override
  String get validUriField => 'Debe ser una URL válida';
  @override
  String get wholeNumberField => 'Debe ser un número entero';
}

// Path: errors
class AppMessages$errors$es implements AppMessages$errors$en {
  AppMessages$errors$es._(this._root);

  final AppMessagesEs _root; // ignore: unused_field

  // Translations
  @override
  String get requestCancelled => 'Se canceló la petición al servidor';
  @override
  String get connectionTimeout =>
      'Tiempo de conexión agotado con el servidor. Revisa tu conexión a internet';
  @override
  String get noConnection =>
      'No se pudo conectar con el servidor. Revisa tu conexión a internet';
  @override
  String get receiveTimeout =>
      'Tiempo de espera agotado recibiendo la respuesta del servidor';
  @override
  String get sendTimeout =>
      'Tiempo de espera agotado enviando la petición al servidor';
  @override
  String get transformTimeout =>
      'Tiempo de espera agotado procesando la respuesta del servidor';
  @override
  String get badCertificate => 'Certificado no válido';
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
  String get noData => 'No hay datos';
  @override
  String get genericError => 'Algo ha salido mal';
  @override
  String get errorWrongRouteId => 'Id de ruta incorrecto';
  @override
  String errorLoadingRoute({required Object id, required Object message}) =>
      'Error cargando la ruta ${id}. ${message}';
  @override
  String get errorUnsupportedAction => 'Acción no soportada';
}

// Path: login
class AppMessages$login$es implements AppMessages$login$en {
  AppMessages$login$es._(this._root);

  final AppMessagesEs _root; // ignore: unused_field

  // Translations
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
  String get rememberMeWarning =>
      'Su sesión seguirá abierta en este navegador hasta que caduque. Úselo solo en un equipo de confianza.';
  @override
  String get gatewayReachable => 'Gateway accesible';
  @override
  String get gatewayUnreachable => 'Gateway no accesible';
}

// Path: routes
class AppMessages$routes$es implements AppMessages$routes$en {
  AppMessages$routes$es._(this._root);

  final AppMessagesEs _root; // ignore: unused_field

  // Translations
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
  String get descriptionLabel => 'Descripción';
  @override
  String get descriptionHint => 'Para qué sirve esta ruta (opcional)';
  @override
  String get searchRoutes => 'Buscar por nombre, path o URI';
  @override
  String get advancedTitle => 'Avanzado';
  @override
  String get orderLabel => 'Orden (el menor se evalúa primero)';
  @override
  String get orderHint => '0';
  @override
  String get methodsLabel => 'Métodos HTTP (ninguno = cualquier método)';
  @override
  String get hostsLabel => 'Hosts (ninguno = cualquier host)';
  @override
  String get hostHint => '**.example.com';
  @override
  String get addHost => 'Añadir host';
  @override
  String get headersLabel =>
      'Headers requeridos (la petición debe cumplirlos todos)';
  @override
  String get headerNameLabel => 'Nombre del header';
  @override
  String get headerNameHint => 'X-Tenant';
  @override
  String get headerRegexpLabel => 'Regexp del valor (opcional)';
  @override
  String get headerRegexpHint => 'acme.*';
  @override
  String get addHeader => 'Añadir header';
  @override
  String get filtersLabel =>
      'Filtros (se aplican en orden, después del rewrite)';
  @override
  String get filterNameLabel => 'Filtro';
  @override
  String get filterNameHint => 'X-From';
  @override
  String get filterValueLabel => 'Valor';
  @override
  String get filterValueHint => 'gateway';
  @override
  String get addFilter => 'Añadir filtro';
}

// Path: restore
class AppMessages$restore$es implements AppMessages$restore$en {
  AppMessages$restore$es._(this._root);

  final AppMessagesEs _root; // ignore: unused_field

  // Translations
  @override
  String get selectFile => 'Select file';
  @override
  String get dropFileHere => 'Arrastre un fichero aquí';
  @override
  String get errorLoadingFile => 'Error cargando archivo';
  @override
  String get errorDecodingFile =>
      'Error decodificando el archivo (No es el archivo correcto)';
  @override
  String restoreSummary({required Object count}) => 'Se crearán ${count} rutas';
  @override
  String restoreDuplicates({required Object names}) =>
      'Nombres duplicados, no se crearía ninguna ruta: ${names}';
}

// Path: logs
class AppMessages$logs$es implements AppMessages$logs$en {
  AppMessages$logs$es._(this._root);

  final AppMessagesEs _root; // ignore: unused_field

  // Translations
  @override
  String get logs => 'Logs http';
  @override
  String get search => 'Buscar contra User Agent, Dirección IP, Path o Ruta';
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
  String get export => 'Exportar';
  @override
  String totalLogs({required Object count}) => '${count} logs';
}

// Path: logDetails
class AppMessages$logDetails$es implements AppMessages$logDetails$en {
  AppMessages$logDetails$es._(this._root);

  final AppMessagesEs _root; // ignore: unused_field

  // Translations
  @override
  String get logDetails => 'Detalles';
  @override
  String get logsDetailsTimestamp => 'Timestamp';
  @override
  String get logsDetailsSourceIp => 'Dirección IP';
  @override
  String get logsDetailsHttpStatus => 'Estado HTTP';
  @override
  String get logsDetailsHttpMethod => 'Método';
  @override
  String get logsDetailsRequestDuration => 'Duración';
  @override
  String get logsDetailsUserAgent => 'User Agent';
  @override
  String get logsDetailsRoute => 'Ruta';
  @override
  String get logsDetailsRouteName => 'Nombre';
  @override
  String get logsDetailsRoutePath => 'Path';
  @override
  String get logsDetailsRouteId => 'Id';
}

// Path: logFilters
class AppMessages$logFilters$es implements AppMessages$logFilters$en {
  AppMessages$logFilters$es._(this._root);

  final AppMessagesEs _root; // ignore: unused_field

  // Translations
  @override
  String get filter => 'Filtrar';
  @override
  String get applyFilters => 'Aplicar filtros';
  @override
  String get clearFilters => 'Limpiar filtros';
  @override
  String get filterHttpStatusLabel => 'Estado HTTP';
  @override
  String get filterHttpStatusHint => '200';
  @override
  String get filterMethodLabel => 'Método HTTP';
  @override
  String get filterMethodHint => 'Seleccione método HTTP (GET, POST)';
  @override
  String get filterRouteLabel => 'Ruta';
  @override
  String get filterRouteHint => 'Selecciona ruta (Admin, Sin-Ruta)';
  @override
  String get filterNoRouteName => 'Sin-Ruta';
  @override
  String get filterDateHint => 'Selecciona fecha';
  @override
  String get filterFromDateLabel => 'Fecha inicial';
  @override
  String get filterToDateLabel => 'Fecha final';
}

/// The flat map containing all translations for locale <es>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on AppMessagesEs {
  dynamic _flatMapFunction(String path) {
    return switch (path) {
      'app.name' => 'Api Gateway',
      'app.needMoreSpace' => 'Se necesita más espacio',
      'app.consoleVersion' => ({
        required Object version,
      }) => 'Consola v${version}',
      'common.loading' => 'Cargando',
      'common.noAccess' => 'Usted no tiene acceso a esta funcionalidad',
      'actions.backup' => 'Backup',
      'actions.restore' => 'Restaurar',
      'actions.create' => 'Crear',
      'actions.edit' => 'Editar',
      'actions.duplicate' => 'Duplicar',
      'actions.delete' => 'Eliminar',
      'actions.tryAgain' => 'Intentar nuevamente',
      'actions.cancel' => 'Cancelar',
      'actions.deleteRouteConfirm' => ({
        required Object name,
      }) => '¿Eliminar la ruta "${name}"? Esta acción no se puede deshacer.',
      'actions.back' => 'Regresar',
      'actions.copiedToClipboard' => 'Copiado al portapapeles',
      'actions.copy' => 'Copiar',
      'actions.refresh' => 'Refrescar',
      'validations.requiredField' => 'Campo requerido',
      'validations.validUriField' => 'Debe ser una URL válida',
      'validations.wholeNumberField' => 'Debe ser un número entero',
      'errors.requestCancelled' => 'Se canceló la petición al servidor',
      'errors.connectionTimeout' => 'Tiempo de conexión agotado con el servidor. Revisa tu conexión a internet',
      'errors.noConnection' =>
        'No se pudo conectar con el servidor. Revisa tu conexión a internet',
      'errors.receiveTimeout' =>
        'Tiempo de espera agotado recibiendo la respuesta del servidor',
      'errors.sendTimeout' =>
        'Tiempo de espera agotado enviando la petición al servidor',
      'errors.transformTimeout' =>
        'Tiempo de espera agotado procesando la respuesta del servidor',
      'errors.badCertificate' => 'Certificado no válido',
      'errors.connection' => 'Error de conexión',
      'errors.validation' => 'Error de validación',
      'errors.auth' => 'Error de autenticación',
      'errors.server' => 'Error del servidor',
      'errors.unknown' => 'Error desconocido',
      'errors.status' => ({required Object status}) => 'Error ${status}',
      'errors.noData' => 'No hay datos',
      'errors.genericError' => 'Algo ha salido mal',
      'errors.errorWrongRouteId' => 'Id de ruta incorrecto',
      'errors.errorLoadingRoute' => ({
        required Object id,
        required Object message,
      }) => 'Error cargando la ruta ${id}. ${message}',
      'errors.errorUnsupportedAction' => 'Acción no soportada',
      'login.usernameLabel' => 'Nombre de usuario',
      'login.usernameHint' => 'admin',
      'login.passwordLabel' => 'Contraseña',
      'login.passwordHint' => 'admin123**',
      'login.login' => 'Login',
      'login.rememberMe' => 'Recordarme',
      'login.rememberMeWarning' => 'Su sesión seguirá abierta en este navegador hasta que caduque. Úselo solo en un equipo de confianza.',
      'login.gatewayReachable' => 'Gateway accesible',
      'login.gatewayUnreachable' => 'Gateway no accesible',
      'routes.routes' => 'Rutas',
      'routes.requestTo' => 'Cualquier petición a:',
      'routes.redirectedTo' => 'Es redirigida a:',
      'routes.nameLabel' => 'Nombre',
      'routes.nameHint' => 'Service-A',
      'routes.pathLabel' => 'Path',
      'routes.pathHint' => '/test-service/**',
      'routes.uriLabel' => 'URI',
      'routes.uriHint' => 'http://localhost:8080',
      'routes.rewritePathFromLabel' => 'Reescribie Path de',
      'routes.rewritePathFromHint' => '/some-path/',
      'routes.rewritePathToLabel' => 'Reescribie Path a',
      'routes.rewritePathToHint' => '/',
      'routes.preview' => 'Previsualizar',
      'routes.descriptionLabel' => 'Descripción',
      'routes.descriptionHint' => 'Para qué sirve esta ruta (opcional)',
      'routes.searchRoutes' => 'Buscar por nombre, path o URI',
      'routes.advancedTitle' => 'Avanzado',
      'routes.orderLabel' => 'Orden (el menor se evalúa primero)',
      'routes.orderHint' => '0',
      'routes.methodsLabel' => 'Métodos HTTP (ninguno = cualquier método)',
      'routes.hostsLabel' => 'Hosts (ninguno = cualquier host)',
      'routes.hostHint' => '**.example.com',
      'routes.addHost' => 'Añadir host',
      'routes.headersLabel' =>
        'Headers requeridos (la petición debe cumplirlos todos)',
      'routes.headerNameLabel' => 'Nombre del header',
      'routes.headerNameHint' => 'X-Tenant',
      'routes.headerRegexpLabel' => 'Regexp del valor (opcional)',
      'routes.headerRegexpHint' => 'acme.*',
      'routes.addHeader' => 'Añadir header',
      'routes.filtersLabel' =>
        'Filtros (se aplican en orden, después del rewrite)',
      'routes.filterNameLabel' => 'Filtro',
      'routes.filterNameHint' => 'X-From',
      'routes.filterValueLabel' => 'Valor',
      'routes.filterValueHint' => 'gateway',
      'routes.addFilter' => 'Añadir filtro',
      'restore.selectFile' => 'Select file',
      'restore.dropFileHere' => 'Arrastre un fichero aquí',
      'restore.errorLoadingFile' => 'Error cargando archivo',
      'restore.errorDecodingFile' =>
        'Error decodificando el archivo (No es el archivo correcto)',
      'restore.restoreSummary' => ({
        required Object count,
      }) => 'Se crearán ${count} rutas',
      'restore.restoreDuplicates' => ({
        required Object names,
      }) => 'Nombres duplicados, no se crearía ninguna ruta: ${names}',
      'logs.logs' => 'Logs http',
      'logs.search' => 'Buscar contra User Agent, Dirección IP, Path o Ruta',
      'logs.columnTimestamp' => 'Timestamp',
      'logs.columnMethod' => 'Método',
      'logs.columnPath' => 'Path',
      'logs.columnRoute' => 'Ruta',
      'logs.columnHttpStatus' => 'Estado HTTP',
      'logs.columnRequestDuration' => 'Duración',
      'logs.export' => 'Exportar',
      'logs.totalLogs' => ({required Object count}) => '${count} logs',
      'logDetails.logDetails' => 'Detalles',
      'logDetails.logsDetailsTimestamp' => 'Timestamp',
      'logDetails.logsDetailsSourceIp' => 'Dirección IP',
      'logDetails.logsDetailsHttpStatus' => 'Estado HTTP',
      'logDetails.logsDetailsHttpMethod' => 'Método',
      'logDetails.logsDetailsRequestDuration' => 'Duración',
      'logDetails.logsDetailsUserAgent' => 'User Agent',
      'logDetails.logsDetailsRoute' => 'Ruta',
      'logDetails.logsDetailsRouteName' => 'Nombre',
      'logDetails.logsDetailsRoutePath' => 'Path',
      'logDetails.logsDetailsRouteId' => 'Id',
      'logFilters.filter' => 'Filtrar',
      'logFilters.applyFilters' => 'Aplicar filtros',
      'logFilters.clearFilters' => 'Limpiar filtros',
      'logFilters.filterHttpStatusLabel' => 'Estado HTTP',
      'logFilters.filterHttpStatusHint' => '200',
      'logFilters.filterMethodLabel' => 'Método HTTP',
      'logFilters.filterMethodHint' => 'Seleccione método HTTP (GET, POST)',
      'logFilters.filterRouteLabel' => 'Ruta',
      'logFilters.filterRouteHint' => 'Selecciona ruta (Admin, Sin-Ruta)',
      'logFilters.filterNoRouteName' => 'Sin-Ruta',
      'logFilters.filterDateHint' => 'Selecciona fecha',
      'logFilters.filterFromDateLabel' => 'Fecha inicial',
      'logFilters.filterToDateLabel' => 'Fecha final',
      _ => null,
    };
  }
}
