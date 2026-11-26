import 'package:coui_web/coui_web.dart';

/// T1 저작 규약 형태의 chain 예제 — 두 인스턴스로 구성한다:
/// (1) 토큰-정확 getter **combo 체인** 1개 (`.radius16.primary` — radius
/// 축·색 축 getter 가 base 전체에서 정확히 1회씩, 랜덤 순열 토글의 치환
/// 앵커), (2) **withStyle full-control** 1개 — getter 밖 필드까지 조합해
/// `CorePopupStyle` 슬롯 전체를 여는 경로.
class PopupChainExample extends StatelessComponent {
  const PopupChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        Popup(
          children: [
            div(
              [Text('프로필').bodyMedium],
              classes: 'px-${CoreSpace.scale.space8} py-${CoreSpace.scale.space4}',
            ),
            div(
              [Text('설정').bodyMedium],
              classes: 'px-${CoreSpace.scale.space8} py-${CoreSpace.scale.space4}',
            ),
            div(
              [Text('로그아웃').bodyMedium],
              classes: 'px-${CoreSpace.scale.space8} py-${CoreSpace.scale.space4}',
            ),
          ],
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        Popup(
          children: [
            div(
              [Text('프로필').bodyMedium],
              classes: 'px-${CoreSpace.scale.space8} py-${CoreSpace.scale.space4}',
            ),
            div(
              [Text('설정').bodyMedium],
              classes: 'px-${CoreSpace.scale.space8} py-${CoreSpace.scale.space4}',
            ),
            div(
              [Text('로그아웃').bodyMedium],
              classes: 'px-${CoreSpace.scale.space8} py-${CoreSpace.scale.space4}',
            ),
          ],
        ).withStyle(
          const CorePopupStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space24,
              vertical: CoreSpace.space8,
            ),
          ),
        ),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}
