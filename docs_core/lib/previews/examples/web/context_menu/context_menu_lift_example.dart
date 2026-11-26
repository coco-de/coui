import 'package:coui_web/coui_web.dart';

/// Lifts the `child` off the page while the menu is open (`liftChild`): a held
/// touch raises it before the menu appears, any other opening raises it as the
/// menu appears, and every way of closing folds the menu back into it.
class ContextMenuLiftExample extends StatelessComponent {
  const ContextMenuLiftExample({super.key});

  @override
  Component build(BuildContext context) {
    return ContextMenu(
      liftChild: true,
      haptics: true,
      items: [
        CoreMenuItem.action('열기', onPressed: () {}),
        CoreMenuItem.action('공유', onPressed: () {}),
        const CoreMenuItem.divider(),
        CoreMenuItem.action('삭제', onPressed: () {}),
      ],
      child: div(
        [Text('길게 눌러 보세요').bodyMedium],
        classes:
            'border border-outline bg-surface '
            'rounded-${CoreRadius.scale.radius16} '
            'px-${CoreSpace.scale.space24} py-${CoreSpace.scale.space16}',
      ),
    );
  }
}
