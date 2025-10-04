import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/types.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/components/menu/dropdown_menu/dropdown_menu_style.dart';
import 'package:jaspr/jaspr.dart';

/// A dropdown menu component for selectable options.
///
/// The DropdownMenu component provides a menu of selectable items
/// that appears when triggered. It follows DaisyUI's dropdown patterns
/// and provides Flutter-compatible API.
///
/// Features:
/// - Click or hover trigger modes
/// - 4-directional positioning
/// - Selectable menu items
/// - Disabled items support
/// - Menu styling with DaisyUI
///
/// Example:
/// ```dart
/// DropdownMenu(
///   trigger: Button([text('Menu')]),
///   items: [
///     DropdownMenuItem(
///       label: 'Option 1',
///       onPressed: () => handleOption1(),
///     ),
///     DropdownMenuItem(
///       label: 'Option 2',
///       onPressed: () => handleOption2(),
///     ),
///     DropdownMenuItem(
///       label: 'Disabled',
///       disabled: true,
///     ),
///   ],
///   position: DropdownPosition.bottom,
/// )
/// ```
class DropdownMenu extends UiComponent {
  /// Creates a DropdownMenu component.
  ///
  /// - [trigger]: Trigger element for the dropdown.
  /// - [items]: List of menu items.
  /// - [open]: Whether the dropdown is open.
  /// - [onChanged]: Callback when dropdown state changes (Flutter-compatible).
  /// - [position]: Position of dropdown relative to trigger.
  /// - [style]: List of [DropdownMenuStyling] instances for styling.
  const DropdownMenu({
    super.attributes,
    super.child,
    super.classes,
    super.css,
    super.id,
    required this.items,
    super.key,
    this.onChanged,
    this.open = false,
    this.position = DropdownPosition.bottom,
    List<DropdownMenuStyling>? style,
    super.tag = 'div',
    required this.trigger,
  }) : super(null, style: style);

  /// Trigger element for the dropdown.
  final Component trigger;

  /// List of menu items.
  final List<DropdownMenuItem> items;

  /// Whether the dropdown is open.
  final bool open;

  /// Callback when dropdown state changes.
  ///
  /// Flutter-compatible callback.
  /// Receives true when dropdown opens, false when it closes.
  final BoolStateCallback? onChanged;

  /// Position of dropdown relative to trigger.
  final DropdownPosition position;

  // --- Static Style Modifiers ---

  /// Hover trigger. `dropdown-hover`.
  static const hover = DropdownMenuStyle(
    'dropdown-hover',
    type: StyleType.state,
  );

  /// Open state. `dropdown-open`.
  static const openState = DropdownMenuStyle(
    'dropdown-open',
    type: StyleType.state,
  );

  @override
  String get baseClass => 'dropdown';

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);

    // Set ARIA attributes for accessibility
    if (!userProvidedAttributes.containsKey('role')) {
      attributes.addRole('menu');
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

    // Build dropdown content with menu
    final dropdownContent = Component.element(
      classes:
          'dropdown-content z-[1] menu p-2 shadow bg-base-100 rounded-box w-52',
      tag: 'div',
      children: [
        Component.element(tag: 'ul', children: menuItems),
      ],
    );

    const emptyString = '';

    return Component.element(
      attributes: componentAttributes,
      classes:
          '$combinedClasses${styles.isNotEmpty ? ' ${styles.join(' ')}' : emptyString}',
      css: this.css,
      id: id,
      tag: tag,
      children: [trigger, dropdownContent],
    );
  }

  @override
  DropdownMenu copyWith({
    Map<String, String>? attributes,
    Component? child,
    String? classes,
    Styles? css,
    String? id,
    List<DropdownMenuItem>? items,
    Key? key,
    BoolStateCallback? onChanged,
    bool? open,
    DropdownPosition? position,
    List<DropdownMenuStyling>? style,
    String? tag,
    Component? trigger,
  }) {
    return DropdownMenu(
      attributes: attributes ?? userProvidedAttributes,
      child: child ?? this.child,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      id: id ?? this.id,
      items: items ?? this.items,
      key: key ?? this.key,
      onChanged: onChanged ?? this.onChanged,
      open: open ?? this.open,
      position: position ?? this.position,
      style: style,
      tag: tag ?? this.tag,
      trigger: trigger ?? this.trigger,
    );
  }

  List<String> _buildStyleClasses() {
    final stylesList = <String>[];

    // Add position class
    stylesList.add(_positionClass);

    // Add open state
    if (open) {
      stylesList.add(openState.cssClass);
    }

    // Add custom styles
    final currentStyle = style;
    if (currentStyle != null) {
      for (final s in currentStyle) {
        stylesList.add(s.cssClass);
      }
    }

    return stylesList;
  }

  String get _positionClass => switch (position) {
        DropdownPosition.top => 'dropdown-top',
        DropdownPosition.bottom => 'dropdown-bottom',
        DropdownPosition.left => 'dropdown-left',
        DropdownPosition.right => 'dropdown-right',
      };

  static Component _buildMenuItem(DropdownMenuItem item) {
    const emptyString = '';
    final disabled = item.disabled;
    final onPressed = item.onPressed;
    final label = item.label;
    final itemClasses = disabled ? 'disabled' : emptyString;

    final itemContent = Component.element(
      classes: itemClasses,
      events: !disabled && onPressed != null
          ? {'click': (_) => onPressed()}
          : null,
      tag: 'a',
      children: [Component.text(label)],
    );

    return Component.element(tag: 'li', children: [itemContent]);
  }
}

/// Individual dropdown menu item configuration.
class DropdownMenuItem {
  /// Creates a DropdownMenuItem.
  ///
  /// - [label]: Text label for the menu item.
  /// - [onPressed]: Callback when item is selected.
  /// - [disabled]: Whether the item is disabled.
  const DropdownMenuItem({
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

/// Position of the dropdown menu relative to trigger.
enum DropdownPosition {
  /// Dropdown appears below the trigger.
  bottom,

  /// Dropdown appears to the left of the trigger.
  left,

  /// Dropdown appears to the right of the trigger.
  right,

  /// Dropdown appears above the trigger.
  top,
}
