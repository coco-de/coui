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
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Collapsible`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                          // outer wrapper (no chrome)
///   ├─ Clickable(clickableStyle)      // trigger interaction wrapper
///   │    └─ triggerRow (<div>)          // full-width flex header row
///   │         ├─ triggerText (<div>)    // typography + flex:1
///   │         ├─ Gap(iconLabelGapStyle) // nested slot — between text & chevron
///   │         └─ chevron (<div>)        // icon wrapper with rotation
///   │              └─ Icon(iconStyle) // sized + coloured via slot
///   └─ content (<div>)                  // grid-template-rows animation
///        └─ contentInner (<div>)        // inner content holder
/// ```
///
/// `co_collapsible.dart` reads each slot's `className` + `inlineStyles`
/// straight from `resolved.<slot>` — no merge / fallback / conversion
/// in the widget body.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only:
/// * Cat 1 — `WebElementChrome` slots (paint-ready chrome).
/// * Cat 2 — nested [CoreXxxStyle] slots forwarded straight to child
///   unified widgets. [iconStyle] feeds the chevron
///   `Icon(iconStyle: …)`, [iconLabelGapStyle] feeds the
///   `Gap(gapStyle: …)` between the trigger text and the chevron, and
///   [clickableStyle] feeds the trigger `Clickable(clickableStyle: …)`
///   — each receiving child runs its own resolve/scaling step so
///   Flutter ↔ Web parity is preserved (no inline `width` rem leak).
///
/// No scalar metadata (durationMs / iconLabelGap / arrowIconSize / …)
/// is exposed — chrome values are already folded into the matching
/// `WebElementChrome` slots, and the chevron sizing / colour rides the
/// [iconStyle] slot.
class ResolvedCollapsible implements WebResolvedChrome {
  /// Creates a [ResolvedCollapsible].
  const ResolvedCollapsible({
    required this.root,
    required this.triggerRow,
    required this.triggerText,
    required this.iconLabelGapStyle,
    required this.chevron,
    required this.content,
    required this.contentInner,
    required this.iconStyle,
    required this.clickableStyle,
  });

  /// Outer wrapper `<div>` chrome — currently no chrome, but kept as the
  /// [WebResolvedChrome] root slot for contract uniformity.
  @override
  final WebElementChrome root;

  /// Clickable trigger row `<div>` chrome — flex layout + cursor +
  /// padding + `outline-none`.
  final WebElementChrome triggerRow;

  /// Trigger text wrapper `<div>` chrome — typography + colour Tailwind
  /// classes plus the resolved `triggerTextStyle` override + `flex:1`.
  final WebElementChrome triggerText;

  /// Nested [CoreGapStyle] slot — passed to `Gap(gapStyle: …)`
  /// between the trigger text and the chevron icon. Carries the merged
  /// design-system default + per-instance override (raw, pre-scaling —
  /// the receiving `Gap` runs its own resolve step). Mirrors the
  /// Flutter `Gap` parity exemplar (basic / breadcrumb).
  final CoreGapStyle iconLabelGapStyle;

  /// Chevron icon wrapper `<div>` chrome — colour Tailwind class plus
  /// the transform-rotation transition driven by the expanded state.
  final WebElementChrome chevron;

  /// Outer content wrapper `<div>` chrome — drives the
  /// `grid-template-rows: 0fr → 1fr` expand/collapse animation.
  final WebElementChrome content;

  /// Inner content holder `<div>` chrome — typography + colour classes
  /// plus inline `padding-top` (expanded only) + `min-height: 0` and the
  /// resolved `contentTextStyle` override (emitted inline via
  /// `toInlineCss`).
  final WebElementChrome contentInner;

  /// Nested [CoreIconStyle] slot — forwarded to `Icon(iconStyle: …)`
  /// for the chevron glyph. Carries the resolved icon size and (when
  /// overridden) colour; a `null` colour lets the glyph inherit the
  /// `currentColor` from the chevron wrapper's `text-on-surface` class.
  final CoreIconStyle iconStyle;

  /// Nested [CoreClickableStyle] slot for the composed trigger
  /// `Clickable` — `CoreCollapsibleStyle.defaultClickableStyle`
  /// (press-scale off) merged with the per-instance override,
  /// raw-forwarded to `Clickable(clickableStyle: …)`. The Clickable
  /// owns the trigger's cursor / `select-none` / `:focus-visible` ring /
  /// keyboard activation, so the widget no longer hand-rolls the
  /// `role="button"` div, its click / keydown / focus / blur handlers,
  /// or the `FocusOutline` wrapper.
  final CoreClickableStyle clickableStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedCollapsible] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.collapsible.style
///   → widget.collapsibleStyle
/// ```
///
/// The semantic [isExpanded] state is a widget prop — it threads
/// through to drive the chevron rotation and the grid-rows animation
/// here. The theme cannot override it (Epic #1603 옵션 B 최종).
ResolvedCollapsible resolveCollapsible(
  BuildContext context, {
  required bool isExpanded,
  CoreCollapsibleStyle? collapsibleStyle,
}) {
  final csTheme = context.theme.coreComponentTheme?.collapsible;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreCollapsibleStyle(), [
    csTheme?.style,
    collapsibleStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  // Each value finished its merge + fallback so the local builders
  // below run from a single source of truth.
  final contentInset =
      merged.contentInset ?? CoreCollapsibleStyle.defaultContentInset;
  // Trigger ↔ chevron gap slot — design-system default `CoreGapStyle`
  // merged with the per-instance override. The slot is forwarded raw
  // (pre-scaling) to `Gap(gapStyle: …)` in `co_collapsible.dart`,
  // mirroring the Flutter parity exemplar (basic / breadcrumb). The
  // receiving `Gap` runs its own resolve step so no inline `width`
  // rem leak rides this resolver (Epic #1603 nested-slot — `merged
  // .iconLabelGapStyle` wins on each non-null field).
  final iconLabelGapStyle = CoreCollapsibleStyle.defaultIconLabelGapStyle.merge(
    merged.iconLabelGapStyle,
  );
  final durationMs =
      (merged.duration ?? CoreCollapsibleStyle.defaultDuration).inMilliseconds;
  // Token-routed duration + easing (`durationMsCss` / `toVarCss` docs),
  // shared by the chevron rotation and content collapse transitions.
  final transitionTiming =
      '${durationMsCss(durationMs)} ${CoreEasing.move.toVarCss()}';
  // Icon style slot — design-system default `CoreIconStyle` merged with
  // the per-instance override. Forwarded straight to
  // `Icon(iconStyle: …)` (Epic #1603 nested-slot — `merged.iconStyle`
  // wins on each non-null field).
  final iconStyle = CoreCollapsibleStyle.defaultIconStyle.merge(
    merged.iconStyle,
  );
  // Nested Clickable slot — the press-scale-off partial default merged
  // with the per-instance override, raw-forwarded to
  // `Clickable(clickableStyle: …)` (the Clickable's own resolver fills
  // the rest, incl. the focus-ring radius).
  final clickableStyle = CoreCollapsibleStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );

  // ─── EMIT Stage 2 (Web, theme-free) ───────────────────
  // Typography routes through `emitTypography` against the Core defaults:
  // the role (`body-medium`) + token colour (`on-surface`) emit Tailwind
  // classes (dark-mode reactive, inherited by the inner text node) while
  // any explicit scalar overlay (trigger's `medium` weight, per-instance
  // size/weight/spacing) emits inline. The chevron is colour-only — routed
  // through `emitColor` so its `currentColor` (the glyph inherits) stays a
  // single-source token class. No hand-rolled `text-${typography...}` /
  // `text-$onSurface` (layer-mapping single-source).
  final triggerTextEmit = emitTypography(
    merged.triggerTextStyle,
    CoreCollapsibleStyle.defaultTriggerTextStyle,
  );
  final contentTextEmit = emitTypography(
    merged.contentTextStyle,
    CoreCollapsibleStyle.defaultContentTextStyle,
  );
  // Chevron wrapper colour — the glyph inherits `currentColor`; route the
  // `onSurface` token through `emitColor` (token → `text-on-surface`
  // class).
  // guard-nested-override: iconColor — the chevron colour override rides the
  // nested CoreIconStyle slot's .color sub-field (merged.iconStyle?.color); the
  // contract has no flat iconColor field (icon chrome → iconStyle slot).
  final chevronColorEmit = emitColor(
    merged.iconStyle?.color,
    CoreCollapsibleStyle.defaultIconColor,
    .text,
  );

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer wrapper `<div>` chrome — `inline-flex flex-col`
  /// so the stack hugs its trigger (Flutter `Column(mainAxisSize: min)`).
  /// An unclassed block `<div>` stretches to the capture frame (widthPx 800).
  WebElementChrome buildRootChrome() => const .new(
    className: '${WebLayout.inlineFlex} ${WebLayout.flexCol}',
  );

  /// Composes the trigger row `<div>` chrome — a full-width `flex`
  /// layout that fills the composing `Clickable` (so the chevron stays
  /// pinned to the right edge), plus the resolved padding. The cursor /
  /// `select-none` / focus-ring live on the `Clickable` root now, not
  /// here. Padding is **always** emitted inline as the
  /// `(merged.contentInset ?? default).toValue()` shorthand (Epic #1603
  /// 단일 시그니처 — radius / padding / gap / size never ride a class-drop
  /// branch).
  WebElementChrome buildTriggerRowChrome() => .new(
    className: WebLayout.flexItemsCenterFull,
    inlineStyles: Styles(raw: {'padding': contentInset.toValue()}),
  );

  /// Composes the trigger text wrapper `<div>` chrome — the
  /// `emitTypography` role + colour classes (`text-body-medium
  /// text-on-surface`, dark-mode reactive) plus the explicit `medium`
  /// weight overlay inline, the interaction-state `hover:underline`
  /// pseudo-class, the `flex:1`, and any per-instance typography overlay
  /// (also carried by [triggerTextEmit] inline).
  WebElementChrome buildTriggerTextChrome() {
    final className = <String>[
      triggerTextEmit.className,
      'hover:underline',
    ].where((cls) => cls.isNotEmpty).join(' ');
    final raw = {
      WebLayout.flex: '1',
      ...?triggerTextEmit.inline,
    };
    return WebElementChrome(
      className: className,
      inlineStyles: Styles(raw: raw),
    );
  }

  /// Composes the chevron icon wrapper `<div>` chrome — `onSurface`
  /// colour Tailwind class ([chevronColorEmit] — the glyph inherits
  /// `currentColor`) plus the rotation transition driven by [isExpanded].
  WebElementChrome buildChevronChrome() => .new(
    className: <String>[
      '${WebLayout.flex} ${WebLayout.itemsCenter} ${WebLayout.shrinkZero}',
      chevronColorEmit.className,
    ].where((cls) => cls.isNotEmpty).join(' '),
    inlineStyles: Styles(
      raw: {
        'transition': 'transform $transitionTiming',
        'transform': isExpanded ? 'rotate(180deg)' : 'rotate(0deg)',
      },
    ),
  );

  /// Composes the outer content wrapper `<div>` chrome — drives the
  /// `grid-template-rows: 0fr → 1fr` expand/collapse animation.
  WebElementChrome buildContentChrome() => .new(
    className: '${WebLayout.grid} ${WebLayout.overflowHidden}',
    inlineStyles: Styles(
      raw: {
        'grid-template-rows': isExpanded ? '1fr' : '0fr',
        'transition': 'grid-template-rows $transitionTiming',
      },
    ),
  );

  /// Composes the inner content holder `<div>` chrome — typography +
  /// colour Tailwind classes plus the inline `padding-top` (expanded
  /// only) + `min-height: 0` so the parent grid row can fully collapse
  /// to height 0.
  WebElementChrome buildContentInnerChrome() => .new(
    className: contentTextEmit.className,
    inlineStyles: Styles(
      raw: {
        'padding-top': spaceCss(isExpanded ? contentInset.top : 0),
        'min-height': '0',
        // Per-instance content body text override (font-size / weight /
        // letter-spacing / …) layered over the `body-medium` + on-surface
        // role classes ([contentTextEmit] inline).
        ...?contentTextEmit.inline,
      },
    ),
  );

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedCollapsible(
    root: buildRootChrome(),
    triggerRow: buildTriggerRowChrome(),
    triggerText: buildTriggerTextChrome(),
    iconLabelGapStyle: iconLabelGapStyle,
    chevron: buildChevronChrome(),
    content: buildContentChrome(),
    contentInner: buildContentInnerChrome(),
    iconStyle: iconStyle,
    clickableStyle: clickableStyle,
  );
}
