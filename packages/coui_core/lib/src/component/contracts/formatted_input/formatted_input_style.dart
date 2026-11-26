/// Per-instance style for `FormattedInput`.
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
import 'package:meta/meta.dart';

/// Immutable style describing how a `FormattedInput` should render.
///
/// `CoreFormattedInputStyle` carries chrome / dimensional flat fields
/// for the segmented input container. Behavioural / semantic fields
/// (`parts`, `value`, `enabled`, `onChanged`, `leading`, `trailing`)
/// stay flat on the widget / contract.
///
/// ```text
/// design system default
///   → CoreFormattedInputTheme.style               // 프로젝트 공통
///   → parent component slot override
///   → widget.formattedInputStyle                  // 인스턴스별
/// ```
@immutable
class CoreFormattedInputStyle implements CoreStyle<CoreFormattedInputStyle> {
  /// Creates a [CoreFormattedInputStyle].
  const CoreFormattedInputStyle({
    this.backgroundColor,
    this.borderColor,
    this.hoverBorderColor,
    this.disabledBackgroundColor,
    this.disabledBorderColor,
    this.disabledForegroundColor,
    this.focusBorderColor,
    this.borderRadius,
    this.borderWidth,
    this.padding,
    this.height,
    this.contentSpacing,
    this.segmentInputStyle,
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
  /// (the same hover step the text field takes). A focused container keeps
  /// [defaultFocusBorderColor] and a disabled one has no hover step.
  static const CoreColor defaultHoverBorderColor = CoreColor.token(
    CoreColors.outline,
  );

  /// Default disabled container background colour token.
  static const CoreColor defaultDisabledBackgroundColor = CoreColor.token(
    CoreColors.disabledContainer,
  );

  /// Default disabled container border colour token.
  static const CoreColor defaultDisabledBorderColor = CoreColor.token(
    CoreColors.disabledOutline,
  );

  /// Default text colour token — value and placeholder — while disabled:
  /// `disabledContent`, the token the text field's own disabled value and
  /// placeholder take, so a disabled mask reads disabled whether or not it
  /// holds text.
  static const CoreColor defaultDisabledForegroundColor = CoreColor.token(
    CoreColors.disabledContent,
  );

  /// Default container focus-ring border colour token.
  static const CoreColor defaultFocusBorderColor = CoreColor.token(
    CoreColors.primary,
  );

  /// Default placeholder / padding-character colour token.
  static const CoreColor defaultPlaceholderColor = CoreColor.token(
    CoreColors.placeholder,
  );

  /// Default editable-segment text style — the `codeMd` role (13 / 21px
  /// line / tracking 0, monospace). Fixed-width segments take a code role
  /// rather than a mono family over a body role, so the glyphs sit on the
  /// code grid instead of carrying the body role's negative tracking.
  /// Token-backed single source for both platforms; feeds
  /// [defaultSegmentInputStyle]'s value.
  static const CoreTextStyle defaultSegmentTextStyle = CoreTextStyle.token(
    CoreTextStyles.codeMd,
  );

  /// Default editable-segment placeholder text style — the `bodySmall` role
  /// (13px). The mask pattern in the empty field is a hint, not a value on
  /// the code grid, so it takes the body face. No colour is stated here: the
  /// composed field's own variant supplies `placeholder` while enabled and
  /// `disabledContent` while disabled (a stated colour would win in every
  /// state).
  static const CoreTextStyle defaultSegmentPlaceholderTextStyle =
      CoreTextStyle.token(CoreTextStyles.bodySmall);

  /// Variant of the composed `TextField` — `plain`: no box of its own, the
  /// outer container draws the single border / fill / focus boundary.
  static const CoreTextFieldVariant defaultSegmentInputVariant =
      CoreTextFieldVariant.plain;

  /// Size row of the composed `TextField` — `lg`, the row the container's
  /// own height ([defaultHeight]) is cut from.
  static const CoreComponentSize defaultSegmentInputSize = CoreComponentSize.lg;

  /// Default editable-segment `TextField` style — the `plain` variant draws
  /// no border or fill, so what remains is the line it types on: no border
  /// width, no padding, no height floor (the outer frame is the box and sets
  /// the row height), centred, with the code-role value and the body-role
  /// placeholder. Flutter composes one unified `TextField` for the editable
  /// text and Web one native `<input>`; both read this (merged with the
  /// instance [segmentInputStyle]) so its typography / chrome chain from one
  /// Core source instead of being synthesised per platform.
  static const CoreTextFieldStyle defaultSegmentInputStyle = CoreTextFieldStyle(
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
    // The outer container draws the focus boundary, so the per-segment
    // focus ring is suppressed — otherwise every segment grows its own
    // ring on focus inside the already-focused container. Both ring
    // layers are stated transparent: `offsetColor` paints the gap layer,
    // and any opaque gap here renders a faint halo that pulses with the
    // focus transition.
    focusOutlineStyle: CoreFocusOutlineStyle(
      borderColor: .transparent,
      borderWidth: 0,
      offsetColor: .transparent,
    ),
    placeholderStyle: defaultSegmentPlaceholderTextStyle,
    valueStyle: defaultSegmentTextStyle,
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

  /// Default gap between the `leading` / field / `trailing` children.
  static const double defaultContentSpacing = CoreSpace.space8;

  /// Container background colour override.
  final CoreColor? backgroundColor;

  /// Container border colour override.
  final CoreColor? borderColor;

  /// Container border colour override while the pointer is over the
  /// container. `null` → [defaultHoverBorderColor]. Never applied while the
  /// container is focused (the focus border wins) or disabled.
  final CoreColor? hoverBorderColor;

  /// Container background colour while the field is disabled. `null` uses
  /// [defaultDisabledBackgroundColor].
  ///
  /// A token rather than an opacity over the enabled fill. An alpha is not
  /// a forced value in a colour-forcing accessibility mode — the colour is
  /// substituted and the alpha survives — so a disabled field dimmed by
  /// opacity reads as enabled there. See `theme-axis-composition.md`'s
  /// "상태 구분도 색만으로 하지 않는다" corollary.
  final CoreColor? disabledBackgroundColor;

  /// Container border colour while the field is disabled. `null` uses
  /// [defaultDisabledBorderColor].
  ///
  /// Both disabled-colour fields on this class landed in #4505, whose
  /// `BREAKING CHANGE:` footer for this addition was one of several
  /// squashed into a single commit and dropped by the release tooling
  /// (only the first footer is read). The restatement in #4616 was
  /// itself squash-merged with four sibling footers and lost the same
  /// way (`ea3efc985`) — this is the second restatement, on its own
  /// commit, not squashed with anything else. They are `==`/`hashCode`
  /// participants like every field here, so a cache or snapshot keyed on
  /// style equality recomputes.
  final CoreColor? disabledBorderColor;

  /// Value / placeholder text colour while the field is disabled.
  /// `null` → [defaultDisabledForegroundColor].
  final CoreColor? disabledForegroundColor;

  /// Container focus-ring border colour override.
  final CoreColor? focusBorderColor;

  /// Container border radius override.
  final CoreBorderRadius? borderRadius;

  /// Container border width override (logical px).
  final double? borderWidth;

  /// Container padding override.
  final CoreEdgeInsets? padding;

  /// Container height override (logical px). `null` → [defaultHeight],
  /// which moves with the density; a stated height stays as stated.
  final double? height;

  /// Gap between the `leading` / field / `trailing` children override
  /// (logical px). `null` → [defaultContentSpacing].
  final double? contentSpacing;

  /// Style for the `TextField` the segments are typed into — its look plus
  /// the value / placeholder text. Laid over [defaultSegmentInputStyle] and
  /// passed to that one `TextField` on both platforms.
  final CoreTextFieldStyle? segmentInputStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreFormattedInputStyle merge(CoreFormattedInputStyle? other) {
    if (other == null) return this;
    return CoreFormattedInputStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      hoverBorderColor: other.hoverBorderColor ?? hoverBorderColor,
      disabledBackgroundColor:
          other.disabledBackgroundColor ?? disabledBackgroundColor,
      disabledBorderColor: other.disabledBorderColor ?? disabledBorderColor,
      disabledForegroundColor:
          other.disabledForegroundColor ?? disabledForegroundColor,
      focusBorderColor: other.focusBorderColor ?? focusBorderColor,
      borderRadius: other.borderRadius ?? borderRadius,
      borderWidth: other.borderWidth ?? borderWidth,
      padding: other.padding ?? padding,
      height: other.height ?? height,
      contentSpacing: other.contentSpacing ?? contentSpacing,
      segmentInputStyle:
          segmentInputStyle?.merge(other.segmentInputStyle) ??
          other.segmentInputStyle,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreFormattedInputStyle copyWith({
    CoreColor? backgroundColor,
    CoreColor? borderColor,
    CoreColor? hoverBorderColor,
    CoreColor? disabledBackgroundColor,
    CoreColor? disabledBorderColor,
    CoreColor? disabledForegroundColor,
    CoreColor? focusBorderColor,
    CoreBorderRadius? borderRadius,
    double? borderWidth,
    CoreEdgeInsets? padding,
    double? height,
    double? contentSpacing,
    CoreTextFieldStyle? segmentInputStyle,
  }) {
    return CoreFormattedInputStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
      disabledBackgroundColor:
          disabledBackgroundColor ?? this.disabledBackgroundColor,
      disabledBorderColor: disabledBorderColor ?? this.disabledBorderColor,
      disabledForegroundColor:
          disabledForegroundColor ?? this.disabledForegroundColor,
      focusBorderColor: focusBorderColor ?? this.focusBorderColor,
      borderRadius: borderRadius ?? this.borderRadius,
      borderWidth: borderWidth ?? this.borderWidth,
      padding: padding ?? this.padding,
      height: height ?? this.height,
      contentSpacing: contentSpacing ?? this.contentSpacing,
      segmentInputStyle: segmentInputStyle ?? this.segmentInputStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreFormattedInputStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          borderColor == other.borderColor &&
          hoverBorderColor == other.hoverBorderColor &&
          disabledBackgroundColor == other.disabledBackgroundColor &&
          disabledBorderColor == other.disabledBorderColor &&
          disabledForegroundColor == other.disabledForegroundColor &&
          focusBorderColor == other.focusBorderColor &&
          borderRadius == other.borderRadius &&
          borderWidth == other.borderWidth &&
          padding == other.padding &&
          height == other.height &&
          contentSpacing == other.contentSpacing &&
          segmentInputStyle == other.segmentInputStyle;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    borderColor,
    hoverBorderColor,
    disabledBackgroundColor,
    disabledBorderColor,
    disabledForegroundColor,
    focusBorderColor,
    borderRadius,
    borderWidth,
    padding,
    height,
    contentSpacing,
    segmentInputStyle,
  );
}
