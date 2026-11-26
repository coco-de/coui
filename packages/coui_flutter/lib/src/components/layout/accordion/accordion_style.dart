import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedAccordion
// ═══════════════════════════════════════════════════

/// Resolved styling values for [Accordion] / [AccordionItem] /
/// [AccordionTrigger].
///
/// Single struct that the widgets read — every field has had the
/// nested-merge chain applied plus design-system default fallback and
/// type conversion:
///
/// ```text
/// CoreAccordionStyle.defaultX
///   → CoreAccordionTheme.style
///   → widget.accordionStyle
/// ```
class ResolvedAccordion {
  /// Creates a [ResolvedAccordion].
  const ResolvedAccordion({
    required this.merged,
    required this.triggerPadding,
    required this.contentPadding,
    required this.iconGapStyle,
    required this.duration,
    required this.chevronIconStyle,
    required this.labelTextStyle,
    required this.labelColor,
    required this.contentTextStyle,
    required this.containerStyle,
    required this.itemSpacing,
    required this.dividerColor,
    required this.dividerThickness,
    required this.clickableStyle,
    this.triggerBackgroundColor,
  });

  /// The merged platform-neutral style — propagated down to descendants
  /// so child items / triggers resolve from the same chain.
  final CoreAccordionStyle merged;

  /// Effective trigger row padding (paint-ready EdgeInsets, scaling applied).
  final EdgeInsets triggerPadding;

  /// Fill painted behind the trigger row — `triggerStyle.backgroundColor`,
  /// resolved. `null` when the caller states none: the row then paints
  /// nothing, the same as Web, which emits no background for it.
  final Color? triggerBackgroundColor;

  /// Padding applied around the expanded content.
  final EdgeInsets contentPadding;

  /// 1-off spacer between the trigger label and the chevron icon —
  /// raw-forwarded `CoreGapStyle` slot (no scaling applied here; the
  /// `Gap` resolver scales it). Consumed by `co_accordion` via
  /// `Gap(gapStyle: …)`.
  final CoreGapStyle iconGapStyle;

  /// Animation duration for expand/collapse.
  final Duration duration;

  /// Paint-ready chevron / disclosure icon style — the resolved default
  /// size / colour pre-merged with the per-instance `arrowIconStyle` /
  /// `chevronIconStyle` override. Forwarded to `Icon(iconStyle: …)` by
  /// `co_accordion` so the chevron sizes / colours from a single source
  /// of truth (no raw scalar leak, no widget-side construct + merge).
  final CoreIconStyle chevronIconStyle;

  /// Paint-ready trigger label text style — the `bodyMedium` typography
  /// role (medium weight, `onSurface` colour) pre-merged with the
  /// per-instance `triggerStyle.labelStyle` override and materialised
  /// against the active theme. Forwarded to `DefaultTextStyle.merge`
  /// by `co_accordion` (which toggles the hover underline `decoration`
  /// on top) so the trigger typography composes from a single source of
  /// truth (no widget-side `theme.typography.bodyMedium.copyWith(...)`).
  final TextStyle labelTextStyle;

  /// Resolved trigger label text colour — the same colour baked into
  /// [labelTextStyle]. Forwarded so `co_accordion` can drive the hover
  /// underline `decorationColor` to match the label.
  final Color labelColor;

  /// Paint-ready expanded content text style — the `bodySmall`
  /// typography role plus the resolved [contentColor], pre-merged with
  /// the per-instance `contentTextStyle` override (`fontSize` /
  /// `fontWeight` / `letterSpacing` / `lineHeight`). Forwarded to
  /// `DefaultTextStyle.merge(style: …)` by `co_accordion` so the
  /// expanded content typography composes from a single source of truth
  /// (no widget-side `theme.typography.bodySmall.copyWith(...)`).
  final TextStyle contentTextStyle;

  /// Composed-`OutlinedContainer` chrome for the accordion panel box
  /// (pre-EMIT `CoreOutlinedContainerStyle`). `OutlinedContainer` runs
  /// the scheme-resolve / geometry / scaling bend itself — carrying Core
  /// values (not resolved Flutter ones) is what keeps that bend applied
  /// exactly once.
  ///
  /// `backgroundColor` / `borderColor` / `borderRadius` have **no
  /// design-system default** on `CoreAccordionStyle` (see that class's
  /// field docs) — an accordion with no caller override draws no box at
  /// all, only the between-items divider. Forcing the transparent
  /// sentinel / zero radius here (rather than leaving them null) is what
  /// keeps `OutlinedContainer`'s own defaults (an opaque `surface` fill,
  /// a 16px radius) from leaking in.
  ///
  /// `surfaceBlur` / `boxShadow` are forced off whenever there is no
  /// fill — this component never painted a cast of its own (unlike
  /// `Fieldset`, it has no `InjectedCast` to preserve), so the safe
  /// default under an unfilled box is none rather than
  /// `OutlinedContainer`'s own `controlShadow` fallback bleeding through
  /// a fill that does not cover it.
  final CoreOutlinedContainerStyle containerStyle;

  /// Vertical spacing between accordion items (logical px, density and
  /// `theme.scaling` pre-applied) — forwarded to `Column.spacing`
  /// (`null` = use divider line instead).
  final double? itemSpacing;

  /// Divider line colour between items (`null` = default separator).
  final Color? dividerColor;

  /// Divider line thickness (`null` = default separator).
  final double? dividerThickness;

  /// Nested [CoreClickableStyle] slot for the composed trigger
  /// `Clickable` — `CoreAccordionStyle.defaultClickableStyle` merged
  /// with the per-instance override, raw-forwarded to
  /// `Clickable(clickableStyle: …)`. The Clickable owns the trigger's
  /// tap / keyboard activation / cursor / press feedback / focus ring
  /// (the ring corner comes from this slot's nested `focusOutlineStyle`).
  final CoreClickableStyle clickableStyle;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResolvedAccordion &&
          runtimeType == other.runtimeType &&
          merged == other.merged &&
          triggerPadding == other.triggerPadding &&
          triggerBackgroundColor == other.triggerBackgroundColor &&
          contentPadding == other.contentPadding &&
          iconGapStyle == other.iconGapStyle &&
          duration == other.duration &&
          chevronIconStyle == other.chevronIconStyle &&
          labelTextStyle == other.labelTextStyle &&
          labelColor == other.labelColor &&
          contentTextStyle == other.contentTextStyle &&
          containerStyle == other.containerStyle &&
          itemSpacing == other.itemSpacing &&
          dividerColor == other.dividerColor &&
          dividerThickness == other.dividerThickness &&
          clickableStyle == other.clickableStyle;

  @override
  int get hashCode => Object.hash(
    merged,
    triggerPadding,
    triggerBackgroundColor,
    contentPadding,
    iconGapStyle,
    duration,
    chevronIconStyle,
    labelTextStyle,
    labelColor,
    contentTextStyle,
    containerStyle,
    itemSpacing,
    dividerColor,
    dividerThickness,
    clickableStyle,
  );
}

// ═══════════════════════════════════════════════════
// resolveAccordion — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedAccordion] for the given [context].
///
/// Single entry point for the accordion Style slot — applies the
/// three-stage merge chain (`CoreAccordionTheme.style` →
/// `accordionStyle`) followed by design-system default fallback.
ResolvedAccordion resolveAccordion(
  BuildContext context, {
  CoreAccordionStyle? accordionStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final coreTheme = theme.coreComponentTheme?.accordion;

  // ─── Stage 1 RESOLVE — merge chain + default fallback (local vars) ──
  final merged = resolveStyleChain(const CoreAccordionStyle(), [
    coreTheme?.style,
    accordionStyle,
  ]);

  // Trigger row chrome — design-system default (padding) merged with the
  // per-instance override (composite merge preserves partial overrides).
  final triggerStyle = CoreAccordionStyle.defaultTriggerStyle.merge(
    merged.triggerStyle,
  );
  // `defaultTriggerStyle` always supplies padding so the merged slot's
  // `padding` is non-null.
  final triggerPaddingInsets = triggerStyle.padding!;
  final contentPaddingInsets =
      merged.contentPadding ?? CoreAccordionStyle.defaultContentPadding;
  // 1-off label↔chevron spacer — raw-forward the merged `CoreGapStyle`
  // slot (no `* scaling`; `Gap`'s own resolver scales it).
  final iconGapStyle =
      merged.iconGapStyle ?? CoreAccordionStyle.defaultIconGapStyle;
  final duration = resolveMotionDuration(
    context,
    merged.duration ?? CoreAccordionStyle.defaultDuration,
  );
  final arrowIconSize =
      merged.arrowIconStyle?.size ??
      merged.chevronIconStyle?.size ??
      CoreAccordionStyle.defaultChevronIconStyle.size!;

  // Pre-merge the resolved default size / colour UNDER the per-instance
  // `chevronIconStyle` override so the widget consumes a single
  // paint-ready slot (no inline `CoreIconStyle(...)` reconstruction). The
  // colour stays a `CoreColor` token — the chevron override (re-applied
  // by the merge) else the `onSurface` default — so `Icon` resolves it
  // itself (no resolve→re-wrap round-trip, no `theme.colorScheme` leak).
  final chevronIconStyle = CoreAccordionStyle.defaultChevronIconStyle
      .copyWith(size: arrowIconSize)
      .merge(merged.chevronIconStyle);

  // Trigger label typography — design-system default role (`bodyMedium`,
  // medium weight, `onSurface`) merged with the per-instance
  // `triggerStyle.labelStyle` overlay. The label colour precedence is
  // `labelStyle.color → foregroundColor → default onSurface`; the
  // `foregroundColor` override (when no explicit label colour) is fed as
  // the `color:` argument so it wins over the default.
  // guard-nested-override: labelTextStyle — reaches here via the
  // nested `triggerStyle.labelStyle` sub-field (itself sourced from
  // `merged.triggerStyle`) rather than a bare top-level reference.
  // Web mirrors the same nested path (verified both platforms
  // consult it).
  final labelCore = CoreAccordionStyle.defaultLabelTextStyle.merge(
    triggerStyle.labelStyle,
  );
  final foregroundOverride = triggerStyle.labelStyle?.color == null
      ? triggerStyle.foregroundColor
      : null;
  // Single-source label colour token — the `foregroundColor` override (when
  // no explicit label colour) else the merged label-style colour (which
  // falls back to `defaultLabelTextStyle`'s `onSurface`). Resolved against
  // the active scheme to drive the hover underline `decorationColor` without
  // a `theme.colorScheme.onSurface` leak.
  final labelColorCore = foregroundOverride ?? labelCore.color;
  final contentCore = CoreAccordionStyle.defaultContentTextStyle.merge(
    merged.contentTextStyle,
  );

  // Nested Clickable slot — partial default (pressedScale off + focus-ring
  // corner) merged with the per-instance override, raw-forwarded (the
  // Clickable's own resolver fills the rest). The Clickable owns the
  // trigger's tap / keyboard activation / cursor / press feedback / focus
  // ring.
  final clickableStyle = CoreAccordionStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );

  // ─── Stage 2 EMIT — paint-ready Flutter types (local vars) ─────────
  final triggerPadding =
      (triggerPaddingInsets.toValue(geometry: theme.geometry)) * scaling;
  final contentPadding =
      (contentPaddingInsets.toValue(geometry: theme.geometry)) * scaling;
  final labelTextStyle = labelCore.toValue(
    color: foregroundOverride == null
        ? null
        : scheme.resolve(foregroundOverride).toValue(),
    theme: theme,
  );
  final labelColor =
      labelTextStyle.color ?? scheme.resolve(labelColorCore!).toValue();
  final contentTextStyle = contentCore.toValue(theme: theme);
  final dividerColor = merged.dividerColor == null
      ? null
      : scheme.resolve(merged.dividerColor!).toValue();
  // Trigger fill — caller-only (no design-system default), the same value
  // the Web resolver paints behind the trigger row.
  final triggerBackgroundColor = triggerStyle.backgroundColor == null
      ? null
      : scheme.resolve(triggerStyle.backgroundColor!).toValue();
  // Spacing between items: the density's rung, then the size factor.
  final itemSpacing = merged.itemSpacing == null
      ? null
      : theme.geometry.space(merged.itemSpacing!) * scaling;

  // ─── Composed `OutlinedContainer` chrome — pre-EMIT ────────────────
  // The accordion panel is the box `Card` / `Fieldset` compose, not a
  // hand-rolled decoration (Epic #4349) — passing Core values (not
  // resolved ones) keeps the scheme-resolve / geometry / scaling bend
  // applied exactly once, by `OutlinedContainer` itself.
  final backgroundToken = merged.backgroundColor ?? .transparent;
  final hasFill = backgroundToken.token != null || backgroundToken.argb != 0;
  final containerStyle = CoreOutlinedContainerStyle(
    backgroundColor: backgroundToken,
    borderColor: merged.borderColor,
    borderRadius: merged.borderRadius ?? .zero,
    borderWidth: merged.borderWidth ?? CoreAccordionStyle.defaultBorderWidth,
    boxShadow: hasFill ? null : const [],
    surfaceBlur: hasFill ? null : 0,
  );

  // ─── RETURN — bare mapping (+ dimensional `* scaling`) ─────────────
  return ResolvedAccordion(
    merged: merged,
    triggerPadding: triggerPadding,
    triggerBackgroundColor: triggerBackgroundColor,
    contentPadding: contentPadding,
    iconGapStyle: iconGapStyle,
    duration: duration,
    chevronIconStyle: chevronIconStyle,
    labelTextStyle: labelTextStyle,
    labelColor: labelColor,
    contentTextStyle: contentTextStyle,
    containerStyle: containerStyle,
    itemSpacing: itemSpacing,
    dividerColor: dividerColor,
    dividerThickness: merged.dividerThickness,
    clickableStyle: clickableStyle,
  );
}
