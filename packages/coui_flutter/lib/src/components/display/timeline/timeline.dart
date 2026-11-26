import 'package:coui_flutter/coui_flutter.dart';

/// Unified cross-platform timeline with token-based rendering.
///
/// Displays a chronological sequence of events with markers,
/// titles, descriptions, and timestamps.
/// Uses [CoreTimelineContract] from `coui_core` for consistent
/// cross-platform API.
///
/// Example:
/// ```dart
/// Timeline(
///   items: [
///     CoreTimelineItem(
///       title: 'Order placed',
///       timestamp: '10:00 AM',
///       description: 'Your order has been received.',
///     ),
///     CoreTimelineItem(
///       title: 'Shipped',
///       timestamp: '2:00 PM',
///     ),
///   ],
/// )
/// ```
class Timeline extends StatelessWidget implements CoreTimelineContract {
  /// Creates a [Timeline].
  const Timeline({
    required this.items,
    super.key,
    this.timelineStyle,
  });

  @override
  final List<CoreTimelineItem> items;

  /// Per-instance composite style — chrome flat fields (dot, connector,
  /// gap) plus nested `timestampTextStyle` / `titleTextStyle` /
  /// `descriptionTextStyle` text-style slots. See [CoreTimelineStyle]
  /// for the merge chain.
  @override
  final CoreTimelineStyle? timelineStyle;

  /// Returns a copy of this [Timeline] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Timeline copyWith({
    Key? key,
    List<CoreTimelineItem>? items,
    CoreTimelineStyle? timelineStyle,
  }) {
    return Timeline(
      key: key ?? this.key,
      items: items ?? this.items,
      timelineStyle: timelineStyle ?? this.timelineStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveTimeline(context, timelineStyle: timelineStyle);

    final rows = <Widget>[
      for (int i = 0; i < items.length; i += 1)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: .stretch,
            children: [
              ConstrainedBox(
                constraints: resolved.timeColumnConstraints,
                child: Align(
                  alignment: .topRight,
                  child: Text(
                    items[i].timestamp ?? '',
                    style: resolved.timestampTextStyle,
                  ),
                ),
              ),
              Gap(gapStyle: resolved.columnGapStyle),
              Column(
                mainAxisSize: .min,
                children: [
                  Container(
                    decoration: resolved.dotDecoration,
                    width: resolved.dotSize,
                    height: resolved.dotSize,
                    margin: .only(top: resolved.dotTopMargin),
                  ),
                  if (i != items.length - 1)
                    Expanded(
                      // Vertical connector, painted directly. The line
                      // starts `connectorSpacing` below its own dot and runs
                      // `connectorReach` past the bottom of its box, which
                      // carries it across the row spacing to stop
                      // `connectorSpacing` above the next dot. Painting (not
                      // laying out) that reach keeps IntrinsicHeight happy
                      // — a layout-time negative extent would not — and
                      // the dot column stays at dotSize width (the Web
                      // twin's column model).
                      child: SizedBox(
                        width: resolved.connectorThickness,
                        child: CustomPaint(
                          painter: _TimelineConnectorPainter(
                            color: resolved.connectorColor,
                            startGap: resolved.connectorSpacing,
                            endReach: resolved.connectorReach,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Gap(gapStyle: resolved.columnGapStyle),
              Expanded(
                child: Column(
                  mainAxisSize: .min,
                  crossAxisAlignment: .stretch,
                  children: [
                    Padding(
                      padding: resolved.titlePadding,
                      child: Text(
                        items[i].title,
                        style: resolved.titleTextStyle,
                      ),
                    ),
                    if (items[i].description != null)
                      Gap(gapStyle: resolved.contentTopGapStyle),
                    if (items[i].description != null)
                      Expanded(
                        child: Text(
                          items[i].description!,
                          style: resolved.descriptionTextStyle,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
    ];

    // Native `Column.spacing` paint-API consumes the resolver's
    // pre-scaled `rowSpacing` directly — no manual `Gap` interleave
    // (Epic #1659 N-sibling uniform distribution pattern).
    return Column(spacing: resolved.rowSpacing, children: rows);
  }
}

/// Chain sugar for merging a [CoreTimelineStyle] patch into
/// [Timeline.timelineStyle] without hand-reconstructing every field.
/// Mirrors the Web `Timeline.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreTimelineStyle.merge` right-side-wins semantics).
extension TimelineStyleChain on Timeline {
  /// Returns a copy of this [Timeline] with [patch] merged into
  /// [timelineStyle] (patch fields win on conflict).
  Timeline withStyle(CoreTimelineStyle patch) => copyWith(
    timelineStyle: (timelineStyle ?? const CoreTimelineStyle()).merge(patch),
  );
}

/// Paints the vertical connector line from [startGap] below the top of
/// its box to [endReach] past the bottom of it, so the line stops short of
/// the next row's dot across the row gap (paint-only — layout is
/// unaffected, so `IntrinsicHeight` measurement stays valid).
class _TimelineConnectorPainter extends CustomPainter {
  const _TimelineConnectorPainter({
    required this.color,
    required this.startGap,
    required this.endReach,
  });

  final Color color;
  final double startGap;
  final double endReach;

  @override
  void paint(Canvas canvas, Size size) {
    final bottom = size.height + endReach;
    // A gap larger than the room between two dots leaves no line.
    if (bottom <= startGap) return;
    canvas.drawRect(
      Rect.fromLTRB(0, startGap, size.width, bottom),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _TimelineConnectorPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.startGap != startGap ||
      oldDelegate.endReach != endReach;
}
