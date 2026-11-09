///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import

part of 'messages.g.dart';

// Path: <root>
typedef AppMessagesEn = AppMessages; // ignore: unused_element

class AppMessages with BaseTranslations<AppMessagesLocale, AppMessages> {
  /// You can call this constructor and build your own translation instance of this locale.
  /// Constructing via the enum [AppMessagesLocale.build] is preferred.
  AppMessages({
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
             locale: AppMessagesLocale.en,
             overrides: overrides ?? {},
             cardinalResolver: cardinalResolver,
             ordinalResolver: ordinalResolver,
           ) {
    _meta.setFlatMapFunction(_flatMapFunction);
  }

  /// Metadata for the translations of <en>.
  final TranslationMetadata<AppMessagesLocale, AppMessages> _meta;
  @override
  TranslationMetadata<AppMessagesLocale, AppMessages> get $meta => _meta;

  /// Access flat map
  dynamic operator [](String key) => _meta.getTranslation(key);

  late final AppMessages _root = this; // ignore: unused_field

  AppMessages $copyWith({
    TranslationMetadata<AppMessagesLocale, AppMessages>? meta,
  }) => AppMessages(meta: meta ?? this.$meta);

  // Translations
  late final AppMessages$app$en app = AppMessages$app$en._(_root);
  late final AppMessages$common$en common = AppMessages$common$en._(_root);
  late final AppMessages$actions$en actions = AppMessages$actions$en._(_root);
  late final AppMessages$validations$en validations =
      AppMessages$validations$en._(_root);
  late final AppMessages$errors$en errors = AppMessages$errors$en._(_root);
  late final AppMessages$login$en login = AppMessages$login$en._(_root);
  late final AppMessages$routes$en routes = AppMessages$routes$en._(_root);
  late final AppMessages$restore$en restore = AppMessages$restore$en._(_root);
  late final AppMessages$logs$en logs = AppMessages$logs$en._(_root);
  late final AppMessages$logDetails$en logDetails = AppMessages$logDetails$en._(
    _root,
  );
  late final AppMessages$logFilters$en logFilters = AppMessages$logFilters$en._(
    _root,
  );
}

// Path: app
class AppMessages$app$en {
  AppMessages$app$en._(this._root);

  final AppMessages _root; // ignore: unused_field

  // Translations

  /// en: 'Api Gateway'
  String get name => 'Api Gateway';

  /// en: 'Need more space'
  String get needMoreSpace => 'Need more space';

  /// en: 'Console v{version: String}'
  String consoleVersion({required String version}) => 'Console v${version}';
}

// Path: common
class AppMessages$common$en {
  AppMessages$common$en._(this._root);

  final AppMessages _root; // ignore: unused_field

  // Translations

  /// en: 'Loading'
  String get loading => 'Loading';

  /// en: 'You don't have access for this feature'
  String get noAccess => 'You don\'t have access for this feature';
}

// Path: actions
class AppMessages$actions$en {
  AppMessages$actions$en._(this._root);

  final AppMessages _root; // ignore: unused_field

  // Translations

  /// en: 'Backup'
  String get backup => 'Backup';

  /// en: 'Restore'
  String get restore => 'Restore';

  /// en: 'Create'
  String get create => 'Create';

  /// en: 'Edit'
  String get edit => 'Edit';

  /// en: 'Duplicate'
  String get duplicate => 'Duplicate';

  /// en: 'Delete'
  String get delete => 'Delete';

  /// en: 'Try again'
  String get tryAgain => 'Try again';

  /// en: 'Cancel'
  String get cancel => 'Cancel';

  /// en: 'Delete route "{name: String}"? This cannot be undone.'
  String deleteRouteConfirm({required String name}) =>
      'Delete route "${name}"? This cannot be undone.';

  /// en: 'Go Back'
  String get back => 'Go Back';

  /// en: 'Copied to clipboard'
  String get copiedToClipboard => 'Copied to clipboard';

  /// en: 'Copy'
  String get copy => 'Copy';

  /// en: 'Refresh'
  String get refresh => 'Refresh';
}

// Path: validations
class AppMessages$validations$en {
  AppMessages$validations$en._(this._root);

  final AppMessages _root; // ignore: unused_field

  // Translations

  /// en: 'Required field'
  String get requiredField => 'Required field';

  /// en: 'Must be a valid URI'
  String get validUriField => 'Must be a valid URI';
}

// Path: errors
class AppMessages$errors$en {
  AppMessages$errors$en._(this._root);

  final AppMessages _root; // ignore: unused_field

  // Translations

  /// en: 'Request to API server was cancelled'
  String get requestCancelled => 'Request to API server was cancelled';

  /// en: 'Connection timeout with API server. Check your internet connection'
  String get connectionTimeout =>
      'Connection timeout with API server. Check your internet connection';

  /// en: 'Connection to API server failed. Check your internet connection'
  String get noConnection =>
      'Connection to API server failed. Check your internet connection';

  /// en: 'Receive timeout in connection with API server'
  String get receiveTimeout => 'Receive timeout in connection with API server';

  /// en: 'Send timeout with API server'
  String get sendTimeout => 'Send timeout with API server';

  /// en: 'Timeout processing the API server response'
  String get transformTimeout => 'Timeout processing the API server response';

  /// en: 'Bad certificate'
  String get badCertificate => 'Bad certificate';

  /// en: 'Connection error'
  String get connection => 'Connection error';

  /// en: 'Validation error'
  String get validation => 'Validation error';

  /// en: 'Authentication error'
  String get auth => 'Authentication error';

  /// en: 'Server error'
  String get server => 'Server error';

  /// en: 'Unknown error'
  String get unknown => 'Unknown error';

  /// en: 'Error {status: int}'
  String status({required int status}) => 'Error ${status}';

  /// en: 'Nothing found here'
  String get noData => 'Nothing found here';

  /// en: 'An error has ocurred'
  String get genericError => 'An error has ocurred';

  /// en: 'Wrong route id'
  String get errorWrongRouteId => 'Wrong route id';

  /// en: 'Error loading route {id: String}. {message: String}'
  String errorLoadingRoute({required String id, required String message}) =>
      'Error loading route ${id}. ${message}';

  /// en: 'Unsupported action'
  String get errorUnsupportedAction => 'Unsupported action';
}

// Path: login
class AppMessages$login$en {
  AppMessages$login$en._(this._root);

  final AppMessages _root; // ignore: unused_field

  // Translations

  /// en: 'Username'
  String get usernameLabel => 'Username';

  /// en: 'admin'
  String get usernameHint => 'admin';

  /// en: 'Password'
  String get passwordLabel => 'Password';

  /// en: 'admin123**'
  String get passwordHint => 'admin123**';

  /// en: 'Login'
  String get login => 'Login';

  /// en: 'Remember me'
  String get rememberMe => 'Remember me';

  /// en: 'Your password will be stored in this browser. Use it only on a trusted device.'
  String get rememberMeWarning =>
      'Your password will be stored in this browser. Use it only on a trusted device.';

  /// en: 'Gateway reachable'
  String get gatewayReachable => 'Gateway reachable';

  /// en: 'Gateway unreachable'
  String get gatewayUnreachable => 'Gateway unreachable';
}

// Path: routes
class AppMessages$routes$en {
  AppMessages$routes$en._(this._root);

  final AppMessages _root; // ignore: unused_field

  // Translations

  /// en: 'Routes'
  String get routes => 'Routes';

  /// en: 'Any request to:'
  String get requestTo => 'Any request to:';

  /// en: 'Is redirected to:'
  String get redirectedTo => 'Is redirected to:';

  /// en: 'Name'
  String get nameLabel => 'Name';

  /// en: 'Service-A'
  String get nameHint => 'Service-A';

  /// en: 'Path'
  String get pathLabel => 'Path';

  /// en: '/test-service/**'
  String get pathHint => '/test-service/**';

  /// en: 'URI'
  String get uriLabel => 'URI';

  /// en: 'http://localhost:8080'
  String get uriHint => 'http://localhost:8080';

  /// en: 'Rewrite Path From'
  String get rewritePathFromLabel => 'Rewrite Path From';

  /// en: '/some-path/'
  String get rewritePathFromHint => '/some-path/';

  /// en: 'Rewrite Path To'
  String get rewritePathToLabel => 'Rewrite Path To';

  /// en: '/'
  String get rewritePathToHint => '/';

  /// en: 'Preview'
  String get preview => 'Preview';

  /// en: 'Description'
  String get descriptionLabel => 'Description';

  /// en: 'What this route is for (optional)'
  String get descriptionHint => 'What this route is for (optional)';

  /// en: 'Search by name, path or URI'
  String get searchRoutes => 'Search by name, path or URI';
}

// Path: restore
class AppMessages$restore$en {
  AppMessages$restore$en._(this._root);

  final AppMessages _root; // ignore: unused_field

  // Translations

  /// en: 'Select file'
  String get selectFile => 'Select file';

  /// en: 'Drop file here'
  String get dropFileHere => 'Drop file here';

  /// en: 'Error loading file'
  String get errorLoadingFile => 'Error loading file';

  /// en: 'Error decoding file (This is not the correct file)'
  String get errorDecodingFile =>
      'Error decoding file (This is not the correct file)';

  /// en: '{count: int} routes will be created'
  String restoreSummary({required int count}) =>
      '${count} routes will be created';

  /// en: 'Duplicated names, nothing would be created: {names: String}'
  String restoreDuplicates({required String names}) =>
      'Duplicated names, nothing would be created: ${names}';
}

// Path: logs
class AppMessages$logs$en {
  AppMessages$logs$en._(this._root);

  final AppMessages _root; // ignore: unused_field

  // Translations

  /// en: 'Http logs'
  String get logs => 'Http logs';

  /// en: 'Search against User Agent, Source IP, Path or Route'
  String get search => 'Search against User Agent, Source IP, Path or Route';

  /// en: 'Timestamp'
  String get columnTimestamp => 'Timestamp';

  /// en: 'Method'
  String get columnMethod => 'Method';

  /// en: 'Path'
  String get columnPath => 'Path';

  /// en: 'Route'
  String get columnRoute => 'Route';

  /// en: 'HTTP Status'
  String get columnHttpStatus => 'HTTP Status';

  /// en: 'Duration'
  String get columnRequestDuration => 'Duration';

  /// en: 'Export'
  String get export => 'Export';

  /// en: '{count: int} logs'
  String totalLogs({required int count}) => '${count} logs';
}

// Path: logDetails
class AppMessages$logDetails$en {
  AppMessages$logDetails$en._(this._root);

  final AppMessages _root; // ignore: unused_field

  // Translations

  /// en: 'Details'
  String get logDetails => 'Details';

  /// en: 'Timestamp'
  String get logsDetailsTimestamp => 'Timestamp';

  /// en: 'Source IP'
  String get logsDetailsSourceIp => 'Source IP';

  /// en: 'HTTP Status'
  String get logsDetailsHttpStatus => 'HTTP Status';

  /// en: 'Method'
  String get logsDetailsHttpMethod => 'Method';

  /// en: 'Duration'
  String get logsDetailsRequestDuration => 'Duration';

  /// en: 'User Agent'
  String get logsDetailsUserAgent => 'User Agent';

  /// en: 'Route'
  String get logsDetailsRoute => 'Route';

  /// en: 'Name'
  String get logsDetailsRouteName => 'Name';

  /// en: 'Path'
  String get logsDetailsRoutePath => 'Path';

  /// en: 'Id'
  String get logsDetailsRouteId => 'Id';
}

// Path: logFilters
class AppMessages$logFilters$en {
  AppMessages$logFilters$en._(this._root);

  final AppMessages _root; // ignore: unused_field

  // Translations

  /// en: 'Filter'
  String get filter => 'Filter';

  /// en: 'Apply filters'
  String get applyFilters => 'Apply filters';

  /// en: 'Clear filters'
  String get clearFilters => 'Clear filters';

  /// en: 'HTTP Status'
  String get filterHttpStatusLabel => 'HTTP Status';

  /// en: '200'
  String get filterHttpStatusHint => '200';

  /// en: 'HTTP Method'
  String get filterMethodLabel => 'HTTP Method';

  /// en: 'Select HTTP Method (GET, POST)'
  String get filterMethodHint => 'Select HTTP Method (GET, POST)';

  /// en: 'Route'
  String get filterRouteLabel => 'Route';

  /// en: 'Select route (Admin, No-Route)'
  String get filterRouteHint => 'Select route (Admin, No-Route)';

  /// en: 'No-Route'
  String get filterNoRouteName => 'No-Route';

  /// en: 'Select date'
  String get filterDateHint => 'Select date';

  /// en: 'From date'
  String get filterFromDateLabel => 'From date';

  /// en: 'To date'
  String get filterToDateLabel => 'To date';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on AppMessages {
  dynamic _flatMapFunction(String path) {
    return switch (path) {
      'app.name' => 'Api Gateway',
      'app.needMoreSpace' => 'Need more space',
      'app.consoleVersion' => ({
        required String version,
      }) => 'Console v${version}',
      'common.loading' => 'Loading',
      'common.noAccess' => 'You don\'t have access for this feature',
      'actions.backup' => 'Backup',
      'actions.restore' => 'Restore',
      'actions.create' => 'Create',
      'actions.edit' => 'Edit',
      'actions.duplicate' => 'Duplicate',
      'actions.delete' => 'Delete',
      'actions.tryAgain' => 'Try again',
      'actions.cancel' => 'Cancel',
      'actions.deleteRouteConfirm' => ({
        required String name,
      }) => 'Delete route "${name}"? This cannot be undone.',
      'actions.back' => 'Go Back',
      'actions.copiedToClipboard' => 'Copied to clipboard',
      'actions.copy' => 'Copy',
      'actions.refresh' => 'Refresh',
      'validations.requiredField' => 'Required field',
      'validations.validUriField' => 'Must be a valid URI',
      'errors.requestCancelled' => 'Request to API server was cancelled',
      'errors.connectionTimeout' =>
        'Connection timeout with API server. Check your internet connection',
      'errors.noConnection' =>
        'Connection to API server failed. Check your internet connection',
      'errors.receiveTimeout' =>
        'Receive timeout in connection with API server',
      'errors.sendTimeout' => 'Send timeout with API server',
      'errors.transformTimeout' => 'Timeout processing the API server response',
      'errors.badCertificate' => 'Bad certificate',
      'errors.connection' => 'Connection error',
      'errors.validation' => 'Validation error',
      'errors.auth' => 'Authentication error',
      'errors.server' => 'Server error',
      'errors.unknown' => 'Unknown error',
      'errors.status' => ({required int status}) => 'Error ${status}',
      'errors.noData' => 'Nothing found here',
      'errors.genericError' => 'An error has ocurred',
      'errors.errorWrongRouteId' => 'Wrong route id',
      'errors.errorLoadingRoute' => ({
        required String id,
        required String message,
      }) => 'Error loading route ${id}. ${message}',
      'errors.errorUnsupportedAction' => 'Unsupported action',
      'login.usernameLabel' => 'Username',
      'login.usernameHint' => 'admin',
      'login.passwordLabel' => 'Password',
      'login.passwordHint' => 'admin123**',
      'login.login' => 'Login',
      'login.rememberMe' => 'Remember me',
      'login.rememberMeWarning' => 'Your password will be stored in this browser. Use it only on a trusted device.',
      'login.gatewayReachable' => 'Gateway reachable',
      'login.gatewayUnreachable' => 'Gateway unreachable',
      'routes.routes' => 'Routes',
      'routes.requestTo' => 'Any request to:',
      'routes.redirectedTo' => 'Is redirected to:',
      'routes.nameLabel' => 'Name',
      'routes.nameHint' => 'Service-A',
      'routes.pathLabel' => 'Path',
      'routes.pathHint' => '/test-service/**',
      'routes.uriLabel' => 'URI',
      'routes.uriHint' => 'http://localhost:8080',
      'routes.rewritePathFromLabel' => 'Rewrite Path From',
      'routes.rewritePathFromHint' => '/some-path/',
      'routes.rewritePathToLabel' => 'Rewrite Path To',
      'routes.rewritePathToHint' => '/',
      'routes.preview' => 'Preview',
      'routes.descriptionLabel' => 'Description',
      'routes.descriptionHint' => 'What this route is for (optional)',
      'routes.searchRoutes' => 'Search by name, path or URI',
      'restore.selectFile' => 'Select file',
      'restore.dropFileHere' => 'Drop file here',
      'restore.errorLoadingFile' => 'Error loading file',
      'restore.errorDecodingFile' =>
        'Error decoding file (This is not the correct file)',
      'restore.restoreSummary' => ({
        required int count,
      }) => '${count} routes will be created',
      'restore.restoreDuplicates' => ({
        required String names,
      }) => 'Duplicated names, nothing would be created: ${names}',
      'logs.logs' => 'Http logs',
      'logs.search' => 'Search against User Agent, Source IP, Path or Route',
      'logs.columnTimestamp' => 'Timestamp',
      'logs.columnMethod' => 'Method',
      'logs.columnPath' => 'Path',
      'logs.columnRoute' => 'Route',
      'logs.columnHttpStatus' => 'HTTP Status',
      'logs.columnRequestDuration' => 'Duration',
      'logs.export' => 'Export',
      'logs.totalLogs' => ({required int count}) => '${count} logs',
      'logDetails.logDetails' => 'Details',
      'logDetails.logsDetailsTimestamp' => 'Timestamp',
      'logDetails.logsDetailsSourceIp' => 'Source IP',
      'logDetails.logsDetailsHttpStatus' => 'HTTP Status',
      'logDetails.logsDetailsHttpMethod' => 'Method',
      'logDetails.logsDetailsRequestDuration' => 'Duration',
      'logDetails.logsDetailsUserAgent' => 'User Agent',
      'logDetails.logsDetailsRoute' => 'Route',
      'logDetails.logsDetailsRouteName' => 'Name',
      'logDetails.logsDetailsRoutePath' => 'Path',
      'logDetails.logsDetailsRouteId' => 'Id',
      'logFilters.filter' => 'Filter',
      'logFilters.applyFilters' => 'Apply filters',
      'logFilters.clearFilters' => 'Clear filters',
      'logFilters.filterHttpStatusLabel' => 'HTTP Status',
      'logFilters.filterHttpStatusHint' => '200',
      'logFilters.filterMethodLabel' => 'HTTP Method',
      'logFilters.filterMethodHint' => 'Select HTTP Method (GET, POST)',
      'logFilters.filterRouteLabel' => 'Route',
      'logFilters.filterRouteHint' => 'Select route (Admin, No-Route)',
      'logFilters.filterNoRouteName' => 'No-Route',
      'logFilters.filterDateHint' => 'Select date',
      'logFilters.filterFromDateLabel' => 'From date',
      'logFilters.filterToDateLabel' => 'To date',
      _ => null,
    };
  }
}
