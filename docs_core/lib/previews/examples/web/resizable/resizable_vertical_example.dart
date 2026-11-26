import 'package:coui_web/coui_web.dart';

class ResizableVerticalExample extends StatelessComponent {
  const ResizableVerticalExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.colorScheme;
    return div(
      [
        Resizable(
          direction: CoreResizableDirection.vertical,
          panes: [
            CoreResizablePaneData<Component>(
              content: div(
                [Text('위쪽')],
                classes: 'flex items-center justify-center bg-${cs.surfaceContainer} text-${cs.onSurface} h-full',
              ),
              initialSize: 0.5,
            ),
            CoreResizablePaneData<Component>(
              content: div(
                [Text('아래쪽')],
                classes: 'flex items-center justify-center bg-${cs.surfaceContainerHigh} text-${cs.onSurface} h-full',
              ),
              initialSize: 0.5,
            ),
          ],
        ),
      ],
      classes: 'coui-resizable-preview',
      styles: Styles(raw: {'width': '100%', 'height': '260px'}),
    );
  }
}
