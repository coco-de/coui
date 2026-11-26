import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreScrollbarStyle] slot without constructing the widget
/// from scratch. The patch repaints the thumb and adds a visible track.
class ScrollbarChainExample extends StatelessComponent {
  const ScrollbarChainExample({super.key});

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
        ).withStyle(
          const CoreScrollbarStyle(
            thumbColor: CoreColor.token(CoreColors.primary),
            thumbRadius: CoreBorderRadius.all(CoreRadius.radius9999),
            thickness: CoreStrokeWidth.stroke8,
            trackColor: CoreColor.token(CoreColors.surfaceContainerHigh),
          ),
        ),
      ],
    );
  }
}
