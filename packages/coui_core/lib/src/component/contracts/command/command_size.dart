/// Density steps for the `Command` palette.
library;

import 'package:coui_core/src/component/contracts/chip/chip_size.dart';
import 'package:coui_core/src/size/component_size.dart';

/// The three density steps a command palette draws — the same rungs form
/// controls sit on (row 32 / 40 / 48).
///
/// Component-specific rather than [CoreComponentSize] because the ladder
/// really is three rungs: `lg`'s 48 is the touch target a fullscreen row
/// needs, and `sm`'s 32 is the inline desktop panel. There is no `xs`
/// palette — a row below 32 cannot hold a 14px label with its inset — and
/// nothing above `lg` that a wider viewport would want. Stating six and
/// drawing three would be an axis that lies about its range.
enum CoreCommandSize {
  /// 32px rows — inline panels on desktop.
  sm,

  /// 40px rows — the dialog palette.
  md,

  /// 48px rows — fullscreen (touch) palettes.
  lg;

  /// Widget default. Both platform constructors reference this value.
  static const CoreCommandSize defaultSize = md;

  /// The shared size rung the composed children (`TextField` / `Button`)
  /// take for this palette density — the same name on both ladders.
  CoreComponentSize toComponentSize() => switch (this) {
    sm => CoreComponentSize.sm,
    md => CoreComponentSize.md,
    lg => CoreComponentSize.lg,
  };

  /// The rung the scope `Chip` takes — `Chip` owns its own three-step
  /// ladder (28 / 32 / 40) rather than the shared six, and the names line
  /// up one to one with the palette's.
  CoreChipSize toChipSize() => switch (this) {
    sm => CoreChipSize.sm,
    md => CoreChipSize.md,
    lg => CoreChipSize.lg,
  };
}
