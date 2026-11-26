/// <reference types="@figma/plugin-typings" />

import { bindLayoutBound } from '../layout-bound';
import {
  kChipCloseName,
  CHIP,
  chipTableColors,
  ChipEmphasis,
  _kChipCloseGlyph,
  setCentringInset,
  kChipPrefixLabelName,
} from '../chip-composition';

import {
  mainComponentIdOf as mainIdOf,
  pinAbsolute,
  sizePin,
  ColorData,
  RegistryEntry,
  VarLookup,
  addControlShadow,
  applySurfaceMaterial,
  applyPanelCompChrome,
  autoFrame,
  bestVariantName,
  bindAxisSize,
  bindPad,
  bindLayerOpacity,
  bindRadiusN,
  bindSize,
  bindSwapProp,
  bindTextProp,
  bindVisibleProp,
  borderData,
  defaultSetLayout,
  defineProp,
  fillData,
  fillSem,
  focusOutlineRing,
  forwardFocusBand,
  focusRing,
  glyphOpts,
  iconMainId,
  iconMainIdAt,
  setSlotIcon,
  glyphPaint,
  labelColor,
  iconSwapDefault,
  instanceOf,
  lockWidth,
  makeIcon,
  makeLabel,
  markStep,
  mint,
  mintPanelComp,
  mountSet,
  PadData,
  panel,
  pinInFlow,
  propertyOwner,
  drainTextStyleAttach,
  reportSubProgressAndYield,
  textLabelOpts,
  timedGeom,
  vStackSet,
  hostedDivider,
  applyForwardedButtonStyle,
  setInstanceBoolNamed,
  setShadow,
  hideInstanceLabel,
  instanceTextNode,
  pinInstanceBox,
  bindSpaceField,
  kAvatarRest,
  kSlotStandInComponent,
  slotStandIn,
  slotStandInDefault,
} from '../helpers';
import { bindShowFocusRing, defineShowFocusRing, stateAxis } from '../state-axis';
import { linkShadowStyle } from '../shadow-style';
import { afterNodeBindLands, findComponentByName } from '../identity';
import type { FocusRingNodes } from '../helpers';
import {
  colorData,
  dimVal,
  mergeTextStyleData,
  optField,
  textStyleData,
  Color,
  Dim,
} from '../compat/v1';
import { STATUS, STAT, COMPONENTS } from '../data';
import {
  axisSpecsOf,
  composeVariantName,
  enumerateAxisAssignments,
  enumerateAxisCombos,
  restingValueOf,
} from '../axis-combos';
import { parseVariantKey } from '../variant-safety';
import { iconShapeGlyphSize, kPlainButtonForeground } from '../button-defaults';

const BANNER = COMPONENTS.banner;
const CHIP_GROUP = COMPONENTS.chip_group;
const KBD = COMPONENTS.kbd;
const CODE_SNIPPET = COMPONENTS.code_snippet;
const DESCRIPTION_CARD = COMPONENTS.description_card;
const EMPTY_STATE = COMPONENTS.empty_state;
const DOT_INDICATOR = COMPONENTS.dot_indicator;
const INDICATOR = COMPONENTS.indicator;
const LOADING = COMPONENTS.loading;
const LISTING = COMPONENTS.listing;
const BASIC = COMPONENTS.basic;
// The size an `Icon` handed to a caller slot draws at when the widget renders
// it as handed — no size of its own and no `IconTheme` around it: the app
// root's ambient icon size, `CoreIconStyle.defaultAmbientSize`. Read by
// Stat's `icon`, DescriptionCard's `titleLeading` / `titleTrailing` and
// Basic's `trailing`; each site says why it qualifies.
const ICON = COMPONENTS.icon;

// ─── Slot → Figma component property ─────────────────────────────────────────
//
// A contract's composition slots (`message` / `leading` / `action` / …) accept
// arbitrary widgets. Figma's equivalent is a component property, and which kind
// follows from the SHAPE of the node the builder puts in that slot — not from
// the slot's nullability:
//
//   text node                 → TEXT           (the copy is what a designer edits)
//   whole region (frame /     → BOOLEAN        (only a property makes a region
//     composed instance)                        hide-able from an instance)
//   Icon instance             → INSTANCE_SWAP  (swap the glyph, keep the layout)
//
// `bindTextProp` / `bindVisibleProp` / `bindSwapProp` each merge one key into
// `componentPropertyReferences` (`addPropRef` copies what is there first), so a
// node can carry two kinds when the slot is a single node — a `W?` text line is
// one TEXT node with `characters` AND `visible` (Banner's description below,
// Toast's in overlay.ts). A `List<W>` slot gets nothing at all: Figma has no
// repeated-slot property, and a designer adds/removes children directly.
//
// An optional INSTANCE slot needs BOTH kinds — "is this slot filled" and "with
// what" — and gets TWO nodes: a `slotHolder` frame carrying the BOOLEAN and its
// single child carrying the INSTANCE_SWAP. That is the shape `badgeIconSlot` /
// `avatarBadgeSlot` (display.ts) already use, for the same reason. The holder
// hugs both axes with no fill, padding or gap, and an auto-layout parent skips
// a hidden child entirely, so an unfilled slot costs no pixels and no gap.
//
// The property that names the slot is the INSTANCE_SWAP / TEXT one, not the
// BOOLEAN: it is the one that answers "what can go here", which is what a
// `W` / `W?` slot is. The BOOLEAN reads `Show <slot>`.
//
// A slot whose placeholder is a plain drawn frame can carry NEITHER kind — a
// BOOLEAN can hide it but nothing can put a different widget in it, so the
// frame IS the slot. Every such placeholder below is an instance of the
// component the widget's own doc example names, which is what makes the slot
// swappable at all.
//
// Properties live on the property OWNER — the COMPONENT_SET when there is one
// (`addComponentProperty` on a set member throws). For a set builder that means
// defining them AFTER `mount.finish()`: until `combineAsVariants` runs, a
// freshly minted variant's parent is still the page, so `propertyOwner` would
// answer with the variant itself and every variant would grow its own copy.
// The per-variant nodes are collected during the loop and bound afterwards.

// The id of the `Icon` set's `Icon=<name>` variant — an INSTANCE_SWAP default
// is a node id (`addComponentProperty('X', 'INSTANCE_SWAP', '2:22')`).
//
// Read off the page rather than from the instance `makeIcon` just returned:
// `InstanceNode.mainComponent` is WRITE-ONLY under this plugin's
// `documentAccess: "dynamic-page"` manifest, so the sync builder here cannot
// read it back (`getMainComponentAsync` is the only reader, and it is async).
//

// ─── Composing a child that WRAPS something ──────────────────────────────────
//
// Figma refuses to add a child to an instance — an instance mirrors its main
// component's subtree, and the API rules out reparenting "children of
// instances". Several widgets in this file wrap something in a component that
// owns a `child` slot: `Button(child: Icon(…))` (CodeSnippet's copy affordance,
// Chip's close affordance), `FocusOutline(child: dot)` (DotIndicator's selected
// dot), `FadeScroll(child: Row(chips))` (ChipGroup's scroll layout). None of
// them can be expressed by nesting into the instance.
//
// So the wrapped content rides above the instance inside a plain, unpainted
// frame that carries no chrome of its own — it stands in for the layout node
// the widget already has there (the `Row` child, the `Padding`, the viewport).
// Everything else below is an ordinary instance override, the same kind
// `repaintGlyph` (icon-nodes.ts) already performs on every icon instance and
// `buildListing` performs on its `Divider` line.
//
// What is deliberately NOT done here: writing another builder's
// component-property ids. `Button` exposes a `Leading icon` INSTANCE_SWAP that
// would be the tidier route, but the runtime harness models component
// properties on a main component and not on an instance, so that override is
// untested code whose failure mode is drawing the wrong glyph, silently.

// A named layer inside a composed instance — the slot the CHILD builder drew
// for its own `child`. Matched by name rather than by position so a structure
// change upstream leaves the slot alone instead of throwing.
function instanceFrameSlot(inst: InstanceNode, name: string): FrameNode | null {
  for (const node of inst.findAll((n) => n.name === name)) {
    if (node.type === 'FRAME') return node;
  }
  return null;
}

// Puts this use site's copy into a composed instance. `setProperties` when the
// child declares a TEXT property (the documented path), else the text node
// itself — the same override a designer's double-click produces, and the only
// path the runtime harness can take (it models properties on a main component,
// not on an instance).
function setInstanceText(inst: InstanceNode, text: string): void {
  const props: ComponentProperties | undefined = inst.componentProperties;
  if (props && typeof inst.setProperties === 'function') {
    for (const name of Object.keys(props)) {
      if (props[name].type === 'TEXT') {
        const patch: { [key: string]: string } = {};
        patch[name] = text;
        inst.setProperties(patch);
        return;
      }
    }
  }
  const node = instanceTextNode(inst);
  if (node) node.characters = text;
}

// The two axis totals of an inset a host forwards to a composed child.
//
// `PadData`'s logical spelling (`start`/`end`) resolves to left/right inside
// `bindPad` and nowhere else, and this does not break that: a SUM of both
// horizontal sides is the same number in either reading direction, so no
// "which side is leading" decision is being made a second time. Only the sum is
// safe to take here; a single side would be that second decision.
function insetTotals(o: PadData): { x: number; y: number } {
  const [l, r] = 'start' in o ? [o.start, o.end] : [o.l, o.r];
  return { x: dimVal(l) + dimVal(r), y: dimVal(o.t) + dimVal(o.b) };
}


// The region an optional slot's BOOLEAN hides — see the header note. Named
// after the contract slot so the layer panel and the property panel agree.
function slotHolder(name: string): FrameNode {
  return autoFrame(name, 'HORIZONTAL');
}

// ─── `Align`, and the `Gap` between two named siblings ───────────────────────

// `CoreBasicAlignment`'s nine members as the pair of Figma auto-layout
// alignments that reproduces them.
//
// A widget's `Align(alignment: …, child: x)` inside a `crossAxisAlignment:
// .stretch` parent is, in Figma, a frame that FILLs the parent's cross axis and
// positions its one child by the two axis alignments — the horizontal component
// on `primaryAxisAlignItems` of a HORIZONTAL frame, the vertical on
// `counterAxisAlignItems`. There is nothing approximate about the mapping: both
// vocabularies are the same 3 × 3 grid.
//
// Spelled out here because the exporter emits the enum member's NAME and
// nothing else (`{"choice":"topCenter"}`), and the two Figma words that name
// appears nowhere in the JSON. A CLOSED set — nine members on one enum — so the
// table is total rather than a sample.
const kBasicAligns: Record<
  string,
  {
    readonly main: 'MIN' | 'CENTER' | 'MAX';
    readonly cross: 'MIN' | 'CENTER' | 'MAX';
  }
> = {
  topStart: { main: 'MIN', cross: 'MIN' },
  topCenter: { main: 'CENTER', cross: 'MIN' },
  topEnd: { main: 'MAX', cross: 'MIN' },
  centerStart: { main: 'MIN', cross: 'CENTER' },
  center: { main: 'CENTER', cross: 'CENTER' },
  centerEnd: { main: 'MAX', cross: 'CENTER' },
  bottomStart: { main: 'MIN', cross: 'MAX' },
  bottomCenter: { main: 'CENTER', cross: 'MAX' },
  bottomEnd: { main: 'MAX', cross: 'MAX' },
};

// `CoreBasicMainAxisAlignment` → the Figma auto-layout alignment on the frame's
// PRIMARY axis. Six members and Figma has all six, so this is a total mapping
// rather than a lossy one — `spaceBetween`/`Around`/`Evenly` are real Figma
// values, not approximations of them.
//
// Throws on an unknown member for the reason `alignCell` does: the runtime
// harness drives every builder against the committed `components.json`, so a new
// member fails on the machine that adds it, whereas a fallback would put the
// content in the wrong place and look deliberate.
const kMainAxisAligns: Record<string, 'MIN' | 'CENTER' | 'MAX' | 'SPACE_BETWEEN'> = {
  start: 'MIN',
  end: 'MAX',
  center: 'CENTER',
  spaceBetween: 'SPACE_BETWEEN',
  // Figma's auto-layout has one distributed mode. `spaceAround` and
  // `spaceEvenly` differ from it only in the half/full gap at the two ends, and
  // that gap is expressible as padding — but which of the two a frame means
  // cannot be recovered from `SPACE_BETWEEN` alone, so they are refused rather
  // than flattened into it. Nothing in this library states either today.
};

function mainAxisOf(
  leaf: { readonly choice: string },
  field: string,
): 'MIN' | 'CENTER' | 'MAX' | 'SPACE_BETWEEN' {
  const align = kMainAxisAligns[leaf.choice];
  if (align === undefined) {
    throw new Error(
      `${field}: unknown CoreBasicMainAxisAlignment "${leaf.choice}". ` +
        'Add it to `kMainAxisAligns` in display-data.ts. `spaceAround` / ' +
        '`spaceEvenly` are deliberately absent — Figma has one distributed ' +
        'mode and collapsing either into it loses the end gap that ' +
        'distinguishes them, which is a design decision. Known: ' +
        `${Object.keys(kMainAxisAligns).join(', ')}.`,
    );
  }
  return align;
}

// One slot's `Align` cell: a HORIZONTAL frame that hugs its child and aligns it
// by the stated member. The caller sets which axis FILLs, because that is the
// parent's `crossAxisAlignment: .stretch` talking, not the alignment field's.
//
// Throws on a name the table does not know rather than falling back to a
// corner. Neither arm is tidy — nothing is rolled back, so the throw leaves a
// half-drawn component on the page too — but the throw is the safe one: it
// names the failing entry in the run log, and `selftest-registry-runtime`
// drives every builder against the committed `components.json`, so an unknown
// member fails CI on the machine that introduced it. A silent fallback is
// caught by neither, because a title aligned to the wrong corner still looks
// like a title.
function alignCell(
  name: string,
  leaf: { readonly choice: string },
  field: string,
): FrameNode {
  const pair = kBasicAligns[leaf.choice];
  if (pair === undefined) {
    throw new Error(
      `${field}: unknown CoreBasicAlignment "${leaf.choice}". Add it to ` +
        '`kBasicAligns` in display-data.ts with the two Figma auto-layout ' +
        'alignments that reproduce it. Known: ' +
        `${Object.keys(kBasicAligns).join(', ')}.`,
    );
  }
  const cell = autoFrame(name, 'HORIZONTAL');
  cell.primaryAxisAlignItems = pair.main;
  cell.counterAxisAlignItems = pair.cross;
  return cell;
}

// The one counter-axis alignment a row can carry, given the two outer slots
// that state one each.
//
// Figma allows exactly one: "all layers in an auto-layout frame must now have
// the same counter axis alignment. `MIN`, `CENTER`, and `MAX` are now deprecated
// values of `layoutAlign`" (`@figma/plugin-typings`, AutoLayoutChildrenMixin).
// The per-slot cell cannot supply it either — a cell that hugs its child is
// exactly the child's height, so a vertical alignment inside it has no room to
// act, and making the cell FILL instead would drop the child's own height out
// of the row's hug and leave a 40px avatar in a 32px cell.
//
// So the two fields are read together. They agree today (both `center`), and
// a divergence is refused rather than drawn: only one of the two could be
// honoured and nothing on the canvas would say which. Loud for the same reason
// `alignCell`'s throw is — `selftest-registry-runtime` drives this builder
// against the committed `components.json`, so the machine that changes one
// field sees it, instead of a designer finding a glyph in the wrong place.
function rowCounterAxis(
  leading: { readonly choice: string },
  trailing: { readonly choice: string },
): 'MIN' | 'CENTER' | 'MAX' {
  const lead = kBasicAligns[leading.choice];
  const trail = kBasicAligns[trailing.choice];
  if (lead === undefined || trail === undefined) {
    throw new Error(
      'basic.leadingAlignment / trailingAlignment: unknown CoreBasicAlignment ' +
        `"${leading.choice}" / "${trailing.choice}" — see \`kBasicAligns\`.`,
    );
  }
  if (lead.cross !== trail.cross) {
    throw new Error(
      'basic.leadingAlignment / trailingAlignment disagree on the vertical ' +
        `axis ("${leading.choice}" is ${lead.cross}, "${trailing.choice}" is ` +
        `${trail.cross}). A Figma auto-layout frame carries ONE counter-axis ` +
        'alignment for all its children, so the row cannot honour both. Give ' +
        'each slot a fixed-height cell of its own and align inside it, which ' +
        'means deciding that height — a design decision, not a wiring one.',
    );
  }
  return lead.cross;
}

// A `Gap(gapStyle: …)` the widget interleaves between two named siblings.
//
// Figma gives an auto-layout frame ONE `itemSpacing`, so a column whose widget
// interleaves two or three DIFFERENT gaps cannot carry them all that way — the
// frame's own gap is set to nothing and each stated gap gets a node, which is
// exactly the shape the widget has.
//
// Square and unpainted, which is `Gap` itself — it paints nothing. Not an
// INSTANCE of that component: `Gap` owns no chrome at all — it *is* the space —
// so there is no surface here for a child component to be the single source of,
// and an instance would need resizing per use site plus a `needs` edge for a
// node that draws nothing. `form-pickers.ts` already stands a gap up this way.
//
// Bound to `space/N`, the token the code states: every `CoreGapStyle.size`
// these spacers carry is a `CoreSpace` step, and the export names it
// `Primitives/space/N`. Binding the same number to `size/N` drew the right
// length under the wrong token — a reader of the variable panel saw a
// dimension where the code has a gap. The `space/N` variables are scoped to
// GAP, which only narrows Figma's picker; the binding itself holds. A document
// whose Variables predate the step falls back to `size/N`, as `bindSize` does.
function gapSpacer(name: string, lk: VarLookup, size: number | Dim): FrameNode {
  const g = figma.createFrame();
  g.name = name;
  g.layoutMode = 'NONE';
  g.fills = [];
  const side = dimVal(size);
  const space = lk.spaceOrNull(side);
  if (!space) {
    bindSize(g, lk, side, side);
    return g;
  }
  g.resize(side, side);
  g.setBoundVariable('width', space);
  g.setBoundVariable('height', space);
  return g;
}

// A composed `Button` whose code counterpart takes an `Icon` as its child.
//
// Returns the layout cell, not the instance: the glyph has to sit inside the
// button's box and cannot be appended to it, so the cell holds the instance and
// the glyph stacked at the same origin.
//
// The box is the one the widget resolves, in the widget's own order:
//
//   · an explicit `width`/`height` from the forwarded `buttonStyle` wins
//     outright — `button.dart` spends them as `SizedBox(width:)` and as the
//     `ConstrainedBox`'s `minHeight`.
//   · otherwise the button hugs `padding + child`, which is why `padding` has to
//     arrive: with the forwarded zero inset the affordance is exactly the glyph
//     wide, and without it the canvas showed Button's own size-row inset (24 wide
//     for a 16 glyph at `sm`) — the widget's `closeButtonStyle.padding` never
//     reaching the child it was forwarded to.
//   · the cross axis is floored by the size token's height, which the `Button`
//     component already carries as its own locked box (`form.ts` resizes each
//     variant to `s.height`). Read off the child rather than restated here, so
//     the floor cannot disagree with the button it applies to.
//
// The instance is resized rather than left hugging, because a hug with every
// child hidden collapses to nothing: the glyph rides ABOVE the instance (Figma
// refuses to append into one), so with the label hidden and the inset at zero
// there is nothing inside left to hold the box open.
function iconButton(
  page: PageNode,
  lk: VarLookup,
  o: {
    name: string;
    variant: string;
    size: string;
    glyph: string;
    glyphSize: number | Dim;
    glyphColor: ColorData | null;
    /// The host's forwarded `buttonStyle.padding`. Bound onto the instance as
    /// its own override, the way a designer's change to an instance's inset is.
    padding?: PadData;
    /// `square` / `circle` — the widget's `shape:`. The box is the size row's
    /// height on both axes (the `Button` member of that shape already carries
    /// it), and `padding` does not apply: those shapes resolve their own inset
    /// (`iconShapePadding`, zero by default), not the forwarded one.
    shape?: 'square' | 'circle';
    radius?: number | Dim;
    width?: number | Dim;
    height?: number | Dim;
    /// The band under the button's ring, when the host states an opaque one —
    /// a host whose own background the button cannot know. Omitted, the band
    /// stays Button's transparent default.
    focusOutlineStyle?: { offsetColor: Color; borderWidth: Dim; align: Dim } | null;
    /// Lays the cell out around its glyph instead of at a fixed box: an
    /// auto-layout frame that hugs the glyph plus an even inset, with the
    /// button behind it on STRETCH. An instance of the component can then move
    /// the box without a size override (refused inside an instance) — by
    /// swapping the glyph's step and stating the inset (`forwardChipCloseBox`).
    hug?: boolean;
  },
): FrameNode {
  const btn = instanceOf(
    page,
    'Button',
    bestVariantName(page, 'Button', {
      Variant: o.variant,
      Size: o.size,
      ...(o.shape != null ? { Shape: o.shape } : {}),
    }),
  );
  btn.name = o.name;
  // Into its cell first, so every override below lands on an instance that is
  // already where it will stay — the box is stated last and nothing after it
  // moves the instance again.
  const cell = figma.createFrame();
  cell.name = o.name;
  cell.layoutMode = o.hug ? 'HORIZONTAL' : 'NONE';
  cell.fills = [];
  // Hugging: the button rides behind the glyph as an absolute layer on
  // STRETCH, through a holder (an instance takes neither `constraints` nor an
  // absolute pin of its own — `pinAbsolute` says why), so it follows whatever
  // box the glyph and the inset make.
  let holder: FrameNode | null = null;
  if (o.hug) {
    cell.primaryAxisAlignItems = 'CENTER';
    cell.counterAxisAlignItems = 'CENTER';
    // Pinned at MIN, not yet STRETCH: the cell is still the 100×100 a new frame
    // is minted at and only hugs the glyph below. A STRETCH pin keeps the gap to
    // the far edge it has now (100 − the instance's own 32), so the shrink to a
    // 20 box drives the holder's height below zero, which Figma stores as a
    // vertical flip (`scaleY −1`) — and the later resize keeps the flip, leaving
    // the button a box above its glyph. Measured on the canvas: every Chip close
    // button sat at y −10 while its ✕ sat at y 12. STRETCH goes on once the
    // holder has the cell's size (below), when both gaps are zero.
    holder = pinAbsolute(cell, btn, 0, 0, { horizontal: 'MIN', vertical: 'MIN' }) as FrameNode;
  } else {
    cell.appendChild(btn);
    btn.x = 0;
    btn.y = 0;
  }
  hideInstanceLabel(btn);
  if (o.padding != null) bindPad(btn, lk, o.padding);
  if (o.radius != null) bindRadiusN(btn, lk, o.radius);
  if (o.focusOutlineStyle != null) forwardFocusBand(btn, lk, o.focusOutlineStyle);
  const side = dimVal(o.glyphSize);
  const pad = o.padding != null ? insetTotals(o.padding) : { x: 0, y: 0 };
  // The `> 0` guard is for the runtime harness, whose nodes have no layout
  // engine and report height 0 on a hug auto-layout; Figma rejects
  // `resize(0, …)`. In Figma this reads the main component's real box.
  const floorH = btn.height > 0 ? btn.height : 0;
  const shapeSide = Math.max(side, floorH);
  const w = o.width != null ? dimVal(o.width) : o.shape != null ? shapeSide : side + pad.x;
  const h = o.height != null ? dimVal(o.height) : o.shape != null ? shapeSide : Math.max(side + pad.y, floorH);
  if (o.shape != null && holder == null) {
    // A shaped member draws its own glyph — the `Leading` slot, swapped to
    // `Button`'s default icon (a check) — so the glyph goes INTO that slot
    // instead of riding above it. Riding above, the default stayed under it:
    // Banner's dismiss shipped the ✕ drawn over a ✓, which read as an ✕ on a
    // solid fill and as both strokes on a weak one (#6214). Through the slot
    // the designer also sees `lucide/x` on the instance's `Leading` property.
    cell.resize(w, h);
    pinInstanceBox(btn, w, h);
    setSlotIcon(btn, 'leading', iconMainIdAt(page, side), o.glyph, glyphPaint(lk, labelColor(lk, o.glyphColor)));
    return cell;
  }
  const glyph = makeIcon(o.glyph, lk, glyphOpts(lk, o.glyphColor, o.glyphSize, 'size'));
  if (holder != null) {
    // A floor the button inherited from its size row would hold it open past
    // the box (the same clearing `pinInstanceBox` does for a fixed one).
    if (btn.minWidth != null && btn.minWidth > w) btn.minWidth = null;
    if (btn.minHeight != null && btn.minHeight > h) btn.minHeight = null;
    cell.appendChild(glyph);
    // The box is the glyph plus an even inset — the centring offset, not a
    // spacing token.
    setCentringInset(cell, w, h, side);
    cell.primaryAxisSizingMode = 'AUTO';
    cell.counterAxisSizingMode = 'AUTO';
    sizePin(holder, w, h);
    holder.x = 0;
    holder.y = 0;
    holder.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };
    return cell;
  }
  cell.resize(w, h);
  pinInstanceBox(btn, w, h);
  cell.appendChild(glyph);
  glyph.x = (w - side) / 2;
  glyph.y = (h - side) / 2;
  return cell;
}

// ─── Banner ──────────────────────────────────────────────────────────────────

// Data-driven from coui_core: BANNER.variants.defaultsByVariant (5 real
// variants — default/info/success/warning/destructive, not the old
// hand-picked 4) + BANNER.fields
// (radius/border-width/padding/gaps/icon size/title + description typography).
//
// Shape mirrors the widget: `[icon, Expanded(Column[message, description]),
// action]`. The message reads `titleStyle` and the description `descriptionStyle`
// — before the content column existed, the single message line was drawn with
// `descriptionStyle`, which is the description's field, so the two-level
// hierarchy the widget renders was not visible at all.
//
// The action affordance is an INSTANCE of the `Button` component: `CoreBannerStyle`
// carries an `actionButtonStyle` slot, so a banner genuinely composes Button, and
// a hand-drawn label could not follow a Button change (the content-hash skip
// leaves a parent alone whose own recipe did not change).
//
// Keyed by the axis member spelling, and the lookups below THROW on a miss.
// They used to read `default_` (Dart's stand-in for the reserved word) and
// fall back with `??`. The axis member was later renamed `neutral` and these
// keys were not, so `neutral` silently drew the fallback glyph with an EMPTY
// message — and an empty TEXT node FILLing its parent measures zero wide,
// which is how two of the ten members came to render ~400px tall with one
// character per line. The `??` is what made a rename look like a layout bug.
const _kBannerIcon: Record<string, string> = {
  neutral: 'bell',
  info: 'info',
  success: 'circle-check',
  warning: 'triangle-alert',
  destructive: 'circle-x',
};
const _kBannerMsg: Record<string, string> = {
  neutral: '일반 안내예요.',
  info: '새 버전이 나왔어요.',
  success: '변경 사항을 저장했어요.',
  warning: '체험 기간이 3일 남았어요.',
  destructive: '결제를 처리하지 못했어요.',
};

/** The glyph for a variant, or a throw naming the key that drifted. */
function bannerGlyph(variant: string): string {
  const glyph = _kBannerIcon[variant];
  if (glyph == null) {
    throw new Error(
      `Banner: no glyph for variant "${variant}" — _kBannerIcon is keyed by ` +
        `the axis member and one of them was renamed. Keys present: ` +
        `${Object.keys(_kBannerIcon).join(' | ')}`,
    );
  }
  return glyph;
}

/** The demo line for a variant, or a throw naming the key that drifted. */
function bannerMessage(variant: string): string {
  const message = _kBannerMsg[variant];
  if (message == null) {
    throw new Error(
      `Banner: no message for variant "${variant}" — _kBannerMsg is keyed by ` +
        `the axis member and one of them was renamed. An empty message ` +
        `measures zero wide and collapses the member's height. Keys ` +
        `present: ${Object.keys(_kBannerMsg).join(' | ')}`,
    );
  }
  return message;
}
// One shared line: a TEXT property's default lives on the SET, so a per-variant
// description would be overwritten by whichever variant defined it first.
const _kBannerDesc = '내용을 확인하고 필요하면 조치해 주세요.';

// #4035 (C3) — full 4-axis combos (Variant = 5), enumerated by the SAME
// function G10 measures with (T-14). Banner has no Size and no Enabled axis in
// v3, so the combination set is exactly the variant enum; the only change on
// the page is the `default` → `default_` spelling the axis carries (a rename
// in src/renames.ts — the child keeps its key).
function buildBanner(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = BANNER.fields;
  const titleStyle = textStyleData(f.titleStyle);
  const descStyle = textStyleData(f.descriptionStyle);
  const variantData = new Map(Object.entries(BANNER.variants.defaultsByVariant));
  // Two axes. The emphasis members come from the exported contract rather
  // than a literal here, so the canvas cannot hold a member the enum does
  // not have — which is the whole reason the axis is worth wiring instead
  // of hardcoding one half.
  const emphasis = BANNER.axes.other.find(
    (o) => o.enum === 'CoreBannerEmphasis',
  );
  if (!emphasis) {
    throw new Error(
      'Banner: CoreBannerEmphasis is gone from the exported axes — the ' +
        'canvas has a Style axis that nothing in the contract now backs.',
    );
  }
  const combos = enumerateAxisCombos([
    ...axisSpecsOf(BANNER.axes),
    { axis: 'Style' as const, values: emphasis.members },
  ]);
  const mount = mountSet(page, 'Banner', combos);
  // `outline`, not the set's first variant — banner.dart's own example
  // documents the action as an outline Button, and an unnamed instanceOf
  // returns whatever variant happens to sort first (a filled primary pill).
  // `Enabled=true` is Button's own axis spelling under the four-axis
  // enumeration; a pref naming an axis the child no longer has would score
  // nothing and let the first variant win again.
  const actionVariant = bestVariantName(page, 'Button', {
    Variant: 'outline',
    Size: 'sm',
  });
  // The inline inset is a `plain` action's alone (`plainActionButtonStyle`);
  // any other variant keeps its own size row's (12 at `sm` for the outline the
  // docs show), so the same `sm` outline is as wide here as outside a banner
  // (#6214). Which variant that is is decided by what the swap LANDS, not by
  // what is asked for above: `defineProp` keeps an existing `Action` default
  // so a designer's instance overrides keep their property, and that default
  // was `plain`. Keyed on the request, the canvas drew a `plain` action flush
  // with its label (0 a side) while both widgets give it 8.
  const plainActionPadding = f.plainActionButtonStyle.padding;
  const actionPaddingFor = (variantName: string | undefined): typeof plainActionPadding | null =>
    variantName != null && parseVariantKey(variantName)['Variant'] === 'plain'
      ? plainActionPadding
      : null;
  const actionPadding = actionPaddingFor(actionVariant ?? undefined);
  const messageNodes: TextNode[] = [];
  const descriptionNodes: TextNode[] = [];
  const actionHolders: FrameNode[] = [];
  const actionNodes: InstanceNode[] = [];
  const actionForegrounds: {
    node: InstanceNode;
    color: ColorData | null;
    band: { offsetColor: Color; borderWidth: Dim; align: Dim } | null;
  }[] = [];
  const dismissHolders: FrameNode[] = [];
  for (const comboName of combos) {
    const combo = parseVariantKey(comboName);
    const name = combo['Variant'];
    // Keyed `variant/emphasis`, matching the two axes above.
    const v = variantData.get(`${name}/${combo['Style']}`);
    if (!v) throw new Error(`Banner: no data for combo "${comboName}"`);
    const bg = colorData(v.backgroundColor)!;
    // Optional: only the `weak` rows state a border. The `solid` rows fill
    // with the tone itself, and a border against your own fill is invisible
    // — so those rows say nothing rather than repeating the fill.
    const border = colorData(optField<Color>(v, 'borderColor'));
    const icon = colorData(v.iconColor);
    const text = colorData(v.textColor);
    // Only the `solid` rows state a ring band: a tone fill is a background the
    // dismiss and the action cannot be assumed to share with the page, so both
    // resolvers merge this under the caller's own button slots. The `weak` rows
    // sit on the page's own tint and say nothing — the transparent default.
    const rowOutline = 'focusOutlineStyle' in v ? v.focusOutlineStyle : null;
    const c = mount.getOrCreate(comboName);
    applyPanelCompChrome(c, 'HORIZONTAL', lk, {
      border: border?.color ?? undefined, borderOp: border?.opacity, borderArgb: border?.argb,
      // No stroke where no colour was stated, rather than a zero-width one:
      // a stroke with no colour renders as black in a forced-colours mode.
      strokeN: border ? f.borderWidth : 0, radius: f.borderRadius.topLeft,
      // The rule is one hairline UNDER the banner, not a box — both
      // widgets draw exactly that (`Border(bottom:)` /
      // `border-bottom-width`), and with a zero radius it falls as a
      // straight line across the page. Painting all four sides made the
      // canvas a boxed banner the code never renders.
      strokeSides: { bottom: true },
      pl: f.padding.l, pr: f.padding.r, pt: f.padding.t, pb: f.padding.b,
      gap: f.iconContentGapStyle.size,
    });
    // A content surface on both platforms (`banner_style.dart` folds
    // `theme.surfaceFor(.content)` into its fill; the Web twin marks itself
    // `webSurfaceMarkerFor(.content)`). A literal fill stays unpainted, as the
    // chrome options above always left it.
    applySurfaceMaterial(c, lk, bg.color == null ? null : bg, 'content', {
      radius: f.borderRadius.topLeft,
    });
    // It states no shadow of its own, so it takes the cast a style contributes
    // on both platforms — `resolveInjectedCast` around the band on Flutter,
    // `kControlShadowRestMarker` on Web — the one `OutlinedContainer` hands a
    // surface at rest, restated because the one-sided border keeps both from
    // composing that primitive.
    addControlShadow(c, lk);
    c.counterAxisAlignItems = 'CENTER';
    // `CoreBannerStyle.minHeight` — the same floor Alert states, and bound
    // for the same reason: the drawn height was a consequence of the
    // content, not of the value the widget enforces.
    c.minHeight = dimVal(f.minHeight);
    c.setBoundVariable('minHeight', lk.spaceLadder(dimVal(f.minHeight)));
    // The widget spans its parent (`banner.dart`: "Renders a full-width
    // banner") and `CoreBannerStyle` states no width, so the extent a Figma
    // frame has to have is the canvas's own decision.
    // g7-preview-only: Banner preview width, no width field in the code
    lockWidth(c, 480);
    c.appendChild(
      makeIcon(
        bannerGlyph(name),
        lk,
        glyphOpts(lk, icon, f.iconStyle.size, 'size'),
      ),
    );
    // `body` — the message column and the trailing group, wrapping. Both
    // widgets put the leading icon outside this box and let only these two
    // wrap, so a wrapped trailing line starts where the message TEXT starts
    // (after the icon), not at the band's edge. The row gap here is the
    // content-to-trailing gap the widgets put between the two on one line
    // (`iconContentGapStyle` when an action is shown); the wrapped line's
    // distance is `trailingRunSpacing`.
    const body = autoFrame('body', 'HORIZONTAL');
    body.layoutWrap = 'WRAP';
    body.counterAxisAlignItems = 'CENTER';
    body.clipsContent = false;
    bindSpaceField(body, 'itemSpacing', lk, dimVal(f.iconContentGapStyle.size));
    bindSpaceField(body, 'counterAxisSpacing', lk, dimVal(f.trailingRunSpacing));
    c.appendChild(body);
    body.layoutSizingHorizontal = 'FILL';
    const content = autoFrame('content', 'VERTICAL');
    // Nothing here clips: a focus ring on the action or the dismiss reaches
    // past its own box, and the column has nothing to hide.
    content.clipsContent = false;
    content.setBoundVariable('itemSpacing', lk.space(dimVal(f.titleDescriptionGapStyle.size)));
    // FILL is a value auto-layout computes from the PARENT, so the column
    // goes into the row and takes its FILL before anything inside it asks
    // for one. The other order — FILL text inside a column that was still
    // hugging — measures 0 wide.
    //
    // Ordering was not the whole of it. `neutral` kept collapsing after
    // this was fixed, and only `neutral`: its message came back EMPTY from
    // a table keyed under the axis's old name, and an empty FILLing text
    // measures zero for a reason no ordering can repair. Both causes make
    // the same 0×N text, which is why the first fix looked complete —
    // see `bannerMessage`.
    body.appendChild(content);
    content.layoutSizingHorizontal = 'FILL';
    // `contentMinWidth` — the message keeps this much width beside the
    // trailing group; below it the trailing group wraps to its own line.
    bindLayoutBound(content, lk, 'minWidth', dimVal(f.contentMinWidth));
    const msg = makeLabel(bannerMessage(name), lk, textLabelOpts(lk, titleStyle, text));
    content.appendChild(msg);
    msg.layoutSizingHorizontal = 'FILL';
    messageNodes.push(msg);
    // The description has its own colour — every `weak` row steps it down
    // to `onSurfaceVariant` while the message keeps the tone's foreground.
    const descColor = colorData(v.descriptionColor);
    const desc = makeLabel(_kBannerDesc, lk, textLabelOpts(lk, descStyle, descColor));
    content.appendChild(desc);
    desc.layoutSizingHorizontal = 'FILL';
    descriptionNodes.push(desc);
    // `[action, Gap(contentDismissGapStyle), dismiss]` — the widget's two
    // trailing branches in its own order. The region exists so that gap has a
    // frame to be the `itemSpacing` of: the row's own gap is
    // `iconContentGapStyle` (the `Gap` the widget puts BEFORE the action) and
    // Figma gives one gap per frame. With no region the dismiss button was not
    // drawn at all and `contentDismissGapStyle` reached nothing.
    //
    // The one pose this collapses: with `Show action` off, the widget's
    // remaining gap before the dismiss is `contentDismissGapStyle`, and the row
    // still spends `iconContentGapStyle` there. 12 against 8, on a pose a
    // designer reaches by turning a boolean off.
    const trailingRegion = panel('trailing', 'HORIZONTAL', lk, {
      gap: f.contentDismissGapStyle.size,
    });
    trailingRegion.counterAxisAlignItems = 'CENTER';
    trailingRegion.clipsContent = false;
    body.appendChild(trailingRegion);
    const actionHolder = slotHolder('action');
    actionHolder.clipsContent = false;
    trailingRegion.appendChild(actionHolder);
    const action = instanceOf(page, 'Button', actionVariant);
    actionHolder.appendChild(action);
    // A `plain` action's inline inset (`plainActionButtonStyle`) is the
    // instance's own box, not a nested paint, so it is written here — before
    // the loose fingerprint — and the swap bind below keeps it. Any other
    // variant keeps the member's own inset.
    if (actionPadding != null) bindPad(action, lk, actionPadding);
    // The label wears the banner's own foreground, which is what both
    // resolvers now inject into `actionButtonStyle` before forwarding it
    // to the action. Left to the variant it arrives as, the label keeps
    // `plain`'s colour — picked for a light neutral surface — so on a
    // solid banner it read as a dark grey word on a saturated fill while
    // the message, description, glyph and dismiss all tracked the tone.
    actionHolders.push(actionHolder);
    actionNodes.push(action);
    // The label's colour lands AFTER the swap property is bound (the pass
    // below), not here. `bindSwapProp` makes this node an INSTANCE_SWAP
    // target, and at bind time Figma re-applies the property's own main —
    // discarding a nested fill written before it. Painted here it was
    // silently dropped on all ten members, which read on the canvas as "the
    // action label ignores the variant" long after the resolvers had started
    // injecting it.
    actionForegrounds.push({ node: action, color: text, band: rowOutline });
    // `Button(variant: .plain, buttonStyle: resolved.closeButtonStyle, child:
    // Icon(LucideIcons.x, iconStyle: resolved.closeButtonStyle.leadingIconStyle))`
    // — the same forwarded-slot composition chip's close affordance is, reading
    // the same three values off the slot (inset, corner, glyph size). The widget
    // names no size, so Button's own default (`md`) applies.
    const dismissHolder = slotHolder('dismiss');
    dismissHolder.clipsContent = false;
    trailingRegion.appendChild(dismissHolder);
    dismissHolder.appendChild(
      iconButton(page, lk, {
        name: 'dismiss',
        variant: 'plain',
        size: 'md',
        glyph: 'x',
        glyphSize: iconShapeGlyphSize('md', f.closeButtonStyle),
        // The glyph inherits `Button`'s per-state foreground, and both
        // resolvers build that foreground from the variant's ICON colour at
        // full strength, resting and hovered alike (`banner_style.dart`, and
        // the Web twin says it the same way).
        //
        // It once passed `text` — the variant's TEXT colour, which is
        // `on-surface` on every row while `iconColor` is the variant's own hue
        // (`info` / `success` / `warning` / `error`) — so the ✕ landed the
        // wrong colour. The tone outright, and not tone times an alpha: a
        // colour scaled by an opacity resolves against whatever panel is
        // behind it, so its contrast cannot be checked. That is why the two
        // multipliers this used to name are gone rather than retuned.
        glyphColor: colorData(optField<Color>(v, 'iconColor')),
        // Both widgets compose the dismiss with `shape: .square` — the size
        // row's height on both axes and the shape's zero inset — and the
        // slot's full corner makes that square a circle. On the rectangle
        // shape the 4 inset drew the wash as a 28 × 40 pill.
        shape: 'square',
        radius: f.closeButtonStyle.borderRadius.topLeft,
        focusOutlineStyle: rowOutline,
      }),
    );
    dismissHolders.push(dismissHolder);
  }
  const set = mount.finish();
  vStackSet(set);
  // #4099 — 렌더되는 슬롯만, 발명 없음: `message`(required 텍스트 콘텐츠) 는
  // TEXT, `action`(optional 위젯 유무) 은 BOOLEAN + INSTANCE_SWAP 쌍,
  // `onDismiss`(콜백 유무) 는 BOOLEAN 하나.
  // `description` 은 `W?` 라 TEXT + BOOLEAN(`Show description`) 쌍이다 —
  // "별도 렌더 노드가 없어 property 없음"은 이 빌더에는 해당되지 않는다: 위
  // content 열이 그 줄을 실제로 그리고, 위젯은 `description == null` 일 때
  // 그 줄과 그 위 gap 을 같이 뺀다.
  //
  // `Message` is a required `W` slot, so it gets a property even though a
  // TEXT property's default is set-wide while each variant carries its OWN
  // copy (`_kBannerMsg`: a general notice, an info line, a success line, …).
  // What that costs is exactly one thing: a placed INSTANCE starts from the
  // one default below rather than from its variant's line. The variants on
  // this page keep their own characters — the strings above are still what
  // each one is built with — and the tone axis was never carried by the copy
  // alone anyway (icon, fill, border and text colour all move with it).
  //
  // Leaving it unbound was the other trade, and it is the worse one: with no
  // property the panel does not say `message` is a slot at all, so the line
  // reads as this component's fixed wording rather than as the caller's
  // widget. Figma has no per-variant property default; that is the limit
  // being paid here, not a claim that the copy does not differ.
  // The default is the code's default variant's line, read through the
  // throwing lookup: indexing the map with a stale key (`default_`, from
  // before the axis member was renamed `neutral`) handed `defineProp` an
  // undefined default, and the file kept whatever English it held before.
  const messageProp = defineProp(set, 'Message', 'TEXT', bannerMessage(BANNER.axes.variant.default));
  for (const n of messageNodes) bindTextProp(n, messageProp);
  const descProp = defineProp(set, 'Description', 'TEXT', _kBannerDesc);
  for (const n of descriptionNodes) bindTextProp(n, descProp);
  // `description` is `W?`, and both widgets drop the node AND the
  // `titleDescriptionGapStyle` gap in one `if (description != null)` branch
  // (`banner.dart`, Flutter and Web alike). The canvas twin needs no second
  // node for that: `content` is an auto-layout column whose `itemSpacing` IS
  // that gap, and auto-layout skips a hidden child entirely — so the BOOLEAN
  // on the TEXT node alone collapses the line and the gap together. On by
  // default because that is the pose the field describes, like `Show action`
  // and `Show dismiss` below. Defined by name so the designer's existing
  // property keeps its id — `defineProp` reuses a same-name, same-type
  // definition rather than adding a second one.
  const showDescProp = defineProp(set, 'Show description', 'BOOLEAN', true);
  for (const n of descriptionNodes) bindVisibleProp(n, showDescProp);
  // `action` is `W?`: the swap says what may fill it, the boolean says whether
  // it is filled at all. Two nodes — see the header note on why an instance
  // slot gets a holder.
  const actionProp = defineProp(
    set,
    'Action',
    'INSTANCE_SWAP',
    mainIdOf(page, 'Button', actionVariant),
  );
  for (const n of actionNodes) bindSwapProp(n, actionProp);
  // The variant the bind lands is the property's DEFAULT, which `defineProp`
  // may have kept from an earlier run (see `actionPaddingFor`). It is read off
  // the definition and matched to a Button member by id — not off the bound
  // instance's `mainComponent`, which is unreadable under
  // `documentAccess: "dynamic-page"` (the canvas threw on it, and the whole
  // Banner entry failed).
  const landedDefault = actionProp != null ? set.componentPropertyDefinitions[actionProp]?.defaultValue : undefined;
  const buttonSet = findComponentByName(page, 'Button');
  const landedVariant =
    typeof landedDefault === 'string' && buttonSet?.type === 'COMPONENT_SET'
      ? (buttonSet.children.find((c) => c.id === landedDefault)?.name ?? actionVariant)
      : actionVariant;
  const landedPadding = actionPaddingFor(landedVariant ?? undefined);
  // Now that the swap owns these nodes, tint their labels: the widget's
  // resolvers inject the variant foreground into `actionButtonStyle` before
  // forwarding it to the action, and without this the canvas showed
  // `plain`'s own label colour — chosen for a light neutral surface — on
  // saturated and dark fills alike.
  //
  // "Now that" is the bind LANDING, not the line above it. The set's members
  // are drawn loose and put back into it after the builder returns, and the
  // property references are written then (`identity.ts`, `recordPropRef`): a
  // write on the line below `bindSwapProp` runs BEFORE the bind. The label
  // paint sat there since September and was discarded by the bind when the
  // members were reassembled — all ten members came back with the plain
  // button's own `on-surface-variant` label (#6028), and no drill read it.
  // `afterNodeBindLands` runs it once the reference is written, and at once
  // when the set was never deferred.
  for (const entry of actionForegrounds) {
    afterNodeBindLands(entry.node, (action) => {
      const button = action as InstanceNode;
      // The inset again, in case the bind re-applied the main's own box: the
      // same value as before the bind, so where the bind kept it this writes
      // nothing new.
      applyForwardedButtonStyle(button, lk, {
        foregroundColor: entry.color,
        ...(landedPadding != null ? { padding: landedPadding } : {}),
      });
      // The row's band, in the same post-bind pass and for the same reason: a
      // nested paint written before the swap was bound is discarded with it.
      if (entry.band != null) forwardFocusBand(button, lk, entry.band);
    });
  }
  const actionShownProp = defineProp(set, 'Show action', 'BOOLEAN', true);
  for (const n of actionHolders) bindVisibleProp(n, actionShownProp);
  // `onDismiss` is a callback, not a `W?` slot, so there is nothing to swap —
  // the affordance is either drawn or it is not, which is one BOOLEAN. Drawn by
  // default, like `action` above and for the same reason: it is the pose the
  // field describes, and a banner whose dismiss button is off by default shows
  // neither the button nor the gap that positions it.
  const dismissShownProp = defineProp(set, 'Show dismiss', 'BOOLEAN', true);
  for (const n of dismissHolders) bindVisibleProp(n, dismissShownProp);
  return set;
}

// ─── Chip ────────────────────────────────────────────────────────────────────

// Data-driven from coui_core: CHIP.variants.defaultsByColor ×
// CHIP.sizes.defaultsBySize × CHIP.variants.defaultsByShape × the poses
// declared below.
//
// ─── The seven axes ──────────────────────────────────────────────────────────
//
// Two axes carry what the widget calls a colour and a look, and the canvas
// spells each the way the code does (`chipColor` ↔ `Color`, `variant` ↔
// `Variant`):
//
//   `Color`   — `CoreChipColor`: the colour a SELECTED chip takes on. It sits
//               under `axes.other` (the exporter records a colour enum and
//               does not promote it), so the member list comes from the table
//               that is keyed by it, `defaultsByColor` — `neutral` and
//               `primary`. `custom` has no row in the table and no member here:
//               its fill and border come from a caller-supplied `seedColor`,
//               and the only canvas stand-in would be a seed this file
//               invented (see `_kChipCustomSeed`).
//   `Variant` — `CoreChipVariant`: how an UNSELECTED chip is drawn, `outlined`
//               or `filled`. This one IS promoted (`axes.variant`), so its
//               members and its default are read off the schema, not spelled
//               here. It never reaches a selected or a disabled chip, and an
//               unselected chip names no colour either, so the `Color` axis
//               does nothing to an unselected member — the members stay
//               separate because they are separate props.
//
// `Selected` and `Emphasis` are the resolver's other two inputs
// (`chip_style.dart` `resolveChip(chipColor:, variant:, size:, selected:,
// emphasis:, enabled:, shape:)`): `selected` picks the filled row, `emphasis` picks
// between the loud and the quiet fill of that row. They are design axes, not
// poses: the widget takes them as constructor arguments and holds them until
// the caller changes them.
//
// `Shape` — `CoreChipShape`: the outline, `rounded` (the default, the size
// row's corner) or `pill` (both ends half a circle). Also under `axes.other`
// and read off the schema; the corner each value draws is its row in
// `defaultsByShape`, merged over the size row the way `resolveChip` merges it.
// It moves the corner and nothing else — the face, the wash and the focus ring
// follow it, the close button keeps its size row's.
//
// `State` is declared here the way `Button` declares its own — `axes.state` is
// null because a chip's states are not a Core enum the exporter could carry,
// they are `_PressableChipState`'s flags. Its values are the rungs of the
// widget's own select (`chip.dart`, `_PressableChipState.build`):
//
//   disabled → pressed → focus → hover → resting
//
// Read top-down, strongest wins: `!enabled` gates first and `containerStyle`
// is already the disabled chrome by then, so `Selected` / `Emphasis` do not
// reach a disabled member. `Enabled` is folded into `State` exactly as Button
// folds it — `axisValueOf` reads `State=disabled` as `Enabled=false` for G10.
//
// ─── What each rung paints (`chip_style.dart`) ───────────────────────────────
//
// The base colour is the table branch, in the resolver's own precedence:
// disabled → `disabledBg` / `disabledFg` / `disabledBorderColor`, whatever
// `selected`, `emphasis` or `variant` say; selected → `lowSelectedBg` /
// `lowSelectedFg` at `low`, `selectedBg` / `selectedFg` at `high`, border =
// that fill (Web parity: `border-${selectedBg}`); unselected → at
// `outlined` the row's `unselectedBg` (the `.transparent` sentinel on every
// row) with, at `low`, the row's `lowUnselectedFg` and the border authored
// ONCE on the style (`lowUnselectedBorderColor`), and the row's
// `unselectedFg` / `borderColor` at `high`. A resting chip states no colour,
// so those four columns read the same in every row. At `filled` the fill is
// the style's one grey (`filledUnselectedBackgroundColor`) and the border
// mirrors it — the way a selected chip's border mirrors its own fill — while
// the label stays the emphasis's neutral.
//
// Over that base, `washedFill(weight)` composites the resolved foreground at
// `stateLayer.hover` / `.focus` / `.pressed` — premultiplied over the base, so
// a chip with no fill of its own washes toward its own ink. The canvas form of
// that is a foreground-filled rectangle at the weight's opacity over the base
// fill (the same node `Button` draws). The border stays the base border.
//
// `State=focus` additionally wears the `Clickable` ring — the widget composes
// `Clickable(clickableStyle: resolved.clickableStyle)` only when `onTap !=
// null`, so a non-tappable chip never focuses; the member is still the honest
// rendering of the focusable one. The ring's geometry is the slot's
// `focusOutlineStyle` and its corner is the chip's own face corner — the size
// row's `borderRadius` (6 / 8 / 10) on a `rounded` chip, the full rung on a
// `pill` — which both resolvers put into the slot ahead of the caller's
// `clickableStyle`, so the ring sits `align` outside it.
//
// Not modelled: pressed on Flutter also hides the injected cast and translates
// by `pressedTranslate` under a style that publishes a cast. The canvas draws
// only the wash, the same limitation `Button` accepted.
//
// Border is always drawn (`Border.all(color: resolved.borderColor, …)`), and its
// colour is the third value each branch picks.
//
// The leading slot is an Icon INSTANCE. It used to be a `'•'` text character
// sized by `leadingIconStyle` — a font-dependent shape a designer could not
// swap, because a character is not an instance.
//
// `trailing` is the third composition slot and renders on the same terms as
// `leading` — `IconTheme(size: trailingIconSize, color: trailingIconColor,
// child: trailing!)`, between the label and the close affordance. It starts
// hidden because the widget's own default is `trailing: null`, so the two
// icon slots between them show both poses: `leading` what a filled slot looks
// like, `trailing` what an empty one does.
//
// `child` is the label node. The widget renders `child ?? Text(label)` into
// that one position, and the TEXT property is named for the slot rather than
// for the String field so the panel and the contract agree on what it is.
//
// The close affordance is an INSTANCE of `Button`, not a drawn `✕` box:
// `chip.dart` builds it as `Button(variant: .ghost, size: .sm, buttonStyle:
// resolved.closeButtonStyle, child: Icon(LucideIcons.x, iconStyle:
// resolved.closeIconStyle))`, and `CoreChipStyle.closeButtonStyle` is that
// forwarded slot — so BOTH values it carries land on the instance (padding and
// radius) and the glyph is the real `x` at `closeIconStyle.size`.
//
// The padding is the one that was missing, and being an instance is what made it
// invisible: a `Button` instance arrives already carrying its own size-row inset,
// so a forwarded value that never gets written does not leave a hole — it leaves
// the CHILD's number in place, which looks like a deliberate 24-wide affordance
// rather than a dropped override. `defaultCloseButtonStyle` is
// `CoreButtonStyle(padding: .zero)`; the whole point of the slot is that the
// button collapses onto the glyph.
//
// It exists only on the enabled rungs, because the widget's condition is
// `onRemove != null && enabled`: a disabled chip renders no close button at
// all, whatever `onRemove` is. That is why the BOOLEAN property below does
// nothing on `State=disabled` — there is no node there to show, which is the
// API being honest rather than the axis being noisy.
//
// This node IS the `Clickable` when `onTap != null`: it owns tap / keyboard /
// cursor / focus-ring wiring, and the one piece of chrome it draws — the ring —
// hangs off this root on `State=focus`. There is no second node for it, for
// the reason `Button` records: a wrapper whose entire job is to hold the chip
// has no content of its own to instantiate around.
const _kChipLeadingGlyph = 'tag';
const _kChipTrailingGlyph = 'chevron-down';
const _kChipLabel = '디자인';
// The key a filter chip names ahead of its value ("필터" before "전체").
const _kChipPrefixLabel = '필터';

// The select's rungs in the order a designer reads them (`chip.dart`,
// `_PressableChipState.build`: `!enabled` → `_pressed` → `_focused` →
// `_hovered` → rest). `disabled` last for the reason Button puts it last: it
// is where the ladder starts, and the one nobody clicks through looking for.
// No `selected` rung — on a chip that is an axis the resolver takes as input,
// not a state it lands on.
// No `focus` rung: the ring is `Show focus ring`'s pose, and a rung that
// drew the same picture behind a second name was the 78-member duplicate
// the canvas shed. Focus is a property, not a state.
const kChipStates = stateAxis(['enabled', 'hover', 'pressed', 'disabled']);

type ChipState = (typeof kChipStates)[number];

// The caller's `seedColor`, standing in — not a Core default, and there is no
// field for it to come from: `seedColor` is a constructor argument like the
// label string, and `CoreChipColor.custom` is precisely the column whose
// selected pose takes its fill and border from it (an unselected chip states
// no colour, so a resting custom chip is the neutral chip). `primary` because
// a seed is a brand colour and a token keeps the swatch following the theme; a
// literal would freeze this column at one hue in both light and dark.
//
// What Core DOES state for this column is the four `custom*` fields below, and
// none of them had a node before: the colour axis was built from
// `defaultsByColor`, which has no `custom` row — the whole point of the member
// is that its colours are computed rather than tabulated.
//
// It still has no node, and the reason is the seed rather than the axis: the
// colour enum IS drawn as `Color` now, but `custom` is the one member of it
// whose colours are computed from a constructor argument rather than
// tabulated, and minting a hundred-odd members on a seed this file made up
// would put a hue on the canvas no widget renders. `chipCustomColors` below is
// kept as the resolver branch those four fields belong to; it is deliberately
// not wired to a `Variant=custom` column.
const _kChipCustomSeed: ColorData = { color: 'primary' };

// One colour column of the Chip set: its name, and the three colours its state
// pair resolves to — the shape both `chip*Colors` branches below satisfy.
//
// Nothing consumes it: the tabulated columns read `chipTableColors`
// directly off their `defaultsByColor` row, and the one column that would
// need this seam — `custom` — has no member (see `_kChipCustomSeed`). Kept
// beside the two branches it describes, so giving `custom` a column is one
// loop rather than a re-derivation of what a column is.
interface ChipColumn {
  readonly name: string;
  readonly colors: (
    selected: boolean,
    disabled: boolean,
  ) => {
    readonly bg: ColorData | null;
    readonly fg: ColorData | null;
    readonly border: ColorData | null;
  };
}

// The same resolver's `chipColor == .custom && seedColor != null && (selected ||
// !enabled)` branch, in the same precedence order. Disabled drops the seed
// entirely for the `customDisabled*` tokens; selected fills and borders with the
// seed and puts `customSelectedForegroundColor` on the label. An enabled
// unselected chip is not in this branch: it states no colour, so it reads the
// neutral table row (`chipTableColors`) and this returns null for it.
function chipCustomColors(
  selected: boolean,
  disabled: boolean,
): { bg: ColorData | null; fg: ColorData | null; border: ColorData | null } | null {
  const f = CHIP.fields;
  if (disabled) {
    // Two rows, like the table branch: the selected chip keeps a filled
    // container with no border (the shared `disabledSelectedBorderColor`),
    // the unselected one sits on the surface behind a hairline.
    if (selected) {
      return {
        bg: colorData(f.customDisabledBackgroundColor),
        fg: colorData(f.customDisabledForegroundColor),
        border: colorData(f.disabledSelectedBorderColor),
      };
    }
    return {
      bg: colorData(f.customDisabledUnselectedBackgroundColor),
      fg: colorData(f.customDisabledForegroundColor),
      border: colorData(f.customDisabledBorderColor),
    };
  }
  if (!selected) return null;
  return {
    bg: _kChipCustomSeed,
    fg: colorData(f.customSelectedForegroundColor),
    border: _kChipCustomSeed,
  };
}

interface ChipSlots {
  label: TextNode;
  prefixLabel: TextNode;
  leadingHolder: FrameNode;
  leading: InstanceNode;
  trailingHolder: FrameNode;
  trailing: InstanceNode;
  /** Null on the disabled rung — the widget draws no close affordance there. */
  close: FrameNode | null;
  ring: FocusRingNodes;
}

// `async` for the reason `buildButton` is: 384 members is one of the largest
// sets in the plugin, and a synchronous loop that long freezes the plugin UI
// and Figma itself with nothing to tell "still working" from "hung". Every
// caller already `await`s `RegistryEntry.build()`.
async function buildChip(page: PageNode, lk: VarLookup): Promise<ComponentSetNode> {
  // The colours, as a `Color` axis; the unselected look, as a `Variant` axis.
  //
  // `CoreChipColor` is recorded in `axes.other` and not promoted, so the axis'
  // members are the keys of the table that is keyed by it — a chip colour with
  // no row (`custom`) has no member, for the reason `_kChipCustomSeed` gives.
  // Every comparable set draws its unpromoted colour enum as an axis (`Status`
  // as `Variant`, `Dock` / `Fab` / `ValidationBadge` / `DescriptionCard` each
  // their own; an enum that says what a colour MEANS — `CoreBadgeTone`,
  // `CoreProgressTone` — is the `Tone` axis); Chip's is named `Color` because
  // the name `Variant` is taken by the contract's own `variant`
  // (`CoreChipVariant`).
  //
  // The colours still come through the resolver's own table branch rather than
  // being read field-by-field here, so the precedence the widget applies is the
  // precedence the canvas shows.
  const colourData = new Map(Object.entries(CHIP.variants.defaultsByColor));
  // Promoted by the exporter, so the schema is the only place the two looks
  // are spelled — a third value added to `CoreChipVariant` lands on the canvas
  // without touching this file. The default is the schema's too: it is the
  // member the unselected `Color` columns collapse onto in `renames.ts`.
  const shape = CHIP.axes.variant;
  if (!shape) throw new Error('Chip: `CoreChipVariant` is not `chip.axes.variant`');
  // Loud on a value this builder draws no look for: a third shape added to the
  // enum would otherwise be drawn as one of the two and never reported.
  for (const m of shape.members) {
    if (m !== shape.default && m !== 'filled') {
      throw new Error(`Chip: \`Variant=${m}\` has no look in buildChip — draw it, or hide it in the enum`);
    }
  }
  const sizeData = new Map(Object.entries(CHIP.sizes.defaultsBySize));
  // `Emphasis` is read off the schema rather than spelled here so a value added
  // to `CoreChipEmphasis` lands on the canvas without touching this file;
  // `Selected` is the boolean the widget takes, spelled the way every other
  // boolean axis is (`restingValueOf` rests at `'false'`).
  const emphasis = CHIP.axes.other.find((o) => o.enum === 'CoreChipEmphasis');
  if (!emphasis) throw new Error('Chip: `CoreChipEmphasis` is not in `chip.axes.other`');
  // The outline — `CoreChipShape` (rounded | pill), a contract parameter the
  // widget takes beside `size`. Not to be confused with `shape` above, which is
  // `CoreChipVariant` (how an unselected chip is drawn). Read off the schema
  // like `Emphasis`, and every member has to have a row in `defaultsByShape`:
  // the row is what the shape changes, so a member without one would be drawn
  // as whichever corner the size row happens to state and never reported.
  const chipShape = CHIP.axes.other.find((o) => o.enum === 'CoreChipShape');
  if (!chipShape) throw new Error('Chip: `CoreChipShape` is not in `chip.axes.other`');
  const shapeRows = new Map<string, object>(Object.entries(CHIP.variants.defaultsByShape));
  for (const m of chipShape.members) {
    if (!shapeRows.has(m)) {
      throw new Error(`Chip: \`Shape=${m}\` has no row in \`defaultsByShape\` — state one in Core`);
    }
  }
  // `State` is declared here, not derived from `axes` — see the note above the
  // ladder. `Enabled` is dropped exactly as Button drops it: `State=disabled`
  // says everything it would have said.
  // The full matrix — 2 × 2 × 3 × 4 × 2 × 2 × 2 = 384, nothing collapsed. A
  // resting chip states no colour, so the `primary` members of an unselected
  // row repeat `neutral`'s picture on purpose — the colour is the look a chip
  // takes on when selected — and a selected or disabled chip ignores `Variant`
  // the same way. The members stay separate because they are separate props.
  // Disabled is two rows (selected keeps a fill), so no disabled member is
  // another's picture within a `Variant`. `Shape` changes only the corner, so
  // a `pill` member is its `rounded` twin with both ends half a circle. `Size`
  // is declared here rather than read from `axisSpecsOf`: the contract's size
  // is `CoreChipSize`, its own three-tier enum, which the schema files under
  // `other` and the enumerator does not promote — the keys of `defaultsBySize`
  // ARE the axis. `Shape` sits last because `kAxisOrder` puts it after
  // `Emphasis`, and a member's name is its identity.
  const members = enumerateAxisAssignments([
    { axis: 'Color', values: [...colourData.keys()] },
    { axis: 'Variant', values: shape.members },
    { axis: 'Size', values: [...sizeData.keys()] },
    { axis: 'State', values: [...kChipStates] },
    { axis: 'Selected', values: ['false', 'true'] },
    { axis: 'Emphasis', values: emphasis.members },
    { axis: 'Shape', values: chipShape.members },
  ]);
  const mount = mountSet(page, 'Chip', members.map((m) => m.name));
  // The label a size row draws: the row's ROLE (`labelSmall` / `labelMedium` /
  // `labelLarge` — the 12 / 13 / 14 ladder stated as roles, so each rung's
  // tracking arrives with its size) at the semi-bold weight every row states,
  // over the field default (`labelMedium` at that same weight — the md row's
  // own) — the same `defaultLabelStyle.merge(row.labelStyle)` both resolvers
  // compose, in the shape `toggleLabelStyle` already has. A row's role still
  // fills every metric from the scale (`textStyleData`), so the merge IS the
  // row; the fall-through is for a row that one day states less. The size is
  // always the role's, never a `fontSize` scalar read off the row: that overlay
  // is what the size-ladder rule forbids, because it carries one role's
  // tracking to every size.
  const labelBase = textStyleData(CHIP.fields.labelStyle);
  const chipLabelStyle = (
    row: Parameters<typeof textStyleData>[0],
  ): ReturnType<typeof textStyleData> => {
    const size = textStyleData(row);
    return {
      fontSize: size.fontSize ?? labelBase.fontSize,
      fontWeight: size.fontWeight ?? labelBase.fontWeight,
      lineHeight: size.lineHeight ?? labelBase.lineHeight,
      color: size.color ?? labelBase.color,
      role: size.role ?? labelBase.role,
      letterSpacing: size.letterSpacing ?? labelBase.letterSpacing,
    };
  };
  // The key's base role (`labelSmall`, the `md` row's own) — each row states
  // its key one role under its label and at the role's own weight, so the
  // merge below is the row's role whenever the row states one.
  const prefixLabelBase = textStyleData(CHIP.fields.prefixLabelStyle);
  const slots: ChipSlots[] = [];
  for (let index = 0; index < members.length; index++) {
    const { name: comboName, values } = members[index];
    // Reported/yielded BEFORE the member it names is built, so the label reads
    // as live rather than one step stale (same shape as `buildButton`).
    await reportSubProgressAndYield(index, members.length);
    const sz = sizeData.get(values.Size);
    if (!sz) throw new Error(`Chip: no size data for combo "${comboName}"`);
    const colour = colourData.get(values.Color);
    if (!colour) throw new Error(`Chip: no colour row for combo "${comboName}"`);
    const shapeRow = shapeRows.get(values.Shape);
    if (!shapeRow) throw new Error(`Chip: no shape row for combo "${comboName}"`);
    // The corner — the shape's row over the size's, the order `resolveChip`
    // merges them in on both platforms (`defaultsBySize[size]`, then
    // `defaultsByShape[shape]`). `rounded` states nothing, so the size row's
    // own corner stands (6 / 8 / 10 — the chip's height × 0.25 on a
    // `CoreRadius` rung); `pill` states the full rung, which every renderer
    // clamps to half the drawn height, so both ends are a half circle at any
    // size. The canvas states no override, so the source the resolvers read
    // first (`borderRadius` on the theme or the instance) has nothing to
    // contribute here. The face, the wash and the focus ring all follow it.
    const corner = optField<{ topLeft: Dim }>(shapeRow, 'borderRadius')?.topLeft ?? sz.borderRadius.topLeft;
    const state = values.State as ChipState;
    const disabled = state === 'disabled';
    const selected = values.Selected === 'true';
    const { bg, fg, border } = chipTableColors(
      colour,
      selected,
      disabled,
      values.Emphasis as ChipEmphasis,
      // The one member of `Variant` that draws anything other than the
      // outlined look (the schema's default, which needs no spelling here).
      values.Variant === 'filled',
    );
    const c = mount.getOrCreate(comboName);
    applyPanelCompChrome(c, 'HORIZONTAL', lk, {
      // The shape's corner over the size row's (see `corner` above); both
      // resolvers read it through `merged.borderRadius`. A `rounded` chip has
      // no size-independent corner; a `pill` binds the full rung, which no
      // size or density moves.
      radius: corner,
      pl: sz.padding.l, pr: sz.padding.r, pt: sz.padding.t, pb: sz.padding.b,
      gap: sz.iconLabelGapStyle.size,
    });
    c.counterAxisAlignItems = 'CENTER';
    // Where the content row sits when the chip is drawn wider than it — both
    // resolvers read `merged.contentAlignment ?? defaultContentAlignment`
    // (Flutter `Row.mainAxisAlignment`, Web `justify-*`). A hugging member has
    // no free space, so this only shows on an instance a caller widens.
    c.primaryAxisAlignItems = mainAxisOf(CHIP.fields.contentAlignment, 'chip.contentAlignment');
    // The size tier's floor — `resolveChip` states this so a chip matches
    // the control beside it rather than its own label; padding + icon +
    // label alone lands well under the ladder — the label role's line box is
    // 140%. Same shape as Banner's `minHeight`.
    c.minHeight = dimVal(sz.minHeight);
    c.setBoundVariable('minHeight', lk.spaceLadder(dimVal(sz.minHeight)));
    // Not via ChromeOpts.bg/border — a chip's background can be the
    // `.transparent` sentinel (ref: null, argb: 0), which only the
    // ColorData paths model; ChromeOpts takes a Semantic name.
    fillData(c, lk, bg);
    borderData(c, lk, border, CHIP.fields.borderWidth);
    // A chip states no cast, and both platforms give it the one a style
    // contributes unless its cast motion says otherwise: `noShadow` never
    // casts, the default hides the cast while the chip is engaged — hovered
    // or pressed — and `reverse` casts only then.
    const castMotion = CHIP.fields.castMotion.choice as string;
    const engaged = state === 'hover' || state === 'pressed';
    const castsHere = castMotion !== 'noShadow' && (castMotion === 'reverse' ? engaged : !engaged);
    if (castsHere) addControlShadow(c, lk);
    // Both glyph slots sit behind a BOOLEAN and NOT behind an INSTANCE_SWAP.
    // A swap property's default overrides the nested icon's own `Icon Size`,
    // so every tier would draw the swap's 24 glyph whatever step the row
    // states, and the glyph would walk into the label. Sizing the nested
    // `icon` instance per tier is the only path Figma leaves open (a nested
    // instance's variant is shared by the whole set); the glyph itself is
    // swapped one level in, the way `Icon` already works. Same for `trailing`
    // below.
    const leadingHolder = slotHolder('leading');
    c.appendChild(leadingHolder);
    const leading = makeIcon(
      _kChipLeadingGlyph,
      lk,
      glyphOpts(lk, fg, sz.leadingIconStyle.size, 'size'),
    );
    leadingHolder.appendChild(leading);
    leadingHolder.visible = false;
    // The key — `prefixLabel`, a `String?`, so one TEXT node carries both the
    // BOOLEAN (the null) and the TEXT (the words). Between the leading glyph
    // and the label, which is where `chipContent` puts it, and parted from the
    // label by the chip's own `iconLabelGapStyle` spacing, the gap the widget
    // sets between key and value. Its role is the row's over the field
    // default (`defaultPrefixLabelStyle.merge(row.prefixLabelStyle)` on both
    // platforms). Its colour is the one rule the key has of its own: a resting
    // chip draws it in the colour row's `unselectedPrefixFg`, and a selected
    // or disabled chip in that state's label colour.
    const prefixLabelStyle = mergeTextStyleData(
      prefixLabelBase,
      textStyleData(sz.prefixLabelStyle),
    );
    const prefixLabelColor = selected || disabled ? fg : colorData(colour.unselectedPrefixFg);
    const prefixLabel = makeLabel(
      _kChipPrefixLabel,
      lk,
      textLabelOpts(lk, prefixLabelStyle, prefixLabelColor),
    );
    prefixLabel.name = kChipPrefixLabelName;
    prefixLabel.visible = false;
    c.appendChild(prefixLabel);
    // The row's role over the field default — `chip_style.dart` merges the
    // same way (see `chipLabelStyle` above the loop).
    const labelStyle = chipLabelStyle(sz.labelStyle);
    const label = makeLabel(_kChipLabel, lk, textLabelOpts(lk, labelStyle, fg));
    c.appendChild(label);
    // Between label and close, which is where `chipContent` puts it.
    const trailingHolder = slotHolder('trailing');
    c.appendChild(trailingHolder);
    const trailing = makeIcon(
      _kChipTrailingGlyph,
      lk,
      glyphOpts(lk, fg, sz.trailingIconStyle.size, 'size'),
    );
    trailingHolder.appendChild(trailing);
    trailingHolder.visible = false;
    let close: FrameNode | null = null;
    if (!disabled) {
      close = iconButton(page, lk, {
        name: kChipCloseName,
        variant: 'ghost',
        size: 'sm',
        glyph: _kChipCloseGlyph,
        // Hugging, so a host that forwards a smaller close (`ChipInput`) can
        // restate it on its instance — see `forwardChipCloseBox`.
        hug: true,
        glyphSize: sz.closeIconStyle.size,
        // No explicit colour in the widget either — the glyph inherits
        // Button's per-state IconTheme, which the resolver binds to the
        // chip foreground. Passing `fg` is that same value.
        glyphColor: fg,
        // What `CoreChipStyle.defaultCloseButtonStyle` states
        // (`CoreButtonStyle(padding: .zero)`) with the size row's corner
        // folded over it, the way `chip_style.dart` merges them. The inset is
        // the one that moves pixels: it is what makes the affordance the
        // glyph's own width instead of Button's `sm` row (12 + 12). The corner
        // is forwarded only where a slot states one — the `sm` row does (6, so
        // the button stays inside the 6 corner of its chip); the flat slot and
        // the `md` / `lg` rows state none, and the instance keeps its own
        // size row's corner. `Shape` does not reach it (Core: the close
        // button keeps its size row's corner) — a pill is rounder than any of
        // them, so no button is rounder than the face around it.
        padding: CHIP.fields.closeButtonStyle.padding,
        radius:
          optField<{ topLeft: Dim }>(sz.closeButtonStyle, 'borderRadius')?.topLeft ??
          optField<{ topLeft: Dim }>(CHIP.fields.closeButtonStyle, 'borderRadius')?.topLeft,
        // The band under the ✕'s ring. A chip's own fill is a tone the ✕
        // cannot assume the page shares, so the slot states an opaque band.
        focusOutlineStyle: CHIP.fields.closeButtonStyle.focusOutlineStyle,
        // The per-SIZE box, from the row this loop already holds. The
        // resolver folds `defaultsBySize[size].closeButtonStyle` into the
        // style it forwards (`chip_style.dart`), and Core states a distinct
        // pair for each row — none of them null. Without these the fallback
        // computed the box from the glyph and `Button`'s own `sm` row
        // instead, so both axes diverged (md: 16×32 against the stated
        // 20×20).
        width: sz.closeButtonStyle.width,
        height: sz.closeButtonStyle.height,
      });
      c.appendChild(close);
    }
    // Read ONCE, after the last in-flow child: every read of a laid-out
    // property flushes the layout, and both overlays below want the same
    // box. Both are absolute, so neither moves the hug between here and there.
    //
    // Bracketed as `geom` for the reason Button's copy of this gives: the
    // flush is the one per-member cost that could scale with the document
    // rather than with the chip, and Chip is the most expensive entry in the
    // run — if the recycle-path penalty lives in a layout settle, it shows up
    // here first.
    const box = timedGeom(() => ({ width: c.width, height: c.height }));
    const compWidth = box.width;
    const compHeight = box.height;
    // `Clickable(clickableStyle: resolved.clickableStyle)` — the ring the chip
    // wears when the keyboard reaches it. Geometry from the slot's own
    // `focusOutlineStyle`; the corner is the one the face is drawn with (the
    // shape's over the size row's), which both resolvers write into the slot
    // ahead of the caller's `clickableStyle` — the slot's default states no
    // corner of its own, because the ring has to follow a corner that differs
    // per size and per shape. A pill's ring stays a pill (`derivedCorner`).
    //
    // Visible on `State=focus` and NOT bound there: a bound `visible` has one
    // source of truth — the property — and binding would hand the focus member
    // the default `false`. On the other four it stays a pose behind the BOOLEAN.
    const ring = focusRing(c, lk, {
      outline: CHIP.fields.clickableStyle.focusOutlineStyle,
      color: colorData(CHIP.fields.clickableStyle.focusOutlineStyle.borderColor),
      corner,
      width: compWidth,
      height: compHeight,
      // Never a rung's pose — `Show focus ring` is the only way it shows.
      visible: false,
    });
    // `washedFill(weight)` — the resolved foreground composited over the base
    // fill at the rung's weight, premultiplied so a transparent unselected chip
    // washes toward its own ink instead of toward the page. A foreground rect
    // at that opacity over the base is the same stacking. Rest and disabled
    // carry no wash (`_PressableChipState` only reaches the washed styles when
    // enabled, and rest IS `containerStyle`).
    //
    // Child 0, so it sits over the fill and under the label — the same
    // stacking `alphaBlend(fg@a, bg)` produces.
    const layerAlpha =
      state === 'pressed'
        ? CHIP.fields.stateLayer.pressed
        : state === 'hover'
          ? CHIP.fields.stateLayer.hover
          : null;
    if (layerAlpha != null) {
      const stateLayer = figma.createRectangle();
      stateLayer.name = 'state layer';
      stateLayer.resize(compWidth, compHeight);
      stateLayer.cornerRadius = dimVal(corner);
      // The resolved foreground — the ink the resolver blends. Its opacity is
      // the weight, so the token stays bound and follows the theme.
      fillData(stateLayer, lk, fg);
      stateLayer.opacity = layerAlpha;
      // `insertChild` first, then pin: `pinAbsolute` appends, so pinning and
      // then moving to index 0 reparents the same node twice.
      c.insertChild(0, stateLayer);
      pinInFlow(c, stateLayer);
      stateLayer.x = 0;
      stateLayer.y = 0;
      stateLayer.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };
    }
    slots.push({
      label,
      prefixLabel,
      leadingHolder,
      leading,
      trailingHolder,
      trailing,
      close,
      ring,
    });
  }
  // The last member's labels — no yield follows it, and after `finish()` the
  // attach would be a write on the set instead of on a loose node (same as
  // `buildButton`; `text-style-attach.ts`).
  await drainTextStyleAttach();
  const set = mount.finish();
  // No `layoutSet` override: at this many members a fixed-width wrap is a
  // hundred-odd rows tall, and `finish()` already applied `defaultSetLayout`,
  // whose square grid keeps the block readable whatever the count.
  //
  // A mark for the property pass, for the reason `buildButton` gives.
  markStep('Chip:props');
  const childProp = defineProp(set, 'Child', 'TEXT', _kChipLabel);
  // `prefixLabel == null` by default — a chip names only its value until a
  // caller gives it a key.
  const prefixLabelShownProp = defineProp(set, 'Show prefix label', 'BOOLEAN', false);
  const prefixLabelProp = defineProp(set, 'Prefix label', 'TEXT', _kChipPrefixLabel);
  const leadingShownProp = defineProp(set, 'Show leading', 'BOOLEAN', false);
  const trailingShownProp = defineProp(set, 'Show trailing', 'BOOLEAN', false);
  // `onClose == null` by default — a chip is a label, and the ✕ is the pose
  // a caller opts into. `true` put a close button on every chip on the
  // canvas, which no default chip in the code has.
  const closeProp = defineProp(set, 'Remove', 'BOOLEAN', false);
  const showFocusId = defineShowFocusRing(set);
  for (const s of slots) {
    bindTextProp(s.label, childProp);
    bindVisibleProp(s.prefixLabel, prefixLabelShownProp);
    bindTextProp(s.prefixLabel, prefixLabelProp);
    bindVisibleProp(s.leadingHolder, leadingShownProp);
    bindVisibleProp(s.trailingHolder, trailingShownProp);
    if (s.close) bindVisibleProp(s.close, closeProp);
    bindShowFocusRing(s.ring, showFocusId);
  }
  return set;
}

// ─── ChipGroup ───────────────────────────────────────────────────────────────

// CHIP_GROUP.fields drives every gap and both text styles: `titleHintGapStyle`
// (title ↔ hint), `titleGapStyle` (header ↔ chips), `itemSpacing` (chip ↔
// chip), `titleTextStyle` and `selectionHintTextStyle`. The header exists
// because `title` and `selectionHint` are the contract's two composition slots —
// without a node for each, neither could be declared as a property. It stacks
// the two, title over hint, the way both platforms do.
//
// The chips are INSTANCES of `Chip`. They used to be hand-drawn pills with
// their own invented chrome (`surface-container` fill, 9999 radius, 12/6
// padding, 14pt label) — none of which any `CoreChipGroupStyle` field decides,
// and none of which could follow a `Chip` change, because the content-hash skip
// leaves a parent alone whose own recipe did not move. `chipBuilder` is
// caller-supplied in code, so what the group draws is whatever chip the caller
// builds; the design system's answer to "a chip" is `Chip`.
//
// The scroll region is an INSTANCE of `FadeScroll`: `_buildScrollLayout` is
// literally `FadeScroll(direction: .horizontal, child: Row(chips))`. The region
// opens at the FadeScroll component's OWN viewport box and follows the card
// from there (#4826): the instance rides a STRETCH×STRETCH holder, and its
// extents are pinned in its own builder, so they follow the instance the way
// they follow the main. A viewport narrower than its content is the
// precondition for the widget existing at all, so the chips clipping at its
// edge is the behaviour, not a bug.
//
// The row is the scroll layout's `Row`, so it never wraps: one line of chips,
// and the region is as tall as that line — `FadeScroll`'s scroll view hugs its
// child on the cross axis. `rowSpacing` is the wrap layout's run gap and has
// nothing to reach here.
//
// The fade itself IS drawn, and by this builder rather than by the instance,
// because of where the two values live. `FadeScroll` leaves its own bands
// unpainted on purpose — `CoreFadeScrollStyle` has no colour field, the caller
// supplies `gradient` — and this is that caller: `fadeColor` and `fadeWidth` are
// `CoreChipGroupStyle`'s, forwarded in as `startOffset`/`endOffset` and the
// gradient's first stop. So nothing is duplicated; what is drawn here is the
// half the child does not own. It also has to be above the chip row, which
// itself rides above the instance (Figma refuses to append into one), or the
// instance's bands would sit under the chips where nothing can see them —
// and `FadeScroll` has no Direction axis, so those bands read vertical while
// this caller asks for horizontal.
const _kChipGroupTags = ['디자인', '개발', '기획', '리서치'];

// One edge fade, drawn as `FadeScroll` draws it: a mask over the scroll edge,
// not a band of colour laid on top of the chips. In Figma that is a frame
// holding an alpha MASK (a literal ramp, opaque at the outer edge and clear
// inward) and, above it, a fill bound to `fadeColor`. The fill shows only where
// the mask is opaque, so the chips come through as they come in.
//
// The ramp lives on the mask and not on the bound fill because a bound gradient
// stop takes its alpha from the Variable, not from the stop: a
// `[fadeColor, fadeColor @ 0]` gradient with both stops bound paints `fadeColor`
// at full strength across the whole band — a solid band that hides the chips.
// The mask's stops are literal (only their alpha is read), so they keep theirs.
//
// The start fade is drawn hidden: `FadeScroll` shows it only once the row has
// scrolled away from its start, and the canvas shows the row at rest.
function fadeBand(
  scroll: FrameNode,
  lk: VarLookup,
  cd: ColorData | null,
  side: 'start' | 'end',
  width: number,
): FrameNode {
  const band = figma.createFrame();
  band.name = `fade ${side}`;
  band.layoutMode = 'NONE';
  band.fills = [];
  band.clipsContent = true;
  scroll.appendChild(band);
  band.resize(width, scroll.height);
  const mask = figma.createRectangle();
  mask.name = 'fade mask';
  band.appendChild(mask);
  mask.resize(width, scroll.height);
  const stop = (position: number, a: number): ColorStop => ({
    position,
    color: { r: 0, g: 0, b: 0, a },
  });
  mask.fills = [
    {
      type: 'GRADIENT_LINEAR',
      gradientTransform: [
        [1, 0, 0],
        [0, 1, 0],
      ],
      gradientStops: side === 'start' ? [stop(0, 1), stop(1, 0)] : [stop(0, 0), stop(1, 1)],
      visible: true,
      opacity: 1,
      blendMode: 'NORMAL',
    },
  ];
  mask.isMask = true;
  mask.maskType = 'ALPHA';
  mask.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };
  const fill = figma.createRectangle();
  fill.name = 'fade fill';
  band.appendChild(fill);
  fill.resize(width, scroll.height);
  if (cd?.color != null) {
    fillSem(fill, lk, cd.color, cd.opacity == null ? 1 : cd.opacity);
  } else {
    fill.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 } }];
  }
  fill.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };
  band.visible = side === 'end';
  return band;
}

function buildChipGroup(page: PageNode, lk: VarLookup): ComponentNode {
  const f = CHIP_GROUP.fields;
  const c = mintPanelComp(page, 'ChipGroup', 'VERTICAL', lk, { gap: f.titleGapStyle.size });
  // The header is `[title, Gap(titleHintGapStyle), selectionHint]` in a
  // start-aligned column on both platforms.
  const head = panel('head', 'VERTICAL', lk, { gap: f.titleHintGapStyle.size });
  head.primaryAxisAlignItems = 'MIN';
  head.counterAxisAlignItems = 'MIN';
  const title = makeLabel('필터', lk, textLabelOpts(lk, textStyleData(f.titleTextStyle)));
  head.appendChild(title);
  const hint = makeLabel('최대 2개까지 고를 수 있어요', lk, textLabelOpts(lk, textStyleData(f.selectionHintTextStyle)));
  head.appendChild(hint);
  c.appendChild(head);
  // The header spans the card so an instance resized wider keeps both lines
  // against the start edge.
  head.layoutSizingHorizontal = 'FILL';
  const row = panel('chips', 'HORIZONTAL', lk, { gap: f.itemSpacing });
  row.counterAxisAlignItems = 'CENTER';
  // `Row(spacing: itemSpacing)` inside `FadeScroll` — one line, no wrap.
  row.layoutWrap = 'NO_WRAP';
  for (const t of _kChipGroupTags) {
    const chip = instanceOf(
      page,
      'Chip',
      // The widget's own defaults (`chip.dart`: `neutral` / `outlined` /
      // `high` / `selected: false` / `enabled: true` / `rounded`), spelled in
      // full.
      // `bestVariantName` only scores, so a key the set lacks is silently
      // worth nothing — asking for `Enabled` would leave the pick to whichever
      // member enumerates first, and asking for less than every axis would do
      // the same on the axes left out. That is also what a renamed axis does:
      // this pick once asked for the colour as `Variant`, which the set
      // renamed `Color`, and would have kept "working" on the wrong member.
      bestVariantName(page, 'Chip', {
        Color: 'neutral',
        Variant: CHIP.axes.variant.default,
        Size: 'md',
        State: 'enabled',
        Selected: 'false',
        Emphasis: 'high',
        // `CoreChipShape.defaultShape` — the documented `chipBuilder`
        // (`Chip(label:, selected:, enabled:, onTap:)`) names no shape.
        Shape: 'rounded',
      }),
    );
    setInstanceText(chip, t);
    row.appendChild(chip);
  }
  const viewport = instanceOf(page, 'FadeScroll');
  viewport.name = 'fade scroll';
  // The child slot the FadeScroll builder drew for its own preview — the chip
  // row is what fills it here, so its placeholder content steps aside.
  const placeholder = instanceFrameSlot(viewport, 'child');
  if (placeholder) placeholder.visible = false;
  const scroll = figma.createFrame();
  scroll.name = 'scroll';
  scroll.layoutMode = 'NONE';
  scroll.fills = [];
  scroll.clipsContent = true;
  // As tall as the chip line: the scroll view hugs its row on the cross axis.
  scroll.resize(viewport.width, row.height);
  // The composed viewport rides a STRETCH×STRETCH holder (#4826) — `constraints`
  // is refused on an instance, and a holder is the one node that can hand a
  // resized region's box to the instance inside it (the instance FILLs the
  // holder, `wrapForPin`).
  const viewportHolder = pinAbsolute(scroll, viewport, 0, 0, { horizontal: 'STRETCH', vertical: 'STRETCH' });
  sizePin(viewportHolder, scroll.width, scroll.height);
  scroll.appendChild(row);
  row.x = 0;
  row.y = 0;
  // The chips are the scrolled content: their own width, anchored at the start
  // edge, centred on the cross axis — a `Row` inside `FadeScroll` with the
  // default centre alignment. A wider region shows more of the row; the row
  // does not stretch to it.
  row.constraints = { horizontal: 'MIN', vertical: 'CENTER' };
  // The two edge fades, above the chips because that is the only place they can
  // be seen: the row already rides ABOVE the instance (Figma refuses to append
  // into one), so the instance's own bands are underneath it. `fadeWidth` is the
  // extent the widget hands `FadeScroll` as `startOffset`/`endOffset`, and
  // `fadeColor` the first stop of the `gradient` it hands with them.
  const fadeWidth = dimVal(f.fadeWidth);
  const fadeColor = colorData(f.fadeColor);
  for (const side of ['start', 'end'] as const) {
    const band = fadeBand(scroll, lk, fadeColor, side, fadeWidth);
    if (lk.sizeOrNull(fadeWidth)) band.setBoundVariable('width', lk.size(fadeWidth));
    band.x = side === 'start' ? 0 : scroll.width - fadeWidth;
    band.y = 0;
    band.constraints = {
      horizontal: side === 'start' ? 'MIN' : 'MAX',
      vertical: 'STRETCH',
    };
  }
  c.appendChild(scroll);
  // The card's width is the region's authored width, FIXED so that both rows
  // can FILL it (#4826): `head` already did, and `scroll` now does too. An
  // instance a designer sets to Fill container hands its width to this axis,
  // and only FILL children take it — while hugging with every child FILLing
  // would leave the width to nothing.
  lockWidth(c, scroll.width);
  scroll.layoutSizingHorizontal = 'FILL';
  const owner = propertyOwner(c);
  bindTextProp(title, defineProp(owner, 'Title', 'TEXT', '필터'));
  // Named for the contract slot (`selectionHint`), not prose-cased. The name
  // is how a reader tells which slot a property is — `Selection Hint` matched
  // no slot at all, so the panel offered an affordance that answered for
  // nothing in the API.
  bindTextProp(hint, defineProp(owner, 'SelectionHint', 'TEXT', '최대 2개까지 고를 수 있어요'));
  return c;
}

// ─── Stat ────────────────────────────────────────────────────────────────────

// Data-driven from coui_core STAT: per-variant surface/outline chrome
// + label / value / unit / change / description typography + colors.
//
// Shape mirrors the widget, top to bottom: a `spaceBetween` label row
// `[label, ?icon]`, the value row `[value, Gap(valueUnitGapStyle), ?unit]` on
// one baseline, a change row `[trend glyph, Gap(changeIconGapStyle), change]`,
// then the description line. `icon` is the contract's one composition slot, and
// `changeIconGapStyle` had no geometry to attach to while the change line was a
// single label. The trend character is the widget's own (`'↑'` / `_upArrow`),
// not an Icon — the widget renders it as text.
//
// `stat.axes` declares two Variant members (`outlined`, `filled`) and the
// whole `CoreComponentSize` enum, but `sizes.defaultsBySize` states only `md`
// and `sm` — a size the table does not state renders at the nearest stated one
// below it, so `Size` takes its members from the table, not from the enum.
// `outlined` and `md` are the code's defaults, so that combination is the set's
// lead — the member Figma hands a freshly placed instance. The members drawn
// before `Size` existed are the `md` ones (`src/renames.ts`).
//
// The card is the composed `OutlinedContainer` on both platforms — a content
// surface (Web marks it `webSurfaceMarkerFor(.content)`, Flutter's container
// reads `theme.surfaceFor(role)`) — so the variant's fill goes to the material
// layer. Neither variant states a shadow, so both take the cast a style
// contributes (Flutter's container falls back to `controlShadow`, Web's to
// `kControlShadowVar`) and no rim. Neither platform gives it the contributed
// boundary (`kControlBorderMarker` / `resolveInjectedBorder` are not on its
// path), so the borderless `filled` row draws no stroke under any style.
//
// `ChangeType` is appended to those four as a POSE axis because
// `CoreStatChangeType` is a three-member enum the widget switches on twice —
// once for the glyph (`↑` / `↓` / `→`) and once for the colour
// (`changeTextStylePositive` / `…Negative` / `…Neutral`, which the resolver
// bakes from `positiveColor` / `negativeColor` / `neutralColor`). v3 records the
// enum under `axes.other` and does not promote it (seed spec §4-2), and with
// only the positive pose drawn two of those three colours reached no node at all
// — a designer had no way to show a stat that fell. Figma's only enum-shaped
// property is a variant axis, which is why this became a set.
//
// `adoptLooseAs` names the combination the legacy COMPONENT actually drew, so a
// file where that node survives is promoted in place and keeps its key. On a
// file where it does not, `src/renames.ts`'s `STRUCTURAL_MIGRATIONS` entry for
// `Stat` has already removed it (the shape changed, COMPONENT → COMPONENT_SET),
// and this builder mints the set fresh — the two paths end at the same page.
//
// The three members differ in exactly what the widget's two switches differ in.
// The change STRING is per-member too, because a fall reading "12.5%" would say
// the axis is decorative — and that is why the change line is no TEXT property.
// A layer bound to a TEXT property reads the property's value, and a property
// has one default for the whole set, so binding the line would make all three
// members read the positive copy beside a `↓` and a `→`. Measured on the live
// file: the ten Banner members, whose builder writes five different messages,
// all read the one `Message` default. A placed instance still edits the line as
// a text override.
//
// `label` and `value` are strings with the same copy on every member, so each
// is a TEXT property (`Label` / `Value`) and binding loses nothing. `unit` and
// `description` are the same kind of field and get `Unit` / `Description`.
//
// Both are `String?`, and both widgets draw them only when they are set, so
// each carries a BOOLEAN — `Show unit` on the unit label, `Show description` on
// the description line. Hiding the unit drops its gap too, because that gap is
// the value row's `itemSpacing`; hiding the description drops the
// `contentGapStyle` gap in front of it, the tile's `itemSpacing`. Both default
// on: a freshly placed instance is the v2 KPI card (#5475's precedent — the
// default instance draws the look the redesign shipped).
//
// The empty value has no property. A `null` value draws
// `CoreStatContract.defaultEmptyValue` in `emptyValueColor`; a designer types
// the dash as a `Value` override, but the colour stays `valueColor`. Drawing it
// needs a pose the set does not have (see the G16 allowlist entry for
// `stat.emptyValueColor`).
//
// `change` is `String?`, and both widgets add the change row — with the
// `contentGapStyle` gap in front of it — only when `change` and `changeType`
// are both non-null. So the row carries `Show change`; hiding it drops the gap
// too, because the gap is the tile's `itemSpacing`. On by default: the
// `ChangeType` axis paints nothing but that row, so with it off the three
// members would be one picture. The trend glyph is not a property of its own —
// the widget derives it from `changeType`, which is the axis.
//
// `icon` is the contract's one `W?` slot and the widget renders it only when a
// caller passes one (`?icon`), so it takes a holder + swap pair — `Show icon`
// (off, the widget's `null`) on the holder, `Icon` on the glyph inside it.
const _kStatIcon = 'ellipsis';
const _kStatLabel = '총매출';
const _kStatValue = '1,248만';
const _kStatUnit = '원';
const _kStatDescription = '환불 전 금액';
const _kStatChanges: readonly {
  readonly type: string;
  readonly arrow: string;
  readonly color: 'positiveColor' | 'negativeColor' | 'neutralColor';
  readonly text: string;
}[] = [
  { type: 'positive', arrow: '↑', color: 'positiveColor', text: '이번 달 12.5%' },
  { type: 'negative', arrow: '↓', color: 'negativeColor', text: '이번 달 3.2%' },
  { type: 'neutral', arrow: '→', color: 'neutralColor', text: '이번 달 0.0%' },
];

function buildStat(page: PageNode, lk: VarLookup): ComponentSetNode {
  const variantData = new Map(Object.entries(STAT.variants.defaultsByVariant));
  // The sizes the library states (`defaultsBySize` — md and sm), not the whole
  // `CoreComponentSize` enum `axes.size` lists: a size the table does not state
  // renders at the nearest stated one below it, so it has no member of its own.
  const sizeData = new Map(Object.entries(STAT.sizes.defaultsBySize));
  const changeByType = new Map(_kStatChanges.map((s) => [s.type, s] as const));
  const combos = enumerateAxisCombos([
    ...axisSpecsOf({ ...STAT.axes, size: null }),
    { axis: 'Size', values: [...sizeData.keys()] },
    { axis: 'ChangeType', values: _kStatChanges.map((s) => s.type) },
  ]);
  const iconSwap = iconSwapDefault(page, 'Stat', 'Icon', iconMainId(page));
  const mount = mountSet(page, 'Stat', combos, {
    adoptLooseAs: `Variant=outlined, Size=md, ChangeType=${_kStatChanges[0].type}`,
  });
  const labelColorData = colorData(STAT.fields.labelColor);
  const iconNodes: InstanceNode[] = [];
  const iconHolders: FrameNode[] = [];
  const labelNodes: TextNode[] = [];
  const valueNodes: TextNode[] = [];
  const unitNodes: TextNode[] = [];
  const descriptionNodes: TextNode[] = [];
  const changeRows: FrameNode[] = [];
  for (const comboName of combos) {
    const combo = parseVariantKey(comboName);
    const variant = variantData.get(combo['Variant']);
    if (!variant) throw new Error(`Stat: no data for combo "${comboName}"`);
    const trend = changeByType.get(combo['ChangeType']);
    if (!trend) throw new Error(`Stat: no change tone for combo "${comboName}"`);
    // The row's boundary, read as stated. Both widgets hand `borderColor` /
    // `borderWidth` to the composed `OutlinedContainer`, which draws no line at
    // width 0 — so neither does this. It read `|| 1`, which turned a stated 0
    // into a 1px line, and asserted a border colour (`!`) that a borderless row
    // need not state.
    const strokeN = dimVal(variant.borderWidth);
    const size = sizeData.get(combo['Size']);
    if (!size) throw new Error(`Stat: no size row for combo "${comboName}"`);
    const c = mount.getOrCreate(comboName);
    applyPanelCompChrome(c, 'VERTICAL', lk, {
      radius: STAT.fields.borderRadius.topLeft,
      gap: size.contentGapStyle.size,
    });
    if (strokeN > 0) borderData(c, lk, colorData(variant.borderColor), strokeN);
    else c.strokes = [];
    bindPad(c, lk, size.padding);
    // The variant's face goes to the material layer — see the section note.
    // Neither row states a shadow, so the cast a style contributes rides the
    // surface node, and no rim.
    applySurfaceMaterial(c, lk, colorData(variant.backgroundColor), 'content', {
      radius: STAT.fields.borderRadius.topLeft,
    });
    addControlShadow(c, lk);
    const head = autoFrame('label-row', 'HORIZONTAL');
    head.primaryAxisAlignItems = 'SPACE_BETWEEN';
    head.counterAxisAlignItems = 'CENTER';
    const label = makeLabel(_kStatLabel, lk, textLabelOpts(lk, textStyleData(size.labelTextStyle), labelColorData));
    head.appendChild(label);
    labelNodes.push(label);
    // `icon` is a caller widget the label row renders as handed (`?icon` on
    // both platforms) — no `CoreStatStyle` field sizes it and nothing between
    // it and the app root mounts an `IconTheme`, so an `Icon` passed there
    // draws at the app root's ambient icon size. Drawn from the `Icon` swap
    // default, so the property's first bind leaves it at that size (see
    // `IconOpts.fromVariant`).
    //
    // In a holder that carries `Show icon` — see the section note. The glyph
    // goes in before the holder is hidden, so the holder has hugged it by
    // then, the order DescriptionCard's title slots use.
    const iconHolder = slotHolder('icon');
    head.appendChild(iconHolder);
    const icon = makeIcon(_kStatIcon, lk, {
      ...glyphOpts(lk, labelColorData, ICON.constants.ambientSize, 'size'),
      fromVariant: iconSwap.variant,
    });
    iconHolder.appendChild(icon);
    iconHolder.visible = false;
    iconHolders.push(iconHolder);
    iconNodes.push(icon);
    c.appendChild(head);
    head.layoutSizingHorizontal = 'FILL';
    // The value row: the figure and its unit on one baseline (`Row(crossAxis:
    // baseline)` on Flutter, `items-baseline` on Web), `valueUnitGapStyle`
    // between them. The gap is the row's `itemSpacing`, so hiding the unit
    // takes its gap with it, as the widgets draw no `Gap` without a unit.
    const valueRow = autoFrame('value-row', 'HORIZONTAL');
    valueRow.counterAxisAlignItems = 'BASELINE';
    bindSpaceField(valueRow, 'itemSpacing', lk, dimVal(STAT.fields.valueUnitGapStyle.size));
    const value = makeLabel(_kStatValue, lk, textLabelOpts(lk, textStyleData(size.valueTextStyle), colorData(STAT.fields.valueColor)));
    valueRow.appendChild(value);
    valueNodes.push(value);
    const unit = makeLabel(_kStatUnit, lk, textLabelOpts(lk, textStyleData(size.unitTextStyle), colorData(STAT.fields.unitColor)));
    unit.name = 'unit';
    valueRow.appendChild(unit);
    unitNodes.push(unit);
    c.appendChild(valueRow);
    // One style for both cells, which is the widget: it hands the SAME
    // `changeTextStyle` to the arrow `Text` and to the change `Text`.
    const changeOpts = textLabelOpts(
      lk,
      textStyleData(size.changeTextStyle),
      colorData(STAT.fields[trend.color]),
    );
    const change = panel('change', 'HORIZONTAL', lk, { gap: STAT.fields.changeIconGapStyle.size });
    change.counterAxisAlignItems = 'CENTER';
    change.appendChild(makeLabel(trend.arrow, lk, changeOpts));
    change.appendChild(makeLabel(trend.text, lk, changeOpts));
    c.appendChild(change);
    changeRows.push(change);
    // The footnote, after the change row — the order both widgets render. No
    // arrow and no trend colour: it is context for the figure, not a trend.
    const description = makeLabel(
      _kStatDescription,
      lk,
      textLabelOpts(lk, textStyleData(size.descriptionTextStyle), colorData(STAT.fields.descriptionColor)),
    );
    description.name = 'description';
    c.appendChild(description);
    descriptionNodes.push(description);
    // The widget hugs its content and takes its width from whatever grid the
    // app puts it in; `CoreStatStyle` states no width. A tile that hugged here
    // would be exactly its longest label wide, which is not a stat card. 272 is
    // the v2 KPI card's width.
    // g7-preview-only: Stat tile preview width, no width field in the code
    lockWidth(c, 272);
  }
  const set = mount.finish();
  // The code's defaults lead, so a freshly placed instance is the `outlined`
  // `md` card the widget draws when `variant` and `size` are omitted.
  defaultSetLayout(set, {
    Variant: STAT.axes.variant.default,
    Size: 'md',
    ChangeType: _kStatChanges[0].type,
  });
  // After `finish()`: until `combineAsVariants` has run, a fresh variant's
  // parent is still the page, so `propertyOwner` would answer with the variant
  // and each member would grow its own copy of the property.
  const iconProp = defineProp(set, 'Icon', 'INSTANCE_SWAP', iconSwap.id);
  for (const n of iconNodes) bindSwapProp(n, iconProp);
  const iconShownProp = defineProp(set, 'Show icon', 'BOOLEAN', false);
  for (const n of iconHolders) bindVisibleProp(n, iconShownProp);
  const labelProp = defineProp(set, 'Label', 'TEXT', _kStatLabel);
  for (const n of labelNodes) bindTextProp(n, labelProp);
  const valueProp = defineProp(set, 'Value', 'TEXT', _kStatValue);
  for (const n of valueNodes) bindTextProp(n, valueProp);
  const unitShownProp = defineProp(set, 'Show unit', 'BOOLEAN', true);
  const unitProp = defineProp(set, 'Unit', 'TEXT', _kStatUnit);
  for (const n of unitNodes) {
    bindVisibleProp(n, unitShownProp);
    bindTextProp(n, unitProp);
  }
  // The change line itself stays unbound — see the section note.
  const changeShownProp = defineProp(set, 'Show change', 'BOOLEAN', true);
  for (const n of changeRows) bindVisibleProp(n, changeShownProp);
  const descriptionShownProp = defineProp(set, 'Show description', 'BOOLEAN', true);
  const descriptionProp = defineProp(set, 'Description', 'TEXT', _kStatDescription);
  for (const n of descriptionNodes) {
    bindVisibleProp(n, descriptionShownProp);
    bindTextProp(n, descriptionProp);
  }
  return set;
}

// ─── Status ──────────────────────────────────────────────────────────────────

// Data-driven from coui_core: STATUS.variants.defaultsByVariant (the colour a
// presence state draws in), STATUS.sizes.defaultsBySize (the dot, the bar
// across a busy dot, the label's role and its distance from the dot) and
// STATUS.fields (ring and bar thickness, the bar's colour, the dot's corner).
//
// The canvas axis is `Variant` (online · busy · away · offline) — the
// contract's `state` — times `Size`. A state decides the SHAPE as well as the
// colour: `online` a filled dot, `busy` a filled dot with a bar across it,
// `away` and `offline` a ring. The shape is `CoreStatusVariant.hollow` /
// `hasBar`; the canvas states the same two answers by member.
//
// The label is the widget's `label` slot, so it is a `Show label` BOOLEAN
// (on by default: the pose a labelled Status is drawn in). Its text is the
// builder's sample wording — the widget takes whatever the caller hands it.
const kStatusVariants = [
  { n: 'online', label: '온라인', hollow: false, bar: false },
  { n: 'busy', label: '다른 용무 중', hollow: false, bar: true },
  { n: 'away', label: '자리 비움', hollow: true, bar: false },
  { n: 'offline', label: '오프라인', hollow: true, bar: false },
] as const;

function buildStatus(page: PageNode, lk: VarLookup): ComponentSetNode {
  const sizes = Object.entries(STATUS.sizes.defaultsBySize);
  const names: string[] = [];
  for (const v of kStatusVariants) {
    for (const [zn] of sizes) names.push(`Variant=${v.n}, Size=${zn}`);
  }
  const mount = mountSet(page, 'Status', names);
  const labels: TextNode[] = [];
  for (const v of kStatusVariants) {
    const stateColor = colorData(STATUS.variants.defaultsByVariant[v.n].color);
    for (const [zn, sz] of sizes) {
      const c = mount.getOrCreate(`Variant=${v.n}, Size=${zn}`);
      applyPanelCompChrome(c, 'HORIZONTAL', lk, {});
      bindSpaceField(c, 'itemSpacing', lk, dimVal(sz.labelSpacing));
      c.counterAxisAlignItems = 'CENTER';
      const dotSize = dimVal(sz.size);
      const dot = figma.createFrame();
      dot.name = 'dot';
      dot.fills = [];
      dot.clipsContent = false;
      bindSize(dot, lk, sz.size, sz.size);
      // A RECTANGLE, not an ELLIPSE. Both platforms draw a `size × size` box and
      // ROUND it — `borderRadius` is `radius9999`, the scale's fully-round step —
      // so an ellipse is the same picture by coincidence rather than because the
      // stated value reached anything. Move that value off `radius9999` and the
      // ellipse stays an ellipse.
      const shape = figma.createRectangle();
      shape.name = 'shape';
      bindSize(shape, lk, sz.size, sz.size);
      bindRadiusN(shape, lk, STATUS.fields.borderRadius.topLeft);
      if (v.hollow) {
        // A ring: the stroke sits inside the box, so the dot is the same size
        // as a filled one (`Border.all` inside the decoration on Flutter,
        // `box-sizing: border-box` on the Web).
        shape.fills = [];
        borderData(shape, lk, stateColor, STATUS.fields.ringWidth);
        shape.strokeAlign = 'INSIDE';
      } else {
        fillData(shape, lk, stateColor);
      }
      dot.appendChild(shape);
      if (v.bar) {
        const bar = figma.createRectangle();
        bar.name = 'bar';
        bindSize(bar, lk, sz.barLength, STATUS.fields.barWidth);
        // Round ends — the full radius, which Figma clamps to half the bar's
        // thickness as both platforms do.
        bindRadiusN(bar, lk, STATUS.fields.barBorderRadius.topLeft);
        fillData(bar, lk, colorData(STATUS.fields.barColor));
        // Centred in the dot — the dot's flex box does it on the Web, an
        // aligned container on Flutter.
        bar.x = (dotSize - bar.width) / 2;
        bar.y = (dotSize - bar.height) / 2;
        dot.appendChild(bar);
      }
      c.appendChild(dot);
      // The size row's role in `on-surface`, merged with the state's own label
      // style (`offline` alone states `on-surface-variant`) — the resolver's
      // `sizeStyle.labelStyle.merge(variantStyle.labelStyle)`.
      const stateLabel = optField<Parameters<typeof textStyleData>[0]>(
        STATUS.variants.defaultsByVariant[v.n],
        'labelStyle',
      );
      const labelStyle = mergeTextStyleData(
        textStyleData(sz.labelStyle),
        textStyleData(stateLabel),
      );
      const label = makeLabel(v.label, lk, textLabelOpts(lk, labelStyle));
      label.name = 'Label';
      c.appendChild(label);
      labels.push(label);
    }
  }
  const set = mount.finish();
  vStackSet(set);
  const showLabelProp = defineProp(set, 'Show label', 'BOOLEAN', true);
  for (const n of labels) bindVisibleProp(n, showLabelProp);
  return set;
}

// ─── Kbd ─────────────────────────────────────────────────────────────────────

// Data-driven from coui_core: KBD.fields (key box bg/border/radius/border-
// width/shadow/padding, the key label's typography role, and the gap between
// two keys).
//
// The component is a ROW of key caps. `Kbd(keys: List<String>)` draws one cap
// per key, side by side, with `keySeparatorSpacing` between neighbours and no
// glyph in the gap — `Row(spacing:)` on Flutter, a flex `gap` on the Web
// wrapper. The row therefore has no separator node, and the gap is the row's
// `itemSpacing`, bound to that field.
//
// A Figma component cannot repeat a child by a runtime count, and it has no
// repeated-slot property, so the key count is the set of BOOLEANs the
// component carries — the shape `DotIndicator`'s `Show dot N`, `Tabs` and
// `NavigationBar` take. Four caps are drawn (`kKbdCapGlyphs`); cap 1 always
// draws, caps 2–4 each hide behind `Show key N` (default off), so the resting
// component and every instance of it show one key. Each cap's glyph is bound
// to its own TEXT property (`KeyContent` for the first, `KeyContent N` after
// it); `KeyContent` is also the `Kbd.icon` glyph slot (one widget key, mutually
// exclusive with `keys`).
//
// The root is the ROW that holds the caps, not a cap: the box is the `keyCap`
// inside it, which is what carries the fill, the edge and the shadow. The
// shadow rides each cap and not the row — the row paints no fill, and a shadow
// on a fill-less frame is cast by every child it holds.
//
// The edge and the shadow are each drawn only when the data states one. The
// default cap is a fill alone: its border colour is the transparent sentinel
// (code folds the stroke width to 0 and takes no layout for it, and the canvas
// draws no stroke at all), and it states no shadow layer, so there is no shadow
// effect to link and no rim — the rim rides the shadow the cap itself states,
// on both platforms.
//
// The label takes its size / weight / line-height / colour from the role the
// data names (`keyTextStyle` = labelXs) rather than a number written here.
// A literal survives every other gate — the role name still reaches the JSON,
// so field coverage counts the field as read — while the cap renders 40%
// oversized; only reading the canvas back can tell the two apart.
//
// `keyMinSize` is a min-square floor (`ConstrainedBox(minWidth:, minHeight:)`),
// written as the cap's own min width and height: a one-character key is a
// square of that side, a longer one still grows past it. The cap draws in the
// text face, as Core does: `keyTextStyle` names no family, and the text face
// carries the key symbols (⌘ ⌥ ⌃ ⎋) the monospace one lacks.
//
// A shadow a cap states is linked to the document's `shadow/<step>` effect style
// that states the same layers (`shadow-style.ts`) rather than left as a copy of
// its numbers: the style is what a designer's own Kbd wears, so editing it has
// to reach this one too.

// The copy each cap draws until a designer types over its `KeyContent`
// property — display text only, no Core field states a key's letters. The list
// is also how many caps the component draws.
const kKbdCapGlyphs = ['Ctrl', 'Shift', 'K', 'F5'] as const;

// Caps below this index always draw and carry no `Show key N`; the rest ship
// hidden. One key is the resting component — a `Kbd.single` / `Kbd.icon`, and
// the shape `Command` composes.
const kKbdAlwaysShownCaps = 1;

// The layer name of cap `index` (0-based): the first keeps the bare `keyCap`
// the Kbd drill and the shadow-miss report name it by, the rest carry their
// ordinal the way the designer's `Show key N` properties count them.
function kbdCapName(index: number): string {
  return index === 0 ? 'keyCap' : `keyCap ${index + 1}`;
}

async function buildKbd(page: PageNode, lk: VarLookup): Promise<ComponentNode> {
  const f = KBD.fields;
  const c = mintPanelComp(page, 'Kbd', 'HORIZONTAL', lk, { gap: f.keySeparatorSpacing });
  c.counterAxisAlignItems = 'CENTER';
  const keyLabel = textLabelOpts(lk, textStyleData(f.keyTextStyle));
  // Each key cap is a content surface on both platforms (`kbd_style.dart`
  // reads `theme.surfaceFor(.content)`; the Web twin marks each cap
  // `webSurfaceMarkerFor(.content)`). Both give it the style's rim only while
  // the cap states a shadow of its own, so the rim follows `keyShadow` — a cap
  // that states none (the default) takes no rim under any surface style. Its
  // fill lives a layer below, so the cap's own effects stay free for the
  // shadow style it links.
  const keyFill = colorData(f.keyBackgroundColor);
  // The edge is drawn only while its colour can be seen: a transparent border —
  // the `ref: null` sentinel, or a token stated at zero strength — is the cap
  // with no outline at all, whatever width the field carries (code folds the
  // width of an invisible border to 0 and keeps it out of layout).
  const keyBorder = colorData(f.keyBorderColor);
  const keyEdge = keyBorder != null && keyBorder.color != null && (keyBorder.opacity ?? 1) > 0 ? keyBorder : null;
  const caps: { box: FrameNode; glyph: TextNode; shown: boolean }[] = [];
  for (let index = 0; index < kKbdCapGlyphs.length; index++) {
    const box = panel(kbdCapName(index), 'HORIZONTAL', lk, {
      border: keyEdge?.color ?? undefined, borderOp: keyEdge?.opacity, borderArgb: keyEdge?.argb,
      strokeN: f.keyBorderWidth, radius: f.keyRadius.topLeft,
      pl: f.keyPadding.l, pr: f.keyPadding.r, pt: f.keyPadding.t, pb: f.keyPadding.b,
    });
    applySurfaceMaterial(box, lk, keyFill?.color == null ? null : keyFill, 'content', {
      radius: f.keyRadius.topLeft,
      rim: f.keyShadow.layers.length > 0,
    });
    box.primaryAxisAlignItems = 'CENTER';
    box.counterAxisAlignItems = 'CENTER';
    // `ConstrainedBox(constraints: BoxConstraints(minWidth: keyMinSize,
    // minHeight: keyMinSize))` inside the key box — a floor, not a size, so
    // a one-character key is square instead of as narrow as its glyph while a
    // longer one still grows.
    box.minWidth = dimVal(f.keyMinSize);
    box.minHeight = dimVal(f.keyMinSize);
    // Per-key, on the box that has the fill — `Ctrl Shift` shows one shadow per key.
    setShadow(box, f.keyShadow, lk);
    await linkShadowStyle(box, f.keyShadow, `Kbd/${box.name}`);
    const glyph = makeLabel(kKbdCapGlyphs[index], lk, keyLabel);
    box.appendChild(glyph);
    c.appendChild(box);
    // The node starts hidden, not just the property's default — a BOOLEAN
    // default governs instances while the main component keeps whatever the
    // builder left visible, so without this the component's own picture would
    // carry every cap.
    const shown = index < kKbdAlwaysShownCaps;
    box.visible = shown;
    caps.push({ box, glyph, shown });
  }
  // Properties AFTER every cap is in the row: a reference needs its node inside
  // the component. `KeyContent` is the contract's slot name — a property whose
  // name matches no slot covers no slot — and belongs to the first key; the
  // keys after it carry their ordinal.
  const owner = propertyOwner(c);
  bindTextProp(caps[0].glyph, defineProp(owner, 'KeyContent', 'TEXT', kKbdCapGlyphs[0]));
  for (let index = 1; index < caps.length; index++) {
    const ordinal = index + 1;
    const cap = caps[index];
    if (index >= kKbdAlwaysShownCaps) {
      bindVisibleProp(cap.box, defineProp(owner, `Show key ${ordinal}`, 'BOOLEAN', cap.shown));
    }
    bindTextProp(cap.glyph, defineProp(owner, `KeyContent ${ordinal}`, 'TEXT', kKbdCapGlyphs[index]));
  }
  return c;
}

// ─── CodeSnippet ─────────────────────────────────────────────────────────────

// Data-driven from coui_core: CODE_SNIPPET.fields (bg/border/border-width/
// radius/padding, and `codeTypography` — the `codeSm` code role — for the code
// lines' and the gutter's size / weight / 21px line box, so both columns sit
// on one grid). The face is `surface-container-low` with no border (a
// transparent border colour and a zero width, one pair), and the code text is
// `on-surface` through `codeTextStyle.color`.
//
// That colour is read, not written: the widget's
// `codeStyleCore.toValue(color: fgColor, …)` forces the foreground over the
// role's own, and `fgColor` resolves `codeTextStyle.color` →
// `defaultCodeTextStyle.color` → `CoreColors.onSurface`. The field carries that
// value, so the two paths are the same one — `codeTypography` supplies the
// metrics and `codeTextStyle` the colour, which is exactly how the resolver
// splits them. The gutter has a stated colour of its own
// (`lineNumberTextStyle.color`, `on-surface-variant`, opaque) and does not
// derive from the code colour.
//
// Not drawn: the syntax colours of the sample lines. The widget paints each
// span from the scheme's syntax slots, and a range fill bound to a variable is
// a builder helper that does not exist yet (only the range font is), so the
// sample lines stay one ink.
//
// Shape mirrors the widget: `Stacks([Container(code), Position(top:, right:,
// child: Row([...actions, copy Button]))])`. Figma has no separate stack node —
// an absolutely-positioned child of an auto-layout frame IS that stack, pinned
// to the box's own top-right corner, which is what `Position` does here.
//
// The copy affordance is an INSTANCE of `Button`: the widget builds
// `Button(variant: .plain, buttonStyle: resolved.copyButtonStyle, child:
// Icon(...))`, and `copyButtonStyle` is that forwarded slot — its 28×28 box and
// radius 8 are bound onto the instance. The row around it carries
// `actionGapStyle` as its `itemSpacing`, which is the `Gap` the widget
// interleaves between `actions` (a `List<W>`; Figma has no repeated-slot
// property, so a designer adds to the row directly).
//
// The glyph is the resting `copy` — the widget renders `_copied ?
// LucideIcons.check : LucideIcons.copy` in this one slot, and the preview is
// the block before anything was copied. The `check` pose is the second of the
// slot's two states and only lasts the copied-feedback window, so it is not
// drawn.
//
// The line tones (`lineTones`) are bands behind the sample lines, one per tone
// that draws one: warning on the first line, success on the second, error on
// the third, each hidden until its `Show … line` is on (the widget's default
// is no tone). A band is the line box tall — the code role's, the one both
// columns sit on — and runs the snippet's full width, under the gutter, the
// code and the padding on both sides, as the widgets paint it. It sits in
// `pre`, so it follows the padding above it in every density; reaching out
// over the side padding is a stated offset, which a density that moves that
// padding does not move.
//
// The code lines are drawn text, not instances of the REGISTRY's
// `SelectableText`, and the name in code_snippet.dart is not that component:
// the file opens with `import 'package:coui_flutter/coui_flutter.dart' hide
// SelectableText;` and `import 'package:flutter/material.dart' show
// SelectableText;`. It composes Material's widget and explicitly hides CoUI's.
// Instancing the CoUI one here would put a component on the canvas that the
// widget goes out of its way not to use.
const _kCodeSnippetWidth = 320;
function buildCodeSnippet(page: PageNode, lk: VarLookup): ComponentNode {
  const f = CODE_SNIPPET.fields;
  const c = mintPanelComp(page, 'CodeSnippet', 'VERTICAL', lk, {
    bg: colorData(f.backgroundColor)?.color ?? undefined,
    border: colorData(f.borderColor)?.color ?? undefined,
    strokeN: f.borderWidth, radius: f.borderRadius.topLeft,
    pl: f.padding.l, pr: f.padding.r, pt: f.padding.t, pb: f.padding.b,
  });
  lockWidth(c, _kCodeSnippetWidth);
  const lines = ['const greet = (name) => {', '  return `Hello, ${name}`;', '};'];
  // `codeTypography` supplies size / weight / line-height and states no colour
  // of its own; `codeTextStyle.color` is the foreground the resolver forces over
  // the role, so it arrives as the fallback colour rather than as a literal.
  const codeLineOpts = textLabelOpts(
    lk,
    textStyleData(f.codeTypography),
    colorData(f.codeTextStyle.color),
  );
  // The `<pre>` wrapper, and `preMargin` its own inset inside the container's
  // padding. Zero today, so no pixel moves — what changes is that the field has
  // somewhere to land, instead of the wrapper's inset being a thing the canvas
  // decided. Only the Web resolver spends it (`'margin'` on the pre); the
  // Flutter one resolves it into `ResolvedCodeSnippet.preMargin` and the widget
  // never reads it back — see `notes`.
  const pre = panel('pre', 'HORIZONTAL', lk, {
    pl: f.preMargin, pr: f.preMargin, pt: f.preMargin, pb: f.preMargin,
  });
  // `Row(crossAxisAlignment: .start)` — the gutter and the code start on the
  // same line, whatever their heights are.
  pre.counterAxisAlignItems = 'MIN';
  c.appendChild(pre);
  // The code block spans the snippet's width — a block, not a chip (#4805).
  pre.layoutSizingHorizontal = 'FILL';
  // The line-number gutter: `Padding(padding: .only(right: lineNumberMargin),
  // child: Column(crossAxisAlignment: .end, children: [Text('1'), …]))`. That
  // inset is the only thing separating the numbers from the code, and it had no
  // node at all — the gutter was not drawn, so `lineNumberMargin` reached
  // nothing.
  const gutter = panel('line numbers', 'VERTICAL', lk, { pr: f.lineNumberMargin });
  gutter.counterAxisAlignItems = 'MAX';
  const gutterOpts = textLabelOpts(
    lk,
    textStyleData(f.codeTypography),
    // The gutter's own foreground — `lineNumberTextStyle.color`, an opaque
    // token, which is what both resolvers apply. It is not the code colour
    // dimmed: the retired `lineNumberAlpha` is gone from the data, and the
    // hierarchy between the numbers and the code is the token chosen.
    colorData(f.lineNumberTextStyle.color),
  );
  for (let n = 1; n <= lines.length; n++) {
    gutter.appendChild(makeLabel(String(n), lk, gutterOpts));
  }
  pre.appendChild(gutter);
  // `showLineNumbers` defaults to false, so the gutter starts hidden and the
  // BOOLEAN below is what says it exists. Hidden rather than absent: an
  // auto-layout frame skips a hidden child entirely, so the resting preview is
  // byte-identical to the one before the gutter existed.
  gutter.visible = false;
  const code = autoFrame('code', 'VERTICAL');
  for (const ln of lines) {
    code.appendChild(makeLabel(ln, lk, codeLineOpts));
  }
  pre.appendChild(code);
  // The line bands, behind both columns (children 0…, under the gutter and the
  // code). `pre` draws them past its own edges, out over the side padding.
  const codeType = textStyleData(f.codeTypography);
  const lineBox =
    codeType.lineHeightPx ??
    (codeType.fontSize != null && codeType.lineHeight != null
      ? codeType.fontSize * codeType.lineHeight
      : null);
  if (lineBox == null) {
    throw new Error('CodeSnippet: the code role states no line box to size a line band by');
  }
  pre.clipsContent = false;
  const lineTones = [
    { tone: 'warning', color: f.warningLineColor },
    { tone: 'success', color: f.successLineColor },
    { tone: 'error', color: f.errorLineColor },
  ];
  const lineBands = lineTones.map(({ tone, color }, index) => {
    const band = figma.createRectangle();
    band.name = `${tone} line`;
    band.resize(_kCodeSnippetWidth, lineBox);
    fillData(band, lk, colorData(color));
    // `insertChild` first, then pin: `pinAbsolute` appends, so pinning and
    // then moving to the back reparents the same node twice.
    pre.insertChild(index, band);
    pinInFlow(pre, band);
    band.x = -dimVal(f.padding.l);
    band.y = dimVal(f.preMargin) + index * lineBox;
    band.constraints = { horizontal: 'STRETCH', vertical: 'MIN' };
    band.visible = false;
    return { tone, band };
  });
  const copyStyle = f.copyButtonStyle;
  const actions = panel('actions', 'HORIZONTAL', lk, { gap: f.actionGapStyle.size });
  actions.counterAxisAlignItems = 'CENTER';
  actions.appendChild(
    iconButton(page, lk, {
      name: 'copy',
      variant: 'plain',
      // The widget names no size, so Button's own default (`CoreComponentSize.md`)
      // applies; `copyButtonStyle` then forces the box to 28×28 over it.
      size: 'md',
      glyph: 'copy',
      glyphSize: f.copyIconStyle.size,
      // `copyIconStyle` states no colour on the default face: the glyph takes
      // the one the plain `Button` hands its child, so the canvas draws that
      // variant's resting foreground rather than a colour of its own.
      glyphColor: colorData(kPlainButtonForeground),
      // Forwarded alongside the box: `copyButtonStyle` states a zero inset the
      // same way chip's close style does. The 28×28 pins this button's box, so
      // the inset does not move the glyph here — it is on the instance because
      // that is what the slot says, and a designer reads the instance.
      padding: copyStyle.padding,
      radius: copyStyle.borderRadius.topLeft,
      width: copyStyle.width,
      height: copyStyle.height,
      // No ring is forwarded: the block sits on a container tone, so the copy
      // button keeps Button's own (transparent-band) ring.
    }),
  );
  // Derived, not read back: a hug frame's width is only correct once Figma has
  // relaid it out, and the row holds exactly the one 28-wide affordance.
  const inset = dimVal(f.copyButtonOffset);
  pinAbsolute(c, actions, _kCodeSnippetWidth - dimVal(copyStyle.width) - inset, inset, {
    horizontal: 'MAX',
    vertical: 'MIN',
  });
  bindVisibleProp(
    gutter,
    defineProp(propertyOwner(c), 'Show line numbers', 'BOOLEAN', false),
  );
  for (const { tone, band } of lineBands) {
    bindVisibleProp(
      band,
      defineProp(propertyOwner(c), `Show ${tone} line`, 'BOOLEAN', false),
    );
  }
  return c;
}

// ─── DescriptionCard ─────────────────────────────────────────────────────────

// Data-driven from coui_core: DESCRIPTION_CARD.variants.defaultsByVariant
// (filled/outlined/ghost — bg/border/border-width, one child per member) +
// .fields (radius, row leading gap, value-column color via `titleColor`,
// divider colour, the composed `Clickable`'s disabled opacity) +
// .sizes.defaultsBySize, all five rows (each one's padding, its three gaps, and
// the row type via `labelTextStyle` / `valueTextStyle`).
//
// Three axes — `Variant` × `Size` × `Disabled`, 30 members. `Variant` is the one
// `axisSpecsOf` contributes (`description_card.axes.variant`, three members that
// differ by exactly the fields read through `optField` below — `filled` and
// `ghost` carry no `borderColor` because their `borderWidth` is 0, which is why
// every one of them is optional here rather than a required key).
//
// `Size` and `Disabled` are appended to those four as POSE axes.
// `CoreDescriptionCardSize` is one of the six `CoreDescriptionCard*` enums v3
// records under `axes.other`, and recording without promotion (seed spec §4-2)
// is the enumerator's default — but a posed size would leave four fifths of the
// data with no node: `defaultsBySize` carries five rows and every one of them
// moves more than padding (the label / value / title roles and four gap slots
// all change with it). The other five enums — alignment, empty behaviour,
// layout, overflow, row weight — do stay at this preview's single rendering.
//
// Every gap the size row states lands on a frame, and none of them shares one:
// `titleContentGapStyle` is the card column's `itemSpacing` (the widget spends
// that same gap at every seam of `[titleSection, Divider, rows]` and again in
// the bottom region), `iconLabelGapStyle` is the title row's, and `rowSpacing`
// is the `rows` frame's — which exists because `_buildRows` is its own
// `Column(spacing: resolved.rowSpacing)` rather than three siblings of the
// title. A flat column would have had one Figma gap standing for two stated
// ones, and the widget's own nesting is what avoids it.
//
// The heading is the size row's `titleTextStyle` role with
// `fields.titleTextStyle` (SemiBold) merged on top, and the leading glyph is
// drawn at the size row's `titleLeadingIconStyle` — the ambient icon theme
// both widgets hand that slot.
//
// The row colours stay literal for a different reason: they are in Core but not
// in a Style. `kCoreDescriptionCardRowWeightColors[valueProminent]` — the
// default `rowWeight` — is what the widget reads for the term
// (`on-surface-variant`) and the value (`on-surface`, which `titleColor` also
// happens to be), and the exporter walks Style classes, so that map has no
// export path.
//
// `Disabled` is a boolean axis for `enabled: false` on a card with a tap
// target: the widget dims its CONTENT — the title, the rows and the bottom
// action region, with their icons and rules — to `disabledContentOpacity` (bound to `opacity/40`), and
// the card's fill and border stay at full strength. The composed
// `Clickable`'s own `disabledOpacity` is full strength here so it does not
// dim the card a second time, which is why the member frame carries no
// opacity. `pressedScale` is 1.0 — a Pressed axis would render identically on
// both sides, which is a click a designer pays for and gets nothing from. The
// `Clickable` contributes nothing else visually, so it has no instance: an
// empty frame wrapping the card would assert a region that renders nothing.
// The widget dims its one content column; the canvas dims the four nodes it
// draws that column with (title row, title rule, rows, bottom region) — the
// same pixels, without a frame the copy does not have.
//
// The rule under the title is an INSTANCE of `Divider`: the widget's column is
// `[titleSection, Gap, if (showDivider) Divider(dividerStyle:
// CoreDividerStyle(color: resolved.dividerColor)), Gap, rows…]` with
// `showDivider` defaulting to true, and `DESCRIPTION_CARD.fields.dividerColor`
// is that forwarded colour. The title section had to come with it — the rule
// separates the title from the rows, so a card with no title node has nothing
// for it to separate.
//
// `showRowDividers` (default true) is the widget's third `Divider` site: a
// `Divider` between consecutive rows, so every row but the last has a rule
// under it, and the rows themselves sit edge to edge (`rowSpacing` 0) with
// their own vertical `rowPadding`. `showBottomActionDivider` also defaults
// true — it just never fired while `bottomAction` was null, which is why the
// bottom region below carries a rule of its own.
//
// The three composition slots — `titleLeading`, `titleTrailing`,
// `bottomAction` — each get a holder + content pair (see the header note).
// `titleTrailing` and `bottomAction` start hidden, matching the widget's own
// `null` defaults. `titleLeading` starts SHOWN with a `credit-card` glyph
// even though the widget's slot is `null` too: the designer decided (#6470)
// that the canvas default carries an example icon so a fresh instance shows
// how the title reads with one. The code does not draw it — the widget
// renders `titleLeading` only when a caller passes one — so turning the
// property off is what the widget's default looks like.
//
// The bottom region is the whole `if (bottomAction != null) [...]` branch, not
// just the action: the widget puts a `Divider` inside that same condition, so
// a designer who turns the region on has to get what the code renders — a
// rule, then the action. A holder that produced only the button would be a
// structure the widget never builds.
const _kDescriptionCardTitleLeadingGlyph = 'credit-card';
const _kDescriptionCardTitleTrailingGlyph = 'ellipsis';
const _kDescriptionCardBottomActionLabel = '요금제 관리';


function buildDescriptionCard(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = DESCRIPTION_CARD.fields;
  const variantData = new Map(Object.entries(DESCRIPTION_CARD.variants.defaultsByVariant));
  // All five rows — see the note above for why Size is an axis. Everything a
  // row states (its type roles and its four gap slots, not just padding) is read
  // inside the loop below rather than hoisted, because all of it moves per row.
  const sizeData = new Map(Object.entries(DESCRIPTION_CARD.sizes.defaultsBySize));
  const disabledContentOpacity = dimVal(f.disabledContentOpacity);
  const kBoolAxis = ['false', 'true'] as const;
  // The contract's `enabled` would add an `Enabled` axis; the set keeps the
  // `Disabled` pose axis it already has (the same state, the names the
  // designer's copy and every existing member carry).
  const combos = enumerateAxisCombos([
    ...axisSpecsOf(DESCRIPTION_CARD.axes).filter((spec) => spec.axis !== 'Enabled'),
    { axis: 'Size', values: [...sizeData.keys()] },
    { axis: 'Disabled', values: kBoolAxis },
  ]);
  // The title glyphs are drawn from their swap defaults, so the properties'
  // first binds leave them at their own size (see `IconOpts.fromVariant`).
  const titleLeadingSwap = iconSwapDefault(page, 'DescriptionCard', 'TitleLeading', iconMainId(page));
  const titleTrailingSwap = iconSwapDefault(page, 'DescriptionCard', 'TitleTrailing', iconMainId(page));
  // The legacy static node drew the outlined variant at the `md` row's 16 inset,
  // enabled — so that is the combination it is promoted into, in place, keeping
  // its key. On a file that already carries the set, `src/renames.ts` migrates
  // each `Variant=x, Disabled=y` child into the same name the enumeration
  // produces here, and adoption never fires.
  const mount = mountSet(page, 'DescriptionCard', combos, {
    adoptLooseAs: 'Variant=outlined, Size=md, Disabled=false',
  });
  const rows = [['요금제', 'Pro'], ['좌석', '10석 중 5석'], ['갱신일', '2027년 6월']];
  // `CoreTextAlign` → Figma's horizontal text alignment; an unknown member
  // throws so a new alignment surfaces as a failed build.
  const valueAlign = (() => {
    switch (f.valueTextAlign.choice) {
      case 'left':
      case 'start':
        return 'LEFT' as const;
      case 'center':
        return 'CENTER' as const;
      case 'right':
      case 'end':
        return 'RIGHT' as const;
      default:
        throw new Error(`DescriptionCard: unknown valueTextAlign "${f.valueTextAlign.choice}"`);
    }
  })();
  const valueColor = colorData(f.titleColor);

  const ruleAxes = { Orientation: 'Horizontal', Label: 'None' };
  // The bottom action is an outline Button for the reason banner's is: a card
  // footer affordance sits on the card's own surface, and an unnamed
  // instanceOf returns whatever variant sorts first.
  const bottomActionVariant = bestVariantName(page, 'Button', {
    Variant: 'outline',
    Size: 'sm',
  });
  // The `Divider` main component hugs a fixed-length preview line, and its own
  // default colour is not the one this card forwards — see `hostedDivider`.
  const ruleColor = colorData(f.dividerColor);
  const titleLeadingHolders: FrameNode[] = [];
  const titleLeadingNodes: InstanceNode[] = [];
  const titleTrailingHolders: FrameNode[] = [];
  const titleTrailingNodes: InstanceNode[] = [];
  const bottomActionHolders: FrameNode[] = [];
  const bottomActionNodes: InstanceNode[] = [];
  for (const comboName of combos) {
    const combo = parseVariantKey(comboName);
    const variant = variantData.get(combo['Variant']);
    if (!variant) throw new Error(`DescriptionCard: no data for combo "${comboName}"`);
    const sz = sizeData.get(combo['Size']);
    if (!sz) throw new Error(`DescriptionCard: no size data for combo "${comboName}"`);
    const disabled = combo['Disabled'] === 'true';
    // 멤버로 읽는다 — 키를 문자열로 넘기면 미판독 필드 가드가 이 읽기를 보지
    // 못한다. 이 키가 없는 행(full-bleed 가 아닌 변형)은 양옆을 채운다.
    const padsHorizontally =
      'padsHorizontally' in variant ? variant.padsHorizontally.v : true;
    const c = mount.getOrCreate(comboName);
    // Row type off whichever size row is being built — inside the loop
    // because that is where it changes. Neither `labelTextStyle` nor
    // `valueTextStyle` carries a colour; the value's rides `titleColor` as
    // `textLabelOpts`'s fallback, and the term's comes from the map named
    // below.
    const termOpts = {
      ...textLabelOpts(lk, textStyleData(sz.labelTextStyle)),
      // g7-preview-only: the term colour is `kCoreDescriptionCardRowWeightColors[.valueProminent].labelColor` — a top-level const map keyed by `rowWeight`, not a `CoreDescriptionCardStyle` field, and the exporter walks Style classes, so `components.json` carries no key for it
      colorVar: lk.sem('on-surface-variant'),
    };
    const valueOpts = textLabelOpts(lk, textStyleData(sz.valueTextStyle), valueColor);
    applyPanelCompChrome(c, 'VERTICAL', lk, {
      bg: colorData(optField<Color>(variant, 'backgroundColor'))?.color ?? undefined,
      border: colorData(optField<Color>(variant, 'borderColor'))?.color ?? undefined,
      strokeN: optField<Dim>(variant, 'borderWidth') ?? 1,
      // The corner steps with the size row (xs 12 · sm 14 · md up 16).
      radius: sz.borderRadius.topLeft,
      // `CoreDescriptionCardVariantStyle.paddingFor` — `ghost` keeps the
      // row's top / bottom and drops its left / right (no box edge to inset
      // from).
      pl: padsHorizontally ? sz.padding.l : 0,
      pr: padsHorizontally ? sz.padding.r : 0,
      pt: sz.padding.t,
      pb: sz.padding.b,
      // The card column's seams — the widget spends `titleContentGapStyle`
      // between titleSection and the rule, between the rule and the rows, and
      // again on both sides of the bottom region's rule. One `itemSpacing`
      // says all of them because they are all the same stated gap; row↔row
      // is a different one and lives on the `rows` frame below.
      gap: sz.titleContentGapStyle.size,
    });
    // The card takes its width from the column it is dropped into — neither
    // `CoreDescriptionCardStyle` nor the md size row states one.
    // g7-preview-only: DescriptionCard preview width, no width field in the code
    lockWidth(c, 280);
    // `_buildTitleSection` puts `Gap(gapStyle: resolved.iconLabelGapStyle)`
    // on both sides of the heading — leading↔title and title↔trailing — so
    // the row's one `itemSpacing` is that gap.
    const head = panel('title', 'HORIZONTAL', lk, { gap: sz.iconLabelGapStyle.size });
    head.counterAxisAlignItems = 'CENTER';
    const titleLeadingHolder = slotHolder('titleLeading');
    head.appendChild(titleLeadingHolder);
    // Both title slots are caller widgets `_buildTitleSection` renders as
    // handed — no `CoreDescriptionCardStyle` field sizes them, and neither the
    // row nor the composed `OutlinedContainer` / `Clickable` mounts an
    // `IconTheme`, on either platform. So an `Icon` passed there draws at the
    // app root's ambient icon size, not at the heading's.
    // `titleLeadingIconStyle` is the slot's ambient icon theme on both
    // platforms — a per-size glyph (16 / 16 / 18 / 20 / 20) in
    // `on-surface-variant`, so an `Icon` handed there takes these.
    const titleLeading = makeIcon(_kDescriptionCardTitleLeadingGlyph, lk, {
      ...glyphOpts(
        lk,
        colorData(sz.titleLeadingIconStyle.color),
        sz.titleLeadingIconStyle.size,
        'size',
      ),
      fromVariant: titleLeadingSwap.variant,
    });
    titleLeadingHolder.appendChild(titleLeading);
    // Shown by default — see the slot note above (#6470).
    titleLeadingHolder.visible = true;
    titleLeadingHolders.push(titleLeadingHolder);
    titleLeadingNodes.push(titleLeading);
    // The heading is `titleTextStyle`, and it is a per-size ROW: `labelMedium`
    // at xs climbing to `titleLarge` at xl, 13 → 20. Drawn at a literal 14 it
    // was the same words on every rung while the box around them grew — the
    // ladder defect, with a comment saying so and nothing able to fail on it.
    // `titleTextStyle` states no colour, so the title's own hue is the fallback.
    // The role is the size row's; `defaultTitleTextStyle` lays SemiBold over
    // it (`fields.titleTextStyle`), the same merge both resolvers fold.
    const heading = makeLabel(
      '구독',
      lk,
      textLabelOpts(
        lk,
        mergeTextStyleData(textStyleData(sz.titleTextStyle), textStyleData(f.titleTextStyle)),
        valueColor,
      ),
    );
    head.appendChild(heading);
    heading.layoutSizingHorizontal = 'FILL';
    const titleTrailingHolder = slotHolder('titleTrailing');
    head.appendChild(titleTrailingHolder);
    const titleTrailing = makeIcon(_kDescriptionCardTitleTrailingGlyph, lk, {
      ...glyphOpts(lk, valueColor, ICON.constants.ambientSize, 'size'),
      fromVariant: titleTrailingSwap.variant,
    });
    titleTrailingHolder.appendChild(titleTrailing);
    titleTrailingHolder.visible = false;
    titleTrailingHolders.push(titleTrailingHolder);
    titleTrailingNodes.push(titleTrailing);
    c.appendChild(head);
    head.layoutSizingHorizontal = 'FILL';
    const titleRule = hostedDivider(page, lk, c, { axes: ruleAxes, color: ruleColor });
    // `_buildRows` is its own `Column(mainAxisSize: .min, spacing:
    // resolved.rowSpacing)`, so the rows are ONE child of the card column
    // rather than three of its siblings. That nesting is what lets
    // `rowSpacing` and `titleContentGapStyle` both land — Figma has a single
    // gap per frame, and flattening the two columns into one would force one
    // number to stand for both stated gaps.
    const rowsCol = panel('rows', 'VERTICAL', lk, { gap: sz.rowSpacing });
    c.appendChild(rowsCol);
    rowsCol.layoutSizingHorizontal = 'FILL';
    // Disabled dims the content only — see the `Disabled` note above.
    if (disabled) {
      for (const n of [head, titleRule, rowsCol]) bindLayerOpacity(n, lk, disabledContentOpacity);
    }
    rows.forEach((r, i) => {
      // Each row is `Padding(rowPadding)` around a Row whose children centre
      // on the cross axis; `showRowDividers` (default true) puts a `Divider`
      // between rows — under every row but the last.
      const row = panel('row', 'HORIZONTAL', lk, {
        gap: dimVal(f.rowLeadingGapStyle.size),
        pt: sz.rowPadding.t,
        pb: sz.rowPadding.b,
      });
      row.counterAxisAlignItems = 'CENTER';
      const term = makeLabel(r[0], lk, termOpts);
      row.appendChild(term);
      term.layoutSizingHorizontal = 'FILL';
      const value = makeLabel(r[1], lk, valueOpts);
      // `valueTextAlign` (end) — the value reads flush with the trailing edge.
      value.textAlignHorizontal = valueAlign;
      row.appendChild(value);
      rowsCol.appendChild(row);
      row.layoutSizingHorizontal = 'FILL';
      if (i < rows.length - 1) hostedDivider(page, lk, rowsCol, { axes: ruleAxes, color: ruleColor });
    });
    // `if (bottomAction != null) [Gap, if (showBottomActionDivider) [rule,
    // Gap], bottomAction]` — the rule rides inside the region because the
    // widget gates it on the same null check. Its gap is
    // `titleContentGapStyle` — the same one the card column carries, because
    // the widget spends that gap between the rule and the action too. The
    // action itself hugs and sits at the start, matching the column's
    // `crossAxisAlignment: .start`.
    const bottomHolder = panel('bottomAction', 'VERTICAL', lk, { gap: sz.titleContentGapStyle.size });
    c.appendChild(bottomHolder);
    bottomHolder.layoutSizingHorizontal = 'FILL';
    // The bottom region dims with the rest of the content when disabled.
    if (disabled) bindLayerOpacity(bottomHolder, lk, disabledContentOpacity);
    hostedDivider(page, lk, bottomHolder, {
      axes: ruleAxes,
      color: ruleColor,
    });
    const bottomAction = instanceOf(page, 'Button', bottomActionVariant);
    setInstanceText(bottomAction, _kDescriptionCardBottomActionLabel);
    bottomHolder.appendChild(bottomAction);
    bottomHolder.visible = false;
    bottomActionHolders.push(bottomHolder);
    bottomActionNodes.push(bottomAction);
  }
  const set = mount.finish();
  const titleLeadingProp = defineProp(set, 'TitleLeading', 'INSTANCE_SWAP', titleLeadingSwap.id);
  for (const n of titleLeadingNodes) bindSwapProp(n, titleLeadingProp);
  const titleLeadingShownProp = defineProp(set, 'Show titleLeading', 'BOOLEAN', true);
  for (const n of titleLeadingHolders) bindVisibleProp(n, titleLeadingShownProp);
  const titleTrailingProp = defineProp(set, 'TitleTrailing', 'INSTANCE_SWAP', titleTrailingSwap.id);
  for (const n of titleTrailingNodes) bindSwapProp(n, titleTrailingProp);
  const titleTrailingShownProp = defineProp(set, 'Show titleTrailing', 'BOOLEAN', false);
  for (const n of titleTrailingHolders) bindVisibleProp(n, titleTrailingShownProp);
  const bottomActionProp = defineProp(
    set,
    'BottomAction',
    'INSTANCE_SWAP',
    mainIdOf(page, 'Button', bottomActionVariant),
  );
  for (const n of bottomActionNodes) bindSwapProp(n, bottomActionProp);
  const bottomActionShownProp = defineProp(set, 'Show bottomAction', 'BOOLEAN', false);
  for (const n of bottomActionHolders) bindVisibleProp(n, bottomActionShownProp);
  return set;
}

// ─── EmptyState ──────────────────────────────────────────────────────────────

// Data-driven from coui_core: EMPTY_STATE.fields (maxTextWidth, the
// title / description typography, the icon box radius) +
// .variants.defaultsByVariant (padding, floor, icon size, icon box size, the
// three row gaps and the title / description roles — per member) +
// .variants.defaultsByTone (the icon colour and the icon box fill). The stack
// draws no panel of its own — no border, no radius, no fill — so the only
// chrome on the member frame is its padding; the glyph sits in a circular
// icon box.
//
// A single Figma auto-layout `itemSpacing` can't express the real component's 3
// distinct row gaps (iconTitleGap/titleDescriptionGap/descriptionActionGap)
// without adding new Gap nodes, so this builder adds them: one spacer per
// stated gap, and no `itemSpacing` on the column at all.
//
// `empty_state.axes` declares the Variant members (`normal` / `compact` / `large`) and no
// Size/State/Enabled, so `axisSpecsOf` contributes those two and the loose
// COMPONENT is promoted into one of them in place, keeping its key.
// `CoreEmptyStateTone` is appended as a POSE axis rather than left unpromoted:
// the tone is the icon's own colour (`on-surface-variant` on `neutral`, `error`
// on `failure`), so a tone that only changed the announcement would be
// indistinguishable from absence on screen.
//
// The title is the field's style with the member's `titleTextStyle` merged on
// top — the way both resolvers compose it. `compact` restates only the role
// (`titleSmall`) and keeps the field's colour; reading the field alone drew
// every member at `normal`'s `titleMedium`.
//
// `title` / `description` / `icon` / `action` are the four composition slots, and
// each gets the property its node's shape allows.
//
// The action is an INSTANCE of `Button`. `CoreEmptyStateStyle` forwards no
// button style slot, so this is not a composition the widget performs — it is
// the DEFAULT of an INSTANCE_SWAP, which is the only shape a `W?` slot can
// take in Figma. A drawn frame accepts no swap, so whatever it looked like
// would be the only thing the slot could ever hold; a real Button as the
// placeholder lets a designer put something else there.
const _kEmptyStateActionLabel = '항목 추가';

// Caps a frame at [w] and binds the cap to its `layout/N` step: FILL up to the
// cap, centred past it, shrinking with a narrower host. A FRAME, not a label —
// Figma binds a variable to a frame's `maxWidth` and refuses it on a TEXT node
// (`invalid field for text node: 'maxWidth'`), so the cap has to sit on the
// block that holds the labels, which is also where both widgets put it.
function capFrameWidth(node: FrameNode, lk: VarLookup, w: number): void {
  node.maxWidth = w;
  node.setBoundVariable('maxWidth', lk.layout(w));
}

/** The Button the EmptyState example action draws from, per density: a
 *  panel's empty slot takes the small button, a page-level one the default
 *  (#6468) — the widget's `action` is a caller slot, so this is the canvas's
 *  own example. */
const kEmptyStateActionSizeByVariant: Record<string, string> = {
  compact: 'sm',
  normal: 'md',
  large: 'md',
};

function emptyStateActionAxes(variant: string): Record<string, string> {
  return {
    Variant: 'primary',
    Size: kEmptyStateActionSizeByVariant[variant] ?? 'md',
    State: 'enabled',
    Shape: 'rectangle',
  };
}

function buildEmptyState(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = EMPTY_STATE.fields;
  const variantData = new Map(Object.entries(EMPTY_STATE.variants.defaultsByVariant));
  // The variant the code defaults to (`CoreEmptyStateVariant.defaultVariant`,
  // carried by the export). It sizes the `Icon` swap default on a document
  // that has none yet, and takes the set's top-left corner — the member Figma
  // hands a fresh instance.
  const defaultVariantName = EMPTY_STATE.axes.variant.default;
  const defaultVariantData = variantData.get(defaultVariantName);
  if (!defaultVariantData) {
    throw new Error(`EmptyState: no data for the default variant "${defaultVariantName}"`);
  }
  const toneData = new Map(Object.entries(EMPTY_STATE.variants.defaultsByTone));
  const combos = enumerateAxisCombos([
    ...axisSpecsOf(EMPTY_STATE.axes),
    { axis: 'Tone', values: [...toneData.keys()] },
  ]);
  // The glyph is drawn from the `Icon` property's default, the one the
  // document already holds if it has one, so the first bind leaves every
  // member's icon at its own side (see `IconOpts.fromVariant`, #5246 / #5247).
  const iconSwap = iconSwapDefault(
    page,
    'EmptyState',
    'Icon',
    iconMainIdAt(page, dimVal(defaultVariantData.iconSize)),
  );
  // The legacy static node drew the `normal` variant with no tone distinction at
  // all, which is the neutral one — so that is the combination it is promoted
  // into, in place, keeping its key.
  const mount = mountSet(page, 'EmptyState', combos, {
    adoptLooseAs: 'Variant=normal, Tone=neutral',
  });
  const titleNodes: TextNode[] = [];
  const descNodes: TextNode[] = [];
  const iconNodes: InstanceNode[] = [];
  const iconBoxes: FrameNode[] = [];
  // The gap that precedes each optional slot is bound to the same BOOLEAN
  // as the slot itself — hiding a slot with its spacer left behind would
  // put a gap where the code puts nothing (both widgets render the gap
  // inside the same `if` as its slot).
  const iconGaps: FrameNode[] = [];
  const descGaps: FrameNode[] = [];
  const actionGaps: FrameNode[] = [];
  const actionHolders: FrameNode[] = [];
  const actionNodes: InstanceNode[] = [];
  for (const comboName of combos) {
    const combo = parseVariantKey(comboName);
    const variant = variantData.get(combo['Variant']);
    if (!variant) throw new Error(`EmptyState: no data for combo "${comboName}"`);
    const tone = toneData.get(combo['Tone']);
    if (!tone) throw new Error(`EmptyState: no tone data for combo "${comboName}"`);
    const c = mount.getOrCreate(comboName);
    // Padding only. The 2026-09-14 redesign removed the panel entirely —
    // no border, no radius, no fill — so the stack now sits directly on
    // whatever surface hosts it and the four chrome fields this call used
    // to read (`borderColor` / `borderAlpha` / `borderWidth` /
    // `borderRadius`) no longer exist in `CoreEmptyStateStyle`.
    applyPanelCompChrome(c, 'VERTICAL', lk, {
      pl: variant.padding.l, pr: variant.padding.r, pt: variant.padding.t, pb: variant.padding.b,
    });
    // `minHeight` — the floor both resolvers state (`ConstrainedBox` on
    // Flutter, `min-h-*` on Web). It is the VARIANT's own: `normal` holds the
    // 240 step, `compact` states none and hugs its content. Same shape Alert
    // and Banner use, bound to the layout group rather than spacing because
    // that is where `CoreLayout.layout240` lives.
    const floor = dimVal(variant.minHeight);
    if (floor > 0) {
      c.minHeight = floor;
      c.setBoundVariable('minHeight', lk.layout(floor));
    } else {
      c.setBoundVariable('minHeight', null);
      c.minHeight = null;
    }
    // No `gap`: the widget interleaves THREE different `Gap`s down this column
    // (`iconTitleGapStyle`, `titleDescriptionGapStyle`,
    // `descriptionActionGapStyle` — 16 / 8 / 24 at `normal`, 10 / 10 / 10 at
    // `compact`) and Figma gives a frame one `itemSpacing`. The single gap
    // carried `iconTitleGapStyle` and spent it in all three places, so two of
    // the three were wrong on every member and `descriptionActionGapStyle`
    // reached no node at all.
    c.primaryAxisAlignItems = 'CENTER';
    c.counterAxisAlignItems = 'CENTER';
    // The widget states no width of its own — the stack fills its host and
    // only the title + description are capped at `maxTextWidth` (400). A
    // Figma COMPONENT still needs one, so the member is drawn at the width
    // where that cap is reached: the cap plus this member's side padding.
    // The text then wraps at 400 here as it does on a wide screen, and an
    // instance laid into a narrower slot (FILL) shrinks it the way the
    // widget shrinks — the cap rides on the text block, below, not on the
    // member. Locking the member itself at 400 put the cap on the wrong node:
    // the text got 336 / 368, and a host narrower than 400 clipped it.
    if (combo['Variant'] === 'compact') {
      // `compact` sits inside a panel that is usually narrower than the
      // text cap, so a member drawn at the cap reads as a page-level block.
      // The canvas draws it at a panel's width instead (#6468); the widget
      // is unchanged — it still fills its host and caps the text at 400.
      // g7-preview-only: EmptyState compact preview width, no width field in the code
      lockWidth(c, 300);
    } else {
      lockWidth(c, dimVal(f.maxTextWidth) + dimVal(variant.padding.l) + dimVal(variant.padding.r));
    }
    // Both tones state their glyph colour outright — `neutral`
    // `on-surface-variant`, `failure` Semantic/error. That colour *is* the
    // tone axis: a tone that only changed the announcement would be
    // indistinguishable from absence on screen. No alpha any more —
    // `iconColorAlpha` is gone and the glyph paints its token at full
    // strength.
    const iconColor = colorData(
      optField<{ color?: Color }>(tone, 'iconStyle')?.color,
    );
    // The glyph sits in a circular icon box: `iconBoxSize` on a side (64 /
    // 48 / 72), `iconBoxBorderRadius` (the scale's fully-round step) and the
    // tone's `iconBoxColor` as its fill. The box centres the glyph, which is
    // drawn at `iconSize` (28 / 24 / 32) in the tone's icon colour. A circle
    // that is a rounded square keeps following the stated radius, so this is a
    // frame bound to the radius rather than an ellipse.
    const iconBox = autoFrame('icon box', 'HORIZONTAL');
    iconBox.primaryAxisAlignItems = 'CENTER';
    iconBox.counterAxisAlignItems = 'CENTER';
    bindSize(iconBox, lk, variant.iconBoxSize, variant.iconBoxSize);
    bindRadiusN(iconBox, lk, EMPTY_STATE.fields.iconBoxBorderRadius.topLeft);
    fillData(iconBox, lk, colorData(tone.iconBoxColor));
    const icon = makeIcon('inbox', lk, {
      ...glyphOpts(lk, iconColor, variant.iconSize, 'size'),
      fromVariant: iconSwap.variant,
    });
    iconBox.appendChild(icon);
    c.appendChild(iconBox);
    iconNodes.push(icon);
    iconBoxes.push(iconBox);
    const iconGap = gapSpacer('icon-title gap', lk, variant.iconTitleGapStyle.size);
    c.appendChild(iconGap);
    iconGaps.push(iconGap);
    const titleStyle = mergeTextStyleData(
      textStyleData(f.titleTextStyle),
      textStyleData(variant.titleTextStyle),
    );
    // The widgets' text block: title, its gap and the description in one
    // column capped at `maxTextWidth` — Flutter's `ConstrainedBox(maxWidth:)`
    // around a `Column`, Web's `max-w-layout400` wrapper `<div>`.
    const textBlock = autoFrame('text', 'VERTICAL');
    textBlock.counterAxisAlignItems = 'CENTER';
    c.appendChild(textBlock);
    textBlock.layoutSizingHorizontal = 'FILL';
    capFrameWidth(textBlock, lk, dimVal(f.maxTextWidth));
    const title = makeLabel('아직 항목이 없어요', lk, textLabelOpts(lk, titleStyle));
    // Centred and wrapping, like the description — both widgets set
    // `textAlign: center` on the two.
    title.textAlignHorizontal = 'CENTER';
    textBlock.appendChild(title);
    title.layoutSizingHorizontal = 'FILL';
    titleNodes.push(title);
    const descGap = gapSpacer(
      'title-description gap',
      lk,
      variant.titleDescriptionGapStyle.size,
    );
    textBlock.appendChild(descGap);
    descGaps.push(descGap);
    // The description now owns its own colour — the redesign gave
    // `defaultDescriptionTextStyle` the `on-surface-variant` token outright,
    // so the old shape (the TITLE's hue held at `descriptionAlpha`) is gone
    // and `textLabelOpts` carries role + colour together.
    const desc = makeLabel(
      '첫 항목을 추가해 시작해 보세요.',
      lk,
      textLabelOpts(
        lk,
        mergeTextStyleData(
          textStyleData(f.descriptionTextStyle),
          textStyleData(
            optField<Parameters<typeof textStyleData>[0]>(variant, 'descriptionTextStyle'),
          ),
        ),
      ),
    );
    desc.textAlignHorizontal = 'CENTER';
    textBlock.appendChild(desc);
    desc.layoutSizingHorizontal = 'FILL';
    descNodes.push(desc);
    const actionGap = gapSpacer(
      'description-action gap',
      lk,
      variant.descriptionActionGapStyle.size,
    );
    c.appendChild(actionGap);
    actionGaps.push(actionGap);
    const actionHolder = slotHolder('action');
    c.appendChild(actionHolder);
    const action = instanceOf(
      page,
      'Button',
      bestVariantName(page, 'Button', emptyStateActionAxes(combo['Variant'])),
    );
    setInstanceText(action, _kEmptyStateActionLabel);
    actionHolder.appendChild(action);
    actionHolders.push(actionHolder);
    actionNodes.push(action);
  }
  const set = mount.finish();
  const titleProp = defineProp(set, 'Title', 'TEXT', '아직 항목이 없어요');
  for (const n of titleNodes) bindTextProp(n, titleProp);
  const descProp = defineProp(set, 'Description', 'TEXT', '첫 항목을 추가해 시작해 보세요.');
  for (const n of descNodes) bindTextProp(n, descProp);
  // Binding the `Icon` swap property puts its default in place of every bound
  // instance. Measured on the canvas: members holding a 48 and a 32 both
  // turned 24×24 (the Icon set's own default) the moment they were bound, and
  // swapping one back rewrites the shared default rather than that member.
  // One default cannot hold two sizes. So each icon is drawn FROM the default
  // and rescaled to its own side (`iconSwap` above), and the bind then changes
  // nothing. A rescale is a per-member size, which the canvas keeps across a
  // Variant switch and a designer's later glyph swap (both measured).
  //
  // The default is only what a FIRST run declares: `defineProp` keeps an
  // existing INSTANCE_SWAP default, so a set first drawn before #5216 still
  // defaults to the 24 step. Drawing from that step is fine: a 24 scaled to 48
  // draws the 48 step's stroke too (4, measured). A default this run cannot
  // instance (not a local `Icon` variant) falls back to `bindSwapProp`'s
  // rescale after the bind lands.
  const iconProp = defineProp(set, 'Icon', 'INSTANCE_SWAP', iconSwap.id);
  for (const n of iconNodes) bindSwapProp(n, iconProp);
  // No `Action` INSTANCE_SWAP: a swap property holds one default for the
  // whole set, and binding it redraws every member's action at that default
  // (measured with a throwaway set — swapping one member's button rewrote the
  // shared default and every other member's instance followed). The members
  // need different sizes, so each holds its own Button and exposes it: the
  // designer picks the button one level in, from this set's panel — the
  // mechanism the other composed slots use (`layout.ts` disclosure). A file
  // that still has the old property loses it in the unbound-property sweep.
  for (const n of actionNodes) {
    try {
      n.isExposedInstance = true;
    } catch {
      // Older document doubles have no exposure; the member still draws its
      // own button.
    }
  }
  const actionShownProp = defineProp(set, 'Show action', 'BOOLEAN', true);
  for (const n of actionHolders) bindVisibleProp(n, actionShownProp);
  for (const n of actionGaps) bindVisibleProp(n, actionShownProp);
  // `showIcon` / `showDescription` — the two booleans the redesign added.
  // Each drives its slot AND the spacer in front of it, which is why the
  // gaps were collected above.
  const iconShownProp = defineProp(set, 'Show icon', 'BOOLEAN', true);
  for (const n of iconBoxes) bindVisibleProp(n, iconShownProp);
  for (const n of iconGaps) bindVisibleProp(n, iconShownProp);
  const descShownProp = defineProp(set, 'Show description', 'BOOLEAN', true);
  for (const n of descNodes) bindVisibleProp(n, descShownProp);
  for (const n of descGaps) bindVisibleProp(n, descShownProp);
  // After the icons are back at their own sizes, so the grid measures the
  // members as drawn. `normal` is the taller row, and the height ladder alone
  // would hand the corner — the set's default — to `compact`.
  defaultSetLayout(set, { Variant: defaultVariantName });
  return set;
}

// ─── Indicator (badge overlay) ───────────────────────────────────────────────

// `child` and `item` are both REQUIRED `W` slots, and both are INSTANCES —
// `Avatar` and `Badge`, which is what indicator.dart's own doc example passes
// (`item: Badge(tone: .destructive, variant: .filled, form: .count, size: .xs,
// child: Text('99+')), child: Avatar(initials: 'DW')`). They
// were plain drawn frames, and a drawn frame accepts no INSTANCE_SWAP, so
// whatever those two frames looked like was the only thing either slot could
// ever hold. Neither is a composition the widget performs — `CoreIndicatorStyle`
// forwards no style slot to either — they are the swap DEFAULTS, which is the
// only shape a `W` slot has in Figma.
//
// `offset` is applied now, and could not be before. It is a delta against the
// child's box, so it needs both boxes to be real; two hand-drawn frames only
// had the sizes this file invented for them, and applying a design-system
// offset to an invented box would have asserted geometry coui_core never
// stated. An instance carries its main component's own box, so the placement
// below is `Stacks([child, Position(top: offset, right: offset, child: item)])`
// — the stack sizes to the child, and the badge overhangs it (`clipBehavior:
// .none`), which is why nothing here clips.

function buildIndicator(page: PageNode, lk: VarLookup): ComponentNode {
  const offset = dimVal(INDICATOR.fields.offset);
  const c = mint(page, 'Indicator');
  c.fills = [];
  c.clipsContent = false;
  const childVariant = bestVariantName(page, 'Avatar', { Size: 'md', ...kAvatarRest });
  const child = instanceOf(page, 'Avatar', childVariant);
  child.name = 'child';
  // Pinned through a holder that STRETCHes on both axes: the `Stacks` sizes to
  // this child in the widget, so when a designer sizes the instance the child
  // is what the box is made of. An instance cannot carry constraints itself,
  // which is what `pinAbsolute` wraps for (#4805).
  const childHolder = pinAbsolute(c, child, 0, 0, { horizontal: 'STRETCH', vertical: 'STRETCH' });
  // The `> 0` guard is for the runtime harness, whose nodes have no layout
  // engine and report 0 on a hug auto-layout; Figma rejects `resize(0, …)`.
  // In Figma both read the main component's real box.
  if (child.width > 0 && child.height > 0) {
    c.resize(child.width, child.height);
    sizePin(childHolder, child.width, child.height);
  }
  // A destructive dot at `md` — the Badge `Style=dot` form, sized by the
  // designer's set (the widget takes whatever `item` the caller hands it, so the
  // size is the sample's, not a field). It sits in a ring: a `surface`-coloured
  // pill `ringWidth` wide around it that cuts the item out of the child it
  // overlaps. The ring overhangs the item, so the ITEM's corner meets the child's
  // corner — `Position(top: offset - ring, right: offset - ring)` around the ring.
  const itemVariant = bestVariantName(page, 'Badge', {
    Tone: 'destructive',
    Variant: 'filled',
    Size: 'md',
    Style: 'dot',
  });
  const item = instanceOf(page, 'Badge', itemVariant);
  item.name = 'item';
  const ring = dimVal(INDICATOR.fields.ringWidth);
  const itemWidth = item.width;
  const itemHeight = item.height;
  const ringed = pinAbsolute(c, item, c.width - offset - itemWidth - ring, offset - ring, {
    horizontal: 'MAX',
    vertical: 'MIN',
  }) as FrameNode;
  ringed.name = 'ring';
  ringed.paddingLeft = ring;
  ringed.paddingRight = ring;
  ringed.paddingTop = ring;
  ringed.paddingBottom = ring;
  fillData(ringed, lk, colorData(INDICATOR.fields.ringColor));
  bindRadiusN(ringed, lk, INDICATOR.fields.ringBorderRadius.topLeft);
  sizePin(ringed, itemWidth + 2 * ring, itemHeight + 2 * ring);
  const owner = propertyOwner(c);
  bindSwapProp(
    child,
    defineProp(owner, 'Child', 'INSTANCE_SWAP', mainIdOf(page, 'Avatar', childVariant)),
  );
  bindSwapProp(
    item,
    defineProp(owner, 'Item', 'INSTANCE_SWAP', mainIdOf(page, 'Badge', itemVariant)),
  );
  return c;
}

// ─── DotIndicator ────────────────────────────────────────────────────────────

// Data-driven from coui_core: DOT_INDICATOR.fields (padding / borderRadius /
// colours / inactiveBorderWidth / focusOutlineStyle) + DOT_INDICATOR.sizes
// .defaultsBySize (dotSize / spacing per `CoreDotIndicatorSize` rung). An
// inactive dot is a solid `inactiveColor` disc whose border shares the token
// (`inactiveBorderColor` / `inactiveBorderWidth`) — the designer's decision;
// the active dot is told apart by colour, and hover lands on the border.
//
// ─── Axes — `Size` × `Selected` ─────────────────────────────────────────────
//
// `Size` is the contract's own: `CoreDotIndicatorContract.size` picks the
// `defaultsBySize` rung, so the members are read off the exported enum (the
// `FocusOutline` / `Button` precedent — a member the contract no longer backs
// cannot be minted) and each member's dot diameter + gap come from that rung's
// row. Those are the two dimensions the designer's set binds per size
// (`size/N` on the dots, `space/N` on the gap, the same `N`); padding is one
// value for every rung and comes from the flat field.
//
// `Selected` is a builder-declared pose axis — which drawn dot is current,
// 1-indexed: `Selected=N` is the widget's `index = N-1`, one-based because a
// designer reads it in the Figma panel. It is the same numeric `Selected`
// `Filter` poses on, so `kRestingAxisValue` already rests it at `1`. Declared
// rather than derived because the widget states its selection as a VALUE
// (`index: int`), which no promotion predicate reaches. Only the dots shown
// by default are selectable — a pose on a hidden dot would draw nothing.
//
// The member names are byte-identical to the designer's set (`Size=sm,
// Selected=1` …): `kAxisOrder` seats `Size` before `Selected` and
// `composeVariantName` spells them from that order, so no `VARIANT_RENAMES`
// row is needed. The lone COMPONENT this builder used to mint is retired by
// `STRUCTURAL_MIGRATIONS` (src/renames.ts) on a document that still has it —
// Figma cannot convert a COMPONENT into a COMPONENT_SET in place, and two
// same-named nodes split their consumers (the `FocusOutline` lesson).
//
// ─── Properties — `Show dot 3` … `Show dot 8` ───────────────────────────────
//
// Eight dots are drawn. `length` is a runtime count the canvas cannot take as
// a number, so the count is the set of BOOLEANs the designer's set carries:
// dots 3–5 ship shown, 6–8 hidden, and dots 1 and 2 have no property at all —
// an indicator with fewer than two positions is not one (`length >= 2`).
//
// ─── Composition ────────────────────────────────────────────────────────────
//
// The selected dot is wrapped in an INSTANCE of `FocusOutline` — the widget
// does exactly that, and only there: `i == widget.index ? FocusOutline(focused:
// _groupFocused, shape: .circle, focusOutlineStyle: resolved.focusOutlineStyle,
// child: dot) : dot`. The `shape` is the child's `Shape=circle` member, which
// is what makes `circleBorderRadius` the radius its ring follows — the axis
// reads that field, so nothing here restates it. What IS written is the rest
// of the forward, `borderColor` and `borderWidth`, and it lands on the child's
// ring layer rather than on the instance root, which under the child's shape
// is the dot's own box. The other dots are bare, which is the whole point of
// the wrap being on one of them.
//
// `Clickable` is the fourth thing dot_indicator.dart composes and the one
// child with nothing to draw: it contributes gesture, cursor and focus
// wiring, and every pixel it is responsible for here — the focus ring — is
// already on the canvas as the `FocusOutline` instance above. An instance of
// it would be an empty frame asserting a region that has no chrome.
// `CoreDotIndicatorContract` declares no composition slot either, so the only
// properties are the visibility BOOLEANs above.

// The dots a member draws, 1-indexed the way the `Selected` axis and the
// designer's `Show dot N` properties count them.
const kDotIndicatorDotOrdinals = ['1', '2', '3', '4', '5', '6', '7', '8'] as const;

// Dots 1..N always draw and carry no `Show dot N` — `length >= 2`.
const kDotIndicatorAlwaysShown = 2;

// The first dot that ships hidden. Dots below it are shown by default (and
// are the ones a member may pose as selected); this one and above are the
// designer's reachable extras.
const kDotIndicatorHiddenFrom = 6;

// The rung the loose COMPONENT is adopted under — `CoreDotIndicatorSize
// .defaultSize`, the widget's own `this.size = …`. The exporter carries an
// enum's default only for the Variant axis, so it is spelled here the way
// `Progress` / `Loading` spell theirs, and checked against the exported
// members below so an enum change fails loudly instead of adopting a name
// the enumeration no longer produces.
const kDotIndicatorRestingSize = 'md';

/** One member's hide-able dots, keyed by ordinal, kept for the binds after `finish()`. */
interface DotIndicatorMember {
  dots: Map<string, SceneNode>;
}

function buildDotIndicator(page: PageNode, lk: VarLookup): ComponentSetNode {
  // The default active marker uses the resolved dot diameter. Do not keep
  // drawing circles if the exporter no longer states that relationship.
  const derived = DOT_INDICATOR.derivedDefaults as Record<string, string>;
  if (derived.activeLength !== 'dotSize') {
    throw new Error('DotIndicator: activeLength default is not derived from dotSize');
  }
  const f = DOT_INDICATOR.fields;
  const size = DOT_INDICATOR.axes.other.find((o) => o.enum === 'CoreDotIndicatorSize');
  if (!size) {
    throw new Error(
      'DotIndicator: CoreDotIndicatorSize is gone from the exported axes — the ' +
        'canvas has a Size axis that nothing in the contract now backs.',
    );
  }
  if (size.members.indexOf(kDotIndicatorRestingSize) < 0) {
    throw new Error(
      `DotIndicator: resting size "${kDotIndicatorRestingSize}" is not a member of ` +
        `CoreDotIndicatorSize (${size.members.join(' | ')}) — update kDotIndicatorRestingSize.`,
    );
  }
  const sizeData = new Map(Object.entries(DOT_INDICATOR.sizes.defaultsBySize));
  const selectable = kDotIndicatorDotOrdinals.filter(
    (ordinal) => Number(ordinal) < kDotIndicatorHiddenFrom,
  );
  const assignments = enumerateAxisAssignments([
    { axis: 'Size', values: size.members },
    { axis: 'Selected', values: selectable },
  ]);
  // The loose COMPONENT drew the default rung with the first dot selected —
  // exactly the resting member — so it is adopted under that name, and its
  // node id (and every instance pointing at it) survives the promotion. Inert
  // on a document that already carries the set, which is where this one lives.
  const mount = mountSet(
    page,
    'DotIndicator',
    assignments.map((a) => a.name),
    {
      adoptLooseAs: composeVariantName([
        ['Size', kDotIndicatorRestingSize],
        ['Selected', restingValueOf('Selected')],
      ]),
    },
  );
  const active = colorData(f.activeColor);
  const inactiveBorder = colorData(f.inactiveBorderColor);
  const ringStyle = f.focusOutlineStyle;
  const members: DotIndicatorMember[] = [];
  for (const { name, values } of assignments) {
    const sz = sizeData.get(values['Size']);
    if (!sz) throw new Error(`DotIndicator: no size data for member "${name}"`);
    const selected = values['Selected'];
    const c = mount.getOrCreate(name);
    // `padding` is spent exactly as an auto-layout frame does: `padding.top`/
    // `bottom` on every dot, `padding.left` on the first and `padding.right` on
    // the last, with `spacing / 2` on both inner edges of each gap — which sums
    // to `spacing` between neighbours. So the frame's four insets plus
    // `itemSpacing` reproduce it exactly.
    applyPanelCompChrome(c, 'HORIZONTAL', lk, {
      gap: sz.spacing,
      pl: f.padding.l,
      pt: f.padding.t,
      pr: f.padding.r,
      pb: f.padding.b,
    });
    c.counterAxisAlignItems = 'CENTER';
    const side = dimVal(sz.dotSize);
    const dots = new Map<string, SceneNode>();
    for (const ordinal of kDotIndicatorDotOrdinals) {
      // A rounded RECTANGLE, not an ellipse. Both dots are
      // `AnimatedContainer(decoration: BoxDecoration(borderRadius:
      // resolved.borderRadius), width: dotSize, height: dotSize)` — a square
      // whose corners the field rounds. The default is the full-round token, so
      // an ellipse drew the right picture and stated a shape the widget cannot
      // be given: a caller who sets `borderRadius: radius0` gets squares in the
      // app and ellipses on the canvas. This is `dot_indicator.dart`'s own note,
      // which says the primitive scale is what selects the shape.
      const dot = figma.createRectangle();
      bindSize(dot, lk, sz.dotSize, sz.dotSize);
      bindRadiusN(dot, lk, f.borderRadius.topLeft);
      let node: SceneNode = dot;
      if (ordinal === selected) {
        // The active dot is filled AND stroked in the same colour at the
        // inactive width — the widget states both, and the stroke is what
        // makes the two dots the same overall size.
        fillData(dot, lk, active);
        borderData(dot, lk, active, f.inactiveBorderWidth);
        // `Shape=circle` by name — `dot_indicator.dart` passes `shape: .circle`,
        // and that member's own ring already carries `circleBorderRadius`.
        const ring = instanceOf(page, 'FocusOutline', 'Shape=circle');
        ring.name = 'focus ring';
        // FocusOutline hugs its `child` slot, which its own builder draws at
        // preview size. Shrinking that slot to the dot is what makes the ring
        // hug the dot instead of a 160×48 placeholder — an ordinary override,
        // and if the slot is ever renamed the ring simply keeps its preview
        // size.
        // Stated, not inherited. The component's own defaults are off now,
        // but an instance that already exists on the designer's file carries
        // whatever it was created with — and these two were created when the
        // defaults were on, which is why the placeholder glyph and a resting
        // focus ring survived several Generates beside every dot.
        setInstanceBoolNamed(ring, 'Show child', false);
        setInstanceBoolNamed(ring, 'Focused', false);
        const slot = instanceFrameSlot(ring, 'child');
        if (slot) slot.resize(side, side);
        // The slot resize alone left the ring at its main's size on the live
        // canvas — the instance did not re-hug. So the box is stated outright,
        // and it is the DOT's own box: the child's builder draws the offset
        // band and the ring as layers hanging outside that box (both pinned
        // with STRETCH, so this resize carries them).
        ring.resize(side, side);
        // The forward, painted on the child's ring RECTANGLE rather than on
        // the instance root: the root is the dot's own box and carries no
        // stroke, so writing there would draw a second ring flush against the
        // dot. Both values equal the child's own defaults today, and they are
        // written anyway — the widget really does forward this slot, so a
        // future divergence between the two should land on the canvas instead
        // of being silently absorbed by a coincidence.
        borderData(
          focusOutlineRing(ring),
          lk,
          colorData(ringStyle.borderColor),
          ringStyle.borderWidth,
        );
        const cell = figma.createFrame();
        cell.layoutMode = 'NONE';
        cell.fills = [];
        // The ring's layers overhang the dot; a clipping cell would cut them.
        cell.clipsContent = false;
        cell.resize(side, side);
        cell.appendChild(ring);
        ring.x = 0;
        ring.y = 0;
        cell.appendChild(dot);
        dot.x = 0;
        dot.y = 0;
        node = cell;
      } else {
        // Solid muted disc — `inactiveColor` is stated (the designer's
        // decision); the border shares its token so the two read as one.
        fillData(dot, lk, colorData(f.inactiveColor));
        borderData(dot, lk, inactiveBorder, f.inactiveBorderWidth);
      }
      // The designer's own layer names — `dot 1` … `dot 8` — on whichever
      // node stands for the dot in the row (the cell, when it is selected).
      node.name = `dot ${ordinal}`;
      if (Number(ordinal) >= kDotIndicatorHiddenFrom) node.visible = false;
      c.appendChild(node);
      dots.set(ordinal, node);
    }
    members.push({ dots });
  }
  const set = mount.finish();
  // Properties AFTER `finish()`, on the set — the only moment the owner exists
  // (`form.ts`'s Button records why). Names are the designer's, adopted by
  // `defineProp` (name + type) rather than minted a second time.
  const showIds = new Map<string, string | null>();
  for (const ordinal of kDotIndicatorDotOrdinals) {
    if (Number(ordinal) <= kDotIndicatorAlwaysShown) continue;
    showIds.set(
      ordinal,
      defineProp(set, `Show dot ${ordinal}`, 'BOOLEAN', Number(ordinal) < kDotIndicatorHiddenFrom),
    );
  }
  for (const member of members) {
    for (const [ordinal, id] of showIds) {
      const node = member.dots.get(ordinal);
      if (node) bindVisibleProp(node, id);
    }
  }
  vStackSet(set);
  return set;
}

// ─── Loading ─────────────────────────────────────────────────────────────────

// LOADING has two real axes (variant 4 × size 5) and each variant paints a
// *different shape* — a rotating ring, three fading dots, a sliding bar, a
// scaling circle. A single 3-dot rendering at a fixed 10 px diameter showed
// one of those twenty states and read as if the other nineteen didn't exist.
//
// #4036 (C4a) — `loading.axes` declares the four Variant members and no
// Size/State/Enabled, so `axisSpecsOf` contributes the variants and `Size` is
// appended as a POSE axis off `sizes.defaultsBySize` (five rows, and every
// dimension below is derived from the row's `size`). The loose COMPONENT is
// promoted in place, keeping its key: it drew the DOTS variant, which is the
// half of the combination it actually states — its 10 px dots match no size row
// at all, so `md` is named as the row the promotion lands on rather than as a
// claim about what the legacy node measured.
//
// Every dimension here comes from the size row (`size`, `dotSize`, `barHeight`)
// and the shape ratios `CoreLoadingStyle` carries (`barLengthRatio`,
// `barFillRatio`, `pulseDotRatio`, `pulseHaloAlpha`): the same numbers both
// widgets paint with. Dots sit `dotGapRatio` (half a dot) apart, the row
// centred in the `size` square. The static frame of an animated indicator is
// one pose of its cycle — dots at the start of the wave (the three
// `dotWave*Opacity` levels left to right, the frame both widgets draw at
// `t = 0`), bar fill at the start of its travel, pulse halo at full size,
// spinner arc a quarter turn. A still canvas cannot show the wave travel;
// the per-dot opacities are the pose that names it.
const LOADING_DOT_WAVE = [
  LOADING.constants.dotWaveLeadOpacity,
  LOADING.constants.dotWaveMidOpacity,
  LOADING.constants.dotWaveTailOpacity,
];

interface LoadingToneRow {
  color: Parameters<typeof colorData>[0];
  trackColor?: Parameters<typeof colorData>[0];
  trackAlpha?: Parameters<typeof dimVal>[0];
}

function buildLoading(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = LOADING.fields;
  const sizeData = new Map(Object.entries(LOADING.sizes.defaultsBySize));
  const toneData = new Map(
    Object.entries(LOADING.variants.defaultsByTone as Record<string, LoadingToneRow>),
  );
  const combos = enumerateAxisCombos([
    ...axisSpecsOf(LOADING.axes),
    { axis: 'Size', values: [...sizeData.keys()] },
    { axis: 'Tone', values: [...toneData.keys()] },
  ]);
  const mount = mountSet(page, 'Loading', combos, {
    adoptLooseAs: 'Variant=dots, Size=md, Tone=primary',
  });
  const radius = f.cornerRadius;
  const arcSweep = (dimVal(LOADING.constants.arcSweepDegrees) * Math.PI) / 180;
  for (const comboName of combos) {
    const combo = parseVariantKey(comboName);
    const vn = combo['Variant'];
    const toneRow = toneData.get(combo['Tone']);
    if (!toneRow) throw new Error(`Loading: no tone data for combo "${comboName}"`);
    // The tone's own indicator colour, and its track: a neutral token when the
    // tone states one (`trackColor`), otherwise the indicator colour faded to
    // the tone's alpha (`inverse` states its own, the rest take the field's).
    // `primary` IS the field's resting colour (`CoreLoadingStyle.defaultColor`);
    // the other tones state their own.
    const toneColor = combo['Tone'] === 'primary' ? f.color : toneRow.color;
    const tint = colorData(toneColor)?.color ?? 'primary';
    const trackToken = toneRow.trackColor ? colorData(toneRow.trackColor)?.color : undefined;
    const trackTint = trackToken ?? tint;
    const trackAlpha = trackToken
      ? 1
      : dimVal(toneRow.trackAlpha ?? f.trackAlpha);
    const sz = sizeData.get(combo['Size']);
    if (!sz) throw new Error(`Loading: no size data for combo "${comboName}"`);
    const side = dimVal(sz.size);
    const dotSize = dimVal(sz.dotSize);
    const barHeight = dimVal(sz.barHeight);
    const c = mount.getOrCreate(comboName);
    c.layoutMode = 'NONE';
    c.fills = [];
    switch (vn) {
      case 'dots': {
        // Half a dot apart, the row centred in the `size` square — Flutter's
        // `Row(mainAxisAlignment: center, spacing:)`, Web's
        // `justify-content: center; gap`.
        bindSize(c, lk, side, side);
        const count = dimVal(LOADING.constants.dotCount);
        const gap = dotSize * dimVal(LOADING.constants.dotGapRatio);
        const start = (side - (count * dotSize + (count - 1) * gap)) / 2;
        for (let i = 0; i < count; i++) {
          const dot = figma.createEllipse();
          dot.resize(dotSize, dotSize);
          const level = LOADING_DOT_WAVE[i];
          if (level === undefined) throw new Error(`Loading: no wave level for dot ${i}`);
          fillSem(dot, lk, tint, dimVal(level));
          c.appendChild(dot);
          dot.x = start + i * (dotSize + gap);
          dot.y = (side - dotSize) / 2;
        }
        break;
      }
      case 'bar': {
        const barLength = side * dimVal(LOADING.constants.barLengthRatio);
        bindSize(c, lk, barLength, barHeight);
        const track = figma.createRectangle();
        track.resize(barLength, barHeight);
        bindRadiusN(track, lk, radius);
        fillSem(track, lk, trackTint, trackAlpha);
        c.appendChild(track);
        track.x = 0;
        track.y = 0;
        const fill = figma.createRectangle();
        fill.resize(barLength * dimVal(LOADING.constants.barFillRatio), barHeight);
        bindRadiusN(fill, lk, radius);
        fillSem(fill, lk, tint);
        c.appendChild(fill);
        fill.x = 0;
        fill.y = 0;
        break;
      }
      case 'pulse': {
        bindSize(c, lk, side, side);
        const halo = figma.createEllipse();
        bindSize(halo, lk, side, side);
        fillSem(halo, lk, tint, dimVal(LOADING.constants.pulseHaloAlpha));
        c.appendChild(halo);
        halo.x = 0;
        halo.y = 0;
        const core = side * dimVal(LOADING.constants.pulseDotRatio);
        const dot = figma.createEllipse();
        dot.resize(core, core);
        fillSem(dot, lk, tint);
        c.appendChild(dot);
        dot.x = (side - core) / 2;
        dot.y = (side - core) / 2;
        break;
      }
      default: {
        // spinner — a donut drawn with `arcData.innerRadius` (a stroked
        // ellipse would centre the line on the path and overflow the box by
        // half the stroke). Track is the full circle, arc is `arcSweepDegrees` of it (a quarter).
        bindSize(c, lk, side, side);
        const inner = Math.max(0, 1 - (2 * dimVal(sz.strokeWidth)) / side);
        const ring = figma.createEllipse();
        bindSize(ring, lk, side, side);
        ring.arcData = { startingAngle: 0, endingAngle: Math.PI * 2, innerRadius: inner };
        fillSem(ring, lk, trackTint, trackAlpha);
        c.appendChild(ring);
        ring.x = 0;
        ring.y = 0;
        const arc = figma.createEllipse();
        bindSize(arc, lk, side, side);
        arc.arcData = { startingAngle: 0, endingAngle: arcSweep, innerRadius: inner };
        fillSem(arc, lk, tint);
        c.appendChild(arc);
        arc.x = 0;
        arc.y = 0;
      }
    }
  }
  return mount.finish();
}

// ─── Listing ─────────────────────────────────────────────────────────────────

// Row-based list container (daisyUI `list`): leading badge + grow content
// (title/subtitle) + trailing affordance, hairline-separated. Row padding +
// gap are data-driven from LISTING.fields. The outer container has no bg /
// border / radius field because the widget draws none, and neither does this.
//
// The hairline is an INSTANCE of `Divider`: the widget renders
// `Divider(dividerStyle: resolved.dividerStyle)`, and `LISTING.fields.dividerStyle`
// is that forwarded slot. A hand-painted rectangle could not follow a Divider
// change — and would not, because the content-hash skip leaves this entry
// untouched whenever only Divider's own recipe moved.
//
// `children` is a `List<W>`: no Figma property covers a repeated slot, so the
// rows stay ordinary children a designer adds to or removes from.
const _kListingWidth = 320;

function buildListing(page: PageNode, lk: VarLookup): ComponentNode {
  // `listing.dart`'s build returns a bare `Column` (optionally wrapped in
  // `Semantics`) — no surface, no stroke, no corner — and `CoreListingStyle`
  // holds only itemBorder / padding / colSpacing / dividerStyle. So the frame
  // paints nothing either: a box drawn here would be one every placed Listing
  // carries and no app shows, and the surface a list sits on is its host's.
  const c = mintPanelComp(page, 'Listing', 'VERTICAL', lk, {});
  lockWidth(c, _kListingWidth);
  const rows = [
    { icon: '♪', title: '새벽 산책', sub: '아티스트 A' },
    { icon: '♫', title: '여름밤', sub: '아티스트 B' },
    { icon: '♬', title: '첫눈', sub: '아티스트 C' },
  ];
  // Named, not left to `instanceOf`'s first-variant pick: the two `Label=Present`
  // variants draw an "OR" between two half-length segments, and which variant
  // sorts first is the Divider builder's ordering rather than a statement about
  // what a listing separator is.
  const hairlineAxes = { Orientation: 'Horizontal', Label: 'None' };
  // `resolved.dividerStyle` is what the widget hands the child, and its `color`
  // is the one field in it that paints. Same token as `Divider`'s own default
  // today, so the canvas does not move — what changes is that the line now
  // follows the slot the host forwards instead of the child's default.
  const hairlineColor = colorData(LISTING.fields.dividerStyle.color);
  // `itemBorder` decides whether a rule renders AT ALL — `for (…) [if (i > 0 &&
  // resolved.itemBorder) Divider(…), children[i]]` — and its default is the
  // BOOLEAN's default here, so the canvas shows the rules exactly when the
  // widget's own defaults draw them. The separators exist either way: a
  // designer turns them off with the same property.
  const itemBorder = LISTING.fields.itemBorder.v;
  const separators: InstanceNode[] = [];
  for (let i = 0; i < rows.length; i++) {
    if (i > 0) {
      const sep = hostedDivider(page, lk, c, {
        axes: hairlineAxes,
        color: hairlineColor,
      });
      sep.visible = itemBorder;
      separators.push(sep);
    }
    const r = rows[i];
    const row = panel('row', 'HORIZONTAL', lk, {
      pl: LISTING.fields.padding.l, pr: LISTING.fields.padding.r,
      pt: LISTING.fields.padding.t, pb: LISTING.fields.padding.b,
      gap: LISTING.fields.colSpacing,
    });
    row.counterAxisAlignItems = 'CENTER';
    c.appendChild(row);
    row.layoutSizingHorizontal = 'FILL';
    // Everything from here to the chevron is the row's CONTENTS, and the widget
    // has no opinion about any of it: `ListRow(children:)` / `ListCol(child:)`
    // take arbitrary widgets, and `CoreListingStyle` describes only the row's
    // own inset, its column gap and the rule between rows. A designer swaps
    // these out; they exist so `children` has something in it to look at.
    const lead = figma.createFrame();
    lead.layoutMode = 'HORIZONTAL';
    lead.primaryAxisAlignItems = 'CENTER';
    lead.counterAxisAlignItems = 'CENTER';
    lead.primaryAxisSizingMode = 'FIXED';
    lead.counterAxisSizingMode = 'FIXED';
    bindRadiusN(lead, lk, 8); // g7-preview-only: corner of the demo leading badge
    fillSem(lead, lk, 'surface-container'); // g7-preview-only: that badge's fill
    bindSize(lead, lk, 40, 40); // g7-preview-only: that badge's square
    // g7-preview-only: size + colour of the glyph inside the demo badge
    lead.appendChild(makeLabel(r.icon, lk, { size: 16, colorVar: lk.sem('on-surface') }));
    row.appendChild(lead);
    const col = autoFrame('content', 'VERTICAL');
    col.setBoundVariable('itemSpacing', lk.space(2));
    // g7-preview-only: the demo row's own title line — no listing text field
    col.appendChild(makeLabel(r.title, lk, { size: 14, colorVar: lk.sem('on-surface'), style: 'SemiBold' }));
    // g7-preview-only: the demo row's own subtitle line — same, no field
    col.appendChild(makeLabel(r.sub, lk, { size: 12, colorVar: lk.sem('on-surface-variant') }));
    row.appendChild(col);
    col.layoutSizingHorizontal = 'FILL';
    // Not the app root's ambient icon size, unlike the `Icon` slots elsewhere
    // in this file: this glyph stands in for no `Icon` handed to a slot. It is
    // one piece of the demo row a caller composes whole and hands `children`,
    // and that row states its own sizes, as the 14 / 12 text beside it does.
    // g7-preview-only: the demo row's trailing affordance, a child like any other
    row.appendChild(makeIcon('chevron-right', lk, { size: 14, colorVar: lk.sem('on-surface-variant') }));
  }
  // One BOOLEAN for both rules, because the widget has one flag for all of them.
  const borderProp = defineProp(
    propertyOwner(c),
    'Item border',
    'BOOLEAN',
    itemBorder,
  );
  for (const sep of separators) bindVisibleProp(sep, borderProp);
  return c;
}

// ─── Basic ───────────────────────────────────────────────────────────────────

// Slot-layout row: leading, vertical title/subtitle stack (grow), trailing.
// Data-driven from coui_core BASIC.fields: `titleContentGapStyle` (the ROW's
// gap — the widget spends it on both sides of the body column),
// `titleSubtitleGapStyle` (the body column's own `itemSpacing`),
// `leadingTitleGapStyle` (that column's second stated gap, which is a node
// because a frame has only one `itemSpacing`), all five slot alignments, the
// three slot text styles, and `padding`.
//
// The frame paints nothing: `basic.dart` renders `Padding(child: Row(…))` and
// paints no surface, stroke or corner, and `CoreBasicStyle` has no field for
// any of them. A box drawn here would ride into every composer that places a
// `Basic` — `CardImage` puts one under its image, and the widget draws no box
// there. The INSET is a real field, and it states 0 on all four sides.
//
// All five slots have a node here and get the property their shape allows.
//
// Each also states its OWN alignment, and all five were ignored while the row
// hardcoded `counterAxisAlignItems = 'CENTER'`. The widget wraps every slot in
// `Align(alignment: resolved.<slot>Alignment, child: …)`, so each one gets a
// cell that carries its two axis alignments (`alignCell`). The three body slots
// take theirs per-slot; the two outer ones share the row's single counter-axis
// alignment, which is a Figma constraint rather than a collapse — see
// `rowCounterAxis`.
//
// `leading` is an INSTANCE of `Avatar`. It was a hand-drawn 40 px circle with
// initials in it — which is what `Avatar` is, at its `md` size — and a drawn
// frame accepts no INSTANCE_SWAP, so that circle was the only thing the slot
// could ever hold. The instance is the swap default, not a composition the
// widget performs.
//
// `content` renders `contentTextStyle`, a real field that had no node to
// attach to. It starts hidden, matching the widget's own `content: null`
// default: the column shows title + subtitle as before, and the panel is what
// says a third line exists. The widget separates it from the subtitle with
// `Gap(gapStyle: leadingTitleGapStyle)` — the column's single Figma
// `itemSpacing` already carries `titleSubtitleGapStyle` and cannot also carry
// that one without a Gap node, the same limit this component already has on
// the far side of the row.
// The trailing end is `trailingText` then the built-in chevron, one `Row` in the
// widget: `Show trailing text` / `Trailing text` and `Show trailing icon` /
// `Trailing` map to its three states. `Show subtitle` hides the subtitle cell,
// and the column's `itemSpacing` goes with it. With both trailing children
// hidden the (empty) group still sits behind the row's gap, which the widget
// does not draw — a BOOLEAN cannot be the AND of two others.
const _kBasicTrailingIcon = 'chevron-right';
const _kBasicTrailingText = '켜짐';
const _kBasicContentText = '이 항목에 대한 자세한 설명이 들어가요.';

function buildBasic(page: PageNode, lk: VarLookup): ComponentNode {
  const f = BASIC.fields;
  // The default the `Trailing` property already holds, so the trailing glyph
  // is drawn from it and the first bind leaves it at its own size.
  const trailingSwap = iconSwapDefault(page, 'Basic', 'Trailing', iconMainId(page));
  const c = mintPanelComp(page, 'Basic', 'HORIZONTAL', lk, {
    // No surface, stroke or corner — `basic.dart`'s build is `Padding(padding:
    // resolved.padding, child: Row(…))` and nothing else (see the section note).
    //
    // The ROW's gap is `titleContentGapStyle` — the widget puts it between the
    // outer slots and the body (`leading ↔ body` and `body ↔ trailing`).
    //
    // This read `leadingTitleGapStyle`, and the two fields' names are inverted
    // relative to what they do: `leadingTitleGapStyle` is spent INSIDE the body
    // column, between (title|subtitle) and `content`. So the canvas was drawing
    // the column's inner gap as the row's, and the row's own gap appeared
    // nowhere. Both are fixed here — the column's is set below.
    gap: f.titleContentGapStyle.size,
  });
  // `Padding(padding: resolved.padding, child: row)` is the whole of what wraps
  // the row, so this frame IS that `Padding` — and the field states 0 on every
  // side. Bound rather than left off: an unbound 0 and a stated 0 read the same
  // on the canvas, and only one of them tells a designer where the number came
  // from.
  bindPad(c, lk, f.padding);
  // The two outer slots' VERTICAL alignment, which the row carries once for
  // both — see `rowCounterAxis` for why it cannot be per-slot. Read from the
  // fields, so the avatar and the trailing glyph sit where the widget puts them.
  c.counterAxisAlignItems = rowCounterAxis(f.leadingAlignment, f.trailingAlignment);
  // The row's own MAIN axis, which is a separate field from the two above:
  // `Row(mainAxisAlignment: resolved.mainAxisAlignment, …)`. The row hugs
  // (`mainAxisSize: .min`), so today the value has no slack to act in — and that
  // is the reason to bind it rather than to skip it. A designer who stretches
  // this row gets the widget's answer to "where does the content sit"; an unbound
  // frame would answer `MIN` no matter what the field says.
  // The row is `mainAxisSize: .min` inside whatever surface owns it, so its
  // width is the caller's; `CoreBasicStyle` states none.
  // g7-preview-only: Basic preview width, no width field in the code
  lockWidth(c, 360);
  c.primaryAxisAlignItems = mainAxisOf(f.mainAxisAlignment, 'basic.mainAxisAlignment');
  const leadHolder = alignCell('leading', f.leadingAlignment, 'basic.leadingAlignment');
  c.appendChild(leadHolder);
  const leadVariant = bestVariantName(page, 'Avatar', { Size: 'md', ...kAvatarRest });
  const lead = instanceOf(page, 'Avatar', leadVariant);
  leadHolder.appendChild(lead);
  // `body` in the widget — the column that stacks title / subtitle / content.
  // Named for that rather than for one of the three slots inside it.
  const col = autoFrame('body', 'VERTICAL');
  // `titleSubtitleGapStyle` between the title and the subtitle, and
  // `leadingTitleGapStyle` between those two and `content` — two different stated
  // gaps in one column, so the second one is a node (the reason `gapSpacer`
  // exists) and the column's own spacing carries the first.
  col.setBoundVariable('itemSpacing', lk.space(dimVal(f.titleSubtitleGapStyle.size)));
  // The same field again, because the widget spends it twice — the body
  // `Column` takes `mainAxisAlignment` too (`basic.dart:109`).
  col.primaryAxisAlignItems = mainAxisOf(f.mainAxisAlignment, 'basic.mainAxisAlignment');
  // The whole of the Title line's type comes from `titleTextStyle` — role
  // `labelXl` (15) at the weight the field overrides it with (600 → SemiBold),
  // coloured `onSurface`. Nothing is layered over it, so all three arrive.
  const title = makeLabel('알림 설정', lk, textLabelOpts(lk, textStyleData(f.titleTextStyle)));
  const titleCell = alignCell('title', f.titleAlignment, 'basic.titleAlignment');
  titleCell.appendChild(title);
  col.appendChild(titleCell);
  const subtitle = makeLabel('푸시, 이메일', lk, textLabelOpts(lk, textStyleData(f.subtitleTextStyle)));
  const subtitleCell = alignCell('subtitle', f.subtitleAlignment, 'basic.subtitleAlignment');
  subtitleCell.appendChild(subtitle);
  col.appendChild(subtitleCell);
  // Both the BOOLEAN's region and `content`'s own `Align` — one frame, because
  // the widget has one there (`Align(alignment: contentAlignment, child: …)`
  // inside the `if (content != null)` branch).
  // `Gap(gapStyle: resolved.leadingTitleGapStyle)` — the (title|subtitle)↔content
  // gap, hidden with the content it separates: an auto-layout frame skips hidden
  // children, so a visible spacer over a hidden slot would leave a hole.
  const contentGap = gapSpacer('content gap', lk, f.leadingTitleGapStyle.size);
  col.appendChild(contentGap);
  contentGap.visible = false;
  const contentHolder = alignCell('content', f.contentAlignment, 'basic.contentAlignment');
  col.appendChild(contentHolder);
  const content = makeLabel(
    _kBasicContentText,
    lk,
    textLabelOpts(lk, textStyleData(f.contentTextStyle)),
  );
  contentHolder.appendChild(content);
  contentHolder.visible = false;
  c.appendChild(col);
  col.layoutSizingHorizontal = 'FILL';
  // The column is `crossAxisAlignment: .stretch`, so each cell spans its width
  // and the alignment inside it is what places the line. A cell that hugged
  // would be exactly its text wide and every alignment would read the same.
  for (const cell of [titleCell, subtitleCell, contentHolder]) {
    cell.layoutSizingHorizontal = 'FILL';
  }
  // `trailing` is a `W?` the widget renders as handed to it — `Align(child:
  // trailing)` on Flutter, the slot `<div>` on Web, neither with a size or an
  // `IconTheme` of its own — so an `Icon` passed there draws at the app root's
  // ambient icon size. The INSTANCE_SWAP below is what makes this one
  // replaceable.
  // The built-in chevron `showTrailingIcon` draws (`Icon(LucideIcons.chevronRight,
  // iconStyle: resolved.trailingIconStyle)`), so its colour is the style's own.
  const trailing = makeIcon(_kBasicTrailingIcon, lk, {
    ...glyphOpts(lk, colorData(f.trailingIconStyle.color), ICON.constants.ambientSize, 'size'),
    fromVariant: trailingSwap.variant,
  });
  const trailCell = alignCell('trailing', f.trailingAlignment, 'basic.trailingAlignment');
  // `Row(mainAxisSize: min, [trailingText, Gap(trailingGapStyle), icon])` — the
  // gap is the group's `itemSpacing`, so hiding either child drops it with it.
  const trailGroup = autoFrame('trailing group', 'HORIZONTAL');
  trailGroup.counterAxisAlignItems = 'CENTER';
  bindSpaceField(trailGroup, 'itemSpacing', lk, dimVal(f.trailingGapStyle.size));
  const trailingText = makeLabel(
    _kBasicTrailingText,
    lk,
    textLabelOpts(lk, textStyleData(f.trailingTextStyle)),
  );
  trailingText.name = 'trailing text';
  trailGroup.appendChild(trailingText);
  trailingText.visible = false;
  const trailIconHolder = slotHolder('trailing icon');
  trailIconHolder.appendChild(trailing);
  trailGroup.appendChild(trailIconHolder);
  trailCell.appendChild(trailGroup);
  c.appendChild(trailCell);
  const owner = propertyOwner(c);
  bindTextProp(title, defineProp(owner, 'Title', 'TEXT', '알림 설정'));
  bindTextProp(subtitle, defineProp(owner, 'Subtitle', 'TEXT', '푸시, 이메일'));
  bindTextProp(content, defineProp(owner, 'Content', 'TEXT', _kBasicContentText));
  bindVisibleProp(contentHolder, defineProp(owner, 'Show content', 'BOOLEAN', false));
  bindSwapProp(
    lead,
    defineProp(owner, 'Leading', 'INSTANCE_SWAP', mainIdOf(page, 'Avatar', leadVariant)),
  );
  bindVisibleProp(leadHolder, defineProp(owner, 'Show leading', 'BOOLEAN', true));
  bindSwapProp(
    trailing,
    defineProp(owner, 'Trailing', 'INSTANCE_SWAP', trailingSwap.id),
  );
  // `showSubtitle` and `showTrailingIcon` (both on) take the widget's own
  // defaults, so a freshly placed instance draws what `Basic(...)` draws.
  bindVisibleProp(subtitleCell, defineProp(owner, 'Show subtitle', 'BOOLEAN', true));
  bindVisibleProp(trailIconHolder, defineProp(owner, 'Show trailing icon', 'BOOLEAN', true));
  bindVisibleProp(trailingText, defineProp(owner, 'Show trailing text', 'BOOLEAN', false));
  bindTextProp(trailingText, defineProp(owner, 'Trailing text', 'TEXT', _kBasicTrailingText));
  return c;
}

// ─── DefinitionList ──────────────────────────────────────────────────────────

// Data-driven from coui_core: DEFINITION_LIST.variants.defaultsByLayout (one
// row per `CoreDefinitionLayout`, each stating entrySpacing / pairSpacing /
// termTextStyle / descriptionTextStyle), one member per layout — the enum is
// the component's only visual axis, and the three members are three different
// trees in `definition_list.dart`, each with its own distances and roles:
//
//   · stacked — `Column(spacing: entrySpacing, [Column(spacing: pairSpacing,
//     [term, description]), …])`.
//   · inline  — `Wrap(spacing: entrySpacing, runSpacing: entrySpacing,
//     [Row(spacing: pairSpacing, baseline, [term, description]), …])`. The
//     canvas counterpart of `Wrap` is a wrapping row with both gaps bound; it
//     hugs, so it breaks lines only once a designer fixes its width — which is
//     exactly when `Wrap` does too.
//   · columns — a two-column `Table`: the term column is `IntrinsicColumnWidth`
//     (as wide as its widest term), each row adds `entrySpacing` above every
//     entry but the first and `pairSpacing` before the description, and the
//     row aligns on the alphabetic baseline because a `mono` description sits
//     on a different line box than the term. Figma has no table column, so
//     each row is a baseline row and every term is held at the widest term's
//     measured width — the column a `termWidth`-less list draws. `termWidth`
//     has no default (it is under `absent`), so there is no value to read and
//     a width an app fixes belongs to the consuming file.
//
// The entries are the docs' own (`definition_list_default_example.dart`).
// `items` is a `List` and takes no property — Figma has no repeated slot, so a
// designer adds or removes rows directly.
//
// `numeric` turns on tabular figures in the description. Figma's plugin API
// exposes OpenType features on a text node read-only, so the canvas cannot
// state it; the flag changes digit widths, not the layout this set shows.
//
// `mono` swaps the description role for the code role. A BOOLEAN component
// property cannot switch a text style (it binds visibility, a string or an
// instance), and a variant axis for it would be a new axis, so the set draws
// the layout's own description role and states no Mono.
//
// ─── The rich value (`CoreDefinitionEntry.rich`) ─────────────────────────────
//
// An entry's description is a string OR a widget — `CoreDefinitionEntry.rich`
// takes any `W` (the contract's own example is a `Link`; a plan card's value
// is a `Tag` or a status chip). Each drawn entry carries that second shape as
// a slot after its value text: the `.Slot` stand-in inside a `rich value`
// holder, hidden at rest and bound to that entry's `Show rich value N`, with
// the stand-in itself the `Rich value N` INSTANCE_SWAP target. One pair per
// drawn entry rather than one for the set, because which row holds a widget is
// a per-entry fact and a single swap would put the same component on every
// row. Default off, so the resting pose is the three text entries the docs
// example draws.
//
// The text stays beside the slot when it is on, the way `TableCell`'s
// `Content` sits beside its value: the code's "exactly one of the two" is a
// choice between nodes, and a BOOLEAN can show a node but not hide another in
// the same move. A row that holds only the widget empties its value text on
// the instance.
const DEFINITION_LIST = COMPONENTS.definition_list;
const kDefinitionListRichShape = 'rectangular';

const kDefinitionListEntries: ReadonlyArray<{ term: string; description: string }> = [
  { term: '상호', description: '주식회사 코코드' },
  { term: '대표', description: '김코드' },
  { term: '사업자등록번호', description: '000-00-00000' },
];

function buildDefinitionList(page: PageNode, lk: VarLookup): ComponentSetNode {
  const layout = DEFINITION_LIST.axes.other.find((o) => o.enum === 'CoreDefinitionLayout');
  if (!layout) {
    throw new Error(
      'DefinitionList: CoreDefinitionLayout is gone from the exported axes — the ' +
        'canvas has a Layout axis that nothing in the contract now backs.',
    );
  }
  const layoutRows = new Map(Object.entries(DEFINITION_LIST.variants.defaultsByLayout));
  const mount = mountSet(page, 'DefinitionList', layout.members.map((m) => `Layout=${m}`));
  // Per entry, across every layout member — bound after `finish()`, when the
  // set exists to own the properties.
  const richSlots: { holder: FrameNode; swap: InstanceNode }[][] = kDefinitionListEntries.map(
    () => [],
  );
  for (const member of layout.members) {
    const f = layoutRows.get(member);
    if (!f) throw new Error(`DefinitionList: \`defaultsByLayout\` has no \`${member}\` row`);
    const termOpts = textLabelOpts(lk, textStyleData(f.termTextStyle));
    const descriptionOpts = textLabelOpts(lk, textStyleData(f.descriptionTextStyle));
    const c = mount.getOrCreate(`Layout=${member}`);
    const inline = member === 'inline';
    c.layoutMode = inline ? 'HORIZONTAL' : 'VERTICAL';
    c.primaryAxisSizingMode = 'AUTO';
    c.counterAxisSizingMode = 'AUTO';
    c.fills = [];
    bindSpaceField(c, 'itemSpacing', lk, dimVal(f.entrySpacing));
    if (inline) {
      c.layoutWrap = 'WRAP';
      c.counterAxisAlignItems = 'CENTER';
      c.setBoundVariable('counterAxisSpacing', lk.space(dimVal(f.entrySpacing)));
    }
    const terms: TextNode[] = [];
    for (let i = 0; i < kDefinitionListEntries.length; i++) {
      const entry = kDefinitionListEntries[i];
      // stacked pairs one entry vertically; inline and columns pair it on a
      // baseline row.
      const pair = autoFrame('entry', member === 'stacked' ? 'VERTICAL' : 'HORIZONTAL');
      bindSpaceField(pair, 'itemSpacing', lk, dimVal(f.pairSpacing));
      if (member !== 'stacked') pair.counterAxisAlignItems = 'BASELINE';
      const term = makeLabel(entry.term, lk, termOpts);
      term.name = 'term';
      const description = makeLabel(entry.description, lk, descriptionOpts);
      description.name = 'description';
      pair.appendChild(term);
      // The value cell — the text, then the rich slot after it. A cell rather
      // than the pair's own children so the pair keeps its two-sided shape
      // (term · value) and its `pairSpacing` gap whatever the slot does; the
      // cell's own gap is the same step, so text and widget read as one value.
      const value = autoFrame('value', 'HORIZONTAL');
      value.counterAxisAlignItems = 'CENTER';
      bindSpaceField(value, 'itemSpacing', lk, dimVal(f.pairSpacing));
      value.appendChild(description);
      const richHolder = autoFrame('rich value', 'HORIZONTAL');
      richHolder.counterAxisAlignItems = 'CENTER';
      const richSwap = slotStandIn(page, `rich value ${i + 1}`, kDefinitionListRichShape);
      richHolder.appendChild(richSwap);
      richHolder.visible = false;
      value.appendChild(richHolder);
      pair.appendChild(value);
      c.appendChild(pair);
      terms.push(term);
      richSlots[i].push({ holder: richHolder, swap: richSwap });
    }
    if (member === 'columns') {
      // `IntrinsicColumnWidth` — every term takes the widest term's width, so
      // the descriptions start at one edge. Measured, not stated: the width is
      // the text's own. The `> 0` guard is for the runtime harness, whose text
      // nodes have no layout engine and report 0.
      let widest = 0;
      for (const term of terms) widest = Math.max(widest, term.width);
      if (widest > 0) {
        for (const term of terms) {
          term.textAutoResize = 'HEIGHT';
          term.resize(widest, term.height);
        }
      }
    }
  }
  const set = mount.finish();
  // One pair per drawn entry, shared by the three layout members so a layout
  // switch keeps the designer's choice.
  const richDefault = slotStandInDefault(page, kDefinitionListRichShape);
  for (let i = 0; i < kDefinitionListEntries.length; i++) {
    const show = defineProp(set, `Show rich value ${i + 1}`, 'BOOLEAN', false);
    const swap = defineProp(set, `Rich value ${i + 1}`, 'INSTANCE_SWAP', richDefault);
    for (const slot of richSlots[i]) {
      bindVisibleProp(slot.holder, show);
      bindSwapProp(slot.swap, swap);
    }
  }
  vStackSet(set);
  return set;
}

// ─── Registry ────────────────────────────────────────────────────────────────

export const DISPLAY_DATA: RegistryEntry[] = [
  { section: 'Display', name: 'Banner', build: buildBanner, needs: ['Icon', 'Button'] },
  { section: 'Display', name: 'Chip', build: buildChip, needs: ['Icon', 'Button'] },
  { section: 'Display', name: 'ChipGroup', build: buildChipGroup, needs: ['Chip', 'FadeScroll'] },
  { section: 'Display', name: 'Stat', build: buildStat, needs: ['Icon'] },
  { section: 'Display', name: 'Status', build: buildStatus },
  { section: 'Display', name: 'Kbd', build: buildKbd },
  { section: 'Display', name: 'CodeSnippet', build: buildCodeSnippet, needs: ['Icon', 'Button'] },
  {
    section: 'Display',
    name: 'DescriptionCard',
    build: buildDescriptionCard,
    needs: ['Divider', 'Icon', 'Button'],
  },
  { section: 'Display', name: 'EmptyState', build: buildEmptyState, needs: ['Icon', 'Button'] },
  { section: 'Display', name: 'Indicator', build: buildIndicator, needs: ['Avatar', 'Badge'] },
  { section: 'Display', name: 'DotIndicator', build: buildDotIndicator, needs: ['FocusOutline'] },
  { section: 'Display', name: 'Loading', sizing: { width: 'fixed', height: 'fixed', why: 'loading.dart SizedBox.square(resolved.size); bar 변형은 size × size/4' }, build: buildLoading },
  { section: 'Display', name: 'Listing', build: buildListing, needs: ['Icon', 'Divider'] },
  { section: 'Display', name: 'Basic', build: buildBasic, needs: ['Icon', 'Avatar'] },
  {
    section: 'Text',
    name: 'DefinitionList',
    build: buildDefinitionList,
    // Each entry's rich value is drawn as the slot stand-in.
    needs: [kSlotStandInComponent],
  },
];
