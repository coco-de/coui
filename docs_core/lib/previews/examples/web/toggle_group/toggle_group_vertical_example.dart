import 'package:coui_web/coui_web.dart';

class ToggleGroupVerticalExample extends StatefulComponent {
  const ToggleGroupVerticalExample({super.key});

  @override
  State<ToggleGroupVerticalExample> createState() => _ToggleGroupVerticalExampleState();
}

class _ToggleGroupVerticalExampleState extends State<ToggleGroupVerticalExample> {
  String? _selected = 'am';

  void handleChanged(String value) {
    setState(() => _selected = value);
  }

  @override
  Component build(BuildContext context) {
    // 세로 sm — AM 위, PM 아래. 두 칸이 3 + 24 + 2 + 24 + 3 = 56 으로
    // 시간 선택기의 시 · 분 칸 높이와 같다.
    return ToggleGroup<String>(
      value: _selected,
      onChanged: handleChanged,
      size: CoreComponentSize.sm,
      direction: CoreAxis.vertical,
      items: const [
        CoreToggleGroupItem(value: 'am', label: '오전'),
        CoreToggleGroupItem(value: 'pm', label: '오후'),
      ],
    );
  }
}
