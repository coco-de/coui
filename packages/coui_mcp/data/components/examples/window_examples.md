# Window Examples

This document contains example code for the window component.

## Table of Contents

- [Example 1: Basic Example](#example-1)

## Example 1

**Basic Example**

```dart
import 'package:docs/debug.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class WindowExample1 extends StatefulWidget {
  const WindowExample1({super.key});

  @override
  State<WindowExample1> createState() => _WindowExample1State();
}

class _WindowExample1State extends State<WindowExample1> {
  final GlobalKey<WindowNavigatorHandle> navigatorKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedContainer(
          // for example purpose
          height: 600,
          // for example purpose
          child: WindowNavigator(
            initialWindows: [
              Window(
                bounds: const Rect.fromLTWH(0, 0, 200, 200),
                content: const RebuildCounter(),
                title: Text(t.docs.components.window.window_1),
              ),
              Window(
                bounds: const Rect.fromLTWH(200, 0, 200, 200),
                content: const RebuildCounter(),
                title: Text(t.docs.components.window.window_2),
              ),
            ],
            key: navigatorKey,
            child: Center(child: Text(t.docs.components.window.desktop)),
          ),
        ),
        PrimaryButton(
          child: Text(t.docs.components.window.add_window),
          onPressed: () {
            navigatorKey.currentState?.pushWindow(
              Window(
                bounds: const Rect.fromLTWH(0, 0, 200, 200),
                content: const RebuildCounter(),
                title: Text(
                  '${t.docs.components.window.display_name} ${navigatorKey.currentState!.windows.length + 1}',
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

```

