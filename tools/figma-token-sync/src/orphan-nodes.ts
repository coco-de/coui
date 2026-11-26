/// <reference types="@figma/plugin-typings" />
// 고아 노드 보기 — 빌더가 만들었지만 어디에도 붙이지 않은 조각을 그리지 않고
// 센다.
//
// ## 왜 있는가
//
// `figma.createFrame()` / `instanceOf()` 는 부모에 붙기 전까지 현재 페이지의
// (0,0) 에 떨어진다. 그래서 "만들었는데 붙이지 않은" 노드는 정확히 한 모양으로
// 남는다 — 페이지 직계 · 원점 · 컴포넌트 내부 조각의 이름(`field` · `nav` ·
// `popover panel` 같은). 렌더에는 영향이 없다. 세트 밖이라 어떤 변형에도 들어
// 가지 않기 때문이고, 바로 그래서 **아무 로그도 그 사실을 말하지 않는다.**
//
// 실제로 그런 노드가 일곱 컴포넌트에 걸쳐 21 개 쌓여 있었고, 발견 방법은 사람이
// 페이지를 손으로 훑는 것이었다. 그중 하나는 `mode tabs` · `saturation-value` ·
// `hue slider` 까지 완전히 채워진 패널이었는데, 세트 안에는 현재 코드가 그린
// 다른 판이 멀쩡히 들어 있었다 — 만들어서 다 채운 뒤 버려진 것이다. 새던
// 경로들은 그 뒤 고쳐진 것으로 보이지만, 다시 새기 시작하면 지금 구조로는 또
// 아무도 모른다.
//
// ## 무엇을 재사용하고 무엇을 재사용하지 않는가
//
// 판정에 쓰는 **이름 어휘는 어느 것도 여기서 정하지 않는다** — docs 프레임
// 접두는 `docs-frames.ts` 가, 디자이너 사본의 낱말은 `designer-parity.ts` 가
// 소유하고 여기는 import 만 한다. 여기서 다시 적으면 두 번째 어휘가 되고,
// 표기가 하나 늘어나는 날 파리티 스냅샷이 고아로 신고된다 — 그건 디자이너에게
// "지우세요" 로 읽힌다. `selftest-orphan-nodes` 가 그 포함 관계를 단언한다.
//
// 순회는 `indexDocumentComponents` 를 쓰지 **않는다**. 그 함수는 이름→노드 Map
// 하나를 돌려주는데 고아는 이름이 유일하지 않고(한 페이지에 같은 이름이 셋
// 있었다), 그 함수의 타입 필터가 버리는 자식이 정확히 여기서 찾는 것이다.
// 더 결정적인 것은 시점이다 — Generate 는 그 인덱스를 빌드 **전**에 만들고,
// 이 목록이 답하려는 것은 **이번 실행이 방금 흘린 것**이다. 빌드 전 인덱스로
// 답하면 검출기는 언제나 "0" 을 내고, 그 0 은 탐지기가 죽은 것과 화면에서
// 구별되지 않는다.
//
// 대신 갈릴 수 있는 것 — 순회의 성질 — 은 같게 맞췄다: 직계 자식만 · 재귀 없음,
// 그리고 `documentAccess: dynamic-page` 가 요구하는 페이지별 `loadAsync`.
//
// ## 왜 원점 조건만으로는 안 되는가
//
// 원점 조건 하나만 걸면 이 문서에서 **오탐 10 건**이 난다. Foundation / Overview
// 페이지의 콘텐츠 프레임(`Foundation / 01. Color — CoUI` 류 1680×N)이 전부
// (0,0) 에 놓여 있기 때문이다 — 사람이 그린 페이지에서는 그게 자연스러운
// 자리다. 검출기가 그걸 신고하면 0 이 정상값인 목록이 매번 10 으로 시작하고,
// 그 줄은 곧 읽히지 않는다.
//
// 그래서 **빌더가 그리는 페이지만** 훑는다. `figma.createFrame()` 은
// `figma.currentPage` 에 떨어지고 실행 중 그 페이지는 언제나 그 컴포넌트의
// 페이지라, 흘린 조각은 거기 말고 갈 곳이 없다(발견된 21 개가 전부 그랬다).
// 페이지 이름의 접두는 `data.ts` 가 소유한다 — 여기서 다시 적지 않는다.
//
// **아무것도 지우지 않는다.** 남은 원점 조건도 "이 문서·이 시점에서 오탐 0" 이라는
// 관측이지 오탐이 불가능하다는 증명이 아니다.

import { kComponentPageNamePrefix } from './data';
import { kDocsFrameNamePrefix } from './docs-frames';
import { kSnapshotNameWords } from './designer-parity';
import { kMaxNamesInSummary, truncatedNames } from './summary-format';

/** 판정에 필요한 전부. figma 타입을 받지 않아 노드 없이 검증된다 — 셀프테스트에
 *  `figma` 전역이 없다는 것이 이 모양의 이유다. */
export interface OrphanChild {
  type: string;
  name: string;
  x: number;
  y: number;
}

/** 한 페이지와 그 **직계** 자식들. */
export interface OrphanPage {
  page: string;
  children: readonly OrphanChild[];
}

/** 고아가 하나 이상 있는 페이지 하나. */
export interface OrphanGroup {
  page: string;
  names: string[];
}

export interface OrphanNodesReport {
  /** 실제로 훑은 페이지 수 — 문서 전체가 아니라 **빌더가 그리는 페이지**의 수다
   *  (`listOrphanNodes` 가 나머지를 거른다). 고아가 있는 페이지 수가 아니다. */
  pageCount: number;
  /** 고아가 있는 페이지만, 문서 순서대로. */
  groups: OrphanGroup[];
  /** 고아 노드 총수 = `groups` 의 이름 수 합. */
  count: number;
}

/**
 * 이 페이지 직계 자식이 고아인가. 순수 — 조건 순서까지 이슈 #4866 의 판정 그대로.
 *
 * `COMPONENT` 를 제외하는 것은 아래 원점 조건이 어차피 거르기 때문이 **아니라**,
 * 규칙이 자기 의도를 말하게 하려는 것이다. 변형 축이 없는 컴포넌트는 세트가
 * 아니라 맨 `COMPONENT` 로 페이지 직계에 그려지는 것이 정상이고(이 문서에 47 개
 * 있다), `mountSet` 이 큰 세트를 그리는 동안 세트 **옆**에 파킹하는 멤버도
 * `COMPONENT` 다. 둘 다 고아가 아니며 둘 다 여기서 절대 걸리지 않아야 한다 —
 * 타입 조건과 원점 조건의 이중 방어다. 이 문단이 없으면 다음 사람이 "원점
 * 조건이 이미 거르는데 타입 조건은 왜 있나" 로 읽고 지운다.
 */
export function isOrphanChild(child: OrphanChild): boolean {
  if (child.type === 'COMPONENT' || child.type === 'COMPONENT_SET') return false;
  if (child.name.startsWith(kDocsFrameNamePrefix)) return false;
  if (kSnapshotNameWords.some((word) => child.name.includes(word))) return false;
  // 핵심 판별식 — 붙인 적이 없다는 신호. 빌더가 그리는 페이지에서 (0,0) 은 아무
  // 것도 놓지 않는 자리다: 세트는 (120,120) 에, docs 프레임과 디자이너 사본은
  // 그 옆에 놓인다. 사람이 그린 페이지에서는 반대로 (0,0) 이 자연스러운 자리라
  // 이 조건 하나만으로는 오탐이 난다 — 그래서 페이지를 먼저 거른다(헤더 참조).
  return child.x === 0 && child.y === 0;
}

/** 순수 — 훑은 결과를 페이지별로 묶는다. UI 버튼과 Generate 꼬리가 같은 함수를
 *  지나므로 두 자리가 같은 상태에 같은 답을 준다. */
export function classifyPages(pages: readonly OrphanPage[]): OrphanNodesReport {
  const groups: OrphanGroup[] = [];
  for (const page of pages) {
    const names = page.children.filter(isOrphanChild).map((child) => child.name);
    if (names.length > 0) groups.push({ page: page.page, names });
  }
  return {
    pageCount: pages.length,
    groups,
    count: groups.reduce((sum, group) => sum + group.names.length, 0),
  };
}

/** Reads the canvas. Nothing is written — no stamp, no node, no page.
 *
 *  `onlyPages` narrows the walk to those page names — Generate's tail passes
 *  the pages a cache-hit run loaded (#4803), since a run's leaks land only on
 *  the pages it drew. Absent = every builder page (the UI button). */
export async function listOrphanNodes(
  onlyPages?: ReadonlySet<string>,
): Promise<OrphanNodesReport> {
  const pages: OrphanPage[] = [];
  for (const page of figma.root.children) {
    // 빌더가 그리는 페이지만 — 사람이 그린 페이지에서는 (0,0) 이 콘텐츠의 자리라
    // 원점 조건이 거짓말을 한다(헤더의 "왜 원점 조건만으로는 안 되는가").
    // 이름은 로드 없이 읽히므로, 거른 페이지는 `loadAsync` 왕복도 하지 않는다.
    if (!page.name.startsWith(kComponentPageNamePrefix)) continue;
    if (onlyPages !== undefined && !onlyPages.has(page.name)) continue;
    // `documentAccess: dynamic-page` 는 로드되지 않은 페이지의 `.children` 을
    // 거부한다. Generate 꼬리에서는 이미 전부 로드돼 있어 즉시 돌아온다.
    await page.loadAsync();
    pages.push({
      page: page.name,
      children: page.children.map((child) => ({
        type: child.type,
        name: child.name,
        x: child.x,
        y: child.y,
      })),
    });
  }
  return classifyPages(pages);
}

/** 페이지 묶음을 접을 때의 꼬리. 이름 축(`truncatedNames`)과 이 페이지 축이 한
 *  줄에서 똑같이 `… (+N)` 으로 접히면 무엇이 접혔는지 읽을 수 없어, 이쪽만
 *  단위를 적는다. */
function truncatedGroups(parts: readonly string[]): string {
  const shown = parts.slice(0, kMaxNamesInSummary).join(' · ');
  const rest = parts.length - kMaxNamesInSummary;
  return rest > 0 ? `${shown} · … (+${rest} 페이지)` : shown;
}

/**
 * The log lines. Pure so the wording is testable and the UI button and the
 * Generate tail print the same sentence for the same state — two phrasings of
 * "무엇이 떠 있나" would be read as two different facts.
 *
 *   고아 노드 21 / 페이지 199 — ❖ Label: icon, Icon · ❖ Filter: reset, … (+4 페이지)
 * or, when nothing is floating:
 *   고아 노드 없음 ✅ (페이지 199)
 *
 * 접히는 것은 나열뿐이다 — 개수(21 · 199)는 언제나 문서 전체에 대한 참값이다.
 */
export function formatOrphanNodes(report: OrphanNodesReport): string[] {
  if (report.count === 0) return [`고아 노드 없음 ✅ (페이지 ${report.pageCount})`];
  const parts = report.groups.map((group) => `${group.page}: ${truncatedNames(group.names)}`);
  return [`고아 노드 ${report.count} / 페이지 ${report.pageCount} — ${truncatedGroups(parts)}`];
}
