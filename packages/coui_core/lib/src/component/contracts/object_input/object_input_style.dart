/// Per-instance style for `ObjectInput`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/focus_outline/focus_outline_style.dart';
import 'package:coui_core/src/component/contracts/text_field/text_field_style.dart';
import 'package:coui_core/src/component/contracts/text_field/text_field_variant.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/component_size.dart';
import 'package:coui_core/src/size/control_size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:coui_core/src/typography/typography_scale.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `ObjectInput` should render.
///
/// `CoreObjectInputStyle` carries chrome / dimensional flat fields for
/// the key-value field container. Behavioural / semantic fields
/// (`fields`, `values`, `separator`, `enabled`, `onChanged`, `leading`,
/// `trailing`) stay flat on the widget / contract.
///
/// ```text
/// design system default
///   → CoreObjectInputTheme.style                  // 프로젝트 공통
///   → parent component slot override
///   → widget.objectInputStyle                     // 인스턴스별
/// ```
@immutable
class CoreObjectInputStyle implements CoreStyle<CoreObjectInputStyle> {
  /// Creates a [CoreObjectInputStyle].
  const CoreObjectInputStyle({
    this.backgroundColor,
    this.borderColor,
    this.hoverBorderColor,
    this.focusBorderColor,
    this.disabledBackgroundColor,
    this.disabledBorderColor,
    this.disabledSeparatorColor,
    this.borderRadius,
    this.borderWidth,
    this.padding,
    this.height,
    this.fieldSpacing,
    this.separatorTextStyle,
    this.fieldInputStyle,
    this.shortFieldMaxWidth,
    this.mediumFieldMaxWidth,
    this.longFieldMaxWidth,
    this.separatorPadding,
    this.charWidth,
  });

  // ─── Design-system defaults ────────────────────

  /// Default container background colour token.
  static const CoreColor defaultBackgroundColor = CoreColor.token(
    CoreColors.surface,
  );

  /// Default container border colour token — `outlineVariant`, the resting
  /// edge the text field takes (#5747): a form of several fields reads as a
  /// page of lines when every resting edge is `outline`, so the edge rests
  /// one tone quieter and only the field under the pointer lifts.
  static const CoreColor defaultBorderColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default container border colour token while the pointer is over the
  /// container — `outline`, one step past the resting [defaultBorderColor]
  /// (the same hover step the single-line text field takes). A focused
  /// container keeps [defaultFocusBorderColor] and a disabled one has no
  /// hover step.
  static const CoreColor defaultHoverBorderColor = CoreColor.token(
    CoreColors.outline,
  );

  /// Default container background colour token while disabled —
  /// `disabledContainer`. A token rather than an opacity over the enabled
  /// fill: an alpha is not a forced value in a colour-forcing accessibility
  /// mode, so a field dimmed by opacity reads as enabled there.
  static const CoreColor defaultDisabledBackgroundColor = CoreColor.token(
    CoreColors.disabledContainer,
  );

  /// Default container border colour token while disabled —
  /// `disabledOutline`. It also holds in a disabled field that kept focus:
  /// a field that cannot be edited does not claim the focus ring.
  static const CoreColor defaultDisabledBorderColor = CoreColor.token(
    CoreColors.disabledOutline,
  );

  /// Default field separator text colour token while disabled —
  /// `disabledContent`, the token the fields' own disabled value and
  /// placeholder take.
  static const CoreColor defaultDisabledSeparatorColor = CoreColor.token(
    CoreColors.disabledContent,
  );

  /// Default container focus-ring border colour token.
  static const CoreColor defaultFocusBorderColor = CoreColor.token(
    CoreColors.primary,
  );

  /// Default field separator text colour token — `onSurfaceSubtle`, the
  /// quiet tone the text field's affixes take.
  static const CoreColor defaultSeparatorColor = CoreColor.token(
    CoreColors.onSurfaceSubtle,
  );

  /// Default field placeholder colour token.
  @Deprecated(
    'Nothing reads it (since 0.177) — the field composes TextField, '
    'whose placeholder colour applies; state it on fieldInputStyle.',
  )
  static const CoreColor defaultPlaceholderColor = CoreColor.token(
    CoreColors.placeholder,
  );

  /// Default field separator typography role — `CoreTypography.coui.bodySmall`.
  /// `static final` since record/class field access can't be const-eval'd;
  /// `CoreTypography.coui` itself is const so no runtime cost.
  static final CoreTextStyle defaultSeparatorTypography =
      CoreTypography.coui.bodySmall;

  /// Default field separator text style — combines the typography role
  /// token ([CoreTextStyles.bodySmall]) and [defaultSeparatorColor] into
  /// one [CoreTextStyle] so the Web resolver can drive the separator's
  /// token / colour classes from the single [separatorTextStyle] nested
  /// slot. Mirrors `CoreCheckboxStyle.defaultLabelStyle`.
  static const CoreTextStyle defaultSeparatorTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodySmall,
    color: defaultSeparatorColor,
  );

  /// Default per-field text style — the `codeMd` role (13 / 21px line /
  /// tracking 0, monospace), so structured field values render identical
  /// fixed-width glyphs on both platforms on the code grid rather than a
  /// mono family over a body role. Feeds [defaultFieldInputStyle]'s value.
  static const CoreTextStyle defaultFieldTextStyle = CoreTextStyle.token(
    CoreTextStyles.codeMd,
  );

  /// Default per-field placeholder text style — the `bodyLarge` role (15px).
  /// The hint (`00`, `0000`) is not a value on the code grid, so it takes
  /// the body face. No colour is stated here: the composed field's own
  /// variant supplies `placeholder` while enabled and `disabledContent`
  /// while disabled (a stated colour would win in every state).
  static const CoreTextStyle defaultFieldPlaceholderTextStyle =
      CoreTextStyle.token(CoreTextStyles.bodyLarge);

  /// Variant of the composed per-field `TextField` — `plain`: no box of its
  /// own, the outer container draws the single border / fill / focus
  /// boundary.
  static const CoreTextFieldVariant defaultFieldInputVariant =
      CoreTextFieldVariant.plain;

  /// Size row of the composed per-field `TextField` — `lg`, the row the
  /// container's own height ([defaultHeight]) is cut from.
  static const CoreComponentSize defaultFieldInputSize = CoreComponentSize.lg;

  /// Default per-field `TextField` style — the `plain` variant draws no
  /// border or fill, so what remains is the line it types on: no border
  /// width, no padding, no height floor (the outer frame is the box and sets
  /// the row height), centred, with the code-role value and the body-role
  /// placeholder. Both platforms compose a unified `TextField` per field and
  /// forward this (merged with the instance [fieldInputStyle]) so field
  /// typography / chrome chain from one Core source instead of being
  /// synthesised per platform.
  static const CoreTextFieldStyle defaultFieldInputStyle = CoreTextFieldStyle(
    // The `plain` variant is transparent at rest but takes the disabled
    // container fill when disabled; the outer container already paints that
    // fill, so the field states none of its own in any state.
    backgroundColor: .transparent,
    // A plain field's border is transparent but still has width: zero it so
    // the line does not carry a hairline inside the container.
    borderWidth: 0,
    padding: .zero,
    minHeight: 0,
    textAlign: .center,
    // The outer container draws the focus boundary — suppress the
    // per-field focus ring (both ring layers, gap included, stay
    // transparent or a faint halo pulses with the focus transition).
    focusOutlineStyle: CoreFocusOutlineStyle(
      borderColor: .transparent,
      borderWidth: 0,
      offsetColor: .transparent,
    ),
    placeholderStyle: defaultFieldPlaceholderTextStyle,
    valueStyle: defaultFieldTextStyle,
  );

  /// Default container border radius — `radius12`, the corner the text
  /// field's lg row takes (height × 0.25 of the 48 row), so the container
  /// sits beside a text field as one family.
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius12,
  );

  /// Default container border width (logical px).
  static const double defaultBorderWidth = CoreStrokeWidth.stroke1;

  /// Default container padding — the text field's lg-row inset (14 sides);
  /// the vertical inset is zero because the row height ([defaultHeight])
  /// centres the line, not padding.
  static const CoreEdgeInsets defaultPadding = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space14,
  );

  /// Default container height — the lg row of the control ladder
  /// ([CoreControlSize.heightLg]), the row of the text field it sits beside.
  /// A caller's own [height] stays as stated under every density; only this
  /// default row moves.
  static const double defaultHeight = CoreControlSize.heightLg;

  /// Default gap between the container's children (`leading`, fields and
  /// separators, `trailing`).
  static const double defaultFieldSpacing = CoreSpace.space4;

  /// Default padding around the field separator text.
  static const CoreEdgeInsets defaultSeparatorPadding =
      CoreEdgeInsets.symmetric(horizontal: CoreSpace.space2);

  /// Default per-character field width (logical px).
  static const double defaultCharWidth = CoreSpace.space12;

  /// Default max-width for short fields (1–2 chars).
  static const double defaultShortFieldMaxWidth = CoreSpace.space28;

  /// Default max-width for medium fields (3–4 chars).
  static const double defaultMediumFieldMaxWidth = CoreSpace.space28;

  /// Default max-width for long fields (5+ chars).
  static const double defaultLongFieldMaxWidth = CoreSpace.space48;

  /// Container background colour override.
  final CoreColor? backgroundColor;

  /// Container border colour override.
  final CoreColor? borderColor;

  /// Container border colour override while the pointer is over the
  /// container. `null` → [defaultHoverBorderColor]. Never applied while the
  /// container is focused (the focus border wins) or disabled.
  final CoreColor? hoverBorderColor;

  /// Container focus-ring border colour override.
  final CoreColor? focusBorderColor;

  /// Container background colour override while disabled.
  /// `null` → [defaultDisabledBackgroundColor].
  final CoreColor? disabledBackgroundColor;

  /// Container border colour override while disabled.
  /// `null` → [defaultDisabledBorderColor].
  final CoreColor? disabledBorderColor;

  /// Field separator text colour override while disabled.
  /// `null` → [defaultDisabledSeparatorColor].
  final CoreColor? disabledSeparatorColor;

  /// Container border radius override.
  final CoreBorderRadius? borderRadius;

  /// Container border width override (logical px).
  final double? borderWidth;

  /// Container padding override.
  final CoreEdgeInsets? padding;

  /// Container height override (logical px). `null` → [defaultHeight],
  /// which moves with the density; a stated height stays as stated.
  final double? height;

  /// Gap between the container's children override (logical px).
  /// `null` → [defaultFieldSpacing].
  final double? fieldSpacing;

  /// Field separator text style override (typography role / font / colour).
  final CoreTextStyle? separatorTextStyle;

  /// Style override for each field's `TextField` — its look plus the value
  /// and placeholder typography. Passed to every field's `TextField` on
  /// both platforms.
  final CoreTextFieldStyle? fieldInputStyle;

  /// Max-width override for short fields (1–2 chars) (logical px).
  final double? shortFieldMaxWidth;

  /// Max-width override for medium fields (3–4 chars) (logical px).
  final double? mediumFieldMaxWidth;

  /// Max-width override for long fields (5+ chars) (logical px).
  final double? longFieldMaxWidth;

  /// Custom padding around the field separator glyph (pre-scaling).
  /// `null` → [defaultSeparatorPadding].
  final CoreEdgeInsets? separatorPadding;

  /// Per-character width used to size a field to its `maxChars` bucket
  /// (logical px, pre-scaling). `null` → [defaultCharWidth].
  final double? charWidth;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreObjectInputStyle merge(CoreObjectInputStyle? other) {
    if (other == null) return this;
    return CoreObjectInputStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      hoverBorderColor: other.hoverBorderColor ?? hoverBorderColor,
      focusBorderColor: other.focusBorderColor ?? focusBorderColor,
      disabledBackgroundColor:
          other.disabledBackgroundColor ?? disabledBackgroundColor,
      disabledBorderColor: other.disabledBorderColor ?? disabledBorderColor,
      disabledSeparatorColor:
          other.disabledSeparatorColor ?? disabledSeparatorColor,
      borderRadius: other.borderRadius ?? borderRadius,
      borderWidth: other.borderWidth ?? borderWidth,
      padding: other.padding ?? padding,
      height: other.height ?? height,
      fieldSpacing: other.fieldSpacing ?? fieldSpacing,
      separatorTextStyle: _mergeText(
        separatorTextStyle,
        other.separatorTextStyle,
      ),
      fieldInputStyle:
          fieldInputStyle?.merge(other.fieldInputStyle) ??
          other.fieldInputStyle,
      shortFieldMaxWidth: other.shortFieldMaxWidth ?? shortFieldMaxWidth,
      mediumFieldMaxWidth: other.mediumFieldMaxWidth ?? mediumFieldMaxWidth,
      longFieldMaxWidth: other.longFieldMaxWidth ?? longFieldMaxWidth,
      separatorPadding: other.separatorPadding ?? separatorPadding,
      charWidth: other.charWidth ?? charWidth,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreObjectInputStyle copyWith({
    CoreColor? backgroundColor,
    CoreColor? borderColor,
    CoreColor? hoverBorderColor,
    CoreColor? focusBorderColor,
    CoreColor? disabledBackgroundColor,
    CoreColor? disabledBorderColor,
    CoreColor? disabledSeparatorColor,
    CoreBorderRadius? borderRadius,
    double? borderWidth,
    CoreEdgeInsets? padding,
    double? height,
    double? fieldSpacing,
    CoreTextStyle? separatorTextStyle,
    CoreTextFieldStyle? fieldInputStyle,
    double? shortFieldMaxWidth,
    double? mediumFieldMaxWidth,
    double? longFieldMaxWidth,
    CoreEdgeInsets? separatorPadding,
    double? charWidth,
  }) {
    return CoreObjectInputStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
      focusBorderColor: focusBorderColor ?? this.focusBorderColor,
      disabledBackgroundColor:
          disabledBackgroundColor ?? this.disabledBackgroundColor,
      disabledBorderColor: disabledBorderColor ?? this.disabledBorderColor,
      disabledSeparatorColor:
          disabledSeparatorColor ?? this.disabledSeparatorColor,
      borderRadius: borderRadius ?? this.borderRadius,
      borderWidth: borderWidth ?? this.borderWidth,
      padding: padding ?? this.padding,
      height: height ?? this.height,
      fieldSpacing: fieldSpacing ?? this.fieldSpacing,
      separatorTextStyle: separatorTextStyle ?? this.separatorTextStyle,
      fieldInputStyle: fieldInputStyle ?? this.fieldInputStyle,
      shortFieldMaxWidth: shortFieldMaxWidth ?? this.shortFieldMaxWidth,
      mediumFieldMaxWidth: mediumFieldMaxWidth ?? this.mediumFieldMaxWidth,
      longFieldMaxWidth: longFieldMaxWidth ?? this.longFieldMaxWidth,
      separatorPadding: separatorPadding ?? this.separatorPadding,
      charWidth: charWidth ?? this.charWidth,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreObjectInputStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          borderColor == other.borderColor &&
          hoverBorderColor == other.hoverBorderColor &&
          focusBorderColor == other.focusBorderColor &&
          disabledBackgroundColor == other.disabledBackgroundColor &&
          disabledBorderColor == other.disabledBorderColor &&
          disabledSeparatorColor == other.disabledSeparatorColor &&
          borderRadius == other.borderRadius &&
          borderWidth == other.borderWidth &&
          padding == other.padding &&
          height == other.height &&
          fieldSpacing == other.fieldSpacing &&
          separatorTextStyle == other.separatorTextStyle &&
          fieldInputStyle == other.fieldInputStyle &&
          shortFieldMaxWidth == other.shortFieldMaxWidth &&
          mediumFieldMaxWidth == other.mediumFieldMaxWidth &&
          longFieldMaxWidth == other.longFieldMaxWidth &&
          separatorPadding == other.separatorPadding &&
          charWidth == other.charWidth;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    borderColor,
    hoverBorderColor,
    focusBorderColor,
    disabledBackgroundColor,
    disabledBorderColor,
    disabledSeparatorColor,
    borderRadius,
    borderWidth,
    padding,
    height,
    fieldSpacing,
    separatorTextStyle,
    fieldInputStyle,
    shortFieldMaxWidth,
    mediumFieldMaxWidth,
    longFieldMaxWidth,
    Object.hash(separatorPadding, charWidth),
  );

  /// Merges two optional [CoreTextStyle] slots — `other` wins per field,
  /// `base` inherited. Returns `null` only when both are `null`.
  static CoreTextStyle? _mergeText(CoreTextStyle? base, CoreTextStyle? other) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
