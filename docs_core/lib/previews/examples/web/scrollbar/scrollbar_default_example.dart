import 'package:coui_web/coui_web.dart';

class ScrollbarDefaultExample extends StatelessComponent {
  const ScrollbarDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      styles: Styles(raw: {'width': '240px', 'height': '160px'}),
      [
        Scrollbar(
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
