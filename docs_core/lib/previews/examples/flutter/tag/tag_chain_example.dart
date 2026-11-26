import 'package:coui_flutter/coui_flutter.dart';

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
}
