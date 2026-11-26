import 'package:coui_web/coui_web.dart';

/// T1 저작 규약 형태의 chain 예제 — 두 인스턴스로 구성한다:
/// (1) 토큰-정확 getter **combo 체인** 1개 (`.radius16.primary` — radius
/// 축·색 축 getter 가 base 전체에서 정확히 1회씩, 랜덤 순열 토글의 치환
/// 앵커), (2) **withStyle full-control** 1개 — getter 밖 필드까지 조합해
/// `CoreHoverCardStyle` 슬롯 전체를 여는 경로.
class HoverCardChainExample extends StatelessComponent {
  const HoverCardChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        HoverCard(
          trigger: const Text('@coui').bodyMedium.onPrimaryContainer.underline,
          content: const Text('크로스 플랫폼 UI 디자인 시스템.').bodySmall.onSurface,
          placement: CorePopoverPlacement.bottom,
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderColor·padding)까지 한 번에.
        HoverCard(
          trigger: const Text('직접 지정').bodyMedium.onPrimaryContainer.underline,
          content: const Text('크로스 플랫폼 UI 디자인 시스템.').bodySmall.onSurface,
          placement: CorePopoverPlacement.bottom,
        ).withStyle(
          const CoreHoverCardStyle(
            panelStyle: CorePopupStyle(
              backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
              borderColor: CoreColor.token(CoreColors.tertiary),
              borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
              padding: CoreEdgeInsets.symmetric(
                horizontal: CoreSpace.space24,
                vertical: CoreSpace.space8,
              ),
            ),
          ),
        ),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}
