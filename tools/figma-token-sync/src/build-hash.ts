/// <reference types="@figma/plugin-typings" />

/**
 * A hash of every hand-written source file in this plugin, injected at bundle time.
 *
 * ## What it is for
 *
 * It names the build. Every set the run draws is stamped with it, the run lock
 * carries it, and "다른 빌드" is judged by comparing it — so any edit under `src/`
 * moves it, which is right for an identity.
 *
 * It is also the recipe's fallback. A component is skipped as unchanged when its
 * recorded hash matches the entry's content hash (`content-hash.ts`). For an entry
 * whose import closure the bundler computed (`entry-source.ts`) that hash reads
 * the closure's source and not this value; for an entry with no closure — a
 * harness double, a key the bundler could not close — it is
 * `fnv1a(builder source + data + this)`. `Function.prototype.toString` returns
 * ONE function's own text, not the text of what it calls, so on the fallback path
 * this value is what makes an edit to shared drawing code count. Over-invalidation
 * redraws something that was already right; under-invalidation ships a canvas
 * that disagrees with the code and looks finished — the fallback goes the first way.
 *
 * Data-only changes keep their granularity on both paths: regenerating
 * `components.json` from a Dart contract edit rebuilds exactly the components whose
 * subtree changed (`entryDataHashOf`).
 *
 * ## Why a define rather than reading files
 *
 * The plugin runs in Figma's VM with no filesystem. The hash has to be computed by
 * whatever produces `code.js` and baked in. `npm run build` does that; the harnesses
 * run through `tsx` with no define, and get `dev` — which is right, because a
 * harness builds onto a fresh double every time and has no skip path to poison.
 */
declare const __SHARED_SOURCE_HASH__: string;

export const kSharedSourceHash: string =
  typeof __SHARED_SOURCE_HASH__ === 'string' ? __SHARED_SOURCE_HASH__ : 'dev';

/**
 * `branch@commit` of the bundle, injected by the same `npm run build` — for a
 * person reading a log, where the hash above is for the machine. The hash
 * says two builds differ; this says which commit each one is, which is the
 * question a designer and a developer sharing one file actually have to
 * settle (#4832). Every set the run draws is stamped with both, and the run's
 * first log line carries both.
 *
 * Deliberately no wall-clock time — two builds of the same commit are the
 * same build, and a timestamp here would make them compare unequal even
 * though nothing about the bundle differs. `promote()`'s "content is
 * identical, skip the rewrite" guard (`rebuild_bundle_from_main.sh`) depends
 * on that equality holding byte-for-byte. A person who wants to know exactly
 * when a build was produced reads `builtAt` in `code.js.owner.json`, which
 * `bundle-owner.mjs` writes fresh on every build regardless of commit.
 *
 * `dev` under the harnesses, for the same reason the hash is.
 */
declare const __BUILD_REF__: string;

export const kBuildRef: string = typeof __BUILD_REF__ === 'string' ? __BUILD_REF__ : 'dev';
