import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/components/overlay/popover/popover_style.dart';
import 'package:jaspr/jaspr.dart';

/// A popover component for displaying contextual content.
///
/// The Popover component shows additional content when triggered by
/// a user action. It follows DaisyUI's dropdown patterns (used for popovers)
/// and provides Flutter-compatible API.
///
/// Features:
/// - Click or hover trigger modes
/// - 4-directional positioning (top, bottom, left, right)
/// - State management for open/closed
/// - Accessibility with ARIA attributes
/// - DaisyUI dropdown classes
///
/// Example:
/// ```dart
/// Popover(
///   child: Button([text('Click me')]),
///   content: [
///     text('Popover content here'),
///   ],
///   position: PopoverPosition.bottom,
///   trigger: PopoverTrigger.click,
///   open: isOpen,
///   onChanged: (open) => setState(() => isOpen = open),
/// )
/// ```
class Popover extends UiComponent {
  /// Creates a Popover component.
  ///
  /// - [child]: Trigger element for the popover.
  /// - [content]: Content components displayed in popover.
  /// - [open]: Whether the popover is open.
  /// - [onChanged]: Callback when popover state changes (Flutter-compatible).
  /// - [position]: Position of popover relative to trigger.
  /// - [trigger]: Trigger mode (click or hover).
  /// - [style]: List of [PopoverStyling] instances for styling.
  const Popover({
    super.attributes,
    required this.child,
    super.classes,
    required this.content,
    super.css,
    super.id,
    super.key,
    this.onChanged,
    this.open = false,
    this.position = PopoverPosition.bottom,
    List<PopoverStyling>? style,
    super.tag = 'div',
    this.trigger = PopoverTrigger.click,
  }) : super(null, style: style);

  /// Trigger element for the popover.
  @override
  final Component child;

  /// Content components displayed in popover.
  final List<Component> content;

  /// Whether the popover is open.
  final bool open;

  /// Callback when popover state changes.
  ///
  /// Flutter-compatible void Function(bool) callback.
  /// Receives true when popover opens, false when it closes.
  final void Function(bool)? onChanged;

  /// Position of popover relative to trigger.
  final PopoverPosition position;

  /// Trigger mode (click or hover).
  final PopoverTrigger trigger;

  // --- Static Style Modifiers ---

  /// Hover trigger. `dropdown-hover`.
  static const hover = PopoverStyle('dropdown-hover', type: StyleType.state);

  /// Open state. `dropdown-open`.
  static const openState = PopoverStyle('dropdown-open', type: StyleType.state);

  @override
  String get baseClass => 'dropdown';

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);

    // Set ARIA attributes for accessibility
    if (!userProvidedAttributes.containsKey('role')) {
      attributes.addRole('button');
    }

    if (!userProvidedAttributes.containsKey('aria-haspopup')) {
      attributes.addAria('haspopup', 'true');
    }

    if (open) {
      attributes.addAria('expanded', 'true');
    } else {
      attributes.addAria('expanded', 'false');
    }
  }

  @override
  Component build(BuildContext context) {
    final styles = _buildStyleClasses();

    // Build popover content
    final popoverContent = Component.element(
      classes:
          'dropdown-content z-[1] menu p-2 shadow bg-base-100 rounded-box w-52',
      tag: 'div',
      children: content,
    );

    return Component.element(
      attributes: componentAttributes,
      classes:
          '$combinedClasses${styles.isNotEmpty ? ' ${styles.join(' ')}' : ''}',
      css: css,
      events: _buildEventHandlers(),
      id: id,
      tag: tag,
      children: [
        child,
        popoverContent,
      ],
    );
  }

  List<String> _buildStyleClasses() {
    final stylesList = <String>[];

    // Add position class
    stylesList.add(_getPositionClass());

    // Add trigger class
    if (trigger == PopoverTrigger.hover) {
      stylesList.add(hover.cssClass);
    }

    // Add open state
    if (open) {
      stylesList.add(openState.cssClass);
    }

    // Add custom styles
    if (style != null) {
      for (final s in style!) {
        if (s is PopoverStyling) {
          stylesList.add(s.cssClass);
        }
      }
    }

    return stylesList;
  }

  String _getPositionClass() {
    switch (position) {
      case PopoverPosition.top:
        return 'dropdown-top';
      case PopoverPosition.bottom:
        return 'dropdown-bottom';
      case PopoverPosition.left:
        return 'dropdown-left';
      case PopoverPosition.right:
        return 'dropdown-right';
    }
  }

  Map<String, EventCallback>? _buildEventHandlers() {
    if (onChanged == null) {
      return null;
    }

    // For click trigger, toggle on click
    if (trigger == PopoverTrigger.click) {
      return {
        'click': (_) => onChanged!(!open),
      };
    }

    return null;
  }

  @override
  Popover copyWith({
    Map<String, String>? attributes,
    Component? child,
    String? classes,
    List<Component>? content,
    Styles? css,
    String? id,
    Key? key,
    void Function(bool)? onChanged,
    bool? open,
    PopoverPosition? position,
    List<PopoverStyling>? style,
    String? tag,
    PopoverTrigger? trigger,
  }) {
    return Popover(
      attributes: attributes ?? userProvidedAttributes,
      child: child ?? this.child,
      classes: mergeClasses(this.classes, classes),
      content: content ?? this.content,
      css: css ?? this.css,
      id: id ?? this.id,
      key: key ?? this.key,
      onChanged: onChanged ?? this.onChanged,
      open: open ?? this.open,
      position: position ?? this.position,
      style: style ??
          () {
            final currentStyle = this.style;
            return currentStyle is List<PopoverStyling>? ? currentStyle : null;
          }(),
      tag: tag ?? this.tag,
      trigger: trigger ?? this.trigger,
    );
  }
}

/// Position of the popover relative to trigger element.
enum PopoverPosition {
  /// Popover appears above the trigger.
  top,

  /// Popover appears below the trigger.
  bottom,

  /// Popover appears to the left of the trigger.
  left,

  /// Popover appears to the right of the trigger.
  right,
}

/// Trigger mode for showing the popover.
enum PopoverTrigger {
  /// Popover shows on click.
  click,

  /// Popover shows on hover.
  hover,
}