# Remaining Phase 1 Components Implementation Guide

## Overview

This guide provides detailed specifications for implementing the remaining 11 Phase 1 components. Each component includes:
- Complexity level and recommended pattern
- Complete API specification
- DaisyUI class mappings
- Implementation notes
- Code skeleton

All implementations should follow patterns documented in `component_implementation_patterns.md`.

---

## Overlay Category (3 components)

### 1. Drawer (Medium Complexity)

**Pattern**: Follow Tabs pattern (state management, event callbacks)

**DaisyUI Classes**: `drawer`, `drawer-toggle`, `drawer-content`, `drawer-side`, `drawer-overlay`, `drawer-end`

**API Specification**:

```dart
class Drawer extends UiComponent {
  const Drawer({
    required this.content,      // Main content area
    required this.sideContent,  // Drawer side content
    this.open = false,
    this.onChanged,             // void Function(bool)?
    this.position = DrawerPosition.left,
    this.overlay = true,
    List<DrawerStyling>? style,
  });

  final List<Component> content;
  final List<Component> sideContent;
  final bool open;
  final void Function(bool)? onChanged;
  final DrawerPosition position;
  final bool overlay;

  static const end = DrawerStyle('drawer-end', type: StyleType.layout);

  @override
  String get baseClass => 'drawer';
}

enum DrawerPosition {
  left,
  right,
}
```

**Implementation Notes**:
- Use checkbox pattern for toggle (DaisyUI drawer pattern)
- `drawer-content` wraps main content
- `drawer-side` wraps drawer content
- `drawer-overlay` for backdrop if overlay=true
- Position handled by `drawer-end` class (right position)

**Complexity Factors**:
- Medium: State + checkbox pattern + dual content areas

---

### 2. Toast (Medium Complexity)

**Pattern**: Follow Tabs pattern (state, positioning, auto-dismiss)

**DaisyUI Classes**: `toast`, `toast-start`, `toast-center`, `toast-end`, `toast-top`, `toast-middle`, `toast-bottom`, `alert` (for toast content)

**API Specification**:

```dart
class Toast extends UiComponent {
  const Toast(
    super.children, {
    this.position = ToastPosition.topEnd,
    this.duration,              // Duration? for auto-dismiss
    this.onDismiss,            // void Function()?
    List<ToastStyling>? style,
  });

  final ToastPosition position;
  final Duration? duration;
  final void Function()? onDismiss;

  // Position variants
  static const start = ToastStyle('toast-start', type: StyleType.layout);
  static const center = ToastStyle('toast-center', type: StyleType.layout);
  static const end = ToastStyle('toast-end', type: StyleType.layout);
  static const top = ToastStyle('toast-top', type: StyleType.layout);
  static const middle = ToastStyle('toast-middle', type: StyleType.layout);
  static const bottom = ToastStyle('toast-bottom', type: StyleType.layout);

  @override
  String get baseClass => 'toast';
}

enum ToastPosition {
  topStart,
  topCenter,
  topEnd,
  middleStart,
  middleCenter,
  middleEnd,
  bottomStart,
  bottomCenter,
  bottomEnd,
}
```

**Implementation Notes**:
- Position uses 2 classes (e.g., `toast-top toast-end`)
- Children should be Alert components for proper styling
- Auto-dismiss needs timer if duration provided
- Fixed positioning, appears over content

**Complexity Factors**:
- Medium: Position combinations + optional auto-dismiss timer

---

### 3. Popover (Medium Complexity)

**Pattern**: Follow Tooltip pattern (positioning, hover/click)

**DaisyUI Classes**: Uses dropdown classes: `dropdown`, `dropdown-top`, `dropdown-bottom`, `dropdown-left`, `dropdown-right`, `dropdown-hover`, `dropdown-open`

**API Specification**:

```dart
class Popover extends UiComponent {
  const Popover({
    required this.child,        // Trigger element
    required this.content,      // Popover content
    this.open = false,
    this.onChanged,            // void Function(bool)?
    this.position = PopoverPosition.bottom,
    this.trigger = PopoverTrigger.click,
    List<PopoverStyling>? style,
  });

  final Component child;
  final List<Component> content;
  final bool open;
  final void Function(bool)? onChanged;
  final PopoverPosition position;
  final PopoverTrigger trigger;

  static const hover = PopoverStyle('dropdown-hover', type: StyleType.state);
  static const openState = PopoverStyle('dropdown-open', type: StyleType.state);

  @override
  String get baseClass => 'dropdown';
}

enum PopoverPosition {
  top,
  bottom,
  left,
  right,
}

enum PopoverTrigger {
  click,
  hover,
}
```

**Implementation Notes**:
- Reuses DaisyUI dropdown classes
- Trigger determines if `dropdown-hover` class applied
- Position maps to `dropdown-{position}`
- Content wrapped in `dropdown-content` div

**Complexity Factors**:
- Medium: Trigger logic + positioning + state management

---

## Navigation Category (2 components)

### 4. Pagination (Medium Complexity)

**Pattern**: Follow Tabs pattern (state, indexed callbacks)

**DaisyUI Classes**: `join`, `btn`, `btn-active`, `btn-disabled`

**API Specification**:

```dart
class Pagination extends UiComponent {
  const Pagination({
    required this.currentPage,
    required this.totalPages,
    this.onChanged,            // void Function(int)?
    this.siblingCount = 1,     // Pages to show on each side of current
    this.boundaryCount = 1,    // Pages to show at start/end
    this.showFirstLast = true,
    this.showPrevNext = true,
    List<PaginationStyling>? style,
  });

  final int currentPage;
  final int totalPages;
  final void Function(int)? onChanged;
  final int siblingCount;
  final int boundaryCount;
  final bool showFirstLast;
  final bool showPrevNext;

  static const lg = PaginationStyle('btn-lg', type: StyleType.sizing);
  static const md = PaginationStyle('btn-md', type: StyleType.sizing);
  static const sm = PaginationStyle('btn-sm', type: StyleType.sizing);

  @override
  String get baseClass => 'join';
}
```

**Implementation Notes**:
- Uses DaisyUI join + btn components
- Calculate visible page numbers based on siblingCount/boundaryCount
- Add ellipsis (...) for gaps
- Active page gets `btn-active` class
- Disabled state for first/last pages
- Each button uses `join-item` class

**Complexity Factors**:
- Medium: Page number calculation + ellipsis logic + multiple button states

---

### 5. NavigationBar (Medium-High Complexity)

**Pattern**: Follow Tabs pattern + Dialog pattern (state + multiple sections)

**DaisyUI Classes**: `navbar`, `navbar-start`, `navbar-center`, `navbar-end`

**API Specification**:

```dart
class NavigationBar extends UiComponent {
  const NavigationBar({
    this.start,               // List<Component>?
    this.center,              // List<Component>?
    this.end,                 // List<Component>?
    this.sticky = false,
    List<NavigationBarStyling>? style,
  });

  final List<Component>? start;
  final List<Component>? center;
  final List<Component>? end;
  final bool sticky;

  static const primary = NavigationBarStyle('bg-primary text-primary-content', type: StyleType.style);
  static const neutral = NavigationBarStyle('bg-neutral text-neutral-content', type: StyleType.style);

  @override
  String get baseClass => 'navbar';
}

class NavigationBarItem extends UiComponent {
  const NavigationBarItem(
    super.children, {
    this.active = false,
    this.onPressed,           // void Function()?
  });

  final bool active;
  final void Function()? onPressed;

  @override
  String get baseClass => 'btn btn-ghost';
}
```

**Implementation Notes**:
- Three-section layout (start, center, end)
- Each section wrapped in appropriate div
- Sticky positioning via Tailwind `sticky top-0 z-50`
- NavigationBarItem helper for consistent button styling
- Active state styling

**Complexity Factors**:
- Medium-High: Multiple sections + helper components + positioning

---

## Menu Category (2 components)

### 6. DropdownMenu (Medium Complexity)

**Pattern**: Follow Tabs pattern (state, selection callbacks)

**DaisyUI Classes**: `dropdown`, `dropdown-content`, `menu`, `menu-compact`

**API Specification**:

```dart
class DropdownMenu extends UiComponent {
  const DropdownMenu({
    required this.trigger,      // Component (button/link)
    required this.items,        // List<DropdownMenuItem>
    this.open = false,
    this.onChanged,            // void Function(bool)?
    this.position = DropdownPosition.bottom,
    List<DropdownMenuStyling>? style,
  });

  final Component trigger;
  final List<DropdownMenuItem> items;
  final bool open;
  final void Function(bool)? onChanged;
  final DropdownPosition position;

  static const hover = DropdownMenuStyle('dropdown-hover', type: StyleType.state);
  static const openState = DropdownMenuStyle('dropdown-open', type: StyleType.state);

  @override
  String get baseClass => 'dropdown';
}

class DropdownMenuItem {
  const DropdownMenuItem({
    required this.label,
    this.onPressed,            // void Function()?
    this.disabled = false,
  });

  final String label;
  final void Function()? onPressed;
  final bool disabled;
}

enum DropdownPosition {
  top,
  bottom,
  left,
  right,
}
```

**Implementation Notes**:
- Similar to Popover but with menu styling
- Items rendered in `menu` component inside `dropdown-content`
- Each item is clickable list item
- Position handled by `dropdown-{position}` classes

**Complexity Factors**:
- Medium: Item list + positioning + state + helper class

---

### 7. ContextMenu (Medium-High Complexity)

**Pattern**: Follow Dialog pattern (positioning, event handling)

**DaisyUI Classes**: `menu`, `menu-compact`, `bg-base-200`, `rounded-box`, `shadow`

**API Specification**:

```dart
class ContextMenu extends UiComponent {
  const ContextMenu({
    required this.child,        // Element to attach context menu
    required this.items,        // List<ContextMenuItem>
    this.open = false,
    this.position,             // Offset? (x, y)
    List<ContextMenuStyling>? style,
  });

  final Component child;
  final List<ContextMenuItem> items;
  final bool open;
  final Offset? position;

  @override
  String get baseClass => 'relative';
}

class ContextMenuItem {
  const ContextMenuItem({
    required this.label,
    this.icon,                 // Component?
    this.onPressed,            // void Function()?
    this.disabled = false,
    this.divider = false,
  });

  final String label;
  final Component? icon;
  final void Function()? onPressed;
  final bool disabled;
  final bool divider;
}

class Offset {
  const Offset(this.x, this.y);
  final double x;
  final double y;
}
```

**Implementation Notes**:
- Right-click event handler: `'contextmenu': (event) => handleContextMenu(event)`
- Menu positioned absolutely at click coordinates
- Prevent default context menu: `event.preventDefault()`
- Menu rendered with `menu` component
- Divider items render as `divider` class

**Complexity Factors**:
- Medium-High: Right-click handling + absolute positioning + prevent default

---

## Layout Category (2 components)

### 8. Accordion (Medium Complexity)

**Pattern**: Follow Tabs pattern (expansion state, multiple sections)

**DaisyUI Classes**: `collapse`, `collapse-title`, `collapse-content`, `collapse-arrow`, `collapse-plus`, `collapse-open`

**API Specification**:

```dart
class Accordion extends UiComponent {
  const Accordion(
    super.children, {          // List of AccordionItem
    this.multiple = false,     // Allow multiple expanded
    this.expandedIndexes = const [],
    this.onChanged,            // void Function(List<int>)?
    List<AccordionStyling>? style,
  });

  final bool multiple;
  final List<int> expandedIndexes;
  final void Function(List<int>)? onChanged;

  static const arrow = AccordionStyle('collapse-arrow', type: StyleType.style);
  static const plus = AccordionStyle('collapse-plus', type: StyleType.style);

  @override
  String get baseClass => 'join join-vertical w-full';
}

class AccordionItem extends UiComponent {
  const AccordionItem({
    required this.title,
    required this.content,
    this.expanded = false,
  });

  final String title;
  final List<Component> content;
  final bool expanded;

  @override
  String get baseClass => 'collapse';
}
```

**Implementation Notes**:
- Each item uses `collapse` component
- Checkbox pattern for expand/collapse
- `collapse-open` class for expanded state
- Multiple mode allows multiple items expanded
- Single mode closes others when one opens

**Complexity Factors**:
- Medium: Multiple items + expansion logic + single/multiple modes

---

### 9. Breadcrumb (Low Complexity)

**Pattern**: Follow Tooltip pattern (simple rendering)

**DaisyUI Classes**: `breadcrumbs`, `text-base-content`

**API Specification**:

```dart
class Breadcrumb extends UiComponent {
  const Breadcrumb(
    super.children, {          // List of BreadcrumbItem
    this.separator = '/',
    List<BreadcrumbStyling>? style,
  });

  final String separator;

  @override
  String get baseClass => 'breadcrumbs text-sm';
}

class BreadcrumbItem {
  const BreadcrumbItem({
    required this.label,
    this.href,                 // String?
    this.onPressed,            // void Function()?
    this.active = false,
  });

  final String label;
  final String? href;
  final void Function()? onPressed;
  final bool active;
}
```

**Implementation Notes**:
- Renders as unordered list with links
- Separator inserted between items
- Active item can be different style (non-clickable)
- href for actual links, onPressed for SPA navigation

**Complexity Factors**:
- Low: Simple list rendering + separators

---

## Form Category (2 components)

### 10. DatePicker (High Complexity)

**Pattern**: Follow Dialog pattern (complex interaction, calendar logic)

**DaisyUI Classes**: `input`, `dropdown`, `dropdown-content`, custom calendar styling

**API Specification**:

```dart
class DatePicker extends UiComponent {
  const DatePicker({
    this.value,                // DateTime?
    this.onChanged,            // void Function(DateTime)?
    this.firstDate,            // DateTime?
    this.lastDate,             // DateTime?
    this.initialDate,          // DateTime?
    this.format = 'yyyy-MM-dd',
    this.placeholder = 'Select date',
    List<DatePickerStyling>? style,
  });

  final DateTime? value;
  final void Function(DateTime)? onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final DateTime? initialDate;
  final String format;
  final String placeholder;

  static const bordered = DatePickerStyle('input-bordered', type: StyleType.border);
  static const ghost = DatePickerStyle('input-ghost', type: StyleType.style);

  @override
  String get baseClass => 'form-control';
}
```

**Implementation Notes**:
- Input field + dropdown with calendar
- Calendar grid with month/year navigation
- Date range validation (firstDate/lastDate)
- Format display value using provided format
- Click outside to close
- Keyboard navigation support

**Complexity Factors**:
- High: Calendar rendering + date logic + navigation + validation + formatting

---

### 11. Slider (Medium Complexity)

**Pattern**: Follow Tabs pattern (state, value callbacks)

**DaisyUI Classes**: `range`, `range-primary`, `range-secondary`, `range-accent`, `range-lg`, `range-md`, `range-sm`, `range-xs`

**API Specification**:

```dart
class Slider extends UiComponent {
  const Slider({
    this.value = 50.0,
    this.onChanged,            // void Function(double)?
    this.min = 0.0,
    this.max = 100.0,
    this.step = 1.0,
    this.showValue = false,
    this.showSteps = false,
    List<SliderStyling>? style,
  });

  final double value;
  final void Function(double)? onChanged;
  final double min;
  final double max;
  final double step;
  final bool showValue;
  final bool showSteps;

  static const primary = SliderStyle('range-primary', type: StyleType.style);
  static const secondary = SliderStyle('range-secondary', type: StyleType.style);
  static const accent = SliderStyle('range-accent', type: StyleType.style);
  static const lg = SliderStyle('range-lg', type: StyleType.sizing);
  static const md = SliderStyle('range-md', type: StyleType.sizing);
  static const sm = SliderStyle('range-sm', type: StyleType.sizing);
  static const xs = SliderStyle('range-xs', type: StyleType.sizing);

  @override
  String get baseClass => 'range';
}
```

**Implementation Notes**:
- HTML5 `<input type="range">` element
- Value display optional (label above/below)
- Step markers optional (tick marks)
- Input event handler for real-time updates
- Change event for final value

**Complexity Factors**:
- Medium: Range input + value display + step markers + event handling

---

## Implementation Priority Recommendation

Based on complexity and dependencies:

### Week 1: Low-Medium Complexity
1. **Breadcrumb** (Low) - Simplest, good warmup
2. **Slider** (Medium) - Standard input component
3. **Toast** (Medium) - Useful for testing other components

### Week 2: Medium Complexity
4. **Drawer** (Medium) - Common layout pattern
5. **Popover** (Medium) - Similar to Tooltip
6. **DropdownMenu** (Medium) - Common interaction

### Week 3: Medium-High Complexity
7. **Pagination** (Medium) - Complex calculation logic
8. **Accordion** (Medium) - Multiple item management
9. **NavigationBar** (Medium-High) - Multiple sections

### Week 4: High Complexity
10. **ContextMenu** (Medium-High) - Event handling complexity
11. **DatePicker** (High) - Most complex, calendar logic

---

## Quality Checklist

For each component, verify:

- [ ] Both files created (component.dart, component_style.dart)
- [ ] Follows established patterns from pattern documentation
- [ ] All DaisyUI classes correctly applied
- [ ] Flutter-compatible API (event handlers)
- [ ] Accessibility attributes (ARIA roles)
- [ ] Complete documentation comments
- [ ] Usage example in documentation
- [ ] Exported in coui_web.dart
- [ ] No DCM critical errors
- [ ] Tested in widgetbook
- [ ] Responsive behavior verified

---

## Getting Help

Reference materials:
- `/docs/component_implementation_patterns.md` - Core patterns
- `/docs/phase1_implementation_plan.md` - Overall plan
- `/packages/coui_web/lib/src/components/overlay/dialog/` - High complexity example
- `/packages/coui_web/lib/src/components/navigation/tabs/` - Medium complexity example
- `/packages/coui_web/lib/src/components/overlay/tooltip/` - Low complexity example
- DaisyUI documentation: https://daisyui.com/components/

For each component:
1. Identify complexity level
2. Choose matching pattern from documentation
3. Reference DaisyUI docs for class names
4. Implement following the pattern
5. Test and validate