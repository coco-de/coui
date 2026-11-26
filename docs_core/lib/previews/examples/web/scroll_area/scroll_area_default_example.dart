import 'package:coui_web/coui_web.dart';

class ScrollAreaDefaultExample extends StatelessComponent {
  const ScrollAreaDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      styles: Styles(raw: {'width': '260px'}),
      [
        ScrollArea(
          scrollAreaStyle: const CoreScrollAreaStyle(maxHeight: 180),
          child: div(
            classes: 'flex flex-col gap-${CoreSpace.scale.space8}',
            [
              for (var i = 1; i <= 20; i += 1) Text('스크롤 항목 $i').bodyMedium,
            ],
          ),
        ),
      ],
    );
  }
}
