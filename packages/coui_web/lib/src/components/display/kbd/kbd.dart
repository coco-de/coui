// ignore_for_file: avoid-similar-names

import 'package:coui_web/src/base/ui_component.dart';
import 'package:jaspr/jaspr.dart';

/// A keyboard key display component.
///
/// Example:
/// ```dart
/// Kbd(keys: ['Ctrl', 'C'])
/// Kbd(keys: ['⌘', 'K'])
/// ```
class Kbd extends UiComponent {
  /// Creates a Kbd component.
  const Kbd({
    super.key,
    required this.keys,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(null);

  /// Creates a single key Kbd.
  Kbd.single({
    super.key,
    required String keyText,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : keys = [keyText],
       super(null);

  /// Keyboard keys to display.
  final List<String> keys;

  static const _divValue = 'div';

  @override
  String get baseClass => 'inline-flex items-center gap-1';

  @override
  Component build(BuildContext context) {
    final keyComponents = <Component>[];

    for (final (index, item) in keys.indexed) {
      if (index > 0) {
        keyComponents.add(
          span(
            child: text('+'),
            classes: 'text-xs text-muted-foreground mx-0.5',
          ),
        );
      }

      keyComponents.add(
        Component.element(
          child: text(item),
          tag: 'kbd',
          classes:
              'pointer-events-none inline-flex h-5 select-none items-center gap-1 rounded border bg-muted px-1.5 font-mono text-[10px] font-medium text-muted-foreground opacity-100',
        ),
      );
    }

    return div(
      children: keyComponents,
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: this.componentAttributes,
      events: this.events,
    );
  }

  @override
  UiComponent copyWith({
    Key? key,
    List<String>? keys,
    Map<String, String>? attributes,
    String? classes,
    String? id,
    String? tag,
    Styles? css,
  }) {
    return Kbd(
      key: key ?? this.key,
      keys: keys ?? this.keys,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  String _buildClasses() {
    final classList = [baseClass];

    final currentClasses = classes;
    if (currentClasses != null && currentClasses.isNotEmpty) {
      classList.add(currentClasses);
    }

    return classList.join(' ');
  }
}
