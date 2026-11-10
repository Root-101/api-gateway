import 'dart:async';
import 'dart:math';

import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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

///up to 3 page numbers around the current one (1-based)
List<int> visiblePages({required int page, required int pageCount}) {
  final start = (page - 1).clamp(1, max(1, pageCount - 2)).toInt();
  return [for (var n = start; n < start + 3 && n <= pageCount; n++) n];
}

class LogsScreen extends StatefulWidget {
  static final LogsScreenNavigator navigator = LogsScreenNavigator();

  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  static const Duration _debounce = Duration(milliseconds: 400);

  //follows Intl.defaultLocale, set by the language: 1,555 or 1.555
  NumberFormat get _number => NumberFormat.decimalPattern();

  final TextEditingController _search = TextEditingController();
  late final LogsCubit cubit;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    cubit = app.di.find();
    cubit.init();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _searchNow() {
    _debounceTimer?.cancel();
    cubit.applySearch(query: _search.text);
  }

  void _clearText() {
    _search.clear();
    _searchNow();
  }

  void _clearAll() {
    _debounceTimer?.cancel();
    _search.clear();
    cubit.clearSearchAndFilters();
  }

  Future<void> _refresh() async {
    final intl = context.intl;
    final added = await cubit.refresh();
    if (cubit.state is! LogsSearchOkState) return;
    app.snack.showSuccess(
      message: added <= 0
          ? intl.logs.noNewRequests
          : added == 1
          ? intl.logs.oneNewRequest
          : intl.logs.manyNewRequests(count: added),
    );
  }

  void _onState(BuildContext context, LogsState state) {
    if (state is LogsBackupProcessingState) {
      app.loading.show();
    } else if (state is LogsBackupOkState) {
      app.loading.hide();
      app.snack.showSuccess(
        message: context.intl.logs.exported(count: _number.format(state.count)),
      );
    } else if (state is LogsBackupErrorState) {
      app.loading.hide();
      app.snack.showError(message: state.exception.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LogsCubit, LogsState>(
      listener: _onState,
      buildWhen: (previous, current) => current is LogsSearchState,
      builder: (context, state) {
        if (state is LogsSearchErrorState && !cubit.loaded) {
          return ErrorPage(
            errorMessage: state.exception.message,
            buttonText: context.intl.actions.tryAgain,
            onPressed: cubit.init,
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildPanel(context, filtering: state is LogsFilteringState),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 16,
      runSpacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              intl.logs.logs,
              style: TextStyle(
                fontSize: 26,
                height: 32 / 26,
                fontWeight: FontWeight.w500,
                color: c.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              intl.logs.captured(count: _number.format(cubit.capturedTotal)),
              style: TextStyle(fontSize: 13, color: c.textSecondary),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton(
              label: intl.actions.refresh,
              icon: app.assets.icons.actions.reload,
              kind: AppButtonKind.outlined,
              onPressed: _refresh,
            ),
            const SizedBox(width: 8),
            AppButton(
              label: intl.logs.export,
              icon: app.assets.icons.actions.download,
              kind: AppButtonKind.outlined,
              onPressed: cubit.export,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPanel(BuildContext context, {required bool filtering}) {
    final c = app.colors;
    final booting = !cubit.loaded;
    final noLogs = !booting && !filtering && cubit.items.isEmpty;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.outlineCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.raised)),
            ),
            child: Row(
              children: [
                Expanded(child: _buildSearch(context)),
                const SizedBox(width: 10),
                _buildFilterButton(context),
              ],
            ),
          ),
          SizedBox(
            height: 3,
            child: filtering && !booting
                ? LinearProgressIndicator(
                    color: c.lilac,
                    backgroundColor: c.outlineSoft,
                  )
                : null,
          ),
          AnimatedOpacity(
            opacity: filtering && !booting ? 0.35 : 1,
            duration: motion(context, const Duration(milliseconds: 180)),
            child: _buildTable(context, booting: booting),
          ),
          if (noLogs) _buildNoLogs(context),
          _buildFooter(context, booting: booting, filtering: filtering),
        ],
      ),
    );
  }

  Widget _buildSearch(BuildContext context) {
    final intl = context.intl;
    return AppSearchField(
      controller: _search,
      hint: intl.logs.search,
      clearLabel: intl.actions.clearSearch,
      height: 44,
      fontSize: 14,
      onChanged: (_) {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(_debounce, _searchNow);
      },
      onSubmitted: (_) => _searchNow(),
      onClear: _clearText,
      chips: _buildActiveChips(context),
    );
  }

  ///in this order: method, route, status, date
  List<Widget> _buildActiveChips(BuildContext context) {
    final filters = cubit.filters;
    final format = app.dateFormatter.logsTimeS.format;
    final from = filters.date?.fromDate;
    final to = filters.date?.toDate;
    final status = filters.responseCode;
    return [
      if (filters.hasHttpMethod)
        _chip(filters.httpMethod!, LogFilterKind.method),
      if (filters.hasRoute)
        _chip(filters.route!.routeName, LogFilterKind.route),
      if (status != null)
        _chip(
          status.length == 1 ? '${status}xx' : status,
          LogFilterKind.status,
        ),
      if (filters.hasDate)
        _chip(
          from != null && to != null
              ? '${format(from)} - ${format(to)}'
              : from != null
              ? context.intl.logFilters.chipFrom(date: format(from))
              : context.intl.logFilters.chipUntil(date: format(to!)),
          LogFilterKind.date,
        ),
    ];
  }

  Widget _chip(String label, LogFilterKind kind) {
    final c = app.colors;
    return Container(
      height: 28,
      padding: const EdgeInsets.only(left: 10, right: 2),
      decoration: BoxDecoration(
        color: c.raised,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: c.text,
            ),
          ),
          const SizedBox(width: 2),
          AppIconButton(
            icon: app.assets.icons.actions.close,
            tooltip: context.intl.logs.removeFilter(label: label),
            size: 24,
            iconSize: 13,
            radius: 6,
            onPressed: () => cubit.removeFilter(kind),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final count = cubit.filters.filterCount;
    final active = count > 0;
    void open() => LogsFilterDialog.show(
      filters: cubit.filters,
      routes: cubit.routes,
      callback: cubit.applyFilter,
    );
    //the semantics node replaces the child's, so it carries the tap itself
    return Semantics(
      button: true,
      label: intl.logs.filtersActive(count: count),
      excludeSemantics: true,
      onTap: open,
      child: Material(
        color: active ? c.lilac.withValues(alpha: 0.12) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: active ? c.lilac.withValues(alpha: 0.5) : c.outline,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: open,
          child: Container(
            height: 44,
            padding: const EdgeInsets.only(left: 14, right: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                app.assets.icons.general.filter.build(size: 17, color: c.text),
                const SizedBox(width: 8),
                Text(
                  intl.logs.filters,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: c.text,
                  ),
                ),
                if (active) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.lilac,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: c.onLilac,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTable(BuildContext context, {required bool booting}) {
    final c = app.colors;
    final intl = context.intl;
    const skeletonWidths = [
      240.0,
      180.0,
      280.0,
      210.0,
      260.0,
      150.0,
      220.0,
      190.0,
    ];
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: max(860, constraints.maxWidth),
          child: Column(
            children: [
              Container(
                height: 40,
                color: c.surface,
                child: _cells(
                  CaptionText(
                    intl.logs.columnTimestamp,
                    size: 11,
                    color: c.textSecondary,
                  ),
                  CaptionText(
                    intl.logs.columnMethod,
                    size: 11,
                    color: c.textSecondary,
                  ),
                  CaptionText(
                    intl.logs.columnPath,
                    size: 11,
                    color: c.textSecondary,
                  ),
                  CaptionText(
                    intl.logs.columnRoute,
                    size: 11,
                    color: c.textSecondary,
                  ),
                  CaptionText(
                    intl.logs.columnHttpStatus,
                    size: 11,
                    color: c.textSecondary,
                  ),
                  CaptionText(
                    intl.logs.columnRequestDuration,
                    size: 11,
                    color: c.textSecondary,
                  ),
                ),
              ),
              if (booting)
                for (final width in skeletonWidths)
                  _rowFrame(
                    _cells(
                      const AppSkeleton(width: 130),
                      const AppSkeleton(width: 40),
                      AppSkeleton(width: width),
                      const AppSkeleton(width: 90),
                      const AppSkeleton(width: 52, height: 22, radius: 11),
                      const AppSkeleton(width: 44),
                    ),
                  )
              else
                for (final log in cubit.items) _buildRow(context, log),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rowFrame(Widget child) => Container(
    height: 48,
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: app.colors.outlineSoft)),
    ),
    child: child,
  );

  Widget _cells(
    Widget timestamp,
    Widget method,
    Widget path,
    Widget route,
    Widget status,
    Widget duration,
  ) {
    Widget cell(
      Widget child, {
      double? width,
      Alignment align = Alignment.centerLeft,
    }) {
      final padded = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Align(alignment: align, child: child),
      );
      return width == null
          ? Expanded(child: padded)
          : SizedBox(width: width, child: padded);
    }

    return Row(
      children: [
        cell(timestamp, width: 200),
        cell(method, width: 100),
        cell(path),
        cell(route, width: 190),
        cell(status, width: 110),
        cell(duration, width: 110, align: Alignment.centerRight),
      ],
    );
  }

  Widget _buildRow(BuildContext context, HttpLogModel log) {
    final c = app.colors;
    final intl = context.intl;
    const tabular = [FontFeature.tabularFigures()];
    return _rowFrame(
      Semantics(
        button: true,
        label: '${log.httpMethod} ${log.path}',
        child: InkWell(
          hoverColor: c.surface,
          onTap: () => LogDetailsScreen.open(log),
          child: _cells(
            Text(
              app.dateFormatter.logsTime.format(log.requestedAtLocal),
              maxLines: 1,
              style: TextStyle(
                fontSize: 14,
                color: c.textSecondary,
                fontFeatures: tabular,
              ),
            ),
            Text(
              log.httpMethod,
              style: monoStyle(
                size: 12,
                weight: FontWeight.w500,
                letterSpacing: 0.4,
                color: c.methodColor(log.httpMethod),
              ),
            ),
            Text(
              log.path,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: monoStyle(color: c.text),
            ),
            Text(
              log.route?.routeName ?? intl.logFilters.filterNoRouteName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: log.route == null ? c.textTertiary : c.text,
              ),
            ),
            StatusPill(log.responseCode),
            Text(
              intl.logs.durationMs(ms: log.requestDuration),
              style: TextStyle(
                fontSize: 14,
                color: c.textSecondary,
                fontFeatures: tabular,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoLogs(BuildContext context) {
    final intl = context.intl;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: app.colors.outlineSoft)),
      ),
      child: EmptyState(
        icon: app.assets.icons.general.inbox,
        title: intl.logs.noMatches,
        action: AppButton(
          label: intl.logs.clearAll,
          kind: AppButtonKind.outlined,
          onPressed: _clearAll,
        ),
      ),
    );
  }

  String _statusText(
    BuildContext context, {
    required bool booting,
    required bool filtering,
  }) {
    final logs = context.intl.logs;
    if (booting) return logs.loading;
    if (filtering) return logs.filtering;
    final total = cubit.totalElements;
    final count = total == 1
        ? logs.oneRequest
        : logs.manyRequests(count: _number.format(total));
    return '$count${cubit.filters.isEmpty ? '' : logs.matchSuffix}${logs.rowHint}';
  }

  Widget _buildFooter(
    BuildContext context, {
    required bool booting,
    required bool filtering,
  }) {
    final c = app.colors;
    final intl = context.intl;
    final page = cubit.currentPage + 1;
    final pageCount = max(1, cubit.totalPages);
    final start = cubit.currentPage * cubit.pageSize;
    final total = cubit.totalElements;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.outlineSoft)),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(fontSize: 12, height: 16 / 12, color: c.textTertiary),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _statusText(context, booting: booting, filtering: filtering),
              ),
            ),
            const SizedBox(width: 12),
            Text(intl.logs.rowsPerPage),
            const SizedBox(width: 8),
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: c.outline),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: cubit.pageSize,
                  isDense: true,
                  dropdownColor: c.popup,
                  borderRadius: BorderRadius.circular(8),
                  style: TextStyle(fontSize: 12, color: c.text),
                  iconSize: 16,
                  items: [
                    for (final size in const [10, 25, 50])
                      DropdownMenuItem(value: size, child: Text('$size')),
                  ],
                  onChanged: (size) {
                    if (size != null && size != cubit.pageSize)
                      cubit.setPageSize(size);
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              total == 0
                  ? intl.logs.emptyRange
                  : intl.logs.range(
                      start: '${start + 1}',
                      end: '${start + cubit.items.length}',
                      total: _number.format(total),
                    ),
              style: TextStyle(
                color: c.label,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 12),
            AppIconButton(
              icon: app.assets.icons.general.chevronLeft,
              tooltip: intl.logs.previousPage,
              size: 32,
              iconSize: 16,
              radius: 8,
              onPressed: page <= 1
                  ? null
                  : () => cubit.goToPage(cubit.currentPage - 1),
            ),
            for (final number in visiblePages(page: page, pageCount: pageCount))
              _pageButton(context, number, current: number == page),
            AppIconButton(
              icon: app.assets.icons.general.chevronRight,
              tooltip: intl.logs.nextPage,
              size: 32,
              iconSize: 16,
              radius: 8,
              onPressed: page >= pageCount
                  ? null
                  : () => cubit.goToPage(cubit.currentPage + 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageButton(
    BuildContext context,
    int number, {
    required bool current,
  }) {
    final c = app.colors;
    return Semantics(
      button: true,
      selected: current,
      label: context.intl.logs.page(page: number),
      excludeSemantics: true,
      onTap: current ? null : () => cubit.goToPage(number - 1),
      child: Material(
        color: current ? c.selected : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: current ? null : () => cubit.goToPage(number - 1),
          child: Container(
            constraints: const BoxConstraints(minWidth: 32),
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: current ? c.onSelected : c.label,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
