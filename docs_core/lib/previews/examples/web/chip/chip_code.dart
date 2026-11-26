/// Returns a Web code snippet string for the Chip component.
String chipCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class ChipChainExample extends StatefulComponent {
  const ChipChainExample({super.key});

  @override
  State<ChipChainExample> createState() => _ChipChainExampleState();
}

class _ChipChainExampleState extends State<ChipChainExample> {
  bool _comboSelected = false;
  bool _fullSelected = false;

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        Chip(
          label: '디자인',
          selected: _comboSelected,
          onTap: () => setState(() => _comboSelected = !_comboSelected),
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        Chip(
          label: '직접 지정',
          selected: _fullSelected,
          onTap: () => setState(() => _fullSelected = !_fullSelected),
        ).withStyle(
          const CoreChipStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiaryContainer),
            foregroundColor: CoreColor.token(CoreColors.onTertiaryContainer),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space12,
              vertical: CoreSpace.space4,
            ),
          ),
        ),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}''',
    'selected' =>
      '''
class ChipSelectedExample extends StatefulComponent {
  const ChipSelectedExample({super.key});

  @override
  State<ChipSelectedExample> createState() => _ChipSelectedExampleState();
}

class _ChipSelectedExampleState extends State<ChipSelectedExample> {
  static const _labels = ['전체', '디자인', '개발'];

  final Set<String> _plain = {'전체'};
  final Set<String> _primary = {'디자인'};

  void _toggle(Set<String> picked, String label) {
    setState(() {
      if (!picked.remove(label)) picked.add(label);
    });
  }

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 인자 없이 쓴 칩 — 꺼지면 옅은 테두리, 켜지면 반전 채움.
        div(
          [
            for (final label in _labels)
              Chip(
                label: label,
                selected: _plain.contains(label),
                onTap: () => _toggle(_plain, label),
              ),
          ],
          classes: 'flex flex-row items-center gap-\${CoreSpace.scale.space8}',
        ),
        const Gap.space12(),
        // primary 로 같은 모양 — 꺼진 칩은 무채이고, 켜질 때만 색을 쓴다.
        div(
          [
            for (final label in _labels)
              Chip(
                label: label,
                chipColor: CoreChipColor.primary,
                selected: _primary.contains(label),
                onTap: () => _toggle(_primary, label),
              ),
          ],
          classes: 'flex flex-row items-center gap-\${CoreSpace.scale.space8}',
        ),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}''',
    'variant' =>
      '''
class ChipVariantExample extends StatefulComponent {
  const ChipVariantExample({super.key});

  @override
  State<ChipVariantExample> createState() => _ChipVariantExampleState();
}

class _ChipVariantExampleState extends State<ChipVariantExample> {
  static const _labels = ['전체', '디자인', '개발'];

  final Set<String> _outlined = {'전체'};
  final Set<String> _filled = {'전체'};
  final Set<String> _onGrey = {'전체'};

  void _toggle(Set<String> picked, String label) {
    setState(() {
      if (!picked.remove(label)) picked.add(label);
    });
  }

  Component _row(CoreChipVariant variant, Set<String> picked) {
    return div(
      [
        for (final label in _labels)
          Chip(
            label: label,
            variant: variant,
            selected: picked.contains(label),
            onTap: () => _toggle(picked, label),
          ),
      ],
      classes: 'flex flex-row items-center gap-\${CoreSpace.scale.space8}',
    );
  }

  @override
  Component build(BuildContext context) {
    return div(
      [
        // outlined(기본) — 투명 채움에 옅은 테두리. 어느 바탕 위에서도 쓴다.
        Text('outlined').labelSmall.onSurfaceVariant,
        const Gap.space4(),
        _row(CoreChipVariant.outlined, _outlined),
        const Gap.space12(),
        // filled — 회색 채움에 테두리 없음. 켜지면 진한 채움으로 바뀐다.
        Text('filled').labelSmall.onSurfaceVariant,
        const Gap.space4(),
        _row(CoreChipVariant.filled, _filled),
        const Gap.space12(),
        // 회색 바탕 위의 filled 는 바탕에 묻힌다 — 거기서는 outlined.
        Text('회색 바탕 위에서는 outlined').labelSmall.onSurfaceVariant,
        const Gap.space4(),
        Card(
          variant: CoreCardVariant.filled,
          body: _row(CoreChipVariant.outlined, _onGrey),
        ),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}''',
    'shape' =>
      '''
class ChipShapeExample extends StatefulComponent {
  const ChipShapeExample({super.key});

  @override
  State<ChipShapeExample> createState() => _ChipShapeExampleState();
}

class _ChipShapeExampleState extends State<ChipShapeExample> {
  static const _labels = ['전체', 'USD', 'JPY', 'EUR'];

  String _picked = '전체';

  @override
  Component build(BuildContext context) {
    // 알약 칩 — 양 끝이 반원. 필터 · 정렬 · 통화 줄에 쓰고, 하나만 켜진다.
    return div(
      [
        for (final label in _labels)
          Chip(
            label: label,
            shape: CoreChipShape.pill,
            selected: _picked == label,
            onTap: () => setState(() => _picked = label),
          ),
      ],
      classes: 'flex flex-row items-center gap-\${CoreSpace.scale.space8}',
    );
  }
}''',
    'disabled' =>
      '''
class ChipDisabledExample extends StatefulComponent {
  const ChipDisabledExample({super.key});

  @override
  State<ChipDisabledExample> createState() => _ChipDisabledExampleState();
}

class _ChipDisabledExampleState extends State<ChipDisabledExample> {
  @override
  Component build(BuildContext context) {
    return Chip(
      label: '디자인',
      enabled: false,
      onTap: () {
        setState(() {});
      },
    );
  }
}''',
    'cast-motion' =>
      '''
class ChipCastMotionExample extends StatefulComponent {
  const ChipCastMotionExample({super.key});

  @override
  State<ChipCastMotionExample> createState() => _ChipCastMotionExampleState();
}

class _ChipCastMotionExampleState extends State<ChipCastMotionExample> {
  @override
  Component build(BuildContext context) {
    return div(
      [
        Chip(
          label: '기본',
          chipStyle: const CoreChipStyle(
            castMotion: CoreCastMotion.defaultMotion,
          ),
          onTap: () {},
        ),
        const Gap.space12(),
        Chip(
          label: '그림자 없음',
          chipStyle: const CoreChipStyle(castMotion: CoreCastMotion.noShadow),
          onTap: () {},
        ),
        const Gap.space12(),
        Chip(
          label: '반대로',
          chipStyle: const CoreChipStyle(castMotion: CoreCastMotion.reverse),
          onTap: () {},
        ),
      ],
      classes: 'flex flex-row items-center',
    );
  }
}''',
    'removable' =>
      '''
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
}''',
    'prefix' =>
      '''
class ChipPrefixExample extends StatefulComponent {
  const ChipPrefixExample({super.key});

  @override
  State<ChipPrefixExample> createState() => _ChipPrefixExampleState();
}

class _ChipPrefixExampleState extends State<ChipPrefixExample> {
  static const _filters = [
    (key: '상태', value: '진행 중'),
    (key: '담당자', value: '나'),
  ];

  final Set<String> _applied = {'상태'};

  void _toggle(String key) {
    setState(() {
      if (!_applied.remove(key)) _applied.add(key);
    });
  }

  @override
  Component build(BuildContext context) {
    // 필터 칩 — 키 글자(무엇을 거르는가) + 지금 값. 걸린 필터만 켜진다.
    return div(
      [
        for (final filter in _filters)
          Chip(
            variant: CoreChipVariant.filled,
            prefixLabel: filter.key,
            label: _applied.contains(filter.key) ? filter.value : '전체',
            trailing: const Icon(LucideIcons.chevronDown),
            selected: _applied.contains(filter.key),
            onTap: () => _toggle(filter.key),
          ),
      ],
      classes: 'flex flex-row items-center gap-\${CoreSpace.scale.space8}',
    );
  }
}''',
    _ =>
      '''
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
}''',
  };
}
