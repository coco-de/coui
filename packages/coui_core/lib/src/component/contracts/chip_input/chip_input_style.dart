/// Per-instance style for `ChipInput`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/button/button_style.dart';
import 'package:coui_core/src/component/contracts/chip/chip_size.dart';
import 'package:coui_core/src/component/contracts/chip/chip_style.dart';
import 'package:coui_core/src/component/contracts/chip/chip_variant.dart';
import 'package:coui_core/src/component/contracts/chip/core_chip_emphasis.dart';
import 'package:coui_core/src/component/contracts/focus_outline/focus_outline_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/contracts/text_field/text_field_style.dart';
import 'package:coui_core/src/component/contracts/text_field/text_field_variant.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/effect/state_layer.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/control_size.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `ChipInput` should render.
///
/// `CoreChipInputStyle` carries chrome / dimensional flat fields for the
/// outer field container and the inner chip badges. Behavioural /
/// semantic fields (`chips`, `placeholder`, `enabled`, `maxChips`,
/// callbacks) stay flat on the widget / contract.
///
/// ```text
/// design system default
///   → CoreChipInputTheme.style                   // 프로젝트 공통
///   → parent component slot override
///   → widget.chipInputStyle                      // 인스턴스별
/// ```
@immutable
class CoreChipInputStyle implements CoreStyle<CoreChipInputStyle> {
  /// Creates a [CoreChipInputStyle].
  const CoreChipInputStyle({
    this.backgroundColor,
    this.borderColor,
    this.hoverBorderColor,
    this.disabledBackgroundColor,
    this.disabledBorderColor,
    this.borderWidth,
    this.borderRadius,
    this.minHeight,
    this.padding,
    this.inputPadding,
    this.chipSpacing,
    this.inputTextStyle,
    this.chipStyle,
    this.focusOutlineStyle,
  });

  // ─── Design-system defaults ────────────────────

  /// Default container background colour token.
  static const CoreColor defaultBackgroundColor = CoreColor.token(
    CoreColors.surface,
  );

  /// Default container border colour token — `outlineVariant`.
  ///
  /// The single-line text field's resting edge (#5747): a form with several
  /// fields reads as a page of lines when every resting edge is `outline`,
  /// so the frame steps one tone quieter and only the one under the pointer
  /// lifts.
  static const CoreColor defaultBorderColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default container border colour token while the pointer is over the
  /// frame — `outline`, one step past the resting [defaultBorderColor] (the
  /// same hover step the single-line text field takes). A focused frame
  /// draws its focus ring instead and keeps the resting border, and a
  /// disabled frame has no hover step at all.
  static const CoreColor defaultHoverBorderColor = CoreColor.token(
    CoreColors.outline,
  );

  /// Default container fill while the frame is disabled —
  /// `disabledContainer`, the token the text field's disabled fill takes.
  /// A disabled frame says so with its own tokens, not with an opacity wash
  /// over the enabled ones.
  static const CoreColor defaultDisabledBackgroundColor = CoreColor.token(
    CoreColors.disabledContainer,
  );

  /// Default container border colour while the frame is disabled —
  /// `disabledOutline`.
  static const CoreColor defaultDisabledBorderColor = CoreColor.token(
    CoreColors.disabledOutline,
  );

  /// Default inline text-entry style — the single source for the
  /// editable region's typography. Token-backed on the `bodyMedium` role
  /// with the design-system colour (`onSurface`), matched 1:1 with the
  /// [inputTextStyle] nested slot. Both platforms drive the editable
  /// region from this single style: Flutter via
  /// `defaultInputTextStyle.merge(override).toValue(theme:, color:)`;
  /// Web via `emitTypography(override, defaultInputTextStyle)`.
  static const CoreTextStyle defaultInputTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodyMedium,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default placeholder colour token for the inline text-entry field.
  /// Web emits this as the `placeholder:text-{token}` class; the Flutter
  /// `EditableText` has no placeholder so it is Web-only chrome routed
  /// through this single source (layer-mapping.md).
  static const CoreColor defaultPlaceholderColor = CoreColor.token(
    CoreColors.placeholder,
  );

  /// Default container border radius — `radius12`, the corner the input
  /// family states (the text field's, #5747); it holds when the badges wrap
  /// the frame onto several lines.
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius12,
  );

  /// Default container border width (logical px).
  static const double defaultBorderWidth = CoreStrokeWidth.stroke1;

  /// Variant the composed `Chip` badges are drawn in — `filled`: a tinted
  /// shape with no outline, so a row of badges reads as quiet marks inside
  /// the frame rather than a second set of boxes. Semantic identifier of
  /// the composed child, single source for both platforms.
  static const CoreChipVariant chipVariant = CoreChipVariant.filled;

  /// Emphasis the composed `Chip` badges are drawn at — `low`, neutral ink
  /// on the quiet grey fill.
  static const CoreChipEmphasis chipEmphasis = CoreChipEmphasis.low;

  /// Size row the composed `Chip` badges take — `sm` (28 floor, corner 6,
  /// 10×2 padding, 4 label gap, `labelSmall` label).
  static const CoreChipSize chipSize = CoreChipSize.sm;

  /// Default chip chrome — a partial [CoreChipStyle] carrying only the
  /// values where the ChipInput badge diverges from the standalone `Chip`
  /// `sm` row: a 16px close affordance (the row's is 18) with a 12px glyph
  /// (the row's is 16), so the remove button stays a small mark beside the
  /// label instead of the tallest thing in the badge. Raw-forwarded to the
  /// composed `Chip` as `defaultChipStyle.merge(chipStyle)`. Everything not
  /// set here — fill, corner, padding, label role and ink, the ghost close
  /// button and its idle / disabled colours — flows from the Chip's own
  /// resolver.
  static const CoreChipStyle defaultChipStyle = CoreChipStyle(
    closeIconStyle: CoreIconStyle(size: CoreIconSize.size12),
    closeButtonStyle: CoreButtonStyle(
      height: CoreSize.size16,
      width: CoreSize.size16,
    ),
  );

  /// Variant of the composed entry `TextField` — `plain`: no border, no
  /// fill, so the frame is the only box and the field draws just the caret,
  /// text and placeholder. The entry field takes the `TextField` default
  /// `md` size. Semantic identifier of the composed child, single source
  /// for both platforms.
  static const CoreTextFieldVariant fieldVariant = CoreTextFieldVariant.plain;

  /// Chromeless inline text-entry field — the ChipInput frame owns the
  /// visible boundary (border / background / padding), so the composed
  /// `TextField` is drawn as its `plain` variant (no border, no fill) and
  /// this partial suppresses what `plain` still draws: its own focus ring,
  /// its focus border and its hover wash. Single Core source referenced by
  /// both the Flutter and Web widgets (mirrors
  /// `CorePhoneInputStyle.chromelessFieldStyle`).
  ///
  /// The `focusOutlineStyle:` argument below is the **inner** field's
  /// ring, zeroed so only the frame's ring is visible — it is not the
  /// [CoreChipInputStyle.focusOutlineStyle] slot, which is the frame's
  /// own (visible) ring.
  static const CoreTextFieldStyle chromelessFieldStyle = CoreTextFieldStyle(
    // The frame owns the hover step; the wash `plain` rides would paint a
    // second one over the run of chips.
    stateLayer: CoreStateLayer(
      hover: CoreOpacity.opacity0,
      focus: CoreOpacity.opacity0,
      pressed: CoreOpacity.opacity0,
    ),
    // Square: the frame owns the corners. A browser clips an `<input>`'s
    // content to its rounded box — a corner left to the size row's default
    // (a quarter of the row height) is a pill around a one-line field and
    // shaves the 1px caret to a sliver.
    borderRadius: .zero,
    // No inset of its own: the frame sets the outer inset and
    // [defaultInputPadding] the gap to the last badge, both outside the
    // field, so the size row's padding does not add a second one inside it.
    padding: CoreEdgeInsets.zero,
    // No floor: the outer frame is the box and sets the row height; the
    // field inside it is only the line it types on.
    minHeight: 0,
    focusOutlineStyle: CoreFocusOutlineStyle(
      borderColor: .transparent,
      borderWidth: 0,
      offsetColor: .transparent,
    ),
    // `plain` still tints its resting 1px edge `primary` on focus, which on
    // an input that sits inside the frame is a second box around the line
    // being typed on. The frame's ring is the focus indicator; as with every
    // other composition of a chromeless field (Command, PhoneInput, the OTP
    // buffer, TimePicker segments), the inner edge stays as it rests.
    focusBorderColor: CoreColor.transparent,
  );

  /// Default container minimum height — the md control row
  /// ([CoreControlSize.heightMd]).
  ///
  /// A row of the control ladder rather than a size. The frame sits in a
  /// form beside the `md` text field, and one badge run (a 28 chip between
  /// 6 and 6 of padding) lands exactly on this row. ChipInput has no Size
  /// axis, so the row is always `md`; stating it as that rung is what lets a
  /// theme density move the frame with the text field beside it instead of
  /// holding 40 while the field shrinks. Both resolvers move this default
  /// and leave a caller's own [minHeight] as stated — a stated minimum is a
  /// statement, not a rung.
  ///
  /// The corner does not follow the row. The height × 0.25 corner belongs
  /// to a control whose Size axis picks a rung; this frame picks none and
  /// keeps the 12 it states ([defaultBorderRadius]), which also stays round
  /// when the badges wrap to several lines.
  static const double defaultMinHeight = CoreControlSize.heightMd;

  /// Default container padding — 6 above and below, 10 at the start (the
  /// first badge sits close to the edge, its own 10 inset making up the
  /// rest) and 14 at the end, the text field's horizontal inset.
  ///
  /// Directional: the start and end insets differ because of what they
  /// are (badges begin the run, the caret ends it), so they follow the
  /// reading direction.
  static const CoreEdgeInsets defaultPadding = CoreEdgeInsets.directional(
    start: CoreSpace.space10,
    top: CoreSpace.space6,
    end: CoreSpace.space14,
    bottom: CoreSpace.space6,
  );

  /// Default inset around the inline entry field — 4 at the start, the gap
  /// between the last badge's run and the caret on top of [defaultChipSpacing].
  /// Directional (it is about reading order), and applied outside the
  /// composed `TextField`, which states its own padding in
  /// [chromelessFieldStyle].
  static const CoreEdgeInsets defaultInputPadding = CoreEdgeInsets.directional(
    start: CoreSpace.space4,
  );

  /// Default gap between chips (logical px).
  static const double defaultChipSpacing = CoreSpace.space6;

  /// Container background fill colour override.
  final CoreColor? backgroundColor;

  /// Container border stroke colour override.
  final CoreColor? borderColor;

  /// Container border stroke colour override while the pointer is over the
  /// frame. `null` → [defaultHoverBorderColor]. Never applied while the
  /// frame holds focus (the focus ring owns that state) or while it is
  /// disabled.
  final CoreColor? hoverBorderColor;

  /// Container fill override while the frame is disabled.
  /// `null` → [defaultDisabledBackgroundColor].
  final CoreColor? disabledBackgroundColor;

  /// Container border stroke colour override while the frame is disabled.
  /// `null` → [defaultDisabledBorderColor].
  final CoreColor? disabledBorderColor;

  /// Container border stroke width override (logical px).
  final double? borderWidth;

  /// Container border radius override.
  final CoreBorderRadius? borderRadius;

  /// Container minimum height override (logical px).
  ///
  /// A stated minimum stays as stated under every density — only
  /// [defaultMinHeight], the control row, moves.
  final double? minHeight;

  /// Container padding override.
  final CoreEdgeInsets? padding;

  /// Inset around the inline entry field override.
  /// `null` → [defaultInputPadding].
  final CoreEdgeInsets? inputPadding;

  /// Gap between chip badges override (logical px).
  final double? chipSpacing;

  /// Inline text-entry (`<input>` / `EditableText`) text style override.
  /// The typography role and the text colour ([CoreTextStyle.color]) both
  /// go in this one style.
  final CoreTextStyle? inputTextStyle;

  /// Style of the chips in the field (a [CoreChipStyle]). Laid over
  /// [defaultChipStyle] and passed to each `Chip`, which fills in every
  /// field neither of them states.
  final CoreChipStyle? chipStyle;

  // No paired `default…` const on purpose: every field of one would
  // restate a `CoreFocusOutlineStyle` default verbatim (the ring colour
  // is `CoreColors.primary` on both sides), which is the reach into a
  // child's defaults `resolver/resolver-pattern.md` forbids. The only
  // value the resolvers state is the frame's corner radius — the one
  // thing `FocusOutline` cannot derive — and they state it *underneath*
  // this slot so a caller's `borderRadius` still wins.
  //
  /// Focus ring the **frame** draws while the field (or anything inside it)
  /// has focus. Left `null`, every ring field falls back to
  /// `FocusOutline`'s own defaults. Not the `focusOutlineStyle:` inside
  /// [chromelessFieldStyle], which belongs to the inner `TextField` and
  /// *suppresses* its ring — this slot is the visible one.
  ///
  /// Flutter wraps the frame in `FocusOutline`, Web paints it with
  /// `focus-within:outline-*`.
  ///
  /// **Deliberately has no `default*` — absence is the design.** A default
  /// here would be this style stating the ring's colour, width and offset on
  /// `FocusOutline`'s behalf, which is the partial-slot-forward rule's
  /// "do not reach into the child's defaults" (`resolver/resolver-pattern.md`).
  /// The resolvers state exactly one field underneath this slot — the frame's
  /// corner radius, the one value the child cannot derive — and leave the rest
  /// null so the child's own resolver fills them.
  final CoreFocusOutlineStyle? focusOutlineStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreChipInputStyle merge(CoreChipInputStyle? other) {
    if (other == null) return this;
    return CoreChipInputStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      hoverBorderColor: other.hoverBorderColor ?? hoverBorderColor,
      disabledBackgroundColor:
          other.disabledBackgroundColor ?? disabledBackgroundColor,
      disabledBorderColor: other.disabledBorderColor ?? disabledBorderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      minHeight: other.minHeight ?? minHeight,
      padding: other.padding ?? padding,
      inputPadding: other.inputPadding ?? inputPadding,
      chipSpacing: other.chipSpacing ?? chipSpacing,
      inputTextStyle: _mergeText(inputTextStyle, other.inputTextStyle),
      chipStyle: _mergeChip(chipStyle, other.chipStyle),
      focusOutlineStyle: _mergeFocusOutline(
        focusOutlineStyle,
        other.focusOutlineStyle,
      ),
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreChipInputStyle copyWith({
    CoreColor? backgroundColor,
    CoreColor? borderColor,
    CoreColor? hoverBorderColor,
    CoreColor? disabledBackgroundColor,
    CoreColor? disabledBorderColor,
    double? borderWidth,
    CoreBorderRadius? borderRadius,
    double? minHeight,
    CoreEdgeInsets? padding,
    CoreEdgeInsets? inputPadding,
    double? chipSpacing,
    CoreTextStyle? inputTextStyle,
    CoreChipStyle? chipStyle,
    CoreFocusOutlineStyle? focusOutlineStyle,
  }) {
    return CoreChipInputStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
      disabledBackgroundColor:
          disabledBackgroundColor ?? this.disabledBackgroundColor,
      disabledBorderColor: disabledBorderColor ?? this.disabledBorderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      minHeight: minHeight ?? this.minHeight,
      padding: padding ?? this.padding,
      inputPadding: inputPadding ?? this.inputPadding,
      chipSpacing: chipSpacing ?? this.chipSpacing,
      inputTextStyle: inputTextStyle ?? this.inputTextStyle,
      chipStyle: chipStyle ?? this.chipStyle,
      focusOutlineStyle: focusOutlineStyle ?? this.focusOutlineStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreChipInputStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          borderColor == other.borderColor &&
          hoverBorderColor == other.hoverBorderColor &&
          disabledBackgroundColor == other.disabledBackgroundColor &&
          disabledBorderColor == other.disabledBorderColor &&
          borderWidth == other.borderWidth &&
          borderRadius == other.borderRadius &&
          minHeight == other.minHeight &&
          padding == other.padding &&
          inputPadding == other.inputPadding &&
          chipSpacing == other.chipSpacing &&
          inputTextStyle == other.inputTextStyle &&
          chipStyle == other.chipStyle &&
          focusOutlineStyle == other.focusOutlineStyle;

  @override
  int get hashCode => Object.hashAll([
    backgroundColor,
    borderColor,
    hoverBorderColor,
    disabledBackgroundColor,
    disabledBorderColor,
    borderWidth,
    borderRadius,
    minHeight,
    padding,
    inputPadding,
    chipSpacing,
    inputTextStyle,
    chipStyle,
    focusOutlineStyle,
  ]);

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreChipStyle? _mergeChip(
    CoreChipStyle? base,
    CoreChipStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreFocusOutlineStyle? _mergeFocusOutline(
    CoreFocusOutlineStyle? base,
    CoreFocusOutlineStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
