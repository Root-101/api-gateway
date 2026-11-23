import 'package:console/app_exporter.dart';
import 'package:console/features/routes/view/form/widgets/route_form_stepper.dart';
import 'package:material_ui/material_ui.dart';

///the stepper, and Cancel / Back and Next / Save (create or save changes on the last step)
class RouteFormFooter extends StatelessWidget {
  final int step;
  final int steps;
  final bool isEdit;
  final bool busy;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const RouteFormFooter({
    required this.step,
    required this.steps,
    required this.isEdit,
    required this.busy,
    required this.onBack,
    required this.onNext,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final form = intl.form;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.raised)),
      ),
      child: Row(
        children: [
          RouteFormStepper(
            current: step,
            count: steps,
            nameOf: (step) => switch (step) {
              1 => form.stepGeneral,
              2 => form.stepForwarding,
              _ => form.stepRewrite,
            },
          ),
          const Spacer(),
          AppButton(
            label: step == 1 ? intl.actions.cancel : intl.actions.back,
            kind: AppButtonKind.outlined,
            height: 44,
            onPressed: onBack,
          ),
          const SizedBox(width: 8),
          AppButton(
            label: step < steps
                ? form.next
                : (isEdit ? form.saveChanges : intl.routes.createRoute),
            height: 44,
            onPressed: busy ? null : onNext,
          ),
        ],
      ),
    );
  }
}
