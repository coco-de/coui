import 'package:coui_web/src/base/common_style.dart';
import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';

/// A utility class for applying border styles.
///
/// This includes utilities for setting border width, color, style, and radius.
class BorderUtil extends CommonStyle<BorderUtil> {
  const BorderUtil(super.cssClass, {super.modifiers})
    : super(type: StyleType.border);

  // --- Border Width ---
  /// `border-width: 1px`. The most common border.
  static const border = BorderUtil('border');

  /// `border-width: 0px`.
  static const border0 = BorderUtil('border-0');

  /// `border-width: 2px`.
  static const border2 = BorderUtil('border-2');

  /// `border-width: 4px`.
  static const border4 = BorderUtil('border-4');

  /// `border-width: 8px`.
  static const border8 = BorderUtil('border-8');

  // --- Border Color (From DaisyUI Theme) ---
  /// `border-color: primary`.
  static const primary = BorderUtil('border-primary');

  /// `border-color: primary-content`.
  static const primaryContent = BorderUtil('border-primary-content');

  /// `border-color: secondary`.
  static const secondary = BorderUtil('border-secondary');

  /// `border-color: accent`.
  static const accent = BorderUtil('border-accent');

  /// `border-color: neutral`.
  static const neutral = BorderUtil('border-neutral');

  /// `border-color: base-100`.
  static const base100 = BorderUtil('border-base-100');

  /// `border-color: base-200`.
  static const base200 = BorderUtil('border-base-200');

  /// Border color base-300.
  static const base300 = BorderUtil('border-base-300');

  /// `border-color: info`.
  static const info = BorderUtil('border-info');

  /// `border-color: success`.
  static const success = BorderUtil('border-success');

  /// `border-color: warning`.
  static const warning = BorderUtil('border-warning');

  /// `border-color: error`.
  static const error = BorderUtil('border-error');

  // --- Border Style ---
  /// `border-style: solid`.
  static const solid = BorderUtil('border-solid');

  /// `border-style: dashed`.
  static const dashed = BorderUtil('border-dashed');

  /// `border-style: dotted`.
  static const dotted = BorderUtil('border-dotted');

  /// `border-style: double`.
  static const double = BorderUtil('border-double');

  /// `border-style: none`.
  static const none = BorderUtil('border-none');

  @override
  BorderUtil create(List<PrefixModifier> modifiers) {
    return BorderUtil(cssClass, modifiers: modifiers);
  }

  // Note: Border radius is correctly handled by the `Effects` utility
  // (e.g., `Effects.rounded`, `Effects.roundedBox`) as it relates to
  // clipping and visual effects, not just the border property itself.
}
