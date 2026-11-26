import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// Zero-specificity defaults carry their own Tailwind rules, including when
// public resolver chrome is rendered without a Swap widget. Caller classes
// and inline constraints retain their ordinary cascade priority.
const _kSwapSizeOwner =
    '[:where(&)]:min-w-0 [:where(&)]:min-h-0 '
    '[:where(&)]:max-w-full [:where(&)]:max-h-full';
const _kSwapSizeSlot = '[:where(&>*)]:max-w-full [:where(&>*)]:max-h-full';

const _kSwapGridOverlap = WebElementChrome(
  className: _kSwapSizeOwner,
  inlineStyles: Styles(
    raw: {
      'display': 'grid',
      'grid-template-columns': 'minmax(0, 1fr)',
      'grid-template-rows': 'minmax(0, 1fr)',
      'place-items': 'center',
      'flex': '1 1 auto',
    },
  ),
);

// Each mode names its complete, immutable structural chrome. None and rotate
// share a grid box; flip participates in the existing root without a box.
const _kSwapOverlapLayouts = <CoreSwapAnimation, WebElementChrome>{
  CoreSwapAnimation.none: _kSwapGridOverlap,
  CoreSwapAnimation.rotate: _kSwapGridOverlap,
  CoreSwapAnimation.flip: WebElementChrome(
    className: '',
    inlineStyles: Styles(raw: {'display': 'contents'}),
  ),
};

/// Internal renderer chrome, absent from the barrel's constrained exports.
///
/// The DOM parent stays mounted in every mode. A flip adds no box, preserving
/// the existing root's absolute containing block and 3D rendering context.
WebElementChrome resolveSwapOverlapLayout(CoreSwapAnimation animation) =>
    _kSwapOverlapLayouts[animation]!;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Swap`.
///
/// DOM shape (an interactive swap is wrapped in a composed `Clickable`
/// by `swap.dart` — the Clickable owns cursor / press scale / focus
/// ring on its own node, so its press `transform` never fights the
/// rotate / flip `transform` on [root]):
///
/// ```text
/// Clickable                             // interactive only (onToggle != null)
///  └─ root (<div>)                      // owns animation transform
///       └─ stable private overlap      // grid for none/rotate, boxless for flip
///            ├─ offSlot (<div>)
///            └─ onSlot (<div>)
/// ```
///
/// `swap.dart` reads each slot's `className` + `inlineStyles`
/// straight from `resolved.<slot>` — no merge / fallback / conversion
/// in the widget body.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only
/// `WebElementChrome` slots (paint-ready chrome) plus the nested
/// [clickableStyle] Style slot. No scalar metadata (duration /
/// animation enum / etc.) is exposed — state (`checked` / `animation`)
/// flows in as resolver parameters so the resolver bakes the matching
/// transforms / transitions straight into each slot's inline CSS.
class ResolvedSwap implements WebResolvedChrome {
  /// Creates a [ResolvedSwap].
  const ResolvedSwap({
    required this.root,
    required this.offSlot,
    required this.onSlot,
    required this.clickableStyle,
  });

  /// Paint-ready chrome for the outer container `<div>` — typography +
  /// colour Tailwind className plus position / animation transform
  /// inline CSS.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the first slot `<div>` — flex
  /// centring className plus animation-specific inline CSS (opacity
  /// fade for `none`/`rotate`, `backface-visibility: hidden` for
  /// `flip`).
  final WebElementChrome offSlot;

  /// Paint-ready chrome for the second slot `<div>` — flex centring plus
  /// same-area grid placement, or the existing absolute overlay for flip.
  /// Pre-rotated 180° in `flip` mode.
  final WebElementChrome onSlot;

  /// Nested [CoreClickableStyle] slot for the composed root `Clickable`
  /// (interactive swaps only) — `CoreSwapStyle.defaultClickableStyle`
  /// merged with the per-instance override, raw-forwarded to
  /// `Clickable(clickableStyle:)`.
  final CoreClickableStyle clickableStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedSwap] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.swap.style
///   → widget.swapStyle
/// ```
///
/// State branches (`checked` / `animation`) shape the chrome inline
/// CSS — they are resolver parameters so the widget hands its state
/// once and receives paint-ready output. Interaction chrome (cursor /
/// press feedback / focus ring) is owned by the composed `Clickable`
/// wrapper, fed by the nested [ResolvedSwap.clickableStyle] slot.
ResolvedSwap resolveSwap(
  BuildContext context, {
  required bool checked,
  required CoreSwapAnimation animation,
  CoreSwapStyle? swapStyle,
}) {
  final compTheme = context.theme.coreComponentTheme?.swap;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreSwapStyle(), [
    compTheme?.style,
    swapStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  // Each value finished its merge + fallback so the local builders
  // below run from a single source of truth (closures capture these
  // directly).
  final durationMs =
      (merged.duration ?? CoreSwapStyle.defaultDuration).inMilliseconds;
  // Token-routed duration + easing (`durationMsCss` / `toVarCss` docs)
  // rather than raw `${ms}ms ease-in-out` literals — shared by both the
  // container's `transform` transition and each slot's `opacity` one.
  final transitionTiming =
      '${durationMsCss(durationMs)} ${CoreEasing.move.toVarCss()}';

  // EMIT Stage 2 (Web, theme-free) — typography routes through the
  // single `emitTypography` entry point: it merges the design-system
  // default role with any per-instance overlay and emits a `text-{role}`
  // class (+ token colour class) for a pure role, plus any explicit
  // scalar overlay inline. Both platforms share the same
  // `CoreSwapStyle.defaultTextStyle` so the role mapping cannot
  // silently diverge (verify.md 7-27). Colour is folded into the
  // nested `CoreTextStyle` slot (sb8).
  final textEmit = emitTypography(
    merged.textStyle,
    CoreSwapStyle.defaultTextStyle,
  );

  // Nested Clickable slot — partial default merged with the override,
  // raw-forwarded (the Clickable's own resolver fills the rest).
  final clickableStyle = CoreSwapStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );

  // ─── Local builders ───────────────────────────────────
  // Closures capture every chrome value above — no named-arg
  // explosion. Local to the resolver, inaccessible from outside.

  /// Composes the outer container `<div>` Tailwind className — the
  /// `emitTypography` role class (`text-{role} text-{colorToken}`)
  /// baseline so children that inherit text styling pick up the
  /// design-system body scale. Same single source as the Flutter
  /// side's `DefaultTextStyle` (verify.md 7-27).
  String buildRootClassName() => [
    textEmit.className,
    if (animation != .flip) _kSwapSizeOwner,
  ].join(' ');

  /// Composes the outer container `<div>` inline CSS — handles
  /// positioning, the parent rotation / flip transform that drives the
  /// animation, plus any explicit typography scalar overlay from
  /// `emitTypography`. Cursor is owned by the composed `Clickable`
  /// wrapper (interactive swaps only).
  ///
  /// `perspective(1000px)` is a CSS transform-geometry sentinel — the
  /// 1:1 counterpart of Flutter's `Matrix4..setEntry(3, 2, 0.001)`
  /// (`1 / 1000`). Not a design token: it controls 3D vanishing-point
  /// distance, not chrome.
  Styles buildRootInlineStyles() {
    final transform = switch (animation) {
      .rotate => checked ? 'rotate(180deg)' : 'rotate(0deg)',
      .flip =>
        checked
            ? 'perspective(1000px) rotateY(180deg)'
            : 'perspective(1000px) rotateY(0deg)',
      .none => null,
    };
    return Styles(
      raw: {
        ...?textEmit.inline,
        'position': 'relative',
        'display': animation == .flip ? 'inline-flex' : 'inline-grid',
        if (animation != .flip) ...{
          'place-items': 'center',
          'grid-template-columns': 'minmax(0, 1fr)',
          'grid-template-rows': 'minmax(0, 1fr)',
        },
        if (animation == .flip) ...{
          'transform-style': 'preserve-3d',
          '-webkit-transform-style': 'preserve-3d',
        },
        if (transform != null) ...{
          'transform': transform,
          'transition': 'transform $transitionTiming',
        },
      },
    );
  }

  /// Composes one slot `<div>` Tailwind className — `flex
  /// items-center justify-center` only (shared by both slots).
  String buildSlotClassName() => [
    WebLayout.flexCenter,
    if (animation != .flip) ...[_kSwapSizeOwner, _kSwapSizeSlot],
  ].join(' ');

  /// Composes one slot `<div>` inline CSS — rendering strategy depends
  /// on [animation]:
  ///
  /// - **none / rotate**: both slots overlap and opacity-crossfade.
  /// - **flip**: both slots sit back-to-back via CSS
  ///   `backface-visibility: hidden`. The on slot is pre-rotated 180°
  ///   so that when the parent rotates 180°, on becomes frontal while
  ///   off turns its back and disappears. No opacity — the 3D
  ///   back-face culling does the hide/reveal.
  ///
  /// Non-flip slots both contribute to intrinsic size. Their owned wrappers
  /// fill the shared grid area and center the independently sized public
  /// children. `overlay` selects the existing absolute on-slot only for flip.
  Styles buildSlotInlineStyles({
    required bool visible,
    required bool overlay,
    required bool isOnSlot,
  }) {
    final isFlip = animation == .flip;
    return Styles(
      raw: {
        if (overlay && isFlip) ...{
          'position': 'absolute',
          'inset': '0',
        },
        if (!isFlip) ...{
          'grid-area': '1 / 1',
          'align-self': 'stretch',
          'justify-self': 'stretch',
        },
        if (isFlip) ...{
          'backface-visibility': 'hidden',
          '-webkit-backface-visibility': 'hidden',
          if (isOnSlot) 'transform': 'rotateY(180deg)',
        } else ...{
          'opacity': visible ? '1' : '0',
          'transition': 'opacity $transitionTiming',
        },
      },
    );
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedSwap(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    offSlot: WebElementChrome(
      className: buildSlotClassName(),
      inlineStyles: buildSlotInlineStyles(
        visible: !checked,
        overlay: false,
        isOnSlot: false,
      ),
    ),
    onSlot: WebElementChrome(
      className: buildSlotClassName(),
      inlineStyles: buildSlotInlineStyles(
        visible: checked,
        overlay: true,
        isOnSlot: true,
      ),
    ),
    clickableStyle: clickableStyle,
  );
}
