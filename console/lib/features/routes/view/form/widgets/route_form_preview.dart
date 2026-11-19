import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';

///the route as its card in Routes will show it, with a pencil per value that opens its field
class RouteFormPreview extends StatelessWidget {
  final RouteFormModel model;
  final String gatewayUrl;
  final String rewriteFrom;
  final String rewriteTo;
  final VoidCallback onEditName;
  final VoidCallback onEditDescription;
  final VoidCallback onEditPath;
  final VoidCallback onEditUri;
  final VoidCallback onEditRewrite;

  const RouteFormPreview({
    required this.model,
    required this.gatewayUrl,
    required this.rewriteFrom,
    required this.rewriteTo,
    required this.onEditName,
    required this.onEditDescription,
    required this.onEditPath,
    required this.onEditUri,
    required this.onEditRewrite,
    super.key,
  });

  Widget _pencil(String tooltip, VoidCallback onPressed) => AppIconButton(
    icon: app.assets.icons.actions.edit,
    tooltip: tooltip,
    size: 28,
    iconSize: 14,
    radius: 8,
    color: app.colors.textTertiary,
    onPressed: onPressed,
  );

  ///the value, or its placeholder dimmed
  Widget _value(String value, String placeholder, TextStyle style) => Text(
    value.isEmpty ? placeholder : value,
    style: value.isEmpty
        ? style.copyWith(color: app.colors.textPlaceholder)
        : style,
  );

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final form = intl.form;
    final url = monoStyle(size: 13, height: 20 / 13, color: c.text);
    final hasRewrite = rewriteFrom.isNotEmpty || rewriteTo.isNotEmpty;
    return Column(
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
                        child: DefaultTextStyle.merge(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          child: _value(
                            model.name,
                            form.previewName,
                            TextStyle(
                              fontSize: 19,
                              height: 26 / 19,
                              fontWeight: FontWeight.w500,
                              color: c.text,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      _pencil(form.editName, onEditName),
                    ],
                  ),
                  Transform.translate(
                    offset: const Offset(0, -4),
                    child: Row(
                      children: [
                        Flexible(
                          child: DefaultTextStyle.merge(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            child: _value(
                              model.description,
                              intl.routes.noDescription,
                              TextStyle(
                                fontSize: 13,
                                height: 18 / 13,
                                color: c.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        _pencil(form.editDescription, onEditDescription),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.raised,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                form.preview,
                style: TextStyle(
                  fontSize: 11,
                  height: 16 / 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: c.label,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 6, 6, 10),
          decoration: BoxDecoration(
            color: c.night,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.outlineSoft),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _urlHeader(intl.routes.from, false, form.editPath, onEditPath),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _value(
                  model.path.isEmpty ? '' : model.enterPoint,
                  '$gatewayUrl/…',
                  url,
                ),
              ),
              Container(
                height: 1,
                margin: const EdgeInsets.fromLTRB(0, 8, 6, 2),
                color: c.outlineSoft,
              ),
              _urlHeader(intl.routes.to, true, form.editUri, onEditUri),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _value(
                  model.uri.isEmpty ? '' : model.redirectTo,
                  'https://…',
                  url,
                ),
              ),
              if (hasRewrite)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text.rich(
                          TextSpan(
                            text: '${form.rewrite} ',
                            children: [
                              TextSpan(
                                text:
                                    '${rewriteFrom.isEmpty ? '…' : rewriteFrom} → ${rewriteTo.isEmpty ? '…' : rewriteTo}',
                                style: monoStyle(size: 12, color: c.label),
                              ),
                            ],
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            height: 16 / 12,
                            color: c.textTertiary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _pencil(form.editRewrite, onEditRewrite),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _urlHeader(
    String caption,
    bool accent,
    String tooltip,
    VoidCallback onEdit,
  ) {
    final c = app.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CaptionText(caption, color: accent ? c.lilac : c.textTertiary),
        _pencil(tooltip, onEdit),
      ],
    );
  }
}
