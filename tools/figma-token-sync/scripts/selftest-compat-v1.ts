// Self-test for src/compat/v1.ts (#3753 completion criterion: "union 처리
// 3함수가 같은 규칙" — this exercises the one shared formula, not the three
// call sites, since they now compose these two functions instead of each
// re-implementing the rule). Pure logic, no Figma runtime — runs under plain
// Node via `npm run selftest:compat-v1`. Exits non-zero on any assertion
// failure so it's wireable into CI without a Figma sandbox.

import {
  Dim,
  argbAlpha,
  argbToRgb,
  dimVal,
  exportedMonoFamily,
  familyTokenOf,
  isDim,
  isMonoRole,
  mergeTextStyleData,
  roleMetrics,
  textStyleData,
  type TextLeaf,
} from '../src/compat/v1';

// This script runs under plain Node (see package.json scripts), not the
// Figma plugin sandbox — `@types/node` isn't a dependency here, so `process`
// is declared locally rather than pulling in the whole Node type root.
declare const process: { exit(code: number): never };

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

function approx(a: number, b: number, eps = 1e-9): boolean {
  return Math.abs(a - b) < eps;
}

console.log('dimVal / isDim — number|Dim normalization');
check('a plain number passes through unchanged', () => {
  if (dimVal(16) !== 16) throw new Error(`got ${dimVal(16)}`);
});
check('a Dim normalizes to its .v', () => {
  const d: Dim = { v: 16, ref: 'Primitives/space/16', via: 'CoreSpace.space16' };
  if (dimVal(d) !== 16) throw new Error(`got ${dimVal(d)}`);
});
check('a Dim with ref:null (untokenized) still normalizes to .v', () => {
  const d: Dim = { v: 512, ref: null, via: null };
  if (dimVal(d) !== 512) throw new Error(`got ${dimVal(d)}`);
});
check('isDim rejects a plain number', () => {
  if (isDim(16)) throw new Error('isDim(16) should be false');
});
check('isDim accepts a Dim-shaped object', () => {
  if (!isDim({ v: 16, ref: null })) throw new Error('isDim({v,ref}) should be true');
});

console.log('argbToRgb / argbAlpha — schema v2 Color formula (alpha = ((argb>>>24)/255) * opacity)');
check('fully-opaque white (0xFFFFFFFF) → rgb(1,1,1), alpha 1', () => {
  const rgb = argbToRgb(0xffffffff);
  const alpha = argbAlpha(0xffffffff);
  if (!approx(rgb.r, 1) || !approx(rgb.g, 1) || !approx(rgb.b, 1)) throw new Error(JSON.stringify(rgb));
  if (!approx(alpha, 1)) throw new Error(`alpha=${alpha}`);
});
check('fully-transparent black (argb 0) → alpha 0 (union-fix #1: no longer always-opaque)', () => {
  const alpha = argbAlpha(0);
  if (!approx(alpha, 0)) throw new Error(`alpha=${alpha}, expected 0`);
});
check('half-alpha red (0x80FF0000) → rgb(1,0,0), alpha ≈ 0.502', () => {
  const argb = 0x80ff0000;
  const rgb = argbToRgb(argb);
  const alpha = argbAlpha(argb);
  if (!approx(rgb.r, 1) || !approx(rgb.g, 0) || !approx(rgb.b, 0)) throw new Error(JSON.stringify(rgb));
  if (!approx(alpha, 0x80 / 255, 1e-3)) throw new Error(`alpha=${alpha}`);
});
check('opacity multiplier composes with the argb alpha byte, not just the byte alone', () => {
  // Full-alpha argb (0xFF......) at opacity 0.5 → alpha 0.5. Regression
  // guard for a fix that reads the byte but forgets to multiply by opacity.
  const alpha = argbAlpha(0xffffffff, 0.5);
  if (!approx(alpha, 0.5)) throw new Error(`alpha=${alpha}`);
});
check('opacity omitted defaults to 1 (no silent zeroing)', () => {
  const alpha = argbAlpha(0xffffffff, undefined);
  if (!approx(alpha, 1)) throw new Error(`alpha=${alpha}`);
});
check('unsigned shift: a byte-set argb does not go negative (regression for >> vs >>>)', () => {
  // 0xFF000000 as a signed Int32 is negative; `>> 24` on it sign-extends and
  // yields -1, not 255 — this is exactly the bug an `>>` (not `>>>`) shift
  // would reintroduce.
  const alpha = argbAlpha(0xff000000);
  if (!(alpha >= 0)) throw new Error(`alpha=${alpha} went negative`);
  if (!approx(alpha, 1)) throw new Error(`alpha=${alpha}, expected 1`);
});

// ─── Family and line box — the code roles ───────────────────────────────────
//
// A code role reaches the builder as its role states it: the monospace family
// and a fixed px box in place of a multiplier. The box follows `CoreTextStyle`:
// stated, it wins; a multiplier stated alone over it replaces it.
console.log('\nfamily · line box — role metrics and overlays');
const code = roleMetrics('codeSm');
check('the export names one monospace family, and a code role carries it', () => {
  const mono = exportedMonoFamily();
  if (mono == null) throw new Error('the export names no monospace family');
  if (code?.fontFamily !== mono) throw new Error(`codeSm family ${String(code?.fontFamily)} ≠ ${mono}`);
  if (!isMonoRole('codeSm') || isMonoRole('bodyMedium')) throw new Error('isMonoRole disagrees with the roles');
});
check('a code role-only style is mono on its box, with no multiplier', () => {
  const ts = textStyleData({ role: 'codeSm' } as TextLeaf);
  if (ts.fontFamily !== code?.fontFamily) throw new Error(`family ${String(ts.fontFamily)}`);
  if (ts.lineHeightPx == null || ts.lineHeightPx !== code?.lineHeightPx) throw new Error(`box ${String(ts.lineHeightPx)}`);
  if (ts.lineHeight !== null) throw new Error(`multiplier ${String(ts.lineHeight)}, expected null`);
  if (ts.letterSpacing !== 0) throw new Error(`tracking ${String(ts.letterSpacing)}, expected 0`);
});
check('a multiplier stated over a code role replaces the box (newest statement wins)', () => {
  const ts = textStyleData({ role: 'codeSm', lineHeight: 1.4 } as TextLeaf);
  if (ts.lineHeight !== 1.4 || ts.lineHeightPx !== null) throw new Error(JSON.stringify(ts));
});
check('a box stated over a text role wins over its multiplier', () => {
  const ts = textStyleData({ role: 'bodyMedium', lineHeightPx: 21 } as TextLeaf);
  if (ts.lineHeightPx !== 21) throw new Error(JSON.stringify(ts));
});
check('a family a style overlays is not carried — only the role names one', () => {
  const ts = textStyleData({ role: 'bodyMedium', fontFamily: 'Geist Mono' } as TextLeaf);
  if (ts.fontFamily !== null) throw new Error(`family ${String(ts.fontFamily)}, expected null`);
});
check('merge: the box survives a partial that states no line height', () => {
  const base = textStyleData({ role: 'codeSm' } as TextLeaf);
  const over = textStyleData({ role: null } as TextLeaf);
  const m = mergeTextStyleData(base, over);
  if (m.lineHeightPx !== code?.lineHeightPx || m.fontFamily !== code?.fontFamily) throw new Error(JSON.stringify(m));
});
check('merge: a partial naming a text role brings that role — family and multiplier', () => {
  const base = textStyleData({ role: 'codeSm' } as TextLeaf);
  const over = textStyleData({ role: 'bodyMedium' } as TextLeaf);
  const m = mergeTextStyleData(base, over);
  if (m.fontFamily !== null || m.lineHeightPx !== null || m.lineHeight !== roleMetrics('bodyMedium')?.lineHeight) {
    throw new Error(JSON.stringify(m));
  }
});
check('merge: a partial naming a code role over a text role brings its box', () => {
  const base = textStyleData({ role: 'bodyMedium' } as TextLeaf);
  const over = textStyleData({ role: 'codeSm' } as TextLeaf);
  const m = mergeTextStyleData(base, over);
  if (m.lineHeightPx !== code?.lineHeightPx || m.fontFamily !== code?.fontFamily) throw new Error(JSON.stringify(m));
});
check('familyTokenOf: null is the text face, the exported family is mono, anything else throws', () => {
  if (familyTokenOf(null) !== 'sans') throw new Error('null');
  if (familyTokenOf(exportedMonoFamily()) !== 'mono') throw new Error('mono');
  let threw = false;
  try {
    familyTokenOf('JetBrains Mono');
  } catch {
    threw = true;
  }
  if (!threw) throw new Error('a family the export does not name must throw, not be guessed');
});

if (failures > 0) {
  console.error(`\n${failures} failure(s).`);
  process.exit(1);
}
console.log('\nAll compat/v1 self-tests passed.');
