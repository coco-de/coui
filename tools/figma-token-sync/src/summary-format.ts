// 로그 요약의 이름 나열 캡 — 이름은 접고, 개수는 접지 않는다.
//
// ## 왜 별도 모듈인가
//
// 플러그인을 다시 빌드하면 공유 소스 해시가 전 엔트리에 대해 함께 움직여
// ~100+ 세트가 한꺼번에 낡음이 된다. 그 줄은 버튼뿐 아니라 **모든** Generate
// 실행의 꼬리이고, 상한 없는 `join` 이 그 한 줄을 레지스트리 전체로 만든 적이
// 한 번 있다.
//
// 그 꼬리를 쓰는 요약이 이제 둘이다 — 낡은 세트(`stale-sets.ts`)와 고아 노드
// (`orphan-nodes.ts`). 같은 로그창의 두 줄이 서로 다른 말줄임 관례를 쓰면
// 읽는 사람이 무엇이 접혔는지 알 수 없고, 각자 자기 사본을 들면 한쪽만
// 고쳐지는 날 그 차이가 조용히 생긴다.
//
// 이 파일은 아무것도 import 하지 않는다. `content-hash.ts` 를 leaf 로 뺀 것과
// 같은 형태이고 같은 이유다 — 두 소비자 중 어느 쪽을 import 해도 그 방향이
// 언젠가 역류하면 순환이 된다. `selftest-orphan-nodes` 가 leaf 임을 단언한다.

/** How many names a summary spells out before folding the rest into a count. */
export const kMaxNamesInSummary = 5;

/** `names.join(', ')`, but capped — the same cap `generate.ts` already uses
 *  for its "legacy page kept" summary, so a reader who has seen one has seen
 *  both. */
export function truncatedNames(names: readonly string[]): string {
  const shown = names.slice(0, kMaxNamesInSummary).join(', ');
  const rest = names.length - kMaxNamesInSummary;
  return rest > 0 ? `${shown}, … (+${rest})` : shown;
}
