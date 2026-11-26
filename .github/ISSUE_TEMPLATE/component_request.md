---
name: Component Request
about: Request a new UI component
title: "[Component] "
labels: component-request
assignees: ''
---

## Component Name

Name of the component (e.g., DateRangePicker, Sidebar).

## Category

- [ ] Control
- [ ] Display
- [ ] Form
- [ ] Layout
- [ ] Menu
- [ ] Navigation
- [ ] Overlay
- [ ] Text

## Platform

- [ ] coui_flutter (Flutter)
- [ ] coui_web (Jaspr/CoUI)
- [ ] Both

## Description

What does this component do? What is its purpose?

## API Sketch

```dart
// Proposed API
ComponentName(
  required: value,
  optional: value,
  onChanged: (v) {},
  child: Widget,
)
```

## Design Reference

Link to design spec, CoUI reference, or similar component in other libraries.

## Priority

- [ ] High - Blocking other work
- [ ] Medium - Important but not urgent
- [ ] Low - Nice to have
