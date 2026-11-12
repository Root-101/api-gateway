import 'dart:convert';

import 'package:console/app_exporter.dart';
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

enum LogFilterKind { status, method, route, date }

class LogsSearchFilters {
  String? query;

  ///status prefix: `4` = 4xx, `478` = that exact code
  String? responseCode;
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

  bool get isEmpty => (query ?? '').isEmpty && filterCount == 0;

  Map<String, dynamic> toJson() {
    return {
      'query': query ?? '',
      'responseCode': responseCode,
      'httpMethod': httpMethod,
      'date': {
        'fromDate': date?.fromDate?.toUtc().toIso8601String(),
        'toDate': date?.toDate?.toUtc().toIso8601String(),
      },
      'route': route?.toJson(),
    };
  }
}

class LogsCubit extends Cubit<LogsState>
    with GlobalEventBusCommunication<LogsState> {
  static const int defaultPage = 0;
  static const int defaultPageSize = 10;
  static const int exportPageSize = 1000;

  ///the export stops here: everything is held in browser memory before the download
  static const int exportMaxRows = 100000;

  final LogsRepo repo;
  final RoutesRepo routesRepo;

  int currentPage = defaultPage;
  int pageSize = defaultPageSize;
  int totalPages = 0;

  //total_elements of the last search (with the active filters)
  int totalElements = 0;
  bool totalCapped = false;

  //total_elements of the last search without any filter
  int capturedTotal = 0;
  bool capturedCapped = false;

  ///false until the first page arrives: first load shows the skeleton
  bool loaded = false;

  //only the newest request may publish its result: a slow old search must not overwrite it
  int _lastSearch = 0;

  final List<HttpLogModel> items = [];

  final List<RouteLogModel> routes = [];
  final LogsSearchFilters filters = LogsSearchFilters();

  LogsCubit({required this.repo, required this.routesRepo})
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
    _lastSearch++;
    items.clear();
    routes.clear();
    loaded = false;
    currentPage = defaultPage;
    pageSize = defaultPageSize;
    totalPages = 0;
    totalElements = 0;
    capturedTotal = 0;
    capturedCapped = false;
    _clearFilters();
    emit(const LogsInitialState());
  }

  void _clearFilters() {
    filters
      ..query = null
      ..responseCode = null
      ..httpMethod = null
      ..date = null
      ..route = null;
  }

  Future<void> init() async {
    try {
      emit(LogsSearchingState());

      await _updateRoutes();
    } on Exception catch (exc) {
      emit(LogsSearchErrorState(ExceptionConverter.parse(exc)));
      return;
    }

    return search();
  }

  ///same page, search and filters
  Future<void> search() async {
    final id = ++_lastSearch;
    try {
      emit(LogsFilteringState());

      HttpLogSearchModel response = await repo.findAll(
        page: currentPage,
        size: pageSize,
        query: filters.query,
        method: filters.httpMethod,
        responseCode: filters.responseCode,
        fromDate: filters.date?.fromDate,
        toDate: filters.date?.toDate,
        routeId: filters.route?.routeId,
      );
      if (id != _lastSearch) return;

      totalPages = response.totalPages;
      totalElements = response.totalElements;
      totalCapped = response.totalCapped;
      if (filters.isEmpty) {
        capturedTotal = totalElements;
        capturedCapped = totalCapped;
      }
      items
        ..clear()
        ..addAll(response.pageContent);
      loaded = true;

      emit(LogsSearchOkState(items: items, filters: filters, routes: routes));
    } on Exception catch (exc) {
      if (id != _lastSearch) return;
      emit(LogsSearchErrorState(ExceptionConverter.parse(exc)));
    }
  }

  Future<void> _searchFirstPage() {
    currentPage = defaultPage;
    return search();
  }

  ///back to the newest logs (written in ~1 s batches, so the very last may take a moment);
  ///returns how many arrived since the last search, null when unknown (the count is capped)
  Future<int?> refresh() async {
    final before = totalElements;
    await _searchFirstPage();
    return totalCapped ? null : totalElements - before;
  }

  Future<void> goToPage(int page) {
    currentPage = page;
    return search();
  }

  Future<void> setPageSize(int size) {
    pageSize = size;
    return _searchFirstPage();
  }

  Future<void> applySearch({required String query}) {
    filters.query = query;
    return _searchFirstPage();
  }

  Future<void> applyFilter({
    String? responseCode,
    String? httpMethod,
    DateTime? fromDate,
    DateTime? toDate,
    RouteLogModel? route,
  }) {
    filters.responseCode = responseCode;
    filters.httpMethod = httpMethod;
    filters.date = _dayRange(fromDate, toDate);
    filters.route = route;
    return _searchFirstPage();
  }

  Future<void> removeFilter(LogFilterKind kind) {
    switch (kind) {
      case LogFilterKind.status:
        filters.responseCode = null;
      case LogFilterKind.method:
        filters.httpMethod = null;
      case LogFilterKind.route:
        filters.route = null;
      case LogFilterKind.date:
        filters.date = null;
    }
    return _searchFirstPage();
  }

  Future<void> clearSearchAndFilters() {
    _clearFilters();
    return _searchFirstPage();
  }

  ({DateTime? fromDate, DateTime? toDate}) _dayRange(
    DateTime? from,
    DateTime? to,
  ) {
    //swap before widening to whole days, otherwise the range loses both edge days
    if (from != null && to != null && from.isAfter(to)) {
      (from, to) = (to, from);
    }
    return (fromDate: from?.startOfDay, toDate: to?.endOfDay);
  }

  Future _updateRoutes() async {
    List<RouteModel> rawRoutes = await routesRepo.findAll();
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
    //Admin and No-Route first, like the design's filter dialog
    routes.add(adminRoute);
    routes.add(noRoute);
    routes.addAll(tempRoutes);

    if (filters.route != null && filters.route!.routeId == noRouteId) {
      filters.route = noRoute.copyWith();
    }
  }

  Future export() async {
    try {
      emit(LogsBackupProcessingState());

      //the gateway caps size (MAX_LOGS_SEARCH_SIZE) and truncates silently, so walk every page.
      //`to` is frozen at the start: rows logged meanwhile would shift the offset pages and repeat rows
      final toDate = filters.date?.toDate ?? DateTime.now();
      final List<HttpLogModel> all = [];
      int totalElements = 0;
      int page = 0;
      int totalPages = 1;
      while (page < totalPages && all.length < exportMaxRows) {
        HttpLogSearchModel response = await repo.findAll(
          page: page,
          size: exportPageSize,
          query: filters.query,
          method: filters.httpMethod,
          responseCode: filters.responseCode,
          fromDate: filters.date?.fromDate,
          toDate: toDate,
          routeId: filters.route?.routeId,
        );
        all.addAll(response.pageContent);
        totalElements = response.totalElements;
        totalPages = response.totalPages;
        page++;
      }

      final capped = all.length > exportMaxRows || totalElements > all.length;
      if (all.length > exportMaxRows) {
        all.removeRange(exportMaxRows, all.length);
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
      final stamp = app.dateFormatter.fileStamp.format(DateTime.now());
      ExportDocument.downloadDocument(
        rawData,
        filename: 'logs-export-$stamp.json',
      );

      emit(LogsBackupOkState(all.length, capped: capped));
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

//the screen keeps the current table, dimmed, under the loading bar
class LogsFilteringState extends LogsSearchState {
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
  final int count;

  ///more logs matched than [LogsCubit.exportMaxRows]: only the newest were exported
  final bool capped;

  LogsBackupOkState(this.count, {this.capped = false});
}

class LogsBackupErrorState extends LogsBackupState {
  GlobalException exception;

  LogsBackupErrorState(this.exception);
}
