import 'package:coui_web/coui_web.dart';

/// Default preview for the unified Web `Window` + `WindowNavigator`.
/// Mirrors shadcn_flutter's official `WindowExample1`: two pre-populated
/// draggable windows on a 600-pixel desktop surface, plus a primary
/// button that pushes a new window at runtime.
class WindowDefaultExample extends StatefulComponent {
  const WindowDefaultExample({super.key});

  @override
  State<WindowDefaultExample> createState() => _WindowDefaultExampleState();
}

class _WindowDefaultExampleState extends State<WindowDefaultExample> {
  final GlobalKey _navigatorKey = GlobalKey();

  @override
  Component build(BuildContext context) {
    return div(
      [
        OutlinedContainer(
          containerStyle: const CoreOutlinedContainerStyle(height: 600),
          child: WindowNavigator(
            key: _navigatorKey,
            initialWindows: [
              Window(
                bounds: const CoreWindowRect.fromLTWH(0, 0, 200, 200),
                title: const Text('창 1'),
                content: div(
                  [const Text('창 1')],
                  classes: 'flex items-center justify-center w-full h-full',
                ),
              ),
              Window(
                bounds: const CoreWindowRect.fromLTWH(200, 0, 200, 200),
                title: const Text('창 2'),
                content: div(
                  [const Text('창 2')],
                  classes: 'flex items-center justify-center w-full h-full',
                ),
              ),
            ],
            child: div(
              [const Text('데스크톱')],
              classes: 'flex items-center justify-center w-full h-full',
            ),
          ),
        ),
        Gap.space8(),
        Button(
          onPressed: () {
            final nav = _navigatorKey.currentWindowNavigator;
            if (nav == null) return;
            final index = nav.windows.length + 1;
            nav.pushWindow(
              Window(
                bounds: const CoreWindowRect.fromLTWH(0, 0, 200, 200),
                title: Text('창 $index'),
                content: div(
                  [Text('창 $index')],
                  classes: 'flex items-center justify-center w-full h-full',
                ),
              ),
            );
          },
          child: const Text('창 추가'),
        ),
      ],
      classes: 'flex flex-col w-full',
    );
  }
}
