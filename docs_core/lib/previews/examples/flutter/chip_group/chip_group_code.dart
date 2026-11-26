/// Code snippet for ChipGroup — variant-aware entry point.
String chipGroupCode(String? variant) => switch (variant) {
  'chain' => chipGroupChainCode(),
  'scroll' => chipGroupScrollCode(),
  _ => chipGroupDefaultCode(),
};

String chipGroupChainCode() {
  return '''
class ChipGroupChainExample extends StatefulWidget {
  const ChipGroupChainExample({super.key});

  @override
  State<ChipGroupChainExample> createState() => _ChipGroupChainExampleState();
}

class _ChipGroupChainExampleState extends State<ChipGroupChainExample> {
  Set<String> _selected = const {'Flutter'};

  @override
  Widget build(BuildContext context) {
    return ChipGroup<String>(
      items: const ['Flutter', 'React', 'Swift', 'Kotlin'],
      initialValue: _selected,
      selectionMode: CoreChipGroupSelectionMode.multi,
      onChanged: (next) => setState(() => _selected = next),
      chipBuilder: (item, {required selected, required enabled, required onTap}) => Chip(
        label: item,
        selected: selected,
        enabled: enabled,
        chipColor: CoreChipColor.primary,
        onTap: onTap,
      ),
    ).withStyle(
      const CoreChipGroupStyle(
        itemSpacing: CoreSpace.space12,
        rowSpacing: CoreSpace.space12,
        titleGapStyle: CoreGapStyle(size: CoreSpace.space8),
        titleTextStyle: CoreTextStyle.token(
          CoreTextStyles.labelLarge,
          color: CoreColor.token(CoreColors.onSurfaceVariant),
        ),
      ),
    );
  }
}''';
}

String chipGroupDefaultCode() {
  return '''
class ChipGroupDefaultExample extends StatefulWidget {
  const ChipGroupDefaultExample({super.key});

  @override
  State<ChipGroupDefaultExample> createState() =>
      _ChipGroupDefaultExampleState();
}

class _ChipGroupDefaultExampleState extends State<ChipGroupDefaultExample> {
  Set<String> _selected = const {'Flutter'};

  @override
  Widget build(BuildContext context) {
    return ChipGroup<String>(
      items: const ['Flutter', 'React', 'Swift', 'Kotlin'],
      initialValue: _selected,
      selectionMode: CoreChipGroupSelectionMode.multi,
      onChanged: (next) => setState(() => _selected = next),
      chipBuilder: (item, {required selected, required enabled, required onTap}) =>
          Chip(
        label: item,
        selected: selected,
        enabled: enabled,
        chipColor: CoreChipColor.primary,
        onTap: onTap,
      ),
    );
  }
}
''';
}

String chipGroupScrollCode() {
  return '''
class ChipGroupScrollExample extends StatefulWidget {
  const ChipGroupScrollExample({super.key});

  @override
  State<ChipGroupScrollExample> createState() =>
      _ChipGroupScrollExampleState();
}

class _ChipGroupScrollExampleState extends State<ChipGroupScrollExample> {
  Set<String> _selected = const {};

  @override
  Widget build(BuildContext context) {
    return ChipGroup<String>(
      items: const [
        '전체',
        '프런트엔드',
        '백엔드',
        '모바일',
        '디자인',
        'DevOps',
        '데이터',
        'AI/ML',
      ],
      layout: CoreChipGroupLayout.scroll,
      selectionMode: CoreChipGroupSelectionMode.single,
      initialValue: _selected,
      onChanged: (next) => setState(() => _selected = next),
      chipBuilder: (item, {required selected, required enabled, required onTap}) =>
          Chip(
        label: item,
        selected: selected,
        enabled: enabled,
        chipColor: CoreChipColor.neutral,
        onTap: onTap,
      ),
    );
  }
}
''';
}
