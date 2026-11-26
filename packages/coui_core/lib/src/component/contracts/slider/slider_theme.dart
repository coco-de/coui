/// Theme data for `Slider` customisation.
library;

import 'package:coui_core/src/component/contracts/slider/slider_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `Slider`.
///
/// Holds the project [style] applied to every `Slider` whose
/// widget-level `sliderStyle` is null. Slider has no public variant
/// enum, so there is no `variantStyles` map.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreSliderTheme.style                       // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance sliderStyle
/// ```
@immutable
class CoreSliderTheme {
  /// Creates a [CoreSliderTheme].
  const CoreSliderTheme({this.style});

  /// Project-level base style. `null` → no project override.
  final CoreSliderStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSliderTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
