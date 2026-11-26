/// <reference types="@figma/plugin-typings" />

import {
  mainComponentIdOf as mainComponentId,
  findComponentByName,
  iconMainId,
  iconSwapDefault,
  pinInFlow,
  pinAbsolute,
  sizePin,
  ColorData,
  RegistryEntry,
  VarLookup,
  addControlBorder,
  addControlShadow,
  applySurfaceMaterial,
  autoFrame,
  bestVariantName,
  bindAxisSize,
  bindPad,
  bindRadiusN,
  bindSize,
  bindSurfaceShare,
  bindSwapProp,
  bindTextProp,
  bindVisibleProp,
  borderData,
  corners,
  defaultSetLayout,
  defineProp,
  fillData,
  glyphOpts,
  instanceOf,
  makeIcon,
  makeLabel,
  mountSet,
  textLabelOpts,
  typographyColorOpts,
  wrapSet,
  setShadow,
  setSurfaceRim,
  applyForwardedButtonStyle,
  addFocusRing,
  scaleAlpha,
  applyBorderStyle,
  focusOutlineRingColor,
  kAvatarDefaultShape,
  kAvatarDefaultSize,
  kBadgeDefaultSize,
  kBadgeDefaultTone,
  kCountBadgeDefault,
  kProgressDefaultSize,
  kProgressDefaultTone,
  bindSpaceField,
  lockWidth,
  setInstanceTextNamed,
  focusRing,
  timedGeom,
  FocusRingNodes,
  vStackSet,
  kSlotStandInComponent,
  slotStandIn,
  slotStandInDefault,
  SlotStandInShape,
} from '../helpers';
import { clipsFor, elevationLayers } from '../container-chrome';
import {
  colorData,
  dimVal,
  mergeTextStyleData,
  optField,
  textStyleData,
  Color,
  Dim,
  TextLeaf,
} from '../compat/v1';
import { COMPONENTS, CARD, BADGE, ALERT } from '../data';
import {
  axisSpecsOf,
  composeVariantName,
  enumerateAxisAssignments,
  enumerateAxisCombos,
  sizeRowFor,
} from '../axis-combos';
import { parseVariantKey } from '../variant-safety';
import { bindShowFocusRing, defineShowFocusRing } from '../state-axis';
import { derivedCorner } from '../instance-reach';

// Local accessors for the builders converted below (#3754) — not promoted to
// data.ts's named-export sugar since other worktrees are converting other
// files against that same shared file in parallel; `COMPONENTS` is already
// exported and fully typed, so a file-local const is all this needs.
const AVATAR = COMPONENTS.avatar;
const PROGRESS = COMPONENTS.progress;
const TOOLTIP = COMPONENTS.tooltip;
const SKELETON = COMPONENTS.skeleton;
const TAG = COMPONENTS.tag;
// `icon.constants.ambientSize` — the app root's ambient icon size, which an
// `Icon` handed to a caller slot draws at when the widget renders it as handed.
// Tooltip's trigger and Avatar's `child` say why they qualify.
const ICON = COMPONENTS.icon;

// ─── State axes ──────────────────────────────────────────────────────────────
//
// A state that changes chrome becomes its own INDEPENDENT boolean axis in the
// variant name (`Variant=outlined, Disabled=true, Focused=false`), never a
// single `State=` enum: the code's states COMBINE — a card can be focused and
// disabled at once, and `Clickable` resolves both — and one enum axis cannot
// express a combination. Two axes can.
//
// An axis is only added where the two sides actually render differently. Two
// states in this file are deliberately absent for that reason:
//
//   · Card `pressedScale` is `1.0` (`clickableStyle.pressedScale` — the large
//     card surface opts out of press-shrink on purpose; the press feedback is
//     the hover shadow). A `Pressed` axis would be two identical pictures a
//     designer has to click through to discover that.
//   · Card hover — and this one is BLOCKED UPSTREAM rather than declined.
//     `CoreCardStyle` states it (`hoverElevation`), `card.dart` paints it
//     (`boxShadow: _hovered ? resolved.hoverShadows : null`), and hover is a
//     state the card lingers in, so it earns a pose on every count except the
//     one that matters: the geometry is not in the export. `hoverElevation`
//     arrives as a bare `{"choice":"medium"}`, and the stack that choice names
//     — `CoreCardElevation.medium.toOutlinedContainerElevation()` →
//     `CoreOutlinedContainerStyle.defaultMediumShadow`, an alias of
//     `CoreShadow.md` — is exported nowhere. `card.fields.boxShadow` is
//     `{"layers":[]}`, which is the card's IDLE stack (`CoreShadow.none`), not
//     this one.
//
//     The three ways to draw it anyway are each worse than not drawing it, and
//     naming them is the point of this paragraph:
//
//       — `primitives-chrome.ts#elevationLayers` is the shared helper for
//         exactly this shape, and it THROWS on any non-`none` choice on
//         purpose. It is also file-private there, so reaching it would mean
//         editing that file. Either way `medium` + an empty explicit stack is
//         its throwing branch, and a throw inside a builder is not rolled
//         back — the entry is reported as failed and half a Card is left on
//         the canvas until the next run blanks it.
//       — Writing `CoreShadow.md`'s offsets here puts a design decision in the
//         plugin, which is what `elevationLayers` already refuses.
//       — Borrowing another component's stack is worse than either, because it
//         works. `CorePopupStyle.defaultBoxShadow` is `CoreShadow.md` too, so
//         `popup.fields.boxShadow` carries the right numbers today — by its own
//         independent decision. Reading them here would tie Card's hover
//         shadow to Popup's panel, and the day Popup moves to `lg` the canvas
//         follows it with nothing red anywhere.
//
//     So no axis: hover's only visible effect on a Card is that shadow (nothing
//     else in `_CardInteractiveWrapper` branches on `_hovered`), and a Hover
//     axis with no shadow to draw is eight duplicate members plus a rename of
//     all eight existing ones, for no picture. What unblocks it is one export —
//     the `default*Shadow` stacks reaching `components.json` the way
//     `boxShadow` already does — after which this becomes an axis that draws
//     `elevationLayers(f.hoverElevation, f.boxShadow, …)` and nothing here has
//     to decide a value. See the closing note.
const kBoolAxis = ['false', 'true'] as const;

// The `focusOutlineStyle` nested slot, as the four leaves the ring is drawn
// from. Every one of them is in `components.json` — `badge.fields
// .focusOutlineStyle` and `card.fields.clickableStyle.focusOutlineStyle` both
// carry `align` (4), `borderWidth` (2), `ringOpacity` (1) and `borderColor`
// (`primary`), and so does the `focus_outline` component's own `fields`.
//
// They used to be two literals here (`kFocusRingStrokeN = 2` /
// `kFocusRingAlign = 4`) under a comment asserting that schema v2 does not
// carry them. It does, and asserting otherwise is the expensive half: a number
// written next to a field that states one goes on rendering after the field
// moves, and nothing but a canvas readback can tell.



// ─── Clipping ────────────────────────────────────────────────────────────────
//
// Every component in this file states its own `clipsContent`, because Figma's
// DEFAULT for a freshly created frame or component is `true` and four of them
// draw chrome OUTSIDE the component's bounds:
//
//   · Card's and Badge's focus ring, at `-align` on all four sides
//   · Avatar's corner badge, and its `Ring=true` band at `-ringOffset`
//   · Tooltip's tail (`y = height`) and its trigger (`y = height + offset`)
//
// On a page built from scratch every one of those was cut away — the ring never
// appeared, the tooltip had no tail — and a RE-RUN over the same page looked
// correct, because `resetNode` (`helpers.ts`) clears the flag and only the reuse
// path calls it. A defect that heals on the second run is the worst shape to
// find by looking: whoever checked after a rebuild saw nothing wrong.
//
// The value is not a preference. Each widget states it:
//
//   · `Stacks(clipBehavior: .none)` — `focus_outline.dart:154`,
//     `avatar.dart:470`, `tooltip.dart:213` → false
//   · `Container(clipBehavior: .antiAlias)` — Progress's track → true
//   · Alert's `DecoratedBox` (`alert.dart:159`) takes no clip at all → false
//
// Written even where it agrees with the default (Progress's track), so the
// reuse path cannot quietly flip it back.

// ─── Component properties ────────────────────────────────────────────────────
//
// The main component id an INSTANCE_SWAP property needs as its default value.
//
// It cannot be read back off the instance: `documentAccess: "dynamic-page"`
// (manifest.json) makes `InstanceNode.mainComponent` **write-only**, and its
// async replacement (`getMainComponentAsync`) is unreachable from these
// synchronous builders. The `Icon` set is on the page by construction — every
// caller declares `needs: ['Icon']` — so the main component is located the
// same way `makeIcon` locates it, and the id comes from there.
// One implementation, in `component-props.ts` — this file used to carry its
// own copy (as did `form.ts`) and they drifted. The glyph argument is gone;
// see that function for why an INSTANCE_SWAP default cannot express one.
function iconSlotDefaultId(page: PageNode): string {
  return iconMainId(page);
}


// Corner rounding on an INSTANCE. `bindRadiusN` accepts frames / components /
// rectangles and an instance is none of those, so a composed child whose
// radius is the PARENT's design value — a card surface takes the card's
// radius, not `OutlinedContainer`'s own default — is re-bound here.
function bindInstanceRadius(node: InstanceNode, lk: VarLookup, n: number | Dim): void {
  const radius = dimVal(n);
  for (const corner of corners) node.setBoundVariable(corner, lk.radius(radius));
}

// One composition slot as the two nodes it takes: a holder carrying the
// BOOLEAN (the slot being ABSENT — the widget's `null`) and the instance
// inside it carrying the INSTANCE_SWAP (the slot being ANY widget). Both
// statements are needed and neither is expressible without the other node,
// because a node holds exactly ONE `componentPropertyReferences` map and
// `bindVisibleProp` / `bindSwapProp` each assign that map wholesale — calling
// both on the instance silently drops whichever ran first.
//
// `parent` must ALREADY be inside the component. Figma rejects a property
// reference on a detached node ("Can only set component property references on
// symbol sublayer"), the throw is not rolled back — the entry is reported as
// failed and a half-drawn component is left on the page. Appending here rather
// than leaving it to the caller is what makes the order impossible to get
// wrong; the caller only positions the holder afterwards.
// A slot's two nodes, kept so the caller can declare and bind its properties
// AFTER `mountSet().finish()`.
//
// `propertyOwner()` inside a variant loop answers with the variant, because a
// freshly created component has no set parent until `finish()` combines them.
// Four builders in this file did exactly that, and every one of their
// properties landed on all N members instead of once on the set — Badge's five
// were defined eighty times. Collecting the nodes and binding later is the
// same shape `form.ts` documents for Button and `form-pickers.ts` uses for its
// dialog titles.
interface SlotPair {
  holder: FrameNode;
  content: InstanceNode;
}

// Declares one slot's `Show <name>` / `<Name>` pair on the set and points every
// variant's copy of that slot at it. One definition, N binds — which is what a
// set member sharing its owner's properties means.
//
// Both names are spelled at the call site rather than derived from one. The
// derived version worked and was invisible: `figma_slot_swappability` reads
// property names as string literals, so a computed `Show ${name}` made eight
// closed slots read as having no property at all. A guard that cannot see a
// refactor is a cost the refactor has to pay.
function bindSlotPairs(
  set: ComponentSetNode,
  refs: readonly SlotPair[],
  showProp: string | null,
  swapProp: string | null,
): void {
  if (refs.length === 0) return;
  for (const ref of refs) {
    bindVisibleProp(ref.holder, showProp);
    bindSwapProp(ref.content, swapProp);
  }
}

// Switches off a slot the COMPOSED CHILD owns, through the child's own
// property.
//
// A child built for its own page shows its `W?` slot filled — that placeholder
// is the honest image of "any widget goes here" where the child is the subject.
// Composed as a PARENT's surface it is not the parent's content at all, so the
// parent has to say so, and the only thing entitled to hide that node is the
// property the child bound it to.
//
// Hence `setProperties` and never `.visible` on the node inside the instance:
// a node bound to a property is driven by that property, and assigning around
// one is how the Select trigger lost its chevron once already. Resolved by NAME
// off the instance's own `componentProperties`, because `addComponentProperty`
// hands back an id carrying a `#<id>` suffix the parent never sees — the same
// read-then-patch `helpers.ts#setSlotIcon` does in the other direction (reveal
// a slot, point its swap at a glyph). This is the half no shared helper covers.
//
// Throws when the child declares no such BOOLEAN, for the reason `setSlotIcon`
// throws rather than returning: an empty patch is a legal no-op, so a renamed
// pair upstream would leave the placeholder painted while this builder, the
// harness and every guard stayed green — the exact shape that shipped
// Carousel's two glyph-less circles. The cost is this one entry reported as
// failed with a name on it, and that is the cheaper failure: a named failure
// gets looked for, a component that looks finished while carrying someone
// else's icon does not.
//
// Placed HERE — above `slotNodes`, not below it — and that position is load
// bearing. `figma_composition_parity` attributes a composed child to the
// function whose SPAN the mention falls in, and a span runs from one top-level
// `function` to the next, comments included. Dropping this one between
// `slotNodes` and the Card section moved that section's doc comment into this
// span, and the builders that reach `slotNodes` lost a child they had been
// credited with through it — a guard reading +1 for a paragraph that moved.
function hideComposedSlot(instance: InstanceNode, slot: string): void {
  const props: ComponentProperties | undefined = instance.componentProperties;
  const wanted = `show ${slot.toLowerCase()}`;
  if (props) {
    for (const key of Object.keys(props)) {
      if (key.split('#')[0].toLowerCase() !== wanted) continue;
      if (props[key].type !== 'BOOLEAN') continue;
      const patch: { [name: string]: boolean } = {};
      patch[key] = false;
      instance.setProperties(patch);
      return;
    }
  }
  throw new Error(
    `hideComposedSlot('${slot}'): ${instance.name} declares no 'Show ${slot}' ` +
      `BOOLEAN, so its '${slot}' placeholder cannot be switched off. Its ` +
      `properties are [${props ? Object.keys(props).map((k) => k.split('#')[0]).join(', ') : ''}] ` +
      '— the child renamed the pair, or this is the wrong slot name.',
  );
}

function slotNodes(
  parent: ComponentNode | FrameNode,
  content: InstanceNode,
  name: string,
  showProp: string | null,
  swapProp: string | null,
  shown: boolean,
  dir: 'HORIZONTAL' | 'VERTICAL' = 'HORIZONTAL',
): FrameNode {
  const holder = autoFrame(name, dir);
  content.name = `${name} content`;
  holder.appendChild(content);
  parent.appendChild(holder);
  // Matches the BOOLEAN's default so the main component reads the same way an
  // un-overridden instance of it does.
  holder.visible = shown;
  bindVisibleProp(holder, showProp);
  bindSwapProp(content, swapProp);
  return holder;
}

// ─── Card ────────────────────────────────────────────────────────────────────

// Data-driven from coui_core: CARD.variants.defaultsByVariant (bg/border) +
// A `Gap` node — a column that states TWO different gaps cannot carry both as
// `itemSpacing`, so the second one is a child. Same shape as
// `display-data.ts#gapSpacer`; spelled here because that one is file-private.
function cardGap(name: string, lk: VarLookup, size: number | Dim): FrameNode {
  const g = figma.createFrame();
  g.name = name;
  g.layoutMode = 'NONE';
  g.fills = [];
  bindSize(g, lk, size, size);
  return g;
}

// CARD.fields (borderRadius/padding/headerBodyGapStyle/bodyTextStyle) +
// CARD.fields.clickableStyle — the composed `Clickable` that owns the card's
// disabled opacity and focus ring (`card.dart`'s `_CardInteractiveWrapper`
// passes `resolved.clickableStyle` straight to it), which is where the two
// state axes below read their values from.
//
// `OutlinedContainer` is composed, not redrawn: `card.dart` returns
// `OutlinedContainer(containerStyle: resolved.containerStyle, child: …)`, i.e.
// the card's whole surface. A Figma instance cannot take appended children, so
// it cannot literally wrap the header / body / footer column the way the widget
// does — instead the instance is the component's FIRST child, absolutely
// positioned at the component's own bounds and STRETCHED to them, which puts it
// behind everything (children are ordered back-to-front), leaves the column in
// the root's auto-layout, and keeps the box under whatever size a consumer gives
// the instance. The root paints nothing of its own; painting there too is what
// "draws the box twice" means.
//
// `Clickable` stays drawn — see the note at its local below.
//
// Slots → properties, one per contract slot:
//
//   · `header` / `body` / `footer` are filled with text nodes, so their axis is
//     the copy: a TEXT property each. `footer` additionally gets a BOOLEAN on
//     its holder — "a Card without a footer" is a state to pick, not a layer to
//     delete — and that needs the holder, because one node carries one
//     `componentPropertyReferences` map (see `slotNodes`).
//   · `media` / `overlay` / `child` take arbitrary widgets, so each is an
//     INSTANCE_SWAP plus the BOOLEAN that reaches the widget's `null`. The
//     placeholders are real components (the slot stand-in for the two
//     image-shaped slots — docs/contributing/figma.md, "빈 슬롯의 대역" —
//     and `Badge` for the chip-shaped overlay) rather than drawn rectangles,
//     so what a designer swaps FROM is already a component.
//
// `media` / `overlay` / `child` default OFF. That is the widget's own default —
// all three are `W?` and null unless passed — and it is also what keeps the
// picture honest: `child` REPLACES the slot layout (`card.dart` renders
// `child ?? slotLayout`), so drawing both at once would show a state the widget
// cannot be in. Switching `Show child` on covers the column with the variant's
// own background, which is the closest Figma gets to "instead of".
//
// Header and body both read their whole typography slot — `headerTextStyle`
// (role `titleMedium` at its own weight, `on-surface`) and `bodyTextStyle`
// (role `bodyMedium`) — through the `textStyleData` + `textLabelOpts` pair, so
// every metric is the role's. Naming a size here instead would be a number
// chosen in this file next to a field that already states one: a header written
// as 14 while `titleMedium` is 18 renders the title at body size, and nothing
// but a canvas readback can see it — the role name still reaches the plugin,
// the field still counts as read, and the picture is 4px wrong forever.
const kCardHeaderText = '프로젝트 요약';
const kCardBodyText = '이번 주 진행 상황을 확인해 보세요.';
const kCardFooterText = '3일 전 업데이트';

// Preview-only sizing, applied through `resize()` and never through a
// token-binding helper: `CoreCardStyle` states no card width and no media
// height (`sizing` is a mode, not a number), so binding either would assert a
// design decision the design system never made.
const kCardWidth = 260;
const kCardMediaHeight = 120;

// The stand-in shape for the two image-shaped slots, and the `Badge` pose the
// overlay stands in as. Named by axis rather than spelled in full because
// `bestVariantName` scores what it is given — a child set free to grow an axis
// would break an exact-name match and fail the whole Card entry, leaving half a
// Card on the page.
//
// The pose is the look this overlay has always had: a filled primary pill at
// `sm` — the old `Variant=primary, Style=count` member, a pill on the brand
// colour. Badge's axes split that one value into a tone, a strength and a form
// (`CoreBadgeTone` · `CoreBadgeVariant` · `CoreBadgeForm`), so the same picture
// is now three of them. The old member carried the set's TEXT default — the
// word "Badge" — and a word is a `label` now, so the pill keeps its shape only
// by carrying a number: the composer writes the count's default copy
// (`kCountBadgeDefault`) into its `Child`, as a composed count does in a tab.
const kCardSlotShape: SlotStandInShape = 'rectangular';
const kCardOverlayBadgePose = {
  Tone: 'primary',
  Variant: 'filled',
  Size: 'sm',
  Style: 'count',
} as const;

function cardVariantName(
  variant: string,
  disabled: string,
  focused: string,
  hovered: string,
): string {
  return (
    `Variant=${variant}, Disabled=${disabled}, ` +
    `Focused=${focused}, Hovered=${hovered}`
  );
}

function buildCard(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = CARD.fields;
  // `clickableStyle` is the nested slot `_CardInteractiveWrapper` hands to the
  // composed `Clickable`, and it is where both state axes below get their
  // values: `disabledOpacity` dims the whole surface, and
  // `focusOutlineStyle.borderColor` is the ring `addFocusRing` paints. That
  // wrapper owns no fill and no border of its own (`primitives-behaviour.ts`
  // says the same of the `Clickable` component), so those two effects are its
  // entire visible contribution — there is no third thing an instance would
  // add, and an instance could not wrap the card anyway.
  const clickable = f.clickableStyle;
  const headerStyle = textStyleData(f.headerTextStyle);
  const bodyStyle = textStyleData(f.bodyTextStyle);
  // Card's `axes` declares `variant` and nothing else — no Size, no Enabled —
  // so the shared enumerator's answer for this component is exactly these two
  // names, and the four-loop shape below adds the three POSE axes on top of
  // them. `Object.entries` is kept rather than `enumerateAxisCombos` because
  // the loop needs the variant's DATA row for every member anyway, and the two
  // lists are the same list: `axes.variant.members` and
  // `variants.defaultsByVariant`'s keys are both `outlined, filled`.
  const variants = Object.entries(CARD.variants.defaultsByVariant);
  const names: string[] = [];
  for (const [vn] of variants) {
    for (const disabled of kBoolAxis) {
      for (const focused of kBoolAxis) {
        for (const hovered of kBoolAxis) {
          names.push(cardVariantName(vn, disabled, focused, hovered));
        }
      }
    }
  }
  const mediaRefs: SlotPair[] = [];
  const overlayRefs: SlotPair[] = [];
  const childRefs: SlotPair[] = [];
  const headers: TextNode[] = [];
  const bodies: TextNode[] = [];
  const footers: TextNode[] = [];
  const footerHolders: FrameNode[] = [];
  const footerGaps: FrameNode[] = [];
  const mount = mountSet(page, 'Card', names);
  const overlayBadge = bestVariantName(page, 'Badge', kCardOverlayBadgePose);
  for (const [vn, v] of variants) {
    for (const disabled of kBoolAxis) {
      for (const focused of kBoolAxis) {
        for (const hovered of kBoolAxis) {
          const comp = mount.getOrCreate(
            cardVariantName(vn, disabled, focused, hovered),
          );
          comp.layoutMode = 'VERTICAL';
          comp.primaryAxisSizingMode = 'AUTO';
          comp.counterAxisSizingMode = 'FIXED';
          comp.primaryAxisAlignItems = 'MIN';
          comp.counterAxisAlignItems = 'MIN';
          // The focus ring below is drawn entirely outside these bounds — see
          // the Clipping section.
          comp.clipsContent = false;

          // ── OutlinedContainer — the card's whole surface ──
          // Appended FIRST so it sits at the back (children are ordered
          // back-to-front) and ABSOLUTE so it is out of the column's flow. Its
          // own default border is cleared before repainting: `borderData`
          // returns early on a transparent colour, so a `filled` card would
          // otherwise keep the container's outline.
          //
          // And its own `child` slot is switched off. That slot ships ON — a
          // `file` glyph in a 160×48 cell, which is the right picture for the
          // container's own page and wrong here: this instance is the card's
          // BACKGROUND, and the card's content is the column below plus its own
          // `child` slot. Left on, all eight variants carried that glyph
          // behind the header. The container keeps painting fill,
          // border and radius, which is the whole reason it is composed.
          const surface = instanceOf(page, 'OutlinedContainer');
          // `clipBehavior`, forwarded — and it is not the flag on `comp` above.
          // That one is `false` because the focus ring is drawn outside the
          // component's bounds; this one is the card's SURFACE clip, which the
          // widget hands to the composed container.
          //
          // The RESTING reading, which is the un-upgraded one:
          // `card_style.dart` upgrades `none` to `antiAlias` when a media slot is
          // present, and `Show media` defaults to false — so a card at rest states
          // `none` and clips nothing. A designer turning media on takes the
          // upgraded branch, which Figma has no way to express as a conditional;
          // stating the resting value is the half that is true, and asserting
          // `antiAlias` unconditionally would clip a card that has no image.
          surface.clipsContent = clipsFor(f.clipBehavior, 'card.clipBehavior');
          surface.name = 'OutlinedContainer';
          hideComposedSlot(surface, 'child');
          // Wrapped, not pinned directly — `pinAbsolute` appends it too. The chrome
          // writes below stay on the INSTANCE; only the pin moves to the holder.
          //
          // STRETCH on both axes, and the HOLDER is what gets sized at the end
          // (`sizePin`, below). This surface is the card's whole box, and a card
          // is the one component a consumer resizes on every page — `FILL` across
          // a column, `HUG` down its own copy — so the surface has to follow the
          // instance's bounds, not the bounds this builder previewed. Pinned as
          // `MIN` it did not: an app file's 358-wide Card drew a 260-wide outline
          // under a 358-wide column of text, and its 91-tall copy sat inside a
          // 137-tall outline that ran on under the button below it.
          const surfacePin = pinAbsolute(comp, surface, 0, 0, {
            horizontal: 'STRETCH',
            vertical: 'STRETCH',
          });
          surface.strokes = [];
          // The variant's colour goes to the composed container's material
          // layer: a content surface on both platforms (Web marks the card
          // `webSurfaceMarkerFor(role)`; Flutter's card is the composed
          // `OutlinedContainer`, which reads `theme.surfaceFor(role)`).
          applySurfaceMaterial(surface, lk, colorData(v.backgroundColor), 'content', {
            radius: f.borderRadius.topLeft,
          });
          borderData(surface, lk, colorData(v.borderColor), dimVal(v.borderWidth) || 1);
          // `CoreShadow.none` today. Applied rather than skipped so that a card
          // whose default becomes elevated needs no change here, and so a
          // re-run cannot leave a previous run's shadow attached.
          // Hover raises the card, and that is hover's ONLY visible effect here —
          // nothing else in `_CardInteractiveWrapper` branches on `_hovered`, and
          // `pressedScale` is 1.0 so there is no press-shrink either. A pointer
          // RESTS on a card, so it earns a pose.
          //
          // The stack is READ, not chosen: `hoverElevation` is a choice
          // (`{choice: medium}`) and `elevationLayers` resolves it against
          // `OutlinedContainer`'s exported `constants`. This axis was declined for
          // exactly as long as that resolution was impossible — the note at the top
          // of this file lists the three ways to draw it anyway and why each is
          // worse than not drawing it, the worst being to borrow `Popup`'s stack
          // because it happens to match today and would silently follow `Popup` the
          // day it moved.
          const cardCast =
            hovered === 'true' && disabled === 'false'
              ? elevationLayers(
                  f.hoverElevation,
                  f.boxShadow,
                  'card.hoverElevation',
                )
              // The idle stack comes from `elevation` for the same reason the
              // hover one comes from `hoverElevation`: `card_style.dart` hands
              // `elevation.toOutlinedContainerElevation()` to the composed
              // container, and an explicit `boxShadow` overrides it. Passing
              // `f.boxShadow` alone read the override and never the choice — it
              // is `none` today so the picture is identical, and `elevationLayers`
              // throws on an unexported step rather than painting flat.
              : elevationLayers(f.elevation, f.boxShadow, 'card.elevation');
          setShadow(surface, cardCast, lk, colorData(f.shadowBaseColor));
          // A card at rest casts nothing, and both platforms give it the cast a
          // style contributes (Web gates `kControlShadowRestMarker` off an
          // unstated `boxShadow`; Flutter's composed container falls back to
          // `controlShadow`). Re-added here because the shadow written on the
          // instance replaces the one its main component carries.
          if (cardCast.layers.length === 0) addControlShadow(surface, lk);
          // The rim rides the card's resting lift — the composed container's
          // stack on Flutter, the lift marker on Web — and neither platform
          // lights a hover lift that rose from flat (Flutter paints it on a
          // wrapper, Web adds no marker). Flat today, so off.
          setSurfaceRim(
            surface,
            lk,
            'content',
            elevationLayers(f.elevation, f.boxShadow, 'card.elevation').layers.length > 0,
          );
          bindInstanceRadius(surface, lk, f.borderRadius.topLeft);
          surface.x = 0;
          surface.y = 0;

          // ── media + overlay ──
          // `_CardSlotLayout` renders `Stacks(children: [media!, ?overlay])`
          // above the padded column and outside its padding, so this is a
          // manually-placed frame rather than a third auto-layout child, and
          // `overlayInset` is the inset the Web resolver emits as CSS `inset`.
          const mediaStack = figma.createFrame();
          mediaStack.name = 'media';
          mediaStack.layoutMode = 'NONE';
          mediaStack.fills = [];
          mediaStack.resize(kCardWidth, kCardMediaHeight);
          comp.appendChild(mediaStack);
          mediaStack.layoutSizingHorizontal = 'FILL';
          mediaStack.visible = false;

          const media = slotStandIn(page, 'media content', kCardSlotShape);
          mediaStack.appendChild(media);
          media.x = 0;
          media.y = 0;
          mediaRefs.push({ holder: mediaStack, content: media });

          const overlayInset = dimVal(f.overlayInset);
          const overlayInstance = instanceOf(page, 'Badge', overlayBadge);
          setInstanceTextNamed(overlayInstance, 'Child', kCountBadgeDefault);
          const overlay = slotNodes(mediaStack, overlayInstance, 'overlay', null, null, false);
          overlayRefs.push({ holder: overlay, content: overlayInstance });
          overlay.x = overlayInset;
          overlay.y = overlayInset;

          // ── the padded slot column ──
          // The padding lives here, not on the root: `card.dart` zeroes the
          // container's padding whenever the slots render (`containerStyle
          // .copyWith(padding: .zero)`) and `_CardSlotLayout` re-applies it
          // around the header / body / footer column only, which is what leaves
          // `media` bleeding to the card's edges.
          const content = autoFrame('content', 'VERTICAL');
          bindPad(content, lk, f.padding);
          content.setBoundVariable('itemSpacing', lk.space(dimVal(f.headerBodyGapStyle.size)));
          comp.appendChild(content);
          content.layoutSizingHorizontal = 'FILL';

          const header = makeLabel(kCardHeaderText, lk, textLabelOpts(lk, headerStyle));
          header.name = 'header';
          // `textAutoResize` BEFORE `layoutSizingHorizontal` — the order
          // body/footer and Alert already use. A title that still auto-sizes
          // both axes, then is told to FILL, measures against one unwrapped
          // line and will not wrap when a consumer stretches the card.
          header.textAutoResize = 'HEIGHT';
          content.appendChild(header);
          header.layoutSizingHorizontal = 'FILL';
          header.layoutSizingVertical = 'HUG';
          headers.push(header);

          const body = makeLabel(kCardBodyText, lk, textLabelOpts(lk, bodyStyle));
          body.name = 'body';
          body.textAutoResize = 'HEIGHT';
          content.appendChild(body);
          body.layoutSizingHorizontal = 'FILL';
          body.layoutSizingVertical = 'HUG';
          bodies.push(body);

          // The footer inherits the card's ambient body typography, exactly as
          // `card.dart` does (`DefaultTextStyle.merge(style: bodyTextStyle)`
          // wraps the whole slot layout).
          //
          // `bodyFooterGapStyle` gets a node. The note here used to say this column
          // could not honour it separately because Figma auto-layout has a single
          // `itemSpacing`, so the body↔footer gap read as the header↔body one —
          // true about `itemSpacing` and false about the column: a second stated gap
          // becomes a CHILD, which is what `gapSpacer` exists for and what Timeline,
          // Basic and PhoneInput already do. Two different values were collapsed
          // into one, and only the smaller one was ever on the canvas.
          //
          // Hidden with the footer it separates — an auto-layout frame skips hidden
          // children, so a visible spacer above a hidden slot leaves a hole.
          const footerGap = cardGap('body footer gap', lk, CARD.fields.bodyFooterGapStyle.size);
          content.appendChild(footerGap);
          footerGaps.push(footerGap);

          // Two nodes: the holder is what "no footer" switches off, the text
          // inside it is what the copy is edited on. One node cannot carry both
          // references.
          const footerHolder = autoFrame('footer', 'VERTICAL');
          content.appendChild(footerHolder);
          footerHolder.layoutSizingHorizontal = 'FILL';
          footerHolders.push(footerHolder);
          const footer = makeLabel(kCardFooterText, lk, textLabelOpts(lk, bodyStyle));
          footer.name = 'footer content';
          footer.textAutoResize = 'HEIGHT';
          footerHolder.appendChild(footer);
          footer.layoutSizingHorizontal = 'FILL';
          footer.layoutSizingVertical = 'HUG';
          footers.push(footer);

          // ── child — the escape hatch that replaces the column ──
          // Opaque in the variant's own background and sized to the whole card,
          // so switching it on reads as `child ?? slotLayout` rather than as a
          // widget landing on top of one. It keeps the container padding, which
          // is the one thing `card.dart` does NOT zero on this path.
          const childInstance = slotStandIn(page, 'child content', kCardSlotShape);
          const childHolder = slotNodes(
            comp,
            childInstance,
            'child',
            null,
            null,
            false,
          );
          childRefs.push({ holder: childHolder, content: childInstance });
          pinInFlow(comp, childHolder);
          bindPad(childHolder, lk, f.padding);
          bindRadiusN(childHolder, lk, f.borderRadius.topLeft);
          fillData(childHolder, lk, colorData(v.backgroundColor));

          // Width only. `resize` pins both axes; height goes back to hugging
          // so copy can grow the card, width stays fixed so the column's FILL
          // is not refused under a hugging parent.
          comp.resize(kCardWidth, comp.height);
          comp.primaryAxisSizingMode = 'AUTO';
          comp.counterAxisSizingMode = 'FIXED';
          // Both absolute layers take the card's settled bounds, which only
          // exist once the flow children are in — the same ordering
          // `addFocusRing` depends on. Through `sizePin`, not `resize` on the
          // instance: the holder carries the pin, so the holder is what has to
          // be the card's size (see `sizePin` for the 162×50 this replaces).
          sizePin(surfacePin, comp.width, comp.height);
          childHolder.resize(comp.width, comp.height);
          childHolder.x = 0;
          childHolder.y = 0;
          // The same promise for the `child` layer, which is a plain frame and so
          // carries its own constraints: a designer's swapped-in child fills the
          // card the consumer sized, not the 260 previewed here. Set after the
          // size, as `flushTintLayers` does, so the zero insets are what is kept.
          childHolder.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };

          if (disabled === 'true') comp.opacity = dimVal(clickable.disabledOpacity);
          if (focused === 'true') {
            addFocusRing(comp, lk, clickable.focusOutlineStyle, f.borderRadius.topLeft);
          }
        }
      }
    }
  }
  const set = mount.finish();
  // Ten properties, one definition each, on the set that only exists now —
  // see `SlotPair`. Resolving the owner inside the loop gave all eight
  // variants their own copy of all ten, and the comment that used to sit
  // there asserted the opposite.
  const headerProp = defineProp(set, 'Header', 'TEXT', kCardHeaderText);
  const bodyProp = defineProp(set, 'Body', 'TEXT', kCardBodyText);
  const footerProp = defineProp(set, 'Footer', 'TEXT', kCardFooterText);
  const footerShow = defineProp(set, 'Show footer', 'BOOLEAN', true);
  for (const n of headers) bindTextProp(n, headerProp);
  for (const n of bodies) bindTextProp(n, bodyProp);
  // `CoreCardContract.body` is `W?` — a card without a body is a first-class
  // state, and a composer (Carousel's banner slide) needs to say so from the
  // outside. The `content` column is auto-layout, so a hidden body bills no gap.
  const bodyShow = defineProp(set, 'Show body', 'BOOLEAN', true);
  for (const n of bodies) bindVisibleProp(n, bodyShow);
  for (const n of footers) bindTextProp(n, footerProp);
  for (const n of footerHolders) bindVisibleProp(n, footerShow);
  // The gap follows the slot's own BOOLEAN rather than getting one of its own:
  // a designer toggling `Footer` off and finding a stray 12px above nothing is
  // the hole this pair avoids.
  for (const n of footerGaps) bindVisibleProp(n, footerShow);
  bindSlotPairs(
    set,
    mediaRefs,
    defineProp(set, 'Show media', 'BOOLEAN', false),
    defineProp(set, 'Media', 'INSTANCE_SWAP', slotStandInDefault(page, kCardSlotShape)),
  );
  bindSlotPairs(
    set,
    overlayRefs,
    defineProp(set, 'Show overlay', 'BOOLEAN', false),
    defineProp(set, 'Overlay', 'INSTANCE_SWAP', mainComponentId(page, 'Badge', overlayBadge)),
  );
  bindSlotPairs(
    set,
    childRefs,
    defineProp(set, 'Show child', 'BOOLEAN', false),
    defineProp(set, 'Child', 'INSTANCE_SWAP', slotStandInDefault(page, kCardSlotShape)),
  );
  // The variant the code defaults to (`CoreCardVariant.defaultVariant`, carried
  // by the export) takes the set's top-left corner — the member Figma hands a
  // freshly placed instance.
  defaultSetLayout(set, { Variant: CARD.axes.variant.default });
  // #4099 — contract props.slots 여섯 개 전부가 위에서 property 를 받았고,
  // 각 property 는 그 슬롯을 렌더하는 노드에 BOUND 되어 있다: header/body/
  // footer 는 TEXT (footer 는 `Show footer` BOOLEAN 까지), media/overlay/child
  // 는 BOOLEAN + INSTANCE_SWAP. 정의는 set 에 한 번, 모든 variant child 가
  // 같은 key 를 참조한다 — 슬롯마다 렌더 노드가 실재하므로 "렌더 노드 없음"
  // 으로 건너뛴 슬롯은 없다.
  return set;
}

// ─── Badge ───────────────────────────────────────────────────────────────────

// Fully data-driven from coui_core, through the same three tables the two
// resolvers merge (`badge_style.dart`, both platforms):
//
//   BADGE.sizes.defaultsBySize      the step — height (`minHeight`), padding,
//                                   gap, the label's role, icon, both dot
//                                   diameters and the label form's corner
//   BADGE.variants.defaultsByForm   what the form changes on top of the step —
//                                   the label's weight and the pill corner a
//                                   number and a dot take
//   BADGE.variants.defaultsByTone   each tone's seven colours; `restingColors`
//                                   picks the ones a variant and a form paint
//
// plus BADGE.fields (borderWidth / stateLayer / focusOutlineStyle) and
// BADGE.constants (the transparent fill under an outlined badge).
//
// `leading` / `trailing` are `W?` slots the badge widget fills with an icon
// (`badge.dart` wraps each in an `IconTheme` sized from `iconStyle` and
// coloured from the foreground), so each becomes a real `Icon` INSTANCE plus
// two properties — see `badgeIconSlot`. `child` is the `W?` the badge lays out
// between them; this builder fills it with a text node, so its property is a
// TEXT one. Swapping it would need a `Text` component in the REGISTRY, and the
// owner decided against adding one — Figma's native typography mechanism is
// the shared Text Style.
//
// The INSTANCE_SWAP carries the slot's OWN name and the BOOLEAN is prefixed
// (`Leading` / `Show leading`), not the other way round: the swap is the
// statement the contract makes (`W?` = any widget), the boolean is the
// narrower one (present or not), and a Figma owner cannot hold two properties
// under one name. Both slots rest OFF — `leading` and `trailing` are null
// unless a caller passes them, and a bare Badge carries no icon.
//
// ─── Axes — Variant × Size × Style × Tone ───────────────────────────────────
//
// Four design axes, 3 × 6 × 3 × 6 = 324 members. `Variant` and `Size` are the
// schema's (`axisSpecsOf`); `Style` (`CoreBadgeForm`) and `Tone`
// (`CoreBadgeTone`) come from the exported `axes.other` rather than a literal,
// so the canvas cannot hold a member the enums do not have. The name spells
// them in `kAxisOrder`'s order (`Variant=…, Size=…, Style=…, Tone=…`) because
// `composeVariantName` refuses any other — `Tone` already sits below `Style`
// there for EmptyState and MenuItem, and a member's name is its identity.
// `xl2` is on the Size axis and not in the table: the cell draws what the
// widget renders for it, the `xl` row (`sizeRowFor`).
//
// Hover and focus are NOT axes. They are poses an interactive badge passes
// through (`onPressed != null`), and as axes they multiplied the set by four
// for two layers that are either on or off — so each is a BOOLEAN that shows
// one layer on every member:
//
//   · `Hover`           the state layer — the badge's own foreground over the
//                       fill at `stateLayer.hover`, the wash both resolvers
//                       composite. A dot has no foreground (`restingStyleFor`
//                       states none for it), so it has nothing to wash with and
//                       draws no layer.
//   · `Show focus ring` the `FocusOutline` ring and its band, at the badge's own
//                       corner — what both platforms draw around the badge's
//                       box. Spelled the way every set that draws the shared
//                       ring spells its switch (`state-axis.ts`): a consumer
//                       file keys an override by name and type, and a second
//                       spelling would be a second property.
//
// Pressed is not drawn: it is the same layer at `stateLayer.pressed`, held only
// while a pointer is down.
const kBadgeLabelText = '신규';
const kBadgeLeadingGlyph = 'circle-check';
const kBadgeTrailingGlyph = 'x';
// `CoreBadgeForm.dot` — the form that is a bare circle — and
// `CoreBadgeForm.count`, the one that is never narrower than it is tall.
const kBadgeDotForm = 'dot';
const kBadgeCountForm = 'count';
// The member a freshly placed instance becomes — the widget's own resting badge:
// `CoreBadgeTone.defaultTone`, `CoreBadgeForm.defaultForm` and
// `CoreBadgeContract.defaultSize`. The variant's default is exported
// (`axes.variant.default`); these three are not — schema v3 records `axes.other`
// and the size ladder without a default key — so they are named by hand. The
// tone has a second reader, the count `composeCountBadge` drops into a tab
// (instance-reach.ts), so it is named there once and read here, and the size
// is named beside it; the form is this builder's alone (the count names its
// own form, strength and step).
const kBadgeLead = { Tone: kBadgeDefaultTone, Style: 'label', Size: kBadgeDefaultSize } as const;

type BadgeToneRow =
  (typeof BADGE.variants.defaultsByTone)[keyof typeof BADGE.variants.defaultsByTone];

interface BadgeColors {
  background: ColorData | null;
  /** `null` for a dot — it has no content to colour. */
  foreground: ColorData | null;
  /** `null` unless the variant states a line. */
  border: ColorData | null;
  /**
   * The icon and leading dot — the foreground unless the strength states a
   * mark colour of its own (`outlinedMarkColor` on the status tones).
   */
  mark: ColorData | null;
}

// `CoreBadgeToneStyle.restingStyleFor(variant, form)`, read off the exported row
// — the colours a badge of this tone paints at rest. The choice is the Core
// method's: a dot paints the tone's dot colour whatever the variant, and only
// `outlined` states a line, over the transparent fill Core names for it.
function restingColors(tone: BadgeToneRow, variant: string, form: string): BadgeColors {
  if (form === kBadgeDotForm) {
    return { background: colorData(tone.dotColor), foreground: null, border: null, mark: null };
  }
  switch (variant) {
    case 'filled':
      return {
        background: colorData(tone.filledBackgroundColor),
        foreground: colorData(tone.filledForegroundColor),
        border: null,
        mark: colorData(tone.filledForegroundColor),
      };
    case 'tonal':
      return {
        background: colorData(tone.tonalBackgroundColor),
        foreground: colorData(tone.tonalForegroundColor),
        border: null,
        mark: colorData(tone.tonalForegroundColor),
      };
    case 'outlined': {
      const mark = optField<Color>(tone, 'outlinedMarkColor');
      return {
        background: colorData(BADGE.constants.outlinedBackgroundColor),
        foreground: colorData(tone.outlinedForegroundColor),
        border: colorData(tone.outlinedBorderColor),
        mark: colorData(mark ?? tone.outlinedForegroundColor),
      };
    }
  }
  throw new Error(
    `Badge: variant "${variant}" has no branch in restingColors — ` +
      '`CoreBadgeToneStyle.restingStyleFor` gained a strength this builder does not draw.',
  );
}

// One optional, swappable icon slot: a BOOLEAN for "is this slot filled" and an
// INSTANCE_SWAP for "with which widget".
//
// The two property ids come in from the call site rather than being declared
// here, because their names have to be spelled as literals for a reader (and
// for the slot-swappability scan) to see WHICH slot each property covers —
// a `${label} icon` template hides that from both.
function badgeIconSlot(
  lk: VarLookup,
  comp: ComponentNode,
  slot: 'leading' | 'trailing',
  glyph: string,
  foreground: ColorData | null,
  iconSize: number | Dim,
  refs: SlotPair[],
  // The slot's swap default (`iconSwapDefault`), so the property's first bind
  // leaves the glyph at `iconSize` (see `IconOpts.fromVariant`).
  fromVariant: ComponentNode | null,
): void {
  const icon = makeIcon(glyph, lk, {
    ...glyphOpts(lk, foreground, iconSize, 'size'),
    fromVariant,
  });
  // Off at rest — see the slot note above.
  const holder = slotNodes(comp, icon, slot, null, null, false);
  refs.push({ holder, content: icon });
}

// A badge's box — the same for every form. A content surface on both platforms
// (`badge_style.dart` reads `theme.surfaceFor(.content)`; the Web twin marks
// itself `webSurfaceMarkerFor(.content)`), and a box that states no cast, so it
// takes the one a style contributes on both (`resolveInjectedCast`;
// `kControlShadowRestMarker`).
function badgeChrome(
  comp: ComponentNode,
  lk: VarLookup,
  colors: BadgeColors,
  corner: Dim,
): void {
  bindRadiusN(comp, lk, corner);
  applySurfaceMaterial(comp, lk, colors.background, 'content', { radius: corner });
  borderData(comp, lk, colors.border, BADGE.fields.borderWidth);
  addControlShadow(comp, lk);
}

// The state layer — the foreground over the fill at the hover rung, the stacking
// `alphaBlend(fg @ stateLayer.hover, fill)` produces. Child 0, so it sits over
// the fill and under the content; the material layers go back under it when they
// are sized at the end of the entry (`flushTintLayers`). Hidden at rest, which is
// what `Hover`'s default says.
function badgeStateLayer(
  comp: ComponentNode,
  lk: VarLookup,
  foreground: ColorData,
  corner: Dim,
  box: { width: number; height: number },
): RectangleNode {
  const layer = figma.createRectangle();
  layer.name = 'state layer';
  layer.resize(box.width, box.height);
  bindRadiusN(layer, lk, corner);
  // The foreground's own token, at full strength — the rung's weight is the
  // layer's opacity, so the colour stays bound and follows the theme.
  fillData(layer, lk, foreground);
  layer.opacity = BADGE.fields.stateLayer.hover;
  layer.visible = false;
  // `insertChild` first, then pin: `pinAbsolute` appends, so pinning and then
  // moving to index 0 reparents the same node twice.
  comp.insertChild(0, layer);
  pinInFlow(comp, layer);
  layer.x = 0;
  layer.y = 0;
  layer.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };
  return layer;
}

function buildBadge(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = BADGE.fields;
  const sizeData = new Map(Object.entries(BADGE.sizes.defaultsBySize));
  const formData = new Map(Object.entries(BADGE.variants.defaultsByForm));
  const toneData = new Map(Object.entries(BADGE.variants.defaultsByTone));
  const form = BADGE.axes.other.find((o) => o.enum === 'CoreBadgeForm');
  const tone = BADGE.axes.other.find((o) => o.enum === 'CoreBadgeTone');
  if (!form || !tone) {
    throw new Error(
      'Badge: CoreBadgeForm / CoreBadgeTone is gone from the exported axes — the ' +
        'canvas has a Style / Tone axis that nothing in the contract now backs.',
    );
  }
  const members = enumerateAxisAssignments([
    ...axisSpecsOf(BADGE.axes),
    { axis: 'Style' as const, values: form.members },
    { axis: 'Tone' as const, values: tone.members },
  ]);
  // The slot glyphs are drawn from their swap defaults, so the properties'
  // first binds leave them at the size row's `iconStyle.size` (see
  // `IconOpts.fromVariant`).
  const leadingSwap = iconSwapDefault(page, 'Badge', 'Leading', iconSlotDefaultId(page));
  const trailingSwap = iconSwapDefault(page, 'Badge', 'Trailing', iconSlotDefaultId(page));
  const mount = mountSet(
    page,
    'Badge',
    members.map((m) => m.name),
  );
  const leadingRefs: SlotPair[] = [];
  const trailingRefs: SlotPair[] = [];
  const labels: TextNode[] = [];
  const dots: EllipseNode[] = [];
  const washes: RectangleNode[] = [];
  const rings: FocusRingNodes[] = [];
  for (const m of members) {
    const values = m.values;
    const toneRow = toneData.get(values['Tone']);
    const formRow = formData.get(values['Style']);
    if (!toneRow || !formRow) {
      throw new Error(`Badge: no tone / form row for "${m.name}"`);
    }
    // `xl2` is on the axis and not in the table — core states no xl2 badge
    // geometry, and a sixth row invented here would say something nothing
    // disagrees with. The cell draws what the widget renders for it.
    const s = sizeRowFor(sizeData, values['Size'], BADGE.axes.size.members);
    const colors = restingColors(toneRow, values['Variant'], values['Style']);
    // The form's corner over the step's: a number and a dot take the pill, a
    // word keeps the step's rounded rectangle.
    const corner = optField<{ topLeft: Dim }>(formRow, 'borderRadius')?.topLeft ?? s.borderRadius.topLeft;
    const comp = mount.getOrCreate(m.name);
    // The ring is drawn entirely outside these bounds — see the Clipping
    // section.
    comp.clipsContent = false;

    // A dot is a bare circle: no content row, no padding, and a box the step
    // names rather than one the content leaves behind.
    if (values['Style'] === kBadgeDotForm) {
      comp.layoutMode = 'NONE';
      bindSize(comp, lk, s.dotSize, s.dotSize);
      badgeChrome(comp, lk, colors, corner);
      rings.push(
        focusRing(comp, lk, {
          outline: f.focusOutlineStyle,
          color: focusOutlineRingColor(f.focusOutlineStyle),
          corner,
          width: dimVal(s.dotSize),
          height: dimVal(s.dotSize),
          visible: false,
        }),
      );
      continue;
    }

    // Label and count: content centred in a box at least `minHeight` tall —
    // the floor both resolvers state (`BoxConstraints(minHeight:)`; Web
    // `min-height`), which the content never reaches, so every step draws its
    // own height. Padding is horizontal only. A count is also never narrower
    // than it is tall, so a single digit stays a circle.
    comp.layoutMode = 'HORIZONTAL';
    comp.primaryAxisSizingMode = 'AUTO';
    comp.counterAxisSizingMode = 'AUTO';
    comp.primaryAxisAlignItems = 'CENTER';
    comp.counterAxisAlignItems = 'CENTER';
    bindPad(comp, lk, s.padding);
    comp.setBoundVariable('itemSpacing', lk.space(dimVal(s.iconLabelGapStyle.size)));
    const height = dimVal(s.minHeight);
    const heightStep = lk.sizeOrNull(height);
    comp.minHeight = height;
    if (heightStep) comp.setBoundVariable('minHeight', heightStep);
    if (values['Style'] === kBadgeCountForm) {
      comp.minWidth = height;
      if (heightStep) comp.setBoundVariable('minWidth', heightStep);
    }
    badgeChrome(comp, lk, colors, corner);

    // `showDot` — a circle in the mark colour (the label's, unless the
    // strength states one) before everything else in the row, on the same gap. An ellipse because neither platform states a
    // corner for it: both draw a circle (`BoxShape.circle` on Flutter, a fully
    // rounded box on Web).
    const dot = figma.createEllipse();
    dot.name = 'leading dot';
    bindSize(dot, lk, s.leadingDotSize, s.leadingDotSize);
    fillData(dot, lk, colors.mark);
    dot.visible = false;
    comp.appendChild(dot);
    dots.push(dot);

    badgeIconSlot(
      lk, comp, 'leading', kBadgeLeadingGlyph,
      colors.mark, s.iconStyle.size, leadingRefs, leadingSwap.variant,
    );

    // The step's role with the form's weight over it — a word at the role's
    // own 500, a figure at 600.
    const labelStyle = mergeTextStyleData(
      textStyleData(s.labelStyle),
      textStyleData(optField<TextLeaf>(formRow, 'labelStyle')),
    );
    const t = makeLabel(kBadgeLabelText, lk, textLabelOpts(lk, labelStyle, colors.foreground));
    t.name = 'child';
    comp.appendChild(t);
    t.layoutSizingHorizontal = 'HUG';
    t.layoutSizingVertical = 'HUG';
    labels.push(t);

    badgeIconSlot(
      lk, comp, 'trailing', kBadgeTrailingGlyph,
      colors.mark, s.iconStyle.size, trailingRefs, trailingSwap.variant,
    );

    // Read ONCE, after the last in-flow child: both overlays want the same box,
    // and both are absolute, so neither moves the hug between here and there.
    const box = timedGeom(() => ({ width: comp.width, height: comp.height }));
    if (colors.foreground != null) {
      washes.push(badgeStateLayer(comp, lk, colors.foreground, corner, box));
    }
    rings.push(
      focusRing(comp, lk, {
        outline: f.focusOutlineStyle,
        color: focusOutlineRingColor(f.focusOutlineStyle),
        corner,
        width: box.width,
        height: box.height,
        visible: false,
      }),
    );
  }
  const set = mount.finish();
  // The set is the owner and it exists only now — see `SlotPair`. Three hundred
  // and twenty-four members (Variant 3 × Size 6 × Style 3 × Tone 6, the sixth
  // size included since the enumerator rather than the five-row table decides
  // the Size axis) share these definitions; declaring inside the loop gave each
  // member its own copy.
  const childProp = defineProp(set, 'Child', 'TEXT', kBadgeLabelText);
  for (const t of labels) bindTextProp(t, childProp);
  // `CoreBadgeContract.defaultShowDot` is false — the dot is a cue a caller
  // asks for.
  const showDotProp = defineProp(set, 'Show dot', 'BOOLEAN', false);
  for (const d of dots) bindVisibleProp(d, showDotProp);
  bindSlotPairs(
    set,
    leadingRefs,
    defineProp(set, 'Show leading', 'BOOLEAN', false),
    defineProp(set, 'Leading', 'INSTANCE_SWAP', leadingSwap.id),
  );
  bindSlotPairs(
    set,
    trailingRefs,
    defineProp(set, 'Show trailing', 'BOOLEAN', false),
    defineProp(set, 'Trailing', 'INSTANCE_SWAP', trailingSwap.id),
  );
  // Off by default: hover and focus are states something enters, not how a
  // badge sits — and a non-interactive badge (the default, `onPressed == null`)
  // has neither.
  const hoverProp = defineProp(set, 'Hover', 'BOOLEAN', false);
  for (const w of washes) bindVisibleProp(w, hoverProp);
  const showFocusRingProp = defineShowFocusRing(set);
  for (const r of rings) bindShowFocusRing(r, showFocusRingProp);
  defaultSetLayout(set, { ...kBadgeLead, Variant: BADGE.axes.variant.default });
  return set;
}

// ─── Avatar ──────────────────────────────────────────────────────────────────

// Data-driven from coui_core: AVATAR.fields (backgroundColor /
// fallbackTextStyle / badgeInset / initialsFontRatio), the corner from the
// size and shape rows, plus the three ring
// fields the `Ring` axis below draws (`ringColor` / `ringWidth` /
// `ringOffset`).
//
// `ring` is a widget parameter (`avatar.dart`: `this.ring = false`) rather than
// a variant of a Core enum, and it gets an axis for the same reason Card's
// `Disabled` and `Focused` do: it is a state the avatar LINGERS in, it changes
// chrome, and the three fields that chrome is made of are all stated. The note
// here used to say those three were "unread because nothing here draws the
// ring — `ring` is a widget parameter, not a state this set has an axis for",
// which is an argument from where the flag lives to whether the canvas shows
// it. Being a widget parameter is what made it an axis and not a Variant.
//
// Each size row of `sizes.defaultsBySize` states THREE things — the diameter
// (`CoreAvatarStyle.diameter`), the initials ROLE
// (`CoreAvatarStyle.fallbackTextStyle`: labelXs · labelMedium · labelXl ·
// titleMedium · headlineSmall · headlineLarge at xs..xl2) and the rounded
// tile's corner (`CoreAvatarStyle.borderRadius`), so a step edited in Dart
// moves the canvas with the widget. The colour and the 600 weight every
// size shares are the flat `fields.fallbackTextStyle`; the row's role is laid
// over it with `mergeTextStyleData`, exactly as `resolveAvatar` lays
// `CoreAvatarStyle.fallbackRoleFor(size)` over `defaultFallbackTextStyle`.
//
// #4035 (C3) — the Size axis is enumerated by the SAME function G10 measures
// with (T-14), which means SIX rows: `CoreComponentSize` carries `xl2`, and
// the table has a row for each.
//
// The `Shape` axis is `CoreAvatarShape` (circle | rounded) — a contract
// parameter like `size`, read from the exported `axes.other` rather than a
// list here. A shape changes ONE thing, the corner, and the size row states
// the rounded tile's own (`defaultsBySize[*].borderRadius`, a quarter of the
// diameter); the disc's pill comes from `variants.defaultsByShape`, laid
// over it in `buildAvatar` the way the resolvers merge the two. The box, the
// `child` slot and the ring all take the member's corner, so a tile's
// picture, child and ring keep the tile's curve.
// Size 6 × Shape 2 × Ring 2 = 24 members.
//
// The initials FONT SIZE is the role's own. No diameter ratio is drawn: the
// ratio is an instance's statement (`initialsFontRatio`), not a default, so no
// default-size canvas member can show it. A role the weight departs from (the
// roles are 500 / 700, the avatar says 600) is drawn as node bindings without
// a text style — the same path Alert's title takes.
//
// The initials text carries a TEXT property. It mirrors `Avatar.initials` —
// a `String?` widget field, not one of the two `W?` slots. Both of those are
// real instances: `badge` an `AvatarBadge` (see `avatarBadgeSlot`), `child` an
// `Icon` standing in for the interior a caller replaces.
//
// `child` is drawn as an opaque, avatar-sized overlay rather than a third
// auto-layout child, because `avatar.dart` reads `content = child ?? initials`
// — the two are alternatives, not siblings. Filling the overlay with the
// avatar's own `backgroundColor` is what makes switching `Show child` on read
// as "instead of the initials"; a transparent holder would show both at once,
// a state the widget cannot be in.
const kAvatarInitials = 'A';

// The stand-in for the widget a caller hands `child`. A photo does not come
// through this slot — it has its own field, `imageUrl`, and only that path
// sizes its content to the diameter (`width`/`height` + `fit: .cover` on
// Flutter, `w-full h-full object-cover` on Web). `child` is rendered as handed:
// `Center(child: content)` inside the composed `OutlinedContainer` on Flutter,
// the box's only child on Web, inside an `IconTheme` of the step's icon size
// (`CoreAvatarStyle.childIconStyle` — 12 · 16 · 20 · 24 · 32 · 48, about half
// the diameter). The documented custom child is an `Icon`
// (`Avatar(child: Icon(LucideIcons.user))` in avatar.md), so the stand-in is an
// icon at that size, centred in the disc.
const kAvatarChildGlyph = 'image';

// `CoreAlignment`'s nine statics, as the `(x, y)` pairs in `-1..1` each one
// stores (`coui_core/lib/src/component/alignment.dart:19-41`).
//
// The vocabulary has to be spelled out here because the exporter emits the
// STATIC's NAME and nothing else: `avatar.fields.badgeAlignment` is
// `{"choice":"topEnd"}`, and `topEnd`'s numbers appear nowhere in the JSON. It
// is a CLOSED set — nine `static const`s on one class — so this table is total
// rather than a sample, and `alignmentOf` refuses a tenth name rather than
// guessing at it.
//
// This used to be `kAvatarBadgeAlignmentX = 1` / `kAvatarBadgeAlignmentY = -1`:
// the two numbers of `topEnd`, written next to a field that states which corner
// the badge sits in. That is the expensive shape rather than a tidy one —
// moving `defaultBadgeAlignment` to `bottomEnd` in coui_core would leave this
// canvas drawing the badge top-right forever, and no gate would disagree,
// because the field was never read. The unread-field ratchet counted it for
// exactly that reason.
const kAlignments: Record<string, { readonly x: number; readonly y: number }> = {
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

// A `{"choice": <CoreAlignment static>}` leaf as the pair the widget multiplies
// by, or a throw naming the field.
//
// Throwing looks like the dangerous arm — an exception inside a builder fails
// the entry and leaves a half-drawn component on the page. Here it is
// the safe one, because `selftest-registry-runtime` drives every builder
// against the committed `components.json`: a name this table does not know
// fails CI on the machine that added it, and never reaches a canvas. The
// alternative — falling back to a corner — is the failure that cannot be seen,
// since a badge in the wrong corner still looks like a badge.
function alignmentOf(
  leaf: { readonly choice: string },
  field: string,
): { readonly x: number; readonly y: number } {
  const pair = kAlignments[leaf.choice];
  if (pair === undefined) {
    throw new Error(
      `${field}: unknown CoreAlignment "${leaf.choice}". Add it to ` +
        '`kAlignments` in display.ts with the `(x, y)` its `static const` in ' +
        `coui_core/lib/src/component/alignment.dart carries. Known: ${Object.keys(
          kAlignments,
        ).join(', ')}.`,
    );
  }
  return pair;
}

// The same corner, said again for RESIZE.
//
// An absolutely-positioned child holds its distance from whichever edges its
// `constraints` name, and the default is `MIN`/`MIN` — the left and top ones.
// So without this the badge is in the stated corner only at the diameter it was
// authored at: widen an Avatar instance and a `topEnd` badge walks inward from
// the left edge, which is the field's statement quietly becoming false. Deriving
// the pin from the same pair as `x`/`y` is what keeps the two from disagreeing.
function alignmentConstraint(v: number): ConstraintType {
  if (v < 0) return 'MIN';
  if (v > 0) return 'MAX';
  return 'CENTER';
}

// The `badge` slot, as a real `AvatarBadge` instance placed where
// `_AvatarBadgeLayout` places it.
//
// `avatar.dart` renders `Stacks(clipBehavior: .none, children: [avatar,
// Position(top: dy, left: dx, child: badge)])` the moment `badge != null`, so
// the badge is a corner overlay outside the avatar's own centring layout —
// hence `layoutPositioning = 'ABSOLUTE'` rather than a third auto-layout child.
// The placement arithmetic is the widget's (`CoreAvatarStyle.badgeAnchorFor`,
// restated in `avatarBadgeAnchor` below): an anchor point and the point of the
// badge's own box that sits on it. The badge is the step's size
// (`avatar.sizes.defaultsBySize.<size>.badgeStyle`), the one `resolveAvatar`
// hands the `AvatarBadge` in its slot.
//
// `alignment` is `avatar.fields.badgeAlignment` — the corner itself, passed in
// as the leaf rather than pre-resolved so the call site names the field it
// reads, the way `inset` already names `badgeInset`. The pin the same pair
// produces is legal on this node because `slotNodes` builds the holder with
// `autoFrame`: Figma refuses `constraints` on an INSTANCE outright ("in
// set_constraints: This property cannot be overridden in an instance"), which
// is the whole reason `helpers.ts#pinAbsolute` wraps one in a frame first. The
// badge INSTANCE inside the holder is never written to.
//
// Two nodes for the reason `badgeIconSlot` gives: one node carries a single
// `componentPropertyReferences` map, so the BOOLEAN ("did a caller pass a
// badge") and the INSTANCE_SWAP ("which widget fills the slot") cannot both
// sit on the instance. Default OFF, matching the widget's own default — `badge`
// is null unless passed, and `AvatarGroup` instantiates `Avatar` expecting the
// plain circle.
function avatarBadgeSlot(
  page: PageNode,
  lk: VarLookup,
  comp: ComponentNode,
  refs: SlotPair[],
  avatarSize: number,
  badgeStyle: AvatarRowBadge,
  inset: number | Dim,
  alignment: { readonly choice: string },
  placement: string,
): void {
  const badge = instanceOf(page, 'AvatarBadge');
  const badgeSize = badgeStyle.size;
  // The step's size, the one `resolveAvatar` hands the badge it holds
  // (`CoreAvatarStyle.badgeStyle` in the size row). `AvatarBadge`'s dot and
  // child scale with the instance (see `buildAvatarBadge`), so resizing it is
  // the whole of "a smaller badge".
  bindSize(badge, lk, badgeSize, badgeSize);
  // The step's inner ring, where it is not the badge's own — `stroke1` at
  // the two smallest steps. Written on the instance's dot as an override.
  const own = COMPONENTS.avatar_badge.fields;
  if (dimVal(badgeStyle.borderWidth) !== dimVal(own.borderWidth) || badgeStyle.borderColor.ref !== own.borderColor.ref) {
    const dot = badge.children.find((n): n is EllipseNode => n.type === 'ELLIPSE');
    if (!dot) throw new Error('Avatar: the AvatarBadge instance has no dot to restate the ring on');
    borderData(dot, lk, colorData(badgeStyle.borderColor), badgeStyle.borderWidth);
  }
  const wrapper = slotNodes(comp, badge, 'badge', null, null, false);
  refs.push({ holder: wrapper, content: badge });
  const align = alignmentOf(alignment, 'avatar.fields.badgeAlignment');
  const at = avatarBadgeAnchor(avatarSize, dimVal(inset), align, placement);
  const side = dimVal(badgeSize);
  pinAbsolute(
    wrapper.parent as FrameNode | ComponentNode,
    wrapper,
    at.x - at.alignX * side,
    at.y - at.alignY * side,
    {
      horizontal: alignmentConstraint(align.x),
      vertical: alignmentConstraint(align.y),
    },
  );
}

// The badge a size row hands its slot (`CoreAvatarStyle.badgeStyle`).
interface AvatarRowBadge {
  readonly size: Dim;
  readonly borderWidth: Dim;
  readonly borderColor: Color;
}

// `CoreAvatarStyle.badgeAnchorFor`, restated: the export carries the
// placement's NAME, not the arithmetic, so the two formulas are spelled here
// once. `selftest-registry-runtime` reads `avatar_style.dart` and fails if
// this and the Dart ever disagree.
//
// Returns the anchor point (from the box's top-left) and the point of the
// badge's own box that sits on it, as fractions of its side.
//
//   corner  — the anchor is `inset` in from the corner, and the badge's
//             matching corner sits on it (a tile's badge, flush at inset 0).
//   outline — the anchor is on the disc's outline in the alignment's
//             direction (45° for `topEnd`), `inset` in toward the centre, and
//             the badge's centre sits on it.
//
// A pin cannot keep the outline's point across a resize — it moves by
// (1 + cos 45°) / 2 of the growth, between CENTER and MAX — so a disc keeps
// the corner's pin (`alignmentConstraint`), the nearest of the three. A
// resized disc instance drifts toward the box corner by a fraction of the
// growth; the members, drawn at their own diameters, are exact.
export function avatarBadgeAnchor(
  diameter: number,
  inset: number,
  align: { readonly x: number; readonly y: number },
  placement: string,
): { x: number; y: number; alignX: number; alignY: number } {
  const half = diameter / 2;
  if (placement === 'corner') {
    return {
      x: half + align.x * (half - inset),
      y: half + align.y * (half - inset),
      alignX: (1 + align.x) / 2,
      alignY: (1 + align.y) / 2,
    };
  }
  if (placement === 'outline') {
    const length = Math.sqrt(align.x * align.x + align.y * align.y);
    const ux = length === 0 ? 0 : align.x / length;
    const uy = length === 0 ? 0 : align.y / length;
    return { x: half + ux * (half - inset), y: half + uy * (half - inset), alignX: 0.5, alignY: 0.5 };
  }
  throw new Error(
    `avatar badgePlacement: unknown CoreAvatarBadgePlacement "${placement}". Add its geometry to ` +
      '`avatarBadgeAnchor` in display.ts, the way `CoreAvatarStyle.badgeAnchorFor` states it.',
  );
}

// The member a freshly placed instance becomes — the widget's own resting
// avatar: `CoreAvatarContract.defaultSize`, `CoreAvatarShape.defaultShape` and
// `ring: false`. None of the three is exported as a default key (see
// `kAvatarDefaultSize`), so the size and shape are named once in
// `instance-reach.ts`, beside the Badge's, and the ring is the widget's own
// `this.ring = false`.
const kAvatarLead = { Size: kAvatarDefaultSize, Shape: kAvatarDefaultShape, Ring: 'false' } as const;

// The `ring: true` band, as the three fields it is made of.
//
// Read outward from the avatar's own edge, `ringOffset` is a GAP and
// `ringWidth` is the stroke beyond it:
//
//   avatar │ gap, ringOffset wide │ ringColor, ringWidth wide
//          0                      2                          4
//
// so a rect inset by `-ringOffset` with `strokeAlign = 'OUTSIDE'` paints
// exactly `ringOffset … ringOffset + ringWidth`. OUTSIDE rather than folding
// the two into one number (a CENTER stroke on a rect inset by
// `offset + width / 2`): folding draws today's default correctly and
// drifts the moment either field moves on its own. Figma's DEFAULT is INSIDE,
// which would paint the stroke over the gap and close it.
//
// The rect's corner is the avatar's grown by the gap — `r + ringOffset`, the
// corner `resolveAvatar` hands Flutter's offset layer and the one a Web
// `box-shadow` spread of `ringOffset` draws. The OUTSIDE stroke beyond it is
// grown by Figma itself, so its outer edge lands on `r + ringOffset +
// ringWidth`, Flutter's ring layer. A disc's pill stays the pill
// (`derivedCorner` does not add to the sentinel) and stays bound. A tile's
// grown corner is written as a number, the way `focusRing` writes its band
// and ring: it is computed from the corner rather than stated on the ladder —
// `xl`'s 18 and `xl2`'s 26 are not steps at all, and `lk.radius` throws on a
// missing step, which would fail the entry and leave a half-drawn Avatar on
// the page. The cost is the one the focus ring already pays: a density or a
// surface style that moves the tile's corner on the ladder moves the box and
// not the ring around it.
//
// ─── What both platforms draw ───────────────────────────────────────────────
//
// Both draw the band above — a ring DETACHED from the avatar by the gap: Web
// as a two-layer `box-shadow` on a wrapper the size of the box, Flutter as two
// decorated layers stacked outside it (`avatar.dart`'s ring `Stacks`), each at
// the grown corner. All three fields are read on both.
//
// They agree on one more thing the canvas does not draw: the GAP is painted
// `surface` on both (the inner `box-shadow` layer on Web, the offset layer
// behind the box on Flutter), so the ring reads against a known colour rather
// than whatever the avatar sits on. No Core field states that colour — both
// resolvers name the token directly — so there is nothing here to read, and
// the gap shows the canvas through it. A field on `CoreAvatarStyle` is what
// would let this builder draw it.
function avatarRing(comp: ComponentNode, lk: VarLookup, diameter: number, corner: Dim): void {
  const f = AVATAR.fields;
  const offset = dimVal(f.ringOffset);
  const ring = figma.createRectangle();
  ring.name = 'ring';
  ring.fills = [];
  borderData(ring, lk, colorData(f.ringColor), f.ringWidth);
  ring.strokeAlign = 'OUTSIDE';
  const ringCorner = derivedCorner(dimVal(corner), offset);
  if (ringCorner === dimVal(corner)) bindRadiusN(ring, lk, corner);
  else ring.cornerRadius = ringCorner;
  ring.resize(diameter + offset * 2, diameter + offset * 2);
  // STRETCH so the inset stays the `ringOffset` it states when a designer
  // resizes an instance, instead of pinning to the left/top pair Figma defaults
  // to and drifting off the other two edges — the same argument
  // `alignmentConstraint` makes for the badge.
  pinAbsolute(comp, ring, -offset, -offset, {
    horizontal: 'STRETCH',
    vertical: 'STRETCH',
  });
}

// The `child` slot: the interior a caller hands the avatar instead of an image
// or initials. Absolute and avatar-sized rather than a flow child, and opaque
// in the avatar's own background, because the widget treats it as a
// replacement — see the note above `kAvatarChildGlyph`. Rounded at the
// member's own corner, which is what clips the glyph to the disc or the tile.
function avatarChildSlot(
  page: PageNode,
  lk: VarLookup,
  comp: ComponentNode,
  refs: SlotPair[],
  diameter: number,
  corner: Dim,
  background: ColorData | null,
  glyphColor: ColorData | null,
  // The `Child` swap default (`iconSwapDefault`), so the property's first bind
  // leaves the stand-in at its size (see `IconOpts.fromVariant`).
  fromVariant: ComponentNode | null,
  // The step's ambient icon size around the slot (`childIconStyle`).
  iconSize: number | Dim,
): void {
  // An `Icon` handed as `child` — at the ambient icon size the avatar mounts
  // around the slot, see the note above `kAvatarChildGlyph`.
  const glyph = makeIcon(kAvatarChildGlyph, lk, {
    ...glyphOpts(lk, glyphColor, iconSize, 'size'),
    fromVariant,
  });
  const holder = slotNodes(comp, glyph, 'child', null, null, false);
  refs.push({ holder, content: glyph });
  holder.primaryAxisAlignItems = 'CENTER';
  holder.counterAxisAlignItems = 'CENTER';
  bindRadiusN(holder, lk, corner);
  fillData(holder, lk, background);
  holder.resize(diameter, diameter);
  pinInFlow(holder.parent as FrameNode | ComponentNode, holder);
  holder.x = 0;
  holder.y = 0;
  // The slot is the avatar's whole box, so it keeps the box's edges when the
  // instance is resized — a swapped-in photo that stayed at its minted diameter
  // would sit in one corner of a bigger circle (#4701).
  holder.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };
}

function buildAvatar(page: PageNode, lk: VarLookup): ComponentSetNode {
  const bg = colorData(AVATAR.fields.backgroundColor);
  // Annotated rather than cast: the annotation makes `tsc` check that the JSON
  // leaf really is a `TextLeaf`, which is what lets `fontSize` be READ as the
  // absent-or-present overlay the resolver branches on. The inferred JSON type
  // has no `fontSize` key at all, so a cast would hide the day one appears.
  const fallbackText: TextLeaf = AVATAR.fields.fallbackTextStyle;
  // Colour + weight every size shares; the size's role comes from its row.
  const sharedInitials = textStyleData(fallbackText);
  const initialsColor = sharedInitials.color;
  // The diameters, roles and tile corners are the code's own table,
  // `CoreAvatarStyle.defaultsBySize` (`avatar.sizes.defaultsBySize`, xs..xl2),
  // so editing a step in Dart moves the canvas with the widget.
  const sizes = new Map(Object.entries(AVATAR.sizes.defaultsBySize));
  const shapeData = new Map<string, object>(Object.entries(AVATAR.variants.defaultsByShape));
  const shape = AVATAR.axes.other.find((o) => o.enum === 'CoreAvatarShape');
  if (!shape) {
    throw new Error(
      'Avatar: CoreAvatarShape is gone from the exported axes — the canvas has a ' +
        'Shape axis that nothing in the contract now backs.',
    );
  }
  const members = enumerateAxisAssignments([
    ...axisSpecsOf(AVATAR.axes),
    { axis: 'Shape' as const, values: shape.members },
    { axis: 'Ring' as const, values: kBoolAxis },
  ]);
  // The `child` stand-in is drawn from the `Child` default, so the bind leaves
  // it at its size (see `IconOpts.fromVariant`).
  const childSwap = iconSwapDefault(page, 'Avatar', 'Child', iconSlotDefaultId(page));
  const mount = mountSet(
    page,
    'Avatar',
    members.map((m) => m.name),
  );
  const initials: TextNode[] = [];
  const childRefs: SlotPair[] = [];
  const badgeRefs: SlotPair[] = [];
  for (const m of members) {
    const values = m.values;
    const row = sizeRowFor(sizes, values['Size'], AVATAR.axes.size.members);
    const shapeRow = shapeData.get(values['Shape']);
    if (!shapeRow) throw new Error(`Avatar: no shape row for "${m.name}"`);
    const diameter = dimVal(row.diameter);
    // The corner — the shape's row over the size's, the order `resolveAvatar`
    // merges them in on both platforms (`defaultsBySize[size]`, then
    // `defaultsByShape[shape]`). A disc's row states the pill; a tile's row
    // states nothing, so the size row's own corner stands — a quarter of the
    // diameter, 6 … 24. The canvas states no override, so the source the
    // resolvers read first (`borderRadius` on the theme or the instance) has
    // nothing to contribute here.
    const corner = optField<{ topLeft: Dim }>(shapeRow, 'borderRadius')?.topLeft ?? row.borderRadius.topLeft;
    const initialsStyle = mergeTextStyleData(sharedInitials, textStyleData(row.fallbackTextStyle));
    const c = mount.getOrCreate(m.name);
    c.layoutMode = 'HORIZONTAL';
    c.primaryAxisAlignItems = 'CENTER';
    c.counterAxisAlignItems = 'CENTER';
    c.primaryAxisSizingMode = 'FIXED';
    c.counterAxisSizingMode = 'FIXED';
    // `_AvatarBadgeLayout` puts the corner badge in a `Stacks(clipBehavior:
    // .none)` OUTSIDE the avatar's own `clipBehavior: .antiAlias` box
    // (`avatar.dart`), and this one frame stands in for both. The box's clip
    // is not lost by choosing `.none` here: the `child` slot's holder is
    // avatar-sized with the member's own corner bound, so the glyph inside it
    // is clipped by that holder. The `Ring=true` band needs the same flag for
    // the same reason — see the Clipping section.
    c.clipsContent = false;
    bindRadiusN(c, lk, corner);
    fillData(c, lk, bg);
    // The diameter is the same in every typography mode, so the initials are
    // too: the xl · xl2 roles (headline) step down on Mobile and Tablet, and a
    // label bound to them would shrink inside a box that does not.
    const t = makeLabel(kAvatarInitials, lk, { ...textLabelOpts(lk, initialsStyle), fixedSize: true });
    t.name = 'initials';
    c.appendChild(t);
    t.layoutSizingHorizontal = 'HUG';
    t.layoutSizingVertical = 'HUG';
    initials.push(t);
    bindSize(c, lk, diameter, diameter);
    // Before both slots, so the band sits BEHIND them: the widget's ring is
    // drawn around the avatar's own box, and `_AvatarBadgeLayout` stacks the
    // badge on top of that whole thing. Nothing is occluded either way — with
    // `strokeAlign = 'OUTSIDE'` the band is entirely outside the avatar's
    // bounds and both slots are entirely inside them — but the order is the
    // widget's rather than an accident of where the call went.
    if (values['Ring'] === 'true') avatarRing(c, lk, diameter, corner);
    // `child` before `badge`: the badge is a corner overlay on whatever the
    // interior turns out to be, so it has to stay in front of it.
    avatarChildSlot(page, lk, c, childRefs, diameter, corner, bg, initialsColor, childSwap.variant, row.childIconStyle.size);
    // The placement — the shape's row over the field's default, the order the
    // resolvers read it in.
    const placement =
      optField<{ choice: string }>(shapeRow, 'badgePlacement')?.choice ?? AVATAR.fields.badgePlacement.choice;
    avatarBadgeSlot(
      page,
      lk,
      c,
      badgeRefs,
      diameter,
      row.badgeStyle,
      AVATAR.fields.badgeInset,
      AVATAR.fields.badgeAlignment,
      placement,
    );
  }
  const set = mount.finish();
  // Owner is the set, and it only exists now — see `SlotPair`.
  const initialsProp = defineProp(set, 'Initials', 'TEXT', kAvatarInitials);
  for (const t of initials) bindTextProp(t, initialsProp);
  bindSlotPairs(
    set,
    childRefs,
    defineProp(set, 'Show child', 'BOOLEAN', false),
    defineProp(set, 'Child', 'INSTANCE_SWAP', childSwap.id),
  );
  bindSlotPairs(
    set,
    badgeRefs,
    defineProp(set, 'Show badge', 'BOOLEAN', false),
    defineProp(set, 'Badge', 'INSTANCE_SWAP', mainComponentId(page, 'AvatarBadge')),
  );
  // The axis grid (Size rows × Shape blocks × Ring columns), with the code's
  // resting avatar in the corner Figma hands a new instance. The grid's 16px
  // gap clears the `Ring=true` band, which reaches 4px past each member.
  defaultSetLayout(set, kAvatarLead);
  return set;
}

// ─── Alert ───────────────────────────────────────────────────────────────────

// Lucide name per variant, copied from the widget's own switch — the plugin
// draws the icon the component draws, not a lookalike character. Colors,
// radius, padding, gap, typography all come from coui_core ALERT.
//
// The glyph is the default of the `leading` slot. Both widgets draw it only
// while the caller passes no `leading`, and a `leading` takes its place
// outright in either layout — so the glyph node carries the `Leading`
// INSTANCE_SWAP, and a designer swapping in a `Badge` is choosing exactly what
// the code then draws. There is no `Show leading`: a null `leading` does not
// empty the seat, it draws the tone glyph, so the seat is never absent.
//
// Keyed by the AXIS member spelling — `CoreAlertVariant`'s own names, which the
// enumerator produces and the data bucket (`variants.defaultsByVariant`) shares.
const _kAlertIcon: Record<string, string> = {
  neutral: 'info',
  info: 'info',
  success: 'circle-check',
  warning: 'triangle-alert',
  destructive: 'circle-alert',
};

const kAlertTitleText = '확인이 필요해요';
const kAlertDescriptionText = '결제 수단을 다시 확인해 주세요.';

// Preview-only width, applied through `resize()` — `CoreAlertStyle` states no
// width, so binding one would assert a decision the design system never made.
// The same reason `kCardWidth` is a plain number. Both layouts share it: the
// inline strip is as wide as its parent in an app, and the one-line title
// truncates against whatever width that is.
//
// There is deliberately no height beside it. The widget is the composed
// container around a `Row` with the content column in an `Expanded` — nothing
// in that tree fixes a height, so the alert is as tall as the taller of its
// glyph, its column and its buttons, and never shorter than the layout row's
// `minHeight` (the stacked floor; the inline row states none). This builder
// used to write `comp.resize(340, 80)`, and 80 is not a number any field
// states: once the description wrapped onto a second line the row outgrew 80,
// and the frame's default `clipsContent` is what cut that line off rather
// than letting it spill where someone would have seen it.
const kAlertWidth = 340;

// The one line the inline title is held to. Not a design value, so the Style
// fields (and therefore components.json) do not carry it: it is a behaviour of
// the layout, stated once in Core as `CoreAlertLayout.titleMaxLines`, which
// both resolvers read (`ResolvedAlert.titleMaxLines` on Flutter, `truncate` on
// Web). A strip that let the title wrap would stop being a strip.
//
// The export cannot hand a Dart getter to this file, so the number is restated
// here — the one deliberate exception — and `selftest-registry-runtime.ts`
// reads `alert_layout.dart` and fails if the two ever differ.
export const kAlertInlineTitleLines = 1;

// The dismiss affordance's glyph. `alert.dart:218-232` renders
// `Button(onPressed: onDismiss, variant: .plain, buttonStyle: closeButtonStyle,
// child: Icon(LucideIcons.x, iconStyle: closeButtonStyle.leadingIconStyle))`
// whenever a caller passes `onDismiss`.
const kAlertDismissGlyph = 'x';

// The `plain` Button the dismiss affordance is an instance of, by axis rather
// than by full name — `bestVariantName` scores what it is given, so form.ts is
// free to keep growing Button's axis vocabulary. Same shape the panel-family
// close affordances in overlay.ts use.
const kAlertDismissButtonAxes = {
  Variant: 'plain',
  Size: 'md',
};

// The Button this builder wants for the action slot, named by its first two
// axes only. Kept as a constant because it is a cross-file coupling: the full
// variant-name grammar belongs to form.ts's `buildButton`, not to this file,
// and that file is free to add axes (it already carries
// `Selected=`/`Hover=`/`Disabled=` behind these two).
const kAlertActionButtonVariant = 'Variant=secondary, Size=sm';

// The `Button` variant name the alert's `action` slot is drawn as.
//
// `alert.dart` renders `action!` inside the panel row and forwards its chrome
// through the `actionButtonStyle` nested slot, so this is a composition the
// parent genuinely has — a hand-drawn rounded rectangle here would keep
// painting the old button forever, because the content-hash skip leaves a
// parent whose own recipe did not change alone.
//
// Matched on a PREFIX rather than the whole name: asking `instanceOf` for the
// exact string throws the moment form.ts adds an axis (which it has), and that
// throw would fail the whole Alert entry — half an Alert would be left on the
// page over a name another file owns. A prefix finds
// `Variant=secondary, Size=sm, <every other axis at its first value>`, i.e. the
// idle secondary button, and degrades to the set's first variant only if the axis
// ORDER changes too. A genuinely missing `Button` still throws `instanceOf`'s
// actionable "add needs: ['Button']" error.
//
// Returned as a name rather than as the instance, because the INSTANCE_SWAP
// default has to point at the SAME variant the builder drew — two independent
// lookups would be two chances to disagree.
function alertActionButtonVariant(page: PageNode): string | undefined {
  const found = findComponentByName(page, 'Button');
  const set = found && found.type === 'COMPONENT_SET' ? found : undefined;
  const match = set?.children.find(
    (c) =>
      c.name === kAlertActionButtonVariant ||
      c.name.startsWith(`${kAlertActionButtonVariant}, `),
  );
  return match ? match.name : undefined;
}

// The dismiss affordance, as the `Button(variant: .plain)` + `x` glyph pair the
// widget builds.
//
// It is drawn for the same reason Toast's and Drawer's are: the affordance is
// chrome the widget paints. A CALLBACK rather than a slot turns it on, so there
// is nothing to swap — it is either drawn or not, which is one BOOLEAN
// (`Show dismiss`, bound in `buildAlert`). Leaving the node out would cost the
// one thing `alert.fields.dismissIdleOpacity` exists to say: `alert_style.dart`
// tints this glyph `variantStyle.iconColor.withOpacity(dismissIdleOpacity)`
// (0.7 idle, fading to the full icon colour on hover), so with no glyph on the
// canvas that 70% was a value nothing could read.
//
// The glyph is overlaid absolutely rather than appended into the instance:
// Figma rejects appended children on an instance, so the button's own (emptied)
// label slot stays where it is and the ✕ is centred on top of it.
function alertDismiss(
  page: PageNode,
  lk: VarLookup,
  iconColor: ColorData | null,
  size: number | Dim,
): FrameNode {
  const host = autoFrame('dismiss', 'HORIZONTAL');
  const button = instanceOf(page, 'Button', bestVariantName(page, 'Button', kAlertDismissButtonAxes));
  button.name = 'dismiss button';
  host.appendChild(button);
  // The forwarded `closeButtonStyle` — `alert.dart` hands the composed `Button`
  // the whole slot, and the instance was taking `Button`'s own row inset and
  // corner instead (Alert states 4 and 4).
  applyForwardedButtonStyle(button, lk, ALERT.fields.closeButtonStyle);
  // The button's own demo label. Cleared through its TEXT property, never by
  // reaching for the node: a node bound to a property is driven by that
  // property, and writing around one is how a composed child loses the override
  // its own panel is supposed to make.
  const props: ComponentProperties | undefined = button.componentProperties;
  if (props) {
    for (const key of Object.keys(props)) {
      if (props[key].type !== 'TEXT') continue;
      const patch: { [name: string]: string } = {};
      patch[key] = '';
      button.setProperties(patch);
      break;
    }
  }
  const side = dimVal(size);
  const glyph = makeIcon(kAlertDismissGlyph, lk, glyphOpts(lk, iconColor, size, 'size'));
  // CENTER on both axes: the x/y above are a centring computed once, and only
  // CENTER keeps them centred when the host is resized (#4701).
  pinAbsolute(host, glyph, (button.width - side) / 2, (button.height - side) / 2, { horizontal: 'CENTER', vertical: 'CENTER' });
  return host;
}

// The set is `Variant × Layout` — the contract's tone enum crossed with
// `CoreAlertLayout` (`stacked` · `inline`), enumerated by the SAME function G10
// measures with (T-14). Ten members, the code default first:
// `Variant=neutral, Layout=stacked`. Gaining `Layout` renamed every existing
// `Variant=x` member to `Variant=x, Layout=stacked` (src/renames.ts), so each
// keeps its key and every Alert a designer already placed.
//
// Each member draws its LAYOUT ROW (`variants.defaultsByLayout`) the way both
// resolvers read it: padding, the floor, the glyph-to-content gap, the glyph's
// size and the title's role and colour all change with the layout; the face,
// the corner and the glyph's colour stay the variant row's. The inline member
// is the widget's one-line strip — the title held to one line and cut with an
// ellipsis, no description at all (both widgets skip it, so the node is not
// drawn rather than drawn hidden), and no floor.
function buildAlert(page: PageNode, lk: VarLookup): ComponentSetNode {
  const strokeN = dimVal(ALERT.fields.borderWidth) || 1;
  const descStyle = textStyleData(ALERT.fields.descriptionStyle);
  const variantData = new Map(Object.entries(ALERT.variants.defaultsByVariant));
  const layoutData = new Map(Object.entries(ALERT.variants.defaultsByLayout));
  const layoutAxis = ALERT.axes.other.find((o) => o.enum === 'CoreAlertLayout');
  if (!layoutAxis) {
    throw new Error(
      'Alert: CoreAlertLayout is gone from the exported axes — the canvas has a ' +
        'Layout axis that nothing in the contract now backs. Restore the enum, or ' +
        'retire the axis deliberately (renames.ts) rather than letting this builder ' +
        'fold two members into one.',
    );
  }
  const members = enumerateAxisAssignments([
    ...axisSpecsOf(ALERT.axes),
    { axis: 'Layout', values: layoutAxis.members },
  ]);
  // The slot's swap default, read BEFORE mounting so the glyph is drawn from
  // the variant the property's first bind keeps (`IconOpts.fromVariant`).
  const leadingSwap = iconSwapDefault(page, 'Alert', 'Leading', iconSlotDefaultId(page));
  const mount = mountSet(page, 'Alert', members.map((m) => m.name));
  const titles: TextNode[] = [];
  const descriptions: TextNode[] = [];
  const leadings: InstanceNode[] = [];
  const dismissHosts: FrameNode[] = [];
  const actionRefs: SlotPair[] = [];
  for (const m of members) {
    const name = m.values['Variant'];
    const layout = m.values['Layout'];
    const v = variantData.get(name);
    if (!v) throw new Error(`Alert: \`defaultsByVariant\` has no \`${name}\` row ("${m.name}")`);
    const row = layoutData.get(layout);
    if (!row) throw new Error(`Alert: \`defaultsByLayout\` has no \`${layout}\` row ("${m.name}")`);
    const glyph = _kAlertIcon[name];
    if (!glyph) throw new Error(`Alert: no glyph for variant "${name}" — copy it from the widget's switch`);
    const stacked = layout === 'stacked';
    const comp = mount.getOrCreate(m.name);
    comp.layoutMode = 'HORIZONTAL';
    comp.primaryAxisAlignItems = 'MIN';
    // CENTER: the glyph, the text block, the action and the dismiss mark share
    // the row's middle in both widgets (`Row`'s default cross-axis alignment on
    // Flutter, `items-center` on Web).
    comp.counterAxisAlignItems = 'CENTER';
    // The composed container draws its decoration and never clips its child.
    // See the Clipping section: this is the flag that hid the description's
    // second line.
    comp.clipsContent = false;
    bindPad(comp, lk, row.padding);
    // The floor the layout row states (`CoreAlertStyle.minHeight`), bound
    // rather than left to whatever the content happens to measure: the height
    // was incidental, so a designer shortening the content would have
    // collapsed a box the widget holds open. The inline row states 0 — no
    // floor, the strip is as tall as its content — and both resolvers then
    // emit no minimum at all, so neither does this.
    const floor = dimVal(row.minHeight);
    if (floor > 0) {
      comp.minHeight = floor;
      comp.setBoundVariable('minHeight', lk.spaceLadder(floor));
    }
    comp.setBoundVariable('itemSpacing', lk.space(dimVal(row.iconContentGapStyle.size)));
    bindRadiusN(comp, lk, ALERT.fields.borderRadius.topLeft);
    // A content surface on both platforms: the Web twin marks itself
    // `webSurfaceMarkerFor(.content)`, and Flutter's alert is the composed
    // `OutlinedContainer`, which reads `theme.surfaceFor(role)`. It casts nothing
    // at rest, so it takes the cast a style contributes on both
    // (`kControlShadowRestMarker`; the composed container's `controlShadow`).
    applySurfaceMaterial(comp, lk, colorData(v.backgroundColor), 'content', {
      radius: ALERT.fields.borderRadius.topLeft,
    });
    addControlShadow(comp, lk);
    // No border of its own: the redesign fills opaquely and states none
    // (`borderWidth` is stroke0). The Style slot survives so a caller can opt
    // one back in. A box that draws no boundary takes the one a style
    // contributes, on both platforms — the composed container's
    // `controlBorder`, and the Web twin's `kControlBorderMarker`.
    addControlBorder(comp, lk);
    // The `leading` slot's default: the tone glyph at the layout's size, in the
    // variant's icon colour. iconStyle.size traces to CoreIconSize (via
    // CoreSize), not CoreFontSize — glyphOpts(..., 'size') binds the correct
    // scale (#3754 axis fix).
    const icon = makeIcon(glyph, lk, {
      ...glyphOpts(lk, colorData(v.iconColor), row.iconStyle.size, 'size'),
      fromVariant: leadingSwap.variant,
    });
    icon.name = 'leading';
    comp.appendChild(icon);
    leadings.push(icon);

    // `title` / `description` are `String` / `String?` widget fields rather
    // than `W?` slots, and a TEXT property is exactly what a string field maps
    // to — the copy is editable per instance without detaching.
    // `action` takes both statements: the BOOLEAN reaches the widget's `null`,
    // the INSTANCE_SWAP says the slot holds any widget rather than this
    // particular Button forever. Both are declared after `finish()` — see
    // `SlotPair`.
    const actionVariant = alertActionButtonVariant(page);

    const col = autoFrame('content', 'VERTICAL');
    // The title's role is the LAYOUT's: `labelLarge` 600 stacked, `bodySmall`
    // inline. Its colour is the variant row's `titleColor` — the tone's
    // `on-{tone}-container`, the glyph's — and, where a row states none
    // (`neutral`), the layout's: `onSurface` stacked, `onSurfaceVariant` inline.
    const title = makeLabel(
      kAlertTitleText,
      lk,
      typographyColorOpts(
        lk,
        textStyleData(row.titleStyle),
        colorData(('titleColor' in v ? v.titleColor : undefined) ?? row.titleColor),
      ),
    );
    title.name = 'title';
    col.appendChild(title);
    titles.push(title);
    let desc: TextNode | null = null;
    if (stacked) {
      // The gap between the two lines. Stated only where there are two lines:
      // inline draws no description, so it has nothing for the gap to separate.
      col.setBoundVariable('itemSpacing', lk.space(dimVal(ALERT.fields.titleBottomMargin)));
      desc = makeLabel(kAlertDescriptionText, lk, typographyColorOpts(lk, descStyle, colorData(v.descriptionColor)));
      desc.name = 'description';
      col.appendChild(desc);
      descriptions.push(desc);
    }
    comp.appendChild(col);

    // Drawn OFF, like every other `W?` slot in this file. `action` is
    // `Widget?` and the widget renders it only `if (action != null)`, so
    // the shown state was misstating the widget's default — and it was also what
    // squeezed the column: a secondary/sm Button hugs to ~69px, which with the
    // icon and two 12px gaps left the description ~199px and wrapped it.
    const actionInstance = instanceOf(page, 'Button', actionVariant);
    actionRefs.push({
      holder: slotNodes(comp, actionInstance, 'action', null, null, false),
      content: actionInstance,
    });

    // Last in the row, after `action` — the widget's own order.
    const dismiss = alertDismiss(
      page,
      lk,
      // Stated outright, not the tone times an alpha. A colour multiplied
      // by an opacity resolves against whatever panel is behind it, so
      // its contrast is unknowable — which is why the opacity field is
      // deprecated and this one exists.
      colorData(ALERT.fields.dismissColor),
      ALERT.fields.closeButtonStyle.leadingIconStyle.size,
    );
    comp.appendChild(dismiss);
    // Hidden at rest, the same value `Show dismiss` defaults to below:
    // `onDismiss` is null unless a caller passes one, and both widgets then
    // draw neither the button nor the `iconContentGapStyle` gap in front of it
    // (`if (onDismiss != null) ...[Gap, Button]`). The row's `itemSpacing` IS
    // that gap, and auto-layout skips a hidden child, so hiding the host drops
    // both.
    dismiss.visible = false;
    dismissHosts.push(dismiss);

    // Width only. `comp.resize(w, comp.height)` writes back the height the frame
    // already hugged to, so nothing is pinned — the shape `buildCard` uses. The
    // two sizing modes are then restated because `resize` sets both axes to
    // FIXED, and the counter axis has to go back to hugging or the row cannot
    // grow with its content.
    comp.resize(kAlertWidth, comp.height);
    comp.primaryAxisSizingMode = 'FIXED';
    comp.counterAxisSizingMode = 'AUTO';
    col.layoutSizingHorizontal = 'FILL';
    col.layoutSizingVertical = 'HUG';
    // `textAutoResize` BEFORE `layoutSizingHorizontal`, which is the order
    // Card's body/footer and Dialog's body already use. A text node arrives
    // auto-sizing both axes; telling it to fill first and only then to grow
    // downward measures the column against one unwrapped line of copy.
    title.textAutoResize = 'HEIGHT';
    title.layoutSizingHorizontal = 'FILL';
    if (!stacked) {
      // One line, cut with an ellipsis — Flutter's `maxLines: 1` +
      // `TextOverflow.ellipsis`, Web's `truncate`. Growing downward is what the
      // line limit holds: `HEIGHT` truncates only under `maxLines`.
      title.textTruncation = 'ENDING';
      title.maxLines = kAlertInlineTitleLines;
    }
    if (desc) {
      desc.textAutoResize = 'HEIGHT';
      desc.layoutSizingHorizontal = 'FILL';
    }
    // Restated after the children settled: every statement above reflows the
    // row, and hugging is the only thing keeping the content inside the frame.
    comp.counterAxisSizingMode = 'AUTO';
  }
  const set = mount.finish();
  const titleProp = defineProp(set, 'Title', 'TEXT', kAlertTitleText);
  const descProp = defineProp(set, 'Description', 'TEXT', kAlertDescriptionText);
  for (const t of titles) bindTextProp(t, titleProp);
  for (const d of descriptions) bindTextProp(d, descProp);
  // `description` is `String?`, and both widgets drop the line AND the
  // `titleBottomMargin` gap above it in one `if (description != null)` branch.
  // The content column's `itemSpacing` is that gap and auto-layout skips a
  // hidden child, so the BOOLEAN on the TEXT node collapses both — one node
  // carries `characters` and `visible`, the shape Banner's description has.
  // On by default: it is the pose the `Description` field describes, and the
  // line every placed Alert already shows — Banner's rule for its own
  // `Show description`, not the code's `null`. Defined by name, so a set that
  // already carries a `Show description` BOOLEAN keeps its key and every
  // override on it. Bound on the stacked members only: an inline member has no
  // description node, because neither widget draws one there.
  const descShownProp = defineProp(set, 'Show description', 'BOOLEAN', true);
  for (const d of descriptions) bindVisibleProp(d, descShownProp);
  // `onDismiss` is a callback, not a `W?` slot: there is nothing to swap, so
  // the affordance is one BOOLEAN. Off by default because the callback is —
  // see the hidden host above. Banner's `Show dismiss`, over the same kind of
  // callback, rests on instead ("the pose the field describes"), so the two
  // sets follow different rules here.
  const dismissShownProp = defineProp(set, 'Show dismiss', 'BOOLEAN', false);
  for (const h of dismissHosts) bindVisibleProp(h, dismissShownProp);
  // `leading` is `W?` and replaces the glyph, so it is ONE property: the
  // INSTANCE_SWAP on the glyph node. A designer swaps in a `Badge` (the v2
  // status strip's lead) or any other component; resetting it brings the tone
  // glyph back, which is exactly what a null `leading` draws.
  const leadingProp = defineProp(set, 'Leading', 'INSTANCE_SWAP', leadingSwap.id);
  for (const icon of leadings) bindSwapProp(icon, leadingProp);
  // `showIcon` — the glyph slot and the gap after it, on or off together: both
  // widgets drop them in one `if (showIcon)` branch, whether the slot holds the
  // tone glyph or a swapped-in `leading`. The row's `itemSpacing` IS that gap
  // and auto-layout skips a hidden child, so hiding the slot node drops both.
  // Its default is the contract's (`CoreAlertContract.defaultShowIcon`), read
  // from the export rather than restated here.
  const iconShownProp = defineProp(set, 'Show icon', 'BOOLEAN', ALERT.behaviour.showIcon);
  for (const icon of leadings) bindVisibleProp(icon, iconShownProp);
  bindSlotPairs(
    set,
    actionRefs,
    defineProp(set, 'Show action', 'BOOLEAN', false),
    defineProp(
      set,
      'Action',
      'INSTANCE_SWAP',
      mainComponentId(page, 'Button', alertActionButtonVariant(page)),
    ),
  );
  vStackSetLocal(set);
  return set;
}

// Alert uses a vertical stack that hugs both axes.
function vStackSetLocal(set: ComponentSetNode): void {
  set.layoutMode = 'VERTICAL';
  set.primaryAxisSizingMode = 'AUTO';
  set.counterAxisSizingMode = 'AUTO';
  set.itemSpacing = 16;
  set.paddingLeft = 24;
  set.paddingRight = 24;
  set.paddingTop = 24;
  set.paddingBottom = 24;
}

// ─── Progress ────────────────────────────────────────────────────────────────

// Data-driven from coui_core: PROGRESS.fields (borderRadius / backgroundColor —
// the neutral track every tone runs over — and the three cells' text styles and
// gaps), PROGRESS.variants.defaultsByTone (each tone's fill) and
// PROGRESS.sizes.defaultsBySize (the bar's `minHeight` per step).
//
// Size × Tone, every combination: `CoreProgressSize` and `CoreProgressTone`
// both come from the exported `axes.other`, so a step or a tone added to the
// enum lands on the canvas without touching this file. The track's width (240)
// and the demo fill's (144, 60% of it) have no Style field — the bar takes the
// parent's width and the fill is `maxWidth * value` — and stay literal,
// preview-only sizing. `duration` / `indeterminateDuration` are animation
// timing, not chrome, and aren't drawn.
//
// The three `W?` cells — `label` and `valueLabel` on one row above the bar,
// `caption` below it — are drawn the way both widgets lay them out, and off at
// rest, because both widgets draw the bar alone when every cell is null. Each
// carries a TEXT property for its copy (swapping a cell would need a `Text`
// component in the REGISTRY, which the owner decided against) and a `Show …`
// BOOLEAN for its `null`.
//
// The gap below the row and the gap above the caption are drawn as padding on
// the CELLS rather than as spacing between the column's children, because
// Figma binds a layer's visibility to one BOOLEAN and the row is present when
// EITHER of two cells is. Each label cell carries `labelGapStyle` under it, so
// the row is as deep as its text plus the gap whichever cell shows; with both
// hidden the row hugs nothing and collapses to nothing (a hug with every child
// hidden does), and the column is the bar alone — the widgets' own branch.
// The caption cell carries `captionGapStyle` above it and leaves with it.
//
// `Segmented` is `segments` — `null` the continuous bar, a count a row of
// cells, the steps passed in the tone's fill and the rest in the track colour,
// `segmentSpacing` apart (Flutter `Row(spacing:)` of `Expanded` cells, Web a
// `flex` row with `column-gap`). It is an axis, not a property, because the two
// members draw different structures: one track that clips a fill, or cells.
// `false` is the bar at rest, as `null` is the widgets' default.
//
// How many steps there are and how many are passed is the bar's VALUE, the
// way the continuous fill's 60% is: `segments` and `value` are behaviour
// arguments, not chrome. So a segmented member draws a demo — "STEP 1 / 2",
// the onboarding bar the stepped form was asked for — and the designer sets
// the rest: `Show segment 3` … `Show segment 6` add cells (the first two
// always draw; a one-step bar is either empty or full and has nothing to
// step through), and a further step is marked passed by switching that cell's
// fill to the tone's colour on the instance. A cell's equal share of the row
// is `FILL`, the widgets' `Expanded` / `flex-1`, so cells added or removed
// re-divide the width the way the code does.
//
// `RadialProgress` shares `progress.dart` with `Progress` but is a SIBLING
// class, not a child: `Progress.build` never constructs one, and the ring has
// its own contract (`CoreRadialProgressContract`), its own Style, and its own
// REGISTRY entry + builder (`primitives-data.ts#buildRadialProgress`). The bar
// composing the ring would be a component the code has no path to.
const kProgressLabelText = '업로드 중';
const kProgressValueLabelText = '60%';
const kProgressCaptionText = '3개 중 2개 완료';
// The widest reading the value cell reserves room for (`defaultValueLabelReserve`).
const kProgressValueLabelReserve = '100%';
// The member a freshly placed instance becomes — the widget's resting bar
// (`kProgressDefaultSize` / `kProgressDefaultTone`, instance-reach.ts), and
// continuous because `segments` is `null` unless a caller names a count.
const kProgressLead = {
  Size: kProgressDefaultSize,
  Tone: kProgressDefaultTone,
  Segmented: 'false',
} as const;
// The cells a segmented member draws, the ones shown at rest, and the ones
// drawn passed at rest — "STEP 1 / 2". Cells past `kProgressSegmentsShown`
// carry a `Show segment N` BOOLEAN; the rest of the count is the designer's.
const kProgressSegmentCells = 6;
const kProgressSegmentsShown = 2;
const kProgressSegmentsPassed = 1;

function buildProgress(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = PROGRESS.fields;
  const sizeData = new Map(Object.entries(PROGRESS.sizes.defaultsBySize));
  const toneData = new Map(Object.entries(PROGRESS.variants.defaultsByTone));
  const size = PROGRESS.axes.other.find((o) => o.enum === 'CoreProgressSize');
  const tone = PROGRESS.axes.other.find((o) => o.enum === 'CoreProgressTone');
  if (!size || !tone) {
    throw new Error(
      'Progress: CoreProgressSize / CoreProgressTone is gone from the exported axes — ' +
        'the canvas has a Size / Tone axis that nothing in the contract now backs.',
    );
  }
  const members = enumerateAxisAssignments([
    { axis: 'Size' as const, values: size.members },
    { axis: 'Tone' as const, values: tone.members },
    { axis: 'Segmented' as const, values: ['false', 'true'] },
  ]);
  const labelStyle = textStyleData(f.labelStyle);
  const valueLabelStyle = textStyleData(f.valueLabelStyle);
  const captionStyle = textStyleData(f.captionStyle);
  const labelGap = dimVal(f.labelGapStyle.size);
  const captionGap = dimVal(f.captionGapStyle.size);
  const segmentSpacing = dimVal(f.segmentSpacing);
  // #4034 (C2) — this component used to be a single loose COMPONENT rendering
  // the `md` tier, and reading all six rows makes it a SET. `adoptLooseAs`
  // renames that existing node into the combination it ACTUALLY rendered — the
  // `md` bar, in the fill every bar had before tones existed, which is
  // `primary` — and feeds it through the normal recycle path, so its id/`key`
  // and every instance of it in the consuming files survive the promotion.
  // Without it a fresh set is minted beside the old node: two things named
  // `Progress`, and every existing instance still pointing at the one that no
  // longer updates.
  const mount = mountSet(
    page,
    'Progress',
    members.map((m) => m.name),
    {
      adoptLooseAs: composeVariantName([
        ['Size', 'md'],
        ['Tone', 'primary'],
        ['Segmented', 'false'],
      ]),
    },
  );
  const labels: TextNode[] = [];
  const valueLabels: TextNode[] = [];
  const captions: TextNode[] = [];
  const labelCells: FrameNode[] = [];
  const valueLabelCells: FrameNode[] = [];
  const captionCells: FrameNode[] = [];
  // The cells past the ones shown at rest, by ordinal, for their BOOLEANs.
  const extraSegments = new Map<number, SceneNode[]>();
  for (const m of members) {
    const values = m.values;
    const sz = sizeRowFor(sizeData, values['Size'], size.members);
    const toneRow = toneData.get(values['Tone']);
    if (!toneRow) throw new Error(`Progress: no tone row for "${m.name}"`);
    const c = mount.getOrCreate(m.name);
    // The column both widgets draw once a cell is present — Flutter's
    // `Column(crossAxisAlignment: .stretch)`, Web's `flex flex-col w-full` —
    // and, with every cell off, a column holding the bar alone. It paints
    // nothing and clips nothing (`Column` takes no clip); the track below
    // clips its own fill.
    c.layoutMode = 'VERTICAL';
    c.itemSpacing = 0;
    c.clipsContent = false;
    // g7-preview-only: demo bar width — `progress.dart`'s track gives itself a `height` only and takes its width from the parent's constraints, so nothing states one and the canvas must choose.
    lockWidth(c, 240);

    // label row — `label` on the left (Flutter `Expanded`, Web `flex-1`) and
    // `valueLabel` hugging on the right, centred on the cross axis (`Row`'s
    // default, Web `items-center`). MAX on the main axis is the widgets'
    // `Spacer` / empty `flex-1` cell: with no label the value still sits on
    // the right.
    const row = autoFrame('label row', 'HORIZONTAL');
    row.primaryAxisAlignItems = 'MAX';
    row.counterAxisAlignItems = 'CENTER';
    c.appendChild(row);
    row.layoutSizingHorizontal = 'FILL';
    row.layoutSizingVertical = 'HUG';

    const labelCell = autoFrame('label', 'VERTICAL');
    bindSpaceField(labelCell, 'paddingBottom', lk, labelGap);
    row.appendChild(labelCell);
    labelCell.layoutSizingHorizontal = 'FILL';
    // The style's own colour (`onSurface`) and its role with the 600 weight
    // over it — a departure from `labelMedium`, so the node keeps its own
    // bindings rather than the role's text style (design-tokens).
    const label = makeLabel(kProgressLabelText, lk, textLabelOpts(lk, labelStyle));
    label.name = 'label';
    labelCell.appendChild(label);
    // `textAutoResize` before `layoutSizingHorizontal` — see Alert.
    label.textAutoResize = 'HEIGHT';
    label.layoutSizingHorizontal = 'FILL';
    labelCell.visible = false;
    labels.push(label);
    labelCells.push(labelCell);

    const valueLabelCell = autoFrame('valueLabel', 'VERTICAL');
    bindSpaceField(valueLabelCell, 'paddingBottom', lk, labelGap);
    row.appendChild(valueLabelCell);
    const valueLabel = makeLabel(kProgressValueLabelText, lk, textLabelOpts(lk, valueLabelStyle));
    valueLabel.name = 'valueLabel';
    valueLabelCell.appendChild(valueLabel);
    // The cell is as wide as the widest reading ('100%') and the figure sits at
    // its end — both widgets reserve that width, so the bar does not shift as
    // the value ticks 9% → 10% → 100%.
    const reserve = makeLabel(kProgressValueLabelReserve, lk, textLabelOpts(lk, valueLabelStyle));
    valueLabelCell.appendChild(reserve);
    valueLabelCell.minWidth = Math.ceil(reserve.width);
    reserve.remove();
    valueLabelCell.counterAxisAlignItems = 'MAX';
    valueLabelCell.visible = false;
    valueLabels.push(valueLabel);
    valueLabelCells.push(valueLabelCell);

    const trackHeight = dimVal(sz.minHeight);
    const trackStep = lk.sizeOrNull(trackHeight);
    if (values['Segmented'] === 'true') {
      // The row of cells — full width, `segmentSpacing` between cells, as
      // tall as the track. Each cell is the track's height and corner, in the
      // tone's fill for a step passed and the track colour for one to come.
      const segments = autoFrame('segments', 'HORIZONTAL');
      bindSpaceField(segments, 'itemSpacing', lk, segmentSpacing);
      c.appendChild(segments);
      segments.layoutSizingHorizontal = 'FILL';
      segments.layoutSizingVertical = 'HUG';
      for (let ordinal = 1; ordinal <= kProgressSegmentCells; ordinal++) {
        const cell = figma.createRectangle();
        cell.name = `segment ${ordinal}`;
        cell.resize(c.width / kProgressSegmentCells, trackHeight);
        if (trackStep) cell.setBoundVariable('height', trackStep);
        bindRadiusN(cell, lk, f.borderRadius.topLeft);
        fillData(
          cell,
          lk,
          colorData(
            ordinal <= kProgressSegmentsPassed ? toneRow.color : f.backgroundColor,
          ),
        );
        segments.appendChild(cell);
        cell.layoutSizingHorizontal = 'FILL';
        cell.layoutSizingVertical = 'FIXED';
        if (ordinal > kProgressSegmentsShown) {
          cell.visible = false;
          const extras = extraSegments.get(ordinal) ?? [];
          extras.push(cell);
          extraSegments.set(ordinal, extras);
        }
      }
    } else {
      // The track — the style's own `backgroundColor`, a neutral surface
      // (`surfaceContainerHigh`) on every tone, not the fill colour faded. Both
      // resolvers read `merged.backgroundColor` first, and the default states
      // one, so what the style says is what lands. A caller that states
      // `backgroundAlpha` instead gets the old fade in code; the default does
      // not, so the canvas has nothing to draw for it.
      const track = figma.createFrame();
      track.name = 'track';
      track.resize(c.width, trackHeight);
      if (trackStep) track.setBoundVariable('height', trackStep);
      bindRadiusN(track, lk, f.borderRadius.topLeft);
      // The track clips its indicator — the widget renders the track
      // `Container` with `clipBehavior: .antiAlias`. See the Clipping section
      // for why it is written even though it agrees with Figma's default.
      track.clipsContent = true;
      fillData(track, lk, colorData(f.backgroundColor));
      const fill = figma.createRectangle();
      fill.name = 'indicator';
      // g7-preview-only: demo fill width, 60% of the 240 track — the indicator's width is `constraints.maxWidth * value`, and `value` is a behaviour argument on the widget, not chrome on `CoreProgressStyle`.
      // Only the height is a token (the bar's `minHeight`). The width stays a
      // literal (#5606): a width bound to `size/144` cannot be overridden on an
      // instance, so every placed bar read 60% whatever its `Value label` said —
      // resizing the indicator is the one way a consumer can state the value.
      fill.resize(144, dimVal(sz.minHeight));
      const fillHeightStep = lk.sizeOrNull(dimVal(sz.minHeight));
      if (fillHeightStep) fill.setBoundVariable('height', fillHeightStep);
      bindRadiusN(fill, lk, f.borderRadius.topLeft);
      // The tone's own row — `merged.color ?? defaultsByTone[tone].color` in
      // both resolvers, and the default style states no `color`, so the row is
      // what lands.
      fillData(fill, lk, colorData(toneRow.color));
      track.appendChild(fill);
      fill.x = 0;
      fill.y = 0;
      // SCALE, not the default MIN: the indicator's width is
      // `constraints.maxWidth * value` (`progress.dart`), a PROPORTION of the
      // track. Pinned at MIN, a track the consumer widens keeps a 144px bar — the
      // same instance then reads as a smaller percentage than it is, and nothing
      // on the canvas says so. STRETCH down the short axis, where the bar is the
      // track's full height.
      fill.constraints = { horizontal: 'SCALE', vertical: 'STRETCH' };
      c.appendChild(track);
      track.layoutSizingHorizontal = 'FILL';
      track.layoutSizingVertical = 'FIXED';
    }

    // caption — below the bar, the width of the column.
    const captionCell = autoFrame('caption', 'VERTICAL');
    bindSpaceField(captionCell, 'paddingTop', lk, captionGap);
    c.appendChild(captionCell);
    captionCell.layoutSizingHorizontal = 'FILL';
    const caption = makeLabel(kProgressCaptionText, lk, textLabelOpts(lk, captionStyle));
    caption.name = 'caption';
    captionCell.appendChild(caption);
    caption.textAutoResize = 'HEIGHT';
    caption.layoutSizingHorizontal = 'FILL';
    captionCell.visible = false;
    captions.push(caption);
    captionCells.push(captionCell);
  }
  const set = mount.finish();
  // The set is the owner and it exists only now — see `SlotPair`. Declared
  // once and bound on every member; the property names fold to the contract's
  // slot names (`label` · `valueLabel` · `caption`).
  const labelProp = defineProp(set, 'Label', 'TEXT', kProgressLabelText);
  for (const t of labels) bindTextProp(t, labelProp);
  const valueLabelProp = defineProp(set, 'Value label', 'TEXT', kProgressValueLabelText);
  for (const t of valueLabels) bindTextProp(t, valueLabelProp);
  const captionProp = defineProp(set, 'Caption', 'TEXT', kProgressCaptionText);
  for (const t of captions) bindTextProp(t, captionProp);
  // Off by default: every cell is `W?` and null unless a caller passes one.
  const showLabelProp = defineProp(set, 'Show label', 'BOOLEAN', false);
  for (const n of labelCells) bindVisibleProp(n, showLabelProp);
  const showValueProp = defineProp(set, 'Show value', 'BOOLEAN', false);
  for (const n of valueLabelCells) bindVisibleProp(n, showValueProp);
  const showCaptionProp = defineProp(set, 'Show caption', 'BOOLEAN', false);
  for (const n of captionCells) bindVisibleProp(n, showCaptionProp);
  // Off by default: the demo is "STEP 1 / 2", the first two cells.
  for (const [ordinal, cells] of extraSegments) {
    const prop = defineProp(set, `Show segment ${ordinal}`, 'BOOLEAN', false);
    for (const cell of cells) bindVisibleProp(cell, prop);
  }
  defaultSetLayout(set, kProgressLead);
  return set;
}

// ─── Tooltip ─────────────────────────────────────────────────────────────────

// Data-driven from coui_core: TOOLTIP.fields (panelBackgroundColor /
// panelPadding / panelBorderRadius / labelStyle / tailWidth / tailHeight /
// placementOffset).
//
// Both contract slots are here. `tooltipChild` (`W?` — the panel's content) is
// the label, so it carries a TEXT property; swapping it would need a `Text`
// component in the REGISTRY and the owner decided against adding one. `child`
// is the trigger the panel is anchored TO — it lives in the consuming design,
// which is why it is drawn OFF by default, but it is still a real slot and gets
// the pair every `W?` gets: a BOOLEAN reaching the widget's `null` and an
// INSTANCE_SWAP saying any component can be the trigger.
//
// The trigger sits below the bubble at `placementOffset`, the field that names
// exactly that distance, so turning it on shows the anchoring the tail already
// points at rather than a second floating object.
//
// `Hover` is composed by `tooltip.dart` and deliberately NOT instantiated
// here. It WRAPS the trigger (`child: widget.child`) and Figma rejects
// appending to an instance, so it could not wrap anything; and the call passes
// no `effect`, so it resolves to `CoreHoverEffect.defaultEffect` = `none` —
// its whole contribution at this call site is hover TIMING (`waitDuration` /
// `showDuration` / `minDuration`), which has no static representation
// (`primitives-behaviour.ts` says the same of those three fields on the
// `Hover` component itself).
//
// `none` is not "an effect we chose not to draw": it is the arm of
// `_applyEffect` that returns the child unchanged, under a `MouseRegion` that
// paints nothing. So `Hover` here is the identity function for pixels — the
// same "owns no fill and no border" shape that keeps `Clickable` drawn rather
// than composed at `buildCard`, only more so, since `Clickable` at least has a
// ring and a disabled opacity to contribute and this has neither.
//
// What forcing it would actually put on the canvas, which is the part worth
// recording: `Hover`'s own builder gives every non-stacked variant a `slotBox`
// — the slot stand-in, in place of the child it cannot hold. An
// instance of `Effect=none` therefore arrives carrying that grey box, and
// because the real trigger cannot be moved inside an instance, the tooltip
// would show a placeholder that is not the trigger while the `child`
// INSTANCE_SWAP below went on pointing at a node outside it. That is a wrong
// structure rather than a missing one, which is the worse of the two.
const kTooltipText = '링크 복사';

// The trigger placeholder. `info` is the glyph a tooltip is most often hung
// on. `CoreTooltipStyle` describes the panel, never the widget the panel is
// anchored to, but that does not leave the glyph's size open: the widget renders
// `child` as handed (`Hover(child: widget.child)` on Flutter, the trigger
// `<div>`'s only child on Web), with no size and no `IconTheme` around it, so an
// `Icon` passed there draws at the app root's ambient icon size. Its colour is
// left to `labelColor`'s shared `on-surface` fallback: the trigger sits on the
// page, not on the panel, so no tooltip field states its colour.
const kTooltipTriggerGlyph = 'info';
const kTooltipTriggerSize = ICON.constants.ambientSize;

// Re-points every fill inside a `createNodeFromSvg` frame at `cd`, and clears
// the frame's own background. The SVG arrives with a literal fill (Figma has to
// resolve *something* on import) which would otherwise stay black regardless of
// theme. `icon-nodes.ts#repaintGlyph` does this for Lucide glyphs but is not
// exported, and the tail below is not an icon.
function paintSvgFills(frame: FrameNode, lk: VarLookup, cd: ColorData | null): void {
  frame.fills = [];
  for (const node of frame.findAll(() => true)) {
    if ('fills' in node) fillData(node, lk, cd);
  }
}

// The trigger-pointing tail — drawn, not implied.
//
// `tooltip.dart` wraps the bubble in `Stacks(clipBehavior: .none, children:
// [bubble, Position.fill(child: _TooltipTail(…))])` whenever `tailWidth > 0 &&
// tailHeight > 0`, and both defaults are non-zero
// (`CoreTooltipStyle.defaultTailWidth` = `CoreSpace.space12`,
// `defaultTailHeight` = `CoreSpace.space6`) — so every tooltip the code renders
// has one. Leaving it off drew a bubble the widget never produces.
//
// Geometry is `_TailPainter`'s `.top` branch, which is the widget's default
// `position` (`CoreTooltipPosition.top` — bubble above the trigger, tip
// pointing down): `(0,0) → (w,0) → (w/2,h)`, base flush with the bubble's
// bottom edge. `_TooltipTail` then aligns it bottom-centre and translates it
// by `+protrusion`, i.e. the base sits ON the edge and the triangle hangs
// below — which is what the absolute `y = c.height` below reproduces. The
// bubble does not clip (`resetNode` leaves `clipsContent` false), matching
// `clipBehavior: .none`.
//
// A real vector rather than a rotated rectangle, for the reason ChatBubble's
// tail states: a rectangle would draw a shape the component does not have.
// The bubble edge the tail sits on is the OPPOSITE of the placement side —
// a bubble above the trigger points down from its bottom. Mirrors
// `tooltip.dart`'s `_TailPosition` / `_TailPainter`, which already state all
// four; only this side was behind, drawing one tail pointing down whatever
// the position said.
//
// `base` is the edge flush against the bubble and `protrusion` is how far the
// tip sticks out, so the two swap axes between the vertical and horizontal
// placements — the triangle is not rotated, it is a different triangle.
function tooltipTailSvg(
  position: string,
  base: number,
  protrusion: number,
): { w: number; h: number; path: string } {
  const vertical = position === 'top' || position === 'bottom';
  const w = vertical ? base : protrusion;
  const h = vertical ? protrusion : base;
  const path = {
    top: `M0 0 L${w} 0 L${w / 2} ${h} Z`,
    bottom: `M${w / 2} 0 L${w} ${h} L0 ${h} Z`,
    left: `M0 0 L${w} ${h / 2} L0 ${h} Z`,
    right: `M${w} 0 L${w} ${h} L0 ${h / 2} Z`,
  }[position];
  if (path == null) throw new Error(`Tooltip: no tail for position "${position}"`);
  return { w, h, path };
}

function addTooltipTail(
  c: ComponentNode,
  lk: VarLookup,
  bg: ColorData | null,
  position: string,
): void {
  const base = dimVal(TOOLTIP.fields.tailWidth);
  const protrusion = dimVal(TOOLTIP.fields.tailHeight);
  // A `0` on either axis removes the tail — Core's own words for both fields,
  // and what both widgets do: Flutter paints it only when both are positive,
  // the Web twin's clip-path box collapses. Drawn anyway, it was a zero-extent
  // SVG pinned to the bubble's edge — a node the widget does not have, built
  // from a document Figma may refuse.
  if (!(base > 0 && protrusion > 0)) return;
  const { w, h, path } = tooltipTailSvg(position, base, protrusion);
  const svg =
    `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" ` +
    `viewBox="0 0 ${w} ${h}">` +
    `<path d="${path}" fill="#000000"/></svg>`;
  const tail = figma.createNodeFromSvg(svg);
  tail.name = 'tail';
  paintSvgFills(tail, lk, bg);
  // The bubble's share of the fill — see `buildTooltipMember`.
  bindSurfaceShare(tail, lk, 'functional');
  c.appendChild(tail);
  pinInFlow(c, tail);
  // Flush against the facing edge, centred on the other axis.
  if (position === 'top') {
    tail.x = (c.width - w) / 2;
    tail.y = c.height;
  } else if (position === 'bottom') {
    tail.x = (c.width - w) / 2;
    tail.y = -h;
  } else if (position === 'left') {
    tail.x = c.width;
    tail.y = (c.height - h) / 2;
  } else {
    tail.x = -w;
    tail.y = (c.height - h) / 2;
  }
}

// Four members, one per placement. `tooltip.dart` has stated all four since
// it was written — the tail moves to the edge facing the trigger and changes
// shape with it — but this side minted ONE component with the tail always
// pointing down, so three of the four placements had no drawing at all.
//
// The members come from the exported contract rather than a literal, so the
// canvas cannot hold a placement the enum does not have.
function buildTooltip(page: PageNode, lk: VarLookup): ComponentSetNode {
  const positionAxis = TOOLTIP.axes.other.find(
    (o) => o.enum === 'CoreTooltipPosition',
  );
  if (!positionAxis) {
    throw new Error(
      'Tooltip: CoreTooltipPosition is gone from the exported axes — the ' +
        'canvas has a Position axis that nothing in the contract now backs.',
    );
  }
  const combos = enumerateAxisCombos([
    { axis: 'Position' as const, values: positionAxis.members },
  ]);
  // The trigger stand-in is drawn from the `Child` default, so the bind leaves
  // it at its own size (see `IconOpts.fromVariant`).
  const childSwapDefault = iconSwapDefault(page, 'Tooltip', 'Child', iconSlotDefaultId(page));
  const mount = mountSet(page, 'Tooltip', combos);
  const labels: TextNode[] = [];
  const childHolders: FrameNode[] = [];
  const triggers: InstanceNode[] = [];
  for (const comboName of combos) {
    const position = parseVariantKey(comboName)['Position'] ?? 'top';
    const built = buildTooltipMember(
      mount.getOrCreate(comboName),
      lk,
      position,
      childSwapDefault.variant,
    );
    labels.push(built.label);
    childHolders.push(built.childHolder);
    triggers.push(built.trigger);
  }
  // Properties belong to the SET, and a fresh component has no set parent
  // yet — asked inside the loop it answers with itself, and the binding
  // lands on a variant instead. So the whole property pass waits for
  // `finish()`; `defineProp` reuses the id after the first call, which is
  // what lets every variant's node bind to the one property.
  const set = mount.finish();
  const labelProp = defineProp(set, 'TooltipChild', 'TEXT', kTooltipText);
  for (const t of labels) bindTextProp(t, labelProp);
  const childShow = defineProp(set, 'Show child', 'BOOLEAN', false);
  const childSwap = defineProp(set, 'Child', 'INSTANCE_SWAP', childSwapDefault.id);
  for (const holder of childHolders) bindVisibleProp(holder, childShow);
  for (const trigger of triggers) bindSwapProp(trigger, childSwap);
  return set;
}

function buildTooltipMember(
  c: ComponentNode,
  lk: VarLookup,
  position: string,
  triggerFrom: ComponentNode | null,
): { label: TextNode; childHolder: FrameNode; trigger: InstanceNode } {
  const pad = TOOLTIP.fields.panelPadding;
  c.layoutMode = 'HORIZONTAL';
  c.primaryAxisSizingMode = 'AUTO';
  c.counterAxisSizingMode = 'AUTO';
  c.primaryAxisAlignItems = 'CENTER';
  c.counterAxisAlignItems = 'CENTER';
  // Both of this component's extra layers sit fully below the bubble — the tail
  // at `y = height`, the trigger at `y = height + placementOffset` — and the
  // widget wraps them in `Stacks(clipBehavior: .none)` (`tooltip.dart:213`).
  // Left at Figma's default the tail was cut off entirely on a fresh page; see
  // the Clipping section.
  c.clipsContent = false;
  bindPad(c, lk, pad);
  bindRadiusN(c, lk, TOOLTIP.fields.panelBorderRadius.topLeft);
  const panelBackground = colorData(TOOLTIP.fields.panelBackgroundColor);
  // A floating surface on both platforms (`tooltip_style.dart` reads
  // `theme.surfaceFor(.functional)`; the Web twin marks itself
  // `webSurfaceMarkerFor(.functional)`). The bubble is a reversed-fill surface
  // and draws no border under any style — it takes none of the one a style
  // contributes (no `addControlBorder`, no `kControlBorderMarker`), so there is
  // no zero-weight stroke on the node either. The tail is its own node and takes
  // the bubble's share of the fill and nothing else: Flutter paints it in the
  // colour the share is folded into, and Web's tail inherits the bubble's
  // computed fill. The frost stays the bubble box's.
  applySurfaceMaterial(c, lk, panelBackground, 'functional', {
    radius: TOOLTIP.fields.panelBorderRadius.topLeft,
  });
  const t = makeLabel(kTooltipText, lk, textLabelOpts(lk, textStyleData(TOOLTIP.fields.labelStyle)));
  t.name = 'tooltipChild';
  c.appendChild(t);
  t.layoutSizingHorizontal = 'HUG';
  t.layoutSizingVertical = 'HUG';
  // After the label: the tail is placed against the bubble's hugged bounds,
  // and those are only final once the content is in.
  addTooltipTail(c, lk, panelBackground, position);

  const trigger = makeIcon(kTooltipTriggerGlyph, lk, {
    ...glyphOpts(lk, null, kTooltipTriggerSize, 'size'),
    fromVariant: triggerFrom,
  });
  // The two props are bound after `finish()` — see `buildTooltip`. Passing
  // null here leaves the nodes ready for that pass.
  const childHolder = slotNodes(c, trigger, 'child', null, null, false);
  pinInFlow(c, childHolder);
  // The trigger sits on the far side of the tail, on whichever axis the
  // placement uses — a bubble to the LEFT of its trigger puts the trigger to
  // its right, not below it.
  const offset = dimVal(TOOLTIP.fields.placementOffset);
  if (position === 'top') {
    childHolder.x = (c.width - childHolder.width) / 2;
    childHolder.y = c.height + offset;
  } else if (position === 'bottom') {
    childHolder.x = (c.width - childHolder.width) / 2;
    childHolder.y = -childHolder.height - offset;
  } else if (position === 'left') {
    childHolder.x = c.width + offset;
    childHolder.y = (c.height - childHolder.height) / 2;
  } else {
    childHolder.x = -childHolder.width - offset;
    childHolder.y = (c.height - childHolder.height) / 2;
  }
  return { label: t, childHolder, trigger };
}

// 'Separator' removed (#3744) — no `Separator` class in coui_core; `Divider`
// (layout.ts, #3743) is the real, contract-covering replacement. The old
// on-page node (if any) is retired via src/renames.ts RETIRED, opt-in only.

// ─── Skeleton ────────────────────────────────────────────────────────────────

// Data-driven from coui_core: SKELETON.variants.defaultsByVariant
// (background + borderRadius, per variant — rectangular/circular/text all
// share the same surface-container background) + SKELETON.fields (lines /
// lineSpacing / lineHeight / lastLineWidth) for the "text" variant's line
// stack (`lastLineWidth` is a ratio of the full line width — 200 * 0.6 = 120).
// `lineHeight` is a size token bound on each line's height, `lineSpacing` a
// space token bound on the stack's gap. `defaultsByVariant` carries no
// width/height per variant — the rectangular/circular demo box sizes
// (160x40 / 40x40) and the text lines' full-line width (200) have no
// Style-default source and stay literal. `duration` is the pulse's timing and
// Figma renders one frame, so it has no counterpart, and `toOpacity` is the far
// end of that pulse.
//
// `fromOpacity` DOES have a counterpart. A skeleton has no opaque state to
// paint: both widgets pulse between the fill with its own alpha multiplied by
// `fromOpacity` and by `toOpacity` (`CoreColor.scaleAlpha` — Web's
// `--pulse-from` / `--pulse-to`, Flutter's `pulseFromColor` / `pulseToColor`),
// starting at the `fromOpacity` end — so that end is the first frame the widget
// paints, and the `toOpacity` end is one instant at the top of a repeating
// pulse. The resting end is both the honest still and the value the data names.
// It reaches the canvas as the LAYER's opacity, bound to the `opacity/<n>`
// variable the field names: the `tint` layer for rectangular and circular, each
// line rectangle for text. `scaleAlpha` folds the strength into the colour and
// `fillData` is told which token it is (its `strength` argument), so the layer
// that carries the alpha also carries the binding. It is never the component's
// own `opacity` — node opacity would fade a `text` variant's line stack as a
// group rather than tint the surface.
//
// No composition slots on `CoreSkeletonStyle` — the component IS the loading
// state, and its callers hand it a size, not widgets.
//
// One axis — `Variant` (3 members), enumerated by the SAME function G10
// measures with (T-14). There is no `Enabled` axis: whether a skeleton is
// drawn is the caller's condition (`if (loading) Skeleton(...)`), so the
// contract carries no on/off toggle for a member to pose.
function buildSkeleton(page: PageNode, lk: VarLookup): ComponentSetNode {
  const variantData = new Map(Object.entries(SKELETON.variants.defaultsByVariant));
  const combos = enumerateAxisCombos(axisSpecsOf(SKELETON.axes));
  const mount = mountSet(page, 'Skeleton', combos);
  const lineCount = dimVal(SKELETON.fields.lines);
  const lineHeight = SKELETON.fields.lineHeight;
  const lastLineWidth = 200 * dimVal(SKELETON.fields.lastLineWidth);
  const pulseFrom = SKELETON.fields.fromOpacity;
  for (const comboName of combos) {
    const combo = parseVariantKey(comboName);
    const name = combo['Variant'];
    const v = variantData.get(name);
    if (!v) throw new Error(`Skeleton: no data for combo "${comboName}"`);
    const comp = mount.getOrCreate(comboName);
    const bg = scaleAlpha(colorData(v.backgroundColor), dimVal(pulseFrom));
    if (name === 'text') {
      comp.layoutMode = 'VERTICAL';
      comp.setBoundVariable('itemSpacing', lk.space(dimVal(SKELETON.fields.lineSpacing)));
      // `resize()` sets both sizing modes to FIXED, so it comes BEFORE them: asked
      // for after `primaryAxisSizingMode = 'AUTO'`, it pins the stack at one line's
      // height and the lines below the first overflow their own frame.
      comp.resize(200, dimVal(lineHeight));
      comp.counterAxisSizingMode = 'FIXED';
      comp.primaryAxisSizingMode = 'AUTO';
      for (let i = 0; i < lineCount; i++) {
        const ln = figma.createRectangle();
        bindAxisSize(ln, lk, {
          width: i === lineCount - 1 ? lastLineWidth : 200,
          height: lineHeight,
          bind: 'height',
        });
        bindRadiusN(ln, lk, v.borderRadius.topLeft);
        fillData(ln, lk, bg, pulseFrom);
        // A placeholder draws no border, so each line takes the one a style
        // contributes on both platforms (`resolveInjectedBorder`;
        // `kControlBorderMarker` on every line).
        addControlBorder(ln, lk);
        comp.appendChild(ln);
        if (i !== lineCount - 1) ln.layoutSizingHorizontal = 'FILL';
      }
    } else if (name === 'circular') {
      // g7-preview-only: demo circle diameter — `Skeleton.width`/`.height` are caller arguments (`Skeleton(width: 200, height: 20)`), so the box size is a use-site input and `defaultsByVariant.circular` carries radius + background only.
      bindSize(comp, lk, 40, 40);
      bindRadiusN(comp, lk, v.borderRadius.topLeft);
      fillData(comp, lk, bg, pulseFrom);
      addControlBorder(comp, lk);
    } else {
      // g7-preview-only: demo box size for the rectangular variant — same caller-supplied `width`/`height` as the circular arm above; the only sizing the data states is `lineHeight`, which belongs to the `text` arm.
      bindSize(comp, lk, 160, 40);
      bindRadiusN(comp, lk, v.borderRadius.topLeft);
      fillData(comp, lk, bg, pulseFrom);
      addControlBorder(comp, lk);
    }
  }
  const set = mount.finish();
  // g7-preview-only: variant-gallery frame width — where Skeleton's three variants wrap on the canvas, not a skeleton's own width (that is a caller argument).
  wrapSet(set, 480);
  return set;
}

// ═══════════════════════════════════════════════════════════════════════════
// EXTENDED BUILDERS — additional Display components are appended below.
// ═══════════════════════════════════════════════════════════════════════════

// ─── DisclosureBadge ─────────────────────────────────────────────────────────

// Data-driven from coui_core: DISCLOSURE_BADGE.fields (borderWidth /
// borderRadius / padding / labelStyle / markerSize / markerRadius /
// markerSpacing), the per-kind colours in `variants.defaultsByKind`, and the
// per-kind SHAPE in `axes.other[CoreDisclosureKind].fields`.
//
// Shape mirrors the widget: a bordered box whose content is padded by
// `borderWidth + padding` (`EdgeInsets.all(borderWidth) + padding`), holding
// `Row(spacing: markerSpacing, [marker?, label])`. The border sits INSIDE the
// box on both platforms, so the frame counts its stroke in layout rather than
// adding it to the padding by hand.
//
// A kind's outline pattern and marker are not style fields. They live on
// `CoreDisclosureKind` itself so no theme can erase the difference between the
// three kinds (WCAG 1.4.1 — the shape half survives a colour-blind reader and a
// black-and-white printout). The canvas reads those two facts off the export
// instead of restating them here: a second copy of "private is dashed" in this
// file would be exactly the drift the enum exists to prevent.
//
// The dash rhythm is the one value this component uses that is not a field of
// its own style: Flutter's dashed painter reads `CoreDashedBorder` directly (the
// doc on `ResolvedDisclosureBadge.dashLength` says why it is not themeable). It
// is read back off the export by its provenance — every leaf the exporter wrote
// from `CoreDashedBorder.dashLength` carries that `via` — so the numbers still
// come from Core and a change there reaches this canvas.
//
// `label` is a required `String` on the contract, not a `W` slot, so it takes
// no component property: each kind shows the copy the docs pair it with, and a
// single set-wide TEXT property would print one kind's words on all three.
// `labelMaxLines` / `labelOverflow` are line-breaking behaviour a one-line
// label never exercises.
const DISCLOSURE_BADGE = COMPONENTS.disclosure_badge;

/** The docs' own copy for each kind (`disclosure_badge_*_example.dart`). */
const kDisclosureBadgeLabels: Readonly<Record<string, string>> = {
  open: '근거 공개',
  commitment: '킥오프 시 제공',
  private: '비공개 · NDA',
};

function buildDisclosureBadge(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = DISCLOSURE_BADGE.fields;
  const kind = DISCLOSURE_BADGE.axes.other.find((o) => o.enum === 'CoreDisclosureKind');
  if (!kind) {
    throw new Error(
      'DisclosureBadge: CoreDisclosureKind is gone from the exported axes — the ' +
        'canvas has a Kind axis that nothing in the contract now backs.',
    );
  }
  const facts = kind.fields as Readonly<
    Record<string, { stroke?: string; hasMarker?: boolean } | undefined>
  >;
  const colours = new Map(Object.entries(DISCLOSURE_BADGE.variants.defaultsByKind));
  const dash = coreDashedBorderRhythm();
  const names = kind.members.map((m) => `Kind=${m}`);
  const mount = mountSet(page, 'DisclosureBadge', names);
  for (const member of kind.members) {
    const fact = facts[member];
    const colour = colours.get(member);
    if (!fact || fact.stroke == null || fact.hasMarker == null || !colour) {
      throw new Error(
        `DisclosureBadge: no stroke/marker facts or colours exported for kind "${member}".`,
      );
    }
    const c = mount.getOrCreate(`Kind=${member}`);
    c.layoutMode = 'HORIZONTAL';
    c.primaryAxisSizingMode = 'AUTO';
    c.counterAxisSizingMode = 'AUTO';
    c.counterAxisAlignItems = 'CENTER';
    c.fills = [];
    // `EdgeInsets.all(borderWidth) + padding`: the stroke is part of the box
    // the padding is measured from, on both platforms.
    c.strokesIncludedInLayout = true;
    bindPad(c, lk, f.padding);
    bindRadiusN(c, lk, f.borderRadius.topLeft);
    c.setBoundVariable('itemSpacing', lk.space(dimVal(f.markerSpacing)));
    borderData(c, lk, colorData(colour.borderColor), f.borderWidth);
    applyBorderStyle(c, fact.stroke, dash.on, dash.off);
    if (fact.hasMarker) {
      // `ExcludeSemantics(Container(size × size, color: foreground,
      // borderRadius: markerRadius))` — the deferral dot.
      const marker = figma.createRectangle();
      marker.name = 'marker';
      bindSize(marker, lk, f.markerSize, f.markerSize);
      bindRadiusN(marker, lk, f.markerRadius.topLeft);
      fillData(marker, lk, colorData(colour.foreground));
      c.appendChild(marker);
    }
    const label = makeLabel(
      kDisclosureBadgeLabels[member] ?? member,
      lk,
      // The style states a role and no colour, so the kind's foreground wins —
      // the resolver's `color: labelStyle.color == null ? foreground : null`.
      textLabelOpts(lk, textStyleData(f.labelStyle), colorData(colour.foreground)),
    );
    label.name = 'label';
    c.appendChild(label);
  }
  const set = mount.finish();
  vStackSet(set);
  return set;
}

// `CoreDashedBorder`'s on/off lengths, read off the export by provenance.
//
// Memoised: the walk visits the leaves of `components.json` once, and the answer
// cannot change within a run. Loud when absent, because the fallback would be
// Figma's own default dash — a pattern nobody chose.
let dashedBorderRhythm: { on: number; off: number } | null = null;
function coreDashedBorderRhythm(): { on: number; off: number } {
  if (dashedBorderRhythm) return dashedBorderRhythm;
  const on = firstLeafVia(COMPONENTS, 'CoreDashedBorder.dashLength');
  const off = firstLeafVia(COMPONENTS, 'CoreDashedBorder.dashGap');
  if (on == null || off == null) {
    throw new Error(
      'DisclosureBadge: no exported leaf carries `CoreDashedBorder.dashLength` / ' +
        '`dashGap` any more — the dashed kind has no rhythm to draw.',
    );
  }
  dashedBorderRhythm = { on, off };
  return dashedBorderRhythm;
}

function firstLeafVia(node: unknown, via: string): number | null {
  if (Array.isArray(node)) {
    for (const item of node) {
      const hit = firstLeafVia(item, via);
      if (hit != null) return hit;
    }
    return null;
  }
  if (node == null || typeof node !== 'object') return null;
  const leaf = node as { via?: unknown; v?: unknown };
  if (leaf.via === via && typeof leaf.v === 'number') return leaf.v;
  for (const value of Object.values(node as Record<string, unknown>)) {
    const hit = firstLeafVia(value, via);
    if (hit != null) return hit;
  }
  return null;
}

// ─── Tag ─────────────────────────────────────────────────────────────────────
//
// A short display-only label that files something under a category, coloured
// by one of the category hues. Data-driven from coui_core through the two
// tables both resolvers merge (`tag_style.dart`, both platforms):
//
//   TAG.sizes.defaultsBySize         the step — height (`minHeight`), padding,
//                                    corner and the label's role
//   TAG.variants.defaultsByEmphasis  what the emphasis changes on top of the
//                                    step — the bold label's weight
//
// plus TAG.fields.borderWidth, the line a subtle tag draws inside its box.
//
// ```text
// Tag  Color=… , Size=md|sm, Emphasis=subtle|bold
//   (HORIZONTAL · centred · hug over a minHeight floor · padding · corner)
//   fill    category-{c}-container (subtle) | category-{c} (bold)
//   stroke  category-{c}-outline, INSIDE (subtle only)
//   └─ label  TEXT, the step's role (+ 600 for bold)        ← `Child`
// ```
//
// ─── Where the colours come from ─────────────────────────────────────────────
//
// `CoreTagStyle.resting(color, emphasis)` picks the colours from the hue's five
// category slots at run time, so the export has no colour row to read
// (`absent` names the three colour fields). The choice is mirrored here, and
// the five slot names are the ones `CoreCategorySlot` documents:
//
//   subtle — `category-{c}-container` behind `on-category-{c}-container`, the
//            line in `category-{c}-outline`
//   bold   — `category-{c}` behind `on-category-{c}`, no line
//
// Every colour binds to its Semantic variable by name (`lk.sem`), which throws
// when the variable is missing — a hue the palette dropped fails the build
// rather than painting a stale hex.
//
// ─── Axes — Color × Size × Emphasis ──────────────────────────────────────────
//
// `Color` is `CoreCategoryColor`. It lives in `color/`, not in the tag's
// contract directory, so the exporter does not record it in `axes.other` and
// the hues are spelled here in the enum's declaration order. `Size`
// (`CoreTagSize`) and `Emphasis` (`CoreTagEmphasis`) come from `axes.other`.
// The Size values run md first: `md` is the default step, and the first value
// is the one a fresh instance picks. 9 × 2 × 2 = 36 members.
//
// No state axes: a tag has no press, hover, pressed or focus on either
// platform.
const kTagLabelText = '디자인';
// `CoreCategoryColor`, in declaration order.
const kTagHues = [
  'red',
  'orange',
  'yellow',
  'green',
  'blue',
  'purple',
  'pink',
  'brown',
  'gray',
] as const;
// `CoreTagContract.defaultColor`, `CoreTagSize.defaultSize` and
// `CoreTagEmphasis.defaultEmphasis` — named by hand because schema v3 records
// `axes.other` without a default key.
const kTagLead = { Color: 'gray', Size: 'md', Emphasis: 'subtle' } as const;

interface TagColors {
  background: ColorData;
  foreground: ColorData;
  /** `null` for bold — it states no line. */
  border: ColorData | null;
}

// `CoreTagStyle.resting(color, emphasis)`, spelled as the variable names its
// category slots carry.
function tagRestingColors(hue: string, emphasis: string): TagColors {
  switch (emphasis) {
    case 'subtle':
      return {
        background: { color: `category-${hue}-container` },
        foreground: { color: `on-category-${hue}-container` },
        border: { color: `category-${hue}-outline` },
      };
    case 'bold':
      return {
        background: { color: `category-${hue}` },
        foreground: { color: `on-category-${hue}` },
        border: null,
      };
  }
  throw new Error(
    `Tag: emphasis "${emphasis}" has no branch in tagRestingColors — ` +
      '`CoreTagStyle.resting` gained a strength this builder does not draw.',
  );
}

function buildTag(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = TAG.fields;
  const sizeData = new Map(Object.entries(TAG.sizes.defaultsBySize));
  const emphasisData = new Map(Object.entries(TAG.variants.defaultsByEmphasis));
  const size = TAG.axes.other.find((o) => o.enum === 'CoreTagSize');
  const emphasis = TAG.axes.other.find((o) => o.enum === 'CoreTagEmphasis');
  if (!size || !emphasis) {
    throw new Error(
      'Tag: CoreTagSize / CoreTagEmphasis is gone from the exported axes — the ' +
        'canvas has a Size / Emphasis axis that nothing in the contract now backs.',
    );
  }
  // The default step first — see the axes note.
  const sizeValues = [kTagLead.Size, ...size.members.filter((m) => m !== kTagLead.Size)];
  if (!size.members.includes(kTagLead.Size)) {
    throw new Error(`Tag: CoreTagSize has no "${kTagLead.Size}" step any more.`);
  }
  const members = enumerateAxisAssignments([
    { axis: 'Color' as const, values: kTagHues },
    { axis: 'Size' as const, values: sizeValues },
    { axis: 'Emphasis' as const, values: emphasis.members },
  ]);
  const mount = mountSet(
    page,
    'Tag',
    members.map((m) => m.name),
  );
  const labels: TextNode[] = [];
  for (const m of members) {
    const values = m.values;
    const s = sizeData.get(values['Size']);
    const e = emphasisData.get(values['Emphasis']);
    if (!s || !e) throw new Error(`Tag: no size / emphasis row for "${m.name}"`);
    const colors = tagRestingColors(values['Color'], values['Emphasis']);
    const corner = s.borderRadius.topLeft;
    const comp = mount.getOrCreate(m.name);

    // Content centred in a box at least `minHeight` tall — the floor both
    // resolvers state (`BoxConstraints(minHeight:)`; Web `min-height`), which
    // the label never reaches, so every step draws its own height. Padding is
    // horizontal only.
    comp.layoutMode = 'HORIZONTAL';
    comp.primaryAxisSizingMode = 'AUTO';
    comp.counterAxisSizingMode = 'AUTO';
    comp.primaryAxisAlignItems = 'CENTER';
    comp.counterAxisAlignItems = 'CENTER';
    bindPad(comp, lk, s.padding);
    const height = dimVal(s.minHeight);
    const heightStep = lk.sizeOrNull(height);
    comp.minHeight = height;
    if (heightStep) comp.setBoundVariable('minHeight', heightStep);

    // A content surface on both platforms (`tag_style.dart` reads
    // `theme.surfaceFor(.content)`; the Web twin marks itself
    // `webSurfaceMarkerFor(.content)`), and a box that states no cast, so it
    // takes the one a style contributes on both (`InjectedCast`;
    // `kControlShadowRestMarker`).
    bindRadiusN(comp, lk, corner);
    applySurfaceMaterial(comp, lk, colors.background, 'content', { radius: corner });
    // Inside the box on both platforms: the line does not add to the step's
    // height (`Border.all` inside the decoration; Web `box-sizing: border-box`).
    borderData(comp, lk, colors.border, f.borderWidth);
    if (colors.border) comp.strokeAlign = 'INSIDE';
    addControlShadow(comp, lk);

    // The step's role with the emphasis's weight over it — bold at 600.
    const labelStyle = mergeTextStyleData(
      textStyleData(s.labelStyle),
      textStyleData(optField<TextLeaf>(e, 'labelStyle')),
    );
    const t = makeLabel(kTagLabelText, lk, textLabelOpts(lk, labelStyle, colors.foreground));
    t.name = 'label';
    comp.appendChild(t);
    t.layoutSizingHorizontal = 'HUG';
    t.layoutSizingVertical = 'HUG';
    labels.push(t);
  }
  const set = mount.finish();
  const labelProp = defineProp(set, 'Child', 'TEXT', kTagLabelText);
  for (const t of labels) bindTextProp(t, labelProp);
  defaultSetLayout(set, kTagLead);
  return set;
}


// Every `W`/`W?` slot the contracts in this file declare now carries a
// property a designer can act on, and every one of those properties is BOUND
// to the node that renders the slot. A declared property nothing points at
// shows in the panel and changes nothing when edited, which is worse than an
// absent one — it looks answered.
//
// Two things in this file still are not composed, and neither is a judgment
// call about how close a drawing gets:
//
//   · Avatar → `AvatarGroup`. `AvatarGroup` declares `needs: ['Avatar']`
//     because its widget builds a row OF avatars, so `needs: ['AvatarGroup']`
//     here would be a CYCLE and `topoSortRegistry` throws on it by design.
//     The scan sees the name only because both classes live in `avatar.dart`
//     and it reads per directory — what it matched is `AvatarGroup`'s own
//     constructor, in `AvatarGroup.copyWith`.
//   · Progress → `RadialProgress`. A SIBLING class, not a child:
//     `Progress.build` never constructs one, and the ring has its own
//     contract, Style, REGISTRY entry and builder
//     (`primitives-data.ts#buildRadialProgress`). The bar composing the ring
//     would be a component the code has no path to.
//
// Tooltip → `Hover` is the third, and its reason is at `buildTooltip`: `Hover`
// wraps the trigger, Figma rejects appending to an instance, and at this call
// site its whole contribution is timing.
//
// Alert's dismiss affordance is driven by the `onDismiss` CALLBACK, not by a
// slot, so it takes no swap — but it is drawn (see `alertDismiss`), the same
// way Toast's and Drawer's are, and `Show dismiss` (off, as the callback is by
// default) says whether it is there. A callback has no Figma counterpart; the
// chrome it switches on does, and `closeButtonStyle` + `dismissIdleOpacity`
// are the fields that supply it.
//
// Two things the widgets draw that this file still does not, recorded because
// "not mentioned" and "checked and impossible" read identically otherwise:
//
//   · `FocusOutline`'s OFFSET BAND. `focus_outline.dart` draws a second
//     layer — the `offsetColor` band in the gap between the component edge
//     and the ring. Card and Badge both state the default, which is
//     transparent, so there is no colour for a node to carry: the gap shows
//     whatever the component sits on, which is what the canvas already shows.
//     Should either ever state an opaque band, it is drawable as an INSIDE
//     stroke on a rectangle inset by `-(align - borderWidth)` — the shape
//     `focus-ring.ts` uses, which paints only the gap and so does not cover
//     the component's own fill.
//   · Card's HOVER shadow, and with it a `Hover` axis. The full reasoning is
//     in the State axes note at the top of this file, next to the two axes
//     Card does have — including the three ways to draw it anyway and why each
//     is worse than the gap. The short version: `hoverElevation` exports as a
//     bare `{"choice":"medium"}`, the stack that choice names
//     (`CoreOutlinedContainerStyle.defaultMediumShadow` = `CoreShadow.md`)
//     reaches `components.json` nowhere, and `card.fields.boxShadow` is the
//     card's IDLE `layers: []`. One export unblocks it.
//
// ─── Card's two durations, and the API that was checked ──────────────────────
//
// `card.fields.chromeAnimationDuration` and `hoverShadowAnimationDuration` are
// both 200ms and both real: the first becomes `containerStyle.duration`
// (`card_style.dart:208-210`), the transition the surface animates its fill and
// border over; the second becomes `interactiveDuration`
// (`card_style.dart:287-289` → `:333`), the fade on the hover shadow above.
// Neither is drawn, and "a static canvas has no time axis" is too quick an
// answer to leave alone, so here is what was actually looked for.
//
// Figma holds a number of seconds in exactly one place: `Reaction.transition
// .duration` — a PROTOTYPE transition between two frames or two variants
// (`plugin-api.d.ts:8949` shows that field being edited). It is not a canvas
// property. Three separate things stop it here:
//
//   · The write path is async and these builders are not. `manifest.json` sets
//     `documentAccess: "dynamic-page"`, which makes `reactions` READ-ONLY
//     (`plugin-api.d.ts:8906`); the only writer left is `setReactionsAsync`
//     (`:9062`), which returns a `Promise`, while every `RegistryEntry.build`
//     is synchronous and returns its node. Firing it un-awaited is the shape
//     that has already cost this project eleven components — a rejection
//     nobody is holding lands after the entry's own catch has returned, so
//     nothing reports it and the write is simply missing.
//   · A transition needs a DESTINATION, and one of the two has none.
//     `hoverShadowAnimationDuration` animates the hover shadow, and this set
//     has no Hover axis for the reason recorded just above — `medium`'s layers
//     are not in the JSON, so the hovered side would be pixel-identical to the
//     idle one. The duration would be timing a change between two identical
//     pictures. (`chromeAnimationDuration` does NOT share this: the Focused
//     axis is a genuine destination. For that one it is only the write path.)
//   · Nothing could read it back. `fidelity.ts` compares canvas NODES against
//     `components.json`; a prototype reaction is not a node property, so the
//     one gate that catches "carries the right value, paints the wrong
//     picture" would be blind to whether the number ever arrived.
//
// Variable binding was the other candidate, because the exporter does hand
// these two a variable ref (`Primitives/duration/200`). It cannot land either:
// `VariableBindableNodeField` (`plugin-api.d.ts:6697-6724`) is 25 fields wide
// and every one of them is geometry, stroke, opacity, visibility or characters
// — there is no time-valued bindable field on any node, in any of the five
// bindable unions. The variable exists in the collection and no property will
// take it.
//
// So these two stay unread, which is the same verdict `absence.ts` records for
// the `duration` KIND ("not representable — the canvas is one frame") and the
// same one this file already reaches for Progress's `duration` /
// `indeterminateDuration`, Skeleton's `duration` and Tooltip's three hover
// timings. Named here rather than left silent so the next person spends this
// paragraph instead of the afternoon.
//
// No component in this file has a `List<W>` slot; Figma has no repeated-slot
// property, so one would be skipped anyway (a designer adds/removes children).
export const DISPLAY_BUILDERS: RegistryEntry[] = [
  {
    section: 'Display',
    name: 'Card',
    build: buildCard,
    // `OutlinedContainer` is the card's surface; the slot stand-in and `Badge`
    // are the placeholders its three widget slots swap FROM.
    needs: ['OutlinedContainer', kSlotStandInComponent, 'Badge'],
  },
  { section: 'Display', name: 'Badge', sizing: { width: 'fixed', height: 'fixed', when: 'Style=dot', why: 'badge.dart dot: BoxConstraints.tightFor(dotSize) — 점은 정의상 고정; label · count 는 minHeight 를 바닥으로 한 hug' }, build: buildBadge, needs: ['Icon'] },
  { section: 'Display', name: 'Avatar', sizing: { width: 'fixed', height: 'fixed', why: 'avatar.dart SizedBox(width: resolvedSize, height: resolvedSize) — Size 토큰의 정사각형' }, build: buildAvatar, needs: ['AvatarBadge', 'Icon'] },
  { section: 'Display', name: 'Alert', build: buildAlert, needs: ['Icon', 'Button'] },
  { section: 'Display', name: 'Progress', build: buildProgress },
  { section: 'Display', name: 'Tooltip', build: buildTooltip, needs: ['Icon'] },
  { section: 'Display', name: 'Skeleton', build: buildSkeleton },
  { section: 'Display', name: 'DisclosureBadge', build: buildDisclosureBadge },
  { section: 'Display', name: 'Tag', build: buildTag },
  // EXTENDED ENTRIES — append new Display registry entries above this line.
];
