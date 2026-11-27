// GENERATED — dart run tool/generate_chain_artifacts.dart (write mode).
// Do not hand-edit; edit the `*StyleChain` extension sources and regenerate.

/// T1 순열 렌더러 — 랜덤 토글 전용 (코드 패널 비노출, 문서용 chain 예제와
/// 역할 분리).
///
/// base 예제(`FieldsetChainExample`)를 변환-복제한 것이라 **같은
/// 2-인스턴스 구조**에서 combo 인스턴스만 순열 좌표를 적용한다 — 코드
/// 치환 결과와 시각이 1:1 이고, 첫 클릭에 콘텐츠 구조 점프가 없다.
library;

import 'package:coui_web/coui_web.dart';
import '../../../../shared/chain_permutations.dart';

/// [permutation] 좌표를 적용한 Fieldset chain 프리뷰를 만든다.
Component buildFieldsetChainPermutation(ChainPermutation permutation) =>
    _FieldsetChainPermutationView(permutation: permutation);

class _FieldsetChainPermutationView extends StatelessComponent {
  const _FieldsetChainPermutationView({required this.permutation});

  /// 현재 순열 좌표 — combo 인스턴스에만 적용된다.
  final ChainPermutation permutation;

  @override
  Component build(BuildContext context) {
    // Fixed-width wrappers keep the preview at the same width as
    // Flutter's `SizedBox(width: CoreSpace.space256)` — the docs
    // preview pane uses `align-items: center` for cross-platform
    // visual parity, so we anchor a known size instead of letting
    // the fieldset stretch to the pane's full inline-axis.
    return div(
      [
        // 팔레트 미리보기에서는 색을 직접 지정한다.
        div(
          [
            Fieldset(
              legend: const Text('계정'),
              children: [
                TextField(
                  autofillHints: const ['name'],
                  placeholder: const Text('이름'),
                ),
                TextField(
                  autofillHints: const ['email'],
                  placeholder: const Text('이메일'),
                ),
              ],
            ).chainPermuted(permutation),
          ],
          classes: 'w-${CoreSpace.scale.space256}',
        ),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        div(
          [
            Fieldset(
              legend: const Text('계정'),
              children: [
                TextField(
                  autofillHints: const ['name'],
                  placeholder: const Text('이름'),
                ),
                TextField(
                  autofillHints: const ['email'],
                  placeholder: const Text('이메일'),
                ),
              ],
            ).withStyle(
              const CoreFieldsetStyle(
                backgroundColor: .tertiary,
                borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
                fieldSpacing: CoreSpace.space12,
                padding: CoreEdgeInsets.symmetric(
                  horizontal: CoreSpace.space24,
                  vertical: CoreSpace.space8,
                ),
              ),
            ),
          ],
          classes: 'w-${CoreSpace.scale.space256}',
        ),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}

/// 좌표를 radius 19-way + 색 11-way **독립 switch** 로 축 분해 적용 —
/// 209-way 단일 테이블 금지. getter 이름은 어휘 상수에서만 오므로
/// 존재하지 않는 getter 참조가 구조적으로 불가능하다.
extension _FieldsetChainPermutations on Fieldset {
  Fieldset chainPermuted(ChainPermutation permutation) {
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
      'primary' => radiused.backgroundColor(.primary),
      'secondary' => radiused.backgroundColor(.secondary),
      'tertiary' => radiused.backgroundColor(.tertiary),
      'surface' => radiused.backgroundColor(.surface),
      'surfaceContainer' => radiused.backgroundColor(.surfaceContainer),
      'error' => radiused.backgroundColor(.error),
      'success' => radiused.backgroundColor(.success),
      'warning' => radiused.backgroundColor(.warning),
      'info' => radiused.backgroundColor(.info),
      'outline' => radiused.backgroundColor(.outline),
      'transparent' => radiused.backgroundColor(.transparent),
      _ => radiused.backgroundColor(.primary),
    };
  }
}
