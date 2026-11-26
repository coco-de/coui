/// <reference types="@figma/plugin-typings" />

import { IconSlot, iconSlot, slotBox, kHalf } from '../chrome-preview';

import { clipsFor, elevationLayers, OUTLINED_CONTAINER } from '../container-chrome';
import { linkShadowStyle } from '../shadow-style';

import {
  RegistryEntry,
  VarLookup,
  addControlShadow,
  applySurfaceMaterial,
  applyBorderStyle,
  applyPanelCompChrome,
  bestVariantName,
  bindPad,
  bindRadiusN,
  bindSwapProp,
  bindTextProp,
  bindVisibleProp,
  borderData,
  corners,
  defineProp,
  fillData,
  glyphOpts,
  instanceOf,
  kFocusOutlineBandName,
  kFocusOutlineRingName,
  makeIcon,
  makeLabel,
  mint,
  mountSet,
  panel,
  pinAbsolute,
  pinInFlow,
  propertyOwner,
  textLabelOpts,
  setShadow,
} from '../helpers';
import { Color, Dim, NormalizedColor, colorData, dimVal, textStyleData } from '../compat/v1';
import { COMPONENTS } from '../data';
import { enumerateAxisCombos } from '../axis-combos';
import { parseVariantKey } from '../variant-safety';
import { reserveTransparentBorder } from '../transparent-border-reservation';

// Surface chrome renderers; Popup, text and composition have separate modules.
const FOCUS_OUTLINE = COMPONENTS.focus_outline;
const WINDOW_PANEL = COMPONENTS.window_panel;

// ─── Preview-only extents ────────────────────────────────────────────────────
//
// No exported field describes how big a caller-supplied child is — `child` /
// `children` are composition slots, and their size comes from whatever the
// caller puts there. These are this preview's own layout choices, the same
// convention as `Card`'s `comp.resize(260, …)` and `Range`'s canvas
// (display.ts / form-controls.ts). Nothing chrome-bearing reads them.
const kSlotWidth = 160;
const kSlotHeight = 48;
const kPanelWidth = 320;
// The placeholder glyph's side — unlike the three above, not this preview's
// choice. No field describes how big a caller-supplied child is, but the glyph
// standing in for one is an `Icon`, and the three slots that draw it
// (OutlinedContainer `child`, FocusOutline `child`, WindowPanel `actions`)
// render the caller's widget as handed, with no size and no `IconTheme` around
// it on either platform. So an `Icon` passed there draws at the app root's
// ambient icon size, `CoreIconStyle.defaultAmbientSize`, read here from the
// `Icon` data. Deliberately NOT `controlIconStyle.size` (the nearest field) —
// that field sizes the window controls' own glyphs, and `actions` is not one
// of them.
const kSlotGlyph = COMPONENTS.icon.constants.ambientSize;
// The demo host's corner radius, for the one member whose ring follows its
// host: `FocusOutline.borderRadius` is `@hostDerived` (no kit default can hold
// it — a button's ring is 8, a card's 16), so the ring drawn around THIS
// preview's slot on the `Shape=rectangle` member takes the slot's own radius,
// and the slot stands in for a control-sized host. (`Shape=circle` needs none
// of this: `circleBorderRadius` is stated, so that member reads it.) Preview
// geometry like the extents above; the field is exported under `hostDerived`,
// not `absent`, so fidelity does not read this as a rounded corner where the
// code said square.
const kSlotRadius = 8;

// Not a design token either — an inset stated once lands on BOTH sides of an
// axis, so a box drawn `n` outside a child is `child + n * 2` wide. Geometry.
const kBothSides = 2;

// A colour with its alpha multiplied — `CoreColor.scaleAlpha(factor)`, which
// is how a resolver folds an opacity FIELD into a colour FIELD before paint.
//
// The token identity survives, and has to: `fillData`/`borderData` bind the
// Semantic Variable and pass this `opacity` to `solid()`, which keeps it in the
// paint's own `opacity` slot (`SolidPaint.color` is RGB and holds no alpha).
// So the colour still retints with the theme and the factor still shows —
// dropping the factor is what makes a stated opacity paint solid.
function scaleAlpha(cd: NormalizedColor | null, factor: number): NormalizedColor | null {
  if (cd == null) return null;
  return {
    color: cd.color,
    argb: cd.argb,
    opacity: (cd.opacity == null ? 1 : cd.opacity) * factor,
  };
}

// Rewrites the copy inside a composed child instance.
//
// Two paths, in the order Figma prefers them. `setProperties` is the supported
// way to drive a TEXT property, and the property id is the CHILD builder's to
// declare — so the key is read off the instance rather than spelled here,
// which keeps this working when that child renames or re-suffixes it. When the
// child exposes no TEXT property the first TEXT descendant's `characters` is
// written instead, the same override a designer's double-click produces; that
// write is rejected outright on a node the child DID bind to a property, hence
// the catch. Losing one line of demo copy is the right trade against a throw
// that abandons the component half-built on the canvas — the bound property's
// own default already reads as placeholder copy.
function setInstanceText(inst: InstanceNode, text: string): void {
  const props = inst.componentProperties;
  if (props && typeof inst.setProperties === 'function') {
    for (const key of Object.keys(props)) {
      if (props[key].type !== 'TEXT') continue;
      const patch: Record<string, string> = {};
      patch[key] = text;
      inst.setProperties(patch);
      return;
    }
  }
  for (const node of inst.findAll((n) => n.type === 'TEXT')) {
    if (node.type !== 'TEXT') continue;
    try {
      node.characters = text;
    } catch {
      // Bound to a component property — the designer sets it on the instance.
    }
    return;
  }
}

// The rounded, outlined, surface-filled box — in the widget's own two nodes:
//
// ```text
// root     (backgroundColor · borderColor/borderWidth · borderRadius
//           · boxShadow/elevation · clipBehavior)
//   └─ content  (padding · clipBehavior, rounded at radius − borderWidth)
//        └─ child          // W? slot
// ```
//
// Both come from `outlined_container.dart`: an outer `AnimatedContainer`
// carrying the decoration and the outer clip, and an inner one carrying
// `padding` and the child's clip. The inner node was missing here, and with it
// three stated values reached the canvas and were ignored — `padding`,
// `clipBehavior` and `elevation`. Two of the three had a comment claiming the
// field did not exist.
//
// `padding` is `CoreEdgeInsets.zero`, so the child does sit flush against the
// border — but not, as this used to say, because the style "has no padding
// field". It has one; Core's own note explains the zero ("The primitive draws
// a box, not a spacing scheme: every composing component states its own
// padding through this slot, so a non-zero baseline here would inset all of
// them at once"). Binding the zero rather than leaving it unwritten is the same
// argument `setShadow` makes below about `none`, and it is not academic here:
// `resetNode` zeroes the insets on a persistent node, so the two agree today
// and would diverge silently the moment the baseline moved.
//
// `clipBehavior` is the one with a symptom to see. Its default is
// `Clip.antiAlias` — the widget clips at both nodes, and the inner one exists
// precisely so a child flush with a corner cannot paint over the border there
// ("the outer container's clip follows the decoration's outer path, whose
// corner arcs bow into the content area"). On this canvas a freshly minted
// frame clips and `resetNode` sets `clipsContent = false`, so the first
// generation matched the widget and every regeneration afterwards did not.
// Written explicitly for the reason `CardImage` states the opposite one
// explicitly: fresh mint clips, `resetNode` does not.
//
// The inner radius is `radius − borderWidth`, the widget's
// `subtractByBorder(borderWidth, borderRadius)`, and it is set as a number
// rather than bound: 15 is not a step on the radius ladder, so `lk.radius(15)`
// would throw and abandon the component half-built. It is a derivation of two
// read fields, the same shape as `FocusOutline`'s `offsetExtent` below, not a
// value chosen here.
//
// `child` is a swappable slot, not a picture. It used to be an empty unpainted
// frame, argued for on the grounds that this container owns the box and
// nothing inside it — true about chrome, and beside the point about the slot:
// an untouchable empty box says the child is fixed at "nothing", which is a
// stronger claim than `W?` makes. A glyph a designer can swap for any
// component, and hide, is the honest image of the same field. It moves inside
// `content` here, where the widget puts it; the `Show child` BOOLEAN stays on
// the cell so the composing builders that switch it off through the property
// (`hideComposedSlot`) are unaffected, and the hug still collapses to the same
// extent in both states.
//
// Still not drawn, and the reason is a missing export rather than a missing
// Figma feature: `dashLength` (3) and `dashSpacing` (2) are the dash geometry
// of `borderStyle: dashed | dotted`, which Figma paints natively with
// `strokes` + `dashPattern` — and the widget's mapping is exact
// (`_DashedRectPainter`: dashed takes `dashLength`/`dashGap`, dotted swaps in
// `strokeWidth` for the segment and `dashLength` for the gap). What is missing
// is the state selector: `borderStyle` is in neither `fields` nor `absent`, so
// nothing in the data says which state the geometry belongs to, and the
// default is `solid` — painting the dashes on this component would show a
// state the widget is not in. Its honest carrier is a `Border` variant axis,
// and that needs machinery this file must not invent: `mint` reuses a
// persistent COMPONENT and `mountSet` looks for a COMPONENT_SET, so promoting
// one to the other would leave the old node on the page for `instanceOf` to
// keep returning to the three builders that compose this container. See the
// notes for both halves.
//
// `duration` (0) is the chrome transition — `Duration.zero` here, and a static
// frame has no time axis to put it on either way.
function buildOutlinedContainer(page: PageNode, lk: VarLookup): ComponentNode {
  const f = OUTLINED_CONTAINER.fields;
  const c = mint(page, 'OutlinedContainer');
  applyPanelCompChrome(c, 'VERTICAL', lk, { radius: f.borderRadius.topLeft });
  // The stack this container states — `elevation` unless an explicit
  // `boxShadow` overrides it. Read before the material because the rim hangs
  // on it.
  const cast = elevationLayers(f.elevation, f.boxShadow, 'outlined_container.elevation');
  // A content surface on both platforms, at the role a composer names —
  // `outlined_container_style.dart` reads `theme.surfaceFor(role)` and the Web
  // twin marks itself `webSurfaceMarkerFor(role)`, both `content` unless told
  // otherwise. The rim only where the container casts a shadow of its own:
  // both platforms key it on the stated stack (`resolveSurfaceRim(stack:)`,
  // and the rim written only beside an authored `box-shadow`), and this main
  // is flat. A composer that makes its instance cast turns the rim on there
  // (`setSurfaceRim`); one that recolours it routes the colour through the
  // same helper, which repoints the instance's material layer.
  applySurfaceMaterial(c, lk, colorData(f.backgroundColor), 'content', {
    radius: f.borderRadius.topLeft,
    rim: cast.layers.length > 0,
  });
  borderData(c, lk, colorData(f.borderColor), f.borderWidth);
  // After the stroke, because `none` clears it — the recipe says `solid`, so this
  // is a no-op today and the branch is what keeps it that way if the recipe
  // changes. Its dash lengths come from the same two fields `Frame` uses.
  applyBorderStyle(
    c,
    f.borderStyle.choice,
    dimVal(f.dashLength),
    dimVal(f.dashSpacing),
  );
  // A transparent stroke normally collapses in both renderers. When the
  // shared style opts in, keep an invisible inside stroke in auto-layout so
  // the child reserves the same width. The helper also resets regeneration.
  const contentBorderWidth = reserveTransparentBorder(
    c,
    colorData(f.borderColor),
    dimVal(f.borderWidth),
    f.preserveTransparentBorder.v,
    f.borderStyle.choice,
  );
  // `CoreShadow.none` — zero layers, and applied rather than skipped. This
  // container's default really is flat, and on a re-run over a persistent node
  // an unapplied "none" would leave whatever the previous run attached. The
  // stack now arrives through `elevation`, which is the source the resolver
  // reads when no explicit `boxShadow` overrides it. The tint is
  // `shadowBaseColor` — the palette's `shadow` slot unless a component pins
  // its own — which both platforms resolve into every layer.
  setShadow(c, cast, lk, colorData(f.shadowBaseColor));
  // At rest elevation the container casts nothing, and both platforms give it
  // the cast a style contributes instead (`theme.geometry.controlShadow` when
  // no stack is stated; `kControlShadowVar` for `.none`).
  if (cast.layers.length === 0) addControlShadow(c, lk);
  const clips = clipsFor(f.clipBehavior, 'outlined_container.clipBehavior');
  c.clipsContent = clips;

  // The widget's inner `AnimatedContainer` — `padding`, its own clip, and the
  // inner rounded path the clip follows.
  const content = panel('content', 'VERTICAL', lk, {});
  bindPad(content, lk, f.padding);
  content.clipsContent = clips;
  // Clamped at 0 because the widget's `_subtractSafe` is (`max(0, a.x - b.x)`)
  // and because Figma REJECTS a negative `cornerRadius` — a border wider than
  // the radius would otherwise throw here and leave the component half-drawn on
  // the page, which is the failure mode this project keeps re-learning.
  content.cornerRadius = Math.max(
    0,
    dimVal(f.borderRadius.topLeft) - contentBorderWidth,
  );

  const child = iconSlot(page, lk, {
    name: 'child',
    glyph: 'file',
    size: kSlotGlyph,
    color: null,
    width: kSlotWidth,
    height: kSlotHeight,
    owner: 'OutlinedContainer',
    prop: 'child',
  });
  content.appendChild(child.cell);
  c.appendChild(content);
  const owner = propertyOwner(c);
  bindSwapProp(child.instance, defineProp(owner, 'child', 'INSTANCE_SWAP', child.mainId));
  // The GLYPH carries the visibility, not the cell that holds it, and the
  // default is OFF.
  //
  // Two reasons, and they pull the same way. This is a wrapper: what it
  // draws is a box around whatever a caller puts inside, and the file
  // glyph is a stand-in for that caller's widget — not content this
  // component has. Shipped visible, it turned up as an unexplained
  // document icon inside every composed surface, which is what the
  // designer reported from the live file. And the cell has to stay: it is
  // a `layoutMode: 'NONE'` box at the placeholder size, and this root
  // hugs, so hiding the cell instead would collapse the wrapper to
  // nothing — the empty box IS the shape a wrapper has when its slot is
  // empty. A caller that wants the stand-in back turns the property on.
  bindVisibleProp(child.instance, defineProp(owner, 'Show child', 'BOOLEAN', false));
  return c;
}

// ─── FocusOutline ────────────────────────────────────────────────────────────

// A behaviour wrapper: it adds a focus ring around its child and draws
// nothing else. So the ring is all this node is — the two bands the widget
// stacks around the `child` slot, and nothing inside it.
//
// ─── The two bands, outward from the child edge ─────────────────────────────
//
// `focus_outline.dart` builds a `Stacks` of three layers: an `offsetColor`
// band `Position`ed at `-(align − borderWidth)` BEHIND the child (a border
// exactly the gap's width, so it never paints under the child), the child,
// then a bordered box `Position`ed at `-align` on top. Reading that outward
// from the child's own edge gives two bands and their widths:
//
//   child │ offsetColor, (align − borderWidth) wide │ borderColor, borderWidth wide
//         0                                        2                             4
//
// Those three layers are three nodes here, in the widget's own order and at
// the widget's own insets. This used to be ONE frame standing in for all three
// — `padding = align − borderWidth` filled with `offsetColor`, plus a
// `strokeAlign: 'OUTSIDE'` stroke — which draws the same picture at the one
// size this preview happens to be and stops being true the moment the child
// is another size, because a padded box measures from its own edge while the
// widget's `Position` insets measure from the child's.
//
// Both decorative layers are pinned ABSOLUTE with STRETCH constraints, and
// that IS the widget's four insets: Figma keeps a stretched child's distance
// to every edge, so a designer who resizes the instance still gets a band 2 px
// outside the child and a ring 4 px outside it (`focus-ring.ts` records the
// same reasoning for the ring it draws on other components' hosts).
//
// `ringOpacity` multiplies the ring colour's alpha and nothing else, which is
// the one thing the resolver does with it (`focus_outline_style.dart`:
// `(merged.borderColor ?? default).scaleAlpha(ringOpacity)`). It lands on the
// stroke paint's own `opacity`, which is where Figma keeps a paint's alpha —
// `SolidPaint.color` is RGB and carries none.
//
// The slot itself is swappable and hideable (see `iconSlot`): `child` is `W?`,
// so a designer puts whatever the ring is wrapping into it. The glyph inside
// is a placeholder, not this component's content — the ring owns no chrome
// within its child, and the INSTANCE_SWAP property is what says so out loud.
//
// ─── `Shape` is an axis, because it is two drawings ─────────────────────────
//
// `CoreFocusOutlineShape` is the only enum in `focus_outline.axes.other`, and
// its two members are not a nuance: `focus_outline.dart` switches on `shape`
// to pick which radius every ring layer follows — the host's own corner for
// `rectangle`, `circleBorderRadius` for `circle`. Read off the exported enum
// rather than spelled here, the way `Button` reads `CoreButtonShape`, so the
// canvas cannot hold a member the contract no longer backs.
//
// The radius each layer gets is the widget's own arithmetic. For a rectangle,
// `_adjustedBorderRadius` adds the layer's own inset to the child's corner so
// the outer curve stays concentric with the inner one — 8 + 4 = 12 for the
// ring, 8 + 2 = 10 for the band. The circle branch (`_standoffBorderRadius`)
// does the same sum, but 9999 + 4 is not a step on the radius ladder and
// renders identically to 9999 once the corner passes half the shorter side —
// so the circle layers bind the stated `circleBorderRadius` variable instead.
// That is also what keeps them following a theme axis that squares every
// radius, which a baked 10003 could not.
//
// Still not drawn: `duration` is the ring's fade-in timing, and nothing in a
// static frame reads it.

/** One member's three property-bearing nodes, kept for the binds after `finish()`. */
interface FocusOutlineMember {
  /** The `W?` slot — `child` (INSTANCE_SWAP) and `Show child` (BOOLEAN). */
  child: IconSlot;
  /** The `offsetColor` band, behind the child. */
  band: RectangleNode;
  /** The `borderColor` ring, over it. */
  ring: RectangleNode;
}

function buildFocusOutline(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = FOCUS_OUTLINE.fields;
  const shape = FOCUS_OUTLINE.axes.other.find((o) => o.enum === 'CoreFocusOutlineShape');
  if (!shape) {
    throw new Error(
      'FocusOutline: CoreFocusOutlineShape is gone from the exported axes — the ' +
        'canvas has a Shape axis that nothing in the contract now backs.',
    );
  }
  const combos = enumerateAxisCombos([{ axis: 'Shape', values: shape.members }]);
  const align = dimVal(f.align);
  // The offset band's width — the widget's own `offsetExtent`, the gap left
  // between the child and the ring.
  const offsetExtent = align - dimVal(f.borderWidth);
  const circleRadius = dimVal(f.circleBorderRadius.topLeft);
  // The loose COMPONENT this builder used to mint drew the rectangle — the
  // enum's first member, and `focus_outline.dart`'s own
  // `this.shape = CoreFocusOutlineShape.rectangle`. Adopting it under that
  // name is what lets its node id (and every instance pointing at it) survive
  // the promotion rather than being replaced by a fresh key. Inert on a
  // document that already carries the set, which is where this one lives.
  const mount = mountSet(page, 'FocusOutline', combos, { adoptLooseAs: combos[0] });
  const members: FocusOutlineMember[] = [];
  for (const comboName of combos) {
    const circle = parseVariantKey(comboName)['Shape'] === 'circle';
    const c = mount.getOrCreate(comboName);
    applyPanelCompChrome(c, 'VERTICAL', lk, {});
    // No padding, and nothing to write for it: the widget's
    // `Stacks(fit: .passthrough)` contributes no box of its own, so the member
    // IS its child's bounds and both bands hang outside them. A recycled
    // member comes out of `resetNode` at zero and a fresh one starts there.
    //
    // It must not clip, though, and that IS written: both layers overhang by
    // construction, a clipping frame cuts them off at exactly the edge they
    // exist to stand outside of, and a freshly created Figma frame clips —
    // only the recycled path has been through `resetNode`.
    c.clipsContent = false;
    // The demo host's corner, which every layer's radius is derived from.
    // `FocusOutline.borderRadius` is `@hostDerived`, so the rectangle member
    // borrows this preview's slot radius (see `kSlotRadius`); the circle
    // member takes the radius the contract states for that branch.
    const hostRadius = circle ? circleRadius : kSlotRadius;
    bindRadiusN(c, lk, hostRadius);
    const child = iconSlot(page, lk, {
      name: 'child',
      glyph: 'file',
      size: kSlotGlyph,
      color: null,
      width: kSlotWidth,
      height: kSlotHeight,
      owner: 'FocusOutline',
      prop: 'child',
    });
    c.appendChild(child.cell);

    // `offsetColor` keeps a node of its own. With the padding gone there is no
    // band left on the member frame for it to paint — a fill there would cover
    // exactly the child's box, which asserts a background this wrapper does
    // not have (`CoreFocusOutlineStyle` states no fill for the child's own
    // area). So it is drawn where the widget draws it: behind the child, inset
    // by `offsetExtent`, at the child's corner plus that inset. Dropping it
    // instead would leave a stated field with nothing on the canvas, and it is
    // half of what this component draws.
    //
    // The stated value is transparent — the gap shows whatever is behind the
    // control — so this node carries no fill on the main. It is still drawn:
    // a composer that places the wrapped control on a background it cannot
    // know (a carousel's dots over a slide) states an opaque band, and
    // `forwardFocusBand` repaints THIS node on its instance, which it could not
    // do to a node that is not there. The widget paints the band as a ring
    // outside the child rather than a box behind it; under an opaque child the
    // two are the same pixels, which is the only case a composer states one.
    const band = figma.createRectangle();
    band.name = kFocusOutlineBandName;
    fillData(band, lk, colorData(f.offsetColor));
    bindRadiusN(band, lk, circle ? circleRadius : hostRadius + offsetExtent);
    band.resize(
      kSlotWidth + offsetExtent * kBothSides,
      kSlotHeight + offsetExtent * kBothSides,
    );
    // `insertChild` first, then pin — `pinAbsolute` appends, so pinning and
    // then moving to index 0 reparents the same node twice. Index 0 is where
    // this has to sit, and `focus_outline.dart` records what happens when it
    // does not: painted on top "it covered the whole field, hiding its
    // content". Constraints last, after the parent has settled back to the
    // child's size, so the intermediate reflow has nothing to stretch.
    c.insertChild(0, band);
    pinInFlow(c, band);
    band.x = -offsetExtent;
    band.y = -offsetExtent;
    band.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };

    const ring = figma.createRectangle();
    ring.name = kFocusOutlineRingName;
    ring.fills = [];
    borderData(
      ring,
      lk,
      scaleAlpha(colorData(f.borderColor), dimVal(f.ringOpacity)),
      f.borderWidth,
    );
    // INSIDE, because this rectangle IS the ring's outer bound: the widget's
    // `Position(-align)` box carries `Border.all`, which Flutter paints inside
    // that box. An OUTSIDE stroke would push the outer edge to
    // `align + borderWidth` and swallow the band it is meant to sit beyond.
    ring.strokeAlign = 'INSIDE';
    bindRadiusN(ring, lk, circle ? circleRadius : hostRadius + align);
    ring.resize(kSlotWidth + align * kBothSides, kSlotHeight + align * kBothSides);
    // Appended last, so it paints over the child — the layer order the
    // widget's `Stacks` gives the two.
    pinAbsolute(c, ring, -align, -align, { horizontal: 'STRETCH', vertical: 'STRETCH' });
    members.push({ child: child, band: band, ring: ring });
  }
  const set = mount.finish();
  // Properties AFTER `finish()`, on the set — the only moment the owner
  // exists: `addComponentProperty` on a set member throws, and during the loop
  // a freshly created member has no parent yet, so `propertyOwner()` would
  // hand back the member itself and scatter one definition per variant. The
  // names are the designer's set's own, and `defineProp` adopts an existing
  // definition by name+type rather than minting a second key.
  const childProp = defineProp(set, 'child', 'INSTANCE_SWAP', members[0].child.mainId);
  // Off by default, and bound to the GLYPH rather than the cell that holds
  // it — same reasoning as `OutlinedContainer`: the stand-in is not this
  // component's content, and the cell is the fixed-size box this hugging
  // root takes its extent from, so hiding the cell would collapse the
  // wrapper instead of emptying it. Every consumer here is a wrapper use
  // (a dot, a thumb, a field, a chip row) that resizes this slot to its
  // own host and never puts a glyph in it.
  const showChildProp = defineProp(set, 'Show child', 'BOOLEAN', false);
  // Both layers on one property, because the widget fades them together off
  // the same `focused` flag. A ring that appears over a band that was already
  // there is not a state `focus_outline.dart` renders.
  // Off by default. Focus is a state something enters, not how a component
  // sits at rest — and a ring drawn at rest is worse than absent, because
  // it says "this is focused" about every instance on the page at once.
  // Both layers are absolutely pinned, so hiding them moves no geometry.
  const focusedProp = defineProp(set, 'Focused', 'BOOLEAN', false);
  for (const member of members) {
    bindSwapProp(member.child.instance, childProp);
    bindVisibleProp(member.child.instance, showChildProp);
    bindVisibleProp(member.band, focusedProp);
    bindVisibleProp(member.ring, focusedProp);
  }
  return set;
}

// ─── WindowPanel ─────────────────────────────────────────────────────────────

// Title bar + controls + content area, in the widget's own order:
//
// ```text
// root (surfaceColor · borderColor/containerBorderWidth · borderRadius)
//   ├─ title bar (titleBarColor · titleBarPadding · titleBarHeight)
//   │    ├─ title            // titleStyle, FILL — the widget's Expanded
//   │    ├─ actions          // W? slot, between title and controls — hidden by default
//   │    └─ controls         // controlSpacing between the three buttons
//   │         ├─ minimize    // controlButtonStyle — hidden (`minimizable` is false)
//   │         ├─ maximize    // controlButtonStyle — hidden (`maximizable` is false)
//   │         └─ close       // closeButtonStyle + controlIconStyle glyph
//   └─ content (contentPadding · contentStyle)
//        └─ child            // W? slot
// ```
//
// ─── The three slots ───────────────────────────────────────────────────────
//
//   · `title` gets a TEXT property and no BOOLEAN. Not an oversight: the
//     widget swaps a null title for a `Spacer`, so the space stays and the
//     controls stay right — "hidden" is not a state this slot has, and a
//     BOOLEAN on the FILL node would collapse it and drag the controls left.
//     Emptying the copy is the honest edit, and one node carries one property
//     reference anyway.
//   · `child` splits across the two nodes the widget already has there: the
//     BOOLEAN sits on the padded content region (the widget drops that whole
//     `Padding` when `child` is null or the panel is minimized) and the TEXT
//     on the copy inside it.
//   · `actions` is an Icon instance — a slot absent from the canvas is
//     indistinguishable from a slot the component does not have — swappable for
//     whatever affordance the caller passes (the contract's own example is
//     refresh / pin buttons). The widget draws it only when the caller passes
//     one, so `Show actions` starts off and the layer is drawn hidden.
//   · the minimize and maximize controls follow the same rule: the widget draws
//     them only for `minimizable` / `maximizable`, both false by default, so
//     the layers are there and hidden. They carry no BOOLEAN of their own —
//     an instance that wants one shows the layer.
//
// Two honest simplifications, both stated rather than hidden:
//
//   · the widget computes the title bar's inner top radius as
//     `outer − containerBorderWidth` (11 — not a step on any radius scale),
//     so the bar keeps square corners and the root clips them instead.
//   · only `close` carries its real glyph. In code each control is
//     `Button(child: Icon(...))`; a Figma instance cannot be given children,
//     so the glyph rides above the instance inside the control's own cell.
//     The other two cannot be drawn at all — the widget uses
//     `LucideIcons.minus` / `LucideIcons.square` and neither name is in the
//     vendored `data/icons.json` (32 glyphs). Adding them is a `gen-icons.ts`
//     change, which this file does not own.
//
// `shadow` + `shadowColor` are drawn together. The frame casts the `md` step of
// the shadow scale and the `shadow` token at full strength is its base, so the
// layer carries the alpha and the cast links the document's `shadow/md` style
// like every other step-casting surface. A style that tints it states a
// `shadowColor` with its own alpha, and `setShadow` keeps that alpha over the
// Variable binding (see that function's note).
//
// There is no divider under the title bar: its fill sets it apart from the
// content, on both platforms.
//
// Not drawn: `dashedBorderColor` / `hoverBackgroundColor` /
// `hoverForegroundColor` / `focusOutlineStyle` / `circleBorderRadius` /
// `iconLabelGapStyle` on the two button styles (per-state and per-shape
// values a resting button does not show — `dashedBorder` is `false`, so the
// 30% on `dashedBorderColor` has no border to tint), and every `*Duration`.
async function buildWindowPanel(page: PageNode, lk: VarLookup): Promise<ComponentNode> {
  const f = WINDOW_PANEL.fields;
  const c = mint(page, 'WindowPanel');
  applyPanelCompChrome(c, 'VERTICAL', lk, { radius: f.borderRadius.topLeft });
  // A floating surface on both platforms — Flutter composes
  // `OutlinedContainer(role: .functional)` for the frame, and the Web twin
  // marks it `webSurfaceMarkerFor(.functional)`. It takes the rim because it
  // casts: the frame's own shadow is there on both, and both draw the rim
  // alongside it (`resolveSurfaceRim` over the frame stack; the rim variable
  // in the frame's `box-shadow`). The title bar keeps its own opaque fill on
  // both, so it does not ride the material.
  applySurfaceMaterial(c, lk, colorData(f.surfaceColor), 'functional', {
    radius: f.borderRadius.topLeft,
    rim: f.shadow.layers.length > 0,
  });
  borderData(c, lk, colorData(f.borderColor), f.containerBorderWidth);
  setShadow(c, f.shadow, lk, colorData(f.shadowColor));
  await linkShadowStyle(c, f.shadow, 'WindowPanel');
  c.clipsContent = true;

  const bar = panel('title bar', 'HORIZONTAL', lk, {
    pl: f.titleBarPadding.l,
    pr: f.titleBarPadding.r,
    pt: f.titleBarPadding.t,
    pb: f.titleBarPadding.b,
  });
  bar.counterAxisAlignItems = 'CENTER';
  fillData(bar, lk, colorData(f.titleBarColor));
  c.appendChild(bar);
  // Height first, FILL after: `resize` switches an auto-layout child to FIXED
  // on both axes, so setting FILL before it would be undone.
  bar.layoutSizingVertical = 'FIXED';
  bar.resize(bar.width, dimVal(f.titleBarHeight));
  bar.setBoundVariable('height', lk.spaceLadder(dimVal(f.titleBarHeight)));
  bar.layoutSizingHorizontal = 'FILL';

  const title = makeLabel('편집기', lk, textLabelOpts(lk, textStyleData(f.titleStyle)));
  bar.appendChild(title);
  title.layoutSizingHorizontal = 'FILL';

  // Between the title and the controls, exactly where `?actions` sits in the
  // widget's `Row`.
  const actions = iconSlot(page, lk, {
    name: 'actions',
    glyph: 'ellipsis',
    size: kSlotGlyph,
    color: colorData(f.controlButtonStyle.foregroundColor),
    owner: 'WindowPanel',
    prop: 'actions',
  });
  // Hidden before the property is bound: the main component's own layer is
  // what an instance starts from, and the property's default (false) has to
  // describe what the layer already is.
  actions.cell.visible = false;
  bar.appendChild(actions.cell);

  const controls = panel('controls', 'HORIZONTAL', lk, { gap: f.controlSpacing });
  controls.counterAxisAlignItems = 'CENTER';
  bar.appendChild(controls);
  // Three, because `_buildControls` has three call sites — `minimizable` /
  // `maximizable` / `closable` gate them at run time, but the panel composes
  // all three and two of them share `controlButtonStyle` while `close` gets
  // `closeButtonStyle`. Drawing the set is what shows that split; the two
  // that default off are drawn hidden, and `closable` (true) shows.
  const minimizeCell = controlButton(page, lk, 'minimize', f.controlButtonStyle, null);
  const maximizeCell = controlButton(page, lk, 'maximize', f.controlButtonStyle, null);
  minimizeCell.visible = false;
  maximizeCell.visible = false;
  controls.appendChild(minimizeCell);
  controls.appendChild(maximizeCell);
  controls.appendChild(controlButton(page, lk, 'close', f.closeButtonStyle, 'x'));

  const content = panel('content', 'VERTICAL', lk, {
    pl: f.contentPadding.l,
    pr: f.contentPadding.r,
    pt: f.contentPadding.t,
    pb: f.contentPadding.b,
  });
  c.appendChild(content);
  content.layoutSizingHorizontal = 'FILL';
  const childCopy = makeLabel(
    '패널 내용',
    lk,
    textLabelOpts(lk, textStyleData(f.contentStyle)),
  );
  content.appendChild(childCopy);

  c.counterAxisSizingMode = 'FIXED';
  c.resize(kPanelWidth, c.height);
  // FIXED, not AUTO, and the content takes what the title bar leaves. A window
  // keeps the size it is given — that is what makes it a window — and left
  // hugging, a panel a designer dragged taller grew its frame and kept a 50px
  // content area with the rest empty (canvas measurement, 2026-09-07). FILL is
  // refused on an axis the parent hugs, which is why the mode is stated first.
  c.primaryAxisSizingMode = 'FIXED';
  content.layoutSizingVertical = 'FILL';

  // After every node is inside the component — a detached node rejects
  // `componentPropertyReferences` and the entry dies half-drawn on the page.
  const owner = propertyOwner(c);
  bindTextProp(title, defineProp(owner, 'title', 'TEXT', '편집기'));
  bindSwapProp(actions.instance, defineProp(owner, 'actions', 'INSTANCE_SWAP', actions.mainId));
  bindVisibleProp(actions.cell, defineProp(owner, 'Show actions', 'BOOLEAN', false));
  bindTextProp(childCopy, defineProp(owner, 'child', 'TEXT', '패널 내용'));
  bindVisibleProp(content, defineProp(owner, 'Show child', 'BOOLEAN', true));
  return c;
}

// The shared shape of `controlButtonStyle` / `closeButtonStyle` — the part of
// the nested `CoreButtonStyle` slot the panel overrides on the Button it
// composes. Declared structurally so both dispatch entries satisfy it.
//
// The per-state colours (`hoverBackgroundColor`, `hoverForegroundColor`, …)
// stay absent: they reach the control through Button's own resolve chain, and
// naming them here would invite this file to paint them a second time.
//
// `foregroundColor` is the exception, and only because Figma forces it. In
// code the glyph is the button's CHILD, so it inherits the button's per-state
// `IconTheme` foreground. An instance cannot be given children, so the glyph
// is a sibling stacked over the instance — nothing hands it that colour, and
// leaving it unpainted renders Lucide's `currentColor` black on every theme.
// Reading the same field the widget's `IconTheme` reads is the one source
// that cannot diverge from it; the two differ only in that a sibling cannot
// follow the button's hover state, which no static frame shows anyway.
interface ControlButtonStyle {
  borderRadius: { topLeft: Dim };
  width: Dim;
  height: Dim;
  foregroundColor: Color;
}

// One window control — an INSTANCE of the `Button` set, because that is what
// `_buildControlButton` composes: `Button(variant: .plain, size: .sm,
// buttonStyle: <controlButtonStyle | closeButtonStyle>)`. It used to be a
// rounded rect this file painted to look like one, and that copy would have
// kept the old look forever the day Button's `plain` chrome changed — the
// content-hash skip leaves a parent alone whose own recipe didn't change.
//
// The variant is asked for by the two axes the code names (`Variant` /
// `Size`), not by a full variant name: Button's name carries its whole axis
// list (`Selected` / `Hover` / `Disabled` today, more tomorrow) and spelling
// it out here would make this component fail to build the moment that list
// grows. The three state axes are pinned to their resting value so the
// scoring cannot drift onto a hovered or disabled member.
//
// Only what the panel's `buttonStyle:` argument actually overrides is applied
// on top — the control's own square extent and its radius. Everything else
// (fill, padding, hover) belongs to the Button set and is left to it;
// re-painting it here is the exact re-implementation composing was meant to
// remove. The label is cleared because in code this button's child is an
// `Icon`, not text.
//
// Returns the cell, not the instance: the glyph has to sit inside the button's
// box and cannot be appended to an instance, so the cell holds the two stacked
// at the same origin. The cell is the button's own square — `style.width` /
// `style.height` — so nothing here invents a dimension. `glyph` is null for
// the two controls whose Lucide names the vendored catalogue does not carry.
function controlButton(
  page: PageNode,
  lk: VarLookup,
  name: string,
  style: ControlButtonStyle,
  glyph: string | null,
): FrameNode {
  const b = instanceOf(
    page,
    'Button',
    bestVariantName(page, 'Button', {
      Variant: 'plain',
      Size: 'sm',
    }),
  );
  b.name = name;
  setInstanceText(b, '');
  const w = dimVal(style.width);
  const h = dimVal(style.height);
  b.resize(w, h);
  if (lk.sizeOrNull(w)) b.setBoundVariable('width', lk.size(w));
  if (lk.sizeOrNull(h)) b.setBoundVariable('height', lk.size(h));
  for (const c of corners) b.setBoundVariable(c, lk.radius(dimVal(style.borderRadius.topLeft)));
  const cell = slotBox(name, w, h);
  cell.appendChild(b);
  b.x = 0;
  b.y = 0;
  if (glyph != null) {
    const iconSize = WINDOW_PANEL.fields.controlIconStyle.size;
    const side = dimVal(iconSize);
    const fg = colorData(style.foregroundColor);
    const mark = makeIcon(glyph, lk, glyphOpts(lk, fg, iconSize, 'size'));
    cell.appendChild(mark);
    mark.x = (w - side) / kHalf;
    mark.y = (h - side) / kHalf;
  }
  return cell;
}

export const PRIMITIVES_SURFACES: RegistryEntry[] = [
  // `Icon`, on both of these, is the swappable default their `child` slot is
  // filled with — a placeholder a designer replaces, not chrome the container
  // draws.
  {
    section: 'Display',
    name: 'OutlinedContainer',
    build: buildOutlinedContainer,
    needs: ['Icon'],
  },
  { section: 'Display', name: 'FocusOutline', build: buildFocusOutline, needs: ['Icon'] },
  // `Icon` twice over: the close control's `x` (the widget's
  // `Button(child: Icon(...))`, stacked over the instance because Figma will
  // not nest into one) and the `actions` slot's swappable default.
  {
    section: 'Display',
    name: 'WindowPanel',
    build: buildWindowPanel,
    needs: ['Button', 'Icon'],
  },
];
