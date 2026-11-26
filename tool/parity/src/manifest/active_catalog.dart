// 카탈로그 순회의 단일 출처 — 매트릭스 파생(`parity_manifest.dart` 의
// `_expand`)과 프루닝 쌍 파생(`pruned_pairs.dart` 의 `resolvePrunedPairs`)이
// 반드시 같은 활성 컴포넌트 집합을 봐야 한다.
//
// 순회가 두 파일에 각자 복제돼 있던 동안 deprecated 제외가 매트릭스
// 쪽에만 들어갔고, 프루닝 쌍은 deprecated 컴포넌트를 계속 확장해 야간
// 스윕의 프루닝 재확인 캡처가 "kWebPreviewRegistry 에 없음" 으로 죽었다 —
// "같은 파생은 정확히 한 곳" 을 어기면 한쪽만 고쳐지는 정확한 사고 유형.
import 'package:docs_core/shared/component_catalog.dart';

/// 활성 카탈로그 컴포넌트 한 항목 — 소속 [DocsComponentGroup] 은 tier
/// 판정(`tier1_policy.dart` 의 그룹 id 기반 규칙)이 필요로 해서 함께
/// 나른다.
typedef ActiveCatalogComponent = ({
  DocsComponentGroup group,
  DocsComponentEntry component,
});

/// 활성(비-deprecated) 카탈로그 컴포넌트를 그룹 순서대로 낸다.
///
/// deprecated 를 제외하는 이유: deprecate 시 Web 은 프리뷰 레지스트리째
/// 삭제되므로(레포 관례 — Flutter 는 `@Deprecated` 보존, Web 은 완전
/// 삭제) 한쪽 캡처가 원리적으로 불가능하다. 파리티/회귀/프루닝 검증은
/// 전부 양 플랫폼이 살아있는 컴포넌트에 대한 진술이라, 어떤 파생에도
/// deprecated 가 나타나면 안 된다.
Iterable<ActiveCatalogComponent> activeCatalogComponents() sync* {
  for (final group in kDocsComponentGroups) {
    for (final component in group.items) {
      if (component.isDeprecated) continue;
      yield (group: group, component: component);
    }
  }
}
