String scrollviewCode(String? variant) {
  return switch (variant) {
    'chain' =>
      r'''
class ScrollViewInterceptorChainExample extends StatelessWidget {
  const ScrollViewInterceptorChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child:
          ScrollViewInterceptor(
            child: ScrollArea(
              scrollAreaStyle: const CoreScrollAreaStyle(maxHeight: 160),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: Theme.of(context).geometry.space(CoreSpace.space8),
                children: [
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
    );
  }
}''',
    _ =>
      r'''
class ScrollViewInterceptorDefaultExample extends StatelessWidget {
  const ScrollViewInterceptorDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: ScrollViewInterceptor(
        child: ScrollArea(
          scrollAreaStyle: const CoreScrollAreaStyle(maxHeight: 160),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Theme.of(context).geometry.space(CoreSpace.space8),
            children: [
              for (var i = 1; i <= 20; i += 1) Text('항목 $i').bodyMedium,
            ],
          ),
        ),
      ),
    );
  }
}''',
  };
}
