import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/components/display/accordion/accordion_style.dart';
import 'package:jaspr/jaspr.dart';

/// An accordion component for expandable/collapsible content sections.
///
/// The Accordion component allows organizing content into expandable panels
/// with either single or multiple expansion modes. It follows DaisyUI's
/// collapse component patterns.
///
/// Features:
/// - Single or multiple expansion modes
/// - Checkbox-based toggle (DaisyUI pattern)
/// - Arrow or plus icon indicators
/// - Support for disabled items
/// - Accessibility with ARIA attributes
///
/// Example:
/// ```dart
/// Accordion(
///   items: [
///     AccordionItem(
///       title: 'Section 1',
///       content: [text('Content for section 1')],
///     ),
///     AccordionItem(
///       title: 'Section 2',
///       content: [text('Content for section 2')],
///       expanded: true,
///     ),
///   ],
///   mode: AccordionMode.single,
///   onChanged: (index, isExpanded) => handleExpansion(index, isExpanded),
/// )
/// ```
class Accordion extends UiComponent {
  /// Creates an Accordion component.
  ///
  /// - [items]: List of accordion items.
  /// - [mode]: Expansion mode (single or multiple).
  /// - [onChanged]: Callback when item expansion changes (Flutter-compatible).
  /// - [icon]: Icon type to display (arrow or plus).
  /// - [style]: List of [AccordionStyling] instances for styling.
  const Accordion({
    super.attributes,
    super.child,
    super.classes,
    super.css,
    this.icon = AccordionIcon.arrow,
    super.id,
    required this.items,
    super.key,
    this.mode = AccordionMode.single,
    this.onChanged,
    List<AccordionStyling>? style,
    super.tag = 'div',
  }) : super(null, style: style);

  /// List of accordion items.
  final List<AccordionItem> items;

  /// Expansion mode (single or multiple).
  final AccordionMode mode;

  /// Callback when item expansion changes.
  ///
  /// Flutter-compatible void Function(int, bool) callback.
  /// Receives item index and new expanded state.
  final void Function(int, bool)? onChanged;

  /// Icon type to display.
  final AccordionIcon icon;

  // --- Static Style Modifiers ---

  /// Arrow icon style. `collapse-arrow`.
  static const arrow = AccordionStyle('collapse-arrow', type: StyleType.style);

  /// Plus icon style. `collapse-plus`.
  static const plus = AccordionStyle('collapse-plus', type: StyleType.style);

  @override
  String get baseClass => '';

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
    final accordionItems = <Component>[];

    for (var i = 0; i < items.length; i++) {
      accordionItems.add(_buildAccordionItem(items[i], i));
    }

    return Component.element(
      attributes: componentAttributes,
      classes:
          '$combinedClasses${styles.isNotEmpty ? ' ${styles.join(' ')}' : ''}',
      css: css,
      id: id,
      tag: tag,
      children: accordionItems,
    );
  }

  List<String> _buildStyleClasses() {
    final stylesList = <String>[];

    // Add custom styles
    if (style != null) {
      for (final s in style!) {
        if (s is AccordionStyling) {
          stylesList.add(s.cssClass);
        }
      }
    }

    return stylesList;
  }

  Component _buildAccordionItem(AccordionItem item, int index) {
    final itemId = 'accordion-item-$index';
    final iconClass = icon == AccordionIcon.plus
        ? 'collapse-plus'
        : 'collapse-arrow';

    final itemClasses = [
      'collapse',
      'bg-base-200',
      iconClass,
      if (item.disabled) 'collapse-disabled',
    ].join(' ');

    // Checkbox for expansion state (DaisyUI pattern)
    final checkbox = Component.element(
      attributes: {
        'type': item.disabled ? 'hidden' : 'checkbox',
        'id': itemId,
        if (item.expanded && !item.disabled) 'checked': '',
        if (mode == AccordionMode.single) 'name': 'accordion-group',
      },
      events: !item.disabled && onChanged != null
          ? {
              'change': (event) {
                final target = (event as dynamic).target;
                final isChecked = target.checked as bool;
                onChanged!(index, isChecked);
              },
            }
          : null,
      tag: 'input',
    );

    // Title section
    final titleSection = Component.element(
      attributes: {
        'for': item.disabled ? '' : itemId,
      },
      classes: 'collapse-title text-xl font-medium',
      tag: item.disabled ? 'div' : 'label',
      children: [Component.text(item.title)],
    );

    // Content section
    final contentSection = Component.element(
      classes: 'collapse-content',
      tag: 'div',
      children: item.content,
    );

    return Component.element(
      classes: itemClasses,
      tag: 'div',
      children: [
        checkbox,
        titleSection,
        contentSection,
      ],
    );
  }

  @override
  Accordion copyWith({
    Map<String, String>? attributes,
    Component? child,
    String? classes,
    Styles? css,
    AccordionIcon? icon,
    String? id,
    List<AccordionItem>? items,
    Key? key,
    AccordionMode? mode,
    void Function(int, bool)? onChanged,
    List<AccordionStyling>? style,
    String? tag,
  }) {
    return Accordion(
      attributes: attributes ?? userProvidedAttributes,
      child: child ?? this.child,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      icon: icon ?? this.icon,
      id: id ?? this.id,
      items: items ?? this.items,
      key: key ?? this.key,
      mode: mode ?? this.mode,
      onChanged: onChanged ?? this.onChanged,
      style:
          style ??
          () {
            final currentStyle = this.style;
            return currentStyle is List<AccordionStyling>?
                ? currentStyle
                : null;
          }(),
      tag: tag ?? this.tag,
    );
  }
}

/// Individual accordion item configuration.
class AccordionItem {
  /// Creates an AccordionItem.
  ///
  /// - [title]: Title text displayed in the header.
  /// - [content]: Content components displayed when expanded.
  /// - [expanded]: Whether the item is initially expanded.
  /// - [disabled]: Whether the item is disabled.
  const AccordionItem({
    required this.title,
    required this.content,
    this.expanded = false,
    this.disabled = false,
  });

  /// Title text displayed in the header.
  final String title;

  /// Content components displayed when expanded.
  final List<Component> content;

  /// Whether the item is initially expanded.
  final bool expanded;

  /// Whether the item is disabled.
  final bool disabled;
}

/// Expansion mode for accordion.
enum AccordionMode {
  /// Only one item can be expanded at a time.
  single,

  /// Multiple items can be expanded simultaneously.
  multiple,
}

/// Icon type for accordion items.
enum AccordionIcon {
  /// Arrow icon.
  arrow,

  /// Plus icon.
  plus,
}
