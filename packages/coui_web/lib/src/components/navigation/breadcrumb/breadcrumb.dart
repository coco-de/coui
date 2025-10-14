import 'package:coui_web/src/base/ui_component.dart';
import 'package:jaspr/jaspr.dart';

/// A breadcrumb navigation component.
///
/// Example:
/// ```dart
/// Breadcrumb(
///   items: [
///     BreadcrumbItem(label: 'Home', href: '/'),
///     BreadcrumbItem(label: 'Products', href: '/products'),
///     BreadcrumbItem(label: 'Laptop', isActive: true),
///   ],
/// )
/// ```
class Breadcrumb extends UiComponent {
  /// Creates a Breadcrumb component.
  const Breadcrumb({
    super.key,
    required this.items,
    this.separator = '/',
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _navValue,
  }) : super(null);

  /// Breadcrumb items.
  final List<BreadcrumbItem> items;

  /// Separator between items.
  final String separator;

  static const _navValue = 'nav';

  @override
  Breadcrumb copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    List<Component>? items,
    String? separator,
    Key? key,
  }) {
    return Breadcrumb(
      key: key ?? this.key,
      items: items ?? this.items,
      separator: separator ?? this.separator,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
      attributes: attributes ?? this.componentAttributes,
    );
  }

  @override
  Component build(BuildContext context) {
    final children = <Component>[];

    for (int i = 0; i < items.length; i += 1) {
      final item = items[i];

      if (i > 0) {
        children.add(
          span(
            classes: 'mx-2 text-muted-foreground',
            child: text(separator),
          ),
        );
      }

      children.add(item.build(context));
    }

    return nav(
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: {
        ...this.componentAttributes,
        'aria-label': 'Breadcrumb',
      },
      events: events,
      child: ol(
        classes: 'flex items-center space-x-1',
        children: children,
      ),
    );
  }

  @override
  String get baseClass => '';

  String _buildClasses() {
    final classList = <String>[];

    if (baseClass.isNotEmpty) {
      classList.add(baseClass);
    }

    final currentClasses = classes;
    if (currentClasses != null && currentClasses.isNotEmpty) {
      classList.add(currentClasses);
    }

    return classList.join(' ');
  }
}

/// A breadcrumb item component.
class BreadcrumbItem extends UiComponent {
  /// Creates a BreadcrumbItem component.
  const BreadcrumbItem({
    super.key,
    required this.label,
    this.href,
    this.isActive = false,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _liValue,
  }) : super(null);

  /// Item label.
  final String label;

  /// Item link.
  final String? href;

  /// Whether this is the current/active item.
  final bool isActive;

  static const _liValue = 'li';

  @override
  BreadcrumbItem copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    String? label,
    String? href,
    bool? isActive,
    Key? key,
  }) {
    return BreadcrumbItem(
      key: key ?? this.key,
      label: label ?? this.label,
      href: href ?? this.href,
      isActive: isActive ?? this.isActive,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  Component build(BuildContext context) {
    final currentHref = href;
    final labelText = text(label);

    return li(
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: this.componentAttributes,
      events: this.events,
      child: isActive || currentHref == null
          ? span(
              classes: 'font-medium text-foreground',
              attributes: {
                if (isActive) 'aria-current': 'page',
              },
              child: labelText,
            )
          : a(
              href: currentHref,
              classes:
                  'font-medium text-muted-foreground transition-colors hover:text-foreground',
              child: labelText,
            ),
    );
  }

  @override
  String get baseClass => '';

  String _buildClasses() {
    final classList = <String>[];

    if (baseClass.isNotEmpty) {
      classList.add(baseClass);
    }

    final currentClasses = classes;
    if (currentClasses != null && currentClasses.isNotEmpty) {
      classList.add(currentClasses);
    }

    return classList.join(' ');
  }
}
