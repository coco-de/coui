/// Density steps for a `Select` trigger — and, through it, its rows.
library;

import 'package:coui_core/src/component/contracts/menu_item/menu_item_size.dart';
import 'package:coui_core/src/size/component_size.dart';

/// The three height floors a select trigger comes in — 32 / 40 / 48, the
/// same rungs the form fields sit on (`md` / `lg` sit exactly on theirs;
/// `sm`'s content runs a little past 32). The menu rows under it are
/// 32 / 36 / 48: `sm` and `lg` rows are as tall as their trigger, the `md`
/// row (36) is a step under the 40 trigger.
///
/// Component-specific rather than [CoreComponentSize] because the ladder
/// really is three rungs (Select 코드 인계 통합본 2026-09-08 §2): only
/// Fluent draws a 24 select, and there its type falls to 12px; M3's 56 is
/// the height of a field whose label lives inside it, which this kit's
/// does not. An axis that stated `xs` / `xl` / `xl2` would be lying about
/// its range.
///
/// **The trigger's size is the row's size.** `md` opens onto `md` rows —
/// the two ladders share their three names on purpose ([toMenuItemSize]),
/// so a select never mixes a `md` trigger with `sm` rows.
enum CoreSelectSize {
  /// 32px — dense desktop forms. The trigger is a one-line field held on
  /// its row, so it sits on 32 with the value line centred, like the `md`
  /// and `lg` rungs on theirs.
  sm,

  /// 40px — the default, level with the `md` `TextField` beside it.
  md,

  /// 48px — touch targets.
  lg;

  /// Widget default. Both platform constructors reference this value.
  static const CoreSelectSize defaultSize = md;

  /// The `TextField` rung the composed trigger takes — the same name on
  /// both ladders, and the same 32 / 40 / 48 heights.
  CoreComponentSize toComponentSize() => switch (this) {
    sm => CoreComponentSize.sm,
    md => CoreComponentSize.md,
    lg => CoreComponentSize.lg,
  };

  /// The `MenuItem` rung the option rows take — the same three names, so
  /// the trigger and the rows under it agree on size.
  CoreMenuItemSize toMenuItemSize() => switch (this) {
    sm => CoreMenuItemSize.sm,
    md => CoreMenuItemSize.md,
    lg => CoreMenuItemSize.lg,
  };
}
