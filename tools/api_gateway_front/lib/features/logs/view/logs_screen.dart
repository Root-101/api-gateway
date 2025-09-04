import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class LogsScreenNavigator {
  String get name => 'logs';

  String get path => '/logs';

  Widget builder(BuildContext context, GoRouterState state) {
    return const LogsScreen();
  }

  void neglectGo() {
    Router.neglect(app.context, () {
      app.navigator.go(name);
    });
  }
}

class LogsScreen extends StatefulWidget {
  static final LogsScreenNavigator navigator = LogsScreenNavigator();

  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final TextEditingController searchController = TextEditingController();

  late final LogsCubit cubit;
  late LogsDataSource dataSource;

  Map<String, double?> columnWidths = {
    'requestedAt': null,
    'httpMethod': null,
    'route': null,
    'responseCode': null,
    'requestDuration': null,
    'path': null,
  };

  @override
  void initState() {
    super.initState();
    cubit = app.di.find();
    cubit.init();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LogsCubit, LogsState>(
      listener: (context, state) {},
      buildWhen: (previous, current) => current is LogsSearchState,
      builder: (context, state) {
        if (state is LogsInitialState) {
          return const LoadingPage();
        } else if (state is LogsSearchingState) {
          return const LoadingPage();
        } else if (state is LogsSearchOkState) {
          dataSource = LogsDataSource(
            logs: state.items,
            fetchNextPage: cubit.fetchNextPage,
            onRequestedAtTap: (log) async {
              cubit.updateFilter(requestedAt: log.requestedAt);
            },
            onHttpMethodTap: (log) async {
              cubit.updateFilter(httpMethod: log.httpMethod);
            },
            onPathTap: (log) async {
              searchController.text = log.path;
              cubit.applySearch(query: searchController.text);
            },
            onRouteTap: (log) async {
              cubit.updateFilter(route: log.route);
            },
            onResponseCodeTap: (log) async {
              cubit.updateFilter(responseCode: log.responseCode);
            },
          );

          final TextStyle headerStyle = app.textTheme.bodyLarge!.copyWith(
            color: app.colors.neutral.grey3,
          );

          return Scaffold(
            appBar: CustomAppBar.build(title: app.intl.logs),
            body: Padding(
              padding: EdgeInsets.only(
                left: app.dimensions.padding.l,
                right: app.dimensions.padding.l,
                top: app.dimensions.padding.l,
              ),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: app.colors.primary.background2,
                      borderRadius: BorderRadius.only(
                        topLeft: app.dimensions.border.radius.m,
                        topRight: app.dimensions.border.radius.m,
                      ),
                      border: Border.all(color: app.colors.neutral.grey5),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(app.dimensions.padding.l),
                      child: _buildFilterSection(state),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final totalWidth = constraints.maxWidth;

                        final requestedAtWidth = totalWidth * 0.15;
                        final methodWidth = totalWidth * 0.10;
                        final pathWidth = totalWidth * 0.44;
                        final routeWidth = totalWidth * 0.15;
                        final statusWidth = totalWidth * 0.08;
                        double durationWidth = totalWidth * 0.08;

                        return SfDataGrid(
                          source: dataSource,
                          allowColumnsResizing: true,
                          allowPullToRefresh: true,
                          headerRowHeight: 42,
                          rowHeight: 42,
                          onCellTap: (DataGridCellTapDetails details) {
                            if (details.rowColumnIndex.rowIndex > 0) {
                              final int rowIndex =
                                  details.rowColumnIndex.rowIndex - 1;
                              final DataGridRow row = dataSource.rows[rowIndex];

                              final HttpLogModel log =
                                  row
                                          .getCells()
                                          .firstWhere(
                                            (cell) => cell.columnName == 'data',
                                          )
                                          .value
                                      as HttpLogModel;

                              LogDetailsScreen.open(log);
                            }
                          },
                          onColumnResizeUpdate: (details) {
                            setState(() {
                              columnWidths[details.column.columnName] =
                                  details.width;

                              final sum = columnWidths.values.fold(
                                0.0,
                                (previousValue, element) =>
                                    previousValue + (element ?? 0),
                              );

                              final dif = totalWidth - sum;
                              if (columnWidths['requestDuration'] == null) {
                                columnWidths['requestDuration'] =
                                    durationWidth + dif;
                              } else {
                                columnWidths['requestDuration'] =
                                    columnWidths['requestDuration']! + dif;
                              }
                            });
                            return true;
                          },
                          columns: <GridColumn>[
                            GridColumn(
                              columnName: 'data',
                              width: 0,
                              minimumWidth: 0,
                              maximumWidth: 0,
                              label: Text('', style: headerStyle),
                            ),
                            GridColumn(
                              columnName: 'requestedAt',
                              width:
                                  columnWidths['requestedAt'] ??
                                  requestedAtWidth,
                              minimumWidth: 130,
                              label: Padding(
                                padding: EdgeInsets.all(
                                  app.dimensions.padding.s,
                                ),
                                child: Text(
                                  app.intl.columnTimestamp,
                                  style: headerStyle,
                                ),
                              ),
                            ),
                            GridColumn(
                              columnName: 'httpMethod',
                              width: columnWidths['httpMethod'] ?? methodWidth,
                              minimumWidth: 80,
                              label: Padding(
                                padding: EdgeInsets.all(
                                  app.dimensions.padding.s,
                                ),
                                child: Text(
                                  app.intl.columnMethod,
                                  style: headerStyle,
                                ),
                              ),
                            ),
                            GridColumn(
                              columnName: 'path',
                              width: columnWidths['path'] ?? pathWidth,
                              minimumWidth: 250,
                              label: Padding(
                                padding: EdgeInsets.all(
                                  app.dimensions.padding.s,
                                ),
                                child: Text(
                                  app.intl.columnPath,
                                  style: headerStyle,
                                ),
                              ),
                            ),
                            GridColumn(
                              columnName: 'route',
                              width: columnWidths['route'] ?? routeWidth,
                              minimumWidth: 180,
                              label: Padding(
                                padding: EdgeInsets.all(
                                  app.dimensions.padding.s,
                                ),
                                child: Text(
                                  app.intl.columnRoute,
                                  style: headerStyle,
                                ),
                              ),
                            ),
                            GridColumn(
                              columnName: 'responseCode',
                              width:
                                  columnWidths['responseCode'] ?? statusWidth,
                              minimumWidth: 80,
                              label: Padding(
                                padding: EdgeInsets.all(
                                  app.dimensions.padding.s,
                                ),
                                child: Text(
                                  app.intl.columnHttpStatus,
                                  style: headerStyle,
                                ),
                              ),
                            ),
                            GridColumn(
                              columnName: 'requestDuration',
                              width:
                                  columnWidths['requestDuration'] ??
                                  durationWidth,
                              minimumWidth: 80,
                              columnWidthMode: ColumnWidthMode.lastColumnFill,
                              label: Padding(
                                padding: EdgeInsets.all(
                                  app.dimensions.padding.s,
                                ),
                                child: Text(
                                  app.intl.columnRequestDuration,
                                  style: headerStyle,
                                ),
                              ),
                            ),
                          ],
                          loadMoreViewBuilder:
                              (
                                BuildContext context,
                                LoadMoreRows loadMoreRows,
                              ) {
                                loadMoreRows();
                                return const SizedBox.shrink();
                              },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (state is LogsSearchErrorState) {
          return ErrorPage(
            errorMessage: state.exception.message,
            buttonText: app.intl.tryAgain,
            onPressed: cubit.init,
          );
        } else {
          return ErrorPage(
            buttonText: app.intl.tryAgain,
            onPressed: cubit.init,
          );
        }
      },
    );
  }

  Widget _buildFilterButton({
    required LogsSearchFilters filters,
    required List<RouteLogModel> routes,
  }) {
    return Badge(
      label: Text(filters.filterCount.toString()),
      textColor: app.colors.neutral.white,
      backgroundColor: app.colors.primary.purple,
      child: GestureDetector(
        onTap: () {
          LogsFilterDialog.show(
            filters: filters,
            routes: routes,
            callback:
                ({responseCode, httpMethod, route, fromDate, toDate}) async {
                  app.navigator.pop();
                  return cubit.applyFilter(
                    responseCode: responseCode,
                    httpMethod: httpMethod,
                    route: route,
                    fromDate: fromDate,
                    toDate: toDate,
                  );
                },
          );
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: FormComponentTemplate(
            borderColor: app.colors.neutral.grey3,
            height: 42,
            width: 42,
            borderRadius: app.dimensions.border.borderRadius.s,
            child: Padding(
              padding: EdgeInsets.all(app.dimensions.padding.s),
              child: app.assets.icons.general.filter.build(size: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection(LogsSearchOkState state) {
    return Row(
      children: [
        Expanded(
          child: EMTextSearchField(
            controller: searchController,
            hint: app.intl.search,
            onSearch: (value) async {
              cubit.applySearch(query: searchController.text);
            },
            extraSuffix: state.filters.filterCount == 0
                ? null
                : Row(
                    children: [
                      if (state.filters.hasDate)
                        Builder(
                          builder: (context) {
                            DateTime? fromDate = state.filters.date?.fromDate;
                            DateTime? toDate = state.filters.date?.toDate;
                            String finalDate = '';
                            if (fromDate != null) {
                              finalDate += app.dateFormatter.logsTimeS.format(
                                fromDate,
                              );
                            } else {
                              finalDate += 'X';
                            }
                            finalDate += ' - ';
                            if (toDate != null) {
                              finalDate += app.dateFormatter.logsTimeS.format(
                                toDate,
                              );
                            } else {
                              finalDate += 'X';
                            }
                            return _buildSingleFilterTag(
                              tooltip: app.intl.columnTimestamp,
                              text: finalDate,
                              onRemoveFilter: () {
                                cubit.applyFilter(
                                  httpMethod: state.filters.httpMethod,
                                  route: state.filters.route,
                                  responseCode: state.filters.responseCode,
                                  requestedAt: null,
                                  fromDate: null,
                                  toDate: null,
                                );
                              },
                            );
                          },
                        ),
                      if (state.filters.hasResponseCode)
                        _buildSingleFilterTag(
                          tooltip: app.intl.columnHttpStatus,
                          text: state.filters.responseCode!.toString(),
                          onRemoveFilter: () {
                            cubit.applyFilter(
                              httpMethod: state.filters.httpMethod,
                              route: state.filters.route,
                              responseCode: null,
                              fromDate: state.filters.date?.fromDate,
                              toDate: state.filters.date?.toDate,
                            );
                          },
                        ),
                      if (state.filters.hasHttpMethod)
                        _buildSingleFilterTag(
                          tooltip: app.intl.columnMethod,
                          text: state.filters.httpMethod!,
                          onRemoveFilter: () {
                            cubit.applyFilter(
                              httpMethod: null,
                              route: state.filters.route,
                              responseCode: state.filters.responseCode,
                              fromDate: state.filters.date?.fromDate,
                              toDate: state.filters.date?.toDate,
                            );
                          },
                        ),
                      if (state.filters.hasRoute)
                        _buildSingleFilterTag(
                          tooltip: app.intl.columnRoute,
                          text: state.filters.route!.routeName,
                          onRemoveFilter: () {
                            cubit.applyFilter(
                              httpMethod: state.filters.httpMethod,
                              route: null,
                              responseCode: state.filters.responseCode,
                              fromDate: state.filters.date?.fromDate,
                              toDate: state.filters.date?.toDate,
                            );
                          },
                        ),
                    ],
                  ),
          ),
        ),
        app.dimensions.padding.l.gap(),
        _buildFilterButton(filters: state.filters, routes: state.routes),
      ],
    );
  }

  Widget _buildSingleFilterTag({
    required String text,
    required VoidCallback onRemoveFilter,
    required String tooltip,
  }) {
    final int maxTextSize = 25;
    String safeText = text.length > maxTextSize
        ? '${text.substring(0, maxTextSize)}...'
        : text;
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0, top: 4.0, bottom: 4.0),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onRemoveFilter,
            child: Container(
              decoration: BoxDecoration(
                color: app.colors.primary.background3,
                borderRadius: app.dimensions.border.borderRadius.xs,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: Text(
                  safeText,
                  style: app.textTheme.bodyLarge?.copyWith(
                    color: app.colors.neutral.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

typedef OnColumnTap = Future Function(HttpLogModel log);

class LogsDataSource extends DataGridSource {
  final Future<List<HttpLogModel>> Function() fetchNextPage;

  final OnColumnTap? onRequestedAtTap;
  final OnColumnTap? onHttpMethodTap;
  final OnColumnTap? onPathTap;
  final OnColumnTap? onRouteTap;
  final OnColumnTap? onResponseCodeTap;

  List<DataGridRow> _logs = [];
  bool isLoading = false;
  bool hasMoreRows = true;

  LogsDataSource({
    required List<HttpLogModel> logs,
    required this.fetchNextPage,
    this.onRequestedAtTap,
    this.onHttpMethodTap,
    this.onPathTap,
    this.onRouteTap,
    this.onResponseCodeTap,
  }) {
    _logs = logs.map<DataGridRow>((e) => _buildRow(e)).toList();
  }

  @override
  List<DataGridRow> get rows => _logs;

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    HttpLogModel currentLog =
        row
                .getCells()
                .firstWhere((element) => element.columnName == 'data')
                .value
            as HttpLogModel;

    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((dataGridCell) {
        late Widget row;
        switch (dataGridCell.columnName) {
          case 'data':
            row = const Text('', overflow: TextOverflow.ellipsis);
          case 'requestedAt':
            DateTime time = dataGridCell.value as DateTime;
            row = _HoverableClickableText(
              text: app.dateFormatter.logsTime.format(time.toUtc()),
              color: app.colors.neutral.grey3,
              onTap: () {
                if (onRequestedAtTap != null) {
                  onRequestedAtTap!(currentLog);
                }
              },
            );
          case 'httpMethod':
            row = _HoverableClickableText(
              text: dataGridCell.value.toString(),
              color: app.colors.neutral.grey3,
              onTap: () {
                if (onHttpMethodTap != null) {
                  onHttpMethodTap!(currentLog);
                }
              },
            );
          case 'path':
            row = _HoverableClickableText(
              text: dataGridCell.value.toString(),
              color: app.colors.neutral.white,
              onTap: () {
                if (onPathTap != null) {
                  onPathTap!(currentLog);
                }
              },
            );
          case 'route':
            RouteLogModel? route = dataGridCell.value as RouteLogModel?;
            row = _HoverableClickableText(
              text: route == null ? '' : route.routeName,
              color: app.colors.neutral.white,
              onTap: () {
                if (onRouteTap != null) {
                  onRouteTap!(currentLog);
                }
              },
            );
          case 'responseCode':
            int code = dataGridCell.value as int;
            Color color = app.colors.neutral.white;
            if (code >= 200 && code < 300) {
              color = Colors.green;
            } else if (code >= 300 && code < 400) {
              color = Colors.purple;
            } else if (code >= 400 && code < 500) {
              color = Colors.yellow;
            } else if (code >= 500 && code < 600) {
              color = Colors.red;
            } else {
              color = Colors.blue;
            }
            row = _HoverableClickableText(
              text: code.toString(),
              color: color,
              onTap: () {
                if (onResponseCodeTap != null) {
                  onResponseCodeTap!(currentLog);
                }
              },
            );
          case 'requestDuration':
            row = _HoverableClickableText(
              text: dataGridCell.value.toString(),
              color: app.colors.neutral.grey3,
              enableHover: false,
              onTap: () {},
            );
          default:
            row = Text(
              dataGridCell.value.toString(),
              overflow: TextOverflow.ellipsis,
            );
        }
        return Padding(
          padding: EdgeInsets.all(app.dimensions.padding.s),
          child: row,
        );
      }).toList(),
    );
  }

  @override
  Future<void> handleLoadMoreRows() async {
    if (isLoading || !hasMoreRows) return;
    isLoading = true;

    try {
      final moreLogs = await fetchNextPage();

      if (moreLogs.length < LogsCubit.defaultPageSize) {
        hasMoreRows = false;
      }

      if (moreLogs.isNotEmpty) {
        final newRows = moreLogs.map<DataGridRow>((e) => _buildRow(e)).toList();

        _logs.addAll(newRows);

        notifyListeners(); // Refresh data-grid
      }
    } finally {
      isLoading = false;
    }
  }

  DataGridRow _buildRow(HttpLogModel log) {
    return DataGridRow(
      cells: [
        DataGridCell<HttpLogModel>(columnName: 'data', value: log),
        DataGridCell<DateTime>(
          columnName: 'requestedAt',
          value: log.requestedAt,
        ),
        DataGridCell<String>(columnName: 'httpMethod', value: log.httpMethod),
        DataGridCell<String>(columnName: 'path', value: log.path),
        DataGridCell<RouteLogModel?>(columnName: 'route', value: log.route),
        DataGridCell<int>(columnName: 'responseCode', value: log.responseCode),
        DataGridCell<String>(
          columnName: 'requestDuration',
          value: '${log.requestDuration} ms',
        ),
      ],
    );
  }
}

class _HoverableClickableText extends StatefulWidget {
  final String text;
  final Color? color;
  final VoidCallback? onTap;
  final bool enableHover;

  const _HoverableClickableText({
    required this.text,
    required this.onTap,
    this.color,
    this.enableHover = true,
  });

  @override
  State<_HoverableClickableText> createState() =>
      _HoverableClickableTextState();
}

class _HoverableClickableTextState extends State<_HoverableClickableText> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final style = app.textTheme.bodyLarge!.copyWith(
      color: widget.color,
      decoration: widget.enableHover && _isHovering
          ? TextDecoration.underline
          : TextDecoration.none,
      decorationColor: widget.color,
      overflow: TextOverflow.ellipsis,
    );

    return Align(
      alignment: Alignment.centerLeft,
      widthFactor: 1.0,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Text(widget.text, style: style),
        ),
      ),
    );
  }
}
