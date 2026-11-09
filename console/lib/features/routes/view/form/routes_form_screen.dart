import 'package:api_gateway_front/app_exporter.dart';
import 'package:api_gateway_front/features/routes/view/form/routes_advanced_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class RoutesFormScreenNavigator {
  void create() {
    DialogTemplate.open(
      title: app.intl.actions.create,
      child: BlocProvider(
        create: (BuildContext context) => RoutesFormCubit(
          auth: app.di.find(),
          repo: app.di.find(),
          action: RoutesFormAction.create,
        ),
        lazy: false,
        child: const RoutesFormScreen(),
      ),
    );
  }

  String get editName => 'routeEdit';

  ///child of `/routes`: `/routes/:id/edit`
  String get editPath => ':id/edit';

  ///opened from the card (model in `extra`) or from the url (only the id: the route is loaded)
  Page<void> editPageBuilder(BuildContext context, GoRouterState state) {
    final model = state.extra is RouteModel ? state.extra as RouteModel : null;
    return DialogPage(
      key: state.pageKey,
      dialog: DialogTemplate(
        title: app.intl.actions.edit,
        child: BlocProvider(
          create: (BuildContext context) => RoutesFormCubit(
            auth: app.di.find(),
            repo: app.di.find(),
            action: RoutesFormAction.edit,
            paramRouteId: state.pathParameters['id'],
            paramRouteModel: model,
          ),
          lazy: false,
          child: const RoutesFormScreen(),
        ),
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
    DialogTemplate.open(
      title: app.intl.actions.duplicate,
      child: BlocProvider(
        create: (BuildContext context) => RoutesFormCubit(
          auth: app.di.find(),
          repo: app.di.find(),
          action: RoutesFormAction.duplicate,
          paramRouteId: model.id,
          paramRouteModel: model,
        ),
        lazy: false,
        child: const RoutesFormScreen(),
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RoutesFormCubit, RoutesFormState>(
      listener: (context, state) {
        if (state is RoutesFormProcessInProgressState) {
          app.loading.show();
        } else if (state is RoutesFormProcessingErrorState) {
          app.loading.hide();
          app.snack.showError(
            message: state.exception.message,
            context: context,
          );
        } else if (state is RoutesFormValidationErrorState) {
          app.loading.hide();
        } else if (state is RoutesFormProcessingOKState) {
          app.loading.hide();
          app.navigator.pop();
        }
      },
      buildWhen: (previous, current) => current is RoutesFormLoadingState,
      builder: (context, state) {
        if (state is RoutesFormLoadingInProgressState) {
          return const LoadingPage();
        } else if (state is RoutesFormLoadingSuccessState) {
          return RoutesFormWidget(
            failValidations: (state is RoutesFormValidationErrorState)
                ? state.failValidations
                : {},
            action: state.action,
            route: state.routeModel,
            gatewayUrl: state.gatewayUrl,
            onCreate: (create) {
              cubit.create(model: create);
            },
            onEdit: (edit) {
              cubit.edit(model: edit);
            },
          );
        } else if (state is RoutesFormLoadingErrorState) {
          return ErrorPage(
            errorMessage: state.text,
            buttonText: app.intl.actions.back,
            onPressed: () {
              app.navigator.pop();
            },
          );
        } else {
          return ErrorPage(
            buttonText: app.intl.actions.back,
            onPressed: () {
              app.navigator.pop();
            },
          );
        }
      },
    );
  }
}

class RoutesFormWidget extends StatefulWidget {
  final String gatewayUrl;

  final RoutesFormAction action;

  final RouteModel? route;
  final void Function(RouteFormModel create) onCreate;
  final void Function(RouteFormModel edit) onEdit;
  final Map<String, String>? failValidations;

  const RoutesFormWidget({
    required this.onCreate,
    required this.onEdit,
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
  final RoutesFormValidator validator = RoutesFormValidator();

  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _uriCtrl = TextEditingController();
  final _pathCtrl = TextEditingController();
  final _rewriteFromCtrl = TextEditingController();
  final _rewriteToCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  //local copy: clearing it must not mutate the cubit state's map
  Map<String, String> _apiErrors = {};

  //filled once like the text fields: the state after a 422 on duplicate has no route
  final _advanced = RouteAdvancedFormController();
  bool _advancedExpanded = false;

  @override
  void initState() {
    super.initState();
    _apiErrors = {...?widget.failValidations};

    if (widget.route != null) {
      _advanced.load(widget.route!.advanced);
      _advancedExpanded = !widget.route!.advanced.isDefault;
      _nameCtrl.text = widget.route!.name;
      _uriCtrl.text = widget.route!.uri;
      _pathCtrl.text = widget.route!.path;
      _rewriteFromCtrl.text = widget.route!.rewritePath?.replaceFrom ?? '';
      _rewriteToCtrl.text = widget.route!.rewritePath?.replaceTo ?? '';
      _descriptionCtrl.text = widget.route!.description;
    }
  }

  @override
  void didUpdateWidget(covariant RoutesFormWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.failValidations != oldWidget.failValidations) {
      _apiErrors = {...?widget.failValidations};
      _advancedExpanded |= _apiErrors.keys.any(isAdvancedRouteError);
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
    _advanced.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String? nameErrorText = _apiErrors['name'];
    String? uriErrorText = _apiErrors['uri'];
    String? pathErrorText = _apiErrors['path'];
    String? rewriteFromErrorText = _apiErrors['rewrite_path.replace_from'];
    String? rewriteToErrorText = _apiErrors['rewrite_path.replace_to'];

    return Scaffold(
      backgroundColor: app.colors.neutral.transparent,
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: app.dimensions.padding.l,
            vertical: app.dimensions.padding.m,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ///-------------- NAME --------------\\\
                AppTextInput.textField(
                  controller: _nameCtrl,
                  errorText: nameErrorText,
                  label: app.intl.routes.nameLabel,
                  hint: app.intl.routes.nameHint,
                  maxLength: validator.required.maxLong,
                  validator: validator.required.validator,
                ),
                app.dimensions.padding.m.gap(),

                ///-------------- PATH --------------\\\
                AppTextInput.textField(
                  controller: _pathCtrl,
                  errorText: pathErrorText,
                  label: app.intl.routes.pathLabel,
                  hint: app.intl.routes.pathHint,
                  maxLength: validator.required.maxLong,
                  validator: validator.required.validator,
                ),
                app.dimensions.padding.m.gap(),

                ///-------------- URI --------------\\\
                AppTextInput.textField(
                  controller: _uriCtrl,
                  errorText: uriErrorText,
                  label: app.intl.routes.uriLabel,
                  hint: app.intl.routes.uriHint,
                  maxLength: validator.uri.max,
                  validator: validator.uri.validator,
                ),
                app.dimensions.padding.m.gap(),

                ///-------------- Rewrite: FROM - TO --------------\\\
                Row(
                  children: [
                    ///-------------- FROM--------------\\\
                    Expanded(
                      child: AppTextInput.textField(
                        controller: _rewriteFromCtrl,
                        errorText: rewriteFromErrorText,
                        label: app.intl.routes.rewritePathFromLabel,
                        hint: app.intl.routes.rewritePathFromHint,
                        maxLength: validator.required.maxShort,
                        validator: (value) => validator.required
                            .pairedValidator(value, _rewriteToCtrl.text),
                      ),
                    ),
                    app.dimensions.padding.m.gap(),

                    ///-------------- TO--------------\\\
                    Expanded(
                      child: AppTextInput.textField(
                        controller: _rewriteToCtrl,
                        errorText: rewriteToErrorText,
                        label: app.intl.routes.rewritePathToLabel,
                        hint: app.intl.routes.rewritePathToHint,
                        maxLength: validator.required.maxShort,
                        validator: (value) => validator.required
                            .pairedValidator(value, _rewriteFromCtrl.text),
                      ),
                    ),
                  ],
                ),
                app.dimensions.padding.m.gap(),

                ///-------------- DESCRIPTION --------------\                //optional in the api (text column, no length limit)
                AppTextInput.textField(
                  controller: _descriptionCtrl,
                  errorText: _apiErrors['description'],
                  label: app.intl.routes.descriptionLabel,
                  hint: app.intl.routes.descriptionHint,
                  maxLines: 3,
                ),
                app.dimensions.padding.m.gap(),

                ///-------------- ADVANCED --------------\\\
                RoutesAdvancedSection(
                  controller: _advanced,
                  errors: _apiErrors,
                  expanded: _advancedExpanded,
                  requiredValidator: validator.required.validator,
                  onToggle: () => setState(
                    () => _advancedExpanded = !_advancedExpanded,
                  ),
                  onChanged: () => setState(
                    () => _apiErrors.removeWhere(
                      (source, _) => isAdvancedRouteError(source),
                    ),
                  ),
                ),
                app.dimensions.padding.xxl.gap(),

                ///-------------- PREVIEW --------------\\\
                Text(app.intl.routes.preview, style: app.textTheme.labelMedium),
                app.dimensions.padding.xs.gap(),
                ListenableBuilder(
                  listenable: Listenable.merge([
                    _nameCtrl,
                    _uriCtrl,
                    _pathCtrl,
                    _rewriteFromCtrl,
                    _rewriteToCtrl,
                  ]),
                  builder: (context, _) {
                    return _buildSingleRouteTile(
                      model: RouteFormModel(
                        gatewayUrl: widget.gatewayUrl,
                        name: _nameCtrl.text,
                        uri: _uriCtrl.text,
                        path: _pathCtrl.text,
                        description: _descriptionCtrl.text,
                        rewritePath: RewritePathModel.fromFields(
                          from: _rewriteFromCtrl.text,
                          to: _rewriteToCtrl.text,
                        ),
                      ),
                    );
                  },
                ),

                ///-------------- FINAL GAP --------------\\\
                80.gap(),
              ],
            ),
          ),
        ),
      ),
      bottomSheet: Padding(
        padding: EdgeInsets.all(app.dimensions.padding.l),
        child: PrimaryButton.primary(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              //the invalid field can be inside the collapsed section
              if (_advanced.hasValues) {
                setState(() => _advancedExpanded = true);
              }
              return;
            } else {
              //remove focus from the text field to hide the keyboard
              FocusManager.instance.primaryFocus?.unfocus();

              //clear old api validation errors
              setState(() => _apiErrors = {});

              if (widget.action == RoutesFormAction.create ||
                  widget.action == RoutesFormAction.duplicate) {
                widget.onCreate(
                  RouteFormModel(
                    advanced: _advanced.toModel(),
                    name: _nameCtrl.text,
                    uri: _uriCtrl.text,
                    path: _pathCtrl.text,
                    description: _descriptionCtrl.text,
                    rewritePath: RewritePathModel.fromFields(
                      from: _rewriteFromCtrl.text,
                      to: _rewriteToCtrl.text,
                    ),
                  ),
                );
              } else if (widget.action == RoutesFormAction.edit) {
                widget.onEdit(
                  RouteFormModel(
                    advanced: _advanced.toModel(),
                    name: _nameCtrl.text,
                    uri: _uriCtrl.text,
                    path: _pathCtrl.text,
                    description: _descriptionCtrl.text,
                    rewritePath: RewritePathModel.fromFields(
                      from: _rewriteFromCtrl.text,
                      to: _rewriteToCtrl.text,
                    ),
                  ),
                );
              } else {
                app.logger.i('Unsupported action');
              }
            }
          },
          color: app.colors.primary.purple.brighten(0.15),
          title: widget.action == RoutesFormAction.edit
              ? app.intl.actions.edit
              : app.intl.actions.create,
        ),
      ),
    );
  }

  Widget _buildSingleRouteTile({required RouteFormModel model}) {
    return SelectionArea(
      child: Container(
        decoration: BoxDecoration(
          color: app.colors.primary.background2,
          borderRadius: app.dimensions.border.borderRadius.m,
          border: Border.all(color: app.colors.neutral.grey5),
        ),
        child: Padding(
          padding: EdgeInsets.all(app.dimensions.padding.s),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...[
                Text(model.name, style: app.textTheme.titleMedium),
                app.dimensions.padding.s.gap(),
                Divider(
                  height: 0.5,
                  color: app.colors.neutral.grey5.withValues(alpha: 0.5),
                ),
              ],
              app.dimensions.padding.s.gap(),
              Text(
                app.intl.routes.requestTo,
                style: app.textTheme.bodySmall?.copyWith(
                  color: app.colors.neutral.grey4,
                ),
              ),
              Text(model.enterPoint, style: app.textTheme.titleSmall),
              app.dimensions.padding.s.gap(),
              Text(
                app.intl.routes.redirectedTo,
                style: app.textTheme.bodySmall?.copyWith(
                  color: app.colors.neutral.grey4,
                ),
              ),
              Text(model.redirectTo, style: app.textTheme.titleSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class RoutesFormValidator {
  RoutesFormRequiredFieldValidator required =
      RoutesFormRequiredFieldValidator();
  RoutesFormUriValidator uri = RoutesFormUriValidator();
}

class RoutesFormRequiredFieldValidator {
  int get maxLong => 255;

  int get maxShort => 155;

  ///rewrite path is optional, but if one side is filled the other one is required
  String? pairedValidator(String? value, String other) {
    if ((value == null || value.isEmpty) && other.isNotEmpty) {
      return app.intl.validations.requiredField;
    }
    return null;
  }

  String? validator(String? value) {
    if (value == null || value.isEmpty) {
      return app.intl.validations.requiredField;
    }
    return null;
  }
}

class RoutesFormUriValidator {
  int get max => 255;

  String? validator(String? value) {
    if (value == null || value.isEmpty) {
      return app.intl.validations.requiredField;
    }
    final uri = Uri.tryParse(value);
    if (!(uri != null && (uri.hasScheme && uri.hasAuthority))) {
      return app.intl.validations.validUriField;
    }
    return null;
  }
}
