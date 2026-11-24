import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';

///shimmering placeholder of the first load
class AppSkeleton extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const AppSkeleton({this.width, this.height = 12, this.radius = 6, super.key});

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: app.colors.skeleton,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
    if (MediaQuery.disableAnimationsOf(context)) return box;
    return box
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1300.ms, color: app.colors.skeletonShine);
  }
}
