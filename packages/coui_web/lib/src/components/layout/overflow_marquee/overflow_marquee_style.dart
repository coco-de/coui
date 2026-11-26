import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:jaspr/jaspr.dart' show BuildContext;

/// Tailwind className for the outer `<div>` wrapper. Acts as the
/// stable hook the per-instance scoped `<style>` block (selectors like
/// `#$id`) targets and gives ad-hoc CSS overrides a single anchor.
const _kOverflowMarqueeRootClassName = 'co-om';

/// Tailwind className for the inner intrinsic-sized track `<div>`.
/// Per-instance scoped CSS targets `> .co-om-track` to set
/// `width: max-content` / `display: inline-block` / `white-space: nowrap`.
const _kOverflowMarqueeTrackClassName = 'co-om-track';

// ═══════════════════════════════════════════════════
// Behavioural runtime config (separate resolver — number_ticker pattern)
// ═══════════════════════════════════════════════════

/// Behavioural runtime config for `OverflowMarquee`.
///
/// Carries the *data* that drives the client `OverflowMarqueeMeasurer`
/// (cycle duration, delay, speed step, easing curve, hover-to-pause) and
/// the two values that also shape the scoped `<style>` block
/// (`direction` → fade-mask axis + track main-axis sizing; `fadePortion`
/// → fade-mask length).
///
/// These are behavioural identifiers read by the stateful measurer
/// between builds — not paint-ready CSS chrome — so they are exposed via
/// the dedicated [resolveOverflowMarqueeConfig] entry point (the
/// number_ticker / hover_card separate-resolver pattern) instead of being
/// carried on [ResolvedOverflowMarquee], keeping that struct pure
/// paint-ready chrome per Epic #1603 (옵션 B 최종).
typedef OverflowMarqueeConfig = ({
  /// Effective scroll direction — drives the fade-mask gradient axis and
  /// the track main-axis sizing (`width` vs `height: max-content`).
  CoreAxis direction,

  /// Effective cycle duration (measurer ticker input).
  Duration duration,

  /// Effective delay between cycles (measurer ticker input).
  Duration delayDuration,

  /// Effective speed step (px) — measurer scales scroll speed by content
  /// length using this.
  double step,

  /// Effective edge fade length (px). Zero disables the `mask-image`
  /// gradient.
  double fadePortion,

  /// Effective easing curve (measurer bezier input).
  CoreMarqueeCurve curve,

  /// Effective hover-to-pause behaviour (measurer hover-listener input).
  bool pauseOnHover,
});

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `OverflowMarquee`.
///
/// DOM shape:
///
/// ```text
/// root (<div id=$scopeId class="co-om">)        // outer clipping container
///   ├─ <style> (scoped)                         // composeOverflowMarqueeCss(config, scopeId)
///   └─ track (<div class="co-om-track">)        // intrinsic-sized scrolling track
///        └─ child                               // user content
/// ```
///
/// `root` carries the outer `<div>` chrome (`co-om` className, no
/// inline style — the scoped `<style>` block written into the first
/// child handles the per-instance overflow / mask / size rules).
/// `track` carries the intrinsic-sized track `<div>` chrome
/// (`co-om-track` className).
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only:
/// * Cat 1 — `WebElementChrome` slots (paint-ready chrome).
///
/// The marquee clipping / fade-mask / track-sizing rules cannot be
/// targeted via inline style (they pin to `#$scopeId` and read
/// `--co-om-fade-*-alpha` CSS variables the client measurer writes each
/// frame), so they live in a scoped `<style>` element. That scoped CSS —
/// and the runtime measurer config it shares values with — are NOT
/// carried on this struct: they are behavioural / composed-CSS data read
/// by the stateful widget body, so the widget resolves them via the
/// dedicated [resolveOverflowMarqueeConfig] entry point and folds in
/// the runtime scope id at build time via [composeOverflowMarqueeCss].
/// This mirrors the number_ticker / hover_card separate-resolver pattern.
class ResolvedOverflowMarquee implements WebResolvedChrome {
  /// Creates a [ResolvedOverflowMarquee].
  const ResolvedOverflowMarquee({required this.root, required this.track});

  /// Paint-ready chrome for the outer `<div>` — `co-om` className,
  /// no inline-style chrome. The scoped `<style>` block written into
  /// the first child handles per-instance clipping / mask / track
  /// rules because they depend on the build-time `scopeId`.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the inner track `<div>` — `co-om-track`
  /// className, no inline-style chrome. The intrinsic sizing
  /// (`width: max-content` / `display: inline-block` /
  /// `white-space: nowrap`) is applied via the per-instance scoped
  /// CSS targeting `#$scopeId > .co-om-track`.
  final WebElementChrome track;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedOverflowMarquee] for `OverflowMarquee` —
/// single chrome entry point. Carries only the static `<div>` chrome;
/// behavioural / scoped-CSS data flows through
/// [resolveOverflowMarqueeConfig].
ResolvedOverflowMarquee resolveOverflowMarquee(BuildContext context) {
  return const ResolvedOverflowMarquee(
    root: WebElementChrome(className: _kOverflowMarqueeRootClassName),
    track: WebElementChrome(className: _kOverflowMarqueeTrackClassName),
  );
}

/// Resolves the behavioural runtime config for `OverflowMarquee` — the
/// measurer ticker inputs (duration / delay / step / curve / pauseOnHover)
/// plus the two values ([direction] / fadePortion) that also shape the
/// scoped `<style>` block. Consumed by the stateful measurer between
/// builds, not by paint-ready chrome.
///
/// Timing / dimensional fields walk the merge chain: design system
/// default → `CoreOverflowMarqueeTheme.style` →
/// `widget.overflowMarqueeStyle`. Semantic / behavioural inputs
/// ([direction] / [curve] / [pauseOnHover]) are widget-only — Theme does
/// not override them. Kept as a separate `resolve*` entry point so
/// [ResolvedOverflowMarquee] stays pure paint-ready chrome
/// (number_ticker separate-resolver pattern).
OverflowMarqueeConfig resolveOverflowMarqueeConfig(
  BuildContext context, {
  CoreAxis? direction,
  CoreMarqueeCurve? curve,
  bool? pauseOnHover,
  CoreOverflowMarqueeStyle? overflowMarqueeStyle,
}) {
  final coreTheme = context.theme.coreComponentTheme?.overflowMarquee;

  final merged = resolveStyleChain(const CoreOverflowMarqueeStyle(), [
    coreTheme?.style,
    overflowMarqueeStyle,
  ]);

  final resolvedDirection = direction ?? .horizontal;
  final duration = merged.duration ?? CoreOverflowMarqueeStyle.defaultDuration;
  final delayDuration =
      merged.delayDuration ?? CoreOverflowMarqueeStyle.defaultDelayDuration;
  final step = merged.step ?? CoreOverflowMarqueeStyle.defaultStep;
  final fadePortion =
      merged.fadePortion ?? CoreOverflowMarqueeStyle.defaultFadePortion;
  final resolvedCurve = curve ?? .linear;
  final resolvedPauseOnHover = pauseOnHover ?? false;

  return (
    direction: resolvedDirection,
    duration: duration,
    delayDuration: delayDuration,
    step: step,
    fadePortion: fadePortion,
    curve: resolvedCurve,
    pauseOnHover: resolvedPauseOnHover,
  );
}

// ═══════════════════════════════════════════════════
// Scoped-CSS composer (Category C)
// ═══════════════════════════════════════════════════

/// Composes the `<style>` block contents for the supplied scope [id]
/// from a [OverflowMarqueeConfig].
///
/// Emits the overflow-independent structure scoped to [id]: a clipping
/// container, the fade mask, and the intrinsic-sized `.co-om-track`.
///
/// All of the marquee's visual state is driven from Dart via
/// `OverflowMarqueeMeasurer` on the client — each frame the measurer
/// writes:
///
///   - `transform: translate(...)` on the track (the position
///     Flutter's `RenderObject.performLayout` computes).
///   - `--co-om-fade-start-alpha` / `--co-om-fade-end-alpha` on the
///     container (directly from Flutter's `1 - fadeStartProgress` /
///     `1 - fadeEndProgress`).
///
/// `width: max-content` (not `max-width`) lets the track expand past
/// the container on the main axis — otherwise `getBoundingClientRect()`
/// would report no overflow to the measurer.
///
/// SSR safety: `var(--co-om-fade-start-alpha, 1)` falls back to a
/// fully-opaque left edge and `var(--co-om-fade-end-alpha, 0)` to a
/// fully-faded right edge, which matches Flutter's `progress == 0`
/// state — the snapshot looks coherent even before the client takes
/// over.
String composeOverflowMarqueeCss(
  OverflowMarqueeConfig config,
  String id,
) {
  final isHorizontal = config.direction == .horizontal;
  final sizeAxis = isHorizontal ? 'width' : 'height';
  final fadeMask = _fadeMask(config.direction, config.fadePortion);

  return '#$id {'
      ' display: block;'
      ' width: 100%;'
      ' overflow: hidden;'
      ' $fadeMask'
      ' }'
      ' #$id > .co-om-track {'
      ' display: inline-block;'
      ' white-space: nowrap;'
      ' $sizeAxis: max-content;'
      ' will-change: transform;'
      ' }';
}

/// Builds the static fade mask. Outer gradient stops read their alpha
/// directly from the CSS variables the measurer writes each frame — no
/// animation, no `@property`, no `@keyframes`. The `var()` fallbacks
/// describe the `progress == 0` state so SSR snapshots render the same
/// way.
String _fadeMask(CoreAxis direction, double fadePortion) {
  if (fadePortion <= 0) return '';
  final axis = direction == .horizontal ? 'right' : 'bottom';
  final whole = fadePortion.toInt();
  final px = whole == fadePortion ? whole : fadePortion;
  const startAlpha = 'rgb(0 0 0 / var(--co-om-fade-start-alpha, 1))';
  const endAlpha = 'rgb(0 0 0 / var(--co-om-fade-end-alpha, 0))';
  final gradient =
      'linear-gradient(to $axis,'
      ' $startAlpha 0,'
      ' black ${px}px,'
      ' black calc(100% - ${px}px),'
      ' $endAlpha 100%)';
  return 'mask-image: $gradient; -webkit-mask-image: $gradient;';
}
