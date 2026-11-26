import 'package:coui_web/coui_web.dart';

class ToggleGroupDisabledExample extends StatefulComponent {
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
  Component build(BuildContext context) {
    // 비활성 — `onChanged` 를 주지 않거나 `enabled: false` 로 끈다.
    return div([
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
    ], classes: 'flex flex-col items-start');
  }
}
