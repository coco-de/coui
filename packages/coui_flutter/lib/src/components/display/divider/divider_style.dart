import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedDivider
// ═══════════════════════════════════════════════════

/// Resolver output for `Divider`.
class ResolvedDivider {
  /// Creates a [ResolvedDivider].
  const ResolvedDivider({
    required this.color,
    required this.thickness,
    required this.indent,
    required this.endIndent,
    required this.leadingFlex,
    required this.trailingFlex,
    required this.childPadding,
  });

  /// Line color.
  final Color color;

  /// Line thickness (already scaled).
  final double thickness;

  /// Leading indent (already scaled).
  final double indent;

  /// Trailing indent (already scaled).
  final double endIndent;

  /// Flex weight for the line segment before the centered child —
  /// `0` collapses that segment so the child sits at the reading start
  /// edge. Only consulted in child mode.
  final int leadingFlex;

  /// Flex weight for the line segment after the centered child —
  /// `0` collapses that segment so the child sits at the reading end
  /// edge. Only consulted in child mode.
  final int trailingFlex;

  /// Padding wrapped around the centered child — the widget applies
  /// this along the divider main axis only (orientation-aware).
  /// Paint-ready Flutter `EdgeInsets`, scaling pre-applied.
  final EdgeInsets childPadding;
}

// ═══════════════════════════════════════════════════
// Resolver
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedDivider] for the given [context].
ResolvedDivider resolveDivider(
  BuildContext context, {
  CoreDividerStyle? dividerStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final scheme = theme.colorScheme;
  final coreTheme = theme.coreComponentTheme?.divider;

  final merged = resolveStyleChain(const CoreDividerStyle(), [
    coreTheme?.style,
    dividerStyle,
  ]);

  // 기본 line colour 는 `CoreDividerStyle.defaultColor` (Core single
  // source — same token Web reads via `bg-${defaultColor}` Tailwind class).
  final effectiveColor = scheme
      .resolve(merged.color ?? CoreDividerStyle.defaultColor)
      .toValue();

  final thickness = theme.geometry.stroke(
    merged.thickness ?? CoreDividerStyle.defaultThickness,
    scaling: scaling,
  );

  // The indents are margins of the line — spacing, so the density moves
  // them with the padding of whatever the line sits in.
  final indent =
      theme.geometry.space(merged.indent ?? CoreDividerStyle.defaultIndent) *
      scaling;

  final endIndent =
      theme.geometry.space(
        merged.endIndent ?? CoreDividerStyle.defaultEndIndent,
      ) *
      scaling;

  final childPadding =
      ((merged.childPadding ?? CoreDividerStyle.defaultChildPadding).toValue(
        geometry: theme.geometry,
      )) *
      scaling;

  // The alignment's two weights come off the Core enum rather than a
  // switch here, so Flutter and Web cannot disagree about which
  // segment collapses. `center` yields 1/1 — the same distribution a
  // bare `Flexible` already had, which is why the default render is
  // untouched.
  final childAlignment =
      merged.childAlignment ?? CoreDividerStyle.defaultChildAlignment;

  return ResolvedDivider(
    color: effectiveColor,
    thickness: thickness,
    indent: indent,
    endIndent: endIndent,
    leadingFlex: childAlignment.leadingFlex,
    trailingFlex: childAlignment.trailingFlex,
    childPadding: childPadding,
  );
}
