---
name: coui-theme
description: Activate when configuring CoUI theming across Flutter or Web — ThemeData, ColorScheme, Typography, RadiusScale, design tokens, light/dark mode, CoUI themes, ThemeController components, CSS variables, or adaptive scaling.
---

# CoUI Theme

## Overview

CoUI provides a unified theming system across Flutter and Web platforms. Both share CoUI semantic color tokens and radius scales, but differ in implementation: Flutter uses a `Theme` widget with `ThemeData`, while Web uses CoUI CSS themes with `ThemeController` components.

## Flutter (coui_flutter)

### Theme Widget

coui_flutter uses its own `Theme` widget (not Flutter's `ThemeData`). Wrap your app:

```dart
import 'package:coui_flutter/coui_flutter.dart';

Theme(
  data: const ThemeData(),  // light theme
  child: MyApp(),
)

Theme(
  data: const ThemeData.dark(),  // dark theme
  child: MyApp(),
)
```

### Accessing Theme

```dart
final theme = Theme.of(context);
final colors = theme.colorScheme;
final typo = theme.typography;
final scaling = theme.scaling;
```

### ThemeData Constructor

```dart
const ThemeData({
  ColorScheme colorScheme = ColorSchemes.lightDefaultColor,
  ComponentThemeData? componentTheme,
  IconThemeProperties iconTheme = const IconThemeProperties(),
  TargetPlatform? platform,
  RadiusScale radiusScale = const RadiusScale.couiWeb(),
  double scaling = 1,
  double? surfaceBlur,
  double? surfaceOpacity,
  Typography typography = const Typography.geist(),
})
```

### ColorScheme

Access semantic colors:

```dart
final cs = theme.colorScheme;

cs.primary        // Primary brand color
cs.primaryContent // Text on primary
cs.neutral        // Neutral/border color
cs.base100        // Background level 1
cs.base200        // Background level 2 (muted text)
cs.base300        // Background level 3
cs.baseContent    // Default text color
cs.brightness     // Brightness.light or .dark
```

Built-in schemes:
- `ColorSchemes.lightDefaultColor` (default light)
- `ColorSchemes.darkDefaultColor` (default dark)

### Typography

```dart
const ThemeData(
  typography: const Typography.geist(),  // default
)
```

Access text styles via extensions:
```dart
theme.typography.xs    // extra small
theme.typography.sm    // small
theme.typography.base  // base
theme.typography.lg    // large
```

Or use widget extensions:
```dart
const Text('Hello').xs
const Text('Hello').sm
const Text('Hello').lg
```

### RadiusScale (CoUI Semantic)

```dart
theme.radiusBox       // cards, dialogs, panels
theme.radiusField     // inputs, form elements
theme.radiusSelector  // buttons, interactive elements

theme.borderRadiusBox
theme.borderRadiusField
theme.borderRadiusSelector
```

### Scaling

```dart
theme.scaling  // default 1.0
```

All components respect `theme.scaling` for consistent sizing across platforms.

### AdaptiveScaling

Scale a subtree:

```dart
AdaptiveScaler(
  scaling: const AdaptiveScaling(1.25),  // 1.25x
  child: MyWidget(),
)

// Or use defaults based on platform (1 on every platform)
AdaptiveScaler(
  scaling: AdaptiveScaler.defaultScalingOf(context),
  child: MyWidget(),
)
```

`CoUIApp` applies the platform default when it is given no `scaling`, so an
app renders at 1 on iOS and Android as it does on desktop. To scale larger,
pass a factor: `CoUIApp(scaling: const AdaptiveScaling(1.25), ...)`.

### AnimatedTheme

Smoothly transition between themes:

```dart
AnimatedTheme(
  data: isDark ? const ThemeData.dark() : const ThemeData(),
  duration: const Duration(milliseconds: 300),
  child: MyApp(),
)
```

### ComponentTheme

Apply component-level theme overrides:

```dart
Theme(
  data: ThemeData(
    componentTheme: ComponentThemeData(
      // Override specific component themes
    ),
  ),
  child: MyApp(),
)
```

### IconThemeProperties

Control icon sizes at theme level:

```dart
theme.iconTheme.small   // IconThemeData(size: 16)
theme.iconTheme.medium  // IconThemeData(size: 20)
theme.iconTheme.large   // IconThemeData(size: 24)
theme.iconTheme.xLarge  // IconThemeData(size: 32)
```

### ThemeMode

```dart
enum ThemeMode { dark, light, system }
```

### copyWith Pattern

```dart
final customTheme = theme.copyWith(
  colorScheme: () => myColorScheme,
  typography: () => const Typography.geist(),
  scaling: () => 1.25,
);
```

Note: `copyWith` uses `ValueGetter` lambdas (not direct values).

## Web (coui_web)

### Import

```dart
import 'package:coui_web/coui_web.dart';
```

### Theme names — `light` and `dark`

Web themes switch through the `data-theme` attribute on `<html>`. `ThemeConfig`
defines `--coui-*` variables for two themes, `light` and `dark`; any other
`data-theme` value has no definition behind it and changes nothing.

```dart
CoUIThemeController.setTheme(CoUIThemeController.dark);
CoUIThemeController.toggleDarkMode();
CoUIThemeController.useSystemPreference();
CoUIThemeController.watchSystemPreference((isDark) {
  CoUIThemeController.setTheme(
    isDark ? CoUIThemeController.dark : CoUIThemeController.light,
  );
});
```

A custom palette is not a theme name — push it as CSS variables:

```dart
CoUIThemeController.setCustomTheme(
  myColorScheme,
  brightness: CoreBrightness.dark,
);
```

The daisyUI-style names still on `CoUIThemeController` (`cupcake`, `cyberpunk`,
…) are deprecated: none of them has a CSS definition.

### Application root — `CoUIWeb`

```dart
runApp(
  CoUIWeb(
    theme: ThemeData.light,
    darkTheme: ThemeData.dark,
    themeMode: CoreThemeMode.system,
    child: const App(),
  ),
);
```

`ThemeData` exposes `coui`, `defaults`, `light` and `dark`, plus
`ThemeData.fromCore(coreThemeData)`.

### ThemeController — a theme picker

`ThemeController` is a selection UI (a grid of palette swatches), not an app
wrapper. It reports the picked name; applying it is the caller's job:

```dart
ThemeController(
  themes: const [
    CoreThemeOption(
      name: 'light',
      primaryColor: CoreColor.token(CoreColors.primary),
    ),
    CoreThemeOption(
      name: 'dark',
      primaryColor: CoreColor.token(CoreColors.primary),
    ),
  ],
  selectedTheme: 'light',
  onThemeChanged: CoUIThemeController.setTheme,
)
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `themes` | `List<CoreThemeOption>` | required | Swatches to show (`name`, `primaryColor`, optional `secondaryColor` / `accentColor` / `neutralColor`) |
| `onThemeChanged` | `CoreValueChanged<String>` | required | Called with the picked theme name |
| `selectedTheme` | `String?` | `null` | Name of the swatch shown as selected |
| `size` | `CoreThemeControllerSize` | `md` | Swatch size (`sm` / `md` / `lg`) |
| `enabled` | `bool` | `true` | Disables every swatch when `false` |
| `themeControllerStyle` | `CoreThemeControllerStyle?` | `null` | Chrome overrides |

### Theme CSS Variables

Every semantic colour token is a `--coui-<token>` variable holding a bare
`R G B` triplet (e.g. `--coui-on-surface: 195 196 198`), so it is read as
`rgb(var(--coui-on-surface))`. Tailwind classes such as `bg-primary` and
`text-on-surface` resolve through these variables, which is why a
`data-theme` flip repaints without a rebuild.

## Common Patterns

### Semantic Color Tokens (shared across platforms)

Both Flutter and Web use CoUI semantic color tokens:

| Token | Flutter (`ColorScheme`) | Web (CSS Variable) | Purpose |
|-------|------------------------|-------------------|---------|
| primary | `cs.primary` | `--p` / `bg-primary` | Brand color |
| primary-content | `cs.primaryContent` | `--pc` / `text-primary-content` | Text on primary |
| neutral | `cs.neutral` | `--n` / `bg-neutral` | Neutral/border |
| base-100 | `cs.base100` | `--b1` / `bg-base-100` | Background level 1 |
| base-200 | `cs.base200` | `--b2` / `bg-base-200` | Background level 2 |
| base-300 | `cs.base300` | `--b3` / `bg-base-300` | Background level 3 |
| base-content | `cs.baseContent` | `--bc` / `text-base-content` | Default text |

### Light/Dark Mode

Both platforms support light, dark, and system modes:

```dart
// Flutter
Theme(data: const ThemeData(), child: app)       // light
Theme(data: const ThemeData.dark(), child: app)   // dark

// Web
CoUIThemeController.setTheme(CoUIThemeController.dark);
```

### CoUI Radius Scale

Both platforms share the CoUI semantic radius scale with three levels:
- **Box** — cards, dialogs, panels
- **Field** — inputs, form elements
- **Selector** — buttons, interactive elements
