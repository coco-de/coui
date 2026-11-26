/// Platform-independent contract for slider components.
library;

import 'package:coui_core/src/component/contracts/slider/slider_style.dart';

/// Contract for a slider component.
///
/// Per Epic #1302, every chrome / dimensional override flows through
/// the single [sliderStyle] field — see [CoreSliderStyle] for the
/// merge chain. Behaviour fields (value / range / step / divisions /
/// callbacks / enabled) stay flat on the contract because they
/// describe the slider's **state and interaction**.
///
/// Type parameters:
/// - [W]: Widget type (Flutter: `Widget`, Web: `Component`).
abstract interface class CoreSliderContract<W> {
  /// Current slider value.
  double get value;

  /// Minimum value.
  double get min;

  /// Maximum value.
  double get max;

  /// Step increment.
  double? get step;

  /// Number of discrete divisions.
  int? get divisions;

  /// Optional widget drawn before the track (e.g. a "volume low" icon).
  /// `null` draws nothing and no gap.
  W? get leading;

  /// Optional widget drawn after the track (e.g. a "volume high" icon).
  /// `null` draws nothing and no gap.
  W? get trailing;

  /// Whether the slider is enabled.
  bool get enabled;

  /// Called when the value changes.
  void Function(double)? get onChanged;

  /// Called when the user starts dragging.
  void Function(double)? get onChangeStart;

  /// Called when the user stops dragging.
  void Function(double)? get onChangeEnd;

  /// Per-instance slider style covering track + thumb chrome plus
  /// nested tickLabelStyle.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreSliderTheme.style
  ///   → parent component slot override
  ///   → widget.sliderStyle
  /// ```
  ///
  /// Named [sliderStyle] (not `style`) so the Web base class
  /// `UiComponent.style: List<Styling>?` still works without
  /// colliding.
  CoreSliderStyle? get sliderStyle;
}
