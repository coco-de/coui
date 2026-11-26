import 'package:coui_web/coui_web.dart';

class SwapRotateExample extends StatefulComponent {
  const SwapRotateExample({super.key});

  @override
  State<SwapRotateExample> createState() => _SwapRotateExampleState();
}

class _SwapRotateExampleState extends State<SwapRotateExample> {
  bool _checked = false;

  @override
  Component build(BuildContext context) {
    return Swap(
      checked: _checked,
      animation: CoreSwapAnimation.rotate,
      onContent: Text('켜짐'),
      offContent: Text('꺼짐'),
      onToggle: (v) => setState(() => _checked = v),
    );
  }
}
