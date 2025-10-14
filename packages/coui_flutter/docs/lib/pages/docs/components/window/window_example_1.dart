import 'package:docs/debug.dart';
import 'package:coui_flutter/coui_flutter.dart';

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
                title: const Text('Window 1'),
              ),
              Window(
                bounds: const Rect.fromLTWH(200, 0, 200, 200),
                content: const RebuildCounter(),
                title: const Text('Window 2'),
              ),
            ],
            key: navigatorKey,
            child: const Center(child: Text('Desktop')),
          ),
        ),
        PrimaryButton(
          child: const Text('Add Window'),
          onPressed: () {
            navigatorKey.currentState?.pushWindow(
              Window(
                bounds: const Rect.fromLTWH(0, 0, 200, 200),
                content: const RebuildCounter(),
                title: Text(
                  'Window ${navigatorKey.currentState!.windows.length + 1}',
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
