import 'package:flutter/widgets.dart' show FontWeight;

import '../util/core_to_flutter.dart' show fontWeightFromInt;

/// Converts [CoreFontWeight] int values to Flutter [FontWeight].
///
/// ```dart
/// CoreFontWeight.semiBold.weight  // FontWeight.w600
/// ```
extension CoreFontWeightExt on int {
  /// Flutter [FontWeight] equivalent.
  ///
  /// Delegates to [fontWeightFromInt] — the single source of the
  /// int → `FontWeight` mapping (shared with resolver-side conversions).
  FontWeight get weight => fontWeightFromInt(this)!;
}
