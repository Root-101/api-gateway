import 'dart:async';

import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';
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

class LogsScreen extends StatefulWidget {
  static final LogsScreenNavigator navigator = LogsScreenNavigator();

  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

///the screen keeps the search (debounced) and the snacks; header, toolbar, table and footer are widgets of their own
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
      message: added == null
          ? intl.logs.refreshed
          : added <= 0
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
        message: state.capped
            ? context.intl.logs.exportedCapped(
                count: _number.format(state.count),
              )
            : context.intl.logs.exported(count: _number.format(state.count)),
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
        //the screen fits the window: only the table's rows scroll
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LogsHeader(cubit: cubit, onRefresh: _refresh),
              const SizedBox(height: 16),
              Expanded(
                child: _buildPanel(
                  context,
                  filtering: state is LogsFilteringState,
                ),
              ),
            ],
          ),
        );
      },
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
          LogsToolbar(
            cubit: cubit,
            search: _search,
            onChanged: (_) {
              _debounceTimer?.cancel();
              _debounceTimer = Timer(_debounce, _searchNow);
            },
            onSubmitted: _searchNow,
            onClear: _clearText,
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
          Expanded(
            child: AnimatedOpacity(
              opacity: filtering && !booting ? 0.35 : 1,
              duration: motion(context, const Duration(milliseconds: 180)),
              child: LogsTable(
                booting: booting,
                items: cubit.items,
                empty: noLogs ? LogsEmpty(onClearAll: _clearAll) : null,
              ),
            ),
          ),
          LogsFooter(cubit: cubit, booting: booting, filtering: filtering),
        ],
      ),
    );
  }
}
