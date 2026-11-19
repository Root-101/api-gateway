import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';

///compact steps: only the current one shows its name, the others their number (✓ when done) with a tooltip
class RouteFormStepper extends StatelessWidget {
  final int current;
  final int count;
  final String Function(int step) nameOf;

  const RouteFormStepper({
    required this.current,
    required this.count,
    required this.nameOf,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final form = context.intl.form;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var step = 1; step <= count; step++) ...[
          Tooltip(
            message: form.stepOf(step: step, name: nameOf(step)),
            child: Semantics(
              selected: step == current,
              label: form.stepOf(step: step, name: nameOf(step)),
              child: ExcludeSemantics(child: _dot(c, step)),
            ),
          ),
          if (step == current) ...[
            const SizedBox(width: 6),
            ExcludeSemantics(
              child: Text(
                nameOf(step),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.text,
                ),
              ),
            ),
          ],
          if (step < count)
            Container(
              width: 16,
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color: step < current ? c.lilac : c.outlineCard,
            ),
        ],
      ],
    );
  }

  Widget _dot(AppColors c, int step) {
    final done = step < current;
    final now = step == current;
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: now
            ? c.lilac
            : done
            ? c.lilac.withValues(alpha: 0.16)
            : Colors.transparent,
        border: Border.all(color: done || now ? c.lilac : c.outline),
      ),
      child: done
          ? app.assets.icons.general.check.build(size: 13, color: c.lilac)
          : Text(
              '$step',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: now ? c.onLilac : c.textTertiary,
              ),
            ),
    );
  }
}
