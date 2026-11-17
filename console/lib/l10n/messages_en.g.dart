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
  late final AppMessages$maintenance$en maintenance =
      AppMessages$maintenance$en._(_root);
  late final AppMessages$health$en health = AppMessages$health$en._(_root);
  late final AppMessages$map$en map = AppMessages$map$en._(_root);
  late final AppMessages$panel$en panel = AppMessages$panel$en._(_root);
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

  /// en: 'Error loading the route. {message: String}'
  String errorLoadingRoute({required String message}) =>
      'Error loading the route. ${message}';

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

  /// en: 'Go to map'
  String get goToMap => 'Go to map';

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

  /// en: 'PREVIEW'
  String get preview => 'PREVIEW';

  /// en: 'Route name'
  String get previewName => 'Route name';

  /// en: 'Rewrite'
  String get rewrite => 'Rewrite';

  /// en: 'About duplicating {name: String}'
  String aboutDuplicating({required String name}) =>
      'About duplicating ${name}';

  /// en: 'Edit name'
  String get editName => 'Edit name';

  /// en: 'Edit description'
  String get editDescription => 'Edit description';

  /// en: 'Edit path'
  String get editPath => 'Edit path';

  /// en: 'Edit URI'
  String get editUri => 'Edit URI';

  /// en: 'Edit path rewrite'
  String get editRewrite => 'Edit path rewrite';

  /// en: 'Next'
  String get next => 'Next';

  /// en: 'Step {step: int} of 3 · {name: String}'
  String stepOf({required int step, required String name}) =>
      'Step ${step} of 3 · ${name}';

  /// en: 'General'
  String get stepGeneral => 'General';

  /// en: 'How the route shows up in the console'
  String get stepGeneralHint => 'How the route shows up in the console';

  /// en: 'Forwarding'
  String get stepForwarding => 'Forwarding';

  /// en: 'Requests that match the path are sent to the URI'
  String get stepForwardingHint =>
      'Requests that match the path are sent to the URI';

  /// en: 'Path rewrite'
  String get stepRewrite => 'Path rewrite';

  /// en: 'Optional. Swap a prefix of the path before forwarding'
  String get stepRewriteHint =>
      'Optional. Swap a prefix of the path before forwarding';

  /// en: 'A route with this name already exists'
  String get nameTaken => 'A route with this name already exists';
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

// Path: maintenance
class AppMessages$maintenance$en {
  AppMessages$maintenance$en._(this._root);

  final AppMessages _root; // ignore: unused_field

  // Translations

  /// en: 'Maintenance'
  String get maintenance => 'Maintenance';

  /// en: 'MAINT'
  String get tagMaint => 'MAINT';

  /// en: 'PAUSED'
  String get tagPaused => 'PAUSED';

  /// en: 'The gateway is in maintenance.'
  String get bannerTitle => 'The gateway is in maintenance.';

  /// en: 'Every route answers 503. The console and /health keep working.'
  String get bannerDetail =>
      'Every route answers 503. The console and /health keep working.';

  /// en: 'Every route answers 503 until {date: String} (in {left: String}). The console and /health keep working.'
  String bannerUntil({required String date, required String left}) =>
      'Every route answers 503 until ${date} (in ${left}). The console and /health keep working.';

  /// en: 'Every route answers 503 (the return time has passed, it stays on until you turn it off). The console and /health keep working.'
  String get bannerPassed =>
      'Every route answers 503 (the return time has passed, it stays on until you turn it off). The console and /health keep working.';

  /// en: 'Edit'
  String get edit => 'Edit';

  /// en: 'Turn off'
  String get turnOff => 'Turn off';

  /// en: 'The service is under maintenance, try again later'
  String get defaultMessage =>
      'The service is under maintenance, try again later';

  /// en: '{count: int} in maintenance'
  String inCount({required int count}) => '${count} in maintenance';

  /// en: 'IN MAINTENANCE · 503'
  String get cardTitle => 'IN MAINTENANCE · 503';

  /// en: 'Back {date: String}'
  String cardBack({required String date}) => 'Back ${date}';

  /// en: 'No return time'
  String get cardNoTime => 'No return time';

  /// en: 'Add-ons'
  String get addons => 'Add-ons';

  /// en: 'Maintenance · on'
  String get badgeOn => 'Maintenance · on';

  /// en: 'Maintenance · off'
  String get badgeOff => 'Maintenance · off';

  /// en: 'On'
  String get chipOn => 'On';

  /// en: 'Off'
  String get chipOff => 'Off';

  /// en: 'Redirect only'
  String get redirectOnly => 'Redirect only';

  /// en: '"{name: String}": maintenance added'
  String added({required String name}) => '"${name}": maintenance added';

  /// en: '"{name: String}": maintenance saved'
  String saved({required String name}) => '"${name}": maintenance saved';

  /// en: '"{name: String}": maintenance removed'
  String removed({required String name}) => '"${name}": maintenance removed';

  /// en: '"{name: String}" in maintenance'
  String routeOn({required String name}) => '"${name}" in maintenance';

  /// en: '"{name: String}" back in service'
  String routeOff({required String name}) => '"${name}" back in service';

  /// en: 'Gateway maintenance added'
  String get gatewayAdded => 'Gateway maintenance added';

  /// en: 'Gateway maintenance saved'
  String get gatewaySaved => 'Gateway maintenance saved';

  /// en: 'Gateway in maintenance'
  String get gatewayOn => 'Gateway in maintenance';

  /// en: 'Gateway maintenance off'
  String get gatewayOff => 'Gateway maintenance off';
}

// Path: health
class AppMessages$health$en {
  AppMessages$health$en._(this._root);

  final AppMessages _root; // ignore: unused_field

  // Translations

  /// en: 'Health check'
  String get title => 'Health check';

  /// en: 'LIVE'
  String get live => 'LIVE';

  /// en: 'DOWN'
  String get down => 'DOWN';

  /// en: 'OFF'
  String get off => 'OFF';

  /// en: 'Endpoint'
  String get endpoint => 'Endpoint';

  /// en: 'Every'
  String get every => 'Every';

  /// en: 'Last check'
  String get lastCheck => 'Last check';

  /// en: 'Every {time: String}'
  String everyValue({required String time}) => 'Every ${time}';

  /// en: 'Off · every {time: String}'
  String offValue({required String time}) => 'Off · every ${time}';

  /// en: 'Waiting for the first check'
  String get waiting => 'Waiting for the first check';

  /// en: 'Checking…'
  String get checking => 'Checking…';

  /// en: 'Just now'
  String get justNow => 'Just now';

  /// en: '{time: String} ago'
  String ago({required String time}) => '${time} ago';

  /// en: '{ago: String} · {status: int} in {millis: int} ms'
  String answered({
    required String ago,
    required int status,
    required int millis,
  }) => '${ago} · ${status} in ${millis} ms';

  /// en: '{ago: String} · no answer'
  String noAnswer({required String ago}) => '${ago} · no answer';

  /// en: 'Run now'
  String get runNow => 'Run now';

  /// en: 'Called on {host: String}; any 2xx counts as live.'
  String calledOn({required String host}) =>
      'Called on ${host}; any 2xx counts as live.';

  /// en: 'Check every'
  String get checkEvery => 'Check every';

  /// en: 'Check on a schedule'
  String get enabled => 'Check on a schedule';

  /// en: 'Off: no calls, Run now still works.'
  String get enabledHint => 'Off: no calls, Run now still works.';

  /// en: 'Remove health check?'
  String get removeTitle => 'Remove health check?';

  /// en: 'Its endpoint, interval and last result are lost. You can add it again later.'
  String get removeBody =>
      'Its endpoint, interval and last result are lost. You can add it again later.';

  /// en: 'Health check'
  String get add => 'Health check';

  /// en: 'Check a path on a schedule, LIVE or DOWN'
  String get addHint => 'Check a path on a schedule, LIVE or DOWN';

  /// en: 'Health · every {time: String}'
  String badge({required String time}) => 'Health · every ${time}';

  /// en: 'Health · off'
  String get badgeOff => 'Health · off';

  /// en: '{count: int} down'
  String downCount({required int count}) => '${count} down';

  /// en: 'Down'
  String get legendDown => 'Down';

  /// en: '"{name: String}": health check added'
  String added({required String name}) => '"${name}": health check added';

  /// en: '"{name: String}": health check saved'
  String saved({required String name}) => '"${name}": health check saved';

  /// en: '"{name: String}": health check removed'
  String removed({required String name}) => '"${name}": health check removed';
}

// Path: map
class AppMessages$map$en {
  AppMessages$map$en._(this._root);

  final AppMessages _root; // ignore: unused_field

  // Translations

  /// en: 'Gateway map'
  String get title => 'Gateway map';

  /// en: 'Redirect only'
  String get legendRedirect => 'Redirect only';

  /// en: 'Maintenance'
  String get legendMaintenance => 'Maintenance';

  /// en: 'Zoom in'
  String get zoomIn => 'Zoom in';

  /// en: 'Zoom out'
  String get zoomOut => 'Zoom out';

  /// en: 'Fit'
  String get fit => 'Fit';

  /// en: 'Drag to move · scroll to zoom · click a route to configure it'
  String get hint =>
      'Drag to move · scroll to zoom · click a route to configure it';

  /// en: 'Add route'
  String get addRoute => 'Add route';

  /// en: 'No routes yet'
  String get noRoutesYet => 'No routes yet';

  /// en: '1 route'
  String get oneRoute => '1 route';

  /// en: '{count: int} routes'
  String manyRoutes({required int count}) => '${count} routes';

  /// en: 'In maintenance'
  String get gatewayInMaintenance => 'In maintenance';

  /// en: '503 on all {count: int} routes'
  String gatewayAll({required int count}) => '503 on all ${count} routes';
}

// Path: panel
class AppMessages$panel$en {
  AppMessages$panel$en._(this._root);

  final AppMessages _root; // ignore: unused_field

  // Translations

  /// en: 'ROUTE'
  String get route => 'ROUTE';

  /// en: 'GATEWAY'
  String get gateway => 'GATEWAY';

  /// en: 'Where every request comes in'
  String get gatewayDescription => 'Where every request comes in';

  /// en: 'Redirect'
  String get redirect => 'Redirect';

  /// en: 'Open in Routes'
  String get openInRoutes => 'Open in Routes';

  /// en: 'Edit route'
  String get editRoute => 'Edit route';

  /// en: 'Maintenance'
  String get maintenance => 'Maintenance';

  /// en: 'Off · requests are forwarded normally'
  String get offRoute => 'Off · requests are forwarded normally';

  /// en: 'Off · every route forwards normally'
  String get offGateway => 'Off · every route forwards normally';

  /// en: 'On · callers get a 503 with this message'
  String get onRoute => 'On · callers get a 503 with this message';

  /// en: 'On · every route answers 503 with this message'
  String get onGateway => 'On · every route answers 503 with this message';

  /// en: 'On for {time: String}'
  String onFor({required String time}) => 'On for ${time}';

  /// en: 'Last window: {time: String}'
  String lastWindow({required String time}) => 'Last window: ${time}';

  /// en: '503 MESSAGE'
  String get message503 => '503 MESSAGE';

  /// en: 'default'
  String get defaultTag => 'default';

  /// en: 'No return time'
  String get noReturn => 'No return time';

  /// en: 'Back around {date: String}'
  String backAround({required String date}) => 'Back around ${date}';

  /// en: 'Slide right to turn on maintenance'
  String get slideOn => 'Slide right to turn on maintenance';

  /// en: 'Slide left to turn off'
  String get slideOff => 'Slide left to turn off';

  /// en: 'Drag the handle, or use the arrow keys'
  String get slideHint => 'Drag the handle, or use the arrow keys';

  /// en: 'Controlled by the gateway'
  String get locked => 'Controlled by the gateway';

  /// en: 'The whole gateway is in maintenance: every route answers its message until it is turned off.'
  String get lockedHint =>
      'The whole gateway is in maintenance: every route answers its message until it is turned off.';

  /// en: 'Edit'
  String get edit => 'Edit';

  /// en: 'Remove'
  String get remove => 'Remove';

  /// en: 'Remove maintenance?'
  String get removeTitle => 'Remove maintenance?';

  /// en: 'Its message and return time are lost. You can add it again later.'
  String get removeBody =>
      'Its message and return time are lost. You can add it again later.';

  /// en: 'Save'
  String get save => 'Save';

  /// en: 'ADD TO THIS ROUTE'
  String get addToRoute => 'ADD TO THIS ROUTE';

  /// en: 'ADD TO THE GATEWAY'
  String get addToGateway => 'ADD TO THE GATEWAY';

  /// en: 'Maintenance mode'
  String get addMaintenance => 'Maintenance mode';

  /// en: 'Answer 503 with a message while it is on'
  String get addMaintenanceHint => 'Answer 503 with a message while it is on';

  /// en: '503 message'
  String get messageLabel => '503 message';

  /// en: 'Empty: “{text: String}”'
  String messageHint({required String text}) => 'Empty: “${text}”';

  /// en: '{count: int} / {max: int}'
  String count({required int count, required int max}) => '${count} / ${max}';

  /// en: 'At most {max: int} characters.'
  String tooLong({required int max}) => 'At most ${max} characters.';

  /// en: 'Back around'
  String get backLabel => 'Back around';

  /// en: 'Optional. Sent as Retry-After while it is ahead; it never turns off by itself.'
  String get backHint =>
      'Optional. Sent as Retry-After while it is ahead; it never turns off by itself.';

  /// en: 'Pick a date and time'
  String get pickTime => 'Pick a date and time';

  /// en: 'Clear'
  String get clear => 'Clear';
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
        required String message,
      }) => 'Error loading the route. ${message}',
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
      'notFound.goToMap' => 'Go to map',
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
      'form.preview' => 'PREVIEW',
      'form.previewName' => 'Route name',
      'form.rewrite' => 'Rewrite',
      'form.aboutDuplicating' => ({
        required String name,
      }) => 'About duplicating ${name}',
      'form.editName' => 'Edit name',
      'form.editDescription' => 'Edit description',
      'form.editPath' => 'Edit path',
      'form.editUri' => 'Edit URI',
      'form.editRewrite' => 'Edit path rewrite',
      'form.next' => 'Next',
      'form.stepOf' => ({
        required int step,
        required String name,
      }) => 'Step ${step} of 3 · ${name}',
      'form.stepGeneral' => 'General',
      'form.stepGeneralHint' => 'How the route shows up in the console',
      'form.stepForwarding' => 'Forwarding',
      'form.stepForwardingHint' =>
        'Requests that match the path are sent to the URI',
      'form.stepRewrite' => 'Path rewrite',
      'form.stepRewriteHint' =>
        'Optional. Swap a prefix of the path before forwarding',
      'form.nameTaken' => 'A route with this name already exists',
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
      'maintenance.maintenance' => 'Maintenance',
      'maintenance.tagMaint' => 'MAINT',
      'maintenance.tagPaused' => 'PAUSED',
      'maintenance.bannerTitle' => 'The gateway is in maintenance.',
      'maintenance.bannerDetail' =>
        'Every route answers 503. The console and /health keep working.',
      'maintenance.bannerUntil' => ({
        required String date,
        required String left,
      }) => 'Every route answers 503 until ${date} (in ${left}). The console and /health keep working.',
      'maintenance.bannerPassed' => 'Every route answers 503 (the return time has passed, it stays on until you turn it off). The console and /health keep working.',
      'maintenance.edit' => 'Edit',
      'maintenance.turnOff' => 'Turn off',
      'maintenance.defaultMessage' =>
        'The service is under maintenance, try again later',
      'maintenance.inCount' => ({
        required int count,
      }) => '${count} in maintenance',
      'maintenance.cardTitle' => 'IN MAINTENANCE · 503',
      'maintenance.cardBack' => ({required String date}) => 'Back ${date}',
      'maintenance.cardNoTime' => 'No return time',
      'maintenance.addons' => 'Add-ons',
      'maintenance.badgeOn' => 'Maintenance · on',
      'maintenance.badgeOff' => 'Maintenance · off',
      'maintenance.chipOn' => 'On',
      'maintenance.chipOff' => 'Off',
      'maintenance.redirectOnly' => 'Redirect only',
      'maintenance.added' => ({
        required String name,
      }) => '"${name}": maintenance added',
      'maintenance.saved' => ({
        required String name,
      }) => '"${name}": maintenance saved',
      'maintenance.removed' => ({
        required String name,
      }) => '"${name}": maintenance removed',
      'maintenance.routeOn' => ({
        required String name,
      }) => '"${name}" in maintenance',
      'maintenance.routeOff' => ({
        required String name,
      }) => '"${name}" back in service',
      'maintenance.gatewayAdded' => 'Gateway maintenance added',
      'maintenance.gatewaySaved' => 'Gateway maintenance saved',
      'maintenance.gatewayOn' => 'Gateway in maintenance',
      'maintenance.gatewayOff' => 'Gateway maintenance off',
      'health.title' => 'Health check',
      'health.live' => 'LIVE',
      'health.down' => 'DOWN',
      'health.off' => 'OFF',
      'health.endpoint' => 'Endpoint',
      'health.every' => 'Every',
      'health.lastCheck' => 'Last check',
      'health.everyValue' => ({required String time}) => 'Every ${time}',
      'health.offValue' => ({required String time}) => 'Off · every ${time}',
      'health.waiting' => 'Waiting for the first check',
      'health.checking' => 'Checking…',
      'health.justNow' => 'Just now',
      'health.ago' => ({required String time}) => '${time} ago',
      'health.answered' => ({
        required String ago,
        required int status,
        required int millis,
      }) => '${ago} · ${status} in ${millis} ms',
      'health.noAnswer' => ({required String ago}) => '${ago} · no answer',
      'health.runNow' => 'Run now',
      'health.calledOn' => ({
        required String host,
      }) => 'Called on ${host}; any 2xx counts as live.',
      'health.checkEvery' => 'Check every',
      'health.enabled' => 'Check on a schedule',
      'health.enabledHint' => 'Off: no calls, Run now still works.',
      'health.removeTitle' => 'Remove health check?',
      'health.removeBody' => 'Its endpoint, interval and last result are lost. You can add it again later.',
      'health.add' => 'Health check',
      'health.addHint' => 'Check a path on a schedule, LIVE or DOWN',
      'health.badge' => ({required String time}) => 'Health · every ${time}',
      'health.badgeOff' => 'Health · off',
      'health.downCount' => ({required int count}) => '${count} down',
      'health.legendDown' => 'Down',
      'health.added' => ({
        required String name,
      }) => '"${name}": health check added',
      'health.saved' => ({
        required String name,
      }) => '"${name}": health check saved',
      'health.removed' => ({
        required String name,
      }) => '"${name}": health check removed',
      'map.title' => 'Gateway map',
      'map.legendRedirect' => 'Redirect only',
      'map.legendMaintenance' => 'Maintenance',
      'map.zoomIn' => 'Zoom in',
      'map.zoomOut' => 'Zoom out',
      'map.fit' => 'Fit',
      'map.hint' =>
        'Drag to move · scroll to zoom · click a route to configure it',
      'map.addRoute' => 'Add route',
      'map.noRoutesYet' => 'No routes yet',
      'map.oneRoute' => '1 route',
      'map.manyRoutes' => ({required int count}) => '${count} routes',
      'map.gatewayInMaintenance' => 'In maintenance',
      'map.gatewayAll' => ({
        required int count,
      }) => '503 on all ${count} routes',
      'panel.route' => 'ROUTE',
      'panel.gateway' => 'GATEWAY',
      'panel.gatewayDescription' => 'Where every request comes in',
      'panel.redirect' => 'Redirect',
      'panel.openInRoutes' => 'Open in Routes',
      'panel.editRoute' => 'Edit route',
      'panel.maintenance' => 'Maintenance',
      'panel.offRoute' => 'Off · requests are forwarded normally',
      'panel.offGateway' => 'Off · every route forwards normally',
      'panel.onRoute' => 'On · callers get a 503 with this message',
      'panel.onGateway' => 'On · every route answers 503 with this message',
      'panel.onFor' => ({required String time}) => 'On for ${time}',
      'panel.lastWindow' => ({required String time}) => 'Last window: ${time}',
      'panel.message503' => '503 MESSAGE',
      'panel.defaultTag' => 'default',
      'panel.noReturn' => 'No return time',
      'panel.backAround' => ({required String date}) => 'Back around ${date}',
      'panel.slideOn' => 'Slide right to turn on maintenance',
      'panel.slideOff' => 'Slide left to turn off',
      'panel.slideHint' => 'Drag the handle, or use the arrow keys',
      'panel.locked' => 'Controlled by the gateway',
      'panel.lockedHint' => 'The whole gateway is in maintenance: every route answers its message until it is turned off.',
      'panel.edit' => 'Edit',
      'panel.remove' => 'Remove',
      'panel.removeTitle' => 'Remove maintenance?',
      'panel.removeBody' =>
        'Its message and return time are lost. You can add it again later.',
      'panel.save' => 'Save',
      'panel.addToRoute' => 'ADD TO THIS ROUTE',
      'panel.addToGateway' => 'ADD TO THE GATEWAY',
      'panel.addMaintenance' => 'Maintenance mode',
      'panel.addMaintenanceHint' => 'Answer 503 with a message while it is on',
      'panel.messageLabel' => '503 message',
      'panel.messageHint' => ({required String text}) => 'Empty: “${text}”',
      'panel.count' => ({
        required int count,
        required int max,
      }) => '${count} / ${max}',
      'panel.tooLong' => ({required int max}) => 'At most ${max} characters.',
      'panel.backLabel' => 'Back around',
      'panel.backHint' => 'Optional. Sent as Retry-After while it is ahead; it never turns off by itself.',
      'panel.pickTime' => 'Pick a date and time',
      'panel.clear' => 'Clear',
      _ => null,
    };
  }
}
