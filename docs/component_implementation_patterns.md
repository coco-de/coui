# coui_web Component Implementation Patterns

## Overview

This document describes the established patterns for implementing coui_web components based on three sample implementations: Dialog (high complexity), Tabs (medium complexity), and Tooltip (low complexity).

All patterns are derived from successful implementations in:
- `/packages/coui_web/lib/src/components/overlay/dialog/`
- `/packages/coui_web/lib/src/components/navigation/tabs/`
- `/packages/coui_web/lib/src/components/overlay/tooltip/`

## Core Architecture Pattern

### File Structure

Every component requires exactly 2 files:

```
src/components/{category}/{component_name}/
├── {component_name}.dart        # Main component implementation
└── {component_name}_style.dart  # Style configuration
```

**Examples**:
- `dialog/dialog.dart` + `dialog/dialog_style.dart`
- `tabs/tabs.dart` + `tabs/tabs_style.dart`
- `tooltip/tooltip.dart` + `tooltip/tooltip_style.dart`

### Style Pattern

Every component must follow this exact style pattern:

```dart
// {component_name}_style.dart
import 'package:coui_web/src/base/style_type.dart';

/// Style configuration for {ComponentName} components.
abstract class {ComponentName}Styling {
  /// The CSS class name for this style.
  String get cssClass;

  /// The type of style this represents.
  StyleType get type;
}

/// Concrete implementation of {component_name} styles.
class {ComponentName}Style implements {ComponentName}Styling {
  /// Creates a [{ComponentName}Style].
  const {ComponentName}Style(this.cssClass, {required this.type});

  @override
  final String cssClass;

  @override
  final StyleType type;
}
```

**Key Points**:
- Abstract interface: `{ComponentName}Styling`
- Concrete implementation: `{ComponentName}Style`
- Two properties: `cssClass` (String) and `type` (StyleType)
- Use `final` for properties, NOT `get` keyword

### Component Class Pattern

```dart
// {component_name}.dart
import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/components/{category}/{component_name}/{component_name}_style.dart';
import 'package:jaspr/jaspr.dart';

/// A {component_name} component for {purpose}.
///
/// {Detailed description of what the component does}
///
/// Features:
/// - {Feature 1}
/// - {Feature 2}
///
/// Example:
/// ```dart
/// {ComponentName}(
///   {example_usage},
/// )
/// ```
class {ComponentName} extends UiComponent {
  /// Creates a {ComponentName} component.
  const {ComponentName}(
    super.children, {  // or super(null) if no children
    super.attributes,
    super.child,
    super.classes,
    super.css,
    super.id,
    super.key,
    // ... component-specific properties
    List<{ComponentName}Styling>? style,
    super.tag = 'div',  // or appropriate HTML tag
  }) : super(style: style);

  // --- Component Properties ---

  // --- Static Style Modifiers ---
  static const example = {ComponentName}Style('css-class', type: StyleType.style);

  @override
  String get baseClass => 'base-css-class';

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);
    // Add HTML/ARIA attributes
  }

  @override
  Component build(BuildContext context) {
    // Build component structure
  }

  @override
  {ComponentName} copyWith({
    // All parameters as optional
  }) {
    return {ComponentName}(
      // Copy logic
    );
  }
}
```

## Pattern by Complexity Level

### Low Complexity: Tooltip Pattern

**Characteristics**:
- Simple hover behavior
- No state management
- Single child element
- DaisyUI data-attribute pattern

**Implementation Pattern**:

```dart
class Tooltip extends UiComponent {
  const Tooltip({
    super.attributes,
    required this.child,
    super.classes,
    super.css,
    super.id,
    super.key,
    required this.message,  // Required property
    this.open = false,      // Boolean state
    this.position = TooltipPosition.top,  // Enum with default
    List<TooltipStyling>? style,
    super.tag = 'div',
  }) : super(null, style: style);  // Note: super(null) for single child

  final String message;
  @override
  final Component child;
  final TooltipPosition position;
  final bool open;

  // Color variants as static constants
  static const primary = TooltipStyle('tooltip-primary', type: StyleType.style);
  static const secondary = TooltipStyle('tooltip-secondary', type: StyleType.style);
  // ... more variants

  @override
  String get baseClass => 'tooltip';

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);
    attributes.add('data-tip', message);  // DaisyUI data-attribute
  }

  @override
  Component build(BuildContext context) {
    final stylesList = <String>[];
    stylesList.add(_getPositionClass());  // Add position
    if (style != null) {
      for (final s in style!) {
        if (s is TooltipStyling) {
          stylesList.add(s.cssClass);
        }
      }
    }
    if (open) {
      stylesList.add('tooltip-open');
    }

    return Component.element(
      attributes: componentAttributes,
      classes: '$combinedClasses${stylesList.isNotEmpty ? ' ${stylesList.join(' ')}' : ''}',
      css: css,
      id: id,
      tag: tag,
      children: [child],
    );
  }

  String _getPositionClass() {
    switch (position) {
      case TooltipPosition.top: return 'tooltip-top';
      case TooltipPosition.bottom: return 'tooltip-bottom';
      case TooltipPosition.left: return 'tooltip-left';
      case TooltipPosition.right: return 'tooltip-right';
    }
  }
}

/// Supporting enum for position
enum TooltipPosition {
  top,
  bottom,
  left,
  right,
}
```

**Key Takeaways for Low Complexity**:
- Use enum for fixed option sets
- DaisyUI data-attributes for behavior
- Simple switch statement for class mapping
- Boolean flags for states

### Medium Complexity: Tabs Pattern

**Characteristics**:
- State management (selectedIndex)
- Event callbacks with parameters
- Dynamic child iteration
- Conditional rendering

**Implementation Pattern**:

```dart
class Tabs extends UiComponent {
  const Tabs(
    super.children, {  // Accept children list
    super.attributes,
    super.child,
    super.classes,
    super.css,
    super.id,
    super.key,
    this.onChanged,           // Flutter-compatible callback
    this.selectedIndex = 0,   // State management
    List<TabsStyling>? style,
    super.tag = 'div',
  }) : super(style: style);

  final int selectedIndex;

  /// Callback when tab selection changes.
  /// Flutter-compatible void Function(int) callback.
  final void Function(int)? onChanged;

  // Style variants (multiple categories)
  static const boxed = TabsStyle('tabs-boxed', type: StyleType.style);
  static const lifted = TabsStyle('tabs-lifted', type: StyleType.style);
  static const lg = TabsStyle('tabs-lg', type: StyleType.sizing);
  static const md = TabsStyle('tabs-md', type: StyleType.sizing);

  @override
  String get baseClass => 'tabs';

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);
    if (!userProvidedAttributes.containsKey('role')) {
      attributes.addRole('tablist');
    }
  }

  @override
  Component build(BuildContext context) {
    final styles = _buildStyleClasses();

    // Build tab buttons from children
    final tabButtons = <Component>[];
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      if (child is Tab) {
        final isActive = i == selectedIndex;
        tabButtons.add(_buildTabButton(child, i, isActive));
      }
    }

    // Build selected tab content
    final tabContent = _buildTabContent();

    return Component.element(
      tag: 'div',
      classes: 'w-full',
      children: [
        // Tab buttons container
        Component.element(
          attributes: componentAttributes,
          classes: '$combinedClasses${styles.isNotEmpty ? ' ${styles.join(' ')}' : ''}',
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

  Component _buildTabButton(Tab tab, int index, bool isActive) {
    return Component.element(
      attributes: {
        'role': 'tab',
        'aria-selected': isActive ? 'true' : 'false',
        'tabindex': isActive ? '0' : '-1',
      },
      classes: isActive ? 'tab tab-active' : 'tab',
      events: onChanged != null
          ? {'click': (_) => onChanged!(index)}  // Event conversion
          : null,
      tag: 'a',
      children: [Component.text(tab.label)],
    );
  }

  Component? _buildTabContent() {
    for (var i = 0; i < children.length; i++) {
      if (i == selectedIndex) {
        final child = children[i];
        if (child is Tab && child.content.isNotEmpty) {
          return Component.element(
            attributes: {'role': 'tabpanel'},
            classes: 'p-4',
            tag: 'div',
            children: child.content,
          );
        }
      }
    }
    return null;
  }
}

/// Individual tab configuration.
class Tab {
  const Tab({
    required this.label,
    this.content = const [],
  });

  final String label;
  final List<Component> content;
}
```

**Key Takeaways for Medium Complexity**:
- State property (`selectedIndex`)
- Flutter-compatible callbacks: `void Function(T)?`
- Web event conversion: `events: {'click': (_) => callback!(value)}`
- Child iteration with type checking
- Helper classes for data structures (Tab)
- Conditional rendering with null returns
- Multiple builder methods for organization

### High Complexity: Dialog Pattern

**Characteristics**:
- Modal behavior with backdrop
- Multiple event handlers
- Helper components (DialogTitle, DialogContent, DialogActions)
- Complex accessibility requirements
- Keyboard event handling

**Implementation Pattern**:

```dart
class Dialog extends UiComponent {
  const Dialog(
    super.children, {
    super.attributes,
    super.child,
    super.classes,
    this.closeOnBackdrop = true,
    this.closeOnEscape = true,
    super.css,
    super.id,
    super.key,
    this.modal = true,
    this.onClose,
    this.open = false,
    List<DialogStyling>? style,
    super.tag = 'dialog',
  }) : super(style: style);

  final bool open;

  /// Callback when the dialog should close.
  /// Flutter-compatible void Function() callback.
  final void Function()? onClose;

  final bool modal;
  final bool closeOnBackdrop;
  final bool closeOnEscape;

  static const modalStyle = DialogStyle('modal', type: StyleType.style);
  static const openStyle = DialogStyle('modal-open', type: StyleType.state);
  static const bottom = DialogStyle('modal-bottom', type: StyleType.layout);
  static const middle = DialogStyle('modal-middle', type: StyleType.layout);

  // HTML/ARIA attribute constants
  static const _roleAttribute = 'role';
  static const _dialogRole = 'dialog';
  static const _ariaModalAttribute = 'modal';
  static const _openAttribute = 'open';

  @override
  String get baseClass => 'modal';

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);

    if (!userProvidedAttributes.containsKey(_roleAttribute)) {
      attributes.addRole(_dialogRole);
    }

    if (modal) {
      attributes.addAria(_ariaModalAttribute, 'true');
    }

    if (open) {
      attributes.add(_openAttribute, '');
    }
  }

  @override
  Component build(BuildContext context) {
    final styles = _buildStyles();
    final eventHandlers = _buildEventHandlers();

    // Dialog box (inner container)
    final dialogBox = Component.element(
      classes: 'modal-box',
      tag: 'div',
      children: children,
    );

    // Backdrop if modal
    final backdrop = modal
        ? Component.element(
            classes: 'modal-backdrop',
            events: closeOnBackdrop && onClose != null
                ? {'click': (_) => onClose!()}
                : null,
            tag: 'div',
          )
        : null;

    return Component.element(
      attributes: componentAttributes,
      classes: '$combinedClasses${styles.isNotEmpty ? ' ${styles.join(' ')}' : ''}',
      css: css,
      events: eventHandlers,
      id: id,
      tag: tag,
      children: [
        if (backdrop != null) backdrop,
        dialogBox,
      ],
    );
  }

  Map<String, EventCallback>? _buildEventHandlers() {
    if (!closeOnEscape || onClose == null) {
      return null;
    }

    // Handle ESC key to close dialog
    return {
      'keydown': (event) {
        final key = event.key;
        if (key == 'Escape' || key == 'Esc') {
          onClose!();
        }
      },
    };
  }
}

/// Helper component for dialog title section.
class DialogTitle extends UiComponent {
  const DialogTitle(
    super.children, {
    super.attributes,
    super.child,
    super.classes,
    super.css,
    super.id,
    super.key,
    super.tag = 'h3',
  });

  @override
  String get baseClass => 'font-bold text-lg';

  @override
  DialogTitle copyWith({
    Map<String, String>? attributes,
    Component? child,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    String? tag,
  }) {
    return DialogTitle(
      children,
      attributes: attributes ?? userProvidedAttributes,
      child: child ?? this.child,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      id: id ?? this.id,
      key: key ?? this.key,
      tag: tag ?? this.tag,
    );
  }
}

/// Helper component for dialog content section.
class DialogContent extends UiComponent {
  const DialogContent(
    super.children, {
    super.attributes,
    super.child,
    super.classes,
    super.css,
    super.id,
    super.key,
    super.tag = 'div',
  });

  @override
  String get baseClass => 'py-4';

  @override
  DialogContent copyWith({/* ... */}) {
    return DialogContent(/* ... */);
  }
}

/// Helper component for dialog actions section.
class DialogActions extends UiComponent {
  const DialogActions(
    super.children, {
    super.attributes,
    super.child,
    super.classes,
    super.css,
    super.id,
    super.key,
    super.tag = 'div',
  });

  @override
  String get baseClass => 'modal-action';

  @override
  DialogActions copyWith({/* ... */}) {
    return DialogActions(/* ... */);
  }
}
```

**Key Takeaways for High Complexity**:
- Multiple boolean configuration options
- Keyboard event handling with event.key
- Backdrop element as separate component
- Helper components extending UiComponent
- Constant definitions for attribute names
- Conditional event handler maps
- Complex accessibility attributes
- Multiple builder methods for organization

## Common Patterns Across All Complexity Levels

### 1. Static Style Constants

All components define static style constants following DaisyUI classes:

```dart
// Style variants
static const primary = ComponentStyle('component-primary', type: StyleType.style);
static const secondary = ComponentStyle('component-secondary', type: StyleType.style);

// Size variants
static const lg = ComponentStyle('component-lg', type: StyleType.sizing);
static const md = ComponentStyle('component-md', type: StyleType.sizing);
static const sm = ComponentStyle('component-sm', type: StyleType.sizing);

// State variants
static const active = ComponentStyle('component-active', type: StyleType.state);
static const disabled = ComponentStyle('component-disabled', type: StyleType.state);

// Layout variants
static const vertical = ComponentStyle('component-vertical', type: StyleType.layout);
static const horizontal = ComponentStyle('component-horizontal', type: StyleType.layout);
```

### 2. Flutter-Compatible Event Handlers

**Pattern**: External API uses Flutter-style callbacks, internal implementation converts to web events.

```dart
// External API (Flutter-compatible)
final void Function()? onClose;
final void Function(int)? onChanged;
final void Function(String)? onSubmit;

// Internal conversion (Web events)
events: onClose != null ? {'click': (_) => onClose!()} : null
events: onChanged != null ? {'click': (_) => onChanged!(index)} : null
events: onSubmit != null ? {'submit': (event) => onSubmit!(value)} : null
```

### 3. Style Building Pattern

```dart
List<String> _buildStyleClasses() {
  final stylesList = <String>[];

  // Add custom styles from style parameter
  if (style != null) {
    for (final s in style!) {
      if (s is ComponentStyling) {
        stylesList.add(s.cssClass);
      }
    }
  }

  // Add conditional styles based on state
  if (someCondition) {
    stylesList.add('conditional-class');
  }

  return stylesList;
}
```

### 4. Accessibility Configuration

```dart
@override
void configureAttributes(UiComponentAttributes attributes) {
  super.configureAttributes(attributes);

  // Set ARIA role if not provided by user
  if (!userProvidedAttributes.containsKey('role')) {
    attributes.addRole('appropriate-role');
  }

  // Add ARIA attributes based on state
  if (someState) {
    attributes.addAria('aria-attribute', 'value');
  }

  // Add data attributes for DaisyUI
  attributes.add('data-attribute', value);
}
```

### 5. copyWith Pattern

```dart
@override
ComponentName copyWith({
  Map<String, String>? attributes,
  Component? child,
  String? classes,
  Styles? css,
  String? id,
  Key? key,
  // ... component-specific parameters
  List<ComponentStyling>? style,
  String? tag,
}) {
  return ComponentName(
    children,  // or appropriate structure
    attributes: attributes ?? userProvidedAttributes,
    child: child ?? this.child,
    classes: mergeClasses(this.classes, classes),
    css: css ?? this.css,
    id: id ?? this.id,
    key: key ?? this.key,
    // ... component-specific properties
    style: style ??
        () {
          final currentStyle = this.style;
          return currentStyle is List<ComponentStyling>? ? currentStyle : null;
        }(),
    tag: tag ?? this.tag,
  );
}
```

## Export Pattern

Add component exports to `/packages/coui_web/lib/coui_web.dart`:

```dart
// --- {CATEGORY} ---
// {Category description}.
export 'src/components/{category}/{component_name}/{component_name}.dart';
export 'src/components/{category}/{component_name}/{component_name}_style.dart' show {ComponentName}Styling;
```

## Documentation Pattern

### Component Documentation Template

```dart
/// A {component_name} component for {purpose}.
///
/// The {ComponentName} component {detailed_description}.
/// It follows DaisyUI's {component_name} patterns and provides
/// Flutter-compatible API.
///
/// Features:
/// - {Feature 1 with brief description}
/// - {Feature 2 with brief description}
/// - {Feature 3 with brief description}
///
/// Example:
/// ```dart
/// {ComponentName}(
///   {parameter1}: {value1},
///   {parameter2}: {value2},
///   style: [{ComponentName}.{styleVariant}],
/// )
/// ```
class ComponentName extends UiComponent {
```

### Parameter Documentation

```dart
/// Creates a {ComponentName} component.
///
/// - [param1]: Description of param1.
/// - [param2]: Description of param2.
/// - [style]: List of [{ComponentName}Styling] instances for styling.
const ComponentName(
```

## Testing Checklist

Before considering a component complete:

- [ ] Both files created (component.dart, component_style.dart)
- [ ] Follows style pattern exactly (abstract interface + concrete implementation)
- [ ] Extends UiComponent correctly
- [ ] All required overrides implemented (baseClass, build, copyWith)
- [ ] Static style constants defined following DaisyUI classes
- [ ] Flutter-compatible event handlers (if applicable)
- [ ] Accessibility attributes configured (role, aria-*)
- [ ] Documentation comments complete
- [ ] Usage example in documentation
- [ ] Exported in coui_web.dart
- [ ] No DCM critical errors
- [ ] Component renders correctly in widgetbook

## Common Mistakes to Avoid

### ❌ Wrong: Using getter syntax with final in implementation

```dart
class ComponentStyle implements ComponentStyling {
  @override
  final String get cssClass;  // ❌ Error: Can't have modifier 'final' with getter
  @override
  final StyleType get type;   // ❌ Error: Can't have modifier 'final' with getter
}
```

### ✅ Correct: Use final without get keyword

```dart
class ComponentStyle implements ComponentStyling {
  @override
  final String cssClass;   // ✅ Correct
  @override
  final StyleType type;    // ✅ Correct
}
```

### ❌ Wrong: Not converting Flutter callbacks to web events

```dart
// External API
final void Function()? onClick;

// Build method
Component.element(
  onPressed: onClick,  // ❌ Wrong: Jaspr doesn't have onPressed
)
```

### ✅ Correct: Convert to web events

```dart
Component.element(
  events: onClick != null ? {'click': (_) => onClick!()} : null,  // ✅ Correct
)
```

### ❌ Wrong: Missing super.configureAttributes call

```dart
@override
void configureAttributes(UiComponentAttributes attributes) {
  // ❌ Missing super call
  attributes.addRole('dialog');
}
```

### ✅ Correct: Always call super first

```dart
@override
void configureAttributes(UiComponentAttributes attributes) {
  super.configureAttributes(attributes);  // ✅ Correct
  attributes.addRole('dialog');
}
```

## Next Steps

This pattern documentation should be used as a reference when implementing the remaining 11 Phase 1 components:

**Overlay**: Drawer, Toast, Popover
**Navigation**: Pagination, NavigationBar
**Menu**: DropdownMenu, ContextMenu
**Layout**: Accordion, Breadcrumb
**Form**: DatePicker, Slider

Each component should follow the patterns established here based on its complexity level.