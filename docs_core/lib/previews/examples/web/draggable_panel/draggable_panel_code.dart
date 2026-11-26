/// Source snippet for the Web `DraggablePanel` default preview.
///
/// Must mirror `draggable_panel_default_example.dart` verbatim (minus
/// imports) so the docs site's "View code" tab stays in sync.
String draggablePanelCode(String? variant) => switch (variant) {
  'chain' => _chainCode,
  'outside' => _outsideCode,
  _ => _defaultCode,
};

const String _chainCode = '''
class DraggablePanelChainExample extends StatefulComponent {
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
  Component build(BuildContext context) {
    return div(
      [
        DraggablePanel(
          controller: _controller,
          panel: div(
            [
              const Text('펜').bodyMedium,
              const Text('지우개').bodyMedium,
              const Text('색상').bodyMedium,
            ],
            classes: 'flex flex-col gap-\${CoreSpace.scale.space8}',
          ),
          child: div(
            [const Text('캔버스').bodyMedium],
            classes: 'flex items-center justify-center w-full h-full bg-surface-container-low',
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
      ],
      styles: Styles(
        raw: const {'width': '\${360 / 16}rem', 'height': '\${360 / 16}rem'},
      ),
    );
  }
}
''';

const String _outsideCode = '''
class DraggablePanelOutsideExample extends StatelessComponent {
  const DraggablePanelOutsideExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        DraggablePanel(
          dockType: CoreDraggablePanelDockType.outside,
          panel: div(
            [
              const Text('펜').bodyMedium,
              const Text('지우개').bodyMedium,
              const Text('색상').bodyMedium,
            ],
            classes: 'flex flex-col gap-\${CoreSpace.scale.space8}',
          ),
          child: div(
            [const Text('캔버스').bodyMedium],
            classes: 'flex items-center justify-center w-full h-full bg-surface-container-low',
          ),
        ),
      ],
      styles: Styles(
        raw: const {'width': '\${360 / 16}rem', 'height': '\${360 / 16}rem'},
      ),
    );
  }
}
''';

const String _defaultCode = '''
class DraggablePanelDefaultExample extends StatefulComponent {
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
  Component build(BuildContext context) {
    return div(
      [
        DraggablePanel(
          controller: _controller,
          panel: div(
            [
              const Text('펜').bodyMedium,
              const Text('지우개').bodyMedium,
              const Text('색상').bodyMedium,
            ],
            classes: 'flex flex-col gap-\${CoreSpace.scale.space8}',
          ),
          child: div(
            [const Text('캔버스').bodyMedium],
            classes:
                'flex items-center justify-center w-full h-full bg-surface-container-low',
          ),
        ),
      ],
      styles: Styles(
        raw: const {'width': '\${360 / 16}rem', 'height': '\${360 / 16}rem'},
      ),
    );
  }
}
''';
