import 'package:coui_web/src/base/types.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/components/menu/context_menu/context_menu_style.dart';
import 'package:jaspr/jaspr.dart';

/// A context menu component for right-click interactions.
///
/// The ContextMenu component displays a menu when the user right-clicks
/// on a target area. It follows DaisyUI's menu styling patterns with
/// absolute positioning for flexible placement.
///
/// Features:
/// - Right-click trigger (contextmenu event)
/// - Absolute positioning at mouse cursor
/// - Menu items with callbacks
/// - Disabled items support
/// - Close on outside click
/// - DaisyUI menu styling
///
/// Example:
/// ```dart
/// ContextMenu(
///   targetChild: text('Right-click me'),
///   items: [
///     ContextMenuItem(
///       label: 'Copy',
///       onPressed: () => handleCopy(),
///     ),
///     ContextMenuItem(
///       label: 'Paste',
///       onPressed: () => handlePaste(),
///     ),
///     ContextMenuItem(
///       label: 'Delete',
///       onPressed: () => handleDelete(),
///       disabled: true,
///     ),
///   ],
/// )
/// ```
class ContextMenu extends UiComponent {
  /// Creates a ContextMenu component.
  ///
  /// - [targetChild]: The target element that triggers the context menu.
  /// - [items]: List of menu items.
  /// - [open]: Whether the context menu is open.
  /// - [onChanged]: Callback when context menu state changes (Flutter-compatible).
  /// - [style]: List of [ContextMenuStyling] instances for styling.
  const ContextMenu({
    super.attributes,
    super.child,
    super.classes,
    super.css,
    super.id,
    required this.items,
    super.key,
    this.onChanged,
    this.open = false,
    List<ContextMenuStyling>? style,
    super.tag = 'div',
    required this.targetChild,
  }) : super(null, style: style);

  /// The target element that triggers the context menu.
  final Component targetChild;

  /// List of menu items.
  final List<ContextMenuItem> items;

  /// Whether the context menu is open.
  final bool open;

  /// Callback when context menu state changes.
  ///
  /// Flutter-compatible callback.
  /// Receives true when menu opens, false when it closes.
  final BoolStateCallback? onChanged;

  @override
  String get baseClass => 'relative';

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);

    // Set ARIA attributes for accessibility
    if (!userProvidedAttributes.containsKey('role')) {
      attributes.addRole('region');
    }
  }

  @override
  Component build(BuildContext context) {
    final styles = _buildStyleClasses();

    // Build menu items
    final menuItems = <Component>[];
    for (final item in items) {
      menuItems.add(_buildMenuItem(item));
    }

    // Build context menu with absolute positioning
    const emptyString = '';
    const hiddenClass = 'hidden';
    final contextMenuElement = Component.element(
      classes:
          'menu bg-base-100 rounded-box shadow-lg absolute z-50 w-52 ${open ? emptyString : hiddenClass}',
      tag: 'div',
      children: [
        Component.element(tag: 'ul', children: menuItems),
      ],
    );

    // Target area with contextmenu event
    final changed = onChanged;
    final targetArea = Component.element(
      events: changed == null
          ? null
          : {
              'contextmenu': (event) {
                // ignore: avoid-dynamic-calls, avoid-type-casts - DOM event handling requires dynamic access
                final _ = (event as dynamic).preventDefault();
                changed(state: true);
              },
            },
      tag: 'div',
      children: [targetChild],
    );

    // Overlay to close menu on outside click
    final overlay = open
        ? Component.element(
            classes: 'fixed inset-0 z-40',
            events: changed == null
                ? null
                : {'click': (_) => changed(state: false)},
            tag: 'div',
          )
        : null;

    return Component.element(
      attributes: componentAttributes,
      classes:
          '$combinedClasses${styles.isNotEmpty ? ' ${styles.join(' ')}' : emptyString}',
      css: this.css,
      id: id,
      tag: tag,
      children: [
        ?overlay,
        targetArea,
        contextMenuElement,
      ],
    );
  }

  @override
  ContextMenu copyWith({
    Map<String, String>? attributes,
    Component? child,
    String? classes,
    Styles? css,
    String? id,
    List<ContextMenuItem>? items,
    Key? key,
    BoolStateCallback? onChanged,
    bool? open,
    List<ContextMenuStyling>? style,
    String? tag,
    Component? targetChild,
  }) {
    return ContextMenu(
      attributes: attributes ?? userProvidedAttributes,
      child: child ?? this.child,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      id: id ?? this.id,
      items: items ?? this.items,
      key: key ?? this.key,
      onChanged: onChanged ?? this.onChanged,
      open: open ?? this.open,
      style: style,
      tag: tag ?? this.tag,
      targetChild: targetChild ?? this.targetChild,
    );
  }

  List<String> _buildStyleClasses() {
    final stylesList = <String>[];

    // Add custom styles
    final currentStyle = style;
    if (currentStyle != null) {
      for (final s in currentStyle) {
        stylesList.add(s.cssClass);
      }
    }

    return stylesList;
  }

  Component _buildMenuItem(ContextMenuItem item) {
    const emptyString = '';
    final disabled = item.disabled;
    final onPressed = item.onPressed;
    final label = item.label;
    final itemClasses = disabled ? 'disabled' : emptyString;
    final changed = onChanged;

    final itemContent = Component.element(
      classes: itemClasses,
      events: !disabled && onPressed != null
          ? {
              'click': (_) {
                final _ = onPressed();
                // Close menu after selection
                if (changed != null) {
                  changed(state: false);
                }
              },
            }
          : null,
      tag: 'a',
      children: [Component.text(label)],
    );

    return Component.element(tag: 'li', children: [itemContent]);
  }
}

/// Individual context menu item configuration.
class ContextMenuItem {
  /// Creates a ContextMenuItem.
  ///
  /// - [label]: Text label for the menu item.
  /// - [onPressed]: Callback when item is selected.
  /// - [disabled]: Whether the item is disabled.
  const ContextMenuItem({
    required this.label,
    this.onPressed,
    this.disabled = false,
  });

  /// Text label for the item.
  final String label;

  /// Callback when item is selected.
  ///
  /// Flutter-compatible void Function() callback.
  final VoidCallback? onPressed;

  /// Whether the item is disabled.
  final bool disabled;
}
