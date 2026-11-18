import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';

///an add-on block's top row: icon, name with its (i), then [status] and, while viewing,
///[extraActions], Edit and Remove
class AddonHeader extends StatelessWidget {
  final SvgAsset icon;
  final Color iconColor;
  final String title;
  final Widget info;

  ///always shown after the name (e.g. the rate, `60/min`)
  final List<Widget> status;

  ///false while editing or confirming: no buttons
  final bool showActions;

  ///before Edit while viewing (e.g. Run now)
  final List<Widget> extraActions;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const AddonHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.info,
    required this.showActions,
    required this.onEdit,
    required this.onRemove,
    this.status = const [],
    this.extraActions = const [],
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    return Row(
      children: [
        icon.build(size: 17, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: c.text,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              info,
            ],
          ),
        ),
        ...status,
        if (showActions) ...[
          ...extraActions,
          AppIconButton(
            icon: app.assets.icons.actions.edit,
            tooltip: intl.panel.edit,
            size: 34,
            iconSize: 16,
            onPressed: onEdit,
          ),
          AppIconButton(
            icon: app.assets.icons.actions.delete,
            tooltip: intl.panel.remove,
            size: 34,
            iconSize: 16,
            hoverColor: c.softRed,
            onPressed: onRemove,
          ),
        ],
      ],
    );
  }
}

///"Remove …?" inside the block itself: its title, what is lost, outlined Cancel and a red Remove (34 px, as in the canvas)
class AddonRemoveConfirm extends StatelessWidget {
  final String title;
  final String body;

  ///Remove is off while the add-on is being saved
  final bool busy;
  final VoidCallback onCancel;
  final VoidCallback onRemove;

  const AddonRemoveConfirm({
    required this.title,
    required this.body,
    required this.busy,
    required this.onCancel,
    required this.onRemove,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: c.text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          style: TextStyle(fontSize: 13, height: 18 / 13, color: c.label),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AppButton(
              label: intl.actions.cancel,
              kind: AppButtonKind.outlined,
              height: 34,
              radius: 10,
              fontSize: 13,
              onPressed: onCancel,
            ),
            const SizedBox(width: 8),
            AppButton(
              label: intl.panel.remove,
              kind: AppButtonKind.danger,
              height: 34,
              radius: 10,
              fontSize: 13,
              onPressed: busy ? null : onRemove,
            ),
          ],
        ),
      ],
    );
  }
}
