import 'package:api_gateway_front/app_exporter.dart';
import 'package:api_gateway_front/features/language/view/language_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LoginScreenNavigator {
  String get name => 'login';

  String get path => '/login';

  Widget builder(BuildContext context, GoRouterState state) {
    return const LoginScreen();
  }

  void neglectGo() {
    Router.neglect(app.context, () {
      app.navigator.go(name);
    });
  }
}

class LoginScreen extends StatefulWidget {
  static final LoginScreenNavigator navigator = LoginScreenNavigator();

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FocusNode _focusNode = FocusNode();

  final LoginValidator validator = LoginValidator();

  late final AuthCubit cubit;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();

    cubit = app.di.find<AuthCubit>();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) => current is AuthLoginState,
      listener: (context, state) {
        if (state is AuthLoginInProgressState) {
          FocusScope.of(context).unfocus();
          app.loading.show();
        } else if (state is AuthLoginOkState) {
          app.loading.hide();

          //no going back to login
          RoutesScreen.navigator.neglectGo();
        } else if (state is AuthLoginErrorState) {
          app.loading.hide();
          app.snack.showError(
            message: state.exception.message,
            context: context,
          );
          app.logger.e(state.exception.toString());
        }
      },
      child: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.enter) {
            _login();
          }
        },
        child: Scaffold(
          body: Stack(
            children: [
              Center(
                child: Container(
                  width: 550,
                  decoration: BoxDecoration(
                    color: app.colors.primary.backgroundForm,
                    borderRadius: app.dimensions.border.borderRadius.m,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(app.dimensions.padding.l),
                    child: Form(
                      key: _formKey,
                      child: Padding(
                        padding: EdgeInsets.all(app.dimensions.padding.l),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              app.intl.login,
                              style: app.textTheme.headlineSmall,
                            ),
                            app.dimensions.padding.xxl.gap(),
                            AppTextInput.textField(
                              controller: usernameController,
                              label: '${app.intl.usernameLabel} *',
                              hint: app.intl.usernameHint,
                              maxLength: validator.username.max,
                              validator: validator.username.validator,
                            ),
                            app.dimensions.padding.l.gap(),
                            AppTextInput.passwordField(
                              controller: passwordController,
                              label: '${app.intl.passwordLabel} *',
                              hint: app.intl.passwordHint,
                              validator: validator.password.validator,
                            ),
                            (1.5 * app.dimensions.padding.xxl).gap(),
                            PrimaryButton.primary(
                              onPressed: _login,
                              title: app.intl.login,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Positioned(left: 50, bottom: 50, child: LanguageWidget()),
            ],
          ),
        ),
      ),
    );
  }

  Future _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    } else {
      await cubit.login(
        username: usernameController.text,
        password: passwordController.text,
      );
    }
  }
}

class LoginValidator {
  LoginNameValidator username = LoginNameValidator();
  LoginPassValidator password = LoginPassValidator();
}

class LoginNameValidator {
  int get max => 64;

  String? validator(String? value) {
    if (value == null || value.isEmpty) {
      return app.intl.requiredField;
    }
    return null;
  }
}

class LoginPassValidator {
  int get max => 64;

  String? validator(String? value) {
    if (value == null || value.isEmpty) {
      return app.intl.requiredField;
    }
    return null;
  }
}
