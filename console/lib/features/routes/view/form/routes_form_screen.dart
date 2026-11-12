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
            onValidate: (model) => cubit.validate(model: model),
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

class RoutesFormWidget extends StatefulWidget {
  final String gatewayUrl;

  final RoutesFormAction action;

  final RouteModel? route;
  final void Function(RouteFormModel model) onSave;

  ///the fields the api rejects, without saving (null: it couldn't be checked)
  final Future<Map<String, String>?> Function(RouteFormModel model) onValidate;
  final Map<String, String>? failValidations;

  const RoutesFormWidget({
    required this.onSave,
    required this.onValidate,
    required this.action,
    required this.gatewayUrl,
    this.route,
    this.failValidations,
    super.key,
  });

  @override
  State<RoutesFormWidget> createState() => _RoutesFormWidgetState();
}

///one field of the form: its api name, controller and focus
class _Field {
  final String key;
  final int step;
  final TextEditingController ctrl = TextEditingController();
  final FocusNode focus = FocusNode();

  ///the whole field (label, input and error), to scroll it into view
  final GlobalKey box = GlobalKey();

  _Field(this.key, this.step);

  void dispose() {
    ctrl.dispose();
    focus.dispose();
  }
}

class _RoutesFormWidgetState extends State<RoutesFormWidget> {
  static const _steps = 3;

  final _name = _Field('name', 1);
  final _description = _Field('description', 1);
  final _path = _Field('path', 2);
  final _uri = _Field('uri', 2);
  final _rewriteFrom = _Field('rewrite_path.replace_from', 3);
  final _rewriteTo = _Field('rewrite_path.replace_to', 3);

  late final List<_Field> _fields = [
    _name,
    _description,
    _path,
    _uri,
    _rewriteFrom,
    _rewriteTo,
  ];

  int _step = 1;
  bool _busy = false;

  ///only when the dialog opens: later the focus moves with the steps and the pencils
  bool _autofocusName = true;

  //local copy: clearing it must not mutate the cubit state's map
  Map<String, String> _errors = {};

  List<RouteModel> get _routes => app.di.find<RoutesCubit>().routes;

  bool get _isEdit => widget.action == RoutesFormAction.edit;

  bool get _isDuplicate => widget.action == RoutesFormAction.duplicate;

  @override
  void initState() {
    super.initState();
    final route = widget.route;
    if (route != null) {
      _name.ctrl.text = _isDuplicate
          ? duplicateRouteName(route.name, _routes.map((r) => r.name))
          : route.name;
      _uri.ctrl.text = route.uri;
      _path.ctrl.text = route.path;
      _rewriteFrom.ctrl.text = route.rewritePath?.replaceFrom ?? '';
      _rewriteTo.ctrl.text = route.rewritePath?.replaceTo ?? '';
      _description.ctrl.text = route.description;
    }
    _showErrors(widget.failValidations);
  }

  @override
  void didUpdateWidget(covariant RoutesFormWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.failValidations != oldWidget.failValidations) {
      setState(() => _showErrors(widget.failValidations));
    }
  }

  @override
  void dispose() {
    for (final f in _fields) {
      f.dispose();
    }
    super.dispose();
  }

  RouteFormModel _model() => RouteFormModel(
    gatewayUrl: widget.gatewayUrl,
    name: _name.ctrl.text.trim(),
    uri: _uri.ctrl.text.trim(),
    path: _path.ctrl.text.trim(),
    description: _description.ctrl.text.trim(),
    rewritePath: RewritePathModel.fromFields(
      from: _rewriteFrom.ctrl.text.trim(),
      to: _rewriteTo.ctrl.text.trim(),
    ),
  );

  ///step of an api field name; `rewrite_path` and its children go to the last one
  int _stepOf(String key) =>
      _fields.where((f) => f.key == key).firstOrNull?.step ??
      (key.startsWith('rewrite_path') ? 3 : 1);

  ///shows [errors] (api names) and goes to the first step with one
  void _showErrors(Map<String, String>? errors) {
    _errors = {...?errors};
    if (_errors.isNotEmpty) {
      _step = _errors.keys.map(_stepOf).reduce((a, b) => a < b ? a : b);
    }
  }

  ///the rules are the api's (`POST /routes/validate`); only the taken name is checked here, against the list
  Future<Map<String, String>?> _check(RouteFormModel model) async {
    final errors = await widget.onValidate(model);
    if (errors == null) return null;
    final currentId = _isEdit ? widget.route?.id : null;
    final nameTaken =
        model.name.isNotEmpty &&
        _routes.any(
          (r) =>
              r.id != currentId &&
              r.name == model.name,
        );
    return {
      ...errors,
      if (nameTaken && !errors.containsKey(_name.key))
        _name.key: app.intl.form.nameTaken,
    };
  }

  ///Next validates only its step; the last one validates everything and saves
  Future<void> _next() async {
    if (_busy) return;
    final model = _model();
    setState(() => _busy = true);
    final errors = await _check(model);
    if (!mounted) return;
    setState(() => _busy = false);
    if (errors == null) return;

    if (_step < _steps) {
      final mine = {
        for (final e in errors.entries)
          if (_stepOf(e.key) == _step) e.key: e.value,
      };
      setState(() => _errors = mine);
      _goTo(mine.isEmpty ? _step + 1 : _step, _firstWithError());
      return;
    }
    setState(() => _showErrors(errors));
    if (errors.isEmpty) {
      widget.onSave(model);
    } else {
      _goTo(_step, _firstWithError());
    }
  }

  _Field? _firstWithError() => _fields
      .where((f) => f.step == _step && _errors.containsKey(f.key))
      .firstOrNull;

  ///shows [step] and focuses [field] (its first one by default), selecting its text
  void _goTo(int step, [_Field? field]) {
    setState(() {
      _step = step;
      _autofocusName = false;
    });
    final target = field ?? _fields.firstWhere((f) => f.step == step);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      target.focus.requestFocus();
      target.ctrl.selection = TextSelection(
        baseOffset: 0,
        extentOffset: target.ctrl.text.length,
      );
      //focus only scrolls to the input; this also brings its error text into view
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final box = target.box.currentContext;
        if (box == null || !box.mounted) return;
        Scrollable.ensureVisible(
          box,
          duration: const Duration(milliseconds: 150),
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      });
    });
  }

  void _back() {
    if (_step == 1) {
      Navigator.of(context).pop();
    } else {
      _goTo(_step - 1);
    }
  }

  void _clearError(String key) {
    if (_errors.containsKey(key)) setState(() => _errors.remove(key));
  }

  Widget _input(
    _Field field, {
    required String label,
    String? hint,
    bool required = false,
    bool mono = false,
    int maxLength = 255,
  }) => AppField(
    key: field.box,
    label: label,
    controller: field.ctrl,
    focusNode: field.focus,
    required: required,
    hint: hint,
    mono: mono,
    autofocus: _autofocusName && field == _name,
    maxLength: maxLength,
    errorText: _errors[field.key],
    onChanged: (_) => _clearError(field.key),
    onSubmitted: (_) => _next(),
  );

  String _stepName(int step) {
    final form = context.intl.form;
    return switch (step) {
      1 => form.stepGeneral,
      2 => form.stepForwarding,
      _ => form.stepRewrite,
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final form = intl.form;
    return DialogFrame(
      width: 600,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      alignment: Alignment.topCenter,
      child: SizedBox(
        //all the height: the footer doesn't jump between steps
        height: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(context),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.raised)),
              ),
              child: ListenableBuilder(
                listenable: Listenable.merge(_fields.map((f) => f.ctrl)),
                builder: (context, _) => _RoutePreview(
                  model: _model(),
                  gatewayUrl: widget.gatewayUrl,
                  rewriteFrom: _rewriteFrom.ctrl.text.trim(),
                  rewriteTo: _rewriteTo.ctrl.text.trim(),
                  onEditName: () => _goTo(1, _name),
                  onEditDescription: () => _goTo(1, _description),
                  onEditPath: () => _goTo(2, _path),
                  onEditUri: () => _goTo(2, _uri),
                  onEditRewrite: () => _goTo(3, _rewriteFrom),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                child: _stepBody(context),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.raised)),
              ),
              child: Row(
                children: [
                  _Stepper(current: _step, count: _steps, nameOf: _stepName),
                  const Spacer(),
                  AppButton(
                    label: _step == 1 ? intl.actions.cancel : intl.actions.back,
                    kind: AppButtonKind.outlined,
                    height: 44,
                    onPressed: _back,
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    label: _step < _steps
                        ? form.next
                        : (_isEdit
                              ? form.saveChanges
                              : intl.routes.createRoute),
                    height: 44,
                    onPressed: _busy ? null : _next,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final form = intl.form;
    final route = widget.route;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 12, 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.raised)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _isEdit
                          ? intl.routes.editRoute
                          : _isDuplicate
                          ? intl.routes.duplicateRoute
                          : intl.routes.createRoute,
                      style: TextStyle(
                        fontSize: 20,
                        height: 28 / 20,
                        fontWeight: FontWeight.w500,
                        color: c.text,
                      ),
                    ),
                    if (_isDuplicate && route != null) ...[
                      const SizedBox(width: 10),
                      Flexible(child: _DuplicateChip(name: route.name)),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _isEdit
                      ? form.editSubtitle
                      : _isDuplicate
                      ? form.duplicateSubtitle
                      : form.createSubtitle,
                  style: TextStyle(
                    fontSize: 13,
                    height: 18 / 13,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          AppIconButton(
            icon: app.assets.icons.actions.close,
            tooltip: intl.actions.close,
            size: 44,
            iconSize: 20,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _stepBody(BuildContext context) {
    final form = context.intl.form;
    final (title, help, fields) = switch (_step) {
      1 => (
        form.stepGeneral,
        form.stepGeneralHint,
        <Widget>[
          _input(
            _name,
            label: form.nameLabel,
            hint: form.nameHint,
            required: true,
          ),
          _input(
            _description,
            label: form.descriptionLabel,
            hint: form.descriptionHint,
            maxLength: 1024,
          ),
        ],
      ),
      2 => (
        form.stepForwarding,
        form.stepForwardingHint,
        <Widget>[
          _input(
            _path,
            label: form.pathLabel,
            hint: form.pathHint,
            required: true,
            mono: true,
          ),
          _input(
            _uri,
            label: form.uriLabel,
            hint: form.uriHint,
            required: true,
            mono: true,
          ),
        ],
      ),
      _ => (
        form.stepRewrite,
        form.stepRewriteHint,
        <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _input(
                  _rewriteFrom,
                  label: form.rewritePathFromLabel,
                  hint: form.rewritePathFromHint,
                  mono: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _input(
                  _rewriteTo,
                  label: form.rewritePathToLabel,
                  hint: form.rewritePathToHint,
                  mono: true,
                ),
              ),
            ],
          ),
        ],
      ),
    };
    final c = app.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            height: 22 / 16,
            fontWeight: FontWeight.w600,
            color: c.text,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          help,
          style: TextStyle(
            fontSize: 12,
            height: 16 / 12,
            color: c.textTertiary,
          ),
        ),
        for (final field in fields) ...[const SizedBox(height: 14), field],
      ],
    );
  }
}

///the route as its card in Routes will show it, with a pencil per value that opens its field
class _RoutePreview extends StatelessWidget {
  final RouteFormModel model;
  final String gatewayUrl;
  final String rewriteFrom;
  final String rewriteTo;
  final VoidCallback onEditName;
  final VoidCallback onEditDescription;
  final VoidCallback onEditPath;
  final VoidCallback onEditUri;
  final VoidCallback onEditRewrite;

  const _RoutePreview({
    required this.model,
    required this.gatewayUrl,
    required this.rewriteFrom,
    required this.rewriteTo,
    required this.onEditName,
    required this.onEditDescription,
    required this.onEditPath,
    required this.onEditUri,
    required this.onEditRewrite,
  });

  Widget _pencil(String tooltip, VoidCallback onPressed) => AppIconButton(
    icon: app.assets.icons.actions.edit,
    tooltip: tooltip,
    size: 28,
    iconSize: 14,
    radius: 8,
    color: app.colors.textTertiary,
    onPressed: onPressed,
  );

  ///the value, or its placeholder dimmed
  Widget _value(String value, String placeholder, TextStyle style) => Text(
    value.isEmpty ? placeholder : value,
    style: value.isEmpty
        ? style.copyWith(color: app.colors.textPlaceholder)
        : style,
  );

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final form = intl.form;
    final url = monoStyle(size: 13, height: 20 / 13, color: c.text);
    final hasRewrite = rewriteFrom.isNotEmpty || rewriteTo.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.outlineCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: DefaultTextStyle.merge(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            child: _value(
                              model.name,
                              form.previewName,
                              TextStyle(
                                fontSize: 19,
                                height: 26 / 19,
                                fontWeight: FontWeight.w500,
                                color: c.text,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        _pencil(form.editName, onEditName),
                      ],
                    ),
                    Transform.translate(
                      offset: const Offset(0, -4),
                      child: Row(
                        children: [
                          Flexible(
                            child: DefaultTextStyle.merge(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              child: _value(
                                model.description,
                                intl.routes.noDescription,
                                TextStyle(
                                  fontSize: 13,
                                  height: 18 / 13,
                                  color: c.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          _pencil(form.editDescription, onEditDescription),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.raised,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  form.preview,
                  style: TextStyle(
                    fontSize: 11,
                    height: 16 / 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: c.label,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 6, 6, 10),
            decoration: BoxDecoration(
              color: c.night,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.outlineSoft),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _urlHeader(intl.routes.from, false, form.editPath, onEditPath),
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _value(
                    model.path.isEmpty ? '' : model.enterPoint,
                    '$gatewayUrl/…',
                    url,
                  ),
                ),
                Container(
                  height: 1,
                  margin: const EdgeInsets.fromLTRB(0, 8, 6, 2),
                  color: c.outlineSoft,
                ),
                _urlHeader(intl.routes.to, true, form.editUri, onEditUri),
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _value(
                    model.uri.isEmpty ? '' : model.redirectTo,
                    'https://…',
                    url,
                  ),
                ),
                if (hasRewrite)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text.rich(
                            TextSpan(
                              text: '${form.rewrite} ',
                              children: [
                                TextSpan(
                                  text:
                                      '${rewriteFrom.isEmpty ? '…' : rewriteFrom} → ${rewriteTo.isEmpty ? '…' : rewriteTo}',
                                  style: monoStyle(size: 12, color: c.label),
                                ),
                              ],
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              height: 16 / 12,
                              color: c.textTertiary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _pencil(form.editRewrite, onEditRewrite),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _urlHeader(
    String caption,
    bool accent,
    String tooltip,
    VoidCallback onEdit,
  ) {
    final c = app.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CaptionText(caption, color: accent ? c.lilac : c.textTertiary),
        _pencil(tooltip, onEdit),
      ],
    );
  }
}

///compact steps: only the current one shows its name, the others their number (✓ when done) with a tooltip
class _Stepper extends StatelessWidget {
  final int current;
  final int count;
  final String Function(int step) nameOf;

  const _Stepper({
    required this.current,
    required this.count,
    required this.nameOf,
  });

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final form = context.intl.form;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var step = 1; step <= count; step++) ...[
          Tooltip(
            message: form.stepOf(step: step, name: nameOf(step)),
            child: Semantics(
              selected: step == current,
              label: form.stepOf(step: step, name: nameOf(step)),
              child: ExcludeSemantics(child: _dot(c, step)),
            ),
          ),
          if (step == current) ...[
            const SizedBox(width: 6),
            ExcludeSemantics(
              child: Text(
                nameOf(step),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.text,
                ),
              ),
            ),
          ],
          if (step < count)
            Container(
              width: 16,
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color: step < current ? c.lilac : c.outlineCard,
            ),
        ],
      ],
    );
  }

  Widget _dot(AppColors c, int step) {
    final done = step < current;
    final now = step == current;
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: now
            ? c.lilac
            : done
            ? c.lilac.withValues(alpha: 0.16)
            : Colors.transparent,
        border: Border.all(color: done || now ? c.lilac : c.outline),
      ),
      child: done
          ? app.assets.icons.general.check.build(size: 13, color: c.lilac)
          : Text(
              '$step',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: now ? c.onLilac : c.textTertiary,
              ),
            ),
    );
  }
}

///duplicate: the name of the source route; its ⓘ opens the note about reviewing the copy
class _DuplicateChip extends StatefulWidget {
  final String name;

  const _DuplicateChip({required this.name});

  @override
  State<_DuplicateChip> createState() => _DuplicateChipState();
}

class _DuplicateChipState extends State<_DuplicateChip> {
  final _popup = OverlayPortalController();
  final _link = LayerLink();

  void _toggle() => setState(_popup.toggle);

  void _hide() {
    if (_popup.isShowing) setState(_popup.hide);
  }

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final form = context.intl.form;
    return TapRegion(
      groupId: _link,
      onTapOutside: (_) => _hide(),
      child: CompositedTransformTarget(
        link: _link,
        child: OverlayPortal(
          controller: _popup,
          overlayChildBuilder: (context) => CompositedTransformFollower(
            link: _link,
            targetAnchor: Alignment.bottomLeft,
            offset: const Offset(0, 10),
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: TapRegion(groupId: _link, child: _note(context, c)),
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Semantics(
              button: true,
              expanded: _popup.isShowing,
              label: form.aboutDuplicating(name: widget.name),
              child: Material(
                color: c.lilac.withValues(alpha: 0.10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: c.lilac.withValues(alpha: 0.35)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _toggle,
                  child: Container(
                    height: 28,
                    padding: const EdgeInsets.only(left: 10, right: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: ExcludeSemantics(
                            child: Text(
                              widget.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: monoStyle(
                                size: 13,
                                weight: FontWeight.w500,
                                color: c.lilac,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        app.assets.icons.general.info.build(
                          size: 15,
                          color: c.lilac,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _note(BuildContext context, AppColors c) {
    final form = context.intl.form;
    return Material(
      color: c.popupLilac,
      elevation: 16,
      shadowColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: c.lilac.withValues(alpha: 0.35)),
      ),
      child: Container(
        width: 360,
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: app.assets.icons.actions.duplicate.build(
                size: 18,
                color: c.lilac,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: '${form.duplicatingStart} ',
                  children: [
                    TextSpan(
                      text: widget.name,
                      style: monoStyle(color: c.lilac, weight: FontWeight.w500),
                    ),
                    TextSpan(text: form.duplicatingEnd),
                  ],
                ),
                style: TextStyle(fontSize: 13, height: 19 / 13, color: c.text),
              ),
            ),
            const SizedBox(width: 4),
            AppIconButton(
              icon: app.assets.icons.actions.close,
              tooltip: context.intl.actions.close,
              size: 28,
              iconSize: 14,
              radius: 8,
              onPressed: _hide,
            ),
          ],
        ),
      ),
    );
  }
}
