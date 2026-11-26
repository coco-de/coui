import 'package:coui_web/coui_web.dart';

class ContextMenuDefaultExample extends StatelessComponent {
  const ContextMenuDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return ContextMenu(
      items: [
        CoreMenuItem.action('복사', onPressed: () {}),
        CoreMenuItem.action('붙여넣기', onPressed: () {}),
        const CoreMenuItem.divider(),
        CoreMenuItem.action('삭제', onPressed: () {}),
      ],
      child: div(
        [Text('여기를 오른쪽 클릭해 보세요').bodyMedium],
        // `border-outline` matches the Flutter example's explicit
        // `outline` border colour — bare `border` would fall back to the
        // current text colour, rendering a darker box on Web only.
        classes:
            'border border-outline rounded-${CoreRadius.scale.radius8} '
            'px-${CoreSpace.scale.space24} py-${CoreSpace.scale.space16}',
      ),
    );
  }
}
