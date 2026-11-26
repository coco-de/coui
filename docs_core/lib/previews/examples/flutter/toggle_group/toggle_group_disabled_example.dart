import 'package:coui_flutter/coui_flutter.dart';

class ToggleGroupDisabledExample extends StatefulWidget {
  const ToggleGroupDisabledExample({super.key});

  @override
  State<ToggleGroupDisabledExample> createState() => _ToggleGroupDisabledExampleState();
}

class _ToggleGroupDisabledExampleState extends State<ToggleGroupDisabledExample> {
  String? _selected = 'slider';

  void handleChanged(String value) {
    setState(() => _selected = value);
  }

  @override
  Widget build(BuildContext context) {
    // 비활성 — `onChanged` 를 주지 않거나 `enabled: false` 로 끈다.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ToggleGroup<String>(
          value: _selected,
          onChanged: handleChanged,
          items: const [
            CoreToggleGroupItem(value: 'wheel', label: '휠'),
            CoreToggleGroupItem(value: 'slider', label: '슬라이더'),
            CoreToggleGroupItem(value: 'input', label: '직접 입력'),
          ],
        ),
        const Gap.space12(),
        ToggleGroup<String>(
          value: _selected,
          enabled: false,
          onChanged: handleChanged,
          items: const [
            CoreToggleGroupItem(value: 'wheel', label: '휠'),
            CoreToggleGroupItem(value: 'slider', label: '슬라이더'),
            CoreToggleGroupItem(value: 'input', label: '직접 입력'),
          ],
        ),
      ],
    );
  }
}
