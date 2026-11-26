/// Returns a Flutter code snippet string for the Filter component.
String filterCode(String? variant) {
  return switch (variant) {
    'disabled' =>
      '''
class FilterDisabledExample extends StatefulWidget {
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
  Widget build(BuildContext context) {
    // 비활성 — `enabled: false` 로 끈다. 트랙은 disabled-container, 선택 칸은
    // 그림자 없이 가라앉고 글자는 disabled-content 이다.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }
}
''',
    'chain' =>
      '''
class FilterChainExample extends StatefulWidget {
  const FilterChainExample({super.key});

  @override
  State<FilterChainExample> createState() => _FilterChainExampleState();
}

class _FilterChainExampleState extends State<FilterChainExample> {
  String? _selected = 'svelte';

  void handleValueChanged(String value) {
    setState(() => _selected = value);
  }

  void handleReset() {
    setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
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
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
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
        ).withStyle(
          const CoreFilterStyle(
            toggleGroupStyle: CoreToggleGroupStyle(
              backgroundColor: CoreColor.token(CoreColors.tertiary),
              borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
              itemBorderRadius: CoreBorderRadius.all(CoreRadius.radius8),
              padding: CoreEdgeInsets.symmetric(
                horizontal: CoreSpace.space24,
                vertical: CoreSpace.space8,
              ),
            ),
          ),
        ),
      ],
    );
  }
}''',
    _ =>
      '''
class FilterDefaultExample extends StatefulWidget {
  const FilterDefaultExample({super.key});

  @override
  State<FilterDefaultExample> createState() => _FilterDefaultExampleState();
}

class _FilterDefaultExampleState extends State<FilterDefaultExample> {
  String? _selected = 'svelte';

  void handleValueChanged(String value) {
    setState(() => _selected = value);
  }

  void handleReset() {
    setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    return Filter<String>(
      groupValue: _selected,
      onValueChanged: handleValueChanged,
      onReset: handleReset,
      showResetButton: true,
      items: const [
        CoreFilterItem(value: 'svelte', label: 'Svelte'),
        CoreFilterItem(value: 'vue', label: 'Vue'),
        CoreFilterItem(value: 'react', label: 'React'),
      ],
    );
  }
}''',
  };
}
