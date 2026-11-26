/// <reference types="@figma/plugin-typings" />

// content-hash.ts — the one recipe for "would this entry's build produce
// different output than what is stamped on the canvas": the source the entry is
// drawn from (the import closure of its module plus the pipeline the generator
// applies to every entry, `entry-source.ts`) + that component's v3 data subtree.
// An entry with no closure falls back to the builder's own source text + the
// whole plugin's source hash.
//
// ## Why this recipe lives in its own module
//
// It used to be defined in `generate.ts` and re-exported (as `expectedHashOf`)
// from `stale-sets.ts`, which imported it back — `generate.ts` also imports
// `classifyRegistry`/`formatStaleSets` FROM `stale-sets.ts` to print a tail
// summary. That is a cycle, and a cycle's live bindings depend on which side
// a bundler evaluates first. Production (`code.ts`) imports `generate.ts`
// before `stale-sets.ts`, so the cycle happened to resolve; a selftest that
// imports `stale-sets.ts` first got `expectedHashOf` bound to `undefined` at
// module-load time — no error, no throw at the import site, just a `const`
// silently holding nothing. Every call downstream throws instead, and a test
// deciding what to call decides whether the bug is ever seen.
//
// Splitting the recipe into a module neither consumer owns removes the cycle
// outright: `generate.ts` and `stale-sets.ts` both import FROM here, neither
// imports the other's recipe, so there is no evaluation order to depend on.
//
// `entryContentHashOf` is exported so a reader of `stale-sets.ts` sees where
// the definition lives, and so the selftest can assert identity — the build
// loop and the read-only listing must compare against the SAME function
// object, not two copies that happen to agree today.

import type { RegistryEntry } from './helpers';
import { kSharedSourceHash } from './build-hash';
import { entrySourceHashOf } from './entry-source';
import { fnv1a } from './hash';
import { slugOfName } from './data';
import componentsJsonRaw from './data/components.json';

/** Plugin-data key a built set carries its content hash under. Read by both
 *  the build loop (`generate.ts`, which stamps it) and the read-only "낡은
 *  세트 보기" (`stale-sets.ts`, which only reads it) — a second literal
 *  would be a second place to typo. */
export const kHashDataKey = 'coui-content-hash';

// #4025 (B3/NFR-A) — per-entry hash granularity. The hash captures
// "would this entry's build recipe produce different output": the
// builder's own source text + THAT COMPONENT's v3 subtree only. Folding
// the whole JSON in (the previous shape) made one component's docs edit
// invalidate all 101 entries — the skip's practical value dies exactly
// when v3 makes the JSON change often (docs/examples edits). meta is
// deliberately excluded (a canonical-library edit is not a build-recipe
// change for any component).
//
// kSchemaRev (T-15) — the one global lever left: renderer/layout format
// changes that a builder's source and its data subtree can't see (page
// frame layout, docs-frame renderers) bump this to invalidate everything
// on purpose. `v3r2` — the D1/D2 docs frames: they render on the built
// path only, so without this bump every already-current entry would skip
// straight past its own first-ever frame render.
// Still here as the DELIBERATE lever — a renderer change someone wants to force
// through even when the source hash would not move (it now almost always does).
const kSchemaRev = 'v3r3'; // v3r3: _Docs / Header 헤드라인 바 (#4105)
const componentsRawBySlug: Record<string, unknown> = componentsJsonRaw.components;
// Hash the slug the entry DRAWS FROM. A `dataSlug` entry (TabItem →
// `tabs`, NavigationBarItem → `navigation_bar`) has no subtree under its own
// name, so hashing `slugOfName(name)` gave it `null` every run and a
// CoreTabsStyle change rebuilt `Tabs` while skipping the `TabItem` it
// composes — the bar then carried stale item chrome.
// A builder fixture has no record under its own name; `fixture.dataFrom` names
// the records it reads instead, and those are hashed in too. Appended after the
// entry's own record so every entry without it hashes byte-for-byte as before.
const entryDataHashOf = (e: {
  name: string;
  dataSlug?: string;
  fixture?: { dataFrom?: readonly string[] };
}): string =>
  fnv1a(
    JSON.stringify(componentsRawBySlug[e.dataSlug ?? slugOfName(e.name)] ?? null) +
      (e.fixture?.dataFrom ?? []).map((s) => JSON.stringify(componentsRawBySlug[s] ?? null)).join('') +
      kSchemaRev,
  );

/**
 * The one definition of "this set is the current code": the hash the build
 * loop stamps on a set and the hash the skip check compares against.
 *
 * With a closure (`entry-source.ts`) the source part is a hash over the TEXT of
 * the files the entry draws from — not over `e.build.toString()`, which is the
 * bundle's output: the bundler suffixes colliding top-level names and inserts
 * lowering helpers, so that text moves when an unrelated module is added.
 *
 * Without one, `kSharedSourceHash` is what makes an edit to shared drawing code
 * count: `e.build.toString()` is one function's own text, so on its own every
 * builder that draws through `helpers` kept an identical hash after a real change.
 *
 * Imported — not copied — by both `generate.ts` (the build loop that stamps
 * it) and `stale-sets.ts` (the read-only listing that only reads it). A
 * second implementation of the same recipe is two recipes the moment one of
 * them is edited, and the listing would then report sets as current that the
 * next Generate rebuilds (or the reverse). `selftest-stale-sets` asserts the
 * identity.
 */
export function entryContentHashOf(e: RegistryEntry): string {
  const source = entrySourceHashOf(e);
  // 닫힘을 계산한 엔트리 — 소스 텍스트의 닫힘 해시(번들 출력의 `toString()` 이 아니다).
  if (source !== null) return fnv1a(`closure:${source}${entryDataHashOf(e)}`);
  // 닫힘이 없는 엔트리(하네스 · 닫힘을 계산하지 못한 키) — 플러그인 전체 해시로 되돌아간다.
  return fnv1a(e.build.toString() + entryDataHashOf(e) + kSharedSourceHash);
}

/**
 * What a built entry is stamped with: its hash, or nothing.
 *
 * The hash answers "has the recipe moved". It cannot answer "did this build draw
 * what the recipe says", because a fault outside the recipe — a library whose
 * glyphs are not on SCALE yet, an `Icon` collection missing a mode, a run that
 * found no collection at all — changes what the same recipe draws without
 * touching any input to the hash. An entry drawn off the rule that way and
 * stamped current is then skipped by every later run (`⏭ skipped — unchanged`)
 * and reported current by the stale listing, after the library has been mended:
 * only the force-rebuild option would bring it back, and nothing in the log says
 * so.
 *
 * An unstamped entry is rebuilt by the next run and listed as stale until then,
 * which is what a set drawn off the rule should cost — the same trade the docs
 * frames make when they fail to render (`generate.ts`).
 */
export function hashStampFor(hash: string, drawnOffTheRule: boolean): string {
  return drawnOffTheRule ? '' : hash;
}
