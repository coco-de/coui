/// <reference types="@figma/plugin-typings" />

import { Color, Dim, NormalizedColor, colorData, dimVal } from './compat/v1';
import { COMPONENTS } from './data';
import {
  derivedCorner,
  kFocusOutlineBandName,
  kFocusOutlineRingName,
  scaleAlpha,
  strokeFocusBand,
} from './instance-reach';
import { borderData, pinAbsolute } from './paint';
import { VarLookup } from './variables';
import { bindVisibleProp } from './component-props';

// Both sides of the box — an inset of `align` on the left and the right.
const kBothSides = 2;

// The `FocusOutline` ring, sized and placed the way `focus_outline.dart` draws
// it for a rectangular child.
//
// That widget builds the ring as a box inset by `-align` on all four sides with
// `Border.all(width: borderWidth)`, and rounds it by the child's own radius
// PLUS `align` (`_adjustedBorderRadius`) so the outer corner stays concentric
// with the inner one. All three inputs are stated: `align` and `borderWidth` in
// the component's own `focusOutlineStyle` slot — the one the resolver merges,
// not the child component's defaults — and the radius is the field's.
//
// `STRETCH` on both axes IS the four pinned insets: Figma keeps a stretched
// child's distance to both edges, so the ring stays `align` px outside the
// field at every width and height the instance is resized to. A fixed-size ring
// would come adrift the first time a designer widened the field.
//
// ─── Why the ring hangs off the field instead of sharing a wrapper with it ────
//
// The widget's `FocusOutline` is the field's PARENT, and the obvious translation
// is a wrapper frame holding the field in flow plus the ring beside it — which is
// what `buildRadioGroup` does for its indicator. Here that wrapper is wrong for a
// reason outside the geometry: THREE builders compose a `TextField` instance and
// find its chrome by sweeping the instance's direct children for the one PAINTED
// frame (`form-fields.ts#paintedChildRow`, `form-pickers.ts#paintedFieldRow`).
// A wrapper makes the painted row a grandchild, those sweeps find zero, and each
// throws — the runtime harness reported all three the moment the wrapper went in.
//
// Their own error text says the fix is to name the row instead of sweeping, and
// that fix lives in their files. So the ring goes INSIDE the field as an
// overhanging absolute child, which needs no wrapper and is geometrically the
// same statement: the widget's `Stacks(fit: .passthrough)` contributes no box of
// its own either, and the field is the box the insets are measured from either
// way. Appended last so it paints over the row's own children, which is where
// the widget's ring layer sits in its stack.
//
// The host must not clip — an overhanging child of a clipping frame is cut off at
// exactly the bounds the ring exists to stand outside of.
//
// ─── The band — the other half of what the widget draws ──────────────────────
//
// `FocusOutline` has a SECOND layer: the `offsetColor` band filling the
// `align - borderWidth` gap between the child's edge and the ring's inner edge.
// By default that colour is transparent — the gap shows whatever is behind the
// control, which on the page the control sits on is the page itself. Only a
// control whose background its parent cannot know (a FAB over scrolling
// content, a close button on an inverse-surface toast, a carousel button over a
// photo) states an opaque band, and it states it in its own slot
// (`CoreFocusRing.opaqueOffsetColor`, `surface`) so the ring is read against a
// colour the design system chose: a two-colour indicator, not a ring against a
// photo.
//
// Drawn as an INSIDE stroke, not a fill. `buildFocusOutline` fills its band
// because that component's child sits ON TOP of it and covers the middle;
// here the host is the component's own box, which paints its own fill, and a
// filled band pinned over it would cover the control. A `borderWidth`-wide
// INSIDE stroke on a rectangle inset by `-offsetExtent` paints exactly the
// gap and nothing else — the pixels the widget's stroke ring lands on.
//
// The node is drawn even when the band is transparent (`borderData` then writes
// `strokes = []`). Two things need it to exist. A composer that states an
// opaque band for an instance of this host repaints THIS node
// (`forwardFocusBand`) — Figma lets a parent override a nested node's paint but
// not add a child to an instance. And the runtime drills find a helper-drawn
// ring by the band sitting just before it.
//
// The band mirrors the ring in everything a designer can toggle: same
// `visible`, and `bindFocusRing` below binds both to the same BOOLEAN, so a
// `Show focus ring` that reveals the ring reveals the band with it.
//
// The band's colour is the caller's own `focusOutlineStyle.offsetColor` when
// its slot carries one — every per-component slot does, as the exporter spreads
// the child's own defaults under the parent's partial — and `FocusOutline`'s
// stated default otherwise, read from the contract that states it rather than
// spelled here.
//
// The ring's colour, for the field builders, is the VARIANT ROW's
// `focusRingColor`, not the slot's own `borderColor`: both resolvers overwrite
// the slot's colour with
// `merged.focusBorderColor ?? vs.focusRingColor` on every build, and
// `absent.focusBorderColor` says the override is null. So an error field's ring
// is the error colour, which is a difference this axis now shows.
//
// Shared by every builder that draws a `Clickable` / `FocusOutline` ring on its
// own root (`Button`, `TextField`, `Chip`, …) — one geometry for one widget, so
// a ring cannot be `align` px out on one set and flush on another.
export function focusRing(
  /**
   * The box the insets are measured from — a field's row, or a `Button`'s own
   * component frame (both are auto-layout parents an absolute child can pin to).
   */
  host: FrameNode | ComponentNode,
  lk: VarLookup,
  o: {
    /**
     * The field's own `focusOutlineStyle` slot — `align` + `borderWidth`, and
     * the band's `offsetColor` when the slot states one.
     */
    outline: { align: Dim; borderWidth: Dim; offsetColor?: Color };
    /** The variant row's `focusRingColor`. */
    color: NormalizedColor | null;
    /**
     * The field's own corner, which the ring's own corner is derived from.
     *
     * `null` when the host is square and no field says so. A rectangular host
     * states its radius; one drawn at 0 has nothing to state, because the
     * design system names corners it rounds, not corners it leaves alone
     * (`applyPanelCompChrome` takes the same `radius?` and skips the bind).
     * Writing a literal 0 at the call site instead would put a dimension
     * literal in `src/components/**`, which is the one thing G7 counts.
     */
    corner: Dim | null;
    width: number;
    height: number;
    visible: boolean;
  },
): FocusRingNodes {
  host.clipsContent = false;
  const align = dimVal(o.outline.align);
  const borderWidth = dimVal(o.outline.borderWidth);
  // The gap the band fills: `align` out to the ring's outer edge, less the
  // ring's own stroke, which is INSIDE that edge.
  const offsetExtent = align - borderWidth;

  // Band first, so it sits under the ring in the child order (`… → focus
  // offset → focus ring`), the layer order the widget's stack gives the two.
  const band = figma.createRectangle();
  band.name = kFocusOutlineBandName;
  band.fills = [];
  band.resize(o.width + offsetExtent * kBothSides, o.height + offsetExtent * kBothSides);
  // Derived like the ring's corner below: the child's radius plus the inset,
  // so the band's outer corner stays concentric with the child's.
  const hostCorner = o.corner == null ? 0 : dimVal(o.corner);
  band.cornerRadius = derivedCorner(hostCorner, offsetExtent);
  // Stroked the gap's width, not the ring's — see `strokeFocusBand`.
  strokeFocusBand(
    band,
    lk,
    colorData(o.outline.offsetColor ?? COMPONENTS.focus_outline.fields.offsetColor),
    offsetExtent,
  );
  band.strokeAlign = 'INSIDE';
  band.visible = o.visible;
  pinAbsolute(host, band, -offsetExtent, -offsetExtent, {
    horizontal: 'STRETCH',
    vertical: 'STRETCH',
  });

  const ring = figma.createFrame();
  ring.name = kFocusOutlineRingName;
  ring.fills = [];
  ring.clipsContent = false;
  ring.resize(o.width + align * kBothSides, o.height + align * kBothSides);
  // Derived, so nothing to bind — see `statedRadius` on why a by-value bind is
  // a provenance claim. The widget adds `align` to each corner for the same
  // reason: an outer ring at the child's radius reads pinched at the corners.
  ring.cornerRadius = derivedCorner(hostCorner, align);
  borderData(ring, lk, o.color, o.outline.borderWidth);
  // INSIDE: this frame IS the ring's outer bound (the widget's `Position(-align)`
  // box carries `Border.all`, painted inside it). OUTSIDE would push the outer
  // edge to `align + borderWidth` and swallow the band it sits beyond.
  ring.strokeAlign = 'INSIDE';
  ring.visible = o.visible;
  pinAbsolute(host, ring, -align, -align, {
    horizontal: 'STRETCH',
    vertical: 'STRETCH',
  });
  // Returned so a caller that ships the ring hidden can bind a BOOLEAN to it —
  // to BOTH nodes, via `bindFocusRing`.
  return { ring, band };
}

// The ring colour a `focusOutlineStyle` slot states: its `borderColor` with
// `ringOpacity` multiplied into the alpha.
//
// `focus_outline_style.dart` combines the two in one place
// (`borderColor.scaleAlpha(ringOpacity)`), and an alpha does not travel with a
// Variable binding, so the multiplication has to happen before the paint is
// written. Both are 1 today; a ring drawn from `borderColor` alone would stay
// solid on the canvas the day Core dims it, which is the drop this exists to
// make impossible for the callers that pass it as `focusRing`'s `color`.
export function focusOutlineRingColor(outline: {
  borderColor: Color;
  ringOpacity: Dim;
}): NormalizedColor | null {
  return scaleAlpha(colorData(outline.borderColor), dimVal(outline.ringOpacity));
}

/** The two nodes `focusRing` draws — always together, never one without the other. */
export interface FocusRingNodes {
  ring: FrameNode;
  band: RectangleNode;
}

// One BOOLEAN for the pair. The band must follow the ring exactly — same
// `visible`, same property — or `Show focus ring` on a control that states an
// opaque band (one its composer repaints, `forwardFocusBand`) produces a ring
// with no band under it, against whatever is behind the control.
export function bindFocusRing(nodes: FocusRingNodes, propId: string | null): void {
  bindVisibleProp(nodes.ring, propId);
  bindVisibleProp(nodes.band, propId);
}
