/// Returns a Web code snippet string for the Resizable component.
String resizableCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
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
                    'flex items-center justify-center bg-\${cs.surfaceContainer} text-\${cs.onSurface} text-\${CoreTextStyles.bodyMedium.name} h-full',
              ),
              initialSize: 0.4,
            ),
            CoreResizablePaneData<Component>(
              content: div(
                [Text('영역 2')],
                classes:
                    'flex items-center justify-center bg-\${cs.surfaceContainerHigh} text-\${cs.onSurface} text-\${CoreTextStyles.bodyMedium.name} h-full',
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
}''',
    'drag-handle' =>
      '''
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
                classes: 'flex items-center justify-center bg-\${cs.surfaceContainer} text-\${cs.onSurface} h-full',
              ),
              initialSize: 0.4,
            ),
            CoreResizablePaneData<Component>(
              content: div(
                [Text('영역 2')],
                classes: 'flex items-center justify-center bg-\${cs.surfaceContainerHigh} text-\${cs.onSurface} h-full',
              ),
              initialSize: 0.6,
            ),
          ],
        ),
      ],
      styles: Styles(raw: {'width': '100%', 'height': '200px'}),
    );
  }
}''',
    'vertical' =>
      '''
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
                classes: 'flex items-center justify-center bg-\${cs.surfaceContainer} text-\${cs.onSurface} h-full',
              ),
              initialSize: 0.5,
            ),
            CoreResizablePaneData<Component>(
              content: div(
                [Text('아래쪽')],
                classes: 'flex items-center justify-center bg-\${cs.surfaceContainerHigh} text-\${cs.onSurface} h-full',
              ),
              initialSize: 0.5,
            ),
          ],
        ),
      ],
      styles: Styles(raw: {'width': '100%', 'height': '260px'}),
    );
  }
}''',
    _ =>
      '''
class ResizableDefaultExample extends StatelessComponent {
  const ResizableDefaultExample({super.key});

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
                classes: 'flex items-center justify-center bg-\${cs.surfaceContainer} text-\${cs.onSurface} h-full',
              ),
              initialSize: 0.4,
            ),
            CoreResizablePaneData<Component>(
              content: div(
                [Text('영역 2')],
                classes: 'flex items-center justify-center bg-\${cs.surfaceContainerHigh} text-\${cs.onSurface} h-full',
              ),
              initialSize: 0.6,
            ),
          ],
        ),
      ],
      styles: Styles(raw: {'width': '100%', 'height': '200px'}),
    );
  }
}''',
  };
}
