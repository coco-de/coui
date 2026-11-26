/// Platform-independent contract for unified indicator components.
library;

import 'package:coui_core/src/component/contracts/indicator/indicator_position.dart';
import 'package:coui_core/src/component/contracts/indicator/indicator_style.dart';

/// Contract for a unified `Indicator`.
///
/// Wraps a [child] and overlays an [item] on a corner / edge of the bounding
/// box. Used for status dots on avatars, count badges on icons, "NEW" labels
/// on cards, etc.
///
/// Type parameter:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreIndicatorContract<W> {
  /// Main content wrapped by the indicator overlay.
  W get child;

  /// Item rendered on the corner / edge of [child] (e.g., a `Badge`).
  W get item;

  /// Horizontal position of [item] relative to [child].
  CoreIndicatorHorizontalPosition get horizontalPosition;

  /// Vertical position of [item] relative to [child].
  CoreIndicatorVerticalPosition get verticalPosition;

  /// Per-instance chrome / dimensional style (currently only `offset`).
  /// Resolution order: `widget.indicatorStyle` → `theme.style` →
  /// `CoreIndicatorStyle.defaultOffset`.
  CoreIndicatorStyle? get indicatorStyle;
}
