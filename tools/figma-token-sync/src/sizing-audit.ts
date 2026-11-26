// Root sizing audit (#4805) — does a variant root answer to auto-layout?
//
// A generated component is a fixed picture when a designer drops its instance
// into an auto-layout frame, picks *Fill container*, and the content inside
// does not follow the box — or picks *Hug contents* and the box does not
// shrink. Whether that is so cannot be read from builder source (the source
// may say STRETCH while the node says 162×50 — #4701); it is read from the
// drawn node: the root's own sizing mode on each axis, and whether any visible
// direct child follows that axis.
//
// This module is pure — no `figma` global, no registry — so the harness can
// run it over its double and a future in-plugin verifier can run it over the
// canvas. The shape it reads is the subset of `FrameNode` both expose.

import { isSurfaceLayer } from './surface-layers';

export type SizingAxis = 'width' | 'height';

/** What one axis of one variant root reads as. `unset` is a double-only
 *  state: the root is auto-layout but the builder never stated the mode, so
 *  the double holds `undefined` where Figma would hold its default. It is
 *  reported apart from the other three and COUNTS AS FIXED for the ratchet —
 *  a mode nobody stated is not evidence of hugging, and stating it (Story B)
 *  is the fix either way. */
export type AxisReading = 'hug' | 'fill-able' | 'fixed-box' | 'unset';

/** The ratchet's three-valued verdict — `unset` folded into `fixed-box`. */
export type AxisVerdict = 'hug' | 'fill-able' | 'fixed-box';

export const kSizingAxes: readonly SizingAxis[] = ['width', 'height'];

/** The properties the audit reads — present on Figma's `FrameNode` and on
 *  the harness double alike. Everything is `unknown` because the double
 *  leaves unwritten properties `undefined`. */
export interface SizingNodeLike {
  readonly type?: unknown;
  readonly name?: unknown;
  readonly visible?: unknown;
  readonly layoutMode?: unknown;
  readonly primaryAxisSizingMode?: unknown;
  readonly counterAxisSizingMode?: unknown;
  readonly layoutPositioning?: unknown;
  readonly layoutSizingHorizontal?: unknown;
  readonly layoutSizingVertical?: unknown;
  readonly constraints?: unknown;
  readonly children?: readonly SizingNodeLike[];
}

/** A REGISTRY entry's declaration that an axis is fixed BY DEFINITION —
 *  a divider's thickness, a progress track's height, a dot's diameter. A
 *  declared axis is not counted as a fixed box; its `why` is printed in the
 *  report in its place. A declaration with no reason is refused, and one that
 *  no variant actually reads as fixed is refused too (a declaration is a
 *  claim about the drawn node, and a stale claim hides the day it stopped
 *  being true). */
export interface SizingDeclaration {
  readonly width?: 'fixed';
  readonly height?: 'fixed';
  /** Scope the declaration to the variants whose name carries this one
   *  `Prop=Value` pair (e.g. `Style=dot` — a badge's dot is a fixed circle,
   *  its label variants are not). Absent, the declaration covers every
   *  variant. Variants outside the scope are audited as usual. */
  readonly when?: string;
  readonly why: string;
}

const kWhenPattern = /^[A-Za-z0-9_ .-]+=[A-Za-z0-9_ .-]+$/;

/** Does this variant root fall under the declaration's `when` scope? Variant
 *  names are `Prop=Value, Prop=Value, …`; the pair has to match a whole
 *  segment, so `Size=s` does not cover `Size=sm`. */
export function declarationCovers(decl: SizingDeclaration, root: SizingNodeLike): boolean {
  if (decl.when === undefined) return true;
  if (typeof root.name !== 'string') return false;
  const want = decl.when.trim();
  return root.name.split(',').some((segment) => segment.trim() === want);
}

export function isAutoLayout(node: SizingNodeLike): boolean {
  return typeof node.layoutMode === 'string' && node.layoutMode !== 'NONE';
}

/** The sizing MODE that governs `axis` on an auto-layout node. `layoutMode`
 *  says which of the two properties that is: HORIZONTAL's width is the primary
 *  axis and its height the counter axis; VERTICAL is the reverse. A node that
 *  is not auto-layout has no sizing mode — `undefined`. */
export function axisSizingMode(node: SizingNodeLike, axis: SizingAxis): unknown {
  if (!isAutoLayout(node)) return undefined;
  const primaryIsWidth = node.layoutMode === 'HORIZONTAL';
  return (axis === 'width') === primaryIsWidth ? node.primaryAxisSizingMode : node.counterAxisSizingMode;
}

/** Does this direct child follow its parent's box on `axis`?
 *
 *  - In-flow child of an auto-layout root: its `layoutSizing*` is `FILL`.
 *  - Child of a `NONE` root, or an ABSOLUTE-positioned child of an auto-layout
 *    root: its constraint on that side is `STRETCH` (pinned to both edges) or
 *    `SCALE` (resizes with the parent — Progress's indicator does this on
 *    purpose, #4701). `MIN`/`MAX`/`CENTER` keep the child's own size.
 *
 *  Hidden children do not count: a slot that is off in this variant cannot
 *  carry the box's content. `visible` is `undefined` on the double until a
 *  builder writes it, and Figma's default is `true`, so only an explicit
 *  `false` hides. */
export function childFollowsAxis(root: SizingNodeLike, child: SizingNodeLike, axis: SizingAxis): boolean {
  if (child.visible === false) return false;
  const absolute = child.layoutPositioning === 'ABSOLUTE';
  if (isAutoLayout(root) && !absolute) {
    const sizing = axis === 'width' ? child.layoutSizingHorizontal : child.layoutSizingVertical;
    return sizing === 'FILL';
  }
  const constraints = child.constraints as { horizontal?: unknown; vertical?: unknown } | null | undefined;
  const side = axis === 'width' ? constraints?.horizontal : constraints?.vertical;
  return side === 'STRETCH' || side === 'SCALE';
}

/** One axis of one variant root — see `AxisReading`. */
export function readRootAxis(root: SizingNodeLike, axis: SizingAxis): AxisReading {
  // A material surface's own fill layers stretch with the box whatever its
  // content does, so they are no evidence that the content follows.
  const children = (root.children ?? []).filter((child) => !isSurfaceLayer(child));
  const follows = children.some((child) => childFollowsAxis(root, child, axis));
  if (isAutoLayout(root)) {
    const mode = axisSizingMode(root, axis);
    if (mode === 'AUTO') return 'hug';
    if (mode === 'FIXED') return follows ? 'fill-able' : 'fixed-box';
    // Never stated. A FILL child is only legal under a fixed parent axis, so
    // its presence says what the author meant; otherwise the mode is unknown.
    return follows ? 'fill-able' : 'unset';
  }
  // A plain frame has no sizing mode of its own — its children's constraints
  // are the only thing that can make its content follow the box.
  return follows ? 'fill-able' : 'fixed-box';
}

export function verdictOf(reading: AxisReading): AxisVerdict {
  return reading === 'unset' ? 'fixed-box' : reading;
}

/** `null` when the declaration is acceptable, else the reason it is not. */
export function validateSizingDeclaration(name: string, decl: SizingDeclaration): string | null {
  if (typeof decl.why !== 'string' || decl.why.trim() === '') {
    return `${name}: sizing declaration has no \`why\` — a fixed axis is declared with its reason or not at all`;
  }
  if (decl.width === undefined && decl.height === undefined) {
    return `${name}: sizing declaration names no axis — declare \`width: 'fixed'\`, \`height: 'fixed'\`, or both`;
  }
  for (const axis of kSizingAxes) {
    const value = decl[axis];
    if (value !== undefined && value !== 'fixed') {
      return `${name}: sizing.${axis} is ${JSON.stringify(value)} — the only declarable value is 'fixed'`;
    }
  }
  if (decl.when !== undefined && !kWhenPattern.test(decl.when.trim())) {
    return `${name}: sizing.when is ${JSON.stringify(decl.when)} — expected one \`Prop=Value\` pair as it appears in the variant name`;
  }
  return null;
}

/** Per-axis counts of readings, plus the roots a declaration exempted. */
export type AxisTally = Record<AxisReading | 'declared', number>;

export interface RootSizingSummary {
  readonly name: string;
  readonly variants: number;
  readonly tally: Record<SizingAxis, AxisTally>;
  /** The first variant (by name) whose axis reads `fixed-box` or `unset`. */
  readonly firstFixed: Partial<Record<SizingAxis, string>>;
  /** Axes declared fixed, with the reason (and the `when` scope if any). */
  readonly declared: Partial<Record<SizingAxis, string>>;
  /** Axes that count as fixed boxes for the ratchet — some variant outside
   *  any declaration reads `fixed-box` or `unset` on that axis. */
  readonly fixedAxes: readonly SizingAxis[];
  /** Axes declared fixed although no variant in the declaration's scope
   *  reads fixed there — a stale claim, refused by the harness. */
  readonly staleDeclarations: readonly SizingAxis[];
}

function emptyTally(): AxisTally {
  return { hug: 0, 'fill-able': 0, 'fixed-box': 0, unset: 0, declared: 0 };
}

/** Classify every variant root of one component and fold the readings into
 *  per-axis tallies plus the ratchet's (component, axis) verdict. */
export function summarizeRootSizing(
  name: string,
  roots: readonly SizingNodeLike[],
  decl?: SizingDeclaration,
): RootSizingSummary {
  const tally: Record<SizingAxis, AxisTally> = { width: emptyTally(), height: emptyTally() };
  const firstFixed: Partial<Record<SizingAxis, string>> = {};
  // Per axis: did any root outside the declaration read fixed (→ ratchet),
  // and did any root inside it (→ the declaration is not stale)?
  const fixedOutside: Record<SizingAxis, boolean> = { width: false, height: false };
  const fixedInside: Record<SizingAxis, boolean> = { width: false, height: false };
  for (const root of roots) {
    const covered = decl !== undefined && declarationCovers(decl, root);
    for (const axis of kSizingAxes) {
      const reading = readRootAxis(root, axis);
      const fixed = verdictOf(reading) === 'fixed-box';
      if (covered && decl?.[axis] === 'fixed') {
        tally[axis].declared += 1;
        if (fixed) fixedInside[axis] = true;
        continue;
      }
      tally[axis][reading] += 1;
      if (fixed) {
        fixedOutside[axis] = true;
        if (firstFixed[axis] === undefined) firstFixed[axis] = typeof root.name === 'string' ? root.name : '(unnamed)';
      }
    }
  }
  const declared: Partial<Record<SizingAxis, string>> = {};
  const fixedAxes: SizingAxis[] = [];
  const staleDeclarations: SizingAxis[] = [];
  for (const axis of kSizingAxes) {
    if (decl?.[axis] === 'fixed') {
      declared[axis] = decl.when === undefined ? decl.why : `${decl.when.trim()}: ${decl.why}`;
      if (!fixedInside[axis]) staleDeclarations.push(axis);
    }
    if (fixedOutside[axis]) fixedAxes.push(axis);
  }
  return { name, variants: roots.length, tally, firstFixed, declared, fixedAxes, staleDeclarations };
}

/** The ratchet baseline's key for one (component, axis). */
export function sizingBaselineKey(name: string, axis: SizingAxis): string {
  return `${name}|${axis}`;
}

function formatAxis(label: string, s: RootSizingSummary, axis: SizingAxis): string {
  const t = s.tally[axis];
  const parts: string[] = [];
  if (t.hug > 0) parts.push(`hug ${t.hug}`);
  if (t['fill-able'] > 0) parts.push(`fill-able ${t['fill-able']}`);
  if (t['fixed-box'] > 0) parts.push(`fixed ${t['fixed-box']}`);
  if (t.unset > 0) parts.push(`unset ${t.unset}`);
  if (t.declared > 0) parts.push(`declared ${t.declared}`);
  let out = `${label} ${parts.join(' / ') || '—'}`;
  const why = s.declared[axis];
  if (why !== undefined) out += ` (declared: ${why})`;
  if (s.firstFixed[axis] !== undefined) out += ` (first fixed: ${s.firstFixed[axis]})`;
  return out;
}

/** One report line per component:
 *  `SIZING Card :: 24 variants · W fill-able 24 · H hug 24`. */
export function formatSizingLine(s: RootSizingSummary): string {
  return `SIZING ${s.name} :: ${s.variants} variant${s.variants === 1 ? '' : 's'} · ${formatAxis('W', s, 'width')} · ${formatAxis('H', s, 'height')}`;
}

export const kSizingReportLegend =
  'hug = root auto-layout, axis AUTO · fill-able = axis FIXED (or plain frame) but a visible direct child FILLs / STRETCHes / SCALEs on it · ' +
  'fixed = neither · unset = auto-layout root whose mode was never stated (double only; counts as fixed for the ratchet) · ' +
  'declared = exempted by the entry\'s `sizing` declaration (reason printed)';
