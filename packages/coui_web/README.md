# CoUI

Jaspr + Tailwind CSS => CoUI

A type-safe Dart web component library for Jaspr, providing a fluent API for building beautiful web apps with Tailwind CSS.

> [!WARNING]
> **Experimental** — This package is in an experimental stage. APIs may change without notice before `1.0.0`. Breaking changes can occur in any release. Use in production at your own discretion.

## **Design Principles**

- 🎯 **Type Safety** - Catch styling errors at compile time
- 🔧 **Fluent API** - Chain modifiers intuitively
- 📱 **Responsive** - Built-in breakpoint support
- 🎨 **CoUI Theme System** - Semantic CSS classes backed by `--coui-*` variables (built-in `light` and `dark`)
- ⚡ **Performance** - Minimal runtime overhead
- 🌓 **Theme System** - Light and dark themes, plus custom palettes via `CoUIThemeController.setCustomTheme`

## Getting Started

1. **Add Dependency**

    ```sh
    dart pub add coui_web
    ```

2. **Setup Tailwind CSS**

    Follow the [Jaspr installation guide](https://coui.cocode.im/getting-started)
    to configure Tailwind and supply CoUI's theme variables.

## Usage Examples

### Basic Components

Components take **named properties**, and the names are the same ones the Flutter
package uses — that is the point of the kit. Text goes in through the `Text` chain.

```dart
import 'package:coui_web/coui_web.dart';

class MyComponent extends StatelessComponent {
  @override
  Iterable<Component> build(BuildContext context) sync* {
    yield Button(
      variant: CoreButtonVariant.primary,
      onPressed: handleClick,
      child: const Text('Click Me'),
    );

    yield Card(
      header: const Text('Card Title'),
      body: const Text('Card content goes here'),
      footer: Button(
        variant: CoreButtonVariant.primary,
        onPressed: handleAction,
        child: const Text('Action'),
      ),
    );

    yield Alert(
      variant: CoreAlertVariant.info,
      title: const Text('Heads up!'),
      description: const Text('You can add components using the CLI.'),
    );
  }
}
```

### Theme System

```dart
import 'package:coui_web/coui_web.dart';

void main() {
  // Set a specific theme
  CoUIThemeController.setTheme(CoUIThemeController.dark);

  // Toggle dark mode
  CoUIThemeController.toggleDarkMode();

  // Use system preference
  CoUIThemeController.useSystemPreference();

  // Watch for system theme changes
  CoUIThemeController.watchSystemPreference((isDark) {
    print('System dark mode: $isDark');
    CoUIThemeController.setTheme(
      isDark ? CoUIThemeController.dark : CoUIThemeController.light
    );
  });

  runApp(MyApp());
}
```

### Available Themes

`ThemeConfig` defines `--coui-*` variables for two themes: `light` (default)
and `dark`. Any other `data-theme` value has no definition behind it and
changes nothing. To apply a custom palette, push it as CSS variables with
`CoUIThemeController.setCustomTheme(colorScheme)`.

## Component Status

**161 component contracts are implemented on both Flutter and Web.**
`tool/api_sync_check.dart` gates that in CI — if a contract lands on one platform
only, the build fails.

There is no hand-written component checklist here on purpose: the one that used to
live in this spot claimed 72 components and about 65% completion, and listed as
*planned* components that had already shipped. A list nobody re-derives becomes
wrong, and a wrong list is worse than no list.

For what exists and what it looks like, see **[coui.cocode.im](https://coui.cocode.im/)**.
The catalog behind it (`docs_core/lib/shared/component_catalog.dart`) is the single
source the docs site, its search index and the native docs app all read.

## Features

- 🎯 **Type-Safe Components** - Compile-time error checking for component props
- 🎨 **Themes** - Built-in `light` and `dark`, plus custom palettes as CSS variables
- 🌓 **Dark Mode** - Automatic system preference detection and manual toggle
- 📱 **Responsive** - Mobile-first design with responsive utilities
- ♿ **Accessible** - ARIA attributes and keyboard navigation
- 🎭 **Variants** - Multiple style variants for each component
- 🔧 **Customizable** - Extend with custom classes and styles
- ⚡ **Performance** - Lightweight with minimal runtime overhead

## Architecture

CoUI combines semantic component APIs with utility-first styling:

- **CoUI Components**: Semantic, type-safe Dart APIs for rapid development
- **Jaspr**: Modern Dart web framework
- **Tailwind CSS v4**: Utility-first CSS framework

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Credits

CoUI Web's component structure, the `UiComponent` and `UiComponentAttributes`
base classes, and portions of its documentation comments originate from
[Deepyr](https://pub.dev/packages/deepyr) by Philipp H. Gerber,
licensed under the MIT License.
The implementations here have largely been rewritten.

See [`NOTICE`](../../NOTICE) at the repository root for full attribution.

## License

MIT License - see the LICENSE file in this package for details, including the
upstream notice that applies to the derived portions.
