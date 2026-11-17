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

  ///null = locked (shows [lockedLabel] and can't move)
  final ValueChanged<bool>? onChanged;
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
  static const double _height = 48;
  static const double _knob = 40;

  ///handle position while dragging, 0 (left) to 1 (right); null when not dragging
  double? _drag;
  bool _focused = false;

  void _set(bool on) {
    if (widget.onChanged == null || on == widget.value) return;
    widget.onChanged!(on);
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
    final on = widget.value;
    return LayoutBuilder(
      builder: (context, constraints) {
        final travel = constraints.maxWidth - _knob - 8;
        final t = _drag ?? (on ? 1.0 : 0.0);
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
                child: Container(
                  height: _height,
                  decoration: BoxDecoration(
                    color: locked
                        ? c.field
                        : on
                        ? c.maintenance.withValues(alpha: 0.14)
                        : c.field,
                    borderRadius: BorderRadius.circular(_height / 2),
                    border: Border.all(
                      color: _focused
                          ? c.lilac
                          : on && !locked
                          ? c.maintenance.withValues(alpha: 0.5)
                          : c.outlineCard,
                      width: _focused ? 2 : 1,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        //the text takes the side the handle isn't on
                        padding: on && !locked
                            ? const EdgeInsets.only(left: 16, right: 52)
                            : const EdgeInsets.only(left: 52, right: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (locked) ...[
                              app.assets.icons.general.lock.build(
                                size: 15,
                                color: c.textTertiary,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: locked
                                      ? c.textTertiary
                                      : on
                                      ? c.maintenance
                                      : c.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 4 + travel * t,
                        top: (_height - 2 - _knob) / 2,
                        child: AnimatedOpacity(
                          opacity: locked ? 0.35 : 1,
                          duration: const Duration(milliseconds: 150),
                          child: Container(
                            width: _knob,
                            height: _knob,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: locked
                                  ? c.raised
                                  : on
                                  ? c.maintenance
                                  : c.lilacText,
                              shape: BoxShape.circle,
                            ),
                            child: Transform.flip(
                              flipX: on,
                              child: Text(
                                '»',
                                style: TextStyle(
                                  fontSize: 18,
                                  height: 1,
                                  fontWeight: FontWeight.w700,
                                  color: on ? c.onMaintenance : c.onLilac,
                                ),
                              ),
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
        );
      },
    );
  }
}
