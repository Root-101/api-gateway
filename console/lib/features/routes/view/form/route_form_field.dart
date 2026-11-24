import 'package:material_ui/material_ui.dart';

///one field of the form: its api name, controller and focus
class RouteFormField {
  final String key;
  final int step;
  final TextEditingController ctrl = TextEditingController();
  final FocusNode focus = FocusNode();

  ///the whole field (label, input and error), to scroll it into view
  final GlobalKey box = GlobalKey();

  RouteFormField(this.key, this.step);

  void dispose() {
    ctrl.dispose();
    focus.dispose();
  }
}
