/// Platform-independent contract for the unified divider component.
library;

import 'package:coui_core/src/component/contracts/divider/divider_orientation.dart';
import 'package:coui_core/src/component/contracts/divider/divider_style.dart';

/// Contract for a unified divider.
///
/// Platform-neutral (Epic #1415 option D) — only the widget type [W]
/// remains generic.
abstract interface class CoreDividerContract<W> {
  /// Divider orientation.
  CoreDividerOrientation get orientation;

  /// Optional child rendered at the center of the divider.
  W? get child;

  /// Per-instance chrome / dimensional style. Carries every override
  /// previously exposed as flat widget params (`color` / `thickness` /
  /// `indent` / `endIndent` / `childPadding`).
  CoreDividerStyle? get dividerStyle;

  /// Whether this divider marks a meaningful boundary rather than pure
  /// decoration — e.g. between groups of items in a `Menu`.
  ///
  /// Most dividers are decorative (default `false`, no assistive-tech
  /// exposure). A caller that composes `Divider` as a structural
  /// separator — ARIA's non-focusable `role="separator"`
  /// (`CoreSemanticRole.separator`), distinct from that role's focusable
  /// "window splitter" variant — sets this to `true`, which is the only
  /// thing that turns on `role="separator"` + an accessible name (Web) /
  /// an accessible name alone (Flutter has no flag for the non-focusable
  /// case) — a bare `Divider` never announces itself, so a card's
  /// decorative rule between sections is unaffected.
  bool get semantic;
}
