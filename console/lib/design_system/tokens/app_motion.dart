import 'package:material_ui/material_ui.dart';

const Curve appEase = Cubic(0.2, 0, 0, 1);

///[duration], or none when the user prefers reduced motion
Duration motion(BuildContext context, Duration duration) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
