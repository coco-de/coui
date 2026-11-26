/// Per-instance style for `Tree`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/clickable/clickable_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/size/size.dart' show CoreSize;
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Tree` should render.
///
/// `CoreTreeStyle` carries chrome flat fields for node row + indent
/// line, plus nested node-text / chevron-icon slot styles.
///
/// ```text
/// design system default
///   → CoreTreeTheme.style
///   → parent component slot override
///   → widget.treeStyle
/// ```
@immutable
class CoreTreeStyle implements CoreStyle<CoreTreeStyle> {
  /// Creates a [CoreTreeStyle].
  const CoreTreeStyle({
    this.nodeBackgroundColor,
    this.nodeSelectedColor,
    this.dropTargetColor,
    this.dropIndicatorColor,
    this.nodeHoverColor,
    this.nodePadding,
    this.nodeMinHeight,
    this.rowSpacing,
    this.indent,
    this.borderRadius,
    this.iconStyle,
    this.leafIconStyle,
    this.transitionDuration,
    this.indentLineColor,
    this.indentLineThickness,
    this.nodeTextStyle,
    this.nodeSelectedTextStyle,
    this.chevronIconStyle,
    this.chevronPlaceholderGapStyle,
    this.iconGapStyle,
    this.labelGapStyle,
    this.clickableStyle,
  }) : assert(
         rowSpacing == null || rowSpacing >= 0,
         'rowSpacing must not be negative.',
       );

  // ── Defaults (single source of truth) ────────

  /// Default per-depth indentation (logical px) — one chevron slot (12) plus
  /// the chevron ↔ icon gap (6), so a child's chevron stands where its
  /// parent's icon starts. Shared by Flutter (`EdgeInsets`) and Web (inline
  /// `rem`) resolvers.
  static const double defaultIndent = CoreSpace.space18;

  /// Default indent-guide line thickness.
  static const double defaultIndentLineThickness = CoreStrokeWidth.stroke1;

  /// Default node row padding — 6 on the sides, none above and below. The
  /// row's height comes from [defaultNodeMinHeight], which centres the
  /// label's line box. The left side is the row's inset *before* the
  /// per-depth indent: both platforms start a row's chevron at
  /// `left + depth * indent`. Shared by Flutter and Web resolvers.
  static const CoreEdgeInsets defaultNodePadding = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space6,
  );

  /// Default node row minimum height (logical px) — 28. The label's 21px
  /// line box sits centred in it, and a row stays 28 while its label is
  /// swapped for a taller rename field. It is the row's own height, not a
  /// spacing: density does not move it.
  static const double defaultNodeMinHeight = CoreSize.size28;

  /// Space between visible rows; zero preserves the contiguous tree.
  static const double defaultRowSpacing = CoreSpace.space0;

  /// Default leading folder / file icon style — `size` only (14 logical
  /// px). Shared by Flutter and Web resolvers. Per-instance override flows
  /// through [iconStyle] (merged on top of this default). It sizes the
  /// leading glyph only; the disclosure chevron has its own
  /// [defaultChevronIconStyle].
  static const CoreIconStyle defaultIconStyle = CoreIconStyle(
    size: CoreIconSize.size14,
  );

  /// Default disclosure chevron icon style — 12 logical px in
  /// `onSurfaceSubtle`. Shared by Flutter and Web resolvers. Per-instance
  /// override flows through [chevronIconStyle] (merged on top of this
  /// default). The chevron does not follow [iconStyle]'s size: a caller that
  /// resizes the leading glyph leaves the chevron at 12 unless it also sets
  /// `chevronIconStyle.size`.
  ///
  /// The colour is one constant for every row state: the chevron is a quiet
  /// affordance beside the label, so it does not step up with the selected
  /// label and does not follow the label colour (see [chevronIconStyle]).
  static const CoreIconStyle defaultChevronIconStyle = CoreIconStyle(
    size: CoreIconSize.size12,
    color: CoreColor.token(CoreColors.onSurfaceSubtle),
  );

  /// Default leaf-row (file) icon style — the `onSurfaceSubtle` colour only.
  /// A file is quieter than a folder, so a leaf row's glyph steps down from
  /// [defaultIconColor] (`onSurfaceVariant`, the folder colour). It states no
  /// `size`, so a leaf glyph follows the leading icon size
  /// ([defaultIconStyle], or a caller's [iconStyle]). Per-instance override
  /// flows through [leafIconStyle]; a caller's [iconStyle] `color` sits
  /// between this default and [leafIconStyle], so a colour given to
  /// [iconStyle] alone colours folders and files alike.
  static const CoreIconStyle defaultLeafIconStyle = CoreIconStyle(
    color: CoreColor.token(CoreColors.onSurfaceSubtle),
  );

  /// Default leading folder / file icon glyph colour (`onSurfaceVariant`).
  /// Flutter bakes this token onto the merged leading icon style; Web
  /// emits the matching `text-{token}` class on the icon wrapper `<span>`
  /// so the wrapped `Icon` inherits it via `currentColor`. Per-instance
  /// override flows through [iconStyle]'s `color`.
  static const CoreColor defaultIconColor = CoreColor.token(
    CoreColors.onSurfaceVariant,
  );

  /// Default selected-row background — `surfaceContainerHigh`, opaque: a
  /// neutral container face rather than a tint of the accent. Flutter
  /// resolves it through the active scheme; Web emits the matching
  /// `bg-{token}` class. Per-instance override flows through
  /// [nodeSelectedColor].
  ///
  /// It is the selected row's face and nothing else: the drag-and-drop
  /// affordances have their own colours ([dropTargetColor],
  /// [dropIndicatorColor]) and do not follow it.
  static const CoreColor defaultNodeSelectedColor = CoreColor.token(
    CoreColors.surfaceContainerHigh,
  );

  /// Default drop-target tint — `primary` at 10 % opacity, painted behind a
  /// folder row while a dragged node hovers it as a valid target. Flutter
  /// resolves it through the active scheme; Web emits it as the inline
  /// `background-color` of the target. It is its own colour, not the
  /// selected face, so restyling the selected row does not restyle the drop
  /// target. Per-instance override flows through [dropTargetColor].
  static const CoreColor defaultDropTargetColor = CoreColor.token(
    CoreColors.primary,
    opacity: CoreOpacity.opacity10,
  );

  /// Default drop-indicator colour — solid `primary`: the 2px insertion line
  /// drawn between rows (and across the top edge of a leaf row that is a
  /// valid target) while a node is dragged. Flutter resolves it through the
  /// active scheme; Web emits it as the colour of the line's `border-top`.
  /// Its own colour, like [defaultDropTargetColor]. Per-instance override
  /// flows through [dropIndicatorColor].
  static const CoreColor defaultDropIndicatorColor = CoreColor.token(
    CoreColors.primary,
  );

  /// Default node row border radius (6 — a step value of the radius ladder,
  /// not a role). Flutter consumes via `BorderRadius.circular(...)`, Web via
  /// the `tailwindRadius` adapter extension. The inline rename field takes
  /// the same corner (`CoreTreeRenameRules.fieldStyle`).
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius6,
  );

  /// Default chevron rotate transition duration. Flutter consumes it
  /// directly; Web emits a CSS millisecond value.
  static const Duration defaultTransitionDuration = Duration(
    milliseconds: CoreDuration.fast,
  );

  /// Default leaf-row chevron-placeholder spacer style — `size` only
  /// (12 logical px, matching [defaultChevronIconStyle]). Reserves the slot
  /// the disclosure chevron would occupy on parent rows so leaf nodes stay
  /// horizontally aligned with their siblings. The platform resolvers
  /// override `size` with the effective chevron icon size (so a chevron
  /// resized through [chevronIconStyle] keeps its leaf slot); a per-instance
  /// override flows through [chevronPlaceholderGapStyle] (merged on top).
  static const CoreGapStyle defaultChevronPlaceholderGapStyle = CoreGapStyle(
    size: CoreSpace.space12,
  );

  /// Default chevron-slot ↔ folder/file-icon spacer style — `size` only.
  /// Forwarded straight to `Gap(gapStyle: …)` by the platform resolvers
  /// (raw forward — `Gap` applies its own scaling). Sits between the
  /// disclosure-chevron slot and the leading folder / file icon; a
  /// per-instance override is merged on top via [iconGapStyle].
  static const CoreGapStyle defaultIconGapStyle = CoreGapStyle(
    size: CoreSpace.space6,
  );

  /// Default folder/file-icon ↔ label spacer style — `size` only.
  /// Forwarded straight to `Gap(gapStyle: …)` by the platform resolvers
  /// (raw forward — `Gap` applies its own scaling). Sits between the
  /// leading folder / file icon and the node label; a per-instance
  /// override is merged on top via [labelGapStyle].
  static const CoreGapStyle defaultLabelGapStyle = CoreGapStyle(
    size: CoreSpace.space6,
  );

  /// Default node label text style — unselected state. Carries the
  /// `onSurfaceVariant` content colour (the label is quieter than the page's
  /// body text; the selected label steps up to `onSurface`); the platform
  /// resolvers overlay the `codeSm` typography role (mono 12, fixed 21px
  /// line box) and bind the colour through the active scheme. Per-instance
  /// override flows through [nodeTextStyle] (merged on top).
  ///
  /// The disclosure chevron does not follow this colour (see
  /// [defaultChevronIconStyle]). The inline rename field does not either: its
  /// typed text is pinned to `CoreTreeRenameRules.fieldTextColor`.
  static const CoreTextStyle defaultNodeTextStyle = CoreTextStyle.token(
    CoreTextStyles.codeSm,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Default node label text style — selected state. Carries the
  /// `onSurface` content colour, read on the selected face
  /// ([defaultNodeSelectedColor]); the platform resolvers overlay the
  /// `codeSm` typography role (mono 12, fixed 21px line box) and bind the
  /// colour through the active scheme. Per-instance override flows through
  /// [nodeSelectedTextStyle] (merged on top).
  static const CoreTextStyle defaultNodeSelectedTextStyle = CoreTextStyle.token(
    CoreTextStyles.codeSm,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default nested [CoreClickableStyle] slot for the composed per-row
  /// `Clickable` — a partial that pins `pressedScale: 1.0`: a tree node
  /// row spans the full width, so the boxed press-shrink feedback that
  /// suits compact controls would visibly jump the whole row.
  ///
  /// (Non-interactive rows — a display-only leaf with no `onNodeSelect`
  /// — are not composed with `Clickable` at all, so they keep the
  /// default cursor and never dim; no `disabledOpacity` override is
  /// needed.) Everything else stays null and resolves inside the
  /// Clickable's own resolver via
  /// `defaultClickableStyle.merge(merged.clickableStyle)`.
  static const CoreClickableStyle defaultClickableStyle = CoreClickableStyle(
    pressedScale: 1,
  );

  // ── Node chrome (flat) ───────────────────────

  /// Node row background fill colour.
  ///
  /// Carries no `defaultNodeBackgroundColor`: an unselected, unhovered tree
  /// row paints **no fill** — the file-explorer idiom this component
  /// follows, and the reason [nodeSelectedColor] (which does have a
  /// default) is the only row fill the design system states. Both
  /// platforms express that as absence rather than as a transparent value:
  /// Flutter passes it to `BoxDecoration.color`, where null paints nothing,
  /// and Web skips `emitColor` entirely (`== null ? null : …`) so no
  /// `bg-` class and no inline `background-color` is emitted. A constant
  /// here would put a fill behind every row of every tree.
  final CoreColor? nodeBackgroundColor;

  /// Node row background colour when selected. `null` defers to
  /// [defaultNodeSelectedColor].
  final CoreColor? nodeSelectedColor;

  /// Tint behind a folder row while a dragged node hovers it as a valid drop
  /// target. `null` defers to [defaultDropTargetColor]. Independent of
  /// [nodeSelectedColor]. A leaf row that is a valid target takes the top
  /// edge in [dropIndicatorColor] instead of a tint.
  final CoreColor? dropTargetColor;

  /// Colour of the drop indicator line — the 2px insertion line between rows
  /// and the top edge of a leaf row that is a valid target. `null` defers to
  /// [defaultDropIndicatorColor]. Independent of [nodeSelectedColor].
  final CoreColor? dropIndicatorColor;

  /// Node row background colour on hover.
  ///
  /// Carries no `defaultNodeHoverColor`: absence means the row has no hover
  /// fill, and on Flutter it means the hover *listener is never installed*
  /// — the row composes `Clickable(onHover: nodeHover != null ? … : null)`,
  /// so a constant would both tint every row on hover and start a
  /// `setState` per row per pointer-enter on trees that never asked for it.
  /// Web emits `hover:bg-{token}` (or the scoped raw-colour rule) only when
  /// the slot is set, so the same constant would add a hover state to every
  /// tree there too. Hover feedback on a tree row is opt-in; the cursor and
  /// focus ring the composed `Clickable` owns are what a row gets for free.
  final CoreColor? nodeHoverColor;

  /// Node row padding.
  final CoreEdgeInsets? nodePadding;

  /// Node row minimum height (logical px). Defaults to
  /// [defaultNodeMinHeight].
  final double? nodeMinHeight;

  /// Space between visible rows, outside the selected and hover faces.
  final double? rowSpacing;

  /// Per-depth indent (logical px).
  final double? indent;

  /// Node row border radius. `null` defers to [defaultBorderRadius].
  final CoreBorderRadius? borderRadius;

  /// Leading folder / file icon style override. `size` defers to
  /// [defaultIconStyle]. It does not resize the disclosure chevron — that
  /// is [chevronIconStyle]. A `color` given here colours folder and file
  /// glyphs alike; [leafIconStyle] overrides the file glyph alone.
  final CoreIconStyle? iconStyle;

  /// Leaf-row (file) icon style override, applied on top of [iconStyle] for
  /// leaf rows only. Chain for a leaf glyph, lowest to highest: the leading
  /// default ([defaultIconStyle]) → [defaultLeafIconStyle] (`onSurfaceSubtle`)
  /// → the caller's [iconStyle] → this slot. A branch (folder) row never
  /// reads it.
  final CoreIconStyle? leafIconStyle;

  /// Chevron rotate transition duration. `null` defers to
  /// [defaultTransitionDuration].
  final Duration? transitionDuration;

  // ── Indent line chrome (flat) ────────────────

  /// Indent line colour.
  ///
  /// Carries no `defaultIndentLineColor` because this field is the *switch*
  /// for the whole indent guide, not just its colour. Web computes
  /// `hasIndentLine = indentLineColor != null && depth > 0` and that one
  /// boolean gates `border-left-style`, `border-left-width` **and**
  /// `border-left-color` — which is also why [indentLineThickness] can
  /// safely have a default while this cannot: the thickness default is only
  /// ever reached once this slot is set. A constant here would draw an
  /// indent guide down every nested row of every tree.
  ///
  /// Flutter resolves it (`ResolvedTree.indentLineColor`) but its widget
  /// does not paint an indent guide at all, so the guide is Web-only today.
  /// That asymmetry is a `cross-platform/api.md` gap to close by painting
  /// the guide on Flutter, not by giving this field a value.
  final CoreColor? indentLineColor;

  /// Indent line thickness (logical px).
  final double? indentLineThickness;

  // ── Slot Styles (nested) ─────────────────────

  /// Node label text style override — unselected state. Role and colour
  /// defer to [defaultNodeTextStyle] (`codeSm`, `onSurfaceVariant`).
  final CoreTextStyle? nodeTextStyle;

  /// Node label text style override — selected state. Role and colour
  /// defer to [defaultNodeSelectedTextStyle] (`codeSm`, `onSurface`).
  final CoreTextStyle? nodeSelectedTextStyle;

  /// Disclosure chevron icon style.
  ///
  /// `size` defers to [defaultChevronIconStyle] (12) — it is its own
  /// default and does **not** follow [iconStyle]'s size, so resizing the
  /// leading folder / file glyph leaves the chevron alone. The leaf-row
  /// [chevronPlaceholderGapStyle] reserves the effective chevron width, so a
  /// chevron resized here keeps leaf rows aligned with their siblings.
  ///
  /// `color` defers to [defaultChevronIconStyle] (`onSurfaceSubtle`) and is
  /// the same for every row state — selected or not. Set `color` here to
  /// recolour the chevron for every state.
  final CoreIconStyle? chevronIconStyle;

  /// Space a leaf row keeps where a parent row draws the disclosure
  /// chevron; its `size` is that width, so leaf rows stay aligned with
  /// their siblings. It holds a glyph's place, so it is a fixed width that
  /// density does not change. Laid over [defaultChevronPlaceholderGapStyle].
  final CoreGapStyle? chevronPlaceholderGapStyle;

  /// Space between the chevron slot and the folder / file icon. Laid over
  /// [defaultIconGapStyle] and passed as is to `Gap(gapStyle: …)`, which
  /// applies its own scaling.
  final CoreGapStyle? iconGapStyle;

  /// Space between the folder / file icon and the label. Laid over
  /// [defaultLabelGapStyle] and passed as is to `Gap(gapStyle: …)`, which
  /// applies its own scaling.
  final CoreGapStyle? labelGapStyle;

  /// Style for each row's `Clickable` — press scale, durations, focus ring,
  /// disabled opacity. Laid over [defaultClickableStyle] and passed to the
  /// `Clickable` as is; it fills in the rest.
  final CoreClickableStyle? clickableStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are
  /// merged recursively.
  @override
  CoreTreeStyle merge(CoreTreeStyle? other) {
    if (other == null) return this;
    return CoreTreeStyle(
      nodeBackgroundColor: other.nodeBackgroundColor ?? nodeBackgroundColor,
      nodeSelectedColor: other.nodeSelectedColor ?? nodeSelectedColor,
      dropTargetColor: other.dropTargetColor ?? dropTargetColor,
      dropIndicatorColor: other.dropIndicatorColor ?? dropIndicatorColor,
      nodeHoverColor: other.nodeHoverColor ?? nodeHoverColor,
      nodePadding: other.nodePadding ?? nodePadding,
      nodeMinHeight: other.nodeMinHeight ?? nodeMinHeight,
      rowSpacing: other.rowSpacing ?? rowSpacing,
      indent: other.indent ?? indent,
      borderRadius: other.borderRadius ?? borderRadius,
      iconStyle: _mergeIcon(iconStyle, other.iconStyle),
      leafIconStyle: _mergeIcon(leafIconStyle, other.leafIconStyle),
      transitionDuration: other.transitionDuration ?? transitionDuration,
      indentLineColor: other.indentLineColor ?? indentLineColor,
      indentLineThickness: other.indentLineThickness ?? indentLineThickness,
      nodeTextStyle: _mergeText(nodeTextStyle, other.nodeTextStyle),
      nodeSelectedTextStyle: _mergeText(
        nodeSelectedTextStyle,
        other.nodeSelectedTextStyle,
      ),
      chevronIconStyle: _mergeIcon(chevronIconStyle, other.chevronIconStyle),
      chevronPlaceholderGapStyle: _mergeGap(
        chevronPlaceholderGapStyle,
        other.chevronPlaceholderGapStyle,
      ),
      iconGapStyle: _mergeGap(iconGapStyle, other.iconGapStyle),
      labelGapStyle: _mergeGap(labelGapStyle, other.labelGapStyle),
      clickableStyle:
          clickableStyle?.merge(other.clickableStyle) ?? other.clickableStyle,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreTreeStyle copyWith({
    CoreColor? nodeBackgroundColor,
    CoreColor? nodeSelectedColor,
    CoreColor? dropTargetColor,
    CoreColor? dropIndicatorColor,
    CoreColor? nodeHoverColor,
    CoreEdgeInsets? nodePadding,
    double? nodeMinHeight,
    double? rowSpacing,
    double? indent,
    CoreBorderRadius? borderRadius,
    CoreIconStyle? iconStyle,
    CoreIconStyle? leafIconStyle,
    Duration? transitionDuration,
    CoreColor? indentLineColor,
    double? indentLineThickness,
    CoreTextStyle? nodeTextStyle,
    CoreTextStyle? nodeSelectedTextStyle,
    CoreIconStyle? chevronIconStyle,
    CoreGapStyle? chevronPlaceholderGapStyle,
    CoreGapStyle? iconGapStyle,
    CoreGapStyle? labelGapStyle,
    CoreClickableStyle? clickableStyle,
  }) {
    return CoreTreeStyle(
      nodeBackgroundColor: nodeBackgroundColor ?? this.nodeBackgroundColor,
      nodeSelectedColor: nodeSelectedColor ?? this.nodeSelectedColor,
      dropTargetColor: dropTargetColor ?? this.dropTargetColor,
      dropIndicatorColor: dropIndicatorColor ?? this.dropIndicatorColor,
      nodeHoverColor: nodeHoverColor ?? this.nodeHoverColor,
      nodePadding: nodePadding ?? this.nodePadding,
      nodeMinHeight: nodeMinHeight ?? this.nodeMinHeight,
      rowSpacing: rowSpacing ?? this.rowSpacing,
      indent: indent ?? this.indent,
      borderRadius: borderRadius ?? this.borderRadius,
      iconStyle: iconStyle ?? this.iconStyle,
      leafIconStyle: leafIconStyle ?? this.leafIconStyle,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      indentLineColor: indentLineColor ?? this.indentLineColor,
      indentLineThickness: indentLineThickness ?? this.indentLineThickness,
      nodeTextStyle: nodeTextStyle ?? this.nodeTextStyle,
      nodeSelectedTextStyle:
          nodeSelectedTextStyle ?? this.nodeSelectedTextStyle,
      chevronIconStyle: chevronIconStyle ?? this.chevronIconStyle,
      chevronPlaceholderGapStyle:
          chevronPlaceholderGapStyle ?? this.chevronPlaceholderGapStyle,
      iconGapStyle: iconGapStyle ?? this.iconGapStyle,
      labelGapStyle: labelGapStyle ?? this.labelGapStyle,
      clickableStyle: clickableStyle ?? this.clickableStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreTreeStyle &&
          runtimeType == other.runtimeType &&
          nodeBackgroundColor == other.nodeBackgroundColor &&
          nodeSelectedColor == other.nodeSelectedColor &&
          dropTargetColor == other.dropTargetColor &&
          dropIndicatorColor == other.dropIndicatorColor &&
          nodeHoverColor == other.nodeHoverColor &&
          nodePadding == other.nodePadding &&
          nodeMinHeight == other.nodeMinHeight &&
          rowSpacing == other.rowSpacing &&
          indent == other.indent &&
          borderRadius == other.borderRadius &&
          iconStyle == other.iconStyle &&
          leafIconStyle == other.leafIconStyle &&
          transitionDuration == other.transitionDuration &&
          indentLineColor == other.indentLineColor &&
          indentLineThickness == other.indentLineThickness &&
          nodeTextStyle == other.nodeTextStyle &&
          nodeSelectedTextStyle == other.nodeSelectedTextStyle &&
          chevronIconStyle == other.chevronIconStyle &&
          chevronPlaceholderGapStyle == other.chevronPlaceholderGapStyle &&
          iconGapStyle == other.iconGapStyle &&
          labelGapStyle == other.labelGapStyle &&
          clickableStyle == other.clickableStyle;

  @override
  int get hashCode => Object.hashAll([
    nodeBackgroundColor,
    nodeSelectedColor,
    dropTargetColor,
    dropIndicatorColor,
    nodeHoverColor,
    nodePadding,
    nodeMinHeight,
    rowSpacing,
    indent,
    borderRadius,
    iconStyle,
    leafIconStyle,
    transitionDuration,
    indentLineColor,
    indentLineThickness,
    nodeTextStyle,
    nodeSelectedTextStyle,
    chevronIconStyle,
    chevronPlaceholderGapStyle,
    iconGapStyle,
    labelGapStyle,
    clickableStyle,
  ]);

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
