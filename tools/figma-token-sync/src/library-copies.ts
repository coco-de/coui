/// <reference types="@figma/plugin-typings" />

// 가져온 사본 중복 (#5933) — 소비 파일이 같은 키의 라이브러리 변수를 두 번 가져와
// 사본이 둘이 된 상태. 소비 파일 점검이 「가져온 사본 중복」으로 보고하고(읽기),
// 「옛 사본 다시 연결」이 옛 사본을 참조하는 곳을 현재 사본으로 옮긴다(쓰기).
//
// ## 무엇이 문제인가
//
// 원격 변수의 id 는 `VariableID:<key>/<원본 노드 id>` 이고, 같은 키의 두 사본은 뒤의
// 원본 노드 id 만 다르다 — 2026-11-01 한 소비 파일에서 `…/7138:320` 이 옛 사본,
// `…/7817:29` 가 현재 사본이었다. 옛 사본에 묶인 레이어는 라이브러리가 바뀌어도
// 조용히 옛 값으로 남는다(그 파일에서는 상태 색 개편 #5725 전의 값). 그리고 사본이
// 둘인 동안 확장 컬렉션에서 그 변수를 덮어쓰면 `Mismatched variable type` 으로
// 거부된다 — 옛 사본도 현재 사본도. 드리프트 점검과 글자 점검은 이름으로 견주므로
// 이 상태를 보지 못한다.
//
// 플러그인은 원격 사본을 지울 수 없다(`remove()` → `Removing this node is not
// allowed`). 참조를 0 으로 만든 뒤 파일을 다시 열면 옛 사본이 정리된다(실측). 다시
// 열면 이 파일이 쓰지 않는 라이브러리 변수도 그 변수에 걸린 확장 컬렉션 덮어쓰기와
// 함께 정리되므로, 다시 연 뒤에는 「같은 이름의 로컬 토큰으로 다시 맞추기」
// (`collection-overrides.ts`)를 돌린다.
//
// ## 어느 사본이 현재 사본인가
//
// `importVariableByKeyAsync(key)` 가 돌려주는 사본이다. 같은 키의 사본이 이미 둘
// 이상인 변수에만 묻는다 — 그때 Figma 는 그중 현재 사본을 돌려준다(실측). 사본이
// 하나뿐인 변수에 물으면 라이브러리의 새 판을 이 파일로 가져오는 쓰기가 될 수 있다.
//
// ## 무엇을 참조로 세는가
//
// - 노드의 `boundVariables` 전부 — 채움 · 선 · 효과 · 격자 · 글자 구간의 채움 · 컴포넌트
//   속성 · 그 밖의 필드(모서리 · 간격 · 글자 크기 …). 숨은 노드도 센다 — 숨어도 옛
//   사본을 붙든다. 그래서 점검 범위(현재 페이지)와 상관없이 모든 페이지를 걷는다.
// - 로컬 스타일 — 채움 · 효과 · 격자 · 글자 스타일의 바인딩.
// - 로컬 별칭 — 로컬 변수의 모드 값과 확장 컬렉션의 덮어쓰기 값이 옛 사본을 가리키는 것.
//
// **인스턴스 안은 이 파일이 덮어쓴 필드만 이 파일의 참조다.** 덮어쓰지 않은 바인딩은
// 원본 컴포넌트의 것이다. 원본이 이 파일의 컴포넌트면 그 정의를 걸을 때 한 번 센다
// (인스턴스에서 또 세면 두 번이 된다). 원본이 라이브러리면 「라이브러리 컴포넌트
// 안」으로 따로 세고 다시 연결하지 않는다 — 인스턴스에서 덮어쓰면 그 레이어에
// 라이브러리 변경이 더는 닿지 않아, 이 분류가 없애려는 "조용히 옛 값" 을 다른 모양으로
// 만든다. 그 자리는 라이브러리 업데이트를 받아 옮긴다. 덮어쓴 필드인지는 사람이 놓은
// 바깥 인스턴스의 `overrides` 로 가른다 — 이 파일이 한 덮어쓰기는 거기 적히고, 안쪽
// 인스턴스의 `overrides` 에는 라이브러리 정의가 한 덮어쓰기가 섞일 수 있다.
//
// ## 보지 않는 것
//
// 그라데이션 색 지점의 바인딩은 세지도 옮기지도 않는다. 라이브러리 스타일은 이 파일이
// 고칠 수 없다.
//
// ## 순수 판정과 Figma 읽기를 나눈 이유
//
// `consumer-audit.ts` 와 같다 — 걷기(`collectNodeUses`)와 판정(`scanLibraryCopies`)은
// 노드와 조회를 주입받아 셀프테스트의 노드 더블 위에서 돈다. 문서에 쓰는 것은
// `rebindLibraryCopies` 하나다.

import { isMismatchedVariableType, mismatchedCopiesHint } from './collection-overrides';
import {
  kAuditIdsPerPage,
  type AuditGroup,
  type AuditGroupPage,
  type ConsumerAuditReport,
  type LibraryCopySummary,
} from './consumer-audit';

// ─── 모양 ────────────────────────────────────────────────────────────────────

/** 판정이 읽는 변수. 실제 `Variable` 에서 옮겨 담고, 셀프테스트는 같은 모양을 넘긴다. */
export interface CopyVariable {
  id: string;
  key: string;
  name: string;
  remote: boolean;
  resolvedType: string;
  collectionId: string;
  valuesByMode: { readonly [modeId: string]: unknown };
}

export interface CopyCollection {
  id: string;
  name: string;
  modes: readonly { modeId: string; name: string }[];
  defaultModeId: string;
  variableIds: readonly string[];
}

/** 이 파일의 확장 컬렉션. */
export interface CopyExtension {
  id: string;
  name: string;
  rootId: string;
  /** 부모에게서 물려받은 변수까지. */
  variableIds: readonly string[];
  /** `{ [변수 id]: { [확장 모드 id]: 값 } }` */
  overrides: { readonly [variableId: string]: { readonly [modeId: string]: unknown } };
}

/** 로컬 스타일 하나의 바인딩. `field` 는 채움 · 효과 · 격자 스타일이면 `paints` ·
 *  `effects` · `layoutGrids`, 글자 스타일이면 그 필드(`fontSize` …)다. */
export interface CopyStyle {
  id: string;
  name: string;
  uses: readonly { field: string; variableId: string }[];
}

/** 걷는 데 필요한 노드의 모양 — 실제 `SceneNode` 가 이 모양을 갖는다. */
export interface CopyNode {
  readonly id: string;
  readonly name: string;
  readonly type: string;
  readonly children?: readonly CopyNode[];
  readonly boundVariables?: unknown;
  readonly overrides?: readonly { id: string; overriddenFields: readonly string[] }[];
}

export interface CopyPage {
  id: string;
  name: string;
  children: readonly CopyNode[];
}

export interface CopyDeps {
  variableOf(id: string): Promise<CopyVariable | null>;
  collectionOf(id: string): Promise<CopyCollection | null>;
  /** 인스턴스의 원본이 라이브러리 것인가. 원본을 읽지 못하면 null. */
  mainOf(instance: CopyNode): Promise<{ remote: boolean } | null>;
  localVariables(): Promise<readonly CopyVariable[]>;
  extensions(): Promise<readonly CopyExtension[]>;
  localStyles(): Promise<readonly CopyStyle[]>;
  /** `importVariableByKeyAsync(key)` 가 돌려준 사본의 id. 같은 키의 사본이 둘 이상일 때만 묻는다. */
  currentCopyOf(key: string): Promise<{ id: string } | { error: string }>;
}

// ─── 참조 ────────────────────────────────────────────────────────────────────

/**
 * 변수를 참조하는 곳의 종류.
 *
 *   node        이 파일의 노드 — 다시 연결한다
 *   library     라이브러리 컴포넌트 안에서 덮어쓰지 않은 바인딩 — 옮기지 않는다
 *   style       로컬 스타일 — 다시 연결한다
 *   alias       로컬 변수의 모드 값 — 다시 연결한다
 *   override    확장 컬렉션의 덮어쓰기 값 — 다시 연결한다
 *   overridden  확장 컬렉션이 덮어쓰기를 그 변수 자체에 걸어 둔 것 — 옮길 수 없다
 */
export type CopyUseKind = 'node' | 'library' | 'style' | 'alias' | 'override' | 'overridden';

export interface CopyUse {
  variableId: string;
  kind: CopyUseKind;
  /** 다시 연결할 때 찾는 열쇠 — 노드 · 스타일 · 값을 가진 변수 · 확장 컬렉션의 id. */
  ownerId: string;
  /** 목록에 적는 이름 — 별칭 · 덮어쓰기면 그 변수나 확장 컬렉션의 이름. */
  ownerName: string;
  /** 바인딩 필드(`fills` · `cornerRadius` …) 또는 모드 id. */
  field: string;
  pageId?: string;
  pageName?: string;
}

/** 바인딩 값 안의 별칭 id 전부 — 별칭 하나 · 별칭 목록 · `{ 속성: 별칭 }`(컴포넌트 속성). */
export function aliasIds(value: unknown): string[] {
  const out: string[] = [];
  const visit = (v: unknown): void => {
    if (v == null || typeof v !== 'object') return;
    if (Array.isArray(v)) {
      for (const item of v) visit(item);
      return;
    }
    const alias = v as { type?: unknown; id?: unknown };
    if (alias.type === 'VARIABLE_ALIAS' && typeof alias.id === 'string') {
      out.push(alias.id);
      return;
    }
    for (const item of Object.values(v as Record<string, unknown>)) visit(item);
  };
  visit(value);
  return out;
}

// 인스턴스의 덮어쓰기 목록이 바인딩 필드를 부르는 이름 — 글자 구간의 채움은 `fills`,
// 서체 세 필드는 `fontName`. 나머지는 같은 이름이다.
const kOverrideFieldOf: Readonly<Record<string, string>> = {
  textRangeFills: 'fills',
  fontFamily: 'fontName',
  fontStyle: 'fontName',
  fontWeight: 'fontName',
};

/** 인스턴스 안 레이어의 바인딩 [field] 를 이 파일이 덮어썼나 — 바깥 인스턴스가 그
 *  레이어에 적은 덮어쓰기 필드로. */
export function isOverridden(field: string, overridden: readonly string[]): boolean {
  return overridden.includes('boundVariables') || overridden.includes(kOverrideFieldOf[field] ?? field);
}

interface InstanceChain {
  /** 사람이 놓은 바깥 인스턴스의 덮어쓰기 — 레이어 id → 필드. */
  overrides: ReadonlyMap<string, readonly string[]>;
  /** 거쳐 온 인스턴스 중 원본이 이 파일의 컴포넌트인 것이 있다 — 그러면 덮어쓰지
   *  않은 바인딩은 그 정의의 것이다. */
  local: boolean;
}

/** 페이지의 노드를 전부 걸어(숨은 노드 포함) 변수 바인딩을 모은다. 노드에 쓰는 것은 없다. */
export async function collectNodeUses(
  pages: readonly CopyPage[],
  deps: Pick<CopyDeps, 'mainOf'>,
): Promise<CopyUse[]> {
  const uses: CopyUse[] = [];
  const record = (node: CopyNode, chain: InstanceChain | null, page: CopyPage): void => {
    let bound: unknown;
    try {
      bound = node.boundVariables;
    } catch {
      return;
    }
    if (bound == null || typeof bound !== 'object') return;
    const overridden = chain?.overrides.get(node.id) ?? [];
    for (const [field, value] of Object.entries(bound as Record<string, unknown>)) {
      let kind: CopyUseKind = 'node';
      if (chain != null && !isOverridden(field, overridden)) {
        if (chain.local) continue; // 그 정의를 걸을 때 센다
        kind = 'library';
      }
      for (const variableId of aliasIds(value)) {
        uses.push({
          variableId,
          kind,
          ownerId: node.id,
          ownerName: node.name,
          field,
          pageId: page.id,
          pageName: page.name,
        });
      }
    }
  };
  const walk = async (node: CopyNode, chain: InstanceChain | null, page: CopyPage): Promise<void> => {
    let next = chain;
    if (node.type === 'INSTANCE') {
      if (chain == null) {
        const main = await deps.mainOf(node);
        const overrides = new Map<string, readonly string[]>();
        for (const o of node.overrides ?? []) overrides.set(o.id, o.overriddenFields);
        // 원본을 읽지 못한 인스턴스는 라이브러리 것처럼 둔다 — 건드리지 않는 쪽이다.
        next = { overrides, local: main != null && !main.remote };
      } else if (!chain.local) {
        // 라이브러리 컴포넌트의 슬롯에 바꿔 넣은 이 파일의 컴포넌트 — 그 아래는 그 정의의 것이다.
        const main = await deps.mainOf(node);
        if (main != null && !main.remote) next = { overrides: chain.overrides, local: true };
      }
    }
    record(node, next, page);
    for (const child of node.children ?? []) await walk(child, next, page);
  };
  for (const page of pages) {
    for (const child of page.children) await walk(child, null, page);
  }
  return uses;
}

/** 스타일 · 로컬 변수 · 확장 컬렉션의 참조. [candidates] 는 참조는 아니지만 이
 *  파일에 있는 원격 변수 — 확장 컬렉션과 그 원본 컬렉션의 변수 목록이다. 아무도
 *  참조하지 않는 현재 사본도 거기서 보인다. */
export async function collectDocumentUses(
  deps: Pick<CopyDeps, 'collectionOf' | 'localStyles' | 'localVariables' | 'extensions'>,
): Promise<{ uses: CopyUse[]; candidates: string[] }> {
  const uses: CopyUse[] = [];
  const candidates: string[] = [];
  for (const style of await deps.localStyles()) {
    for (const u of style.uses) {
      uses.push({ variableId: u.variableId, kind: 'style', ownerId: style.id, ownerName: style.name, field: u.field });
    }
  }
  for (const v of await deps.localVariables()) {
    if (v.remote) continue;
    for (const [modeId, value] of Object.entries(v.valuesByMode)) {
      for (const variableId of aliasIds(value)) {
        uses.push({ variableId, kind: 'alias', ownerId: v.id, ownerName: v.name, field: modeId });
      }
    }
  }
  for (const ext of await deps.extensions()) {
    for (const id of ext.variableIds) candidates.push(id);
    const root = await deps.collectionOf(ext.rootId);
    for (const id of root?.variableIds ?? []) candidates.push(id);
    for (const [variableId, modes] of Object.entries(ext.overrides)) {
      uses.push({ variableId, kind: 'overridden', ownerId: ext.id, ownerName: ext.name, field: '' });
      for (const [modeId, value] of Object.entries(modes)) {
        for (const target of aliasIds(value)) {
          uses.push({ variableId: target, kind: 'override', ownerId: variableId, ownerName: ext.name, field: modeId });
        }
      }
    }
  }
  return { uses, candidates };
}

// ─── 판정 ────────────────────────────────────────────────────────────────────

export interface CopySet {
  key: string;
  /** 같은 키의 원격 사본 — 둘 이상, id 순. */
  copies: CopyVariable[];
}

/** 같은 키의 원격 사본이 둘 이상인 라이브러리 변수. 로컬 변수는 사본이 아니다. */
export function duplicateKeys(variables: readonly CopyVariable[]): CopySet[] {
  const byKey = new Map<string, Map<string, CopyVariable>>();
  for (const v of variables) {
    if (!v.remote || v.key === '') continue;
    let copies = byKey.get(v.key);
    if (copies == null) {
      copies = new Map();
      byKey.set(v.key, copies);
    }
    copies.set(v.id, v);
  }
  const out: CopySet[] = [];
  for (const [key, copies] of byKey) {
    if (copies.size < 2) continue;
    out.push({ key, copies: [...copies.values()].sort((a, b) => a.id.localeCompare(b.id)) });
  }
  return out;
}

/** `VariableID:<key>/<원본 노드 id>` 를 나눈다. 그 모양이 아니면 null. */
export function parseRemoteVariableId(id: string): { key: string; source: string } | null {
  const m = /^VariableID:([^/]+)\/(.+)$/.exec(id);
  return m == null ? null : { key: m[1], source: m[2] };
}

/** 목록에 적는 사본의 이름 — 같은 키의 사본끼리는 뒤의 원본 노드 id 만 다르다. */
export function shortCopyId(id: string): string {
  const parsed = parseRemoteVariableId(id);
  return parsed == null ? id : `…/${parsed.source}`;
}

export function hexOf(c: { r: number; g: number; b: number; a?: number }): string {
  const h = (x: number): string =>
    Math.round(Math.max(0, Math.min(1, x)) * 255)
      .toString(16)
      .padStart(2, '0');
  const alpha = c.a == null || c.a >= 1 ? '' : h(c.a);
  return `#${h(c.r)}${h(c.g)}${h(c.b)}${alpha}`.toUpperCase();
}

/** 끝의 값(별칭이 아닌 것)을 보이는 모양으로. 색은 hex, 숫자는 넷째 자리까지 — Figma 가
 *  32비트로 저장해 되읽은 숫자는 적은 숫자와 마지막 자리가 다르다. */
export function formatCopyValue(value: unknown): string {
  if (value == null) return '(없음)';
  if (typeof value === 'number') return String(Math.round(value * 10000) / 10000);
  if (typeof value === 'boolean') return value ? 'true' : 'false';
  if (typeof value === 'string') return JSON.stringify(value);
  if (typeof value === 'object' && 'r' in value && 'g' in value && 'b' in value) {
    return hexOf(value as { r: number; g: number; b: number; a?: number });
  }
  return JSON.stringify(value);
}

function aliasOf(value: unknown): string | null {
  if (value == null || typeof value !== 'object') return null;
  const alias = value as { type?: unknown; id?: unknown };
  return alias.type === 'VARIABLE_ALIAS' && typeof alias.id === 'string' ? alias.id : null;
}

const kAliasDepth = 6;

/** 한 모드의 값 — 별칭이면 따라가서 끝의 값을. 따라간 변수의 컬렉션에 같은 이름의
 *  모드가 없으면 그 컬렉션의 기본 모드로 읽는다(Primitives 는 모드가 하나다). */
async function shownValue(
  value: unknown,
  mode: string,
  deps: Pick<CopyDeps, 'variableOf' | 'collectionOf'>,
  depth: number,
): Promise<string> {
  const id = aliasOf(value);
  if (id == null) return formatCopyValue(value);
  const target = await deps.variableOf(id);
  if (target == null) return '→ (읽지 못한 변수)';
  if (depth >= kAliasDepth) return `→ ${target.name}`;
  const collection = await deps.collectionOf(target.collectionId);
  const modeId = collection?.modes.find((m) => m.name === mode)?.modeId ?? collection?.defaultModeId;
  if (modeId == null || !(modeId in target.valuesByMode)) return `→ ${target.name}`;
  return shownValue(target.valuesByMode[modeId], mode, deps, depth + 1);
}

async function shownByModeName(
  v: CopyVariable,
  deps: Pick<CopyDeps, 'variableOf' | 'collectionOf'>,
): Promise<{ names: string[]; shown: Map<string, string> }> {
  const collection = await deps.collectionOf(v.collectionId);
  const modes = collection?.modes ?? Object.keys(v.valuesByMode).map((modeId) => ({ modeId, name: modeId }));
  const names: string[] = [];
  const shown = new Map<string, string>();
  for (const m of modes) {
    if (!(m.modeId in v.valuesByMode)) continue;
    names.push(m.name);
    shown.set(m.name, await shownValue(v.valuesByMode[m.modeId], m.name, deps, 0));
  }
  return { names, shown };
}

export interface ModeDiff {
  mode: string;
  stale: string;
  current: string;
}

/** 옛 사본과 현재 사본의 모드별 값 중 다른 것. 모드는 이름으로 맞춘다 — 두 사본의
 *  컬렉션이 같은 모드 id 를 쓴다는 보장이 없다. */
export async function modeDiffs(
  stale: CopyVariable,
  current: CopyVariable,
  deps: Pick<CopyDeps, 'variableOf' | 'collectionOf'>,
): Promise<ModeDiff[]> {
  const s = await shownByModeName(stale, deps);
  const c = await shownByModeName(current, deps);
  const out: ModeDiff[] = [];
  for (const mode of [...c.names, ...s.names.filter((n) => !c.shown.has(n))]) {
    const a = s.shown.get(mode) ?? '(없음)';
    const b = c.shown.get(mode) ?? '(없음)';
    if (a !== b) out.push({ mode, stale: a, current: b });
  }
  return out;
}

/** 옛 사본 하나. 현재 사본을 알 수 없는 키는 그 키의 사본 전부가 하나씩 나온다. */
export interface LibraryCopyFinding {
  key: string;
  /** 변수 이름 — 현재 사본의 것(모르면 첫 사본의 것). */
  name: string;
  collection: string;
  stale: string;
  current: string | null;
  currentError: string | null;
  /** 이 옛 사본을 참조하는 곳. */
  uses: CopyUse[];
  diffs: ModeDiff[];
}

export interface LibraryCopyScan {
  /** 살펴본 원격 변수(사본)의 수. */
  remoteVariables: number;
  /** 사본이 둘 이상인 키의 수. */
  keys: number;
  findings: LibraryCopyFinding[];
}

/** 파일 전체의 가져온 사본 중복. `currentCopyOf` 말고는 읽기만 한다. */
export async function scanLibraryCopies(pages: readonly CopyPage[], deps: CopyDeps): Promise<LibraryCopyScan> {
  const nodeUses = await collectNodeUses(pages, deps);
  const doc = await collectDocumentUses(deps);
  const byVariable = new Map<string, CopyUse[]>();
  for (const use of [...nodeUses, ...doc.uses]) {
    const list = byVariable.get(use.variableId);
    if (list == null) byVariable.set(use.variableId, [use]);
    else list.push(use);
  }
  const remote: CopyVariable[] = [];
  for (const id of new Set([...byVariable.keys(), ...doc.candidates])) {
    const v = await deps.variableOf(id);
    if (v != null && v.remote) remote.push(v);
  }
  const sets = duplicateKeys(remote);
  const findings: LibraryCopyFinding[] = [];
  for (const set of sets) {
    const answer = await deps.currentCopyOf(set.key);
    const currentId = 'id' in answer ? answer.id : null;
    const current =
      currentId == null ? null : (set.copies.find((c) => c.id === currentId) ?? (await deps.variableOf(currentId)));
    const named = current ?? set.copies[0];
    const collection = (await deps.collectionOf(named.collectionId))?.name ?? '';
    for (const copy of set.copies) {
      if (copy.id === currentId) continue;
      findings.push({
        key: set.key,
        name: named.name,
        collection,
        stale: copy.id,
        current: currentId,
        currentError: 'error' in answer ? answer.error : null,
        uses: byVariable.get(copy.id) ?? [],
        diffs: current == null ? [] : await modeDiffs(copy, current, deps),
      });
    }
  }
  findings.sort((a, b) => a.name.localeCompare(b.name) || a.stale.localeCompare(b.stale));
  return { remoteVariables: remote.length, keys: sets.length, findings };
}

export interface CopyCounts {
  /** 이 파일의 노드 — 다시 연결할 노드 수. */
  nodes: number;
  styles: number;
  /** 로컬 변수 · 확장 컬렉션의 별칭 — 값을 가진 변수 단위. */
  aliases: number;
  /** 라이브러리 컴포넌트 안에서 덮어쓰지 않은 바인딩 — 노드 수. */
  library: number;
  /** 덮어쓰기를 그 사본에 걸어 둔 확장 컬렉션 수. */
  overridden: number;
}

export function countUses(uses: readonly CopyUse[]): CopyCounts {
  const distinct = (kinds: readonly CopyUseKind[], keyOf: (u: CopyUse) => string): number => {
    const seen = new Set<string>();
    for (const u of uses) if (kinds.includes(u.kind)) seen.add(keyOf(u));
    return seen.size;
  };
  const owner = (u: CopyUse): string => u.ownerId;
  return {
    nodes: distinct(['node'], owner),
    styles: distinct(['style'], owner),
    aliases: distinct(['alias', 'override'], (u) => `${u.kind}\u0001${u.ownerName}\u0001${u.ownerId}`),
    library: distinct(['library'], owner),
    overridden: distinct(['overridden'], owner),
  };
}

/** 「옛 사본 다시 연결」이 옮기는 곳의 수. */
export function placesOf(c: CopyCounts): number {
  return c.nodes + c.styles + c.aliases;
}

// ─── 목록 · 문장 ─────────────────────────────────────────────────────────────

const kCopyLabel = '경고 · 가져온 사본 중복';

export function placesText(c: CopyCounts): string {
  const parts: string[] = [];
  if (c.nodes > 0) parts.push(`노드 ${c.nodes}`);
  if (c.styles > 0) parts.push(`스타일 ${c.styles}`);
  if (c.aliases > 0) parts.push(`별칭 ${c.aliases}`);
  return parts.join(' · ');
}

function diffsText(diffs: readonly ModeDiff[]): string {
  if (diffs.length === 0) return '값 차이 없음';
  return `값 차이 — ${diffs.map((d) => `${d.mode} ${d.stale} → ${d.current}`).join(' · ')}`;
}

function copyAction(f: LibraryCopyFinding, c: CopyCounts): string {
  if (f.current == null) {
    return `현재 사본을 알 수 없다(${f.currentError ?? '응답 없음'}) — CoUI 라이브러리가 켜져 있는지 확인하고 다시 점검한다`;
  }
  const places = placesOf(c);
  const notes = [
    places > 0
      ? `「옛 사본 다시 연결」로 참조 ${places}곳(${placesText(c)})을 현재 사본에 옮긴다`
      : '이 파일에는 옮길 참조가 없다',
  ];
  if (c.library > 0) {
    notes.push(`라이브러리 컴포넌트 안 ${c.library}곳은 덮어쓰지 않는다 — 라이브러리 업데이트를 받는다`);
  } else if (places === 0) {
    notes.push('파일을 다시 열면 정리된다');
  }
  if (c.overridden > 0) {
    notes.push(
      `확장 컬렉션 ${c.overridden}개가 덮어쓰기를 이 옛 사본에 걸어 두었다 — 다시 열면 사라지므로 ` +
        '연 뒤 「같은 이름의 로컬 토큰으로 다시 맞추기」를 돌린다',
    );
  }
  notes.push(diffsText(f.diffs));
  return notes.join('. ');
}

/** 옛 사본마다 목록 한 줄. 줄을 누르면 그 사본을 참조하는 이 파일의 노드를 선택한다. */
export function libraryCopyGroups(findings: readonly LibraryCopyFinding[]): AuditGroup[] {
  return findings.map((f): AuditGroup => {
    const counts = countUses(f.uses);
    const pages = new Map<string, AuditGroupPage & { idSet: Set<string> }>();
    for (const u of f.uses) {
      if (u.kind !== 'node' || u.pageId == null) continue;
      let page = pages.get(u.pageId);
      if (page == null) {
        page = { pageId: u.pageId, pageName: u.pageName ?? '', count: 0, ids: [], idSet: new Set() };
        pages.set(u.pageId, page);
      }
      if (page.idSet.has(u.ownerId)) continue;
      page.idSet.add(u.ownerId);
      page.count += 1;
      if (page.ids.length < kAuditIdsPerPage) page.ids.push(u.ownerId);
    }
    const sorted = [...pages.values()]
      .sort((a, b) => b.count - a.count)
      .map(({ pageId, pageName, count, ids }) => ({ pageId, pageName, count, ids }));
    const where = sorted.map((p) => ({ name: p.pageName, count: p.count }));
    if (counts.styles > 0) where.push({ name: '스타일', count: counts.styles });
    if (counts.aliases > 0) where.push({ name: '별칭', count: counts.aliases });
    if (counts.library > 0) where.push({ name: '라이브러리 컴포넌트 안', count: counts.library });
    return {
      category: 'library-copy',
      label: kCopyLabel,
      warn: true,
      signature: `${f.name} · 옛 사본 ${shortCopyId(f.stale)} → 현재 ${f.current == null ? '모름' : shortCopyId(f.current)}`,
      action: copyAction(f, counts),
      role: null,
      departs: [],
      runs: placesOf(counts),
      nodes: counts.nodes,
      sample: '',
      where,
      whereRest: 0,
      pages: sorted,
    };
  });
}

export function libraryCopySummary(scan: LibraryCopyScan): LibraryCopySummary {
  let places = 0;
  let library = 0;
  for (const f of scan.findings) {
    const c = countUses(f.uses);
    // 현재 사본을 모르는 사본은 다시 연결하지 않으므로 "옮기는 곳" 에 넣지 않는다.
    if (f.current != null) places += placesOf(c);
    library += c.library;
  }
  return {
    remoteVariables: scan.remoteVariables,
    keys: scan.keys,
    copies: scan.findings.length,
    places,
    library,
    error: null,
  };
}

/** 글자 점검의 보고에 「가져온 사본 중복」을 더한다 — 줄은 목록의 맨 위(경고)에. */
export function withLibraryCopies(
  report: ConsumerAuditReport,
  scan: LibraryCopyScan | { error: string },
): ConsumerAuditReport {
  if ('error' in scan) {
    return {
      ...report,
      libraryCopies: { remoteVariables: 0, keys: 0, copies: 0, places: 0, library: 0, error: scan.error },
    };
  }
  return {
    ...report,
    libraryCopies: libraryCopySummary(scan),
    groups: [...libraryCopyGroups(scan.findings), ...report.groups],
  };
}

// ─── 다시 연결 — 순수 부분 ───────────────────────────────────────────────────

/** 바인딩을 가진 항목 — 채움(`SolidPaint`) · 효과 · 격자. 그라데이션처럼 바인딩이 없는
 *  항목은 이 필드가 없다. */
interface BoundItem {
  readonly boundVariables?: { readonly [field: string]: { readonly id: string } | undefined };
}

/**
 * 항목마다 옛 사본에 묶인 필드를 현재 사본으로. Figma 의 `setBoundVariableFor*` 는 받은
 * 항목을 바꾸지 않고 **고친 사본**을 돌려주므로, 돌려받은 목록을 노드(또는 스타일)에
 * 다시 넣어야 바뀐다 — 그래서 목록을 돌려준다. [bind] 는 그 Figma 함수다.
 */
export function rebindItems<T, V>(
  items: readonly T[],
  swap: ReadonlyMap<string, V>,
  bind: (item: T, field: string, variable: V) => T,
): { list: T[]; changed: number } {
  let changed = 0;
  const list = items.map((item) => {
    let next = item;
    for (const [field, alias] of Object.entries((item as BoundItem).boundVariables ?? {})) {
      const variable = alias == null ? undefined : swap.get(alias.id);
      if (variable === undefined) continue;
      next = bind(next, field, variable);
      changed += 1;
    }
    return next;
  });
  return { list, changed };
}

/**
 * 칠 목록의 바인딩을 짝 변수로 — 단색은 칠의 `color`, 그라디언트는 정지점마다의 `color`.
 * 그라디언트의 바인딩은 칠이 아니라 정지점(`gradientStops[i].boundVariables`)에 있고,
 * 묶어 주는 도우미(`setBoundVariableForPaint`)는 단색만 받는다. 그래서 정지점은 별칭을
 * 바꾼 새 정지점으로 다시 쓴다. 받은 칠은 바꾸지 않는다(→ `rebindItems`).
 */
export function rebindPaintList<V>(
  paints: readonly Paint[],
  swap: ReadonlyMap<string, V>,
  bindSolid: (paint: Paint, field: string, variable: V) => Paint,
  aliasOf: (variable: V) => VariableAlias,
): { list: Paint[]; changed: number } {
  let changed = 0;
  const list = paints.map((paint) => {
    const stops = (paint as GradientPaint).gradientStops;
    if (!Array.isArray(stops)) {
      const r = rebindItems([paint], swap, bindSolid);
      changed += r.changed;
      return r.list[0];
    }
    let touched = false;
    const next = stops.map((stop) => {
      const current = stop.boundVariables?.color;
      const variable = current == null ? undefined : swap.get(current.id);
      if (variable === undefined) return stop;
      touched = true;
      changed += 1;
      return { ...stop, boundVariables: { ...stop.boundVariables, color: aliasOf(variable) } };
    });
    return touched ? ({ ...paint, gradientStops: next } as Paint) : paint;
  });
  return { list, changed };
}

/** [field] 에 아직 [swap] 의 옛 변수가 묶여 있나 — 쓰기 뒤 다시 읽어 실패 줄을 만든다. */
export function leftoverIds(bound: unknown, field: string, swap: ReadonlyMap<string, unknown>): string[] {
  const value = bound == null || typeof bound !== 'object' ? undefined : (bound as Record<string, unknown>)[field];
  return aliasIds(value).filter((id) => swap.has(id));
}

// ─── Figma 에 잇기 ───────────────────────────────────────────────────────────

function messageOf(e: unknown): string {
  return e instanceof Error ? e.message : String(e);
}

function copyVariableOf(v: Variable): CopyVariable {
  return {
    id: v.id,
    key: v.key,
    name: v.name,
    remote: v.remote,
    resolvedType: v.resolvedType,
    collectionId: v.variableCollectionId,
    valuesByMode: v.valuesByMode,
  };
}

function itemUses(field: string, items: readonly unknown[]): { field: string; variableId: string }[] {
  const out: { field: string; variableId: string }[] = [];
  for (const item of items) {
    for (const variableId of aliasIds((item as BoundItem).boundVariables)) out.push({ field, variableId });
  }
  return out;
}

async function readLocalStyles(): Promise<CopyStyle[]> {
  const out: CopyStyle[] = [];
  for (const s of await figma.getLocalPaintStylesAsync()) {
    out.push({ id: s.id, name: s.name, uses: itemUses('paints', s.paints) });
  }
  for (const s of await figma.getLocalEffectStylesAsync()) {
    out.push({ id: s.id, name: s.name, uses: itemUses('effects', s.effects) });
  }
  for (const s of await figma.getLocalGridStylesAsync()) {
    out.push({ id: s.id, name: s.name, uses: itemUses('layoutGrids', s.layoutGrids) });
  }
  for (const s of await figma.getLocalTextStylesAsync()) {
    const uses: { field: string; variableId: string }[] = [];
    for (const [field, alias] of Object.entries(s.boundVariables ?? {})) {
      for (const variableId of aliasIds(alias)) uses.push({ field, variableId });
    }
    out.push({ id: s.id, name: s.name, uses });
  }
  return out.filter((s) => s.uses.length > 0);
}

/** 실제 문서의 조회 — 같은 변수 · 컬렉션을 수백 번 묻는다. id 마다 한 번만 묻는다. */
export function figmaCopyDeps(): CopyDeps {
  const variables = new Map<string, Promise<CopyVariable | null>>();
  const collections = new Map<string, Promise<CopyCollection | null>>();
  return {
    variableOf(id) {
      let p = variables.get(id);
      if (p == null) {
        p = figma.variables
          .getVariableByIdAsync(id)
          .then((v) => (v == null ? null : copyVariableOf(v)))
          .catch(() => null);
        variables.set(id, p);
      }
      return p;
    },
    collectionOf(id) {
      let p = collections.get(id);
      if (p == null) {
        p = figma.variables
          .getVariableCollectionByIdAsync(id)
          .then((c) =>
            c == null
              ? null
              : {
                  id: c.id,
                  name: c.name,
                  modes: c.modes.map((m) => ({ modeId: m.modeId, name: m.name })),
                  defaultModeId: c.defaultModeId,
                  variableIds: c.variableIds.slice(),
                },
          )
          .catch(() => null);
        collections.set(id, p);
      }
      return p;
    },
    async mainOf(instance) {
      const main = await (instance as unknown as InstanceNode).getMainComponentAsync().catch(() => null);
      return main == null ? null : { remote: main.remote };
    },
    async localVariables() {
      return (await figma.variables.getLocalVariablesAsync()).map(copyVariableOf);
    },
    async extensions() {
      const out: CopyExtension[] = [];
      for (const c of await figma.variables.getLocalVariableCollectionsAsync()) {
        if (!c.isExtension) continue;
        // `isExtension` 이 런타임의 판별자다 — 타입 선언은 아직 합 타입이 아니다.
        const ext = c as unknown as ExtendedVariableCollection;
        out.push({
          id: ext.id,
          name: ext.name,
          rootId: ext.rootVariableCollectionId,
          variableIds: ext.variableIds.slice(),
          overrides: ext.variableOverrides,
        });
      }
      return out;
    },
    localStyles: readLocalStyles,
    async currentCopyOf(key) {
      try {
        return { id: (await figma.variables.importVariableByKeyAsync(key)).id };
      } catch (e) {
        return { error: messageOf(e) };
      }
    },
  };
}

// `documentAccess: dynamic-page` 는 로드되지 않은 페이지의 children 을 거부한다.
export async function loadedPages(): Promise<PageNode[]> {
  for (const page of figma.root.children) await page.loadAsync();
  return figma.root.children.slice();
}

export function asCopyPages(pages: readonly PageNode[]): CopyPage[] {
  return pages.map((p) => ({ id: p.id, name: p.name, children: p.children as unknown as CopyNode[] }));
}

/** 소비 파일 점검이 부른다. 실패해도 글자 점검은 그대로 보고되도록 오류를 돌려준다. */
export async function auditLibraryCopies(): Promise<LibraryCopyScan | { error: string }> {
  try {
    return await scanLibraryCopies(asCopyPages(await loadedPages()), figmaCopyDeps());
  } catch (e) {
    return { error: messageOf(e) };
  }
}

// ─── 다시 연결 — 명령 ────────────────────────────────────────────────────────

export interface RebindTally {
  fills: number;
  strokes: number;
  effects: number;
  layoutGrids: number;
  textFills: number;
  fields: number;
  properties: number;
  styles: number;
  aliases: number;
}

const kTallyKo: readonly [keyof RebindTally, string][] = [
  ['fills', '채움'],
  ['strokes', '선'],
  ['effects', '효과'],
  ['layoutGrids', '격자'],
  ['textFills', '글자 구간 채움'],
  ['fields', '그 밖의 필드'],
  ['properties', '컴포넌트 속성'],
  ['styles', '스타일'],
  ['aliases', '별칭'],
];

const kTextFields: ReadonlySet<string> = new Set([
  'fontFamily',
  'fontSize',
  'fontStyle',
  'fontWeight',
  'letterSpacing',
  'lineHeight',
  'paragraphSpacing',
  'paragraphIndent',
]);

/** 로그에 적는 실패 줄의 상한 — 개수는 늘 전체 수다. */
const kFailureLines = 20;

// `setBoundVariableFor*` 는 첫 인자를 바꾸지 않고 묶은 사본을 돌려준다(→ `rebindItems`).
// 칠의 도우미는 단색만 받는다 — 그라디언트 정지점은 `rebindPaints` 가 따로 다시 쓴다.
const bindPaint = (paint: Paint, field: string, v: Variable): Paint =>
  figma.variables.setBoundVariableForPaint(paint as SolidPaint, field as VariableBindablePaintField, v);
const rebindPaints = (paints: readonly Paint[], swap: ReadonlyMap<string, Variable>): { list: Paint[]; changed: number } =>
  rebindPaintList(paints, swap, bindPaint, (v) => figma.variables.createVariableAlias(v));
const bindEffect = (effect: Effect, field: string, v: Variable): Effect =>
  figma.variables.setBoundVariableForEffect(effect, field as VariableBindableEffectField, v);
const bindGrid = (grid: LayoutGrid, field: string, v: Variable): LayoutGrid =>
  figma.variables.setBoundVariableForLayoutGrid(grid, field as VariableBindableLayoutGridField, v);

/** 글자 노드를 고치기 전에 그 노드가 쓰는 글꼴을 전부 불러온다. 못 불러온 글꼴이
 *  있으면 그 이름을 돌려준다(그 노드는 건너뛴다). */
function fontLoader(): (node: TextNode) => Promise<string | null> {
  const loaded = new Set<string>();
  return async (node) => {
    const fonts: FontName[] =
      node.characters.length > 0
        ? node.getRangeAllFontNames(0, node.characters.length)
        : node.fontName === figma.mixed
          ? []
          : [node.fontName as FontName];
    for (const font of fonts) {
      const id = `${font.family}\u0001${font.style}`;
      if (loaded.has(id)) continue;
      try {
        await figma.loadFontAsync(font);
        loaded.add(id);
      } catch {
        return `${font.family} ${font.style}`;
      }
    }
    return null;
  };
}

function rebindTextRangeFills(node: TextNode, swap: ReadonlyMap<string, Variable>): number {
  let changed = 0;
  for (const seg of node.getStyledTextSegments(['fills'])) {
    const r = rebindPaints(seg.fills, swap);
    if (r.changed === 0) continue;
    node.setRangeFills(seg.start, seg.end, r.list);
    changed += r.changed;
  }
  return changed;
}

function rebindTextRangeField(node: TextNode, field: VariableBindableTextField, swap: ReadonlyMap<string, Variable>): number {
  let changed = 0;
  for (const seg of node.getStyledTextSegments(['boundVariables'])) {
    const alias = seg.boundVariables?.[field];
    const current = alias == null ? undefined : swap.get(alias.id);
    if (current == null) continue;
    node.setRangeBoundVariable(seg.start, seg.end, field, current);
    changed += 1;
  }
  if (changed > 0) return changed;
  // 글자가 비면 구간이 없다 — 바인딩은 노드에만 있으니 노드에 다시 묶는다.
  let current: Variable | undefined;
  for (const id of aliasIds((node.boundVariables as Record<string, unknown> | undefined)?.[field])) current = current ?? swap.get(id);
  if (current == null) return 0;
  node.setBoundVariable(field, current);
  return 1;
}

function rebindComponentProperties(node: InstanceNode, swap: ReadonlyMap<string, Variable>): number {
  const next: { [name: string]: VariableAlias } = {};
  for (const [name, alias] of Object.entries(node.boundVariables?.componentProperties ?? {})) {
    const current = swap.get(alias.id);
    if (current != null) next[name] = figma.variables.createVariableAlias(current);
  }
  const n = Object.keys(next).length;
  if (n > 0) node.setProperties(next);
  return n;
}

/** 노드 하나의 [fields] 에서 옛 사본을 현재 사본으로. 실패한 필드는 문장으로 돌려준다. */
async function rebindNode(
  node: SceneNode,
  fields: ReadonlySet<string>,
  swap: ReadonlyMap<string, Variable>,
  tally: RebindTally,
  loadFonts: (node: TextNode) => Promise<string | null>,
): Promise<string[]> {
  if (node.type === 'TEXT') {
    const missing = await loadFonts(node);
    if (missing != null) return [`"${node.name}" — 글꼴 ${missing} 을 불러오지 못해 건너뛰었다`];
  }
  const failures: string[] = [];
  const failed = new Set<string>();
  for (const field of fields) {
    try {
      if (field === 'fills' || field === 'strokes') {
        const paints = (node as GeometryMixin)[field];
        if (paints === figma.mixed) {
          if (node.type === 'TEXT') tally.textFills += rebindTextRangeFills(node, swap);
          continue;
        }
        const r = rebindPaints(paints as readonly Paint[], swap);
        if (r.changed === 0) continue;
        (node as GeometryMixin)[field] = r.list;
        tally[field] += r.changed;
      } else if (field === 'textRangeFills') {
        if (node.type === 'TEXT') tally.textFills += rebindTextRangeFills(node, swap);
      } else if (field === 'effects') {
        const host = node as BlendMixin;
        const r = rebindItems(host.effects, swap, bindEffect);
        if (r.changed === 0) continue;
        host.effects = r.list;
        tally.effects += r.changed;
      } else if (field === 'layoutGrids') {
        const host = node as BaseFrameMixin;
        const r = rebindItems(host.layoutGrids, swap, bindGrid);
        if (r.changed === 0) continue;
        host.layoutGrids = r.list;
        tally.layoutGrids += r.changed;
      } else if (field === 'componentProperties') {
        if (node.type === 'INSTANCE') tally.properties += rebindComponentProperties(node, swap);
      } else if (node.type === 'TEXT' && kTextFields.has(field)) {
        tally.fields += rebindTextRangeField(node, field as VariableBindableTextField, swap);
      } else {
        const bound = (node.boundVariables as Record<string, unknown> | undefined)?.[field];
        let current: Variable | undefined;
        for (const id of aliasIds(bound)) current = current ?? swap.get(id);
        if (current == null) continue;
        node.setBoundVariable(field as VariableBindableNodeField, current);
        tally.fields += 1;
      }
    } catch (e) {
      failures.push(`"${node.name}" · ${field} — ${messageOf(e)}`);
      failed.add(field);
    }
  }
  // 쓴 것을 셌다고 옮겨진 것은 아니다 — 옮길 길이 없던 필드도 여기서 자리와 함께 남긴다.
  let bound: unknown;
  try {
    bound = node.boundVariables;
  } catch {
    return failures;
  }
  for (const field of fields) {
    if (failed.has(field)) continue;
    const left = leftoverIds(bound, field, swap);
    if (left.length > 0) failures.push(`"${node.name}" (${node.id}) · ${field} — 다시 묶은 뒤에도 옛 변수 ${left.length}개가 남았다`);
  }
  return failures;
}

async function rebindStyle(
  id: string,
  fields: ReadonlySet<string>,
  swap: ReadonlyMap<string, Variable>,
  tally: RebindTally,
): Promise<string | null> {
  const style = await figma.getStyleByIdAsync(id);
  if (style == null) return `스타일 ${id} 를 찾지 못했다`;
  try {
    if (style.type === 'PAINT') {
      const s = style as PaintStyle;
      const r = rebindPaints(s.paints, swap);
      if (r.changed > 0) s.paints = r.list;
      if (r.changed > 0) tally.styles += 1;
    } else if (style.type === 'EFFECT') {
      const s = style as EffectStyle;
      const r = rebindItems(s.effects, swap, bindEffect);
      if (r.changed > 0) s.effects = r.list;
      if (r.changed > 0) tally.styles += 1;
    } else if (style.type === 'GRID') {
      const s = style as GridStyle;
      const r = rebindItems(s.layoutGrids, swap, bindGrid);
      if (r.changed > 0) s.layoutGrids = r.list;
      if (r.changed > 0) tally.styles += 1;
    } else if (style.type === 'TEXT') {
      const s = style as TextStyle;
      await figma.loadFontAsync(s.fontName);
      let changed = false;
      for (const field of fields) {
        const alias = s.boundVariables?.[field as VariableBindableTextField];
        const current = alias == null ? undefined : swap.get(alias.id);
        if (current == null) continue;
        s.setBoundVariable(field as VariableBindableTextField, current);
        changed = true;
      }
      if (changed) tally.styles += 1;
    }
  } catch (e) {
    return `스타일 "${style.name}" — ${messageOf(e)}`;
  }
  return null;
}

export interface SwapResult {
  tally: RebindTally;
  /** 옮기지 못한 자리 — 문장 하나씩. */
  failures: string[];
  /** 덮어쓰기를 그 변수에 걸지 못한 확장 컬렉션 변수(`Mismatched variable type`). */
  mismatched: Set<string>;
}

/**
 * [uses] 중 [swap] 에 든 변수를 참조하는 이 파일의 노드 · 로컬 스타일 · 로컬 별칭을 그
 * 짝 변수로 옮긴다. 「옛 사본 다시 연결」과 「옛 브랜드 컬렉션 다시 연결」
 * (`brand-collections.ts`)이 같이 쓴다 — 무엇을 무엇으로 옮기는지(swap)만 다르다.
 * `library` · `overridden` 참조는 옮기지 않는다(파일 머리). 노드는 그 페이지로 옮겨 가서
 * 고치고(`setCurrentPageAsync`), 끝나면 원래 페이지로 돌아온다.
 */
export async function applyVariableSwap(
  pages: readonly PageNode[],
  uses: readonly CopyUse[],
  swap: ReadonlyMap<string, Variable>,
): Promise<SwapResult> {
  const tally: RebindTally = {
    fills: 0,
    strokes: 0,
    effects: 0,
    layoutGrids: 0,
    textFills: 0,
    fields: 0,
    properties: 0,
    styles: 0,
    aliases: 0,
  };
  const failures: string[] = [];
  const mismatched = new Set<string>();
  const nodesByPage = new Map<string, Map<string, Set<string>>>();
  const styleFields = new Map<string, Set<string>>();
  for (const use of uses) {
    if (!swap.has(use.variableId)) continue;
    if (use.kind === 'node' && use.pageId != null) {
      let nodes = nodesByPage.get(use.pageId);
      if (nodes == null) nodesByPage.set(use.pageId, (nodes = new Map()));
      let fields = nodes.get(use.ownerId);
      if (fields == null) nodes.set(use.ownerId, (fields = new Set()));
      fields.add(use.field);
    } else if (use.kind === 'style') {
      let fields = styleFields.get(use.ownerId);
      if (fields == null) styleFields.set(use.ownerId, (fields = new Set()));
      fields.add(use.field);
    } else if (use.kind === 'alias' || use.kind === 'override') {
      // 별칭은 값을 가진 변수의 그 모드 값이다 — 확장 컬렉션의 덮어쓰기 값도 같은 호출이다.
      const owner = await figma.variables.getVariableByIdAsync(use.ownerId);
      const current = swap.get(use.variableId);
      if (owner == null || current == null) continue;
      try {
        owner.setValueForMode(use.field, figma.variables.createVariableAlias(current));
        tally.aliases += 1;
      } catch (e) {
        const message = messageOf(e);
        if (use.kind === 'override' && isMismatchedVariableType(message)) mismatched.add(owner.name);
        else failures.push(`별칭 ${use.ownerName} (${owner.name}) — ${message}`);
      }
    }
  }

  for (const [id, fields] of styleFields) {
    const failure = await rebindStyle(id, fields, swap, tally);
    if (failure != null) failures.push(failure);
  }

  const original = figma.currentPage;
  const loadFonts = fontLoader();
  try {
    for (const page of pages) {
      const nodes = nodesByPage.get(page.id);
      if (nodes == null) continue;
      await figma.setCurrentPageAsync(page);
      for (const [nodeId, fields] of nodes) {
        const node = await figma.getNodeByIdAsync(nodeId);
        if (node == null || node.type === 'PAGE' || node.type === 'DOCUMENT') {
          failures.push(`노드 ${nodeId} 를 찾지 못했다 (${page.name})`);
          continue;
        }
        for (const failure of await rebindNode(node as SceneNode, fields, swap, tally, loadFonts)) failures.push(failure);
      }
    }
  } finally {
    if (figma.currentPage.id !== original.id) await figma.setCurrentPageAsync(original);
  }
  return { tally, failures, mismatched };
}

/** 옮긴 곳의 수를 종류별로 — `채움 5 · 선 2 · …`. */
export function tallyText(tally: RebindTally): string {
  const done = kTallyKo.filter(([k]) => tally[k] > 0).map(([k, ko]) => `${ko} ${tally[k]}`);
  return done.length > 0 ? done.join(' · ') : '바꾼 곳 없음';
}

/** 실패 줄 — `kFailureLines` 줄까지, 나머지는 수만. */
export function failureLines(failures: readonly string[]): string[] {
  const out = failures.slice(0, kFailureLines).map((f) => `  ⚠ ${f}`);
  if (failures.length > kFailureLines) out.push(`  … 실패 ${failures.length - kFailureLines}줄 더`);
  return out;
}

/**
 * 「옛 사본 다시 연결」 — 파일 전체에서 옛 사본을 참조하는 이 파일의 노드 · 로컬 스타일
 * · 로컬 별칭을 현재 사본으로 옮긴다. 라이브러리 컴포넌트 안에서 덮어쓰지 않은 자리는
 * 건드리지 않는다(파일 머리). 노드는 그 페이지로 옮겨 가서 고치고(`setCurrentPageAsync`),
 * 끝나면 원래 페이지로 돌아온다. 끝에 파일을 다시 걸어 옛 사본의 참조가 남았는지 센다.
 */
export async function rebindLibraryCopies(): Promise<string[]> {
  const pages = await loadedPages();
  const before = await scanLibraryCopies(asCopyPages(pages), figmaCopyDeps());
  const log: string[] = [`옛 사본 다시 연결 — 파일 전체 (페이지 ${pages.length})`];
  if (before.findings.length === 0) {
    log.push(`가져온 사본 중복이 없다 — 옮길 것이 없다 (원격 변수 ${before.remoteVariables}개).`);
    return log;
  }

  const swap = new Map<string, Variable>();
  for (const f of before.findings) {
    const c = countUses(f.uses);
    const target = f.current == null ? '모름' : shortCopyId(f.current);
    log.push(`  ${f.name} · 옛 사본 ${shortCopyId(f.stale)} → 현재 ${target} — ${placesText(c) || '옮길 참조 없음'}`);
    if (f.current == null) {
      log.push(`  ⚠ 현재 사본을 알 수 없어 건너뛴다 — ${f.currentError ?? '응답 없음'}`);
      continue;
    }
    const current = await figma.variables.getVariableByIdAsync(f.current);
    if (current == null) {
      log.push(`  ⚠ 현재 사본 ${f.current} 을 읽지 못해 건너뛴다`);
      continue;
    }
    swap.set(f.stale, current);
  }

  const { tally, failures, mismatched } = await applyVariableSwap(
    pages,
    before.findings.filter((f) => swap.has(f.stale)).flatMap((f) => f.uses),
    swap,
  );

  log.push(`✓ 다시 연결 — ${tallyText(tally)}`);
  for (const line of failureLines(failures)) log.push(line);
  if (mismatched.size > 0) log.push(`  ⚠ ${mismatchedCopiesHint([...mismatched])}`);

  // 다시 읽어 센다 — 쓴 것을 셌다고 옮겨진 것은 아니다. 조회 캐시는 새로 만든다(값이 바뀌었다).
  const after = await scanLibraryCopies(asCopyPages(await loadedPages()), figmaCopyDeps());
  let remaining = 0;
  let library = 0;
  for (const f of after.findings) {
    if (!swap.has(f.stale)) continue;
    const c = countUses(f.uses);
    remaining += placesOf(c);
    library += c.library;
  }
  if (remaining === 0) {
    log.push('✓ 다시 읽어 확인 — 옛 사본을 참조하는 이 파일의 노드 · 스타일 · 별칭 0');
    log.push(
      '파일을 닫았다가 다시 열면 옛 사본이 정리된다. 다시 연 뒤 토큰 탭의 「같은 이름의 로컬 토큰으로 ' +
        '다시 맞추기」를 돌린다 — 다시 열면 이 파일이 쓰지 않는 라이브러리 변수가 그 덮어쓰기와 함께 정리된다.',
    );
  } else {
    log.push(
      `⚠ 다시 읽어 보니 옛 사본을 아직 ${remaining}곳이 참조한다 — 위 실패 줄의 자리를 손으로 다시 연결하고 ` +
        '점검을 다시 돌린다.',
    );
  }
  if (library > 0) {
    log.push(
      `⚠ 라이브러리 컴포넌트 안 ${library}곳은 덮어쓰지 않았다 — 덮어쓰면 그 레이어에 라이브러리 변경이 닿지 ` +
        '않는다. Assets 에서 라이브러리 업데이트를 받은 뒤 다시 점검한다. 그 자리가 옛 사본을 쓰는 동안에는 ' +
        '다시 열어도 정리되지 않을 수 있다.',
    );
  }
  return log;
}
