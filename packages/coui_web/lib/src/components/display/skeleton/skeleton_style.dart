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

/// Paint-ready chrome for Web `Skeleton`.
///
/// DOM shape varies by variant — `co_skeleton` decides which optional
/// branches render based on the variant prop:
///
/// ```text
/// // rectangular / circular variant:
/// root (<div>)                            // animate-pulse + bg className,
///                                         // width / height / radius /
///                                         // animation inline CSS
///
/// // text variant:
/// root (<div>)                            // flex-column container,
///                                         // inter-line gap inline CSS
///   ├─ textLines[0] (<div>)               // animate-pulse + bg + line-height,
///   ├─ textLines[1] (<div>)               // per-line width baked into
///   └─ textLines[N-1] (<div>) (last)      //   inlineStyles by the resolver
///
/// // either variant, outside a `LoadingRegion`:
///   └─ announcer (<span>) (last)          // sr-only — the status text
/// ```
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only:
/// * Cat 1 — `WebElementChrome` slots (paint-ready chrome).
/// * Cat 2 — nested `CoreXxxStyle` slots (skeleton has none).
///
/// No scalar metadata (variant / lines count / last-line-width fraction)
/// is exposed — semantic identifiers stay on the widget prop, the
/// per-line count is baked into the [textLines] list length, and the
/// last-line width is baked into the final entry's inline-CSS `width`.
class ResolvedSkeleton implements WebResolvedChrome {
  /// Creates a [ResolvedSkeleton].
  const ResolvedSkeleton({
    required this.root,
    required this.textLines,
    required this.announcer,
  });

  /// Paint-ready chrome for the outermost `<div>`.
  ///
  /// - **Rectangular / circular**: full skeleton block chrome — width,
  ///   height, background, border-radius, animation duration / pulse
  ///   opacities baked into `inlineStyles`. `co_skeleton` renders this
  ///   as the leaf element.
  /// - **Text**: flex-column container chrome — `display: flex` +
  ///   `gap` inline CSS. `co_skeleton` renders [textLines] children
  ///   inside.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome per text-skeleton line — each entry has its
  /// per-line `width` baked into `inlineStyles` (the last entry is
  /// typically narrower). Empty list for non-text variants.
  ///
  /// The resolver determines the line count by reading the resolved
  /// `lines` value once; `co_skeleton` simply renders one `<div>` per
  /// chrome entry without re-touching `CoreSkeletonStyle`.
  final List<WebElementChrome> textLines;

  /// Chrome for the visually hidden element that holds the status text.
  ///
  /// The root is a `role="status"` live region, and a live region announces
  /// its content, not its `aria-label` — a status with a name and no text
  /// has nothing to say. The widget renders this only when no enclosing
  /// `LoadingRegion` announces for the skeleton.
  final WebElementChrome announcer;
}

// The status text is for assistive technology only. Out of flow and out of the
// page's scrollable overflow (`srOnlyFixed`): a plain `sr-only` span in each
// skeleton of a horizontal scroller would widen the page itself.
const _kAnnouncer = WebElementChrome(className: WebLayout.srOnlyFixed);

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedSkeleton] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default (per variant)
///   → theme.coreComponentTheme.skeleton.style
///   → widget.skeletonStyle
/// ```
///
/// Single entry point — `co_skeleton.dart` must not call
/// `context.theme.coreComponentTheme.skeleton` directly nor invoke
/// `CoreSkeletonStyle.merge(...)` outside this function.
ResolvedSkeleton resolveSkeleton(
  BuildContext context, {
  required CoreSkeletonVariant variant,
  String? width,
  String? height,
  CoreSkeletonStyle? skeletonStyle,
}) {
  final skeletonTheme = context.theme.coreComponentTheme?.skeleton;

  // ─── Merge chain ──────────────────────────────────────
  // theme.style → theme.variantStyles[variant] → widget.skeletonStyle.
  // Semantic `variant` is widget-only; the theme cannot override it.
  // Flutter wires the same chain so the two platforms stay 1:1.
  final merged = resolveStyleChain(const CoreSkeletonStyle(), [
    skeletonTheme?.style,
    skeletonTheme?.variantStyles?[variant],
    skeletonStyle,
  ]);

  // ─── Token tables ─────────────────────────────────────
  final variantStyle = CoreSkeletonStyle.defaultsByVariant[variant]!;

  // ─── EMIT Stage 2 (Web, theme-free) ───────────────────
  // Background routes through the emit family — a single
  // class-XOR-inline decision. Token-bound values (the variant default
  // AND token overrides) emit a Tailwind `bg-{token}` class so they
  // stay dark-mode reactive; raw overrides go inline. No `scheme.resolve`
  // (a no-op on Web) and no hand-rolled `if (override != null)` branch.
  final backgroundEmit = emitColor(
    merged.backgroundColor,
    variantStyle.backgroundColor,
    .background,
  );
  final bgClassFragment = backgroundEmit.className;

  // Border radius — widget override wins, else the per-variant token.
  // Emitted as CSS shorthand so per-instance values and design-system
  // defaults flow through the same channel.
  final borderRadius = (merged.borderRadius ?? variantStyle.borderRadius)
      .toValue();

  // Pulse animation chrome. `duration` is one full pulse — the keyframe
  // cycle `0%,100%` → `50%` — and `curve` eases each half of it: CSS
  // applies the timing function per keyframe interval, which is what the
  // Flutter controller does with its two forward-eased halves.
  final durationMs =
      (merged.duration ?? CoreSkeletonStyle.defaultDuration).inMilliseconds;
  final timingFunction = (merged.curve ?? CoreSkeletonStyle.defaultCurve)
      .toVarCss();
  // Through a variable, so the reduced-motion media query can swap the pulse
  // for the held resting end — an inline value outranks every stylesheet
  // rule, a variable it reads does not.
  const animationName =
      'var($kSkeletonPulseNameVar, $kSkeletonPulseAnimationName)';
  final fromOpacity =
      merged.fromOpacity ?? CoreSkeletonStyle.defaultFromOpacity;
  final toOpacity = merged.toOpacity ?? CoreSkeletonStyle.defaultToOpacity;

  // The two ends of the pulse, as fully composed colours.
  //
  // Flutter pulses the FILL: it composes these same two ends and tweens the
  // fill's alpha between them inside an `AnimatedBuilder`, so the surface
  // fades and nothing else does. Web pulsed the element instead — the global
  // keyframes animated `opacity` — which fades the node and every descendant
  // together. For a bare block the two are the same picture, which is why it
  // sat here; they stop being the same the moment a skeleton carries a border
  // or anything inside it, and they composite differently against whatever is
  // behind them either way.
  //
  // Composed here rather than in the keyframes because the keyframes are
  // global (one rule, every instance) and a colour needs its token. A custom
  // property inside `@keyframes` resolves against the animated element's own
  // computed style, so per-node variables carry the per-instance values into
  // the one shared rule — the same mechanism the two opacity numbers used,
  // now carrying colours so the token stays inside and dark mode keeps
  // tracking.
  final pulseBase = merged.backgroundColor ?? variantStyle.backgroundColor;
  final pulseFrom = pulseBase.scaleAlpha(fromOpacity).toValue();
  final pulseTo = pulseBase.scaleAlpha(toOpacity).toValue();

  // Text-variant chrome.
  // Native-spacing `lineSpacing` consumed by the flex-column
  // container's inline `gap` CSS — Epic #1659 D-cat — N-sibling
  // uniform distribution pattern. No nested `CoreGapStyle` slot.
  final lineSpacingPx =
      merged.lineSpacing ?? CoreSkeletonStyle.defaultLineSpacing;
  final lastLineWidthFrac =
      merged.lastLineWidth ?? CoreSkeletonStyle.defaultLastLineWidth;
  final lines = merged.lines ?? CoreSkeletonStyle.defaultLines;
  final lastLineWidthPercent = (lastLineWidthFrac * kPercentScale).toInt();
  // Per-line height from the single Core source — emitted inline (rem)
  // because `CoreSize.scale` keys do not resolve on Tailwind `h-`.
  final lineHeightPx = merged.lineHeight ?? CoreSkeletonStyle.defaultLineHeight;

  // ─── Local builders ───────────────────────────────────

  /// Composes the rectangular / circular block `<div>` Tailwind
  /// className — `animate-pulse` plus the variant background fragment
  /// (suppressed when an inline override is supplied so the inline rule
  /// wins cleanly).
  String buildBlockClassName() => [
    'animate-pulse',
    bgClassFragment,
    // A skeleton draws no border of its own, so a style's stroke floor
    // has nothing to lift here. The marker takes the boundary a boxed
    // style contributes and is inert under every style that contributes
    // none — see `kControlBorderMarker`.
    kControlBorderMarker,
  ].where((c) => c.isNotEmpty).join(' ');

  /// Composes the rectangular / circular block `<div>` inline CSS —
  /// width / height (forwarded from the widget), optional background
  /// colour override, border-radius, animation duration, pulse opacity
  /// CSS variables.
  Styles buildBlockInlineStyles() {
    final raw = {
      'width': ?width,
      // Clamp a fixed width to the parent the way Flutter's `Container`
      // does — its box is bounded by the parent constraints, so it
      // shrinks to fit rather than overflowing (the Web CSS default).
      // This is the per-component clamp choice, mirroring Flutter's
      // widget type (bounded box here; scrollable components emit their
      // own overflow instead). Only bites when `width` is set.
      if (width != null) 'max-width': '100%',
      'height': ?height,
      // Emit-family inline fragment (raw colour override only — a token
      // value stays on the `bg-{token}` class and contributes nothing).
      ...?backgroundEmit.inline,
      'border-radius': borderRadius,
      // Overrides the `animation-name` / `-duration` / `-timing-function`
      // longhands of Tailwind's `animate-pulse` shorthand (kept in the
      // className below for its `animation-iteration-count`) so the pulse
      // reads the `--pulse-from` / `--pulse-to` colours below instead of
      // Tailwind's built-in fixed 1 → 0.5 → 1 opacity keyframe, at the Core
      // period and curve instead of Tailwind's 2s
      // `cubic-bezier(0.4, 0, 0.6, 1)`.
      'animation-name': animationName,
      'animation-duration': '${durationMs}ms',
      'animation-timing-function': timingFunction,
      '--pulse-from': pulseFrom,
      '--pulse-to': pulseTo,
    };
    return Styles(raw: raw);
  }

  /// Composes the text-variant container `<div>` Tailwind className —
  /// flex-column layout.
  String buildTextContainerClassName() =>
      '${WebLayout.flex} ${WebLayout.flexCol} ${WebLayout.wFull}';

  /// Composes the text-variant container `<div>` inline CSS — inter-line
  /// `gap` only (through `spaceCss` from the logical-px override).
  Styles buildTextContainerInlineStyles() => .new(
    raw: {'gap': spaceCss(lineSpacingPx)},
  );

  /// Composes a single text-line `<div>` Tailwind className —
  /// `animate-pulse` + variant bg fragment. The line height is emitted
  /// inline (from the single Core [CoreSkeletonStyle.lineHeight] source)
  /// rather than an `h-` class, because `CoreSize.scale` keys do not
  /// resolve on Tailwind `h-`/`w-` utilities (an `h-size16` class was
  /// never generated, so the lines collapsed to zero height and the
  /// text skeleton rendered invisible).
  String buildTextLineClassName() => [
    'animate-pulse',
    bgClassFragment,
    kControlBorderMarker,
  ].where((c) => c.isNotEmpty).join(' ');

  /// Composes a single text-line `<div>` inline CSS — per-line `width`
  /// (full-width for non-last lines, `lastLineWidthPercent` for the
  /// final entry) plus the shared per-line chrome (optional
  /// background-colour override, border-radius, animation duration,
  /// pulse colour CSS variables).
  Styles buildTextLineInlineStyles({required bool isLast}) {
    final raw = {
      'width': isLast ? '$lastLineWidthPercent%' : '100%',
      'height': '${lineHeightPx / kRemDivisor}rem',
      // Emit-family inline fragment (raw colour override only — a token
      // value stays on the `bg-{token}` class and contributes nothing).
      ...?backgroundEmit.inline,
      'border-radius': borderRadius,
      // See buildBlockInlineStyles — same override for the same reason.
      'animation-name': animationName,
      'animation-duration': '${durationMs}ms',
      'animation-timing-function': timingFunction,
      '--pulse-from': pulseFrom,
      '--pulse-to': pulseTo,
    };
    return Styles(raw: raw);
  }

  // ─── Compose paint-ready chrome ───────────────────────
  final isText = variant == .text;
  if (!isText) {
    return ResolvedSkeleton(
      root: WebElementChrome(
        className: buildBlockClassName(),
        inlineStyles: buildBlockInlineStyles(),
      ),
      textLines: const [],
      announcer: _kAnnouncer,
    );
  }

  final textLineClassName = buildTextLineClassName();
  final textLines = List.generate(
    lines,
    (index) => WebElementChrome(
      className: textLineClassName,
      inlineStyles: buildTextLineInlineStyles(isLast: index == lines - 1),
    ),
  );
  return ResolvedSkeleton(
    root: WebElementChrome(
      className: buildTextContainerClassName(),
      inlineStyles: buildTextContainerInlineStyles(),
    ),
    textLines: textLines,
    announcer: _kAnnouncer,
  );
}
