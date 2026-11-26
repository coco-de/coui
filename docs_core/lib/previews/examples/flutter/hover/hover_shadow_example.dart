import 'package:coui_flutter/coui_flutter.dart';

class HoverShadowExample extends StatelessWidget {
  const HoverShadowExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Hover(
      effect: CoreHoverEffect.shadow,
      child: Card(
        cardStyle: const CoreCardStyle(boxShadow: CoreShadow.none),
        child: const Text('올려 보세요'),
      ),
    );
  }
}
