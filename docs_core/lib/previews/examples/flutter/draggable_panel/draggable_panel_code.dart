/// Source snippet for the Flutter `DraggablePanel` default preview.
///
/// Must mirror `draggable_panel_default_example.dart` verbatim (minus
/// imports) so the docs site's "View code" tab stays in sync.
String draggablePanelCode(String? variant) => switch (variant) {
  'chain' => _chainCode,
  'outside' => _outsideCode,
  _ => _defaultCode,
};

const String _chainCode = '''
class DraggablePanelChainExample extends StatefulWidget {
  const DraggablePanelChainExample({super.key});

  @override
  State<DraggablePanelChainExample> createState() => _DraggablePanelChainExampleState();
}

class _DraggablePanelChainExampleState extends State<DraggablePanelChainExample> {
  final CoreDraggablePanelController _controller = CoreDraggablePanelController(initiallyOpen: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 360,
      height: 360,
      child:
          DraggablePanel(
            controller: _controller,
            panel: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: Theme.of(context).geometry.space(CoreSpace.space8),
              children: [
                const Text('펜').bodyMedium,
                const Text('지우개').bodyMedium,
                const Text('색상').bodyMedium,
              ],
            ),
            child: ColoredBox(
              color: theme.colorScheme.surfaceContainerLow.toValue(),
              child: Center(child: const Text('캔버스').bodyMedium),
            ),
          ).withStyle(
            const CoreDraggablePanelStyle(
              panelBackgroundColor: CoreColor.token(
                CoreColors.surfaceContainerHighest,
              ),
              panelBorderColor: CoreColor.token(CoreColors.primary),
              panelBorderWidth: CoreStrokeWidth.stroke2,
              panelBorderRadius: CoreBorderRadius.all(CoreRadius.radius24),
              handleBorderRadius: CoreBorderRadius.all(CoreRadius.radius4),
              handleBackgroundColor: CoreColor.token(
                CoreColors.primaryContainer,
              ),
              handleIconStyle: CoreIconStyle(
                size: CoreIconSize.size24,
                color: CoreColor.token(CoreColors.onPrimaryContainer),
              ),
            ),
          ),
    );
  }
}
''';

const String _outsideCode = '''
class DraggablePanelOutsideExample extends StatelessWidget {
  const DraggablePanelOutsideExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 360,
      height: 360,
      child: DraggablePanel(
        dockType: CoreDraggablePanelDockType.outside,
        panel: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Theme.of(context).geometry.space(CoreSpace.space8),
          children: [
            const Text('펜').bodyMedium,
            const Text('지우개').bodyMedium,
            const Text('색상').bodyMedium,
          ],
        ),
        child: ColoredBox(
          color: theme.colorScheme.surfaceContainerLow.toValue(),
          child: Center(child: const Text('캔버스').bodyMedium),
        ),
      ),
    );
  }
}
''';

const String _defaultCode = '''
class DraggablePanelDefaultExample extends StatefulWidget {
  const DraggablePanelDefaultExample({super.key});

  @override
  State<DraggablePanelDefaultExample> createState() =>
      _DraggablePanelDefaultExampleState();
}

class _DraggablePanelDefaultExampleState
    extends State<DraggablePanelDefaultExample> {
  final CoreDraggablePanelController _controller =
      CoreDraggablePanelController(initiallyOpen: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 360,
      height: 360,
      child: DraggablePanel(
        controller: _controller,
        panel: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Theme.of(context).geometry.space(CoreSpace.space8),
          children: [
            const Text('펜').bodyMedium,
            const Text('지우개').bodyMedium,
            const Text('색상').bodyMedium,
          ],
        ),
        child: ColoredBox(
          color: theme.colorScheme.surfaceContainerLow.toValue(),
          child: Center(child: const Text('캔버스').bodyMedium),
        ),
      ),
    );
  }
}
''';
