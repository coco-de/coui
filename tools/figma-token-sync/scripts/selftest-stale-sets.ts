/// <reference types="@figma/plugin-typings" />

// Self-test for src/stale-sets.ts — the read-only "낡은 세트 보기".
//
// Two things can be wrong without a canvas, and both would make the listing
// lie in the direction that matters (a set reported current that the next
// Generate rebuilds, or the reverse):
//
//   1. The hash recipe. The listing must compare against THE function the
//      build loop stamps with — not a copy of it. Asserted three ways: the
//      exported binding is the same function object (identity, not equal
//      output on a sample — a drifted copy also passes a sample until the day
//      it does not); generate.ts's loop calls that function and nothing else
//      concatenates `build.toString()`; stale-sets.ts contains no hashing of
//      its own.
//   2. The three-way classification and the sentence it prints.
//
// No Figma runtime — nodes are plain objects carrying only `type` and
// `getPluginData`, which is all `classifyRegistry` reads.

import {
  classifyRegistry,
  classifyStamp,
  expectedHashOf,
  formatStaleSets,
} from '../src/stale-sets';
import { kGenerationStampKey, makeGenerationStamp } from '../src/generation-stamp';
import { entryContentHashOf, kHashDataKey } from '../src/content-hash';
import type { RegistryEntry } from '../src/helpers';

declare const process: { exit(code: number): never; cwd(): string };
declare function require(m: string): unknown;
const { readFileSync } = require('fs') as {
  readFileSync(p: string, enc: string): string;
};
const { join } = require('path') as { join(...parts: string[]): string };

let failures = 0;

function check(label: string, fn: () => void): void {
  try {
    fn();
    console.log(`  ok  ${label}`);
  } catch (e) {
    failures++;
    console.error(`FAIL  ${label}\n      ${String(e)}`);
  }
}

function assert(cond: boolean, msg: string): void {
  if (!cond) throw new Error(msg);
}

function assertEq<T>(actual: T, expected: T, what: string): void {
  const a = JSON.stringify(actual);
  const b = JSON.stringify(expected);
  if (a !== b) throw new Error(`${what}: expected ${b}, got ${a}`);
}

// A builder that is never called — the hash reads its SOURCE TEXT, so two
// entries need textually different functions to get different hashes.
function fakeEntry(name: string, build: RegistryEntry['build']): RegistryEntry {
  return { section: 'Form', name, build };
}

function fakeNode(type: string, stored: string, extra: Record<string, string> = {}): SceneNode {
  return {
    type,
    getPluginData: (key: string) => (key === kHashDataKey ? stored : extra[key] ?? ''),
  } as unknown as SceneNode;
}

console.log('selftest: stale-sets');

check('hash recipe is content-hash.ts\'s function — identity, not a copy', () => {
  assert(
    expectedHashOf === entryContentHashOf,
    'stale-sets.expectedHashOf must BE content-hash.entryContentHashOf (same function object)',
  );
});

// Code lines only — a comment is allowed to EXPLAIN the recipe; what must not
// exist twice is a line that computes it.
function codeLines(src: string): string {
  return src
    .split('\n')
    .filter((l) => !/^\s*(\/\/|\*|\/\*)/.test(l))
    .join('\n');
}

check('content-hash.ts holds the one recipe — generate.ts and stale-sets.ts import it, neither computes it', () => {
  const recipe = codeLines(readFileSync(join(process.cwd(), 'src', 'content-hash.ts'), 'utf8'));
  const recipeCalls = recipe.match(/build\.toString\(\)/g) ?? [];
  assertEq(
    recipeCalls.length,
    1,
    'exactly one `build.toString()` concatenation in content-hash.ts (inside entryContentHashOf)',
  );
  const build = codeLines(readFileSync(join(process.cwd(), 'src', 'generate.ts'), 'utf8'));
  assert(
    /const hash = entryContentHashOf\(e\);/.test(build),
    'the build loop must take its hash from entryContentHashOf(e)',
  );
  assert(
    !/build\.toString\(\)/.test(build) && !/fnv1a\(/.test(build),
    'generate.ts must not hash on its own — it imports the recipe from content-hash.ts',
  );
  const listing = codeLines(readFileSync(join(process.cwd(), 'src', 'stale-sets.ts'), 'utf8'));
  assert(
    !/fnv1a\(/.test(listing) && !/build\.toString\(\)/.test(listing),
    'stale-sets.ts must not hash on its own — it imports the recipe from content-hash.ts',
  );
});

// The recipe module itself must not import back from either of its two
// consumers — that back-edge is exactly the cycle this file replaced (see
// content-hash.ts's header comment for the regression it caused).
check('content-hash.ts does not import generate.ts or stale-sets.ts (no cycle)', () => {
  const recipe = codeLines(readFileSync(join(process.cwd(), 'src', 'content-hash.ts'), 'utf8'));
  assert(
    !/from '\.\/generate'/.test(recipe) && !/from '\.\/stale-sets'/.test(recipe),
    'content-hash.ts must not import from generate.ts or stale-sets.ts',
  );
});

// The three wiring points a reader would otherwise have to trust "must have
// been done" — instructed exactly once, easy to add the pure function above
// without also adding its caller, its message route, or its button. Each is
// a source-text assertion because none of the four checks above would fail
// if this file went dark: the recipe can stay correct while nothing left in
// the plugin ever calls it.
check('Generate prints the stale-set summary at the end of a run (source text)', () => {
  const build = codeLines(readFileSync(join(process.cwd(), 'src', 'generate.ts'), 'utf8'));
  assert(
    /for \(const line of staleAfterRun\) log\.push\(line\);/.test(build),
    'generate.ts must push the stale-sets tail summary onto the run log',
  );
});

// The summary is extra information, not the run's result — a throw while
// classifying the live index (a removed-node alias reading `.type` /
// `getPluginData`, the same failure mode the per-entry catch earlier in this
// file already logs a real instance of) must not take a 71-minute run's
// whole `log` down with it. Asserted on source text because the failure only
// reproduces with a Figma node that throws mid-run — nothing a Node-side
// selftest can construct — so the guarantee this checks is structural: the
// call is inside a `try`, and the `catch` still assigns `staleAfterRun` so
// the `for` loop above still runs.
check('the stale-set summary is wrapped so it cannot take the run log down with it (source text)', () => {
  const build = codeLines(readFileSync(join(process.cwd(), 'src', 'generate.ts'), 'utf8'));
  assert(
    /try \{\s*staleAfterRun = formatStaleSets\(classifyRegistry\(/.test(build),
    'the classifyRegistry/formatStaleSets call must be inside a try block',
  );
  assert(
    /\} catch \(e\) \{\s*staleAfterRun = \[/.test(build),
    'the catch must still assign staleAfterRun (a warning line), not let the summary crash the run',
  );
});

check('code.ts routes the "stale-sets" message to the read-only listing (source text)', () => {
  const main = readFileSync(join(process.cwd(), 'code.ts'), 'utf8');
  assert(
    /msg\.type === 'stale-sets'/.test(main),
    'code.ts must route msg.type === \'stale-sets\' to listStaleSets/formatStaleSets',
  );
  assert(
    /formatStaleSets\(await listStaleSets\(\)\)/.test(main),
    'the "stale-sets" handler must call formatStaleSets(await listStaleSets())',
  );
});

check('ui.html has a "낡은 세트 보기" button wired and disabled while busy (source text)', () => {
  const ui = readFileSync(join(process.cwd(), 'ui.html'), 'utf8');
  assert(/id="stale-sets"/.test(ui), 'ui.html must have a button with id="stale-sets"');
  assert(
    /getElementById\('stale-sets'\)\.onclick/.test(ui),
    'the stale-sets button must have an onclick handler',
  );
  assert(
    /type: 'stale-sets'/.test(ui),
    'the stale-sets button must postMessage type: \'stale-sets\'',
  );
  assert(
    /\[[^\]]*'stale-sets'[^\]]*\]\.map\(\(id\) => document\.getElementById\(id\)\)/.test(ui),
    'the stale-sets button must be in the shared busy/disable list — otherwise it stays clickable mid-run',
  );
});

check('recipe is deterministic and reads the builder text', () => {
  const a = fakeEntry('FakeA', () => ({ a: 1 }) as unknown as ComponentNode);
  const aAgain = fakeEntry('FakeA', () => ({ a: 1 }) as unknown as ComponentNode);
  const b = fakeEntry('FakeA', () => ({ b: 2 }) as unknown as ComponentNode);
  assertEq(expectedHashOf(a), expectedHashOf(aAgain), 'same text → same hash');
  assert(expectedHashOf(a) !== expectedHashOf(b), 'different builder text → different hash');
  assert(/^[0-9a-f]{8}$/.test(expectedHashOf(a)), 'fnv1a shape: 8 hex chars');
});

check('classifyStamp — absent / stale (empty or different) / current', () => {
  assertEq(classifyStamp(undefined, 'abc', false), 'absent', 'no node');
  assertEq(classifyStamp('abc', 'abc', false), 'absent', 'no node wins over a matching stamp');
  assertEq(classifyStamp('', 'abc', true), 'stale', 'empty stamp (docs frame failed / never stamped)');
  assertEq(classifyStamp(undefined, 'abc', true), 'stale', 'missing stamp');
  assertEq(classifyStamp('zzz', 'abc', true), 'stale', 'different stamp');
  assertEq(classifyStamp('abc', 'abc', true), 'current', 'same stamp');
});

check('classifyRegistry — one row per entry, three buckets', () => {
  const current = fakeEntry('Current', () => ({ c: 1 }) as unknown as ComponentNode);
  const stale = fakeEntry('Stale', () => ({ s: 1 }) as unknown as ComponentNode);
  const unstamped = fakeEntry('Unstamped', () => ({ u: 1 }) as unknown as ComponentNode);
  const absent = fakeEntry('Absent', () => ({ x: 1 }) as unknown as ComponentNode);
  const notASet = fakeEntry('NotASet', () => ({ n: 1 }) as unknown as ComponentNode);
  const nodes = new Map<string, SceneNode>([
    ['Current', fakeNode('COMPONENT_SET', expectedHashOf(current))],
    ['Stale', fakeNode('COMPONENT_SET', 'deadbeef')],
    ['Unstamped', fakeNode('COMPONENT', '')],
    // A FRAME of the right name is not a built set (a designer snapshot, say).
    ['NotASet', fakeNode('FRAME', expectedHashOf(notASet))],
  ]);
  const report = classifyRegistry((n) => nodes.get(n), [current, stale, unstamped, absent, notASet]);
  assertEq(report.rows.length, 5, 'rows');
  assertEq(report.current, ['Current'], 'current');
  assertEq(report.stale, ['Stale', 'Unstamped'], 'stale');
  assertEq(report.absent, ['Absent', 'NotASet'], 'absent');
});

check('classifyRegistry — why stale: recipe / other-build / unstamped, and the reason line names the build (#4832)', () => {
  const recipe = fakeEntry('Recipe', () => ({ r: 1 }) as unknown as ComponentNode);
  const other = fakeEntry('Other', () => ({ o: 1 }) as unknown as ComponentNode);
  const unstamped = fakeEntry('Unstamped', () => ({ u: 1 }) as unknown as ComponentNode);
  const fresh = fakeEntry('Fresh', () => ({ f: 1 }) as unknown as ComponentNode);
  const mine = makeGenerationStamp({ sessionId: 's2', user: 'Dev' }, 'mine', 'main@aaaaaaa 2026-09-12T13:00Z', 0);
  const theirs = makeGenerationStamp({ sessionId: 's1', user: 'Design' }, 'theirs', 'feature@bbbbbbb 2026-09-12T12:11Z', 0);
  const nodes = new Map<string, SceneNode>([
    // Wrong hash, drawn by THIS build — the code moved under it.
    ['Recipe', fakeNode('COMPONENT_SET', 'old', { [kGenerationStampKey]: JSON.stringify(mine) })],
    // Wrong hash, drawn by ANOTHER build — no redraw here makes the listing quiet.
    ['Other', fakeNode('COMPONENT_SET', 'whatever', { [kGenerationStampKey]: JSON.stringify(theirs) })],
    ['Unstamped', fakeNode('COMPONENT', '')],
    ['Fresh', fakeNode('COMPONENT_SET', expectedHashOf(fresh), { [kGenerationStampKey]: JSON.stringify(mine) })],
  ]);
  const report = classifyRegistry((n) => nodes.get(n), [recipe, other, unstamped, fresh], expectedHashOf, 'mine');
  assertEq(report.stale, ['Recipe', 'Other', 'Unstamped'], 'stale');
  assertEq(report.current, ['Fresh'], 'current');
  assertEq(report.reasons?.recipe, ['Recipe'], 'recipe');
  assertEq(report.reasons?.['other-build'], ['Other'], 'other-build');
  assertEq(report.reasons?.unstamped, ['Unstamped'], 'unstamped');
  assertEq(report.otherBuilds, ['theirs (feature@bbbbbbb 2026-09-12T12:11Z) by Design'], 'the build behind the other-build row');
  const lines = formatStaleSets(report);
  assertEq(lines[0], '낡은 세트 3 / 전체 4 — Recipe, Other, Unstamped', 'first sentence unchanged');
  assertEq(
    lines[1],
    '  사유 — 레시피 변경 1 · 다른 빌드 1 (theirs (feature@bbbbbbb 2026-09-12T12:11Z) by Design) · 스탬프 없음 1',
    'the reason line',
  );
  // A report without reasons (assembled by hand, or from a build before the
  // stamp) prints the old two sentences and nothing more.
  const bare = formatStaleSets({ rows: report.rows, current: report.current, stale: report.stale, absent: [] });
  assertEq(bare.length, 1, 'no reason line without reasons');
});

check('classifyRegistry — a stale stamp from an older recipe is stale, not current', () => {
  // The exact failure the listing exists for: the code moved, the canvas did
  // not. A node stamped with the hash of the OLD builder text must be stale
  // against the new one.
  const before = fakeEntry('Select', () => ({ v: 'old' }) as unknown as ComponentNode);
  const after = fakeEntry('Select', () => ({ v: 'new' }) as unknown as ComponentNode);
  const node = fakeNode('COMPONENT_SET', expectedHashOf(before));
  assertEq(classifyRegistry(() => node, [after]).stale, ['Select'], 'stale after code change');
  assertEq(classifyRegistry(() => node, [before]).current, ['Select'], 'current for the code it was drawn from');
});

check('formatStaleSets — the two sentences', () => {
  const allCurrent = formatStaleSets({
    rows: [
      { name: 'A', status: 'current' },
      { name: 'B', status: 'current' },
    ],
    current: ['A', 'B'],
    stale: [],
    absent: [],
  });
  assertEq(allCurrent, ['캔버스 = 현재 코드 ✅ (전체 2)'], 'nothing stale, nothing absent');

  const mixed = formatStaleSets({
    rows: [
      { name: 'Button', status: 'current' },
      { name: 'Select', status: 'stale' },
      { name: 'Chip', status: 'stale' },
      { name: 'Ghost', status: 'absent' },
    ],
    current: ['Button'],
    stale: ['Select', 'Chip'],
    absent: ['Ghost'],
  });
  assertEq(
    mixed,
    ['낡은 세트 2 / 전체 4 — Select, Chip', '없음 1 — Ghost'],
    'stale count over the whole registry, names listed, absent on its own line',
  );

  const absentOnly = formatStaleSets({
    rows: [
      { name: 'A', status: 'current' },
      { name: 'Z', status: 'absent' },
    ],
    current: ['A'],
    stale: [],
    absent: ['Z'],
  });
  assertEq(
    absentOnly,
    ['캔버스 = 현재 코드 ✅ (전체 2)', '없음 1 — Z'],
    'absent sets do not make the canvas "stale" — they are a separate fact',
  );
});

// The failure this guards: right after a plugin rebuild every entry goes
// stale at once (shared source hash moves for all of them), and an
// unbounded `.join(', ')` turned this line into every component's name —
// once, in this file's own registry of ~100+.
check('formatStaleSets — the name list is capped, the counts are not', () => {
  const rows = Array.from({ length: 8 }, (_, i) => ({
    name: `Set${i}`,
    status: 'stale' as const,
  }));
  const manyStale = formatStaleSets({
    rows,
    current: [],
    stale: rows.map((r) => r.name),
    absent: [],
  });
  assertEq(
    manyStale,
    ['낡은 세트 8 / 전체 8 — Set0, Set1, Set2, Set3, Set4, … (+3)'],
    'first 5 names spelled out, the rest folded into a count — 8 and 8 stay exact',
  );

  const manyAbsent = formatStaleSets({
    rows: [{ name: 'Current', status: 'current' as const }],
    current: ['Current'],
    stale: [],
    absent: ['A', 'B', 'C', 'D', 'E', 'F'],
  });
  assertEq(
    manyAbsent,
    ['캔버스 = 현재 코드 ✅ (전체 1)', '없음 6 — A, B, C, D, E, … (+1)'],
    'absent line truncates the same way',
  );
});

if (failures > 0) {
  console.error(`\nselftest: stale-sets — ${failures} failure(s)`);
  process.exit(1);
}
console.log('selftest: stale-sets — all ok');
