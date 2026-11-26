/// <reference types="@figma/plugin-typings" />

import { bindRadiusOrLiteral, noteOffScaleSize } from './box';
import { Dim, dimVal } from './compat/v1';
import { corners, VarLookup } from './variables';

// These operations derive geometry, not new token steps. Keep this module out
// of the helpers barrel: only builders that use the derivations depend on it.
const geometryProof = Symbol('box geometry');
type BoxGeometry = Readonly<{
  width: number;
  height: number;
  [geometryProof]: true;
  source: Readonly<
    | { kind: 'box'; width: number; height: number }
    | { kind: 'shrunk-square'; side: number; shrink: number }
  >;
}>;

function lengthOf(n: number | Dim, allowZero = false): number {
  const value = dimVal(n);
  if (!Number.isFinite(value) || (allowZero ? value < 0 : value <= 0)) {
    throw new RangeError(`Invalid geometry length: ${value}`);
  }
  return value;
}

function checkSourceLength(lk: VarLookup, value: number): void {
  // Same size/space lookup as bindSize. An unsupported authored input is
  // still reported even when the arithmetic happens to land on a token.
  if (!lk.sizeOrNull(value)) noteOffScaleSize(value);
}

/** Bounds stated by two supported lengths, including a capsule's short side. */
export function boxGeometry(lk: VarLookup, width: number | Dim, height: number | Dim): BoxGeometry {
  const w = lengthOf(width);
  const h = lengthOf(height);
  checkSourceLength(lk, w);
  checkSourceLength(lk, h);
  return Object.freeze({
    width: w, height: h, [geometryProof]: true as const,
    source: Object.freeze({ kind: 'box' as const, width: w, height: h }),
  });
}

/** A square's diameter minus a stated shrink, retaining both source lengths. */
export function shrunkSquareGeometry(lk: VarLookup, side: number | Dim, shrink: number | Dim): BoxGeometry {
  const base = lengthOf(side);
  const delta = lengthOf(shrink, true);
  const result = lengthOf(base - delta);
  checkSourceLength(lk, base);
  checkSourceLength(lk, delta);
  return Object.freeze({
    width: result, height: result, [geometryProof]: true as const,
    source: Object.freeze({ kind: 'shrunk-square' as const, side: base, shrink: delta }),
  });
}

/**
 * A fully round box has radius min(width, height)/2. A stated radius can cap
 * that result (ClipRRect semantics); it remains authored and must be checked.
 * Only the result of the geometry is exempt from the authored-token warning.
 *
 * Keep the existing binding when that result has a radius variable. Otherwise
 * unbind all corners and write the exact computed number, as the old callers
 * did. This is a static derivation, not a live Figma variable expression.
 */
export function bindRoundBoxRadius(
  node: FrameNode | ComponentNode | RectangleNode | InstanceNode,
  lk: VarLookup,
  geometry: BoxGeometry,
  statedRadius?: number | Dim,
): void {
  if (node.width !== geometry.width || node.height !== geometry.height) {
    throw new Error('Round radius bounds do not match the node');
  }
  let radius = Math.min(geometry.width, geometry.height) / 2;
  if (statedRadius !== undefined) {
    const limit = lengthOf(statedRadius, true);
    // Reuse the ordinary authored-value reporter on a miss, including when
    // clipping would hide the unsupported input behind a supported result.
    if (!lk.radiusOrNull(limit)) bindRadiusOrLiteral(node, lk, limit);
    radius = Math.min(limit, radius);
  }
  const variable = lk.radiusOrNull(radius);
  for (const corner of corners) node.setBoundVariable(corner, variable ?? null);
  if (!variable) node.cornerRadius = radius;
}
