/// Returns a Web code snippet string for the ToggleGroup component.
String toggleGroupCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class ToggleGroupChainExample extends StatefulComponent {
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
  Component build(BuildContext context) {
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
''',
    'vertical' =>
      '''
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
''',
    'disabled' =>
      '''
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
''',
    _ =>
      '''
class ToggleGroupDefaultExample extends StatefulComponent {
  const ToggleGroupDefaultExample({super.key});

  @override
  State<ToggleGroupDefaultExample> createState() => _ToggleGroupDefaultExampleState();
}

class _ToggleGroupDefaultExampleState extends State<ToggleGroupDefaultExample> {
  String? _selected = 'am';

  void handleChanged(String value) {
    setState(() => _selected = value);
  }

  @override
  Component build(BuildContext context) {
    return ToggleGroup<String>(
      value: _selected,
      onChanged: handleChanged,
      items: const [
        CoreToggleGroupItem(value: 'am', label: '오전'),
        CoreToggleGroupItem(value: 'pm', label: '오후'),
      ],
    );
  }
}
''',
  };
}
