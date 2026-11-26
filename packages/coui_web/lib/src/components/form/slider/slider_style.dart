library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

/// Decimals kept when the value's `[0, 1]` position is written into a
/// CSS `calc()`. Four is sub-pixel on any realistic track width.
const _kRatioDecimalPlaces = 4;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Slider`.
///
/// DOM shape:
///
/// ```text
/// root (<div role="slider">)
///   └─ FocusOutline (composed component — draws the keyboard ring)
///        └─ interior (<div>)
///             ├─ track (<div>)
///             │    └─ fill (<div>)
///             └─ thumbHost (FocusOutline — draws the keyboard ring)
///                  └─ thumb (<div>)
/// ```
///
/// All slot chromes are non-null — `co_slider` reads
/// `resolved.<slot>.className` / `resolved.<slot>.inlineStyles` straight
/// off without invoking any top-level builder. The resolver closes over
/// the runtime state (`enabled` / `percent`) supplied at build time.
///
/// Per Epic #1603 (옵션 B 최종, single inline signature) every chrome
/// value (track / fill / thumb colour, track height, thumb size, thumb
/// border width, border radius, container padding) is emitted **inline**
/// through `(merged.X ?? CoreSliderStyle.defaultX).toValue()` / rem — no
/// class-drop branch decides between a Tailwind utility and an inline
/// rule. Only structural classes (`relative` / `flex` / `absolute` /
/// `items-center` …) and the cursor pseudo-affordance remain on the
/// className surface.
///
/// The resolver carries only `WebElementChrome` slots — no scalar
/// metadata or behavioural fields leak out. Semantic identifiers stay on
/// the widget prop (slider has no public variant enum).
class ResolvedSlider implements WebResolvedChrome {
  /// Creates a [ResolvedSlider].
  const ResolvedSlider({
    required this.root,
    required this.interior,
    required this.track,
    required this.fill,
    required this.thumb,
    required this.thumbHost,
    required this.slotGapStyle,
    required this.focusOutlineStyle,
  });

  /// Paint-ready chrome for the outermost `<div role="slider">` element
  /// — flex layout, container vertical padding, plus the tick-label
  /// typography overrides that cascade to child labels.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the interior `<div>` — the track + thumb box,
  /// sized to the thumb. It sits inside the root's container padding and is
  /// the thumb's positioning context. Shrinks beside the slots
  /// (`min-w-0`).
  final WebElementChrome interior;

  /// Paint-ready chrome for the thumb's `FocusOutline` host — it carries
  /// the thumb's position (`left`, vertical centring), so the ring wraps
  /// exactly the thumb.
  final WebElementChrome thumbHost;

  /// Gap between the track and the leading / trailing slots, raw-forwarded
  /// to `Gap`.
  final CoreGapStyle slotGapStyle;

  /// Nested style forwarded to the composed `FocusOutline`, which owns
  /// the keyboard focus ring on both platforms. Raw-forwarded — that
  /// component's resolver fills every field left null here.
  final CoreFocusOutlineStyle focusOutlineStyle;

  /// Paint-ready chrome for the track `<div>` (background rail).
  final WebElementChrome track;

  /// Paint-ready chrome for the fill `<div>` (active portion of the
  /// track from `min` → current value).
  final WebElementChrome fill;

  /// Paint-ready chrome for the thumb `<div>` (drag handle).
  final WebElementChrome thumb;
}

/// Client-side runtime config for `Slider`. Fed to the pointer handler,
/// which is the one place that needs a *number* rather than chrome: the
/// thumb's edges stop at the track ends, so a pointer x maps over
/// `trackWidth - thumbSize`, and only Dart can do that arithmetic
/// against a live `getBoundingClientRect`.
///
/// Kept off [ResolvedSlider] on purpose — that carries chrome slots
/// only, and a raw scalar there would be the first crack in it.
class ResolvedSliderRuntime {
  /// Creates a [ResolvedSliderRuntime].
  const ResolvedSliderRuntime({required this.thumbSize});

  /// Resolved thumb size (logical px) — the span subtracted from the
  /// track width when a pointer position becomes a value.
  final double thumbSize;
}

/// Resolves the client-side runtime config for the given [context].
///
/// Runs the same merge chain as [resolveSlider] so the number the
/// pointer maps against is the one the thumb is actually drawn at.
ResolvedSliderRuntime resolveSliderRuntime(
  BuildContext context, {
  CoreSliderStyle? sliderStyle,
}) {
  final merged = resolveStyleChain(const CoreSliderStyle(), [
    context.theme.coreComponentTheme?.slider?.style,
    sliderStyle,
  ]);
  return ResolvedSliderRuntime(
    thumbSize: merged.thumbSize ?? CoreSliderStyle.defaultThumbSize,
  );
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedSlider] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.slider.style
///   → widget.sliderStyle
/// ```
///
/// The runtime state (`enabled` and `percent`) is captured into the
/// resolver-local closures so each slot's chrome is paint-ready —
/// `co_slider` reads `resolved.<slot>.className` /
/// `resolved.<slot>.inlineStyles` straight off without invoking any
/// top-level builder.
///
/// `ratio` is the current value's position in `[0, 1]`. The resolver —
/// not the widget — turns it into CSS, because the thumb and the fill
/// need different expressions off the same number: the thumb travels
/// `100% - thumbSize` and the fill runs to the thumb's centre.
ResolvedSlider resolveSlider(
  BuildContext context, {
  required bool enabled,
  required double ratio,
  CoreSliderStyle? sliderStyle,
}) {
  final csTheme = context.theme.coreComponentTheme?.slider;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreSliderStyle(), [
    csTheme?.style,
    sliderStyle,
  ]);

  // ─── Resolved chrome values (single inline signature) ──
  // Every chrome value below is `(merged.X ?? CoreSliderStyle.defaultX)`
  // and is emitted inline via `.toValue()` / rem — no class-drop branch
  // toggles a Tailwind utility on / off. Disabled state swaps the
  // colour source to the disabled tokens (matches Flutter parity).
  final trackColor = enabled
      ? (merged.trackColor ?? CoreSliderStyle.defaultTrackColor)
      : (merged.disabledTrackColor ??
            CoreSliderStyle.defaultDisabledTrackColor);
  final activeColor = enabled
      ? (merged.activeColor ?? CoreSliderStyle.defaultActiveColor)
      : (merged.disabledActiveColor ??
            CoreSliderStyle.defaultDisabledActiveColor);
  final thumbColor = enabled
      ? (merged.thumbColor ?? CoreSliderStyle.defaultThumbColor)
      : (merged.disabledThumbColor ??
            CoreSliderStyle.defaultDisabledThumbColor);
  // Thumb border — dedicated `thumbBorderColor` wins, else the active
  // colour doubles as the border (matches Flutter parity); when disabled
  // the thumb states its own border (`disabledThumbBorderColor`).
  final thumbBorderColor = enabled
      ? (merged.thumbBorderColor ??
            merged.activeColor ??
            CoreSliderStyle.defaultThumbBorderColor)
      : (merged.disabledThumbBorderColor ??
            CoreSliderStyle.defaultDisabledThumbBorderColor);
  final trackHeight = merged.trackHeight ?? CoreSliderStyle.defaultTrackHeight;
  final thumbSize = merged.thumbSize ?? CoreSliderStyle.defaultThumbSize;
  final thumbBorderWidth =
      merged.thumbBorderWidth ?? CoreSliderStyle.defaultThumbBorderWidth;
  final containerPadding =
      merged.containerPadding ?? CoreSliderStyle.defaultContainerPadding;
  // Keyboard focus ring — raw-forwarded to the composed `FocusOutline`,
  // which draws it on both platforms. Only the fields this component
  // diverges on are stated; the rest stay null so that component's
  // resolver supplies its own defaults.
  final focusOutlineStyle = CoreSliderStyle.defaultFocusOutlineStyle.merge(
    merged.focusOutlineStyle,
  );
  final slotGapStyle = CoreSliderStyle.defaultSlotGapStyle.merge(
    merged.slotGapStyle,
  );
  // Thumb drop shadow — `emitShadow` so a scale step reads
  // `var(--shadow-<step>)` and the surface style / dark strength reach it.
  final thumbShadowCss = emitShadow(
    merged.thumbShadow ?? CoreSliderStyle.defaultThumbShadow,
    base: kShadowVariableBase,
  );

  // Tick label typography — chrome-only overrides (font / weight /
  // colour / line-height / letter-spacing / family). Cascades from the
  // root element down to caller-supplied child labels.
  final tickLabelStyle = merged.tickLabelStyle != null
      ? const CoreTextStyle().merge(merged.tickLabelStyle)
      : null;

  // Pill / circle radius — slider corners are fully rounded by default
  // (`CoreSliderStyle.defaultBorderRadius`, i.e. the old `rounded-full`).
  // Routed through the contract const so the platform style file never
  // references a common radius token directly, and emitted inline
  // (single-signature CSS surface) via `.toValue()`.
  final pillRadius =
      (merged.borderRadius ?? CoreSliderStyle.defaultBorderRadius).toValue();

  // How far the thumb's left edge has travelled. Its edges — not its
  // centre — stop at the track ends, so the span is `100% - thumbSize`
  // (the Flutter twin's `ratio * (trackWidth - thumbSize)`). The thumb
  // and the fill both read this, which is what keeps them agreeing at
  // every value rather than only at the midpoint.
  final travelExpression =
      '${ratio.toStringAsFixed(_kRatioDecimalPlaces)} * '
      '(100% - ${thumbSize / kRemDivisor}rem)';

  // ─── Local builders ───────────────────────────────────
  // Closures capture every chrome value above — no named-arg
  // explosion. Local to the resolver, inaccessible from outside.

  /// Composes the root `<div role="slider">` Tailwind className —
  /// structural classes plus `outline-none`, which suppresses the
  /// browser's native focus ring so the composed `FocusOutline` is the
  /// single focus indicator. The root takes focus (it owns `tabindex` /
  /// `role="slider"`) but does not draw the ring: its box includes the
  /// container padding, and the Flutter twin keeps that padding outside
  /// the ring.
  String buildRootClassName() =>
      '${WebLayout.relativeFlexItemsCenterFull} outline-none';

  /// Composes the interior `<div>` Tailwind className — the track +
  /// thumb box the ring wraps.
  String buildInteriorClassName() =>
      '${WebLayout.relativeFlexItemsCenterFull} ${WebLayout.minWZero}';

  /// Composes the interior `<div>` inline-CSS bundle — the thumb-sized
  /// height that gives the ring the same box the Flutter twin outlines.
  Styles buildInteriorInlineStyles() => .new(
    raw: {'height': '${thumbSize / kRemDivisor}rem'},
  );

  /// Composes the root `<div>` inline-CSS bundle.
  ///
  /// Emits the design-system container padding (inline rem so
  /// `containerPadding` is the single source of truth) plus the
  /// optional tick-label typography override bundle that cascades down
  /// the container's children (`color` / `font-size` / `font-weight` /
  /// `line-height` / `letter-spacing` / `font-family`) and the
  /// `--coui-slider-focus-color` / `--coui-slider-focus-width` custom
  /// properties consumed by the `focus-visible:` outline utility in
  /// [buildRootClassName].
  Styles buildRootInlineStyles() {
    final raw = {
      'padding': containerPadding.toValue(),
      // Reserve the thumb's height in-flow — mirrors Flutter's
      // `SizedBox(height: thumbSize)`. The Web thumb is absolutely
      // positioned (contributes no height), so without this the root
      // settles on track-height + padding and the track centreline
      // sits a few px above the Flutter twin. Border-box: vertical
      // container padding stacks on top of the thumb size — summed in CSS
      // so the padding stays the same spacing variable as `padding`
      // above, and a density moves the two together.
      'min-height':
          'calc(${thumbSize / kRemDivisor}rem + '
          '${spaceCss(containerPadding.top)} + '
          '${spaceCss(containerPadding.bottom)})',
    };
    if (tickLabelStyle != null) {
      // font-size / font-weight / line-height / letter-spacing AND
      // `color` via the shared `toInlineCss()` override-bundle. Web EMIT
      // is theme-free: a token colour emits `var(--coui-X)` (dark-mode
      // reactive at runtime) without any `scheme.resolve` no-op.
      raw.addAll(tickLabelStyle.toInlineCss());
    }
    return Styles(raw: raw);
  }

  /// Composes the track `<div>` Tailwind className — structural + the
  /// grab cursor over the full track. The whole track is interactive
  /// (clicking / dragging anywhere moves the thumb), so the pointer is a
  /// hand across it — matching the thumb and Flutter. Colour / height /
  /// radius live inline.
  String buildTrackClassName() => <String>[
    WebLayout.relativeFull,
    enabled ? 'cursor-grab' : 'cursor-not-allowed',
  ].join(' ');

  /// Composes the track `<div>` inline-CSS bundle — background colour
  /// plus `height` (so `CoreSliderStyle.defaultTrackHeight` is the
  /// single source of truth) and a pill `border-radius`.
  Styles buildTrackInlineStyles() => .new(
    raw: {
      'background-color': trackColor.toValue(),
      'height': '${trackHeight / kRemDivisor}rem',
      'border-radius': pillRadius,
    },
  );

  /// Composes the fill `<div>` Tailwind className — active portion of
  /// the track. Structural only (colour / radius live inline).
  String buildFillClassName() => WebLayout.absoluteHFull;

  /// Composes the fill `<div>` inline-CSS bundle — runtime `width`,
  /// background colour and a pill `border-radius`.
  ///
  /// The fill runs to the thumb's centre, so it is the thumb's travel
  /// plus half a thumb — not a plain `ratio%`, which would leave the
  /// fill and the thumb disagreeing everywhere except the midpoint.
  Styles buildFillInlineStyles() => .new(
    raw: {
      'width': 'calc($travelExpression + ${thumbSize / 2 / kRemDivisor}rem)',
      'background-color': activeColor.toValue(),
      'border-radius': pillRadius,
    },
  );

  /// Composes the thumb host Tailwind className — positioning only (the
  /// host is the `FocusOutline` that wraps the thumb).
  ///
  /// No horizontal self-translate: `left` already carries the thumb's own
  /// width (see [buildThumbHostInlineStyles]), so the thumb is placed by
  /// its left edge and stays inside the track at both ends.
  String buildThumbHostClassName() =>
      '${WebLayout.absolute} ${WebLayout.topHalf} '
      '${WebLayout.negTranslateYHalf}';

  /// Composes the thumb host inline-CSS bundle — runtime `left`.
  Styles buildThumbHostInlineStyles() => .new(
    raw: {'left': 'calc($travelExpression)'},
  );

  /// Composes the thumb `<div>` Tailwind className — cursor affordance
  /// only (colour / size / radius / border width live inline).
  String buildThumbClassName() =>
      enabled ? 'cursor-grab' : 'cursor-not-allowed';

  /// Composes the thumb `<div>` inline-CSS bundle — `width` / `height`
  /// (resolved thumb size), background / border colour, border width, a
  /// circular `border-radius` and the drop shadow.
  Styles buildThumbInlineStyles() => .new(
    raw: {
      'width': '${thumbSize / kRemDivisor}rem',
      'height': '${thumbSize / kRemDivisor}rem',
      'border-radius': pillRadius,
      'background-color': thumbColor.toValue(),
      'border-style': 'solid',
      'border-width': strokeWidthCss(thumbBorderWidth),
      'border-color': thumbBorderColor.toValue(),
      'box-shadow': thumbShadowCss,
    },
  );

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedSlider(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    interior: WebElementChrome(
      className: buildInteriorClassName(),
      inlineStyles: buildInteriorInlineStyles(),
    ),
    track: WebElementChrome(
      className: buildTrackClassName(),
      inlineStyles: buildTrackInlineStyles(),
    ),
    fill: WebElementChrome(
      className: buildFillClassName(),
      inlineStyles: buildFillInlineStyles(),
    ),
    thumb: WebElementChrome(
      className: buildThumbClassName(),
      inlineStyles: buildThumbInlineStyles(),
    ),
    thumbHost: WebElementChrome(
      className: buildThumbHostClassName(),
      inlineStyles: buildThumbHostInlineStyles(),
    ),
    slotGapStyle: slotGapStyle,
    focusOutlineStyle: focusOutlineStyle,
  );
}
