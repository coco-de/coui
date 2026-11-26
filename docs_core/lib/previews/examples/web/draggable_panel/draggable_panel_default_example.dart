import 'package:coui_web/coui_web.dart';

/// Default preview for `DraggablePanel` on Web. Mirrors the Flutter
/// counterpart: same tool labels, same canvas placeholder, panel open.
class DraggablePanelDefaultExample extends StatefulComponent {
  const DraggablePanelDefaultExample({super.key});

  @override
  State<DraggablePanelDefaultExample> createState() => _DraggablePanelDefaultExampleState();
}

class _DraggablePanelDefaultExampleState extends State<DraggablePanelDefaultExample> {
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
        ),
      ],
      styles: Styles(
        raw: const {'width': '${360 / 16}rem', 'height': '${360 / 16}rem'},
      ),
    );
  }
}
