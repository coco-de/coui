/// <reference types="@figma/plugin-typings" />

import { bindRoundBoxRadius, shrunkSquareGeometry } from '../shape-geometry';
import {
  RegistryEntry,
  VarLookup,
  autoFrame,
  bestVariantName,
  bindPad,
  bindRadiusN,
  bindSize,
  bindSpaceField,
  bindSwapProp,
  bindTextProp,
  bindVisibleProp,
  borderData,
  defineProp,
  exposeAll,
  fillData,
  glyphOpts,
  instanceOf,
  makeIcon,
  makeLabel,
  mint,
  mountSet,
  pinInFlow,
  propertyOwner,
  setInstanceTextNamed,
  solid,
  textLabelOpts,
  typographyColorOpts,
  setShadow,
  addFocusRing,
  kSlotStandInComponent,
  slotStandIn,
  slotStandInDefault,
  SlotStandInShape,
} from '../helpers';
import { stateAxis } from '../state-axis';
import type { SwapDefault } from '../component-props';
import { exampleInstance, exampleSwapDefault, kRefreshTriggerExample } from '../default-examples';
import { axisSpecsOf, enumerateAxisAssignments } from '../axis-combos';
import { Color, Dim, colorData, dimVal, optField, textStyleData } from '../compat/v1';
import { COMPONENTS } from '../data';

// ═══════════════════════════════════════════════════════════════════════════
// Behaviour wrappers — the components a designer never *places* but that the
// widget tree is made of.
//
// Clickable / Hover / Subfocus / RefreshTrigger wrap a child and add an
// affordance: a press-and-focus target, a pointer-hover effect, a focus ring,
// a pull-to-refresh indicator. `ThemeController` — and `ThemeSwatch`, the
// button it lays out — is the one visible control in this file. None of the
// four wrappers paints a background, so the honest
// drawing for each is *the affordance it adds*, wrapped around a stand-in for
// the `child` slot — never a decorative picture that would imply chrome the
// component does not own.
//
// That slot is the whole composition surface of all four, and it takes any
// widget, so it is a real Figma slot rather than a picture of one: a swappable
// placeholder instance plus (where the contract allows a null child) a toggle
// to empty it. See `## The child slot` below for the two-node shape that takes.
//
// Why build them at all: the Figma tree is meant to correspond to the widget
// tree node-for-node, and a wrapper that exists in code but not in the library
// is a hole in that correspondence — the direction a future Figma→code reader
// would walk. "디자인적으로는 쓰지 않더라도 만들어 놓아야지 coui 와 잘 연동이
// 되지."
//
// Every value below comes from these components' own `fields` / `variants`
// entries in components.json, with two deliberate exceptions, each marked at
// its use site: `COMPONENTS.focus_outline` (the style Subfocus's contract
// explicitly routes its ring colour *to*, rather than duplicating) and
// `COMPONENTS.icon.constants.ambientSize` (the size an icon takes when the
// parent's resolver passes none and nothing between it and the app root
// mounts an `IconTheme` — which is exactly what RefreshTrigger's resolver
// does: `CoreIconStyle(color: …)`, no size).
// ═══════════════════════════════════════════════════════════════════════════

const CLICKABLE = COMPONENTS.clickable;
const HOVER = COMPONENTS.hover;
const SUBFOCUS = COMPONENTS.subfocus;
const LOADING = COMPONENTS.loading;
const REFRESH_TRIGGER = COMPONENTS.refresh_trigger;
const THEME_CONTROLLER = COMPONENTS.theme_controller;
const FOCUS_OUTLINE = COMPONENTS.focus_outline;
const ICON = COMPONENTS.icon;

// The only Semantic colour literals in this file, and they paint exactly one
// thing: the two halves of the palette circle inside `ThemeSwatch`. The four
// wrappers' child stand-in is an instance of the shared slot stand-in, whose
// fill is already data-driven (see `## The child slot`), so these are the only
// paints left here that no component states a colour for.
//
// They belong to the *placeholder*, not to any component here: a swatch's
// palette takes its colours from the app's `CoreThemeOption` (`primaryColor`
// required, `secondaryColor` optional), never from `CoreThemeControllerStyle`.
// Painting the stand-in is the same convention as display.ts drawing literal
// '프로젝트 요약' copy into a slot whose text it does not own. Two tokens rather
// than one tint because the widget divides the circle evenly among the colours
// the option carries — two colours are two halves, which is the picture the
// canvas draws — and one tint would make the split invisible.
function paletteSegmentFills(lk: VarLookup): SolidPaint[][] {
  // g7-preview-only: the halves' ink is the caller's `CoreThemeOption.primaryColor` / `secondaryColor` (`theme_controller.dart` `_ThemeSwatch._palette`, Web `theme_controller.dart` preview segments) — `CoreThemeControllerStyle` states this circle's `previewSize` and `previewBorderRadius` but no fill, so there is no field to read and an unpainted rectangle would be invisible. `primary` / `secondary` because a theme swatch previews a brand pair, and tokens keep the stand-in following the theme.
  return [[solid(lk.sem('primary'))], [solid(lk.sem('secondary'))]];
}

// ─── The `child` slot ────────────────────────────────────────────────────────
//
// Every component in this file except `ThemeController` / `ThemeSwatch` has
// exactly one composition slot, `child`, and it accepts ANY widget. Three of the contracts
// declare it `W?` and `RefreshTrigger`'s declares it `W`. Two things have to be
// true on canvas for that to be the component a designer actually gets:
//
//   1. Something arbitrary can go in it. Figma's equivalent of "any widget" is
//      an INSTANCE_SWAP property: the designer picks a component in the panel
//      and it takes the slot. Without one, whatever this file happened to draw
//      IS the component — the wrapper would wrap that one box forever, which is
//      a stronger claim than the contract makes and an invisible one to be
//      wrong about, because the canvas looks finished either way.
//   2. It can be empty, where the contract says it can. `child: null` is a real
//      state for the three `W?` wrappers, and only a BOOLEAN makes a region
//      hide-able from an instance. The contract is what decides that, not the
//      Flutter widget: `CoreClickableContract.child` is `W?` even though
//      `clickable.dart` narrows its own constructor to a required `Widget`, and
//      the contract is the cross-platform surface this library generates.
//
// So the slot is two nodes, not one: an unpainted wrapper that hugs (what the
// BOOLEAN hides) holding a placeholder instance (what the swap replaces). Two,
// because a node carries exactly ONE `componentPropertyReferences` map and
// `bindVisibleProp` / `bindSwapProp` each assign that map wholesale — binding
// both to the instance would silently drop whichever ran first. The wrapper
// paints nothing, has no padding and no gap, so it costs nothing on the canvas.
// Same shape as display.ts's `badgeIconSlot`.
//
// The placeholder is the shared slot stand-in (`slotStandIn`, slot-stand-in.ts)
// rather than a tinted box this file paints — why: docs/contributing/figma.md,
// "빈 슬롯의 대역". Its extent comes from the stand-in component, so this file
// picks no size and no colour for a box that is not its own.
const kSlotShape: SlotStandInShape = 'rectangular';

// The two nodes one `child` slot is made of.
interface SlotNodes {
  /// The slot itself — named `child`, paints nothing, hides as a whole.
  box: FrameNode;
  /// What sits in it until a designer swaps it for their own component.
  content: InstanceNode;
}

// One `child` slot. `scale` applies the wrapper's own press/hover factor to the
// child the way the widget does (`AnimatedScale(child:)` / `Transform.scale`) —
// on the child, not on the affordance around it. Rescaling an instance is the
// same operation `makeIcon` performs on every icon; the factor is read from the
// component's Style, so nothing about the resulting size is chosen here.
function slotBox(page: PageNode, scale?: number): SlotNodes {
  const box = autoFrame('child', 'HORIZONTAL');
  box.primaryAxisAlignItems = 'CENTER';
  box.counterAxisAlignItems = 'CENTER';
  const content = slotStandIn(page, 'child content', kSlotShape);
  if (scale != null) content.rescale(scale);
  box.appendChild(content);
  return { box, content };
}

// A `child` slot that shows an example (`default-examples.ts`) instead of the
// stand-in — the same two nodes, the example instance where the stand-in was.
function exampleSlotBox(page: PageNode, example: string): SlotNodes {
  const box = autoFrame('child', 'HORIZONTAL');
  box.primaryAxisAlignItems = 'CENTER';
  box.counterAxisAlignItems = 'CENTER';
  const content = exampleInstance(page, example, 'child content');
  box.appendChild(content);
  return { box, content };
}

// Declares the slot's two properties on `owner` and points them at the nodes
// that render it.
//
// Called AFTER the nodes are inside their component — Figma rejects
// `componentPropertyReferences` on a detached node ("Can only set component
// property references on symbol sublayer"), the throw aborts the entry, and
// the half-built component is left on the canvas looking finished until the
// next run that mints its name blanks it. For a variant set that
// also means after `mount.finish()`: until `combineAsVariants` runs, a freshly
// minted variant's parent is still the page, so `propertyOwner` would answer
// with the variant itself and every variant would grow its own copy
// (`addComponentProperty` on a set member throws).
//
// `optional` mirrors the contract, not a preference: `RefreshTrigger`'s child is
// `required` (`"type": "W"`), so it gets no BOOLEAN — a property offering to
// remove something the widget cannot be built without would be a state the code
// does not have.
function bindSlotProps(
  page: PageNode,
  owner: ComponentNode | ComponentSetNode,
  slots: readonly SlotNodes[],
  optional: boolean,
  swapDefault: SwapDefault = slotStandInDefault(page, kSlotShape),
): void {
  if (optional) {
    // Distinct names from the swap below — Figma keys a property by name, so
    // two of them called `Child` on one owner is a duplicate, not an overload.
    const showProp = defineProp(owner, 'Show child', 'BOOLEAN', true);
    for (const s of slots) bindVisibleProp(s.box, showProp);
  }
  const swapProp = defineProp(owner, 'Child', 'INSTANCE_SWAP', swapDefault);
  for (const s of slots) bindSwapProp(s.content, swapProp);
}

// Wrapper chrome shared by Clickable / Hover / Subfocus: hug the child on both
// axes, paint nothing. The affordance each one adds is applied on top.
function applyWrapperChrome(c: ComponentNode): void {
  c.layoutMode = 'HORIZONTAL';
  c.primaryAxisSizingMode = 'AUTO';
  c.counterAxisSizingMode = 'AUTO';
  c.primaryAxisAlignItems = 'CENTER';
  c.counterAxisAlignItems = 'CENTER';
  c.fills = [];
}

// ─── Clickable ───────────────────────────────────────────────────────────────

// The interaction wrapper: cursor, focus ring, press feedback, disabled dim.
// It owns no fill and no border of its own, so what is drawn is exactly the
// four things `CoreClickableStyle` decides, across two axes.
//
// `State` — the four chrome states the style names, one field each:
//   default   nothing applied
//   focused   `focusOutlineStyle.borderColor` ring on the wrapper's bounds
//   pressed   the child at `pressedScale`
//   disabled  the whole wrapper at `disabledOpacity`
//
// `Shape` — which radius the ring (and the clip it rounds to) uses. Both
// values are radii of the same ring: `borderRadius` for a rectangular target,
// `focusOutlineStyle.circleBorderRadius` for a round one. Making it an axis is
// what puts the choice in Figma's dropdown; folding it away would leave
// `circleBorderRadius` unreachable on canvas.
//
// Not drawn: `duration` / `pressDuration` / `focusOutlineStyle.duration` are
// transition timings with no static representation, the same reason display.ts
// leaves Progress's `duration` out. The ring's stroke alignment is left at
// Figma's default because `CoreFocusOutlineStyle.align` did not reach the
// export — deciding it here would be inventing chrome.
// `disabled` is NOT one of these. It is not a fourth peer of default / focused /
// pressed — it is the `Enabled` axis the v3 `axes` block promotes (the contract's
// `bool enabled`), and spelling it as a `State` value put the same fact on two
// axes while leaving the promoted one absent, which is why eight members scored
// 0/2 on axis coverage. So the member list carries `Enabled` and the disabled
// pose is `State=default, Enabled=false`.
//
// Sparse on purpose: `Enabled=false` pairs with `default` only. `clickable.dart`
// returns early out of the focus handler when disabled and never scales an
// unpressable child, so `State=focused, Enabled=false` is not a state the app can
// be in — a member for it would be a pose invented on the canvas, and three
// identically-dimmed members read as a bug rather than as three states. Figma
// flags the absent combinations; that notice is the accurate one.
const kClickableStates = ['default', 'focused', 'pressed'] as const;

function buildClickable(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = CLICKABLE.fields;
  const ringColor = colorData(f.focusOutlineStyle.borderColor);
  const pressedScale = dimVal(f.pressedScale);
  const disabledOpacity = dimVal(f.disabledOpacity);
  const shapes = [
    { name: 'rect', radius: f.borderRadius.topLeft },
    { name: 'circle', radius: f.focusOutlineStyle.circleBorderRadius.topLeft },
  ];
  // `{state, enabled}` flattened, so the loop below stays one level deep and the
  // name is composed in exactly one place.
  const poses: { state: string; enabled: boolean }[] = [];
  for (const state of kClickableStates) poses.push({ state: state, enabled: true });
  poses.push({ state: 'default', enabled: false });
  const nameOf = (p: { state: string; enabled: boolean }, shape: string): string =>
    `State=${p.state}, Shape=${shape}, Enabled=${p.enabled}`;
  const names: string[] = [];
  for (const pose of poses) {
    for (const shape of shapes) names.push(nameOf(pose, shape.name));
  }
  const mount = mountSet(page, 'Clickable', names);
  const slots: SlotNodes[] = [];
  for (const pose of poses) {
    const state = pose.state;
    for (const shape of shapes) {
      const c = mount.getOrCreate(nameOf(pose, shape.name));
      applyWrapperChrome(c);
      bindRadiusN(c, lk, shape.radius);
      // The whole ring recipe, not just its colour. `focusOutlineStyle` states the
      // width (2), the offset band (`align` 4) and `ringOpacity` as well, and a
      // stroke painted from the colour alone dropped all three — the ring sat ON
      // the wrapper's edge at 1px instead of outside it at 2.
      if (state === 'focused') {
        addFocusRing(c, lk, CLICKABLE.fields.focusOutlineStyle, shape.radius);
      }
      if (!pose.enabled) c.opacity = disabledOpacity;
      // The radius is the ring's and the pressed shadow's, both of which are
      // drawn on `c` above. It is not the child's: `clickable.dart` wraps the
      // child in `AnimatedScale` and never rounds or clips it, so rounding the
      // slot here would assert a corner the widget does not give it.
      const slot = slotBox(page, state === 'pressed' ? pressedScale : undefined);
      c.appendChild(slot.box);
      slots.push(slot);
    }
  }
  const set = mount.finish();
  bindSlotProps(page, set, slots, true);
  return set;
}

// ─── Composed `Stacks` ───────────────────────────────────────────────────────

// A `Stacks`: children share one origin and later children paint over earlier
// ones. `clip` is its `clipBehavior` — hardEdge (the contract default) → true,
// `.none` → false. A parameter rather than a constant because the two call
// sites in this file differ, and that difference is the widgets' own.
function applyStackChrome(node: FrameNode | ComponentNode, clip: boolean): void {
  node.layoutMode = 'NONE';
  node.clipsContent = clip;
  node.fills = [];
}

// Two components here compose a `Stacks` — the `shadow` hover effect
// (silhouettes behind the child) and `RefreshTrigger` (its indicator over the
// content it wraps) — and both draw the stack rather than instantiating one.
//
// Why drawn: a Figma instance takes no arbitrary children, so an instance of
// the `Stacks` component placed here would render that component's own preview
// (a rectangle and a circle) *beside* this component's content instead of
// stacking it. The frame is not an approximation of a z-stack either — it *is*
// one: Figma expresses stacking as a frame with no auto-layout whose children
// carry explicit `x`/`y`, which is exactly what the `Stacks` builder itself
// puts on the canvas. Same reason the focus ring is drawn on the focusable node
// rather than instantiated around it, and the same reason the theme swatch
// below cannot hold the interaction wrapper whose style it forwards.
function stackFrame(name: string, clip: boolean): FrameNode {
  const f = figma.createFrame();
  f.name = name;
  applyStackChrome(f, clip);
  return f;
}

// Appends then positions — `x`/`y` are parent-relative, so they only mean
// anything once the node is in the parent.
function placeAt(
  parent: FrameNode | ComponentNode,
  child: FrameNode,
  x: number,
  y: number,
): void {
  parent.appendChild(child);
  child.x = x;
  child.y = y;
}

// ─── Hover ───────────────────────────────────────────────────────────────────

// The pointer-hover wrapper. `CoreHoverEffect` is the axis — the enum the
// widget takes — and each position reads the one field that names it, so the
// factor a designer sees on canvas is the factor the code applies.
//
// One position carries no static representation, and is drawn as the
// unaffected box rather than as an invented one:
//   brighten  `brightenFactor` is a colour multiplier; Figma has no brightness
//             effect to bind it to. Faking it (a white overlay at 0.1) would
//             put a colour in this file that coui_core never chose.
// It stays in the axis because the enum position is real — a designer
// selecting `Effect=brighten` is naming `CoreHoverEffect.brighten`, and
// dropping it would say the effect does not exist.
//
// `shadow` is the one effect whose widget is not a single wrapped box: it
// composes a `Stacks` (see `drawHoverShadowStack`).
//
// Not drawn: `effectDuration` / `waitDuration` / `showDuration` are timings.
interface HoverEffectSpec {
  name: string;
  scale?: number;
  opacity?: number;
  /// This effect's widget is a `Stacks`, not a single wrapped box.
  stacked?: boolean;
}

// `CoreHoverEffect.shadow` — the only arm of `_applyEffect` that is not one
// widget around the child. Flutter has no single-element drop shadow, so the
// widget composes `_DropShadow`:
//
//   Stacks(fit: passthrough, clipBehavior: none, children: [
//     for (final shadow in shadows) Position.fill(<child, tinted + blurred>),
//     child,
//   ])
//
// — one silhouette of the child per shadow layer, painted behind it.
//
// Figma expresses the same thing as a stack of DROP_SHADOW effects on the
// child, which is what is drawn here: `shadowBoxShadow` (`CoreShadow.lg`)
// gives the offsets, blurs and layer count, and the child carries them.
//
// This used to be a flat `shadowBaseColor` copy of the child's bounds sitting
// underneath it, with a comment explaining that the geometry "did not reach
// the export" — true when it was written, and the record outlived the reason:
// `List<CoreShadowLayer>` reads now. A silhouette with no offset and no blur
// is fully covered by the child, so the effect was invisible while looking
// implemented.
//
// `shadowBaseColor` stays out of it. `CoreShadowLayer` carries its own
// per-layer opacity and no colour, and the widget's tint is a separate
// concern from the layer geometry — feeding it in here would give one visual
// two sources that can disagree.
function drawHoverShadowStack(page: PageNode, c: ComponentNode, lk: VarLookup): SlotNodes {
  applyStackChrome(c, false);
  const slot = slotBox(page);
  setShadow(slot.box, HOVER.fields.shadowBoxShadow, lk, colorData(HOVER.fields.shadowBaseColor));
  // Measured off the instance, whose extent is its main component's, not off
  // the hug wrapper, whose auto-layout width Figma has not computed yet here.
  placeAt(c, slot.box, 0, 0);
  c.resize(slot.content.width, slot.content.height);
  // The shadowed child IS the member's content — it spans the box the way the
  // other effects' hugging wrapper does by construction (#4805).
  slot.box.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };
  return slot;
}

function buildHover(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = HOVER.fields;
  const effects: HoverEffectSpec[] = [
    { name: 'none' },
    { name: 'scaleUp', scale: dimVal(f.scaleUpFactor) },
    { name: 'scaleDown', scale: dimVal(f.scaleDownFactor) },
    { name: 'fade', opacity: dimVal(f.fadeOpacity) },
    { name: 'brighten' },
    { name: 'shadow', stacked: true },
  ];
  const mount = mountSet(page, 'Hover', effects.map((e) => `Effect=${e.name}`));
  const slots: SlotNodes[] = [];
  for (const effect of effects) {
    const c = mount.getOrCreate(`Effect=${effect.name}`);
    if (effect.stacked) {
      slots.push(drawHoverShadowStack(page, c, lk));
      continue;
    }
    applyWrapperChrome(c);
    if (effect.opacity != null) c.opacity = effect.opacity;
    const slot = slotBox(page, effect.scale);
    c.appendChild(slot.box);
    slots.push(slot);
  }
  const set = mount.finish();
  bindSlotProps(page, set, slots, true);
  return set;
}

// ─── Subfocus ────────────────────────────────────────────────────────────────

// A focusable item inside a subfocus scope. The only chrome it owns is the
// ring's corner radius — `CoreSubfocusStyle` has exactly one field — so the
// ring is the whole drawing: a stroke on the wrapper's bounds at
// `focusRingRadius`, around the child it wraps.
//
// The ring's colour comes from `COMPONENTS.focus_outline`, not from a literal:
// the contract's own words are "the ring colour / width flow through the
// already-unified CoreFocusOutlineStyle", so that component's `borderColor`
// *is* this value's source of truth. Its width did not reach the export
// (`CoreFocusOutlineStyle.defaultBorderWidth` is a `static const double` the
// reader could not route), so the stroke weight falls back to helpers.ts's
// `borderData` default rather than to a number chosen here.
//
// Two members, on the `Enabled` axis the v3 `axes` block promotes — because the
// ring is not unconditional. `subfocus.dart` computes `_isFocused => _focused &&
// widget.enabled`, so a disabled item inside a focused scope draws NO ring: the
// wrapper and its child, nothing on the bounds.
//
// This was one component with a comment saying Subfocus "is focused or it is not
// present", which read the widget's own `enabled` as absence. It is not absence —
// it is a member, and the difference between the two is the entire drawing this
// component owns.
// KNOWN GAP: the ring is drawn here as a stroke, and `subfocus.dart` wraps its
// child in a real `FocusOutline(...)`. So this is a lookalike of a component that
// already exists — the shape the composition gate is for. Left as-is because
// composing it is not a one-line change: a Figma instance's subtree cannot take
// appended children, so the ring cannot become this slot's parent the way the
// widget's does; it has to be an overlaid sibling with its own absolute placement
// (`Range`'s thumbs are the worked example). That is fidelity work with a layout
// question in it, not merge cleanup.
function buildSubfocus(page: PageNode, lk: VarLookup): ComponentSetNode {
  const radius = SUBFOCUS.fields.focusRingRadius.topLeft;
  const ringColor = colorData(FOCUS_OUTLINE.fields.borderColor);
  const mount = mountSet(page, 'Subfocus', ['Enabled=true', 'Enabled=false'], {
    adoptLooseAs: 'Enabled=true',
  });
  const slots: SlotNodes[] = [];
  for (const enabled of [true, false]) {
    const c = mount.getOrCreate(`Enabled=${enabled}`);
    applyWrapperChrome(c);
    bindRadiusN(c, lk, radius);
    // The ring on the enabled member only — that is the whole difference between
    // the two, and `_isFocused => _focused && widget.enabled` is why. Its colour
    // comes from `COMPONENTS.focus_outline`, not from a literal: the contract's own
    // words are "the ring colour / width flow through the already-unified
    // CoreFocusOutlineStyle", so that component's `borderColor` IS this value's
    // source of truth. Its width did not reach the export
    // (`CoreFocusOutlineStyle.defaultBorderWidth` is a `static const double` the
    // reader could not route), so the stroke weight falls back to helpers.ts's
    // `borderData` default rather than to a number chosen here.
    if (enabled) borderData(c, lk, ringColor);
    // `focusRingRadius` is the ring's corner, drawn on `c` above — the one field
    // `CoreSubfocusStyle` has. It is not a corner Subfocus gives its child, so it
    // stops at the ring.
    const slot = slotBox(page);
    c.appendChild(slot.box);
    slots.push(slot);
  }
  const set = mount.finish();
  bindSlotProps(page, set, slots, true);
  return set;
}

// ─── RefreshTrigger ──────────────────────────────────────────────────────────

// The pull-to-refresh wrapper. Unlike the three wrappers above, this one draws
// something of its own — the indicator pill — but the component is *not* the
// pill: `RefreshTrigger`'s `child` slot is required (`"type": "W"`,
// `"required": true`), and what the widget builds around it is a stack.
//
// `_buildPullFrame`:
//
//   Stacks(fit: passthrough, [                       ← clips (hardEdge default)
//     Transform.translate(contentOffset, child),     ← the wrapped scrollable
//     Position.fill(ClipRect(Stacks([                ← the indicator overlay
//       Position(top: 0, left: 0, right: 0, <indicator>),
//     ]))),
//   ])
//
// so that is the shape here: the `child` stand-in filling the frame, and an
// overlay above it holding the pill pinned to the leading edge. The overlay is
// one node for `Position.fill` + `ClipRect` + the inner `Stacks` because Figma
// states all three on one node — an explicitly placed, clipping frame with no
// auto-layout.
//
// Two placements are the widget's and one is this file's:
//   · The pill sits at the top edge, horizontally centred — `_wrapPositioned`'s
//     `Position(top: 0, left: 0, right: 0)` for the default vertical direction,
//     and `_RefreshIndicator`'s own `Center`.
//   · Its distance *into* the frame is a live gesture value
//     (`FractionalTranslation(0, -1)` parked above the clip, then translated
//     down by the pull extent), so it has no static position; it is drawn at
//     the edge that translation interpolates across. Same call as the arrow's
//     unrotated angle below.
//   · The frame's own extent is neither's — `minExtent` / `maxExtent` are
//     widget parameters, not Style fields, and are not in the export. It is
//     read off the `child` placeholder and widened to whichever of that and the
//     pill is wider, so the clip cuts neither.
//
// Only the vertical, non-reversed direction is drawn. `direction` / `reverse`
// are widget parameters with no Style default (nothing in `fields` names them),
// so there is no second value in the data to build an axis from.
//
// The four stages mirror `CoreRefreshStage` and the widget's own per-stage
// rows, child order included:
//   idle        [ label(idleTextStyle) ]
//   pulling     [ arrow, label(idleTextStyle), arrow ]   — padding switches to
//               `pullingPadding`, the one field that only this stage reads
//   refreshing  [ label(refreshingTextStyle), Loading ]
//   completed   [ label(completedTextStyle), check ]
//
// `refreshing` instantiates the real `Loading` component (`needs: ['Loading']`)
// because that is literally what the widget composes — `const Loading()` — and
// an instance keeps the Figma tree corresponding to the widget tree. It takes
// Loading's first variant: RefreshTrigger's contract does not name one, and
// the Figma set carries no "default variant" marker to read.
//
// `completed` draws `check`, the same lucide glyph the widget names. `pulling`
// draws `chevron-down` as a stand-in for `LucideIcons.arrowDown`, which is not
// in the generated icons.json — a down-pointing mark of the right meaning
// rather than an invented one, and the widget's 0→180° arrow rotation has no
// static position so the mark is left unrotated. Icon colours are the stage's
// own text colour, exactly as the resolver builds them
// (`CoreIconStyle(color: idleColorCore)`). Their size is the app root's
// ambient icon size, `CoreIconStyle.defaultAmbientSize`: the resolver reads
// `merged.size ?? ambient ?? CoreIconStyle.defaultSize`, RefreshTrigger
// passes no size and mounts no `IconTheme` on either platform, and both app
// roots (Flutter `CoUIApp`, Web `CoUIWeb`) fill the ambient step from that
// const. `CoreIconStyle.defaultSize` is never reached here.
//
// Not drawn: `animationDuration` (the stage cross-fade). The labels' size and
// weight fall back to helpers.ts's defaults — the export carries these styles'
// `labelLarge` role as a name only, with no resolved font size behind it.
type RefreshStage = 'idle' | 'pulling' | 'refreshing' | 'completed';

const kRefreshStages: readonly RefreshStage[] = ['idle', 'pulling', 'refreshing', 'completed'];

// `_RefreshIndicator` — the pill itself: a `DecoratedBox` in
// `indicatorBackgroundColor` at `indicatorBorderRadius`, padded, holding the
// stage's own row.
function refreshIndicator(page: PageNode, lk: VarLookup, stage: RefreshStage): FrameNode {
  const f = REFRESH_TRIGGER.fields;
  const idleStyle = textStyleData(f.idleTextStyle);
  const arrowColor = colorData(f.idleTextStyle.color);
  const pill = autoFrame('indicator', 'HORIZONTAL');
  pill.primaryAxisAlignItems = 'CENTER';
  pill.counterAxisAlignItems = 'CENTER';
  fillData(pill, lk, colorData(f.indicatorBackgroundColor));
  bindRadiusN(pill, lk, f.indicatorBorderRadius.topLeft);
  bindPad(pill, lk, stage === 'pulling' ? f.pullingPadding : f.indicatorPadding);
  pill.setBoundVariable('itemSpacing', lk.space(dimVal(f.indicatorGapStyle.size)));
  switch (stage) {
    case 'idle':
      pill.appendChild(makeLabel('당겨서 새로고침', lk, textLabelOpts(lk, idleStyle)));
      break;
    case 'pulling':
      pill.appendChild(makeIcon('arrow-down', lk, glyphOpts(lk, arrowColor, ICON.constants.ambientSize, 'size')));
      pill.appendChild(makeLabel('놓으면 새로고침', lk, textLabelOpts(lk, idleStyle)));
      pill.appendChild(makeIcon('chevron-down', lk, glyphOpts(lk, arrowColor, ICON.constants.ambientSize, 'size')));
      break;
    case 'refreshing':
      pill.appendChild(
        makeLabel('새로고침 중', lk, textLabelOpts(lk, textStyleData(f.refreshingTextStyle))),
      );
      // `const Loading()` — the widget states no variant and no size, so the
      // instance takes `Loading`'s OWN defaults: `spinner`, and the size row whose
      // pixel size equals `CoreLoadingStyle.defaultSize`.
      //
      // Named rather than left off. An unnamed `instanceOf` returns whichever
      // variant sorts first, which is a coin flip across a set with four variants
      // and five sizes — `bar` at `lg` is as likely as the spinner the widget
      // draws. The row is looked up rather than written as `'sm'` because the
      // default is 16 and `md` is 24: the obvious guess is the wrong one, and a
      // lookup follows the data if either moves.
      pill.appendChild(
        instanceOf(
          page,
          'Loading',
          bestVariantName(page, 'Loading', {
            Variant: kRefreshSpinnerVariant,
            Size: defaultLoadingSizeRow(),
          }),
        ),
      );
      break;
    case 'completed':
      pill.appendChild(
        makeLabel('새로고침 완료', lk, textLabelOpts(lk, textStyleData(f.completedTextStyle))),
      );
      pill.appendChild(
        makeIcon('check', lk, glyphOpts(lk, colorData(f.completedTextStyle.color), ICON.constants.ambientSize, 'size')),
      );
      break;
  }
  return pill;
}


// `Loading`'s own default variant — `loading.dart`'s
// `this.variant = CoreLoadingVariant.spinner`.
const kRefreshSpinnerVariant = 'spinner';

// The `Size` row whose pixel size equals `CoreLoadingStyle.defaultSize`, which is
// the size `const Loading()` renders at (`componentSize` is null, so the resolver
// falls through to `defaultSize`).
//
// Looked up instead of named: the default is 16 and the row carrying 16 is `sm`,
// not the `md` a reader would assume. Throws rather than guessing — a set with no
// row at the default size is a data change this builder must not paper over.
function defaultLoadingSizeRow(): string {
  const want = dimVal(LOADING.fields.size);
  for (const [row, leaf] of Object.entries(LOADING.sizes.defaultsBySize)) {
    if (dimVal(optField<Dim>(leaf, 'size')!) === want) return row;
  }
  throw new Error(
    `Loading: no Size row has the default size ${want} — ` +
      'CoreLoadingStyle.defaultSize and defaultsBySize disagree, and picking a ' +
      'row here would put that disagreement on the canvas.',
  );
}
// The band the indicator is drawn in, above the content (#6473). In the
// widget the pill and the content are translated down by the same pull
// extent — the pill parked one pill-height above the clip, the content at
// `contentOffset` — so the pill always sits in the gap the content leaves
// above itself and never over it. The canvas draws that pulled pose: the
// content starts below a band and the pill is centred in the band. The
// band's height is the preview's (the live gap is the pull extent, a gesture
// value with no static position — the pill's own height plus a margin, as the
// designer's copy draws it).
const kRefreshIndicatorBand = 40;

function buildRefreshTrigger(page: PageNode, lk: VarLookup): ComponentSetNode {
  const mount = mountSet(page, 'RefreshTrigger', kRefreshStages.map((s) => `Stage=${s}`));
  const slots: SlotNodes[] = [];
  for (const stage of kRefreshStages) {
    const c = mount.getOrCreate(`Stage=${stage}`);
    applyStackChrome(c, true);
    // The child shows the example feed rather than the stand-in (#6473) — a
    // refresh indicator over a dashed box says nothing about what refreshes.
    const slot = exampleSlotBox(page, kRefreshTriggerExample);
    const overlay = stackFrame('overlay', true);
    const pill = refreshIndicator(page, lk, stage);
    // Widened only if the pill needs it — the frame clips, and a pill cut off
    // at both ends would read as the component's shape rather than as the
    // preview's. The pill hugs its own row, so its width is read, not chosen;
    // the content extent is read off the example instance for the same
    // reason (a hug wrapper has no computed width yet at this point).
    const width = Math.max(slot.content.width, pill.width);
    const band = Math.max(kRefreshIndicatorBand, pill.height);
    const height = band + slot.content.height;
    c.resize(width, height);
    // The wrapped scrollable takes the width and the height below the band
    // (`Transform.translate(contentOffset, child)`).
    slot.box.primaryAxisSizingMode = 'FIXED';
    slot.box.counterAxisSizingMode = 'FIXED';
    slot.box.resize(width, slot.content.height);
    // g7-preview-only: the indicator band's height — see `kRefreshIndicatorBand`.
    overlay.resize(width, band);
    placeAt(c, slot.box, 0, band);
    placeAt(c, overlay, 0, 0);
    placeAt(overlay, pill, (width - pill.width) / 2, (band - pill.height) / 2);
    // The content spans the box under the band; the band runs across the top
    // and the pill keeps its centre (`Stacks[child, indicator]`, #4805).
    slot.box.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };
    overlay.constraints = { horizontal: 'STRETCH', vertical: 'MIN' };
    pill.constraints = { horizontal: 'CENTER', vertical: 'CENTER' };
    slots.push(slot);
  }
  const set = mount.finish();
  // No BOOLEAN: this `child` is `required` in the contract (`"type": "W"`),
  // unlike the three wrappers above. The swap defaults to the example, taking
  // over from the stand-in once; a designer's own pick stays.
  bindSlotProps(
    page,
    set,
    slots,
    false,
    exampleSwapDefault(page, kRefreshTriggerExample, slotStandInDefault(page, kSlotShape)),
  );
  return set;
}

// ─── ThemeSwatch ─────────────────────────────────────────────────────────────

// One selectable theme button — `_ThemeSwatch`, which `ThemeController` lays
// out four of. Its own set rather than four frames drawn inside the container,
// for the reason `NavigationBarItem` is a set beside `NavigationBar`: the
// container is a `Wrap` of these, every one of them has the same anatomy, and
// a designer who swaps a theme name or drops a fifth swatch into the row is
// editing an INSTANCE, not redrawing a picture. `dataSlug: 'theme_controller'`
// because the swatch has no contract of its own — every value it draws is a
// `CoreThemeControllerStyle` field, and `_ThemeSwatch` reads the same
// `resolved` bundle the container does.
//
// Three axes, every one an input `_ThemeSwatch.build` branches on:
//   Size      `CoreThemeControllerSize` — the `defaultsBySize` row, iterated so
//             a fourth row lands on the canvas without touching this file.
//             Every dimension below is the row's: `buttonSize` / `buttonRadius`
//             / `previewSize` / `labelGapStyle` / `labelStyle` (the role moves
//             with the rung).
//   State     the composed `Clickable`'s ladder — `enabled` at rest, `hover`,
//             `pressed`, and `disabled`, which is `enabled && option.enabled`
//             false. `disabled` is a rung here and not an `Enabled` axis for
//             the reason `Button` / `Chip` fold it: a disabled swatch is one
//             pose of the same ladder, and `axisValueOf` reads it as
//             `Enabled=false`.
//   Selected  `option.name == selectedTheme` — the strong ring
//             (`selectedBorderColor` · `selectedBorderWidth`) and the label in
//             the strong ink (`selectedLabelColor`). The ring is the whole mark:
//             there is no badge, and a ring is a border, so it is still drawn
//             when a forced-colours mode folds every colour into one.
//
// Anatomy, `_ThemeSwatch.build` top-down (`Column(mainAxisSize: .min)`):
//
//   swatch                       VERTICAL hug, gap = labelGapStyle.size
//     ├─ button                  buttonSize², buttonRadius (a circle). NO fill
//     │    │                     (`buttonBackgroundColor` is transparent) and no
//     │    │                     border at rest. The ring: `hoverBorderColor` ·
//     │    │                     `hoverBorderWidth` on `State=hover` / `pressed`
//     │    │                     of an UNSELECTED swatch; the selected ring on
//     │    │                     `Selected=true`; `disabledBorderColor` at the
//     │    │                     SELECTION's width when disabled — a locked
//     │    │                     selection is still legible as the selection.
//     │    ├─ state layer        the wash, `State=hover` / `pressed` only — see
//     │    │                     `themeSwatchStateLayer`
//     │    └─ palette            previewSize² (less `pressedPreviewShrink` on
//     │         │                `State=pressed`), a circle. Two half-circle
//     │         ├─ segment       ELLIPSE arcs: the left half is the first colour
//     │         └─ segment       the option carries, the right half the second.
//     │                          Disabled paints both `disabledPreviewColor`: a
//     │                          locked theme must not say "you can pick this".
//     └─ label                   Text(option.name) at labelStyle — the row's
//                                role. The colour is a separate field
//                                (`labelColor` / `selectedLabelColor` /
//                                `disabledLabelColor` by state): the role
//                                carries none, so exactly one colour lands on
//                                the text.
//
// Two properties, both on the label: `Name` (TEXT) is `option.name`, the one
// string a swatch shows; `Show label` (BOOLEAN) hides it. Both bind the same
// node — `addPropRef` merges fields, so a TEXT and a BOOLEAN can drive one
// text node — and hiding an auto-layout child collapses its gap with it.
//
// Not drawn: `clickableStyle`. Its `pressedScale` / `focusOutlineStyle` are
// the `Clickable` set's own chrome (see that builder), and its
// `disabledOpacity` is `opacity100` — this component paints dedicated
// disabled tokens (border / preview / label) INSTEAD of a fade, the
// way `Checkbox` and `Chip` do, so the honest disabled pose is those tokens
// at full strength and no `opacity` write anywhere.
const kThemeSwatchStates = stateAxis(['enabled', 'hover', 'pressed', 'disabled']);

type ThemeSwatchState = (typeof kThemeSwatchStates)[number];

// The `option.name` a lone swatch shows — the first of the docs' own
// `ThemeController` example options, so the default reads as a theme and not
// as placeholder copy.
const kThemeSwatchDefaultName = '오션';

// The two halves of the palette circle, as the arcs of one ellipse each. Figma
// measures an arc clockwise from three o'clock: π/2 → 3π/2 is the LEFT half
// (six o'clock round through nine to twelve) and −π/2 → π/2 the RIGHT half.
// The first colour the option carries is the left half, the second the right —
// the order the widget's `Row` of `Expanded` segments lays them in.
const kPaletteHalfArcs = [
  { startingAngle: Math.PI / 2, endingAngle: (3 * Math.PI) / 2, innerRadius: 0 },
  { startingAngle: -Math.PI / 2, endingAngle: Math.PI / 2, innerRadius: 0 },
] as const;

// The ramp a hover / pressed wash is painted at, when the data states one.
interface StateLayerRamp {
  hover: number;
  focus: number;
  pressed: number;
}

// The wash over the button on `State=hover` / `State=pressed` — the
// foreground-over-fill layer `Chip` and `TextField` draw from their own
// `stateLayer` field.
//
// Read off THIS component's data and drawn only when it is there. Neither
// `theme_controller.dart` nor its Web twin paints a wash today — the composed
// `Clickable` carries `pressedScale` / focus ring and nothing over the fill —
// and `CoreThemeControllerStyle` states no `stateLayer`, so there is no ramp to
// read. `optField` rather than a field access so the moment Core adds
// `stateLayer` + `stateLayerColor` (the `NavigationBar` shape) the export
// carries them and these two rungs get their wash without another edit here.
// Painting a ramp borrowed from another component's field would put a value on
// the canvas that this component's code never renders — the second source
// this file exists to avoid.
//
// Null when there is nothing to paint, and the rung then draws exactly the
// enabled pose: a hovered swatch that changes nothing IS what both apps show.
function themeSwatchStateLayer(
  lk: VarLookup,
  button: FrameNode,
  side: number,
  radius: number,
  state: ThemeSwatchState,
): void {
  const ramp = optField<StateLayerRamp>(THEME_CONTROLLER.fields, 'stateLayer');
  const ink = optField<Color>(THEME_CONTROLLER.fields, 'stateLayerColor');
  if (ramp == null || ink == null) return;
  const layerAlpha =
    state === 'pressed' ? ramp.pressed : state === 'hover' ? ramp.hover : null;
  if (layerAlpha == null) return;
  const layer = figma.createRectangle();
  layer.name = 'state layer';
  layer.resize(side, side);
  layer.cornerRadius = radius;
  fillData(layer, lk, colorData(ink));
  layer.opacity = layerAlpha;
  // Child 0 — over the fill, under the palette — then pinned so it stretches
  // with the box rather than taking a slot in the row.
  button.insertChild(0, layer);
  pinInFlow(button, layer);
  layer.x = 0;
  layer.y = 0;
  layer.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };
}

function buildThemeSwatch(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = THEME_CONTROLLER.fields;
  const sizeData = new Map(Object.entries(THEME_CONTROLLER.sizes.defaultsBySize));
  // Enumerated once, `.name` for `mountSet` and `.values` for the loop — the
  // shape `Chip` uses, so the member list and the draw loop cannot diverge.
  const members = enumerateAxisAssignments([
    { axis: 'Size', values: [...sizeData.keys()] },
    { axis: 'State', values: [...kThemeSwatchStates] },
    { axis: 'Selected', values: ['false', 'true'] },
  ]);
  const mount = mountSet(page, 'ThemeSwatch', members.map((m) => m.name));
  const labels: TextNode[] = [];
  for (const { name, values } of members) {
    const sz = sizeData.get(values.Size);
    if (!sz) throw new Error(`ThemeSwatch: no size row for member "${name}"`);
    const state = values.State as ThemeSwatchState;
    const enabled = state !== 'disabled';
    const pressed = state === 'pressed';
    const lit = state === 'hover' || pressed;
    const selected = values.Selected === 'true';
    const c = mount.getOrCreate(name);
    // `Column(mainAxisSize: .min, [button, Gap(labelGapStyle), Text])`.
    c.layoutMode = 'VERTICAL';
    c.primaryAxisSizingMode = 'AUTO';
    c.counterAxisSizingMode = 'AUTO';
    c.primaryAxisAlignItems = 'CENTER';
    c.counterAxisAlignItems = 'CENTER';
    c.fills = [];
    bindSpaceField(c, 'itemSpacing', lk, dimVal(sz.labelGapStyle.size));

    // The button box — the composed `OutlinedContainer`'s fill / radius / border
    // (`selectedContainerStyle` and its siblings in the resolver), drawn here
    // because a Figma instance takes no children and the palette has to sit
    // inside it. No fill (transparent clears it), and a ring only where a state
    // asks for one: hover / pressed on an unselected swatch, the selection, or
    // the locked selection. Disabled keeps the SELECTION's border width and only
    // swaps the colour, which is what `disabledSelectedContainerStyle` states.
    const button = autoFrame('button', 'HORIZONTAL');
    button.primaryAxisAlignItems = 'CENTER';
    button.counterAxisAlignItems = 'CENTER';
    button.primaryAxisSizingMode = 'FIXED';
    button.counterAxisSizingMode = 'FIXED';
    bindSize(button, lk, sz.buttonSize, sz.buttonSize);
    bindRadiusN(button, lk, sz.buttonRadius.topLeft);
    fillData(button, lk, colorData(f.buttonBackgroundColor));
    const ring = !enabled
      ? {
          color: f.disabledBorderColor,
          width: selected ? f.selectedBorderWidth : f.unselectedBorderWidth,
        }
      : selected
        ? { color: f.selectedBorderColor, width: f.selectedBorderWidth }
        : lit
          ? { color: f.hoverBorderColor, width: f.hoverBorderWidth }
          : { color: f.unselectedBorderColor, width: f.unselectedBorderWidth };
    // A ring of width 0 is no border: the stroke is not drawn at all rather
    // than drawn hairline-thin.
    if (dimVal(ring.width) > 0) borderData(button, lk, colorData(ring.color), ring.width);
    c.appendChild(button);

    // The palette — `ClipRRect(previewBorderRadius, SizedBox(previewSize²,
    // Row([Expanded(ColoredBox) …])))`: a circle split down the middle. Drawn as
    // two half-circle arcs (an ellipse each) over one another rather than as
    // rectangles clipped by a round frame, so the circle is exact and the frame
    // needs no clip. The frame is the circle's box (no auto-layout: the arcs
    // sit on the same origin). Pressed draws it `pressedPreviewShrink` smaller;
    // its corner is half its side, which is the fully round corner
    // `previewBorderRadius` states, clamped to what a box that size can show.
    const geometry = shrunkSquareGeometry(
      lk, sz.previewSize, pressed ? f.pressedPreviewShrink : 0,
    );
    const side = geometry.width;
    const palette = figma.createFrame();
    palette.name = 'palette';
    palette.fills = [];
    palette.clipsContent = false;
    palette.resize(side, side);
    bindRoundBoxRadius(palette, lk, geometry, f.previewBorderRadius.topLeft);
    button.appendChild(palette);
    const fills = paletteSegmentFills(lk);
    for (let i = 0; i < kPaletteHalfArcs.length; i++) {
      const segment = figma.createEllipse();
      segment.name = 'segment';
      palette.appendChild(segment);
      bindSize(segment, lk, side, side);
      segment.x = 0;
      segment.y = 0;
      segment.arcData = { ...kPaletteHalfArcs[i] };
      // `enabled ? scheme.resolve(color) : resolved.disabledPreviewColor` —
      // disabled discards the option's colours entirely.
      if (enabled) segment.fills = fills[i];
      else fillData(segment, lk, colorData(f.disabledPreviewColor));
    }

    themeSwatchStateLayer(
      lk,
      button,
      dimVal(sz.buttonSize),
      dimVal(sz.buttonRadius.topLeft),
      state,
    );

    // `Text(option.name, style: …)` — the row's role (`labelSmall` ·
    // `labelMedium` · `labelLarge`) with the colour the STATE picks, which is
    // what `typographyColorOpts` is for.
    const label = makeLabel(
      kThemeSwatchDefaultName,
      lk,
      typographyColorOpts(
        lk,
        textStyleData(sz.labelStyle),
        colorData(!enabled ? f.disabledLabelColor : selected ? f.selectedLabelColor : f.labelColor),
      ),
    );
    label.name = 'label';
    c.appendChild(label);
    labels.push(label);
  }
  const set = mount.finish();
  // Declared on the SET after `finish()` — see `bindSlotProps` for why a
  // property cannot land on a detached member.
  const nameProp = defineProp(set, 'Name', 'TEXT', kThemeSwatchDefaultName);
  const showLabelProp = defineProp(set, 'Show label', 'BOOLEAN', true);
  for (const label of labels) {
    bindTextProp(label, nameProp);
    bindVisibleProp(label, showLabelProp);
  }
  return set;
}

// ─── ThemeController ─────────────────────────────────────────────────────────

// The wrapping row of theme swatches — `Wrap(spacing: buttonSpacing,
// runSpacing: buttonSpacing, [for (option in themes) _ThemeSwatch(…)])`.
//
// Two axes, both the contract's own:
//   Size     `CoreThemeControllerSize`, the `defaultsBySize` row every swatch
//            takes and the row `buttonSpacing` comes from.
//   Enabled  the contract's `bool enabled` — the group lock, which composes
//            with each option's own `enabled` (`enabled && option.enabled`) so
//            a disabled controller shows every swatch in its disabled pose.
//            Spelled `Enabled=` because that is the axis schema v3 promotes
//            (`axes.enabled`) and the spelling every builder with a promoted
//            `enabled` uses; the canvas's `Disabled=` members are carried
//            across by `VARIANT_RENAMES`, keys intact.
//
// The four swatches are INSTANCES of the `ThemeSwatch` set — the first
// selected, the other three at rest — each with its `Name` set to one of the
// docs example's options (plus `Mono`, the one the canvas shows selected).
// Instances rather than four drawings, for the reason `NavigationBar` composes
// `NavigationBarItem`: the widget IS a row of that child, and a designer who
// swaps a theme edits the child one level in. The instances are exposed so
// the swatch's own `Name` / `Show label` reach the controller's panel — the
// same answer `Fab`'s Extended pill gives for a label that lives inside a
// composed instance.
//
// What the container itself states is the row's `buttonSpacing` — twelve between
// the cells on every rung, along the row and between rows — and each cell's floor,
// `swatchMinWidth` (48): the instance HUGs and is floored, so a longer theme name
// widens its own cell and is never cut. (A FIXED 48 would clip it; a FILL cell in
// a hugging row would size the row to one cell.) The enabled controller paints each
// example theme in its own two colours — the caller's data, see
// `kThemeControllerPreviewPalettes`.
//
// Nothing else is drawn here: every colour, radius and inset is the swatch's,
// and drawing any of it on the container would be the second source this file
// exists to avoid. The controller's own opacity is left alone — its
// `clickableStyle.disabledOpacity` is `opacity100`, and disabled is the
// swatches' dedicated tokens, not a fade.
const kThemeControllerPreviewNames = ['Mono', 'Ocean', 'Forest', 'Sunset'] as const;
// The copy each swatch's `Name` reads, held apart from the option name the
// instance is named with so translating the copy does not rename the layer a
// designer's override is keyed on.
const kThemeControllerPreviewLabels: Record<(typeof kThemeControllerPreviewNames)[number], string> = {
  Mono: '모노',
  Ocean: '오션',
  Forest: '포레스트',
  Sunset: '선셋',
};

// The two palette colours each example theme previews — `CoreThemeOption.primaryColor`
// then `secondaryColor`, the left and the right half of the circle. They are the
// CALLER'S DATA (the code takes them from the options it is handed, never from
// `CoreThemeControllerStyle`), so there is no field to read them from: a swatch
// that painted `color/primary` · `color/secondary` for all four would show four
// copies of one theme. Painted only on `Enabled=true` — a locked swatch discards
// its colours (`disabledPreviewColor`), which is the swatch set's own fill.
//
// Keyed by the option name the instance is named with.
const kThemeControllerPreviewPalettes: Record<
  (typeof kThemeControllerPreviewNames)[number],
  readonly [string, string]
> = {
  // g7-preview-only: the example options' palette — the caller's data, not a Style field (see above). Mono is zinc 800 · 400, Ocean sky 600 · blue 900, Forest green 600 · 900, Sunset orange 500 · pink 700.
  Mono: ['#27272a', '#a1a1aa'],
  Ocean: ['#0284c7', '#1e3a8a'],
  Forest: ['#16a34a', '#14532d'],
  Sunset: ['#f97316', '#be185d'],
};

// A `#rrggbb` literal as a Figma paint (channels 0–1).
function hexPaint(hex: string): SolidPaint {
  const channel = (at: number): number => parseInt(hex.slice(at, at + 2), 16) / 255;
  return { type: 'SOLID', color: { r: channel(1), g: channel(3), b: channel(5) } };
}

// Overrides the two palette halves INSIDE a swatch instance: the first
// `segment` is the left half (the option's `primaryColor`), the second the right
// (`secondaryColor`). A fill written on a node inside an instance is that
// instance's own override — the swatch set keeps its token-bound stand-ins.
function paintSwatchPalette(swatch: InstanceNode, colors: readonly [string, string]): void {
  const segments = swatch.findAll((n) => n.name === 'segment');
  if (segments.length !== colors.length) {
    throw new Error(
      `ThemeController: "${swatch.name}" has ${segments.length} palette segment(s), expected ${colors.length}`,
    );
  }
  for (let i = 0; i < segments.length; i++) {
    (segments[i] as GeometryMixin).fills = [hexPaint(colors[i])];
  }
}

function buildThemeController(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = THEME_CONTROLLER.fields;
  const sizeData = new Map(Object.entries(THEME_CONTROLLER.sizes.defaultsBySize));
  // `Enabled`, from the schema — not the canvas's `Disabled`. The
  // contract states `bool get enabled` and G10 reads coverage by that
  // name, the way it does for the other thirty-odd components whose
  // contracts declare it; a hand-declared `Disabled` axis here reads as
  // "the enabled axis never reached the canvas". The six members the
  // designer spelled `Disabled=…` migrate through `VARIANT_RENAMES`,
  // which is what keeps their keys (and so any instance of them)
  // attached across the rename.
  const members = enumerateAxisAssignments([
    { axis: 'Size', values: [...sizeData.keys()] },
    ...axisSpecsOf(THEME_CONTROLLER.axes),
  ]);
  const mount = mountSet(page, 'ThemeController', members.map((m) => m.name));
  const swatches: InstanceNode[] = [];
  for (const { name, values } of members) {
    const sz = sizeData.get(values.Size);
    if (!sz) throw new Error(`ThemeController: no size row for member "${name}"`);
    const enabled = values.Enabled === 'true';
    const c = mount.getOrCreate(name);
    // `Wrap` — a wrapping horizontal row; `spacing` is the gap along the row and
    // `runSpacing` the gap between rows, both `buttonSpacing`. Hugging on both
    // axes, so the four swatches sit on one line until a designer fixes the
    // width — which is exactly when `Wrap` starts breaking lines too.
    c.layoutMode = 'HORIZONTAL';
    c.layoutWrap = 'WRAP';
    c.primaryAxisSizingMode = 'AUTO';
    c.counterAxisSizingMode = 'AUTO';
    c.primaryAxisAlignItems = 'MIN';
    c.counterAxisAlignItems = 'MIN';
    c.fills = [];
    bindSpaceField(c, 'itemSpacing', lk, dimVal(sz.buttonSpacing));
    c.setBoundVariable('counterAxisSpacing', lk.space(dimVal(sz.buttonSpacing)));
    for (let i = 0; i < kThemeControllerPreviewNames.length; i++) {
      const optionName = kThemeControllerPreviewNames[i];
      const selected = i === 0;
      // Picked by name, the axes this container decides: the row, the rest /
      // disabled rung of the ladder (`enabled && option.enabled`), and which
      // one is current. `bestVariantName` so a pose added to the swatch's
      // ladder later degrades to "closest" rather than failing this entry.
      const swatch = instanceOf(
        page,
        'ThemeSwatch',
        bestVariantName(page, 'ThemeSwatch', {
          Size: values.Size,
          State: enabled ? 'enabled' : 'disabled',
          Selected: selected ? 'true' : 'false',
        }),
      );
      swatch.name = optionName;
      setInstanceTextNamed(swatch, 'Name', kThemeControllerPreviewLabels[optionName]);
      c.appendChild(swatch);
      // A cell is at least `swatchMinWidth` wide and hugs past it — a longer
      // name widens its own cell and is never cut. A floor over a hug, not a
      // fixed width (`Wrap` gives the cell `minWidth` and no `maxWidth`).
      swatch.layoutSizingHorizontal = 'HUG';
      swatch.minWidth = dimVal(f.swatchMinWidth);
      swatch.setBoundVariable('minWidth', lk.size(dimVal(f.swatchMinWidth)));
      // The example themes' own colours, on the enabled controller only.
      if (enabled) paintSwatchPalette(swatch, kThemeControllerPreviewPalettes[optionName]);
      swatches.push(swatch);
    }
  }
  const set = mount.finish();
  // Deferred to after assembly: Figma rejects the flag on an instance with no
  // COMPONENT ancestor.
  exposeAll(swatches);
  return set;
}

// `needs: [kSlotStandInComponent]` on the four wrappers: each draws the slot
// stand-in as its `child` placeholder, and drawing it throws if the stand-in is
// not on the page when the parent runs. `ThemeController` instantiates
// `ThemeSwatch` four times, so the swatch builds before the controller.
export const PRIMITIVES_BEHAVIOUR: RegistryEntry[] = [
  { section: 'Layout', name: 'Clickable', build: buildClickable, needs: [kSlotStandInComponent] },
  { section: 'Layout', name: 'Hover', build: buildHover, needs: [kSlotStandInComponent] },
  {
    section: 'Layout',
    name: 'Subfocus',
    build: buildSubfocus,
    needs: [kSlotStandInComponent],
  },
  {
    section: 'Layout',
    name: 'RefreshTrigger',
    build: buildRefreshTrigger,
    needs: ['Icon', 'Loading', kSlotStandInComponent, kRefreshTriggerExample],
  },
  {
    section: 'Layout',
    name: 'ThemeSwatch',
    build: buildThemeSwatch,
    // Its chrome is `CoreThemeControllerStyle` — `_ThemeSwatch` has no Style of
    // its own and reads the controller's resolved bundle, so its stated values
    // live under the parent's slug (the `NavigationBarItem` shape).
    dataSlug: 'theme_controller',
  },
  {
    section: 'Layout',
    name: 'ThemeController',
    build: buildThemeController,
    needs: ['ThemeSwatch'],
  },
];
