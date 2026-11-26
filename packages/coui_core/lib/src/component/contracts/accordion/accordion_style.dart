/// Per-instance style for `Accordion`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart' show CoreColors;
import 'package:coui_core/src/component/contracts/button/button_style.dart';
import 'package:coui_core/src/component/contracts/clickable/clickable_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart' show CoreSpace;
import 'package:coui_core/src/typography/core_text_style_token.dart'
    show CoreTextStyles;
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Accordion` should render.
///
/// `CoreAccordionStyle` carries chrome flat fields plus nested
/// trigger button / content text / chevron icon slot styles.
///
/// **Semantic enums (`type` / behaviour like `expanded`) live on the
/// widget, not on this style** (Epic #1302 원칙 6/7). To change the
/// trigger's variant inject a `Button` directly via the trigger
/// slot (Epic #1302 원칙 8 — asChild).
///
/// ```text
/// design system default
///   → CoreAccordionTheme.style                       // 프로젝트 공통
///   → parent component slot override
///   → widget.accordionStyle                          // 인스턴스별
/// ```
@immutable
class CoreAccordionStyle implements CoreStyle<CoreAccordionStyle> {
  /// Creates a [CoreAccordionStyle].
  const CoreAccordionStyle({
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.contentPadding,
    this.itemSpacing,
    this.dividerColor,
    this.dividerThickness,
    this.duration,
    this.arrowIconStyle,
    this.triggerStyle,
    this.contentTextStyle,
    this.chevronIconStyle,
    this.iconGapStyle,
    this.clickableStyle,
  });

  // ── Defaults (design-system fallback) ────────

  /// Default outer border stroke width — `stroke0` (no border).
  ///
  /// Supplying a wider value changes nothing today: neither platform's
  /// `Accordion` reads this field. The widgets consume `dividerColor` and
  /// `dividerThickness` and draw no outer outline at all, so seats (4) and (6)
  /// of the 1:1:1:1:1:1 mapping are empty for it. The default is here because
  /// the field is, and a field with no default cannot reach the Figma export
  /// either — but it is a baseline waiting for a consumer, not a value the
  /// canvas or the app is honouring.
  static const double defaultBorderWidth = CoreStrokeWidth.stroke0;

  /// Default expanded content padding — symmetric vertical only so the
  /// collapsed grid row clears the trigger's bottom edge. Forwarded as
  /// the fallback for the [contentPadding] override field.
  static const CoreEdgeInsets defaultContentPadding = CoreEdgeInsets.symmetric(
    vertical: CoreSpace.space16,
  );

  /// Default horizontal gap between trigger label and chevron icon
  /// (logical px).
  static const double defaultIconGap = CoreSpace.space20;

  /// Default 1-off spacer between the trigger label and the chevron
  /// icon. Forwarded as the fallback for the [iconGapStyle] override
  /// slot — rendered by `Gap` (Flutter) / inline `gap` CSS (Web).
  static const CoreGapStyle defaultIconGapStyle = CoreGapStyle(
    size: defaultIconGap,
  );

  /// Default chevron / disclosure icon style — `size` only (16 logical
  /// px). Per-instance override flows through [arrowIconStyle] (merged
  /// on top of this default).
  ///
  /// [arrowIconStyle] and [chevronIconStyle] are two override slots for
  /// the one glyph, so the resolvers take the size from whichever the
  /// caller set and fall through to [defaultChevronIconStyle] — the slot
  /// that also carries the colour — when neither did. This default is
  /// therefore what the `arrowIconStyle` slot resolves to on its own, and
  /// it states the same 16 px.
  static const CoreIconStyle defaultArrowIconStyle = CoreIconStyle(
    size: CoreIconSize.size16,
  );

  /// Default rotating chevron / disclosure indicator style — the same 16
  /// logical px as [defaultArrowIconStyle] plus the `onSurface` glyph
  /// colour. The size is restated as the primitive rather than read off
  /// [defaultArrowIconStyle] because a `const` initializer cannot access
  /// another object's property (`const_eval_property_access`).
  ///
  /// The colour is what the indicator renders in its resting state on both
  /// platforms: Flutter applies it to the glyph directly, Web lets the
  /// glyph inherit the trigger row's label colour, whose own default
  /// ([defaultLabelTextStyle]) is the same `onSurface`. Per-instance
  /// overrides flow through [chevronIconStyle] (merged on top of this
  /// default).
  static const CoreIconStyle defaultChevronIconStyle = CoreIconStyle(
    size: CoreIconSize.size16,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default trigger row chrome — vertical padding. Forwarded as the
  /// fallback for the [triggerStyle] override slot so the resolver
  /// composes the trigger padding from a single source of truth. The
  /// label-to-chevron gap lives on the dedicated [iconGapStyle] slot
  /// ([defaultIconGapStyle]).
  static const CoreButtonStyle defaultTriggerStyle = CoreButtonStyle(
    padding: CoreEdgeInsets.symmetric(vertical: CoreSpace.space16),
  );

  /// Default trigger label typography — `labelXl` role (token-backed,
  /// 15 / 500 / 1.4) with the `onSurface` colour. Per-instance overrides
  /// flow through `triggerStyle.labelStyle` (merged on top of this
  /// default); the resolver materialises the paint-ready label text style
  /// from this single source of truth.
  // A label role, not a body role + a `medium` overlay: one fewer place the
  // weight is spelled — and the overlay is exactly the per-component
  // spelling that left `Button` lighter than the row beside it.
  static const CoreTextStyle defaultLabelTextStyle = CoreTextStyle.token(
    CoreTextStyles.labelXl,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default expanded content typography — `bodySmall` role (token-backed)
  /// with the `onSurface` colour. Per-instance overrides flow through
  /// [contentTextStyle] (merged on top of this default).
  static const CoreTextStyle defaultContentTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodySmall,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default expand / collapse animation duration.
  static const Duration defaultDuration = Duration(
    milliseconds: CoreDuration.normal,
  );

  /// Default nested [CoreClickableStyle] slot for the composed trigger
  /// `Clickable` — pins only `pressedScale: 1` (a full-width header row
  /// must not visibly shrink on press). The focus-ring corner radius
  /// (`radius4`) is already the Clickable's own default, so it is not
  /// re-declared here (child-default duplication is a "합성 = 재구현
  /// 금지" violation). Everything else stays null and resolves inside
  /// the Clickable's own resolver via
  /// `defaultClickableStyle.merge(merged.clickableStyle)`.
  static const CoreClickableStyle defaultClickableStyle = CoreClickableStyle(
    pressedScale: 1,
  );

  // ── Chrome (flat) ────────────────────────────

  /// Expand / collapse animation duration.
  ///
  /// Visual transition timing — chrome category, lives on the style not
  /// the widget.
  final Duration? duration;

  /// Chevron / disclosure icon style override. `size` defers to
  /// [defaultArrowIconStyle].
  final CoreIconStyle? arrowIconStyle;

  /// Container background colour for an expanded item.
  ///
  /// **Deliberately has no `default*` — absence is the design.** The Web
  /// resolver adds the `bg-*` class and its inline fragment only inside
  /// `if (merged.backgroundColor != null)`, so a null here is what leaves
  /// the accordion transparent over whichever surface hosts it. A
  /// constant would turn that branch permanently on and give every
  /// accordion in every tree an opaque panel of its own — and only on one
  /// platform, because the Flutter widget never reads the resolved value
  /// (it paints no container fill at all, so seat (4) of the
  /// 1:1:1:1:1:1 mapping is empty for this field).
  final CoreColor? backgroundColor;

  /// Outer border stroke colour.
  ///
  /// **Deliberately has no `default*` — absence is the design.** The Web
  /// resolver emits the border colour only inside
  /// `if (merged.borderColor != null)`, and that emit sets `border-color`
  /// alone — width comes from the separate [borderWidth] override, whose
  /// own default is `stroke0` ([defaultBorderWidth]). A colour constant
  /// would therefore put a `border-*` class on every accordion to describe
  /// a stroke that has no width to draw it. The outline this component
  /// ships is the between-items rule, not a box around the whole list.
  final CoreColor? borderColor;

  /// Outer border stroke width (logical px).
  final double? borderWidth;

  /// Outer border radius.
  ///
  /// **Deliberately has no `default*` — absence is the design.** The Web
  /// resolver writes `border-radius` only inside
  /// `if (merged.borderRadius != null)`. Square is correct for the shipped
  /// accordion: it has no outer fill and no outer stroke ([borderColor] /
  /// [defaultBorderWidth] above), so there is no edge for a radius to
  /// round. A constant would turn that branch permanently on, so the rule
  /// would ship on every accordion and start rounding the moment a caller
  /// sets [backgroundColor] or [borderColor] — a corner nobody asked for,
  /// arriving with an unrelated override.
  final CoreBorderRadius? borderRadius;

  /// Padding applied to expanded content.
  final CoreEdgeInsets? contentPadding;

  /// Vertical spacing between accordion items (logical px) — native
  /// `Column.spacing` (Flutter) / `row-gap` (Web). When `null` items
  /// share a divider line instead of a gap.
  ///
  /// **Deliberately has no `default*` — absence is the design, and it is
  /// load-bearing on both platforms.** Being null is what selects the
  /// divider-separated layout: the Flutter widget branches on
  /// `itemSpacing != null` to decide between `Column.spacing` and
  /// interleaved `Divider`s, and the Web resolver only switches the
  /// container to `display:flex; flex-direction:column; row-gap` inside
  /// `if (merged.itemSpacing != null)`. A constant would delete the
  /// separator from every accordion that never asked for gaps — the two
  /// layouts are alternatives, so a default here is a default for the
  /// choice, not for a measurement.
  final double? itemSpacing;

  /// Divider line colour between items.
  ///
  /// **Deliberately has no `default*` — absence delegates to the child.**
  /// Both platforms treat null as "let the composed `Divider` supply its
  /// own colour": Flutter renders a bare `const Divider()` unless
  /// [dividerColor] or [dividerThickness] is set, and the Web resolver
  /// returns a null `divider` chrome for the same condition so the widget
  /// falls back to the `Divider` component instead of a raw `<div>`. A
  /// constant would flip that pair of branches and, being equal to
  /// `CoreDividerStyle.defaultColor`, would restate the child's own
  /// default here — the flat-duplication half of "합성 = 재구현 금지".
  final CoreColor? dividerColor;

  /// Divider line thickness (logical px).
  ///
  /// **Deliberately has no `default*` — same delegation as
  /// [dividerColor].** It is the other half of the one condition both
  /// platforms test (`dividerColor == null && dividerThickness == null`),
  /// so a constant on either field alone is enough to swap the composed
  /// `Divider` for a hand-built rule on every accordion, and its value
  /// would restate `CoreDividerStyle.defaultThickness`.
  final double? dividerThickness;

  // ── Slot Styles (nested) ─────────────────────

  /// Look of each trigger row — its padding, fill, label text style and
  /// label colour. Laid over [defaultTriggerStyle].
  ///
  /// The row is a `Clickable`, not a composed `Button`: only `padding`,
  /// `backgroundColor`, `labelStyle` and `foregroundColor` are read, so
  /// other `CoreButtonStyle` fields have no effect.
  final CoreButtonStyle? triggerStyle;

  /// Expanded content text style (applied when the content is a
  /// plain string).
  final CoreTextStyle? contentTextStyle;

  /// Chevron / disclosure icon style (the rotating indicator).
  final CoreIconStyle? chevronIconStyle;

  /// 1-off spacer between the trigger label and the chevron icon —
  /// rendered by `Gap` (Flutter) / inline `gap` CSS (Web). Defers to
  /// [defaultIconGapStyle].
  final CoreGapStyle? iconGapStyle;

  /// Style for the trigger's `Clickable` — press scale, focus ring, cursor,
  /// keyboard activation. Laid over [defaultClickableStyle] and passed to
  /// the `Clickable` as is; the `Clickable` fills in the rest.
  final CoreClickableStyle? clickableStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are
  /// merged recursively.
  @override
  CoreAccordionStyle merge(CoreAccordionStyle? other) {
    if (other == null) return this;
    return CoreAccordionStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      contentPadding: other.contentPadding ?? contentPadding,
      itemSpacing: other.itemSpacing ?? itemSpacing,
      dividerColor: other.dividerColor ?? dividerColor,
      dividerThickness: other.dividerThickness ?? dividerThickness,
      duration: other.duration ?? duration,
      arrowIconStyle: _mergeIcon(arrowIconStyle, other.arrowIconStyle),
      triggerStyle: _mergeButton(triggerStyle, other.triggerStyle),
      contentTextStyle: _mergeText(contentTextStyle, other.contentTextStyle),
      chevronIconStyle: _mergeIcon(chevronIconStyle, other.chevronIconStyle),
      iconGapStyle: _mergeGap(iconGapStyle, other.iconGapStyle),
      clickableStyle:
          clickableStyle?.merge(other.clickableStyle) ?? other.clickableStyle,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreAccordionStyle copyWith({
    CoreColor? backgroundColor,
    CoreColor? borderColor,
    double? borderWidth,
    CoreBorderRadius? borderRadius,
    CoreEdgeInsets? contentPadding,
    double? itemSpacing,
    CoreColor? dividerColor,
    double? dividerThickness,
    Duration? duration,
    CoreIconStyle? arrowIconStyle,
    CoreButtonStyle? triggerStyle,
    CoreTextStyle? contentTextStyle,
    CoreIconStyle? chevronIconStyle,
    CoreGapStyle? iconGapStyle,
    CoreClickableStyle? clickableStyle,
  }) {
    return CoreAccordionStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      contentPadding: contentPadding ?? this.contentPadding,
      itemSpacing: itemSpacing ?? this.itemSpacing,
      dividerColor: dividerColor ?? this.dividerColor,
      dividerThickness: dividerThickness ?? this.dividerThickness,
      duration: duration ?? this.duration,
      arrowIconStyle: arrowIconStyle ?? this.arrowIconStyle,
      triggerStyle: triggerStyle ?? this.triggerStyle,
      contentTextStyle: contentTextStyle ?? this.contentTextStyle,
      chevronIconStyle: chevronIconStyle ?? this.chevronIconStyle,
      iconGapStyle: iconGapStyle ?? this.iconGapStyle,
      clickableStyle: clickableStyle ?? this.clickableStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreAccordionStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          borderRadius == other.borderRadius &&
          contentPadding == other.contentPadding &&
          itemSpacing == other.itemSpacing &&
          dividerColor == other.dividerColor &&
          dividerThickness == other.dividerThickness &&
          duration == other.duration &&
          arrowIconStyle == other.arrowIconStyle &&
          triggerStyle == other.triggerStyle &&
          contentTextStyle == other.contentTextStyle &&
          chevronIconStyle == other.chevronIconStyle &&
          iconGapStyle == other.iconGapStyle &&
          clickableStyle == other.clickableStyle;

  @override
  int get hashCode => Object.hashAll([
    backgroundColor,
    borderColor,
    borderWidth,
    borderRadius,
    contentPadding,
    itemSpacing,
    dividerColor,
    dividerThickness,
    duration,
    arrowIconStyle,
    triggerStyle,
    contentTextStyle,
    chevronIconStyle,
    iconGapStyle,
    clickableStyle,
  ]);

  static CoreButtonStyle? _mergeButton(
    CoreButtonStyle? base,
    CoreButtonStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreIconStyle? _mergeIcon(
    CoreIconStyle? base,
    CoreIconStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreGapStyle? _mergeGap(
    CoreGapStyle? base,
    CoreGapStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
