import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';

///the whole gateway answers 503: edit or turn it off from any screen
class MaintenanceBanner extends StatelessWidget {
  final MaintenanceModel maintenance;

  const MaintenanceBanner(this.maintenance, {super.key});

  //the countdown moves on by itself
  @override
  Widget build(BuildContext context) => Ticking(builder: _build);

  Widget _build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final retry = maintenance.retryAfter?.toLocal();
    final seconds = maintenance.retrySeconds;
    final detail = retry == null
        ? intl.maintenance.bannerDetail
        : seconds == 0
        ? intl.maintenance.bannerPassed
        : intl.maintenance.bannerUntil(
            date: app.dateFormatter.dayTime.format(retry),
            left: durationText(seconds),
          );
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: c.maintenance.withValues(alpha: 0.10),
          border: Border(
            bottom: BorderSide(color: c.maintenance.withValues(alpha: 0.45)),
          ),
        ),
        child: Row(
          children: [
            app.assets.icons.general.wrench.build(
              size: 18,
              color: c.maintenance,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${intl.maintenance.bannerTitle}  ',
                      style: TextStyle(
                        color: c.maintenance,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(text: detail),
                  ],
                ),
                style: TextStyle(fontSize: 13, height: 18 / 13, color: c.text),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: GatewayMapScreen.navigator.openGateway,
              style: OutlinedButton.styleFrom(
                foregroundColor: c.maintenance,
                side: BorderSide(color: c.maintenance.withValues(alpha: 0.6)),
                minimumSize: const Size(0, 34),
                //web's compact density would make it shorter than Turn off
                visualDensity: VisualDensity.standard,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(intl.maintenance.edit),
            ),
            const SizedBox(width: 8),
            AppButton(
              label: intl.maintenance.turnOff,
              kind: AppButtonKind.maintenance,
              height: 34,
              radius: 10,
              fontSize: 13,
              //keeps the message and time for next time
              onPressed: () =>
                  app.di.find<MaintenanceCubit>().setEnabled(enabled: false),
            ),
          ],
        ),
      ),
    );
  }
}
