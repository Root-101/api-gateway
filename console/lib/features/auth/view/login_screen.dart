import 'package:console/app_exporter.dart';
import 'package:console/features/language/view/language_widget.dart';
import 'package:flutter/material.dart';
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
  late final AuthCubit cubit;

  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _rememberMe = false;
  bool _showPassword = false;
  bool _signingIn = false;
  bool _wrongCredentials = false;
  String? _usernameError;
  String? _passwordError;

  //tells "gateway down" apart from "wrong credentials" before the user even tries
  late final Future<bool> _gatewayUp;

  @override
  void initState() {
    super.initState();
    cubit = app.di.find<AuthCubit>();
    _gatewayUp = cubit.isGatewayUp();
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _clearErrors() {
    if (_wrongCredentials || _usernameError != null || _passwordError != null) {
      setState(() {
        _wrongCredentials = false;
        _usernameError = null;
        _passwordError = null;
      });
    }
  }

  void _login() {
    if (_signingIn) return;
    final required = context.intl.validations.requiredField;
    setState(() {
      _usernameError = _username.text.isEmpty ? required : null;
      _passwordError = _password.text.isEmpty ? required : null;
    });
    if (_usernameError != null || _passwordError != null) return;
    cubit.login(
      username: _username.text,
      password: _password.text,
      rememberMe: _rememberMe,
    );
  }

  void _onState(BuildContext context, AuthState state) {
    if (state is AuthLoginInProgressState) {
      setState(() => _signingIn = true);
    } else if (state is AuthLoginOkState) {
      //no going back to login
      RoutesScreen.navigator.neglectGo();
    } else if (state is AuthLoginErrorState) {
      setState(() {
        _signingIn = false;
        _wrongCredentials = state.exception.type == GlobalExceptionType.auth;
      });
      app.snack.showError(message: state.exception.message);
      app.logger.e(state.exception.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) => current is AuthLoginState,
      listener: _onState,
      child: Scaffold(
        backgroundColor: app.colors.gridBg,
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 940) {
              return ListView(
                children: [
                  GridBackground(child: _buildIdentity(context)),
                  _buildFormColumn(context),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                //like the design's CSS flex (1.25 1 520px | 1 1 420px): the bases first, the rest 1.25:1
                SizedBox(
                  width: 520 + (constraints.maxWidth - 940) * 1.25 / 2.25,
                  child: GridBackground(child: _buildIdentity(context)),
                ),
                Expanded(flex: 100, child: _buildFormColumn(context)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildIdentity(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    return Padding(
      //8% of the window, not of the column: the design's CSS padding percentage refers to the page width
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.sizeOf(context).width * 0.08,
        vertical: 64,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const AppLogo(width: 150),
                const SizedBox(width: 36),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: -20,
                      top: -90,
                      child: IgnorePointer(
                        child: Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                c.glow.withValues(alpha: 0.34),
                                c.glow.withValues(alpha: 0),
                              ],
                              stops: const [0, 0.65],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppWordmark(size: 72, letterSpacing: -3),
                        SizedBox(height: 14),
                        Padding(
                          padding: EdgeInsets.only(left: 2),
                          child: AppTagline(size: 30, letterSpacing: -0.6),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _FeatureChip(intl.login.featureRedirections, dot: c.lilac),
                _FeatureChip(intl.login.featureLogs, dot: c.lilacMuted),
                _FeatureChip(intl.login.featureBackup, dot: c.lilacMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormColumn(BuildContext context) {
    final c = app.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.gridBg,
        border: Border(left: BorderSide(color: c.brandBorder)),
      ),
      child: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 72, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCard(context),
                  const SizedBox(height: 20),
                  FutureBuilder<String?>(
                    future: appVersion,
                    builder: (context, snapshot) => Text(
                      snapshot.data == null
                          ? 'api-gateway'
                          : 'api-gateway v${snapshot.data}',
                      style: monoStyle(size: 12, color: c.textTertiary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(right: 24, top: 24, child: LanguageWidget()),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final failed = _wrongCredentials;
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: c.field,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.raised),
      ),
      child: AutofillGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  intl.login.login,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: c.text,
                  ),
                ),
                FutureBuilder<bool>(
                  future: _gatewayUp,
                  builder: (context, snapshot) => snapshot.hasData
                      ? _GatewayPill(up: snapshot.data!)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              intl.login.subtitle,
              style: TextStyle(fontSize: 13, color: c.textTertiary),
            ),
            const SizedBox(height: 24),
            AppField(
              label: intl.login.usernameLabel,
              controller: _username,
              autofocus: true,
              maxLength: 64,
              hasError: failed,
              errorText: _usernameError,
              autofillHint: AutofillHints.username,
              onChanged: (_) => _clearErrors(),
              onSubmitted: (_) => _login(),
            ),
            const SizedBox(height: 16),
            AppField(
              label: intl.login.passwordLabel,
              controller: _password,
              obscure: !_showPassword,
              maxLength: 64,
              hasError: failed,
              errorText: _passwordError,
              autofillHint: AutofillHints.password,
              onChanged: (_) => _clearErrors(),
              onSubmitted: (_) => _login(),
              suffix: AppIconButton(
                icon: _showPassword
                    ? app.assets.icons.general.eyeOff
                    : app.assets.icons.general.eye,
                tooltip: _showPassword
                    ? intl.login.hidePassword
                    : intl.login.showPassword,
                size: 40,
                iconSize: 20,
                radius: 10,
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
            if (failed) ...[
              const SizedBox(height: 10),
              _buildWrongCredentials(context),
            ],
            const SizedBox(height: 16),
            MergeSemantics(
              child: InkWell(
                onTap: () => setState(() => _rememberMe = !_rememberMe),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 2,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox.square(
                        dimension: 20,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (value) =>
                              setState(() => _rememberMe = value ?? false),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              intl.login.rememberMe,
                              style: TextStyle(
                                fontSize: 14,
                                height: 20 / 14,
                                color: c.text,
                              ),
                            ),
                            if (_rememberMe)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  intl.login.rememberMeWarning,
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 16 / 12,
                                    color: c.textSecondary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: _signingIn ? intl.login.signingIn : intl.login.login,
              height: 48,
              fontSize: 15,
              onPressed: _signingIn ? null : _login,
            ),
            const SizedBox(height: 16),
            const CredentialsHint(),
          ],
        ),
      ),
    );
  }

  Widget _buildWrongCredentials(BuildContext context) {
    final c = app.colors;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: c.danger.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.danger.withValues(alpha: 0.45)),
        ),
        child: Row(
          children: [
            app.assets.icons.general.alertCircle.build(
              size: 16,
              color: c.dangerText,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.intl.login.wrongCredentials,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: c.dangerText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;
  final Color dot;

  const _FeatureChip(this.label, {required this.dot});

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: c.field,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.brandBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: dot,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: c.lilacText,
            ),
          ),
        ],
      ),
    );
  }
}

class _GatewayPill extends StatelessWidget {
  final bool up;

  const _GatewayPill({required this.up});

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final dot = up ? c.successDot : c.danger;
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: dot.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            up
                ? context.intl.login.gatewayReachable
                : context.intl.login.gatewayUnreachable,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: up ? c.success : c.dangerText,
            ),
          ),
        ],
      ),
    );
  }
}
