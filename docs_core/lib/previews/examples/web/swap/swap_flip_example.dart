import 'package:coui_web/coui_web.dart';

class SwapFlipExample extends StatefulComponent {
  const SwapFlipExample({super.key});

  @override
  State<SwapFlipExample> createState() => _SwapFlipExampleState();
}

class _SwapFlipExampleState extends State<SwapFlipExample> {
  bool _checked = false;

  @override
  Component build(BuildContext context) {
    return Swap(
      checked: _checked,
      animation: CoreSwapAnimation.flip,
      onContent: Text('켜짐'),
      offContent: Text('꺼짐'),
      onToggle: (v) => setState(() => _checked = v),
    );
  }
}
