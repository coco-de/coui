import 'package:coui_web/coui_web.dart';

class ScrollViewInterceptorDefaultExample extends StatelessComponent {
  const ScrollViewInterceptorDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      styles: Styles(raw: {'width': '260px'}),
      [
        ScrollViewInterceptor(
          child: ScrollArea(
            scrollAreaStyle: const CoreScrollAreaStyle(maxHeight: 160),
            child: div(
              classes: 'flex flex-col gap-${CoreSpace.scale.space8}',
              [
                for (var i = 1; i <= 20; i += 1) Text('항목 $i').bodyMedium,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
