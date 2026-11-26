/// <reference types="@figma/plugin-typings" />

import {
  pinInFlow,
  pinAbsolute,
  RegistryEntry,
  VarLookup,
  applyPanelCompChrome,
  applySurfaceMaterial,
  applyBorderStyle,
  autoFrame,
  bestVariantName,
  bindAxisSize,
  bindPad,
  bindRadiusN,
  bindSize,
  bindSpaceField,
  bindSwapProp,
  bindTextProp,
  bindVisibleProp,
  defineProp,
  exposeAll,
  fillData,
  fillSem,
  fillDataOnNode,
  instanceOf,
  instanceTextNode,
  kProgressDefaultSize,
  kProgressDefaultTone,
  lockWidth,
  makeIcon,
  makeLabel,
  mint,
  mountSet,
  panel,
  propertyOwner,
  rowSet,
  setInstanceBoolNamed,
  setInstanceTextNamed,
  textLabelOpts,
  FocusOutlineSlot,
  addFocusRing,
  setShadow,
  kSlotStandInComponent,
  slotStandIn,
  slotStandInDefault,
  SlotStandInShape,
} from '../helpers';
import { Color, Dim, NormalizedColor, colorData, dimVal, textStyleData } from '../compat/v1';
import { axisSpecsOf, enumerateAxisCombos } from '../axis-combos';
import { parseVariantKey } from '../variant-safety';
import { clipsFor, elevationLayers } from '../container-chrome';
import { COMPONENTS } from '../data';
import type { PadData } from '../box';

/** The horizontal sum of an inset, physical or logical. */
function padHorizontal(pad: PadData | null | undefined): number {
  if (pad == null) return 0;
  return 'start' in pad ? dimVal(pad.start) + dimVal(pad.end) : dimVal(pad.l) + dimVal(pad.r);
}

// ═══════════════════════════════════════════════════════════════════════════
// Layout primitives — the structural half of coui_core's component set.
//
// Every component in this file had no Figma builder at all, and most of them
// own no chrome: `Gap` is empty space, `Stacks` only layers, `Mask` only clips,
// `Hidden` / `MediaQueryVisibility` / `Breakpoint` only decide *whether* their
// child renders. They are built anyway because the Figma tree is meant to
// correspond to the widget tree node-for-node — a node a designer never
// places is still the node a future Figma→code direction reads.
//
// That correspondence is also the constraint on what each one draws. A
// component with no chrome gets the smallest honest structural statement and
// nothing more: a spacer is space, a z-stack is two overlapping boxes, a clip
// container is a clipping frame. None of them gets a decorative picture that
// would imply chrome the Style class does not carry — that lie is worse than a
// plain node, because it reads as a real design decision.
//
// ─── The slots, and the property each one carries ─────────────────────────
//
// Most of these components' only real content is a caller-supplied slot
// (`child` / `children`). It is drawn as the shared slot stand-in
// (`slotStandIn`, slot-stand-in.ts), and every non-repeated slot gets an
// INSTANCE_SWAP named for the slot, bound to the node that actually draws it —
// why, and why the stand-in is a placeholder rather than content:
// docs/contributing/figma.md, "빈 슬롯의 대역".
//
// The property name is the contract's own identifier, verbatim and in its own
// casing (`child`, `sidebar`, `floatingActionButton`) — not a prettified
// `Floating action button`. The panel is then reading out the widget's
// vocabulary, which is the same correspondence the node tree is for.
//
// Two rules the shape below follows, both of them Figma's:
//
//   · Bind AFTER the node is inside the component. `componentPropertyReferences`
//     on a detached node throws ("Can only set component property references on
//     symbol sublayer"), the throw aborts the entry, and the half-built
//     component is left on the page looking finished until the next run that
//     mints its name blanks it.
//   · A node carries exactly ONE `componentPropertyReferences` map, and
//     `bindSwapProp` / `bindVisibleProp` each assign it wholesale — the second
//     call drops the first key. An optional slot therefore needs two nodes: an
//     unpainted hug frame for the BOOLEAN ("did a caller pass one"), holding the
//     instance for the INSTANCE_SWAP ("which widget"). The frame hugs with no
//     padding, fill or gap, so it costs nothing on the canvas.
//
// For a variant SET the properties live on the set, so they are declared after
// `mount.finish()`: until `combineAsVariants` runs, a freshly minted variant's
// parent is still the page and `propertyOwner` would answer with the variant
// itself, putting a separate copy on every one. The per-variant nodes are
// collected during the loop and bound afterwards.
//
// ─── Preview-only geometry ────────────────────────────────────────────────
//
// The constants below are NOT design tokens and are deliberately not bound to
// any variable. None of these components carries a Style default for the size
// of the *demo* box a preview needs — a `ScrollArea`'s height is a caller's
// constraint, not a `CoreScrollAreaStyle` field — so a preview has to pick
// one. Same category as `Card`'s `comp.resize(260, …)` in display.ts. They are
// applied through `resize()` / `x` / `y` / loop counts only, never through a
// token-binding helper, so nothing here can be mistaken for a bound value.
// ═══════════════════════════════════════════════════════════════════════════

const kViewportHeight = 96; // scroll viewport height (shorter than its content)
const kOverflowRows = 4; // enough placeholder rows to overflow that viewport
const kMarqueeViewportWidth = 120; // narrower than one line of content
const kGridWidth = 480; // wide enough that 12 columns are still legible
const kContainerWidth = 240; // stands in for `maxWidth: xl` = 1280 — see buildResponsiveContainer
const kContainerViewportWidth = 360; // wider, so the centring gutter is visible
const kScaffoldWidth = 480;
const kScaffoldHeight = 300;
const kGridPreviewRows = 2; // enough rows to show inter-row spacing
const kHalf = 2; // "half of the child" — overlap offset / thumb length divisor
const kBothSides = 2; // an inset sits on each of two opposite sides of the thing it surrounds

// The stand-in shapes the slots below are drawn as (`SlotStandInShape`).
const kSlotRect: SlotStandInShape = 'rectangular';
const kSlotCircle: SlotStandInShape = 'circular';
const kSlotText: SlotStandInShape = 'text';

// `ResponsiveRowColumn`'s three `children[]`, deliberately three DIFFERENT
// stand-in shapes. A cross-axis alignment is only visible on children that
// disagree about their cross-axis extent, and these three disagree on BOTH axes
// (`text` is 200 wide and several lines tall, `rectangular` 160×40, `circular`
// 40×40) — so one triple shows the centring as a Row, where the cross axis is
// vertical, and as a Column, where it is horizontal. Three identical boxes would
// have made a stated alignment look like no alignment at all, the same reason
// `MediaQueryVisibility` draws its two slots as different shapes.
const kRowColumnChildVariants: SlotStandInShape[] = [kSlotText, kSlotRect, kSlotCircle];

// The slot region of an OPTIONAL (`W?`) slot: an unpainted hug frame carrying
// the BOOLEAN, holding the placeholder instance that carries the swap.
//
// Two nodes because one node holds one `componentPropertyReferences` map — see
// the header. The frame is what a designer switches off to reach the widget's
// `null`, and the instance inside is what they re-point to a different
// component; neither statement is expressible without the other node.
interface SlotNodes {
  /** The region a BOOLEAN hides — the `W?` being absent. */
  holder: FrameNode;
  /** The placeholder an INSTANCE_SWAP re-points — the `W?` being anything. */
  content: InstanceNode;
}

function optionalSlot(
  page: PageNode,
  name: string,
  variant: SlotStandInShape,
  dir: 'HORIZONTAL' | 'VERTICAL' = 'HORIZONTAL',
): SlotNodes {
  const holder = autoFrame(name, dir);
  const content = slotStandIn(page, `${name} content`, variant);
  holder.appendChild(content);
  return { holder, content };
}

// An unpainted, absolutely-placed box marking a region a component *measures*
// but does not paint — a fade extent. Not `autoFrame`: these hold no children,
// and a hug auto-layout box has nothing to hug.
function extentBox(name: string): FrameNode {
  const f = figma.createFrame();
  f.name = name;
  f.layoutMode = 'NONE';
  f.fills = [];
  return f;
}

// The scrollable content of a viewport: a column of placeholder rows, drawn
// taller than the viewport so the overflow these components exist to manage is
// actually visible. A column of natural-size rows rather than one box stretched
// past the viewport, because a stand-in instance carries its main
// component's bound width/height — resizing one to force the overflow would be
// overriding a bound value, and the row column leaves every binding intact.
//
// `rowWidth` comes back with it: the viewport is sized from a row rather than
// from the column's own width, so it does not depend on when Figma recomputes
// the column's auto-layout. `rows` comes back so the caller can bind them — see
// `bindViewportChild`.
//
// The column's width is the viewport's, not the rows' (#4826). A hugging column
// pinned STRETCH re-hugs to its rows the moment Figma lays it out, so the
// constraint every caller put on it reached nothing — a ScrollArea widened to
// 240 kept 160px of content (LAYOUT_AUDIT). So the cross axis is FIXED at the
// row width the viewport is sized from, and every row FILLs it: the rows are
// instances, FILL is the one sizing an instance accepts, and the placeholder
// content is then what actually follows the box. The main axis keeps hugging —
// the overflow is the content's own height, and the viewport shows a part of it.
function overflowingContent(page: PageNode): {
  column: FrameNode;
  rows: InstanceNode[];
  rowWidth: number;
} {
  const column = autoFrame('child', 'VERTICAL');
  const rows: InstanceNode[] = [];
  let rowWidth = 0;
  for (let i = 0; i < kOverflowRows; i++) {
    const row = slotStandIn(page, 'child content', kSlotRect);
    column.appendChild(row);
    rows.push(row);
    rowWidth = Math.max(rowWidth, row.width);
  }
  lockWidth(column, rowWidth);
  for (const row of rows) row.layoutSizingHorizontal = 'FILL';
  return { column, rows, rowWidth };
}

// The `child` slot of a scrolling viewport, as a swappable property.
//
// Bound to every placeholder row rather than to the column holding them. The
// column IS the slot — `ScrollArea(child: …)` takes one widget — but a column
// is a frame, and Figma re-points an INSTANCE, never a frame. Wrapping the
// column in an instance is not available either: an instance mirrors its main
// component's subtree and cannot be given children, which is the same
// constraint `drawFocusOutline` runs into below.
//
// So the rows are what the property re-points, and they all move together:
// whichever component a designer picks becomes what fills the viewport, and it
// still overflows — the precondition for any of these components doing
// anything at all. That is the closest expressible reading of the slot, and it
// is a truer one than "this slot holds the stand-in, forever".
//
// Call AFTER the column is inside the component; the rows are grandchildren of
// it and Figma rejects the binding on anything still detached.
function bindViewportChild(
  page: PageNode,
  owner: ComponentNode | ComponentSetNode,
  rows: InstanceNode[],
): void {
  const prop = defineProp(owner, 'child', 'INSTANCE_SWAP', slotStandInDefault(page, kSlotRect));
  for (const row of rows) bindSwapProp(row, prop);
}

// ─── Flex alignment → Figma auto-layout alignment ────────────────────────────
//
// `CoreMainAxisAlignment` / `CoreCrossAxisAlignment` are *direction-relative*
// in exactly the way Figma's two alignment properties are: the PRIMARY property
// governs whichever axis `layoutMode` flows along and the COUNTER property the
// other one, so a component that flips its axis keeps one mapping for both
// directions. That correspondence is the enums' own claim — each declares
// "Figma: Auto Layout …alignment" in its doc — and these two maps are what
// makes it true of the canvas rather than only of the comment.
//
// Keyed by string rather than switched exhaustively because a JSON import
// widens `"start"` to `string`; there is no union to be exhaustive over. The
// fallback is the Core enum's own default rather than a throw — a value added
// to either enum tomorrow must not strand the component half-drawn on the
// canvas, which is what a throw inside a builder does (nothing is rolled back;
// the entry is reported as failed and its partial node stays).
//
// Two Core values have no Figma counterpart, recorded here rather than silently
// rounded off. Neither is reachable from today's data:
//
//   · `spaceAround` / `spaceEvenly` — Figma's primary axis offers only
//     `SPACE_BETWEEN`, which leaves no free space on the edges. Both collapse
//     onto it; the edge half/third is not expressible as an alignment value.
//   · `stretch` — Figma states cross-axis stretch on the CHILD
//     (`layoutSizingHorizontal = 'FILL'`), not as a parent alignment, so the
//     parent property falls back to `MIN`. The child half is left unwired until
//     something in the data asks for it.
type FigmaPrimaryAlign = 'MIN' | 'MAX' | 'CENTER' | 'SPACE_BETWEEN';
type FigmaCounterAlign = 'MIN' | 'MAX' | 'CENTER' | 'BASELINE';

const kMainAxisAlign: Record<string, FigmaPrimaryAlign> = {
  start: 'MIN',
  end: 'MAX',
  center: 'CENTER',
  spaceBetween: 'SPACE_BETWEEN',
  spaceAround: 'SPACE_BETWEEN',
  spaceEvenly: 'SPACE_BETWEEN',
};

const kCrossAxisAlign: Record<string, FigmaCounterAlign> = {
  start: 'MIN',
  end: 'MAX',
  center: 'CENTER',
  baseline: 'BASELINE',
  stretch: 'MIN',
};

// `CoreMainAxisAlignment.start` / `CoreCrossAxisAlignment.center` are the
// defaults these fall back to, matching each Core enum's own `default*`.
function mainAxisAlign(choice: string): FigmaPrimaryAlign {
  return kMainAxisAlign[choice] ?? 'MIN';
}

function crossAxisAlign(choice: string): FigmaCounterAlign {
  return kCrossAxisAlign[choice] ?? 'CENTER';
}

const ASPECT_RATIO_BOX = COMPONENTS.aspect_ratio_box;
const GAP = COMPONENTS.gap;
const STACKS = COMPONENTS.stacks;
const FRAME = COMPONENTS.frame;
const RESPONSIVE_CONTAINER = COMPONENTS.responsive_container;
const RESPONSIVE_GRID = COMPONENTS.responsive_grid;
const RESPONSIVE_ROW_COLUMN = COMPONENTS.responsive_row_column;
const SCROLL_AREA = COMPONENTS.scroll_area;
const SCROLLBAR = COMPONENTS.scrollbar;
const SCROLLABLE_CLIENT = COMPONENTS.scrollable_client;
const FADE_SCROLL = COMPONENTS.fade_scroll;
const OVERFLOW_MARQUEE = COMPONENTS.overflow_marquee;
const STAGE_CONTAINER = COMPONENTS.stage_container;
const SCAFFOLD = COMPONENTS.scaffold;
const APP_BAR = COMPONENTS.app_bar;
// `icon.constants.ambientSize` — the app root's ambient icon size, which an
// `Icon` handed to a caller slot draws at when the widget renders it as handed.
// AppBar's `leading` / `trailing` items say why they qualify.
const ICON = COMPONENTS.icon;

// The ❖ AppBar member a Scaffold's header and footer compose: every pose axis
// at the widget's own default. `Variant` is the contract's default enum value;
// `Leading=none` because `leading` is an empty list unless a caller fills it;
// `Align=start` because `centerTitle` defaults to false.
const kScaffoldAppBarPose: Record<string, string> = {
  Variant: APP_BAR.axes.variant?.default ?? 'standard',
  Leading: 'none',
  Align: 'start',
};

// The ❖ Progress member a Scaffold's loading bar composes: the widget's own
// resting bar (`kProgressDefaultSize` / `kProgressDefaultTone`,
// instance-reach.ts), which is what `Scaffold` gets by constructing
// `Progress(value: …)` with no size and no tone — and no `segments`, so the
// continuous bar. Every axis is named, so the score picks one member rather
// than leaving the tone or the segmented pose to set order.
const kScaffoldProgressPose: Record<string, string> = {
  Size: kProgressDefaultSize,
  Tone: kProgressDefaultTone,
  Segmented: 'false',
};

// ─── Composed scrollbar ──────────────────────────────────────────────────────

// The `Scrollbar` a viewport composes, as an instance of that component.
//
// Every scrolling widget in this file composes the unified `Scrollbar` rather
// than painting a thumb of its own — `ScrollArea` wraps its scroll view in one,
// `ScrollableClient` nests one per axis, `FadeScroll` attaches one when
// `showScrollbar` is on. The rectangles this file drew instead looked like the
// result while saying something false about it: that the viewport owns that
// chrome. It does not; the composed component does, and a Figma→code direction
// reading this tree would have found no scrollbar to read back.
//
// The Figma `Scrollbar` component is minted in its vertical orientation and has
// no axis variant to pick, so a horizontal instance is that same component laid
// along the other axis — root and thumb swap their extents.
//
// `thickness` / `thumbLength` / `thumbColor` / `trackColor` are the values a
// parent forwards through its nested `CoreScrollbarStyle` slot. They land as
// Figma instance overrides, which is how a parent customises a composed child —
// as opposed to repainting a rectangle of its own, which is the parent
// re-implementing the child (`core/style-contract.md`). Omitted, the child's own
// defaults stand, which is exactly what a parent that forwards nothing renders.
// Corner radius is overridden only by the parent that states one
// (`ScrollableClient`'s radius/4); the others rest at the child's capsule.
//
// The bar occupies its thumb plus the gap the thumb keeps from the edge, on both
// sides (`thumbInset`) — the track Flutter's `RawScrollbar` lays out and the
// width the browser reserves beside the content. So the instance is as wide as
// that footprint, not as the thumb: a parent that forwards a thickness changes
// the thumb, and the footprint follows from it. No parent forwards an inset, so
// the child's own stands. The footprint is derived, not a token, and nothing
// binds to it; the thumb's thickness is the value a token names.
//
// `trackLength` is not one of those values and cannot be. How far a thumb
// travels is a property of the content, not of the scrollbar, so the parent
// supplies it as the viewport extent.
function composeScrollbar(
  page: PageNode,
  lk: VarLookup,
  o: {
    axis: 'vertical' | 'horizontal';
    trackLength: number;
    thickness?: number | Dim;
    thumbLength?: number | Dim;
    thumbColor?: NormalizedColor | null;
    thumbRadius?: number | Dim | null;
    trackColor?: NormalizedColor | null;
  },
): InstanceNode {
  const bar = instanceOf(page, 'Scrollbar');
  const vertical = o.axis === 'vertical';
  const inset = dimVal(SCROLLBAR.fields.thumbInset);
  const breadth = dimVal(o.thickness == null ? SCROLLBAR.fields.thickness : o.thickness);
  const run = dimVal(o.thumbLength == null ? SCROLLBAR.fields.minThumbLength : o.thumbLength);
  const footprint = breadth + inset * kBothSides;
  // A layer inside an instance cannot be moved — Figma refuses `x`/`y` there
  // whatever the value ("relative-transform", #5438). So the thumb keeps the
  // inset it is drawn at in the main through its pin (MIN across, STRETCH
  // along — both hold the near edge), and is only ever RESIZED here.
  const thumbs = bar.children.filter(
    (kid): kid is RectangleNode => kid.type === 'RECTANGLE' && kid.name === 'thumb',
  );
  // STRETCH keeps both margins, so collapsing the main's track to a horizontal
  // bar's footprint would leave the thumb a negative length. Run it down to the
  // far inset first: the margin it keeps is then the inset on both ends, and
  // the length it lands at is the footprint less those — the breadth.
  for (const kid of thumbs) kid.resize(kid.width, bar.height - inset * kBothSides);
  bar.resize(vertical ? footprint : o.trackLength, vertical ? o.trackLength : footprint);
  if (o.trackColor !== undefined) fillData(bar, lk, o.trackColor);
  for (const kid of thumbs) {
    kid.resize(vertical ? breadth : run, vertical ? run : breadth);
    // Keep the forwarded thickness inspectable, on the node that carries it. The
    // other axis — the content-derived run — is left as plain geometry unless the
    // parent forwarded nothing and the child's own token stands.
    const breadthVar = lk.sizeOrNull(breadth);
    if (breadthVar) kid.setBoundVariable(vertical ? 'width' : 'height', breadthVar);
    if (o.thumbLength == null) {
      const runVar = lk.sizeOrNull(run);
      if (runVar) kid.setBoundVariable(vertical ? 'height' : 'width', runVar);
    }
    // On the NODE, not the paint: the child's own default is a translucent ink, so
    // a colour a parent forwards has to restate its strength too (an opaque one
    // would otherwise keep drawing the child's half).
    if (o.thumbColor !== undefined) fillDataOnNode(kid, lk, o.thumbColor);
    // `thumbRadius: CoreBorderRadius.all(resolved.scrollbarRadius)` — the caller's
    // own field, because the two callers state it under different names and only
    // one of them is `Scrollbar`'s.
    if (o.thumbRadius != null) bindRadiusN(kid, lk, o.thumbRadius);
  }
  return bar;
}

// ─── Composed focus outline ──────────────────────────────────────────────────

// The ring `FocusOutline` renders, drawn on the focusable node's own root
// rather than instantiated.
//
// This is the one child here that cannot be an instance. `FocusOutline` is a
// *wrapper* — the widget is `FocusOutline(child: <the whole viewport>)` — and a
// Figma instance cannot be given children, so an instance placed inside would
// sit *beside* the content as a second bordered box instead of around it. That
// picture is falser than drawing the ring: what the widget paints is a border
// in `focusOutlineStyle.borderColor` around the focusable node, and that is
// what this puts there, from the same field the widget forwards.
// The whole ring recipe, through the shared `addFocusRing`.
//
// This used to paint `borderData(node, lk, borderColor)` and nothing else, which
// dropped three stated values: the width (2 — the stroke landed at Figma's default
// 1), the offset band (`align` 4 — the ring sat ON the edge instead of outside it),
// and `ringOpacity`. All three are in `focusOutlineStyle` next to the colour that
// WAS being read.
function drawFocusOutline(
  node: ComponentNode,
  lk: VarLookup,
  focus: FocusOutlineSlot,
  radius: number | Dim,
): void {
  addFocusRing(node, lk, focus, radius);
}

// ─── Gap ─────────────────────────────────────────────────────────────────────

// The spacer. `Gap` owns no chrome at all — it *is* the space — so the node is
// its extent and nothing else: both dimensions bound to `CoreGapStyle.size`
// via bindSize, no fill, no stroke, no children. Painting it would state a
// colour `CoreGapStyle` does not have, and an unpainted box of exactly the
// token's extent is the whole truth about this widget.
function buildGap(page: PageNode, lk: VarLookup): ComponentNode {
  const c = mint(page, 'Gap');
  c.fills = [];
  bindSize(c, lk, GAP.fields.size, GAP.fields.size);
  return c;
}

// `CoreAlignment` → its two scalars. The Core type IS a pair of -1..1 doubles
// (`CoreAlignment(-1, -1)` is `topStart`), and the exporter publishes the member's
// NAME, so the name is mapped back to the pair the constant holds.
//
// Throws on an unknown name rather than defaulting to a corner: the runtime
// harness drives every builder against the committed data, so a tenth member
// fails on the machine that adds it — whereas a child placed at the wrong corner
// looks like a layout decision.
const kAlignments: Record<string, { x: number; y: number }> = {
  topStart: { x: -1, y: -1 },
  topCenter: { x: 0, y: -1 },
  topEnd: { x: 1, y: -1 },
  centerStart: { x: -1, y: 0 },
  center: { x: 0, y: 0 },
  centerEnd: { x: 1, y: 0 },
  bottomStart: { x: -1, y: 1 },
  bottomCenter: { x: 0, y: 1 },
  bottomEnd: { x: 1, y: 1 },
};

function alignmentOf(
  leaf: { readonly choice: string },
  field: string,
): { x: number; y: number } {
  const pair = kAlignments[leaf.choice];
  if (pair === undefined) {
    throw new Error(
      `${field}: unknown CoreAlignment "${leaf.choice}". Add it to ` +
        '`kAlignments` in primitives-layout.ts with the (x, y) pair its ' +
        `constant holds in alignment.dart. Known: ${Object.keys(kAlignments).join(', ')}.`,
    );
  }
  return pair;
}

// ─── Stacks ──────────────────────────────────────────────────────────────────

// The z-stack. `CoreStacksStyle` carries no chrome fields, so what there is to
// show is the *stacking*: two children sharing one position, the second
// painted over the first (the contract's "last child renders on top"). The
// overlap offset is half the first child's own size — derived from the child
// rather than picked, so no spacing decision is invented here.
//
// `clipsContent` mirrors the contract's `clipBehavior` default (hardEdge).
//
// `alignment` DOES have a default (`CoreAlignment.topStart`) and it decides where
// a non-positioned child sits, so the two children's coordinates come from it
// rather than from an invented offset. What stood here was `front` at half the
// back's size — a diagonal cascade that showed "these two overlap" and showed a
// position no `CoreAlignment` member produces. The two are now both placed by
// the field, and the stacking still reads because the front child is the smaller
// of the two placeholders: at the corner the field names, the back shows around
// it on the other two sides.
//
// `textDirection` stays unread — it only flips what `start` MEANS, and the axis
// that would show it is the one this canvas does not have (`localization.md`: no
// component mirrors its geometry yet).
function buildStacks(page: PageNode, lk: VarLookup): ComponentNode {
  const c = mint(page, 'Stacks');
  c.fills = [];
  // `clipBehavior` → the frame's one clip flag. `.none` is the only member that
  // does not clip; `hardEdge`, `antiAlias` and `antiAliasWithSaveLayer` are all
  // one hard rectangular clip here, which is the whole of what Figma offers.
  // Asserted as `true` before, and `hardEdge` is what the data says today — so the
  // flag was right by coincidence rather than because the field reached it.
  c.clipsContent = clipsFor(STACKS.fields.clipBehavior, 'stacks.clipBehavior');
  // `fit` decides whether the non-positioned children keep their own size
  // (`loose`) or are stretched to the stack's (`expand`). `loose` is what the
  // recipe states, and it is what these two slots already did — but by accident:
  // the sizes came from the slot placeholders and nothing connected them to the
  // field, so a recipe that said `expand` would have gone on drawing loose.
  const expand = STACKS.fields.fit.choice === 'expand';
  const align = alignmentOf(STACKS.fields.alignment, 'stacks.alignment');
  const back = slotStandIn(page, 'children[0]', kSlotRect);
  c.appendChild(back);
  const front = slotStandIn(page, 'children[1]', kSlotCircle);
  c.appendChild(front);
  // The stack is the union of its loose children, which for children sharing one
  // corner is just the larger of the two on each axis.
  c.resize(
    Math.max(back.width, front.width),
    Math.max(back.height, front.height),
  );
  if (!expand) {
    // Flutter's own inscribe: a member's -1..1 pair scaled into the slack left
    // over on each axis. Nine members, one formula, no table of corners to keep
    // in step with `alignment.dart`.
    for (const kid of [back, front]) {
      kid.x = ((align.x + 1) / 2) * (c.width - kid.width);
      kid.y = ((align.y + 1) / 2) * (c.height - kid.height);
    }
  }
  if (expand) {
    // Both children take the stack's box — `StackFit.expand` passes tight
    // constraints down, so every non-positioned child is exactly the stack. With
    // no slack left the alignment has nothing to act on, which is why it is only
    // applied on the other arm.
    for (const kid of [back, front]) {
      kid.resize(c.width, c.height);
      kid.x = 0;
      kid.y = 0;
    }
  }
  return c;
}

// ─── AspectRatioBox ──────────────────────────────────────────────────────────

// Constrains its child to a fixed width:height `ratio`. The widget takes `ratio`
// as a parameter and `CoreAspectRatioBoxStyle.defaultRatio` is the fallback it
// lands on when the caller's value is not strictly positive — `1`, a square.
//
// This box was a square before too, and the note here said the data had no ratio
// to draw so the square asserted nothing. That was true of the JSON and false of
// the code: the field is named `defaultRatio` and its constant
// `defaultDefaultRatio`, and the reader stripped `default` from BOTH, landing the
// constant on `defaultRatio` and the field on `ratio` — a name no field has. The
// pairing never met and the component shipped with an empty `fields`. So the
// square is unchanged and its provenance is not: the number now comes from Core,
// and a designer who changes that constant moves this box.
//
// The child fills the box on both axes, which is the actual statement: the box
// decides the extent, the child obeys it.
function buildAspectRatioBox(page: PageNode, lk: VarLookup): ComponentNode {
  const c = mint(page, 'AspectRatioBox');
  c.layoutMode = 'HORIZONTAL';
  c.primaryAxisSizingMode = 'FIXED';
  c.counterAxisSizingMode = 'FIXED';
  c.fills = [];
  const child = slotStandIn(page, 'child', kSlotRect);
  c.appendChild(child);
  // width / ratio, which is what `width:height` means. Not bound to a Variable:
  // the ratio is a bare number in Core (`ref: null`) rather than a step on any
  // scale, so binding it would assert a token the design system never named.
  c.resize(child.width, child.width / dimVal(ASPECT_RATIO_BOX.fields.defaultRatio));
  child.layoutSizingHorizontal = 'FILL';
  child.layoutSizingVertical = 'FILL';
  // `child` is required (`W`, never null), so it gets the swap and no BOOLEAN:
  // a component property that could remove it would describe a widget that
  // cannot be constructed.
  bindSwapProp(
    child,
    defineProp(propertyOwner(c), 'child', 'INSTANCE_SWAP', slotStandInDefault(page, kSlotRect)),
  );
  return c;
}

// ─── ResponsiveContainer ─────────────────────────────────────────────────────

// Centres its max-width-constrained child, with a minimum horizontal gutter
// inside that constraint. The widget is
// `Align(topCenter, child: ConstrainedBox(maxWidth, child: SizedBox(width:
// infinity, child: Padding(horizontalPadding, child: child))))` — the `Align`
// present only when `centered`.
//
// So there are two boxes, and which value lives on which one is the whole
// point. `centered` belongs to the OUTER box: it is the wrapper's alignment of
// the constrained box inside the available width, and it is the reason the
// outer node is wider than the inner one here — with a single node there is no
// leftover space for a centring to be visible in, which is how this field
// reached the canvas and showed nothing. `horizontalPadding` belongs to the
// INNER box, inside the constraint, and the child fills what is left
// (`SizedBox(width: infinity)`).
//
// `centered` maps onto one Figma property because `Align(topCenter)` is two
// statements and only one of them is this field's: the resolver's own note
// calls it "horizontal centring only, vertical alignment stays at the top", so
// the cross axis of this vertical stack carries `centered` and the primary axis
// is pinned to the top either way.
//
// The available width is the caller's, so `kContainerViewportWidth` asserts
// nothing. `kContainerWidth` is a different case and should not be read as one:
// `maxWidth` is NOT dimensionless. `CoreResponsiveContainerMaxWidth.xl` carries
// `1280`, and the widget draws exactly that — `responsive_container_style.dart`
// resolves `preset.maxWidth * scaling` into `BoxConstraints(maxWidth:)`. What
// has no dimension is components.json, which flattens the field to
// `{"choice": "xl"}` and drops the enum's numeric payload (the same leaf shape
// also parks `responsiveMaxWidth` in `absent`), so there is nothing here to
// bind to.
//
// 1280 would not be drawable even if it were exported: a 1280-wide component
// sitting beside 240-wide cards is a canvas-scale problem, not a fidelity one.
// So the preview substitutes a narrower constrained box and the *ratio* — inner
// box narrower than the available width, which is what makes `centered`
// visible — is the part that is true. Recorded as an exporter gap (choice
// leaves should carry their enum's value) rather than as an absent design
// value. The breakpoint-keyed clamp that reselects `maxWidth` per tier is
// behaviour a static preview has no way to vary.
function buildResponsiveContainer(page: PageNode, lk: VarLookup): ComponentNode {
  const c = mint(page, 'ResponsiveContainer');
  c.layoutMode = 'VERTICAL';
  c.fills = [];
  c.counterAxisAlignItems = RESPONSIVE_CONTAINER.fields.centered.v ? 'CENTER' : 'MIN';
  // The `top` half of `topCenter` — not `centered`'s to decide, and stated so
  // the two halves of that alignment are both visible in the tree.
  c.primaryAxisAlignItems = 'MIN';
  // The `ConstrainedBox`/`Padding` pair, named for the field that decides its
  // extent. Deliberately NOT filled to the parent: a box that fills its parent
  // has nothing to be centred in.
  const constrained = autoFrame('maxWidth', 'VERTICAL');
  bindPad(constrained, lk, RESPONSIVE_CONTAINER.fields.horizontalPadding);
  lockWidth(constrained, kContainerWidth);
  c.appendChild(constrained);
  const child = slotStandIn(page, 'child', kSlotRect);
  constrained.appendChild(child);
  child.layoutSizingHorizontal = 'FILL';
  lockWidth(c, kContainerViewportWidth);
  bindSwapProp(
    child,
    defineProp(propertyOwner(c), 'child', 'INSTANCE_SWAP', slotStandInDefault(page, kSlotRect)),
  );
  return c;
}

// ─── ResponsiveGrid ──────────────────────────────────────────────────────────

// `columns` equal-width cells with `cellSpacing` between every column *and*
// every row — both from coui_core, and both visible: the cell count is the
// loop bound, and the same spacing field drives the row gap (outer
// itemSpacing) and the column gap (each row's itemSpacing). Cell width is not
// computed here; every cell is a FILL child, so Figma divides the row exactly
// as the grid does.
//
// The breakpoint-driven column reduction (1 column below md, 2 below lg) is
// behaviour keyed to viewport width — not representable in a static preview,
// and `responsive`/`breakpoints` carry no dimensional default to bind.
function buildResponsiveGrid(page: PageNode, lk: VarLookup): ComponentNode {
  const spacing = RESPONSIVE_GRID.fields.cellSpacing;
  const columns = dimVal(RESPONSIVE_GRID.fields.columns);
  const c = mint(page, 'ResponsiveGrid');
  c.layoutMode = 'VERTICAL';
  c.fills = [];
  c.setBoundVariable('itemSpacing', lk.space(dimVal(spacing)));
  lockWidth(c, kGridWidth);
  for (let r = 0; r < kGridPreviewRows; r++) {
    const row = autoFrame('row', 'HORIZONTAL');
    row.setBoundVariable('itemSpacing', lk.space(dimVal(spacing)));
    c.appendChild(row);
    row.layoutSizingHorizontal = 'FILL';
    for (let i = 0; i < columns; i++) {
      const cell = slotStandIn(page, 'children[]', kSlotRect);
      row.appendChild(cell);
      cell.layoutSizingHorizontal = 'FILL';
    }
  }
  return c;
}

// ─── ResponsiveRowColumn ─────────────────────────────────────────────────────

// Renders its children along one axis above a breakpoint tier and the other
// below it. The axis is the entire component, so it is the Figma axis too —
// `Direction=Row` / `Direction=Column` are the same children under the same
// `spacing` token, laid out both ways.
//
// `Direction` is a real state of the widget, not a dispatch table: which one
// renders is derived at build time from the ambient tier (`switchAt`, a
// Contract behaviour default of `tablet`), never a widget parameter — so the
// designer picks it here the way the viewport picks it at runtime.
//
// All three Style defaults drive both variants, and all three are
// direction-relative, which is why one set of writes serves both axes: the
// widget is a single `Flex(direction:, mainAxisAlignment:, crossAxisAlignment:,
// spacing:)` whose alignment fields mean "along/across whichever axis is
// currently the main one" — the same thing Figma's primary/counter pair means.
//
// `crossAxisAlignment` (`center`) is the one with an immediately visible
// effect; the canvas previously left it at Figma's `MIN`, so the preview packed
// its children to the top of a Row where the widget centres them.
// `mainAxisAlignment` (`start`) happens to coincide with `MIN` today and shows
// nothing while both axes hug, but it is read rather than assumed — the point
// of reading it is that the canvas follows coui_core if that default ever
// changes, which a coincidence does not.
function buildResponsiveRowColumn(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = RESPONSIVE_ROW_COLUMN.fields;
  const directions: { label: string; mode: 'HORIZONTAL' | 'VERTICAL' }[] = [
    { label: 'Row', mode: 'HORIZONTAL' },
    { label: 'Column', mode: 'VERTICAL' },
  ];
  const mount = mountSet(
    page,
    'ResponsiveRowColumn',
    directions.map((d) => `Direction=${d.label}`),
  );
  for (const d of directions) {
    const c = mount.getOrCreate(`Direction=${d.label}`);
    applyPanelCompChrome(c, d.mode, lk, { gap: f.spacing });
    c.primaryAxisAlignItems = mainAxisAlign(f.mainAxisAlignment.choice);
    c.counterAxisAlignItems = crossAxisAlign(f.crossAxisAlignment.choice);
    for (const variant of kRowColumnChildVariants) {
      const child = slotStandIn(page, 'children[]', variant);
      c.appendChild(child);
    }
  }
  const set = mount.finish();
  rowSet(set);
  return set;
}

// ─── ScrollArea ──────────────────────────────────────────────────────────────

// A viewport that keeps its content fully visible and lets a slim scrollbar
// communicate the overflow. The widget wraps its scroll view in exactly one
// `Scrollbar` and raw-forwards its nested `scrollbarStyle` slot to it, so this
// composes that component and hands it the same four values (`thickness`,
// `minThumbLength`, `thumbColor`, `trackColor`) as instance overrides. The
// child is drawn taller than the viewport so the thumb has something to be a
// fraction of.
//
// `trackColor` resolves to `.transparent` (alpha 0) here, so the composed
// scrollbar's track paints nothing — that is what the data says, not a
// simplification. `showScrollbar` only flips the composed scrollbar's
// `visibility` (the widget composes it either way), and `direction` (vertical
// by default) is a semantic enum with no dispatch table; the preview shows the
// default axis.
function buildScrollArea(page: PageNode, lk: VarLookup): ComponentNode {
  const bar = SCROLL_AREA.fields.scrollbarStyle;
  const c = mint(page, 'ScrollArea');
  c.fills = [];
  c.clipsContent = true;
  const content = overflowingContent(page);
  c.appendChild(content.column);
  content.column.x = 0;
  content.column.y = 0;
  c.resize(content.rowWidth, kViewportHeight);
  // A scroll view's cross axis is tight and its main axis is not: the content
  // spans the viewport's width and keeps its own height past the bottom edge.
  // STRETCH×MIN — a second write here used to say STRETCH×STRETCH and win,
  // which told a taller viewport to shrink the overflow to its own height
  // (#4826); the overflow IS the content, and the viewport shows a part of it.
  content.column.constraints = { horizontal: 'STRETCH', vertical: 'MIN' };
  // `child` is `W` — required, so swap only, no BOOLEAN.
  bindViewportChild(page, propertyOwner(c), content.rows);
  const scrollbar = composeScrollbar(page, lk, {
    axis: 'vertical',
    trackLength: kViewportHeight,
    thickness: bar.thickness,
    thumbLength: bar.minThumbLength,
    thumbColor: colorData(bar.thumbColor),
    trackColor: colorData(bar.trackColor),
  });
  // Through `pinAbsolute`, which wraps the instance in a holder: `constraints`
  // is refused on an instance outright, and the bar has to be measured from the
  // right edge and span the height or it stays put while a resized frame's edge
  // moves away from it.
  pinAbsolute(c, scrollbar, c.width - scrollbar.width, 0, {
    horizontal: 'MAX',
    vertical: 'STRETCH',
  });
  return c;
}

// ─── Scrollbar ───────────────────────────────────────────────────────────────

// The scrollbar itself, standalone. The component node is the track — it is as
// wide as the bar's footprint (the thumb plus the gap it keeps from the edge on
// both sides) and its fill is `trackColor`, which is `.transparent`, so the
// track reads as the space the thumb travels rather than as a painted rail
// (that is what the data says, not a simplification). The thumb inside carries
// `thumbColor` / `thumbRadius` / `thickness` / `minThumbLength`, and sits
// `thumbInset` in from the track's edge on every side.
//
// The thumb's colour is the surface ink at a stated strength, and the strength
// is the NODE's: the fill is `color/on-surface`, the layer's opacity is bound to
// the `opacity/<n>` step that holds it (`fillDataOnNode`). A paint cannot carry
// a bound colour below full strength, and a literal 0.5 would render the same
// pixels while hiding which token states it.
//
// Track length is the one thing the Style cannot supply — how far a thumb
// travels depends on the content, not on the scrollbar — so it is derived
// from `minThumbLength` (twice it), which puts the thumb at half the track and
// makes "there is more content" legible without inventing a length.
// `axis` / `visibility` / `interactive` are semantic + behaviour fields with
// no dispatch table; the fade timings on the Contract (`timeToFadeMs` /
// `fadeDurationMs`) are animation, which a static component cannot carry. The
// hover and drag look (`hoverThumbColor` / `hoverThickness`) is a pose of the
// thumb, and the canvas draws one — the resting vertical bar; it has no State
// axis to hold the other.
//
// `child` — the content the bar scrolls — is a real slot on the contract
// (`W?`) and now a real node here, off by default. Every parent in this file
// composes the bar *beside* its own content instead of inside it, because a
// Figma instance cannot be given children (`composeScrollbar` / the wrapper
// note on `drawFocusOutline`), so an instance of this component is a bar and
// nothing else — which is exactly the `child: null` the parents construct. A
// designer using `Scrollbar` on its own switches the region on and swaps the
// placeholder for whatever it wraps. Without the node there is no property,
// and without the property the slot claims it can only ever be empty.
function buildScrollbar(page: PageNode, lk: VarLookup): ComponentNode {
  const f = SCROLLBAR.fields;
  const inset = dimVal(f.thumbInset);
  const trackLength = dimVal(f.minThumbLength) * kHalf;
  const footprint = dimVal(f.thickness) + inset * kBothSides;
  const c = mint(page, 'Scrollbar');
  fillData(c, lk, colorData(f.trackColor));
  // The footprint is derived from two fields, not a field of its own, so there is
  // no variable for it to bind to — the thumb's thickness is the value a token
  // names, and it is bound on the thumb below.
  c.resize(footprint, trackLength);
  // Appended before the thumb so the thumb draws over the content it scrolls,
  // the way the widget stacks them. The track is this component's own fill and
  // so paints *under* the child rather than over it — which the widget does not
  // do, and which only stays invisible because `trackColor` resolves to
  // `.transparent`. Painting the track as its own rectangle would fix the order
  // and is the change to make if that colour ever stops being transparent.
  const child = optionalSlot(page, 'child', kSlotRect);
  c.appendChild(child.holder);
  child.holder.x = 0;
  child.holder.y = 0;
  // The wrapped content spans the scrollbar's box (#4805).
  child.holder.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };
  // Matches the BOOLEAN's default, so the main component reads the same way an
  // un-overridden instance of it does — and the same way every parent here
  // composes it.
  child.holder.visible = false;
  const thumb = figma.createRectangle();
  thumb.name = 'thumb';
  bindSize(thumb, lk, f.thickness, f.minThumbLength);
  bindRadiusN(thumb, lk, f.thumbRadius.topLeft);
  fillDataOnNode(thumb, lk, colorData(f.thumbColor));
  c.appendChild(thumb);
  thumb.x = inset;
  thumb.y = inset;
  // The thumb's thickness is the component's own (declared fixed), so MIN
  // across. Along the track it STRETCHes: it grows with a longer track (#4805)
  // while holding the inset at the near edge. That edge is what matters — the
  // pin is the only thing that keeps the gap in a composed bar, because
  // `composeScrollbar` resizes an instance and cannot move the thumb inside it
  // (#5438). SCALE scaled the gap with the track and put the thumb off its
  // inset in every bar whose track is not this one's.
  thumb.constraints = { horizontal: 'MIN', vertical: 'STRETCH' };
  const owner = propertyOwner(c);
  bindVisibleProp(child.holder, defineProp(owner, 'Show child', 'BOOLEAN', false));
  bindSwapProp(
    child.content,
    defineProp(owner, 'child', 'INSTANCE_SWAP', slotStandInDefault(page, kSlotRect)),
  );
  // `Scrollbar` is a composition target (`ScrollArea` / `ScrollableClient` /
  // `FadeScroll` all instantiate it), and `instanceOf` resolves by scanning
  // `page.children` — so being a child of `page` is a hard requirement of this
  // component, not an incidental fact. `figma.createComponent()` happens to
  // attach to the current page for us, which makes that requirement invisible:
  // it holds only while `page` is the current page, and nothing states it. A
  // set-valued sibling gets the same attachment explicitly, from
  // `combineAsVariants(comps, page)` inside `mountSet().finish()`; a single
  // component has no equivalent, so it says it here. `appendChild` on a node
  // already parented to `page` is a reorder, and placement assigns x/y after
  // every builder runs.
  page.appendChild(c);
  return c;
}

// ─── ScrollableClient ────────────────────────────────────────────────────────

// The two-dimensional scrollable client: a viewport, a `Scrollbar` per axis,
// and the focus ring it shows when focused.
//
// Two scrollbars, not one, because the widget composes two — a vertical
// `Scrollbar` wrapping a horizontal one, each bound to its own controller,
// because `TwoDimensionalScrollable` exposes two independent scroll positions
// and one scrollbar cannot detect both. Its `showScrollbar` defaults to true,
// so both are present at rest.
//
// Both are handed the same flat fields the widget packs into the
// `CoreScrollbarStyle` it passes down (`scrollbarThickness`,
// `scrollbarThumbColor`, `scrollbarTrackColor`, `scrollbarRadius`, and the thumb
// length derived from the viewport). Unlike `ScrollArea` this one *does* paint a
// track — `scrollbarTrackColor` is a real surface token here, not transparent —
// and it fills the bar's whole footprint, the thumb plus the gap it keeps from
// the edge. `scrollbarRadius` is radius/4, and the composed child rests at a
// capsule, so it IS re-stated as an override. The widget forwards no inset, so
// the child's own gap stands on both bars.
//
// The focus outline is on the root because that is the node the widget
// outlines, and because a wrapper cannot be an instance — see
// `drawFocusOutline`. `focusOutlineStyle` carries the border colour but no
// width, so `borderData` binds its default stroke step. Its
// `circleBorderRadius` describes a circular focus target and its `duration` is
// the ring's fade — neither applies to a rectangular client drawn at rest, and
// Figma has no node field a duration binds to.
function buildScrollableClient(page: PageNode, lk: VarLookup): ComponentNode {
  const f = SCROLLABLE_CLIENT.fields;
  const c = mint(page, 'ScrollableClient');
  c.fills = [];
  c.clipsContent = true;
  // The viewport itself is square — `ScrollableClient` states no radius of its own
  // (its fields are the two scrollbar values plus the ring), so the ring follows
  // the node it hugs rather than a corner the component does not have.
  drawFocusOutline(c, lk, f.focusOutlineStyle, 0);
  const content = overflowingContent(page);
  c.appendChild(content.column);
  content.column.x = 0;
  content.column.y = 0;
  // A scroll view's cross axis is tight: the content spans the viewport's
  // width and overflows its height (#4805).
  content.column.constraints = { horizontal: 'STRETCH', vertical: 'MIN' };
  c.resize(content.rowWidth, kViewportHeight);
  // `child` is `W?` here (a client with nothing in it still scrolls its own
  // extent), so the column doubles as the BOOLEAN's region — it is already the
  // frame the whole slot lives in, so no extra holder is needed — and the rows
  // inside it carry the swap. Default ON, because that is what the preview
  // draws; switching it off is the `null`.
  const owner = propertyOwner(c);
  bindVisibleProp(content.column, defineProp(owner, 'Show child', 'BOOLEAN', true));
  bindViewportChild(page, owner, content.rows);
  const thumbColor = colorData(f.scrollbarThumbColor);
  const trackColor = colorData(f.scrollbarTrackColor);
  const vertical = composeScrollbar(page, lk, {
    axis: 'vertical',
    trackLength: kViewportHeight,
    thickness: f.scrollbarThickness,
    thumbLength: kViewportHeight / kHalf,
    thumbColor,
    trackColor,
    thumbRadius: f.scrollbarRadius,
  });
  c.appendChild(vertical);
  vertical.x = c.width - vertical.width;
  vertical.y = 0;
  const horizontal = composeScrollbar(page, lk, {
    axis: 'horizontal',
    trackLength: c.width,
    thickness: f.scrollbarThickness,
    thumbLength: c.width / kHalf,
    thumbColor,
    trackColor,
    thumbRadius: f.scrollbarRadius,
  });
  c.appendChild(horizontal);
  horizontal.x = 0;
  horizontal.y = c.height - horizontal.height;
  return c;
}

// ─── ScrollViewInterceptor ───────────────────────────────────────────────────

// Wraps a scroll view and turns a drag near its edge into auto-scrolling. Both
// of its fields (`dragSpeed`, `maxScrollSpeed`) are rates, not chrome — they
// have no ref on any token scale and nothing on a static canvas moves at a
// speed — so this node draws only what it structurally is: the clipping
// viewport its child scrolls inside. Drawing an edge affordance (an arrow, a
// hot-zone band) would assert chrome the widget never paints; the intercept is
// invisible by design, and a preview that showed it would be describing a
// different component.
function buildScrollViewInterceptor(page: PageNode, lk: VarLookup): ComponentNode {
  const c = mint(page, 'ScrollViewInterceptor');
  c.fills = [];
  c.clipsContent = true;
  const content = overflowingContent(page);
  c.appendChild(content.column);
  content.column.x = 0;
  content.column.y = 0;
  // A scroll view's cross axis is tight: the content spans the viewport's
  // width and overflows its height (#4805).
  content.column.constraints = { horizontal: 'STRETCH', vertical: 'MIN' };
  c.resize(content.rowWidth, kViewportHeight);
  // `child` is `W?` — the interceptor is an edge-drag behaviour and holds
  // whether or not a scroll view was handed to it. Column = the region the
  // BOOLEAN hides, rows = what the swap re-points.
  const owner = propertyOwner(c);
  bindVisibleProp(content.column, defineProp(owner, 'Show child', 'BOOLEAN', true));
  bindViewportChild(page, owner, content.rows);
  return c;
}

// ─── FadeScroll ──────────────────────────────────────────────────────────────

// A scroll viewport whose edges fade to hint at content past the view. The two
// fade extents are real Style defaults (`startOffset` / `endOffset`) and are
// drawn as the bands they cover, bound to those tokens — so the *size* of the
// fade is inspectable and tracks coui_core.
//
// The bands are not painted, and the reason is not that there is no colour:
// `CoreFadeScrollStyle.defaultGradient` is `[onSurface, transparent]` and
// components.json carries both stops. Those two are not a surface colour. The
// widget feeds them to a `ShaderMask` with `BlendMode.dstIn`, where — its own
// words — "the mask is monochrome (only alpha matters)": the opaque stop keeps
// the child, the transparent stop erases it. `onSurface`'s RGB never reaches a
// pixel. Filling the band with an on-surface→transparent ramp would therefore
// darken the content instead of dissolving it, which is a worse picture than an
// unpainted band, so the extent is bound and the ramp is left alone.
//
// The ramp itself is expressible and is a real remaining gap: an alpha mask is
// a Figma layer mask with a gradient fill, applied to the scroll content rather
// than drawn as a box beside it. It is not done here because it changes what
// the component paints, which is a builder change and not this pass's.
//
// `showScrollbar` attaches the design system's `Scrollbar` (and suppresses the
// ambient platform one when off), so the composed child is here — behind a
// BOOLEAN property defaulting to `false`, which is the widget's own default and
// therefore what the component reads as at rest. It is composed with no
// overrides because the widget forwards none: `Scrollbar(controller:, child:)`
// gets the child's own defaults, and re-stating them here would be this file
// keeping a second copy of them.
function buildFadeScroll(page: PageNode, lk: VarLookup): ComponentNode {
  const f = FADE_SCROLL.fields;
  const c = mint(page, 'FadeScroll');
  c.fills = [];
  c.clipsContent = true;
  const content = overflowingContent(page);
  c.appendChild(content.column);
  content.column.x = 0;
  content.column.y = 0;
  // A scroll view's cross axis is tight: the content spans the viewport's
  // width and overflows its height (#4805).
  content.column.constraints = { horizontal: 'STRETCH', vertical: 'MIN' };
  c.resize(content.rowWidth, kViewportHeight);
  const owner = propertyOwner(c);
  // `child` is `W` — required, so swap only, no BOOLEAN.
  bindViewportChild(page, owner, content.rows);
  const startBand = extentBox('fade start');
  c.appendChild(startBand);
  bindAxisSize(startBand, lk, { width: c.width, height: f.startOffset, bind: 'height' });
  startBand.x = 0;
  startBand.y = 0;
  startBand.constraints = { horizontal: 'STRETCH', vertical: 'MIN' };
  const endBand = extentBox('fade end');
  c.appendChild(endBand);
  bindAxisSize(endBand, lk, { width: c.width, height: f.endOffset, bind: 'height' });
  endBand.x = 0;
  endBand.y = c.height - endBand.height;
  endBand.constraints = { horizontal: 'STRETCH', vertical: 'MAX' };
  const scrollbar = composeScrollbar(page, lk, {
    axis: 'vertical',
    trackLength: kViewportHeight,
  });
  c.appendChild(scrollbar);
  scrollbar.x = c.width - scrollbar.width;
  scrollbar.y = 0;
  bindVisibleProp(scrollbar, defineProp(owner, 'showScrollbar', 'BOOLEAN', false));
  return c;
}

// ─── OverflowMarquee ─────────────────────────────────────────────────────────

// Scrolls content that overflows its box, with a fade at the edge it scrolls
// under. The child is drawn wider than the viewport — that overflow is the
// precondition for the widget doing anything at all — and the `fadePortion`
// band at the trailing edge is bound to its token, unpainted for the same
// reason as `FadeScroll`'s: there is no colour field, the fade resolves
// against the caller's surface.
//
// `duration` / `delayDuration` / `step` are the marquee's animation timing and
// travel distance per tick. They are the component's real defaults but no
// static node can carry them, and Figma has no node field a duration binds to.
function buildOverflowMarquee(page: PageNode, lk: VarLookup): ComponentNode {
  const f = OVERFLOW_MARQUEE.fields;
  const c = mint(page, 'OverflowMarquee');
  c.fills = [];
  c.clipsContent = true;
  const child = slotStandIn(page, 'child', kSlotText);
  c.appendChild(child);
  child.x = 0;
  child.y = 0;
  c.resize(kMarqueeViewportWidth, child.height);
  const fade = extentBox('fade');
  c.appendChild(fade);
  bindAxisSize(fade, lk, { width: f.fadePortion, height: c.height, bind: 'width' });
  fade.x = c.width - fade.width;
  fade.y = 0;
  // `child` is `W` — required, so swap only. Its default is the `text`
  // stand-in, the shape the marquee is drawn with: a run of copy is what
  // overflows a narrow box, which is the case the widget exists for.
  bindSwapProp(
    child,
    defineProp(propertyOwner(c), 'child', 'INSTANCE_SWAP', slotStandInDefault(page, kSlotText)),
  );
  return c;
}

// ─── StageContainer ──────────────────────────────────────────────────────────

// Sits its content on a breakpoint rung by measuring the viewport and turning
// the leftover width into equal side gutters. `padding` is the *minimum*
// gutter, and it is the whole visible statement: the stage stops short of both
// edges by exactly that inset (top/bottom pass through as zero). The extra
// redistribution on top of it is a function of the live viewport width, which
// a static preview has no way to vary.
//
// The stage content is drawn even though `slots` is empty in components.json:
// `StageContainer` hands its content back through a `builder` callback rather
// than a widget field, so the exporter records no slot. The node it returns
// still renders inside this box, and a container drawn without it would say
// the gutters surround nothing.
function buildStageContainer(page: PageNode, lk: VarLookup): ComponentNode {
  const c = mint(page, 'StageContainer');
  c.layoutMode = 'HORIZONTAL';
  c.primaryAxisSizingMode = 'AUTO';
  c.counterAxisSizingMode = 'AUTO';
  c.fills = [];
  bindPad(c, lk, STAGE_CONTAINER.fields.padding);
  const stage = slotStandIn(page, 'builder(padding)', kSlotRect);
  c.appendChild(stage);
  return c;
}

// ─── AppBar ──────────────────────────────────────────────────────────────────

// What each `Leading` pose previews. `none` still draws the back glyph so the
// item holds the same content as its siblings — the pose hides the ITEM, which
// is what the designer's own `leading=none` members do.
const kAppBarLeadingGlyphs: Record<string, string> = {
  none: 'arrow-left',
  back: 'arrow-left',
  close: 'x',
  menu: 'menu',
};

// The `Leading` pose that draws WORDS instead of a glyph. Not in the table
// above — it has no glyph; its item is a composed `Button` (see the header).
const kAppBarLeadingText = 'text';

// The `Button` a words-only action is: `Button(variant: .ghost, child:
// Text('…'))` — the way an app that shows its back and its trailing action as
// text writes them into `leading` / `trailing`. Every axis is named so the
// score lands on ONE member: `bestVariantName` scores only the axes it is given
// and breaks a tie on set order, so a call that named `Variant` and `Size`
// alone would land on whichever `State` / `Shape` the set listed first.
//
// `Size: md` is `CoreComponentSize`'s default — an app that names no size gets
// it — and its 40px row sits inside every bar this component draws (the lowest,
// `dense`, is 48; `medium` states its top row at 48). `ghost` is the quiet one:
// no fill at rest, so the item reads as words, with the hover wash a pointer
// shows. `State`/`Shape` are `Button`'s own resting members.
const kAppBarTextButtonAxes: Record<string, string> = {
  Variant: 'ghost',
  Size: 'md',
  State: 'enabled',
  Shape: 'rectangle',
};

// What each composed words-only action reads until an instance overrides its
// `Child`. "뒤로" is the back affordance spelled out; "목록으로" is the trailing
// action a screen that returns to its list shows.
const kAppBarLeadingLabelCopy = '뒤로';
const kAppBarTrailingLabelCopy = '목록으로';

// The trailing words' colour — the token the widget code states,
// `CoreButtonStyle(foregroundColor: CoreColor.token(CoreColors.onSurfaceVariant))`.
const kAppBarTrailingWordsColor = 'on-surface-variant';

// The layer names the two composed buttons carry. The name is what the
// instance's panel section is titled once the button is exposed (see
// `buildAppBar`), so it is the designer-facing handle for the words — spelled as
// the property it stands in for, not as the layout role (`leading`).
const kAppBarLeadingLabelNode = 'Leading label';
const kAppBarTrailingLabelNode = 'Trailing label';

// The top app bar. The designer authored this set FIRST (❖ AppBar, set
// 3064:502) and that canvas is this builder's spec: the axes, the per-variant
// geometry and the property spellings (`title` / `action 1` / `action 2` /
// `divider` / `elevated`) all reproduce it, so `mountSet` adopts the existing
// 24 members (via the AppBar rows in VARIANT_RENAMES — the initial canvas
// spelled the pose axes lower-case) and `defineProp`'s mint-by-name reuses the
// designer's property keys, keeping every instance override alive.
//
// Axes. `Variant` is the contract's own enum (`CoreAppBarVariant`) — it picks
// the bar height, the title's typography role and, for `medium`, a two-row
// layout with the title on its own bottom-aligned line; `dense` also states
// its own face and cluster gaps, which the member reads before the shared
// fields. `Leading` and `Align`
// are POSE axes the way Tabs' `Selected` is: `leading` is a `List<W>` caller
// slot the widget states no content for, so the axis previews the common
// affordances (none/back/close/menu, and `text` — words instead of a glyph) and
// doubles as the item's visibility; `Align` is `centerTitle`'s two values and
// moves only the title text's alignment — the designer's `medium/menu/center`
// members keep their Leading item visible, so alignment says nothing about the
// item.
//
// Words as an action (`Leading=text`, `Show trailing text`). An app that shows
// its back and its trailing action as words rather than glyphs writes
// `leading: [Button(variant: .ghost, child: Text('뒤로'))]` and `trailing:
// [Button(variant: .ghost, buttonStyle: …onSurfaceVariant, child:
// Text('목록으로'))]` — the bar already takes
// both, it states no content for either list. So the canvas draws those two as
// what they are: a real composed `Button` (ghost, md — `kAppBarTextButtonAxes`),
// not a text node dressed up to look like one, so a change to `Button` reaches
// the bar. The words are the button's own `Child`, and the button is EXPOSED, so
// its properties show on the bar's panel under the layer's name (`Leading
// label` / `Trailing label`). Figma will not bind a set-level TEXT property to a
// node inside an instance (`componentPropertyReferences` is rejected on an
// instance sublayer — the wall `composeCountBadge` in instance-reach.ts
// records), so a `Leading label` / `Trailing label` property on the bar itself
// is not available; the exposed `Child` is the one way Figma has to put the
// words on the parent. The trailing words are a separate item beside the
// `trailing` cluster, not a third item in it: the cluster's visibility is
// `action 1`, and a words-only bar must show its action without drawing a glyph
// it does not have. With glyph actions AND words both on, the two sit one bar
// `spacing` apart where the code puts one `actionSpacing` — the same number on
// every variant but `dense` (bar gap 14, action gap 8).
//
// Member shape (standard/compact/dense — medium nests leading/trailing in a
// top row and bottom-aligns the title area):
//
// ```text
// root (HORIZONTAL h=height, fill backgroundColor, padding, gap spacing)
//   ├─ elevated (RECTANGLE, index 0, STRETCH×STRETCH, hidden — the shadow
//   │            surface `elevated` toggles)
//   ├─ leading (HUG item, glyph at the ambient icon size — hidden when
//   │           Leading=none; Leading=text holds the composed `Leading label`
//   │           Button instead of a glyph)
//   ├─ title area (VERTICAL FILL×FILL, titlePadding)
//   │    ├─ header holder (hidden `W?` slot)
//   │    ├─ title (TEXT, titleStyle role — `Align` sets its alignment)
//   │    ├─ subtitle holder (hidden `W?` slot)
//   │    └─ child holder (hidden `W?` slot)
//   ├─ trailing (HUG cluster, gap actionSpacing — hidden: `action 1` is the
//   │    │        cluster existing at all, i.e. `trailing` is not empty)
//   │    ├─ action 1 (first item — always drawn inside the cluster)
//   │    └─ action 2 (second item — `action 2` toggles, hidden)
//   ├─ trailing text (composed `Trailing label` Button, hidden — `Show
//   │                  trailing text` toggles; beside the cluster, see above)
//   └─ divider (RECTANGLE, absolute at the bottom edge, dividerWidth ×
//              dividerColor — `divider` toggles)
// ```
//
// Why `action 1` sits on the cluster and not on its first item: `trailing`
// defaults to `const []` on both platforms, and an empty list draws no
// cluster — Flutter `if (trailing.isNotEmpty)`, Web
// `trailing.isEmpty ? null : …`. Leaving out the cluster also leaves out the
// bar's `spacing` gap in front of it, because the row has one child fewer.
// Hiding only the first item would keep an empty HUG frame in the row, and the
// root's `itemSpacing` would still open a gap before it: the title area would
// come out narrower than the code's, and a centred title would shift. So the
// whole cluster hides. `action 2` stays on the second item, so it means "a
// second item". With `action 1` off, `action 2` has nothing to show; the code
// cannot build that combination either, because a list cannot have a second
// item without a first.
function buildAppBar(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = APP_BAR.fields;
  const variantData = new Map(Object.entries(APP_BAR.variants.defaultsByVariant));
  const combos = enumerateAxisCombos([
    ...axisSpecsOf(APP_BAR.axes),
    { axis: 'Leading', values: ['none', 'back', 'close', 'menu', kAppBarLeadingText] },
    { axis: 'Align', values: ['start', 'center'] },
  ]);
  const mount = mountSet(page, 'AppBar', combos);
  // Collected across every member; the set-level properties are declared after
  // `finish()` — see the file header on property owners.
  const titleNodes: TextNode[] = [];
  const trailingClusters: FrameNode[] = [];
  const action2Boxes: FrameNode[] = [];
  const dividerRects: RectangleNode[] = [];
  const elevationRects: RectangleNode[] = [];
  const headerSlots: SlotNodes[] = [];
  const leadingSlots: SlotNodes[] = [];
  const trailingSlots: SlotNodes[] = [];
  const subtitleSlots: SlotNodes[] = [];
  const childSlots: SlotNodes[] = [];
  // The composed words-only `Button`s (`Leading=text` and the trailing item).
  // Exposed together once the set exists — `exposeAll` says why it cannot be
  // written where the instance is made — and the trailing ones also take the
  // `Show trailing text` binding.
  const textButtons: InstanceNode[] = [];
  const trailingTextButtons: InstanceNode[] = [];
  // Named once, outside the member loop: every member asks the same question.
  const textButtonVariant = bestVariantName(page, 'Button', kAppBarTextButtonAxes);
  const textButton = (name: string, copy: string): InstanceNode => {
    const button = instanceOf(page, 'Button', textButtonVariant);
    button.name = name;
    setInstanceTextNamed(button, 'Child', copy);
    textButtons.push(button);
    return button;
  };

  // A title-area slot stretches to the column's width — the holder AND the
  // stand-in inside it.
  //
  // Left at their natural size both keep the stand-in's own 160×40 box, so a
  // designer who swaps in their own component inherits that box and has to
  // reach for the sizing panel after every swap. The widget stretches these
  // three anyway (Flutter `Column(crossAxisAlignment: .stretch)`, and the Web
  // title wrapper is `flex flex-col`, whose `align-items` defaults to
  // `stretch`), so filling is not a canvas convenience — it is the pose the
  // code already draws.
  //
  // Vertical stays HUG: the column's height is its content's, and `child`
  // replacing the column must not force the bar taller than its variant.
  //
  // Reading this back on the canvas needs care: all three ship hidden, and
  // Figma reports a hidden auto-layout child's sizing as `FIXED` at its
  // intrinsic width — so a resting member shows `FIXED`/160 here even though
  // the fill is set. Reveal the slot on a `clone()` to see the authored
  // value (measured: shown `FILL`/224 on the single-row variants, 328 on
  // medium).
  //
  // `optionalSlot` itself is left alone — eight call sites across Scaffold and
  // others share it, and widening the default there would move canvases this
  // change has no claim on.
  const fillSlotWidth = (s: SlotNodes): void => {
    s.holder.layoutSizingHorizontal = 'FILL';
    s.content.layoutSizingHorizontal = 'FILL';
  };

  for (const comboName of combos) {
    const combo = parseVariantKey(comboName);
    const vs = variantData.get(combo['Variant']);
    if (!vs) throw new Error(`AppBar: no data for combo "${comboName}"`);
    const medium = combo['Variant'] === 'medium';
    // The variant row's own chrome before the shared field — the order both
    // resolvers read it in (`merged.X ?? vs.X ?? defaultX`). A row that
    // states no inset, gap or face (every row but dense states no face or
    // gap) falls through to the field default.
    const row = vs as {
      padding?: PadData;
      spacing?: Dim;
      actionSpacing?: Dim;
      backgroundColor?: Color;
    };
    const barPadding = row.padding ?? f.padding;
    const barSpacing = row.spacing ?? f.spacing;
    const barFace = colorData(row.backgroundColor ?? f.backgroundColor);

    const c = mount.getOrCreate(comboName);
    c.layoutMode = medium ? 'VERTICAL' : 'HORIZONTAL';
    c.primaryAxisSizingMode = 'FIXED';
    c.counterAxisSizingMode = 'FIXED';
    fillData(c, lk, barFace);
    // Height IS data (defaultsByVariant.height), bound to its size step; the
    // width is not — the widget takes it from the parent's constraints.
    // g7-preview-only: preview width, no root extent field in the code.
    bindSize(c, lk, 360, dimVal(vs.height));

    // One item of the `leading` / `trailing` lists. Both are `List<W>` the bar
    // renders as handed — Flutter puts them straight into a `Row`, Web into
    // the cluster `<div>`, and neither mounts an `IconTheme` or states a size
    // — so an `Icon` passed there draws at the app root's ambient icon size,
    // and brings no box with it. That is what the shipped Scaffold examples
    // hand their header bar (`trailing: const [Icon(LucideIcons.settings)]`),
    // so the item is the glyph and its frame hugs it. The AppBar docs
    // examples wrap the glyph in a `Button(variant: .plain)` instead, whose
    // default `md` size gives the glyph its own row's `leadingIconStyle` (16),
    // smaller than the ambient 20 this item draws; the button's own box is the
    // caller's widget, not anything the bar states.
    const slotItem = (name: string, glyph: string): FrameNode => {
      const item = autoFrame(name, 'HORIZONTAL');
      item.counterAxisAlignItems = 'CENTER';
      item.appendChild(makeIcon(glyph, lk, { size: ICON.constants.ambientSize }));
      return item;
    };

    // `Leading=text` holds the composed words-only `Button` where the other
    // poses hold a glyph. The item keeps the name and the hug of its siblings —
    // it is still the bar's `leading` item, and the button is what it holds.
    let leading: FrameNode;
    if (combo['Leading'] === kAppBarLeadingText) {
      leading = autoFrame('leading', 'HORIZONTAL');
      leading.counterAxisAlignItems = 'CENTER';
      leading.appendChild(textButton(kAppBarLeadingLabelNode, kAppBarLeadingLabelCopy));
    } else {
      leading = slotItem('leading', kAppBarLeadingGlyphs[combo['Leading']]);
    }
    if (combo['Leading'] === 'none') leading.visible = false;

    // Hidden at rest: `trailing` defaults to `const []`, so the bar draws no
    // cluster (see the header for why `action 1` drives this frame).
    const actions = autoFrame('trailing', 'HORIZONTAL');
    actions.counterAxisAlignItems = 'CENTER';
    bindSpaceField(actions, 'itemSpacing', lk, dimVal(row.actionSpacing ?? f.actionSpacing));
    actions.visible = false;
    trailingClusters.push(actions);
    const action1 = slotItem('action 1', 'circle-dashed');
    actions.appendChild(action1);
    const action2 = slotItem('action 2', 'circle-dashed');
    action2.visible = false;
    actions.appendChild(action2);
    action2Boxes.push(action2);

    // The trailing words — `trailing: [Button(variant: .ghost, child:
    // Text('…'))]`. Hidden at rest like the cluster (`trailing` is `const []`);
    // `Show trailing text` is its own switch because the cluster's is `action
    // 1` (see the header for why the words are not a third item in it).
    const trailingText = textButton(kAppBarTrailingLabelNode, kAppBarTrailingLabelCopy);
    // One tier quieter than the back action: the same `ghost` button with its
    // words in `onSurfaceVariant` — `buttonStyle: CoreButtonStyle(foregroundColor:
    // onSurfaceVariant)`. Recoloured rather than
    // swapped to `plain`, because the code's `plain` is flush (no inline
    // padding) and would pull the words 16 closer to the bar's edge.
    const trailingWords = instanceTextNode(trailingText);
    if (trailingWords) fillSem(trailingWords, lk, kAppBarTrailingWordsColor);
    trailingText.visible = false;
    trailingTextButtons.push(trailingText);

    // The `leading` / `trailing` lists as composition points — one swap each,
    // the first item a caller hands. Beside the pose items rather than inside
    // them: the `Leading` axis previews the glyph a pose stands for, and a
    // swap bound inside it would replace that glyph on every pose at once.
    // Hidden at rest, like the lists' `const []`; circular because what a bar
    // is handed there is an icon-sized control.
    const leadingSlot = optionalSlot(page, 'leading slot', kSlotCircle);
    leadingSlot.holder.counterAxisAlignItems = 'CENTER';
    leadingSlot.holder.visible = false;
    leadingSlots.push(leadingSlot);
    const trailingSlot = optionalSlot(page, 'trailing slot', kSlotCircle);
    trailingSlot.holder.counterAxisAlignItems = 'CENTER';
    trailingSlot.holder.visible = false;
    trailingSlots.push(trailingSlot);

    // The title area carries the three optional `W?` slots around the title
    // text — hidden holders, so the resting pose is the widget's own default
    // (`header` / `subtitle` / `child` are null unless a caller passes one).
    const titleArea = autoFrame('title area', 'VERTICAL');
    bindPad(titleArea, lk, vs.titlePadding);
    // `medium` bottom-aligns its title line (designer: primary MAX); the
    // single-row variants centre it in the bar.
    titleArea.primaryAxisAlignItems = medium ? 'MAX' : 'CENTER';
    const header = optionalSlot(page, 'header', kSlotRect);
    header.holder.visible = false;
    titleArea.appendChild(header.holder);
    fillSlotWidth(header);
    headerSlots.push(header);
    const title = makeLabel('홈', lk, textLabelOpts(lk, textStyleData(vs.titleStyle)));
    title.name = 'title';
    titleArea.appendChild(title);
    // A centred single row sits its title on the bar's centre, one line —
    // see the `start` / `end` sides below. Every other pose fills the room
    // between the clusters.
    const barCentred = combo['Align'] === 'center' && !medium;
    if (!barCentred) title.layoutSizingHorizontal = 'FILL';
    title.textAlignHorizontal = combo['Align'] === 'center' ? 'CENTER' : 'LEFT';
    titleNodes.push(title);
    const subtitle = optionalSlot(page, 'subtitle', kSlotRect);
    subtitle.holder.visible = false;
    titleArea.appendChild(subtitle.holder);
    fillSlotWidth(subtitle);
    subtitleSlots.push(subtitle);
    const child = optionalSlot(page, 'child', kSlotRect);
    child.holder.visible = false;
    titleArea.appendChild(child.holder);
    fillSlotWidth(child);
    childSlots.push(child);

    if (medium) {
      // Two rows: leading + spacer + actions across the top at topRowHeight,
      // the title area filling the rest. The bar inset and gap live on the
      // top row here — the root itself has none (designer: pad 0, gap 0).
      const topRow = autoFrame('top row', 'HORIZONTAL');
      topRow.counterAxisAlignItems = 'CENTER';
      bindPad(topRow, lk, barPadding);
      bindSpaceField(topRow, 'itemSpacing', lk, dimVal(barSpacing));
      topRow.appendChild(leading);
      topRow.appendChild(leadingSlot.holder);
      const spacer = autoFrame('spacer', 'HORIZONTAL');
      topRow.appendChild(spacer);
      spacer.layoutSizingHorizontal = 'FILL';
      spacer.layoutSizingVertical = 'FILL';
      topRow.appendChild(actions);
      topRow.appendChild(trailingText);
      topRow.appendChild(trailingSlot.holder);
      c.appendChild(topRow);
      topRow.layoutSizingHorizontal = 'FILL';
      topRow.layoutSizingVertical = 'FIXED';
      bindAxisSize(topRow, lk, {
        width: topRow.width,
        height: f.topRowHeight,
        bind: 'height',
      });
      c.appendChild(titleArea);
    } else if (barCentred) {
      // A centred single row holds its two sides at one width so the title
      // sits on the centre of the whole bar — both platforms size the sides
      // to the wider cluster (`max(leading, trailing)`; Flutter's
      // `_CenteredTitleLayout`, Web's measured grid columns). The canvas
      // cannot measure a caller's clusters, so the two sides split the
      // width the title leaves (FILL each), and the title's room is the
      // rule's with the widest trailing item — the words button — standing
      // in for `max(leading, trailing)`.
      c.counterAxisAlignItems = 'CENTER';
      bindPad(c, lk, barPadding);
      bindSpaceField(c, 'itemSpacing', lk, dimVal(barSpacing));
      const start = autoFrame('start', 'HORIZONTAL');
      start.counterAxisAlignItems = 'CENTER';
      bindSpaceField(start, 'itemSpacing', lk, dimVal(barSpacing));
      start.appendChild(leading);
      start.appendChild(leadingSlot.holder);
      const end = autoFrame('end', 'HORIZONTAL');
      end.primaryAxisAlignItems = 'MAX';
      end.counterAxisAlignItems = 'CENTER';
      bindSpaceField(end, 'itemSpacing', lk, dimVal(barSpacing));
      end.appendChild(actions);
      end.appendChild(trailingText);
      end.appendChild(trailingSlot.holder);
      c.appendChild(start);
      c.appendChild(titleArea);
      c.appendChild(end);
      start.layoutSizingHorizontal = 'FILL';
      end.layoutSizingHorizontal = 'FILL';

      const side = trailingText.width;
      const room =
        c.width -
        padHorizontal(barPadding) -
        2 * side -
        2 * dimVal(barSpacing) -
        padHorizontal(vs.titlePadding);
      title.layoutSizingHorizontal = 'HUG';
      title.textAutoResize = 'WIDTH_AND_HEIGHT';
      title.maxLines = 1;
      title.textTruncation = 'ENDING';
      title.maxWidth = Math.max(room, 0);
    } else {
      c.counterAxisAlignItems = 'CENTER';
      bindPad(c, lk, barPadding);
      bindSpaceField(c, 'itemSpacing', lk, dimVal(barSpacing));
      c.appendChild(leading);
      c.appendChild(leadingSlot.holder);
      c.appendChild(titleArea);
      c.appendChild(actions);
      c.appendChild(trailingText);
      c.appendChild(trailingSlot.holder);
    }
    titleArea.layoutSizingHorizontal = barCentred ? 'HUG' : 'FILL';
    titleArea.layoutSizingVertical = 'FILL';

    // divider — the bottom hairline, a filled rectangle the way Scaffold and
    // Table draw theirs (chrome, not a composed `Divider`): the root's own
    // stroke slot stays free and the BOOLEAN below toggles one node.
    const divider = figma.createRectangle();
    divider.name = 'divider';
    divider.resize(c.width, dimVal(f.dividerWidth));
    fillData(divider, lk, colorData(f.dividerColor));
    pinAbsolute(c, divider, 0, dimVal(vs.height) - dimVal(f.dividerWidth), {
      horizontal: 'STRETCH',
      vertical: 'MAX',
    });
    dividerRects.push(divider);

    // elevated — the shadow surface `elevated` toggles. A separate hidden
    // rectangle rather than effects on the root, so the toggle is one
    // `visible` flip a BOOLEAN can drive.
    const elevation = figma.createRectangle();
    elevation.name = 'elevated';
    elevation.resize(c.width, c.height);
    fillData(elevation, lk, barFace);
    setShadow(elevation, f.elevatedShadow, lk);
    // `insertChild` first, then pin — `pinAbsolute` appends, so pinning and
    // then moving to index 0 reparents the same node twice. Index 0 keeps the
    // surface behind everything: switched on, the cast draws around the bar
    // while the surface itself stays covered by the root's own fill.
    c.insertChild(0, elevation);
    pinInFlow(c, elevation);
    elevation.x = 0;
    elevation.y = 0;
    elevation.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };
    elevation.visible = false;
    elevationRects.push(elevation);
  }

  const set = mount.finish();
  // Property display names are the designer's, verbatim (`title#3065:0`,
  // `action 1#3065:25`, …) — `defineProp` mints by name+type, so matching the
  // spelling is what makes it reuse those keys instead of minting fresh ones,
  // and a reused key is what keeps instance overrides in consuming files.
  const titleProp = defineProp(set, 'title', 'TEXT', '홈');
  for (const node of titleNodes) bindTextProp(node, titleProp);
  // The title can be turned off, because the widget's `child` slot REPLACES
  // the header/title/subtitle column — both constructors assert
  // `child == null || title == null`. Without this the canvas can only ever
  // draw the two together, which is a state neither platform can render: a
  // designer who switches `Show child` on gets the placeholder AND the title,
  // and no handle to resolve it.
  //
  // A second BOOLEAN cannot express "exactly one of these" — Figma has no
  // such property — so this does not enforce the assert. It makes the legal
  // pose reachable, which is what was missing.
  const showTitle = defineProp(set, 'Show title', 'BOOLEAN', true);
  for (const node of titleNodes) bindVisibleProp(node, showTitle);
  // `action 1` defaults off: `trailing` is `const []` on both platforms, so a
  // bare AppBar has no actions. It drives the whole cluster (see the header).
  // A composer that shows an action switches it on on its own instance.
  const action1Prop = defineProp(set, 'action 1', 'BOOLEAN', false);
  for (const cluster of trailingClusters) bindVisibleProp(cluster, action1Prop);
  const action2Prop = defineProp(set, 'action 2', 'BOOLEAN', false);
  for (const box of action2Boxes) bindVisibleProp(box, action2Prop);
  // The trailing words: off, because `trailing` is `const []` and a bare AppBar
  // has no action of either kind. The leading words need no property — they are
  // the `Leading=text` pose. Both buttons' `Child` reach the bar's panel through
  // the exposure below.
  const showTrailingText = defineProp(set, 'Show trailing text', 'BOOLEAN', false);
  for (const button of trailingTextButtons) bindVisibleProp(button, showTrailingText);
  exposeAll(textButtons);
  const dividerProp = defineProp(set, 'divider', 'BOOLEAN', true);
  for (const rect of dividerRects) bindVisibleProp(rect, dividerProp);
  const elevatedProp = defineProp(set, 'elevated', 'BOOLEAN', false);
  for (const rect of elevationRects) bindVisibleProp(rect, elevatedProp);
  // The three optional `W?` slots, each the two-node shape from the file
  // header: the holder's BOOLEAN is the widget's `null`, the instance's swap
  // is "any widget". Defaults OFF — that is what every member draws.
  const slotDefault = slotStandInDefault(page, kSlotRect);
  const headerProp = defineProp(set, 'Header', 'INSTANCE_SWAP', slotDefault);
  const showHeader = defineProp(set, 'Show header', 'BOOLEAN', false);
  for (const s of headerSlots) {
    bindSwapProp(s.content, headerProp);
    bindVisibleProp(s.holder, showHeader);
  }
  const subtitleProp = defineProp(set, 'Subtitle', 'INSTANCE_SWAP', slotDefault);
  const showSubtitle = defineProp(set, 'Show subtitle', 'BOOLEAN', false);
  for (const s of subtitleSlots) {
    bindSwapProp(s.content, subtitleProp);
    bindVisibleProp(s.holder, showSubtitle);
  }
  const childProp = defineProp(set, 'Child', 'INSTANCE_SWAP', slotDefault);
  const showChild = defineProp(set, 'Show child', 'BOOLEAN', false);
  for (const s of childSlots) {
    bindSwapProp(s.content, childProp);
    bindVisibleProp(s.holder, showChild);
  }
  // `leading` / `trailing` are `List<W>` — repeated slots in `props.slots`,
  // drawn as one swap each (see the member loop), named for the item they
  // hold. Not bare `Leading`: that is the VARIANT axis's name, and Figma flags
  // a swap that shares it and leaves the whole set off the publish list (#5679
  // — AppBar went unpublished from #5512 on). `Trailing item` matches it.
  const slotItemDefault = slotStandInDefault(page, kSlotCircle);
  const leadingProp = defineProp(set, 'Leading item', 'INSTANCE_SWAP', slotItemDefault);
  const showLeading = defineProp(set, 'Show leading', 'BOOLEAN', false);
  for (const s of leadingSlots) {
    bindSwapProp(s.content, leadingProp);
    bindVisibleProp(s.holder, showLeading);
  }
  const trailingProp = defineProp(set, 'Trailing item', 'INSTANCE_SWAP', slotItemDefault);
  const showTrailing = defineProp(set, 'Show trailing', 'BOOLEAN', false);
  for (const s of trailingSlots) {
    bindSwapProp(s.content, trailingProp);
    bindVisibleProp(s.holder, showTrailing);
  }
  return set;
}

// ─── Scaffold ────────────────────────────────────────────────────────────────

// The app shell: header(s), an optional sidebar, the body, footer(s) and a
// floating action button. The `headers` and `footers` sections each hold a
// composed ❖ AppBar instance (`buildAppBar` above) — the widget each shipped
// example puts there — so the bar's chrome is AppBar's own rather than a
// second drawing of it. It has a real dispatch table
// (`variants.defaultsByVariant`), so it gets a real Figma axis — iterated,
// with one variant per key, rather than one key read out of the table. There
// is one key today (`standard`); the axis exists so a second surface added in
// coui_core shows up as a second variant instead of silently not existing.
//
// Everything chrome-bearing comes from that table plus `fields`: the shell's
// own background, the header's and footer's backgrounds, the hairline under
// the header (`headerBorderColor` / `headerBorderWidth`), and the FAB's
// offset from the bottom-right corner (`fabPadding`). The bar INSIDE a
// section — its inset, gaps, title role and actions — belongs to the composed
// `AppBar` and is not restated here.
//
// The hairline is a filled rectangle rather than a one-sided stroke on the
// header, matching how `Table` (layout.ts) draws its row separators — the
// border colour and width are the same two data fields either way, and the
// rectangle keeps the header's own stroke slot free.
//
// Three of its slots are single (`child`, `sidebar`, `floatingActionButton`) and
// all three get properties, declared after `mount.finish()` for the reason the
// header gives: before `combineAsVariants` a minted variant's parent is still
// the page, so `propertyOwner` would hand back the variant and each one would
// grow its own copy. `headers` / `footers` are `List<W>` and get no Scaffold
// property — Figma has no repeated-slot property, and a designer adds or
// removes those children directly. The composed bars are exposed instead, so
// their own properties (title, actions) surface on the Scaffold's panel.
function buildScaffold(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = SCAFFOLD.fields;
  const variants = Object.entries(SCAFFOLD.variants.defaultsByVariant);
  const mount = mountSet(
    page,
    'Scaffold',
    variants.map(([name]) => `Variant=${name}`),
  );
  const childNodes: InstanceNode[] = [];
  const sidebarSlots: SlotNodes[] = [];
  const fabSlots: SlotNodes[] = [];
  // The composed header/footer bars — exposed once the set exists, so a
  // designer edits the bar's title and actions from the Scaffold's panel.
  const composedBars: InstanceNode[] = [];
  for (const [name, v] of variants) {
    const c = mount.getOrCreate(`Variant=${name}`);
    c.layoutMode = 'VERTICAL';
    c.primaryAxisSizingMode = 'FIXED';
    c.counterAxisSizingMode = 'FIXED';
    c.clipsContent = true;
    fillData(c, lk, colorData(v.backgroundColor));
    c.resize(kScaffoldWidth, kScaffoldHeight);

    // headers — the section the widget draws (`_ScaffoldSection`): a column
    // painted `headerBackgroundColor`, holding the caller's `headers`. The
    // caller's widget is an `AppBar` in every example this library ships
    // (`scaffold_chain_example`, the docs page), so the preview composes the
    // real ❖ AppBar instead of redrawing one: the bar's inset, gaps, title
    // role and action items are AppBar's own, and a change to AppBar reaches
    // this shell without a second copy here to forget.
    //
    // At rest on every pose axis — `Leading=none` (the widget's `leading` is
    // empty unless a caller passes one), `Align=start` (`centerTitle` false),
    // the contract's default `Variant`. The section itself has no inset or
    // gap: `_ScaffoldSection` is a plain column.
    //
    // The bar's `trailing` is NOT at rest: every shipped example gives the
    // header one action (`trailing: const [Icon(LucideIcons.settings)]`), so
    // the instance turns `action 1` on. AppBar's own default is off (a bare
    // bar has no actions), so this is a real override on the instance.
    const header = panel('headers[]', 'VERTICAL', lk, {});
    // The app bar is the scaffold's floating surface on both platforms
    // (`scaffold_style.dart` folds `theme.surfaceFor(.functional)` into the
    // header fill; the Web twin marks the header `webSurfaceMarkerFor(
    // .functional)`). The page and the footer are not surfaces.
    applySurfaceMaterial(header, lk, colorData(v.headerBackgroundColor), 'functional', { radius: null });
    c.appendChild(header);
    header.layoutSizingHorizontal = 'FILL';
    const headerBar = instanceOf(page, 'AppBar', bestVariantName(page, 'AppBar', kScaffoldAppBarPose));
    headerBar.name = 'header';
    header.appendChild(headerBar);
    headerBar.layoutSizingHorizontal = 'FILL';
    setInstanceBoolNamed(headerBar, 'action 1', true);
    composedBars.push(headerBar);

    const hairline = figma.createRectangle();
    hairline.name = 'header border';
    hairline.resize(kScaffoldWidth, dimVal(f.headerBorderWidth));
    fillData(hairline, lk, colorData(f.headerBorderColor));
    c.appendChild(hairline);
    hairline.layoutSizingHorizontal = 'FILL';

    // body — sidebar beside child, both filling the remaining height.
    const body = autoFrame('body', 'HORIZONTAL');
    c.appendChild(body);
    body.layoutSizingHorizontal = 'FILL';
    body.layoutSizingVertical = 'FILL';
    // `sidebar` is `W?` — a shell with no rail is the common case — so the
    // region and its content are two nodes: the hug frame takes the BOOLEAN,
    // the instance inside takes the swap.
    const sidebar = optionalSlot(page, 'sidebar', kSlotRect);
    body.appendChild(sidebar.holder);
    sidebar.holder.layoutSizingVertical = 'FILL';
    sidebar.content.layoutSizingVertical = 'FILL';
    sidebarSlots.push(sidebar);
    const child = slotStandIn(page, 'child', kSlotRect);
    body.appendChild(child);
    child.layoutSizingHorizontal = 'FILL';
    child.layoutSizingVertical = 'FILL';
    childNodes.push(child);

    // footers — the same section shape without the hairline, and the same
    // composed bar: the shipped example's footer is `AppBar(title: …)` with
    // no actions. AppBar's own `action 1` default is off too; the write below
    // still states it, so the example's intent is written here and not left to
    // whatever default the AppBar set in the file happens to carry.
    const footer = panel('footers[]', 'VERTICAL', lk, {});
    fillData(footer, lk, colorData(v.footerBackgroundColor));
    c.appendChild(footer);
    footer.layoutSizingHorizontal = 'FILL';
    const footerBar = instanceOf(page, 'AppBar', bestVariantName(page, 'AppBar', kScaffoldAppBarPose));
    footerBar.name = 'footer';
    footer.appendChild(footerBar);
    footerBar.layoutSizingHorizontal = 'FILL';
    setInstanceBoolNamed(footerBar, 'action 1', false);
    composedBars.push(footerBar);

    // loadingProgress — the composed `Progress`, pinned across the very top.
    //
    // The widget stacks `Position(top: 0, left: 0, right: 0, child: Progress())`
    // over everything else, so the instance spans the shell's full width; that
    // width is the parent's constraint, exactly as it is in the widget, which is
    // why it overrides the child's own preview width rather than being drawn
    // beside it.
    //
    // Hidden, because the widget mounts it only when `loadingProgress` /
    // `loadingProgressIndeterminate` is set and both default to off — the node
    // is in the tree (a designer sees the slot, a reader finds it) showing the
    // default state. A BOOLEAN property would say this better, but the property
    // owner of a variant-set member differs between the first run (the member,
    // still detached) and later runs (the set), so declaring one from inside
    // this loop would put it in two different places on two different runs.
    const progress = instanceOf(
      page,
      'Progress',
      bestVariantName(page, 'Progress', kScaffoldProgressPose),
    );
    progress.name = 'loadingProgress';
    // Resize first, pin second: `pinAbsolute` sizes the holder to the instance.
    progress.resize(c.width, progress.height);
    // STRETCH across: the bar spans the scaffold's top edge, whatever width a
    // designer gives the scaffold (#4701).
    pinAbsolute(c, progress, 0, 0, { horizontal: 'STRETCH', vertical: 'MIN' }).visible = false;

    // floatingActionButton — inset from the bottom-right by fabPadding. `W?`,
    // so the same two-node shape as the sidebar. The inset is measured off the
    // instance rather than off its hug frame: the frame's width is whatever
    // Figma last computed for it, and the instance's is known now.
    const fab = optionalSlot(page, 'floatingActionButton', kSlotCircle);
    c.appendChild(fab.holder);
    pinInFlow(c, fab.holder);
    fab.holder.x = c.width - fab.content.width - dimVal(f.fabPadding.r);
    fab.holder.y = c.height - fab.content.height - dimVal(f.fabPadding.b);
    // Measured from the bottom-right, so the inset is what a resize keeps — a
    // MIN-pinned button stays put while the corner moves away from it (#4701).
    fab.holder.constraints = { horizontal: 'MAX', vertical: 'MAX' };
    fabSlots.push(fab);
  }
  const set = mount.finish();
  // Defaults ON for both optional slots: that is what the preview draws, and
  // the property exists so the `null` state is *reachable*, not so it is the
  // one a designer starts from.
  const childProp = defineProp(set, 'child', 'INSTANCE_SWAP', slotStandInDefault(page, kSlotRect));
  for (const n of childNodes) bindSwapProp(n, childProp);
  const sidebarProp = defineProp(set, 'sidebar', 'INSTANCE_SWAP', slotStandInDefault(page, kSlotRect));
  const showSidebar = defineProp(set, 'Show sidebar', 'BOOLEAN', true);
  for (const s of sidebarSlots) {
    bindSwapProp(s.content, sidebarProp);
    bindVisibleProp(s.holder, showSidebar);
  }
  const fabProp = defineProp(
    set,
    'floatingActionButton',
    'INSTANCE_SWAP',
    slotStandInDefault(page, kSlotCircle),
  );
  const showFab = defineProp(set, 'Show floatingActionButton', 'BOOLEAN', true);
  for (const s of fabSlots) {
    bindSwapProp(s.content, fabProp);
    bindVisibleProp(s.holder, showFab);
  }
  // The bar's own properties (title, action 1/2, divider, elevated) are the
  // handles — the Scaffold declares none of its own for them. Exposing is
  // legal only now that the instances sit inside a component (see
  // `exposeAll`).
  exposeAll(composedBars);
  return set;
}

// ─── Frame ───────────────────────────────────────────────────────────────────

// The low-level layout primitive — the cross-platform analogue of a Figma
// Frame, and of Flutter's Container/Row/Column/Padding/… collapsed into one
// component. Its contract is deliberately flat and enormous (direction, gap,
// padding, fill, stroke, radius, effects, opacity, transform), and nearly all
// of it is per-instance. What `fields` carries is six values, and every one is
// conditional on a caller opting into something that has no default:
//
//   · `shadowBaseColor` is the colour shadows are *derived* from, and only
//     becomes a shadow once a caller sets `elevation`. `elevation` is `none`,
//     so a drop shadow would need a blur and an offset this file would have to
//     invent — and a `Frame` that arrived pre-shadowed would be the wrong
//     default in every composition a designer built from it.
//   · `clipBehavior` is `hardEdge` and still reaches nothing at rest.
//     `frame.dart` only builds the `AnimatedContainer` that carries it when
//     `hasChrome` holds, and every input to that flag (border colour,
//     background, gradient, shadow, image) is null by default. So this node
//     does not clip either — `clipsContent` stays off, which is what the
//     widget does, not an omission.
//   · `duration` is `Duration.zero`: nothing to animate even where a canvas
//     could carry animation, which it cannot.
//   · `dashLength` / `dashSpacing` are written to the node — see below.
//
// So the node is an empty auto-layout box holding its child slot, painting no
// chrome, which is the honest reading of "every gate is off".
//
// The dash pattern is written even though nothing strokes it, because
// `dashPattern` is an independent property of Figma's stroke mixin: with
// `strokes` empty it paints nothing, and that makes it exactly as conditional
// as the widget's own pair. Both sides of the widget's gate refuse to open by
// default — `borderColor` is the border's opt-in and deliberately carries no
// default ("A default would stroke every frame, the plain layout ones
// included", `frame_style.dart`), and `borderStyle` is `solid`, so
// `_DashedRectPainter` never runs at rest. Painting a dashed border here would
// mean inventing the one colour Core explicitly refuses to choose. Stating the
// geometry without the stroke says what the data says: the dashes are 3 on /
// 2 off whenever something asks, and nothing is asking yet — and a designer who
// does add a stroke gets the design system's dash rhythm, traceable to
// `CoreDashedBorder`, instead of Figma's own default pattern.
//
// `child` is `W?` and `children` is `List<W>?` — a `Frame` with neither is a
// legal, if empty, box. So the single slot gets the two-node shape (hug frame
// for the BOOLEAN, instance for the swap) and the repeated one gets nothing:
// Figma has no repeated-slot property, and a designer adds children directly.
function buildFrame(page: PageNode, lk: VarLookup): ComponentNode {
  const f = FRAME.fields;
  const c = mint(page, 'Frame');
  // `borderStyle` decides whether that pattern applies at all. It used to be
  // written unconditionally while the recipe says `solid`, so the canvas carried
  // a dash pattern for a border the widget draws unbroken — inert only because
  // this builder sets no stroke, and wrong the moment one arrives.
  //
  // The field reached the JSON only after the reader learned that a `Core*Style`
  // name the class registry does not know is an ENUM, not a nested style slot.
  applyBorderStyle(
    c,
    f.borderStyle.choice,
    dimVal(f.dashLength),
    dimVal(f.dashSpacing),
  );
  c.layoutMode = 'HORIZONTAL';
  c.primaryAxisSizingMode = 'AUTO';
  c.counterAxisSizingMode = 'AUTO';
  c.fills = [];
  // The two chrome values this frame states and did not draw.
  //
  // `clipBehavior` → the clip flag (`hardEdge` today, so no pixel moves; `.none`
  // is the member that would). `elevation` → the shadow stack, through the same
  // resolver precedence `Card` and `OutlinedContainer` use — an explicit
  // `boxShadow` wins, else the elevation's own layers. It is `none` today and
  // `elevationLayers` throws on an unexported step rather than painting flat, so a
  // `Frame` that starts lifting itself shows up here instead of staying flat.
  c.clipsContent = clipsFor(f.clipBehavior, 'frame.clipBehavior');
  setShadow(
    c,
    elevationLayers(f.elevation, { layers: [] }, 'frame.elevation'),
    lk,
    colorData(f.shadowBaseColor),
  );
  const child = optionalSlot(page, 'child', kSlotRect);
  c.appendChild(child.holder);
  const owner = propertyOwner(c);
  bindVisibleProp(child.holder, defineProp(owner, 'Show child', 'BOOLEAN', true));
  bindSwapProp(
    child.content,
    defineProp(owner, 'child', 'INSTANCE_SWAP', slotStandInDefault(page, kSlotRect)),
  );
  return c;
}

// ─── Mask ────────────────────────────────────────────────────────────────────

// Crops its child to a shape. What the node can honestly say is that it clips:
// an auto-layout box that hugs its child with `clipsContent` on, so anything
// the child paints outside the box is gone.
//
// It does not say *which* silhouette, and that is a Figma limit rather than a
// missing export.
//
// The note here used to say the two enum defaults "do not reach
// components.json" because "the exporter carries dimensional and colour leaves
// only". That stopped being true when the reader learned to route enums: both
// arrive today, as `{choice: 'squircle'}` and `{choice: 'none'}`.
//
// What has not changed is that neither is drawable. `mask.dart` renders a
// `ClipPath` over a hand-built `Path`, and the shape enum has twelve members —
// heart, hexagon, decagon, star, triangle among them. A builder cannot put an
// arbitrary clip path on an auto-layout frame, and approximating the default with
// a corner radius would assert a radius the code never states while being flatly
// wrong for nine of the twelve. The half-crop is drawable in principle (resize
// plus clip) but its default is `none`, so the un-cropped box IS the default's
// picture; the two crop poses would need an axis.
//
// Both are recorded in the unread-fields allowlist with those reasons rather than
// guessed at here.
function buildMask(page: PageNode, lk: VarLookup): ComponentNode {
  const c = mint(page, 'Mask');
  c.layoutMode = 'HORIZONTAL';
  c.primaryAxisSizingMode = 'AUTO';
  c.counterAxisSizingMode = 'AUTO';
  c.fills = [];
  c.clipsContent = true;
  const child = slotStandIn(page, 'child', kSlotRect);
  c.appendChild(child);
  // `child` is `W` — required, so swap only. A mask with nothing under it
  // crops nothing, and the property should not describe that.
  bindSwapProp(
    child,
    defineProp(propertyOwner(c), 'child', 'INSTANCE_SWAP', slotStandInDefault(page, kSlotRect)),
  );
  return c;
}

// ─── Hidden ──────────────────────────────────────────────────────────────────

// Fades and collapses its child when `hidden` is true. The Figma affordance
// for exactly that is a BOOLEAN component property on the child's visibility:
// switching it off removes the child from the auto-layout, so the wrapper
// collapses the way the widget collapses (`keepSpace` false, its default). The
// property is the inverse of the widget's field — Figma toggles "shown", the
// widget names "hidden" — so it is named `Show child`.
//
// It sits alongside an INSTANCE_SWAP named for the slot, and they are on two
// nodes rather than one: `child` is `W`, meaning any widget at all, and a node
// holds a single `componentPropertyReferences` map, so the region's visibility
// and its content's identity cannot share one. The flag is what this component
// is *for*; the swap is what its slot accepts. Neither says the other.
//
// `transitionDuration` and `transitionCurve` are the fade/collapse timing and
// its easing, and neither is written. No plain node field takes either one, and
// the single Figma surface that carries them is the prototyping transition on
// `reactions` — `Reaction.action.transition`, whose `easing: Easing` does admit
// a cubic bezier, which is exactly the type `CoreCubicBezier` is. It is out of
// reach twice over:
//
//   · `manifest.json` sets `documentAccess: "dynamic-page"`, under which the
//     typings declare `reactions` read-only in favour of the async
//     `setReactionsAsync` — the same wall `slotStandInDefault` (slot-stand-in.ts)
//     documents for `getMainComponentAsync`, and unreachable from a
//     synchronous builder for the same reason.
//   · A transition interpolates between two states. This component states its
//     collapse as a BOOLEAN property on one node, and a property has no
//     transition to hang an easing off; expressing one would mean rebuilding
//     `Hidden` as a two-variant set whose variants exist only to be animated
//     between, which is a different component than the widget.
//
// So this is a genuine gap rather than an omission, and it is the one shape of
// gap a static canvas should be expected to have: a curve and a duration are
// both statements about a time axis the canvas does not have.
function buildHidden(page: PageNode, lk: VarLookup): ComponentNode {
  const c = mint(page, 'Hidden');
  c.layoutMode = 'VERTICAL';
  c.primaryAxisSizingMode = 'AUTO';
  c.counterAxisSizingMode = 'AUTO';
  c.fills = [];
  const child = optionalSlot(page, 'child', kSlotRect, 'VERTICAL');
  c.appendChild(child.holder);
  const owner = propertyOwner(c);
  bindVisibleProp(child.holder, defineProp(owner, 'Show child', 'BOOLEAN', true));
  bindSwapProp(
    child.content,
    defineProp(owner, 'child', 'INSTANCE_SWAP', slotStandInDefault(page, kSlotRect)),
  );
  return c;
}

// ─── MediaQueryVisibility ────────────────────────────────────────────────────

// Shows `child` while the viewport is inside a width range and
// `alternateChild` when it isn't. Which one renders is the whole component, so
// it is the Figma axis: `Matches=True` / `Matches=False`. Both slot nodes
// exist in both variants — the widget tree has both children too, and the
// range only decides which is mounted — with visibility flipped between them,
// so exactly one ever draws.
//
// The two are drawn as different placeholder shapes on purpose: identical
// boxes would make the variant switch look like nothing happened.
//
// The gating widths themselves cannot be shown. `minWidth`/`maxWidth`/
// `minBreakpoint`/`maxBreakpoint` are per-instance behaviour values with no
// Style default — `CoreMediaQueryVisibilityStyle` carries no fields at all —
// so there is no dimension in the data to draw the range at.
//
// Both slots get an INSTANCE_SWAP and neither gets a BOOLEAN, including the
// optional `alternateChild`. A component property's value is one value for the
// whole set, so a BOOLEAN bound to either node's `visible` would override the
// per-variant visibility below and collapse the `Matches` axis into showing
// the same thing twice. The axis IS the visibility control here, and it is the
// truer one: the viewport decides which child mounts, not the designer.
function buildMediaQueryVisibility(page: PageNode, lk: VarLookup): ComponentSetNode {
  const states = [true, false];
  const nameOf = (matches: boolean): string => `Matches=${matches ? 'True' : 'False'}`;
  const mount = mountSet(page, 'MediaQueryVisibility', states.map(nameOf));
  const childNodes: InstanceNode[] = [];
  const alternateNodes: InstanceNode[] = [];
  for (const matches of states) {
    const c = mount.getOrCreate(nameOf(matches));
    applyPanelCompChrome(c, 'VERTICAL', lk, {});
    const child = slotStandIn(page, 'child', kSlotRect);
    c.appendChild(child);
    child.visible = matches;
    childNodes.push(child);
    const alternate = slotStandIn(page, 'alternateChild', kSlotText);
    c.appendChild(alternate);
    alternate.visible = !matches;
    alternateNodes.push(alternate);
  }
  const set = mount.finish();
  rowSet(set);
  // On the set, not on the variants — see the header. Each property binds both
  // variants' node, so swapping once changes what the component shows on
  // either side of the breakpoint, which is what one slot means.
  const childProp = defineProp(set, 'child', 'INSTANCE_SWAP', slotStandInDefault(page, kSlotRect));
  for (const n of childNodes) bindSwapProp(n, childProp);
  const alternateProp = defineProp(
    set,
    'alternateChild',
    'INSTANCE_SWAP',
    slotStandInDefault(page, kSlotText),
  );
  for (const n of alternateNodes) bindSwapProp(n, alternateProp);
  return set;
}

// ─── Breakpoint ──────────────────────────────────────────────────────────────

// The viewport-tier accessor. It renders nothing — `CoreBreakpointStyle` is an
// empty token holder by design, and the thing it answers with (mobile /
// tablet / desktop, and the widths that separate them) lives on the Contract
// as `defaultBoundaries`, a behaviour value the exporter does not carry into
// components.json.
//
// So the node is empty, and deliberately so. There is no chrome to draw, and
// the tier widths that would let a preview draw the three rungs are not in
// this builder's data — drawing them from the Dart source instead would put a
// second copy of those numbers in a file that cannot be kept in step with
// them. What the node is for is correspondence: the widget exists in the tree,
// so a node exists in the tree, named the same, ready to carry chrome if
// `CoreBreakpointStyle` ever gains a field.
function buildBreakpoint(page: PageNode, lk: VarLookup): ComponentNode {
  const c = mint(page, 'Breakpoint');
  c.fills = [];
  return c;
}

// ─── Registry ────────────────────────────────────────────────────────────────

export const PRIMITIVES_LAYOUT: RegistryEntry[] = [
  { section: 'Layout', name: 'Gap', sizing: { width: 'fixed', height: 'fixed', why: 'spacer 는 자기 extent 가 전부 — 양 축을 CoreGapStyle.size 에 바인딩(gap.dart SizedBox); 따라올 내용이 없다' }, build: buildGap },
  { section: 'Layout', name: 'Stacks', sizing: { width: 'fixed', height: 'fixed', why: 'StackFit.loose — 자식은 자기 크기를 지키고 박스만 자란다(stacks.dart); 따라올 자식이 없는 것이 정의' }, build: buildStacks, needs: [kSlotStandInComponent] },
  { section: 'Layout', name: 'AspectRatioBox', build: buildAspectRatioBox, needs: [kSlotStandInComponent] },
  {
    section: 'Layout',
    name: 'ResponsiveContainer',
    sizing: { width: 'fixed', why: 'maxWidth 컨테이너 — 안쪽 박스는 maxWidth 에서 멈추고 가운데 놓인다(responsive_container.dart ConstrainedBox); 바깥이 자라도 따라오지 않는 것이 정의' },
    build: buildResponsiveContainer,
    needs: [kSlotStandInComponent],
  },
  { section: 'Layout', name: 'ResponsiveGrid', build: buildResponsiveGrid, needs: [kSlotStandInComponent] },
  {
    section: 'Layout',
    name: 'ResponsiveRowColumn',
    build: buildResponsiveRowColumn,
    needs: [kSlotStandInComponent],
  },
  {
    section: 'Layout',
    name: 'ScrollArea',
    build: buildScrollArea,
    needs: [kSlotStandInComponent, 'Scrollbar'],
  },
  { section: 'Layout', name: 'Scrollbar', sizing: { width: 'fixed', why: '세로 스크롤바의 폭은 thickness(CoreScrollbarStyle.defaultThickness); 길이만 트랙을 따른다' }, build: buildScrollbar, needs: [kSlotStandInComponent] },
  {
    section: 'Layout',
    name: 'ScrollableClient',
    sizing: { height: 'fixed', why: 'viewport — 내용은 박스보다 커서 스크롤된다; 박스가 커지면 더 보일 뿐 세로로 따라올 자식이 없다' },
    build: buildScrollableClient,
    needs: [kSlotStandInComponent, 'Scrollbar'],
  },
  {
    // `Infra`, not `Layout` — its widget lives in `infra/scrollview/`, and the
    // docs catalog lists it under Infra. The data cannot say so here: the
    // directory slug is `scrollview` while this entry's name resolves to
    // `scroll_view_interceptor`, so the section falls back to this declaration.
    section: 'Infra',
    name: 'ScrollViewInterceptor',
    sizing: { height: 'fixed', why: 'viewport — 내용은 박스보다 커서 스크롤된다; 박스가 커지면 더 보일 뿐 세로로 따라올 자식이 없다' },
    build: buildScrollViewInterceptor,
    needs: [kSlotStandInComponent],
  },
  {
    section: 'Layout',
    name: 'FadeScroll',
    sizing: { height: 'fixed', why: 'viewport — 내용은 박스보다 커서 스크롤된다; 박스가 커지면 더 보일 뿐 세로로 따라올 자식이 없다(스크롤바는 기본 숨김)' },
    build: buildFadeScroll,
    needs: [kSlotStandInComponent, 'Scrollbar'],
  },
  { section: 'Layout', name: 'OverflowMarquee', sizing: { width: 'fixed', height: 'fixed', why: 'marquee viewport — 내용이 박스보다 넓어 스크롤되는 것이 존재 이유; 높이는 child 의 것(overflow_marquee.dart)' }, build: buildOverflowMarquee, needs: [kSlotStandInComponent] },
  { section: 'Layout', name: 'StageContainer', build: buildStageContainer, needs: [kSlotStandInComponent] },
  // `Button` for the words-only `Leading=text` item and `Show trailing text`.
  { section: 'Layout', name: 'AppBar', build: buildAppBar, needs: [kSlotStandInComponent, 'Icon', 'Button'] },
  {
    section: 'Layout',
    name: 'Scaffold',
    build: buildScaffold,
    needs: [kSlotStandInComponent, 'Progress', 'AppBar'],
  },
  { section: 'Layout', name: 'Frame', build: buildFrame, needs: [kSlotStandInComponent] },
  { section: 'Layout', name: 'Mask', build: buildMask, needs: [kSlotStandInComponent] },
  { section: 'Layout', name: 'Hidden', build: buildHidden, needs: [kSlotStandInComponent] },
  {
    section: 'Layout',
    name: 'MediaQueryVisibility',
    build: buildMediaQueryVisibility,
    needs: [kSlotStandInComponent],
  },
  { section: 'Layout', name: 'Breakpoint', sizing: { width: 'fixed', height: 'fixed', why: 'chrome 없는 대응 노드 — 위젯은 LayoutBuilder 로 자식을 고를 뿐 그릴 박스가 없다(breakpoint.dart)' }, build: buildBreakpoint },
];
