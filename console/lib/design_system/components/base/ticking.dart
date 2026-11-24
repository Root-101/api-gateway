import 'package:material_ui/material_ui.dart';

///rebuilds [builder] every 10 s, so "on for 3 min" and countdowns move on by themselves
class Ticking extends StatelessWidget {
  static final Stream<void> _clock = Stream<void>.periodic(
    const Duration(seconds: 10),
  ).asBroadcastStream();

  final WidgetBuilder builder;

  const Ticking({required this.builder, super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<void>(
    stream: _clock,
    builder: (context, _) => builder(context),
  );
}
