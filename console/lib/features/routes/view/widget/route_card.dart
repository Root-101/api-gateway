import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

class RouteCard extends StatefulWidget {
  final RouteModel route;
  final bool gatewayOn;
  final VoidCallback onDelete;

  const RouteCard({
    required this.route,
    required this.gatewayOn,
    required this.onDelete,
    super.key,
  });

  @override
  State<RouteCard> createState() => _RouteCardState();
}

class _RouteCardState extends State<RouteCard> {
  bool _hovered = false;

  Future<void> _copy(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    app.toast.success(app.intl.actions.copiedToClipboard);
  }

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final route = widget.route;
    final maintenance = route.inMaintenance;
    final Color border = maintenance
        ? c.maintenance.withValues(alpha: _hovered ? 0.85 : 0.55)
        : (_hovered ? c.textTertiary : c.outlineCard);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: motion(context, const Duration(milliseconds: 150)),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              route.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 19,
                                height: 26 / 19,
                                fontWeight: FontWeight.w500,
                                color: c.text,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusTag(
                            RouteStatus.of(route, gatewayOn: widget.gatewayOn),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        route.description.isEmpty
                            ? intl.routes.noDescription
                            : route.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 18 / 13,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AppIconButton(
                  icon: app.assets.icons.actions.edit,
                  tooltip: intl.routes.edit,
                  onPressed: () =>
                      RoutesFormScreen.navigator.edit(model: route),
                ),
                AppIconButton(
                  icon: app.assets.icons.actions.duplicate,
                  tooltip: intl.routes.duplicate,
                  onPressed: () =>
                      RoutesFormScreen.navigator.duplicate(model: route),
                ),
                AppIconButton(
                  icon: app.assets.icons.actions.delete,
                  tooltip: intl.routes.delete,
                  hoverColor: c.softRed,
                  onPressed: widget.onDelete,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 8, 6, 12),
                decoration: BoxDecoration(
                  color: c.night,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.outlineSoft),
                ),
                child: SelectionArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _urlRow(
                        intl.routes.from,
                        route.enterPoint,
                        intl.routes.copyFrom,
                        false,
                      ),
                      Container(
                        height: 1,
                        margin: const EdgeInsets.fromLTRB(0, 10, 6, 2),
                        color: c.outlineSoft,
                      ),
                      _urlRow(
                        intl.routes.to,
                        route.redirectTo,
                        intl.routes.copyTo,
                        true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (maintenance) ...[
              const SizedBox(height: 12),
              RouteCardMaintenance(route.maintenance!),
            ],
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(vertical: 12),
              color: c.outlineSoft,
            ),
            RouteCardAddons(route: route),
          ],
        ),
      ),
    );
  }

  Widget _urlRow(String caption, String url, String copyLabel, bool accent) {
    final c = app.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CaptionText(caption, color: accent ? c.lilac : c.textTertiary),
            AppIconButton(
              icon: app.assets.icons.actions.duplicate,
              tooltip: copyLabel,
              size: 32,
              iconSize: 15,
              radius: 8,
              color: c.textTertiary,
              onPressed: () => _copy(url),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Text(
            url,
            style: monoStyle(size: 13, height: 20 / 13, color: c.text),
          ),
        ),
      ],
    );
  }
}
