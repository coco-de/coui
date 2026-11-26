/// <reference types="@figma/plugin-typings" />
// The document component index, remembered between runs.
//
// ## Why it exists
//
// Generate used to open with `loadAsync()` on every page of the document —
// 198 of them, 28.9–33.3s on the first run of a session — because two things
// after it need the whole document: the rename/migration passes, and the
// name → node index (`indexDocumentComponents`) that mint-by-name reads. A
// partial run that draws one component paid the same half-minute as a run
// that draws all of them.
//
// Neither of those needs the whole document every time. The index is a pure
// function of the document's COMPONENT / COMPONENT_SET nodes, and those only
// move when something draws, renames or deletes one. So the last run's index
// is written to `figma.root` plugin data, and a scoped run that finds it
// still true loads only the pages it is about to draw on plus the pages its
// `needs` point at.
//
// ## What "still true" means — and every way it can be false
//
// A cache that answers wrong is worse than no cache: mint-by-name trusts the
// index to say whether a component exists, and a false "absent" mints a
// second copy next to the designer's instances. So a hit is granted only when
// every check below passes, and any single failure falls back to the full
// load, which then rewrites the cache (`cacheVerdict`):
//
//   - **Same build.** A different plugin bundle may carry different rename
//     tables, a different REGISTRY or a different notion of "canonical page".
//     The build hash covers all of it at once, so the first run of a new
//     build always loads everything — which is also what applies that build's
//     pending renames to the whole document.
//   - **Same pages.** The page list (ids and names, in order) is readable
//     without loading any page. A page added, removed, renamed, demoted or
//     restored since the cache was written is exactly the change that moves a
//     component or opts it out, so any difference is a miss.
//   - **Every name this run reads is accounted for** — either an entry, or a
//     REGISTRY name the last full index did not find (`absent`). A REGISTRY
//     entry added in code is neither, and misses.
//   - **Every entry this run reads still resolves** to a node of the same
//     name, a component type, on the page the cache recorded
//     (`resolveCachedIndex`). One that does not — another client deleted or
//     renamed it — is a miss. Nothing is repaired in place.
//
// ## What a hit does not see — said out loud in the run log
//
// The duplicate-name warning and the canonical-page winner rule
// (`prefersDuplicateWinner`) are statements about the WHOLE document; a hit
// does not walk it, so a duplicate created since the last full run goes
// unreported until the next one. A component pasted onto an existing page
// by hand (no page added, no Generate) is not in the cache either. Both are
// why the hit path logs its reach instead of pretending to be the full walk.
// Any full run — a new build, a page change, a `force` run, an unscoped run
// — restores the whole-document view.

import { REGISTRY } from './registry';

/** `figma.root` plugin-data key. Independent of every per-node key. */
export const kComponentIndexCacheKey = 'coui-component-index';

/** Bumped when the stored shape changes; an old shape is simply a miss. */
const kCacheVersion = 1;

export interface CachedIndexEntry {
  /** Node id at the time the cache was written. */
  id: string;
  /** Name of the page the node sat on directly. */
  page: string;
}

export interface ComponentIndexCache {
  v: number;
  /** `kSharedSourceHash` of the bundle that wrote it. */
  build: string;
  /** `id\tname` of every page, in document order. */
  pages: string[];
  /** REGISTRY name → where it was. */
  entries: Record<string, CachedIndexEntry>;
  /** REGISTRY names the writing run's index did not contain. */
  absent: string[];
}

export interface PageRef {
  readonly id: string;
  readonly name: string;
}

/** The order-sensitive page signature the cache compares. Names are readable
 *  on an unloaded page under `documentAccess: dynamic-page`, so this costs no
 *  load. */
export function pageSignature(pages: readonly PageRef[]): string[] {
  return pages.map((p) => `${p.id}\t${p.name}`);
}

/** Parses stored plugin data. Anything unexpected is `null` — a miss, never a
 *  throw: a corrupt cache must cost a full load, not the run. */
export function parseComponentIndexCache(raw: string): ComponentIndexCache | null {
  if (!raw) return null;
  let value: unknown;
  try {
    value = JSON.parse(raw);
  } catch {
    return null;
  }
  if (value === null || typeof value !== 'object') return null;
  const c = value as Partial<ComponentIndexCache>;
  if (c.v !== kCacheVersion || typeof c.build !== 'string') return null;
  if (!Array.isArray(c.pages) || !c.pages.every((p) => typeof p === 'string')) return null;
  if (!Array.isArray(c.absent) || !c.absent.every((n) => typeof n === 'string')) return null;
  if (c.entries === null || typeof c.entries !== 'object') return null;
  for (const entry of Object.values(c.entries)) {
    if (entry === null || typeof entry !== 'object') return null;
    if (typeof entry.id !== 'string' || typeof entry.page !== 'string') return null;
  }
  return c as ComponentIndexCache;
}

export type CacheVerdict = { hit: true } | { hit: false; reason: string };

export interface CacheQuestion {
  /** The running bundle's `kSharedSourceHash`. */
  build: string;
  /** The document's `pageSignature` right now. */
  pages: readonly string[];
  /** Every REGISTRY name this run will look up. `null` = the whole REGISTRY,
   *  i.e. an unscoped run — which loads everything anyway. */
  required: readonly string[] | null;
  /** Reasons that force the full walk regardless of the cache (a `force`
   *  run, a legacy migration page still present, …). */
  fullLoadReasons: readonly string[];
}

/**
 * Hit or miss, and why. Pure — the checks that do not need a node. The one
 * that does (every entry still resolves) is `resolveCachedIndex`, run after
 * a hit here.
 */
export function cacheVerdict(
  cache: ComponentIndexCache | null,
  q: CacheQuestion,
): CacheVerdict {
  if (q.fullLoadReasons.length > 0) return { hit: false, reason: q.fullLoadReasons.join(' · ') };
  if (q.required === null) return { hit: false, reason: '범위 전체 실행' };
  if (cache === null) return { hit: false, reason: '캐시 없음' };
  if (cache.build !== q.build) {
    return { hit: false, reason: `다른 빌드가 쓴 캐시 (${cache.build} ≠ ${q.build})` };
  }
  if (!sameList(cache.pages, q.pages)) return { hit: false, reason: '페이지 목록이 바뀜' };
  const absent = new Set(cache.absent);
  const unknown = q.required.filter((name) => !(name in cache.entries) && !absent.has(name));
  if (unknown.length > 0) {
    return { hit: false, reason: `캐시에 없는 이름 ${unknown.length}개 (${unknown.slice(0, 3).join(', ')})` };
  }
  return { hit: true };
}

function sameList(a: readonly string[], b: readonly string[]): boolean {
  if (a.length !== b.length) return false;
  for (let i = 0; i < a.length; i++) if (a[i] !== b[i]) return false;
  return true;
}

/**
 * The page names a hit run has to load: the pages its entries draw on, plus
 * the pages the cache says its required names live on. Everything else stays
 * unloaded.
 */
export function pagesToLoad(
  cache: ComponentIndexCache,
  required: readonly string[],
  targetPageNames: readonly string[],
): Set<string> {
  const pages = new Set(targetPageNames);
  for (const name of required) {
    const entry = cache.entries[name];
    if (entry) pages.add(entry.page);
  }
  return pages;
}

/** What `resolveCachedIndex` needs to know about a node. */
export interface ResolvedNodeFacts {
  type: string;
  name: string;
  /** Name of the page the node sits on directly, or `null` when it is not
   *  directly on a page (moved into a frame, removed). */
  page: string | null;
}

/**
 * The index a hit run installs — the required names that are entries, each
 * resolved and checked. Returns a miss reason on the first entry that no
 * longer matches: the cache is not repaired, the run falls back.
 *
 * Generic over the node type so the selftest drives it with plain objects.
 */
export async function resolveCachedIndex<N>(
  cache: ComponentIndexCache,
  required: readonly string[],
  resolve: (id: string) => Promise<N | null>,
  factsOf: (node: N) => ResolvedNodeFacts,
): Promise<{ index: Map<string, N> } | { miss: string }> {
  const index = new Map<string, N>();
  for (const name of required) {
    const entry = cache.entries[name];
    if (!entry) continue; // accounted for as `absent` by `cacheVerdict`
    let node: N | null;
    let facts: ResolvedNodeFacts;
    try {
      node = await resolve(entry.id);
      if (node === null) return { miss: `${name}: 노드 ${entry.id} 가 없다` };
      facts = factsOf(node);
    } catch (e) {
      return { miss: `${name}: 노드 ${entry.id} 를 읽지 못함 (${String(e).slice(0, 80)})` };
    }
    if (facts.type !== 'COMPONENT' && facts.type !== 'COMPONENT_SET') {
      return { miss: `${name}: 노드 ${entry.id} 가 컴포넌트가 아님 (${facts.type})` };
    }
    if (facts.name !== name) return { miss: `${name}: 노드 ${entry.id} 이름이 "${facts.name}"` };
    if (facts.page !== entry.page) {
      return { miss: `${name}: "${entry.page}" 에 있던 노드가 "${facts.page ?? '(페이지 직계 아님)'}" 에 있다` };
    }
    index.set(name, node);
  }
  return { index };
}

/**
 * The cache to write at the end of a run.
 *
 * `base` is the previous cache's entries when this run was a HIT — it only
 * looked at part of the document, so everything it did not look at is carried
 * over unchanged. A full run passes `null`: it saw everything, and anything the
 * old cache still names but the document no longer has must not survive.
 *
 * Only REGISTRY names are kept — the index also carries whatever else is a
 * component in the file (designer copies, foundation frames), and none of it is
 * ever looked up by name.
 *
 * A live entry of `null` means "this run held the name but could not place
 * its node" (a dead handle, a node no longer directly on a page). That name
 * becomes neither an entry nor `absent` — so the next run that needs it
 * misses. Recording it as absent would let that run mint a second copy of a
 * component that may well still exist.
 */
export function nextComponentIndexCache(
  base: Readonly<Record<string, CachedIndexEntry>> | null,
  live: Iterable<readonly [string, CachedIndexEntry | null]>,
  meta: { build: string; pages: readonly string[]; registryNames?: readonly string[] },
): ComponentIndexCache {
  const registryNames = meta.registryNames ?? REGISTRY.map((e) => e.name);
  const wanted = new Set(registryNames);
  const entries: Record<string, CachedIndexEntry> = {};
  const unknown = new Set<string>();
  if (base) {
    for (const [name, entry] of Object.entries(base)) {
      if (wanted.has(name)) entries[name] = { id: entry.id, page: entry.page };
    }
  }
  for (const [name, entry] of live) {
    if (!wanted.has(name)) continue;
    if (entry === null) {
      delete entries[name];
      unknown.add(name);
    } else {
      entries[name] = { id: entry.id, page: entry.page };
    }
  }
  const absent = registryNames.filter((name) => !(name in entries) && !unknown.has(name));
  return { v: kCacheVersion, build: meta.build, pages: [...meta.pages], entries, absent };
}

/** The page a node sits on DIRECTLY, or `null`. Structural, so the selftest's
 *  plain objects answer it too. */
export function directPageNameOf(node: {
  readonly parent: { readonly type: string; readonly name: string } | null;
}): string | null {
  const parent = node.parent;
  return parent !== null && parent.type === 'PAGE' ? parent.name : null;
}

/** The two log lines a run prints about its load: which path, and — on a
 *  hit — what that path did not look at. Pure, so the wording is pinned. */
export function formatCacheLine(
  verdict: { hit: true; loaded: number; total: number } | { hit: false; reason: string },
): string[] {
  if (verdict.hit) {
    return [
      `⚡ 컴포넌트 인덱스 캐시 적중 — 페이지 ${verdict.loaded}/${verdict.total} 만 로드`,
      '   이번 실행은 문서 전체를 훑지 않았다: 중복 이름 경고 · 캐논 페이지 승자 판정 · ' +
        '손으로 붙여 넣은 컴포넌트는 다음 전체 로드(새 빌드 · 페이지 변경 · 강제 재생성 · 전체 범위)가 본다',
    ];
  }
  return [`컴포넌트 인덱스 캐시 미사용 — 전체 로드 (${verdict.reason})`];
}
