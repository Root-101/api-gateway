import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';
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
      app.snack.showError(message: state.exception.message);
    } else if (state is RoutesFormValidationErrorState) {
      app.loading.hide();
    } else if (state is RoutesFormProcessingOKState) {
      app.loading.hide();
      app.snack.showSuccess(
        message: state.created
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

///`<name>-copy`, or `-copy-2` and up when that one is taken (ignoring case)
String duplicateRouteName(String name, Iterable<String> existing) {
  final taken = existing.map((e) => e.toLowerCase()).toSet();
  var candidate = '$name-copy';
  for (var i = 2; taken.contains(candidate.toLowerCase()); i++) {
    candidate = '$name-copy-$i';
  }
  return candidate;
}

class RoutesFormWidget extends StatefulWidget {
  final String gatewayUrl;

  final RoutesFormAction action;

  final RouteModel? route;
  final void Function(RouteFormModel model) onSave;
  final Map<String, String>? failValidations;

  const RoutesFormWidget({
    required this.onSave,
    required this.action,
    required this.gatewayUrl,
    this.route,
    this.failValidations,
    super.key,
  });

  @override
  State<RoutesFormWidget> createState() => _RoutesFormWidgetState();
}

class _RoutesFormWidgetState extends State<RoutesFormWidget> {
  static const _name = 'name';
  static const _path = 'path';
  static const _uri = 'uri';
  static const _rewriteFrom = 'rewrite_path.replace_from';
  static const _rewriteTo = 'rewrite_path.replace_to';
  static const _description = 'description';

  final _nameCtrl = TextEditingController();
  final _uriCtrl = TextEditingController();
  final _pathCtrl = TextEditingController();
  final _rewriteFromCtrl = TextEditingController();
  final _rewriteToCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  //local copy: clearing it must not mutate the cubit state's map
  Map<String, String> _errors = {};

  List<RouteModel> get _routes => app.di.find<RoutesCubit>().routes;

  bool get _isEdit => widget.action == RoutesFormAction.edit;

  bool get _isDuplicate => widget.action == RoutesFormAction.duplicate;

  @override
  void initState() {
    super.initState();
    _errors = {...?widget.failValidations};

    final route = widget.route;
    if (route != null) {
      _nameCtrl.text = _isDuplicate
          ? duplicateRouteName(route.name, _routes.map((r) => r.name))
          : route.name;
      _uriCtrl.text = route.uri;
      _pathCtrl.text = route.path;
      _rewriteFromCtrl.text = route.rewritePath?.replaceFrom ?? '';
      _rewriteToCtrl.text = route.rewritePath?.replaceTo ?? '';
      _descriptionCtrl.text = route.description;
    }
  }

  @override
  void didUpdateWidget(covariant RoutesFormWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.failValidations != oldWidget.failValidations) {
      setState(() => _errors = {...?widget.failValidations});
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _uriCtrl.dispose();
    _pathCtrl.dispose();
    _rewriteFromCtrl.dispose();
    _rewriteToCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  RouteFormModel _model() => RouteFormModel(
    gatewayUrl: widget.gatewayUrl,
    name: _nameCtrl.text.trim(),
    uri: _uriCtrl.text.trim(),
    path: _pathCtrl.text.trim(),
    description: _descriptionCtrl.text.trim(),
    rewritePath: RewritePathModel.fromFields(
      from: _rewriteFromCtrl.text.trim(),
      to: _rewriteToCtrl.text.trim(),
    ),
  );

  Map<String, String> _validate(RouteFormModel model) {
    final form = app.intl.form;
    final currentId = _isEdit ? widget.route?.id : null;
    final nameTaken = _routes.any(
      (r) =>
          r.id != currentId && r.name.toLowerCase() == model.name.toLowerCase(),
    );
    return {
      if (model.name.isEmpty)
        _name: form.nameRequired
      else if (nameTaken)
        _name: form.nameTaken,
      if (!model.path.startsWith('/')) _path: form.pathInvalid,
      if (!RegExp(r'^https?://\S+$').hasMatch(model.uri)) _uri: form.uriInvalid,
    };
  }

  void _save() {
    final model = _model();
    final errors = _validate(model);
    setState(() => _errors = errors);
    if (errors.isEmpty) widget.onSave(model);
  }

  void _clearError(String key) {
    if (_errors.containsKey(key)) setState(() => _errors.remove(key));
  }

  Widget _field(
    String key, {
    required String label,
    required TextEditingController controller,
    String? hint,
    bool required = false,
    bool mono = false,
    bool autofocus = false,
    int maxLength = 255,
  }) => AppField(
    label: label,
    controller: controller,
    required: required,
    hint: hint,
    mono: mono,
    autofocus: autofocus,
    maxLength: maxLength,
    errorText: _errors[key],
    onChanged: (_) => _clearError(key),
    onSubmitted: (_) => _save(),
  );

  @override
  Widget build(BuildContext context) {
    final intl = context.intl;
    final form = intl.form;
    return DialogTemplate(
      title: _isEdit
          ? intl.routes.editRoute
          : _isDuplicate
          ? intl.routes.duplicateRoute
          : intl.routes.createRoute,
      subtitle: _isEdit
          ? form.editSubtitle
          : _isDuplicate
          ? form.duplicateSubtitle
          : form.createSubtitle,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppButton(
            label: intl.actions.cancel,
            kind: AppButtonKind.outlined,
            height: 44,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          AppButton(
            label: _isEdit ? form.saveChanges : intl.routes.createRoute,
            height: 44,
            onPressed: _save,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isDuplicate && widget.route != null) ...[
            _DuplicateNote(name: widget.route!.name),
            const SizedBox(height: 16),
          ],
          _field(
            _name,
            label: form.nameLabel,
            controller: _nameCtrl,
            hint: form.nameHint,
            required: true,
            autofocus: true,
          ),
          const SizedBox(height: 16),
          _pair(
            _field(
              _path,
              label: form.pathLabel,
              controller: _pathCtrl,
              hint: form.pathHint,
              required: true,
              mono: true,
            ),
            _field(
              _uri,
              label: form.uriLabel,
              controller: _uriCtrl,
              hint: form.uriHint,
              required: true,
              mono: true,
            ),
          ),
          const SizedBox(height: 16),
          _pair(
            _field(
              _rewriteFrom,
              label: form.rewritePathFromLabel,
              controller: _rewriteFromCtrl,
              hint: form.rewritePathFromHint,
              mono: true,
              maxLength: 155,
            ),
            _field(
              _rewriteTo,
              label: form.rewritePathToLabel,
              controller: _rewriteToCtrl,
              hint: form.rewritePathToHint,
              mono: true,
              maxLength: 155,
            ),
          ),
          const SizedBox(height: 16),
          _field(
            _description,
            label: form.descriptionLabel,
            controller: _descriptionCtrl,
            hint: form.descriptionHint,
            maxLength: 1024,
          ),
          const SizedBox(height: 16),
          FieldLabel(form.preview),
          const SizedBox(height: 8),
          ListenableBuilder(
            listenable: Listenable.merge([
              _nameCtrl,
              _uriCtrl,
              _pathCtrl,
              _rewriteFromCtrl,
              _rewriteToCtrl,
            ]),
            builder: (context, _) => _buildPreview(context),
          ),
        ],
      ),
    );
  }

  Widget _pair(Widget left, Widget right) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: left),
      const SizedBox(width: 16),
      Expanded(child: right),
    ],
  );

  Widget _buildPreview(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final model = _model();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.outlineCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            model.name.isEmpty ? intl.form.previewName : model.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: c.text,
            ),
          ),
          const SizedBox(height: 8),
          RouteUrlBlock(
            caption: intl.routes.from,
            url: model.path.isEmpty
                ? '${widget.gatewayUrl}…'
                : model.enterPoint,
          ),
          const SizedBox(height: 8),
          RouteUrlBlock(
            caption: intl.routes.to,
            url: model.uri.isEmpty ? 'https://…' : model.redirectTo,
            accent: true,
          ),
        ],
      ),
    );
  }
}

class _DuplicateNote extends StatelessWidget {
  final String name;

  const _DuplicateNote({required this.name});

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final form = context.intl.form;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.lilac.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.lilac.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          app.assets.icons.actions.duplicate.build(size: 18, color: c.lilac),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: '${form.duplicatingStart} ',
                children: [
                  TextSpan(
                    text: name,
                    style: monoStyle(color: c.lilac, weight: FontWeight.w500),
                  ),
                  TextSpan(text: form.duplicatingEnd),
                ],
              ),
              style: TextStyle(fontSize: 13, height: 19 / 13, color: c.text),
            ),
          ),
        ],
      ),
    );
  }
}
