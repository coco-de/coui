import 'package:coui_web/coui_web.dart';

/// `outside` dock preview on Web. Mirrors the Flutter counterpart: the
/// closed handle rests half past the right edge and a tap pulls it back in.
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
