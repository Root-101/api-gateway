import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

class DeleteRouteDialogNavigator {
  /// `true` when the user confirms
  Future<bool?> open({required RouteModel route}) =>
      app.dialog.open<bool>(dialog: DeleteRouteDialog(route: route));
}

class DeleteRouteDialog extends StatelessWidget {
  static final DeleteRouteDialogNavigator navigator =
      DeleteRouteDialogNavigator();

  final RouteModel route;

  const DeleteRouteDialog({required this.route, super.key});

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    return DialogFrame(
      width: 420,
      radius: 28,
      color: c.toast,
      borderColor: c.outlineCard,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xff8c1d18),
                shape: BoxShape.circle,
              ),
              child: app.assets.icons.actions.delete.build(
                size: 26,
                color: const Color(0xfff9dedc),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              intl.delete.title,
              style: TextStyle(
                fontSize: 22,
                height: 28 / 22,
                fontWeight: FontWeight.w500,
                color: c.text,
              ),
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                text: '${intl.delete.descriptionStart} ',
                children: [
                  TextSpan(
                    text: route.path,
                    style: monoStyle(size: 14, color: c.text),
                  ),
                  TextSpan(text: ' ${intl.delete.descriptionEnd}'),
                ],
              ),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 20 / 14, color: c.label),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.outlineCard),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: c.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  RouteUrlBlock(
                    caption: intl.routes.from,
                    url: route.enterPoint,
                    fontSize: 12,
                    urlColor: c.label,
                  ),
                  const SizedBox(height: 6),
                  RouteUrlBlock(
                    caption: intl.routes.to,
                    url: route.redirectTo,
                    accent: true,
                    fontSize: 12,
                    urlColor: c.label,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: intl.actions.cancel,
                    kind: AppButtonKind.outlined,
                    height: 46,
                    radius: 23,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label: intl.delete.confirm,
                    icon: app.assets.icons.actions.delete,
                    kind: AppButtonKind.softDanger,
                    height: 46,
                    radius: 23,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
