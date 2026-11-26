/// <reference types="@figma/plugin-typings" />
// 레이어에 연결되지 않은 컴포넌트 속성의 정리 — Generate 가 세트를 그린 직후 한 번.
//
// ## 왜 있는가
//
// Figma 게시 창은 어떤 레이어도 `componentPropertyReferences` 로 참조하지 않는 속성
// (BOOLEAN · TEXT · INSTANCE_SWAP)이 하나라도 있는 세트를 **아무 표시 없이** 목록에서
// 뺀다 (#5323). 새 세트는 한 번도 발행되지 않고, 발행된 세트는 그 뒤 수정이 소비
// 파일에 닿지 않는다 — 열두 세트가 그렇게 멈춰 있었고, 신호는 어디에도 없었다.
//
// 그 속성들은 빌더가 만든 것이 아니다. `defineProp` 은 더하거나 재사용할 뿐 지우지
// 않고(`identity.ts` resetNode), 재활용된 세트는 정의를 그대로 들고 있다 — 디자이너가
// 손으로 붙인 속성, 이름에 `(deprecated · …)` 를 달아 남겨 둔 속성, 빌더가 더는 그리지
// 않는 레이어의 속성이 다음 Generate 를 지나서도 남는다. 빌더 쪽 검사("정의한 것은
// 전부 결선")는 새 문서에서 구동되므로 이 잔재를 볼 수 없다.
//
// ## 무엇을 하는가
//
//   1. 판정 — 소유자가 선언한 non-VARIANT 속성 중 이번 실행의 결선 기록에 없는 것이 후보다
//      (`component-props.ts#drainUnboundProps`, 세트 크기에 비례하지 않는다).
//   2. 확인 — 후보가 있을 때만, 세트 전체 하위 트리(숨은 레이어 · 중첩 인스턴스 안쪽 포함,
//      모든 변형을 합쳐서)를 실제로 훑어 참조가 정말 없는지 본다. 한 변형이라도 참조하면
//      연결된 것이다. 결선 기록이 놓친 경로가 있어도 지우는 방향으로는 틀리지 않는다.
//   3. 제거 — 남은 후보를 `deleteComponentProperty` 로 지우고 **한 줄씩** 로그에 남긴다.
//      로그 없이 지우는 경로는 없다.
//
// 지워도 그림은 변하지 않는다: 참조하는 레이어가 없는 속성은 정의상 아무것도 움직이지 않는다.
// 소비 파일은 효과 없던 override 하나를 잃고 패널 손잡이가 사라질 뿐이다.
//
// 디자이너 사본(`(리디자인`…)은 대상이 아니다 — 작업본이다. 레지스트리 엔트리의 결과가
// 사본일 일은 없지만 이 함수가 어디서 불리든 같은 말을 하도록 이름으로도 막는다.

import { drainUnboundProps, type UnboundProp } from './component-props';
import { collectReferencedKeys, isDesignerCopyName, type PropRefNode } from './orphan-props';
import { truncatedNames } from './summary-format';

export interface UnboundSettle {
  owner: string;
  /** 지운 속성. */
  removed: UnboundProp[];
  /** 지우려 했으나 남은 것과 이유. */
  remaining: { prop: UnboundProp; why: string }[];
  /** 결선 기록에는 없었지만 실제 트리에서 참조가 발견돼 지우지 않은 것. */
  trackerMissed: UnboundProp[];
  /** 정의를 읽을 수 없어 판정하지 못했다. */
  unreadable: boolean;
}

/** `settleUnboundProps` 가 만지는 노드의 모양 — 셀프테스트가 순수 객체로 구동한다. */
export interface SettleOwner extends PropRefNode {
  readonly name: string;
  readonly componentPropertyDefinitions: Readonly<
    Record<string, { readonly type: string; readonly defaultValue?: unknown }>
  >;
  deleteComponentProperty?(propertyId: string): void;
}

/**
 * `owner` 가 선언하고 어떤 레이어도 참조하지 않는 속성을 지운다.
 * 던지지 않는다 — 속성 정리의 실패가 세트를 그린 엔트리를 실패시켜서는 안 된다.
 */
export function settleUnboundProps(owner: ComponentNode | ComponentSetNode): UnboundSettle {
  const out: UnboundSettle = {
    owner: owner.name,
    removed: [],
    remaining: [],
    trackerMissed: [],
    unreadable: false,
  };
  // 기록은 이름과 무관하게 비운다 — 다음 엔트리로 새지 않게.
  const candidates = drainUnboundProps(owner);
  if (candidates === null) {
    out.unreadable = true;
    return out;
  }
  if (candidates.length === 0) return out;

  if (isDesignerCopyName(owner.name)) {
    for (const prop of candidates) {
      out.remaining.push({ prop: prop, why: '디자이너 사본이라 건드리지 않았다' });
    }
    return out;
  }

  let referenced: Set<string>;
  try {
    referenced = collectReferencedKeys(owner as unknown as PropRefNode);
  } catch (e) {
    // 확인하지 못한 채 지우지 않는다 — 후보 전부를 남은 것으로 보고한다.
    const why = `하위 트리를 훑지 못해 지우지 않았다 (${String(e)})`;
    for (const prop of candidates) out.remaining.push({ prop: prop, why: why });
    return out;
  }

  const deletable = owner as unknown as SettleOwner;
  for (const prop of candidates) {
    if (referenced.has(prop.key)) {
      out.trackerMissed.push(prop);
      continue;
    }
    if (typeof deletable.deleteComponentProperty !== 'function') {
      out.remaining.push({ prop: prop, why: 'deleteComponentProperty 를 쓸 수 없다' });
      continue;
    }
    try {
      deletable.deleteComponentProperty(prop.key);
      out.removed.push(prop);
    } catch (e) {
      out.remaining.push({ prop: prop, why: `제거가 거부됐다 (${String(e)})` });
    }
  }
  return out;
}

/** 기본값을 로그에 쓸 모양으로 — 문자열은 따옴표, 나머지는 그대로. */
function showDefault(prop: UnboundProp): string {
  return prop.type === 'TEXT' ? JSON.stringify(prop.defaultValue) : prop.defaultValue;
}

/**
 * 로그 줄. 순수 — 문구가 테스트된다.
 *
 *   🧹 TextField: 어떤 레이어도 참조하지 않는 속성 제거 — "Show label (deprecated · FormField로 이관)" (BOOLEAN, 기본값 true)
 *   ⚠ Alert: 미연결 속성이 남았다 — "X" (TEXT): 제거가 거부됐다 (...) — 게시 창이 이 세트를 조용히 뺀다 (#5323)
 */
export function formatUnboundSettle(s: UnboundSettle): string[] {
  const lines: string[] = [];
  if (s.unreadable) {
    lines.push(
      `⚠ ${s.owner}: 속성 정의를 읽을 수 없어 미연결 속성을 판정하지 못했다 ` +
        '(중복 변형 이름이면 variant-safety 가 따로 말한다)',
    );
  }
  for (const p of s.removed) {
    lines.push(
      `🧹 ${s.owner}: 어떤 레이어도 참조하지 않는 속성 제거 — "${p.name}" ` +
        `(${p.type}, 기본값 ${showDefault(p)})`,
    );
  }
  for (const r of s.remaining) {
    lines.push(
      `⚠ ${s.owner}: 미연결 속성이 남았다 — "${r.prop.name}" (${r.prop.type}): ${r.why} — ` +
        '게시 창이 이 세트를 조용히 뺀다 (#5323)',
    );
  }
  for (const p of s.trackerMissed) {
    lines.push(
      `⚠ ${s.owner}: 결선 기록에는 없지만 레이어가 참조하는 속성 — "${p.name}" (${p.type}) ` +
        '— 지우지 않았다 (결선 기록이 놓친 경로: component-props.ts addPropRef 를 거치지 않은 쓰기)',
    );
  }
  return lines;
}

/** 한 실행 동안의 합계 — 꼬리 줄을 만든다. */
export interface UnboundTally {
  /** 속성을 하나라도 지운 세트. */
  prunedSets: string[];
  /** 지운 속성 수. */
  pruned: number;
  /** 정리 뒤에도 미연결 속성이 남았거나 판정하지 못한 세트. */
  stillUnbound: string[];
}

export function emptyUnboundTally(): UnboundTally {
  return { prunedSets: [], pruned: 0, stillUnbound: [] };
}

export function addToUnboundTally(tally: UnboundTally, s: UnboundSettle): void {
  if (s.removed.length > 0) {
    tally.prunedSets.push(s.owner);
    tally.pruned += s.removed.length;
  }
  if (s.remaining.length > 0 || s.unreadable) tally.stillUnbound.push(s.owner);
}

/**
 * 꼬리 줄 — "미연결 속성이 남은 세트" 를 센다. 게시 전에 이 수가 0 인지 눈으로 볼 수
 * 있게 하는 줄이다. 이번 실행이 **다시 그린** 세트만 안다: 해시가 같아 건너뛴 세트는
 * 읽지 않았고, 그 세트의 잔재는 "프로퍼티 orphan 보기" (라이브 캔버스 전수)가 말한다.
 *
 *   미연결 속성 정리 — 2 세트에서 7 개 제거 (TextField, TextArea) · 남은 세트 0 ✅ (기대 0)
 *   ⚠ 미연결 속성이 남은 세트 1 (기대 0) — Alert — 게시 창이 이 세트들을 조용히 뺀다
 */
export function formatUnboundTally(tally: UnboundTally, built: number): string[] {
  const lines: string[] = [];
  const removedText =
    tally.pruned > 0
      ? `${tally.prunedSets.length} 세트에서 ${tally.pruned} 개 제거 (${truncatedNames(tally.prunedSets)})`
      : '제거할 것 없음';
  if (tally.stillUnbound.length === 0) {
    lines.push(`미연결 속성 정리 — 다시 그린 ${built} 세트 중 ${removedText} · 남은 세트 0 ✅ (기대 0)`);
  } else {
    lines.push(
      `⚠ 미연결 속성이 남은 세트 ${tally.stillUnbound.length} (기대 0) — ` +
        `${truncatedNames(tally.stillUnbound)} — 게시 창이 이 세트들을 조용히 뺀다 (#5323). ` +
        `이번 실행: 다시 그린 ${built} 세트 중 ${removedText}`,
    );
  }
  return lines;
}
