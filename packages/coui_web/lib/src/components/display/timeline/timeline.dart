import 'package:coui_web/src/base/ui_component.dart';
import 'package:jaspr/jaspr.dart';

/// A timeline component for displaying chronological events.
///
/// Example:
/// ```dart
/// Timeline(
///   items: [
///     TimelineItem(
///       title: 'Event 1',
///       description: 'Description',
///       timestamp: '2024-01-01',
///     ),
///     TimelineItem(
///       title: 'Event 2',
///       description: 'Description',
///       timestamp: '2024-01-02',
///     ),
///   ],
/// )
/// ```
class Timeline extends UiComponent {
  /// Creates a Timeline component.
  const Timeline({
    super.key,
    required this.items,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(null);

  /// Timeline items.
  final List<TimelineItem> items;

  static const _divValue = 'div';

  @override
  Timeline copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    List<TimelineItem>? items,
    Key? key,
  }) {
    return Timeline(
      key: key ?? this.key,
      items: items ?? this.items,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  Component build(BuildContext context) {
    return div(
      children: items.map((item) => _buildTimelineItem(item)).toList(),
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: this.componentAttributes,
      events: this.events,
    );
  }

  @override
  String get baseClass =>
      'space-y-8 relative before:absolute before:inset-0 before:ml-5 before:-translate-x-px before:w-0.5 before:bg-gradient-to-b before:from-transparent before:via-border before:to-transparent';

  String _buildClasses() {
    final classList = [baseClass];

    final currentClasses = classes;
    if (currentClasses != null && currentClasses.isNotEmpty) {
      classList.add(currentClasses);
    }

    return classList.join(' ');
  }

  static Component _buildTimelineItem(TimelineItem item) {
    return div(
      children: [
        // Timeline marker
        div(
          child:
              item.icon ??
              div(classes: 'w-2 h-2 rounded-full bg-primary-foreground'),
          classes:
              'absolute left-0 top-0 flex items-center justify-center w-10 h-10 rounded-full border-4 border-background bg-primary',
        ),
        // Content
        div(
          children: [
            if (item.timestamp != null)
              span(
                child: text(item.timestamp),
                classes: 'text-xs text-muted-foreground',
              ),
            h3(
              child: text(item.title),
              classes: 'font-semibold',
            ),
            if (item.description != null)
              p(
                child: text(item.description),
                classes: 'text-sm text-muted-foreground',
              ),
            if (item.content != null) item.content,
          ],
          classes: 'flex flex-col gap-1',
        ),
      ],
      classes: 'relative pl-12',
    );
  }
}

/// A timeline item.
class TimelineItem {
  /// Creates a TimelineItem.
  const TimelineItem({
    required this.title,
    this.description,
    this.timestamp,
    this.icon,
    this.content,
  });

  /// Item title.
  final String title;

  /// Optional description.
  final String? description;

  /// Optional timestamp.
  final String? timestamp;

  /// Optional custom icon.
  final Component? icon;

  /// Optional additional content.
  final Component? content;
}
