import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

/// Number of dots in the `dots` variant.
const int _kDotsCount = CoreLoadingStyle.dotCount;

/// Marker classNames applied to the variant-specific animating element
/// so the scoped `<style>` block can target it via
/// `#$scopeId .co-loading-<variant>`.
const String _kSpinnerMarker = 'co-loading-spinner';

const String _kDotMarker = 'co-loading-dot';
const String _kBarMarker = 'co-loading-bar';
const String _kHaloMarker = 'co-loading-halo';

/// Decimal places kept when a ratio is written into CSS.
const int _kCssRatioDigits = 4;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Loading`.
///
/// DOM shape (variant-specific — `co_loading` reads only the slots
/// matching the active [CoreLoadingVariant]):
///
/// `spinner`:
///
/// ```text
/// root (<span role="status">)
///   ├─ <style>                              // resolveLoadingCss(ctx, .., id: scopeId)
///   ├─ track (<svg><circle>)                // faded full ring
///   └─ sweep (<svg><circle>)                // rotating partial ring
/// ```
///
/// `dots`:
///
/// ```text
/// root (<span role="status">)
///   ├─ <style>                              // resolveLoadingCss(ctx, .., id: scopeId)
///   ├─ dot0 (<span>)
///   ├─ dot1 (<span>)
///   └─ dot2 (<span>)
/// ```
///
/// `bar`:
///
/// ```text
/// root (<span role="status">)
///   ├─ <style>                              // resolveLoadingCss(ctx, .., id: scopeId)
///   └─ fill (<span>)                        // moving fill, slides left ↔ right
/// ```
///
/// `pulse`:
///
/// ```text
/// root (<span role="status">)
///   ├─ <style>                              // resolveLoadingCss(ctx, .., id: scopeId)
///   ├─ halo (<span>)                        // spreads from the dot to the full size, fading out
///   └─ dot (<span>)                         // centre dot
/// ```
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only:
/// * Cat 1 — `WebElementChrome` slots (paint-ready chrome). All
///   variant-specific slots ([track] / [sweep] / [dot0] / [dot1] /
///   [dot2] / [fill]) are nullable — non-null only for the slots the
///   active variant renders.
///
/// The scoped `<style>` block (variant `@keyframes` + selector rule
/// bound to the runtime scope id) is NOT carried here — its inputs
/// (active variant + merged animation duration) are behavioural
/// identifiers consumed by the per-instance `<style>` injection, not
/// paint chrome. The widget composes them via the top-level
/// [resolveLoadingCss] resolver (number_ticker separate-resolver
/// pattern), which walks the same merge chain and folds in the runtime
/// scope id.
///
/// No scalar metadata (variant / size / colour / duration) is
/// exposed — the active variant stays on the widget prop and threads
/// straight through to the resolver which selects the matching DOM
/// shape.
class ResolvedLoading implements WebResolvedChrome {
  /// Creates a [ResolvedLoading].
  const ResolvedLoading({
    required this.root,
    this.track,
    this.sweep,
    this.dot0,
    this.dot1,
    this.dot2,
    this.fill,
    this.halo,
    this.dot,
  });

  /// Paint-ready chrome for the root `<span role="status">` — variant-
  /// specific layout (`inline-block` / `inline-flex` / `relative`) plus
  /// fixed width / height (logical px → rem) and variant-specific
  /// chrome (track colour / pill border).
  @override
  final WebElementChrome root;

  /// `spinner` static track ring slot — non-null only for the `spinner`
  /// variant.
  final WebElementChrome? track;

  /// `spinner` rotating sweep slot — non-null only for the `spinner`
  /// variant.
  final WebElementChrome? sweep;

  /// `dots` dot 0 (no animation delay) — non-null only for the `dots`
  /// variant.
  final WebElementChrome? dot0;

  /// `dots` dot 1 (`dotPhaseOffsetRatio` of the cycle delayed) —
  /// non-null only for the `dots` variant.
  final WebElementChrome? dot1;

  /// `dots` dot 2 (`2 * dotPhaseOffsetRatio` of the cycle delayed) —
  /// non-null only for the `dots` variant.
  final WebElementChrome? dot2;

  /// `bar` moving fill slot — non-null only for the `bar` variant.
  final WebElementChrome? fill;

  /// `pulse` halo slot — non-null only for the `pulse` variant.
  final WebElementChrome? halo;

  /// `pulse` centre dot slot — non-null only for the `pulse` variant.
  final WebElementChrome? dot;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedLoading] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default (CoreLoadingStyle.defaultX /
///   defaultsByVariant[variant] / defaultsBySize[componentSize])
///   → theme.coreComponentTheme.loading.style
///   → widget.loadingStyle
/// ```
ResolvedLoading resolveLoading(
  BuildContext context, {
  required CoreLoadingVariant variant,
  CoreLoadingTone tone = CoreLoadingTone.defaultTone,
  CoreComponentSize? componentSize,
  CoreLoadingStyle? loadingStyle,
}) {
  final loadingTheme = context.theme.coreComponentTheme?.loading;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreLoadingStyle(), [
    loadingTheme?.style,
    loadingTheme?.variantStyles?[variant],
    loadingStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  // Each value finished its merge + fallback so the local builders
  // below run from a single source of truth.
  final double effectiveSize;
  if (merged.size != null) {
    effectiveSize = merged.size!;
  } else if (componentSize != null) {
    effectiveSize = CoreLoadingStyle.defaultsBySize[componentSize]!.size!;
  } else {
    effectiveSize = CoreLoadingStyle.defaultSize;
  }
  // Preserve the existing token-class serialization (including its opacity
  // rounding). Only raw colours need the emit family's inline CSS path.
  final toneStyle = CoreLoadingStyle.defaultsByTone[tone]!;
  final indicatorColor = merged.color ?? toneStyle.color!;
  final colorToken = indicatorColor.toString();
  final indicatorText = indicatorColor.token == null
      ? emitColor(indicatorColor, toneStyle.color!, .text)
      : null;
  final indicatorFill = indicatorColor.token == null
      ? emitColor(indicatorColor, toneStyle.color!, .background)
      : null;
  // Track colour — **always** emitted inline via `.toValue()`
  // (`var(--color-X)` for token overrides, `color-mix(...)` for the
  // implicit alpha-faded tint). Web EMIT is theme-free — the browser
  // resolves the token via CSS variables, so `scheme.resolve(...)` is a
  // no-op here (web-specifics.md "Web EMIT — scheme.resolve 는 no-op →
  // 금지"). The explicit `merged.trackColor` override wins, else the
  // indicator colour faded by `merged.trackAlpha` (Epic #1603 chaining
  // gate — both `trackColor` and `trackAlpha` reflected here). Single
  // CSS surface mirrors the Flutter `effectiveColor.scaleAlpha(...)` path.
  // The tone's own track — a neutral token, or (inverse) the indicator
  // colour faded — unless a track colour or alpha is stated.
  final toneTrackColor = toneStyle.trackColor;
  final trackColorCss =
      (merged.trackColor ??
              (merged.trackAlpha == null && toneTrackColor != null
                  ? toneTrackColor
                  : indicatorColor.scaleAlpha(
                      merged.trackAlpha ??
                          toneStyle.trackAlpha ??
                          CoreLoadingStyle.defaultTrackAlpha,
                    )))
          .toValue();
  // Stroke width — **always** inline via `strokeWidthCss(...)`
  // (`var(--coui-stroke-width-N)` for token values, fixed `px` for
  // arbitrary overrides). No `border-${...stroke}` Tailwind class so the
  // override path and the default path share one CSS surface (Epic #1603
  // single-signature).
  final strokeWidthValue = strokeWidthCss(
    merged.strokeWidth ??
        (componentSize == null
            ? CoreLoadingStyle.defaultStrokeWidth
            : CoreLoadingStyle.defaultsBySize[componentSize]!.strokeWidth!),
  );
  // Corner radius — **always** inline via `CoreBorderRadius.all(...)
  // .toValue()` (`var(--coui-radius-N)` for token values, `px` for
  // arbitrary overrides). No `rounded-*` Tailwind class so override and
  // default share one surface (Epic #1603 single-signature + chaining —
  // `cornerRadius` reflected here).
  final borderRadius = CoreBorderRadius.all(
    merged.cornerRadius ?? CoreLoadingStyle.defaultCornerRadius,
  ).toValue();
  // A size step states its own dot and track; a stated pixel size with no
  // step keeps the proportions instead (and with neither, the `xs` step's).
  final stepStyle = componentSize != null
      ? CoreLoadingStyle.defaultsBySize[componentSize]!
      : null;
  final sizeStated = merged.size != null;
  final dotSize =
      merged.dotSize ??
      stepStyle?.dotSize ??
      (sizeStated
          ? effectiveSize * CoreLoadingStyle.defaultDotSizeRatio
          : CoreLoadingStyle.defaultDotSize);
  final trackHeight =
      merged.barHeight ??
      stepStyle?.barHeight ??
      (sizeStated
          ? effectiveSize * CoreLoadingStyle.defaultBarHeightRatio
          : CoreLoadingStyle.defaultBarHeight);
  final barLength = effectiveSize * CoreLoadingStyle.defaultBarLengthRatio;
  final dotGap = dotSize * CoreLoadingStyle.dotGapRatio;
  final pulseDotInset = ((1 - CoreLoadingStyle.defaultPulseDotRatio) * 50)
      .toStringAsFixed(_kCssRatioDigits);
  final barFillPercent = (CoreLoadingStyle.defaultBarFillRatio * 100)
      .toStringAsFixed(_kCssRatioDigits);
  const pulseHaloAlpha = CoreLoadingStyle.defaultPulseHaloAlpha;
  // Dot phase-offset stagger — a *ratio* of the resolved duration (the same
  // `CoreLoadingStyle.dotWavePhase` the Flutter twin samples), not a fixed
  // millisecond literal. The `dots` variant is the only one that
  // needs `durationMs` in this (chrome) resolver — the shared duration
  // computation otherwise lives in `resolveLoadingCss`.
  final durationMs =
      (merged.duration ?? CoreLoadingStyle.defaultsByVariant[variant]!.duration)
          .inMilliseconds;

  // ─── Local builders ───────────────────────────────────
  // Closures capture every chrome value above — closure-local builders
  // own DOM-element-specific composition; the resolver body only stitches
  // the WebElementChrome slots together.

  /// Composes the root `<span>` Tailwind className. Only structural /
  /// colour-token classes — the indicator colour stays a token class
  /// (token classes or raw inline colour); radius / track-colour
  /// chrome is emitted inline in [buildRootInlineStyles].
  String buildRootClassName() {
    switch (variant) {
      case .spinner:
        return '';
      case .dots:
        return '${WebLayout.inlineFlex} ${WebLayout.flexRow} '
            '${WebLayout.itemsCenter} ${WebLayout.justifyCenter}';
      case .bar:
        return WebLayout.relativeOverflowHidden;
      case .pulse:
        return '${WebLayout.inlineFlex} ${WebLayout.itemsCenter} '
            '${WebLayout.justifyCenter} ${WebLayout.relative}';
    }
  }

  /// Composes the root `<span>` inline CSS — fixed width / height, the
  /// variant-specific `display` / `position` rules, plus the always-
  /// inline `border-radius` (pulse / bar) and `background-color` track
  /// fill (bar).
  Styles buildRootInlineStyles() {
    final raw = {
      'width':
          '${(variant == .bar ? barLength : effectiveSize) / kRemDivisor}rem',
    };
    switch (variant) {
      case .spinner:
        raw['position'] = WebLayout.relative;
        raw['display'] = WebLayout.inlineBlock;
        raw['height'] = '${effectiveSize / kRemDivisor}rem';
      case .dots:
        raw['height'] = '${effectiveSize / kRemDivisor}rem';
        // Half a dot — derived from the dot, not a spacing step, so it does
        // not move with density (Flutter's `Row.spacing` is the same value).
        raw['gap'] = pinnedLengthCss(dotGap);
      case .bar:
        raw['display'] = WebLayout.inlineBlock;
        raw['height'] = '${trackHeight / kRemDivisor}rem';
        raw['border-radius'] = borderRadius;
        raw['background-color'] = trackColorCss;
      case .pulse:
        raw['height'] = '${effectiveSize / kRemDivisor}rem';
    }
    return Styles(raw: raw);
  }

  /// Composes the spinner static track SVG Tailwind className —
  /// structural classes only; circle radius / stroke width / track colour are
  /// inline (see [buildSpinnerTrackInlineStyles]).
  String buildSpinnerTrackClassName() => WebLayout.absoluteFull;

  /// Composes the static track circle paint. Its radius is inset by
  /// half the stroke width, matching Flutter drawCircle.
  Styles buildSpinnerTrackInlineStyles() => .new(
    raw: {
      'r': 'calc(50% - $strokeWidthValue / 2)',
      'fill': 'none',
      'stroke-width': strokeWidthValue,
      'stroke': trackColorCss,
    },
  );

  /// Composes the spinner rotating sweep SVG Tailwind className —
  /// the indicator's token colour class so `stroke: currentColor` picks it
  /// up. Raw colour, radius and stroke width are inline.
  String buildSpinnerSweepClassName() =>
      '${WebLayout.absolute} ${WebLayout.insetZero} $_kSpinnerMarker '
      '${indicatorText?.className ?? 'text-$colorToken'}';

  /// Composes the sweep circle paint. SVG pathLength normalizes a
  /// revolution to 360. The Core sweep starts at noon with round caps,
  /// matching the Flutter painter.
  Styles buildSpinnerSweepInlineStyles() => .new(
    raw: {
      ...?indicatorText?.inline,
      'r': 'calc(50% - $strokeWidthValue / 2)',
      'fill': 'none',
      'stroke-width': strokeWidthValue,
      'stroke': 'currentColor',
      'stroke-linecap': 'round',
      'stroke-dasharray': '${CoreLoadingStyle.defaultArcSweepDegrees} 360',
      'transform': 'rotate(-90deg)',
      'transform-origin': 'center',
    },
  );

  /// Composes the dot `<span>` Tailwind className (shared by all three
  /// dots — the per-dot inline CSS differs by `animation-delay`). The
  /// token colour stays a class; raw colour and radius are inline.
  String buildDotClassName() =>
      '${indicatorFill?.className ?? 'bg-$colorToken'} $_kDotMarker';

  /// How far into its own cycle dot [index] starts, in milliseconds.
  int dotStartMs(int index) =>
      (CoreLoadingStyle.dotWavePhase(index, 0) * durationMs).round();

  /// Composes a single dot's inline CSS — diameter + always-inline
  /// `border-radius` + staggered delay.
  ///
  /// The delay is negative — `-dotWavePhase(index, 0) * durationMs` — so each
  /// dot starts mid-cycle at the phase the Flutter twin samples at `t = 0`
  /// (`CoreLoadingStyle.dotWavePhase`). A positive delay would hold the
  /// later dots at their resting opacity until it elapsed instead of
  /// showing the wave from the first frame.
  Styles buildDotInlineStyles(int index) => .new(
    raw: {
      ...?indicatorFill?.inline,
      'width': '${dotSize / kRemDivisor}rem',
      'height': '${dotSize / kRemDivisor}rem',
      'border-radius': borderRadius,
      'animation-delay': '${-dotStartMs(index)}ms',
    },
  );

  /// Composes the bar moving fill `<span>` Tailwind className. The
  /// token colour stays a class; raw colour and radius are inline.
  String buildBarFillClassName() =>
      '${WebLayout.absolute} ${WebLayout.topZero} ${WebLayout.leftZero} '
      '${WebLayout.hFull} '
      '${indicatorFill?.className ?? 'bg-$colorToken'} $_kBarMarker';

  /// Composes the bar moving fill `<span>` inline CSS — fill width +
  /// always-inline `border-radius`.
  Styles buildBarFillInlineStyles() => .new(
    raw: {
      ...?indicatorFill?.inline,
      'width': '$barFillPercent%',
      'border-radius': borderRadius,
    },
  );

  /// Composes the pulse halo `<span>` Tailwind className — the indicator
  /// token colour as a class; raw colour, radius, size and the starting
  /// opacity are inline.
  String buildHaloClassName() =>
      '${WebLayout.absoluteFull} '
      '${indicatorFill?.className ?? 'bg-$colorToken'} $_kHaloMarker';

  /// Composes the pulse halo inline CSS — always-inline `border-radius` and
  /// the opacity the beat starts from (the keyframes fade it out).
  Styles buildHaloInlineStyles() => .new(
    raw: {
      ...?indicatorFill?.inline,
      'border-radius': borderRadius,
      'opacity': '$pulseHaloAlpha',
    },
  );

  /// Composes the pulse centre dot Tailwind className.
  String buildPulseDotClassName() =>
      '${WebLayout.absoluteFull} '
      '${indicatorFill?.className ?? 'bg-$colorToken'}';

  /// Composes the pulse centre dot inline CSS.
  Styles buildPulseDotInlineStyles() => .new(
    raw: {
      ...?indicatorFill?.inline,
      // Clip a full-size box so fractional dot edges stay centered during
      // rasterization. A small background box snaps to whole pixels.
      'clip-path': 'inset($pulseDotInset% round $borderRadius)',
    },
  );

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedLoading(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    track: variant == .spinner
        ? WebElementChrome(
            className: buildSpinnerTrackClassName(),
            inlineStyles: buildSpinnerTrackInlineStyles(),
          )
        : null,
    sweep: variant == .spinner
        ? WebElementChrome(
            className: buildSpinnerSweepClassName(),
            inlineStyles: buildSpinnerSweepInlineStyles(),
          )
        : null,
    dot0: variant == .dots
        ? WebElementChrome(
            className: buildDotClassName(),
            inlineStyles: buildDotInlineStyles(0),
          )
        : null,
    dot1: variant == .dots
        ? WebElementChrome(
            className: buildDotClassName(),
            inlineStyles: buildDotInlineStyles(1),
          )
        : null,
    dot2: variant == .dots
        ? WebElementChrome(
            className: buildDotClassName(),
            inlineStyles: buildDotInlineStyles(2),
          )
        : null,
    fill: variant == .bar
        ? WebElementChrome(
            className: buildBarFillClassName(),
            inlineStyles: buildBarFillInlineStyles(),
          )
        : null,
    halo: variant == .pulse
        ? WebElementChrome(
            className: buildHaloClassName(),
            inlineStyles: buildHaloInlineStyles(),
          )
        : null,
    dot: variant == .pulse
        ? WebElementChrome(
            className: buildPulseDotClassName(),
            inlineStyles: buildPulseDotInlineStyles(),
          )
        : null,
  );
}

// ═══════════════════════════════════════════════════
// Scoped-CSS resolver (Category C)
// ═══════════════════════════════════════════════════

/// Resolves the per-instance scoped `<style>` block contents for
/// `Loading` — the variant `@keyframes` plus the selector rule binding
/// the animation to the per-instance marker class
/// (`co-loading-spinner` / `co-loading-dot` / `co-loading-bar`) or the
/// root element itself (`pulse`).
///
/// Kept as a separate `resolve*` entry point so [ResolvedLoading]
/// stays pure paint-ready chrome (number_ticker separate-resolver
/// pattern). Its inputs ([variant] + merged animation duration) are
/// behavioural identifiers consumed by the `<style>` injection between
/// builds, not paint chrome.
///
/// Walks the same merge chain as [resolveLoading]
/// (design-system default per [CoreLoadingVariant] →
/// `theme.coreComponentTheme.loading.style` → `widget.loadingStyle`),
/// folding the runtime scope [id] into the emitted selectors. The
/// duration computation is identical to the chrome resolver's
/// (`(merged.duration ?? defaultsByVariant[variant].duration)
/// .inMilliseconds`).
String resolveLoadingCss(
  BuildContext context, {
  required CoreLoadingVariant variant,
  required String id,
  CoreLoadingStyle? loadingStyle,
}) {
  final loadingTheme = context.theme.coreComponentTheme?.loading;
  final merged = resolveStyleChain(const CoreLoadingStyle(), [
    loadingTheme?.style,
    loadingTheme?.variantStyles?[variant],
    loadingStyle,
  ]);
  final variantStyle = CoreLoadingStyle.defaultsByVariant[variant]!;
  final duration = (merged.duration ?? variantStyle.duration).inMilliseconds;
  // Token-routed duration + easing (`durationMsCss` / `toVarCss` — see
  // their docs) rather than raw `${ms}ms`/`linear`/`ease-in-out` literals.
  final durationCss = durationMsCss(duration);
  final linearCss = 'var(--easing-${CoreEasing.scale.linear})';
  final standardCss = CoreEasing.move.toVarCss();
  switch (variant) {
    case .spinner:
      return '@keyframes $id-spinner { '
          'from { transform: rotate(0deg); } '
          'to { transform: rotate(360deg); } } '
          '#$id .$_kSpinnerMarker { animation: $id-spinner '
          '$durationCss $linearCss infinite; }';
    case .dots:
      // One linear keyframe per dot — `CoreLoadingStyle.dotOpacityAt`
      // sampled at `k / dotCount`, the same piecewise-linear wave Flutter
      // paints every frame.
      final dotKeyframes = StringBuffer();
      for (var k = 0; k <= CoreLoadingStyle.dotCount; k++) {
        final percent = (k / CoreLoadingStyle.dotCount * 100).toStringAsFixed(
          _kCssRatioDigits,
        );
        dotKeyframes.write(
          '$percent% { opacity: '
          '${CoreLoadingStyle.dotWaveKeyframeOpacity(k)}; } ',
        );
      }
      return '@keyframes $id-dot { $dotKeyframes} '
          '#$id .$_kDotMarker { animation: $id-dot '
          '$durationCss $linearCss infinite; }';
    case .bar:
      // The fill slides the track length minus its own width: as a share of
      // its own width, `(1 − ratio) / ratio`.
      const fillRatio = CoreLoadingStyle.defaultBarFillRatio;
      final translateEnd = ((1 - fillRatio) / fillRatio * 100).toStringAsFixed(
        _kCssRatioDigits,
      );
      // Ease once across the whole cycle, then apply Flutter's sine.
      // Escaping the syntax's angle brackets preserves the registration
      // through SSR as well as client-side style insertion.
      return '@property --co-loading-bar-phase { '
          r'syntax: "\3c number\3e"; inherits: false; initial-value: 0; } '
          '@keyframes $id-bar { from { --co-loading-bar-phase: 0; } '
          'to { --co-loading-bar-phase: 1; } } '
          '#$id .$_kBarMarker { '
          'will-change: transform; '
          'transform: translateX(calc($translateEnd% * '
          'sin(var(--co-loading-bar-phase) * pi))); '
          'animation: $id-bar '
          '$durationCss $standardCss infinite; }';
    case .pulse:
      // The halo spreads from the centre dot to the full size while it fades
      // out; the centre dot stays.
      final startScale = CoreLoadingStyle.defaultPulseDotRatio.toStringAsFixed(
        _kCssRatioDigits,
      );
      return '@keyframes $id-pulse { '
          '0% { transform: scale($startScale); '
          'opacity: ${CoreLoadingStyle.defaultPulseHaloAlpha}; } '
          '100% { transform: scale(1); opacity: 0; } } '
          '#$id .$_kHaloMarker { animation: $id-pulse '
          '$durationCss $standardCss infinite; }';
  }
}

/// Public constant for the fixed dot count of the `dots` variant —
/// callers iterating [ResolvedLoading.dot0] / [ResolvedLoading.dot1] /
/// [ResolvedLoading.dot2]
/// reference this so the bound is not duplicated.
const int kLoadingDotsCount = _kDotsCount;
