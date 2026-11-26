/// <reference types="@figma/plugin-typings" />

import { RegistryEntry, kSlotStandInComponent } from '../helpers';

import { slotNodes, SlotNodes, bindSlot, standInSlotNodes, bindOptionalSlot } from '../overlay-preview';
import { mainId } from '../overlay-composition';
import {
  VarLookup,
  applySurfaceMaterial,
  bestVariantName,
  bindSwapProp,
  bindVisibleProp,
  defineProp,
  fillData,
  glyphOpts,
  iconMainId,
  iconSwapDefault,
  indicatorBox,
  instanceOf,
  layoutSet,
  lockWidth,
  makeIcon,
  makeLabel,
  mintPanelComp,
  mountSet,
  panel,
  propertyOwner,
  rowSet,
  textLabelOpts,
  setShadow,
  applyForwardedPanelStyle,
  exposeSlot,
  slotStandInDefault,
  setInstanceBoolNamed,
  setInstanceSwapNamed,
  setInstanceTextNamed,
} from '../helpers';
import {
  exampleInstance,
  exampleMainId,
  exampleSwapDefault,
  kDraggablePanelExample,
  kHoverCardExample,
} from '../default-examples';
import { Dim, colorData, optField, textStyleData } from '../compat/v1';
import { kPopupContentSlotName, popupInstance, popupPaddingOverride } from '../popup-composition';
import { COMPONENTS } from '../data';
import { axisSpecsOf, composeVariantName, enumerateAxisCombos, restingValueOf } from '../axis-combos';
import { parseVariantKey } from '../variant-safety';
const HOVER_CARD = COMPONENTS.hover_card;
const DRAGGABLE_PANEL = COMPONENTS.draggable_panel;
const SWIPER = COMPONENTS.swiper;

// Writes a BOOLEAN component property on a composed child instance.
//
// By property NAME, resolved through the instance's own
// `componentProperties`, because the id Figma hands back from
// `addComponentProperty` carries a `#<id>` suffix the parent never sees. The
// same read-then-write `setInstanceLabel` does for TEXT, and for the same
// reason: the property belongs to the child builder, so this asks what is
// there instead of assuming a spelling.
//
// A no-op when the child declares no such property — including in the runtime
// harness, whose instance double models component properties on a main
// component but not on an instance. So the Figma-only half of this is not
// exercised by `npm run selftest`; what the harness does verify is that the
// call itself is reachable and throws nothing.
function setInstanceBool(inst: InstanceNode, name: string, value: boolean): void {
  const props: ComponentProperties | undefined = inst.componentProperties;
  if (!props || typeof inst.setProperties !== 'function') return;
  for (const key of Object.keys(props)) {
    if (key.split('#')[0] !== name || props[key].type !== 'BOOLEAN') continue;
    const patch: { [name: string]: boolean } = {};
    patch[key] = value;
    inst.setProperties(patch);
    return;
  }
}

// ─── HoverCard ───────────────────────────────────────────────────────────────

/** The label the HoverCard example's trigger carries (designer's copy, #6473). */
const kHoverCardExampleTrigger = '@cocode';

// `hover_card_style.dart` draws its own tree in the header comment, and the
// panel line is not a description — it is the composition:
//
// ```text
// MouseRegion
//   └─ Popup (panelStyle)                // single panel-box source
//        └─ content                      // caller-supplied Widget
// ```
//
// So the card is a `Popup` INSTANCE — exactly the panel `Popover` composes
// (`popover.dart#_buildPanel`), not "a box that resembles it" and not a `Card`.
// That is also why `HOVER_CARD.fields` has no backgroundColor / borderColor /
// borderRadius: the face (corner 12, `surface-bright`, 1px `outline-variant`
// edge, the `lg` cast) is `Popup`'s, and `CoreHoverCardStyle` reaches it through
// the one nested `panelStyle` slot. A hand-drawn box, or a `Card` repainted to
// look like one, is precisely the thing that would stop following `Popup`.
//
// `panelStyle` is the fully-resolved `CorePopupStyle` the export writes (the
// hover card's `defaultPanelStyle` over `Popup`'s defaults); the only field a
// Figma INSTANCE can state of it is the inset, because the `Popup` set carries
// that as its `Padding` axis (16 → `Padding=content`). `maxWidth` (256) is the
// width the card is drawn at — the content-sized card under its ceiling, filled
// to that ceiling the way the example copy is.
//
// ── The two slots ────────────────────────────────────────────────────────────
//
// `trigger` is a required `W` rendered INLINE — the card is the overlay — so it
// is a real node here. It defaults to a `Link`, which is what the widget's own
// example passes (`Text('@coui').bodyMedium.primary.underline` is a link in
// everything but name), and `placementOffset` is the trigger↔panel distance it
// is the gap for.
//
// `content` is `Popup(children: [widget.content])` — it lives INSIDE the
// composed instance, and Figma will not reparent a node into an instance. So it
// is reached the way the code reaches it: through the child. `Popup` draws
// `children` as its `Content` INSTANCE_SWAP slot, and the hover card exposes the
// instance so that property surfaces on every HoverCard — the designer's swap
// is the caller's `content`. The example copy's panel is a `Popup` with its
// content slot, 74 high, and so is this one.
//
// ── The slot fills the card, and the card's shadow is not cut ────────────────
//
// Two things the designer's copy states of the card that the `Popup` member
// alone does not draw, both read off the copy (`HoverCard(리디자인)`) rather
// than guessed:
//
//   · the slot is the card's inner width — 222 inside the 256 card (256, less
//     the 16 inset and the 1 border on each side) — where the member's own
//     slot is the `.Slot` stand-in's 160 box. The copy writes that on the
//     instance: its `content` is `FILL` across the card here and `FIXED` 160 in
//     the Popover copy, which composes the very same member — so this card is
//     overridden and the Popover is not.
//   · the `panel` frame does not clip. It is exactly the card's box (256 × 74),
//     and a frame clips its children's drop shadows at its edge — the `lg` cast
//     the `Popup` carries (16 down, 40 blur) is drawn outside that box, so a
//     clipping frame removes the very elevation the card is composed for. The
//     copy's frame has `clipsContent` off, and an export of it includes the cast.
//
// ── `openDelay` / `closeDelay` are on the wrong plane ────────────────────────
//
// Neither is chrome, and neither is an animation duration. They are the dwell
// times a pointer has to satisfy before anything happens —
// `Future.delayed(openDelay, …)` before the card is shown, `Future.delayed(
// closeDelay, …)` after the pointer leaves both regions — so no pixel differs at
// any moment because of them. The transition itself already has its own field,
// `transitionDuration`, which is what makes this unambiguous rather than a
// judgment call: the animation's length and the gesture's threshold are both
// stated, separately, and only one of them is chrome.
//
// By `core/style-contract.md`'s own test ("does the component look different, or
// behave different?") a dwell threshold belongs to the widget plane, next to
// `swipeSensitivity` and friends. The widget already carries both as flat
// parameters — `resolveHoverCard` reads `widgetOpenDelay ?? merged.openDelay ??
// default` — so `CoreHoverCardStyle` holding them a second time is also the
// double-entry `cross-platform/api.md` forbids once a Style slot exists.
//
// Nothing is drawn for them, and this is NOT the "no Figma counterpart" verdict:
// the fix is on the Core side, and it is a field that should not be on this
// Style at all. Reported upward.
function buildHoverCard(page: PageNode, lk: VarLookup): ComponentNode {
  const c = mintPanelComp(page, 'HoverCard', 'VERTICAL', lk, {
    gap: HOVER_CARD.fields.placementOffset,
  });
  // The trigger is a link in running content — the always-underlined one.
  const linkVariant = bestVariantName(page, 'Link', {
    Variant: 'standard', Underline: 'true', Focus: 'false',
  });
  const link = instanceOf(page, 'Link', linkVariant);
  // The example's trigger — the handle of the profile the card shows (#6473,
  // the designer's copy); a caller's trigger is any widget.
  setInstanceTextNamed(link, 'Child', kHoverCardExampleTrigger);
  const trigger = slotNodes('trigger', link);
  c.appendChild(trigger.holder);
  const surface = panel('panel', 'VERTICAL', lk, {});
  // `panelStyle.padding`, forwarded into the composed `Popup`: the card states
  // the panel's inset, and the `Popup` member that IS that inset is the one
  // composed (16 → `Padding=content`). An inset that is neither preset is still
  // written onto the instance — the one reachable half of a forward whose other
  // fields the composed child already agrees with.
  const panelStyle = HOVER_CARD.fields.panelStyle;
  const popup = popupInstance(page, panelStyle.padding);
  applyForwardedPanelStyle(popup, lk, {
    padding: popupPaddingOverride(panelStyle.padding),
  });
  surface.appendChild(popup);
  c.appendChild(surface);
  lockWidth(surface, panelStyle.maxWidth);
  // `panel` is exactly the card's box, so a clipping frame cuts the cast the
  // `Popup` draws outside it. Set here, on this frame only — `panel()` is shared.
  surface.clipsContent = false;
  popup.layoutSizingHorizontal = 'FILL';
  // The card holds the example profile rather than the stand-in (#6473), set
  // before the width override so the override lands on the example instance.
  setInstanceSwapNamed(popup, 'Content', exampleMainId(page, kHoverCardExample));
  fillPopupContentWidth(popup);
  bindSlot(
    trigger,
    defineProp(propertyOwner(c), 'Trigger', 'INSTANCE_SWAP', mainId(page, 'Link', linkVariant)),
  );
  // After both appends: `surface` is a detached frame until the second one, so
  // exposing before them left the instance with no COMPONENT ancestor and
  // Figma rejected it — and that throw is not rolled back, so it leaves a
  // half-drawn HoverCard on the page.
  exposeSlot([popup], 'Content', 'INSTANCE_SWAP');
  return c;
}

// The composed `Popup`'s content slot, made the width of the card it sits in.
//
// Reached through the instance, because that is where the slot is: `Popup`
// draws `children` as a `content` holder (hugging, bound to `Show content`)
// around the `.Slot` stand-in (bound to `Content`). Both are overridden to
// `FILL`, in that order of nesting — the holder across the popup's inner width,
// the stand-in across the holder. Both are needed: filling only the holder
// leaves the stand-in at its own 160 box inside a wider holder, and filling only
// the stand-in leaves it inside a holder that hugs it, so it stays 160.
//
// Neither has a hugging ancestor to collapse into on this axis: the popup is
// `FILL` in the `panel` frame, which is `FIXED` at the card's ceiling. That is
// what makes `FILL` safe here and not the way a `FILL` under a hugging parent
// would fold its parent toward nothing. Vertical is left as the member draws it
// (the holder hugs, the stand-in is 40 high), which is what the copy states.
//
// Throws when the member's shape is not the one described, not skips: a missing
// holder is a `Popup` that was redrawn into another shape, and a card that
// silently kept a 160 slot would look finished while being the thing this
// override exists to remove.
function fillPopupContentWidth(popup: InstanceNode): void {
  const holders = popup.findAll(
    (n) => n.type === 'FRAME' && n.name === kPopupContentSlotName,
  ) as FrameNode[];
  if (holders.length !== 1) {
    throw new Error(
      `HoverCard: the composed Popup has ${holders.length} "${kPopupContentSlotName}" ` +
        'holder(s), expected 1 — the content slot cannot be made to fill the card',
    );
  }
  const holder = holders[0];
  const stand = holder.children.filter((n) => n.type === 'INSTANCE');
  if (stand.length !== 1) {
    throw new Error(
      `HoverCard: the Popup's "${kPopupContentSlotName}" holder carries ${stand.length} ` +
        'slot instance(s), expected the one `.Slot` stand-in',
    );
  }
  holder.layoutSizingHorizontal = 'FILL';
  (stand[0] as InstanceNode).layoutSizingHorizontal = 'FILL';
}

// ─── DraggablePanel ──────────────────────────────────────────────────────────

// Not a design token, and not chrome: the handle↔panel distance is
// `DraggablePanel.dockOffset`, a widget behaviour parameter whose default is
// `CoreDraggablePanelContract.defaultDockOffset` (= `CoreSpace.space8`). It is
// a widget default rather than a Style field, so it is not in
// `components.json`; mirrored here so the preview docks the panel where the
// widget does.
const kDockOffset = 8;

// Floating edge-docking panel: a drag handle button beside an expandable
// surface panel (caller-provided content). Data-driven from coui_core
// DRAGGABLE_PANEL.fields — handle chrome (background/foreground/size/
// radius/icon) and the surface panel's chrome (background/border/radius/
// padding/width) are both real (the old builder guessed a primary-colored
// fully-round pill handle — the real handle is a surface-colored square at
// a 16px corner radius, sized from `handleSize` rather than hug+padding;
// same "old guess wrong, real token wins" precedent as the Drawer/Toggle
// notes above).
// handleIconStyle.size traces to CoreIconSize (via CoreSize), not
// CoreFontSize — glyphOpts(..., 'size') binds the glyph to the correct
// scale (#3754 axis fix). The panel's own title/body typography has no
// matching field (#3755 OQ-2).
//
// #4037 (C4b) — static→variant-set promotion by ADOPTION. `draggable_panel.axes`
// promotes ONLY `enabled`; its `CoreDraggablePanelDockType` (inside/outside)
// enum sits in `axes.other`, recorded but deliberately not promoted (the seed
// spec's §4-2 boundary), so the enumeration is two combinations and the loose
// COMPONENT is adopted as `Enabled=true`. Enabled=false renders identically:
// `draggable_panel.fields` declares no disabled field at all. Adoption rather
// than a `STRUCTURAL_MIGRATIONS` row because the loose node keeps its id and
// key through the promotion, which is what every instance placed from it needs.
//
// The root is the widget's `Stacks`, so the two children are PLACED, not
// flowed: `_buildHandle` is `AnimatedPositioned(left: x, top: y)` and
// `_buildPanel` opens "beside the handle, on the side with room" at
// `x + handleSize + dockOffset`. Modelling that as a row with an item gap
// invented a spacing field that does not exist — the distance is
// `dockOffset`, a behaviour parameter of the widget, not chrome. Its default
// is `CoreSpace.space8`, which is why the old `lk.space(8)` looked right.
//
// The default handle glyph is `LucideIcons.menu`, not a grip — the widget
// draws `Icon(LucideIcons.menu, iconStyle: resolved.handleIconStyle)` when
// the `handle` slot is null, and this preview draws that default.
//
// Slots → Figma properties. All three, and they take different shapes because
// the slots mean different things:
//   · `handle` — "custom collapsed handle content; when null a default drag
//     glyph is drawn" (contract). The demo draws that default glyph, and the
//     glyph is an Icon INSTANCE, so the slot is an INSTANCE_SWAP whose default
//     is that glyph's main component: a designer swaps the mark, which is
//     exactly what filling the slot does in code.
//   · `panel` — "the expandable panel surface, shown when the handle is open".
//     Two properties, because the surface and its content are different
//     things: the widget draws the surface only `if (open && panel != null)`,
//     so a BOOLEAN hides the whole surface, while the INSTANCE_SWAP fills the
//     one node inside `Padding(panelPadding)` that the caller's widget
//     occupies. The two title/body labels this replaces were content for that
//     slot, and drawing them as fixed copy said this panel has a title and a
//     subtitle — the contract says it has a widget.
//   · `child` — `Position.fill` under everything else, the subtree the panel
//     floats over. It now has a node so it can be swapped and shown; it starts
//     hidden, matching the widget's `null`, so the preview is unchanged.
function buildDraggablePanel(page: PageNode, lk: VarLookup): ComponentSetNode {
  const combos = enumerateAxisCombos(axisSpecsOf(DRAGGABLE_PANEL.axes));
  // The grip is drawn from the `Handle` default, so the bind leaves it at
  // `handleIconStyle.size` (see `IconOpts.fromVariant`).
  const handleSwap = iconSwapDefault(page, 'DraggablePanel', 'Handle', iconMainId(page));
  const mount = mountSet(page, 'DraggablePanel', combos, { adoptLooseAs: 'Enabled=true' });
  // Collected per member and bound after `mount.finish()`: a component property
  // lives on the SET, and until `combineAsVariants` runs a freshly minted
  // member's parent is still the page — so `propertyOwner` would answer with the
  // member itself and each one would grow its own copy of every property.
  const bases: SlotNodes[] = [];
  const grips: InstanceNode[] = [];
  const bodies: SlotNodes[] = [];
  const surfaces: FrameNode[] = [];
  for (const comboName of combos) {
    const c = mount.getOrCreate(comboName);
    c.layoutMode = 'NONE'; // `Stacks` — children are placed, not flowed.
    c.fills = [];
    // `child` first: it is the bottom layer of the widget's `Stacks`.
    const base = standInSlotNodes(page, 'child', 'rectangular');
    c.appendChild(base.holder);
    base.holder.x = 0;
    base.holder.y = 0;
    // `Position.fill` — the base layer spans the box (#4805).
    base.holder.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };
    bases.push(base);
    const handle = indicatorBox(lk, DRAGGABLE_PANEL.fields.handleBorderRadius.topLeft, DRAGGABLE_PANEL.fields.handleSize);
    fillData(handle, lk, colorData(DRAGGABLE_PANEL.fields.handleBackgroundColor));
    setShadow(handle, DRAGGABLE_PANEL.fields.handleShadow, lk, colorData(DRAGGABLE_PANEL.fields.shadowBaseColor));
    // The glyph's colour resolves the way `resolveIcon` resolves one: the
    // `iconStyle`'s own colour wins, and the ambient `IconTheme` is the fallback.
    // Here that ambient is `handleForegroundColor` — the widget wraps the handle
    // content in `IconTheme.merge(data: IconThemeData(color:
    // handleForegroundColor), child: widget.handle ?? Icon(menu,
    // handleIconStyle))`. Both currently name the same token, so writing only the
    // first one meant the canvas was right by coincidence; if Core ever drops
    // `handleIconStyle.color` the glyph now follows the widget instead of losing
    // its colour.
    //
    // What has NO Figma counterpart is the field's other subject: a
    // caller-supplied `handle` inheriting that ambient tint. The `handle` slot is
    // an INSTANCE_SWAP, and whatever component a designer swaps in brings its own
    // fills — Figma has no ambient-colour inheritance, and the nearest thing
    // (`setExplicitVariableModeForCollection`) re-resolves which MODE a bound
    // variable reads, not which variable an arbitrary component's paint is bound
    // to. So the tint reaches the default glyph and stops there.
    const grip = makeIcon('menu', lk, {
      ...glyphOpts(
        lk,
        colorData(DRAGGABLE_PANEL.fields.handleIconStyle.color) ??
          colorData(DRAGGABLE_PANEL.fields.handleForegroundColor),
        DRAGGABLE_PANEL.fields.handleIconStyle.size,
        'size',
      ),
      fromVariant: handleSwap.variant,
    });
    handle.appendChild(grip);
    c.appendChild(handle);
    handle.x = 0;
    handle.y = 0;
    // Collected, not bound here: the reference is written after `finish()` for the
    // reason above, and a detached node rejects `componentPropertyReferences`
    // ("Can only set component property references on symbol sublayer") anyway —
    // nothing rolls that throw back, and it leaves a half-built component on
    // the page.
    grips.push(grip);
    const bg = colorData(DRAGGABLE_PANEL.fields.panelBackgroundColor)!;
    const border = colorData(DRAGGABLE_PANEL.fields.panelBorderColor)!;
    const pad = DRAGGABLE_PANEL.fields.panelPadding;
    const surf = panel('panel', 'VERTICAL', lk, {
      border: border.color!, borderOp: border.opacity, borderArgb: border.argb, strokeN: DRAGGABLE_PANEL.fields.panelBorderWidth,
      radius: DRAGGABLE_PANEL.fields.panelBorderRadius.topLeft,
      pl: pad.l, pr: pad.r, pt: pad.t, pb: pad.b,
    });
    // The panel — not the handle — is a floating surface on both platforms
    // (`draggable_panel_style.dart` reads `theme.surfaceFor(.functional)`; the
    // Web twin marks the panel `webSurfaceMarkerFor(.functional)`), and both
    // opt it into the style's rim.
    applySurfaceMaterial(surf, lk, bg, 'functional', {
      radius: DRAGGABLE_PANEL.fields.panelBorderRadius.topLeft,
      rim: true,
    });
    lockWidth(surf, DRAGGABLE_PANEL.fields.panelWidth);
    setShadow(surf, DRAGGABLE_PANEL.fields.panelShadow, lk, colorData(DRAGGABLE_PANEL.fields.shadowBaseColor));
    // The panel holds the example content rather than the stand-in (#6473) —
    // a docked panel with a dashed box inside reads as empty.
    const body = slotNodes('panel', exampleInstance(page, kDraggablePanelExample, 'panel content'));
    surf.appendChild(body.holder);
    c.appendChild(surf);
    surf.x = handle.width + kDockOffset;
    surf.y = 0;
    body.holder.layoutSizingHorizontal = 'FILL';
    body.instance.layoutSizingHorizontal = 'FILL';
    bodies.push(body);
    surfaces.push(surf);
    const width = surf.x + surf.width;
    const height = Math.max(handle.height, surf.height);
    c.resize(width, height);
    base.instance.resize(width, height); // `Position.fill`
  }
  const set = mount.finish();
  const baseDefault = slotStandInDefault(page, 'rectangular');
  for (const base of bases) {
    bindOptionalSlot(
      base,
      defineProp(set, 'Child', 'INSTANCE_SWAP', baseDefault),
      defineProp(set, 'Show child', 'BOOLEAN', false),
    );
  }
  const gripMainId = handleSwap.id;
  if (gripMainId) {
    for (const grip of grips) {
      bindSwapProp(grip, defineProp(set, 'Handle', 'INSTANCE_SWAP', gripMainId));
    }
  }
  const bodyDefault = exampleSwapDefault(page, kDraggablePanelExample, slotStandInDefault(page, 'text'));
  for (const body of bodies) {
    bindSwapProp(body.instance, defineProp(set, 'Panel', 'INSTANCE_SWAP', bodyDefault));
  }
  // On the surface, not on the slot: the widget draws the whole panel only
  // `if (open && widget.panel != null)`, so `null` removes the surface too.
  //
  // Default ON, unlike the other `W?` slots here, because this one is what the
  // preview is OF — a docked panel with nothing docked is a lone handle, and
  // the widget's own example opens it. `child` above defaults off for the
  // mirror reason: it is the page behind, and drawing it would make every
  // other layer read as content inside it.
  for (const surf of surfaces) {
    bindVisibleProp(surf, defineProp(set, 'Show panel', 'BOOLEAN', true));
  }
  rowSet(set);
  return set;
}

// ─── Swiper ──────────────────────────────────────────────────────────────────

// `CoreSwiperStyle` carries one field of its own — `drawerStyle`, the patch it
// forwards to the `Drawer` it composes — and two variants (`drawer` / `sheet`)
// that are rows of that patch. The swipe gesture is the component; everything
// it draws is the composed drawer's.
//
// ── The panel is a `Drawer` instance ─────────────────────────────────────────
//
// `swiper.dart#_buildDrawerPanel` returns
// `Drawer(content: widget.overlayContent, side:, showDragHandle:, drawerStyle:)`
// — the drawer owns the panel surface (background, border, shadow) AND the
// grab handle, so the surface here is a `Drawer` INSTANCE with its own
// `Show handle` turned on:
//
// ```text
// Swiper (Stacks — the panel is layered over the page)
//   ├─ child     Listener(child: widget.child)          // the page behind
//   └─ Drawer    Side=left, Show handle on              // the panel, its handle
// ```
//
// `Side=left` because that is `CoreSwiperPosition.defaultPosition`, and the
// drawer member for that edge already lays the pill upright on the panel's
// inner edge. `Show handle` is on because `Swiper(showDragHandle:)` defaults
// to true and hands it straight to the drawer.
//
// `Stacks` IS this component's structure: `_buildGhost` renders
// `Stacks[scrim, SlideTransition(panel)]`, the panel layered over the page, so
// the placed root is the modelled edge rather than an artifact of the parity
// guard's `.x =` heuristic.
//
// ── What the composition costs, and why it is still the right trade ──────────
//
// `overlayContent` has no node of its own. In code it is not a child of Swiper
// at all — it is `Drawer(content: widget.overlayContent)`, i.e. it lives inside
// the composed instance, and Figma will not reparent into one. What is reachable
// is the child's own properties, so the Drawer is an exposed instance: its
// `Content` swap surfaces on every Swiper instance, and that IS the slot.
// Drawing a second placeholder over the Drawer's own would have shown two
// contents where the widget has one. Same reading as `buildHoverCard`'s
// `content`.
//
// `Show header` is turned off on the instance: `_buildDrawerPanel` passes no
// `title`, so the widget's `hasHeader` is false and neither the header row nor
// its divider renders. Drawer models that conditional as a BOOLEAN for exactly
// this reason.
//
// The `drawerStyle` patch Swiper forwards reaches the instance only where an
// instance can carry it — the `sheet` row's corner radius, below. Its other
// per-variant value (`panelBorderWidth`: absent on drawer, 0 on sheet) draws no
// visible border either way, so it is left unbound (#3755 OQ-2).
//
// #4035 (C3) — full 4-axis combos (Variant × Enabled = 2×2=4), enumerated by
// the SAME function G10 measures with (T-14). `Enabled` is a real v3 axis on
// swiper, but SWIPER declares no `disabled*` field anywhere (fields or
// variants), so Enabled=false renders identically — the honest rendering of
// "core declares no disabled chrome", not a dimmed grey this builder would
// have to invent. `CoreSwiperPosition` (left/right/top/bottom) stays
// unpromoted in `axes.other` per the seed spec's §4-2 boundary.

// Preview geometry — SWIPER has no page size field (the caller's layout
// decides it), so these are this preview's numbers, applied through `resize()`
// only. The PANEL's width is not among them: it is the composed Drawer's own
// `panelWidth`, read off the instance.
const kSwiperPageWidth = 480;
const kSwiperPageHeight = 320;

function buildSwiper(page: PageNode, lk: VarLookup): ComponentSetNode {
  const variantData = new Map(Object.entries(SWIPER.variants.defaultsByVariant));
  const combos = enumerateAxisCombos(axisSpecsOf(SWIPER.axes));
  const mount = mountSet(page, 'Swiper', combos);
  const bases: SlotNodes[] = [];
  for (const comboName of combos) {
    const combo = parseVariantKey(comboName);
    const v = variantData.get(combo['Variant']);
    if (!v) throw new Error(`Swiper: no data for combo "${comboName}"`);
    const c = mount.getOrCreate(comboName);
    // `Stacks` — the panel is layered over the page, so the children are placed
    // rather than flowed.
    c.layoutMode = 'NONE';
    c.fills = [];
    const base = standInSlotNodes(page, 'child', 'rectangular');
    c.appendChild(base.holder);
    base.holder.x = 0;
    base.holder.y = 0;
    base.instance.resize(kSwiperPageWidth, kSwiperPageHeight);
    // The page under the sheet spans the member — it is the box (#4805).
    base.holder.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };
    bases.push(base);

    // The drawer member for the swiper's default edge — see the note above.
    const drawer = instanceOf(page, 'Drawer', composeVariantName([['Side', restingValueOf('Side')]]));
    // `panelBorderRadius` from the `sheet` row — a bottom sheet is rounded at the
    // top and the composed `Drawer` was keeping its own square corner. Read with
    // `optField` because only the `sheet` row states it: the `drawer` row carries
    // no radius, and reading a missing key would put the sheet's corner on both.
    applyForwardedPanelStyle(drawer, lk, {
      borderRadius: optField<{ topLeft: Dim }>(v, 'panelBorderRadius'),
    });
    // The `overlayContent` slot's only reachable form — see the note above.
    // Exposed after the append: one line earlier the instance had no parent.
    c.appendChild(drawer);
    drawer.isExposedInstance = true;
    setInstanceBool(drawer, 'Show header', false);
    // OFF, because `_buildDrawerPanel` calls the `Drawer` CONSTRUCTOR — not
    // `openDrawer` — and the barrier belongs to the route. Swiper's own ghost
    // (`Stacks[scrim, SlideTransition(panel)]`) has a scrim of its own, and no
    // `CoreSwiperStyle` field for it, so nothing here draws one.
    setInstanceBool(drawer, 'Show barrier', false);
    // ON — `Swiper(showDragHandle: true)` is the widget default, and the swiper
    // hands it to the drawer, which draws the pill in its own handle chrome.
    setInstanceBool(drawer, 'Show handle', true);
    // The instance covers the page: the Drawer member is the route's
    // presentation stack, with its panel docked left inside it. Resizing it to
    // Swiper's own page is what a `.left` dock spanning the full extent means.
    drawer.resize(kSwiperPageWidth, kSwiperPageHeight);
    drawer.x = 0;
    drawer.y = 0;
    c.resize(kSwiperPageWidth, kSwiperPageHeight);
  }
  const set = mount.finish();
  const pageDefault = slotStandInDefault(page, 'rectangular');
  // `defineProp` reuses the id after the first variant — one property on the
  // SET, every variant's node bound to it.
  for (const b of bases) {
    bindSlot(b, defineProp(set, 'Child', 'INSTANCE_SWAP', pageDefault));
  }
  // `layoutSet` arranges the sibling variants inside the SET container. No Dart
  // code has a notion of how wide a variant grid on a Figma page is.
  // g7-preview-only: width of the variant SET's wrap grid on the canvas, no code analogue.
  layoutSet(set, 760);
  return set;
}

// ─── Switcher ────────────────────────────────────────────────────────────────

// COMPONENTS.switcher.fields carries only `duration` (the view-transition
// timing, not rendered in a static preview) — no color/radius/padding/gap/
// typography field exists on CoreSwitcherStyle at all, so nothing here is
// data-driven (#3755 OQ-2 — whole component, same shape as buildPopover
// above). Its one slot is `items: List<W>` — Figma has no repeated-slot
// property, so a designer adds or removes views directly.
//
// View-switcher: shows one of N views with a slide/fade transition; the active
// view is shown by a position indicator underneath. `switcher.dart` draws
// neither that indicator nor a box. The preview borrows `DotIndicator` — the
// component this kit already ships for "which of N is showing" — so the dots
// are an INSTANCE of it, not shapes this file draws and tones itself. The
// redesign names that instance by its member (`Size=sm, Selected=2`) and leaves
// its padding (space/8) and colours to the component, so the one thing written
// onto it here is how many dots show.
function buildSwitcher(page: PageNode, lk: VarLookup): ComponentNode {
  // `switcher.dart` renders `Semantics > GestureDetector > AnimatedValueBuilder
  // > ClipRect > _SwitcherTransition(items)` and paints no box at all — no
  // background, border, corner, inset or spacing anywhere — while `switcher`
  // states only `duration` and `curve`. Undrawn, the component is an empty
  // rectangle on the canvas, so the frame below gives the viewport an edge.
  const c = mintPanelComp(page, 'Switcher', 'VERTICAL', lk, {
    // g7-preview-only: entire preview frame for a widget that paints no box.
    bg: 'surface', border: 'outline-subtle', strokeN: 1, radius: 12, pl: 16, pr: 16, pt: 16, pb: 8, gap: 4,
  });
  c.counterAxisAlignItems = 'CENTER';
  // g7-preview-only: Switcher preview demo width — its size is whichever of `items` shows.
  lockWidth(c, 240);
  // g7-preview-only: placeholder box standing in for `items[index]`, a caller slot.
  const view = panel('view', 'HORIZONTAL', lk, { bg: 'surface-container', radius: 8, pt: 24, pb: 24 });
  view.primaryAxisAlignItems = 'CENTER';
  view.counterAxisAlignItems = 'CENTER';
  c.appendChild(view);
  view.layoutSizingHorizontal = 'FILL';
  // Only the number — `switcher.dart` draws no text of its own, so a worded
  // caption would read as copy the component ships.
  // Its type is the `titleSmall` ROLE (16 · SemiBold · 140%), not a bare size and
  // weight — the role is what states the 140% line box, so the placeholder is
  // 24 + 22.4 + 24 tall (70) rather than the 160% glyph default's 74.
  const caption = textLabelOpts(lk, textStyleData({ role: 'titleSmall' }));
  // g7-preview-only: invented caption in that placeholder, the 2nd of 3 demo views, inked `outline` — the light grey of a stand-in, not `on-surface`, the colour of real content.
  view.appendChild(makeLabel('2', lk, { ...caption, colorVar: lk.sem('outline') }));
  // The position indicator: a `DotIndicator` at its smallest rung, the second
  // of the three dots current. The member is the instance's `Size` / `Selected`
  // pose; its dot colours (`on-surface` current, `outline-variant` the rest)
  // and padding (space/8) are the component's own defaults, restated nowhere
  // here — an instance follows the main component when they move.
  const dots = instanceOf(page, 'DotIndicator', composeVariantName([['Size', 'sm'], ['Selected', '2']]));
  dots.name = 'dot indicator';
  // `DotIndicator` ships dots 3–5 shown (five dots) because a caller's `length`
  // is a runtime count; the three views this preview stands in for are the
  // first three, so dots 4 and 5 are turned off on the instance.
  setInstanceBoolNamed(dots, 'Show dot 4', false);
  setInstanceBoolNamed(dots, 'Show dot 5', false);
  c.appendChild(dots);
  return c;
}

export const OVERLAY_VIEWS: RegistryEntry[] = [
  { section: 'Overlay', name: 'HoverCard', build: buildHoverCard, needs: ['Popup', 'Link', kHoverCardExample] },
  { section: 'Overlay', name: 'DraggablePanel', sizing: { width: 'fixed', height: 'fixed', why: 'stage — 기본 숨김인 child 슬롯만 Position.fill 로 박스를 채우고(STRETCH), 보이는 것은 panelWidth 고정 패널과 핸들뿐이라 따라올 내용이 없다' }, build: buildDraggablePanel, needs: ['Icon', kSlotStandInComponent, kDraggablePanelExample] },
  { section: 'Overlay', name: 'Swiper', build: buildSwiper, needs: ['Drawer', kSlotStandInComponent] },
  { section: 'Overlay', name: 'Switcher', build: buildSwitcher, needs: ['DotIndicator'] },
];
