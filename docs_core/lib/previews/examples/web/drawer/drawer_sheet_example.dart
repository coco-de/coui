import 'package:coui_web/coui_web.dart';

/// Bottom-sheet Drawer example for docs_site Web preview.
///
/// A picker that slides up from the bottom: a grab handle, a title with a
/// description under it, no close button and no rule under the header, and
/// the sheet's own corner radius. The side goes to [openDrawer] alone — the
/// panel docks to the edge the entry opens it from.
class DrawerSheetExample extends StatelessComponent {
  const DrawerSheetExample({super.key});

  @override
  Component build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () {
        openDrawer<void>(
          context: context,
          side: CoreDrawerSide.bottom,
          builder: (close) => Drawer(
            title: '통화 선택',
            description: '받으실 통화를 선택해 주세요',
            showDragHandle: true,
            showCloseButton: false,
            drawerStyle: const CoreDrawerStyle(
              panelBorderRadius: CoreBorderRadius.all(CoreRadius.radius28),
              dividerStyle: CoreDividerStyle(
                thickness: CoreStrokeWidth.stroke0,
              ),
            ),
            content: div(
              [
                Text('KRW · 대한민국 원').bodyMedium,
                Text('USD · 미국 달러').bodyMedium,
                Text('JPY · 일본 엔').bodyMedium,
              ],
              classes: 'flex flex-col gap-${CoreSpace.scale.space8}',
            ),
          ),
        );
      },
      child: const Text('통화 선택'),
    );
  }
}
