/// Density steps for a `MenuItem` row.
library;

import 'package:coui_core/src/size/component_size.dart';

/// The three row heights a menu draws — 32 / 36 / 48.
///
/// Component-specific rather than [CoreComponentSize] because the ladder
/// really is three rungs. 32 is where Primer's ActionList `medium` and
/// Fluent's MenuItem independently landed for desktop; 48 is M3's
/// `MenuListItemContainerHeight` and Flutter's `kMinInteractiveDimension`;
/// 36 is the `md` row — a height between the control ladder's 32 and 40,
/// so the row sits under a `md` Select trigger (40) rather than level with
/// it. None of the six systems surveyed draws a menu row under 32 or over
/// 48, so stating `xs` / `xl` / `xl2` would be an axis that lies about its
/// range.
///
/// The **menu** owns the size, not the row: `Menu(size: …)` hands one value
/// to every row, so a single menu never mixes heights.
enum CoreMenuItemSize {
  /// 32px rows — the default, and the height dense desktop menus settle on.
  sm,

  /// 36px rows. 36 is not a rung of the control ladder, so a density does
  /// not move it.
  md,

  /// 48px rows — touch targets.
  lg;

  /// Widget default. Both platform constructors reference this value.
  static const CoreMenuItemSize defaultSize = sm;

  /// The shared size rung a composed child (`Icon`, an affordance
  /// `Button`) takes for this row density — the same name on both ladders.
  CoreComponentSize toComponentSize() => switch (this) {
    sm => CoreComponentSize.sm,
    md => CoreComponentSize.md,
    lg => CoreComponentSize.lg,
  };
}
