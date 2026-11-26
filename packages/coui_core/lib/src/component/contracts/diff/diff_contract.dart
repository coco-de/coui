/// Platform-independent contract for unified `Diff` components.
library;

import 'package:coui_core/src/component/contracts/diff/diff_style.dart';

/// Contract for a unified before/after split-view comparison
/// component (daisyUI's `Diff` pattern — image vs image, text vs
/// text, anything vs anything, with a draggable resizer).
///
/// Per Epic #1302 / #1370 Phase 4 chrome and dimensional / initial
/// layout overrides flow through the single [diffStyle] field — see
/// [CoreDiffStyle] for the merge chain. Behaviour fields
/// (`before` / `after` / `onPositionChanged` / `interactive` /
/// `ariaLabel`) stay flat on the widget.
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreDiffContract<W> {
  /// Content shown on the left / "before" side.
  W get before;

  /// Content shown on the right / "after" side.
  W get after;

  /// Fired whenever the user drags the resizer or moves it via
  /// keyboard / focus tap-to-expand. Pass-through is best-effort —
  /// the component still owns the position (uncontrolled).
  void Function(double position)? get onPositionChanged;

  /// Chip drawn over the frame's top-left corner to say what the "before"
  /// side is. `null` (the default) draws nothing.
  ///
  /// The chip is a `Badge` the component draws around this widget, placed
  /// [CoreDiffStyle.labelInset] in from the corner; the slot takes the
  /// content only (typically a text).
  W? get beforeLabel;

  /// Chip drawn over the frame's top-right corner to say what the "after"
  /// side is. `null` (the default) draws nothing. Same chip as
  /// [beforeLabel].
  W? get afterLabel;

  /// Whether the resizer responds to pointer / keyboard events. When
  /// `false` only the split line is drawn — no handle — and the split
  /// stays where it started.
  bool get interactive;

  /// Accessible label for the comparison region (announced by screen
  /// readers via `aria-label` on the root element).
  String? get ariaLabel;

  /// Per-instance chrome / dimensional style. Layout chrome
  /// (`aspectRatio`, `initialPosition`) lives here since Epic #1370
  /// Phase 4 — the legacy widget flat fields were removed.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreDiffTheme.style
  ///   → parent component slot override
  ///   → widget.diffStyle
  /// ```
  CoreDiffStyle? get diffStyle;
}
