/// <reference types="@figma/plugin-typings" />
// 겹친 형제 보기 — 한 변형 안에 같은 이름의 직계 자식이 **다른 세션의 것까지**
// 두 벌 들어 있는 것을 그리지 않고 센다.
//
// ## 왜 있는가
//
// 오래 열려 있던 Figma 탭이 다시 연결되면 멀티플레이어가 그 탭이 그때 쓴 것을
// **삭제 없이 추가로** 병합한다. 그 쓰기가 붙을 노드가 아직 같은 id 로 남아
// 있으면(변형 컨테이너가 두 세션에 걸쳐 재사용된 세트), 변형 안에 옛 세션의
// 자식이 현재 자식 옆에 **한 벌 더** 들어간다. 이름은 같고 위치만 어긋난다.
//
// 렌더는 멀쩡해 보이거나 살짝 겹쳐 보일 뿐이고 **아무 로그도 그 사실을 말하지
// 않는다.** 실제로 13 세트 · 486 노드가 그렇게 들어가 있었고, 발견 방법은
// 디자이너가 트리거가 겹쳐 보인다고 말한 것이었다. 실행 잠금은 이걸 막지
// 못한다 — 동시 실행이 아니라 이틀 늦게 도착한 쓰기이기 때문이다.
//
// ## 판정 — 이름과 id 대역
//
// 한 변형(느슨한 컴포넌트면 그 컴포넌트)의 **직계 자식만** 이름으로 묶는다. 한 이름에 노드가 둘 이상이고 그
// id 대역(콜론 앞 숫자)이 갈리면, 가장 큰 대역이 아닌 쪽을 센다. 대역은 그
// 노드를 만든 세션의 흔적이라, 같은 세션이 만든 정당한 반복(`item` × 4)은
// 대역이 같아 자동으로 빠진다.
//
// **기록이 먼저다.** 다시 그릴 때 안쪽 노드를 유지하면(`redraw-keep.ts`) 한
// 변형 안에 옛 실행이 만든 노드와 이번 실행이 만든 노드가 섞이는 것이 정상이다.
// 같은 이름의 정당한 형제(목록의 구분선 둘)가 하나는 유지되고 하나는 교체되면
// 대역이 갈려, 대역만 보면 겹친 형제로 읽힌다 — Command 의 변형 18 개가 그렇게
// 세어졌다. 그래서 유지가 일어난 변형에는 정리를 마친 직계 자식의 id 가
// 기록되고(`kDrawnChildrenKey`), 기록이 있는 변형에서는 **기록 밖의 노드만**
// 센다. 기록이 없는 변형은 대역으로 판정한다.
//
// 대역 비교는 **관측이지 증명이 아니다.** 그래서 **아무것도 지우지 않는다.**
// 지우는 것은 Generate(다시 그릴 때 짝이 없는 옛 자식은 지워진다) 또는 사람의
// 결정이다.
//
// ## 이 검출기가 보는 층과 보지 않는 층
//
// 같은 잔해는 세 층에 남는다. 이 검출기는 그중 하나만 본다:
//
//   - **변형 직계** — 여기. 느슨한 컴포넌트(세트가 아닌 페이지 직계 COMPONENT)는
//     자기 직계 자식이 곧 한 변형이다.
//   - **페이지 직계** — 고아 노드 검출기(`orphan-nodes.ts`)가 본다. 옛 세션의
//     패널 프레임이 페이지 원점에 남은 것이 그 층이었다.
//   - **중첩 인스턴스의 프로퍼티** — 노드가 아니라 오버라이드 값이 병합된 것이라
//     이름·대역으로는 보이지 않는다. 재생성만이 걷는다.
//
// 골격은 `orphan-nodes.ts` 와 같다: 순수 판정 · 주입 분류 · impure lister ·
// 순수 포매터. UI 버튼과 Generate 꼬리가 같은 함수를 지나 같은 문장을 낸다.

import { kComponentPageNamePrefix } from './data';
import { kDrawnChildrenKey } from './redraw-keep';
import { kMaxNamesInSummary } from './summary-format';

/** 판정에 필요한 전부 — figma 타입을 받지 않아 셀프테스트가 plain 객체로 돈다. */
export interface SiblingNode {
  id: string;
  name: string;
}

/**
 * 세트 하나 — 변형마다 **직계** 자식.
 *
 * 빌더가 `ComponentNode` 를 돌려주는 **느슨한 컴포넌트**(Menu · DropdownMenu ·
 * Drawer · Popover 류 — 세트가 아니라 페이지 직계의 COMPONENT)도 여기 들어온다.
 * 그 컴포넌트는 자기 직계 자식을 **변형 하나**로 가진다. 이름의 "세트" 는 훑는
 * 단위를 말할 뿐이다.
 */
export interface SiblingSet {
  set: string;
  page: string;
  variants: readonly (readonly SiblingNode[])[];
  /** Per variant, the children the last redraw settled on (`kDrawnChildrenKey`),
   *  or null where the variant carries no record. Absent = no records at all. */
  drawn?: readonly (ReadonlySet<string> | null)[];
}

export interface OverlapGroup {
  set: string;
  /** 이 세트의 모든 변형에 걸친 겹친 형제 수. */
  count: number;
  /** 겹친 형제가 하나라도 있는 변형 수. */
  variants: number;
}

export interface OverlappingSiblingsReport {
  /** 훑은 세트 수(느슨한 컴포넌트 포함) — 겹친 세트 수가 아니다. */
  setCount: number;
  /** 겹친 형제가 있는 세트만, 문서 순서대로. */
  groups: OverlapGroup[];
  /** 겹친 형제 총수 = `groups` 의 count 합. */
  count: number;
}

/**
 * id 의 대역 — 콜론 앞 숫자. 노드를 만든 세션의 흔적이다(`4206:1234` → 4206).
 * 인스턴스 안쪽 id(`I…;…`)처럼 이 모양이 아니면 `null` — 대역을 모르는 노드는
 * 판정에서 빠진다(세지 않는 쪽으로 틀린다).
 */
export function idBand(id: string): number | null {
  const match = /^(\d+):\d+$/.exec(id);
  return match === null ? null : Number(match[1]);
}

/**
 * 한 변형의 직계 자식 중 겹친 형제. 순수.
 *
 * 한 이름에 둘 이상이고 대역이 **갈릴 때만**, 최댓값 대역이 아닌 쪽을 돌려준다.
 * 같은 대역의 반복은 같은 세션이 만든 정당한 반복이라 빠진다.
 */
export function overlappingSiblingsOf(
  children: readonly SiblingNode[],
  drawn: ReadonlySet<string> | null = null,
): SiblingNode[] {
  const byName = new Map<string, SiblingNode[]>();
  for (const child of children) {
    const bucket = byName.get(child.name) ?? [];
    bucket.push(child);
    byName.set(child.name, bucket);
  }
  const out: SiblingNode[] = [];
  for (const bucket of byName.values()) {
    if (bucket.length < 2) continue;
    // A redraw that kept nodes records the children it settled on: those are
    // this plugin's, whatever their bands, and only a sibling outside the record
    // can be a late-synced duplicate (`kDrawnChildrenKey`, redraw-keep.ts).
    if (drawn !== null) {
      for (const node of bucket) if (!drawn.has(node.id)) out.push(node);
      continue;
    }
    const bands = bucket.map((n) => idBand(n.id)).filter((b): b is number => b !== null);
    if (bands.length < 2) continue;
    const newest = Math.max(...bands);
    if (bands.every((b) => b === newest)) continue;
    for (const node of bucket) {
      const band = idBand(node.id);
      if (band !== null && band < newest) out.push(node);
    }
  }
  return out;
}

/** 순수 — 훑은 결과를 세트별로 묶는다. */
export function classifySiblingSets(sets: readonly SiblingSet[]): OverlappingSiblingsReport {
  const groups: OverlapGroup[] = [];
  for (const s of sets) {
    let count = 0;
    let variants = 0;
    for (let i = 0; i < s.variants.length; i++) {
      const found = overlappingSiblingsOf(s.variants[i], s.drawn?.[i] ?? null).length;
      if (found > 0) {
        count += found;
        variants += 1;
      }
    }
    if (count > 0) groups.push({ set: s.set, count, variants });
  }
  return {
    setCount: sets.length,
    groups,
    count: groups.reduce((sum, g) => sum + g.count, 0),
  };
}

/** 판정이 읽는 노드의 모양 — figma `SceneNode` 가 구조적으로 들어맞고, 셀프테스트는
 *  plain 객체로 가짜 페이지를 만든다. */
export interface SiblingSceneNode {
  readonly type: string;
  readonly id: string;
  readonly name: string;
  readonly children?: readonly SiblingSceneNode[];
  getPluginData?(key: string): string;
}

function directChildren(node: SiblingSceneNode): SiblingNode[] {
  return (node.children ?? []).map((child) => ({ id: child.id, name: child.name }));
}

/** The record a redraw left on a variant, or null — absent, empty or unreadable. */
export function drawnChildrenOf(node: SiblingSceneNode): ReadonlySet<string> | null {
  let raw = '';
  try {
    raw = typeof node.getPluginData === 'function' ? node.getPluginData(kDrawnChildrenKey) : '';
  } catch {
    return null;
  }
  return raw === '' ? null : new Set(raw.split(','));
}

/**
 * 순수 — 한 페이지의 **직계** 노드에서 훑을 단위를 뽑는다.
 *
 *   - `COMPONENT_SET` → 변형마다 그 변형의 직계 자식.
 *   - `COMPONENT`(느슨한 컴포넌트) → 자기 직계 자식을 **한 변형**으로.
 *
 * 느슨한 컴포넌트를 건너뛰면 안 된다. 실제 사고 13 세트 가운데 넷(Menu ·
 * DropdownMenu · Drawer · Popover)이 느슨한 컴포넌트였고, Popover 마스터의 중복
 * `trigger` 는 그 인스턴스를 쓰는 TimePicker · Fab 으로 번졌다. 세트만 보면 번진
 * 쪽만 보이고 번진 **원인**은 안 보인다.
 */
export function siblingSetsOfPage(page: string, children: readonly SiblingSceneNode[]): SiblingSet[] {
  const out: SiblingSet[] = [];
  for (const node of children) {
    if (node.type === 'COMPONENT_SET') {
      const members = node.children ?? [];
      out.push({ set: node.name, page, variants: members.map(directChildren), drawn: members.map(drawnChildrenOf) });
    } else if (node.type === 'COMPONENT') {
      out.push({ set: node.name, page, variants: [directChildren(node)], drawn: [drawnChildrenOf(node)] });
    }
  }
  return out;
}

/** Reads the canvas. Nothing is written — no stamp, no node, no page.
 *
 *  `onlyPages` narrows the walk to those page names (Generate's tail on a
 *  component-index cache hit — the pages it loaded). Absent = every builder
 *  page (the UI button). */
export async function listOverlappingSiblings(
  onlyPages?: ReadonlySet<string>,
): Promise<OverlappingSiblingsReport> {
  const sets: SiblingSet[] = [];
  for (const page of figma.root.children) {
    // 빌더가 그리는 페이지만 — 세트가 사는 곳이다. 이름은 로드 없이 읽힌다.
    if (!page.name.startsWith(kComponentPageNamePrefix)) continue;
    if (onlyPages !== undefined && !onlyPages.has(page.name)) continue;
    // `documentAccess: dynamic-page` 는 로드되지 않은 페이지의 `.children` 을 거부한다.
    await page.loadAsync();
    sets.push(...siblingSetsOfPage(page.name, page.children));
  }
  return classifySiblingSets(sets);
}

/**
 * The log lines. Pure so the wording is testable and the UI button and the
 * Generate tail print the same sentence for the same state.
 *
 *   겹친 형제 486 / 세트 134 — MenuItem: 270 · Fab: 138 · … (+8 세트)
 * or, when nothing overlaps:
 *   겹친 형제 없음 ✅ (세트 134)
 */
export function formatOverlappingSiblings(report: OverlappingSiblingsReport): string[] {
  if (report.count === 0) return [`겹친 형제 없음 ✅ (세트 ${report.setCount})`];
  const sorted = report.groups.slice().sort((a, b) => b.count - a.count);
  const parts = sorted.map((g) => `${g.set}: ${g.count}`);
  const shown = parts.slice(0, kMaxNamesInSummary).join(' · ');
  const rest = parts.length - kMaxNamesInSummary;
  return [
    `겹친 형제 ${report.count} / 세트 ${report.setCount} — ${rest > 0 ? `${shown} · … (+${rest} 세트)` : shown}`,
    '   세기만 했다 — 같은 이름의 직계 자식이 다른 세션 대역으로 한 벌 더 있다(오래된 탭의 늦은 동기화). ' +
      '그 세트를 다시 반영하면 걷힌다',
  ];
}
