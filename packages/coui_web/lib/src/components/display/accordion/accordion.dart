import 'package:coui_web/src/base/ui_component.dart';
import 'package:jaspr/jaspr.dart';

/// An accordion component for collapsible content sections.
///
/// Example:
/// ```dart
/// Accordion(
///   children: [
///     AccordionItem(
///       title: 'Section 1',
///       content: text('Content 1'),
///     ),
///     AccordionItem(
///       title: 'Section 2',
///       content: text('Content 2'),
///     ),
///   ],
/// )
/// ```
class Accordion extends UiComponent {
  /// Creates an Accordion component.
  Accordion({
    super.key,
    required List<Component> children,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(children);

  static const _divValue = 'div';

  @override
  Accordion copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    List<Component>? children,

    Key? key,
  }) {
    return Accordion(
      key: key ?? this.key,
      attributes: attributes ?? this.componentAttributes,
      children: children ?? this.children,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  Component build(BuildContext context) {
    return Component.element(
      tag: tag,
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: this.componentAttributes,
      events: this.events,
      children: children,
    );
  }

  @override
  String get baseClass => 'w-full';

  String _buildClasses() {
    final classList = [baseClass];

    if (classes != null && classes!.isNotEmpty) {
      classList.add(classes!);
    }

    return classList.join(' ');
  }
}

/// An accordion item component.
class AccordionItem extends UiComponent {
  /// Creates an AccordionItem component.
  const AccordionItem({
    super.key,
    required this.title,
    required this.content,
    this.isOpen = false,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(null);

  /// Title of the accordion item.
  final String title;

  /// Content of the accordion item.
  final Component content;

  /// Whether the item is open.
  final bool isOpen;

  static const _divValue = 'div';

  @override
  AccordionItem copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    String? title,
    Component? content,
    bool? isOpen,
    Key? key,
  }) {
    return AccordionItem(
      key: key ?? this.key,
      title: title ?? this.title,
      content: content ?? this.content,
      isOpen: isOpen ?? this.isOpen,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  Component build(BuildContext context) {
    return Component.element(
      tag: tag,
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: this.componentAttributes,
      events: this.events,
      children: [
        // Header/Trigger
        Component.element(
          tag: 'button',
          classes:
              'flex flex-1 items-center justify-between py-4 font-medium transition-all hover:underline [&[data-state=open]>svg]:rotate-180',
          attributes: {
            'type': 'button',
            'data-state': isOpen ? 'open' : 'closed',
          },
          children: [
            text(title),
            // Chevron icon (placeholder - you'd use actual icon component)
            span(
              classes: 'transition-transform duration-200',
              child: text('\u25BC'),
            ),
          ],
        ),
        // Content
        if (isOpen)
          div(
            classes: 'overflow-hidden text-sm transition-all pb-4 pt-0',
            child: div(
              classes: 'pt-0',
              child: content,
            ),
          ),
      ],
    );
  }

  @override
  String get baseClass => 'border-b';

  String _buildClasses() {
    final classList = [baseClass];

    if (classes != null && classes!.isNotEmpty) {
      classList.add(classes!);
    }

    return classList.join(' ');
  }
}
