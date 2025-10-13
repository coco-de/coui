import 'package:coui_web/src/base/ui_component.dart';
import 'package:jaspr/jaspr.dart';

/// Callback signature for collapsible state change.
typedef CollapsibleCallback = void Function(bool isOpen);

/// A collapsible component for expandable/collapsible content.
///
/// Example:
/// ```dart
/// Collapsible(
///   trigger: button(child: text('Toggle')),
///   content: div(child: text('Hidden content')),
///   isOpen: false,
/// )
/// ```
class Collapsible extends UiComponent {
  /// Creates a Collapsible component.
  ///
  /// Parameters:
  /// - [trigger]: Trigger element
  /// - [content]: Collapsible content
  /// - [isOpen]: Whether content is visible
  /// - [onOpenChanged]: Callback when state changes
  const Collapsible({
    super.key,
    required this.trigger,
    required this.content,
    this.isOpen = false,
    this.onOpenChanged,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(null);

  /// Trigger element.
  final Component trigger;

  /// Collapsible content.
  final Component content;

  /// Whether content is visible.
  final bool isOpen;

  /// Callback when state changes.
  final CollapsibleCallback? onOpenChanged;

  static const _divValue = 'div';

  @override
  Collapsible copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    Component? trigger,
    Component? content,
    bool? isOpen,
    CollapsibleCallback? onOpenChanged,
    Key? key,
  }) {
    return Collapsible(
      key: key ?? this.key,
      trigger: trigger ?? this.trigger,
      content: content ?? this.content,
      isOpen: isOpen ?? this.isOpen,
      onOpenChanged: onOpenChanged ?? this.onOpenChanged,
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
      id: id,
      classes: _buildClasses(),
      styles: css,
      attributes: {
        ...this.componentAttributes,
        'data-state': isOpen ? 'open' : 'closed',
      },
      events: this.events,
      children: [
        // Trigger with click handler
        div(
          events: _buildTriggerEvents(),
          child: trigger,
        ),
        // Collapsible content
        if (isOpen)
          div(
            classes:
                'overflow-hidden transition-all data-[state=open]:animate-in data-[state=closed]:animate-out',
            attributes: {
              'data-state': isOpen ? 'open' : 'closed',
            },
            child: content,
          ),
      ],
    );
  }

  @override
  String get baseClass => 'space-y-2';

  String _buildClasses() {
    final classList = [baseClass];

    if (classes != null && classes!.isNotEmpty) {
      classList.add(classes!);
    }

    return classList.join(' ');
  }

  Map<String, List<dynamic>> _buildTriggerEvents() {
    final callback = onOpenChanged;
    return callback == null
        ? {}
        : {
            'click': [
              (event) => callback(!isOpen),
            ],
          };
  }
}
