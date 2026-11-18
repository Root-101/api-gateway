import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';

///a node of the map: clickable card with a hover shadow and the selection ring
class MapNode extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool selected;
  final bool dashed;
  final Color background;
  final Color border;

  ///the 2 px border while it's selected: lilac, or the state's (maintenance, down) as in the canvas
  final Color? selectedBorder;
  final String semanticLabel;

  const MapNode({
    required this.child,
    required this.onTap,
    required this.selected,
    required this.background,
    required this.border,
    required this.semanticLabel,
    this.selectedBorder,
    this.dashed = false,
    super.key,
  });

  @override
  State<MapNode> createState() => _MapNodeState();
}

class _MapNodeState extends State<MapNode> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final border = widget.selected
        ? widget.selectedBorder ?? c.lilac
        : widget.border;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: motion(context, const Duration(milliseconds: 150)),
            decoration: BoxDecoration(
              color: widget.background,
              borderRadius: BorderRadius.circular(16),
              border: widget.dashed && !widget.selected
                  ? null
                  : Border.all(color: border, width: widget.selected ? 2 : 1),
              boxShadow: [
                if (_hovered)
                  const BoxShadow(
                    color: Color(0x73000000),
                    blurRadius: 28,
                    offset: Offset(0, 10),
                  ),
              ],
            ),
            child: CustomPaint(
              foregroundPainter: widget.dashed && !widget.selected
                  ? DashedBorder(color: border, radius: 16, width: 1.2)
                  : null,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
