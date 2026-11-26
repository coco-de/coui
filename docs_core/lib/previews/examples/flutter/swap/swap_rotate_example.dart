import 'package:coui_flutter/coui_flutter.dart';

class SwapRotateExample extends StatefulWidget {
  const SwapRotateExample({super.key});

  @override
  State<SwapRotateExample> createState() => _SwapRotateExampleState();
}

class _SwapRotateExampleState extends State<SwapRotateExample> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    return Swap(
      checked: _checked,
      animation: CoreSwapAnimation.rotate,
      onContent: const Text('켜짐'),
      offContent: const Text('꺼짐'),
      onToggle: (v) => setState(() => _checked = v),
    );
  }
}
