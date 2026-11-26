import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'window.stories.g.dart';

// Window demo layout constants.
const _kNavigatorWidth = 600.0;
const _kNavigatorHeight = 400.0;
const _kWindowWidth = 300.0;
const _kWindowHeight = 200.0;
const _kWindow1Left = 20.0;
const _kWindow1Top = 20.0;
const _kWindow2Left = 150.0;
const _kWindow2Top = 80.0;

/// Demo host for [WindowNavigator] stories.
///
/// Renders two draggable windows inside a fixed-size navigator area.
class WindowDemo extends StatelessWidget {
  /// Creates a [WindowDemo].
  const WindowDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _kNavigatorWidth,
      height: _kNavigatorHeight,
      child: WindowNavigator(
        initialWindows: [
          Window(
            bounds: const CoreWindowRect.fromLTWH(
              _kWindow1Left,
              _kWindow1Top,
              _kWindowWidth,
              _kWindowHeight,
            ),
            content: Padding(
              padding: const .all(CoreSpace.space16),
              child: Center(
                child: const Text('Window 1').bodyLarge(),
              ),
            ),
            title: const Text('Window 1'),
          ),
          Window(
            bounds: const CoreWindowRect.fromLTWH(
              _kWindow2Left,
              _kWindow2Top,
              _kWindowWidth,
              _kWindowHeight,
            ),
            content: Padding(
              padding: const .all(CoreSpace.space16),
              child: Center(
                child: const Text('Window 2').bodyLarge(),
              ),
            ),
            title: const Text('Window 2'),
          ),
        ],
      ),
    );
  }
}

/// Navigation metadata for the Window component.
const kComponentMeta = ComponentMeta(name: 'Window', path: 'layout');

/// Story metadata for [WindowDemo].
const kMeta = Meta(WindowDemo.new);

/// Two overlapping draggable windows.
final $Default = _Story();
