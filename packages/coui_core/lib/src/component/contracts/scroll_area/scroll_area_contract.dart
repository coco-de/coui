/// Platform-independent contract for the unified scroll-area component.
library;

import 'package:coui_core/src/component/contracts/scroll_area/scroll_area_direction.dart';
import 'package:coui_core/src/component/contracts/scroll_area/scroll_area_style.dart';

/// Contract for a unified `ScrollArea`.
///
/// Wraps a [child] in a scrollable viewport with a design-system styled
/// scrollbar. Unlike `FadeScroll` (which masks the edges with a
/// gradient), `ScrollArea` keeps the content fully visible and lets
/// the slim scrollbar communicate the overflow.
///
/// All chrome / dimensional overrides (`height`, `maxHeight`, plus the
/// nested `scrollbarStyle` slot for the composed scrollbar) flow
/// through the single [scrollAreaStyle] field. Behavioural fields
/// (`child`, `showScrollbar`) and the semantic enum (`direction`)
/// remain flat on the widget. The Flutter-only `ScrollController` is
/// exposed as a widget-level field rather than a contract member —
/// Web has no equivalent.
///
/// Type parameter:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreScrollAreaContract<W> {
  /// Scrollable content inside the viewport.
  W get child;

  /// Scroll axis. Defaults to [CoreScrollAreaDirection.defaultDirection].
  CoreScrollAreaDirection get direction;

  /// Whether to render the design-system scrollbar inside the viewport.
  /// When `false` the viewport stays scrollable but the scrollbar is
  /// hidden — useful when the surrounding chrome already communicates
  /// overflow (e.g. a fade gradient or a paginated indicator).
  bool get showScrollbar;

  /// Per-instance chrome / dimensional style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// CoreScrollAreaStyle.defaultX               ← static const default
  ///   → CoreComponentTheme.scrollArea.style    ← project-level override
  ///   → widget.scrollAreaStyle                 ← per-instance override
  /// ```
  CoreScrollAreaStyle? get scrollAreaStyle;
}
