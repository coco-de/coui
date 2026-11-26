import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/src/components/layout/breakpoint/breakpoint_style.dart';
import 'package:coui_flutter/src/components/layout/frame/frame_style.dart'
    show coreCrossAxisAlignmentToFlutter, coreMainAxisAlignmentToFlutter;
import 'package:coui_flutter/src/theme/theme.dart';
import 'package:flutter/widgets.dart';

/// Resolved configuration for `ResponsiveRowColumn`, computed from the
/// resolve-priority chain
/// `widget parameter > CoreComponentTheme.responsiveRowColumn > defaults`
/// plus the ambient viewport breakpoint tier.
///
/// ```text
/// ResponsiveRowColumn (Flex(direction: ...))
///   ├─ direction           → Flex.direction               (Axis, tier-derived select)
///   ├─ spacing             → Flex.spacing                  (paint-ready double, N-sibling)
///   ├─ mainAxisAlignment   → Flex.mainAxisAlignment        (paint-ready enum)
///   └─ crossAxisAlignment  → Flex.crossAxisAlignment       (paint-ready enum)
/// ```
class ResolvedResponsiveRowColumn {
  /// Creates a [ResolvedResponsiveRowColumn].
  const ResolvedResponsiveRowColumn({
    required this.direction,
    required this.spacing,
    required this.mainAxisAlignment,
    required this.crossAxisAlignment,
  });

  /// The flex direction to render — `Axis.horizontal` (`Row`) at or
  /// above `switchAt`, `Axis.vertical` (`Column`) below it.
  final Axis direction;

  /// Paint-ready spacing between children, already multiplied by
  /// `theme.scaling`. Fed straight into `Flex.spacing`.
  final double spacing;

  /// Paint-ready main-axis alignment.
  final MainAxisAlignment mainAxisAlignment;

  /// Paint-ready cross-axis alignment.
  final CrossAxisAlignment crossAxisAlignment;
}

/// Resolves [ResolvedResponsiveRowColumn] from widget inputs, the
/// shared [CoreResponsiveRowColumnTheme], defaults, and the ambient
/// viewport breakpoint tier.
///
/// Direction is derived from [resolveBreakpoint] — the single shared
/// tier-observation entry point (`Breakpoint`/`resolveBreakpoint`,
/// Story B) — never a new `LayoutBuilder`/measurement of its own
/// (`single-source-of-truth.md`).
ResolvedResponsiveRowColumn resolveResponsiveRowColumn(
  BuildContext context, {
  required CoreBreakpointTier? switchAt,
  CoreResponsiveRowColumnStyle? responsiveRowColumnStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final themeStyle = theme.coreComponentTheme?.responsiveRowColumn?.style;

  final merged = resolveStyleChain(const CoreResponsiveRowColumnStyle(), [
    themeStyle,
    responsiveRowColumnStyle,
  ]);

  // ─── Stage1 RESOLVE (local var) ────────────────────────
  final effectiveSwitchAt =
      switchAt ?? CoreResponsiveRowColumnContract.defaultSwitchAt;
  final currentTier = resolveBreakpoint(context).tier;
  final direction = currentTier.isAtLeast(effectiveSwitchAt)
      ? Axis.horizontal
      : Axis.vertical;

  final spacingValue =
      merged.spacing ?? CoreResponsiveRowColumnStyle.defaultSpacing;
  final coreMainAxisAlignment =
      merged.mainAxisAlignment ??
      CoreResponsiveRowColumnStyle.defaultMainAxisAlignment;
  final coreCrossAxisAlignment =
      merged.crossAxisAlignment ??
      CoreResponsiveRowColumnStyle.defaultCrossAxisAlignment;

  // ─── Stage2 EMIT (local var) ───────────────────────────
  final spacing = theme.geometry.space(spacingValue) * scaling;
  final mainAxisAlignment = coreMainAxisAlignmentToFlutter(
    coreMainAxisAlignment,
  );
  final crossAxisAlignment = coreCrossAxisAlignmentToFlutter(
    coreCrossAxisAlignment,
  );

  // ─── RETURN = bare mapping ──────────────────────────────
  return ResolvedResponsiveRowColumn(
    direction: direction,
    spacing: spacing,
    mainAxisAlignment: mainAxisAlignment,
    crossAxisAlignment: crossAxisAlignment,
  );
}
