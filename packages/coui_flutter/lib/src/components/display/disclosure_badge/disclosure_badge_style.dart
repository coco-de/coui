import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `DisclosureBadge`.
///
/// Widget tree (`disclosure_badge.dart` builds):
///
/// ```text
/// DecoratedBox (solid)  |  CustomPaint (dashed)
///   └─ Padding (borderWidth + padding)
///        └─ Row (mainAxisSize.min, spacing: markerSpacing)
///             ├─ marker    // only when kind.hasMarker
///             │              markerSize · markerRadius · foregroundColor
///             └─ Text      // labelTextStyle
/// ```
///
/// Carries paint-ready values only — the widget never spells out a
/// fallback chain inline, and never multiplies by `theme.scaling` again.
///
/// There is no `backgroundColor` field, and the absence is the component:
/// a fill is what makes a `Chip` read as a pressable control, and this
/// badge is a claim about whether a document opens, not a control.
/// [CoreDisclosureBadgeStyle] has no slot to add one through either, so
/// there is nothing here to resolve.
class ResolvedDisclosureBadge {
  /// Creates a [ResolvedDisclosureBadge].
  const ResolvedDisclosureBadge({
    required this.foregroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.borderRadius,
    required this.padding,
    required this.labelTextStyle,
    required this.markerSize,
    required this.markerRadius,
    required this.markerSpacing,
    required this.dashLength,
    required this.dashGap,
  });

  /// Label and marker colour.
  ///
  /// One value feeds both, so a single `foregroundColor` override keeps
  /// the dot and the word in step — the same routing the Web resolver
  /// does by sending the resolved foreground to `color` and to the dot's
  /// `background`.
  final Color foregroundColor;

  /// Outline stroke colour.
  final Color borderColor;

  /// Outline stroke width (logical px, `theme.scaling` and the surface
  /// style's stroke floor pre-applied).
  final double borderWidth;

  /// Corner radius (paint-ready, scaling pre-applied).
  final BorderRadius borderRadius;

  /// Padding around the badge content (paint-ready, scaling pre-applied).
  ///
  /// The stroke is *not* included: `DecoratedBox` and `CustomPaint` both
  /// paint on the box edge without insetting their child, so the widget
  /// reserves [borderWidth] on top of this. Keeping the two separate is
  /// what lets one number stay the caller's padding.
  final EdgeInsets padding;

  /// Paint-ready label typography — the `label-small` role in the kind's
  /// foreground, with any theme / per-instance overlay merged in.
  final TextStyle labelTextStyle;

  /// Diameter of the deferral marker dot (logical px, scaling
  /// pre-applied). Only consumed when
  /// [CoreDisclosureKind.hasMarker] is `true`.
  final double markerSize;

  /// Marker corner radius (paint-ready) — a full circle by default.
  final BorderRadius markerRadius;

  /// Gap between the marker dot and the label (logical px, scaling
  /// pre-applied).
  final double markerSpacing;

  /// Length of one dash on the [CoreDisclosureStroke.dashed] outline
  /// (logical px, scaling pre-applied).
  ///
  /// Not a style slot, and deliberately so: [CoreDisclosureKind] owns the
  /// stroke pattern precisely so no theme can flatten the three kinds
  /// into colour (WCAG 1.4.1), and a dash length a project could set to
  /// the full perimeter would erase the same distinction through the back
  /// door. The value comes from the shared [CoreDashedBorder], which is
  /// also what the Web twin's `border-dashed` was measured against, so
  /// the two platforms break the line the same way.
  final double dashLength;

  /// Gap between two dashes (logical px, scaling pre-applied). See
  /// [dashLength] for why this is not themeable.
  final double dashGap;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedDisclosureBadge] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default for kind
///   → CoreDisclosureBadgeTheme.style              // 프로젝트 공통
///   → CoreDisclosureBadgeTheme.kindStyles[kind]
///   → widget.disclosureBadgeStyle                 // 인스턴스별
/// ```
///
/// [kind] is a widget prop that threads through to pick the per-kind
/// colour table; the theme cannot override it, because a theme that could
/// would let a project silently restate every "비공개" as "공개".
///
/// What it picks up from the kind is colour only. The stroke pattern and
/// the marker dot stay on [CoreDisclosureKind] and are read by the widget
/// straight off the enum, so nothing in this chain — theme or instance —
/// can collapse the three kinds into one shape.
ResolvedDisclosureBadge resolveDisclosureBadge(
  BuildContext context, {
  required CoreDisclosureKind kind,
  CoreDisclosureBadgeStyle? disclosureBadgeStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final badgeTheme = theme.coreComponentTheme?.disclosureBadge;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreDisclosureBadgeStyle(), [
    badgeTheme?.style,
    badgeTheme?.kindStyles?[kind],
    disclosureBadgeStyle,
  ]);

  // ─── Token table ──────────────────────────────────────
  final kindStyle = CoreDisclosureBadgeStyle.defaultsByKind[kind]!;

  // ─── Colour resolution ────────────────────────────────
  // Through `scheme.resolve` rather than a bare `toValue()`, so a token
  // tracks the active scheme instead of freezing at its light value —
  // and `private` keeps landing on `on-surface-variant` / `outline` in
  // dark mode rather than drifting toward the primary family the way a
  // frozen colour would look next to a re-themed `open`.
  final foregroundColor = scheme
      .resolve(merged.foregroundColor ?? kindStyle.foreground)
      .toValue();
  final borderColor = scheme
      .resolve(merged.borderColor ?? kindStyle.borderColor)
      .toValue();

  // ─── Dimensional fallback ─────────────────────────────
  final borderWidth = theme.geometry.stroke(
    merged.borderWidth ?? CoreDisclosureBadgeStyle.defaultBorderWidth,
    scaling: scaling,
  );
  final borderRadius =
      ((merged.borderRadius ?? CoreDisclosureBadgeStyle.defaultBorderRadius)
          .toValue(geometry: theme.geometry)) *
      scaling;
  final padding =
      ((merged.padding ?? CoreDisclosureBadgeStyle.defaultPadding).toValue(
        geometry: theme.geometry,
      )) *
      scaling;
  final markerSize =
      (merged.markerSize ?? CoreDisclosureBadgeStyle.defaultMarkerSize) *
      scaling;
  final markerRadius =
      ((merged.markerRadius ?? CoreDisclosureBadgeStyle.defaultMarkerRadius)
          .toValue(geometry: theme.geometry)) *
      scaling;
  final markerSpacing =
      theme.geometry.space(
        merged.markerSpacing ?? CoreDisclosureBadgeStyle.defaultMarkerSpacing,
      ) *
      scaling;

  // ─── Label typography (EMIT Stage 2, Flutter) ─────────
  // The design-system default is a typography-role token, so it is merged
  // with any overlay first and materialised in one `.toValue(theme:)`
  // call. Merging (rather than `??`) keeps an override of one typographic
  // field from dropping the rest of the role. The `color:` override
  // forces the kind's foreground only when the caller's `labelStyle`
  // states no colour of its own.
  final labelTextStyle = CoreDisclosureBadgeStyle.defaultLabelStyle
      .merge(merged.labelStyle)
      .toValue(
        color: merged.labelStyle?.color == null ? foregroundColor : null,
        theme: theme,
      );

  return ResolvedDisclosureBadge(
    foregroundColor: foregroundColor,
    borderColor: borderColor,
    borderWidth: borderWidth,
    borderRadius: borderRadius,
    padding: padding,
    labelTextStyle: labelTextStyle,
    markerSize: markerSize,
    markerRadius: markerRadius,
    markerSpacing: markerSpacing,
    dashLength: CoreDashedBorder.dashLength * scaling,
    dashGap: CoreDashedBorder.dashGap * scaling,
  );
}
