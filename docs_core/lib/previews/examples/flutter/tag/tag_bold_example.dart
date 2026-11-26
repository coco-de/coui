import 'package:coui_flutter/coui_flutter.dart';

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
}
