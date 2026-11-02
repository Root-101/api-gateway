import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RoutesFormScreenNavigator {
  void create() {
    DialogTemplate.open(
      title: app.intl.create,
      child: BlocProvider(
        create:
            (BuildContext context) => RoutesFormCubit(
              auth: app.di.find(),
              repo: app.di.find(),
              action: RoutesFormAction.create,
            ),
        lazy: false,
        child: const RoutesFormScreen(),
      ),
    );
  }

  void edit({required RouteModel model}) {
    DialogTemplate.open(
      title: app.intl.edit,
      child: BlocProvider(
        create:
            (BuildContext context) => RoutesFormCubit(
              auth: app.di.find(),
              repo: app.di.find(),
              action: RoutesFormAction.edit,
              //in a future we will support the edit from url, this are the bases
              paramRouteId: model.id,
              paramRouteModel: model,
            ),
        lazy: false,
        child: const RoutesFormScreen(),
      ),
    );
  }

  void duplicate({required RouteModel model}) {
    DialogTemplate.open(
      title: app.intl.duplicate,
      child: BlocProvider(
        create:
            (BuildContext context) => RoutesFormCubit(
              auth: app.di.find(),
              repo: app.di.find(),
              action: RoutesFormAction.duplicate,
              //in a future we will support the edit from url, this are the bases
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
            failValidations:
                (state is RoutesFormValidationErrorState)
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
            buttonText: app.intl.back,
            onPressed: () {
              app.navigator.pop();
            },
          );
        } else {
          return ErrorPage(
            buttonText: app.intl.back,
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

  //local copy: clearing it must not mutate the cubit state's map
  Map<String, String> _apiErrors = {};

  @override
  void initState() {
    super.initState();
    _apiErrors = {...?widget.failValidations};

    if (widget.route != null) {
      _nameCtrl.text = widget.route!.name;
      _uriCtrl.text = widget.route!.uri;
      _pathCtrl.text = widget.route!.path;
      _rewriteFromCtrl.text = widget.route!.rewritePath?.replaceFrom ?? '';
      _rewriteToCtrl.text = widget.route!.rewritePath?.replaceTo ?? '';
    }
  }

  @override
  void didUpdateWidget(covariant RoutesFormWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.failValidations != oldWidget.failValidations) {
      _apiErrors = {...?widget.failValidations};
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _uriCtrl.dispose();
    _pathCtrl.dispose();
    _rewriteFromCtrl.dispose();
    _rewriteToCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String? nameErrorText = _apiErrors['name'];
    String? uriErrorText = _apiErrors['uri'];
    String? pathErrorText = _apiErrors['path'];
    String? rewriteFromErrorText =
        _apiErrors['rewrite_path.replace_from'];
    String? rewriteToErrorText =
        _apiErrors['rewrite_path.replace_to'];

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
                  label: app.intl.nameLabel,
                  hint: app.intl.nameHint,
                  maxLength: validator.required.maxLong,
                  validator: validator.required.validator,
                ),
                app.dimensions.padding.m.gap(),

                ///-------------- PATH --------------\\\
                AppTextInput.textField(
                  controller: _pathCtrl,
                  errorText: pathErrorText,
                  label: app.intl.pathLabel,
                  hint: app.intl.pathHint,
                  maxLength: validator.required.maxLong,
                  validator: validator.required.validator,
                ),
                app.dimensions.padding.m.gap(),

                ///-------------- URI --------------\\\
                AppTextInput.textField(
                  controller: _uriCtrl,
                  errorText: uriErrorText,
                  label: app.intl.uriLabel,
                  hint: app.intl.uriHint,
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
                        label: app.intl.rewritePathFromLabel,
                        hint: app.intl.rewritePathFromHint,
                        maxLength: validator.required.maxShort,
                        validator: (value) =>
                            validator.required.pairedValidator(
                              value,
                              _rewriteToCtrl.text,
                            ),
                      ),
                    ),
                    app.dimensions.padding.m.gap(),

                    ///-------------- TO--------------\\\
                    Expanded(
                      child: AppTextInput.textField(
                        controller: _rewriteToCtrl,
                        errorText: rewriteToErrorText,
                        label: app.intl.rewritePathToLabel,
                        hint: app.intl.rewritePathToHint,
                        maxLength: validator.required.maxShort,
                        validator: (value) =>
                            validator.required.pairedValidator(
                              value,
                              _rewriteFromCtrl.text,
                            ),
                      ),
                    ),
                  ],
                ),
                app.dimensions.padding.xxl.gap(),

                ///-------------- PREVIEW --------------\\\
                Text(app.intl.preview, style: app.textTheme.labelMedium),
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
                        description: '',
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
                    name: _nameCtrl.text,
                    uri: _uriCtrl.text,
                    path: _pathCtrl.text,
                    //no description field in ui yet: keep the existing one so edit/duplicate don't wipe it
                    description: widget.route?.description ?? '',
                    rewritePath: RewritePathModel.fromFields(
                      from: _rewriteFromCtrl.text,
                      to: _rewriteToCtrl.text,
                    ),
                  ),
                );
              } else if (widget.action == RoutesFormAction.edit) {
                widget.onEdit(
                  RouteFormModel(
                    name: _nameCtrl.text,
                    uri: _uriCtrl.text,
                    path: _pathCtrl.text,
                    description: widget.route?.description ?? '',
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
          title:
              widget.action == RoutesFormAction.edit
                  ? app.intl.edit
                  : app.intl.create,
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
                app.intl.requestTo,
                style: app.textTheme.bodySmall?.copyWith(
                  color: app.colors.neutral.grey4,
                ),
              ),
              Text(model.enterPoint, style: app.textTheme.titleSmall),
              app.dimensions.padding.s.gap(),
              Text(
                app.intl.redirectedTo,
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
      return app.intl.requiredField;
    }
    return null;
  }

  String? validator(String? value) {
    if (value == null || value.isEmpty) {
      return app.intl.requiredField;
    }
    return null;
  }
}

class RoutesFormUriValidator {
  int get max => 255;

  String? validator(String? value) {
    if (value == null || value.isEmpty) {
      return app.intl.requiredField;
    }
    final uri = Uri.tryParse(value);
    if (!(uri != null && (uri.hasScheme && uri.hasAuthority))) {
      return app.intl.validUriField;
    }
    return null;
  }
}
