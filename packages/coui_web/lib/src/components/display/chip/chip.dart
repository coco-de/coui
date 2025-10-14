// ignore_for_file: avoid-using-non-ascii-symbols

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

  /// Close icon character code (U+00D7 - ×).
  static const _kCloseIconCode = 0x00D7;

  static const _spanValue = 'span';

  /// Close icon character.
  static String get _kCloseIcon => String.fromCharCode(_kCloseIconCode);

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
          child: text(_kCloseIcon),
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

  @override
  String get baseClass => '';

  String _buildClasses() {
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
