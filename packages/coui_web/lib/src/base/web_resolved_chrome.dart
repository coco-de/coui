/// Compile-time contract for Web `ResolvedCo*` outputs.
///
/// Every Web `ResolvedCo*` class — the output of a
/// `resolveCo{Component}` function — exposes the `root` slot: the
/// paint-ready chrome ([WebElementChrome]: className + optional inline
/// CSS) for the outermost DOM element. The resolver finishes the merge
/// chain, variant selection, chrome synthesis, and conversion once; the
/// `co_*` widget reads the result as-is.
///
/// ### Why only `root`?
///
/// All Web components emit exactly one outermost DOM element (jaspr
/// `Component.element(...)` returns a single node, no fragment).
/// `root` is the **invariant truth** shared across every component, so
/// it deserves an interface guarantee. Additional slots
/// (`content` for button, `header`/`footer` for card, etc.) are
/// component-specific and freely added — they don't share a universal
/// shape worth enforcing.
///
/// ```dart
/// class ResolvedButton implements WebResolvedChrome {
///   const ResolvedButton({required this.root, required this.content});
///
///   @override
///   final WebElementChrome root;
///   final WebElementChrome content;  // component-specific slot
/// }
///
/// // co_button.dart — uniform across every Web component
/// @override
/// Component build(BuildContext context) {
///   final resolved = resolveButton(...);
///   return Component.element(
///     tag: 'button',
///     classes: resolved.root.className,
///     styles: resolved.root.inlineStyles,
///     children: [...],
///   );
/// }
/// ```
///
/// ### What this enforces
///
/// - Every `ResolvedCo*` exposes a `root: WebElementChrome`.
/// - `co_*.build` reaches the outer element chrome the same way
///   across every component (`resolved.root.className`,
///   `resolved.root.inlineStyles`) — uniform pattern grep-able and
///   lint-able.
///
/// ### What this does NOT enforce
///
/// Component-specific slots and behavioural fields stay free — Dart
/// interfaces can only mandate presence, not forbid extras.
/// Field-completeness, builder-local-function rule, and the
/// no-conversion rule in `co_*` are enforced by
/// `scripts/guards/resolver/verify_contracts.sh` grep guards.
library;

import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:meta/meta.dart';

/// A Web `ResolvedCo*` value carrying the paint-ready root chrome.
///
/// Components with multiple DOM elements add their own
/// [WebElementChrome] fields (e.g. `content`, `header`, `footer`) —
/// the interface only mandates the root pair so every `co_*` widget
/// can reach it the same way.
@immutable
abstract interface class WebResolvedChrome {
  /// Paint-ready className + inline-CSS pair for the outermost DOM
  /// element.
  ///
  /// Produced by the resolver — layout primitives + variant token
  /// classes + state classes flattened into a [WebElementChrome]. The
  /// `co_*` widget passes it straight to `Component.element(classes:
  /// ..., styles: ...)`.
  WebElementChrome get root;
}
