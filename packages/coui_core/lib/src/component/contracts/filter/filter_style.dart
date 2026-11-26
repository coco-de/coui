/// Per-instance style for `Filter`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/button/button_style.dart';
import 'package:coui_core/src/component/contracts/clickable/clickable_style.dart';
import 'package:coui_core/src/component/contracts/divider/divider_style.dart';
import 'package:coui_core/src/component/contracts/filter/filter_variant.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/contracts/toggle_group/toggle_group_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/component_size.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/size/size.dart' show CoreSize;
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart' show CoreSpace;
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/font_weight.dart' show CoreFontWeight;
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Filter` should render.
///
/// `CoreFilterStyle` is **platform-neutral**. Every chrome / dimensional
/// field is exposed as a nullable override so a single style object can
/// flow through the nested-merge chain:
///
/// ```text
/// design system default (this class' `static const defaultX`)
///   → CoreFilterTheme.style                       // 프로젝트 공통
///   → CoreFilterTheme.variantStyles[variant]
///   → parent component slot override
///   → widget.filterStyle                          // 인스턴스별
/// ```
///
/// The segments are a composed `ToggleGroup`, so the track, the raised
/// chosen face (and its shadow), the segment geometry, the label roles and
/// the disabled look are [toggleGroupStyle]'s — a partial
/// [CoreToggleGroupStyle] merged over [defaultToggleGroupStyle] and
/// raw-forwarded. What the filter adds on top is the reset affordance
/// ([resetButtonStyle]) and the hairline that parts it from the segments
/// ([dividerStyle] · [dividerHeight] · [dividerLeadingSpacing] ·
/// [trailingSpacing]). The older flat
/// track / segment fields ([backgroundColor], [itemPadding], …) are
/// deprecated; they still reach the group — [toggleGroupStyleFor] folds them
/// in under [toggleGroupStyle] — so existing overrides keep working for one
/// more version.
///
/// **Semantic enum (`variant`) lives on the widget, not on this style**
/// (Epic #1302 원칙 6/7).
@immutable
class CoreFilterStyle implements CoreStyle<CoreFilterStyle> {
  /// Creates a [CoreFilterStyle].
  const CoreFilterStyle({
    @Deprecated(
      'Use toggleGroupStyle (since 0.173)',
    )
    this.backgroundColor,
    @Deprecated(
      'Use toggleGroupStyle (since 0.173)',
    )
    this.selectedColor,
    @Deprecated(
      'Use toggleGroupStyle (since 0.173)',
    )
    this.borderRadius,
    @Deprecated(
      'Use toggleGroupStyle (since 0.173)',
    )
    this.itemBorderRadius,
    @Deprecated(
      'Use toggleGroupStyle (since 0.173)',
    )
    this.padding,
    @Deprecated(
      'Use toggleGroupStyle (since 0.173)',
    )
    this.itemPadding,
    @Deprecated(
      'Use toggleGroupStyle (since 0.173)',
    )
    this.labelPadding,
    @Deprecated(
      'Use toggleGroupStyle (since 0.173)',
    )
    this.itemHeight,
    @Deprecated(
      'Use toggleGroupStyle (since 0.173)',
    )
    this.itemSpacing,
    @Deprecated(
      'Use toggleGroupStyle (since 0.173)',
    )
    this.selectedFontWeight,
    @Deprecated(
      'Use toggleGroupStyle (since 0.173)',
    )
    this.transitionDuration,
    @Deprecated(
      'Use toggleGroupStyle (since 0.173)',
    )
    this.labelTextStyle,
    @Deprecated(
      'Use toggleGroupStyle (since 0.173)',
    )
    this.selectedLabelTextStyle,
    @Deprecated(
      'Use toggleGroupStyle (since 0.173)',
    )
    this.iconStyle,
    @Deprecated(
      'Use toggleGroupStyle (since 0.173)',
    )
    this.selectedIconStyle,
    @Deprecated(
      'Use toggleGroupStyle (since 0.173)',
    )
    this.clickableStyle,
    this.resetButtonStyle,
    this.toggleGroupStyle,
    this.dividerStyle,
    this.disabledDividerColor,
    this.dividerHeight,
    this.dividerLeadingSpacing,
    this.trailingSpacing,
  });

  // ─── Design-system defaults ───────────────────────────────────────
  // Variant-independent defaults live as static const here. The single
  // [CoreFilterVariant.segmented] variant supplies no extra chrome, so
  // [defaultsByVariant] holds an empty variant style for that key.

  /// Default container background fill colour token — the grouped-toggle
  /// track (`surfaceContainerHigh`) the time and colour pickers share.
  @Deprecated(
    'The segments are the composed ToggleGroup now — set [toggleGroupStyle] '
    'instead; this default is no longer read (since 0.173)',
  )
  static const CoreColor defaultBackgroundColor = CoreColor.token(
    CoreColors.surfaceContainerHigh,
  );

  /// Default background fill colour of the currently selected item — the
  /// raised face (`surfaceRaised`) that lifts off the track.
  @Deprecated(
    'The segments are the composed ToggleGroup now — set [toggleGroupStyle] '
    'instead; this default is no longer read (since 0.173)',
  )
  static const CoreColor defaultSelectedColor = CoreColor.token(
    CoreColors.surfaceRaised,
  );

  /// Default container corner radius (10 logical px on all four
  /// corners).
  @Deprecated(
    'The segments are the composed ToggleGroup now — set [toggleGroupStyle] '
    'instead; this default is no longer read (since 0.173)',
  )
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius10,
  );

  /// Default per-item corner radius (8 logical px on all four
  /// corners).
  @Deprecated(
    'The segments are the composed ToggleGroup now — set [toggleGroupStyle] '
    'instead; this default is no longer read (since 0.173)',
  )
  static const CoreBorderRadius defaultItemBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius8,
  );

  /// Default padding inside the filter container (4 logical px on all
  /// sides).
  @Deprecated(
    'The segments are the composed ToggleGroup now — set [toggleGroupStyle] '
    'instead; this default is no longer read (since 0.173)',
  )
  static const CoreEdgeInsets defaultPadding = CoreEdgeInsets.all(
    CoreSpace.space4,
  );

  /// Default padding inside each filter item (8 logical px on all
  /// sides). The segment's own inset is uniform so that an icon-only
  /// segment (`8 + 16 icon + 8`) is a 32 logical-px square matching
  /// [defaultItemHeight]; the remaining horizontal inset of a label
  /// segment lives on the label box ([defaultLabelPadding]), so a
  /// label-only segment keeps its former 16 logical-px total per side.
  /// Read by both platform resolvers and the Figma builder.
  @Deprecated(
    'The segments are the composed ToggleGroup now — set [toggleGroupStyle] '
    'instead; this default is no longer read (since 0.173)',
  )
  static const CoreEdgeInsets defaultItemPadding = CoreEdgeInsets.all(
    CoreSpace.space8,
  );

  /// Default inset of the label box inside a segment (8 logical px
  /// horizontal, none vertical). Only painted when the item shows its
  /// label — this is what lets an icon-only segment collapse to a
  /// square. Read by both platform resolvers and the Figma builder.
  @Deprecated(
    'The segments are the composed ToggleGroup now — set [toggleGroupStyle] '
    'instead; this default is no longer read (since 0.173)',
  )
  static const CoreEdgeInsets defaultLabelPadding = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space8,
  );

  /// Default fixed segment height (32 logical px); content is centred
  /// vertically inside it. Read by both platform resolvers and the
  /// Figma builder.
  ///
  /// The Filter's own row, not a control row — a theme density leaves it
  /// where it is, on both platforms. A segment is a part of the Filter's
  /// track (4 + 32 + 4), not a field that lines up with the text field
  /// beside it, and its height carries two relations the control ladder
  /// would break: the reset button is the same 32 square
  /// ([defaultResetButtonStyle]), and the track only lands on the ladder's
  /// rows (32 / 40 / 48) if the segment goes to 24 under compact — below
  /// the label's line box plus the compact inset (16.8 + 2 × 4), the same
  /// reason the ladder itself stops at `sm` under compact. So the bar stays
  /// 40 under every density while an `md` field beside it moves; what the
  /// density does move is the segment's inset ([defaultItemPadding] and
  /// [defaultLabelPadding]), so an icon-only segment is a square only at
  /// the standard density.
  @Deprecated(
    'The segments are the composed ToggleGroup now — set [toggleGroupStyle] '
    'instead; this default is no longer read (since 0.173)',
  )
  static const double defaultItemHeight = CoreSize.size32;

  /// Default spacing between filter items (2 logical px).
  @Deprecated(
    'The segments are the composed ToggleGroup now — set [toggleGroupStyle] '
    'instead; this default is no longer read (since 0.173)',
  )
  static const double defaultItemSpacing = CoreSpace.space2;

  /// Default reset-affordance button style — the single source for the
  /// reset button's own chrome, raw-forwarded to
  /// `Button(variant: .ghost, size: .sm, shape: .square, buttonStyle: …)`
  /// on both platforms. The `ghost` variant owns the transparent fill
  /// and hover tint; this slot pins the 32 logical-px square (former
  /// flat `resetButtonSize`), the zero padding (the fixed square
  /// centres the glyph), the item corner radius (8 logical px —
  /// mirrors [defaultItemBorderRadius]), the colour transition (150 ms
  /// — mirrors [defaultTransitionDuration]), the unselected-label
  /// foreground (`onSurfaceVariant` on both rest and hover — mirrors
  /// [defaultLabelTextStyle]'s colour token, no hover tint change), and
  /// the 16 logical-px close glyph (`leadingIconStyle` — former flat
  /// `resetIconStyle`). The former flat `resetButtonSize` /
  /// `resetIconStyle` fields fold into this nested slot
  /// (child-component-composition).
  static const CoreButtonStyle defaultResetButtonStyle = CoreButtonStyle(
    foregroundColor: CoreColor.token(CoreColors.onSurfaceVariant),
    hoverForegroundColor: CoreColor.token(CoreColors.onSurfaceVariant),
    borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    height: CoreSize.size32,
    width: CoreSize.size32,
    padding: .zero,
    animationDuration: Duration(milliseconds: CoreDuration.fast),
    leadingIconStyle: CoreIconStyle(size: CoreIconSize.size16),
  );

  /// Default font weight applied to the currently selected item label
  /// (CSS font-weight integer — `semiBold`).
  @Deprecated(
    'The segments are the composed ToggleGroup now — set [toggleGroupStyle] '
    'instead; this default is no longer read (since 0.173)',
  )
  static const int defaultSelectedFontWeight = CoreFontWeight.semiBold;

  /// Default selection-state colour transition duration (150 ms).
  /// Powers `transition-colors duration-X` on both items and the reset
  /// button.
  @Deprecated(
    'The segments are the composed ToggleGroup now — set [toggleGroupStyle] '
    'instead; this default is no longer read (since 0.173)',
  )
  static const Duration defaultTransitionDuration = Duration(
    milliseconds: CoreDuration.fast,
  );

  /// Default label text style — token-backed reference to the
  /// `labelLarge` slot carrying the unselected-item / reset-icon
  /// foreground colour (`onSurfaceVariant`). Both Flutter and Web
  /// resolvers materialise this token through their own typography
  /// pipeline.
  @Deprecated(
    'The segments are the composed ToggleGroup now — set [toggleGroupStyle] '
    'instead; this default is no longer read (since 0.173)',
  )
  static const CoreTextStyle defaultLabelTextStyle = CoreTextStyle.token(
    CoreTextStyles.labelLarge,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Default label text style for the currently selected item —
  /// token-backed reference to the `labelLarge` slot carrying the
  /// selected-item foreground colour (`onSurface`). The resolver layers
  /// the `defaultSelectedFontWeight` overlay on top so the selected
  /// state reads slightly heavier than the rest.
  @Deprecated(
    'The segments are the composed ToggleGroup now — set [toggleGroupStyle] '
    'instead; this default is no longer read (since 0.173)',
  )
  static const CoreTextStyle defaultSelectedLabelTextStyle =
      CoreTextStyle.token(
        CoreTextStyles.labelLarge,
        color: CoreColor.token(CoreColors.onSurface),
      );

  /// Default icon style of an unselected segment's caller-supplied icon
  /// — 16 logical px in the unselected-label foreground
  /// (`onSurfaceVariant`, mirrors [defaultLabelTextStyle]'s colour).
  /// Raw-forwarded by both platform resolvers as the ambient icon theme
  /// of the item's icon slot; the Figma builder reads its size and
  /// colour for the unselected segment icon.
  @Deprecated(
    'The segments are the composed ToggleGroup now — set [toggleGroupStyle] '
    'instead; this default is no longer read (since 0.173)',
  )
  static const CoreIconStyle defaultIconStyle = CoreIconStyle(
    size: CoreIconSize.size16,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Default icon style of the selected segment's caller-supplied icon
  /// — 16 logical px in the selected-label foreground (`onSurface`,
  /// mirrors [defaultSelectedLabelTextStyle]'s colour). Raw-forwarded
  /// by both platform resolvers; the Figma builder reads its colour for
  /// the selected segment icon.
  @Deprecated(
    'The segments are the composed ToggleGroup now — set [toggleGroupStyle] '
    'instead; this default is no longer read (since 0.173)',
  )
  static const CoreIconStyle defaultSelectedIconStyle = CoreIconStyle(
    size: CoreIconSize.size16,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default nested [CoreClickableStyle] slot for the composed per-item
  /// `Clickable` — an empty partial: filter items take the Clickable's
  /// own standard press / focus / cursor chrome as-is (the segment-pill
  /// press-shrink is appropriate). Named so the resolver's
  /// `defaultClickableStyle.merge(merged.clickableStyle)` forward has a
  /// single-source default.
  @Deprecated(
    'The segments are the composed ToggleGroup now — set [toggleGroupStyle] '
    'instead; this default is no longer read (since 0.173)',
  )
  static const CoreClickableStyle defaultClickableStyle = CoreClickableStyle();

  /// Default nested [CoreToggleGroupStyle] slot for the composed segments —
  /// an empty partial: the track, the raised chosen face and its shadow, the
  /// segment geometry, the label roles and the disabled look are
  /// `ToggleGroup`'s own, so a change there reaches the filter instead of
  /// being restated here. Named so the resolver's
  /// `defaultToggleGroupStyle.merge(...)` forward has a single-source
  /// default.
  static const CoreToggleGroupStyle defaultToggleGroupStyle =
      CoreToggleGroupStyle();

  /// Default nested [CoreDividerStyle] of the hairline between the segments
  /// and the reset button: 1 logical px in `outlineVariant`. Painted only
  /// while the reset button is.
  static const CoreDividerStyle defaultDividerStyle = CoreDividerStyle(
    color: CoreColor.token(CoreColors.outlineVariant),
    thickness: CoreStrokeWidth.stroke1,
  );

  /// Default colour of the hairline while the filter is disabled —
  /// `disabledOutline`, so the hairline fades together with the disabled
  /// track and labels instead of staying at the enabled `outlineVariant`.
  static const CoreColor defaultDisabledDividerColor = CoreColor.token(
    CoreColors.disabledOutline,
  );

  /// Default length of the hairline (16 logical px) — shorter than the
  /// segments it parts from the reset button.
  static const double defaultDividerHeight = CoreSize.size16;

  /// Default distance from the last segment to the hairline (6 logical px,
  /// measured edge to edge). The group already puts its own item spacing
  /// between the last segment and the trailing slot, so the resolvers add
  /// only the difference on top of that.
  static const double defaultDividerLeadingSpacing = CoreSpace.space6;

  /// Default spacing between the hairline and the reset button (2 logical
  /// px). The button's square already carries its own inner room around the
  /// glyph, so 2 is enough for both sides of the hairline to read alike.
  static const double defaultTrailingSpacing = CoreSpace.space2;

  /// Per-size rows of the Filter's own chrome. The segments take the same
  /// size from the composed `ToggleGroup` (its own `defaultsBySize`), so
  /// these rows state only what sits beside them. Only `md` and `sm` are
  /// stated; any other [CoreComponentSize] reads the `md` row (see
  /// [sizeDefaults]), and a field a row does not state reads the flat
  /// `defaultX` (the `md` value).
  ///
  /// - `md` — the reset button is the 32 square ([defaultResetButtonStyle])
  ///   and the hairline is 16 long ([defaultDividerHeight]), in the 40
  ///   track (4 + 32 + 4).
  /// - `sm` — the reset button is the 26 square (the `sm` segment height,
  ///   off the size scale like that segment) with the 6 corner of the `sm`
  ///   segment and a 14 glyph; the hairline is 14 long. In the 32 track
  ///   (3 + 26 + 3).
  static const Map<CoreComponentSize, CoreFilterStyle> defaultsBySize = {
    CoreComponentSize.md: CoreFilterStyle(),
    CoreComponentSize.sm: CoreFilterStyle(
      resetButtonStyle: CoreButtonStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
        height: 26,
        width: 26,
        leadingIconStyle: CoreIconStyle(size: CoreIconSize.size14),
      ),
      dividerHeight: CoreSize.size14,
    ),
  };

  /// The size row for [size]: `sm` reads its own row, every other size
  /// reads `md`.
  static CoreFilterStyle sizeDefaults(CoreComponentSize size) =>
      defaultsBySize[size] ?? defaultsBySize[CoreComponentSize.md]!;

  /// Per-variant chrome defaults. The single [CoreFilterVariant.segmented]
  /// variant introduces no extra chrome — colour roles come from the
  /// flat `defaultX` colours above. Kept as a map for structural parity
  /// and future variant extension.
  static const Map<CoreFilterVariant, CoreFilterVariantStyle>
  defaultsByVariant = {
    CoreFilterVariant.segmented: CoreFilterVariantStyle(),
  };

  // ─── Fields ───────────────────────────────────────────────────────

  /// Background fill of the filter container.
  @Deprecated(
    'Use toggleGroupStyle — the segments are a composed ToggleGroup now; '
    'the value still reaches it until removed (since 0.173)',
  )
  final CoreColor? backgroundColor;

  /// Background fill of the currently selected filter item.
  @Deprecated(
    'Use toggleGroupStyle — the segments are a composed ToggleGroup now; '
    'the value still reaches it until removed (since 0.173)',
  )
  final CoreColor? selectedColor;

  /// Container corner radius.
  @Deprecated(
    'Use toggleGroupStyle — the segments are a composed ToggleGroup now; '
    'the value still reaches it until removed (since 0.173)',
  )
  final CoreBorderRadius? borderRadius;

  /// Per-item corner radius.
  @Deprecated(
    'Use toggleGroupStyle — the segments are a composed ToggleGroup now; '
    'the value still reaches it until removed (since 0.173)',
  )
  final CoreBorderRadius? itemBorderRadius;

  /// Padding inside the filter container.
  @Deprecated(
    'Use toggleGroupStyle — the segments are a composed ToggleGroup now; '
    'the value still reaches it until removed (since 0.173)',
  )
  final CoreEdgeInsets? padding;

  /// Padding inside each filter item — the segment's own uniform inset
  /// around `[icon][label box]`.
  ///
  /// Read by both platform resolvers and the Figma builder.
  @Deprecated(
    'Use toggleGroupStyle — the segments are a composed ToggleGroup now; '
    'the value still reaches it until removed (since 0.173)',
  )
  final CoreEdgeInsets? itemPadding;

  /// Inset of the label box inside a segment (painted only when the
  /// item shows its label).
  ///
  /// Read by both platform resolvers and the Figma builder.
  @Deprecated(
    'Use toggleGroupStyle — the segments are a composed ToggleGroup now; '
    'the value still reaches it until removed (since 0.173)',
  )
  final CoreEdgeInsets? labelPadding;

  /// Fixed segment height (logical px); content centres vertically.
  ///
  /// Read by both platform resolvers and the Figma builder.
  @Deprecated(
    'Use toggleGroupStyle — the segments are a composed ToggleGroup now; '
    'the value still reaches it until removed (since 0.173)',
  )
  final double? itemHeight;

  /// Spacing between filter items (logical px). Maps to native
  /// `Row.spacing` on Flutter and CSS flex `gap` on Web.
  @Deprecated(
    'Use toggleGroupStyle — the segments are a composed ToggleGroup now; '
    'the value still reaches it until removed (since 0.173)',
  )
  final double? itemSpacing;

  /// Reset (clear-selection) button style override.
  ///
  /// The single entry point for the reset-affordance chrome — square
  /// side (`width` / `height`), padding, corner radius, hover
  /// transition (`animationDuration`), rest / hover foreground, and
  /// the close glyph (`leadingIconStyle`). Recursively merged onto
  /// [defaultResetButtonStyle] and raw-forwarded to
  /// `Button(variant: .ghost, size: .sm, shape: .square, buttonStyle: …)`
  /// (the `ghost` variant owns the transparent-fill / hover semantics).
  final CoreButtonStyle? resetButtonStyle;

  /// Font weight applied to the currently selected item label (CSS
  /// font-weight integer).
  @Deprecated(
    'Use toggleGroupStyle — the segments are a composed ToggleGroup now; '
    'the value still reaches it until removed (since 0.173)',
  )
  final int? selectedFontWeight;

  /// Selection-state colour transition duration.
  @Deprecated(
    'Use toggleGroupStyle — the segments are a composed ToggleGroup now; '
    'the value still reaches it until removed (since 0.173)',
  )
  final Duration? transitionDuration;

  /// Label text style override applied to every unselected filter
  /// item label and the reset icon. Text colour is carried via
  /// [CoreTextStyle.color] inside this slot (sb8 — raw
  /// `foregroundColor` field removed).
  @Deprecated(
    'Use toggleGroupStyle — the segments are a composed ToggleGroup now; '
    'the value still reaches it until removed (since 0.173)',
  )
  final CoreTextStyle? labelTextStyle;

  /// Label text style override applied to the currently selected item
  /// label. Text colour is carried via [CoreTextStyle.color] inside
  /// this slot (sb8 — raw `selectedForegroundColor` field removed).
  @Deprecated(
    'Use toggleGroupStyle — the segments are a composed ToggleGroup now; '
    'the value still reaches it until removed (since 0.173)',
  )
  final CoreTextStyle? selectedLabelTextStyle;

  /// Style for the icon you pass to an unselected segment — size and
  /// colour. Handed to the `ToggleGroup` that draws the segments (see
  /// [toggleGroupStyle]).
  @Deprecated(
    'Use toggleGroupStyle — the segments are a composed ToggleGroup now; '
    'the value still reaches it until removed (since 0.173)',
  )
  final CoreIconStyle? iconStyle;

  /// Style for the icon you pass to the selected segment. Handed to the
  /// `ToggleGroup` that draws the segments (see [toggleGroupStyle]).
  @Deprecated(
    'Use toggleGroupStyle — the segments are a composed ToggleGroup now; '
    'the value still reaches it until removed (since 0.173)',
  )
  final CoreIconStyle? selectedIconStyle;

  /// Style for each item's `Clickable` — press scale, durations, focus
  /// ring, disabled opacity. Handed to the `ToggleGroup` that draws the
  /// segments (see [toggleGroupStyle]).
  @Deprecated(
    'Use toggleGroupStyle — the segments are a composed ToggleGroup now; '
    'the value still reaches it until removed (since 0.173)',
  )
  final CoreClickableStyle? clickableStyle;

  /// Style for the segments, which are a `ToggleGroup`. Laid over
  /// [defaultToggleGroupStyle] and the deprecated flat fields (see
  /// [toggleGroupStyleFor]), then passed to `ToggleGroup(toggleGroupStyle:)`
  /// as is; the group fills the unset fields with its own defaults.
  final CoreToggleGroupStyle? toggleGroupStyle;

  /// Style of the hairline between the segments and the reset button. Laid
  /// over [defaultDividerStyle] and passed to `Divider(dividerStyle:)` as
  /// is.
  final CoreDividerStyle? dividerStyle;

  /// Colour of the hairline while the filter is disabled. Applied on top of
  /// [dividerStyle] only when the filter is disabled; falls back to
  /// [defaultDisabledDividerColor].
  final CoreColor? disabledDividerColor;

  /// Length of the hairline (logical px).
  final double? dividerHeight;

  /// Distance from the last segment to the hairline (logical px, edge to
  /// edge). Counted from the segment, not from the group's own item gap.
  final double? dividerLeadingSpacing;

  /// Spacing between the hairline and the reset button (logical px).
  final double? trailingSpacing;

  /// The [CoreToggleGroupStyle] the segments are drawn with:
  /// [defaultToggleGroupStyle], then the deprecated flat track / segment
  /// fields, then [toggleGroupStyle] (the new slot wins).
  ///
  /// A flat field that was never stated contributes nothing — the group
  /// keeps its own default — so the fold only carries real overrides.
  CoreToggleGroupStyle toggleGroupStyleFor() {
    // The fold reads the deprecated fields on purpose: it is what keeps an
    // existing override reaching the group.
    final folded = CoreToggleGroupStyle(
      backgroundColor: backgroundColor,
      selectedColor: selectedColor,
      borderRadius: borderRadius,
      itemBorderRadius: itemBorderRadius,
      padding: padding,
      itemPadding: itemPadding,
      labelPadding: labelPadding,
      itemHeight: itemHeight,
      itemSpacing: itemSpacing,
      selectedFontWeight: selectedFontWeight,
      transitionDuration: transitionDuration,
      labelTextStyle: labelTextStyle,
      // The old flat label override reached the chosen segment too, so it is
      // the base of the chosen label; the chosen-only override sits on it.
      selectedLabelTextStyle: _mergeText(
        labelTextStyle,
        selectedLabelTextStyle,
      ),
      iconStyle: iconStyle,
      selectedIconStyle: selectedIconStyle,
      clickableStyle: clickableStyle,
    );
    return defaultToggleGroupStyle.merge(folded).merge(toggleGroupStyle);
  }

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles merge
  /// recursively.
  @override
  CoreFilterStyle merge(CoreFilterStyle? other) {
    if (other == null) return this;
    return CoreFilterStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      selectedColor: other.selectedColor ?? selectedColor,
      borderRadius: other.borderRadius ?? borderRadius,
      itemBorderRadius: other.itemBorderRadius ?? itemBorderRadius,
      padding: other.padding ?? padding,
      itemPadding: other.itemPadding ?? itemPadding,
      labelPadding: other.labelPadding ?? labelPadding,
      itemHeight: other.itemHeight ?? itemHeight,
      itemSpacing: other.itemSpacing ?? itemSpacing,
      resetButtonStyle: _mergeButton(resetButtonStyle, other.resetButtonStyle),
      selectedFontWeight: other.selectedFontWeight ?? selectedFontWeight,
      transitionDuration: other.transitionDuration ?? transitionDuration,
      labelTextStyle: _mergeText(labelTextStyle, other.labelTextStyle),
      selectedLabelTextStyle: _mergeText(
        selectedLabelTextStyle,
        other.selectedLabelTextStyle,
      ),
      iconStyle: iconStyle?.merge(other.iconStyle) ?? other.iconStyle,
      selectedIconStyle:
          selectedIconStyle?.merge(other.selectedIconStyle) ??
          other.selectedIconStyle,
      clickableStyle:
          clickableStyle?.merge(other.clickableStyle) ?? other.clickableStyle,
      toggleGroupStyle:
          toggleGroupStyle?.merge(other.toggleGroupStyle) ??
          other.toggleGroupStyle,
      dividerStyle:
          dividerStyle?.merge(other.dividerStyle) ?? other.dividerStyle,
      disabledDividerColor: other.disabledDividerColor ?? disabledDividerColor,
      dividerHeight: other.dividerHeight ?? dividerHeight,
      dividerLeadingSpacing:
          other.dividerLeadingSpacing ?? dividerLeadingSpacing,
      trailingSpacing: other.trailingSpacing ?? trailingSpacing,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreFilterStyle copyWith({
    CoreColor? backgroundColor,
    CoreColor? selectedColor,
    CoreBorderRadius? borderRadius,
    CoreBorderRadius? itemBorderRadius,
    CoreEdgeInsets? padding,
    CoreEdgeInsets? itemPadding,
    CoreEdgeInsets? labelPadding,
    double? itemHeight,
    double? itemSpacing,
    CoreButtonStyle? resetButtonStyle,
    int? selectedFontWeight,
    Duration? transitionDuration,
    CoreTextStyle? labelTextStyle,
    CoreTextStyle? selectedLabelTextStyle,
    CoreIconStyle? iconStyle,
    CoreIconStyle? selectedIconStyle,
    CoreClickableStyle? clickableStyle,
    CoreToggleGroupStyle? toggleGroupStyle,
    CoreDividerStyle? dividerStyle,
    CoreColor? disabledDividerColor,
    double? dividerHeight,
    double? dividerLeadingSpacing,
    double? trailingSpacing,
  }) {
    return CoreFilterStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      selectedColor: selectedColor ?? this.selectedColor,
      borderRadius: borderRadius ?? this.borderRadius,
      itemBorderRadius: itemBorderRadius ?? this.itemBorderRadius,
      padding: padding ?? this.padding,
      itemPadding: itemPadding ?? this.itemPadding,
      labelPadding: labelPadding ?? this.labelPadding,
      itemHeight: itemHeight ?? this.itemHeight,
      itemSpacing: itemSpacing ?? this.itemSpacing,
      resetButtonStyle: resetButtonStyle ?? this.resetButtonStyle,
      selectedFontWeight: selectedFontWeight ?? this.selectedFontWeight,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      labelTextStyle: labelTextStyle ?? this.labelTextStyle,
      selectedLabelTextStyle:
          selectedLabelTextStyle ?? this.selectedLabelTextStyle,
      iconStyle: iconStyle ?? this.iconStyle,
      selectedIconStyle: selectedIconStyle ?? this.selectedIconStyle,
      clickableStyle: clickableStyle ?? this.clickableStyle,
      toggleGroupStyle: toggleGroupStyle ?? this.toggleGroupStyle,
      dividerStyle: dividerStyle ?? this.dividerStyle,
      disabledDividerColor: disabledDividerColor ?? this.disabledDividerColor,
      dividerHeight: dividerHeight ?? this.dividerHeight,
      dividerLeadingSpacing:
          dividerLeadingSpacing ?? this.dividerLeadingSpacing,
      trailingSpacing: trailingSpacing ?? this.trailingSpacing,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreFilterStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          selectedColor == other.selectedColor &&
          borderRadius == other.borderRadius &&
          itemBorderRadius == other.itemBorderRadius &&
          padding == other.padding &&
          itemPadding == other.itemPadding &&
          labelPadding == other.labelPadding &&
          itemHeight == other.itemHeight &&
          itemSpacing == other.itemSpacing &&
          resetButtonStyle == other.resetButtonStyle &&
          selectedFontWeight == other.selectedFontWeight &&
          transitionDuration == other.transitionDuration &&
          labelTextStyle == other.labelTextStyle &&
          selectedLabelTextStyle == other.selectedLabelTextStyle &&
          iconStyle == other.iconStyle &&
          selectedIconStyle == other.selectedIconStyle &&
          clickableStyle == other.clickableStyle &&
          toggleGroupStyle == other.toggleGroupStyle &&
          dividerStyle == other.dividerStyle &&
          disabledDividerColor == other.disabledDividerColor &&
          dividerHeight == other.dividerHeight &&
          dividerLeadingSpacing == other.dividerLeadingSpacing &&
          trailingSpacing == other.trailingSpacing;

  @override
  int get hashCode => Object.hashAll([
    backgroundColor,
    selectedColor,
    borderRadius,
    itemBorderRadius,
    padding,
    itemPadding,
    labelPadding,
    itemHeight,
    itemSpacing,
    resetButtonStyle,
    selectedFontWeight,
    transitionDuration,
    labelTextStyle,
    selectedLabelTextStyle,
    iconStyle,
    selectedIconStyle,
    clickableStyle,
    toggleGroupStyle,
    dividerStyle,
    disabledDividerColor,
    dividerHeight,
    dividerLeadingSpacing,
    trailingSpacing,
  ]);

  static CoreTextStyle? _mergeText(CoreTextStyle? base, CoreTextStyle? other) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreButtonStyle? _mergeButton(
    CoreButtonStyle? base,
    CoreButtonStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}

/// Variant-dependent chrome for a [CoreFilterVariant].
///
/// `Filter`'s single [CoreFilterVariant.segmented] variant currently
/// introduces no variant-specific chrome — colour roles are shared via
/// the flat `defaultX` colour fields on [CoreFilterStyle]. The class is
/// retained for structural parity so future variants (e.g. an outlined
/// filter bar) can add chrome here without a contract change.
@immutable
class CoreFilterVariantStyle {
  /// Creates a [CoreFilterVariantStyle].
  const CoreFilterVariantStyle();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreFilterVariantStyle && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}
