import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';

///the (i) beside an add-on's name: hover, focus or a tap shows what it is for and how it works
class InfoTip extends StatelessWidget {
  ///the add-on's name, for screen readers
  final String name;
  final String title;
  final String body;
  final String note;

  const InfoTip({
    required this.name,
    required this.title,
    required this.body,
    required this.note,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    return Tooltip(
      richMessage: TextSpan(
        children: [
          TextSpan(
            text: '$title\n',
            style: TextStyle(
              fontSize: 13,
              height: 1.7,
              fontWeight: FontWeight.w600,
              color: c.text,
            ),
          ),
          TextSpan(
            text: '$body\n\n$note',
            style: TextStyle(fontSize: 12, height: 1.5, color: c.label),
          ),
        ],
      ),
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.popupLilac,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.outlineCard),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 40,
            offset: Offset(0, 16),
          ),
        ],
      ),
      verticalOffset: 14,
      waitDuration: const Duration(milliseconds: 100),
      showDuration: const Duration(seconds: 10),
      //a tap also opens it (touch); inside an add tile it doesn't add the add-on
      triggerMode: TooltipTriggerMode.tap,
      child: Semantics(
        button: true,
        label: context.intl.info.what(name: name),
        child: MouseRegion(
          cursor: SystemMouseCursors.help,
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: app.assets.icons.general.info.build(
              size: 14,
              color: c.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}

Widget healthInfo(BuildContext context) {
  final intl = context.intl;
  return InfoTip(
    name: intl.health.title,
    title: intl.info.healthTitle,
    body: intl.info.healthBody,
    note: intl.info.healthNote,
  );
}

Widget maintenanceInfo(BuildContext context, {required bool gateway}) {
  final intl = context.intl;
  return InfoTip(
    name: intl.panel.maintenance,
    title: intl.info.maintenanceTitle,
    body: gateway
        ? intl.info.maintenanceBodyGateway
        : intl.info.maintenanceBody,
    note: intl.info.maintenanceNote,
  );
}

Widget rateInfo(BuildContext context, {required bool gateway}) {
  final intl = context.intl;
  return InfoTip(
    name: intl.rate.title,
    title: intl.info.rateTitle,
    body: gateway ? intl.info.rateBodyGateway : intl.info.rateBody,
    note: intl.info.rateNote,
  );
}
