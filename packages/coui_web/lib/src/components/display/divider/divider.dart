import 'package:coui_web/src/base/ui_component.dart';
import 'package:jaspr/jaspr.dart';

/// A divider component for separating content.
///
/// Example:
/// ```dart
/// Divider() // Horizontal divider
/// Divider.vertical() // Vertical divider
/// ```
class Divider extends UiComponent {
  /// Creates a horizontal Divider component.
  const Divider({
    super.key,
    this.orientation = DividerOrientation.horizontal,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _hrValue,
  }) : super(null);

  /// Creates a vertical Divider component.
  const Divider.vertical({
    super.key,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : orientation = DividerOrientation.vertical,
       super(null);

  /// Orientation of the divider.
  final DividerOrientation orientation;

  static const _hrValue = 'hr';
  static const _divValue = 'div';

  @override
  Divider copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    DividerOrientation? orientation,
    Key? key,
  }) {
    return Divider(
      key: key ?? this.key,
      orientation: orientation ?? this.orientation,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  String get baseClass => orientation == DividerOrientation.horizontal
      ? 'shrink-0 bg-border h-[1px] w-full'
      : 'shrink-0 bg-border w-[1px] h-full';

  @override
  Component build(BuildContext context) {
    return Component.element(
      tag: tag,
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: this.componentAttributes,
      events: this.events,
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

/// Divider orientation.
enum DividerOrientation {
  /// Horizontal divider.
  horizontal,

  /// Vertical divider.
  vertical,
}
