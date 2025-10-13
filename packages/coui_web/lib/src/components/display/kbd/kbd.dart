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

    for (int i = 0; i < keys.length; i += 1) {
      if (i > 0) {
        keyComponents.add(
          span(
            classes: 'text-xs text-muted-foreground mx-0.5',
            child: text('+'),
          ),
        );
      }

      keyComponents.add(
        Component.element(
          tag: 'kbd',
          classes:
              'pointer-events-none inline-flex h-5 select-none items-center gap-1 rounded border bg-muted px-1.5 font-mono text-[10px] font-medium text-muted-foreground opacity-100',
          child: text(keys[i]),
        ),
      );
    }

    return div(
      id: id,
      classes: _buildClasses(),
      styles: css,
      attributes: this.componentAttributes,
      events: this.events,
      children: keyComponents,
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

    if (classes != null && classes!.isNotEmpty) {
      classList.add(classes!);
    }

    return classList.join(' ');
  }
}
