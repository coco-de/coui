import 'package:coui_flutter/coui_flutter.dart';

class SwapFlipExample extends StatefulWidget {
  const SwapFlipExample({super.key});

  @override
  State<SwapFlipExample> createState() => _SwapFlipExampleState();
}

class _SwapFlipExampleState extends State<SwapFlipExample> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    return Swap(
      checked: _checked,
      animation: CoreSwapAnimation.flip,
      onContent: const Text('켜짐'),
      offContent: const Text('꺼짐'),
      onToggle: (v) => setState(() => _checked = v),
    );
  }
}
