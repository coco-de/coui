/// <reference types="@figma/plugin-typings" />

// Self-test for src/component-index-cache.ts (#4803).
//
// 이 캐시가 틀리는 방식은 하나다 — **조용히 다른 답을 낸다.** 캐시 적중 실행은
// 문서 전체를 훑지 않으므로, 캐시가 "없다" 고 말한 컴포넌트는 그 실행에서
// 정말 없는 것으로 다뤄지고, mint-by-name 은 디자이너의 인스턴스 옆에 두 번째
// 사본을 만든다. 그래서 여기서는 Node 더블로 네 가지를 고정한다:
//
//   1. **두 경로가 같은 인덱스를 만든다** — 전체 순회(`addPageToIndex`, Generate
//      가 실제로 부르는 그 함수)와 캐시 해석이 필요한 이름마다 **같은 노드**를
//      가리킨다. 중복 이름의 캐논 페이지 승자까지.
//   2. **적중은 필요한 페이지만 로드한다** — 스코프 페이지 + 캐시가 가리키는
//      페이지. 무관한 페이지는 목록에 없다.
//   3. **틀릴 수 있는 모든 경우가 미스다** — 다른 빌드 · 페이지 변경 · 모르는
//      이름 · 강제 사유 · 범위 전체 · 사라진 노드 · 이름 바뀐 노드 · 옮겨진 노드
//      · 읽다 던지는 노드. 양성만 단언하면 `{ hit: true }` 로 바꿔도 통과한다.
//   4. **다음 캐시가 모르는 것을 "없음" 으로 적지 않는다** — 해석하지 못한
//      이름은 absent 가 아니라 unknown 이 돼 다음 실행을 미스로 보낸다.
//
// 그리고 배선 — Generate 가 이 모듈을 실제로 거치는지. 빠져도 타입체크는
// 통과한다.

import {
  cacheVerdict,
  directPageNameOf,
  formatCacheLine,
  kComponentIndexCacheKey,
  nextComponentIndexCache,
  pageSignature,
  pagesToLoad,
  parseComponentIndexCache,
  resolveCachedIndex,
  type CachedIndexEntry,
  type ComponentIndexCache,
} from '../src/component-index-cache';
import { addPageToIndex } from '../src/identity';

declare const process: { exit(code: number): never; cwd(): string };
declare function require(m: string): unknown;
const { readFileSync } = require('fs') as {
  readFileSync(p: string, enc: string): string;
};
const { join } = require('path') as { join(...parts: string[]): string };

let failures = 0;
function check(cond: boolean, label: string): void {
  if (cond) {
    console.log(`  ✓ ${label}`);
  } else {
    console.error(`  ✗ ${label}`);
    failures++;
  }
}

// ─── A document double ─────────────────────────────────────────────────────
interface FakePage {
  id: string;
  name: string;
  type: 'PAGE';
  children: FakeNode[];
}
interface FakeNode {
  id: string;
  type: string;
  name: string;
  parent: FakePage | null;
}

function page(id: string, name: string, kids: [string, string, string][]): FakePage {
  const p: FakePage = { id, name, type: 'PAGE', children: [] };
  for (const [nodeId, type, nodeName] of kids) {
    p.children.push({ id: nodeId, type, name: nodeName, parent: p });
  }
  return p;
}

function makeDocument(): FakePage[] {
  return [
    page('0:1', '❖ Button', [['1:1', 'COMPONENT_SET', 'Button']]),
    page('0:2', '❖ Icon', [['2:1', 'COMPONENT_SET', 'Icon']]),
    page('0:3', '❖ Card', [
      ['3:1', 'COMPONENT_SET', 'Card'],
      ['3:2', 'FRAME', '_Docs / Card'],
    ]),
    // A leftover copy sits EARLIER in the document than the canonical one —
    // the full walk's winner rule must pick `❖ Command`, and the cache must
    // remember that same node.
    page('0:4', '❖ Command (deprecated · 2026-09-08)', [['4:1', 'COMPONENT_SET', 'Command']]),
    page('0:5', '❖ Command', [['5:1', 'COMPONENT_SET', 'Command']]),
    page('0:6', 'Foundation / Color', [['6:1', 'FRAME', 'Foundation / 01. Color']]),
  ];
}

const kRegistryNames = ['Button', 'Icon', 'Card', 'Command', 'Tabs'];

function fullIndex(doc: readonly FakePage[]): Map<string, FakeNode> {
  const index = new Map<string, FakeNode>();
  const pageOf = new Map<string, string>();
  for (const p of doc) addPageToIndex(index, pageOf, p.name, p.children);
  return index;
}

function liveEntries(index: Map<string, FakeNode>): [string, CachedIndexEntry | null][] {
  return [...index].map(([name, node]) => {
    const pageName = directPageNameOf(node);
    return [name, pageName === null ? null : { id: node.id, page: pageName }];
  });
}

function byId(doc: readonly FakePage[]): Map<string, FakeNode> {
  const map = new Map<string, FakeNode>();
  for (const p of doc) for (const n of p.children) map.set(n.id, n);
  return map;
}

const factsOf = (n: FakeNode) => ({ type: n.type, name: n.name, page: directPageNameOf(n) });

async function main(): Promise<void> {
  const doc = makeDocument();
  const sig = pageSignature(doc);
  const full = fullIndex(doc);
  const cache = nextComponentIndexCache(null, liveEntries(full), {
    build: 'b1',
    pages: sig,
    registryNames: kRegistryNames,
  });

  console.log('component-index cache — the full walk writes');
  check(cache.entries.Command?.id === '5:1', 'the canonical `❖ Command` wins, not the earlier leftover');
  check(cache.absent.join(',') === 'Tabs', `a REGISTRY name the walk did not find is absent (got ${cache.absent.join(',')})`);
  check(!('_Docs / Card' in cache.entries), 'non-component frames are not entries');
  check(Object.keys(cache.entries).sort().join(',') === 'Button,Card,Command,Icon', 'only REGISTRY names are kept');

  console.log('component-index cache — round-trip through plugin data');
  const stored = parseComponentIndexCache(JSON.stringify(cache));
  check(stored !== null && JSON.stringify(stored) === JSON.stringify(cache), 'JSON round-trip is lossless');
  check(parseComponentIndexCache('') === null, 'empty data is a miss, not a throw');
  check(parseComponentIndexCache('{not json') === null, 'corrupt data is a miss, not a throw');
  check(parseComponentIndexCache(JSON.stringify({ ...cache, v: 999 })) === null, 'another shape version is a miss');
  check(
    parseComponentIndexCache(JSON.stringify({ ...cache, entries: { Button: { id: 1 } } })) === null,
    'a malformed entry is a miss',
  );
  check(kComponentIndexCacheKey === 'coui-component-index', 'the plugin-data key is stable');

  const c = stored as ComponentIndexCache;
  const required = ['Button', 'Command', 'Icon', 'Tabs'];
  const question = { build: 'b1', pages: sig, required, fullLoadReasons: [] as string[] };

  console.log('component-index cache — hit and miss build the same index');
  const verdict = cacheVerdict(c, question);
  check(verdict.hit, `a same-build, same-pages, fully-accounted question is a hit (${JSON.stringify(verdict)})`);
  const nodes = byId(doc);
  const resolved = await resolveCachedIndex(c, required, async (id) => nodes.get(id) ?? null, factsOf);
  check('index' in resolved, 'every required entry resolves');
  if ('index' in resolved) {
    for (const name of required) {
      check(resolved.index.get(name) === full.get(name), `${name}: the hit path hands back the same node as the full walk`);
    }
    check(!resolved.index.has('Card'), 'a name outside the scope is not resolved (its page stays unloaded)');
  }

  console.log('component-index cache — a hit loads only what it reads');
  const load = pagesToLoad(c, required, required.map((n) => `❖ ${n}`));
  check(load.has('❖ Button') && load.has('❖ Icon') && load.has('❖ Command'), 'scope and needs pages are loaded');
  check(load.has('❖ Tabs'), 'the target page of a not-yet-built entry is in the list (created if missing)');
  check(!load.has('❖ Card') && !load.has('Foundation / Color'), 'unrelated pages are not loaded');
  check(!load.has('❖ Command (deprecated · 2026-09-08)'), 'the losing duplicate’s page is not loaded');

  console.log('component-index cache — every way it can be wrong is a miss');
  const miss = (v: { hit: boolean }) => !v.hit;
  check(miss(cacheVerdict(null, question)), 'no cache');
  check(miss(cacheVerdict(c, { ...question, build: 'b2' })), 'another build (its rename tables may differ)');
  const renamedPages = sig.slice();
  renamedPages[2] = '0:3\t  Card'; // demoted by a designer
  check(miss(cacheVerdict(c, { ...question, pages: renamedPages })), 'a page renamed (demoted) since');
  check(miss(cacheVerdict(c, { ...question, pages: [...sig, '0:9\t❖ New'] })), 'a page added since');
  check(miss(cacheVerdict(c, { ...question, required: [...required, 'NewEntry'] })), 'a REGISTRY name neither entry nor absent');
  check(miss(cacheVerdict(c, { ...question, fullLoadReasons: ['강제 재생성'] })), 'a full-load reason (force)');
  check(miss(cacheVerdict(c, { ...question, required: null })), 'an unscoped run');

  const gone = await resolveCachedIndex(c, required, async (id) => (id === '1:1' ? null : nodes.get(id) ?? null), factsOf);
  check('miss' in gone, 'a node deleted by another client');
  const renamed = await resolveCachedIndex(
    c,
    required,
    async (id) => (id === '2:1' ? { ...nodes.get(id)!, name: 'Glyph' } : nodes.get(id) ?? null),
    factsOf,
  );
  check('miss' in renamed, 'a node renamed since');
  const movedPage = page('0:7', '❖ Elsewhere', []);
  const moved = await resolveCachedIndex(
    c,
    required,
    async (id) => (id === '5:1' ? { ...nodes.get(id)!, parent: movedPage } : nodes.get(id) ?? null),
    factsOf,
  );
  check('miss' in moved, 'a node moved to another page');
  const nested = await resolveCachedIndex(
    c,
    required,
    async (id) => (id === '5:1' ? { ...nodes.get(id)!, parent: null } : nodes.get(id) ?? null),
    factsOf,
  );
  check('miss' in nested, 'a node no longer directly on a page');
  const retyped = await resolveCachedIndex(
    c,
    required,
    async (id) => (id === '1:1' ? { ...nodes.get(id)!, type: 'FRAME' } : nodes.get(id) ?? null),
    factsOf,
  );
  check('miss' in retyped, 'a node that is no longer a component');
  const throwing = await resolveCachedIndex(
    c,
    required,
    async (id) => {
      if (id === '2:1') throw new Error('The node with id "2:1" does not exist');
      return nodes.get(id) ?? null;
    },
    factsOf,
  );
  check('miss' in throwing, 'a lookup that throws is a miss, not a crashed run');

  console.log('component-index cache — the next cache');
  const afterHit = nextComponentIndexCache(
    c.entries,
    [
      ['Button', { id: '1:99', page: '❖ Button' }],
      ['Icon', null],
      ['Tabs', { id: '8:1', page: '❖ Tabs' }],
    ],
    { build: 'b1', pages: sig, registryNames: kRegistryNames },
  );
  check(afterHit.entries.Card?.id === '3:1', 'a hit carries the entries it did not look at');
  check(afterHit.entries.Button?.id === '1:99', 'a redrawn node replaces its entry');
  check(afterHit.entries.Tabs?.id === '8:1' && !afterHit.absent.includes('Tabs'), 'a newly built entry leaves absent');
  check(
    !('Icon' in afterHit.entries) && !afterHit.absent.includes('Icon'),
    'an unresolvable handle becomes unknown — neither entry nor absent',
  );
  check(
    !cacheVerdict(afterHit, { ...question, required: ['Icon'] }).hit,
    '…so the next run that needs it misses instead of minting a second copy',
  );
  const afterFull = nextComponentIndexCache(null, [['Button', { id: '1:1', page: '❖ Button' }]], {
    build: 'b1',
    pages: sig,
    registryNames: kRegistryNames,
  });
  check(!('Card' in afterFull.entries) && afterFull.absent.includes('Card'), 'a full run does not inherit stale entries');

  console.log('component-index cache — log wording');
  const hitLines = formatCacheLine({ hit: true, loaded: 7, total: 199 });
  check(hitLines[0].includes('7/199'), 'a hit names loaded/total');
  check(hitLines.join(' ').includes('중복 이름 경고'), 'a hit says what it did not look at');
  check(formatCacheLine({ hit: false, reason: '캐시 없음' })[0].includes('전체 로드 (캐시 없음)'), 'a miss names its reason');

  console.log('component-index cache — wiring');
  const generate = readFileSync(join(process.cwd(), 'src/generate.ts'), 'utf8');
  check(/resolveCachedIndex<SceneNode>\(/.test(generate), 'Generate resolves the cache before indexing');
  check(/cachedNodeIndex \?\? \(await indexDocumentComponents\(/.test(generate), 'the index is the cache’s on a hit, the full walk otherwise');
  check(/for \(const p of loadedPages\) \{/.test(generate), 'the rename passes walk the loaded pages');
  check(/setPluginData\(kComponentIndexCacheKey, JSON\.stringify\(nextCache\)\)/.test(generate), 'the run writes the next cache');
  check(
    /if \(cachedNodeIndex !== null && failed > 0\) \{[\s\S]{0,600}?setPluginData\(kComponentIndexCacheKey, ''\)/.test(generate),
    'a hit run with a failure drops the cache instead of vouching for it (an undeclared need fails only on a hit)',
  );
  check(
    /const orphanScope = cachedNodeIndex !== null \? loadedPageNames : undefined;/.test(generate) &&
      /listOrphanNodes\(orphanScope\)/.test(generate),
    'the orphan scan stays on the loaded pages on a hit',
  );
  const pkg = readFileSync(join(process.cwd(), 'package.json'), 'utf8');
  check(pkg.includes('npm run selftest:component-index-cache'), 'this harness is in the selftest chain');

  if (failures > 0) {
    console.error(`\n${failures} component-index-cache check(s) failed.`);
    process.exit(1);
  }
  console.log('\nAll component-index-cache self-tests passed.');
}

void main();
