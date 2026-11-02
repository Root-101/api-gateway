import 'package:gap/gap.dart';

///Extensions to simplify the use of gap
///uso: 1.0.gap()
///       1.gap()
extension GapExtensionInt on int {
  Gap gap() => Gap(toDouble());
}

extension GapExtensionDouble on double {
  Gap gap() => Gap(this);
}
