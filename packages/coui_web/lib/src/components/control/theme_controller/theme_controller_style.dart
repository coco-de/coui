import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `ThemeController`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                                    // flex grid container
///   └─ swatch (<div>)                            // column: button + gap + label, one per theme
///        ├─ Clickable (<div role="button">)      // composed interaction wrapper
///        │    └─ button (<div>)                  // ring: selected / unselected / disabled chrome
///        │         └─ preview (<div>)            // one circle, clipped
///        │              └─ segment (<div>)       // one per palette colour (1..4), flex-1
///        ├─ Gap (labelGapStyle)
///        └─ label (<div>)                        // typography role class + colour
/// ```
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only paint-ready
/// `WebElementChrome` slots — `co_*` reads each slot's `className` /
/// `inlineStyles` straight from `resolved.<slot>` without any merge /
/// fallback / conversion in the widget body.
///
/// Slot layout:
/// * [root] — outer flex container chrome (className + gap inline CSS).
/// * [selectedButton] / [unselectedButton] — pre-resolved chrome for a
///   swatch button in the selected / unselected state. `co_*` picks the
///   slot based on `option.name == selectedTheme`.
/// * [disabledButton] / [disabledSelectedButton] — the same two boxes
///   with the border colour dropped to the disabled token (the selected
///   one keeps its width, so the selection survives the greying).
/// * [preview] — the palette circle: size + radius + clip. Its
///   children are [segment]s, one per colour, each a `flex-1` box —
///   the widget layers the colour on as the only per-iteration rule,
///   or [disabledSegment] when the swatch is locked.
/// * [label] / [selectedLabel] / [disabledLabel] — the theme-name text
///   below the button, in the ink its state picks.
/// * [labelGapStyle] — nested `CoreGapStyle` for the button-to-label
///   gap, raw-forwarded to `Gap`.
/// * [clickableStyle] — nested [CoreClickableStyle] slot raw-forwarded
///   to the composed per-swatch `Clickable`.
class ResolvedThemeController implements WebResolvedChrome {
  /// Creates a [ResolvedThemeController].
  const ResolvedThemeController({
    required this.root,
    required this.swatch,
    required this.selectedButton,
    required this.unselectedButton,
    required this.disabledButton,
    required this.disabledSelectedButton,
    required this.preview,
    required this.segment,
    required this.disabledSegment,
    required this.label,
    required this.selectedLabel,
    required this.disabledLabel,
    required this.labelGapStyle,
    required this.clickableStyle,
  });

  /// Paint-ready chrome for the root `<div>` flex grid container.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for a theme swatch `<div>` in the selected
  /// state — `co_*` picks this when the option matches `selectedTheme`.
  final WebElementChrome selectedButton;

  /// Paint-ready chrome for a theme swatch `<div>` in the unselected
  /// state.
  final WebElementChrome unselectedButton;

  /// Paint-ready chrome for one swatch column `<div>` — button, gap,
  /// label stacked and centred.
  final WebElementChrome swatch;

  /// Button chrome for a disabled unselected swatch.
  final WebElementChrome disabledButton;

  /// Button chrome for a disabled selected swatch.
  final WebElementChrome disabledSelectedButton;

  /// Paint-ready chrome for the palette circle `<div>` — size, radius,
  /// clip, and a horizontal flex so its segments divide it evenly.
  final WebElementChrome preview;

  /// Base chrome for one palette segment `<div>` — `flex-1` so N of
  /// them split the circle into N equal columns. The widget layers the
  /// colour on as the only per-iteration inline rule.
  final WebElementChrome segment;

  /// Segment chrome on a disabled swatch — the disabled fill is baked
  /// in, so the widget adds nothing per colour.
  final WebElementChrome disabledSegment;

  /// Label chrome (enabled, unselected) — typography role class +
  /// colour.
  final WebElementChrome label;

  /// Label chrome of the selected, enabled swatch — the same role in the
  /// selected ink.
  final WebElementChrome selectedLabel;

  /// Label chrome (disabled).
  final WebElementChrome disabledLabel;

  /// Nested [CoreGapStyle] for the button-to-label gap — raw-forwarded
  /// to `Gap`.
  final CoreGapStyle labelGapStyle;

  /// Nested [CoreClickableStyle] slot for the composed per-swatch
  /// `Clickable` — `CoreThemeControllerStyle.defaultClickableStyle`
  /// merged with the per-instance override, raw-forwarded to
  /// `Clickable(clickableStyle:)`.
  final CoreClickableStyle clickableStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedThemeController] for the given [context].
///
/// Merge chain:
///
/// ```text
/// CoreThemeControllerStyle.defaultsBySize[size]
///   → theme.coreComponentTheme.themeController.style
///   → widget.themeControllerStyle
/// ```
ResolvedThemeController resolveThemeController(
  BuildContext context, {
  required CoreThemeControllerSize size,
  CoreThemeControllerStyle? themeControllerStyle,
}) {
  final controllerTheme = context.theme.coreComponentTheme?.themeController;

  // ─── Merge chain ──────────────────────────────────────
  // The size tier is the base of the chain, not a lookup beside it —
  // same shape as the Flutter twin.
  final sizeStyle = CoreThemeControllerStyle.defaultsBySize[size]!;
  final merged = resolveStyleChain(sizeStyle, [
    controllerTheme?.style,
    themeControllerStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  // Each value finished its merge + fallback so the local builders
  // below run from a single source of truth (closures capture these
  // directly).
  final buttonSize =
      merged.buttonSize ?? CoreThemeControllerStyle.defaultButtonSize;
  final previewSize =
      merged.previewSize ?? CoreThemeControllerStyle.defaultPreviewSize;
  final buttonSpacing =
      merged.buttonSpacing ?? CoreThemeControllerStyle.defaultButtonSpacing;
  final swatchMinWidth =
      merged.swatchMinWidth ?? CoreThemeControllerStyle.defaultSwatchMinWidth;
  final buttonRadius =
      merged.buttonRadius ?? CoreThemeControllerStyle.defaultButtonRadius;
  final selectedBorderColor =
      merged.selectedBorderColor ??
      CoreThemeControllerStyle.defaultSelectedBorderColor;
  final unselectedBorderColor =
      merged.unselectedBorderColor ??
      CoreThemeControllerStyle.defaultUnselectedBorderColor;
  final selectedBorderWidth =
      merged.selectedBorderWidth ??
      CoreThemeControllerStyle.defaultSelectedBorderWidth;
  final unselectedBorderWidth =
      merged.unselectedBorderWidth ??
      CoreThemeControllerStyle.defaultUnselectedBorderWidth;
  // Preview circle defaults to a fully round dot, but the override path
  // wins so the resolved chrome reflects `merged.previewBorderRadius`
  // directly (Epic #1603 chaining gate — always-inline radius).
  final previewBorderRadius =
      merged.previewBorderRadius ??
      CoreThemeControllerStyle.defaultPreviewBorderRadius;
  // Swatch button background fill. Web EMIT is theme-free: `.toValue()`
  // emits the token name as a `rgb(var(--coui-<token>))` reference for
  // the browser to resolve at runtime (no `scheme.resolve`, which is a
  // no-op on Web).
  final buttonBackgroundColor =
      merged.buttonBackgroundColor ??
      CoreThemeControllerStyle.defaultButtonBackgroundColor;
  final buttonBackgroundColorValue = buttonBackgroundColor.toValue();
  // Whether the button paints a fill at rest — the question a surface
  // material hangs on (see [buildButtonClassName]).
  final buttonPaintsFill = surfacePaintsFill(buttonBackgroundColor);
  // ─── Disabled · label ─────────────────────────────────
  final disabledBorderColorValue =
      (merged.disabledBorderColor ??
              CoreThemeControllerStyle.defaultDisabledBorderColor)
          .toValue();
  final disabledPreviewColorValue =
      (merged.disabledPreviewColor ??
              CoreThemeControllerStyle.defaultDisabledPreviewColor)
          .toValue();
  final labelStyle = CoreThemeControllerStyle.defaultLabelStyle.merge(
    merged.labelStyle,
  );
  final labelEmit = emitTypography(
    labelStyle,
    CoreThemeControllerStyle.defaultLabelStyle,
  );
  // The role carries no colour, so exactly one colour utility lands on
  // the label — two competing `text-*` classes would be settled by
  // stylesheet order rather than by anything stated here.
  final labelColorEmit = emitColor(
    labelStyle.color ?? merged.labelColor,
    CoreThemeControllerStyle.defaultLabelColor,
    .text,
  );
  final selectedLabelColorEmit = emitColor(
    labelStyle.color ?? merged.selectedLabelColor,
    CoreThemeControllerStyle.defaultSelectedLabelColor,
    .text,
  );
  final disabledLabelColorEmit = emitColor(
    merged.disabledLabelColor,
    CoreThemeControllerStyle.defaultDisabledLabelColor,
    .text,
  );
  final labelGapStyle = CoreThemeControllerStyle.defaultLabelGapStyle.merge(
    merged.labelGapStyle,
  );
  // Per-state swatch border colours — emitted inline (the border width /
  // style vary by selection state in the same `Styles(raw)` bundle, so
  // colour stays inline alongside). Web EMIT is theme-free → `.toValue()`.
  final selectedBorderColorValue = selectedBorderColor.toValue();
  final unselectedBorderColorValue = unselectedBorderColor.toValue();
  // Nested Clickable slot — partial default merged with the override,
  // raw-forwarded (the Clickable's own resolver fills the rest).
  final clickableStyle = CoreThemeControllerStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );

  // ─── Local builders ───────────────────────────────────
  // Closures capture every chrome value above — no named-arg
  // explosion. Local to the resolver, inaccessible from outside.

  /// Composes the root `<div>` Tailwind className — flex grid
  /// container that wraps the swatch buttons.
  String buildRootClassName() =>
      '${WebLayout.flex} ${WebLayout.flexRow} ${WebLayout.flexWrap}';

  /// Composes the root `<div>` inline-CSS bundle — the inter-button
  /// gap (through `spaceCss` from the resolved logical-px value).
  Styles buildRootInlineStyles() {
    return Styles(raw: {'gap': spaceCss(buttonSpacing)});
  }

  /// Composes a swatch button `<div>` Tailwind className. Interaction
  /// chrome (cursor / focus ring / press) is owned by the composing
  /// `Clickable` — no cursor class here.
  ///
  /// Carries the surface marker only while the button paints a fill
  /// ([buttonPaintsFill]). The default button is a ring around the
  /// palette with no body, and a material handed to a box that is not
  /// there frosts the page behind nothing. The Flutter twin forces
  /// `surfaceBlur: 0` on the same answer — see `selectedContainerStyle`.
  String buildButtonClassName() => [
    'box-border',
    WebLayout.relative,
    WebLayout.inlineFlex,
    WebLayout.itemsCenter,
    WebLayout.justifyCenter,
    if (buttonPaintsFill) ...webSurfaceMarkerFor(.content),
  ].join(' ');

  /// Composes the swatch button `<div>` inline-CSS bundle for the
  /// given selection / enabled state — size, radius, background fill,
  /// and the resolved border (width / colour) for that state.
  Styles buildButtonInlineStyles({
    required bool selected,
    required bool enabled,
  }) {
    return Styles(
      raw: {
        'width': '${buttonSize / kRemDivisor}rem',
        'height': '${buttonSize / kRemDivisor}rem',
        'background-color': buttonBackgroundColorValue,
        'border-radius': buttonRadius.toValue(),
        'border-style': 'solid',
        'border-width': selected
            ? strokeWidthCss(selectedBorderWidth)
            : strokeWidthCss(unselectedBorderWidth),
        // Disabled keeps the selected *width* and drops only the colour
        // — a locked selected swatch is still the selected one.
        'border-color': !enabled
            ? disabledBorderColorValue
            : selected
            ? selectedBorderColorValue
            : unselectedBorderColorValue,
        // The other half of the marker above — publishes the fill so a
        // material preset can restate it at its own alpha. Every state
        // shares the same fill token (selection never changes the
        // background), so this is the same value for all four.
        if (buttonPaintsFill) ...surfaceFillVar(buttonBackgroundColor),
      },
    );
  }

  /// The palette circle — a horizontal flex so its segments divide it
  /// evenly, clipped to the round radius so N columns read as one
  /// circle. Two colours are two halves (the canvas picture), three or
  /// four divide the same circle.
  ///
  /// Wears [kThemeSwatchPaletteMarker] so the pressed rule in
  /// [ResolvedThemeControllerRules] can shrink it.
  String buildPreviewClassName() =>
      '${WebLayout.flex} ${WebLayout.flexRow} ${WebLayout.overflowHidden} '
      '${WebLayout.shrinkZero} $kThemeSwatchPaletteMarker';

  Styles buildPreviewInlineStyles() {
    return Styles(
      raw: {
        'width': '${previewSize / kRemDivisor}rem',
        'height': '${previewSize / kRemDivisor}rem',
        'border-radius': previewBorderRadius.toValue(),
      },
    );
  }

  /// One palette segment — `flex-1` so N of them split the circle. The
  /// widget layers the caller's colour on; disabled bakes the disabled
  /// fill in here instead (the palette discards its colours when locked).
  String buildSegmentClassName() => WebLayout.flex1;

  Styles? buildSegmentInlineStyles({required bool enabled}) => enabled
      ? null
      : Styles(raw: {'background-color': disabledPreviewColorValue});

  /// The swatch column — button over label, centred.
  String buildSwatchClassName() =>
      '${WebLayout.inlineFlex} ${WebLayout.flexCol} ${WebLayout.itemsCenter}';

  /// The swatch column's floor — a `min-width`, not a `width`, so a longer
  /// theme name widens its own cell instead of being cut. The button and
  /// the label stay centred in it (`items-center`).
  Styles buildSwatchInlineStyles() {
    return Styles(raw: {'min-width': '${swatchMinWidth / kRemDivisor}rem'});
  }

  /// The label — typography role class (+ overlay inline if any) and
  /// the colour, class for a token, inline for a raw override.
  ///
  /// The ink is the state's: disabled, else selected, else the resting
  /// one.
  Emit labelColorFor({
    required bool enabled,
    required bool selected,
  }) => !enabled
      ? disabledLabelColorEmit
      : selected
      ? selectedLabelColorEmit
      : labelColorEmit;

  String buildLabelClassName({required bool enabled, required bool selected}) =>
      [
        labelEmit.className,
        labelColorFor(enabled: enabled, selected: selected).className,
      ].where((c) => c.isNotEmpty).join(' ');

  Styles? buildLabelInlineStyles({
    required bool enabled,
    required bool selected,
  }) {
    final colorInline = labelColorFor(
      enabled: enabled,
      selected: selected,
    ).inline;
    final raw = {...?labelEmit.inline, ...?colorInline};
    return raw.isEmpty ? null : Styles(raw: raw);
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedThemeController(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    swatch: WebElementChrome(
      className: buildSwatchClassName(),
      inlineStyles: buildSwatchInlineStyles(),
    ),
    selectedButton: WebElementChrome(
      className: buildButtonClassName(),
      inlineStyles: buildButtonInlineStyles(selected: true, enabled: true),
    ),
    unselectedButton: WebElementChrome(
      className: buildButtonClassName(),
      inlineStyles: buildButtonInlineStyles(selected: false, enabled: true),
    ),
    disabledButton: WebElementChrome(
      className: buildButtonClassName(),
      inlineStyles: buildButtonInlineStyles(selected: false, enabled: false),
    ),
    disabledSelectedButton: WebElementChrome(
      className: buildButtonClassName(),
      inlineStyles: buildButtonInlineStyles(selected: true, enabled: false),
    ),
    preview: WebElementChrome(
      className: buildPreviewClassName(),
      inlineStyles: buildPreviewInlineStyles(),
    ),
    segment: WebElementChrome(
      className: buildSegmentClassName(),
      inlineStyles: buildSegmentInlineStyles(enabled: true),
    ),
    disabledSegment: WebElementChrome(
      className: buildSegmentClassName(),
      inlineStyles: buildSegmentInlineStyles(enabled: false),
    ),
    label: WebElementChrome(
      className: buildLabelClassName(enabled: true, selected: false),
      inlineStyles: buildLabelInlineStyles(enabled: true, selected: false),
    ),
    selectedLabel: WebElementChrome(
      className: buildLabelClassName(enabled: true, selected: true),
      inlineStyles: buildLabelInlineStyles(enabled: true, selected: true),
    ),
    disabledLabel: WebElementChrome(
      className: buildLabelClassName(enabled: false, selected: false),
      inlineStyles: buildLabelInlineStyles(enabled: false, selected: false),
    ),
    labelGapStyle: labelGapStyle,
    clickableStyle: clickableStyle,
  );
}

// ═══════════════════════════════════════════════════
// Resolver — scoped hover / pressed rules (category C)
// ═══════════════════════════════════════════════════

/// The class the palette circle wears so the pressed rule can reach it.
const String kThemeSwatchPaletteMarker = 'co-theme-swatch-palette';

/// Scoped CSS text for the `<style>` block in `ThemeController`. Carries
/// the two pseudo-state looks no preset class states: the ring an
/// unselected swatch grows while it is hovered or pressed, and the
/// smaller palette circle while it is pressed.
///
/// Empty when the style states neither.
class ResolvedThemeControllerRules {
  /// Creates a [ResolvedThemeControllerRules].
  const ResolvedThemeControllerRules({
    required this.ringClass,
    required this.pressClass,
    required this.css,
  });

  /// Class an **unselected, enabled** swatch button wears so the ring
  /// rule reaches it. Empty exactly when the ring rule is.
  final String ringClass;

  /// Class an **enabled** swatch button (selected or not) wears so the
  /// pressed palette rule reaches it. Empty exactly when that rule is.
  final String pressClass;

  /// Raw CSS rule text.
  final String css;
}

/// Resolves the scoped hover / pressed rules for a `ThemeController`.
///
/// Runs the same merge chain as [resolveThemeController], so the ring and
/// the pressed palette the rules carry come from the values the button
/// itself resolved.
///
/// The ring is `!important` on purpose: the button states its border
/// inline (width and colour per selection state, so a locked or selected
/// swatch needs no rule), and an inline declaration beats every
/// stylesheet rule that lacks it. The rule only ever lands on the
/// unselected, enabled button, whose resting border is the one it
/// replaces. The pressed palette is a `transform`, not a size: it shrinks
/// the circle about its centre without moving the ring or the label.
///
/// Content-addressed, like the radio's halo rule: two controllers that
/// resolve to the same look share one class instead of one per instance,
/// and the server and the client agree on the name without an id.
ResolvedThemeControllerRules resolveThemeControllerRules(
  BuildContext context, {
  required CoreThemeControllerSize size,
  CoreThemeControllerStyle? themeControllerStyle,
}) {
  final controllerTheme = context.theme.coreComponentTheme?.themeController;
  final merged = resolveStyleChain(
    CoreThemeControllerStyle.defaultsBySize[size]!,
    [controllerTheme?.style, themeControllerStyle],
  );
  final ringColor =
      (merged.hoverBorderColor ??
              CoreThemeControllerStyle.defaultHoverBorderColor)
          .toValue();
  final ringWidth =
      merged.hoverBorderWidth ??
      CoreThemeControllerStyle.defaultHoverBorderWidth;
  final previewSize =
      merged.previewSize ?? CoreThemeControllerStyle.defaultPreviewSize;
  final shrink =
      merged.pressedPreviewShrink ??
      CoreThemeControllerStyle.defaultPressedPreviewShrink;
  // A ratio, not a length: the transform scales the circle whatever root
  // font size its `rem` size resolves against.
  final pressedScale = previewSize > 0 && shrink > 0
      ? (previewSize - shrink) / previewSize
      : 1.0;

  final hasRing = ringWidth > 0;
  final hasPress = pressedScale < 1;
  if (!hasRing && !hasPress) {
    return const ResolvedThemeControllerRules(
      ringClass: '',
      pressClass: '',
      css: '',
    );
  }
  final ringSeed = '$ringColor|${strokeWidthCss(ringWidth)}';
  final pressSeed = '$pressedScale';
  final ringClass = hasRing
      ? 'co-theme-swatch-ring-${_stableHash(ringSeed)}'
      : '';
  final pressClass = hasPress
      ? 'co-theme-swatch-press-${_stableHash(pressSeed)}'
      : '';
  // hover → active, so a pressed swatch does not step back to the hover
  // look on the same-specificity tie while the pointer is still over it.
  final css = StringBuffer();
  if (hasRing) {
    css.write(
      '.$ringClass:hover,.$ringClass:active'
      '{border-width:${strokeWidthCss(ringWidth)}!important;'
      'border-color:$ringColor!important;}',
    );
  }
  if (hasPress) {
    css.write(
      '.$pressClass:active .$kThemeSwatchPaletteMarker'
      '{transform:scale(${_trimmed(pressedScale)});}',
    );
  }
  return ResolvedThemeControllerRules(
    ringClass: ringClass,
    pressClass: pressClass,
    css: css.toString(),
  );
}

/// A string hash that is the same on the VM and in the browser.
///
/// `String.hashCode` is not: the server renders the class name and the
/// client renders it again, and the two must agree.
String _stableHash(String seed) {
  // FNV-1a, 32 bit. Not a design token: pure hash arithmetic.
  var hash = 0x811c9dc5;
  for (final unit in seed.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(36);
}

/// A number to four decimals, trailing zeros dropped.
String _trimmed(double value) =>
    value.toStringAsFixed(4).replaceFirst(RegExp(r'\.?0+$'), '');
