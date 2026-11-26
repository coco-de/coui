/// <reference types="@figma/plugin-typings" />
// 손 편집 보존 + 리디자인 대조.
//
// ## 왜 이 모듈이 있나
//
// `Generate` 는 세트를 제자리에서 다시 그린다(노드 재활용). 디자이너가 그
// 세트를 캔버스에서 직접 고쳐 둔 상태 — 리디자인은 대개 그렇게 시작한다 —
// 에서 코드가 바뀌어 그 세트가 다시 그려지면, 손 편집은 아무 흔적 없이
// 사라진다. 그래서 디자이너는 Generate 전에 세트를 통째로 복사해 옆에 두고
// 있었고, 그 복사본과 새로 그린 것을 **눈으로** 대조하고 있었다.
//
// 이 모듈은 그 두 일을 플러그인이 하게 한다.
//
// 1. **지문(fingerprint)** — 플러그인이 어떤 세트를 그리고 나면, 그 세트의
//    *보이는 값*(크기 · 패딩 · 모서리 · 채움 · 보더 · 글자 · 아이콘)을 읽어
//    해시로 노드에 남긴다. 다음 실행에서 그 세트를 다시 그리기 직전에 같은
//    값을 다시 읽어 해시가 다르면, 그 사이에 손이 닿은 것이다.
// 2. **스냅샷** — 덮어쓰기 전에 옆으로 복제한다. 복제는 인스턴스를 만들어
//    **끝까지 detach** 한 프레임이다: 컴포넌트를 복제하면 라이브러리에 같은
//    이름의 세트가 둘 생기고(발행 시 충돌), 인스턴스로 두면 원본 세트가 다시
//    그려질 때 같이 바뀌어 "이전" 을 보존하지 못한다.
//
//    **이유가 둘이고 그래서 이름도 역할도 둘이다** ([SnapshotKind]):
//    - 지문이 달라 **손 편집이 감지**되면 그 그림은 디자이너의 의도다 →
//      `<이름> (리디자인 · 시각)` 으로 남고 **아래 3 의 기준이 된다**. 그것은
//      디자이너의 작업이므로 자동으로 지우지 않는다.
//    - 지문이 없어 **판단할 수 없었으면** 그 그림은 어제의 생성본일 뿐이다 →
//      `<이름> (이전 · 시각)` 으로 남고 **대조하지 않는다**. 세트당 하나만
//      남는다 — 새 것을 뜨기 전에 같은 세트의 이전 백업을 지운다.
// 3. **대조(parity)** — 세트를 그린 뒤, 같은 페이지의 **리디자인 사본**과
//    변형 이름으로(개명표로 옛 이름을 읽은 뒤) 짝을 지어 보이는 값의 차이를
//    로그에 낸다. 기준이 되는
//    것은 두 가지뿐이다: 디자이너가 손으로 둔 `<이름>(리디자인)`(괄호 앞 공백은
//    선택, `isRedesignFrameName`), 그리고 위 2 가 손 편집을 보존한
//    `(리디자인 · 시각)` 프레임. 이 대조가 0 이 되는 것이 "캔버스대로
//    반영됐다" 의 기계적 정의다. 기준이 없으면 한 줄로 "없음" 을 말하고 끝난다.
//
// ## 백업과 대조하지 않는다 — 이유가 자격을 가른다
//
// 지문이 없어 뜬 백업은 덮어쓰기 직전의 **어제의 생성본**이다. 그것과 오늘의
// 생성본을 대조하면 나오는 것은 "코드가 어제와 얼마나 달라졌나" 이지
// "리디자인과 얼마나 다른가" 가 아니다. 실제로 사본이 없는 세트에서 대조가
// 조용히 그 백업을 집어 "192/192 다름" 을 냈고, 그 숫자는 리디자인의
// 크기였지 결함의 수가 아니었다.
//
// 그래서 판정은 **이름이 아니라 이유**로 한다. 두 스냅샷은 이름도 다르지만
// (`(리디자인 · …)` vs `(이전 · …)`) 이름은 사람이 바꿀 수 있으므로, 뜬 이유를
// 노드에 함께 남기고(`coui-snapshot-reason`) 그 값만 기준 자격을 준다. 이유를
// 알 수 없는 옛 스냅샷은 후보가 아니다 — 어느 쪽이었는지 모르는 것을 기준으로
// 쓰면 위의 거짓 숫자가 그대로 돌아온다.
//
// ## 대조는 경로가 아니라 값의 다중집합으로 한다
//
// 디자이너의 프레임과 빌더의 트리는 구조가 다르다 — 디자이너는 `trigger`
// 프레임 아래 `value` 텍스트를 두고, 빌더는 `TextField` 인스턴스 아래
// `field/input/Placeholder` 를 둔다. 경로로 짝을 지으면 전부 "없음" 이 되어
// 아무것도 말해 주지 않는다. 대신 각 변형에서 **보이는 잎**(채움이나 보더가
// 있는 박스 · 글자 · 아이콘)을 서술자 문자열로 뽑아, 변형별 다중집합의
// 대칭차를 낸다. 같은 박스가 어느 깊이에 있든 같은 서술자가 된다.
//
// 숨은 노드는 하위 트리째 빠진다: 숨은 패널 · 숨은 상태 레이어는 캔버스에
// 보이지 않으므로 "다르다" 고 말할 것이 없다. 반대로 보이는 상태 레이어의
// 불투명도, 보이는 링의 색은 서술자에 들어간다.
//
// ## 사본은 개명되지 않는다 — 짝을 짓기 전에 개명표를 읽는다
//
// 축이나 값의 이름이 바뀌면(`Enabled=false` → `State=disabled`) Generate 는
// 개명표(`VARIANT_RENAMES`)대로 **원본 세트의** 멤버 이름만 제자리에서 바꾼다 —
// 그 패스는 세트를 이름으로 찾으므로 `(리디자인)` 사본은 건드리지 않는다. 개명
// 전에 복제한 사본은 옛 이름을 그대로 들고 있고, 이름으로만 짝을 지으면 바뀐
// 변형이 전부 "리디자인에만" 과 "생성본에만" 으로 갈라져 값은 하나도 대조되지
// 않는다. 차이 수는 커지지만 그 수가 말하는 것은 이름이지 그림이 아니다.
//
// 그래서 짝을 짓기 전에 사본의 옛 이름을 같은 개명표로 새 이름으로 읽는다.
// - 생성본에 그대로 있는 이름은 옮기지 않는다 — 새 이름을 쓴 사본은 지금처럼
//   바로 짝지어진다.
// - 표를 따라가 생성본에 있는 이름에 닿을 때만 옮긴다. 표는 여러 세대를 거칠
//   수 있어(옛 세대 → 중간 → 지금) 닿을 때까지 따라가고, 닿지 못하면 옛 이름
//   그대로 "리디자인에만" 이다 — 없는 짝을 만들지 않는다.
// - 목적지를 사본의 다른 변형이 이미 차지했으면 옮기지 않고 그 사실을 적는다 —
//   한 변형을 두 그림과 동시에 대조할 수는 없다.
//
// 표로 맺은 짝은 로그와 JSON 에 옛 이름 → 새 이름으로 남는다. 짝이 이름이 아니라
// 표로 맺어졌다는 것이 보여야, 표의 행이 틀렸을 때 그 짝을 의심할 수 있다.

import { fnv1a } from './hash';
import { isSurfaceLayer, readSurfaceMaterial } from './surface-layers';
import { VARIANT_RENAMES, type VariantRename } from './renames';
import { layoutInsetWitness, layoutInsetWitnesses, matchesLayoutInsetWitness, projectLayoutInsets, type LayoutInsetWitness } from './layout-inset-projection';

export const kCanvasFingerprintKey = 'coui-canvas-fingerprint';
export const kSnapshotStampKey = 'coui-designer-snapshot';
/**
 * 스냅샷이 **왜** 떠졌는지. 이 값만 대조 기준 자격을 준다 — 이름은 사람이
 * 바꿀 수 있고, 이유를 모르는 프레임을 기준으로 쓰면 어제의 생성본과
 * 대조하게 된다.
 */
export const kSnapshotReasonKey = 'coui-snapshot-reason';
/** 손 편집을 보존한 스냅샷의 표기 — `<세트 이름> (리디자인 · 시각)`. */
export const kRedesignSnapshotMarker = ' (리디자인 · ';
/** 지문이 없어 뜬 백업의 표기 — `<세트 이름> (이전 · 시각)`. */
export const kPriorSnapshotMarker = ' (이전 · ';

/**
 * 사본 이름에 나타나는 낱말 전부 — `(리디자인 …)` · `(디자이너 …)`(옛 표기) ·
 * `(이전 · …)`. 위 두 마커와 [isRedesignFrameName] / [isPriorSnapshotName] 이
 * 받는 접두가 전부 이 중 하나를 담고 있다.
 *
 * 세트 이름을 모르는 채 "이 이름이 사본인가" 를 물어야 하는 자리가 쓴다 —
 * 고아 노드 검출(`orphan-nodes.ts`)이 그 자리다. 두 판정 함수는 `setName` 을
 * 받아 그 뒤를 보므로 재사용할 수 없고, 낱말만 뽑는 것이 최소 공유 표면이다.
 *
 * 그 자리가 낱말을 자기 파일에 다시 적으면, 표기가 하나 더 늘어나는 날
 * **디자이너의 파리티 스냅샷이 고아로 신고되고** 그건 "지우세요" 로 읽힌다.
 * `selftest-orphan-nodes` 가 이 파일의 사본 접두 리터럴을 전부 훑어 남김없이
 * 이 목록에 담기는지 단언한다.
 */
export const kSnapshotNameWords = ['리디자인', '디자이너', '이전'] as const;

/**
 * 스냅샷이 떠지는 두 이유. 이름도 역할도 갈린다.
 *
 * `hand-edit` — 지문이 달라 손 편집이 감지됐다. 그 그림은 디자이너의 의도라
 * `(리디자인 · 시각)` 으로 남고 **대조 기준이 된다**. 자동으로 지우지 않는다.
 * `prior` — 지문이 없어 판단할 수 없었다. 그 그림은 어제의 생성본일 뿐이라
 * `(이전 · 시각)` 으로 남고 **대조하지 않는다**. 세트당 하나만 남는다.
 */
export type SnapshotKind = 'hand-edit' | 'prior';

function restAfterSet(name: string, setName: string): string | null {
  if (!name.startsWith(setName)) return null;
  const rest = name.slice(setName.length);
  return rest.startsWith(' ') ? rest.slice(1) : rest;
}

/**
 * 이 이름이 `setName` 의 **리디자인 사본**인가 — 디자이너가 손으로 둔
 * `Checkbox(리디자인)`, 또는 손 편집을 보존한 `Checkbox (리디자인 · 시각)`.
 *
 * **괄호 앞 공백은 선택이다.** 사람이 손으로 붙여 넣은 사본은
 * `Checkbox(리디자인)` 처럼 붙여 적는다 — 실제로 넷 다 그렇게 두었고, 공백
 * 하나 때문에 대조가 침묵했다. 침묵한 대조는 "차이 없음" 과 화면에서
 * 구별되지 않으므로, 규약을 사람 쪽에 요구하는 대신 이쪽이 둘 다 받는다.
 *
 * 옛 표기 `(디자이너…)` 도 받는다 — 캔버스에 이미 그 이름으로 둔 사본들이
 * 있고, 표기를 바꿨다고 그것들이 조용히 후보에서 빠지면 대조가 어제까지
 * 되던 일을 오늘 안 하게 된다.
 *
 * 세트 이름은 정확히 일치해야 한다 — `Checkbox` 를 찾을 때
 * `CheckboxGroup(리디자인)` 은 남은 부분이 `Group(리디자인)` 이라 걸리지
 * 않는다. 지문 없이 뜬 백업 `Checkbox (이전 · …)` 은 **아니다** —
 * [isPriorSnapshotName].
 */
export function isRedesignFrameName(name: string, setName: string): boolean {
  const body = restAfterSet(name, setName);
  if (body == null) return false;
  return body.startsWith('(리디자인') || body.startsWith('(디자이너');
}

/**
 * 이 이름이 `setName` 의 **백업**(지문이 없어 판단할 수 없을 때 뜬 이전
 * 상태)인가. 백업은 대조 기준이 아니다 — 그것은 어제의 생성본이지
 * 리디자인의 의도가 아니다.
 */
export function isPriorSnapshotName(name: string, setName: string): boolean {
  const body = restAfterSet(name, setName);
  return body != null && body.startsWith('(이전 · ');
}

// ─── 순수 부분 — Figma 없이 검증 가능 ───────────────────────────────────

/** 변형 이름(정규화) → 그 변형의 보이는 잎 서술자(정렬됨). */
export type VariantLeaves = Record<string, string[]>;

export interface ParityDiff {
  /** 양쪽에 다 있는 변형 수. */
  compared: number;
  /** 값이 하나라도 다른 변형 이름. */
  differing: string[];
  /** 디자이너 쪽에만 있는 변형 이름. */
  onlyDesigner: string[];
  /** 생성본에만 있는 변형 이름. */
  onlyGenerated: string[];
  /** 변형별 — 디자이너에만 있는 서술자 / 생성본에만 있는 서술자. */
  lines: { variant: string; designer: string[]; generated: string[] }[];
}

/**
 * `Variant=a, State=b, Size=c` 와 `Variant=a, Size=c, State=b` 는 같은
 * 포즈다 — 축 순서는 세트마다 다시 조립되므로(빌더는 T-16 순서, 캔버스는
 * 디자이너가 적은 순서) 이름 비교는 축을 정렬한 뒤 한다.
 */
export function normalizeVariantName(name: string): string {
  const parts = name
    .split(',')
    .map((p) => p.trim())
    .filter((p) => p.length > 0);
  if (parts.length <= 1) return name.trim();
  return parts
    .map((p) => {
      const eq = p.indexOf('=');
      return eq < 0 ? p : `${p.slice(0, eq).trim()}=${p.slice(eq + 1).trim()}`;
    })
    .sort()
    .join(', ');
}

/**
 * 변형 키 — 인스턴스는 **이름이 아니라 축 값**으로 읽는다. 같은 파일 안에서
 * 세트를 복사·붙여 넣으면 멤버가 전부 INSTANCE 가 되고 그 이름은 변형이
 * 아니라 세트 이름(`Button`)이라, 이름으로 키를 잡으면 27 변형이 한 칸에
 * 겹쳐 마지막 하나만 남는다 — 대조는 "디자이너 프레임이 비었다" 로 읽힌다.
 */
export function variantKeyOf(
  name: string,
  variantProperties?: Readonly<Record<string, string>> | null,
): string {
  if (variantProperties) {
    const keys = Object.keys(variantProperties);
    if (keys.length > 0) {
      return normalizeVariantName(keys.map((k) => `${k}=${variantProperties[k]}`).join(', '));
    }
  }
  return normalizeVariantName(name);
}

/** 개명표의 한 행 — 이 세트로 이미 걸러진 것. `from` · `to` 는 표에 적힌 그대로. */
export interface ParityRename {
  from: string;
  to: string;
}

/** 개명표로 맺은 짝 — 사본의 변형 키(옛 이름) → 생성본의 변형 키(새 이름). 둘 다
 *  [normalizeVariantName] 을 거친 키다. */
export interface RenamedPair {
  from: string;
  to: string;
}

export interface CopyRenameResult {
  /** 개명을 적용한 사본의 잎. 옮긴 것도 막힌 것도 없으면 입력 객체 그대로다. */
  leaves: VariantLeaves;
  /** 옮긴 짝 — 사본 키 정렬 순. */
  renamed: RenamedPair[];
  /** 목적지를 사본의 다른 변형이 이미 차지해 옮기지 않은 짝. */
  conflicts: RenamedPair[];
}

/** 개명표에서 `setName` 의 행만. 표의 `component` 는 세트의 지금 이름이다. */
export function variantRenamesFor(
  setName: string,
  table: readonly VariantRename[] = VARIANT_RENAMES,
): ParityRename[] {
  return table.filter((r) => r.component === setName).map((r) => ({ from: r.from, to: r.to }));
}

/**
 * 사본의 옛 변형 이름을 개명표로 생성본의 이름으로 읽는다(모듈 머리말 "사본은
 * 개명되지 않는다").
 *
 * - 생성본에 그대로 있는 키는 옮기지 않는다.
 * - 표를 따라가다 생성본에 있는 키에 처음 닿는 곳이 목적지다. 닿지 못하거나
 *   표가 돌면 옮기지 않는다.
 * - 목적지가 이미 사본의 다른 변형 몫이면(직접 짝이 먼저, 그다음 키 정렬 순)
 *   옮기지 않고 `conflicts` 에 적는다.
 *
 * 축 순서만 다른 행(`Size=…, Open=…` → `Open=…, Size=…`)은 정규화하면 같은
 * 키라 아무 일도 하지 않는다.
 */
export function renameCopyVariants(
  designer: VariantLeaves,
  generated: VariantLeaves,
  renames: readonly ParityRename[],
): CopyRenameResult {
  const next = new Map<string, string>();
  for (const r of renames) {
    const from = normalizeVariantName(r.from);
    const to = normalizeVariantName(r.to);
    // 같은 키를 두 번 적은 행은 먼저 적힌 것이 이긴다 — 실행 순서대로 바꾸는
    // Generate 쪽 패스와 같은 쪽이다.
    if (from !== to && !next.has(from)) next.set(from, to);
  }
  if (next.size === 0) return { leaves: designer, renamed: [], conflicts: [] };

  const produced = new Set(Object.keys(generated));
  const keys = Object.keys(designer).sort();
  const claimed = new Set(keys.filter((k) => produced.has(k)));
  const leaves: VariantLeaves = {};
  const renamed: RenamedPair[] = [];
  const conflicts: RenamedPair[] = [];
  for (const key of keys) {
    const to = produced.has(key) ? null : renamedTarget(key, next, produced);
    if (to == null) {
      leaves[key] = designer[key];
    } else if (claimed.has(to)) {
      leaves[key] = designer[key];
      conflicts.push({ from: key, to });
    } else {
      claimed.add(to);
      leaves[to] = designer[key];
      renamed.push({ from: key, to });
    }
  }
  if (renamed.length === 0 && conflicts.length === 0) {
    return { leaves: designer, renamed, conflicts };
  }
  return { leaves, renamed, conflicts };
}

function renamedTarget(
  key: string,
  next: ReadonlyMap<string, string>,
  produced: ReadonlySet<string>,
): string | null {
  const seen = new Set<string>([key]);
  let current = next.get(key);
  while (current !== undefined) {
    if (produced.has(current)) return current;
    if (seen.has(current)) return null;
    seen.add(current);
    current = next.get(current);
  }
  return null;
}

/**
 * 개명표로 맺은 짝을 대조 블록 안에 적는 줄. 짝마다 한 줄이면 축이 바뀐 세트는
 * 수백 줄이 되므로 앞의 `cap` 개만 보이고 나머지는 수로 접는다 — 전부는 JSON 에
 * 있다. 아무것도 없으면 빈 배열이라, 개명이 없는 세트의 로그는 그대로다.
 */
export function formatRenameLines(
  renamed: readonly RenamedPair[],
  conflicts: readonly RenamedPair[],
  cap = 3,
): string[] {
  const out: string[] = [];
  if (renamed.length > 0) {
    out.push(`  ↻ 개명표로 짝지음 ${renamed.length} 변형 — 사본의 옛 이름을 지금 이름으로 읽었다`);
    for (const p of renamed.slice(0, cap)) out.push(`      ${p.from} → ${p.to}`);
    if (renamed.length > cap) out.push(`      … 외 ${renamed.length - cap} 변형`);
  }
  if (conflicts.length > 0) {
    out.push(
      `  ⚠ 개명 목적지를 사본의 다른 변형이 이미 차지해 옛 이름 그대로 둠 ${conflicts.length} 변형 — ` +
        `사본에 옛 이름과 새 이름이 함께 있다`,
    );
    for (const p of conflicts.slice(0, cap)) out.push(`      ${p.from} → ${p.to}`);
    if (conflicts.length > cap) out.push(`      … 외 ${conflicts.length - cap} 변형`);
  }
  return out;
}

export interface DesignerCandidate {
  name: string;
  /** 플러그인 스냅샷이 남긴 ISO 시각. 사람이 손으로 둔 사본은 빈 문자열. */
  stamp: string;
  /** 스냅샷이 뜬 이유(`coui-snapshot-reason`). 손 사본은 없거나 빈 문자열. */
  reason?: string;
  /** 후보가 COMPONENT_SET / COMPONENT 인가(일반 FRAME 이면 false). */
  isComponent?: boolean;
}

/**
 * 대조 기준을 고른다. 자격은 둘뿐이고 순위가 있다.
 *
 * 1. **사람이 손으로 둔 사본**(스탬프 없음) — 디자이너가 직접 만들어 둔 것.
 *    여럿이면 이름 정렬의 마지막.
 * 2. **손 편집을 보존한 스냅샷**(`reason === 'hand-edit'`) — 디자이너가 세트를
 *    직접 고쳤고 플러그인이 그 그림을 뜬 것. 여럿이면 스탬프가 최신인 것.
 *
 * 그 밖의 것은 후보가 아니다 — 지문 없이 뜬 백업(`prior`)도, 이유를 알 수
 * 없는 옛 스냅샷도. 후자를 받아 주면 그것이 백업이었을 때 어제의 생성본과
 * 대조하게 되고, 그 거짓 숫자는 리디자인의 크기처럼 보인다.
 *
 * `preferComponents`(원본이 컴포넌트 세트·컴포넌트일 때) 이고 후보 중 같은
 * 종류(`isComponent`)가 하나라도 있으면 일반 프레임은 순위에서 뺀다 — 세트 옆에
 * 둔 `X(리디자인) / 비교` 같은 비교용 그림이 이름 정렬에서 세트보다 뒤라
 * 기준으로 뽑혀 변형이 하나도 짝지어지지 않던 자리다.
 *
 * 없으면 -1.
 */
export function pickDesignerFrame(
  candidates: readonly DesignerCandidate[],
  preferComponents = false,
): number {
  let manual = -1;
  let preserved = -1;
  const sameKindExists = preferComponents && candidates.some((c) => c.isComponent === true);
  for (let i = 0; i < candidates.length; i++) {
    const c = candidates[i];
    if (sameKindExists && c.isComponent !== true) continue;
    if (c.stamp === '') {
      if (manual < 0 || c.name > candidates[manual].name) manual = i;
      continue;
    }
    if (c.reason !== 'hand-edit') continue;
    if (preserved < 0 || c.stamp > candidates[preserved].stamp) preserved = i;
  }
  return manual >= 0 ? manual : preserved;
}

// ─── 결과 봉투 — 로그는 14 줄로 접히지만 JSON 은 전부 싣는다 ─────────────
//
// 로그 상한은 사람이 읽는 창의 크기고, 결함 목록의 크기가 아니다. 192 변형
// 에서 30 종류의 차이가 나면 로그는 14 줄에서 잘리고 나머지 16 종류는 어디에도
// 남지 않는다. 그래서 같은 대조를 봉투 하나로 통째 내보낸다 — 뒤에서 이것을
// 읽는 쪽(코드로 옮기는 작업)은 잘린 로그가 아니라 이 파일을 본다.

export interface ParityFreshness {
  /** 사본 안 TEXT 노드 수. */
  textNodes: number;
  /** 그중 fontSize 또는 letterSpacing 이 변수에 바인딩된(또는 텍스트 스타일이
   *  붙은) 노드 수. */
  boundTextNodes: number;
  /** `raw-paste` = 바인딩 0 — 다른 파일에서 붙여 넣은 로우 사본이라 자간·크기
   *  축은 신뢰할 수 없다. `bound` = 하나라도 바인딩. `n/a` = 텍스트 없음/사본 없음. */
  hint: 'raw-paste' | 'bound' | 'n/a';
}

export interface ParitySetReport {
  name: string;
  page: string;
  /** 기준으로 쓴 손 사본 이름. 없으면 null — 그때 아래 수는 전부 0/빈 배열. */
  designerFrame: string | null;
  freshness: ParityFreshness;
  compared: number;
  differing: string[];
  onlyDesigner: string[];
  onlyGenerated: string[];
  /** 잎 서술자 원문 그대로 — 상한 없음. */
  lines: { variant: string; designer: string[]; generated: string[] }[];
  /** 사본은 있는데 대조하지 않은 이유(멤버가 세트 자신의 인스턴스). 대조한
   *  세트에는 없는 키다 — `designerFrame != null && compared === 0` 만으로는
   *  "변형 0 개" 와 구별되지 않아 따로 적는다. */
  skipped?: string;
  /** 개명표로 맺은 짝 — 사본의 옛 이름 → 생성본의 새 이름. 하나도 없으면 키가
   *  없다: 개명이 없는 세트의 JSON 은 이 필드가 생기기 전과 같다. */
  renamed?: RenamedPair[];
  /** 개명표가 가리키는 변형을 사본의 다른 변형이 이미 차지해 옛 이름 그대로 둔 것.
   *  하나도 없으면 키가 없다. */
  renameConflicts?: RenamedPair[];
}

export interface ParityEnvelope {
  kind: 'coui-designer-parity';
  schema: 1;
  capturedAt: string;
  fileKey: string | null;
  sourceHash: string;
  sets: ParitySetReport[];
}

export const kParityEnvelopeKind = 'coui-designer-parity';
export const kParityEnvelopeSchema = 1;

export function freshnessOf(textNodes: number, boundTextNodes: number): ParityFreshness {
  return {
    textNodes,
    boundTextNodes,
    hint: textNodes === 0 ? 'n/a' : boundTextNodes === 0 ? 'raw-paste' : 'bound',
  };
}

export const kNoFreshness: ParityFreshness = { textNodes: 0, boundTextNodes: 0, hint: 'n/a' };

/**
 * 사본 신선도 한 줄 — 로우 사본일 때만. 다른 파일에서 붙여 넣은 사본은 텍스트에
 * 변수 바인딩이 하나도 없고 자간이 0 으로 읽힌다. 디자이너는 "자간은 들어가는
 * 게 맞다" 고 했으므로, 그 사본이 내는 자간·크기 차이는 결함이 아니라 붙여넣기가
 * 잃은 값일 수 있다 — 대조 줄 옆에 그 사실을 적지 않으면 그 차이가 이슈가 된다.
 */
export function formatFreshnessLine(f: ParityFreshness): string | null {
  if (f.hint !== 'raw-paste') return null;
  return (
    `  ⚠ 사본이 로우 텍스트(변수 바인딩 ${f.boundTextNodes}/${f.textNodes}) — ` +
    `자간·크기 축의 차이는 붙여넣기에서 잃은 값일 수 있다`
  );
}

export function noDesignerCopyReport(name: string, page: string): ParitySetReport {
  return {
    name,
    page,
    designerFrame: null,
    freshness: kNoFreshness,
    compared: 0,
    differing: [],
    onlyDesigner: [],
    onlyGenerated: [],
    lines: [],
  };
}

export function formatNoDesignerCopy(name: string): string {
  return `⇄ ${name}: 리디자인 사본 없음 — 세트를 직접 고쳐 반영하거나, 같은 페이지에 "${name}(리디자인)" 을 두면 대조한다`;
}

function differenceCount(r: ParitySetReport): number {
  return r.differing.length + r.onlyDesigner.length + r.onlyGenerated.length;
}

/**
 * Generate 끝의 한 줄. 세트별 `⇄` 줄이 수십 개 흘러간 뒤 "그래서 몇 개가
 * 맞았나" 를 다시 세게 하지 않는다. 건너뛴 세트(사본이 세트 자신의 인스턴스)는
 * 대조한 것도 아니고 사본 없는 것도 아니라 있을 때만 따로 센다.
 */
export function formatParitySummary(sets: readonly ParitySetReport[]): string {
  let compared = 0;
  let clean = 0;
  let differing = 0;
  let missing = 0;
  let skipped = 0;
  let renamed = 0;
  for (const s of sets) {
    if (s.designerFrame == null) {
      missing++;
    } else if (s.skipped != null) {
      skipped++;
    } else {
      compared++;
      if (differenceCount(s) === 0) clean++;
      else differing++;
      if ((s.renamed?.length ?? 0) > 0) renamed++;
    }
  }
  return (
    `⇄ 요약: 대조 ${compared} 세트 · 차이 0 → ${clean} 세트 · 차이 있음 ${differing} 세트 · ` +
    `사본 없음 ${missing} 세트` +
    (skipped > 0 ? ` · 건너뜀 ${skipped} 세트` : '') +
    (renamed > 0 ? ` · 개명표로 짝지음 ${renamed} 세트` : '')
  );
}

export function serialiseParityEnvelope(
  sets: readonly ParitySetReport[],
  meta: { capturedAt: string; fileKey: string | null; sourceHash: string },
): string {
  const envelope: ParityEnvelope = {
    kind: kParityEnvelopeKind,
    schema: kParityEnvelopeSchema,
    capturedAt: meta.capturedAt,
    fileKey: meta.fileKey,
    sourceHash: meta.sourceHash,
    sets: sets.slice(),
  };
  return JSON.stringify(envelope, null, 2);
}

function multisetDiff(a: readonly string[], b: readonly string[]): string[] {
  const counts = new Map<string, number>();
  for (const x of b) counts.set(x, (counts.get(x) ?? 0) + 1);
  const out: string[] = [];
  for (const x of a) {
    const n = counts.get(x) ?? 0;
    if (n > 0) counts.set(x, n - 1);
    else out.push(x);
  }
  return out;
}

export function diffLeaves(designer: VariantLeaves, generated: VariantLeaves): ParityDiff {
  const dNames = Object.keys(designer).sort();
  const gNames = new Set(Object.keys(generated));
  const diff: ParityDiff = {
    compared: 0,
    differing: [],
    onlyDesigner: [],
    onlyGenerated: [],
    lines: [],
  };
  for (const name of dNames) {
    if (!gNames.has(name)) {
      diff.onlyDesigner.push(name);
      continue;
    }
    diff.compared++;
    const d = multisetDiff(designer[name], generated[name]);
    const g = multisetDiff(generated[name], designer[name]);
    if (d.length > 0 || g.length > 0) {
      diff.differing.push(name);
      diff.lines.push({ variant: name, designer: d, generated: g });
    }
  }
  for (const name of Object.keys(generated).sort()) {
    if (!(name in designer)) diff.onlyGenerated.push(name);
  }
  return diff;
}

/** 지문 — 변형 이름과 서술자를 정렬해 직렬화한 해시. 위치 · id 는 안 들어간다. */
export function fingerprintOfLeaves(leaves: VariantLeaves): string {
  const names = Object.keys(leaves).sort();
  const parts: string[] = [];
  for (const n of names) parts.push(`${n}\u0001${leaves[n].join('\u0002')}`);
  return fnv1a(parts.join('\u0003'));
}

/**
 * 같은 값 차이가 여러 변형에 반복되면(예: 모든 focus 포즈의 링 색) 한 줄로
 * 접는다 — 27 변형 × 같은 한 줄을 27 번 읽게 하지 않는다. 접힌 줄은 그
 * 차이를 가진 변형 수를 단다.
 */
export function formatParityDiff(
  name: string,
  diff: ParityDiff,
  cap = 14,
): string[] {
  const total = diff.differing.length + diff.onlyDesigner.length + diff.onlyGenerated.length;
  if (total === 0) {
    return [`⇄ ${name}: 리디자인 대조 — 차이 없음 (${diff.compared} 변형)`];
  }
  const out: string[] = [
    `⇄ ${name}: 리디자인 대조 — ${diff.differing.length} / ${diff.compared} 변형에서 값이 다름` +
      (diff.onlyDesigner.length > 0 ? ` · 리디자인에만 ${diff.onlyDesigner.length} 변형` : '') +
      (diff.onlyGenerated.length > 0 ? ` · 생성본에만 ${diff.onlyGenerated.length} 변형` : ''),
  ];
  // 접기: `designer → generated` 쌍(각각 정렬해 합친 문자열)별로 변형을 모은다.
  const folded = new Map<string, { d: string[]; g: string[]; variants: string[] }>();
  for (const l of diff.lines) {
    const key = `${l.designer.join('\u0002')}\u0001${l.generated.join('\u0002')}`;
    const f = folded.get(key);
    if (f) f.variants.push(l.variant);
    else folded.set(key, { d: l.designer, g: l.generated, variants: [l.variant] });
  }
  const groups = Array.from(folded.values()).sort((a, b) => b.variants.length - a.variants.length);
  let emitted = 0;
  for (const g of groups) {
    if (emitted >= cap) break;
    const where =
      g.variants.length === 1 ? g.variants[0] : `${g.variants[0]} 외 ${g.variants.length - 1} 변형`;
    out.push(`  · ${where}`);
    emitted++;
    for (const d of g.d) {
      if (emitted >= cap) break;
      out.push(`      리디자인: ${d}`);
      emitted++;
    }
    for (const x of g.g) {
      if (emitted >= cap) break;
      out.push(`      생성본:   ${x}`);
      emitted++;
    }
  }
  if (emitted >= cap) {
    out.push(`  … 상한 ${cap} 줄에서 잘림 — 전체 ${groups.length} 종류의 차이`);
  }
  for (const v of diff.onlyDesigner.slice(0, 3)) out.push(`  · 리디자인에만: ${v}`);
  if (diff.onlyDesigner.length > 3) out.push(`  · … 리디자인에만 ${diff.onlyDesigner.length - 3} 더`);
  for (const v of diff.onlyGenerated.slice(0, 3)) out.push(`  · 생성본에만: ${v}`);
  if (diff.onlyGenerated.length > 3) out.push(`  · … 생성본에만 ${diff.onlyGenerated.length - 3} 더`);
  return out;
}

// ─── 읽기 — 캔버스에서 잎 서술자를 뽑는다 ───────────────────────────────

type VarName = (id: string) => Promise<string>;

// #4830 — an entry's post-build designer-parity pass visits the same
// (reassembled, un-rebuilt-since) node tree up to three times — the loose
// fingerprint, the fallback `fingerprintNode`, and both halves of
// `parityReport`'s diff — and each visit re-asks `getMainComponentAsync()`
// for every INSTANCE it crosses, uncached. Between those three nothing can
// move what an instance's main-component binding resolves to (no build runs
// in between; reassembly only reparents), so the answer is safe to keep for
// the rest of that stretch of one Generate run. It is NOT safe across a
// build boundary — a build can rebind an icon slot's swap, and a cache that
// spans pre- and post-build reads of the same reused node id would hand a
// pre-build answer back after the build changed it (`generate.ts` keeps the
// pre-build fingerprint read out of the shared cache for exactly this
// reason). `generate.ts` makes one `Map` per run (never module-level — a
// stale answer from a node a DIFFERENT run rebuilt would outlive the run
// that made it) and threads it through the post-build calls. Callers that
// pass none still work — each lookup just goes straight to the API,
// uncached, as it always did.
export type MainComponentCache = Map<string, ComponentNode | null>;

async function cachedMainComponent(
  node: InstanceNode,
  cache?: MainComponentCache,
): Promise<ComponentNode | null> {
  if (!cache) return node.getMainComponentAsync();
  const hit = cache.get(node.id);
  if (hit !== undefined) return hit;
  const main = await node.getMainComponentAsync();
  cache.set(node.id, main);
  return main;
}

function half(n: number): number {
  return Math.round(n * 2) / 2;
}

function hex(c: RGB): string {
  const h = (x: number) => Math.round(x * 255).toString(16).padStart(2, '0');
  return `#${h(c.r)}${h(c.g)}${h(c.b)}`;
}

async function paintText(
  paints: readonly Paint[] | PluginAPI['mixed'],
  varName: VarName,
): Promise<string> {
  if (paints === figma.mixed) return 'mixed';
  const out: string[] = [];
  for (const p of paints) {
    if (p.visible === false) continue;
    if (p.type !== 'SOLID') {
      out.push(p.type.toLowerCase());
      continue;
    }
    const bound = p.boundVariables?.color;
    const base = bound ? await varName(bound.id) : hex(p.color);
    const op = p.opacity != null && p.opacity < 1 ? `@${Math.round(p.opacity * 100)}%` : '';
    out.push(base + op);
  }
  return out.length === 0 ? 'none' : out.join('+');
}

function isIconInstance(main: ComponentNode | null): boolean {
  if (!main) return false;
  if (main.name.startsWith('lucide/')) return true;
  const set = main.parent;
  return set != null && set.type === 'COMPONENT_SET' && set.name === 'Icon';
}

async function iconGlyph(
  node: SceneNode,
  varName: VarName,
  cache?: MainComponentCache,
): Promise<string> {
  // 글리프 이름은 안쪽 `lucide/*` 인스턴스에서, 색은 첫 보이는 벡터에서.
  let glyph = '?';
  let color = 'none';
  const stack: SceneNode[] = [node];
  while (stack.length > 0) {
    const n = stack.pop()!;
    if (n.visible === false) continue;
    if (n.type === 'INSTANCE') {
      const main = await cachedMainComponent(n, cache);
      if (main && main.name.startsWith('lucide/')) glyph = main.name.slice('lucide/'.length);
    }
    if ((n.type === 'VECTOR' || n.type === 'BOOLEAN_OPERATION') && color === 'none') {
      const s = await paintText(n.strokes, varName);
      color = s !== 'none' ? s : await paintText(n.fills, varName);
    }
    if ('children' in n) for (const c of n.children) stack.push(c);
  }
  return `icon ${glyph} ${half(node.width)} ${color}`;
}

function lineHeightText(lh: LineHeight | PluginAPI['mixed']): string {
  if (lh === figma.mixed) return 'mixed';
  if (lh.unit === 'AUTO') return 'auto';
  return `${Math.round(lh.value * 10) / 10}${lh.unit === 'PERCENT' ? '%' : 'px'}`;
}

async function collectLeaves(
  node: SceneNode,
  varName: VarName,
  out: string[],
  cache?: MainComponentCache,
  projection?: { root: SceneNode; witnesses: readonly LayoutInsetWitness[] },
): Promise<void> {
  if (node.visible === false) return;
  if (node.type === 'TEXT') {
    const fs = node.fontSize === figma.mixed ? 'mixed' : String(node.fontSize);
    const face = node.fontName === figma.mixed ? 'mixed' : node.fontName.style;
    const ls =
      node.letterSpacing === figma.mixed
        ? 'mixed'
        : `${Math.round(node.letterSpacing.value * 100) / 100}${node.letterSpacing.unit === 'PERCENT' ? '%' : ''}`;
    out.push(
      `text "${node.characters}" ${fs} ${face} lh${lineHeightText(node.lineHeight)} ls${ls} ${await paintText(node.fills, varName)}`,
    );
    return;
  }
  if (node.type === 'INSTANCE') {
    const main = await cachedMainComponent(node, cache);
    if (isIconInstance(main)) {
      out.push(await iconGlyph(node, varName, cache));
      return;
    }
  }
  if (node.type === 'VECTOR' || node.type === 'BOOLEAN_OPERATION' || node.type === 'LINE') {
    out.push(
      `vec ${half(node.width)}x${half(node.height)} ${await paintText(node.fills, varName)} / ${await paintText(node.strokes, varName)}`,
    );
    return;
  }
  // Only a counterpart in this same paired variant can witness equivalence.
  // Unknown geometry or a guard failure takes the original raw path below.
  if (projection) {
    const p = projectLayoutInsets(node);
    const key = p && p.frames.length > 1 ? await layoutInsetWitness(node, projection.root) : null;
    if (p && key != null && projection.witnesses.some((peer) => matchesLayoutInsetWitness(key, peer))) {
      if (p.padding.some((v) => v !== 0) || p.gap !== 0) {
        out.push(`layout pad${p.padding.map(half).join('/')} gap${half(p.gap)}`);
      }
      // All folded frames have no other leaves; preserve their descendants and
      // multiplicity, without writing any source-node padding or bindings.
      for (const c of p.tail.children) await collectLeaves(c, varName, out, cache, projection);
      return;
    }
  }
  // 오토레이아웃의 인셋과 간격 — 패딩은 디자이너가 가장 자주 만지는 값인데
  // 채움도 보더도 없는 프레임이 들고 있을 수 있어, 박스 서술자만으로는
  // 보이지 않는다. 0 인 것은 뺀다: 빌더와 디자이너의 래퍼 프레임 수는
  // 다르고, 패딩 0 래퍼가 하나 더 있는 것은 그림의 차이가 아니다. 크기는
  // 싣지 않는다 — 채움·보더가 있는 박스는 위 서술자가 크기를 이미 들고
  // 있고, 없는 래퍼의 크기는 그림이 아니다(디자이너의 복사본은 변형 프레임을
  // 한 높이로 고정해 두기도 하는데, 그 프레임은 아무것도 칠하지 않는다).
  if ('layoutMode' in node && node.layoutMode !== 'NONE') {
    const pad = [node.paddingTop, node.paddingRight, node.paddingBottom, node.paddingLeft];
    const gap = node.itemSpacing;
    if (pad.some((p) => p !== 0) || gap !== 0) {
      out.push(`layout pad${pad.map(half).join('/')} gap${half(gap)}`);
    }
  }
  // 재질 표면 — 채움이 `material` 자식 레이어에 있고 테두리는 노드 자신에 있다.
  // 디자이너의 복사본은 채움과 테두리가 한 노드라, 그대로 읽으면 같은 그림이
  // 상자 둘 대 하나로 갈린다. 그래서 레이어를 노드 자신의 박스에 합쳐 읽는다
  // (크기는 노드의 것, 채움은 레이어의 것). 합치면 숨는 것이 하나 있다 — 레이어가
  // 노드의 테두리를 덮어 그림에서 테두리가 사라지는 것. 그것은 값이 아니라
  // 렌더에서만 보이므로, 덮는 레이어는 자기 줄로 남겨 복사본과 다르게 읽힌다.
  const surface = 'children' in node ? readSurfaceMaterial(node) : null;
  const material =
    surface != null && 'children' in node ? (node.children[surface.index] as RectangleNode) : null;
  let fills = 'fills' in node ? await paintText(node.fills, varName) : 'none';
  let folded = false;
  if (fills === 'none' && material != null) {
    fills = await paintText(material.fills, varName);
    folded = true;
  }
  const strokes = 'strokes' in node ? await paintText(node.strokes, varName) : 'none';
  if (fills !== 'none' || strokes !== 'none') {
    const radius =
      'cornerRadius' in node
        ? node.cornerRadius === figma.mixed
          ? 'mixed'
          : String(node.cornerRadius)
        : '0';
    const sw =
      strokes !== 'none' && 'strokeWeight' in node
        ? node.strokeWeight === figma.mixed
          ? 'mixed'
          : String(node.strokeWeight)
        : '0';
    // 합친 채움은 레이어의 몫(불투명도)을 노드의 것에 곱해 읽는다.
    const opacity = ('opacity' in node ? node.opacity : 1) * (folded && material != null ? material.opacity : 1);
    const op = opacity < 1 ? ` op${Math.round(opacity * 100)}%` : '';
    out.push(
      `box ${half(node.width)}x${half(node.height)} r${radius} fill:${fills} stroke:${strokes} w${sw}${op}`,
    );
  }
  if (surface?.covers != null) out.push(surface.covers);
  if ('children' in node) {
    for (const c of node.children) {
      // 표면 자신의 레이어는 위에서 노드의 박스로 읽었다 — 따로 읽지 않는다.
      if (isSurfaceLayer(c)) continue;
      await collectLeaves(c, varName, out, cache, projection);
    }
  }
}

function makeVarName(): VarName {
  const cache = new Map<string, string>();
  return async (id) => {
    const hit = cache.get(id);
    if (hit != null) return hit;
    const v = await figma.variables.getVariableByIdAsync(id);
    const name = v ? v.name : id;
    cache.set(id, name);
    return name;
  };
}

/**
 * 세트(또는 단일 컴포넌트, 또는 스냅샷 · 손 복사본 프레임)의 변형별 잎.
 * 자식 하나가 변형 하나 — 세트의 `COMPONENT`, 스냅샷의 `FRAME`, 디자이너가
 * 붙여 넣은 `COMPONENT` 전부 같은 규칙이다. 단일 `COMPONENT` 는 자기 이름
 * 하나의 변형으로 읽는다.
 *
 * With no counterpart this remains the raw descriptor reader. The parity pass
 * supplies the opposite root plus its official rename direction, so a proven
 * additive FRAME chain can use an exact witness in the same paired variant.
 * Fingerprints use their separate collector and never this projection.
 */
export async function readVariantLeaves(
  root: ComponentSetNode | ComponentNode | FrameNode,
  cache?: MainComponentCache,
  counterpart?: {
    root: ComponentSetNode | ComponentNode | FrameNode;
    /** Maps the counterpart's keys to this root's keys. */
    renames: readonly ParityRename[];
  },
): Promise<VariantLeaves> {
  const varName = makeVarName();
  const leaves: VariantLeaves = {};
  const members: readonly SceneNode[] =
    root.type === 'COMPONENT' ? [root] : root.children;
  const peers = new Map<string, SceneNode>();
  if (counterpart) {
    try {
      const ownKeys: VariantLeaves = {};
      const peerKeys: VariantLeaves = {};
      const peerMembers = counterpart.root.type === 'COMPONENT' ? [counterpart.root] : counterpart.root.children;
      const memberKey = (m: SceneNode): string => variantKeyOf(m.name, m.type === 'INSTANCE' ? m.variantProperties : null);
      for (const m of members) ownKeys[memberKey(m)] = [];
      for (const m of peerMembers) {
        if (m.type !== 'COMPONENT' && m.type !== 'FRAME' && m.type !== 'INSTANCE') continue;
        const key = memberKey(m);
        peerKeys[key] = [];
        peers.set(key, m);
      }
      const keyed = renameCopyVariants(peerKeys, ownKeys, counterpart.renames);
      // The same rename/conflict policy as the leaf diff, never a second pairing
      // heuristic. Take the original map so chained names cannot overwrite peers.
      const originals = new Map(peers);
      for (const pair of keyed.renamed) peers.delete(pair.from);
      for (const pair of keyed.renamed) peers.set(pair.to, originals.get(pair.from)!);
    } catch {
      // Unsupported counterpart getters must not break the existing raw read.
      peers.clear();
    }
  }
  for (const m of members) {
    if (m.type !== 'COMPONENT' && m.type !== 'FRAME' && m.type !== 'INSTANCE') continue;
    // 변형 자신의 박스(채움 · 보더가 있으면)도 잎이다 — `collectLeaves` 가
    // 루트에서 시작하므로 그 박스를 포함한다.
    const out: string[] = [];
    const key = variantKeyOf(m.name, m.type === 'INSTANCE' ? m.variantProperties : null);
    const peer = peers.get(key);
    await collectLeaves(m, varName, out, cache, peer ? { root: m, witnesses: await layoutInsetWitnesses(peer) } : undefined);
    out.sort();
    leaves[variantKeyOf(m.name, m.type === 'INSTANCE' ? m.variantProperties : null)] = out;
  }
  return leaves;
}

/**
 * 이 프레임의 멤버가 대조 대상 세트 **자신의 인스턴스**인가. 그렇다면 그
 * 프레임은 마스터를 그대로 비추므로 재생성 직후 언제나 "차이 없음" 이 된다 —
 * 대조가 공허하게 초록이 되는 정확한 경우라 기준으로 쓰지 않는다. 다른
 * 세트(TextField · Icon)의 인스턴스를 끼워 넣은 것은 정상이다.
 */
async function mirrorsSet(
  frame: FrameNode | ComponentSetNode,
  setName: string,
  cache?: MainComponentCache,
): Promise<boolean> {
  for (const c of frame.children) {
    if (c.type !== 'INSTANCE') continue;
    const main = await cachedMainComponent(c, cache);
    if (!main) continue;
    const owner = main.parent && main.parent.type === 'COMPONENT_SET' ? main.parent.name : main.name;
    if (owner === setName) return true;
  }
  return false;
}

// ─── 지문 — 대조와 다른 수집기를 쓴다 ──────────────────────────────────
//
// 대조(`collectLeaves`)는 **구조가 다른 두 트리**를 견주므로 값을 느슨하게
// 뽑아야 한다. 지문은 **같은 노드를 자기 자신의 과거와** 견주므로 느슨할
// 이유가 없다 — 그림자를 바꾸거나 숨은 레이어를 고친 손 편집도 잡아야 한다.
// 그래서 수집기가 둘이다. 하나로 두면 둘 중 하나가 반드시 틀린다.
//
// **인스턴스 안은 오버라이드만 읽는다.** 지문이 인스턴스 하위로 그냥 내려가면
// 자식 세트(Icon · TextField)가 이 실행에서 먼저 다시 그려진 순간, 그것을
// 담은 부모 세트의 캔버스 값이 손이 닿지 않았는데도 움직인다 — 공유 코드가
// 바뀐 실행마다 합성 세트 전부가 "손 편집 감지" 로 스냅샷을 뜨게 된다.
// `instance.overrides` 는 "이 인스턴스가 마스터에서 무엇을 덮었는가" 라서
// 마스터가 다시 그려져도 움직이지 않고, 디자이너가 인스턴스 안을 고치면
// 정확히 그 항목이 늘어난다.
//
// **기하는 저작된 것만 싣는다.** 오토레이아웃 안에서 x · y · 크기는 패딩 ·
// 간격 · 글자 · 고정크기에서 파생되고, 그 파생값은 자식 마스터가 커지기만
// 해도 움직인다. 그래서 위치는 빼고, 크기는 `layoutSizing*` 이 `FIXED` 인
// 축만 싣는다 — 고정 크기는 파생이 아니라 누군가 정한 값이다.
//
// **변수는 이름이 아니라 id 로 싣는다.** 토큰 import 가 변수를 rename 하면
// 이름 기반 지문은 손이 닿지 않은 세트까지 통째로 움직인다.

/** 인스턴스 안에서 "이 노드의 이 필드는 덮였다" 를 나타내는 표. */
type OverrideMap = Map<string, Set<string>>;

function mergeOverrides(into: OverrideMap, instance: InstanceNode): void {
  for (const o of instance.overrides) {
    const set = into.get(o.id) ?? new Set<string>();
    for (const f of o.overriddenFields) set.add(String(f));
    into.set(o.id, set);
  }
}

function paintFingerprint(paints: readonly Paint[] | PluginAPI['mixed']): string {
  if (paints === figma.mixed) return 'mixed';
  return paints
    .map((p) => {
      const vis = p.visible === false ? '-' : '';
      const op = p.opacity != null ? `@${Math.round(p.opacity * 1000)}` : '';
      if (p.type !== 'SOLID') return `${vis}${p.type}${op}`;
      // 변수 id — rename 에 흔들리지 않는다. 미바인딩은 raw 채널.
      const bound = p.boundVariables?.color;
      const base = bound
        ? `v:${bound.id}`
        : `${Math.round(p.color.r * 1000)},${Math.round(p.color.g * 1000)},${Math.round(p.color.b * 1000)}`;
      return `${vis}${base}${op}`;
    })
    .join('|');
}

/** 한 필드의 값 — 아는 것은 값으로, 모르는 것은 필드 이름만(그래도 "여기가
 *  덮였다" 는 남는다). 값 직렬화는 마스터가 아니라 인스턴스가 든 값을 읽는다. */
function overriddenFieldValue(node: SceneNode, field: string): string {
  switch (field) {
    case 'fills':
      return 'fills' in node ? paintFingerprint(node.fills) : '?';
    case 'strokes':
      return 'strokes' in node ? paintFingerprint(node.strokes) : '?';
    case 'strokeWeight':
      return 'strokeWeight' in node ? String(node.strokeWeight) : '?';
    case 'effects':
      return 'effects' in node ? JSON.stringify(node.effects) : '?';
    case 'opacity':
      return 'opacity' in node ? String(node.opacity) : '?';
    case 'visible':
      return String(node.visible);
    case 'cornerRadius':
      return 'cornerRadius' in node ? String(node.cornerRadius) : '?';
    case 'characters':
      return node.type === 'TEXT' ? node.characters : '?';
    case 'fontSize':
      return node.type === 'TEXT' ? String(node.fontSize) : '?';
    case 'fontName':
      return node.type === 'TEXT' ? JSON.stringify(node.fontName) : '?';
    case 'lineHeight':
      return node.type === 'TEXT' ? JSON.stringify(node.lineHeight) : '?';
    case 'letterSpacing':
      return node.type === 'TEXT' ? JSON.stringify(node.letterSpacing) : '?';
    case 'textStyleId':
      return node.type === 'TEXT' ? String(node.textStyleId) : '?';
    case 'componentProperties':
      return node.type === 'INSTANCE' ? JSON.stringify(node.componentProperties) : '?';
    default:
      return '';
  }
}

function authoredSize(node: SceneNode): string {
  // `FIXED` 인 축만 — 나머지는 hug/fill 로 파생되고, 파생값은 자식 마스터가
  // 커지기만 해도 움직여 손 편집과 구별되지 않는다.
  if (!('layoutSizingHorizontal' in node)) return `${half(node.width)}x${half(node.height)}`;
  const w = node.layoutSizingHorizontal === 'FIXED' ? half(node.width) : '-';
  const h = node.layoutSizingVertical === 'FIXED' ? half(node.height) : '-';
  return `${w}x${h}`;
}

async function collectFingerprint(
  node: SceneNode,
  overrides: OverrideMap | null,
  out: string[],
  cache?: MainComponentCache,
): Promise<void> {
  if (overrides) {
    // 인스턴스 안 — 이 노드가 덮은 필드만 싣는다. 마스터가 그린 것은
    // 마스터의 지문이 책임진다.
    const fields = overrides.get(node.id);
    if (fields) {
      const parts: string[] = [];
      for (const f of Array.from(fields).sort()) parts.push(`${f}=${overriddenFieldValue(node, f)}`);
      out.push(`ovr ${node.name} ${parts.join(' ')}`);
    }
  } else {
    const bits: string[] = [`${node.type} ${node.name}`, authoredSize(node), `vis${node.visible ? 1 : 0}`];
    if ('opacity' in node && node.opacity < 1) bits.push(`op${Math.round(node.opacity * 1000)}`);
    if ('blendMode' in node && node.blendMode !== 'PASS_THROUGH') bits.push(`bl${node.blendMode}`);
    if ('cornerRadius' in node) {
      bits.push(
        node.cornerRadius === figma.mixed && 'topLeftRadius' in node
          ? `r${node.topLeftRadius}/${node.topRightRadius}/${node.bottomRightRadius}/${node.bottomLeftRadius}`
          : `r${String(node.cornerRadius)}`,
      );
    }
    if ('fills' in node) bits.push(`f${paintFingerprint(node.fills)}`);
    if ('strokes' in node) {
      bits.push(
        `s${paintFingerprint(node.strokes)}w${String(node.strokeWeight)}${node.strokeAlign}`,
      );
    }
    if ('effects' in node && node.effects.length > 0) bits.push(`e${JSON.stringify(node.effects)}`);
    if ('layoutMode' in node && node.layoutMode !== 'NONE') {
      bits.push(
        `l${node.layoutMode}p${node.paddingTop}/${node.paddingRight}/${node.paddingBottom}/${node.paddingLeft}g${node.itemSpacing}a${node.primaryAxisAlignItems}/${node.counterAxisAlignItems}`,
      );
    }
    if ('layoutPositioning' in node && node.layoutPositioning === 'ABSOLUTE') {
      bits.push(`abs${half(node.x)},${half(node.y)}`);
    }
    if (node.type === 'TEXT') {
      bits.push(
        `t"${node.characters}"${String(node.fontSize)}${JSON.stringify(node.fontName)}${JSON.stringify(node.lineHeight)}${JSON.stringify(node.letterSpacing)}${node.textAlignHorizontal}`,
      );
    }
    out.push(bits.join(' '));
  }
  if (node.type === 'INSTANCE') {
    const main = await cachedMainComponent(node, cache);
    const next: OverrideMap = overrides ? new Map(overrides) : new Map();
    mergeOverrides(next, node);
    if (!overrides) {
      out.push(
        `inst→${main ? main.name : '?'} ${JSON.stringify(node.componentProperties)}`,
      );
    }
    for (const c of node.children) await collectFingerprint(c, next, out, cache);
    return;
  }
  if ('children' in node) {
    for (const c of node.children) await collectFingerprint(c, overrides, out, cache);
  }
}

/**
 * 세트의 캔버스 지문 — 변형별로 문서 순서 그대로 직렬화한 해시.
 * 순서를 정렬하지 않는 것은 두 노드가 값을 맞바꾼 경우도 잡기 위해서다.
 */
export async function fingerprintNode(
  node: ComponentSetNode | ComponentNode,
  cache?: MainComponentCache,
): Promise<string> {
  return fingerprintMembers(node.type === 'COMPONENT' ? [node] : node.children, cache);
}

/**
 * 같은 지문을 멤버 목록으로 — 세트 안이든 페이지에 loose 로 놓여 있든.
 *
 * 수집기가 싣는 값(저작 기하 · ABSOLUTE 자식의 부모-상대 위치 · 텍스트 · 채움 ·
 * 인스턴스 오버라이드)은 멤버가 어디 있는지와 무관하고, 변형별 키는 이름이라
 * 순서도 무관하다. 그래서 generate 는 재조립 **전** 에 loose 멤버로 지문을 내고
 * 972 멤버 세트를 다시 걷지 않는다(#4802) — 세트 안 노드 읽기는 loose 보다
 * 훨씬 비싸다(#4038). 두 경로가 같은 해시를 내는 것은 하네스가 고정한다.
 */
export async function fingerprintMembers(
  members: readonly SceneNode[],
  cache?: MainComponentCache,
): Promise<string> {
  const perVariant: VariantLeaves = {};
  for (const m of members) {
    const out: string[] = [];
    await collectFingerprint(m, null, out, cache);
    // Keyed, last writer wins — the visit order here (anchor · staged · built ·
    // parked) differs from the assembled set's child order, so two members
    // normalising to one key would hash differently loose vs whole. Figma
    // refuses duplicate variant names inside a set, so the key is unique.
    perVariant[normalizeVariantName(m.name)] = out;
  }
  return fingerprintOfLeaves(perVariant);
}

// ─── 스냅샷 — 덮어쓰기 전에 옆에 복제 ───────────────────────────────────

function stampText(d: Date): string {
  const p = (n: number) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}`;
}

/**
 * 안쪽 인스턴스까지 프레임으로 푼다 — **아이콘만 빼고**. 한 단계만 detach
 * 하면 안쪽 `TextField` 인스턴스는 그 마스터를 계속 가리키고, 마스터가 다시
 * 그려지는 순간 스냅샷도 같이 바뀐다("이전" 을 보존하지 못한다).
 *
 * 아이콘을 남기는 이유는 대조가 그것을 다르게 읽기 때문이다. `collectLeaves`
 * 는 아이콘 인스턴스를 `icon <글리프> <크기> <색>` 한 줄로 접는데, detach 하면
 * 그 인스턴스가 프레임이 되어 같은 글리프가 `vec …` 여러 줄로 풀린다 — 그러면
 * 스냅샷과 새 그림은 **아무것도 바뀌지 않아도 전 변형이 다르다**고 나오고,
 * "0 차이 = 캔버스대로" 라는 이 기능의 정의가 아이콘을 가진 세트(사실상 전부)
 * 에서 도달 불가능해진다. 아이콘 마스터가 나중에 다시 그려져도 글리프 · 크기 ·
 * 색 오버라이드는 그대로라 스냅샷의 그 줄은 움직이지 않는다.
 */
async function detachDeep(node: SceneNode, cache?: MainComponentCache): Promise<SceneNode> {
  let current: SceneNode = node;
  if (current.type === 'INSTANCE') {
    if (isIconInstance(await cachedMainComponent(current, cache))) return current;
    try {
      current = current.detachInstance();
    } catch {
      // 원격 라이브러리 인스턴스처럼 풀 수 없는 것은 인스턴스로 남긴다 —
      // 그 하나 때문에 스냅샷 전체를 포기하는 것보다 낫다.
      return current;
    }
  }
  if ('children' in current) {
    // detach 는 자식 배열을 바꾸므로 스냅샷을 떠서 돈다.
    for (const c of current.children.slice()) await detachDeep(c, cache);
  }
  return current;
}

export interface SnapshotResult {
  node: FrameNode;
  members: number;
  /** 이번 스냅샷이 대체하며 지운 이전 스냅샷 수. */
  replaced: number;
}

/** 스냅샷 이름 — 이유가 표기를 정한다 ([SnapshotKind]). */
export function snapshotName(setName: string, kind: SnapshotKind, now: Date): string {
  const marker = kind === 'hand-edit' ? kRedesignSnapshotMarker : kPriorSnapshotMarker;
  return `${setName}${marker}${stampText(now)})`;
}

/** `<세트 이름> (이전 · YYYY-MM-DD HH:mm)` — 지문 없이 뜬 백업. */
export function priorSnapshotName(setName: string, now: Date): string {
  return snapshotName(setName, 'prior', now);
}

/** `<세트 이름> (리디자인 · YYYY-MM-DD HH:mm)` — 손 편집을 보존한 스냅샷. */
export function redesignSnapshotName(setName: string, now: Date): string {
  return snapshotName(setName, 'hand-edit', now);
}

/**
 * 이 프레임이 **새 스냅샷이 대체해도 되는 백업**인가.
 *
 * 백업(`prior`)만 대체 대상이다 — 그것은 어제의 생성본이라 더 최근의 것이
 * 생기면 값이 없다. 손 편집을 보존한 스냅샷은 **절대 지우지 않는다**: 그것은
 * 디자이너가 실제로 그린 것이고, 자동으로 지우면 이 모듈이 막으려던 그
 * 사고(손 편집이 흔적 없이 사라짐)를 이 모듈이 저지르게 된다.
 *
 * 이유를 알 수 없는 옛 스냅샷도 지우지 않는다 — 손 편집이었을 수 있다.
 */
export function isReplaceablePrior(
  node: Pick<SceneNode, 'name'> & { getPluginData(key: string): string },
  setName: string,
): boolean {
  if (isPriorSnapshotName(node.name, setName)) return true;
  return (
    isRedesignFrameName(node.name, setName) &&
    node.getPluginData(kSnapshotStampKey) !== '' &&
    node.getPluginData(kSnapshotReasonKey) === 'prior'
  );
}

/**
 * 세트 오른쪽에 스냅샷 프레임을 만든다. 멤버는 세트 안 상대 위치를 그대로
 * 갖는다(격자가 보존되어 나란히 놓고 볼 수 있다).
 *
 * 이름과 역할은 `kind` 가 정한다 ([SnapshotKind]) — 손 편집을 보존한 것은
 * `(리디자인 · 시각)` 으로 대조 기준이 되고, 지문 없이 뜬 백업은
 * `(이전 · 시각)` 으로 대조에서 빠진다.
 *
 * **백업은 세트당 하나만 남는다** — 실행마다 하나씩 쌓이면 페이지가 백업으로
 * 덮이고, 그중 어느 것이 "직전" 인지 이름의 시각을 읽어야 안다. 백업의 목적은
 * 직전 상태 하나를 되찾는 것이고, 그보다 오래된 것은 버전 히스토리가 든다.
 * 반면 손 편집 스냅샷은 지우지 않는다 — [isReplaceablePrior].
 */
export async function snapshotBeforeOverwrite(
  set: ComponentSetNode | ComponentNode,
  page: PageNode,
  kind: SnapshotKind,
  now: Date = new Date(),
  cache?: MainComponentCache,
): Promise<SnapshotResult> {
  let replaced = 0;
  for (const c of page.children.slice()) {
    if (c === set || !isReplaceablePrior(c, set.name)) continue;
    c.remove();
    replaced++;
  }
  const frame = figma.createFrame();
  frame.name = snapshotName(set.name, kind, now);
  frame.fills = [];
  frame.clipsContent = false;
  page.appendChild(frame);
  frame.x = set.x + set.width + 80;
  frame.y = set.y;
  frame.resize(Math.max(1, set.width), Math.max(1, set.height));
  const members: readonly ComponentNode[] =
    set.type === 'COMPONENT' ? [set] : (set.children.filter((c) => c.type === 'COMPONENT') as ComponentNode[]);
  let count = 0;
  for (const m of members) {
    const inst = m.createInstance();
    frame.appendChild(inst);
    const detached = await detachDeep(inst, cache);
    detached.name = m.name;
    detached.x = set.type === 'COMPONENT' ? 0 : m.x;
    detached.y = set.type === 'COMPONENT' ? 0 : m.y;
    count++;
  }
  frame.setPluginData(kSnapshotStampKey, now.toISOString());
  frame.setPluginData(kSnapshotReasonKey, kind);
  return { node: frame, members: count, replaced };
}

type DesignerFrame = FrameNode | ComponentSetNode;

/**
 * 같은 페이지의 **리디자인 사본** 후보들과, 그중 기준으로 고른 것. 자격은
 * 사람이 둔 사본과 손 편집을 보존한 스냅샷 둘뿐이다 — 백업과 이유 불명은
 * 목록에도 들어가지 않는다 ([pickDesignerFrame]).
 */
export function findDesignerFrames(
  page: PageNode,
  setName: string,
  preferComponents = false,
): { chosen: DesignerFrame | null; all: DesignerFrame[]; skippedFrames: DesignerFrame[] } {
  const all: DesignerFrame[] = [];
  const candidates: DesignerCandidate[] = [];
  for (const c of page.children) {
    if (c.type !== 'FRAME' && c.type !== 'COMPONENT_SET') continue;
    if (isPriorSnapshotName(c.name, setName)) continue;
    if (!isRedesignFrameName(c.name, setName)) continue;
    const stamp = c.getPluginData(kSnapshotStampKey);
    const reason = c.getPluginData(kSnapshotReasonKey);
    if (stamp !== '' && reason !== 'hand-edit') continue;
    all.push(c);
    candidates.push({ name: c.name, stamp, reason, isComponent: c.type === 'COMPONENT_SET' });
  }
  const idx = pickDesignerFrame(candidates, preferComponents);
  const chosen = idx >= 0 ? all[idx] : null;
  // 같은 종류 후보가 있어 순위에서 빠진 일반 프레임 — 로그에 이유를 남긴다.
  const skippedFrames =
    preferComponents && candidates.some((c) => c.isComponent === true)
      ? all.filter((f) => f.type !== 'COMPONENT_SET')
      : [];
  return { chosen, all, skippedFrames };
}

/**
 * 사본 안 TEXT 노드 중 fontSize/letterSpacing 이 변수에 바인딩된(또는 텍스트
 * 스타일이 붙은) 것을 센다. 다른 파일에서 붙여 넣은 사본은 이것이 0 이라
 * 자간이 0 으로 읽힌다 — 그 축의 차이는 붙여넣기가 잃은 값이지 디자인 결정이
 * 아닐 수 있다.
 */
function readFreshness(root: DesignerFrame): ParityFreshness {
  let textNodes = 0;
  let bound = 0;
  const stack: SceneNode[] = [root];
  while (stack.length > 0) {
    const n = stack.pop()!;
    if (n.type === 'TEXT') {
      textNodes++;
      const bv = n.boundVariables;
      const fontSize = bv?.fontSize;
      const letterSpacing = bv?.letterSpacing;
      const hasVar =
        (fontSize != null && fontSize.length > 0) ||
        (letterSpacing != null && letterSpacing.length > 0);
      const hasStyle = n.textStyleId !== figma.mixed && n.textStyleId !== '';
      if (hasVar || hasStyle) bound++;
      continue;
    }
    if ('children' in n) for (const c of n.children) stack.push(c);
  }
  return freshnessOf(textNodes, bound);
}

export interface ParityResult {
  lines: string[];
  report: ParitySetReport;
}

/**
 * 세트와 그 디자이너 손 사본을 대조해 로그 줄(상한 있음)과 전체 결과(상한
 * 없음)를 함께 돌려준다. 사본이 없으면 그 사실을 한 줄로 말한다 — 침묵은
 * "차이 없음" 과 화면에서 구별되지 않는다.
 *
 * 짝을 짓기 전에 사본의 옛 변형 이름을 `renameTable` 로 읽는다
 * ([renameCopyVariants]). 기본값은 Generate 가 원본 세트에 적용하는 바로 그 표다 —
 * 두 쪽이 다른 표를 읽으면 원본은 개명되고 사본은 짝을 잃는다.
 */
export async function parityReport(
  set: ComponentSetNode | ComponentNode,
  page: PageNode,
  cache?: MainComponentCache,
  renameTable: readonly VariantRename[] = VARIANT_RENAMES,
): Promise<ParityResult> {
  const { chosen, all, skippedFrames } = findDesignerFrames(page, set.name, true);
  if (!chosen) {
    return {
      lines: [formatNoDesignerCopy(set.name)],
      report: noDesignerCopyReport(set.name, page.name),
    };
  }
  const freshness = readFreshness(chosen);
  // 멤버가 이 세트 자신의 인스턴스면 마스터를 그대로 비추므로 재생성 직후
  // 언제나 "차이 없음" 이다 — 초록이 아무것도 뜻하지 않게 되는 자리라
  // 대조하지 않고 그 이유를 적는다.
  if (await mirrorsSet(chosen, set.name, cache)) {
    const skipped =
      `"${chosen.name}" 의 멤버가 이 세트의 인스턴스라 언제나 같게 나온다. ` +
      `그 프레임을 선택해 detach 하세요(우클릭 → Detach instance).`;
    return {
      lines: [`⇄ ${set.name}: 대조 건너뜀 — ${skipped}`],
      report: {
        ...noDesignerCopyReport(set.name, page.name),
        designerFrame: chosen.name,
        freshness,
        skipped,
      },
    };
  }
  const renames = variantRenamesFor(set.name, renameTable);
  const d = await readVariantLeaves(chosen, cache, {
    root: set, renames: renames.map((r) => ({ from: r.to, to: r.from })),
  });
  const g = await readVariantLeaves(set, cache, { root: chosen, renames });
  const keyed = renameCopyVariants(d, g, renames);
  const diff = diffLeaves(keyed.leaves, g);
  const lines = formatParityDiff(set.name, diff);
  const others = all
    .filter((f) => f !== chosen)
    .map((f) => (skippedFrames.includes(f) ? `"${f.name}" 비교용 프레임으로 건너뜀` : `"${f.name}"`));
  lines[0] =
    `${lines[0]} — 기준 "${chosen.name}"` +
    (others.length > 0 ? ` (다른 후보 ${others.length}: ${others.slice(0, 3).join(', ')})` : '');
  const notes: string[] = [];
  const freshnessLine = formatFreshnessLine(freshness);
  if (freshnessLine != null) notes.push(freshnessLine);
  notes.push(...formatRenameLines(keyed.renamed, keyed.conflicts));
  lines.splice(1, 0, ...notes);
  return {
    lines,
    report: {
      name: set.name,
      page: page.name,
      designerFrame: chosen.name,
      freshness,
      compared: diff.compared,
      differing: diff.differing,
      onlyDesigner: diff.onlyDesigner,
      onlyGenerated: diff.onlyGenerated,
      lines: diff.lines,
      ...(keyed.renamed.length > 0 ? { renamed: keyed.renamed } : {}),
      ...(keyed.conflicts.length > 0 ? { renameConflicts: keyed.conflicts } : {}),
    },
  };
}

/** 로그 줄만 필요한 호출자를 위한 얇은 래퍼. */
export async function parityLog(
  set: ComponentSetNode | ComponentNode,
  page: PageNode,
  cache?: MainComponentCache,
): Promise<string[]> {
  return (await parityReport(set, page, cache)).lines;
}
