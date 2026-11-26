import 'package:coui_flutter/coui_flutter.dart';

/// Rubber-band Drawer example for docs_site Flutter preview.
///
/// A bottom sheet that gives under the finger: pulled further open than it is,
/// its far edge follows with less and less return while the edge on the screen
/// stays where it is, and letting go brings it back. Pulling it down
/// closes it by the usual distance and fling rules — the stretch never counts as
/// a distance.
/// The Done / Cancel bar is ordinary content, a [Row] of [Button]s in the
/// sheet, not a component of its own. On Flutter `rubberBand` goes to
/// [openDrawer] alone: the route owns the drag.
class DrawerRubberBandExample extends StatelessWidget {
  const DrawerRubberBandExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () {
        openDrawer<void>(
          context: context,
          side: CoreDrawerSide.bottom,
          rubberBand: true,
          builder: (ctx) => Drawer(
            showDragHandle: true,
            showCloseButton: false,
            drawerStyle: const CoreDrawerStyle(
              panelBorderRadius: CoreBorderRadius.all(CoreRadius.radius28),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: CoreSpace.space16,
              children: [
                Row(
                  spacing: CoreSpace.space8,
                  children: [
                    Button(
                      variant: CoreButtonVariant.ghost,
                      onPressed: () => closeDrawer<void>(ctx),
                      child: const Text('취소'),
                    ),
                    Expanded(
                      child: Center(child: Text('알림 시간').titleMedium),
                    ),
                    Button(
                      onPressed: () => closeDrawer<void>(ctx),
                      child: const Text('완료'),
                    ),
                  ],
                ),
                Text('오전 8:00').bodyMedium,
                Text('오후 12:30').bodyMedium,
                Text('오후 6:00').bodyMedium,
              ],
            ),
          ),
        );
      },
      child: const Text('고무줄 시트'),
    );
  }
}
