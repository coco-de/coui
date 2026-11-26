/// <reference types="@figma/plugin-typings" />

// Self-test for `pinComposedCorner` (src/instance-reach.ts) — a host stating the
// corner of a control it composes.
//
// The control draws three layers from one corner — its box, the `state layer`
// wash over the fill, and the focus band and ring outside it. A host that holds
// the control at a smaller corner than the control's own size row (a `Menu`
// holding its `md` rows at 8 while the row ladder says 10) has to move all three,
// or the wash and the ring stay concentric with a box that is no longer there.
// The registry harness builds the sets but never reads a nested layer's corner
// back, so the three answers are pinned here:
//
//   1. The box and the wash take the host corner, BOUND to its radius variable.
//   2. The band and the ring take `host + align - borderWidth` / `host + align`,
//      written as numbers — a 14 host has an 18 ring, a step the radius ladder
//      does not have, and a bind there would throw.
//   3. Only the box's direct children move. A composed `Button` inside a field
//      row keeps its own wash and ring.
//
// No Figma runtime — plain objects carrying only what the helper reads.

import { VarLookup } from '../src/variables';
import {
  applyForwardedButtonStyle,
  forwardFocusBand,
  pinComposedCorner,
} from '../src/instance-reach';

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

function assert(cond: boolean, msg: string): void {
  if (!cond) throw new Error(msg);
}

// ─── doubles ────────────────────────────────────────────────────────────────

// The radius ladder the double knows. A step outside it throws, the way
// `VarLookup.radius` does on a document with no such variable.
const kLadder = new Set([4, 6, 8, 10, 12, 14, 16, 9999]);

const lk = {
  radius(n: number): Variable {
    if (!kLadder.has(n)) throw new Error(`no Primitives/radius/${n}`);
    return { id: `radius/${n}` } as unknown as Variable;
  },
} as unknown as VarLookup;

interface FakeLayer {
  type: 'RECTANGLE' | 'FRAME' | 'INSTANCE';
  name: string;
  cornerRadius: number;
  bound: { [field: string]: string };
  children: FakeLayer[];
  setBoundVariable(field: string, v: { id: string }): void;
}

function layer(
  type: FakeLayer['type'],
  name: string,
  corner: number,
  children: FakeLayer[] = [],
): FakeLayer {
  const node: FakeLayer = {
    type,
    name,
    cornerRadius: corner,
    bound: {},
    children,
    setBoundVariable(field: string, v: { id: string }): void {
      node.bound[field] = v.id;
    },
  };
  return node;
}

// A control drawn at its own size row's corner (`md`, 10 — ring 14, band 12),
// optionally holding a composed `Button` that draws the same three layers.
function control(withButton: boolean): {
  box: FakeLayer;
  wash: FakeLayer;
  band: FakeLayer;
  ring: FakeLayer;
  inner: { wash: FakeLayer; ring: FakeLayer } | null;
} {
  const wash = layer('RECTANGLE', 'state layer', 10);
  const band = layer('RECTANGLE', 'focus offset', 12);
  const ring = layer('FRAME', 'focus ring', 14);
  const kids = [wash, band, ring];
  let inner: { wash: FakeLayer; ring: FakeLayer } | null = null;
  if (withButton) {
    const innerWash = layer('RECTANGLE', 'state layer', 10);
    const innerRing = layer('FRAME', 'focus ring', 14);
    kids.push(layer('INSTANCE', 'feature button', 10, [innerWash, innerRing]));
    inner = { wash: innerWash, ring: innerRing };
  }
  const box = layer('INSTANCE', 'row', 10, kids);
  return { box, wash, band, ring, inner };
}

const kOutline = { align: 4, borderWidth: 2 };

function pin(box: FakeLayer, host: number): void {
  pinComposedCorner(box as unknown as InstanceNode, lk, host, kOutline);
}

// ─── cases ──────────────────────────────────────────────────────────────────

check('a panel-hosted row: box and wash bound at the host corner (8)', () => {
  const c = control(false);
  pin(c.box, 8);
  assert(c.box.bound.topLeftRadius === 'radius/8', `box ${c.box.bound.topLeftRadius}`);
  assert(c.box.bound.bottomRightRadius === 'radius/8', 'box: all four corners');
  assert(c.wash.bound.topLeftRadius === 'radius/8', `wash ${c.wash.bound.topLeftRadius}`);
});

check('the band and the ring follow at host + 2 / host + 4 (10 / 12)', () => {
  const c = control(false);
  pin(c.box, 8);
  assert(c.band.cornerRadius === 10, `band ${c.band.cornerRadius}`);
  assert(c.ring.cornerRadius === 12, `ring ${c.ring.cornerRadius}`);
});

check('a derived corner off the ladder is a number, not a bind (14 → ring 18)', () => {
  const c = control(false);
  pin(c.box, 14);
  assert(c.ring.cornerRadius === 18, `ring ${c.ring.cornerRadius}`);
  assert(c.band.cornerRadius === 16, `band ${c.band.cornerRadius}`);
  assert(Object.keys(c.ring.bound).length === 0, 'the ring carries no binding');
});

check('a pill host keeps the pill on all three layers', () => {
  const c = control(false);
  pin(c.box, 9999);
  assert(c.ring.cornerRadius === 9999, `ring ${c.ring.cornerRadius}`);
  assert(c.band.cornerRadius === 9999, `band ${c.band.cornerRadius}`);
});

check("a composed Button's own wash and ring are left alone", () => {
  const c = control(true);
  pin(c.box, 8);
  const inner = c.inner!;
  assert(Object.keys(inner.wash.bound).length === 0, 'inner wash re-bound');
  assert(inner.ring.cornerRadius === 14, `inner ring ${inner.ring.cornerRadius}`);
});

check('a forwarded Button corner moves the layers too (Toast close at 8)', () => {
  const c = control(false);
  applyForwardedButtonStyle(c.box as unknown as InstanceNode, lk, {
    borderRadius: { topLeft: 8 },
    focusOutlineStyle: kOutline,
  });
  assert(c.box.bound.topLeftRadius === 'radius/8', `box ${c.box.bound.topLeftRadius}`);
  assert(c.wash.bound.topLeftRadius === 'radius/8', `wash ${c.wash.bound.topLeftRadius}`);
  assert(c.ring.cornerRadius === 12, `ring ${c.ring.cornerRadius}`);
});

check('a slot that states no corner leaves the instance at its own', () => {
  const c = control(false);
  applyForwardedButtonStyle(c.box as unknown as InstanceNode, lk, {});
  assert(Object.keys(c.box.bound).length === 0, 'box was bound');
  assert(c.ring.cornerRadius === 14, `ring ${c.ring.cornerRadius}`);
});

// ─── the material layers keep their stroke inset ───────────────────────────
//
// A material surface's `material` / `glass` layers sit inside the box's own
// stroke, their corners pulled in by its reach (`insetLayerCorners`). A host
// that re-rounds the box re-rounds them too — and a bare bind to the host corner
// left a composed Select trigger's fill at 10 inside a 10 border: a crescent of
// background at the corner's diagonal. The radius a layer ends at is a number
// (the ladder has no variable for a corner pulled in by a 1.5 stroke).

interface FakeRect {
  type: 'RECTANGLE';
  name: string;
  topLeftRadius: number;
  topRightRadius: number;
  bottomLeftRadius: number;
  bottomRightRadius: number;
  bound: { [field: string]: string | undefined };
  setBoundVariable(field: string, v: { id: string } | null): void;
}

// A radius bound to `radius/<n>` reads back as n, the way Figma resolves it.
function rect(name: string, corner: number): FakeRect {
  const node: FakeRect = {
    type: 'RECTANGLE',
    name,
    topLeftRadius: corner,
    topRightRadius: corner,
    bottomLeftRadius: corner,
    bottomRightRadius: corner,
    bound: {},
    setBoundVariable(field: string, v: { id: string } | null): void {
      node.bound[field] = v == null ? undefined : v.id;
      if (v != null) (node as unknown as Record<string, number>)[field] = Number(v.id.split('/')[1]);
    },
  };
  return node;
}

function strokedBox(weight: number, kids: unknown[]): InstanceNode {
  return {
    type: 'INSTANCE',
    name: 'field',
    strokes: [{ type: 'SOLID', visible: true }],
    strokeAlign: 'INSIDE',
    strokeWeight: weight,
    strokeTopWeight: weight,
    strokeRightWeight: weight,
    strokeBottomWeight: weight,
    strokeLeftWeight: weight,
    children: kids,
    setBoundVariable(): void {},
  } as unknown as InstanceNode;
}

check('a re-rounded material layer stays pulled in by the stroke (10 in a 1 border → 9)', () => {
  const material = rect('material', 9);
  const glass = rect('glass', 9);
  const wash = rect('state layer', 10);
  pinComposedCorner(strokedBox(1, [material, glass, wash]), lk, 10, kOutline);
  for (const l of [material, glass]) {
    assert(l.topLeftRadius === 9 && l.bottomRightRadius === 9, `${l.name} ${l.topLeftRadius}`);
    assert(l.bound.topLeftRadius === undefined, `${l.name} still bound to the bare host corner`);
  }
  assert(wash.bound.topLeftRadius === 'radius/10', `wash ${String(wash.bound.topLeftRadius)}`);
});

check('the inset follows the stroke the box carries (8 in a 1.5 border → 6.5)', () => {
  const material = rect('material', 8);
  pinComposedCorner(strokedBox(1.5, [material]), lk, 8, kOutline);
  assert(material.topLeftRadius === 6.5, `material ${material.topLeftRadius}`);
});

check('a box with no stroke keeps the host corner bound on its layers', () => {
  const material = rect('material', 10);
  const box = { type: 'INSTANCE', name: 'row', strokes: [], children: [material], setBoundVariable(): void {} };
  pinComposedCorner(box as unknown as InstanceNode, lk, 8, kOutline);
  assert(material.bound.topLeftRadius === 'radius/8', `material ${String(material.bound.topLeftRadius)}`);
  assert(material.topLeftRadius === 8, `material ${material.topLeftRadius}`);
});

// ─── forwardFocusBand: the band strokes the gap ─────────────────────────────
//
// A stated band fills the space between the control's edge and the ring's inner
// edge — `align - borderWidth`, what Flutter strokes and Web spreads. The ring's
// own `borderWidth` is the wrong width the moment the two differ (a 1px ring at
// align 4 leaves a 3px gap), so the stroke is read off the gap. A gap the stroke
// ladder lacks is written as a literal rather than failing the entry.

const kStrokeLadder = new Set([0, 1, 2, 3, 4, 6, 8]);

const bandLk = {
  stroke(n: number): Variable {
    if (!kStrokeLadder.has(n)) throw new Error(`no Primitives/stroke/${n}`);
    return { id: `stroke/${n}` } as unknown as Variable;
  },
  strokeOrNull(n: number): Variable | undefined {
    return kStrokeLadder.has(n) ? ({ id: `stroke/${n}` } as unknown as Variable) : undefined;
  },
} as unknown as VarLookup;

interface FakeBand {
  type: 'RECTANGLE';
  name: string;
  strokes: unknown[];
  strokeWeight: number;
  bound: { [field: string]: string | undefined };
  parent: null;
  setBoundVariable(field: string, v: { id: string } | null): void;
}

function bandInstance(): { inst: InstanceNode; band: FakeBand } {
  const band: FakeBand = {
    type: 'RECTANGLE',
    name: 'focus offset',
    strokes: [],
    strokeWeight: 1,
    bound: {},
    parent: null,
    setBoundVariable(field: string, v: { id: string } | null): void {
      band.bound[field] = v == null ? undefined : v.id;
    },
  };
  const inst = {
    name: 'close',
    findAll(p: (n: FakeBand) => boolean): FakeBand[] {
      return [band].filter(p);
    },
  } as unknown as InstanceNode;
  return { inst, band };
}

// A raw, opaque band colour — the path that paints without a semantic lookup.
const kRawBand = { ref: null, argb: 0xffffffff, opacity: 1, fallbacks: [] };

check('a stated band strokes the gap, not the ring (align 4, ring 1 → 3)', () => {
  const { inst, band } = bandInstance();
  forwardFocusBand(inst, bandLk, { offsetColor: kRawBand, borderWidth: 1, align: 4 } as never);
  assert(band.strokes.length === 1, `band strokes ${band.strokes.length}`);
  assert(band.bound.strokeWeight === 'stroke/3', `band weight ${String(band.bound.strokeWeight)}`);
});

check('the default geometry still strokes 2 (align 4, ring 2)', () => {
  const { inst, band } = bandInstance();
  forwardFocusBand(inst, bandLk, { offsetColor: kRawBand, borderWidth: 2, align: 4 } as never);
  assert(band.bound.strokeWeight === 'stroke/2', `band weight ${String(band.bound.strokeWeight)}`);
});

check('a gap off the stroke ladder is a literal, not a failed bind (4 - 2.5)', () => {
  const { inst, band } = bandInstance();
  forwardFocusBand(inst, bandLk, { offsetColor: kRawBand, borderWidth: 2.5, align: 4 } as never);
  assert(band.bound.strokeWeight === undefined, `band still bound ${String(band.bound.strokeWeight)}`);
  assert(band.strokeWeight === 1.5, `band weight ${band.strokeWeight}`);
});

if (failures > 0) {
  console.error(`\n${failures} composed-corner self-test(s) failed.`);
  process.exit(1);
}
console.log('\nAll composed-corner self-tests passed.');
