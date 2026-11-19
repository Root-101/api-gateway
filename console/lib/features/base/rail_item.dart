import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';

class RailLabel extends StatelessWidget {
  final bool open;
  final Widget child;

  const RailLabel({required this.open, required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final duration = motion(context, const Duration(milliseconds: 280));
    return AnimatedOpacity(
      opacity: open ? 1 : 0,
      duration: duration,
      curve: open ? const Interval(0.35, 1) : Curves.linear,
      child: AnimatedSlide(
        offset: open ? Offset.zero : const Offset(-0.1, 0),
        duration: duration,
        curve: appEase,
        child: child,
      ),
    );
  }
}

class RailItem extends StatelessWidget {
  final SvgAsset icon;
  final String label;
  final bool open;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  const RailItem({
    required this.icon,
    required this.label,
    required this.open,
    required this.selected,
    required this.onTap,
    this.trailing,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final color = selected ? c.onSelected : c.label;
    final item = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: selected ? c.selected : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 48,
            //the row keeps its open width while the rail animates, the rail clips it
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              maxWidth: 232,
              child: SizedBox(
                width: 232,
                child: Row(
                  children: [
                    SizedBox(
                      width: 56,
                      child: Center(child: icon.build(size: 22, color: color)),
                    ),
                    Expanded(
                      child: RailLabel(
                        open: open,
                        child: Text(
                          label,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                    if (trailing != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: RailLabel(open: open, child: trailing!),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return Semantics(
      selected: selected,
      child: open ? item : Tooltip(message: label, child: item),
    );
  }
}

class RailCountBadge extends StatelessWidget {
  final int count;

  const RailCountBadge(this.count, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.lilac.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: c.lilac,
        ),
      ),
    );
  }
}
