import 'package:coui_flutter/coui_flutter.dart';

/// T1 저작 규약 형태의 chain 예제 — 두 인스턴스로 구성한다:
/// (1) 토큰-정확 getter **combo 체인** 1개 (`.radius16.primary` — radius
/// 축·색 축 getter 가 base 전체에서 정확히 1회씩, 랜덤 순열 토글의 치환
/// 앵커), (2) **withStyle full-control** 1개 — getter 밖 필드까지 조합해
/// `CoreProgressStyle` 슬롯 전체를 여는 경로.
class ProgressChainExample extends StatefulWidget {
  const ProgressChainExample({super.key});

  @override
  State<ProgressChainExample> createState() => _ProgressChainExampleState();
}

class _ProgressChainExampleState extends State<ProgressChainExample> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        SizedBox(
          width: double.infinity,
          child: const Progress(value: 0.65).radius16.primary,
        ),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(minHeight)까지 한 번에.
        SizedBox(
          width: double.infinity,
          child: const Progress(value: 0.65).withStyle(
            const CoreProgressStyle(
              color: CoreColor.token(CoreColors.tertiary),
              borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
              minHeight: CoreSpace.space16,
            ),
          ),
        ),
      ],
    );
  }
}
