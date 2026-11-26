import 'package:coui_web/coui_web.dart';

class HoverFadeExample extends StatelessComponent {
  const HoverFadeExample({super.key});

  @override
  Component build(BuildContext context) {
    return Hover(
      effect: CoreHoverEffect.fade,
      child: Card(child: const Text('올려 보세요')),
    );
  }
}
