import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/components/navigation/tabs/tabs_style.dart';
import 'package:jaspr/jaspr.dart';

/// A tab navigation component for organizing content into multiple panels.
///
/// The Tabs component provides a tabbed interface where users can switch
/// between different content panels. It follows DaisyUI's tabs patterns
/// and provides Flutter-compatible API.
///
/// Features:
/// - Multiple tab styles (boxed, lifted, bordered)
/// - Active tab indication
/// - Keyboard navigation support
/// - Flutter-style onChanged callback
/// - Responsive design
///
/// Example:
/// ```dart
/// Tabs(
///   selectedIndex: 0,
///   onChanged: (index) => setState(() => currentTab = index),
///   tabs: [
///     Tab(label: 'Tab 1', content: [text('Content 1')]),
///     Tab(label: 'Tab 2', content: [text('Content 2')]),
///     Tab(label: 'Tab 3', content: [text('Content 3')]),
///   ],
///   style: [Tabs.boxed],
/// )
/// ```
class Tabs extends UiComponent {
  /// Creates a Tabs component.
  ///
  /// - [tabs]: List of Tab configurations.
  /// - [selectedIndex]: Index of the currently selected tab.
  /// - [onChanged]: Callback when tab selection changes (Flutter-compatible).
  /// - [style]: List of [TabsStyling] instances for styling.
  const Tabs({
    super.attributes,
    super.child,
    super.classes,
    super.css,
    super.id,
    super.key,
    this.onChanged,
    this.selectedIndex = 0,
    List<TabsStyling>? style,
    super.tag = 'div',
    required this.tabs,
  }) : super(null, style: style);

  /// List of tab configurations.
  final List<Tab> tabs;

  /// Index of the currently selected tab.
  final int selectedIndex;

  /// Callback when tab selection changes.
  ///
  /// Flutter-compatible void Function(int) callback.
  /// Receives the index of the newly selected tab.
  final void Function(int)? onChanged;

  // --- Static Style Modifiers ---

  /// Boxed style tabs. `tabs-boxed`.
  static const boxed = TabsStyle('tabs-boxed', type: StyleType.style);

  /// Lifted style tabs. `tabs-lifted`.
  static const lifted = TabsStyle('tabs-lifted', type: StyleType.style);

  /// Bordered style tabs. `tabs-bordered`.
  static const bordered = TabsStyle('tabs-bordered', type: StyleType.style);

  /// Large size. `tabs-lg`.
  static const lg = TabsStyle('tabs-lg', type: StyleType.sizing);

  /// Medium size. `tabs-md`.
  static const md = TabsStyle('tabs-md', type: StyleType.sizing);

  /// Small size. `tabs-sm`.
  static const sm = TabsStyle('tabs-sm', type: StyleType.sizing);

  /// Extra small size. `tabs-xs`.
  static const xs = TabsStyle('tabs-xs', type: StyleType.sizing);

  // HTML/ARIA attribute constants
  static const _roleAttribute = 'role';
  static const _tablistRole = 'tablist';

  @override
  String get baseClass => 'tabs';

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);

    // Set ARIA role for accessibility
    if (!userProvidedAttributes.containsKey(_roleAttribute)) {
      attributes.addRole(_tablistRole);
    }
  }

  @override
  Component build(BuildContext context) {
    final styles = _buildStyleClasses();

    // Build tab buttons
    final tabButtons = <Component>[];
    for (var i = 0; i < tabs.length; i++) {
      final tab = tabs[i];
      final isActive = i == selectedIndex;
      tabButtons.add(_buildTabButton(tab, i, isActive));
    }

    // Build tab content
    final tabContent = _buildTabContent();

    return Component.element(
      tag: 'div',
      classes: 'w-full',
      children: [
        // Tab buttons container
        Component.element(
          attributes: componentAttributes,
          classes:
              '$combinedClasses${styles.isNotEmpty ? ' ${styles.join(' ')}' : ''}',
          css: css,
          id: id,
          tag: tag,
          children: tabButtons,
        ),
        // Tab content container
        if (tabContent != null) tabContent,
      ],
    );
  }

  List<String> _buildStyleClasses() {
    final stylesList = <String>[];

    if (style != null) {
      for (final s in style!) {
        if (s is TabsStyling) {
          stylesList.add(s.cssClass);
        }
      }
    }

    return stylesList;
  }

  Component _buildTabButton(Tab tab, int index, bool isActive) {
    final classNames = isActive ? 'tab tab-active' : 'tab';

    return Component.element(
      attributes: {
        'role': 'tab',
        'aria-selected': isActive ? 'true' : 'false',
        'tabindex': isActive ? '0' : '-1',
      },
      classes: classNames,
      events: onChanged != null
          ? {
              'click': (_) => onChanged!(index),
            }
          : null,
      tag: 'a',
      children: [Component.text(tab.label)],
    );
  }

  Component? _buildTabContent() {
    if (selectedIndex >= 0 && selectedIndex < tabs.length) {
      final tab = tabs[selectedIndex];
      if (tab.content.isNotEmpty) {
        return Component.element(
          attributes: {
            'role': 'tabpanel',
          },
          classes: 'p-4',
          tag: 'div',
          children: tab.content,
        );
      }
    }
    return null;
  }

  @override
  Tabs copyWith({
    Map<String, String>? attributes,
    Component? child,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    void Function(int)? onChanged,
    int? selectedIndex,
    List<TabsStyling>? style,
    String? tag,
    List<Tab>? tabs,
  }) {
    return Tabs(
      attributes: attributes ?? userProvidedAttributes,
      child: child ?? this.child,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      id: id ?? this.id,
      key: key ?? this.key,
      onChanged: onChanged ?? this.onChanged,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      style: style ??
          () {
            final currentStyle = this.style;
            return currentStyle is List<TabsStyling>? ? currentStyle : null;
          }(),
      tag: tag ?? this.tag,
      tabs: tabs ?? this.tabs,
    );
  }
}

/// Individual tab configuration.
///
/// Represents a single tab with its label and content.
class Tab {
  /// Creates a Tab.
  ///
  /// - [label]: Text label displayed on the tab button.
  /// - [content]: Content components displayed when tab is active.
  const Tab({
    required this.label,
    this.content = const [],
  });

  /// Text label for the tab button.
  final String label;

  /// Content components for this tab panel.
  final List<Component> content;
}