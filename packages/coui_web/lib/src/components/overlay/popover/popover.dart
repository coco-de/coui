import 'package:coui_web/src/base/ui_component.dart';
import 'package:jaspr/jaspr.dart';

/// A popover component for displaying content in a floating panel.
///
/// Example:
/// ```dart
/// Popover(
///   trigger: Button.outline(child: text('Open')),
///   content: div(child: text('Popover content')),
/// )
/// ```
class Popover extends UiComponent {
  /// Creates a Popover component.
  ///
  /// Parameters:
  /// - [trigger]: Component that triggers the popover
  /// - [content]: Popover content
  /// - [side]: Popover position (top, right, bottom, left)
  const Popover({
    super.key,
    required this.trigger,
    required this.content,
    this.side = PopoverSide.bottom,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(null);

  /// Trigger component.
  final Component trigger;

  /// Popover content.
  final Component content;

  /// Popover position.
  final PopoverSide side;

  static const _divValue = 'div';

  @override
  Popover copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    List<Component>? children,
    Component? trigger,
    Component? content,
    PopoverSide? side,
    Key? key,
  }) {
    return Popover(
      key: key ?? this.key,
      trigger: trigger ?? this.trigger,
      content: content ?? this.content,
      side: side ?? this.side,
      children: children ?? this.children,
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
    return div(
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: this.componentAttributes,
      events: this.events,
      children: [
        trigger,
        // Popover content
        div(
          classes: _buildPopoverClasses(),
          attributes: {
            'data-side': side.name,
            'role': 'dialog',
          },
          child: content,
        ),
      ],
    );
  }

  String _buildClasses() {
    final classList = [baseClass];

    if (classes != null && classes!.isNotEmpty) {
      classList.add(classes!);
    }

    return classList.join(' ');
  }

  String _buildPopoverClasses() {
    const base =
        'z-50 w-72 rounded-md border bg-popover p-4 text-popover-foreground shadow-md outline-none';
    final position = switch (side) {
      PopoverSide.top => 'bottom-full mb-2',
      PopoverSide.right => 'left-full ml-2',
      PopoverSide.bottom => 'top-full mt-2',
      PopoverSide.left => 'right-full mr-2',
    };

    return '$base $position hidden group-hover:block';
  }
}

/// Popover position options.
enum PopoverSide {
  /// Display above the trigger.
  top,

  /// Display to the right of the trigger.
  right,

  /// Display below the trigger.
  bottom,

  /// Display to the left of the trigger.
  left,
}
