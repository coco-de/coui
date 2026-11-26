import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreScrollAreaStyle] slot without constructing the widget
/// from scratch. The patch drives the viewport height plus the nested
/// scrollbar chrome in one instance.
class ScrollAreaChainExample extends StatelessComponent {
  const ScrollAreaChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      styles: Styles(raw: {'width': '260px'}),
      [
        ScrollArea(
          child: div(
            classes: 'flex flex-col gap-${CoreSpace.scale.space8}',
            [
              for (var i = 1; i <= 20; i += 1) Text('스크롤 항목 $i').bodyMedium,
            ],
          ),
        ).withStyle(
          const CoreScrollAreaStyle(
            height: CoreSpace.space192,
            maxHeight: CoreSpace.space192,
            scrollbarStyle: CoreScrollbarStyle(
              thumbColor: CoreColor.token(CoreColors.primary),
              thumbRadius: CoreBorderRadius.all(CoreRadius.radius9999),
              thickness: CoreStrokeWidth.stroke8,
            ),
          ),
        ),
      ],
    );
  }
}
