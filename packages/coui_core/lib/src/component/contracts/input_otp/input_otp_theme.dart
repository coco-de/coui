// Theme is effectively immutable (const constructor, final fields), but we
// don't depend on `meta` for the @immutable annotation.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:coui_core/src/component/contracts/input_otp/input_otp_style.dart';
import 'package:coui_core/src/component/contracts/input_otp/input_otp_variant.dart';

/// Project-level theme overrides for OTP input components.
///
/// All chrome / dimensional overrides flow through [style] (project-wide)
/// and [variantStyles] (per-[CoreInputOtpVariant]) — [CoreInputOtpStyle]
/// slots. When both are null the component uses design system defaults.
///
/// `size` is a widget-only semantic identifier — the theme has no per-size
/// slot, because a theme that overrode it would overrule a caller's `size:`.
/// Per-size defaults live in [CoreInputOtpStyle.defaultsBySize], and [style]
/// sits above them: a project-wide `cellSize` sets every size's cell.
///
/// Example:
/// ```dart
/// CoreComponentTheme(
///   inputOtp: CoreInputOtpTheme(
///     style: CoreInputOtpStyle(
///       cellSize: 40,
///       cellSpacing: 8,
///     ),
///     variantStyles: {
///       CoreInputOtpVariant.error: CoreInputOtpStyle(
///         borderColor: CoreColor.token(CoreColors.error),
///       ),
///     },
///   ),
/// )
/// ```
class CoreInputOtpTheme {
  /// Creates a [CoreInputOtpTheme].
  const CoreInputOtpTheme({this.style, this.variantStyles});

  /// Project-wide composite style applied to every `InputOtp`.
  ///
  /// Resolved before any per-instance `widget.inputOtpStyle`.
  final CoreInputOtpStyle? style;

  /// Per-[CoreInputOtpVariant] project-wide overrides (e.g. re-theming
  /// the `error` variant's border colour). Resolved after [style] and
  /// before any per-instance `widget.inputOtpStyle`.
  final Map<CoreInputOtpVariant, CoreInputOtpStyle>? variantStyles;

  @override
  bool operator ==(Object other) {
    return other is CoreInputOtpTheme &&
        other.style == style &&
        _mapEquals(other.variantStyles, variantStyles);
  }

  @override
  int get hashCode => Object.hash(
    style,
    variantStyles == null
        ? null
        : Object.hashAllUnordered(
            variantStyles!.entries.map((e) => Object.hash(e.key, e.value)),
          ),
  );

  static bool _mapEquals(
    Map<CoreInputOtpVariant, CoreInputOtpStyle>? a,
    Map<CoreInputOtpVariant, CoreInputOtpStyle>? b,
  ) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
