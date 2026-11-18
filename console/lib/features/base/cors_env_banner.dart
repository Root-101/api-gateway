import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';

///`CORS_ALLOWED_ORIGINS` is still set (deprecated): migrated into the gateway's CORS (blue, can be
///closed) or set but ignored because it differs from it (yellow, with both lists). Only removing
///it from the deploy and restarting the gateway makes it go away for good
class CorsEnvBanner extends StatelessWidget {
  final CorsModel gateway;
  final CorsEnvVar env;

  const CorsEnvBanner({required this.gateway, required this.env, super.key});

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl.cors;
    final ignored = !env.matches;
    final color = ignored ? c.warn : c.info;
    final mono = monoStyle(size: 12, color: c.text);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 10, 16, 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          border: Border(
            bottom: BorderSide(color: color.withValues(alpha: 0.45)),
          ),
        ),
        child: Row(
          children: [
            (ignored
                    ? app.assets.icons.general.alertTriangle
                    : app.assets.icons.general.info)
                .build(size: 18, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text:
                              '${ignored ? intl.envIgnoredTitle(name: env.name) : intl.envMigratedTitle(name: env.name)}  ',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: ignored
                              ? intl.envIgnoredDetail
                              : intl.envMigratedDetail,
                        ),
                      ],
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      height: 18 / 13,
                      color: c.text,
                    ),
                  ),
                  if (ignored) ...[
                    const SizedBox(height: 4),
                    SelectionArea(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${intl.envVariable}  ',
                              style: TextStyle(color: c.textTertiary),
                            ),
                            TextSpan(text: env.origins.join(', '), style: mono),
                            TextSpan(
                              text: '   ·   ${intl.envApplies}  ',
                              style: TextStyle(color: c.textTertiary),
                            ),
                            TextSpan(
                              text: gateway.allowedOrigins.join(', '),
                              style: mono,
                            ),
                          ],
                        ),
                        style: const TextStyle(fontSize: 12, height: 18 / 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: GatewayMapScreen.navigator.openGateway,
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color.withValues(alpha: 0.6)),
                minimumSize: const Size(0, 34),
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
              child: Text(intl.envOpen),
            ),
            //the ignored one stays: what applies isn't what the deploy says
            if (!ignored) ...[
              const SizedBox(width: 4),
              AppIconButton(
                icon: app.assets.icons.actions.close,
                tooltip: context.intl.actions.close,
                size: 34,
                iconSize: 16,
                onPressed: app.di.find<CorsCubit>().closeEnvInfo,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
