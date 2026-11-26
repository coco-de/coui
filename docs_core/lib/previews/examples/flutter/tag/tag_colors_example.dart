import 'package:coui_flutter/coui_flutter.dart';

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
}
