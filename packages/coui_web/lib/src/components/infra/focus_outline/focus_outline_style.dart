import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

// ═══════════════════════════════════════════════════
// ResolvedFocusOutline (Web)
// ═══════════════════════════════════════════════════

/// Resolver output for `FocusOutline` on Web.
///
/// DOM shape:
///
/// ```text
/// root (<div>)              // transparent passthrough wrapper hosting the outline ring
/// ```
///
/// The wrapper has no layout classes — the child decides the wrapper's
/// size (a `w-full` input stretches it to the parent's full width, a
/// fixed-size radio circle keeps it tight). Same as Flutter's
/// `Stack(fit: passthrough)`.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only:
/// * Cat 1 — [WebElementChrome] slots (paint-ready chrome).
///
/// The ring's dimensional / colour / timing values (`align`,
/// `borderWidth`, `duration`, `borderColor`, `borderRadius`) are NOT
/// exposed as scalars — they are folded once into [root]'s className
/// (`outline`) and its inline `outline-*` / `box-shadow`
/// (band only) / `transition` / `border-radius` at resolve time so the
/// widget body reads only `resolved.root.className / inlineStyles`.
class ResolvedFocusOutline implements WebResolvedChrome {
  /// Creates a [ResolvedFocusOutline].
  const ResolvedFocusOutline({required this.root});

  /// Paint-ready chrome for the focus-outline wrapper `<div>` — className
  /// `outline` in both states (the ring's colour, not its style, carries
  /// the focus; the wrapper has no layout of its own), plus the inline ring (`outline-color` / `-width` /
  /// `-offset`), the gap band's `box-shadow` when it paints,
  /// `transition` and optional `border-radius`.
  @override
  final WebElementChrome root;
}

/// Resolves [ResolvedFocusOutline] for the given [context].
///
/// Single entry point for the focus outline Style slot — applies the
/// merge chain (`CoreFocusOutlineTheme.style` → `focusOutlineStyle`).
/// The closure-local builder composes the wrapper chrome once at the
/// resolver entry point and stores the result on `resolved.root`.
///
/// The `focused` flag and `shape` enum are runtime semantics — the
/// resolver folds them into the ring's className / inline colour and the
/// `border-radius` composition.
ResolvedFocusOutline resolveFocusOutline(
  BuildContext context, {
  required bool focused,
  required CoreFocusOutlineShape shape,
  CoreFocusOutlineStyle? focusOutlineStyle,
}) {
  final csTheme = context.theme.coreComponentTheme?.focusOutline;

  // Merge chain: theme.style → focusOutlineStyle.
  final merged = resolveStyleChain(const CoreFocusOutlineStyle(), [
    csTheme?.style,
    focusOutlineStyle,
  ]);

  final align = merged.align ?? CoreFocusOutlineStyle.defaultAlign;
  final borderWidth =
      merged.borderWidth ?? CoreFocusOutlineStyle.defaultBorderWidth;
  final duration =
      (merged.duration ?? CoreFocusOutlineStyle.defaultDuration).inMilliseconds;
  // Token-routed duration + easing (`durationMsCss` / `toVarCss` docs).
  final durationCss = durationMsCss(duration);
  final easingCss = CoreEasing.move.toVarCss();
  // Ring + offset (gap) colours. The merge chain fills these from the
  // design-system defaults (`CoreFocusOutlineStyle.defaultBorderColor` /
  // `defaultOffsetColor` → the focus-ring token / transparent), so emit
  // the (possibly-token) colour as a token-safe bare `R G B` triplet: a
  // tagged
  // token keeps the reactive `var(--coui-<token>)` CSS variable
  // (dark-mode parity), a raw override emits its channels. Never calls
  // `.toHex()` on an unresolved token, so it cannot throw (#2123).
  // `ringOpacity` is a multiplier applied on top of whichever
  // `borderColor` is in effect (default or per-instance override) — the
  // single place this happens, so it is applied exactly once regardless
  // of colour source (mirrors the Flutter resolver — #2128 platform
  // parity; see `CoreFocusOutlineStyle.defaultRingOpacity`).
  final ringOpacity =
      merged.ringOpacity ?? CoreFocusOutlineStyle.defaultRingOpacity;
  final ringColor =
      (merged.borderColor ?? CoreFocusOutlineStyle.defaultBorderColor)
          .scaleAlpha(ringOpacity);
  final ringOffsetColor =
      merged.offsetColor ?? CoreFocusOutlineStyle.defaultOffsetColor;
  final borderColor = _ringTriplet(ringColor);
  final offsetColor = _ringTriplet(ringOffsetColor);
  // The scaled-in `ringOpacity` (via `scaleAlpha` above) flows through to
  // the active ring colour. The faded state always uses ` / 0`
  // regardless — only the active alpha varies.
  final borderAlpha = _ringAlpha(ringColor);
  final offsetAlpha = _ringAlpha(ringOffsetColor);
  // The band paints only where the caller states one (a background that
  // is not known) — the default is transparent and emits no layer at all.
  final bandPaints = focusBandPaints(ringOffsetColor);
  final borderRadius = merged.borderRadius;
  // Circle ring radius — override wins, else the design-system default
  // all-9999 token (Epic #1603 chaining gate — promoted override field
  // `circleBorderRadius` reflected via `(merged ?? default)`).
  final circleBorderRadius =
      (merged.circleBorderRadius ??
              CoreFocusOutlineStyle.defaultCircleBorderRadius)
          .toValue();

  // ─── Local builders ───────────────────────────────────

  /// Composes the focus-outline wrapper `<div>` chrome — the ring as an
  /// `outline` on the wrapper, the optional gap band as a `box-shadow`
  /// layer, the fade transition, and optional `border-radius`.
  ///
  /// An outline, not a `box-shadow` ring, so the gap between the child
  /// and the ring is a real gap: an outline offset is never painted,
  /// and a transparent band shows whatever is behind the child. The
  /// outline follows `border-radius` (outer corner = radius + offset)
  /// on every current engine. The declarations come from the kit's one
  /// ring emitter ([focusRingDeclarations]), which every scoped ring
  /// shares.
  ///
  /// The outline is on in both states (the `outline` class) and only its
  /// colour moves — the ring colour at full alpha when [focused], the
  /// same triplet at ` / 0` otherwise — so the ring fades in and out by
  /// interpolating the alpha channel alone, the same way the Flutter
  /// twin fades its `AnimatedOpacity`. Dropping the class on blur would
  /// drop `outline-style` to `none` in that frame, and the outline would
  /// stop painting before the colour transition had anything to show.
  ///
  /// The outline is switched on by a class rather than inline because
  /// the wrapper is never the focused element itself: under forced
  /// colours the root rule
  /// `.coui-root :not(:focus-visible){outline-style:none;}` (0,2,0)
  /// outranks the one-class `outline` (0,1,0) but not an inline
  /// declaration, so a class lets the platform draw its one ring on the
  /// focused element instead of a second one here.
  ///
  /// The band, when it paints, follows the same "same layer, alpha only"
  /// rule as the ring: both states emit one layer of the same spread,
  /// so the browser interpolates colour channels rather than padding a
  /// missing layer with `transparent` (`rgba(0,0,0,0)`) and fading in
  /// from black.
  WebElementChrome buildRootChrome() {
    // `borderColor` / `offsetColor` are bare `R G B` triplets (token →
    // `var(--coui-<token>)` reactive variable, raw override → channels),
    // which `rgb(R G B / A)` modern syntax accepts directly.
    final activeColor = 'rgb($borderColor / $borderAlpha)';
    final fadedColor = 'rgb($borderColor / 0)';
    final activeGapColor = 'rgb($offsetColor / $offsetAlpha)';
    final fadedGapColor = 'rgb($offsetColor / 0)';

    final radius = switch (shape) {
      // Circle = full pill: any radius ≥ half the longest edge produces
      // a circle. `CoreBorderRadius.toValue()` emits `var(--coui-radius-9999)`
      // for the all-9999 token so designer overrides flow through.
      .circle => circleBorderRadius,
      .rectangle => borderRadius?.toValue(),
    };

    final transition = bandPaints
        ? 'outline-color $durationCss $easingCss, '
              'box-shadow $durationCss $easingCss'
        : 'outline-color $durationCss $easingCss';

    return WebElementChrome(
      className: 'outline',
      inlineStyles: Styles(
        raw: {
          // `borderWidth` is a stroke-axis value — the emitter routes it
          // through `--coui-stroke-width-N` so a surface style's stroke
          // floor reaches it, and keeps the ring's outer edge at `align`.
          ...focusRingDeclarations(
            ringColor: focused ? activeColor : fadedColor,
            ringWidth: borderWidth,
            ringOffset: align - borderWidth,
            bandColor: bandPaints
                ? (focused ? activeGapColor : fadedGapColor)
                : null,
          ),
          'transition': transition,
          'border-radius': ?radius,
        },
      ),
    );
  }

  return ResolvedFocusOutline(root: buildRootChrome());
}

/// Scoped CSS text for `<style>` block in `FocusOutline` — the ring a
/// `FocusOutline` slot describes, drawn by a host on one of its own
/// elements instead of on the wrapper `<div>`.
///
/// For a host whose ring has to land on an element the wrapper cannot
/// stand around (`Toggle` paints it on the track, one level inside the
/// focusable `Clickable` root). The slot settles through the same chain
/// [resolveFocusOutline] walks — `CoreFocusOutlineTheme.style` →
/// `focusOutlineStyle` → the design-system defaults — and the CSS comes
/// from the kit's one scoped-ring emitter, `focusRingScopedRule`, so the
/// host neither re-derives the ring nor reads another resolver's
/// paint-ready map.
class ResolvedFocusOutlineRules {
  /// Creates a [ResolvedFocusOutlineRules].
  const ResolvedFocusOutlineRules({required this.css});

  /// Raw CSS rule text — the resting / outline-on / focused rules.
  final String css;
}

/// Resolves [ResolvedFocusOutlineRules] for the given [context].
///
/// [scopeSelector] is the host's base selector, [pseudo] gates when the
/// ring paints, [target] is the descendant the ring hugs (appended after
/// the pseudo-class), and [restShadow] is a `box-shadow` the host shows
/// at rest, composed after a painted band so the band does not erase it.
ResolvedFocusOutlineRules resolveFocusOutlineRules(
  BuildContext context, {
  required String scopeSelector,
  required WebPseudo pseudo,
  String target = '',
  String restShadow = '',
  CoreFocusOutlineStyle? focusOutlineStyle,
}) {
  final csTheme = context.theme.coreComponentTheme?.focusOutline;
  final merged = resolveStyleChain(const CoreFocusOutlineStyle(), [
    csTheme?.style,
    focusOutlineStyle,
  ]);
  final align = merged.align ?? CoreFocusOutlineStyle.defaultAlign;
  final borderWidth =
      merged.borderWidth ?? CoreFocusOutlineStyle.defaultBorderWidth;
  final css = focusRingScopedRule(
    scopeSelector: scopeSelector,
    pseudo: pseudo,
    ringColor: merged.borderColor ?? CoreFocusOutlineStyle.defaultBorderColor,
    offsetColor: merged.offsetColor ?? CoreFocusOutlineStyle.defaultOffsetColor,
    ringWidth: borderWidth,
    ringOffset: align - borderWidth,
    ringOpacity: merged.ringOpacity ?? CoreFocusOutlineStyle.defaultRingOpacity,
    target: target,
    restShadow: restShadow,
  );
  return ResolvedFocusOutlineRules(css: css);
}

/// Emits a bare `R G B` triplet for the focus ring's colours from a
/// possibly-token [color], token-safely and theme-free.
///
/// Web EMIT is theme-free — the token name alone is emitted and the
/// browser resolves `var(--coui-<token>)` at runtime (no
/// `scheme.resolve`, which is a no-op on Web). A tagged token emits the
/// reactive `var(--coui-<token>)` CSS variable so daisyUI / dark-mode
/// switching keeps working; a raw colour emits its `R G B` channels. The
/// triplet form lets the faded ring colour append ` / 0`. Never calls
/// `.toHex()` on an unresolved token, so it cannot throw.
String _ringTriplet(CoreColor color) {
  final tok = color.token;
  if (tok != null) return 'var(--coui-${tok.name})';
  return '${color.red} ${color.green} ${color.blue}';
}

/// Effective alpha for the active ring (or band) colour.
///
/// A raw (token-less) colour carries its transparency in the ARGB `A`
/// channel — `CoreColor.transparent` (`0x00000000`) must stay invisible
/// when focused rather than collapse to opaque black (`rgb(0 0 0 / 1)`,
/// the alpha channel [_ringTriplet] necessarily drops). Tokens are bare
/// opaque triplets, so only the raw path multiplies the channel in; the
/// token-baked [CoreColor.opacity] multiplier applies to both.
double _ringAlpha(CoreColor color) {
  const channelMax = 0xFF;
  const alphaShift = 24;
  final channelAlpha = color.token == null
      ? ((color.argb >> alphaShift) & channelMax) / channelMax
      : 1.0;
  return color.opacity * channelAlpha;
}
