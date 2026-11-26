/// <reference types="@figma/plugin-typings" />

// Self-test for the entry source hash — `scripts/entry-source-hash.mjs` (번들 단계가 import 그래프의
// 닫힘으로 엔트리별 해시를 굽는다) 와 `src/entry-source.ts` · `src/content-hash.ts` (런타임이 그 표를
// 읽어 레시피를 만든다).
//
// 이 해시가 틀릴 수 있는 방향은 둘이고 **하나는 눈에 안 보인다**:
//
//   - 과잉 무효화: 고치지 않은 엔트리가 낡음으로 나온다. 비용이 들 뿐 캔버스는 맞다.
//   - 과소 무효화: 그림이 바뀌는 수정에 어떤 엔트리의 해시도 안 움직인다. 캔버스는 옛 그림인데
//     `⏭ skipped — unchanged` 로 보고된다.
//
// 그래서 아래 검사는 "무관한 파일을 고쳐도 안 움직인다" 와 "닫힘 안의 파일을 고치면 움직인다" 를 한
// 쌍으로 하고, 각 검사를 **회귀 주입**(간선 하나 제거 · 번들 출력 텍스트를 해시에 되돌림)으로 실제로
// 실패시켜 본다 — 통과만 하는 검사는 어떤 구현에서도 통과하는 검사일 수 있다.
//
// 번들러: 실제 번들과 같은 진입점 · 타깃으로 esbuild 를 돌린다. 캔버스 · Figma 접속은 없다.

import * as esbuild from 'esbuild';
import { REGISTRY, SOURCE_GROUPS } from '../src/registry';
import { entryContentHashOf } from '../src/content-hash';
import { entrySourceHashOf, entrySourceKeysOf } from '../src/entry-source';
import type { RegistryEntry } from '../src/helpers';
import {
  bundleGraph,
  checkDeclarations,
  closureOf,
  defaultConfig,
  entrySourceHashes,
  hashFiles,
  kNonDrawingModules,
  kPipelineGlue,
  kPipelineRoots,
  moduleGraph,
  registryKeyModules,
  toolchainOf,
  type EntrySourceHashes,
  type HashConfig,
  type ModuleGraph,
} from './entry-source-hash.mjs';

declare const process: { exit(code: number): never; cwd(): string; env: Record<string, string | undefined> };
declare function require(m: string): unknown;
const fs = require('fs') as {
  readFileSync(p: string, enc?: string): string | Uint8Array;
  writeFileSync(p: string, data: string): void;
  mkdtempSync(prefix: string): string;
  cpSync(from: string, to: string, opts: { recursive: boolean }): void;
  rmSync(p: string, opts: { recursive: boolean; force: boolean }): void;
};
const path = require('path') as { join(...parts: string[]): string };
const os = require('os') as { tmpdir(): string };
const cp = require('child_process') as {
  execFileSync(cmd: string, args: string[], opts: { encoding: 'utf8'; cwd?: string }): string;
};

let failures = 0;
let pending = Promise.resolve();

function check(label: string, fn: () => void | Promise<void>): void {
  pending = pending.then(async () => {
    try {
      await fn();
      console.log(`  ok  ${label}`);
    } catch (e) {
      failures++;
      console.error(`FAIL  ${label}\n      ${String(e)}`);
    }
  });
}

function assert(cond: boolean, msg: string): void {
  if (!cond) throw new Error(msg);
}

function assertEq<T>(actual: T, expected: T, what: string): void {
  const a = JSON.stringify(actual);
  const b = JSON.stringify(expected);
  if (a !== b) throw new Error(`${what}: expected ${b}, got ${a}`);
}

/** 이 함수가 던지면 검사가 회귀를 **잡은** 것이다 — 안 던지면 검사가 눈이 먼 것. */
function mustThrow(what: string, fn: () => void): void {
  let threw = false;
  try {
    fn();
  } catch {
    threw = true;
  }
  if (!threw) throw new Error(`회귀 주입이 검사를 통과했다: ${what}`);
}

// ─── 실제 소스 트리의 그래프 ─────────────────────────────────────────────────

const root = process.cwd();
const disk = (p: string): string | Uint8Array => fs.readFileSync(path.join(root, p));

interface Fixture {
  graph: ModuleGraph;
  toolchain: string;
  registrySource: string;
}

async function loadFixture(): Promise<Fixture> {
  return {
    graph: moduleGraph(await bundleGraph(esbuild, root)),
    toolchain: toolchainOf(esbuild),
    registrySource: fs.readFileSync(path.join(root, 'src/registry.ts'), 'utf8') as string,
  };
}

function hashesWith(
  f: Fixture,
  overrides: Record<string, string> = {},
  graph: ModuleGraph = f.graph,
  config: HashConfig = defaultConfig(),
): EntrySourceHashes {
  return entrySourceHashes({
    graph,
    registrySource: f.registrySource,
    readFile: (p) => overrides[p] ?? disk(p),
    toolchain: f.toolchain,
    config,
  });
}

/** 간선 하나를 뺀 사본 — 닫힘 계산이 그 간선을 놓치는 회귀를 만든다. */
function withoutEdge(graph: ModuleGraph, from: string, to: string): ModuleGraph {
  const edges = new Map(graph.edges);
  const before = edges.get(from);
  assert(before !== undefined && before.includes(to), `그래프에 ${from} → ${to} 간선이 없다`);
  edges.set(from, (before as string[]).filter((d) => d !== to));
  return { edges, opaque: graph.opaque, modules: graph.modules };
}

function changedKeys(a: EntrySourceHashes, b: EntrySourceHashes): string[] {
  return Object.keys(a.hashes).filter((k) => a.hashes[k] !== b.hashes[k]);
}

const mutate = (p: string): Record<string, string> => ({
  [p]: `${disk(p).toString()}\n// edited by selftest\n`,
});

console.log('selftest: entry-hash');

// ─── 1. 순수: 닫힘 · 폴백 ───────────────────────────────────────────────────

const synthetic = (): ModuleGraph => ({
  edges: new Map([
    ['a.ts', ['shared.ts', 'leaf.json']],
    ['b.ts', ['shared.ts']],
    ['shared.ts', ['deep.ts']],
    ['deep.ts', []],
    ['leaf.json', []],
    ['dyn.ts', ['shared.ts']],
  ]),
  opaque: new Map([['dyn.ts', 'dynamic-import ./x']]),
  modules: new Set(['a.ts', 'b.ts', 'shared.ts', 'deep.ts', 'leaf.json', 'dyn.ts']),
});

check('closureOf — 간선을 전이적으로 따라가고, 자르는 모듈은 들어오지도 지나가지도 않는다', () => {
  const g = synthetic();
  assertEq([...(closureOf(g, ['a.ts'], new Set()).files as Set<string>)].sort(), ['a.ts', 'deep.ts', 'leaf.json', 'shared.ts'], 'a.ts 의 닫힘');
  assertEq([...(closureOf(g, ['b.ts'], new Set()).files as Set<string>)].sort(), ['b.ts', 'deep.ts', 'shared.ts'], 'b.ts 의 닫힘');
  assertEq(
    [...(closureOf(g, ['a.ts'], new Set(['shared.ts'])).files as Set<string>)].sort(),
    ['a.ts', 'leaf.json'],
    '자른 shared.ts 는 닫힘에도, 그 너머 deep.ts 도 들어오지 않는다',
  );
});

check('closureOf — 계산하지 못하는 모듈(동적 import)이 닫힘 안에 있으면 null 이다', () => {
  const c = closureOf(synthetic(), ['dyn.ts'], new Set());
  assert(c.files === null, '닫힘을 계산하지 못했는데 집합을 돌려줬다');
  assert(String(c.why).includes('dyn.ts'), '사유가 모듈을 말하지 않는다');
});

check('moduleGraph — 값으로 쓰이지 않아 지워진 import 는 간선이 아니고, 동적 import · 외부 모듈은 opaque 다', () => {
  const g = moduleGraph({
    inputs: {
      'a.ts': {
        imports: [
          { path: './types', kind: 'import-statement', external: true },
          { path: 'b.ts', kind: 'import-statement' },
          { path: './lazy', kind: 'dynamic-import' },
        ],
      },
      'b.ts': { imports: [{ path: 'left-pad', kind: 'import-statement', external: true }] },
    },
  });
  assertEq(g.edges.get('a.ts'), ['b.ts'], 'a.ts 의 간선');
  assertEq(g.opaque.has('a.ts'), true, '동적 import 는 opaque');
  assertEq(g.opaque.has('b.ts'), true, '번들 밖 외부 모듈은 opaque');
});

check('hashFiles — 닫힘의 내용이 같으면 같고, 한 파일이 달라지거나 도구 지문이 달라지면 달라진다', () => {
  const read = (m: Record<string, string>) => (p: string) => m[p] ?? '';
  const base = { 'a.ts': '1', 'b.ts': '2' };
  const h = hashFiles(['a.ts', 'b.ts'], read(base), 'tool 1');
  assertEq(hashFiles(['b.ts', 'a.ts'], read(base), 'tool 1'), h, '순서는 무관');
  assert(hashFiles(['a.ts', 'b.ts'], read({ ...base, 'b.ts': '3' }), 'tool 1') !== h, '내용이 달라졌는데 같다');
  assert(hashFiles(['a.ts', 'b.ts'], read(base), 'tool 2') !== h, '도구가 달라졌는데 같다');
});

check('entrySourceHashes — 닫힘을 계산하지 못한 키는 표에서 빠지고 사유가 남는다(전체 해시로 되돌아간다)', () => {
  const r = entrySourceHashes({
    graph: synthetic(),
    registrySource: "import { A } from './components/a';\nimport { DYN } from './components/dyn';\n",
    readFile: () => '',
    toolchain: 't',
    config: { nonDrawing: {}, pipelineRoots: [], pipelineGlue: [] },
  } as never);
  // 합성 그래프의 모듈 경로는 `src/components/*` 가 아니므로 키는 "그래프에 없다" 로 빠진다.
  assertEq(Object.keys(r.hashes), [], '모듈이 없으면 해시도 없다');
  assertEq(r.unresolved.map((u) => u.key).sort(), ['A', 'DYN'], '빠진 키');
});

// ─── 2. 실제 그래프 ─────────────────────────────────────────────────────────

check('선언한 비그림 모듈 · 파이프라인 경로가 모두 번들 그래프에 있다(낡은 선언이 없다)', async () => {
  const f = await loadFixture();
  assertEq(checkDeclarations(f.graph), [], '그래프에 없는 선언');
  mustThrow('없는 경로를 선언해도 통과한다', () => {
    const problems = checkDeclarations(f.graph, {
      nonDrawing: { ...kNonDrawingModules, 'src/no-such-module.ts': '낡은 선언' },
      pipelineRoots: [...kPipelineRoots],
      pipelineGlue: [...kPipelineGlue],
    });
    if (problems.length > 0) throw new Error(problems.join('; '));
  });
});

check('키 목록 — registry.ts 의 import 식별자 = SOURCE_GROUPS 의 키, 모든 엔트리가 정확히 한 배열에 있다', async () => {
  const f = await loadFixture();
  const fromImports = [...registryKeyModules(f.registrySource).keys()].sort();
  assertEq(Object.keys(SOURCE_GROUPS).sort(), fromImports, 'SOURCE_GROUPS 의 키');
  const seen = new Map<RegistryEntry, number>();
  for (const group of Object.values(SOURCE_GROUPS)) for (const e of group) seen.set(e, (seen.get(e) ?? 0) + 1);
  assertEq(seen.size, REGISTRY.length, '배열에 든 엔트리 수 = REGISTRY 길이');
  for (const e of REGISTRY) assertEq(seen.get(e), 1, `${e.name} 가 든 배열 수`);
});

check('모든 키가 닫힘을 얻고, 폴백은 몇 개인지 보인다', async () => {
  const f = await loadFixture();
  const r = hashesWith(f);
  const keys = Object.keys(SOURCE_GROUPS);
  console.log(`      키 ${keys.length}개 중 닫힘 ${Object.keys(r.hashes).length}개 · 전체 해시 폴백 ${r.unresolved.length}개`);
  assertEq(r.unresolved, [], '전체 해시로 되돌아간 키');
  assertEq(Object.keys(r.hashes).sort(), keys.sort(), '해시가 만들어진 키');
});

/**
 * 닫힘의 두 성질 — 한 쌍이다. (a) 무관한 파일은 어떤 엔트리도 못 움직이고 (b) 닫힘 안의 파일은
 * 그것을 닫힘에 가진 엔트리를 움직인다. 회귀 주입은 이 함수를 간선이 빠진 그래프에 돌려 던지는지 본다.
 */
function assertClosureProperties(f: Fixture, graph: ModuleGraph, config: HashConfig = defaultConfig()): void {
  const base = hashesWith(f, {}, graph, config);
  const keys = Object.keys(SOURCE_GROUPS);

  // (a) 빌더가 import 하지 않는 파일 — 읽기 전용 보기 · 실행 잠금 · 마지막 단계 · 대조.
  for (const p of [
    'src/designer-parity.ts',
    'src/stale-sets.ts',
    'src/overlapping-siblings.ts',
    'src/run-lock.ts',
    'src/last-step.ts',
    'src/orphan-nodes.ts',
    'src/generation-stamp.ts',
  ]) {
    assertEq(changedKeys(base, hashesWith(f, mutate(p), graph, config)), [], `${p} 를 고쳤는데 해시가 움직였다`);
  }
  // 데이터는 엔트리 데이터 해시가 맡는다 — 이 닫힘에는 없다.
  assertEq(changedKeys(base, hashesWith(f, mutate('src/data/components.json'), graph, config)), [], 'components.json');

  // (b) 닫힘 안 — 공유 그리기 코드 · 파이프라인 · 아이콘 데이터는 모든 엔트리를 움직인다.
  for (const p of [
    'src/helpers.ts',
    'src/paint.ts',
    'src/identity.ts',
    'src/docs-frames.ts',
    'src/text-style-attach.ts',
    'src/generate.ts',
    'src/data/icons.json',
    'src/data/icon-keys.json',
  ]) {
    assertEq(changedKeys(base, hashesWith(f, mutate(p), graph, config)).sort(), [...keys].sort(), `${p} 를 고쳤는데 해시가 안 움직인 엔트리가 있다`);
  }

  // (c) 아무도 import 하지 않는 컴포넌트 모듈 — 자기 배열 하나만 움직인다.
  for (const [key, mod] of registryKeyModules(f.registrySource)) {
    const importers = [...graph.edges].filter(([, deps]) => deps.includes(mod)).map(([m]) => m);
    const importedByEntryModule = importers.some((m) => m.startsWith('src/components/'));
    if (importedByEntryModule) continue;
    assertEq(changedKeys(base, hashesWith(f, mutate(mod), graph, config)), [key], `${mod} 만 고쳤는데 ${key} 외가 움직였거나 ${key} 가 안 움직였다`);
  }
}

check('닫힘의 성질 — 무관한 파일은 안 움직이고, 닫힘 안의 파일은 움직인다', async () => {
  const f = await loadFixture();
  assertClosureProperties(f, f.graph);
});

check('회귀 주입 — 닫힘 계산에서 간선 하나를 빼면(또는 파이프라인 루트를 빼면) 위 검사가 실패한다', async () => {
  const f = await loadFixture();
  // 모든 엔트리의 닫힘이 icon-nodes.ts 를 통해 아이콘 데이터에 닿는다 — 그 간선이 유일한 길이다.
  const noIcons = withoutEdge(f.graph, 'src/icon-nodes.ts', 'src/data/icons.json');
  mustThrow('icon-nodes → icons.json 간선을 빼도 닫힘 검사가 통과한다', () => assertClosureProperties(f, noIcons));
  // helpers.ts → icon-nodes.ts 를 빼도 아이콘 데이터에 닿는 다른 길(component-props)이 있을 수 있어 단정하지 않는다.
  // docs-frames.ts 는 generate.ts 만 import 한다 — 파이프라인 루트 선언이 닫힘에 넣는 유일한 길이다.
  const noPipeline: HashConfig = { ...defaultConfig(), pipelineRoots: [] };
  mustThrow('파이프라인 루트를 빼도 닫힘 검사가 통과한다', () => assertClosureProperties(f, f.graph, noPipeline));
  // 비교용 — 온전한 그래프 · 설정은 통과한다(위 주입이 "항상 던지는 검사" 가 아님을 보인다).
  assertClosureProperties(f, f.graph);
});

check('components.json 은 닫힘 밖이지만 아이콘 데이터는 안이다 — 근거: 엔트리 데이터 해시가 맡는 쪽과 아무도 맡지 않던 쪽', async () => {
  const f = await loadFixture();
  const r = hashesWith(f);
  const files = r.filesByKey.ICON_BUILDERS as Set<string>;
  assert(files.has('src/data/icons.json') && files.has('src/data/icon-keys.json'), '아이콘 데이터가 닫힘에 없다');
  assert(!files.has('src/data/components.json'), 'components.json 이 닫힘에 들어 있다');
  for (const set of Object.values(r.filesByKey)) {
    assert(!set.has('src/stale-sets.ts') && !set.has('src/run-lock.ts'), '읽기 전용 · 잠금 모듈이 닫힘에 들어 있다');
  }
});

// ─── 3. 런타임 레시피 ───────────────────────────────────────────────────────

check('런타임 — 표가 없으면(하네스) 모든 엔트리가 옛 레시피(전체 해시 폴백)로 간다', () => {
  for (const e of REGISTRY) assertEq(entrySourceHashOf(e, null), null, `${e.name} 의 소스 해시`);
});

check('런타임 — 표의 해시가 키에 매달리고, 레지스트리 밖 엔트리와 표에 없는 키는 null(폴백)이다', () => {
  const table: Record<string, string> = {};
  for (const k of Object.keys(SOURCE_GROUPS)) table[k] = `h-${k}`;
  const button = REGISTRY.find((e) => e.name === 'Button') as RegistryEntry;
  const s = entrySourceHashOf(button, table);
  assert(s !== null && s.includes('FORM_BUILDERS=h-FORM_BUILDERS'), 'Button 의 해시가 자기 배열 키를 담지 않는다');
  const phone = REGISTRY.find((e) => e.name === 'PhoneInput') as RegistryEntry;
  const phoneKeys = entrySourceKeysOf(phone) as string[];
  const popover = REGISTRY.find((e) => e.name === 'Popover') as RegistryEntry;
  assert(
    (phone.needs ?? []).includes('Popover') && phoneKeys.includes(entrySourceKeysOf(popover)![0]),
    'needs 로 인스턴스를 만드는 자식의 키가 부모의 해시에 들지 않는다',
  );
  const { FORM_BUILDERS: _drop, ...partial } = table;
  void _drop;
  assertEq(entrySourceHashOf(button, partial), null, '표에 없는 키가 있으면 폴백');
  const stranger: RegistryEntry = { section: 'Form', name: 'Stranger', build: () => ({}) as never };
  assertEq(entrySourceHashOf(stranger, table), null, '레지스트리 밖 엔트리는 폴백');
});

check('런타임 — 폴백 엔트리의 해시는 옛 레시피(빌더 텍스트가 든다)이고 같은 엔트리는 같은 값이다', () => {
  const a: RegistryEntry = { section: 'Form', name: 'Alpha', build: () => ({}) as never };
  const b: RegistryEntry = { section: 'Form', name: 'Alpha', build: () => ({ x: 1 }) as never };
  assertEq(entryContentHashOf(a), entryContentHashOf(a), '같은 엔트리');
  assert(entryContentHashOf(a) !== entryContentHashOf(b), '빌더 텍스트가 다른데 같다(폴백 레시피가 아니다)');
});

// ─── 4. 번들 안정성 — 이름이 겹쳐도 닫힘 해시가 안 움직인다 ───────────────────

const kProbeSource = `
import { REGISTRY } from './src/registry';
import { entryContentHashOf } from './src/content-hash';
import { fnv1a } from './src/hash';
const out: Record<string, { hash: string; text: string }> = {};
for (const e of REGISTRY) out[e.name] = { hash: entryContentHashOf(e), text: fnv1a(e.build.toString()) };
console.log(JSON.stringify(out));
`;

// 최상위에 기존 모듈과 같은 이름의 식별자를 둔 무관한 모듈. 번들러는 충돌하는 이름에 숫자 접미사를
// 붙이고, 먼저 오는 쪽이 이름을 지키므로 **프로브가 이 모듈을 먼저 import** 하면 기존 빌더 함수의
// 이름이 바뀐다 — 그 함수의 `toString()` 도 바뀐다.
const kCollidingModule = `
export function buildButton(): number { return 1; }
export function buildTextField(): number { return 2; }
export function buildCheckbox(): number { return 3; }
export const kSchemaRev = 'unrelated';
// 쓰이지 않는 최상위 선언은 번들러가 지운다 — 지워지면 이름이 겹치지 않는다.
(globalThis as { __unrelated?: unknown }).__unrelated = [buildButton, buildTextField, buildCheckbox, kSchemaRev];
`;

interface Probed {
  [name: string]: { hash: string; text: string };
}

async function probeTree(
  variant: 'plain' | 'colliding',
  patchRecipe: boolean,
): Promise<{ probed: Probed; collidedIn: string[] }> {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'coui-entry-hash-'));
  try {
    fs.cpSync(path.join(root, 'src'), path.join(tmp, 'src'), { recursive: true });
    fs.cpSync(path.join(root, 'code.ts'), path.join(tmp, 'code.ts'), { recursive: true });
    // `src/structure-snapshot.ts` 가 `../reverse/snapshot_format` 을 import 한다.
    fs.cpSync(path.join(root, 'reverse'), path.join(tmp, 'reverse'), { recursive: true });
    let probe = kProbeSource;
    let codeTs = fs.readFileSync(path.join(tmp, 'code.ts'), 'utf8') as string;
    if (variant === 'colliding') {
      fs.writeFileSync(path.join(tmp, 'src/zz-unrelated.ts'), kCollidingModule);
      probe = `import './src/zz-unrelated';\n${probe}`;
      codeTs = `import './src/zz-unrelated';\n${codeTs}`;
      fs.writeFileSync(path.join(tmp, 'code.ts'), codeTs);
    }
    if (patchRecipe) {
      // 회귀 주입 — 닫힘 레시피에 번들 출력의 `toString()` 을 되돌린다.
      const p = path.join(tmp, 'src/content-hash.ts');
      const text = fs.readFileSync(p, 'utf8') as string;
      const needle = 'return fnv1a(`closure:${source}${entryDataHashOf(e)}`);';
      assert(text.includes(needle), '주입할 자리(닫힘 레시피)를 찾지 못했다');
      fs.writeFileSync(p, text.replace(needle, 'return fnv1a(`closure:${source}${e.build.toString()}${entryDataHashOf(e)}`);'));
    }
    fs.writeFileSync(path.join(tmp, 'probe.ts'), probe);

    // 표는 실제 번들 단계처럼 `code.ts` 의 그래프에서 계산한다.
    const graph = moduleGraph(await bundleGraph(esbuild, tmp));
    const table = entrySourceHashes({
      graph,
      registrySource: fs.readFileSync(path.join(tmp, 'src/registry.ts'), 'utf8') as string,
      readFile: (p) => fs.readFileSync(path.join(tmp, p)),
      toolchain: toolchainOf(esbuild),
    });
    assertEq(table.unresolved, [], '임시 트리에서 폴백이 생겼다');

    await esbuild.build({
      entryPoints: [path.join(tmp, 'probe.ts')],
      outfile: path.join(tmp, 'probe.cjs'),
      bundle: true,
      platform: 'node',
      format: 'cjs',
      target: 'es2017',
      logLevel: 'silent',
      absWorkingDir: tmp,
      define: {
        __ENTRY_SOURCE_HASHES__: JSON.stringify(JSON.stringify(table.hashes)),
        __SHARED_SOURCE_HASH__: JSON.stringify('fixed'),
        __BUILD_REF__: JSON.stringify('fixed'),
      },
    });
    const stdout = cp.execFileSync('node', [path.join(tmp, 'probe.cjs')], { encoding: 'utf8' });
    const probed = JSON.parse(stdout.trim().split('\n').pop() as string) as Probed;
    return { probed, collidedIn: [] };
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
}

check('번들 안정성 — 무관한 모듈이 최상위 이름을 겹쳐도 빌더 텍스트는 움직이지만 닫힘 해시는 안 움직인다', async () => {
  const plain = (await probeTree('plain', false)).probed;
  const colliding = (await probeTree('colliding', false)).probed;
  const names = Object.keys(plain);
  assertEq(Object.keys(colliding).sort(), [...names].sort(), '엔트리 이름');
  // 전제: 이 시나리오가 실제로 번들 출력의 빌더 텍스트를 움직인다 — 아니면 아래 검사는 아무것도 증명하지 못한다.
  const textMoved = names.filter((n) => plain[n].text !== colliding[n].text);
  console.log(`      이름 충돌로 빌더 텍스트가 바뀐 엔트리 ${textMoved.length} / ${names.length}`);
  assert(textMoved.length > 0, '이름을 겹쳤는데 어떤 빌더 텍스트도 바뀌지 않았다 — 시나리오가 무효다');
  const hashMoved = names.filter((n) => plain[n].hash !== colliding[n].hash);
  assertEq(hashMoved, [], '무관한 모듈을 더했는데 닫힘 해시가 움직인 엔트리');
});

check('회귀 주입 — 닫힘 레시피에 번들 출력의 `toString()` 을 되돌리면 위 검사가 실패한다', async () => {
  const plain = (await probeTree('plain', true)).probed;
  const colliding = (await probeTree('colliding', true)).probed;
  const moved = Object.keys(plain).filter((n) => plain[n].hash !== colliding[n].hash);
  assert(moved.length > 0, '`toString()` 을 되돌렸는데도 해시가 안 움직여 검사가 회귀를 못 잡는다');
  console.log(`      주입하면 해시가 움직인 엔트리 ${moved.length} (예: ${moved.slice(0, 3).join(', ')})`);
});

void pending.then(() => {
  if (failures > 0) {
    console.error(`\nselftest: entry-hash — ${failures} failure(s)`);
    process.exit(1);
  }
  console.log('selftest: entry-hash — all ok');
});
