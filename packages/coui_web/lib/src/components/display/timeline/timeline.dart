import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/components/display/timeline/timeline_style.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' hide Text;

/// Unified cross-platform timeline for CoUI Web.
///
/// Displays a chronological sequence of events with markers, titles,
/// descriptions, and timestamps. Uses [CoreTimelineContract] from
/// `coui_core` for consistent cross-platform API.
///
/// Example:
/// ```dart
/// Timeline(
///   items: [
///     CoreTimelineItem(title: 'Event 1', timestamp: '2024-01-01'),
///     CoreTimelineItem(title: 'Event 2', timestamp: '2024-01-02'),
///   ],
/// )
/// ```
class Timeline extends UiComponent implements CoreTimelineContract {
  /// Creates a [Timeline].
  const Timeline({
    required this.items,
    this.timelineStyle,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.key,
    super.tag = 'div',
  });

  @override
  final List<CoreTimelineItem> items;

  /// Per-instance composite style — chrome flat fields plus nested
  /// `timestampTextStyle` / `titleTextStyle` / `descriptionTextStyle`
  /// slots. See [CoreTimelineStyle] for the merge chain.
  @override
  final CoreTimelineStyle? timelineStyle;
  @override
  Component build(BuildContext context) {
    final resolved = resolveTimeline(context, timelineStyle: timelineStyle);

    return div(
      [
        for (var i = 0; i < items.length; i++)
          _buildTimelineItem(
            items[i],
            isLast: i == items.length - 1,
            resolved: resolved,
          ),
      ],
      id: id,
      classes: resolved.root.className,
      styles: resolved.root.inlineStyles,
      attributes: componentAttributes,
      events: this.events,
    );
  }

  @override
  Timeline copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    List<CoreTimelineItem>? items,
    CoreTimelineStyle? timelineStyle,
    Key? key,
    String? tag,
  }) {
    return Timeline(
      key: key ?? this.key,
      items: items ?? this.items,
      timelineStyle: timelineStyle ?? this.timelineStyle,
      attributes: attributes ?? componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  static Component _buildTimelineItem(
    CoreTimelineItem item, {
    required bool isLast,
    required ResolvedTimeline resolved,
  }) {
    // Render explicit `Gap` widgets between siblings inside the row
    // so the per-row column spacing is owned by the nested
    // `columnGapStyle` slot (matching the Flutter widget). `Gap`
    // runs its own resolve / scaling step.
    final columnGap = Gap(gapStyle: resolved.columnGapStyle);

    return div(
      [
        div(
          [Text(item.timestamp ?? '')],
          classes: resolved.timestamp.className,
          styles: resolved.timestamp.inlineStyles,
        ),
        columnGap,
        div(
          [
            div(
              [],
              classes: resolved.dot.className,
              styles: resolved.dot.inlineStyles,
            ),
            if (!isLast)
              div(
                [],
                classes: resolved.connector.className,
                styles: resolved.connector.inlineStyles,
              ),
          ],
          classes: resolved.markerColumn.className,
          styles: resolved.markerColumn.inlineStyles,
        ),
        columnGap,
        div(
          [
            div(
              [Text(item.title)],
              classes: resolved.title.className,
              styles: resolved.title.inlineStyles,
            ),
            if (item.description != null)
              div(
                [Text(item.description!)],
                classes: resolved.description.className,
                styles: resolved.description.inlineStyles,
              ),
          ],
          classes: resolved.contentColumn.className,
          styles: resolved.contentColumn.inlineStyles,
        ),
      ],
      classes: resolved.itemRow.className,
      styles: resolved.itemRow.inlineStyles,
    );
  }
}

/// Chain sugar mirroring the Flutter `Timeline.withStyle` extension —
/// merges a [CoreTimelineStyle] patch into [Timeline.timelineStyle] via
/// the existing [Timeline.copyWith].
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
