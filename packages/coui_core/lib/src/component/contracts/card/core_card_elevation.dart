/// Shadow elevation level for card components.
library;

import 'package:coui_core/src/component/contracts/outlined_container/core_outlined_container_elevation.dart';

/// Shadow elevation level for card components.
enum CoreCardElevation {
  /// No shadow.
  none,

  /// Subtle shadow for slight depth.
  soft,

  /// Medium shadow for moderate depth.
  medium,

  /// Strong shadow for prominent depth.
  strong;

  /// Maps this card elevation to the matching
  /// [CoreOutlinedContainerElevation]. Both enums share the same four
  /// levels — keeping the conversion next to the source enum means
  /// any future entry added here surfaces a compile error on the
  /// switch instead of silently drifting from the outlined container
  /// counterpart.
  CoreOutlinedContainerElevation toOutlinedContainerElevation() {
    return switch (this) {
      .none => .none,
      .soft => .soft,
      .medium => .medium,
      .strong => .strong,
    };
  }
}
