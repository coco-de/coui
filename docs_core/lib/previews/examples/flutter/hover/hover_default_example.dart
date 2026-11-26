import 'package:coui_flutter/coui_flutter.dart';

class HoverDefaultExample extends StatelessWidget {
  const HoverDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Hover(
      effect: CoreHoverEffect.scaleUp,
      child: Card(child: const Text('올려 보세요')),
    );
  }
}
