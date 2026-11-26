import 'package:coui_flutter/coui_flutter.dart';

/// Resolved styling values for [Collapsible] / [CollapsibleTrigger].
class ResolvedCollapsible {
  const ResolvedCollapsible({
    required this.contentInset,
    required this.iconLabelGapStyle,
    required this.duration,
    required this.iconStyle,
    required this.triggerTextStyle,
    required this.contentTextStyle,
    required this.clickableStyle,
  });

  /// Inner inset around the trigger and content.
  final EdgeInsets contentInset;

  /// Horizontal gap slot between trigger content and the chevron.
  /// Forwarded straight to `Gap(gapStyle: …)` — no manual
  /// `CoreGapStyle(size: …)` reconstruction in the widget body
  /// (Epic #1603 옵션 B nested-slot pattern).
  final CoreGapStyle iconLabelGapStyle;

  /// Animation duration for expand/collapse.
  final Duration duration;

  /// Nested [CoreIconStyle] slot — forwarded straight to
  /// `Icon(iconStyle: …)` for the chevron glyph. Carries the merged
  /// design-system default + per-instance override (raw, pre-scaling —
  /// the receiving `Icon` runs its own resolve/scaling step). The
  /// widget reads it directly, no inline `CoreIconStyle(...)` re-packaging
  /// (Epic #1603 옵션 B nested-slot pattern).
  final CoreIconStyle iconStyle;

  /// Paint-ready trigger-row [TextStyle] (typography role + on-surface
  /// colour + medium weight + per-instance `triggerTextStyle` overlay).
  /// The widget forwards it straight to `DefaultTextStyle.merge`, layering
  /// only the interaction-state hover underline on top (Web parity:
  /// `hover:underline`).
  final TextStyle triggerTextStyle;

  /// Paint-ready content body [TextStyle] (typography role + on-surface
  /// colour + per-instance `contentTextStyle` overlay). The widget
  /// forwards it straight to `DefaultTextStyle.merge` (no widget-side
  /// `copyWith`). Single static site, no state branch.
  final TextStyle contentTextStyle;

  /// Nested [CoreClickableStyle] slot for the composed trigger
  /// `Clickable` — `CoreCollapsibleStyle.defaultClickableStyle`
  /// (press-scale off) merged with the per-instance override,
  /// raw-forwarded to `Clickable(clickableStyle: …)`. The Clickable's
  /// own resolver fills the remaining chrome (focus-ring radius / colour
  /// / durations), so the trigger stops constructing an inline focus
  /// outline in the widget body (render-only).
  final CoreClickableStyle clickableStyle;
}

/// Resolves [ResolvedCollapsible] for [Collapsible].
///
/// Single entry point — applies the merge chain
/// (`CoreCollapsibleTheme.style` → `collapsibleStyle`) followed by
/// design-system default fallback. Stage1 RESOLVE + Stage2 EMIT run in
/// local vars; the `return` is a bare mapping (resolver-pattern.md
/// chaining position — return literal carries no `??` / `.merge` /
/// `.toValue` synthesis).
ResolvedCollapsible resolveCollapsible(
  BuildContext context, {
  CoreCollapsibleStyle? collapsibleStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final coreTheme = theme.coreComponentTheme?.collapsible;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreCollapsibleStyle(), [
    coreTheme?.style,
    collapsibleStyle,
  ]);

  // ─── Stage1 RESOLVE (Core values) ─────────────────────
  final contentInset =
      ((merged.contentInset ?? CoreCollapsibleStyle.defaultContentInset)
          .toValue(geometry: theme.geometry)) *
      scaling;
  // Nested icon slot — design-system default merged with the per-instance
  // override, raw-forwarded (no `* scaling`). The receiving `Icon` runs
  // its own resolve/scaling step (Epic #1603 nested-slot — `merged
  // .iconStyle` wins on each non-null field). Colour falls back to the
  // single-source named default only when the per-instance
  // `iconStyle.color` override is absent — matches Web's
  // `merged.iconStyle?.color ?? defaultIconColor` (previously this
  // never set a colour at all, leaving the chevron uncoloured on
  // Flutter while Web tinted its wrapper `onSurface`).
  // guard-nested-override: iconColor — reaches here via the nested
  // `iconStyle.color` sub-field rather than a bare top-level
  // reference. Web mirrors the same `merged.iconStyle?.color` path
  // (verified both platforms consult it).
  final iconStyle = CoreCollapsibleStyle.defaultIconStyle
      .merge(merged.iconStyle)
      .copyWith(
        color: merged.iconStyle?.color ?? CoreCollapsibleStyle.defaultIconColor,
      );
  // Nested gap slot — design-system default merged with the per-instance
  // override, raw-forwarded to `Gap(gapStyle: …)`.
  final iconLabelGapStyle = CoreCollapsibleStyle.defaultIconLabelGapStyle.merge(
    merged.iconLabelGapStyle,
  );
  // Nested Clickable slot — the press-scale-off partial default merged
  // with the per-instance override, raw-forwarded (the Clickable's own
  // resolver fills the rest, incl. the focus-ring radius).
  final clickableStyle = CoreCollapsibleStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );
  final duration = resolveMotionDuration(
    context,
    merged.duration ?? CoreCollapsibleStyle.defaultDuration,
  );
  // Typography Core values — design-system default merged with the
  // per-instance slot override (composite merge preserves the role +
  // colour when a caller overrides only a scalar).
  final triggerTextCore = CoreCollapsibleStyle.defaultTriggerTextStyle.merge(
    merged.triggerTextStyle,
  );
  final contentTextCore = CoreCollapsibleStyle.defaultContentTextStyle.merge(
    merged.contentTextStyle,
  );

  // ─── Stage2 EMIT (Flutter, theme-aware) ───────────────
  // `style.toValue(theme:)` materialises the typography role and resolves
  // the colour through the active scheme (dark-mode reactive). Single
  // primitive — no `applyCoreTextStyle` / `resolveTypographyRole` assembly.
  final triggerTextStyle = triggerTextCore.toValue(theme: theme);
  final contentTextStyle = contentTextCore.toValue(theme: theme);

  // ─── RETURN = bare mapping (+ dimensional * scaling) ──
  return ResolvedCollapsible(
    contentInset: contentInset,
    iconLabelGapStyle: iconLabelGapStyle,
    duration: duration,
    iconStyle: iconStyle,
    triggerTextStyle: triggerTextStyle,
    contentTextStyle: contentTextStyle,
    clickableStyle: clickableStyle,
  );
}
