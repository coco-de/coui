library;

import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved output — Gap
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `Gap`.
///
/// Widget tree:
///
/// ```text
/// _RawGap (LeafRenderObjectWidget)
///   └─ RenderGap (mainAxisExtent / crossAxisExtent / color)
/// ```
///
/// All values are already merged + fallback-filled by [resolveGap]
/// so `co_gap.dart` is render-only.
class ResolvedGap {
  /// Creates a [ResolvedGap].
  const ResolvedGap({
    required this.size,
    required this.crossAxisExtent,
    required this.color,
  });

  /// Gap size (logical px) along the parent's main axis — the authored
  /// size moved by the theme density, then scaled.
  final double size;

  /// Gap size (logical px) along the parent's cross axis. `null`
  /// stretches to the parent's cross constraint.
  final double? crossAxisExtent;

  /// Fill colour painted across the gap rectangle.
  final Color? color;
}

// ═══════════════════════════════════════════════════
// Resolved output — MaxGap
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `MaxGap`.
class ResolvedMaxGap {
  /// Creates a [ResolvedMaxGap].
  const ResolvedMaxGap({
    required this.size,
    required this.crossAxisExtent,
    required this.color,
  });

  /// Maximum gap size (logical px) along the parent's main axis. The
  /// widget wraps the underlying `RenderGap` in `Flexible(fit: loose)`
  /// so the actual painted extent is capped at this value but can be
  /// smaller when the parent runs out of space.
  final double size;

  /// Gap size (logical px) along the parent's cross axis.
  final double? crossAxisExtent;

  /// Fill colour painted across the gap rectangle.
  final Color? color;
}

// ═══════════════════════════════════════════════════
// Resolved output — SliverGap
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `SliverGap`.
class ResolvedSliverGap {
  /// Creates a [ResolvedSliverGap].
  const ResolvedSliverGap({required this.size, required this.color});

  /// Sliver main-axis extent (logical px).
  final double size;

  /// Fill colour.
  final Color? color;
}

// ═══════════════════════════════════════════════════
// Resolver — Gap entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedGap] for [Gap].
///
/// Merge chain:
///
/// ```text
/// design-system default (CoreGapStyle.defaultSize)
///   → theme.coreComponentTheme.gap.style
///   → widget.gapStyle
/// ```
ResolvedGap resolveGap(BuildContext context, {CoreGapStyle? gapStyle}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final coreTheme = theme.coreComponentTheme?.gap;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreGapStyle(), [
    coreTheme?.style,
    gapStyle,
  ]);

  // The fill colour is resolved against the active scheme so semantic
  // tokens (e.g. `CoreColors.surface`) pick the right light/dark value
  // before `.toValue()` (Epic #1603 C7 color-path — no standalone
  // `merged.color.toValue()`).
  final color = merged.color == null
      ? null
      : scheme.resolve(merged.color!).toValue();

  // The main-axis size is spacing: the theme density moves it one rung on
  // the spacing scale (`theme.geometry.space`) before the size factor,
  // because the density says where on the scale a value sits and the
  // factor how many pixels that covers. The cross axis is the extent of
  // the painted rectangle, not spacing, so only the factor reaches it.
  //
  // `* scaling` is Stage2 EMIT — it lives in the local so the return is
  // a bare mapping (the nullable cross-axis scales inside its null-check).
  final size =
      theme.geometry.space(merged.size ?? CoreGapStyle.defaultSize) * scaling;
  final crossAxisExtent = merged.crossAxisExtent == null
      ? null
      : merged.crossAxisExtent! * scaling;

  return ResolvedGap(
    size: size,
    crossAxisExtent: crossAxisExtent,
    color: color,
  );
}

// ═══════════════════════════════════════════════════
// Resolver — MaxGap entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedMaxGap] for [MaxGap].
///
/// Merge chain:
///
/// ```text
/// design-system default (CoreGapStyle.defaultSize)
///   → theme.coreComponentTheme.maxGap.style
///   → widget.gapStyle
/// ```
ResolvedMaxGap resolveMaxGap(
  BuildContext context, {
  CoreGapStyle? gapStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final coreTheme = theme.coreComponentTheme?.maxGap;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreGapStyle(), [
    coreTheme?.style,
    gapStyle,
  ]);

  // Scheme-resolved fill colour (Epic #1603 C7 color-path).
  final color = merged.color == null
      ? null
      : scheme.resolve(merged.color!).toValue();

  // The main-axis size is spacing: the theme density moves it one rung on
  // the spacing scale (`theme.geometry.space`) before the size factor,
  // because the density says where on the scale a value sits and the
  // factor how many pixels that covers. The cross axis is the extent of
  // the painted rectangle, not spacing, so only the factor reaches it.
  //
  // `* scaling` is Stage2 EMIT — it lives in the local so the return is
  // a bare mapping (the nullable cross-axis scales inside its null-check).
  final size =
      theme.geometry.space(merged.size ?? CoreGapStyle.defaultSize) * scaling;
  final crossAxisExtent = merged.crossAxisExtent == null
      ? null
      : merged.crossAxisExtent! * scaling;

  return ResolvedMaxGap(
    size: size,
    crossAxisExtent: crossAxisExtent,
    color: color,
  );
}

// ═══════════════════════════════════════════════════
// Resolver — SliverGap entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedSliverGap] for [SliverGap].
///
/// Merge chain:
///
/// ```text
/// design-system default (CoreGapStyle.defaultSize)
///   → theme.coreComponentTheme.sliverGap.style
///   → widget.gapStyle
/// ```
///
/// `CoreGapStyle.crossAxisExtent` is intentionally ignored — the
/// sliver protocol decides the cross axis from the surrounding
/// `CustomScrollView` constraints.
ResolvedSliverGap resolveSliverGap(
  BuildContext context, {
  CoreGapStyle? gapStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final coreTheme = theme.coreComponentTheme?.sliverGap;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreGapStyle(), [
    coreTheme?.style,
    gapStyle,
  ]);

  // Scheme-resolved fill colour (Epic #1603 C7 color-path).
  final color = merged.color == null
      ? null
      : scheme.resolve(merged.color!).toValue();

  // The theme density's rung, then the size factor — see [resolveGap].
  // `* scaling` is Stage2 EMIT — it lives in the local so the return is
  // a bare mapping.
  final size =
      theme.geometry.space(merged.size ?? CoreGapStyle.defaultSize) * scaling;

  return ResolvedSliverGap(size: size, color: color);
}
