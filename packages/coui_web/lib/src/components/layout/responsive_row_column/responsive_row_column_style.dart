import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/components/layout/breakpoint/breakpoint_style.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `ResponsiveRowColumn`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)              // flex row/column — direction flips at `switchAt`
///   └─ …children             // caller-supplied content
/// ```
///
/// `responsive_row_column.dart` reads `resolved.root.className` +
/// `resolved.root.inlineStyles` straight back into
/// `Component.element(...)` — no merge / fallback / conversion in the
/// widget body.
///
/// The resolver carries only the `WebElementChrome` root slot
/// (paint-ready chrome) — no scalar metadata (`direction` /
/// `spacing` / alignment) is exposed separately, matching the PoC
/// button/card/frame standard.
class ResolvedResponsiveRowColumn implements WebResolvedChrome {
  /// Creates a [ResolvedResponsiveRowColumn].
  const ResolvedResponsiveRowColumn({required this.root});

  /// Paint-ready chrome for the outer `<div>` — `flex flex-row`/
  /// `flex flex-col` + `justify-*`/`items-*` className plus the
  /// inline-CSS `gap` for the resolved spacing.
  @override
  final WebElementChrome root;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedResponsiveRowColumn] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.responsiveRowColumn.style
///   → widget.responsiveRowColumnStyle
/// ```
///
/// Direction is derived from [resolveBreakpoint] — the single shared
/// tier-observation entry point (Story C) — never a new
/// `ResizeObserver`/measurement of its own
/// (`single-source-of-truth.md`).
ResolvedResponsiveRowColumn resolveResponsiveRowColumn(
  BuildContext context, {
  required CoreBreakpointTier? switchAt,
  CoreResponsiveRowColumnStyle? responsiveRowColumnStyle,
}) {
  final themeStyle =
      context.theme.coreComponentTheme?.responsiveRowColumn?.style;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreResponsiveRowColumnStyle(), [
    themeStyle,
    responsiveRowColumnStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  final effectiveSwitchAt =
      switchAt ?? CoreResponsiveRowColumnContract.defaultSwitchAt;
  final currentTier = resolveBreakpoint(context).tier;
  final isRow = currentTier.isAtLeast(effectiveSwitchAt);

  final spacing = merged.spacing ?? CoreResponsiveRowColumnStyle.defaultSpacing;
  final mainAxisAlignment =
      merged.mainAxisAlignment ??
      CoreResponsiveRowColumnStyle.defaultMainAxisAlignment;
  final crossAxisAlignment =
      merged.crossAxisAlignment ??
      CoreResponsiveRowColumnStyle.defaultCrossAxisAlignment;

  // ─── Local builders ───────────────────────────────────

  /// Rows fill their main-axis width. Columns hug their content unless
  /// cross-axis stretching requests the available width, as Flutter Flex
  /// does. A caller can still state its own width in either direction.
  String buildRootClassName() {
    final classList = [
      WebLayout.flex,
      if (isRow || crossAxisAlignment == CoreCrossAxisAlignment.stretch)
        WebLayout.wFull,
      WebLayout.maxWFull,
      if (isRow) WebLayout.flexRow else WebLayout.flexCol,
      mainAxisAlignment.tailwindJustify,
      _crossAxisAlignmentClass(crossAxisAlignment),
    ];
    return classList.join(' ');
  }

  /// Composes the outer `<div>` inline CSS.
  ///
  /// `gap` stays inline (not a `gap-*` Tailwind utility) because
  /// [spacing] is an arbitrary user-overridable `double?`, not
  /// guaranteed to land on the `CoreSpace` scale — matching `Frame`'s
  /// same-shaped `gap` field.
  Styles buildRootInlineStyles() {
    return Styles(raw: {'gap': spaceCss(spacing)});
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedResponsiveRowColumn(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
  );
}

// ═══════════════════════════════════════════════════
// File-private helpers (small pure functions, short signatures)
// ═══════════════════════════════════════════════════

/// Maps [CoreCrossAxisAlignment] to the Tailwind `items-*` class.
String _crossAxisAlignmentClass(CoreCrossAxisAlignment a) => switch (a) {
  .start => WebLayout.itemsStart,
  .end => WebLayout.itemsEnd,
  .center => WebLayout.itemsCenter,
  .stretch => WebLayout.itemsStretch,
  .baseline => WebLayout.itemsBaseline,
};
