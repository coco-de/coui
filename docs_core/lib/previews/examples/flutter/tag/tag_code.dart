/// Returns a Flutter code snippet string for the Tag component.
String tagCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class TagChainExample extends StatelessWidget {
  const TagChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    // withStyle full-control — a tweak laid over the hue's colours.
    return const Tag(
      color: CoreCategoryColor.purple,
      child: Text('둥근 모양'),
    ).withStyle(
      const CoreTagStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
        padding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space12),
      ),
    );
  }
}''',
    'colors' =>
      '''
class TagColorsExample extends StatelessWidget {
  const TagColorsExample({super.key});

  @override
  Widget build(BuildContext context) {
    // One category hue per tag — the same subtle label in each.
    final space = Theme.of(context).geometry.space(CoreSpace.space8);
    return Wrap(
      spacing: space,
      runSpacing: space,
      children: const [
        Tag(color: CoreCategoryColor.red, child: Text('빨강')),
        Tag(color: CoreCategoryColor.orange, child: Text('주황')),
        Tag(color: CoreCategoryColor.yellow, child: Text('노랑')),
        Tag(color: CoreCategoryColor.green, child: Text('초록')),
        Tag(color: CoreCategoryColor.blue, child: Text('파랑')),
        Tag(color: CoreCategoryColor.purple, child: Text('보라')),
        Tag(color: CoreCategoryColor.pink, child: Text('분홍')),
        Tag(color: CoreCategoryColor.brown, child: Text('갈색')),
        Tag(child: Text('회색')),
      ],
    );
  }
}''',
    'bold' =>
      '''
class TagBoldExample extends StatelessWidget {
  const TagBoldExample({super.key});

  @override
  Widget build(BuildContext context) {
    // The bold emphasis — the hue's solid fill, no line, the label at 600.
    final space = Theme.of(context).geometry.space(CoreSpace.space8);
    return Wrap(
      spacing: space,
      runSpacing: space,
      children: const [
        Tag(
          color: CoreCategoryColor.red,
          emphasis: CoreTagEmphasis.bold,
          child: Text('빨강'),
        ),
        Tag(
          color: CoreCategoryColor.orange,
          emphasis: CoreTagEmphasis.bold,
          child: Text('주황'),
        ),
        Tag(
          color: CoreCategoryColor.yellow,
          emphasis: CoreTagEmphasis.bold,
          child: Text('노랑'),
        ),
        Tag(
          color: CoreCategoryColor.green,
          emphasis: CoreTagEmphasis.bold,
          child: Text('초록'),
        ),
        Tag(
          color: CoreCategoryColor.blue,
          emphasis: CoreTagEmphasis.bold,
          child: Text('파랑'),
        ),
        Tag(
          color: CoreCategoryColor.purple,
          emphasis: CoreTagEmphasis.bold,
          child: Text('보라'),
        ),
        Tag(
          color: CoreCategoryColor.pink,
          emphasis: CoreTagEmphasis.bold,
          child: Text('분홍'),
        ),
        Tag(
          color: CoreCategoryColor.brown,
          emphasis: CoreTagEmphasis.bold,
          child: Text('갈색'),
        ),
        Tag(emphasis: CoreTagEmphasis.bold, child: Text('회색')),
      ],
    );
  }
}''',
    'sizes' =>
      '''
class TagSizesExample extends StatelessWidget {
  const TagSizesExample({super.key});

  @override
  Widget build(BuildContext context) {
    // The two steps — md (24) and sm (20), at each emphasis.
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: Theme.of(context).geometry.space(CoreSpace.space8),
      children: const [
        Tag(color: CoreCategoryColor.blue, child: Text('중간')),
        Tag(
          color: CoreCategoryColor.blue,
          size: CoreTagSize.sm,
          child: Text('작음'),
        ),
        Tag(
          color: CoreCategoryColor.blue,
          emphasis: CoreTagEmphasis.bold,
          child: Text('중간'),
        ),
        Tag(
          color: CoreCategoryColor.blue,
          emphasis: CoreTagEmphasis.bold,
          size: CoreTagSize.sm,
          child: Text('작음'),
        ),
      ],
    );
  }
}''',
    _ =>
      '''
class TagDefaultExample extends StatelessWidget {
  const TagDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Every default — gray, subtle, md.
    return const Tag(child: Text('디자인'));
  }
}''',
  };
}
