import 'package:coui_web/coui_web.dart';

class ChipDefaultExample extends StatefulComponent {
  const ChipDefaultExample({super.key});

  @override
  State<ChipDefaultExample> createState() => _ChipDefaultExampleState();
}

class _ChipDefaultExampleState extends State<ChipDefaultExample> {
  bool _selected = false;

  @override
  Component build(BuildContext context) {
    return Chip(
      label: '디자인',
      selected: _selected,
      onTap: () => setState(() => _selected = !_selected),
    );
  }
}
