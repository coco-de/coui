/// <reference types="@figma/plugin-typings" />

// Self-test for src/composed-instance.ts — the two things every icon-only
// `Button` composition does to its instance (#4885).
//
// The registry harness cannot see either failure: its nodes have no layout
// engine (a resize always "takes") and it models component properties on a
// main component, not on an instance. So both are pinned here against doubles
// that behave the way the canvas did:
//
//   1. A label whose `visible` is BOUND to `Show child`. Writing the node does
//      nothing while the property says `true` — the double ignores the write,
//      the way Figma's binding outranks it — so only a property write hides it.
//   2. An instance that inherits Button's size-row floor (`minHeight` 32) and
//      clamps a resize below it. A bare `resize(28, 28)` leaves 28×32, which is
//      the exact box CodeSnippet's copy drew.
//   3. An instance whose engine reverts the box no matter what — the read-back
//      has to say so in the drain instead of passing silently.
//
// No Figma runtime — plain objects carrying only what the helpers read.

import {
  drainUnpinnedInstanceBoxes,
  hideInstanceLabel,
  instanceTextNode,
  pinInstanceBox,
} from '../src/composed-instance';

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

interface FakeText {
  type: 'TEXT';
  name: string;
  visible: boolean;
}

// A Button-shaped instance: a label TEXT whose visibility is bound to a
// `Show child` BOOLEAN when `bound` is set.
function fakeButton(o: {
  bound: boolean;
  minHeight?: number | null;
  minWidth?: number | null;
  revert?: boolean;
}): {
  inst: InstanceNode;
  label: FakeText;
  showChild: () => boolean;
} {
  let show = true;
  let labelVisible = true;
  const label = {
    type: 'TEXT' as const,
    name: 'label',
    get visible(): boolean {
      return o.bound ? show : labelVisible;
    },
    set visible(v: boolean) {
      // A bound `visible` has one source of truth — the property.
      if (!o.bound) labelVisible = v;
    },
  };
  const props: { [k: string]: { type: string; value: boolean } } = {};
  if (o.bound) props['Show child#1:2'] = { type: 'BOOLEAN', value: true };
  let w = 64;
  let h = 32;
  const node = {
    type: 'INSTANCE',
    name: 'copy',
    layoutMode: 'HORIZONTAL',
    primaryAxisSizingMode: 'AUTO',
    counterAxisSizingMode: 'AUTO',
    minWidth: o.minWidth ?? null,
    maxWidth: null as number | null,
    minHeight: o.minHeight ?? null,
    maxHeight: null as number | null,
    children: [label],
    findAll(pred: (n: { type: string }) => boolean) {
      return this.children.filter(pred);
    },
    get componentProperties() {
      return props;
    },
    setProperties(patch: { [k: string]: boolean }) {
      for (const k of Object.keys(patch)) {
        props[k].value = patch[k];
        if (k.startsWith('Show child')) show = patch[k];
      }
    },
    get width(): number {
      return w;
    },
    get height(): number {
      return h;
    },
    resize(nw: number, nh: number) {
      if (o.revert) return;
      w = this.minWidth != null ? Math.max(nw, this.minWidth) : nw;
      h = this.minHeight != null ? Math.max(nh, this.minHeight) : nh;
    },
  };
  return {
    inst: node as unknown as InstanceNode,
    label,
    showChild: () => show,
  };
}

// ─── label ──────────────────────────────────────────────────────────────────

check('a bound label is hidden through `Show child`, not the node', () => {
  const { inst, label, showChild } = fakeButton({ bound: true });
  hideInstanceLabel(inst);
  assert(!showChild(), '`Show child` still true');
  assert(!label.visible, 'label still visible — the node write lost to its binding');
});

check('a child with no `Show child` falls back to the node', () => {
  const { inst, label } = fakeButton({ bound: false });
  hideInstanceLabel(inst);
  assert(!label.visible, 'label still visible');
});

check('instanceTextNode prefers a direct TEXT child', () => {
  const { inst, label } = fakeButton({ bound: false });
  assert(instanceTextNode(inst) === (label as unknown as TextNode), 'picked something else');
});

// ─── box ────────────────────────────────────────────────────────────────────

check("an inherited size-row floor does not keep Button's height (28×28, not 28×32)", () => {
  drainUnpinnedInstanceBoxes();
  const { inst } = fakeButton({ bound: true, minHeight: 32, minWidth: 32 });
  pinInstanceBox(inst, 28, 28);
  assert(inst.width === 28 && inst.height === 28, `holds ${inst.width}×${inst.height}`);
  assert(inst.primaryAxisSizingMode === 'FIXED', 'primary axis left to auto-layout');
  assert(inst.counterAxisSizingMode === 'FIXED', 'counter axis left to auto-layout');
  assert(drainUnpinnedInstanceBoxes().length === 0, 'a held box was reported as drifted');
});

check('a floor below the asked box is left alone', () => {
  const { inst } = fakeButton({ bound: true, minHeight: 20 });
  pinInstanceBox(inst, 28, 28);
  assert(inst.minHeight === 20, 'cleared a floor that clamped nothing');
});

check('a box the engine does not keep is reported, and the drain empties', () => {
  drainUnpinnedInstanceBoxes();
  const { inst } = fakeButton({ bound: true, revert: true });
  pinInstanceBox(inst, 28, 28);
  const lines = drainUnpinnedInstanceBoxes();
  assert(lines.length === 1, `expected one line, got ${lines.length}`);
  assert(lines[0].includes('28×28') && lines[0].includes('64×32'), lines[0]);
  assert(drainUnpinnedInstanceBoxes().length === 0, 'drain did not empty');
});

if (failures > 0) {
  console.error(`\n${failures} composed-instance self-test(s) failed.`);
  process.exit(1);
}
console.log('\nAll composed-instance self-tests passed.');
