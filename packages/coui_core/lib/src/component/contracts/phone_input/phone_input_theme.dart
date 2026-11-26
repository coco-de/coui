// Theme is effectively immutable (const constructor, final fields), but we
// don't depend on `meta` for the @immutable annotation.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:coui_core/src/component/contracts/phone_input/phone_input_style.dart';

/// Project-level theme overrides for phone input components.
///
/// All chrome / dimensional overrides flow through the single [style]
/// slot ([CorePhoneInputStyle]). When [style] is null the component
/// uses design system defaults.
///
/// Example:
/// ```dart
/// CoreComponentTheme(
///   phoneInput: CorePhoneInputTheme(
///     style: CorePhoneInputStyle(
///       borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
///       flagGap: 8.0,
///     ),
///   ),
/// )
/// ```
class CorePhoneInputTheme {
  /// Creates a [CorePhoneInputTheme].
  const CorePhoneInputTheme({this.style});

  /// Project-wide composite style applied to every `PhoneInput`.
  ///
  /// Resolved before any per-instance `widget.phoneInputStyle`.
  final CorePhoneInputStyle? style;

  @override
  bool operator ==(Object other) {
    return other is CorePhoneInputTheme && other.style == style;
  }

  @override
  int get hashCode => style.hashCode;
}
