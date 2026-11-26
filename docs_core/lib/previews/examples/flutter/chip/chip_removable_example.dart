import 'package:coui_flutter/coui_flutter.dart';

class ChipRemovableExample extends StatefulWidget {
  const ChipRemovableExample({super.key});

  @override
  State<ChipRemovableExample> createState() => _ChipRemovableExampleState();
}

class _ChipRemovableExampleState extends State<ChipRemovableExample> {
  bool _visible = true;

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return Chip(
      label: '삭제 가능',
      onRemove: () => setState(() => _visible = false),
      onTap: () {},
    );
  }
}
