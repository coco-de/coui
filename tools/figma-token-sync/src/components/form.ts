/// <reference types="@figma/plugin-typings" />

import { caretLineBox, statedRadius, kToggleTrackName } from '../form-drawing';

import {
  iconMainId,
  iconSwapDefault,
  kMarkBarName,
  paintsFill,
  pinInFlow,
  RegistryEntry,
  VarLookup,
  applyChrome,
  applyFormRowChrome,
  addControlShadow,
  applySurfaceMaterial,
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
  borderData,
  defineProp,
  fillData,
  focusRing,
  glyphOpts,
  indicatorBox,
  instanceOf,
  lockWidth,
  mainComponentIdOf,
  makeIcon,
  makeLabel,
  markStep,
  textLabelOpts,
  mountSet,
  pinAbsolute,
  drainTextStyleAttach,
  reportSubProgressAndYield,
  setShadow,
  timedGeom,
  typographyColorOpts,
  vStackSet,
  applyForwardedButtonStyle,
} from '../helpers';
import { bindShowFocusRing, defineShowFocusRing, stateAxis } from '../state-axis';
import { linkShadowStyle } from '../shadow-style';
import type { FocusRingNodes, IconOpts } from '../helpers';
import {
  colorData,
  dimVal,
  mergeTextStyleData,
  optField,
  textStyleData,
  Color,
  Dim,
  NormalizedColor,
  TextLeaf,
} from '../compat/v1';
import {
  BUTTON,
  TEXT_FIELD,
  CHECKBOX,
  TOGGLE,
  RADIO_GROUP,
  COMPONENTS,
} from '../data';
import {
  axisSpecsOf,
  enumerateAxisAssignments,
  composeVariantName,
  enumerateAxisCombos,
  sizeRowFor,
} from '../axis-combos';
import { parseVariantKey } from '../variant-safety';
import { formLabelSizeCells } from '../form-label-sizes';

const SLIDER = COMPONENTS.slider;
const TEXT_AREA = COMPONENTS.text_area;
// `FocusOutline` carries its own recipe — `RadioGroup` composes the wrapper
// without passing a `focusOutlineStyle:`, so the ring's colour/shape come from
// the child's defaults exactly as they do at run time.
const FOCUS_OUTLINE = COMPONENTS.focus_outline;
// `icon.constants.ambientSize` — the app root's ambient icon size, which an
// `Icon` handed to a caller slot draws at when the widget renders it as handed.
// Checkbox's `trailing` says why it qualifies.
const ICON = COMPONENTS.icon;

// Preview width for the two field components. Not a token — no CoUI recipe
// carries "how wide a text field is": `TEXT_AREA.fields.minWidth` (100) is a
// resize floor, applied as one below, and its `initialWidth` is
// `{unbounded: true}`, which says the widget fills its parent rather than
// naming a number. This is the one width the builder invents, so it sits on the
// component that a designer resizes and every row inside it FILLs — no second
// copy to drift, and nothing downstream re-states it.
const kFieldPreviewWidth = 240;

// `initialWidth` → whether the field's row fills its parent or takes a width of
// its own.
//
// The value is `{unbounded: true}` (`double.infinity`), and the FILL below is
// what that means. Read as a branch rather than assumed: the note above already
// said "the widget fills its parent", and the canvas agreed with it by
// coincidence — nothing connected the two, so a recipe that named a real width
// would have gone on filling.
// A resize CEILING as Figma states it: a number, or `null` for unbounded.
//
// `double.infinity` arrives as `{unbounded: true}` and Web's own reading is to emit
// no `max-*` rule at all (`_remOrNull`), so `null` is the same statement in Figma's
// vocabulary — an unconstrained axis. Written rather than skipped, because a
// skipped write leaves the constraint true by coincidence.
function resizeCeiling(leaf: { unbounded?: boolean; v?: number }): number | null {
  return leaf.unbounded === true ? null : (leaf.v ?? null);
}

function fieldSizingFor(initialWidth: { unbounded?: boolean }): 'FILL' | 'HUG' {
  return initialWidth.unbounded === true ? 'FILL' : 'HUG';
}

// Track width for `Slider`, and the fraction of it the preview's thumb sits at.
// Neither is a token: the widget's track takes `constraints.maxWidth` from
// whatever it is dropped into, and where the thumb rests is the caller's value.
// Every other number in that builder is derived from these two plus the stated
// `thumbSize` / `trackHeight` / `containerPadding`.
// Canvas display width only (designer-confirmed): the code fills its parent,
// so inside the set the track is a FILL child and this width merely gives
// that FILL something to resolve against.
const kSliderPreviewWidth = 240;
const kSliderPreviewRatio = 0.5;

// ─── Composition slots → Figma component properties ──────────────────────────
//
// A CoUI composition slot (`child` / `leading` / `prefix` / …) accepts an
// arbitrary widget. Figma's nearest equivalent is a component property, and a
// slot needs TWO of them to be fully expressible:
//
//   · a BOOLEAN bound to the slot's whole region — the only way an *optional*
//     slot (`W?`) is reachable at all. A layer hidden inside a main component
//     cannot be revealed from an instance unless a boolean property governs
//     it, so without this a `Button` can never grow a leading icon and a
//     `TextField` can never grow an affix.
//   · a TEXT or INSTANCE_SWAP bound to what *fills* the region — the copy, or
//     which glyph.
//
// Both cannot live on one node: `componentPropertyReferences` is assigned
// wholesale by each bind helper, so a second call replaces the first. Hence the
// holder pattern below — the region is a frame (BOOLEAN) and the content is its
// single child (TEXT / INSTANCE_SWAP). The frame hugs and paints nothing, so it
// costs no pixels.
//
// ─── Naming: the content property carries the contract slot's own name ───────
//
// `Leading` — not `Leading icon`. The panel name IS the slot name, so a
// designer reading the properties panel and a developer reading
// `Button(leading: …)` are looking at the same list, and
// `figma_slot_swappability` can tell which slot a property covers (it matches
// name to slot, case-insensitively; `Leading icon` matched nothing and the slot
// read as unreachable).
//
// The presence BOOLEAN therefore cannot also be `Leading` — Figma allows one
// property per name whatever the types — so it takes `Show leading`. The prefix
// keeps the boolean out of the slot namespace rather than describing a second
// slot.
//
// A property whose region is NOT a contract slot keeps a plain descriptive name
// (`Value` / `Value text` on the two field components — the editable's typed
// text is state, not a `W?` slot).
//
// One operational constraint this naming has to be run against: a name may hold
// only ONE property, whatever the types, and `defineProp` reuses an existing one
// only when name AND type match. So a Figma file generated while a name carried
// a different type still has that stale property, `addComponentProperty` rejects
// the second, and nothing rolls that throw back — the entry is reported as
// failed and the half-built component stays on the page until the next run
// blanks it.
// `src/renames.ts` covers node names, not property names — until it covers both,
// such a file needs the stale property deleted by hand before the next run.
interface SlotNodes {
  /** The slot region — what the BOOLEAN "is this slot filled" property hides. */
  holder: FrameNode;
  /** The glyph filling it — what an INSTANCE_SWAP re-points. */
  icon?: InstanceNode;
  /** The copy filling it — what a TEXT property replaces. */
  text?: TextNode;
}

// The `Icon` variant an INSTANCE_SWAP property defaults to.
//
// One implementation, in `component-props.ts`. This file used to carry its own
// copy (as did `display.ts`), and they drifted: two threw on a missing glyph
// while a third returned `''`. The glyph argument is gone — see that function
// for why the slot's default cannot express one.
//
// Document index, not the current page — `Icon` is on `❖ Icon` and this
// builder is on its own page.
function iconSlotDefaultId(): string {
  return iconMainId(figma.currentPage);
}

// An icon-filled slot region, hidden.
//
// Hidden because every slot this file wires is `W?` and none of these
// components fills it by default — a `Button` is a labelled button, a
// `TextField` has no affix. Shipping them visible would change what the whole
// library looks like; shipping them absent would leave the slot unreachable.
// Hidden + a BOOLEAN property is the only arrangement that is both faithful to
// the default rendering and expressible.
//
// ─── The region is SIZED, not hugged ─────────────────────────────────────────
//
// `autoFrame` hugs both axes, and a hug is a value auto-layout computes — so
// while the region is hidden there is nothing to compute it from, and the
// holder measured 0×0 at the frame origin instead of a box beside the label.
// Revealing `Show leading` then produced an icon in the top-left corner rather
// than in the row, which is what the canvas showed.
//
// The fix is to state the box instead of deriving it: `size` is the size row's
// own `leadingIconStyle` / `trailingIconStyle` / `iconShapeIconStyle` /
// `iconStyle` extent, and it is
// exactly the box the widget gives the glyph — `Icon` renders into a
// `size × size` square. A stated box cannot collapse, hidden or not, and
// carries the same value the glyph inside it is scaled to.
//
// Both alignments centre, so the glyph sits in the middle of that square the
// way `Icon`'s own `Center` puts it there; the row's `counterAxisAlignItems:
// CENTER` then centres the square on the counter axis, which is where
// `button.dart`'s `crossAxisAlignment: .stretch` + `Icon`'s internal centring
// land a 16px glyph in a 40px row. `clipsContent` off so a designer who swaps
// in a larger component through the INSTANCE_SWAP property sees all of it
// rather than a cropped corner.
function iconSlot(
  name: string,
  glyph: string,
  lk: VarLookup,
  size: number | Dim,
  color: NormalizedColor | null,
  // The slot's INSTANCE_SWAP default variant (`iconSwapDefault`). The glyph is
  // drawn from it so the property's first bind changes nothing (see
  // `IconOpts.fromVariant`).
  fromVariant: ComponentNode | null,
): SlotNodes {
  // `makeIcon` FIRST, on purpose — it is the one call in this function that
  // can throw (Icon missing/mispinned), and nothing here has an undo. A
  // `holder` frame created before that throw is never appended to its
  // caller's component (the exception unwinds past `comp.appendChild(...)`)
  // and never cleaned up — it just sits wherever `figma.createFrame()`
  // landed it (`figma.currentPage`, i.e. whatever page the human happened to
  // have open), a debris fragment named "leading"/"trailing" next to
  // whatever else that page holds. Every one of a run's icon-bearing
  // failures left one of these; calling `makeIcon` before `holder` exists
  // means a failure here leaves nothing behind to clean up.
  const opts: IconOpts = glyphOpts(lk, color, size);
  opts.fromVariant = fromVariant;
  const icon = makeIcon(glyph, lk, opts);
  const holder = autoFrame(name, 'HORIZONTAL');
  holder.primaryAxisAlignItems = 'CENTER';
  holder.counterAxisAlignItems = 'CENTER';
  // Both axes stated outright rather than left to `resize`'s side effect, so
  // the box is the stated one and does not re-hug to whatever lands inside it.
  bindSize(holder, lk, size, size);
  holder.primaryAxisSizingMode = 'FIXED';
  holder.counterAxisSizingMode = 'FIXED';
  holder.clipsContent = false;
  holder.appendChild(icon);
  // FILL, so the instance follows the holder, which is the node bound to the
  // size token (§3-3 (a)). `setProperties({Size})` cannot pick a step per
  // variant either: a nested instance's variant property propagates across
  // the whole set (measured on 1,080 members).
  //
  // FILL sizes the BOX only; the glyph inside is already at the slot's side by
  // the time FILL is set. `makeIcon` fits a slot icon drawn from the swap
  // default to its side by size alone (the glyph sits on SCALE constraints and
  // follows the box) and gives the instance the `Icon` collection mode named
  // for that side, which is where the stroke comes from. Valid only here: the
  // holder is auto-layout and the instance is its in-flow child.
  icon.layoutSizingHorizontal = 'FILL';
  icon.layoutSizingVertical = 'FILL';
  holder.visible = false;
  return { holder, icon };
}

// A text-filled slot region, hidden. Used where the code styles the slot as
// text rather than as an icon — checkbox / toggle wrap `prefix` in
// `.bodySmall().medium()`, which is a typography statement, so a glyph would
// be the wrong shape for that slot.
function textSlot(
  name: string,
  copy: string,
  lk: VarLookup,
  labelStyle: ReturnType<typeof textStyleData>,
  color: NormalizedColor | null,
): SlotNodes {
  const holder = autoFrame(name, 'HORIZONTAL');
  holder.counterAxisAlignItems = 'CENTER';
  const text = makeLabel(copy, lk, typographyColorOpts(lk, labelStyle, color));
  holder.appendChild(text);
  text.layoutSizingHorizontal = 'HUG';
  text.layoutSizingVertical = 'HUG';
  holder.visible = false;
  return { holder, text };
}

// `textAlignVertical` → the field row's cross-axis alignment.
//
// Both field components state this and both had it hardcoded — TextField's row
// at `CENTER`, TextArea's at `MIN` — which happened to match `center` / `top`,
// the two values the data carries. The widget spends it the same way: it wraps
// the editable in `Align(Alignment(-1, resolved.textAlignVertical.y))`, so the
// choice IS where the text sits on the vertical axis of the box, which is
// exactly what an auto-layout row's counter-axis alignment says.
//
// The third value centres rather than throwing. `CoreVerticalAlign` has exactly
// three, all three are named here, so the fall-through is unreachable today —
// and a throw for a fourth would fail the entry and leave a half-built
// component on the page, which is a worse answer to "the exporter grew a value"
// than an alignment one step off.
// `textAlign` → a TEXT node's own horizontal alignment.
//
// The counterpart to `verticalAlignItems`, and it lands on a different kind of
// node for a reason: the vertical choice is where the editable sits in the box
// (the row's cross-axis alignment), while the horizontal one is how the glyphs
// sit inside their own line box — which is the text node's property, not the
// row's. Writing it on the row would centre the box and leave the words
// left-aligned inside it.
//
// Three of Flutter's six `TextAlign` values map straight across; `justify`,
// `start` and `end` do not have Figma members, and `start`/`end` are the LTR
// defaults this library renders at, so they resolve to LEFT/RIGHT here. A
// fourth value would fall through to LEFT rather than throw — a whole component
// left half-built on the page is a worse answer to "the exporter grew a value"
// than an alignment one step off (the same trade `verticalAlignItems` states).
function textAlignHorizontal(choice: string): 'LEFT' | 'CENTER' | 'RIGHT' | 'JUSTIFIED' {
  if (choice === 'center') return 'CENTER';
  if (choice === 'right' || choice === 'end') return 'RIGHT';
  if (choice === 'justify') return 'JUSTIFIED';
  return 'LEFT';
}

function verticalAlignItems(choice: string): 'MIN' | 'CENTER' | 'MAX' {
  if (choice === 'top') return 'MIN';
  if (choice === 'bottom') return 'MAX';
  return 'CENTER';
}

// `CoreCrossAxisAlignment` → the same Figma property `verticalAlignItems` writes,
// which is why the two are read TOGETHER rather than one winning.
//
// TextField states both, and they are different statements about different boxes:
// `textAlignVertical` positions the decorated container's whole content
// (`Align(Alignment(-1, y))` around the Padding), and `crossAxisAlignment` is the
// inner `Row(crossAxisAlignment: …)` that holds prefix / editable / suffix. On the
// canvas those two boxes are ONE auto-layout frame, and a frame carries one
// counter-axis alignment for all its children — the same collision `rowCounterAxis`
// documents for `Basic`'s two slot alignments.
//
// They agree today (both centre), so this changes no pixel; what it changes is
// that `crossAxisAlignment` is now read at all, and that a divergence is refused
// instead of silently resolving to whichever field the builder happened to read.
// Splitting the frame in two is the way to honour both, and that means deciding
// the inner row's height — a design decision, not a wiring one.
//
// `stretch` and `baseline` have no counter-axis keyword: stretch is a child's own
// `layoutAlign = 'STRETCH'` and baseline has no Figma equivalent at all. Neither
// is stated here, and both are refused rather than approximated by CENTER.
function fieldRowCounterAxis(
  cross: { readonly choice: string },
  vertical: { readonly choice: string },
): 'MIN' | 'CENTER' | 'MAX' {
  const fromVertical = verticalAlignItems(vertical.choice);
  const fromCross: Record<string, 'MIN' | 'CENTER' | 'MAX'> = {
    start: 'MIN',
    end: 'MAX',
    center: 'CENTER',
  };
  const mapped = fromCross[cross.choice];
  if (mapped === undefined) {
    throw new Error(
      `text_field.crossAxisAlignment: "${cross.choice}" has no Figma ` +
        'counter-axis keyword. `stretch` is the CHILD\'s `layoutAlign` and ' +
        '`baseline` has no equivalent, so neither can be written on the row — ' +
        'they need the children handled one by one, which is a design decision. ' +
        `Known: ${Object.keys(fromCross).join(', ')}.`,
    );
  }
  if (mapped !== fromVertical) {
    throw new Error(
      'text_field.crossAxisAlignment / textAlignVertical disagree ' +
        `("${cross.choice}" is ${mapped}, "${vertical.choice}" is ` +
        `${fromVertical}). Both land on the one counter-axis alignment this ` +
        'frame has, so only one could be honoured and nothing on the canvas ' +
        'would say which. Give the inner prefix/editable/suffix row a frame of ' +
        'its own to honour both — which means deciding its height.',
    );
  }
  return mapped;
}

// Centring divisor. Named the way `primitives-layout.ts` names it, so the
// arithmetic reads as "half of" rather than as an unexplained 2.
const kHalf = 2;

// `textAlign` → which end of the input stack the caret stands at.
//
// The caret sits where the text starts, so this reads the same field
// `textAlignHorizontal` does — but it answers in the two vocabularies an
// absolutely positioned node needs: the offset that puts it there now, and the
// Figma constraint that keeps it there when a designer drags the instance
// wider. Giving only the offset would pin the caret to a width the preview
// happened to be built at.
//
// `JUSTIFIED` lands on MIN with the two `start`-like values: justified text
// still begins at the leading edge, and only its interior spacing differs.
function caretPlacement(
  choice: string,
  contentWidth: number,
  caretWidth: number,
): { x: number; horizontal: 'MIN' | 'CENTER' | 'MAX' } {
  const align = textAlignHorizontal(choice);
  if (align === 'CENTER') {
    return { x: (contentWidth - caretWidth) / kHalf, horizontal: 'CENTER' };
  }
  if (align === 'RIGHT') return { x: contentWidth - caretWidth, horizontal: 'MAX' };
  return { x: 0, horizontal: 'MIN' };
}

// ─── Button ──────────────────────────────────────────────────────────────────

// Data-driven from coui_core: BUTTON.variants.defaultsByVariant
// (colors/radius/border overrides) + BUTTON.sizes.defaultsBySize
// (padding/height/gap/label/icon). Structure stays here; every visual value
// comes from components.json. A variant's `radius`/`borderWidth` override
// `fields.borderRadius` / a plain 1px default exactly like the Dart resolver's
// own merge chain (`variantStyle.field ?? fields.defaultField`,
// `core/style-contract.md`).
//
// ─── The State axis ──────────────────────────────────────────────────────────
//
// `button.axes` promotes Variant (12) × Size (6) × Enabled (2); `axes.state` is
// null and stays null — a button's states are not a Core enum the exporter could
// carry, they are Flutter `WidgetState` members. So the axis is DECLARED here,
// the way a pose is, and its values are the rungs of the resolver's own ladder.
//
// ─── Why one enum and not three booleans ─────────────────────────────────────
//
// This was `Enabled × Selected × Hover` — three independent booleans, on the
// reasoning that `buildDecoration(Set<WidgetState>)` takes a *set* and one enum
// cannot say "selected AND hovered".
//
// The premise is true and the conclusion does not follow. That resolver folds
// the set into exactly ONE branch through a priority ladder, so however many
// states are simultaneously true, a button only ever paints one of them. A
// canvas member is a RENDERING, not an input set — naming the rung it lands on
// is the whole of what a member can carry, and "selected and hovered" renders
// as selected because selected outranks hover.
//
// Three booleans could not say that either: they enumerated 8 poses for 5
// renderings and left a designer to know which of the duplicates was real.
//
// It also cost the axis its two ends. There was no rung for `pressed` at all,
// and `focus` was argued away on the grounds that `focusedBackgroundColor` is
// byte-identical to hover on the only two variants that set it — true, and
// beside the point, because the variants with a `stateLayer` distinguish
// focus by the RAMP's middle weight, not by that field.
//
// The order below is the ladder's own, read top-down; `disabled` sits last
// because it is where the ladder starts and the least interesting to click to.
//
// ─── The ladder (button_style.dart) ──────────────────────────────────────────
//
//   disabled
//     → selected   (useSelectedState && selectedBackgroundColor != null)
//     → pressed    (pressedBackgroundColor ?? hoverBackgroundColor)
//     → hover | focus-as-hover
//     → resting
//   …and over all of it except disabled/selected, the state layer:
//   pressed > focus > hover, composited over the RESTING fill.
//
// ─── Where the `Clickable` went ──────────────────────────────────────────────
//
// `button.dart` builds `Clickable(decoration: …, child: Row([leading, Gap,
// label, Gap, trailing]))` and then wraps the result in `FocusOutline`. There
// is no separate node for the `Clickable` here because there is nothing left
// for it to be: it is the node that carries the decoration, the padding and
// the row, and that node is this component's root. The variant chrome painted
// below (fill / border / radius / padding / itemSpacing) is precisely what the
// widget hands to `Clickable.decoration` — the two are the same surface, not a
// parent and a child.
//
// Instantiating the `Clickable` component instead is not an option and would
// not be an improvement: a Figma instance's subtree is fixed, so nothing can be
// placed *inside* one, and a wrapper whose entire job is to hold a caller's
// widget has no content of its own to instantiate around the label.
//
// The focus *ring* is a different surface from any of this
// (`fields.focusOutlineStyle` → a nested `CoreFocusOutlineStyle` drawn by
// `FocusOutline`) and rides on `State=focus` rather than replacing it.
//
// The ladder's rungs, in the order a designer reads them. `disabled` last: it is
// where the ladder starts, and the one nobody clicks through looking for.
const kButtonStates = [
  'enabled',
  'hover',
  'focus',
  'pressed',
  'selected',
  'disabled',
] as const;

type ButtonState = (typeof kButtonStates)[number];

// One combination's name, composed through the shared composer rather than
// concatenated here — so a member this builder mints and a member
// `enumerateAxisCombos` expects are produced by the same code, and an axis in
// the wrong order throws instead of minting a second name for one pose.
function buttonVariantName(
  variant: string,
  size: string,
  state: ButtonState,
  // Defaulted rather than required: every caller here composes a button with a
  // label in it, which is `CoreButtonShape.rectangle` — the widget's own
  // `this.shape = CoreButtonShape.rectangle`. A caller that wants the square
  // affordance says so; the sixteen that did not kept working when the axis
  // arrived, instead of each spelling a fourth value to stand still.
  shape: string = 'rectangle',
): string {
  return composeVariantName([
    ['Variant', variant],
    ['Size', size],
    ['State', state],
    ['Shape', shape],
  ]);
}

interface ButtonSlots {
  label: TextNode;
  leading: SlotNodes;
  trailing: SlotNodes;
  ring: FocusRingNodes;
  /** Null on the states that carry no overlay, and on variants with no ramp. */
  stateLayer: RectangleNode | null;
  /** `Shape` is square or circle — the member draws a glyph, not a label. */
  shaped: boolean;
}

// Glyphs the leading / trailing slots default to. Both are real Lucide names
// carried by `icons.json`; a designer re-points them through the
// INSTANCE_SWAP properties defined at the end of the builder.
const kButtonLeadingGlyph = 'check';
const kButtonTrailingGlyph = 'chevron-down';

// The label a member draws — `CoreButtonStyle.labelStyleFor` for a Button no
// caller has styled: the size row's role, with the weight the variant's
// `labelStyle` states on top (stated by the seven variants that draw a filled
// or outlined button and absent on the menu rows and `fixed`, which keep the
// role's own). Only that slot's weight is read, as `labelStyleFor` reads it:
// the size row's role owns the rest of the label. The canvas has no
// composer, so there is no `labelStyle` of its own that could state a role or
// a weight and make the variant's step aside — the variant's weight always
// lands.
//
// A weight off the role's own makes the label depart from its role
// (`roleDeparture('weight')`), so those seven variants' labels are drawn
// without a text style, at the primitive size steps — a text style carries the
// weight with the rest of its bundle and cannot be kept under an overlay.
function buttonLabelStyle(
  row: Parameters<typeof textStyleData>[0],
  variantLabel: Parameters<typeof textStyleData>[0],
): ReturnType<typeof textStyleData> {
  const role = textStyleData(row);
  const variantWeight = variantLabel?.fontWeight;
  if (variantWeight == null) return role;
  return mergeTextStyleData(role, textStyleData({ role: null, fontWeight: variantWeight }));
}

// `async` (unlike every other builder here) purely to let this loop yield —
// see `reportSubProgressAndYield` in helpers.ts. Button is the one builder
// with enough variant combos for a real Figma document to spend real minutes
// on it fully synchronously, which froze both the plugin UI's progress bar and
// Figma itself for that whole span with no way to tell "still working" from
// "actually hung." Every caller already `await`s `RegistryEntry.build()`'s
// result for exactly this reason.
async function buildButton(page: PageNode, lk: VarLookup): Promise<ComponentSetNode> {
  const variantData = new Map(Object.entries(BUTTON.variants.defaultsByVariant));
  const sizeData = new Map(Object.entries(BUTTON.sizes.defaultsBySize));
  // `disableHoverEffect` — the recipe's switch for whether hover chrome is
  // painted at all, and the only thing that decides what `State=hover` shows.
  // `button.dart` spends it inside the state set itself:
  //
  //   if (_hovered && !disableHoverEffect) WidgetState.hovered
  //
  // so with the switch on, a hovered button keeps its IDLE decoration — the
  // hover tokens are still in the recipe and nothing ever resolves against
  // them. Read here rather than assumed off, because assuming it is what makes
  // a Core flip invisible: the hover members would keep asserting a hover the
  // widget suppresses, and the two pictures would differ with every gate green.
  // It is `false` in the data today, so the canvas is unchanged.
  const hoverPaints = !BUTTON.fields.disableHoverEffect.v;
  // `Shape` — `CoreButtonShape`, read off the exported enum rather than spelled
  // as a literal, so the canvas cannot hold a member the enum does not have
  // (the reason Badge wires its second axis the same way).
  //
  // This axis is what absorbs the separate `IconButton` set the designer drew.
  // The two were never different components: every box in that set is
  // already Button's own size row — sm 32x32 / md 40x40 / lg 48x48 against
  // Button's `height` 32/40/48. The glyph is the row's `iconShapeIconStyle`
  // (14/16/18/20/24/28 for xs…xl2), a step larger than the `leadingIconStyle`
  // beside a label, and it sits centred in a box at least `height` wide. The
  // space left around it, `(height - glyph) / 2` = 5/8/11/14/16/18, is what
  // centring a glyph in a box you already have leaves — `iconShapePadding` is
  // zero. A square button IS `Button(shape: .square)`, and the code has said
  // so since the enum's own doc ("Square button with equal width and height").
  //
  // Full cross product, not the four variants and three sizes the drawn set
  // carried. A sparse axis is worse than no axis here: nothing in the widget
  // forbids `shape: .square` on any variant or size, so a designer choosing
  // one the canvas skipped would land on a fallback member and be quietly
  // wrong. (`Clickable` IS sparse, but for the opposite reason — its missing
  // combinations are ones `clickable.dart` returns early out of and the app
  // cannot reach.)
  const shape = BUTTON.axes.other.find((o) => o.enum === 'CoreButtonShape');
  if (!shape) {
    throw new Error(
      'Button: CoreButtonShape is gone from the exported axes — the canvas ' +
        'has a Shape axis that nothing in the contract now backs.',
    );
  }
  // `State` is declared here, not derived from `axes` — see the note above the
  // ladder. Everything else still comes from the schema, so a variant or size
  // added in Dart lands on the canvas without touching this file.
  const combos = enumerateAxisCombos([
    ...axisSpecsOf(BUTTON.axes).filter((spec) => spec.axis !== 'Enabled'),
    { axis: 'State', values: [...kButtonStates] },
    { axis: 'Shape', values: shape.members },
  ]);
  // The glyphs are drawn from the swap properties' own defaults, so the first
  // bind leaves them where they are (see `iconSlot`).
  const leadingSwap = iconSwapDefault(page, 'Button', 'Leading', iconSlotDefaultId());
  const trailingSwap = iconSwapDefault(page, 'Button', 'Trailing', iconSlotDefaultId());
  const mount = mountSet(page, 'Button', combos);
  const slots: ButtonSlots[] = [];
  for (let comboIndex = 0; comboIndex < combos.length; comboIndex++) {
    const comboName = combos[comboIndex];
    // Reported/yielded BEFORE the combo it names is built — a report after
    // every single combo would mean the label always trails what's actually
    // happening by one; reporting the one about to start reads as live
    // instead of one step stale, and costs nothing extra (still exactly one
    // yield per combo).
    await reportSubProgressAndYield(comboIndex, combos.length);
    const combo = parseVariantKey(comboName);
    const v = variantData.get(combo['Variant']);
    // The row the app renders for this size — `resolveSizeRow`'s answer,
    // not `md` — so a tier the table stops stating draws its fallback.
    const s = sizeRowFor(sizeData, combo['Size'], BUTTON.axes.size.members);
    if (!v) throw new Error(`Button: no data for combo "${comboName}"`);
    const state = combo['State'] as ButtonState;
    const idleBorder = optField<Color>(v, 'borderColor');
    const selectedBg = optField<Color>(v, 'selectedBackgroundColor');
    const borderWidth = optField<Dim>(v, 'borderWidth');
    // The three things `shape` changes, and nothing else — the fill, border,
    // foreground, state layer and ring below are the same picture the
    // rectangle of this variant/size/state draws. `button_style.dart` says the
    // same in the same order: the shape swaps the padding for
    // `iconShapePadding`, floors the width at the height, and (circle only)
    // swaps the radius for `circleBorderRadius`.
    const shaped = combo['Shape'] !== 'rectangle';
    // The same precedence `CoreButtonStyle.borderRadiusForSize` states: a
    // variant's own `radius` when it states one, else this size row's
    // corner — the control height × 0.25, so each `Size` column draws its
    // own (xs 6 … xl2 16). `square` takes the same row: it is a rectangle
    // whose width is floored at the height, not a different corner.
    const radius =
      combo['Shape'] === 'circle'
        ? BUTTON.fields.circleBorderRadius.topLeft
        : (optField<Dim>(v, 'radius') ?? s.borderRadius.topLeft);
    // `CoreButtonStyle.paddingFor`: the size row's insets with the inline
    // pair replaced by the variant's `paddingInline` when it states one
    // (`link` / `plain` sit flush, §5-6). The block pair stays the size's.
    const inline = optField<Dim>(v, 'paddingInline');
    const padding = shaped
      ? BUTTON.fields.iconShapePadding
      : inline == null
        ? s.padding
        : { l: inline, t: s.padding.t, r: inline, b: s.padding.b };
    // `useSelectedState` / `useFocusedAsHover` gate their rungs the same way
    // the resolver does: a state a variant does not opt into falls through to
    // the next one down, so `State=selected` on the variants without it
    // renders as rest rather than as an invented look — and so does
    // `State=focus` on every variant but the two menu rows.
    const takesSelected =
      state === 'selected' && Boolean(optField(v, 'useSelectedState')) && Boolean(selectedBg);
    const focusBorrowsHover =
      state === 'focus' && Boolean(optField(v, 'useFocusedAsHover'));
    // Per-state chrome, mirroring `button_style.dart`'s
    // `buildDecoration` / `buildTextStyle` / `buildIconTheme`.
    let bg: Color;
    let border: Color | undefined;
    let fg: Color;
    let iconFg: Color;
    if (state === 'disabled') {
      bg = v.disabledBackgroundColor;
      border = optField<Color>(v, 'disabledBorderColor');
      fg = v.disabledForegroundColor;
      // `disabledIconColor` is unset on every variant, so the icon
      // follows the disabled foreground — the resolver's own fallback.
      iconFg = v.disabledForegroundColor;
    } else if (takesSelected && selectedBg) {
      bg = selectedBg;
      border = optField<Color>(v, 'selectedBorderColor') ?? idleBorder;
      fg = optField<Color>(v, 'selectedForegroundColor') ?? v.foregroundColor;
      // Selected icon follows the selected foreground (contrast on the
      // selected fill) — mirrors the label.
      iconFg = fg;
    } else if (state === 'pressed') {
      // Every field falls through to hover's — only the container-swap
      // variants (`primary`, `destructive`) state a pressed fill, so on the
      // rest this rung paints exactly what hover does (and, where the variant
      // carries a ramp, the wash below is what separates the two). That is
      // not a gap to fill here: it is what the widget renders, and inventing
      // a pressed look on the canvas would be the canvas lying about the app.
      bg = optField<Color>(v, 'pressedBackgroundColor') ?? v.hoverBackgroundColor;
      border =
        optField<Color>(v, 'pressedBorderColor') ??
        optField<Color>(v, 'hoverBorderColor') ??
        idleBorder;
      fg =
        optField<Color>(v, 'pressedForegroundColor') ??
        optField<Color>(v, 'hoverForegroundColor') ??
        v.foregroundColor;
      iconFg = fg;
    } else if ((state === 'hover' && hoverPaints) || focusBorrowsHover) {
      // `focus` is the resting look plus the ring — the ring is the focus
      // indicator, and a second, weaker one (a hover-coloured fill, an 8%
      // wash) is a change too small to be what tells a keyboard user where
      // they are. The one exception is the rows that fold focus into hover
      // on purpose (`useFocusedAsHover`: the two menu rows), which keep
      // their own `focusedBackgroundColor` first, as `buildDecoration` does.
      // `focusedBackgroundColor` only where the variant opted in; otherwise the
      // plain hover fill, which is what the resolver's inner `if` says.
      bg =
        (focusBorrowsHover ? optField<Color>(v, 'focusedBackgroundColor') : undefined) ??
        v.hoverBackgroundColor;
      border = optField<Color>(v, 'hoverBorderColor') ?? idleBorder;
      fg = optField<Color>(v, 'hoverForegroundColor') ?? v.foregroundColor;
      iconFg =
        optField<Color>(v, 'hoverIconColor') ??
        optField<Color>(v, 'hoverForegroundColor') ??
        v.foregroundColor;
    } else {
      bg = v.backgroundColor;
      border = idleBorder;
      fg = v.foregroundColor;
      iconFg = optField<Color>(v, 'iconColor') ?? v.foregroundColor;
    }

    // This node IS the `Clickable`: everything set on it below —
    // decoration, padding, the row it lays out — is what
    // `button.dart` hands to `Clickable(decoration:, child: Row(…))`.
    // See the section note above for why there is no second node.
    const comp = mount.getOrCreate(comboName);
    comp.layoutMode = 'HORIZONTAL';
    comp.primaryAxisSizingMode = 'AUTO';
    comp.counterAxisSizingMode = 'AUTO';
    comp.primaryAxisAlignItems = 'CENTER';
    comp.counterAxisAlignItems = 'CENTER';
    bindPad(comp, lk, padding);
    comp.setBoundVariable('itemSpacing', lk.space(dimVal(s.iconLabelGapStyle.size)));
    bindRadiusN(comp, lk, radius);
    // A content surface on both platforms when its RESTING fill paints — the
    // same `hasFill` answer both resolvers gate the material on: Flutter
    // reads `theme.surfaceFor(role)` (the share folded into every state's
    // fill, the frost and edge around the box), and the Web twin carries
    // `webSurfaceMarkerFor(role)`. A variant that rests unfilled (ghost, link,
    // plain, menu, …) is no surface in any state — its hover wash is a wash,
    // not a box to frost — so it keeps the single fill. Whichever fill this
    // state paints is what the material layer carries; the state layer below
    // stays over it at its own weight, as `alphaBlend` composites it over the
    // shared resting fill.
    if (paintsFill(colorData(v.backgroundColor))) {
      applySurfaceMaterial(comp, lk, colorData(bg), 'content', { radius: radius });
    } else {
      fillData(comp, lk, colorData(bg));
    }
    borderData(comp, lk, colorData(border), borderWidth ? dimVal(borderWidth) : 1);
    // A button that states no cast takes the one a style contributes, when it
    // has a filled box to throw it (`hasFill` on both platforms). The cast
    // motion decides the member: the default hides the cast while the button
    // is engaged — hovered or pressed — and `reverse` casts only then.
    const castMotion = BUTTON.fields.castMotion.choice as string;
    const engaged = state === 'hover' || state === 'pressed';
    const castsHere = castMotion !== 'noShadow' && (castMotion === 'reverse' ? engaged : !engaged);
    if (castsHere && paintsFill(colorData(bg))) addControlShadow(comp, lk);

    // `leading` / `trailing` are `W?` icon slots — the size comes from
    // the size row's own icon style, the colour from the state above. A
    // shaped member has no label to sit beside, so its glyph is the row's
    // `iconShapeIconStyle` (a step larger than the slot's), and both slots
    // take that one size, the way the widget seeds them from a single
    // `iconSize` (`CoreButtonStyle.iconSizeFor`).
    const leading = iconSlot(
      'leading',
      kButtonLeadingGlyph,
      lk,
      shaped ? s.iconShapeIconStyle.size : s.leadingIconStyle.size,
      colorData(iconFg),
      leadingSwap.variant,
    );
    comp.appendChild(leading.holder);
    // A shaped button's glyph is not a slot you turn off — it is the whole
    // content, and the box is sized for it and nothing else. So it is left
    // visible and UNBOUND, the way the focus ring is on the members whose
    // state already accounts for it. The `Leading` swap stays bound below, so
    // which glyph it is remains the designer's choice; only "is there one" is
    // settled by the shape.
    if (shaped) leading.holder.visible = true;

    // labelStyle carries typography (role/size/weight); the state
    // carries colour, so it wins outright — `typographyColorOpts`
    // rather than `textLabelOpts`, which would let a colour the
    // exporter later starts emitting on `labelStyle` silently
    // override the per-state foreground. The variant's weight rides on the
    // size row's role (`buttonLabelStyle`).
    const label = makeLabel(
      '버튼',
      lk,
      typographyColorOpts(
        lk,
        buttonLabelStyle(s.labelStyle, optField<TextLeaf>(v, 'labelStyle')),
        colorData(fg),
      ),
    );
    comp.appendChild(label);
    label.layoutSizingHorizontal = 'HUG';
    label.layoutSizingVertical = 'HUG';
    // Hidden on the shaped members, and hidden by the NODE rather than by the
    // `Child` property: the padding is zero and the width is floored at the
    // height, so a word in there would be clipped by the box that shape asked
    // for. It stays a real text node so the member keeps the same shape of
    // children as its rectangle sibling — what changes is which one is drawn.
    if (shaped) label.visible = false;
    const trailing = iconSlot(
      'trailing',
      kButtonTrailingGlyph,
      lk,
      shaped ? s.iconShapeIconStyle.size : s.trailingIconStyle.size,
      colorData(iconFg),
      trailingSwap.variant,
    );
    comp.appendChild(trailing.holder);

    // Lock this size's height. The width argument is a PLACEHOLDER, not a
    // measurement — `resize` needs one and the next line throws it away.
    //
    // This read `comp.width`, and that was the single most expensive line in
    // the loop. At this point `comp` is a hug auto-layout row whose three
    // children were appended moments ago, so answering `.width` obliges Figma
    // to shape the label, measure both icon holders and run the row — a full
    // layout flush, per combo, whose result the `AUTO` on the next line
    // discards. 432 flushes per Button run, for a number nothing reads.
    //
    // Measured, because the reason matters: with the `AUTO` restore, `0.01`
    // and the real width both settle at the same box (67x40 on a Button-shaped
    // probe). WITHOUT it, `0.01` survives as a FIXED 0.01 — so the width is
    // recomputed by the restore, not clamped by `resize`, and the argument
    // genuinely cannot matter as long as the line below runs.
    // Timed as `geom`, resize included. The two mutations and the read are
    // one unit: the resize dirties the layout and the read is what makes
    // Figma settle it, so timing only the read would put the flush's cost on
    // whichever line happened to touch the node next. This is also the one
    // span in the loop whose cost could scale with the whole document rather
    // than with this button — which is the shape the unexplained recycle-path
    // penalty has, and the reason this block is bracketed rather than left in
    // the remainder.
    // The row a density moves — bound so a frame that pins `compact` draws
    // the 32 row the platforms draw, not the authored 40 with compact padding
    // inside it. The ring and the state layer are STRETCH-pinned and follow.
    const rowHeight = lk.controlHeightOrNull(dimVal(s.height));
    const box = timedGeom(() => {
      comp.resize(0.01, dimVal(s.height)); // resets both axes to FIXED
      if (rowHeight) comp.setBoundVariable('height', rowHeight);
      comp.primaryAxisSizingMode = 'AUTO'; // restore width hug — recomputes width
      // A shaped button is at LEAST square, not exactly square — the widget
      // states `minWidth: … ?? height`, a floor, so a wide child still makes a
      // wide button. Figma's own `minWidth` is that same floor, which is why
      // the hug above is restored for every member: a fixed `resize(h, h)`
      // here would draw a box the widget does not promise, and would clip the
      // moment a designer swapped in a wider glyph or turned the label back on.
      if (shaped) {
        comp.minWidth = dimVal(s.height);
        if (rowHeight) comp.setBoundVariable('minWidth', rowHeight);
      }
      // Read ONCE. Every read of a laid-out property flushes the layout Figma
      // was holding, and the two overlays below both want the same box — read
      // per overlay and the second one pays for a flush that the first already
      // did, per combo. Both overlays are absolute-positioned, so neither
      // changes the hug between here and there and the values stay true.
      return { width: comp.width, height: comp.height };
    });
    const compWidth = box.width;
    const compHeight = box.height;
    // `Clickable(focusOutlineStyle: resolved.focusOutlineStyle)` — the ring
    // the button wears when the keyboard reaches it. Hidden, behind a
    // BOOLEAN, for the reason `form-controls.ts` records once: focus is a
    // pose, and one more axis on a set that already has five is a
    // node-identity change needing a `renames.ts` entry, while a property
    // is additive. The ring's width comes from the field — the note that
    // said `CoreFocusOutlineStyle`'s width was absent from the export is
    // no longer true, and it was the reason this ring did not exist.
    //
    // After the resize: the ring is measured from the component's box and
    // the height is only final here.
    const ring = focusRing(comp, lk, {
      outline: BUTTON.fields.focusOutlineStyle,
      // The slot's OWN colour, unlike the two field builders above: those
      // overwrite it with the variant row's `focusRingColor` because their
      // resolvers do, and Button's variant table has no such column — the
      // ring is `focusOutlineStyle.borderColor` for every variant.
      color: colorData(BUTTON.fields.focusOutlineStyle.borderColor),
      corner: radius,
      width: compWidth,
      height: compHeight,
      // A focused button wears its ring — the state says so, and a member that
      // named the state but did not draw it would be the axis lying. The
      // BOOLEAN below still exists for the other five, where the ring is a
      // pose a designer opts into rather than the state itself.
      visible: state === 'focus',
    });

    // ─── The state layer ─────────────────────────────────────────────────────
    //
    // `button_style.dart` composites ONE overlay for whichever of
    // pressed > hover is active, at the variant's own ramp weight, and
    // always over the RESTING fill — never over the branch above, which is why
    // the variants that carry a ramp (`secondary`, `tonal`, `outline`, `ghost`) leave
    // their hover/pressed colours equal to rest and let this carry the whole
    // change. The ramp states a `focus` weight too, and `Button` does not draw
    // it: a focused button is its resting look plus the ring.
    //
    // Drawn as a rectangle rather than baked into the fill because the ramp has
    // rungs and a pre-composited colour token can only have as many values as
    // someone remembered to author.
    //
    // Child 0, so it sits over the fill and under the label — the same
    // stacking `alphaBlend(fg@a, bg)` produces.
    const ramp = optField<{ hover: number; focus: number; pressed: number }>(v, 'stateLayer');
    const layerAlpha =
      ramp == null || state === 'disabled' || takesSelected
        ? null
        : state === 'pressed'
          ? ramp.pressed
          : state === 'hover'
            ? ramp.hover
            : null;
    let stateLayer: RectangleNode | null = null;
    if (layerAlpha != null) {
      stateLayer = figma.createRectangle();
      stateLayer.name = 'state layer';
      stateLayer.resize(compWidth, compHeight);
      stateLayer.cornerRadius = dimVal(radius);
      // The variant's own foreground — what the resolver blends. Its opacity is
      // the ramp weight, so the token stays bound and follows the theme.
      fillData(stateLayer, lk, colorData(v.foregroundColor));
      // A literal here: a layer's opacity binds to a percent FLOAT
      // (`VarLookup.opacity`, `bindLayerOpacity`), but this layer binds no
      // rung, so the `state-layer/*` aliases are authoring registry the ramp is
      // written against — the same arrangement `line-height/control` has.
      stateLayer.opacity = layerAlpha;
      // `insertChild` first, then pin: `pinAbsolute` appends, so pinning and
      // then moving to index 0 reparents the same node twice. Index 0 is where
      // this has to sit — over the fill, under the label.
      comp.insertChild(0, stateLayer);
      pinInFlow(comp, stateLayer);
      stateLayer.x = 0;
      stateLayer.y = 0;
      stateLayer.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };
    }
    slots.push({ label, leading, trailing, ring, stateLayer, shaped });
  }
  // The last combo's labels. No yield follows it, so without this they would
  // get their styles after `finish()` has put the member back in its set — a
  // write on the 972-member set instead of on a loose node
  // (`text-style-attach.ts`).
  await drainTextStyleAttach();
  const set = mount.finish();
  // The property pass gets a mark of its own: `finish:done` only says the set
  // was reassembled, and a run that dies binding 972 members would otherwise
  // read as one that died at the finish line.
  markStep('Button:props');
  // Properties are defined AFTER `finish()`, on the set, because that is the
  // only moment the owner exists: `addComponentProperty` on a set member
  // throws, and during the loop above a freshly created variant has no parent
  // yet (`mountSet` combines at the end), so `propertyOwner()` would hand back
  // the member itself and scatter one definition per variant.
  //
  // `Child` is the label node: `button.dart` lays out `Row([leading, Gap,
  // child, Gap, trailing])` and the label IS `child` — the widget has no
  // separate label field. A TEXT property is the ceiling for it (the words are
  // editable, the widget is not); making it swappable would need a `Text`
  // component in the REGISTRY, which the library decided against.
  const childId = defineProp(set, 'Child', 'TEXT', '버튼');
  const showLeadingId = defineProp(set, 'Show leading', 'BOOLEAN', false);
  const leadingId = defineProp(set, 'Leading', 'INSTANCE_SWAP', leadingSwap.id);
  const showTrailingId = defineProp(set, 'Show trailing', 'BOOLEAN', false);
  const trailingId = defineProp(set, 'Trailing', 'INSTANCE_SWAP', trailingSwap.id);
  const showFocusId = defineShowFocusRing(set);
  // Adopted, not invented: a designer added `Show child` to this set by hand
  // and bound it to the label, and it has been surviving regeneration on the
  // recycled node. `defineProp` matches by name and type, so this reuses that
  // exact property id rather than minting a second one — what changes is that
  // the builder now knows about it, which is the difference between a binding
  // that happens to persist and one that is stated.
  //
  // Default `true`, because `Button.child` is `required` and non-nullable on
  // both platforms — a button always has one. Switching it off is a PREVIEW
  // affordance (see this button without its words), not a widget state, and
  // that is worth saying out loud because the picture it makes — a glyph and
  // no label — now has a real code spelling that this one does not:
  // `Button(shape: .square, child: Icon(…))`, the axis above.
  const showChildId = defineProp(set, 'Show child', 'BOOLEAN', true);
  for (const s of slots) {
    // The two slots a shaped member settles rather than exposes. A bound
    // `visible` has one source of truth — the property — so binding the glyph
    // here would hand every square member the set-wide `Show leading=false`
    // and empty the box that exists to hold it, and binding the label would
    // hand it `Child`'s default words with nowhere to put them. Same reasoning
    // the ring below is left unbound on the focus members.
    if (!s.shaped) {
      bindTextProp(s.label, childId);
      bindVisibleProp(s.label, showChildId);
      bindVisibleProp(s.leading.holder, showLeadingId);
      bindVisibleProp(s.trailing.holder, showTrailingId);
    }
    // NOT bound on the focus members. A bound `visible` has exactly one source
    // of truth — the property — so binding here would hand every focus member
    // the default `false` and take the ring straight back off the state that
    // exists to show it. On the other five the ring stays a pose behind the
    // BOOLEAN, which is what it was for.
    // (`bindShowFocusRing` leaves a ring that is already visible unbound; the
    // state already says why it is there.)
    bindShowFocusRing(s.ring, showFocusId);
    // Bound on every member, shaped included: WHICH glyph a square button
    // draws is still the designer's choice — only whether there is one is
    // settled by the shape.
    bindSwapProp(s.leading.icon!, leadingId);
    bindSwapProp(s.trailing.icon!, trailingId);
  }
  // No `layoutSet` override here: at this many variants a 560px-wide wrap is
  // a hundred-odd rows tall. `finish()` already applied `defaultSetLayout`,
  // whose ceil(sqrt(n)) grid keeps the block roughly square whatever `n` is.
  //
  // The number is kept out of the call parentheses on purpose: written inside
  // them, this sentence read to the literal ratchet as a call this builder
  // makes — and it makes none, so the count would have been of prose.
  return set;
}

// ─── TextField ───────────────────────────────────────────────────────────────

// Data-driven from coui_core: TEXT_FIELD.fields (borderRadius/borderWidth/
// activeBorderWidth/rowSpacing/affixColor) + TEXT_FIELD.sizes.defaultsBySize (padding/minHeight/
// iconStyle/baseTextStyle) + TEXT_FIELD.variants.defaultsByVariant (fill,
// border, value and placeholder colours).
//
// ─── The field's fill and border colour, and where they come from now ────────
//
// Two notes stood here in turn and both are gone. The first said
// `CoreTextFieldStyle` "has no variant enum", the container fill and border
// colour were "not a Style field at all", and the resolver "reaches the ambient
// scheme directly" — all three false. `CoreTextFieldVariant` exists with
// `defaultVariant` / `error` members, `CoreTextFieldStyle.defaultsByVariant`
// states per variant `backgroundColor` (surface), `borderColor` (outline
// on the clean variant, error on the other), `focusRingColor` and a dedicated
// disabled trio, and `text_field_style.dart` resolves them from exactly that
// table — `final vs = CoreTextFieldStyle.defaultsByVariant[variant]!`, then
// `vs.borderColor` / `vs.disabledBorderColor` into the `BoxDecoration`.
//
// The second said the table nevertheless arrived `{}`, so the values here were
// hand-copied literals wearing a preview-only marker. That was a true reading
// of the export and no longer is: the entries are written as references to the
// sibling `defaultNormalVariant` / `defaultErrorVariant` consts, and the reader
// now dereferences an object-valued sibling const, so both rows and all eight
// of their colours arrive. Nothing here is a literal any more — the fill, the
// two borders, the focus ring and the disabled trio are all read from the row.
//
// ─── `State` is one enum, and it is the resolver's ladder ─────────────────────
//
// This set carried `Enabled × Focus` — two booleans for what
// `text_field_style.dart` resolves as ONE branch. `buildDecoration` reads the
// widget's state set top-down and lands on exactly one rung:
//
//   disabled  → bg/border/value = the disabled trio; no layer, no caret, and
//               no ring — disabled sits above focus, so a disabled field that
//               takes focus by traversal still paints as disabled.
//     → focus → bg = resting, border = `focusRingColor` (the BORDER itself
//               turns primary/error, not only the ring), caret, ring, and the
//               state layer at the ramp's `focus` weight.
//     → hover → bg/border = resting. There is no hover token anywhere on
//               `CoreTextFieldStyle` — the only thing hover paints is the
//               state layer at the ramp's `hover` weight.
//     → rest.
//
// Two booleans could not say that. `Enabled=false, Focus=true` enumerated a
// pose the ladder never renders (disabled outranks focus), and there was no
// spelling at all for hover, so the 3% wash the widget paints on every
// hovered field had no member. The rungs are declared here, not derived from
// `axes`, exactly as `Button` does — see the note above `kButtonStates`.
//
// `pressed` is deliberately not a rung. The resolver has the branch
// (`isPressed → layer.pressed`), but `TextField._states` only ever carries
// disabled / focused / hovered, so on Flutter that branch is unreachable and
// a `State=pressed` member would assert a look the widget never produces. If
// `WidgetState.pressed` is ever added to `_states`, insert `pressed` between
// `focus` and `disabled` below — a new value on a builder-declared axis is
// additive, no rename row needed.
//
// ─── Variant is the schema's, and error × disabled exists ─────────────────────
//
// `CoreTextFieldVariant` is a real v3 axis, so the two members are its own
// spellings — `defaultVariant` / `error`, not the `Default` / `Error` this set
// carried while the axis was hand-rolled here. Both migrations are explicit
// rows in `src/renames.ts`, so the existing children keep their keys.
//
// The `error` row states the SAME disabled trio as the clean row
// (`defaultErrorVariant` — "a disabled field with a stale error is still
// disabled first"), so `Variant=error, State=disabled` paints the same box as
// `Variant=defaultVariant, State=disabled`. That is not a member to skip: it
// is what a `Variant=error` instance switches to when its host disables it,
// and its helper row still wears `errorTextStyle` (the widget's error/
// description split is on `errorText != null`, not on `enabled`).
//
// What `State=disabled` draws is the whole trio, not just the label: bg →
// `disabledBackgroundColor`, border → `disabledBorderColor`, the value's colour
// → `disabledForegroundColor`, plus `labelDisabledColor` on the label. A note
// here used to justify recolouring only the label on the grounds that "the
// resolver does not emit" the rest; it does, and the reason the trio looked
// absent was the empty variant table the section above records.
//
// ─── Shape ───────────────────────────────────────────────────────────────────
//
// `text_field.dart` returns the bare field until a `label` / `description` /
// `errorText` is set, at which point it returns a Column around it:
//
//   Column
//     ├─ Padding(labelPadding) └─ FormLabel(label:, isRequired:)
//     └─ MouseRegion └─ FocusOutline └─ Container(decoration) └─ Row
//          ├─ prefix?
//          ├─ Expanded └─ Stacks(centerStart) [placeholder?, editable]
//          ├─ feature Button(s)
//          └─ suffix?
//
// This component is that Column: a hidden `Padding(labelPadding)` holder
// carrying a real `FormLabel` INSTANCE, then the field row and its container.
// The label region is hidden because the widget's own default has no label —
// `Show label` reveals it, the same arrangement the affix slots use, so the
// component still renders as a bare field until a designer asks for one.
//
// A hand-drawn label row is deliberately NOT the fallback. A text node shaped
// like a FormLabel is the exact "lookalike" this work removes, and it would
// also hide the required-asterisk slot the real instance carries — the
// instance keeps `FormLabel`'s own `Label` / `Required` properties, which a
// designer drives from the instance panel. `Required` is left to FormLabel's
// own default (off), which is TextField's: the widget passes
// `isRequired: widget.required`, and `required` defaults to false.
//
// ─── The helper row under the field, and why it is ONE row ────────────────────
//
// The widget's last two children are mutually exclusive by construction:
//
//   if (description != null && errorText == null) Padding(descriptionPadding, Text(description, descriptionTextStyle))
//   if (errorText   != null)                      Padding(descriptionPadding, Text(errorText,   errorTextStyle))
//
// Same inset, same position, never both — an error REPLACES the description. So
// it is one node here, and which text style it wears is decided by the axis this
// set already has: `Variant=Error` is `errorText != null`, which is the same
// condition that picks `errorTextStyle` in the widget. Two rows would put the
// two on screen together, a state the widget cannot reach.
//
// `descriptionPadding` is the row's own inset (the top edge only), so it lands
// on the holder exactly as `labelPadding` lands on the label holder above, and
// the Column keeps no spacing of its own — which is what the Dart `Column`
// without a `spacing:` is.
//
// The typography is `fields.descriptionStyle` (or `fields.errorStyle` on the
// error row), not the size row's base: both resolvers build this text as
// `defaultDescriptionStyle.merge(<caller override>)` /
// `defaultErrorStyle.merge(<caller override>)`, the same size-invariant role on
// every rung, and the export states exactly those two defaults.

// The ladder's rungs in the order a designer reads them; `disabled` last for
// the reason `kButtonStates` gives. No `pressed` — see the section note.
const kTextFieldStates = stateAxis(['enabled', 'hover', 'focus', 'disabled']);

type TextFieldState = (typeof kTextFieldStates)[number];

// The width a field's boundary is drawn at in one pose.
//
// The resting boundary (`borderWidth`) stays in the layout in both widgets and
// the active boundary (`activeBorderWidth`) is only the part beyond it, laid
// over the box. A width at or below the resting one therefore adds nothing —
// the active value is a floor over the rest, not a replacement — and the node
// keeps the resting width. A pose that is not active draws the resting width.
// `activePose` is each builder's own reading of the code's condition (a
// focused field, or an enabled one in the error variant); the bare `plain`
// field and a boundary that paints nothing never reach this width, because
// `borderData` draws no stroke for them.
function boundaryWidthFor(rest: Dim, active: Dim, activePose: boolean): Dim {
  return activePose && dimVal(active) > dimVal(rest) ? active : rest;
}

function buildTextField(page: PageNode, lk: VarLookup): ComponentSetNode {
  const sizeData = new Map(Object.entries(TEXT_FIELD.sizes.defaultsBySize));
  const labelCells = formLabelSizeCells();
  // The two rows of `defaultsByVariant`, keyed the way the export writes them
  // (`default` / `error`) while the axis member the combination carries is
  // `CoreTextFieldVariant`'s own spelling (`defaultVariant` / `error`) — one
  // boolean rather than a map lookup, because there are exactly two rows and
  // "is this field in its error state" is the question both of them answer.
  const variantRows = TEXT_FIELD.variants.defaultsByVariant;
  const affix = colorData(TEXT_FIELD.fields.affixColor);
  // `valueStyle` is NOT hoisted here any more — it is the size row's, so it
  // has to be read inside the loop. It used to stand at this line reading the
  // flat `fields.valueStyle`, which is size-independent, and that is how all
  // six sizes came out at one font size while the app rendered a two-step
  // ladder (`bodySmall` xs–md, `bodyMedium` lg–xl2). The pairing the old
  // comment protected — value text and the caret standing in it built from ONE
  // style object, so the caret's line box cannot disagree with the text — is
  // kept by declaring it once per combination rather than once per run.
  // `State` is declared here, not derived from `axes` — see the section note.
  // Variant and Size still come from the schema, so a variant or size added in
  // Dart lands on the canvas without touching this file.
  const combos = enumerateAxisCombos([
    ...axisSpecsOf(TEXT_FIELD.axes).filter((spec) => spec.axis !== 'Enabled'),
    { axis: 'State', values: [...kTextFieldStates] },
  ]);
  // Affix glyphs drawn from the swap defaults (see `iconSlot`).
  const prefixSwap = iconSwapDefault(page, 'TextField', 'Prefix', iconSlotDefaultId());
  const suffixSwap = iconSwapDefault(page, 'TextField', 'Suffix', iconSlotDefaultId());
  const mount = mountSet(page, 'TextField', combos);
  const slots: {
    placeholder: TextNode;
    value: SlotNodes;
    prefix: SlotNodes;
    suffix: SlotNodes;
    suffixText: SlotNodes;
    feature: InstanceNode;
    label: FrameNode;
    helper: SlotNodes;
    ring: FocusRingNodes;
  }[] = [];
  for (const comboName of combos) {
    const combo = parseVariantKey(comboName);
    // `resolveSizeRow`'s row: once the `xs` notice ends with that row gone,
    // the `Size=xs` cell draws `sm` — what the field renders — not `md`.
    const zn = combo['Size'];
    const sz = sizeRowFor(sizeData, zn, TEXT_FIELD.axes.size.members);
    // The size row's own typography — what both resolvers read
    // (`merged.baseTextStyle ?? ss.baseTextStyle!`) and therefore what the app
    // draws. The placeholder and the value are the same style here because
    // that is what the widget resolves them to: `placeholderStyle` /
    // `valueStyle` are caller-override slots whose defaults neither platform
    // consults, so with no caller in the picture both collapse to this base.
    // `buildTextArea` reads its size row the same way.
    const valueStyle = textStyleData(sz.baseTextStyle);
    const state = combo['State'] as TextFieldState;
    const disabled = state === 'disabled';
    const focused = state === 'focus';
    const hovered = state === 'hover';
    // The variant row and the helper-row colour that goes with it —
    // `descriptionColor` when the field is clean, `errorColor` when it is
    // not. Both are stated fields, and the widget reads them in exactly this
    // pair (`descriptionTextStyle` / `errorTextStyle`).
    const isError = combo['Variant'] === 'error';
    // `plain` is the bare field — transparent fill and border in every state
    // (`CoreTextFieldStyle.defaultPlainVariant`), for a host that draws the
    // box itself (Command's search row). `fillData` / `borderData` paint
    // nothing for a transparent colour, so the row reads through unchanged.
    // `filled` (#5747) is the tinted-fill row — its resting edge takes the
    // fill's own tone, its hover steps the fill.
    const variantKey =
      combo['Variant'] === 'plain'
        ? 'plain'
        : combo['Variant'] === 'filled'
          ? 'filled'
          : isError
            ? 'error'
            : 'default';
    const row = variantRows[variantKey];
    const helperColor = isError
      ? TEXT_FIELD.fields.errorColor
      : TEXT_FIELD.fields.descriptionColor;
    // The field row's inset — the size row's, with the variant row's own
    // `horizontalPadding` laid over its left/right when the row states one
    // (only `plain`: 0, so the bare field's text starts flush with the label
    // above it). Both resolvers apply it under the caller's `padding`
    // override; the canvas has no caller override, so a stated value always
    // lands.
    const rowInline =
      'horizontalPadding' in row ? row.horizontalPadding : undefined;
    // A one-line field is held on its size row with the line centred
    // (`CoreTextFieldStyle.contentPadding`, both resolvers): the row's
    // vertical padding does not size it, so the canvas lays none either —
    // the fixed row height and the centred cross axis place the line.
    const fieldPad = {
      l: rowInline ?? sz.padding.l,
      r: rowInline ?? sz.padding.r,
      t: 0,
      b: 0,
    };
    // `buildDecoration`'s ladder, read top-down: the disabled trio outranks
    // everything, then focus turns the border itself to `focusRingColor`,
    // then hover steps it to the row's `hoverBorderColor` (`outline`
    // → `on-surface`; the error row restates `error`, so error outranks the
    // pointer), then rest. A row that states no hover border (`plain`)
    // keeps its resting one — that field's hover is the state layer alone.
    // The value's colour is keyed on disabled alone (`buildValueTextStyle`).
    const boxFill = disabled
      ? row.disabledBackgroundColor
      : hovered
        ? (('hoverBackgroundColor' in row ? row.hoverBackgroundColor : undefined) ?? row.backgroundColor)
        : row.backgroundColor;
    const boxBorder = disabled
      ? row.disabledBorderColor
      : focused
        ? row.focusRingColor
        : hovered
          ? (optField<Color>(row, 'hoverBorderColor') ?? row.borderColor)
          : row.borderColor;
    const valueColor = disabled ? row.disabledForegroundColor : row.foregroundColor;
    // The outer Column (`mainAxisSize: .min, crossAxisAlignment: .start`).
    // It paints nothing — every bit of chrome belongs to the field row
    // below, which is what `Container(decoration:)` wraps in the widget.
    const comp = mount.getOrCreate(comboName);
    comp.layoutMode = 'VERTICAL';
    comp.primaryAxisSizingMode = 'AUTO';
    comp.counterAxisSizingMode = 'AUTO';
    comp.primaryAxisAlignItems = 'MIN';
    comp.counterAxisAlignItems = 'MIN';
    comp.fills = [];
    // `lockWidth` at the end of the body puts the preview width HERE, on the
    // component, and the field row fills it — see the note there.

    // `Padding(labelPadding) └─ FormLabel(label:, isRequired:)`. The padding
    // is the widget's own field, and it is what separates the label from the
    // field — this Column has no itemSpacing of its own, exactly as the Dart
    // `Column` has no `spacing:`.
    const labelHolder = autoFrame('label', 'HORIZONTAL');
    // The `lg` rung and above state their own label gap (#5747); the flat
    // default covers the rest — `merged.labelPadding ?? ss.labelPadding ??
    // defaultLabelPadding` in both resolvers.
    bindPad(labelHolder, lk, optField<typeof TEXT_FIELD.fields.labelPadding>(sz, 'labelPadding') ?? TEXT_FIELD.fields.labelPadding);
    const labelInstance = instanceOf(
      page,
      'FormLabel',
      bestVariantName(page, 'FormLabel', {
        // The FormLabel cell that shows this size's label — FormLabel draws
        // one cell per picture, so `xs`/`sm` find theirs at `md`.
        Size: labelCells.cellFor(zn),
        Enabled: disabled ? 'false' : 'true',
      }),
    );
    labelHolder.appendChild(labelInstance);
    // `!enabled && labelStyle?.color == null` → the label's colour becomes
    // `labelDisabledColor`. Repainted on the composed instance rather than
    // asked of `FormLabel`'s own axes: this colour is TextField's statement
    // about its label, not FormLabel's about itself, and the resolver spends
    // it in TextField's own typography emit.
    if (disabled) {
      for (const node of labelInstance.findAll((n) => n.type === 'TEXT')) {
        if (node.type !== 'TEXT') continue;
        fillData(node, lk, colorData(TEXT_FIELD.fields.labelDisabledColor));
      }
    }
    labelHolder.visible = false;
    comp.appendChild(labelHolder);

    // `MouseRegion └─ FocusOutline └─ Container(decoration)`. The ring the
    // middle one draws hangs off this row rather than sitting in a wrapper
    // around it — see `focusRing` for why the wrapper is not available here.
    // This row stays the component's one painted direct child either way.
    const field = autoFrame('field', 'HORIZONTAL');
    comp.appendChild(field);
    field.primaryAxisSizingMode = 'FIXED';
    field.counterAxisSizingMode = 'FIXED';
    field.primaryAxisAlignItems = 'MIN';
    field.counterAxisAlignItems = fieldRowCounterAxis(
      TEXT_FIELD.fields.crossAxisAlignment,
      TEXT_FIELD.fields.textAlignVertical,
    );
    bindPad(field, lk, fieldPad);
    // The inner Row's spacing is a real field (`resolved.rowSpacing`) and
    // now has siblings to separate — before the affix/feature slots below
    // existed there was only one child, so nothing showed it.
    field.setBoundVariable(
      'itemSpacing',
      lk.space(dimVal(TEXT_FIELD.fields.rowSpacing)),
    );
    // The size row's corner — the control height × 0.25, so the field and a
    // `Button` of the same size share one corner (`merged.borderRadius ??
    // ss.borderRadius!` in both resolvers).
    bindRadiusN(field, lk, sz.borderRadius.topLeft);
    // Both from the variant row — the fill and the boundary this variant
    // states, in the pair the `enabled` branch picks. The framed box is a
    // content surface on both platforms (the fill-less variants wear none).
    applySurfaceMaterial(field, lk, colorData(boxFill), 'content', { radius: sz.borderRadius.topLeft });
    // The active boundary: a focused field, or an enabled one in the error
    // variant (`disabled > error`, so a disabled error member rests). The
    // bare `plain` field keeps its resting boundary in every pose.
    borderData(
      field,
      lk,
      colorData(boxBorder),
      // Focus alone widens it (#5747) — an error edge rests at the resting
      // width.
      boundaryWidthFor(
        TEXT_FIELD.fields.borderWidth,
        TEXT_FIELD.fields.activeBorderWidth,
        !disabled && variantKey !== 'plain' && focused,
      ),
    );

    const prefix = iconSlot('prefix', 'search', lk, sz.iconStyle.size, affix, prefixSwap.variant);
    field.appendChild(prefix.holder);

    // `Expanded(child: Stacks(alignment: .centerStart, children:
    // [placeholder?, editable]))`. The placeholder is not swapped out for
    // the value — it sits *under* it behind a `Visibility(maintainSize:
    // true)`, which is why an empty field and a filled one are the same
    // height. Modelled the same way: the placeholder is the in-flow child so
    // the stack hugs one line box, and the editable is an absolutely
    // positioned sibling sharing its origin.
    const inputStack = autoFrame('input', 'VERTICAL');
    field.appendChild(inputStack);
    inputStack.layoutSizingHorizontal = 'FILL';

    // Inked with the variant row's `placeholderColor` — what both resolvers
    // paint it with when no caller `placeholderStyle` states a colour
    // (`vs.placeholderColor`), in every state. Not `affixColor`: that is the
    // affix slots' tone, and the two coincide only while their tokens happen
    // to resolve to the same value.
    const placeholder = makeLabel(
      '이메일을 입력해 주세요',
      lk,
      // A disabled placeholder takes the disabled foreground (#5747).
      typographyColorOpts(
        lk,
        valueStyle,
        colorData(disabled ? row.disabledForegroundColor : row.placeholderColor),
      ),
    );
    inputStack.appendChild(placeholder);
    placeholder.layoutSizingHorizontal = 'FILL';
    placeholder.layoutSizingVertical = 'HUG';
    // `textAlign` — on the text node, not on the row. See `textAlignHorizontal`.
    placeholder.textAlignHorizontal = textAlignHorizontal(
      TEXT_FIELD.fields.textAlign.choice,
    );

    // `valueStyle` carries no colour of its own, so the row's foreground is
    // what `buildValueTextStyle` colours it with — `foregroundColor` enabled,
    // `disabledForegroundColor` not. Stated rather than left to the shared
    // on-surface fallback: the two agree on the enabled half, which is exactly
    // why nothing on the canvas showed which one it was reading. Holder + text,
    // like every other slot here: one node cannot carry both the BOOLEAN and
    // the TEXT property.
    const value = textSlot('value', 'hello@cocode.im', lk, valueStyle, colorData(valueColor));
    inputStack.appendChild(value.holder);
    // In FLOW, not pinned at the stack's origin.
    //
    // It was absolute at (0, 0), and that put the value in a different place
    // from the placeholder it replaces: the placeholder is a stack child, so
    // the field's `MIN/CENTER` alignment centres it vertically, while (0, 0) is
    // the top-left corner. Turning the `Value` property on therefore moved the
    // text to the corner — the same misplacement that made `TimePicker`'s
    // digits sit off their own baseline.
    //
    // A consumer that shows the value hides the placeholder
    // (`revealValueOverPlaceholder`), so in-flow does not mean both in the
    // column — and if a consumer forgets, `checkStackedText` in the fidelity
    // readback reports two visible strings rather than letting one ghost
    // behind the other. Between "wrong place, always" and "right place, with a
    // gate on the misuse", the second is the one that can be seen going wrong.
    value.holder.layoutSizingHorizontal = 'FILL';
    value.holder.layoutSizingVertical = 'HUG';
    if (value.text) {
      value.text.textAlignHorizontal = textAlignHorizontal(
        TEXT_FIELD.fields.textAlign.choice,
      );
    }

    // The caret. `RenderEditable` paints it inside the editable, so it shares
    // the input stack's origin exactly as the two stack children do — hence
    // absolute at that origin rather than a row child. A row child would take
    // `cursorWidth` of width and shove the placeholder 2px right the moment
    // focus arrived, which is a displacement the widget does not make (the one
    // reservation it does make is on the TRAILING edge, and only to rebalance
    // centred text).
    const caretWidth = dimVal(TEXT_FIELD.fields.cursorWidth);
    const caret = figma.createRectangle();
    caret.name = 'caret';
    // Neither extent is a Variable to bind: `cursorWidth.ref` is null, and the
    // height is arithmetic (see `caretLineBox`). Same reading the drag handle
    // in `buildTextArea` records for its own `ref: null` size.
    caret.resize(caretWidth, caretLineBox(valueStyle));
    statedRadius(caret, lk, TEXT_FIELD.fields.cursorRadius.topLeft);
    fillData(caret, lk, colorData(TEXT_FIELD.fields.cursorColor));
    // `showCursor` resolves to `!readOnly`, and a disabled field is
    // `readOnly: widget.readOnly || !widget.enabled`. On a single `State`
    // enum that reads as: the caret stands on `focus`, and `disabled` — which
    // outranks focus in the ladder — never has one.
    caret.visible = focused;
    // The stack spans the row's inner width while the affix and feature slots
    // are hidden, which is their shipped default — so this is the width the
    // caret's own end is measured against.
    const contentWidth =
      kFieldPreviewWidth - dimVal(fieldPad.l) - dimVal(fieldPad.r);
    const caretAt = caretPlacement(
      TEXT_FIELD.fields.textAlign.choice,
      contentWidth,
      caretWidth,
    );
    pinAbsolute(inputStack, caret, caretAt.x, 0, {
      horizontal: caretAt.horizontal,
      vertical: 'MIN',
    });

    // The clear / reveal affordance. `CoreTextFieldStyle.featureButtonStyle`
    // is a `CoreButtonStyle` raw-forwarded to a real `Button(variant:
    // .plain)` (text_field.dart `_buildFeatureButton`), so this is an
    // INSTANCE of the Button component, never a redrawn box — a redrawn copy
    // would keep painting the old Button forever, since the content-hash skip
    // leaves a parent alone whose own recipe didn't change.
    //
    // Sized to the field's own size step rather than Button's `md` default
    // (the code passes no `size:`): the two components' `height` tokens are
    // identical per step, so this is the one mapping that isn't invented, and
    // an `md` button inside an `xs` field would visibly overflow.
    //
    // Left at Button's own property defaults on purpose — in code this button
    // is icon-only (`child: Icon(x)`), and pre-setting the instance's `Label`
    // / `Leading icon` values needs `InstanceNode.setProperties`, whose
    // effect the runtime harness cannot observe (its node double reports no
    // `componentProperties`, so the call would be untested code running only
    // in Figma, where a rejected value would fail the entry and leave the
    // field half-built). A designer sets them from the instance panel; what
    // matters here is that it IS a Button instance and follows the Button set.
    // Only `disabled` follows the field's own state: `_buildFeatureButton`
    // hands `onPressed: enabled ? … : null`, so a disabled field's affordance
    // is a disabled button, and pointing every instance at the enabled member
    // would make the composed child contradict its host on a quarter of the
    // set. The field's hover and focus do NOT reach the button — it has its
    // own `MouseRegion` and focus node — so those rungs compose the resting
    // one.
    const feature = instanceOf(
      page,
      'Button',
      buttonVariantName('plain', zn, disabled ? 'disabled' : 'enabled'),
    );
    feature.name = 'feature button';
    feature.visible = false;
    field.appendChild(feature);
    // `featureButtonStyle`, forwarded in the resolvers' merge order — the
    // field's default (the inset, 8), then this size row's (the corner, equal
    // to the field's own, so the affordance is never rounder than the box it
    // sits in). The instance was arriving with the `plain` row's inset.
    applyForwardedButtonStyle(feature, lk, TEXT_FIELD.fields.featureButtonStyle);
    applyForwardedButtonStyle(feature, lk, sz.featureButtonStyle);
    feature.layoutSizingVertical = 'FILL';

    const suffix = iconSlot('suffix', 'calendar', lk, sz.iconStyle.size, affix, suffixSwap.variant);
    field.appendChild(suffix.holder);
    // The same slot as WORDS. `suffix` is `W?` in the contract — a unit, a
    // count, a timer are all things the widget accepts there — but the
    // canvas offered only the glyph, so a designer with a timer to show
    // reached for the feature button instead and shipped a control that is
    // not one. Drawn in the field's own size-base typography in the affix
    // colour, which is what both widgets now render a `Text` affix in.
    const suffixText = textSlot(
      'suffix text',
      '원',
      lk,
      textStyleData(sz.baseTextStyle),
      affix,
    );
    field.appendChild(suffixText.holder);

    // `Padding(descriptionPadding) └─ Text(description | errorText)` — the
    // third child of the Column, hidden until a designer asks for it (the
    // widget returns the bare field until one of the two strings is set).
    // See the section note for why the two strings share one node.
    const helper = textSlot(
      'description',
      '업무용 이메일을 권장해요.',
      lk,
      // The `lg` rung and above state their own helper role (#5747).
      textStyleData(
        isError
          ? (optField<typeof TEXT_FIELD.fields.errorStyle>(sz, 'errorStyle') ?? TEXT_FIELD.fields.errorStyle)
          : (optField<typeof TEXT_FIELD.fields.descriptionStyle>(sz, 'descriptionStyle') ??
              TEXT_FIELD.fields.descriptionStyle),
      ),
      colorData(helperColor),
    );
    bindPad(
      helper.holder,
      lk,
      optField<typeof TEXT_FIELD.fields.descriptionPadding>(sz, 'descriptionPadding') ??
        TEXT_FIELD.fields.descriptionPadding,
    );
    comp.appendChild(helper.holder);

    // The row carries the size step's height; the Column hugs it, so with the
    // label hidden the component measures exactly what it did before it grew
    // one. It is the size row's `minHeight` — the control height both
    // resolvers floor the box at (`CoreTextFieldStyle.boxMinHeight`), and
    // with the line centred and no vertical padding it is what the app draws
    // at every size.
    field.resize(kFieldPreviewWidth, dimVal(sz.minHeight));
    // The control row a density moves (see `buildButton`). The state layer
    // and the ring below are STRETCH-pinned to this row and follow it.
    const fieldRow = lk.controlHeightOrNull(dimVal(sz.minHeight));
    if (fieldRow) field.setBoundVariable('height', fieldRow);

    // ─── The state layer ─────────────────────────────────────────────────────
    //
    // `text_field_style.dart` composites ONE overlay for whichever of
    // pressed > focus > hover is active, at the variant's ramp weight, over the
    // RESTING fill — gated on `!isDisabled`, which is why the disabled rung has
    // none. On a `surface`-filled field the hover weight is a 3% on-surface
    // wash: faint on purpose, and the whole of what `State=hover` shows.
    //
    // A rectangle rather than a pre-composited fill, for the reason
    // `buildButton` records: the ramp has more rungs than anyone authored
    // colour tokens for, and `fillData(row.foregroundColor)` + `opacity` keeps
    // the token bound so the wash follows a theme rebind.
    //
    // Inside the `field` row at index 0, never a sibling of it: the parents
    // that compose this set (`paintedChildRow` / `paintedFieldRow`) sweep the
    // instance's direct children for exactly ONE painted frame, and a second
    // painted node at that level would make them throw. Index 0 puts it over
    // the row's own fill and under every slot the row lays out.
    const ramp = optField<{ hover: number; focus: number; pressed: number }>(
      row,
      'stateLayer',
    );
    const layerAlpha =
      ramp == null || disabled
        ? null
        : focused
          ? ramp.focus
          : hovered
            ? ramp.hover
            : null;
    if (layerAlpha != null) {
      const stateLayer = figma.createRectangle();
      stateLayer.name = 'state layer';
      stateLayer.resize(kFieldPreviewWidth, dimVal(sz.minHeight));
      stateLayer.cornerRadius = dimVal(sz.borderRadius.topLeft);
      fillData(stateLayer, lk, colorData(row.foregroundColor));
      stateLayer.opacity = layerAlpha;
      // `insertChild` first, then pin — `pinAbsolute` appends, so pinning and
      // then moving to index 0 would reparent the same node twice.
      field.insertChild(0, stateLayer);
      pinInFlow(field, stateLayer);
      stateLayer.x = 0;
      stateLayer.y = 0;
      stateLayer.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };
    }

    // The ring, once the field it surrounds has a size to stand outside of,
    // and last so it paints over the row's own children. The widget puts it
    // around this container and nothing else — the label above and the helper
    // row below are the Column's other children, outside the `FocusOutline`.
    // Visible on `State=focus` and left unbound there, as `buildButton` does;
    // every other member hides it behind `Show focus ring` (bound below) —
    // the rule every ring-drawing set follows (Show-focus-ring 불일치
    // 2026-09-08 §4-2), so a keyboard-focused disabled or pressed pose can
    // be drawn without a `State` for it.
    const ring = focusRing(field, lk, {
      outline: TEXT_FIELD.fields.focusOutlineStyle,
      color: colorData(row.focusRingColor),
      corner: sz.borderRadius.topLeft,
      width: kFieldPreviewWidth,
      height: dimVal(sz.minHeight),
      // A keyboard signal (#5747): the focus member shows the `primary`
      // active boundary alone, and the ring is `Show focus ring` on every
      // member — a pointer focus draws none.
      visible: false,
    });

    // ─── Width belongs to the Column, and the row FILLS it ────────────────
    //
    // The widget constrains no width anywhere: the `Container(decoration:)`
    // takes what its parent offers, and the `Row` inside it is
    // `mainAxisSize.max` with an `Expanded` input, so the field spans the
    // full available width. Pinning the ROW at a preview width and letting
    // the Column hug it inverted that — the Column's width became a readout
    // of the row instead of the row's constraint, so resizing an instance
    // moved the component box while the row stayed at its baked 240 and the
    // two disagreed: the field fell short of the box, or the label row (which
    // hugs its own content) pushed the box past the field.
    //
    // Stated the other way round, the pair matches the widget: the component
    // carries the one invented number (240 — no CoUI recipe says how wide a
    // text field is) and the row fills whatever the component is, at every
    // width a designer drags it to.
    // The ring is transparent to that arrangement: stretched to the row's four
    // edges, it follows whatever width the row is given.
    lockWidth(comp, kFieldPreviewWidth);
    field.layoutSizingHorizontal = 'FILL';
    slots.push({
      placeholder,
      value,
      prefix,
      suffix,
      suffixText,
      feature,
      label: labelHolder,
      helper,
      ring,
    });
  }
  const set = mount.finish();
  const placeholderId = defineProp(set, 'Placeholder', 'TEXT', '이메일을 입력해 주세요');
  // The widget's `Visibility(maintainSize: true)` around the placeholder, as a
  // handle: a consumer that shows a value turns it off so the two strings do not
  // stack (`revealValueOverPlaceholder`). It is the designer's own property,
  // adopted by name+type so its key — and every consuming file's override of it —
  // stays; `true` is the resting pose, so no member draws differently. It was
  // declared on the live set and bound to nothing, which both left the handle
  // inert and kept the set out of Figma's publish dialog (#5144, #5323).
  const showPlaceholderId = defineProp(set, 'Show placeholder', 'BOOLEAN', true);
  const valueId = defineProp(set, 'Value', 'BOOLEAN', false);
  const valueTextId = defineProp(set, 'Value text', 'TEXT', 'hello@cocode.im');
  const showPrefixId = defineProp(set, 'Show prefix', 'BOOLEAN', false);
  const prefixId = defineProp(set, 'Prefix', 'INSTANCE_SWAP', prefixSwap.id);
  const showSuffixId = defineProp(set, 'Show suffix', 'BOOLEAN', false);
  const suffixId = defineProp(set, 'Suffix', 'INSTANCE_SWAP', suffixSwap.id);
  const showSuffixTextId = defineProp(set, 'Show suffix text', 'BOOLEAN', false);
  const suffixTextId = defineProp(set, 'Suffix text', 'TEXT', '원');
  const featureId = defineProp(set, 'Feature button', 'BOOLEAN', false);
  // `label` is a `String?` on the contract, not a `W?` slot — the boolean is
  // `widget.label != null`, which is what decides whether the Column has a
  // label row at all. The words inside it are `FormLabel`'s own `Label`.
  const showLabelId = defineProp(set, 'Show label', 'BOOLEAN', false);
  // Same shape for the helper row: `description` / `errorText` are `String?`,
  // so the boolean is "is either set" and the TEXT is the words. Named after
  // the `Variant=Default` reading of the row — on `Variant=Error` the same node
  // is the error text, which is the widget's own mutual exclusion and not a
  // second property.
  const showHelperId = defineProp(set, 'Show description', 'BOOLEAN', false);
  const helperTextId = defineProp(set, 'Description', 'TEXT', '업무용 이메일을 권장해요.');
  // A drawing switch, not a code prop — the runtime decides focus through
  // `:focus-visible` / `FocusableActionDetector`. Left unbound on the
  // `State=focus` members, whose ring is already on.
  const showFocusId = defineShowFocusRing(set);
  for (const s of slots) {
    bindTextProp(s.placeholder, placeholderId);
    bindVisibleProp(s.placeholder, showPlaceholderId);
    bindTextProp(s.value.text!, valueTextId);
    bindVisibleProp(s.value.holder, valueId);
    bindVisibleProp(s.prefix.holder, showPrefixId);
    bindSwapProp(s.prefix.icon!, prefixId);
    bindVisibleProp(s.suffix.holder, showSuffixId);
    bindSwapProp(s.suffix.icon!, suffixId);
    bindVisibleProp(s.suffixText.holder, showSuffixTextId);
    bindTextProp(s.suffixText.text!, suffixTextId);
    bindVisibleProp(s.feature, featureId);
    bindVisibleProp(s.label, showLabelId);
    bindVisibleProp(s.helper.holder, showHelperId);
    bindTextProp(s.helper.text!, helperTextId);
    bindShowFocusRing(s.ring, showFocusId);
  }
  // No `layoutSet` override, for the reason `buildButton` records: at 48
  // members a hand-picked 520px wrap is narrower than two 240px fields, so the
  // block collapses to one column 48 rows tall — the opposite of what a variant
  // grid is for. `finish()` has already applied `defaultSetLayout`, whose
  // ceil(sqrt(n)) grid stays roughly square whatever `n` becomes, and it needs
  // no number of this file's own.
  return set;
}

// ─── Checkbox ────────────────────────────────────────────────────────────────

// Data-driven from coui_core CHECKBOX. No `defaultsByVariant` row — the
// checkbox has no variant axis (its single `defaultVariant` member was an axis
// with nothing to choose between), so every colour is a flat
// `CHECKBOX.fields.*` default.
//
// ─── Three axes, all declared here ───────────────────────────────────────────
//
// `checkbox.axes` says `size` + `enabled` and nothing else: the widget's value
// is Flutter's tristate `bool?`, not an enum the reader could promote. So the
// set's identity is
//
//   Size (six, the keys of `defaultsBySize`)
//   × State (`enabled` / `hover` / `focus` / `pressed` / `disabled`)
//   × Checked (`false` / `true` / `indeterminate` — the tristate spelled out;
//     `restingValueOf` rests at `'false'`)
//
// = 90 members. `State` is what `Enabled` used to say plus the three poses
// `checkbox.dart` reads off its `Clickable` (`onHover` / `onPressedChange` /
// `onFocus`): `disabled` is the old `Enabled=false`, and the other four are the
// rest / hover / focus / pressed the widget SELECTS chrome for. Same shape as
// `Chip` and `Button`.
//
// Value → which colour slot (checkbox.dart / checkbox_style.dart):
//   false          fill = boxBackgroundColor (none)   border = boxBorderColor
//   true           fill = boxActiveColor              ✓ glyph = checkmarkIconStyle.color
//   indeterminate  fill = boxActiveColor              — glyph = checkmarkIconStyle.color
//   State=disabled fill = disabledBackgroundColor     border = disabledBorderColor
//                  label / description = disabledForegroundColor
//                  glyph = disabledCheckmarkColor — the disabled branch runs
//                  FIRST in the widget, so a disabled checked box takes the
//                  disabled fill AND keeps its mark, in the disabled ink (the
//                  `onPrimary`-on-grey invisible mark is what this field fixes).
//
// Stroke (`boxBorderWidth`) and corner (`boxBorderRadius`) are FLAT fields, not
// rows of `defaultsBySize` — they must not ride the size axis. Twice a
// generator put them there, and twice `xl` / `xl2` walked back to `stroke2` /
// `radius8`.
//
// State layer (hover / pressed): a `state layer` rect at child 0 of the box —
// under the glyphs — reaching `stateLayerSpread` beyond it on every side, with
// `stateLayerBorderRadius` (its own corner, concentric with the box, the same
// silhouette as the ring) and `stateLayerColor` at the ramp's `hover` /
// `pressed` weight as node opacity. The Flutter twin's `Position(-spread)`
// `AnimatedContainer`, the Web twin's `.co-checkbox-box::before`.
//
// Focus (State=focus only): the ring stands around the BOX, not the row —
// `checkbox.dart` wraps the square in `FocusOutline` and tells its `Clickable`
// `focusOutline: false`. Geometry is the checkbox's own `focusOutlineStyle`
// slot over the box's own corner, which is exactly what `focusRing()` draws
// (band 0..offset, ring offset..align, INSIDE). There is no `Show focus ring`
// BOOLEAN: the pose IS the rung.
//
// The indeterminate glyph is a horizontal DASH — `indeterminateLength` wide,
// `markThickness` tall, pill-capped — not a square wearing the box's corner.
// The ✓ stays an `Icon` instance and follows the icon stroke like any other
// icon: its weight comes from the `Icon` variant / collection mode the instance
// carries, not from `checkbox/mark-thickness`. Only the dash's height binds to
// that variable. The variable's value is `CoreCheckboxStyle.defaultMarkThickness`,
// which Core takes from the icon stroke rule's floor, so the dash and the ✓ read
// as one weight at every size.
const kCheckboxStates = stateAxis(['enabled', 'hover', 'focus', 'pressed', 'disabled']);
type CheckboxState = (typeof kCheckboxStates)[number];
const kCheckedValues = ['false', 'true', 'indeterminate'] as const;
// The `Component` variable the dash height binds to — a raw FLOAT the exporter
// ships from `CoreCheckboxStyle.defaultMarkThickness` (no primitive stroke rung
// carries that weight). The ✓ is an `Icon` instance and does not bind to it.
const kCheckboxMarkThicknessVar = 'checkbox/mark-thickness';

function buildCheckbox(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = CHECKBOX.fields;
  const sizeData = new Map(Object.entries(CHECKBOX.sizes.defaultsBySize));
  // The role and the colour come from the component field; the SIZE comes
  // from the row.
  const labelBase = textStyleData(f.labelStyle);
  const descriptionBase = textStyleData(f.descriptionStyle);
  const members = enumerateAxisAssignments([
    { axis: 'Size', values: [...sizeData.keys()] },
    { axis: 'State', values: [...kCheckboxStates] },
    { axis: 'Checked', values: [...kCheckedValues] },
  ]);
  // The trailing glyph is drawn from its swap default (see `iconSlot`).
  const trailingSwap = iconSwapDefault(page, 'Checkbox', 'Trailing', iconSlotDefaultId());
  const mount = mountSet(page, 'Checkbox', members.map((m) => m.name));
  const slots: {
    content: FrameNode;
    label: TextNode;
    prefix: SlotNodes;
    description: TextNode;
    trailing: SlotNodes;
  }[] = [];
  const markThicknessVar = lk.tryGet('Component', kCheckboxMarkThicknessVar);
  for (const { name: comboName, values } of members) {
    const sz = sizeData.get(values.Size);
    if (!sz) throw new Error(`Checkbox: no size data for combo "${comboName}"`);
    const state = values.State as CheckboxState;
    const disabled = state === 'disabled';
    const active = values.Checked !== 'false';
    const boxSide = dimVal(sz.boxSize);
    // An active box's border is its own fill — one colour, the stroke blends
    // in. The disabled branch runs FIRST in `checkbox.dart`.
    const fill = disabled
      ? f.disabledBackgroundColor
      : active
        ? f.boxActiveColor
        : f.boxBackgroundColor;
    const border = disabled
      ? f.disabledBorderColor
      : active
        ? f.boxActiveColor
        : f.boxBorderColor;
    const mark = disabled ? f.disabledCheckmarkColor : f.checkmarkIconStyle.color;
    // `sz.labelStyle` / `sz.descriptionStyle` carry only this size's
    // `fontSize`; everything else stays the field's.
    const label = { ...labelBase, fontSize: dimVal(sz.labelStyle.fontSize) };
    const description = {
      ...descriptionBase,
      fontSize: dimVal(sz.descriptionStyle.fontSize),
    };
    // Disabled folds both lines onto the one `disabledForegroundColor`.
    const labelColor = disabled
      ? colorData(f.disabledForegroundColor)
      : label.color;
    const descriptionColor = disabled
      ? colorData(f.disabledForegroundColor)
      : description.color;
    const c = mount.getOrCreate(comboName);
    // This node is the Row inside `Clickable` — the wrapper adds no pixels
    // here (it owns gesture, cursor and focus DETECTION, none of which a
    // static component carries), so the row is the outermost thing there is
    // to draw. Its `Gap(gapStyle: indicatorLabelGapStyle)` siblings are the
    // row's itemSpacing.
    applyFormRowChrome(c, lk, dimVal(sz.indicatorLabelGapStyle.size));
    // The widget picks `.start` vs `.center` at build time from whether
    // `description` is non-null — a static node can't follow that: `Show
    // description` is a BOOLEAN property, not a variant axis, so this row
    // draws the branch the overwhelming majority of callers get — `CENTER`.
    c.counterAxisAlignItems = 'CENTER';
    // The halo and the ring overhang the box; nothing between them and the
    // page may clip.
    c.clipsContent = false;

    // `prefix` sits BEFORE the indicator (checkbox.dart's Row) and the
    // widget hands it the label's typography, so the slot's Figma stand-in
    // is copy, not a glyph.
    const prefix = textSlot('prefix', '알림 받기', lk, label, labelColor);
    c.appendChild(prefix.holder);

    const b = indicatorBox(lk, f.boxBorderRadius.topLeft, sz.boxSize);
    b.clipsContent = false;
    // `boxBorderWidth` strokes INSIDE the box (Flutter's `Border.all`, Web's
    // `border-box`): the square stays `boxSize` wide whatever the width, and
    // the glyphs sit in what the border leaves.
    b.strokeAlign = 'INSIDE';
    fillData(b, lk, colorData(fill));
    borderData(b, lk, colorData(border), f.boxBorderWidth);

    // `Center(child: Stacks(alignment: .center, children: [check, dash]))`.
    // BOTH glyphs are always in the widget's tree — `AnimatedScale` /
    // `AnimatedOpacity` take the inactive one to zero, they do not remove
    // it, and that is the whole reason checked ↔ indeterminate can
    // cross-fade.
    const checkSide = dimVal(sz.checkmarkSize);
    const dashLength = dimVal(sz.indeterminateLength);
    const dashThickness = dimVal(f.markThickness);
    const glyphSide = Math.max(checkSide, dashLength);
    const glyphs = figma.createFrame();
    glyphs.name = 'glyphs';
    glyphs.layoutMode = 'NONE';
    glyphs.fills = [];
    glyphs.clipsContent = false;
    glyphs.resize(glyphSide, glyphSide);
    b.appendChild(glyphs);

    const check = makeIcon(
      'check',
      lk,
      glyphOpts(lk, colorData(mark), sz.checkmarkSize, 'size'),
    );
    glyphs.appendChild(check);
    // The ✓ is a plain `Icon` instance: whatever stroke `makeIcon` leaves on it
    // is the icon library's for a glyph of that side, and nothing here rewrites
    // or binds it.
    check.x = (glyphSide - checkSide) / kHalf;
    check.y = (glyphSide - checkSide) / kHalf;
    check.visible = values.Checked === 'true';

    // The dash — `indeterminateLength` long, `markThickness` tall, a pill.
    // The length binds to the size ladder; the thickness binds to the one
    // component variable (no primitive rung carries that weight, so `bindSize`
    // would leave it unbound — bound here by name instead).
    const dash = figma.createRectangle();
    dash.name = kMarkBarName;
    bindSize(dash, lk, sz.indeterminateLength, dashThickness);
    if (markThicknessVar) dash.setBoundVariable('height', markThicknessVar);
    bindRadiusN(dash, lk, f.indeterminateBorderRadius.topLeft);
    fillData(dash, lk, colorData(mark));
    glyphs.appendChild(dash);
    dash.x = (glyphSide - dashLength) / kHalf;
    dash.y = (glyphSide - dashThickness) / kHalf;
    dash.visible = values.Checked === 'indeterminate';

    // The halo — hover / pressed only. Child 0 of the box so it sits under
    // the glyphs (and under the box's own fill? no: a frame paints its fill
    // beneath its children, so the halo paints OVER the fill — which is the
    // stacking the widget has, ink washed over the box AND its surround).
    // Its opacity is the ramp's weight; the ink stays a bound token.
    const layerAlpha =
      state === 'pressed'
        ? f.stateLayer.pressed
        : state === 'hover'
          ? f.stateLayer.hover
          : null;
    if (layerAlpha != null) {
      const spread = dimVal(f.stateLayerSpread);
      const halo = figma.createRectangle();
      halo.name = 'state layer';
      bindSize(halo, lk, boxSide + spread * kHalf, boxSide + spread * kHalf);
      bindRadiusN(halo, lk, f.stateLayerBorderRadius.topLeft);
      fillData(halo, lk, colorData(f.stateLayerColor));
      halo.opacity = layerAlpha;
      // `insertChild` first, then pin: `pinAbsolute` appends, so pinning and
      // then moving to index 0 reparents the same node twice.
      b.insertChild(0, halo);
      pinInFlow(b, halo);
      halo.x = -spread;
      halo.y = -spread;
      halo.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };
    }

    // The ring — focus only, around the BOX. Visible as the pose and not
    // bound: there is no `Show focus ring` property on this set. Geometry
    // is the checkbox's OWN `focusOutlineStyle` slot (the `Clickable`'s
    // ring is off), over the box's corner.
    if (state === 'focus') {
      focusRing(b, lk, {
        outline: f.focusOutlineStyle,
        color: colorData(f.focusOutlineStyle.borderColor),
        corner: f.boxBorderRadius.topLeft,
        width: boxSide,
        height: boxSide,
        visible: true,
      });
    }

    c.appendChild(b);

    // The label IS the `suffix` slot — checkbox.dart resolves
    // `widget.suffix ?? Text(widget.label)`, so this node is the one that
    // slot renders and the property bound to it is named `Suffix`.
    // The label and the description stack in one column — the widget's
    // `Column(children: [label, Gap, description])`. The column's own
    // spacing is `labelDescriptionGapStyle`, a different axis from the
    // row's `indicatorLabelGapStyle` above.
    const content = autoFrame('content', 'VERTICAL');
    content.counterAxisAlignItems = 'MIN';
    content.itemSpacing = dimVal(f.labelDescriptionGapStyle.size);
    c.appendChild(content);

    const lb = makeLabel('이용약관에 동의합니다', lk, typographyColorOpts(lk, label, labelColor));
    content.appendChild(lb);
    lb.layoutSizingHorizontal = 'HUG';
    lb.layoutSizingVertical = 'HUG';

    const desc = makeLabel(
      '선택 사항이에요.',
      lk,
      typographyColorOpts(lk, description, descriptionColor),
    );
    content.appendChild(desc);
    desc.layoutSizingHorizontal = 'HUG';
    desc.layoutSizingVertical = 'HUG';
    desc.visible = false;

    content.layoutSizingHorizontal = 'HUG';
    content.layoutSizingVertical = 'HUG';

    // `trailing` sits after the content column — the end of the row. A
    // glyph slot rather than copy, because what it holds is an affordance
    // (a disclosure chevron), not a second label. Its size is the app root's
    // ambient icon size on every size row, not the box's: both platforms add
    // the caller's `trailing` to the row as handed, and neither puts an
    // `IconTheme` around it (Flutter's only one wraps the checkmark), so an
    // `Icon` passed there does not follow the box. The glyph inside FILLS the
    // holder, so a swapped-in larger icon does not spill out of the slot.
    const trailing = iconSlot(
      'trailing',
      'chevron-right',
      lk,
      ICON.constants.ambientSize,
      labelColor,
      trailingSwap.variant,
    );
    trailing.holder.visible = false;
    c.appendChild(trailing.holder);
    if (trailing.icon) {
      trailing.icon.layoutSizingHorizontal = 'FILL';
      trailing.icon.layoutSizingVertical = 'FILL';
    }

    slots.push({ content, label: lb, prefix, description: desc, trailing });
  }
  const set = mount.finish();
  // Both slots are TEXT, not INSTANCE_SWAP, because both are drawn as copy:
  // the widget hands each one the label typography, so a glyph would be the
  // wrong shape for either.
  const suffixId = defineProp(set, 'Suffix', 'TEXT', '이용약관에 동의합니다');
  // `CoreCheckboxContract.label` is a `String?` and `suffix` a `W?`, and a box
  // with neither — the bare indicator a table row or a list's select-all
  // carries — is a pose the code draws (`widget.suffix ?? (widget.label !=
  // null ? Text(...) : null)`). So the label carries `Show label` beside its
  // TEXT, on by default, the same pair Radio's label has.
  //
  // `Show label` hides the whole column, not just the label (#5605). A hugging
  // frame whose children are all hidden keeps its last size, so hiding the
  // label alone left the bare box at the labelled width (xs 72 for an 18 box)
  // with the row gap still before it. A BOOLEAN cannot answer "label or
  // description", so the column follows the label: the description-only pose
  // the widget can build (`label == null`, `description != null`) is not
  // drawable here — rare, and the bare box a table row carries is not.
  const showLabelId = defineProp(set, 'Show label', 'BOOLEAN', true);
  const showPrefixId = defineProp(set, 'Show prefix', 'BOOLEAN', false);
  const prefixId = defineProp(set, 'Prefix', 'TEXT', '알림 받기');
  const showDescriptionId = defineProp(
    set,
    'Show description',
    'BOOLEAN',
    false,
  );
  const descriptionId = defineProp(
    set,
    'Description',
    'TEXT',
    '선택 사항이에요.',
  );
  const showTrailingId = defineProp(set, 'Show trailing', 'BOOLEAN', false);
  const trailingId = defineProp(set, 'Trailing', 'INSTANCE_SWAP', trailingSwap.id);
  for (const s of slots) {
    bindTextProp(s.label, suffixId);
    bindVisibleProp(s.content, showLabelId);
    bindVisibleProp(s.prefix.holder, showPrefixId);
    bindTextProp(s.prefix.text!, prefixId);
    bindVisibleProp(s.description, showDescriptionId);
    bindTextProp(s.description, descriptionId);
    bindVisibleProp(s.trailing.holder, showTrailingId);
    bindSwapProp(s.trailing.icon!, trailingId);
  }
  vStackSet(set);
  return set;
}

// The ladder's rungs, in the order a designer reads them — `disabled` last, as
// on `Button`, because it is the one nobody clicks through looking for.
const kToggleStates = stateAxis(['enabled', 'hover', 'focus', 'pressed', 'disabled']);

type ToggleState = (typeof kToggleStates)[number];

interface ToggleSlots {
  label: TextNode;
  prefix: SlotNodes;
  ring: FocusRingNodes;
}

// The label a size row draws: the row's role (the 13 / 14 / 15 / 15 / 15
// ladder at body weight) over the field default, which is where the colour
// lives — the same `defaultLabelStyle.merge(row.labelStyle)` both resolvers
// compose. A row states only the role, so every other field falls through.
function toggleLabelStyle(
  row: Parameters<typeof textStyleData>[0],
): ReturnType<typeof textStyleData> {
  const base = textStyleData(TOGGLE.fields.labelStyle);
  const size = textStyleData(row);
  return {
    fontSize: size.fontSize ?? base.fontSize,
    fontWeight: size.fontWeight ?? base.fontWeight,
    lineHeight: size.lineHeight ?? base.lineHeight,
    color: size.color ?? base.color,
    role: size.role ?? base.role,
    letterSpacing: size.letterSpacing ?? base.letterSpacing,
  };
}

function buildToggle(page: PageNode, lk: VarLookup): ComponentSetNode {
  const variantData = new Map(Object.entries(TOGGLE.variants.defaultsByVariant));
  const variant = variantData.get('default');
  if (!variant) throw new Error('Toggle: `defaultsByVariant` has no `default` row');
  const sizeData = new Map(Object.entries(TOGGLE.sizes.defaultsBySize));
  const members = enumerateAxisAssignments([
    { axis: 'Size', values: [...sizeData.keys()] },
    { axis: 'State', values: [...kToggleStates] },
    { axis: 'On', values: ['false', 'true'] },
  ]);
  const mount = mountSet(page, 'Toggle', members.map((m) => m.name));
  const slots: ToggleSlots[] = [];
  for (const { name: comboName, values } of members) {
    const sz = sizeData.get(values.Size);
    if (!sz) throw new Error(`Toggle: no size data for combo "${comboName}"`);
    const state = values.State as ToggleState;
    const disabled = state === 'disabled';
    const on = values.On === 'true';
    const label = toggleLabelStyle(sz.labelStyle);
    // The thumb's offset, measured inside the padded box, matching the
    // widget's `AnimatedPositioned` under `OutlinedContainer(padding:)` — the
    // padding is the frame's, so adding it here would apply it twice.
    // Keyed on `On` alone: `left:` reads `widget.value` and nothing else, so a
    // disabled toggle keeps the thumb where its value put it.
    const offY = 0;
    const offX = on ? dimVal(sz.thumbOffset) : dimVal(TOGGLE.fields.inactiveThumbOffset);
    // `toggle.dart`'s ladder: `!_enabled` first, then `widget.value`. Hover /
    // pressed / focus keep the rest fill — their chrome is the layer and the
    // ring drawn below, not a different track colour.
    const trackColor = disabled
      ? on
        ? variant.disabledActiveTrack
        : variant.disabledInactiveTrack
      : on
        ? variant.activeTrack
        : variant.inactiveTrack;
    const thumbColor = disabled
      ? on
        ? variant.disabledThumb
        : variant.disabledInactiveThumb
      : on
        ? variant.activeThumb
        : variant.inactiveThumb;
    const labelColor = disabled
      ? colorData(variant.disabledForegroundColor)
      : label.color;
    const c = mount.getOrCreate(comboName);
    // The Row inside `Clickable`, whose `Gap(gapStyle: iconLabelGapStyle)`
    // siblings are this row's itemSpacing — see the same note in
    // buildCheckbox for both halves.
    applyFormRowChrome(c, lk, dimVal(sz.iconLabelGapStyle.size));

    const prefix = textSlot('prefix', '알림 받기', lk, label, labelColor);
    c.appendChild(prefix.holder);

    // The widget is `OutlinedContainer(padding:) > Stacks >
    // AnimatedPositioned(left: value ? thumbOffset : inactiveThumbOffset)`,
    // so the padding is on the OUTER box and the thumb offsets are measured
    // inside it. `thumbOffset` equals `trackWidth − thumbSize − padding.l −
    // padding.r` in every size row — the travel inside the padded box.
    const track = figma.createFrame();
    // Named so a composing parent can reach it, and so a designer selecting
    // the layer reads what it is. `SwitchField` forwards `activeColor` /
    // `inactiveColor` into this toggle's track (`switch_field.dart` passes them
    // as `trackActiveColor` / `trackInactiveColor`), and an unnamed node is one
    // a parent cannot address.
    track.name = kToggleTrackName;
    track.layoutMode = 'HORIZONTAL';
    applyChrome(track, lk, {
      pl: sz.padding.l,
      pr: sz.padding.r,
      pt: sz.padding.t,
      pb: sz.padding.b,
    });
    const trackWidth = dimVal(sz.trackWidth);
    const trackHeight = dimVal(sz.trackHeight);
    bindSize(track, lk, sz.trackWidth, sz.trackHeight);
    track.primaryAxisSizingMode = 'FIXED';
    track.counterAxisSizingMode = 'FIXED';
    bindRadiusN(track, lk, sz.trackBorderRadius.topLeft);
    fillData(track, lk, colorData(trackColor));
    track.clipsContent = false;

    // The state layer — the track's own ink over its fill, child 0 so it sits
    // over the fill and under the thumb, the same stacking `Color.alphaBlend`
    // / `color-mix()` produce on the two platforms. Its OPACITY is the weight
    // (a bound colour would overwrite a paint alpha — see `solid`), so the
    // token stays bound and follows the theme. Drawn only on the two rungs
    // that wash, as `Chip` does — the designer's canvas keeps a hidden copy on
    // the other three, and a hidden node paints nothing either way.
    const layerAlpha =
      state === 'pressed'
        ? TOGGLE.fields.stateLayer.pressed
        : state === 'hover'
          ? TOGGLE.fields.stateLayer.hover
          : null;
    if (layerAlpha != null) {
      const stateLayer = figma.createRectangle();
      stateLayer.name = 'state layer';
      stateLayer.resize(trackWidth, trackHeight);
      bindRadiusN(stateLayer, lk, sz.trackBorderRadius.topLeft);
      fillData(
        stateLayer,
        lk,
        colorData(on ? variant.activeStateLayer : variant.inactiveStateLayer),
      );
      stateLayer.opacity = layerAlpha;
      track.appendChild(stateLayer);
      pinInFlow(track, stateLayer);
      stateLayer.x = 0;
      stateLayer.y = 0;
      stateLayer.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };
    }

    // The `Stacks` — the coordinate space the offsets are relative to. Its
    // own frame carries no chrome; it exists so the thumb's x means what the
    // widget's `left:` means.
    const travel = figma.createFrame();
    travel.name = 'travel';
    travel.layoutMode = 'NONE';
    travel.fills = [];
    travel.clipsContent = false;
    track.appendChild(travel);
    travel.layoutSizingHorizontal = 'FILL';
    travel.layoutSizingVertical = 'FILL';
    // A square of `thumbSize` — which is ALSO the content height: every row
    // states `thumbSize = trackHeight − padding.t − padding.b`, so the
    // `AspectRatio(1)` under a tight-height `AnimatedPositioned` and the
    // stated size agree, and the size can bind to its own token (`size/12`).
    const thumb = figma.createEllipse();
    bindSize(thumb, lk, sz.thumbSize, sz.thumbSize);
    fillData(thumb, lk, colorData(thumbColor));
    // Apply the Core recipe to the moving thumb, not the track. The default
    // is a faint drop + contact ring that carries the white off thumb's
    // outline on the light off track, in every state.
    setShadow(thumb, TOGGLE.fields.thumbShadow, lk, colorData(TOGGLE.fields.thumbShadowBaseColor));
    travel.appendChild(thumb);
    thumb.x = offX;
    thumb.y = offY;
    // Pinned to the edge it rests against, so a resized instance keeps the
    // thumb flush with the same padded edge the widget keeps it flush with.
    thumb.constraints = { horizontal: on ? 'MAX' : 'MIN', vertical: 'CENTER' };
    c.appendChild(track);

    // Same `widget.suffix ?? Text(widget.label)` resolution as Checkbox —
    // this node is the `suffix` slot, and carries that name's property.
    const lb = makeLabel('다크 모드', lk, typographyColorOpts(lk, label, labelColor));
    c.appendChild(lb);
    lb.layoutSizingHorizontal = 'HUG';
    lb.layoutSizingVertical = 'HUG';

    // The `FocusOutline` around the TRACK — `toggle.dart` wraps the track in
    // one and switches the Clickable's row-wide ring off, so the ring says
    // "the switch" and not "the switch and its label". Geometry is the
    // recipe's own `focusOutlineStyle`; the corner is the slot's pill.
    const ring = focusRing(track, lk, {
      outline: TOGGLE.fields.focusOutlineStyle,
      color: colorData(TOGGLE.fields.focusOutlineStyle.borderColor),
      corner: TOGGLE.fields.focusOutlineStyle.borderRadius.topLeft,
      width: trackWidth,
      height: trackHeight,
      // A focused toggle wears its ring — the state says so. The BOOLEAN
      // below still exists for the other four rungs, where the ring is a
      // pose a designer opts into rather than the state itself.
      visible: state === 'focus',
    });
    slots.push({ label: lb, prefix, ring });
  }
  const set = mount.finish();
  const suffixId = defineProp(set, 'Suffix', 'TEXT', '다크 모드');
  // `suffix` is `W?` like `prefix`; it defaults ON because a bare toggle on
  // the canvas is unreadable without a label. A composing parent that brings
  // its own label (`SwitchField`) turns it off through the property — a
  // hidden-text override on the instance did not survive the next run.
  const showSuffixId = defineProp(set, 'Show suffix', 'BOOLEAN', true);
  const showPrefixId = defineProp(set, 'Show prefix', 'BOOLEAN', false);
  const prefixId = defineProp(set, 'Prefix', 'TEXT', '알림 받기');
  const showFocusId = defineShowFocusRing(set);
  for (const s of slots) {
    bindTextProp(s.label, suffixId);
    bindVisibleProp(s.label, showSuffixId);
    bindVisibleProp(s.prefix.holder, showPrefixId);
    bindTextProp(s.prefix.text!, prefixId);
    // NOT bound on the focus members — a bound `visible` has exactly one
    // source of truth, the property, and its default `false` would take the
    // ring straight back off the state that exists to show it. Same as
    // `Button`.
    bindShowFocusRing(s.ring, showFocusId);
  }
  vStackSet(set);
  return set;
}

// ─── RadioGroup ──────────────────────────────────────────────────────────────
// Renamed from Figma's "Radio" (#3742) — coui_core has no standalone `Radio`
// class, only `RadioGroup` (CoreRadioGroupStyle). Data-driven from coui_core
// RADIO_GROUP.
//
// ─── Four axes: Variant × Size × State × Selected ────────────────────────────
//
// `Variant` is `CoreRadioGroupVariant` as the schema promotes it, spelled the
// way the schema spells it (`defaultVariant` · `card`): the plain row, and the
// selectable tile — see "The `card` variant" below. `defaultsByVariant` keys
// the same two rows `default` / `card`.
//
// `State` is declared here, like `Chip`'s and `Toggle`'s — `Enabled` folds into
// it (`disabled` is a rung) and the three pointer rungs are what `radio_group
// .dart` and the `Clickable` it wraps the row in actually paint:
//
//   · `enabled`  — rest. Ring `borderColor` (`outline`) at the size row's
//     resting width, no fill; selected swaps the ring to `activeColor` at the
//     row's selected width. The selection is said by the ring: the dot is
//     `innerDotSize`, which is 0 unless a caller states one, and a zero-sized
//     dot draws nothing (the ring encloses a hole of `indicatorSize − 2 ×
//     selected width`).
//   · `hover` / `pressed` — rest chrome plus the STATE LAYER: a circle
//     `stateLayerSpread` px outside the ring, `stateLayerColor` at the ramp's
//     hover / pressed weight (`stateLayer.hover` / `.pressed`). It stands
//     outside the box because a wash confined to a 12–24 px interior is
//     invisible — which is also why it is its own child of the ring frame
//     (beside the dot, when a caller states one) rather than a fill on the ring.
//   · `focus` — rest chrome plus the `FocusOutline` band + ring, shown on the
//     member itself. No state layer: the ramp's `focus` weight is stated by
//     `CoreStateLayer` but drawn by neither platform nor the canvas.
//   · `disabled` — the widget's first branch for the fill and the label:
//     fill `disabledBackgroundColor`, label `disabledForegroundColor`. The
//     ring follows the selection inside it — unselected `disabledBorderColor`
//     at the resting width, selected `disabledActiveColor` (disabled content)
//     at the selected width, and a dot, when a caller states one,
//     `disabledActiveColor`. With no dot the ring's colour and width are the
//     only selection mark, so a disabled *selected* radio still reads as
//     selected.
//
// `Selected` is the pose axis this builder declares — which option is chosen
// is the group's VALUE (`radio_group.axes.state` is null), the way `buildToggle`
// declares `On`. `kAxisOrder` seats it after `State`, so `enumerateAxisAssignments`
// spells the canvas's names byte for byte.
//
// ─── The FocusOutline ────────────────────────────────────────────────────────
//
// `radio_group.dart` builds `FocusOutline(focused: _focusing && isSelected,
// shape: .circle, child: <indicator>)` around the INDICATOR, not the row (the
// row's own `Clickable` has `focusOutline: false`). So the band + ring pin to
// the ring frame here, from `FocusOutline`'s own recipe — the widget passes no
// `focusOutlineStyle:`, so the colour and circle radius are exactly the
// child's defaults at run time too. Drawn by the shared `focusRing`, which is
// the widget's geometry (`align` out, `borderWidth` INSIDE that edge, the band
// filling the gap behind).
//
// Visible on `State=focus` and NOT bound there: a bound `visible` has one source
// of truth — the property — and binding would hand the focus member the default
// `false`. On the other four rungs it stays a pose behind `Show focus ring`.
//
// ─── The `card` variant ──────────────────────────────────────────────────────
//
// A card group draws each option as a tile: `FocusOutline(rectangle) >
// OutlinedContainer(tile chrome) > Stacks[state layer, Padding(tilePadding) >
// Row]` on Flutter, the `<label>` tile with its layer and body on Web. So a card
// member IS the tile — its face, border and corner, padded by the size row's
// `tilePadding` — and the state layer and the focus ring move off the indicator
// onto it. The indicator inside is the bare ring: no halo, no ring of its own.
//
//   · face · border — `tileBackgroundColor` / `tileBorderColor` at
//     `tileBorderWidth` at rest, `tileSelectedBackgroundColor` /
//     `tileSelectedBorderColor` at `tileSelectedBorderWidth` when selected.
//     The heavier selected stroke is drawn inward (Flutter takes it off the
//     padding, Web paints it as an inset shadow), so a selection moves
//     nothing; the canvas strokes INSIDE, which is the same picture. A
//     disabled tile keeps its face and width and takes the card row's
//     `disabledBorderColor` for its edge, selected or not.
//   · material · cast — an enabled tile is a content surface on both
//     platforms (Flutter's `OutlinedContainer` at its default role, the Web
//     `<label>`'s surface marker), so its face rides the `material` layers
//     and follows the style's share, frost and bend. The Web marker is gated
//     on `enabled`, so a disabled tile keeps the single fill. Every tile takes
//     the style's contributed cast: it states no shadow, and both platforms
//     give such a tile the cast in every pose. No rim — the rim belongs to a
//     surface that casts a shadow it states.
//   · state layer — the whole face in `stateLayerColor` at the ramp's hover /
//     pressed weight, under the content and rounded to the tile's corner (the
//     widget clips it there).
//   · focus ring — `FocusOutline`'s own recipe around the tile, its corner
//     derived from the tile's.
//
// The size layer is `CoreRadioGroupStyle.sizeDefaultsFor`: the card row laid
// over the size row, with the card row's two text roles REPLACING the size
// row's rather than merging into them (the size row's label is a bare
// `fontSize`, which a merge would keep under the card's title role). The card
// rows state the indicator, the gaps, the text roles and the tile's padding and
// corner; the inner dot is the size row's.
//
// ─── The description ─────────────────────────────────────────────────────────
//
// `CoreRadioItemContract.description` — the supporting line under the label,
// in its own column with it (`Column(label, Gap(labelDescriptionGapStyle),
// description)`), on both variants. A `String?`, so one TEXT node carries the
// BOOLEAN and the words. Off by default, the code's `null`: a component
// property has one default across the set, and the option a row is usually
// reached for — a plain radio, or the compact tile — has none.
//
// The widget top-aligns the row once the description is there and centres it
// otherwise. `Show description` is a BOOLEAN, not an axis, so a member draws
// one of the two — the centred row its default pose is, as Checkbox does.
//
// ─── The label ───────────────────────────────────────────────────────────────
//
// `CoreRadioItemContract.label` is a `String?` too, and a tile holding a bare
// indicator is a pose the code draws. So the label carries `Show label` (on by
// default — an option is usually reached for with its words) beside its TEXT.
// With the label off, the description stands alone in the column, as the
// widget builds it. With both off the widget drops the column and the gap
// before it, while the canvas keeps an empty column and that gap: a BOOLEAN
// can hide a node but cannot answer "label or description".
const kRadioGroupStates = stateAxis(['enabled', 'hover', 'focus', 'pressed', 'disabled']);

type RadioGroupState = (typeof kRadioGroupStates)[number];

// The copy the description node opens on — example copy for the `Label` above.
const kRadioDescription = '매달 자동으로 결제돼요.';

interface RadioGroupSlots {
  content: FrameNode;
  label: TextNode;
  description: TextNode;
  ring: FocusRingNodes;
}

function buildRadioGroup(page: PageNode, lk: VarLookup): ComponentSetNode {
  const variantData = new Map(Object.entries(RADIO_GROUP.variants.defaultsByVariant));
  const sizeData = new Map(Object.entries(RADIO_GROUP.sizes.defaultsBySize));
  // The card's tile rows — the overlay `sizeDefaultsFor` lays over `sizeData`.
  const cardSizeData = new Map(Object.entries(RADIO_GROUP.sizes.cardDefaultsBySize));
  // The role and the colour come from the component field; the SIZE comes
  // from the row — Button's ladder (12/13/14/16/16/16), same as Checkbox.
  const labelBase = textStyleData(RADIO_GROUP.fields.labelStyle);
  // The description's foreground; its role is each size row's (one step under
  // the label), merged over it the way both resolvers do.
  const descriptionBase = textStyleData(RADIO_GROUP.fields.descriptionStyle);
  const variantAxis = RADIO_GROUP.axes.variant;
  if (!variantAxis) throw new Error('RadioGroup: `CoreRadioGroupVariant` is not `radio_group.axes.variant`');
  // Loud on a value this builder draws no look for: a third variant added to
  // the enum would otherwise be drawn as the plain row and never reported.
  for (const m of variantAxis.members) {
    if (m !== 'defaultVariant' && m !== 'card') {
      throw new Error(`RadioGroup: \`Variant=${m}\` has no look in buildRadioGroup — draw it, or hide it in the enum`);
    }
  }
  // `indicatorDotStyle` is the dot's nested `CoreIconStyle` slot, and
  // radio_group_style.dart consults it BEFORE both of the values the dot is
  // otherwise drawn from:
  //
  //   innerDotSize:  merged.innerDotSize ?? merged.indicatorDotStyle?.size ?? ss.innerDotSize
  //   dotColor:      indicatorDotStyle.color ?? activeColor
  //
  // It is `{}` in the export — every field unset, which is what a raw-forwarded
  // slot looks like when the child supplies its own defaults — so the JSON type
  // carries no `size` / `color` member and `optField` is how an
  // absent-but-outranking field is read; both fall through to the size row /
  // active token, which is what the resolver does with the same nulls.
  const dotSlot = RADIO_GROUP.fields.indicatorDotStyle;
  const dotSlotSize = optField<Dim>(dotSlot, 'size');
  const dotSlotColor = optField<Color>(dotSlot, 'color');
  const ramp = RADIO_GROUP.fields.stateLayer;
  const stateLayerSpread = dimVal(RADIO_GROUP.fields.stateLayerSpread);
  const members = enumerateAxisAssignments([
    { axis: 'Variant', values: variantAxis.members },
    { axis: 'Size', values: [...sizeData.keys()] },
    { axis: 'State', values: [...kRadioGroupStates] },
    { axis: 'Selected', values: ['false', 'true'] },
  ]);
  const mount = mountSet(page, 'RadioGroup', members.map((m) => m.name));
  const slots: RadioGroupSlots[] = [];
  for (const { name: comboName, values } of members) {
    const isCard = values.Variant === 'card';
    const variant = variantData.get(isCard ? 'card' : 'default');
    if (!variant) throw new Error(`RadioGroup: no variant row for combo "${comboName}"`);
    const sz = sizeData.get(values.Size);
    if (!sz) throw new Error(`RadioGroup: no size data for combo "${comboName}"`);
    const cardRow = cardSizeData.get(values.Size);
    if (!cardRow) throw new Error(`RadioGroup: no card size data for combo "${comboName}"`);
    const state = values.State as RadioGroupState;
    const disabled = state === 'disabled';
    const selected = values.Selected === 'true';
    // The size layer this member draws — the size row, or the card row laid
    // over it (see the section note). The inner dot is the size row's on both:
    // the card rows state none.
    const indicatorSize = isCard ? cardRow.indicatorSize : sz.indicatorSize;
    const indicatorLabelGap = isCard
      ? cardRow.indicatorLabelGapStyle.size
      : sz.indicatorLabelGapStyle.size;
    // The ring is the selection mark: a selected ring is drawn at the size row's
    // selected width in every pose, disabled included, and every other ring at
    // the resting width — `resolveRadioGroup`'s two ring bundles. Every width a
    // row states is a step of the stroke ladder (the larger sizes' selected ring
    // is `stroke/5`), so `lk.stroke` throws by name in a document whose Import
    // has not run: Import comes before Generate, and the entry fails whole rather
    // than drawing a ring on an unbound width.
    const strokeN = dimVal(
      isCard
        ? selected
          ? cardRow.selectedIndicatorBorderWidth
          : cardRow.indicatorBorderWidth
        : selected
          ? sz.selectedIndicatorBorderWidth
          : sz.indicatorBorderWidth,
    );
    // The ring's fill does not change on selection — only the border (colour
    // and width) and the separately-drawn dot do. The fill takes the disabled
    // branch first, as in the widget; the ring colour is the disabled pair's
    // selected / unselected half.
    const fill = disabled
      ? variant.disabledBackgroundColor
      : variant.uncheckedBackground;
    const border = disabled
      ? selected
        ? variant.disabledActiveColor
        : variant.disabledBorderColor
      : selected
        ? variant.activeColor
        : variant.borderColor;
    // The dot: slot size outranks the size row, slot colour outranks the
    // active token, and disabled replaces whichever colour won.
    const dotSide = dimVal(dotSlotSize ?? sz.innerDotSize);
    const dotColor = disabled
      ? variant.disabledActiveColor
      : (dotSlotColor ?? variant.activeColor);
    // `sz.labelStyle` carries only this size's `fontSize`; everything else
    // stays the field's. A card row states a role instead — the tile's title —
    // which replaces the size step rather than sitting under it.
    const label = isCard
      ? mergeTextStyleData(labelBase, textStyleData(cardRow.labelStyle))
      : { ...labelBase, fontSize: dimVal(sz.labelStyle.fontSize) };
    const labelColor = disabled
      ? colorData(variant.disabledForegroundColor)
      : label.color;
    // The description: its row's role over the field's foreground, and the
    // label's disabled fold, so a disabled option dims as one block.
    const description = mergeTextStyleData(
      descriptionBase,
      textStyleData(isCard ? cardRow.descriptionStyle : sz.descriptionStyle),
    );
    const descriptionColor = disabled
      ? colorData(variant.disabledForegroundColor)
      : description.color;
    // The column's own spacing — the card rows state theirs; a plain row
    // states none and takes the field's.
    const labelDescriptionGap = isCard
      ? cardRow.labelDescriptionGapStyle.size
      : RADIO_GROUP.fields.labelDescriptionGapStyle.size;
    const c = mount.getOrCreate(comboName);
    // The Row inside `Clickable`, whose `Gap(gapStyle: indicatorLabelGapStyle)`
    // siblings are this row's itemSpacing — see the same note in buildCheckbox.
    applyFormRowChrome(c, lk, dimVal(indicatorLabelGap));
    if (isCard) {
      // The tile — face, border and corner on the member itself, its content
      // inset by `tilePadding`. The state layer and the focus ring below hang
      // off it; neither may be clipped by it, so the layer is rounded to the
      // tile's corner itself (see the section note).
      const face = selected
        ? RADIO_GROUP.fields.tileSelectedBackgroundColor
        : RADIO_GROUP.fields.tileBackgroundColor;
      const edge = disabled
        ? variant.disabledBorderColor
        : selected
          ? RADIO_GROUP.fields.tileSelectedBorderColor
          : RADIO_GROUP.fields.tileBorderColor;
      // The row inside the tile is `mainAxisSize: .min` at the tile's start,
      // so a tile stretched across a group keeps its content at the leading
      // edge rather than centring it.
      c.primaryAxisAlignItems = 'MIN';
      bindPad(c, lk, cardRow.tilePadding);
      bindRadiusN(c, lk, cardRow.tileBorderRadius.topLeft);
      // An enabled tile is a content surface on both platforms: Flutter
      // composes `OutlinedContainer` for it at its default role, and the Web
      // `<label>` carries `webSurfaceMarkerFor(.content)`. The Web marker is
      // gated on `enabled`, and the canvas draws a material only where both
      // platforms mark the surface, so a disabled tile keeps the single fill.
      // No rim: the tile states no shadow of its own.
      if (disabled) {
        fillData(c, lk, colorData(face));
      } else {
        applySurfaceMaterial(c, lk, colorData(face), 'content', {
          radius: cardRow.tileBorderRadius.topLeft,
        });
      }
      // Inside the tile, as `OutlinedContainer` draws its `Border.all` and the
      // Web `<label>` its `border-box`: the tile stays the size its padding
      // makes it whatever the width.
      c.strokeAlign = 'INSIDE';
      borderData(
        c,
        lk,
        colorData(edge),
        selected ? RADIO_GROUP.fields.tileSelectedBorderWidth : RADIO_GROUP.fields.tileBorderWidth,
      );
      // The tile states no shadow, so it takes the one a style contributes in
      // every pose — `OutlinedContainer` falls to `controlShadow` on an empty
      // stack, and the Web root carries the rest marker unconditionally.
      if (paintsFill(colorData(face))) addControlShadow(c, lk);
      c.clipsContent = false;
    }
    // The ring's own corner radius — `CoreRadioGroupStyle.indicatorBorderRadius`,
    // chained through both resolvers onto the composed `OutlinedContainer`
    // (`radius9999`, "fully round", a genuine numeric default rather than a
    // shape enum). `topLeft` stands in for the field: the four corners are
    // always equal for this indicator.
    const b = indicatorBox(
      lk,
      RADIO_GROUP.fields.indicatorBorderRadius.topLeft,
      indicatorSize,
    );
    b.clipsContent = false;
    // The ring lives INSIDE the indicator's box (Flutter's `Border.all`, Web's
    // `border-box`), so the box stays `indicatorSize` at every width and the
    // hole it encloses is `indicatorSize − 2 × ring`. Stated, not left to the
    // frame default, because that identity is the selection mark.
    b.strokeAlign = 'INSIDE';
    fillData(b, lk, colorData(fill));
    borderData(b, lk, colorData(border), strokeN);

    // ─── The state layer ───────────────────────────────────────────────────
    //
    // The ink at the rung's weight — what `radio_group.dart` selects between as
    // `hover` / `pressed` state-layer colour and `radio_group.dart` (Web)
    // raises through its scoped `:hover` / `:active` rules. A plain row lays
    // it as a circle `stateLayerSpread` px outside the ring on every side; a
    // card lays it over the whole tile (below, once the tile has its size).
    // Present on every member and hidden off the two rungs it belongs to, so a
    // designer sees one structure across the set.
    const layerAlpha =
      state === 'pressed' ? ramp.pressed : state === 'hover' ? ramp.hover : null;
    const stateLayer = figma.createRectangle();
    stateLayer.name = 'state layer';
    fillData(stateLayer, lk, colorData(RADIO_GROUP.fields.stateLayerColor));
    // A literal here: a layer's opacity binds to a percent FLOAT
    // (`VarLookup.opacity`, `bindLayerOpacity`), but this layer binds no rung,
    // so the ramp is written against the `state-layer/*` registry rather than
    // pointed at — the same arrangement `buildTextField`'s layer has. The
    // hover weight is the resting value on the hidden copies so a designer who
    // reveals one sees the lighter rung.
    stateLayer.opacity = layerAlpha ?? ramp.hover;
    stateLayer.visible = layerAlpha != null;
    if (!isCard) {
      // Child 0 of the ring, under the dot. It stands outside the box because
      // a wash confined to a 12–24 px interior is invisible.
      const layerSide = dimVal(indicatorSize) + stateLayerSpread * kHalf;
      stateLayer.resize(layerSide, layerSide);
      bindRadiusN(stateLayer, lk, RADIO_GROUP.fields.indicatorBorderRadius.topLeft);
      b.appendChild(stateLayer);
      pinInFlow(b, stateLayer);
      stateLayer.x = -stateLayerSpread;
      stateLayer.y = -stateLayerSpread;
      stateLayer.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };
    }

    // The inner dot — an `AnimatedContainer(shape: .circle)` centred inside
    // the composed ring, in the widget's tree on every member and scaled to
    // zero when unselected (that is what lets selection animate). It is drawn
    // here only when it has a size: `innerDotSize` is 0 unless a caller states
    // one (`indicatorDotStyle.size` or `innerDotSize`), a zero-sized circle
    // paints nothing, and `resize` refuses a zero extent — so the default
    // member carries no `dot` node and the ring alone says "selected". With a
    // stated size the node is on every member and hidden when unselected, so a
    // designer toggling `Selected` sees the same dot come and go.
    if (dotSide > 0) {
      const dot = figma.createEllipse();
      dot.name = 'dot';
      bindSize(dot, lk, dotSide, dotSide);
      fillData(dot, lk, colorData(dotColor));
      dot.visible = selected;
      b.appendChild(dot);
      pinInFlow(b, dot);
      dot.x = (dimVal(indicatorSize) - dotSide) / kHalf;
      dot.y = (dimVal(indicatorSize) - dotSide) / kHalf;
      dot.constraints = { horizontal: 'CENTER', vertical: 'CENTER' };
    }

    // A plain row puts the `FocusOutline` around the indicator: the indicator
    // in flow (so the wrapper hugs it) plus the band + ring the shared helper
    // pins to it — see the section note for why they sit on the ring and not
    // the row. A card's indicator is the bare ring; its ring goes around the
    // tile below.
    let ring: FocusRingNodes | null = null;
    if (isCard) {
      b.name = 'indicator';
      c.appendChild(b);
    } else {
      const outline = autoFrame('focus outline', 'HORIZONTAL');
      outline.primaryAxisAlignItems = 'CENTER';
      outline.counterAxisAlignItems = 'CENTER';
      outline.clipsContent = false;
      outline.appendChild(b);
      c.appendChild(outline);
      ring = focusRing(b, lk, {
        outline: {
          align: FOCUS_OUTLINE.fields.align,
          borderWidth: FOCUS_OUTLINE.fields.borderWidth,
          offsetColor: FOCUS_OUTLINE.fields.offsetColor,
        },
        color: colorData(FOCUS_OUTLINE.fields.borderColor),
        corner: FOCUS_OUTLINE.fields.circleBorderRadius.topLeft,
        width: dimVal(indicatorSize),
        height: dimVal(indicatorSize),
        visible: state === 'focus',
      });
    }

    // The label and the description stack in one column — the widget's
    // `Column(children: [label, Gap, description])`. The column's own spacing
    // is `labelDescriptionGapStyle`, a different axis from the row's
    // `indicatorLabelGapStyle` above.
    const content = autoFrame('content', 'VERTICAL');
    content.counterAxisAlignItems = 'MIN';
    bindSpaceField(content, 'itemSpacing', lk, dimVal(labelDescriptionGap));
    c.appendChild(content);

    const lb = makeLabel('월간 결제', lk, typographyColorOpts(lk, label, labelColor));
    content.appendChild(lb);
    lb.layoutSizingHorizontal = 'HUG';
    lb.layoutSizingVertical = 'HUG';

    const desc = makeLabel(
      kRadioDescription,
      lk,
      typographyColorOpts(lk, description, descriptionColor),
    );
    desc.name = 'description';
    content.appendChild(desc);
    desc.layoutSizingHorizontal = 'HUG';
    desc.layoutSizingVertical = 'HUG';
    desc.visible = false;

    content.layoutSizingHorizontal = 'HUG';
    content.layoutSizingVertical = 'HUG';

    if (isCard) {
      // Read once the content has settled the tile's box; both overlays are
      // absolute, so neither moves it.
      const tileWidth = c.width;
      const tileHeight = c.height;
      // Child 0, so the layer washes the face under the indicator and text —
      // the widget's `Stacks` puts it under the padded row. An enabled tile's
      // material layers go back under it when the entry settles, so it stays
      // over the fill they carry. Rounded to the tile's corner, which is what
      // the widget's clip does to it.
      stateLayer.resize(tileWidth, tileHeight);
      bindRadiusN(stateLayer, lk, cardRow.tileBorderRadius.topLeft);
      c.insertChild(0, stateLayer);
      pinInFlow(c, stateLayer);
      stateLayer.x = 0;
      stateLayer.y = 0;
      stateLayer.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };
      // `FocusOutline`'s own recipe around the tile, its corner the tile's —
      // the widget hands `FocusOutline` only that corner.
      ring = focusRing(c, lk, {
        outline: {
          align: FOCUS_OUTLINE.fields.align,
          borderWidth: FOCUS_OUTLINE.fields.borderWidth,
          offsetColor: FOCUS_OUTLINE.fields.offsetColor,
        },
        color: colorData(FOCUS_OUTLINE.fields.borderColor),
        corner: cardRow.tileBorderRadius.topLeft,
        width: tileWidth,
        height: tileHeight,
        visible: state === 'focus',
      });
    }
    if (!ring) throw new Error(`RadioGroup: no focus ring drawn for combo "${comboName}"`);
    slots.push({ content, label: lb, description: desc, ring });
  }
  const set = mount.finish();
  // `CoreRadioItem.label` is a `String?`, not a `W?` slot, so a BOOLEAN for its
  // null and a TEXT for its words are exactly its shape (see the section note).
  //
  // ─── Why `child` has no property here ────────────────────────────────────
  //
  // The contract's one composition slot is `child`, and radio_group.dart uses
  // it as `child ?? _buildOptionsLayout()` — it replaces the ENTIRE group body,
  // the Column/Wrap of every item. This component draws ONE item row, so there
  // is no node here that the slot stands for. An INSTANCE_SWAP bound to a
  // hidden holder beside the indicator would show in the panel as "put your
  // group body here" and put a component next to a single radio instead — a
  // property bound to the wrong node, which reads as covered and changes
  // nothing, the one failure `figma_slot_swappability` says it cannot see.
  //
  // Closing it means making this component the group: a Column whose built-in
  // options layout and whose `child` are the two mutually exclusive branches
  // the widget asserts on (`child != null || options != null`). Two exclusive
  // branches are a variant axis, not a boolean, and adding an axis renames
  // every variant here — which `mountSet().finish()` refuses without a
  // `VARIANT_RENAMES` entry (src/renames.ts). The group framing also has no
  // spacing to build from: `RADIO_GROUP.fields` carries no `itemSpacing`.
  // Bound to the whole label column, not the label — the reason is Checkbox's
  // (#5605): a column with every child hidden keeps its width.
  const showLabelId = defineProp(set, 'Show label', 'BOOLEAN', true);
  const labelId = defineProp(set, 'Label', 'TEXT', '월간 결제');
  // `description` is a `String?` — the BOOLEAN is its null, the TEXT its words.
  // Off by default; see the section note.
  const showDescriptionId = defineProp(set, 'Show description', 'BOOLEAN', false);
  const descriptionId = defineProp(set, 'Description', 'TEXT', kRadioDescription);
  // A drawing switch, not a code prop — the runtime decides focus through
  // `:focus-visible` / `Clickable.onFocus`. Left unbound on the `State=focus`
  // members, whose ring is already on.
  const showFocusId = defineShowFocusRing(set);
  for (const s of slots) {
    bindVisibleProp(s.content, showLabelId);
    bindTextProp(s.label, labelId);
    bindVisibleProp(s.description, showDescriptionId);
    bindTextProp(s.description, descriptionId);
    bindShowFocusRing(s.ring, showFocusId);
  }
  vStackSet(set);
  return set;
}

// ─── Slider ──────────────────────────────────────────────────────────────────

// Data-driven from coui_core SLIDER.fields — no variant/size dispatch on
// CoreSliderStyle, every value is a flat default.
//
// ─── What the old 240×36 / 120 / 110 literals actually were ──────────────────
//
// One of the four was a preview choice and three were the widget's arithmetic
// written out by hand:
//
//   240  the track's width. Still invented — the widget takes
//        `constraints.maxWidth` from its parent and no recipe says how wide a
//        slider is.
//   36   `containerPadding.t + thumbSize + containerPadding.b`. The component
//        states that inset (8 top and bottom) and it reached nothing: the
//        padding was invisible and the height it produces was retyped as a
//        constant, so a change to either token would have moved the widget and
//        left the canvas at 36.
//   110  `ratio * (trackWidth - thumbSize)` — the thumb's own offset formula.
//   120  `thumbOffset + thumbSize / 2` — the active track reaching the thumb's
//        centre, which is what `slider.dart` gives that `Container`'s width.
//
// The three derived ones are computed below from the ratio the preview picks, so
// the only number this builder still invents is the width.
//
// ─── `Enabled` axis, reached by ADOPTION ──────────────────────────────────────
//
// `CoreSliderContract` declares two composition slots, `leading` and `trailing`
// (stand-in labels in holders, `Show leading` / `Show trailing`, the way Range
// draws its min / max), plus the focus BOOLEAN below. The thumb wears the
// smallest step of the shadow scale and the focus ring wraps the thumb alone.
//
// The axis is new, and it is the whole of what `slider.axes` promotes (`variant`
// / `size` / `state` are all null). It exists because the recipe carries
// `disabledTrackColor` / `disabledActiveColor` and a single COMPONENT had no
// second pose to put them in, so both were stated by Core and reached no pixel.
//
// A COMPONENT cannot be turned into a COMPONENT_SET in place, so the loose node
// is ADOPTED rather than retired: `mountSet(…, { adoptLooseAs: 'Enabled=true' })`
// renames it to the combination it was already rendering — it read
// `trackColor` / `activeColor` and never the `disabled*` pair — and seeds the
// recycle map with it, so its id and key survive into the set. Retiring it
// instead would have destroyed the key that every composed instance points at,
// which is the reason adoption is the shape here and a `STRUCTURAL_MIGRATIONS`
// entry is not.
//
// Four things swap, which is what both resolvers say (`slider_style.dart`, and
// the Web twin line for line):
//
//   trackColor        → disabledTrackColor
//   activeColor       → disabledActiveColor
//   thumbColor        → disabledThumbColor        (a disabled fill of its own)
//   thumbBorderColor  → disabledThumbBorderColor  (a disabled ring of its own)
//
// The thumb used to keep its enabled fill and borrow `disabledActiveColor` for
// its ring; the redesign copy states a disabled fill and ring, so both are
// fields of their own now and nothing is borrowed.
//
// Nothing else moves: no opacity, no greyed tick labels. `disabledOpacity` is
// not a field this component has, and inventing a fade would be this builder
// deciding a design value.
async function buildSlider(page: PageNode, lk: VarLookup): Promise<ComponentSetNode> {
  const trackHeight = dimVal(SLIDER.fields.trackHeight);
  const thumbSize = dimVal(SLIDER.fields.thumbSize);
  const pad = SLIDER.fields.containerPadding;
  const trackWidth =
    kSliderPreviewWidth - dimVal(pad.l) - dimVal(pad.r);
  // `_handleUpdate`'s travel, read forwards: the thumb's left edge moves across
  // `trackWidth - thumbSize`, so at the preview's ratio it lands here, and the
  // active track ends at the thumb's centre.
  const thumbX = kSliderPreviewRatio * (trackWidth - thumbSize);
  const activeWidth = thumbX + thumbSize / kHalf;
  // Both bars are `centerStart` in a stack of the thumb's height.
  const barY = (thumbSize - trackHeight) / kHalf;

  const combos = enumerateAxisCombos(axisSpecsOf(SLIDER.axes));
  const mount = mountSet(page, 'Slider', combos, { adoptLooseAs: 'Enabled=true' });
  const rings: FocusRingNodes[] = [];
  const leadingHolders: FrameNode[] = [];
  const leadingLabels: TextNode[] = [];
  const trailingHolders: FrameNode[] = [];
  const trailingLabels: TextNode[] = [];
  for (const comboName of combos) {
    const combo = parseVariantKey(comboName);
    const disabled = combo['Enabled'] === 'false';
    // `enabled ? <token> : <disabled token>`, exactly as the resolver's three
    // colour locals read — see the section note for why the thumb's fill is not
    // one of them.
    const trackColor = disabled
      ? SLIDER.fields.disabledTrackColor
      : SLIDER.fields.trackColor;
    const activeColor = disabled
      ? SLIDER.fields.disabledActiveColor
      : SLIDER.fields.activeColor;
    const thumbBorderColor = disabled
      ? SLIDER.fields.disabledThumbBorderColor
      : SLIDER.fields.thumbBorderColor;
    const thumbColor = disabled
      ? SLIDER.fields.disabledThumbColor
      : SLIDER.fields.thumbColor;

    const c = mount.getOrCreate(comboName);
    // This node IS the `Padding(containerPadding)`: auto-layout with the inset
    // bound, so the value is on the node a designer inspects instead of folded
    // into its children's coordinates. Hugging the cross axis produces the
    // widget's own height — `pad.t + thumbSize + pad.b`. The main axis is
    // FIXED at the preview width (#4826): the widget's track takes
    // `constraints.maxWidth` from whatever hosts it, and a canvas track can
    // take the instance's width only as a FILL child — which a hugging row
    // refuses, so the row has to stop hugging for the track to follow.
    c.layoutMode = 'HORIZONTAL';
    c.clipsContent = false;
    c.fills = [];
    bindPad(c, lk, pad);
    lockWidth(c, kSliderPreviewWidth);
    c.counterAxisAlignItems = 'CENTER';
    // `Gap(gapStyle: slotGapStyle)` beside each slot, as the row's own
    // spacing: a hidden holder leaves the flow, so a slider with no slot
    // carries no gap — the widget draws a `Gap` only beside a slot.
    c.setBoundVariable('itemSpacing', lk.space(dimVal(SLIDER.fields.slotGapStyle.size)));
    const leadingHolder = autoFrame('leading', 'HORIZONTAL');
    leadingHolder.counterAxisAlignItems = 'CENTER';
    // The stand-in label wears `tickLabelStyle` — `slider.dart` wraps the whole row in
    // `DefaultTextStyle.merge(tickLabelTextStyle)`, so a slot's text inherits that role.
    const leadingLabel = makeLabel('0', lk, {
      ...textLabelOpts(lk, textStyleData(SLIDER.fields.tickLabelStyle)),
      // g7-preview-only: the ink of the stand-in min label — `leading` is a raw `Widget?`, so its colour is the caller's, and `CoreSliderStyle` states none.
      colorVar: lk.sem('on-surface-variant'),
    });
    leadingHolder.appendChild(leadingLabel);
    c.appendChild(leadingHolder);
    leadingHolders.push(leadingHolder);
    leadingLabels.push(leadingLabel);

    // `SizedBox(height: thumbSize, child: Stacks(alignment: .centerStart, …))` —
    // the box the three bars sit in, and the space the thumb's offset is measured
    // in. No auto-layout: the widget places all three by hand, and the offset is
    // meaningless without that origin. Only the height is bound — the width is the
    // invented preview number, and binding it would put a `Primitives/size/240`
    // claim on the node that the design system never made.
    const stack = figma.createFrame();
    stack.name = 'track';
    stack.layoutMode = 'NONE';
    stack.fills = [];
    stack.clipsContent = false;
    bindAxisSize(stack, lk, {
      width: trackWidth,
      height: SLIDER.fields.thumbSize,
      bind: 'height',
    });
    // Not in the row yet: the bars go in first (below), while the box is the
    // width they are drawn at. A constraint holds the margins a layer has when
    // it lands, so a rail appended to a box that already FILLs the row lands
    // in whatever width the row left it — narrower by the leading label and
    // its gap — and STRETCH keeps that overhang through every later resize:
    // the rail ran 21 past a 240 track once the labels hid (#6474).

    // How the picture follows a resize (#4826). The widget lays the three out
    // from `constraints.maxWidth` on every frame; a static node has one
    // constraint per layer instead, and they have to say the same thing:
    //   · rail   — STRETCH: the track is the box.
    //   · active — SCALE: it ends at `kSliderPreviewRatio` of the track, and a
    //              fraction is what SCALE keeps.
    //   · thumb  — a knob whose CENTRE is that fraction and whose SIZE is a
    //              token. Figma has no "scale my position, keep my size", so
    //              the knob rides in a `travel` frame that spans 0 → the active
    //              bar's end (SCALE) and is pinned to that frame's far edge
    //              (MAX): the edge moves by the ratio, the knob keeps
    //              `thumbSize`, and the active bar still ends at its centre —
    //              the invariant `_handleUpdate` states. The last thumb-width
    //              of travel is the one thing this cannot say exactly (the
    //              widget's left edge is `ratio × (track − thumbSize)`), so a
    //              widened track puts the canvas knob a fraction of
    //              `thumbSize` past where the widget would — never off the bar.
    const track = figma.createRectangle();
    track.name = 'rail';
    bindAxisSize(track, lk, {
      width: trackWidth,
      height: SLIDER.fields.trackHeight,
      bind: 'height',
    });
    bindRadiusN(track, lk, SLIDER.fields.borderRadius.topLeft);
    fillData(track, lk, colorData(trackColor));
    stack.appendChild(track);
    track.x = 0;
    track.y = barY;
    track.constraints = { horizontal: 'STRETCH', vertical: 'CENTER' };
    const fill = figma.createRectangle();
    fill.name = 'active';
    bindAxisSize(fill, lk, {
      width: activeWidth,
      height: SLIDER.fields.trackHeight,
      bind: 'height',
    });
    bindRadiusN(fill, lk, SLIDER.fields.borderRadius.topLeft);
    fillData(fill, lk, colorData(activeColor));
    stack.appendChild(fill);
    fill.x = 0;
    fill.y = barY;
    fill.constraints = { horizontal: 'SCALE', vertical: 'CENTER' };
    const travel = figma.createFrame();
    travel.name = 'travel';
    travel.layoutMode = 'NONE';
    travel.fills = [];
    travel.clipsContent = false;
    travel.resize(activeWidth, thumbSize);
    stack.appendChild(travel);
    travel.x = 0;
    travel.y = 0;
    travel.constraints = { horizontal: 'SCALE', vertical: 'STRETCH' };
    // `FocusOutline(child: thumb)` — the ring wraps the thumb, so the thumb
    // rides in a host the size of the thumb and the ring is measured from it.
    const thumbHost = figma.createFrame();
    thumbHost.name = 'thumb host';
    thumbHost.layoutMode = 'NONE';
    thumbHost.fills = [];
    bindSize(thumbHost, lk, SLIDER.fields.thumbSize, SLIDER.fields.thumbSize);
    travel.appendChild(thumbHost);
    // `Position(left: thumbOffset)` with the stack `centerStart` and the child as
    // tall as the stack — the thumb fills the box's height, so its top is 0. Its
    // x is the same offset, now measured inside `travel`, whose far edge is the
    // active bar's end: the knob's centre sits exactly there.
    thumbHost.x = thumbX;
    thumbHost.y = 0;
    thumbHost.constraints = { horizontal: 'MAX', vertical: 'MIN' };
    const thumb = figma.createEllipse();
    thumb.name = 'thumb';
    bindSize(thumb, lk, SLIDER.fields.thumbSize, SLIDER.fields.thumbSize);
    fillData(thumb, lk, colorData(thumbColor));
    borderData(
      thumb,
      lk,
      colorData(thumbBorderColor),
      SLIDER.fields.thumbBorderWidth,
    );
    thumbHost.appendChild(thumb);
    thumb.x = 0;
    thumb.y = 0;
    // The smallest step of the shadow scale (`thumbShadow`), linked to the
    // file's effect style when it states the same layers.
    setShadow(thumb, SLIDER.fields.thumbShadow, lk);
    await linkShadowStyle(thumb, SLIDER.fields.thumbShadow, 'Slider/thumb');
    // `FocusOutline(focused: _showFocusOutline, focusOutlineStyle:
    // resolved.focusOutlineStyle)` wraps the thumb (`slider.dart`). Hidden
    // behind a BOOLEAN for the reason Button's is: focus is a pose and a second
    // axis here is a node-identity change.
    rings.push(
      focusRing(thumbHost, lk, {
        outline: SLIDER.fields.focusOutlineStyle,
        color: colorData(SLIDER.fields.focusOutlineStyle.borderColor),
        corner: SLIDER.fields.focusOutlineStyle.borderRadius.topLeft,
        width: thumbSize,
        height: thumbSize,
        visible: false,
      }),
    );
    // Now the box joins the row and FILLs it: every bar is in at the width it
    // was drawn for, so the resize that FILL makes carries them by their
    // constraints instead of leaving the rail an overhang (see above).
    c.appendChild(stack);
    stack.layoutSizingHorizontal = 'FILL';
    const trailingHolder = autoFrame('trailing', 'HORIZONTAL');
    trailingHolder.counterAxisAlignItems = 'CENTER';
    const trailingLabel = makeLabel('100', lk, {
      ...textLabelOpts(lk, textStyleData(SLIDER.fields.tickLabelStyle)),
      // g7-preview-only: the ink of the stand-in max label — `trailing` is a raw `Widget?`, so its colour is the caller's, and `CoreSliderStyle` states none.
      colorVar: lk.sem('on-surface-variant'),
    });
    trailingHolder.appendChild(trailingLabel);
    c.appendChild(trailingHolder);
    trailingHolders.push(trailingHolder);
    trailingLabels.push(trailingLabel);
  }
  const set = mount.finish();
  // After `finish()`, on the SET (see Range): a fresh variant has no parent
  // until `combineAsVariants` runs, so the property would scatter per member.
  const showLeading = defineProp(set, 'Show leading', 'BOOLEAN', false);
  for (const node of leadingHolders) bindVisibleProp(node, showLeading);
  const leadingProp = defineProp(set, 'Leading', 'TEXT', '0');
  for (const node of leadingLabels) bindTextProp(node, leadingProp);
  const showTrailing = defineProp(set, 'Show trailing', 'BOOLEAN', false);
  for (const node of trailingHolders) bindVisibleProp(node, showTrailing);
  const trailingProp = defineProp(set, 'Trailing', 'TEXT', '100');
  for (const node of trailingLabels) bindTextProp(node, trailingProp);
  const showFocusId = defineShowFocusRing(set);
  for (const ring of rings) bindShowFocusRing(ring, showFocusId);
  // Two members, each 240 wide. A column stacks the enabled and disabled rails
  // at the same x, so the three colours that swap line up vertically and can be
  // read against each other — the same arrangement the other form sets in this
  // file take, and the wrap grid `finish()` applies would put these two side by
  // side with 240px between the two rails it is worth comparing.
  vStackSet(set);
  return set;
}

// ─── TextArea ────────────────────────────────────────────────────────────────

// Data-driven from coui_core TEXT_AREA.fields (borderRadius/borderWidth/
// activeBorderWidth/rowSpacing/affixColor/helperTextColor) + TEXT_AREA.sizes.defaultsBySize
// (padding/iconStyle) + `variants.defaultsByVariant`, which arrives whole here
// exactly as it does for buildTextField above. Two notes stood here in turn:
// the first said the recipe was silent about the container's fill and border,
// the second that `CoreTextAreaStyle.defaultsByVariant` states them
// (`backgroundColor` surface, `borderColor` outline / error, plus
// `focusRingColor` and a disabled trio) but that the export dropped the table —
// twice over, because the entries are references to the sibling
// `defaultNormalVariant` / `defaultErrorVariant` consts AND the key type is
// `Map<bool, …>`, which has no enum member name to normalise into a variant key.
// Both are fixed in the reader: the rows arrive under `'false'` / `'true'`, and
// every colour below is read from one. Nothing here is a literal.
//
// The placeholder is the variant row's `placeholderColor` — what both
// resolvers paint it with when no caller `placeholderStyle` states a colour
// (`vs.placeholderColor`), on the clean row and the error row alike. It is not
// the helper row's tone: an error turns the helper line `errorTextColor`, and
// the placeholder above it stays the placeholder colour.
//
// The affix glyphs wear `affixColor` in every pose — enabled, hover, focus,
// disabled, the error variant included — on both platforms and on `TextField`.
// A glyph that annotates the value does not change with the area's state; the
// value text and the boundary are what say "disabled". The helper line under
// the field is a different node with its own tone (`helperTextColor`,
// `errorTextColor` on the error variant).
//
// The row is HORIZONTAL with start cross-alignment, matching text_area.dart's
// `Row(crossAxisAlignment: .start, spacing: rowSpacing, children: [prefix,
// inputStack, suffix])`. It reads the same as the previous VERTICAL layout (a
// full-width placeholder pinned to the top) and is the arrangement the affix
// slots actually live in.
//
// ─── `Focus` axis ─────────────────────────────────────────────────────────────
//
// The same axis buildTextField grew, for the same reason and off the same
// fields: `text_area.dart` wraps its container in `FocusOutline(focused:
// _focusNode.hasFocus, focusOutlineStyle: resolved.focusOutlineStyle)` and hands
// the editable a caret, and `cursorColor` / `cursorRadius` were carried by
// `components.json` with nowhere on this component to land.
//
// A note here used to read "no state axis: as with TextField,
// `focusOutlineStyle` is the only state-keyed field and its ring belongs to a
// separate `FocusOutline` surface". Both halves are true and neither is a
// reason: `fields.focusOutlineStyle` states the ring's `align` and
// `borderWidth`, each variant row states its `focusRingColor`, and a ring drawn
// by a child component is one this builder can draw from the same slot the
// resolver merges.
//
// ─── What the four axes are here, and what the old `Variant=` was ─────────────
//
// `text_area.axes.variant` is null: `CoreTextAreaStyle` carries no variant enum
// at all, and the table above is keyed by BOOL — "is this field in its error
// state" is a boolean question in this recipe, not an enum. So the old
// `Variant=Error` child encodes an axis that does not exist in v3 (not in the
// four, not even in `axes.other`) and has no destination; it is retired by name
// in `src/renames.ts` rather than dropped, and `Variant=Default` migrates onto
// `Size=md, Enabled=true`. Every combination reads the `'false'` (clean) row —
// the error row's `borderColor` / `focusRingColor` are out of this axis system's
// reach, which is a different statement from unpainted, and worth writing down so
// a later `Error` pose has something to point at.
//
// `Enabled` is the axis that replaces it, and unlike the old `Variant=` it is
// the schema's own. What it draws is the same trio `text_area_style.dart`
// resolves in its `isDisabled` branch: bg → `disabledBackgroundColor`, border →
// `disabledBorderColor`, and the value → `disabledForegroundColor`; the affix
// glyphs are not in the trio (they wear `affixColor` in every pose, see the
// section note above). The caret follows `Enabled` as well as `Focus`, for
// the same reason as TextField: `readOnly: widget.readOnly || !widget.enabled`,
// and `showCursor` defaults to `!readOnly`.
//
// `defaultsBySize` stops at `xl` while the size axis carries six members, so
// `xl2` reads the `md` row — core carries no xl2 row and inventing one here is
// not this builder's call.
//
// `text_area.dart` opens a Column with `FormLabel(...)` + `Gap(labelGapStyle)`
// once a label is set, and that Column is this component: a real `FormLabel`
// INSTANCE hidden behind `Show label`, then the field. The gap between them
// is the Column's itemSpacing, which is what a `Gap` between two auto-layout
// siblings is. Unlike TextField there is no `Padding` wrapper around the label
// — the widget puts the FormLabel straight into the Column.
//
// ─── Two gaps in one stack, which is why there is a `body` frame ──────────────
//
// The widget's Column carries TWO different gaps — `Gap(labelGapStyle)` above
// the field and `Gap(descriptionGapStyle)` below it — and a Figma auto-layout
// stack has exactly one `itemSpacing`. The two values are equal today, so one
// spacing would look right and assert half of what the data says: change either
// token and the canvas would follow the wrong one.
//
// So the field and its helper row share an inner `body` stack whose spacing is
// `descriptionGapStyle`, and the outer Column's spacing stays `labelGapStyle`.
// Each value is bound where it applies, and the picture is unchanged — a hidden
// child contributes no gap, so with neither the label nor the helper shown the
// component is still exactly the field.
//
// ─── The resize grip ─────────────────────────────────────────────────────────
//
// `Stacks(fit: .passthrough, clipBehavior: .none)` overlays a
// `Position(right/bottom: dragHandleOffset)` box of `dragHandleSize`, inset by
// `dragHandlePadding`, holding a `CustomPaint` of two diagonal ticks. It is
// drawn here as the widget draws it: an SVG of those two lines (the painter's
// own coordinates, in the padded content box), stroked with `dragHandleColor`,
// pinned with Figma constraints so it stays on its corner at any width a
// designer drags the instance to — the box's bottom-right corner, or with a
// footer the end of the text row (see the note at the pin).
//
// Hidden behind a BOOLEAN because the widget's own default hides it too —
// `expandableHeight` and `expandableWidth` are both `false`, and the grip
// renders only `if (expandableHeight || expandableWidth)`.
function buildTextArea(page: PageNode, lk: VarLookup): ComponentSetNode {
  const sizeData = new Map(Object.entries(TEXT_AREA.sizes.defaultsBySize));
  const labelCells = formLabelSizeCells();
  // Both rows of `defaultsByVariant`, picked per member — `CoreTextAreaVariant`
  // now keys that table, so the Variant axis exists and the error row has a
  // place to be drawn. It did not before: the table was keyed by a bare `bool`
  // and the exporter promotes a `Core{Name}Variant` enum and nothing else, so
  // the twelve error members the designer drew had nowhere in code to land
  // while TextField's identical twelve did.
  //
  // The helper row below is ONE node because the widget's description and
  // error text are mutually exclusive (an error replaces the description), and
  // which of the two colours it wears is exactly the variant's question —
  // which is why `errorTextColor` waits here rather than at the top.
  const variantRows = TEXT_AREA.variants.defaultsByVariant;
  // `State` rather than `Enabled` × `Focus`, the same way TextField spells
  // it: the row states `hoverBorderColor` (`outline` → `on-surface`, the
  // error row restating `error`), and a pose axis pair has no member for the
  // pointer to land on — the hover border Core added reached no node. The
  // schema's `Enabled` is folded into `State=disabled` for the same reason
  // TextField folds it: enabled/hover/focus/disabled is one exclusive pose,
  // not two booleans that can both be true.
  const combos = enumerateAxisCombos([
    ...axisSpecsOf(TEXT_AREA.axes).filter((spec) => spec.axis !== 'Enabled'),
    { axis: 'State', values: [...kTextFieldStates] },
  ]);
  // Affix glyphs drawn from the swap defaults (see `iconSlot`).
  const prefixSwap = iconSwapDefault(page, 'TextArea', 'Prefix', iconSlotDefaultId());
  const suffixSwap = iconSwapDefault(page, 'TextArea', 'Suffix', iconSlotDefaultId());
  // The footer's default — the member drawn and the member the swap points
  // at, read once so the two cannot disagree. `primary` at `sm`, the send
  // action a footer is reached for; the other axes rest at Button's first
  // value.
  const footerVariant = bestVariantName(page, 'Button', { Variant: 'primary', Size: 'sm' });
  const mount = mountSet(page, 'TextArea', combos);
  const slots: {
    placeholder: TextNode;
    value: SlotNodes;
    prefix: SlotNodes;
    suffix: SlotNodes;
    footer: { holder: FrameNode; content: InstanceNode };
    label: InstanceNode;
    helper: SlotNodes;
    counter: SlotNodes;
    grip: SceneNode;
    ring: FocusRingNodes;
  }[] = [];
  for (const comboName of combos) {
    const combo = parseVariantKey(comboName);
    // Same pairing TextField makes: the variant row and the helper colour
    // that belongs with it, read together so they cannot disagree.
    const isError = combo['Variant'] === 'error';
    // Indexed, the way TextField picks its row: the unread-fields gate
    // (`check_figma_unread_fields.py`) follows a row alias only through
    // `table[key]`, so a row reached as `table.error` / `table.default` read as
    // nine unread keys — `placeholderColor` among them — while every one was in
    // use below.
    // `filled` (#5747) is the tinted-fill row.
    const row =
      variantRows[
        combo['Variant'] === 'filled' ? 'filled' : isError ? 'error' : 'default'
      ];
    // The helper row's tone: an error replaces the description, so the error
    // variant wears `errorTextColor` and the clean one `helperTextColor`.
    const helperColor = isError
      ? TEXT_AREA.fields.errorTextColor
      : TEXT_AREA.fields.helperTextColor;
    const sz = sizeRowFor(sizeData, combo['Size'], TEXT_AREA.axes.size.members);
    const state = combo['State'] as TextFieldState;
    const disabled = state === 'disabled';
    const focused = state === 'focus';
    const hovered = state === 'hover';
    // The disabled trio, which is what `buildDecoration` /
    // `buildValueTextStyle` / `buildIconTheme` spend when `enabled` is false.
    // The border reads the same ladder TextField's does: disabled outranks
    // everything, then focus turns the border to `focusRingColor`, then hover
    // steps it to the row's `hoverBorderColor`, then rest.
    const boxFill = disabled
      ? row.disabledBackgroundColor
      : hovered
        ? (('hoverBackgroundColor' in row ? row.hoverBackgroundColor : undefined) ?? row.backgroundColor)
        : row.backgroundColor;
    const boxBorder = disabled
      ? row.disabledBorderColor
      : focused
        ? row.focusRingColor
        : hovered
          ? (optField<Color>(row, 'hoverBorderColor') ?? row.borderColor)
          : row.borderColor;
    // The affix glyphs wear one colour in every pose, the error variant and
    // the disabled pose included — `buildIconTheme` reads `affixColor`
    // whatever the state (see the section note).
    const affixColor = colorData(TEXT_AREA.fields.affixColor);
    // The value text and the caret standing in it are built from ONE style
    // object — the caret's height is that style's line box, and two separate
    // reads of the same size row could not be seen to agree.
    const valueStyle = textStyleData(sz.baseTextStyle);
    // The outer Column. It paints nothing — the chrome belongs to the field
    // row below.
    const c = mount.getOrCreate(comboName);
    c.layoutMode = 'VERTICAL';
    c.primaryAxisAlignItems = 'MIN';
    c.counterAxisAlignItems = 'MIN';
    c.primaryAxisSizingMode = 'AUTO';
    c.counterAxisSizingMode = 'AUTO';
    c.fills = [];
    c.setBoundVariable(
      'itemSpacing',
      // The `lg` rung and above state their own gaps (#5747).
      lk.space(
        dimVal(
          (optField<typeof TEXT_AREA.fields.labelGapStyle>(sz, 'labelGapStyle') ??
            TEXT_AREA.fields.labelGapStyle).size,
        ),
      ),
    );

    const formLabel = instanceOf(
      page,
      'FormLabel',
      bestVariantName(page, 'FormLabel', {
        // See the same lookup in `buildTextField`.
        Size: labelCells.cellFor(combo['Size']),
        Enabled: disabled ? 'false' : 'true',
      }),
    );
    formLabel.name = 'label';
    formLabel.visible = false;
    // `Required` is left to FormLabel's own default (off), which is
    // TextArea's: the widget passes `isRequired: widget.required`, and
    // `required` defaults to false.
    // No text style written onto this instance. The role belongs to the
    // child: `FormLabel` states it per size in its own `defaultsBySize`, the
    // variant picked one line up already carries that rung, and both
    // resolvers now forward only what `TextArea` overrides. Writing
    // `TEXT_AREA.fields.labelStyle` here overrode the rung the instance had
    // just been chosen for, so `lg` and up drew the `md` label — the canvas
    // half of a role that Flutter, Web and this builder each answered
    // differently.
    c.appendChild(formLabel);
    // The enabled colour stays the FormLabel cell's own (`onSurfaceVariant`,
    // the same beside a `TextField`). A disabled area states its own tint
    // instead: `!enabled` forwards `labelDisabledColor` as the child's
    // `disabledColor`, so the `Enabled=false` cell's `disabledContent` is
    // repainted on the composed instance, as the TextField builder does.
    if (disabled) {
      for (const node of formLabel.findAll((n) => n.type === 'TEXT')) {
        if (node.type !== 'TEXT') continue;
        fillData(node, lk, colorData(TEXT_AREA.fields.labelDisabledColor));
      }
    }

    // The asterisk's colour is TextArea's OWN field, not the child's default:
    // `text_area.dart` composes `FormLabel(formLabelStyle:
    // CoreFormLabelStyle(requiredColor: resolved.requiredMarkColor))` on every
    // build, so the host states it whether or not the two agree — and today
    // they do, which is exactly why nothing on the canvas showed which one it
    // was reading. Painted through the instance the way `makeIcon` recolours an
    // icon instance's vectors: a sublayer's fill is an instance override, and
    // that mechanism is what every icon in this plugin already rides on.
    //
    // Only while the area is enabled: a disabled `FormLabel` draws its
    // indicator in the same `disabledColor` as the label it marks, and that is
    // the `labelDisabledColor` painted above.
    if (!disabled) {
      for (const holder of formLabel.findAll((n) => n.name === 'requiredIndicator')) {
        if (!('children' in holder)) continue;
        for (const mark of holder.children) {
          if (!('fills' in mark)) continue;
          fillData(mark, lk, colorData(TEXT_AREA.fields.requiredMarkColor));
        }
      }
    }

    // The inner stack — see the section note on why there are two.
    // `Gap(descriptionGapStyle)` sits above the helper row only when the row
    // shows something (`hasHelperText || showCounter`). An auto-layout gap
    // would stay under an empty row, so the step rides as the top padding of
    // each of the row's two parts instead — a hidden part takes no space, and
    // the gap leaves with it (the designer copy draws it the same way).
    const descriptionGap = dimVal(
      (optField<typeof TEXT_AREA.fields.descriptionGapStyle>(sz, 'descriptionGapStyle') ??
        TEXT_AREA.fields.descriptionGapStyle).size,
    );
    const body = autoFrame('body', 'VERTICAL');
    body.primaryAxisAlignItems = 'MIN';
    body.counterAxisAlignItems = 'MIN';
    body.itemSpacing = 0;
    c.appendChild(body);

    // The box — the decoration, the padding, and inside it the text row with
    // the footer under it: the widget's `Padding(Column(Expanded(textRow),
    // Gap(footerGapStyle), footer))`, or the bare text row when there is no
    // footer. One column for both, because a hidden child takes no space and
    // no gap: with the footer off the text row fills the padded box, which is
    // the bare row the widget lays out without one.
    const field = autoFrame('field', 'VERTICAL');
    body.appendChild(field);
    field.primaryAxisAlignItems = 'MIN';
    field.counterAxisAlignItems = 'MIN';
    field.primaryAxisSizingMode = 'FIXED';
    field.counterAxisSizingMode = 'FIXED';
    // The grip overhangs the box by `-dragHandleOffset`, and the widget's
    // `Stacks` says `clipBehavior: .none` — a clipping frame would cut the
    // overhang off, which is the one part of the grip that reads as "grab
    // here".
    field.clipsContent = false;
    bindPad(field, lk, sz.padding);
    field.setBoundVariable(
      'itemSpacing',
      lk.space(dimVal(TEXT_AREA.fields.footerGapStyle.size)),
    );
    // The size step's corner, the same value a TextField of that size takes
    // — the area's height is rows-based, so the step (not the height) keys it.
    bindRadiusN(field, lk, sz.borderRadius.topLeft);
    // Both from the variant row — the fill and the boundary it states, in the
    // pair the `enabled` branch picks. The framed box is a content surface on
    // both platforms (the fill-less variants wear none).
    applySurfaceMaterial(field, lk, colorData(boxFill), 'content', { radius: sz.borderRadius.topLeft });
    // The active boundary, read as TextField reads it: a focused area, or an
    // enabled one in the error variant (`disabled > error`).
    borderData(
      field,
      lk,
      colorData(boxBorder),
      boundaryWidthFor(
        TEXT_AREA.fields.borderWidth,
        TEXT_AREA.fields.activeBorderWidth,
        // Focus alone widens it (#5747).
        !disabled && focused,
      ),
    );

    // The text row — prefix, input, suffix. It takes the height the footer
    // leaves (`Expanded`), and the box's vertical alignment applies inside it,
    // as the widget's `Align` does around the row.
    const textRow = autoFrame('text row', 'HORIZONTAL');
    field.appendChild(textRow);
    textRow.primaryAxisAlignItems = 'MIN';
    textRow.counterAxisAlignItems = verticalAlignItems(
      TEXT_AREA.fields.textAlignVertical.choice,
    );
    textRow.clipsContent = false;
    textRow.setBoundVariable('itemSpacing', lk.space(dimVal(TEXT_AREA.fields.rowSpacing)));
    textRow.layoutSizingHorizontal = 'FILL';
    textRow.layoutSizingVertical = 'FILL';

    const prefix = iconSlot('prefix', 'search', lk, sz.iconStyle.size, affixColor, prefixSwap.variant);
    textRow.appendChild(prefix.holder);

    // `Expanded(child: Stacks(alignment: .topStart, children: [placeholder?,
    // editable]))` — same overlay as TextField, pinned to the top instead of
    // centred, which is already what this row's MIN cross-alignment does.
    // Figma cannot invert Value; expose placeholder visibility for authors.
    const inputStack = autoFrame('input', 'VERTICAL');
    textRow.appendChild(inputStack);
    inputStack.layoutSizingHorizontal = 'FILL';

    // The variant row's `placeholderColor`, not the helper tone — see the
    // section note.
    const ph = makeLabel(
      '내용을 입력해 주세요',
      lk,
      // A disabled placeholder takes the disabled foreground (#5747).
      typographyColorOpts(
        lk,
        valueStyle,
        colorData(disabled ? row.disabledForegroundColor : row.placeholderColor),
      ),
    );
    inputStack.appendChild(ph);
    ph.layoutSizingHorizontal = 'FILL';
    ph.layoutSizingVertical = 'HUG';
    ph.textAlignHorizontal = textAlignHorizontal(TEXT_AREA.fields.textAlign.choice);

    // `buildValueTextStyle` colours the value `foregroundColor` enabled and
    // `disabledForegroundColor` not; the first agrees with the shared
    // on-surface fallback this slot used to lean on, which is why nothing on
    // the canvas showed which of the two it was reading.
    const value = textSlot(
      'value',
      '회의에서 나온 내용을 정리했어요.',
      lk,
      valueStyle,
      colorData(disabled ? row.disabledForegroundColor : row.foregroundColor),
    );
    inputStack.appendChild(value.holder);
    // In FLOW — same reason as `TextField`'s value slot above: pinned at the
    // stack origin it landed in the corner instead of where the placeholder it
    // replaces sits.
    value.holder.layoutSizingHorizontal = 'FILL';
    value.holder.layoutSizingVertical = 'HUG';
    if (value.text) {
      value.text.textAlignHorizontal = textAlignHorizontal(
        TEXT_FIELD.fields.textAlign.choice,
      );
    }

    // The caret — absolute at the stack's origin, which for this widget is
    // `Stacks(alignment: .topStart)`: the row's MIN cross-alignment already
    // puts the stack at the top of a 100px-tall field, so `y = 0` inside it is
    // the first line. Same reasoning as buildTextField for why this is not a
    // row child, and the same two unbindable extents.
    const caretWidth = dimVal(TEXT_AREA.fields.cursorWidth);
    const caret = figma.createRectangle();
    caret.name = 'caret';
    caret.resize(caretWidth, caretLineBox(valueStyle));
    statedRadius(caret, lk, TEXT_AREA.fields.cursorRadius.topLeft);
    fillData(caret, lk, colorData(TEXT_AREA.fields.cursorColor));
    // `readOnly: widget.readOnly || !widget.enabled` and `showCursor` defaults
    // to `!readOnly` — so a disabled area that takes focus by traversal shows
    // the ring and no caret, exactly as TextField does.
    caret.visible = focused && !disabled;
    const caretAt = caretPlacement(
      TEXT_AREA.fields.textAlign.choice,
      kFieldPreviewWidth - dimVal(sz.padding.l) - dimVal(sz.padding.r),
      caretWidth,
    );
    pinAbsolute(inputStack, caret, caretAt.x, 0, {
      horizontal: caretAt.horizontal,
      vertical: 'MIN',
    });

    const suffix = iconSlot('suffix', 'calendar', lk, sz.iconStyle.size, affixColor, suffixSwap.variant);
    textRow.appendChild(suffix.holder);

    // `footer` — a `W?` slot under the text row, inside the box. Holder →
    // BOOLEAN, instance → INSTANCE_SWAP. Its default is what the slot is
    // reached for, a send action — `Button` primary at `sm` — start-aligned
    // across the box's content width, the width both widgets hand the footer
    // before leaving its layout to it.
    const footer = autoFrame('footer', 'HORIZONTAL');
    footer.primaryAxisAlignItems = 'MIN';
    footer.counterAxisAlignItems = 'CENTER';
    const footerContent = instanceOf(page, 'Button', footerVariant);
    footerContent.name = 'footer content';
    footer.appendChild(footerContent);
    field.appendChild(footer);
    footer.layoutSizingHorizontal = 'FILL';
    footer.visible = false;

    // `Text(description | errorText)` — the Column's last child, one node for
    // the two mutually exclusive strings (see the variant table above). No
    // `Padding` wrapper here, unlike TextField: this widget separates it with
    // a `Gap(descriptionGapStyle)`, which is the `body` stack's spacing.
    //
    // Typography is `fields.descriptionStyle` because that is what both
    // resolvers merge the (null by default) caller override onto, for the
    // error text as well — the same size-invariant role on every rung.
    // The `lg` rung and above state their own helper role (#5747).
    const helperRole =
      optField<typeof TEXT_AREA.fields.descriptionStyle>(sz, 'descriptionStyle') ??
      TEXT_AREA.fields.descriptionStyle;
    const helper = textSlot(
      'description',
      '최대 200자까지 쓸 수 있어요.',
      lk,
      textStyleData(helperRole),
      colorData(helperColor),
    );
    // The helper row — the widget's `Row(Expanded(helper),
    // Gap(counterGapStyle), counter)` (#5747). The two parts are siblings so
    // either shows without the other; the row aligns to its end so a counter
    // with no description still sits at the right.
    const supporting = autoFrame('supporting', 'HORIZONTAL');
    supporting.primaryAxisAlignItems = 'MAX';
    supporting.counterAxisAlignItems = 'MIN';
    // With every child hidden, Figma retains the previous HUG height (100px
    // initially). A zero-size flow anchor also collapses the row after a
    // helper has been shown then hidden. The counter owns its own gap so the
    // anchor introduces no extra spacing. Live Figma clamps zero to 0.0001px.
    supporting.itemSpacing = 0;
    const emptyAnchor = figma.createFrame();
    emptyAnchor.name = 'empty supporting anchor';
    emptyAnchor.fills = [];
    emptyAnchor.resize(0, 0);
    supporting.appendChild(emptyAnchor);
    body.appendChild(supporting);
    supporting.layoutSizingHorizontal = 'FILL';
    supporting.appendChild(helper.holder);
    helper.holder.layoutSizingHorizontal = 'FILL';
    helper.holder.setBoundVariable('paddingTop', lk.space(descriptionGap));
    // The character count — the helper role in the counter colour.
    const counter = textSlot(
      'counter',
      '0 / 200',
      lk,
      textStyleData(helperRole),
      colorData(TEXT_AREA.fields.counterStyle.color ?? TEXT_AREA.fields.helperTextColor),
    );
    supporting.appendChild(counter.holder);
    counter.holder.setBoundVariable('paddingTop', lk.space(descriptionGap));
    counter.holder.setBoundVariable('paddingLeft', lk.space(dimVal(TEXT_AREA.fields.counterGapStyle.size)));

    // `initialHeight` is the widget's own starting height (`SizedBox(height:
    // _height ?? resolved.initialHeight)`), so the preview stands at the
    // height a fresh TextArea actually opens at.
    // Four lines plus the row's padding (#5747) — the size row states it.
    const fieldHeight = dimVal(
      optField<typeof TEXT_AREA.fields.initialHeight>(sz, 'initialHeight') ??
        TEXT_AREA.fields.initialHeight,
    );
    const fieldSizing = fieldSizingFor(TEXT_AREA.fields.initialWidth);
    field.resize(kFieldPreviewWidth, fieldHeight);

    // ─── The resize grip ──────────────────────────────────────────────────
    //
    // `dragHandleSize` is the box, `dragHandlePadding` the inset, and the two
    // ticks are the painter's own lines: `(w,0)→(0,h)` and `(w,h/2)→(w/2,h)`
    // over the PADDED content box, 1px, round caps. Coordinates are derived
    // from the two stated values rather than written out, so a change to
    // either moves the ticks with it.
    //
    // The box is `resize`d, not `bindSize`d: `dragHandleSize`'s leaf carries
    // `ref: null`, so there is no Variable to point at, and binding it to the
    // size step that happens to share the number would put a design-system
    // claim on the node that the design system never made.
    const gripSide = dimVal(TEXT_AREA.fields.dragHandleSize);
    const gp = TEXT_AREA.fields.dragHandlePadding;
    const tickSide = gripSide - dimVal(gp.l) - dimVal(gp.r);
    const grip = autoFrame('drag handle', 'HORIZONTAL');
    grip.primaryAxisAlignItems = 'CENTER';
    grip.counterAxisAlignItems = 'CENTER';
    bindPad(grip, lk, gp);
    grip.resize(gripSide, gripSide);
    grip.primaryAxisSizingMode = 'FIXED';
    grip.counterAxisSizingMode = 'FIXED';
    grip.clipsContent = false;
    const ticks = figma.createNodeFromSvg(
      `<svg xmlns="http://www.w3.org/2000/svg" width="${tickSide}" ` +
        `height="${tickSide}" viewBox="0 0 ${tickSide} ${tickSide}" ` +
        'fill="none" stroke="currentColor" stroke-linecap="round">' +
        `<line x1="${tickSide}" y1="0" x2="0" y2="${tickSide}"/>` +
        `<line x1="${tickSide}" y1="${tickSide / kHalf}" ` +
        `x2="${tickSide / kHalf}" y2="${tickSide}"/></svg>`,
    );
    ticks.name = 'ticks';
    ticks.fills = [];
    ticks.resize(tickSide, tickSide);
    // Lucide's own import path recolours the same way (`repaintGlyph`): the SVG
    // arrives stroked in whatever `currentColor` resolved to, so every vector
    // is re-pointed at the stated colour. `borderData` also binds the stroke
    // weight to the 1px token the painter draws with.
    for (const tick of ticks.findAll(() => true)) {
      if (!('strokes' in tick)) continue;
      borderData(tick, lk, colorData(TEXT_AREA.fields.dragHandleColor));
    }
    grip.appendChild(ticks);
    grip.visible = false;
    // `right`/`bottom: dragHandleOffset` — a NEGATIVE inset, so the box hangs
    // one pixel outside the box's corner. Pinned MAX/MAX so it keeps that
    // corner when the instance is resized, which is the whole point of a
    // resize grip sitting on it.
    //
    // Pinned to the TEXT ROW, reaching out across the box's end and bottom
    // padding to the box's corner. With the footer off the row fills the
    // padded box, so the grip lands on the box's corner — where the widget
    // puts it without a footer. With the footer on, the row gives up the
    // footer's height and the grip rides up with it, off the footer's
    // trailing action and onto the end of the text row, which is the corner
    // both widgets move it to (the web's native grip on the `<textarea>`). A
    // BOOLEAN can move a node only by resizing what it is pinned to, not by
    // repinning it, so it keeps the padding's reach there: it sits that far
    // past the text row's corner, in the box's padding beside it.
    const gripOffset = dimVal(TEXT_AREA.fields.dragHandleOffset);
    const textRowWidth = kFieldPreviewWidth - dimVal(sz.padding.l) - dimVal(sz.padding.r);
    const textRowHeight = fieldHeight - dimVal(sz.padding.t) - dimVal(sz.padding.b);
    const pinnedGrip = pinAbsolute(
      textRow,
      grip,
      textRowWidth + dimVal(sz.padding.r) - gripSide - gripOffset,
      textRowHeight + dimVal(sz.padding.b) - gripSide - gripOffset,
      { horizontal: 'MAX', vertical: 'MAX' },
    );

    // The ring last, after the grip: the widget's ring layer is the top of its
    // stack while the grip is inside the box the ring surrounds. Around the
    // whole box, footer included — the widget's `FocusOutline` wraps the box
    // the footer sits in — and only the box: the label above it and the helper
    // row below are the Column's other children, outside the `FocusOutline`.
    const ring = focusRing(field, lk, {
      outline: TEXT_AREA.fields.focusOutlineStyle,
      color: colorData(row.focusRingColor),
      corner: sz.borderRadius.topLeft,
      width: kFieldPreviewWidth,
      height: fieldHeight,
      // A keyboard signal (#5747) — `Show focus ring` on every member.
      visible: false,
    });

    // The width is the other half of that same `SizedBox`, and here the data
    // says outright what it is: `initialWidth` is `{unbounded: true}` — the
    // widget hands `SizedBox(width: double.infinity)`, i.e. "fill the
    // parent". So the row fills, exactly as in buildTextField above, and the
    // Column carries the preview number.
    //
    // `minWidth` (100) IS a resize floor and is now stated as one: it is the
    // value the widget clamps a drag of its resize grip to
    // (`.clamp(resolved.minWidth, maxWidth)`), and Figma's own `minWidth` is
    // the same constraint, so dragging an instance narrower than the widget
    // allows is no longer possible. Unbound — the leaf carries `ref: null`,
    // so there is no Variable to point at.
    lockWidth(c, kFieldPreviewWidth);
    c.minWidth = dimVal(TEXT_AREA.fields.minWidth);
    // The other three of the same clamp. `.clamp(minHeight, maxHeight)` on the
    // vertical drag and `.clamp(minWidth, maxWidth)` on the horizontal one — the
    // comment above quotes the second and only its floor was stated.
    //
    // `minHeight` is 100 (the same `_kResizeBaseline` the initial height names),
    // so it matches the frame's current height rather than changing it: this
    // constrains resizing without moving a pixel. The two ceilings are
    // `{unbounded: true}` — `double.infinity`, which Web emits as no `max-*` at
    // all — so they resolve to `null`, and writing that is what keeps the
    // constraint from being true by coincidence.
    c.minHeight = dimVal(TEXT_AREA.fields.minHeight);
    c.maxWidth = resizeCeiling(TEXT_AREA.fields.maxWidth);
    c.maxHeight = resizeCeiling(TEXT_AREA.fields.maxHeight);
    // Both stacks fill outward from the component's stated width, so the
    // helper row and the field share the box the Column carries. The ring is
    // stretched to the box's four edges, so it follows whichever sizing the
    // box takes.
    body.layoutSizingHorizontal = 'FILL';
    field.layoutSizingHorizontal = fieldSizing;
    slots.push({
      placeholder: ph,
      value,
      prefix,
      suffix,
      footer: { holder: footer, content: footerContent },
      label: formLabel,
      helper,
      counter,
      grip: pinnedGrip,
      ring,
    });
  }
  const set = mount.finish();
  const placeholderId = defineProp(set, 'Placeholder', 'TEXT', '내용을 입력해 주세요');
  const showPlaceholderId = defineProp(set, 'Show placeholder', 'BOOLEAN', true);
  const valueId = defineProp(set, 'Value', 'BOOLEAN', false);
  const valueTextId = defineProp(set, 'Value text', 'TEXT', '회의에서 나온 내용을 정리했어요.');
  const showPrefixId = defineProp(set, 'Show prefix', 'BOOLEAN', false);
  const prefixId = defineProp(set, 'Prefix', 'INSTANCE_SWAP', prefixSwap.id);
  const showSuffixId = defineProp(set, 'Show suffix', 'BOOLEAN', false);
  const suffixId = defineProp(set, 'Suffix', 'INSTANCE_SWAP', suffixSwap.id);
  // `footer` is a `W?` slot and `null` by default — an area with no actions.
  const showFooterId = defineProp(set, 'Show footer', 'BOOLEAN', false);
  const footerId = defineProp(
    set,
    'Footer',
    'INSTANCE_SWAP',
    mainComponentIdOf(page, 'Button', footerVariant),
  );
  // As in TextField: `label` is a `String?`, so the boolean is
  // `widget.label != null` and the words live on the FormLabel instance.
  const showLabelId = defineProp(set, 'Show label', 'BOOLEAN', false);
  const showHelperId = defineProp(set, 'Show description', 'BOOLEAN', false);
  const helperTextId = defineProp(set, 'Description', 'TEXT', '최대 200자까지 쓸 수 있어요.');
  // `showCounter` (#5747) — the count at the helper line's end; `Counter` is
  // the words a preview shows there.
  const showCounterId = defineProp(set, 'Show counter', 'BOOLEAN', false);
  const counterTextId = defineProp(set, 'Counter', 'TEXT', '0 / 200');
  // `expandableHeight || expandableWidth` — the widget's own condition for
  // rendering the grip at all, and both are `false` by default. One boolean
  // rather than two, because the grip is the same node either way: which axes it
  // resizes is a gesture, and a gesture has no rendering to vary.
  const showGripId = defineProp(set, 'Show drag handle', 'BOOLEAN', false);
  // Same drawing switch as TextField's — see the note there.
  const showFocusId = defineShowFocusRing(set);
  for (const s of slots) {
    bindTextProp(s.placeholder, placeholderId);
    bindVisibleProp(s.placeholder, showPlaceholderId);
    bindTextProp(s.value.text!, valueTextId);
    bindVisibleProp(s.value.holder, valueId);
    bindVisibleProp(s.prefix.holder, showPrefixId);
    bindSwapProp(s.prefix.icon!, prefixId);
    bindVisibleProp(s.suffix.holder, showSuffixId);
    bindSwapProp(s.suffix.icon!, suffixId);
    bindVisibleProp(s.footer.holder, showFooterId);
    bindSwapProp(s.footer.content, footerId);
    bindVisibleProp(s.label, showLabelId);
    bindVisibleProp(s.helper.holder, showHelperId);
    bindTextProp(s.helper.text!, helperTextId);
    bindVisibleProp(s.counter.holder, showCounterId);
    bindTextProp(s.counter.text!, counterTextId);
    bindVisibleProp(s.grip, showGripId);
    bindShowFocusRing(s.ring, showFocusId);
  }
  // No `rowSet` override any more: a single row of 24 members is 24 × 240px of
  // horizontal scrolling, and comparing poses is the whole reason the axes
  // exist. `finish()` has already applied `defaultSetLayout`, whose
  // ceil(sqrt(n)) grid stays roughly square as `n` grows — the same reading
  // `buildButton` and `buildTextField` record.
  return set;
}

// ═══════════════════════════════════════════════════════════════════════════
// EXTENDED BUILDERS — additional Form components are appended below.
// ═══════════════════════════════════════════════════════════════════════════

export const FORM_BUILDERS: RegistryEntry[] = [
  { section: 'Form', name: 'Button', build: buildButton, needs: ['Icon'] },
  // `Button` and `FormLabel` as well as `Icon`: the clear / reveal affordance
  // is a real `Button(variant: .plain)` instance and the label row is a real
  // `FormLabel` instance (see buildTextField), so both children must be on the
  // page before this entry runs.
  {
    section: 'Form',
    name: 'TextField',
    build: buildTextField,
    needs: ['Icon', 'Button', 'FormLabel'],
  },
  { section: 'Form', name: 'Checkbox', build: buildCheckbox, needs: ['Icon'] },
  { section: 'Form', name: 'Toggle', build: buildToggle },
  { section: 'Form', name: 'RadioGroup', build: buildRadioGroup },
  { section: 'Form', name: 'Slider', build: buildSlider },
  // `Button` as well: the footer slot defaults to a real `Button` instance.
  {
    section: 'Form',
    name: 'TextArea',
    build: buildTextArea,
    needs: ['Icon', 'Button', 'FormLabel'],
  },
  // EXTENDED ENTRIES — append new Form registry entries above this line.
];
