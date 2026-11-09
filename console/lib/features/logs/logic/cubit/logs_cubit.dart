import 'dart:convert';

import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

RouteLogModel adminRoute = RouteLogModel(
  routeId: '00000000-0000-0000-0000-000000000000',
  routeName: 'Admin',
  routePath: '/${Environment.adminPath}/**',
);

final String noRouteId = 'NO-ROUTE';
//getter so the name follows the current language
RouteLogModel get noRoute => RouteLogModel(
  routeId: noRouteId,
  routeName: app.intl.logFilters.filterNoRouteName,
  routePath: noRouteId,
);

class LogsSearchFilters {
  String? query;
  int? responseCode;
  String? httpMethod;

  ({DateTime? fromDate, DateTime? toDate})? date;

  RouteLogModel? route;

  LogsSearchFilters({
    this.query,
    this.responseCode,
    this.httpMethod,
    this.date,
    this.route,
  });

  int get filterCount =>
      (hasResponseCode ? 1 : 0) +
      (hasHttpMethod ? 1 : 0) +
      (hasDate ? 1 : 0) +
      (hasRoute ? 1 : 0);

  bool get hasResponseCode => responseCode != null;

  bool get hasHttpMethod => httpMethod != null;

  bool get hasDate =>
      date != null && (date?.fromDate != null || date?.toDate != null);

  bool get hasRoute => route != null;

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'responseCode': responseCode,
      'httpMethod': httpMethod,
      'date': {'fromDate': date?.fromDate, 'toDate': date?.toDate},
      'route': route?.toJson(),
    };
  }
}

class LogsCubit extends Cubit<LogsState>
    with GlobalEventBusCommunication<LogsState> {
  static const int defaultPage = 0;
  static const int defaultPageSize = 20;
  static const int exportPageSize = 1000;

  final AuthCubit auth;
  final LogsRepo repo;
  final RoutesRepo routesRepo;

  int currentPage = 0;

  //from the last response's total_pages, not from "page came back short"
  bool hasMorePages = true;

  //total_elements of the last search (with the active filters)
  int totalElements = 0;

  final List<HttpLogModel> items = [];

  final List<RouteLogModel> routes = [];
  final LogsSearchFilters filters = LogsSearchFilters();

  LogsCubit({required this.auth, required this.repo, required this.routesRepo})
    : super(const LogsInitialState()) {
    onBus<LanguageChangedState>((event) {
      _updateRoutes();
    });

    //if a new route is added/edited, update
    onBus<RoutesFormProcessingOKState>((event) {
      _updateRoutes();
    });
    //if a route is deleted, update
    onBus<RoutesDeleteOkState>((event) {
      _updateRoutes();
    });
    //if routes are restored, update
    onBus<RoutesRestoreOkState>((event) {
      _updateRoutes();
    });
  }

  //called on logout: nothing from the previous session must survive
  void reset() {
    items.clear();
    routes.clear();
    currentPage = defaultPage;
    hasMorePages = true;
    totalElements = 0;
    filters
      ..query = null
      ..responseCode = null
      ..httpMethod = null
      ..date = null
      ..route = null;
    emit(const LogsInitialState());
  }

  Future<void> init() async {
    try {
      emit(LogsSearchingState());

      await _updateRoutes();
    } on Exception catch (exc) {
      emit(LogsSearchErrorState(ExceptionConverter.parse(exc)));
      return;
    }

    //always restart from page 0 with the active filters, so "try again" doesn't duplicate items
    return _executeSearchFilters();
  }

  Future<List<HttpLogModel>> fetchNextPage() async {
    HttpLogSearchModel response = await repo.findAll(
      credential: auth.current,
      page: currentPage,
      size: defaultPageSize,
      query: filters.query,
      method: filters.httpMethod,
      responseCode: filters.responseCode,
      fromDate: filters.date?.fromDate,
      toDate: filters.date?.toDate,
      routeId: filters.route?.routeId,
    );
    currentPage++;
    hasMorePages = currentPage < response.totalPages;

    items.addAll(response.pageContent);

    return response.pageContent;
  }

  ///same search and filters from page 0 (logs are written in ~1 s batches, so the newest may take a moment)
  Future refresh() => _executeSearchFilters();

  Future applySearch({required String query}) async {
    filters.query = query;
    return _executeSearchFilters();
  }

  Future applyFilter({
    int? responseCode,
    String? httpMethod,
    DateTime? requestedAt,
    DateTime? fromDate,
    DateTime? toDate,
    RouteLogModel? route,
  }) async {
    filters.responseCode = responseCode;

    filters.httpMethod = httpMethod;

    DateTime? safeFromDate = (fromDate ?? requestedAt)?.startOfDay;
    DateTime? safeToDate = (toDate ?? requestedAt)?.endOfDay;
    if (safeFromDate != null &&
        safeToDate != null &&
        safeFromDate.isAfter(safeToDate) == true) {
      DateTime tempDate = safeFromDate;
      safeFromDate = safeToDate;
      safeToDate = tempDate;
    }
    filters.date = (fromDate: safeFromDate, toDate: safeToDate);

    filters.route = route;

    return _executeSearchFilters();
  }

  Future updateFilter({
    int? responseCode,
    String? httpMethod,
    DateTime? requestedAt,
    DateTime? fromDate,
    DateTime? toDate,
    RouteLogModel? route,
  }) async {
    if (responseCode != null) {
      filters.responseCode = responseCode;
    }
    if (httpMethod != null) {
      filters.httpMethod = httpMethod;
    }

    if (requestedAt != null || fromDate != null || toDate != null) {
      DateTime? safeFromDate = (fromDate ?? requestedAt)?.startOfDay;
      DateTime? safeToDate = (toDate ?? requestedAt)?.endOfDay;
      if (safeFromDate != null &&
          safeToDate != null &&
          safeFromDate.isAfter(safeToDate) == true) {
        DateTime tempDate = safeFromDate;
        safeFromDate = safeToDate;
        safeToDate = tempDate;
      }
      filters.date = (fromDate: safeFromDate, toDate: safeToDate);
    }
    if (route != null) {
      filters.route = route;
    }

    return _executeSearchFilters();
  }

  Future _executeSearchFilters() async {
    try {
      emit(LogsFilteringState());
      items.clear();

      currentPage = 0;
      HttpLogSearchModel response = await repo.findAll(
        credential: auth.current,
        page: currentPage,
        size: defaultPageSize,
        query: filters.query,
        method: filters.httpMethod,
        responseCode: filters.responseCode,
        fromDate: filters.date?.fromDate,
        toDate: filters.date?.toDate,
        routeId: filters.route?.routeId,
      );
      currentPage++;
      hasMorePages = currentPage < response.totalPages;
      totalElements = response.totalElements;

      items.addAll(response.pageContent);

      emit(LogsSearchOkState(items: items, filters: filters, routes: routes));
    } on Exception catch (exc) {
      emit(LogsSearchErrorState(ExceptionConverter.parse(exc)));
    }
  }

  Future _updateRoutes() async {
    List<RouteModel> rawRoutes = await routesRepo.findAll(
      credential: auth.current,
    );
    routes.clear();
    List<RouteLogModel> tempRoutes = rawRoutes
        .map(
          (e) => RouteLogModel(
            routeId: e.id,
            routeName: e.name,
            routePath: e.path,
          ),
        )
        .toList();
    routes.addAll(tempRoutes);

    routes.add(adminRoute);
    routes.add(noRoute);

    if (filters.route != null && filters.route!.routeId == noRouteId) {
      filters.route = noRoute.copyWith();
    }
  }

  Future export() async {
    try {
      emit(LogsBackupProcessingState());

      //the gateway caps size (MAX_LOGS_SEARCH_SIZE) and truncates silently, so walk every page
      final List<HttpLogModel> all = [];
      int totalElements = 0;
      int page = 0;
      int totalPages = 1;
      while (page < totalPages) {
        HttpLogSearchModel response = await repo.findAll(
          credential: auth.current,
          page: page,
          size: exportPageSize,
          query: filters.query,
          method: filters.httpMethod,
          responseCode: filters.responseCode,
          fromDate: filters.date?.fromDate,
          toDate: filters.date?.toDate,
          routeId: filters.route?.routeId,
        );
        all.addAll(response.pageContent);
        totalElements = response.totalElements;
        totalPages = response.totalPages;
        page++;
      }

      final encoder = const JsonEncoder.withIndent('  ');
      String rawData = encoder.convert({
        'filters': filters.toJson(),
        'data': HttpLogSearchModel(
          page: 0,
          size: all.length,
          totalPages: 1,
          totalElements: totalElements,
          pageContent: all,
        ).toJson(),
      });
      ExportDocument.downloadDocument(
        rawData,
        filename: 'logs-export-${DateTime.now().toString()}.json',
      );

      emit(LogsBackupOkState());
    } on Exception catch (exc) {
      emit(LogsBackupErrorState(ExceptionConverter.parse(exc)));
    }
  }
}

abstract class LogsState {
  const LogsState();
}

class LogsInitialState extends LogsState {
  const LogsInitialState();
}

//------------------------- SEARCH -------------------------\\
abstract class LogsSearchState extends LogsState {
  LogsSearchState();
}

class LogsSearchingState extends LogsSearchState {
  LogsSearchingState();
}

class LogsSearchOkState extends LogsSearchState {
  final LogsSearchFilters filters;
  final List<HttpLogModel> items;

  List<RouteLogModel> routes;

  LogsSearchOkState({
    required this.items,
    required this.filters,
    required this.routes,
  });
}

class LogsSearchErrorState extends LogsSearchState {
  GlobalException exception;

  LogsSearchErrorState(this.exception);
}

//not a LogsSearchState: the screen keeps the current table and only shows the loading overlay
class LogsFilteringState extends LogsState {
  LogsFilteringState();
}

//------------------------- BACKUP -------------------------\\
abstract class LogsBackupState extends LogsState {
  LogsBackupState();
}

class LogsBackupProcessingState extends LogsBackupState {
  LogsBackupProcessingState();
}

class LogsBackupOkState extends LogsBackupState {
  LogsBackupOkState();
}

class LogsBackupErrorState extends LogsBackupState {
  GlobalException exception;

  LogsBackupErrorState(this.exception);
}
