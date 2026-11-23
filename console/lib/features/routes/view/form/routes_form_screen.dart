import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class RoutesFormScreenNavigator {
  Widget _dialog(
    RoutesFormAction action, {
    String? routeId,
    RouteModel? model,
  }) => BlocProvider(
    create: (BuildContext context) => RoutesFormCubit(
      repo: app.di.find(),
      action: action,
      paramRouteId: routeId,
      paramRouteModel: model,
    ),
    lazy: false,
    child: const RoutesFormScreen(),
  );

  void create() {
    app.dialog.open(dialog: _dialog(RoutesFormAction.create));
  }

  String get editName => 'routeEdit';

  ///child of `/routes`: `/routes/:id/edit`
  String get editPath => ':id/edit';

  ///opened from the card (model in `extra`) or from the url (only the id: the route is loaded)
  Page<void> editPageBuilder(BuildContext context, GoRouterState state) {
    final model = state.extra is RouteModel ? state.extra as RouteModel : null;
    return DialogPage(
      key: state.pageKey,
      dialog: _dialog(
        RoutesFormAction.edit,
        routeId: state.pathParameters['id'],
        model: model,
      ),
    );
  }

  /// `/routes/:id/edit`, a dialog over the whole app (root navigator)
  List<RouteBase> routes() => [
    GoRoute(
      name: editName,
      path: editPath,
      parentNavigatorKey: navigatorKey,
      pageBuilder: editPageBuilder,
    ),
  ];

  void edit({required RouteModel model}) {
    app.navigator.push(
      editName,
      pathParameters: {'id': model.id},
      extra: model,
    );
  }

  void duplicate({required RouteModel model}) {
    app.dialog.open(
      dialog: _dialog(
        RoutesFormAction.duplicate,
        routeId: model.id,
        model: model,
      ),
    );
  }
}

class RoutesFormScreen extends StatefulWidget {
  static final RoutesFormScreenNavigator navigator =
      RoutesFormScreenNavigator();

  const RoutesFormScreen({super.key});

  @override
  State<RoutesFormScreen> createState() => _RoutesFormScreenState();
}

class _RoutesFormScreenState extends State<RoutesFormScreen> {
  ///null when it couldn't be checked: the error is shown (an expired session has its own dialog)
  Future<Map<String, String>?> _validate(RouteFormModel model) async {
    try {
      return await cubit.validate(model: model);
    } on GlobalException catch (global) {
      if (global.type != GlobalExceptionType.auth) {
        app.toast.error(global.intlMessage);
      }
      return null;
    }
  }

  late final RoutesFormCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = context.read<RoutesFormCubit>();
  }

  void _onState(BuildContext context, RoutesFormState state) {
    final intl = context.intl;
    if (state is RoutesFormProcessInProgressState) {
      app.loading.show();
    } else if (state is RoutesFormProcessingErrorState) {
      app.loading.hide();
      app.toast.error(state.exception.intlMessage);
    } else if (state is RoutesFormValidationErrorState) {
      app.loading.hide();
    } else if (state is RoutesFormProcessingOKState) {
      app.loading.hide();
      app.toast.success(
        state.created
            ? intl.routes.created(name: state.name)
            : intl.routes.updated(name: state.name),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RoutesFormCubit, RoutesFormState>(
      listener: _onState,
      buildWhen: (previous, current) => current is RoutesFormLoadingState,
      builder: (context, state) {
        if (state is RoutesFormLoadingSuccessState) {
          return RoutesFormWidget(
            failValidations: (state is RoutesFormValidationErrorState)
                ? state.failValidations
                : {},
            action: state.action,
            route: state.routeModel,
            gatewayUrl: state.gatewayUrl,
            onSave: (model) => state.action == RoutesFormAction.edit
                ? cubit.edit(model: model)
                : cubit.create(model: model),
            onValidate: _validate,
          );
        }
        return DialogTemplate(
          title: context.intl.routes.routes,
          width: 420,
          alignment: Alignment.center,
          body: Center(
            child: state is RoutesFormLoadingErrorState
                ? Text(state.text, textAlign: TextAlign.center)
                : SmallSpinner(color: app.colors.lilac, size: 24),
          ),
        );
      },
    );
  }
}

///`<name>-copy`, or `-copy-2` and up when that one is taken (exact match, like the api)
String duplicateRouteName(String name, Iterable<String> existing) {
  final taken = existing.toSet();
  var candidate = '$name-copy';
  for (var i = 2; taken.contains(candidate); i++) {
    candidate = '$name-copy-$i';
  }
  return candidate;
}
