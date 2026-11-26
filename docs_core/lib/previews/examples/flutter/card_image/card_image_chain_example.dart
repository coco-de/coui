import 'package:coui_flutter/coui_flutter.dart';

/// T1 저작 규약 형태의 chain 예제 — 두 인스턴스로 구성한다:
/// (1) 토큰-정확 getter **combo 체인** 1개 (`.radius16.primary` — radius
/// 축·색 축 getter 가 base 전체에서 정확히 1회씩, 랜덤 순열 토글의 치환
/// 앵커), (2) **withStyle full-control** 1개 — getter 밖 필드까지 조합해
/// `CoreCardImageStyle` 슬롯 전체를 여는 경로.
class CardImageChainExample extends StatelessWidget {
  const CardImageChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        SizedBox(
          width: 240,
          child: CardImage(
            image: Image.network(
              'https://picsum.photos/seed/coui/240/160',
              width: 240,
              height: 160,
              fit: BoxFit.cover,
            ),
            title: const Text('산 풍경'),
            subtitle: const Text('해 뜰 무렵 촬영'),
            onPressed: () {},
          ).radius16.primary,
        ),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(frameStyle.borderColor)
        // 까지 한 번에.
        SizedBox(
          width: 240,
          child:
              CardImage(
                image: Image.network(
                  'https://picsum.photos/seed/coui/240/160',
                  width: 240,
                  height: 160,
                  fit: BoxFit.cover,
                ),
                title: const Text('산 풍경'),
                subtitle: const Text('해 뜰 무렵 촬영'),
                onPressed: () {},
              ).withStyle(
                const CoreCardImageStyle(
                  frameStyle: CoreOutlinedContainerStyle(
                    backgroundColor: CoreColor.token(
                      CoreColors.tertiaryContainer,
                    ),
                    borderColor: CoreColor.token(CoreColors.tertiary),
                    borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
                  ),
                ),
              ),
        ),
      ],
    );
  }
}
