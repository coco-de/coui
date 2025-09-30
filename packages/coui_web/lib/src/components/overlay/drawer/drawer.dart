import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/components/overlay/drawer/drawer_style.dart';
import 'package:jaspr/jaspr.dart';

/// A drawer component for side navigation panels.
///
/// The Drawer component provides a slide-out panel for navigation or
/// additional content. It follows DaisyUI's drawer patterns and provides
/// Flutter-compatible API.
///
/// Features:
/// - Left or right positioning
/// - Optional backdrop overlay
/// - Separate main content and drawer content areas
/// - Checkbox-based toggle mechanism (DaisyUI pattern)
/// - Accessibility support
///
/// Example:
/// ```dart
/// Drawer(
///   content: [
///     text('Main content area'),
///   ],
///   sideContent: [
///     text('Drawer navigation'),
///   ],
///   open: drawerOpen,
///   onChanged: (isOpen) => setState(() => drawerOpen = isOpen),
///   position: DrawerPosition.left,
///   overlay: true,
/// )
/// ```
class Drawer extends UiComponent {
  /// Creates a Drawer component.
  ///
  /// - [content]: Main content area components.
  /// - [sideContent]: Drawer side panel components.
  /// - [open]: Whether the drawer is open.
  /// - [onChanged]: Callback when drawer state changes (Flutter-compatible).
  /// - [position]: Position of drawer (left or right).
  /// - [overlay]: Whether to show backdrop overlay.
  /// - [style]: List of [DrawerStyling] instances for styling.
  const Drawer({
    super.attributes,
    super.child,
    super.classes,
    required this.content,
    super.css,
    super.id,
    super.key,
    this.onChanged,
    this.open = false,
    this.overlay = true,
    this.position = DrawerPosition.left,
    required this.sideContent,
    List<DrawerStyling>? style,
    super.tag = 'div',
  }) : super(null, style: style);

  /// Main content area components.
  final List<Component> content;

  /// Drawer side panel components.
  final List<Component> sideContent;

  /// Whether the drawer is open.
  final bool open;

  /// Callback when drawer state changes.
  ///
  /// Flutter-compatible void Function(bool) callback.
  /// Receives true when drawer opens, false when it closes.
  final void Function(bool)? onChanged;

  /// Position of the drawer.
  final DrawerPosition position;

  /// Whether to show backdrop overlay.
  final bool overlay;

  // --- Static Style Modifiers ---

  /// Right-side drawer. `drawer-end`.
  static const end = DrawerStyle('drawer-end', type: StyleType.layout);

  // Checkbox ID for drawer toggle
  static const _drawerId = 'drawer-toggle';

  @override
  String get baseClass => 'drawer';

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);

    // Set ARIA attributes for accessibility
    if (!userProvidedAttributes.containsKey('role')) {
      attributes.addRole('navigation');
    }
  }

  @override
  Component build(BuildContext context) {
    final styles = _buildStyleClasses();

    // Drawer toggle checkbox (DaisyUI pattern)
    final toggleCheckbox = Component.element(
      attributes: {
        'type': 'checkbox',
        'id': _drawerId,
        if (open) 'checked': '',
      },
      classes: 'drawer-toggle',
      events: onChanged != null
          ? {
              'change': (event) {
                final target = (event as dynamic).target;
                final isChecked = target.checked as bool;
                onChanged!(isChecked);
              },
            }
          : null,
      tag: 'input',
    );

    // Main content area
    final contentArea = Component.element(
      classes: 'drawer-content',
      tag: 'div',
      children: content,
    );

    // Drawer side panel
    final sidePanel = Component.element(
      classes: 'drawer-side',
      tag: 'div',
      children: [
        // Overlay label (closes drawer when clicked)
        if (overlay)
          Component.element(
            attributes: {
              'for': _drawerId,
            },
            classes: 'drawer-overlay',
            tag: 'label',
          ),
        // Drawer content menu
        Component.element(
          classes: 'menu p-4 w-80 min-h-full bg-base-200 text-base-content',
          tag: 'ul',
          children: sideContent,
        ),
      ],
    );

    return Component.element(
      attributes: componentAttributes,
      classes:
          '$combinedClasses${styles.isNotEmpty ? ' ${styles.join(' ')}' : ''}',
      css: css,
      id: id,
      tag: tag,
      children: [
        toggleCheckbox,
        contentArea,
        sidePanel,
      ],
    );
  }

  List<String> _buildStyleClasses() {
    final stylesList = <String>[];

    // Add position style
    if (position == DrawerPosition.right) {
      stylesList.add(end.cssClass);
    }

    // Add custom styles
    if (style != null) {
      for (final s in style!) {
        if (s is DrawerStyling) {
          stylesList.add(s.cssClass);
        }
      }
    }

    return stylesList;
  }

  @override
  Drawer copyWith({
    Map<String, String>? attributes,
    Component? child,
    String? classes,
    List<Component>? content,
    Styles? css,
    String? id,
    Key? key,
    void Function(bool)? onChanged,
    bool? open,
    bool? overlay,
    DrawerPosition? position,
    List<Component>? sideContent,
    List<DrawerStyling>? style,
    String? tag,
  }) {
    return Drawer(
      attributes: attributes ?? userProvidedAttributes,
      child: child ?? this.child,
      classes: mergeClasses(this.classes, classes),
      content: content ?? this.content,
      css: css ?? this.css,
      id: id ?? this.id,
      key: key ?? this.key,
      onChanged: onChanged ?? this.onChanged,
      open: open ?? this.open,
      overlay: overlay ?? this.overlay,
      position: position ?? this.position,
      sideContent: sideContent ?? this.sideContent,
      style: style ??
          () {
            final currentStyle = this.style;
            return currentStyle is List<DrawerStyling>? ? currentStyle : null;
          }(),
      tag: tag ?? this.tag,
    );
  }
}

/// Position of the drawer panel.
enum DrawerPosition {
  /// Drawer slides from the left side.
  left,

  /// Drawer slides from the right side.
  right,
}