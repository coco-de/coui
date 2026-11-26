import 'package:coui_flutter/coui_flutter.dart';

/// Lifts the `child` off the page while the menu is open (`liftChild`): a held
/// touch raises it before the menu appears, any other opening raises it as the
/// menu appears, and every way of closing folds the menu back into it.
class ContextMenuLiftExample extends StatelessWidget {
  const ContextMenuLiftExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ContextMenu(
      liftChild: true,
      haptics: true,
      items: [
        CoreMenuItem.action('열기', onPressed: () {}),
        CoreMenuItem.action('공유', onPressed: () {}),
        const CoreMenuItem.divider(),
        CoreMenuItem.action('삭제', onPressed: () {}),
      ],
      child: Container(
        decoration: BoxDecoration(
          color: context.theme.colorScheme.surface.toValue(),
          border: Border.all(
            color: context.theme.colorScheme.outline.toValue(),
            width: CoreStrokeWidth.stroke1,
          ),
          borderRadius: BorderRadius.circular(CoreRadius.radius16),
        ),
        child: Padding(
          padding: const CoreEdgeInsets.symmetric(
            horizontal: CoreSpace.space24,
            vertical: CoreSpace.space16,
          ).toValue(geometry: Theme.of(context).geometry),
          child: Text('길게 눌러 보세요').bodyMedium,
        ),
      ),
    );
  }
}
