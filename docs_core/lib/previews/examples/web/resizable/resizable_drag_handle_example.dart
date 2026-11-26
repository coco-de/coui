import 'package:coui_web/coui_web.dart';

class ResizableDragHandleExample extends StatelessComponent {
  const ResizableDragHandleExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.colorScheme;
    return div(
      [
        Resizable(
          showDragHandle: true,
          panes: [
            CoreResizablePaneData<Component>(
              content: div(
                [Text('영역 1')],
                classes:
                    'flex items-center justify-center bg-${cs.surfaceContainer} text-${cs.onSurface} text-${CoreTextStyles.bodyMedium.name} h-full',
              ),
              initialSize: 0.4,
            ),
            CoreResizablePaneData<Component>(
              content: div(
                [Text('영역 2')],
                classes:
                    'flex items-center justify-center bg-${cs.surfaceContainerHigh} text-${cs.onSurface} text-${CoreTextStyles.bodyMedium.name} h-full',
              ),
              initialSize: 0.6,
            ),
          ],
        ),
      ],
      classes: 'coui-resizable-preview',
      styles: Styles(raw: {'width': '100%', 'height': '200px'}),
    );
  }
}
