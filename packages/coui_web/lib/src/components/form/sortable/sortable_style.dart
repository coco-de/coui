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
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Sortable`.
///
/// DOM shape:
///
/// ```text
/// root (<div role="list">)              // list container — owns the inter-row
///   │                                   //   `gap`, so rows stay its *direct*
///   │                                   //   children (the drag scope adopts
///   │                                   //   this element rather than nesting
///   │                                   //   a box of its own between them)
///   └─ [DragItem (<div>)]                // reorderable rows only — pointer
///        │                                //   grab only; the keyboard path
///        │                                //   lives on the handle
///        └─ item (<div role="listitem">)       // per-row — sortable.dart layers
///             │                                //   the runtime transform on top
///             │                                //   of `item` via composeSortableItem
///             └─ caller item content           // itemBuilder's single return;
///                                              //   handle and removeButton
///                                              //   (a composed `Button`) are
///                                              //   handed to it and placed by
///                                              //   the caller
/// ```
///
/// The handle a reorderable row hands out:
///
/// ```text
/// [DragHandle (<div>)]                    // pointer grab surface
///   └─ FocusOutline (<div>)               // handleRing; ring ← handleFocusOutlineStyle
///        └─ handle (<span role="application" tabindex="0">)
///             └─ Icon                     // ← iconStyle
/// ```
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only Cat 1
/// `WebElementChrome` slots (paint-ready chrome) plus the shared nested
/// [CoreIconStyle] slot. No scalar metadata (`enabled`, raw colour
/// strings, DOM-measured gap) is exposed as a top-level field — the
/// default-vs-override branching lives entirely inside the resolver's
/// local builders, and the behavioural runtime values the widget applies
/// imperatively (DOM-measured inter-row gap + JS hover-colour) come from
/// the separate [resolveSortableRuntime] entry point (number_ticker
/// separate-resolver pattern), so this struct stays pure paint-ready
/// chrome.
class ResolvedSortable implements WebResolvedChrome {
  /// Creates a [ResolvedSortable].
  const ResolvedSortable({
    required this.root,
    required this.item,
    required this.handle,
    required this.handleRing,
    required this.removeButtonStyle,
    required this.iconStyle,
    required this.handleFocusOutlineStyle,
  });

  /// Paint-ready chrome for the outermost `<div role="list">` sortable
  /// container — `flex flex-col` className plus the resolved
  /// inter-row gap inline CSS.
  @override
  final WebElementChrome root;

  /// Paint-ready base chrome for each row `<div role="listitem">` —
  /// composed Tailwind className (`flex w-full items-center` + gap +
  /// padding + radius + background + hover-tint + transitions) plus the
  /// per-instance background / radius override inline CSS. `co_sortable`
  /// layers the per-row runtime transform / drag opacity on top via
  /// [composeSortableItem].
  final WebElementChrome item;

  /// Paint-ready chrome for each drag handle `<span>` — composed
  /// Tailwind className (`inline-flex items-center cursor-grab
  /// active:cursor-grabbing select-none` + horizontal padding) plus the
  /// optional resolved handle-colour override inline CSS.
  final WebElementChrome handle;

  /// Layout for the `FocusOutline` wrapper around each handle — a bare
  /// `inline-flex`, so the wrapper takes the handle's own size. A block
  /// wrapper would open a line box and park the inline-level handle on
  /// its baseline, adding descender space the Flutter twin's ring (a
  /// pass-through stack) does not have.
  final WebElementChrome handleRing;

  /// Remove-button style — `defaultRemoveButtonStyle` chained with the
  /// flat remove fields and the per-instance `removeButtonStyle`
  /// override, raw-forwarded to
  /// `Button(variant: .plain, size: .sm, shape: .square, buttonStyle: …)`.
  /// The child `Button` resolves its own colours / hover / focus ring.
  final CoreButtonStyle removeButtonStyle;

  /// Shared nested [CoreIconStyle] slot for the drag-handle and remove
  /// glyphs — the resolver absorbs the design-system default
  /// ([CoreSortableStyle.defaultIconStyle]) so this is non-null and
  /// carries a concrete `size`. `co_sortable.dart` forwards this to
  /// `Icon(iconStyle: …)` for the drag handle.
  final CoreIconStyle iconStyle;

  /// Focus ring around the drag handle — the keyboard's way into a
  /// reorder. Raw-forwarded from the nested `handleStyle.focusOutlineStyle`
  /// slot; `FocusOutline` resolves its own defaults for whatever is null.
  final CoreFocusOutlineStyle? handleFocusOutlineStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedSortable] for the given [context].
///
/// Walks the merge chain:
///
/// ```text
/// design system default
///   → theme.coreComponentTheme.sortable.style
///   → widget.sortableStyle
/// ```
///
/// The [enabled] flag stays a function parameter — it only gates the
/// cursor / hover classes the local builders compose, so it never
/// surfaces as a field on [ResolvedSortable].
ResolvedSortable resolveSortable(
  BuildContext context, {
  required bool enabled,
  CoreSortableAxis axis = CoreSortableContract.defaultAxis,
  CoreSortableStyle? sortableStyle,
}) {
  final csTheme = context.theme.coreComponentTheme?.sortable;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreSortableStyle(), [
    csTheme?.style,
    sortableStyle,
  ]);

  // surface:content — each row draws its own box on its own
  // `<div role="listitem">` rather than composing `OutlinedContainer`.
  // The design default always states a solid `surface` token, so the
  // pair applies unconditionally unless the caller explicitly opted out
  // with a raw transparent override — same gate every other
  // content-role surface on this axis uses.
  // A disabled list wears the dedicated disabled fill and border instead
  // of the enabled ones (and no hover tint).
  final fillOverride = enabled
      ? merged.itemBackgroundColor
      : merged.disabledItemBackgroundColor;
  final fillDefault = enabled
      ? CoreSortableStyle.defaultItemBackgroundColor
      : CoreSortableStyle.defaultDisabledItemBackgroundColor;
  final containerFillCore = fillOverride ?? fillDefault;
  final borderEmit = emitColor(
    enabled ? merged.itemBorderColor : merged.disabledItemBorderColor,
    enabled
        ? CoreSortableStyle.defaultItemBorderColor
        : CoreSortableStyle.defaultDisabledItemBorderColor,
    .border,
  );
  final itemBorderWidth =
      merged.itemBorderWidth ?? CoreSortableStyle.defaultItemBorderWidth;
  final itemMinHeight =
      merged.itemMinHeight ?? CoreSortableStyle.defaultItemMinHeight;

  // ─── Resolved chrome values ───────────────────────────
  // Each dimensional value finishes its merge + fallback so the local
  // builders below emit it inline (`(merged.X ?? default).toValue()` /
  // `spaceCss` / rem) on a single CSS surface — no Tailwind
  // size/radius/padding class, no default-vs-override class-drop branch
  // (Epic #1603 단일 시그니처).
  final itemSpacing =
      merged.itemSpacing ?? CoreSortableStyle.defaultItemSpacing;
  final itemPadding =
      merged.itemPadding ?? CoreSortableStyle.defaultItemPadding;
  // The handle's focus ring rides the same nested button-style slot as
  // its padding and colour — raw-forwarded, `FocusOutline` fills the rest.
  final handleFocusOutlineStyle = merged.handleStyle?.focusOutlineStyle;
  // Handle padding — nested `handleStyle.padding` slot wins, else flat
  // `handlePadding`, else design-system default.
  final handlePadding =
      merged.handleStyle?.padding ??
      merged.handlePadding ??
      CoreSortableStyle.defaultHandlePadding;
  final itemBorderRadius =
      merged.itemBorderRadius ?? CoreSortableStyle.defaultItemBorderRadius;
  // Animation duration (ms for `durationMsCss`) — nested
  // `removeButtonStyle.animationDuration` / `handleStyle.animationDuration`
  // slot wins, else flat `animationDuration`, else design-system default.
  final animationDuration =
      (merged.removeButtonStyle?.animationDuration ??
              merged.handleStyle?.animationDuration ??
              merged.animationDuration ??
              CoreSortableStyle.defaultAnimationDuration)
          .inMilliseconds;
  // Item label typography slot (sb-text-style-repackage). The bodyMedium
  // role and the onSurface colour default live in the single
  // `defaultItemTextStyle` slot default; the per-instance itemTextStyle
  // slot layers on top so the item row emits the resolved font-size,
  // weight, line-height, and colour inline and the caller content
  // inherits them.
  // A disabled list says so in its own token — the item text and the remove
  // button's glyph take `disabledForegroundColor`, last in the chain.
  final disabledForegroundColor =
      merged.disabledForegroundColor ??
      CoreSortableStyle.defaultDisabledForegroundColor;
  final mergedItemTextStyle = CoreSortableStyle.defaultItemTextStyle
      .merge(merged.itemTextStyle)
      .merge(enabled ? null : CoreTextStyle(color: disabledForegroundColor));
  // Nested icon slot — absorb the design-system default so the resolver
  // forwards a non-null `CoreIconStyle` to both icon use sites.
  final iconStyle = CoreSortableStyle.defaultIconStyle.merge(merged.iconStyle);
  // Handle colour — nested `handleStyle.foregroundColor` slot wins, else
  // flat `handleColor`, else null (so the colour-token class drives the SVG
  // via `currentColor`). A disabled list takes `disabledHandleColor`.
  final handleColorOverride = enabled
      ? (merged.handleStyle?.foregroundColor ?? merged.handleColor)
      : merged.disabledHandleColor;
  final handleColorDefault = enabled
      ? CoreSortableStyle.defaultHandleColor
      : CoreSortableStyle.defaultDisabledHandleColor;
  // Remove-button chrome — chained `defaultRemoveButtonStyle`, then a
  // linkage layer carrying the flat remove fields and the shared icon slot
  // / transition duration, then the per-instance nested override.
  // Raw-forwarded to the composed `Button`, which resolves the rest.
  final removeButtonStyle = CoreSortableStyle.defaultRemoveButtonStyle
      .merge(
        CoreButtonStyle(
          foregroundColor: merged.removeButtonColor,
          borderRadius: merged.removeButtonBorderRadius,
          width: merged.removeButtonSize,
          height: merged.removeButtonSize,
          leadingIconStyle: merged.iconStyle,
          animationDuration: merged.animationDuration,
        ),
      )
      .merge(merged.removeButtonStyle)
      .merge(
        enabled
            ? null
            : CoreButtonStyle(foregroundColor: disabledForegroundColor),
      );
  // ─── Local builders ───────────────────────────────────

  /// Composes the sortable `<div role="list">` Tailwind className —
  /// `flex flex-col w-full` vertical stack. `w-full` fills the parent so
  /// the list matches its Flutter twin (a `Column` that fills width); a
  /// `.vertical` row also emits `w-full` (see [buildItemClassName]), but
  /// without it on the container the list itself collapses to content
  /// width.
  String buildRootClassName() => switch (axis) {
    .vertical => '${WebLayout.flex} ${WebLayout.flexCol} ${WebLayout.wFull}',
    .horizontal => '${WebLayout.flex} ${WebLayout.wFull}',
    .grid => '${WebLayout.flex} flex-wrap ${WebLayout.wFull}',
  };

  /// Composes the sortable `<div role="list">` inline CSS — carries the
  /// resolved inter-row gap inline (single signature).
  Styles buildRootInlineStyles() => .new(raw: {'gap': spaceCss(itemSpacing)});

  /// Composes the base per-row `<div role="listitem">` Tailwind
  /// className. Only colour token + pseudo-state classes live here —
  /// the background token class drops when the caller supplies a
  /// per-instance `itemBackgroundColor` (card colour model), and the
  /// hover-tint pseudo class drops when interaction is disabled or a
  /// per-instance hover colour drives the JS path instead. Padding /
  /// gap / radius are emitted inline by [buildItemInlineStyles].
  ///
  /// Row width mirrors the Flutter twin's `_layout`: a `.vertical` stack
  /// stretches its cross axis (`w-full`, matching `Column`'s
  /// `crossAxisAlignment: .stretch`), while `.horizontal` / `.grid` size
  /// each row to its own content — a `Row`/`Wrap` child never stretches
  /// to fill, so a row's width is the item's, not the container's
  /// (the item is one child among several sharing that main axis, not
  /// the only thing occupying it).
  String buildItemClassName() {
    final itemLayout = axis == .vertical
        ? WebLayout.flexFullItemsCenter
        : WebLayout.flexItemsCenter;
    final classList = [
      itemLayout,
      // Marks each row as a component surface, so a material preset
      // reaches it the same way it reaches a card. The design default
      // always states a solid `surface` token, so the pair applies
      // unconditionally unless the caller explicitly opted out with a
      // raw transparent override — same gate every other content-role
      // surface on this axis uses.
      if (!containerFillCore.isTransparent) ...webSurfaceMarkerFor(.content),
      // No `transition-transform` / `transition-colors` pair here: both
      // utilities write `transition-property`, and a second declaration
      // replaces the first outright rather than adding to it — the row
      // ended up transitioning `transform` only, so the hover tint
      // snapped while the Flutter twin faded it over the same clock
      // (`AnimatedContainer`). The property list is one declaration,
      // emitted inline by [buildItemInlineStyles] together with its clock.
      'will-change-transform',
    ];
    if (fillOverride == null) {
      classList.add('bg-${fillDefault.tailwindColor}');
    }
    // The border colour is a class when it is a token; a raw override goes
    // inline in [buildItemInlineStyles].
    if (borderEmit.className.isNotEmpty) classList.add(borderEmit.className);
    if (enabled && merged.itemHoverColor == null) {
      classList.add(
        'hover:bg-${CoreSortableStyle.defaultItemHoverColor.tailwindColor}',
      );
    }
    return classList.join(' ');
  }

  /// Composes the base per-row inline CSS — the resolved padding / radius
  /// (always inline, single signature) plus the per-instance background
  /// colour override (card colour model). The runtime reorder transform +
  /// drag opacity are layered on top by [composeSortableItem].
  ///
  /// No `gap` here: `itemSpacing` means the distance *between rows*, and a
  /// row owns a single child (the caller's item content), so spending the
  /// same field on the row's own inner gap would let a change to row
  /// spacing move something else as well. The Flutter twin emits no inner
  /// gap either.
  Styles buildItemInlineStyles() {
    final raw = <String, String>{
      // `CoreEasing.move` is exactly the Flutter engine's hard-coded
      // gap-shift curve (`Curves.easeInOut`, cubic-bezier(0.42, 0, 0.58,
      // 1)) — like the curve on the Flutter side, it is intentionally
      // not user-tunable, but still routes through `--easing-ease-in-out`
      // (not a raw `ease-in-out` literal) so a future systemic override
      // reaches it.
      'transition-timing-function': CoreEasing.move.toVarCss(),
      'transition-duration': durationMsCss(animationDuration),
      // One declaration naming everything the row animates — the reorder
      // shift and the hover tint ride the same clock, as they do on
      // Flutter (one `AnimatedContainer` carries both). Named rather than
      // `all`, which would drag `box-shadow` and `padding` onto this
      // clock too: the drag proxy's shadow appears in a single frame by
      // design, and easing it would smear the lift.
      'transition-property': 'transform, color, background-color, border-color',
      ...itemPadding.toLogicalDeclarations('padding'),
      'border-radius': itemBorderRadius.toValue(),
      // The border rides the row's box (it counts toward the minimum
      // height below, as it does on the Flutter twin's decoration).
      'border-style': 'solid',
      'border-width': strokeWidthCss(itemBorderWidth),
      ...?borderEmit.inline,
      // A floor, not a fixed height — the Flutter twin's `minHeight`.
      'min-height': pinnedLengthCss(itemMinHeight),
      // Item label typography — emitted on the row so the caller content
      // inherits the resolved font-size / weight / line-height / colour
      // (sb-text-style-repackage). Mirrors Flutter's
      // `DefaultTextStyle.merge(style: resolved.itemTextStyle)`.
      ...mergedItemTextStyle.toInlineCss(),
    };
    if (fillOverride != null) {
      // Web EMIT is theme-free — the token name goes straight to inline CSS
      // (`rgb(var(--coui-X))`) and the browser resolves it at runtime. No
      // `scheme.resolve` (no-op on Web).
      raw['background-color'] = fillOverride.toValue();
    }
    // The marker's other half — a preset restates this fill at a lower
    // alpha and cannot know which token the row chose.
    if (!containerFillCore.isTransparent) {
      raw
        ..addAll(surfaceFillVar(containerFillCore))
        ..addAll(surfaceBleedVar(strokeWidthCss(itemBorderWidth)));
    }
    return Styles(raw: raw);
  }

  /// Composes the drag handle `<span>` Tailwind className — the colour
  /// token class drops when a per-instance `handleColor` is supplied so
  /// the inline rule wins (card colour model). Horizontal padding is
  /// emitted inline by [buildHandleInlineStyles].
  String buildHandleClassName() {
    final classList = [
      '${WebLayout.inlineFlexItemsCenter} cursor-grab active:cursor-grabbing',
      'select-none',
    ];
    if (handleColorOverride == null) {
      classList.add('text-${handleColorDefault.tailwindColor}');
    }
    return classList.join(' ');
  }

  /// Composes the drag handle `<span>` inline CSS — the resolved
  /// horizontal padding (always inline) plus the per-instance handle
  /// colour override (card colour model).
  Styles buildHandleInlineStyles() {
    final raw = {
      ...handlePadding.toLogicalDeclarations('padding'),
      // Pointer-drag source — a touch on the handle must start a drag,
      // not scroll the page (Flutter parity: the handle owns the gesture).
      'touch-action': 'none',
    };
    if (handleColorOverride != null) {
      raw['color'] = handleColorOverride.toValue();
    }
    return Styles(raw: raw);
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedSortable(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    item: WebElementChrome(
      className: buildItemClassName(),
      inlineStyles: buildItemInlineStyles(),
    ),
    handle: WebElementChrome(
      className: buildHandleClassName(),
      inlineStyles: buildHandleInlineStyles(),
    ),
    handleRing: const WebElementChrome(className: WebLayout.inlineFlex),
    removeButtonStyle: removeButtonStyle,
    iconStyle: iconStyle,
    handleFocusOutlineStyle: handleFocusOutlineStyle,
  );
}

/// Resolves the behavioural runtime values for `Sortable` — the values
/// the widget applies imperatively at runtime rather than through a
/// static className / inline-CSS slot, so they are NOT part of the
/// paint-ready [ResolvedSortable] chrome (number_ticker
/// separate-resolver pattern):
///
/// * `hoverColor` — per-instance hover background as a CSS string,
///   toggled via the widget's JS `mouseenter` / `mouseleave` handlers
///   because CSS `:hover` cannot reference a per-instance value. `null`
///   when the default `hover:` Tailwind class already covers it.
/// * `proxyScale` / `proxyElevation` — the lift the dragged row takes on,
///   applied per-frame by the drag handlers rather than by a static class.
///
/// Walks the same merge chain as [resolveSortable] (design-system
/// default → `CoreSortableTheme.style` → `widget.sortableStyle`) with the
/// identical fallback, so the values match the chrome resolver exactly.
({String? hoverColor, double proxyScale, double proxyElevation})
resolveSortableRuntime(
  BuildContext context, {
  CoreSortableStyle? sortableStyle,
}) {
  final csTheme = context.theme.coreComponentTheme?.sortable;
  final merged = resolveStyleChain(const CoreSortableStyle(), [
    csTheme?.style,
    sortableStyle,
  ]);
  return (
    // Web EMIT is theme-free — emit the token name straight to a CSS string
    // (`rgb(var(--coui-X))`); the browser resolves it at runtime. No
    // `scheme.resolve` (no-op on Web).
    hoverColor: merged.itemHoverColor?.toValue(),
    // Drag-proxy lift — the dragged row scales up + casts a Material
    // elevation shadow (see [composeSortableItem]), mirroring the Flutter
    // `proxyDecorator` (`Transform.scale` + `Material(elevation:)`).
    proxyScale: merged.proxyScale ?? CoreSortableStyle.defaultProxyScale,
    proxyElevation:
        merged.proxyElevation ?? CoreSortableStyle.defaultProxyElevation,
  );
}

// ═══════════════════════════════════════════════════
// composeSortableItem — per-row runtime layer
// ═══════════════════════════════════════════════════

/// Layers the per-row runtime transform on top of the resolved base
/// [ResolvedSortable.item] chrome.
///
/// The base className / inline CSS are fully composed by
/// [resolveSortable]; this helper only folds in the runtime values the
/// widget knows per row — mirroring the Flutter `SliverReorderableList`
/// engine:
///
/// * non-source rows slide by [shiftPx] to open the drop gap (positive
///   shifts the row down, negative up), animated by the base chrome's
///   `transition-transform` class;
/// * the drag source ([isDragSource]) follows the pointer by
///   [dragOffsetY] and lifts — scaled up by [proxyScale] with a Material
///   drop shadow sized by [proxyElevation], raised above its siblings
///   (the Flutter `proxyDecorator`, `Transform.scale` +
///   `Material(elevation:)`);
/// * [suppressTransition] drops the base `transition-transform` for this
///   render — while the source tracks the pointer (no lag), and for the
///   single commit frame after the settle (the reorder swaps row
///   contents in place; without the suppression the stale transforms
///   animate back and the list visibly moves twice);
/// * [sessionActive] disables the row's pointer events for the whole
///   drag session (drag → settle → commit frame) — the document-level
///   listeners drive everything, and without it the source row's stale
///   `:hover` (and the JS hover override's inline background) survives
///   the commit and flashes the hover tint on the row left at the old
///   index (the Flutter twin gates its hover state the same way).
///
/// No style merge / default branching happens here, so the
/// single-source-of-truth resolver stays authoritative.
WebElementChrome composeSortableItem(
  ResolvedSortable resolved, {
  required double shiftPx,
  required bool isDragSource,
  required bool suppressTransition,
  required bool sessionActive,
  required double dragOffsetY,
  required double proxyScale,
  required double proxyElevation,
  double shiftXPx = 0,
  double dragOffsetX = 0,
}) {
  final runtimeRaw = <String, String>{};
  // The drag source follows the pointer and lifts (scale, see
  // [proxyScale]); a non-source row shifts to open the drop gap
  // ([shiftPx]). Both ride the one `transform` slot.
  // A grid displaces on both axes at once — the cell leaving the end of a
  // row lands at the start of the next — so both carry an x component.
  final transform = isDragSource
      ? 'translate(${dragOffsetX}px, ${dragOffsetY}px) scale($proxyScale)'
      : shiftPx != 0 || shiftXPx != 0
      ? 'translate(${shiftXPx}px, ${shiftPx}px)'
      : null;
  if (transform != null) {
    runtimeRaw['transform'] = transform;
  }
  if (suppressTransition) {
    runtimeRaw['transition'] = 'none';
  } else if (isDragSource) {
    // Release settle — `CoreEasing.enter` is exactly the Flutter
    // engine's hard-coded drop curve (`Curves.easeOut`,
    // cubic-bezier(0, 0, 0.58, 1)), routed through `--easing-ease-out`
    // rather than a raw literal.
    runtimeRaw['transition-timing-function'] = CoreEasing.enter.toVarCss();
  }
  if (sessionActive) {
    runtimeRaw['pointer-events'] = 'none';
  }
  if (isDragSource) {
    // Drag proxy — Material elevation drop shadow, lifted above the siblings.
    // `rem` carries the browser font-size accessibility scale. The rim
    // reference rides along so claymorphism's edge-light still reaches the
    // proxy while it is airborne — the marker on `resolved.item` alone
    // cannot compose it once this shadow overrides `box-shadow` wholesale.
    runtimeRaw['box-shadow'] =
        '0 ${proxyElevation / kRemDivisor}rem '
        '${proxyElevation * 2 / kRemDivisor}rem '
        'rgba(0, 0, 0, ${CoreOpacity.opacity20}), $kSurfaceRimVar';
    runtimeRaw['position'] = WebLayout.relative;
    // Lift above sibling list items only — `CoreZIndex.z0` (1000) is the
    // floor of the shared page-level ladder, and this stays 1 below the
    // next named rung (dropdown menus, z10=1010) intentionally: local
    // intra-list stacking, not a page-level overlay layer.
    runtimeRaw['z-index'] = '${CoreZIndex.z0 + 1}';
  }

  final base = resolved.item;
  if (runtimeRaw.isEmpty) return base;

  return WebElementChrome(
    className: base.className,
    inlineStyles: Styles.combine([
      ?base.inlineStyles,
      Styles(raw: runtimeRaw),
    ]),
  );
}
