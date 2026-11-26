import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `Tracker`.
///
/// Widget tree (`co_tracker` is render-only):
///
/// ```text
/// Row (spacing: itemSpacing)            // native Row.spacing (3.27+)
///   └─ Expanded × segments.length
///        └─ Tooltip
///             └─ Container
///                  (color: segmentColors[i],
///                   borderRadius: segmentRadii[i],
///                   height: itemHeight)
/// ```
///
/// Every chrome / dimensional override has been merged through:
///
/// ```text
/// design-system default (CoreTrackerStyle.defaultX /
///   defaultsByStatus[status])
///   → theme.coreComponentTheme.tracker.style
///   → widget.trackerStyle
/// ```
///
/// Field grouping:
///
/// 1. **Per-segment paint values** — [segmentColors] resolves each
///    segment's [CoreTrackerStatus] through `scheme.resolve(token)
///    .toValue()` (or the global override), and [segmentRadii] rounds
///    only the row's outer ends (inner corners zeroed). Both lists are
///    indexed 1:1 with `segments`, so the widget just reads
///    `segmentColors[i]` / `segmentRadii[i]` without re-running any
///    colour / radius logic.
/// 2. **State-independent chrome** — [itemHeight] / [itemSpacing] as
///    plain Flutter `double`s. [itemSpacing] flows directly into
///    `Row.spacing` (native paint-API argument, 3.27+) so the widget
///    stays render-only with no interleave loop.
class ResolvedTracker {
  /// Creates a [ResolvedTracker].
  const ResolvedTracker({
    required this.itemHeight,
    required this.itemSpacing,
    required this.segmentColors,
    required this.segmentRadii,
  });

  /// Effective per-segment height (logical px).
  final double itemHeight;

  /// Effective horizontal spacing between adjacent segments (logical
  /// px). Flows directly into `Row.spacing`.
  final double itemSpacing;

  /// Paint-ready segment fill colours, indexed 1:1 with the widget's
  /// `segments`. Each entry is resolved via
  /// `scheme.resolve(token).toValue()` from the segment's
  /// [CoreTrackerStatus] (or the global `segmentColor` override when
  /// set).
  final List<Color> segmentColors;

  /// Paint-ready per-segment [BorderRadius], indexed 1:1 with the
  /// widget's `segments`. The leftmost / rightmost segments round their
  /// outer corners (`endRadius`) while inner corners stay square;
  /// `null` when `rounded == false`.
  final List<BorderRadius?> segmentRadii;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedTracker] for the given [context].
///
/// Merge chain (per-field):
///
/// ```text
/// design-system default (CoreTrackerStyle.defaultX /
///   defaultsByStatus[status])
///   → theme.coreComponentTheme.tracker.style
///   → widget.trackerStyle
/// ```
///
/// [segments] and [rounded] are forwarded from the widget so the
/// resolver can pre-compute paint-ready per-segment colours and corner
/// radii — the widget stays render-only.
ResolvedTracker resolveTracker(
  BuildContext context, {
  required List<CoreTrackerSegment> segments,
  required bool rounded,
  CoreTrackerStyle? trackerStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final scheme = theme.colorScheme;
  final trackerTheme = theme.coreComponentTheme?.tracker;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreTrackerStyle(), [
    trackerTheme?.style,
    trackerStyle,
  ]);

  // ─── Resolved chrome (paint-ready) ────────────────────
  final itemHeight =
      (merged.itemHeight ?? CoreTrackerStyle.defaultItemHeight) * scaling;
  final itemSpacing =
      theme.geometry.space(
        merged.itemSpacing ?? CoreTrackerStyle.defaultItemSpacing,
      ) *
      scaling;
  final endRadius =
      theme.geometry
          .borderRadius(
            CoreBorderRadius.all(
              merged.endRadius ?? CoreTrackerStyle.defaultEndRadius,
            ),
          )
          .topLeft *
      scaling;
  // Global segment colour override (when set, every segment uses it
  // regardless of status).
  final overrideColor = merged.segmentColor;

  // ─── Per-segment paint values (1:1 with segments) ─────
  // Colour: override wins, else the per-status default token. Both run
  // through `scheme.resolve(token).toValue()` so the widget reads
  // paint-ready Flutter `Color`s (Epic #1603 C7 colour path).
  final segmentColors = <Color>[
    for (final segment in segments)
      scheme
          .resolve(
            overrideColor ??
                CoreTrackerStyle
                    .defaultsByStatus[segment.status]!
                    .segmentColor!,
          )
          .toValue(),
  ];

  // Radius: only the row's outer ends round (inner corners square).
  // Resolved as paint-ready Flutter `BorderRadius` here (Epic #1603 C9
  // — no raw `double` *Radius leaks to the widget).
  final lastIndex = segments.length - 1;
  final segmentRadii = <BorderRadius?>[
    for (var i = 0; i < segments.length; i++)
      rounded
          ? BorderRadius.horizontal(
              left: i == 0 ? .circular(endRadius) : .zero,
              right: i == lastIndex ? .circular(endRadius) : .zero,
            )
          : null,
  ];

  return ResolvedTracker(
    itemHeight: itemHeight,
    itemSpacing: itemSpacing,
    segmentColors: segmentColors,
    segmentRadii: segmentRadii,
  );
}
