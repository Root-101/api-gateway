import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

///asks for the password again over the current screen; can only be left by signing in or going to login
class SessionExpiredDialog extends StatefulWidget {
  static void show() {
    app.dialog.open(
      dialog: const SessionExpiredDialog(),
      barrierDismissible: false,
      barrierColor: const Color(0xb80a090f),
    );
  }

  const SessionExpiredDialog({super.key});

  @override
  State<SessionExpiredDialog> createState() => _SessionExpiredDialogState();
}

class _SessionExpiredDialogState extends State<SessionExpiredDialog> {
  late final AuthCubit auth = app.di.find<AuthCubit>();
  late final TextEditingController _user = TextEditingController(
    text: auth.username ?? '',
  );
  final TextEditingController _pass = TextEditingController();
  bool _failed = false;
  bool _busy = false;

  bool get _knowsUser => auth.username != null;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _submit() {
    if (_busy || _user.text.isEmpty || _pass.text.isEmpty) return;
    auth.reauthenticate(username: _user.text, password: _pass.text);
  }

  void _onState(BuildContext context, AuthState state) {
    if (state is AuthReauthInProgressState) {
      setState(() {
        _busy = true;
        _failed = false;
      });
    } else if (state is AuthReauthOkState) {
      Navigator.of(context).pop();
      app.di.find<RoutesCubit>().search(emitLoading: false);
      final logs = app.di.find<LogsCubit>();
      if (logs.state is! LogsInitialState) logs.search();
    } else if (state is AuthReauthErrorState) {
      setState(() {
        _busy = false;
        _failed = state.exception.type == GlobalExceptionType.auth;
      });
      if (!_failed) app.snack.showError(message: state.exception.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    return PopScope(
      canPop: false,
      child: BlocListener<AuthCubit, AuthState>(
        listener: _onState,
        child: DialogFrame(
          width: 420,
          radius: 20,
          color: c.field,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.lilac.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: app.assets.icons.general.lock.build(
                      size: 24,
                      color: c.lilac,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  intl.session.title,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                    color: c.text,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  intl.session.description,
                  style: TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                AppField(
                  label: intl.login.usernameLabel,
                  controller: _user,
                  mono: true,
                  readOnly: _knowsUser,
                  autofocus: !_knowsUser,
                  fill: c.surface,
                  autofillHint: AutofillHints.username,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 16),
                AppField(
                  label: intl.login.passwordLabel,
                  controller: _pass,
                  obscure: true,
                  autofocus: _knowsUser,
                  hint: intl.session.passwordHint,
                  autofillHint: AutofillHints.password,
                  errorText: _failed ? intl.session.wrongPassword : null,
                  onChanged: (_) {
                    if (_failed) setState(() => _failed = false);
                  },
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: intl.session.signIn,
                  height: 48,
                  fontSize: 15,
                  onPressed: _busy ? null : _submit,
                ),
                const SizedBox(height: 16),
                Center(
                  child: AppButton(
                    label: intl.session.goToLogin,
                    kind: AppButtonKind.text,
                    height: 36,
                    fontSize: 13,
                    onPressed: () {
                      Navigator.of(context).pop();
                      auth.logout();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
