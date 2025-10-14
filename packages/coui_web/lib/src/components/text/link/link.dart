import 'package:coui_web/src/base/ui_component.dart';
import 'package:jaspr/jaspr.dart';

/// A link component following shadcn-ui design patterns.
///
/// Example:
/// ```dart
/// Link(
///   href: '/about',
///   child: text('About Us'),
/// )
/// ```
class Link extends UiComponent {
  /// Creates a Link component.
  ///
  /// Parameters:
  /// - [href]: Link destination URL
  /// - [child]: Link content
  /// - [external]: Whether link opens in new tab
  /// - [underline]: Whether link has underline
  Link({
    super.key,
    required this.href,
    Component? child,
    this.external = false,
    this.underline = true,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _aValue,
  }) : super(null, child: child);

  /// Link destination URL.
  final String href;

  /// Whether link opens in new tab.
  final bool external;

  /// Whether link has underline.
  final bool underline;

  static const _aValue = 'a';

  @override
  Link copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    Component? child,
    bool? external,
    bool? underline,
    String? href,
    Key? key,
  }) {
    return Link(
      key: key ?? this.key,
      href: href ?? this.href,
      child: child ?? this.child,
      external: external ?? this.external,
      underline: underline ?? this.underline,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  Component build(BuildContext context) {
    return a(
      id: id,
      href: href,
      classes: _buildClasses(),
      styles: this.css,
      attributes: {
        ...this.componentAttributes,
        if (external) ...{
          'target': '_blank',
          'rel': 'noopener noreferrer',
        },
      },
      events: this.events,
      child: child,
    );
  }

  @override
  String get baseClass =>
      'text-primary ${underline ? 'underline-offset-4 hover:underline' : ''} transition-colors';

  String _buildClasses() {
    final classList = [baseClass];

    final currentClasses = classes;
    if (currentClasses != null && currentClasses.isNotEmpty) {
      classList.add(currentClasses);
    }

    return classList.join(' ');
  }
}
