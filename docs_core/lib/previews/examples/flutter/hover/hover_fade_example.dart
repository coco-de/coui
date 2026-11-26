import 'package:coui_flutter/coui_flutter.dart';

class HoverFadeExample extends StatelessWidget {
  const HoverFadeExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Hover(
      effect: CoreHoverEffect.fade,
      child: Card(child: const Text('올려 보세요')),
    );
  }
}
