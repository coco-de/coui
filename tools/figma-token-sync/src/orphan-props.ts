/// <reference types="@figma/plugin-typings" />
// 프로퍼티 orphan 보기 — 컴포넌트가 선언만 하고 어느 노드도 참조하지 않는
// 프로퍼티를 라이브 캔버스에서 센다. 읽기 전용이고 아무것도 고치지 않는다.
//
// ## 왜 있는가
//
// Properties 패널에 손잡이가 보이는데 토글해도 아무 일이 안 일어나는 상태다.
// 오류 없이 조용히 아무것도 안 하는 형태라, 발견 경로는 디자이너가 그 손잡이를
// 실제로 쓰려다 "왜 안 되지" 로 만나는 것뿐이었다 — 하루에 같은 계열 네 건이 그렇게
// 나왔다. 전수로 쟀을 때 7 개가 한 컴포넌트(FormField)에 몰려 있었다.
//
// ## 빌더 쪽 검사와 무엇이 다른가
//
// `selftest-registry-runtime` 의 props drill 이 **빌더가 만드는** orphan 은 이미
// CI 에서 막는다("is not referenced by any rendered node"). 그러나 그 그물은 빌더를
// Node 더블에 구동할 뿐 라이브 파일을 읽지 않는다. FormField 의 7 개는 빌더가 아니라
// **캔버스에 손으로 추가된** 프로퍼티였고, 그래서 CI 를 통과했다. 이 파일은 그
// 나머지 절반 — 라이브 파일을 직접 읽는 쪽이다. 두 그물은 서로를 대신하지 못한다.
//
// 캔버스는 CI 가 읽지 못하므로 ratchet baseline 을 코드에 둘 수 없다. 대신 기대값
// (`kExpectedOrphanProps`)을 로그에 싣고, 그와 다르면 `⚠` 로 시작해 로그창이 경고색이
// 된다.
//
// ## 판정
//
//   소유자 = 페이지 직계의 COMPONENT_SET 또는 COMPONENT (디자이너 사본 제외)
//   orphan = componentPropertyDefinitions 의 non-VARIANT 키 중
//            소유자 하위 트리 **전체**의 componentPropertyReferences 값 어디에도
//            나오지 않는 것
//
// 하위 트리는 중첩 인스턴스 **안쪽까지** 따라간다. 인스턴스 서브레이어의 참조는
// 대개 그 인스턴스의 메인 컴포넌트 프로퍼티를 가리키므로(키에 `#id` 가 붙어 호스트
// 키와 겹치지 않는다) 따라가도 오탐이 생기지 않고, 따라가지 않으면 참조를 놓칠 수
// 있는 쪽이 된다 — 틀리는 방향을 "orphan 이라고 잘못 말함" 이 아니라 "놓침" 쪽으로
// 둔다. 순회는 `findAll` 이 아니라 `children` 을 직접 재귀한다: 이 판정의 한 축이
// "인스턴스 안까지 가는가" 인데, `findAll` 에 맡기면 그 축을 셀프테스트가 볼 수 없다.
//
// VARIANT 는 제외한다 — 변형 축은 노드 참조가 아니라 멤버 이름으로 소비된다.
//
// `componentPropertyDefinitions` 접근은 **던질 수 있다**. 두 멤버가 같은 조합을
// 주장하면 세트가 "existing errors" 상태가 되고 그 상태에서는 모든 프로퍼티 읽기가
// 던진다(→ `variant-safety.ts` 의 `findDuplicateVariantNames`). 실측에서 Toast 가
// 그랬다. 그런 소유자는 실행을 멈추지 않고 "읽을 수 없음" 줄로 따로 센다 — 그 자체가
// 별도로 확인해야 할 결함이라 숨기지 않는다.
//
// ## 무엇을 재사용하는가
//
// 사본 낱말은 `designer-parity.ts` 가 소유하고 여기는 import 만 한다(고아 노드
// 보기와 같은 이유). 말줄임 캡은 `summary-format.ts` 하나다.
//
// Generate 꼬리에는 붙이지 않는다. 이 순회는 전 세트의 전 멤버 하위 트리(중첩 인스턴스
// 안쪽 포함)를 도는데, Generate 는 끝에서 이미 고아 노드 스캔을 하고 그 비용이
// 실측으로 추적되는 자리다. 이 질문은 "이번 실행이 흘렸나" 가 아니라 "캔버스에 손으로
// 붙은 것이 있나" 라서 실행 직후에 물을 이유도 없다.

import { kSnapshotNameWords } from './designer-parity';
import { kMaxNamesInSummary, truncatedNames } from './summary-format';

/**
 * 기대값 — 캔버스 전체의 프로퍼티 orphan 수. 0 이다: 실측의 7 개(FormField)는 빌더가
 * 그 프로퍼티들을 실제로 그리도록 구현되면서 해소됐다. 이 수가 0 이 아니게 되는 날이
 * 이 버튼이 말해야 하는 날이다.
 */
export const kExpectedOrphanProps = 0;

/** `componentPropertyReferences` 를 들 수 있고 자식을 가질 수 있는 노드. figma 타입을
 *  직접 받지 않아 셀프테스트가 순수 객체로 구동한다. */
export interface PropRefNode {
  readonly componentPropertyReferences?: Readonly<Record<string, string | undefined>> | null;
  readonly children?: readonly PropRefNode[];
}

/** 프로퍼티를 선언하는 노드 — 세트 또는 변형 축 없는 컴포넌트. */
export interface PropOwner extends PropRefNode {
  readonly name: string;
  /** 던질 수 있다 — 헤더의 "existing errors" 참조. */
  readonly componentPropertyDefinitions: Readonly<Record<string, { readonly type: string }>>;
}

export type PropOwnerVerdict =
  | { kind: 'read'; owner: string; declared: number; orphans: string[] }
  | { kind: 'unreadable'; owner: string; error: string };

export interface OrphanPropGroup {
  owner: string;
  names: string[];
}

export interface OrphanPropsReport {
  /** 정의를 읽을 수 있었던 소유자 수. */
  ownerCount: number;
  /** 그 소유자들의 non-VARIANT 프로퍼티 수. */
  propertyCount: number;
  /** orphan 이 하나 이상 있는 소유자만, 문서 순서대로. */
  groups: OrphanPropGroup[];
  /** orphan 총수 = `groups` 의 이름 수 합. */
  count: number;
  /** 정의 접근이 던진 소유자. */
  unreadable: { owner: string; error: string }[];
  /** 이름으로 걸러낸 디자이너 사본 수. */
  copiesSkipped: number;
}

/** 이 이름이 디자이너 사본인가 — 사본은 원본의 프로퍼티를 복제해 같은 orphan 을 두 번
 *  세게 만든다. 낱말은 `designer-parity.ts` 소유. */
export function isDesignerCopyName(name: string): boolean {
  return kSnapshotNameWords.some((word) => name.includes(word));
}

/** 표시용 이름 — Figma 키 `Show label#12:0` 에서 `#` 뒤 id 를 뗀다. */
export function displayPropName(key: string): string {
  const hash = key.lastIndexOf('#');
  return hash > 0 ? key.slice(0, hash) : key;
}

/**
 * `root` 자신과 모든 자손(중첩 인스턴스 안쪽 포함)이 참조하는 프로퍼티 키 전부.
 * `children` 을 직접 재귀한다 — 헤더의 "판정" 참조.
 */
export function collectReferencedKeys(root: PropRefNode): Set<string> {
  const keys = new Set<string>();
  const stack: PropRefNode[] = [root];
  while (stack.length > 0) {
    const node = stack.pop()!;
    const refs = node.componentPropertyReferences;
    if (refs) {
      for (const field of Object.keys(refs)) {
        const key = refs[field];
        if (key !== undefined) keys.add(key);
      }
    }
    const children = node.children;
    if (children) for (const child of children) stack.push(child);
  }
  return keys;
}

/** 소유자 하나를 판정한다. 무엇이 던지든 "읽을 수 없음" 으로 돌아오고 호출자를
 *  끌고 내려가지 않는다. */
export function inspectPropOwner(owner: PropOwner): PropOwnerVerdict {
  try {
    const defs = owner.componentPropertyDefinitions;
    const declared = Object.keys(defs).filter((key) => defs[key].type !== 'VARIANT');
    const referenced = collectReferencedKeys(owner);
    const orphans = declared.filter((key) => !referenced.has(key)).map(displayPropName);
    return { kind: 'read', owner: owner.name, declared: declared.length, orphans };
  } catch (e) {
    return {
      kind: 'unreadable',
      owner: owner.name,
      error: e instanceof Error ? e.message : String(e),
    };
  }
}

/** 순수 — 판정들을 한 보고로 묶는다. */
export function summarizeOrphanProps(
  verdicts: readonly PropOwnerVerdict[],
  copiesSkipped = 0,
): OrphanPropsReport {
  const groups: OrphanPropGroup[] = [];
  const unreadable: { owner: string; error: string }[] = [];
  let ownerCount = 0;
  let propertyCount = 0;
  for (const v of verdicts) {
    if (v.kind === 'unreadable') {
      unreadable.push({ owner: v.owner, error: v.error });
      continue;
    }
    ownerCount += 1;
    propertyCount += v.declared;
    if (v.orphans.length > 0) groups.push({ owner: v.owner, names: v.orphans });
  }
  return {
    ownerCount,
    propertyCount,
    groups,
    count: groups.reduce((sum, group) => sum + group.names.length, 0),
    unreadable,
    copiesSkipped,
  };
}

/** Reads the canvas. Nothing is written — no stamp, no node, no property. */
export async function listOrphanProps(): Promise<OrphanPropsReport> {
  const verdicts: PropOwnerVerdict[] = [];
  let copiesSkipped = 0;
  // 모든 페이지 — 고아 노드 보기와 달리 `❖ ` 페이지로 거르지 않는다. 찾는 것이
  // 바로 빌더 밖에서 손으로 만든 컴포넌트이기 때문이다.
  for (const page of figma.root.children) {
    // `documentAccess: dynamic-page` 는 로드되지 않은 페이지의 `.children` 을 거부한다.
    await page.loadAsync();
    for (const child of page.children) {
      if (child.type !== 'COMPONENT_SET' && child.type !== 'COMPONENT') continue;
      if (isDesignerCopyName(child.name)) {
        copiesSkipped += 1;
        continue;
      }
      verdicts.push(inspectPropOwner(child));
    }
  }
  return summarizeOrphanProps(verdicts, copiesSkipped);
}

/** 소유자 묶음을 접을 때의 꼬리 — 고아 노드 보기의 페이지 축과 같은 이유로 단위를 적는다. */
function truncatedOwners(parts: readonly string[]): string {
  const shown = parts.slice(0, kMaxNamesInSummary).join(' · ');
  const rest = parts.length - kMaxNamesInSummary;
  return rest > 0 ? `${shown} · … (+${rest} 컴포넌트)` : shown;
}

/**
 * The log lines. Pure so the wording is testable.
 *
 *   ⚠ 프로퍼티 orphan 7 (기대 0) / 컴포넌트 79 · 프로퍼티 231 — FormField: Show label, …
 * or, when nothing is dangling:
 *   프로퍼티 orphan 없음 ✅ (컴포넌트 79 · 프로퍼티 231)
 * plus, when a set could not be read at all:
 *   ⚠ 읽을 수 없는 컴포넌트 1 — Toast (…existing errors)
 *
 * 접히는 것은 나열뿐이다 — 개수는 언제나 문서 전체에 대한 참값이다.
 */
export function formatOrphanProps(report: OrphanPropsReport): string[] {
  const scope =
    `컴포넌트 ${report.ownerCount} · 프로퍼티 ${report.propertyCount}` +
    (report.copiesSkipped > 0 ? ` · 사본 ${report.copiesSkipped} 제외` : '');
  const lines: string[] = [];
  if (report.count === 0) {
    lines.push(`프로퍼티 orphan 없음 ✅ (${scope})`);
  } else {
    const parts = report.groups.map((g) => `${g.owner}: ${truncatedNames(g.names)}`);
    const tail = parts.length > 0 ? ` — ${truncatedOwners(parts)}` : '';
    lines.push(
      `⚠ 프로퍼티 orphan ${report.count} (기대 ${kExpectedOrphanProps}) / ${scope}${tail}`,
    );
  }
  if (report.unreadable.length > 0) {
    const parts = report.unreadable.map((u) => `${u.owner} (${u.error})`);
    lines.push(`⚠ 읽을 수 없는 컴포넌트 ${report.unreadable.length} — ${truncatedOwners(parts)}`);
  }
  return lines;
}
