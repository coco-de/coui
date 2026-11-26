/// Returns a Flutter code snippet string for the Resizable component.
String resizableCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class ResizableChainExample extends StatelessWidget {
  const ResizableChainExample({super.key});

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
      child:
          Resizable(
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
          ).withStyle(
            const CoreResizableStyle(
              dividerThickness: CoreStrokeWidth.stroke6,
              dividerColor: CoreColor.token(CoreColors.primary),
              dividerHoverColor: CoreColor.token(CoreColors.tertiary),
              handleLength: CoreSize.size32,
            ),
          ),
    );
  }
}''',
    'drag-handle' =>
      '''
class ResizableDragHandleExample extends StatelessWidget {
  const ResizableDragHandleExample({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onSurface = scheme.onSurface.toValue();
    return SizedBox(
      height: 200,
      child: Resizable(
        showDragHandle: true,
        panes: [
          CoreResizablePaneData(
            content: Container(
              color: scheme.surfaceContainer.toValue(),
              alignment: Alignment.center,
              child: Text('영역 1', style: TextStyle(color: onSurface)),
            ),
            initialSize: 0.4,
          ),
          CoreResizablePaneData(
            content: Container(
              color: scheme.surfaceContainerHigh.toValue(),
              alignment: Alignment.center,
              child: Text('영역 2', style: TextStyle(color: onSurface)),
            ),
            initialSize: 0.6,
          ),
        ],
      ),
    );
  }
}''',
    'vertical' =>
      '''
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
}''',
    _ =>
      '''
class ResizableDefaultExample extends StatelessWidget {
  const ResizableDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onSurface = scheme.onSurface.toValue();
    return SizedBox(
      height: 200,
      child: Resizable(
        panes: [
          CoreResizablePaneData(
            content: Container(
              color: scheme.surfaceContainer.toValue(),
              alignment: Alignment.center,
              child: Text('영역 1', style: TextStyle(color: onSurface)),
            ),
            initialSize: 0.4,
          ),
          CoreResizablePaneData(
            content: Container(
              color: scheme.surfaceContainerHigh.toValue(),
              alignment: Alignment.center,
              child: Text('영역 2', style: TextStyle(color: onSurface)),
            ),
            initialSize: 0.6,
          ),
        ],
      ),
    );
  }
}''',
  };
}
