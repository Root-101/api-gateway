import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

///`100,000+` when the gateway capped the count; follows Intl.defaultLocale (1,555 or 1.555)
String logsCount(int total, {required bool capped}) =>
    '${NumberFormat.decimalPattern().format(total)}${capped ? '+' : ''}';

///Logs' title with how many requests were captured, and refresh and export
class LogsHeader extends StatelessWidget {
  final LogsCubit cubit;
  final VoidCallback onRefresh;

  const LogsHeader({required this.cubit, required this.onRefresh, super.key});

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 16,
      runSpacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              intl.logs.logs,
              style: TextStyle(
                fontSize: 26,
                height: 32 / 26,
                fontWeight: FontWeight.w500,
                color: c.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              intl.logs.captured(
                count: logsCount(
                  cubit.capturedTotal,
                  capped: cubit.capturedCapped,
                ),
              ),
              style: TextStyle(fontSize: 13, color: c.textSecondary),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton(
              label: intl.actions.refresh,
              icon: app.assets.icons.actions.reload,
              kind: AppButtonKind.outlined,
              onPressed: onRefresh,
            ),
            const SizedBox(width: 8),
            AppButton(
              label: intl.logs.export,
              icon: app.assets.icons.actions.download,
              kind: AppButtonKind.outlined,
              onPressed: cubit.export,
            ),
          ],
        ),
      ],
    );
  }
}
