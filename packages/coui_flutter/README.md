# CoUI for Flutter

Build Flutter app screens with the same component names and design tokens used in CoUI's Figma library and Jaspr examples. The component catalog pairs live previews with the Dart code and the properties that control each state. [Component catalog](https://coui.cocode.im/components-overview/) · [Figma library](https://coui.cocode.im/guides/figma-library/)

## Get started

Use Flutter 3.47 or later and Dart 3.12 or later. Add CoUI to your Flutter app.

```sh
flutter pub add coui_flutter
```

Set up the theme at the app root and add a primary button. The CoUI import provides the Flutter types used here.

```dart
import 'package:coui_flutter/coui_flutter.dart';

void main() {
  runApp(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      home: Center(
        child: Button(
          variant: CoreButtonVariant.primary,
          onPressed: () {},
          child: const Text('Save changes'),
        ),
      ),
    ),
  );
}
```

Add your action in the button callback. The quick start covers the setup, and the theming guide shows how to apply a brand palette and choose a surface style. [Getting Started](https://coui.cocode.im/getting-started/) · [Theming](https://coui.cocode.im/guides/theming/)

CoUI is pre-1.0 and public APIs can change between releases. [Changelog](CHANGELOG.md) · [Deprecation policy](https://github.com/coco-de/coui/blob/main/docs/contributing/upgrading.md#deprecation)

## Credits and license

The component taxonomy, public API surface, and portions of the documentation comments originate from `shadcn_flutter` by Thito Yalasatria Sunarya, licensed under the BSD 3-Clause License. The implementations here have largely been rewritten. [shadcn_flutter](https://github.com/sunarya-thito/shadcn_flutter)

CoUI Flutter is licensed under the BSD 3-Clause License. The package notice contains third-party license terms. [License](LICENSE) · [NOTICE](NOTICE)
