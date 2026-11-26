// Self-test for the brand extension command — `src/brand-table.ts` (the code
// brands' value tables and what applying one takes) and the writes in
// `src/collection-overrides.ts` (`applyBrandExtension`, `fillBrandOverrides`,
// the brand branch of `resyncOverridesByName`) — driving the REAL functions
// against a fake Figma.
//
// What the fake can and cannot say. It stores what `setValueForMode` is given,
// so it holds the decisions this plugin makes: which variable gets which colour
// in which mode, matching by name, what is left alone, what is reported. It does
// NOT know Figma's own behaviour: whether an extension can be created at all
// (Figma decides by plan), that a reopened file drops the overrides of variables it stopped
// using, that an override really paints the library's components. Those are
// checked by hand in a consumer file (the PR names what was not).

import {
  BRANDS,
  brandExtensionNameFor,
  brandOfExtension,
  findBrand,
  planBrandFill,
  sameColor,
  type BrandColor,
  type BrandTable,
} from '../src/brand-table';
import { pointScopeAtBrand } from '../src/brand-scope-modes';
import { applyBrandExtension, resyncOverridesByName } from '../src/collection-overrides';

declare const process: { cwd(): string; exit(code: number): never };
declare function require(id: string): {
  readFileSync(path: string, encoding: string): string;
  join(...parts: string[]): string;
};
const { readFileSync } = require('fs');
const { join } = require('path');

function assert(ok: unknown, message: string): asserts ok {
  if (!ok) throw new Error(message);
}

function assertEq(actual: unknown, expected: unknown, message: string): void {
  const a = JSON.stringify(actual);
  const e = JSON.stringify(expected);
  if (a !== e) throw new Error(`${message}\n   got      ${a}\n   expected ${e}`);
}

async function rejects(run: () => Promise<unknown>): Promise<string> {
  try {
    await run();
  } catch (error) {
    return error instanceof Error ? error.message : String(error);
  }
  throw new Error('expected a rejection');
}

const MODES = ['Light', 'Dark', 'HCLight', 'HCDark'] as const;
const LIBRARY = BRANDS.library.collection;
const MEDIBOOKS = findBrand('Medibooks')!;
const UNIBOOK = findBrand('unibook')!;

const rgb = (hex: string): BrandColor => ({
  r: parseInt(hex.slice(0, 2), 16) / 255,
  g: parseInt(hex.slice(2, 4), 16) / 255,
  b: parseInt(hex.slice(4, 6), 16) / 255,
  a: 1,
});

// ── 세계 ─────────────────────────────────────────────────────────────────────

type Overrides = Record<string, Record<string, unknown>>;

interface FakeVariable {
  id: string;
  name: string;
  resolvedType: string;
  remote: boolean;
  variableCollectionId: string;
  setValueForMode(modeId: string, value: unknown): void;
}

interface FakeExtension {
  id: string;
  name: string;
  isExtension: true;
  rootVariableCollectionId: string;
  modes: { modeId: string; name: string; parentModeId: string }[];
  variableIds: string[];
  variableOverrides: Overrides;
}

/**
 * A consumer file. [inFile] names the library variables the file carries — the
 * ones components in the file use; the others are not in the file, so an
 * extension of the collection has no variable of that name to write to. A table
 * row for one of those cannot be written until something brings it in.
 */
function world(
  opts: {
    inFile?: readonly string[];
    libraryNames?: string[];
    rootName?: string;
    types?: Record<string, string>;
    dropWritesTo?: string;
    mismatched?: string;
    enterprise?: boolean;
  } = {},
) {
  const rootName = opts.rootName ?? LIBRARY;
  const root = { id: 'C:root', key: 'key-sem', name: rootName, isExtension: false, remote: true };
  const collections: Array<typeof root | FakeExtension> = [];
  const variables = new Map<string, FakeVariable>();
  const extended: string[] = [];
  const created: FakeExtension[] = [];

  const variableFor = (ext: FakeExtension, name: string): FakeVariable => {
    // A variable belongs to one extension — each extension has its own copies.
    const id = vid(ext, name);
    const existing = variables.get(id);
    if (existing != null) return existing;
    const v: FakeVariable = {
      id,
      name,
      resolvedType: opts.types?.[name] ?? 'COLOR',
      remote: true,
      variableCollectionId: root.id,
      setValueForMode(modeId: string, value: unknown) {
        if (opts.mismatched === name) throw new Error('in setValueForMode: Mismatched variable type');
        if (opts.dropWritesTo === name) return;
        ext.variableOverrides[id] = { ...(ext.variableOverrides[id] ?? {}), [modeId]: value };
      },
    };
    variables.set(id, v);
    return v;
  };

  const present = opts.inFile ?? MEDIBOOKS.overrides.map((o) => o.name);
  const makeExtension = (name: string): FakeExtension => {
    const ext: FakeExtension = {
      id: `C:ext:${created.length}`,
      name,
      isExtension: true,
      rootVariableCollectionId: root.id,
      modes: MODES.map((m, i) => ({ modeId: `e${i}`, name: m, parentModeId: `m${i}` })),
      variableIds: [],
      variableOverrides: {},
    };
    ext.variableIds = present.map((n) => variableFor(ext, n).id);
    created.push(ext);
    collections.push(ext);
    return ext;
  };

  (globalThis as unknown as { figma: unknown }).figma = {
    teamLibrary: {
      getAvailableLibraryVariableCollectionsAsync: async () =>
        (opts.libraryNames ?? ['CoUI']).map((libraryName, i) => ({
          key: i === 0 ? 'key-sem' : `key-sem-${i}`,
          name: LIBRARY,
          libraryName,
        })),
    },
    variables: {
      getLocalVariableCollectionsAsync: async () => collections,
      getVariableCollectionByIdAsync: async (id: string) =>
        id === root.id ? root : (collections.find((c) => c.id === id) ?? null),
      getVariableByIdAsync: async (id: string) => variables.get(id) ?? null,
      getLocalVariablesAsync: async () => [],
      extendLibraryCollectionByKeyAsync: async (key: string, name: string) => {
        if (opts.enterprise === false) {
          throw new Error('Cannot create extended collections outside of enterprise plan');
        }
        extended.push(`${key}:${name}`);
        return makeExtension(name);
      },
    },
  };
  return { collections, created, extended, variables, variableFor, makeExtension };
}

function vid(ext: { id: string }, name: string): string {
  return `${ext.id}|${name}`;
}

const valueAt = (ext: FakeExtension, name: string, mode: string): unknown =>
  ext.variableOverrides[vid(ext, name)]?.[`e${MODES.indexOf(mode as (typeof MODES)[number])}`];

// ── 표 ───────────────────────────────────────────────────────────────────────

function tableChecks(): void {
  assertEq(BRANDS.library, { brand: 'coui', collection: 'Semantic/ Color · CoUI', modes: [...MODES] }, 'the library collection and its modes');
  assertEq(BRANDS.brands.map((b) => b.id), ['unibook', 'medibooks', 'miracle-alarm'], 'the code brands beyond the library brand');

  for (const brand of BRANDS.brands) {
    assert(brand.overrides.length > 0, `${brand.id}: a table with rows`);
    const seen = new Set<string>();
    for (const row of brand.overrides) {
      assert(!seen.has(row.name), `${brand.id}: ${row.name} appears once`);
      seen.add(row.name);
      assert(row.name.startsWith('color/') || row.name.startsWith('effect/shadow/'), `${brand.id}: ${row.name} is a colour slot`);
      const modes = Object.keys(row.valuesByMode);
      assert(modes.length > 0 && modes.every((m) => (MODES as readonly string[]).includes(m)), `${brand.id}: ${row.name} modes ${modes}`);
      for (const c of Object.values(row.valuesByMode)) {
        for (const channel of [c.r, c.g, c.b, c.a]) assert(channel >= 0 && channel <= 1, `${brand.id}: ${row.name} channel ${channel}`);
      }
    }
    // 공용 그룹의 색은 어느 브랜드나 같다 — 표에 없다.
    assert(![...seen].some((n) => n.includes('category-') && !n.startsWith('color/on-category-')), `${brand.id}: no shared category slot`);
  }

  // 번들이 코드와 같은 값을 들고 있는지 — Dart 쪽 테스트가 Figma 에 넣어 둔 값과의 일치를 고정하고,
  // 여기서는 그 값 하나가 번들 표까지 왔는지 본다(낡은 표를 번들에 넣은 빌드를 잡는다).
  const primary = MEDIBOOKS.overrides.find((o) => o.name === 'color/primary')!;
  assertEq(primary.valuesByMode.Light, rgb('009260'), 'Medibooks primary, Light — the green the designer put in the DS file');
  assertEq(primary.valuesByMode.Dark, rgb('009260'), 'Medibooks primary keeps its saturated base in dark');

  const name = brandExtensionNameFor(MEDIBOOKS);
  assertEq(name, 'Semantic/ Color · CoUI → Medibooks', 'the extension name');
  assert(brandOfExtension(name)?.id === 'medibooks', 'the brand is read back off the name');
  assert(brandOfExtension(brandExtensionNameFor(UNIBOOK))?.id === 'unibook', 'and Unibook off its own');
  assert(brandOfExtension('Semantic/ Color · CoUI → Blue') === null, 'a designer-made extension is not a code brand');
  assert(brandOfExtension('Semantic/ Color · CoUI · Overrides') === null, 'nor the generic overrides one');
  assert(findBrand('medibooks') === MEDIBOOKS && findBrand(' MEDIBOOKS ') === MEDIBOOKS && findBrand('CoUI') === null, 'brand lookup by id or name; the library brand is no table');

  // planBrandFill — 이름으로 짝짓고, 이미 있는 값은 쓰지 않고, 짝이 없으면 쓰지 않는다.
  const table: BrandTable = {
    id: 't',
    displayName: 'T',
    overrides: [
      { name: 'color/a', valuesByMode: { Light: rgb('112233'), Dark: rgb('445566') } },
      { name: 'color/gone', valuesByMode: { Light: rgb('000000') } },
      { name: 'color/num', valuesByMode: { Light: rgb('000000') } },
      { name: 'color/b', valuesByMode: { Light: rgb('778899'), Nope: rgb('000000') } },
    ],
  };
  const modes = [
    { modeId: 'e0', name: 'Light' },
    { modeId: 'e1', name: 'Dark' },
  ];
  const vars = [
    { id: 'A', name: 'color/a', resolvedType: 'COLOR' },
    { id: 'N', name: 'color/num', resolvedType: 'FLOAT' },
    { id: 'B', name: 'color/b', resolvedType: 'COLOR' },
  ];
  const plan = planBrandFill(table, vars, modes, {
    A: { e0: { r: 17 / 255, g: 34 / 255, b: 51 / 255, a: 1 } }, // already right
    B: { e1: rgb('abcdef') }, // stray: the table states B in Light only
    Z: { e0: rgb('000000') }, // stray: not even a variable of the table
  });
  assertEq(plan.set.map((w) => `${w.name}@${w.modeName}`), ['color/a@Dark', 'color/b@Light'], 'only what is not already there is written');
  assert(plan.alreadyRight === 1, 'a value already in place is counted, not rewritten');
  assertEq(plan.absent, ['color/gone'], 'a row with no variable of that name is absent');
  assertEq(plan.notColor, ['color/num'], 'a same-named variable that is not a colour is not written');
  assertEq(plan.noMode, ['Nope'], 'a mode the extension lacks is named');
  assert(plan.strayOverrides === 2, `overrides the table does not state are counted, not removed (${plan.strayOverrides})`);
  assert(sameColor({ r: 1, g: 0, b: 0 }, { r: 1, g: 0, b: 0, a: 1 }) && !sameColor(undefined, rgb('000000')), 'sameColor: alpha defaults to 1; nothing is not a colour');
  console.log('brand table: ok');
}

// ── 명령 ─────────────────────────────────────────────────────────────────────

async function applyChecks(): Promise<void> {
  // 파일에는 표의 변수 중 일부만 있다 — 컴포넌트가 쓰는 것만.
  const inFile = MEDIBOOKS.overrides.slice(0, 20).map((o) => o.name);
  const w = world({ inFile });

  const log = await applyBrandExtension('Medibooks');
  assert(w.created.length === 1, 'one extension');
  const ext = w.created[0];
  assert(ext.name === 'Semantic/ Color · CoUI → Medibooks', `named after the library collection and the brand: ${ext.name}`);
  assertEq(w.extended, ['key-sem:Semantic/ Color · CoUI → Medibooks'], 'extended from the library collection by its key');

  // 표의 값이 이름이 같은 변수의 모드에 그대로 들어갔다.
  for (const row of MEDIBOOKS.overrides.slice(0, 20)) {
    for (const mode of MODES) {
      const want = row.valuesByMode[mode];
      const got = valueAt(ext, row.name, mode);
      if (want == null) assert(got === undefined, `${row.name} @ ${mode}: not stated by the table → not written`);
      else assert(sameColor(got, want), `${row.name} @ ${mode}: ${JSON.stringify(got)} ≠ ${JSON.stringify(want)}`);
    }
  }
  const wrote = MEDIBOOKS.overrides.slice(0, 20).reduce((n, o) => n + Object.keys(o.valuesByMode).length, 0);
  const rest = MEDIBOOKS.overrides.length - 20;
  assert(log[0].startsWith('브랜드: Medibooks'), `header: ${log[0]}`);
  assert(log.some((l) => l.startsWith('+ 확장 컬렉션 생성: Semantic/ Color · CoUI → Medibooks')), 'creation is logged');
  assert(
    log.some((l) => l.startsWith(`✓ ${ext.name}: Medibooks 값 넣음 ${wrote}개 (다시 읽어 확인 ${wrote}) · 이미 맞음 0 · 이 파일에 없는 변수 ${rest}`)),
    `summary: ${log.join(' | ')}`,
  );
  assert(log.some((l) => l.includes('이 파일에 없는 변수 —') && l.includes('이름으로 다시 맞추기')), 'the absent variables are named, with what to do');
  assert(
    w.variables.size === 20 && ext.variableIds.length === 20,
    'nothing is created for a variable the file does not have — a variable is the file\'s, not the plugin\'s',
  );

  // 다시 돌리면 컬렉션을 다시 만들지 않고 값도 다시 쓰지 않는다.
  const again = await applyBrandExtension('Medibooks');
  assert(w.created.length === 1 && w.extended.length === 1, 'the extension is not made twice');
  assert(again.some((l) => l.startsWith('= 이미 생성됨')), 'and says so');
  assert(
    again.some((l) => l.startsWith(`✓ ${ext.name}: Medibooks 값 넣음 0개 (다시 읽어 확인 0) · 이미 맞음 ${wrote}`)),
    `idempotent: ${again.join(' | ')}`,
  );

  // 연결은 건드리지 않는다 — 바인딩은 확장 컬렉션이 아니라 노드에 있고, 이 명령은 노드를 읽지도 않는다.
  const code = readFileSync(join(process.cwd(), 'src/collection-overrides.ts'), 'utf8')
    .split('\n')
    .filter((l) => !/^\s*(\/\/|\*|\/\*)/.test(l))
    .join('\n');
  assert(!/setBoundVariable|boundVariables|currentPage|selection/.test(code), 'the brand path never touches a node or a binding');
  console.log('apply brand extension: ok');
}

async function resyncChecks(): Promise<void> {
  // 한 모드만 말하는 행이 하나는 있어야 「표에 없는 덮어쓰기」를 시험할 수 있다.
  const partial = MEDIBOOKS.overrides.find((o) => Object.keys(o.valuesByMode).length < MODES.length)!;
  assert(partial != null, 'the Medibooks table has a row that states fewer than all four modes');
  const names = [...new Set([...MEDIBOOKS.overrides.slice(0, 10).map((o) => o.name), partial.name])];
  const w = world({ inFile: names });
  await applyBrandExtension('Medibooks');
  const ext = w.created[0];

  // 파일을 다시 열면 쓰지 않는 변수의 덮어쓰기가 정리된다(2026-11-01 실측) — 둘이 사라지고,
  // 컴포넌트가 들어와 변수 하나가 새로 생긴다.
  delete ext.variableOverrides[vid(ext, names[0])];
  delete ext.variableOverrides[vid(ext, names[1])];
  const comeBack = MEDIBOOKS.overrides[10].name;
  ext.variableIds.push(w.variableFor(ext, comeBack).id);
  const log = await resyncOverridesByName();
  for (const n of [names[0], names[1], comeBack]) {
    const row = MEDIBOOKS.overrides.find((o) => o.name === n)!;
    for (const [mode, want] of Object.entries(row.valuesByMode)) {
      assert(sameColor(valueAt(ext, n, mode), want), `${n} @ ${mode} is back, by name`);
    }
  }
  assert(log[0].startsWith(`✓ ${ext.name}: Medibooks 값 넣음 `), `the brand branch answered: ${log[0]}`);
  assert(!log.some((l) => l.includes('짝 없음')), 'the generic same-named-local path did not run for a code brand');

  // 표에 없는 덮어쓰기는 세기만 하고 지우지 않는다.
  const strayMode = MODES.find((m) => !(m in partial.valuesByMode))!;
  const strayId = `e${MODES.indexOf(strayMode)}`;
  ext.variableOverrides[vid(ext, partial.name)] ??= {};
  ext.variableOverrides[vid(ext, partial.name)][strayId] = rgb('123456');
  const l2 = await resyncOverridesByName();
  assert(sameColor(ext.variableOverrides[vid(ext, partial.name)][strayId], rgb('123456')), 'a value the table does not state is left as it was');
  assert(l2.some((l) => l.includes('표에 없는 덮어쓰기 1개')), `and counted: ${l2.join(' | ')}`);

  // 다른 브랜드의 확장은 그 브랜드의 표로 — 같은 파일에 둘이 있어도 섞지 않는다.
  const uniName = brandExtensionNameFor(UNIBOOK);
  const uni = w.makeExtension(uniName);
  uni.variableIds = [w.variableFor(uni, names[0]).id];
  await resyncOverridesByName();
  const uniRow = UNIBOOK.overrides.find((o) => o.name === names[0]);
  assert(uniRow != null, `Unibook states ${names[0]} too`);
  for (const [mode, want] of Object.entries(uniRow.valuesByMode)) {
    assert(sameColor(valueAt(uni, names[0], mode), want), `Unibook's extension gets Unibook's value: ${names[0]} @ ${mode}`);
  }
  assert(!sameColor(valueAt(uni, names[0], 'Light'), MEDIBOOKS.overrides[0].valuesByMode.Light), "and not Medibooks'");
  const medRow = MEDIBOOKS.overrides.find((o) => o.name === names[0])!;
  for (const [mode, want] of Object.entries(medRow.valuesByMode)) {
    assert(sameColor(valueAt(ext, names[0], mode), want), 'and Medibooks keeps its own');
  }
  console.log('resync by name: ok');
}

async function failureChecks(): Promise<void> {
  world();
  const unknown = await rejects(() => applyBrandExtension('Nope'));
  assert(unknown.includes('Nope') && unknown.includes('Unibook') && unknown.includes('Medibooks'), `unknown brand names the code brands: ${unknown}`);
  const library = await rejects(() => applyBrandExtension('CoUI'));
  assert(library.includes('CoUI'), 'the library brand is not a table — nothing to extend with');

  world({ libraryNames: [] });
  const none = await rejects(() => applyBrandExtension('Medibooks'));
  assert(none.includes('활성화된 라이브러리') && none.includes(LIBRARY), `no library: ${none}`);

  world({ libraryNames: ['CoUI', 'CoUI (copy)'] });
  const two = await rejects(() => applyBrandExtension('Medibooks'));
  assert(two.includes('CoUI, CoUI (copy)') && two.includes('고르지'), `two libraries are not guessed between: ${two}`);

  const plan = world({ enterprise: false });
  const enterprise = await rejects(() => applyBrandExtension('Medibooks'));
  assert(enterprise.includes('Enterprise') && plan.created.length === 0, `a plan refusal is explained: ${enterprise}`);

  // 이름은 브랜드의 확장인데 원본이 다른 컬렉션이면 쓰지 않는다.
  const stray = world({ rootName: 'Something else' });
  stray.makeExtension(brandExtensionNameFor(MEDIBOOKS));
  const wrongRoot = await applyBrandExtension('Medibooks');
  assert(wrongRoot.some((l) => l.startsWith('⚠') && l.includes('Something else')), `a wrong root is named: ${wrongRoot.join(' | ')}`);
  assert(Object.keys(stray.created[0].variableOverrides).length === 0, 'and nothing is written');

  // 던지지 않았는데 들어가지 않은 값은 다시 읽어 드러난다.
  const target = MEDIBOOKS.overrides[0].name;
  const dropped = world({ inFile: [target], dropWritesTo: target });
  const droppedLog = await applyBrandExtension('Medibooks');
  const n = Object.keys(MEDIBOOKS.overrides[0].valuesByMode).length;
  assert(
    droppedLog.some((l) => l.startsWith(`⚠ ${dropped.created[0].name}: Medibooks 값 넣음 ${n}개 (다시 읽어 확인 0)`)),
    `read-back: ${droppedLog.join(' | ')}`,
  );

  // 같은 키의 사본이 둘이라 거부된 변수는 원인과 고치는 명령을 함께 적는다.
  world({ inFile: [target], mismatched: target });
  const mismatch = await applyBrandExtension('Medibooks');
  assert(mismatch.some((l) => l.startsWith('⚠') && l.includes('Mismatched variable type') && l.includes('「옛 사본 다시 연결」')), `mismatch is explained: ${mismatch.join(' | ')}`);

  // 같은 이름의 변수가 색이 아니면 쓰지 않는다.
  world({ inFile: [target], types: { [target]: 'FLOAT' } });
  const notColor = await applyBrandExtension('Medibooks');
  assert(notColor.some((l) => l.includes('색이 아닌 변수라 건너뜀') && l.includes(target)), `a non-colour is skipped: ${notColor.join(' | ')}`);

  // 확장 컬렉션이 없으면 다시 맞출 것도 없다 — 브랜드 탭으로 안내한다.
  world();
  const empty = await resyncOverridesByName();
  assert(empty.length === 1 && empty[0].startsWith('이 파일에 확장 컬렉션이 없다') && empty[0].includes('브랜드 확장 컬렉션 만들기'), `no extension: ${empty[0]}`);
  console.log('failures are loud and name the cause: ok');
}

// ── 모드 ─────────────────────────────────────────────────────────────────────
//
// 확장을 만든 것만으로는 화면이 바뀌지 않는다 — 노드가 원래 컬렉션의 모드를 읽는 동안에는
// CoUI 색 그대로다(시험 소비 파일에서 실측). 가짜는 Figma 처럼 모드를 컬렉션 계열마다 하나만
// 들고 있게 한다: 확장의 모드를 지정하면 같은 원본 계열의 다른 키가 빠진다.

interface FakeNode {
  id: string;
  name: string;
  explicitVariableModes: Record<string, string>;
  children: FakeNode[];
  writes: number;
  setExplicitVariableModeForCollection(collection: { id: string }, modeId: string): void;
  findAll(pred: (n: FakeNode) => boolean): FakeNode[];
}

function fakeNode(id: string, worn: Record<string, string> = {}, children: FakeNode[] = [], family: () => Set<string>): FakeNode {
  const n: FakeNode = {
    id,
    name: id,
    explicitVariableModes: { ...worn },
    children,
    writes: 0,
    setExplicitVariableModeForCollection(collection, modeId) {
      const next: Record<string, string> = {};
      for (const [k, v] of Object.entries(n.explicitVariableModes)) if (!family().has(k)) next[k] = v;
      next[collection.id] = modeId;
      n.explicitVariableModes = next;
      n.writes++;
    },
    findAll(pred) {
      const out: FakeNode[] = [];
      const walk = (x: FakeNode): void => {
        for (const c of x.children) {
          if (pred(c)) out.push(c);
          walk(c);
        }
      };
      walk(n);
      return out;
    },
  };
  return n;
}

function scene(w: ReturnType<typeof world>, build: (node: (id: string, worn?: Record<string, string>, children?: FakeNode[]) => FakeNode) => FakeNode[], selection: string[] = []) {
  const family = (): Set<string> => new Set(['C:root', ...w.collections.filter((c) => c.isExtension).map((c) => c.id)]);
  const node = (id: string, worn: Record<string, string> = {}, children: FakeNode[] = []): FakeNode => fakeNode(id, worn, children, family);
  const page = node('page', {}, build(node));
  (page as FakeNode & { selection: FakeNode[] }).selection = [];
  const all = [page, ...page.findAll(() => true)];
  (page as FakeNode & { selection: FakeNode[] }).selection = selection.map((id) => all.find((x) => x.id === id)!);
  (globalThis as unknown as { figma: { currentPage: unknown } }).figma.currentPage = page;
  const byId = (id: string): FakeNode => all.find((x) => x.id === id)!;
  return { page, byId, all };
}

async function modeChecks(): Promise<void> {
  // 확장이 없으면 모드를 지정할 곳이 없다 — 조용히 넘어가지 않는다.
  const bare = world();
  scene(bare, (node) => [node('frame', { 'C:root': 'm0' })]);
  const missing = await pointScopeAtBrand('Medibooks');
  assert(missing.length === 1 && missing[0].startsWith('⚠') && missing[0].includes(brandExtensionNameFor(MEDIBOOKS)), `no extension: ${missing.join(' | ')}`);

  // 선택이 없으면 현재 페이지 — 원래 컬렉션의 모드를 쓰는 노드는 같은 부모 모드로, 페이지는 기본 모드로.
  const w = world();
  const ext = w.makeExtension(brandExtensionNameFor(MEDIBOOKS));
  const s = scene(w, (node) => [
    node('light', { 'C:root': 'm0' }, [node('inner')]),
    node('dark', { 'C:root': 'm1' }),
    node('other', { 'C:else': 'x1' }),
    node('plain'),
  ]);
  const log = await pointScopeAtBrand('Medibooks');
  assertEq(s.byId('page').explicitVariableModes, { [ext.id]: 'e0' }, 'the page gets the extension mode of the default parent mode');
  assertEq(s.byId('light').explicitVariableModes, { [ext.id]: 'e0' }, 'Light moves to the extension Light');
  assertEq(s.byId('dark').explicitVariableModes, { [ext.id]: 'e1' }, 'Dark moves to the extension Dark');
  assertEq(s.byId('other').explicitVariableModes, { 'C:else': 'x1' }, 'a mode of another collection is left alone');
  assert(s.byId('inner').writes === 0 && s.byId('plain').writes === 0, 'a node that inherits is not written — it reads its parent');
  assert(log.some((l) => l.startsWith('✓ 모드: 현재 페이지') && l.includes('옮김 2곳') && l.includes('새로 지정 1곳')), `page log: ${log.join(' | ')}`);

  // 다시 돌리면 쓰지 않는다.
  const before = s.all.map((n) => n.writes).join(',');
  const again = await pointScopeAtBrand('Medibooks');
  assert(s.all.map((n) => n.writes).join(',') === before, 'idempotent — nothing is rewritten');
  assert(again.some((l) => l.startsWith('= 이미')), `says so: ${again.join(' | ')}`);

  // 선택이 있으면 선택한 레이어만.
  const ws = world();
  const extS = ws.makeExtension(brandExtensionNameFor(MEDIBOOKS));
  const sel = scene(ws, (node) => [node('picked', {}, [node('child', { 'C:root': 'm1' })]), node('left', { 'C:root': 'm1' })], ['picked']);
  const selLog = await pointScopeAtBrand('Medibooks');
  assertEq(sel.byId('picked').explicitVariableModes, { [extS.id]: 'e0' }, 'the selected top gets the default');
  assertEq(sel.byId('child').explicitVariableModes, { [extS.id]: 'e1' }, 'its descendant moves with its own parent mode');
  assertEq(sel.byId('left').explicitVariableModes, { 'C:root': 'm1' }, 'outside the selection is left alone');
  assert(sel.byId('page').writes === 0, 'the page is not the scope when there is a selection');
  assert(selLog.some((l) => l.startsWith('✓ 모드: 선택한 레이어 1개')), `selection log: ${selLog.join(' | ')}`);

  // 다른 브랜드의 확장 모드를 쓰던 화면도 이 브랜드로 옮긴다 — 같은 부모 모드로.
  const wb = world();
  const uni = wb.makeExtension(brandExtensionNameFor(UNIBOOK));
  const med = wb.makeExtension(brandExtensionNameFor(MEDIBOOKS));
  const sb = scene(wb, (node) => [node('uni-dark', { [uni.id]: 'e1' })]);
  await pointScopeAtBrand('Medibooks');
  assertEq(sb.byId('uni-dark').explicitVariableModes, { [med.id]: 'e1' }, 'Unibook Dark moves to Medibooks Dark');
  await pointScopeAtBrand('unibook');
  assertEq(sb.byId('uni-dark').explicitVariableModes, { [uni.id]: 'e1' }, 'and back');

  // 노드의 연결은 읽지도 쓰지도 않는다.
  const src = readFileSync(join(process.cwd(), 'src/brand-scope-modes.ts'), 'utf8')
    .split('\n')
    .filter((l) => !/^\s*(\/\/|\*|\/\*)/.test(l))
    .join('\n');
  assert(!/setBoundVariable|boundVariables|setValueForMode/.test(src), 'the mode step touches modes only — no binding, no value');
  console.log('point the scope at the brand: ok');
}

// ── 배선 ─────────────────────────────────────────────────────────────────────

function wiringChecks(): void {
  const read = (rel: string): string => readFileSync(join(process.cwd(), rel), 'utf8');
  const lines = (src: string): string => src.split('\n').filter((l) => !/^\s*(\/\/|\*|\/\*)/.test(l)).join('\n');
  const code = lines(read('code.ts'));
  assert(/msg\.type === 'apply-brand-extension' && msg\.brandName\) \{\s*[^}]*await applyBrandExtension\(msg\.brandName\)/.test(code), 'code.ts routes apply-brand-extension');
  assert(/await applyBrandExtension\(msg\.brandName\)[\s\S]{0,400}?await pointScopeAtBrand\(msg\.brandName\)/.test(code), 'and then points the scope at the brand');
  assert(/msg\.type === 'list-brands'\) \{[\s\S]*?BRANDS\.brands\.map\(/.test(code), 'the dropdown lists the code brands this build carries');
  assert(!/rebind-brand|rebindToBrand|discoverBrands/.test(code), 'the old connection-swapping command is gone from the router');

  const ui = read('ui.html');
  assert(/id="apply-brand-extension"/.test(ui), 'button');
  assert(/getElementById\('apply-brand-extension'\)\.onclick/.test(ui), 'handler');
  assert(/pluginMessage: \{ type: 'apply-brand-extension', brandName \}/.test(ui), 'message');
  const list = /const buttons = \[([\s\S]*?)\]\.map/.exec(ui)?.[1] ?? '';
  assert(list.includes("'apply-brand-extension'"), 'disabled while busy');
  const start = ui.indexOf('<section data-tab="brand"');
  const end = ui.indexOf('</section>', start);
  const at = ui.indexOf('id="apply-brand-extension"');
  assert(start >= 0 && at > start && at < end, 'lives in the brand tab');
  assert(!/rebind-brand/.test(ui), 'the old command is gone from the UI');

  const pkg = JSON.parse(read('package.json')) as { scripts: Record<string, string> };
  assert(pkg.scripts.selftest.includes('npm run selftest:brand-extension'), 'the selftest chain runs this file — CI runs only what the chain names');
  assert(pkg.scripts['selftest:brand-extension']?.includes('scripts/selftest-brand-extension.ts'), 'script entry');
  assert(!('selftest:rebind-brand' in pkg.scripts), 'and not the old one');
  console.log('wiring: ok');
}

async function main(): Promise<void> {
  tableChecks();
  await applyChecks();
  await resyncChecks();
  await failureChecks();
  await modeChecks();
  wiringChecks();
  console.log('\nAll brand-extension self-tests passed.');
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
