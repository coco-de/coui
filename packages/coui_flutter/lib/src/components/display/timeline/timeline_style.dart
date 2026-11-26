import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `Timeline`.
///
/// Widget tree (`co_timeline.dart` decides which optional branches
/// render):
///
/// ```text
/// Column (spacing = rowSpacing)                      // native `Column.spacing` paint-API
///   └─ IntrinsicHeight × items.length
///        └─ Row (crossAxisAlignment.stretch)
///             ├─ ConstrainedBox (timeColumnConstraints)
///             │    └─ Align (topRight)
///             │         └─ Text (timestamp, timestampTextStyle)   // rendered only when timestamp != null
///             ├─ Gap (columnGapStyle)
///             ├─ Column (dot + connector)
///             │    ├─ Container (dotDecoration / dotSize / dotTopMargin)
///             │    └─ Expanded > SizedBox > CustomPaint            // rendered only when not last
///             │         (connectorColor / connectorThickness /
///             │          connectorSpacing / connectorReach)
///             ├─ Gap (columnGapStyle)
///             └─ Expanded > Column
///                  ├─ Padding (titlePadding)
///                  │    └─ Text (title, titleTextStyle)
///                  ├─ Gap (contentTopGapStyle)                   // rendered only when description != null
///                  └─ Expanded > Text (description, descriptionTextStyle)
///                                                                  // rendered only when description != null
/// ```
///
/// Field grouping:
///
/// 1. **Layout values** — [rowSpacing] / [dotSize] /
///    [timeColumnConstraints] / [dotTopMargin] / [titlePadding] /
///    [connectorThickness] / [connectorSpacing] / [connectorReach] (scaling
///    pre-applied) consumed by `Column.spacing` / `Container` /
///    `Padding` / the connector painter.
/// 2. **Nested gap slots** — [columnGapStyle] / [contentTopGapStyle]
///    forwarded raw to `Gap(gapStyle: …)` (Gap self-scales).
/// 3. **Paint-ready typography** — [timestampTextStyle] /
///    [titleTextStyle] / [descriptionTextStyle] composed once.
/// 4. **Dot chrome** — [dotDecoration] is a paint-ready
///    [BoxDecoration] (fill + optional border + shape).
/// 5. **Connector chrome** — [connectorColor] resolved Flutter
///    [Color], handed to the connector painter that draws the line from
///    [connectorSpacing] below its dot to [connectorReach] past its row.
class ResolvedTimeline {
  /// Creates a [ResolvedTimeline].
  const ResolvedTimeline({
    required this.rowSpacing,
    required this.columnGapStyle,
    required this.dotSize,
    required this.dotDecoration,
    required this.dotTopMargin,
    required this.connectorColor,
    required this.connectorThickness,
    required this.connectorSpacing,
    required this.connectorReach,
    required this.timeColumnConstraints,
    required this.titlePadding,
    required this.contentTopGapStyle,
    required this.timestampTextStyle,
    required this.titleTextStyle,
    required this.descriptionTextStyle,
  });

  /// Vertical spacing between adjacent timeline rows (scaling
  /// pre-applied). Consumed by the native `Column.spacing` paint-API
  /// (Epic #1659 N-sibling uniform distribution pattern).
  final double rowSpacing;

  /// Nested [CoreGapStyle] for the horizontal gap between the
  /// timestamp / dot / content columns — forwarded straight to
  /// `Gap(gapStyle: …)` (Gap self-scales).
  final CoreGapStyle columnGapStyle;

  /// Effective dot indicator diameter (scaling pre-applied).
  final double dotSize;

  /// Paint-ready [BoxDecoration] for the dot — background colour +
  /// optional border + shape (rectangle vs circle from the resolved
  /// dot corner radius).
  final BoxDecoration dotDecoration;

  /// Top margin of the dot so its centre meets the centre of the title's
  /// first line (scaling pre-applied).
  final double dotTopMargin;

  /// Resolved connector line colour.
  final Color connectorColor;

  /// Effective connector line thickness (scaling pre-applied).
  final double connectorThickness;

  /// Gap between the connector and the dot at each of its ends
  /// (scaling pre-applied): the line starts this far below its own dot.
  final double connectorSpacing;

  /// How far the connector runs on past the bottom of its row (scaling
  /// pre-applied): across the row spacing and down to the next item's
  /// dot, stopping [connectorSpacing] short of it. Painted, not laid out,
  /// so the row's own height is unaffected.
  final double connectorReach;

  /// Fixed-width constraints for the timestamp column (scaling
  /// pre-applied).
  final BoxConstraints timeColumnConstraints;

  /// Padding of the item title (paint-ready Flutter `EdgeInsetsGeometry`,
  /// scaling pre-applied). Zero by default; a directional caller value
  /// stays directional and resolves against the ambient text direction.
  final EdgeInsetsGeometry titlePadding;

  /// Nested [CoreGapStyle] for the vertical gap between the title and
  /// the description — forwarded straight to `Gap(gapStyle: …)`
  /// (Gap self-scales).
  final CoreGapStyle contentTopGapStyle;

  /// Paint-ready timestamp [TextStyle] (bodySmall + onSurfaceVariant,
  /// layered with the per-instance `timestampTextStyle` override).
  final TextStyle timestampTextStyle;

  /// Paint-ready title [TextStyle] (the `labelLarge` role +
  /// onSurface, layered with the per-instance `titleTextStyle`
  /// override).
  final TextStyle titleTextStyle;

  /// Paint-ready description [TextStyle] (bodySmall +
  /// onSurfaceVariant, layered with the per-instance
  /// `descriptionTextStyle` override).
  final TextStyle descriptionTextStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedTimeline] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design system default
///   → theme.coreComponentTheme.timeline.style
///   → widget.timelineStyle
/// ```
ResolvedTimeline resolveTimeline(
  BuildContext context, {
  CoreTimelineStyle? timelineStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final tlTheme = theme.coreComponentTheme?.timeline;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreTimelineStyle(), [
    tlTheme?.style,
    timelineStyle,
  ]);

  // ─── Resolved chrome (scaling pre-applied) ────────────
  // Nested CoreGapStyle slots — forwarded raw to `Gap(gapStyle: …)`,
  // which self-scales (no widget-side `* scaling`). The merged slot
  // wins; design-system default supplies the fallback.
  final columnGapStyle = CoreTimelineStyle.defaultColumnGapStyle.merge(
    merged.columnGapStyle,
  );
  final contentTopGapStyle = CoreTimelineStyle.defaultContentTopGapStyle.merge(
    merged.contentTopGapStyle,
  );
  final dotSize =
      (merged.dotSize ?? CoreTimelineStyle.defaultDotSize) * scaling;
  final connectorThickness = theme.geometry.stroke(
    merged.connectorThickness ?? CoreTimelineStyle.defaultConnectorThickness,
    scaling: scaling,
  );
  // A gap between the line and a dot is spacing: it moves with the density
  // (the Web twin routes it through `spaceCss`).
  final connectorSpacing =
      theme.geometry.space(
        merged.connectorSpacing ?? CoreTimelineStyle.defaultConnectorSpacing,
      ) *
      scaling;
  final rowSpacing =
      theme.geometry.space(
        merged.rowSpacing ?? CoreTimelineStyle.defaultRowSpacing,
      ) *
      scaling;
  final dotTopMargin =
      (merged.dotTopMargin ?? CoreTimelineStyle.defaultDotTopMargin) * scaling;
  final titlePadding =
      ((merged.titlePadding ?? CoreTimelineStyle.defaultTitlePadding)
          .toGeometry(geometry: theme.geometry)) *
      scaling;
  final timeColumnWidth =
      (merged.timeColumnWidth ?? CoreTimelineStyle.defaultTimeColumnWidth) *
      scaling;
  // The line is anchored to the dots at both ends: it runs from
  // [connectorSpacing] below its own dot to [connectorSpacing] above the
  // next one. The next dot sits `rowSpacing + dotTopMargin` below this
  // row's bottom.
  final connectorReach = rowSpacing + dotTopMargin - connectorSpacing;

  final timeColumnConstraints = BoxConstraints(
    minWidth: timeColumnWidth,
    maxWidth: timeColumnWidth,
  );

  // ─── Resolved colours ─────────────────────────────────
  final dotColor = scheme
      .resolve(merged.dotColor ?? CoreTimelineStyle.defaultDotColor)
      .toValue();
  final connectorColor = scheme
      .resolve(
        merged.connectorColor ?? CoreTimelineStyle.defaultConnectorColor,
      )
      .toValue();
  final dotBorderColor = merged.dotBorderColor != null
      ? scheme.resolve(merged.dotBorderColor!).toValue()
      : null;
  final dotBorderWidth = merged.dotBorderWidth;

  // ─── Paint-ready dot decoration ───────────────────────
  // Corner radius drives the shape: `9999` (default) ⇒ circle,
  // `0` ⇒ square, anything else ⇒ rounded rectangle via
  // `borderRadius`.
  final dotCornerRadius =
      merged.dotCornerRadius ?? CoreTimelineStyle.defaultDotCornerRadius;
  final dotShape = dotCornerRadius >= dotSize / 2
      ? BoxShape.circle
      : BoxShape.rectangle;
  final dotDecoration = BoxDecoration(
    color: dotColor,
    border: dotBorderColor != null && dotBorderWidth != null
        ? .all(color: dotBorderColor, width: dotBorderWidth)
        : null,
    borderRadius: dotShape == .rectangle && dotCornerRadius > 0
        ? .circular(dotCornerRadius * scaling)
        : null,
    shape: dotShape,
  );

  // ─── Paint-ready typography ───────────────────────────
  // EMIT Stage 2 (Flutter) — single primitive
  // `default.merge(override).toValue(theme:)`. `toValue(theme:)`
  // materialises the token role (size-aware slot) and resolves the
  // slot's own colour (`onSurfaceVariant` / `onSurface`) through the
  // active scheme, so dark mode tracks. No hand-rolled
  // `typography.resolve` / `scheme.resolve` of the colour — both
  // happen inside `.toValue(theme:)`.
  final timestampTextStyle = CoreTimelineStyle.defaultTimestampTextStyle
      .merge(merged.timestampTextStyle)
      .toValue(theme: theme);
  final titleTextStyle = CoreTimelineStyle.defaultTitleTextStyle
      .merge(merged.titleTextStyle)
      .toValue(theme: theme);
  final descriptionTextStyle = CoreTimelineStyle.defaultDescriptionTextStyle
      .merge(merged.descriptionTextStyle)
      .toValue(theme: theme);

  // ─── Compose paint-ready resolved object ──────────────
  return ResolvedTimeline(
    rowSpacing: rowSpacing,
    columnGapStyle: columnGapStyle,
    dotSize: dotSize,
    dotDecoration: dotDecoration,
    dotTopMargin: dotTopMargin,
    connectorColor: connectorColor,
    connectorThickness: connectorThickness,
    connectorSpacing: connectorSpacing,
    connectorReach: connectorReach,
    timeColumnConstraints: timeColumnConstraints,
    titlePadding: titlePadding,
    contentTopGapStyle: contentTopGapStyle,
    timestampTextStyle: timestampTextStyle,
    titleTextStyle: titleTextStyle,
    descriptionTextStyle: descriptionTextStyle,
  );
}
