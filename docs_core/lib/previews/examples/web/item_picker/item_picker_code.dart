/// Returns a Web code snippet string for the ItemPicker component.
String itemPickerCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class ItemPickerChainExample extends StatefulComponent {
  const ItemPickerChainExample({super.key});

  @override
  State<ItemPickerChainExample> createState() => _ItemPickerChainExampleState();
}

class _ItemPickerChainExampleState extends State<ItemPickerChainExample> {
  String _selected = '김코드';

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        ItemPicker(
          items: const ['김코드', '이코드', '박코드', '최코드', '정코드'],
          selectedValue: _selected,
          title: '담당자',
          onChanged: (value) => setState(() => _selected = value),
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderColor·borderWidth)까지 한 번에.
        ItemPicker(
          items: const ['김코드', '이코드', '박코드', '최코드', '정코드'],
          selectedValue: _selected,
          title: '직접 지정',
          onChanged: (value) => setState(() => _selected = value),
        ).withStyle(
          const CoreItemPickerStyle(
            backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
            borderColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            borderWidth: CoreStrokeWidth.stroke2,
          ),
        ),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}''',
    _ =>
      '''
class ItemPickerDefaultExample extends StatefulComponent {
  const ItemPickerDefaultExample({super.key});

  @override
  State<ItemPickerDefaultExample> createState() =>
      _ItemPickerDefaultExampleState();
}

class _ItemPickerDefaultExampleState extends State<ItemPickerDefaultExample> {
  String _selected = '김코드';

  @override
  Component build(BuildContext context) {
    return ItemPicker(
      items: const ['김코드', '이코드', '박코드', '최코드', '정코드'],
      selectedValue: _selected,
      title: '담당자',
      onChanged: (value) => setState(() => _selected = value),
    );
  }
}''',
  };
}
