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
  late final AppMessages$session$en session = AppMessages$session$en._(_root);
  late final AppMessages$offline$en offline = AppMessages$offline$en._(_root);
  late final AppMessages$notFound$en notFound = AppMessages$notFound$en._(
    _root,
  );
  late final AppMessages$routes$en routes = AppMessages$routes$en._(_root);
  late final AppMessages$form$en form = AppMessages$form$en._(_root);
  late final AppMessages$delete$en delete = AppMessages$delete$en._(_root);
  late final AppMessages$restore$en restore = AppMessages$restore$en._(_root);
  late final AppMessages$logs$en logs = AppMessages$logs$en._(_root);
  late final AppMessages$logDetails$en logDetails = AppMessages$logDetails$en._(
    _root,
  );
  late final AppMessages$logFilters$en logFilters = AppMessages$logFilters$en._(
    _root,
  );
  late final AppMessages$calendar$en calendar = AppMessages$calendar$en._(
    _root,
  );
}

// Path: app
class AppMessages$app$en {
  AppMessages$app$en._(this._root);

  final AppMessages _root; // ignore: unused_field

  // Translations

  /// en: 'api-gateway'
  String get name => 'api-gateway';

  /// en: 'Need more space'
  String get needMoreSpace => 'Need more space';

  /// en: 'One route to'
  String get taglineStart => 'One route to';

  /// en: 'rule them all'
  String get taglineEnd => 'rule them all';

  /// en: 'Connecting to the gateway…'
  String get connecting => 'Connecting to the gateway…';

  /// en: 'Language: {name: String}'
  String languageLabel({required String name}) => 'Language: ${name}';

  /// en: 'Logout'
  String get logout => 'Logout';

  /// en: 'Expand menu'
  String get expandMenu => 'Expand menu';

  /// en: 'Collapse menu'
  String get collapseMenu => 'Collapse menu';
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

  /// en: 'Try again'
  String get tryAgain => 'Try again';

  /// en: 'Cancel'
  String get cancel => 'Cancel';

  /// en: 'Close'
  String get close => 'Close';

  /// en: 'Dismiss'
  String get dismiss => 'Dismiss';

  /// en: 'Back'
  String get back => 'Back';

  /// en: 'Copied to clipboard'
  String get copiedToClipboard => 'Copied to clipboard';

  /// en: 'Copy'
  String get copy => 'Copy';

  /// en: 'Refresh'
  String get refresh => 'Refresh';

  /// en: 'Clear search'
  String get clearSearch => 'Clear search';
}

// Path: validations
class AppMessages$validations$en {
  AppMessages$validations$en._(this._root);

  final AppMessages _root; // ignore: unused_field

  // Translations

  /// en: 'Required field'
  String get requiredField => 'Required field';
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

  /// en: 'Password'
  String get passwordLabel => 'Password';

  /// en: 'Login'
  String get login => 'Login';

  /// en: 'Signing in…'
  String get signingIn => 'Signing in…';

  /// en: 'Manage your routes and HTTP logs.'
  String get subtitle => 'Manage your routes and HTTP logs.';

  /// en: 'Show password'
  String get showPassword => 'Show password';

  /// en: 'Hide password'
  String get hidePassword => 'Hide password';

  /// en: 'Remember me'
  String get rememberMe => 'Remember me';

  /// en: 'Your session will stay open in this browser until it expires. Use it only on a trusted device.'
  String get rememberMeWarning =>
      'Your session will stay open in this browser until it expires. Use it only on a trusted device.';

  /// en: 'Gateway reachable'
  String get gatewayReachable => 'Gateway reachable';

  /// en: 'Gateway unreachable'
  String get gatewayUnreachable => 'Gateway unreachable';

  /// en: 'Wrong username or password'
  String get wrongCredentials => 'Wrong username or password';

  /// en: 'Credentials are set by the'
  String get credentialsHintStart => 'Credentials are set by the';

  /// en: 'and'
  String get credentialsHintAnd => 'and';

  /// en: 'environment variables'
  String get credentialsHintEnd => 'environment variables';

  /// en: 'Signed out'
  String get signedOut => 'Signed out';

  /// en: 'Easy redirections'
  String get featureRedirections => 'Easy redirections';

  /// en: 'HTTP logs'
  String get featureLogs => 'HTTP logs';

  /// en: 'Backup & restore'
  String get featureBackup => 'Backup & restore';
}

// Path: session
class AppMessages$session$en {
  AppMessages$session$en._(this._root);

  final AppMessages _root; // ignore: unused_field

  // Translations

  /// en: 'Your session expired'
  String get title => 'Your session expired';

  /// en: 'Your session has ended. Sign in again to continue where you left off.'
  String get description =>
      'Your session has ended. Sign in again to continue where you left off.';

  /// en: 'Enter your password'
  String get passwordHint => 'Enter your password';

  /// en: 'Wrong password, try again.'
  String get wrongPassword => 'Wrong password, try again.';

  /// en: 'Sign in'
  String get signIn => 'Sign in';

  /// en: 'Go to the login page'
  String get goToLogin => 'Go to the login page';
}

// Path: offline
class AppMessages$offline$en {
  AppMessages$offline$en._(this._root);

  final AppMessages _root; // ignore: unused_field

  // Translations

  /// en: 'Can’t reach the gateway.'
  String get title => 'Can’t reach the gateway.';

  /// en: 'Showing what was loaded at {time: String}. Routing keeps working on the server.'
  String detail({required String time}) =>
      'Showing what was loaded at ${time}. Routing keeps working on the server.';

  /// en: 'Retrying automatically every 10 s.'
  String get retryAuto => 'Retrying automatically every 10 s.';

  /// en: 'Trying to reconnect…'
  String get retrying => 'Trying to reconnect…';

  /// en: 'Retry now'
  String get retryNow => 'Retry now';

  /// en: 'Retrying…'
  String get retryingButton => 'Retrying…';

  /// en: 'Connection restored'
  String get restored => 'Connection restored';
}

// Path: notFound
class AppMessages$notFound$en {
  AppMessages$notFound$en._(this._root);

  final AppMessages _root; // ignore: unused_field

  // Translations

  /// en: 'This page doesn’t exist'
  String get title => 'This page doesn’t exist';

  /// en: 'The route or log may have been deleted, or the link is wrong.'
  String get description =>
      'The route or log may have been deleted, or the link is wrong.';

  /// en: 'Go to Routes'
  String get goToRoutes => 'Go to Routes';

  /// en: 'Open Http logs'
  String get openLogs => 'Open Http logs';
}

// Path: routes
class AppMessages$routes$en {
  AppMessages$routes$en._(this._root);

  final AppMessages _root; // ignore: unused_field

  // Translations

  /// en: 'Routes'
  String get routes => 'Routes';

  /// en: '1 route'
  String get oneRoute => '1 route';

  /// en: '{count: int} routes'
  String manyRoutes({required int count}) => '${count} routes';

  /// en: 'Backup'
  String get backup => 'Backup';

  /// en: 'Restore'
  String get restore => 'Restore';

  /// en: 'Create route'
  String get createRoute => 'Create route';

  /// en: 'Edit route'
  String get editRoute => 'Edit route';

  /// en: 'Duplicate route'
  String get duplicateRoute => 'Duplicate route';

  /// en: 'Edit'
  String get edit => 'Edit';

  /// en: 'Duplicate'
  String get duplicate => 'Duplicate';

  /// en: 'Delete'
  String get delete => 'Delete';

  /// en: 'Search by name, path or URI'
  String get search => 'Search by name, path or URI';

  /// en: 'No description'
  String get noDescription => 'No description';

  /// en: 'No routes match "{query: String}"'
  String noMatches({required String query}) => 'No routes match "${query}"';

  /// en: 'No routes yet'
  String get noRoutesYet => 'No routes yet';

  /// en: 'Try another search or create a new route.'
  String get noMatchesHint => 'Try another search or create a new route.';

  /// en: 'FROM'
  String get from => 'FROM';

  /// en: 'TO'
  String get to => 'TO';

  /// en: 'Copy source URL'
  String get copyFrom => 'Copy source URL';

  /// en: 'Copy target URL'
  String get copyTo => 'Copy target URL';

  /// en: 'Backup saved · {count: int} routes'
  String backupSaved({required int count}) => 'Backup saved · ${count} routes';

  /// en: 'Route "{name: String}" created'
  String created({required String name}) => 'Route "${name}" created';

  /// en: 'Route "{name: String}" updated'
  String updated({required String name}) => 'Route "${name}" updated';

  /// en: 'Route "{name: String}" deleted'
  String deleted({required String name}) => 'Route "${name}" deleted';
}

// Path: form
class AppMessages$form$en {
  AppMessages$form$en._(this._root);

  final AppMessages _root; // ignore: unused_field

  // Translations

  /// en: 'Forward matching requests to another service'
  String get createSubtitle => 'Forward matching requests to another service';

  /// en: 'Changes apply to new requests right away'
  String get editSubtitle => 'Changes apply to new requests right away';

  /// en: 'A new route is created from the copy'
  String get duplicateSubtitle => 'A new route is created from the copy';

  /// en: 'Save changes'
  String get saveChanges => 'Save changes';

  /// en: 'You’re duplicating'
  String get duplicatingStart => 'You’re duplicating';

  /// en: '. Review the name, path and URI before saving — two routes with the same path will compete for the same requests.'
  String get duplicatingEnd =>
      '. Review the name, path and URI before saving — two routes with the same path will compete for the same requests.';

  /// en: 'Name'
  String get nameLabel => 'Name';

  /// en: 'e.g. auth'
  String get nameHint => 'e.g. auth';

  /// en: 'Path'
  String get pathLabel => 'Path';

  /// en: '/service/**'
  String get pathHint => '/service/**';

  /// en: 'URI'
  String get uriLabel => 'URI';

  /// en: 'https://service.example.com'
  String get uriHint => 'https://service.example.com';

  /// en: 'Rewrite path from'
  String get rewritePathFromLabel => 'Rewrite path from';

  /// en: '/service/'
  String get rewritePathFromHint => '/service/';

  /// en: 'Rewrite path to'
  String get rewritePathToLabel => 'Rewrite path to';

  /// en: '/'
  String get rewritePathToHint => '/';

  /// en: 'Description'
  String get descriptionLabel => 'Description';

  /// en: 'What this route is for (optional)'
  String get descriptionHint => 'What this route is for (optional)';

  /// en: 'Preview'
  String get preview => 'Preview';

  /// en: 'Route name'
  String get previewName => 'Route name';

  /// en: 'Name is required'
  String get nameRequired => 'Name is required';

  /// en: 'A route with this name already exists'
  String get nameTaken => 'A route with this name already exists';

  /// en: 'Path must start with /'
  String get pathInvalid => 'Path must start with /';

  /// en: 'Enter a valid http(s) URL'
  String get uriInvalid => 'Enter a valid http(s) URL';
}

// Path: delete
class AppMessages$delete$en {
  AppMessages$delete$en._(this._root);

  final AppMessages _root; // ignore: unused_field

  // Translations

  /// en: 'Delete this route?'
  String get title => 'Delete this route?';

  /// en: 'Requests to'
  String get descriptionStart => 'Requests to';

  /// en: 'will stop being forwarded. This cannot be undone.'
  String get descriptionEnd =>
      'will stop being forwarded. This cannot be undone.';

  /// en: 'Delete route'
  String get confirm => 'Delete route';
}

// Path: restore
class AppMessages$restore$en {
  AppMessages$restore$en._(this._root);

  final AppMessages _root; // ignore: unused_field

  // Translations

  /// en: 'Restore routes'
  String get title => 'Restore routes';

  /// en: 'Replaces every current route with the ones in the backup'
  String get subtitle =>
      'Replaces every current route with the ones in the backup';

  /// en: 'Select file'
  String get selectFile => 'Select file';

  /// en: 'Drag a backup file here'
  String get dropFileHere => 'Drag a backup file here';

  /// en: 'Release to load the file'
  String get releaseFile => 'Release to load the file';

  /// en: 'A .json file created with Backup'
  String get hint => 'A .json file created with Backup';

  /// en: '{count: int} routes ready to restore'
  String ready({required int count}) => '${count} routes ready to restore';

  /// en: 'Not a valid routes backup — use a .json list of routes with name, path and uri.'
  String get invalidFile =>
      'Not a valid routes backup — use a .json list of routes with name, path and uri.';

  /// en: 'Duplicated names in the file: {names: String}'
  String duplicatedNames({required String names}) =>
      'Duplicated names in the file: ${names}';

  /// en: 'Replace {current: int} routes with {next: int}?'
  String confirmTitle({required int current, required int next}) =>
      'Replace ${current} routes with ${next}?';

  /// en: 'Every current route is removed and replaced with the ones in'
  String get confirmStart =>
      'Every current route is removed and replaced with the ones in';

  /// en: '. This cannot be undone.'
  String get confirmEnd => '. This cannot be undone.';

  /// en: 'CURRENT · {count: int}'
  String current({required int count}) => 'CURRENT · ${count}';

  /// en: 'FROM BACKUP · {count: int}'
  String fromBackup({required int count}) => 'FROM BACKUP · ${count}';

  /// en: 'Replace routes'
  String get replace => 'Replace routes';

  /// en: 'Restored {count: int} routes'
  String restored({required int count}) => 'Restored ${count} routes';
}

// Path: logs
class AppMessages$logs$en {
  AppMessages$logs$en._(this._root);

  final AppMessages _root; // ignore: unused_field

  // Translations

  /// en: 'Http logs'
  String get logs => 'Http logs';

  /// en: '{count: String} requests captured · newest first'
  String captured({required String count}) =>
      '${count} requests captured · newest first';

  /// en: 'Search by user agent, source IP, path or route'
  String get search => 'Search by user agent, source IP, path or route';

  /// en: 'Export'
  String get export => 'Export';

  /// en: 'Filters'
  String get filters => 'Filters';

  /// en: 'Filters, {count: int} active'
  String filtersActive({required int count}) => 'Filters, ${count} active';

  /// en: 'Remove filter {label: String}'
  String removeFilter({required String label}) => 'Remove filter ${label}';

  /// en: 'TIMESTAMP'
  String get columnTimestamp => 'TIMESTAMP';

  /// en: 'METHOD'
  String get columnMethod => 'METHOD';

  /// en: 'PATH'
  String get columnPath => 'PATH';

  /// en: 'ROUTE'
  String get columnRoute => 'ROUTE';

  /// en: 'STATUS'
  String get columnHttpStatus => 'STATUS';

  /// en: 'DURATION'
  String get columnRequestDuration => 'DURATION';

  /// en: '{ms: int} ms'
  String durationMs({required int ms}) => '${ms} ms';

  /// en: 'No logs match your search or filters'
  String get noMatches => 'No logs match your search or filters';

  /// en: 'Clear search and filters'
  String get clearAll => 'Clear search and filters';

  /// en: 'Loading requests…'
  String get loading => 'Loading requests…';

  /// en: 'Filtering…'
  String get filtering => 'Filtering…';

  /// en: '1 request'
  String get oneRequest => '1 request';

  /// en: '{count: String} requests'
  String manyRequests({required String count}) => '${count} requests';

  /// en: ' match your search and filters'
  String get matchSuffix => ' match your search and filters';

  /// en: ' · click a row to see its details'
  String get rowHint => ' · click a row to see its details';

  /// en: 'Rows per page'
  String get rowsPerPage => 'Rows per page';

  /// en: '{start: String}–{end: String} of {total: String}'
  String range({
    required String start,
    required String end,
    required String total,
  }) => '${start}–${end} of ${total}';

  /// en: '0 of 0'
  String get emptyRange => '0 of 0';

  /// en: 'Previous page'
  String get previousPage => 'Previous page';

  /// en: 'Next page'
  String get nextPage => 'Next page';

  /// en: 'Page {page: int}'
  String page({required int page}) => 'Page ${page}';

  /// en: 'No new requests'
  String get noNewRequests => 'No new requests';

  /// en: 'Showing the newest requests'
  String get refreshed => 'Showing the newest requests';

  /// en: '1 new request'
  String get oneNewRequest => '1 new request';

  /// en: '{count: int} new requests'
  String manyNewRequests({required int count}) => '${count} new requests';

  /// en: 'Exported {count: String} logs as JSON'
  String exported({required String count}) => 'Exported ${count} logs as JSON';

  /// en: 'Exported the newest {count: String} logs as JSON (the export limit). Narrow the filters to export the rest'
  String exportedCapped({required String count}) =>
      'Exported the newest ${count} logs as JSON (the export limit). Narrow the filters to export the rest';
}

// Path: logDetails
class AppMessages$logDetails$en {
  AppMessages$logDetails$en._(this._root);

  final AppMessages _root; // ignore: unused_field

  // Translations

  /// en: 'Request details'
  String get title => 'Request details';

  /// en: 'REQUEST'
  String get request => 'REQUEST';

  /// en: 'ROUTE'
  String get route => 'ROUTE';

  /// en: 'Timestamp'
  String get timestamp => 'Timestamp';

  /// en: 'Source IP'
  String get sourceIp => 'Source IP';

  /// en: 'User agent'
  String get userAgent => 'User agent';

  /// en: 'Name'
  String get routeName => 'Name';

  /// en: 'Path'
  String get routePath => 'Path';

  /// en: 'Id'
  String get routeId => 'Id';

  /// en: 'Open route {name: String}'
  String openRoute({required String name}) => 'Open route ${name}';
}

// Path: logFilters
class AppMessages$logFilters$en {
  AppMessages$logFilters$en._(this._root);

  final AppMessages _root; // ignore: unused_field

  // Translations

  /// en: 'Filter logs'
  String get filter => 'Filter logs';

  /// en: 'Apply filters'
  String get applyFilters => 'Apply filters';

  /// en: 'Clear all'
  String get clearAll => 'Clear all';

  /// en: 'HTTP status'
  String get status => 'HTTP status';

  /// en: 'Exact HTTP status code'
  String get exactCode => 'Exact HTTP status code';

  /// en: 'Other'
  String get exactCodeHint => 'Other';

  /// en: 'HTTP method'
  String get method => 'HTTP method';

  /// en: 'Any'
  String get anyMethod => 'Any';

  /// en: 'Route'
  String get route => 'Route';

  /// en: 'Any route'
  String get anyRoute => 'Any route';

  /// en: 'No-Route'
  String get filterNoRouteName => 'No-Route';

  /// en: 'Date range'
  String get dateRange => 'Date range';

  /// en: 'Any date'
  String get anyDate => 'Any date';

  /// en: 'From {date: String}'
  String chipFrom({required String date}) => 'From ${date}';

  /// en: 'Until {date: String}'
  String chipUntil({required String date}) => 'Until ${date}';
}

// Path: calendar
class AppMessages$calendar$en {
  AppMessages$calendar$en._(this._root);

  final AppMessages _root; // ignore: unused_field

  // Translations

  /// en: 'Select date range'
  String get title => 'Select date range';

  /// en: 'Previous month'
  String get previousMonth => 'Previous month';

  /// en: 'Next month'
  String get nextMonth => 'Next month';

  /// en: 'Today'
  String get today => 'Today';

  /// en: 'Last 7 days'
  String get last7 => 'Last 7 days';

  /// en: 'Last 30 days'
  String get last30 => 'Last 30 days';

  /// en: 'This month'
  String get thisMonth => 'This month';

  /// en: 'Clear'
  String get clear => 'Clear';

  /// en: 'Done'
  String get done => 'Done';

  /// en: 'Mo,Tu,We,Th,Fr,Sa,Su'
  String get weekdays => 'Mo,Tu,We,Th,Fr,Sa,Su';

  /// en: 'Pick a start date'
  String get hintStart => 'Pick a start date';

  /// en: 'Now pick the end date'
  String get hintEnd => 'Now pick the end date';

  /// en: 'Click a day to start a new range'
  String get hintRestart => 'Click a day to start a new range';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on AppMessages {
  dynamic _flatMapFunction(String path) {
    return switch (path) {
      'app.name' => 'api-gateway',
      'app.needMoreSpace' => 'Need more space',
      'app.taglineStart' => 'One route to',
      'app.taglineEnd' => 'rule them all',
      'app.connecting' => 'Connecting to the gateway…',
      'app.languageLabel' => ({required String name}) => 'Language: ${name}',
      'app.logout' => 'Logout',
      'app.expandMenu' => 'Expand menu',
      'app.collapseMenu' => 'Collapse menu',
      'common.loading' => 'Loading',
      'common.noAccess' => 'You don\'t have access for this feature',
      'actions.tryAgain' => 'Try again',
      'actions.cancel' => 'Cancel',
      'actions.close' => 'Close',
      'actions.dismiss' => 'Dismiss',
      'actions.back' => 'Back',
      'actions.copiedToClipboard' => 'Copied to clipboard',
      'actions.copy' => 'Copy',
      'actions.refresh' => 'Refresh',
      'actions.clearSearch' => 'Clear search',
      'validations.requiredField' => 'Required field',
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
      'login.passwordLabel' => 'Password',
      'login.login' => 'Login',
      'login.signingIn' => 'Signing in…',
      'login.subtitle' => 'Manage your routes and HTTP logs.',
      'login.showPassword' => 'Show password',
      'login.hidePassword' => 'Hide password',
      'login.rememberMe' => 'Remember me',
      'login.rememberMeWarning' => 'Your session will stay open in this browser until it expires. Use it only on a trusted device.',
      'login.gatewayReachable' => 'Gateway reachable',
      'login.gatewayUnreachable' => 'Gateway unreachable',
      'login.wrongCredentials' => 'Wrong username or password',
      'login.credentialsHintStart' => 'Credentials are set by the',
      'login.credentialsHintAnd' => 'and',
      'login.credentialsHintEnd' => 'environment variables',
      'login.signedOut' => 'Signed out',
      'login.featureRedirections' => 'Easy redirections',
      'login.featureLogs' => 'HTTP logs',
      'login.featureBackup' => 'Backup & restore',
      'session.title' => 'Your session expired',
      'session.description' =>
        'Your session has ended. Sign in again to continue where you left off.',
      'session.passwordHint' => 'Enter your password',
      'session.wrongPassword' => 'Wrong password, try again.',
      'session.signIn' => 'Sign in',
      'session.goToLogin' => 'Go to the login page',
      'offline.title' => 'Can’t reach the gateway.',
      'offline.detail' => ({
        required String time,
      }) => 'Showing what was loaded at ${time}. Routing keeps working on the server.',
      'offline.retryAuto' => 'Retrying automatically every 10 s.',
      'offline.retrying' => 'Trying to reconnect…',
      'offline.retryNow' => 'Retry now',
      'offline.retryingButton' => 'Retrying…',
      'offline.restored' => 'Connection restored',
      'notFound.title' => 'This page doesn’t exist',
      'notFound.description' =>
        'The route or log may have been deleted, or the link is wrong.',
      'notFound.goToRoutes' => 'Go to Routes',
      'notFound.openLogs' => 'Open Http logs',
      'routes.routes' => 'Routes',
      'routes.oneRoute' => '1 route',
      'routes.manyRoutes' => ({required int count}) => '${count} routes',
      'routes.backup' => 'Backup',
      'routes.restore' => 'Restore',
      'routes.createRoute' => 'Create route',
      'routes.editRoute' => 'Edit route',
      'routes.duplicateRoute' => 'Duplicate route',
      'routes.edit' => 'Edit',
      'routes.duplicate' => 'Duplicate',
      'routes.delete' => 'Delete',
      'routes.search' => 'Search by name, path or URI',
      'routes.noDescription' => 'No description',
      'routes.noMatches' => ({
        required String query,
      }) => 'No routes match "${query}"',
      'routes.noRoutesYet' => 'No routes yet',
      'routes.noMatchesHint' => 'Try another search or create a new route.',
      'routes.from' => 'FROM',
      'routes.to' => 'TO',
      'routes.copyFrom' => 'Copy source URL',
      'routes.copyTo' => 'Copy target URL',
      'routes.backupSaved' => ({
        required int count,
      }) => 'Backup saved · ${count} routes',
      'routes.created' => ({required String name}) => 'Route "${name}" created',
      'routes.updated' => ({required String name}) => 'Route "${name}" updated',
      'routes.deleted' => ({required String name}) => 'Route "${name}" deleted',
      'form.createSubtitle' => 'Forward matching requests to another service',
      'form.editSubtitle' => 'Changes apply to new requests right away',
      'form.duplicateSubtitle' => 'A new route is created from the copy',
      'form.saveChanges' => 'Save changes',
      'form.duplicatingStart' => 'You’re duplicating',
      'form.duplicatingEnd' => '. Review the name, path and URI before saving — two routes with the same path will compete for the same requests.',
      'form.nameLabel' => 'Name',
      'form.nameHint' => 'e.g. auth',
      'form.pathLabel' => 'Path',
      'form.pathHint' => '/service/**',
      'form.uriLabel' => 'URI',
      'form.uriHint' => 'https://service.example.com',
      'form.rewritePathFromLabel' => 'Rewrite path from',
      'form.rewritePathFromHint' => '/service/',
      'form.rewritePathToLabel' => 'Rewrite path to',
      'form.rewritePathToHint' => '/',
      'form.descriptionLabel' => 'Description',
      'form.descriptionHint' => 'What this route is for (optional)',
      'form.preview' => 'Preview',
      'form.previewName' => 'Route name',
      'form.nameRequired' => 'Name is required',
      'form.nameTaken' => 'A route with this name already exists',
      'form.pathInvalid' => 'Path must start with /',
      'form.uriInvalid' => 'Enter a valid http(s) URL',
      'delete.title' => 'Delete this route?',
      'delete.descriptionStart' => 'Requests to',
      'delete.descriptionEnd' =>
        'will stop being forwarded. This cannot be undone.',
      'delete.confirm' => 'Delete route',
      'restore.title' => 'Restore routes',
      'restore.subtitle' =>
        'Replaces every current route with the ones in the backup',
      'restore.selectFile' => 'Select file',
      'restore.dropFileHere' => 'Drag a backup file here',
      'restore.releaseFile' => 'Release to load the file',
      'restore.hint' => 'A .json file created with Backup',
      'restore.ready' => ({
        required int count,
      }) => '${count} routes ready to restore',
      'restore.invalidFile' => 'Not a valid routes backup — use a .json list of routes with name, path and uri.',
      'restore.duplicatedNames' => ({
        required String names,
      }) => 'Duplicated names in the file: ${names}',
      'restore.confirmTitle' => ({
        required int current,
        required int next,
      }) => 'Replace ${current} routes with ${next}?',
      'restore.confirmStart' =>
        'Every current route is removed and replaced with the ones in',
      'restore.confirmEnd' => '. This cannot be undone.',
      'restore.current' => ({required int count}) => 'CURRENT · ${count}',
      'restore.fromBackup' => ({
        required int count,
      }) => 'FROM BACKUP · ${count}',
      'restore.replace' => 'Replace routes',
      'restore.restored' => ({
        required int count,
      }) => 'Restored ${count} routes',
      'logs.logs' => 'Http logs',
      'logs.captured' => ({
        required String count,
      }) => '${count} requests captured · newest first',
      'logs.search' => 'Search by user agent, source IP, path or route',
      'logs.export' => 'Export',
      'logs.filters' => 'Filters',
      'logs.filtersActive' => ({
        required int count,
      }) => 'Filters, ${count} active',
      'logs.removeFilter' => ({
        required String label,
      }) => 'Remove filter ${label}',
      'logs.columnTimestamp' => 'TIMESTAMP',
      'logs.columnMethod' => 'METHOD',
      'logs.columnPath' => 'PATH',
      'logs.columnRoute' => 'ROUTE',
      'logs.columnHttpStatus' => 'STATUS',
      'logs.columnRequestDuration' => 'DURATION',
      'logs.durationMs' => ({required int ms}) => '${ms} ms',
      'logs.noMatches' => 'No logs match your search or filters',
      'logs.clearAll' => 'Clear search and filters',
      'logs.loading' => 'Loading requests…',
      'logs.filtering' => 'Filtering…',
      'logs.oneRequest' => '1 request',
      'logs.manyRequests' => ({required String count}) => '${count} requests',
      'logs.matchSuffix' => ' match your search and filters',
      'logs.rowHint' => ' · click a row to see its details',
      'logs.rowsPerPage' => 'Rows per page',
      'logs.range' => ({
        required String start,
        required String end,
        required String total,
      }) => '${start}–${end} of ${total}',
      'logs.emptyRange' => '0 of 0',
      'logs.previousPage' => 'Previous page',
      'logs.nextPage' => 'Next page',
      'logs.page' => ({required int page}) => 'Page ${page}',
      'logs.noNewRequests' => 'No new requests',
      'logs.refreshed' => 'Showing the newest requests',
      'logs.oneNewRequest' => '1 new request',
      'logs.manyNewRequests' => ({
        required int count,
      }) => '${count} new requests',
      'logs.exported' => ({
        required String count,
      }) => 'Exported ${count} logs as JSON',
      'logs.exportedCapped' => ({
        required String count,
      }) => 'Exported the newest ${count} logs as JSON (the export limit). Narrow the filters to export the rest',
      'logDetails.title' => 'Request details',
      'logDetails.request' => 'REQUEST',
      'logDetails.route' => 'ROUTE',
      'logDetails.timestamp' => 'Timestamp',
      'logDetails.sourceIp' => 'Source IP',
      'logDetails.userAgent' => 'User agent',
      'logDetails.routeName' => 'Name',
      'logDetails.routePath' => 'Path',
      'logDetails.routeId' => 'Id',
      'logDetails.openRoute' => ({
        required String name,
      }) => 'Open route ${name}',
      'logFilters.filter' => 'Filter logs',
      'logFilters.applyFilters' => 'Apply filters',
      'logFilters.clearAll' => 'Clear all',
      'logFilters.status' => 'HTTP status',
      'logFilters.exactCode' => 'Exact HTTP status code',
      'logFilters.exactCodeHint' => 'Other',
      'logFilters.method' => 'HTTP method',
      'logFilters.anyMethod' => 'Any',
      'logFilters.route' => 'Route',
      'logFilters.anyRoute' => 'Any route',
      'logFilters.filterNoRouteName' => 'No-Route',
      'logFilters.dateRange' => 'Date range',
      'logFilters.anyDate' => 'Any date',
      'logFilters.chipFrom' => ({required String date}) => 'From ${date}',
      'logFilters.chipUntil' => ({required String date}) => 'Until ${date}',
      'calendar.title' => 'Select date range',
      'calendar.previousMonth' => 'Previous month',
      'calendar.nextMonth' => 'Next month',
      'calendar.today' => 'Today',
      'calendar.last7' => 'Last 7 days',
      'calendar.last30' => 'Last 30 days',
      'calendar.thisMonth' => 'This month',
      'calendar.clear' => 'Clear',
      'calendar.done' => 'Done',
      'calendar.weekdays' => 'Mo,Tu,We,Th,Fr,Sa,Su',
      'calendar.hintStart' => 'Pick a start date',
      'calendar.hintEnd' => 'Now pick the end date',
      'calendar.hintRestart' => 'Click a day to start a new range',
      _ => null,
    };
  }
}
