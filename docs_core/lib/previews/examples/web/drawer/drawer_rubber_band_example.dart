import 'package:coui_web/coui_web.dart';

/// Rubber-band Drawer example for docs_site Web preview.
///
/// A bottom sheet that gives under the pointer: pulled further open than it is,
/// its far edge follows with less and less return while the edge on the screen
/// stays where it is, and letting go brings it back. Pulling it down
/// closes it by the usual distance and fling rules — the stretch never counts as
/// a distance.
/// The Done / Cancel bar is ordinary content, a row of [Button]s in the sheet,
/// not a component of its own. On Web `rubberBand` is read off the [Drawer].
class DrawerRubberBandExample extends StatelessComponent {
  const DrawerRubberBandExample({super.key});

  @override
  Component build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () {
        openDrawer<void>(
          context: context,
          side: CoreDrawerSide.bottom,
          builder: (close) => Drawer(
            rubberBand: true,
            showDragHandle: true,
            showCloseButton: false,
            drawerStyle: const CoreDrawerStyle(
              panelBorderRadius: CoreBorderRadius.all(CoreRadius.radius28),
            ),
            content: div(
              [
                div(
                  [
                    Button(
                      variant: CoreButtonVariant.ghost,
                      onPressed: () => close(),
                      child: const Text('취소'),
                    ),
                    div(
                      [Text('알림 시간').titleMedium],
                      classes: 'flex flex-1 justify-center',
                    ),
                    Button(
                      onPressed: () => close(),
                      child: const Text('완료'),
                    ),
                  ],
                  classes: 'flex items-center gap-${CoreSpace.scale.space8}',
                ),
                Text('오전 8:00').bodyMedium,
                Text('오후 12:30').bodyMedium,
                Text('오후 6:00').bodyMedium,
              ],
              classes: 'flex flex-col gap-${CoreSpace.scale.space16}',
            ),
          ),
        );
      },
      child: const Text('고무줄 시트'),
    );
  }
}
