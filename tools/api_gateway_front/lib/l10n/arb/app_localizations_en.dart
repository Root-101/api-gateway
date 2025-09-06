// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get es => 'Spanish';

  @override
  String get en => 'English';

  @override
  String get section_general => '--------- GENERAL ---------';

  @override
  String get loading => 'Loading';

  @override
  String get noAccess => 'You don\'t have access for this feature';

  @override
  String get section_login => '--------- LOGIN ---------';

  @override
  String get usernameLabel => 'Username';

  @override
  String get usernameHint => 'admin';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => 'admin123**';

  @override
  String get login => 'Login';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get section_validations => '--------- VALIDATIONS ---------';

  @override
  String get requiredField => 'Required field';

  @override
  String get section_actions => '--------- ACTIONS ---------';

  @override
  String get backup => 'Backup';

  @override
  String get restore => 'Restore';

  @override
  String get create => 'Create';

  @override
  String get edit => 'Edit';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get delete => 'Delete';

  @override
  String get tryAgain => 'Try again';

  @override
  String get back => 'Go Back';

  @override
  String get section_routes => '--------- ROUTES ---------';

  @override
  String get routes => 'Routes';

  @override
  String get requestTo => 'Any request to:';

  @override
  String get redirectedTo => 'Is redirected to:';

  @override
  String get nameLabel => 'Name';

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
  String get rewritePathFromLabel => 'Rewrite Path From';

  @override
  String get rewritePathFromHint => '/some-path/';

  @override
  String get rewritePathToLabel => 'Rewrite Path To';

  @override
  String get rewritePathToHint => '/';

  @override
  String get preview => 'Preview';

  @override
  String get section_logs => '--------- LOGS ---------';

  @override
  String get logs => 'Http logs';

  @override
  String get search => 'Search';

  @override
  String get columnTimestamp => 'Timestamp';

  @override
  String get columnMethod => 'Method';

  @override
  String get columnPath => 'Path';

  @override
  String get columnRoute => 'Route';

  @override
  String get columnHttpStatus => 'HTTP Status';

  @override
  String get columnRequestDuration => 'Duration';

  @override
  String get export => 'Export';

  @override
  String get section_log_details => '--------- LOG-DETAILS ---------';

  @override
  String get logDetails => 'Details';

  @override
  String get logsDetailsTimestamp => 'Timestamp';

  @override
  String get logsDetailsSourceIp => 'Source IP';

  @override
  String get logsDetailsHttpStatus => 'HTTP Status';

  @override
  String get logsDetailsHttpMethod => 'Method';

  @override
  String get logsDetailsRequestDuration => 'Duration';

  @override
  String get logsDetailsUserAgent => 'User Agent';

  @override
  String get logsDetailsRoute => 'Route';

  @override
  String get logsDetailsRouteName => 'Name';

  @override
  String get logsDetailsRoutePath => 'Path';

  @override
  String get logsDetailsRouteId => 'Id';

  @override
  String get section_log_filters => '--------- LOG-FILTERS ---------';

  @override
  String get filter => 'Filter';

  @override
  String get applyFilters => 'Apply filters';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get filterHttpStatusLabel => 'HTTP Status';

  @override
  String get filterHttpStatusHint => '200';

  @override
  String get filterMethodLabel => 'HTTP Method';

  @override
  String get filterMethodHint => 'Select HTTP Method (GET, POST)';

  @override
  String get filterRouteLabel => 'Route';

  @override
  String get filterRouteHint => 'Select route (Admin, No-Route)';

  @override
  String get filterNoRouteName => 'No-Route';

  @override
  String get filterDateHint => 'Select date';

  @override
  String get filterFromDateLabel => 'From date';

  @override
  String get filterToDateLabel => 'To date';

  @override
  String get section_errors => '--------- ERRORS ---------';

  @override
  String get noData => 'Nothing found here';

  @override
  String get genericError => 'An error has ocurred';

  @override
  String get section_restore => '--------- RESTORE ---------';

  @override
  String get selectFile => 'Select file';

  @override
  String get dropFileHere => 'Drop file here';

  @override
  String get errorLoadingFile => 'Error loading file';

  @override
  String get errorDecodingFile =>
      'Error decoding file (This is not the correct file)';
}
