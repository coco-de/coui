import 'package:coui_web/coui_web.dart';

class ChipRemovableExample extends StatefulComponent {
  const ChipRemovableExample({super.key});

  @override
  State<ChipRemovableExample> createState() => _ChipRemovableExampleState();
}

class _ChipRemovableExampleState extends State<ChipRemovableExample> {
  bool _visible = true;

  @override
  Component build(BuildContext context) {
    if (!_visible) return Text('');
    return Chip(
      label: '삭제 가능',
      onRemove: () => setState(() => _visible = false),
      onTap: () {},
    );
  }
}
