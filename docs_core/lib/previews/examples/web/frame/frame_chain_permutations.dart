// GENERATED — dart run tool/generate_chain_artifacts.dart (write mode).
// Do not hand-edit; edit the `*StyleChain` extension sources and regenerate.

/// T1 순열 렌더러 — 랜덤 토글 전용 (코드 패널 비노출, 문서용 chain 예제와
/// 역할 분리).
///
/// base 예제(`FrameChainExample`)를 변환-복제한 것이라 **같은
/// 2-인스턴스 구조**에서 combo 인스턴스만 순열 좌표를 적용한다 — 코드
/// 치환 결과와 시각이 1:1 이고, 첫 클릭에 콘텐츠 구조 점프가 없다.
library;

import 'package:coui_web/coui_web.dart';
import '../../../../shared/chain_permutations.dart';

/// [permutation] 좌표를 적용한 Frame chain 프리뷰를 만든다.
Component buildFrameChainPermutation(ChainPermutation permutation) =>
    _FrameChainPermutationView(permutation: permutation);

class _FrameChainPermutationView extends StatelessComponent {
  const _FrameChainPermutationView({required this.permutation});

  /// 현재 순열 좌표 — combo 인스턴스에만 적용된다.
  final ChainPermutation permutation;

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        Frame(
          direction: CoreFrameDirection.row,
          gap: CoreSpace.space12,
          crossAxisAlignment: CoreCrossAxisAlignment.center,
          padding: const CoreEdgeInsets.all(CoreSpace.space16),
          children: [
            Icon(
              LucideIcons.frame,
              iconStyle: CoreIconStyle(size: CoreSpace.space24),
            ),
            Text('기본 프레임'),
          ],
        ).chainPermuted(permutation),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderColor·borderWidth)까지 한 번에.
        Frame(
          direction: CoreFrameDirection.row,
          gap: CoreSpace.space12,
          crossAxisAlignment: CoreCrossAxisAlignment.center,
          padding: const CoreEdgeInsets.all(CoreSpace.space16),
          children: [
            Icon(
              LucideIcons.frame,
              iconStyle: CoreIconStyle(size: CoreSpace.space24),
            ),
            Text('직접 지정'),
          ],
        ).withStyle(
          const CoreFrameStyle(
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
}

/// 좌표를 radius 19-way + 색 11-way **독립 switch** 로 축 분해 적용 —
/// 209-way 단일 테이블 금지. getter 이름은 어휘 상수에서만 오므로
/// 존재하지 않는 getter 참조가 구조적으로 불가능하다.
extension _FrameChainPermutations on Frame {
  Frame chainPermuted(ChainPermutation permutation) {
    final radiused = switch (kChainRadiusGetters[permutation.radiusIndex]) {
      'radius0' => radius0,
      'radius2' => radius2,
      'radius4' => radius4,
      'radius6' => radius6,
      'radius8' => radius8,
      'radius10' => radius10,
      'radius12' => radius12,
      'radius14' => radius14,
      'radius16' => radius16,
      'radius20' => radius20,
      'radius24' => radius24,
      'radius28' => radius28,
      'radius32' => radius32,
      'radius36' => radius36,
      'radius40' => radius40,
      'radius48' => radius48,
      'radius56' => radius56,
      'radius64' => radius64,
      'radius9999' => radius9999,
      _ => radius16,
    };
    return switch (kChainColorGetters[permutation.colorIndex]) {
      'primary' => radiused.primary,
      'secondary' => radiused.secondary,
      'tertiary' => radiused.tertiary,
      'surface' => radiused.surface,
      'surfaceContainer' => radiused.surfaceContainer,
      'error' => radiused.error,
      'success' => radiused.success,
      'warning' => radiused.warning,
      'info' => radiused.info,
      'outline' => radiused.outline,
      'transparent' => radiused.transparent,
      _ => radiused.primary,
    };
  }
}
