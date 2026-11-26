/// <reference types="@figma/plugin-typings" />

// Shared drawing operations: dependencies point here, never through a registry builder.
import { VarLookup } from './helpers';
// A bound that may be "no bound" — the exporter spells `double.infinity` as
// `{ unbounded: true }`. Finite → the number; unbounded → null.
export function boundOrNull(v: unknown): number | null {
  if (typeof v === 'number') return v;
  if (v != null && typeof v === 'object' && 'v' in v) {
    const inner = (v as { v: unknown }).v;
    return typeof inner === 'number' ? inner : null;
  }
  return null;
}

// Binds a min/max extent to its `layout/N` variable when the value sits on
// that scale. A value off the scale is left literal — the same rule
// `bindSize` applies to `size/N`.
export function bindLayoutBound(
  node: FrameNode | ComponentNode,
  lk: VarLookup,
  field: 'minWidth' | 'maxWidth' | 'minHeight' | 'maxHeight',
  v: number | null,
): void {
  if (v == null || v <= 0) return;
  node[field] = v;
  try {
    node.setBoundVariable(field, lk.layout(v));
  } catch (_e) {
    // Off the `layout/N` scale — the literal stays, as `bindSize` leaves it.
  }
}
