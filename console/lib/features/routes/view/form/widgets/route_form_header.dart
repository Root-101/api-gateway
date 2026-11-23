import 'package:console/app_exporter.dart';
import 'package:console/features/routes/view/form/widgets/route_form_duplicate_chip.dart';
import 'package:material_ui/material_ui.dart';

///the form's title (create, edit or duplicate, with the copied route's chip), subtitle and close
class RouteFormHeader extends StatelessWidget {
  final RoutesFormAction action;

  ///the route being edited or duplicated
  final RouteModel? route;

  const RouteFormHeader({required this.action, this.route, super.key});

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final form = intl.form;
    final isEdit = action == RoutesFormAction.edit;
    final isDuplicate = action == RoutesFormAction.duplicate;
    final route = this.route;
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
                      isEdit
                          ? intl.routes.editRoute
                          : isDuplicate
                          ? intl.routes.duplicateRoute
                          : intl.routes.createRoute,
                      style: TextStyle(
                        fontSize: 20,
                        height: 28 / 20,
                        fontWeight: FontWeight.w500,
                        color: c.text,
                      ),
                    ),
                    if (isDuplicate && route != null) ...[
                      const SizedBox(width: 10),
                      Flexible(child: RouteFormDuplicateChip(name: route.name)),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isEdit
                      ? form.editSubtitle
                      : isDuplicate
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
}
