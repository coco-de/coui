import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/components/display/tracker/tracker_style.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/components/overlay/tooltip/tooltip.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

/// Unified cross-platform tracker for CoUI Web.
///
/// Displays a row of color-coded segments representing status data.
/// Uses [CoreTrackerContract] from `coui_core` for consistent
/// cross-platform API.
///
/// Chrome / dimensional overrides flow through the single
/// [trackerStyle] slot per Epic #1302. Behavioural flags
/// (`segments`, `rounded`) stay flat on the widget. Per Epic #1603
/// (옵션 B 최종) the resolver carries only paint-ready
/// `WebElementChrome` slots — `co_tracker` reads
/// `resolved.<slot>.className` / `resolved.<slot>.inlineStyles` straight
/// off.
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
class Tracker extends UiComponent implements CoreTrackerContract {
  /// Creates a [Tracker].
  const Tracker({
    required this.segments,
    this.rounded = true,
    this.trackerStyle,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.key,
    super.tag = 'div',
  });

  @override
  final List<CoreTrackerSegment> segments;

  @override
  final bool rounded;

  @override
  final CoreTrackerStyle? trackerStyle;
  @override
  Component build(BuildContext context) {
    // Resolver finishes className + inlineStyles synthesis (Epic #1603
    // 옵션 B 최종 — `WebResolvedChrome` contract). `co_tracker` reads
    // the paint-ready strings directly without any merge / fallback in
    // the widget body.
    final resolved = resolveTracker(
      context,
      segments: segments,
      rounded: rounded,
      trackerStyle: trackerStyle,
    );

    final userClasses = classes;
    final finalClasses = userClasses == null || userClasses.isEmpty
        ? resolved.root.className
        : '${resolved.root.className} $userClasses';

    return div(
      [
        for (var i = 0; i < segments.length; i++)
          _buildSegment(
            segments[i],
            segmentChrome: resolved.segments[i],
            tooltipChrome: resolved.segmentTooltip,
          ),
      ],
      id: id,
      classes: finalClasses,
      styles: Styles.combine([?resolved.root.inlineStyles, ?this.css]),
      // `aria-label` needs `CouiLocalizations.of(context)`, unavailable
      // in `configureAttributes`. Mirrors the Flutter twin's
      // `Semantics(container: true, label: ...trackerLabel)`.
      attributes: {
        ...componentAttributes,
        'aria-label': CouiLocalizations.of(context).trackerLabel,
      },
      events: this.events,
    );
  }

  @override
  Tracker copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    bool? rounded,
    List<CoreTrackerSegment>? segments,
    CoreTrackerStyle? trackerStyle,
    String? tag,
  }) {
    return Tracker(
      key: key ?? this.key,
      segments: segments ?? this.segments,
      rounded: rounded ?? this.rounded,
      trackerStyle: trackerStyle ?? this.trackerStyle,
      attributes: attributes ?? componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  Component _buildSegment(
    CoreTrackerSegment segment, {
    required WebElementChrome segmentChrome,
    required WebElementChrome tooltipChrome,
  }) {
    // `status.name` is a Dart identifier, not a translated string, and
    // not stable across a refactor — falls back to it only when the
    // caller supplied no `tooltip` (same source and same fallback as
    // the Flutter twin's `Tooltip(message: ...)` below, which is what
    // Flutter's own accessible name comes from).
    final segmentDiv = div(
      [],
      classes: segmentChrome.className,
      styles: segmentChrome.inlineStyles,
      attributes: {'aria-label': segment.tooltip ?? segment.status.name},
    );

    return Tooltip(
      classes: tooltipChrome.className,
      css: tooltipChrome.inlineStyles,
      message: segment.tooltip ?? segment.status.name,
      position: .bottom,
      child: segmentDiv,
    );
  }
}

/// Chain sugar mirroring the Flutter `Tracker.withStyle` extension —
/// merges a [CoreTrackerStyle] patch into [Tracker.trackerStyle] via the
/// existing [Tracker.copyWith].
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
