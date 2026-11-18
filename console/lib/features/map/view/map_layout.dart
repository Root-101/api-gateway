import 'dart:math';

class MapLayout {
  static const double cardW = 248;
  static const double cardH = 140;
  static const double gap = 48;
  static const double urlW = 440;
  static const double urlH = 44;
  static const double gwW = 350;
  static const double gwH = 112;
  static const double gwTop = 92;
  static const double cardTop = 352;
  static const double margin = 120;

  final int count;
  late final double width = max(
    900,
    max(1, count) * cardW + (max(1, count) - 1) * gap + margin * 2,
  );
  final double height = cardTop + cardH + 40;

  MapLayout(this.count);

  double get cx => width / 2;

  double get gwBottom => gwTop + gwH;

  double get labelY => (gwBottom + cardTop) / 2;

  double cardLeft(int i) {
    final n = max(1, count);
    final total = n * cardW + (n - 1) * gap;
    return cx - total / 2 + i * (cardW + gap);
  }

  double cardCenter(int i) => cardLeft(i) + cardW / 2;

  ///where branch [i] leaves the gateway node: spread along its bottom edge
  double startX(int i) =>
      cx + ((cardCenter(i) - cx) * 0.35).clamp(-gwW / 2 + 40, gwW / 2 - 40);
}
