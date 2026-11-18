import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';

///duplicate: the name of the source route; its ⓘ opens the note about reviewing the copy
class RouteFormDuplicateChip extends StatefulWidget {
  final String name;

  const RouteFormDuplicateChip({required this.name, super.key});

  @override
  State<RouteFormDuplicateChip> createState() => _RouteFormDuplicateChipState();
}

class _RouteFormDuplicateChipState extends State<RouteFormDuplicateChip> {
  final _popup = OverlayPortalController();
  final _link = LayerLink();

  void _toggle() => setState(_popup.toggle);

  void _hide() {
    if (_popup.isShowing) setState(_popup.hide);
  }

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final form = context.intl.form;
    return TapRegion(
      groupId: _link,
      onTapOutside: (_) => _hide(),
      child: CompositedTransformTarget(
        link: _link,
        child: OverlayPortal(
          controller: _popup,
          overlayChildBuilder: (context) => CompositedTransformFollower(
            link: _link,
            targetAnchor: Alignment.bottomLeft,
            offset: const Offset(0, 10),
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: TapRegion(groupId: _link, child: _note(context, c)),
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Semantics(
              button: true,
              expanded: _popup.isShowing,
              label: form.aboutDuplicating(name: widget.name),
              child: Material(
                color: c.lilac.withValues(alpha: 0.10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: c.lilac.withValues(alpha: 0.35)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _toggle,
                  child: Container(
                    height: 28,
                    padding: const EdgeInsets.only(left: 10, right: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: ExcludeSemantics(
                            child: Text(
                              widget.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: monoStyle(
                                size: 13,
                                weight: FontWeight.w500,
                                color: c.lilac,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        app.assets.icons.general.info.build(
                          size: 15,
                          color: c.lilac,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _note(BuildContext context, AppColors c) {
    final form = context.intl.form;
    return Material(
      color: c.popupLilac,
      elevation: 16,
      shadowColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: c.lilac.withValues(alpha: 0.35)),
      ),
      child: Container(
        width: 360,
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: app.assets.icons.actions.duplicate.build(
                size: 18,
                color: c.lilac,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: '${form.duplicatingStart} ',
                  children: [
                    TextSpan(
                      text: widget.name,
                      style: monoStyle(color: c.lilac, weight: FontWeight.w500),
                    ),
                    TextSpan(text: form.duplicatingEnd),
                  ],
                ),
                style: TextStyle(fontSize: 13, height: 19 / 13, color: c.text),
              ),
            ),
            const SizedBox(width: 4),
            AppIconButton(
              icon: app.assets.icons.actions.close,
              tooltip: context.intl.actions.close,
              size: 28,
              iconSize: 14,
              radius: 8,
              onPressed: _hide,
            ),
          ],
        ),
      ),
    );
  }
}
