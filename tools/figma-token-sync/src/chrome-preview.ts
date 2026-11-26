/// <reference types="@figma/plugin-typings" />

// Shared drawing operations: dependencies point here, never through a registry builder.
import { VarLookup, glyphOpts, iconMainId, iconSwapDefault, makeIcon } from './helpers';
import { Dim, NormalizedColor, dimVal } from './compat/v1';
// Not a design token — the divisor that centres a child in its parent's
// remaining space (`Stacks`' `alignment: .center`). Geometry, not chrome.
export const kHalf = 2;

// An unpainted, manually-positioned cell — a composition slot's own box.
//
// Deliberately without fill or border: the components that place one own the
// box *around* what goes in it and nothing inside, so painting the cell would
// imply chrome they do not have. `layoutMode = 'NONE'` because everything put
// here is placed by coordinate: a glyph centred in the slot, or a glyph
// stacked over the instance it belongs inside (Figma will not let a child be
// appended to an instance). The layer name is what carries the meaning.
export function slotBox(name: string, w: number, h: number): FrameNode {
  const f = figma.createFrame();
  f.name = name;
  f.layoutMode = 'NONE';
  f.fills = [];
  f.resize(w, h);
  return f;
}

// ─── Composition slots ───────────────────────────────────────────────────────
//
// A `W` / `W?` slot takes any widget, and the Figma equivalent of "any widget"
// is an INSTANCE_SWAP property: the designer picks a component from the panel
// and it takes that slot. Without one, whatever this file happened to draw IS
// the component — the only thing the slot can ever hold — and the canvas reads
// as finished while claiming something the contract never said.
//
// Two nodes per swappable slot, not one. A Figma node carries a single
// `componentPropertyReferences` entry, so the INSTANCE_SWAP and the BOOLEAN
// that expresses `W?`'s null cannot both sit on the instance — the second bind
// silently drops the first. The instance takes the swap; the unpainted cell
// around it takes the visibility. The cell is not invented structure: it stands
// in for the layout node the parent already puts its child into.
//
// Neither property is declared here. The NAME has to be spelled at the call
// site as a literal, because it must match the contract's own slot identifier
// exactly, and the BIND has to happen after the cell is inside the component —
// Figma rejects `componentPropertyReferences` on a detached node ("Can only set
// component property references on symbol sublayer"), the throw aborts the
// entry, and the half-built component is left on the canvas looking finished
// until the next run that mints its name blanks it.
export interface IconSlot {
  /// Stand-in for the parent's layout node — carries the BOOLEAN.
  cell: FrameNode;
  /// What the slot is filled with by default — carries the INSTANCE_SWAP.
  instance: InstanceNode;
  /// The swap property's default: the one the document already holds, or the
  /// `Icon` set's own default variant on a document that has none. The glyph
  /// is drawn from that variant, so the property's first bind leaves it at the
  /// slot's size (see `IconOpts.fromVariant`).
  mainId: string;
}

export function iconSlot(
  page: PageNode,
  lk: VarLookup,
  o: {
    name: string;
    glyph: string;
    size: number | Dim;
    color: NormalizedColor | null;
    /// Cell extent, when the slot stands for a whole content region rather
    /// than for the glyph alone. Defaults to the glyph's own square.
    width?: number;
    height?: number;
    /// The component that will own the slot's INSTANCE_SWAP, and that
    /// property's name, so the glyph is drawn from its default.
    owner: string;
    prop: string;
  },
): IconSlot {
  const side = dimVal(o.size);
  const swap = iconSwapDefault(page, o.owner, o.prop, iconMainId(page));
  const cell = slotBox(o.name, o.width ?? side, o.height ?? side);
  const instance = makeIcon(o.glyph, lk, {
    ...glyphOpts(lk, o.color, o.size, 'size'),
    fromVariant: swap.variant,
  });
  cell.appendChild(instance);
  instance.x = (cell.width - side) / kHalf;
  instance.y = (cell.height - side) / kHalf;
  return { cell: cell, instance: instance, mainId: swap.id };
}
