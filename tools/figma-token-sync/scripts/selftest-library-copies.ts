/// <reference types="@figma/plugin-typings" />

// Self-test for src/library-copies.ts — 「가져온 사본 중복」(소비 파일 점검의 분류)과
// 「옛 사본 다시 연결」(#5933).
//
// 캔버스 없이 틀릴 수 있는 것 다섯:
//
//   1. **무엇을 이 파일의 참조로 세는가.** 인스턴스 안은 바깥 인스턴스가 덮어쓴
//      필드만 이 파일의 것이다. 덮어쓰지 않은 바인딩은 원본이 이 파일의 컴포넌트면
//      그 정의에서 한 번(인스턴스에서 또 세면 두 번), 원본이 라이브러리면 「라이브러리
//      컴포넌트 안」으로 따로 — 그리고 그 자리는 옮기지 않는다. 숨은 노드도 센다.
//   2. **현재 사본을 묻는 것은 같은 키의 사본이 이미 둘 이상인 변수에만.** 사본이 하나뿐인
//      변수에 `importVariableByKeyAsync` 를 부르면 문서에 쓰는 일이 될 수 있다.
//   3. **새 항목을 다시 넣는가.** `setBoundVariableForPaint` · `…ForEffect` 는 받은 것을
//      바꾸지 않고 묶은 사본을 돌려준다. 더블도 그렇게 해서, 돌려받은 목록을 노드에
//      다시 넣지 않으면 아무것도 옮겨지지 않은 채 끝난다.
//   4. **페이지 · 글꼴.** 노드는 그 페이지가 현재 페이지일 때만 고쳐지고(`setCurrentPageAsync`
//      — 더블은 다른 페이지의 노드에 쓰면 던진다), 글자 노드는 그 글꼴을 불러온 뒤에만
//      고쳐진다(더블은 그 전에 쓰면 던진다).
//   5. **배선.** 버튼 · 핸들러 · 메시지 · 비활성 목록 · 위치 · selftest 체인.
//
// 세계는 2026-11-01 한 소비 파일에서 잰 모양을 따른다 — 원격 변수 id 는
// `VariableID:<key>/<원본 노드 id>`, 같은 키의 두 사본은 뒤의 id 만 다르고(`…/7138:320`
// 옛 · `…/7817:29` 현재), 확장 컬렉션의 변수 목록에 두 사본이 함께 있다.

import { buildConsumerAuditReport, formatConsumerAudit } from '../src/consumer-audit';
import {
  aliasIds,
  applyVariableSwap,
  auditLibraryCopies,
  duplicateKeys,
  formatCopyValue,
  isOverridden,
  parseRemoteVariableId,
  leftoverIds,
  rebindItems,
  rebindLibraryCopies,
  rebindPaintList,
  shortCopyId,
  withLibraryCopies,
  type CopyVariable,
  type LibraryCopyScan,
} from '../src/library-copies';

declare const process: { exit(code: number): never; cwd(): string };
declare function require(m: string): unknown;
const { readFileSync } = require('fs') as { readFileSync(p: string, enc: string): string };
const { join } = require('path') as { join(...parts: string[]): string };

let failures = 0;

function check(label: string, fn: () => void | Promise<void>): Promise<void> {
  return Promise.resolve()
    .then(fn)
    .then(
      () => console.log(`  ok  ${label}`),
      (e) => {
        failures++;
        console.error(`FAIL  ${label}\n      ${String(e)}`);
      },
    );
}

function assert(cond: boolean, msg: string): void {
  if (!cond) throw new Error(msg);
}

function assertEq<T>(actual: T, expected: T, what: string): void {
  const a = JSON.stringify(actual);
  const b = JSON.stringify(expected);
  if (a !== b) throw new Error(`${what}: expected ${b}, got ${a}`);
}

function read(rel: string): string {
  return readFileSync(join(process.cwd(), rel), 'utf8');
}

function codeLines(src: string): string {
  return src
    .split('\n')
    .filter((l) => !/^\s*(\/\/|\*|\/\*)/.test(l))
    .join('\n');
}

// ── 세계 ─────────────────────────────────────────────────────────────────────

type Any = any; // eslint-disable-line @typescript-eslint/no-explicit-any

const alias = (id: string): VariableAlias => ({ type: 'VARIABLE_ALIAS', id });

function rgb(hex: string): RGBA {
  const n = (i: number): number => parseInt(hex.slice(i, i + 2), 16) / 255;
  return { r: n(1), g: n(3), b: n(5), a: 1 };
}

function solid(hex: string, bound?: string): Paint {
  const c = rgb(hex);
  return Object.freeze({
    type: 'SOLID',
    color: { r: c.r, g: c.g, b: c.b },
    opacity: 1,
    ...(bound == null ? {} : { boundVariables: Object.freeze({ color: Object.freeze(alias(bound)) }) }),
  }) as Paint;
}

function shadow(bound: string): Effect {
  return Object.freeze({
    type: 'DROP_SHADOW',
    color: rgb('#000000'),
    offset: { x: 0, y: 1 },
    radius: 4,
    spread: 0,
    visible: true,
    blendMode: 'NORMAL',
    boundVariables: Object.freeze({ color: Object.freeze(alias(bound)) }),
  }) as Effect;
}

// 원격 변수 id — 실측한 모양.
const S1 = 'VariableID:k-err/7138:320'; // color/error-container 옛 사본
const C1 = 'VariableID:k-err/7817:29'; //  … 현재 사본
const S2 = 'VariableID:k-out/7347:638'; // color/outline-variant 옛 사본
const C2 = 'VariableID:k-out/7979:3'; //   … 현재 사본
const S5 = 'VariableID:k-gap/10:1'; //     space/4 옛 사본 (값은 같다)
const C5 = 'VariableID:k-gap/20:1';
const G1 = 'VariableID:k-gone/1:1'; //     게시가 내려가 현재 사본을 알 수 없는 변수
const G2 = 'VariableID:k-gone/2:2';
const P1 = 'VariableID:k-pri/1:1'; //      사본이 하나뿐인 변수
const C8 = 'VariableID:k-bg/3:3'; //       확장 컬렉션이 덮어쓴 변수(사본 하나)
const POLD = 'VariableID:k-red50/1:9'; //  Primitives — 옛 사본이 가리키는 값
const PNEW = 'VariableID:k-red51/2:9'; //  Primitives — 현재 사본이 가리키는 값
const L1 = 'VariableID:local-danger'; //   로컬 변수 — 옛 사본의 별칭

interface NodeSpec {
  id: string;
  name: string;
  type: string;
  visible?: boolean;
  fills?: Paint[] | 'mixed';
  strokes?: Paint[];
  effects?: Effect[];
  scalar?: Record<string, VariableAlias>;
  children?: Any[];
  overrides?: { id: string; overriddenFields: string[] }[];
  main?: { remote: boolean };
  segments?: { start: number; end: number; fills: Paint[] }[];
}

interface World {
  figma: Any;
  writes: string[];
  imports: string[];
  pageCalls: string[];
  fonts: Set<string>;
  nodes: Map<string, Any>;
  variables: Map<string, Any>;
  extension: Any;
  styles: Any[];
}

const kFont = { family: 'Pretendard', style: 'Regular' };
const fontKey = (f: { family: string; style: string }): string => `${f.family}\u0001${f.style}`;

function makeWorld(withDuplicates = true): World {
  const mixed = Symbol('mixed');
  const w: World = {
    figma: null,
    writes: [],
    imports: [],
    pageCalls: [],
    fonts: new Set(),
    nodes: new Map(),
    variables: new Map(),
    extension: null,
    styles: [],
  };
  let current: Any = null;
  const pageOf = new Map<string, string>();

  const paintAliases = (list: readonly Any[]): VariableAlias[] =>
    list.filter((p) => p.boundVariables?.color != null).map((p) => p.boundVariables.color);

  const node = (pageId: string, spec: NodeSpec): Any => {
    const state = {
      fills: spec.fills ?? [],
      strokes: spec.strokes ?? [],
      effects: spec.effects ?? [],
      scalar: { ...(spec.scalar ?? {}) },
      segments: spec.segments ?? [],
    };
    const guard = (what: string): void => {
      w.writes.push(`${spec.id}:${what}`);
      if (current?.id !== pageOf.get(spec.id)) {
        throw new Error(`${spec.id}: ${what} written while page ${current?.id} is current`);
      }
      if (spec.type === 'TEXT' && !w.fonts.has(fontKey(kFont))) {
        throw new Error(`${spec.id}: ${what} written before its font was loaded`);
      }
    };
    const n: Any = {
      id: spec.id,
      name: spec.name,
      type: spec.type,
      visible: spec.visible ?? true,
      children: spec.children,
      overrides: spec.overrides,
      async getMainComponentAsync() {
        return spec.main ?? null;
      },
      setBoundVariable(field: string, v: Any) {
        guard(field);
        state.scalar[field] = alias(v.id);
      },
    };
    Object.defineProperty(n, 'fills', {
      get: () => (state.fills === 'mixed' ? mixed : state.fills),
      set: (v: Paint[]) => {
        guard('fills');
        state.fills = v;
      },
    });
    Object.defineProperty(n, 'strokes', {
      get: () => state.strokes,
      set: (v: Paint[]) => {
        guard('strokes');
        state.strokes = v;
      },
    });
    Object.defineProperty(n, 'effects', {
      get: () => state.effects,
      set: (v: Effect[]) => {
        guard('effects');
        state.effects = v;
      },
    });
    Object.defineProperty(n, 'boundVariables', {
      get: () => {
        const out: Any = { ...state.scalar };
        if (state.fills === 'mixed') {
          const ranged = state.segments.reduce((acc: VariableAlias[], s) => acc.concat(paintAliases(s.fills)), []);
          if (ranged.length > 0) out.textRangeFills = ranged;
        } else if (paintAliases(state.fills).length > 0) {
          out.fills = paintAliases(state.fills);
        }
        if (paintAliases(state.strokes).length > 0) out.strokes = paintAliases(state.strokes);
        const fx = state.effects.filter((e: Any) => e.boundVariables?.color != null).map((e: Any) => e.boundVariables.color);
        if (fx.length > 0) out.effects = fx;
        return out;
      },
    });
    if (spec.type === 'TEXT') {
      n.characters = 'AB';
      n.fontName = kFont;
      n.getRangeAllFontNames = () => [kFont];
      n.getStyledTextSegments = (fields: string[]) =>
        state.segments.map((s) => ({
          characters: 'AB'.slice(s.start, s.end),
          start: s.start,
          end: s.end,
          ...(fields.includes('fills') ? { fills: s.fills } : {}),
          ...(fields.includes('boundVariables') ? { boundVariables: {} } : {}),
        }));
      n.setRangeFills = (start: number, end: number, paints: Paint[]) => {
        guard('rangeFills');
        const seg = state.segments.find((s) => s.start === start && s.end === end);
        if (seg == null) throw new Error(`no segment ${start}-${end}`);
        seg.fills = paints;
      };
    }
    w.nodes.set(spec.id, n);
    pageOf.set(spec.id, pageId);
    for (const child of spec.children ?? []) pageOf.set(child.id, pageId);
    return n;
  };

  const variable = (spec: {
    id: string;
    key: string;
    name: string;
    remote: boolean;
    type: string;
    collection: string;
    values: Record<string, unknown>;
  }): Any => {
    const v: Any = {
      id: spec.id,
      key: spec.key,
      name: spec.name,
      remote: spec.remote,
      resolvedType: spec.type,
      variableCollectionId: spec.collection,
      valuesByMode: spec.values,
      setValueForMode(modeId: string, value: unknown) {
        w.writes.push(`${spec.id}:${modeId}`);
        if (w.extension.modes.some((m: Any) => m.modeId === modeId)) {
          const o = w.extension.variableOverrides;
          o[spec.id] = { ...(o[spec.id] ?? {}), [modeId]: value };
          return;
        }
        if (spec.remote) throw new Error('Cannot modify a remote variable');
        spec.values[modeId] = value;
      },
    };
    w.variables.set(spec.id, v);
    return v;
  };

  // 컬렉션 — 옛 사본은 다른 모드 id 의 옛 컬렉션에 산다(모드는 이름으로 맞춘다).
  const collections = new Map<string, Any>([
    ['C:sem', { id: 'C:sem', name: 'Semantic/ Color · CoUI', remote: true, isExtension: false, modes: [{ modeId: 'm-l', name: 'Light' }, { modeId: 'm-d', name: 'Dark' }], defaultModeId: 'm-l', variableIds: [C1, C2, C8] }],
    ['C:sem-old', { id: 'C:sem-old', name: 'Semantic/ Color · CoUI', remote: true, isExtension: false, modes: [{ modeId: 'o-l', name: 'Light' }, { modeId: 'o-d', name: 'Dark' }], defaultModeId: 'o-l', variableIds: [] }],
    ['C:prim', { id: 'C:prim', name: 'Primitives', remote: true, isExtension: false, modes: [{ modeId: 'p-v', name: 'Value' }], defaultModeId: 'p-v', variableIds: [] }],
    ['C:space', { id: 'C:space', name: 'Semantic/ Spacing', remote: true, isExtension: false, modes: [{ modeId: 's-v', name: 'Value' }], defaultModeId: 's-v', variableIds: [] }],
    ['C:app', { id: 'C:app', name: 'App', remote: false, isExtension: false, modes: [{ modeId: 'a-1', name: 'Mode 1' }], defaultModeId: 'a-1', variableIds: [L1] }],
  ]);

  variable({ id: POLD, key: 'k-red50', name: 'color/coui/red/50', remote: true, type: 'COLOR', collection: 'C:prim', values: { 'p-v': rgb('#FFF2F0') } });
  variable({ id: PNEW, key: 'k-red51', name: 'color/coui/red/50', remote: true, type: 'COLOR', collection: 'C:prim', values: { 'p-v': rgb('#FFEFED') } });
  variable({ id: S1, key: 'k-err', name: 'color/error-container', remote: true, type: 'COLOR', collection: 'C:sem-old', values: { 'o-l': alias(POLD), 'o-d': rgb('#690408') } });
  variable({ id: C1, key: 'k-err', name: 'color/error-container', remote: true, type: 'COLOR', collection: 'C:sem', values: { 'm-l': alias(PNEW), 'm-d': rgb('#690408') } });
  variable({ id: S2, key: 'k-out', name: 'color/outline-variant', remote: true, type: 'COLOR', collection: 'C:sem-old', values: { 'o-l': rgb('#CFD1D4'), 'o-d': rgb('#31353C') } });
  variable({ id: C2, key: 'k-out', name: 'color/outline-variant', remote: true, type: 'COLOR', collection: 'C:sem', values: { 'm-l': rgb('#CFD1D4'), 'm-d': rgb('#3C4249') } });
  variable({ id: S5, key: 'k-gap', name: 'space/4', remote: true, type: 'FLOAT', collection: 'C:space', values: { 's-v': 16 } });
  variable({ id: C5, key: 'k-gap', name: 'space/4', remote: true, type: 'FLOAT', collection: 'C:space', values: { 's-v': 16 } });
  variable({ id: G1, key: 'k-gone', name: 'color/retired', remote: true, type: 'COLOR', collection: 'C:sem-old', values: { 'o-l': rgb('#112233') } });
  variable({ id: G2, key: 'k-gone', name: 'color/retired', remote: true, type: 'COLOR', collection: 'C:sem', values: { 'm-l': rgb('#112233') } });
  variable({ id: P1, key: 'k-pri', name: 'color/primary', remote: true, type: 'COLOR', collection: 'C:sem', values: { 'm-l': rgb('#0055FF') } });
  variable({ id: C8, key: 'k-bg', name: 'color/surface', remote: true, type: 'COLOR', collection: 'C:sem', values: { 'm-l': rgb('#FFFFFF') } });
  variable({ id: L1, key: 'local-danger', name: 'app/danger', remote: false, type: 'COLOR', collection: 'C:app', values: { 'a-1': alias(withDuplicates ? S1 : C1) } });

  const ext = {
    id: 'C:ext-blue',
    name: 'Blue · Overrides',
    remote: false,
    isExtension: true,
    rootVariableCollectionId: 'C:sem',
    defaultModeId: 'e-l',
    modes: [
      { modeId: 'e-l', name: 'Light', parentModeId: 'm-l' },
      { modeId: 'e-d', name: 'Dark', parentModeId: 'm-d' },
    ],
    // 실측 — 두 사본이 확장 컬렉션의 변수 목록에 함께 있다.
    variableIds: withDuplicates ? [S1, C1, S2, C2, C8, G2] : [C1, C2, C8],
    variableOverrides: withDuplicates
      ? ({ [C8]: { 'e-l': alias(S1) }, [S2]: { 'e-l': rgb('#000000') } } as Any)
      : ({ [C8]: { 'e-l': alias(C1) } } as Any),
  };
  w.extension = ext;
  collections.set(ext.id, ext);

  const style = (id: string, name: string, type: 'PAINT' | 'EFFECT', items: Any[]): Any => {
    const field = type === 'PAINT' ? 'paints' : 'effects';
    let state = items;
    const s: Any = { id, name, type };
    Object.defineProperty(s, field, {
      get: () => state,
      set: (v: Any[]) => {
        w.writes.push(`${id}:${field}`);
        state = v;
      },
    });
    w.styles.push(s);
    return s;
  };
  style('S:danger', 'Danger fill', 'PAINT', [solid('#FFF2F0', withDuplicates ? S1 : C1)]);
  style('S:glow', 'Danger glow', 'EFFECT', [shadow(withDuplicates ? S1 : C1)]);

  const stale = (id: string, fallback: string): string => (withDuplicates ? id : fallback);
  const archive: Any = { id: 'p-arch', name: 'Archive', type: 'PAGE', children: [] };
  const home: Any = { id: 'p-home', name: 'Home', type: 'PAGE', children: [] };
  archive.children = [
    node('p-arch', {
      id: '1:1',
      name: 'Card',
      type: 'FRAME',
      fills: [solid('#FFF2F0', stale(S1, C1))],
      strokes: [solid('#FFF2F0', stale(S1, C1))],
      children: [
        node('p-arch', { id: '1:2', name: 'Badge', type: 'RECTANGLE', fills: [solid('#FFEFED', C1)], effects: [shadow(stale(S1, C1))] }),
        node('p-arch', { id: '1:3', name: 'Hidden', type: 'RECTANGLE', visible: false, fills: [solid('#FFF2F0', stale(S1, C1))] }),
      ],
    }),
    node('p-arch', { id: '1:4', name: 'Label', type: 'TEXT', fills: [solid('#FFF2F0', stale(S1, C1))] }),
    node('p-arch', {
      id: '1:5',
      name: 'Mixed',
      type: 'TEXT',
      fills: 'mixed',
      segments: [
        { start: 0, end: 1, fills: [solid('#FFF2F0', stale(S1, C1))] },
        { start: 1, end: 2, fills: [solid('#000000')] },
      ],
    }),
    // 사람이 놓은 라이브러리 인스턴스 — 배경은 이 파일이 덮어썼고(fills), 글자색은 원본 그대로다.
    node('p-arch', {
      id: '2:1',
      name: 'Button',
      type: 'INSTANCE',
      main: { remote: true },
      overrides: [{ id: 'I2:1;1:1', overriddenFields: ['fills'] }],
      children: [
        node('p-arch', { id: 'I2:1;1:1', name: 'bg', type: 'FRAME', fills: [solid('#FFF2F0', stale(S1, C1))] }),
        node('p-arch', { id: 'I2:1;1:2', name: 'fg', type: 'FRAME', fills: [solid('#CFD1D4', stale(S2, C2))] }),
      ],
    }),
    // 이 파일의 컴포넌트의 인스턴스 — 덮어쓰지 않은 바인딩은 아래 정의의 것이다.
    node('p-arch', {
      id: '3:1',
      name: 'LocalCard',
      type: 'INSTANCE',
      main: { remote: false },
      overrides: [],
      children: [node('p-arch', { id: 'I3:1;12:1', name: 'bg', type: 'FRAME', fills: [solid('#FFF2F0', stale(S1, C1))] })],
    }),
    node('p-arch', {
      id: '12:0',
      name: 'LocalCardMain',
      type: 'COMPONENT',
      children: [node('p-arch', { id: '12:1', name: 'bg', type: 'FRAME', fills: [solid('#FFF2F0', stale(S1, C1))] })],
    }),
    node('p-arch', { id: '1:6', name: 'Divider', type: 'FRAME', strokes: [solid('#CFD1D4', stale(S2, C2))] }),
    node('p-arch', { id: '1:7', name: 'Row', type: 'FRAME', scalar: { itemSpacing: alias(stale(S5, C5)) } }),
  ];
  home.children = [
    // 현재 사본도 어딘가가 참조해야 이 파일에 있다 — space/4 의 현재 사본은 여기서 보인다.
    node('p-home', {
      id: '4:1',
      name: 'Hero',
      type: 'FRAME',
      fills: [solid('#FFEFED', C1), solid('#0055FF', P1)],
      scalar: { paddingLeft: alias(C5) },
    }),
    node('p-home', { id: '4:2', name: 'Old', type: 'FRAME', fills: [solid('#112233', withDuplicates ? G1 : G2)] }),
  ];
  for (const p of [archive, home]) {
    p.loadAsync = async () => undefined;
    w.nodes.set(p.id, p);
  }
  current = home;

  const currentByKey: Record<string, string> = { 'k-err': C1, 'k-out': C2, 'k-gap': C5, 'k-pri': P1, 'k-bg': C8, 'k-gone': G2 };
  w.figma = {
    mixed,
    root: { children: [archive, home] },
    get currentPage() {
      return current;
    },
    async setCurrentPageAsync(page: Any) {
      w.pageCalls.push(page.id);
      current = page;
    },
    async getNodeByIdAsync(id: string) {
      return w.nodes.get(id) ?? null;
    },
    async loadFontAsync(font: { family: string; style: string }) {
      w.fonts.add(fontKey(font));
    },
    async getLocalPaintStylesAsync() {
      return w.styles.filter((s) => s.type === 'PAINT');
    },
    async getLocalEffectStylesAsync() {
      return w.styles.filter((s) => s.type === 'EFFECT');
    },
    async getLocalGridStylesAsync() {
      return [];
    },
    async getLocalTextStylesAsync() {
      return [];
    },
    async getStyleByIdAsync(id: string) {
      return w.styles.find((s) => s.id === id) ?? null;
    },
    variables: {
      async getVariableByIdAsync(id: string) {
        return w.variables.get(id) ?? null;
      },
      async getVariableCollectionByIdAsync(id: string) {
        return collections.get(id) ?? null;
      },
      async getLocalVariablesAsync() {
        return [...w.variables.values()].filter((v) => !v.remote);
      },
      async getLocalVariableCollectionsAsync() {
        return [collections.get('C:app'), ext];
      },
      async importVariableByKeyAsync(key: string) {
        w.imports.push(key);
        if (key === 'k-gone') throw new Error('not published');
        return w.variables.get(currentByKey[key]);
      },
      createVariableAlias(v: Any) {
        return alias(v.id);
      },
      // 받은 것을 바꾸지 않고 묶은 사본을 돌려준다 — 실제 API 와 같다.
      setBoundVariableForPaint(paint: Any, field: string, v: Any) {
        return { ...paint, boundVariables: { ...(paint.boundVariables ?? {}), [field]: alias(v.id) } };
      },
      setBoundVariableForEffect(effect: Any, field: string, v: Any) {
        return { ...effect, boundVariables: { ...(effect.boundVariables ?? {}), [field]: alias(v.id) } };
      },
      setBoundVariableForLayoutGrid(grid: Any, field: string, v: Any) {
        return { ...grid, boundVariables: { ...(grid.boundVariables ?? {}), [field]: alias(v.id) } };
      },
    },
  };
  return w;
}

function install(w: World): void {
  (globalThis as Any).figma = w.figma;
}

const boundId = (paint: Any): string | undefined => paint?.boundVariables?.color?.id;

// ── 본문 ─────────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  console.log('selftest: library-copies');

  // ── 1. 순수 부분 ──────────────────────────────────────────────────────────

  await check('원격 변수 id — 키와 원본 노드 id, 짧은 이름', () => {
    assertEq(parseRemoteVariableId(S1), { key: 'k-err', source: '7138:320' }, 'parse');
    assertEq(parseRemoteVariableId('VariableID:12:3'), null, 'a local id has no source part');
    assertEq(shortCopyId(C1), '…/7817:29', 'short');
    assertEq(shortCopyId('VariableID:12:3'), 'VariableID:12:3', 'unparsed id stays');
  });

  await check('aliasIds — 별칭 하나 · 목록 · 컴포넌트 속성, 값은 별칭이 아니다', () => {
    assertEq(aliasIds(alias('a')), ['a'], 'one');
    assertEq(aliasIds([alias('a'), alias('b')]), ['a', 'b'], 'list');
    assertEq(aliasIds({ 'On#1:0': alias('c') }), ['c'], 'component properties');
    assertEq(aliasIds(rgb('#FFFFFF')), [], 'a colour value');
    assertEq(aliasIds(16), [], 'a number');
  });

  await check('isOverridden — 덮어쓰기 필드 이름으로', () => {
    assert(isOverridden('fills', ['fills']), 'fills');
    assert(isOverridden('textRangeFills', ['fills']), 'range fills are fills');
    assert(isOverridden('fontWeight', ['fontName']), 'font fields are fontName');
    assert(isOverridden('cornerRadius', ['boundVariables']), 'boundVariables covers every field');
    assert(!isOverridden('strokes', ['fills']), 'a different field');
    assert(!isOverridden('fills', []), 'nothing overridden');
  });

  await check('duplicateKeys — 같은 키의 원격 사본이 둘 이상일 때만', () => {
    const v = (id: string, key: string, remote = true): CopyVariable => ({
      id,
      key,
      name: key,
      remote,
      resolvedType: 'COLOR',
      collectionId: 'c',
      valuesByMode: {},
    });
    const sets = duplicateKeys([v(S1, 'k-err'), v(C1, 'k-err'), v(C1, 'k-err'), v(P1, 'k-pri'), v('L', 'k-loc', false), v('L2', 'k-loc', false)]);
    assertEq(sets.map((s) => [s.key, s.copies.map((c) => c.id)]), [['k-err', [S1, C1]]], 'only the remote key with two copies');
  });

  await check('formatCopyValue — hex · 숫자 · 글 · 참거짓', () => {
    assertEq(formatCopyValue(rgb('#FFF2F0')), '#FFF2F0', 'colour');
    assertEq(formatCopyValue({ ...rgb('#000000'), a: 0.5 }), '#00000080', 'translucent colour');
    assertEq(formatCopyValue(16.000000059604645), '16', 'a 32-bit float read back');
    assertEq(formatCopyValue('Pretendard'), '"Pretendard"', 'string');
    assertEq(formatCopyValue(true), 'true', 'boolean');
  });

  await check('rebindItems — 묶은 사본으로 바꾼 새 목록, 받은 항목은 그대로', () => {
    const before = [solid('#FFF2F0', S1), solid('#000000'), solid('#FFEFED', C1)];
    const swap = new Map([[S1, { id: C1 }]]);
    const r = rebindItems(before, swap, (p: Any, field, v) => ({ ...p, boundVariables: { [field]: alias(v.id) } }));
    assertEq(r.changed, 1, 'one paint was on the stale copy');
    assertEq(r.list.map(boundId), [C1, undefined, C1], 'bindings after');
    assert(r.list[0] !== before[0], 'the changed paint is a new object');
    assert(r.list[1] === before[1] && r.list[2] === before[2], 'untouched paints are kept as they are');
    assertEq(boundId(before[0]), S1, 'the paint it was given is unchanged');
  });

  await check('rebindPaintList — 그라디언트는 정지점의 color 를, 단색은 칠의 color 를 옮긴다', () => {
    const stop = (pos: number, bound?: string): Any =>
      Object.freeze({ position: pos, color: { r: 0, g: 0, b: 0, a: 1 }, ...(bound == null ? {} : { boundVariables: { color: alias(bound) } }) });
    const gradient: Any = Object.freeze({ type: 'GRADIENT_LINEAR', gradientTransform: [[1, 0, 0], [0, 1, 0]], gradientStops: [stop(0, S1), stop(1)] });
    const before = [gradient, solid('#000000', S1), solid('#FFFFFF')];
    const swap = new Map([[S1, { id: C1 }]]);
    const r = rebindPaintList(before, swap, (p: Any, field, v) => ({ ...p, boundVariables: { [field]: alias(v.id) } }), (v) => alias(v.id));
    assertEq(r.changed, 2, 'one gradient stop + one solid');
    assertEq(r.list[0].type, 'GRADIENT_LINEAR', 'the gradient stays a gradient');
    assertEq((r.list[0] as Any).gradientStops.map((s: Any) => s.boundVariables?.color?.id), [C1, undefined], 'stop bindings after');
    assertEq((r.list[0] as Any).gradientStops[0].position, 0, 'the stop keeps its position');
    assertEq(boundId(r.list[1]), C1, 'solid after');
    assert(r.list[2] === before[2], 'an untouched paint is kept as it is');
    assertEq(gradient.gradientStops[0].boundVariables.color.id, S1, 'the gradient it was given is unchanged');
  });

  await check('leftoverIds — 그 필드에 남은 옛 변수만', () => {
    const swap = new Map([[S1, { id: C1 }]]);
    assertEq(leftoverIds({ fills: [alias(S1), alias(C1)] }, 'fills', swap), [S1], 'stale one left');
    assertEq(leftoverIds({ fills: [alias(C1)] }, 'fills', swap), [], 'moved');
    assertEq(leftoverIds(undefined, 'fills', swap), [], 'no bindings');
  });

  await check('applyVariableSwap — 그라디언트 정지점 · 빈 글자 노드를 옮기고, 옮기지 못한 자리는 실패 줄로 남긴다', async () => {
    const saved = (globalThis as Any).figma;
    const NEW = { id: C1 };
    const stopsOf = (paints: Any[]): VariableAlias[] =>
      paints.flatMap((p: Any) => (p.gradientStops ?? []).map((s: Any) => s.boundVariables?.color).concat(p.boundVariables?.color ?? []).filter(Boolean));
    // 그라디언트 채움 — 정지점이 옛 사본을 가리킨다.
    let gradientFills: Any[] = [
      { type: 'GRADIENT_LINEAR', gradientTransform: [[1, 0, 0], [0, 1, 0]], gradientStops: [{ position: 0, color: { r: 1, g: 1, b: 1, a: 1 }, boundVariables: { color: alias(S1) } }] },
    ];
    const gradient: Any = { id: '9:1', name: 'sidebar', type: 'FRAME' };
    Object.defineProperty(gradient, 'fills', { get: () => gradientFills, set: (v: Any[]) => (gradientFills = v) });
    Object.defineProperty(gradient, 'boundVariables', { get: () => ({ fills: stopsOf(gradientFills) }) });
    // 빈 글자 — 구간이 없고 바인딩은 노드에만 있다.
    let family = alias(S1);
    const empty: Any = {
      id: 'I9:2;1:1',
      name: 'title',
      type: 'TEXT',
      characters: '',
      fontName: { family: 'Pretendard', style: 'Regular' },
      getStyledTextSegments: () => [],
      setBoundVariable(field: string, v: Any) {
        if (field === 'fontFamily') family = alias(v.id);
      },
    };
    Object.defineProperty(empty, 'boundVariables', { get: () => ({ fontFamily: family }) });
    // 쓰기를 받고도 바뀌지 않는 칠 — 새 형태가 나와도 위치가 로그에 남아야 한다.
    const sticky: Any = { id: '9:3', name: 'Sticky', type: 'FRAME' };
    Object.defineProperty(sticky, 'fills', { get: () => [solid('#000000', S1)], set: () => undefined });
    Object.defineProperty(sticky, 'boundVariables', { get: () => ({ fills: [alias(S1)] }) });
    const nodes = new Map<string, Any>([gradient, empty, sticky].map((n) => [n.id, n]));
    const page: Any = { id: 'p1', name: 'Page', type: 'PAGE', children: [gradient, empty, sticky] };
    (globalThis as Any).figma = {
      mixed: Symbol('mixed'),
      currentPage: page,
      async setCurrentPageAsync(pg: Any) {
        (globalThis as Any).figma.currentPage = pg;
      },
      async getNodeByIdAsync(id: string) {
        return nodes.get(id) ?? null;
      },
      async loadFontAsync() {},
      variables: {
        setBoundVariableForPaint: (p: Any, field: string, v: Any) => ({ ...p, boundVariables: { [field]: alias(v.id) } }),
        createVariableAlias: (v: Any) => alias(v.id),
      },
    };
    try {
      const use = (ownerId: string, field: string): Any => ({ variableId: S1, kind: 'node', ownerId, ownerName: ownerId, field, pageId: 'p1', pageName: 'Page' });
      const r = await applyVariableSwap([page], [use('9:1', 'fills'), use('I9:2;1:1', 'fontFamily'), use('9:3', 'fills')], new Map([[S1, NEW as Any]]));
      assertEq(gradientFills[0].gradientStops[0].boundVariables.color.id, C1, 'gradient stop moved');
      assertEq(family.id, C1, 'empty text moved at the node level');
      assertEq(r.tally.fills, 2, 'gradient + the sticky write counted as writes');
      assertEq(r.tally.fields, 1, 'empty text counted');
      assertEq(r.failures.length, 1, `exactly the sticky node fails: ${JSON.stringify(r.failures)}`);
      assert(r.failures[0].includes('"Sticky" (9:3) · fills'), `failure names the node and field: ${r.failures[0]}`);
    } finally {
      (globalThis as Any).figma = saved;
    }
  });

  // ── 2. 점검 — 읽기 전용 ───────────────────────────────────────────────────

  let scan: LibraryCopyScan | { error: string } | null = null;
  const audited = makeWorld();
  await check('점검: 사본이 둘인 변수만 찾고, 현재 사본은 그런 키에만 묻고, 아무것도 쓰지 않는다', async () => {
    install(audited);
    scan = await auditLibraryCopies();
    assert(!('error' in scan), `scan failed: ${JSON.stringify(scan)}`);
    const s = scan as LibraryCopyScan;
    assertEq(s.keys, 4, 'k-err · k-out · k-gap · k-gone');
    assertEq(
      s.findings.map((f) => [f.name, f.stale, f.current]),
      [
        ['color/error-container', S1, C1],
        ['color/outline-variant', S2, C2],
        ['color/retired', G1, null],
        ['color/retired', G2, null],
        ['space/4', S5, C5],
      ],
      'one finding per stale copy; an unknown current copy lists every copy',
    );
    assertEq([...new Set(audited.imports)].sort(), ['k-err', 'k-gap', 'k-gone', 'k-out'], 'import asked only for keys with two copies');
    assertEq(audited.writes, [], 'the audit writes nothing');
  });

  await check('점검: 이 파일의 참조 — 숨은 노드 포함, 인스턴스는 덮어쓴 필드만, 로컬 정의는 한 번', () => {
    const s = scan as LibraryCopyScan;
    const err = s.findings.find((f) => f.stale === S1)!;
    const nodes = [...new Set(err.uses.filter((u) => u.kind === 'node').map((u) => u.ownerId))].sort();
    assertEq(nodes, ['12:1', '1:1', '1:2', '1:3', '1:4', '1:5', 'I2:1;1:1'], 'owned nodes (the local instance mirrors 12:1)');
    assert(!err.uses.some((u) => u.ownerId === 'I3:1;12:1'), 'the local instance is not counted twice');
    assertEq(
      err.uses.filter((u) => u.kind !== 'node').map((u) => [u.kind, u.ownerName]),
      [
        ['style', 'Danger fill'],
        ['style', 'Danger glow'],
        ['alias', 'app/danger'],
        ['override', 'Blue · Overrides'],
      ],
      'styles · local alias · override value',
    );
    const out = s.findings.find((f) => f.stale === S2)!;
    assertEq(
      out.uses.map((u) => [u.kind, u.ownerId]),
      [
        ['library', 'I2:1;1:2'],
        ['node', '1:6'],
        ['overridden', 'C:ext-blue'],
      ],
      'the library-held binding is counted apart',
    );
  });

  await check('점검: 모드별 값 차이 — 모드는 이름으로 맞추고, 별칭은 끝의 값까지', () => {
    const s = scan as LibraryCopyScan;
    assertEq(s.findings.find((f) => f.stale === S1)!.diffs, [{ mode: 'Light', stale: '#FFF2F0', current: '#FFEFED' }], 'error-container');
    assertEq(s.findings.find((f) => f.stale === S2)!.diffs, [{ mode: 'Dark', stale: '#31353C', current: '#3C4249' }], 'outline-variant');
    assertEq(s.findings.find((f) => f.stale === S5)!.diffs, [], 'space/4 — same value');
  });

  await check('점검 목록 · 로그 — 옛 사본마다 한 줄, 맨 위에', () => {
    const report = withLibraryCopies(
      buildConsumerAuditReport([], { sans: 'Pretendard', mono: 'Geist Mono' }, { scope: '현재 페이지 "Home"', pageCount: 1, textNodes: 0 }),
      scan as LibraryCopyScan,
    );
    const rows = report.groups;
    assertEq(rows.map((g) => g.category), ['library-copy', 'library-copy', 'library-copy', 'library-copy', 'library-copy'], 'categories');
    const err = rows[0];
    assertEq(err.signature, 'color/error-container · 옛 사본 …/7138:320 → 현재 …/7817:29', 'signature');
    assertEq([err.label, err.warn, err.runs, err.nodes], ['경고 · 가져온 사본 중복', true, 11, 7], 'counts');
    assertEq(err.where, [{ name: 'Archive', count: 7 }, { name: '스타일', count: 2 }, { name: '별칭', count: 2 }], 'where');
    assertEq(err.pages.map((p) => [p.pageName, p.ids.length]), [['Archive', 7]], 'selectable nodes per page');
    assert(err.action.includes('「옛 사본 다시 연결」로 참조 11곳(노드 7 · 스타일 2 · 별칭 2)을 현재 사본에 옮긴다'), err.action);
    assert(err.action.includes('값 차이 — Light #FFF2F0 → #FFEFED'), err.action);
    const out = rows[1];
    assert(out.action.includes('라이브러리 컴포넌트 안 1곳은 덮어쓰지 않는다'), out.action);
    assert(out.action.includes('확장 컬렉션 1개가 덮어쓰기를 이 옛 사본에 걸어 두었다'), out.action);
    assert(rows[2].action.startsWith('현재 사본을 알 수 없다(not published)'), rows[2].action);
    assert(rows[3].pages.length === 0 && rows[3].runs === 0, 'a copy only the extension lists has nothing to select');
    assert(rows[4].action.includes('값 차이 없음'), rows[4].action);
    const log = formatConsumerAudit(report);
    assertEq(log[1], '글자 경고 없음 ✅', 'no text warning, but not a clean file');
    assert(
      log.includes(
        '⚠ 가져온 사본 중복 5 — 라이브러리 변수 4개를 두 번 이상 가져왔다. 옛 사본을 참조하는 곳 13 (파일 전체) — 「옛 사본 다시 연결」로 현재 사본에 옮긴다',
      ),
      log.join(' | '),
    );
    assert(log.includes('  라이브러리 컴포넌트 안 1곳은 덮어쓰지 않는다 — 라이브러리 업데이트를 받는다'), log.join(' | '));
    assert(log.some((l) => l.startsWith('  ⚠ 가져온 사본 중복 ×11 — color/error-container')), 'row line in the log');
  });

  await check('점검: 사본이 없으면 그렇게 말하고, 못 봤으면 그렇게 말한다', async () => {
    const clean = makeWorld(false);
    install(clean);
    const s = await auditLibraryCopies();
    assert(!('error' in s) && s.findings.length === 0, 'no findings');
    assertEq(clean.imports, [], 'nothing to ask');
    const base = buildConsumerAuditReport([], { sans: 'Pretendard', mono: 'Geist Mono' }, { scope: 's', pageCount: 1, textNodes: 0 });
    const log = formatConsumerAudit(withLibraryCopies(base, s));
    assertEq(log[1], '경고 없음 ✅', 'clean');
    assert(log.some((l) => /^가져온 사본 중복 없음 — 파일 전체의 원격 변수 \d+개$/.test(l)), log.join(' | '));
    const failed = formatConsumerAudit(withLibraryCopies(base, { error: 'boom' }));
    assertEq([failed[1], failed[2]], ['글자 경고 없음 ✅', '⚠ 가져온 사본 중복은 보지 못했다 — boom'], 'scan failure is not silence');
  });

  // ── 3. 다시 연결 ──────────────────────────────────────────────────────────

  const w = makeWorld();
  const originals = {
    card: w.nodes.get('1:1').fills[0],
    style: w.styles[0].paints[0],
  };
  let log: string[] = [];
  await check('다시 연결: 이 파일의 참조를 현재 사본으로 — 새 항목을 다시 넣는다', async () => {
    install(w);
    log = await rebindLibraryCopies();
    const fills = (id: string): Any[] => w.nodes.get(id).fills;
    for (const id of ['1:1', '1:3', '1:4', 'I2:1;1:1', '12:1']) assertEq(boundId(fills(id)[0]), C1, `${id} fills`);
    assertEq(boundId(w.nodes.get('1:1').strokes[0]), C1, 'Card strokes');
    assertEq(boundId(w.nodes.get('1:6').strokes[0]), C2, 'Divider strokes');
    assertEq(w.nodes.get('1:2').effects[0].boundVariables.color.id, C1, 'Badge shadow');
    assertEq(w.nodes.get('1:5').getStyledTextSegments(['fills']).map((s: Any) => boundId(s.fills[0])), [C1, undefined], 'range fills');
    assertEq(w.nodes.get('1:7').boundVariables.itemSpacing.id, C5, 'Row itemSpacing');
    assertEq(boundId(w.styles[0].paints[0]), C1, 'paint style');
    assertEq(w.styles[1].effects[0].boundVariables.color.id, C1, 'effect style');
    assertEq((w.variables.get(L1).valuesByMode['a-1'] as Any).id, C1, 'local alias');
    assertEq(w.extension.variableOverrides[C8]['e-l'].id, C1, 'override value');
    assertEq(boundId(originals.card), S1, 'the paint read before is untouched — the new one was written back');
    assertEq(boundId(originals.style), S1, 'the style paint read before is untouched');
  });

  await check('다시 연결: 라이브러리 컴포넌트 안 · 로컬 인스턴스 · 모르는 현재 사본은 건드리지 않는다', () => {
    assertEq(boundId(w.nodes.get('I2:1;1:2').fills[0]), S2, 'library-held binding stays');
    assertEq(boundId(w.nodes.get('I3:1;12:1').fills[0]), S1, 'the local instance gets no override (its definition was moved)');
    assertEq(boundId(w.nodes.get('4:2').fills[0]), G1, 'a copy without a known current copy stays');
    assertEq(boundId(w.nodes.get('1:2').fills[0]), C1, 'a binding already on the current copy stays');
    assert(!w.writes.some((x) => x.startsWith('I2:1;1:2') || x.startsWith('I3:1;12:1') || x.startsWith('4:')), w.writes.join(' '));
    assertEq(w.extension.variableOverrides[S2], { 'e-l': rgb('#000000') }, 'an override stored on the stale copy is not moved');
  });

  await check('다시 연결: 페이지를 옮겨 가며 고치고 원래 페이지로 돌아오며, 글꼴을 먼저 불러온다', () => {
    assertEq(w.pageCalls, ['p-arch', 'p-home'], 'Archive, then back to Home');
    assert(w.fonts.has(fontKey(kFont)), 'the text face was loaded');
    // 더블은 다른 페이지 · 글꼴 전의 쓰기를 던진다 — 실패 줄이 없어야 한다.
    assert(!log.some((l) => l.includes('written')), log.join(' | '));
  });

  await check('다시 연결: 센 것 · 다시 읽어 확인 · 다시 열라는 안내', () => {
    assert(log.includes('✓ 다시 연결 — 채움 5 · 선 2 · 효과 1 · 글자 구간 채움 1 · 그 밖의 필드 1 · 스타일 2 · 별칭 2'), log.join(' | '));
    assert(log.includes('✓ 다시 읽어 확인 — 옛 사본을 참조하는 이 파일의 노드 · 스타일 · 별칭 0'), log.join(' | '));
    assert(log.some((l) => l.startsWith('파일을 닫았다가 다시 열면 옛 사본이 정리된다.')), 'reopen purges the stale copies');
    assert(log.some((l) => l.includes('「같은 이름의 로컬 토큰으로 다시 맞추기」')), 'and then re-sync the overrides');
    assert(log.some((l) => l.startsWith('⚠ 라이브러리 컴포넌트 안 1곳은 덮어쓰지 않았다')), 'library-held place is reported');
    assert(log.includes('  ⚠ 현재 사본을 알 수 없어 건너뛴다 — not published'), 'unknown current copy is reported');
  });

  await check('다시 연결: 사본 중복이 없으면 아무것도 쓰지 않는다', async () => {
    const clean = makeWorld(false);
    install(clean);
    const out = await rebindLibraryCopies();
    assert(out.some((l) => l.startsWith('가져온 사본 중복이 없다')), out.join(' | '));
    assertEq(clean.writes, [], 'no writes');
  });

  // ── 4. 배선 ───────────────────────────────────────────────────────────────

  await check('code.ts 가 두 명령을 라우팅하고 점검에 사본 중복을 더한다', () => {
    const code = codeLines(read('code.ts'));
    assert(/msg\.type === 'rebind-library-copies'\) \{\s*[^}]*await rebindLibraryCopies\(\)/.test(code), 'rebind branch');
    assert(/msg\.type === 'resync-collection-overrides'\) \{\s*[^}]*await resyncOverridesByName\(\)/.test(code), 'resync branch');
    assert(/withLibraryCopies\(\s*await auditConsumerFile\(\{[\s\S]*?await auditLibraryCopies\(\),\s*\)/.test(code), 'audit merges the copy scan');
  });

  await check('ui.html — 버튼 · 핸들러 · 메시지 · 비활성 목록 · 위치', () => {
    const ui = read('ui.html');
    const list = /const buttons = \[([\s\S]*?)\]\.map/.exec(ui)?.[1] ?? '';
    for (const id of ['rebind-library-copies', 'resync-collection-overrides']) {
      assert(new RegExp(`id="${id}"`).test(ui), `${id} button`);
      assert(new RegExp(`getElementById\\('${id}'\\)\\.onclick`).test(ui), `${id} click handler`);
      assert(new RegExp(`pluginMessage: \\{ type: '${id}' \\}`).test(ui), `${id} posted message`);
      assert(list.includes(`'${id}'`), `${id} is disabled while busy`);
    }
    const section = (tab: string): [number, number] => {
      const start = ui.indexOf(`<section data-tab="${tab}"`);
      return [start, ui.indexOf('</section>', start)];
    };
    const inside = (id: string, tab: string): boolean => {
      const [a, b] = section(tab);
      const at = ui.indexOf(`id="${id}"`);
      return a >= 0 && at > a && at < b;
    };
    assert(inside('rebind-library-copies', 'manage'), 'rebind lives next to the audit (관리 탭)');
    assert(inside('resync-collection-overrides', 'tokens'), 're-sync lives with the collection overrides (토큰 탭)');
    assert(/if \(g\.pages\.length > 0\) selectAuditPage\(g\.pages\[0\]\);/.test(ui), 'a row without nodes does not select');
  });

  await check('package.json 의 selftest 체인에 들어 있다', () => {
    const pkg = JSON.parse(read('package.json')) as { scripts: Record<string, string> };
    assert(pkg.scripts['selftest:library-copies'] != null, 'selftest:library-copies script');
    assert(/npm run selftest:library-copies\b/.test(pkg.scripts.selftest), 'aggregate selftest runs it');
  });

  if (failures > 0) {
    console.error(`\n${failures} failure(s)`);
    process.exit(1);
  }
  console.log('\nall ok');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
