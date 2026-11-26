/// <reference types="@figma/plugin-typings" />

// Self-test for src/brand-collections.ts — 「옛 브랜드 컬렉션」(소비 파일 점검의 분류)과
// 「옛 브랜드 컬렉션 다시 연결」(#6211).
//
// 캔버스 없이 틀릴 수 있는 것:
//
//   1. **어느 컬렉션이 옛 브랜드 컬렉션인가.** 이름은 코드 브랜드 목록(`brands.json`)에서
//      읽고, 옛 번호 접두를 빼고 견준다. 라이브러리 브랜드의 컬렉션과 목록에 없는 브랜드의
//      컬렉션은 아니다.
//   2. **무엇을 무엇으로 옮기는가.** 노드 · 스타일 · 별칭 · 덮어쓴 인스턴스 필드는 같은
//      이름의 `Semantic/ Color · CoUI` 변수로. 라이브러리 인스턴스의 덮어쓰지 않은 바인딩,
//      짝이 없는 이름, 타입이 다른 짝, 브랜드 원시값에 직접 묶인 곳은 그대로 두고 보고한다.
//   3. **점검은 읽기만 한다.** 짝은 팀 라이브러리의 변수 목록에서 찾는다 — 가져오기
//      (`importVariableByKeyAsync`)는 쓰기 명령만, 짝이 있는 변수만.
//   4. **배선.** 버튼 · 핸들러 · 메시지 · 비활성 목록 · 위치 · selftest 체인.

import { buildConsumerAuditReport, formatConsumerAudit } from '../src/consumer-audit';
import {
  auditOldBrandCollections,
  brandOfPrimitive,
  oldBrandOfCollection,
  rebindOldBrandCollections,
  withOldBrandCollections,
  type OldBrandScan,
} from '../src/brand-collections';
import { BRANDS } from '../src/brand-table';

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

function solid(bound?: string): Paint {
  return Object.freeze({
    type: 'SOLID',
    color: { r: 0, g: 0, b: 0 },
    opacity: 1,
    ...(bound == null ? {} : { boundVariables: Object.freeze({ color: Object.freeze(alias(bound)) }) }),
  }) as Paint;
}

function shadow(bound: string): Effect {
  return Object.freeze({
    type: 'DROP_SHADOW',
    color: { r: 0, g: 0, b: 0, a: 1 },
    offset: { x: 0, y: 1 },
    radius: 4,
    spread: 0,
    visible: true,
    blendMode: 'NORMAL',
    boundVariables: Object.freeze({ color: Object.freeze(alias(bound)) }),
  }) as Effect;
}

// 옛 브랜드 컬렉션의 변수 — 키는 라이브러리 CoUI 의 것과 다르다(다른 컬렉션이다).
const U_PRIC = 'VariableID:u-pric/1:1'; // Unibook color/primary-container
const U_SURF = 'VariableID:u-surf/1:2'; // Unibook color/surface
const U_ODD = 'VariableID:u-odd/1:3'; //   Unibook color/legacy-only — CoUI 에 짝이 없다
const U_CLASH = 'VariableID:u-clash/1:4'; // Unibook color/type-clash — CoUI 의 같은 이름은 FLOAT
const M_PRI = 'VariableID:m-pri/2:1'; //   Medibooks color/primary
const A_PRI = 'VariableID:a-pri/3:1'; //   Acme(코드 브랜드 아님) color/primary
// 라이브러리 CoUI 의 변수.
const K_PRIC = 'VariableID:kk-pric/9:1';
const K_SURF = 'VariableID:kk-surf/9:2';
const K_PRI = 'VariableID:kk-pri/9:3';
// 원시값.
const P_UNI = 'VariableID:p-uni/5:1'; //   color/unibook/blue/500
const P_COUI = 'VariableID:p-coui/5:2'; // color/coui/red/50 — 브랜드 원시값이 아니다
const L1 = 'VariableID:local-accent';

interface NodeSpec {
  id: string;
  name: string;
  type: string;
  fills?: Paint[] | 'mixed';
  strokes?: Paint[];
  effects?: Effect[];
  children?: Any[];
  overrides?: { id: string; overriddenFields: string[] }[];
  main?: { remote: boolean };
  segments?: { start: number; end: number; fills: Paint[] }[];
}

interface World {
  figma: Any;
  writes: string[];
  imports: string[];
  nodes: Map<string, Any>;
  variables: Map<string, Any>;
  extension: Any;
  styles: Any[];
}

const kFont = { family: 'Pretendard', style: 'Regular' };

function makeWorld(withOld = true): World {
  const mixed = Symbol('mixed');
  const w: World = { figma: null, writes: [], imports: [], nodes: new Map(), variables: new Map(), extension: null, styles: [] };
  let current: Any = null;
  let fontLoaded = false;
  const pageOf = new Map<string, string>();
  const paintAliases = (list: readonly Any[]): VariableAlias[] =>
    list.filter((p) => p.boundVariables?.color != null).map((p) => p.boundVariables.color);

  const node = (pageId: string, spec: NodeSpec): Any => {
    const state = { fills: spec.fills ?? [], strokes: spec.strokes ?? [], effects: spec.effects ?? [], segments: spec.segments ?? [] };
    const guard = (what: string): void => {
      w.writes.push(`${spec.id}:${what}`);
      if (current?.id !== pageOf.get(spec.id)) throw new Error(`${spec.id}: ${what} written off its page`);
      if (spec.type === 'TEXT' && !fontLoaded) throw new Error(`${spec.id}: ${what} written before its font was loaded`);
    };
    const n: Any = {
      id: spec.id,
      name: spec.name,
      type: spec.type,
      visible: true,
      children: spec.children,
      overrides: spec.overrides,
      async getMainComponentAsync() {
        return spec.main ?? null;
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
        const out: Any = {};
        if (state.fills === 'mixed') {
          const ranged = state.segments.reduce((acc: VariableAlias[], s) => acc.concat(paintAliases(s.fills)), []);
          if (ranged.length > 0) out.textRangeFills = ranged;
        } else if (paintAliases(state.fills).length > 0) out.fills = paintAliases(state.fills);
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

  const collections = new Map<string, Any>([
    ['C:uni', { id: 'C:uni', name: '1-1. Semantic/ Color · Unibook', remote: true, modes: [{ modeId: 'u-l', name: 'Light' }], defaultModeId: 'u-l', variableIds: [] }],
    ['C:medi', { id: 'C:medi', name: 'Semantic/ Color · Medibooks', remote: true, modes: [{ modeId: 'md-l', name: 'Light' }], defaultModeId: 'md-l', variableIds: [] }],
    ['C:acme', { id: 'C:acme', name: 'Semantic/ Color · Acme', remote: true, modes: [{ modeId: 'a-l', name: 'Light' }], defaultModeId: 'a-l', variableIds: [] }],
    ['C:coui', { id: 'C:coui', name: 'Semantic/ Color · CoUI', remote: true, modes: [{ modeId: 'k-l', name: 'Light' }], defaultModeId: 'k-l', variableIds: [K_PRIC, K_SURF, K_PRI] }],
    ['C:prim', { id: 'C:prim', name: 'Primitives', remote: true, modes: [{ modeId: 'p-v', name: 'Value' }], defaultModeId: 'p-v', variableIds: [] }],
    ['C:app', { id: 'C:app', name: 'App', remote: false, modes: [{ modeId: 'app-1', name: 'Mode 1' }], defaultModeId: 'app-1', variableIds: [L1] }],
  ]);

  const variable = (id: string, key: string, name: string, collection: string, remote = true, type = 'COLOR', values: Record<string, unknown> = {}): Any => {
    const v: Any = {
      id,
      key,
      name,
      remote,
      resolvedType: type,
      variableCollectionId: collection,
      valuesByMode: values,
      setValueForMode(modeId: string, value: unknown) {
        w.writes.push(`${id}:${modeId}`);
        if (w.extension.modes.some((m: Any) => m.modeId === modeId)) {
          const o = w.extension.variableOverrides;
          o[id] = { ...(o[id] ?? {}), [modeId]: value };
          return;
        }
        if (remote) throw new Error('Cannot modify a remote variable');
        values[modeId] = value;
      },
    };
    w.variables.set(id, v);
    return v;
  };
  variable(U_PRIC, 'u-pric', 'color/primary-container', 'C:uni');
  variable(U_SURF, 'u-surf', 'color/surface', 'C:uni');
  variable(U_ODD, 'u-odd', 'color/legacy-only', 'C:uni');
  variable(U_CLASH, 'u-clash', 'color/type-clash', 'C:uni');
  variable(M_PRI, 'm-pri', 'color/primary', 'C:medi');
  variable(A_PRI, 'a-pri', 'color/primary', 'C:acme');
  variable(K_SURF, 'kk-surf', 'color/surface', 'C:coui'); // 이미 이 파일에 있다
  variable(P_UNI, 'p-uni', 'color/unibook/blue/500', 'C:prim');
  variable(P_COUI, 'p-coui', 'color/coui/red/50', 'C:prim');
  variable(L1, 'local-accent', 'app/accent', 'C:app', false, 'COLOR', { 'app-1': alias(withOld ? U_SURF : K_SURF) });

  // 라이브러리에만 있고 가져오면 생기는 변수.
  const library: Record<string, () => Any> = {
    'kk-pric': () => w.variables.get(K_PRIC) ?? variable(K_PRIC, 'kk-pric', 'color/primary-container', 'C:coui'),
    'kk-surf': () => w.variables.get(K_SURF),
    'kk-pri': () => w.variables.get(K_PRI) ?? variable(K_PRI, 'kk-pri', 'color/primary', 'C:coui'),
    'kk-clash': () => variable('VariableID:kk-clash/9:9', 'kk-clash', 'color/type-clash', 'C:coui', true, 'FLOAT'),
  };

  const ext = {
    id: 'C:ext',
    name: 'Semantic/ Color · CoUI → Medibooks',
    remote: false,
    isExtension: true,
    rootVariableCollectionId: 'C:coui',
    defaultModeId: 'e-l',
    modes: [{ modeId: 'e-l', name: 'Light', parentModeId: 'k-l' }],
    variableIds: [K_SURF],
    // 이 파일이 확장의 덮어쓰기 값으로 Medibooks 컬렉션의 변수를 가리킨다.
    variableOverrides: (withOld ? { [K_SURF]: { 'e-l': alias(M_PRI) } } : {}) as Any,
  };
  w.extension = ext;
  collections.set(ext.id, ext);

  const style: Any = { id: 'S:accent', name: 'Accent fill', type: 'PAINT' };
  let stylePaints: Paint[] = [solid(withOld ? U_PRIC : K_PRIC)];
  Object.defineProperty(style, 'paints', {
    get: () => stylePaints,
    set: (v: Paint[]) => {
      w.writes.push('S:accent:paints');
      stylePaints = v;
    },
  });
  w.styles.push(style);

  const old = (id: string, fallback: string): string => (withOld ? id : fallback);
  const shell: Any = { id: 'p-shell', name: '000 shell', type: 'PAGE', children: [] };
  const home: Any = { id: 'p-home', name: 'Home', type: 'PAGE', children: [] };
  shell.children = [
    node('p-shell', { id: '1:1', name: 'Header', type: 'FRAME', fills: [solid(old(U_PRIC, K_PRIC))], strokes: [solid(old(U_SURF, K_SURF))] }),
    node('p-shell', { id: '1:2', name: 'Card', type: 'RECTANGLE', effects: [shadow(old(M_PRI, K_PRI))] }),
    node('p-shell', {
      id: '1:3',
      name: 'Mixed',
      type: 'TEXT',
      fills: 'mixed',
      segments: [
        { start: 0, end: 1, fills: [solid(old(U_PRIC, K_PRIC))] },
        { start: 1, end: 2, fills: [solid()] },
      ],
    }),
    // 라이브러리 인스턴스 — 배경은 이 파일이 덮어썼고, 글자색은 원본 그대로다.
    node('p-shell', {
      id: '2:1',
      name: 'Button',
      type: 'INSTANCE',
      main: { remote: true },
      overrides: [{ id: 'I2:1;1:1', overriddenFields: ['fills'] }],
      children: [
        node('p-shell', { id: 'I2:1;1:1', name: 'bg', type: 'FRAME', fills: [solid(old(U_PRIC, K_PRIC))] }),
        node('p-shell', { id: 'I2:1;1:2', name: 'fg', type: 'FRAME', fills: [solid(old(U_SURF, K_SURF))] }),
      ],
    }),
    node('p-shell', { id: '1:4', name: 'AlreadyCoui', type: 'FRAME', fills: [solid(K_SURF)] }),
    node('p-shell', { id: '1:5', name: 'AcmeBox', type: 'FRAME', fills: [solid(A_PRI)] }),
    node('p-shell', { id: '1:6', name: 'RampDirect', type: 'FRAME', fills: [solid(P_UNI)] }),
    node('p-shell', { id: '1:7', name: 'CouiRamp', type: 'FRAME', fills: [solid(P_COUI)] }),
    node('p-shell', { id: '1:8', name: 'Legacy', type: 'FRAME', fills: [solid(old(U_ODD, K_SURF))] }),
    node('p-shell', { id: '1:9', name: 'Clash', type: 'FRAME', fills: [solid(old(U_CLASH, K_SURF))] }),
  ];
  home.children = [node('p-home', { id: '4:1', name: 'Hero', type: 'FRAME', fills: [solid(old(M_PRI, K_PRI))] })];
  for (const p of [shell, home]) {
    p.loadAsync = async () => undefined;
    w.nodes.set(p.id, p);
  }
  current = home;

  w.figma = {
    mixed,
    root: { children: [shell, home] },
    get currentPage() {
      return current;
    },
    async setCurrentPageAsync(page: Any) {
      current = page;
    },
    async getNodeByIdAsync(id: string) {
      return w.nodes.get(id) ?? null;
    },
    async loadFontAsync() {
      fontLoaded = true;
    },
    async getLocalPaintStylesAsync() {
      return w.styles;
    },
    async getLocalEffectStylesAsync() {
      return [];
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
    teamLibrary: {
      async getAvailableLibraryVariableCollectionsAsync() {
        return [
          { key: 'lib-uni', name: 'Semantic/ Color · Unibook', libraryName: 'CoUI' },
          { key: 'lib-coui', name: 'Semantic/ Color · CoUI', libraryName: 'CoUI' },
        ];
      },
      async getVariablesInLibraryCollectionAsync(key: string) {
        if (key !== 'lib-coui') throw new Error(`read the wrong collection ${key}`);
        return [
          { name: 'color/primary-container', key: 'kk-pric', resolvedType: 'COLOR' },
          { name: 'color/surface', key: 'kk-surf', resolvedType: 'COLOR' },
          { name: 'color/primary', key: 'kk-pri', resolvedType: 'COLOR' },
          { name: 'color/type-clash', key: 'kk-clash', resolvedType: 'FLOAT' },
        ];
      },
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
        const make = library[key];
        if (make == null) throw new Error(`no library variable ${key}`);
        return make();
      },
      createVariableAlias(v: Any) {
        return alias(v.id);
      },
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
  console.log('selftest: brand-collections');

  // ── 1. 순수 판정 ──────────────────────────────────────────────────────────

  await check('옛 브랜드 컬렉션 — 코드 브랜드 목록에서, 번호 접두를 빼고', () => {
    assert(BRANDS.brands.some((b) => b.displayName === 'Unibook'), 'fixture assumes the Unibook code brand');
    assertEq(oldBrandOfCollection('1-1. Semantic/ Color · Unibook')?.displayName, 'Unibook', 'numbered Unibook');
    assertEq(oldBrandOfCollection('Semantic/ Color · Medibooks')?.displayName, 'Medibooks', 'Medibooks');
    assertEq(oldBrandOfCollection('Semantic/ Color · CoUI'), null, 'the library brand is the target, not an old collection');
    assertEq(oldBrandOfCollection('1-1. Semantic/ Color · CoUI'), null, 'numbered library brand');
    assertEq(oldBrandOfCollection('Semantic/ Color · Acme'), null, 'a brand not in brands.json is ignored');
    const doc = { ...BRANDS, brands: [{ id: 'acme', displayName: 'Acme', overrides: [] }] };
    assertEq(oldBrandOfCollection('Semantic/ Color · Acme', doc)?.displayName, 'Acme', 'the list decides, not a hard-coded name');
    assertEq(oldBrandOfCollection('Semantic/ Color · Unibook', doc), null, 'and only the list');
  });

  await check('브랜드 원시값 — Primitives 의 color/<브랜드 id>/…', () => {
    assertEq(brandOfPrimitive('Primitives', 'color/unibook/blue/500')?.displayName, 'Unibook', 'unibook ramp');
    assertEq(brandOfPrimitive('0. Primitives', 'color/medibooks/red/50')?.displayName, 'Medibooks', 'numbered Primitives');
    assertEq(brandOfPrimitive('Primitives', 'color/coui/red/50'), null, 'the library ramp is not a brand ramp');
    assertEq(brandOfPrimitive('Semantic/ Color · CoUI', 'color/unibook/x'), null, 'only Primitives');
  });

  // ── 2. 점검 ───────────────────────────────────────────────────────────────

  let scan: OldBrandScan | null = null;
  await check('점검: 옛 브랜드 컬렉션의 변수 · 짝 · 원시값 — 아무것도 가져오지 않는다', async () => {
    const w = makeWorld();
    install(w);
    const s = await auditOldBrandCollections();
    assert('findings' in s, `scan failed: ${JSON.stringify(s)}`);
    scan = s as OldBrandScan;
    assertEq(
      scan.findings.map((f) => `${f.brand}:${f.name}:${f.targetKey ?? 'none'}`),
      [
        'Unibook:color/legacy-only:none',
        'Unibook:color/primary-container:kk-pric',
        'Unibook:color/surface:kk-surf',
        'Unibook:color/type-clash:none',
        'Medibooks:color/primary:kk-pri',
      ],
      'findings',
    );
    assert(scan.findings.every((f) => f.brand !== 'Acme'), 'Acme ignored');
    assertEq(scan.primitives.map((p) => p.name), ['color/unibook/blue/500'], 'brand primitives only');
    assertEq(w.imports, [], 'the audit imports nothing');
    assertEq(w.writes, [], 'the audit writes nothing');
    const clash = scan.findings.find((f) => f.name === 'color/type-clash');
    assert(clash?.missing?.includes('타입이 다르다') === true, `clash reason: ${clash?.missing}`);
  });

  await check('점검: 보고 줄과 목록', () => {
    const base = buildConsumerAuditReport([], { sans: 'Pretendard' } as Any, { scope: '현재 페이지', pageCount: 1, textNodes: 0 });
    const report = withOldBrandCollections(base, scan as OldBrandScan);
    const s = report.oldBrandCollections!;
    // 옮길 곳: Header fills+strokes · Card · Mixed · Button bg · Hero 노드 6, 스타일 1, 별칭 2(로컬 · 덮어쓰기).
    assertEq({ places: s.places, unmatched: s.unmatched, library: s.library, primitives: s.primitivePlaces }, { places: 9, unmatched: 2, library: 1, primitives: 1 }, 'summary');
    const lines = formatConsumerAudit(report);
    assert(lines.includes('글자 경고 없음 ✅'), `no clean claim: ${lines.join(' | ')}`);
    assert(lines.some((l) => l.startsWith('⚠ 옛 브랜드 컬렉션에 묶인 곳 11 (변수 5개, 파일 전체)')), lines.join(' | '));
    assert(lines.some((l) => l.includes('짝이 없어 옮기지 않는 곳 2 — color/legacy-only, color/type-clash')), lines.join(' | '));
    assert(lines.some((l) => l.startsWith('⚠ 브랜드 원시값에 직접 묶인 곳 1 (변수 1개)')), lines.join(' | '));
    assert(lines.includes('  000 shell · "RampDirect" · fills · color/unibook/blue/500'), lines.join(' | '));
    assertEq(report.groups.map((g) => g.category), ['old-brand', 'old-brand', 'old-brand', 'old-brand', 'old-brand', 'brand-primitive'], 'rows');
    const pric = report.groups.find((g) => g.signature.includes('color/primary-container'))!;
    assertEq(pric.signature, '1-1. Semantic/ Color · Unibook / color/primary-container → Semantic/ Color · CoUI / color/primary-container', 'signature');
    assert(pric.action.includes('「옛 브랜드 컬렉션 다시 연결」로 참조 4곳(노드 3 · 스타일 1)'), pric.action);
    const clean = withOldBrandCollections(base, { findings: [], primitives: [], libraryError: null, libraryName: null });
    assert(formatConsumerAudit(clean).includes('옛 브랜드 컬렉션에 묶인 곳 없음 — 파일 전체'), 'silence is said');
    assert(formatConsumerAudit(withOldBrandCollections(base, { error: 'boom' })).includes('⚠ 옛 브랜드 컬렉션은 보지 못했다 — boom'), 'failure is said');
  });

  // ── 3. 다시 연결 ──────────────────────────────────────────────────────────

  const w = makeWorld();
  let log: string[] = [];
  await check('다시 연결: 노드 · 스타일 · 별칭 · 덮어쓴 인스턴스 필드를 같은 이름의 CoUI 변수로', async () => {
    install(w);
    log = await rebindOldBrandCollections();
    const fill = (id: string): string | undefined => boundId(w.nodes.get(id).fills[0]);
    assertEq(fill('1:1'), K_PRIC, 'Header fills');
    assertEq(boundId(w.nodes.get('1:1').strokes[0]), K_SURF, 'Header strokes');
    assertEq(w.nodes.get('1:2').effects[0].boundVariables.color.id, K_PRI, 'Card shadow (Medibooks → CoUI)');
    assertEq(w.nodes.get('1:3').getStyledTextSegments(['fills']).map((s: Any) => boundId(s.fills[0])), [K_PRIC, undefined], 'range fills');
    assertEq(fill('I2:1;1:1'), K_PRIC, 'overridden instance field');
    assertEq(fill('4:1'), K_PRI, 'Hero on the other page');
    assertEq(boundId(w.styles[0].paints[0]), K_PRIC, 'paint style');
    assertEq((w.variables.get(L1).valuesByMode['app-1'] as Any).id, K_SURF, 'local alias');
    assertEq(w.extension.variableOverrides[K_SURF]['e-l'].id, K_PRI, 'extension override value');
    assertEq([...w.imports].sort(), ['kk-pri', 'kk-pric', 'kk-surf'], 'imports only the counterparts that exist and match');
  });

  await check('다시 연결: 라이브러리 안 · CoUI · 목록 밖 브랜드 · 원시값 · 짝 없는 이름은 그대로', () => {
    const fill = (id: string): string | undefined => boundId(w.nodes.get(id).fills[0]);
    assertEq(fill('I2:1;1:2'), U_SURF, 'library-held binding stays');
    assertEq(fill('1:4'), K_SURF, 'CoUI binding stays');
    assertEq(fill('1:5'), A_PRI, 'Acme stays');
    assertEq(fill('1:6'), P_UNI, 'brand primitive stays');
    assertEq(fill('1:7'), P_COUI, 'CoUI primitive stays');
    assertEq(fill('1:8'), U_ODD, 'no-counterpart stays');
    assertEq(fill('1:9'), U_CLASH, 'type-clash stays');
    const untouched = ['I2:1;1:2', '1:4', '1:5', '1:6', '1:7', '1:8', '1:9'];
    assert(!w.writes.some((x) => untouched.some((id) => x.startsWith(`${id}:`))), w.writes.join(' '));
  });

  await check('다시 연결: 센 것 · 다시 읽어 확인 · 보고 · 다시 열라는 안내', () => {
    const text = log.join(' | ');
    assert(log.includes('✓ 다시 연결 — 채움 3 · 선 1 · 효과 1 · 글자 구간 채움 1 · 스타일 1 · 별칭 2'), text);
    assert(log.some((l) => l.startsWith('✓ 다시 읽어 확인 — 옛 브랜드 컬렉션을 참조하는')), text);
    assert(log.some((l) => l.startsWith('⚠ 짝이 없어 옮기지 않은 곳 2 — color/legacy-only, color/type-clash')), text);
    assert(log.some((l) => l.startsWith('⚠ 라이브러리 컴포넌트 안 1곳은 덮어쓰지 않았다')), text);
    assert(log.some((l) => l.startsWith('⚠ 브랜드 원시값에 직접 묶인 곳 1 (변수 1개)')), text);
    assert(log.includes('  000 shell · "RampDirect" · fills · color/unibook/blue/500'), text);
    assert(log.some((l) => l.includes('「이름으로 다시 맞추기」')), 'reopen + resync hint');
    assert(!log.some((l) => l.includes('written')), text);
  });

  await check('다시 연결: 옛 브랜드 컬렉션이 없으면 아무것도 가져오거나 쓰지 않는다', async () => {
    const clean = makeWorld(false);
    install(clean);
    const out = await rebindOldBrandCollections();
    assert(out.some((l) => l.startsWith('옛 브랜드 컬렉션에 묶인 곳이 없다')), out.join(' | '));
    assertEq(clean.writes, [], 'no writes');
    assertEq(clean.imports, [], 'no imports');
  });

  // ── 4. 배선 ───────────────────────────────────────────────────────────────

  await check('code.ts 가 명령을 라우팅하고 점검에 옛 브랜드 컬렉션을 더한다', () => {
    const code = codeLines(read('code.ts'));
    assert(/msg\.type === 'rebind-old-brand-collections'\) \{\s*[^}]*await rebindOldBrandCollections\(\)/.test(code), 'rebind branch');
    assert(/withOldBrandCollections\(\s*withLibraryCopies\([\s\S]*?await auditOldBrandCollections\(\),\s*\)/.test(code), 'audit merges the brand scan');
  });

  await check('ui.html — 버튼 · 핸들러 · 메시지 · 비활성 목록 · 「옛 사본 다시 연결」 옆', () => {
    const ui = read('ui.html');
    const id = 'rebind-old-brand-collections';
    const list = /const buttons = \[([\s\S]*?)\]\.map/.exec(ui)?.[1] ?? '';
    assert(new RegExp(`id="${id}" class="secondary">옛 브랜드 컬렉션 다시 연결</button>`).test(ui), 'button with its Korean label');
    assert(new RegExp(`getElementById\\('${id}'\\)\\.onclick`).test(ui), 'click handler');
    assert(new RegExp(`pluginMessage: \\{ type: '${id}' \\}`).test(ui), 'posted message');
    assert(list.includes(`'${id}'`), 'disabled while busy');
    const row = /<div class="row">\s*<button id="consumer-audit"[\s\S]*?<\/div>/.exec(ui)?.[0] ?? '';
    assert(row.includes('id="rebind-library-copies"') && row.includes(`id="${id}"`), 'same row as the copy rebind');
  });

  await check('package.json 의 selftest 체인에 들어 있다', () => {
    const pkg = JSON.parse(read('package.json')) as { scripts: Record<string, string> };
    assert(pkg.scripts['selftest:brand-collections'] != null, 'selftest:brand-collections script');
    assert(/npm run selftest:brand-collections\b/.test(pkg.scripts.selftest), 'aggregate selftest runs it');
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
