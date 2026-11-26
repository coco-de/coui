import 'package:coui_web/coui_web.dart';

class FilterDisabledExample extends StatefulComponent {
  const FilterDisabledExample({super.key});

  @override
  State<FilterDisabledExample> createState() => _FilterDisabledExampleState();
}

class _FilterDisabledExampleState extends State<FilterDisabledExample> {
  String? _selected = 'vue';

  void handleValueChanged(String value) {
    setState(() => _selected = value);
  }

  void handleReset() {
    setState(() => _selected = null);
  }

  @override
  Component build(BuildContext context) {
    // 비활성 — `enabled: false` 로 끈다. 트랙은 disabled-container, 선택 칸은
    // 그림자 없이 가라앉고 글자는 disabled-content 이다.
    return div([
      Filter<String>(
        groupValue: _selected,
        onValueChanged: handleValueChanged,
        onReset: handleReset,
        showResetButton: true,
        items: const [
          CoreFilterItem(value: 'svelte', label: 'Svelte'),
          CoreFilterItem(value: 'vue', label: 'Vue'),
          CoreFilterItem(value: 'react', label: 'React'),
        ],
      ),
      const Gap.space12(),
      Filter<String>(
        groupValue: _selected,
        onValueChanged: handleValueChanged,
        onReset: handleReset,
        showResetButton: true,
        enabled: false,
        items: const [
          CoreFilterItem(value: 'svelte', label: 'Svelte'),
          CoreFilterItem(value: 'vue', label: 'Vue'),
          CoreFilterItem(value: 'react', label: 'React'),
        ],
      ),
    ], classes: 'flex flex-col items-start');
  }
}
