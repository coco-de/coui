import 'package:coui_web/src/base/ui_component.dart';
import 'package:jaspr/jaspr.dart';

/// Callback signature for menu item selection.
typedef MenuItemCallback = void Function();

/// A dropdown menu component following shadcn-ui design patterns.
///
/// Example:
/// ```dart
/// DropdownMenu(
///   trigger: Button.outline(child: text('Menu')),
///   items: [
///     DropdownMenuItem(label: 'Item 1', onSelect: () {}),
///     DropdownMenuItem(label: 'Item 2', onSelect: () {}),
///   ],
/// )
/// ```
class DropdownMenu extends UiComponent {
  /// Creates a DropdownMenu component.
  ///
  /// Parameters:
  /// - [trigger]: Component that opens the menu
  /// - [items]: List of menu items
  const DropdownMenu({
    super.key,
    required this.trigger,
    required this.items,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(null);

  /// Trigger component.
  final Component trigger;

  /// Menu items.
  final List<Component> items;

  static const _divValue = 'div';

  @override
  DropdownMenu copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    Component? trigger,
    List<Component>? items,
    Key? key,
  }) {
    return DropdownMenu(
      key: key ?? this.key,
      trigger: trigger ?? this.trigger,
      items: items ?? this.items,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  Component build(BuildContext context) {
    return div(
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: this.componentAttributes,
      events: this.events,
      children: [
        trigger,
        // Menu content (controlled by JS or state management)
        div(
          classes:
              'absolute right-0 z-10 mt-2 w-56 origin-top-right rounded-md bg-background shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none hidden group-hover:block',
          child: div(
            classes: 'py-1',
            children: items,
          ),
        ),
      ],
    );
  }

  @override
  String get baseClass => 'relative inline-block text-left';

  String _buildClasses() {
    final classList = [baseClass];

    if (classes != null && classes!.isNotEmpty) {
      classList.add(classes!);
    }

    return classList.join(' ');
  }
}

/// A dropdown menu item component.
class DropdownMenuItem extends UiComponent {
  /// Creates a DropdownMenuItem component.
  const DropdownMenuItem({
    super.key,
    required this.label,
    this.onSelect,
    this.icon,
    this.disabled = false,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _buttonValue,
  }) : super(null);

  /// Menu item label.
  final String label;

  /// Selection callback.
  final MenuItemCallback? onSelect;

  /// Optional icon.
  final Component? icon;

  /// Whether the item is disabled.
  final bool disabled;

  static const _buttonValue = 'button';

  @override
  DropdownMenuItem copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    List<Component>? children,
    String? label,
    MenuItemCallback? onSelect,
    Component? icon,
    bool? disabled,
    Key? key,
  }) {
    return DropdownMenuItem(
      key: key ?? this.key,
      label: label ?? this.label,
      onSelect: onSelect ?? this.onSelect,
      icon: icon ?? this.icon,
      disabled: disabled ?? this.disabled,
      children: children ?? this.children,
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

    final currentIcon = icon;
    if (currentIcon != null) {
      children.add(currentIcon);
    }

    children.add(text(label));

    return button(
      id: id,
      classes: _buildClasses(),
      styles: css,
      attributes: {
        ...componentAttributes,
        'type': 'button',
        'role': 'menuitem',
        if (disabled) 'disabled': '',
      },
      events: _buildEvents(),
      children: children,
    );
  }

  @override
  String get baseClass =>
      'w-full text-left px-4 py-2 text-sm text-foreground hover:bg-accent hover:text-accent-foreground disabled:opacity-50 disabled:pointer-events-none flex items-center gap-2';

  String _buildClasses() {
    final classList = [baseClass];

    if (classes != null && classes!.isNotEmpty) {
      classList.add(classes!);
    }

    return classList.join(' ');
  }

  Map<String, List<dynamic>> _buildEvents() {
    final eventMap = <String, List<dynamic>>{};

    final currentOnSelect = onSelect;
    if (currentOnSelect != null && !disabled) {
      eventMap['click'] = [
        (event) => currentOnSelect(),
      ];
    }

    return eventMap;
  }
}
