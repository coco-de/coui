/// <reference types="@figma/plugin-typings" />

import { bestVariantName, type SwapDefault } from './component-props';
import { instanceOf, mainComponentIdOf } from './identity';
import { parseVariantKey } from './variant-safety';

// ─── The stand-in a caller-supplied slot is drawn as ─────────────────────────
//
// A `W` / `W?` contract slot takes ANY widget. Its only Figma statement is an
// INSTANCE_SWAP property, and that property needs a component as its default —
// so every such slot is drawn as an instance of one stand-in component, and the
// swap defaults to the member it is drawn as (re-picking it in the panel is a
// no-op). The stand-in is `.Slot`, a builder fixture (`components/fixtures.ts`):
// a dashed outline that marks a place, not a picture of anything that could
// fill it. Why most slots start hidden, and how the instance is named:
// docs/contributing/figma.md, "빈 슬롯의 대역".
//
// Every builder reaches the stand-in through these two functions, and every
// REGISTRY entry that calls them declares `needs: [kSlotStandInComponent]` so
// the stand-in is built first — changing which component stands in is the one
// constant below.
//
// Absent stand-in set: both functions THROW (`instanceOf` / `mainComponentIdOf`
// name the missing `needs`). A builder that declares a swap default also draws
// the instance it defaults to, and drawing it throws without the set anyway —
// so a quiet `''` for the id only moved the same failure a few lines down.

/** The component a caller slot stands in as. */
export const kSlotStandInComponent = '.Slot';

/** The stand-in's `Shape` axis — a box (corner 0) and a circle (full corner). */
export const kSlotShapes = ['rectangle', 'circle'] as const;
export type SlotShape = (typeof kSlotShapes)[number];

/**
 * What usually fills a slot — a box, a run of copy, a round avatar. A builder
 * names the closest; the stand-in draws it as one of its two `Shape` members.
 */
export type SlotStandInShape = 'rectangular' | 'text' | 'circular';

interface StandIn {
  shape: SlotShape;
  /** The box the instance takes when its member's own box is not the slot's. */
  box: readonly [number, number] | null;
}

const kStandIns: Record<SlotStandInShape, StandIn> = {
  rectangular: { shape: 'rectangle', box: null },
  circular: { shape: 'circle', box: null },
  // A paragraph's box — three 16px lines 8px apart, 200 wide. Copy is drawn as
  // a box, but a copy slot that its builder leaves unsized holds this box, not
  // the member's: `OverflowMarquee` reads its height off the instance, and
  // `MediaQueryVisibility`'s alternate child sits at it.
  text: { shape: 'rectangle', box: [200, 64] },
};

/** The `Skeleton` set slots were drawn as before `.Slot` — read, never drawn.
 *  Exported so a scoped run loads its page too (`generate.ts`): with it
 *  unloaded no predecessor is found, and old swap defaults stay put quietly. */
export const kSlotStandInPredecessor = 'Skeleton';

// Matched on the `Shape` axis alone (`bestVariantName`), never on a full
// member name: a set can gain an axis, and an exact name stops naming any
// member the day it does.
function standInMember(page: PageNode, shape: SlotStandInShape): string | undefined {
  return bestVariantName(page, kSlotStandInComponent, { Shape: kStandIns[shape].shape });
}

/**
 * One slot's stand-in instance, already carrying `name`.
 *
 * `name` is required because the instance must never keep the stand-in
 * component's own name on the canvas: a layer called `.Slot` reads as the
 * component's content instead of as the slot it marks. Pass the slot name when
 * the instance IS the slot (`child`, `children[0]`), and `<slot> content` when
 * a holder frame named after the slot wraps it — whether or not that holder
 * carries a `Show <slot>` BOOLEAN.
 */
export function slotStandIn(
  page: PageNode,
  name: string,
  shape: SlotStandInShape,
): InstanceNode {
  const instance = instanceOf(page, kSlotStandInComponent, standInMember(page, shape));
  instance.name = name;
  const box = kStandIns[shape].box;
  if (box !== null) instance.resize(box[0], box[1]);
  return instance;
}

/**
 * The default a slot's INSTANCE_SWAP takes — the very member
 * `slotStandIn(page, …, shape)` draws — and the default it takes over from.
 *
 * `replaces` is the `Skeleton` member a slot of this kind defaulted to before
 * the stand-in was `.Slot`. `defineProp` moves an existing default only while
 * it still holds exactly that id, because nobody but the builder put it there;
 * a default holding anything else is a designer's pick and stays (#5277).
 *
 * Located by name rather than read off a drawn instance: `documentAccess:
 * "dynamic-page"` (manifest.json) makes `InstanceNode.mainComponent`
 * write-only, and its async replacement is unreachable from a synchronous
 * builder.
 */
export function slotStandInDefault(page: PageNode, shape: SlotStandInShape): SwapDefault {
  return {
    id: mainComponentIdOf(page, kSlotStandInComponent, standInMember(page, shape)),
    replaces: predecessorId(page, shape),
  };
}

// The `Skeleton` member a slot of this kind used to default to, or null on a
// document that never had one. Matched on `Variant` EXACTLY: `bestVariantName`
// falls back to the first member when nothing matches, and a wrong guess here
// would move a default a designer chose.
function predecessorId(page: PageNode, shape: SlotStandInShape): string | null {
  const member = bestVariantName(page, kSlotStandInPredecessor, { Variant: shape });
  if (member === undefined || parseVariantKey(member)['Variant'] !== shape) return null;
  try {
    return mainComponentIdOf(page, kSlotStandInPredecessor, member);
  } catch {
    return null;
  }
}
