import 'dart:math';

import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

///full-width slide control: drag the handle right to turn on, left to turn off, no confirmation.
///Arrow keys do the same, so it works without a mouse
class SlideSwitch extends StatefulWidget {
  final bool value;
  final String onLabel;
  final String offLabel;
  final String hint;

  ///null = locked (shows [lockedLabel] and can't move).
  ///Completes with true when the change was saved; till then the handle stays where it was dropped
  final Future<bool> Function(bool on)? onChanged;
  final String? lockedLabel;

  const SlideSwitch({
    required this.value,
    required this.onLabel,
    required this.offLabel,
    required this.hint,
    required this.onChanged,
    this.lockedLabel,
    super.key,
  });

  @override
  State<SlideSwitch> createState() => _SlideSwitchState();
}

class _SlideSwitchState extends State<SlideSwitch> {
  static const double _height = 44;
  static const double _knob = 38;

  ///handle position while dragging, 0 (left) to 1 (right); null when not dragging
  double? _drag;

  ///the side it was dropped on, shown until [SlideSwitch.value] gets there (or the save fails):
  ///without it the handle jumped back to the old side and then to the new one
  bool? _pending;
  bool _focused = false;

  @override
  void didUpdateWidget(SlideSwitch old) {
    super.didUpdateWidget(old);
    if (_pending == widget.value) _pending = null;
  }

  Future<void> _set(bool on) async {
    if (widget.onChanged == null || on == (_pending ?? widget.value)) return;
    setState(() => _pending = on);
    final ok = await widget.onChanged!(on);
    //failed, or the value was already there: show the real side again
    if (mounted && (!ok || _pending == widget.value)) {
      setState(() => _pending = null);
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _set(true);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _set(false);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final locked = widget.onChanged == null;
    final on = _pending ?? widget.value;
    return LayoutBuilder(
      builder: (context, constraints) {
        //inside the 1 px border: the knob runs 2 px from each end
        final travel = max(1.0, constraints.maxWidth - 2 - _knob - 4);
        final t = _drag ?? (on ? 1.0 : 0.0);
        final x = travel * t;
        final live = t;
        final slide = _drag == null
            ? motion(context, const Duration(milliseconds: 200))
            : Duration.zero;
        final label = locked
            ? (widget.lockedLabel ?? '')
            : (on ? widget.offLabel : widget.onLabel);
        return Semantics(
          toggled: on,
          enabled: !locked,
          label: label,
          hint: locked ? null : widget.hint,
          onTap: locked ? null : () => _set(!on),
          child: Focus(
            canRequestFocus: !locked,
            onKeyEvent: _onKey,
            onFocusChange: (f) => setState(() => _focused = f),
            child: Tooltip(
              message: locked ? '' : widget.hint,
              child: MouseRegion(
                //it acts like a button: the click hand, not the arrow
                cursor: locked
                    ? SystemMouseCursors.forbidden
                    : SystemMouseCursors.click,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: locked
                      ? null
                      : (d) => setState(
                          () => _drag = ((_drag ?? t) + d.delta.dx / travel)
                              .clamp(0.0, 1.0),
                        ),
                  onHorizontalDragEnd: locked
                      ? null
                      : (_) {
                          final end = (_drag ?? t) > 0.5;
                          setState(() => _drag = null);
                          _set(end);
                        },
                  //as in the canvas: a 44 px track, a 38 px knob with a shadow and an orange fill behind it
                  child: Opacity(
                    opacity: locked ? 0.45 : 1,
                    child: Container(
                      height: _height,
                      decoration: BoxDecoration(
                        color: on
                            ? c.maintenance.withValues(alpha: 0.10)
                            : c.night,
                        borderRadius: BorderRadius.circular(_height / 2),
                        border: Border.all(
                          color: _focused
                              ? c.lilac
                              : on
                              ? c.maintenance.withValues(alpha: 0.55)
                              : c.outlineCard,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedPositioned(
                            duration: slide,
                            curve: appEase,
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: x + _knob + 4,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: c.maintenance.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(
                                  _height / 2,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            //room for the knob on its side only: the canvas's 48 px on both cut the label
                            padding: on
                                ? const EdgeInsets.only(left: 12, right: 46)
                                : const EdgeInsets.only(left: 46, right: 12),
                            child: Opacity(
                              //fades out while the knob is dragged away from its side
                              opacity: _drag == null
                                  ? 1
                                  : (1 - (live - (on ? 1 : 0)).abs() * 2.2)
                                        .clamp(0.0, 1.0),
                              child: Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: on ? c.maintenance : c.textTertiary,
                                ),
                              ),
                            ),
                          ),
                          AnimatedPositioned(
                            duration: slide,
                            curve: appEase,
                            left: x + 2,
                            top: 2,
                            child: Container(
                              width: _knob,
                              height: _knob,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: live > 0.5 ? c.maintenance : c.label,
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x59000000),
                                    offset: Offset(0, 2),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: RotatedBox(
                                quarterTurns: on ? 2 : 0,
                                child: app.assets.icons.general.chevronsRight
                                    .build(
                                      size: 16,
                                      color: live > 0.5
                                          ? c.onMaintenance
                                          : c.surface,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
