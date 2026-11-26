import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

// ═══════════════════════════════════════════════════
// Resolved output — group container
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `RadioGroup`.
///
/// DOM shape:
///
/// ```text
/// root (<div role="radiogroup">)
///   └─ children (Radio instances; each emits its own DOM tree —
///                see ResolvedRadioOption)
/// ```
///
/// `co_radio_group.dart` reads `resolved.root.className` /
/// `resolved.root.inlineStyles` straight off — no merge / fallback /
/// conversion in the widget body.
///
/// Per Epic #1603 (옵션 B 최종, single inline signature) every chrome
/// value (item gap) is emitted **inline** through
/// `'${(merged.X ?? default) / kRemDivisor}rem'` — no class-drop branch
/// decides between a `gap-*` Tailwind utility and an inline rule. Only
/// structural (`flex` / `flex-row` / `flex-col` / `flex-wrap`) classes
/// remain on the className surface.
///
/// The resolver carries only:
/// * Cat 1 — `WebElementChrome` slot ([root]) for the group container.
/// * Cat 2 — nested `CoreRadioGroupStyle` slot ([radioGroupStyle])
///   forwarded to [resolveRadioOption] so the per-item resolver does
///   not re-run the merge chain.
///
/// No scalar metadata (variant / size / orientation) is exposed —
/// semantic identifiers stay on the widget prop and the per-item
/// resolver receives them as function arguments.
class ResolvedRadioGroup implements WebResolvedChrome {
  /// Creates a [ResolvedRadioGroup].
  const ResolvedRadioGroup({
    required this.root,
    required this.radioGroupStyle,
  });

  /// Paint-ready chrome for the outermost `<div role="radiogroup">`
  /// container — orientation-driven flex layout plus inline item-gap.
  @override
  final WebElementChrome root;

  /// Nested [CoreRadioGroupStyle] slot — the fully-merged Style bundle
  /// (`design-system default → theme.style → matching variant style
  /// → widget.radioGroupStyle`) forwarded to [resolveRadioOption] so
  /// the per-item resolver consumes a single source of truth.
  final CoreRadioGroupStyle radioGroupStyle;
}

// ═══════════════════════════════════════════════════
// Resolved output — per-option (Radio)
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for a single Web `Radio` item.
///
/// DOM shape:
///
/// ```text
/// root (<label>)                        // radio renders only when label / prefix / suffix / hidden input is present; otherwise renders `button` directly
///   ├─ <style>                          // scoped hover / active halo rules (ResolvedRadioRules), enabled only
///   ├─ hiddenInput (<input>)            // radio renders only when name != null
///   ├─ prefix                           // caller-supplied
///   ├─ Gap(gapStyle: indicatorLabelGapStyle)  // rendered only when prefix != null
///   ├─ button (<div role="radio">)      // wrapped in FocusOutline; `relative`; the ring is its border
///   │    ├─ halo (<div>)                // absolute, `spread` beyond the border box on every side — the hover / pressed state layer
///   │    └─ dot (<div>)                 // inner-dot always mounted (scale-anim); zero-size unless restated
///   ├─ Gap(gapStyle: indicatorLabelGapStyle)  // rendered only when label / description / suffix present
///   ├─ label text | content             // label alone, or the column below once a description is present
///   └─ suffix                           // caller-supplied; inside content once a description is present
///
/// content (<span>)                      // flex column — the label slot over the description
///   ├─ label text | suffix | labelLine  // whichever fills the label slot; omitted when neither is set
///   │    └─ (labelLine) label text · suffix   // only when both are set
///   ├─ Gap(gapStyle: labelDescriptionGapStyle)  // rendered only when the label slot is filled
///   └─ description (<span>)
/// ```
///
/// The `card` variant draws the same row inside a tile and moves the
/// state layer and the focus ring onto it:
///
/// ```text
/// FocusOutline (<div>, tileFocusOutlineStyle)   // the ring around the tile
///   └─ root (<label>)                   // the tile — face, border, corner, padding; clips its children
///        ├─ <style> · hiddenInput
///        ├─ tileStateLayer (<div>)      // absolute, the whole face — hover / pressed layer
///        └─ tileBody (<span>)           // positioned row over the layer
///             └─ prefix · Gap · button · Gap · label | content · suffix
///                                  // button: no halo, no ring of its own
/// ```
///
/// The halo's opacity is driven by `:hover` / `:active` on the ROOT
/// (label included — the whole row is the hit area), through the scoped
/// rules in [ResolvedRadioRules]; the root wears that resolver's
/// `scopeClass` so the selectors reach the halo one or two levels in.
///
/// All slot chromes are non-null — `co_radio` decides whether to render
/// each optional slot based on instance state.
///
/// Per Epic #1603 (옵션 B 최종, single inline signature) every chrome
/// value (width / height / border width / colour / label colour)
/// is emitted **inline** through `(merged.X ?? default).toValue()` / rem
/// — no class-drop branch decides between a Tailwind utility and an
/// inline rule. The indicator↔label gap is owned by the nested
/// [indicatorLabelGapStyle] slot and rendered via `Gap` (which runs
/// its own resolve step), mirroring the Flutter widget. Only the label
/// typography **role** token class (`text-body-small`), structural
/// (`inline-flex` / `rounded-full` / `flex` / `shrink-0` / `select-none`)
/// and pseudo-state (`cursor-*` / `outline-none` / transition +
/// scale) classes remain on the className surface.
class ResolvedRadioOption implements WebResolvedChrome {
  /// Creates a [ResolvedRadioOption].
  const ResolvedRadioOption({
    required this.root,
    required this.button,
    required this.halo,
    required this.dot,
    required this.indicatorLabelGapStyle,
    required this.content,
    required this.labelLine,
    required this.description,
    required this.labelDescriptionGapStyle,
    required this.tileBody,
    required this.tileStateLayer,
    required this.tileFocusOutlineStyle,
  });

  /// Paint-ready chrome for the outer `<label>` wrapper. `co_radio`
  /// falls back to a bare button (no wrapper) when label / prefix /
  /// suffix / hidden input are all absent and skips this slot in that
  /// branch.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the `<div role="radio">` circle.
  final WebElementChrome button;

  /// Paint-ready chrome for the halo `<div>` — the state layer standing
  /// `stateLayerSpread` outside the circle. Mounted at opacity 0; the
  /// scoped rules in [ResolvedRadioRules] raise it on hover / active.
  final WebElementChrome halo;

  /// Paint-ready chrome for the inner dot `<div>`.
  final WebElementChrome dot;

  /// Nested [CoreGapStyle] slot — passed to `Gap(gapStyle: …)` on
  /// either side of the indicator (between prefix↔indicator and
  /// indicator↔label/suffix). `Gap` runs its own resolve / scaling
  /// step, so this slot stays as the merged design-system default +
  /// per-instance override in pre-scaling units (mirrors the Flutter
  /// widget's [CoreGapStyle] forwarding).
  final CoreGapStyle indicatorLabelGapStyle;

  /// Paint-ready chrome for the column that stacks the label slot over the
  /// description — rendered only when a description is present, so a
  /// labelled radio without one has no extra wrapper.
  final WebElementChrome content;

  /// Paint-ready chrome for the label slot's own row inside [content] — the
  /// label and the suffix side by side, the way the plain row lays them
  /// out. Rendered only when a description is present and both are set, so
  /// the description sits under the whole label slot, as it does under the
  /// Flutter twin's.
  final WebElementChrome labelLine;

  /// Paint-ready chrome for the description line — its own role and
  /// foreground classes, which override the label typography the root
  /// puts on the whole row.
  final WebElementChrome description;

  /// Nested [CoreGapStyle] slot for the vertical gap between the label and
  /// the description — passed to `Gap(gapStyle: …)` inside [content].
  final CoreGapStyle labelDescriptionGapStyle;

  /// Paint-ready chrome for the card's inner row — positioned, so it
  /// paints over [tileStateLayer] and the layer washes the face, not the
  /// text. Read only by the `card` variant.
  final WebElementChrome tileBody;

  /// Paint-ready chrome for the card's state layer — the whole face,
  /// mounted at opacity 0; the scoped rules in [ResolvedRadioRules] raise it
  /// on hover / active through the same marker the halo wears. Read only by
  /// the `card` variant.
  final WebElementChrome tileStateLayer;

  /// Focus-ring slot for the card — the tile's own corner, so the ring
  /// around a focused tile stays concentric with it. Read only by the
  /// `card` variant.
  final CoreFocusOutlineStyle tileFocusOutlineStyle;
}

/// Scoped CSS text for `<style>` block in `Radio`. Carries the hover /
/// pressed halo weights — pseudo-state opacity has no preset Tailwind
/// class at the ramp's weights, and the halo lives inside the element the
/// pointer rests on, so the rule is `scope:hover halo` rather than a
/// class on the halo itself. Empty on the disabled path.
class ResolvedRadioRules {
  /// Creates a [ResolvedRadioRules].
  const ResolvedRadioRules({required this.scopeClass, required this.css});

  /// Class the radio's root wears, and the class the CSS text below
  /// selects on. Empty exactly when [css] is empty.
  final String scopeClass;

  /// Raw CSS rule text — empty on the disabled path.
  final String css;
}

/// The class the halo `<div>` wears so the scoped rules can reach it.
const String kRadioHaloMarker = 'co-radio-halo';

/// The resting opacity of every layer wearing [kRadioHaloMarker] — a class,
/// never an inline declaration.
///
/// An inline declaration beats every stylesheet rule that lacks
/// `!important`, whatever its specificity, so an inline `opacity: 0` would
/// hold the layer at 0 under the scoped `:hover` / `:active` rules in
/// [ResolvedRadioRules] and the wash would never show. As a class (0,1,0)
/// it loses to those rules (0,3,0). A disabled row wears no scope class, so
/// nothing raises it there.
const String _kRadioHaloRestClass = 'opacity-0';

// ═══════════════════════════════════════════════════
// Resolver — group container (single entry point)
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedRadioGroup] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.radioGroup.style
///   → theme.coreComponentTheme.radioGroup.variantStyles[variant]
///   → widget.radioGroupStyle
/// ```
///
/// The merged [CoreRadioGroupStyle] is forwarded on the resolved bundle
/// so [resolveRadioOption] consumes it directly without re-running
/// the merge chain.
ResolvedRadioGroup resolveRadioGroup(
  BuildContext context, {
  required CoreRadioGroupVariant variant,
  required CoreComponentSize size,
  required CoreRadioGroupOrientation orientation,
  CoreRadioGroupStyle? radioGroupStyle,
}) {
  final csTheme = context.theme.coreComponentTheme?.radioGroup;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreRadioGroupStyle(), [
    csTheme?.style,
    csTheme?.variantStyles?[variant],
    radioGroupStyle,
  ]);

  // ─── Token tables ─────────────────────────────────────
  // The size layer — the `card` variant's tile row laid over the size row
  // (`CoreRadioGroupStyle.sizeDefaultsFor` owns the order).
  final sizeStyle = CoreRadioGroupStyle.sizeDefaultsFor(variant, size);

  // ─── Resolved chrome values (single inline signature) ──
  // Item spacing — caller override wins, else size-default. The slot is
  // a raw `double?` (native-API spacing — Flutter `Wrap.spacing` /
  // `Column.spacing`, Web flex `gap` CSS) and the resolver reads it
  // straight through, emitting the inline `gap` rule below.
  final itemSpacing = merged.itemSpacing ?? sizeStyle.itemSpacing!;

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer radio group container Tailwind className —
  /// orientation-driven flex direction only (the item gap lives inline).
  /// A column stretches its items, which is what makes card tiles span
  /// the group's width; a row of cards keeps each tile at its own height
  /// (`items-start`), the Flutter twin's `Wrap`.
  String buildRootClassName() => orientation == .horizontal
      ? <String>[
          WebLayout.flex,
          WebLayout.flexRow,
          WebLayout.flexWrap,
          if (variant == .card) WebLayout.itemsStart,
        ].join(' ')
      : '${WebLayout.flex} ${WebLayout.flexCol}';

  /// Composes the outer radio group container inline-CSS bundle — emits
  /// the resolved item `gap` (single inline signature).
  Styles buildRootInlineStyles() => .new(raw: {'gap': spaceCss(itemSpacing)});

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedRadioGroup(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    radioGroupStyle: merged,
  );
}

// ═══════════════════════════════════════════════════
// Resolver — per-option (Radio)
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedRadioOption] for a single radio item inside a
/// [resolveRadioGroup].
///
/// Reads the merged [CoreRadioGroupStyle] off [group] so the per-item
/// chrome composes from the same source of truth without re-running
/// the merge chain. [variant] / [size] are scalar arguments — they
/// drive the per-variant / per-size token-table lookups and stay off
/// the resolved class (semantic identifiers live on the widget).
ResolvedRadioOption resolveRadioOption(
  BuildContext context, {
  required ResolvedRadioGroup group,
  required CoreRadioGroupVariant variant,
  required CoreComponentSize size,
  required bool isSelected,
  required bool enabled,
  // Whether the caller supplied a description — a build-time semantic
  // input like `enabled`, not an interaction state, so it belongs in the
  // resolver signature (widget/render-only.md). It picks the row's
  // cross-axis alignment.
  bool hasDescription = false,
}) {
  // ─── Token tables ─────────────────────────────────────
  final variantStyle = CoreRadioGroupStyle.defaultsByVariant[variant]!;
  // The size layer — the card's tile row over the size row, so every
  // `?? sizeStyle.X` below reads the tile's indicator, gaps and text roles
  // when the group is a card.
  final sizeStyle = CoreRadioGroupStyle.sizeDefaultsFor(variant, size);
  // The tile's own geometry, read straight off the card table so the tile
  // chrome below resolves for every variant (only `card` mounts it).
  final tileRow = CoreRadioGroupStyle.cardDefaultsBySize[size]!;
  final isCard = variant == .card;
  final merged = group.radioGroupStyle;

  // ─── Resolved chrome values (single inline signature) ──
  // Inner dot icon style — the design-system default slot merged with
  // the per-instance override. Carries the optional dot colour override.
  final indicatorDotStyle = CoreRadioGroupStyle.defaultIndicatorDotStyle.merge(
    merged.indicatorDotStyle,
  );

  // Dimensional chrome — caller override wins, else size-default. All
  // emitted inline below.
  final indicatorSize = merged.indicatorSize ?? sizeStyle.indicatorSize!;
  final stateLayerSpread =
      merged.stateLayerSpread ?? CoreRadioGroupStyle.defaultStateLayerSpread;
  final innerDotSize = merged.innerDotSize ?? sizeStyle.innerDotSize!;
  final dotSize = indicatorDotStyle.size ?? innerDotSize;
  // Indicator → label gap — merge the size-bucket nested gap-style slot
  // with the per-instance override. The merged slot is forwarded on
  // [ResolvedRadioOption.indicatorLabelGapStyle] so `co_radio` can
  // render a `Gap(gapStyle: …)` widget on either side of the indicator
  // (mirroring the Flutter widget). `Gap` runs its own resolve /
  // scaling step, so this slot stays in pre-scaling units.
  final indicatorLabelGapStyle =
      (sizeStyle.indicatorLabelGapStyle ?? const CoreGapStyle()).merge(
        merged.indicatorLabelGapStyle,
      );
  // Ring stroke. The selected ring is thicker than the resting one — the
  // selection is the ring, not a dot — and reads its own statement, else
  // this size's row, else the resting width (a size whose row states none).
  // Disabled does not change that: the selection is the ring, so a disabled
  // selected ring keeps the selected width — the same split the Flutter twin
  // makes (`disabledSelectedRingContainerStyle` /
  // `disabledUnselectedRingContainerStyle`).
  final restingBorderWidth =
      merged.indicatorBorderWidth ?? sizeStyle.indicatorBorderWidth!;
  final selectedBorderWidth =
      merged.selectedIndicatorBorderWidth ??
      sizeStyle.selectedIndicatorBorderWidth ??
      restingBorderWidth;
  final borderWidth = isSelected ? selectedBorderWidth : restingBorderWidth;
  final ringRadius =
      merged.indicatorBorderRadius ??
      CoreRadioGroupStyle.defaultIndicatorBorderRadius;

  // Colour / dot transition durations — caller override wins, else
  // design-system default. The existing CSS adapter retains token
  // remapping and arbitrary durations on each animated slot.
  final colorTransitionMs =
      (merged.colorTransitionDuration ??
              CoreRadioGroupStyle.defaultColorTransitionDuration)
          .inMilliseconds;
  final dotTransitionMs =
      (merged.dotTransitionDuration ??
              CoreRadioGroupStyle.defaultDotTransitionDuration)
          .inMilliseconds;

  // ─── Variant state base colours ───────────────────────
  // Pick the [CoreColor] base for each surface from the per-state branch
  // (`enabled` / `selected` / `unselected`). These are platform-neutral
  // `CoreColor`s only (variant token table) — the per-channel user
  // override is passed separately to `emitColor` below so a token-bound
  // base emits a Tailwind class (dark-mode reactive) while a raw override
  // goes inline. The override is only honoured in the enabled states
  // (disabled colours are fixed by the variant table).
  final CoreColor bgBase;
  final CoreColor borderBase;
  final CoreColor dotBase;
  final CoreColor? bgOverride;
  final CoreColor? borderOverride;
  final CoreColor? dotOverride;
  if (!enabled) {
    bgBase = variantStyle.disabledBackgroundColor;
    // A disabled selected ring reads in the disabled-content colour — the one
    // a disabled "on" state reads in — and an unselected one rests on the
    // disabled outline. With the dot gone, this colour and the width above
    // are all that tell a disabled selected radio from an unselected one.
    borderBase = isSelected
        ? variantStyle.disabledActiveColor
        : variantStyle.disabledBorderColor;
    dotBase = variantStyle.disabledActiveColor;
    bgOverride = null;
    borderOverride = null;
    dotOverride = null;
  } else if (isSelected) {
    bgBase = variantStyle.uncheckedBackground;
    borderBase = variantStyle.activeColor;
    dotBase = variantStyle.activeColor;
    bgOverride = merged.indicatorBackgroundColor;
    borderOverride = merged.indicatorActiveColor;
    // Inner dot: slot-level dot colour wins over the group active override.
    dotOverride = indicatorDotStyle.color ?? merged.indicatorActiveColor;
  } else {
    bgBase = variantStyle.uncheckedBackground;
    borderBase = variantStyle.borderColor;
    dotBase = variantStyle.activeColor;
    bgOverride = merged.indicatorBackgroundColor;
    borderOverride = merged.indicatorBorderColor;
    dotOverride = indicatorDotStyle.color ?? merged.indicatorActiveColor;
  }

  // Label text — role + colour from the design-system default, this
  // size's `fontSize` step from the size row, then the per-instance
  // overlay. Disabled swaps only the foreground for the variant's disabled
  // token; a caller's own colour is honoured while enabled. Same shape
  // Checkbox's Web resolver uses.
  final effectiveLabelColor = enabled
      ? (merged.labelStyle?.color ??
            CoreRadioGroupStyle.defaultLabelStyle.color!)
      : variantStyle.disabledForegroundColor;
  final labelStyleForEmit = CoreRadioGroupStyle.defaultLabelStyle
      .merge(sizeStyle.labelStyle)
      .merge(merged.labelStyle)
      .copyWith(color: effectiveLabelColor);

  // Description — the same three-step chain with the quieter foreground,
  // and the label's fold onto the variant's disabled foreground.
  final effectiveDescriptionColor = enabled
      ? (merged.descriptionStyle?.color ??
            CoreRadioGroupStyle.defaultDescriptionStyle.color!)
      : variantStyle.disabledForegroundColor;
  final descriptionStyleForEmit = CoreRadioGroupStyle.defaultDescriptionStyle
      .merge(sizeStyle.descriptionStyle)
      .merge(merged.descriptionStyle)
      .copyWith(color: effectiveDescriptionColor);
  // The size layer states this gap only for the card; a plain row falls to
  // the design-system default beneath it.
  final labelDescriptionGapStyle = CoreRadioGroupStyle
      .defaultLabelDescriptionGapStyle
      .merge(sizeStyle.labelDescriptionGapStyle)
      .merge(merged.labelDescriptionGapStyle);

  // ─── Card tile values ─────────────────────────────────
  // The selected tile wears a heavier stroke without moving anything: the
  // in-flow border stays at the resting width in every state, and the
  // selected tile paints the difference as an inset `box-shadow` in its
  // border colour — paint only, no layout, so neither the content nor the
  // box shifts (and nothing layout-affecting animates). The Flutter twin
  // draws the real border and takes the difference off its padding; the
  // content lands at padding + resting width on both. A disabled tile keeps
  // its face and width and takes the variant's disabled outline for its
  // edge, honouring no border override, like the disabled ring.
  final tileBorderRadius = merged.tileBorderRadius ?? tileRow.tileBorderRadius!;
  final tileBorderWidth =
      merged.tileBorderWidth ?? CoreRadioGroupStyle.defaultTileBorderWidth;
  final tileSelectedBorderWidth =
      merged.tileSelectedBorderWidth ??
      CoreRadioGroupStyle.defaultTileSelectedBorderWidth;
  // Measured in CSS, between the two widths' stroke variables, so the inset
  // follows a style that bends strokes the way the Flutter twin's
  // `theme.geometry.stroke()` difference does. A selected width under the
  // resting one draws at the resting one.
  final selectedPaddingOverride = merged.tileSelectedPadding;
  final independentSelectedPadding =
      isSelected && selectedPaddingOverride != null;
  final tileInsetStroke =
      isSelected &&
      !independentSelectedPadding &&
      tileSelectedBorderWidth > tileBorderWidth;
  final tilePadding = independentSelectedPadding
      ? selectedPaddingOverride
      : merged.tilePadding ?? tileRow.tilePadding!;
  final tileLayoutBorderWidth =
      independentSelectedPadding && tileSelectedBorderWidth > tileBorderWidth
      ? tileSelectedBorderWidth
      : tileBorderWidth;
  final CoreColor tileBackgroundBase;
  final CoreColor tileBorderBase;
  final CoreColor? tileBackgroundOverride;
  final CoreColor? tileBorderOverride;
  if (isSelected) {
    tileBackgroundBase = CoreRadioGroupStyle.defaultTileSelectedBackgroundColor;
    tileBackgroundOverride = merged.tileSelectedBackgroundColor;
  } else {
    tileBackgroundBase = CoreRadioGroupStyle.defaultTileBackgroundColor;
    tileBackgroundOverride = merged.tileBackgroundColor;
  }
  if (!enabled) {
    tileBorderBase = variantStyle.disabledBorderColor;
    tileBorderOverride = null;
  } else if (isSelected) {
    tileBorderBase = CoreRadioGroupStyle.defaultTileSelectedBorderColor;
    tileBorderOverride = merged.tileSelectedBorderColor;
  } else {
    tileBorderBase = CoreRadioGroupStyle.defaultTileBorderColor;
    tileBorderOverride = merged.tileBorderColor;
  }
  // The ring around a focused tile follows the tile's corner.
  final tileFocusOutlineStyle = CoreFocusOutlineStyle(
    borderRadius: tileBorderRadius,
  );

  // ─── EMIT Stage 2 (Web, theme-free) ───────────────────
  // Each colour / typography value routes through the emit family — a
  // single class-XOR-inline decision per design value. Token-bound bases
  // (variant token table) emit Tailwind classes that stay dark-mode
  // reactive, raw overrides go inline. No `scheme.resolve` (a no-op on
  // Web).
  final buttonBackgroundEmit = emitColor(bgOverride, bgBase, .background);
  final buttonBorderEmit = emitColor(borderOverride, borderBase, .border);
  final dotEmit = emitColor(dotOverride, dotBase, .background);
  // The halo's ink — mounted at opacity 0; the scoped rules raise it.
  final haloEmit = emitColor(
    merged.stateLayerColor,
    CoreRadioGroupStyle.defaultStateLayerColor,
    .background,
  );

  // Label typography — `emitTypography` emits the role on a
  // `text-body-small` class (dark-mode / accessibility-scale reactive,
  // inherited by the label text node), the state-resolved colour as a
  // `text-{token}` class, AND the explicit scalar overlay (this size's
  // `fontSize` step, any caller weight) inline.
  final labelTypographyEmit = emitTypography(
    labelStyleForEmit,
    CoreRadioGroupStyle.defaultLabelStyle,
  );
  final descriptionTypographyEmit = emitTypography(
    descriptionStyleForEmit,
    CoreRadioGroupStyle.defaultDescriptionStyle,
  );
  final tileBackgroundEmit = emitColor(
    tileBackgroundOverride,
    tileBackgroundBase,
    .background,
  );
  final tileBorderEmit = emitColor(
    tileBorderOverride,
    tileBorderBase,
    .border,
  );

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer `<label>` wrapper Tailwind className —
  /// structural layout, the label typography **role** + colour classes
  /// ([labelTypographyEmit] — inherited by the label text node), a
  /// cursor pseudo-state hint, and `select-none`. Raw colour / typography
  /// overlays live inline; the indicator↔label gap is rendered by sibling
  /// `Gap` widgets in `radio_group.dart`.
  ///
  /// For a card the root is the tile: a block-level flex box that clips
  /// its children to its corner (the state layer inside follows it),
  /// recolours on the ring's clock, and wears the tile's face / border
  /// classes. Like the ring, an enabled tile is marked as a component
  /// surface — the Flutter twin composes `OutlinedContainer` for it — and
  /// takes the style's cast when it states none of its own.
  String buildRootClassName() => <String>[
    if (isCard) ...[
      kControlShadowRestMarker,
      WebLayout.flex,
      WebLayout.relative,
      WebLayout.overflowHidden,
      'transition-colors',
      tileBackgroundEmit.className,
      tileBorderEmit.className,
      if (enabled) ...webSurfaceMarkerFor(.content),
    ] else if (hasDescription)
      // Top-aligned once a description is present — centring the ring
      // against a two-line block floats it against neither line.
      '${WebLayout.inlineFlex} ${WebLayout.itemsStart}'
    else
      WebLayout.inlineFlexItemsCenter,
    labelTypographyEmit.className,
    'select-none',
    if (enabled) 'cursor-pointer' else 'cursor-not-allowed',
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the outer `<label>` wrapper inline-CSS bundle — the
  /// emit-family inline fragments (raw foreground colour override + the
  /// explicit `labelStyle` typography overlay) plus any `font-family`
  /// override (`toInlineCss` does not cover it). The indicator↔label gap
  /// is rendered by `Gap` widgets on either side of the indicator
  /// (see [ResolvedRadioOption.indicatorLabelGapStyle]).
  ///
  /// A card adds the tile's padding, corner and stroke, any raw tile colour
  /// override, and the fill it publishes for a material preset.
  Styles buildRootInlineStyles() => .new(
    raw: {
      ...?labelTypographyEmit.inline,
      if (isCard) ...{
        'transition-duration': durationMsCss(colorTransitionMs),
        'padding': tilePadding.toValue(),
        'border-radius': tileBorderRadius.toValue(),
        'border-width': strokeWidthCss(tileLayoutBorderWidth),
        'border-style': 'solid',
        ...?tileBackgroundEmit.inline,
        ...?tileBorderEmit.inline,
        // The selected stroke's extra width, drawn inward over the padding,
        // then the cast the style contributes to a surface that states none —
        // the value the rest marker would have given, which this inline
        // declaration out-ranks.
        if (tileInsetStroke)
          'box-shadow':
              'inset 0 0 0 calc(${strokeWidthCss(tileSelectedBorderWidth)} - '
              '${strokeWidthCss(tileBorderWidth)}) '
              '${(tileBorderOverride ?? tileBorderBase).toValue()}, '
              '$kControlShadowVar',
        if (enabled)
          ...surfaceFillVar(tileBackgroundOverride ?? tileBackgroundBase),
      },
    },
  );

  /// Composes the description-column `<span>` Tailwind className — the
  /// label slot stacked over the description. The gap between them is a `Gap`
  /// child (Flutter parity), not a `gap-*` class.
  String buildContentClassName() =>
      '${WebLayout.flex} ${WebLayout.flexCol} ${WebLayout.itemsStart} '
      '${WebLayout.minWZero}';

  /// Composes the label-slot row `<span>` Tailwind className — the label
  /// and the suffix in a row, centred like the plain row they come from.
  String buildLabelLineClassName() =>
      '${WebLayout.flexItemsCenter} ${WebLayout.minWZero}';

  /// Composes the description `<span>` Tailwind className — its own role
  /// and colour classes, overriding the label typography on the root.
  String buildDescriptionClassName() => <String>[
    WebLayout.minWZero,
    descriptionTypographyEmit.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the description `<span>` inline-CSS bundle — the raw colour /
  /// scalar overlay only (token role + colour stay on classes above).
  Styles? buildDescriptionInlineStyles() {
    final inline = descriptionTypographyEmit.inline;
    return inline == null ? null : Styles(raw: inline);
  }

  /// Composes the card's inner row `<span>` Tailwind className —
  /// positioned so it paints over the state layer, with the plain row's
  /// alignment rule.
  String buildTileBodyClassName() => <String>[
    WebLayout.relative,
    WebLayout.flex,
    if (hasDescription) WebLayout.itemsStart else WebLayout.itemsCenter,
    WebLayout.minWZero,
  ].join(' ');

  /// Composes the card's state-layer `<div>` Tailwind className — the
  /// whole face, inert to the pointer, on the ring's clock, in the halo's
  /// ink, and wearing the halo's marker so the same scoped rules raise it.
  /// Rests at [_kRadioHaloRestClass] for the reason given there.
  String buildTileStateLayerClassName() => <String>[
    kRadioHaloMarker,
    _kRadioHaloRestClass,
    WebLayout.absoluteFull,
    WebLayout.pointerEventsNone,
    'transition-opacity',
    haloEmit.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the card's state-layer `<div>` inline-CSS bundle — any raw
  /// ink override only. The resting opacity is a class (see
  /// [buildTileStateLayerClassName]); the tile clips the layer to its
  /// corner.
  Styles? buildTileStateLayerInlineStyles() {
    return Styles(
      raw: {
        'transition-duration': durationMsCss(colorTransitionMs),
        ...?haloEmit.inline,
      },
    );
  }

  /// Composes the halo `<div>` Tailwind className — absolutely placed
  /// inside the (`relative`) circle, inert to the pointer, on the ring's
  /// colour clock, and the resolved ink class ([haloEmit] — token-bound →
  /// `bg-{token}`, dark-mode reactive). Its marker class is what the
  /// scoped hover / active rules select on; it rests at
  /// [_kRadioHaloRestClass] for the reason given there.
  String buildHaloClassName() => <String>[
    kRadioHaloMarker,
    _kRadioHaloRestClass,
    WebLayout.absolute,
    WebLayout.pointerEventsNone,
    'transition-opacity',
    haloEmit.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the halo `<div>` inline-CSS bundle — `spread` outside the
  /// circle on every side, a full-round corner and any raw ink override.
  /// The resting opacity is a class (see [buildHaloClassName]), never an
  /// inline declaration.
  ///
  /// The halo is absolutely positioned inside the circle, so its inset is
  /// measured from the circle's *padding* box — the ring's stroke inside
  /// the border box. Reaching `spread` beyond the circle's outer edge
  /// (where the Flutter twin's halo reaches, off the outer box) takes the
  /// stroke on top of the spread, and the stroke is the state's own: a
  /// selected ring is several times heavier than a resting one. The inset
  /// rides the stroke's clock (see the `transition-property` below) so the
  /// halo's edge holds still while the ring grows under it.
  Styles buildHaloInlineStyles() => .new(
    raw: {
      'transition-duration': durationMsCss(colorTransitionMs),
      'inset':
          'calc(-${stateLayerSpread / kRemDivisor}rem - '
          '${strokeWidthCss(borderWidth)})',
      'border-radius': '50%',
      // The class's `transition-opacity` names opacity alone; the inset
      // joins it, keeping the resolved duration and class's curve.
      'transition-property': 'opacity, inset',
      ...?haloEmit.inline,
    },
  );

  /// Composes the `<div role="radio">` circle Tailwind className —
  /// structural layout, the colour-transition (`transition-colors
  /// duration-*`) class, the state-resolved background / border colour
  /// classes ([buttonBackgroundEmit] / [buttonBorderEmit] — token-bound →
  /// class, dark-mode reactive), cursor hint, and the `:focus` overrides
  /// that hand the focus ring drawing to the surrounding `FocusOutline`.
  /// Width / height / border width / circular radius (and any raw colour
  /// override) live inline.
  String buildButtonClassName() => <String>[
    // States no shadow of its own, so it takes the style's — the
    // Flutter twin reads the same cast.
    kControlShadowRestMarker,
    // The halo is positioned against this box.
    WebLayout.relative,
    WebLayout.flexCenter,
    'transition-colors',
    WebLayout.shrinkZero,
    buttonBackgroundEmit.className,
    buttonBorderEmit.className,
    if (enabled) 'cursor-pointer' else 'cursor-not-allowed',
    // The focus ring is drawn by the surrounding FocusOutline; we
    // suppress the browser's default rectangular focus outline so it
    // does not double-up over the circular ring.
    'outline-none',
    // The circle is 12 or 14 at the smaller sizes, under the WCAG
    // minimum. This extends where a pointer is accepted and draws
    // nothing; the circle still renders at its own size.
    kWebTouchTargetMarker,
    // Marks the ring as a component surface (the Flutter twin composes
    // `OutlinedContainer` for the same two states — see
    // `selectedRingContainerStyle`/`unselectedRingContainerStyle`).
    // Disabled is never marked, matching the resolver's
    // `disabledSelectedRingContainerStyle.surfaceBlur: 0` (and its
    // unselected twin). Selected and
    // unselected both carry it — the inner dot's colour is fixed either
    // way, so there is no glyph-contrast risk (mirrors the Flutter
    // resolver's reasoning).
    if (enabled) ...webSurfaceMarkerFor(.content),
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the `<div role="radio">` circle inline-CSS bundle — width
  /// / height / border width plus the circular `border-radius: 50%` and
  /// any raw colour override emitted by the emit family (token bases stay
  /// on classes — see [buildButtonClassName] — and contribute nothing
  /// here). `border-style: solid` is set inline so the inline
  /// `border-width` actually paints; `border-radius: 50%` makes a perfect
  /// circle on the square indicator.
  ///
  /// The selection grows the ring, so the border width is on the colour
  /// clock: the class's `transition-colors` names the colours alone, and
  /// the inline `transition-property` adds the width to them while the
  /// inline duration and class curve keep the same clock the Flutter
  /// twin's `AnimatedContainer` interpolates the width on.
  Styles buildButtonInlineStyles() => .new(
    raw: {
      'transition-duration': durationMsCss(colorTransitionMs),
      'width': '${indicatorSize / kRemDivisor}rem',
      'height': '${indicatorSize / kRemDivisor}rem',
      'border-width': strokeWidthCss(borderWidth),
      'border-style': 'solid',
      'transition-property': 'background-color, border-color, border-width',
      'border-radius': ringRadius.toValue(),
      ...?buttonBackgroundEmit.inline,
      ...?buttonBorderEmit.inline,
      // The other half of the surface marker above — publishes the
      // fill this state chose so a material preset can restate it at
      // its own alpha. Empty (no-op) for a raw colour override with no
      // token.
      if (enabled) ...surfaceFillVar(bgOverride ?? bgBase),
      // The ring's width, so the material's edge band reaches the outside of
      // the border instead of one border inside it.
      if (enabled) ...surfaceBleedVar(strokeWidthCss(borderWidth)),
    },
  );

  /// Composes the inner dot `<div>` Tailwind className — the
  /// scale-transition (`transition-transform duration-*`) class, the
  /// selected / unselected scale, and the resolved dot colour class
  /// ([dotEmit] — token-bound → `bg-{token}`, dark-mode reactive).
  /// Width / height / circular radius (and any raw colour override) live
  /// inline.
  String buildDotClassName() => <String>[
    'transition-transform',
    if (isSelected) 'scale-100' else 'scale-0',
    dotEmit.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the inner dot `<div>` inline-CSS bundle — width / height
  /// plus the circular `border-radius: 50%` and any raw dot-colour
  /// override (the token base stays on the class — see [buildDotClassName]).
  /// The dot is always mounted (CSS `scale` animates the in/out
  /// transition), so the colour is emitted unconditionally.
  Styles buildDotInlineStyles() => .new(
    raw: {
      'transition-duration': durationMsCss(dotTransitionMs),
      'width': '${dotSize / kRemDivisor}rem',
      'height': '${dotSize / kRemDivisor}rem',
      'border-radius': '50%',
      ...?dotEmit.inline,
    },
  );

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedRadioOption(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    button: WebElementChrome(
      className: buildButtonClassName(),
      inlineStyles: buildButtonInlineStyles(),
    ),
    halo: WebElementChrome(
      className: buildHaloClassName(),
      inlineStyles: buildHaloInlineStyles(),
    ),
    dot: WebElementChrome(
      className: buildDotClassName(),
      inlineStyles: buildDotInlineStyles(),
    ),
    indicatorLabelGapStyle: indicatorLabelGapStyle,
    content: WebElementChrome(className: buildContentClassName()),
    labelLine: WebElementChrome(className: buildLabelLineClassName()),
    description: WebElementChrome(
      className: buildDescriptionClassName(),
      inlineStyles: buildDescriptionInlineStyles(),
    ),
    labelDescriptionGapStyle: labelDescriptionGapStyle,
    tileBody: WebElementChrome(className: buildTileBodyClassName()),
    tileStateLayer: WebElementChrome(
      className: buildTileStateLayerClassName(),
      inlineStyles: buildTileStateLayerInlineStyles(),
    ),
    tileFocusOutlineStyle: tileFocusOutlineStyle,
  );
}

// ═══════════════════════════════════════════════════
// Resolver — scoped hover / active rules (category C)
// ═══════════════════════════════════════════════════

/// Resolves the scoped CSS that raises the halo on `:hover` / `:active`
/// of the radio's root for a single item inside a [resolveRadioGroup].
///
/// Reads the merged style off [group] like [resolveRadioOption], so the
/// weights the rules carry and the halo the option resolver mounts come
/// from one merge chain. Empty on the disabled path — a disabled row
/// never engages, so it wears no scope class and no rule.
///
/// Content-addressed: two radios (or a whole group) that resolve to the
/// same ramp share one class and one rule instead of emitting a
/// duplicate per instance.
ResolvedRadioRules resolveRadioRules(
  BuildContext context, {
  required ResolvedRadioGroup group,
  required bool enabled,
}) {
  if (!enabled) return const ResolvedRadioRules(scopeClass: '', css: '');
  final merged = group.radioGroupStyle;
  final layer = merged.stateLayer ?? CoreRadioGroupStyle.defaultStateLayer;
  final seed = '${layer.hover}|${layer.pressed}';
  final scopeClass =
      'co-radio-sl-${seed.hashCode.toRadixString(36).replaceAll('-', 'n')}';
  final scope = '.$scopeClass';
  // hover → active, so a pressed row does not step DOWN to the hover
  // weight on the same-specificity tie while the pointer is still over it.
  final buffer = StringBuffer()
    ..write('$scope:hover .$kRadioHaloMarker{opacity:${layer.hover};}')
    ..write('$scope:active .$kRadioHaloMarker{opacity:${layer.pressed};}');
  return ResolvedRadioRules(scopeClass: scopeClass, css: buffer.toString());
}
