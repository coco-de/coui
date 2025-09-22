// ignore_for_file: format-comment, no-magic-string, newline-before-method
import 'package:coui_web/src/base/common_style.dart';
import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';

/// Utilities for controlling spacing (margin and padding).
class Spacing extends CommonStyle<Spacing> {
  const Spacing(super.cssClass, {super.modifiers})
    : super(type: StyleType.spacing);

  // --- Margin ---
  /// Margin on all sides. `m-{value}`
  Spacing.m(double value)
    : super('m-${_formatValue(value)}', type: StyleType.spacing);

  /// Margin on x-axis. `mx-{value}`
  Spacing.mx(double value)
    : super('mx-${_formatValue(value)}', type: StyleType.spacing);

  /// Margin on y-axis. `my-{value}`
  Spacing.my(double value)
    : super('my-${_formatValue(value)}', type: StyleType.spacing);

  /// Margin on top. `mt-{value}`
  Spacing.mt(double value)
    : super('mt-${_formatValue(value)}', type: StyleType.spacing);

  /// Margin on right. `mr-{value}` or `me-{value}` (end)
  Spacing.mr(double value)
    : super('mr-${_formatValue(value)}', type: StyleType.spacing);

  Spacing.me(double value)
    : super('me-${_formatValue(value)}', type: StyleType.spacing);

  /// Margin on bottom. `mb-{value}`
  Spacing.mb(double value)
    : super('mb-${_formatValue(value)}', type: StyleType.spacing);

  /// Margin on left. `ml-{value}` or `ms-{value}` (start)
  Spacing.ml(double value)
    : super('ml-${_formatValue(value)}', type: StyleType.spacing);

  Spacing.ms(double value)
    : super('ms-${_formatValue(value)}', type: StyleType.spacing);

  // Predefined spacing values (examples)
  static const m0 = Spacing('m-0');

  static const m1 = Spacing('m-1');

  static const m2 = Spacing('m-2');

  static const m4 = Spacing('m-4');

  static const m6 = Spacing('m-6');

  static const m10 = Spacing('m-10');

  static const p0 = Spacing('p-0');

  static const p1 = Spacing('p-1');

  static const p2 = Spacing('p-2');
  static const p4 = Spacing('p-4');

  static const p6 = Spacing('p-6');

  static const p10 = Spacing('p-10');

  // --- Padding ---
  /// Padding on all sides. `p-{value}`
  static Spacing p(double value) => Spacing('p-${_formatValue(value)}');

  /// Padding on x-axis. `px-{value}`
  static Spacing px(double value) => Spacing('px-${_formatValue(value)}');

  /// Padding on y-axis. `py-{value}`
  static Spacing py(double value) => Spacing('py-${_formatValue(value)}');

  /// Padding on top. `pt-{value}`
  static Spacing pt(double value) => Spacing('pt-${_formatValue(value)}');

  /// Padding on right. `pr-{value}` or `pe-{value}` (end)
  static Spacing pr(double value) => Spacing('pr-${_formatValue(value)}');

  static Spacing pe(double value) => Spacing('pe-${_formatValue(value)}');

  /// Padding on bottom. `pb-{value}`
  static Spacing pb(double value) => Spacing('pb-${_formatValue(value)}');

  /// Padding on left. `pl-{value}` or `ps-{value}` (start)
  static Spacing pl(double value) => Spacing('pl-${_formatValue(value)}');

  static Spacing ps(double value) => Spacing('ps-${_formatValue(value)}');

  @override
  Spacing create(List<PrefixModifier> modifiers) {
    return Spacing(cssClass, modifiers: modifiers);
  }

  // Helper to format value for Tailwind class (e.g., 2.5 -> 2.5, 2.0 -> 2)
  static String _formatValue(double value) {
    return value == value.truncate()
        ? value.truncate().toString()
        : value.toString();
  }
}
