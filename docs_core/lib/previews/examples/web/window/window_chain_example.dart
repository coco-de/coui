import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreWindowStyle] slot without constructing the widget
/// from scratch.
class WindowChainExample extends StatefulComponent {
  const WindowChainExample({super.key});

  @override
  State<WindowChainExample> createState() => _WindowChainExampleState();
}

class _WindowChainExampleState extends State<WindowChainExample> {
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
              ).withStyle(
                const CoreWindowStyle(
                  titleBarHeight: CoreSpace.space48,
                  unfocusedTitleStyle: CoreTextStyle(
                    color: CoreColor.token(CoreColors.outline),
                  ),
                  panelStyle: CoreWindowPanelStyle(
                    borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
                    borderColor: CoreColor.token(CoreColors.primary),
                    containerBorderWidth: CoreStrokeWidth.stroke2,
                  ),
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
