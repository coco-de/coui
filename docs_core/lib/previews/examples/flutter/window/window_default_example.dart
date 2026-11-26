import 'package:coui_flutter/coui_flutter.dart';

/// Default preview for the unified `Window` + `WindowNavigator`.
/// Mirrors shadcn_flutter's official `WindowExample1`: two pre-populated
/// draggable windows on a 600-pixel desktop surface, plus a primary button
/// that pushes a new window at runtime.
class WindowDefaultExample extends StatefulWidget {
  const WindowDefaultExample({super.key});

  @override
  State<WindowDefaultExample> createState() => _WindowDefaultExampleState();
}

class _WindowDefaultExampleState extends State<WindowDefaultExample> {
  final GlobalKey<WindowNavigatorHandle> _navigatorKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedContainer(
          containerStyle: const CoreOutlinedContainerStyle(height: 600),
          child: WindowNavigator(
            key: _navigatorKey,
            initialWindows: [
              Window(
                bounds: const CoreWindowRect.fromLTWH(0, 0, 200, 200),
                title: const Text('창 1'),
                content: const Center(child: Text('창 1')),
              ),
              Window(
                bounds: const CoreWindowRect.fromLTWH(200, 0, 200, 200),
                title: const Text('창 2'),
                content: const Center(child: Text('창 2')),
              ),
            ],
            child: const Center(child: Text('데스크톱')),
          ),
        ),
        const Gap.space8(),
        Button(
          onPressed: () {
            final nav = _navigatorKey.currentState;
            if (nav == null) return;
            final index = nav.windows.length + 1;
            nav.pushWindow(
              Window(
                bounds: const CoreWindowRect.fromLTWH(0, 0, 200, 200),
                title: Text('창 $index'),
                content: Center(child: Text('창 $index')),
              ),
            );
          },
          child: const Text('창 추가'),
        ),
      ],
    );
  }
}
