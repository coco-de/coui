/// <reference types="@figma/plugin-typings" />

import { isSurfaceLayer } from './surface-layers';

// A read-only projection of additive layout insets, never a canvas rewrite.
// Keep the authored bindings and the raw reader/fingerprint intact. A nested
// frame can stand for one layout descriptor only with a matching geometric
// witness in the SAME counterpart variant; equal padding alone proves nothing
// about positions, extents or clipping.

export interface LayoutInsetProjection {
  tail: FrameNode;
  frames: readonly FrameNode[];
  padding: number[];
  gap: number;
}

// Only compensates floating-point addition in the eligibility equations. It
// never rounds a descriptor or a counterpart witness (those match exactly).
export const kInsetArithmeticEpsilon = 1e-6;

function finite(n: unknown): n is number {
  return typeof n === 'number' && Number.isFinite(n);
}

function rect(r: Rect | null): r is Rect {
  return r != null && [r.x, r.y, r.width, r.height].every(finite) && r.width >= 0 && r.height >= 0;
}

function empty(value: unknown): boolean {
  return record(value) && Object.keys(value).length === 0;
}

function record(value: unknown): value is Record<string, unknown> {
  return value != null && typeof value === 'object' && !Array.isArray(value);
}

function modes(n: FrameNode): string {
  if (!record(n.resolvedVariableModes)) throw new Error('unknown variable modes');
  const entries = Object.entries(n.resolvedVariableModes).sort(([a], [b]) => a.localeCompare(b));
  if (entries.some(([, mode]) => typeof mode !== 'string')) throw new Error('unknown variable mode');
  return JSON.stringify(entries);
}

function padding(n: FrameNode): number[] {
  return [n.paddingTop, n.paddingRight, n.paddingBottom, n.paddingLeft];
}

function spacingBindings(value: unknown): boolean {
  return record(value) && Object.entries(value).every(([key, binding]) =>
    ['paddingTop', 'paddingRight', 'paddingBottom', 'paddingLeft', 'itemSpacing'].includes(key) &&
    record(binding) && binding.type === 'VARIABLE_ALIAS' && typeof binding.id === 'string');
}

function plain(n: SceneNode): n is FrameNode {
  if (n.type !== 'FRAME') return false;
  // The ordinary reader folds a material child into its parent's painted box.
  // Such a frame is not paint-free even when its own fills array is empty.
  if (n.children.some(isSurfaceLayer)) return false;
  if (n.visible !== true || !['HORIZONTAL', 'VERTICAL'].includes(n.layoutMode) ||
      n.layoutWrap !== 'NO_WRAP' || n.primaryAxisSizingMode !== 'AUTO' ||
      n.counterAxisSizingMode !== 'AUTO' || n.layoutSizingHorizontal !== 'HUG' ||
      n.layoutSizingVertical !== 'HUG' || n.primaryAxisAlignItems !== 'MIN' ||
      n.counterAxisAlignItems !== 'MIN' || n.layoutPositioning !== 'AUTO' ||
      n.layoutGrow !== 0 || n.layoutAlign !== 'INHERIT' || n.opacity !== 1 ||
      n.blendMode !== 'PASS_THROUGH' || n.isMask !== false ||
      typeof n.clipsContent !== 'boolean' || n.rotation !== 0) return false;
  if (![n.fills, n.strokes, n.effects, n.layoutGrids].every((a) => Array.isArray(a) && a.length === 0) ||
      ![n.fillStyleId, n.strokeStyleId, n.effectStyleId, n.gridStyleId].every((s) => s === '') ||
      ![n.cornerRadius, n.topLeftRadius, n.topRightRadius, n.bottomLeftRadius,
        n.bottomRightRadius, n.cornerSmoothing].every((v) => v === 0) ||
      ![n.minWidth, n.maxWidth, n.minHeight, n.maxHeight].every((v) => v === null) ||
      !empty(n.componentPropertyReferences) || !empty(n.explicitVariableModes)) return false;
  // Only ordinary authored inset/gap bindings can participate. Visibility,
  // typography, size or mode bindings on these frames are not transparent.
  if (!spacingBindings(n.boundVariables)) return false;
  modes(n);
  if (![n.x, n.y, n.width, n.height, n.itemSpacing, ...padding(n)].every(finite) ||
      n.width < 0 || n.height < 0 || padding(n).some((p) => p < 0)) return false;
  const t = n.relativeTransform;
  const absolute = n.absoluteTransform;
  return Array.isArray(t) && t.length === 2 && t.every((row) => Array.isArray(row) && row.length === 3) &&
    t[0][0] === 1 && t[0][1] === 0 && t[1][0] === 0 && t[1][1] === 1 &&
    t[0][2] === n.x && t[1][2] === n.y && rect(n.absoluteBoundingBox) &&
    Array.isArray(absolute) && absolute.length === 2 && absolute.every((row) => Array.isArray(row) && row.length === 3) &&
    absolute[0][0] === 1 && absolute[0][1] === 0 && absolute[1][0] === 0 && absolute[1][1] === 1 &&
    finite(absolute[0][2]) && finite(absolute[1][2]) &&
    near(absolute[0][2], n.absoluteBoundingBox.x) && near(absolute[1][2], n.absoluteBoundingBox.y) &&
    near(n.absoluteBoundingBox.width, n.width) && near(n.absoluteBoundingBox.height, n.height);
}

function near(a: number, b: number): boolean {
  return Math.abs(a - b) <= kInsetArithmeticEpsilon;
}

function contains(a: Rect, b: Rect): boolean {
  // Clipping is not an arithmetic waiver: even tiny known overflow rejects.
  return b.x >= a.x && b.y >= a.y && b.x + b.width <= a.x + a.width &&
    b.y + b.height <= a.y + a.height;
}

function painted(n: SceneNode): boolean {
  if (n.type === 'TEXT' || n.type === 'VECTOR' || n.type === 'BOOLEAN_OPERATION' || n.type === 'LINE') return true;
  for (const value of ['fills' in n ? n.fills : [], 'strokes' in n ? n.strokes : [], 'effects' in n ? n.effects : []]) {
    if (!Array.isArray(value)) throw new Error('unknown paint');
    if (value.some((p: { visible?: boolean }) => p.visible !== false)) return true;
  }
  return false;
}

function renderBounds(n: SceneNode): Rect | null {
  if (!('absoluteRenderBounds' in n)) return null;
  return n.absoluteRenderBounds;
}

function visiblePaint(n: SceneNode, out: SceneNode[]): void {
  if (n.visible === false) return;
  if (n.visible !== true) throw new Error('unknown visibility');
  if (painted(n)) out.push(n);
  if ('children' in n) for (const c of n.children) visiblePaint(c, out);
}

function containedPaint(n: FrameNode): boolean {
  const bounds = n.absoluteBoundingBox;
  if (!rect(bounds)) return false;
  const nodes: SceneNode[] = [];
  visiblePaint(n, nodes);
  return nodes.every((c) => {
    const r = renderBounds(c);
    return rect(r) && contains(bounds, r);
  });
}

/** Missing/unsupported getters and unproved geometry always retain raw reading. */
export function projectLayoutInsets(node: SceneNode): LayoutInsetProjection | null {
  try {
    if (!plain(node)) return null;
    const frames = [node];
    let tail = node;
    let pad = padding(node);
    while (tail.children.length === 1 && tail.itemSpacing === 0) {
      const child = tail.children[0];
      if (!plain(child) || child.layoutMode !== tail.layoutMode || modes(child) !== modes(tail)) break;
      const p = padding(tail);
      if (!near(child.x, p[3]) || !near(child.y, p[0]) ||
          !near(tail.width, child.width + p[1] + p[3]) ||
          !near(tail.height, child.height + p[0] + p[2])) break;
      const outer = tail.absoluteBoundingBox!;
      const inner = child.absoluteBoundingBox!;
      if (!near(inner.x, outer.x + p[3]) || !near(inner.y, outer.y + p[0]) ||
          !near(outer.width, tail.width) || !near(outer.height, tail.height) ||
          !near(inner.width, child.width) || !near(inner.height, child.height)) break;
      if ((tail.clipsContent || child.clipsContent) &&
          (!contains(outer, inner) || !containedPaint(child))) break;
      pad = pad.map((v, i) => v + padding(child)[i]);
      if (!pad.every(finite)) return null;
      frames.push(child);
      tail = child;
    }
    return { tail, frames, padding: pad, gap: tail.itemSpacing };
  } catch {
    return null;
  }
}

export interface LayoutInsetWitness {
  geometry: string;
  usedModes: ReadonlyMap<string, string>;
}

// Compare used collections, not incidental inherited map entries. A literal
// inset can equal a resolved bound inset; neither binding is rewritten. If a
// consumer DOES reference a variable, its mode must be available and any shared
// used collection must agree across the counterpart. Missing data fails closed.
async function usedModes(root: SceneNode, cache: Map<string, Variable | null>): Promise<Map<string, string>> {
  const result = new Map<string, string>();
  const aliases = (value: unknown, out: Set<string>): void => {
    if (value == null) return;
    if (Array.isArray(value)) { for (const v of value) aliases(v, out); return; }
    if (!record(value)) return;
    if (value.type === 'VARIABLE_ALIAS') {
      if (typeof value.id !== 'string') throw new Error('unknown alias');
      out.add(value.id);
    } else for (const v of Object.values(value)) aliases(v, out);
  };
  const visit = async (n: SceneNode): Promise<void> => {
    if (n.visible === false) return;
    const ids = new Set<string>();
    aliases(n.boundVariables, ids);
    if ('fills' in n) aliases(n.fills, ids);
    if ('strokes' in n) aliases(n.strokes, ids);
    if ('effects' in n) aliases(n.effects, ids);
    if (n.type === 'TEXT') {
      if (n.textStyleId === figma.mixed) throw new Error('mixed text style');
      if (n.textStyleId !== '') {
        const style = await figma.getStyleByIdAsync(n.textStyleId);
        if (!style || style.type !== 'TEXT') throw new Error('unknown text style');
        aliases(style.boundVariables, ids);
      }
    }
    for (const id of ids) {
      if (!cache.has(id)) cache.set(id, await figma.variables.getVariableByIdAsync(id));
      const variable = cache.get(id);
      if (!variable) throw new Error('unknown variable');
      const collection = variable.variableCollectionId;
      const mode = n.resolvedVariableModes?.[collection];
      if (typeof mode !== 'string' || (result.has(collection) && result.get(collection) !== mode)) {
        throw new Error('unknown or scoped used mode');
      }
      result.set(collection, mode);
    }
    if ('children' in n) for (const c of n.children) await visit(c);
  };
  await visit(root);
  return result;
}

/** Exact layout positions/extents. Render bounds serve clipping, not equality. */
export async function layoutInsetWitness(
  node: SceneNode,
  root: SceneNode,
  cache = new Map<string, Variable | null>(),
): Promise<LayoutInsetWitness | null> {
  try {
    const p = projectLayoutInsets(node);
    if (!p) return null;
    if (p.frames.some((frame) => frame.clipsContent && !containedPaint(frame))) return null;
    const origin = root.absoluteBoundingBox;
    const box = node.absoluteBoundingBox;
    if (!rect(origin) || !rect(box)) return null;
    const relative = (r: Rect | null): number[] => {
      if (!rect(r)) throw new Error('unknown rendered geometry');
      return [r.x - origin.x, r.y - origin.y, r.width, r.height];
    };
    const leaves: SceneNode[] = [];
    visiblePaint(p.tail, leaves);
    const geometry = leaves.map((n) => JSON.stringify([n.type, relative(n.absoluteBoundingBox)])).sort();
    return {
      geometry: JSON.stringify([p.tail.layoutMode, p.padding, p.gap, relative(box), geometry]),
      usedModes: await usedModes(node, cache),
    };
  } catch {
    return null;
  }
}

/** Candidates are bounded to one already-paired variant, never other members. */
export async function layoutInsetWitnesses(root: SceneNode): Promise<readonly LayoutInsetWitness[]> {
  const witnesses: LayoutInsetWitness[] = [];
  const cache = new Map<string, Variable | null>();
  const visit = async (n: SceneNode): Promise<void> => {
    if (n.visible === false) return;
    const key = await layoutInsetWitness(n, root, cache);
    if (key != null) witnesses.push(key);
    if ('children' in n) for (const c of n.children) await visit(c);
  };
  try { await visit(root); } catch { return []; }
  return witnesses;
}

export function matchesLayoutInsetWitness(a: LayoutInsetWitness, b: LayoutInsetWitness): boolean {
  if (a.geometry !== b.geometry) return false;
  for (const [collection, mode] of a.usedModes) {
    if (b.usedModes.has(collection) && b.usedModes.get(collection) !== mode) return false;
  }
  return true;
}
