import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/components/layout/breadcrumb/breadcrumb_style.dart';
import 'package:jaspr/jaspr.dart';

/// A breadcrumb navigation component for showing hierarchical page location.
///
/// The Breadcrumb component displays the current page's location within
/// the site hierarchy. It follows DaisyUI's breadcrumb patterns and provides
/// Flutter-compatible API.
///
/// Features:
/// - Hierarchical navigation path display
/// - Customizable separator
/// - Active item indication
/// - Link or button navigation
/// - Accessibility with ARIA attributes
///
/// Example:
/// ```dart
/// Breadcrumb(
///   items: [
///     BreadcrumbItem(label: 'Home', href: '/'),
///     BreadcrumbItem(label: 'Products', href: '/products'),
///     BreadcrumbItem(label: 'Details', active: true),
///   ],
/// )
/// ```
class Breadcrumb extends UiComponent {
  /// Creates a Breadcrumb component.
  ///
  /// - [items]: List of breadcrumb items to display.
  /// - [separator]: Character or string to separate items (default: '/').
  /// - [style]: List of [BreadcrumbStyling] instances for styling.
  const Breadcrumb({
    super.attributes,
    super.child,
    super.classes,
    super.css,
    super.id,
    required this.items,
    super.key,
    this.separator = '/',
    List<BreadcrumbStyling>? style,
    super.tag = 'div',
  }) : super(null, style: style);

  /// List of breadcrumb items to display.
  final List<BreadcrumbItem> items;

  /// Separator character between items.
  final String separator;

  @override
  String get baseClass => 'breadcrumbs text-sm';

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);

    // Set ARIA navigation landmark
    if (!userProvidedAttributes.containsKey('aria-label')) {
      attributes.addAria('label', 'Breadcrumb');
    }
  }

  @override
  Component build(BuildContext context) {
    final styles = _buildStyleClasses();

    // Build breadcrumb list
    final listItems = <Component>[];
    for (final item in items) {
      listItems.add(_buildBreadcrumbItem(item));
    }

    const emptyString = '';

    return Component.element(
      css: this.css,
      tag: tag,
      id: id,
      classes:
          '$combinedClasses${styles.isNotEmpty ? ' ${styles.join(' ')}' : emptyString}',
      attributes: componentAttributes,
      children: [
        Component.element(tag: 'ul', children: listItems),
      ],
    );
  }

  @override
  Breadcrumb copyWith({
    Map<String, String>? attributes,
    Component? child,
    String? classes,
    Styles? css,
    String? id,
    List<BreadcrumbItem>? items,
    Key? key,
    String? separator,
    List<BreadcrumbStyling>? style,
    String? tag,
  }) {
    return Breadcrumb(
      attributes: attributes ?? userProvidedAttributes,
      child: child ?? this.child,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      id: id ?? this.id,
      items: items ?? this.items,
      key: key ?? this.key,
      separator: separator ?? this.separator,
      style: style,
      tag: tag ?? this.tag,
    );
  }

  List<String> _buildStyleClasses() {
    final stylesList = <String>[];
    final currentStyle = style;

    if (currentStyle != null) {
      for (final s in currentStyle) {
        stylesList.add(s.cssClass);
      }
    }

    return stylesList;
  }

  static Component _buildBreadcrumbItem(BreadcrumbItem item) {
    final label = item.label;
    final href = item.href;
    final onPressed = item.onPressed;
    final active = item.active;

    // Build item content using pattern matching
    final itemContent = switch ((active, href, onPressed)) {
      // Link item
      (false, final String h, _) => Component.element(
        tag: 'a',
        attributes: {'href': h},
        children: [Component.text(label)],
      ),
      // Button item (for SPA navigation)
      (false, null, final VoidCallback cb) => Component.element(
        tag: 'a',
        events: {'click': (_) => cb()},
        children: [Component.text(label)],
      ),
      // Active item or plain text
      _ => Component.text(label),
    };

    return Component.element(tag: 'li', children: [itemContent]);
  }
}

/// Individual breadcrumb item configuration.
///
/// Represents a single item in the breadcrumb navigation.
class BreadcrumbItem {
  /// Creates a BreadcrumbItem.
  ///
  /// - [label]: Text label for the breadcrumb item.
  /// - [href]: URL for link navigation (mutually exclusive with onPressed).
  /// - [onPressed]: Callback for button navigation (mutually exclusive with href).
  /// - [active]: Whether this is the current active page.
  const BreadcrumbItem({
    required this.label,
    this.href,
    this.onPressed,
    this.active = false,
  });

  /// Text label for the item.
  final String label;

  /// URL for link navigation.
  final String? href;

  /// Callback for button navigation (SPA).
  ///
  /// Flutter-compatible void Function() callback.
  final VoidCallback? onPressed;

  /// Whether this item represents the current page.
  final bool active;
}
