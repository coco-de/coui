@TestOn('vm')
library;

import 'package:docs_core/shared/preview_constraints.dart';
import 'package:test/test.dart';

/// 프리뷰 제약 조회 단일 출처(`docsPreviewConstraintsFor`)의 계약을
/// 고정한다 — Web 팬·Flutter 팬이 같은 함수를 부르므로 조회 순서가
/// 여기서 깨지면 두 팬의 세로가 어긋나거나 chain 프리뷰가 잘린다.
void main() {
  test('non-chain: component/variant → component → 기본값 순서 유지', () {
    // 명시 per-variant 키가 있으면 그것.
    expect(
      docsPreviewConstraintsFor('typography', 'scale'),
      kDocsPreviewConstraints['typography/scale'] ?? docsPreviewConstraintsFor('typography', null),
    );
    // component 키.
    expect(
      docsPreviewConstraintsFor('accordion', 'default'),
      kDocsPreviewConstraints['accordion'],
    );
    // 미등록 → 기본값.
    expect(
      docsPreviewConstraintsFor('no-such-component', null),
      kDocsDefaultConstraints,
    );
  });

  test('chain 하한: 단일-행 컴포넌트도 chain 변형은 medium 이상', () {
    // chain 예제는 2-인스턴스(combo + withStyle) 저작 규약이라 기본
    // 80px 이 구조적으로 부족하다 — 프리뷰 클리핑 방지 하한.
    final button = docsPreviewConstraintsFor('button', 'chain');
    expect(button.maxHeight, kDocsMediumConstraints.maxHeight);
    expect(
      docsPreviewConstraintsFor('button', null),
      kDocsDefaultConstraints,
      reason: 'non-chain 은 기존 그대로 (하한 미적용)',
    );
  });

  test('chain 하한은 더 큰 컴포넌트 제약을 깎지 않는다', () {
    // accordion 은 tall(400) — chain 이라고 medium(200)으로 줄면 안 된다.
    final accordion = docsPreviewConstraintsFor('accordion', 'chain');
    expect(
      accordion.maxHeight,
      greaterThanOrEqualTo(kDocsPreviewConstraints['accordion']!.maxHeight),
    );
  });

  test(
    'text-field: default 는 기본 무대, error/chain 은 medium',
    () {
      // `default` 변형은 에러 줄이 없는 필드 하나다 — 표준 밀도 40px,
      // spacious 48px. 두 팬이 모두 이 조회의 maxHeight 를 무대 높이로
      // 쓰므로 medium 을 주면 필드 아래로 ~150px 가 비고, compact(56)는
      // spacious 필드(인셋 포함 64)를 담지 못한다.
      expect(
        docsPreviewConstraintsFor('text-field', 'default'),
        kDocsDefaultConstraints,
      );
      // error 는 에러 줄이 붙어 80px 를 넘으므로 그대로 medium 유지.
      expect(
        docsPreviewConstraintsFor('text-field', 'error'),
        kDocsMediumConstraints,
      );
      // chain 은 명시 키가 없으니 base('text-field') 를 보되, chain
      // 하한 규칙이 그 base 를 medium 이상으로 그대로 유지시킨다.
      final chain = docsPreviewConstraintsFor('text-field', 'chain');
      expect(chain.maxHeight, kDocsMediumConstraints.maxHeight);
    },
  );
}
