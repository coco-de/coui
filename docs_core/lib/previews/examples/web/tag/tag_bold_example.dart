import 'package:coui_web/coui_web.dart';

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
    ], classes: 'flex flex-wrap items-center gap-${CoreSpace.scale.space8}');
  }
}
