import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreDraggablePanelStyle] slot without constructing the
/// component from scratch.
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
            classes: 'flex flex-col gap-${CoreSpace.scale.space8}',
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
        raw: const {'width': '${360 / 16}rem', 'height': '${360 / 16}rem'},
      ),
    );
  }
}
