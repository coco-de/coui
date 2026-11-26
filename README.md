# CoUI

CoUI is a design system for Flutter apps and Jaspr websites. Design a button, a form, or a navigation pattern in Figma, then use the same component names and shared design tokens to build it in Dart. [CoUI documentation](https://coui.cocode.im/) · [한국어](README.ko-kr.md)

[![Package checks](https://github.com/coco-de/coui/actions/workflows/public-ci.yml/badge.svg)](https://github.com/coco-de/coui/actions/workflows/public-ci.yml)

## Start with a button

| Platform | Install | App setup |
| --- | --- | --- |
| Flutter | `flutter pub add coui_flutter` | Apply the theme at the root with `CoUIApp`. [Flutter setup](packages/coui_flutter/README.md) |
| Jaspr Web | `dart pub add coui_web` | Wrap your app in `CoUIWeb` and load the theme's CSS variables and Tailwind configuration. [Web setup](packages/coui_web/README.md) |

The primary button uses the same name and properties on both platforms. Import `coui_flutter.dart` or `coui_web.dart` for your target.

```dart
Button(
  variant: CoreButtonVariant.primary,
  onPressed: saveChanges,
  child: const Text('Save changes'),
)
```

The quick start walks through the app root and the first component for each platform. [Getting Started](https://coui.cocode.im/getting-started/) · [Button preview and code](https://coui.cocode.im/components/button/)

## Explore the design system

- **Foundations** covers the colors, type, spacing, shape, and motion shared across platforms. Core defines the values. Flutter resolves them into widget styles, and Jaspr uses them through CSS variables and Tailwind utilities. [Foundations](https://coui.cocode.im/tokens/overview/) · [CoUI Core](packages/coui_core/README.md)
- **Components** pairs live previews with Flutter and Web examples. Use the docs theme picker to see how surface styles such as Liquid Glass change the same components. [Component catalog](https://coui.cocode.im/components-overview/)
- **Blocks** gives you starting layouts for page sections such as a hero or footer. [Block catalog](https://coui.cocode.im/blocks/)
- **Resources** takes you to the Figma library, theme setup, and the MCP guide for looking up components and tokens from an editor. [Figma library](https://coui.cocode.im/guides/figma-library/) · [Theming](https://coui.cocode.im/guides/theming/) · [AI and MCP](https://coui.cocode.im/guides/mcp/)

## Contribute to CoUI

The contributor guide covers workspace setup, shared component changes, and verification across Flutter, Web, and Figma. [Contributing](CONTRIBUTING.md) · [한국어 기여 가이드](docs/contributing/README.md)

CoUI is pre-1.0 and public APIs can change between releases. Check the release notes and deprecation policy when upgrading. [Changelog](https://coui.cocode.im/changelog/) · [Deprecation policy](docs/contributing/upgrading.md#deprecation)

## License and credits

Cocode Inc. maintains CoUI. The repository notice documents the upstream projects and third-party terms. [License](LICENSE) · [Third-party notices](NOTICE) · [Cocode](https://cocode.im/)
