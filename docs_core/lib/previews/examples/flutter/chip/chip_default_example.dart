import 'package:coui_flutter/coui_flutter.dart';

class ChipDefaultExample extends StatefulWidget {
  const ChipDefaultExample({super.key});

  @override
  State<ChipDefaultExample> createState() => _ChipDefaultExampleState();
}

class _ChipDefaultExampleState extends State<ChipDefaultExample> {
  bool _selected = false;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: '디자인',
      selected: _selected,
      onTap: () => setState(() => _selected = !_selected),
    );
  }
}
