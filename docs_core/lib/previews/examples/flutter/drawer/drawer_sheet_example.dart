import 'package:coui_flutter/coui_flutter.dart';

/// Bottom-sheet Drawer example for docs_site Flutter preview.
///
/// A picker that slides up from the bottom: a grab handle, a title with a
/// description under it, no close button and no rule under the header, and
/// the sheet's own corner radius. The side goes to [openDrawer] alone — the
/// panel docks to the edge the route opens it from.
class DrawerSheetExample extends StatelessWidget {
  const DrawerSheetExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () {
        openDrawer<void>(
          context: context,
          side: CoreDrawerSide.bottom,
          builder: (ctx) => Drawer(
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
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: CoreSpace.space8,
              children: [
                Text('KRW · 대한민국 원').bodyMedium,
                Text('USD · 미국 달러').bodyMedium,
                Text('JPY · 일본 엔').bodyMedium,
              ],
            ),
          ),
        );
      },
      child: const Text('통화 선택'),
    );
  }
}
