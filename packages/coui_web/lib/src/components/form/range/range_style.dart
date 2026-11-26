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

/// Decimals kept when a value's `[0, 1]` position is written into a CSS
/// `calc()`. Four is sub-pixel on any realistic track width.
const _kRatioDecimalPlaces = 4;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Range`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                            // outer row (flex)
///   ├─ leading (Component)                 // optional caller slot
///   ├─ Gap (minMaxGapStyle)              // rendered only when leading != null
///   ├─ track (<div>)                       // inactive rail — decorative,
///   │                                      // no role (pointerdown still
///   │                                      // drags the nearest thumb)
///   │    ├─ fill (<div>)                   // active range
///   │    ├─ minThumb (<div role="slider">) // independently focusable —
///   │    │                                 // co_range wires role/tabindex/
///   │    │                                 // aria-*/keydown directly
///   │    └─ maxThumb (<div role="slider">) // same, upper bound
///   ├─ Gap (minMaxGapStyle)              // rendered only when trailing != null
///   └─ trailing (Component)                // optional caller slot
/// ```
///
/// All paint-ready fields are [WebElementChrome] — `co_range` reads
/// `resolved.<slot>.className` / `resolved.<slot>.inlineStyles` straight
/// off. Runtime state (`enabled` / `minPercent` / `maxPercent`) is
/// consumed by [resolveRange] as arguments; the widget re-invokes the
/// resolver every build.
///
/// Per Epic #1603 (옵션 B 최종, single inline signature) every chrome
/// value (track / fill / thumb colour, track height, thumb size, thumb
/// border width, border radius) is emitted **inline** through
/// `(merged.X ?? CoreRangeStyle.defaultX).toValue()` / rem — no
/// class-drop branch decides between a Tailwind utility and an inline
/// rule. Only structural classes (`relative` / `flex` / `absolute` /
/// `items-center` …) and the cursor pseudo-affordance remain on the
/// className surface.
///
/// The resolver carries Cat 1 `WebElementChrome` slots (paint-ready
/// chrome) plus the nested [CoreGapStyle] slot [minMaxGapStyle] which is
/// forwarded to `Gap(gapStyle: …)` rendered between the track and the
/// optional `leading` / `trailing` composition slots — mirroring the
/// Flutter widget 1:1. The track / thumb are chrome of the range slider
/// (not independent CoUI components), so no nested `CoreXxxStyle` slot
/// is exposed for them.
class ResolvedRange implements WebResolvedChrome {
  /// Creates a [ResolvedRange].
  const ResolvedRange({
    required this.root,
    required this.track,
    required this.fill,
    required this.minThumb,
    required this.maxThumb,
    required this.minMaxGapStyle,
    required this.minThumbPositioner,
    required this.maxThumbPositioner,
    required this.focusOutlineStyle,
  });

  /// Paint-ready chrome for the outermost `<div>` row container.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the inactive track `<div>` — decorative
  /// (no ARIA role); `co_range` still wires a `pointerdown` handler on
  /// it so click/drag-anywhere-on-the-track still moves the nearest
  /// thumb.
  final WebElementChrome track;

  /// Paint-ready chrome for the active fill `<div>` inside the track.
  final WebElementChrome fill;

  /// Paint-ready chrome for the min-value thumb `<div>` — `co_range`
  /// makes this its own `role="slider"` element (see [ResolvedRange]
  /// doc), independently focusable from [maxThumb].
  final WebElementChrome minThumb;

  /// Paint-ready chrome for the max-value thumb `<div>` — `co_range`
  /// makes this its own `role="slider"` element (see [ResolvedRange]
  /// doc), independently focusable from [minThumb].
  final WebElementChrome maxThumb;

  /// Nested [CoreGapStyle] slot — passed to `Gap(gapStyle: …)` on
  /// either side of the track when [Range.leading] / [Range.trailing]
  /// is supplied. `Gap` runs its own resolve / scaling step.
  final CoreGapStyle minMaxGapStyle;

  /// Paint-ready chrome for the min thumb's positioner — the
  /// `FocusOutline` box that carries the thumb's travel along the track.
  final WebElementChrome minThumbPositioner;

  /// Paint-ready chrome for the max thumb's positioner.
  final WebElementChrome maxThumbPositioner;

  /// Nested style forwarded to the `FocusOutline` the focused thumb
  /// composes, which owns the keyboard ring on both platforms.
  /// Raw-forwarded — that component's resolver fills every field left
  /// null here.
  final CoreFocusOutlineStyle focusOutlineStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — single entry point
// ═══════════════════════════════════════════════════

/// Client-side runtime config for `Range`. Fed to the pointer handler,
/// which is the one place that needs a *number* rather than chrome: a
/// thumb's edges stop at the track ends, so a pointer x maps over
/// `trackWidth - thumbSize`, and only Dart can do that arithmetic
/// against a live `getBoundingClientRect`.
///
/// Kept off [ResolvedRange] on purpose — that carries chrome slots and
/// nested styles only, and a raw scalar there would be the first crack
/// in it.
class ResolvedRangeRuntime {
  /// Creates a [ResolvedRangeRuntime].
  const ResolvedRangeRuntime({required this.thumbSize});

  /// Resolved thumb size (logical px) — the span subtracted from the
  /// track width when a pointer position becomes a value.
  final double thumbSize;
}

/// Resolves the client-side runtime config for the given [context].
///
/// Runs the same merge chain as [resolveRange] so the number the pointer
/// maps against is the one the thumbs are actually drawn at.
ResolvedRangeRuntime resolveRangeRuntime(
  BuildContext context, {
  CoreRangeStyle? rangeStyle,
}) {
  final merged = resolveStyleChain(const CoreRangeStyle(), [
    context.theme.coreComponentTheme?.range?.style,
    rangeStyle,
  ]);
  return ResolvedRangeRuntime(
    thumbSize: merged.thumbSize ?? CoreRangeStyle.defaultThumbSize,
  );
}

/// Resolves [ResolvedRange] for the given [context].
///
/// Walks the nested-merge chain (Epic #1302):
///
/// ```text
/// design system default
///   → theme.coreComponentTheme.range.style
///   → widget.rangeStyle
/// ```
///
/// [minRatio] / [maxRatio] are the per-build positions in `[0, 1]`. The
/// resolver — not the widget — turns them into CSS, because the thumbs
/// and the fill need different expressions off the same numbers: a thumb
/// travels `100% - thumbSize` and the fill runs between thumb centres.
///
/// (superseded doc line)
/// (`'0.0'..'100.0'` as decimal strings) for the min / max handles —
/// the resolver bakes them into the fill insets and thumb left positions.
ResolvedRange resolveRange(
  BuildContext context, {
  required bool enabled,
  required double minRatio,
  required double maxRatio,
  CoreRangeStyle? rangeStyle,
}) {
  final csTheme = context.theme.coreComponentTheme?.range;

  final merged = resolveStyleChain(const CoreRangeStyle(), [
    csTheme?.style,
    rangeStyle,
  ]);

  // ─── Resolved chrome values (single inline signature, theme-free) ──
  // Every chrome value below is `(merged.X ?? CoreRangeStyle.defaultX)`
  // and is emitted inline via `.toValue()` / rem — no class-drop branch
  // toggles a Tailwind colour utility on / off. Colour EMIT is theme-free
  // on Web: `CoreColorToCss.toValue()` emits the token name
  // (`rgb(var(--coui-X))`) and the browser resolves it at runtime, so no
  // `scheme.resolve` (a no-op on Web) is involved.
  final activeTrackColor =
      (enabled
              ? (merged.activeTrackColor ??
                    CoreRangeStyle.defaultActiveTrackColor)
              : (merged.disabledActiveTrackColor ??
                    CoreRangeStyle.defaultDisabledActiveTrackColor))
          .toValue();
  final inactiveTrackColor =
      (enabled
              ? (merged.inactiveTrackColor ??
                    CoreRangeStyle.defaultInactiveTrackColor)
              : (merged.disabledInactiveTrackColor ??
                    CoreRangeStyle.defaultDisabledInactiveTrackColor))
          .toValue();
  final thumbColor =
      (enabled
              ? (merged.thumbColor ?? CoreRangeStyle.defaultThumbColor)
              : (merged.disabledThumbColor ??
                    CoreRangeStyle.defaultDisabledThumbColor))
          .toValue();
  final thumbBorderColor =
      (enabled
              ? (merged.thumbBorderColor ??
                    CoreRangeStyle.defaultThumbBorderColor)
              : (merged.disabledThumbBorderColor ??
                    CoreRangeStyle.defaultDisabledThumbBorderColor))
          .toValue();
  final trackHeight = merged.trackHeight ?? CoreRangeStyle.defaultTrackHeight;
  final thumbSize = merged.thumbSize ?? CoreRangeStyle.defaultThumbSize;
  final thumbBorderWidth =
      merged.thumbBorderWidth ?? CoreRangeStyle.defaultThumbBorderWidth;
  // Nested `CoreGapStyle` slot — merged design-system default +
  // theme + per-instance override, forwarded to `Gap(gapStyle: …)`
  // in `co_range` (no inline `gap` CSS emitted on the root).
  final minMaxGapStyle = CoreRangeStyle.defaultMinMaxGapStyle.merge(
    merged.minMaxGapStyle,
  );

  // Pill / circle radius — range corners are fully rounded by default
  // (`CoreRangeStyle.defaultBorderRadius`, i.e. the old `rounded-full`).
  // Routed through the contract const so the platform style file never
  // references a common radius token directly, and emitted inline
  // (single-signature CSS surface) via `.toValue()`.
  final pillRadius = (merged.borderRadius ?? CoreRangeStyle.defaultBorderRadius)
      .toValue();
  // Keyboard focus ring — raw-forwarded to the `FocusOutline` each thumb
  // composes, which draws it on both platforms. Only the field this
  // component diverges on is stated; the rest stay null so that
  // component's resolver supplies its own defaults.
  final focusOutlineStyle = CoreRangeStyle.defaultFocusOutlineStyle.merge(
    merged.focusOutlineStyle,
  );

  // How far a thumb's left edge has travelled at a given position. Its
  // edges — not its centre — stop at the track ends, so the span is
  // `100% - thumbSize` (the Flutter twin's `ratio * (trackWidth -
  // thumbSize)`). Thumbs and fill both read this, which is what keeps
  // them agreeing at every value rather than only at the midpoint.
  String travel(double ratio) =>
      '${ratio.toStringAsFixed(_kRatioDecimalPlaces)} * '
      '(100% - ${thumbSize / kRemDivisor}rem)';
  final halfThumb = '${thumbSize / 2 / kRemDivisor}rem';

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer range `<div>` Tailwind className. The gap
  /// between the track and the optional leading / trailing slots is
  /// rendered by an explicit `Gap` widget (driven by the nested
  /// [minMaxGapStyle] slot), so no inline `gap` CSS is emitted here.
  String buildRootClassName() => WebLayout.relativeFlexItemsCenterFull;

  /// Composes the inactive track `<div>` Tailwind className —
  /// structural + disabled affordance only (colour / height / radius
  /// live inline).
  ///
  /// No `overflow-hidden`: the fill carries its own pill `border-radius`
  /// so it stays rounded without clipping, and the thumbs — which are
  /// taller than the track and centred on it (`top-1/2 -translate-y-1/2`)
  /// — must overflow the track vertically instead of being cut off.
  String buildTrackClassName() => <String>[
    '${WebLayout.relative} ${WebLayout.wFull} ${WebLayout.grow}',
    // The whole track is interactive (click / drag moves a handle), so
    // it carries the grab cursor over its full width — matching Flutter,
    // where the pointer is a hand anywhere on the track, not only the
    // thumbs.
    enabled ? 'cursor-grab' : 'cursor-not-allowed',
  ].join(' ');

  /// Composes the inactive track `<div>` inline CSS — `height`, a pill
  /// `border-radius` and the resolved inactive-track `background-color`.
  Styles buildTrackInlineStyles() => .new(
    raw: {
      'height': '${trackHeight / kRemDivisor}rem',
      'border-radius': pillRadius,
      'background-color': inactiveTrackColor,
    },
  );

  /// Composes the active fill `<div>` Tailwind className — structural
  /// only (colour lives inline).
  String buildFillClassName() => WebLayout.absoluteHFull;

  /// Composes the active fill `<div>` inline CSS — `left` + `width`, a
  /// pill `border-radius` plus the resolved active-track
  /// `background-color`.
  ///
  /// The fill spans thumb centre to thumb centre, so both ends are the
  /// thumb's travel plus half a thumb — not plain percentages, which
  /// would leave the fill and the thumbs disagreeing everywhere except
  /// the midpoint.
  Styles buildFillInlineStyles() => .new(
    raw: {
      'left': 'calc(${travel(minRatio)} + $halfThumb)',
      'width': 'calc(${travel(maxRatio)} - ${travel(minRatio)})',
      'border-radius': pillRadius,
      'background-color': activeTrackColor,
    },
  );

  /// Composes a thumb `<div>` Tailwind className — structural + cursor
  /// affordance only (colour / size / radius / border live inline).
  ///
  /// `outline-none` suppresses the browser's native ring — the keyboard
  /// ring is drawn by the `FocusOutline` that positions this thumb.
  String buildThumbClassName() => <String>[
    enabled ? 'cursor-grab' : 'cursor-not-allowed',
    'outline-none',
  ].join(' ');

  /// Composes a thumb positioner `<div>` Tailwind className. The
  /// positioner is the `FocusOutline` wrapping the thumb, so the ring it
  /// draws follows this box; being absolute with no width it shrinks to
  /// the thumb it holds.
  String buildThumbPositionerClassName() =>
      '${WebLayout.absolute} ${WebLayout.topHalf} '
      '${WebLayout.negTranslateYHalf}';

  /// Composes a thumb positioner `<div>` inline CSS — its travel along
  /// the track.
  Styles buildThumbPositionerInlineStyles(double ratio) => .new(
    raw: {'left': 'calc(${travel(ratio)})'},
  );

  /// Composes a thumb `<div>` inline CSS — `width` / `height`, a circular
  /// `border-radius`, background / border colour and the resolved border
  /// width. Its position lives on the positioner above.
  Styles buildThumbInlineStyles() => .new(
    raw: {
      'width': '${thumbSize / kRemDivisor}rem',
      'height': '${thumbSize / kRemDivisor}rem',
      'border-radius': pillRadius,
      'background-color': thumbColor,
      'border-style': 'solid',
      'border-width': strokeWidthCss(thumbBorderWidth),
      'border-color': thumbBorderColor,
    },
  );

  return ResolvedRange(
    root: WebElementChrome(
      className: buildRootClassName(),
      // Reserve the thumb's height in-flow — mirrors Flutter's
      // `SizedBox(height: thumbSize)`. The Web thumbs are absolutely
      // positioned inside the track (contribute no height), so without
      // this the root settles on the 6px rail height and the track
      // centreline sits a few px above the Flutter twin.
      inlineStyles: Styles(
        raw: {'min-height': '${thumbSize / kRemDivisor}rem'},
      ),
    ),
    track: WebElementChrome(
      className: buildTrackClassName(),
      inlineStyles: buildTrackInlineStyles(),
    ),
    fill: WebElementChrome(
      className: buildFillClassName(),
      inlineStyles: buildFillInlineStyles(),
    ),
    minThumb: WebElementChrome(
      className: buildThumbClassName(),
      inlineStyles: buildThumbInlineStyles(),
    ),
    maxThumb: WebElementChrome(
      className: buildThumbClassName(),
      inlineStyles: buildThumbInlineStyles(),
    ),
    minMaxGapStyle: minMaxGapStyle,
    minThumbPositioner: WebElementChrome(
      className: buildThumbPositionerClassName(),
      inlineStyles: buildThumbPositionerInlineStyles(minRatio),
    ),
    maxThumbPositioner: WebElementChrome(
      className: buildThumbPositionerClassName(),
      inlineStyles: buildThumbPositionerInlineStyles(maxRatio),
    ),
    focusOutlineStyle: focusOutlineStyle,
  );
}
