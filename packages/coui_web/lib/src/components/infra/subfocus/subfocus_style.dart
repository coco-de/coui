/// Style-slot single entry point for the Web `SubfocusScope` /
/// `Subfocus` pair.
///
/// Mirrors the Flutter `subfocus_style.dart`: a `resolveSubfocus`
/// merge function that walks the nested merge chain
/// (`CoreSubfocusStyle.defaultX` → `theme.subfocusScope.style` →
/// `widget.subfocusStyle`) and ships back a [ResolvedSubfocus]
/// paint-ready chrome bundle.
///
/// The companion [resolveSubfocusScope] is state-independent — the
/// scope wrapper carries no design-system style slot of its own (it is
/// a focus-suppression container), so its [ResolvedSubfocusScope]
/// just ships the static `outline-none` className. Keeping it as a
/// `WebResolvedChrome` mirrors the PoC pattern used by the rest of the
/// navigation family (tabs / pagination / switcher / navigation_bar /
/// breadcrumb).
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' show Styles;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ════════════════════════════════════════════════════════════════
// ResolvedSubfocusScope — state-independent scope chrome
// ════════════════════════════════════════════════════════════════

/// Paint-ready chrome for Web `SubfocusScope`.
///
/// DOM shape:
///
/// ```text
/// root (<div role="group" tabindex="0">)   // outer focus-suppression
/// ```
///
/// The scope is a transparent container — it must not introduce any
/// chrome, only suppress its own default focus outline (it carries a
/// `tabindex` so it can receive focus before any item does). The
/// `root` slot just ships `outline-none`.
class ResolvedSubfocusScope implements WebResolvedChrome {
  /// Creates a [ResolvedSubfocusScope].
  const ResolvedSubfocusScope({required this.root});

  /// Paint-ready chrome for the outer `<div role="group">` scope.
  @override
  final WebElementChrome root;
}

// ════════════════════════════════════════════════════════════════
// resolveSubfocusScope — single entry point (state-independent)
// ════════════════════════════════════════════════════════════════

/// Resolves [ResolvedSubfocusScope].
///
/// State-independent — the scope wrapper exists purely to suppress its
/// own default focus outline. Kept as a `resolveCo*` entry point so
/// the contract mirrors the rest of the navigation family.
ResolvedSubfocusScope resolveSubfocusScope() {
  // ─── Local builders ───────────────────────────────────

  /// Composes the scope `<div role="group">` Tailwind className —
  /// transparent container that suppresses its own default focus
  /// outline (the focus ring is rendered by the wrapping
  /// `FocusOutline` while a child item holds focus).
  String buildRootClassName() => 'outline-none';

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedSubfocusScope(
    root: WebElementChrome(className: buildRootClassName()),
  );
}

// ════════════════════════════════════════════════════════════════
// ResolvedSubfocus — state-independent item chrome
// ════════════════════════════════════════════════════════════════

/// Paint-ready chrome for Web `Subfocus`.
///
/// DOM shape:
///
/// ```text
/// root (<div role="option" tabindex>)   // focusable item wrapper
///   └─ <FocusOutline>                  // design-system focus ring
///        └─ child                        // caller content
/// ```
///
/// The `root` slot bundles the static `outline-none` className (the
/// browser default outline is replaced by the design-system focus
/// ring rendered by the wrapping `FocusOutline`) plus the inline
/// `border-radius` that pins the focus-ring corner radius.
class ResolvedSubfocus implements WebResolvedChrome {
  /// Creates a [ResolvedSubfocus].
  const ResolvedSubfocus({required this.root});

  /// Paint-ready chrome for the focusable item `<div role="option">`
  /// wrapper.
  @override
  final WebElementChrome root;
}

// ════════════════════════════════════════════════════════════════
// resolveSubfocus — single entry point (state-independent)
// ════════════════════════════════════════════════════════════════

/// Resolves [ResolvedSubfocus] for the given [context].
///
/// Walks the 2-stage merge chain and applies the
/// `CoreSubfocusStyle.defaultX` static const fallback so the entry
/// reads only fully-resolved CSS-ready values:
///
/// ```text
/// CoreSubfocusStyle.defaultX        // design system default
///   → theme.coreComponentTheme.subfocusScope.style
///   → widget.subfocusStyle
/// ```
ResolvedSubfocus resolveSubfocus({
  required BuildContext context,
  CoreSubfocusStyle? subfocusStyle,
}) {
  final coreTheme = context.theme.coreComponentTheme?.subfocusScope;

  // Merge chain: theme.style → subfocusStyle.
  final merged = resolveStyleChain(const CoreSubfocusStyle(), [
    coreTheme?.style,
    subfocusStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  final radius =
      merged.focusRingRadius ?? CoreSubfocusStyle.defaultFocusRingRadius;
  final focusRingRadius = radius.toValue();

  // ─── Local builders ───────────────────────────────────

  /// Composes the focusable item `<div role="option">` Tailwind
  /// className — suppresses the browser default focus outline so the
  /// design-system focus ring (rendered by the wrapping
  /// `FocusOutline`) is the only ring shown.
  String buildRootClassName() => 'outline-none';

  /// Composes the focusable item `<div role="option">` inline-CSS
  /// bundle — pins the focus-ring corner radius that the wrapping
  /// `FocusOutline` rounds its ring to.
  Styles buildRootInlineStyles() {
    return Styles(raw: {'border-radius': focusRingRadius});
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedSubfocus(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
  );
}
