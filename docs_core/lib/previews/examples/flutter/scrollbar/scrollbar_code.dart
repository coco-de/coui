String scrollbarCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class ScrollbarChainExample extends StatefulWidget {
  const ScrollbarChainExample({super.key});

  @override
  State<ScrollbarChainExample> createState() => _ScrollbarChainExampleState();
}

class _ScrollbarChainExampleState extends State<ScrollbarChainExample> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 160,
      child:
          Scrollbar(
            controller: _controller,
            child: SingleChildScrollView(
              controller: _controller,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: Theme.of(context).geometry.space(CoreSpace.space8),
                children: [
                  for (var i = 1; i <= 20; i += 1) Text('스크롤 항목 \$i').bodyMedium,
                ],
              ),
            ),
          ).withStyle(
            const CoreScrollbarStyle(
              thumbColor: CoreColor.token(CoreColors.primary),
              thumbRadius: CoreBorderRadius.all(CoreRadius.radius9999),
              thickness: CoreStrokeWidth.stroke8,
              trackColor: CoreColor.token(CoreColors.surfaceContainerHigh),
            ),
          ),
    );
  }
}''',
    _ =>
      '''
class ScrollbarDefaultExample extends StatefulWidget {
  const ScrollbarDefaultExample({super.key});

  @override
  State<ScrollbarDefaultExample> createState() =>
      _ScrollbarDefaultExampleState();
}

class _ScrollbarDefaultExampleState extends State<ScrollbarDefaultExample> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 160,
      child: Scrollbar(
        controller: _controller,
        child: SingleChildScrollView(
          controller: _controller,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Theme.of(context).geometry.space(CoreSpace.space8),
            children: [
              for (var i = 1; i <= 20; i += 1) Text('스크롤 항목 \$i').bodyMedium,
            ],
          ),
        ),
      ),
    );
  }
}''',
  };
}
