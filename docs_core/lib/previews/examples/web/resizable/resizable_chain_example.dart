import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreResizableStyle] slot without constructing the
/// component from scratch.
class ResizableChainExample extends StatelessComponent {
  const ResizableChainExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.colorScheme;
    return div(
      [
        Resizable(
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
        ).withStyle(
          const CoreResizableStyle(
            dividerThickness: CoreStrokeWidth.stroke6,
            dividerColor: CoreColor.token(CoreColors.primary),
            dividerHoverColor: CoreColor.token(CoreColors.tertiary),
            handleLength: CoreSize.size32,
          ),
        ),
      ],
      classes: 'coui-resizable-preview',
      styles: Styles(raw: {'width': '100%', 'height': '200px'}),
    );
  }
}
