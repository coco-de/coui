/// <reference types="@figma/plugin-typings" />

import {
  type ColorData,
  RegistryEntry,
  SetMount,
  VarLookup,
  addControlShadow,
  applyForwardedCollapsibleStyle,
  applyPanelCompChrome,
  applySurfaceMaterial,
  autoFrame,
  bestVariantName,
  bindPad,
  bindRadiusN,
  bindSize,
  bindStrokeAxis,
  bindSpaceField,
  bindSwapProp,
  bindTextProp,
  bindVisibleProp,
  borderData,
  defineProp,
  exposeAll,
  fillData,
  focusOutlineRingColor,
  focusRing,
  type FocusRingNodes,
  glyphOpts,
  glyphPaint,
  iconMainIdAt,
  instanceOf,
  kCollapsibleBodyName,
  kCollapsibleHeaderName,
  lockWidth,
  mainComponentIdOf as mainIdOf,
  makeIcon,
  makeLabel,
  mint,
  mintPanelComp,
  mountSet,
  panel,
  pinAbsolute,
  propertyOwner,
  setInstanceBoolNamed,
  hideInstanceLabel,
  setInstanceTextNamed,
  setSlotIcon,
  textLabelOpts,
  typographyColorOpts,
  hostedDivider,
  kSlotStandInComponent,
  labelColor,
  slotStandIn,
  slotStandInDefault,
  SlotStandInShape,
} from '../helpers';
import { bindShowFocusRing, defineShowFocusRing, stateAxis } from '../state-axis';
import { Color, Dim, colorData, dimVal, optField, textStyleData } from '../compat/v1';
import { BUTTON, COMPONENTS } from '../data';
import {
  axisSpecsOf,
  composeVariantName,
  enumerateAxisAssignments,
  restingValueOf,
} from '../axis-combos';

const ACCORDION = COMPONENTS.accordion;
const COLLAPSIBLE = COMPONENTS.collapsible;
const DISCLOSURE = COMPONENTS.disclosure;
const DIVIDER = COMPONENTS.divider;
const FOOTER = COMPONENTS.footer;
const HERO = COMPONENTS.hero;
const JOIN = COMPONENTS.join;
const TABLE = COMPONENTS.table;
const TREE = COMPONENTS.tree;
const RESIZABLE = COMPONENTS.resizable;
const PAGE_HEADER = COMPONENTS.page_header;
const PANEL_HEADER = COMPONENTS.panel_header;
const BOTTOM_ACTION_BAR = COMPONENTS.bottom_action_bar;
const SWIPE_ACTIONS = COMPONENTS.swipe_actions;

// ─── Boolean state axes ──────────────────────────────────────────────────────
//
// A CoUI state is not a member of one enum — the code's states COMBINE (a tree
// node can be selected AND focused AND disabled at the same time), so each one
// becomes its own INDEPENDENT boolean axis in the variant name
// (`Disabled=true, Focus=false`). A single `State=` enum axis could only ever
// express one at a time, which is a shape the widgets do not have.
//
// Every axis is enumerated, never sampled: Figma builds the right-hand
// dropdown from the component NAME strings, so a state the loop skips is a
// state that does not exist as far as a designer can tell. Combinatorial
// growth is the accepted cost (Table/Tree reach 8 variants each here).
//
// Two candidate states in this file deliberately get NO axis, because an axis
// whose two sides render identically is a knob a designer has to click to
// learn it does nothing:
//   · `clickableStyle.pressedScale` — every clickableStyle in
//     components.json carries `{"v": 1}`, i.e. identity. There is no pressed
//     geometry to show.
//   · `clickableStyle.duration` / `pressDuration` /
//     `focusOutlineStyle.duration` — animation timings, no static equivalent.
const kBools: readonly boolean[] = [false, true];

function flag(axisName: string, on: boolean): string {
  return `${axisName}=${on ? 'true' : 'false'}`;
}

// The Focus axis's ring on a row the widget wraps in a `Clickable`.
//
// `Clickable` builds `FocusOutline(focusOutlineStyle: …)` around its child —
// a band in `offsetColor` filling the `align - borderWidth` gap and the ring at
// `-align` — and the shared `focusRing` draws exactly that pair.
// `focusOutlineStyle` carries all three numbers it needs (`align`,
// `borderWidth`, `ringOpacity`) beside the colour, so nothing here stands for
// a Core field.
//
// `corner` is the radius the outline follows: the row's `Clickable` radius
// (`clickableStyle.borderRadius`, which `clickable_style.dart` hands the
// outline when `focusOutlineStyle` states none of its own). Every caller in
// this file passes that one field — Accordion included, whose trigger is a
// `Clickable(clickableStyle: resolved.clickableStyle)` on both platforms and
// not a `Button`, so `triggerStyle.borderRadius` never reaches its outline.
//
// Called LAST for its row — after the row has been appended and set to FILL —
// because both layers pin STRETCH×STRETCH to the row's settled box and a row
// that FILLs has no width until its parent has shared the track.
function rowFocusRing(
  row: FrameNode,
  lk: VarLookup,
  outline: {
    align: Dim;
    borderWidth: Dim;
    ringOpacity: Dim;
    borderColor: Color;
    // The band — transparent unless the slot states an opaque one.
    offsetColor: Color;
  },
  corner: Dim,
): void {
  focusRing(row, lk, {
    outline,
    color: focusOutlineRingColor(outline),
    corner,
    width: row.width,
    height: row.height,
    visible: true,
  });
}

// ─── Caller-supplied slots ───────────────────────────────────────────────────
//
// A `W` / `W?` composition slot is drawn as the shared slot stand-in
// (`slotStandIn`, slot-stand-in.ts) with an INSTANCE_SWAP defaulting to it —
// why: docs/contributing/figma.md, "빈 슬롯의 대역". Every slot here is a box,
// so every one takes the `rectangular` shape.
const kSlotShape: SlotStandInShape = 'rectangular';

// ─── Divider composition ─────────────────────────────────────────────────────

// The item separator `Accordion` composes, as an instance of the `Divider`
// component rather than a rectangle that resembles one.
//
// Which variant, stated rather than defaulted: the widget writes
// `const Divider()` — no `child`, default (horizontal) orientation — and an
// `instanceOf` with no variant name returns whichever variant sorts first,
// which here would be a vertical hairline turned the wrong way.
//
// Stretched twice on purpose (which is `hostedDivider`'s whole subject): the
// `Label=None` variant is a single preview-length rectangle inside a hugging row,
// so stretching only the instance would leave that rectangle at its own length
// inside a wider frame, and the separator would stop short of the card edge.
function appendDividerInstance(
  page: PageNode,
  lk: VarLookup,
  parent: ComponentNode | FrameNode,
): void {
  hostedDivider(page, lk, parent);
}

// ─── Accordion ───────────────────────────────────────────────────────────────

// Data-driven from coui_core ACCORDION.fields. iconGapStyle sources the
// header's label↔chevron gap, contentPadding sources the expanded body's
// padding (l/r are genuinely 0 — CoreAccordionStyle's content inset has no
// horizontal component of its own), and contentTextStyle sources the expanded
// body's typography+color. `duration` has no static-preview equivalent
// (animation-only).
//
// Four values this builder used to draw as literals are all answered by the
// data, and three of the answers are absences:
//
//   · the item card's fill, border and radius — `CoreAccordionStyle` declares
//     `backgroundColor`, `borderColor` and `borderRadius`, and components.json
//     records all three under `absent`. An absent colour means "unpainted" and
//     an absent radius means "sharp corners" (`absence.ts`), so the honest card
//     is unfilled, unbordered and square, and the widget agrees twice over: it
//     resolves all three and then reads none of them (`accordion.dart` never
//     mentions `resolved.backgroundColor`). Where a `surface`/`outline`/8 card
//     stood, the data says draw nothing — so the card carries no chrome now.
//   · the header row's padding — `triggerStyle.padding` states it; see below.
//   · the item-to-item spacing — `itemSpacing` is a declared field recorded
//     absent, which is exactly why the widget takes its `spacing: 0.0` branch
//     and separates items with `Divider`s. That part IS wired (0 gap +
//     instances), so nothing is outstanding here.
//   · the chevron's colour — `chevronIconStyle.color` states `on-surface` and
//     is read below; the literal that stood there said `on-surface-variant`,
//     one step lighter than either platform paints.
//
// One gap is left, and it is an export gap rather than a builder one: the
// header label's type. See the note at the label itself.
//
// State axes (Disabled × Focus) come from `clickableStyle`, the accordion
// trigger's own interaction style: `disabledOpacity` (0.5) and
// `focusOutlineStyle.borderColor` (primary). Disabled dims the whole preview
// rather than each header individually — every trigger in the group is
// disabled at once, and a preview where only the three header rows fade while
// the expanded body stays crisp reads as a rendering bug, not a state.
function accordionVariantName(disabled: boolean, focused: boolean): string {
  return `${flag('Disabled', disabled)}, ${flag('Focus', focused)}`;
}

function buildAccordionVariant(
  page: PageNode,
  mount: SetMount,
  lk: VarLookup,
  disabled: boolean,
  focused: boolean,
): void {
  const iconGap = ACCORDION.fields.iconGapStyle.size;
  const contentPad = ACCORDION.fields.contentPadding;
  const contentStyle = textStyleData(ACCORDION.fields.contentTextStyle);
  // The header the widget wraps in `Clickable` is not an instance here: a
  // Figma instance takes no arbitrary children, so a `Clickable` instance
  // would replace the header row with that component's own placeholder box
  // and the question/chevron would be gone. Its two visible contributions are
  // drawn onto the header instead — the focus ring from
  // `clickableStyle.focusOutlineStyle` and the dim from
  // `clickableStyle.disabledOpacity` — which is the whole of what the
  // Clickable renders. (Same call the `ThemeController` builder makes for the
  // Clickable its swatch composes.)
  const clickable = ACCORDION.fields.clickableStyle;
  const c = mount.getOrCreate(accordionVariantName(disabled, focused));
  // No item-to-item gap: `itemSpacing` has no CoreAccordionStyle default, so
  // `Accordion.build` takes its `Column(spacing: 0.0)` branch and separates the
  // items with `Divider` instances instead (appended below).
  applyPanelCompChrome(c, 'VERTICAL', lk, {});
  // `CoreAccordionStyle` declares no extent field, and the widget is
  // `IntrinsicWidth > Column` — an accordion's width is whatever its parent
  // gives it, so there is no value here to read and never will be.
  // g7-preview-only: Accordion preview width, no extent field in the code.
  lockWidth(c, 320);
  if (disabled) c.opacity = dimVal(clickable.disabledOpacity);
  const items: { q: string; open: boolean }[] = [
    { q: '환불 정책은 어떻게 되나요?', open: true },
    { q: '요금제는 어떻게 해지하나요?', open: false },
    { q: '이메일을 바꿀 수 있나요?', open: false },
  ];
  for (let i = 0; i < items.length; i++) {
    const it = items[i];
    // No chrome, and that is the data speaking: `backgroundColor`,
    // `borderColor` and `borderRadius` are all under `accordion.absent`, which
    // `absence.ts` reads as unpainted / unbordered / square. See the section
    // note above for the widget side.
    const card = panel('item', 'VERTICAL', lk, {});
    // The insets come from `triggerStyle.padding` now. The note that used to be
    // here had it exactly right — "reading it here is the correct wiring AND it
    // moves the canvas: the row loses its horizontal inset and gains 4 on each
    // vertical edge" — and left the literals in place because moving pixels was
    // out of that pass's scope. Moving them is this one's.
    //
    // `CoreAccordionStyle.defaultTriggerStyle` states
    // `CoreEdgeInsets.symmetric(vertical: CoreSpace.space16)` and
    // `accordion.dart:437` draws it as `Padding(padding: resolved.triggerPadding)`.
    // So the row has no horizontal inset — the header's text starts where the
    // panel's own padding leaves it, which is what both platforms render.
    //
    // Label: decided by `CoreAccordionStyle.defaultLabelTextStyle`
    // (`labelXl` at the role's own 500 + onSurface), which both
    // platforms already read — Flutter via `resolved.labelTextStyle`
    // (accordion.dart:448), Web via `emitTypography` — so there is nothing
    // to lift into Core. What is missing is the export: the exporter emits a
    // `default*` only when the Style declares an instance field of the same
    // name (schema_v2.dart:326), and this default's override seat is the
    // nested `triggerStyle.labelStyle`, whose own baseline sits in button's
    // `defaultsBySize` rather than a flat `defaultLabelStyle`. So neither
    // `fields.labelTextStyle` nor `fields.triggerStyle.labelStyle` exists to
    // read, and once it does it will repaint: labelXl is 15 in the root
    // `typography` table against the 14 here, its 500 against Regular.
    //
    // Nothing downstream would catch either move — the fidelity check
    // compares the component's top-level `padding`, and accordion states
    // none; it compares no typography at all — so both rewirings belong to a
    // change authorised to move those pixels.
    const triggerPad = ACCORDION.fields.triggerStyle.padding;
    const header = panel('header', 'HORIZONTAL', lk, {
      pl: triggerPad.l, pr: triggerPad.r, pt: triggerPad.t, pb: triggerPad.b,
      gap: iconGap,
    });
    header.counterAxisAlignItems = 'CENTER';
    // No corner on the row. The trigger is not a `Button`: both platforms
    // build it as `Clickable(clickableStyle: resolved.clickableStyle)` around a
    // `Padding` and read `triggerStyle` for its padding and label only, so no
    // `triggerStyle` corner is painted anywhere. The focus ring below follows
    // the Clickable's radius, which is the one the widget's outline is drawn
    // from.
    // g7-preview-only: no label type in `accordion.fields` — neither `labelTextStyle` nor `triggerStyle.labelStyle` is exported (see above).
    const q = makeLabel(it.q, lk, { size: 14, colorVar: lk.sem('on-surface') });
    header.appendChild(q);
    q.layoutSizingHorizontal = 'FILL';
    // The chevron's colour is `chevronIconStyle.color` — `on-surface`, and it
    // is the glyph's own slot rather than a neighbour's: `accordion.dart:467`
    // draws `Icon(iconStyle: resolved.chevronIconStyle)`, whose colour comes
    // from `CoreAccordionStyle.defaultChevronIconStyle`. That repaints the
    // chevron a step darker than the `on-surface-variant` literal that stood
    // here, which is the point — fidelity compares no colours, so nothing
    // downstream would ever have reported the divergence.
    //
    // The size stays on `arrowIconStyle`, which resolves to the same 16 px:
    // the resolver reads `merged.arrowIconStyle?.size ?? merged
    // .chevronIconStyle?.size` in that order, so `arrowIconStyle` is the outer
    // seat for it and moving the read would strand that field unread.
    // ONE mark, turned. `accordion.dart:460-468` draws `LucideIcons.chevronDown`
    // and rotates it by `controller.value * pi` — so closed is a chevron pointing
    // DOWN at 0° and open is that same chevron at 180°, pointing up.
    //
    // What stood here was two different glyphs: `chevron-right` closed and
    // `chevron-down` open. Both ends were wrong and in opposite directions — the
    // closed row pointed sideways where the app points down, and the open row
    // pointed down where the app points up. It reads as a deliberate disclosure
    // affordance either way, which is why nothing reported it.
    const chevron = makeIcon(
      'chevron-down',
      lk,
      glyphOpts(
        lk,
        colorData(ACCORDION.fields.chevronIconStyle.color),
        ACCORDION.fields.arrowIconStyle.size,
        'size',
      ),
    );
    header.appendChild(chevron);
    // Degrees, and Figma turns counter-clockwise — at half a turn the direction
    // does not matter, which is the whole of what `value * pi` reaches at rest.
    if (it.open) chevron.rotation = kHalfTurnDegrees;
    card.appendChild(header);
    header.layoutSizingHorizontal = 'FILL';
    if (it.open) {
      const body = panel('body', 'VERTICAL', lk, {
        pl: contentPad.l, pr: contentPad.r, pt: contentPad.t, pb: contentPad.b,
      });
      const txt = makeLabel('구매 후 30일 안에 전액 환불을 요청할 수 있어요.', lk, textLabelOpts(lk, contentStyle));
      txt.textAutoResize = 'HEIGHT';
      body.appendChild(txt);
      card.appendChild(body);
      body.layoutSizingHorizontal = 'FILL';
      txt.layoutSizingHorizontal = 'FILL';
    }
    c.appendChild(card);
    card.layoutSizingHorizontal = 'FILL';
    // Focus lands on the first trigger only: the ring means "this row has
    // keyboard focus", and three ringed rows would say the opposite. After the
    // FILLs (see `rowFocusRing`); the card is a frame, and a frame clips, so it
    // lets the ring stand outside the header's edge.
    if (focused && i === 0) {
      card.clipsContent = false;
      rowFocusRing(header, lk, clickable.focusOutlineStyle, clickable.borderRadius.topLeft);
    }
    // One separator after EVERY item, the trailing one included — that is
    // literally what the widget builds (`…, if (i < last) separator, …,
    // separator`). Dropping the trailing line because it looks redundant
    // under a bordered card would make the canvas disagree with the code.
    appendDividerInstance(page, lk, c);
  }
}

// `items` (the contract's only composition slot) is `List<W>` and gets no
// Figma component property: Figma has no repeated-slot property type, so a
// designer adds or removes item cards directly. Binding a TEXT property to one
// item's question would declare a single-item slot the widget does not have.
function buildAccordion(page: PageNode, lk: VarLookup): ComponentSetNode {
  const names: string[] = [];
  for (const disabled of kBools) {
    for (const focused of kBools) names.push(accordionVariantName(disabled, focused));
  }
  const mount = mountSet(page, 'Accordion', names);
  for (const disabled of kBools) {
    for (const focused of kBools) buildAccordionVariant(page, mount, lk, disabled, focused);
  }
  return mount.finish();
}

// ─── Collapsible ─────────────────────────────────────────────────────────────

// Data-driven from coui_core COLLAPSIBLE.fields. iconLabelGapStyle sources the
// header's title↔chevron gap, contentInset sources the disclosure body's
// padding, triggerTextStyle sources the trigger title's typography+color, and
// contentTextStyle sources the body paragraph's. `duration` has no
// static-preview equivalent (animation-only).
//
// `absent` is empty for this component — every declared field reached a value —
// so nothing here is exempt by absence. Three drawn values were divergences and
// all three are settled by reading the widget rather than by reading a field:
//
//   · the header↔body gap (8) — the widget puts NO spacing between them
//     (`collapsible.dart:192` is a bare `Column`, and the file states `spacing`
//     nowhere); the separation it does have is the content's own
//     `.only(top: contentInset.top)`, which the body panel below already
//     spends. So the 8 was a second separation on top of a stated 16, and the
//     two rows sit flush now.
//   · the body panel's fill and radius — `CoreCollapsibleStyle` declares
//     neither, and the widget's content wrapper is `Padding` +
//     `DefaultTextStyle.merge` with no decoration at all. Deletion, not wiring:
//     a `surface-container-low`/8 panel is chrome no platform draws.
//   · the chevron's colour — stated in Core and NOT exported; see the marker at
//     the glyph.
//
// One gap stays, and it is neither a literal nor a colour: the widget pads the
// trigger row with `contentInset` on all four edges (`collapsible.dart:283`)
// and this header panel has no inset at all. Moving that is a layout change on
// its own footing, so it is not folded into a literal pass.
//
// State axes (Disabled × Focus) come from `clickableStyle` — same fields, same
// reasoning as Accordion above.
const kCollapsibleTrigger = '고급 설정';
const kCollapsibleContent = '고급 사용자를 위한 옵션이에요.';

interface CollapsibleRefs {
  comp: ComponentNode;
  trigger: TextNode;
  content: TextNode;
}

function collapsibleVariantName(
  expanded: boolean,
  disabled: boolean,
  focused: boolean,
): string {
  return `${flag('Expanded', expanded)}, ${flag('Disabled', disabled)}, ` +
    `${flag('Focus', focused)}`;
}

function buildCollapsibleVariant(
  mount: SetMount,
  lk: VarLookup,
  expanded: boolean,
  disabled: boolean,
  focused: boolean,
): CollapsibleRefs {
  const headerGap = COLLAPSIBLE.fields.iconLabelGapStyle.size;
  const inset = COLLAPSIBLE.fields.contentInset;
  // `CollapsibleTrigger` returns `Clickable(child: Semantics(Padding(Row(…))))`
  // — a wrapper around an arbitrary child, which a Figma instance cannot hold.
  // Instancing it would swap the whole trigger row for that component's
  // placeholder box, so the Clickable's visible chrome (focus ring +
  // disabled opacity, both read below) is drawn onto the header instead.
  const clickable = COLLAPSIBLE.fields.clickableStyle;
  const c = mount.getOrCreate(collapsibleVariantName(expanded, disabled, focused));
  // No header↔body gap — see the section note: the widget's root `Column` has
  // no spacing and the body's own `contentInset` top is the whole separation.
  applyPanelCompChrome(c, 'VERTICAL', lk, {});
  // Same shape as Accordion's: `CoreCollapsibleStyle` declares no extent field
  // and the widget's root is a plain `Column`, so the disclosure takes its
  // parent's width.
  // g7-preview-only: Collapsible preview width, no extent field in the code.
  lockWidth(c, 300);
  if (disabled) c.opacity = dimVal(clickable.disabledOpacity);
  const header = panel(kCollapsibleHeaderName, 'HORIZONTAL', lk, { gap: headerGap });
  header.counterAxisAlignItems = 'CENTER';
  const title = makeLabel(
    kCollapsibleTrigger,
    lk,
    textLabelOpts(lk, textStyleData(COLLAPSIBLE.fields.triggerTextStyle)),
  );
  header.appendChild(title);
  title.layoutSizingHorizontal = 'FILL';
  const chevron = makeIcon('chevron-down', lk, {
    size: COLLAPSIBLE.fields.iconStyle.size,
    // `collapsible.fields.iconStyle` carries a size and no colour, and the
    // colour the code paints lives in a field the exporter cannot reach:
    // `Collapsible` draws `Icon(iconStyle: resolved.iconStyle)`
    // (collapsible.dart:308) whose colour is
    // `CoreCollapsibleStyle.defaultIconColor` (`onSurface`) — a bare scalar
    // with no `iconColor` instance field beside it, and the exporter emits a
    // `default*` only where a same-named field exists. `icon`'s own default is
    // the same token but reading it here would be reaching into a child
    // component's default, which `core/style-contract.md` forbids.
    // g7-preview-only: `defaultIconColor` has no exported seat under `collapsible`.
    colorVar: lk.sem('on-surface-variant'),
  });
  header.appendChild(chevron);
  // One mark, turned — `Transform.rotate(angle: controller.value * pi)` around
  // `LucideIcons.chevronDown` (collapsible.dart:298-310). Collapsed is that
  // chevron pointing down at 0°, expanded is the same mark at half a turn.
  if (expanded) chevron.rotation = kHalfTurnDegrees;
  c.appendChild(header);
  header.layoutSizingHorizontal = 'FILL';
  if (focused) {
    rowFocusRing(header, lk, clickable.focusOutlineStyle, clickable.borderRadius.topLeft);
  }
  // Padding only. The widget's content wrapper is `Padding` +
  // `DefaultTextStyle.merge` and carries no decoration, so a fill and a corner
  // here would be chrome `CoreCollapsibleStyle` never declares.
  const body = panel(kCollapsibleBodyName, 'VERTICAL', lk, {
    pl: inset.l, pr: inset.r, pt: inset.t, pb: inset.b,
  });
  const content = makeLabel(
    kCollapsibleContent,
    lk,
    textLabelOpts(lk, textStyleData(COLLAPSIBLE.fields.contentTextStyle)),
  );
  body.appendChild(content);
  c.appendChild(body);
  body.layoutSizingHorizontal = 'FILL';
  // `expanded = false` is the widget's default, and the body is what the flag
  // gates — an auto-layout frame skips a hidden child, so the collapsed member is
  // the header alone, which is what the app draws before anyone clicks.
  //
  // The state used to have no axis at all: every member showed the content with a
  // chevron pointing the collapsed way, so the canvas was a disclosure caught
  // between its two poses and the DEFAULT one was not on the page.
  body.visible = expanded;
  return { comp: c, trigger: title, content: content };
}

// `trigger` and `content` are both required (`W`) composition slots that this
// preview fills with a single TEXT node each — so each becomes a TEXT
// component property whose default is the placeholder copy already here. That
// is what turns "double-click into the component and retype" into a declared
// slot a designer can fill from the right-hand panel.
function buildCollapsible(page: PageNode, lk: VarLookup): ComponentSetNode {
  const names: string[] = [];
  for (const expanded of kBools) {
    for (const disabled of kBools) {
      for (const focused of kBools) {
        names.push(collapsibleVariantName(expanded, disabled, focused));
      }
    }
  }
  const mount = mountSet(page, 'Collapsible', names);
  const refs: CollapsibleRefs[] = [];
  for (const expanded of kBools) {
    for (const disabled of kBools) {
      for (const focused of kBools) {
        refs.push(buildCollapsibleVariant(mount, lk, expanded, disabled, focused));
      }
    }
  }
  const set = mount.finish();
  // Properties are defined AFTER finish(), never inside the variant loop:
  // `mount.getOrCreate()` hands back a standalone COMPONENT (it joins the set
  // in finish()), so `propertyOwner` would answer "the member" during the loop
  // and "the set" on the next run — the same property landing in two different
  // places depending on whether the page already had the set.
  const owner = propertyOwner(refs[0].comp);
  const triggerProp = defineProp(owner, 'Trigger', 'TEXT', kCollapsibleTrigger);
  const contentProp = defineProp(owner, 'Content', 'TEXT', kCollapsibleContent);
  for (const r of refs) {
    bindTextProp(r.trigger, triggerProp);
    bindTextProp(r.content, contentProp);
  }
  return set;
}

// ─── Disclosure ──────────────────────────────────────────────────────────────
//
// The no-JS sibling of Collapsible: Web renders `<details>/<summary>` and the
// browser owns the toggle, so the widget holds no state. That changes what the
// canvas has to show, in three ways that are worth stating because each one is
// a place this builder deliberately differs from `buildCollapsible` above.
//
//   · No `Disabled` axis. Collapsible takes one from `clickableStyle`, but
//     `CoreDisclosureContract` has no `enabled` parameter and `<details>` has
//     no disabled state to mirror — an axis here would be a knob a designer
//     clicks to learn it does nothing, which the boolean-axis note at the top
//     of this file already rules out. `clickableStyle.disabledOpacity` is
//     therefore read by nothing on this component, and that is correct rather
//     than missing.
//   · The summary row IS padded. Collapsible's header carries no inset and its
//     section note records that as the one gap left standing; both Disclosure
//     resolvers put `contentInset` on all four edges of `<summary>`
//     (`disclosure_style.dart`, Web `buildSummaryChrome` / Flutter
//     `resolved.contentInset`), so it is padded here from the start.
//   · The body takes `contentInset.top` ONLY. That is the whole separation the
//     widget draws between header and body on both platforms — Web emits
//     `padding-top` and nothing else, Flutter wraps the content in
//     `Padding(.only(top: contentInset.top))`. Binding l/r/b as well would
//     state an inset no platform paints.
//
// The chevron's colour comes from `constants.iconColor` — the seat Collapsible
// could not reach (its note explains why) and this component does export,
// because `CoreDisclosureStyle.defaultIconColor` sits beside a same-named
// nested slot the exporter can follow. So there is no literal here standing in
// for a Core value.
//
// `duration` is animation-only (the chevron's rotation), with no static
// equivalent — same as Collapsible.
// Matches Collapsible's own preview width — the two are the same disclosure
// shape and a designer comparing them should not be reading a width
// difference as a design one.
const kDisclosurePreviewWidth = 300;
const kDisclosureTitle = 'CoUI는 무엇인가요?';
const kDisclosureContent =
  'Flutter와 웹에서 똑같이 보이는 디자인 시스템이에요.';

interface DisclosureRefs {
  comp: ComponentNode;
  title: TextNode;
  content: TextNode;
}

function disclosureVariantName(open: boolean, focused: boolean): string {
  return `${flag('Open', open)}, ${flag('Focus', focused)}`;
}

function buildDisclosureVariant(
  mount: SetMount,
  lk: VarLookup,
  open: boolean,
  focused: boolean,
): DisclosureRefs {
  const inset = DISCLOSURE.fields.contentInset;
  const clickable = DISCLOSURE.fields.clickableStyle;
  const c = mount.getOrCreate(disclosureVariantName(open, focused));
  // No root gap: the body's own top inset is the entire header↔body
  // separation, the same reading Collapsible's note arrives at.
  applyPanelCompChrome(c, 'VERTICAL', lk, {});
  // g7-preview-only: Disclosure preview width, no extent field in the code —
  // the widget's root is a plain `Column` / `<details>` and takes its parent's
  // width.
  lockWidth(c, kDisclosurePreviewWidth);
  // `<summary>` — the row the browser makes focusable and clickable. Padded on
  // all four edges, per the section note.
  const summary = panel('summary', 'HORIZONTAL', lk, {
    gap: DISCLOSURE.fields.iconLabelGapStyle.size,
    pl: inset.l,
    pr: inset.r,
    pt: inset.t,
    pb: inset.b,
  });
  summary.counterAxisAlignItems = 'CENTER';
  const title = makeLabel(
    kDisclosureTitle,
    lk,
    textLabelOpts(lk, textStyleData(DISCLOSURE.fields.triggerTextStyle)),
  );
  summary.appendChild(title);
  title.layoutSizingHorizontal = 'FILL';
  const chevron = makeIcon(
    'chevron-down',
    lk,
    glyphOpts(
      lk,
      colorData(DISCLOSURE.constants.iconColor),
      DISCLOSURE.fields.iconStyle.size,
      // The icon-size ladder, not the font-size one — this leaf's ref says
      // `Component/icon-size/16`. Spelled out rather than globbed on
      // purpose: a star directly after a slash reads as the start of a
      // block comment to the unread-fields guard's stripper, and every
      // field reference after it stops counting as read.
      'size',
    ),
  );
  summary.appendChild(chevron);
  // One mark, turned. Both platforms rotate the same `chevronDown` half a turn
  // when open — Web through `group-open:rotate-180` reading the browser's own
  // `open` attribute, Flutter through `AnimatedRotation(turns: 0.5)`.
  if (open) chevron.rotation = kHalfTurnDegrees;
  c.appendChild(summary);
  summary.layoutSizingHorizontal = 'FILL';
  // Web paints this ring only when a caller states one and otherwise leaves
  // the browser's own outline alone, but the ring the data carries is the one
  // both platforms use once asked, and a focus pose that showed nothing would
  // be a variant with no visible difference.
  if (focused) {
    rowFocusRing(summary, lk, clickable.focusOutlineStyle, clickable.borderRadius.topLeft);
  }
  // Padding only, and only on top — see the section note. No fill and no
  // corner: `CoreDisclosureStyle` declares neither, and the widget's body
  // wrapper carries no decoration on either platform.
  const body = panel('content', 'VERTICAL', lk, { pt: inset.t });
  const content = makeLabel(
    kDisclosureContent,
    lk,
    textLabelOpts(lk, textStyleData(DISCLOSURE.fields.contentTextStyle)),
  );
  body.appendChild(content);
  c.appendChild(body);
  body.layoutSizingHorizontal = 'FILL';
  // Closed is the default (`open = false`), and closed is what a static render
  // ships: the browser does not render a closed section's content at all, and
  // the Flutter twin leaves it out of the tree. An auto-layout frame skips a
  // hidden child, so the closed member is the summary row alone — which is
  // exactly what the page shows before anyone clicks.
  body.visible = open;
  return { comp: c, title: title, content: content };
}

// `content` is a required (`W`) slot and `trigger` an optional (`W?`) one, and
// both land on this preview as a single TEXT node each — so each becomes a
// TEXT component property, the same shape Collapsible uses for the same
// reason.
//
// The header property is named for the SLOT (`Trigger`), not for the string
// that fills it by default (`title`). They are one seat: the widget renders
// `trigger ?? Text(title!)` on both platforms, so a header is either a
// caller's widget or the title text, never both. Naming the property `Title`
// would leave `trigger` — a composition point the contract really declares —
// with nothing on the canvas to fill it, and a designer with no way to see
// that the seat takes a widget at all. The default text is still the title
// copy, because that is what the widget draws when no trigger is passed.
function buildDisclosure(page: PageNode, lk: VarLookup): ComponentSetNode {
  const names: string[] = [];
  for (const open of kBools) {
    for (const focused of kBools) {
      names.push(disclosureVariantName(open, focused));
    }
  }
  const mount = mountSet(page, 'Disclosure', names);
  const refs: DisclosureRefs[] = [];
  for (const open of kBools) {
    for (const focused of kBools) {
      refs.push(buildDisclosureVariant(mount, lk, open, focused));
    }
  }
  const set = mount.finish();
  // After `finish()`, never inside the loop — same reason as Collapsible's.
  const owner = propertyOwner(refs[0].comp);
  const triggerProp = defineProp(owner, 'Trigger', 'TEXT', kDisclosureTitle);
  const contentProp = defineProp(owner, 'Content', 'TEXT', kDisclosureContent);
  for (const r of refs) {
    bindTextProp(r.title, triggerProp);
    bindTextProp(r.content, contentProp);
  }
  return set;
}

// ─── DisclosureGroup ─────────────────────────────────────────────────────────
//
// A stack of independent `Disclosure`s — the FAQ shape the component was filed
// for. It composes real `Disclosure` INSTANCES rather than redrawing a section,
// which is the same rule the widget follows: the group holds no state and
// restyles nothing, so there is nothing for it to draw except the distance
// between its children.
//
// That distance is `itemSpacing`, and this is the only place it can land — a
// lone `Disclosure` has no sibling to space against, which is what the field's
// own doc says. It is why the group is a component at all rather than an
// auto-layout frame a designer makes by hand.
//
// The first member is open and the rest closed: a group where every section is
// shut states nothing about what opening one does to the others, and the answer
// — nothing, they are independent — is the whole difference from `Accordion`.
const kDisclosureGroupSections = 3;

function buildDisclosureGroup(page: PageNode, lk: VarLookup): ComponentNode {
  const c = mintPanelComp(page, 'DisclosureGroup', 'VERTICAL', lk, {
    gap: DISCLOSURE.fields.itemSpacing,
  });
  // g7-preview-only: matches the `Disclosure` preview width above so the
  // stacked instances do not resize against their own component.
  lockWidth(c, kDisclosurePreviewWidth);
  for (let i = 0; i < kDisclosureGroupSections; i++) {
    const section = instanceOf(page, 'Disclosure', disclosureVariantName(i === 0, false));
    c.appendChild(section);
    section.layoutSizingHorizontal = 'FILL';
  }
  return c;
}

// ─── Divider ─────────────────────────────────────────────────────────────────
// #3743 — covers the CoreDividerStyle contract as a variant matrix instead of
// the single hardcoded "labeled OR" shape: Orientation(Horizontal/Vertical) ×
// Label(None/Present). Data-driven from coui_core DIVIDER.fields (#3755):
// color/thickness source the line itself, and childPadding sources the label
// wrap's main-axis inset (l/r ↔ t/b swapped for the vertical orientation —
// the same axis swap the literals it replaces already encoded). indent/
// endIndent are genuinely CoreSpace.space0 (no inset — the two line segments
// run edge to edge, which is what these variants demonstrate) and have no
// geometry here to bind them to. The line itself is a filled rectangle whose
// thickness axis binds to the stroke step `thickness` names. The "OR" label's
// colour and the two segments' preview length (90/200) have no matching
// CoreDividerStyle field (#3755 OQ-2); its type follows `labelMedium`, the role
// the docs example gives the same child.
//
// CoreDividerStyle carries no state-keyed chrome at all, so Divider gets no
// boolean state axis — the existing two axes are its whole matrix.

const kDividerChild = '또는';

interface DividerRefs {
  comp: ComponentNode;
  /** The `child` slot's text node — absent in the two `Label=None` variants. */
  label: TextNode | null;
}

// The rule is a filled rectangle, not a stroke: its thickness is the rectangle's
// own extent across the line (height for a horizontal rule, width for a vertical
// one), bound to the `Primitives/stroke` step the field names. Bound right after
// the resize; `stretchRule` later writes only the length axis.
function dividerLine(lk: VarLookup, horizontal: boolean, length: number): RectangleNode {
  const line = figma.createRectangle();
  const thickness = DIVIDER.fields.thickness;
  const across = dimVal(thickness);
  line.resize(horizontal ? length : across, horizontal ? across : length);
  bindStrokeAxis(line, lk, horizontal ? 'height' : 'width', thickness);
  fillData(line, lk, colorData(DIVIDER.fields.color));
  return line;
}

// `Padding(padding: isHorizontal ? .only(left: indent, right: endIndent) : .only(
// top: indent, bottom: endIndent))` around the line, in the childless case.
//
// Two fields, not one doubled: the widget names the leading inset `indent` and
// the trailing one `endIndent`, and reading only `indent` for both would draw a
// symmetric line where the data says asymmetric. They agree at their defaults
// (both 0), which is exactly why the collapse left no trace.
function applyDividerIndents(c: ComponentNode, lk: VarLookup, horizontal: boolean): void {
  const indent = DIVIDER.fields.indent;
  const endIndent = DIVIDER.fields.endIndent;
  bindPad(c, lk, horizontal
    ? { l: indent, r: endIndent, t: 0, b: 0 }
    : { l: 0, r: 0, t: indent, b: endIndent });
}

function buildDividerVariant(
  mount: SetMount,
  lk: VarLookup,
  horizontal: boolean,
  labeled: boolean,
): DividerRefs {
  const name = `Orientation=${horizontal ? 'Horizontal' : 'Vertical'}, Label=${labeled ? 'Present' : 'None'}`;
  const c = mount.getOrCreate(name);
  c.layoutMode = horizontal ? 'HORIZONTAL' : 'VERTICAL';
  c.primaryAxisSizingMode = 'AUTO';
  c.counterAxisSizingMode = 'AUTO';
  c.counterAxisAlignItems = 'CENTER';
  c.itemSpacing = 0; // childPadding IS the gap mechanism, not a sibling gap
  c.fills = [];

  if (!labeled) {
    const line = dividerLine(lk, horizontal, 200);
    c.appendChild(line);
    // Only the childless branch takes these — with a child the widget spends the
    // insets on the two `Expanded` segments' own `Padding`s instead.
    applyDividerIndents(c, lk, horizontal);
    stretchRule(c, horizontal, [line]);
    return { comp: c, label: null };
  }

  const segmentLength = 90;
  const before = dividerLine(lk, horizontal, segmentLength);
  c.appendChild(before);
  const childPad = DIVIDER.fields.childPadding;
  const labelWrap = panel('label', horizontal ? 'HORIZONTAL' : 'VERTICAL', lk, {
    pl: horizontal ? childPad.l : childPad.t,
    pr: horizontal ? childPad.r : childPad.b,
    pt: horizontal ? childPad.t : childPad.l,
    pb: horizontal ? childPad.b : childPad.r,
  });
  // The `child` slot is `W?` and `Divider` wraps whatever arrives in
  // `Padding(padding: childPadding)` and nothing else — no `DefaultTextStyle`,
  // and `CoreDividerStyle` carries no text field to add one. So this "OR" is the
  // placeholder that gives the two `Label=Present` variants something for
  // `childPadding` to sit around, and a caller's own widget replaces it. Its type
  // is the role the docs example gives the same child (`labelMedium`), drawn
  // through the shared role opts so the canvas wears that role's text style; the
  // colour is this file's.
  const labelType = typographyColorOpts(lk, textStyleData({ role: 'labelMedium' }), null);
  // g7-preview-only: no CoreDividerStyle field states the colour of the invented "OR" filling the `child` slot.
  labelType.colorVar = lk.sem('on-surface-variant');
  const label = makeLabel(kDividerChild, lk, labelType);
  labelWrap.appendChild(label);
  c.appendChild(labelWrap);
  const after = dividerLine(lk, horizontal, segmentLength);
  c.appendChild(after);
  // Both segments share what is left beside the label, so the label stays centred
  // at any length instead of sitting between two 90px stubs.
  stretchRule(c, horizontal, [before, after]);
  return { comp: c, label: label };
}

// A Divider's whole visible contribution is its rule, and `divider.dart` takes
// its length from the parent's constraints — there is no stated length to bind.
// So the member is FIXED at the preview length and the rule FILLS it: an
// instance a consumer stretches carries the line with it.
//
// Left HUG with a FIXED rule, it did not: the member grew and the 200px
// rectangle inside stayed 200, so every full-width rule in a consuming file drew
// about a fifth of the way across (found on Saem's site footer, 2026-09-07).
// FILL on a hugging axis is refused by Figma, which is why the sizing mode is
// stated here rather than left at `AUTO`.
function stretchRule(
  c: ComponentNode,
  horizontal: boolean,
  lines: readonly RectangleNode[],
): void {
  const length = kDividerPreviewLength;
  if (horizontal) {
    c.resize(length, c.height);
  } else {
    c.resize(c.width, length);
  }
  // After `resize`, which resets the sizing modes it touches.
  c.primaryAxisSizingMode = 'FIXED';
  for (const line of lines) {
    if (horizontal) line.layoutSizingHorizontal = 'FILL';
    else line.layoutSizingVertical = 'FILL';
  }
}

// The length a Divider member previews at — a canvas choice, not a stated field
// (see `stretchRule`).
// g7-preview-only: Divider preview length; `CoreDividerStyle` states thickness and indents, never a length.
const kDividerPreviewLength = 200;

// The `child` slot (`W?`) is expressed two ways, and both are needed: the
// existing `Label` axis says whether the slot is filled at all (the two
// `Label=None` variants have no label node to hide), and a TEXT property says
// what it contains. A BOOLEAN visibility property would be a third control
// duplicating the axis, on a node that only exists in half the variants.
function buildDivider(page: PageNode, lk: VarLookup): ComponentSetNode {
  const names = [
    'Orientation=Horizontal, Label=None',
    'Orientation=Horizontal, Label=Present',
    'Orientation=Vertical, Label=None',
    'Orientation=Vertical, Label=Present',
  ];
  const mount = mountSet(page, 'Divider', names);
  const refs: DividerRefs[] = [
    buildDividerVariant(mount, lk, true, false),
    buildDividerVariant(mount, lk, true, true),
    buildDividerVariant(mount, lk, false, false),
    buildDividerVariant(mount, lk, false, true),
  ];
  const set = mount.finish();
  set.layoutMode = 'HORIZONTAL';
  set.layoutWrap = 'WRAP';
  set.primaryAxisSizingMode = 'AUTO';
  set.counterAxisSizingMode = 'AUTO';
  set.counterAxisAlignItems = 'CENTER';
  set.itemSpacing = 24;
  set.counterAxisSpacing = 24;
  set.paddingLeft = 24;
  set.paddingRight = 24;
  set.paddingTop = 24;
  set.paddingBottom = 24;
  // After finish() — see buildCollapsible for why the owner is only correct here.
  const childProp = defineProp(propertyOwner(refs[0].comp), 'Child', 'TEXT', kDividerChild);
  for (const r of refs) {
    if (r.label) bindTextProp(r.label, childProp);
  }
  return set;
}

// ─── Footer ──────────────────────────────────────────────────────────────────

// The `Info` pose axis — whether the composed business-info disclosure is open.
// Nothing in `CoreFooterContract` is named `Info`: the two values are the two
// states of `businessInfoExpanded`, spelled the way the designer's members
// already spell them, because a member's name is its identity.
const kFooterInfoCollapsed = 'collapsed';
const kFooterInfoExpanded = 'expanded';
const kFooterInfoValues: readonly string[] = [
  kFooterInfoCollapsed,
  kFooterInfoExpanded,
];

// `CoreFooterContract.defaultShowDivider`. A behaviour flag, so the exporter
// (chrome only) has no seat for it — restated here rather than left implicit,
// because "off" is the whole claim the designer's four hidden rules make.
const kFooterShowDividerDefault = false;

// `CoreLinkVariant` member the legal row uses — her `links` are
// `Link / Variant=muted`.
const kFooterLinkVariant = 'muted';

// Preview copy for the slots the contract types as `W?` / `List<W>`. Content,
// not chrome: the widget draws whatever the caller passes, and these are what a
// designer sees before she replaces them.
const kFooterColumns: ReadonlyArray<{ title: string; links: readonly string[] }> = [
  { title: '제품', links: ['기능', '요금', '업데이트 내역'] },
  { title: '회사', links: ['소개', '블로그', '채용'] },
  { title: '약관 및 정책', links: ['개인정보 처리방침', '이용약관', '보안'] },
];
const kFooterCompany = '코코드';
const kFooterBusinessInfoLabel = '사업자 정보';
// One line, where hers wraps to three. The disclosure hugs its trigger in this
// row (see `buildFooterLegal`), so a paragraph long enough to wrap on her 592
// would instead make one very wide line and push the row past the preview's
// 640. The words are the designer's to replace — a longer one wraps wherever
// the app's own constraint puts it.
const kFooterBusinessInfo = '대표 김코드 · 사업자등록번호 000-00-00000';
const kFooterLegalLinks: readonly string[] = [
  '환불 정책',
  '이용약관',
  '개인정보 처리방침',
];
const kFooterCopyright = '© 2026 코코드. All rights reserved.';

// Data-driven from coui_core FOOTER.fields — no variant/size dispatch on
// CoreFooterStyle, and no state-keyed chrome, so no boolean state axis.
// backgroundColor/padding source the outer chrome, sectionSpacing sources the
// column-to-column gap, sectionTitleGapStyle sources each column's title↔links
// gap, titleTextStyle sources the section titles' typography+color, and
// bodyTextStyle sources the link items'.
//
// `aside` (`W?`) is the contract's optional branding slot, rendered FIRST —
// the widget builds `[?aside, ...sections]`, so a slot placed after the columns
// would put the Figma preview in a different order than the code.
//
// It takes TWO nodes and two properties, because it makes two statements and a
// node holds exactly ONE `componentPropertyReferences` map (`bindVisibleProp` /
// `bindSwapProp` each assign that map wholesale, so calling both on one node
// silently drops whichever ran first):
//
//   · the holder carries the BOOLEAN — the slot being ABSENT, the widget's
//     `null`. An optional slot with no visibility property is one a designer
//     cannot turn off.
//   · the instance inside carries the INSTANCE_SWAP — the slot being ANY
//     widget, which is what `W?` means and what the widget's own doc example
//     (`aside: Logo()`) puts there.
//
// The swap gets the slot's own name and the BOOLEAN is prefixed
// (`Aside` / `Show aside`): the swap is the statement the contract makes, the
// boolean is the narrower one, and a Figma owner cannot hold two properties
// under one name (`addComponentProperty` throws on a duplicate).
//
// A placeholder box rather than the wordmark that used to stand here, and the
// reason is not only "any widget": that wordmark was drawn in
// `titleTextStyle`, and the widget never styles the aside with it.
// `titleTextStyle` reaches `_FooterNavSection`'s section titles only — an
// `aside` widget inherits the ambient `bodyTextStyle` like any other child.
// The box asserts no typography at all, which is the accurate claim.
// `CoreFooterLayout` → the three things the widget's `switch` decides: which way
// the sections stack, whether they wrap, and where they sit on the cross axis.
//
//   · `horizontal` → `Wrap(spacing, runSpacing)` — a row that wraps, which in
//     Figma is `layoutWrap: 'WRAP'` plus `counterAxisSpacing` for the run gap.
//     Both come from the one `sectionSpacing` field, as they do in the widget.
//   · `vertical` → `Column(crossAxisAlignment: .start)`
//   · `center`   → `Column(crossAxisAlignment: .center)`
//
// The cross-axis value is the widget's own line for it
// (`resolved.layout == .center ? .center : .start`), not a guess per case.
//
// Throws on an unknown member for the same reason the alignment tables do: the
// runtime harness drives this builder against the committed data, so a fourth
// member fails on the machine that adds it rather than silently laying the
// sections out the old way.
function footerLayoutOf(leaf: { readonly choice: string }): {
  mode: 'HORIZONTAL' | 'VERTICAL';
  wrap: boolean;
  cross: 'MIN' | 'CENTER';
} {
  switch (leaf.choice) {
    case 'horizontal':
      return { mode: 'HORIZONTAL', wrap: true, cross: 'MIN' };
    case 'vertical':
      return { mode: 'VERTICAL', wrap: false, cross: 'MIN' };
    case 'center':
      return { mode: 'VERTICAL', wrap: false, cross: 'CENTER' };
    default:
      throw new Error(
        `footer.layout: unknown CoreFooterLayout "${leaf.choice}". Add it to ` +
          '`footerLayoutOf` in layout.ts with the direction / wrap / cross-axis ' +
          'triple that reproduces its `switch` arm in footer.dart.',
      );
  }
}

// The designer's set — `Layout=horizontal|vertical|center × Info=collapsed|expanded`
// — and the two things it added that this builder used to have nowhere to put:
// a top rule that is off by default, and a legal block under the nav band.
//
// ```text
// root (VERTICAL, gap = blockSpacing, fill = backgroundColor)
//   ├─ rule   Divider instance, full-bleed        ← `Show divider`, default OFF
//   └─ band   (VERTICAL, padding, gap = blockSpacing)
//        ├─ main      ← Layout axis flips direction / wrap / cross-axis
//        │    ├─ aside    ← `Aside` swap + `Show aside`
//        │    └─ sections ← Layout axis flips direction here too
//        │         └─ column ×3
//        └─ legal     (VERTICAL, gap = legalSpacing)
//             ├─ company-row (HORIZONTAL, gap = companyRowSpacing)
//             │    ├─ company · sep · disclosure (a `Collapsible`)
//             ├─ links       (HORIZONTAL, gap = linkRowSpacing)
//             │    └─ Link · sep · Link · sep · Link
//             └─ copyright
// ```
//
// ─── Why `band` exists, when the designer drew root → [rule, main, legal] ────
//
// Her rule is a 640-wide node inside a 640-wide root whose other children are
// 592 — i.e. it is not in the padded flow, and Figma would have made it 592 the
// moment it were. `CoreFooterStyle.defaultDividerStyle` reads that the same way
// and states it: the platform places the rule above the padded column rather
// than inside it. A frame that owns the padding is how a full-bleed sibling gets
// one, and it reproduces her four measurements exactly (root 640, rule 640,
// main 592, legal 592).
//
// The gap between rule and band is `blockSpacing`, whose own doc names the rule
// as one of the blocks it separates. With the rule hidden — the default — Figma
// skips it and the gap is unobservable, so the default rendering is the same
// either way.
//
// ─── Why the disclosure is a `Collapsible` instance ─────────────────────────
//
// `Collapsible` already draws this: a trigger row that owns its chevron, a body
// the `Expanded` axis reveals, and the `Trigger`/`Content` TEXT properties a
// designer fills. Redrawing a label + `Icon/Size=16` beside it would be a second
// disclosure with the same picture and its own drift — `core/style-contract.md`
// "합성 = 재구현 금지". So the `Info` axis picks that child's `Expanded` member,
// and the three places `Footer` diverges from the child's own defaults arrive
// through `FOOTER.fields.collapsibleStyle` (`applyForwardedCollapsibleStyle`),
// not as literals here.
//
// It sits IN the company row, hugging, because that is what the forwarded style
// says: `iconLabelGapStyle` is `space4` (a chevron beside its label, not pushed
// to the far edge of a filled row) and `contentInset` is zero. Her own drawing
// puts the paragraph one row lower, as a sibling of the company row — a shape no
// single `Collapsible` node can take, since a trigger and its content would then
// live under two different parents. The composed child is the decision the
// contract makes; this is where the canvas follows it.
function buildFooter(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = FOOTER.fields;
  const pad = f.padding;
  const titleStyle = textStyleData(f.titleTextStyle);
  const linkStyle = textStyleData(f.bodyTextStyle);
  const layoutAxis = FOOTER.axes.other.find((o) => o.enum === 'CoreFooterLayout');
  if (!layoutAxis) {
    throw new Error(
      'Footer: CoreFooterLayout is gone from the exported axes — the canvas has ' +
        'a Layout axis that nothing in the contract now backs. Restore the enum, ' +
        'or retire the axis deliberately (renames.ts) rather than letting this ' +
        'builder fold three members into one.',
    );
  }
  const combos = enumerateAxisAssignments([
    { axis: 'Layout', values: layoutAxis.members },
    { axis: 'Info', values: kFooterInfoValues },
  ]);
  const mount = mountSet(page, 'Footer', combos.map((a) => a.name), {
    // What the legacy single COMPONENT actually drew: the contract's own
    // default layout, with no legal block and so nothing for `Info` to toggle —
    // which is the collapsed pose.
    adoptLooseAs: composeVariantName([
      ['Layout', f.layout.choice],
      ['Info', restingValueOf('Info')],
    ]),
  });
  const asideHolders: FrameNode[] = [];
  const asideSwaps: InstanceNode[] = [];
  const rules: InstanceNode[] = [];
  const legals: FooterLegalRefs[] = [];
  for (const combo of combos) {
    // The direction is the member's, not the field's — that is the whole point
    // of the axis. `footerLayoutOf` still answers it, so the three arms stay one
    // reading of `footer.dart`'s `switch`.
    const layout = footerLayoutOf({ choice: combo.values['Layout'] });
    const expanded = combo.values['Info'] === kFooterInfoExpanded;
    const c = mount.getOrCreate(combo.name);
    applyPanelCompChrome(c, 'VERTICAL', lk, { gap: f.blockSpacing });
    fillData(c, lk, colorData(f.backgroundColor));
    // Preview width only — `CoreFooterStyle` carries no width, and the widget
    // asks for `width: double.infinity`, so a footer's width IS its parent's
    // constraint. Wide enough that the branding slot's placeholder and three nav
    // columns all read at once.
    // g7-preview-only: Footer preview width, no extent field in the code.
    lockWidth(c, 640);
    // Full-bleed, and off unless a designer turns it on — see the note above and
    // `CoreFooterContract.defaultShowDivider`.
    const rule = hostedDivider(page, lk, c, {
      forwarded: {
        color: colorData(f.dividerStyle.color),
        thickness: f.dividerStyle.thickness,
        indent: f.dividerStyle.indent,
        endIndent: f.dividerStyle.endIndent,
      },
    });
    rules.push(rule);
    const band = panel('band', 'VERTICAL', lk, {
      pl: pad.l, pr: pad.r, pt: pad.t, pb: pad.b, gap: f.blockSpacing,
    });
    c.appendChild(band);
    band.layoutSizingHorizontal = 'FILL';
    const main = panel('main', layout.mode, lk, { gap: f.sectionSpacing });
    main.counterAxisAlignItems = layout.cross;
    if (layout.wrap) {
      main.layoutWrap = 'WRAP';
      // `Wrap.runSpacing` — the gap BETWEEN rows once it wraps, which the widget
      // gives the same `sectionSpacing`. Figma keeps it as a second property, so
      // leaving it off would make the run gap 0 while the item gap was bound.
      main.setBoundVariable('counterAxisSpacing', lk.space(dimVal(f.sectionSpacing)));
    }
    band.appendChild(main);
    main.layoutSizingHorizontal = 'FILL';
    // `aside` (`W?`) is the contract's optional branding slot, rendered FIRST —
    // the widget builds `[?aside, ...sections]`, so a slot placed after the
    // columns would put the Figma preview in a different order than the code.
    const aside = panel('aside', 'VERTICAL', lk, {});
    const asideContent = slotStandIn(page, 'aside content', kSlotShape);
    aside.appendChild(asideContent);
    main.appendChild(aside);
    asideHolders.push(aside);
    asideSwaps.push(asideContent);
    // Its own frame, because that is what she drew — the Layout axis flips it
    // too (408×128 row → 592×432 column), and the aside sits beside or above the
    // group rather than inside it.
    //
    // The widget has ONE flow here: `layout == horizontal` is a single `Wrap`
    // over `[?aside, ...sections]`. Two frames cannot be one flow, so both carry
    // the direction, the wrap and the cross-axis value — narrowing then wraps at
    // whichever level runs out of room, which is the behaviour the single `Wrap`
    // has. Neither shows at the preview width; the seam is recorded because a
    // Figma→code reading would otherwise see two flows the code does not have.
    const sections = panel('sections', layout.mode, lk, { gap: f.sectionSpacing });
    sections.counterAxisAlignItems = layout.cross;
    if (layout.wrap) {
      sections.layoutWrap = 'WRAP';
      sections.setBoundVariable('counterAxisSpacing', lk.space(dimVal(f.sectionSpacing)));
    }
    main.appendChild(sections);
    sections.layoutSizingHorizontal = 'FILL';
    for (const col of kFooterColumns) {
      const column = panel('column', 'VERTICAL', lk, { gap: f.sectionTitleGapStyle.size });
      column.appendChild(makeLabel(col.title, lk, textLabelOpts(lk, titleStyle)));
      for (const link of col.links) {
        column.appendChild(makeLabel(link, lk, textLabelOpts(lk, linkStyle)));
      }
      sections.appendChild(column);
      column.layoutSizingHorizontal = 'FILL';
    }
    legals.push(buildFooterLegal(page, lk, band, expanded));
  }
  const set = mount.finish();
  // Defined AFTER finish(), never inside the member loop — `mount.getOrCreate`
  // hands back a standalone COMPONENT that only joins the set in finish(), so
  // `propertyOwner` would answer "the member" during the loop and "the set" on
  // the next run: the same property landing in two places depending on whether
  // the page already had the set. (Binding, too: Figma rejects a property
  // reference on a detached node — "Can only set component property references
  // on symbol sublayer" — and nothing rolls that throw back.)
  const asideProp = defineProp(set, 'Aside', 'INSTANCE_SWAP', slotStandInDefault(page, kSlotShape));
  for (const n of asideSwaps) bindSwapProp(n, asideProp);
  const showAside = defineProp(set, 'Show aside', 'BOOLEAN', true);
  for (const n of asideHolders) bindVisibleProp(n, showAside);
  // `CoreFooterContract.defaultShowDivider` is the default, not a taste call
  // here — the contract states the rule is opt-in and this is that statement
  // reaching the canvas.
  const showDivider = defineProp(
    set,
    'Show divider',
    'BOOLEAN',
    kFooterShowDividerDefault,
  );
  for (const n of rules) bindVisibleProp(n, showDivider);
  // `company` / `copyright` are `W?` slots this preview fills with a TEXT node
  // each, so each becomes a TEXT property — the same treatment `Divider`'s own
  // `W?` `child` and `Link`'s `child` get, and what turns "double-click in and
  // retype" into a slot the right-hand panel offers.
  const companyProp = defineProp(set, 'Company', 'TEXT', kFooterCompany);
  const copyrightProp = defineProp(set, 'Copyright', 'TEXT', kFooterCopyright);
  for (const legal of legals) {
    bindTextProp(legal.company, companyProp);
    bindTextProp(legal.copyright, copyrightProp);
    // `businessInfoLabel` / `businessInfo` live inside the `Collapsible`
    // INSTANCE, and a host TEXT property cannot drive a nested instance's text
    // (the limit `DatePicker`'s dialog title and `TabItem`'s count badge both
    // hit). Exposure is the mechanism Figma provides for that shape: the
    // designer edits the disclosure's own `Trigger` / `Content` one level in,
    // from this set's panel.
    try {
      legal.disclosure.isExposedInstance = true;
    } catch {
      // The document double has no exposure; the live plugin does.
    }
  }
  return set;
}

// The nodes `buildFooter` binds set-level properties to after `finish()` —
// returned rather than bound in place for the reason the note there records:
// during the member loop `propertyOwner` answers the member, not the set.
interface FooterLegalRefs {
  company: TextNode;
  copyright: TextNode;
  disclosure: InstanceNode;
}

// The legal block — company row, the composed disclosure, the link row, the
// copyright line. Split out because `buildFooter`'s member loop is already the
// nav band's, and the two read as one wall otherwise.
function buildFooterLegal(
  page: PageNode,
  lk: VarLookup,
  band: FrameNode,
  expanded: boolean,
): FooterLegalRefs {
  const f = FOOTER.fields;
  const collapsible = f.collapsibleStyle;
  const legal = panel('legal', 'VERTICAL', lk, { gap: f.legalSpacing });
  band.appendChild(legal);
  legal.layoutSizingHorizontal = 'FILL';
  const companyRow = panel('company-row', 'HORIZONTAL', lk, { gap: f.companyRowSpacing });
  // Start, not centre — the platforms start-align this row and the reason
  // travels with the composition: the disclosure is ONE `Collapsible` node
  // whose body opens INSIDE the row, so on the `Info=expanded` members a
  // centred company name would float to the vertical middle of the revealed
  // paragraph. Her drawing centres it because there the paragraph is a
  // sibling of the row, not a child — the shape the composed child cannot
  // take (see the note above `buildFooter`). Collapsed, the 26px company
  // name and the 22px trigger now top-align rather than centre: a 4px seam
  // the composition decision buys, and the price of one disclosure.
  companyRow.counterAxisAlignItems = 'MIN';
  legal.appendChild(companyRow);
  const company = makeLabel(
    kFooterCompany,
    lk,
    textLabelOpts(lk, textStyleData(f.companyTextStyle)),
  );
  company.name = 'company';
  companyRow.appendChild(company);
  footerTick(page, lk, companyRow);
  // The disclosure. `Expanded` is the `Info` axis; `Disabled`/`Focus` are asked
  // for at rest because a footer draws neither.
  const disclosure = instanceOf(
    page,
    'Collapsible',
    bestVariantName(page, 'Collapsible', {
      Expanded: expanded ? 'true' : 'false',
      Disabled: restingValueOf('Disabled'),
      Focus: restingValueOf('Focus'),
    }),
  );
  disclosure.name = 'disclosure';
  companyRow.appendChild(disclosure);
  // The child's own preview is a fixed 300 box (its `lockWidth` scaffold); in
  // this row the disclosure hugs its trigger, which is what `iconLabelGapStyle:
  // space4` describes.
  disclosure.layoutSizingHorizontal = 'HUG';
  setInstanceTextNamed(disclosure, 'Trigger', kFooterBusinessInfoLabel);
  setInstanceTextNamed(disclosure, 'Content', kFooterBusinessInfo);
  applyForwardedCollapsibleStyle(disclosure, lk, {
    contentInset: collapsible.contentInset,
    iconLabelGap: collapsible.iconLabelGapStyle.size,
    triggerTextStyle: textStyleData(collapsible.triggerTextStyle),
    contentTextStyle: textStyleData(collapsible.contentTextStyle),
  });
  // `links` is `List<W>` — a length the contract does not fix and Figma has no
  // property for, so three is the preview. (Her set carries a fourth link and a
  // fourth tick, both hidden: a spare she reveals by hand. Redrawing them hidden
  // every run would undo that reveal, which is the loop this pipeline is scarred
  // by, so the list is drawn at the length it reads at.)
  const links = panel('links', 'HORIZONTAL', lk, { gap: f.linkRowSpacing });
  links.counterAxisAlignItems = 'CENTER';
  legal.appendChild(links);
  const mutedLink = bestVariantName(page, 'Link', {
    Variant: kFooterLinkVariant,
    Underline: restingValueOf('Underline'),
    Focus: restingValueOf('Focus'),
  });
  kFooterLegalLinks.forEach((label, index) => {
    if (index > 0) footerTick(page, lk, links);
    const link = instanceOf(page, 'Link', mutedLink);
    link.name = 'link';
    links.appendChild(link);
    setInstanceTextNamed(link, 'Child', label);
  });
  const copyright = makeLabel(
    kFooterCopyright,
    lk,
    textLabelOpts(lk, textStyleData(f.copyrightTextStyle)),
  );
  copyright.name = 'copyright';
  legal.appendChild(copyright);
  return { company: company, copyright: copyright, disclosure: disclosure };
}

// The hairline tick between two inline legal items — a vertical `Divider` at the
// length `CoreFooterStyle.inlineDividerLength` states, because a divider has no
// length of its own (it takes the box it is given, and in a hugging row there is
// no box to take).
//
// `inlineDivider*`, not `divider*`: the top rule is the one named `dividerStyle`,
// and these two are told apart by WHERE the line is drawn rather than by a second
// noun for "line" (`code-style/naming.md` — 얇은 선 = `Divider` 하나).
function footerTick(page: PageNode, lk: VarLookup, host: FrameNode): InstanceNode {
  const f = FOOTER.fields;
  const tick = hostedDivider(page, lk, host, {
    vertical: true,
    size: {
      length: f.inlineDividerLength,
      thickness: f.inlineDividerStyle.thickness,
    },
    forwarded: {
      color: colorData(f.inlineDividerStyle.color),
      thickness: f.inlineDividerStyle.thickness,
      indent: f.inlineDividerStyle.indent,
      endIndent: f.inlineDividerStyle.endIndent,
    },
  });
  tick.name = 'sep';
  return tick;
}

// ─── Hero ────────────────────────────────────────────────────────────────────

// Data-driven from coui_core HERO_SECTION.fields — no variant/size dispatch
// on CoreHeroSectionStyle, and no state-keyed chrome, so no boolean state axis.
// Title/subtitle typography, the gap between them, and the CTA buttons' chrome
// have no matching CoreHeroSectionStyle field at all — only chrome-level
// padding/bg/minHeight exist on the Style; content is a caller-supplied slot
// (#3755 OQ-2).
//
// The root is a STACK, not a column. `HeroSection.build` is
// `Container(color: backgroundColor, minHeight: minHeight) > Stacks(fit:
// .passthrough) > [ if (overlayColor != null) Position.fill(ColoredBox), Center
// > Padding(padding) > child ]`, so the container places its layers by
// coordinate and the padded content is one of them. Drawn as an auto-layout
// column, the preview said the content was the container — and that is the
// structure a Figma→code direction would read back.
//
// One layer, not two: `overlayColor` has no CoreHeroSectionStyle default, so
// the widget's `if (overlayColor != null)` layer is absent by default and
// inventing a tint here would put a colour in this file that coui_core never
// chose. `backgroundColor` and `minHeight` ARE defaults, and now that the stack
// needs a definite box they are the honest source for it rather than a number
// this file picks.
//
// ONE `child` (`W`), because that is how many the widget has: `Padding` takes a
// single child and `Center` does not stretch it, so the honest picture is one
// hug-sized node floating in the middle of a `minHeight`-tall box, with
// `padding` between it and the edges.
//
// It used to be a composed group — headline, subhead, two CTA rectangles —
// behind `Title` and `Subtitle` TEXT properties. Three things were wrong with
// that and they are the same thing: it was this file's content, not the
// component's. `CoreHeroContract` has no title and no subtitle, so the
// panel offered two slots the API does not have and none of the one it does;
// the group could not be swapped, so the headline a preview happened to pick
// became the only thing a hero can ever contain; and the CTA rectangles were
// Button lookalikes that `CoreHeroSectionStyle` forwards no chrome to.
//
// So: the design system's placeholder box, and an INSTANCE_SWAP named for the
// slot. Required (`W`, never null), so no BOOLEAN beside it — a property that
// could remove the child would describe a widget that cannot be constructed.
//
// `Layout` is the only axis. `center` is the pose above. `split` is a
// horizontal pair — copy (`child`) then `media`, media trailing — with the
// gutter from `splitGapStyle`. The narrow stack (copy above media) is the
// runtime breakpoint, the same tablet threshold as `ResponsiveRowColumn`;
// the canvas shows the wide pose. `media` is not mounted on `center`.
const kHeroCenterPreviewWidth = 480;
// g7-preview-only: wide enough that the two FILL cells read as a pair.
const kHeroSplitPreviewWidth = 720;

function buildHero(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = HERO.fields;
  const layoutAxis = HERO.axes.other.find((o) => o.enum === 'CoreHeroLayout');
  if (!layoutAxis) {
    throw new Error('buildHero: coui_core exported no CoreHeroLayout axis');
  }
  const combos = enumerateAxisAssignments([
    { axis: 'Layout', values: layoutAxis.members },
  ]);
  const mount = mountSet(
    page,
    'Hero',
    combos.map((a) => a.name),
    { adoptLooseAs: composeVariantName([['Layout', f.layout.choice]]) },
  );
  const drawn = combos.map((a) => drawHeroMember(page, lk, mount, a.values.Layout));
  // Properties after finish(), on the set. A member has no set parent until
  // then, and `addComponentProperty` on a member throws.
  const set = mount.finish();
  const owner = propertyOwner(drawn[0].comp);
  const childProp = defineProp(owner, 'Child', 'INSTANCE_SWAP', slotStandInDefault(page, kSlotShape));
  const mediaProp = defineProp(owner, 'Media', 'INSTANCE_SWAP', slotStandInDefault(page, kSlotShape));
  for (const member of drawn) {
    bindSwapProp(member.child, childProp);
    if (member.media) bindSwapProp(member.media, mediaProp);
  }
  return set;
}

function drawHeroMember(
  page: PageNode,
  lk: VarLookup,
  mount: SetMount,
  layout: string,
): { comp: ComponentNode; child: InstanceNode; media: InstanceNode | null } {
  const f = HERO.fields;
  const pad = f.padding;
  const split = layout === 'split';
  const previewWidth = split ? kHeroSplitPreviewWidth : kHeroCenterPreviewWidth;
  const stackHeight = dimVal(f.minHeight);
  const name = composeVariantName([['Layout', layout]]);
  const c = mount.getOrCreate(name);
  c.layoutMode = 'NONE';
  c.resize(previewWidth, stackHeight);
  fillData(c, lk, colorData(f.backgroundColor));
  const content = panel('content', split ? 'HORIZONTAL' : 'VERTICAL', lk, {
    pl: pad.l,
    pr: pad.r,
    pt: pad.t,
    pb: pad.b,
    ...(split ? { gap: f.splitGapStyle.size } : {}),
  });
  content.primaryAxisAlignItems = 'CENTER';
  content.counterAxisAlignItems = 'CENTER';
  const child = slotStandIn(page, 'child', kSlotShape);
  content.appendChild(child);
  let media: InstanceNode | null = null;
  if (split) {
    media = slotStandIn(page, 'media', kSlotShape);
    content.appendChild(media);
    child.layoutSizingHorizontal = 'FILL';
    media.layoutSizingHorizontal = 'FILL';
  }
  c.appendChild(content);
  content.primaryAxisSizingMode = 'FIXED';
  content.counterAxisSizingMode = 'FIXED';
  content.resize(previewWidth, stackHeight);
  content.x = 0;
  content.y = 0;
  content.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };
  return { comp: c, child, media };
}

// ─── Join (segmented buttons) ────────────────────────────────────────────────

// Data-driven from coui_core JOIN.fields — no variant/size dispatch on
// CoreJoinStyle, no state-keyed chrome (so no boolean state axis), and the only
// field it carries is borderRadius (applied to the outer corners of the
// first/last cell — the same "round outer corners only" shape the literal `8`
// already encoded). Per-cell background/foreground, padding, and border have no
// matching field — CoreJoinStyle only styles the group's outer corners, not
// individual cell chrome (#3755 OQ-2).
//
// `children` is `List<W>`, so no component property (Figma has no repeated-slot
// property) — a designer adds or removes cells directly. The cells stay
// hand-drawn for the same reason HeroSection's CTAs do: they are placeholder
// content for a caller-supplied list, not a child `CoreJoinStyle` forwards
// chrome to, so instancing `Button` would assert an edge the Style does not
// declare.
function buildJoin(page: PageNode, lk: VarLookup): ComponentNode {
  const radius = JOIN.fields.borderRadius;
  const c = mintPanelComp(page, 'Join', 'HORIZONTAL', lk, {});
  // Each cell overlaps the one before it by `itemOverlap` — one border width —
  // so the seam between two bordered cells reads as a single line instead of
  // two (1 + 1). Both platforms do this (Flutter's overlapping `Flex`, Web's
  // negative inline margin), and a later cell's border paints over the earlier
  // one's; Figma's default stacking is the same (`itemReverseZIndex` off draws
  // the last child on top). A NEGATIVE `itemSpacing` is how an auto-layout row
  // overlaps its children, and it is written as a value, not bound: a
  // variable holds the positive line width, and binding `itemSpacing` to it
  // would push the cells apart by that much instead of pulling them together.
  c.itemSpacing = -dimVal(JOIN.fields.itemOverlap);
  // The representative example is the docs' `JoinInputExample` (#6573): a
  // field and a button joined into one strip. Everything about the two cells
  // except their outer corners is invented here, and there is no field
  // anywhere for it: `CoreJoinStyle` declares exactly one field
  // (`borderRadius`), and `Join.build` only clips each child to its share of
  // that radius (`ClipRRect`) — it draws no fill, no border, no padding and no
  // text style. The cells stand in for the `children: List<W>` a caller
  // passes, so a real Join's cell chrome comes from whatever those children
  // are (here `TextField` and `Button`), never from this component.
  const field = panel('input', 'HORIZONTAL', lk, {
    // g7-preview-only: demo field chrome standing in for a caller `TextField`.
    bg: 'surface', border: 'outline-variant', pl: 12, pr: 12, pt: 8, pb: 8,
  });
  field.counterAxisAlignItems = 'CENTER';
  // The docs example's `_kFieldWidth` — a `Row` gives its children unbounded
  // width, so the caller says how wide the field is.
  // g7-preview-only: demo field width standing in for the caller's `SizedBox`.
  lockWidth(field, 200);
  field.setBoundVariable('topLeftRadius', lk.radius(dimVal(radius.topLeft)));
  field.setBoundVariable('bottomLeftRadius', lk.radius(dimVal(radius.bottomLeft)));
  const placeholder = makeLabel('이메일 주소', lk, {
    // g7-preview-only: type for the demo field's invented placeholder.
    size: 14, colorVar: lk.sem('placeholder'),
  });
  placeholder.name = 'placeholder';
  field.appendChild(placeholder);
  placeholder.layoutSizingHorizontal = 'FILL';
  c.appendChild(field);

  const button = panel('button', 'HORIZONTAL', lk, {
    // g7-preview-only: demo button chrome standing in for a caller `Button`.
    bg: 'primary', pl: 16, pr: 16, pt: 8, pb: 8,
  });
  button.primaryAxisAlignItems = 'CENTER';
  button.counterAxisAlignItems = 'CENTER';
  button.setBoundVariable('topRightRadius', lk.radius(dimVal(radius.topRight)));
  button.setBoundVariable('bottomRightRadius', lk.radius(dimVal(radius.bottomRight)));
  const label = makeLabel('구독하기', lk, {
    // g7-preview-only: type for the demo button's invented label.
    size: 14, style: 'Medium', colorVar: lk.sem('on-primary'),
  });
  label.name = 'label';
  button.appendChild(label);
  c.appendChild(button);
  // The two cells share one row height, as a field and a button on the same
  // control row do (`md`, 40). The bordered field is the taller of the two
  // here, so the button stretches to it instead of hugging its label.
  button.layoutSizingVertical = 'FILL';
  return c;
}

// ─── Table ───────────────────────────────────────────────────────────────────

// Data-driven from coui_core TABLE.fields. The outer box reads `outer·BorderWidth`
// (0 draws no box: the root carries no stroke) and borderRadius; the hairline
// separators between rows read borderColor / borderWidth — the box, when a
// caller turns it on, takes the separator colour. headerPadding /
// cellPadding source the header's and body rows' padding respectively;
// headerTextStyle / cellTextStyle source their typography.
//
// Two more drawn values, and both are answered by what the data already says:
//
//   · the container's `surface` fill — `backgroundColor` IS a declared field,
//     recorded `absent`, which `absence.ts` reads as "unpainted — this role
//     contributes no colour". The widget matches that: its `DecoratedBox` takes
//     `resolved.backgroundColor`, which is null by default, so a default table
//     has no fill of its own. The root carries no fill now; the header band and
//     the state rows are the only painted surfaces, which is what both
//     platforms render.
//   · the 12 that sat between cells — the widget spends `cellPadding` per CELL
//     (`table.dart:371`, a `Container(padding: effectivePadding)` around each
//     one), so adjacent cells sit 24 apart. That number was stated data seen
//     through the wrong structure; the padding moved onto the cells, so the
//     outer edges keep their 12 and the inter-cell distance doubles.
//
// Four fields components.json files under `table` are NOT drawn here, and none
// of them is a Figma limitation. Written down because the reason differs per
// field and each one looks like an omission from the outside.
//
// The names below carry a `·` on purpose. G16 (`check_figma_unread_fields.py`)
// decides a field is read by searching `src/**/*.ts` for its name as an
// identifier, and it does not know a comment from code — so spelling these four
// out here would delete them from that gate's count and leave it green about the
// exact fields this block exists to say are undrawn. Splitting the token keeps
// the gate honest and the name greppable by prefix. (Reported in `notes`: a
// documentation pass anywhere in this repo can silence that gate by accident.)
//
//   · `resizer·Thickness` (2) · `resizer·HoverColor` · `resizer·DragColor` —
//     these belong to `ResizableTable`, not to `Table`. `Table.build` contains
//     the string "resizer" zero times (nor does `table_layout_render.dart`); the
//     handle is `_resizerVisual` in `resizable_table.dart:611`, a separate
//     widget implementing its own `CoreResizableTableContract<Widget>`. They
//     ride under this slug only because that widget's `tableStyle` IS a
//     `CoreTableStyle`. Drawing a resizer on this component would assert a
//     handle `Table` cannot produce — the same false claim `buildTable` below
//     refuses for the frozen overlay. The fix is a `ResizableTable` entry, and
//     it is blocked on that widget having no `components.json` slug of its own;
//     see `notes`.
//
//     Two of the three could not be told apart even there. `_resizerVisual`
//     reads `dragging ? <drag colour> : hovered ? <hover colour> :
//     Colors.transparent`, and Core defines the drag and hover defaults as
//     aliases of one `defaultResizerColor` (all three export as `primary` at
//     opacity 1) — so idle is invisible and hover and drag are one colour under
//     three names. An axis whose sides render identically is the knob this
//     file's header refuses to add.
//
//   · `frozenCell·BackgroundColor` (`surface`) — `Table` does read it
//     (table.dart:302), but it is defined to equal the surface it covers. Its
//     stated job is opacity, not contrast: "sticky cells layer over the table
//     surface so scrolled content doesn't bleed through", and body rows "fall
//     back to the table background colour (opaque by default via
//     `ThemeData.fromCore`)" — the same `surface`. On a canvas with nothing
//     scrolling underneath, painting it changes no pixel. It is also gated on
//     `widget.frozenCells`, which has no default, so a `Frozen` axis would
//     double this set to 16 members to show nothing.
//
// Three state axes, all from real CoreTableStyle fields:
//   · Disabled  → `disabledForegroundColor` replaces `foregroundColor` on
//     BOTH header and body text, which is what `resolveTable` does (it derives
//     `headerDisabledForegroundColor` from the same field).
//   · Hover     → `rowHoverColor` fills one demo row.
//   · Selected  → `rowSelectedColor` fills a different demo row.
// Hover and Selected paint different rows on purpose: the two are independent
// axes, and stacking them on one row would force this builder to invent a
// precedence between two fills that components.json says nothing about, while
// hiding whichever lost.
const kTableSelectedRow = 1;
const kTableHoverRow = 2;

interface TableRowOpts {
  /** Which of the widget's three row kinds this is — the branch it takes. */
  kind: 'header' | 'body' | 'footer';
  disabled: boolean;
  /** Row background for a state (hover / selected), or null for no state fill. */
  stateFill: Color | null;
}

// ─── TableHeaderCell · TableCell ────────────────────────────────────────────
//
// The Figma twins of `CoreTableCellData` — a data value whose `child` is any
// widget, with no Style of its own: every pixel a cell paints is a
// `CoreTableStyle` field (`headerPadding` / `cellPadding`, the two text styles,
// the two foregrounds). The same shape as TabItem and CommandItem: a set of its
// own so a designer puts a cell's content in through a property instead of
// detaching the table, and the table builds its rows out of these instances.
//
// Each set has one axis, `Disabled`, because the foreground is the only thing a
// cell changes with the table's state. Hover and selection paint the ROW (the
// cells tile it edge to edge — see `tableRow`), so they stay on the table.
//
// Everything past the value text is canvas structure the code states nothing
// about, because in code the cell is a widget: `Sub` (a second line under the
// value — the screens' two-line cells) and `Content` (any component in place of
// the text). Both default off, so a cell at rest draws exactly what the code
// draws for a `Text` child.
const kTableCellPreviewWidth = 120;
const kTableHeaderCellName = 'TableHeaderCell';
const kTableCellName = 'TableCell';

function tableCellForeground(disabled: boolean): ColorData | null {
  return colorData(disabled ? TABLE.fields.disabledForegroundColor : TABLE.fields.foregroundColor);
}

function buildTableHeaderCell(page: PageNode, lk: VarLookup): ComponentSetNode {
  const names = kBools.map((disabled) => flag('Disabled', disabled));
  const mount = mountSet(page, kTableHeaderCellName, names);
  const labels: TextNode[] = [];
  const pad = TABLE.fields.headerPadding;
  const textStyle = textStyleData(TABLE.fields.headerTextStyle);
  for (const disabled of kBools) {
    const c = mount.getOrCreate(flag('Disabled', disabled));
    applyPanelCompChrome(c, 'HORIZONTAL', lk, { pl: pad.l, pr: pad.r, pt: pad.t, pb: pad.b });
    c.counterAxisAlignItems = 'CENTER';
    // g7-preview-only: a third of the Table preview — the table sets each cell to FILL.
    lockWidth(c, kTableCellPreviewWidth);
    // The header's enabled colour is its text style's own (`onSurfaceSubtle`);
    // a disabled cell paints `disabledForegroundColor` over it.
    const cellStyle = disabled
      ? { ...textStyle, color: colorData(TABLE.fields.disabledForegroundColor) }
      : textStyle;
    const label = makeLabel('이름', lk, textLabelOpts(lk, cellStyle));
    label.name = 'label';
    label.textAutoResize = 'HEIGHT';
    c.appendChild(label);
    label.layoutSizingHorizontal = 'FILL';
    labels.push(label);
  }
  const set = mount.finish();
  const labelProp = defineProp(set, 'Label', 'TEXT', '이름');
  for (const n of labels) bindTextProp(n, labelProp);
  return set;
}

function buildTableCell(page: PageNode, lk: VarLookup): ComponentSetNode {
  const names = kBools.map((disabled) => flag('Disabled', disabled));
  const mount = mountSet(page, kTableCellName, names);
  const values: TextNode[] = [];
  const subs: TextNode[] = [];
  const contentSwaps: InstanceNode[] = [];
  const contentHolders: FrameNode[] = [];
  const pad = TABLE.fields.cellPadding;
  const textStyle = textStyleData(TABLE.fields.cellTextStyle);
  // The second line is the screens' caption under a value. The code has no such
  // field (the cell's child is any widget), so its role is the library's small
  // body text in the secondary foreground — the pair a two-line cell child
  // uses in the docs' examples.
  const subStyle = textStyleData({ role: 'bodyXs' });
  const subColor: ColorData = { color: 'on-surface-variant' };
  for (const disabled of kBools) {
    const c = mount.getOrCreate(flag('Disabled', disabled));
    applyPanelCompChrome(c, 'HORIZONTAL', lk, { pl: pad.l, pr: pad.r, pt: pad.t, pb: pad.b });
    c.counterAxisAlignItems = 'CENTER';
    // g7-preview-only: a third of the Table preview — the table sets each cell to FILL.
    lockWidth(c, kTableCellPreviewWidth);
    const text = panel('text', 'VERTICAL', lk, {});
    c.appendChild(text);
    text.layoutSizingHorizontal = 'FILL';
    const value = makeLabel('김코드', lk, textLabelOpts(lk, textStyle, tableCellForeground(disabled)));
    value.name = 'value';
    value.textAutoResize = 'HEIGHT';
    text.appendChild(value);
    value.layoutSizingHorizontal = 'FILL';
    values.push(value);
    const sub = makeLabel('디자이너', lk, textLabelOpts(lk, subStyle, disabled ? tableCellForeground(true) : subColor));
    sub.name = 'sub';
    sub.textAutoResize = 'HEIGHT';
    text.appendChild(sub);
    sub.layoutSizingHorizontal = 'FILL';
    sub.visible = false;
    subs.push(sub);
    const holder = panel('content', 'HORIZONTAL', lk, {});
    const swap = slotStandIn(page, 'content slot', kSlotShape);
    holder.appendChild(swap);
    c.appendChild(holder);
    holder.visible = false;
    contentHolders.push(holder);
    contentSwaps.push(swap);
  }
  const set = mount.finish();
  const valueProp = defineProp(set, 'Value', 'TEXT', '김코드');
  for (const n of values) bindTextProp(n, valueProp);
  const showSub = defineProp(set, 'Show sub', 'BOOLEAN', false);
  const subProp = defineProp(set, 'Sub', 'TEXT', '디자이너');
  for (const n of subs) {
    bindTextProp(n, subProp);
    bindVisibleProp(n, showSub);
  }
  const showContent = defineProp(set, 'Show content', 'BOOLEAN', false);
  const contentProp = defineProp(set, 'Content', 'INSTANCE_SWAP', slotStandInDefault(page, kSlotShape));
  for (const n of contentHolders) bindVisibleProp(n, showContent);
  for (const n of contentSwaps) bindSwapProp(n, contentProp);
  return set;
}

function tableRow(page: PageNode, lk: VarLookup, cells: string[], o: TableRowOpts): FrameNode {
  // Every one of the widget's branches is `header` vs NOT-header — padding, text
  // style and min-height all read `rowKind == .header ? … : …`, so a footer row
  // takes the body values (`table.dart:353-367`). Its background is the one thing
  // that differs, and that is the field this kind exists to reach.
  const header = o.kind === 'header';
  // The row spends nothing of its own — `headerPadding` / `cellPadding` go on
  // each CELL, which is where `table.dart:371` spends them, and two adjacent
  // cells' facing insets ARE the distance between them. So there is no sibling
  // gap to set either: a `gap` here would be added on top of the two insets.
  const row = panel('row', 'HORIZONTAL', lk, {});
  row.itemSpacing = 0;
  // The fill stays on the row. In the widget it is per-cell (each cell's
  // `BoxDecoration(color: background)`), but the cells tile the row edge to
  // edge, so one rect covers the same pixels — and it keeps the state fills a
  // single node a designer can find.
  if (header) fillData(row, lk, colorData(TABLE.fields.headerBackgroundColor));
  else if (o.kind === 'footer') {
    fillData(row, lk, colorData(TABLE.fields.footerBackgroundColor));
  } else if (o.stateFill) fillData(row, lk, colorData(o.stateFill));
  // Each cell is an instance of the matching cell set, so a designer edits a
  // cell's text — or swaps a component into it — on the instance. An empty
  // cell (the totals row's middle) is the instance with its text emptied: the
  // text node keeps the cell's width, so typing into it later shows.
  const setName = header ? kTableHeaderCellName : kTableCellName;
  const variant = bestVariantName(page, setName, { Disabled: String(o.disabled) });
  for (const text of cells) {
    const cell = instanceOf(page, setName, variant);
    row.appendChild(cell);
    cell.layoutSizingHorizontal = 'FILL';
    setInstanceTextNamed(cell, header ? 'Label' : 'Value', text);
  }
  return row;
}

// Half a turn, in the degrees Figma's `rotation` takes. `Transform.rotate(angle:
// value * pi)` at a settled `value` of 1 is exactly this, and the two rest states
// are the only ones a static frame has.
const kHalfTurnDegrees = 180;

// The outer box. `outer·BorderWidth` is 0 by default: borderData lays a stroke by
// colour presence, not by width, so a zero width has to skip the call and say
// "no stroke" outright. The row separators keep borderWidth.
function tableOuterBorder(c: ComponentNode | FrameNode, lk: VarLookup): void {
  if (dimVal(TABLE.fields.outerBorderWidth) > 0) {
    borderData(c, lk, colorData(TABLE.fields.borderColor), TABLE.fields.outerBorderWidth);
  } else {
    c.strokes = [];
  }
}

function tableVariantName(disabled: boolean, hover: boolean, selected: boolean): string {
  return `${flag('Disabled', disabled)}, ${flag('Hover', hover)}, ${flag('Selected', selected)}`;
}

function buildTableVariant(
  mount: SetMount,
  page: PageNode,
  lk: VarLookup,
  disabled: boolean,
  hover: boolean,
  selected: boolean,
): void {
  const c = mount.getOrCreate(tableVariantName(disabled, hover, selected));
  // Unfilled — `table.backgroundColor` is a declared field recorded `absent`
  // (see the section note). Border and radius below ARE stated.
  applyPanelCompChrome(c, 'VERTICAL', lk, {});
  tableOuterBorder(c, lk);
  bindRadiusN(c, lk, TABLE.fields.borderRadius.topLeft);
  c.clipsContent = true;
  // No material: both platforms mark the table a surface only once it paints a
  // fill, and it paints none. It states no cast either, so it takes the one a
  // style contributes — on both platforms, fill or not.
  addControlShadow(c, lk);
  // `CoreTableStyle` states no extent for the table itself. It does declare
  // `viewport·Width` / `viewport·Height`, and both are recorded absent — and
  // `absence.ts` already writes down that those two are the extent of the inner
  // scroll viewport rather than of the component root ("extents of something
  // *else*"), which is why they are not what this line stands in for. The root
  // takes its parent's constraint.
  // g7-preview-only: Table preview width, no root extent field in the code.
  lockWidth(c, 360);
  const header = tableRow(page, lk, ['이름', '역할', '상태'], {
    kind: 'header', disabled: disabled, stateFill: null,
  });
  c.appendChild(header);
  header.layoutSizingHorizontal = 'FILL';
  const data = [
    ['김코드', '개발자', '활성'],
    ['이코드', '디자이너', '활성'],
    ['박코드', '기획자', '자리 비움'],
  ];
  for (let i = 0; i < data.length; i++) {
    const sep = figma.createRectangle();
    sep.resize(360, dimVal(TABLE.fields.borderWidth));
    fillData(sep, lk, colorData(TABLE.fields.borderColor));
    c.appendChild(sep);
    sep.layoutSizingHorizontal = 'FILL';
    let stateFill: Color | null = null;
    if (selected && i === kTableSelectedRow) stateFill = TABLE.fields.rowSelectedColor;
    else if (hover && i === kTableHoverRow) stateFill = TABLE.fields.rowHoverColor;
    const row = tableRow(page, lk, data[i], { kind: 'body', disabled: disabled, stateFill: stateFill });
    c.appendChild(row);
    row.layoutSizingHorizontal = 'FILL';
  }
  // A totals row, because `CoreTableRowKind` has three values and the exemplar
  // showed two. `footerBackgroundColor` is a real fill the widget paints
  // (`table.dart:292`) and it is not the header's — reading it needed a row of
  // that kind on the canvas, and a table whose columns are text and a status has
  // a plausible total: how many rows there are.
  const footSep = figma.createRectangle();
  footSep.resize(360, dimVal(TABLE.fields.borderWidth));
  fillData(footSep, lk, colorData(TABLE.fields.borderColor));
  c.appendChild(footSep);
  footSep.layoutSizingHorizontal = 'FILL';
  const footer = tableRow(page, lk, ['3 people', '', '2 active'], {
    kind: 'footer', disabled: disabled, stateFill: null,
  });
  c.appendChild(footer);
  footer.layoutSizingHorizontal = 'FILL';
}

// CoreTableContract exposes no composition slot (rows/columns arrive as data
// records, not widgets), so Table declares no component property — its whole
// designer-facing surface is the three state axes.
function buildTable(page: PageNode, lk: VarLookup): ComponentSetNode {
  // No stack layer here, and that is not an omission. `Table.build` is
  // `DecoratedBox > Padding > ClipRRect > SizedBox > TableLayoutWidget` — it
  // never composes `Stacks`. The `Stacks(...)` calls that sit next to this
  // widget belong to `ResizableTable` (`resizable_table.dart`), a separate
  // widget that happens to share the `layout/table` directory and has no
  // registry entry of its own. G14 attributes children per directory, so it
  // reads those as Table's; drawing a layered overlay here to satisfy that
  // would put a structure on the canvas that `Table` does not have.
  //
  // "It has no Stacks call" is not on its own enough to settle this, so the
  // near miss is worth naming: the cell layout underneath really does paint in
  // three passes — regular, frozen column, frozen row — and a frozen cell
  // really does overlay the scrolled ones it covers. But both predicates are
  // read off `frozenCells`, which is nullable with no default, so the component
  // this library ships makes one pass over one layer. Rows that flow ARE its
  // structure, and a placed layer here would draw a state the default `Table`
  // cannot be in — the same false claim as an overlay it never builds, only
  // harder to catch because the widget does own the code for it.
  const names: string[] = [];
  for (const disabled of kBools) {
    for (const hover of kBools) {
      for (const selected of kBools) names.push(tableVariantName(disabled, hover, selected));
    }
  }
  const mount = mountSet(page, 'Table', names);
  for (const disabled of kBools) {
    for (const hover of kBools) {
      for (const selected of kBools) buildTableVariant(mount, page, lk, disabled, hover, selected);
    }
  }
  return mount.finish();
}

// ─── ResizableTable ──────────────────────────────────────────────────────────

// `resizable_table.dart` on both platforms, and it had no REGISTRY entry — so
// three `CoreTableStyle` fields (`resizerThickness` / `resizerHoverColor` /
// `resizerDragColor`) were read by a real widget and had no node on any canvas.
// Drawing them on `Table` would have been the wrong place and the note in
// `buildTable` says why: `Table.build` never draws a handle.
//
// The geometry is transcribed rather than invented. Each cell carries
// `Position(top: 0, right: -resizerThickness / 2, bottom: 0, width:
// resizerThickness)` — a full-height bar straddling the column boundary, so half
// of it hangs outside the cell it belongs to. `_resizerVisual` fills it
// `transparent` at rest, `resizerHoverColor` under the pointer and
// `resizerDragColor` while dragging.
//
// One axis, `Hover`, and the drag colour is deliberately not a third member:
// hovering is a state the pointer RESTS in, so a static canvas can pose it,
// while dragging exists only while a button is held. That boundary is the same
// one `figma_unread_fields_allowlist.json` draws for `resizerDragColor`.
//
// The bar hangs outside its column by half its width, which is why the root does
// not clip — `Table` clips (`c.clipsContent = true`) because rows end at its
// rounded corner; here a clipped boundary bar would lose its outer half at the
// table edge.
function resizableTableVariantName(hover: boolean): string {
  return flag('Hover', hover);
}

function buildResizableTable(page: PageNode, lk: VarLookup): ComponentSetNode {
  const names = kBools.map((hover) => resizableTableVariantName(hover));
  const mount = mountSet(page, 'ResizableTable', names);
  for (const hover of kBools) buildResizableTableVariant(mount, page, lk, hover);
  return mount.finish();
}

// Which column boundary the pointer is on. One, not all of them — the widget
// tracks a single `hoveredColumnNotifier`, so a canvas that coloured every
// boundary would show a state the controller cannot hold.
const kResizableTableHoveredBoundary = 0;

function buildResizableTableVariant(
  mount: SetMount,
  page: PageNode,
  lk: VarLookup,
  hover: boolean,
): void {
  const c = mount.getOrCreate(resizableTableVariantName(hover));
  // Same `CoreTableStyle`, same absence: `backgroundColor` never reaches
  // components.json, so the root is unpainted here too.
  applyPanelCompChrome(c, 'VERTICAL', lk, {});
  tableOuterBorder(c, lk);
  bindRadiusN(c, lk, TABLE.fields.borderRadius.topLeft);
  c.clipsContent = false;
  // g7-preview-only: ResizableTable preview width, no root extent field in the code.
  lockWidth(c, kResizableTablePreviewWidth);
  const header = tableRow(page, lk, kResizableTableColumns, {
    kind: 'header', disabled: false, stateFill: null,
  });
  c.appendChild(header);
  header.layoutSizingHorizontal = 'FILL';
  for (const row of kResizableTableRows) {
    const sep = figma.createRectangle();
    sep.resize(kResizableTablePreviewWidth, dimVal(TABLE.fields.borderWidth));
    fillData(sep, lk, colorData(TABLE.fields.borderColor));
    c.appendChild(sep);
    sep.layoutSizingHorizontal = 'FILL';
    const dataRow = tableRow(page, lk, row, { kind: 'body', disabled: false, stateFill: null });
    c.appendChild(dataRow);
    dataRow.layoutSizingHorizontal = 'FILL';
  }

  // The boundary bars, one per gap between columns. Absolute over the whole
  // height because that is what `top: 0, bottom: 0` means, and pinned STRETCH
  // vertically so they keep spanning a table a designer makes taller.
  const thickness = dimVal(TABLE.fields.resizerThickness);
  const columnWidth = kResizableTablePreviewWidth / kResizableTableColumns.length;
  for (let i = 0; i < kResizableTableColumns.length - 1; i++) {
    const bar = figma.createFrame();
    bar.name = `resizer ${i}`;
    bar.layoutMode = 'NONE';
    bar.strokes = [];
    // Transparent at rest, and only the one boundary the pointer is on takes
    // the hover colour.
    if (hover && i === kResizableTableHoveredBoundary) {
      fillData(bar, lk, colorData(TABLE.fields.resizerHoverColor));
    } else {
      bar.fills = [];
    }
    bar.resize(thickness, c.height);
    pinAbsolute(c, bar, columnWidth * (i + 1) - thickness / kResizableTableHalf, 0, {
      horizontal: 'MIN',
      vertical: 'STRETCH',
    });
  }
}

// Centring divisor for the bar's straddle (`right: -resizerThickness / 2`).
const kResizableTableHalf = 2;
const kResizableTablePreviewWidth = 360;
const kResizableTableColumns = ['이름', '역할', '상태'];
const kResizableTableRows = [
  ['김코드', '디자이너', '활성'],
  ['이코드', '개발자', '비활성'],
];

// ─── Tree ────────────────────────────────────────────────────────────────────

// Data-driven from coui_core TREE.fields. nodePadding + indent source each
// row's left inset (base inset at depth 0, plus one `indent` increment per
// nesting level), nodeMinHeight the row's floor (size/28 — nodePadding carries
// no vertical inset, so the 21 label line box is centred in it),
// iconStyle.size sources the folder/file glyph's size and chevronIconStyle.size
// the disclosure chevron's (their `via` names CoreIconSize → CoreSize, so they
// bind through the size scale, not font-size — #3754 axis fix), and
// nodeTextStyle / nodeSelectedTextStyle source the label's typography+color.
// The glyph colours have their own seats: chevronIconStyle.color (fixed,
// selected or not), leafIconStyle.color for the file glyph and
// constants.iconColor for the folder glyph.
//
// The leading glyph is the one the widget picks: `folder-open` on an expanded
// parent, `folder-closed` on a collapsed one, `file` on a leaf (`isExpanded ?
// folderOpen : folderClosed` / `file` in both `tree.dart` twins). The row's
// `trailingBuilder` slot is the `Trailing` swap at the row's end.
//
// The distance between rows is `rowSpacing`: the widget's root `Column` spaces
// its visible rows by it, outside the selected and hover faces, and the Web twin
// states the same distance. Its default is `CoreSpace.space0`, so a tree that
// states none sits flush — and the frame's `itemSpacing` is bound to that
// variable rather than left as a literal 0, so a design system that changes the
// default moves the canvas with it. Two adjacent rows are already told apart by
// their indent and by the selected row's fill.
//
// `indentLine·Thickness` (1) is stated and stays undrawn, and Figma's ability to
// stroke a left edge is not what stops it — there is no line for the thickness
// to measure. (The `·` keeps G16 counting this field; see the note in the Table
// section above for why a comment can otherwise silence that gate.)
//
// `indentLineColor` is the switch for the whole guide, not just its colour, and
// it deliberately carries no default: "Web computes `hasIndentLine =
// indentLineColor != null && depth > 0` and that one boolean gates
// `border-left-style`, `border-left-width` **and** `border-left-color` — which
// is also why [the thickness] can safely have a default while this cannot"
// (tree_style.dart). So the colour never reaches components.json, and inventing
// one here would put a value on the canvas coui_core refused to choose — the
// same call `buildHeroSection` makes about `overlayColor`.
//
// The reference platform is more emphatic still: "Flutter resolves it
// (`ResolvedTree.indentLineColor`) but its widget does not paint an indent guide
// at all, so the guide is Web-only today. That asymmetry is a
// `cross-platform/api.md` gap to close by painting the guide on Flutter, not by
// giving this field a value." Drawing a guide here would take the side Core
// names as the one to fix; see `notes`.
//
// The row has FIVE children, because that is how many the widget's `Row` has
// (tree.dart:151-192, mirrored span-for-span by the Web twin at
// web tree.dart:152-200):
//
//   [ chevron | chevron-placeholder ] iconGap [ folder | file ] labelGap label
//
// It used to have two — one glyph that was the chevron on a parent row and the
// file icon on a leaf — and collapsing the two columns into one is what left
// `chevronPlaceholderGapStyle` with nothing to bind to. Three separate values
// were invisible in that shape:
//
//   · `chevronPlaceholderGapStyle` — the leaf row's reserved chevron
//     slot. Its whole job is keeping a leaf's icon+label aligned with its
//     siblings' (`CoreTreeStyle.defaultChevronPlaceholderGapStyle`), and a row
//     that draws no icon column cannot show that.
//   · `iconGapStyle` — chevron slot ↔ folder/file icon. Undrawn, and NOT
//     reported by G16 because `accordion` has a field of the same name and the
//     gate matches identifiers document-wide; see `notes`.
//   · the folder glyph itself — the widget draws `LucideIcons.folderOpen` /
//     `folderClosed` on parent rows and `file` on leaves, and so does the row
//     now (both glyphs are in `data/icons.json`).
//
// The gaps are spacer NODES, not `itemSpacing`, because the widget spends
// them as `Gap` widgets between specific siblings rather than as a uniform
// `Row` spacing — the chevron slot, icon gap and label gap are three separate
// fields that sit between different pairs of the row's children and need not
// be equal, so one `itemSpacing` cannot express them. `itemSpacing` is pinned
// to 0 for that reason.
//
// The chevron is `chevron-down` when expanded and `chevron-right` when not,
// which is the static reading of the widget's single `chevronRight` turned by
// `expandedTurns` (0.25 → 90°). `expandedTurns` itself never reaches
// components.json, so the rotation is expressed as the glyph it lands on.
//
// Three state axes, all from real CoreTreeStyle fields:
//   · Selected → `nodeSelectedColor` fills the row, `borderRadius` rounds it,
//     and `nodeSelectedTextStyle` recolours the label. Three fields that exist
//     only for this state and had no rendering at all before.
//   · Focus    → the `clickableStyle.focusOutlineStyle` band + ring pair
//     (`rowFocusRing`).
//   · Disabled → `clickableStyle.disabledOpacity`, on the whole preview (every
//     node in the tree is disabled at once).
// Selected and Focus land on the same designated demo row, so a variant with
// both shows the ring around the selected node — the combination the widget
// actually produces when you arrow onto a selected item.
const kTreeStateRow = 2;

// ─── TreeItem ────────────────────────────────────────────────────────────────
//
// One node row as its own set — the row `Tree` draws five of, so a designer
// assembles a file tree out of instances instead of detaching the sample tree
// (the v2 kit's FileTreeItem is this row). Like `TableCell` and `TabItem` it
// has no Dart widget and no Style of its own: `CoreTreeNode` is a data value,
// and every pixel the row paints is a `CoreTreeStyle` field that `resolveTree`
// hands the row (`dataSlug: 'tree'`).
//
// Three axes, each a fact about ONE row the widget reads off the node:
//   · `Kind` — `leaf` (no children: the chevron slot is the reserved
//     placeholder and the glyph is `file`), `collapsed` / `expanded` (a parent:
//     `chevron-right` / `chevron-down`, `folder-closed` / `folder-open`).
//   · `Selected` — `nodeSelectedColor` fills the row and
//     `nodeSelectedTextStyle` recolours the label; the radius is on every row.
//   · `Depth` — `0`…`3`, the row's start inset: `nodePadding.l` plus one
//     `indent` per level, the way the widget pads `itemPadding + indent *
//     depth`. An axis rather than an instance padding override because the
//     inset is a bound variable on the member, and an override would be a
//     bare number a designer cannot trace.
//
// Properties: `Label` (the node's name), `Show trailing` + `Trailing` (the
// `trailingBuilder` slot — a `Gap(labelGapStyle)` then the caller's widget,
// with the name taking the remaining width so the trailing sits at the row's
// end). Disabled and focus stay on `Tree`: disabled dims every node at once,
// and the focus ring is the `Clickable` around the row, drawn where the tree
// places it.
const kTreeItemName = 'TreeItem';
const kTreeItemKinds = ['leaf', 'collapsed', 'expanded'] as const;
type TreeItemKind = (typeof kTreeItemKinds)[number];
// `Depth` members — the root and three nested levels, the deepest the v2
// file tree reaches.
const kTreeItemDepths = ['0', '1', '2', '3'] as const;
// g7-preview-only: the Tree preview width — `CoreTreeStyle` declares no extent field and the widget's root is `Column(mainAxisSize: .min, crossAxisAlignment: .stretch)`, so a row and the tree are as wide as their parent allows; the canvas has to pick one for the label to FILL.
const kTreePreviewWidth = 260;
// The demo name a bare row shows until a tree overrides it.
const kTreeItemLabel = 'button.dart';

function treeItemVariantName(kind: TreeItemKind, selected: boolean, depth: number): string {
  return composeVariantName([
    ['Kind', kind],
    ['Selected', String(selected)],
    ['Depth', String(depth)],
  ]);
}

// An unpainted fixed box standing in for one `Gap(gapStyle: …)` widget.
//
// Square and fill-less, which is `Gap` itself — `primitives-layout.ts#buildGap`
// binds both dimensions to `CoreGapStyle.size` and paints nothing. Not an
// INSTANCE of that component: `Gap` owns no chrome, so there is no surface here
// for a child component to be the single source of, and an instance would need
// resizing per use site plus a `needs` edge for a node that draws nothing.
// (`display-data.ts` and `form-pickers.ts` each stand a gap up the same way.)
function treeGapSpacer(name: string, lk: VarLookup, size: number | Dim): FrameNode {
  const g = figma.createFrame();
  g.name = name;
  g.layoutMode = 'NONE';
  g.fills = [];
  bindSize(g, lk, size, size);
  return g;
}

interface TreeItemNodes {
  label: TextNode;
  trailing: FrameNode;
  trailingSwap: InstanceNode;
}

function treeItemRow(
  page: PageNode,
  c: ComponentNode,
  lk: VarLookup,
  kind: TreeItemKind,
  selected: boolean,
  depth: number,
): TreeItemNodes {
  const pad = TREE.fields.nodePadding;
  const pl = dimVal(pad.l) + depth * dimVal(TREE.fields.indent);
  applyPanelCompChrome(c, 'HORIZONTAL', lk, { pl, pr: pad.r, pt: pad.t, pb: pad.b });
  // The three inter-child gaps are nodes (see the section comment), so the
  // row's own uniform spacing has to be nothing or it would be added on top of
  // each of them.
  c.itemSpacing = 0;
  c.counterAxisAlignItems = 'CENTER';
  lockWidth(c, kTreePreviewWidth);
  // The row's floor — `nodeMinHeight` (size/28) with no vertical padding
  // (`nodePadding` t/b are 0), so the 21 label line box sits centred in a 28 row.
  const minHeight = dimVal(TREE.fields.nodeMinHeight);
  const minHeightStep = lk.sizeOrNull(minHeight);
  c.minHeight = minHeight;
  if (minHeightStep) c.setBoundVariable('minHeight', minHeightStep);
  // The radius is unconditional and the FILL is what selection changes — the
  // widget puts `borderRadius: resolved.borderRadius` on every row's decoration
  // and only swaps `backgroundColor`.
  bindRadiusN(c, lk, TREE.fields.borderRadius.topLeft);
  if (selected) fillData(c, lk, colorData(TREE.fields.nodeSelectedColor));
  const labelLeaf = selected ? TREE.fields.nodeSelectedTextStyle : TREE.fields.nodeTextStyle;
  // The two glyphs have their own SIZES and their own COLOURS, and neither
  // tracks the label:
  //   · the chevron: `chevronIconStyle.size` + `chevronIconStyle.color`
  //     (`defaultChevronIconStyle` — onSurfaceSubtle), selected or not;
  //   · the folder glyph: `iconStyle.size` + `constants.iconColor`
  //     (`defaultIconColor` — onSurfaceVariant);
  //   · the file (leaf) glyph: `iconStyle.size` + `leafIconStyle.color`
  //     (`defaultLeafIconStyle` — onSurfaceSubtle).
  const chevronGlyph = glyphOpts(
    lk,
    colorData(TREE.fields.chevronIconStyle.color),
    TREE.fields.chevronIconStyle.size,
    'size',
  );
  const folderGlyph = glyphOpts(
    lk,
    colorData(TREE.constants.iconColor),
    TREE.fields.iconStyle.size,
    'size',
  );
  const fileGlyph = glyphOpts(
    lk,
    colorData(TREE.fields.leafIconStyle.color),
    TREE.fields.iconStyle.size,
    'size',
  );
  const leaf = kind === 'leaf';
  // Slot 1 — the disclosure chevron, or the gap that reserves its width.
  if (leaf) {
    c.appendChild(
      treeGapSpacer('chevron placeholder', lk, TREE.fields.chevronPlaceholderGapStyle.size),
    );
  } else {
    c.appendChild(
      makeIcon(kind === 'expanded' ? 'chevron-down' : 'chevron-right', lk, chevronGlyph),
    );
  }
  // Slot 2 — chevron slot ↔ leading icon.
  c.appendChild(treeGapSpacer('icon gap', lk, TREE.fields.iconGapStyle.size));
  // Slot 3 — the leading icon, the branch both widgets take.
  c.appendChild(
    makeIcon(
      leaf ? 'file' : kind === 'expanded' ? 'folder-open' : 'folder-closed',
      lk,
      leaf ? fileGlyph : folderGlyph,
    ),
  );
  // Slot 4 — leading icon ↔ label.
  c.appendChild(treeGapSpacer('label gap', lk, TREE.fields.labelGapStyle.size));
  // The name — one line ending in an ellipsis (`maxLines: 1`, `overflow:
  // ellipsis`), taking the width the row leaves so a trailing sits at the end.
  const label = makeLabel(kTreeItemLabel, lk, textLabelOpts(lk, textStyleData(labelLeaf)));
  label.name = 'label';
  c.appendChild(label);
  label.layoutSizingHorizontal = 'FILL';
  label.textTruncation = 'ENDING';
  label.maxLines = 1;
  // Slot 5 — `trailingBuilder`: `Gap(labelGapStyle)` then the caller's widget.
  // Hidden at rest (the widget draws nothing without a builder), and the gap
  // goes with it.
  const trailing = autoFrame('trailing', 'HORIZONTAL');
  trailing.counterAxisAlignItems = 'CENTER';
  trailing.appendChild(treeGapSpacer('trailing gap', lk, TREE.fields.labelGapStyle.size));
  const trailingSwap = slotStandIn(page, 'trailing content', kSlotShape);
  // A row-sized stand-in: the slot's own preview box is taller than the 28
  // floor, and an empty marker that grew the row would draw a row the widget
  // never lays out. The glyph's box is the row's own measure for "a mark at
  // the end".
  bindSize(trailingSwap, lk, TREE.fields.iconStyle.size, TREE.fields.iconStyle.size);
  trailing.appendChild(trailingSwap);
  trailing.visible = false;
  c.appendChild(trailing);
  return { label, trailing, trailingSwap };
}

function buildTreeItem(page: PageNode, lk: VarLookup): ComponentSetNode {
  const names: string[] = [];
  for (const kind of kTreeItemKinds) {
    for (const selected of kBools) {
      for (let depth = 0; depth < kTreeItemDepths.length; depth++) {
        names.push(treeItemVariantName(kind, selected, depth));
      }
    }
  }
  const mount = mountSet(page, kTreeItemName, names);
  const nodes: TreeItemNodes[] = [];
  for (const kind of kTreeItemKinds) {
    for (const selected of kBools) {
      for (let depth = 0; depth < kTreeItemDepths.length; depth++) {
        const c = mount.getOrCreate(treeItemVariantName(kind, selected, depth));
        nodes.push(treeItemRow(page, c, lk, kind, selected, depth));
      }
    }
  }
  const set = mount.finish();
  const labelProp = defineProp(set, 'Label', 'TEXT', kTreeItemLabel);
  const showTrailing = defineProp(set, 'Show trailing', 'BOOLEAN', false);
  const trailingProp = defineProp(
    set,
    'Trailing',
    'INSTANCE_SWAP',
    slotStandInDefault(page, kSlotShape),
  );
  for (const n of nodes) {
    bindTextProp(n.label, labelProp);
    bindVisibleProp(n.trailing, showTrailing);
    bindSwapProp(n.trailingSwap, trailingProp);
  }
  return set;
}

function treeVariantName(disabled: boolean, selected: boolean, focused: boolean): string {
  return `${flag('Disabled', disabled)}, ${flag('Selected', selected)}, ${flag('Focus', focused)}`;
}

// The sample tree — `expanded` carries `hasKids` and the disclosure state
// together, the way the widget reads them. The two `.dart` leaves at depth 2
// are what give `chevronPlaceholderGapStyle` something to measure.
const kTreeSampleNodes: ReadonlyArray<{ label: string; depth: number; kind: TreeItemKind }> = [
  { label: 'src', depth: 0, kind: 'expanded' },
  { label: 'components', depth: 1, kind: 'expanded' },
  { label: 'button.dart', depth: 2, kind: 'leaf' },
  { label: 'card.dart', depth: 2, kind: 'leaf' },
  { label: 'utils', depth: 1, kind: 'collapsed' },
];

function buildTreeVariant(
  page: PageNode,
  mount: SetMount,
  lk: VarLookup,
  disabled: boolean,
  selected: boolean,
  focused: boolean,
): void {
  const c = mount.getOrCreate(treeVariantName(disabled, selected, focused));
  // The distance between rows is `rowSpacing`, bound to its own variable —
  // zero by default, so the rows sit flush until a tree states one. See the
  // section note.
  applyPanelCompChrome(c, 'VERTICAL', lk, { gap: TREE.fields.rowSpacing });
  lockWidth(c, kTreePreviewWidth);
  // Each node row is `Clickable(child: …)` in the widget. Its visible chrome is
  // drawn here — `disabledOpacity` on the whole preview, and the focus ring
  // from `clickableStyle.focusOutlineStyle` around the stated row.
  if (disabled) c.opacity = dimVal(TREE.fields.clickableStyle.disabledOpacity);
  for (let i = 0; i < kTreeSampleNodes.length; i++) {
    const n = kTreeSampleNodes[i];
    const stated = i === kTreeStateRow;
    // Each row is a `TreeItem` instance — a designer edits a name or turns a
    // row's trailing on on the instance, and a change to the row set reaches
    // every tree.
    const row = instanceOf(
      page,
      kTreeItemName,
      treeItemVariantName(n.kind, selected && stated, n.depth),
    );
    row.name = 'node';
    setInstanceTextNamed(row, 'Label', n.label);
    if (focused && stated) {
      // The ring and its band are two absolute children pinned to the box they
      // outline, and an instance takes no children — so the focused row sits
      // in a hugging host that is exactly its box, and the pair pins to that.
      // After the FILL: the ring is measured from the settled row.
      const host = autoFrame('focusHost', 'VERTICAL');
      host.appendChild(row);
      c.appendChild(host);
      host.layoutSizingHorizontal = 'FILL';
      row.layoutSizingHorizontal = 'FILL';
      const clickable = TREE.fields.clickableStyle;
      rowFocusRing(host, lk, clickable.focusOutlineStyle, clickable.borderRadius.topLeft);
      continue;
    }
    c.appendChild(row);
    row.layoutSizingHorizontal = 'FILL';
  }
}

// CoreTreeContract's nodes arrive as data records rather than widget slots, so
// Tree declares no component property — its designer-facing surface is the
// three state axes, and each row's own is the `TreeItem` instance's.
function buildTree(page: PageNode, lk: VarLookup): ComponentSetNode {
  const names: string[] = [];
  for (const disabled of kBools) {
    for (const selected of kBools) {
      for (const focused of kBools) names.push(treeVariantName(disabled, selected, focused));
    }
  }
  const mount = mountSet(page, 'Tree', names);
  for (const disabled of kBools) {
    for (const selected of kBools) {
      for (const focused of kBools) buildTreeVariant(page, mount, lk, disabled, selected, focused);
    }
  }
  return mount.finish();
}

// ─── Resizable ───────────────────────────────────────────────────────────────

// Two resizable panes with the resizer OVERLAID on the seam. Data-driven from
// coui_core RESIZABLE.fields; the panes' own background/typography have no
// matching field — pane content isn't part of CoreResizableStyle, only the
// divider/handle chrome is (#3755 OQ-2).
//
// The root is a stack, not a row, because that is what the widget builds:
// `Stacks(clipBehavior: .none, children: [Position.fill(paneRow), line,
// handle])`. The panes fill the container by flex with **no gutter reserved**
// ("no divider gutter reserved, so the content area stays maximal"), and the
// hairline and grab handle are placed on the computed seam. Drawn as
// `pane | handle | pane` in one row — which is what this builder used to do —
// the preview gave the divider a column of layout width the widget never
// allocates, so the panes were narrower on the canvas than in the app and the
// handle could not overhang them at all.
//
// The handle is drawn now, not skipped: `_buildHandle` composes
// `Icon(LucideIcons.gripVertical)` at `handleIconSize`/`handleIconColor` inside
// a `handleBreadth × handleLength` pill filled with `handleColor`, and those
// five fields plus `handleHitExtent` had no rendering at all while it was
// absent. `dividerHitExtent` stays unconsumed on purpose — it is the invisible
// grab area of the pointer-mode divider, and a hit region has no pixels.
//
// One state axis: `isActive` (the widget's hover-or-keyboard-focus flag) swaps
// `dividerColor` → `dividerHoverColor` on the hairline AND `handleColor` →
// `dividerHoverColor` on the pill, exactly as `_buildDividerLine` /
// `_buildHandle` each do. A resizer whose hover affordance is invisible in the
// library is the one piece of this component a designer most needs to see.
const kResizablePreviewWidth = 360;
const kResizablePreviewHeight = 160;

// The set's two axes. `Orientation` is the contract's own `direction` enum
// (the data names its members); `State` is the divider's runtime posture the
// widget tracks — resting, under the pointer, being dragged, holding keyboard
// focus. State is not a Core enum (the widget keeps it in `_hoveredDivider` /
// `_draggingDivider` / `_focusedDivider`), so the canvas names the four poses —
// with the R1 names the `State` axis takes everywhere: being dragged is the
// divider's `pressed` pose.
const kResizableStates = stateAxis(['enabled', 'hover', 'focus', 'pressed']);
type ResizableState = (typeof kResizableStates)[number];

function resizableOrientations(): string[] {
  const axis = RESIZABLE.axes.other.find((o) => o.enum === 'CoreResizableDirection');
  if (!axis) throw new Error('resizable.axes no longer states CoreResizableDirection');
  return axis.members;
}

function resizableVariantName(orientation: string, state: ResizableState): string {
  return composeVariantName([
    ['State', state],
    ['Orientation', orientation],
  ]);
}

function buildResizableVariant(
  mount: SetMount,
  lk: VarLookup,
  orientation: string,
  state: ResizableState,
): { handle: FrameNode; ring: FocusRingNodes } {
  const f = RESIZABLE.fields;
  // `direction: .horizontal` lays the panes in a row — the line is vertical;
  // `.vertical` stacks them and the line runs across.
  const across = orientation === resizableOrientations()[0];
  const c = mount.getOrCreate(resizableVariantName(orientation, state));
  c.layoutMode = 'NONE';
  // `clipBehavior: .none` — the pill overflows the hairline onto both panes.
  c.clipsContent = false;
  c.fills = [];
  c.resize(kResizablePreviewWidth, kResizablePreviewHeight);

  // `Position.fill(child: paneRow)` — the `Flex` of panes, edge to edge.
  const paneRow = panel('paneRow', across ? 'HORIZONTAL' : 'VERTICAL', lk, {});
  paneRow.primaryAxisSizingMode = 'FIXED';
  paneRow.counterAxisSizingMode = 'FIXED';
  paneRow.resize(kResizablePreviewWidth, kResizablePreviewHeight);
  // A pane's inside belongs to the caller: the widget renders
  // `widget.panes[i].content` unwrapped, and every `CoreResizableStyle`
  // field describes the divider and the handle — none of them describes a pane.
  // So the two tones below are not a value this builder failed to read; they
  // are what makes the seam visible at all, since two unfilled panes would
  // leave the hairline and handle floating over nothing. The labels are the
  // same kind of stand-in for the content a caller supplies.
  // g7-preview-only: demo pane fill — the seam needs two tones to read.
  const left = panel('pane1', 'HORIZONTAL', lk, { bg: 'surface-container' });
  left.primaryAxisAlignItems = 'CENTER';
  left.counterAxisAlignItems = 'CENTER';
  // g7-preview-only: type for the invented '영역 1' standing in for content.
  left.appendChild(makeLabel('영역 1', lk, { size: 14, colorVar: lk.sem('on-surface') }));
  paneRow.appendChild(left);
  left.layoutSizingHorizontal = 'FILL';
  left.layoutSizingVertical = 'FILL';
  // g7-preview-only: demo pane fill, the second tone of the same pair.
  const right = panel('pane2', 'HORIZONTAL', lk, { bg: 'surface' });
  right.primaryAxisAlignItems = 'CENTER';
  right.counterAxisAlignItems = 'CENTER';
  // g7-preview-only: type for the invented '영역 2' standing in for content.
  right.appendChild(makeLabel('영역 2', lk, { size: 14, colorVar: lk.sem('on-surface') }));
  paneRow.appendChild(right);
  right.layoutSizingHorizontal = 'FILL';
  right.layoutSizingVertical = 'FILL';
  c.appendChild(paneRow);
  paneRow.x = 0;
  paneRow.y = 0;
  // The panes share the box (`Expanded` both sides); the seam stays centred
  // and the divider spans the cross axis (#4805).
  paneRow.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };

  // Two equal flexes, so the seam the overlays centre on is the midpoint.
  const seam = (across ? kResizablePreviewWidth : kResizablePreviewHeight) / 2;
  const crossExtent = across ? kResizablePreviewHeight : kResizablePreviewWidth;

  // `_buildDividerLine` — the divider across the seam, in the colour and
  // thickness its posture picks: dragged is the heavier `primary` line,
  // hovered the `outline` one, and resting AND focused the quiet one (a
  // focused divider keeps its resting line and wears the shared ring).
  const lineColor =
    state === 'pressed'
      ? f.dividerDraggingColor
      : state === 'hover'
        ? f.dividerHoverColor
        : f.dividerColor;
  const lineThickness = dimVal(state === 'pressed' ? f.dividerDraggingThickness : f.dividerThickness);
  // The host the ring measures from: the line's own box.
  const host = figma.createFrame();
  host.name = 'divider';
  host.layoutMode = 'NONE';
  host.fills = [];
  host.strokes = [];
  host.clipsContent = false;
  host.resize(across ? lineThickness : crossExtent, across ? crossExtent : lineThickness);
  const line = figma.createRectangle();
  line.name = 'line';
  line.resize(host.width, host.height);
  fillData(line, lk, colorData(lineColor));
  host.appendChild(line);
  line.x = 0;
  line.y = 0;
  line.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };
  c.appendChild(host);
  host.x = across ? seam - lineThickness / 2 : 0;
  host.y = across ? 0 : seam - lineThickness / 2;
  host.constraints = across
    ? { horizontal: 'CENTER', vertical: 'STRETCH' }
    : { horizontal: 'STRETCH', vertical: 'CENTER' };
  // Keyboard focus only — the ring is the shared `FocusOutline`, drawn on the
  // posture that holds focus and absent on the rest.
  // Drawn on every member and shown on `State=focus` (hidden elsewhere behind
  // `Show focus ring`, for a pose State alone cannot reach).
  const ring = focusRing(host, lk, {
    outline: f.focusOutlineStyle,
    color: colorData(f.focusOutlineStyle.borderColor),
    corner: null,
    width: host.width,
    height: host.height,
    visible: state === 'focus',
  });

  // `_buildHandle` — the pill floating over the seam. Its radius is
  // `.circular(handleBreadth / 2)`, derived from the field rather than named,
  // so it stays a true half-round if coui_core changes the breadth.
  //
  // The literal ratchet counts the halving below, because its pattern reads
  // any digit inside a radius call as a hardcoded value. Here the digit is
  // the widget's own divisor, not a design value — the breadth it halves
  // already comes from the data. Hoisting it into a local would drop the
  // count by one while removing no decision, which is the kind of win that
  // makes the metric stop meaning anything; leave it visible instead.
  const breadth = dimVal(f.handleBreadth);
  const length = dimVal(f.handleLength);
  const handle = panel('handle', 'HORIZONTAL', lk, {});
  handle.primaryAxisAlignItems = 'CENTER';
  handle.counterAxisAlignItems = 'CENTER';
  handle.primaryAxisSizingMode = 'FIXED';
  handle.counterAxisSizingMode = 'FIXED';
  fillData(handle, lk, colorData(state === 'enabled' || state === 'focus' ? f.handleColor : lineColor));
  if (across) bindSize(handle, lk, f.handleBreadth, f.handleLength);
  else bindSize(handle, lk, f.handleLength, f.handleBreadth);
  // g7-preview-only: the widget's own `/ 2` from `.circular(handleBreadth / 2)` — `resizable` states no handle radius for it to stand in for, and the breadth it halves is read data.
  bindRadiusN(handle, lk, breadth / 2);
  handle.appendChild(
    makeIcon(
      'grip-vertical',
      lk,
      glyphOpts(lk, colorData(f.handleIconColor), f.handleIconSize, 'size'),
    ),
  );
  c.appendChild(handle);
  if (across) {
    handle.x = seam - breadth / 2;
    handle.y = (kResizablePreviewHeight - length) / 2;
    handle.constraints = { horizontal: 'CENTER', vertical: 'CENTER' };
  } else {
    handle.x = (kResizablePreviewWidth - length) / 2;
    handle.y = seam - breadth / 2;
    handle.constraints = { horizontal: 'CENTER', vertical: 'CENTER' };
  }
  return { handle, ring };
}

// CoreResizableContract's panes arrive as data records, not widget slots, so
// the only component property is the handle's: `showDragHandle`, off by
// default, the contract's own default.
function buildResizable(page: PageNode, lk: VarLookup): ComponentSetNode {
  const names: string[] = [];
  for (const orientation of resizableOrientations()) {
    for (const state of kResizableStates) names.push(resizableVariantName(orientation, state));
  }
  const mount = mountSet(page, 'Resizable', names);
  const drawn: { handle: FrameNode; ring: FocusRingNodes }[] = [];
  for (const orientation of resizableOrientations()) {
    for (const state of kResizableStates) drawn.push(buildResizableVariant(mount, lk, orientation, state));
  }
  const set = mount.finish();
  const showHandle = defineProp(set, 'Show handle', 'BOOLEAN', RESIZABLE.behaviour.showDragHandle);
  const showFocus = defineShowFocusRing(set);
  for (const { handle, ring } of drawn) {
    handle.visible = RESIZABLE.behaviour.showDragHandle;
    bindVisibleProp(handle, showHandle);
    bindShowFocusRing(ring, showFocus);
  }
  return set;
}

// ─── PageHeader · PanelHeader ────────────────────────────────────────────────
//
// Data-driven from coui_core: PAGE_HEADER.fields (the three line styles, the
// three gaps, the text floor) and PANEL_HEADER.fields (the title style, the
// head's inset, the gap, the title floor). Each is one COMPONENT — neither
// contract has a variant, size or state axis, so there is no set to mount.
//
// Both heads put their text beside a trailing group and move the group under
// the text once the text would get less than its floor. That is ONE flow on
// the canvas, the way the Web twins draw it: a HORIZONTAL auto-layout that
// WRAPS, the text FILLing the row with a `minWidth` of the floor, the group
// hugging at the end. Narrower than the floor plus the group, Figma moves the
// group to the next run, at the start — the rule `HeaderWrapLayout` (Flutter)
// and `flex-wrap` over a text basis (Web) both state. One gap serves both
// directions on both platforms, so `itemSpacing` and `counterAxisSpacing` are
// bound to the same field.
//
// The floors are widths, not spacing: `minTextWidth` binds its `layout/N`
// step and `minTitleWidth` its `size/N` step, never the density rows the gaps
// read — a density does not move them in either widget.

// The copy the screen designs put in a page head.
const kPageHeaderEyebrowCopy = '워크스페이스';
const kPageHeaderTitleCopy = '설정';
const kPageHeaderDescriptionCopy = '멤버, 결제, 연동을 관리해요.';
const kPanelHeaderTitleCopy = '최근 파일';

// The page head's actions — a secondary beside the primary, the order the
// docs prescribe (the primary last, so it stays at the end in both
// arrangements).
const kPageHeaderActions: readonly { name: string; axes: Record<string, string>; copy: string }[] = [
  { name: 'action 1', axes: { Variant: 'secondary', Size: 'md' }, copy: '취소' },
  { name: 'action 2', axes: { Variant: 'primary', Size: 'md' }, copy: '변경 사항 저장' },
];
// The panel head's one action — small and quiet, so it does not raise the
// title row or compete with the page's primary: a `plain` button, no tint, that
// reads "전체 보기 >" (label in the button's own muted ink, a chevron after it).
const kPanelHeaderActionAxes = { Variant: 'plain', Size: 'sm' };
// The default `kPanelHeaderActionAxes` supersedes: what a file generated before
// the head took its `plain` action still holds in the `Action` swap.
const kPanelHeaderRetiredActionAxes = { Variant: 'ghost', Size: 'sm' };
// g7-preview-only: the widget takes any `action` and states no default one, so no field carries the trailing chevron's step.
const kPanelHeaderActionGlyphStep = 14;

// A line of a head's text block: filling the block's width and wrapping in
// it, as `Text` does in the widgets' text column.
function headerLine(
  parent: FrameNode | ComponentNode,
  copy: string,
  lk: VarLookup,
  style: Parameters<typeof textStyleData>[0],
  name: string,
): TextNode {
  const line = makeLabel(copy, lk, textLabelOpts(lk, textStyleData(style)));
  line.name = name;
  line.textAutoResize = 'HEIGHT';
  parent.appendChild(line);
  line.layoutSizingHorizontal = 'FILL';
  return line;
}

// The row both heads share: wrapping, one gap both ways, the trailing group's
// alignment against the text stated by the caller (bottoms for a page head,
// centres for a panel head).
function headerRow(c: ComponentNode, lk: VarLookup, gap: Dim, align: 'MAX' | 'CENTER'): void {
  c.layoutMode = 'HORIZONTAL';
  c.layoutWrap = 'WRAP';
  c.primaryAxisSizingMode = 'FIXED';
  c.counterAxisSizingMode = 'AUTO';
  c.fills = [];
  c.counterAxisAlignItems = align;
  bindSpaceField(c, 'itemSpacing', lk, dimVal(gap));
  c.setBoundVariable('counterAxisSpacing', lk.space(dimVal(gap)));
}

// ```text
// PageHeader (VERTICAL · gap textSpacing · fills its 640 preview width)
//   ├─ eyebrow     (eyebrowTextStyle — `Show eyebrow`)
//   ├─ title row   (HORIZONTAL · WRAP · gap textActionsSpacing both ways · centred)
//   │    ├─ title   (VERTICAL · FILL · minWidth minTextWidth)
//   │    │    └─ title (titleTextStyle)
//   │    └─ actions (HORIZONTAL · WRAP · gap actionSpacing both ways · centred · `Show actions`)
//   │         ├─ action 1 (Button secondary md)
//   │         └─ action 2 (Button primary md)
//   └─ description (descriptionTextStyle · FILL · wraps — `Show description`, off)
// ```
//
// At rest the component draws the head the screen designs use — an eyebrow
// over the title, and a secondary + primary pair on the title's line. The
// sentence under the line is off; turning it on is one toggle. The title sits
// in a frame of its own because the floor has to: Figma binds a variable to a
// frame's `minWidth` and refuses it on a TEXT node.
function buildPageHeader(page: PageNode, lk: VarLookup): ComponentNode {
  const f = PAGE_HEADER.fields;
  const c = mint(page, 'PageHeader');
  c.layoutMode = 'VERTICAL';
  c.primaryAxisSizingMode = 'AUTO';
  c.counterAxisSizingMode = 'FIXED';
  c.fills = [];
  bindSpaceField(c, 'itemSpacing', lk, dimVal(f.textSpacing));
  // The widget states no width — a head fills the column it is placed in.
  // g7-preview-only: PageHeader preview width, no extent field in the code.
  lockWidth(c, 640);
  const owner = propertyOwner(c);
  // Placed before their children exist: `bindTextProp` below writes
  // `componentPropertyReferences`, which Figma rejects on a node with no
  // COMPONENT ancestor.
  const eyebrow = headerLine(c, kPageHeaderEyebrowCopy, lk, f.eyebrowTextStyle, 'eyebrow');
  const row = autoFrame('title row', 'HORIZONTAL');
  c.appendChild(row);
  row.layoutSizingHorizontal = 'FILL';
  row.layoutWrap = 'WRAP';
  row.counterAxisAlignItems = 'CENTER';
  bindSpaceField(row, 'itemSpacing', lk, dimVal(f.textActionsSpacing));
  row.setBoundVariable('counterAxisSpacing', lk.space(dimVal(f.textActionsSpacing)));
  const titleBlock = autoFrame('title', 'VERTICAL');
  row.appendChild(titleBlock);
  titleBlock.layoutSizingHorizontal = 'FILL';
  titleBlock.minWidth = dimVal(f.minTextWidth);
  titleBlock.setBoundVariable('minWidth', lk.layout(dimVal(f.minTextWidth)));
  const title = headerLine(titleBlock, kPageHeaderTitleCopy, lk, f.titleTextStyle, 'title');
  // `actions` is a `List<W>`, which no component property can be — the two
  // Buttons are the list the designs draw, exposed so a designer changes
  // their variant or copy on the head's own panel. An empty list draws no
  // group, so the toggle hides the group frame, and the row's gap with it.
  const actions = panel('actions', 'HORIZONTAL', lk, { gap: f.actionSpacing });
  actions.counterAxisAlignItems = 'CENTER';
  actions.layoutWrap = 'WRAP';
  actions.setBoundVariable('counterAxisSpacing', lk.space(dimVal(f.actionSpacing)));
  row.appendChild(actions);
  const buttons: InstanceNode[] = [];
  for (const a of kPageHeaderActions) {
    const button = instanceOf(page, 'Button', bestVariantName(page, 'Button', a.axes));
    button.name = a.name;
    actions.appendChild(button);
    setInstanceTextNamed(button, 'Child', a.copy);
    buttons.push(button);
  }
  // Under the title line at the head's full width, so it wraps there.
  const description = headerLine(
    c,
    kPageHeaderDescriptionCopy,
    lk,
    f.descriptionTextStyle,
    'description',
  );
  bindTextProp(eyebrow, defineProp(owner, 'Eyebrow', 'TEXT', kPageHeaderEyebrowCopy));
  bindVisibleProp(eyebrow, defineProp(owner, 'Show eyebrow', 'BOOLEAN', true));
  bindTextProp(title, defineProp(owner, 'Title', 'TEXT', kPageHeaderTitleCopy));
  bindTextProp(description, defineProp(owner, 'Description', 'TEXT', kPageHeaderDescriptionCopy));
  bindVisibleProp(description, defineProp(owner, 'Show description', 'BOOLEAN', false));
  bindVisibleProp(actions, defineProp(owner, 'Show actions', 'BOOLEAN', true));
  exposeAll(buttons);
  return c;
}

// ```text
// PanelHeader (HORIZONTAL · WRAP · padding · gap titleActionSpacing both ways · centred)
//   ├─ title (VERTICAL · FILL · minWidth minTitleWidth)
//   │    └─ title (titleTextStyle)
//   └─ action (the slot — `Action` swap · `Show action`)
//        └─ Button plain sm
// ```
//
// The title sits in a frame of its own because the floor has to: Figma binds
// a variable to a frame's `minWidth` and refuses it on a TEXT node.
function buildPanelHeader(page: PageNode, lk: VarLookup): ComponentNode {
  const f = PANEL_HEADER.fields;
  const c = mint(page, 'PanelHeader');
  headerRow(c, lk, f.titleActionSpacing, 'CENTER');
  bindPad(c, lk, f.padding);
  // The widget states no width — a panel head fills its panel.
  // g7-preview-only: PanelHeader preview width, no extent field in the code.
  lockWidth(c, 400);
  const owner = propertyOwner(c);
  const titleBlock = autoFrame('title', 'VERTICAL');
  c.appendChild(titleBlock);
  titleBlock.layoutSizingHorizontal = 'FILL';
  titleBlock.minWidth = dimVal(f.minTitleWidth);
  titleBlock.setBoundVariable('minWidth', lk.size(dimVal(f.minTitleWidth)));
  const title = headerLine(titleBlock, kPanelHeaderTitleCopy, lk, f.titleTextStyle, 'title');
  bindTextProp(title, defineProp(owner, 'Title', 'TEXT', kPanelHeaderTitleCopy));
  const holder = autoFrame('action', 'HORIZONTAL');
  c.appendChild(holder);
  const actionVariant = bestVariantName(page, 'Button', kPanelHeaderActionAxes);
  const action = instanceOf(page, 'Button', actionVariant);
  holder.appendChild(action);
  setInstanceTextNamed(action, 'Child', '전체 보기');
  // The chevron after the label, in the label's own muted ink.
  setInstanceBoolNamed(action, 'Show trailing', true);
  setSlotIcon(
    action,
    'Trailing',
    iconMainIdAt(page, kPanelHeaderActionGlyphStep),
    'chevron-right',
    // g7-preview-only: no field carries the default action's chevron ink — it matches the plain button's own muted label.
    glyphPaint(lk, { colorVar: lk.sem('on-surface-variant') }),
  );
  // `defineProp` leaves an existing swap default alone unless it names the
  // exact id it replaces, so without `replaces` a file generated while the
  // action was `ghost` `sm` keeps that Button as the slot's default however
  // often it is redrawn. A designer's own pick is any other id, and stays.
  bindSwapProp(
    action,
    defineProp(owner, 'Action', 'INSTANCE_SWAP', {
      id: mainIdOf(page, 'Button', actionVariant),
      replaces: mainIdOf(page, 'Button', bestVariantName(page, 'Button', kPanelHeaderRetiredActionAxes)),
    }),
  );
  bindVisibleProp(holder, defineProp(owner, 'Show action', 'BOOLEAN', true));
  return c;
}

// ─── BottomActionBar ─────────────────────────────────────────────────────────
//
// The action area docked under a screen: an optional note over one or two
// Buttons, on a filled surface with a hairline along its top edge.
//
// ```text
// BottomActionBar  Layout=vertical|horizontal
//   (VERTICAL · gap 0 · no padding · functional surface · fill = backgroundColor)
//   ├─ divider  RECTANGLE in flow, FILL width, height = dividerWidth   ← `Show divider`
//   └─ band     (VERTICAL · padding · gap = spacing · FILL)
//        ├─ description  TEXT (descriptionTextStyle · descriptionTextAlign)
//        │                                      ← `Description` · `Show description`, off
//        └─ actions  (VERTICAL: primary, secondary | HORIZONTAL: secondary, primary)
//             ├─ primary    Button primary xl, FILL            ← `Primary action`
//             └─ secondary  Button ghost lg, FILL    ← `Secondary action` · `Show secondary`
// ```
//
// The axis is `Layout` and nothing else: the bar has no variant, size or state
// of its own, and the Buttons inside it are the caller's. `vertical` comes first
// because the member Figma instances by default is the first one, and the
// contract's `defaultLayout` is `vertical`.
//
// ─── The hairline is a rectangle in the flow ─────────────────────────────────
//
// Both widgets draw it as BORDER chrome on top of the bar (Flutter
// `Border(top:)` inside a `Container`, Web `border-top`), so it takes layout
// height: the content starts at the line's width PLUS the padding. A rectangle
// in the flow reproduces that, and hiding it with `Show divider` then leaves
// exactly the padding — which is what the widgets do with `showDivider: false`.
// It is a rectangle and not a stroke because a component property can switch a
// node's visibility and not a stroke. Its height binds to the stroke step the
// field names (`bindStrokeAxis`), so a surface style that raises the line's
// minimum reaches it as it reaches the widgets.
//
// ─── Why the root carries no padding ─────────────────────────────────────────
//
// The padding belongs to the band under the hairline, as in the widgets (the
// `Padding` sits below the border). On the root it would also inset the line,
// and the line runs the full width of the bar.
//
// ─── The device's bottom safe area is not drawn ──────────────────────────────
//
// The widgets add the home indicator's inset to the padding's bottom edge. That
// inset is the device's, supplied by the host at run time — there is no field
// and no token for it — so a canvas that drew it would be drawing one device.
// The band's bottom padding is `padding.b` alone; the surface a designer sees
// is the bar without a home indicator under it.
//
// ─── One Secondary Button for both members ───────────────────────────────────
//
// `Secondary action` is an INSTANCE_SWAP property, and a set has ONE default for
// it. Binding it puts that default in place of every bound instance's main
// (measured in Figma, see `afterBindsLand`), so the two members cannot hold two
// different Buttons behind one property: a `ghost` `xl` in the row and a
// `ghost` `lg` in the column would both come out as whichever the default names.
// The default is the column's — the member the canvas opens on, and the pose the
// docs show — so the row's secondary is the same `lg` Button beside the
// primary's `xl`. The row centres its cells (`counterAxisAlignItems`) exactly
// because the Buttons are the caller's own and their heights may differ; a
// designer who wants two `xl` in the row swaps that one instance.
//
// ─── The surface is a functional one ─────────────────────────────────────────
//
// Both widgets mark the bar as a functional surface that the page scrolls
// behind (`bottom_action_bar_style.dart` reads `surfaceFor(.functional)`, the
// Web twin `webSurfaceMarkerFor(.functional)`), so the fill is painted through
// `applySurfaceMaterial` and not as a plain fill. The corners are square.
const kBottomActionBarDescriptionCopy = '계속하면 이용약관에 동의하게 돼요.';
const kBottomActionBarPrimaryCopy = '계속';
const kBottomActionBarSecondaryCopy = '나중에';
// The Buttons the preview is drawn with — the pair the docs' default example
// passes, and named by axis so a Button axis that grows cannot move the pick.
const kBottomActionBarPrimaryAxes = {
  Variant: 'primary',
  Size: 'xl',
  State: 'enabled',
  Shape: 'rectangle',
};
// The compact summary row's primary keeps its label's width, so it is drawn a
// size down — the size the designer's row states.
const kBottomActionBarCompactPrimaryAxes = {
  ...kBottomActionBarPrimaryAxes,
  Size: 'lg',
};
const kBottomActionBarSecondaryAxes = {
  Variant: 'ghost',
  Size: 'lg',
  State: 'enabled',
  Shape: 'rectangle',
};
// The row arrangements draw the secondary as a `secondary` `xl` Button (the
// primary's own height, so the two cells read as one row); the icon-only
// arrangement draws it square.
const kBottomActionBarRowSecondaryAxes = {
  Variant: 'secondary',
  Size: 'xl',
  State: 'enabled',
  Shape: 'rectangle',
};
const kBottomActionBarIconSecondaryAxes = {
  Variant: 'secondary',
  Size: 'xl',
  State: 'enabled',
  Shape: 'square',
};
// Display copy for the new arrangements — what the preview shows, not chrome.
const kBottomActionBarWeightedSecondaryCopy = '장바구니';
const kBottomActionBarSummaryLabelCopy = '총 금액';
const kBottomActionBarSummaryValueCopy = '64,000원';

// `CoreBottomActionBarLayout` member → the direction its actions run. Throws on
// a member it does not know, so a third arrangement surfaces as a failed build
// and not as a column that quietly stands in for it.
function bottomActionBarDirectionOf(member: string): 'HORIZONTAL' | 'VERTICAL' {
  switch (member) {
    case 'vertical':
      return 'VERTICAL';
    case 'horizontal':
    case 'weighted':
    case 'icon':
    case 'summary':
    case 'summaryCompact':
      return 'HORIZONTAL';
    default:
      throw new Error(
        `bottom_action_bar.layout: unknown CoreBottomActionBarLayout "${member}". Add it ` +
          'to `bottomActionBarDirectionOf` in layout.ts with the direction its `switch` ' +
          'arm in bottom_action_bar.dart gives the actions.',
      );
  }
}

// `CoreTextAlign` → the horizontal alignment Figma paints the note with. The
// note is a text node of its own, so the alignment is the node's, not its
// frame's. Throws on a member it does not know, so a new alignment surfaces as
// a failed build and not as a left-aligned note.
function bottomActionBarNoteAlignOf(choice: string): 'LEFT' | 'CENTER' | 'RIGHT' | 'JUSTIFIED' {
  switch (choice) {
    case 'left':
    case 'start':
      return 'LEFT';
    case 'center':
      return 'CENTER';
    case 'right':
    case 'end':
      return 'RIGHT';
    case 'justify':
      return 'JUSTIFIED';
    default:
      throw new Error(`bottom_action_bar.descriptionTextAlign: unknown choice "${choice}"`);
  }
}

function buildBottomActionBar(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = BOTTOM_ACTION_BAR.fields;
  const layoutAxis = BOTTOM_ACTION_BAR.axes.other.find(
    (o) => o.enum === 'CoreBottomActionBarLayout',
  );
  if (!layoutAxis) {
    throw new Error(
      'BottomActionBar: CoreBottomActionBarLayout is gone from the exported axes — the ' +
        'canvas has a Layout axis that nothing in the contract now backs. Restore the ' +
        'enum, or retire the axis deliberately (renames.ts) rather than letting this ' +
        'builder fold the arrangements into one.',
    );
  }
  const combos = enumerateAxisAssignments([{ axis: 'Layout', values: layoutAxis.members }]);
  const mount = mountSet(page, 'BottomActionBar', combos.map((a) => a.name));
  const primaryVariant = bestVariantName(page, 'Button', kBottomActionBarPrimaryAxes);
  const compactPrimaryVariant = bestVariantName(page, 'Button', kBottomActionBarCompactPrimaryAxes);
  const rules: RectangleNode[] = [];
  const notes: TextNode[] = [];
  const primaries: InstanceNode[] = [];
  const secondaries: InstanceNode[] = [];
  const rowSecondaries: InstanceNode[] = [];
  const summaryLabels: TextNode[] = [];
  const summaryValues: TextNode[] = [];
  for (const combo of combos) {
    const direction = bottomActionBarDirectionOf(combo.values['Layout']);
    const c = mount.getOrCreate(combo.name);
    applyPanelCompChrome(c, 'VERTICAL', lk, {});
    // The hairline and the band stack with nothing between them: the line is
    // the bar's first row, not a sibling the padding spaces.
    c.itemSpacing = 0;
    applySurfaceMaterial(c, lk, colorData(f.backgroundColor), 'functional', { radius: null });
    // The widgets state no width — a bar fills the screen it is docked to.
    // g7-preview-only: BottomActionBar preview width, a phone screen; no extent field in the code.
    lockWidth(c, 402);

    // Sized and bound before it joins the flow, set to FILL after: `resize`
    // makes an auto-layout child FIXED, and FILL is what makes it span the bar.
    const rule = figma.createRectangle();
    rule.name = 'divider';
    rule.resize(c.width, dimVal(f.dividerWidth));
    bindStrokeAxis(rule, lk, 'height', f.dividerWidth);
    fillData(rule, lk, colorData(f.dividerColor));
    c.appendChild(rule);
    rule.layoutSizingHorizontal = 'FILL';
    rules.push(rule);

    const band = panel('band', 'VERTICAL', lk, { gap: f.spacing });
    bindPad(band, lk, f.padding);
    c.appendChild(band);
    band.layoutSizingHorizontal = 'FILL';

    // `Text` in the widgets takes `descriptionTextStyle` through the ambient
    // text style and stretches across the column, so the note fills the band
    // and wraps in it.
    const note = makeLabel(
      kBottomActionBarDescriptionCopy,
      lk,
      textLabelOpts(lk, textStyleData(f.descriptionTextStyle)),
    );
    note.name = 'description';
    note.textAutoResize = 'HEIGHT';
    note.textAlignHorizontal = bottomActionBarNoteAlignOf(f.descriptionTextAlign.choice);
    band.appendChild(note);
    note.layoutSizingHorizontal = 'FILL';
    // Absent by default, like the slot in the code.
    note.visible = false;
    notes.push(note);

    const actions = panel('actions', direction, lk, { gap: f.spacing });
    // The row centres its cells, stated rather than left to the platforms'
    // different defaults (a Flutter `Row` centres, a Web flex row stretches).
    if (direction === 'HORIZONTAL') actions.counterAxisAlignItems = 'CENTER';
    band.appendChild(actions);
    actions.layoutSizingHorizontal = 'FILL';
    const layout = combo.values['Layout'];
    const compact = layout === 'summaryCompact';
    const primary = instanceOf(page, 'Button', compact ? compactPrimaryVariant : primaryVariant);
    primary.name = 'primary';
    setInstanceTextNamed(primary, 'Child', kBottomActionBarPrimaryCopy);
    // The compact row's `lg` primary is another Button than the swap's `xl`
    // default — binding it would put that default in its place — so it is
    // swapped on the instance itself, like the column's secondary.
    if (!compact) primaries.push(primary);

    if (layout === 'summary' || compact) {
      // The summary keeps the width of its words (caption over figure), the
      // primary takes the rest; the secondary action is not drawn. The
      // compact row swaps the two: the summary takes the rest and the
      // primary keeps its label's width at the end.
      const summary = panel('summary', 'VERTICAL', lk, {});
      summary.itemSpacing = 0;
      actions.appendChild(summary);
      summary.layoutSizingHorizontal = compact ? 'FILL' : 'HUG';
      const summaryLabel = makeLabel(
        kBottomActionBarSummaryLabelCopy,
        lk,
        textLabelOpts(lk, textStyleData(f.summaryLabelTextStyle)),
      );
      summaryLabel.name = 'Summary label';
      summary.appendChild(summaryLabel);
      summaryLabel.layoutSizingHorizontal = 'HUG';
      summaryLabels.push(summaryLabel);
      const summaryValue = makeLabel(
        kBottomActionBarSummaryValueCopy,
        lk,
        textLabelOpts(lk, textStyleData(f.summaryValueTextStyle)),
      );
      summaryValue.name = 'Summary value';
      summary.appendChild(summaryValue);
      summaryValue.layoutSizingHorizontal = 'HUG';
      summaryValues.push(summaryValue);
      actions.appendChild(primary);
      primary.layoutSizingHorizontal = compact ? 'HUG' : 'FILL';
      continue;
    }

    // The column's secondary is the quiet ghost `lg`; the rows' is a
    // `secondary` `xl`, square in the icon-only arrangement.
    const secondaryAxes =
      layout === 'vertical'
        ? kBottomActionBarSecondaryAxes
        : layout === 'icon'
          ? kBottomActionBarIconSecondaryAxes
          : kBottomActionBarRowSecondaryAxes;
    const secondary = instanceOf(page, 'Button', bestVariantName(page, 'Button', secondaryAxes));
    secondary.name = 'secondary';
    if (layout === 'icon') {
      // Icon-only: no label, the square carries the glyph.
      hideInstanceLabel(secondary);
    } else {
      setInstanceTextNamed(
        secondary,
        'Child',
        layout === 'weighted' ? kBottomActionBarWeightedSecondaryCopy : kBottomActionBarSecondaryCopy,
      );
    }
    // The column puts the primary first, the row puts it last — the order the
    // widget builds each in.
    for (const action of direction === 'VERTICAL' ? [primary, secondary] : [secondary, primary]) {
      actions.appendChild(action);
      // The column and the equal-width row give each action its cell; the
      // weighted and icon rows keep the secondary at its own width and let
      // the primary take the rest.
      action.layoutSizingHorizontal =
        action === secondary && (layout === 'weighted' || layout === 'icon') ? 'HUG' : 'FILL';
    }
    secondaries.push(secondary);
    // Only the members whose secondary is the same Button can share one swap
    // property — a set has ONE default for it (see the header).
    if (layout === 'horizontal' || layout === 'weighted') rowSecondaries.push(secondary);
  }
  const set = mount.finish();
  // Defined AFTER finish(), never inside the member loop — see `buildFooter`.
  const primaryProp = defineProp(
    set,
    'Primary action',
    'INSTANCE_SWAP',
    mainIdOf(page, 'Button', primaryVariant),
  );
  for (const n of primaries) bindSwapProp(n, primaryProp);
  // One swap for the contract's one `secondaryAction` slot, and a set has ONE
  // default for it: the rows' `secondary` `xl` Button, which the horizontal and
  // weighted members share. The column's quiet ghost `lg` and the icon-only
  // square are other Buttons — binding them would put this default in their
  // place — so they are swapped on the instance itself.
  // The default this one supersedes is the column's `ghost` `lg` — what the set
  // held before the rows had their own `secondary` `xl`. `defineProp` leaves an
  // existing swap default alone unless it names the exact id it replaces, so a
  // file generated before the change keeps the old Button on the row slots.
  const secondaryProp = defineProp(set, 'Secondary action', 'INSTANCE_SWAP', {
    id: mainIdOf(page, 'Button', bestVariantName(page, 'Button', kBottomActionBarRowSecondaryAxes)),
    replaces: mainIdOf(page, 'Button', bestVariantName(page, 'Button', kBottomActionBarSecondaryAxes)),
  });
  for (const n of rowSecondaries) bindSwapProp(n, secondaryProp);
  // The summary's two lines are `W?` slots like the note: TEXT properties.
  const summaryLabelProp = defineProp(
    set,
    'Summary label',
    'TEXT',
    kBottomActionBarSummaryLabelCopy,
  );
  for (const n of summaryLabels) bindTextProp(n, summaryLabelProp);
  const summaryValueProp = defineProp(
    set,
    'Summary value',
    'TEXT',
    kBottomActionBarSummaryValueCopy,
  );
  for (const n of summaryValues) bindTextProp(n, summaryValueProp);
  // `secondaryAction` is `W?`: absent, its cell is not drawn and a lone primary
  // fills the row.
  const showSecondary = defineProp(set, 'Show secondary', 'BOOLEAN', true);
  for (const n of secondaries) bindVisibleProp(n, showSecondary);
  // `description` is `W?` and absent by default; the canvas fills it with a
  // text node, so it is a TEXT property beside its toggle.
  const descriptionProp = defineProp(set, 'Description', 'TEXT', kBottomActionBarDescriptionCopy);
  for (const n of notes) bindTextProp(n, descriptionProp);
  const showDescription = defineProp(set, 'Show description', 'BOOLEAN', false);
  for (const n of notes) bindVisibleProp(n, showDescription);
  // `CoreBottomActionBarContract.defaultShowDivider` — the contract's own
  // default reaching the canvas.
  const showDivider = defineProp(
    set,
    'Show divider',
    'BOOLEAN',
    BOTTOM_ACTION_BAR.behaviour.showDivider,
  );
  for (const n of rules) bindVisibleProp(n, showDivider);
  return set;
}

// ─── SwipeActions ────────────────────────────────────────────────────────────
//
// A list row that slides sideways to uncover the actions behind it: `child` (the
// row) over a platter on each side, where a platter is the strip the row uncovers
// and holds that side's actions as cells. A cell is the action's `Button` (a
// circle as wide as the cell) with the action's label under it.
//
// ```text
// SwipeActions  Enabled × Pose=closed | openLeading | openTrailing   (no auto-layout · clips · one row big)
//   ├─ platter  leading | trailing  (HORIZONTAL · inset platterInset · gap actionSpacing · fill platterColor)
//   │    └─ action × n  (VERTICAL · actionWidth wide · gap labelGapStyle)
//   │         ├─ button  Button circle, in the action's variant
//   │         └─ label   labelStyle · one line · centred                         ← `Show labels`
//   └─ row   (the `Child` swap, filling a box the size of the set)
// ```
//
// The first action of a side is the outermost one, so the trailing platter lists
// its cells right-to-left in declaration order and the leading one left-to-right.
//
// ─── The poses are the places a row rests ────────────────────────────────────
//
// `CoreSwipeOutcome` names where a released row ends up. Its two execute members
// are what a release DOES — the first action runs, then the row is back at rest —
// and the contract marks them `@behaviourOnly`, so the exporter leaves them off
// `members` and this set draws what a designer can place a row at: closed, and
// open on either side. A closed row draws no platter: the widget clips each one
// to the width the row has uncovered, and that is nothing.
//
// ─── The platter is as wide as the strip the row uncovers ────────────────────
//
// `CoreSwipeActionsStyle.extentFor` states the width — an inset at each end, a cell
// per action and a spacing between them — and the row stands exactly that far
// along. The plugin reads no Dart, so the sum is restated here; the registry-runtime
// harness replays every `extent` row of the shared vector table through it.
//
// ─── What the canvas does not draw ───────────────────────────────────────────
//
// The first cell scaled by `fullSwipeScale` exists only while a pull is past the
// full-swipe threshold, which no resting pose is; the builder reads the field to
// refuse a default it has no picture of. Right-to-left is the platforms' mirror of
// the same picture. A density other than the standard one moves the cells and the
// Buttons but not the platter's width, which is the standard strip.
type SwipeActionsSide = 'leading' | 'trailing';

interface SwipeActionDemo {
  label: string;
  glyph: string;
  /** A `CoreSwipeActionVariant` member. */
  variant: string;
}

// The Button rung every action is drawn with: its `Size` member and the glyph's size.
interface SwipeActionsRung {
  size: string;
  glyph: Dim;
}

// What the members hand back to be bound once the set exists: the labels `Show
// labels` hides, the Buttons that are exposed, and the rows the `Child` swap points at.
interface SwipeActionsDrawn {
  labels: TextNode[];
  buttons: InstanceNode[];
  rows: InstanceNode[];
}

// What the preview's platters hold: one plain action on the leading side, and a
// destructive one beside a plain one on the trailing side — the first action of a
// side is the outermost, and a destructive one is the first thing a full swipe
// should run.
const kSwipeActionsLeading: readonly SwipeActionDemo[] = [
  { label: '즐겨찾기', glyph: 'star', variant: 'defaultVariant' },
];
const kSwipeActionsTrailing: readonly SwipeActionDemo[] = [
  { label: '삭제', glyph: 'x', variant: 'destructive' },
  { label: '보관', glyph: 'inbox', variant: 'defaultVariant' },
];
// g7-preview-only: the row the preview is drawn on — the box the shared gesture table replays on; the widget states no row size, the row is the caller's.
const kSwipeActionsRowWidth = 400;
// g7-preview-only: the row's height, same box as the width above.
const kSwipeActionsRowHeight = 72;

/** `CoreSwipeActionsStyle.extentFor`: the strip [count] cells uncover. */
export function swipeActionsExtentOf(
  count: number,
  cell: number,
  spacing: number,
  inset: number,
): number {
  return count <= 0 ? 0 : 2 * inset + count * cell + (count - 1) * spacing;
}

// The side a `CoreSwipeOutcome` member leaves open. Throws on a member it does not
// know, so a fourth resting pose surfaces as a failed build and not as a row that
// quietly stands in for it.
function swipeActionsSideOf(member: string): SwipeActionsSide | null {
  switch (member) {
    case 'closed':
      return null;
    case 'openLeading':
      return 'leading';
    case 'openTrailing':
      return 'trailing';
    default:
      throw new Error(
        `swipe_actions.pose: unknown CoreSwipeOutcome "${member}". Add it to ` +
          '`swipeActionsSideOf` in layout.ts with the side its row leaves open — or ' +
          'mark it `@behaviourOnly` if it is not a place the row rests.',
      );
  }
}

// The `Button` variant an action variant is drawn as. The pairing is stated once,
// on the enum's members (`CoreSwipeActionVariant`), and read from the export.
function swipeActionButtonVariantOf(member: string): string {
  const axis = SWIPE_ACTIONS.axes.other.find((o) => o.enum === 'CoreSwipeActionVariant');
  const facts = axis?.fields as
    | Readonly<Record<string, { buttonVariant?: string } | undefined>>
    | undefined;
  const buttonVariant = facts?.[member]?.buttonVariant;
  if (typeof buttonVariant !== 'string') {
    throw new Error(
      `SwipeActions: CoreSwipeActionVariant.${member} exports no buttonVariant — the ` +
        'canvas cannot tell which Button draws that action.',
    );
  }
  return buttonVariant;
}

// The Button rung a cell is as wide as. The widget fixes the action's size and
// shape (`actionButtonSize`, `actionButtonShape`); the contract pins the size to the
// cell, so the row that is as tall as the cell is the size it names. Its glyph is the
// row's `iconShapeIconStyle` — a circle draws a glyph, not a label.
function swipeActionsButtonRung(): SwipeActionsRung {
  const cell = dimVal(SWIPE_ACTIONS.fields.actionWidth);
  for (const [size, row] of Object.entries(BUTTON.sizes.defaultsBySize)) {
    if (dimVal(row.height) === cell) return { size, glyph: row.iconShapeIconStyle.size };
  }
  throw new Error(
    `SwipeActions: no Button size is ${cell} tall, the width of a cell — the action ` +
      "Button is the size row as tall as the cell (`CoreSwipeActionsContract.actionButtonSize`).",
  );
}

// One action: its Button over its label. The label is the Button's accessible name
// in the widgets and is also drawn under it; `Show labels` takes the drawn one away
// and the gap with it (a hidden child takes no part in the layout).
function drawSwipeActionCell(
  page: PageNode,
  lk: VarLookup,
  action: SwipeActionDemo,
  rung: SwipeActionsRung,
  labels: TextNode[],
  buttons: InstanceNode[],
): FrameNode {
  const f = SWIPE_ACTIONS.fields;
  const buttonVariant = swipeActionButtonVariantOf(action.variant);
  const variantRow = new Map(Object.entries(BUTTON.variants.defaultsByVariant)).get(buttonVariant);
  const cell = panel('action', 'VERTICAL', lk, { gap: f.labelGapStyle.size });
  cell.counterAxisAlignItems = 'CENTER';
  lockWidth(cell, f.actionWidth);
  // The cell is a control rung wide, so a density that moves the Button moves it.
  const width = dimVal(f.actionWidth);
  const widthVar = lk.controlHeightOrNull(width) ?? lk.sizeOrNull(width);
  if (widthVar) cell.setBoundVariable('width', widthVar);
  const button = instanceOf(
    page,
    'Button',
    bestVariantName(page, 'Button', {
      Variant: buttonVariant,
      Size: rung.size,
      State: 'enabled',
      Shape: 'circle',
    }),
  );
  button.name = 'button';
  setSlotIcon(
    button,
    'leading',
    iconMainIdAt(page, dimVal(rung.glyph)),
    action.glyph,
    glyphPaint(lk, labelColor(lk, colorData(optField<Color>(variantRow ?? {}, 'foregroundColor')))),
  );
  cell.appendChild(button);
  buttons.push(button);
  const label = makeLabel(action.label, lk, textLabelOpts(lk, textStyleData(f.labelStyle)));
  label.name = 'label';
  cell.appendChild(label);
  // The label takes the cell's width, one line, cut with an ellipsis.
  label.textAutoResize = 'HEIGHT';
  label.textAlignHorizontal = 'CENTER';
  label.layoutSizingHorizontal = 'FILL';
  label.textTruncation = 'ENDING';
  label.maxLines = 1;
  labels.push(label);
  return cell;
}

function drawSwipeActionsMember(
  page: PageNode,
  lk: VarLookup,
  mount: SetMount,
  name: string,
  side: SwipeActionsSide | null,
  rung: SwipeActionsRung,
  drawn: SwipeActionsDrawn,
): void {
  const f = SWIPE_ACTIONS.fields;
  const c = mount.getOrCreate(name);
  c.layoutMode = 'NONE';
  c.fills = [];
  c.clipsContent = true;
  c.resize(kSwipeActionsRowWidth, kSwipeActionsRowHeight);
  // Where the row stands: along by the strip it uncovers, away from the edge it left.
  let rowX = 0;
  if (side !== null) {
    const actions = side === 'leading' ? kSwipeActionsLeading : kSwipeActionsTrailing;
    const extent = swipeActionsExtentOf(
      actions.length,
      dimVal(f.actionWidth),
      dimVal(f.actionSpacing),
      dimVal(f.platterInset),
    );
    const platter = panel(side, 'HORIZONTAL', lk, {
      pl: f.platterInset,
      pr: f.platterInset,
      gap: f.actionSpacing,
    });
    platter.counterAxisAlignItems = 'CENTER';
    fillData(platter, lk, colorData(f.platterColor));
    // The first action is the outermost: the trailing platter's outer edge is its right.
    for (const action of side === 'leading' ? actions : [...actions].reverse()) {
      platter.appendChild(drawSwipeActionCell(page, lk, action, rung, drawn.labels, drawn.buttons));
    }
    c.appendChild(platter);
    platter.primaryAxisSizingMode = 'FIXED';
    platter.counterAxisSizingMode = 'FIXED';
    platter.resize(extent, kSwipeActionsRowHeight);
    platter.x = side === 'leading' ? 0 : kSwipeActionsRowWidth - extent;
    platter.y = 0;
    platter.constraints = { horizontal: side === 'leading' ? 'MIN' : 'MAX', vertical: 'STRETCH' };
    rowX = side === 'leading' ? extent : -extent;
  }
  // Above the platter, like the widget's stack. The `Child` swap fills the box, so a
  // row the designer swaps in takes the row's size whatever size it came in at.
  const row = autoFrame('row', 'HORIZONTAL');
  const child = slotStandIn(page, 'child', kSlotShape);
  row.appendChild(child);
  child.layoutSizingHorizontal = 'FILL';
  child.layoutSizingVertical = 'FILL';
  c.appendChild(row);
  row.primaryAxisSizingMode = 'FIXED';
  row.counterAxisSizingMode = 'FIXED';
  row.resize(kSwipeActionsRowWidth, kSwipeActionsRowHeight);
  row.x = rowX;
  row.y = 0;
  row.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };
  drawn.rows.push(child);
}

function buildSwipeActions(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = SWIPE_ACTIONS.fields;
  const poseAxis = SWIPE_ACTIONS.axes.other.find((o) => o.enum === 'CoreSwipeOutcome');
  if (!poseAxis) {
    throw new Error(
      'SwipeActions: CoreSwipeOutcome is gone from the exported axes — the canvas has a ' +
        'Pose axis that nothing in the contract now backs.',
    );
  }
  if (dimVal(f.fullSwipeScale) !== 1) {
    throw new Error(
      `SwipeActions: fullSwipeScale is ${dimVal(f.fullSwipeScale)}, not 1. The first cell ` +
        'is scaled only while a pull is past the full-swipe threshold, and the canvas draws ' +
        'resting poses only — draw that pose, scaling the first cell in it, before changing ' +
        'the default.',
    );
  }
  // `Enabled` is the axis the contract promotes (`enabled` is a widget bool), and a
  // disabled row is a closed row: it takes no drag and exposes no action, so the
  // open poses of a disabled row are poses the widget cannot reach and are not
  // members (the way `Clickable`'s missing combinations are ones its widget returns
  // early out of). The member that is left draws what an enabled closed row draws —
  // the honest rendering, as in `ContextMenu`: nothing in the Style tells a disabled
  // row from an enabled one, so there is nothing to recolour without inventing it.
  const combos = enumerateAxisAssignments([
    ...axisSpecsOf(SWIPE_ACTIONS.axes),
    { axis: 'Pose', values: poseAxis.members },
  ]).filter((a) => a.values['Enabled'] === 'true' || swipeActionsSideOf(a.values['Pose']) === null);
  const mount = mountSet(
    page,
    'SwipeActions',
    combos.map((a) => a.name),
  );
  const rung = swipeActionsButtonRung();
  const drawn: SwipeActionsDrawn = { labels: [], buttons: [], rows: [] };
  for (const combo of combos) {
    const side = swipeActionsSideOf(combo.values['Pose']);
    drawSwipeActionsMember(page, lk, mount, combo.name, side, rung, drawn);
  }
  const set = mount.finish();
  // Defined AFTER finish(), never inside the member loop — see `buildFooter`.
  const childProp = defineProp(set, 'Child', 'INSTANCE_SWAP', slotStandInDefault(page, kSlotShape));
  for (const n of drawn.rows) bindSwapProp(n, childProp);
  // `CoreSwipeActionsContract.defaultShowLabels` — the contract's own default
  // reaching the canvas.
  const showLabels = defineProp(set, 'Show labels', 'BOOLEAN', SWIPE_ACTIONS.behaviour.showLabels);
  for (const n of drawn.labels) bindVisibleProp(n, showLabels);
  // `leadingActions` / `trailingActions` are `List<CoreSwipeAction>`, which no
  // component property can be — the Buttons are the lists the preview draws, exposed
  // so a designer changes an action's variant or glyph on the set's own panel.
  exposeAll(drawn.buttons);
  return set;
}

// ─── Registry ────────────────────────────────────────────────────────────────

export const LAYOUT_BUILDERS: RegistryEntry[] = [
  // `Divider` is declared even though it is built in this same file: the
  // generation loop walks REGISTRY order, and Accordion is listed before
  // Divider, so without the edge `instanceOf` would run first and throw.
  { section: 'Layout', name: 'Accordion', build: buildAccordion, needs: ['Icon', 'Divider'] },
  { section: 'Layout', name: 'Collapsible', build: buildCollapsible, needs: ['Icon'] },
  { section: 'Layout', name: 'Divider', build: buildDivider },
  { section: 'Layout', name: 'Disclosure', build: buildDisclosure, needs: ['Icon'] },
  {
    section: 'Layout',
    name: 'DisclosureGroup',
    build: buildDisclosureGroup,
    // Composes real `Disclosure` instances, so the child has to exist first.
    needs: ['Disclosure'],
    // No `CoreDisclosureGroupStyle` of its own — the group's one chrome value
    // (`itemSpacing`) is declared on the sibling `CoreDisclosureStyle`, which
    // is where `DisclosureGroup` reads it from on both platforms.
    dataSlug: 'disclosure',
  },
  // The slot stand-in is what both of these draw their caller-supplied slot
  // as, and it is a `Display` entry — the generation loop walks sections
  // (Form → Display → Navigation → Overlay → Layout), which happens to build
  // it first today, but nothing states that. The edge does.
  // The stand-in is what the `aside` swap points at; `Divider` draws
  // the top rule and the hairline ticks; `Collapsible` IS the business-info
  // disclosure; `Link` is each legal link. All four are composed as instances,
  // so all four have to be on the page before this entry runs.
  {
    section: 'Layout',
    name: 'Footer',
    build: buildFooter,
    needs: [kSlotStandInComponent, 'Divider', 'Collapsible', 'Link'],
  },
  { section: 'Layout', name: 'Hero', build: buildHero, needs: [kSlotStandInComponent] },
  { section: 'Layout', name: 'Join', build: buildJoin },
  {
    section: 'Layout',
    name: 'TableHeaderCell',
    build: buildTableHeaderCell,
    // A fragment of `CoreTableStyle` — `CoreTableCellData` is a data value with
    // no Style of its own. The header cell reads the header half of the table's
    // fields; the table's own box (border, radius, row fills) is not its to match.
    dataSlug: 'table',
    dataFields: ['headerPadding', 'headerTextStyle', 'disabledForegroundColor'],
  },
  {
    section: 'Layout',
    name: 'TableCell',
    build: buildTableCell,
    // The body half of the same fragment.
    dataSlug: 'table',
    dataFields: ['cellPadding', 'cellTextStyle', 'foregroundColor', 'disabledForegroundColor'],
    needs: [kSlotStandInComponent],
  },
  { section: 'Layout', name: 'Table', build: buildTable, needs: ['TableHeaderCell', 'TableCell'] },
  {
    section: 'Layout',
    name: 'ResizableTable',
    build: buildResizableTable,
    // Takes a `CoreTableStyle` and calls `resolveTable` — its chrome is stated
    // under `table`, and no `resizable_table` entry exists to read.
    dataSlug: 'table',
    needs: ['TableHeaderCell', 'TableCell'],
  },
  {
    section: 'Layout',
    name: 'TreeItem',
    build: buildTreeItem,
    // A fragment of `CoreTreeStyle` — `CoreTreeNode` is a data value with no
    // Style of its own. The row reads the node half of the tree's fields; the
    // `Clickable` around it (disabled fade, focus ring) is the tree's.
    dataSlug: 'tree',
    dataFields: [
      'indent',
      'nodePadding',
      'nodeMinHeight',
      'iconStyle',
      'chevronIconStyle',
      'leafIconStyle',
      'nodeSelectedColor',
      'borderRadius',
      'chevronPlaceholderGapStyle',
      'iconGapStyle',
      'labelGapStyle',
      'nodeTextStyle',
      'nodeSelectedTextStyle',
    ],
    needs: ['Icon', kSlotStandInComponent],
  },
  {
    section: 'Layout',
    name: 'Tree',
    build: buildTree,
    // The tree's own half of `CoreTreeStyle`: the `Clickable` every row sits
    // in (the disabled fade, the focus ring). The rows are `TreeItem`'s.
    dataFields: ['clickableStyle'],
    needs: ['TreeItem'],
  },
  { section: 'Layout', name: 'Resizable', build: buildResizable, needs: ['Icon'] },
  // Both compose real `Button` instances, so the set has to be on the page
  // first.
  { section: 'Layout', name: 'PageHeader', build: buildPageHeader, needs: ['Button'] },
  { section: 'Layout', name: 'PanelHeader', build: buildPanelHeader, needs: ['Button'] },
  // Draws real `Button` instances for its two actions, so the set has to be on the
  // page first.
  { section: 'Layout', name: 'BottomActionBar', build: buildBottomActionBar, needs: ['Button'] },
  // Draws a real circular `Button` per action and the slot stand-in for the row; the
  // glyph inside each Button comes from the `Icon` set.
  {
    section: 'Layout',
    name: 'SwipeActions',
    build: buildSwipeActions,
    needs: ['Button', 'Icon', kSlotStandInComponent],
  },
];
