import 'package:coui_flutter/coui_flutter.dart';

class ToggleGroupDefaultExample extends StatefulWidget {
  const ToggleGroupDefaultExample({super.key});

  @override
  State<ToggleGroupDefaultExample> createState() => _ToggleGroupDefaultExampleState();
}

class _ToggleGroupDefaultExampleState extends State<ToggleGroupDefaultExample> {
  String? _selected = 'am';

  void handleChanged(String value) {
    setState(() => _selected = value);
  }

  @override
  Widget build(BuildContext context) {
    return ToggleGroup<String>(
      value: _selected,
      onChanged: handleChanged,
      items: const [
        CoreToggleGroupItem(value: 'am', label: '오전'),
        CoreToggleGroupItem(value: 'pm', label: '오후'),
      ],
    );
  }
}
