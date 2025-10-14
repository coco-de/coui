import 'package:coui_web/src/base/ui_component.dart';
import 'package:jaspr/jaspr.dart';

/// Callback signature for context menu item selection.
typedef ContextMenuItemCallback = void Function();

/// A context menu component (right-click menu) following shadcn-ui patterns.
///
/// Example:
/// ```dart
/// ContextMenu(
///   child: div(child: text('Right-click me')),
///   items: [
///     ContextMenuItem(label: 'Copy', onSelect: () {}),
///     ContextMenuItem(label: 'Paste', onSelect: () {}),
///   ],
/// )
/// ```
class ContextMenu extends UiComponent {
  /// Creates a ContextMenu component.
  ///
  /// Parameters:
  /// - [child]: Trigger content
  /// - [items]: Context menu items
  const ContextMenu({
    super.key,
    required Component this.triggerChild,
    required this.items,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(null);

  /// Trigger content.
  final Component triggerChild;

  /// Menu items.
  final List<Component> items;

  static const _divValue = 'div';

  @override
  ContextMenu copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    Component? triggerChild,
    List<Component>? items,
    Key? key,
  }) {
    return ContextMenu(
      key: key ?? this.key,
      triggerChild: triggerChild ?? this.triggerChild,
      items: items ?? this.items,
      attributes: attributes ?? this.componentAttributes,
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
      attributes: {
        ...this.componentAttributes,
        'data-context-menu': '',
      },
      events: _buildEvents(),
      children: [
        triggerChild,
        // Context menu (hidden by default, shown on contextmenu event)
        div(
          classes:
              'absolute z-50 min-w-[8rem] overflow-hidden rounded-md border bg-popover p-1 text-popover-foreground shadow-md hidden',
          attributes: {
            'data-context-menu-content': '',
          },
          children: items,
        ),
      ],
    );
  }

  @override
  String get baseClass => 'relative';

  String _buildClasses() {
    final classList = [baseClass];

    final currentClasses = classes;
    if (currentClasses != null && currentClasses.isNotEmpty) {
      classList.add(currentClasses);
    }

    return classList.join(' ');
  }

  static Map<String, List<dynamic>> _buildEvents() {
    final eventMap = <String, List<dynamic>>{};

    // Add contextmenu event handler
    eventMap['contextmenu'] = [
      (event) {
        // Prevent default context menu and show custom menu
        // This would need JS implementation
      },
    ];

    return eventMap;
  }
}

/// A context menu item component.
class ContextMenuItem extends UiComponent {
  /// Creates a ContextMenuItem component.
  const ContextMenuItem({
    super.key,
    required this.label,
    this.onSelect,
    this.icon,
    this.shortcut,
    this.disabled = false,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(null);

  /// Menu item label.
  final String label;

  /// Selection callback.
  final ContextMenuItemCallback? onSelect;

  /// Optional icon.
  final Component? icon;

  /// Optional keyboard shortcut display.
  final String? shortcut;

  /// Whether the item is disabled.
  final bool disabled;

  static const _divValue = 'div';

  @override
  ContextMenuItem copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    String? label,
    ContextMenuItemCallback? onSelect,
    Component? icon,
    String? shortcut,
    bool? disabled,
    String? tag,
  }) {
    return ContextMenuItem(
      key: key ?? this.key,
      label: label ?? this.label,
      onSelect: onSelect ?? this.onSelect,
      icon: icon ?? this.icon,
      shortcut: shortcut ?? this.shortcut,
      disabled: disabled ?? this.disabled,
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

    children.add(span(child: text(label)));

    final currentShortcut = shortcut;
    if (currentShortcut != null) {
      children.add(
        span(
          classes: 'ml-auto text-xs tracking-widest opacity-60',
          child: text(currentShortcut),
        ),
      );
    }

    return div(
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: {
        ...this.componentAttributes,
        'role': 'menuitem',
        if (disabled) 'data-disabled': '',
      },
      events: _buildEvents(),
      children: children,
    );
  }

  @override
  String get baseClass =>
      'relative flex cursor-default select-none items-center rounded-sm px-2 py-1.5 text-sm outline-none transition-colors hover:bg-accent hover:text-accent-foreground data-[disabled]:pointer-events-none data-[disabled]:opacity-50';

  String _buildClasses() {
    final classList = [baseClass];

    final currentClasses = classes;
    if (currentClasses != null && currentClasses.isNotEmpty) {
      classList.add(currentClasses);
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
