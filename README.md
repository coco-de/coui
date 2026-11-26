# CoUI

**Flutter + Jaspr => CoUI**

A unified design system for **Flutter** mobile/desktop apps and **Jaspr** web applications. Type-safe Dart components, shared design tokens, and consistent APIs across all platforms.

[![CI](https://github.com/coco-de/coui/actions/workflows/ci.yaml/badge.svg)](https://github.com/coco-de/coui/actions/workflows/ci.yaml)

> [!WARNING]
> **Experimental** — CoUI is currently in an experimental stage. Breaking changes can occur before `1.0.0`; review the release notes and [deprecation policy](docs/contributing/upgrading.md#deprecation) when upgrading. Feedback and contributions are welcome.

[한국어](README.ko-kr.md) · [Docs Site](https://coui.cocode.im/) · [Design Tokens](https://coui.cocode.im/tokens/overview) · [Widgetbook](https://coui.cocode.studio/)

Improving CoUI itself? Start with [Contributing](CONTRIBUTING.md) or the
[한국어 단계별 가이드](docs/contributing/README.md) for Core → Flutter/Web → Figma.

## Key Features

- **Cross-Platform** — One component library for Flutter (mobile/desktop) and Jaspr (web)
- **161 Components, Both Platforms** — every component contract is implemented on Flutter *and* Web, with the same parameter names; CI fails if one side falls behind
- **Design Tokens** — colour, typography, spacing, radius and motion scales, all in `coui_core` and shared by both platforms ([token reference](https://coui.cocode.im/tokens/overview))
- **3 Design Systems** — CoUI Web, M3 Expressive (Flutter), Liquid Glass (visionOS/AR)
- **Dark Mode** — Full light/dark support on both platforms
- **Type-Safe** — Compile-time checked styling, no stringly-typed CSS classes in Flutter

## Quick Start

### Flutter

Install the Flutter beta from pub.dev:

```sh
flutter pub add 'coui_flutter:^0.194.2-beta.1'
```

Set up your app:

```dart
import 'package:coui_flutter/coui_flutter.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CoUIApp(
      theme: const ThemeData(),
      darkTheme: const ThemeData.dark(),
      home: MyHomePage(),
    );
  }
}
```

Use components:

```dart
Column(
  children: [
    Button(
      variant: CoreButtonVariant.primary,
      onPressed: handleSubmit,
      child: const Text('Submit'),
    ),
    const TextField(placeholder: Text('Enter your name...')),
    const Badge(tone: CoreBadgeTone.primary, child: Text('New')),
  ],
)
```

### Jaspr Web

Install a published release from pub.dev:

```sh
dart pub add coui_web
```

Requires Tailwind CSS configured in your Jaspr project.

The API is the same one you just saw on Flutter — same names, same slots:

```dart
import 'package:coui_web/coui_web.dart';

Button(
  variant: CoreButtonVariant.primary,
  onPressed: handleClick,
  child: const Text('Click me'),
)

TextField(placeholder: const Text('Search...'))
```

## Component Categories

| Category | Flutter | Web |
|----------|--------:|----:|
| Display | 36 | 36 |
| Layout | 35 | 35 |
| Form | 31 | 32 |
| Infra | 14 | 11 |
| Overlay | 9 | 9 |
| Control | 6 | 6 |
| Navigation | 5 | 5 |
| Menu | 5 | 5 |
| Text | 3 | 3 |
| Icon | 1 | 1 |
| Locale | — | 1 |

**161 component contracts are implemented on both platforms** — `tool/api_sync_check.dart`
gates that number in CI, so it cannot drift. The per-category counts differ only where a
platform needs extra infrastructure files (Flutter overlay/render plumbing, Web locale
scope); no contract is missing on either side.

The component list itself lives in one place and is not duplicated here — a hand-written
list goes stale and then lies. Browse it at **[coui.cocode.im](https://coui.cocode.im/)**,
or read `docs_core/lib/shared/component_catalog.dart`, which is what the docs site,
the search index and the native docs app all read.

## Package Structure

```
packages/
  coui/           # Umbrella package
  coui_core/      # Platform-agnostic design tokens, contracts, shared logic
  coui_flutter/   # Flutter implementation (Material + CoUI theme)
  coui_web/       # Jaspr web implementation (CoUI themes + Tailwind CSS)
  coui_i10n/      # Shared localization strings
  coui_lints/     # Lint rules used across the workspace
  coui_mcp/       # MCP server for AI-assisted development (not a workspace member)
```

| Package | Description | README |
|---------|-------------|--------|
| `coui_core` | Design tokens (colour · typography · spacing · radius · motion), 3 design systems | — |
| `coui_flutter` | Flutter widgets, themes, controllers | [README](packages/coui_flutter/README.md) |
| `coui_web` | Jaspr web components | [README](packages/coui_web/README.md) |

## Design Token System (`coui_core`)

CoUI uses a unified design token system supporting 3 design systems:

| Design System | Target | Shape | Motion | Surface |
|---------------|--------|-------|--------|---------|
| **CoUI Web** | Web (Jaspr) | rounded | CSS transition | flat |
| **M3 Expressive** | Flutter App | squircle | Spring physics | tonalElevation |
| **Liquid Glass** | visionOS/AR | glassRounded | Glass physics | glass |

### Token Categories

| Category | Class | Tokens |
|----------|-------|--------|
| Color | `CoreColorScheme` | semantic slots, resolved per brightness / contrast |
| Typography | `CoreTypography` | 22 roles (display · headline · title · body · label · code) |
| Spacing | `CoreSpace` | 46 steps (`space0`–`space256`) |
| Shape | `CoreRadius` | 19 levels (`radius0`–`radius64`, `radius9999`) |
| Size | `CoreComponentSize` | 5 (xs/sm/md/lg/xl) |
| Motion | `CoreDuration` + `CoreEasing` + `CoreSpringConfig` | semantic duration aliases, easing curves, 5 spring presets |
| Surface | `CoreSurfaceToken` | 3 types (flat/tonalElevation/glass) |

### CoreThemeData

```dart
import 'package:coui_core/coui_core.dart';

final theme = CoreThemeData(
  // CoUI's own colours — a brand palette is CouiSemanticColors(palette)
  colorScheme: CouiSemanticColors.from(CouiColorPresets.source).light,
  brightness: CoreBrightness.light,          // light | dark
  designSystem: DesignSystem.couiWeb,        // couiWeb | m3Expressive | liquidGlass
  typography: CoreTypography.coui,
);

// Dark mode variant
final darkTheme = theme.copyWith(
  colorScheme: darkColors,
  brightness: CoreBrightness.dark,
);
```

### Web Theme

Theme switching via the `data-theme` attribute on `<html>`. `ThemeConfig`
defines `--coui-*` variables for two themes — `light` and `dark`:

```dart
CoUIThemeController.setTheme(CoUIThemeController.dark);
CoUIThemeController.toggleDarkMode();

// A custom palette is pushed as CSS variables instead of a theme name.
CoUIThemeController.setCustomTheme(myColorScheme);
```

## Development

This is a Dart workspace managed with [Melos](https://melos.invertase.dev/).

```bash
# Install Melos
dart pub global activate melos

# Bootstrap workspace
melos bootstrap

# Run analysis
melos run analyze:all

# Run tests
melos run test
```




---

Built for the Dart & Flutter community.
