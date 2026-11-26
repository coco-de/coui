/// <reference types="@figma/plugin-typings" />

import { Dim, dimVal, isDim } from './compat/v1';
import { VarLookup } from './variables';
import { corners } from './variables';

// Dimension binding: padding, radius, gap, width/height.
//
// The numbers a component states become Primitives-collection variable bindings
// rather than literals, so a token edit reaches the canvas without regenerating.
// Padding arrives either physical (left/right) or logical (start/end) — a horizontal
// inset that differs across the axis is a statement about reading direction, and
// flattening it here would be correct in English and wrong in Arabic.
//
// Split out of `helpers.ts` (see the barrel note there).
export interface PhysicalPadData {
  l: number | Dim;
  t: number | Dim;
  r: number | Dim;
  b: number | Dim;
}

export interface LogicalPadData {
  start: number | Dim;
  t: number | Dim;
  end: number | Dim;
  b: number | Dim;
}

export type PadData = PhysicalPadData | LogicalPadData;

export function bindRadiusN(
  // `InstanceNode` included: corner radius is one of the few things a Figma
  // instance carries as its own override, which is what lets a composing
  // component state a radius its child rests at a different value.
  node: FrameNode | ComponentNode | RectangleNode | InstanceNode,
  lk: VarLookup,
  n: number | Dim,
): void {
  const radius = dimVal(n);
  for (const c of corners) node.setBoundVariable(c, lk.radius(radius));
}

/** Radii drawn at a step the `radius` ladder has no variable for — written as
 *  literals, drained per entry (same reporting shape as [offScaleSpaces]). */
const offScaleRadii: number[] = [];

/** Reports the radii written unbound, and clears the list. */
export function drainOffScaleRadii(): number[] {
  const seen = [...new Set(offScaleRadii)].sort((a, b) => a - b);
  offScaleRadii.length = 0;
  return seen;
}

/**
 * Binds the four corners to `radius/<n>`, or writes the number when the ladder
 * has no such step.
 *
 * `bindRadiusN` goes through `lk.radius()`, which throws on a miss — right for
 * a corner the code states on the ladder, wrong for a number a designer drew
 * off it: the throw costs the whole entry for a corner that renders exactly
 * unbound. The literal is not silent — it lands in [offScaleRadii], so the
 * entry's log line names it, the way [bindSpaceField] names a spacing.
 *
 * The corners are unbound first: assigning a number to a field that is still
 * bound would leave the variable in charge.
 */
export function bindRadiusOrLiteral(
  node: FrameNode | ComponentNode | RectangleNode | InstanceNode,
  lk: VarLookup,
  n: number | Dim,
): void {
  const radius = dimVal(n);
  const variable = lk.radiusOrNull(radius);
  if (variable) {
    for (const c of corners) node.setBoundVariable(c, variable);
    return;
  }
  offScaleRadii.push(radius);
  for (const c of corners) node.setBoundVariable(c, null);
  node.cornerRadius = radius;
}

/** Spacing values drawn at a step the `space` ladder has no variable for —
 *  written as literals, drained per entry (same reporting shape as
 *  `inexactIconSizes`). */
const offScaleSpaces: number[] = [];

/** Reports the spacing values written unbound, and clears the list. */
export function drainOffScaleSpaces(): number[] {
  const seen = [...new Set(offScaleSpaces)].sort((a, b) => a - b);
  offScaleSpaces.length = 0;
  return seen;
}

/** Box sides drawn at a value the `size` ladder has no variable for — written
 *  as literals, drained per entry (same reporting shape as [offScaleSpaces]). */
const offScaleSizes: number[] = [];

/** Records a box side written as a plain number because no `size` step names
 *  it. A computed value (a pressed circle two smaller than its rest size)
 *  lands here — it renders exactly and binds to nothing, so a token edit will
 *  not reach it. */
export function noteOffScaleSize(n: number): void {
  offScaleSizes.push(n);
}

/** Reports the sizes written unbound, and clears the list. */
export function drainOffScaleSizes(): number[] {
  const seen = [...new Set(offScaleSizes)].sort((a, b) => a - b);
  offScaleSizes.length = 0;
  return seen;
}

/**
 * Binds one spacing field to its `space/<n>` variable, or writes the number
 * when the ladder has no such step.
 *
 * `lk.space()` throws on a miss, and every padding / gap in this file used to
 * call it directly — so a component stating an off-ladder inset killed its
 * whole entry. Toggle's thumb inset is 3, which the ladder skips (…2, 4, 6…),
 * and the run reported `variable not found: Primitives/space/3` for a value
 * that is perfectly renderable. `makeLabel` already resolved this same
 * question the same way ("bound when the step exists, literal when it does
 * not"): an unbound number renders, a throw leaves half a component behind.
 *
 * The literal is not silent — it lands in [offScaleSpaces] so the entry's log
 * line names it, the way an off-axis icon size is named.
 */
export function bindSpaceField(
  node: FrameNode | ComponentNode | InstanceNode,
  field:
    | 'paddingLeft' | 'paddingRight' | 'paddingTop' | 'paddingBottom'
    | 'itemSpacing' | 'counterAxisSpacing',
  lk: VarLookup,
  n: number,
): void {
  const variable = lk.spaceOrNull(n);
  if (variable) {
    node.setBoundVariable(field, variable);
    return;
  }
  offScaleSpaces.push(n);
  node[field] = n;
}

export function bindPad(
  // `InstanceNode` for the same reason `bindRadiusN` above takes one: an inset a
  // composing component states for the child it forwards to lands as that
  // instance's own override (Chip's close `Button` takes
  // `closeButtonStyle.padding` — zero — over Button's own size-row padding).
  // Widened rather than copied into the caller, because a second function that
  // resolves `start`/`end` itself is exactly the second conversion point the
  // note below exists to prevent.
  node: FrameNode | ComponentNode | InstanceNode,
  lk: VarLookup,
  o: PadData,
): void {
  const [l, r] = 'start' in o ? [o.start, o.end] : [o.l, o.r];
  bindSpaceField(node, 'paddingLeft', lk, dimVal(l));
  bindSpaceField(node, 'paddingRight', lk, dimVal(r));
  bindSpaceField(node, 'paddingTop', lk, dimVal(o.t));
  bindSpaceField(node, 'paddingBottom', lk, dimVal(o.b));
}

export function bindBox(
  node: FrameNode | ComponentNode,
  lk: VarLookup,
  o: {
    pl: number | Dim;
    pr: number | Dim;
    pt: number | Dim;
    pb: number | Dim;
    gap: number | Dim;
    radius: number | Dim;
  },
): void {
  bindPad(node, lk, { l: o.pl, r: o.pr, t: o.pt, b: o.pb });
  bindSpaceField(node, 'itemSpacing', lk, dimVal(o.gap));
  bindRadiusN(node, lk, o.radius);
}

export function bindAxisSize(
  node: FrameNode | ComponentNode | InstanceNode | RectangleNode | EllipseNode,
  lk: VarLookup,
  o: {
    width: number | Dim;
    height: number | Dim;
    /// Which axis carries a real design value. The other is left unbound.
    bind: 'width' | 'height';
  },
): void {
  const w = dimVal(o.width);
  const h = dimVal(o.height);
  node.resize(w, h);
  const value = o.bind === 'width' ? w : h;
  if (lk.sizeOrNull(value)) node.setBoundVariable(o.bind, lk.size(value));
}

/**
 * A `Dim.ref` that names a step of the stroke ladder — a whole step
 * (`stroke/1`) or a fractional one spelled with `_` (`stroke/0_5`,
 * `stroke/1_5`), the spelling Figma's variable names force.
 */
const kStrokeRef = /^Primitives\/stroke\/(\d+(?:_\d+)?)$/;

/**
 * The variable a line's thickness binds to.
 *
 * A thickness is a stroke width: `CoreStrokeWidth.stroke1` reaches the builders
 * as a `Dim` whose `ref` is `Primitives/stroke/1`, and that is the variable the
 * axis belongs on. Looking it up by VALUE through the size / space ladders — as
 * every other dimension is — finds nothing for 1px, because neither ladder has
 * that step; the axis would be a bare number a token edit never reaches.
 *
 * Which step: a ref naming a stroke step binds that step. A bare number, or a
 * `Dim` with no ref, is read as a stroke width, so it takes the stroke ladder
 * first. A ref into any other scale, and a step the stroke ladder lacks, take the
 * size / space lookup by value (`sizeOrNull`).
 */
function strokeVariableOf(lk: VarLookup, thickness: number | Dim): Variable | undefined {
  const value = dimVal(thickness);
  const ref = isDim(thickness) ? thickness.ref : null;
  if (ref == null) return lk.strokeOrNull(value) ?? lk.sizeOrNull(value);
  const named = kStrokeRef.exec(ref);
  if (named == null) return lk.sizeOrNull(value);
  return lk.strokeOrNull(Number(named[1].replace('_', '.'))) ?? lk.sizeOrNull(value);
}

/**
 * Binds one axis of a line to the variable its thickness names, and never
 * throws on a miss — an unbound number renders, a throw leaves half a component
 * behind (see [bindSpaceField]).
 *
 * Writes no size: the caller states the node's geometry first and binds right
 * after, and a caller that resizes the node again binds again (`hostedDivider`
 * rebinds after its forwarded thickness resize). The axis is the thickness one
 * (`height` of a horizontal rule, `width` of a vertical one); the length axis is
 * the caller's layout choice and not a stroke width.
 */
export function bindStrokeAxis(
  node: FrameNode | ComponentNode | InstanceNode | RectangleNode | EllipseNode,
  lk: VarLookup,
  axis: 'width' | 'height',
  thickness: number | Dim,
): void {
  const variable = strokeVariableOf(lk, thickness);
  if (variable) node.setBoundVariable(axis, variable);
}

export function bindSize(
  node: FrameNode | ComponentNode | RectangleNode | EllipseNode | InstanceNode,
  lk: VarLookup,
  w: number | Dim,
  h: number | Dim,
): void {
  const width = dimVal(w);
  const height = dimVal(h);
  node.resize(width, height);
  if (lk.sizeOrNull(width)) node.setBoundVariable('width', lk.size(width));
  if (lk.sizeOrNull(height)) node.setBoundVariable('height', lk.size(height));
}
