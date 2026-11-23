import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

///one step's body: its title and help in one line, as in the canvas
///("General · How the route shows up in the console"), then its fields
class RouteFormStep extends StatelessWidget {
  final String title;
  final String help;
  final List<Widget> fields;

  const RouteFormStep({
    required this.title,
    required this.help,
    required this.fields,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 8,
          runSpacing: 2,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                height: 22 / 16,
                fontWeight: FontWeight.w600,
                color: c.text,
              ),
            ),
            for (final part in ['·', help])
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  part,
                  style: TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    color: c.textTertiary,
                  ),
                ),
              ),
          ],
        ),
        for (final field in fields) ...[const SizedBox(height: 14), field],
      ],
    );
  }
}
