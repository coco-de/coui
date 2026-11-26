String scrollAreaCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class ScrollAreaChainExample extends StatelessWidget {
  const ScrollAreaChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child:
          ScrollArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Theme.of(context).geometry.space(CoreSpace.space8),
              children: [
                for (var i = 1; i <= 20; i += 1) Text('스크롤 항목 \$i').bodyMedium,
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
    );
  }
}''',
    _ =>
      '''
class ScrollAreaDefaultExample extends StatelessWidget {
  const ScrollAreaDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: ScrollArea(
        scrollAreaStyle: const CoreScrollAreaStyle(maxHeight: 180),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Theme.of(context).geometry.space(CoreSpace.space8),
          children: [
            for (var i = 1; i <= 20; i += 1) Text('스크롤 항목 \$i').bodyMedium,
          ],
        ),
      ),
    );
  }
}''',
  };
}
