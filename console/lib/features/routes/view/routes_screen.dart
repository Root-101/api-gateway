import 'package:console/app_exporter.dart';
import 'package:console/features/routes/view/form/routes_form_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class RoutesScreenNavigator {
  String get name => 'routes';

  String get path => '/routes';

  Widget builder(BuildContext context, GoRouterState state) {
    return const RoutesScreen();
  }

  void neglectGo() {
    Router.neglect(app.context, () {
      app.navigator.go(name);
    });
  }
}

class RoutesScreen extends StatefulWidget {
  static final RoutesScreenNavigator navigator = RoutesScreenNavigator();

  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

///the list keeps the search and the delete confirmation; header, grid and cards are widgets of their own
class _RoutesScreenState extends State<RoutesScreen> {
  late final RoutesCubit cubit;
  final TextEditingController _searchCtrl = TextEditingController();

  //local filter: the api has no search for routes and the list is small
  List<RouteModel> get _visible {
    final query = cubit.query.value.trim().toLowerCase();
    if (query.isEmpty) return cubit.routes;
    return cubit.routes
        .where(
          (r) => [
            r.name,
            r.path,
            r.uri,
            r.description,
          ].any((field) => field.toLowerCase().contains(query)),
        )
        .toList();
  }

  void _syncSearch() {
    if (_searchCtrl.text != cubit.query.value) {
      _searchCtrl.text = cubit.query.value;
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    cubit = app.di.find();
    cubit.query.addListener(_syncSearch);
    _searchCtrl.text = cubit.query.value;
    if (cubit.state is RoutesInitialState) {
      cubit.search();
    }
  }

  @override
  void dispose() {
    cubit.query.removeListener(_syncSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onState(BuildContext context, RoutesState state) {
    final intl = context.intl;
    if (state is RoutesBackupProcessingState ||
        state is RoutesDeleteProcessingState) {
      app.loading.show();
    } else if (state is RoutesBackupOkState) {
      app.loading.hide();
      app.snack.showSuccess(
        message: intl.routes.backupSaved(count: state.count),
      );
    } else if (state is RoutesDeleteOkState) {
      app.loading.hide();
      app.snack.showSuccess(message: intl.routes.deleted(name: state.name));
    } else if (state is RoutesBackupErrorState) {
      app.loading.hide();
      app.snack.showError(message: state.exception.message);
    } else if (state is RoutesDeleteErrorState) {
      app.loading.hide();
      app.snack.showError(message: state.exception.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RoutesCubit, RoutesState>(
      listener: _onState,
      buildWhen: (previous, current) => current is RoutesSearchState,
      builder: (context, state) {
        if (state is RoutesSearchErrorState && !cubit.loaded) {
          return ErrorPage(
            errorMessage: state.exception.message,
            buttonText: context.intl.actions.tryAgain,
            onPressed: cubit.search,
          );
        }
        final loading = !cubit.loaded;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RoutesHeader(routes: cubit.routes, onBackup: cubit.backup),
              const SizedBox(height: 16),
              AppSearchField(
                controller: _searchCtrl,
                hint: context.intl.routes.search,
                clearLabel: context.intl.actions.clearSearch,
                onChanged: (value) => cubit.query.value = value,
                onClear: () => cubit.query.value = '',
              ),
              const SizedBox(height: 20),
              if (loading)
                RoutesGrid(
                  cards: List.generate(4, (_) => const RouteCardSkeleton()),
                )
              else
                _buildBody(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    final intl = context.intl;
    final visible = _visible;
    if (visible.isEmpty) {
      final noRoutes = cubit.routes.isEmpty;
      return Padding(
        padding: const EdgeInsets.only(top: 44),
        child: Center(
          child: EmptyState(
            icon: app.assets.icons.general.search,
            title: noRoutes
                ? intl.routes.noRoutesYet
                : intl.routes.noMatches(query: cubit.query.value),
            subtitle: intl.routes.noMatchesHint,
            action: AppButton(
              label: intl.routes.createRoute,
              onPressed: RoutesFormScreen.navigator.create,
            ),
          ),
        ),
      );
    }
    return BlocBuilder<MaintenanceCubit, MaintenanceState>(
      builder: (context, _) {
        final gatewayOn = app.di.find<MaintenanceCubit>().gatewayOn;
        return RoutesGrid(
          cards: [
            for (final route in visible)
              RouteCard(
                route: route,
                gatewayOn: gatewayOn,
                onDelete: () => _confirmDelete(route),
              ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(RouteModel route) async {
    final confirmed = await app.dialog.open<bool>(
      dialog: DeleteRouteDialog(route: route),
    );
    if (confirmed == true) cubit.delete(route: route);
  }
}
