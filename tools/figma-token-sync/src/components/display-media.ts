/// <reference types="@figma/plugin-typings" />

import { kCanvasOnlyApiNotes } from '../canvas-only-notes';
import { bindRoundBoxRadius, boxGeometry } from '../shape-geometry';
import { beginLegacyCountdown, captureLegacyCountdown, restoreLegacyCountdown } from '../countdown-migration';
import { retainTextInRedrawWrapper } from '../redraw-keep';
import {
  mainComponentIdOf as mainIdOf,
  findComponentByName,
  ChromeOpts,
  ColorData,
  RegistryEntry,
  SetMount,
  ShadowData,
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
  corners,
  defineProp,
  applyForwardedButtonStyle,
  applyPanelCompChrome,
  applySurfaceMaterial,
  fillData,
  fillSem,
  forwardFocusBand,
  glyphOpts,
  glyphPaint,
  iconMainId,
  iconMainIdAt,
  iconSwapDefault,
  instanceOf,
  labelColor,
  lockWidth,
  makeIcon,
  makeLabel,
  mint,
  mintPanelComp,
  mountSet,
  panel,
  pinAbsolute,
  sizePin,
  propertyOwner,
  rowSet,
  textLabelOpts,
  weightStyle,
  typographyColorOpts,
  setSlotIcon,
  setInstanceBoolNamed,
  setInstanceTextNamed,
  setShadow,
  setSurfaceRim,
  applyForwardedPanelStyle,
  assignPaints,
  colorPaint,
  fadeNode,
  fillDataOnPaint,
  gradientPaint,
  literalPaint,
  solid,
  freePropName,
  kSlotStandInComponent,
  slotStandInDefault,
  kAvatarRest,
  focusRing,
  vStackSet,
  exposeAll,
} from '../helpers';
import type { FocusRingNodes } from '../helpers';
import { afterNodeBindLands } from '../identity';
import { bindOptionalSlot, slotNodes } from '../overlay-preview';
import { bindShowFocusRing, defineShowFocusRing, stateAxisSpec } from '../state-axis';
import { exampleInstance, exampleSwapDefault, kMockupDeviceExample } from '../default-examples';
import { colorData, dimVal, textStyleData, Color, Dim } from '../compat/v1';
import { clipsFor } from '../container-chrome';
import { linkShadowStyle } from '../shadow-style';
import { COMPONENTS } from '../data';
import { fillComposedColor } from '../paint';
import {
  AntennaBand,
  DeviceEdge,
  DeviceGeometry,
  DeviceGlyph,
  DeviceRect,
  SafeAreaFlag,
  SafeAreaSide,
  SafeAreaSource,
  StatusBarBatteryItem,
  StatusBarGroup,
  StatusBarItem,
  StatusBarLayout,
  buttonDepthGradient,
  buttonLengthGradient,
  isVerticalEdge,
  mockupDeviceGeometry,
  mockupDeviceSettings,
  safeAreaSources,
} from '../mockup-device-geometry';
import { roleLeaf } from '../text-nodes';
import { parseVariantKey } from '../variant-safety';
import {
  axisSpecsOf,
  composeVariantName,
  enumerateAxisCombos,
  restingAxisSummary,
  restingValueOf,
} from '../axis-combos';

const NUMBER_TICKER = COMPONENTS.number_ticker;
const COUNTDOWN = COMPONENTS.countdown;
const TIMELINE = COMPONENTS.timeline;
const kTimelinePreviewWidth = 360;
const kChatPreviewWidth = 300;
const kDiffPreviewWidth = 360;
const kDiffKnobSide = 24;
const kDiffHalf = 2;
const CHAT_BUBBLE = COMPONENTS.chat_bubble;
// Centring divisor for the connector inside the dot column.
const kTimelineHalf = 2;
// Figma refuses a zero-length side on `resize`; the connector never gets this short on a real row.
const kTimelineMinSide = 0.01;
const TRACKER = COMPONENTS.tracker;
const CARD_IMAGE = COMPONENTS.card_image;
const CAROUSEL = COMPONENTS.carousel;
const CAROUSEL_BANNER = COMPONENTS.carousel_banner;
const CARD = COMPONENTS.card;
const CHAT = COMPONENTS.chat;
// `CoreWindowStyle.panelStyle` is NOT read here — that nested slot is resolved
// by the composed `WindowPanel` itself (see `buildWindow`), and reading it here
// as well would be the second copy that composition exists to remove. What IS
// read are the style's own flat fields: the drag-time snap overlay.
const WINDOW = COMPONENTS.window;
const CODE_DIFF = COMPONENTS.code_diff;
const DIFF = COMPONENTS.diff;
const HOVER_GALLERY = COMPONENTS.hover_gallery;
const MOCKUP_BROWSER = COMPONENTS.mockup_browser;
const MOCKUP_CODE = COMPONENTS.mockup_code;
const MOCKUP_DEVICE = COMPONENTS.mockup_device;
const SORTABLE = COMPONENTS.sortable;

// ─── Preview-only constants (not design values) ──────────────────────────────
//
// The carousel viewport's size and the card's width are this preview's own
// choices — neither `CoreCarouselStyle` nor `CoreCardImageStyle` states one,
// so they are applied through `resize()` / `lockWidth()` and never through a
// token-binding helper. Keyed by axis member rather than inline so the places
// each size appears cannot drift apart, and so a renamed member throws
// instead of silently drawing the wrong screen; a name is not evidence of a
// token.
// g7-preview-only: the two screens the designer draws the carousel on. The
// widget takes its extent from its parent — nothing in `CoreCarouselStyle`
// states a width — so these are the canvas picking a phone and a desktop.
const kCarouselSlideSize: Record<string, { w: number; h: number }> = {
  sm: { w: 320, h: 180 },
  md: { w: 480, h: 270 },
};
// g7-preview-only: the banner strip's own preview width per screen. Its HEIGHT
// is not here — `CarouselBanner` states it (inset + thumbnail + inset), which
// is why this pair is width-only.
const kCarouselBannerWidth: Record<string, number> = { sm: 361, md: 1034 };
// The designer's banner copy — `CarouselBanner`'s `Title` / `Description`
// at rest.
const kCarouselBannerTitle = '겨울 시즌 할인';
const kCarouselBannerBody = '12월 31일까지 전 상품 20% 할인';
const kCardImageWidth = 240;
// g7-preview-only: the stand-in image's height — 16:9 under the 240 card. The
// widget draws the caller's `image` at that image's own size; nothing in
// `CoreCardImageStyle` states a height or an aspect, so this is the preview
// picking a picture shape, the way `kCardImageWidth` picks a width.
const kCardImageHeight = 135;
// g7-preview-only: size of the glyph that says "a picture goes here" over the
// stand-in image. The widget draws no icon — the caller's picture fills the
// frame — so, like HoverGallery's placeholder glyph, this is the preview's own.
const kCardImagePlaceholderSize = 28;

// The desktop aspect each snap-preset thumbnail mirrors. The widget reads it
// off the navigator's own constraints (`_buildSnapPresets`: `aspectRatio =
// constraints.biggest.width / constraints.biggest.height`), so it is a property
// of the viewport the bar floats over and no field of any component states it —
// this preview picks a plain desktop shape, the way `kCarouselSlideSize` picks a
// viewport size. Every thumbnail's WIDTH derives from it, so the bar is as wide
// as six of them: ~860px against a 320px panel, which is also true of the app.
const kSnapDesktopAspect = 16 / 10;

// Which step of the `Avatar` set stands in for `Chat.avatar`. `CoreChatStyle`
// states the gap beside the avatar and nothing about its size — the caller
// supplies the widget — so this is the preview picking a step, and `sm` is the
// 32px one the hand-drawn ellipse it replaces was.
const kChatAvatarSize = 'sm';

// ─── Components in this file with no composition slots ───────────────────────
//
// Recorded once here rather than repeated per builder: `NumberTicker`,
// `Countdown`, `Timeline`, `Tracker`, `CodeDiff`, `HoverGallery`, `MockupCode`
// and `Sortable` declare no `W`/`W?` slot on their contracts — what they render
// comes from data inputs (a value, a list of events/lines/statuses), not from
// caller-supplied widgets. There is nothing for a Figma component property to
// stand for, so none is declared. A TEXT property over, say, NumberTicker's
// digits would invent a slot the contract doesn't have.
//
// Repeated slots are also skipped everywhere, for a structural reason: Figma
// has no repeated-slot property. `Carousel.items` (`List<W>?`) is the only one
// in this file; a designer adds or removes children directly instead.
//
// `Tracker`'s one property is the exception that proves the rule: `Tooltip` is
// a BOOLEAN over a hover-revealed overlay, not a slot — the widget wraps every
// segment in a `Tooltip` unconditionally, and the switch reveals what hovering
// would (see `buildTracker`).
//
// `Tracker` also carries an unexploited *variant* axis
// (`variants.defaultsByStatus` — fine / warning / critical / unknown) that this
// builder spends as a mixed strip of bars inside one component rather than as a
// `Status=` axis. That is a variant axis, not a state axis, so it is out of
// scope here — noted so it isn't mistaken for "already covered".

// ─── Picking a variant of a composed child ───────────────────────────────────
//
// `instanceOf(page, name, variantName)` matches a variant by its EXACT name,
// and a child's axis list is not this file's to know. `Button` is the proof:
// it grew independent `Selected` / `Hover` / `Disabled` boolean axes, and the
// literal `'Variant=ghost, Size=sm'` this file first passed stopped matching
// the moment it did — `Variant=ghost, Size=sm, Selected=false, Hover=false,
// Disabled=false` is the name now, and it will grow again the next time an
// axis is added.
//
// So the name is read off the set that is actually on the page: the variant
// whose axes carry the values this call site asks for, with every axis it does
// NOT ask for reading its RESTING value — which is what a parent composing a
// child wants (a nav arrow is not pre-hovered). Only the *name* is resolved
// here; `instanceOf` still does the lookup, the instantiation, and the loud
// failure.
//
// Which value each axis rests at lives in `axis-combos.ts` — one table, shared
// with `form-pickers.ts`, which asks the same question a different way. It was
// two hand-rolled answers until a state axis stopped being a boolean; the note
// there records what that cost.
//
// Throws rather than falling back to the set's first variant: that fallback
// would silently hand back `Variant=primary, Size=xs` — a differently-coloured,
// differently-sized button that still looks like a button, which is the kind of
// wrong that survives review.
function restingVariant(
  page: PageNode,
  setName: string,
  axes: Record<string, string>,
): string {
  const found = findComponentByName(page, setName);
  const set = found && found.type === 'COMPONENT_SET' ? found : undefined;
  const names: string[] = [];
  for (const child of set ? set.children : []) {
    if (child.type !== 'COMPONENT') continue;
    names.push(child.name);
    const present = child.variantProperties;
    if (!present) continue;
    let match = true;
    for (const key of Object.keys(present)) {
      const want = axes[key] ?? restingValueOf(key);
      if (present[key] !== want) {
        match = false;
        break;
      }
    }
    if (match) return child.name;
  }
  const asked = Object.keys(axes)
    .map((k) => `${k}=${axes[k]}`)
    .join(', ');
  throw new Error(
    `restingVariant('${setName}', {${asked}}): no variant carries those axis ` +
      `values at rest (unasked axes read "false", except ` +
      `${restingAxisSummary()}). The child's ` +
      `axis vocabulary changed. Variants present: ${names.join(' | ')}`,
  );
}

// ─── Overriding a composed child's radius / inset ────────────────────────────
//
// A parent that forwards `CoreXxxStyle(borderRadius: …)` or a padding into a
// child it composes is stating that child's chrome, and on this canvas that is
// an instance override. This file used to carry its own `bindInstanceRadius`
// because `bindRadiusN`'s parameter union predated any builder doing that;
// `bindRadiusN` and `bindPad` both take an `InstanceNode` now, so the local copy
// is gone and both call sites below use the shared helpers. One definition of
// which fields a radius is, and one place that resolves `start`/`end`.

// ─── Emptying a composed child's own label ───────────────────────────────────
//
// `Button` declares its label as a TEXT component property whose default is the
// word "Button" — the demo copy every plain instance shows. A parent composing
// an icon-only button (`Button(child: Icon(…))`, no text at all) has to say so,
// and until it does the canvas renders the placeholder: Carousel's prev/next
// controls read literally "Button", which is what a person looking at the real
// file reported.
//
// `setProperties` and never `characters` on the node inside the instance:
// writing through the node would be the override that decouples this parent
// from the child it composed, so the next change to `Button`'s label would move
// every other instance and not these two. Matching by property TYPE rather than
// by name for the reason `setSlotIcon` centralises its own matching — the id
// Figma appends (`Child#123:4`) is not knowable here, and the label's *name* is
// the child builder's to change.
//
// A child that declares no TEXT property has nothing to clear, so this is a
// no-op rather than a throw: unlike `setSlotIcon`, there is no glyph that would
// silently go missing — the failure this guards against is visible in the one
// thing it writes.
function clearInstanceLabel(inst: InstanceNode): void {
  const props: ComponentProperties | undefined = inst.componentProperties;
  if (!props || typeof inst.setProperties !== 'function') return;
  for (const key of Object.keys(props)) {
    if (props[key].type !== 'TEXT') continue;
    const patch: { [name: string]: string } = {};
    patch[key] = '';
    inst.setProperties(patch);
    return;
  }
}


// ─── A slot the widget forwards into a child it composes ─────────────────────
//
// `CardImage` hands `leading` / `title` / `subtitle` / `trailing` straight to
// the `Basic` it composes. The Figma component contains that `Basic` as an
// instance, and a component property reference cannot be bound to a node inside
// an instance — so the parent cannot declare those four itself without drawing
// a second copy of the child's nodes to bind them to.
//
// Figma's mechanism for exactly this is the exposed nested instance: the
// child's own properties surface in the parent's panel. It is the same
// forwarding the widget does, expressed the one way Figma has.
//
// Wrapped, and only for the affordance's sake: a rejected write here would fail
// the entry and leave a half-drawn component on the page — one that still looks
// finished. Losing the lift is a designer selecting one level deeper
// — which Figma allows anyway — and that is the right trade against half a
// component. Same shape as `primitives-chrome.ts`'s `characters` fallback.
function exposeNested(instance: InstanceNode): void {
  try {
    instance.isExposedInstance = true;
  } catch {
    // The child's properties stay reachable by selecting the nested instance.
  }
}

// ─── A glyph inside a composed `Button` ──────────────────────────────────────
//
// `Button(child: Icon(...))` is one node in Figma and it is an instance, which
// takes no children, so the glyph goes in through the child's own properties —
// which is where the widget puts it too.
//
// Matching lives in `setSlotIcon` (helpers.ts) rather than here. This file had
// its own copy that looked for a BOOLEAN literally named `leading` and a swap
// named `leading icon`; `Button` declares `Show leading` + `Leading`, so the
// patch came out empty, `setProperties` was never called, and Carousel's
// prev/next rendered as two identical glyph-less circles. An empty patch is a
// legal no-op — nothing failed, and the harness counted a call that had
// nothing to do. One copy of the matching means the next rename in `Button`
// breaks one place loudly instead of emptying every caller's patch quietly.

// ─── NumberTicker ────────────────────────────────────────────────────────────

// Data-driven from coui_core NUMBER_TICKER.fields.textStyle (role=titleLarge,
// no color override → falls back to on-surface, same as the old literal).
// `duration` (500ms) is the count-up animation timing — no visual meaning in
// a static frame, so it's simply not consumed here (same as every other
// component's duration or animation field in this file). The caption ("Total
// downloads") and the value↔caption gap have no matching Style field (OQ-2).
function buildNumberTicker(page: PageNode, lk: VarLookup): ComponentNode {
  // g7-preview-only: gap between the digits and the caption under them. `NumberTicker.build` returns one `Text` and nothing else, so a caller who wants a caption places it and owns this gap.
  const c = mintPanelComp(page, 'NumberTicker', 'VERTICAL', lk, { gap: 2 });
  c.counterAxisAlignItems = 'CENTER';
  c.appendChild(makeLabel('2,048', lk, textLabelOpts(lk, textStyleData(NUMBER_TICKER.fields.textStyle))));
  // The caption is a preview-only second line — the widget draws only the number, so no field describes it. Its type is the library's small body role (Body/XS), attached as that role's text style through the shared role opts; its ink is `on-surface-variant`.
  const captionColor: ColorData = { color: 'on-surface-variant' };
  c.appendChild(makeLabel('총 다운로드', lk, textLabelOpts(lk, textStyleData({ role: 'bodyXs' }), captionColor)));
  return c;
}

// ─── Countdown ───────────────────────────────────────────────────────────────

// Data-driven from coui_core COUNTDOWN.fields.labelStyle (role=headlineLarge,
// color=on-surface) — applied to the big digit. `animationDuration` (150ms,
// the flip/tick transition) has no static-frame meaning. The unit caption
// ("Days"/"Hrs"/…) and all block chrome (bg/radius/padding/gap) + the row gap
// between blocks have no matching Style field (OQ-2 — CoreCountdownStyle only
// carries `animationDuration` + `labelStyle`).
// The unit word wears the library's small body role (Body/XS) as a text style.
//
// Figma-only four-unit composition. The runtime API remains one integer.
// Each column measures the same four styled values through TEXT references,
// so native HUG computes max(size/56, widest numeral + both bound space/8
// insets) in every column. The invisible carrier has legal height 4, cancelled
// by -4 spacing; these are structural lengths, independent of density tokens.
const kCountdownBlockMinWidth = 56;
const kCountdownCarrierHeight = 4;
async function buildCountdown(page: PageNode, lk: VarLookup): Promise<ComponentNode> {
  const legacy = await captureLegacyCountdown(findComponentByName(page, 'Countdown'));
  if (legacy) beginLegacyCountdown(legacy);
  // g7-preview-only: this four-unit row belongs to Figma's composition, not the runtime integer.
  const c = mintPanelComp(page, 'Countdown', 'HORIZONTAL', lk, { gap: 8 });
  c.description = kCanvasOnlyApiNotes.Countdown;
  const blocks = [['12', '일'], ['08', '시간'], ['30', '분'], ['15', '초']];
  const names = ['Days', 'Hours', 'Minutes', 'Seconds'];
  const numbers = names.map((name, i) => defineProp(c, name, 'TEXT', blocks[i][0]));
  if (numbers.some(id => id === null)) throw new Error('Countdown TEXT property creation failed');
  if (legacy && legacy.main !== c) throw new Error('Countdown migration main changed');
  const digitOpts = textLabelOpts(lk, textStyleData(COUNTDOWN.fields.labelStyle));
  const unitColor: ColorData = { color: 'on-surface-variant' };
  const unitOpts = textLabelOpts(lk, textStyleData({ role: 'bodyXs' }), unitColor);
  for (const [i, b] of blocks.entries()) {
    const blk = panel('block', 'VERTICAL', lk, {
      // g7-preview-only: preserve the existing Figma unit chrome; runtime Countdown draws one numeral.
      bg: 'surface-container', radius: 8, pl: 8, pr: 8, pt: 8, pb: 8,
    });
    c.appendChild(blk);
    blk.primaryAxisAlignItems = 'CENTER';
    blk.counterAxisAlignItems = 'CENTER';
    blk.minWidth = kCountdownBlockMinWidth;
    blk.setBoundVariable('minWidth', lk.size(kCountdownBlockMinWidth));
    // The visible digit/caption gap keeps its existing density-aware binding.
    // The outer spacing cancels only the structural carrier height.
    blk.setBoundVariable('itemSpacing', null);
    blk.itemSpacing = -kCountdownCarrierHeight;
    // g7-preview-only: caption spacing belongs to the existing Figma sample.
    const visible = panel('visible', 'VERTICAL', lk, { gap: 2 });
    blk.appendChild(visible);
    visible.counterAxisAlignItems = 'CENTER';
    visible.clipsContent = false;
    const digit = makeLabel(b[0], lk, digitOpts);
    digit.name = `digit-${i}`;
    visible.appendChild(digit);
    bindTextProp(digit, numbers[i]);
    const caption = makeLabel(b[1], lk, unitOpts);
    visible.appendChild(caption);
    const carrier = autoFrame('intrinsic-carrier', 'VERTICAL');
    blk.appendChild(carrier);
    carrier.resize(1, kCountdownCarrierHeight);
    carrier.layoutSizingHorizontal = 'HUG';
    carrier.layoutSizingVertical = 'FIXED';
    carrier.counterAxisAlignItems = 'CENTER';
    carrier.opacity = 0;
    carrier.clipsContent = true;
    for (let j = 0; j < blocks.length; j++) {
      if (j === i) continue;
      const measure = makeLabel(blocks[j][0], lk, digitOpts);
      measure.name = `measure-${j}`;
      carrier.appendChild(measure);
      bindTextProp(measure, numbers[j]);
    }
    blk.layoutSizingHorizontal = 'HUG';
    blk.layoutSizingVertical = 'HUG';
    if (legacy) retainTextInRedrawWrapper({
      member: c, oldParent: legacy.rows[i].block, freshParent: blk, wrapper: visible,
      leaves: [{ old: legacy.rows[i].digit, fresh: digit }, { old: legacy.rows[i].caption, fresh: caption }],
    });
  }
  if (legacy) restoreLegacyCountdown(legacy, numbers);
  return c;
}

// ─── Timeline ────────────────────────────────────────────────────────────────

// Data-driven from coui_core TIMELINE: rowSpacing (event↔event gap, exact
// value match), dotSize + dotColor (the marker), titleTextStyle (the event
// title) and timestampTextStyle (the secondary "time ago" line).
// `descriptionTextStyle` is the line under each title: the widget draws a
// description only `if (items[i].description != null)`, and these three preview
// events carry one — which is also what lets the 360-wide preview show the
// column folding it (the first event's description takes two lines).
//
// The dot↔content horizontal gap and the title↔timestamp
// vertical gap inside `content` each have two same-shaped candidates
// (`columnGapStyle`/`contentTopGapStyle`/`dotTopMargin`) with no way to tell
// which maps to which from the JSON alone — kept literal rather than guess
// (OQ-2). `dotCornerRadius` is unused: the dot is a `createEllipse()`, which
// is inherently round without a bindable radius (same reasoning as
// RadioGroup's indicator, `form.ts`). `timeColumnWidth`/`titlePadding`/
// `connectorSpacing`/`connectorColor`/`connectorThickness` describe a
// dedicated time column + connecting line this simplified 2-part (dot +
// content) preview doesn't render — restructuring to add them would change
// layout, out of scope.
// A `Gap` node rather than an auto-layout `itemSpacing`, for the reason
// `display-data.ts#gapSpacer` states: a row that interleaves two or three
// DIFFERENT gaps cannot carry them all as one spacing value. Timeline's row has
// `columnGapStyle` twice and the content column has `contentTopGapStyle` once,
// so each stated gap gets a node and the frames' own spacing is nothing.
function timelineGap(name: string, lk: VarLookup, size: number | Dim): FrameNode {
  const g = figma.createFrame();
  g.name = name;
  g.layoutMode = 'NONE';
  g.fills = [];
  bindSize(g, lk, size, size);
  return g;
}

/**
 * Where the connector starts inside the dot column and how long it is, for a
 * row of the given height.
 *
 * The widget paints the line from `connectorSpacing` below its own dot to
 * `connectorReach` past the bottom of the row, so it stops `connectorSpacing`
 * above the next item's dot — the next dot sits `rowSpacing + dotTopMargin`
 * below this row's bottom. `top` is the first, `length` is the row's height
 * plus the reach, less where the line starts. All of it is read from the data;
 * the only input is the row's height, which is the one thing that changes when
 * a description folds (a row whose description takes two lines is 20 taller,
 * and the line reaches 20 further).
 *
 * Exported so the registry-runtime drill can read the arithmetic itself: its
 * Figma double does not lay text out, so a built row's height is 0 there and a
 * built line can only show that it came from this function, not what it measures.
 * The floor is Figma's: a node cannot be resized to a zero (or negative) side.
 */
export function timelineConnectorSpan(rowHeight: number): { top: number; length: number } {
  const f = TIMELINE.fields;
  const spacing = dimVal(f.connectorSpacing);
  const dotTop = dimVal(f.dotTopMargin);
  const top = dotTop + dimVal(f.dotSize) + spacing;
  const reach = dimVal(f.rowSpacing) + dotTop - spacing;
  return { top, length: Math.max(rowHeight + reach - top, kTimelineMinSide) };
}

function buildTimeline(page: PageNode, lk: VarLookup): ComponentNode {
  const f = TIMELINE.fields;
  const c = mintPanelComp(page, 'Timeline', 'VERTICAL', lk, { gap: f.rowSpacing });
  // g7-preview-only: the frame's own width. The widget's root is a `Column` that takes its width from its parent, and `timeColumnWidth` is the timestamp column's width, not the component's — so nothing states one.
  lockWidth(c, kTimelinePreviewWidth);
  // The connector overshoots the row it belongs to (see below), so the root
  // cannot clip.
  c.clipsContent = false;
  const events = [
    ['계정 생성', '2시간 전', '등록된 주소로 환영 메일을 보냈어요.'],
    ['프로필 수정', '1시간 전', '표시 이름과 프로필 사진을 바꿨어요.'],
    ['설정 변경', '5분 전', '2단계 인증을 켰어요.'],
  ];
  // Each line reads its own role: `titleTextStyle` is the Label/Large role (no
  // weight laid over it, so the role's text style attaches to the label),
  // `timestampTextStyle` bodySmall, `descriptionTextStyle` bodySmall in the
  // muted colour.
  const titleOpts = textLabelOpts(lk, textStyleData(f.titleTextStyle));
  const timestampOpts = textLabelOpts(lk, textStyleData(f.timestampTextStyle));
  const descriptionOpts = textLabelOpts(lk, textStyleData(f.descriptionTextStyle));
  const dotSide = dimVal(f.dotSize);
  for (let i = 0; i < events.length; i++) {
    const e = events[i];
    // `IntrinsicHeight(Row(crossAxisAlignment: .stretch))` — the row is as tall
    // as its tallest column and every column spans it, which is what makes the
    // connector able to reach the bottom.
    const ev = panel('event', 'HORIZONTAL', lk, {});
    ev.itemSpacing = 0;
    // `crossAxisAlignment: .stretch` is expressed per child (`layoutSizingVertical
    // = 'FILL'` below), not on the row: Figma's counter-axis alignment has no
    // STRETCH member — stretching is the child's own sizing statement.
    ev.counterAxisAlignItems = 'MIN';
    ev.clipsContent = false;

    // ── timestamp column ──────────────────────────────────────────────────
    // `ConstrainedBox(timeColumnConstraints)` + `Align(alignment: .topRight)`.
    // Its width is the one `timeColumnWidth` states; MAX on the main axis is the
    // "right" of that alignment and MIN on the counter axis is the "top".
    const timeCol = panel('timestamp', 'HORIZONTAL', lk, {});
    timeCol.primaryAxisAlignItems = 'MAX';
    timeCol.counterAxisAlignItems = 'MIN';
    timeCol.appendChild(makeLabel(e[1], lk, timestampOpts));
    ev.appendChild(timeCol);
    bindSize(timeCol, lk, f.timeColumnWidth, timeCol.height);
    timeCol.primaryAxisSizingMode = 'FIXED';
    timeCol.layoutSizingVertical = 'FILL';

    ev.appendChild(timelineGap('column gap', lk, f.columnGapStyle.size));

    // ── dot column ────────────────────────────────────────────────────────
    // `Column(mainAxisSize: .min)` holding the dot and, on every row but the
    // last, the connector. Its width is the dot's — the widget's comment says so
    // outright ("the dot column stays at dotSize width").
    const dotCol = panel('dot column', 'VERTICAL', lk, {});
    dotCol.itemSpacing = 0;
    dotCol.counterAxisAlignItems = 'CENTER';
    dotCol.clipsContent = false;
    // `margin: .only(top: dotTopMargin)` — the dot's own inset, so it lands on
    // the column rather than on the dot (a margin is space outside the box).
    // Through `bindSpaceField`, not `lk.space()`: the default (5) is the centre
    // of the title's first line, not a step of the spacing ladder, and
    // `lk.space()` throws on a miss — an off-ladder inset would kill the whole
    // entry. The field binds when the step exists and is written as a number
    // (and named in the entry's log line) when it does not.
    bindSpaceField(dotCol, 'paddingTop', lk, dimVal(f.dotTopMargin));
    // A RECTANGLE with a bound corner radius, not an ELLIPSE. The widget's dot is
    // `Container(decoration: dotDecoration)` and the decoration's radius is
    // `dotCornerRadius` (9999 — the scale's fully-round step, which renders as a
    // circle at this size). An ellipse draws the same pixels and states nothing:
    // the radius would be implied by the node type instead of carried by the
    // field, so changing the field could not move it.
    const dot = figma.createRectangle();
    dot.name = 'dot';
    bindSize(dot, lk, f.dotSize, f.dotSize);
    bindRadiusN(dot, lk, f.dotCornerRadius);
    fillData(dot, lk, colorData(f.dotColor));
    dotCol.appendChild(dot);
    ev.appendChild(dotCol);
    bindSize(dotCol, lk, f.dotSize, dotCol.height);
    dotCol.primaryAxisSizingMode = 'FIXED';
    dotCol.counterAxisSizingMode = 'FIXED';
    dotCol.layoutSizingVertical = 'FILL';

    ev.appendChild(timelineGap('column gap', lk, f.columnGapStyle.size));

    // ── content column ────────────────────────────────────────────────────
    const content = panel('content', 'VERTICAL', lk, {});
    content.itemSpacing = 0;
    // `Padding(padding: titlePadding)` around the title only. `bindPad` reads
    // either shape (physical or directional), so a directional value emits as
    // the leading edge rather than as `left`.
    const titleBox = panel('title', 'HORIZONTAL', lk, {});
    bindPad(titleBox, lk, f.titlePadding);
    titleBox.appendChild(makeLabel(e[0], lk, titleOpts));
    content.appendChild(titleBox);
    content.appendChild(timelineGap('content top gap', lk, f.contentTopGapStyle.size));
    // `Expanded(child: Text(description))` — the description takes the content
    // column's width and folds inside it, so a long line adds rows to the event
    // instead of running out of the column. `textAutoResize` BEFORE the FILL
    // statement, the order Card's header/body use: a label that still auto-sizes
    // both axes and is then told to FILL measures against one unwrapped line and
    // never wraps. The height is the text's own (HUG), which is what lets the
    // row below grow with the lines.
    const description = makeLabel(e[2], lk, descriptionOpts);
    description.name = 'description';
    description.textAutoResize = 'HEIGHT';
    content.appendChild(description);
    description.layoutSizingHorizontal = 'FILL';
    description.layoutSizingVertical = 'HUG';
    ev.appendChild(content);
    content.layoutSizingHorizontal = 'FILL';
    titleBox.layoutSizingHorizontal = 'FILL';

    c.appendChild(ev);
    ev.layoutSizingHorizontal = 'FILL';

    // ── connector ─────────────────────────────────────────────────────────
    // Absolute, and that is the widget's own choice restated: it paints the line
    // rather than laying it out precisely so the line can leave the box
    // (`Expanded(SizedBox(width: connectorThickness, CustomPaint(...)))`, which
    // draws from `connectorSpacing` below the top of the box to `connectorReach`
    // past the bottom of it). In Figma an auto-layout child cannot hang outside
    // its parent either, so the line is pinned instead — STRETCH keeps it
    // spanning a row a designer makes taller.
    //
    // Anchored to the dots at both ends, like the widget: it starts
    // `connectorSpacing` below its own dot and stops that far above the next
    // one. The next dot sits `rowSpacing + dotTopMargin` below this row's
    // bottom, so the line runs `rowSpacing + dotTopMargin - connectorSpacing`
    // past it — all three read from the data, none restated here.
    //
    // Read after the row is in the tree AND its width is settled (`ev` FILL in
    // the 360-wide root, the description FILL in the content column above),
    // because that is when Figma has folded the description and `ev.height` is
    // the intrinsic height the widget's `IntrinsicHeight` stands for. A row whose
    // description folds to two lines is 20 taller than one that does not, and the
    // line has to reach that much further to meet the next dot: the length is the
    // row's own height, never an estimate taken before the fold.
    if (i === events.length - 1) continue;
    const span = timelineConnectorSpan(ev.height);
    const line = figma.createRectangle();
    line.name = 'connector';
    fillData(line, lk, colorData(f.connectorColor));
    line.resize(dimVal(f.connectorThickness), span.length);
    pinAbsolute(
      dotCol,
      line,
      (dotSide - dimVal(f.connectorThickness)) / kTimelineHalf,
      span.top,
      { horizontal: 'CENTER', vertical: 'STRETCH' },
    );
  }
  return c;
}

// ─── Tracker (activity bars) ─────────────────────────────────────────────────

// Data-driven from coui_core TRACKER: itemHeight (bar height), itemSpacing
// (gap between bars), endRadius (bar corner radius), and
// variants.defaultsByStatus[*].segmentColor for each bar's fill — replacing
// the old builder's hand-picked semantic-color-name strip with the real
// 4-status dispatch table (fine/warning/critical/unknown), keeping the same
// visual pattern (mostly-fine with a few warning/critical/unknown bars).
//
// ─── Composition: every segment is wrapped in a `Tooltip` ──────────────────
//
// `tracker.dart` renders each segment as `Expanded(child: Tooltip(message:
// segment.tooltip ?? segment.status.name, position: .bottom, child: bar))` —
// the tooltip is not optional decoration, it is how a segment says what it
// is. Nothing in the old preview said so, and the resting canvas cannot show
// it either, because a tooltip is revealed on hover.
//
// So one `Tooltip` instance rides along (`needs: ['Tooltip']`): hidden by
// default, absolutely positioned under the strip the way `position: .bottom`
// places it, and revealed by a BOOLEAN property. `layoutPositioning =
// 'ABSOLUTE'` keeps it out of the bar row's flow — an inline child would
// appear as a 17th segment when switched on, which is a different claim from
// the one the widget makes. One instance rather than sixteen: they are the
// same panel at the same offset from whichever bar is hovered, and sixteen
// stacked copies would only be sixteen chances to disagree.
function buildTracker(page: PageNode, lk: VarLookup): ComponentNode {
  const c = mintPanelComp(page, 'Tracker', 'HORIZONTAL', lk, { gap: TRACKER.fields.itemSpacing });
  c.counterAxisAlignItems = 'CENTER';
  // A `Row` does not clip, and the tooltip below the strip is outside this
  // frame's bounds by construction. Set explicitly because a freshly minted
  // COMPONENT defaults to clipping while `resetNode` clears it on reuse — an
  // unset value would render differently on the first run than on the next.
  c.clipsContent = false;
  const statuses = TRACKER.variants.defaultsByStatus;
  const roles: Array<keyof typeof statuses> = [
    'fine', 'fine', 'fine', 'warning', 'fine', 'fine', 'critical', 'fine',
    'fine', 'warning', 'fine', 'fine', 'fine', 'unknown', 'fine', 'fine',
  ];
  for (const r of roles) {
    const bar = panel('bar', 'HORIZONTAL', lk, { radius: TRACKER.fields.endRadius });
    fillData(bar, lk, colorData(statuses[r].segmentColor));
    c.appendChild(bar);
    // g7-preview-only: the bar's WIDTH (the height beside it is data). Each segment is an `Expanded` in the widget's `Row`, so its width is whatever the parent's constraints divide by sixteen — there is no field to state, and this preview picks the width that fits sixteen in the frame.
    bindSize(bar, lk, 8, TRACKER.fields.itemHeight);
  }
  const hint = instanceOf(page, 'Tooltip');
  hint.name = 'tooltip';
  // Through `pinAbsolute`, which wraps an instance in a plain holder frame and
  // pins the FRAME. Writing `layoutPositioning` on the instance itself is refused
  // ("cannot be overridden in an instance") — not always, which is worse: the same
  // line built here and threw on two other components in the same run.
  const hintPin = pinAbsolute(c, hint, 0, dimVal(TRACKER.fields.itemHeight), { horizontal: 'MIN', vertical: 'MIN' });
  hintPin.visible = false;
  bindVisibleProp(hintPin, defineProp(propertyOwner(c), 'Tooltip', 'BOOLEAN', false));
  return c;
}

// ─── CardImage ───────────────────────────────────────────────────────────────

// Data-driven from coui_core CARD_IMAGE. The frame's chrome is no longer three
// flat fields: `CoreCardImageStyle` states it as ONE nested slot,
// `frameStyle: CoreOutlinedContainerStyle?` — flat
// `backgroundColor`/`borderColor`/`borderRadius` are `@Deprecated` aliases the
// resolver folds in *underneath* it (`card_image_style.dart`:
// `defaultFrameStyle.merge(deprecatedFrameOverride).merge(merged.frameStyle)`),
// and the exporter drops deprecated aliases — so `card_image.fields` carries
// `frameStyle` and no top-level colour at all. Every read below is retargeted
// onto it; that is the only reason this builder changed shape here.
//
// What the exported `frameStyle` says, and where it disagrees with the widget:
// the JSON's `backgroundColor` is `Semantic/color/surface`, `borderColor` is
// `outline-variant`, `borderWidth` 1, `borderRadius` 16 — which is
// `CoreOutlinedContainerStyle`'s OWN default table, not `CardImage`'s
// `defaultFrameStyle` (that one states `.transparent` / `.transparent` / 16,
// "meant to show the image, not a chip around it"). The reader resolves an
// unqualified `defaultBackgroundColor` written *inside* a nested
// `CoreOutlinedContainerStyle(...)` against the nested class (`emit.dart`:
// `targetOwner: owner ?? currentClass`), so the two transparent aliases are
// read as OutlinedContainer's surface pair. Recorded rather than worked around:
// the exporter is not this file's to change, and inventing a `transparent`
// literal here to out-guess the data is the hardcode the token rules forbid.
// The practical effect on the canvas is small — the forward restates the child's
// own resting chrome, so the image layer renders as an un-overridden
// `OutlinedContainer` instance does — and it follows automatically if the
// reader's nested-identifier scope is fixed.
//
// imageContentGapStyle (12 — the image↔content seam, previously un-set/0)
// converts with high confidence. Content padding, the leading↔text↔trailing row
// gap, and the title/subtitle typography have no matching Style fields (OQ-2 —
// CardImage's Style has no typography or content-padding fields at all).
//
// ─── Composition: an `OutlinedContainer` over a `Basic` ────────────────────
//
// `card_image.dart` is three children in a `Flex`: `OutlinedContainer` (the
// image layer), `Gap(imageContentGapStyle)`, and `Basic(leading:, title:,
// subtitle:, trailing:)`. Both of those are unified components with builders
// of their own, so both arrive as instances (`needs: ['Basic',
// 'OutlinedContainer']`).
//
// This replaces a hand-drawn picture that misplaced the chrome as well as the
// structure: `backgroundColor` / `borderColor` / `borderRadius` were painted
// on the CARD root, and the widget hands all three to the *image layer's*
// `CoreOutlinedContainerStyle` — the card root itself has no chrome at all.
// They are applied here as instance overrides, which is Figma's equivalent of
// that forward. `strokes` is cleared first because `borderData` skips a
// transparent colour (correctly — there is nothing to paint), and skipping is
// not the same as removing the border the child already draws.
//
// ─── Slots → Figma properties ─────────────────────────────────────────────
//
// `image` is the one slot CardImage owns a node for: the `OutlinedContainer`
// instance IS the image region, so it carries an `Image` INSTANCE_SWAP. What
// a swap replaces is that layer — the widget's `image` is the container's
// child, and Figma cannot bind a property reference to a node inside an
// instance, so the layer is as close as the slot gets. The chrome CardImage
// forwards onto it — `frameStyle`, the one nested `CoreOutlinedContainerStyle`
// the widget hands to `OutlinedContainer(containerStyle:)` — rides on that same
// node as instance overrides, and a swap drops them the way a swap drops any
// override. It goes on through `applyForwardedPanelStyle`, the same helper
// `Window` uses for its `panelStyle`, because a forwarded child style is the
// same operation whichever parent states it and it is partial by construction:
// only fields `frameStyle` actually states are written, so anything it leaves
// null keeps the child's own resolved value instead of a fallback invented here.
//
// The four text/icon slots come back as the composed `Basic`'s own properties
// rather than as a second copy declared here — CardImage forwards those slots
// to `Basic` in the widget too. Declaring them twice would put the same slot
// in two panels with no rule for which one wins, and there is no node here to
// bind a second copy to that is not a redraw of the child. `exposeNested`
// surfaces whatever the child declares for them in this component's panel,
// which is the one mechanism Figma has for a forwarded slot — and reading the
// child's properties off the instance rather than naming them here is what
// keeps this true when that builder renames one.
//
// `hoverScale` (1.05) / `normalScale` (1) / `hoverDuration` get no POSE axis of
// their own: a uniform 1.05 transform is not chrome, and Figma cannot express it
// on a variant without rescaling every child of the card — a `Hover=true`
// side would render identically to `Hover=false` here, which is exactly the
// kind of axis a designer has to click through for nothing.
//
// #4037 (C4b) — static→variant-set promotion by ADOPTION. `card_image.axes`
// promotes ONLY `enabled` (CoreCardImageStyle has no variant/size/state enum and
// `axes.other` is empty), so the enumeration is two combinations and the loose
// COMPONENT is adopted as `Enabled=true` — the combination the static node
// actually rendered, so its node id and every instance in a consuming file
// survive the promotion. `Enabled=false` renders identically:
// `card_image.fields` declares no disabled field at all — the only state chrome
// it carries is the hover trio above, which a static preview doesn't render
// either. Both members are therefore drawn by the same body, and the honest
// rendering of "no declared disabled chrome" is the same pixels rather than a
// grey one this builder makes up.
//
// ─── Why the `Button` wrapper is NOT composed ──────────────────────────────
//
// `card_image.dart` ends with `if (widget.onPressed == null) return content;`
// and otherwise `Button(variant: .fixed, statesController:, child: content)`.
// Three things about that wrapper, and each one alone would settle it:
//
//   · It paints nothing. `.fixed` is one of the "no-fill" variants —
//     `backgroundColor` / `hoverBackgroundColor` / `disabledBackgroundColor`
//     are all `CoreColor.transparent` and it declares no border and no radius.
//     The widget picks it precisely so a pressable card looks identical to a
//     decorative one; what the wrapper adds is tap, focus and the hover states
//     the card's own `AnimatedScale` reads. That is the same shape as the
//     `Clickable` skip `display.ts`'s `buildCard` states — a wrapper whose
//     whole visible contribution is interaction, not chrome.
//   · It is conditional. The default CardImage has no Button at all, so a
//     component that always contained one would assert a state the widget
//     only sometimes has.
//   · Figma rejects appending children to an instance, and a component's root
//     cannot be one either — nothing on this canvas can hold arbitrary content
//     inside a Button.
//
// Why not the behind-everything placement `buildCard` uses for its
// `OutlinedContainer`, then: that works there because the container IS the
// card's painted surface, so putting it at the back paints the right pixels.
// A `Variant=fixed` Button instance paints none, and it is not empty — every
// Button variant carries its own `Button` label node and two icon holders.
// Behind a CardImage whose `backgroundColor` is itself transparent, that label
// would read straight through the card. A picture the code never paints is
// worse than an absent wrapper.
//
// The Web twin is the same reading from the other side: it composes no Button
// either, and adds `'role': 'button'` to the div it already had, only when
// `onPressed != null`.
// `CoreBasicMainAxisAlignment` → the row's primary-axis alignment. Local to
// this builder rather than borrowed from `display-data.ts`, which keeps its own
// table private; only the members a `CardImage` forward can state are listed,
// and an unknown one throws rather than drawing the row somewhere else.
const kCardImageRowMainAxis: Record<string, 'MIN' | 'CENTER' | 'MAX' | 'SPACE_BETWEEN'> = {
  start: 'MIN',
  center: 'CENTER',
  end: 'MAX',
  spaceBetween: 'SPACE_BETWEEN',
};

// The text node inside the cell named [cell], searched through `children` —
// a composed `Basic` keeps each slot's line in an `Align` cell of that name.
function cellText(node: SceneNode, cell: string): TextNode | null {
  if (!('children' in node)) return null;
  for (const kid of node.children) {
    if (kid.name === cell && 'children' in kid) {
      const text = kid.children.find((n) => n.type === 'TEXT');
      if (text !== undefined && text.type === 'TEXT') return text;
    }
    const found = cellText(kid, cell);
    if (found !== null) return found;
  }
  return null;
}

async function buildCardImage(page: PageNode, lk: VarLookup): Promise<ComponentSetNode> {
  // `direction` decides whether the image sits above the content or beside it —
  // the widget branches its `Flex` on it, and `vertical` is what the recipe
  // states. Read rather than assumed: the axis was hardcoded, so a recipe that
  // said `horizontal` would still have drawn a column.
  const f = CARD_IMAGE.fields;
  const box = f.containerStyle;
  const frame = f.frameStyle;
  const row = f.contentStyle;
  const rowMain = kCardImageRowMainAxis[row.mainAxisAlignment.choice];
  if (rowMain === undefined) {
    throw new Error(
      `CardImage: contentStyle.mainAxisAlignment "${row.mainAxisAlignment.choice}" ` +
        `has no row alignment here. Known: ${Object.keys(kCardImageRowMainAxis).join(', ')}.`,
    );
  }
  const boxBorder = colorData(box.borderColor);
  const dim = dimVal(f.disabledContentOpacity);
  const combos = enumerateAxisCombos(axisSpecsOf(CARD_IMAGE.axes));
  const mount = mountSet(page, 'CardImage', combos, { adoptLooseAs: 'Enabled=true' });
  // Collected across variants and bound after `finish()`, for the reason
  // `buildWindow` states: a component property belongs to the SET, and
  // `propertyOwner` inside this loop answers with the MEMBER — `getOrCreate`
  // hands back a parentless COMPONENT that only joins the set in `finish()` —
  // so each member would declare its own copy of `Image`.
  const images: InstanceNode[] = [];
  for (const comboName of combos) {
    const c = mount.getOrCreate(comboName);
    // The card's box — `containerStyle`, the outer `OutlinedContainer` the
    // widget wraps the column in. Painted on the root, the way `Command`
    // paints its composed panel: an instance cannot hold the column, and the
    // box is the card's whole face, so the root is where it reads true. Its
    // edge, corners and bottom inset are bound here; the fill goes to the
    // material layer below.
    const chrome: ChromeOpts = {
      gap: f.imageContentGapStyle.size,
      radius: box.borderRadius.topLeft,
      pl: box.padding.l,
      pr: box.padding.r,
      pt: box.padding.t,
      pb: box.padding.b,
    };
    if (boxBorder != null && boxBorder.color != null && dimVal(box.borderWidth) > 0) {
      chrome.border = boxBorder.color;
      chrome.borderOp = boxBorder.opacity;
      chrome.borderArgb = boxBorder.argb;
      chrome.strokeN = box.borderWidth;
    }
    applyPanelCompChrome(
      c,
      f.direction.choice === 'horizontal' ? 'HORIZONTAL' : 'VERTICAL',
      lk,
      chrome,
    );
    // A content surface on both platforms: the box is a composed
    // `OutlinedContainer` (`theme.surfaceFor(.content)` on Flutter, the
    // `coui-surface-content` marker on Web).
    // The cast: `containerStyle.boxShadow` (the `xs` stack) at rest, and the
    // disabled layer's explicitly empty stack once the card is unavailable —
    // the resolver lays `disabledContainerStyle` over the box. The rim rides
    // only a cast the box states, as both platforms draw it.
    const disabled = comboName.includes('Enabled=false');
    const cast = disabled ? f.disabledContainerStyle.boxShadow : box.boxShadow;
    applySurfaceMaterial(c, lk, colorData(box.backgroundColor), 'content', {
      radius: box.borderRadius.topLeft,
      rim: cast.layers.length > 0,
    });
    setShadow(c, cast, lk, colorData(box.shadowBaseColor));
    await linkShadowStyle(c, cast, `CardImage/${comboName}`);
    // The box clips — that is what rounds the image's top corners, since the
    // frame states square ones.
    c.clipsContent = clipsFor(box.clipBehavior, 'card_image.containerStyle.clipBehavior');

    const image = instanceOf(page, 'OutlinedContainer');
    image.name = 'image';
    // Same as Carousel's slide: the stand-in glyph is stated off rather than
    // inherited, because an existing instance keeps what it was created with.
    setInstanceBoolNamed(image, 'Show child', false);
    c.appendChild(image);
    // Cleared before the forward, not after: `borderData` returns early on a
    // transparent colour — correctly, there is nothing to paint — and skipping
    // a write is not the same as removing the border the child already draws.
    image.strokes = [];
    applyForwardedPanelStyle(image, lk, {
      backgroundColor: colorData(frame.backgroundColor),
      borderColor: colorData(frame.borderColor),
      borderWidth: frame.borderWidth,
      borderRadius: frame.borderRadius,
      padding: frame.padding,
    });
    image.layoutSizingHorizontal = 'FILL';
    image.resize(image.width, kCardImageHeight);
    image.layoutSizingVertical = 'FIXED';
    images.push(image);

    const content = instanceOf(page, 'Basic');
    content.name = 'content';
    c.appendChild(content);
    content.layoutSizingHorizontal = 'FILL';
    // `contentStyle`, forwarded onto the composed `Basic`: its inset (start
    // 14 · end 10 — `bindPad` resolves start/end the one way this file does),
    // its row alignment, and the subtitle's colour. The title keeps `Basic`'s
    // own, which the forward does not restate.
    bindPad(content, lk, row.padding);
    content.primaryAxisAlignItems = rowMain;
    const subtitle = cellText(content, 'subtitle');
    if (subtitle === null) {
      throw new Error(
        'CardImage: no subtitle text under the composed Basic — its `subtitle` ' +
          'cell was renamed, so `contentStyle.subtitleTextStyle` lands nowhere.',
      );
    }
    fillData(subtitle, lk, colorData(row.subtitleTextStyle.color));
    exposeNested(content);

    lockWidth(c, kCardImageWidth);

    const placeholder = makeIcon('image', lk, {
      size: kCardImagePlaceholderSize,
      // g7-preview-only: the placeholder glyph's ink — the designer's pick for a "picture goes here" mark; no CardImage field states it, as no field states the glyph.
      colorVar: lk.sem('on-surface-subtle'),
      placeholder: true,
    });
    placeholder.name = 'image icon';
    // Centred over the stand-in image, and kept there when the card is
    // resized — the image is the card's width and its preview height.
    pinAbsolute(
      c,
      placeholder,
      (kCardImageWidth - kCardImagePlaceholderSize) / 2,
      (kCardImageHeight - kCardImagePlaceholderSize) / 2,
      { horizontal: 'CENTER', vertical: 'MIN' },
    );

    // `enabled: false` dims the image and the text row to
    // `disabledContentOpacity`; the box keeps its fill and edge.
    if (disabled) {
      for (const node of [image, content, placeholder]) {
        node.opacity = dim;
        const rung = lk.opacityOrNull(dim);
        if (rung) node.setBoundVariable('opacity', rung);
      }
    }
  }
  const set = mount.finish();
  // Bound after the instance has a parent, never before: a detached node rejects
  // `componentPropertyReferences` ("Can only set component property references
  // on symbol sublayer") and the throw fails the entry, leaving a half-drawn
  // component on the page.
  const imageProp = defineProp(
    set,
    'Image',
    'INSTANCE_SWAP',
    mainIdOf(page, 'OutlinedContainer'),
  );
  for (const image of images) bindSwapProp(image, imageProp);
  rowSet(set);
  return set;
}

// ─── The dots' tone ──────────────────────────────────────────────────────────
//
// `resolveCarousel` hands the `DotIndicator` its own active and inactive colours
// (`indicatorActiveColor` / `indicatorInactiveColor`, defaulting to `primary` and
// `outline`) rather than letting the dots take theirs, so the carousel's dots and
// a bare `DotIndicator`'s no longer agree. Figma has no nested-style slot to
// forward them through, so they land on the nodes the instance draws: the
// selected dot is the `Rectangle` in the `dot 1` cell, the rest are the
// `dot N` rectangles.
//
// The active dot's corner is the number the designer drew: half its side, which
// is the circle it always was (`radius/9999` clamps to the same shape). It is
// stated on the cell as well as on the dot — the cell is what a reader of the
// layer panel sees. The half-side is geometry, not an independently authored
// radius: the 6px row still draws an unbound 3px corner.
//
// The selected dot is told apart from the rest by its shape in the tree, not by
// its name: it is the one wrapped in a cell (a FRAME holding the `focus ring`
// instance and the dot), wherever the `Selected` axis puts it. The rest are bare
// rectangles named `dot N`.
function toneIndicatorDots(dots: InstanceNode, lk: VarLookup, size: string): void {
  const rows = COMPONENTS.dot_indicator.sizes.defaultsBySize as unknown as Record<
    string,
    { dotSize: Dim }
  >;
  const row = rows[size];
  if (!row) {
    throw new Error(
      `Carousel: DotIndicator has no size row for "${size}" — the carousel's ` +
        'Size axis and the dot indicator\'s no longer map one to one.',
    );
  }
  const active = colorData(CAROUSEL.fields.indicatorActiveColor);
  const inactive = colorData(CAROUSEL.fields.indicatorInactiveColor);
  const geometry = boxGeometry(lk, row.dotSize, row.dotSize);
  let seenActive = false;
  for (const node of dots.children) {
    if (node.type === 'FRAME') {
      const dot = node.children.find((kid) => kid.type === 'RECTANGLE');
      if (dot === undefined || dot.type !== 'RECTANGLE') continue;
      fillData(dot, lk, active);
      bindRoundBoxRadius(dot, lk, geometry);
      bindRoundBoxRadius(node, lk, geometry);
      seenActive = true;
    } else if (node.type === 'RECTANGLE') {
      fillData(node, lk, inactive);
    }
  }
  if (!seenActive) {
    throw new Error(
      `Carousel: no selected dot under the ${dots.name} DotIndicator — the cell ` +
        'that wraps it was reshaped, so the active tone lands nowhere.',
    );
  }
}

// ─── Carousel ────────────────────────────────────────────────────────────────

// Data-driven from coui_core CAROUSEL: borderRadius (slide corner radius),
// navInset (the prev/next controls' inset from the slide edges) and
// indicatorInset (the indicator row's anchor).
//
// ─── Structure: the root is the widget's `Stacks`, not a column ─────────────
//
// `Carousel`'s build is one stack — `Stacks(children: [slides,
// Position.fill(navButtons), Position(indicatorInset)(indicators)])`. Both
// controls sit ON the slide. This preview used to render the dots as a
// separate row *under* the image, which put `indicatorInset` out of reach and
// told a designer the indicator was a sibling of the viewport rather than an
// overlay on it. The root is now an absolutely-laid-out frame (that is what
// `Stacks` is here — there is no node to instantiate for a layout primitive
// with no chrome), the nav row is `Position.fill` + `Padding(navInset)`, and
// the indicator row is a full-bleed overlay whose bottom-anchored, centred
// child is `Position(indicatorInset)` + `Center`. Both insets stay bound as
// auto-layout padding, so the anchor keeps its token provenance instead of
// becoming an x/y literal — Figma cannot bind a Variable to `x`/`y`.
//
// ─── Composition: the nav controls are `Button` instances ──────────────────
//
// `CoreCarouselStyle.prevNextButtonStyle` is a `CoreButtonStyle` slot, and
// the widget forwards it straight to `Button(variant: .ghost, size: .sm)` on
// both platforms — so the two controls are Buttons, not carousel-shaped
// approximations of one. They arrive here as instances of the `Button`
// component (`needs: ['Button']`) rather than as hand-drawn boxes: an
// instance follows the main component when Button's own chrome changes,
// whereas a redrawn copy keeps painting whatever Button looked like the day
// it was copied — and the content-hash skip means a run that only changed
// Button never re-enters this builder to notice.
//
// `navFadeDuration` is the hover reveal's timing (the controls are hidden until
// the pointer enters the viewport), and Figma renders one moment — the canvas
// shows the revealed one, the same choice `Tracker` makes for its hover-only
// tooltip.
//
// ─── The nav controls are raised faces, and the pair is arranged by variant ──
//
// `prevNextButtonStyle` states an opaque `surface-raised` fill, a one-pixel
// `outline-variant` edge drawn INSIDE the disc, and the `sm` cast
// (`CoreShadow.sm`, the nearest step to the 0 1 3 · 12% the designer draws) —
// the edge and the cast are forwarded onto the instance exactly as the fill is.
// `slide` puts one button at each end of the viewport; `banner` gathers the pair
// at the trailing end, `navGapStyle` apart.

// ─── What the instance does NOT inherit from its variant ────────────────────
//
// Composing the child is not the whole forward. `resolveCarousel` hands
// `Button` a `navButtonStyle`, and the widget passes `shape: .circle` — so the
// instance is the `Shape=circle` member of `Variant=ghost, Size=sm`, not the
// rectangle one. The shape is an axis of the child, and it is the axis that
// decides the disc: `button_style.dart` floors the width at the height for
// `circle`, swaps the content padding for `iconShapePadding`, and collapses
// the radius to `circleBorderRadius`. Composing the rectangle member and then
// zeroing its padding left a 20-wide sliver hugging the glyph — the shape was
// being approximated with overrides instead of asked for by name.
//
// Two values still travel as instance overrides, exactly as `CardImage`
// overrides the `OutlinedContainer` it composes two functions up:
//
//   · `controlOverlayColor` (surface at 80%) replaces ghost's background, which
//     is `surface-container` at opacity ZERO — the widget's control is a
//     frosted disc and the canvas painted nothing at all. The alpha travels on
//     the paint (`fillData` passes `opacity` into the `SolidPaint`), because a
//     Variable binding carries the colour and not its transparency: binding
//     `Semantic/color/surface` alone would paint the disc opaque and hide the
//     slide behind it. This was reported from the real file as "opacity is not
//     applied".
//   · `circleBorderRadius` / `iconShapePadding` from the exported slot — the
//     two fields the `circle` branch of the resolver reads
//     (`merged.circleBorderRadius ?? default`, `merged.iconShapePadding ??
//     default`). They are byte-identical to what the circle member already
//     carries (9999 / zero), and are bound anyway so a `prevNextButtonStyle`
//     that states different ones moves the canvas — the rectangle-branch
//     `padding` the slot also exports is never read for this shape.
//
// `itemSpacing` goes to zero for a structural reason rather than a stated one:
// the widget's row is `[child]` — one child — so no `Gap` is materialised
// between anything, while the instance carries a row of three (glyph, label,
// trailing). With the label emptied and the trailing slot off, a surviving gap
// would push the glyph off the disc's centre by half of itself.
//
// Left as the child's own: `foregroundColor` (`defaultNavButtonForegroundColor`
// is `on-surface`, byte-identical to ghost's, so the glyph is already right)
// and the size row's height.
//
// NOT expressible from the data: the disc is square —
// `defaultPrevNextButtonStyle` sets `width`/`height` to `defaultNavButtonSize`
// (40 = 2×8 + 24, `carousel_style.dart:155`) — but the exporter drops
// `width`/`height`/`backgroundColor`/`foregroundColor` from a nested
// `CoreButtonStyle` slot (those live in Button's per-size / per-variant tables,
// not in a flat `default*`), so `components.json` states no side here. The
// instance keeps Button's `sm` row (32), and the circle member floors its width
// at that height, so the disc is 32 on the canvas and 40 in the widget. Writing
// 40 would be inventing the one number this file must not.
//
// ─── Composition: the indicator is a `DotIndicator` ─────────────────────────
//
// `resolveCarousel` builds a `CoreDotIndicatorStyle` and forwards it to
// `DotIndicator(index:, length:, dotIndicatorStyle:)`, so the dots are that
// component — not three ellipses this file sizes and paints itself. Same
// treatment as the nav buttons, and the same consequence: `indicatorSpacing`
// / `indicatorActiveColor` / `indicatorInactiveColor` are the parent's
// per-instance override of the child's own chrome, and they now live inside
// the `DotIndicator` instance rather than as literals here (Figma has no
// nested-style slot to forward them through). The two colours default to the
// carousel's own tone (`primary` / `outline`), not the child's, so they are
// written onto the instance's dots (`toneIndicatorDots`, above).
//
// ─── The chevron goes in through Button's own slot ─────────────────────────
//
// Each control is `Button(child: Icon(LucideIcons.chevronLeft | chevronRight))`
// and Figma rejects appending to an instance, so the glyph cannot be a child of
// the node here. It goes where `Button` keeps its child instead — the `Leading`
// holder plus the `Leading icon` swap, set on the instance (`needs: ['Icon']`
// so the glyph's main component is on the page to point at).
//
// Not left empty, and not redrawn beside the button: prev and next differ
// *by* their glyph, so two glyph-less ghost circles are the same picture twice
// and neither says which way it goes.
//
// And the label that slot sits beside is emptied in the same breath
// (`clearInstanceLabel`), because `Button`'s TEXT property defaults to the demo
// word "Button" and the widget's control has no text at all. Turning the glyph
// on without clearing the word is what shipped: a translucent-less pill reading
// "Button" with a chevron in front of it.
//
// This is the child's own slot rather than an `instanceOf`/`makeIcon` call, so
// `figma_composition_parity` — which credits an Icon on those two spellings —
// still counts this edge as missing. The edge is drawn; the guard's regex
// cannot see through `setProperties`.
// The designer's set — `Variant=slide|banner × Size=sm|md` — is the set the
// contract states now (`CoreCarouselVariant` × `CoreCarouselSize`), so the
// builder enumerates it rather than folding it:
//
// ```text
// Variant=slide                         Variant=banner
// root (per-size box, layers)           root (VERTICAL, gap = indicatorBelowGapStyle)
//   ├─ slide  ← `Slide` swap              ├─ viewport (HORIZONTAL, hug, radius = borderRadius)
//   ├─ nav    ← `Show nav`                │    └─ slide — a `CarouselBanner`, exposed
//   └─ indicators ← `Show indicators`     └─ dots (DotIndicator) ← `Show indicators`
//        └─ dots (DotIndicator)
// ```
//
// Two things moved out of this file to get there.
//
// The strip itself is a `CarouselBanner` instance. It used to be drawn here —
// inset, thumbnail side, two type roles, all literals — because no component
// stated that shape: `Card` was the near miss and it stacks media ABOVE text,
// which put a different picture on the canvas than the one she drew. A
// component states it now, so this composes it, and the four properties
// (`Title` / `Description` / `Show description` / `Show thumbnail`) are that
// component's — reached through the exposed instance, because a parent TEXT
// property cannot drive a nested instance's text.
//
// `Size` decides two things and neither is the carousel's own extent (that
// comes from the parent): the indicator dot size, mapped the way both
// resolvers map it, and which `CarouselBanner` member the strip is. The
// preview boxes per screen are the canvas picking a phone and a desktop
// (`kCarouselSlideSize` / `kCarouselBannerWidth`, g7-preview-only).
//
// Nothing renames or retires here any more. The fold rows that rewrote her
// axes — and the rows that retired the md members — are gone from
// `renames.ts`: leaving them would re-collapse the set on the next Generate,
// which is the exact loop that lost her work twice.
function buildCarousel(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = CAROUSEL.fields;
  const variantAxis = CAROUSEL.axes.variant;
  const sizeAxis = CAROUSEL.axes.other.find(
    (o) => o.enum === 'CoreCarouselSize',
  );
  if (!variantAxis || !sizeAxis) {
    throw new Error(
      'Carousel: CoreCarouselVariant / CoreCarouselSize are gone from the ' +
        'exported axes — the canvas has Variant × Size axes that nothing in ' +
        'the contract now backs.',
    );
  }
  const combos = enumerateAxisCombos([
    { axis: 'Variant', values: variantAxis.members },
    { axis: 'Size', values: sizeAxis.members },
  ]);
  const mount = mountSet(page, 'Carousel', combos, {
    // What the legacy single COMPONENT actually drew: a slide with the dots
    // inset over it, at the smaller of the two screens.
    adoptLooseAs: composeVariantName([
      ['Variant', restingValueOf('Variant')],
      ['Size', restingValueOf('Size')],
    ]),
  });
  // Only the `slide` members' content takes the `Slide` swap. A set-level
  // INSTANCE_SWAP has ONE value across every variant, so binding the banner
  // member's strip to it too would swap that strip for the property's default
  // (`OutlinedContainer`) on the first Generate — which is exactly what
  // happened. The banner slide is the exposed `CarouselBanner` and stays out
  // of `Slide`.
  const swapSlides: InstanceNode[] = [];
  const navLayers: FrameNode[] = [];
  const indicatorNodes: SceneNode[] = [];
  const banners: InstanceNode[] = [];
  const navVariant = restingVariant(page, 'Button', {
    Variant: 'ghost',
    Size: 'sm',
    Shape: 'circle',
  });
  const navGlyphs: { side: string; glyph: string }[] = [
    { side: 'prev', glyph: 'chevron-left' },
    { side: 'next', glyph: 'chevron-right' },
  ];
  const navButton = f.prevNextButtonStyle;
  // The glyph's step: `Button(size: .sm, shape: .circle, child: const
  // Icon(chevronLeft))` — the `Icon` carries no style of its own and takes the
  // button's ambient icon theme, which for a circle is `Button`'s `sm` row
  // `iconShapeIconStyle` (16, the glyph of a button with no label beside it).
  // Swapped to that step rather than the set's default, which is what the slot
  // rendered at while the row said otherwise. The Web twin reads the same row.
  const navIconId = iconMainIdAt(
    page,
    dimVal(COMPONENTS.button.sizes.defaultsBySize.sm.iconShapeIconStyle.size),
  );
  // The glyph's colour: the chevron `Icon` inherits the Button's foreground,
  // and the Button's foreground is the one `prevNextButtonStyle` forwards.
  // Stated here rather than left to the ghost member's own leading tint — the
  // two are the same token today, which is agreement by coincidence.
  const navGlyphPaint = glyphPaint(lk, labelColor(lk, colorData(navButton.foregroundColor)));
  // The prev / next pair overlays the viewport in BOTH placements — the widget
  // stacks them over the slides regardless of where the dots go. What differs
  // is the arrangement: `slide` puts one button at each end of the viewport
  // (SPACE_BETWEEN), `banner` is a strip too short for that and gathers the
  // pair at the trailing end with `navGapStyle` between them (MAX +
  // `itemSpacing`), as the widget's `Row(mainAxisAlignment: .end)` does.
  const buildNav = (placement: 'ends' | 'trailing'): FrameNode => {
    const nav = panel('nav', 'HORIZONTAL', lk, {});
    bindPad(nav, lk, f.navInset);
    if (placement === 'ends') {
      nav.primaryAxisAlignItems = 'SPACE_BETWEEN';
    } else {
      nav.primaryAxisAlignItems = 'MAX';
      bindSpaceField(nav, 'itemSpacing', lk, dimVal(f.navGapStyle.size));
    }
    nav.counterAxisAlignItems = 'CENTER';
    for (const nb of navGlyphs) {
      const button = instanceOf(page, 'Button', navVariant);
      button.name = nb.side;
      nav.appendChild(button);
      setSlotIcon(button, 'Leading', navIconId, nb.glyph, navGlyphPaint);
      clearInstanceLabel(button);
      fillData(button, lk, colorData(f.controlOverlayColor));
      bindRadiusN(button, lk, navButton.circleBorderRadius.topLeft);
      bindPad(button, lk, navButton.iconShapePadding);
      button.setBoundVariable('itemSpacing', lk.space(0));
      // The pair sits over the slides in both placements, and a slide is
      // content the carousel cannot know — so `prevNextButtonStyle` states an
      // opaque band under the ring instead of Button's transparent default.
      forwardFocusBand(button, lk, navButton.focusOutlineStyle);
      // The raised face: an edge drawn inside the disc, and the cast. Both are
      // fields of `prevNextButtonStyle`, so a restated style moves them — and
      // the fill above is opaque, so the cast reads as the shadow of a body.
      applyForwardedButtonStyle(button, lk, {
        borderColor: colorData(navButton.borderColor),
        borderWidth: navButton.borderWidth,
      });
      button.strokeAlign = 'INSIDE';
      setShadow(button, navButton.boxShadow, lk);
    }
    navLayers.push(nav);
    return nav;
  };
  // The dot size is the carousel's own size axis, mapped the way both
  // resolvers map it — two sizes here, three there.
  const dotsVariantFor = (size: string): string =>
    composeVariantName([
      ['Size', size],
      ['Selected', restingValueOf('Selected')],
    ]);
  for (const comboName of combos) {
    const keys = parseVariantKey(comboName);
    const below = keys['Variant'] === 'banner';
    const size = keys['Size'];
    const dotsVariant = dotsVariantFor(size);
    const c = mount.getOrCreate(comboName);
    const slideBox = kCarouselSlideSize[size];
    if (!slideBox) {
      throw new Error(
        `Carousel: no preview box for Size="${size}" — \`kCarouselSlideSize\` ` +
          'is keyed by the axis member and one of them was renamed.',
      );
    }
    if (!below) {
      // ─── slide — the layered preview, at this screen's box ────────────────
      c.layoutMode = 'NONE';
      c.fills = [];
      c.clipsContent = true;
      // The widget's `ClipRRect` is this member. Binding
      // `defaultBorderRadius` here is what puts radius16 on the component
      // the designer selects; the inner `slide` frame carries the same
      // token so the layer and the clip agree. An unbound member stays at
      // Figma's default 0, which is the corner the canvas was reporting.
      bindRadiusN(c, lk, f.borderRadius.topLeft);
      c.resize(slideBox.w, slideBox.h);
      const slideFrame = panel('slide', 'HORIZONTAL', lk, {
        radius: f.borderRadius.topLeft,
      });
      slideFrame.clipsContent = true;
      slideFrame.primaryAxisSizingMode = 'FIXED';
      slideFrame.counterAxisSizingMode = 'FIXED';
      c.appendChild(slideFrame);
      slideFrame.resize(slideBox.w, slideBox.h);
      slideFrame.x = 0;
      slideFrame.y = 0;
      // The three layers span the member: a designer who FILLs a slide gets a
      // wider slide, not a wider frame around the same picture (#4805).
      slideFrame.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };
      // The slide is an instance so the designer's `Slide` swap has a node to
      // drive; `OutlinedContainer` is what her set defaulted it to.
      const content = instanceOf(page, 'OutlinedContainer');
      content.name = 'content';
      // Stated, not inherited — an instance already on the designer's file
      // carries the value it was created with, and this one was created when
      // the wrapper's stand-in glyph was on by default. That is the file icon
      // she reported in the empty slide.
      setInstanceBoolNamed(content, 'Show child', false);
      slideFrame.appendChild(content);
      content.layoutSizingHorizontal = 'FILL';
      content.layoutSizingVertical = 'FILL';
      swapSlides.push(content);
      const nav = buildNav('ends');
      nav.primaryAxisSizingMode = 'FIXED';
      nav.counterAxisSizingMode = 'FIXED';
      c.appendChild(nav);
      nav.resize(slideBox.w, slideBox.h);
      nav.x = 0;
      nav.y = 0;
      nav.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };
      const indicators = panel('indicators', 'VERTICAL', lk, {});
      bindPad(indicators, lk, f.indicatorInset);
      indicators.primaryAxisAlignItems = 'MAX';
      indicators.counterAxisAlignItems = 'CENTER';
      indicators.primaryAxisSizingMode = 'FIXED';
      indicators.counterAxisSizingMode = 'FIXED';
      const dots = instanceOf(page, 'DotIndicator', dotsVariant);
      dots.name = 'dots';
      // Here the dots sit ON the slide, so the selected dot's ring gets the
      // opaque band the resolvers put into the dot style for this placement
      // only. Below the strip (the banner branch) they sit on the page, and
      // the transparent default is the band.
      forwardFocusBand(dots, lk, CAROUSEL.fields.overlayIndicatorFocusOutlineStyle, 'fill');
      toneIndicatorDots(dots, lk, size);
      indicators.appendChild(dots);
      c.appendChild(indicators);
      indicators.resize(slideBox.w, slideBox.h);
      indicators.x = 0;
      indicators.y = 0;
      indicators.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };
      indicatorNodes.push(indicators);
      continue;
    }
    // ─── below — viewport in flow, dots under it ─────────────────────────────
    // ─── banner — the strip in flow, dots under it ────────────────────────
    applyPanelCompChrome(c, 'VERTICAL', lk, {});
    c.counterAxisAlignItems = 'CENTER';
    c.setBoundVariable('itemSpacing', lk.space(dimVal(f.indicatorBelowGapStyle.size)));
    const bannerWidth = kCarouselBannerWidth[size];
    if (!bannerWidth) {
      throw new Error(
        `Carousel: no banner preview width for Size="${size}" — ` +
          '`kCarouselBannerWidth` is keyed by the axis member and one of them ' +
          'was renamed.',
      );
    }
    lockWidth(c, bannerWidth);
    const viewport = panel('viewport', 'HORIZONTAL', lk, {
      radius: f.borderRadius.topLeft,
    });
    viewport.clipsContent = true;
    c.appendChild(viewport);
    viewport.layoutSizingHorizontal = 'FILL';
    viewport.layoutSizingVertical = 'HUG';
    // The slide is a `CarouselBanner` instance, at the size this member is.
    // It used to be drawn here — inset, thumbnail, two type roles, all
    // literals — because no component stated that shape. One does now, so
    // this composes it: the strip's metrics live in `CoreCarouselBannerStyle`
    // and an instance follows the main component when they change, whereas a
    // redrawn copy keeps painting whatever the strip looked like the day it
    // was copied.
    const slide = instanceOf(
      page,
      'CarouselBanner',
      composeVariantName([['Size', size]]),
    );
    slide.name = 'slide';
    viewport.appendChild(slide);
    slide.layoutSizingHorizontal = 'FILL';
    slide.layoutSizingVertical = 'HUG';
    banners.push(slide);
    // The nav spans the viewport, as it does on the slide members and on both
    // platforms, but gathers the pair at the trailing end: next at the end
    // inset, prev beside it `navGapStyle` away, both centred across. `panel`
    // makes it hug, and a hugging layer pinned STRETCH stays the size of its two
    // buttons — they sat side by side in the strip's top-left corner. FIXED, and
    // the viewport's size once the strip has settled it.
    const nav = buildNav('trailing');
    nav.primaryAxisSizingMode = 'FIXED';
    nav.counterAxisSizingMode = 'FIXED';
    pinAbsolute(viewport, nav, 0, 0, { horizontal: 'STRETCH', vertical: 'STRETCH' });
    const dots = instanceOf(page, 'DotIndicator', dotsVariant);
    dots.name = 'dots';
    toneIndicatorDots(dots, lk, size);
    c.appendChild(dots);
    indicatorNodes.push(dots);
    sizePin(nav, viewport.width, viewport.height);
  }
  const set = mount.finish();
  // Properties adopted from the designer's set BY NAME (`defineProp` reuses a
  // same-name+type definition, so her ids survive).
  const slideProp = defineProp(
    set,
    'Slide',
    'INSTANCE_SWAP',
    mainIdOf(page, 'OutlinedContainer'),
  );
  for (const n of swapSlides) bindSwapProp(n, slideProp);
  const showNav = defineProp(set, 'Show nav', 'BOOLEAN', true);
  for (const n of navLayers) bindVisibleProp(n, showNav);
  const showIndicators = defineProp(set, 'Show indicators', 'BOOLEAN', true);
  for (const n of indicatorNodes) bindVisibleProp(n, showIndicators);
  // The banner slide's four properties (`Title` / `Description` /
  // `Show description` / `Show thumbnail`) are `CarouselBanner`'s now, and
  // they arrive through the exposed instance rather than being re-declared
  // here — a parent TEXT property cannot drive a nested instance's text
  // (the same limit `TabItem`'s count badge hits). Exposure is what puts
  // them on this set's own panel.
  for (const banner of banners) {
    try {
      banner.isExposedInstance = true;
    } catch {
      // The document double has no exposure; the live plugin does.
    }
  }
  return set;
}

// ─── CarouselBanner ──────────────────────────────────────────────────────────
//
// The promotional strip a `banner` carousel cycles: a thumbnail beside a
// title and a supporting line. Two members, because that is what the
// contract's size axis states, and every metric that separates them lives in
// `CoreCarouselBannerStyle.defaultsBySize` — inset, thumbnail side, both
// gaps, both type roles. So this builder reads a row and binds it; there is
// no literal here for anything the strip's own height depends on.
//
// The four properties are the designer's, adopted by name (`defineProp`
// reuses a same-name+type definition, so her ids survive): `Title` and
// `Description` are the two text nodes, `Show description` hides the second
// line, `Show thumbnail` hides the picture. Carousel exposes an instance of
// this set rather than re-declaring them, which is why they are here and not
// there.
function buildCarouselBanner(page: PageNode, lk: VarLookup): ComponentSetNode {
  const sizeAxis = CAROUSEL_BANNER.axes.other.find(
    (o) => o.enum === 'CoreCarouselBannerSize',
  );
  if (!sizeAxis) {
    throw new Error(
      'CarouselBanner: CoreCarouselBannerSize is gone from the exported axes ' +
        '— the canvas has a Size axis that nothing in the contract now backs.',
    );
  }
  const f = CAROUSEL_BANNER.fields;
  const rows = new Map(Object.entries(CAROUSEL_BANNER.sizes.defaultsBySize));
  const combos = enumerateAxisCombos([
    { axis: 'Size', values: sizeAxis.members },
  ]);
  // The thumbnail stand-in is drawn from the `Thumbnail` property's default,
  // so the first bind leaves it at `thumbnailSize` (see `IconOpts.fromVariant`).
  const thumbnailSwap = iconSwapDefault(page, 'CarouselBanner', 'Thumbnail', iconMainId(page));
  const mount = mountSet(page, 'CarouselBanner', combos, {
    adoptLooseAs: composeVariantName([['Size', restingValueOf('Size')]]),
  });
  const thumbs: FrameNode[] = [];
  const pictures: InstanceNode[] = [];
  const titles: TextNode[] = [];
  const descriptions: TextNode[] = [];
  for (const comboName of combos) {
    const size = parseVariantKey(comboName)['Size'];
    const row = rows.get(size);
    if (!row) {
      throw new Error(
        `CarouselBanner: no size row for "${size}" — \`defaultsBySize\` and the ` +
          'Size axis disagree about which members exist.',
      );
    }
    const c = mount.getOrCreate(comboName);
    applyPanelCompChrome(c, 'HORIZONTAL', lk, {
      bg: colorData(f.backgroundColor)?.color ?? undefined,
      radius: f.borderRadius.topLeft,
      pl: row.padding.l,
      pr: row.padding.r,
      pt: row.padding.t,
      pb: row.padding.b,
      gap: row.thumbnailTextGapStyle.size,
    });
    c.counterAxisAlignItems = 'CENTER';
    // g7-preview-only: the strip's own width. The widget's root takes it from
    // the carousel viewport it fills, so nothing states one — the canvas has
    // to pick a screen, and the two it picks are the carousel's.
    lockWidth(c, kCarouselBannerWidth[size] ?? kCarouselBannerWidth['sm']!);
    const thumb = panel('thumb', 'HORIZONTAL', lk, {
      bg: colorData(f.thumbnailBackgroundColor)?.color ?? undefined,
      radius: f.thumbnailBorderRadius.topLeft,
    });
    thumb.clipsContent = true;
    thumb.primaryAxisAlignItems = 'CENTER';
    thumb.counterAxisAlignItems = 'CENTER';
    c.appendChild(thumb);
    // Square, and it is what sets the strip's height: inset + this + inset.
    bindSize(thumb, lk, row.thumbnailSize, row.thumbnailSize);
    thumbs.push(thumb);
    // `thumbnail` is a `W?` slot — any widget. Its Figma equivalent is an
    // INSTANCE_SWAP, so the box holds a swappable stand-in rather than
    // painting a bare rectangle: a designer picks what goes in there the
    // same way a caller passes a widget.
    //
    // The stand-in is the slot's icon half: an `Icon` handed to the thumbnail
    // is a mark, not a picture, so it is centred in the square at the row's
    // `thumbnailIconStyle` size and tone (24, `on-surface-variant`) instead
    // of being stretched to the whole side. The box above is centred on both
    // axes, which is what places it. A picture handed in takes the square,
    // which a swapped-in instance does by being resized — the other half of
    // the rule, and not something this stand-in draws. The size is the
    // slot's own, not an Icon rung (`placeholder`), and the stroke is whatever
    // the rule gives that size (`CoreIconStroke`), never a field here.
    const iconRow = row.thumbnailIconStyle;
    const picture = makeIcon('image', lk, {
      ...glyphOpts(lk, colorData(iconRow.color), iconRow.size, 'size'),
      placeholder: true,
      fromVariant: thumbnailSwap.variant,
    });
    picture.name = 'thumbnail';
    thumb.appendChild(picture);
    pictures.push(picture);
    const text = panel('text', 'VERTICAL', lk, {
      gap: row.titleDescriptionGapStyle.size,
    });
    c.appendChild(text);
    text.layoutSizingHorizontal = 'FILL';
    text.layoutSizingVertical = 'HUG';
    const title = makeLabel(
      kCarouselBannerTitle,
      lk,
      textLabelOpts(lk, textStyleData(row.titleStyle)),
    );
    title.name = 'title';
    text.appendChild(title);
    title.layoutSizingHorizontal = 'FILL';
    titles.push(title);
    const description = makeLabel(
      kCarouselBannerBody,
      lk,
      textLabelOpts(lk, textStyleData(row.descriptionStyle)),
    );
    description.name = 'description';
    text.appendChild(description);
    description.layoutSizingHorizontal = 'FILL';
    descriptions.push(description);
  }
  const set = mount.finish();
  const titleProp = defineProp(set, 'Title', 'TEXT', kCarouselBannerTitle);
  for (const n of titles) bindTextProp(n, titleProp);
  const descriptionProp = defineProp(
    set,
    'Description',
    'TEXT',
    kCarouselBannerBody,
  );
  for (const n of descriptions) bindTextProp(n, descriptionProp);
  const showDescription = defineProp(set, 'Show description', 'BOOLEAN', true);
  for (const n of descriptions) bindVisibleProp(n, showDescription);
  const showThumbnail = defineProp(set, 'Show thumbnail', 'BOOLEAN', true);
  for (const n of thumbs) bindVisibleProp(n, showThumbnail);
  const thumbnailProp = defineProp(set, 'Thumbnail', 'INSTANCE_SWAP', thumbnailSwap.id);
  for (const n of pictures) bindSwapProp(n, thumbnailProp);
  return set;
}

// The `ChatBubble` pose a preview row composes, one per side of the thread. The
// side decides all of it, the way `CoreChatBubbleContract.defaultVariantFor` /
// `defaultTailFor` decide it for a bubble that states nothing: the `end` side is
// the reader's own message, a `primary` bubble with its tail on that side; the
// `start` side is a received one, the neutral bubble. The start-side rows carry
// their tail (`Tail=start`) as an example the caller asked for — the code's own
// start-side default is no tail — which is the picture the designer's copy draws.
const kChatStartBubble = { Variant: 'neutral', Tail: 'start' } as const;
const kChatEndBubble = { Variant: 'primary', Tail: 'end' } as const;

/** The share of the row a bubble of [variant] may take: its own
 *  `maxWidthFactor` when the variant states one, the shared field otherwise. */
function chatBubbleMaxWidthFactor(variant: string): number {
  const rows = CHAT_BUBBLE.variants.defaultsByVariant as Record<
    string,
    { maxWidthFactor?: Dim }
  >;
  return dimVal(rows[variant]?.maxWidthFactor ?? CHAT_BUBBLE.fields.maxWidthFactor);
}

// ─── Chat ────────────────────────────────────────────────────────────────────

// `CoreChatContract` is ONE chat row — avatar + header + bubble + footer —
// and this preview renders three of them to read as a thread. Each row now
// carries all four slots, which is what lets CoreChatStyle's fields land:
// `avatarSpacing` is the avatar↔column gap (the widget's
// `EdgeInsetsDirectional` around the avatar slot), `headerTextStyle` /
// `footerTextStyle` are the roles the widget merges over the header/footer
// slots. The column itself is tight in code (`Column` with no `spacing`), so
// no gap is set on it.
//
// ─── Composition: the bubble slot holds a `ChatBubble` ─────────────────────
//
// `bubble` is `Chat`'s one required slot, and the widget's own documented
// filling for it is a `ChatBubble` — the sibling contract that owns the
// bubble's background / radius / padding / tail. So the preview composes an
// instance of it (`needs: ['ChatBubble']`) instead of drawing a rounded box
// that resembles one. The variant and tail follow the row's side, which is how
// the widget reads it: `Chat` hands its `alignment` to the bubble it holds, and
// a bubble that states nothing takes the side's defaults — `primary` with the
// tail on the `end` side, the neutral bubble on the `start` side. An outgoing
// row is `Variant=primary, Tail=end`, an incoming row `Variant=neutral,
// Tail=start`. The side a row sits on is also its alignment, which this preview
// draws with the column's cross-axis alignment.
//
// The message copy moves with the bubble: it is the ChatBubble's child, not
// Chat's, and a designer edits it by double-clicking into the instance the
// same way they would in any nested-instance library. That is also why the
// bubble's shape (fill, corners, inset) arrives for free — that chrome was
// unreachable while this preview drew the box itself.
//
// Still literal (OQ-2): the between-row gap has no CoreChatStyle field that
// isn't tied to a message-grouping concept this preview doesn't model
// (`groupSpacing` is the gap *within* a same-sender group; these rows
// alternate sender).
//
// ─── Composition: the avatar slot holds an `Avatar` ────────────────────────
//
// `avatar` took a hand-drawn ellipse before — a lookalike of a component this
// library already has, sized and painted here so that whatever this file chose
// was the only avatar the slot could ever hold. It is an `Avatar` instance now
// (`Size=sm`, the 32px step the ellipse was), which both puts the real
// component on the canvas and gives the slot something an INSTANCE_SWAP can
// bind to. `Avatar` is a placeholder for this slot, not a claim that `Chat`
// composes one — the widget takes whatever the caller passes, which is exactly
// what the swap says.
//
// ─── Why nothing here is placed absolutely ─────────────────────────────────
//
// `Chat.build` is a `Column` inside a `Row` and nothing else — the avatar is a
// `Padding` sibling of the column, not an overlay — so this component flows,
// and manual placement would be a claim the widget does not make.
//
// The one `Stacks` in `chat.dart` belongs to `ChatBubble`, further down the
// same file: it holds the bubble and a `Position`ed `CustomPaint` tail. Since
// that class has no directory of its own, a per-directory reader attributes it
// to `Chat`. It is already on this canvas the right way round — inside the
// `ChatBubble` instance composed below, which is where the tail it positions
// lives too.
//
// ─── Slots → Figma properties ─────────────────────────────────────────────
//
// Every slot is `W`/`W?` — it accepts any widget — so every slot gets the
// property that says so: `Avatar` and `Bubble` are INSTANCE_SWAP over the two
// instances, `Header` and `Footer` are TEXT over the two labels. One property
// drives all three rows because the Figma component is one node: three rows of
// a single-row contract, which is the same reason the visibility toggles
// already worked that way.
//
// The three optional slots keep a visibility toggle on top of that, since
// `W?` also means absent — but on a *holder* frame around the content, not on
// the content itself. `componentPropertyReferences` is one map per node and
// both `bindVisibleProp` and `bindTextProp` assign the whole map, so a second
// call on the same node silently drops the first binding — a property left in
// the panel driving nothing. Holder-plus-content is how `Button` splits its
// own `Leading` BOOLEAN from its `Leading icon` INSTANCE_SWAP, for the same
// reason.
//
// The toggles are therefore named `Show avatar` / `Show header` /
// `Show footer`: Figma rejects two properties sharing a name, and the slot's
// own name belongs to the property that fills it rather than to the one that
// hides it.
//
// What `Bubble` costs, stated rather than discovered: the start-side rows bind
// to one property and the end-side row does not. A swap on a placed instance
// replaces both received bubbles together and leaves the sent one `primary` with
// its tail — the redesigned pose. Binding the sent row too would put the
// property's single default (the received pose) on every row of a placed
// instance and drop the side distinction from the canvas, which is the one thing
// the preview is for.
function buildChat(page: PageNode, lk: VarLookup): ComponentNode {
  // g7-preview-only: gap between the three rows. `Chat` IS one row (`Row` of avatar + `Column`), so a thread is a caller stacking several and this gap is that caller's. `groupSpacing` is not it — that field belongs to `ChatGroup` and spaces bubbles WITHIN one sender's group, while these rows alternate sender.
  const c = mintPanelComp(page, 'Chat', 'VERTICAL', lk, { gap: 8 });
  // g7-preview-only: the frame's own width. A chat row sizes to its parent (`mainAxisSize: .min` inside the caller's list); no field states a width.
  lockWidth(c, kChatPreviewWidth);
  const owner = propertyOwner(c);
  const avatarVariant = bestVariantName(page, 'Avatar', { Size: kChatAvatarSize, ...kAvatarRest });
  const avatarProp = defineProp(
    owner,
    'Avatar',
    'INSTANCE_SWAP',
    mainIdOf(page, 'Avatar', avatarVariant),
  );
  const showAvatarProp = defineProp(owner, 'Show avatar', 'BOOLEAN', false);
  const bubbleProp = defineProp(
    owner,
    'Bubble',
    'INSTANCE_SWAP',
    mainIdOf(page, 'ChatBubble', bestVariantName(page, 'ChatBubble', { ...kChatStartBubble })),
  );
  const headerProp = defineProp(owner, 'Header', 'TEXT', '김코드');
  const showHeaderProp = defineProp(owner, 'Show header', 'BOOLEAN', false);
  const footerProp = defineProp(owner, 'Footer', 'TEXT', '오전 11:30');
  const showFooterProp = defineProp(owner, 'Show footer', 'BOOLEAN', false);
  const headerOpts = textLabelOpts(lk, textStyleData(CHAT.fields.headerTextStyle));
  const footerOpts = textLabelOpts(lk, textStyleData(CHAT.fields.footerTextStyle));
  // One entry per row, carrying only the thing `Chat` itself decides: which
  // side the row is on (`CoreChatAlignment.end` → outgoing). Everything
  // inside the bubble now belongs to the composed `ChatBubble`.
  // An everyday exchange, one line per row — three rows reading the bubble's
  // own default looked like one message sent three times.
  const rows = [
    { out: false, text: '오늘 점심 뭐 먹을까요?' },
    { out: true, text: '회사 앞 국숫집 어때요?' },
    { out: false, text: '좋아요, 12시에 1층에서 봬요!' },
  ];
  for (const { out, text } of rows) {
    const row = panel('row', 'HORIZONTAL', lk, { gap: CHAT.fields.avatarSpacing });
    const avatarHolder = autoFrame('avatar', 'HORIZONTAL');
    const avatar = instanceOf(page, 'Avatar', avatarVariant);
    avatarHolder.appendChild(avatar);
    avatarHolder.visible = false;

    const column = panel('column', 'VERTICAL', lk, {});
    column.counterAxisAlignItems = out ? 'MAX' : 'MIN';
    const headerHolder = autoFrame('header', 'HORIZONTAL');
    const header = makeLabel('김코드', lk, headerOpts);
    headerHolder.appendChild(header);
    column.appendChild(headerHolder);
    headerHolder.visible = false;
    const pose = out ? kChatEndBubble : kChatStartBubble;
    const bubble = instanceOf(page, 'ChatBubble', bestVariantName(page, 'ChatBubble', { ...pose }));
    bubble.name = 'bubble';
    setInstanceTextNamed(bubble, 'Child', text);
    // The widget nests TWO columns and only the inner one is spaced: the outer
    // (header / bubbles / footer) has no `spacing` argument, and `bubblesColumn`
    // carries `spacing: groupSpacing` because `Chat.bubbles` is a
    // `List<Widget>` — consecutive messages from the same sender.
    //
    // So the gap lives on a node of its own rather than on the column above it.
    // With one bubble nothing separates yet, which is also true of the widget
    // given one; a designer who duplicates the bubble inside this frame gets the
    // stated gap instead of whichever number Figma's default happens to be.
    const bubbles = panel('bubbles', 'VERTICAL', lk, { gap: CHAT.fields.groupSpacing });
    bubbles.counterAxisAlignItems = out ? 'MAX' : 'MIN';
    bubbles.appendChild(bubble);
    column.appendChild(bubbles);
    // `ConstrainedBox(maxWidth: constraints.maxWidth * maxWidthFactor)` — Chat
    // applies the cap using the BUBBLE's field, which is why it lands here and
    // not in `buildChatBubble`: the factor is a fraction of what the row offers,
    // and a bubble on its own has no row. Without it a long message spans the
    // whole conversation instead of wrapping at three quarters of it.
    // The factor is the variant's own when it states one (`plain` takes the whole
    // row), the shared field otherwise (neutral and primary, 0.75).
    bubble.maxWidth = kChatPreviewWidth * chatBubbleMaxWidthFactor(pose.Variant);
    const footerHolder = autoFrame('footer', 'HORIZONTAL');
    const footer = makeLabel('오전 11:30', lk, footerOpts);
    footerHolder.appendChild(footer);
    column.appendChild(footerHolder);
    footerHolder.visible = false;

    // Outgoing rows put the avatar after the column, mirroring the widget's
    // `if (!isEnd) avatarSlot … else` ordering.
    if (out) {
      row.appendChild(column);
      row.appendChild(avatarHolder);
    } else {
      row.appendChild(avatarHolder);
      row.appendChild(column);
    }
    c.appendChild(row);
    // Bound only now. `componentPropertyReferences` is rejected while the node
    // is still detached ("Can only set component property references on symbol
    // sublayer"), and that throw is not rolled back — the entry is reported as
    // failed and half a Chat is left on the page looking finished until the
    // next run blanks it.
    bindVisibleProp(avatarHolder, showAvatarProp);
    bindSwapProp(avatar, avatarProp);
    bindVisibleProp(headerHolder, showHeaderProp);
    bindTextProp(header, headerProp);
    // Only the received rows follow the `Bubble` swap — see the cost above.
    if (!out) bindSwapProp(bubble, bubbleProp);
    bindVisibleProp(footerHolder, showFooterProp);
    bindTextProp(footer, footerProp);
    row.layoutSizingHorizontal = 'FILL';
    row.primaryAxisAlignItems = out ? 'MAX' : 'MIN';
  }
  return c;
}

// ─── Window (chrome) ─────────────────────────────────────────────────────────

// ─── Composition: a `Window` IS a `WindowPanel` ────────────────────────────
//
// `_WindowWidgetState._buildWindow` opens with `Widget windowClient =
// WindowPanel(title:, actions:, closable:, minimizable:, maximizable:,
// windowPanelStyle: …, child: content)` and then wraps that in animation,
// pointer and resize layers — a close/open scale, a minimise scale, an
// `IgnorePointer`, a `Listener`, and invisible resize hit regions. None of
// those paint anything at rest. So the whole of a window's resting chrome is
// one `WindowPanel`, and that is what this component now contains
// (`needs: ['WindowPanel']`).
//
// This replaces a full redraw of the panel — shell + title bar + three
// controls + body, all read off `CoreWindowStyle.panelStyle`. The values were
// right (`panelStyle` is the same nested slot the widget forwards) and the
// picture was convincing, which is exactly the problem: `WindowPanel` already
// exists as its own component built from `CoreWindowPanelStyle`, so the canvas
// carried two independent drawings of one panel and nothing said which was
// authoritative. A change to `WindowPanel`'s title bar would have moved one of
// them and not the other, and the content-hash skip means a run that only
// touched `WindowPanel` never re-enters this builder to notice.
//
// What that costs, stated rather than hidden: `Window`'s own `Title` /
// `Content` / `Actions` component properties are gone, because a property
// reference cannot be bound to a node inside an instance. Those three slots
// are `WindowPanel`'s to declare — the widget forwards all three to it
// (`title:`, `actions:`, and `content` as the panel's `child:`) — so they
// belong on that component's builder, not re-declared here over a second copy
// of its nodes.
//
// `exposeNested` is how the forward reaches this component's panel: whatever
// the child declares for those slots surfaces here, which is the one mechanism
// Figma has for a slot a parent hands straight to a child. Deliberately not a
// list of the child's property names — reading them off the instance is what
// keeps this true when that builder renames one, and spelling them here would
// be the second copy this composition exists to remove.
//
// `Button` and `Icon` read as this component's children for the same
// file-scope reason: `window.dart` also declares `WindowActions`, the default
// filling of the `actions` slot, and that is three ghost `Button`s each
// holding an `Icon`. They belong inside the panel's title bar, which is inside
// the instance — drawing them here would put a second row of controls beside
// the panel rather than in it.
//
// ─── The drag-time snap overlay ────────────────────────────────────────────
//
// Seventeen of `CoreWindowStyle`'s own fields describe two surfaces that appear
// while a window is being dragged: the snap bar (the strip of layout presets
// that slides down from the top edge) and the snap preview (the blurred ghost of
// where the window will land). The canvas showed none of them — the whole
// component was one `WindowPanel` instance.
//
// Six of the remaining seven are poses and timings of animations rather than
// chrome, and a static canvas has no axis for either: the scale a window tweens
// from as it opens and the one it tweens to as it closes (both at the moment
// `Opacity` is zero, so their pose is an invisible one), the scale a window
// shrinks to while a drag is armed, the bar's own hidden-pose fraction, and the
// two transition durations. Naming them here would be enough to make the
// unread-field census count them as read — the census looks for a field name as
// an identifier anywhere under `src/` — so they are described instead.
//
// The seventh is the title colour every window except the frontmost one takes.
// That one is drawable and is not drawn: it is a per-window STATE, so it needs a
// `Focused` variant axis, which turns this single COMPONENT into a
// COMPONENT_SET through `renames.ts#STRUCTURAL_MIGRATIONS` — and the colour
// would then have to land on a text node inside the composed `WindowPanel`
// instance, whose name is that builder's to change. Both halves belong in one
// change with that migration, not here.
//
// They are drawn here, hidden behind a BOOLEAN each, the way `Tracker` carries
// its hover-only `Tooltip` twelve functions up. Two things about that placement,
// both stated because neither is obvious:
//
//   · The overlay belongs to the NAVIGATOR, not to one window —
//     `_WindowLayerGroup` draws one bar per layer, above every window in it.
//     There is no navigator component on this canvas, and `CoreWindowStyle` is
//     where these values are stated, so this is the component that can carry
//     them. "Another class paints it" is a Flutter composition fact; it is not a
//     reason for a stated value to reach no pixel.
//   · Both are ABSOLUTE, so neither grows the component. The bar is ~860 wide
//     against a 320 panel (six thumbnails of a desktop-shaped preset), so it
//     hangs outside the frame's bounds on both sides — same as `Tracker`'s
//     tooltip hangs below its own, and why `clipsContent` is off here too.
//
// The bar's surface is drawn rather than composed, and this is the one place in
// this file where that is the right call. In Flutter the strip is an
// `OutlinedContainer`, so composing looks correct — but every value it paints
// (`backgroundColor` / `borderColor` / `borderWidth` / `padding` / `height`) is
// forwarded INTO it by `CoreWindowStyle`, the tile row has to live inside it,
// and Figma will not append children to an instance. The behind-everything
// placement that solves that elsewhere (`Menu`'s `Popup`) needs the surface to
// track a size this component computes, and resizing an auto-layout INSTANCE is
// exactly the class of write that has been rejected eleven times here — a throw
// that is not rolled back, so it fails the entry and leaves half a component on
// the page. The Web twin settles it: `window_style.dart` emits
// `snapBarContainer` as a plain `<div>` carrying the same five values inline —
// no container composed, on the platform that has no such constraint.
// Two axes, and both are runtime state `window.dart` reads on every build.
//
// `Focused` — `final focused = _viewport?.focused ?? true`, and an unfocused
// window hands its panel `panelBundle.copyWith(titleStyle:
// resolved.unfocusedTitleStyle)`. That style states a colour and no role, so the
// pose is one repaint of the composed panel's title, not a re-typesetting.
//
// `Minimized` — `Transform.scale(scale: _viewport.minify ? minimizedScale : 1)`
// wrapping the whole window. `rescale` is Figma's own proportional scale (it
// takes font sizes with it, which `Transform.scale` does), so it is the mapping
// rather than a resize.
//
// Both were absent before, and the two fields they spend had nowhere on the
// canvas to live — the exact state G16 counts. Neither is motion: a window rests
// unfocused for as long as you look at another one, and rests minimized until
// you restore it.
function windowVariantName(focused: boolean, minimized: boolean): string {
  return `Focused=${focused ? 'true' : 'false'}, Minimized=${
    minimized ? 'true' : 'false'
  }`;
}

async function buildWindow(page: PageNode, lk: VarLookup): Promise<ComponentSetNode> {
  const names: string[] = [];
  for (const focused of [true, false]) {
    for (const minimized of [false, true]) names.push(windowVariantName(focused, minimized));
  }
  const mount = mountSet(page, 'Window', names);
  // Collected across variants and bound after `finish()`, because a component
  // property belongs to the SET and not to a member. Asking `propertyOwner` for
  // it inside the loop gets the member back — it has no set parent yet — and
  // then every member declares its own copy of the pair. The runtime harness
  // refuses that outright, which is how this was caught the moment Window grew
  // its first axis; the same mistake shipped once as Badge's five properties
  // defined eighty times.
  const bars: FrameNode[] = [];
  const previews: FrameNode[] = [];
  for (const focused of [true, false]) {
    for (const minimized of [false, true]) {
      const overlays = await buildWindowVariant(mount, page, lk, focused, minimized);
      bars.push(overlays.bar);
      previews.push(overlays.preview);
    }
  }
  const set = mount.finish();
  const barId = defineProp(set, 'Show snap bar', 'BOOLEAN', false);
  for (const bar of bars) bindVisibleProp(bar, barId);
  const previewId = defineProp(set, 'Show snap preview', 'BOOLEAN', false);
  for (const preview of previews) bindVisibleProp(preview, previewId);
  return set;
}

async function buildWindowVariant(
  mount: SetMount,
  page: PageNode,
  lk: VarLookup,
  focused: boolean,
  minimized: boolean,
): Promise<{ bar: FrameNode; preview: FrameNode }> {
  const f = WINDOW.fields;
  const c = mount.getOrCreate(windowVariantName(focused, minimized));
  applyPanelCompChrome(c, 'VERTICAL', lk, {});
  // Both overlays reach outside the panel's box by construction. Explicit
  // because a freshly minted COMPONENT clips while `resetNode` clears it — an
  // unset value renders differently on the first run than on the next.
  c.clipsContent = false;
  const panelNode = instanceOf(page, 'WindowPanel');
  panelNode.name = 'panel';
  // `panelStyle.borderRadius`, forwarded into the composed `WindowPanel` — the
  // window states its own corner and the instance was keeping the panel's.
  applyForwardedPanelStyle(panelNode, lk, {
    borderRadius: WINDOW.fields.panelStyle.borderRadius,
  });
  c.appendChild(panelNode);
  exposeNested(panelNode);
  if (!focused) unfocusPanelTitle(panelNode, lk);

  // Read once, before the absolute children are appended: they do not change an
  // auto-layout frame's size, but reading after would invite the assumption
  // that they might.
  const rootWidth = c.width;
  const rootHeight = c.height;

  const bar = await buildSnapBar(lk);
  // `Align(alignment: Alignment.topCenter)` + `Transform.translate(0,
  // snapBarTopOffset)` at the fully-shown pose. Plain x/y, not padding on a
  // full-bleed wrapper the way `Carousel` keeps its insets bound: Figma cannot
  // bind a Variable to x/y, and here there is nothing to bind anyway —
  // `snapBarTopOffset` carries `ref: null` (a plain 24 in Core, not a step on
  // the space ladder), so binding it would assert a token the design system
  // never named. CENTER/MIN keeps the centring true when the frame resizes.
  pinAbsolute(c, bar, (rootWidth - bar.width) / 2, dimVal(f.snapBarTopOffset), {
    horizontal: 'CENTER',
    vertical: 'MIN',
  });
  bar.visible = false;

  const preview = buildSnapPreview(lk, rootWidth, rootHeight);
  pinAbsolute(c, preview, 0, 0, { horizontal: 'STRETCH', vertical: 'STRETCH' });
  preview.visible = false;
  // Last, and that ordering is the whole reason this is one line rather than
  // arithmetic: everything above is placed at full size, so the scale takes the
  // pins and the two overlays with it, exactly as `Transform.scale` wrapping the
  // window takes its subtree. Scaling first would leave every later x/y in the
  // unscaled coordinate space.
  if (minimized) {
    // `rescale` lets go of an effect style a node wears while the layers it
    // drew stay on the node — measured on the canvas: the minimised bar came
    // back holding the `lg` step's numbers and no link, which is the direct
    // value the document's own style is supposed to replace. The bar was
    // linked when it was built, so the id it wore is put back; reading it
    // here and not asking the document again keeps a document without the
    // style from listing the same miss twice.
    const barStyleId = bar.effectStyleId;
    c.rescale(dimVal(f.minimizedScale));
    if (barStyleId) await bar.setEffectStyleIdAsync(barStyleId);
    // The scaled corner (12 × 0.65 = 7.8) is no step of the radius scale, and
    // the panel's own corner variable still says 12 — so the number the node
    // shows and the variable it is bound to disagree. The design leaves the
    // minified corner unlinked (the issue's "허용 차이"), so the binding goes
    // and the scaled value stays.
    for (const corner of corners) panelNode.setBoundVariable(corner, null);
  }
  return { bar: bar, preview: preview };
}

// `panelBundle.copyWith(titleStyle: resolved.unfocusedTitleStyle)` on the
// composed panel.
//
// A repaint and not a re-typesetting, because that is what the field says:
// `unfocusedTitleStyle` carries a colour and `role: null`, so the title keeps the
// panel's own metrics and changes what it is painted with. Writing a role here
// would assert a size the code does not state.
function unfocusPanelTitle(panelNode: InstanceNode, lk: VarLookup): void {
  fillData(
    instanceTitleNode(panelNode),
    lk,
    colorData(WINDOW.fields.unfocusedTitleStyle.color),
  );
}

// The composed `WindowPanel`'s title TEXT node.
//
// By position among the instance's text nodes rather than by name, and the
// reason is worth stating: `WindowPanel` names its title holder, not the TEXT
// inside it, and a name this file does not own is the thing that goes stale
// silently. The panel's first text IS its title — its own builder appends the
// title before the actions — so the ordering is the child builder's contract and
// a change to it moves the throw here rather than the paint.
function instanceTitleNode(inst: InstanceNode): TextNode {
  const texts = inst.findAll((n) => n.type === 'TEXT');
  const first = texts.length > 0 ? texts[0] : null;
  if (first == null || first.type !== 'TEXT') {
    throw new Error(
      `instanceTitleNode: no TEXT under ${inst.name}. WindowPanel stopped ` +
        'drawing a title, so the unfocused pose has nothing to repaint — the ' +
        'pose would silently equal the focused one.',
    );
  }
  return first;
}

// ─── The snap bar's preset table ─────────────────────────────────────────────
//
// One pane of one preset: a rect relative to the thumbnail, plus which of its
// corners abut a sibling pane. The flags are what carry the chrome — an abutting
// corner takes the tight (snap-preview) radius and one on the preset's outer
// edge takes the loose (snap-bar) radius, which is the pick `_SnapHoverState`
// makes at every corner.
//
// `allL`/`allR` are the widget's `allLeft`/`allRight`: both corners on that side
// abut, which only the middle pane of a three-column preset does.
interface SnapPane {
  l: number;
  t: number;
  w: number;
  h: number;
  tl?: true;
  tr?: true;
  bl?: true;
  br?: true;
  allL?: true;
  allR?: true;
}

// Transcribed from `_buildSnapPresets`'s six `aspect(...)` groups rather than
// paraphrased, because the corner flags are NOT derivable from the rect: the
// same `[0.5, 0, 0.5, 0.5]` pane abuts on three sides in the third preset and on
// three DIFFERENT sides in the fourth, and only the call sites say which.
const kSnapPresets: readonly (readonly SnapPane[])[] = [
  [
    { l: 0, t: 0, w: 0.5, h: 1, tr: true, br: true },
    { l: 0.5, t: 0, w: 0.5, h: 1, tl: true, bl: true },
  ],
  [
    { l: 0, t: 0, w: 0.7, h: 1, tr: true, br: true },
    { l: 0.7, t: 0, w: 0.3, h: 1, tl: true, bl: true },
  ],
  [
    { l: 0, t: 0, w: 0.5, h: 1, tr: true, br: true },
    { l: 0.5, t: 0, w: 0.5, h: 0.5, tl: true, bl: true, br: true },
    { l: 0.5, t: 0.5, w: 0.5, h: 0.5, tl: true, tr: true, bl: true },
  ],
  [
    { l: 0, t: 0, w: 0.5, h: 0.5, tr: true, bl: true, br: true },
    { l: 0.5, t: 0, w: 0.5, h: 0.5, tl: true, bl: true, br: true },
    { l: 0, t: 0.5, w: 0.5, h: 0.5, tl: true, tr: true, br: true },
    { l: 0.5, t: 0.5, w: 0.5, h: 0.5, tl: true, tr: true, bl: true },
  ],
  [
    { l: 0, t: 0, w: 1 / 3, h: 1, tr: true, br: true },
    { l: 1 / 3, t: 0, w: 1 / 3, h: 1, allL: true, allR: true },
    { l: 2 / 3, t: 0, w: 1 / 3, h: 1, tl: true, bl: true },
  ],
  [
    { l: 0, t: 0, w: 2 / 7, h: 1, tr: true, br: true },
    { l: 2 / 7, t: 0, w: 3 / 7, h: 1, allL: true, allR: true },
    { l: 5 / 7, t: 0, w: 2 / 7, h: 1, tl: true, bl: true },
  ],
];

// `_createPaneSnapStrategy`'s gap arithmetic, verbatim: a pane gives back the
// `snapTileSpacing` it shares with each neighbour, on the side it shares it.
// The branch order matters — the widget's own `else if` chain means a pane that
// abuts on three sides takes the FIRST matching pair's inset and only the
// remaining single side from the nested test.
function snapPaneRect(
  p: SnapPane,
  w: number,
  h: number,
  gap: number,
): { left: number; top: number; width: number; height: number } {
  let left = p.l * w;
  let top = p.t * h;
  let width = p.w * w;
  let height = p.h * h;
  if (p.tl && p.tr) {
    top += gap;
    height -= gap;
    if (p.bl) {
      left += gap;
      width -= gap;
    } else if (p.br) {
      width -= gap;
    }
  } else if (p.bl && p.br) {
    height -= gap;
    if (p.tl) {
      left += gap;
      width -= gap;
    } else if (p.tr) {
      width -= gap;
    }
  } else if (p.tl && p.bl) {
    left += gap;
    width -= gap;
    if (p.tr) {
      top += gap;
      height -= gap;
    } else if (p.br) {
      height -= gap;
    }
  } else if (p.tr && p.br) {
    width -= gap;
    if (p.tl) {
      top += gap;
      height -= gap;
    } else if (p.bl) {
      height -= gap;
    }
  } else if (p.allL && p.allR) {
    left += gap;
    width -= gap * 2;
  }
  return { left, top, width, height };
}

// Per-corner tight/loose radius. `bindRadiusN` binds all four to one value,
// which is the wrong shape here and only here: the pick is per corner and comes
// from this component's own flags, so the loop reads the shared `corners` field
// list and the shared `lk.radius` binder rather than either being copied.
function bindPaneCorners(
  tile: FrameNode,
  lk: VarLookup,
  p: SnapPane,
  tight: number,
  loose: number,
): void {
  // Same order as `corners`: top-left, top-right, bottom-left, bottom-right.
  const abuts = [
    p.tl === true || p.allL === true,
    p.tr === true || p.allR === true,
    p.bl === true || p.allL === true,
    p.br === true || p.allR === true,
  ];
  for (let i = 0; i < corners.length; i++) {
    tile.setBoundVariable(corners[i], lk.radius(abuts[i] ? tight : loose));
  }
}

// The bar itself: `OutlinedContainer(height: snapBarHeight, padding:
// snapBarPadding)` around `Row(spacing: snapBarTileSpacing)` of six presets.
//
// Sized by arithmetic rather than by hugging, because the x that centres it has
// to be known before Figma has laid anything out — and a `resize` on an
// auto-layout frame would flip its width back to FIXED anyway, undoing the hug
// it was asked for.
//
// One tile is drawn in its hover fill. `snapTileHoverBackgroundColor` is a real
// state and a variant axis would need this single COMPONENT to become a
// COMPONENT_SET, which routes through `renames.ts#STRUCTURAL_MIGRATIONS` and is
// not this file's to add. Spending it as one armed tile inside the strip is the
// same trade `Tracker` makes with its mixed status bars — and it is a moment the
// app really has: the bar is only visible while the pointer is inside it, and
// the pointer is over one tile.
async function buildSnapBar(lk: VarLookup): Promise<FrameNode> {
  const f = WINDOW.fields;
  const pad = f.snapBarPadding;
  const gap = dimVal(f.snapBarTileSpacing);
  const barHeight = dimVal(f.snapBarHeight);
  const thumbHeight = barHeight - dimVal(pad.t) - dimVal(pad.b);
  const thumbWidth = Math.round(thumbHeight * kSnapDesktopAspect);
  const barWidth =
    dimVal(pad.l) +
    dimVal(pad.r) +
    kSnapPresets.length * thumbWidth +
    (kSnapPresets.length - 1) * gap;

  const bar = panel('snap bar', 'HORIZONTAL', lk, { gap: f.snapBarTileSpacing });
  bindPad(bar, lk, pad);
  bindRadiusN(bar, lk, f.snapBarBorderRadius.topLeft);
  // A floating surface on both platforms — a drag affordance over content:
  // Flutter composes `OutlinedContainer` at the functional role, and the Web
  // twin marks the bar `webSurfaceMarkerFor(.functional)`. It states its own
  // cast (the `lg` step), so it takes the rim a casting surface takes and the
  // document's `shadow/lg` style when there is one.
  applySurfaceMaterial(bar, lk, colorData(f.snapBarBackgroundColor), 'functional', {
    radius: f.snapBarBorderRadius.topLeft,
    rim: f.snapBarShadow.layers.length > 0,
  });
  borderData(bar, lk, colorData(f.snapBarBorderColor), f.snapBarBorderWidth);
  setShadow(bar, f.snapBarShadow, lk);
  await linkShadowStyle(bar, f.snapBarShadow, 'Window/snap bar');
  bar.clipsContent = false;
  bar.primaryAxisSizingMode = 'FIXED';
  bar.counterAxisSizingMode = 'FIXED';
  bar.resize(barWidth, barHeight);

  // A tile's own corners — not the preview's and not the banner's: it sits one
  // banner padding inside the banner, so its outer corner is the banner's
  // minus that padding, and an edge it shares with a sibling is tighter still.
  const tight = dimVal(f.snapTileInnerBorderRadius.topLeft);
  const loose = dimVal(f.snapTileBorderRadius.topLeft);
  const tileFill = colorData(f.snapTileBackgroundColor);
  const hoverFill = colorData(f.snapTileHoverBackgroundColor);
  const tileBorder = colorData(f.snapTileBorderColor);
  const tileGap = dimVal(f.snapTileSpacing);
  for (let i = 0; i < kSnapPresets.length; i++) {
    // `layoutMode = 'NONE'` — the widget's `GroupWidget` of `GroupPositioned`
    // panes. The rects are absolute inside the thumbnail, so there is no
    // auto-layout to express them.
    const preset = figma.createFrame();
    preset.name = 'preset';
    preset.layoutMode = 'NONE';
    preset.fills = [];
    preset.clipsContent = false;
    preset.resize(thumbWidth, thumbHeight);
    bar.appendChild(preset);
    for (let j = 0; j < kSnapPresets[i].length; j++) {
      const pane = kSnapPresets[i][j];
      const rect = snapPaneRect(pane, thumbWidth, thumbHeight, tileGap);
      const tile = figma.createFrame();
      tile.name = 'tile';
      tile.layoutMode = 'NONE';
      // The armed tile: the first pane of the first preset — the left half of
      // the 50/50 split, the most ordinary snap there is. By index rather than
      // by identity, so a pane object reused across two presets could not arm
      // two tiles at once.
      fillData(tile, lk, i === 0 && j === 0 ? hoverFill : tileFill);
      borderData(tile, lk, tileBorder, f.snapTileBorderWidth);
      bindPaneCorners(tile, lk, pane, tight, loose);
      preset.appendChild(tile);
      tile.resize(Math.max(rect.width, 0.01), Math.max(rect.height, 0.01));
      tile.x = rect.left;
      tile.y = rect.top;
    }
  }
  return bar;
}

// The ghost: `_BlurContainer` — `Padding(snapBarPaddingInsets)` around a box
// filled with `snapPreviewBackgroundColor`, outlined in
// `snapPreviewBorderColor`, rounded at `snapPreviewBorderRadius`, over a
// `BackdropFilter(ImageFilter.blur(snapPreviewBlurSigma))`.
//
// Full-bleed over this component, because the widget positions it at the armed
// snap target's rect (`GroupPositioned.fromRect`) and "this window's own box" is
// the one such rect a single-window component can show.
//
// σ lands on Figma's `BACKGROUND_BLUR`, whose `radius` is the same knob CSS
// `backdrop-filter: blur()` takes — which is what the Web twin emits from the
// same field. The stroke width is Flutter's `Border.all` default of 1 (the field
// set states no width for this box, and Web reaches the same 1 through the
// Tailwind `border` class), so it is left to `borderData`'s own default rather
// than spelled here.
function buildSnapPreview(lk: VarLookup, width: number, height: number): FrameNode {
  const f = WINDOW.fields;
  const preview = autoFrame('snap preview', 'VERTICAL');
  bindPad(preview, lk, f.snapBarPadding);
  preview.clipsContent = false;
  preview.resize(Math.max(width, 0.01), Math.max(height, 0.01));

  const ghost = figma.createFrame();
  ghost.name = 'ghost';
  ghost.layoutMode = 'NONE';
  fillData(ghost, lk, colorData(f.snapPreviewBackgroundColor));
  borderData(ghost, lk, colorData(f.snapPreviewBorderColor));
  bindRadiusN(ghost, lk, f.snapPreviewBorderRadius.topLeft);
  ghost.effects = [
    {
      type: 'BACKGROUND_BLUR',
      blurType: 'NORMAL',
      radius: dimVal(f.snapPreviewBlurSigma),
      visible: true,
    },
  ];
  preview.appendChild(ghost);
  ghost.layoutSizingHorizontal = 'FILL';
  ghost.layoutSizingVertical = 'FILL';
  return preview;
}

// ─── CodeDiff ────────────────────────────────────────────────────────────────

// Data-driven from coui_core CODE_DIFF: cornerRadius (outer radius),
// surfaceColor + outlineColor/borderWidth (outer fill, and a border that is
// stated as zero width and a transparent colour — `borderData` clears the
// stroke for a transparent colour, so the block is told apart by its face
// alone, as in the widget),
// linePadding (per-line l/t/r/b — vertical 0, so a row is its text's 21px line
// box and rows abut),
// and the four band fields: `addedBackgroundColor` / `removedBackgroundColor`
// are the OPAQUE face the whole row is filled with (no alpha — a band is a
// container token), and `addedForegroundColor` / `removedForegroundColor` are
// the ink of the `+` / `-` prefix and of the gutter number on that band. The
// code itself keeps the body ink on every row — `unchangedTextStyle`'s colour,
// the same value the widget draws the diff text with for added, removed and
// unchanged alike — so a band recolours the prefix and the number, never the
// code. A plain row has no band and its gutter number is `lineNumberColor`.
// The deprecated `addedColor` / `removedColor` / `rowTintAlpha` /
// `lineNumberAlpha` are not read here: the exporter drops a deprecated field
// from `fields`, so a read would be `undefined`.
// The outer container's own inset is not a CodeDiff field (`linePadding` is
// per-line, not per-container): the widget composes `OutlinedContainer` and
// states no padding, so the container's own default applies, and the block's
// inset is read from that container's `padding` data.
// The `Column` states no spacing either, so no seam is set between rows.
// `prefixFontWeight` is unused — it styles a prefix character as a
// separate text run from the rest of the line, which would require
// splitting each line into two text nodes (a structural change, out of
// scope).
//
// ─── Why the line-number gutter is drawn ───────────────────────────────────
//
// `gutterTypography` is the gutter's role (`codeSm`: 12px on the 21px line
// box), and the gutter is the one thing that renders it. Three more fields —
// `lineNumberWidth` / `lineNumberPadding` / `lineNumberColor` — describe
// nothing else either, so four of this Style's fields have no subject without
// it (the added/removed foregrounds also reach the gutter, on a band).
// `lineNumberWidth` is the cell's TOTAL width (Figma's frame width is a border
// box, so the padding sits inside it as it does in the widget), and
// `lineNumberPadding` is directional — its gap is on the end side — so it is
// bound through `bindPad`, which reads either shape.
//
// The widget draws it: `showLineNumbers` defaults to `true`, the gutter is
// `if (showLineNumbers && line.lineNumber != null)`, and every line of the
// docs example passes a `lineNumber`. A numbered gutter is what a designer
// comparing this against the app sees — not a node invented here to make a
// role appear.
function buildCodeDiff(page: PageNode, lk: VarLookup): ComponentNode {
  const c = mintPanelComp(page, 'CodeDiff', 'VERTICAL', lk, {
    radius: CODE_DIFF.fields.cornerRadius.topLeft,
  });
  // The block's inset is the composed `OutlinedContainer`'s own padding: the
  // widget passes that container no padding, so its default applies (the
  // `Column` inside states no `spacing` either — rows abut, so no `gap` is
  // set), and the inset a row does have is `linePadding`, read per row below.
  bindPad(c, lk, COMPONENTS.outlined_container.fields.padding);
  fillData(c, lk, colorData(CODE_DIFF.fields.surfaceColor));
  borderData(c, lk, colorData(CODE_DIFF.fields.outlineColor), CODE_DIFF.fields.borderWidth);
  // g7-preview-only: the frame's own width. The widget's root `Container` has no width — lines stretch to the parent — and `lineNumberWidth` is the gutter's, not the block's. This one is wide enough for a line of code to read.
  lockWidth(c, 360);
  const linePad = CODE_DIFF.fields.linePadding;
  const gutterStyle = textStyleData(CODE_DIFF.fields.gutterTypography);
  const bodyStyle = textStyleData(CODE_DIFF.fields.bodyTypography);
  // `unchangedTextStyle` states a colour and no role (`role: null`), so only its
  // colour is taken — the metrics stay `bodyTypography`'s, which is the split
  // `typographyColorOpts` exists for. This is the BODY ink: the diff text of
  // every row, band or not, and an unchanged row's blank prefix.
  const bodyInk = textStyleData(CODE_DIFF.fields.unchangedTextStyle).color;
  // The gutter number on a plain row — opaque, no alpha. A band row's number
  // is the band's own foreground instead (below), never this subdued colour.
  const plainGutterInk = colorData(CODE_DIFF.fields.lineNumberColor);
  // Prefix and text are separate, because the widget draws them as two `Text`
  // nodes: the prefix takes `bodyTextStyle.copyWith(fontWeight:
  // prefixFontWeight)` — bold — and the code takes the same style at its own
  // weight. They were one string here (`'+  const total = …'`), so the marker
  // rendered at the body weight and `prefixFontWeight` had no node.
  const lines: {
    prefix: string;
    text: string;
    band: Color | null;
    ink: Color | null;
  }[] = [
    {
      prefix: '+',
      text: 'const total = price * qty;',
      band: CODE_DIFF.fields.addedBackgroundColor,
      ink: CODE_DIFF.fields.addedForegroundColor,
    },
    {
      prefix: '-',
      text: 'const total = price;',
      band: CODE_DIFF.fields.removedBackgroundColor,
      ink: CODE_DIFF.fields.removedForegroundColor,
    },
    { prefix: ' ', text: 'return total;', band: null, ink: null },
  ];
  for (let i = 0; i < lines.length; i++) {
    const ln = lines[i];
    const row = panel('line', 'HORIZONTAL', lk, { pl: linePad.l, pr: linePad.r, pt: linePad.t, pb: linePad.b });
    // The band: an opaque face across the whole row. A plain row has none, so
    // the block's own face shows through.
    const band = colorData(ln.band);
    if (band) {
      fillData(row, lk, band);
    }
    // The ink the band states for its prefix and number; a plain row has none.
    const bandInk = colorData(ln.ink);
    // `SizedBox(width: lineNumberWidth) > Padding(lineNumberPadding) > Text(…,
    // textAlign: .end)`. `MAX` is that end alignment: the number hugs its
    // own width, so pushing it to the end of a fixed-width frame is what puts
    // it against the gutter's inner edge.
    const gutter = panel('gutter', 'HORIZONTAL', lk, {});
    bindPad(gutter, lk, CODE_DIFF.fields.lineNumberPadding);
    gutter.primaryAxisAlignItems = 'MAX';
    gutter.appendChild(
      makeLabel(`${i + 1}`, lk, typographyColorOpts(lk, gutterStyle, bandInk ?? plainGutterInk)),
    );
    row.appendChild(gutter);
    lockWidth(gutter, CODE_DIFF.fields.lineNumberWidth);
    // The prefix wears the band's foreground; an unchanged row has no band, so
    // its (blank) prefix keeps the body ink. The code is the body ink on every
    // row — a band recolours the marker and the number, never the text.
    // `bodyTypography` supplies size/weight/line-height.
    row.appendChild(
      makeLabel(ln.prefix, lk, {
        ...typographyColorOpts(lk, bodyStyle, bandInk ?? bodyInk),
        style: weightStyle(dimVal(CODE_DIFF.fields.prefixFontWeight)),
      }),
    );
    row.appendChild(makeLabel(ln.text, lk, typographyColorOpts(lk, bodyStyle, bodyInk)));
    c.appendChild(row);
    row.layoutSizingHorizontal = 'FILL';
  }
  return c;
}

// 'Datalist' removed (#3744) — no `Datalist` class anywhere in coui_core.
// The old on-page node (if any) is retired via src/renames.ts RETIRED,
// opt-in only.

// ─── Diff ────────────────────────────────────────────────────────────────────

// Data-driven from coui_core DIFF. The frame is `borderRadius` over a
// `aspectRatio` box; the split is the raised line (`resizerColor` +
// `resizerWidth` + `resizerShadow`) with a round handle on it
// (`handle*`), a frame edge laid inside (`borderColor` × `borderWidth`) and
// the two optional label chips (`labelInset` + `labelBadgeStyle`).
// `initialPosition` (0.5) is the split's resting place; `keyboardStep` /
// `keyboardPageStep` are runtime behaviour with no static-frame meaning. The
// outer surface fill and the pane words have no matching Style field
// (`CoreDiffStyle` carries no backgroundColor / pane typography).
//
// ─── Poses ────────────────────────────────────────────────────────────────
//
// `State` is the handle's: `enabled` · `hover` (cast `handleHoverShadow`) ·
// `focus` (the ring) · `pressed` (held: `handlePressedShadow`, the disc at
// `handlePressedScale`) · `disabled` (`interactive: false` — the handle is
// not drawn at all, only the line). The hit strip around the handle is
// invisible and has no node.
//
// ─── Slots → Figma properties ─────────────────────────────────────────────
//
// `before` / `after` are required, so neither can be a BOOLEAN; each is
// filled with a text node here, so each becomes a TEXT property whose default
// is the copy already on the canvas. `beforeLabel` / `afterLabel` are `W?`
// slots: an INSTANCE_SWAP whose default is the composed `Badge`, hidden
// behind a `Show …` BOOLEAN because the slot is null unless a caller passes
// one. Each chip is also an exposed instance, so the Badge's own properties
// (its words, tone, size) are edited from Diff's panel — a set property
// cannot bind to a node inside an instance.
const kDiffStates = stateAxisSpec(['enabled', 'hover', 'focus', 'pressed', 'disabled']);
type DiffState = 'enabled' | 'hover' | 'focus' | 'pressed' | 'disabled';

// `Badge(size: .sm)` in the default tone and strength — the chip the widget
// composes around a label. The style the widget forwards over it
// (`labelBadgeStyle`) is applied to the instance below.
const kDiffLabelBadgePose = {
  Tone: 'neutral',
  Variant: 'tonal',
  Size: 'sm',
  Style: 'label',
} as const;
// The words on the two stand-in chips — what a designer reads as "this side is
// the old one". They live in the swap's default `Badge`, so a designer's own
// chip replaces them.
const kDiffBeforeChip = '전';
const kDiffAfterChip = '후';

async function buildDiff(page: PageNode, lk: VarLookup): Promise<ComponentSetNode> {
  const f = DIFF.fields;
  const width = kDiffPreviewWidth;
  // g7-preview-only: the frame's own WIDTH — the widget takes it from its parent.
  // The height is not invented: `if (aspectRatio > 0) AspectRatio(aspectRatio:)`
  // wraps the whole thing, so the height is the width divided by the stated
  // ratio.
  const height = width / dimVal(f.aspectRatio);
  // `_position ?? resolved.initialPosition` — the split's resting place, as a
  // fraction of the width.
  const split = width * dimVal(f.initialPosition);
  const handleSize = dimVal(f.handleSize);
  const pressedScale = dimVal(f.handlePressedScale);

  const combos = enumerateAxisCombos([kDiffStates]);
  const mount = mountSet(page, 'Diff', combos, { adoptLooseAs: 'State=enabled' });
  const badgeVariant = bestVariantName(page, 'Badge', kDiffLabelBadgePose);
  const beforeWords: TextNode[] = [];
  const afterWords: TextNode[] = [];
  const beforeChips: ReturnType<typeof slotNodes>[] = [];
  const afterChips: ReturnType<typeof slotNodes>[] = [];
  const rings: FocusRingNodes[] = [];

  for (const comboName of combos) {
    const state = parseVariantKey(comboName)['State'] as DiffState;
    const c = mount.getOrCreate(comboName);
    c.resize(width, height);
    bindRadiusN(c, lk, f.borderRadius.topLeft);
    c.clipsContent = true;
    // g7-preview-only: backdrop standing in for the `after` pane. In the widget `after` is `Position.fill(child: widget.after)` — a caller widget covering the whole frame — and the frame itself paints no fill, so this is the surface the preview shows where that image would be.
    fillSem(c, lk, 'surface');

    const before = figma.createFrame();
    before.resize(split, height);
    before.x = 0;
    before.y = 0;
    // The split is a FRACTION of the width, so the pane SCALEs with the box and
    // spans its height; the `after` pane is the frame's own fill (#4805).
    before.constraints = { horizontal: 'SCALE', vertical: 'STRETCH' };
    before.layoutMode = 'HORIZONTAL';
    before.primaryAxisAlignItems = 'CENTER';
    before.counterAxisAlignItems = 'CENTER';
    before.primaryAxisSizingMode = 'FIXED';
    before.counterAxisSizingMode = 'FIXED';
    // g7-preview-only: stand-in fill for the `before` pane, which the widget clips out of a caller widget (`ClipRect` over `widget.before`) and paints nothing of its own. A second tone is what makes the split readable at rest.
    fillSem(before, lk, 'surface-container');
    const beforeWord = makeLabel('변경 전', lk, {
      // g7-preview-only: size/ink of the word naming the left pane. Both panes are arbitrary caller widgets, so the widget styles no text here and `CoreDiffStyle` carries no label typography — the words exist so a designer can tell the two halves apart.
      size: 16, colorVar: lk.sem('on-surface-variant'), style: 'SemiBold',
    });
    beforeWord.name = 'before';
    before.appendChild(beforeWord);
    c.appendChild(before);
    beforeWords.push(beforeWord);

    // g7-preview-only: same for the right pane's word — a stand-in for the `after` caller widget, with no typography field behind it.
    const afterWord = makeLabel('변경 후', lk, { size: 16, colorVar: lk.sem('on-surface'), style: 'SemiBold' });
    afterWord.name = 'after';
    c.appendChild(afterWord);
    // Centred in the pane the split leaves for it, so both words move with
    // `initialPosition` instead of sitting at numbers picked for one split.
    afterWord.x = split + (width - split) / kDiffHalf - afterWord.width / kDiffHalf;
    afterWord.y = height / kDiffHalf - afterWord.height / kDiffHalf;
    afterWord.constraints = { horizontal: 'SCALE', vertical: 'CENTER' };
    afterWords.push(afterWord);

    // The split line: `resizerColor` × `resizerWidth`, cast `resizerShadow`.
    // It rides a frame that spans 0 → the split (SCALE) and is pinned to that
    // frame's far edge (MAX), so the line keeps its token width while the split
    // keeps its fraction — Figma has no "scale my position, keep my size".
    const lineTravel = figma.createFrame();
    lineTravel.name = 'line travel';
    lineTravel.layoutMode = 'NONE';
    lineTravel.fills = [];
    lineTravel.clipsContent = false;
    lineTravel.resize(split, height);
    c.appendChild(lineTravel);
    lineTravel.x = 0;
    lineTravel.y = 0;
    lineTravel.constraints = { horizontal: 'SCALE', vertical: 'STRETCH' };
    const bar = figma.createRectangle();
    bar.name = 'line';
    bindSize(bar, lk, f.resizerWidth, height);
    fillData(bar, lk, colorData(f.resizerColor));
    lineTravel.appendChild(bar);
    bar.x = split - dimVal(f.resizerWidth) / kDiffHalf;
    bar.y = 0;
    bar.constraints = { horizontal: 'MAX', vertical: 'STRETCH' };
    setShadow(bar, f.resizerShadow, lk);
    await linkShadowStyle(bar, f.resizerShadow, 'Diff/line');

    // The two label chips — `Badge` instances in `W?` slots, `labelInset` in from
    // the top corners, no pointer. Hidden: the slot is null unless a caller
    // passes one.
    const chipInset = f.labelInset;
    const beforeChip = slotNodes('before label', diffLabelChip(page, lk, badgeVariant, kDiffBeforeChip));
    c.appendChild(beforeChip.holder);
    beforeChip.holder.x = dimVal(chipInset.l);
    beforeChip.holder.y = dimVal(chipInset.t);
    beforeChip.holder.constraints = { horizontal: 'MIN', vertical: 'MIN' };
    beforeChips.push(beforeChip);
    const afterChip = slotNodes('after label', diffLabelChip(page, lk, badgeVariant, kDiffAfterChip));
    c.appendChild(afterChip.holder);
    afterChip.holder.x = width - dimVal(chipInset.r) - afterChip.holder.width;
    afterChip.holder.y = dimVal(chipInset.t);
    afterChip.holder.constraints = { horizontal: 'MAX', vertical: 'MIN' };
    afterChips.push(afterChip);

    // The frame's edge, laid INSIDE over the content (`borderColor` ×
    // `borderWidth`) — it takes from the overlay and never from the frame, so
    // the frame keeps its size.
    const edge = figma.createFrame();
    edge.name = 'edge';
    edge.layoutMode = 'NONE';
    edge.fills = [];
    edge.clipsContent = false;
    edge.resize(width, height);
    c.appendChild(edge);
    edge.x = 0;
    edge.y = 0;
    edge.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };
    bindRadiusN(edge, lk, f.borderRadius.topLeft);
    borderData(edge, lk, colorData(f.borderColor), f.borderWidth);

    // The handle — interactive poses only (`if (interactive)` in the widget).
    if (state !== 'disabled') {
      const held = state === 'pressed';
      const handleTravel = figma.createFrame();
      handleTravel.name = 'handle travel';
      handleTravel.layoutMode = 'NONE';
      handleTravel.fills = [];
      handleTravel.clipsContent = false;
      handleTravel.resize(split, height);
      c.appendChild(handleTravel);
      handleTravel.x = 0;
      handleTravel.y = 0;
      handleTravel.constraints = { horizontal: 'SCALE', vertical: 'STRETCH' };

      // `AnimatedScale(scale: handlePressedScale)` while held — the disc and its
      // ring shrink about their centre, so the held pose is the same box at that
      // fraction of its size. Left unbound: a scaled value has no variable.
      const side = held ? handleSize * pressedScale : handleSize;
      const host = figma.createFrame();
      host.name = 'handle host';
      host.layoutMode = 'NONE';
      host.fills = [];
      host.clipsContent = false;
      if (held) host.resize(side, side);
      else bindSize(host, lk, f.handleSize, f.handleSize);
      handleTravel.appendChild(host);
      host.x = split - side / kDiffHalf;
      host.y = height / kDiffHalf - side / kDiffHalf;
      host.constraints = { horizontal: 'MAX', vertical: 'CENTER' };

      const disc = figma.createEllipse();
      disc.name = 'handle';
      if (held) disc.resize(side, side);
      else bindSize(disc, lk, f.handleSize, f.handleSize);
      fillData(disc, lk, colorData(f.handleColor));
      borderData(disc, lk, colorData(f.handleBorderColor), f.handleBorderWidth);
      host.appendChild(disc);
      disc.x = 0;
      disc.y = 0;
      const castData =
        state === 'hover' ? f.handleHoverShadow : held ? f.handlePressedShadow : f.handleShadow;
      setShadow(disc, castData, lk);
      await linkShadowStyle(disc, castData, `Diff/handle ${state}`);

      const glyph = makeIcon(
        'chevrons-left-right',
        lk,
        glyphOpts(lk, colorData(f.handleIconStyle.color), f.handleIconStyle.size, 'size'),
      );
      glyph.name = 'glyph';
      host.appendChild(glyph);
      glyph.x = (side - glyph.width) / kDiffHalf;
      glyph.y = (side - glyph.height) / kDiffHalf;

      // `FocusOutline(focused: _showFocusOutline, focusOutlineStyle:
      // resolved.focusOutlineStyle)` wraps the handle. Visible in the `focus`
      // pose; behind `Show focus ring` elsewhere, for the overlaps a single axis
      // cannot draw (a held handle that also has the keyboard).
      rings.push(
        focusRing(host, lk, {
          outline: f.focusOutlineStyle,
          color: colorData(f.focusOutlineStyle.borderColor),
          corner: f.focusOutlineStyle.borderRadius.topLeft,
          width: side,
          height: side,
          visible: state === 'focus',
        }),
      );
    }
  }

  const set = mount.finish();
  // After `finish()`, on the SET: a fresh variant has no parent until
  // `combineAsVariants` runs, so a property defined earlier would scatter per
  // member.
  const beforeProp = defineProp(set, 'Before', 'TEXT', '변경 전');
  for (const node of beforeWords) bindTextProp(node, beforeProp);
  const afterProp = defineProp(set, 'After', 'TEXT', '변경 후');
  for (const node of afterWords) bindTextProp(node, afterProp);
  const badgeMain = mainIdOf(page, 'Badge', badgeVariant);
  const beforeSwap = defineProp(set, 'Before label', 'INSTANCE_SWAP', badgeMain);
  const beforeShow = defineProp(set, 'Show before label', 'BOOLEAN', false);
  for (const chip of beforeChips) bindOptionalSlot(chip, beforeSwap, beforeShow);
  const afterSwap = defineProp(set, 'After label', 'INSTANCE_SWAP', badgeMain);
  const afterShow = defineProp(set, 'Show after label', 'BOOLEAN', false);
  for (const chip of afterChips) bindOptionalSlot(chip, afterSwap, afterShow);
  const labelChips = [
    ...beforeChips.map((slot) => ({ chip: slot.instance, words: kDiffBeforeChip })),
    ...afterChips.map((slot) => ({ chip: slot.instance, words: kDiffAfterChip })),
  ];
  // Exposed here, in the builder, because a redraw compares the flag between
  // the node it just drew and the one it may keep, and that comparison runs
  // before the queued work below: a chip exposed only there would read as a
  // different node on every run, and be replaced along with its overrides.
  exposeAll(labelChips.map((entry) => entry.chip));
  // And again once the swap bind has landed. The bind is written after this
  // builder returns, and it discards what was painted on the chip's words
  // before it — measured on `Banner`'s action label (#6028). The look goes on
  // a second time, and the flag with it.
  for (const entry of labelChips) {
    afterNodeBindLands(entry.chip, (node) => {
      const chip = node as InstanceNode;
      wearDiffLabel(chip, lk, entry.words);
      exposeAll([chip]);
    });
  }
  const showFocusId = defineShowFocusRing(set);
  for (const ring of rings) bindShowFocusRing(ring, showFocusId);
  vStackSet(set);
  return set;
}

// One label chip: a `Badge` at the pose above, wearing the style the widget
// forwards over it (`labelBadgeStyle` — a raised face).
function diffLabelChip(
  page: PageNode,
  lk: VarLookup,
  variant: string | undefined,
  text: string,
): InstanceNode {
  const chip = instanceOf(page, 'Badge', variant);
  wearDiffLabel(chip, lk, text);
  return chip;
}

// What a label chip wears over the Badge: its example words, face and ink. The
// fill goes on the instance and the ink on its text, because the chip is a
// composed child, not a box drawn here.
function wearDiffLabel(chip: InstanceNode, lk: VarLookup, text: string): void {
  const style = DIFF.fields.labelBadgeStyle;
  setInstanceTextNamed(chip, 'Child', text);
  fillComposedColor(chip, lk, colorData(style.backgroundColor));
  for (const node of chip.findAll((n) => n.type === 'TEXT')) {
    fillData(node as TextNode, lk, colorData(style.foregroundColor));
  }
}

// ─── HoverGallery ────────────────────────────────────────────────────────────

// g7-preview-only, all five: the gallery's width and everything about the dot
// strip. `CoreHoverGalleryStyle` has three fields and none of them describes a
// position indicator — the widget's `Container` holds one `AnimatedSwitcher` over
// `items[activeIndex]` and draws no dots at all. Named rather than inline so the
// arithmetic below reads as centring instead of as measured offsets.
const kHoverGalleryWidth = 280;
const kHoverGalleryDots = 4;
const kHoverGalleryDotSide = 6;
const kHoverGalleryDotPitch = 14;
const kHoverGalleryDotBottom = 18;
const kHoverGalleryHalf = 2;

// Data-driven from coui_core HOVER_GALLERY.fields.borderRadius + `height`.
//
// The height used to be a literal 180 with a note saying the field (300) was too
// risky to adopt, because the icon and the dot strip were placed at y-offsets
// measured against that 180. That is a reason to stop measuring against a
// literal, not a reason to keep one: the two children are now placed by the
// frame's own height, so the field decides the box and the contents follow it.
// The frame was also 100px shorter than the widget's `SizedBox(height:
// resolved.height)` for as long as the note stood.
//
// `animationDuration` (the hover-slide transition) has no static-frame meaning.
// The container fill, the image glyph and the position dots have no matching
// Style field — `CoreHoverGalleryStyle` carries only height / borderRadius /
// animationDuration, so those three are the preview's own and marked as such.
function buildHoverGallery(page: PageNode, lk: VarLookup): ComponentNode {
  const c = mint(page, 'HoverGallery');
  const height = dimVal(HOVER_GALLERY.fields.height);
  // g7-preview-only: the gallery's WIDTH. `SizedBox(height: resolved.height)` is
  // the whole of what the widget constrains — the width is its parent's — so this
  // is the preview choosing a frame to show that height in.
  c.resize(kHoverGalleryWidth, height);
  const heightVar = lk.sizeOrNull(height);
  if (heightVar) c.setBoundVariable('height', heightVar);
  bindRadiusN(c, lk, HOVER_GALLERY.fields.borderRadius.topLeft);
  c.clipsContent = true;
  c.fills = [];
  // The active item, as its own layer spanning the box — `items[activeIndex]`
  // is what a designer's FILL should stretch, and a layer with STRETCH
  // constraints is what follows a resized instance; the root's own fill would
  // not (#4805).
  const item = figma.createFrame();
  item.name = 'item';
  item.resize(c.width, c.height);
  // g7-preview-only: stand-in fill for the active item. The widget's `Container` carries a radius and a height and NO colour — what fills it is the caller's `items[i]` — so this tone is the preview showing that region.
  fillSem(item, lk, 'surface-container-high');
  c.appendChild(item);
  item.x = 0;
  item.y = 0;
  item.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };
  // g7-preview-only: size/ink of a placeholder image glyph, standing in for the same caller item. The widget draws no icon anywhere; this is the preview saying "a picture goes here".
  const icon = makeIcon('image', lk, { size: 40, colorVar: lk.sem('on-surface-variant'), placeholder: true });
  c.appendChild(icon);
  // Centred in the frame rather than at a measured offset — the same place for
  // any height the field states.
  icon.x = (c.width - icon.width) / kHoverGalleryHalf;
  icon.y = (c.height - icon.height) / kHoverGalleryHalf;
  const stripWidth = kHoverGalleryDots * kHoverGalleryDotPitch - (kHoverGalleryDotPitch - kHoverGalleryDotSide);
  const stripLeft = (c.width - stripWidth) / kHoverGalleryHalf;
  for (let i = 0; i < kHoverGalleryDots; i++) {
    const d = figma.createEllipse();
    // g7-preview-only: the position dots' diameter. `CoreHoverGalleryStyle` has three fields — height, borderRadius, animationDuration — and the widget draws no dots: its `Container` holds one `AnimatedSwitcher` over `items[activeIndex]`. This strip is the preview saying which of four is showing.
    bindSize(d, lk, kHoverGalleryDotSide, kHoverGalleryDotSide);
    d.x = stripLeft + i * kHoverGalleryDotPitch;
    d.y = c.height - kHoverGalleryDotBottom - kHoverGalleryDotSide;
    // g7-preview-only: which dot reads as current and how the other three recede. Same absent subject as the diameter above — no field describes a position indicator, so the active/inactive pair is this preview's own.
    fillSem(d, lk, i === 1 ? 'primary' : 'on-surface-variant');
    if (i !== 1) d.opacity = 0.4;
    c.appendChild(d);
    d.constraints = { horizontal: 'CENTER', vertical: 'MAX' };
  }
  return c;
}

// ─── MockupBrowser / MockupCode / MockupPhone ────────────────────────────────
// Three standalone components — coui_core has no drawable `Mockup` class, only
// these three contracts. A desktop app window is not a fourth: it is
// `MockupBrowser(addressBar: null)`, the same frame with the browser
// affordances left out, drawn here by that component's `Show address bar`
// property.
//
// Each mockup's shell sources its own bg/border/radius from that mockup's own
// CoreMockupXxxStyle.{backgroundColor,borderColor,borderRadius} (`border` is
// passed `null` for MockupCode, which has no borderColor field at all — no
// border is drawn, rather than reusing another type's outline literal).

function mockupShell(
  page: PageNode,
  name: string,
  lk: VarLookup,
  radius: number | Dim,
  bg: ColorData | null,
  border: ColorData | null,
  borderWidth: number | Dim = 1,
  // The body's own cast, for the mockup whose Style states one. Applied to the
  // composed `OutlinedContainer` because that instance is the box the widget
  // hands `boxShadow` to (`containerStyle`); the shell root is transparent and
  // does not clip, so the cast is not cut at the frame's edge.
  shadow: ShadowData | null = null,
): { shell: ComponentNode; surfacePin: FrameNode } {
  // Root is a transparent column. Fill / border / radius live on a composed
  // `OutlinedContainer` instance — the same primitive the four widgets wrap
  // (`mockup_*.dart` → `OutlinedContainer(containerStyle:)`). Pinned
  // STRETCH so a consumer-resized mockup keeps its chrome, matching Card.
  // Callers `sizePin` the holder LAST, after lockWidth / fillMockupBody
  // settle the host bounds (#4701).
  const c = mintPanelComp(page, name, 'VERTICAL', lk, {});
  c.clipsContent = false;
  const surface = instanceOf(page, 'OutlinedContainer');
  surface.name = 'OutlinedContainer';
  setInstanceBoolNamed(surface, 'Show child', false);
  surface.strokes = [];
  applyForwardedPanelStyle(surface, lk, {
    backgroundColor: bg,
    borderColor: border,
    borderWidth: border ? borderWidth : null,
    borderRadius: { topLeft: radius },
  });
  if (shadow) setShadow(surface, shadow, lk);
  // The rim rides the cast the container is handed: both platforms key it on
  // the stack the composed `OutlinedContainer` states, and its main is flat.
  setSurfaceRim(surface, lk, 'content', shadow != null && shadow.layers.length > 0);
  const surfacePin = pinAbsolute(c, surface, 0, 0, {
    horizontal: 'STRETCH',
    vertical: 'STRETCH',
  });
  return { shell: c, surfacePin: surfacePin as FrameNode };
}

// ─── The window's three controls ───────────────────────────────────────────
//
// Each dot is the widget's `_ControlDot(color, size, borderRadius)` — a
// rounded box, and 9999 makes it a circle. So it is a RECTANGLE carrying
// `controlBorderRadius`, not an ellipse: an ellipse draws the same pixels while
// stating nothing, the roundness implied by the node type instead of carried by
// the field, and changing the field could not move it.
//
// The controls use semantic status colours and follow the active mode.
function mockupControlDots(
  row: FrameNode,
  lk: VarLookup,
  size: number | Dim,
  radius: number | Dim,
  colors: readonly (ColorData | null)[],
): void {
  const names = ['close', 'minimize', 'maximize'];
  for (let i = 0; i < names.length; i++) {
    const dot = figma.createRectangle();
    dot.name = names[i];
    bindRadiusN(dot, lk, radius);
    bindSize(dot, lk, size, size);
    fillData(dot, lk, colors[i]);
    row.appendChild(dot);
  }
}

// The mockup's body is its screen — where a caller's `child` lives — so it takes
// whatever height the chrome leaves. Left hugging it did not: a mockup made
// taller grew its frame and kept an 86px screen with the rest empty (canvas
// measurement, 2026-09-07). The shell is fixed at the height it hugged to first,
// because Figma refuses FILL on an axis the parent hugs.
//
// Called at the very end of a shell's build, once every row is inside it.
function fillMockupBody(shell: ComponentNode, content: FrameNode): void {
  shell.primaryAxisSizingMode = 'FIXED';
  content.layoutSizingVertical = 'FILL';
}

function mockupContent(lk: VarLookup, bg: ColorData | null): FrameNode {
  // g7-preview-only: the body area's own height, as top/bottom inset. The widget puts the caller's `child` straight into its content card with no padding, so nothing states a body height — this gives the one-word `Child` stand-in a screen-shaped area to sit in instead of collapsing to a line of text.
  const content = panel('content', 'HORIZONTAL', lk, { pt: 32, pb: 32 });
  fillData(content, lk, bg);
  content.primaryAxisAlignItems = 'CENTER';
  content.counterAxisAlignItems = 'CENTER';
  return content;
}

// `CoreTextAlign` → the horizontal alignment Figma paints a text box with.
// Throws on a member it does not know, so a new alignment surfaces as a failed
// build instead of a silently left-aligned label.
function textAlignOf(choice: string): 'LEFT' | 'CENTER' | 'RIGHT' | 'JUSTIFIED' {
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
      throw new Error(`mockup_browser.addressBarTextAlign: unknown choice "${choice}"`);
  }
}

// The example page `MockupBrowser` shows in its `child` (designer's copy, #6473).
const kMockupBrowserExampleHeadline = '더 빠르게 만드는 앱과 웹';
const kMockupBrowserExampleLine = 'CoUI 컴포넌트와 토큰으로 화면을 바로 조립해요.';
const kMockupBrowserExampleActions: readonly (readonly [string, string])[] = [
  ['primary', '시작하기'],
  ['outline', '문서 보기'],
];

// Browser content fills the window beneath a pinned, blurred toolbar. The
// outline is pinned last so its stroke/highlight stays above every child.
// Show address bar removes nav, addr and actions together; the other public
// properties retain their names so existing instances keep their overrides.
function buildMockupBrowser(page: PageNode, lk: VarLookup): ComponentNode {
  const f = MOCKUP_BROWSER.fields;
  // Resolve the native color aliases before mint clears an existing browser.
  // An unsupported variable API must fail while the previous canvas is intact.
  for (const background of [f.toolbarBackgroundColor, f.capsuleBackgroundColor, f.addressBarBackgroundColor]) {
    const cd = colorData(background);
    if (cd?.color) lk.semWithOpacity(cd.color, cd.opacity ?? 1);
  }
  const { shell: browser, surfacePin } = mockupShell(
    page, 'MockupBrowser', lk, f.borderRadius.topLeft,
    colorData(f.backgroundColor), null,
    f.borderWidth,
    f.boxShadow,
  );
  // g7-preview-only: the designer's 380×200 preview; runtime follows its host.
  lockWidth(browser, 380);
  const owner = propertyOwner(browser);

  const toolbarPad = f.toolbarPadding;
  const bar = panel('bar', 'HORIZONTAL', lk, {
    pl: toolbarPad.l, pr: toolbarPad.r, pt: toolbarPad.t, pb: toolbarPad.b,
    gap: f.toolbarSpacing,
  });
  bar.counterAxisAlignItems = 'CENTER';
  // Author the toolbar in flow; pin it only after its final insertion below.
  browser.appendChild(bar);
  fillComposedColor(bar, lk, colorData(f.toolbarBackgroundColor));
  borderData(bar, lk, colorData(f.toolbarBorderColor), dimVal(f.toolbarBorderWidth));
  bar.strokeTopWeight = 0;
  bar.strokeLeftWeight = 0;
  bar.strokeRightWeight = 0;
  bar.topLeftRadius = dimVal(f.borderRadius.topLeft);
  bar.topRightRadius = dimVal(f.borderRadius.topRight);
  bar.setBoundVariable('topLeftRadius', lk.radius(dimVal(f.borderRadius.topLeft)));
  bar.setBoundVariable('topRightRadius', lk.radius(dimVal(f.borderRadius.topRight)));
  bar.effects = [{ type: 'BACKGROUND_BLUR', blurType: 'NORMAL', radius: dimVal(f.toolbarBlur), visible: true }];
  // The overlay's bounds are explicit: the address FILL slot must not make
  // its parent hug width or height while the frame is being assembled.
  bar.primaryAxisSizingMode = 'FIXED';
  bar.counterAxisSizingMode = 'FIXED';
  bar.layoutSizingVertical = 'FIXED';
  bar.resize(bar.width, dimVal(f.toolbarHeight));
  bar.setBoundVariable('height', lk.spaceLadder(dimVal(f.toolbarHeight)));

  const controls = panel('controls', 'HORIZONTAL', lk, { gap: f.controlSpacing });
  controls.counterAxisAlignItems = 'CENTER';
  bar.appendChild(controls);
  mockupControlDots(controls, lk, f.controlSize, f.controlBorderRadius.topLeft, [
    colorData(f.controlCloseColor),
    colorData(f.controlMinimizeColor),
    colorData(f.controlMaximizeColor),
  ]);
  bindVisibleProp(controls, defineProp(owner, 'Show controls', 'BOOLEAN', true));

  const showAddressBar = defineProp(owner, 'Show address bar', 'BOOLEAN', true);

  const capsulePad = f.capsulePadding;
  const capsuleOpts = { radius: f.capsuleBorderRadius.topLeft, pl: capsulePad.l, pr: capsulePad.r, pt: capsulePad.t, pb: capsulePad.b };
  const nav = panel('nav', 'HORIZONTAL', lk, { ...capsuleOpts, gap: f.navSpacing });
  fillComposedColor(nav, lk, colorData(f.capsuleBackgroundColor));
  nav.counterAxisAlignItems = 'CENTER';
  bar.appendChild(nav);
  // Through `makeIcon`, whose paint binds every vector stroke to the CoUI
  // semantic variable named by the icon style — never left to whatever colour
  // the glyph library's own component carries.
  const back = makeIcon('chevron-left', lk,
    glyphOpts(lk, colorData(f.navIconStyle.color), f.navIconStyle.size, 'size'));
  back.name = 'back';
  nav.appendChild(back);
  const forward = makeIcon('chevron-right', lk,
    glyphOpts(lk, colorData(f.navDisabledIconStyle.color), f.navDisabledIconStyle.size, 'size'));
  forward.name = 'forward';
  nav.appendChild(forward);
  nav.resize(nav.width, dimVal(f.capsuleHeight));
  nav.setBoundVariable('height', lk.spaceLadder(dimVal(f.capsuleHeight)));
  nav.layoutSizingVertical = 'FIXED';
  bindVisibleProp(nav, showAddressBar);

  const addrPad = f.addressBarPadding;
  const addr = panel('addr', 'HORIZONTAL', lk, {
    radius: f.addressBarBorderRadius.topLeft,
    pl: addrPad.l, pr: addrPad.r, pt: addrPad.t, pb: addrPad.b,
    gap: f.addressBarSpacing,
  });
  // `Container(alignment: Alignment.center)` around the text.
  addr.primaryAxisAlignItems = 'SPACE_BETWEEN';
  addr.counterAxisAlignItems = 'CENTER';
  fillComposedColor(addr, lk, colorData(f.addressBarBackgroundColor));
  bar.appendChild(addr);
  const url = makeLabel('example.com', lk, textLabelOpts(lk, textStyleData(f.addressBarTextStyle)));
  const domain = panel('domain', 'HORIZONTAL', lk, { gap: f.domainSpacing });
  domain.counterAxisAlignItems = 'CENTER';
  addr.appendChild(domain);
  const lock = makeIcon('lock', lk, glyphOpts(lk, colorData(f.addressIconStyle.color), f.addressIconStyle.size, 'size'));
  lock.name = 'lock';
  domain.appendChild(lock);
  url.name = 'address';
  domain.appendChild(url);
  const reload = makeIcon('rotate-cw', lk, glyphOpts(lk, colorData(f.addressIconStyle.color), f.addressIconStyle.size, 'size'));
  reload.name = 'reload';
  addr.appendChild(reload);
  // Resize first, sizing mode after: `resize` puts both axes back to FIXED, so
  // an `Expanded` pill set to FILL before it would stop filling the toolbar.
  addr.resize(addr.width, dimVal(f.addressBarHeight));
  addr.setBoundVariable('height', lk.spaceLadder(dimVal(f.addressBarHeight)));
  addr.layoutSizingVertical = 'FIXED';
  addr.layoutSizingHorizontal = 'FILL';
  // The label takes the pill's width so `addressBarTextAlign` decides where the
  // text sits, rather than the text box hugging and the field reaching nothing.
  // Domain hugs the lock and text; the address capsule takes the spare width.
  url.textAlignHorizontal = textAlignOf(f.addressBarTextAlign.choice);
  bindTextProp(url, defineProp(owner, 'Address', 'TEXT', 'example.com'));
  bindVisibleProp(addr, showAddressBar);

  const action = makeIcon('plus', lk,
    glyphOpts(lk, colorData(f.actionIconStyle.color), f.actionIconStyle.size, 'size'));
  const actions = panel('actions', 'HORIZONTAL', lk, { ...capsuleOpts, gap: f.actionSpacing });
  fillComposedColor(actions, lk, colorData(f.capsuleBackgroundColor));
  actions.counterAxisAlignItems = 'CENTER';
  bar.appendChild(actions);
  const share = makeIcon('share', lk, glyphOpts(lk, colorData(f.actionIconStyle.color), f.actionIconStyle.size, 'size'));
  share.name = 'share';
  actions.appendChild(share);
  action.name = 'action';
  actions.appendChild(action);
  actions.resize(actions.width, dimVal(f.capsuleHeight));
  actions.setBoundVariable('height', lk.spaceLadder(dimVal(f.capsuleHeight)));
  actions.layoutSizingVertical = 'FIXED';
  bindVisibleProp(actions, showAddressBar);

  const chromeWidth = f.chromeWidth;
  const inset = panel('inset', 'VERTICAL', lk, { pl: chromeWidth, pr: chromeWidth, pb: chromeWidth });
  browser.appendChild(inset);
  inset.layoutSizingHorizontal = 'FILL';
  // g7-preview-only: the example page's side inset (designer's copy, #6473) — the caller's `child` fills the card with no padding of the widget's.
  const content = panel('content', 'HORIZONTAL', lk, { pt: f.toolbarHeight, pl: 28, pr: 28 });
  fillData(content, lk, colorData(f.contentBackgroundColor));
  // The example page's hero sits at the start, centred down the body (#6473).
  content.primaryAxisAlignItems = 'MIN';
  content.counterAxisAlignItems = 'CENTER';
  content.cornerRadius = Math.max(0, dimVal(f.borderRadius.topLeft) - dimVal(chromeWidth));
  // `clipBehavior: .antiAlias` — a screenshot child follows the card's corners.
  content.clipsContent = true;
  inset.appendChild(content);
  content.layoutSizingHorizontal = 'FILL';
  // The example page the card shows (#6473, the designer's copy): a hero —
  // headline, one line under it, two actions — rather than the one word it
  // held, which read as an empty window. `child` is a caller widget the card
  // holds without merging any text style over it, so the headline's role is
  // the example's; the line under it wears `contentTextStyle`, the ambient
  // copy style the card states.
  // g7-preview-only: the hero's line gap (designer's copy).
  const hero = panel('hero', 'VERTICAL', lk, { gap: 6 });
  content.appendChild(hero);
  const headline: ColorData = { color: 'on-surface' };
  const child = makeLabel(kMockupBrowserExampleHeadline, lk, textLabelOpts(lk, textStyleData({ role: 'titleLarge' }), headline));
  child.name = 'child';
  hero.appendChild(child);
  const line = makeLabel(kMockupBrowserExampleLine, lk, textLabelOpts(lk, textStyleData(f.contentTextStyle)));
  line.name = kMockupBrowserExampleLine;
  hero.appendChild(line);
  // g7-preview-only: the gap between the hero's two actions and the extra space above them (designer's copy).
  const heroActions = panel('actions', 'HORIZONTAL', lk, { gap: 8, pt: 10 });
  hero.appendChild(heroActions);
  for (const [variant, label] of kMockupBrowserExampleActions) {
    const axes = { Variant: variant, Size: 'sm', State: 'enabled', Shape: 'rectangle' };
    const action = instanceOf(page, 'Button', bestVariantName(page, 'Button', axes));
    action.name = 'Button';
    setInstanceTextNamed(action, 'Child', label);
    heroActions.appendChild(action);
  }
  // The TEXT on the label and the toggle on the card: `componentPropertyReferences`
  // is one map per node and both binders assign the whole map, so binding both to
  // one node would leave whichever came first declared and driving nothing. The
  // toggle drives the hero as well as the card, so `Show child` off removes the
  // whole example, as the copy does.
  bindTextProp(child, defineProp(owner, 'Child', 'TEXT', kMockupBrowserExampleHeadline));
  const showChild = defineProp(owner, 'Show child', 'BOOLEAN', true);
  bindVisibleProp(content, showChild);
  bindVisibleProp(hero, showChild);

  // g7-preview-only: designer preview height, independent of caller content.
  browser.resize(browser.width, 200);
  fillMockupBody(browser, inset);
  content.layoutSizingVertical = 'FILL';
  sizePin(surfacePin, browser.width, browser.height);
  // Reparenting can recalculate auto-layout placement. The last insertion
  // must own the pin as well as the paint order: no bare append after pinning.
  const barPin = pinAbsolute(browser, bar, 0, 0, { horizontal: 'STRETCH', vertical: 'MIN' });
  sizePin(barPin, browser.width, dimVal(f.toolbarHeight));
  bar.x = 0;
  bar.y = 0;
  // A rectangle's stroke silhouette receives the inner highlight. An empty
  // frame with the same effect does not paint it (Figma export probe, #5341).
  const windowBorder = figma.createRectangle();
  windowBorder.name = 'window border';
  bindRadiusN(windowBorder, lk, f.borderRadius.topLeft);
  windowBorder.fills = [];
  borderData(windowBorder, lk, colorData(f.borderColor), dimVal(f.borderWidth));
  windowBorder.strokeAlign = 'INSIDE';
  setShadow(windowBorder, { layers: [{ x: 0, y: dimVal(f.highlightWidth), blur: 0, spread: 0, opacity: 1, inset: true }] }, lk, colorData(f.highlightColor));
  const borderPin = pinAbsolute(browser, windowBorder, 0, 0, { horizontal: 'STRETCH', vertical: 'STRETCH' });
  sizePin(borderPin, browser.width, browser.height);
  return browser;
}

// ─── There is one box, so there is one fill ────────────────────────────────
//
// The body was painted 'inverse-surface' with 'inverse-on-surface' ink — a dark
// terminal — and the note here defended it: `backgroundColor`
// (surface-container-low) and `textStyle` (on-surface) describe a *light* panel,
// which the dark body would be illegible against, and no field distinguishes
// "shell background" from "code body background".
//
// The reason no field distinguishes them is that the widget has no two things to
// distinguish. `mockup_code.dart` is a single `Container(padding:
// resolved.padding, color: resolved.backgroundColor, borderRadius:
// resolved.borderRadius)` over a `Column` of lines. This builder splits that one
// box across two frames — the shell carries the fill and the corner, the body the
// inset and the line seam — so the fill belongs to the shell, which already
// reads it, and the body states none: `autoFrame` leaves it transparent and the
// shell shows through.
//
// So the dark panel goes, and both halves of it move: the canvas said
// inverse-surface where the data says surface-container-low, and inverse-on-surface
// where `textStyle` says on-surface. It was a panel the app never renders, and
// "the light one would be illegible" was an argument for keeping the wrong
// colour rather than for reading the right one.
//
// Everything else about the body was already data-driven: its inset
// (`padding`, one value per side — vertical and horizontal differ),
// the line↔line seam (`lineSpacing`, 4 — the widget's per-line
// `Padding(.only(bottom:))`), and the code lines' SIZE and line box, which
// come from `textStyle`'s role (codeSm: 12, a fixed 21px line box,
// monospace) rather than a literal they used to be drawn at — being
// illegible on a dark fill was not a reason to render a role at a size the
// data never states, and now there is no dark fill either.
// With the ink coming from the same slot, `textLabelOpts` is the whole of it:
// role for size/weight/line-height, `textStyle.color` for the colour. The
// `typographyColorOpts` split — role from the style, colour from the caller —
// is for the places where a STATE and not the typography slot picks the ink,
// which this is not.
//
// The lines are NUMBERED, and that is the widget's default rather than a choice
// made here. `MockupCode.fromString` takes `showLineNumbers = true` and fills
// `CoreCodeLine.prefix` with `'${index + 1}'`, so a gutter is what the component
// draws unless a caller turns it off. What stood here was a terminal transcript
// (`'$ npm install coui'`), which is a real usage but is the opt-OUT: with no
// prefix on any line, neither `prefixTextStyle` nor `lineNumberWidth` had a node,
// and the reason written down for that was the exemplar's own choice.
//
// MockupCode has no borderColor field, so the shell gets no border.
function buildMockupCode(page: PageNode, lk: VarLookup): ComponentNode {
  const { shell: code, surfacePin } = mockupShell(
    page, 'MockupCode', lk, MOCKUP_CODE.fields.borderRadius.topLeft,
    colorData(MOCKUP_CODE.fields.backgroundColor), null,
  );
  // g7-preview-only: the shell's own width. The widget's root is `width: .infinity` — it fills whatever it is given — so a finite frame has to come from somewhere, and this preview uses the same 280 as the browser mockup.
  lockWidth(code, 280);
  const cPad = MOCKUP_CODE.fields.padding;
  // No fill: the widget's one `Container` has one, the shell carries it from
  // `backgroundColor`, and this frame is the other half of that same box.
  const codeBody = panel('body', 'VERTICAL', lk, {
    pl: cPad.l, pr: cPad.r, pt: cPad.t, pb: cPad.b,
    gap: MOCKUP_CODE.fields.lineSpacing,
  });
  code.appendChild(codeBody);
  codeBody.layoutSizingHorizontal = 'FILL';
  // A terminal transcript, one line per tone: `CoreCodeLine.tone` is a line's
  // ink, so the sample states every tone the line carries rather than one ink
  // for the whole block. `neutral` is no tone field — it is the code's own ink,
  // `textStyle.color`. The lines are samples (a mockup draws a session caught at
  // one moment); the ink each one wears is read from the tone's own field.
  const codeLines: { text: string; tone: string }[] = [
    { text: '$ flutter run', tone: 'muted' },
    { text: 'Launching lib/main.dart', tone: 'neutral' },
    { text: 'Warning: 1 deprecated API', tone: 'warning' },
    { text: 'Error: port 8080 is in use', tone: 'error' },
    { text: 'Built build/app.apk', tone: 'success' },
    { text: 'http://localhost:8080', tone: 'link' },
  ];
  const tones =
    COMPONENTS.mockup.axes.other.find((e) => e.enum === 'CoreCodeLineTone')?.members ?? [];
  if (tones.length === 0) {
    throw new Error(
      'MockupCode: CoreCodeLineTone is missing from components.json ' +
        '(components.mockup.axes.other) — re-run `export:figma-components`.',
    );
  }
  // `<tone>ToneColor` is the field that states a tone's ink; `neutral` has none.
  const toneFields: Record<string, Color> = {
    muted: MOCKUP_CODE.fields.mutedToneColor,
    link: MOCKUP_CODE.fields.linkToneColor,
    success: MOCKUP_CODE.fields.successToneColor,
    warning: MOCKUP_CODE.fields.warningToneColor,
    error: MOCKUP_CODE.fields.errorToneColor,
  };
  // A tone Core adds has no ink here yet, and a table entry for a tone Core
  // dropped is dead — both are refused, not drawn as neutral.
  for (const tone of tones) {
    if (tone !== 'neutral' && toneFields[tone] == null) {
      throw new Error(`MockupCode: tone "${tone}" has no ink field wired — add \`${tone}ToneColor\` to toneFields.`);
    }
  }
  const toneInk = (tone: string): ColorData | null => {
    if (!tones.includes(tone)) throw new Error(`MockupCode: "${tone}" is not a CoreCodeLineTone.`);
    return tone === 'neutral' ? null : colorData(toneFields[tone]);
  };
  // Both the metrics and the ink come from `textStyle`. The spread that used to
  // sit here re-pointed `colorVar` at 'inverse-on-surface' and blanked
  // `rawColor` so the inverse literal could not be outranked — i.e. it took the
  // slot's colour and threw it away. With the body no longer dark there is
  // nothing to throw it away for.
  const codeStyle = textStyleData(MOCKUP_CODE.fields.textStyle);
  const codeLineOpts = textLabelOpts(lk, codeStyle);
  // The metrics are the code's, the ink is the tone's — the split
  // `typographyColorOpts` exists for. A tone states only the ink.
  const codeToneOpts = (tone: string): ReturnType<typeof textLabelOpts> => {
    const ink = toneInk(tone);
    return ink == null ? codeLineOpts : typographyColorOpts(lk, codeStyle, ink);
  };
  const gutterOpts = textLabelOpts(lk, textStyleData(MOCKUP_CODE.fields.prefixTextStyle));
  for (let i = 0; i < codeLines.length; i++) {
    // gutter + code, the two spans the widget emits per line. The gutter's width
    // is fixed (`'width': '${lineNumberWidth / kRemDivisor}rem'`) rather than
    // hugging its digits, which is what keeps the code column aligned once the
    // count reaches two digits — so it is locked here, not left to HUG.
    const lineRow = panel('line', 'HORIZONTAL', lk, {});
    lineRow.itemSpacing = 0;
    codeBody.appendChild(lineRow);
    lineRow.layoutSizingHorizontal = 'FILL';
    const gutter = makeLabel(`${i + 1}`, lk, gutterOpts);
    lineRow.appendChild(gutter);
    gutter.layoutSizingVertical = 'HUG';
    gutter.layoutSizingHorizontal = 'FIXED';
    gutter.resize(dimVal(MOCKUP_CODE.fields.lineNumberWidth), gutter.height);
    // A gutter width is a dimension, so it binds on the size ladder (the
    // default is `CoreSize.size28`); `lk.size` falls back to the space step
    // of the same number in a document that predates the size ladder.
    gutter.setBoundVariable('width', lk.size(dimVal(MOCKUP_CODE.fields.lineNumberWidth)));
    const code = makeLabel(codeLines[i].text, lk, codeToneOpts(codeLines[i].tone));
    lineRow.appendChild(code);
    code.layoutSizingHorizontal = 'FILL';
  }
  sizePin(surfacePin, code.width, code.height);
  return code;
}

// ─── MockupDevice — one rule set, two bodies ──────────────────────────────
//
// The widget's structure, the same on both platforms (`mockup_device.dart`),
// back to front:
//
// ```text
// Stacks (nothing clips — the buttons protrude)
//   ├─ power / volume buttons        (buttonColor + length gloss + depth shade)
//   ├─ OutlinedContainer              (railGradient · borderColor/borderWidth
//   │                                  · borderRadius · containerStyle.boxShadow)
//   ├─ rim highlight · rim glow       (hairline strokes over the body)
//   ├─ antenna bands                  (phone only)
//   └─ bezel                          (bezelColor · outline · inner shadow)
//        ├─ screen                    (backgroundColor · radius − inset · clip)
//        │    ├─ child                 // W slot — fills the screen under the safe area
//        │    ├─ StatusBar              // the operating system's, drawn in points × S
//        │    ├─ camera set             // when the camera is cut out of the screen
//        │    └─ HomeIndicator
//        └─ camera set                 // when the camera sits in the bezel strip
// ```
//
// Every rectangle is DERIVED from read fields by the rules
// `CoreMockupDeviceLayout` states, and `src/mockup-device-geometry.ts` is that
// rule set transcribed. What it returns is a derivation of read fields — the
// shape `OutlinedContainer`'s inner `radius − borderWidth` has — so the results
// are written as numbers and not bound: the bezel radius (21 · 13) is not a step
// on the radius ladder, and binding the ones that happen to be would claim a
// token the code never names.
//
// The members are `Device=… , Orientation=… , Finish=…`, the product of
// `defaultsByDevice` (a device Core adds becomes a member here with no edit),
// `CoreMockupOrientation` and `CoreMockupDeviceFinish` read off the export's
// `axes.other` — the orientation enum keys no defaults map, because a turned
// device is the same hardware and only its derived geometry turns. The finish
// is keyed by `defaultsByFinish`, whose row is laid over the per-device row:
// `realistic` is the empty row (the picture drawn above), `flat` restates a
// frame — one ring in `surfaceContainerHighest` around a 1 : 2 screen, with no
// rail, rim, button, antenna band, lens, cast or inner shadow, so those nodes
// are not drawn at all rather than drawn at zero. A flat frame defaults the
// camera, status bar and home indicator off (`kFinishPose`), and the three
// `Show …` BOOLEANs are set-wide, so a flat member draws none of that chrome.
//
// The hardware colours — frame, bezel, buttons, camera — are the designer copy's
// own values, literals in the contract (their `ref` is null in the export), so
// they land as raw paints: a mode switch changes the screen, the status bar and
// the home indicator and leaves the device as it is, and no brand palette tints
// it. The paint helpers would bind a token as deep as the paint goes — a solid's
// colour, each stop of a gradient (`ColorStop.boundVariables`) — but these
// defaults state none. A paint the design states at a strength (the antenna ramp
// at 70%) carries that strength on the PAINT with the node at full strength —
// `assignPaints` makes it stick, because the write resets it. The optical
// layers — the button's gloss and shade, the rim glow, the bezel's inner shadow
// and the body's cast — are literals too: translucent white or black laid over
// each other, the same in every mode. The screen, the status bar's ink and the
// home indicator bind the ordinary semantic tokens. Every scaled length — the
// status bar is drawn in iOS points times the screen's factor — is a literal: a
// bound variable would overwrite it with the unscaled value.
//
// The body is the composed `OutlinedContainer`, not a painted frame — the
// widget hands it rail gradient, rim, radius and the nested `containerStyle`
// (its `CoreShadow.xl` cast). The bezel and screen sit over it as siblings
// because Figma cannot nest children into an instance; with its `Show child`
// off the primitive draws the box and nothing inside it.
//
// The status bar and the home indicator are DRAWN here, not instanced: the
// canvas's own are library instances of system-bar components that code cannot
// create, so the frames below are the closest structure the data can state and
// the plugin's comparison lists them as differing.
//
// `child` (required `W`) is a TEXT property on a label centred on the screen.
// It is bound after `finish()`, because a property belongs to the set and a
// member mid-mount has none.

// g7-preview-only: each body's canvas width. `CoreMockupDeviceStyle.defaultWidth` (320) is a widget-edge knob with no instance field; these are the widths the preview drew, chosen so each screen is the aspect the device states (144 = 9×16 and 299 = the tablet's aspect numerator) and no edge lands on a fraction.
const kDevicePreviewWidth: Record<string, Record<string, number>> = {
  phone: { portrait: 160, landscape: 328 },
  tablet: { portrait: 321, landscape: 455 },
};

// What a finish says about the operating system's chrome and the body's width. Neither is a field of `defaultsByFinish`: whether the camera, status bar and home indicator are drawn is the widget's `showCamera` / `showStatusBar` / `showGestureBar`, whose default follows the finish (`CoreMockupDeviceContract.defaultShow…For`), and the width is a widget-edge knob. A finish Core adds has no entry here and the builder throws — it has to be decided, not drawn as the one before it.
//
// `realistic` draws the picture of a device: the three layers are on and the body is `kDevicePreviewWidth`. `flat` is a frame: they default off, so the member does not draw them at all — the `Show camera` · `Show status bar` · `Show gesture bar` BOOLEANs are set-wide and default on, so a flat member that kept the layers would show them and a flat member bound to them could not default off. A caller who turns them on for a flat frame has no Figma pose for it. The flat screen is the 1 : 2 the finish states for every device kind, so its width does not depend on the device: portrait is `CoreMockupDeviceStyle.defaultFlatWidth` (the screen plus one ring each side); turned, the same screen runs 2 : 1, so the body is the long edge — `flatScreenWidth` — beyond that. Read from the export's constants, so no edge lands on a fraction.
interface FinishPose {
  readonly osChrome: boolean;
  readonly width: (device: string, orientation: string) => number | undefined;
}
const kFinishPose: Record<string, FinishPose> = {
  realistic: { osChrome: true, width: (device, orientation) => kDevicePreviewWidth[device]?.[orientation] },
  flat: {
    osChrome: false,
    width: (_device, orientation) => {
      const k = MOCKUP_DEVICE.constants;
      const portrait = dimVal(k.flatWidth);
      if (orientation === 'portrait') return portrait;
      if (orientation === 'landscape') return portrait + dimVal(k.flatScreenWidth);
      return undefined;
    },
  },
};

// A pinned part holds to the two sides its position was measured from —
// otherwise a resized member drags the slab off its edge. The edge fixes the
// across-axis (a bottom slab holds to the bottom); `fromRightEnd` fixes the
// along-axis, because power measures from the far end and volume from the near
// one, exactly as `mockupDeviceGeometry` computes them.
function edgeConstraints(edge: DeviceEdge, fromRightEnd: boolean): Constraints {
  switch (edge) {
    case 'left':
      return { horizontal: 'MIN', vertical: 'MIN' };
    case 'right':
      return { horizontal: 'MAX', vertical: 'MIN' };
    case 'top':
      return { horizontal: fromRightEnd ? 'MAX' : 'MIN', vertical: 'MIN' };
    case 'bottom':
      return { horizontal: fromRightEnd ? 'MAX' : 'MIN', vertical: 'MAX' };
  }
}

// An antenna band is pinned to the edge it lies on across it, and to the end it
// was measured from along it.
function bandConstraints(band: AntennaBand): Constraints {
  const across = band.edge === 'left' || band.edge === 'top' ? 'MIN' : 'MAX';
  const along = band.fromFarEnd ? 'MAX' : 'MIN';
  return isVerticalEdge(band.edge)
    ? { horizontal: across, vertical: along }
    : { horizontal: along, vertical: across };
}

// A body-wide layer keeps its insets when the member is resized.
const kStretch: Constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };

// One flat hardware part — a rounded box at an absolute rectangle, unpainted.
// Half the short side for the radius, the widget's `_pillRadius`, unless the
// caller states one.
function devicePart(
  host: FrameNode | ComponentNode,
  name: string,
  r: DeviceRect,
  constraints: Constraints,
  radius?: number,
): RectangleNode {
  const part = figma.createRectangle();
  part.name = name;
  part.resize(Math.max(r.w, kMinNodeSize), Math.max(r.h, kMinNodeSize));
  part.cornerRadius = radius ?? Math.min(r.w, r.h) / 2;
  part.fills = [];
  pinAbsolute(host, part, r.x, r.y, constraints);
  return part;
}

// Figma refuses a zero-size node; a derived rectangle that collapses to nothing
// is drawn at the smallest size it accepts.
const kMinNodeSize = 0.01;

// A stroke at a literal weight, aligned as the widget draws it. `borderData`
// would bind the weight to a `stroke/<n>` step — right for a token width, wrong
// for the half-px outlines and the scaled battery outline, which no step names
// and which the bound value would overwrite.
//
// A token colour below full strength keeps its token and says the strength
// somewhere, and `strength` is where: `node` fades the NODE (the same route
// `fillData` takes for a fill), so the outline must not be a node whose children
// would fade with it — every caller passes a childless one; `paint` leaves the
// node at full strength and lays the opacity on the stroke paint itself, which is
// how a hardware highlight is stated.
function paintStroke(
  node: RectangleNode | FrameNode,
  lk: VarLookup,
  cd: ColorData | null,
  weight: number,
  align: 'INSIDE' | 'OUTSIDE',
  strength: 'node' | 'paint' = 'node',
): void {
  if (cd == null || (cd.color == null && cd.argb == null)) {
    node.strokes = [];
    return;
  }
  if (cd.color == null) {
    node.strokes = [literalPaint(cd)];
  } else if (strength === 'paint') {
    assignPaints(node, 'strokes', [colorPaint(lk, cd, node)]);
  } else {
    node.strokes = [solid(lk.sem(cd.color), 1, node)];
    fadeNode(node, cd.opacity == null ? 1 : cd.opacity);
  }
  node.strokeWeight = weight;
  node.strokeAlign = align;
}

// A `CoreVectorGlyph` as a vector node, scaled from the glyph's own box to
// `w` × `h`. The path is `M` / `L` / `C` / `Z` in the glyph's units, which
// Figma's `vectorPaths` takes as it is.
function glyphVector(
  host: FrameNode,
  lk: VarLookup,
  name: string,
  glyph: DeviceGlyph,
  w: number,
  h: number,
  fill: ColorData | null,
): VectorNode {
  const vector = figma.createVector();
  vector.name = name;
  let windingRule: 'EVENODD' | 'NONZERO';
  if (glyph.fillRule === 'evenOdd') windingRule = 'EVENODD';
  else if (glyph.fillRule === 'nonZero') windingRule = 'NONZERO';
  else throw new Error(`MockupDevice: unknown glyph fill rule "${glyph.fillRule}" (evenOdd and nonZero are drawn).`);
  vector.vectorPaths = [{ windingRule, data: glyph.path }];
  vector.resize(Math.max(w, kMinNodeSize), Math.max(h, kMinNodeSize));
  fillData(vector, lk, fill);
  vector.strokes = [];
  host.appendChild(vector);
  return vector;
}

// The names the canvas gives the status bar's layers — Figma-library facts, not
// Core's: Core states the geometry and which glyph is which only by the role the
// geometry port attaches.
const kStatusGlyphName: Record<string, string> = {
  cellular: 'Cellular Connection',
  wifi: 'Wifi',
  battery: 'Battery',
};
const kStatusTextName: Record<string, string> = {
  meridiem: 'AM/PM',
  date: 'Date',
};

// The text style a status bar item is set in: the device's role, scaled.
interface StatusBarInk {
  // `CoreTextStyle` role + colour, resolved against the type scale.
  style: ReturnType<typeof textStyleData>;
  scale: number;
}

// One piece of sample text. The role's size shrinks with the screen
// (`CoreTextStyle.scale`: font size × factor; tracking em and unitless leading
// are ratios and follow on their own), so the size is a literal — a bound
// `font-size/<role>` variable would overwrite it with the unscaled value, and
// the role is deliberately not passed for the same reason. Family and weight DO
// bind: neither shrinks.
function statusBarText(host: FrameNode, lk: VarLookup, text: string, ink: StatusBarInk): TextNode {
  const style = ink.style;
  if (style.fontSize == null || style.color == null || style.color.color == null) {
    throw new Error('MockupDevice: the status bar text style states no role size or no token colour.');
  }
  const label = makeLabel(text, lk, {
    size: style.fontSize * ink.scale,
    colorVar: lk.sem(style.color.color),
    style: weightStyle(style.fontWeight),
    lineHeightPercent: style.lineHeight == null ? undefined : style.lineHeight * kPercent,
    letterSpacingEm: style.letterSpacing ?? undefined,
  });
  // `font-weight/<group>` of the role (`title`, `label`) — what the canvas binds.
  const group = style.role == null ? null : roleLeaf(style.role).split('-')[0];
  const weight = group == null ? undefined : lk.typographyOrNull(`font-weight/${group}`);
  if (weight) label.setBoundVariable('fontWeight', weight);
  host.appendChild(label);
  return label;
}

const kPercent = 100;
// Two gaps are the same gap when they differ by less than this — they come out
// of the same multiplication, so a real difference is far larger.
const kGapEpsilon = 1e-9;

// The phone's battery: an outline, a nub and a level in one box. The outline's
// stroke sits INSIDE its box; the level and nub are fills.
function statusBarBattery(host: FrameNode, lk: VarLookup, item: StatusBarBatteryItem): void {
  const f = MOCKUP_DEVICE.fields;
  const battery = figma.createFrame();
  battery.name = kStatusGlyphName[item.role];
  battery.layoutMode = 'NONE';
  battery.fills = [];
  battery.clipsContent = false;
  battery.resize(Math.max(item.w, kMinNodeSize), Math.max(item.h, kMinNodeSize));
  host.appendChild(battery);
  const top: Constraints = { horizontal: 'MIN', vertical: 'MIN' };

  const outline = devicePart(battery, 'Border', item.border, top, item.borderRadius);
  paintStroke(outline, lk, colorData(f.statusBarBatteryBorderColor), item.borderWidth, 'INSIDE');

  const nub = glyphVector(
    battery,
    lk,
    'Cap',
    item.capGlyph,
    item.cap.w,
    item.cap.h,
    colorData(f.statusBarBatteryCapColor),
  );
  nub.x = item.cap.x;
  nub.y = item.cap.y;

  const level = devicePart(battery, 'Capacity', item.capacity, top, item.capacityRadius);
  fillData(level, lk, colorData(f.statusBarIconColor));
}

// A row of items. The gaps between them are one number each, and a Figma
// auto-layout frame has ONE spacing — so a row whose gaps all match is one
// frame, and a row whose gaps differ nests: it splits at its widest gap into
// segments, each a row of its own. That is the canvas's own structure for the
// tablet clock (`Time` holds the clock and its meridiem, 2 pt apart, inside a
// row that keeps the date 8 pt away).
function statusBarRow(host: FrameNode, lk: VarLookup, items: readonly StatusBarItem[], ink: StatusBarInk): void {
  const f = MOCKUP_DEVICE.fields;
  const gaps = items.slice(0, -1).map((i) => i.gapAfter);
  const widest = gaps.length === 0 ? 0 : Math.max(...gaps);
  host.itemSpacing = widest;
  const uniform = gaps.every((gap) => Math.abs(gap - widest) < kGapEpsilon);

  const draw = (item: StatusBarItem): void => {
    switch (item.kind) {
      case 'text': {
        const label = statusBarText(host, lk, item.text, ink);
        const name = kStatusTextName[item.role];
        if (name != null) label.name = name;
        return;
      }
      case 'glyph':
        glyphVector(host, lk, kStatusGlyphName[item.role], item.glyph, item.w, item.h, colorData(f.statusBarIconColor));
        return;
      case 'battery':
        statusBarBattery(host, lk, item);
        return;
    }
  };

  if (uniform) {
    for (const item of items) draw(item);
    return;
  }
  let segment: StatusBarItem[] = [];
  const flush = (): void => {
    if (segment.length === 1) {
      draw(segment[0]);
    } else if (segment.length > 1) {
      const nested = autoFrame(segment[0].role === 'clock' ? 'Time' : 'group', 'HORIZONTAL');
      nested.counterAxisAlignItems = 'CENTER';
      host.appendChild(nested);
      statusBarRow(nested, lk, segment, ink);
    }
    segment = [];
  };
  items.forEach((item, i) => {
    segment.push(item);
    if (i < items.length - 1 && Math.abs(item.gapAfter - widest) < kGapEpsilon) flush();
  });
  flush();
}

// `start` / `center` / `end` as the main-axis alignment Figma lays a row out by.
function rowAlignment(alignment: StatusBarGroup['alignment']): 'MIN' | 'CENTER' | 'MAX' {
  switch (alignment) {
    case 'start':
      return 'MIN';
    case 'center':
      return 'CENTER';
    case 'end':
      return 'MAX';
  }
}

function sameRect(a: DeviceRect, b: DeviceRect): boolean {
  return a.x === b.x && a.y === b.y && a.w === b.w && a.h === b.h;
}

// The status bar over the top of the screen: the screen's own fill (opaque,
// over the child) and the two groups. The bar is ONE auto-layout row with the
// groups pushed to its two ends — space between — and the bar's padding is
// exactly what puts each group's box where Core states it. A device with wings
// gives each group a fixed box and centres its items in it; one without lets the
// groups hug their content and hug the edges.
function drawStatusBar(
  screen: FrameNode,
  lk: VarLookup,
  bar: StatusBarLayout,
  style: ReturnType<typeof textStyleData>,
): FrameNode {
  const f = MOCKUP_DEVICE.fields;
  const lead = bar.leading;
  const trail = bar.trailing;
  const wings = !sameRect(lead.box, trail.box);
  if (lead.box.y !== trail.box.y || lead.box.h !== trail.box.h) {
    throw new Error('MockupDevice: the two status bar groups state different vertical boxes — the bar draws one row.');
  }
  if (!wings && (lead.alignment !== 'start' || trail.alignment !== 'end')) {
    throw new Error(
      'MockupDevice: a status bar whose groups share one box has to push them to its two ends ' +
        `(leading start, trailing end) — got ${lead.alignment} / ${trail.alignment}.`,
    );
  }

  const frame = figma.createFrame();
  frame.name = 'StatusBar';
  frame.fills = [];
  frame.clipsContent = false;
  frame.layoutMode = 'HORIZONTAL';
  frame.primaryAxisSizingMode = 'FIXED';
  frame.counterAxisSizingMode = 'FIXED';
  frame.primaryAxisAlignItems = 'SPACE_BETWEEN';
  frame.counterAxisAlignItems = 'CENTER';
  frame.resize(Math.max(bar.rect.w, kMinNodeSize), Math.max(bar.rect.h, kMinNodeSize));
  // Float noise must not become a negative padding, which Figma refuses.
  frame.paddingLeft = Math.max(lead.box.x, 0);
  frame.paddingRight = Math.max(bar.rect.w - (trail.box.x + trail.box.w), 0);
  frame.paddingTop = Math.max(lead.box.y, 0);
  frame.paddingBottom = Math.max(bar.rect.h - (lead.box.y + lead.box.h), 0);
  pinAbsolute(screen, frame, bar.rect.x, bar.rect.y, { horizontal: 'STRETCH', vertical: 'MIN' });

  // The screen's fill, so the child's overflow cannot show through the bar.
  const background = figma.createRectangle();
  background.name = 'Background';
  background.resize(Math.max(bar.rect.w, kMinNodeSize), Math.max(bar.rect.h, kMinNodeSize));
  fillData(background, lk, colorData(f.backgroundColor));
  pinAbsolute(frame, background, 0, 0, kStretch);

  const ink: StatusBarInk = { style, scale: bar.scale };
  const groupFrame = (name: string, group: StatusBarGroup): FrameNode => {
    const row = autoFrame(name, 'HORIZONTAL');
    row.counterAxisAlignItems = 'CENTER';
    if (wings) {
      row.primaryAxisSizingMode = 'FIXED';
      row.counterAxisSizingMode = 'FIXED';
      row.primaryAxisAlignItems = rowAlignment(group.alignment);
      row.resize(Math.max(group.box.w, kMinNodeSize), Math.max(group.box.h, kMinNodeSize));
    }
    frame.appendChild(row);
    statusBarRow(row, lk, group.items, ink);
    return row;
  };
  groupFrame(wings ? 'Time' : 'Leading Accessories', lead);
  groupFrame(wings ? 'Levels' : 'Trailing Accessories', trail);
  return frame;
}

// The home indicator: a bar `gestureBarOffset` above the screen's bottom edge,
// centred, in an area along the bottom as tall as the pose's bottom inset. No
// background — the screen's own shows through.
function drawHomeIndicator(screen: FrameNode, lk: VarLookup, g: DeviceGeometry): FrameNode {
  const f = MOCKUP_DEVICE.fields;
  const area = g.gestureBarArea;
  const frame = figma.createFrame();
  frame.name = 'HomeIndicator';
  frame.fills = [];
  frame.clipsContent = false;
  frame.layoutMode = 'VERTICAL';
  frame.primaryAxisSizingMode = 'FIXED';
  frame.counterAxisSizingMode = 'FIXED';
  frame.primaryAxisAlignItems = 'MAX';
  frame.counterAxisAlignItems = 'CENTER';
  frame.resize(Math.max(area.w, kMinNodeSize), Math.max(area.h, kMinNodeSize));
  frame.paddingBottom = Math.max(g.screenHeight - (g.gestureBar.y + g.gestureBar.h), 0);
  pinAbsolute(screen, frame, area.x, area.y, { horizontal: 'STRETCH', vertical: 'MAX' });

  const bar = figma.createRectangle();
  bar.name = 'Bar';
  bar.resize(Math.max(g.gestureBar.w, kMinNodeSize), Math.max(g.gestureBar.h, kMinNodeSize));
  bar.cornerRadius = g.gestureBarRadius;
  fillData(bar, lk, colorData(f.gestureBarColor));
  frame.appendChild(bar);
  return frame;
}

// The camera set — camera, lens ring, core, glint — under one parent in the
// space the placement names: the screen when the camera is cut out of it, the
// bezel box when it sits in the bezel strip. Returns every node, for the
// `Show camera` binding.
function drawCameraSet(host: FrameNode, lk: VarLookup, g: DeviceGeometry): SceneNode[] {
  const f = MOCKUP_DEVICE.fields;
  // A pill on the top edge holds to it and the middle across; one standing on
  // the left edge holds to that and the middle down.
  const pin: Constraints =
    g.cameraEdge === 'left'
      ? { horizontal: 'MIN', vertical: 'CENTER' }
      : { horizontal: 'CENTER', vertical: 'MIN' };
  const nodes: SceneNode[] = [];
  nodes.push(
    mockupDevicePart(host, lk, 'camera', g.camera, colorData(g.cameraIsLens ? f.lensColor : f.cutoutColor), pin),
  );
  if (g.lens != null) {
    nodes.push(mockupDevicePart(host, lk, 'lens', g.lens, colorData(f.lensColor), pin));
  }
  // The core is a radial gradient when the style leaves the cut-out colour
  // unstated (`resolveCoreGradient`); the builder draws the defaults, which do.
  // `cutoutColor` is the solid it falls back to, and fills the camera above
  // when that cut-out holds a ring.
  const core = devicePart(host, 'core', g.core, pin);
  core.fills = [gradientPaint(f.coreGradient, { lk })];
  nodes.push(core);
  const glint = figma.createEllipse();
  glint.name = 'lens highlight';
  glint.resize(Math.max(g.lensHighlight.w, kMinNodeSize), Math.max(g.lensHighlight.h, kMinNodeSize));
  // The glint is white at full strength — the paint carries it, with the node
  // at full strength.
  fillDataOnPaint(glint, lk, colorData(f.lensHighlightColor));
  pinAbsolute(host, glint, g.lensHighlight.x, g.lensHighlight.y, pin);
  nodes.push(glint);
  return nodes;
}

// One flat hardware part — a rounded box at an absolute rectangle, painted a
// solid colour.
function mockupDevicePart(
  host: FrameNode | ComponentNode,
  lk: VarLookup,
  name: string,
  r: DeviceRect,
  fill: ColorData | null,
  constraints: Constraints,
): RectangleNode {
  const part = devicePart(host, name, r, constraints);
  fillData(part, lk, fill);
  return part;
}

// A hardware button: the base colour, a gloss along its length and a shade
// across its thickness, bottom to top, each pointed for the edge the button sits
// on. The base is the copy's solid; the gloss and the shade are translucent
// white and black laid over it, the same in every mode.
function paintButton(part: RectangleNode, lk: VarLookup, edge: DeviceEdge): void {
  const f = MOCKUP_DEVICE.fields;
  const base = colorData(f.buttonColor);
  if (base == null) throw new Error('MockupDevice: buttonColor states no colour.');
  part.fills = [
    colorPaint(lk, base, part),
    gradientPaint(buttonLengthGradient(f.buttonLengthGradient, edge)),
    gradientPaint(buttonDepthGradient(f.buttonDepthColor, edge)),
  ];
  part.strokes = [];
}

// What each `Show …` flag hides inside one member, collected while it is drawn
// and bound once the set exists.
interface DeviceToggles {
  camera: SceneNode[];
  statusBar: SceneNode[];
  gestureBar: SceneNode[];
}

// The names of the three safe-area spacers, one per thing that reserves an edge.
const kSafeAreaName: Record<SafeAreaFlag, string> = {
  camera: 'camera safe area',
  statusBar: 'status bar safe area',
  gestureBar: 'gesture safe area',
};

// The order a band stacks its spacers in: the operating system's chrome first,
// then the hardware.
const kSafeAreaOrder: readonly SafeAreaFlag[] = ['statusBar', 'camera', 'gestureBar'];

// One edge's reservation, as spacers bound to the flag that releases them.
//
// `CoreMockupDeviceLayout.safeAreaInsets` states an edge as the DEEPEST of the
// things that reserve it, each released by its own flag — the phone's top is
// `max(status bar, camera)`. A Figma spacer is bound to one boolean, and two
// spacers in a column would SUM. So an edge with two sources stacks them in one
// auto-layout container whose spacing is NEGATIVE by the smaller of the two:
// hidden children leave the flow, so the spacing applies only when both are
// shown, and the container is as deep as
//
//   one shown  → that one's inset
//   both shown → a + b − min(a, b) = max(a, b)
//   none shown → 0
//
// exactly Core's fold, in all four flag states. A spacing is one number, so the
// trick holds for two sources and no more — a third source on an edge has to
// throw rather than draw a sum.
function drawSafeAreaBand(
  parent: FrameNode,
  toggles: DeviceToggles,
  g: DeviceGeometry,
  side: SafeAreaSide,
  sources: readonly SafeAreaSource[],
): void {
  if (side === 'right') {
    throw new Error(
      'MockupDevice: a source reserves the screen\'s right edge — `CoreMockupDeviceLayout.safeAreaInsets` ' +
        'states one now, and this builder has no spacer drawn for it.',
    );
  }
  if (sources.length > 2) {
    throw new Error(
      `MockupDevice: ${sources.length} sources reserve the ${side} edge. One auto-layout spacing ` +
        'is exact for two (max = a + b − min); a third needs another construction.',
    );
  }
  // A band across the screen reserves height; one down its side reserves width.
  const across = side === 'top' || side === 'bottom';
  const ordered = [...sources].sort(
    (x, y) => kSafeAreaOrder.indexOf(x.flag) - kSafeAreaOrder.indexOf(y.flag),
  );
  const spacer = (s: SafeAreaSource): FrameNode => {
    const node = autoFrame(kSafeAreaName[s.flag], 'VERTICAL');
    node.resize(
      Math.max(across ? g.screenWidth : s.inset, kMinNodeSize),
      Math.max(across ? s.inset : g.screenHeight, kMinNodeSize),
    );
    toggles[s.flag].push(node);
    return node;
  };
  // The inset axis is fixed; the other shares what its parent gives.
  const size = (node: FrameNode): void => {
    node.layoutSizingHorizontal = across ? 'FILL' : 'FIXED';
    node.layoutSizingVertical = across ? 'FIXED' : 'FILL';
  };
  if (ordered.length === 1) {
    const node = spacer(ordered[0]);
    parent.appendChild(node);
    size(node);
    return;
  }
  // Stacked ALONG the inset axis (a column for the top, a row for the left), and
  // hugging it, so the container is as deep as what is left in the flow.
  const container = autoFrame(`${side} safe area`, across ? 'VERTICAL' : 'HORIZONTAL');
  container.itemSpacing = -Math.min(ordered[0].inset, ordered[1].inset);
  parent.appendChild(container);
  container.layoutSizingHorizontal = across ? 'FILL' : 'HUG';
  container.layoutSizingVertical = across ? 'HUG' : 'FILL';
  for (const s of ordered) {
    const node = spacer(s);
    container.appendChild(node);
    size(node);
  }
}

function buildMockupDevice(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = MOCKUP_DEVICE.fields;
  const devices = Object.entries(MOCKUP_DEVICE.variants.defaultsByDevice);
  // The finish is a third axis. Its members are `CoreMockupDeviceFinish`, read
  // off the export's `axes.other` the way the turn is, and each one's row is
  // `variants.defaultsByFinish[finish]` — what that finish restates over the
  // per-device row (`realistic` is the empty row, so it draws the picture the
  // set has always drawn).
  const finishNames =
    COMPONENTS.mockup.axes.other.find((e) => e.enum === 'CoreMockupDeviceFinish')?.members ?? [];
  if (finishNames.length === 0) {
    throw new Error(
      'MockupDevice: CoreMockupDeviceFinish is missing from components.json ' +
        '(components.mockup.axes.other) — re-run `export:figma-components`.',
    );
  }
  const finishRows = MOCKUP_DEVICE.variants.defaultsByFinish as Readonly<
    Record<string, Readonly<Record<string, unknown>>>
  >;
  const finishes: [string, Readonly<Record<string, unknown>>][] = finishNames.map((finish) => {
    const row = finishRows[finish];
    if (row == null) {
      throw new Error(`MockupDevice: finish "${finish}" has no row in variants.defaultsByFinish.`);
    }
    if (kFinishPose[finish] == null) {
      throw new Error(`MockupDevice: no pose for finish "${finish}" — add it to kFinishPose.`);
    }
    return [finish, row];
  });
  // The turn is a second axis, and its members come from the enum rather
  // than a literal here — `CoreMockupOrientation` has no per-orientation
  // defaults map to iterate (a turned device is the same hardware), so the
  // export records it under the directory group's `axes.other`.
  const orientations =
    COMPONENTS.mockup.axes.other.find((e) => e.enum === 'CoreMockupOrientation')?.members ?? [];
  if (orientations.length === 0) {
    throw new Error(
      'MockupDevice: CoreMockupOrientation is missing from components.json ' +
        '(components.mockup.axes.other) — re-run `export:figma-components`.',
    );
  }
  const combos = devices.flatMap(([name, d]) =>
    orientations.flatMap((orientation) =>
      finishes.map(([finish, finishRow]) => ({ name, d, orientation, finish, finishRow })),
    ),
  );
  const memberName = (name: string, orientation: string, finish: string): string =>
    `Device=${name}, Orientation=${orientation}, Finish=${finish}`;
  const members = combos.map(({ name, orientation, finish }) => memberName(name, orientation, finish));
  // #4034 (C2) — this was the loose `MockupPhone` COMPONENT (renamed in place
  // by `SET_RENAMES` before this runs). It drew the upright phone, so it is
  // adopted as that member and its key — and every instance of it — survives
  // becoming a set. The finish axis keeps the picture it drew: `realistic`,
  // the first row of `defaultsByFinish`.
  const mount = mountSet(page, 'MockupDevice', members, {
    adoptLooseAs: memberName('phone', 'portrait', finishes[0][0]),
  });
  const children: InstanceNode[] = [];
  const toggles: DeviceToggles = { camera: [], statusBar: [], gestureBar: [] };
  for (const { name, d: deviceRow, orientation, finish, finishRow } of combos) {
    const c = mount.getOrCreate(memberName(name, orientation, finish));
    // The per-device row with the finish laid over it — the order of the
    // widget's merge chain (`defaultsByDevice` → `defaultsByFinish`). Keys the
    // finish also reaches in the flat fields (`railColor`, `borderWidth`, …)
    // are read through `stated`.
    const d = { ...deviceRow, ...finishRow } as typeof deviceRow;
    const stated = <T>(key: string, base: T): T => (finishRow[key] as T | undefined) ?? base;
    const pose = kFinishPose[finish];
    const width = pose.width(name, orientation);
    if (width == null) {
      throw new Error(
        `MockupDevice: no preview width for device "${name}" turned ` +
          `"${orientation}" in the "${finish}" finish — add it to kDevicePreviewWidth / kFinishPose.`,
      );
    }
    const g = mockupDeviceGeometry(
      mockupDeviceSettings({ device: name, orientation, width, d: deviceRow, finish: finishRow }),
    );

    // The cell is a plain box at the body's size. Nothing on it clips: the
    // buttons sit past its edge the way they sit past the widget's body.
    c.layoutMode = 'NONE';
    c.fills = [];
    c.clipsContent = false;
    c.resize(width, g.height);

    // Buttons first, so the body paints over the part of each slab that
    // tucks behind it — the widget's `Stacks` order.
    // A device that states a zero length has no such button: no part is drawn
    // for it rather than a zero-sized one (`hasPowerButton` · `hasVolumeButton`).
    if (g.hasPowerButton) {
      const power = devicePart(c, 'power button', g.power, edgeConstraints(g.powerEdge, true));
      paintButton(power, lk, g.powerEdge);
    }
    if (g.hasVolumeButton) {
      const volumeUp = devicePart(c, 'volume up', g.volumeUp, edgeConstraints(g.volumeEdge, false));
      paintButton(volumeUp, lk, g.volumeEdge);
    }
    if (g.volumeDown != null) {
      const volumeDown = devicePart(c, 'volume down', g.volumeDown, edgeConstraints(g.volumeEdge, false));
      paintButton(volumeDown, lk, g.volumeEdge);
    }

    // ── body ── `railColor` is the solid a style that states it would paint
    // (`resolveBodyGradient`); the defaults state the gradient, so it is
    // forwarded as the primitive receives it — and wins.
    const body = instanceOf(page, 'OutlinedContainer');
    body.name = 'OutlinedContainer';
    setInstanceBoolNamed(body, 'Show child', false);
    body.strokes = [];
    // A finish that states a solid body (`railColor`) without a gradient of its
    // own is a solid — the gradient is only the body when nothing stated one
    // (`resolveBodyGradient`). The border is the rim line; a zero width draws no
    // line, whatever colour it states.
    const bodyGradient = (finishRow.railGradient as typeof f.railGradient | undefined) ??
      ('railColor' in finishRow ? null : f.railGradient);
    const borderWidth = stated('borderWidth', f.borderWidth);
    applyForwardedPanelStyle(body, lk, {
      backgroundColor: colorData(stated('railColor', f.railColor)),
      backgroundGradient: bodyGradient,
      borderColor: dimVal(borderWidth) > 0 ? colorData(stated('borderColor', f.borderColor)) : null,
      borderWidth,
      borderRadius: d.borderRadius,
    });
    // The nested slot's cast — `CoreMockupDeviceStyle.defaultBodyShadow` by
    // default (v1's two layers, pinned), in the black the slot states. Black
    // in every colour mode, so no colour token binds; and the stack is not a
    // step of the shadow scale, so no `Semantic/ Surface` row binds either —
    // the layers are drawn as the numbers they are, as Web writes them.
    const containerStyle = (finishRow.containerStyle as typeof f.containerStyle | undefined) ?? f.containerStyle;
    setShadow(
      body,
      containerStyle.boxShadow,
      lk,
      colorData(containerStyle.shadowBaseColor),
    );
    // The body casts, so it takes the rim its flat main does not carry — the
    // composed container keys it on the same stack on both platforms. A finish
    // that states no cast (`boxShadow` with no layers) casts nothing, so no rim.
    setSurfaceRim(body, lk, 'content', containerStyle.boxShadow.layers.length > 0);
    const bodyPin = pinAbsolute(c, body, 0, 0, kStretch);

    // ── rim ── two hairlines over the body, inset top and bottom only, with
    // the body's own corners.
    // A finish that states a zero width draws no stroke, so no part either.
    if (dimVal(stated('rimHighlightWidth', f.rimHighlightWidth)) > 0) {
      const highlight = devicePart(c, 'rim highlight', g.rimHighlight, kStretch);
      bindRadiusN(highlight, lk, d.borderRadius.topLeft);
      // The highlight is white at full strength — the stroke paint carries it,
      // with the node at full strength.
      paintStroke(highlight, lk, colorData(f.rimHighlightColor), dimVal(stated('rimHighlightWidth', f.rimHighlightWidth)), 'INSIDE', 'paint');
    }
    if (dimVal(stated('rimGlowWidth', f.rimGlowWidth)) > 0) {
      const glow = devicePart(c, 'rim glow', g.rimGlow, kStretch);
      bindRadiusN(glow, lk, d.borderRadius.topLeft);
      // The ramp's opacity is the PAINT's — half the whole stroke, not folded into
      // its stops — and the blur softens that one stroke.
      glow.strokes = [gradientPaint(f.rimGlowGradient, { opacity: f.rimGlowOpacity })];
      glow.strokeWeight = dimVal(stated('rimGlowWidth', f.rimGlowWidth));
      glow.strokeAlign = 'INSIDE';
      glow.effects = [{ type: 'LAYER_BLUR', blurType: 'NORMAL', radius: dimVal(f.rimGlowBlur), visible: true }];
    }

    // ── antenna bands ── the gaps in the rail's metal; phone only. The band's
    // strength is the PAINT's — the node stays at full strength, the way the
    // design states it.
    for (const band of g.antennaBands) {
      const part = devicePart(c, 'antenna band', band.rect, bandConstraints(band), 0);
      assignPaints(part, 'fills', [gradientPaint(f.antennaGradient, { lk, opacity: f.antennaOpacity })]);
    }

    // ── bezel ── inside the rail, concentric with the body: black, outlined
    // OUTSIDE (the line lands in the rail ring) and lit from inside.
    const bezel = figma.createFrame();
    bezel.name = 'bezel';
    bezel.layoutMode = 'NONE';
    bezel.clipsContent = false;
    bezel.resize(Math.max(g.bezelBox.w, kMinNodeSize), Math.max(g.bezelBox.h, kMinNodeSize));
    bezel.cornerRadius = g.bezelRadius;
    fillData(bezel, lk, colorData(stated('bezelColor', f.bezelColor)));
    // A finish that states a zero line draws none, and one that states no blur
    // and no spread has no inner shadow to lay (a zero-sized one is the node a
    // finish with no glow must not carry).
    if (dimVal(stated('bezelBorderWidth', f.bezelBorderWidth)) > 0) {
      paintStroke(bezel, lk, colorData(f.bezelBorderColor), dimVal(stated('bezelBorderWidth', f.bezelBorderWidth)), 'OUTSIDE');
    }
    if (dimVal(stated('bezelInnerShadowBlur', f.bezelInnerShadowBlur)) > 0 || dimVal(stated('bezelInnerShadowSpread', f.bezelInnerShadowSpread)) > 0) {
      setShadow(
        bezel,
        {
          layers: [
            {
              x: 0,
              y: 0,
              blur: dimVal(stated('bezelInnerShadowBlur', f.bezelInnerShadowBlur)),
              spread: dimVal(stated('bezelInnerShadowSpread', f.bezelInnerShadowSpread)),
              opacity: 1,
              inset: true,
            },
          ],
        },
        lk,
        colorData(f.bezelInnerShadowColor),
      );
    }
    pinAbsolute(c, bezel, g.bezelBox.x, g.bezelBox.y, kStretch);

    // ── screen ── inset content viewport + the system chrome and hardware over it.
    const screen = figma.createFrame();
    screen.name = 'screen';
    screen.layoutMode = 'VERTICAL';
    screen.primaryAxisSizingMode = 'FIXED';
    screen.counterAxisSizingMode = 'FIXED';
    screen.primaryAxisAlignItems = 'MIN';
    screen.counterAxisAlignItems = 'CENTER';
    screen.clipsContent = true;
    screen.resize(Math.max(g.screenWidth, kMinNodeSize), Math.max(g.screenHeight, kMinNodeSize));
    screen.cornerRadius = g.screenRadius;
    fillData(screen, lk, colorData(f.backgroundColor));
    pinAbsolute(bezel, screen, g.screenBox.x - g.bezelBox.x, g.screenBox.y - g.bezelBox.y, kStretch);

    // The safe area — what the camera, the status bar and the home indicator
    // each reserve, spacers in the screen's flow that leave it when their own
    // `Show …` is off. Derived (`safeAreaSources`), not authored.
    // A finish that draws no OS chrome (`kFinishPose`) reserves nothing: the
    // three flags default off for it, and a reservation is released by its flag.
    const sources = pose.osChrome ? safeAreaSources(g).filter((s) => s.inset > 0) : [];
    const on = (side: SafeAreaSide): SafeAreaSource[] => sources.filter((s) => s.side === side);
    // A turned phone's camera stands on the screen's left edge, so the whole
    // column of content sits to the right of a left spacer, in a row. The row
    // exists only for a member whose layout states a left inset.
    let column: FrameNode = screen;
    if (on('left').length > 0) {
      const row = autoFrame('safe area row', 'HORIZONTAL');
      screen.appendChild(row);
      row.layoutSizingHorizontal = 'FILL';
      row.layoutSizingVertical = 'FILL';
      drawSafeAreaBand(row, toggles, g, 'left', on('left'));
      column = autoFrame('safe area column', 'VERTICAL');
      row.appendChild(column);
      column.layoutSizingHorizontal = 'FILL';
      column.layoutSizingVertical = 'FILL';
    }
    if (on('right').length > 0) drawSafeAreaBand(column, toggles, g, 'right', on('right'));
    if (on('top').length > 0) drawSafeAreaBand(column, toggles, g, 'top', on('top'));
    const content = autoFrame('safe content', 'VERTICAL');
    content.primaryAxisAlignItems = 'CENTER';
    content.counterAxisAlignItems = 'CENTER';
    column.appendChild(content);
    content.layoutSizingHorizontal = 'FILL';
    content.layoutSizingVertical = 'FILL';
    // `child` is a required `W` — the app screen the caller hands the frame,
    // any widget — so it is an instance of the slot stand-in, and the `Child`
    // INSTANCE_SWAP below is what puts a real screen there. It was a TEXT node
    // reading "App": the words were editable and nothing could be placed, so a
    // device frame could only ever show a caption. It fills the safe area, which
    // is what the widget gives its child.
    //
    // It shows the example app screen rather than the stand-in (#6473): a
    // device frame around a dashed box reads as empty. The example is drawn at
    // one screen's size; FILL grows it with each device and the screen clips
    // it on a smaller one.
    const child = exampleInstance(page, kMockupDeviceExample, 'child');
    content.appendChild(child);
    child.layoutSizingHorizontal = 'FILL';
    child.layoutSizingVertical = 'FILL';
    children.push(child);
    if (on('bottom').length > 0) drawSafeAreaBand(column, toggles, g, 'bottom', on('bottom'));

    // ── status bar ── over the child, behind the camera: the phone's pill sits
    // inside the bar's rectangle. A phone on its side draws none.
    if (pose.osChrome && g.statusBar != null) {
      toggles.statusBar.push(drawStatusBar(screen, lk, g.statusBar, textStyleData(d.statusBarTextStyle)));
    }
    // ── camera ── the phone's is cut out of the screen, the tablet's sits in
    // the bezel strip above it.
    if (pose.osChrome) {
      toggles.camera.push(...drawCameraSet(g.cameraPlacement === 'screen' ? screen : bezel, lk, g));
      toggles.gestureBar.push(drawHomeIndicator(screen, lk, g));
    }

    sizePin(bodyPin, width, g.height);
  }
  const set = mount.finish();
  // A document generated while `Child` was the TEXT stand-in still declares
  // that one, and Figma holds one property per name — so it goes first
  // (logged), then the swap takes the slot's name.
  freePropName(set, 'Child', 'INSTANCE_SWAP');
  // The swap defaults to the example, taking over from the stand-in once; a
  // designer's own pick stays.
  const childProp = defineProp(
    set,
    'Child',
    'INSTANCE_SWAP',
    exampleSwapDefault(page, kMockupDeviceExample, slotStandInDefault(page, 'rectangular')),
  );
  for (const child of children) bindSwapProp(child, childProp);
  const cameraProp = defineProp(set, 'Show camera', 'BOOLEAN', true);
  for (const node of toggles.camera) bindVisibleProp(node, cameraProp);
  const gestureBarProp = defineProp(set, 'Show gesture bar', 'BOOLEAN', true);
  for (const node of toggles.gestureBar) bindVisibleProp(node, gestureBarProp);
  const statusBarProp = defineProp(set, 'Show status bar', 'BOOLEAN', true);
  for (const node of toggles.statusBar) bindVisibleProp(node, statusBarProp);
  return set;
}

// ─── Sortable ────────────────────────────────────────────────────────────────

// Data-driven from coui_core SORTABLE: itemSpacing (row↔row gap), the row's
// fill (`itemBackgroundColor` · `disabledItemBackgroundColor`), border
// (`itemBorderColor` · `disabledItemBorderColor` at `itemBorderWidth`), corner
// (`itemBorderRadius`), padding (`itemPadding`, start 12 · end 8 · none above or
// below) and floor height (`itemMinHeight`, the `lg` control row), the grip
// glyph (`iconStyle.size`, colour `handleColor` · `disabledHandleColor`), and the
// label (`itemTextStyle`). The remove glyph's colour is `removeButtonColor` and
// its size `iconStyle.size`.
//
// The drag handle is `Padding(handlePadding) > Icon(gripVertical,
// iconStyle: handleIconStyle)`, so it is two nodes: `handlePadding` needs a
// frame around the glyph before it can land anywhere. `handleColor` is what the
// resolver merges into `handleIconStyle`
// (`sortable_style.dart`: `iconStyle.merge(CoreIconStyle(color: handleColor))`);
// `Resizable` has a field of the same name that `layout.ts` reads, and a shared
// name is not a shared value.
//
// The row's own internal (handle↔label↔remove) gap has no matching field — it is
// the caller's `itemBuilder` layout — and stays a preview literal.
//
// `animationDuration`/`proxyElevation`/`proxyScale` are drag-proxy behavior —
// not rendered in a static preview.
//
// ─── What is composed here ─────────────────────────────────────────────────
//
// The remove affordance is `Button(variant: .plain, size: .sm, shape: .square,
// buttonStyle: resolved.removeButtonStyle)` on both platforms, so it is a Button
// INSTANCE here: `defaultRemoveButtonStyle` states the 32 square, the zero
// padding, the `sm` corner, the `onSurfaceSubtle` foreground and the 16 glyph.
// The drag handle is `Padding(handlePadding) > Icon(gripVertical)` — a padded
// glyph with no button box — so it stays a frame around an `Icon` instance.
//
// `Clickable` and `Stacks` are not composed: `Clickable` is an interaction wrapper
// whose canvas box is a focus ring around a placeholder slot, and the outer
// `Stacks(fit: .passthrough)` carries `DragOverlay`, which draws nothing inline.
// The proxy it carries (`proxyElevation` / `proxyScale`) is a drag-time pose.
//
// ─── The set: `Enabled`, by adoption ───────────────────────────────────────
//
// #4037 (C4b) — static→variant-set promotion by ADOPTION. `sortable.axes`
// promotes ONLY `enabled` (CoreSortableStyle has no variant/size/state enum and
// `axes.other` is empty), so the enumeration is two combinations and the loose
// COMPONENT is adopted as `Enabled=true` — the combination the static node
// actually rendered, so its node id and every consuming instance survive the
// promotion instead of being rebuilt under a new key. `Enabled=false` draws the
// disabled tokens, not the enabled ones. Worth
// stating plainly for this one, because a disabled sortable list is a real state
// the widget has (a list you cannot reorder): it wears `disabledItemBackgroundColor`
// · `disabledItemBorderColor` · `disabledHandleColor`, none of them a fade.
//
// This component's `section` folds to Form (`sectionNameOf('sortable')`), not
// the Display its REGISTRY entry literal reads — that literal is only the
// registry-parity guard's extraction anchor and is not consumed for placement
// (see registry.ts), so the two disagreeing is expected, not a bug to fix here.
//
// ─── Why there is no `Hover` axis yet ──────────────────────────────────────
//
// `itemHoverColor` (tertiary @ 50%) is genuine, top-level, row-level chrome
// that differs from `itemBackgroundColor` — the one real state axis in this
// file. The obstacle is no longer the node type: the promotion above already
// made `Sortable` a `ComponentSetNode`, and it made it the way that keeps the
// old node's identity. What stops the axis is that a member's NAME is its
// identity — `kAxisOrder` puts poses after the four schema axes, so declaring
// one turns `Enabled=true` into `Enabled=true, Hover=false`, and every existing
// member is then a name this builder no longer produces. `mountSet.finish()`
// refuses that outright (S-a: it will not delete a variant a rename does not
// explain) unless `src/renames.ts#VARIANT_RENAMES` carries the migration, and
// this file does not own that table. The entry has to land in the same change
// as the axis.
//
// And when it does land, the tint is a LAYER, not a paint: `itemHoverColor` is a
// token at 50%, and a bound Figma paint supplies its own alpha and overwrites
// the paint's — a probe wrote 0.1 and Figma stored 1. So the hovered row's fill
// goes on through `tintLayer`, the same way every other sub-1 token tint in this
// file does, rather than as an opacity on the row's own fill.
function buildSortable(page: PageNode, lk: VarLookup): ComponentSetNode {
  const combos = enumerateAxisCombos(axisSpecsOf(SORTABLE.axes));
  const mount = mountSet(page, 'Sortable', combos, { adoptLooseAs: 'Enabled=true' });
  for (const comboName of combos) {
    const disabled = parseVariantKey(comboName)['Enabled'] === 'false';
    const c = mount.getOrCreate(comboName);
    applyPanelCompChrome(c, 'VERTICAL', lk, { gap: SORTABLE.fields.itemSpacing });
    // g7-preview-only: the list's own width. The widget's rows stretch to the parent and `CoreSortableStyle` has no width field; 300 is wide enough to show handle, label and remove in one row.
    lockWidth(c, 300);
    const itemPad = SORTABLE.fields.itemPadding;
    const itemTextData = textStyleData(SORTABLE.fields.itemTextStyle);
    // `disabledForegroundColor` — a disabled list's item text and remove glyph take
    // their own token rather than a dimmed enabled pair.
    const disabledForeground = colorData(SORTABLE.fields.disabledForegroundColor);
    const itemTextOpts = textLabelOpts(
      lk,
      disabled ? { ...itemTextData, color: disabledForeground } : itemTextData,
    );
    const items = ['커트', '펌', '염색'];
    for (const label of items) {
      const row = panel('row', 'HORIZONTAL', lk, {
        radius: SORTABLE.fields.itemBorderRadius.topLeft,
        // g7-preview-only: the handle↔label↔remove gap (`gap`; the four insets beside it are data). A row's children come from the caller's `itemBuilder(context, index, dragHandle, removeButton)` — the docs example is a `Row` with a 10 spacing (`CoreSpace.space10`) — so this gap belongs to the caller's layout, not to `CoreSortableStyle`.
        pl: itemPad.start, pr: itemPad.end, pt: itemPad.t, pb: itemPad.b, gap: 10,
      });
      // `BoxDecoration(border: Border.all(itemBorderColor | disabledItemBorderColor, itemBorderWidth))`.
      borderData(
        row,
        lk,
        colorData(
          disabled ? SORTABLE.fields.disabledItemBorderColor : SORTABLE.fields.itemBorderColor,
        ),
        dimVal(SORTABLE.fields.itemBorderWidth),
      );
      // Each row is a content surface on both platforms (`surfaceFor(.content)`
      // folded into the row fill on Flutter, the content marker on each row on
      // Web). No rim: a resting row casts nothing, and neither platform rims a
      // surface that casts nothing. The row lifted under the pointer casts and
      // takes the rim on both while it does — a pose this set does not draw.
      applySurfaceMaterial(
        row,
        lk,
        colorData(
          disabled ? SORTABLE.fields.disabledItemBackgroundColor : SORTABLE.fields.itemBackgroundColor,
        ),
        'content',
        { radius: SORTABLE.fields.itemBorderRadius.topLeft },
      );
      row.counterAxisAlignItems = 'CENTER';
      c.appendChild(row);
      row.layoutSizingHorizontal = 'FILL';
      // `constraints: BoxConstraints(minHeight: itemMinHeight)` — the `lg` control row.
      // The preview content never outgrows it, so the row is drawn at the floor, bound
      // to the row a density moves (a document that predates the density rows keeps the
      // size step).
      const rowHeight = dimVal(SORTABLE.fields.itemMinHeight);
      row.counterAxisSizingMode = 'FIXED';
      row.resize(row.width, rowHeight);
      const rowHeightVar = lk.controlHeightOrNull(rowHeight) ?? lk.sizeOrNull(rowHeight);
      if (rowHeightVar) row.setBoundVariable('height', rowHeightVar);
      // `handleStyle?.padding ?? handlePadding` — the nested slot wins, which is what
      // both resolvers do. Reading the flat field alone meant an override placed in
      // the slot the widget prefers landed nowhere.
      const handlePad = SORTABLE.fields.handleStyle.padding ?? SORTABLE.fields.handlePadding;
      const handle = panel('handle', 'HORIZONTAL', lk, {
        pl: handlePad.l, pr: handlePad.r, pt: handlePad.t, pb: handlePad.b,
      });
      handle.counterAxisAlignItems = 'CENTER';
      // No corner: the handle is not a `Button` on either platform — both
      // resolvers read `handleStyle` for its inset, colour, motion and ring,
      // and neither paints a `handleStyle.borderRadius` — and the frame has no
      // fill a corner could round.
      handle.appendChild(
        makeIcon(
          'grip-vertical',
          lk,
          glyphOpts(
            lk,
            colorData(
              disabled ? SORTABLE.fields.disabledHandleColor : SORTABLE.fields.handleColor,
            ),
            SORTABLE.fields.iconStyle.size,
            'size',
          ),
        ),
      );
      row.appendChild(handle);
      const lbl = makeLabel(label, lk, itemTextOpts);
      row.appendChild(lbl);
      lbl.layoutSizingHorizontal = 'FILL';
      // The remove affordance is `Button(variant: .plain, size: .sm, shape:
      // .square, child: Icon(x))` in the widget, with `removeButtonStyle`
      // forwarded into it — so it is a Button INSTANCE here, not a bare glyph.
      const remove = instanceOf(
        page,
        'Button',
        restingVariant(page, 'Button', { Variant: 'plain', Size: 'sm', Shape: 'square' }),
      );
      remove.name = 'remove';
      row.appendChild(remove);
      // The ✕ is swapped to the step `iconStyle.size` states (16) and painted
      // in `removeButtonColor` (`onSurfaceVariant`) while enabled and in
      // `disabledForegroundColor` once the list is disabled. The colour is the FLAT field, not
      // the slot's foreground: the resolver chains the flat fields under the
      // per-instance `removeButtonStyle`, and at defaults that slot is null. It
      // lands on the GLYPH; the Button's own box keeps the plain variant's
      // transparent surface.
      setSlotIcon(
        remove,
        'Leading',
        iconMainIdAt(page, dimVal(SORTABLE.fields.iconStyle.size)),
        'x',
        glyphPaint(
          lk,
          labelColor(lk, disabled ? disabledForeground : colorData(SORTABLE.fields.removeButtonStyle.foregroundColor)),
        ),
      );
      clearInstanceLabel(remove);
      // The box the widget states, then the corner — the flat `removeButton*`
      // fields carry no default of their own (deprecated since 0.177), so both
      // widgets fall back to `defaultRemoveButtonStyle`, and so does the canvas.
      remove.resize(
        dimVal(SORTABLE.fields.removeButtonStyle.width),
        dimVal(SORTABLE.fields.removeButtonStyle.height),
      );
      bindRadiusN(remove, lk, SORTABLE.fields.removeButtonStyle.borderRadius.topLeft);
      // The forwarded style's own width, bound to its control-size row.
      remove.setBoundVariable(
        'width',
        lk.size(dimVal(SORTABLE.fields.removeButtonStyle.width)),
      );
    }
  }
  const set = mount.finish();
  rowSet(set);
  return set;
}

// ─── Registry ────────────────────────────────────────────────────────────────

export const DISPLAY_MEDIA: RegistryEntry[] = [
  { section: 'Display', name: 'NumberTicker', build: buildNumberTicker },
  { section: 'Display', name: 'Countdown', build: buildCountdown },
  { section: 'Display', name: 'Timeline', build: buildTimeline },
  { section: 'Display', name: 'Tracker', build: buildTracker, needs: ['Tooltip'] },
  { section: 'Display', name: 'CardImage', build: buildCardImage, needs: ['Basic', 'OutlinedContainer'] },
  { section: 'Display', name: 'CarouselBanner', build: buildCarouselBanner },
  {
    section: 'Display',
    name: 'Carousel',
    build: buildCarousel,
    needs: [
      'Button',
      'CarouselBanner',
      'DotIndicator',
      'Icon',
      'OutlinedContainer',
    ],
  },
  { section: 'Display', name: 'Chat', build: buildChat, needs: ['Avatar', 'ChatBubble'] },
  { section: 'Display', name: 'Window', build: buildWindow, needs: ['WindowPanel'] },
  { section: 'Display', name: 'CodeDiff', build: buildCodeDiff },
  { section: 'Display', name: 'Diff', build: buildDiff, needs: ['Badge', 'Icon'] },
  { section: 'Display', name: 'HoverGallery', build: buildHoverGallery, needs: ['Icon'] },
  { section: 'Display', name: 'MockupBrowser', build: buildMockupBrowser, needs: ['Button', 'Icon', 'OutlinedContainer'] },
  { section: 'Display', name: 'MockupCode', build: buildMockupCode, needs: ['OutlinedContainer'] },
  {
    section: 'Display',
    name: 'MockupDevice',
    build: buildMockupDevice,
    needs: ['OutlinedContainer', kSlotStandInComponent, kMockupDeviceExample],
  },
  // `Button` as well as `Icon`: the remove affordance is a real Button
  // instance (`buildSortable` composes one at rest). Undeclared, this entry
  // still built — but only because ties in `topoSortRegistry` break on the
  // original REGISTRY index and DISPLAY_MEDIA is concatenated after
  // FORM_BUILDERS, so Sortable happened to land after Button. Reordering the
  // concat, or anything above it, would have moved it ahead and turned a
  // silent ordering accident into a build failure.
  { section: 'Display', name: 'Sortable', build: buildSortable, needs: ['Icon', 'Button'] },
];
