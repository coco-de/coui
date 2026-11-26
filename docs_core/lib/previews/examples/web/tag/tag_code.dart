/// Returns a Web code snippet string for the Tag component.
String tagCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class TagChainExample extends StatelessComponent {
  const TagChainExample({super.key});

  @override
  Component build(BuildContext context) {
    // withStyle full-control — a tweak laid over the hue's colours.
    return Tag(
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
class TagColorsExample extends StatelessComponent {
  const TagColorsExample({super.key});

  @override
  Component build(BuildContext context) {
    // One category hue per tag — the same subtle label in each.
    return div([
      Tag(color: CoreCategoryColor.red, child: Text('빨강')),
      Tag(color: CoreCategoryColor.orange, child: Text('주황')),
      Tag(color: CoreCategoryColor.yellow, child: Text('노랑')),
      Tag(color: CoreCategoryColor.green, child: Text('초록')),
      Tag(color: CoreCategoryColor.blue, child: Text('파랑')),
      Tag(color: CoreCategoryColor.purple, child: Text('보라')),
      Tag(color: CoreCategoryColor.pink, child: Text('분홍')),
      Tag(color: CoreCategoryColor.brown, child: Text('갈색')),
      Tag(child: Text('회색')),
    ], classes: 'flex flex-wrap items-center gap-\${CoreSpace.scale.space8}');
  }
}''',
    'bold' =>
      '''
class TagBoldExample extends StatelessComponent {
  const TagBoldExample({super.key});

  @override
  Component build(BuildContext context) {
    // The bold emphasis — the hue's solid fill, no line, the label at 600.
    return div([
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
    ], classes: 'flex flex-wrap items-center gap-\${CoreSpace.scale.space8}');
  }
}''',
    'sizes' =>
      '''
class TagSizesExample extends StatelessComponent {
  const TagSizesExample({super.key});

  @override
  Component build(BuildContext context) {
    // The two steps — md (24) and sm (20), at each emphasis.
    return div([
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
    ], classes: 'flex items-center gap-\${CoreSpace.scale.space8}');
  }
}''',
    _ =>
      '''
class TagDefaultExample extends StatelessComponent {
  const TagDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    // Every default — gray, subtle, md.
    return Tag(child: Text('디자인'));
  }
}''',
  };
}
