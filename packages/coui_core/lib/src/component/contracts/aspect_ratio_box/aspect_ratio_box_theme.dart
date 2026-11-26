/// Platform-independent theme overrides for `AspectRatioBox`.
///
/// `AspectRatioBox` has no chrome (background / border / padding) —
/// it is a pure layout primitive. The theme therefore exposes a
/// single `style` slot whose [CoreAspectRatioBoxStyle.defaultRatio]
/// supplies the fallback ratio applied when the widget receives a
/// non-positive value. Kept in parity with Flutter and Web
/// implementations.
library;

import 'package:coui_core/src/component/contracts/aspect_ratio_box/aspect_ratio_box_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `AspectRatioBox`.
///
/// Follows the standard CoUI `CoreXxxTheme { style: CoreXxxStyle? }`
/// shape — all knobs live on [CoreAspectRatioBoxStyle], the theme
/// just exposes a single slot.
@immutable
class CoreAspectRatioBoxTheme {
  /// Creates a [CoreAspectRatioBoxTheme].
  const CoreAspectRatioBoxTheme({this.style});

  /// Style overrides applied to every `AspectRatioBox` rendered
  /// under this theme.
  final CoreAspectRatioBoxStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreAspectRatioBoxTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
