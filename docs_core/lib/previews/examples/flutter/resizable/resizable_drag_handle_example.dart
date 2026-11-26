import 'package:coui_flutter/coui_flutter.dart';

class ResizableDragHandleExample extends StatelessWidget {
  const ResizableDragHandleExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textStyle = theme.typography.bodyMedium
        .toValue(theme: theme)
        .copyWith(
          color: scheme.onSurface.toValue(),
        );
    return SizedBox(
      height: 200,
      child: Resizable(
        showDragHandle: true,
        panes: [
          CoreResizablePaneData(
            content: Container(
              color: scheme.surfaceContainer.toValue(),
              alignment: Alignment.center,
              child: Text('영역 1', style: textStyle),
            ),
            initialSize: 0.4,
          ),
          CoreResizablePaneData(
            content: Container(
              color: scheme.surfaceContainerHigh.toValue(),
              alignment: Alignment.center,
              child: Text('영역 2', style: textStyle),
            ),
            initialSize: 0.6,
          ),
        ],
      ),
    );
  }
}
