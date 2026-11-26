// Self-test for the role→variable binding decision in `applyRole`
// (src/helpers.ts), reached through both opts builders, and for the same
// decision `makeLabel` puts again before it queues a label for a text style.
// Pure logic — a stub `VarLookup` is enough because the decision reads only
// the style and the role metrics table. Runs under plain Node via
// `npm run selftest`.
//
// ## What it defends
//
// Figma binds `fontSize` to a variable, and **a bound variable overwrites the
// literal the builder set**. So a text style that says "role `bodySmall`, but
// 10px on this rung" — which is how a size ladder written as a per-size
// `fontSize` overlay on a role-bearing flat default reaches the plugin —
// rendered at the role's 14 on every rung, and the 10 the code stated reached
// no node at all. Checkbox · RadioGroup · Chip all state their ladders that
// way; the canvas drew one size for six rungs until a designer's own copy was
// held next to it.
//
// The failure is invisible from the code side: the builder does set the right
// number, the export carries the right number, and the node ends up with the
// wrong one. Only the binding explains it, so the binding is what this test
// pins.

import { textLabelOpts, typographyColorOpts, type TextStyleData } from '../src/helpers';
import { textStyleData, type RoleMetrics, type TextLeaf } from '../src/compat/v1';
import { COMPONENTS, TYPOGRAPHY } from '../src/data';
import { weightStyle } from '../src/paint';
import { createTextStyleAttacher, faceKeyOf } from '../src/text-style-attach';
import {
  makeLabel,
  resetPendingTextStyles,
  roleDeparture,
  takePendingTextStyles,
} from '../src/text-nodes';
import { VarLookup } from '../src/variables';

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

// The attach is async, and this file bundles to CommonJS, where there is no
// top-level await — so an async check is started here and the report below
// waits for it.
const asyncChecks: Promise<void>[] = [];
function checkAsync(label: string, fn: () => Promise<void>): void {
  asyncChecks.push(
    fn().then(
      () => console.log(`  ok  ${label}`),
      (e) => {
        failures++;
        console.error(`FAIL  ${label}\n      ${String(e)}`);
      },
    ),
  );
}

function assert(cond: boolean, msg: string): void {
  if (!cond) throw new Error(msg);
}

function assertEq<T>(actual: T, expected: T, what: string): void {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(`${what}: expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}

// The decision never touches the lookup — colours resolve through it, and a
// name is all `labelColor` asks for.
const lk = { sem: (n: string) => ({ name: n }) } as never;

function style(over: Partial<TextStyleData>): TextStyleData {
  return { fontSize: null, fontWeight: null, lineHeight: null, color: null, ...over };
}

console.log('selftest: role binding');

// The fixtures below reason about `bodyMedium` as a 14px, 400, 150%, −0.01em
// role. Checked against the export first, so a scale change reads as "the
// premise moved" rather than as a dozen unrelated failures.
check('premise: bodyMedium is 14 · 400 · 150% · −0.01em in the export', () => {
  const m = (TYPOGRAPHY as Record<string, RoleMetrics>).bodyMedium;
  assertEq([m?.fontSize, m?.fontWeight, m?.lineHeight, m?.letterSpacing], [14, 400, 1.5, -0.01], 'bodyMedium');
});

check('a role-only style keeps its role — the semantic variable is the point', () => {
  const o = textLabelOpts(lk, style({ role: 'bodyMedium' }));
  assertEq(o.role, 'bodyMedium', 'role');
  assertEq(o.size, 14, 'size falls back to 14 when the style states none');
});

check('a role plus its OWN size keeps the role', () => {
  // `bodyMedium` is 14 in the scale — a style restating 14 is not a departure,
  // and dropping the role there would lose the semantic binding for nothing.
  const o = textLabelOpts(lk, style({ role: 'bodyMedium', fontSize: 14 }));
  assertEq(o.role, 'bodyMedium', 'role kept');
  assertEq(o.size, 14, 'size');
});

check('a role plus a DIFFERENT size drops the role — otherwise the binding '
  + 'overwrites the size', () => {
  for (const [size, label] of [[10, 'xs'], [16, 'lg'], [18, 'xl']] as const) {
    const o = textLabelOpts(lk, style({ role: 'bodyMedium', fontSize: size }));
    assert(o.role == null, `${label}: role must be dropped, got ${String(o.role)}`);
    assertEq(o.size, size, `${label}: the stated size survives`);
  }
});

check('dropping the role keeps its tracking ratio, not its pixel value', () => {
  // `letter-spacing/body-medium` holds −0.14 PIXELS — computed for 14px. Bound
  // to a 10px label it states a ratio nobody chose, so the binding goes and
  // the em ratio (−0.01) is re-applied to the size that renders.
  const o = textLabelOpts(lk, style({ role: 'bodyMedium', fontSize: 10 }));
  assertEq(o.letterSpacingEm, -0.01, 'the role em ratio is carried');
  assert(o.role == null, 'and the role binding is gone');
});

check('an explicitly stated letterSpacing still wins over the role ratio', () => {
  const o = textLabelOpts(lk, style({ role: 'bodyMedium', fontSize: 10, letterSpacing: -0.05 }));
  assertEq(o.letterSpacingEm, -0.05, 'explicit wins');
});

check('the same decision applies through typographyColorOpts', () => {
  // The two builders differ only in who wins on colour; the role decision
  // must not be one of the differences.
  const kept = typographyColorOpts(lk, style({ role: 'bodyMedium', fontSize: 14 }), null);
  const dropped = typographyColorOpts(lk, style({ role: 'bodyMedium', fontSize: 18 }), null);
  assertEq(kept.role, 'bodyMedium', 'same size → kept');
  assert(dropped.role == null, 'different size → dropped');
  assertEq(dropped.size, 18, 'and the size survives');
});

check('an unknown role is left alone — the table decides, and it cannot '
  + 'decide about a role it does not have', () => {
  const o = textLabelOpts(lk, style({ role: 'notARole', fontSize: 99 }));
  assertEq(o.role, 'notARole', 'kept');
});

check('a style with no role is unaffected', () => {
  const o = textLabelOpts(lk, style({ fontSize: 10 }));
  assert(o.role == null, 'no role to keep');
  assertEq(o.size, 10, 'size');
});

// ── Letter-spacing: the second tier ─────────────────────────────────────────
//
// Dropping the role (above) also drops the only letter-spacing variable a
// label could reach, so every rung whose size departed from its role — the
// whole Checkbox · RadioGroup ladder — carried a BOUND font size next to a
// LITERAL letter spacing on the same node. The exporter now emits a
// size-keyed step (`letter-spacing/size-<n>`) and `makeLabel` binds it as a
// second tier, the same two-step `fontSize` already makes.
//
// The binding is value-gated: a bound variable overwrites the literal, so it
// may attach only when the variable already holds what the literal says.
// That gate is what keeps this a render-neutral change, and it is what the
// checks below pin — both directions, because "binds when equal" and "stays
// literal when not" are separately breakable.

interface FakeVariable {
  name: string;
  variableCollectionId: string;
  valuesByMode: Record<string, unknown>;
}

function fakeVar(coll: string, name: string, valuesByMode: Record<string, unknown>): FakeVariable {
  return { name, variableCollectionId: coll, valuesByMode };
}

// Fixture values, not a curve: the exporter owns the tracking rule
// (`_opticalTrackingEm` in export_figma_tokens.dart) and this file must not
// grow a copy of it. These are the steps the checks reason about — the rule
// tracks below 20px at −1% and from 20px at −2%.
const SIZE_STEPS: Record<number, number> = { 10: -0.1, 14: -0.14, 16: -0.16, 24: -0.48 };
const MODES = ['Mobile', 'Tablet', 'Desktop'];

function catalog(): VarLookup {
  const vars: FakeVariable[] = [
    // `labelColor` resolves the fallback foreground through `sem` even when
    // the node is then painted with `rawColor`.
    fakeVar('s', 'color/on-surface', { Light: 0, Dark: 0 }),
    fakeVar('p', 'font/family/Pretendard', { Value: 'Pretendard' }),
    // Two monospace families, the old one first: Import never deletes a
    // variable, so a document that moved faces holds both, and the mono role
    // must resolve to the one the export names — not to whichever sorts first.
    fakeVar('p', 'font/family/JetBrains Mono', { Value: 'JetBrains Mono' }),
    fakeVar('p', 'font/family/Geist Mono', { Value: 'Geist Mono' }),
    ...[10, 12, 14, 16, 18, 24].map((n) => fakeVar('p', `font/size/${n}`, { Value: n })),
    fakeVar('t', 'font-size/body-medium', { Mobile: 14, Tablet: 14, Desktop: 14 }),
    fakeVar('t', 'letter-spacing/body-medium', { Mobile: -0.14, Tablet: -0.14, Desktop: -0.14 }),
    // A code role: its own size, and no tracking.
    fakeVar('t', 'font-size/code-sm', { Mobile: 12, Tablet: 12, Desktop: 12 }),
    fakeVar('t', 'letter-spacing/code-sm', { Mobile: 0, Tablet: 0, Desktop: 0 }),
    ...Object.entries(SIZE_STEPS).map(([n, px]) =>
      fakeVar('t', `letter-spacing/size-${n}`, Object.fromEntries(MODES.map((m) => [m, px]))),
    ),
    // A step whose modes disagree — must never bind: no single value to be
    // equal to.
    fakeVar('t', 'letter-spacing/size-18', { Mobile: -0.27, Tablet: -0.27, Desktop: -0.3 }),
  ];
  const collById = new Map<string, string>([
    ['s', '1-1. Semantic/ Color · CoUI'],
    ['p', '0. Primitives'],
    ['t', '1-2. Semantic/ Typography'],
  ]);
  return new VarLookup(vars as unknown as Variable[], collById);
}

// The smallest `figma` a `makeLabel` call touches: a text node that records
// what gets bound. `rawColor` keeps the fill off the paint helpers, so no
// variable-paint API is needed.
interface FakeTextNode {
  fontName: { family: string; style: string } | null;
  characters: string;
  fontSize: number;
  letterSpacing: { unit: string; value: number } | undefined;
  lineHeight: unknown;
  fills: unknown;
  opacity: number;
  removed: boolean;
  textDecoration: string;
  textStyleId: string;
  bound: Record<string, string>;
  setBoundVariable(field: string, v: { name: string } | null): void;
  setTextStyleIdAsync(id: string): Promise<void>;
}

// The fake's text styles, by id. `setTextStyleIdAsync` writes the whole bundle
// onto the node — what the canvas did when it was measured: a `titleSmall`
// label drawn Bold came back SemiBold, a 120% `bodyMedium` label came back at
// 160%. Without that the attach below would be a no-op and could not show the
// overlay being lost.
interface FakeTextStyle {
  id: string;
  name: string;
  fontName: { family: string; style: string };
  fontSize: number;
  lineHeight: { unit: string; value: number };
  letterSpacing: { unit: string; value: number };
}
const fakeStyles = new Map<string, FakeTextStyle>();

function installFigma(): void {
  (globalThis as { figma?: unknown }).figma = {
    createText(): FakeTextNode {
      const node: FakeTextNode = {
        fontName: null,
        characters: '',
        fontSize: 0,
        letterSpacing: undefined,
        lineHeight: null,
        fills: [],
        opacity: 1,
        removed: false,
        textDecoration: 'NONE',
        textStyleId: '',
        bound: {},
        setBoundVariable(field, v) {
          if (v == null) delete node.bound[field];
          else node.bound[field] = v.name;
        },
        async setTextStyleIdAsync(id) {
          const style = fakeStyles.get(id);
          if (style == null) throw new Error(`no style ${id}`);
          node.textStyleId = id;
          node.fontName = { ...style.fontName };
          node.fontSize = style.fontSize;
          node.lineHeight = { ...style.lineHeight };
          node.letterSpacing = { ...style.letterSpacing };
          node.textDecoration = 'NONE';
        },
      };
      return node;
    },
  };
}

function label(lk: VarLookup, ts: TextStyleData): FakeTextNode {
  const opts = textLabelOpts(lk, ts);
  opts.rawColor = { r: 0, g: 0, b: 0 };
  return makeLabel('x', lk, opts) as unknown as FakeTextNode;
}

console.log('selftest: letter-spacing size tier');
installFigma();
const lk2 = catalog();

check('letterSpacingOrNull answers only when every mode holds the literal', () => {
  assertEq(lk2.letterSpacingOrNull(14, -0.14)?.name, 'letter-spacing/size-14', 'on-curve');
  assertEq(lk2.letterSpacingOrNull(14, -0.14 + 1e-9)?.name, 'letter-spacing/size-14', 'last-ulp');
  assert(lk2.letterSpacingOrNull(14, -0.1) == null, 'off-curve value must not bind');
  assert(lk2.letterSpacingOrNull(22, -0.22) == null, 'no step for that size');
  assert(lk2.letterSpacingOrNull(18, -0.27) == null, 'modes disagree → no single value → no bind');
});

check('a kept role binds the ROLE leaf, first tier, as before', () => {
  // `textStyleData` fills `letterSpacing` from the role's metrics, so a
  // builder's style always states the em — this is the shape that reaches
  // `makeLabel` from every registry entry.
  const n = label(lk2, style({ role: 'bodyMedium', fontSize: 14, letterSpacing: -0.01 }));
  assertEq(n.bound.fontSize, 'font-size/body-medium', 'fontSize');
  assertEq(n.bound.letterSpacing, 'letter-spacing/body-medium', 'letterSpacing');
});

check('a dropped role whose carried ratio lands on the curve binds the SIZE step', () => {
  // A size ladder: `bodyMedium` (−0.01em) overlaid to 16 → −0.16, and the curve
  // tracks 16px at −0.01 too. Before this tier: fontSize bound, letter spacing
  // literal — on the same node.
  const n = label(lk2, style({ role: 'bodyMedium', fontSize: 16 }));
  assertEq(n.bound.fontSize, 'font/size/16', 'fontSize falls to the primitive step');
  assertEq(n.bound.letterSpacing, 'letter-spacing/size-16', 'letterSpacing falls to the size step');
  assertEq(n.letterSpacing, { unit: 'PIXELS', value: -0.16 }, 'the literal is still written');
});

check('a dropped role whose carried ratio is OFF the curve stays a literal', () => {
  // `bodyMedium`'s −0.01em carried onto 24px is −0.24; the curve says 24px
  // tracks at −0.02 (−0.48). Binding the step would overwrite the literal and
  // move the picture — so it must not.
  const n = label(lk2, style({ role: 'bodyMedium', fontSize: 24 }));
  assertEq(n.bound.fontSize, 'font/size/24', 'fontSize still binds');
  assert(n.bound.letterSpacing == null, `letterSpacing must stay literal, bound ${n.bound.letterSpacing}`);
  assertEq(n.letterSpacing, { unit: 'PIXELS', value: -0.24 }, 'and the literal is the carried ratio');
});

check('an explicit letterSpacing that happens to equal the curve binds; one that does not, does not', () => {
  const on = label(lk2, style({ fontSize: 14, letterSpacing: -0.01 }));
  assertEq(on.bound.letterSpacing, 'letter-spacing/size-14', 'explicit −0.01em at 14 = −0.14 = the step');
  const off = label(lk2, style({ fontSize: 14, letterSpacing: -0.05 }));
  assert(off.bound.letterSpacing == null, 'explicit −0.05em at 14 = −0.7 ≠ step → literal');
  assert(Math.abs((off.letterSpacing?.value ?? 0) - -0.7) <= 1e-6, `literal kept, got ${off.letterSpacing?.value}`);
});

check('a bound step always agrees with the literal — the render-neutral invariant', () => {
  // Whatever binds, the variable's value IS the node's literal. This is the
  // one property that makes the whole tier safe to ship without a picture.
  for (const [size, ts] of [
    [16, style({ role: 'bodyMedium', fontSize: 16 })],
    [14, style({ fontSize: 14, letterSpacing: -0.01 })],
  ] as const) {
    const n = label(lk2, ts);
    const boundName = n.bound.letterSpacing;
    assert(boundName != null, `${size}: expected a binding`);
    const v = lk2.tryGet('Semantic/Typography', boundName!)!;
    for (const raw of Object.values(v.valuesByMode)) {
      assert(Math.abs((raw as number) - n.letterSpacing!.value) <= 1e-6, `${size}: bound value ≠ literal`);
    }
  }
});

// ── Style admission: every field the style states ──────────────────────────
//
// A kept role does more than bind variables — `makeLabel` queues the role's
// TEXT STYLE for it, and attaching a style writes the style's whole bundle onto
// the node: size, weight, line height, tracking, family. So the size test above
// is one fifth of the question. A label that keeps its role's size but states
// another weight (Steps' digit at 700 over `labelLarge`'s 500) or another line
// height (TextField's value text at 120% over `bodyMedium`'s own) came out of
// the attach as the role — Core drew the overlay, the canvas did not.
//
// Writing the field back after the attach is no fix: on the canvas that
// detaches the style and leaves the node bound to the role's semantic
// variables. So these checks pin the other half of the decision — the role is
// dropped before the label is queued — and then run the real attacher over the
// queue, so a gate that lets a departing label through shows up as the weight
// it would have lost.

console.log('selftest: style admission');
installFigma();
resetPendingTextStyles();

check('a role plus a DIFFERENT weight drops the role', () => {
  const o = textLabelOpts(lk, style({ role: 'labelLarge', fontSize: 14, fontWeight: 700 }));
  assert(o.role == null, `role must be dropped, got ${String(o.role)}`);
  assertEq(o.style, 'Bold', 'the stated weight survives');
  assertEq(o.size, 14, 'and the size, which never departed');
});

check('a role restating its OWN weight keeps the role', () => {
  const o = textLabelOpts(lk, style({ role: 'labelLarge', fontWeight: 500 }));
  assertEq(o.role, 'labelLarge', 'role kept');
  assertEq(o.style, 'Medium', 'face');
});

check('a role plus a DIFFERENT line height drops the role', () => {
  const o = textLabelOpts(lk, style({ role: 'bodyMedium', lineHeight: 1.2 }));
  assert(o.role == null, `role must be dropped, got ${String(o.role)}`);
  assertEq(o.lineHeightPercent, 120, 'the stated line height survives');
});

check('a role plus a DIFFERENT tracking drops the role — the role leaf would bind over it', () => {
  // Kept, this label would bind `letter-spacing/body-medium` (−0.14 px) over the
  // −0.7 px it states, and then the style would write −0.14 again.
  const o = textLabelOpts(lk, style({ role: 'bodyMedium', fontSize: 14, letterSpacing: -0.05 }));
  assert(o.role == null, `role must be dropped, got ${String(o.role)}`);
  assertEq(o.letterSpacingEm, -0.05, 'the stated ratio survives');
});

check('the same decision applies through typographyColorOpts', () => {
  const o = typographyColorOpts(lk, style({ role: 'labelLarge', fontWeight: 700 }), null);
  assert(o.role == null, 'weight departure → dropped');
});

// Read from the export rather than restated, the way `selftest-text-style-name`
// reads the exporter: the overlays this protects are Core's, and a new one is
// covered the day it lands. The face comparison is written out here rather than
// borrowed from `roleDeparture`, so the check does not grade itself.
check('every exported role-bearing style whose weight departs from its role drops the role', () => {
  const roles = TYPOGRAPHY as Record<string, { fontWeight: number | null }>;
  let roleLeaves = 0;
  let departing = 0;
  const kept: string[] = [];
  const walk = (value: unknown, path: string): void => {
    if (value == null || typeof value !== 'object') return;
    if (Array.isArray(value)) {
      value.forEach((v, i) => walk(v, `${path}[${i}]`));
      return;
    }
    const record = value as Record<string, unknown>;
    const role = record.role;
    if (typeof role === 'string' && roles[role] != null) {
      roleLeaves++;
      const ts = textStyleData(record as unknown as TextLeaf);
      if (weightStyle(ts.fontWeight) !== weightStyle(roles[role].fontWeight)) {
        departing++;
        if (textLabelOpts(lk, ts).role != null) kept.push(`${path} (${role} at ${ts.fontWeight})`);
      }
    }
    for (const [k, v] of Object.entries(record)) walk(v, path === '' ? k : `${path}.${k}`);
  };
  walk(COMPONENTS, '');
  // Guards the walk, not the data: zero role leaves means the export's shape
  // moved and this check would pass over nothing.
  assert(roleLeaves > 0, 'found no role-bearing styles in the export — did its shape change?');
  assert(kept.length === 0, `kept a role over a different weight: ${kept.join(' · ')}`);
  console.log(`      (${departing} of ${roleLeaves} role-bearing styles state another weight)`);
});

// `makeLabel` is the last word, because a builder can restate a field after the
// opts are built — Steps draws its current step's title Bold over the role's
// own face (`titleOpts.style = 'Bold'`), and `applyRole` never saw that.
check('makeLabel drops a role the opts kept when the face it draws departs', () => {
  resetPendingTextStyles();
  const o = textLabelOpts(lk2, style({ role: 'bodyMedium', fontSize: 14, fontWeight: 400, letterSpacing: -0.01 }));
  assertEq(o.role, 'bodyMedium', 'precondition: the opts kept the role');
  o.style = 'Bold';
  o.rawColor = { r: 0, g: 0, b: 0 };
  const n = makeLabel('x', lk2, o) as unknown as FakeTextNode;
  assertEq(n.bound.fontSize, 'font/size/14', 'fontSize falls to the primitive step');
  assertEq(n.bound.letterSpacing, 'letter-spacing/size-14', 'letterSpacing falls to the size step');
  assertEq(takePendingTextStyles().length, 0, 'and nothing is queued for a style');
});

// A style that names only its role is the role, whatever the role is — the
// two judgements must agree on it. Before the opts builders filled unstated
// fields from the scale, `applyRole` kept this role while `makeLabel` saw a
// 14px Regular label and dropped it. `bodyMedium` (14, Regular) hid that, so
// this uses a role that is neither.
check('a role-only style keeps its role through makeLabel — both judgements see the role', () => {
  resetPendingTextStyles();
  const n = label(lk2, style({ role: 'headlineLarge' }));
  const queued = takePendingTextStyles();
  const m = (TYPOGRAPHY as Record<string, RoleMetrics>).headlineLarge;
  assertEq(queued.length, 1, 'queued for its style');
  assertEq(n.fontSize, m.fontSize, 'draws the role size');
  assertEq(n.fontName?.style, weightStyle(m.fontWeight), 'and the role face');
});

check('a label drawn in another family than its role departs', () => {
  assertEq(roleDeparture('bodyMedium', { family: 'mono' }), 'family', 'mono over a text role');
  assertEq(roleDeparture('bodyMedium', { family: 'sans' }), null, 'sans is the text role family');
  resetPendingTextStyles();
  const o = textLabelOpts(lk2, style({ role: 'bodyMedium', fontSize: 14, fontWeight: 400, letterSpacing: -0.01 }));
  o.family = 'mono';
  o.rawColor = { r: 0, g: 0, b: 0 };
  const n = makeLabel('x', lk2, o) as unknown as FakeTextNode;
  assertEq(n.fontName?.family, 'Geist Mono', 'drawn in the exported mono — not the older family that sorts first');
  assertEq(n.bound.fontSize, 'font/size/14', 'no role variable');
  assertEq(takePendingTextStyles().length, 0, 'and no style queued');
});

// A code role's style draws in mono on a fixed 21px box. Judged against the
// role's OWN family and box, so a mono label keeps a code role and a sans one,
// or one on a multiplier, does not.
check('a code role is mono on a px box — its own family and box keep it', () => {
  const m = (TYPOGRAPHY as Record<string, RoleMetrics>).codeSm;
  const box = m.lineHeightPx as number;
  assert(box != null && m.fontFamily != null, `precondition: codeSm states a box and a family, got ${JSON.stringify(m)}`);
  assertEq(roleDeparture('codeSm', { family: 'mono' }), null, 'mono is the code role family');
  assertEq(roleDeparture('codeSm', { family: 'sans' }), 'family', 'sans departs a code role');
  assertEq(roleDeparture('codeSm', { lineHeightPx: box }), null, 'its own box');
  assertEq(roleDeparture('codeSm', { lineHeightPx: box + 3 }), 'lineHeight', 'another box');
  assertEq(roleDeparture('codeSm', { lineHeightPercent: 160 }), 'lineHeight', 'a multiplier over a box');
  assertEq(roleDeparture('bodyMedium', { lineHeightPx: 21 }), 'lineHeight', 'a box over a multiplier');
});

check('a code role arrives at makeLabel as mono, on its box, with no tracking', () => {
  const m = (TYPOGRAPHY as Record<string, RoleMetrics>).codeSm;
  resetPendingTextStyles();
  const o = textLabelOpts(lk2, style({ role: 'codeSm' }));
  assertEq(o.role, 'codeSm', 'role kept');
  assertEq(o.size, m.fontSize, 'the role size');
  assertEq(o.style, weightStyle(m.fontWeight), 'the role face');
  assertEq(o.family, 'mono', 'the mono family token');
  assertEq(o.lineHeightPx, m.lineHeightPx, 'the role box');
  assertEq(o.letterSpacingEm, 0, 'no tracking');
  o.rawColor = { r: 0, g: 0, b: 0 };
  const n = makeLabel('x', lk2, o) as unknown as FakeTextNode;
  assertEq(n.fontName?.family, 'Geist Mono', 'drawn in the exported mono');
  assertEq(n.lineHeight, { unit: 'PIXELS', value: m.lineHeightPx }, 'on the px box');
  assertEq(n.bound.fontSize, 'font-size/code-sm', 'binds the role size');
  assertEq(n.bound.letterSpacing, 'letter-spacing/code-sm', 'and the role tracking');
  assertEq(takePendingTextStyles().length, 1, 'queued for Code/SM');
});

// `CoreTextStyle`'s merge rule: a multiplier stated over a box replaces it —
// the newer statement is the one drawn — and the label then departs the role.
check('a multiplier stated over a code role drops the box, and the role', () => {
  const ts = textStyleData({ role: 'codeSm', lineHeight: 1.4 } as TextLeaf);
  assertEq(ts.lineHeight, 1.4, 'the stated multiplier');
  assertEq(ts.lineHeightPx, null, 'the box is gone');
  const o = textLabelOpts(lk2, ts);
  assertEq(o.lineHeightPx, undefined, 'no box reaches the opts');
  assertEq(o.lineHeightPercent, 140, 'the multiplier does');
  assert(o.role == null, `a code role on a multiplier is not the role, kept ${String(o.role)}`);
});

check('a role-only label is still queued — the gate is not a blanket', () => {
  resetPendingTextStyles();
  const n = label(lk2, style({ role: 'bodyMedium', fontSize: 14, fontWeight: 400, letterSpacing: -0.01 }));
  const queued = takePendingTextStyles();
  assertEq(queued.length, 1, 'queued');
  assert((queued[0].node as unknown) === n, 'the label itself');
  assertEq(n.bound.fontSize, 'font-size/body-medium', 'and it binds the role');
});

checkAsync('after the attach, an overlay keeps its face and a role-only label wears its style', async () => {
  fakeStyles.clear();
  fakeStyles.set('S:body-medium', {
    id: 'S:body-medium',
    name: 'Body/Medium',
    fontName: { family: 'Pretendard', style: 'Regular' },
    fontSize: 14,
    lineHeight: { unit: 'PERCENT', value: 150 },
    letterSpacing: { unit: 'PIXELS', value: -0.14 },
  });
  const styleIndex = new Map([['Body/Medium', fakeStyles.get('S:body-medium') as unknown as TextStyle]]);
  const faces = new Set([faceKeyOf({ family: 'Pretendard', style: 'Regular' })]);
  const attacher = createTextStyleAttacher(styleIndex, faces, () => {});
  resetPendingTextStyles();

  const plain = label(lk2, style({ role: 'bodyMedium', fontSize: 14, fontWeight: 400 }));
  const heavyData = label(lk2, style({ role: 'bodyMedium', fontSize: 14, fontWeight: 700 }));
  const restated = textLabelOpts(lk2, style({ role: 'bodyMedium', fontSize: 14, fontWeight: 400 }));
  restated.style = 'Bold';
  restated.rawColor = { r: 0, g: 0, b: 0 };
  const heavyOpts = makeLabel('x', lk2, restated) as unknown as FakeTextNode;
  const tall = label(lk2, style({ role: 'bodyMedium', fontSize: 14, lineHeight: 1.2 }));

  await attacher.attach(takePendingTextStyles());
  assertEq(plain.textStyleId, 'S:body-medium', 'role-only label wears the style');
  for (const [what, n] of [['weight from the style', heavyData], ['weight restated on the opts', heavyOpts]] as const) {
    assertEq(n.textStyleId, '', `${what}: no style`);
    assertEq(n.fontName?.style, 'Bold', `${what}: keeps its face`);
  }
  assertEq(tall.textStyleId, '', 'line height: no style');
  assertEq(tall.lineHeight, { unit: 'PERCENT', value: 120 }, 'line height: keeps its own');
  assertEq(attacher.stats.attached, 1, 'exactly one attach');

  // The fake can see the defect: the same Bold label handed to the attacher
  // anyway comes back in the role's face. Without this, the checks above could
  // pass against an attach that writes nothing.
  await attacher.attach([{ node: heavyOpts as unknown as TextNode, role: 'bodyMedium' }]);
  assertEq(heavyOpts.fontName?.style, 'Regular', 'an attached overlay is overwritten');
});

void Promise.all(asyncChecks).then(() => {
  if (failures > 0) {
    console.error(`\n${failures} check(s) failed`);
    process.exit(1);
  }
  console.log('✅ role-binding selftest passed');
});
