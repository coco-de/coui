# CoUI Core

CoUI Core defines the design tokens, theme presets, and component contracts used by CoUI's Flutter and Jaspr packages. A value such as `CoreSpace.space16` has a shared meaning across apps and websites. Flutter resolves it to a layout value, and Jaspr can use it through a utility such as `p-space16`. [Foundations](https://coui.cocode.im/tokens/overview/)

## Use Core in shared Dart code

Flutter and Web bring in Core as a dependency. Add it directly when a Dart package needs to refer to the same tokens and types across platforms.

```sh
dart pub add coui_core
```

```dart
import 'package:coui_core/coui_core.dart';

const saveButtonVariant = CoreButtonVariant.primary;
const formSpacing = CoreSpace.space16;
```

See how those values reach a rendered component in the platform packages. [CoUI Flutter](https://pub.dev/packages/coui_flutter) · [CoUI Web](https://pub.dev/packages/coui_web) · [Component catalog](https://coui.cocode.im/components-overview/)

## License

CoUI Core is maintained by Cocode Inc. under the MIT License. [License](LICENSE) · [CoUI repository](https://github.com/coco-de/coui)
