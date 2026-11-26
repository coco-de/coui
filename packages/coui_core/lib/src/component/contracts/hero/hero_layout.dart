/// Layout axis for the `Hero` block.
library;

import 'package:coui_core/src/component/contracts/breakpoint/breakpoint_tier.dart';
import 'package:coui_core/src/component/contracts/media_query_visibility/core_breakpoint.dart';
import 'package:coui_core/src/component/contracts/responsive_row_column/responsive_row_column_contract.dart';

/// Arrangement of copy and media inside a `Hero` block.
///
/// - [center] renders `child` centred in the hero. `media` is not shown.
///   This is the default and matches the historical `HeroSection`.
/// - [split] places `child` (the copy) beside `media`. `media` is
///   trailing on the wide pose. Below
///   [CoreResponsiveRowColumnContract.defaultSwitchAt] the pair stacks
///   with the copy above the media — the same tablet threshold
///   `ResponsiveRowColumn` uses, not a hero-only breakpoint.
///
/// The enum lives on the widget, not as a variant chrome map. The two
/// members are one block arranged differently (`CoreFooterLayout`).
enum CoreHeroLayout {
  /// Centred copy. `media` is not rendered.
  center,

  /// Copy leading, media trailing. Stacks (copy above media) below the
  /// tablet breakpoint.
  split,
}

/// Whether a [CoreHeroLayout.split] hero lays the pair in a row.
///
/// True at or above [CoreResponsiveRowColumnContract.defaultSwitchAt]
/// (tablet — [CoreBreakpoint.md], 768px). Below that the pair stacks.
/// Both platforms call this so the threshold cannot drift.
bool heroSplitIsRow(CoreBreakpointTier tier) =>
    tier.isAtLeast(CoreResponsiveRowColumnContract.defaultSwitchAt);
