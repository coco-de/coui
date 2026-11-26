import 'package:coui_flutter/coui_flutter.dart';

class ToggleGroupChainExample extends StatefulWidget {
  const ToggleGroupChainExample({super.key});

  @override
  State<ToggleGroupChainExample> createState() => _ToggleGroupChainExampleState();
}

class _ToggleGroupChainExampleState extends State<ToggleGroupChainExample> {
  String? _selected = 'am';

  void handleChanged(String value) {
    setState(() => _selected = value);
  }

  @override
  Widget build(BuildContext context) {
    // withStyle full-control — 트랙 모서리와 선택 면 그림자를 한 번에.
    return ToggleGroup<String>(
      value: _selected,
      onChanged: handleChanged,
      items: const [
        CoreToggleGroupItem(value: 'am', label: '오전'),
        CoreToggleGroupItem(value: 'pm', label: '오후'),
      ],
    ).withStyle(
      const CoreToggleGroupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
        itemBorderRadius: CoreBorderRadius.all(CoreRadius.radius12),
        selectedShadow: CoreShadow.none,
      ),
    );
  }
}
