import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

///the gateway is unreachable: when the last data came, and retry
class OfflineBanner extends StatelessWidget {
  final GatewayStatus status;

  const OfflineBanner(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final time = status.lastLoadedAt == null
        ? '--:--'
        : app.dateFormatter.clock.format(status.lastLoadedAt!);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: c.offline.withValues(alpha: 0.10),
          border: Border(
            bottom: BorderSide(color: c.offline.withValues(alpha: 0.4)),
          ),
        ),
        child: Row(
          children: [
            app.assets.icons.general.wifiOff.build(size: 18, color: c.offline),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${intl.offline.title}  ',
                      style: TextStyle(
                        color: c.offline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text:
                          '${intl.offline.detail(time: time)} '
                          '${status.retrying ? intl.offline.retrying : intl.offline.retryAuto}',
                    ),
                  ],
                ),
                style: TextStyle(fontSize: 13, height: 18 / 13, color: c.text),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: status.retrying
                  ? null
                  : app.di.find<GatewayStatusCubit>().retry,
              style: OutlinedButton.styleFrom(
                foregroundColor: c.offline,
                disabledForegroundColor: c.offline,
                side: BorderSide(color: c.offline.withValues(alpha: 0.6)),
                minimumSize: const Size(0, 34),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (status.retrying) ...[
                    SmallSpinner(color: c.offline),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    status.retrying
                        ? intl.offline.retryingButton
                        : intl.offline.retryNow,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
