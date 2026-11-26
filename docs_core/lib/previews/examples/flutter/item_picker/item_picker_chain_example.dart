import 'package:coui_flutter/coui_flutter.dart';

/// T1 저작 규약 형태의 chain 예제 — 두 인스턴스로 구성한다:
/// (1) 토큰-정확 getter **combo 체인** 1개 (`.radius16.primary` — radius
/// 축·색 축 getter 가 base 전체에서 정확히 1회씩, 랜덤 순열 토글의 치환
/// 앵커), (2) **withStyle full-control** 1개 — getter 밖 필드까지 조합해
/// `CoreItemPickerStyle` 슬롯 전체를 여는 경로.
class ItemPickerChainExample extends StatefulWidget {
  const ItemPickerChainExample({super.key});

  @override
  State<ItemPickerChainExample> createState() => _ItemPickerChainExampleState();
}

class _ItemPickerChainExampleState extends State<ItemPickerChainExample> {
  String _selected = '김코드';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
    );
  }
}
