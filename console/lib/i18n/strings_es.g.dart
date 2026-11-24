///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import

import 'package:intl/intl.dart';
import 'package:slang/generated.dart';

import 'strings.g.dart';

// Path: <root>
class AppTextsEs
    with BaseTranslations<AppLocale, AppTexts>
    implements AppTexts {
  /// You can call this constructor and build your own translation instance of this locale.
  /// Constructing via the enum [AppLocale.build] is preferred.
  AppTextsEs({
    Map<String, Node>? overrides,
    PluralResolver? cardinalResolver,
    PluralResolver? ordinalResolver,
    TranslationMetadata<AppLocale, AppTexts>? meta,
  }) : assert(
         overrides == null,
         'Set "translation_overrides: true" in order to enable this feature.',
       ),
       _meta =
           meta ??
           TranslationMetadata(
             locale: AppLocale.es,
             overrides: overrides ?? {},
             cardinalResolver: cardinalResolver,
             ordinalResolver: ordinalResolver,
           ) {
    _meta.setFlatMapFunction(_flatMapFunction);
  }

  /// Metadata for the translations of <es>.
  final TranslationMetadata<AppLocale, AppTexts> _meta;
  @override
  TranslationMetadata<AppLocale, AppTexts> get $meta => _meta;

  /// Access flat map
  @override
  dynamic operator [](String key) => _meta.getTranslation(key);

  late final AppTextsEs _root = this; // ignore: unused_field

  @override
  AppTextsEs $copyWith({TranslationMetadata<AppLocale, AppTexts>? meta}) =>
      AppTextsEs(meta: meta ?? this.$meta);

  // Translations
  @override
  late final AppTexts$app$es app = AppTexts$app$es._(_root);
  @override
  late final AppTexts$actions$es actions = AppTexts$actions$es._(_root);
  @override
  late final AppTexts$validations$es validations = AppTexts$validations$es._(
    _root,
  );
  @override
  late final AppTexts$errors$es errors = AppTexts$errors$es._(_root);
  @override
  late final AppTexts$login$es login = AppTexts$login$es._(_root);
  @override
  late final AppTexts$session$es session = AppTexts$session$es._(_root);
  @override
  late final AppTexts$offline$es offline = AppTexts$offline$es._(_root);
  @override
  late final AppTexts$notFound$es notFound = AppTexts$notFound$es._(_root);
  @override
  late final AppTexts$routes$es routes = AppTexts$routes$es._(_root);
  @override
  late final AppTexts$form$es form = AppTexts$form$es._(_root);
  @override
  late final AppTexts$delete$es delete = AppTexts$delete$es._(_root);
  @override
  late final AppTexts$restore$es restore = AppTexts$restore$es._(_root);
  @override
  late final AppTexts$logs$es logs = AppTexts$logs$es._(_root);
  @override
  late final AppTexts$logDetails$es logDetails = AppTexts$logDetails$es._(
    _root,
  );
  @override
  late final AppTexts$logFilters$es logFilters = AppTexts$logFilters$es._(
    _root,
  );
  @override
  late final AppTexts$calendar$es calendar = AppTexts$calendar$es._(_root);
  @override
  late final AppTexts$maintenance$es maintenance = AppTexts$maintenance$es._(
    _root,
  );
  @override
  late final AppTexts$health$es health = AppTexts$health$es._(_root);
  @override
  late final AppTexts$rate$es rate = AppTexts$rate$es._(_root);
  @override
  late final AppTexts$cors$es cors = AppTexts$cors$es._(_root);
  @override
  late final AppTexts$map$es map = AppTexts$map$es._(_root);
  @override
  late final AppTexts$panel$es panel = AppTexts$panel$es._(_root);
  @override
  late final AppTexts$info$es info = AppTexts$info$es._(_root);
}

// Path: app
class AppTexts$app$es implements AppTexts$app$en {
  AppTexts$app$es._(this._root);

  final AppTextsEs _root; // ignore: unused_field

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
  String configError({required Object error}) =>
      'Error de configuración: ${error}';
  @override
  String languageLabel({required Object name}) => 'Idioma: ${name}';
  @override
  String get logout => 'Cerrar sesión';
  @override
  String get expandMenu => 'Expandir menú';
  @override
  String get collapseMenu => 'Contraer menú';
}

// Path: actions
class AppTexts$actions$es implements AppTexts$actions$en {
  AppTexts$actions$es._(this._root);

  final AppTextsEs _root; // ignore: unused_field

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
  String get refresh => 'Actualizar';
  @override
  String get clearSearch => 'Limpiar búsqueda';
}

// Path: validations
class AppTexts$validations$es implements AppTexts$validations$en {
  AppTexts$validations$es._(this._root);

  final AppTextsEs _root; // ignore: unused_field

  // Translations
  @override
  String get requiredField => 'Campo requerido';
}

// Path: errors
class AppTexts$errors$es implements AppTexts$errors$en {
  AppTexts$errors$es._(this._root);

  final AppTextsEs _root; // ignore: unused_field

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
class AppTexts$login$es implements AppTexts$login$en {
  AppTexts$login$es._(this._root);

  final AppTextsEs _root; // ignore: unused_field

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
class AppTexts$session$es implements AppTexts$session$en {
  AppTexts$session$es._(this._root);

  final AppTextsEs _root; // ignore: unused_field

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
class AppTexts$offline$es implements AppTexts$offline$en {
  AppTexts$offline$es._(this._root);

  final AppTextsEs _root; // ignore: unused_field

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
class AppTexts$notFound$es implements AppTexts$notFound$en {
  AppTexts$notFound$es._(this._root);

  final AppTextsEs _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'Esta página no existe';
  @override
  String get description =>
      'La ruta o el log pueden haberse borrado, o el enlace es incorrecto.';
  @override
  String get goToMap => 'Ir al mapa';
  @override
  String get openLogs => 'Abrir Http logs';
}

// Path: routes
class AppTexts$routes$es implements AppTexts$routes$en {
  AppTexts$routes$es._(this._root);

  final AppTextsEs _root; // ignore: unused_field

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
  String backupSaved({required num count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(
        count,
        one: 'Backup guardado · ${count} ruta',
        other: 'Backup guardado · ${count} rutas',
      );
  @override
  String created({required Object name}) => 'Ruta "${name}" creada';
  @override
  String updated({required Object name}) => 'Ruta "${name}" actualizada';
  @override
  String deleted({required Object name}) => 'Ruta "${name}" eliminada';
}

// Path: form
class AppTexts$form$es implements AppTexts$form$en {
  AppTexts$form$es._(this._root);

  final AppTextsEs _root; // ignore: unused_field

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
  String get stepGeneralHint => 'Cómo se ve la ruta en la consola';
  @override
  String get stepForwarding => 'Reenvío';
  @override
  String get stepForwardingHint =>
      'Las peticiones que coinciden con el path se envían a la URI';
  @override
  String get stepRewrite => 'Reescritura del path';
  @override
  String get stepRewriteHint =>
      'Opcional. Cambia un prefijo del path antes de reenviar';
  @override
  String get nameTaken => 'Ya existe una ruta con este nombre';
}

// Path: delete
class AppTexts$delete$es implements AppTexts$delete$en {
  AppTexts$delete$es._(this._root);

  final AppTextsEs _root; // ignore: unused_field

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
class AppTexts$restore$es implements AppTexts$restore$en {
  AppTexts$restore$es._(this._root);

  final AppTextsEs _root; // ignore: unused_field

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
  String ready({required num count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(
        count,
        one: '${count} ruta lista para restaurar',
        other: '${count} rutas listas para restaurar',
      );
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
  String restored({required num count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(
        count,
        one: 'Restaurada ${count} ruta',
        other: 'Restauradas ${count} rutas',
      );
}

// Path: logs
class AppTexts$logs$es implements AppTexts$logs$en {
  AppTexts$logs$es._(this._root);

  final AppTextsEs _root; // ignore: unused_field

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
  String filtersActive({required num count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(
        count,
        one: 'Filtros, ${count} activo',
        other: 'Filtros, ${count} activos',
      );
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
  String matchSuffix({required num count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(
        count,
        one: ' coincide con tu búsqueda y filtros',
        other: ' coinciden con tu búsqueda y filtros',
      );
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
class AppTexts$logDetails$es implements AppTexts$logDetails$en {
  AppTexts$logDetails$es._(this._root);

  final AppTextsEs _root; // ignore: unused_field

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
class AppTexts$logFilters$es implements AppTexts$logFilters$en {
  AppTexts$logFilters$es._(this._root);

  final AppTextsEs _root; // ignore: unused_field

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
class AppTexts$calendar$es implements AppTexts$calendar$en {
  AppTexts$calendar$es._(this._root);

  final AppTextsEs _root; // ignore: unused_field

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

// Path: maintenance
class AppTexts$maintenance$es implements AppTexts$maintenance$en {
  AppTexts$maintenance$es._(this._root);

  final AppTextsEs _root; // ignore: unused_field

  // Translations
  @override
  String get maintenance => 'Mantenimiento';
  @override
  String get tagMaint => 'MANT';
  @override
  String get tagPaused => 'PAUSADA';
  @override
  String get bannerTitle => 'El gateway está en mantenimiento.';
  @override
  String get bannerDetail =>
      'Todas las rutas responden 503. La consola y /health siguen funcionando.';
  @override
  String bannerUntil({required Object date, required Object left}) =>
      'Todas las rutas responden 503 hasta el ${date} (en ${left}). La consola y /health siguen funcionando.';
  @override
  String get bannerPassed =>
      'Todas las rutas responden 503 (la hora de vuelta ya pasó, sigue activo hasta que lo apagues). La consola y /health siguen funcionando.';
  @override
  String get edit => 'Editar';
  @override
  String get turnOff => 'Apagar';
  @override
  String get defaultMessage =>
      'El servicio está en mantenimiento, inténtalo más tarde';
  @override
  String inCount({required Object count}) => '${count} en mantenimiento';
  @override
  String get cardTitle => 'EN MANTENIMIENTO · 503';
  @override
  String cardBack({required Object date}) => 'Vuelve ${date}';
  @override
  String get cardNoTime => 'Sin hora de vuelta';
  @override
  String get addons => 'Add-ons';
  @override
  String get badgeOn => 'Mantenimiento · on';
  @override
  String get badgeOff => 'Mantenimiento · off';
  @override
  String get chipOn => 'On';
  @override
  String get chipOff => 'Off';
  @override
  String get redirectOnly => 'Solo redirección';
  @override
  String added({required Object name}) => '"${name}": mantenimiento añadido';
  @override
  String saved({required Object name}) => '"${name}": mantenimiento guardado';
  @override
  String removed({required Object name}) => '"${name}": mantenimiento quitado';
  @override
  String routeOn({required Object name}) => '"${name}" en mantenimiento';
  @override
  String routeOff({required Object name}) => '"${name}" vuelve a dar servicio';
  @override
  String get gatewayAdded => 'Mantenimiento del gateway añadido';
  @override
  String get gatewaySaved => 'Mantenimiento del gateway guardado';
  @override
  String get gatewayOn => 'Gateway en mantenimiento';
  @override
  String get gatewayOff => 'Mantenimiento del gateway apagado';
  @override
  String get gatewayRemoved => 'Mantenimiento del gateway quitado';
}

// Path: health
class AppTexts$health$es implements AppTexts$health$en {
  AppTexts$health$es._(this._root);

  final AppTextsEs _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'Health check';
  @override
  String get live => 'LIVE';
  @override
  String get down => 'CAÍDA';
  @override
  String get endpoint => 'Endpoint';
  @override
  String get every => 'Cada';
  @override
  String get lastCheck => 'Última';
  @override
  String everyValue({required Object time}) => 'Cada ${time}';
  @override
  String offValue({required Object time}) => 'Apagado · cada ${time}';
  @override
  String get waiting => 'Esperando la primera comprobación';
  @override
  String get checking => 'Comprobando…';
  @override
  String get justNow => 'Ahora mismo';
  @override
  String ago({required Object time}) => 'Hace ${time}';
  @override
  String answered({
    required Object ago,
    required Object status,
    required Object millis,
  }) => '${ago} · ${status} en ${millis} ms';
  @override
  String noAnswer({required Object ago}) => '${ago} · sin respuesta';
  @override
  String get runNow => 'Comprobar ahora';
  @override
  String calledOn({required Object host}) =>
      'Se llama en ${host}; cualquier 2xx cuenta como activo.';
  @override
  String get checkEvery => 'Comprobar cada';
  @override
  String get enabled => 'Comprobar periódicamente';
  @override
  String hintOn({required Object time}) => 'Encendido · se llama cada ${time}';
  @override
  String get hintOff => 'Apagado · solo lo llama Comprobar ahora';
  @override
  String get slideOn => 'Desliza para comprobar periódicamente';
  @override
  String get slideOff => 'Desliza para dejar de comprobar';
  @override
  String get removeTitle => '¿Quitar el health check?';
  @override
  String get removeBody =>
      'Se pierden su endpoint, su intervalo y el último resultado. Puedes volver a añadirlo después.';
  @override
  String get add => 'Health check';
  @override
  String get addHint => 'Comprueba una ruta periódicamente, LIVE o CAÍDA';
  @override
  String badge({required Object time}) => 'Health · cada ${time}';
  @override
  String get badgeOff => 'Health · off';
  @override
  String downCount({required num count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(
        count,
        one: '${count} caída',
        other: '${count} caídas',
      );
  @override
  String get legendDown => 'Caída';
  @override
  String added({required Object name}) => '"${name}": health check añadido';
  @override
  String saved({required Object name}) => '"${name}": health check guardado';
  @override
  String routeOn({required Object name}) => '"${name}": health check encendido';
  @override
  String routeOff({required Object name}) => '"${name}": health check apagado';
  @override
  String removed({required Object name}) => '"${name}": health check quitado';
}

// Path: rate
class AppTexts$rate$es implements AppTexts$rate$en {
  AppTexts$rate$es._(this._root);

  final AppTextsEs _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'Rate limit';
  @override
  String get limit => 'Límite';
  @override
  String get burst => 'Ráfaga';
  @override
  String get overLimit => 'Al pasarlo';
  @override
  String get tooMany => '429 Too Many Requests';
  @override
  String limitValue({required Object limit, required Object period}) =>
      '${limit} peticiones por ${period}, por IP de cliente';
  @override
  String limitValueGateway({required Object limit, required Object period}) =>
      '${limit} peticiones por ${period}, por IP de cliente, en todas las rutas juntas';
  @override
  String burstValue({required Object burst}) => '${burst} a la vez';
  @override
  String get burstSame => 'Igual que el límite';
  @override
  String get second => 'segundo';
  @override
  String get minute => 'minuto';
  @override
  String get hour => 'hora';
  @override
  String get requests => 'Peticiones';
  @override
  String get burstPlaceholder => 'Igual que el límite';
  @override
  String get per => 'Por IP de cliente, cada';
  @override
  String get enabled => 'Limitar peticiones';
  @override
  String get hintOn => 'Encendido · al pasar el límite, 429';
  @override
  String get hintOff => 'Apagado · no se limita nada';
  @override
  String get slideOn => 'Desliza para limitar peticiones';
  @override
  String get slideOff => 'Desliza para dejar de limitar';
  @override
  String get resetHint => 'Al guardar, todas las cuentas vuelven a cero.';
  @override
  String get removeTitle => '¿Quitar el rate limit?';
  @override
  String get removeBody =>
      'Se pierden su límite y su ráfaga. Puedes volver a añadirlo después.';
  @override
  String get add => 'Rate limit';
  @override
  String get addHint => 'Responde 429 al pasar un límite por IP de cliente';
  @override
  String get addHintGateway =>
      'Responde 429 al pasar un límite por IP de cliente, en todas las rutas juntas';
  @override
  String badge({required Object value}) => 'Rate limit · ${value}';
  @override
  String get badgeOff => 'Rate limit · off';
  @override
  String added({required Object name}) => '"${name}": rate limit añadido';
  @override
  String saved({required Object name}) => '"${name}": rate limit guardado';
  @override
  String removed({required Object name}) => '"${name}": rate limit quitado';
  @override
  String routeOn({required Object name}) => '"${name}": rate limit encendido';
  @override
  String routeOff({required Object name}) => '"${name}": rate limit apagado';
  @override
  String get gatewayAdded => 'Rate limit del gateway añadido';
  @override
  String get gatewaySaved => 'Rate limit del gateway guardado';
  @override
  String get gatewayOn => 'Rate limit del gateway encendido';
  @override
  String get gatewayOff => 'Rate limit del gateway apagado';
  @override
  String get gatewayRemoved => 'Rate limit del gateway quitado';
}

// Path: cors
class AppTexts$cors$es implements AppTexts$cors$en {
  AppTexts$cors$es._(this._root);

  final AppTextsEs _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'CORS';
  @override
  String get all => 'TODOS';
  @override
  String get origins => 'Orígenes';
  @override
  String get credentials => 'Credenciales';
  @override
  String get credentialsYes => 'Se envían (cookies, cabeceras de auth)';
  @override
  String get credentialsNo => 'No se envían';
  @override
  String get credentialsGateway => 'No se envían · la API admin usa un token';
  @override
  String get usedByRoutes => 'Las rutas sin CORS propio usan este.';
  @override
  String originsCount({required Object count}) => '${count} orígenes';
  @override
  String get enabled => 'CORS propio';
  @override
  String get hintOn => 'Encendido · se aplican sus propios orígenes';
  @override
  String get hintOff => 'Apagado · se aplica el CORS del gateway';
  @override
  String get slideOn => 'Desliza para usar su propio CORS';
  @override
  String get slideOff => 'Desliza para usar el del gateway';
  @override
  String get originsLabel => 'Orígenes permitidos';
  @override
  String get originsPlaceholder => 'https://app.com y Enter';
  @override
  String get clear => 'Limpiar';
  @override
  String get originsHint =>
      'Un origen exacto, un patrón como https://*.example.com, o * para cualquiera.';
  @override
  String invalidOrigin({required Object origin}) =>
      '${origin}: debe ser * o un origen como https://app.com o https://*.example.com, sin ruta';
  @override
  String removeOrigin({required Object origin}) => 'Quitar ${origin}';
  @override
  String get credentialsSwitch => 'Permitir credenciales';
  @override
  String get credentialsSwitchHint => 'Para servicios con sesión por cookies';
  @override
  String get credentialsNoAll =>
      'No con un origen que deja pasar cualquier sitio (*, o un * en el host que no sea *.dominio.com)';
  @override
  String lockout({required Object origin}) =>
      'Esta consola está en ${origin}, que no está en la lista: al guardar se quedaría sin acceso al gateway.';
  @override
  String get removeTitle => '¿Quitar el CORS?';
  @override
  String get removeBody =>
      'Se pierden sus orígenes y la ruta vuelve a usar el CORS del gateway.';
  @override
  String get add => 'CORS';
  @override
  String get addHint =>
      'Sus propios orígenes permitidos, y cookies si el servicio las necesita';
  @override
  String badge({required Object value}) => 'CORS · ${value}';
  @override
  String get badgeOff => 'CORS · off';
  @override
  String added({required Object name}) => '"${name}": CORS añadido';
  @override
  String saved({required Object name}) => '"${name}": CORS guardado';
  @override
  String removed({required Object name}) =>
      '"${name}": CORS quitado, usa el del gateway';
  @override
  String routeOn({required Object name}) => '"${name}": CORS propio encendido';
  @override
  String routeOff({required Object name}) =>
      '"${name}": CORS propio apagado, usa el del gateway';
  @override
  String get gatewaySaved => 'CORS del gateway guardado';
  @override
  String envMigratedTitle({required Object name}) =>
      'La variable de entorno ${name} ya está en el CORS del gateway.';
  @override
  String get envMigratedDetail =>
      'Sus orígenes pasaron al add-on: edita el CORS aquí. Quita la variable del despliegue y reinicia el gateway para ocultar esto.';
  @override
  String envIgnoredTitle({required Object name}) =>
      'La variable de entorno ${name} está puesta pero se ignora.';
  @override
  String get envIgnoredDetail =>
      'No coincide con el CORS del gateway, que es el que se aplica. Edita el CORS aquí, luego quita la variable del despliegue y reinicia el gateway.';
  @override
  String get envVariable => 'Variable';
  @override
  String get envApplies => 'Se aplica';
  @override
  String get envOpen => 'Editar CORS';
}

// Path: map
class AppTexts$map$es implements AppTexts$map$en {
  AppTexts$map$es._(this._root);

  final AppTextsEs _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'Mapa del gateway';
  @override
  String get legendRedirect => 'Solo redirección';
  @override
  String get legendMaintenance => 'Mantenimiento';
  @override
  String get zoomIn => 'Acercar';
  @override
  String get zoomOut => 'Alejar';
  @override
  String get fit => 'Ajustar';
  @override
  String get hint =>
      'Arrastra para mover · rueda para zoom · clic en una ruta para configurarla';
  @override
  String get addRoute => 'Añadir ruta';
  @override
  String get noRoutesYet => 'Aún no hay rutas';
  @override
  String get oneRoute => '1 ruta';
  @override
  String manyRoutes({required Object count}) => '${count} rutas';
  @override
  String get gatewayInMaintenance => 'En mantenimiento';
  @override
  String gatewayAll({required Object count}) => '503 en las ${count} rutas';
}

// Path: panel
class AppTexts$panel$es implements AppTexts$panel$en {
  AppTexts$panel$es._(this._root);

  final AppTextsEs _root; // ignore: unused_field

  // Translations
  @override
  String get route => 'RUTA';
  @override
  String get gateway => 'GATEWAY';
  @override
  String get gatewayDescription => 'Por donde entra cada petición';
  @override
  String get redirect => 'Redirección';
  @override
  String get openInRoutes => 'Abrir en Rutas';
  @override
  String get editRoute => 'Editar ruta';
  @override
  String get expand => 'Abrir en el panel grande';
  @override
  String get collapse => 'Volver al panel lateral';
  @override
  String get maintenance => 'Mantenimiento';
  @override
  String get offRoute => 'Apagado · las peticiones se reenvían con normalidad';
  @override
  String get offGateway => 'Apagado · todas las rutas reenvían con normalidad';
  @override
  String get onRoute =>
      'Encendido · los clientes reciben un 503 con este mensaje';
  @override
  String get onGateway =>
      'Encendido · todas las rutas responden 503 con este mensaje';
  @override
  String onFor({required Object time}) => 'Encendido desde hace ${time}';
  @override
  String lastWindow({required Object time}) => 'Última ventana: ${time}';
  @override
  String get message503 => 'MENSAJE 503';
  @override
  String get defaultTag => 'por defecto';
  @override
  String get noReturn => 'Sin hora de vuelta';
  @override
  String backAround({required Object date}) => 'Vuelve hacia ${date}';
  @override
  String get slideOn => 'Desliza para encender el mantenimiento';
  @override
  String get slideOff => 'Desliza para apagar';
  @override
  String get slideHint => 'Arrastra el control o usa las flechas';
  @override
  String get locked => 'Lo controla el gateway';
  @override
  String get lockedHint =>
      'Todo el gateway está en mantenimiento: cada ruta responde su mensaje hasta que se apague.';
  @override
  String get edit => 'Editar';
  @override
  String get remove => 'Quitar';
  @override
  String get removeTitle => '¿Quitar el mantenimiento?';
  @override
  String get removeBody =>
      'Se pierden su mensaje y su hora de vuelta. Puedes volver a añadirlo después.';
  @override
  String get save => 'Guardar';
  @override
  String get addToRoute => 'AÑADIR A ESTA RUTA';
  @override
  String get addToGateway => 'AÑADIR AL GATEWAY';
  @override
  String get addMaintenance => 'Modo mantenimiento';
  @override
  String get addMaintenanceHint =>
      'Responde 503 con un mensaje mientras está encendido';
  @override
  String get messageLabel => 'Mensaje 503';
  @override
  String messageHint({required Object text}) => 'Vacío: “${text}”';
  @override
  String count({required Object count, required Object max}) =>
      '${count} / ${max}';
  @override
  String tooLong({required Object max}) => 'Como máximo ${max} caracteres.';
  @override
  String get backLabel => 'Vuelve hacia';
  @override
  String get backHint =>
      'Opcional. Se envía como Retry-After mientras no haya pasado; nunca lo apaga solo.';
  @override
  String get pickTime => 'Elige fecha y hora';
  @override
  String get clear => 'Quitar';
  @override
  String get overview => 'Resumen';
  @override
  String get publicUrl => 'URL pública';
  @override
  String get routes => 'Rutas';
  @override
  String get healthChecked => 'Con health check';
  @override
  String get down => 'Caídas';
  @override
  String get inMaintenance => 'Mantenimiento';
  @override
  String get rateLimited => 'Con rate limit';
  @override
  String get ownCors => 'Con CORS propio';
  @override
  String allRoutes({required Object count}) => 'Las ${count} (gateway)';
}

// Path: info
class AppTexts$info$es implements AppTexts$info$en {
  AppTexts$info$es._(this._root);

  final AppTextsEs _root; // ignore: unused_field

  // Translations
  @override
  String what({required Object name}) => '¿Qué es ${name}?';
  @override
  String get healthTitle => '¿Está arriba el servicio?';
  @override
  String get healthBody =>
      'El gateway llama cada cierto tiempo a una ruta del servicio, como /health. Una respuesta 2xx marca la ruta LIVE; cualquier otra, o ninguna, la marca DOWN.';
  @override
  String get healthNote =>
      'Solo vigila: las peticiones siguen llegando al servicio igual. Para cortarlas, activa el mantenimiento. Comprobar ahora lo hace al momento.';
  @override
  String get maintenanceTitle => 'Ciérrala un rato';
  @override
  String get maintenanceBody =>
      'Mientras está activo, el gateway responde a cada petición de esta ruta con un 503 y tu mensaje, sin llamar al servicio.';
  @override
  String get maintenanceBodyGateway =>
      'Mientras está activo, el gateway responde a cada petición, en todas las rutas, con un 503 y tu mensaje, sin llamar a ningún servicio.';
  @override
  String get maintenanceNote =>
      'Puedes indicar una hora de vuelta para los clientes. Al apagarlo, las peticiones vuelven a pasar.';
  @override
  String get rateTitle => 'Cuántas peticiones por cliente';
  @override
  String get rateBody =>
      'Cada IP de cliente tiene un número de peticiones por segundo, minuto u hora. El burst es cuántas pueden llegar a la vez.';
  @override
  String get rateBodyGateway =>
      'Cada IP de cliente tiene un número de peticiones por segundo, minuto u hora, sumando todas las rutas. El burst es cuántas pueden llegar a la vez.';
  @override
  String get rateNote =>
      'Al pasarse, el gateway responde 429 sin llamar al servicio. Cualquier cambio reinicia los contadores.';
  @override
  String get corsTitle => 'Qué webs pueden llamarla';
  @override
  String get corsBody =>
      'Una página de otro origen solo puede leer las respuestas de esta ruta si su origen está en la lista. Permite credenciales si el servicio usa cookies.';
  @override
  String get corsBodyGateway =>
      'Una página de otro origen solo puede llamar al gateway si su origen está en la lista. Cubre la API admin (esta consola) y todas las rutas sin CORS propio.';
  @override
  String get corsNote =>
      'Solo los navegadores aplican CORS: curl, Postman y los servidores no se ven afectados. El gateway responde él mismo a los preflights.';
}

/// The flat map containing all translations for locale <es>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on AppTextsEs {
  dynamic _flatMapFunction(String path) {
    return switch (path) {
      'app.name' => 'api-gateway',
      'app.needMoreSpace' => 'Se necesita más espacio',
      'app.taglineStart' => 'One route to',
      'app.taglineEnd' => 'rule them all',
      'app.connecting' => 'Conectando con el gateway…',
      'app.configError' => ({
        required Object error,
      }) => 'Error de configuración: ${error}',
      'app.languageLabel' => ({required Object name}) => 'Idioma: ${name}',
      'app.logout' => 'Cerrar sesión',
      'app.expandMenu' => 'Expandir menú',
      'app.collapseMenu' => 'Contraer menú',
      'actions.tryAgain' => 'Reintentar',
      'actions.cancel' => 'Cancelar',
      'actions.close' => 'Cerrar',
      'actions.dismiss' => 'Descartar',
      'actions.back' => 'Atrás',
      'actions.copiedToClipboard' => 'Copiado al portapapeles',
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
      'notFound.goToMap' => 'Ir al mapa',
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
      'routes.backupSaved' =>
        ({required num count}) =>
            (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(
              count,
              one: 'Backup guardado · ${count} ruta',
              other: 'Backup guardado · ${count} rutas',
            ),
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
      'form.stepGeneralHint' => 'Cómo se ve la ruta en la consola',
      'form.stepForwarding' => 'Reenvío',
      'form.stepForwardingHint' =>
        'Las peticiones que coinciden con el path se envían a la URI',
      'form.stepRewrite' => 'Reescritura del path',
      'form.stepRewriteHint' =>
        'Opcional. Cambia un prefijo del path antes de reenviar',
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
      'restore.ready' =>
        ({required num count}) =>
            (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(
              count,
              one: '${count} ruta lista para restaurar',
              other: '${count} rutas listas para restaurar',
            ),
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
      'restore.restored' =>
        ({required num count}) =>
            (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(
              count,
              one: 'Restaurada ${count} ruta',
              other: 'Restauradas ${count} rutas',
            ),
      'logs.logs' => 'Http logs',
      'logs.captured' => ({
        required Object count,
      }) => '${count} peticiones capturadas · las más recientes primero',
      'logs.search' => 'Buscar por user agent, IP de origen, path o ruta',
      'logs.export' => 'Exportar',
      'logs.filters' => 'Filtros',
      'logs.filtersActive' =>
        ({required num count}) =>
            (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(
              count,
              one: 'Filtros, ${count} activo',
              other: 'Filtros, ${count} activos',
            ),
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
      'logs.matchSuffix' =>
        ({required num count}) =>
            (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(
              count,
              one: ' coincide con tu búsqueda y filtros',
              other: ' coinciden con tu búsqueda y filtros',
            ),
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
      'maintenance.maintenance' => 'Mantenimiento',
      'maintenance.tagMaint' => 'MANT',
      'maintenance.tagPaused' => 'PAUSADA',
      'maintenance.bannerTitle' => 'El gateway está en mantenimiento.',
      'maintenance.bannerDetail' => 'Todas las rutas responden 503. La consola y /health siguen funcionando.',
      'maintenance.bannerUntil' => ({
        required Object date,
        required Object left,
      }) => 'Todas las rutas responden 503 hasta el ${date} (en ${left}). La consola y /health siguen funcionando.',
      'maintenance.bannerPassed' => 'Todas las rutas responden 503 (la hora de vuelta ya pasó, sigue activo hasta que lo apagues). La consola y /health siguen funcionando.',
      'maintenance.edit' => 'Editar',
      'maintenance.turnOff' => 'Apagar',
      'maintenance.defaultMessage' =>
        'El servicio está en mantenimiento, inténtalo más tarde',
      'maintenance.inCount' => ({
        required Object count,
      }) => '${count} en mantenimiento',
      'maintenance.cardTitle' => 'EN MANTENIMIENTO · 503',
      'maintenance.cardBack' => ({required Object date}) => 'Vuelve ${date}',
      'maintenance.cardNoTime' => 'Sin hora de vuelta',
      'maintenance.addons' => 'Add-ons',
      'maintenance.badgeOn' => 'Mantenimiento · on',
      'maintenance.badgeOff' => 'Mantenimiento · off',
      'maintenance.chipOn' => 'On',
      'maintenance.chipOff' => 'Off',
      'maintenance.redirectOnly' => 'Solo redirección',
      'maintenance.added' => ({
        required Object name,
      }) => '"${name}": mantenimiento añadido',
      'maintenance.saved' => ({
        required Object name,
      }) => '"${name}": mantenimiento guardado',
      'maintenance.removed' => ({
        required Object name,
      }) => '"${name}": mantenimiento quitado',
      'maintenance.routeOn' => ({
        required Object name,
      }) => '"${name}" en mantenimiento',
      'maintenance.routeOff' => ({
        required Object name,
      }) => '"${name}" vuelve a dar servicio',
      'maintenance.gatewayAdded' => 'Mantenimiento del gateway añadido',
      'maintenance.gatewaySaved' => 'Mantenimiento del gateway guardado',
      'maintenance.gatewayOn' => 'Gateway en mantenimiento',
      'maintenance.gatewayOff' => 'Mantenimiento del gateway apagado',
      'maintenance.gatewayRemoved' => 'Mantenimiento del gateway quitado',
      'health.title' => 'Health check',
      'health.live' => 'LIVE',
      'health.down' => 'CAÍDA',
      'health.endpoint' => 'Endpoint',
      'health.every' => 'Cada',
      'health.lastCheck' => 'Última',
      'health.everyValue' => ({required Object time}) => 'Cada ${time}',
      'health.offValue' => ({required Object time}) => 'Apagado · cada ${time}',
      'health.waiting' => 'Esperando la primera comprobación',
      'health.checking' => 'Comprobando…',
      'health.justNow' => 'Ahora mismo',
      'health.ago' => ({required Object time}) => 'Hace ${time}',
      'health.answered' => ({
        required Object ago,
        required Object status,
        required Object millis,
      }) => '${ago} · ${status} en ${millis} ms',
      'health.noAnswer' => ({required Object ago}) => '${ago} · sin respuesta',
      'health.runNow' => 'Comprobar ahora',
      'health.calledOn' => ({
        required Object host,
      }) => 'Se llama en ${host}; cualquier 2xx cuenta como activo.',
      'health.checkEvery' => 'Comprobar cada',
      'health.enabled' => 'Comprobar periódicamente',
      'health.hintOn' => ({
        required Object time,
      }) => 'Encendido · se llama cada ${time}',
      'health.hintOff' => 'Apagado · solo lo llama Comprobar ahora',
      'health.slideOn' => 'Desliza para comprobar periódicamente',
      'health.slideOff' => 'Desliza para dejar de comprobar',
      'health.removeTitle' => '¿Quitar el health check?',
      'health.removeBody' => 'Se pierden su endpoint, su intervalo y el último resultado. Puedes volver a añadirlo después.',
      'health.add' => 'Health check',
      'health.addHint' => 'Comprueba una ruta periódicamente, LIVE o CAÍDA',
      'health.badge' => ({required Object time}) => 'Health · cada ${time}',
      'health.badgeOff' => 'Health · off',
      'health.downCount' =>
        ({required num count}) =>
            (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(
              count,
              one: '${count} caída',
              other: '${count} caídas',
            ),
      'health.legendDown' => 'Caída',
      'health.added' => ({
        required Object name,
      }) => '"${name}": health check añadido',
      'health.saved' => ({
        required Object name,
      }) => '"${name}": health check guardado',
      'health.routeOn' => ({
        required Object name,
      }) => '"${name}": health check encendido',
      'health.routeOff' => ({
        required Object name,
      }) => '"${name}": health check apagado',
      'health.removed' => ({
        required Object name,
      }) => '"${name}": health check quitado',
      'rate.title' => 'Rate limit',
      'rate.limit' => 'Límite',
      'rate.burst' => 'Ráfaga',
      'rate.overLimit' => 'Al pasarlo',
      'rate.tooMany' => '429 Too Many Requests',
      'rate.limitValue' => ({
        required Object limit,
        required Object period,
      }) => '${limit} peticiones por ${period}, por IP de cliente',
      'rate.limitValueGateway' => ({
        required Object limit,
        required Object period,
      }) => '${limit} peticiones por ${period}, por IP de cliente, en todas las rutas juntas',
      'rate.burstValue' => ({required Object burst}) => '${burst} a la vez',
      'rate.burstSame' => 'Igual que el límite',
      'rate.second' => 'segundo',
      'rate.minute' => 'minuto',
      'rate.hour' => 'hora',
      'rate.requests' => 'Peticiones',
      'rate.burstPlaceholder' => 'Igual que el límite',
      'rate.per' => 'Por IP de cliente, cada',
      'rate.enabled' => 'Limitar peticiones',
      'rate.hintOn' => 'Encendido · al pasar el límite, 429',
      'rate.hintOff' => 'Apagado · no se limita nada',
      'rate.slideOn' => 'Desliza para limitar peticiones',
      'rate.slideOff' => 'Desliza para dejar de limitar',
      'rate.resetHint' => 'Al guardar, todas las cuentas vuelven a cero.',
      'rate.removeTitle' => '¿Quitar el rate limit?',
      'rate.removeBody' =>
        'Se pierden su límite y su ráfaga. Puedes volver a añadirlo después.',
      'rate.add' => 'Rate limit',
      'rate.addHint' => 'Responde 429 al pasar un límite por IP de cliente',
      'rate.addHintGateway' => 'Responde 429 al pasar un límite por IP de cliente, en todas las rutas juntas',
      'rate.badge' => ({required Object value}) => 'Rate limit · ${value}',
      'rate.badgeOff' => 'Rate limit · off',
      'rate.added' => ({
        required Object name,
      }) => '"${name}": rate limit añadido',
      'rate.saved' => ({
        required Object name,
      }) => '"${name}": rate limit guardado',
      'rate.removed' => ({
        required Object name,
      }) => '"${name}": rate limit quitado',
      'rate.routeOn' => ({
        required Object name,
      }) => '"${name}": rate limit encendido',
      'rate.routeOff' => ({
        required Object name,
      }) => '"${name}": rate limit apagado',
      'rate.gatewayAdded' => 'Rate limit del gateway añadido',
      'rate.gatewaySaved' => 'Rate limit del gateway guardado',
      'rate.gatewayOn' => 'Rate limit del gateway encendido',
      'rate.gatewayOff' => 'Rate limit del gateway apagado',
      'rate.gatewayRemoved' => 'Rate limit del gateway quitado',
      'cors.title' => 'CORS',
      'cors.all' => 'TODOS',
      'cors.origins' => 'Orígenes',
      'cors.credentials' => 'Credenciales',
      'cors.credentialsYes' => 'Se envían (cookies, cabeceras de auth)',
      'cors.credentialsNo' => 'No se envían',
      'cors.credentialsGateway' => 'No se envían · la API admin usa un token',
      'cors.usedByRoutes' => 'Las rutas sin CORS propio usan este.',
      'cors.originsCount' => ({required Object count}) => '${count} orígenes',
      'cors.enabled' => 'CORS propio',
      'cors.hintOn' => 'Encendido · se aplican sus propios orígenes',
      'cors.hintOff' => 'Apagado · se aplica el CORS del gateway',
      'cors.slideOn' => 'Desliza para usar su propio CORS',
      'cors.slideOff' => 'Desliza para usar el del gateway',
      'cors.originsLabel' => 'Orígenes permitidos',
      'cors.originsPlaceholder' => 'https://app.com y Enter',
      'cors.clear' => 'Limpiar',
      'cors.originsHint' => 'Un origen exacto, un patrón como https://*.example.com, o * para cualquiera.',
      'cors.invalidOrigin' => ({
        required Object origin,
      }) => '${origin}: debe ser * o un origen como https://app.com o https://*.example.com, sin ruta',
      'cors.removeOrigin' => ({required Object origin}) => 'Quitar ${origin}',
      'cors.credentialsSwitch' => 'Permitir credenciales',
      'cors.credentialsSwitchHint' => 'Para servicios con sesión por cookies',
      'cors.credentialsNoAll' => 'No con un origen que deja pasar cualquier sitio (*, o un * en el host que no sea *.dominio.com)',
      'cors.lockout' => ({
        required Object origin,
      }) => 'Esta consola está en ${origin}, que no está en la lista: al guardar se quedaría sin acceso al gateway.',
      'cors.removeTitle' => '¿Quitar el CORS?',
      'cors.removeBody' =>
        'Se pierden sus orígenes y la ruta vuelve a usar el CORS del gateway.',
      'cors.add' => 'CORS',
      'cors.addHint' => 'Sus propios orígenes permitidos, y cookies si el servicio las necesita',
      'cors.badge' => ({required Object value}) => 'CORS · ${value}',
      'cors.badgeOff' => 'CORS · off',
      'cors.added' => ({required Object name}) => '"${name}": CORS añadido',
      'cors.saved' => ({required Object name}) => '"${name}": CORS guardado',
      'cors.removed' => ({
        required Object name,
      }) => '"${name}": CORS quitado, usa el del gateway',
      'cors.routeOn' => ({
        required Object name,
      }) => '"${name}": CORS propio encendido',
      'cors.routeOff' => ({
        required Object name,
      }) => '"${name}": CORS propio apagado, usa el del gateway',
      'cors.gatewaySaved' => 'CORS del gateway guardado',
      'cors.envMigratedTitle' => ({
        required Object name,
      }) => 'La variable de entorno ${name} ya está en el CORS del gateway.',
      'cors.envMigratedDetail' => 'Sus orígenes pasaron al add-on: edita el CORS aquí. Quita la variable del despliegue y reinicia el gateway para ocultar esto.',
      'cors.envIgnoredTitle' => ({
        required Object name,
      }) => 'La variable de entorno ${name} está puesta pero se ignora.',
      'cors.envIgnoredDetail' => 'No coincide con el CORS del gateway, que es el que se aplica. Edita el CORS aquí, luego quita la variable del despliegue y reinicia el gateway.',
      'cors.envVariable' => 'Variable',
      'cors.envApplies' => 'Se aplica',
      'cors.envOpen' => 'Editar CORS',
      'map.title' => 'Mapa del gateway',
      'map.legendRedirect' => 'Solo redirección',
      'map.legendMaintenance' => 'Mantenimiento',
      'map.zoomIn' => 'Acercar',
      'map.zoomOut' => 'Alejar',
      'map.fit' => 'Ajustar',
      'map.hint' => 'Arrastra para mover · rueda para zoom · clic en una ruta para configurarla',
      'map.addRoute' => 'Añadir ruta',
      'map.noRoutesYet' => 'Aún no hay rutas',
      'map.oneRoute' => '1 ruta',
      'map.manyRoutes' => ({required Object count}) => '${count} rutas',
      'map.gatewayInMaintenance' => 'En mantenimiento',
      'map.gatewayAll' => ({
        required Object count,
      }) => '503 en las ${count} rutas',
      'panel.route' => 'RUTA',
      'panel.gateway' => 'GATEWAY',
      'panel.gatewayDescription' => 'Por donde entra cada petición',
      'panel.redirect' => 'Redirección',
      'panel.openInRoutes' => 'Abrir en Rutas',
      'panel.editRoute' => 'Editar ruta',
      'panel.expand' => 'Abrir en el panel grande',
      'panel.collapse' => 'Volver al panel lateral',
      'panel.maintenance' => 'Mantenimiento',
      'panel.offRoute' => 'Apagado · las peticiones se reenvían con normalidad',
      'panel.offGateway' => 'Apagado · todas las rutas reenvían con normalidad',
      'panel.onRoute' =>
        'Encendido · los clientes reciben un 503 con este mensaje',
      'panel.onGateway' =>
        'Encendido · todas las rutas responden 503 con este mensaje',
      'panel.onFor' => ({
        required Object time,
      }) => 'Encendido desde hace ${time}',
      'panel.lastWindow' => ({
        required Object time,
      }) => 'Última ventana: ${time}',
      'panel.message503' => 'MENSAJE 503',
      'panel.defaultTag' => 'por defecto',
      'panel.noReturn' => 'Sin hora de vuelta',
      'panel.backAround' => ({required Object date}) => 'Vuelve hacia ${date}',
      'panel.slideOn' => 'Desliza para encender el mantenimiento',
      'panel.slideOff' => 'Desliza para apagar',
      'panel.slideHint' => 'Arrastra el control o usa las flechas',
      'panel.locked' => 'Lo controla el gateway',
      'panel.lockedHint' => 'Todo el gateway está en mantenimiento: cada ruta responde su mensaje hasta que se apague.',
      'panel.edit' => 'Editar',
      'panel.remove' => 'Quitar',
      'panel.removeTitle' => '¿Quitar el mantenimiento?',
      'panel.removeBody' => 'Se pierden su mensaje y su hora de vuelta. Puedes volver a añadirlo después.',
      'panel.save' => 'Guardar',
      'panel.addToRoute' => 'AÑADIR A ESTA RUTA',
      'panel.addToGateway' => 'AÑADIR AL GATEWAY',
      'panel.addMaintenance' => 'Modo mantenimiento',
      'panel.addMaintenanceHint' =>
        'Responde 503 con un mensaje mientras está encendido',
      'panel.messageLabel' => 'Mensaje 503',
      'panel.messageHint' => ({required Object text}) => 'Vacío: “${text}”',
      'panel.count' => ({
        required Object count,
        required Object max,
      }) => '${count} / ${max}',
      'panel.tooLong' => ({
        required Object max,
      }) => 'Como máximo ${max} caracteres.',
      'panel.backLabel' => 'Vuelve hacia',
      'panel.backHint' => 'Opcional. Se envía como Retry-After mientras no haya pasado; nunca lo apaga solo.',
      'panel.pickTime' => 'Elige fecha y hora',
      'panel.clear' => 'Quitar',
      'panel.overview' => 'Resumen',
      'panel.publicUrl' => 'URL pública',
      'panel.routes' => 'Rutas',
      'panel.healthChecked' => 'Con health check',
      'panel.down' => 'Caídas',
      'panel.inMaintenance' => 'Mantenimiento',
      'panel.rateLimited' => 'Con rate limit',
      'panel.ownCors' => 'Con CORS propio',
      'panel.allRoutes' => ({
        required Object count,
      }) => 'Las ${count} (gateway)',
      'info.what' => ({required Object name}) => '¿Qué es ${name}?',
      'info.healthTitle' => '¿Está arriba el servicio?',
      'info.healthBody' => 'El gateway llama cada cierto tiempo a una ruta del servicio, como /health. Una respuesta 2xx marca la ruta LIVE; cualquier otra, o ninguna, la marca DOWN.',
      'info.healthNote' => 'Solo vigila: las peticiones siguen llegando al servicio igual. Para cortarlas, activa el mantenimiento. Comprobar ahora lo hace al momento.',
      'info.maintenanceTitle' => 'Ciérrala un rato',
      'info.maintenanceBody' => 'Mientras está activo, el gateway responde a cada petición de esta ruta con un 503 y tu mensaje, sin llamar al servicio.',
      'info.maintenanceBodyGateway' => 'Mientras está activo, el gateway responde a cada petición, en todas las rutas, con un 503 y tu mensaje, sin llamar a ningún servicio.',
      'info.maintenanceNote' => 'Puedes indicar una hora de vuelta para los clientes. Al apagarlo, las peticiones vuelven a pasar.',
      'info.rateTitle' => 'Cuántas peticiones por cliente',
      'info.rateBody' => 'Cada IP de cliente tiene un número de peticiones por segundo, minuto u hora. El burst es cuántas pueden llegar a la vez.',
      'info.rateBodyGateway' => 'Cada IP de cliente tiene un número de peticiones por segundo, minuto u hora, sumando todas las rutas. El burst es cuántas pueden llegar a la vez.',
      'info.rateNote' => 'Al pasarse, el gateway responde 429 sin llamar al servicio. Cualquier cambio reinicia los contadores.',
      'info.corsTitle' => 'Qué webs pueden llamarla',
      'info.corsBody' => 'Una página de otro origen solo puede leer las respuestas de esta ruta si su origen está en la lista. Permite credenciales si el servicio usa cookies.',
      'info.corsBodyGateway' => 'Una página de otro origen solo puede llamar al gateway si su origen está en la lista. Cubre la API admin (esta consola) y todas las rutas sin CORS propio.',
      'info.corsNote' => 'Solo los navegadores aplican CORS: curl, Postman y los servidores no se ven afectados. El gateway responde él mismo a los preflights.',
      _ => null,
    };
  }
}
