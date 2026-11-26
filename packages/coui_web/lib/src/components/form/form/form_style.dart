/// Style helpers for `Form` (Web).
///
/// Encapsulates the `CoreFormStyle` merge chain (design default →
/// `CoreFormTheme.style` → `widget.formStyle`), so `co_form.dart` reads
/// only [ResolvedForm] and never touches the merge chain or
/// `coreComponentTheme` directly.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// ResolvedForm
// ═══════════════════════════════════════════════════

/// Resolver output for `Form` (Web).
///
/// DOM shape:
///
/// ```text
/// root (<div> | <form>)              // vertical flex stack
///   ├─ children[0]
///   ├─ children[1]
///   ├─ …
///   └─ actionsRow (<div>)            // co_form renders only when showActions == true
///        ├─ secondaryAction            // and only when showSecondaryAction == true
///        └─ primaryAction
/// ```
///
/// `Form` is a pure layout container — its only chrome is the
/// inter-item spacing. The vertical spacer between adjacent children
/// (and the actions row itself, rendered as one more flex child) is
/// emitted **inline** as a flex `gap` CSS rule (through `spaceCss`) on
/// [root], mirroring the Flutter `Column.spacing` native paint-API
/// argument; the spacer between the two action buttons is the same
/// shape on [actionsRow]. Single struct that the widget reads — the
/// merge chain has been applied:
///
/// ```text
/// design system default (CoreFormStyle.defaultRowSpacing / defaultActionSpacing)
///   → theme.coreComponentTheme.form.style
///   → widget.formStyle
/// ```
class ResolvedForm implements WebResolvedChrome {
  /// Creates a [ResolvedForm].
  const ResolvedForm({required this.root, required this.actionsRow});

  /// Paint-ready chrome for the outermost `<div>` / `<form>` flex stack —
  /// composed Tailwind className (`flex flex-col w-full`) and inline-CSS
  /// bundle carrying the resolved inter-row `gap`.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the actions row `<div>` — a `flex` row
  /// (right-aligned) with the resolved inter-button `gap` inline.
  /// `co_form` skips this element entirely when `showActions` is
  /// `false`.
  final WebElementChrome actionsRow;
}

/// Resolves [ResolvedForm] for a `Form` (Web).
///
/// Walks the merge chain:
///
/// ```text
/// design system default (CoreFormStyle.defaultRowSpacing)
///   → theme.coreComponentTheme.form.style
///   → widget.formStyle
/// ```
///
/// The inter-item spacing is emitted inline as a flex `gap` rule (single
/// inline signature — no `gap-*` Tailwind utility / class-drop branch).
/// No `scheme.resolve` (a no-op on Web) and no direct `cs.<token>` /
/// `ts.<role>` reference — `Form` carries no colour / typography chrome.
ResolvedForm resolveForm(
  BuildContext context, {
  double? rowSpacing,
  double? actionSpacing,
  CoreFormStyle? formStyle,
}) {
  final coreTheme = context.theme.coreComponentTheme?.form;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreFormStyle(), [
    coreTheme?.style,
    formStyle,
    if (rowSpacing != null || actionSpacing != null)
      CoreFormStyle(rowSpacing: rowSpacing, actionSpacing: actionSpacing),
  ]);

  // Inter-item spacing — caller widget override wins, else theme
  // override, else design-system default. Emitted inline as a flex `gap`
  // rule (single inline signature) through the spacing variable, which is
  // rem so it tracks the browser root font-size (text-scale parity with
  // Flutter).
  final rowGap = spaceCss(
    merged.rowSpacing ?? CoreFormStyle.defaultRowSpacing,
  );
  final actionGap = spaceCss(
    merged.actionSpacing ?? CoreFormStyle.defaultActionSpacing,
  );

  // ─── Local builders ───────────────────────────────────

  /// Composes the form `<div>` / `<form>` Tailwind className — `flex
  /// flex-col w-full` stack. The inter-item spacing is emitted inline as
  /// a `gap` rule, so no `gap-*` class is composed here.
  String buildRootClassName() => WebLayout.flexColFull;

  /// Composes the form `<div>` / `<form>` inline CSS — the resolved
  /// inter-row `gap`.
  Styles buildRootInlineStyles() => .new(raw: {'gap': rowGap});

  /// Composes the actions row `<div>` Tailwind className — a right-aligned
  /// flex row. The inter-button spacing is emitted inline as a `gap`
  /// rule, so no `gap-*` class is composed here.
  String buildActionsRowClassName() =>
      '${WebLayout.flexItemsCenter} ${WebLayout.justifyEnd}';

  /// Composes the actions row `<div>` inline CSS — the resolved
  /// inter-button `gap`.
  Styles buildActionsRowInlineStyles() => .new(raw: {'gap': actionGap});

  return ResolvedForm(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    actionsRow: WebElementChrome(
      className: buildActionsRowClassName(),
      inlineStyles: buildActionsRowInlineStyles(),
    ),
  );
}
