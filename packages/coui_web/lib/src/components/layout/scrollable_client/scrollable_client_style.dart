import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

// ═══════════════════════════════════════════════════
// Resolved output — Category A (chrome)
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `ScrollableClient` — Category A
/// (chrome only).
///
/// DOM shape:
///
/// ```text
/// root (<div id=$scopeId>)                    // scroll viewport (overflow: auto)
///   ├─ <style>                                // scoped ::-webkit-scrollbar rules
///   └─ (optional flip wrapper <div>) or       // resolveScrollableClientContent
///        builder output                       // when reverse axis direction
/// ```
///
/// Per Epic #1603 (PoC v3 canonical), this struct carries **chrome only**.
/// Runtime / behaviour scalars (`diagonalDragBehavior`,
/// `hitTestBehavior`, `keyboardDismissBehavior`, `overscroll`,
/// `clipBehavior`, `showScrollbar`) are intentionally split into the
/// Category D record [ScrollableClientRuntime] produced by
/// [resolveScrollableClientRuntime] so the chrome resolver output
/// stays free of logic metadata (PoC button/alert/card parity rule —
/// "raw scalar 행동 enum, logic 메타" 금지).
///
/// `root` carries the scroll viewport chrome — `overflow-{auto,visible}`
/// + `relative w-full h-full` className plus the inline-CSS bundle
/// (`max-width:100%; max-height:100%`, `scrollbar-color`,
/// `scrollbar-width`, optional `overscroll-behavior` / `pointer-events`)
/// derived from the resolved fields.
///
/// Per-instance scrollbar `<style>` text is produced by the dedicated
/// [resolveScrollableClientScrollbarCss] entry point (Category C —
/// rules text) because it depends on the runtime [String] `scopeId` of
/// the viewport `<div>`. The optional flip wrapper chrome is produced by
/// [resolveScrollableClientContent] because it depends on the
/// per-widget axis direction.
class ResolvedScrollableClient implements WebResolvedChrome {
  /// Creates a [ResolvedScrollableClient].
  const ResolvedScrollableClient({required this.root});

  /// Paint-ready chrome for the outer scroll viewport `<div>` —
  /// `overflow-{auto,visible}` + `relative w-full h-full` className
  /// plus the inline-CSS bundle (`max-width:100%; max-height:100%`,
  /// `scrollbar-color`, `scrollbar-width`, optional
  /// `overscroll-behavior` / `pointer-events`).
  ///
  /// When the drag-axis lock activates (`weightedEvent` /
  /// `weightedContinuous`), the widget composes an additional
  /// `touch-action` rule onto this bundle at build time because the
  /// lock is per-frame state.
  @override
  final WebElementChrome root;
}

// ═══════════════════════════════════════════════════
// Runtime behaviour config (Category D — not paint chrome)
// ═══════════════════════════════════════════════════

/// Runtime behaviour configuration for Web `ScrollableClient` —
/// Category D (runtime scroll behaviour).
///
/// Per Epic #1603 (PoC v3 canonical) behaviour scalars are split out of
/// the chrome [ResolvedScrollableClient] so the chrome resolver output
/// carries only paint-ready chrome. Exposed as a Dart record (NOT a
/// `ResolvedCo*` struct) because these are behavioural identifiers read
/// by the pointer / scroll / keyboard handlers between builds, not paint
/// chrome (number_ticker / hover_card separate-resolver record pattern).
///
/// The widget reads these scalars to drive:
/// * scroll-axis lock (`diagonalDragBehavior`),
/// * scroll-driven keyboard dismissal (`keyboardDismissBehavior`),
/// * scrollbar `<style>` emission (`showScrollbar` — also passed to
///   [resolveScrollableClientScrollbarCss]),
/// * inline `touch-action` composition when the axis lock fires,
/// * branching between `overflow-visible` and `overflow-auto` chrome
///   classes (`clipBehavior` — also folded into the chrome resolver
///   via the same call).
///
/// Folded once by [resolveScrollableClientRuntime] from the
/// widget → theme → design-system default chain.
typedef ScrollableClientRuntime = ({
  /// Effective diagonal drag behaviour (already folded widget/theme).
  CoreDiagonalDragBehavior diagonalDragBehavior,

  /// Whether overscroll physics (rubber-banding / scroll chaining) are
  /// enabled.
  bool overscroll,

  /// Clip behaviour applied to the viewport. [CoreClip.none] disables
  /// scrolling (CSS `overflow: visible`).
  CoreClip clipBehavior,

  /// Effective hit-test behaviour (already folded widget/theme).
  CoreHitTestBehavior hitTestBehavior,

  /// Effective keyboard-dismiss behaviour (already folded widget/theme).
  CoreKeyboardDismissBehavior keyboardDismissBehavior,

  /// Whether the design-system scrollbar skin is rendered.
  bool showScrollbar,
});

// ═══════════════════════════════════════════════════
// Resolved output — Category A (flip wrapper chrome)
// ═══════════════════════════════════════════════════

/// Resolver output for the optional flip wrapper `<div>` of a
/// `ScrollableClient`.
///
/// DOM shape:
///
/// ```text
/// content (<div>)                       // resolved.root — transform-flipped wrapper
///   └─ builder output                   // user content (kept upright by its own wrapper)
/// ```
///
/// The wrapper is rendered only when [CoreScrollableDetails.direction]
/// requires a reverse-axis flip (vertical `.up` and/or horizontal
/// `.left`). When neither axis reverses, the widget injects the builder
/// output directly so the child's intrinsic width/height controls the
/// scrollbar — a wrapper with `min-width/height: 100%` would force the
/// child to shrink-fit the viewport instead.
class ResolvedScrollableClientContent implements WebResolvedChrome {
  /// Creates a [ResolvedScrollableClientContent].
  const ResolvedScrollableClientContent({required this.root});

  /// Paint-ready chrome for the flip wrapper `<div>` — empty className
  /// plus the inline-CSS bundle (`min-width:100%; min-height:100%`,
  /// `transform: scaleY(-1) / scaleX(-1)`, `transform-origin: center`).
  @override
  final WebElementChrome root;
}

// ═══════════════════════════════════════════════════
// Resolvers
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedScrollableClient] for [ScrollableClient] —
/// chrome entry point (Category A).
///
/// Reads the already-folded runtime [runtime] (Category D) so the
/// chrome derivation never duplicates the widget → theme → default
/// fallback chain. Callers MUST resolve [runtime] first via
/// [resolveScrollableClientRuntime] and pass it in.
ResolvedScrollableClient resolveScrollableClient(
  BuildContext context, {
  required ScrollableClientRuntime runtime,
}) {
  // Fold the design-system default scrollbar tint with the project theme
  // override (mirrors `resolveScrollableClientScrollbarCss`'s chain —
  // no per-instance widget style is plumbed through this entry point).
  final merged = resolveStyleChain(const CoreScrollableClientStyle(), [
    context.theme.coreComponentTheme?.scrollableClient?.style,
  ]);

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer viewport `<div>` Tailwind className —
  /// `overflow-{auto,visible}` plus `relative w-full h-full`, and the
  /// suppression of the user-agent focus outline.
  /// [CoreClip.none] disables scrolling (CSS `overflow: visible`).
  ///
  /// The root carries `tabindex="0"` unconditionally and draws its own
  /// ring through `resolveScrollableClientFocusRingCss`, so without
  /// `outline-none` the browser's default outline would paint in place of
  /// that ring. `outline-none` is unconditional because it is the ring's
  /// resting state (`2px solid transparent`): focusing then moves only
  /// the outline colour instead of flipping `outline-style`, the same
  /// resting state every other ring host carries (`button_style.dart`).
  String buildRootClassName() {
    final overflow = runtime.clipBehavior == .none
        ? WebLayout.overflowVisible
        : WebLayout.overflowAuto;
    return '$overflow ${WebLayout.relative} ${WebLayout.wFull} '
        '${WebLayout.hFull} outline-none';
  }

  /// Composes the outer viewport `<div>` inline CSS — `max-width:100%;
  /// max-height:100%`, scrollbar tint (`scrollbar-color` /
  /// `scrollbar-width` for Firefox + Chromium 121+), optional
  /// `overscroll-behavior` and `pointer-events` rules.
  Styles buildRootInlineStyles() {
    // Native scrollbar tint — `scrollbar-color: <thumb> <track>` (Firefox +
    // Chromium 121+). Both colours flow from the design-system
    // `CoreScrollableClientStyle` defaults (single source shared with the
    // Flutter `RawScrollbar` thumb tint); `.toValue()` emits the token as a
    // valid `rgb(var(--coui-X))` value.
    final thumb =
        (merged.scrollbarThumbColor ??
                CoreScrollableClientStyle.defaultScrollbarThumbColor)
            .toValue();
    final track =
        (merged.scrollbarTrackColor ??
                CoreScrollableClientStyle.defaultScrollbarTrackColor)
            .toValue();

    final raw = {
      'max-width': '100%',
      'max-height': '100%',
      if (runtime.showScrollbar) 'scrollbar-color': '$thumb $track',
      'scrollbar-width': runtime.showScrollbar ? 'thin' : 'none',
    };

    if (!runtime.overscroll) {
      raw['overscroll-behavior'] = 'contain';
    }

    // hitTestBehavior → pointer-events.
    // - opaque / translucent: CSS default (`auto`), events land on the
    //   element. Native behaviour already lets siblings underneath receive
    //   events when we don't stopPropagation, so translucent + opaque
    //   render identically at the DOM level.
    // - deferToChild: disable events on the bare root; children opt back
    //   in by rendering an actual DOM node (CSS default).
    if (runtime.hitTestBehavior == .deferToChild) {
      raw['pointer-events'] = 'none';
    }

    // diagonalDragBehavior is honoured by the pointer-event driven axis
    // lock in `co_scrollable_client.dart`. Leaving `touch-action` at the
    // browser default ('auto') preserves horizontal wheel/trackpad scroll
    // on desktop — an inline `touch-action: pan-y` would block them even
    // though it's strictly a touch-gesture property on paper.
    return Styles(raw: raw);
  }

  return ResolvedScrollableClient(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
  );
}

/// Resolves the [ScrollableClientRuntime] record for
/// [ScrollableClient] — runtime behaviour entry point (Category D).
///
/// Priority (per-field): widget value > shared `CoreScrollableClientContract`
/// design-system default. The behaviour defaults are `static const` on the
/// contract so the Flutter and Web resolvers stay in parity.
ScrollableClientRuntime resolveScrollableClientRuntime(
  BuildContext context, {
  CoreDiagonalDragBehavior? diagonalDragBehavior,
  bool? overscroll,
  CoreClip? clipBehavior,
  CoreHitTestBehavior? hitTestBehavior,
  CoreKeyboardDismissBehavior? keyboardDismissBehavior,
  bool? showScrollbar,
}) {
  final effectiveDiagonalDragBehavior =
      diagonalDragBehavior ??
      CoreScrollableClientContract.defaultDiagonalDragBehavior;
  final effectiveOverscroll =
      overscroll ?? CoreScrollableClientContract.defaultOverscroll;
  final effectiveClipBehavior = clipBehavior ?? .hardEdge;
  final effectiveHitTestBehavior =
      hitTestBehavior ?? CoreScrollableClientContract.defaultHitTestBehavior;
  final effectiveKeyboardDismissBehavior =
      keyboardDismissBehavior ??
      CoreScrollableClientContract.defaultKeyboardDismissBehavior;
  final effectiveShowScrollbar =
      showScrollbar ?? CoreScrollableClientContract.defaultShowScrollbar;
  return (
    diagonalDragBehavior: effectiveDiagonalDragBehavior,
    overscroll: effectiveOverscroll,
    clipBehavior: effectiveClipBehavior,
    hitTestBehavior: effectiveHitTestBehavior,
    keyboardDismissBehavior: effectiveKeyboardDismissBehavior,
    showScrollbar: effectiveShowScrollbar,
  );
}

/// Resolves [ResolvedScrollableClientContent] for the flip wrapper
/// `<div>` of a `ScrollableClient`. Closes over the per-widget axis
/// directions ([verticalDirection] / [horizontalDirection]) so the
/// transform inline CSS is pre-composed.
///
/// `scaleY(-1)` / `scaleX(-1)` flips the painted content so the user
/// sees it end-first while the browser still scrolls from (0,0).
/// Children are flipped back in their own wrapper so text doesn't
/// render upside down.
ResolvedScrollableClientContent resolveScrollableClientContent({
  required CoreAxisDirection verticalDirection,
  required CoreAxisDirection horizontalDirection,
}) {
  // ─── Local builders ───────────────────────────────────

  /// Composes the flip wrapper `<div>` inline CSS — `min-width:100%;
  /// min-height:100%` plus the resolved `transform` declaration when
  /// either axis reverses.
  Styles buildContentInlineStyles() {
    final flips = <String>[];
    if (verticalDirection == .up) flips.add('scaleY(-1)');
    if (horizontalDirection == .left) flips.add('scaleX(-1)');
    final raw = {
      'min-width': '100%',
      'min-height': '100%',
    };
    if (flips.isNotEmpty) {
      raw['transform'] = flips.join(' ');
      raw['transform-origin'] = 'center';
    }
    return Styles(raw: raw);
  }

  return ResolvedScrollableClientContent(
    root: WebElementChrome(
      className: '',
      inlineStyles: buildContentInlineStyles(),
    ),
  );
}

/// Resolves the scoped `<style>` CSS text for the WebKit / Blink
/// scrollbar skin of a `ScrollableClient`. Closes over the per-
/// instance [scopeId] of the viewport `<div>` so the
/// `::-webkit-scrollbar` rules target the matching element.
///
/// Returns the raw CSS [String] directly (Category C — rules text)
/// rather than a `ResolvedCo*` wrapper, because it carries `<style>`
/// text content, not an element's className / inlineStyles. The widget
/// injects the returned string into a `<style>` element.
///
/// Firefox / Chromium 121+ already pick up `scrollbar-color` +
/// `scrollbar-width: thin` from the inline `style` on the root. WebKit
/// and older Blink ignore those properties so the legacy
/// `::-webkit-scrollbar` pseudo-element rules are still needed to
/// match Flutter's `RawScrollbar`. The thumb / track dimensions fold
/// the design-system default with the project `style` override
/// (thickness = `merged.scrollbarThickness`, radius =
/// `merged.scrollbarRadius`, thumb = `onSurface @ opacityDisabled`,
/// track = `surfaceContainer`).
String resolveScrollableClientScrollbarCss(
  BuildContext context, {
  required String scopeId,
  required bool showScrollbar,
}) {
  if (!showScrollbar) {
    return '#$scopeId::-webkit-scrollbar { display: none; }';
  }
  // Fold the design-system default scrollbar style with the project
  // theme override. The radius is emitted inline as a
  // `(merged.X ?? default) / kRemDivisor`-based rem rule (single
  // signature — no Tailwind class).
  final merged = resolveStyleChain(const CoreScrollableClientStyle(), [
    context.theme.coreComponentTheme?.scrollableClient?.style,
  ]);
  final scrollbarThickness =
      merged.scrollbarThickness ??
      CoreScrollableClientStyle.defaultScrollbarThickness;
  final scrollbarRadius =
      merged.scrollbarRadius ??
      CoreScrollableClientStyle.defaultScrollbarRadius;
  // Stroke-axis value (mirrors Flutter's `theme.geometry.stroke` on this
  // same field) — must ride `strokeWidthCss` so the neo-brutalism
  // `strokeFloor` preset reaches it via `--coui-stroke-width-N`, not a
  // literal rem it can't override.
  final thickness = strokeWidthCss(scrollbarThickness);
  final radius = '${scrollbarRadius / kRemDivisor}rem';
  // Thumb / track tints flow from the design-system
  // `CoreScrollableClientStyle` defaults (same source as the inline
  // `scrollbar-color`); `.toValue()` emits a valid `rgb(var(--coui-X))`.
  final thumb =
      (merged.scrollbarThumbColor ??
              CoreScrollableClientStyle.defaultScrollbarThumbColor)
          .toValue();
  final track =
      (merged.scrollbarTrackColor ??
              CoreScrollableClientStyle.defaultScrollbarTrackColor)
          .toValue();
  return '''
#$scopeId::-webkit-scrollbar { width: $thickness; height: $thickness; }
#$scopeId::-webkit-scrollbar-track { background: $track; border-radius: $radius; }
#$scopeId::-webkit-scrollbar-thumb { background: $thumb; border-radius: $radius; }
#$scopeId::-webkit-scrollbar-corner { background: transparent; }
''';
}

/// Resolves the scoped `:focus-visible` ring rule for a
/// `ScrollableClient` (Category C — rules text).
///
/// The viewport carries `tabindex="0"`, so a keyboard user lands on it
/// and WCAG 2.4.7 requires that landing to be visible. The ring is a
/// scoped `outline` on the viewport itself rather than a `FocusOutline`
/// wrapper: the viewport is the element that owns `overflow`, and
/// putting a wrapper around it would move the sized box one level out.
/// An outline is not clipped by its own element's `overflow`, so the
/// ring stays whole however the content scrolls. Flutter has no
/// `:focus-visible` to key on, so its twin composes `FocusOutline` off
/// `onShowFocusHighlight` — different mechanism, same
/// [CoreFocusOutlineStyle] slot and therefore the same ring.
///
/// The ring values are read from the component's own filled default
/// merged with the per-instance override, exactly as `Button` does.
String resolveScrollableClientFocusRingCss(
  BuildContext context, {
  required String scopeId,
}) {
  final merged = resolveStyleChain(const CoreScrollableClientStyle(), [
    context.theme.coreComponentTheme?.scrollableClient?.style,
  ]);
  // The ring override arrives through the nested focus-outline slot
  // (base-then-merge with `merged.focusOutlineStyle`) rather than as a
  // flat field, so the literal form the chaining guard looks for cannot
  // appear here. The marker below is how that is declared; reach is not
  // taken on faith — a test overrides the opacity and reads it back out
  // of the emitted rule.
  // guard-nested-override: ringOpacity
  final slot = CoreScrollableClientStyle.defaultFocusOutlineStyle.merge(
    merged.focusOutlineStyle,
  );
  final ringWidth = slot.borderWidth!;

  return focusRingScopedRule(
    scopeSelector: '#$scopeId',
    pseudo: .focusVisible,
    ringColor: slot.borderColor!,
    offsetColor: slot.offsetColor!,
    ringWidth: ringWidth,
    ringOffset: slot.align! - ringWidth,
    ringOpacity: slot.ringOpacity ?? CoreFocusOutlineStyle.defaultRingOpacity,
  );
}
