/// Per-instance style for `NumberInput`.
library;

import 'package:coui_core/src/component/contracts/button/button_style.dart';
import 'package:coui_core/src/component/contracts/number_input/number_input_size.dart';
import 'package:coui_core/src/component/contracts/text_field/text_field_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/control_size.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_align.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `NumberInput` renders.
///
/// A `NumberInput` is a composed `TextField` with a `Button` at each end, so
/// its chrome is two nested slots — [fieldStyle] for the `TextField`
/// (forwarded raw; the field owns border, fill, hover, focus and error) and
/// [buttonStyle] for the two step buttons — plus the one dimension the
/// composition adds: the field's [width]. Which `Button` size step the ends
/// take follows the field's size and is stated once, in
/// `CoreNumberInputSize.toStepButtonSize`.
///
/// ```text
/// design system default
///   → defaultsBySize[size]
///   → CoreNumberInputTheme.style
///   → CoreNumberInputTheme.variantStyles[variant]
///   → widget.numberInputStyle
/// ```
@immutable
class CoreNumberInputStyle implements CoreStyle<CoreNumberInputStyle> {
  /// Creates a [CoreNumberInputStyle].
  const CoreNumberInputStyle({
    this.width,
    this.buttonStyle,
    this.fieldStyle,
  });

  // ─── Design-system defaults ────────────────────

  /// The gap between the field's border and the step buttons.
  static const double defaultInset = CoreSpace.space4;

  /// The field's border width — the `TextField` default, stated here because
  /// the field's [width] counts it.
  static const double defaultBorderWidth = CoreStrokeWidth.stroke1;

  /// The width of the value between the two buttons, per size step.
  static const double _smValueWidth = CoreSize.size32;
  static const double _mdValueWidth = CoreSize.size40;
  static const double _lgValueWidth = CoreSize.size48;

  /// A field's width: border + inset + button + value + button + inset +
  /// border. Derived from the parts it is made of, so the three steps stay
  /// 90 · 114 · 138 only while those parts do.
  static double _widthOf(double valueWidth, double buttonExtent) =>
      2 * defaultBorderWidth + 2 * defaultInset + 2 * buttonExtent + valueWidth;

  /// The composed `TextField`'s style: the buttons sit [defaultInset] from
  /// the border with no gap between button and value, and the value is
  /// centred in the `bodyMedium` role (Regular 14 · 150%) — the body text
  /// every other input value reads in, so the value is not the one cell in a
  /// form that reads emphasised. The caret is that line box tall (21).
  ///
  /// Horizontally the inset is measured inside the border, so the width adds
  /// the border to it. Vertically the field's own height is fixed by the size
  /// step and the buttons are centred in it, so the padding is only what is
  /// left between button and border: the inset less the border.
  static const CoreTextFieldStyle defaultFieldStyle = CoreTextFieldStyle(
    padding: CoreEdgeInsets.symmetric(
      horizontal: defaultInset,
      vertical: defaultInset - defaultBorderWidth,
    ),
    rowSpacing: 0,
    textAlign: CoreTextAlign.center,
    valueStyle: CoreTextStyle.token(CoreTextStyles.bodyMedium),
  );

  /// The step buttons' own style. Nothing is restated: the buttons are
  /// `plain` · `square` and take the chrome of that variant at their size.
  static const CoreButtonStyle defaultButtonStyle = CoreButtonStyle();

  /// Size rows. The width counts the buttons the field's height carries: a
  /// 32 field carries 24 buttons, a 40 field 32, a 48 field 40.
  static const Map<CoreNumberInputSize, CoreNumberInputStyle> defaultsBySize = {
    CoreNumberInputSize.sm: CoreNumberInputStyle(
      width:
          2 * defaultBorderWidth +
          2 * defaultInset +
          2 * CoreControlSize.heightXs +
          _smValueWidth,
    ),
    CoreNumberInputSize.md: CoreNumberInputStyle(
      width:
          2 * defaultBorderWidth +
          2 * defaultInset +
          2 * CoreControlSize.heightSm +
          _mdValueWidth,
    ),
    CoreNumberInputSize.lg: CoreNumberInputStyle(
      width:
          2 * defaultBorderWidth +
          2 * defaultInset +
          2 * CoreControlSize.heightMd +
          _lgValueWidth,
    ),
  };

  /// The width of a field at [size]'s step, derived the same way as the
  /// rows in [defaultsBySize]. Exposed so a test can pin the two together.
  static double widthAt(CoreNumberInputSize size) => switch (size) {
    CoreNumberInputSize.sm => _widthOf(_smValueWidth, CoreControlSize.heightXs),
    CoreNumberInputSize.md => _widthOf(_mdValueWidth, CoreControlSize.heightSm),
    CoreNumberInputSize.lg => _widthOf(_lgValueWidth, CoreControlSize.heightMd),
  };

  /// The whole field's width (logical px), border to border. `null` → the
  /// size row's width.
  final double? width;

  /// Style for the two step buttons, passed to each `Button` as is.
  final CoreButtonStyle? buttonStyle;

  /// Style for the `TextField` inside, passed to it as is.
  final CoreTextFieldStyle? fieldStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreNumberInputStyle merge(CoreNumberInputStyle? other) {
    if (other == null) return this;
    return CoreNumberInputStyle(
      width: other.width ?? width,
      buttonStyle: buttonStyle?.merge(other.buttonStyle) ?? other.buttonStyle,
      fieldStyle: fieldStyle?.merge(other.fieldStyle) ?? other.fieldStyle,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreNumberInputStyle copyWith({
    double? width,
    CoreButtonStyle? buttonStyle,
    CoreTextFieldStyle? fieldStyle,
  }) {
    return CoreNumberInputStyle(
      width: width ?? this.width,
      buttonStyle: buttonStyle ?? this.buttonStyle,
      fieldStyle: fieldStyle ?? this.fieldStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreNumberInputStyle &&
          runtimeType == other.runtimeType &&
          width == other.width &&
          buttonStyle == other.buttonStyle &&
          fieldStyle == other.fieldStyle;

  @override
  int get hashCode => Object.hash(width, buttonStyle, fieldStyle);
}
