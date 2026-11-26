import 'package:coui_flutter/coui_flutter.dart';

/// Unified cross-platform tracker with token-based rendering.
///
/// Displays a row of color-coded segments representing status data.
/// Uses [CoreTrackerContract] from `coui_core` for consistent
/// cross-platform API.
///
/// Chrome / dimensional overrides flow through the single
/// [trackerStyle] slot per Epic #1302. Behavioural flags
/// (`segments`, `rounded`) stay flat on the widget.
///
/// Example:
/// ```dart
/// Tracker(
///   segments: [
///     CoreTrackerSegment(status: CoreTrackerStatus.fine, tooltip: 'Healthy'),
///     CoreTrackerSegment(status: CoreTrackerStatus.warning, tooltip: 'High load'),
///     CoreTrackerSegment(status: CoreTrackerStatus.critical, tooltip: 'Down'),
///   ],
/// )
/// ```
class Tracker extends StatelessWidget implements CoreTrackerContract {
  /// Creates a [Tracker].
  const Tracker({
    super.key,
    required this.segments,
    this.rounded = true,
    this.trackerStyle,
  });

  @override
  final List<CoreTrackerSegment> segments;

  @override
  final bool rounded;

  @override
  final CoreTrackerStyle? trackerStyle;

  /// Returns a copy of this [Tracker] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Tracker copyWith({
    Key? key,
    List<CoreTrackerSegment>? segments,
    bool? rounded,
    CoreTrackerStyle? trackerStyle,
  }) {
    return Tracker(
      key: key ?? this.key,
      segments: segments ?? this.segments,
      rounded: rounded ?? this.rounded,
      trackerStyle: trackerStyle ?? this.trackerStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveTracker(
      context,
      segments: segments,
      rounded: rounded,
      trackerStyle: trackerStyle,
    );

    // Web twin exposes aria-label on the track group.
    return Semantics(
      container: true,
      label: CoUILocalizations.of(context).trackerLabel,
      child: Row(
        spacing: resolved.itemSpacing,
        children: [
          for (var i = 0; i < segments.length; i++)
            Expanded(
              child: Tooltip(
                message: segments[i].tooltip ?? segments[i].status.name,
                position: .bottom,
                child: Container(
                  decoration: BoxDecoration(
                    color: resolved.segmentColors[i],
                    borderRadius: resolved.segmentRadii[i],
                  ),
                  height: resolved.itemHeight,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Chain sugar for merging a [CoreTrackerStyle] patch into
/// [Tracker.trackerStyle] without hand-reconstructing every field.
/// Mirrors the Web `Tracker.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreTrackerStyle.merge` right-side-wins semantics).
extension TrackerStyleChain on Tracker {
  /// Returns a copy of this [Tracker] with [patch] merged into
  /// [trackerStyle] (patch fields win on conflict).
  Tracker withStyle(CoreTrackerStyle patch) => copyWith(
    trackerStyle: (trackerStyle ?? const CoreTrackerStyle()).merge(patch),
  );
}
