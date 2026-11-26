import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Label`.
///
/// DOM shape:
///
/// ```text
/// root (<span>)                          // inline-flex row container
///   ├─ iconWrapper (<span>)              // co_label renders only when widget.icon != null
///   │    └─ icon (caller Component, wrapped in IconTheme(iconStyle.size))
///   ├─ text (Component.text)             // no chrome — passthrough
///   └─ requiredIndicator (<span>)        // co_label renders only when widget.isRequired
/// ```
///
/// All slot chromes are non-null — `co_label` decides whether to
/// render each optional slot based on instance state.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only:
/// * Cat 1 — `WebElementChrome` slots (paint-ready chrome).
/// * Cat 2 — nested `CoreXxxStyle` slots passed to child unified
///   widgets. [iconStyle] is forwarded to the leading icon via an
///   ambient `IconTheme(IconThemeData(size: iconStyle.size!))` so any
///   descendant `Icon` picks up the resolved icon size.
///   [iconLabelGapStyle] / [labelRequiredGapStyle] are forwarded
///   straight to `Gap(gapStyle: …)` siblings between the leading
///   icon / text / trailing required-indicator (matching Flutter
///   parity — no inline CSS margin leak).
///
/// No scalar metadata (iconSize / iconSpacing / etc.) is exposed —
/// dimensional values are folded into the nested [iconStyle] /
/// [iconLabelGapStyle] / [labelRequiredGapStyle] slots.
class ResolvedLabel implements WebResolvedChrome {
  /// Creates a [ResolvedLabel].
  const ResolvedLabel({
    required this.root,
    required this.iconWrapper,
    required this.requiredIndicator,
    required this.iconStyle,
    required this.iconLabelGapStyle,
    required this.labelRequiredGapStyle,
  });

  /// Paint-ready chrome for the outer `<span>` container — inline-flex
  /// row that lays out the optional leading icon + text + optional
  /// required indicator. Carries typography + colour className plus
  /// optional opacity / font-size inline CSS.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the leading icon wrapper `<span>` —
  /// `co_label` renders this only when `icon != null`. Carries
  /// inline-flex centred layout className. Spacing toward the label
  /// text is owned by [iconLabelGapStyle] forwarded to a sibling
  /// `Gap(gapStyle: …)`.
  final WebElementChrome iconWrapper;

  /// Paint-ready chrome for the trailing required indicator (`*`)
  /// `<span>` — `co_label` renders this only when `isRequired` is
  /// true. Carries required colour className only. Spacing from the
  /// label text is owned by [labelRequiredGapStyle] forwarded to a
  /// sibling `Gap(gapStyle: …)`.
  final WebElementChrome requiredIndicator;

  /// Nested `CoreIconStyle` slot — forwarded to the leading icon via
  /// an ambient `IconTheme(IconThemeData(size: iconStyle.size!))` in
  /// `co_label`, so any descendant `Icon` (or other size-aware
  /// component) picks up the resolved icon size.
  final CoreIconStyle iconStyle;

  /// Nested [CoreGapStyle] slot — passed to
  /// `Gap(gapStyle: …)` between the leading icon wrapper and the
  /// label text. Carries the merged design-system default +
  /// per-instance override (raw, pre-scaling — the receiving `Gap`
  /// runs its own resolve step). Mirrors Flutter parity.
  final CoreGapStyle iconLabelGapStyle;

  /// Nested [CoreGapStyle] slot — passed to
  /// `Gap(gapStyle: …)` between the label text and the trailing
  /// required indicator. Carries the merged design-system default +
  /// per-instance override (raw, pre-scaling — the receiving `Gap`
  /// runs its own resolve step). Mirrors Flutter parity.
  final CoreGapStyle labelRequiredGapStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedLabel] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.label.style
///   → widget.labelStyle
/// ```
ResolvedLabel resolveLabel(
  BuildContext context, {
  required bool disabled,
  CoreLabelStyle? labelStyle,
}) {
  final labelTheme = context.theme.coreComponentTheme?.label;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreLabelStyle(), [
    labelTheme?.style,
    labelStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  // Each value finished its merge + fallback so the local builders
  // below run from a single source of truth.
  // Nested `CoreIconStyle` slot — merge the design-system default with
  // any per-instance override and forward the whole slot to the wrapping
  // `IconTheme` via `co_label`.
  final iconStyle = CoreLabelStyle.defaultIconStyle.merge(merged.iconStyle);
  // Nested `CoreGapStyle` slots — merge the design-system default with
  // the per-instance override. Forwarded straight to sibling
  // `Gap(gapStyle: …)` between the leading icon / text / trailing
  // required indicator (mirrors Flutter parity — no inline CSS margin
  // leak).
  final iconLabelGapStyle = CoreLabelStyle.defaultIconLabelGapStyle.merge(
    merged.iconLabelGapStyle,
  );
  final labelRequiredGapStyle = CoreLabelStyle.defaultLabelRequiredGapStyle
      .merge(merged.labelRequiredGapStyle);
  final disabledOpacity =
      merged.disabledOpacity ?? CoreLabelStyle.defaultDisabledOpacity;

  // ─── EMIT Stage 2 (Web, theme-free) ───────────────────
  // Label typography — `emitTypography` merges the disabled-aware default
  // role (carrying its `onSurface` / `disabledContent` colour token) with
  // the per-instance overlay, emitting the `text-{role}` + `text-{colour}`
  // classes for the token-bound default and any explicit scalar overlay
  // (font-size / weight / line-height / spacing) inline (Flutter parity).
  // The disabled axis lives in its own nested `disabledTextStyle` slot
  // (sb8) so typography + colour for the muted state stay 1:1 with the
  // enabled path. No hand-rolled `text-${token.name}` role-class
  // construction and no separate `cs.<token>` colour pin.
  final labelEmit = disabled
      ? emitTypography(
          merged.disabledTextStyle,
          CoreLabelStyle.defaultDisabledTextStyle,
        )
      : emitTypography(merged.textStyle, CoreLabelStyle.defaultTextStyle);
  // Required indicator (`*`) colour — token-bound default / override emits
  // a `text-{token}` class (dark-mode reactive), a raw override goes
  // inline. Single class-XOR-inline decision via the emit family.
  // A disabled label paints its text, its `*` and its icon with the one
  // colour its disabled text style carries, so `requiredColor` only speaks
  // for the enabled state.
  final requiredEmit = disabled
      ? emitColor(
          merged.disabledTextStyle?.color,
          CoreLabelStyle.defaultDisabledTextStyle.color!,
          .text,
        )
      : emitColor(
          merged.requiredColor,
          CoreLabelStyle.defaultRequiredColor,
          .text,
        );
  final requiredInline = requiredEmit.inline == null
      ? null
      : Styles(raw: requiredEmit.inline);

  // ─── Local builders ───────────────────────────────────

  /// Composes the root `<span>` Tailwind className — inline-flex row +
  /// label typography ([labelEmit]) + disabled cursor.
  String buildRootClassName() {
    return <String>[
      WebLayout.inlineFlex,
      WebLayout.flexRow,
      WebLayout.itemsCenter,
      labelEmit.className,
      if (disabled) 'cursor-not-allowed',
    ].where((c) => c.isNotEmpty).join(' ');
  }

  /// Composes the root `<span>` inline-CSS bundle — disabled opacity +
  /// any inline typography overlay produced by [labelEmit] (raw overlays
  /// only — token role / colour stay on classes). Returns `null` when no
  /// inline rules apply.
  Styles? buildRootInlineStyles() {
    final raw = <String, String>{
      if (disabled) 'opacity': '$disabledOpacity',
      ...?labelEmit.inline,
    };
    return raw.isEmpty ? null : Styles(raw: raw);
  }

  /// Composes the leading icon wrapper `<span>` Tailwind className —
  /// inline-flex centred layout. Spacing toward the label text is
  /// owned by [iconLabelGapStyle] forwarded to a sibling `Gap`.
  String buildIconWrapperClassName() => WebLayout.inlineFlexItemsCenter;

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedLabel(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    iconWrapper: WebElementChrome(
      className: buildIconWrapperClassName(),
    ),
    requiredIndicator: WebElementChrome(
      className: requiredEmit.className,
      inlineStyles: requiredInline,
    ),
    iconStyle: iconStyle,
    iconLabelGapStyle: iconLabelGapStyle,
    labelRequiredGapStyle: labelRequiredGapStyle,
  );
}
