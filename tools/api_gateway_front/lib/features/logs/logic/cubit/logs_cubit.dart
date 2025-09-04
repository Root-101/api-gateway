import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
}

class LogsCubit extends Cubit<LogsState>
    with GlobalEventBusCommunication<LogsState> {
  static const int defaultPage = 0;
  static const int defaultPageSize = 20;

  final AuthCubit auth;
  final LogsRepo repo;
  final RoutesRepo routesRepo;

  int currentPage = 0;

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

  void reset() {
    emit(const LogsInitialState());
  }

  Future<void> init() async {
    try {
      emit(LogsSearchingState());

      await _updateRoutes();

      //when start don't use filters (for now at least)
      HttpLogSearchModel response = await repo.findAll(
        credential: auth.current,
        page: currentPage,
        size: defaultPageSize,
      );
      currentPage++;
      items.addAll(response.pageContent);

      emit(LogsSearchOkState(items: items, filters: filters, routes: routes));
    } on Exception catch (exc) {
      emit(LogsSearchErrorState(ExceptionConverter.parse(exc)));
    }
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

    items.addAll(response.pageContent);

    return response.pageContent;
  }

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

    RouteLogModel adminRoute = RouteLogModel(
      routeId: '00000000-0000-0000-0000-000000000000',
      routeName: 'Admin',
      routePath: '/${env.ADMIN_PATH}/**',
    );
    routes.add(adminRoute);

    final String noRouteId = 'NO-ROUTE';
    RouteLogModel noRoute = RouteLogModel(
      routeId: noRouteId,
      routeName: app.intl.filterNoRouteName,
      routePath: noRouteId,
    );
    routes.add(noRoute);

    if (filters.route != null && filters.route!.routeId == noRouteId) {
      filters.route = noRoute.copyWith();
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
