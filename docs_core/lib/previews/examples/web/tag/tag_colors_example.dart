import 'package:coui_web/coui_web.dart';

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
    ], classes: 'flex flex-wrap items-center gap-${CoreSpace.scale.space8}');
  }
}
