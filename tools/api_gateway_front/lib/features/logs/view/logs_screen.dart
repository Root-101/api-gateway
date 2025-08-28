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
  late final LogsCubit cubit;
  late EmployeeDataSource dataSource;

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
          // La DataSource siempre se actualiza con la lista acumulada de logs
          dataSource = EmployeeDataSource(logs: state.items, cubit: cubit);

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
              child: SfDataGrid(
                source: dataSource,
                allowColumnsResizing: true,
                allowPullToRefresh: true,
                columnWidthMode: ColumnWidthMode.none,
                headerRowHeight: 42,
                rowHeight: 48,
                columns: <GridColumn>[
                  GridColumn(
                    columnName: 'requestedAt',
                    width: 200,
                    label: Padding(
                      padding: EdgeInsets.all(app.dimensions.padding.s),
                      child: Text('Time (CST)', style: headerStyle),
                    ),
                  ),
                  GridColumn(
                    columnName: 'httpMethod',
                    width: 80,
                    label: Padding(
                      padding: EdgeInsets.all(app.dimensions.padding.s),
                      child: Text('Method', style: headerStyle),
                    ),
                  ),
                  GridColumn(
                    columnName: 'path',
                    columnWidthMode: ColumnWidthMode.fill,
                    label: Padding(
                      padding: EdgeInsets.all(app.dimensions.padding.s),
                      child: Text('Path', style: headerStyle),
                    ),
                  ),
                  GridColumn(
                    columnName: 'route',
                    width: 230,
                    label: Padding(
                      padding: EdgeInsets.all(app.dimensions.padding.s),
                      child: Text('Route', style: headerStyle),
                    ),
                  ),
                  GridColumn(
                    columnName: 'responseCode',
                    width: 120,
                    label: Padding(
                      padding: EdgeInsets.all(app.dimensions.padding.s),
                      child: Text('HTTP Status', style: headerStyle),
                    ),
                  ),
                  GridColumn(
                    columnName: 'requestDuration',
                    width: 100,
                    label: Padding(
                      padding: EdgeInsets.all(app.dimensions.padding.s),
                      child: Text('Duration', style: headerStyle),
                    ),
                  ),
                ],
                loadMoreViewBuilder:
                    (BuildContext context, LoadMoreRows loadMoreRows) {
                      loadMoreRows();
                      return const SizedBox.shrink();
                    },
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
}

class EmployeeDataSource extends DataGridSource {
  EmployeeDataSource({required List<HttpLogModel> logs, required this.cubit}) {
    _logs = logs.map<DataGridRow>((e) => _buildRow(e)).toList();
  }

  final LogsCubit cubit;

  List<DataGridRow> _logs = [];
  bool isLoading = false;
  bool hasMoreRows = true;

  @override
  List<DataGridRow> get rows => _logs;

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    TextStyle style = app.textTheme.bodyLarge!.copyWith(
      color: app.colors.neutral.grey3,
    );
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((dataGridCell) {
        late Widget row;
        switch (dataGridCell.columnName) {
          case 'requestedAt':
            DateTime time = dataGridCell.value as DateTime;
            row = Text(app.dateFormatter.logsTime.format(time), style: style);
          case 'httpMethod':
            row = Text(dataGridCell.value.toString(), style: style);
          case 'path':
            row = Text(
              dataGridCell.value.toString(),
              style: style.copyWith(
                color: app.colors.neutral.white,
                overflow: TextOverflow.ellipsis,
              ),
            );
          case 'route':
            RouteLogModel? route = dataGridCell.value as RouteLogModel?;
            row = Text(
              route == null ? '' : route.routeName,
              style: style.copyWith(
                color: app.colors.neutral.white,
                overflow: TextOverflow.ellipsis,
              ),
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
            row = Text(code.toString(), style: style.copyWith(color: color));
          case 'requestDuration':
            row = Text(dataGridCell.value.toString(), style: style);
          default:
            row = Text(dataGridCell.value.toString(), style: style);
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
      final moreLogs = await cubit.fetchNextPage();

      if (moreLogs.isEmpty) {
        hasMoreRows = false;
      } else {
        final newRows = moreLogs.map<DataGridRow>((e) => _buildRow(e)).toList();

        _logs.addAll(newRows);
        notifyListeners(); // Refresca la DataGrid
      }
    } finally {
      isLoading = false;
    }
  }

  DataGridRow _buildRow(HttpLogModel log) {
    return DataGridRow(
      cells: [
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
