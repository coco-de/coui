import 'package:coui_flutter/coui_flutter.dart';

class ResizableVerticalExample extends StatelessWidget {
  const ResizableVerticalExample({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onSurface = scheme.onSurface.toValue();
    return SizedBox(
      height: 260,
      child: Resizable(
        direction: CoreResizableDirection.vertical,
        panes: [
          CoreResizablePaneData(
            content: Container(
              color: scheme.surfaceContainer.toValue(),
              alignment: Alignment.center,
              child: Text('위쪽', style: TextStyle(color: onSurface)),
            ),
            initialSize: 0.5,
          ),
          CoreResizablePaneData(
            content: Container(
              color: scheme.surfaceContainerHigh.toValue(),
              alignment: Alignment.center,
              child: Text('아래쪽', style: TextStyle(color: onSurface)),
            ),
            initialSize: 0.5,
          ),
        ],
      ),
    );
  }
}
