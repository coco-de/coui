import 'package:coui_flutter/coui_flutter.dart';

class SwapDefaultExample extends StatefulWidget {
  const SwapDefaultExample({super.key});

  @override
  State<SwapDefaultExample> createState() => _SwapDefaultExampleState();
}

class _SwapDefaultExampleState extends State<SwapDefaultExample> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    return Swap(
      checked: _checked,
      onContent: const Text('켜짐'),
      offContent: const Text('꺼짐'),
      onToggle: (v) => setState(() => _checked = v),
    );
  }
}
