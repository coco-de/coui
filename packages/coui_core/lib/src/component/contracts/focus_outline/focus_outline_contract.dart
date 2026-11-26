/// Platform-independent contract for unified focus outline components.
///
/// Defines the interface that all FocusOutline implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/focus_outline/focus_outline_shape.dart';
import 'package:coui_core/src/component/contracts/focus_outline/focus_outline_style.dart';

/// Contract for a unified focus outline component.
///
/// Renders a focus ring around [child] when [focused] is `true`. The
/// caller owns focus tracking — they pass the boolean from whichever
/// source matches their widget (e.g. `focusNode.hasFocus`,
/// `_focusing && isSelected`, or `FocusableActionDetector`'s
/// `onShowFocusHighlight`). The ring is positioned outside the
/// child's bounding box and uses the platform's primary color by
/// default.
///
/// Per Epic #1302 chrome / dimensional / animation overrides flow
/// through the single [focusOutlineStyle] field — see
/// [CoreFocusOutlineStyle] for the merge chain. Behavioural / shape
/// fields (`child` / `focused` / `shape`) stay flat on the widget.
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreFocusOutlineContract<W> {
  /// The child wrapped by the focus outline.
  W? get child;

  /// Whether the focus ring is currently visible. Driven by the caller.
  bool get focused;

  /// Outline shape. Defaults to [CoreFocusOutlineShape.rectangle].
  CoreFocusOutlineShape get shape;

  /// Per-instance chrome / dimensional / animation style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreFocusOutlineTheme.style
  ///   → parent component slot override
  ///   → widget.focusOutlineStyle
  /// ```
  CoreFocusOutlineStyle? get focusOutlineStyle;
}
