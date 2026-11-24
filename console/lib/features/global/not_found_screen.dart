import 'package:console/app_exporter.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class NotFoundScreenNavigator {
  String get path => '/not-found';

  /// The 404 of [requested] (an url the router doesn't know)
  String location(String requested) =>
      Uri(path: path, queryParameters: {'path': requested}).toString();

  List<RouteBase> routes() => [
    GoRoute(
      path: path,
      builder: (context, state) =>
          NotFoundScreen(requested: state.uri.queryParameters['path'] ?? ''),
    ),
  ];
}

class NotFoundScreen extends StatelessWidget {
  static final NotFoundScreenNavigator navigator = NotFoundScreenNavigator();

  final String requested;

  const NotFoundScreen({required this.requested, super.key});

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppLogo(width: 64, color: c.selected),
              const SizedBox(height: 14),
              Text(
                '404',
                style: monoStyle(
                  size: 72,
                  height: 80 / 72,
                  weight: FontWeight.w500,
                  color: c.selected,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                intl.notFound.title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: c.text,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                intl.notFound.description,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: c.textSecondary),
              ),
              if (requested.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: c.field,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: c.brandBorder),
                  ),
                  child: Text(
                    requested,
                    style: monoStyle(size: 12, color: c.textTertiary),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  AppButton(
                    label: intl.notFound.goToMap,
                    height: 42,
                    onPressed: () => GatewayMapScreen.navigator.go(),
                  ),
                  AppButton(
                    label: intl.notFound.openLogs,
                    kind: AppButtonKind.outlined,
                    height: 42,
                    onPressed: () => LogsScreen.navigator.go(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
