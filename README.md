# CoUI

[![pub version](https://img.shields.io/pub/v/coui.svg)](https://pub.dev/packages/coui)

**Flutter + Jaspr => CoUI**

A unified design system providing type-safe Dart implementations of modern UI components for both Flutter mobile apps and Jaspr web applications. Build beautiful, consistent interfaces across all platforms with a single codebase.

## 🌟 Design Principles

- **🎯 Type Safety** - Catch styling errors at compile time
- **🔧 Fluent API** - Chain modifiers intuitively  
- **📱 Cross Platform** - Flutter mobile + Jaspr web support
- **🎨 Modern Design** - Inspired by coui/ui and DaisyUI
- **⚡ Performance** - Minimal runtime overhead
- **🛠️ Template Ready** - Built for code generation and templating

## 🚀 Getting Started

### Add Dependency

Add CoUI to your pubspec.yaml:

```yaml
dependencies:
  coui: ^0.1.0
  # For Flutter projects
  coui_flutter: ^0.1.0
  # For Jaspr web projects  
  coui_web: ^0.1.0
```

### Flutter Setup

```dart
import 'package:flutter/material.dart';
import 'package:coui_flutter/coui_flutter.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: CoUITheme.lightTheme(),
      darkTheme: CoUITheme.darkTheme(),
      home: MyHomePage(),
    );
  }
}
```

### Jaspr Web Setup

CoUI for Jaspr requires Tailwind CSS to be configured in your project for proper styling.

```dart
import 'package:jaspr/jaspr.dart';
import 'package:coui_web/coui_web.dart';

class MyComponent extends StatelessComponent {
  @override
  Iterable<Component> build(BuildContext context) sync* {
    yield CoUIProvider([
      // Your components here
    ]);
  }
}
```

## 💡 Usage Examples

### Flutter Example

```dart
import 'package:coui_flutter/coui_flutter.dart';

class FlutterExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CoButton(
            'Click Me',
            variant: CoButtonVariant.primary,
            size: CoButtonSize.lg,
            onPressed: () => print('Button clicked!'),
          ),
          CoCard(
            child: CoText('Hello from Flutter!'),
            elevation: 2,
          ),
          CoInput(
            placeholder: 'Enter text...',
            onChanged: (value) => print(value),
          ),
        ],
      ),
    );
  }
}
```

### Jaspr Web Example

```dart
import 'package:coui_web/coui_web.dart';

class JasprExample extends StatelessComponent {
  @override
  Iterable<Component> build(BuildContext context) sync* {
    yield div([
      CoButton(
        [text('Click Me')],
        style: [
          CoButton.primary,
          CoButton.lg,
        ],
        onClick: (_) => print('Button clicked!'),
      ),
      CoCard([
        text('Hello from Jaspr Web!'),
      ]),
      CoInput(
        placeholder: 'Enter text...',
        onInput: (value) => print(value),
      ),
    ]);
  }
}
```

## 📦 Package Structure

```
packages/
├── coui/              # Core design tokens and types
├── coui_flutter      # Flutter implementation
├── coui_web/          # Jaspr web implementation
└── coui_cli/          # Code generation CLI tools
```

## 🎯 Component Roadmap

### ✅ Phase 1: Foundation Components
Essential building blocks - Available now

- **Button** - Primary, secondary, destructive variants
- **Input** - Text input with validation states  
- **Card** - Content containers with elevation
- **Badge** - Status indicators and labels
- **Alert** - Notification and warning messages
- **Avatar** - User profile images and fallbacks
- **Separator** - Visual content dividers

### 🔄 Phase 2: Form Components
Form inputs and validation (In Progress)

- **Checkbox** - Boolean selection with indeterminate state
- **RadioGroup** - Single choice selection
- **Switch** - Toggle boolean input
- **Textarea** - Multi-line text input
- **Select** - Dropdown selection with search
- **Combobox** - Searchable dropdown with custom options
- **Slider** - Range value selection
- **Progress** - Task completion indicators

### 📋 Phase 3: Navigation & Layout
Page structure and navigation

- **Tabs** - Tabbed content interfaces
- **Breadcrumb** - Navigation hierarchy
- **Pagination** - Page navigation controls
- **Navigation Menu** - Header and sidebar navigation
- **Menubar** - Application menu bars
- **Accordion** - Expandable content sections
- **Collapsible** - Toggle content visibility

### 🎨 Phase 4: Data Display
Information presentation

- **Table** - Structured data with sorting/filtering
- **Data Table** - Enhanced tables with actions
- **Calendar** - Date selection and display
- **Date Picker** - Date input with calendar popup
- **Time Picker** - Time selection interface
- **Skeleton** - Loading state placeholders
- **Tooltip** - Contextual help and information

### 🚀 Phase 5: Feedback & Overlays
User notifications and dialogs

- **Dialog** - Modal dialogs and confirmations
- **Sheet** - Bottom sheets and side panels
- **Drawer** - Sliding navigation panels
- **Popover** - Contextual content overlays
- **Toast** - Notification messages
- **Sonner** - Advanced toast notifications
- **Context Menu** - Right-click and long-press menus

### 🎮 Phase 6: Advanced Components
Complex interactions and layouts

- **Command** - Command palette interface
- **Resizable** - Resizable panels and layouts
- **Carousel** - Content sliders and galleries
- **Toggle Group** - Multiple toggle selection
- **Input OTP** - One-time password input
- **Form** - Form validation and submission
- **Charts** - Data visualization components

## 🛠️ Code Generation Support

CoUI is built with template generation in mind, making it perfect for AI-powered app generation platforms:

```dart
// CLI usage for component generation
coui generate button --name="SubmitButton" --variant="primary" --size="lg"
coui generate form --fields="email,password,confirmPassword"
coui generate page --template="dashboard" --components="card,table,chart"
```

## 🎨 Theming & Customization

### Flutter Theming

```dart
CoUITheme.custom(
  colorScheme: CoUIColorScheme(
    primary: Colors.blue,
    secondary: Colors.green,
    // ... other colors
  ),
  typography: CoUITypography.custom(
    // Custom font styles
  ),
)
```

### Jaspr CSS Variables

```css
:root {
  --coui-primary: 220 100% 50%;
  --coui-secondary: 150 100% 40%;
  --coui-background: 0 0% 100%;
  --coui-foreground: 0 0% 10%;
  /* ... other variables */
}
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## 📄 License

MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- **Documentation**: [coui-docs.web.app](https://coui-docs.web.app)
- **Flutter Example**: [flutter-coui.web.app](https://flutter-coui.web.app)
- **Jaspr Example**: [jaspr-coui.web.app](https://jaspr-coui.web.app)
- **Pub.dev**: [pub.dev/packages/coui](https://pub.dev/packages/coui)

## 🌟 Inspiration

CoUI is inspired by the excellent work of:
- [coui/ui](https://ui.coui.com/) - Modern React component library
- [DaisyUI](https://daisyui.com/) - Semantic CSS framework
- [Flutter CocnUI](https://flutter-coui-ui.mariuti.com/) - coui/ui for Flutter
- [Coui Web](https://coui_web-doc.web.app/) - DaisyUI for Jaspr

---

**Built with ❤️ for the Dart & Flutter community**