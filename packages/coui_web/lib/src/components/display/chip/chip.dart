import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/components/display/chip/chip_style.dart';
import 'package:jaspr/jaspr.dart';

/// Callback signature for chip removal.
typedef ChipRemoveCallback = void Function();

/// A chip component for tags, labels, or removable items.
///
/// Example:
/// ```dart
/// Chip(
///   label: 'Tag',
///   onRemove: () => print('Removed'),
/// )
/// ```
class Chip extends UiComponent {
  /// Creates a Chip component.
  ///
  /// Parameters:
  /// - [label]: Text label of the chip
  /// - [onRemove]: Optional callback for remove action
  /// - [leading]: Optional leading component (e.g., icon)
  Chip({
    super.key,
    required this.label,
    this.onRemove,
    this.leading,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _spanValue,
  }) : super(
         null,
         style: [
           ChipVariantStyle(),
         ],
       );

  /// Text label of the chip.
  final String label;

  /// Optional callback for remove action.
  final ChipRemoveCallback? onRemove;

  /// Optional leading component.
  final Component? leading;

  static const _spanValue = 'span';

  @override
  Chip copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    Component? leading,
    String? label,
    ChipRemoveCallback? onRemove,
    Key? key,
  }) {
    return Chip(
      key: key ?? this.key,
      label: label ?? this.label,
      onRemove: onRemove ?? this.onRemove,
      leading: leading ?? this.leading,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  String get baseClass => '';

  @override
  Component build(BuildContext context) {
    final children = <Component>[];

    // Add leading if provided
    final currentLeading = leading;
    if (currentLeading != null) {
      children.add(currentLeading);
    }

    // Add label
    children.add(text(label));

    // Add remove button if callback provided
    final currentOnRemove = onRemove;
    if (currentOnRemove != null) {
      children.add(
        Component.element(
          tag: 'button',
          classes:
              'ml-1 rounded-full hover:bg-accent-foreground/10 focus:outline-none',
          attributes: {
            'type': 'button',
            'aria-label': 'Remove',
          },
          events: {
            'click': (event) => currentOnRemove(),
          },
          child: text('\u00D7'),
        ),
      );
    }

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

  String _buildClasses() {
    final classList = <String>[];

    // Add variant classes from style
    if (style != null) {
      for (final s in style!) {
        classList.add(s.cssClass);
      }
    }

    // Add user classes
    if (classes != null && classes!.isNotEmpty) {
      classList.add(classes!);
    }

    return classList.join(' ');
  }
}
