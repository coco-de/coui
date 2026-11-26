// Self-test for `CONTROL_ROW_TIERS` (src/variables.ts) — the table that turns a
// control row's height into the `Semantic/ Dimension/control-size/<tier>` row a
// builder binds it to.
//
// ## What it defends
//
// The table exists twice. The authority is Dart: `CoreControlSize`
// (packages/coui_core/lib/src/size/control_size.dart) states the heights, and
// the token exporter names one `control-size/<tier>` row per height. The copy
// here is what a builder uses to find that row again, and the plugin reads no
// Dart, so it is numbers.
//
// When the two disagree the failure is silent: `controlHeightOrNull` finds no
// row, the builder keeps the literal height, and the set draws — at the
// authored height under every density, which is the one thing a density row
// exists to change. So the heights are read FROM the Dart source here rather
// than restated.

import { CONTROL_ROW_TIERS } from '../src/variables';

declare const process: { exit(code: number): never; cwd(): string };
declare function require(id: string): {
  readFileSync(path: string, encoding: string): string;
  join(...parts: string[]): string;
};

const { readFileSync } = require('fs');
const { join } = require('path');

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

// `process.cwd()`, not `__dirname` — see selftest-text-style-name.ts.
const REPO = join(process.cwd(), '..', '..');
const CONTROL_SIZE = join(REPO, 'packages', 'coui_core', 'lib', 'src', 'size', 'control_size.dart');
const EXPORTER = join(REPO, 'packages', 'coui_core', 'bin', 'export_figma_tokens.dart');

/** `heightXs` → 24, read from `static const double heightXs = CoreSize.size24;`. */
function heightsFromDart(): Map<string, number> {
  const src = readFileSync(CONTROL_SIZE, 'utf8');
  const out = new Map<string, number>();
  for (const m of src.matchAll(/static const double (height[A-Za-z0-9]+) = CoreSize\.size(\d+);/g)) {
    out.set(m[1], Number(m[2]));
  }
  return out;
}

/** The exporter's `'<tier>': CoreControlSize.<member>` pairs for the
 *  `control-size/<tier>` rows. */
function tiersFromExporter(): Map<string, string> {
  const src = readFileSync(EXPORTER, 'utf8');
  const start = src.indexOf("'control-size/${e.key}'");
  assert(start !== -1, 'control-size rows not found — did the exporter rename them?');
  const blockStart = src.lastIndexOf('for (final e in <String, double>{', start);
  assert(blockStart !== -1, 'the tier map above the control-size rows was not found');
  const block = src.slice(blockStart, start);
  const out = new Map<string, string>();
  for (const m of block.matchAll(/'([a-z0-9]+)': CoreControlSize\.(height[A-Za-z0-9]+)/g)) {
    out.set(m[1], m[2]);
  }
  return out;
}

console.log('selftest: control rows');

const heights = heightsFromDart();
const tiers = tiersFromExporter();

check('read the ladder and the exporter rows (not nothing)', () => {
  assert(heights.size === 6, `read ${heights.size} heights from CoreControlSize`);
  assert(tiers.size === 6, `read ${tiers.size} control-size rows from the exporter`);
});

check('every exporter row is in the table under the height Dart states', () => {
  for (const [tier, member] of tiers) {
    const px = heights.get(member);
    assert(px !== undefined, `${member} has no height in control_size.dart`);
    assert(CONTROL_ROW_TIERS[px as number] === tier, `${px} → ${CONTROL_ROW_TIERS[px as number]}, exporter says ${tier}`);
  }
});

check('the table names no row the exporter does not write', () => {
  const written = new Set(tiers.keys());
  for (const tier of Object.values(CONTROL_ROW_TIERS)) {
    assert(written.has(tier), `table names control-size/${tier}, which the exporter does not write`);
  }
});

if (failures > 0) {
  console.error(`\n${failures} check(s) failed`);
  process.exit(1);
}
console.log('selftest: control rows — all passed');
