import 'package:coui_core/src/component/contracts/hover/hover_effect.dart';

/// Platform-independent contract for unified hover components.
///
/// Defines the interface that all `Hover` implementations
/// (Flutter, Web) must satisfy.
///
/// `Hover` wraps a child and provides two cross-platform features:
///
/// 1. **Hover-state tracking** — reports the pointer hover state via
///    [onHover] / [onEnter] / [onExit] callbacks, governed by the
///    [waitDuration] / [showDuration] / [minDuration] timings.
/// 2. **Hover visual effect** — animates a chosen [effect]
///    (scale / fade / brighten / shadow) while the pointer is over
///    the child.
///
/// Type parameters:
/// - [W] - platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreHoverContract<W> {
  /// Content wrapped by the hover region.
  W? get child;

  /// Visual effect applied while the pointer is over [child].
  CoreHoverEffect get effect;

  /// Fired whenever the resolved hover state changes.
  ///
  /// The positional `bool` is the new hover state — `true` once the
  /// pointer has rested for [waitDuration], `false` once it has left
  /// for [showDuration]. Named positionally to match the Flutter
  /// `ValueChanged<bool>` and Web `ValueChanged<bool>` callback shape.
  void Function(bool)? get onHover;

  /// Fired immediately when the pointer enters [child], before any
  /// timing delay.
  void Function()? get onEnter;

  /// Fired immediately when the pointer leaves [child], before any
  /// timing delay.
  void Function()? get onExit;

  /// Delay before the hover state is reported as active.
  ///
  /// When null, resolves to `CoreHoverTheme.style?.waitDuration` then
  /// the design-system default (500 ms).
  Duration? get waitDuration;

  /// Delay before the hover state is reported as inactive after the
  /// pointer leaves.
  ///
  /// When null, resolves to `CoreHoverTheme.style?.showDuration` then
  /// the design-system default (200 ms).
  Duration? get showDuration;

  /// Minimum duration the hover state stays active once reported,
  /// even if the pointer leaves quickly.
  ///
  /// When null, resolves to `CoreHoverTheme.style?.minDuration` then
  /// the design-system default (0 ms).
  Duration? get minDuration;
}
