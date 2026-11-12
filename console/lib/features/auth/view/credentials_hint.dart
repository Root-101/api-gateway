import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';

///where the admin credentials come from, under the login and the session expired dialog
class CredentialsHint extends StatelessWidget {
  const CredentialsHint({super.key});

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    return Text.rich(
      TextSpan(
        text: '${intl.login.credentialsHintStart} ',
        children: [
          TextSpan(
            text: 'ADMIN_USERNAME',
            style: monoStyle(size: 12, color: c.label),
          ),
          TextSpan(text: ' ${intl.login.credentialsHintAnd} '),
          TextSpan(
            text: 'ADMIN_PASSWORD',
            style: monoStyle(size: 12, color: c.label),
          ),
          TextSpan(text: ' ${intl.login.credentialsHintEnd}'),
        ],
      ),
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 12, height: 18 / 12, color: c.textTertiary),
    );
  }
}
