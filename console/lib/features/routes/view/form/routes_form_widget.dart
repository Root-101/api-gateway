import 'package:console/app_exporter.dart';
import 'package:console/features/routes/view/form/route_form_field.dart';
import 'package:console/features/routes/view/form/routes_form_screen.dart';
import 'package:console/features/routes/view/form/widgets/route_form_preview.dart';
import 'package:console/features/routes/view/form/widgets/route_form_footer.dart';
import 'package:console/features/routes/view/form/widgets/route_form_header.dart';
import 'package:console/features/routes/view/form/widgets/route_form_step.dart';
import 'package:material_ui/material_ui.dart';

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

///the form's state: its fields, the step, validation against the api and saving;
///header, preview, step and footer are widgets of their own
class _RoutesFormWidgetState extends State<RoutesFormWidget> {
  static const _steps = 3;

  final _name = RouteFormField('name', 1);
  final _description = RouteFormField('description', 1);
  final _path = RouteFormField('path', 2);
  final _uri = RouteFormField('uri', 2);
  final _rewriteFrom = RouteFormField('rewrite_path.replace_from', 3);
  final _rewriteTo = RouteFormField('rewrite_path.replace_to', 3);

  late final List<RouteFormField> _fields = [
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
        _routes.any((r) => r.id != currentId && r.name == model.name);
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

  RouteFormField? _firstWithError() => _fields
      .where((f) => f.step == _step && _errors.containsKey(f.key))
      .firstOrNull;

  ///shows [step] and focuses [field] (its first one by default), selecting its text
  void _goTo(int step, [RouteFormField? field]) {
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
    RouteFormField field, {
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

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
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
            RouteFormHeader(action: widget.action, route: widget.route),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              decoration: BoxDecoration(
                color: c.card,
                border: Border(bottom: BorderSide(color: c.raised)),
              ),
              child: ListenableBuilder(
                listenable: Listenable.merge(_fields.map((f) => f.ctrl)),
                builder: (context, _) => RouteFormPreview(
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
            RouteFormFooter(
              step: _step,
              steps: _steps,
              isEdit: _isEdit,
              busy: _busy,
              onBack: _back,
              onNext: _next,
            ),
          ],
        ),
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
    return RouteFormStep(title: title, help: help, fields: fields);
  }
}
