import 'package:coui_web/src/base/ui_component.dart';
import 'package:jaspr/jaspr.dart';

/// A tabs component for organizing content into selectable sections.
///
/// Example:
/// ```dart
/// Tabs(
///   defaultValue: 'tab1',
///   children: [
///     TabsList(
///       children: [
///         TabsTrigger(value: 'tab1', label: 'Tab 1'),
///         TabsTrigger(value: 'tab2', label: 'Tab 2'),
///       ],
///     ),
///     TabsContent(value: 'tab1', child: text('Content 1')),
///     TabsContent(value: 'tab2', child: text('Content 2')),
///   ],
/// )
/// ```
class Tabs extends UiComponent {
  /// Creates a Tabs component.
  Tabs({
    super.key,
    required List<Component> children,
    this.defaultValue,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(children);

  /// Default selected tab value.
  final String? defaultValue;

  static const _divValue = 'div';

  @override
  Tabs copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    String? defaultValue,
    List<Component>? children,
    Key? key,
  }) {
    return Tabs(
      key: key ?? this.key,
      defaultValue: defaultValue ?? this.defaultValue,
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
    return Component.element(
      tag: tag,
      id: id,
      classes: _buildClasses(),
      styles: css,
      attributes: {
        ...componentAttributes,
        if (defaultValue != null) 'data-value': defaultValue!,
      },
      events: events,
      children: children,
    );
  }

  @override
  String get baseClass => 'w-full';

  String _buildClasses() {
    final classList = [baseClass];

    if (classes != null && classes!.isNotEmpty) {
      classList.add(classes!);
    }

    return classList.join(' ');
  }
}

/// Tabs list component (tab buttons container).
class TabsList extends UiComponent {
  /// Creates a TabsList component.
  TabsList({
    super.key,
    required List<Component> children,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(children);

  static const _divValue = 'div';

  @override
  TabsList copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    List<Component>? children,
    Key? key,
  }) {
    return TabsList(
      key: key ?? this.key,
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
    return Component.element(
      tag: tag,
      id: id,
      classes: _buildClasses(),
      styles: css,
      attributes: this.componentAttributes,
      events: this.events,
      children: children,
    );
  }

  @override
  String get baseClass =>
      'inline-flex h-10 items-center justify-center rounded-md bg-muted p-1 text-muted-foreground';

  String _buildClasses() {
    final classList = [baseClass];

    if (classes != null && classes!.isNotEmpty) {
      classList.add(classes!);
    }

    return classList.join(' ');
  }
}

/// Tabs trigger component (tab button).
class TabsTrigger extends UiComponent {
  /// Creates a TabsTrigger component.
  const TabsTrigger({
    super.key,
    required this.value,
    required this.label,
    this.isActive = false,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _buttonValue,
  }) : super(null);

  /// Value identifier for this tab.
  final String value;

  /// Label text for the tab.
  final String label;

  /// Whether this tab is active.
  final bool isActive;

  static const _buttonValue = 'button';

  @override
  TabsTrigger copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    Component? child,
    bool? isActive,
    String? value,
    String? label,
    Key? key,
  }) {
    return TabsTrigger(
      key: key ?? this.key,
      value: value ?? this.value,
      label: label ?? this.label,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
      child: child ?? this.child,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  Component build(BuildContext context) {
    return Component.element(
      tag: tag,
      id: id,
      classes: _buildClasses(),
      styles: css,
      attributes: {
        ...componentAttributes,
        'type': 'button',
        'role': 'tab',
        'data-value': value,
        'data-state': isActive ? 'active' : 'inactive',
      },
      events: events,
      child: text(label),
    );
  }

  @override
  String get baseClass =>
      'inline-flex items-center justify-center whitespace-nowrap rounded-sm px-3 py-1.5 text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm';

  String _buildClasses() {
    final classList = [baseClass];

    if (classes != null && classes!.isNotEmpty) {
      classList.add(classes!);
    }

    return classList.join(' ');
  }
}

/// Tabs content component (tab panel).
class TabsContent extends UiComponent {
  /// Creates a TabsContent component.
  TabsContent({
    super.key,
    required this.value,
    Component? child,
    this.isActive = false,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(null, child: child);

  /// Value identifier for this content.
  final String value;

  /// Whether this content is active.
  final bool isActive;

  static const _divValue = 'div';

  @override
  TabsContent copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    Component? child,
    bool? isActive,
    String? value,
    Key? key,
  }) {
    return TabsContent(
      key: key ?? this.key,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
      child: child ?? this.child,
      isActive: isActive ?? this.isActive,
      value: value ?? this.value,
    );
  }

  @override
  Component build(BuildContext context) {
    return isActive
        ? Component.element(
            tag: tag,
            id: id,
            classes: _buildClasses(),
            styles: css,
            attributes: {
              ...componentAttributes,
              'role': 'tabpanel',
              'data-value': value,
              'data-state': isActive ? 'active' : 'inactive',
            },
            events: events,
            child: child,
          )
        : Component.fragment(children: []);
  }

  @override
  String get baseClass =>
      'mt-2 ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2';

  String _buildClasses() {
    final classList = [baseClass];

    if (classes != null && classes!.isNotEmpty) {
      classList.add(classes!);
    }

    return classList.join(' ');
  }
}
