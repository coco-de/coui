import 'package:docs_app/src/markdown/docs_tag.dart';
import 'package:docs_app/src/preview/live_preview_tag.dart';
import 'package:flutter_test/flutter_test.dart';

/// `<LivePreview>` 태그 → 변형 해석의 docs_site 파리티 게이트.
///
/// 해석은 공유 단일 출처(`resolveDocsPreviewVariants`)지만 **태그 속성 →
/// 파라미터 배선**은 플랫폼별 태그 핸들러 몫이라, 한쪽만 배선되면 같은 md
/// 가 두 앱에서 다르게 렌더된다 — 실제로 `chain="off"` 큐레이션이 jaspr
/// 쪽에만 배선돼 docs_app 이 큐레이션 페이지에 chain 갤러리를 태그 수만큼
/// 중복 노출한 회귀가 있었다.
void main() {
  DocsTag tag(Map<String, String> attributes) =>
      DocsTag(name: 'LivePreview', attributes: attributes);

  group('resolveLivePreviewTagVariants', () {
    // `command` 는 chain 스니펫 보유 — 레지스트리 파생 판정이라 목록
    // 하드코딩 없이 chain-capable 대표로 쓴다 (docs_core 테스트와 동일).
    test('chain 스니펫 보유 컴포넌트는 chain 이 덧붙는다 (appended 출하 모드)', () {
      expect(
        resolveLivePreviewTagVariants(tag({'component': 'command'})),
        equals(const ['default', 'chain']),
      );
    });

    test('chain="off" 태그 큐레이션은 선언 그대로다 — docs_site 와 동일 배선', () {
      expect(
        resolveLivePreviewTagVariants(
          tag({'component': 'command', 'chain': 'off'}),
        ),
        isEmpty,
      );
      expect(
        resolveLivePreviewTagVariants(
          tag({'component': 'command', 'variant': 'default', 'chain': 'off'}),
        ),
        equals(const ['default']),
      );
    });

    test('component 없으면 빈 목록 (태그 skip 과 정합)', () {
      expect(resolveLivePreviewTagVariants(tag({})), isEmpty);
    });
  });
}
