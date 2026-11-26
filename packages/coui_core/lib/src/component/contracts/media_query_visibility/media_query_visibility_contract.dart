/// Platform-independent contract for the unified MediaQueryVisibility
/// component.
library;

import 'package:coui_core/src/component/contracts/media_query_visibility/core_breakpoint.dart';

/// Contract for a responsive visibility wrapper.
///
/// Shows [child] when the current viewport width is within
/// `minWidth..maxWidth` (inclusive/exclusive per platform convention),
/// otherwise shows [alternateChild] (or nothing).
///
/// Pixel bounds ([minWidth]/[maxWidth]) take precedence over `breakpoint`
/// bounds ([minBreakpoint]/[maxBreakpoint]). When both are provided for the
/// same end, the pixel value wins so that consumers can fine-tune above the
/// breakpoint system.
///
/// Type parameters:
/// - [W] - platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreMediaQueryVisibilityContract<W> {
  /// Content shown when the viewport is within range.
  W get child;

  /// Content shown when the viewport is out of range. `null` renders empty.
  W? get alternateChild;

  /// Explicit minimum viewport width (px).
  double? get minWidth;

  /// Explicit maximum viewport width (px).
  double? get maxWidth;

  /// Minimum breakpoint at which [child] is visible.
  CoreBreakpoint? get minBreakpoint;

  /// Maximum breakpoint at which [child] is visible.
  CoreBreakpoint? get maxBreakpoint;
}
