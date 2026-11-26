/// <reference types="@figma/plugin-typings" />

import { bindRadiusOrLiteral, drainOffScaleRadii, drainOffScaleSizes } from '../src/box';
import { bindRoundBoxRadius, boxGeometry, shrunkSquareGeometry } from '../src/shape-geometry';
import { corners, VarLookup } from '../src/variables';

declare function require(name: string): { readFileSync(path: string, encoding: string): string };
const fs = require('node:fs');

function equal(actual: unknown, expected: unknown): void {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(`Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}

function throws(fn: () => void): void {
  try { fn(); } catch { return; }
  throw new Error('Expected invalid geometry to throw');
}

// Use the production lookup with the actual Core ladders, including its
// size -> space fallback and semantic radius precedence. No added token steps.
const variables: Variable[] = [];
for (const [file, prefix] of [
  ['size/size', 'size'], ['spacing/spacing', 'space'], ['shape/radius_scale', 'radius'],
]) {
  const src = fs.readFileSync(`../../packages/coui_core/lib/src/${file}.dart`, 'utf8');
  const re = new RegExp(`static const (?:double )?${prefix}\\d+ = ([\\d.]+);`, 'g');
  const values = [...src.matchAll(re)].map(m => Number(m[1]));
  if (!values.length) throw new Error(`No Core ${prefix} ladder read`);
  for (const value of values) {
    for (const collection of prefix === 'radius' ? ['primitive', 'dimension'] : ['primitive']) {
      variables.push({
        id: `${collection}/${prefix}/${value}`, name: `${prefix}/${value}`,
        variableCollectionId: collection,
      } as Variable);
    }
  }
}
const lk = new VarLookup(variables, new Map([
  ['primitive', 'Primitives'], ['dimension', 'Semantic/Dimension'],
]));

function shape(width: number, height: number) {
  const bindings: Record<string, Variable> = {};
  const value = {
    width, height, cornerRadius: 0,
    setBoundVariable(field: string, variable: Variable | null) {
      if (variable) bindings[field] = variable;
      else delete bindings[field];
    },
  };
  return { node: value as unknown as FrameNode, value, bindings };
}

function warnings(radii: number[] = [], sizes: number[] = []): void {
  equal(drainOffScaleRadii(), radii);
  equal(drainOffScaleSizes(), sizes);
}

// Capsules and circles use half the short side, clearing any previous corner
// bindings on a miss and retaining the original variable on a supported result.
for (const [width, height] of [[18, 6], [6, 6], [8, 8], [6, 18]]) {
  const s = shape(width, height);
  for (const corner of corners) s.node.setBoundVariable(corner, lk.radius(8));
  const geometry = boxGeometry(lk, width, height);
  equal(geometry.source, { kind: 'box', width, height });
  bindRoundBoxRadius(s.node, lk, geometry);
  if (Math.min(width, height) === 6) {
    equal(s.value.cornerRadius, 3);
    equal(s.bindings, {});
  } else {
    for (const corner of corners) equal(s.bindings[corner], lk.radius(4));
  }
  warnings();
}

for (const side of [24, 32, 40]) {
  for (const shrink of [0, 2]) {
    const geometry = shrunkSquareGeometry(lk, side, shrink);
    equal(geometry.source, { kind: 'shrunk-square', side, shrink });
    equal(Object.isFrozen(geometry) && Object.isFrozen(geometry.source), true);
    equal([geometry.width, geometry.height], [side - shrink, side - shrink]);
    const s = shape(geometry.width, geometry.height);
    bindRoundBoxRadius(s.node, lk, geometry, 9999);
    if (shrink) {
      equal(s.value.cornerRadius, (side - shrink) / 2);
      equal(s.bindings, {});
    } else {
      for (const corner of corners) equal(s.bindings[corner], lk.radius(side / 2));
    }
    warnings();
  }
}

// The cap remains an authored input: a smaller supported override is respected;
// an unsupported one still warns, even if clipping hides its numeric value.
for (const [side, cap, expectedRadius, expectedWarning] of [
  [40, 8, 8, []], [24, 3, 3, [3]], [6, 11, 3, [11]],
] as const) {
  const s = shape(side, side);
  bindRoundBoxRadius(s.node, lk, boxGeometry(lk, side, side), cap);
  if (lk.radiusOrNull(expectedRadius)) {
    for (const corner of corners) equal(s.bindings[corner], lk.radius(expectedRadius));
  } else equal(s.value.cornerRadius, expectedRadius);
  warnings([...expectedWarning]);
}

// Ordinary unsupported authored radii still go through the unchanged reporter.
for (const radius of [3, 11, 15, 19]) {
  bindRadiusOrLiteral(shape(40, 40).node, lk, radius);
  warnings([radius]);
}
// Calling a dimension geometry cannot hide an unsupported authored size,
// including when the subtraction's output lands back on a supported step.
for (const size of [3, 22, 30, 38]) {
  const s = shape(size, size);
  bindRoundBoxRadius(s.node, lk, boxGeometry(lk, size, size));
  warnings([], [size]);
}
const authoredBase = shrunkSquareGeometry(lk, 22, 2);
equal(authoredBase.width, 20);
bindRoundBoxRadius(shape(20, 20).node, lk, authoredBase);
warnings([], [22]);
shrunkSquareGeometry(lk, 24, 3);
warnings([], [3]);

// A missing source variable is still a warning. Invalid arithmetic or a proof
// applied to different bounds cannot be relabeled as derived geometry.
boxGeometry(new VarLookup([], new Map()), 18, 6);
warnings([], [6, 18]);
for (const invalid of [NaN, Infinity, -1, 0]) {
  throws(() => boxGeometry(lk, invalid, 6));
  throws(() => shrunkSquareGeometry(lk, invalid, 2));
}
for (const invalid of [NaN, Infinity, -1, 24, 25]) {
  throws(() => shrunkSquareGeometry(lk, 24, invalid));
}
throws(() => bindRoundBoxRadius(shape(20, 6).node, lk, boxGeometry(lk, 18, 6)));
throws(() => bindRoundBoxRadius(shape(6, 6).node, lk, boxGeometry(lk, 6, 6), NaN));
warnings();
console.log('shape geometry: exact capsules, shrunk circles, radius caps, binding retention/clearing, unsupported authored inputs, missing variables and invalid proofs passed');
