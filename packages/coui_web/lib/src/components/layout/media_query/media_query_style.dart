import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

/// Tailwind className for the outer container `<div>`. `co-mqv` is a
/// stable hook for ad-hoc CSS overrides; the actual visibility
/// switching uses the scoped `@container` rule written into the
/// first child.
///
/// `w-full`: the root is `container-type: inline-size`, and CSS
/// containment removes the children's contribution to the container's
/// own size — the element is inherently full-bleed (its width must
/// come from the parent, never from content). Declaring it as the
/// `w-full` **class** (in addition to the inline `width:100%`) lets
/// class-based full-bleed selectors match it like every other
/// full-bleed component root; under a shrink-to-fit ancestor an
/// inline-only width resolves against a collapsed 0-width parent.
const _kMediaQueryVisibilityRootClassName = 'co-mqv w-full';

/// Tailwind className for the primary slot wrapper `<div>`. Toggled
/// to `display: none` by the scoped `@container` rule when the
/// container width falls outside the configured bounds.
const _kMediaQueryVisibilityPrimaryClassName = 'co-mqv-primary';

/// Tailwind className for the optional alternate slot wrapper `<div>`.
/// Toggled to `display: contents` by the scoped `@container` rule when
/// the container width falls outside the configured bounds.
const _kMediaQueryVisibilityAlternateClassName = 'co-mqv-alternate';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Resolver output for [MediaQueryVisibility] (Web).
///
/// DOM shape (bounded):
///
/// ```text
/// root (<div id=$scopeId class="co-mqv">)   // CSS container wrapper
///   ├─ <style>                              // scoped @container rule
///   ├─ <div class="co-mqv-primary">         // primary child slot
///   └─ <div class="co-mqv-alternate">       // optional alternate slot
/// ```
///
/// `root` carries the outer container chrome — `co-mqv` className
/// plus the inline-CSS bundle (`width:100%`, `container-type` and
/// `container-name`) keyed on the build-time `scopeId`. The
/// `primary` / `alternate` slots are pre-composed
/// [WebElementChrome] pairs the widget passes straight to its inner
/// `<div>`s; per-slot visibility flips via the scoped `@container`
/// rule.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only:
/// * Cat 1 — [WebElementChrome] slots (paint-ready chrome).
///
/// The behavioural / composed-CSS data (`scopeId`, the scoped
/// `@container` rule CSS text, and the resolved `minWidth` / `maxWidth`
/// bounds that decide the unbounded short-circuit) is NOT carried here
/// — it is resolved separately via [resolveMediaQueryVisibilityCss]
/// because the widget injects it into a `<style>` child and uses the
/// `isUnbounded` flag to branch its build (number_ticker
/// separate-resolver pattern). The chrome resolver takes the
/// pre-computed `scopeId` so the `container-name` inline style and the
/// `@container` rule selector agree on the same string.
class ResolvedMediaQueryVisibility implements WebResolvedChrome {
  /// Creates a [ResolvedMediaQueryVisibility].
  const ResolvedMediaQueryVisibility({
    required this.root,
    required this.primary,
    required this.alternate,
  });

  /// Paint-ready chrome for the outer container `<div>` — `co-mqv`
  /// className plus the inline-CSS for `width:100%`,
  /// `container-type:inline-size`, and `container-name:$scopeId`.
  ///
  /// In the unbounded case the resolver still produces a valid
  /// chrome pair but the widget short-circuits to render the child
  /// directly; the chrome payload then exists only for callers that
  /// reach for `resolved.root` defensively.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the primary slot wrapper `<div>` —
  /// `co-mqv-primary` className. Toggled by the scoped `@container`
  /// rule when the container width falls outside the configured
  /// bounds.
  final WebElementChrome primary;

  /// Paint-ready chrome for the alternate slot wrapper `<div>` —
  /// `co-mqv-alternate` className. The widget renders the wrapper
  /// only when the consumer supplies an alternate child; the chrome
  /// pair is always provided here so callers don't conditionally
  /// resolve it.
  final WebElementChrome alternate;
}

// ═══════════════════════════════════════════════════
// Resolver — chrome entry point
// ═══════════════════════════════════════════════════

/// Resolves the paint-ready chrome for [MediaQueryVisibility].
///
/// Single chrome entry point — pure [WebElementChrome] slots only. The
/// [scopeId] is pre-computed by [resolveMediaQueryVisibilityCss] and
/// passed in so the outer container's `container-name` inline style
/// matches the `@container` rule selector.
ResolvedMediaQueryVisibility resolveMediaQueryVisibility({
  required String scopeId,
}) {
  // ─── Local builders ───────────────────────────────────

  /// Composes the outer container `<div>` inline CSS —
  /// `width:100%`, `container-type:inline-size`, and the per-instance
  /// `container-name` keyed on [scopeId] so the scoped `@container`
  /// rule targets this wrapper.
  Styles buildRootInlineStyles() => .new(
    raw: {
      'width': '100%',
      'container-type': 'inline-size',
      'container-name': scopeId,
    },
  );

  return ResolvedMediaQueryVisibility(
    root: WebElementChrome(
      className: _kMediaQueryVisibilityRootClassName,
      inlineStyles: buildRootInlineStyles(),
    ),
    primary: const WebElementChrome(
      className: _kMediaQueryVisibilityPrimaryClassName,
    ),
    alternate: const WebElementChrome(
      className: _kMediaQueryVisibilityAlternateClassName,
    ),
  );
}

// ═══════════════════════════════════════════════════
// Resolver — behavioural / composed-CSS entry point
// ═══════════════════════════════════════════════════

/// Resolves the scope id + scoped `@container` rule CSS text + the
/// unbounded branch flag for [MediaQueryVisibility].
///
/// Kept off [ResolvedMediaQueryVisibility] (pure chrome) per the
/// number_ticker / hover_card separate-resolver pattern: the
/// `@container` rule must be injected into a `<style>` child (cannot be
/// expressed as className / inlineStyles), and `isUnbounded` is a
/// build-time branch flag, not paint chrome. The `scopeId` is fed back
/// into [resolveMediaQueryVisibility] so the outer container's
/// `container-name` inline style matches the `@container` rule selector.
///
/// Single entry point — encapsulates the
/// `theme.coreComponentTheme.mediaQueryVisibility` lookup so the widget
/// `build` never touches the theme directly (mirrors Flutter resolver).
///
/// Priority: widget pixel > widget breakpoint > theme pixel > theme
/// breakpoint.
({String scopeId, String? containerRuleCss, bool isUnbounded})
resolveMediaQueryVisibilityCss(
  BuildContext context, {
  double? minWidth,
  double? maxWidth,
  CoreBreakpoint? minBreakpoint,
  CoreBreakpoint? maxBreakpoint,
}) {
  final coreTheme = context.theme.coreComponentTheme?.mediaQueryVisibility;

  final effectiveMin =
      minWidth ??
      minBreakpoint?.minWidth ??
      coreTheme?.style?.minWidth ??
      coreTheme?.style?.minBreakpoint?.minWidth;

  final effectiveMax =
      maxWidth ??
      maxBreakpoint?.minWidth ??
      coreTheme?.style?.maxWidth ??
      coreTheme?.style?.maxBreakpoint?.minWidth;

  // ─── Local builders ───────────────────────────────────

  /// Composes the stable container scope id for the resolved bounds.
  /// Same range → same id so `<style>` blocks deduplicate across the
  /// page and the resolver / widget agree on the `container-name`
  /// they wire up.
  String buildScopeId() {
    String slug(double? v) {
      if (v == null) return 'none';
      if (v == v.roundToDouble()) return 'px${v.toInt()}';
      return 'px${v.toString().replaceAll('.', '_')}';
    }

    return 'co-mqv-${slug(effectiveMin)}_${slug(effectiveMax)}';
  }

  final scopeId = buildScopeId();

  /// Composes the scoped `@container` rule CSS text — default
  /// hiding rule for the alternate slot + scoped `@container` swap
  /// rule that flips primary/alternate when the container width
  /// falls outside the configured bounds. Returns `null` when no
  /// bounds are configured (unbounded → widget short-circuits to
  /// render the child directly).
  String? buildContainerRuleCss() {
    if (effectiveMin == null && effectiveMax == null) return null;

    String fmtBreakpointPx(double v) {
      if (v == v.roundToDouble()) return v.toInt().toString();
      return v.toString();
    }

    final conditions = <String>[];
    if (effectiveMin != null) {
      conditions.add('(max-width: ${fmtBreakpointPx(effectiveMin - 1)}px)');
    }
    if (effectiveMax != null) {
      conditions.add('(min-width: ${fmtBreakpointPx(effectiveMax + 1)}px)');
    }
    final outOfRange = conditions.join(', ');

    return '#$scopeId .$_kMediaQueryVisibilityPrimaryClassName'
        ' { display: contents; }'
        ' #$scopeId .$_kMediaQueryVisibilityAlternateClassName'
        ' { display: none; }'
        ' @container $scopeId $outOfRange {'
        ' #$scopeId .$_kMediaQueryVisibilityPrimaryClassName'
        ' { display: none; }'
        ' #$scopeId .$_kMediaQueryVisibilityAlternateClassName'
        ' { display: contents; }'
        ' }';
  }

  return (
    scopeId: scopeId,
    containerRuleCss: buildContainerRuleCss(),
    isUnbounded: effectiveMin == null && effectiveMax == null,
  );
}
