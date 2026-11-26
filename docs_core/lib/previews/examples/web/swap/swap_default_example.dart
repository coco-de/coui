import 'package:coui_web/coui_web.dart';

class SwapDefaultExample extends StatefulComponent {
  const SwapDefaultExample({super.key});

  @override
  State<SwapDefaultExample> createState() => _SwapDefaultExampleState();
}

class _SwapDefaultExampleState extends State<SwapDefaultExample> {
  bool _checked = false;

  @override
  Component build(BuildContext context) {
    return Swap(
      checked: _checked,
      onContent: Text('켜짐'),
      offContent: Text('꺼짐'),
      onToggle: (v) => setState(() => _checked = v),
    );
  }
}
