/// <reference types="@figma/plugin-typings" />

import {
  pinAbsolute,
  sizePin,
  RegistryEntry,
  VarLookup,
  applyPanelCompChrome,
  applySurfaceMaterial,
  autoFrame,
  bestVariantName,
  bindAxisSize,
  bindLayerOpacity,
  bindSpaceField,
  exposeAll,
  exposeSlot,
  bindPad,
  bindRadiusN,
  bindSize,
  bindSwapProp,
  bindTextProp,
  bindVisibleProp,
  borderData,
  corners,
  defineProp,
  fillData,
  glyphOpts,
  iconMainId,
  iconMainIdAt,
  iconSwapDefault,
  indicatorBox,
  instanceOf,
  glyphPaint,
  kPreserveGlyphPaint,
  labelColor,
  layoutSet,
  lockWidth,
  makeIcon,
  makeLabel,
  mint,
  mountSet,
  panel,
  pinInFlow,
  repaintGlyph,
  textLabelOpts,
  vStackSet,
  rowSet,
  setShadow,
  setSlotIcon,
  hostedDivider,
  applyForwardedButtonStyle,
  applyForwardedPanelStyle,
  applyInstanceTextStyle,
  bindInstanceOverlayRadius,
  forwardFocusBand,
  focusOutlineRing,
  focusOutlineRingColor,
  focusRing,
  namedDescendant,
  pinComposedCorner,
  suppressFieldChrome,
  applyForwardedFieldText,
  setFieldPlaceholder,
} from '../helpers';
import { bindShowFocusRing, defineShowFocusRing, stateAxis } from '../state-axis';
import type { ColorData, FocusRingNodes } from '../helpers';
import {
  Color,
  Dim,
  colorData,
  dimVal,
  mergeTextStyleData,
  optField,
  textStyleData,
} from '../compat/v1';
import { setIconGlyph } from '../icon-nodes';
import { kAmbientInkKey } from '../paint';
import { hidePopupContent, popupInstance } from '../popup-composition';
import { mainId } from '../overlay-composition';
import { elevationLayers } from '../container-chrome';
import { caretLineBox, kToggleTrackName, statedRadius } from '../form-drawing';
import { bindLayoutBound, boundOrNull } from '../layout-bound';
import { setInstanceLabel } from '../instance-label';
import { linkShadowStyle } from '../shadow-style';
import { COMPONENTS } from '../data';
import {
  AxisName,
  AxisSpec,
  axisSpecsOf,
  composeVariantName,
  enumerateAxisAssignments,
  enumerateAxisCombos,
  sizeRowFor,
} from '../axis-combos';
import { setInstanceBoolNamed, setInstanceTextNamed } from '../component-props';
import { setFieldValue } from '../field-value';
import { kFieldInputName, kFieldRowName, kFieldValueName, paintPlaceholder } from '../instance-reach';
import { parseVariantKey } from '../variant-safety';

const SELECT = COMPONENTS.select;
const TEXT_FIELD = COMPONENTS.text_field;
const MENU_ITEM = COMPONENTS.menu_item;
const AUTOCOMPLETE = COMPONENTS.autocomplete;
const SWITCH_FIELD = COMPONENTS.switch_field;
const TOGGLE_CTRL = COMPONENTS.toggle;
const RANGE = COMPONENTS.range;
const STAR_RATING = COMPONENTS.star_rating;
// g7-preview-only: the example the design copy draws — 3.5 of 5, and a count of 128.
const kStarRatingValue = '3.5';
const kStarRatingCount = '(128)';
const STEPPER = COMPONENTS.stepper;
const FAB = COMPONENTS.fab;
const MULTIPLE_CHOICE = COMPONENTS.multiple_choice;
const MULTI_ANSWER_CARD = COMPONENTS.multi_answer_card;
const FILTER = COMPONENTS.filter;
const TOGGLE_GROUP = COMPONENTS.toggle_group;
const ITEM_PICKER = COMPONENTS.item_picker;
const OBJECT_INPUT = COMPONENTS.object_input;
// `icon.constants.ambientSize` — the app root's ambient icon size, which an
// `Icon` handed to a caller slot draws at when the widget renders it as handed.
// ObjectInput's `leading` / `trailing` say why they qualify.
const ICON = COMPONENTS.icon;
const NUMBER_INPUT = COMPONENTS.number_input;
const BUTTON = COMPONENTS.button;
const RICH_EDITOR = COMPONENTS.rich_editor;
const TEXT_AREA = COMPONENTS.text_area;

// ─── State axes in this file ─────────────────────────────────────────────────
//
// A boolean axis per state, never one `State=` enum: the code's states
// combine (a card can be selected AND disabled), and one enum axis cannot
// express a combination. Each axis reads its value from that state's OWN
// Core field — `clickableStyle.disabledOpacity`, `disabledTextStyle`,
// `selectedBorderColor`, `focusBorderColor`, … — so an axis exists only
// where coui_core actually says the chrome changes.
//
// Where a state is deliberately NOT an axis, the reason is at that builder.
// Two recurring ones, recorded once here:
//
//   · `clickableStyle.focusOutlineStyle` carries a `borderColor` and a
//     `circleBorderRadius` but no *width* (`CoreFocusOutlineStyle`'s width
//     default isn't in the exported JSON). Drawing a ring needs a width, and
//     inventing one is exactly the hardcoded chrome this pipeline removes —
//     so components whose only focus data is that nested slot get no `Focus`
//     axis. The way OUT of that is composition, not invention: where the
//     widget wraps a child in `FocusOutline` (Range's thumbs), the ring is an
//     INSTANCE of that component, so the width is the child's own default and
//     nothing here has to guess it. `ObjectInput` gets a `Focus` axis for the
//     other reason: its `focusBorderColor` is a top-level field and the width
//     comes from its own `borderWidth`.
//   · `clickableStyle.pressedScale` is a transform, not chrome. A variant
//     baked at 0.97 scale would bake a *rounded* size for every child at a
//     scale Figma cannot express as a live effect, so `Pressed` is not an
//     axis anywhere in this file.
//
// A state that would need a NEW axis on a set that already has one (or a new
// axis on a single COMPONENT) is expressed as a BOOLEAN component property
// instead, because both of those are node-identity changes that need a
// `VARIANT_RENAMES` / `STRUCTURAL_MIGRATIONS` entry in `src/renames.ts` — a
// file outside this one's ownership.
const kStepperLayouts = ['horizontal', 'vertical'] as const;

// `Stepper`'s member name: the schema's `Enabled` axis (the contract states
// `bool? get enabled`, and G10 reads coverage through that spelling) and the
// builder's own `Layout`. `Enabled` sorts before `Layout` in `kAxisOrder`, so
// `composeVariantName` takes the pair in the order a member is named.
//
// The canvas used to spell the boolean the other way round (`Disabled=true`) and
// put it after `Layout`; `VARIANT_RENAMES` carries those four members onto the
// names below, so their keys — and every instance placed from them — survive.
function stepperVariantName(
  layout: (typeof kStepperLayouts)[number],
  enabled: boolean,
): string {
  return composeVariantName([
    ['Enabled', enabled ? 'true' : 'false'],
    ['Layout', layout],
  ]);
}

// Sub-pixel tolerance for "is this already the size the data asks for". Figma
// geometry is float, so an equality test on a rescaled node is a coin flip.
const kSizeEpsilon = 0.01;

// Centring divisor. Named the way `form.ts` names it, so the arithmetic reads
// as "half of" rather than as an unexplained 2.
const kHalf = 2;

// The two values a boolean axis carries, spelled the way a variant name spells
// them — so one reading serves the schema's own `Enabled` axis and every pose
// axis below it (`parseVariantKey(name)['Focus'] === 'true'`).
const kBoolAxisValues: readonly string[] = ['false', 'true'];

// The axes `axes` declares, plus the pose axes a builder adds.
//
// The append is not a formatting convenience: `composeVariantName` (inside
// `enumerateAxisCombos`) throws on an assignment out of `kAxisOrder`, and every
// pose axis sits AFTER the four schema axes there — so a spec list built this
// way either produces canonical names or fails loudly at build time.
// Enumerating by hand is what let a builder's member count and G10's
// measurement of it disagree. Named the way `form.ts` names it, for the same
// reason `kHalf` is.
function withPoses(declared: AxisSpec[], ...poses: AxisName[]): AxisSpec[] {
  return [
    ...declared,
    ...poses.map((axis) => ({ axis, values: kBoolAxisValues })),
  ];
}

// ─── Composition helpers ─────────────────────────────────────────────────────
//
// The rule these encode: when a widget composes another unified component, the
// Figma component contains an INSTANCE of it — never a frame drawn to look
// like one. An instance follows its main component when that component's own
// chrome changes; a redrawn copy keeps painting whatever the child looked like
// the day it was copied, and the content-hash skip means a run that only moved
// the child's data never re-enters this file to notice.

// The resting variant of a child set, named only by the axes this call site
// actually cares about.
//
// `bestVariantName` scores the axes it is given and ignores the ones the child
// does not have, so an axis added or renamed over in `form.ts` degrades to
// "ignored" rather than to a throw that would fail the parent's entry over a
// child's refactor and leave the parent half-drawn on the page.
// Every boolean state axis is named explicitly at `false`: a composed child is
// not pre-hovered, pre-selected or pre-disabled, and leaving those unnamed
// makes the answer depend on the child's own loop order.
//
// `state` is the ONE of those a caller may move off rest, and only where the
// widget itself hands the child that state: `disabled` where it forwards
// `enabled` (`Button(enabled: widget.enabled)` in `select.dart:339`,
// `TextField(enabled: widget.enabled)` in `autocomplete.dart:445`,
// `item_picker.dart:506`, `object_input.dart:204`), and the whole ladder where
// the child IS the widget's interactive surface (`Fab`'s main circle is the
// `Button` the pointer lands on, so its hover/focus/pressed are that Button's).
// Moving it hands the child's OWN chrome for that rung to the member instead
// of inventing a grey or a tint here, which is the same "composition, not
// invention" move the file header makes for Range's focus ring.
//
// Both spellings of that axis are named. `Enabled` is the schema's (v3
// `button.axes.enabled` / `text_field.axes.enabled`); `Disabled` is the pose
// spelling a builder may still be carrying. `bestVariantName` scores the axes
// it is given and ignores the ones the child does not have, so naming both is
// how this keeps matching while `form.ts` finishes moving between them —
// exactly the degradation that helper exists for.
//
// `shape` is `CoreButtonShape`'s member spelling (`rectangle` / `square` /
// `circle`), defaulted to the widget's own `this.shape = .rectangle` so the
// callers composing a labelled button keep saying nothing. A caller whose
// widget hands the child `shape: .square` — `Filter`'s reset — names it, and
// gets the member that draws a glyph in a box floored at its height instead of
// a rectangle it would then have to resize and overlay a glyph on.
function restingButton(
  page: PageNode,
  variant: string,
  size: string,
  name: string,
  state = 'enabled',
  shape = 'rectangle',
): InstanceNode {
  const instance = instanceOf(
    page,
    'Button',
    // `State`, not `Enabled` — and the difference is not cosmetic. This asked
    // through `Enabled` plus a `Disabled` key that was never a Button axis at
    // all, and `bestVariantName` scores rather than demands: a key naming no
    // axis contributes nothing and the call still returns SOMETHING. So a
    // disabled trigger quietly resolved to the enabled member and the caller
    // had no way to notice.
    bestVariantName(page, 'Button', {
      Variant: variant,
      Size: size,
      State: state,
      Shape: shape,
    }),
  );
  instance.name = name;
  return instance;
}

function restingTextField(
  page: PageNode,
  size: string,
  name: string,
  enabled = true,
  variant = 'defaultVariant',
  state?: string,
): InstanceNode {
  const instance = instanceOf(
    page,
    'TextField',
    // `defaultVariant`, not `Default`: that is the member spelling v3
    // `text_field.axes.variant` carries (the Dart reserved word avoided).
    // `State`, not `Enabled` / `Focus` — the same trap `restingButton` records
    // above: the child's poses live on one enum, `bestVariantName` scores
    // rather than demands, and a key naming no axis contributes nothing, so a
    // disabled request would quietly land on the first rung (`enabled`).
    bestVariantName(page, 'TextField', {
      Variant: variant,
      Size: size,
      // An explicit pose wins; otherwise `enabled` picks the two rungs a
      // caller with no state in mind means. A key naming no axis scores
      // nothing and `bestVariantName` still returns SOMETHING, so a pose
      // the field does not have (`pressed`) lands on the field's own
      // nearest rung rather than throwing — which is the honest answer:
      // the field has no pressed member, and the select's pressed pose
      // differs from its hover only in the wash this frame does not draw.
      State: state ?? (enabled ? 'enabled' : 'disabled'),
    }),
  );
  instance.name = name;
  return instance;
}

// The `Popover` wrapper three widgets in this file build around everything
// else they draw. `Select`, `Autocomplete` and `Fab` all end in
// `Popover(trigger: …, content: …, popoverStyle: resolved.popoverStyle)`, so
// the wrapper is a real composition edge and gets a real INSTANCE — the same
// resolution `PhoneInput` (form-fields.ts) already ships for the same wrapper.
//
// It lands as a SIBLING rather than as the parent it is in Dart because Figma
// reparents nothing into an instance: `Popover`'s component holds its own
// `trigger` holder and its own `Popup`, and neither this widget's trigger nor
// its panel content can be moved inside them.
//
// ABSOLUTE, so the column it cannot be the parent of is not reflowed by it.
//
// Hidden, for the reason that decides this whole shape: `Popover`'s component
// renders a trigger AND a panel, and every caller here already draws both —
// the trigger as its own composed `Button`/`TextField` instance (that node IS
// the widget's `trigger:` argument), and the panel as the box this builder
// fills with the widget's real content. A visible instance would put a second
// trigger beside the first and a second, empty `Popup` behind the populated
// panel, which is the double draw that is worse than not composing. Hidden it
// costs the canvas nothing — auto-layout skips invisible children — and a
// designer who toggles the layer on reaches the actual `Popover` component,
// which is the whole reason to compose it instead of describing it in a
// comment.
//
// What this deliberately does NOT do is reach into the instance to repaint its
// nested `Popup`. `popoverStyle.panelStyle` is a forward into that panel, and
// each caller consumes it on the panel it actually draws — the node that holds
// the content — so asserting it a second time on a nested node would be the
// same value claimed from two places (`PhoneInput` leaves its three `popup*`
// fields unconsumed for the same reason).
// Returns the instance so a caller whose `popoverStyle.panelStyle` states a
// chromeless host can apply that statement to it. That is not the repaint the
// header above rules out: this suppresses, and it suppresses on a node no
// caller draws twice. A designer who toggles this layer on should meet what
// the widget renders, and for a host declared transparent / zero-width that
// is nothing.
function popoverWrapper(page: PageNode, c: ComponentNode): InstanceNode {
  const popover = instanceOf(page, 'Popover');
  popover.name = 'Popover';
  // See `pinAbsolute`: the pin goes on a holder frame, because Figma refuses
  // `layoutPositioning` on an instance — inconsistently, which is why this is
  // routed rather than guarded.
  pinAbsolute(c, popover, 0, 0, { horizontal: 'MIN', vertical: 'MIN' }).visible = false;
  return popover;
}

// `bindRadiusN` for an instance.
//
// Corner radius is one of the few chrome values a Figma instance DOES let a
// parent override, and three widgets here override exactly it —
// `Fab`'s `buttonStyle.borderRadius` (9999, the circle), `Filter`'s
// `resetButtonStyle.borderRadius`, `Range`'s `focusOutlineStyle
// .circleBorderRadius`. Same four bindings `bindRadiusN` makes; separate only
// because that helper's parameter type predates any instance call site, and
// widening it is `helpers.ts`'s change to make, not this file's.
function bindInstanceRadius(
  instance: InstanceNode,
  lk: VarLookup,
  n: number | Dim,
): void {
  const radius = dimVal(n);
  for (const corner of corners) instance.setBoundVariable(corner, lk.radius(radius));
}

// Switches a composed child's text slot off.
//
// `Button` models its content slot as the `Label` TEXT property, and a Figma
// instance takes no appended children — so when the widget passes an `Icon`
// rather than a `Text` into that slot (`Fab`'s trigger, `Filter`'s reset), the
// honest override is to turn the label off and let the real glyph ride on top
// (see `glyphOverButton`). Leaving it on would put the word "Button" inside a
// FAB circle. The designer still has the child's own `Leading` / `Leading icon`
// properties in the instance panel — the composed Button is a Button, with all
// of Button's slots, which is the whole point of composing it.
function hideInstanceText(instance: InstanceNode): void {
  for (const node of instance.findAll((n) => n.type === 'TEXT')) {
    node.visible = false;
  }
}

// A BOOLEAN property on a composed instance, set by its display name. The
// key Figma stores is `name#id`, so the lookup is by prefix; a child that
// does not expose the property is left alone rather than thrown on — the
// instance keeps its main's pose, which is what a missing property means.
function setInstanceBool(instance: InstanceNode, name: string, value: boolean): void {
  const key = Object.keys(instance.componentProperties).find(
    (k) => k === name || k.startsWith(`${name}#`),
  );
  if (key) instance.setProperties({ [key]: value });
}

// A named FRAME inside a composed instance — that child's own caller slot.
//
// `FocusOutline` draws its `child` slot at preview size, so resizing that frame
// is what makes the ring hug what THIS use site wraps instead of a placeholder.
// Found by name rather than by index so a sibling added to the child does not
// move it, and null when the child renames it — a ring at preview size, not a
// builder that throws.
function instanceFrameSlot(instance: InstanceNode, name: string): FrameNode | null {
  for (const node of instance.findAll((n) => n.name === name)) {
    if (node.type === 'FRAME') return node;
  }
  return null;
}

// One `W?` affix slot: an unpainted holder frame plus the glyph inside it.
//
// TWO nodes, because a node carries exactly ONE `componentPropertyReferences`
// map and `bindVisibleProp` / `bindSwapProp` each assign that map wholesale — a
// second call drops the first key. The holder takes the BOOLEAN ("did a caller
// pass this slot"), the icon takes the INSTANCE_SWAP ("with which component").
// The holder hugs with no padding, fill or gap, so it costs nothing on canvas.
//
// Hidden, because the widget renders nothing where the slot is null and every
// slot wired this way is `W?`. Hidden + a BOOLEAN is the only arrangement that
// is both faithful to the default rendering and reachable from an instance: a
// layer hidden inside a main component cannot be revealed unless a property
// governs it.
interface AffixSlot {
  /** The slot region — what the BOOLEAN hides. */
  holder: FrameNode;
  /** The glyph filling it — what the INSTANCE_SWAP re-points. */
  icon: InstanceNode;
}

function hiddenAffixSlot(
  name: string,
  glyph: string,
  lk: VarLookup,
  size: number | Dim,
  color: ReturnType<typeof colorData>,
  // The slot's swap default (`iconSwapDefault`), so the property's first bind
  // leaves the glyph at `size` (see `IconOpts.fromVariant`).
  fromVariant: ComponentNode | null,
): AffixSlot {
  const holder = autoFrame(name, 'HORIZONTAL');
  holder.counterAxisAlignItems = 'CENTER';
  const icon = makeIcon(glyph, lk, { ...glyphOpts(lk, color, size, 'size'), fromVariant });
  holder.appendChild(icon);
  holder.visible = false;
  return { holder, icon };
}

// Repaints a composed child's text slot in the colour the PARENT forwards.
//
// `Select` builds its trigger as `Button(child: Text(style: TextStyle(color:
// resolved.contentColor)))` — the typography is Button's, the colour is
// Select's. Painting the instance's text node is exactly that override, and it
// is the one part of "the parent supplies the child's content" that a Figma
// instance CAN express (fills are overridable; children are not).
function paintInstanceText(
  instance: InstanceNode,
  lk: VarLookup,
  color: ReturnType<typeof colorData>,
): void {
  for (const node of instance.findAll((n) => n.type === 'TEXT')) {
    if (node.type === 'TEXT') fillData(node, lk, color);
  }
}

// Repaints the glyph a composed child draws in one of ITS OWN slots.
//
// The counterpart to `paintInstanceText` for an icon slot. `select.dart` hands
// both of its `Icon`s an `iconStyle` it derived itself — the trigger chevron
// gets `chevronIconStyle`, the selected row's check gets `selectedIconStyle`,
// each `trailingIconStyle` with a different colour laid over it — and both of
// those `Icon`s live inside the composed `Button`. So the node that draws them
// is a nested instance, and paint on a nested instance's children is precisely
// what a Figma override is for.
//
// This is for a glyph the child already holds — the row's check mark is
// `MenuItem`'s own. A glyph this builder SWAPS in is painted by the swap itself
// (`setSlotIcon(…, paint)`), so it never needs a second pass here.
//
// The walk is `repaintGlyph`'s, the same one every swap and every `makeIcon`
// ends in: this file used to carry its own copy of it, and that copy shipped
// the solid-square defect a second time after the first was fixed.
//
// Silent when the child renames the holder — the glyph then keeps the child's
// own foreground, which is a slightly wrong colour rather than a throw that
// fails the whole entry and leaves the component half-drawn on the page.
function paintSlotGlyph(
  instance: InstanceNode,
  slot: string,
  lk: VarLookup,
  color: ReturnType<typeof colorData>,
  size: number | Dim,
): void {
  const holder = stateSlotGlyphSize(instance, slot, size);
  if (holder == null) return;
  // `labelColor` owns the Color-leaf → paint formula (semantic variable vs raw
  // literal vs the on-surface fallback); reproducing it here would be a second
  // copy of it, which is the divergence this pipeline keeps finding.
  repaintGlyph(holder, glyphPaint(lk, labelColor(lk, color)));
}

// The PARENT's size for the glyph in a composed child's slot, stated on the
// glyph instance inside that slot. Returns the slot holder, or null when the
// child renamed it (see `paintSlotGlyph`).
function stateSlotGlyphSize(
  instance: InstanceNode,
  slot: string,
  size: number | Dim,
): FrameNode | null {
  const holder = instanceFrameSlot(instance, slot);
  if (holder == null) return null;
  const side = dimVal(size);
  for (const node of holder.findAll(() => true)) {
    // The forwarded size and the child's own step are the same token today, so
    // this rescales nothing. It is here because the size is the PARENT's
    // statement: without it a divergence would render at the child's step and
    // look deliberate.
    if (
      node.type === 'INSTANCE' &&
      node.width > 0 &&
      Math.abs(node.width - side) > kSizeEpsilon
    ) {
      // Attempted, and a refusal is survived. These nodes are DESCENDANTS of an
      // instance, and Figma refuses `size` overrides there — "This property cannot
      // be overridden in an instance: size". The line above says this rescales
      // nothing because the two tokens agree today; when they stopped agreeing
      // (`Select`, once `Button` was actually reaching the canvas), the throw
      // failed the entry and left the component half-drawn on the page.
      //
      // A half-drawn component is worse than rendering the icon at the child's
      // step, which is the outcome this line exists to avoid — so the divergence
      // is accepted rather than paid for with the whole component.
      try {
        node.rescale(side / node.width);
      } catch {
        // Descendant of an instance — the parent's stated size cannot reach it.
      }
    }
  }
  return holder;
}

// Reveals a composed child's named affix slot (`leading` / `trailing` /
// `prefix` / `suffix`), which the child builds hidden behind a BOOLEAN
// property. Used where the widget passes that slot a glyph the child's own
// default already is — `Select`'s trigger chevron IS `Button`'s trailing
// `chevron-down`. No-op when the child renames the holder, which is the right
// failure: a missing chevron, not a failed entry and a half-drawn component.
// Shows an optional slot inside a composed instance.
//
// `setProperties` first, because that is what the child actually exposes: the
// slot's node is bound to a BOOLEAN component property, and a direct
// `node.visible = true` on a property-bound layer is not the designer's path —
// Figma either ignores it or rejects it, and a rejection fails the whole entry,
// leaving what it had already drawn half-built on the page until the next run
// mints that name and blanks it. Writing `visible` directly was how the
// Select trigger lost its chevron: the hand-drawn one was deleted on the
// strength of "Button's trailing slot revealed", and the reveal never landed.
//
// The direct write survives as the fallback for a child with no such property,
// and it is also the only path the runtime harness can take — it models
// properties on a main component, not on an instance.

// A composed `Button` with the widget's own glyph centred over it.
//
// Figma instances take no children, so a `Button(child: Icon(...))` cannot be
// drawn as one node. Drawing the circle by hand instead would be a second copy
// of Button's chrome; drawing only the instance would drop the glyph and make
// two variants that differ *by* their glyph identical. So the box is the
// instance (one copy of the chrome, following the Button set) and the glyph is
// stacked on top of it, which is the same shape Figma's own "instance +
// overlay" workaround has.
function glyphOverButton(
  button: InstanceNode,
  glyph: SceneNode,
  side: number,
  glyphSide: number,
): FrameNode {
  const box = figma.createFrame();
  box.name = 'button';
  box.layoutMode = 'NONE';
  box.clipsContent = false;
  box.fills = [];
  box.resize(side, side);
  hideInstanceText(button);
  box.appendChild(button);
  button.x = 0;
  button.y = 0;
  button.resize(side, side);
  box.appendChild(glyph);
  glyph.x = (side - glyphSide) / 2;
  glyph.y = (side - glyphSide) / 2;
  return box;
}

// The widget's width-reservation `Stacks`.
//
// `Filter`'s item and `Stepper`'s horizontal label both wrap their text in a
// `Stacks` holding invisible copies of the label in every typography state it
// can switch to, so the row keeps a constant width when selection moves. That
// stack IS the structure — a single text node here would be a narrower claim
// than the widget makes, and the reflow it prevents is the reason both widgets
// grew one. Figma's stack is a `layoutMode: 'NONE'` frame.
function labelStack(
  lk: VarLookup,
  text: string,
  ghosts: ReturnType<typeof textStyleData>[],
  live: ReturnType<typeof textStyleData>,
): FrameNode {
  const stack = figma.createFrame();
  stack.name = 'label';
  stack.layoutMode = 'NONE';
  stack.clipsContent = false;
  stack.fills = [];
  let width = 1;
  let height = 1;
  for (const ghost of ghosts) {
    const node = makeLabel(text, lk, textLabelOpts(lk, ghost));
    node.visible = false;
    stack.appendChild(node);
    node.x = 0;
    node.y = 0;
    if (node.width > width) width = node.width;
    if (node.height > height) height = node.height;
  }
  const front = makeLabel(text, lk, textLabelOpts(lk, live));
  stack.appendChild(front);
  if (front.width > width) width = front.width;
  if (front.height > height) height = front.height;
  stack.resize(width, height);
  front.x = (width - front.width) / 2;
  front.y = (height - front.height) / 2;
  return stack;
}
// ─── Select ──────────────────────────────────────────────────────────────────
//
// `Variant(2) × Size(3) × State(5)` − `error × disabled`(3) = 27 — the
// field's axis model, inherited (Select 코드 인계 통합본 2026-09-09 §2). Not
// `plain`: a borderless select exists in none of the seven systems surveyed.
// Not `xs` / `xl` / `xl2`: only one system draws a 24 select and its type
// falls to 12px there. Not `error × disabled`: disabled outranks error
// (Carbon's `disabled > error > hover`), so a disabled select paints the
// disabled trio whatever its validation says, and a member for the pair
// would draw the same picture as `defaultVariant × disabled` under a name
// claiming a difference. The canvas carries exactly these 27.
//
// `select.dart` composes three unified components, and this builder composes
// the same three:
//
// ```text
// column (gap = popoverStyle.placementOffset — the trigger↔panel distance)
//   ├─ trigger  — TextField INSTANCE (readOnly; the chevron in its suffix seat)
//   └─ panel    — the Popup box, `Open` BOOLEAN, holding
//        ├─ option × 3 — MenuItem INSTANCEs, the middle one marked
//        └─ empty      — `Empty state` BOOLEAN
// ```
//
// The trigger is a `TextField` rather than a `Button` because that is what
// the widget composes now, and the 4px it moves is the point: the field
// ladder insets 10 / 12 / 14 where the button ladder insets 12 / 16 / 20, so
// a select and a text field stacked in one form finally share a text line.
//
// The rows are `MenuItem` INSTANCEs for the same reason — no surveyed system
// draws an option row as a button, and the row's mark column is reserved on
// every row (`Show mark` on, `Marked` only on the selected one) so the labels
// keep one start line whether or not a row carries a check.
//
// The trigger's states are the field's, with the two divergences
// `CoreSelectStyle.defaultTriggerStyle` states: its wash is pressed-only
// (hover is the border step `outline` → `on-surface`, focus is the
// ring — neither paints a fill), and its value type is 14px `body-medium` at
// the role's own line height on every rung. The instance carries both from the field set (its `sm` /
// `md` / `lg` rungs already read that role, and the canvas field hides its
// hover / focus layers); the wash is restated below
// by overriding the instance's own `state layer` from `triggerStyle
// .stateLayer`, so the select's ramp — not the field's — is what a designer
// reads on the select. `pressed` has no field member, so that pose asks the
// field for `hover` (same border) and turns the layer on at the pressed
// weight.
//
// There is no search box. A select's letters move the cursor; a list the user
// narrows by typing is `Autocomplete`, and every reference system draws the
// boundary there.
// `filled` (#5747) composes the field's filled member.
const kSelectVariants = ['defaultVariant', 'error', 'filled'] as const;
const kSelectSizes = ['sm', 'md', 'lg'] as const;
const kSelectStates = stateAxis(['enabled', 'hover', 'focus', 'pressed', 'disabled']);
// The unchosen pose's copy — the designer's frame reads "옵션을 선택해 주세요",
// and the field's own "Placeholder" is a field word, not a select's.
const kSelectPlaceholderCopy = '옵션을 선택해 주세요';
// ItemPicker's search hint — `localizations.itemPickerSearchPlaceholder` (ko).
const kItemPickerSearchPlaceholder = '검색';
// The open list's rows. `name` is the row's layer name, held apart from the
// copy so translating the copy does not rename the layer a designer's
// override is keyed on.
const kSelectOptions = [
  { name: 'Apple', label: '사과', marked: false },
  { name: 'Banana', label: '바나나', marked: true },
  { name: 'Cherry', label: '체리', marked: false },
] as const;
type SelectSize = (typeof kSelectSizes)[number];
type SelectState = (typeof kSelectStates)[number];

function buildSelect(page: PageNode, lk: VarLookup): ComponentSetNode {
  const panelStyle = SELECT.fields.popoverStyle.panelStyle;
  const placeholderColor = colorData(SELECT.fields.placeholderColor);
  const emptyStateStyle = textStyleData({
    role: null,
    color: SELECT.fields.emptyStateColor,
  });
  const sizeRows = new Map(Object.entries(SELECT.sizes.defaultsBySize));
  // The chevron's tint: `placeholderColor` while the select is enabled, the
  // composed field's own disabled foreground once it is not — a disabled
  // select leaves the chevron untinted and the field's tone applies.
  const fieldRows = TEXT_FIELD.variants.defaultsByVariant;
  const chevronColorFor = (pose: {
    variant: (typeof kSelectVariants)[number];
    state: SelectState;
  }) =>
    pose.state === 'disabled'
      ? colorData(
          fieldRows[pose.variant === 'defaultVariant' ? 'default' : pose.variant]
            .disabledForegroundColor,
        )
      : placeholderColor;
  // The composed trigger's own ladder — where its corner comes from when Select
  // states none (see the trigger below).
  const textFieldRows = new Map(Object.entries(TEXT_FIELD.sizes.defaultsBySize));

  const names: string[] = [];
  const poses: {
    variant: (typeof kSelectVariants)[number];
    size: SelectSize;
    state: SelectState;
  }[] = [];
  for (const variant of kSelectVariants) {
    for (const size of kSelectSizes) {
      for (const state of kSelectStates) {
        // `disabled > error`: no member for the pair (header above).
        if (variant === 'error' && state === 'disabled') continue;
        poses.push({ variant: variant, size: size, state: state });
        names.push(`Variant=${variant}, Size=${size}, State=${state}`);
      }
    }
  }
  const mount = mountSet(page, 'Select', names);
  const emptyStates: FrameNode[] = [];
  const panels: FrameNode[] = [];
  // Flushed after `mount.finish()` — `exposeAll` explains why it cannot be set
  // where the trigger is made.
  const triggers: InstanceNode[] = [];

  for (let i = 0; i < poses.length; i++) {
    const pose = poses[i];
    const sz = sizeRows.get(pose.size);
    if (!sz) throw new Error(`Select: \`select.sizes.defaultsBySize\` has no \`${pose.size}\` row`);
    const c = mount.getOrCreate(names[i]);
    applyPanelCompChrome(c, 'VERTICAL', lk, {
      gap: SELECT.fields.popoverStyle.placementOffset,
    });

    // The trigger — the field itself, at this member's own variant, size
    // and state. `restingTextField` asks through `State`, so a disabled
    // select gets the disabled field rather than quietly landing on the
    // enabled rung.
    const trigger = restingTextField(
      page,
      pose.size,
      'trigger',
      pose.state !== 'disabled',
      pose.variant,
      // The field has no `pressed` member; its `hover` rung carries the
      // same border a pressed select shows, and the wash is restated below.
      pose.state === 'pressed' ? 'hover' : pose.state,
    );
    // The select's own ramp over the field's: `triggerStyle.stateLayer`
    // (pressed-only) decides what the instance's `state layer` shows, so
    // the hover / focus poses hide the layer the field member drew and the
    // pressed pose turns it on at the pressed weight. An instance child
    // takes `visible` / `opacity` overrides without detaching.
    const ramp = SELECT.fields.triggerStyle.stateLayer;
    const washWeight =
      pose.state === 'pressed'
        ? ramp.pressed
        : pose.state === 'focus'
          ? ramp.focus
          : pose.state === 'hover'
            ? ramp.hover
            : null;
    for (const layer of trigger.findAll((n) => n.name === 'state layer')) {
      layer.visible = washWeight != null && washWeight > 0;
      if (washWeight != null && 'opacity' in layer) layer.opacity = washWeight;
    }
    // `showCursor: false` — the widget hands the field `readOnly: true`
    // and no caret, so the focus pose is the ring alone. The field's own
    // `focus` member draws a caret (it is an editable), and an instance
    // child takes `visible` without detaching, so hide it here rather than
    // let the canvas show a cursor the widget never paints.
    //
    // Counted, and a focus pose that hid nothing throws — the idiom
    // `paintPlaceholder` / `revealValueOverPlaceholder` already use for the
    // field's other named parts. A loop over zero matches is a legal no-op,
    // so a field that renamed its caret would leave every focus member
    // showing a cursor the select never paints, with the harness and every
    // guard green. The other poses hide whatever is there and are not held
    // to a count: the field's own contract puts a caret on `focus`, and only
    // that member is the picture this override changes.
    let hiddenCarets = 0;
    for (const caret of trigger.findAll((n) => n.name === 'caret')) {
      caret.visible = false;
      hiddenCarets += 1;
    }
    if (pose.state === 'focus' && hiddenCarets === 0) {
      throw new Error(
        `Select: the focus trigger (${names[i]}) has no 'caret' node to hide — ` +
          'the composed TextField renamed its caret, and the select would show ' +
          'a cursor `showCursor: false` never paints.',
      );
    }
    setInstanceTextNamed(trigger, 'Placeholder', kSelectPlaceholderCopy);
    // `textFieldStyle: resolved.triggerStyle` — the field resolves its corner
    // as `merged.borderRadius ?? ss.borderRadius!`, so the corner is Select's
    // if the slot states one, else the composed field's own size row: the
    // control height × 0.25, sm 8 · md 10 · lg 12 across this set's `Size`
    // axis. Bound per member on the field ROW, not the instance root — the
    // root is the label column and paints nothing, so a corner written there
    // reaches no pixel.
    const triggerCorner =
      optField<{ topLeft: Dim }>(SELECT.fields.triggerStyle, 'borderRadius')?.topLeft ??
      sizeRowFor(textFieldRows, pose.size, TEXT_FIELD.axes.size.members).borderRadius.topLeft;
    pinComposedCorner(
      namedDescendant(trigger, kFieldRowName),
      lk,
      triggerCorner,
      TEXT_FIELD.fields.focusOutlineStyle,
    );
    // The chevron rides in the field's suffix seat, at the size THIS rung
    // states — `trailingIconStyle.size`, 14 / 16 / 18 on sm / md / lg
    // (`select_style.dart` derives `chevronIconStyle` from it; the field's own
    // suffix ladder steps the same 14 / 16 / 18 on those rungs, and the
    // select states its own row rather than reading the field's) — and in
    // the placeholder colour: it is the field's affordance, not its content.
    //
    // Swapped to the `Size=<step>` variant that row states, not the set's
    // default: a swap lands the variant it names, and the rescale
    // `stateSlotGlyphSize` attempts after it is refused on an instance
    // descendant and survived — so the set's default step would reach every
    // member whatever Core said. The step is chosen at the swap, where it
    // takes — and so is the colour.
    setSlotIcon(
      trigger,
      'suffix',
      iconMainIdAt(page, dimVal(sz.trailingIconStyle.size)),
      'chevron-down',
      glyphPaint(lk, labelColor(lk, chevronColorFor(pose))),
    );
    // The seat itself, at the same size. The field's suffix holder is FIXED
    // at the field's own step (`iconSlot` states the box), so on `lg` it is
    // a 24 box; the widget has no 24 seat — the `Icon` renders into a
    // `size × size` square and that square IS the seat — so binding the
    // holder to the select's size is the parity, the way `ColorPicker`
    // binds `Button`'s leading holder to `eyeDropperIconStyle`.
    bindSize(
      namedDescendant(trigger, 'suffix'),
      lk,
      sz.trailingIconStyle.size,
      sz.trailingIconStyle.size,
    );
    stateSlotGlyphSize(trigger, 'suffix', sz.trailingIconStyle.size);
    // The two colours Select folds into the field (`effectiveTriggerStyle`):
    // the placeholder in `placeholderColor` — the same token the chevron
    // takes — and the chosen value in `contentColor`. The value node sits
    // hidden under the placeholder on every member (the canvas shows the
    // unchosen pose), and is painted anyway so a designer who types a
    // `Value` sees the select's colour, not the field's.
    // A disabled select folds neither colour (`effectiveDisabledTriggerStyle`):
    // the composed field member's own disabled foreground stays on both the
    // placeholder and the value.
    if (pose.state !== 'disabled') {
      paintPlaceholder(trigger, lk, placeholderColor);
      applyInstanceTextStyle(
        namedDescendant(trigger, kFieldValueName),
        lk,
        textStyleData({ role: null, color: SELECT.fields.contentColor }),
      );
    }
    // The value type reads at the field's own per-size default now
    // (`TEXT_FIELD.sizes.defaultsBySize[size].baseTextStyle`) — Select no
    // longer restates it (2026-09-11 재검토, `select_style.dart`): the
    // field's own `sm` / `md` / `lg` rungs read at 14px `body-medium` at the
    // role's own line height themselves, so a Select-specific override would be the
    // "flat default equals child default" duplicate `core/style-contract.md`
    // forbids. Stated on both text stacks so the placeholder and a typed
    // value agree.
    for (const stack of [kFieldInputName, kFieldValueName]) {
      applyInstanceTextStyle(
        namedDescendant(trigger, stack),
        lk,
        textStyleData(TEXT_FIELD.sizes.defaultsBySize[pose.size].baseTextStyle),
      );
    }
    c.appendChild(trigger);
    trigger.layoutSizingHorizontal = 'FILL';
    triggers.push(trigger);

    // The panel — drawn in every member, shown by the `Open` BOOLEAN.
    // Drawn rather than omitted because a layer that does not exist
    // cannot be revealed from an instance, and every value the panel
    // carries would otherwise reach no node at all.
    const options = panel('panel', 'VERTICAL', lk, {
      pl: panelStyle.padding.l,
      pr: panelStyle.padding.r,
      pt: panelStyle.padding.t,
      pb: panelStyle.padding.b,
      gap: SELECT.fields.optionSpacing,
    });
    bindRadiusN(options, lk, panelStyle.borderRadius.topLeft);
    // The box is the composed `Popup`'s (`Popover` → `Popup` on both
    // platforms), a functional surface that takes the rim — drawn here, so it
    // wears the material here.
    applySurfaceMaterial(options, lk, colorData(panelStyle.backgroundColor), 'functional', {
      radius: panelStyle.borderRadius.topLeft,
      rim: true,
    });
    borderData(
      options,
      lk,
      colorData(panelStyle.borderColor),
      panelStyle.borderWidth,
    );
    setShadow(
      options,
      panelStyle.boxShadow,
      lk,
      colorData(panelStyle.shadowBaseColor),
    );
    c.appendChild(options);
    options.layoutSizingHorizontal = 'FILL';
    panels.push(options);
    // The widget's own ceiling on the list, above which it scrolls
    // instead of growing. Unbound: the value's `ref` is null (it comes
    // from `CorePopoverStyle.defaultFormPopoverMaxHeight`, not from a step
    // on a ladder), and binding it would claim a token the data does not
    // name.
    options.maxHeight = dimVal(SELECT.fields.optionsPanelMaxHeight);

    // Three rows, the middle one marked — the mark column is reserved on
    // all three, which is the thing that was wrong before it was a
    // `MenuItem`: an unmarked row started its label at the panel edge and
    // a marked one started it a check further in.
    //
    // At the trigger's own rung: `size: widget.size.toMenuItemSize()` — a
    // `md` select opens onto `md` rows (36 under the 40 trigger), never `sm`
    // rows.
    for (const option of kSelectOptions) {
      const row = instanceOf(
        page,
        'MenuItem',
        bestVariantName(page, 'MenuItem', {
          Size: pose.size,
          State: 'enabled',
          Tone: 'neutral',
        }),
      );
      row.name = option.name;
      setInstanceTextNamed(row, 'Label', option.label);
      setInstanceBoolNamed(row, 'Show shortcut', false);
      setInstanceBoolNamed(row, 'Show mark', true);
      setInstanceBoolNamed(row, 'Marked', option.marked);
      // `menuItemStyle: resolved.optionStyle` — the panel states its rows'
      // corner (6 on every size): a row inside the panel's corner is not a
      // standalone row, whose own ladder would draw a different corner here. Pinned onto
      // the box, its wash and its ring, so the hosted row is one picture.
      pinComposedCorner(
        row,
        lk,
        SELECT.fields.optionStyle.borderRadius.topLeft,
        MENU_ITEM.fields.clickableStyle.focusOutlineStyle,
      );
      if (option.marked) {
        // The mark is Select's one decision about a row — neutral, not the
        // accent (`selectedIconColor`, folded into `optionStyle.markIconStyle`
        // by `effectiveOptionStyle`). The glyph sits in the row's `mark`
        // seat at the row's own mark size.
        paintSlotGlyph(
          row,
          'mark',
          lk,
          colorData(SELECT.fields.selectedIconColor),
          SELECT.fields.optionStyle.markIconStyle.size,
        );
      }
      options.appendChild(row);
      row.layoutSizingHorizontal = 'FILL';
    }

    // `emptyStateInsets` / `emptyStateColor` describe the copy the panel
    // shows when the list is empty — a real part of the panel, hidden here
    // so the populated list is what the canvas reads.
    const empty = panel('empty', 'VERTICAL', lk, {
      pl: SELECT.fields.emptyStateInsets.l,
      pr: SELECT.fields.emptyStateInsets.r,
      pt: SELECT.fields.emptyStateInsets.t,
      pb: SELECT.fields.emptyStateInsets.b,
    });
    empty.appendChild(
      makeLabel('검색 결과가 없어요', lk, textLabelOpts(lk, emptyStateStyle, placeholderColor)),
    );
    options.appendChild(empty);
    empty.layoutSizingHorizontal = 'FILL';
    empty.visible = false;
    emptyStates.push(empty);

    // The widget floors AND caps the panel at the trigger's own width
    // (`.anchorFixedSize`), so on the canvas the two share one number.
    // g7-preview-only: the demo trigger width that number comes from.
    lockWidth(c, 240);
    popoverWrapper(page, c);
  }

  const set = mount.finish();
  const emptyProp = defineProp(set, 'Empty state', 'BOOLEAN', false);
  for (const node of emptyStates) bindVisibleProp(node, emptyProp);
  // Default FALSE so a fresh instance dropped into a form reads at the
  // same height as its Form siblings instead of arriving as a
  // permanently-open block next to their 40px rows.
  const openProp = defineProp(set, 'Open', 'BOOLEAN', false);
  for (const node of panels) bindVisibleProp(node, openProp);
  // The chosen value lives on the trigger field (`Value` · `Value text` ·
  // `Placeholder`), and nothing on the select itself reached it — a designer had
  // to dig into the layer tree to say what was picked (#5607). Exposed, the
  // field's properties show on the select's own panel, the way the pickers
  // expose theirs.
  exposeSlot(triggers, 'Suffix', 'INSTANCE_SWAP');
  // g7-preview-only: gallery width of the Select variant grid.
  layoutSet(set, 560);
  return set;
}

// ─── Autocomplete ────────────────────────────────────────────────────────────
//
// `autocomplete.dart` is `Popover(trigger: TextField(...), content: the
// suggestion list)`. The trigger is a composed `TextField` — no magnifier
// glyph, no bespoke box: the widget passes no prefix at all, so the search
// icon this used to draw was invented chrome, and the field's border/padding
// were a second copy of TextField's.
//
// `CoreAutocompleteStyle` exposes only dropdown chrome (dropdownTextStyle /
// optionHoverColor / optionHoverTextStyle / optionBorderRadius /
// optionPadding / dropdownMaxHeight) — which is exactly what the panel below
// the field is made of, now that the panel is drawn.
//
// The `Popover` that wraps the field and that dropdown is composed —
// `needs: ['Popover']`, a hidden ABSOLUTE instance from `popoverWrapper`
// (header there for why the wrapper is a sibling and why it does not draw).
// The column's gap is that Popover's `placementOffset`, the field↔dropdown
// distance.
//
// A COMPONENT_SET now, by ADOPTION rather than by migration: `autocomplete.axes`
// promotes `enabled`, so the enumeration is two combinations and `mountSet`'s
// `adoptLooseAs` renames the loose COMPONENT to `Enabled=true` in place — which
// is why no `STRUCTURAL_MIGRATIONS` entry is needed for the shape change (the
// earlier note here declined the axis on exactly that cost). Its
// `CoreAutocompleteMode` enum stays in `axes.other`, recorded and deliberately
// not promoted (the seed spec's §4-2 boundary).
//
// `Enabled=false` is two things, and neither is invented: the composed field
// instantiates `TextField`'s own disabled variant (`autocomplete.dart:445` hands
// it `enabled: widget.enabled`), and the dropdown is not drawn at all, because
// `_showPanel` is `_focusNode.hasFocus && widget.enabled && …`
// (`autocomplete.dart:264`) — a disabled autocomplete has no path to an open
// panel. `autocomplete.fields` declares no disabled colour of its own.
//
// Open/closed remains a `Dropdown` BOOLEAN over the panel, not an axis, for the
// reason `Select` keeps one: it is a pose the four axes do not carry.
// Demo rows of the open list; the first row's match is the query typed in the
// trigger.
// `name` is the row's layer name, held apart from the copy so translating the
// copy does not rename the layer a designer's override is keyed on.
const kAutocompleteSuggestions = [
  { name: 'Apple', before: '', match: '과', after: '자', hovered: false },
  { name: 'Grape', before: '사', match: '과', after: '잼', hovered: true },
  { name: 'Wrap', before: '사', match: '과', after: '', hovered: false },
];

function buildAutocomplete(page: PageNode, lk: VarLookup): ComponentSetNode {
  const panelStyle = AUTOCOMPLETE.fields.popoverStyle.panelStyle;
  const optionPad = AUTOCOMPLETE.fields.optionPadding;
  const text = textStyleData(AUTOCOMPLETE.fields.dropdownTextStyle);
  const hoverText = textStyleData(AUTOCOMPLETE.fields.optionHoverTextStyle);
  const matchText = textStyleData(AUTOCOMPLETE.fields.matchTextStyle);
  const combos = enumerateAxisCombos(axisSpecsOf(AUTOCOMPLETE.axes));
  const mount = mountSet(page, 'Autocomplete', combos, {
    adoptLooseAs: 'Enabled=true',
  });
  const dropdowns: FrameNode[] = [];
  for (const comboName of combos) {
    const enabled = parseVariantKey(comboName)['Enabled'] !== 'false';
    const c = mount.getOrCreate(comboName);
    applyPanelCompChrome(c, 'VERTICAL', lk, {
      gap: AUTOCOMPLETE.fields.popoverStyle.placementOffset,
    });
    // The panel is only ever open while the input holds focus and a query
    // (`_showPanel` is `_focusNode.hasFocus && widget.enabled && <rows>`,
    // `autocomplete.dart:264`), so an enabled member — which draws the open
    // list — draws its trigger in the field's own `focus` pose with the typed
    // query in the value seat and the placeholder hidden behind it. The field
    // is an editable (`showCursor` is left at its default), so the `focus`
    // member's caret stays. A disabled member never opens, and keeps the
    // disabled rung.
    const input = restingTextField(
      page,
      'md',
      'input',
      enabled,
      'defaultVariant',
      enabled ? 'focus' : undefined,
    );
    c.appendChild(input);
    if (enabled) setFieldValue(input, kAutocompleteSuggestions[0].match);
    // g7-preview-only: demo field width so the dropdown below it has a width to match — `CoreAutocompleteStyle` states `dropdownMaxHeight` but no width, and `autocomplete.dart` floors the panel at the input's own width via `.anchorMinSize`.
    lockWidth(c, 240);
    input.layoutSizingHorizontal = 'FILL';
    if (!enabled) {
      // `Popover(trigger: input, content: _buildPanel(resolved))` — the wrapper
      // is still in the tree when the field is disabled; only its panel is
      // unreachable.
      popoverWrapper(page, c);
      continue;
    }

    const dropdown = panel('dropdown', 'VERTICAL', lk, {
      pl: panelStyle.padding.l,
      pr: panelStyle.padding.r,
      pt: panelStyle.padding.t,
      pb: panelStyle.padding.b,
    });
    bindRadiusN(dropdown, lk, panelStyle.borderRadius.topLeft);
    // `ConstrainedBox(constraints: BoxConstraints(maxHeight: dropdownMaxHeight))`
    // around the panel — `_buildPanel` states it and nothing else caps the list, so
    // an uncapped panel here grows with however many rows a designer pastes in.
    dropdown.maxHeight = dimVal(AUTOCOMPLETE.fields.dropdownMaxHeight);
    // The composed `Popup`'s box, as in Select above.
    applySurfaceMaterial(dropdown, lk, colorData(panelStyle.backgroundColor), 'functional', {
      radius: panelStyle.borderRadius.topLeft,
      rim: true,
    });
    borderData(
      dropdown,
      lk,
      colorData(panelStyle.borderColor),
      panelStyle.borderWidth,
    );
    // Same panel, same two `boxShadow` layers as Select's — this is the popover
    // panel `autocomplete.dart` floats over the field, and it was flat.
    setShadow(
      dropdown,
      panelStyle.boxShadow,
      lk,
      colorData(panelStyle.shadowBaseColor),
    );
    c.appendChild(dropdown);
    dropdown.layoutSizingHorizontal = 'FILL';
    dropdowns.push(dropdown);
    // The label is split around the query's first occurrence the way
    // `CoreAutocompleteMatch` does in code — the matched piece is SemiBold
    // `on-surface`, the rest Regular (`on-surface-variant`, or the hover
    // text). The three demo rows put the match at the start, in the middle
    // and at the end of the label (query `과`).
    const suggestions = kAutocompleteSuggestions;
    for (const suggestion of suggestions) {
      const rowName = suggestion.name;
      const row = autoFrame(rowName, 'HORIZONTAL');
      row.counterAxisAlignItems = 'CENTER';
      bindPad(row, lk, {
        l: optionPad.l,
        r: optionPad.r,
        t: optionPad.t,
        b: optionPad.b,
      });
      bindRadiusN(row, lk, AUTOCOMPLETE.fields.optionBorderRadius.topLeft);
      if (suggestion.hovered) {
        fillData(row, lk, colorData(AUTOCOMPLETE.fields.optionHoverColor));
      } else {
        row.fills = [];
      }
      const baseOpts = textLabelOpts(lk, suggestion.hovered ? hoverText : text);
      const matchOpts = textLabelOpts(lk, matchText);
      for (const [piece, opts] of [
        [suggestion.before, baseOpts],
        [suggestion.match, matchOpts],
        [suggestion.after, baseOpts],
      ] as const) {
        if (piece === '') continue;
        row.appendChild(makeLabel(piece, lk, opts));
      }
      dropdown.appendChild(row);
      row.layoutSizingHorizontal = 'FILL';
    }
    // `Popover(trigger: input, content: _buildPanel(resolved))` — the wrapper
    // around the field and the dropdown above.
    popoverWrapper(page, c);
  }
  const set = mount.finish();
  // On the SET, after `finish()`: until `combineAsVariants` runs a fresh
  // variant has no parent, so a per-member definition would scatter one
  // property per variant.
  const dropdownProp = defineProp(set, 'Dropdown', 'BOOLEAN', true);
  for (const node of dropdowns) bindVisibleProp(node, dropdownProp);
  rowSet(set);
  return set;
}

// ─── SwitchField (title + description + toggle) ───────────────────────────────
//
// The toggle is a real `Toggle` INSTANCE, not a redrawn track+thumb.
// `switch_field.dart` composes `Toggle` and forwards exactly two values into
// it (`toggleStyle: CoreToggleStyle(trackActiveColor: resolved.activeColor,
// trackInactiveColor: resolved.inactiveColor)`), which is why SwitchField's
// own data has the two track colours and none of the geometry: the track, the
// thumb and the thumb offsets are `Toggle`'s defaults at the size the field
// forwards (`size`, below). A
// hand-drawn copy of them is a second source that cannot follow — Figma
// propagates a main component's change to its instances, and the
// content-hash skip means a run where only `toggle.dart`'s data moved would
// not even re-run this builder. So the geometry now comes from where it
// lives, and the two forwarded colours ride along with it.
//
// The instance's own demo label ("Toggle", drawn by `buildToggle` next to the
// track) is hidden: SwitchField supplies the label itself, in its own column.
// Auto-layout skips invisible children entirely, so the instance hugs down to
// just the track and no gap is left behind.
//
// Axes — `Enabled` (the schema's: `switch_field.axes` promotes it, and the old
// `State=Off` child carries its key forward into `Enabled=true` per
// `src/renames.ts`) and the `On` POSE, independent because they combine.
//
// `Enabled` is real chrome here, which is why it is not two identical members:
// `labelTextStyle` (on-surface) vs `disabledLabelTextStyle` (on-surface-variant),
// `descriptionTextStyle` vs `disabledDescriptionTextStyle` (two fields, each
// read for its own pose, so a Core change to either one arrives), the composed
// `Toggle`'s disabled rung, and `clickableStyle
// .disabledOpacity` on the root. That opacity is `opacity100` today, so it dims
// nothing — it is read anyway, because reading it is what makes a change to it
// in Core arrive here.
//
// `On` is a POSE and not one of the four: the switch's on/off is the widget's
// VALUE, so the old `State=On` member is retired in `src/renames.ts` rather than
// migrated. It is still an axis and not a BOOLEAN because the two positions are
// mutually exclusive and each one instantiates a DIFFERENT child variant —
// Figma cannot express "exactly one of these two properties", which is the same
// reasoning `Fab`'s `Open` axis records for its two glyphs.
//
// Both axes map onto `Toggle`'s own, so each variant instantiates the matching
// Toggle variant and the track/thumb side of both states comes from the child.
// That variant is resolved by axis rather than spelled out, so an axis added or
// renamed in `form.ts` degrades to the nearest match instead of failing this
// component's entry and leaving it half-drawn on the page.
function buildSwitchField(page: PageNode, lk: VarLookup): ComponentSetNode {
  // NOT composed: `Clickable`. `switch_field.dart` wraps the whole row in one, and
  // `Clickable` is a wrapper with no chrome of its own at rest — its Figma
  // component is a focus ring around a demo slot, and an instance takes no
  // appended children, so there is nothing to put the row inside.
  const labelStyle = textStyleData(SWITCH_FIELD.fields.labelTextStyle);
  const disabledLabelStyle = textStyleData(SWITCH_FIELD.fields.disabledLabelTextStyle);
  const desc = textStyleData(SWITCH_FIELD.fields.descriptionTextStyle);
  const disabledDesc = textStyleData(SWITCH_FIELD.fields.disabledDescriptionTextStyle);
  // The disabled track colours come from `Toggle`'s own variant style
  // (`disabledActiveTrack` / `disabledInactiveTrack`), not from
  // `SwitchField`'s two forwarded colours — `switch_field.dart` never
  // overrides those two fields on the composed `Toggle`, so at runtime
  // a disabled switch shows `Toggle`'s own disabled tokens regardless
  // of `SwitchField.activeColor` / `.inactiveColor`. The explicit fill
  // below must follow the same split or a disabled member draws the
  // enabled colours (#4815 디자이너 결정 #3).
  const toggleVariant = new Map(
    Object.entries(TOGGLE_CTRL.variants.defaultsByVariant),
  ).get('default');
  if (!toggleVariant) {
    throw new Error('SwitchField: `Toggle` defaultsByVariant has no `default` row');
  }
  const combos = enumerateAxisCombos(
    withPoses(axisSpecsOf(SWITCH_FIELD.axes), 'On'),
  );
  const mount = mountSet(page, 'SwitchField', combos);
  const labels: TextNode[] = [];
  const descriptions: TextNode[] = [];
  for (const comboName of combos) {
    const combo = parseVariantKey(comboName);
    const disabled = combo['Enabled'] === 'false';
    const on = combo['On'] === 'true';
    const c = mount.getOrCreate(comboName);
    applyPanelCompChrome(c, 'HORIZONTAL', lk, { gap: SWITCH_FIELD.fields.labelToggleGapStyle.size });
    c.counterAxisAlignItems = 'CENTER';
    // `clickableStyle.disabledOpacity` — `opacity100` for this component, so
    // this dims nothing today and that is the reason to READ it rather than
    // to reason about it: the previous version left the field unread on the
    // strength of its current value, so a change to `opacity50` in Core would
    // have moved the app and not the canvas, with nothing red in between.
    if (disabled) c.opacity = dimVal(SWITCH_FIELD.fields.clickableStyle.disabledOpacity);
    // g7-preview-only: demo row width so the label/description have somewhere to wrap — neither `CoreSwitchFieldStyle` nor `switch_field.dart` states a width; the real row fills whatever the caller gives it.
    lockWidth(c, 300);
    const txt = panel('text', 'VERTICAL', lk, { gap: SWITCH_FIELD.fields.labelDescriptionGapStyle.size });
    const label = makeLabel(
      '이메일 알림',
      lk,
      textLabelOpts(lk, disabled ? disabledLabelStyle : labelStyle),
    );
    const description = makeLabel(
      '새 소식을 이메일로 받아요',
      lk,
      textLabelOpts(lk, disabled ? disabledDesc : desc),
    );
    txt.appendChild(label);
    txt.appendChild(description);
    labels.push(label);
    descriptions.push(description);
    c.appendChild(txt);
    txt.layoutSizingHorizontal = 'FILL';
    const toggle = instanceOf(
      page,
      'Toggle',
      bestVariantName(page, 'Toggle', {
        // The child's axes as its builder spells them: `On` is the pose this
        // row is on, and `State` is the ladder `Enabled` folded into. Asked
        // for by the resting rung, never `hover` — the pointer is over the
        // field, and what changes under it is the field's own statement.
        // `bestVariantName` scores a missing axis as a silent zero, so a key
        // the child does not carry would leave every `Size=md` member tied and
        // hand back the first one, an OFF thumb under the ON fill below. No
        // `Variant:` for that reason — `Toggle` dropped its one-value axis in
        // the 2026-09 redesign, and a key for an axis the set no longer has
        // is exactly that silent zero.
        // The size the widget forwards, not a literal. `switch_field.dart`
        // hands its own `size` to the composed `Toggle`, so the member to pick
        // is the one at `SWITCH_FIELD.fields.size` — a row naming any other
        // size points at a switch the field never draws, and a literal there
        // is right only for as long as the field happens to agree with it.
        Size: SWITCH_FIELD.fields.size.choice,
        State: disabled ? 'disabled' : 'enabled',
        On: `${on}`,
      }),
    );
    hideInstanceText(toggle);
    // Through the property as well: the field draws its own label, and a
    // visibility override on the child's text node was back on after the
    // next regeneration (the live canvas showed "Toggle" beside every
    // field). The property is the child's own statement and survives it.
    setInstanceBool(toggle, 'Show suffix', false);
    // `activeColor` / `inactiveColor`, forwarded into the composed `Toggle`'s
    // track — `switch_field.dart` hands them over as `trackActiveColor` /
    // `trackInactiveColor`, and the instance was showing `Toggle`'s own track
    // colour for both states. Which of the two applies is the `On` pose this
    // loop is already on — the same pose the child was picked by.
    //
    // Only for the ENABLED half, though: `switch_field.dart` never touches
    // `Toggle`'s `disabledActiveTrack` / `disabledInactiveTrack`, so a
    // disabled switch's track is `Toggle`'s own disabled tokens, not
    // `SwitchField`'s two forwarded colours (`toggleVariant` above).
    fillData(
      namedDescendant(toggle, kToggleTrackName),
      lk,
      colorData(
        disabled
          ? on
            ? toggleVariant.disabledActiveTrack
            : toggleVariant.disabledInactiveTrack
          : on
            ? SWITCH_FIELD.fields.activeColor
            : SWITCH_FIELD.fields.inactiveColor,
      ),
    );
    c.appendChild(toggle);
  }
  const set = mount.finish();
  const labelProp = defineProp(set, 'Label', 'TEXT', '이메일 알림');
  const descProp = defineProp(set, 'Description', 'TEXT', '새 소식을 이메일로 받아요');
  for (const n of labels) bindTextProp(n, labelProp);
  for (const n of descriptions) bindTextProp(n, descProp);
  vStackSet(set);
  return set;
}

// ─── Range (dual-thumb slider) ───────────────────────────────────────────────
//
// Data-driven from coui_core RANGE.fields — CoreRangeStyle has no variant/
// size dispatch. The slider canvas size (240x36) and the thumb x positions /
// fill x+width (which encode a *value*, not chrome) stay literal — this
// static preview's own layout choices, same reasoning as Slider's canvas
// (form.ts).
//
// `leading` / `trailing` (`W?`) are the min/max labels: `range.dart` lays
// them out around the slider separated by `Gap(gapStyle:
// resolved.minMaxGapStyle)`, and that gap is the field bound below — which is
// what makes a text node the truthful stand-in for these two slots rather
// than an invented one. Their colour is the one literal here (coui_core has
// no min/max label colour — the caller's widget carries its own).
//
// Each slot carries TWO properties, on two nodes, because one node holds a
// single `componentPropertyReferences` map:
//
//   · `Leading` / `Trailing` (TEXT, on the label) — the copy. A slot typed
//     `W?` accepts any widget, and TEXT is the ceiling for one the builder
//     renders as words: swapping would want a `Text` component in the
//     REGISTRY, and that was decided against (Figma's native typography
//     mechanism is the shared Text Style).
//   · `Show leading` / `Show trailing` (BOOLEAN, on the holder frame) —
//     `range.dart` emits the label AND its gap only `if (leading != null)`,
//     so "Range without a max label" is a state the widget really has. Both
//     default to shown, since `minMaxGapStyle` exists for that arrangement.
//
// Composed: `FocusOutline`, one instance per thumb. `range.dart` wraps each
// thumb in it ("The keyboard ring is `FocusOutline`'s job on both platforms —
// drawing it on the thumb itself would be a second ring implementation whose
// geometry only matches the Web twin's for as long as someone keeps matching
// it by hand"), which is also the answer to the ring's missing width: it is
// the child's own, not one invented here. `focusOutlineStyle` supplies the
// values the widget forwards INTO that child — `borderColor` and
// `borderWidth`, painted onto the child's own ring layer — while the
// `circleBorderRadius` that `shape: .circle` selects comes from the child's
// `Shape=circle` member, which is the axis that reads it. The child's `child`
// slot is resized to the thumb so the ring hugs it.
//
// The rings are hidden behind a `Focus` BOOLEAN rather than shown at rest:
// the wrapper is always in the widget's tree but paints only while
// `_showMinFocusOutline` / `_showMaxFocusOutline`, and a ring on both thumbs
// of a resting Range would be chrome the component does not have. A property
// rather than an axis, because the four axes carry no focus pose and adding a
// fifth here would double a set whose two members already render alike.
//
// A COMPONENT_SET, by ADOPTION rather than by migration: `range.axes` promotes
// `enabled`, so the enumeration is two combinations and `mountSet`'s
// `adoptLooseAs` renames the loose COMPONENT to `Enabled=true` in place — no
// `STRUCTURAL_MIGRATIONS` entry needed for the shape change.
//
// `Enabled=false` swaps the four colours that `range.fields` states for it —
// `disabledInactiveTrackColor` / `disabledActiveTrackColor` / `disabledThumbColor`
// / `disabledThumbBorderColor` — exactly as the resolvers read
// `enabled ? <token> : <disabled token>`. Nothing fades: no opacity is stated.
function buildRange(page: PageNode, lk: VarLookup): ComponentSetNode {
  const combos = enumerateAxisCombos(axisSpecsOf(RANGE.axes));
  const mount = mountSet(page, 'Range', combos, { adoptLooseAs: 'Enabled=true' });
  const leadingHolders: FrameNode[] = [];
  const leadingLabels: TextNode[] = [];
  const trailingHolders: FrameNode[] = [];
  const trailingLabels: TextNode[] = [];
  const rings: SceneNode[] = [];
  for (const comboName of combos) {
    const disabled = parseVariantKey(comboName)['Enabled'] === 'false';
    const inactiveTrackColor = disabled
      ? RANGE.fields.disabledInactiveTrackColor
      : RANGE.fields.inactiveTrackColor;
    const activeTrackColor = disabled
      ? RANGE.fields.disabledActiveTrackColor
      : RANGE.fields.activeTrackColor;
    const thumbColor = disabled
      ? RANGE.fields.disabledThumbColor
      : RANGE.fields.thumbColor;
    const thumbBorderColor = disabled
      ? RANGE.fields.disabledThumbBorderColor
      : RANGE.fields.thumbBorderColor;
    const c = mount.getOrCreate(comboName);
    c.layoutMode = 'HORIZONTAL';
    // Hugging while the three children come in — a recycled member may still be
    // FIXED at a stale width — and frozen once they have (see the end of this
    // loop).
    c.primaryAxisSizingMode = 'AUTO';
    c.counterAxisSizingMode = 'AUTO';
    c.counterAxisAlignItems = 'CENTER';
    c.setBoundVariable('itemSpacing', lk.space(dimVal(RANGE.fields.minMaxGapStyle.size)));
    c.fills = [];
    const leadingHolder = autoFrame('leading', 'HORIZONTAL');
    leadingHolder.counterAxisAlignItems = 'CENTER';
    // g7-preview-only: type size + colour of the stand-in min label — `leading` is a raw `Widget?` that `range.dart` inserts unstyled, so this text style is the caller's, and `CoreRangeStyle` has no min/max label style to source.
    const leading = makeLabel('0', lk, { size: 14, colorVar: lk.sem('on-surface-variant') });
    leadingHolder.appendChild(leading);
    c.appendChild(leadingHolder);
    leadingHolders.push(leadingHolder);
    leadingLabels.push(leading);
    // The track/fill/thumbs are absolutely positioned, so they need a
    // layoutMode: 'NONE' frame of their own now that the component itself is an
    // auto-layout row.
    const canvas = figma.createFrame();
    canvas.name = 'slider';
    canvas.layoutMode = 'NONE';
    canvas.clipsContent = false;
    canvas.fills = [];
    canvas.resize(240, 36);
    const trackHeight = dimVal(RANGE.fields.trackHeight);
    const trackY = (36 - trackHeight) / 2;
    const thumbSize = dimVal(RANGE.fields.thumbSize);
    const thumbY = (36 - thumbSize) / 2;
    // How the picture follows a resize (#4826) — the same three pins as
    // Slider's (form.ts), read there: the rail STRETCHes because it is the
    // box; the active fill SCALEs because both of its ends are values; each
    // knob rides a `travel` frame spanning 0 → its own centre (SCALE) and is
    // pinned to that frame's far edge (MAX), so its position keeps the ratio
    // while its size stays `thumbSize`. The fill's ends ARE the two knobs'
    // centres (60 and 170 with a 20px knob), so all three stay aligned.
    const track = figma.createRectangle();
    track.name = 'rail';
    // g7-preview-only: the track's length is this preview's own canvas width — `range.dart` takes it from `constraints.maxWidth` inside an `Expanded`, so there is no width in the widget or in `CoreRangeStyle` to read.
    bindSize(track, lk, 240, RANGE.fields.trackHeight);
    bindRadiusN(track, lk, RANGE.fields.borderRadius.topLeft);
    fillData(track, lk, colorData(inactiveTrackColor));
    canvas.appendChild(track);
    track.x = 0;
    track.y = trackY;
    track.constraints = { horizontal: 'STRETCH', vertical: 'CENTER' };
    const fill = figma.createRectangle();
    fill.name = 'active';
    // g7-preview-only: the active fill's length stands in for a VALUE, not chrome — `range.dart` derives it from `maxOffset - minOffset`, i.e. wherever the two thumbs currently are.
    bindSize(fill, lk, 110, RANGE.fields.trackHeight);
    bindRadiusN(fill, lk, RANGE.fields.borderRadius.topLeft);
    fillData(fill, lk, colorData(activeTrackColor));
    canvas.appendChild(fill);
    fill.x = 60;
    fill.y = trackY;
    fill.constraints = { horizontal: 'SCALE', vertical: 'CENTER' };
    const ringStyle = RANGE.fields.focusOutlineStyle;
    const xs = [50, 160];
    for (const x of xs) {
      const travel = figma.createFrame();
      travel.name = 'travel';
      travel.layoutMode = 'NONE';
      travel.fills = [];
      travel.clipsContent = false;
      travel.resize(x + thumbSize / 2, canvas.height);
      canvas.appendChild(travel);
      travel.x = 0;
      travel.y = 0;
      travel.constraints = { horizontal: 'SCALE', vertical: 'STRETCH' };
      // The ring goes down first so the thumb paints over it, the same order
      // `FocusOutline(child: thumb)` gives the two.
      // `Shape=circle` by name — `range.dart` passes `shape: .circle`, and the
      // member draws that branch's radius itself. Naming it replaces a radius
      // override that used to reach into the child's own `circleBorderRadius`
      // to restate what the axis now says.
      const ring = instanceOf(page, 'FocusOutline', 'Shape=circle');
      ring.name = 'focus ring';
      const slot = instanceFrameSlot(ring, 'child');
      if (slot) slot.resize(thumbSize, thumbSize);
      // And the instance itself: an inner slot resize does not re-hug the
      // root, and the root is the wrapped box now — the thumb — with the
      // child's ring layers hanging outside it on STRETCH constraints. This is
      // also what centres the ring on the thumb; the old root carried the
      // offset band as padding, so pinning it at the thumb's own origin put
      // the ring two pixels down and right of centre.
      ring.resize(thumbSize, thumbSize);
      // On the ring RECTANGLE, not on the instance root: the root is the
      // child's own box, so a stroke there would draw a second ring flush
      // against the thumb while the real one sits `align` px outside it. The
      // colour is a genuine forward — `range.focusOutlineStyle.borderColor` is
      // `primary`, where the child's own default is `focus-ring`.
      borderData(focusOutlineRing(ring), lk, colorData(ringStyle.borderColor), ringStyle.borderWidth);
      // Pinned through a holder — `constraints` is refused on an instance, and
      // the holder is what rides `travel`'s far edge alongside the knob.
      const ringHolder = pinAbsolute(travel, ring, x, thumbY, { horizontal: 'MAX', vertical: 'MIN' });
      sizePin(ringHolder, thumbSize, thumbSize);
      // The parent's `Focus` BOOLEAN gates this holder (see the loop that
      // binds `rings` below), so the instance's own layers stay on —
      // `FocusOutline` rests unfocused now, and a revealed instance whose
      // `Focused` is false would draw nothing.
      setInstanceBool(ring, 'Focused', true);
      ringHolder.visible = false;
      rings.push(ringHolder);
      const thumb = figma.createEllipse();
      thumb.name = 'thumb';
      bindSize(thumb, lk, RANGE.fields.thumbSize, RANGE.fields.thumbSize);
      fillData(thumb, lk, colorData(thumbColor));
      borderData(thumb, lk, colorData(thumbBorderColor), RANGE.fields.thumbBorderWidth);
      travel.appendChild(thumb);
      thumb.x = x;
      thumb.y = thumbY;
      thumb.constraints = { horizontal: 'MAX', vertical: 'MIN' };
    }
    c.appendChild(canvas);
    const trailingHolder = autoFrame('trailing', 'HORIZONTAL');
    trailingHolder.counterAxisAlignItems = 'CENTER';
    // g7-preview-only: type size + colour of the stand-in max label — `trailing` is a raw `Widget?` that `range.dart` inserts unstyled, so this text style is the caller's, and `CoreRangeStyle` has no min/max label style to source.
    const trailing = makeLabel('100', lk, { size: 14, colorVar: lk.sem('on-surface-variant') });
    trailingHolder.appendChild(trailing);
    c.appendChild(trailingHolder);
    trailingHolders.push(trailingHolder);
    trailingLabels.push(trailing);
    // `range.dart` puts the slider in an `Expanded`: the labels take their own
    // width and the track takes the rest. FIXED freezes the width the row just
    // hugged to — no width of the widget's is being stated, the row simply
    // stops hugging — and FILL on the canvas is what hands a resized
    // instance's width to the track (#4826). Written after all three children
    // are in the row, so the frozen width is the hugged one.
    c.primaryAxisSizingMode = 'FIXED';
    canvas.layoutSizingHorizontal = 'FILL';
  }
  const set = mount.finish();
  // On the SET, after `finish()`: a fresh variant has no parent until
  // `combineAsVariants` runs, so `propertyOwner` would answer with the member
  // itself and scatter one definition per variant. The nodes are inside their
  // component by now too, which `componentPropertyReferences` requires ("Can
  // only set component property references on symbol sublayer" is the throw
  // that fails the entry and leaves this component half-built on the page).
  const showLeading = defineProp(set, 'Show leading', 'BOOLEAN', true);
  for (const node of leadingHolders) bindVisibleProp(node, showLeading);
  const leadingProp = defineProp(set, 'Leading', 'TEXT', '0');
  for (const node of leadingLabels) bindTextProp(node, leadingProp);
  const showTrailing = defineProp(set, 'Show trailing', 'BOOLEAN', true);
  for (const node of trailingHolders) bindVisibleProp(node, showTrailing);
  const trailingProp = defineProp(set, 'Trailing', 'TEXT', '100');
  for (const node of trailingLabels) bindTextProp(node, trailingProp);
  const focusProp = defineProp(set, 'Focus', 'BOOLEAN', false);
  for (const ring of rings) bindVisibleProp(ring, focusProp);
  rowSet(set);
  return set;
}

// ─── StarRating ──────────────────────────────────────────────────────────────
//
// Data-driven from coui_core STAR_RATING.fields (activeColor, backgroundColor,
// the disabled pair, valueGapStyle, focusOutlineStyle) and
// STAR_RATING.sizes.defaultsBySize (starSize, starSpacing, valueStyle,
// countStyle per size). `star_rating.dart` draws one `Star` per index in
// `filled` / `half` / `empty`; here each star is the same glyph, the three
// states being what is painted — filled in `activeColor`, empty in
// `backgroundColor` (a FILLED glyph, not an outline), and a half star as the
// empty glyph with the filled one clipped to its leading half over it.
//
// Axes — `Size` over the four sizes `defaultsBySize` states, and `Enabled`, the
// schema's own. `Enabled=false` swaps BOTH colours (`disabledActiveColor`,
// `disabledBackgroundColor`) and the value / count ink
// (`constants.disabledTextColor`), exactly as `resolveStarRating` does.
//
// Properties — `Show value` / `Value` and `Show count` / `Count` (the optional
// "4.5" and "(128)" beside the stars, `showValue` / `showCount` / `count`), and
// a `Show focus ring` BOOLEAN for the ONE ring around the whole group (`FocusOutline`
// wraps the stars and the text; a ring per star is gone).
//
// The stars show 3.5 of 5 — three filled, one half, one empty — the example the
// design copy draws. `animationDuration` is rendered nowhere: a transition has
// no resting pose to draw.
function buildStarRating(page: PageNode, lk: VarLookup): ComponentSetNode {
  const sizeData = new Map(Object.entries(STAR_RATING.sizes.defaultsBySize));
  const combos = enumerateAxisCombos(
    axisSpecsOf({
      ...STAR_RATING.axes,
      size: { ...STAR_RATING.axes.size!, members: [...sizeData.keys()] },
    }),
  );
  const mount = mountSet(page, 'StarRating', combos, {
    adoptLooseAs: 'Size=lg, Enabled=true',
  });
  const valueLabels: TextNode[] = [];
  const countLabels: TextNode[] = [];
  const rings: FocusRingNodes[] = [];
  for (const comboName of combos) {
    const combo = parseVariantKey(comboName);
    const disabled = combo['Enabled'] === 'false';
    const row = sizeData.get(combo['Size']);
    if (!row) throw new Error(`StarRating: no size row for combo "${comboName}"`);
    const active = colorData(
      disabled ? STAR_RATING.fields.disabledActiveColor : STAR_RATING.fields.activeColor,
    );
    const inactive = colorData(
      disabled ? STAR_RATING.fields.disabledBackgroundColor : STAR_RATING.fields.backgroundColor,
    );
    const textInk = disabled ? colorData(STAR_RATING.constants.disabledTextColor) : null;
    const c = mount.getOrCreate(comboName);
    applyPanelCompChrome(c, 'HORIZONTAL', lk, { gap: STAR_RATING.fields.valueGapStyle.size });
    c.counterAxisAlignItems = 'CENTER';
    const side = dimVal(row.starSize);
    const starsRow = autoFrame('stars', 'HORIZONTAL');
    starsRow.counterAxisAlignItems = 'CENTER';
    bindSpaceField(starsRow, 'itemSpacing', lk, dimVal(row.starSpacing));
    for (let i = 0; i < 5; i++) {
      // 3.5 of 5: `CoreStarState.forIndex(3.5, i)`.
      const state = i < 3 ? 'filled' : i === 3 ? 'half' : 'empty';
      const star = figma.createFrame();
      star.name = `star ${i + 1}`;
      star.layoutMode = 'NONE';
      star.clipsContent = false;
      star.fills = [];
      star.resize(side, side);
      // The same `star` glyph in every state — the state is what is painted
      // inside it. `fill: true` asks `repaintGlyph` to ADD a fill, because Lucide
      // authors the star with `fill="none"` and there is nothing to recolour.
      const base = makeIcon('star', lk, {
        ...glyphOpts(lk, state === 'filled' ? active : inactive, row.starSize),
        fill: true,
      });
      star.appendChild(base);
      base.x = 0;
      base.y = 0;
      if (state === 'half') {
        // The filled glyph over the empty one, clipped to the leading half
        // (`Star` fills the left half, the lower half when vertical).
        const half = figma.createFrame();
        half.name = 'half';
        half.layoutMode = 'NONE';
        half.fills = [];
        half.clipsContent = true;
        half.resize(side / kHalf, side);
        const filled = makeIcon('star', lk, {
          ...glyphOpts(lk, active, row.starSize),
          fill: true,
        });
        half.appendChild(filled);
        filled.x = 0;
        filled.y = 0;
        star.appendChild(half);
        half.x = 0;
        half.y = 0;
      }
      starsRow.appendChild(star);
    }
    c.appendChild(starsRow);
    const valueStyle = textStyleData(row.valueStyle);
    const countStyle = textStyleData(row.countStyle);
    const value = makeLabel(
      kStarRatingValue,
      lk,
      textLabelOpts(lk, textInk ? { ...valueStyle, color: textInk } : valueStyle),
    );
    value.name = 'value';
    value.visible = false;
    c.appendChild(value);
    valueLabels.push(value);
    const count = makeLabel(
      kStarRatingCount,
      lk,
      textLabelOpts(lk, textInk ? { ...countStyle, color: textInk } : countStyle),
    );
    count.name = 'count';
    count.visible = false;
    c.appendChild(count);
    countLabels.push(count);
    // ONE ring around the whole group: `FocusOutline(child: <stars + text>)`.
    // Measured from the component's own box as it hugs the visible stars; it
    // follows a resize by STRETCH pins.
    rings.push(
      focusRing(c, lk, {
        outline: STAR_RATING.fields.focusOutlineStyle,
        color: focusOutlineRingColor(STAR_RATING.fields.focusOutlineStyle),
        corner: null,
        width: c.width,
        height: c.height,
        visible: false,
      }),
    );
  }
  const set = mount.finish();
  // On the SET, after `finish()`: a fresh variant has no parent until
  // `combineAsVariants` runs, so the property would scatter per member.
  const showValue = defineProp(set, 'Show value', 'BOOLEAN', false);
  const valueProp = defineProp(set, 'Value', 'TEXT', kStarRatingValue);
  for (const n of valueLabels) {
    bindVisibleProp(n, showValue);
    bindTextProp(n, valueProp);
  }
  const showCount = defineProp(set, 'Show count', 'BOOLEAN', false);
  const countProp = defineProp(set, 'Count', 'TEXT', kStarRatingCount);
  for (const n of countLabels) {
    bindVisibleProp(n, showCount);
    bindTextProp(n, countProp);
  }
  const showFocusId = defineShowFocusRing(set);
  for (const ring of rings) bindShowFocusRing(ring, showFocusId);
  // g7-preview-only: gallery width of the StarRating variant grid — a COMPONENT_SET is a Figma-only container of variants, with no counterpart anywhere in the code.
  layoutSet(set, 560);
  return set;
}

// ─── Stepper (multi-step progress indicator) ─────────────────────────────────
//
// `CoreStepperStyle` is NOT a numeric increment/decrement control — it is a
// multi-step tracker ("Displays a multi-step process with numbered indicators,
// connectors, and step labels", `stepper.dart`). Built as a 3-step tracker in
// both layouts from coui_core STEPPER.fields, one pose per `Enabled` value.
//
// Composition:
//   · Step 1 is COMPLETED, and `stepper.dart` draws a completed indicator as
//     `Icon(LucideIcons.check, iconStyle: style.indicatorIconStyle)` — so it
//     is an `Icon` instance, sized `indicatorSize × iconSizeRatio` and
//     coloured from `indicatorIconStyle.color` (`disabledForegroundColor`
//     while disabled), all from the JSON.
//   · Step 2 is CURRENT and step 3 UPCOMING. A completed circle is filled
//     (`indicatorActiveColor`, `indicatorDisabledColor` while disabled) and
//     wears no ring. The current circle is the `surface`
//     (`indicatorCurrentColor`) inside a ring (`indicatorCurrentBorderColor`,
//     `indicatorDisabledBorderColor` while disabled) of `indicatorBorderWidth`,
//     its number in `indicatorNumberActiveStyle`; an upcoming circle is the
//     `surface` (`indicatorInactiveColor`) inside the quieter ring
//     (`indicatorInactiveBorderColor`, the same disabled ring while disabled)
//     — the rings the resolvers draw whatever the caller states.
//   · Each connector is `Divider(dividerStyle: connector{Active,Inactive}
//     DividerStyle)` in both orientations — a `Divider` INSTANCE, whose line the
//     per-step colour and `connectorThickness` recolour. A disabled stepper
//     draws every segment in `connectorDisabledColor`.
//   · The horizontal label sits in a `Stacks` holding invisible copies in both
//     the current and the reached typography, so the weight toggle repaints in
//     place instead of shifting every later indicator. Drawn as the same stack.
//     An upcoming label reads in `labelUpcomingStyle`'s colour.
//
// ─── Sizing follows the widget ──────────────────────────────────────────────
//
// The horizontal widget is a row that fills the width it is given
// (`_HorizontalStepRow`): every step is a column of the same width — an equal
// share of the row — holding a track (half-line · circle · half-line) over its
// label. The connector between two steps is the trailing half of one and the
// leading half of the next, so the two meet at the column boundary; the first
// step's leading half and the last step's trailing half draw nothing (opacity
// 0) but keep their width, which centres the circle in its column. So the set
// draws the row at a stated width, each step column is FILL, the track FILL,
// each half-line lane FILL — and the connector instance inside it FILL too,
// because a FILL child under a HUG parent makes Figma size the parent from
// that one child. The vertical widget is a `Row` per step: an indicator column
// (the circle, then the connector `Expanded` between `connectorMarginVertical`
// margins) beside the content, so the column is a FILL-height child of the step
// and the connector a FILL-height child of the column — the line is whatever the
// content leaves, never a length this file states.
//
// ─── Spacing, and which field says it ───────────────────────────────────────
//
//   · horizontal: the row has no gap (the columns share it), a track's gap is
//     `connectorMargin` (the margin between a circle and each half-line beside
//     it), a step's circle↔label gap is `labelGapStyle`.
//   · vertical: the circle↔connector↔next-circle margins are
//     `connectorMarginVertical` (the column's gap, and the padding under a
//     non-last connector), the indicator↔content gap is
//     `indicatorContentGapStyle`, the room under a non-last step's content is
//     `stepPadding`.
//   · both: the label↔description gap is `descriptionGapStyle`.
//
// Axis — `Enabled`, from the contract's `bool? get enabled`. A disabled stepper
// is not a dimmed one: the widget drops the `Clickable` (whose disabled opacity
// would dim it twice) and the resolvers hand every circle, line and word its
// disabled colour, so the member reads those fields and sets no opacity.

// The width a horizontal stepper is drawn at.
// g7-preview-only: the real row fills the width its host gives it, which has no Style default behind it.
const kStepperPreviewWidth = 400;

// The connector instance's initial length, replaced by FILL once it is placed.
// g7-preview-only: the lane/column the connector sits in states the length; this only seeds the instance.
const kStepperConnectorSeed = 40;

function buildStepper(page: PageNode, lk: VarLookup): ComponentSetNode {
  // NOT composed: `Clickable`. `stepper.dart` wraps every navigable indicator in one, and
  // `Clickable` is a wrapper with no chrome of its own at rest — its Figma
  // component is a focus ring around a demo slot, and an instance takes no
  // appended children, so there is nothing to put the circle inside.
  const f = STEPPER.fields;
  const indicatorSize = f.indicatorSize;
  const labelGap = f.labelGapStyle.size;
  // Two label roles, one per orientation, and the resolver picks by it:
  // `orientation == .vertical ? defaultLabelVerticalStyle.merge(...) :
  // defaultLabelHorizontalStyle.merge(...)`. A reached label is the role, the
  // current one adds `labelActiveStyle`, an upcoming one `labelUpcomingStyle`.
  const labelH = textStyleData(f.labelHorizontalStyle);
  const labelV = textStyleData(f.labelVerticalStyle);
  const labelActiveOverlay = textStyleData(f.labelActiveStyle);
  const labelUpcomingOverlay = textStyleData(f.labelUpcomingStyle);
  const activeNumber = textStyleData(f.indicatorNumberActiveStyle);
  const inactiveNumber = textStyleData(f.indicatorNumberInactiveStyle);
  const descriptionText = textStyleData(f.descriptionStyle);
  const checkSize = dimVal(indicatorSize) * dimVal(f.iconSizeRatio);
  const connectorThickness = dimVal(f.connectorThickness);
  const disabledInk = colorData(f.disabledForegroundColor);
  // `CoreStepItem.description` is optional and `stepper.dart` renders it under the
  // label when present (`Text(item.description!, style: style.descriptionTextStyle)`)
  // — so `descriptionStyle` reaches a node only if a demo step has one. One does,
  // not all three: the field is optional and a column where every step carries the
  // same second line says the description is part of a step rather than a choice.
  const steps = [
    { n: '1', label: '1단계', description: '계정 정보', done: true, current: false, upcoming: false },
    { n: '2', label: '2단계', description: null, done: false, current: true, upcoming: false },
    { n: '3', label: '3단계', description: null, done: false, current: false, upcoming: true },
  ];
  const names: string[] = [];
  for (const layout of kStepperLayouts) {
    for (const enabled of [true, false]) {
      names.push(stepperVariantName(layout, enabled));
    }
  }
  // A loose COMPONENT under this name predates the axes and drew the enabled
  // horizontal tracker, so it is adopted as that combination rather than left
  // beside the new set as a silent duplicate — `mountSet`'s `adoptLooseAs`
  // renames it in place and its key survives. (A page that already carries the
  // SET is untouched by this: adoption only fires when no set exists, and the
  // `VARIANT_RENAMES` rows migrate that page's members instead.)
  const mount = mountSet(page, 'Stepper', names, {
    adoptLooseAs: stepperVariantName('horizontal', true),
  });
  for (const layout of kStepperLayouts) {
  const vertical = layout === 'vertical';
  const label = vertical ? labelV : labelH;
  const labelActive = mergeTextStyleData(label, labelActiveOverlay);
  const labelUpcoming = mergeTextStyleData(label, labelUpcomingOverlay);
  for (const enabled of [true, false]) {
    const c = mount.getOrCreate(stepperVariantName(layout, enabled));
    // `_buildVertical` stacks the steps and `_buildHorizontal` lays them in a
    // row; each step's own cell then runs the other way, indicator beside the
    // label rather than above it.
    c.layoutMode = vertical ? 'VERTICAL' : 'HORIZONTAL';
    c.primaryAxisSizingMode = 'AUTO';
    c.counterAxisSizingMode = 'AUTO';
    // Both layouts start their children at the cross-axis origin, which is what
    // the widget's two roots say (`Row(crossAxisAlignment: .start)` /
    // `Column(crossAxisAlignment: .stretch)`). The offset that DOES belong to the
    // connector is its own, below.
    c.counterAxisAlignItems = 'MIN';
    c.fills = [];
    // The vertical row's margins live inside each indicator column, and the
    // horizontal row's inside each track, so the steps butt against one
    // another either way.
    c.itemSpacing = 0;
    if (!vertical) lockWidth(c, kStepperPreviewWidth);
    const currentIndex = steps.findIndex((step) => step.current);
    // The ink of a disabled pose: one colour over every word, number and glyph.
    const inked = <T extends { color: ColorData | null }>(ts: T): T =>
      enabled ? ts : { ...ts, color: disabledInk };
    const connectorColorFor = (done: boolean): ColorData | null =>
      colorData(
        !enabled
          ? f.connectorDisabledColor
          : done
            ? f.connectorActiveColor
            : f.connectorInactiveColor,
      );
    for (let i = 0; i < steps.length; i++) {
      const s = steps[i];
      const last = i === steps.length - 1;
      const cell = autoFrame('step', vertical ? 'HORIZONTAL' : 'VERTICAL');
      cell.counterAxisAlignItems = vertical ? 'MIN' : 'CENTER';
      // The circle↔content gap, and WHICH field it is depends on the layout: the
      // horizontal orientation spends `labelGapStyle` and the vertical one spends
      // `indicatorContentGapStyle`.
      cell.setBoundVariable(
        'itemSpacing',
        lk.space(dimVal(vertical ? f.indicatorContentGapStyle.size : labelGap)),
      );
      // `CoreStepperStyle.indicatorBorderRadius` — both platforms shape the
      // indicator as a literal circle by default, but the value is a field, so a
      // caller override reaches this node the same way `indicatorSize` does.
      const circle = indicatorBox(lk, f.indicatorBorderRadius.topLeft, indicatorSize);
      const fillField = s.upcoming
        ? f.indicatorInactiveColor
        : s.current
          ? f.indicatorCurrentColor
          : enabled
            ? f.indicatorActiveColor
            : f.indicatorDisabledColor;
      fillData(circle, lk, colorData(fillField));
      if (s.upcoming || s.current) {
        // The ring a current or upcoming circle always wears — the surface
        // alone would vanish on a surface background; the current one's is
        // the primary, the upcoming one's the quieter outline. Inside the
        // box, as the widget's border-box is, so the circle stays
        // `indicatorSize`.
        const ringField = s.current ? f.indicatorCurrentBorderColor : f.indicatorInactiveBorderColor;
        borderData(
          circle,
          lk,
          colorData(enabled ? ringField : f.indicatorDisabledBorderColor),
          f.indicatorBorderWidth,
        );
      }
      if (s.done) {
        circle.appendChild(
          makeIcon(
            'check',
            lk,
            glyphOpts(
              lk,
              colorData(enabled ? f.indicatorIconStyle.color : f.disabledForegroundColor),
              checkSize,
              'size',
            ),
          ),
        );
      } else {
        const num = makeLabel(
          s.n,
          lk,
          textLabelOpts(lk, inked(s.current ? activeNumber : inactiveNumber)),
        );
        circle.appendChild(num);
        num.layoutSizingHorizontal = 'HUG';
        num.layoutSizingVertical = 'HUG';
      }
      // The widget reserves width for the current AND the reached label styles,
      // so the column keeps its width as the current step moves; the live label
      // takes the style of the step's own state.
      const liveLabel = inked(s.current ? labelActive : s.upcoming ? labelUpcoming : label);
      const content = autoFrame('content', 'VERTICAL');
      // The label↔description gap — `descriptionGapStyle`, the `Gap` the widget
      // puts between the two `Text`s.
      content.setBoundVariable('itemSpacing', lk.space(dimVal(f.descriptionGapStyle.size)));
      const labelFrame = labelStack(lk, s.label, [inked(labelActive), inked(label)], liveLabel);
      content.appendChild(labelFrame);
      if (s.description != null) {
        content.appendChild(makeLabel(s.description, lk, textLabelOpts(lk, inked(descriptionText))));
      }
      if (vertical) {
        // `Expanded(child: Padding(padding: i < last ? style.stepPadding :
        // EdgeInsets.zero, child: Column[label, description]))` — the room under
        // a step's content, on every step but the last, which is the gap the next
        // step's label is measured from. A wrapper rather than an inset on `cell`,
        // because `cell` also holds the indicator and the widget's `Padding` does
        // not.
        if (!last) bindPad(content, lk, f.stepPadding);
        // `Column[circle, Expanded(Padding(vertical: connectorMarginVertical,
        // Divider))]`: the circle, then a connector that takes what the content
        // leaves, between the two margins. The last step has no connector.
        const column = autoFrame('indicator', 'VERTICAL');
        column.counterAxisAlignItems = 'CENTER';
        column.setBoundVariable('itemSpacing', lk.space(dimVal(f.connectorMarginVertical)));
        column.appendChild(circle);
        if (!last) {
          // The margin under the connector, the one the column's gap cannot say:
          // the gap sits between children, this sits after the last one.
          column.setBoundVariable('paddingBottom', lk.space(dimVal(f.connectorMarginVertical)));
          const connector = hostedDivider(page, lk, null, {
            vertical: true,
            color: connectorColorFor(s.done),
            size: { length: kStepperConnectorSeed, thickness: f.connectorThickness },
          });
          connector.name = 'connector';
          column.appendChild(connector);
          connector.layoutSizingVertical = 'FILL';
          // `ConstrainedBox(constraints: BoxConstraints(minHeight:
          // style.connectorMinExtent))` — the floor under a segment that is
          // otherwise `Expanded`, so a designer who shortens the step stops where
          // the widget stops instead of collapsing the connector to nothing.
          const minExtent = dimVal(f.connectorMinExtent);
          connector.minHeight = minExtent;
          connector.setBoundVariable('minHeight', lk.spaceLadder(minExtent));
        }
        // The fixture titles are single-line. Read the final visible text,
        // not a token product or the hidden state-sizer frame's height.
        const visibleLabel = labelFrame.children.find(
          (node): node is TextNode => node.type === 'TEXT' && node.visible !== false,
        )!;
        const alignment = autoFrame('content alignment', 'VERTICAL');
        alignment.paddingTop = Math.max(0, (circle.height - visibleLabel.height) / kHalf);
        // Keep every authored padding binding on content; this outer inset is
        // derived geometry. Like labelStack, it is recomputed at Generate,
        // not a new live font/diameter override mechanism on instances.
        alignment.appendChild(content);
        cell.appendChild(column);
        cell.appendChild(alignment);
        c.appendChild(cell);
        // After the cell is in its parent: FILL is refused on a node with no
        // auto-layout parent, and the column stretches to the content's height.
        column.layoutSizingVertical = 'FILL';
        continue;
      }
      // The label sits centred under the circle (`textAlign: .center`) — the
      // node's alignment, not the column's, so a wrapped label centres per line.
      for (const node of [...labelFrame.children, ...content.children]) {
        if (node.type === 'TEXT') node.textAlignHorizontal = 'CENTER';
      }
      // The label's own frame is as wide as its text, and a description under it
      // can be wider. Across the column the default is MIN, which leaves the
      // title against the description's left edge instead of under the circle;
      // CENTER puts the title on the same centre line as the circle and the
      // description. (A step with no description is as wide as its title, so
      // nothing moves there.)
      content.counterAxisAlignItems = 'CENTER';
      // `Column[track, Gap, label]`: the track is `Row[Expanded(half-line),
      // circle, Expanded(half-line)]`. The connector between two steps is the
      // trailing half of one and the leading half of the next, so the line that
      // reaches this step is completed once the current step is this one or
      // later, and the one that leaves it once the current step is past it. The
      // first step's leading half and the last step's trailing half have no
      // step beyond them: `_buildConnectorHalf(visible: false)` draws nothing
      // and keeps the band, which is what centres the circle — here opacity 0.
      const track = autoFrame('track', 'HORIZONTAL');
      // `connectorMargin` — the margin between the circle and each half-line.
      track.setBoundVariable('itemSpacing', lk.space(dimVal(f.connectorMargin)));
      const halves: { lane: FrameNode; connector: ReturnType<typeof hostedDivider> }[] = [];
      for (const [name, done, visible] of [
        ['connector-start', i <= currentIndex, i > 0],
        ['connector-end', i < currentIndex, !last],
      ] as const) {
        // A band the height of the circle with the line centred in it — a lane
        // whose leading inset is half the circle, so the line lands on the
        // circle's centre line.
        //
        // Set, not bound: `indicatorSize / 2` is arithmetic on a stated field, not
        // a step on the space ladder, and binding it would claim a token the data
        // does not name for this.
        const lane = autoFrame(name, 'HORIZONTAL');
        lane.paddingTop = dimVal(indicatorSize) / kHalf;
        const connector = hostedDivider(page, lk, null, {
          vertical: false,
          color: connectorColorFor(done),
          size: { length: kStepperConnectorSeed, thickness: f.connectorThickness },
        });
        connector.name = 'connector';
        lane.appendChild(connector);
        if (!visible) lane.opacity = 0;
        halves.push({ lane, connector });
      }
      track.appendChild(halves[0].lane);
      track.appendChild(circle);
      track.appendChild(halves[1].lane);
      cell.appendChild(track);
      cell.appendChild(content);
      c.appendChild(cell);
      // Every level FILL, outermost first: the row's width goes to the equal
      // step columns, a column's to its track, the track's to the half-lines,
      // and the instance fills its lane. A FILL instance under a HUG lane would
      // make Figma size the lane from that one child.
      cell.layoutSizingHorizontal = 'FILL';
      track.layoutSizingHorizontal = 'FILL';
      for (const { lane, connector } of halves) {
        lane.layoutSizingHorizontal = 'FILL';
        connector.layoutSizingHorizontal = 'FILL';
      }
    }
  }
  }
  const set = mount.finish();
  vStackSet(set);
  return set;
}

// ─── Fab (floating action button) ────────────────────────────────────────────
//
// `fab.dart` composes the unified components below, and each arrives as an
// INSTANCE (`needs: ['Icon', 'Button', 'Tooltip', 'MenuItem', 'Popup']`).
//
//   · the main circle is `Button(variant: .primary, buttonStyle:
//     resolved.buttonStyle, child: trigger)` — a `Button` INSTANCE, so the
//     fill and the foreground come from Button's own `primary` variant rather
//     than from this file reaching into Button's defaults table, and the
//     9999 radius is applied on top because that IS the override
//     `buttonStyle.borderRadius` carries. The trigger / close glyph rides
//     over the instance (see `glyphOverButton`).
//   · each speed-dial action is a `MenuItem` INSTANCE — `_FabMenu` returns
//     `MenuItem(size: CoreFabContract.actionItemSize, leading: action.icon,
//     label: action.label, menuItemStyle: resolved.actionItemStyle)`, the
//     same row every menu draws. It is drawn at that size (`lg`, the 48 touch
//     row) and its insets, gap, icon and label role are `MenuItem`'s own
//     ladder. The one divergence `actionItemStyle` states is the corner: a
//     row the card hosts is the card's 12 minus its 4 inset (8), not the lg
//     row's own 12 the issue's spec drew — a hosted row's corner is derived
//     from the panel so the inner never rounds past the outer. Pinned the
//     way `Menu` and `Select` pin theirs.
//   · the rows sit in a `Popup` INSTANCE, the visible menu card, and that card
//     is the Fab's OWN: `popupStyle` is no longer Menu's panel, so the surface
//     is written onto the instance from the contract — fill, border, corner,
//     elevation — rather than left at the `Popup` set's defaults. The floor and
//     ceiling of its width are bound to `layout/160` and `layout/280`.
//   · `_buildMainFab` wraps the circle in a `Tooltip` when `tooltip` is set,
//     so one `Tooltip` INSTANCE rides along — first in the column, hidden,
//     behind a `Tooltip` BOOLEAN. Hidden because a tooltip is revealed on
//     hover and the resting canvas has none; first because that is where a
//     tooltip above its trigger lands. Auto-layout skips invisible children
//     entirely, so the resting FAB is unchanged.
//
// `Popover` is not drawn. The widget hosts the menu in `Popover(trigger:
// mainFab, content: _FabMenu(…))`, and that host is a wrapper: it wraps the
// circle, so no instance can stand in its place (Figma reparents nothing into
// an instance), and `defaultPopoverStyle` makes it paint nothing — transparent
// fill and border, zero width — because the visible box is the `Popup` above.
// A hidden instance of it only ever added an empty second trigger and panel to
// the layer tree. The panel the host would open is the card drawn here.
//
// The card aligns to the FAB's END edge (`expandDirection` up / down place it
// `topEnd` / `bottomEnd`), so an open member's column is end-aligned: the
// panel's right edge meets the circle's right edge, `spacing` apart. A closed
// member has nothing wider than the circle, and keeps the centred column a
// shown `Tooltip` is laid over.
//
// Axis — `Open`, the contract's own `bool get open`. `_buildMainFab` reads
// `showClose ? (closeIcon ?? Icon(LucideIcons.x)) : trigger`, so the two
// glyphs are mutually EXCLUSIVE. That is why `closeIcon` (`W?`) is an axis
// value rather than a BOOLEAN visibility property: two boolean-gated nodes
// living in the same auto-layout row would let a designer switch both on and
// render a FAB with a ✕ next to a +, a state the widget has no path to, and
// Figma cannot express "exactly one of these two properties". `Open=true`
// draws the close glyph as a real `Icon` instance — `fab.dart`'s own fallback
// for that slot is `Icon(LucideIcons.x)` — and shows the action panel, which
// is the state that panel exists in.
//
// Both glyph slots are real `Icon` instances, so both are INSTANCE_SWAP —
// `Trigger` defaulting to `plus`, `CloseIcon` to `x`, each named for the
// contract slot it IS. That is what a slot typed `W` means: any widget goes
// there, and in Figma any component does.
//
// Neither gets a BOOLEAN. `trigger` is required, so it is never absent; and
// `closeIcon` being null does not hide anything — `_buildMainFab` reads
// `widget.closeIcon ?? const Icon(LucideIcons.x)`, so null renders the `x`
// this property already defaults to. A visibility toggle would offer an empty
// FAB circle, which is a state the widget has no path to.
//
// Axis — `State`. FAB states no state chrome of its own: `CoreFabStyle` is
// nested `buttonStyle` / `actionButtonStyle` plus dimensions and the label
// row, and `resolveFab` reads no state at all — it raw-forwards `buttonStyle`
// into `Button(variant: .primary, …)`, which is the node the pointer lands on.
// So the ladder here IS the composed primary Button's ladder, and each member
// composes the Button member of that State plus FAB's own glyph tint. The
// values are Button's rungs minus `selected`: Fab passes no statesController
// and no ambient `WidgetStatesData`, and primary does not opt into
// `useSelectedState`, so that rung would render as rest under a name that
// promised more.
//
// Sparse on purpose, the way `Clickable` is (primitives-behaviour.ts): an open
// speed dial needs actions (`showClose = _hasActions && _isOpen`), and with
// actions the main circle's `onPressed` is always the toggle, so Button's
// `enabled = widget.enabled ?? (onPressed != null)` cannot be false while open.
// `Open=true × State=disabled` is not a state the app can be in; a member for
// it would be a pose invented on the canvas. Figma flags the three absent
// combinations, and that notice is the accurate one.
//
// `State=pressed` shows the Button set's pressed member — the resolver's
// `pressed` branch. `button.dart` never puts `WidgetState.pressed` into the
// set it resolves against (`_pressed` only feeds `engaged`), so the running
// app paints a held FAB as hover plus `Clickable`'s press scale. That gap is
// Button's, not this composer's; inventing a Fab-side pressed look on top of
// it would make two pictures where the app has one.
//
// FAB states no typography role of its own: the action labels are the
// `MenuItem`'s (`labelXl` at `lg`), drawn in the `Open=true` members — the only
// state the menu exists in on both sides (`_FabActionPanelState` records that
// "The panel mounts only while the popover is open"). The canvas readback
// samples `membersOf(set)[0]` — `Size=mini, State=enabled, Open=false` — whose
// every text node belongs to a composed child instead (the hidden `Tooltip`, the
// `Button` circle, each at that child's own size). Nothing here passes a literal
// size; drawing the speed dial in the closed state to satisfy that sample would
// claim a state the widget never paints.
//
// The rungs, in the order a designer reads them — Button's minus `selected`
// (header). `disabled` last, for the reason `form.ts` gives.
const kFabStates = stateAxis(['enabled', 'hover', 'focus', 'pressed', 'disabled']);

// `CoreFabSize.toExtendedButtonSize()`, on the canvas. The Extended pill takes
// the `Button` member whose height matches the FAB's diameter, so the label
// role comes from that member rather than from a size FAB states itself — the
// enum's own doc says why: a pill and a Button of the same height must not
// answer differently.
const kFabExtendedSizes: Record<string, string> = {
  mini: 'lg',
  regular: 'xl',
  large: 'xl2',
};

type FabState = (typeof kFabStates)[number];

// The rows the open menu shows — the actions a "create new" entry point
// opens: add an event, attach a file, upload a photo, write. Four, inside the
// two-to-six range Material 3 gives a FAB menu (two is not worth opening a
// menu for, and six reaches halfway up a phone). The most-used row, writing,
// is last: the panel opens upward, so it lands next to the circle, where the
// thumb already is.
//
// The glyphs are the ones the redesign names for these rows, and each is in the
// library index (`src/data/icon-keys.json`): a name outside it cannot be
// imported, and the entry would stop half drawn.
const kFabExampleRows = [
  { label: '일정 추가', icon: 'calendar-plus' },
  { label: '파일 첨부', icon: 'paperclip' },
  { label: '사진 올리기', icon: 'image' },
  { label: '글쓰기', icon: 'pencil' },
] as const;

async function buildFab(page: PageNode, lk: VarLookup): Promise<ComponentSetNode> {
  const primary = COMPONENTS.button.variants.defaultsByVariant.primary;
  const popupStyle = FAB.fields.popupStyle;
  const sizes = FAB.sizes.defaultsBySize;
  // All three axes are declared here: `axisSpecsOf(FAB.axes)` is empty (the
  // schema promotes nothing for fab — `CoreFabSize` sits in `other`), `State`
  // is the composed Button's ladder (header), `Open` is the contract's own
  // bool. Enumerated ONCE and read back from `.values` in the loop, so the
  // list `mountSet` is handed and the members the loop draws cannot diverge.
  // The filter is the sparse pair the header explains: no actions means no
  // open panel, and actions mean the toggle is always wired.
  const combos = enumerateAxisAssignments([
    { axis: 'Size', values: Object.keys(sizes) },
    { axis: 'State', values: [...kFabStates] },
    { axis: 'Open', values: ['false', 'true'] },
    { axis: 'Extended', values: ['false', 'true'] },
  ]).filter(
    (c) =>
      !(c.values['Open'] === 'true' && c.values['State'] === 'disabled') &&
      // `label != null && !_hasActions` — the widget asserts the two apart, so
      // an open speed dial has no Extended pose to draw.
      !(c.values['Open'] === 'true' && c.values['Extended'] === 'true'),
  );
  // The circle's glyphs are drawn from their swap defaults, so the properties'
  // first binds leave them at `iconStyle.size` (see `IconOpts.fromVariant`).
  const triggerSwap = iconSwapDefault(page, 'Fab', 'Trigger', iconMainId(page));
  const closeSwap = iconSwapDefault(page, 'Fab', 'CloseIcon', iconMainId(page));
  const mount = mountSet(page, 'Fab', combos.map((c) => c.name));
  const tooltips: InstanceNode[] = [];
  const triggerGlyphs: InstanceNode[] = [];
  const closeGlyphs: InstanceNode[] = [];
  const pills: InstanceNode[] = [];
  for (const combo of combos) {
    const zn = combo.values['Size'];
    const sz = sizes[zn as keyof typeof sizes];
    const ext = sz.extendedButtonStyle;
    const open = combo.values['Open'] === 'true';
    const extended = combo.values['Extended'] === 'true';
    const state = combo.values['State'] as FabState;
    const c = mount.getOrCreate(combo.name);
    applyPanelCompChrome(c, 'VERTICAL', lk, { gap: FAB.fields.spacing });
    // An open member is end-aligned (the header says why); a closed one has
    // nothing wider than the circle, so the shown `Tooltip` stays centred on it.
    c.counterAxisAlignItems = open ? 'MAX' : 'CENTER';

    const tip = instanceOf(page, 'Tooltip');
    tip.name = 'tooltip';
    c.appendChild(tip);
    tip.visible = false;
    tooltips.push(tip);

    if (open) {
      // The menu — `_FabMenu` / `_buildMenu`: a `Popup` card holding one
      // `MenuItem` row per action. Built the way the Menu builder builds its
      // own: the card's inset and row gap are `popupStyle`'s, and the `Popup`
      // instance is the bottom-most child stretched to the frame so every row
      // draws over it.
      const menu = panel('menu', 'VERTICAL', lk, {
        pl: popupStyle.padding.l,
        pr: popupStyle.padding.r,
        pt: popupStyle.padding.t,
        pb: popupStyle.padding.b,
        gap: popupStyle.spacing,
      });
      // Content-driven between a floor and a ceiling — the widget's own rule
      // (`popupStyle.minWidth` / `maxWidth`): the card hugs its widest row, is
      // never narrower than `layout/160`, and stops growing at `layout/280`.
      // Not locked to the floor: a longer label has to widen it.
      bindLayoutBound(menu, lk, 'minWidth', dimVal(popupStyle.minWidth));
      bindLayoutBound(menu, lk, 'maxWidth', boundOrNull(popupStyle.maxWidth));
      // Unclipped, like the Menu set's own panel: the card's cast falls OUTSIDE
      // this frame, and a clipped frame cuts it at its straight edges — the
      // shadow then reads as a square plate behind the round card, so the
      // menu looked angular on the canvas while the app draws a soft cast.
      menu.clipsContent = false;
      // The Fab states the list inset (`popupStyle.padding` = 6, what it opens is
      // a list of actions), so the backdrop is the `Padding=list` member.
      const surface = popupInstance(page, popupStyle.padding);
      const surfacePin = pinAbsolute(menu, surface, 0, 0, {
        horizontal: 'STRETCH',
        vertical: 'STRETCH',
      });
      hidePopupContent(surface);
      // `Popup(popupStyle: resolved.popupStyle)` — the Fab states its own card,
      // so the instance wears it. The `Popup` set still draws its own defaults;
      // what the Fab says over them is written from the contract, not by hand.
      applyForwardedPanelStyle(surface, lk, {
        borderRadius: popupStyle.borderRadius,
        borderWidth: popupStyle.borderWidth,
        backgroundColor: colorData(popupStyle.backgroundColor),
        borderColor: colorData(popupStyle.borderColor),
      });
      setShadow(surface, popupStyle.boxShadow, lk, colorData(popupStyle.shadowBaseColor));
      await linkShadowStyle(surface, popupStyle.boxShadow, `Fab/${combo.name} menu`);
      // The rows are `MenuItem` instances at the size `actionItemSize` names:
      // the row owns its fill, wash, ring, typography and glyph tint, and the
      // Fab only says which of its slots are filled — the label, and the
      // leading glyph (no shortcut: `FabAction` has none, and the set's default
      // shows one). Only text and boolean properties are written; a nested
      // instance's VARIANT property propagates to the whole set, so the pose
      // stays the set's resting one and the poses live on `MenuItem` itself.
      for (const { label, icon } of kFabExampleRows) {
        // The literal, not a constant: the composition-parity gate reads the
        // builder's source for `instanceOf(page, '<Child>')`.
        const row = instanceOf(
          page,
          'MenuItem',
          bestVariantName(page, 'MenuItem', { Size: 'lg', State: 'enabled', Tone: 'neutral' }),
        );
        row.name = label;
        setInstanceTextNamed(row, 'Label', label);
        setInstanceBoolNamed(row, 'Show shortcut', false);
        setInstanceBoolNamed(row, 'Show leading', true);
        // `leading: action.icon` — the row's own leading seat, revealed and
        // handed the action's glyph. The colour is the row's: the action's icon
        // carries no style, so the glyph takes the foreground the row draws it
        // in, written back onto every leaf after the swap.
        const [leadingIcon] = row.findAll(
          (n) => n.type === 'INSTANCE' && n.name === 'leading',
        );
        if (leadingIcon && leadingIcon.type === 'INSTANCE') {
          setIconGlyph(leadingIcon, icon, kPreserveGlyphPaint);
        }
        // `menuItemStyle: resolved.actionItemStyle` — the card states its
        // rows' corner (8, the corner every list row of a panel shares): the lg row's
        // own 12 is not what the app draws. Pinned onto the box,
        // its wash and its ring, so the hosted row is one picture.
        pinComposedCorner(
          row,
          lk,
          FAB.fields.actionItemStyle.borderRadius.topLeft,
          MENU_ITEM.fields.clickableStyle.focusOutlineStyle,
        );
        menu.appendChild(row);
        row.layoutSizingHorizontal = 'FILL';
      }
      // Last, once the rows have settled the frame's size: an absolute child
      // is laid out from its own box, so the surface has to start at the size
      // its STRETCH constraints will then keep it at — the holder's box, through
      // `sizePin` (see `buildMenu` for the same line and why).
      sizePin(surfacePin, menu.width, menu.height);
      c.appendChild(menu);
    }

    // The glyph's colour per rung, mirroring `button_style.dart`'s
    // `buildIconTheme`: Fab's `leadingIconStyle` carries a size and NO colour,
    // so in the app the glyph takes whatever icon theme the composed Button
    // resolves for its state. `focus` falls to rest on purpose — that ladder
    // has no focus branch and primary does not set `useFocusedAsHover`.
    // `pressed` and `hover` fall all the way to `foregroundColor` on primary
    // (no `*IconColor` / `hoverForegroundColor` in its row), which is what the
    // widget renders — the state layer carries the change, not the glyph.
    const glyphFg: Color =
      state === 'disabled'
        ? (optField<Color>(primary, 'disabledIconColor') ?? primary.disabledForegroundColor)
        : state === 'pressed'
          ? (optField<Color>(primary, 'pressedIconColor') ??
            optField<Color>(primary, 'pressedForegroundColor') ??
            optField<Color>(primary, 'hoverIconColor') ??
            optField<Color>(primary, 'hoverForegroundColor') ??
            primary.foregroundColor)
          : state === 'hover'
            ? (optField<Color>(primary, 'hoverIconColor') ??
              optField<Color>(primary, 'hoverForegroundColor') ??
              primary.foregroundColor)
            : (optField<Color>(primary, 'iconColor') ?? primary.foregroundColor);
    const glyph = glyphOpts(lk, colorData(glyphFg), sz.iconStyle.size, 'size');
    if (extended) {
      // Extended — `label != null` makes the circle a pill. Not a second
      // drawing of the same thing: the glyph moves OUT of the overlay this
      // builder stacks over the circle and INTO the composed Button's own
      // `leading` slot, because that is where `fab.dart` puts it
      // (`Button(leading: child, child: label)`). Overlaying a glyph on a pill
      // would put it over the label instead of beside it.
      //
      // The Button member is picked by the height ladder rather than by `md`:
      // `CoreFabSize.toExtendedButtonSize()` maps 48/56/72 to `lg`/`xl`/`xl2`,
      // and the label role rides along with that member. The FAB states no
      // label typography of its own precisely so the pill and a Button of the
      // same height cannot answer differently.
      const pill = restingButton(page, 'primary', kFabExtendedSizes[zn], 'fab', state);
      // Height is the diameter (`copyWith(height: diameter)`), and only the
      // height — `xl2` is 64 where a large FAB is 72, and the width is the
      // label's to decide.
      // Same two-step the `Filter` segments use: `resize` fixes both axes, the
      // width hug is restored on the line after, and the height keeps its
      // token. A pill whose width were fixed here would stop following its
      // label, which is the one thing that makes it a pill and not a circle.
      pill.counterAxisSizingMode = 'FIXED';
      bindAxisSize(pill, lk, {
        width: pill.width,
        height: sz.diameter,
        bind: 'height',
      });
      pill.primaryAxisSizingMode = 'AUTO';
      // Padding and gap are the pair `defaultsBySize` overrides; everything
      // else (fill, radius, cast) is the circle's own forward, below.
      applyForwardedButtonStyle(pill, lk, { padding: ext.padding });
      bindSpaceField(pill, 'itemSpacing', lk, dimVal(ext.iconLabelGapStyle.size));
      bindRadiusN(pill, lk, FAB.fields.buttonStyle.borderRadius.topLeft);
      bindInstanceOverlayRadius(pill, lk, FAB.fields.buttonStyle.borderRadius.topLeft);
      // The band under the ring — the circle's own, below: a FAB floats over
      // content it cannot know, so its `buttonStyle` states an opaque band.
      forwardFocusBand(pill, lk, FAB.fields.buttonStyle.focusOutlineStyle);
      setShadow(pill, FAB.fields.buttonStyle.boxShadow, lk);
      setInstanceBool(pill, 'Show leading', true);
      setInstanceLabel(pill, '새 메모');
      const [leadingIcon] = pill.findAll(
        (n) => n.type === 'INSTANCE' && n.parent?.name === 'leading',
      );
      // In `glyphFg` — the same per-state colour the circle's overlay glyph
      // takes below, so the pill and the circle cannot answer differently.
      if (leadingIcon && leadingIcon.type === 'INSTANCE') {
        setIconGlyph(leadingIcon, 'plus', glyphPaint(lk, glyph));
      }
      c.appendChild(pill);
      // The label text — and the leading glyph beside it — live inside this
      // instance, where the set's own TEXT / INSTANCE_SWAP properties cannot
      // reach. Same shape `DatePicker`'s title has, so the same answer: expose
      // the instance and let the designer edit the Button's own Label and
      // leading one level in. That is also why `Trigger` binds only on the
      // circle members below — on a pill the glyph is not this builder's node.
      //
      // Deferred to after assembly: Figma rejects the flag on an instance with
      // no COMPONENT ancestor.
      pills.push(pill);
    } else {
      // The circle is the Button set's member for this State — fill, state
      // layer and focus ring all come from Button's own ladder, which is the
      // one the app resolves (header). Picked by name rather than written
      // with `setProperties`, for the reason `form.ts` records: the name-pick
      // path is the one the harness can observe.
      const circle = restingButton(page, 'primary', 'md', 'fab', state);
      bindInstanceRadius(circle, lk, FAB.fields.buttonStyle.borderRadius.topLeft);
      // The state layer and focus ring inside that member still carry Button's
      // md corner — bound to the same 9999 the root just took, or they poke out
      // of the circle (see `bindInstanceOverlayRadius`).
      bindInstanceOverlayRadius(circle, lk, FAB.fields.buttonStyle.borderRadius.topLeft);
      // The band under that ring. Button's own default is transparent — the gap
      // shows the page it sits on — but a FAB floats over scrolling content it
      // cannot know, so `buttonStyle.focusOutlineStyle` states an opaque band
      // and the ring reads against it rather than against whatever scrolls by.
      forwardFocusBand(circle, lk, FAB.fields.buttonStyle.focusOutlineStyle);
      // `buttonStyle.boxShadow` (`CoreShadow.lg`, 2 layers) — the whole reason a
      // FAB reads as floating rather than as a circle lying on the page. Same
      // forward as the action buttons above: `Button` paints a composer's
      // `boxShadow`, and this composer's `buttonStyle` is exactly where the 9999
      // radius one line up comes from too.
      //
      // On every rung, unchanged. `Button` hides its cast only where
      // `hasSignatureShadow` — a non-zero `pressedTranslateOffset` — and Fab's
      // `castMotion` is the default, so pressed keeps the shadow; and disabled
      // keeps it too, since Button pins `disabledOpacity` at 1 and paints the
      // disabled fill instead of fading. An opacity drop or a shadow drop here
      // would be chrome the resolver never draws.
      setShadow(circle, FAB.fields.buttonStyle.boxShadow, lk);
      const mark = makeIcon(open ? 'x' : 'plus', lk, {
        ...glyph,
        fromVariant: open ? closeSwap.variant : triggerSwap.variant,
      });
      c.appendChild(
        glyphOverButton(circle, mark, dimVal(sz.diameter), dimVal(sz.iconStyle.size)),
      );
      // `_buildMainFab` picks ONE of the two — `showClose ? closeIcon : trigger`
      // — so each variant binds the slot it actually renders.
      if (open) closeGlyphs.push(mark);
      else triggerGlyphs.push(mark);
    }
  }
  const set = mount.finish();
  // After `finish()`: until `combineAsVariants` runs, a freshly minted variant
  // has no parent, so `propertyOwner` would answer with the member itself and
  // scatter one definition per variant. The nodes are inside their component by
  // now too, which `componentPropertyReferences` requires.
  const tooltipProp = defineProp(set, 'Tooltip', 'BOOLEAN', false);
  for (const tip of tooltips) bindVisibleProp(tip, tooltipProp);
  const triggerProp = defineProp(set, 'Trigger', 'INSTANCE_SWAP', triggerSwap.id);
  for (const mark of triggerGlyphs) bindSwapProp(mark, triggerProp);
  const closeProp = defineProp(set, 'CloseIcon', 'INSTANCE_SWAP', closeSwap.id);
  for (const mark of closeGlyphs) bindSwapProp(mark, closeProp);
  // `label` (`W?`) — the only slot with no host property. Its text lives inside
  // the composed `Button` instance, where a TEXT property on this set cannot
  // reach, so the instance is exposed and the designer edits the Button's own
  // Label one level in. Same mechanism `DatePicker`'s `dialogTitle` uses, and
  // for the same reason.
  exposeAll(pills);
  // g7-preview-only: gallery width of the Fab variant grid — a COMPONENT_SET is a Figma-only container of variants, with no counterpart anywhere in the code.
  layoutSet(set, 560);
  return set;
}

// ─── MultipleChoice (single-select option row) ──────────────────────────────
//
// `multiple_choice.dart` draws no option box of its own: every option is a
// composed `Chip` — neutral · outlined · `Emphasis=low` while it rests, primary ·
// outlined · `Emphasis=low` once chosen (`CoreMultipleChoiceContract`'s
// `defaultSelected/UnselectedChipColor` · `…ChipEmphasis`) — 32 tall (`Chip` `md`, which `CoreMultipleChoiceStyle.defaultChipStyle`
// also states as `minHeight`), `optionSpacing` apart. So the row is a
// HORIZONTAL frame of three `Chip` INSTANCES, and the only value this builder
// owns is the gap between them. The old hand-drawn pill (padding, radius,
// border, fills, label ink read off the group's own flat fields) is gone with
// the box: those fields are deprecated pass-throughs to the chip's own style,
// and a chip change reaches this set through the instance.
//
// Axis — `Enabled` only, the schema's own (`multiple_choice.axes` promotes it),
// by ADOPTION: the enumeration is two combinations and `mountSet`'s
// `adoptLooseAs` renames the loose COMPONENT to `Enabled=true` in place, keeping
// its key. `Enabled=false` picks the `Chip` set's `State=disabled` member for
// every option (a disabled chip wears its own disabled tokens, and a disabled
// selected chip still shows which one was picked) — the widget hands
// `enabled: false` to each chip, nothing more.
//
// There is no `Selected` axis: selection is per *option*, not per component (the
// widget takes `options` + a `value`), and the demo already shows a selected
// option next to unselected ones — a component-level axis would have to mean
// "every option selected", which the widget cannot be.
function buildMultipleChoice(page: PageNode, lk: VarLookup): ComponentSetNode {
  const options = [
    { label: '작음', selected: false },
    { label: '보통', selected: true },
    { label: '큼', selected: false },
  ];
  const combos = enumerateAxisCombos(axisSpecsOf(MULTIPLE_CHOICE.axes));
  const mount = mountSet(page, 'MultipleChoice', combos, {
    adoptLooseAs: 'Enabled=true',
  });
  for (const comboName of combos) {
    const disabled = parseVariantKey(comboName)['Enabled'] === 'false';
    const c = mount.getOrCreate(comboName);
    c.layoutMode = 'HORIZONTAL';
    c.primaryAxisSizingMode = 'AUTO';
    c.counterAxisSizingMode = 'AUTO';
    c.counterAxisAlignItems = 'CENTER';
    c.setBoundVariable('itemSpacing', lk.space(dimVal(MULTIPLE_CHOICE.fields.optionSpacing)));
    c.fills = [];
    for (const o of options) {
      const chip = instanceOf(
        page,
        'Chip',
        // The widget's own call: `Chip(chipColor:, emphasis:, selected:, enabled:)`
        // `chipColor:` — primary when selected, neutral when it rests;
        // `emphasis:` — low either way — the rest is the chip's defaults (`outlined` / `md` /
        // `rounded`), spelled in full because `bestVariantName` only scores and
        // a key the set lacks is silently worth nothing.
        bestVariantName(page, 'Chip', {
          Color: o.selected ? 'primary' : 'neutral',
          Variant: 'outlined',
          Size: 'md',
          State: disabled ? 'disabled' : 'enabled',
          Selected: o.selected ? 'true' : 'false',
          Emphasis: 'low',
          Shape: 'rounded',
        }),
      );
      setInstanceTextNamed(chip, 'Child', o.label);
      c.appendChild(chip);
    }
  }
  const set = mount.finish();
  vStackSet(set);
  return set;
}

// ─── MultiAnswerCard (single selectable card) ────────────────────────────────
//
// `CoreMultiAnswerCardStyle` describes ONE selectable card: a row with the
// caller's answer on the left and a trailing `Checkbox` (`lg`) that shows the
// selection. The card's chrome per state is data — `backgroundColor` ·
// `selectedBackgroundColor` · `hoverColor` · `disabledBackgroundColor`,
// `borderColor` · `selectedBorderColor` · `hoverBorderColor` ·
// `disabledBorderColor` at `borderWidth` / `selectedBorderWidth` (equal, so the
// card never changes height) — plus the body text per state (`bodyTextStyle` ·
// `selectedBodyTextStyle` · `disabledBodyTextStyle`), the gap to the checkbox
// (`checkboxGapStyle`), `padding` and `borderRadius`.
//
// Axes — `Enabled` × `Selected` × `Hover`.
//
// `Enabled` is the schema's own (`multi_answer_card.axes` promotes it). A
// disabled card wears the dedicated disabled fill / border / text tokens — not
// a faded enabled card (`clickableStyle.disabledOpacity` is 1).
//
// `Selected` and `Hover` are POSES: the card's selected VALUE is not one of the
// four axes, so the pose is declared here. The widget's own state select is
// `disabled > selected > hover > idle`, so a hovered or selected disabled card
// still draws the disabled tokens, and hover needs `enabled`; the one
// combination in which `hoverColor` / `hoverBorderColor` reach a node is
// `Enabled=true, Selected=false, Hover=true`.
//
// The trailing `Checkbox` instance follows the card: `Checked` is `Selected`,
// `State` is `Enabled`. The label is hidden — the card's answer text is the label.
// The widget excludes it from pointer, focus and semantics; the canvas only needs
// its picture.
//
// `transitionDuration` is rendered nowhere — a transition has no resting pose to
// draw.
//
// `child` (`W`, required) is the card's content and the builder fills it with
// a text node → TEXT property, named `Child` for the slot it IS. TEXT is the
// ceiling for a slot rendered as words.
function buildMultiAnswerCard(page: PageNode, lk: VarLookup): ComponentSetNode {
  // NOT composed: `Clickable`. `multi_answer_card.dart` wraps the card body in one, and
  // `Clickable` is a wrapper with no chrome of its own at rest — its Figma
  // component is a focus ring around a demo slot, and an instance takes no
  // appended children, so there is nothing to put the card inside.
  const f = MULTI_ANSWER_CARD.fields;
  const pad = f.padding;
  const radius = f.borderRadius.topLeft;
  const combos = enumerateAxisCombos(
    withPoses(axisSpecsOf(MULTI_ANSWER_CARD.axes), 'Selected', 'Hover'),
  );
  const mount = mountSet(page, 'MultiAnswerCard', combos);
  const bodies: TextNode[] = [];
  for (const comboName of combos) {
    const combo = parseVariantKey(comboName);
    const disabled = combo['Enabled'] === 'false';
    const selected = combo['Selected'] === 'true';
    const hovered = combo['Hover'] === 'true';
    const c = mount.getOrCreate(comboName);
    c.layoutMode = 'HORIZONTAL';
    c.primaryAxisSizingMode = 'FIXED';
    c.counterAxisSizingMode = 'AUTO';
    c.primaryAxisAlignItems = 'MIN';
    c.counterAxisAlignItems = 'CENTER';
    bindPad(c, lk, { l: pad.l, r: pad.r, t: pad.t, b: pad.b });
    bindRadiusN(c, lk, radius);
    // `clickableStyle.disabledOpacity` (`opacity100` today): a disabled card wears
    // the dedicated disabled tokens, and the fade is whatever the field states.
    if (disabled) c.opacity = dimVal(f.clickableStyle.disabledOpacity);
    // `Row(children: [Expanded(content), Gap(checkboxGapStyle), Checkbox])`.
    bindSpaceField(c, 'itemSpacing', lk, dimVal(f.checkboxGapStyle.size));
    // The widget's state select: `disabled > selected > hover (needs enabled) > idle`.
    const hoverPose = hovered && !disabled && !selected;
    const fill = disabled
      ? f.disabledBackgroundColor
      : selected
        ? f.selectedBackgroundColor
        : hoverPose
          ? f.hoverColor
          : f.backgroundColor;
    const border = disabled
      ? f.disabledBorderColor
      : selected
        ? f.selectedBorderColor
        : hoverPose
          ? f.hoverBorderColor
          : f.borderColor;
    fillData(c, lk, colorData(fill));
    borderData(c, lk, colorData(border), selected && !disabled ? f.selectedBorderWidth : f.borderWidth);
    const text = disabled ? f.disabledBodyTextStyle : selected ? f.selectedBodyTextStyle : f.bodyTextStyle;
    const body = makeLabel('해당하는 항목을 모두 골라 주세요', lk, textLabelOpts(lk, textStyleData(text)));
    body.textAutoResize = 'HEIGHT';
    c.appendChild(body);
    body.layoutSizingHorizontal = 'FILL';
    body.layoutSizingVertical = 'HUG';
    bodies.push(body);
    // `Checkbox(checked: selected, enabled: enabled, size: lg)` — a picture of the selection.
    // `State`, not `Enabled`: the checkbox's poses live on one enum, and
    // `bestVariantName` scores rather than demands (see `restingButton`).
    const checkbox = instanceOf(
      page,
      'Checkbox',
      bestVariantName(page, 'Checkbox', {
        Size: 'lg',
        State: disabled ? 'disabled' : 'enabled',
        Checked: selected ? 'true' : 'false',
      }),
    );
    checkbox.name = 'checkbox';
    setInstanceBoolNamed(checkbox, 'Show label', false);
    c.appendChild(checkbox);
    // g7-preview-only: the card's width in the gallery — the widget's card fills its parent, and `CoreMultiAnswerCardStyle` has no width field.
    c.resize(320, c.height);
    c.primaryAxisSizingMode = 'FIXED';
    c.counterAxisSizingMode = 'AUTO';
  }
  const set = mount.finish();
  const childProp = defineProp(set, 'Child', 'TEXT', '해당하는 항목을 모두 골라 주세요');
  for (const n of bodies) bindTextProp(n, childProp);
  // g7-preview-only: gallery width of the MultiAnswerCard variant grid — a COMPONENT_SET is a Figma-only container of variants, with no counterpart anywhere in the code.
  layoutSet(set, 700);
  return set;
}

// ─── Filter ──────────────────────────────────────────────────────────────────
//
// Controlled segmented filter: `ToggleGroup` segments (one chosen) + a
// hairline and a reset button after the last one, inside the same track.
// Data-driven from coui_core FILTER.fields: the track and the segments are the
// composed `ToggleGroup`'s, forwarded as `FILTER.fields.toggleGroupStyle`
// (backgroundColor / selectedColor / selectedShadow / padding / borderRadius,
// itemPadding / itemBorderRadius / itemHeight / labelPadding / itemSpacing,
// the per-state icon and label styles, and the disabled fills and ink —
// `selectedLabelTextStyle` carries no `fontWeight` key, so
// `selectedFontWeight`, a standalone Dim field, is combined manually). The
// filter's own fields are `resetButtonStyle`, `dividerStyle`,
// `dividerHeight`, `dividerLeadingSpacing` and `trailingSpacing`.
//
// NOT composed here: `ToggleGroup`. The widget's reset affordance rides the
// group's `trailing` slot INSIDE the track, and an instance takes no appended
// children, so the track and the segments are drawn directly from the same
// data — the group's own set is the picture of that bare shape.
//
// ─── A segment ───────────────────────────────────────────────────────────────
//
// `CoreFilterItem(value:, label:, icon:, showLabel:)` — the label is required
// (it stays the accessible name), the icon is a `W?` slot, and `showLabel`
// hides the label box. Both platforms draw the segment as a fixed-height row,
// vertically centred, inset by `itemPadding` on every side:
//
//   seg (row, height = itemHeight, padding = itemPadding)
//     ├─ icon      // `W?` — hidden, `Show seg N icon` reveals, `Seg N icon` swaps
//     └─ label     // box inset by `labelPadding`, `Show seg N label` hides
//          └─ text // `Seg N label`
//
// The two insets are two fields because only a label segment needs room for
// its words: the label box adds `labelPadding` on each side (2 + 8 + text + 8
// + 2 at `md`, 8 + text + 8 at `sm`). An icon-only segment is a square by the
// segment's minimum width — its height — not by its inset.
//
// The icon slot is SIZED, not hugged, for the reason `form.ts`'s `iconSlot`
// records: a hidden hug holder measures 0×0 and a revealed glyph lands in the
// corner rather than in the row. The box is the icon style's own `size`.
//
// ─── Composition ─────────────────────────────────────────────────────────────
//
//   · The reset affordance is `Button(variant: .ghost, size: .sm, shape:
//     .square, buttonStyle: resolved.resetButtonStyle, child: Icon(LucideIcons.x))`
//     — so it is the `Shape=square` member of `Button`, which draws its
//     `Leading` glyph and no label. The ✕ goes into that slot through the
//     child's own `Leading` INSTANCE_SWAP (`setSlotIcon`), and the forwarded
//     `resetButtonStyle` lands as instance overrides — `width`/`height`,
//     `borderRadius`, and `foregroundColor`/`leadingIconStyle.size` on the
//     glyph (`setSlotIcon`'s paint + `stateSlotGlyphSize`). The square
//     member IS the picture of that button, drawn by the child.
//   · The label box IS the widget's width-reservation `Stacks`: the live label
//     sits in its flow and the invisible selected-typography twin is pinned
//     ABSOLUTE beneath it. Not `labelStack` (a `layoutMode: 'NONE'` frame sized
//     once at build), because the designer's `Seg N label` TEXT property has
//     to re-hug the box when the words change, and a fixed stack cannot. The
//     twin stays because it is the widget's structure — hidden, it reserves
//     nothing on a canvas where selection is an axis, and it follows the same
//     TEXT property so revealing it shows the twin of the current words.
//
// Axes — `Variant` × `Size` × `Enabled` × `Selected`.
//
// `Size` is the schema's own (the contract states `size`, the composed
// group's, handed over as is), drawn at the two rows the group states: `md`
// (40 track) and `sm` (32 track). The segments read the group's row through
// `toggleGroupAtSize`; the reset button height and the hairline length read
// Filter's own `defaultsBySize` (`sm`: 32 × 26, 14 long).
//
// `Variant` is the schema's own and it has exactly one member: `filter.axes`
// declares `segmented`. Its `defaultsByVariant
// .segmented` entry is empty: `segmented` names the only look `CoreFilterStyle`
// declares, and every value below still comes from the flat `fields`. It is
// enumerated anyway rather than dropped for being single-valued, because a
// member's name is its identity and the name the schema gives it is the one
// the rename table and G10 both expect.
//
// `Selected` is a builder-declared axis — which of the four drawn segments is
// current, 1-indexed (one-based because a designer reads the axis in the
// Figma panel). It has to be declared
// rather than derived because the widget states its selection as a VALUE
// (`selected: T`), which no promotion predicate reaches. Multi-valued rather
// than boolean because "which segment" is an index, not a flag. The two
// members the canvas already had are the `Selected=1` rung, renamed in
// `src/renames.ts`.
//
// `Enabled` is the schema's own (`filter.axes.enabled` is true: the contract
// states `enabled`). `Enabled=false` is the composed group's flat look — the
// track takes `disabledBackgroundColor`, the chosen face sinks to
// `disabledSelectedColor` without its shadow, and every label and glyph takes
// the disabled ink — not a dimmed copy of the enabled bar. No `Hover`: the
// spec's `hoverForegroundColor` lives inside `resetButtonStyle`, i.e. it is the
// composed Button's own state, not the filter bar's.
//
// ─── Properties ──────────────────────────────────────────────────────────────
//
// Adopted from the designer's set by name and type (`defineProp` reuses an
// existing property that matches both): `Show reset`, `Show seg 3` / `Show seg
// 4` (the third segment shown, the fourth hidden — a three-segment preview with
// a fourth reachable), and per segment `Seg N label` / `Show seg N label` /
// `Show seg N icon` / `Seg N icon`.

// The segments a member draws, 1-indexed the way the `Selected` axis and the
// designer's `Seg N …` properties count them.
const kFilterSegmentOrdinals = ['1', '2', '3', '4'] as const;

// The label each segment's TEXT property defaults to. The fourth ships hidden —
// it is the designer's slot, not a fourth state.
const kFilterSegmentLabels: readonly string[] = ['전체', '진행 중', '완료', '보관'];

// What a segment's icon slot draws before a designer swaps it. A real Lucide
// name carried by `icons.json`, the same one `Button`'s leading slot rests on.
const kFilterSegmentGlyph = 'check';

// The glyph the reset affordance draws — `Icon(LucideIcons.x)` in both widgets.
const kFilterResetGlyph = 'x';

// The last segment ships hidden: the widget's preview has three, and a fourth
// that a designer can turn on is the property's whole purpose.
const kFilterHiddenSegment = '4';

interface FilterSegmentNodes {
  /** The segment row — what `Show seg 3` / `Show seg 4` hide. */
  seg: FrameNode;
  /** The icon region — what `Show seg N icon` reveals. */
  iconHolder: FrameNode;
  /** The glyph in it — what `Seg N icon` re-points. */
  icon: InstanceNode;
  /** The label box — what `Show seg N label` hides. */
  labelBox: FrameNode;
  /** The label copy — what `Seg N label` replaces. */
  label: TextNode;
  /** The hidden selected-typography twin — follows the same TEXT property. */
  twin: TextNode;
}

interface FilterMemberNodes {
  /** The widget's trailing row — what `Show reset` hides (hairline + button). */
  trailing: FrameNode;
  reset: InstanceNode;
  segments: FilterSegmentNodes[];
}

// The Button size rung whose square (`Shape=square`) glyph is `side` — the
// `iconShapeIconStyle` each size row states. Throws when no rung draws it: a
// size row asking for a glyph no Button rung has would otherwise land on the
// nearest one and draw a glyph the code does not.
function buttonRungForSquareGlyph(side: number): string {
  for (const [rung, row] of Object.entries(BUTTON.sizes.defaultsBySize)) {
    if (Math.abs(dimVal(row.iconShapeIconStyle.size) - side) < 1e-6) return rung;
  }
  throw new Error(`Filter: no Button size rung draws a ${side} square glyph`);
}

async function buildFilter(page: PageNode, lk: VarLookup): Promise<ComponentSetNode> {
  // NOT composed: `Clickable`. `filter.dart` wraps every segment in one, and
  // `Clickable` is a wrapper with no chrome of its own at rest — its Figma
  // component is a focus ring around a demo slot, and an instance takes no
  // appended children, so there is nothing to put the segment inside.
  const f = FILTER.fields.toggleGroupStyle;
  const labelPad = f.labelPadding;
  const itemRadius = f.itemBorderRadius.topLeft;
  const reset = FILTER.fields.resetButtonStyle;
  const divider = FILTER.fields.dividerStyle;
  // Filter's own size rows — the reset button height and the hairline length.
  const filterSizeRows = new Map(Object.entries(FILTER.sizes.defaultsBySize));
  // The Icon variant every `Seg N icon` swap resets to — read once, the way
  // `iconSlotDefaultId` reads it once per set in `form.ts`.
  const iconDefaultId = iconMainId(page);
  // Each segment's glyph is drawn from its own `Seg N icon` default, so the
  // property's first bind leaves it at the icon style's size (see
  // `IconOpts.fromVariant`).
  const segIconSwaps = new Map(
    kFilterSegmentOrdinals.map(
      (ordinal) => [ordinal, iconSwapDefault(page, 'Filter', `Seg ${ordinal} icon`, iconDefaultId)] as const,
    ),
  );
  // The variant the reset ✕ is swapped TO — the step the size row's
  // `resetButtonStyle.leadingIconStyle.size` states (16 at `md`, 14 at `sm`),
  // not the set's default. Read once per step: the style is the component's
  // size row, not the member's.
  const resetIconIds = new Map<number, string>();
  const resetIconIdAt = (side: number): string => {
    let id = resetIconIds.get(side);
    if (id === undefined) {
      id = iconMainIdAt(page, side);
      resetIconIds.set(side, id);
    }
    return id;
  };
  const combos = enumerateAxisCombos([
    ...axisSpecsOf({
      ...FILTER.axes,
      size: { ...FILTER.axes.size!, members: [...filterSizeRows.keys()] },
    }),
    { axis: 'Selected', values: kFilterSegmentOrdinals },
  ]);
  // The loose COMPONENT drew the enabled segmented bar, so it is adopted as the
  // combination that still draws it — both changes in ONE name, the way
  // `src/renames.ts` composes a member rename that gains an axis at the same
  // time. Adopting it as the bare `Variant=segmented` would hand it a name this
  // builder no longer produces.
  const mount = mountSet(page, 'Filter', combos, {
    adoptLooseAs: combos[0],
  });
  const members: FilterMemberNodes[] = [];
  for (const comboName of combos) {
    const combo = parseVariantKey(comboName);
    const enabled = combo['Enabled'] === 'true';
    const selectedOrdinal = combo['Selected'];
    const z = toggleGroupAtSize(f, combo['Size']);
    const pad = z.padding;
    const itemPad = z.itemPadding;
    const itemHeight = z.itemHeight;
    const labelStyle = textStyleData(z.labelTextStyle);
    // The whole selected style with the weight laid over it — the disabled
    // twin's shape. Picking four fields out dropped the role and the tracking
    // with them, and a label drawn with no ratio writes Figma's PERCENT 0: the
    // selected segment came out wider than the code's (−1% of 14px is −0.14).
    const selectedLabelStyle = {
      ...textStyleData(z.selectedLabelTextStyle),
      fontWeight: dimVal(f.selectedFontWeight),
    };
    const disabledLabelStyle = textStyleData(z.disabledLabelTextStyle);
    const disabledSelectedLabelStyle = {
      ...disabledLabelStyle,
      fontWeight: dimVal(f.selectedFontWeight),
    };
    const filterRow = filterSizeRows.get(combo['Size']);
    if (!filterRow) throw new Error(`Filter: no size row for combo "${comboName}"`);
    // The size row's reset statement over the flat `md` one — the resolvers'
    // `defaultResetButtonStyle.merge(sizeRow.resetButtonStyle)`.
    const rowReset = 'resetButtonStyle' in filterRow ? filterRow.resetButtonStyle : null;
    const resetHeight = rowReset?.height ?? reset.height;
    const resetWidth = rowReset?.width ?? reset.width;
    const resetRadius = (rowReset?.borderRadius ?? reset.borderRadius).topLeft;
    const resetGlyphSize = (rowReset?.leadingIconStyle ?? reset.leadingIconStyle).size;
    const dividerHeight =
      'dividerHeight' in filterRow ? filterRow.dividerHeight : FILTER.fields.dividerHeight;
    const c = mount.getOrCreate(comboName);
    c.layoutMode = 'HORIZONTAL';
    c.primaryAxisSizingMode = 'AUTO';
    c.counterAxisSizingMode = 'AUTO';
    c.counterAxisAlignItems = 'CENTER';
    bindPad(c, lk, { l: pad.l, r: pad.r, t: pad.t, b: pad.b });
    c.setBoundVariable('itemSpacing', lk.space(dimVal(f.itemSpacing)));
    bindRadiusN(c, lk, z.borderRadius.topLeft);
    // A disabled filter takes the group's flat track — the widget hands
    // `enabled: false` to the composed `ToggleGroup`, nothing is dimmed.
    fillData(c, lk, colorData(enabled ? f.backgroundColor : f.disabledBackgroundColor));

    // `filter.dart` puts the reset button LAST in the track, after every segment and the
    // hairline. The `Shape=square`
    // member draws its leading glyph and nothing else, so the ✕ is that slot —
    // the widget's `child: Icon(LucideIcons.x)` in the one place an instance
    // can take it. `resetButtonStyle` is the widget's forward into the child,
    // and the parts of it an instance can carry land as overrides: the square's
    // own `width`/`height` (32 square at `md`, 26 square at `sm` on the `xs`
    // rung — the PARENT's
    // statement, so a divergence would render as one), its
    // `borderRadius`, and the glyph's `foregroundColor` at
    // `leadingIconStyle.size`.
    // A disabled filter hands `onPressed: null` to the button, so the ✕ takes the
    // ghost variant's disabled rung and its `disabledContent` ink — not the
    // reset style's resting `onSurfaceVariant`.
    // The Button rung whose square glyph IS the row's glyph size — `sm` (16)
    // at `md`, `xs` (14) at `sm`. The widget keeps `size: .sm` and states the
    // smaller glyph through `leadingIconStyle`, but an instance cannot resize
    // the glyph inside it (Figma refuses size overrides on an instance's
    // descendants), and the `sm` member's `minWidth` (its 32 control row)
    // would hold the 26 square open. The rung that already draws the stated
    // glyph is the canvas's spelling of the same button.
    const resetRung = buttonRungForSquareGlyph(dimVal(resetGlyphSize));
    const resetButton = restingButton(
      page,
      'ghost',
      resetRung,
      'reset',
      enabled ? 'enabled' : 'disabled',
      'square',
    );
    bindInstanceRadius(resetButton, lk, resetRadius);
    applyForwardedButtonStyle(resetButton, lk, { width: resetWidth, height: resetHeight });
    setSlotIcon(
      resetButton,
      'leading',
      resetIconIdAt(dimVal(resetGlyphSize)),
      kFilterResetGlyph,
      glyphPaint(
        lk,
        labelColor(
          lk,
          colorData(
            enabled
              ? reset.foregroundColor
              : BUTTON.variants.defaultsByVariant.ghost.disabledForegroundColor,
          ),
        ),
      ),
    );
    stateSlotGlyphSize(resetButton, 'leading', resetGlyphSize);

    const segments: FilterSegmentNodes[] = [];
    for (let i = 0; i < kFilterSegmentOrdinals.length; i++) {
      const ordinal = kFilterSegmentOrdinals[i];
      const sel = ordinal === selectedOrdinal;
      // A disabled group states one icon ink for both states.
      const segIconStyle = !enabled ? f.disabledIconStyle : sel ? f.selectedIconStyle : f.iconStyle;
      const seg = autoFrame(`seg ${ordinal}`, 'HORIZONTAL');
      seg.primaryAxisAlignItems = 'CENTER';
      seg.counterAxisAlignItems = 'CENTER';
      bindPad(seg, lk, { l: itemPad.l, r: itemPad.r, t: itemPad.t, b: itemPad.b });
      bindRadiusN(seg, lk, itemRadius);
      if (sel) {
        fillData(seg, lk, colorData(enabled ? f.selectedColor : f.disabledSelectedColor));
        // The chosen face carries the shared toggle shadow (`CoreShadow.xs`);
        // a disabled filter paints none under it.
        if (enabled) {
          setShadow(seg, f.selectedShadow, lk);
          await linkShadowStyle(seg, f.selectedShadow, 'Filter/selected');
        }
      } else seg.fills = [];

      // The `W?` icon slot — holder + glyph, the two-node shape every affix
      // slot in this file has (`hiddenAffixSlot`), but SIZED to the icon
      // style's own step so the hidden box still measures what the glyph will.
      const icon = makeIcon(kFilterSegmentGlyph, lk, {
        ...glyphOpts(lk, colorData(segIconStyle.color), segIconStyle.size, 'size'),
        fromVariant: segIconSwaps.get(ordinal)?.variant ?? null,
      });
      const iconHolder = autoFrame('icon', 'HORIZONTAL');
      iconHolder.primaryAxisAlignItems = 'CENTER';
      iconHolder.counterAxisAlignItems = 'CENTER';
      bindSize(iconHolder, lk, segIconStyle.size, segIconStyle.size);
      iconHolder.primaryAxisSizingMode = 'FIXED';
      iconHolder.counterAxisSizingMode = 'FIXED';
      iconHolder.clipsContent = false;
      iconHolder.appendChild(icon);
      iconHolder.visible = false;
      seg.appendChild(iconHolder);

      // The label box: `labelPadding` is ITS inset, not the segment's — see
      // the section note for the arithmetic that makes the two distinct.
      const labelBox = autoFrame('label', 'HORIZONTAL');
      labelBox.primaryAxisAlignItems = 'CENTER';
      labelBox.counterAxisAlignItems = 'CENTER';
      bindPad(labelBox, lk, { l: labelPad.l, r: labelPad.r, t: labelPad.t, b: labelPad.b });
      const segLabelStyle = enabled
        ? sel
          ? selectedLabelStyle
          : labelStyle
        : sel
          ? disabledSelectedLabelStyle
          : disabledLabelStyle;
      const label = makeLabel(kFilterSegmentLabels[i], lk, textLabelOpts(lk, segLabelStyle));
      labelBox.appendChild(label);
      label.layoutSizingHorizontal = 'HUG';
      label.layoutSizingVertical = 'HUG';
      // The widget's invisible twin (`filter.dart`: "Mirrors the Web label
      // ghost") — the selected typography under the live label, so the row
      // reserves the wider of the two at runtime. Pinned where the live label
      // sits, inside the same inset.
      const twin = makeLabel(
        kFilterSegmentLabels[i],
        lk,
        textLabelOpts(lk, enabled ? selectedLabelStyle : disabledSelectedLabelStyle),
      );
      pinAbsolute(labelBox, twin, dimVal(labelPad.l), dimVal(labelPad.t), {
        horizontal: 'MIN',
        vertical: 'MIN',
      });
      twin.visible = false;
      seg.appendChild(labelBox);

      // Fixed height, hugged width, never narrower than the height — what makes
      // an icon-only segment a square. Same two-step `Button` uses: `resize`
      // fixes both axes, the width hug is restored on the next line, and the
      // height is bound to its token.
      seg.counterAxisSizingMode = 'FIXED';
      bindAxisSize(seg, lk, { width: seg.width, height: itemHeight, bind: 'height' });
      seg.primaryAxisSizingMode = 'AUTO';
      bindSegmentMinWidth(seg, lk, itemHeight);
      if (ordinal === kFilterHiddenSegment) seg.visible = false;
      c.appendChild(seg);
      segments.push({ seg, iconHolder, icon, labelBox, label, twin });
    }
    // The widget's trailing `Row(spacing: trailingSpacing)`: the hairline, then
    // the reset button. The hairline is a vertical `Divider` INSTANCE at its own
    // stated length (`SizedBox(height: dividerHeight)` around the widget's
    // `Divider`) — through `hostedDivider`, the one door a `Divider` is instanced
    // through.
    const trailing = autoFrame('trailing', 'HORIZONTAL');
    trailing.counterAxisAlignItems = 'CENTER';
    trailing.setBoundVariable('itemSpacing', lk.space(dimVal(FILTER.fields.trailingSpacing)));
    // The room in front of the hairline: the leading distance (last segment to
    // hairline) minus the track's own item spacing, which already sits between
    // the last segment and this frame — the difference the resolvers take.
    // Bound to the space step that equals the difference at the standard
    // density; a density axis moves the two terms separately in code, so the
    // canvas matches the code at the standard density only.
    bindSpaceField(
      trailing,
      'paddingLeft',
      lk,
      Math.max(0, dimVal(FILTER.fields.dividerLeadingSpacing) - dimVal(f.itemSpacing)),
    );
    const hairline = hostedDivider(page, lk, trailing, {
      vertical: true,
      // A disabled filter fades the hairline with the track and labels:
      // `disabledDividerColor` instead of the divider slot's own colour.
      forwarded: {
        color: colorData(enabled ? divider.color : FILTER.fields.disabledDividerColor),
        thickness: divider.thickness,
      },
      size: { length: dividerHeight, thickness: divider.thickness },
    });
    hairline.name = 'divider';
    trailing.appendChild(resetButton);
    c.appendChild(trailing);
    members.push({ trailing, reset: resetButton, segments });
  }
  const set = mount.finish();
  // Properties AFTER `finish()`, on the set — the only moment the owner exists
  // (`form.ts`'s Button records why). Names are the designer's, adopted.
  const showResetId = defineProp(set, 'Show reset', 'BOOLEAN', true);
  const showSegIds = new Map<string, string | null>();
  const labelIds = new Map<string, string | null>();
  const showLabelIds = new Map<string, string | null>();
  const showIconIds = new Map<string, string | null>();
  const iconIds = new Map<string, string | null>();
  for (let i = 0; i < kFilterSegmentOrdinals.length; i++) {
    const ordinal = kFilterSegmentOrdinals[i];
    // Only the third and fourth segments are optional as WHOLE segments: a
    // filter with fewer than two choices is not a filter, so the first two
    // have no `Show seg N` and always draw.
    if (ordinal === '3' || ordinal === kFilterHiddenSegment) {
      showSegIds.set(
        ordinal,
        defineProp(set, `Show seg ${ordinal}`, 'BOOLEAN', ordinal !== kFilterHiddenSegment),
      );
    }
    labelIds.set(ordinal, defineProp(set, `Seg ${ordinal} label`, 'TEXT', kFilterSegmentLabels[i]));
    showLabelIds.set(ordinal, defineProp(set, `Show seg ${ordinal} label`, 'BOOLEAN', true));
    showIconIds.set(ordinal, defineProp(set, `Show seg ${ordinal} icon`, 'BOOLEAN', false));
    iconIds.set(
      ordinal,
      defineProp(set, `Seg ${ordinal} icon`, 'INSTANCE_SWAP', segIconSwaps.get(ordinal)?.id ?? iconDefaultId),
    );
  }
  for (const member of members) {
    bindVisibleProp(member.trailing, showResetId);
    for (let i = 0; i < member.segments.length; i++) {
      const ordinal = kFilterSegmentOrdinals[i];
      const s = member.segments[i];
      const showSegId = showSegIds.get(ordinal);
      if (showSegId !== undefined) bindVisibleProp(s.seg, showSegId);
      bindTextProp(s.label, labelIds.get(ordinal) ?? null);
      bindTextProp(s.twin, labelIds.get(ordinal) ?? null);
      bindVisibleProp(s.labelBox, showLabelIds.get(ordinal) ?? null);
      bindVisibleProp(s.iconHolder, showIconIds.get(ordinal) ?? null);
      bindSwapProp(s.icon, iconIds.get(ordinal) ?? null);
    }
  }
  vStackSet(set);
  return set;
}

// The ToggleGroup's size row laid over a flat field set — the resolvers'
// `merged ?? sizeRow ?? defaultX` order. `base` is the group's own flat fields,
// or the set Filter forwards (`FILTER.fields.toggleGroupStyle`, which the
// exporter fills with the same flat defaults). A row states a label ROLE only,
// so the role is laid over the base style and the state colour stays the
// base's — `defaultLabelTextStyle.merge(sizeRow.labelTextStyle)` in code.
function toggleGroupAtSize(base: typeof TOGGLE_GROUP.fields, size: string) {
  const row = Object.entries(TOGGLE_GROUP.sizes.defaultsBySize).find(([k]) => k === size)?.[1];
  if (!row) throw new Error(`ToggleGroup: no size row "${size}"`);
  return {
    padding: 'padding' in row ? row.padding : base.padding,
    borderRadius: 'borderRadius' in row ? row.borderRadius : base.borderRadius,
    itemPadding: 'itemPadding' in row ? row.itemPadding : base.itemPadding,
    itemHeight: 'itemHeight' in row ? row.itemHeight : base.itemHeight,
    labelTextStyle:
      'labelTextStyle' in row ? { ...base.labelTextStyle, ...row.labelTextStyle } : base.labelTextStyle,
    selectedLabelTextStyle:
      'selectedLabelTextStyle' in row
        ? { ...base.selectedLabelTextStyle, ...row.selectedLabelTextStyle }
        : base.selectedLabelTextStyle,
    disabledLabelTextStyle:
      'disabledLabelTextStyle' in row
        ? { ...base.disabledLabelTextStyle, ...row.disabledLabelTextStyle }
        : base.disabledLabelTextStyle,
  };
}

// A segment is never narrower than it is tall — both widgets' minimum width
// (`constraints: minWidth: itemHeight` / `min-width`), so an icon-only segment
// is a square. Bound only when the height names a size step: the `sm` row's 26
// is off the scale and lands as the number.
function bindSegmentMinWidth(seg: FrameNode, lk: VarLookup, itemHeight: number | Dim): void {
  const want = dimVal(itemHeight);
  seg.minWidth = want;
  const variable = lk.sizeOrNull(want);
  if (variable) seg.setBoundVariable('minWidth', variable);
}

// ─── ToggleGroup ─────────────────────────────────────────────────────────────
//
// The grouped toggle Filter, TimePicker's AM / PM and ColorPicker's mode tabs
// share: one track holding mutually exclusive segments, the chosen one a raised
// face with the smallest shadow step. Data-driven from coui_core
// TOGGLE_GROUP.fields:
//
//   track    backgroundColor · borderRadius · padding · itemSpacing
//   segment  itemPadding · itemBorderRadius · itemHeight · labelPadding
//   chosen   selectedColor · selectedShadow
//   ink      labelTextStyle · selectedLabelTextStyle (+ selectedFontWeight, a
//            standalone Dim — the selected style carries no weight of its own)
//   disabled disabledBackgroundColor · disabledSelectedColor ·
//            disabledLabelTextStyle (chosen and unchosen alike)
//
// ```text
// ToggleGroup  Size=md|sm , Enabled=true|false , Width=Hug|Fill , Selected=1|2|3 ,
//              Hover=false|true , Orientation=Horizontal|Vertical
//   track (HORIZONTAL | VERTICAL · hug · padding · corner · fill)
//     └─ seg N (HORIZONTAL · centred · itemHeight · itemPadding · itemRadius)
//          ├─ state layer (itemRadius · onSurface @ hover)   ← `Hover=true`, one seg
//          └─ label box (labelPadding)
//               └─ text                              ← `Option N label`
//     └─ trailing (hidden icon region)             ← `Show trailing` / `Trailing`
// ```
//
// `Size` is the widget's `size` over the two rows `defaultsBySize` states: `md`
// (segment 32 in a 4 inset · track 40, corner 10, segment inset 2, labelLarge)
// and `sm` (segment 26 in a 3 inset · track 32, corner 8, no segment inset,
// labelMedium) — read through `toggleGroupAtSize`, the row over the flat fields.
// The track is not a number of its own: inset + segment + inset. Every segment
// is at least as wide as it is tall (`bindSegmentMinWidth`). A panel's toggles
// (TimePicker AM / PM, ColorPicker mode tabs) compose `Size=sm`. `Size` is
// orthogonal to `Width`.
//
// `Orientation` is the widget's `direction` (`CoreAxis`): `Horizontal` is the row
// above, `Vertical` is a column — AM above PM. The inset, the gap between
// segments and every segment value are the horizontal ones; only the track's
// axis changes, and each segment stretches to the widest one (the widget's
// `Column(crossAxisAlignment: stretch)`) with its content centred. A vertical
// `sm` pair is 3 + 26 + 2 + 26 + 3 = 60 tall, the height of a time picker's
// hour / minute tile. Builder-declared like `Width` and `Selected`:
// `direction` is a flat enum the schema's axis promotion does not reach.
//
// `Vertical` is drawn at `Size=sm` · `Width=Hug` only — the one shape its sole
// consumer (the TimePicker's AM / PM) states. `Width=Fill` runs along the
// column's height, so a fill column has no use yet, and an `md` column has no
// consumer: both are left out of the matrix rather than drawn unasked (the
// widget still takes any `size` / `fillWidth` with a `direction`; only the
// canvas is narrower). Members that were drawn before are retired
// (`RETIRED_VARIANTS`).
//
// `Hover` is the widget's per-segment hover state layer: the layer colour
// (`stateLayerColor`, `onSurface`) at the ramp's hover weight, laid over one
// segment as a rect at child 0 (over its face, under its label) with the
// segment's own corner. A boolean pose cannot say WHICH segment is pointed at,
// so the canvas draws the first segment that is not the chosen one — the shape
// of the usual hover, the pointer moving to the alternative — and the chosen
// face wearing the layer is the same rect on the same node. A disabled group
// paints no layer, so `Enabled=false` with `Hover=true` draws what
// `Hover=false` draws.
//
// The chosen segment is the `Selected` axis, 1-indexed the way Filter's is: the
// widget states its selection as a VALUE (`value: T`), which no promotion
// predicate reaches, so the axis is builder-declared. `Enabled` is the schema's
// own — the contract states `enabled`.
//
// `Width` is the widget's `fillWidth`: `Hug` is the default track that wraps
// its segments, `Fill` makes the track take the width its parent offers and the
// segments split it equally (each segment's content centred) — a panel's mode
// tabs turn it on so the track lines up with the full-width fields below. Like
// `Selected` it is builder-declared: `fillWidth` is a flat boolean the schema's
// axis promotion does not reach. In a `Fill` variant every segment FILLs, and
// a track with FILL children is FIXED — at a demo width no narrower than
// inset + one floor per segment + gaps (`fillToggleGroupTrack`); its height
// still hugs. The instance that wants the parent's width sets its own
// horizontal sizing to FILL, and the segments then split it.
//
// A disabled group goes flat: the track takes `disabledContainer`, the chosen
// face sinks to `surfaceContainerHigh` with NO shadow, and every label takes
// `disabledContent`. The chosen label keeps its weight.
//
// Not drawn: the segment's optional icon (`CoreToggleGroupItem.icon`) and the
// focus ring. Filter's builder carries the icon slot as four properties per
// segment; this set is the shared shape the pickers compose, whose segments are
// words (AM · PM · Wheel · Slider), so the icon slot and the invisible
// selected-weight twin the widget keeps for width stability are left to the
// code. The invisible twin IS drawn (hidden, pinned under the live label), as
// in Filter. The ring is a pose, not an axis, as everywhere else in this file.
//
// Properties: `Option N label` (TEXT) per segment and `Show option 3` — the
// third segment ships shown, since a two-segment group (AM / PM) is the
// smallest the widget accepts.
const kToggleGroupOrdinals = ['1', '2', '3'] as const;
const kToggleGroupWidths = ['Hug', 'Fill'] as const;
const kToggleGroupOrientations = ['Horizontal', 'Vertical'] as const;
// A boolean pose, spelled the way every other pose in this file is.
const kToggleGroupHovers = ['false', 'true'] as const;

// The canvas draws a column at `Size=sm` · `Width=Hug` only (see the set's
// header). Applied to the enumerated product so the rest is still the full
// product of the other axes.
function drawsToggleGroupMember(combo: Record<string, string>): boolean {
  return combo['Orientation'] !== 'Vertical' || (combo['Size'] === 'sm' && combo['Width'] === 'Hug');
}
const kToggleGroupLabels: readonly string[] = ['옵션 1', '옵션 2', '옵션 3'];

// `Width=Fill` — the segments split the track equally (`fillWidth`). A FILL
// child cannot sit in a hugging track: Figma turns the track FIXED at the width
// it has the moment the first segment fills, and growing segments one at a
// time froze it at one segment's width (81 at `md`, 71 at `sm`) with three
// segments floored at their height overflowing it. So the segments are laid
// out at their own width first and fill afterwards, and the track is stated
// FIXED at the larger of that hugged width and the smallest track whose equal
// shares still meet every segment's floor — inset + floors + gaps, from the
// values the segments were drawn with. The height still hugs (`resize` sets
// both axes FIXED, so the counter axis is written back after it).
function fillToggleGroupTrack(
  track: FrameNode | ComponentNode,
  segs: readonly FrameNode[],
  m: { readonly padding: number; readonly spacing: number; readonly segmentMinWidth: number },
): void {
  const minimum = m.padding + segs.length * m.segmentMinWidth + (segs.length - 1) * m.spacing;
  const width = Math.max(track.width, minimum);
  track.primaryAxisSizingMode = 'FIXED';
  track.resize(width, track.height);
  track.counterAxisSizingMode = 'AUTO';
  for (const seg of segs) seg.layoutSizingHorizontal = 'FILL';
  // The hover segment's state layer is drawn while the segment hugs its label,
  // at that width, and STRETCH-pinned so it follows the segment afterwards. The
  // equal share is not a whole pixel (221 / 3 at `md`), and the stretched layer
  // stayed at the whole-pixel width it was drawn at — 74 over a 73.67 segment on
  // the canvas. The layer is the segment's size, not a size of its own, so it is
  // written to the segment's final box here; the pin keeps it following later.
  for (const seg of segs) {
    for (const child of seg.children) {
      if (child.name === 'state layer' && 'resize' in child) child.resize(Math.max(1, seg.width), Math.max(1, seg.height));
    }
  }
}

async function buildToggleGroup(page: PageNode, lk: VarLookup): Promise<ComponentSetNode> {
  const f = TOGGLE_GROUP.fields;
  const labelPad = f.labelPadding;
  // The rows `defaultsBySize` states (md, sm).
  const sizeRows = new Map(Object.entries(TOGGLE_GROUP.sizes.defaultsBySize));
  const itemRadius = f.itemBorderRadius.topLeft;
  const combos = enumerateAxisCombos([
    ...axisSpecsOf({
      ...TOGGLE_GROUP.axes,
      size: { ...TOGGLE_GROUP.axes.size!, members: [...sizeRows.keys()] },
    }),
    // Canonical order puts `Width` ahead of `Selected` (T-16).
    { axis: 'Width', values: kToggleGroupWidths },
    { axis: 'Selected', values: kToggleGroupOrdinals },
    // Pose axis, after `Selected` and before `Orientation` in T-16 order.
    { axis: 'Hover', values: kToggleGroupHovers },
    // After `Hover` in T-16 order; the column is the widget's `direction`.
    { axis: 'Orientation', values: kToggleGroupOrientations },
  ]).filter((name) => drawsToggleGroupMember(parseVariantKey(name)));
  const mount = mountSet(page, 'ToggleGroup', combos);
  const labels: TextNode[][] = kToggleGroupOrdinals.map(() => []);
  const thirds: FrameNode[] = [];
  // The `trailing` slot (`W?`, painted inside the track after the last segment):
  // a hidden icon region, `Show trailing` reveals it and `Trailing` swaps what
  // it holds — the same holder + glyph shape a segment's icon slot has. Read the
  // Icon variant once, the way `buildFilter` does.
  const iconDefaultId = iconMainId(page);
  const trailingSwap = iconSwapDefault(page, 'ToggleGroup', 'Trailing', iconDefaultId);
  const trailings: { holder: FrameNode; icon: InstanceNode }[] = [];
  for (const comboName of combos) {
    const combo = parseVariantKey(comboName);
    const enabled = combo['Enabled'] === 'true';
    const selectedOrdinal = combo['Selected'];
    const fillWidth = combo['Width'] === 'Fill';
    const vertical = combo['Orientation'] === 'Vertical';
    // A disabled group paints no layer; the first segment that is not the
    // chosen one wears it (see the header).
    const hoverOrdinal =
      combo['Hover'] === 'true' && enabled
        ? kToggleGroupOrdinals.find((o) => o !== selectedOrdinal)
        : undefined;
    const z = toggleGroupAtSize(f, combo['Size']);
    const pad = z.padding;
    const itemPad = z.itemPadding;
    const itemHeight = z.itemHeight;
    const labelStyle = textStyleData(z.labelTextStyle);
    // The whole selected style with the weight laid over it — the disabled
    // twin's shape. Picking four fields out dropped the role and the tracking
    // with them, and a label drawn with no ratio writes Figma's PERCENT 0: the
    // selected segment came out wider than the code's (−1% of 14px is −0.14).
    const selectedLabelStyle = {
      ...textStyleData(z.selectedLabelTextStyle),
      fontWeight: dimVal(f.selectedFontWeight),
    };
    const disabledLabelStyle = textStyleData(z.disabledLabelTextStyle);
    const disabledSelectedLabelStyle = {
      ...disabledLabelStyle,
      fontWeight: dimVal(f.selectedFontWeight),
    };
    const c = mount.getOrCreate(comboName);
    c.layoutMode = vertical ? 'VERTICAL' : 'HORIZONTAL';
    c.primaryAxisSizingMode = 'AUTO';
    c.counterAxisSizingMode = 'AUTO';
    c.counterAxisAlignItems = 'CENTER';
    bindPad(c, lk, { l: pad.l, r: pad.r, t: pad.t, b: pad.b });
    c.setBoundVariable('itemSpacing', lk.space(dimVal(f.itemSpacing)));
    bindRadiusN(c, lk, z.borderRadius.topLeft);
    fillData(c, lk, colorData(enabled ? f.backgroundColor : f.disabledBackgroundColor));

    const fillSegs: FrameNode[] = [];
    for (let i = 0; i < kToggleGroupOrdinals.length; i++) {
      const ordinal = kToggleGroupOrdinals[i];
      const chosen = ordinal === selectedOrdinal;
      const seg = autoFrame(`seg ${ordinal}`, 'HORIZONTAL');
      seg.primaryAxisAlignItems = 'CENTER';
      seg.counterAxisAlignItems = 'CENTER';
      bindPad(seg, lk, { l: itemPad.l, r: itemPad.r, t: itemPad.t, b: itemPad.b });
      bindRadiusN(seg, lk, itemRadius);
      if (chosen) {
        fillData(seg, lk, colorData(enabled ? f.selectedColor : f.disabledSelectedColor));
        // A disabled group paints no shadow under the chosen face.
        if (enabled) {
          setShadow(seg, f.selectedShadow, lk);
          await linkShadowStyle(seg, f.selectedShadow, 'ToggleGroup/selected');
        }
      } else {
        seg.fills = [];
      }

      const labelBox = autoFrame('label', 'HORIZONTAL');
      labelBox.primaryAxisAlignItems = 'CENTER';
      labelBox.counterAxisAlignItems = 'CENTER';
      bindPad(labelBox, lk, { l: labelPad.l, r: labelPad.r, t: labelPad.t, b: labelPad.b });
      const style = enabled
        ? chosen
          ? selectedLabelStyle
          : labelStyle
        : chosen
          ? disabledSelectedLabelStyle
          : disabledLabelStyle;
      const label = makeLabel(kToggleGroupLabels[i], lk, textLabelOpts(lk, style));
      labelBox.appendChild(label);
      label.layoutSizingHorizontal = 'HUG';
      label.layoutSizingVertical = 'HUG';
      // The widget's invisible width-reservation twin (`toggle_group.dart`: the
      // chosen typography under the live label), pinned where the live label
      // sits. It follows the same TEXT property.
      const twin = makeLabel(
        kToggleGroupLabels[i],
        lk,
        textLabelOpts(lk, enabled ? selectedLabelStyle : disabledSelectedLabelStyle),
      );
      pinAbsolute(labelBox, twin, dimVal(labelPad.l), dimVal(labelPad.t), {
        horizontal: 'MIN',
        vertical: 'MIN',
      });
      twin.visible = false;
      seg.appendChild(labelBox);

      // Fixed height, hugged width — the two-step Filter's segments use — and
      // never narrower than the height.
      seg.counterAxisSizingMode = 'FIXED';
      bindAxisSize(seg, lk, { width: seg.width, height: itemHeight, bind: 'height' });
      seg.primaryAxisSizingMode = 'AUTO';
      bindSegmentMinWidth(seg, lk, itemHeight);
      c.appendChild(seg);
      // A column stretches its segments to the widest one (grow would size
      // the height). `fillWidth` is applied after the loop, once every
      // segment has been laid out at its own width (`fillToggleGroupTrack`).
      if (vertical) seg.layoutAlign = 'STRETCH';
      else if (fillWidth) fillSegs.push(seg);
      if (ordinal === hoverOrdinal) {
        // `foregroundDecoration` in the widget: the ink at the hover weight over
        // the segment's face, the segment's own corner. Child 0, so it sits over
        // the fill and under the label. `insertChild` first, then pin — pinning
        // appends, and moving it to 0 afterwards would reparent it twice.
        const wash = figma.createRectangle();
        wash.name = 'state layer';
        bindRadiusN(wash, lk, itemRadius);
        fillData(wash, lk, colorData(f.stateLayerColor));
        bindLayerOpacity(wash, lk, f.stateLayer.hover);
        seg.insertChild(0, wash);
        pinInFlow(seg, wash);
        wash.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };
        wash.resize(Math.max(1, seg.width), Math.max(1, seg.height));
        wash.x = 0;
        wash.y = 0;
      }
      labels[i].push(label, twin);
      if (ordinal === '3') thirds.push(seg);
    }
    const trailingStyle = enabled ? f.iconStyle : f.disabledIconStyle;
    const trailingIcon = makeIcon(kFilterSegmentGlyph, lk, {
      ...glyphOpts(lk, colorData(trailingStyle.color), trailingStyle.size, 'size'),
      fromVariant: trailingSwap?.variant ?? null,
    });
    const trailingHolder = autoFrame('trailing', 'HORIZONTAL');
    trailingHolder.primaryAxisAlignItems = 'CENTER';
    trailingHolder.counterAxisAlignItems = 'CENTER';
    bindSize(trailingHolder, lk, trailingStyle.size, trailingStyle.size);
    trailingHolder.primaryAxisSizingMode = 'FIXED';
    trailingHolder.counterAxisSizingMode = 'FIXED';
    trailingHolder.clipsContent = false;
    trailingHolder.appendChild(trailingIcon);
    trailingHolder.visible = false;
    c.appendChild(trailingHolder);
    trailings.push({ holder: trailingHolder, icon: trailingIcon });
    if (fillSegs.length > 0) {
      fillToggleGroupTrack(c, fillSegs, {
        padding: dimVal(pad.l) + dimVal(pad.r),
        spacing: dimVal(f.itemSpacing),
        segmentMinWidth: dimVal(itemHeight),
      });
    }
  }
  const set = mount.finish();
  // Properties AFTER `finish()`, on the set — the only moment the owner
  // exists (`Button` records why).
  for (let i = 0; i < kToggleGroupOrdinals.length; i++) {
    const id = defineProp(set, `Option ${kToggleGroupOrdinals[i]} label`, 'TEXT', kToggleGroupLabels[i]);
    for (const t of labels[i]) bindTextProp(t, id);
  }
  const showThird = defineProp(set, 'Show option 3', 'BOOLEAN', true);
  for (const seg of thirds) bindVisibleProp(seg, showThird);
  const showTrailing = defineProp(set, 'Show trailing', 'BOOLEAN', false);
  const trailingSwapId = defineProp(set, 'Trailing', 'INSTANCE_SWAP', trailingSwap?.id ?? iconDefaultId);
  for (const t of trailings) {
    bindVisibleProp(t.holder, showTrailing);
    bindSwapProp(t.icon, trailingSwapId);
  }
  vStackSet(set);
  return set;
}

// ─── ItemPicker ──────────────────────────────────────────────────────────────
//
// Searchable single-select list: a search field above a list of selectable
// items (one selected, shown in ITEM_PICKER.fields.selectedColor's tone —
// tertiary, not primary-container as the old hardcoded builder assumed).
// Data-driven: container backgroundColor/borderColor/borderRadius/
// borderWidth, itemsPadding (used here as the overall container padding —
// there is no separate "outer container padding" field distinct from the
// items-scroll-area padding), option padding/radius/spacing, option text
// colours (`optionTextStyle` unselected / `selectedTextStyle` selected —
// both carry a role and a colour, so the selected row's label and its check
// glyph now read from the data instead of a literal on-tertiary), and the
// check-glyph size (checkIconSize, traces to CoreIconSize — axis fix).
//
// (An earlier note recorded `selectedTextStyle` as "genuinely absent from
// `item_picker.fields`, verified against the dump", on the strength of its being
// a role-less overlay. It carries `role: bodySmall` and an `on-tertiary` colour
// in the regenerated export, so the selected row's label and check glyph are
// read, not literal.)
//
// Composition — the search row is `TextField(variant: .plain, prefix: Icon(
// search))` inside a `SizedBox(height: resolved.searchHeight)`, closed by a
// `Divider`: a bare `TextField` INSTANCE (the panel is the only boundary) behind
// the 16 search glyph, then a horizontal `Divider` INSTANCE. The panel is a
// floating face — its own stated cast (`elevation`), not the one a style
// contributes — and the selection is the check alone (`checkColor`); the only
// filled row is the one under the pointer. The title is a label inside the
// list, ahead of the rows.
//
// Axis — `Enabled`, the schema's own (`item_picker.axes` promotes it), by
// ADOPTION: the enumeration is two combinations and `mountSet`'s `adoptLooseAs`
// renames the loose COMPONENT to `Enabled=true` in place. Its
// `CoreItemPickerLayout` enum (list/grid) stays in `axes.other`, recorded and
// deliberately not promoted (the seed spec's §4-2 boundary), so this preview
// keeps rendering the list layout.
//
// `Enabled=false` is two things: `clickableStyle.disabledOpacity` (0.5) on the
// panel, and the composed search field at `TextField`'s own disabled variant —
// `item_picker.dart:506` hands it `enabled: widget.enabled`, so that half comes
// from the child's data rather than from a literal here.
//
// No `Hover`: `optionHoverColor` (tertiary) and `optionHoverTextStyle`
// (on-tertiary) are the same pair as `selectedColor`/`selectedTextStyle`, so a
// hover axis would render identically to the row already shown as selected.
//
// The old `Search placeholder` TEXT property is the composed TextField's own
// `Placeholder` property now. `emptyText` is a `String?` and the empty-state
// line below renders it, so it is a TEXT property on that node. `title` is also
// `String?` and this preview draws no title bar, so it gets no property — one
// with no node to bind is a property that does nothing.
// A field the Dart contract added with the redesign: read through `optField`
// so the builder compiles against the export that carries it, and a stale
// `components.json` fails loudly instead of painting the old value.
function requiredField<T>(entry: object, key: string, where: string): T {
  const v = optField<T>(entry, key);
  if (v == null) {
    throw new Error(
      `${where}.${key} is missing from components.json — re-run ` +
        '`export_figma_components.dart` so the builder reads the redesigned Core defaults.',
    );
  }
  return v;
}

async function buildItemPicker(page: PageNode, lk: VarLookup): Promise<ComponentSetNode> {
  // NOT composed: `Clickable`. `item_picker.dart` wraps every item row in one, and
  // `Clickable` is a wrapper with no chrome of its own at rest — its Figma
  // component is a focus ring around a demo slot, and an instance takes no
  // appended children, so there is nothing to put the row inside.
  const optionTextStyle = textStyleData(ITEM_PICKER.fields.optionTextStyle);
  const selectedTextStyle = textStyleData(ITEM_PICKER.fields.selectedTextStyle);
  const optionPad = ITEM_PICKER.fields.optionPadding;
  const optionRadius = ITEM_PICKER.fields.optionBorderRadius.topLeft;
  const itemsPad = ITEM_PICKER.fields.itemsPadding;
  const emptyPad = ITEM_PICKER.fields.emptyPadding;
  const emptyTextStyle = textStyleData(ITEM_PICKER.fields.emptyTextStyle);
  const searchHeight = dimVal(ITEM_PICKER.fields.searchHeight);
  const items = [
    { label: '김코드', sel: false, hover: true },
    { label: '이코드', sel: true, hover: false },
    { label: '박코드', sel: false, hover: false },
  ];
  const combos = enumerateAxisCombos(axisSpecsOf(ITEM_PICKER.axes));
  const mount = mountSet(page, 'ItemPicker', combos, {
    adoptLooseAs: 'Enabled=true',
  });
  const emptyStates: FrameNode[] = [];
  const emptyLabels: TextNode[] = [];
  const titleBars: FrameNode[] = [];
  const titleLabels: TextNode[] = [];
  const titlePad = ITEM_PICKER.fields.titlePadding;
  const titleTextStyle = textStyleData(ITEM_PICKER.fields.titleTextStyle);
  // `disabledForegroundColor` — the option text and the check while the picker is
  // disabled, in its own token rather than a dimmed enabled pair.
  const disabledForeground = colorData(ITEM_PICKER.fields.disabledForegroundColor);
  for (const comboName of combos) {
    const disabled = parseVariantKey(comboName)['Enabled'] === 'false';
    const c = mount.getOrCreate(comboName);
    c.layoutMode = 'VERTICAL';
    c.primaryAxisSizingMode = 'AUTO';
    c.counterAxisSizingMode = 'AUTO';
    // The panel's own inset and its child gap are NOT `itemsPadding` /
    // `optionSpacing` — those two belong inside the ceiling'd items box below, and
    // reading them here was this builder standing in for a field the component does
    // not have. The panel keeps a zero inset; its children (title, search, items)
    // are spaced by the items box's own padding.
    c.setBoundVariable('itemSpacing', lk.space(0));
    bindRadiusN(c, lk, ITEM_PICKER.fields.borderRadius.topLeft);
    // A content surface on both platforms — Flutter composes `OutlinedContainer`
    // at its default role, Web marks the container it draws.
    applySurfaceMaterial(c, lk, colorData(ITEM_PICKER.fields.backgroundColor), 'content', {
      radius: ITEM_PICKER.fields.borderRadius.topLeft,
    });
    borderData(c, lk, colorData(ITEM_PICKER.fields.borderColor), ITEM_PICKER.fields.borderWidth);
    // It states its own cast (`elevation`, a floating panel), so it takes no
    // style-contributed one — `OutlinedContainer(elevation:)` on Flutter, the
    // `shadow-*` class on Web.
    const panelShadow = elevationLayers(
      ITEM_PICKER.fields.elevation,
      { layers: [] },
      'item_picker.elevation',
    );
    setShadow(c, panelShadow, lk);
    // The document's `shadow/<step>` effect style that states these layers, so
    // the panel follows the style instead of holding a copy (a miss keeps the
    // direct value and is listed in the build summary).
    await linkShadowStyle(c, panelShadow, `ItemPicker/${comboName}`);
    if (disabled) c.opacity = dimVal(ITEM_PICKER.fields.clickableStyle.disabledOpacity);
    // g7-preview-only: demo panel width so the preview has a box to show — `CoreItemPickerStyle` states `maxHeight` and `searchHeight` but no width, and `item_picker.dart` states none either; the real panel takes the caller's.
    lockWidth(c, 280);
    // `SizedBox(height: resolved.searchHeight)` around the field — height
    // first, then FILL: `resize` sets BOTH axes fixed, so claiming the
    // width first would be undone by the line after it. The height is the md
    // control row (`CoreItemPickerStyle.defaultSearchHeight`, the field's own
    // md row), bound to the row a density moves; a document that predates
    // the density rows keeps the literal.
    // The row is a frame of the stated height: the field's own `padding`
    // (`searchFieldStyle.padding`) insets the glyph and the field together,
    // and the glyph's gap to the field is the field's own row spacing.
    const searchStyle = ITEM_PICKER.fields.searchFieldStyle;
    const searchPad = requiredField<{
      l: Dim;
      r: Dim;
      t: Dim;
      b: Dim;
    }>(searchStyle, 'padding', 'item_picker.searchFieldStyle');
    const searchRowFrame = panel('search', 'HORIZONTAL', lk, {
      pl: searchPad.l,
      pr: searchPad.r,
      gap: TEXT_FIELD.fields.rowSpacing,
    });
    searchRowFrame.counterAxisAlignItems = 'CENTER';
    c.appendChild(searchRowFrame);
    // Height first, then FILL: `resize` sets BOTH axes fixed, so a FILL claimed
    // before it is undone and the row keeps its hugged width (226 beside a 278
    // panel interior).
    searchRowFrame.counterAxisSizingMode = 'FIXED';
    searchRowFrame.resize(searchRowFrame.width, searchHeight);
    searchRowFrame.layoutSizingHorizontal = 'FILL';
    const searchRow = lk.controlHeightOrNull(searchHeight);
    if (searchRow) searchRowFrame.setBoundVariable('height', searchRow);
    // `prefix: Icon(LucideIcons.search, iconStyle: resolved.searchIconStyle)` —
    // the quiet affix tone, `disabledContent` while disabled.
    const searchIcon = ITEM_PICKER.fields.searchIconStyle;
    const disabledSearchIconColor = ITEM_PICKER.constants.disabledSearchIconColor;
    searchRowFrame.appendChild(
      makeIcon(
        'search',
        lk,
        glyphOpts(
          lk,
          colorData(disabled ? disabledSearchIconColor : searchIcon.color),
          searchIcon.size,
          'size',
        ),
      ),
    );
    // `variant: .plain` — no box of its own.
    const search = restingTextField(page, 'md', 'search', !disabled, 'plain');
    // `localizations.itemPickerSearchPlaceholder` (ko) — not TextField's email copy.
    setInstanceTextNamed(search, 'Placeholder', kItemPickerSearchPlaceholder);
    searchRowFrame.appendChild(search);
    search.layoutSizingHorizontal = 'FILL';
    search.layoutSizingVertical = 'FILL';
    // `Divider(dividerStyle: resolved.searchDividerStyle)` closes the row; the
    // forwarded style's colour, thickness and indents reach the rule.
    const searchDividerStyle = ITEM_PICKER.fields.searchDividerStyle;
    const searchDivider = hostedDivider(page, lk, c, {
      forwarded: {
        color: colorData(searchDividerStyle.color),
        thickness: searchDividerStyle.thickness,
        indent: searchDividerStyle.indent,
        endIndent: searchDividerStyle.endIndent,
      },
    });
    searchDivider.name = 'divider';
    // `ConstrainedBox(constraints: BoxConstraints(maxHeight: resolved.maxHeight))`
    // wraps the scrolling list ONLY — the search field above and the title bar are
    // outside that box, which is why the ceiling belongs to an items frame and not
    // to the panel. `itemsPadding` and the row gap live inside the same box, so
    // they move here off the panel with it.
    //
    // Above this height the widget scrolls instead of growing; a designer dropping
    // twenty options in now stops where the widget stops.
    const itemsArea = panel('items', 'VERTICAL', lk, {
      pl: itemsPad.l,
      pr: itemsPad.r,
      pt: itemsPad.t,
      pb: itemsPad.b,
      // Rows sit flush: `optionSpacing` is the glyph-to-label gap inside a
      // row (and the grid gap), not a gap between list rows.
    });
    c.appendChild(itemsArea);
    itemsArea.layoutSizingHorizontal = 'FILL';
    itemsArea.maxHeight = dimVal(ITEM_PICKER.fields.maxHeight);
    // The title label, inside the list ahead of the rows, hidden behind a BOOLEAN — the same arrangement the empty
    // state below uses, and for the same reason. `title` is the contract's own
    // `String?` and `item_picker.dart` renders it above the search field when
    // present, so `titlePadding` and `titleTextStyle` had nowhere to land while the node did not exist.
    //
    // The note above this function said `title` "gets no property — one with no
    // node to bind is a property that does nothing", which was true only while
    // the node was missing. The very next paragraph makes the opposite move for
    // `emptyText`, also a `String?`, once its node was drawn.
    const titleBar = panel('title', 'HORIZONTAL', lk, {
      pl: titlePad.l,
      pr: titlePad.r,
      pt: titlePad.t,
      pb: titlePad.b,
    });
    // Disabled, the title and the empty line take `disabledForegroundColor` too —
    // `resolveItemPicker` swaps both styles' colours for it, so a hidden layer
    // the designer switches on reads disabled like the rows around it.
    const titleLabel = makeLabel(
      '담당자',
      lk,
      textLabelOpts(lk, disabled ? { ...titleTextStyle, color: disabledForeground } : titleTextStyle),
    );
    titleBar.appendChild(titleLabel);
    itemsArea.appendChild(titleBar);
    titleBar.layoutSizingHorizontal = 'FILL';
    titleBar.visible = false;
    titleBars.push(titleBar);
    titleLabels.push(titleLabel);
    for (const it of items) {
      const row = autoFrame('item', 'HORIZONTAL');
      row.counterAxisAlignItems = 'CENTER';
      row.setBoundVariable(
        'itemSpacing',
        lk.space(dimVal(ITEM_PICKER.fields.optionSpacing)),
      );
      bindPad(row, lk, { l: optionPad.l, r: optionPad.r, t: optionPad.t, b: optionPad.b });
      bindRadiusN(row, lk, optionRadius);
      // The filled row is the one under the pointer (the first, shown
      // hovered); the selected row carries the check alone, so its
      // `selectedColor` — transparent — draws nothing.
      if (it.hover && !disabled) fillData(row, lk, colorData(ITEM_PICKER.fields.optionHoverColor));
      else if (it.sel) fillData(row, lk, colorData(ITEM_PICKER.fields.selectedColor));
      else row.fills = [];
      itemsArea.appendChild(row);
      row.layoutSizingHorizontal = 'FILL';
      const lbl = makeLabel(
        it.label,
        lk,
        textLabelOpts(
          lk,
          disabled
            ? { ...(it.sel ? selectedTextStyle : optionTextStyle), color: disabledForeground }
            : it.sel
              ? selectedTextStyle
              : optionTextStyle,
        ),
      );
      row.appendChild(lbl);
      lbl.layoutSizingHorizontal = 'FILL';
      if (it.sel) {
        row.appendChild(
          makeIcon(
            'check',
            lk,
            glyphOpts(
              lk,
              disabled ? disabledForeground : colorData(ITEM_PICKER.fields.checkColor),
              ITEM_PICKER.fields.checkIconSize,
              'size',
            ),
          ),
        );
      }
    }
    // `if (filtered.isEmpty) children.add(Padding(padding: resolved
    // .emptyPadding, child: DefaultTextStyle.merge(style: resolved
    // .emptyTextStyle, child: Text(emptyText ?? l10n.itemPickerEmpty))))`
    // (`item_picker.dart:512-521`) — the branch this preview took the other side
    // of. It is a real part of the picker: the same container, with the items
    // area replaced by one line of copy, and the two values that describe it
    // (`emptyPadding` 24 on all four sides, `emptyTextStyle` bodySmall /
    // on-surface-variant) had nowhere on the canvas to land while the node did
    // not exist.
    //
    // Drawn hidden behind a BOOLEAN, the same arrangement `Select`'s empty state
    // uses two builders up and for the same two reasons: the populated list is
    // what a designer should read at rest, and a layer hidden inside a main
    // component is unreachable from an instance unless a property governs it.
    //
    // `emptyText` is the contract's own `String?` and this node renders it, so
    // it becomes a TEXT property here — the earlier note that it was "a property
    // with no node to bind" was true only while the node was missing. On the
    // holder frame vs the text node respectively, because
    // `componentPropertyReferences` is one map per node and each binder assigns
    // it wholesale.
    const empty = panel('empty', 'VERTICAL', lk, {
      pl: emptyPad.l,
      pr: emptyPad.r,
      pt: emptyPad.t,
      pb: emptyPad.b,
    });
    const emptyLabel = makeLabel(
      '항목이 없어요.',
      lk,
      textLabelOpts(lk, disabled ? { ...emptyTextStyle, color: disabledForeground } : emptyTextStyle),
    );
    empty.appendChild(emptyLabel);
    c.appendChild(empty);
    empty.layoutSizingHorizontal = 'FILL';
    empty.visible = false;
    emptyStates.push(empty);
    emptyLabels.push(emptyLabel);
  }
  const set = mount.finish();
  const emptyProp = defineProp(set, 'Empty state', 'BOOLEAN', false);
  for (const node of emptyStates) bindVisibleProp(node, emptyProp);
  const emptyTextProp = defineProp(set, 'Empty text', 'TEXT', '항목이 없어요.');
  for (const node of emptyLabels) bindTextProp(node, emptyTextProp);
  // The title's pair — `Show title` over the bar, `Title` over the words. Two
  // properties on two nodes because `componentPropertyReferences` is one map per
  // node, the same split the empty state above makes.
  const titleProp = defineProp(set, 'Show title', 'BOOLEAN', false);
  for (const node of titleBars) bindVisibleProp(node, titleProp);
  const titleTextProp = defineProp(set, 'Title', 'TEXT', '담당자');
  for (const node of titleLabels) bindTextProp(node, titleTextProp);
  // g7-preview-only: gallery width of the ItemPicker variant grid — a COMPONENT_SET is a Figma-only container of variants, with no counterpart anywhere in the code.
  layoutSet(set, 680);
  return set;
}

// ─── ObjectInput ─────────────────────────────────────────────────────────────
//
// Structured key-value input emitting a `Map<String, String>`.
// `object_input.dart` is ONE bordered `Container` (padding / backgroundColor /
// borderColor-or-focusBorderColor / borderWidth / borderRadius) wrapping a
// `Row` of `TextField`s separated by the `separator` glyph — not two bordered
// boxes with a colon between them, which is what this drew. Every one of
// those six chrome fields is the OUTER box's; attributing them to each field
// painted the container's border twice and never painted the container.
//
// Composition — each field is a `TextField` INSTANCE
// (`needs: ['TextField']`), one per bucket width the component declares (see
// `fieldBuckets` for why the count is three and why that is not invented
// content). `fieldInputStyle` (the nested `CoreTextFieldStyle` the widget
// forwards) is what the composed child's own resolver already applies —
// reaching into it from here is the "parent fills the child's defaults"
// anti-pattern, so it stays with the child.
//
// Axes — `Enabled` × `Focus`.
//
// `Enabled` is the schema's own (`object_input.axes` promotes it), by ADOPTION:
// `mountSet`'s `adoptLooseAs` renames the loose COMPONENT to the first
// combination in place, so no `STRUCTURAL_MIGRATIONS` entry is needed for the
// shape change. `object_input.fields` declares no disabled field of its own, so
// what changes is the composed fields: each one instantiates `TextField`'s own
// disabled variant, because `object_input.dart:204` hands it `enabled:
// widget.enabled`. Nothing is greyed out here by hand.
//
// `Focus` is a POSE, and the one focus axis in this file that can be drawn from
// data: `focusBorderColor` is a top-level field (primary, against
// `borderColor`'s outline-variant) and the width is the component's own
// `borderWidth`, so nothing is invented. It is on the container, because that
// is the node `_focused` repaints.
//
// `separator` is the contract's `String?` and the ':' node renders it → TEXT
// property.
//
// `leading` / `trailing` (`W?`) are the first and last children of that Row
// (`children.add(leading)` … `children.add(trailing)`), and each gets the
// affix pair: a BOOLEAN on the holder frame (`Show leading` / `Show
// trailing`) and an INSTANCE_SWAP on the glyph inside it, named `Leading` /
// `Trailing` for the slots they are.
//
// Drawn hidden, with a placeholder glyph. Nothing in `object_input.dart` or
// its data says WHAT goes in these slots — which is the point of a slot typed
// `W?`, and is why the earlier reading ("any node invented here would be
// content this component does not specify") left them with no node at all.
// But a slot with no node is not neutral: it is unreachable. A layer hidden
// inside a main component cannot be revealed from an instance unless a
// property governs it, so "no node" means a designer can never put anything
// there — a narrower claim than the contract's, and the one direction where
// being wrong is invisible, because the canvas looks finished. Hidden by
// default keeps the resting render identical to the widget's (null → nothing
// drawn); the glyph is a swap default, not a statement about content.
//
// Its two values do come from data. `fieldInputStyle.affixColor` is the
// colour this component forwards to its fields for exactly this position. The
// size is the app root's ambient icon size (`icon.constants.ambientSize`): the
// widget adds `leading` / `trailing` to its row as handed
// (`children.add(leading)`), inside the composed `OutlinedContainer` on Flutter
// and the root `<div>` on Web, and nothing on that path mounts an `IconTheme` —
// so an `Icon` passed there draws at that size, whatever the separator's type.
// Display copy, not chrome: one sample mask per width bucket, in bucket order.
const kObjectInputCellSamples: readonly string[] = ['00', '00', '0000'];

function buildObjectInput(page: PageNode, lk: VarLookup): ComponentSetNode {
  const pad = OBJECT_INPUT.fields.padding;
  const sep = textStyleData(OBJECT_INPUT.fields.separatorTextStyle);
  const sepPad = OBJECT_INPUT.fields.separatorPadding;
  // One field per bucket width the component declares, in ascending order.
  //
  // `fieldMaxWidthFor` (`object_input_style.dart:79-88`) answers with exactly
  // one of these three for every field, picked by that field's `maxLength`
  // against the two character bounds — and those two bounds are widget-plane
  // behaviour (`CoreObjectInputContract.defaultShortFieldMaxChars` / `…Medium…`,
  // "they pick which width applies and paint nothing"). So which bucket a given
  // field is in is not a Style statement, but all three WIDTHS are, and a
  // preview that draws one field can only ever show one of them.
  //
  // It used to draw two fields, both at `medium`, on the reading that medium was
  // "the closest non-invented stand-in" — which left `short` (32) and `long`
  // (96) stated by the data and absent from the canvas. Three fields is not an
  // invention of content: `fields` is a required `List` with no default, so the
  // count was always this preview's own choice, and choosing it to cover the
  // component's three declared widths is what a library preview is for. The
  // widget's own doc example (`object_input.dart:19-27`) is a three-field
  // `YYYY / MM / DD`, so the shape is the documented one.
  const fieldBuckets: readonly { name: string; width: Dim }[] = [
    { name: 'field (short)', width: OBJECT_INPUT.fields.shortFieldMaxWidth },
    { name: 'field (medium)', width: OBJECT_INPUT.fields.mediumFieldMaxWidth },
    { name: 'field (long)', width: OBJECT_INPUT.fields.longFieldMaxWidth },
  ];
  const disabledSepColor = colorData(OBJECT_INPUT.fields.disabledSeparatorColor);
  const affixColor = colorData(OBJECT_INPUT.fields.fieldInputStyle.affixColor);
  const affixSize = ICON.constants.ambientSize;
  const combos = enumerateAxisCombos(
    withPoses(axisSpecsOf(OBJECT_INPUT.axes), 'Focus'),
  );
  // The affix glyphs are drawn from their swap defaults, so the properties'
  // first binds leave them at `affixSize` (see `IconOpts.fromVariant`).
  const leadingSwap = iconSwapDefault(page, 'ObjectInput', 'Leading', iconMainId(page));
  const trailingSwap = iconSwapDefault(page, 'ObjectInput', 'Trailing', iconMainId(page));
  // The loose COMPONENT drew the enabled, unfocused row, so it is adopted as the
  // combination that still draws it — both changes in ONE name (see `Filter`).
  const mount = mountSet(page, 'ObjectInput', combos, {
    adoptLooseAs: combos[0],
  });
  const separators: TextNode[] = [];
  const leadingSlots: AffixSlot[] = [];
  const trailingSlots: AffixSlot[] = [];
  for (const comboName of combos) {
    const combo = parseVariantKey(comboName);
    const enabled = combo['Enabled'] !== 'false';
    const focused = combo['Focus'] === 'true';
    const c = mount.getOrCreate(comboName);
    c.layoutMode = 'HORIZONTAL';
    c.primaryAxisSizingMode = 'AUTO';
    c.counterAxisSizingMode = 'AUTO';
    c.counterAxisAlignItems = 'CENTER';
    bindPad(c, lk, { l: pad.l, r: pad.r, t: pad.t, b: pad.b });
    bindRadiusN(c, lk, OBJECT_INPUT.fields.borderRadius.topLeft);
    // The box is the lg control row (`CoreObjectInputStyle.defaultHeight`), the
    // row of the text field beside it — the row a density moves — and the
    // children sit on `fieldSpacing`. A document that predates the density rows
    // keeps the size step.
    bindSpaceField(c, 'itemSpacing', lk, dimVal(OBJECT_INPUT.fields.fieldSpacing));
    const rowHeight = dimVal(OBJECT_INPUT.fields.height);
    c.resize(c.width, rowHeight);
    c.primaryAxisSizingMode = 'AUTO';
    // The border is counted in the layout, so the width the box hugs to carries
    // its two edges — the width the widget lays out (`BoxDecoration` border, CSS
    // `border-box`). Stated outright rather than left to whatever an adopted
    // member last carried.
    c.strokesIncludedInLayout = true;
    // The row is the box's floor AND its ceiling: each composed field keeps its
    // own lg row (the field FormattedInput composes is that same row), so the
    // hug would add the border's two edges to it and read 50. Clamped at the row,
    // the box is the row and the field sits on it whole, its top and bottom edge
    // under the border it has no paint of its own to cover.
    const rowHeightVar = lk.controlHeightOrNull(rowHeight) ?? lk.sizeOrNull(rowHeight);
    if (rowHeightVar) {
      c.setBoundVariable('minHeight', rowHeightVar);
      c.setBoundVariable('maxHeight', rowHeightVar);
    } else {
      c.minHeight = rowHeight;
      c.maxHeight = rowHeight;
    }
    // Disabled says so in its own tokens, not by dimming the enabled pair — an
    // alpha is not a forced value in a colour-forcing mode — and it outranks
    // focus: a field that cannot be edited does not claim the focus ring.
    fillData(
      c,
      lk,
      colorData(
        enabled
          ? OBJECT_INPUT.fields.backgroundColor
          : OBJECT_INPUT.fields.disabledBackgroundColor,
      ),
    );
    borderData(
      c,
      lk,
      colorData(
        !enabled
          ? OBJECT_INPUT.fields.disabledBorderColor
          : focused
            ? OBJECT_INPUT.fields.focusBorderColor
            : OBJECT_INPUT.fields.borderColor,
      ),
      OBJECT_INPUT.fields.borderWidth,
    );
    const leadingSlot = hiddenAffixSlot('leading', 'tag', lk, affixSize, affixColor, leadingSwap.variant);
    c.appendChild(leadingSlot.holder);
    leadingSlots.push(leadingSlot);
    for (let i = 0; i < fieldBuckets.length; i++) {
      const bucket = fieldBuckets[i];
      // `if (separator != null && i < widget.fields.length - 1)`
      // (`object_input.dart:216`) — one between each consecutive pair, so a
      // three-field row draws two.
      if (i > 0) {
        const sepWrap = autoFrame('separator', 'HORIZONTAL');
        bindPad(sepWrap, lk, { l: sepPad.l, r: sepPad.r, t: sepPad.t, b: sepPad.b });
        const sepLabel = makeLabel(
          ':',
          lk,
          textLabelOpts(lk, enabled ? sep : { ...sep, color: disabledSepColor }),
        );
        sepWrap.appendChild(sepLabel);
        separators.push(sepLabel);
        c.appendChild(sepWrap);
      }
      // `TextField(variant: plain, size: lg)` — `CoreObjectInputStyle.defaultFieldInput
      // Variant` / `…Size`: the bare field on the lg row, so the box above is the
      // only boundary.
      const field = restingTextField(page, 'lg', bucket.name, enabled, 'plain');
      c.appendChild(field);
      // `fieldInputStyle` — a chromeless forward, the same statement `PhoneInput`
      // and `ChipInput` make: this row's own border and fill (bound above) are the
      // single boundary, so each bucket's field draws none. Its `padding` is zero
      // for the same reason, and the instance was arriving with `TextField`'s own
      // border, fill and `md`-row inset — three bordered boxes inside one.
      suppressFieldChrome(field, lk, OBJECT_INPUT.fields.fieldInputStyle);
      // The field's value role (a code role) — see `applyForwardedFieldText`.
      // The hint is set in the body face, the value on the code grid.
      applyForwardedFieldText(
        field,
        lk,
        OBJECT_INPUT.fields.fieldInputStyle.valueStyle,
        (
          OBJECT_INPUT.fields.fieldInputStyle as {
            placeholderStyle?: Parameters<typeof textStyleData>[0];
          }
        ).placeholderStyle,
      );
      // The cell's sample mask — display copy for the preview (the widget's
      // `fields` are the caller's), the `00` / `00` / `0000` the designer's copy
      // reads at the short / medium / long widths.
      setFieldPlaceholder(field, kObjectInputCellSamples[i]);
      // `SizedBox(width: min(intrinsicWidth, maxWidth))` — the widget draws a
      // field at its bucket width once its per-character intrinsic width has
      // reached the cap, which is the state the cap describes and the one worth
      // showing. FIXED before `resize`, because `resize` sets both axes fixed.
      // The height is the field's own lg row — the cell is the same 48 the
      // FormattedInput field is; the box above clamps itself to that row.
      field.layoutSizingHorizontal = 'FIXED';
      field.resize(dimVal(bucket.width), field.height);
    }
    const trailingSlot = hiddenAffixSlot(
      'trailing',
      'ellipsis',
      lk,
      affixSize,
      affixColor,
      trailingSwap.variant,
    );
    c.appendChild(trailingSlot.holder);
    trailingSlots.push(trailingSlot);
  }
  const set = mount.finish();
  const sepProp = defineProp(set, 'Separator', 'TEXT', ':');
  for (const n of separators) bindTextProp(n, sepProp);
  const showLeading = defineProp(set, 'Show leading', 'BOOLEAN', false);
  const leadingProp = defineProp(set, 'Leading', 'INSTANCE_SWAP', leadingSwap.id);
  for (const s of leadingSlots) {
    bindVisibleProp(s.holder, showLeading);
    bindSwapProp(s.icon, leadingProp);
  }
  const showTrailing = defineProp(set, 'Show trailing', 'BOOLEAN', false);
  const trailingProp = defineProp(set, 'Trailing', 'INSTANCE_SWAP', trailingSwap.id);
  for (const s of trailingSlots) {
    bindVisibleProp(s.holder, showTrailing);
    bindSwapProp(s.icon, trailingProp);
  }
  vStackSet(set);
  return set;
}

// ─── NumberInput ─────────────────────────────────────────────────────────────
//
// `TextField(type: number, textAlign: center, prefix: Button, suffix: Button)` —
// the widget composes both parts and draws no box of its own, so this set
// instantiates both. The field instance IS the box (border, fill, corner come
// from `TextField`'s own ladder at this member's variant, size and state); the
// two step buttons are `Button(variant: plain, shape: square)` instances laid
// over its two ends, and the value is a text node of this set between them.
//
// An instance takes no appended children, and `TextField`'s prefix / suffix
// seats hold icons, not buttons — so the buttons sit over the field, pinned at
// the widget's own offsets (border + inset from the box edge). The field's own
// text is switched off and the set draws `Value` itself, so a designer edits it
// from this set's panel (an instance's inner text cannot take a property).
//
// Axes: `Variant` × `Size` × `State` — the copy's 36. `Size` is the component's
// own `CoreNumberInputSize`, which the exporter files under `other` rather than
// `size`, so it is enumerated by name. hover / focus / disabled are the composed
// field's and buttons' own poses: the field instance takes the member's `State`,
// the step buttons go `disabled` with it.
//
// Properties, in the copy's order: `Value`, `Show label`, `Show description`,
// `Description`, `Show focus ring`. The label is a `FormLabel` instance and the
// description sits under the field in `descriptionStyle`, as in `TextField`.
//
// Not drawn: the at-bound disabled pose of a single button — a runtime value,
// not a member.
const kNumberInputStepButton: Readonly<Record<string, string>> = {
  sm: 'xs',
  md: 'sm',
  lg: 'md',
};
const kNumberInputStates = stateAxis(['enabled', 'hover', 'focus', 'disabled']);
const kNumberInputValueCopy = '1';
const kNumberInputDescriptionCopy = '최대 10개까지 고를 수 있어요.';

function buildNumberInput(page: PageNode, lk: VarLookup): ComponentSetNode {
  const sizeAxis = NUMBER_INPUT.axes.other.find((o) => o.enum === 'CoreNumberInputSize');
  if (!sizeAxis || !NUMBER_INPUT.axes.variant) {
    throw new Error('NumberInput: the exported axes lost CoreNumberInputSize / the variant enum.');
  }
  const members = enumerateAxisAssignments([
    { axis: 'Variant' as const, values: NUMBER_INPUT.axes.variant.members },
    { axis: 'Size' as const, values: sizeAxis.members },
    { axis: 'State' as const, values: kNumberInputStates },
  ]);
  const mount = mountSet(
    page,
    'NumberInput',
    members.map((m) => m.name),
  );
  const widths = new Map(Object.entries(NUMBER_INPUT.sizes.defaultsBySize));
  const buttonRows = new Map(Object.entries(BUTTON.sizes.defaultsBySize));
  const fieldRows = new Map(Object.entries(TEXT_FIELD.sizes.defaultsBySize));
  const plain = BUTTON.variants.defaultsByVariant.plain;
  const border = dimVal(NUMBER_INPUT.constants.borderWidth);
  const inset = dimVal(NUMBER_INPUT.constants.inset);
  const fieldStyle = NUMBER_INPUT.fields.fieldStyle;
  const valueStyle = textStyleData(fieldStyle.valueStyle);
  const descriptionStyle = textStyleData({
    ...fieldStyle.descriptionStyle,
    color: fieldStyle.descriptionColor,
  });
  const errorStyle = textStyleData({
    ...fieldStyle.errorStyle,
    color: fieldStyle.errorColor,
  });

  const valueTexts: TextNode[] = [];
  const descriptionTexts: TextNode[] = [];
  const labelFrames: FrameNode[] = [];
  const descriptionFrames: FrameNode[] = [];
  const rings: FocusRingNodes[] = [];
  for (const m of members) {
    const size = m.values['Size'];
    const state = m.values['State'];
    const disabled = state === 'disabled';
    const buttonSize = kNumberInputStepButton[size];
    const row = widths.get(size);
    const buttonRow = buttonRows.get(buttonSize);
    const fieldRow = fieldRows.get(size);
    if (!row || !buttonRow || !fieldRow || !buttonSize) {
      throw new Error(`NumberInput: no width / button / field row for "${size}" (${m.name}).`);
    }
    const width = dimVal(row.width);
    const side = dimVal(buttonRow.height);
    // Box edge to the first button: the border plus the inset's horizontal run;
    // vertically the border plus (inset − border) of padding is the inset itself.
    const edge = border + inset;
    const fieldHeight = 2 * inset + side;

    const c = mount.getOrCreate(m.name);
    c.layoutMode = 'VERTICAL';
    c.primaryAxisSizingMode = 'AUTO';
    c.counterAxisSizingMode = 'AUTO';
    c.counterAxisAlignItems = 'MIN';
    c.fills = [];
    // The root hugs; the field box below carries the widget's fixed `SizedBox` width.

    // Label slot — a `FormLabel` instance above the field, off until asked.
    const labelFrame = autoFrame('label', 'HORIZONTAL');
    bindPad(labelFrame, lk, fieldStyle.labelPadding);
    const formLabel = instanceOf(
      page,
      'FormLabel',
      bestVariantName(page, 'FormLabel', { Size: 'md', State: disabled ? 'disabled' : 'enabled' }),
    );
    labelFrame.appendChild(formLabel);
    labelFrame.visible = false;
    c.appendChild(labelFrame);
    labelFrames.push(labelFrame);

    // The box: the field instance, the two ends, the value, the ring.
    const box = autoFrame('field', 'HORIZONTAL');
    box.counterAxisAlignItems = 'CENTER';
    box.fills = [];
    c.appendChild(box);
    lockWidth(box, width);
    const field = restingTextField(page, size, 'field', !disabled, m.values['Variant'], state);
    box.appendChild(field);
    field.layoutSizingHorizontal = 'FILL';
    hideInstanceText(field);
    // The field's own caret stands where ITS text would start — after the
    // field's horizontal padding, next to the − button — but the field's text
    // is off and the set draws `Value` itself, centred between the ends. The
    // caret the widget paints is the editable's, and the editable holds that
    // centred value (`textAlign: center`, selection at the end on focus), so it
    // stands right after the value. Hide the composed one and draw it in the
    // value row below.
    //
    // Counted, as `Select` / `TimePicker` count theirs: a loop over zero
    // matches is a legal no-op, so a field that renamed its caret would leave
    // the focus member with the field's cursor AND this one.
    let hiddenCarets = 0;
    for (const caret of field.findAll((n) => n.name === 'caret')) {
      caret.visible = false;
      hiddenCarets += 1;
    }
    if (state === 'focus' && hiddenCarets === 0) {
      throw new Error(
        `NumberInput: the focus field (${m.name}) has no 'caret' node to hide — ` +
          'the composed TextField renamed its caret, and the member would show ' +
          'a second cursor at the field\'s start.',
      );
    }

    const fg = disabled ? plain.disabledForegroundColor : plain.foregroundColor;
    // The ends are square buttons, and a square button draws the row's
    // `iconShapeIconStyle` glyph (a step larger than the leading slot's) —
    // `button_style.dart` reads that field for `shape: square` (#5762).
    const glyphSize = dimVal(buttonRow.iconShapeIconStyle.size);
    for (const end of ['decrease', 'increase'] as const) {
      const button = restingButton(
        page,
        'plain',
        buttonSize,
        end,
        disabled ? 'disabled' : 'enabled',
        'square',
      );
      setSlotIcon(
        button,
        'leading',
        iconMainIdAt(page, glyphSize),
        end === 'decrease' ? 'minus' : 'plus',
        glyphPaint(lk, labelColor(lk, colorData(fg))),
      );
      stateSlotGlyphSize(button, 'leading', buttonRow.iconShapeIconStyle.size);
      // `buttonStyle` is the widget's forward into both ends: a corner it states
      // wins over the member's own rung (none by default, so this is a no-op
      // until a theme or `withStyle` gives one).
      const forwardedCorner = optField<{ topLeft: Dim }>(
        NUMBER_INPUT.fields.buttonStyle,
        'borderRadius',
      )?.topLeft;
      if (forwardedCorner) bindInstanceRadius(button, lk, forwardedCorner);
      const x = end === 'decrease' ? edge : width - edge - side;
      const pinned = pinAbsolute(box, button, x, inset, { horizontal: 'MIN', vertical: 'MIN' });
      sizePin(pinned, side, side);
    }

    // The value, centred between the ends — `textAlign: center`, in the value's
    // own type; disabled reads in the disabled-content tone like the buttons.
    const valueBox = autoFrame('value', 'HORIZONTAL');
    valueBox.primaryAxisAlignItems = 'CENTER';
    valueBox.counterAxisAlignItems = 'CENTER';
    valueBox.fills = [];
    const valueText = makeLabel(
      kNumberInputValueCopy,
      lk,
      textLabelOpts(lk, disabled ? { ...valueStyle, color: colorData(plain.disabledForegroundColor) } : valueStyle),
    );
    valueBox.appendChild(valueText);
    valueText.setPluginData(kAmbientInkKey, '1');
    valueTexts.push(valueText);
    // The caret, right after the value in the same row: `RenderEditable`
    // paints it at the end of the centred line with no gap. Width, corner and
    // colour are the `cursor*` fields `fieldStyle` hands the field; the height
    // is the value's own line box — the same reading `TextField` makes. Only
    // `focus` has one: `showCursor` is `!readOnly`, and disabled outranks focus
    // in the ladder.
    if (state === 'focus') {
      const caret = figma.createRectangle();
      caret.name = 'caret';
      caret.resize(dimVal(fieldStyle.cursorWidth), caretLineBox(valueStyle));
      statedRadius(caret, lk, fieldStyle.cursorRadius.topLeft);
      fillData(caret, lk, colorData(fieldStyle.cursorColor));
      valueBox.appendChild(caret);
    }
    const valuePin = pinAbsolute(box, valueBox, edge + side, 0, {
      horizontal: 'MIN',
      vertical: 'MIN',
    });
    sizePin(valuePin, width - 2 * (edge + side), fieldHeight);

    // `Show focus ring` — the field's own ring, off until asked (the focus
    // member's border is the field's, not this layer).
    rings.push(
      focusRing(box, lk, {
        outline: fieldStyle.focusOutlineStyle,
        color: focusOutlineRingColor(fieldStyle.focusOutlineStyle),
        corner: fieldRow.borderRadius.topLeft,
        width: width,
        height: fieldHeight,
        visible: false,
      }),
    );

    // Description slot — under the field in `descriptionStyle`, off until asked.
    const descriptionFrame = autoFrame('description', 'HORIZONTAL');
    bindPad(descriptionFrame, lk, fieldStyle.descriptionPadding);
    const descriptionText = makeLabel(
      kNumberInputDescriptionCopy,
      lk,
      textLabelOpts(lk, m.values['Variant'] === 'error' ? errorStyle : descriptionStyle),
    );
    descriptionFrame.appendChild(descriptionText);
    descriptionFrame.visible = false;
    c.appendChild(descriptionFrame);
    descriptionFrames.push(descriptionFrame);
    descriptionTexts.push(descriptionText);
  }
  const set = mount.finish();
  const valueProp = defineProp(set, 'Value', 'TEXT', kNumberInputValueCopy);
  for (const t of valueTexts) bindTextProp(t, valueProp);
  const showLabelProp = defineProp(set, 'Show label', 'BOOLEAN', false);
  for (const f of labelFrames) bindVisibleProp(f, showLabelProp);
  const showDescriptionProp = defineProp(set, 'Show description', 'BOOLEAN', false);
  for (const f of descriptionFrames) bindVisibleProp(f, showDescriptionProp);
  const descriptionProp = defineProp(set, 'Description', 'TEXT', kNumberInputDescriptionCopy);
  for (const t of descriptionTexts) bindTextProp(t, descriptionProp);
  const showRing = defineShowFocusRing(set);
  for (const ring of rings) bindShowFocusRing(ring, showRing);
  rowSet(set);
  return set;
}

// ─── RichEditor ──────────────────────────────────────────────────────────────
//
// `Column(box, counter)` with the toolbar INSIDE the box: one border, one fill
// and one focus ring around `toolbar strip · Divider · editing area`. The box
// is the composed `TextArea`'s chrome at `md` — both widgets resolve it through
// TextArea's resolver from the empty `textAreaStyle` slot — but it is drawn
// here as a frame rather than a `TextArea` instance, because Figma takes no
// children into an instance and the strip has to sit inside the border. Its
// corner, fill, border, inset and placeholder are therefore TextArea's own md
// row and variant row, read off the TextArea export, the way the widget reads
// them off TextArea's resolver.
//
// The strip is `ColoredBox(toolbarBackgroundColor, Padding(toolbarPadding,
// buttons · spacer · trailing))`: filled `surface-container` while enabled and
// left empty while disabled (the box's own disabled fill shows through). Its
// inset is directional — the wider side is where the text starts, in front of
// the block-type button's label. Under it a horizontal `Divider` forwarded
// `toolbarDividerStyle` (`disabled-outline` while disabled, as the box border).
//
// The buttons, by `CoreRichEditorFormat.defaultToolbar`'s groups:
//
//   [block type] [bold italic strikethrough code link] [list ordered todo]
//   [quote image]
//
// The groups are `toolbarGroupGapStyle` apart with a vertical `Divider`
// (`Orientation=Vertical, Label=None`, `toolbarGroupDividerHeight` long) in the
// middle of each gap; inside a group the buttons are `toolbarItemSpacing`
// apart. Each format is a `Button(variant: plain)` square holding one Lucide
// glyph, sized and inset by the forwarded `toolbarButtonStyle`; its rung is the
// Button size whose height is that slot's (32 → `sm`). The block-type entry is
// the one labelled button: `Button(variant: plain, size: sm)` with the
// paragraph's name ("Text") and a trailing `chevron-down`, the label and the
// chevron `blockTypeButtonStyle.iconLabelGapStyle` apart. The menu it opens is
// not drawn — an open menu is an overlay, and `Menu` / `MenuItem` have sets of
// their own.
//
// The image button draws the `image` glyph, as the widget does. The widget
// shows that button only when the app gives it an upload and a delete; the
// canvas shows it as the designer drew the set, with it.
//
// Beside the box, as the designer drew the set to show it in use: a
// `FormLabel` above and a supporting row (description, counter) below — the
// widget draws neither label nor description (the app's `FormLabel` and text
// do), only the counter. The editing area is a fixed preview height and the
// set a fixed preview width; the widget follows its content (`minHeight` …
// `maxHeight`) and its parent.
//
// Axes: `State` — enabled / disabled, the box's and the buttons' own poses.
// Focus is not a member: the editor's focus is the box's ring.
//
// Properties: `Show toolbar`, `Show toolbar trailing` and `Toolbar trailing` —
// the app control at the strip's end (`toolbarTrailing`), a `Checkbox` by
// default because that is what the slot is reached for ("show changes").
//
// Not drawn: the formatted document (bold runs, lists, quotes) — content a
// designer types, not a pose; the held-down button of a format on at the caret;
// the tooltip with its shortcut keys and the block-type menu — overlays with
// sets of their own; the second row a toolbar wraps onto when the trailing
// control has no room.
const kRichEditorStates = stateAxis(['enabled', 'disabled']);
// `null` is the block-type entry; every other string is a Lucide glyph.
const kRichEditorToolbar: readonly (readonly (string | null)[])[] = [
  [null],
  ['bold', 'italic', 'strikethrough', 'code', 'link'],
  ['list', 'list-ordered', 'list-todo'],
  ['quote', 'image'],
];
const kRichEditorPlaceholderCopy = '댓글을 입력해 주세요';
const kRichEditorBlockTypeCopy = '본문';
const kRichEditorLabelCopy = '댓글';
const kRichEditorDescriptionCopy = '최대 200자까지 쓸 수 있어요.';
const kRichEditorCounterCopy = '0 / 200';
// g7-preview-only: the set's width on the canvas — the widget takes its parent's width, and no RichEditor or TextArea field states one.
const kRichEditorPreviewWidth = 640;
// g7-preview-only: the editing area's height on the canvas — the widget follows its content between `minHeight` and `maxHeight`.
const kRichEditorPreviewBodyHeight = 180;

/**
 * The buttons of a RichEditor toolbar: [groups] of plain `Button`s — the
 * block-type button where a group names `null`, a 32-square icon button for
 * every glyph — with a gap, a vertical `Divider` and a gap between groups.
 *
 * One function for the toolbar in the box and the one that floats over a
 * selection, as one widget (`RichEditorToolbarBar`) draws both in code: the
 * two cannot drift on the canvas either.
 */
function richEditorToolbarButtons(
  page: PageNode,
  lk: VarLookup,
  groups: readonly (readonly (string | null)[])[],
  o: { disabled: boolean },
): FrameNode {
  const fields = RICH_EDITOR.fields;
  const buttonStyle = fields.toolbarButtonStyle;
  const side = dimVal(buttonStyle.height);
  const buttonSize = Object.entries(BUTTON.sizes.defaultsBySize).find(
    ([, row]) => dimVal(row.height) === side,
  )?.[0];
  if (!buttonSize) {
    throw new Error(`RichEditor: no Button size is ${side} tall (toolbarButtonStyle.height).`);
  }
  const buttonRow = BUTTON.sizes.defaultsBySize[buttonSize as keyof typeof BUTTON.sizes.defaultsBySize];
  const plain = BUTTON.variants.defaultsByVariant.plain;
  const glyphSize = fields.toolbarIconStyle.size;
  const itemSpacing = dimVal(fields.toolbarItemSpacing);
  const groupGap = dimVal(fields.toolbarGroupGapStyle.size);
  const groupDividerHeight = fields.toolbarGroupDividerHeight;
  const blockTypeGap = dimVal(fields.blockTypeButtonStyle.iconLabelGapStyle.size);
  const dividerStyle = fields.toolbarDividerStyle;
  const state = o.disabled ? 'disabled' : 'enabled';

  const buttons = autoFrame('buttons', 'HORIZONTAL');
  buttons.counterAxisAlignItems = 'CENTER';
  bindSpaceField(buttons, 'itemSpacing', lk, groupGap);

  const fg = o.disabled ? plain.disabledForegroundColor : plain.foregroundColor;
  const paint = glyphPaint(lk, labelColor(lk, colorData(fg)));
  for (const [g, group] of groups.entries()) {
    // Gap · line · gap between two groups: the line sits in the middle of
    // the groups' gap, which the row's spacing draws on each side of it.
    if (g > 0) {
      const line = hostedDivider(page, lk, null, {
        vertical: true,
        forwarded: { color: colorData(dividerStyle.color), thickness: dividerStyle.thickness },
        size: { length: groupDividerHeight, thickness: dividerStyle.thickness },
      });
      line.name = 'group divider';
      buttons.appendChild(line);
    }
    const row = autoFrame(`group ${g + 1}`, 'HORIZONTAL');
    row.counterAxisAlignItems = 'CENTER';
    bindSpaceField(row, 'itemSpacing', lk, itemSpacing);
    buttons.appendChild(row);
    for (const glyph of group) {
      if (glyph === null) {
        // The block-type button: the paragraph's name and a chevron.
        const blockType = restingButton(page, 'plain', buttonSize, 'block type', state);
        setInstanceLabel(blockType, kRichEditorBlockTypeCopy);
        setSlotIcon(
          blockType,
          'trailing',
          iconMainIdAt(page, dimVal(buttonRow.trailingIconStyle.size)),
          'chevron-down',
          paint,
        );
        stateSlotGlyphSize(blockType, 'trailing', buttonRow.trailingIconStyle.size);
        bindSpaceField(blockType, 'itemSpacing', lk, blockTypeGap);
        row.appendChild(blockType);
        continue;
      }
      const button = restingButton(page, 'plain', buttonSize, glyph, state, 'square');
      setSlotIcon(button, 'leading', iconMainIdAt(page, dimVal(glyphSize)), glyph, paint);
      stateSlotGlyphSize(button, 'leading', glyphSize);
      applyForwardedButtonStyle(button, lk, {
        width: buttonStyle.width,
        height: buttonStyle.height,
        padding: buttonStyle.padding,
      });
      row.appendChild(button);
    }
  }
  return buttons;
}

function buildRichEditor(page: PageNode, lk: VarLookup): ComponentSetNode {
  const members = enumerateAxisAssignments([
    { axis: 'State' as const, values: kRichEditorStates },
  ]);
  const mount = mountSet(
    page,
    'RichEditor',
    members.map((m) => m.name),
  );
  const fields = RICH_EDITOR.fields;
  const dividerStyle = fields.toolbarDividerStyle;
  // The box: TextArea's `md` row and its clean variant row — what TextArea's
  // resolver hands the widget for `size: md, hasError: false`.
  const area = TEXT_AREA.sizes.defaultsBySize.md;
  const areaRow = TEXT_AREA.variants.defaultsByVariant['default'];
  const valueStyle = textStyleData(area.baseTextStyle);
  const helperStyle = textStyleData(TEXT_AREA.fields.descriptionStyle);
  const trailingVariant = bestVariantName(page, 'Checkbox', {
    Size: 'sm',
    State: 'enabled',
    Checked: 'true',
  });

  const toolbars: SceneNode[] = [];
  const trailingHolders: FrameNode[] = [];
  const trailingContents: InstanceNode[] = [];
  for (const m of members) {
    const disabled = m.values['State'] === 'disabled';

    const c = mount.getOrCreate(m.name);
    c.layoutMode = 'VERTICAL';
    c.primaryAxisSizingMode = 'AUTO';
    c.counterAxisSizingMode = 'AUTO';
    c.counterAxisAlignItems = 'MIN';
    c.fills = [];
    bindSpaceField(c, 'itemSpacing', lk, dimVal(TEXT_AREA.fields.labelGapStyle.size));
    lockWidth(c, kRichEditorPreviewWidth);

    // The app's label above the box — a `FormLabel` at `md`.
    const formLabel = instanceOf(
      page,
      'FormLabel',
      bestVariantName(page, 'FormLabel', {
        Size: 'md',
        State: disabled ? 'disabled' : 'enabled',
        Enabled: disabled ? 'false' : 'true',
      }),
    );
    formLabel.name = 'label';
    setInstanceLabel(formLabel, kRichEditorLabelCopy);
    c.appendChild(formLabel);

    // The box and the supporting row below it, the description gap riding as
    // the row's top inset (TextArea's own arrangement).
    const body = autoFrame('body', 'VERTICAL');
    body.primaryAxisAlignItems = 'MIN';
    body.counterAxisAlignItems = 'MIN';
    body.itemSpacing = 0;
    c.appendChild(body);
    body.layoutSizingHorizontal = 'FILL';

    const field = autoFrame('field', 'VERTICAL');
    body.appendChild(field);
    field.primaryAxisAlignItems = 'MIN';
    field.counterAxisAlignItems = 'MIN';
    field.layoutSizingHorizontal = 'FILL';
    // The strip's fill ends under the rounded corners, as the widget clips it.
    field.clipsContent = true;
    bindRadiusN(field, lk, area.borderRadius.topLeft);
    applySurfaceMaterial(
      field,
      lk,
      colorData(disabled ? areaRow.disabledBackgroundColor : areaRow.backgroundColor),
      'content',
      { radius: area.borderRadius.topLeft },
    );
    borderData(
      field,
      lk,
      colorData(disabled ? areaRow.disabledBorderColor : areaRow.borderColor),
      TEXT_AREA.fields.borderWidth,
    );
    // The strip and the editing area sit inside the border, as the widget
    // insets them by its width: a child is painted over its parent's stroke,
    // so a strip laid edge to edge would cover the border it meets. The
    // stroke itself takes that room in the layout — stated here rather than
    // left to the frame's default, and with no padding of its own on top:
    // both at once inset the content by twice the border (#5951).
    field.strokesIncludedInLayout = true;

    // The strip.
    const toolbar = autoFrame('toolbar', 'HORIZONTAL');
    toolbar.counterAxisAlignItems = 'CENTER';
    bindPad(toolbar, lk, fields.toolbarPadding);
    if (disabled) {
      toolbar.fills = [];
    } else {
      fillData(toolbar, lk, colorData(fields.toolbarBackgroundColor));
    }
    field.appendChild(toolbar);
    toolbar.layoutSizingHorizontal = 'FILL';
    toolbars.push(toolbar);

    toolbar.appendChild(
      richEditorToolbarButtons(page, lk, kRichEditorToolbar, { disabled }),
    );

    // What is left of the strip, then the app's control at its end.
    // A plain frame, not an auto-layout one: an empty hugging frame keeps
    // the height it was created with and would stretch the strip.
    const spacer = figma.createFrame();
    spacer.name = 'spacer';
    spacer.fills = [];
    spacer.resize(0, 0);
    toolbar.appendChild(spacer);
    spacer.layoutGrow = 1;
    const trailing = autoFrame('trailing', 'HORIZONTAL');
    trailing.counterAxisAlignItems = 'CENTER';
    trailing.fills = [];
    toolbar.appendChild(trailing);
    const trailingContent = instanceOf(page, 'Checkbox', trailingVariant);
    trailingContent.name = 'trailing content';
    trailing.appendChild(trailingContent);
    trailing.visible = false;
    trailingHolders.push(trailing);
    trailingContents.push(trailingContent);

    // The line under the strip — the box's border colour while disabled.
    const rule = hostedDivider(page, lk, field, {
      forwarded: {
        color: colorData(disabled ? areaRow.disabledBorderColor : dividerStyle.color),
        thickness: dividerStyle.thickness,
      },
    });
    rule.name = 'toolbar divider';
    toolbars.push(rule);

    // The editing area — TextArea's inset and placeholder.
    const editing = autoFrame('editing area', 'VERTICAL');
    editing.primaryAxisAlignItems = 'MIN';
    editing.counterAxisAlignItems = 'MIN';
    editing.fills = [];
    bindPad(editing, lk, area.padding);
    field.appendChild(editing);
    // The widget's floor (`minHeight`), bound, so a designer who shortens the
    // preview stops where the widget stops; the preview stands taller.
    const minHeight = dimVal(fields.minHeight);
    editing.minHeight = minHeight;
    const minHeightStep = lk.sizeOrNull(minHeight);
    if (minHeightStep) editing.setBoundVariable('minHeight', minHeightStep);
    editing.primaryAxisSizingMode = 'FIXED';
    editing.resize(editing.width, kRichEditorPreviewBodyHeight);
    // After the resize, which pins the width it was handed.
    editing.layoutSizingHorizontal = 'FILL';
    const placeholder = makeLabel(
      kRichEditorPlaceholderCopy,
      lk,
      textLabelOpts(lk, {
        ...valueStyle,
        color: colorData(disabled ? areaRow.disabledForegroundColor : areaRow.placeholderColor),
      }),
    );
    placeholder.name = 'placeholder';
    editing.appendChild(placeholder);
    placeholder.layoutSizingHorizontal = 'FILL';

    // The supporting row — the app's description and the editor's counter.
    const supporting = autoFrame('supporting', 'HORIZONTAL');
    supporting.primaryAxisAlignItems = 'MIN';
    supporting.counterAxisAlignItems = 'MIN';
    supporting.fills = [];
    bindSpaceField(
      supporting,
      'paddingTop',
      lk,
      dimVal(TEXT_AREA.fields.descriptionGapStyle.size),
    );
    bindSpaceField(
      supporting,
      'itemSpacing',
      lk,
      dimVal(TEXT_AREA.fields.counterGapStyle.size),
    );
    body.appendChild(supporting);
    supporting.layoutSizingHorizontal = 'FILL';
    const description = makeLabel(
      kRichEditorDescriptionCopy,
      lk,
      textLabelOpts(lk, { ...helperStyle, color: colorData(TEXT_AREA.fields.helperTextColor) }),
    );
    description.name = 'description';
    supporting.appendChild(description);
    description.layoutSizingHorizontal = 'FILL';
    const counter = makeLabel(
      kRichEditorCounterCopy,
      lk,
      textLabelOpts(lk, {
        ...helperStyle,
        color: colorData(TEXT_AREA.fields.counterStyle.color ?? TEXT_AREA.fields.helperTextColor),
      }),
    );
    counter.name = 'counter';
    supporting.appendChild(counter);
  }
  const set = mount.finish();
  const showToolbar = defineProp(set, 'Show toolbar', 'BOOLEAN', true);
  for (const t of toolbars) bindVisibleProp(t, showToolbar);
  const showTrailing = defineProp(set, 'Show toolbar trailing', 'BOOLEAN', false);
  for (const h of trailingHolders) bindVisibleProp(h, showTrailing);
  const trailingProp = defineProp(
    set,
    'Toolbar trailing',
    'INSTANCE_SWAP',
    mainId(page, 'Checkbox', trailingVariant),
  );
  for (const t of trailingContents) bindSwapProp(t, trailingProp);
  rowSet(set);
  return set;
}

// ─── RichEditorSelectionToolbar ──────────────────────────────────────────────
//
// The toolbar `RichEditor` floats over a run of selected text
// (`showSelectionToolbar`). In code it is two lines:
//
// ```dart
// Popup(popupStyle: resolved.selectionToolbarPanelStyle,
//       children: [RichEditorToolbarBar(groups: selectionToolbar, …)])
// ```
//
// So the panel IS a `Popup` — its fill, line and cast are that component's —
// and the buttons are the toolbar's own, drawn by the function the box's
// toolbar is drawn by. A Figma instance takes no children, so the `Popup`
// instance goes BEHIND the buttons, pinned to all four edges (the arrangement
// `Menu` uses), and the two things the panel states differently from a plain
// `Popup` land where they can: the inset on the root's own auto-layout
// (`selectionToolbarPanelStyle.padding` — 4, with 12 where the text starts)
// and the corner on the instance (`selectionToolbarPanelStyle.borderRadius`).
//
// The groups are `CoreRichEditorFormat.selectionToolbar`: the default toolbar
// without the image button — an image is a new block, not a change to the
// selected text.
//
// One component, no axes: the toolbar shows only in an editor that takes
// input, so it has no disabled pose, and the poses of its buttons are
// `Button`'s own.
//
// Not drawn: where it sits (`selectionToolbarOffset` above the selection, the
// flip below it, the shift at the screen's edge) — positioning, which a
// static frame has no selection to show against; the held-down button of a
// format on at the selection; the block-type menu and the tooltips —
// overlays with sets of their own.
const kRichEditorSelectionToolbar: readonly (readonly (string | null)[])[] = kRichEditorToolbar
  .map((group) => group.filter((glyph) => glyph !== 'image'))
  .filter((group) => group.length > 0);

function buildRichEditorSelectionToolbar(page: PageNode, lk: VarLookup): ComponentNode {
  const panelStyle = RICH_EDITOR.fields.selectionToolbarPanelStyle;
  const c = mint(page, 'RichEditorSelectionToolbar');
  c.layoutMode = 'HORIZONTAL';
  c.primaryAxisSizingMode = 'AUTO';
  c.counterAxisSizingMode = 'AUTO';
  c.counterAxisAlignItems = 'CENTER';
  c.fills = [];
  bindPad(c, lk, panelStyle.padding);
  // The panel surface, as the first (bottom-most) child so the buttons draw
  // over it; STRETCH keeps it tracking the frame.
  const surface = popupInstance(page, panelStyle.padding);
  const surfacePin = pinAbsolute(c, surface, 0, 0, { horizontal: 'STRETCH', vertical: 'STRETCH' });
  hidePopupContent(surface);
  applyForwardedPanelStyle(surface, lk, { borderRadius: panelStyle.borderRadius });
  c.appendChild(
    richEditorToolbarButtons(page, lk, kRichEditorSelectionToolbar, { disabled: false }),
  );
  // Last, once the buttons have settled the root's size. The root hugs both
  // axes, so when the surface was pinned the root was the padding alone and
  // STRETCH carried only the GROWTH from there: the panel came out 395×32 at the
  // top-left of a 411×40 toolbar — the quote button past its right edge, no
  // inset below the buttons — while every value the parity read was right.
  // `sizePin` gives the holder the box its constraints then keep (see
  // `buildMenu` and the Fab menu for the same line).
  sizePin(surfacePin, c.width, c.height);
  return c;
}

// ─── Registry ────────────────────────────────────────────────────────────────
//
// `needs` names every REGISTRY component a builder instantiates, so
// `topoSortRegistry` builds the child first. Without the edge the parent runs
// before the child exists and `instanceOf` throws — and because the generation
// loop walks sections (Form → Display → Navigation → Overlay → Layout), a Form
// component composing `Divider` (Layout) or `Tooltip` (Display) is exactly the
// case position alone cannot order.
//
// No cycles: `Button` needs only `Icon`, `TextField` needs `Icon` + `Button`,
// `Popover` needs `Button` + `Popup`, and `Divider` / `Tooltip` /
// `FocusOutline` / `Toggle` need nothing from this file. Nothing this file
// declares is itself needed by any of them, so every edge points out of the
// Form section and `topoSortRegistry` has an order.
//
// Eight entries here changed node type (single COMPONENT → COMPONENT_SET) by
// gaining an axis: Autocomplete, Range, StarRating, Stepper, MultipleChoice,
// Filter, ItemPicker, ObjectInput. Figma cannot convert a node type in place, so
// the old loose node has to be accounted for or it lingers beside the new set
// under the same name — and the mechanism for that is `mountSet`'s
// `adoptLooseAs`, which RENAMES the loose COMPONENT to one combination and lets
// `getOrCreate` recycle it in place. Adoption keeps its key, which a
// `STRUCTURAL_MIGRATIONS` retire-and-remint would destroy; that is why every set
// above passes it and no entry in that table names a component from this file.
// The adopted combination is always the one the loose node actually DREW, and
// where a builder adds a pose on top of the schema's axes it is the composed name
// (`Filter`, `ObjectInput`) — adopting the bare schema name would hand the node a
// name this file no longer produces.
//
// Adding an axis also renames every existing variant of a set that already had
// one, which `mountSet` refuses to resolve on its own by design (S-a) — so those
// need `VARIANT_RENAMES` entries: `Select` and `SwitchField` and
// `MultiAnswerCard` (their old single `Variant=`/`State=` children), `Stepper`
// (`Disabled=…` → `Layout=horizontal, Disabled=…`) and `Fab` (the canvas spelled
// its designer-added `State` axis last, `Size=…, Open=…, State=…`; the rows
// move each of those twelve to the T-16 order this builder composes). That
// table is outside this file's ownership.
//
// Where a state could NOT become an axis it became a BOOLEAN property instead,
// which needs no migration at all: `Select`'s open panel and `Autocomplete`'s
// dropdown (open/closed is a pose the four axes do not carry, and its old
// `Variant=Open` member is retired in `src/renames.ts`), `Range`'s two focus
// rings, `StarRating`'s focus layer, `ItemPicker`'s title bar and empty state.
export const FORM_CONTROLS: RegistryEntry[] = [
  {
    section: 'Form',
    name: 'Select',
    // No `Button`: the trigger is a `TextField` and the rows are
    // `MenuItem`s — the select composes neither a button nor a glyph of
    // its own any more (the chevron rides in the field's suffix seat).
    build: buildSelect,
    needs: ['Icon', 'MenuItem', 'Popover', 'TextField'],
  },
  {
    section: 'Form',
    name: 'Autocomplete',
    build: buildAutocomplete,
    needs: ['TextField', 'Popover'],
  },
  { section: 'Form', name: 'SwitchField', build: buildSwitchField, needs: ['Toggle'] },
  { section: 'Form', name: 'Range', build: buildRange, needs: ['FocusOutline'] },
  { section: 'Form', name: 'StarRating', build: buildStarRating, needs: ['Icon'] },
  { section: 'Form', name: 'Stepper', build: buildStepper, needs: ['Icon', 'Divider'] },
  {
    section: 'Form',
    name: 'Fab',
    build: buildFab,
    needs: ['Icon', 'Button', 'Tooltip', 'MenuItem', 'Popup'],
  },
  { section: 'Form', name: 'MultipleChoice', build: buildMultipleChoice, needs: ['Chip'] },
  { section: 'Form', name: 'MultiAnswerCard', build: buildMultiAnswerCard, needs: ['Checkbox'] },
  // 'Rating' removed (#3742) — no standalone `Rating` class exists in
  // coui_core; `StarRating` above was always the same shape, duplicated.
  { section: 'Form', name: 'Filter', build: buildFilter, needs: ['Icon', 'Button', 'Divider'] },
  { section: 'Form', name: 'ToggleGroup', build: buildToggleGroup, needs: ['Icon'] },
  { section: 'Form', name: 'ItemPicker', build: buildItemPicker, needs: ['Icon', 'TextField'] },
  // The field and both ends are composed instances; `Icon` for the two glyphs.
  {
    section: 'Form',
    name: 'NumberInput',
    build: buildNumberInput,
    needs: ['Icon', 'Button', 'TextField', 'FormLabel'],
  },
  {
    section: 'Form',
    name: 'ObjectInput',
    build: buildObjectInput,
    needs: ['Icon', 'TextField'],
  },
  // The box holds the toolbar strip, so it is drawn from TextArea's rows
  // rather than composed; the label is a `FormLabel`, each toolbar button a
  // plain `Button` with an `Icon` glyph, the rules `Divider`s and the trailing
  // slot's default a `Checkbox`.
  {
    section: 'Form',
    name: 'RichEditor',
    build: buildRichEditor,
    needs: ['Icon', 'Button', 'Checkbox', 'Divider', 'FormLabel'],
  },
  // The toolbar `RichEditor` floats over selected text. Its chrome is a
  // fragment of `CoreRichEditorStyle` — the widget is a part of the editor
  // with no Style of its own: the panel slot, and the toolbar slots the
  // buttons are drawn from. The panel is a composed `Popup`.
  {
    section: 'Form',
    name: 'RichEditorSelectionToolbar',
    build: buildRichEditorSelectionToolbar,
    dataSlug: 'rich_editor',
    dataFields: [
      'selectionToolbarPanelStyle',
      'toolbarButtonStyle',
      'toolbarIconStyle',
      'toolbarItemSpacing',
      'toolbarGroupGapStyle',
      'toolbarGroupDividerHeight',
      'toolbarDividerStyle',
      'blockTypeButtonStyle',
    ],
    needs: ['Icon', 'Button', 'Divider', 'Popup'],
  },
];
