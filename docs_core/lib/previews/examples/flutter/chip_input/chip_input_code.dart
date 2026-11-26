/// Returns a Flutter code snippet string for the ChipInput component.
String chipInputCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class ChipInputChainExample extends StatefulWidget {
  const ChipInputChainExample({super.key});

  @override
  State<ChipInputChainExample> createState() => _ChipInputChainExampleState();
}

class _ChipInputChainExampleState extends State<ChipInputChainExample> {
  List<String> _chips = const <String>['Flutter', 'Dart'];

  void handleChanged(List<String> chips) {
    setState(() {
      _chips = chips;
    });
  }

  void handleSubmitted(String text) {
    setState(() {
      _chips = [..._chips, text];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        ChipInput(
          chips: _chips,
          placeholder: '태그를 입력해 주세요',
          onChanged: handleChanged,
          onSubmitted: handleSubmitted,
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        ChipInput(
          chips: _chips,
          placeholder: '태그를 입력해 주세요',
          onChanged: handleChanged,
          onSubmitted: handleSubmitted,
        ).withStyle(
          const CoreChipInputStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space24,
              vertical: CoreSpace.space8,
            ),
            chipSpacing: CoreSpace.space8,
          ),
        ),
      ],
    );
  }
}''',
    _ =>
      '''
class ChipInputDefaultExample extends StatefulWidget {
  const ChipInputDefaultExample({super.key});

  @override
  State<ChipInputDefaultExample> createState() =>
      _ChipInputDefaultExampleState();
}

class _ChipInputDefaultExampleState extends State<ChipInputDefaultExample> {
  List<String> _chips = const <String>['Flutter', 'Dart'];

  void handleChanged(List<String> chips) {
    setState(() {
      _chips = chips;
    });
  }

  void handleSubmitted(String text) {
    setState(() {
      _chips = [..._chips, text];
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChipInput(
      chips: _chips,
      placeholder: '태그를 입력해 주세요',
      onChanged: handleChanged,
      onSubmitted: handleSubmitted,
    );
  }
}''',
  };
}
