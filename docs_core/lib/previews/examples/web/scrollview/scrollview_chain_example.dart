import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreScrollViewInterceptorStyle] slot without
/// constructing the component from scratch. The scrollable content
/// matches the default example; only the auto-scroll tuning
/// (`dragSpeed` / `maxScrollSpeed`) is patched through the single style
/// slot.
class ScrollViewInterceptorChainExample extends StatelessComponent {
  const ScrollViewInterceptorChainExample({super.key});

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
        ).withStyle(
          const CoreScrollViewInterceptorStyle(
            dragSpeed: 0.05,
            maxScrollSpeed: 24,
          ),
        ),
      ],
    );
  }
}
