import 'package:coui_web/coui_web.dart';

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
    ], classes: 'flex items-center gap-${CoreSpace.scale.space8}');
  }
}
