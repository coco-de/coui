import 'package:coui_web/src/base/ui_component.dart';
import 'package:jaspr/jaspr.dart';

/// A hover card component that shows content on hover.
///
/// Example:
/// ```dart
/// HoverCard(
///   trigger: text('Hover me'),
///   content: div(child: text('Hidden content')),
/// )
/// ```
class HoverCard extends UiComponent {
  /// Creates a HoverCard component.
  const HoverCard({
    super.key,
    required this.trigger,
    required this.content,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(null);

  /// Trigger element.
  final Component trigger;

  /// Card content.
  final Component content;

  static const _divValue = 'div';

  @override
  HoverCard copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    Component? trigger,
    Component? content,
    Key? key,
  }) {
    return HoverCard(
      key: key ?? this.key,
      trigger: trigger ?? this.trigger,
      content: content ?? this.content,
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
      children: [
        // Trigger
        trigger,
        // Card content (shown on hover)
        div(
          child: content,
          classes:
              'absolute z-50 w-64 rounded-md border bg-popover p-4 text-popover-foreground shadow-md outline-none invisible group-hover:visible opacity-0 group-hover:opacity-100 transition-opacity mt-2',
          attributes: {
            'role': 'dialog',
          },
        ),
      ],
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: this.componentAttributes,
      events: this.events,
    );
  }

  @override
  String get baseClass => 'relative inline-block group';

  String _buildClasses() {
    final classList = [baseClass];

    final currentClasses = classes;
    if (currentClasses != null && currentClasses.isNotEmpty) {
      classList.add(currentClasses);
    }

    return classList.join(' ');
  }
}
