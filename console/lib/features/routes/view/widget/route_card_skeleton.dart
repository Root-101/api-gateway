import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

class RouteCardSkeleton extends StatelessWidget {
  const RouteCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.raised),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppSkeleton(width: 140, height: 20),
              AppSkeleton(width: 110, height: 32, radius: 10),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.outlineSoft),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeleton(width: 40, height: 10, radius: 4),
                SizedBox(height: 8),
                AppSkeleton(width: double.infinity, height: 14),
                SizedBox(height: 14),
                AppSkeleton(width: 28, height: 10, radius: 4),
                SizedBox(height: 8),
                AppSkeleton(width: 260, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
