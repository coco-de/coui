import 'package:coui_web/coui_web.dart';

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
}
