# CoUI Core

Platform-independent design tokens, themes, and component contracts shared by
[CoUI Flutter](https://pub.dev/packages/coui_flutter) and
[CoUI Web](https://pub.dev/packages/coui_web). Add Core directly when Dart code
needs to share these types across platforms.

```sh
dart pub add coui_core
```

```dart
import 'package:coui_core/coui_core.dart';

const buttonVariant = CoreButtonVariant.primary;
final outlineStroke = CoreStrokeWidth.stroke1;
```

See the [CoUI component catalog](https://coui.cocode.im/) for examples and
[the source repository](https://github.com/coco-de/coui) for contribution details.
