import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreWindowStyle] slot without constructing the widget
/// from scratch.
class WindowChainExample extends StatefulWidget {
  const WindowChainExample({super.key});

  @override
  State<WindowChainExample> createState() => _WindowChainExampleState();
}

class _WindowChainExampleState extends State<WindowChainExample> {
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
