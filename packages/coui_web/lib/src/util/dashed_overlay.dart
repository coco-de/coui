import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/util/core_to_css.dart' show radiusCss;
import 'package:jaspr/dom.dart' show Styles;

/// Shared chrome for the dashed/dotted-border SVG overlay.
///
/// CSS `border-style: dashed` leaves the dash pattern to the engine —
/// it differs per browser and cannot be tuned. Components that draw a
/// dashed (or dotted) boundary instead compose an absolutely-positioned
/// `<svg><rect/></svg>` overlay whose `stroke-dasharray` carries the
/// Core dash tokens, so the pattern is deterministic across browsers,
/// user-tunable through the component's `dashLength` / `dashGap` style
/// slots, and identical to the Flutter dash painter.
///
/// The `<rect>` strokes with `currentColor`, so the host's state /
/// hover text-colour classes recolour the dashes without extra wiring.
/// The host root must be `relative`.
///
/// One function per surface (dedup — a single source for the overlay
/// geometry): [dashedOverlaySvgClassName] / [dashedOverlaySvgStyles]
/// dress the `<svg>`, [dashedOverlayRectStyles] dresses the `<rect>`.
String dashedOverlaySvgClassName() =>
    '${WebLayout.absolute} ${WebLayout.insetZero}';

/// Inline CSS for the overlay `<svg>` — an SVG is a replaced element,
/// so `inset-0` alone leaves it at its intrinsic 300×150 default; both
/// axes are pinned, and pointer events fall through to the host.
Styles dashedOverlaySvgStyles() => const .new(
  raw: {
    'width': '100%',
    'height': '100%',
    'pointer-events': 'none',
  },
);

/// Inline CSS for the overlay `<rect>` — SVG2 geometry properties
/// (inset by half the stroke so the dash is not clipped by the
/// viewport), the stroke pattern, and the host's corner radius.
///
/// [strokeWidth] is a caller-supplied CSS length — usually
/// `strokeWidthCss(borderWidth)` for a border that is meant to be
/// stroke-axis-bound (a token value rides `var(--coui-stroke-width-N)`
/// so a preset like neo-brutalism's `strokeFloor` can thicken it; an
/// arbitrary override falls back to a literal px), but any caller whose
/// Flutter twin does not run that value through `theme.geometry.stroke`
/// passes its own unfloored literal instead (e.g. `'${x / kRemDivisor}rem'`)
/// to stay behaviourally identical to that twin. The util does not
/// decide this — every derived dimension below runs the arithmetic in
/// CSS `calc()` precisely so it works for either shape without needing
/// to know which one it got.
///
/// [radius] is the host's uniform outer corner radius in logical px. Token
/// values retain their CSS variable so the surface geometry reaches the
/// stroke just as it reaches the host's border-radius. An SVG
/// `rect` cannot express per-corner radii (`rx` rejects the 4-corner
/// CSS shorthand). [dotted] renders the CSS `dotted` analogue: round
/// caps with zero-length segments spaced one stroke-width apart. [solid]
/// strokes the same rect unbroken (`stroke-dasharray: none`) — for a host
/// state that turns its dashed edge solid without moving it.
Styles dashedOverlayRectStyles({
  required String strokeWidth,
  required double dashLength,
  required double dashGap,
  required double radius,
  bool dotted = false,
  bool solid = false,
}) => .new(
  raw: {
    'x': 'calc($strokeWidth / 2)',
    'y': 'calc($strokeWidth / 2)',
    'width': 'calc(100% - $strokeWidth)',
    'height': 'calc(100% - $strokeWidth)',
    'rx': 'max(0px, calc(${radiusCss(radius)} - $strokeWidth / 2))',
    'fill': 'none',
    'stroke': 'currentColor',
    'stroke-width': strokeWidth,
    if (dotted) 'stroke-linecap': 'round',
    'stroke-dasharray': solid
        ? 'none'
        : dotted
        ? '0 calc($strokeWidth * 2)'
        : '$dashLength $dashGap',
  },
);
