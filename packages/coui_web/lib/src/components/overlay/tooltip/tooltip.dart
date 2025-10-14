import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/components/overlay/tooltip/tooltip_style.dart';
import 'package:jaspr/jaspr.dart';

/// A tooltip component for displaying helpful text on hover.
///
/// Example:
/// ```dart
/// Tooltip(
///   content: 'Helpful tip',
///   child: Button.primary(child: text('Hover me')),
/// )
/// ```
class Tooltip extends UiComponent {
  /// Creates a Tooltip component.
  ///
  /// Parameters:
  /// - [content]: Tooltip content text
  /// - [child]: Trigger element
  Tooltip({
    super.key,
    required this.content,
    required Component this.triggerChild,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(
         null,
         style: [
           TooltipVariantStyle(),
         ],
       );

  /// Tooltip content text.
  final String content;

  /// Trigger element.
  final Component triggerChild;

  static const _divValue = 'div';

  @override
  Tooltip copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    List<Component>? children,
    Component? triggerChild,
    String? content,
    Key? key,
  }) {
    return Tooltip(
      key: key ?? this.key,
      content: content ?? this.content,
      triggerChild: triggerChild ?? this.triggerChild,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  String get baseClass => 'relative inline-block';

  @override
  Component build(BuildContext context) {
    return Component.element(
      tag: tag,
      id: id,
      classes: baseClass,
      styles: this.css,
      attributes: this.componentAttributes,
      events: this.events,
      children: [
        // Trigger
        triggerChild,
        // Tooltip content (shown on hover via CSS)
        Component.element(
          child: text(content),
          tag: 'span',
          classes:
              '${_buildTooltipClasses()} invisible group-hover:visible opacity-0 group-hover:opacity-100 transition-opacity',
        ),
      ],
    );
  }

  String _buildTooltipClasses() {
    final classList = <String>[];

    // Add variant classes from style
    final currentStyle = style;
    if (currentStyle != null) {
      for (final s in currentStyle) {
        classList.add(s.cssClass);
      }
    }

    // Add user classes
    final currentClasses = classes;
    if (currentClasses != null && currentClasses.isNotEmpty) {
      classList.add(currentClasses);
    }

    return classList.join(' ');
  }
}
