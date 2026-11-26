import 'package:coui_web/coui_web.dart';

class HoverShadowExample extends StatelessComponent {
  const HoverShadowExample({super.key});

  @override
  Component build(BuildContext context) {
    return Hover(
      effect: CoreHoverEffect.shadow,
      child: Card(
        cardStyle: const CoreCardStyle(boxShadow: CoreShadow.none),
        child: const Text('올려 보세요'),
      ),
    );
  }
}
