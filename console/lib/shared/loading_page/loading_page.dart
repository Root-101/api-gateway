import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) =>
      Center(child: SmallSpinner(color: app.colors.lilac, size: 28));
}
