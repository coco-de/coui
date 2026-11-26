/// Platform-independent contract for unified swap components.
///
/// Defines the interface that all Swap implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/swap/swap_style.dart';

/// Animation type for swap transitions.
enum CoreSwapAnimation {
  /// No animation.
  none,

  /// Rotation animation.
  rotate,

  /// Flip animation.
  flip,
}

/// Contract for a unified swap component.
///
/// Toggles between two visual states with optional animation.
///
/// Per Epic #1302 every chrome / animation override flows through
/// the single [swapStyle] field — see [CoreSwapStyle] for the merge
/// chain. Behaviour / semantic fields (`animation` variant enum,
/// `checked` boolean toggle, `onContent` / `offContent` composition
/// slots, `onToggle` callback) stay flat on the widget.
///
/// Type parameters:
/// - [W] - platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreSwapContract<W> {
  /// Content displayed in "on" (checked) state.
  W get onContent;

  /// Content displayed in "off" (unchecked) state.
  W get offContent;

  /// Whether in "on" state.
  bool get checked;

  /// Animation type for transitions.
  CoreSwapAnimation get animation;

  /// Toggle callback fired with the new checked value on click.
  ///
  /// The positional `bool` matches Flutter's `ValueChanged<bool>` and
  /// Web `ValueChanged<bool>` — both use a positional parameter, so
  /// naming it here would diverge from the platform callback shape
  /// that contract implementers must accept.
  void Function(bool)? get onToggle;

  /// Per-instance chrome / animation style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreSwapTheme.style
  ///   → parent component slot override
  ///   → widget.swapStyle
  /// ```
  CoreSwapStyle? get swapStyle;
}
