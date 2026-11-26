/// <reference types="@figma/plugin-typings" />

// Self-test for the wiring that turns the icon stroke mode on — the part of
// `generate.ts` and `verify.ts` that no harness executes.
//
// `selftest-registry-runtime` drives the step itself (`prepareIconModes`, the
// slot fit, the swap re-point) against a document double, but it cannot drive
// `generateComponents` or `verifyResetCompleteness`: both need the live Figma
// runtime. What they CALL is therefore only type-checked, and a call that is
// deleted still type-checks. Each of these was deleted in a scratch copy with
// `tsc` and every drill green, and the plugin then logged success while every
// slot icon fell back to the rescale path at the old stroke:
//
//   · the prelude's `prepareIconModes(...)` — without it no collection is ever
//     installed, and nothing says so;
//   · the per-entry `refreshIconModeCollection` — without it the collection
//     object taken in the prelude goes stale across an hour of entries;
//   · the per-entry drains — without them one entry's slot-icon notes surface
//     under whichever entry runs next, and the "unstamped" decision reads the
//     wrong entry's state;
//   · the stamp going through `hashStampFor` — without it an entry drawn off the
//     stroke rule is stamped current and skipped once the library is mended;
//   · `verify.ts`'s `clearIconModeIndex()` — without it a collection an earlier
//     Generate left installed is written into the verify builds as a stale object.
//
// Asserted on source text, the way `selftest-stale-sets` pins the hash recipe's
// wiring: the guarantee is structural ("this call is on this path"), and the
// behaviour each call buys is held by the registry-runtime drills. Comments are
// stripped first, so a call that survives only in a comment is not a call.

// A module (the `export {}` below), so the `process` / `require` declarations
// stay local instead of colliding with the other script files' globals.
declare const process: { exit(code: number): never; cwd(): string };
declare function require(m: string): unknown;
const { readFileSync } = require('fs') as { readFileSync(p: string, enc: string): string };
const { join } = require('path') as { join(...parts: string[]): string };

let failures = 0;
function check(label: string, fn: () => void): void {
  try {
    fn();
    console.log(`  ✓ ${label}`);
  } catch (err) {
    console.error(`  ✗ ${label}\n      ${err instanceof Error ? err.message : String(err)}`);
    failures++;
  }
}
function assert(cond: boolean, message: string): void {
  if (!cond) throw new Error(message);
}

/** Source with block comments and whole-line `//` comments removed. */
function codeOf(file: string): string {
  const text = readFileSync(join(process.cwd(), 'src', file), 'utf8');
  return text.replace(/\/\*[\s\S]*?\*\//g, '').replace(/^\s*\/\/.*$/gm, '');
}

function countOf(haystack: string, needle: string): number {
  let n = 0;
  for (let at = haystack.indexOf(needle); at >= 0; at = haystack.indexOf(needle, at + needle.length)) n++;
  return n;
}

const generate = codeOf('generate.ts');
const verify = codeOf('verify.ts');

check('generate.ts: the prelude calls prepareIconModes with the live lookups and the run log', () => {
  const call = /await prepareIconModes\(\s*iconSetForPins[\s\S]*?getVariableByIdAsync[\s\S]*?getVariableCollectionByIdAsync[\s\S]*?\blog,?\s*\)/;
  assert(call.test(generate), 'generate.ts must `await prepareIconModes(<Icon set>, getVariableByIdAsync, getVariableCollectionByIdAsync, log)`');
  const preludeGlyphs = generate.indexOf('await importGlyphs()');
  const entryGlyphs = generate.indexOf('const entryGlyphs = await importGlyphs()');
  const prepare = generate.indexOf('await prepareIconModes(');
  assert(
    preludeGlyphs >= 0 && entryGlyphs > preludeGlyphs && prepare > preludeGlyphs && prepare < entryGlyphs,
    'prepareIconModes must run in the prelude — after the glyph import and before the entry loop',
  );
});

check('generate.ts: the install is only ever done by prepareIconModes (no second, unchecked path)', () => {
  assert(
    countOf(generate, 'installIconModeIndex(') === 0,
    'generate.ts must not call installIconModeIndex itself — the prelude step owns the install, the harness drives that step',
  );
});

check('generate.ts: the collection object is refreshed per entry, before the entry is hashed', () => {
  const refresh = generate.indexOf('await refreshIconModeCollection(');
  const entryGlyphs = generate.indexOf('const entryGlyphs = await importGlyphs()');
  const hash = generate.indexOf('const hash = entryContentHashOf(e)');
  assert(refresh >= 0, 'generate.ts must call refreshIconModeCollection');
  assert(
    refresh > entryGlyphs && refresh < hash,
    'refreshIconModeCollection must run per entry, beside the per-entry glyph import and ahead of the build',
  );
  assert(
    /try \{\s*await refreshIconModeCollection\([\s\S]*?\} catch/.test(generate),
    'a failed refresh must be caught — it must not be what fails the run',
  );
});

check('generate.ts: the slot-icon accumulators are drained in the prelude, after each build, and after a throw', () => {
  assert(
    countOf(generate, 'drainSlotIconNotes()') === 3,
    `drainSlotIconNotes() must be called three times (prelude, success path, failure path), found ${countOf(generate, 'drainSlotIconNotes()')}`,
  );
  assert(
    countOf(generate, 'drainSlotIconWithoutCollection()') === 3,
    `drainSlotIconWithoutCollection() must be called three times (prelude, success path, failure path), found ${countOf(generate, 'drainSlotIconWithoutCollection()')}`,
  );
  const prelude = generate.indexOf('drainSlotIconNotes();');
  const prepare = generate.indexOf('await prepareIconModes(');
  assert(prelude >= 0 && prelude < prepare, 'the prelude must reset the accumulators before the run draws anything');
  assert(
    /drawnOffStrokeRule = slotIconNotes\.length > 0 \|\| withoutCollection/.test(generate),
    'the success path must read the notes AND the no-collection flag into drawnOffStrokeRule',
  );
});

check('generate.ts: an entry drawn off the stroke rule is not stamped current', () => {
  assert(
    /setPluginData\(kHashDataKey, hashStampFor\(hash, drawnOffStrokeRule\)\)/.test(generate),
    'the stamp must be hashStampFor(hash, drawnOffStrokeRule)',
  );
  assert(
    !/setPluginData\(kHashDataKey, hash\)/.test(generate),
    'no path may stamp the bare hash — it would claim current for a set drawn off the rule',
  );
});

check("verify.ts: the verify builds start from no collection, after the glyph index and before anything is drawn", () => {
  const glyphs = verify.indexOf('installGlyphIndex(glyphIndex)');
  const clear = verify.indexOf('clearIconModeIndex()');
  const drain = verify.indexOf('drainInexactIconSizes()', glyphs);
  assert(glyphs >= 0 && clear > glyphs, 'verify.ts must call clearIconModeIndex() after installGlyphIndex(glyphIndex)');
  assert(drain > clear, 'clearIconModeIndex() must run before the first drain, ahead of every build');
  assert(/import \{[^}]*\bclearIconModeIndex\b[^}]*\} from '\.\/helpers'/.test(verify), 'verify.ts must import clearIconModeIndex');
});

// ─── The glyph colour a slot carries (`icon-content.ts`) ──────────────────────
//
// The same shape of guarantee, for the same reason: the harness drives the prelude
// step (`prepareContentColors`) and the flush (`flushContentModes`) against the
// double, but cannot drive `generateComponents` — so a call deleted from it still
// type-checks. Each of these, deleted in a scratch copy with `tsc` and every drill
// green, left the plugin logging success while glyphs read the first mode of the
// content collection (on-surface) on every variant:
//
//   · the prelude's `prepareContentColors(...)` — without it no collection is
//     installed and every glyph is painted directly, with nothing to say so;
//   · the per-entry `refreshContentCollections` — without it the collection objects
//     taken in the prelude go stale across an hour of entries;
//   · the `flushContentModes()` after the builder — without it the strokes are bound
//     to `content/current` and no slot frame pins a mode;
//   · the stamp reading the content flag — without it an entry drawn directly because
//     the file has no content collection is stamped current and skipped after Import;
//   · `verify.ts`'s `clearContentIndex()` — without it a collection an earlier
//     Generate left installed is written into the verify builds as a stale object.

check('generate.ts: the prelude calls prepareContentColors with the collections, the lookup and the run log', () => {
  assert(
    /prepareContentColors\(\s*collections,\s*lk,\s*log,?\s*\)/.test(generate),
    'generate.ts must call prepareContentColors(collections, lk, log)',
  );
  const iconModes = generate.indexOf('await prepareIconModes(');
  const content = generate.indexOf('prepareContentColors(');
  const entryGlyphs = generate.indexOf('const entryGlyphs = await importGlyphs()');
  assert(
    iconModes >= 0 && content > iconModes && content < entryGlyphs,
    'prepareContentColors must run in the prelude — after the icon mode step and before the entry loop',
  );
  assert(
    countOf(generate, 'installContentIndex(') === 0,
    'generate.ts must not install the content index itself — the prelude step owns the install, the harness drives that step',
  );
});

check('generate.ts: the content collection objects are refreshed per entry, before the entry is built', () => {
  const refresh = generate.indexOf('await refreshContentCollections(');
  const entryGlyphs = generate.indexOf('const entryGlyphs = await importGlyphs()');
  const hash = generate.indexOf('const hash = entryContentHashOf(e)');
  assert(refresh >= 0, 'generate.ts must call refreshContentCollections');
  assert(refresh > entryGlyphs && refresh < hash, 'refreshContentCollections must run per entry, ahead of the build');
  assert(
    /try \{\s*await refreshContentCollections\([\s\S]*?\} catch/.test(generate),
    'a failed refresh must be caught — it must not be what fails the run',
  );
});

check('generate.ts: each entry\'s glyph colours are pinned right after the builder and its tints, before anything reads the tree', () => {
  const build = generate.indexOf('node = await e.build(targetPage, lk)');
  const tints = generate.indexOf('flushTintLayers();', build);
  const flush = generate.indexOf('flushContentModes()', build);
  const keep = generate.indexOf('await reconcileRedrawnMembers()', build);
  assert(build >= 0 && tints > build, 'generate.ts must flush the tint layers after the build');
  assert(flush > tints, 'flushContentModes() must run after flushTintLayers()');
  assert(keep > flush, 'flushContentModes() must run before the redrawn members are settled — the settle and the fingerprint read the tree with its modes');
  assert(countOf(generate, 'flushContentModes()') === 1, `flushContentModes() must be called once per entry, found ${countOf(generate, 'flushContentModes()')}`);
});

check('generate.ts: the content accumulators are drained in the prelude, after each build, and after a throw', () => {
  assert(countOf(generate, 'drainDirectGlyphs()') === 3, `drainDirectGlyphs() must be called three times (prelude, success path, failure path), found ${countOf(generate, 'drainDirectGlyphs()')}`);
  assert(
    countOf(generate, 'drainContentWithoutCollection()') === 3,
    `drainContentWithoutCollection() must be called three times (prelude, success path, failure path), found ${countOf(generate, 'drainContentWithoutCollection()')}`,
  );
  assert(
    countOf(generate, 'dropPendingContentGlyphs()') === 2,
    `dropPendingContentGlyphs() must be called twice (prelude, failure path), found ${countOf(generate, 'dropPendingContentGlyphs()')}`,
  );
});

check('generate.ts: an entry drawn off the content rule is not stamped current', () => {
  assert(
    /contentOffRule\s*=\s*drainContentWithoutCollection\(\)\s*\|\|\s*contentFlush\.refused\.length > 0/.test(generate),
    'the content flag and the refused pins must feed contentOffRule',
  );
  assert(
    /drawnOffStrokeRule = slotIconNotes\.length > 0 \|\| withoutCollection \|\| contentOffRule/.test(generate),
    'drawnOffStrokeRule must include contentOffRule — it is what hashStampFor reads',
  );
});

check('verify.ts: the verify builds start from no content collection', () => {
  assert(countOf(verify, 'clearContentIndex()') === 1, 'verify.ts must call clearContentIndex() once');
  const clear = verify.indexOf('clearContentIndex()');
  const iconClear = verify.indexOf('clearIconModeIndex()');
  const drain = verify.indexOf('drainInexactIconSizes()', iconClear);
  assert(clear > iconClear && clear < drain, 'clearContentIndex() must follow clearIconModeIndex() and run before the first drain, ahead of every build');
  assert(/import \{[^}]*\bclearContentIndex\b[^}]*\} from '\.\/helpers'/.test(verify), 'verify.ts must import clearContentIndex');
});

if (failures > 0) {
  console.error(`\nselftest: icon-mode-wiring — ${failures} failure(s)`);
  process.exit(1);
}
console.log('\nselftest: icon-mode-wiring — all checks passed.');

export {};
