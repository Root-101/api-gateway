import 'dart:math';

import 'package:material_ui/material_ui.dart';

///like a css auto-fill grid: as many 380 px+ columns as fit, cards of a row share their height
class RoutesGrid extends StatelessWidget {
  //3 columns fit with the rail expanded too
  static const double minCardWidth = 380;
  static const double gap = 12;

  final List<Widget> cards;

  const RoutesGrid({required this.cards, super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = max(
          1,
          ((constraints.maxWidth + gap) / (minCardWidth + gap)).floor(),
        );
        return Column(
          children: [
            for (var i = 0; i < cards.length; i += columns)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : gap),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var col = 0; col < columns; col++) ...[
                        if (col > 0) const SizedBox(width: gap),
                        Expanded(
                          child: i + col < cards.length
                              ? cards[i + col]
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
