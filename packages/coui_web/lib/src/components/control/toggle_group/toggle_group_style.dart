/// Style-slot single entry point for the Web `ToggleGroup`.
///
/// Mirrors the Flutter `toggle_group_style.dart`: a `resolveToggleGroup`
/// merge function that walks the merge chain
/// (`CoreToggleGroupStyle.defaultX` → `theme.toggleGroup.style` →
/// `component.toggleGroupStyle`) and ships back a [ResolvedToggleGroup]
/// chrome bundle. Per-state segment chrome (chosen vs unchosen) is folded
/// into the bundle as two paint-ready slot fields, and the disabled state
/// is folded into the same fields, so `toggle_group.dart` only reads
/// `chrome.X.className / inlineStyles`.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ════════════════════════════════════════════════════════════════
// ResolvedToggleGroup — slot-only chrome bundle
// ════════════════════════════════════════════════════════════════

/// Paint-ready chrome for Web `ToggleGroup`.
///
/// DOM shape:
///
/// ```text
/// root (<div role="radiogroup">)             // the track
///   └─ inner (<div inline-flex>)             // row of segments
///        ├─ items[] (Clickable role="radio") // cursor / press / focus
///             └─ <div>                        // chosen → itemSelected
///                  │                          // unchosen → itemUnselected
///                  │                          // (fixed itemHeight, centred)
///                  ├─ <span>?                 // iconSlotSelected /
///                  │    │                     // iconSlotUnselected — only
///                  │    │                     // when item.icon != null
///                  │    └─ IconTheme(size)    // caller icon (ambient size)
///                  └─ <span>?                 // labelBox (labelPadding) —
///                       │                     // only when item.showLabel
///                       └─ <span>             // labelStack (column overlay)
///                            ├─ label text
///                            └─ <span>        // labelGhost — invisible
///                                             // chosen-weight twin
///        └─ trailing?                        // caller content after the last
///                                          // segment (inside the track)
/// ```
///
/// Per-segment chrome is folded into per-state slot fields so the widget
/// picks the right one from a single `isSelected` flag. A disabled group
/// resolves the same slots to their flat values (disabled track, sunk
/// chosen face, no shadow, disabled ink).
class ResolvedToggleGroup implements WebResolvedChrome {
  /// Creates a [ResolvedToggleGroup].
  const ResolvedToggleGroup({
    required this.root,
    required this.inner,
    required this.itemHost,
    required this.itemSelected,
    required this.itemUnselected,
    required this.iconSlotSelected,
    required this.iconSlotUnselected,
    required this.labelBox,
    required this.labelStack,
    required this.labelGhost,
    required this.iconStyle,
    required this.selectedIconStyle,
    required this.clickableStyle,
  });

  /// Chrome for the outermost `<div role="radiogroup">` — the track:
  /// fill + inset + radius.
  @override
  final WebElementChrome root;

  /// Chrome for the inner segment-row `<div inline-flex>` (carries the
  /// gap between segments).
  final WebElementChrome inner;

  /// Inline chrome for each segment's `Clickable` host — the equal share
  /// of a `fillWidth` track (empty otherwise).
  final WebElementChrome itemHost;

  /// Chrome for a *chosen* segment `<div>` — chosen fill, shadow, ink.
  final WebElementChrome itemSelected;

  /// Chrome for an *unchosen* segment `<div>`.
  final WebElementChrome itemUnselected;

  /// Chrome for the chosen segment's icon slot `<span>` — carries the
  /// icon colour so a caller icon inherits it via `currentColor`.
  final WebElementChrome iconSlotSelected;

  /// Chrome for an unchosen segment's icon slot `<span>`.
  final WebElementChrome iconSlotUnselected;

  /// Chrome for the label box `<span>` — the label's own horizontal
  /// inset, rendered only with the label (an icon-only segment is a
  /// square by the segment's minimum width).
  final WebElementChrome labelBox;

  /// Chrome for the label-stack `<span>` — overlays the visible label on
  /// the invisible chosen-weight twin so the segment width is the max of
  /// both weights.
  final WebElementChrome labelStack;

  /// Chrome for the invisible chosen-weight label twin.
  final WebElementChrome labelGhost;

  /// Icon style of an unchosen segment's icon, raw-forwarded as the
  /// ambient `IconTheme` size. The colour rides [iconSlotUnselected].
  final CoreIconStyle iconStyle;

  /// Icon style of the chosen segment's icon. The colour rides
  /// [iconSlotSelected].
  final CoreIconStyle selectedIconStyle;

  /// Nested [CoreClickableStyle] for the composed per-segment
  /// `Clickable`, raw-forwarded. The Clickable owns the cursor / press /
  /// focus ring / `select-none`.
  final CoreClickableStyle clickableStyle;
}

// ════════════════════════════════════════════════════════════════
// resolveToggleGroup — single entry point
// ════════════════════════════════════════════════════════════════

/// Resolves [ResolvedToggleGroup] for the given Web [context].
///
/// ```text
/// design system default → CoreToggleGroupTheme.style
///   → component.toggleGroupStyle
/// ```
///
/// [enabled] is a semantic state (a build-time prop both platforms
/// share); hover / press / focus are detected by the browser.
ResolvedToggleGroup resolveToggleGroup(
  BuildContext context, {
  required bool enabled,
  CoreComponentSize size = CoreToggleGroupContract.defaultSize,
  CoreAxis direction = CoreToggleGroupContract.defaultDirection,
  bool fillWidth = false,
  CoreToggleGroupStyle? toggleGroupStyle,
}) {
  final toggleGroupTheme = context.theme.coreComponentTheme?.toggleGroup;

  final merged = resolveStyleChain(const CoreToggleGroupStyle(), [
    toggleGroupTheme?.style,
    toggleGroupStyle,
  ]);

  // The size row — sits between the merged override and the flat default.
  final sizeRow = CoreToggleGroupStyle.sizeDefaults(size);
  final borderRadiusValue =
      merged.borderRadius ??
      sizeRow.borderRadius ??
      CoreToggleGroupStyle.defaultBorderRadius;
  final itemBorderRadiusValue =
      merged.itemBorderRadius ??
      sizeRow.itemBorderRadius ??
      CoreToggleGroupStyle.defaultItemBorderRadius;
  final paddingValue =
      merged.padding ?? sizeRow.padding ?? CoreToggleGroupStyle.defaultPadding;
  final itemPaddingValue =
      merged.itemPadding ??
      sizeRow.itemPadding ??
      CoreToggleGroupStyle.defaultItemPadding;
  final labelPaddingValue =
      merged.labelPadding ?? CoreToggleGroupStyle.defaultLabelPadding;
  final itemHeightValue =
      merged.itemHeight ??
      sizeRow.itemHeight ??
      CoreToggleGroupStyle.defaultItemHeight;
  final itemSpacing =
      merged.itemSpacing ?? CoreToggleGroupStyle.defaultItemSpacing;

  // Per-state icon slots — composite nested `CoreIconStyle`, default
  // merged with the override so a colour-only override keeps the default
  // size. A disabled group states one icon style for both states.
  final iconStyle = enabled
      ? CoreToggleGroupStyle.defaultIconStyle.merge(merged.iconStyle)
      : CoreToggleGroupStyle.defaultDisabledIconStyle.merge(
          merged.disabledIconStyle,
        );
  final selectedIconStyle = enabled
      ? CoreToggleGroupStyle.defaultSelectedIconStyle.merge(
          merged.selectedIconStyle,
        )
      : iconStyle;
  final clickableStyle = CoreToggleGroupStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );
  final selectedFontWeight =
      merged.selectedFontWeight ??
      CoreToggleGroupStyle.defaultSelectedFontWeight;
  final transitionMs =
      (merged.transitionDuration ??
              CoreToggleGroupStyle.defaultTransitionDuration)
          .inMilliseconds;

  // ─── EMIT family (theme-free, single class-XOR-inline per surface) ──
  final trackEmit = enabled
      ? emitColor(
          merged.backgroundColor,
          CoreToggleGroupStyle.defaultBackgroundColor,
          .background,
        )
      : emitColor(
          merged.disabledBackgroundColor,
          CoreToggleGroupStyle.defaultDisabledBackgroundColor,
          .background,
        );
  final trackFill = enabled
      ? merged.backgroundColor ?? CoreToggleGroupStyle.defaultBackgroundColor
      : merged.disabledBackgroundColor ??
            CoreToggleGroupStyle.defaultDisabledBackgroundColor;
  final selectedBgEmit = enabled
      ? emitColor(
          merged.selectedColor,
          CoreToggleGroupStyle.defaultSelectedColor,
          .background,
        )
      : emitColor(
          merged.disabledSelectedColor,
          CoreToggleGroupStyle.defaultDisabledSelectedColor,
          .background,
        );
  // A disabled group paints no shadow under the chosen face. `emitShadow`
  // routes a scale step to `var(--shadow-<step>)`, so the surface style
  // and the dark strength reach it.
  final selectedShadowCss = enabled
      ? emitShadow(
          merged.selectedShadow ?? CoreToggleGroupStyle.defaultSelectedShadow,
          base: kShadowVariableBase,
        )
      : 'none';

  // Per-state icon colour — `text-{token}` class or inline for a raw
  // override, inherited by the caller icon via `currentColor`.
  final unselectedIconEmit = emitColor(
    iconStyle.color,
    CoreToggleGroupStyle.defaultIconStyle.color!,
    .text,
  );
  final selectedIconEmit = emitColor(
    selectedIconStyle.color,
    CoreToggleGroupStyle.defaultSelectedIconStyle.color!,
    .text,
  );

  // The hover state layer — the layer colour at the ramp's hover weight,
  // published on every segment; the shared `ThemeConfig` rule lays it over
  // the segment on `:hover`, over whichever face the segment wears. A
  // disabled group publishes none.
  final hoverLayer =
      (merged.stateLayerColor ?? CoreToggleGroupStyle.defaultStateLayerColor)
          .scaleAlpha(
            (merged.stateLayer ?? CoreToggleGroupStyle.defaultStateLayer).hover,
          )
          .toValue();

  final borderRadius = borderRadiusValue.toValue();
  final itemBorderRadius = itemBorderRadiusValue.toValue();
  final padding = paddingValue.toValue();
  final itemPadding = itemPaddingValue.toValue();
  final labelPadding = labelPaddingValue.toValue();
  final itemHeightRem = '${itemHeightValue / kRemDivisor}rem';
  final itemSpacingCss = spaceCss(itemSpacing);

  // ─── Label typography (the state ink folds in here) ──────────────
  // `emitTypography` is the single path: the `label-large` role on a
  // `text-{role}` class plus the state colour token on a `text-{colour}`
  // class, and any explicit overlay (the chosen weight, a per-instance
  // size / weight / spacing / raw colour) inline. A disabled group states
  // one ink for both states; the chosen label keeps its weight.
  final CoreTextStyle? unselectedOverlay;
  final CoreTextStyle unselectedDefault;
  final CoreTextStyle? selectedOverlay;
  final CoreTextStyle selectedDefault;
  if (enabled) {
    unselectedOverlay = merged.labelTextStyle;
    unselectedDefault = CoreToggleGroupStyle.defaultLabelTextStyle.merge(
      sizeRow.labelTextStyle,
    );
    selectedOverlay = merged.selectedLabelTextStyle;
    selectedDefault = CoreToggleGroupStyle.defaultSelectedLabelTextStyle
        .merge(sizeRow.selectedLabelTextStyle)
        .copyWith(fontWeight: selectedFontWeight);
  } else {
    final disabledDefault = CoreToggleGroupStyle.defaultDisabledLabelTextStyle
        .merge(sizeRow.disabledLabelTextStyle);
    unselectedOverlay = merged.disabledLabelTextStyle;
    unselectedDefault = disabledDefault;
    // A disabled chosen label retains the selected weight (Flutter's
    // final copyWith), while every other disabled override stays intact.
    selectedOverlay = merged.disabledLabelTextStyle?.copyWith(
      fontWeight: selectedFontWeight,
    );
    selectedDefault = disabledDefault.copyWith(
      fontWeight: selectedFontWeight,
    );
  }
  final unselectedLabelEmit = emitTypography(
    unselectedOverlay,
    unselectedDefault,
  );
  final selectedLabelEmit = emitTypography(selectedOverlay, selectedDefault);

  // ─── Local builders ───────────────────────────────────

  /// The track `<div>` className. Carries the surface marker
  /// unconditionally — the track is the actual surface; the moving chosen
  /// face is not. The Flutter twin composes `OutlinedContainer` for this
  /// same box.
  String buildRootClassName() {
    return [
      if (fillWidth) ...[
        WebLayout.flex,
        WebLayout.itemsCenter,
        WebLayout.wFull,
      ] else
        WebLayout.inlineFlexItemsCenter,
      ...webSurfaceMarkerFor(.content),
      if (trackEmit.className.isNotEmpty) trackEmit.className,
    ].join(' ');
  }

  Styles buildRootInlineStyles() {
    return Styles(
      raw: {
        'padding': padding,
        'border-radius': borderRadius,
        // Padding sits inside the offered width.
        if (fillWidth) 'box-sizing': 'border-box',
        ...?trackEmit.inline,
        // The other half of the marker above — publishes the fill so a
        // material preset can restate it at its own alpha.
        ...surfaceFillVar(trackFill),
      },
    );
  }

  // A vertical group is a column whose segments stretch to the widest one
  // (the Flutter `Column(crossAxisAlignment: stretch)`), so the segments
  // share the track's width and centre their content.
  final vertical = direction == CoreAxis.vertical;

  String buildInnerClassName() {
    if (vertical) {
      return [
        WebLayout.flex,
        WebLayout.flexCol,
        WebLayout.itemsStretch,
        if (fillWidth) WebLayout.wFull,
      ].join(' ');
    }
    return fillWidth
        ? '${WebLayout.flex} ${WebLayout.itemsCenter} ${WebLayout.wFull}'
        : WebLayout.inlineFlexItemsCenter;
  }

  /// Each segment's `Clickable` host takes an equal share of a
  /// `fillWidth` track (`flex: 1 1 0`, `min-width: 0` so a long label can
  /// shrink instead of overflowing).
  Styles? buildItemHostInlineStyles() => fillWidth && !vertical
      ? const Styles(raw: {'flex': '1 1 0%', 'min-width': '0'})
      : null;

  /// The item gap lives on the inner row (not the track, whose only child
  /// it is) so it separates every sibling like Flutter's
  /// `Row(spacing: itemSpacing)`.
  Styles buildInnerInlineStyles() => .new(raw: {'gap': itemSpacingCss});

  /// A segment's className (child of the composing `Clickable`, which owns
  /// the cursor / press / focus ring). `transition` covers the fill, the
  /// ink and the shadow.
  String buildItemClassName({required bool isSelected}) {
    final labelEmit = isSelected ? selectedLabelEmit : unselectedLabelEmit;
    final bgClass = isSelected ? selectedBgEmit.className : '';
    return [
      WebLayout.inlineFlexCenter,
      if (fillWidth || vertical) WebLayout.wFull,
      if (enabled) kStateLayerHoverMarker,
      'transition',
      if (labelEmit.className.isNotEmpty) labelEmit.className,
      if (bgClass.isNotEmpty) bgClass,
    ].join(' ');
  }

  /// A segment's inline-CSS: padding + radius + the fixed height (content
  /// centres via the `items-center` class), the per-state label overlay,
  /// the chosen fill override (raw colours only) and the chosen shadow.
  Styles buildItemInlineStyles({required bool isSelected}) {
    final labelEmit = isSelected ? selectedLabelEmit : unselectedLabelEmit;
    return Styles(
      raw: {
        'padding': itemPadding,
        'height': itemHeightRem,
        // Never narrower than it is tall — an icon-only segment is a
        // square (Flutter's `constraints: minWidth: itemHeight`).
        'min-width': itemHeightRem,
        // Fixed height, minimum width AND padding on one box: border-box
        // keeps the padding inside both (Flutter's
        // `AnimatedContainer(height:, constraints:, padding:)` is
        // border-box by nature).
        'box-sizing': 'border-box',
        'border-radius': itemBorderRadius,
        'transition-duration': durationMsCss(transitionMs),
        if (enabled) kStateLayerHoverVar: hoverLayer,
        ...?labelEmit.inline,
        if (isSelected) ...?selectedBgEmit.inline,
        if (isSelected) 'box-shadow': selectedShadowCss,
      },
    );
  }

  String buildIconSlotClassName({required bool isSelected}) {
    final iconEmit = isSelected ? selectedIconEmit : unselectedIconEmit;
    return [
      WebLayout.inlineFlexCenter,
      WebLayout.shrinkZero,
      if (iconEmit.className.isNotEmpty) iconEmit.className,
    ].join(' ');
  }

  Styles? buildIconSlotInlineStyles({required bool isSelected}) {
    final iconEmit = isSelected ? selectedIconEmit : unselectedIconEmit;
    final inline = iconEmit.inline;
    if (inline == null) return null;
    return Styles(raw: inline);
  }

  String buildLabelBoxClassName() => WebLayout.inlineFlexItemsCenter;

  Styles buildLabelBoxInlineStyles() => .new(raw: {'padding': labelPadding});

  /// An inline column overlaying the visible label on the invisible
  /// chosen-weight twin (centred like the Flutter `Stacks(alignment:
  /// .center)` twin).
  Styles buildLabelStackInlineStyles() => const Styles(
    raw: {
      'display': 'inline-flex',
      'flex-direction': 'column',
      'align-items': 'center',
    },
  );

  /// The invisible chosen-state label twin — the full resolved chosen
  /// typography collapsed to zero height and hidden from paint + a11y.
  Styles buildLabelGhostInlineStyles() => .new(
    raw: {
      // Not a design token — CSS mechanics collapsing the twin's box.
      'height': '0',
      'overflow': 'hidden',
      'visibility': 'hidden',
      ...?selectedLabelEmit.inline,
    },
  );

  return ResolvedToggleGroup(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    inner: WebElementChrome(
      className: buildInnerClassName(),
      inlineStyles: buildInnerInlineStyles(),
    ),
    itemHost: WebElementChrome(
      className: '',
      inlineStyles: buildItemHostInlineStyles(),
    ),
    itemSelected: WebElementChrome(
      className: buildItemClassName(isSelected: true),
      inlineStyles: buildItemInlineStyles(isSelected: true),
    ),
    itemUnselected: WebElementChrome(
      className: buildItemClassName(isSelected: false),
      inlineStyles: buildItemInlineStyles(isSelected: false),
    ),
    iconSlotSelected: WebElementChrome(
      className: buildIconSlotClassName(isSelected: true),
      inlineStyles: buildIconSlotInlineStyles(isSelected: true),
    ),
    iconSlotUnselected: WebElementChrome(
      className: buildIconSlotClassName(isSelected: false),
      inlineStyles: buildIconSlotInlineStyles(isSelected: false),
    ),
    labelBox: WebElementChrome(
      className: buildLabelBoxClassName(),
      inlineStyles: buildLabelBoxInlineStyles(),
    ),
    labelStack: WebElementChrome(
      className: '',
      inlineStyles: buildLabelStackInlineStyles(),
    ),
    labelGhost: WebElementChrome(
      className: selectedLabelEmit.className,
      inlineStyles: buildLabelGhostInlineStyles(),
    ),
    iconStyle: iconStyle,
    selectedIconStyle: selectedIconStyle,
    clickableStyle: clickableStyle,
  );
}
