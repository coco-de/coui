import 'package:coui_flutter/coui_flutter.dart';

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
}
