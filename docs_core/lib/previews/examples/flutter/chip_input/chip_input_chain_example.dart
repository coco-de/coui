import 'package:coui_flutter/coui_flutter.dart';

/// T1 저작 규약 형태의 chain 예제 — 두 인스턴스로 구성한다:
/// (1) 토큰-정확 getter **combo 체인** 1개 (`.radius16.primary` — radius
/// 축·색 축 getter 가 base 전체에서 정확히 1회씩, 랜덤 순열 토글의 치환
/// 앵커), (2) **withStyle full-control** 1개 — getter 밖 필드까지 조합해
/// `CoreChipInputStyle` 슬롯 전체를 여는 경로.
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
}
