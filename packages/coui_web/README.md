# CoUI for Jaspr Web

Build web pages in Dart with CoUI's component library for Jaspr. The Web package uses the same design tokens and component vocabulary as CoUI Flutter. Tailwind utilities and `--coui-*` CSS variables bring those values into the browser. [Foundations](https://coui.cocode.im/tokens/overview/) · [Component catalog](https://coui.cocode.im/components-overview/)

## Get started

Use Dart 3.11 or later and Jaspr `>=0.23.5 <0.25.0`.

```sh
dart pub add coui_web
```

Wrap your Jaspr page in `CoUIWeb` to make its theme available to the components. In the document head, load Tailwind CSS 3 and the Tailwind configuration and CSS variables from `ThemeConfig.defaults()`. The quick start includes the complete setup. [Getting Started](https://coui.cocode.im/getting-started/)

```dart
import 'package:coui_web/coui_web.dart';

class App extends StatelessComponent {
  const App({super.key});

  @override
  Component build(BuildContext context) {
    return CoUIWeb(
      theme: ThemeData.coui,
      child: Button(
        variant: CoreButtonVariant.primary,
        onPressed: () {},
        child: const Text('Save changes'),
      ),
    );
  }
}
```

Preview the button and its Flutter counterpart in the catalog. For page layouts and theme options, see the block catalog and theming guide. [Button](https://coui.cocode.im/components/button/) · [Blocks](https://coui.cocode.im/blocks/) · [Theming](https://coui.cocode.im/guides/theming/)

CoUI is pre-1.0 and public APIs can change between releases. [Changelog](CHANGELOG.md) · [Deprecation policy](https://github.com/coco-de/coui/blob/main/docs/contributing/upgrading.md#deprecation)

## Credits and license

CoUI Web's component structure, the `UiComponent` and `UiComponentAttributes` base classes, and portions of its documentation comments originate from Deepyr by Philipp H. Gerber, licensed under the MIT License. The implementations here have largely been rewritten. [Deepyr](https://pub.dev/packages/deepyr)

The package license includes the upstream terms. See the repository's NOTICE for full attribution. [License](LICENSE) · [NOTICE](https://github.com/coco-de/coui/blob/main/NOTICE)
