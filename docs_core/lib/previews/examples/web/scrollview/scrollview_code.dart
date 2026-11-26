String scrollviewCode(String? variant) {
  return switch (variant) {
    'chain' =>
      r'''
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
}''',
    _ =>
      r'''
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
}''',
  };
}
