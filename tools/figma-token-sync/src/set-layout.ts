/// <reference types="@figma/plugin-typings" />

import { Dim, dimVal } from './compat/v1';
import { planAxisGrid } from './set-grid';
import { parseVariantKey } from './variant-safety';

// A set whose members are still being withheld (`identity.ts`, deferred
// reassembly) has one member in it, and laying that out would lay out nothing.
// `identity.ts` installs a gate that records the call as the set's layout
// intent and answers `true`; every entry point below asks it first. Installed
// rather than imported, because `identity.ts` imports this module for the
// default layout and the dependency stays one-way.
export type LayoutDeferralGate = (
  set: ComponentSetNode,
  name: string,
  apply: () => void,
) => boolean;
let layoutDeferral: LayoutDeferralGate | null = null;
export function installLayoutDeferral(gate: LayoutDeferralGate | null): void {
  layoutDeferral = gate;
}
function deferred(set: ComponentSetNode, name: string, apply: () => void): boolean {
  return layoutDeferral != null && layoutDeferral(set, name, apply);
}

// How a COMPONENT_SET arranges its members on the canvas.
//
// Purely about the container: the members are already drawn when these run. Split
// out of `helpers.ts` because `identity.ts` needs `defaultSetLayout` (a freshly
// mounted set gets laid out before it is returned) and `helpers.ts` still exports
// the rest — leaving it in place would have made the two import each other.
//
// Every layout that wraps (`defaultSetLayout`, `layoutSet`, `wrapSet`) tries the
// axis grid first (`set-grid.ts`) and only wraps when the set is not a grid — one
// axis, or names the grid cannot read. `rowSet` / `vStackSet` are a builder's
// explicit "one line" / "one column" and stay as they are: a set small enough to
// be a single row is already legible, and the builder said so on purpose.

/**
 * Lays the set out as the axis grid — bands × blocks × rows × columns read
 * straight off the variant names (see `set-grid.ts`). Returns false, touching
 * nothing, when the set has no grid to read; the caller then wraps.
 *
 * Absolute positions rather than auto-layout: a wrap has one column pitch for
 * the whole set, and the grid needs one per block (a 64px circle and a 150px
 * label button cannot share a column). `NONE` is also what `mountSet` parks
 * the set in while it reparents members, so nothing here is a state the set
 * has not already been in.
 */
export function axisGridSetLayout(
  set: ComponentSetNode,
  lead?: Readonly<Record<string, string>>,
): boolean {
  const kids = set.children;
  const plan = planAxisGrid(
    kids.map((k) => ({ name: k.name, width: k.width, height: k.height })),
    undefined,
    lead,
  );
  if (!plan) return false;
  set.layoutMode = 'NONE';
  for (const p of plan.placements) {
    const k = kids[p.index];
    k.x = p.x;
    k.y = p.y;
  }
  set.resizeWithoutConstraints(plan.width, plan.height);
  return true;
}

/**
 * [lead] names, per axis, the value whose member must sit in the set's
 * top-left corner — the member Figma hands a freshly placed instance
 * (`set-grid.ts`, "THE LEAD MEMBER"). A builder passes the defaults the code
 * states; omitted, the grid's own order stands.
 */
export function defaultSetLayout(
  set: ComponentSetNode,
  lead?: Readonly<Record<string, string>>,
): void {
  if (deferred(set, 'defaultSetLayout', () => defaultSetLayout(set, lead))) return;
  const kids = set.children;
  if (kids.length === 0) return;
  if (axisGridSetLayout(set, lead)) return;
  let maxW = 0;
  for (const k of kids) if (k.width > maxW) maxW = k.width;
  const cols = Math.max(1, Math.ceil(Math.sqrt(kids.length)));
  layoutSet(set, cols * (maxW + 16) + 48);
}

export function layoutSet(set: ComponentSetNode, width: number | Dim): void {
  if (deferred(set, 'layoutSet', () => layoutSet(set, width))) return;
  if (axisGridSetLayout(set)) return;
  set.layoutMode = 'HORIZONTAL';
  set.layoutWrap = 'WRAP';
  set.primaryAxisSizingMode = 'FIXED';
  set.counterAxisSizingMode = 'AUTO';
  set.itemSpacing = 16;
  set.counterAxisSpacing = 16;
  set.paddingLeft = 24;
  set.paddingRight = 24;
  set.paddingTop = 24;
  set.paddingBottom = 24;
  set.resize(dimVal(width), set.height);
}

export function vStackSet(set: ComponentSetNode): void {
  if (deferred(set, 'vStackSet', () => vStackSet(set))) return;
  set.layoutMode = 'VERTICAL';
  set.primaryAxisSizingMode = 'AUTO';
  set.counterAxisSizingMode = 'AUTO';
  set.itemSpacing = 16;
  set.paddingLeft = 24;
  set.paddingRight = 24;
  set.paddingTop = 24;
  set.paddingBottom = 24;
}

/**
 * One row, in member order. In an auto-layout row the FIRST member is the one
 * in the set's top-left corner — the member Figma hands a freshly placed
 * instance (`set-grid.ts`, "THE LEAD MEMBER") — so [lead] (axis → value, the
 * defaults the code states) moves the first member that carries all of them
 * to the front.
 *
 * Why the move and not only the builder's combo order: a set that already
 * exists keeps its recycled members where they sat (`mountSet` reparents only
 * the members it took out), so a builder that fixes its enumeration fixes a
 * first-ever build and leaves every existing set's corner where it was. The
 * move is a reorder inside the set — names, ids and keys are untouched.
 */
export function rowSet(
  set: ComponentSetNode,
  lead?: Readonly<Record<string, string>>,
): void {
  if (deferred(set, 'rowSet', () => rowSet(set, lead))) return;
  if (lead) moveLeadMemberFirst(set, lead);
  set.layoutMode = 'HORIZONTAL';
  set.primaryAxisSizingMode = 'AUTO';
  set.counterAxisSizingMode = 'AUTO';
  set.counterAxisAlignItems = 'CENTER';
  set.itemSpacing = 24;
  set.paddingLeft = 24;
  set.paddingRight = 24;
  set.paddingTop = 24;
  set.paddingBottom = 24;
}

export function wrapSet(set: ComponentSetNode, width: number | Dim): void {
  if (deferred(set, 'wrapSet', () => wrapSet(set, width))) return;
  if (axisGridSetLayout(set)) return;
  set.layoutMode = 'HORIZONTAL';
  set.layoutWrap = 'WRAP';
  set.primaryAxisSizingMode = 'FIXED';
  set.counterAxisSizingMode = 'AUTO';
  set.counterAxisAlignItems = 'CENTER';
  set.itemSpacing = 24;
  set.counterAxisSpacing = 24;
  set.paddingLeft = 24;
  set.paddingRight = 24;
  set.paddingTop = 24;
  set.paddingBottom = 24;
  set.resize(dimVal(width), set.height);
}

// The first member whose variant carries every [lead] value goes to index 0;
// the rest keep their order. A member name the parser refuses is skipped — it
// cannot be the lead — and no match leaves the set as it was.
function moveLeadMemberFirst(
  set: ComponentSetNode,
  lead: Readonly<Record<string, string>>,
): void {
  const entries = Object.entries(lead);
  const match = set.children.find((k) => {
    if (k.type !== 'COMPONENT') return false;
    let axes: Record<string, string>;
    try {
      axes = parseVariantKey(k.name);
    } catch {
      return false;
    }
    return entries.every(([axis, value]) => axes[axis] === value);
  });
  if (match && set.children[0] !== match) set.insertChild(0, match);
}
