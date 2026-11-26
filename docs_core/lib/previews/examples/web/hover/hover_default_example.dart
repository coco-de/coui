import 'package:coui_web/coui_web.dart';

class HoverDefaultExample extends StatelessComponent {
  const HoverDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return Hover(
      effect: CoreHoverEffect.scaleUp,
      child: Card(child: const Text('올려 보세요')),
    );
  }
}
