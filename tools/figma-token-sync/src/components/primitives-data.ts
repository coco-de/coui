/// <reference types="@figma/plugin-typings" />

// Display-column builders for seven coui_core components that had no Figma
// node at all (`figma_registry_uncovered_baseline.txt`): ChatBubble ·
// RadialProgress · AvatarGroup · AvatarBadge · TabPane · Validated · Form.
//
// Every chrome / dimensional value below is read from `components.json`
// (schema v2) through `data.ts` + `compat/v1.ts`, the same way display.ts's
// converted builders do — no hardcoded colour, radius, spacing, stroke or
// font size. The handful of numbers this file *does* name are preview-only
// (how many demo rows to draw, which example progress fraction to sweep) and
// are declared as named constants below with the reason each one has no Style
// field behind it. That is the same judgment display-data.ts's
// `LOADING_BAR_FILL_RATIO` records, not a shortcut around it.
//
// Three of these builders compose other REGISTRY components rather than
// redrawing them (`needs:` on the entry): AvatarGroup instantiates `Avatar`,
// Validated instantiates `TextField` + `ValidatorHint`, Form instantiates
// `FormField`. That mirrors what the widgets do — `Validated`'s message *is* a
// `ValidatorHint`, `Form`'s rows *are* `FormField`s — so the Figma tree
// corresponds to the widget tree node-for-node instead of restating a child's
// chrome in the parent.
//
// Which variant of a composed child gets instantiated is asked for by AXIS
// (`bestVariantName(page, 'X', { Variant: 'Error' })`), never spelled as a
// full variant name. A spelled name is an exact-match lookup, so the day a
// child set grows an axis — TextField gaining `Disabled` alongside
// `Variant`/`Size` — every literal naming it stops resolving and `instanceOf`
// throws, failing the parent's entry over a child's refactor and leaving the
// parent half-drawn on the canvas until the next run blanks it.
// Scoring degrades to "closest match" instead.
//
// ─── Composition slots → Figma component properties ──────────────────────────
//
// A contract slot typed `W` / `W?` takes ANY widget, so the Figma component has
// to take any component in the same place. Without a property, the glyph a
// builder happened to draw IS the slot — the canvas looks finished and says
// something the contract never said.
//
// Each slot below is bound, not just declared. A property with nothing pointing
// at it appears in the panel and changes nothing when a designer edits it,
// which is the same "looks finished" failure one layer up.
//
// Which property a slot gets follows what the demo puts in it:
//   · an instance of another component → INSTANCE_SWAP, defaulted to that
//     component's main id (`iconMainId` for the `Icon` set, `mainIdOf` below
//     for the rest).
//   · a text node → TEXT. Not INSTANCE_SWAP: swapping a label would want a
//     `Text` component in the REGISTRY and that was decided against, so TEXT is
//     the ceiling and a designer edits the words.
//   · additionally `W?` (the widget's null is a real rendering) → a BOOLEAN on
//     the slot's region, so it can be turned off.
//
// The BOOLEAN and the swap/text cannot share a node: `componentPropertyReferences`
// is assigned wholesale by each bind helper, so the second call drops the first.
// Hence the holder pattern — an empty hugging frame carries the BOOLEAN and its
// single child carries the swap. No padding, fill or gap, so it costs nothing.
//
// Two ordering rules, both of which cost a component when broken:
//   · bind only AFTER the node is inside the component. Figma rejects a
//     reference on a detached node, the throw is not rolled back, and the
//     entry is reported as failed with a half-drawn component on the page.
//   · for a variant set, the owner is the set, which only exists after
//     `mountSet().finish()` — so the nodes are collected in the loop and bound
//     once the set is in hand.

import {
  mainComponentIdOf as mainIdOf,
  ColorData,
  PadData,
  RegistryEntry,
  VarLookup,
  applySurfaceMaterial,
  applyPanelCompChrome,
  autoFrame,
  bestVariantName,
  bindPad,
  bindRadiusN,
  bindSize,
  bindSurfaceShare,
  bindSwapProp,
  bindTextProp,
  bindVisibleProp,
  borderData,
  composeCountBadge,
  defineProp,
  exposeAll,
  setInstanceTextNamed,
  fillData,
  applyLetterSpacing,
  glyphOpts,
  iconMainId,
  iconSwapDefault,
  instanceOf,
  lockWidth,
  makeIcon,
  makeLabel,
  mint,
  mountSet,
  panel,
  paintsFill,
  pinInFlow,
  propertyOwner,
  textLabelOpts,
  typographyColorOpts,
  vStackSet,
  weightStyle,
  kAvatarRest,
} from '../helpers';
import {
  Color,
  Dim,
  colorData,
  dimVal,
  mergeTextStyleData,
  optField,
  textStyleData,
} from '../compat/v1';
import { COMPONENTS } from '../data';
import { applyValidatorHintStyle } from '../validator-hint-composition';
import { composeVariantName, enumerateAxisAssignments } from '../axis-combos';

const CHAT_BUBBLE = COMPONENTS.chat_bubble;
const RADIAL_PROGRESS = COMPONENTS.radial_progress;
const AVATAR_GROUP = COMPONENTS.avatar_group;
const AVATAR_BADGE = COMPONENTS.avatar_badge;
const TAB_PANE = COMPONENTS.tab_pane;
const VALIDATED = COMPONENTS.validated;
const FORM = COMPONENTS.form;

// ─── Preview-only constants (no Style field behind them) ─────────────────────
//
// Each of these stands for a *widget parameter*, not a design token: the caller
// supplies it at the use site and `CoreXxxStyle` never carries a default for
// it, so `components.json` has nothing to read. They are named (not inlined)
// so the difference between "this number is a design decision the plugin
// should be sourcing" and "this number is how many demo rows to draw" stays
// legible — the same reason display-data.ts names `LOADING_BAR_FILL_RATIO`.

// `RadialProgress.value` — the caller's progress reading. 0.75 sweeps three
// quarters so the arc, the track behind it and the centred value label are all
// visible at once.
const RADIAL_PREVIEW_VALUE = 0.75;

// `AvatarGroup.children.length`. Three is the smallest count that shows two
// overlaps, which is what the component is for.
const AVATAR_GROUP_PREVIEW_COUNT = 3;

// `Form.children.length`. Two rows is the smallest count where `rowSpacing`
// appears as actual space rather than as an unused field.
const FORM_PREVIEW_ROWS = 2;

// `AvatarBadge.child` — the caller's centred widget, and the caller's colour
// too. `CoreAvatarBadgeStyle` carries `backgroundColor` and `size` and nothing
// about what sits on top, because the widget just `Center`s whatever arrives
// and the child brings its own paint. So the placeholder needs a glyph and a
// colour chosen here; the colour that reads on `backgroundColor`'s default
// (`primary`) is its semantic counterpart, and a check mark is the status mark
// the widget's own doc names first ("online status, notification counts").
//
// Its size is NOT a choice — it is the badge's own `size`, the largest child
// that fits without overflowing, which also lands the holder at the badge's
// origin with no centring arithmetic to get wrong.
const AVATAR_BADGE_CHILD_GLYPH = 'check';
// One note on the marker below. This literal is invisible to G7 today: the `ColorData`
// spelling `{ color: '<token>' }` is the one colour form `COLOR_PATTERN` does not match
// (it looks for `.sem(` / `fillSem(` / `setBorder(` / `bg:` / `border:`), so the count
// neither reports it nor credits the marker — flagged in `notes` because converting a
// builder to `fillData`/`ColorData`, which is what this file is, moves its remaining
// hand-picked colours out of the count's sight without removing them.
//
// The marker keyword therefore sits on the line DIRECTLY above the literal, which is the
// only placement the mechanism reads (that line or the literal's own). Written out at
// length here rather than there for the same reason: the reason has to fit on the marker
// line to be read, so the argument lives above it and the marker states the claim.
// g7-preview-only: AvatarBadge `child` slot placeholder colour — the widget just `Center`s the caller's widget, which brings its own paint; `CoreAvatarBadgeStyle` states only backgroundColor + size
const AVATAR_BADGE_CHILD_COLOR: ColorData = { color: 'on-primary' };

// ─── Shared: the main-component id an INSTANCE_SWAP defaults to ──────────────


// Which variant of each composed child the preview asks for. Not values —
// axis preferences handed to `bestVariantName`, which scores them against the
// child set's actual variants (see the composition note at the top of this
// file for why these are preferences and not spelled variant names).
const AVATAR_MD = { Size: 'md', ...kAvatarRest };
const FORM_FIELD_DEFAULT = { Variant: 'Default' };
const TEXT_FIELD_ERROR_MD = { Variant: 'Error', Size: 'md' };
const VALIDATOR_HINT_ERROR = { Variant: 'error' };

// Demo copy. Slot content, not chrome — a component whose only text is a slot
// still has to render *something* for the box to have a size.
const CHAT_BUBBLE_TEXT = '오늘 점심 뭐 먹을까요?';
const TAB_PANE_TABS = ['Account', 'Password', 'Team'];
// The copy each tab reads, held apart from `TAB_PANE_TABS` (which names the
// layers) so translating the copy does not rename the layer a designer's
// override is keyed on.
const TAB_PANE_TAB_LABELS = ['계정', '비밀번호', '팀'];
const TAB_PANE_CONTENT = '계정 설정을 관리해요.';

// Which demo tab stands in for `CoreTabItem.enabled == false`. A per-item
// widget parameter, like `TAB_PANE_TABS` itself — `CoreTabPaneStyle` carries the
// fade but not which item wears it. Last rather than first because tab 0 is
// already carrying the focused fill, and one tab showing two states at once
// would make neither legible.
//
// OPT-IN, not welded: this tab is hidden at rest and bound to a `Show disabled
// tab` BOOLEAN below. Drawn unconditionally it was a claim the canvas could not
// retract — every placed instance shipped a permanently greyed third tab, a
// picture no docs example and no code block on this page shows, and the widget's
// own default is every tab enabled. Hiding it lands the resting pose on the
// two-tab Account/Password configuration the docs example draws, and makes the
// faded state one checkbox away instead of unreachable. The same shape
// `buildTabs` uses for its extra tabs (navigation.ts).
const TAB_PANE_DISABLED_INDEX = TAB_PANE_TABS.length - 1;
// The count badge is each `TabPaneTab`'s own `Show count` — a badge is a
// per-`CoreTabItem` slot, so it lives on the tab set and a designer turns it on
// for the tab that carries one. The `Badge` pose is `composeCountBadge`'s
// (instance-reach.ts) — shared with `TabItem`, so a count reads the same in a
// `Tabs` bar and a `TabPane` strip, and nothing about it is spelled here.
//
// The only docs example that draws that pose is **Tabs**'
// (`tabs_badge_example.dart`, `Inbox` with a `3`). `TabPane` has no badge
// example on either platform, so `Show count` is a capability this canvas
// offers and the docs never show — an unimplemented doc, not a canvas-only
// feature.

// Stand-ins for the two composition slots — a file glyph before the label
// and a close affordance after it, the editor strip's own pair. Both are
// INSTANCE_SWAP targets, so these are defaults, not the only choice.
const TAB_PANE_LEADING_GLYPH = 'file';
const TAB_PANE_TRAILING_GLYPH = 'x';
// Their size is `slotIconStyle.size` (read per row in `tabPaneChrome`): the
// widget wraps both slots in an ambient `IconTheme` / font-size of that size,
// so an `Icon` handed there takes it rather than the app root's ambient step.

// ─── Shared: painting an SVG-sourced vector ──────────────────────────────────

// Re-points every fill inside a `createNodeFromSvg` frame at `cd`, and clears
// the frame's own background. The SVG arrives with a literal fill (Figma has to
// resolve *something* on import) which would otherwise stay black regardless of
// theme; `icon-nodes.ts#repaintGlyph` does the same for Lucide glyphs but is not
// exported, and this file needs it for one shape that is not an icon.
function paintSvgFills(frame: FrameNode, lk: VarLookup, cd: ColorData | null): void {
  frame.fills = [];
  for (const node of frame.findAll(() => true)) {
    if ('fills' in node) fillData(node, lk, cd);
  }
}

// ─── ChatBubble ──────────────────────────────────────────────────────────────

// Data-driven from coui_core CHAT_BUBBLE: `variants.defaultsByVariant`
// (9 entries — background + foreground per tone, and per variant an optional
// `padding` / `maxWidthFactor` that replace the shared field when stated) +
// `fields` (padding / borderRadius / textStyle / tailWidth / tailHeight /
// tailTipRadius).
//
// The set has two axes, `Variant` and `Tail` (`none` | `start` | `end`). `Tail`
// is the contract's `tail` flag plus the side it leaves from: `defaultTail` is
// false, so the resting pose is `Tail=none` — four equal corners and no tail
// node — and `start` / `end` are the two silhouettes a caller gets by asking for
// one. `plain` has no fill, and a tail is that fill carried past the bubble's
// box, so there is nothing to continue: the widget draws none for it however
// `tail` is set, and the set has no `plain` × `start|end` member
// (9 × 3 − 2 = 25).
//
// The tail is drawn, not implied: `_ChatTailPainter` (Flutter) and the Web
// twin's clip path both draw a right triangle sticking sideways out of the
// bubble's corner on the tail edge, with the outward tip rounded by
// `tailTipRadius` via a quadratic arc. Which edge is `tailEdge` (`bottom` by
// default): a `top` tail is the bottom outline reflected across the tail's own
// horizontal centre line, flush with the bubble's top. `tailPath` below is that same path, so the three tail fields
// reach the canvas instead of sitting unused. It is a real vector rather than a
// rotated rectangle because a rectangle would draw a shape the component does
// not have. `end` is the same path mirrored in its own coordinates rather than
// the node flipped, because a flipped node carries a reflected transform that
// reads back as a correct box and renders upside down.
//
// And the corner the tail leaves from is SQUARE — see `bubble`'s per-corner
// binding below for which one and why. A tail is only a tail if the bubble
// gives it an edge to continue.
//
// One geometry fact the data does not carry: the widget insets the tail 1 px
// INTO the bubble (`Position(left: -tailWidth + CoreChatBubbleContract
// .tailEdgeOverlap)`, `chat.dart:339`) so no anti-aliasing seam shows where the
// two fills meet. `tailEdgeOverlap` is a `static const` on the contract
// (`chat_contract.dart:64`), not a `CoreChatBubbleStyle` field, so
// `components.json` has no leaf for it and the tail here sits flush at gap 0
// instead. Recorded rather than typed in as a `-1` this file invented.
//
// `maxWidthFactor` (0.75; 1 for `plain`) is a fraction of the *parent's* max
// width, so a bubble on its own has no cap to draw — the widget settles it
// inside a `LayoutBuilder`, and a component sitting on a Figma page IS the
// unbounded case (`constraints.hasBoundedWidth ? … : double.infinity`). Both
// Figma APIs that could carry a maximum were checked and neither expresses a
// fraction of a parent: `FrameNode.maxWidth` is absolute px, and horizontal
// `constraints: { type: 'SCALE' }` is a fixed proportion rather than a ceiling
// and is refused on an INSTANCE outright (`helpers.ts#pinAbsolute`). The row
// that offers a width — `Chat`'s preview — reads the variant's factor and caps
// the placed bubble itself.
function tailPath(
  w: number,
  h: number,
  r: number,
  mirrored: boolean,
  onTop: boolean,
): string {
  // Where the rounded tip rejoins the hypotenuse — `r` back from the tip along
  // the hypotenuse direction (identical arithmetic to the Flutter painter).
  const hypotenuse = Math.sqrt(w * w + h * h);
  const backX = round3((r * w) / hypotenuse);
  const backY = round3(h - (r * h) / hypotenuse);
  const width = round3(w);
  const height = round3(h);
  const tip = round3(r);
  // The bottom-edge outline, reflected for a tail on the top edge — the
  // painter's `pointUp`.
  const y = (v: number): number => (onTop ? round3(height - v) : v);
  if (mirrored) {
    // `pointEnd: true` — the same outline reflected across the tail's own
    // vertical centre line: the bubble-side edge is the LEFT one and the rounded
    // tip is the bottom-right (top-right on the top edge).
    return (
      `M0 ${y(0)} L${round3(width - backX)} ${y(backY)} Q${width} ${y(height)} ` +
      `${round3(width - tip)} ${y(height)} L0 ${y(height)} Z`
    );
  }
  return (
    `M${width} ${y(0)} L${backX} ${y(backY)} Q0 ${y(height)} ${tip} ${y(height)} ` +
    `L${width} ${y(height)} Z`
  );
}

// `tailEdge` is a choice leaf. A name this side does not know fails the build
// rather than drawing the tail on a guessed edge — a tail on the wrong edge
// still looks like a tail.
function chatTailOnTop(leaf: { readonly choice: string }): boolean {
  if (leaf.choice === 'top') return true;
  if (leaf.choice === 'bottom') return false;
  throw new Error(
    `ChatBubble.tailEdge: unknown CoreChatBubbleTailEdge "${leaf.choice}" — ` +
      'add it to `chatTailOnTop` in primitives-data.ts.',
  );
}

function round3(n: number): number {
  const scale = 1000;
  return Math.round(n * scale) / scale;
}

/** One `chat_bubble.variants.defaultsByVariant` row. `padding` and
 *  `maxWidthFactor` are stated only by a variant that replaces the shared
 *  field (`plain`); the others fall through to `fields`. */
interface ChatBubbleVariantRow {
  backgroundColor: Color;
  foregroundColor: Color;
  padding?: PadData;
  maxWidthFactor?: Dim;
}

/** `Tail` poses, in the order the axis lists them: `none` is the contract's
 *  `defaultTail` (false), so it comes first. */
const kChatTails = ['none', 'start', 'end'] as const;
type ChatTail = (typeof kChatTails)[number];

/** The members the set draws: every variant at `Tail=none`, and the two tailed
 *  poses for every variant that has a fill to continue. */
function chatBubbleMembers(): Array<{ name: string; variant: string; tail: ChatTail }> {
  const rows = CHAT_BUBBLE.variants.defaultsByVariant as Record<string, ChatBubbleVariantRow>;
  const members: Array<{ name: string; variant: string; tail: ChatTail }> = [];
  for (const [variant, row] of Object.entries(rows)) {
    const filled = paintsFill(colorData(row.backgroundColor));
    for (const tail of kChatTails) {
      // A tail is the bubble's fill carried past its box — a variant that paints
      // no fill has none to carry, and the widget draws none for it.
      if (tail !== 'none' && !filled) continue;
      members.push({
        name: composeVariantName([
          ['Variant', variant],
          ['Tail', tail],
        ]),
        variant,
        tail,
      });
    }
  }
  return members;
}

function buildChatBubble(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = CHAT_BUBBLE.fields;
  const bodyStyle = textStyleData(f.textStyle);
  const tailW = dimVal(f.tailWidth);
  const tailH = dimVal(f.tailHeight);
  const tailR = dimVal(f.tailTipRadius);
  const tailOnTop = chatTailOnTop(f.tailEdge);
  const svgFor = (mirrored: boolean): string =>
    `<svg xmlns="http://www.w3.org/2000/svg" width="${tailW}" height="${tailH}" ` +
    `viewBox="0 0 ${tailW} ${tailH}">` +
    `<path d="${tailPath(tailW, tailH, tailR, mirrored, tailOnTop)}" fill="#000000"/></svg>`;
  const rows = CHAT_BUBBLE.variants.defaultsByVariant as Record<string, ChatBubbleVariantRow>;
  const members = chatBubbleMembers();
  const mount = mountSet(
    page,
    'ChatBubble',
    members.map((m) => m.name),
  );
  // Collected for the property pass below — the owner only becomes the set once
  // `finish()` has combined the variants.
  const contents: TextNode[] = [];
  for (const m of members) {
    const v = rows[m.variant];
    const bg = colorData(v.backgroundColor);
    // A variant that paints no fill (`plain`) is a bare run of text: no material
    // layers, no share, no cast, and — above — no tail.
    const filled = paintsFill(bg);
    const comp = mount.getOrCreate(m.name);
    applyPanelCompChrome(comp, 'HORIZONTAL', lk, {});
    // The tail's outer edge is flush with the bubble's edge it sits on.
    comp.counterAxisAlignItems = tailOnTop ? 'MIN' : 'MAX';

    // `start` puts the tail before the bubble (tip on the bottom-left, or the
    // top-left on the top edge), `end` after it — the widget's `pointEnd`.
    const tail = m.tail === 'none' ? null : figma.createNodeFromSvg(svgFor(m.tail === 'end'));
    if (tail != null) {
      tail.name = 'tail';
      paintSvgFills(tail, lk, bg);
      // The same share of the fill the bubble keeps — see the material call
      // below.
      bindSurfaceShare(tail, lk, 'content');
      if (m.tail === 'start') comp.appendChild(tail);
    }

    const bubble = autoFrame('bubble', 'VERTICAL');
    // The variant's own inset replaces the shared one when it states one.
    bindPad(bubble, lk, v.padding ?? f.padding);
    // The corner the tail leaves from is square, so the tail's bubble-side edge
    // continues the bubble's own outline and the two read as one silhouette.
    // The resolver states it directly — `tail ? mergedRadius.copyWith(
    // bottomLeft: isEnd ? null : .zero, bottomRight: isEnd ? .zero : null)`
    // (`chat_style.dart:169`) — daisyUI zeroes `border-end-end-radius` for the
    // same reason. Rounded, a notch opens between bubble and tail and the shape
    // reads as a bubble with a triangle parked beside it.
    //
    // `Tail=start` squares the LEFT corner on the tail edge, `Tail=end` the
    // RIGHT one (the bottom corners by default, the top ones when `tailEdge` is
    // `top`), and `Tail=none` squares nothing — a bubble with no tail has no
    // edge to continue, so its four corners are one radius. (`tailCornerRadius`
    // shapes that corner on a bubble with no pointer; its default is no value —
    // the corner follows `borderRadius` — so the resting pose has nothing to
    // draw for it.)
    //
    // Left unbound at Figma's own 0 rather than bound to `Primitives/radius/0`:
    // the widget says `Radius.zero`, not `CoreRadius.radius0`, and binding the
    // token would put a design-system claim on the node that no CoUI code makes.
    // Same treatment `buildTabPane`'s bottom corners and `Join`'s inner corners
    // (layout.ts) already get.
    //
    // Each corner reads its OWN field instead of fanning `topLeft` out to all
    // four the way `bindRadiusN` does. With one corner square the four are no
    // longer interchangeable, and `borderRadius` states each of them.
    const squareLeft = m.tail === 'start';
    const squareRight = m.tail === 'end';
    const squareTopLeft = squareLeft && tailOnTop;
    const squareTopRight = squareRight && tailOnTop;
    const squareBottomLeft = squareLeft && !tailOnTop;
    const squareBottomRight = squareRight && !tailOnTop;
    if (!squareTopLeft) {
      bubble.setBoundVariable('topLeftRadius', lk.radius(dimVal(f.borderRadius.topLeft)));
    }
    if (!squareTopRight) {
      bubble.setBoundVariable('topRightRadius', lk.radius(dimVal(f.borderRadius.topRight)));
    }
    if (!squareBottomLeft) {
      bubble.setBoundVariable('bottomLeftRadius', lk.radius(dimVal(f.borderRadius.bottomLeft)));
    }
    if (!squareBottomRight) {
      bubble.setBoundVariable('bottomRightRadius', lk.radius(dimVal(f.borderRadius.bottomRight)));
    }
    if (filled) {
      // The bubble is a content surface on both platforms — it restates the
      // content-role seat itself because the tail is cut against the same fill
      // (`surfaceFor(.content)` on Flutter, the content marker on Web). The
      // square corner stays Figma's own 0 on the layers too. The tail takes the
      // bubble's share of the fill and nothing else: Flutter paints it in the
      // colour the share is folded into, and Web's tail is the marked element's
      // child and inherits its computed fill. Neither frosts it — the backdrop
      // pass is the bubble box's.
      applySurfaceMaterial(bubble, lk, bg, 'content', {
        radius: {
          topLeft: squareTopLeft ? null : f.borderRadius.topLeft,
          topRight: squareTopRight ? null : f.borderRadius.topRight,
          bottomLeft: squareBottomLeft ? null : f.borderRadius.bottomLeft,
          bottomRight: squareBottomRight ? null : f.borderRadius.bottomRight,
        },
      });
    } else {
      bubble.fills = [];
    }
    const label = makeLabel(
      CHAT_BUBBLE_TEXT,
      lk,
      // The variant foreground is the base colour and `textStyle` carries no
      // colour of its own, so the variant wins — `typographyColorOpts`, not
      // `textLabelOpts` (which would let a null style colour fall through to
      // the generic on-surface default).
      typographyColorOpts(lk, bodyStyle, colorData(v.foregroundColor)),
    );
    bubble.appendChild(label);
    label.layoutSizingHorizontal = 'HUG';
    label.layoutSizingVertical = 'HUG';
    comp.appendChild(bubble);
    if (tail != null && m.tail === 'end') comp.appendChild(tail);
    contents.push(label);
  }
  const set = mount.finish();
  // `child` is `W`, not `W?` — a bubble with nothing in it is not a rendering
  // the widget has — so the slot gets no BOOLEAN. It is drawn as a text node,
  // and TEXT is the ceiling for one: a swap would want a `Text` component in
  // the REGISTRY, which was decided against.
  //
  // One property for all twenty-five members: `defineProp` returns the existing
  // id once the set owns it, and every member's label points at that same id, so
  // the copy survives a variant switch instead of resetting per tone.
  const childProp = defineProp(set, 'Child', 'TEXT', CHAT_BUBBLE_TEXT);
  for (const content of contents) bindTextProp(content, childProp);
  vStackSet(set);
  return set;
}

// ─── RadialProgress ──────────────────────────────────────────────────────────

// Data-driven from coui_core RADIAL_PROGRESS: `fields` (the lg / primary
// resting values), `sizes.defaultsBySize` (size / strokeWidth / valueTextStyle
// per `CoreProgressSize` step) and `variants.defaultsByTone` (the arc colour per
// `CoreProgressTone`). A SET of Size × Tone, the same two axes `Progress` has.
//
// A donut drawn with `arcData.innerRadius`, not a stroked ellipse: Figma
// centres a stroke on the path, so a stroked circle would overflow its own box
// by half `strokeWidth` and the component would no longer be `size` wide. The
// inner radius is derived from the two fields that decide it —
// `1 - 2 * strokeWidth / size` — which is the same ring thickness the painter's
// `radius = (width - strokeWidth) / 2` produces. The track is the style's own
// `backgroundColor` (a neutral surface), the arc is the tone's colour.
//
// The arc starts at 12 o'clock (`-π/2`, the painter's `_kRadialStartAngle`) and
// sweeps clockwise. How far it sweeps is the caller's `value` — a widget
// parameter with no Style default (see `RADIAL_PREVIEW_VALUE`).
//
// `sm` states no `valueTextStyle`: a 32 ring has no room for a legible
// percentage, so the widget draws none and the member hides its label.
interface RadialSizeRow {
  size: Parameters<typeof dimVal>[0];
  strokeWidth: Parameters<typeof dimVal>[0];
  valueTextStyle?: Parameters<typeof textStyleData>[0];
}
interface RadialToneRow {
  color: Parameters<typeof colorData>[0];
}
const RADIAL_LEAD = { Size: 'lg', Tone: 'primary' } as const;

function buildRadialProgress(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = RADIAL_PROGRESS.fields;
  const sizeRows = RADIAL_PROGRESS.sizes.defaultsBySize as Record<string, RadialSizeRow>;
  const toneRows = RADIAL_PROGRESS.variants.defaultsByTone as Record<string, RadialToneRow>;
  const members = enumerateAxisAssignments([
    { axis: 'Size' as const, values: Object.keys(sizeRows) },
    { axis: 'Tone' as const, values: Object.keys(toneRows) },
  ]);
  const mount = mountSet(
    page,
    'RadialProgress',
    members.map((m) => m.name),
    {
      // The loose COMPONENT this used to be drew the one ring the widget had —
      // the `lg` size in the `primary` tone — so it is promoted in place and
      // every instance of it survives.
      adoptLooseAs: composeVariantName([
        ['Size', RADIAL_LEAD.Size],
        ['Tone', RADIAL_LEAD.Tone],
      ]),
    },
  );
  const percent = Math.round(RADIAL_PREVIEW_VALUE * 100);
  const leadStyle = sizeRows[RADIAL_LEAD.Size].valueTextStyle;
  if (!leadStyle) throw new Error('RadialProgress: the lead size states no valueTextStyle');
  const labels: TextNode[] = [];
  for (const m of members) {
    const sz = sizeRows[m.values['Size']];
    const tone = toneRows[m.values['Tone']];
    const side = dimVal(sz.size);
    const c = mount.getOrCreate(m.name);
    c.fills = [];
    bindSize(c, lk, sz.size, sz.size);

    const inner = Math.max(0, 1 - (2 * dimVal(sz.strokeWidth)) / side);
    const start = -Math.PI / 2;
    const fullTurn = Math.PI * 2;

    const track = figma.createEllipse();
    bindSize(track, lk, sz.size, sz.size);
    track.arcData = { startingAngle: start, endingAngle: start + fullTurn, innerRadius: inner };
    fillData(track, lk, colorData(f.backgroundColor));
    c.appendChild(track);
    track.x = 0;
    track.y = 0;

    const arc = figma.createEllipse();
    bindSize(arc, lk, sz.size, sz.size);
    arc.arcData = {
      startingAngle: start,
      endingAngle: start + fullTurn * RADIAL_PREVIEW_VALUE,
      innerRadius: inner,
    };
    fillData(arc, lk, colorData(tone.color));
    c.appendChild(arc);
    arc.x = 0;
    arc.y = 0;

    // `showValueText` renders `'${value.toInt()}%'` in the size's
    // `valueTextStyle` (which carries its own colour, so `textLabelOpts` is
    // right here). A size that states none draws no text.
    const textStyle = sz.valueTextStyle;
    const label = makeLabel(
      `${percent}%`,
      lk,
      // Hidden on `sm`, but a node still has to exist for the shared `Child`
      // property to bind to — it borrows the lead size's style, which is
      // never seen.
      textLabelOpts(lk, textStyleData(textStyle ?? leadStyle)),
    );
    c.appendChild(label);
    const half = 2;
    label.x = (side - label.width) / half;
    label.y = (side - label.height) / half;
    label.visible = textStyle != null;
    labels.push(label);
  }
  const set = mount.finish();
  // This node is the `child` slot. The widget puts both in the same place and
  // lets the slot win — `centerChild = child; if (centerChild == null &&
  // showValueText) centerChild = Text('…%')` — so the percentage is what fills
  // the slot's position when the caller passes nothing, not a second region.
  //
  // TEXT, because a text node is what is drawn there; the contract records the
  // slot as `W` and it gets no BOOLEAN for the same reason ChatBubble's
  // doesn't. One property for every member: the copy survives a variant switch.
  const childProp = defineProp(set, 'Child', 'TEXT', `${percent}%`);
  for (const label of labels) bindTextProp(label, childProp);
  return set;
}

// ─── AvatarGroup ─────────────────────────────────────────────────────────────

// Data-driven from coui_core AVATAR_GROUP: `fields` (overlap / extraSpacing /
// borderColor / borderWidth). The avatars themselves are instances of the
// `Avatar` component — this component owns the overlap and the separator ring,
// not the avatar, and instantiating is what keeps that true on the canvas
// (`needs: ['Avatar']`).
//
// The overlap is one negative auto-layout gap rather than a per-child paint
// offset, because Figma has no equivalent of the widget's
// `Transform.translate(-overlap * i + extraSpacing * i)` — but the arithmetic
// is the widget's own per-step offset, so the two agree for every i. It is
// assigned as a raw number rather than bound to a Variable for the reason a
// negative gap cannot be bound: there is no `space/-16` token, and inventing
// one would put a value in the token collection that no CoUI code references.
//
// `max` (and the `+N` overflow avatar it adds) is a widget parameter with no
// Style default, so the preview draws a plain group of
// `AVATAR_GROUP_PREVIEW_COUNT`.
// Sample initials in precedence order: one English letter each, A first.
const kAvatarGroupInitials = ['A', 'B', 'C'] as const;

function buildAvatarGroup(page: PageNode, lk: VarLookup): ComponentNode {
  const f = AVATAR_GROUP.fields;
  const ring = colorData(f.borderColor);
  const c = mint(page, 'AvatarGroup');
  applyPanelCompChrome(c, 'HORIZONTAL', lk, {});
  c.counterAxisAlignItems = 'CENTER';
  c.itemSpacing = dimVal(f.extraSpacing) - dimVal(f.overlap);
  for (let i = 0; i < AVATAR_GROUP_PREVIEW_COUNT; i++) {
    const avatar = instanceOf(page, 'Avatar', bestVariantName(page, 'Avatar', AVATAR_MD));
    // The widget wraps each avatar in a bordered Container; the stroke goes on
    // the instance itself here, which is the same ring in one fewer node — and
    // the Avatar component's radius already makes it follow the circle.
    borderData(avatar, lk, ring, f.borderWidth);
    // Each avatar a different person — A, B, C from the front, so the group
    // does not read as one person three times.
    setInstanceTextNamed(avatar, 'Initials', kAvatarGroupInitials[i % kAvatarGroupInitials.length]);
    c.appendChild(avatar);
  }
  return c;
}

// ─── AvatarBadge ─────────────────────────────────────────────────────────────

// Data-driven from coui_core AVATAR_BADGE: `fields` (backgroundColor / size).
//
// The widget is a `Container(shape: .circle)` of `size` × `size` with an
// optional centred child. The circle is an ellipse child rather than a rounded
// component root because `shape: .circle` is not a radius: there is no radius
// field on `CoreAvatarBadgeStyle` to read, and binding a pill radius would be
// inventing chrome the component does not own.
//
// `child` defaults to null, so the *default rendering* is the bare dot — but
// "the default is nothing" and "nothing can ever go there" are different
// claims, and drawing only the dot made the second one. The slot is therefore
// present and hidden: an `Icon` instance (`needs: ['Icon']`) inside a holder
// whose BOOLEAN is off, matching the widget's null, so nothing on the canvas
// changes and a designer can switch it on and swap it for any component.
//
// Hidden also keeps `Avatar` unchanged — it instantiates this component for its
// own `badge` slot, and an instance clones the holder in whatever state the
// main component left it.
function buildAvatarBadge(page: PageNode, lk: VarLookup): ComponentNode {
  const f = AVATAR_BADGE.fields;
  const c = mint(page, 'AvatarBadge');
  c.fills = [];
  bindSize(c, lk, f.size, f.size);
  // The dot and the child holder are the badge's whole box and SCALE with it:
  // `Avatar` resizes the instance to its step's badge (8 at `xs` up to 20 at
  // `xl2`, `CoreAvatarStyle.badgeStyle`), and a dot held at its own size
  // would be clipped by a smaller badge and stop short of a larger one. The
  // size is written on the root alone — a size variable bound on the dot as
  // well would hold it at 12 in every instance.
  const side = dimVal(f.size);
  const dot = figma.createEllipse();
  dot.resize(side, side);
  fillData(dot, lk, colorData(f.backgroundColor));
  // The ring inside the dot's edge (`borderColor` · `borderWidth`), INSIDE
  // so the dot keeps its size — Flutter's foreground border, Web's inset
  // `box-shadow`. `Avatar` restates the width on its two smallest steps.
  borderData(dot, lk, colorData(f.borderColor), f.borderWidth);
  dot.strokeAlign = 'INSIDE';
  c.appendChild(dot);
  dot.x = 0;
  dot.y = 0;
  dot.constraints = { horizontal: 'SCALE', vertical: 'SCALE' };

  const owner = propertyOwner(c);
  const showProp = defineProp(owner, 'Show child', 'BOOLEAN', false);
  // The glyph is drawn from the `Child` default, so the bind leaves it at the
  // badge's size (see `IconOpts.fromVariant`).
  const childSwap = iconSwapDefault(page, 'AvatarBadge', 'Child', iconMainId(page));
  const swapProp = defineProp(owner, 'Child', 'INSTANCE_SWAP', childSwap.id);
  const holder = autoFrame('child', 'HORIZONTAL');
  holder.primaryAxisAlignItems = 'CENTER';
  holder.counterAxisAlignItems = 'CENTER';
  const glyph = makeIcon(AVATAR_BADGE_CHILD_GLYPH, lk, {
    ...glyphOpts(lk, AVATAR_BADGE_CHILD_COLOR, f.size, 'size'),
    fromVariant: childSwap.variant,
  });
  holder.appendChild(glyph);
  // Appended last so it sits above the dot, and at the origin because it is the
  // badge's own `size` — `Center` with no room left to centre in. That is the
  // size, not the app root's ambient icon size: the Flutter widget is a
  // `size × size` `Container` whose `Center` hands the child loose constraints
  // capped at that box, so a bare `Icon` here is clamped to `size`. Web does
  // not clamp — its dot is an unclipped `inline-flex` box and the `Icon`
  // states its own width — so there a bare `Icon` keeps the ambient size and
  // spills past the dot. The two platforms disagree; the canvas draws
  // Flutter's, and the disagreement is the code's to settle.
  c.appendChild(holder);
  holder.resize(side, side);
  holder.x = 0;
  holder.y = 0;
  holder.constraints = { horizontal: 'SCALE', vertical: 'SCALE' };
  // Matches the BOOLEAN's default so the main component reads the same way an
  // un-overridden instance of it does.
  holder.visible = false;
  bindVisibleProp(holder, showProp);
  bindSwapProp(glyph, swapProp);
  return c;
}

// ─── TabPane ─────────────────────────────────────────────────────────────────

// Data-driven from coui_core TAB_PANE: `fields` (backgroundColor /
// borderColor / borderRadius / borderWidth / barHeight / tabPadding /
// tabSpacing / contentTextStyle / labelBadgeGapStyle).
//
// `labelBadgeGapStyle` is the tab's one in-tab spacer — the step between the
// label and whatever the item hangs beside it (`CoreTabItem.badge`, `leading`,
// `trailing`). `tab_pane.dart` composes a `Gap` of that step per slot the item
// actually carries. It is one field and not three because a Figma auto-layout
// frame has ONE `itemSpacing`: three distinct 1-off gaps in this row would be
// a handle only two of the three surfaces could hold.
// Here it is each tab's own `itemSpacing`, and the badge is a composed `Badge`
// INSTANCE on each `TabPaneTab` member — `composeCountBadge`'s pose,
// shared with `TabItem`: hidden at rest and bound to a `Show count` BOOLEAN
// (default `false`, so the resting pose stays the bare strip), its `Child`
// set to the count's default and surfaced on this panel by exposing the
// nested instance — a component-level TEXT cannot bind to a node inside an
// instance (`navigation.ts`'s `TabItem` header has the full note). A hidden
// child stops billing the row's `itemSpacing`, so `Show count=false` leaves
// no gap, the way the widget composes no `Gap` without a badge.
//
// Structure follows the widget's `Column`: the ROOT is the card (the one
// hairline edge, the content-material fill, the corner radius), and it holds a
// `barHeight`-tall row of underline tabs — inset by `barPadding`, every tab as
// tall as the bar — over the content panel. Only the focused tab carries the
// indicator, a `indicatorWidth`-tall bar the tab's full width: along the
// bottom edge on `boxed` (over the bar's bottom line, its top corners rounded
// by `indicatorBorderRadius`), along the top edge on `editorStrip`. A tab has
// a face (the fill, and an outline) only where the style states one:
// `editorStrip` fills its focused chip, `boxed` leaves `tabBorderColor`
// transparent and so draws neither.
//
// The panel has no padding of its own on purpose: `CoreTabPaneStyle` carries no
// panel inset, and the widget puts `tabs[i].content` straight inside the
// `DecoratedBox` — whatever padding a panel has comes from the content widget.
// Adding one to the PANEL here would draw an inset the component does not
// own. The stand-in CONTENT is padded instead, the way the docs example pads
// its content (`Padding(CoreSpace.space20)`, its text `bodyMedium` in
// `onSurfaceVariant`), so the designer judges the same picture the docs show —
// without it a one-line panel at `radius12` is a pill.
//
// ─── `clickableStyle.disabledOpacity` (0.5) — drawn, per item ────────────────
//
// The comment that used to sit here recorded this field as stated-and-undrawn
// and argued the fix was out of reach: opacity per state needs a VARIANT (Figma
// binds a component property to `visible` / `characters` / `mainComponent` only —
// `plugin-api.d.ts` line 6427 — so two opacities need two nodes), turning this
// COMPONENT into a COMPONENT_SET. That shape change has since happened, but
// for `CoreTabPaneVariant` (`Variant=boxed|editorStrip`), not for a Disabled
// axis — see `buildTabPane` and the `TabPane` row in `STRUCTURAL_MIGRATIONS`.
//
// All of that is still true and none of it was the blocker, because the premise
// under it was wrong. That note read the fade as component-wide — "a TabPane
// built without `onChanged` renders EVERY tab disabled". It does, but that is the
// weaker of the two ways in: `tab_pane.dart:115` is
// `isEnabled = item.enabled && widget.onChanged != null`, and `item.enabled` is
// per-`CoreTabItem`. A single disabled tab beside enabled ones is an ordinary
// resting configuration of this widget — `TabItem(label: 'Team', enabled: false)`
// — so it needs no state axis to draw. The bar already varies its tabs (tab 0
// carries the focused fill and border, the others do not); one of them carrying
// the disabled fade is the same kind of fact about the same demo row.
//
// So the last tab is drawn at `disabledOpacity` and the field reaches the canvas.
// The fade lands on that `tab` frame, not on the component root: the widget wraps
// only the tabs in `Clickable`, and the content panel sits outside it at full
// opacity. Both states are now visible at once, which a `Disabled` toggle could
// not have shown.
//
// What a variant axis is still owed, and what it would buy: the component-wide
// case (`onChanged == null`, every tab dimmed together). That remains
// undrawn — it is the same picture repeated across three tabs rather than a new
// value, so it is the cheaper half to be missing.
//
// Nothing automated would have caught either half. `fidelity.ts` runs no opacity
// check, G7 counts literals and an opacity never written leaves none, and
// `check_figma_unread_fields.py` word-searches every builder at once, so
// `disabledOpacity` counted as read here on the strength of six other files
// reading it. The same blind spot hides `dragOpacity` below.
//
// Unused, and why:
//   · `dragOpacity` (0.5) is the opacity of the tab while it is being dragged —
//     `Opacity(opacity: dragOpacity, child: tab)` passed as BOTH `feedback:` (the
//     copy under the pointer) and `childWhenDragging:` (the tab left behind in the
//     row), `tab_pane.dart:162-171`. Unlike `enabled: false` this is not a resting
//     configuration: it exists only while a pointer is down, and only when the
//     caller passed `reorderable` AND `onReorder`. Drawing a permanently
//     half-faded tab would assert a rendering the component never holds still in.
//     The honest form is a `Dragging` column on the set this builder now
//     returns. That is a further axis (`VARIANT_RENAMES`), not the
//     `STRUCTURAL_MIGRATIONS` row — that row retires the old single COMPONENT
//     so `Variant=editorStrip` can exist. Flagged in `notes` rather than
//     drawn here.
//     (A hidden BOOLEAN-revealed ghost was the tempting shortcut and is rejected:
//     `dragOpacity` and `disabledOpacity` are both 0.5, so it would put a second
//     identical fade on the canvas meaning something else entirely.)
//   · the rest of `clickableStyle` — focus-ring colour/radius, `pressedScale`,
//     durations. Ring and press are states with the same axis cost;
//     durations have no static rendering at all.
//   · `leading` / `trailing` both default to `const []`; the preview is the
//     default, so both brackets are empty.
//
// ─── `Variant=boxed | editorStrip` ──────────────────────────────────────────
//
// `CoreTabPaneVariant` is the contract axis. Figma spells contract enums
// `Variant=…`, the same label the other navigation builders use. There is
// no `chrome` axis and no per-component `theme` / `dark` axis: dark
// appearance is the product canvas's CoUI mode, not a TabPane property.
//
// `boxed` is the card this function used to mint alone. `editorStrip` is
// the strip-only pose (`variant == .editorStrip` returns the bar and
// nothing else). Chrome for that member comes from
// `variants.defaultsByVariant.editorStrip`, which is
// `CoreTabPaneStyle.editorStrip`: the strip's height, the chip padding, the
// label role, the band fill, flush radius, no rule between tabs, and the
// strip's bottom line (`borderWidth` in `borderColor`). A row key wins over
// `fields`; `boxed` is an empty partial, so `fields` is what that member
// paints.
//
// Two more row values belong to `editorStrip` alone and are drawn only where the
// row states them:
//   · the selected tab's indicator — `indicatorColor` (`primary`) × `indicatorWidth`
//     (`stroke/2`), a bar along the INSIDE of the tab's top edge. It is the tab's
//     top stroke (an inside stroke that is not counted in the layout), so the
//     label sits at the same y on the selected and on an unselected tab — the
//     Flutter twin's foreground `DecoratedBox` and the Web inset shadow do the
//     same, because a border that inflated the padding would push only the
//     selected label down. `boxed` states a transparent indicator (the field's
//     default), so it draws none and the three-sided tab stroke is untouched.
//   · the close affordance — `closeButtonStyle` (the 24 × 24 box, no inset, the
//     6-radius corner) around `closeIconStyle` (the 12 glyph in
//     `on-surface-subtle`, which holds in every state). The widget builds it as a
//     `Button(variant: .ghost)`; the `TabPaneTab` set draws it as a box of that
//     size, inset and corner around the glyph — what `closeButtonStyle` states
//     at rest — rather than composing a `Button`, whose own ghost row would
//     have to be overridden back to these values on every instance. It is
//     hidden at rest and bound to the tab's `Show close`, the shape the leading
//     and trailing slots already take: the widget draws it only for a tab given
//     `onClose`, and the docs default has none. `boxed` states no close slot
//     and draws none.
//
// The tabs themselves are `TabPaneTab` instances (P6-b): the strip places one
// per demo tab and exposes them, so each tab's label, slots, count and close
// are that instance's properties, not the strip's.
//
// Shape change: this was a single COMPONENT and is now a COMPONENT_SET,
// which Figma cannot convert in place — see the `TabPane` entry in
// `STRUCTURAL_MIGRATIONS` (`src/renames.ts`), without which the old node
// stays on the page as a same-named duplicate. Publishing that set into
// the live file is a Generate + Publish in the CoUI library, not a side
// effect of merging this builder.
/** The `editorStrip` row's `closeButtonStyle`, as far as the strip's close box
 *  reads it: the box the widget spends as `SizedBox` (width / height), its inset
 *  and its corner. */
interface TabPaneCloseButton {
  width: Dim;
  height: Dim;
  padding: PadData;
  borderRadius: { topLeft: Dim };
}

/** The row's `closeIconStyle`: the glyph's size and colour. */
interface TabPaneCloseIcon {
  size: Dim;
  color: Color;
}

/** The close box, when the style states one: a size, an inset and a corner. */
function closeBoxOf(style: Partial<TabPaneCloseButton>): TabPaneCloseButton | null {
  const { width, height, padding, borderRadius } = style;
  return width != null && height != null && padding != null && borderRadius != null
    ? { width, height, padding, borderRadius }
    : null;
}

/** The close glyph, when the style states a size and a colour. */
function closeGlyphOf(style: Partial<TabPaneCloseIcon>): TabPaneCloseIcon | null {
  const { size, color } = style;
  return size != null && color != null ? { size, color } : null;
}

/** Everything a `CoreTabPaneVariant` row states for the strip and its tabs,
 *  row over field — `chrome.X ?? defaultX` in `resolveTabPane`. A key the row
 *  does not state stays the field, which is how `boxed` (an empty partial)
 *  keeps the card. One reading for `TabPaneTab` (the tab) and `TabPane` (the
 *  strip and the panel), so the two cannot disagree about a member. */
function tabPaneChrome(name: string, row: object) {
  const f = TAB_PANE.fields;
  const contentRole = optField<typeof f.contentTextStyle>(row, 'contentTextStyle');
  return {
    // `editorStrip` is the strip-only member. The widget branches on the enum
    // (`stripOnly`), not on a second axis.
    stripOnly: name === 'editorStrip',
    backgroundColor: optField<typeof f.backgroundColor>(row, 'backgroundColor') ?? f.backgroundColor,
    borderColor: optField<typeof f.borderColor>(row, 'borderColor') ?? f.borderColor,
    tabBorderColor: optField<typeof f.tabBorderColor>(row, 'tabBorderColor') ?? f.tabBorderColor,
    stripBackgroundColor:
      optField<typeof f.stripBackgroundColor>(row, 'stripBackgroundColor') ?? f.stripBackgroundColor,
    tabSeparatorColor:
      optField<typeof f.tabSeparatorColor>(row, 'tabSeparatorColor') ?? f.tabSeparatorColor,
    tabSeparatorWidth:
      optField<typeof f.tabSeparatorWidth>(row, 'tabSeparatorWidth') ?? f.tabSeparatorWidth,
    borderRadius: optField<typeof f.borderRadius>(row, 'borderRadius') ?? f.borderRadius,
    borderWidth: optField<typeof f.borderWidth>(row, 'borderWidth') ?? f.borderWidth,
    tabSpacing: optField<typeof f.tabSpacing>(row, 'tabSpacing') ?? f.tabSpacing,
    // The strip's own height, the chip padding and the label role are row
    // values too (`editorStrip` states 36, start 12 / end 8, `codeSm`; `boxed`
    // states 44, 2 either side and `labelLarge`); a row that states none leaves
    // the field.
    barHeight: optField<typeof f.barHeight>(row, 'barHeight') ?? f.barHeight,
    tabPadding: optField<PadData>(row, 'tabPadding') ?? f.tabPadding,
    // The tabs' inset inside the bar — 16 either side on `boxed` (the first tab
    // clears the card's corner), flush on `editorStrip`.
    barPadding: optField<PadData>(row, 'barPadding') ?? f.barPadding,
    // The selected tab's indicator bar and the close affordance — row values
    // the strip states: both rows draw the indicator (`boxed` along the
    // bottom, `editorStrip` along the top); only `editorStrip` states a close
    // slot, so the close box is drawn there alone.
    indicator: colorData(optField<typeof f.indicatorColor>(row, 'indicatorColor') ?? f.indicatorColor),
    indicatorWidth: optField<typeof f.indicatorWidth>(row, 'indicatorWidth') ?? f.indicatorWidth,
    indicatorBorderRadius:
      optField<typeof f.indicatorBorderRadius>(row, 'indicatorBorderRadius') ?? f.indicatorBorderRadius,
    // The field is the shared default (a bare `CoreButtonStyle` /
    // `CoreIconStyle`, no box and no glyph size), so a close box exists only
    // where the merged style states one.
    closeButton: closeBoxOf(
      optField<Partial<TabPaneCloseButton>>(row, 'closeButtonStyle') ??
        (f.closeButtonStyle as Partial<TabPaneCloseButton>),
    ),
    slotIconSize: (optField<{ size?: Dim }>(row, 'slotIconStyle') ?? (f.slotIconStyle as { size?: Dim })).size,
    closeIcon: closeGlyphOf(
      optField<Partial<TabPaneCloseIcon>>(row, 'closeIconStyle') ??
        (f.closeIconStyle as Partial<TabPaneCloseIcon>),
    ),
    // The role is the row's when it states one (`editorStrip`: `codeSm`),
    // laid over the field the way `resolveTabPane` merges them.
    contentStyle:
      contentRole == null
        ? textStyleData(f.contentTextStyle)
        : mergeTextStyleData(textStyleData(f.contentTextStyle), textStyleData(contentRole)),
  };
}

// ─── TabPaneTab ──────────────────────────────────────────────────────────────
//
// One tab of the strip as its own set — the tab `TabPane` places once per
// `CoreTabItem`, so a designer picks how many tabs a strip holds and which one
// is current by placing instances, instead of detaching the sample strip (the
// v2 kit's CodeTab is this tab). Like `TabItem` for `Tabs` it has no Dart
// widget and no Style of its own: `CoreTabItem<W>` is a data value, and every
// pixel the tab paints is a `CoreTabPaneStyle` field (`dataSlug: 'tab_pane'`).
//
// Two axes:
//   · `Variant` — `CoreTabPaneVariant`, because a strip's tab is drawn by its
//     strip's row (`boxed` — the card's top-rounded tab, `editorStrip` — the
//     flush chip with the indicator and the close box).
//   · `Selected` — `isFocused` in the widget: the face (`backgroundColor`),
//     the boxed three-sided stroke / the strip's inside top indicator, and the
//     active label colour.
//
// Properties, every one a slot of `CoreTabItem` the strip used to state on its
// own panel: `Label`, `Show leading` + `Leading`, `Show trailing` +
// `Trailing`, `Show count` (the composed count `Badge`, `composeCountBadge`),
// and — on the `editorStrip` members, the only row that states the close slot
// — `Show close`: the widget's close `Button(buttonStyle: closeButtonStyle,
// child: Icon(x, iconStyle: closeIconStyle))`, drawn as a box of that size,
// inset and corner around the 12 glyph in the row's close ink. A disabled tab
// is the strip's (`Show disabled tab`), because `item.enabled` is the strip's
// `Clickable` fade on the placed instance.
const kTabPaneTabName = 'TabPaneTab';
const kTabPaneTabLabel = '계정';

function tabPaneTabVariantName(variant: string, selected: boolean): string {
  return composeVariantName([
    ['Variant', variant],
    ['Selected', String(selected)],
  ]);
}

function buildTabPaneTab(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = TAB_PANE.fields;
  const variantRows = Object.entries(TAB_PANE.variants.defaultsByVariant);
  // The slot glyphs are drawn from their swap defaults, so the properties'
  // first binds leave them at their own size (see `IconOpts.fromVariant`).
  const leadingSwap = iconSwapDefault(page, kTabPaneTabName, 'Leading', iconMainId(page));
  const trailingSwap = iconSwapDefault(page, kTabPaneTabName, 'Trailing', iconMainId(page));
  // Unselected first: a tab dropped from the assets panel is one of the many
  // tabs a strip holds, and the set's first member is what it lands on.
  const names: string[] = [];
  for (const [name] of variantRows) {
    for (const selected of [false, true]) names.push(tabPaneTabVariantName(name, selected));
  }
  const mount = mountSet(page, kTabPaneTabName, names);
  const labels: TextNode[] = [];
  const leadingSlots: { holder: FrameNode; glyph: InstanceNode }[] = [];
  const trailingSlots: { holder: FrameNode; glyph: InstanceNode }[] = [];
  const closeBoxes: FrameNode[] = [];
  const members: ComponentNode[] = [];
  for (const [name, row] of variantRows) {
    const chrome = tabPaneChrome(name, row);
    for (const isFocused of [false, true]) {
      const tab = mount.getOrCreate(tabPaneTabVariantName(name, isFocused));
      members.push(tab);
      applyPanelCompChrome(tab, 'HORIZONTAL', lk, {});
      tab.counterAxisAlignItems = 'CENTER';
      bindPad(tab, lk, chrome.tabPadding);
      // An underline tab has no corners of its own — the indicator rounds
      // itself. Stated rather than left alone: members are recycled, and an
      // untouched tab keeps the top radius an earlier build gave it.
      // g7-preview-only: no `CoreTabPaneStyle` field states a tab radius — the widgets draw the tab as a box with no corners (the indicator rounds itself, `indicatorBorderRadius`), so the canvas states the 0 the widgets' shape implies.
      bindRadiusN(tab, lk, 0);
      // A face — the fill, and the three-sided outline — only where the style
      // states one: `editorStrip` fills its focused chip; `boxed` leaves
      // `tabBorderColor` transparent, so the focused tab sits on the card's own
      // surface with neither. The widgets' `faced` / `showTabBorder`.
      tab.strokes = [];
      tab.strokesIncludedInLayout = false;
      let outlined = false;
      if (isFocused && (chrome.stripOnly || paintsFill(colorData(chrome.tabBorderColor)))) {
        fillData(tab, lk, colorData(chrome.backgroundColor));
        if (!chrome.stripOnly && dimVal(chrome.borderWidth) > 0) {
          borderData(tab, lk, colorData(chrome.tabBorderColor), chrome.borderWidth, {
            top: true,
            left: true,
            right: true,
          });
          outlined = true;
        }
      } else {
        tab.fills = [];
      }
      // The inter-tab rule, on the tab's inline-end edge and on every tab
      // whatever its focus — `editorStrip` states `outline-variant`, `boxed`
      // states none. The widgets draw it on a wrapper OUTSIDE the chip, which
      // reserves the rule's width beside the chip; included in layout, the
      // tab's own stroke reserves the same width, so the strip measures the
      // same and the tab carries its rule wherever a designer places it. A
      // tab that already wears the three-sided outline keeps that one stroke
      // paint (a Figma node has one): no row states both.
      const separator = colorData(chrome.tabSeparatorColor);
      const separated = !outlined && paintsFill(separator);
      if (separated) {
        borderData(tab, lk, separator, chrome.tabSeparatorWidth, { right: true });
        tab.strokesIncludedInLayout = true;
      }
      // The label↔badge spacer, on every tab: the stated field is the tab's own
      // row gap, whether or not this tab's badge is showing.
      tab.setBoundVariable('itemSpacing', lk.space(dimVal(f.labelBadgeGapStyle.size)));
      // The role is one statement; only the colour varies by focus (both
      // widgets layer it the same way).
      const label = makeLabel(
        kTabPaneTabLabel,
        lk,
        textLabelOpts(lk, {
          ...chrome.contentStyle,
          color: colorData(isFocused ? f.activeContentColor : f.inactiveContentColor),
        }),
      );
      label.name = 'label';
      labels.push(label);
      // Leading / trailing composition slots. Hidden at rest and bound to a
      // BOOLEAN, so the resting pose is the bare tab; the glyph inside is the
      // INSTANCE_SWAP target. The shape `buildAvatarBadge` uses for its own
      // `Show child` / `Child` pair.
      const leadHolder = autoFrame('leading', 'HORIZONTAL');
      leadHolder.counterAxisAlignItems = 'CENTER';
      const leadGlyph = makeIcon(TAB_PANE_LEADING_GLYPH, lk, {
        ...glyphOpts(lk, colorData(f.activeContentColor), chrome.slotIconSize ?? f.slotIconStyle.size, 'size'),
        fromVariant: leadingSwap.variant,
      });
      leadHolder.appendChild(leadGlyph);
      leadHolder.visible = false;
      tab.appendChild(leadHolder);
      leadingSlots.push({ holder: leadHolder, glyph: leadGlyph });
      tab.appendChild(label);
      const trailHolder = autoFrame('trailing', 'HORIZONTAL');
      trailHolder.counterAxisAlignItems = 'CENTER';
      const trailGlyph = makeIcon(TAB_PANE_TRAILING_GLYPH, lk, {
        ...glyphOpts(lk, colorData(f.inactiveContentColor), chrome.slotIconSize ?? f.slotIconStyle.size, 'size'),
        fromVariant: trailingSwap.variant,
      });
      trailHolder.appendChild(trailGlyph);
      trailHolder.visible = false;
      tab.appendChild(trailHolder);
      trailingSlots.push({ holder: trailHolder, glyph: trailGlyph });
      if (chrome.closeButton != null && chrome.closeIcon != null) {
        // The widget's `Button(buttonStyle: closeButtonStyle, child: Icon(x,
        // iconStyle: closeIconStyle))`: a fixed box with the stated inset and
        // corner, the glyph centred in it. After the trailing slot, which is
        // the order `sideChildren` adds them in.
        const closeBox = autoFrame('close', 'HORIZONTAL');
        closeBox.primaryAxisAlignItems = 'CENTER';
        closeBox.counterAxisAlignItems = 'CENTER';
        bindPad(closeBox, lk, chrome.closeButton.padding);
        bindRadiusN(closeBox, lk, chrome.closeButton.borderRadius.topLeft);
        closeBox.primaryAxisSizingMode = 'FIXED';
        closeBox.counterAxisSizingMode = 'FIXED';
        bindSize(closeBox, lk, chrome.closeButton.width, chrome.closeButton.height);
        closeBox.appendChild(
          makeIcon(
            TAB_PANE_TRAILING_GLYPH,
            lk,
            glyphOpts(lk, colorData(chrome.closeIcon.color), chrome.closeIcon.size, 'size'),
          ),
        );
        closeBox.visible = false;
        tab.appendChild(closeBox);
        closeBoxes.push(closeBox);
      }
      // As tall as the strip, selected or not: the widgets' chip fills the
      // bar (`barHeight` — 36 on `editorStrip`, 44 on `boxed`) and centres its
      // row in it. Left hugging, the tab took its label's line box — 21 on the
      // `codeSm` strip, whose chip states no vertical padding — so the set's
      // members were shorter than the tab they stand for. A floor rather than
      // a fixed height: the tab still answers to auto-layout (it hugs, and
      // the strip places it FILL), and the bar's height is the floor it hugs
      // up to — bound to the same `size/<barHeight>` step the bar binds.
      tab.minHeight = dimVal(chrome.barHeight);
      tab.setBoundVariable('minHeight', lk.size(dimVal(chrome.barHeight)));
      // The indicator: a bar the tab's full width, `indicatorWidth` tall, along
      // the tab's bottom edge (`boxed`) or top edge (`editorStrip`), its corners
      // `indicatorBorderRadius` (the two top ones on `boxed`). An absolute child
      // takes no layout, so the label sits at the same y selected or not — the
      // widgets overlay it in a stack for the same reason. Built last and pinned
      // after the tab has its size, for the reason `Tabs` pins its rule last.
      if (isFocused && paintsFill(chrome.indicator)) {
        const bar = figma.createRectangle();
        bar.name = 'indicator';
        bar.resize(100, dimVal(chrome.indicatorWidth));
        const r = chrome.indicatorBorderRadius;
        bar.setBoundVariable('topLeftRadius', lk.radius(dimVal(r.topLeft)));
        bar.setBoundVariable('topRightRadius', lk.radius(dimVal(r.topRight)));
        bar.setBoundVariable('bottomLeftRadius', lk.radius(dimVal(r.bottomLeft)));
        bar.setBoundVariable('bottomRightRadius', lk.radius(dimVal(r.bottomRight)));
        fillData(bar, lk, chrome.indicator);
        tab.appendChild(bar);
        pinInFlow(tab, bar);
        bar.constraints = { horizontal: 'STRETCH', vertical: chrome.stripOnly ? 'MIN' : 'MAX' };
        // The chip's width, not the rule's: the widgets' rule sits outside the
        // chip, so the bar stops where the rule begins (STRETCH keeps that
        // end inset when the tab grows).
        const ruleWidth = separated ? dimVal(chrome.tabSeparatorWidth) : 0;
        bar.resize(tab.width - ruleWidth, bar.height);
        bar.x = 0;
        bar.y = chrome.stripOnly ? 0 : tab.height - bar.height;
      }
    }
  }
  const set = mount.finish();
  const labelProp = defineProp(set, 'Label', 'TEXT', kTabPaneTabLabel);
  for (const n of labels) bindTextProp(n, labelProp);
  const showLeadingProp = defineProp(set, 'Show leading', 'BOOLEAN', false);
  const leadingProp = defineProp(set, 'Leading', 'INSTANCE_SWAP', leadingSwap.id);
  const showTrailingProp = defineProp(set, 'Show trailing', 'BOOLEAN', false);
  const trailingProp = defineProp(set, 'Trailing', 'INSTANCE_SWAP', trailingSwap.id);
  const showCountProp = defineProp(set, 'Show count', 'BOOLEAN', false);
  // Only a row that states the close slot draws a box for it; the property is
  // defined when one does and binds on those members.
  if (closeBoxes.length > 0) {
    const showCloseProp = defineProp(set, 'Show close', 'BOOLEAN', false);
    for (const box of closeBoxes) bindVisibleProp(box, showCloseProp);
  }
  for (const slot of leadingSlots) {
    bindVisibleProp(slot.holder, showLeadingProp);
    bindSwapProp(slot.glyph, leadingProp);
  }
  for (const slot of trailingSlots) {
    bindVisibleProp(slot.holder, showTrailingProp);
    bindSwapProp(slot.glyph, trailingProp);
  }
  // The count joins every member after `finish()` — the set is the ancestor
  // both its binding and its exposure need (`composeCountBadge`).
  for (const member of members) composeCountBadge(page, member, showCountProp);
  return set;
}

function buildTabPane(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = TAB_PANE.fields;
  const variantRows = Object.entries(TAB_PANE.variants.defaultsByVariant);
  const mount = mountSet(
    page,
    'TabPane',
    variantRows.map(([name]) => `Variant=${name}`),
  );
  // Collected across members so the properties live on the SET — the owner
  // only exists after `finish()`, and a reference on a detached node is
  // refused.
  const painted: {
    contentLabel: TextNode | null;
    disabledTab: SceneNode | null;
    tabs: InstanceNode[];
  }[] = [];

  for (const [name, row] of variantRows) {
    const chrome = tabPaneChrome(name, row);
    const stripOnly = chrome.stripOnly;
    const surface = colorData(chrome.backgroundColor);
    const edge = colorData(chrome.borderColor);
    const band = colorData(chrome.stripBackgroundColor);
    // The inter-tab rule is each `TabPaneTab`'s own (its inline-end stroke,
    // included in layout so it reserves the width the widgets' wrapper
    // does), so the strip places the tabs bare.
    const c = mount.getOrCreate(`Variant=${name}`);
    applyPanelCompChrome(c, 'VERTICAL', lk, {});
    // The bar and the panel sit flush — nothing overlaps (the card owns the one
    // edge), and recycled members may still carry the old negative gap.
    c.setBoundVariable('itemSpacing', lk.space(0));
    c.itemReverseZIndex = false;
    // Boxed: the ROOT is the card — the content-material fill, the one
    // hairline edge and the corner radius. The bar and the panel are children
    // of it and draw no edge of their own. `editorStrip` has no card: the bar
    // is the root's only child.
    if (!stripOnly) {
      // The card is a content surface on both platforms (`resolveTabPane` folds
      // `theme.surfaceFor(.content)` into its fill; the Web twin marks the
      // root `webSurfaceMarkerFor(.content)`).
      applySurfaceMaterial(c, lk, surface, 'content', { radius: chrome.borderRadius.topLeft });
      borderData(c, lk, edge, chrome.borderWidth);
      bindRadiusN(c, lk, chrome.borderRadius.topLeft);
      c.clipsContent = true;
    }

    const bar = autoFrame('bar', 'HORIZONTAL');
    // The band paints the whole strip; `barPadding` is padding, so it moves the
    // tabs in without leaving the band's ends unpainted. Transparent on `boxed`
    // — the card's own fill shows through. `editorStrip` states a band colour,
    // so the band fills.
    fillData(bar, lk, band);
    // The bottom line: `borderWidth` in `borderColor` along the bar's lower
    // edge, inside its height, on both rows (`boxed` states the same
    // hairline). A frame's stroke is painted above its fill and below its
    // children, so `editorStrip`'s focused face covers it, the unfocused tabs
    // leave it visible, and `boxed`'s indicator bar is drawn over it — the
    // widgets' order. A transparent `borderColor` is the statement "no line",
    // which `borderData` honours by drawing nothing.
    borderData(bar, lk, edge, chrome.borderWidth, { bottom: true });
    bar.setBoundVariable('itemSpacing', lk.space(dimVal(chrome.tabSpacing)));
    // The tabs' inset inside the bar — a stated value, not derived from the
    // card's corner radius. 16 either side on `boxed`, flush on `editorStrip`.
    bindPad(bar, lk, chrome.barPadding);
    const barHeight = dimVal(chrome.barHeight);
    let disabledTab: SceneNode | null = null;
    const tabs: InstanceNode[] = [];
    for (let i = 0; i < TAB_PANE_TABS.length; i++) {
      // Each tab is a `TabPaneTab` instance of this strip's row — the first
      // the current one, the way `focusedIndex` rests at 0. Its copy is the
      // instance's own `Label`, overridden here, which is where
      // `CoreTabItem.label` lives in the code too.
      const tab = instanceOf(page, kTabPaneTabName, tabPaneTabVariantName(name, i === 0));
      tab.name = `tab ${TAB_PANE_TABS[i]}`;
      setInstanceTextNamed(tab, 'Label', TAB_PANE_TAB_LABELS[i]);
      tabs.push(tab);
      bar.appendChild(tab);
      // `Clickable` dims its whole child when `enabled` is false, so the fade
      // sits on the placed tab — fill, border and label together — and never
      // on the root.
      if (i === TAB_PANE_DISABLED_INDEX) {
        tab.opacity = dimVal(f.clickableStyle.disabledOpacity);
        // Hidden at rest AND bound to the BOOLEAN below, so the node and the
        // property's default say the same thing.
        tab.visible = false;
        disabledTab = tab;
      }
    }
    c.appendChild(bar);
    bar.counterAxisSizingMode = 'FIXED';
    bar.resize(bar.width, barHeight);
    bar.setBoundVariable('height', lk.size(barHeight));
    // Every tab is as tall as the bar, on both rows: `editorStrip`'s focused
    // face fills the strip (and covers its bottom line), and on `boxed` the
    // indicator lies on the bar's bottom edge — the widgets' chip fills the
    // bar the same way. FILL needs the bar's height fixed first, hence here.
    for (const tab of tabs) tab.layoutSizingVertical = 'FILL';

    // `editorStrip` renders the strip alone — the widget returns `bar` and
    // never builds a content panel. Omitting the node (rather than hiding a
    // card) is that tree: an empty panel is the hack the variant replaces.
    let contentLabel: TextNode | null = null;
    let contentPanel: FrameNode | null = null;
    let widest = bar.width;
    if (!stripOnly) {
      // The panel draws no chrome: the card (the root) owns the fill, the
      // edge and the corners, and the panel is the area under the bar.
      contentPanel = autoFrame('panel', 'VERTICAL');
      // g7-preview-only: the docs example pads its content with `CoreSpace.space20` on every side — the PANEL states no inset (content is a composition slot, and a panel padding field would double up on every caller that already pads), so the stand-in CONTENT is padded the way the example's content is, bound to `space/20` like the example's token. Without it a one-line panel at radius 12 reads as a pill and the designer judges a picture the docs never show.
      const content = panel('content', 'VERTICAL', lk, { pl: 20, pr: 20, pt: 20, pb: 20 });
      // The stand-in copy wears what the docs example hands the slot —
      // `Text(...).bodyMedium.onSurfaceVariant`, the role's own line height —
      // not the tab label's style: `contentTextStyle` reaches the tab labels
      // only, and the panel body is the caller's widget on both platforms.
      const contentType = textLabelOpts(lk, textStyleData({ role: 'bodyMedium' }), {
        color: 'on-surface-variant',
      });
      contentLabel = makeLabel(TAB_PANE_CONTENT, lk, contentType);
      content.appendChild(contentLabel);
      contentPanel.appendChild(content);
      content.layoutSizingHorizontal = 'FILL';
      c.appendChild(contentPanel);
      if (contentPanel.width > widest) widest = contentPanel.width;
    }
    // `crossAxisAlignment: .stretch` — bar and panel share one width. The
    // strip-only member has no panel, so the bar's own width is the member.
    // FILL is applied after the width is locked: a FILL child of a still-hugging
    // frame is not a width the lock can read.
    lockWidth(c, widest);
    bar.layoutSizingHorizontal = 'FILL';
    if (contentPanel !== null) contentPanel.layoutSizingHorizontal = 'FILL';
    painted.push({ contentLabel, disabledTab, tabs });
  }

  const set = mount.finish();
  // The panel's copy and the opt-in disabled tab are the strip's own. Each
  // tab's label, slots, count and close are its `TabPaneTab` instance's — so
  // every tab is EXPOSED: a placed TabPane lists each tab's own properties one
  // level in, the way `Tabs` surfaces its `TabItem`s, instead of a second home
  // for values the tab set already owns. After `finish()` and the binds,
  // because Figma rejects the flag on an instance with no component ancestor.
  const contentProp = defineProp(set, 'Content', 'TEXT', TAB_PANE_CONTENT);
  const showDisabledProp = defineProp(set, 'Show disabled tab', 'BOOLEAN', false);
  const allTabs: InstanceNode[] = [];
  for (const member of painted) {
    if (member.contentLabel !== null) bindTextProp(member.contentLabel, contentProp);
    if (member.disabledTab !== null) bindVisibleProp(member.disabledTab, showDisabledProp);
    allTabs.push(...member.tabs);
  }
  exposeAll(allTabs);
  vStackSet(set);
  return set;
}


// ─── Validated ───────────────────────────────────────────────────────────────

// Data-driven from coui_core VALIDATED: `fields.fieldMessageGapStyle` (the gap
// between the wrapped field and its message).
//
// `Validated` has no chrome of its own — it is a `Column` of the field it wraps
// and the message below it. So the honest drawing is exactly that column, with
// both children as instances of the components the widget composes
// (`needs: ['TextField', 'ValidatorHint']`): the field at its error variant,
// because `Validated` propagates the validation state down so the field paints
// its own error tone rather than stacking a second ring, and the hint at
// `error` to match.
//
// `validatorHintStyle` is a raw-forward partial — the child's resolver fills the
// rest — so the composed `ValidatorHint` instance is where those values belong,
// and its own builder already reads them from its own component data. That
// covers the two leaves where parent and child state the same token (icon size,
// icon/label gap), and it does NOT cover the one where they differ: the message
// role. `applyValidatorHintStyle` above writes the partial onto the instance and
// carries the whole argument for why, including why the note that used to sit
// here calling it unreachable had gone stale.
//
// Both slots are `W?`, and both are drawn as instances, so both get the full
// pair: INSTANCE_SWAP for "which component fills this", BOOLEAN for "is it
// filled at all" — `child` null is a bare message, `message` null (or `state`
// pending) is a bare field, and the widget renders each of those.
//
// The `Message` swap re-points the whole `ValidatorHint`, which is one node
// wider than the slot: the widget passes `message` *into* the hint
// (`ValidatorHint(message: message, type: …)`), so the hint is chrome
// `Validated` wraps around the slot rather than the slot itself. Figma has no
// finer handle here — the region that holds `message` on the canvas IS that
// instance, and the alternative is the slot having no property at all.
function buildValidated(page: PageNode, lk: VarLookup): ComponentNode {
  const f = VALIDATED.fields;
  const c = mint(page, 'Validated');
  applyPanelCompChrome(c, 'VERTICAL', lk, { gap: f.fieldMessageGapStyle.size });
  const owner = propertyOwner(c);

  const fieldVariant = bestVariantName(page, 'TextField', TEXT_FIELD_ERROR_MD);
  const field = instanceOf(page, 'TextField', fieldVariant);
  const fieldHolder = autoFrame('child', 'HORIZONTAL');
  fieldHolder.appendChild(field);
  c.appendChild(fieldHolder);

  const hintVariant = bestVariantName(page, 'ValidatorHint', VALIDATOR_HINT_ERROR);
  const hint = instanceOf(page, 'ValidatorHint', hintVariant);
  const hintHolder = autoFrame('message', 'HORIZONTAL');
  hintHolder.appendChild(hint);
  c.appendChild(hintHolder);
  // Before the width measurement below — the role override changes the label's
  // size, so it changes the instance's width, and `widest` has to see the value
  // that will actually be on the canvas.
  applyValidatorHintStyle(hint, lk, f.validatorHintStyle);

  // After the appends — a reference on a node that is not yet inside the
  // component throws, and that throw is not rolled back: the entry is reported
  // as failed and a half-drawn Validated stays on the page.
  bindVisibleProp(fieldHolder, defineProp(owner, 'Show child', 'BOOLEAN', true));
  bindSwapProp(
    field,
    defineProp(owner, 'Child', 'INSTANCE_SWAP', mainIdOf(page, 'TextField', fieldVariant)),
  );
  bindVisibleProp(hintHolder, defineProp(owner, 'Show message', 'BOOLEAN', true));
  bindSwapProp(
    hint,
    defineProp(
      owner,
      'Message',
      'INSTANCE_SWAP',
      mainIdOf(page, 'ValidatorHint', hintVariant),
    ),
  );

  // Measured off the instances, not the holders: a holder hugs its one child,
  // so the two agree, and the instance is the node whose width is real before
  // Figma has laid the frame out.
  const widest = field.width > hint.width ? field.width : hint.width;
  lockWidth(c, widest);
  fieldHolder.layoutSizingHorizontal = 'FILL';
  field.layoutSizingHorizontal = 'FILL';
  return c;
}

// ─── Form ────────────────────────────────────────────────────────────────────

// Data-driven from coui_core FORM: `fields.rowSpacing`.
//
// `Form` draws nothing — it is a `Column(spacing: rowSpacing)` around its
// children (plus a `Data.inherit` for the controller, which has no visual). Its
// one visual fact is therefore the gap between rows, and a gap is only visible
// as space *between things*, so the preview has to put something in that slot.
//
// What goes in it is `FormField`, instantiated (`needs: ['FormField']`). The
// slot is caller-supplied, so *some* choice is forced here; between the two
// candidates only one is the library's form row. `FormField` is the component
// that owns label + input + description/error, and both doc examples on this
// pair (`Form`'s and `FormField`'s) fill `Form.children` with exactly it. A
// bare `TextField` is what a `FormField` wraps — stacking those drew a Form
// whose rows had lost their labels, which is a shape no caller of this widget
// writes.
//
// `FormLabel` is NOT composed here — deliberately skipped, not overlooked,
// though the composition scan reports it against this component.
//
// `Form` never mentions it. The widget is a `Column` around caller-supplied
// children and nothing else; there is exactly one `FormLabel(` in the whole
// `components/form/form/` directory and it sits in `form_field.dart`, i.e. it
// is `FormField`'s composition, one level down. The scan attributes it here
// because `slug_of('Form')` is `form`, which globs that directory, and the
// directory holds `form.dart` and `form_field.dart` both.
//
// The edge has nowhere else to land: `slug_of('FormField')` is `form_field`
// and no directory by that name exists, so the component that actually
// composes the label is invisible to the scan and this one absorbs its edge.
// That is a property of the attribution, not something this builder can fix by
// drawing more.
//
// Composing it anyway would make the drawing *less* true, not more: a
// `FormLabel` appended straight to this column is a label belonging to no
// field, a node the `Form` widget has nowhere in its tree, and a row shape no
// caller of this widget writes. The label belongs to the row — where in the
// row, and whether that row reaches it as an instance or draws it, is the row
// component's decision to record, not this one's.
//
// Rows fill the width, matching `crossAxisAlignment: .stretch`.
//
// `primaryAction` / `secondaryAction` (2026-09-11): each is a `W?` slot with
// a documented single default — `Button()` (primary) / `Button(variant:
// .ghost)` — unlike `Dialog.actions` (a `List<W>?` with no single default,
// hence its pill stand-ins, overlay.ts), so these compose the real `Button`
// set (`needs: ['Button']`) rather than a look-alike. `Show actions` is the
// BOOLEAN gating the whole row (`showActions`, false by default — an
// existing `Form` gains no visual change until a caller opts in);
// `Show secondary action` (`showSecondaryAction`, true by default) hides
// just the secondary button — the primary has no toggle of its own, since
// a row without a primary action is simply `Show actions` off. `null` on
// either swap slot means "the design-system default button", never "no
// button". Property names follow the designer's own set on the canvas
// (`Primary action` / `Secondary action` / `Show secondary action`,
// 2026-09-11 결정: 캔버스 기준) — two-word props are spaced here like
// every other two-word prop in this registry. `actionSpacing` binds the
// row's own gap, mirroring `Dialog.actionSpacing`'s shape and the same
// right-aligned (`primaryAxisAlignItems: 'MAX'`) row.
function buildForm(page: PageNode, lk: VarLookup): ComponentNode {
  const c = mint(page, 'Form');
  applyPanelCompChrome(c, 'VERTICAL', lk, { gap: FORM.fields.rowSpacing });
  const rowVariant = bestVariantName(page, 'FormField', FORM_FIELD_DEFAULT);
  const rows: InstanceNode[] = [];
  let widest = 0;
  for (let i = 0; i < FORM_PREVIEW_ROWS; i++) {
    const row = instanceOf(page, 'FormField', rowVariant);
    c.appendChild(row);
    rows.push(row);
    if (row.width > widest) widest = row.width;
  }
  const actionsRow = autoFrame('actions', 'HORIZONTAL');
  actionsRow.setBoundVariable('itemSpacing', lk.space(dimVal(FORM.fields.actionSpacing)));
  actionsRow.primaryAxisAlignItems = 'MAX';
  c.appendChild(actionsRow);
  actionsRow.layoutSizingHorizontal = 'FILL';
  actionsRow.visible = false;
  const secondaryVariant = bestVariantName(page, 'Button', { Variant: 'ghost', Size: 'md' });
  const secondaryAction = instanceOf(page, 'Button', secondaryVariant);
  actionsRow.appendChild(secondaryAction);
  const primaryVariant = bestVariantName(page, 'Button', { Variant: 'primary', Size: 'md' });
  const primaryAction = instanceOf(page, 'Button', primaryVariant);
  actionsRow.appendChild(primaryAction);
  lockWidth(c, widest);
  for (const row of rows) row.layoutSizingHorizontal = 'FILL';
  const owner = propertyOwner(c);
  bindVisibleProp(actionsRow, defineProp(owner, 'Show actions', 'BOOLEAN', false));
  bindVisibleProp(secondaryAction, defineProp(owner, 'Show secondary action', 'BOOLEAN', true));
  bindSwapProp(
    secondaryAction,
    defineProp(owner, 'Secondary action', 'INSTANCE_SWAP', mainIdOf(page, 'Button', secondaryVariant)),
  );
  bindSwapProp(
    primaryAction,
    defineProp(owner, 'Primary action', 'INSTANCE_SWAP', mainIdOf(page, 'Button', primaryVariant)),
  );
  return c;
}

export const PRIMITIVES_DATA: RegistryEntry[] = [
  { section: 'Display', name: 'ChatBubble', build: buildChatBubble },
  { section: 'Display', name: 'RadialProgress', sizing: { width: 'fixed', height: 'fixed', why: 'size 토큰의 정사각형 — 위젯도 resolved.size 로 그린다' }, build: buildRadialProgress },
  { section: 'Display', name: 'AvatarGroup', build: buildAvatarGroup, needs: ['Avatar'] },
  { section: 'Display', name: 'AvatarBadge', build: buildAvatarBadge, needs: ['Icon'] },
  {
    section: 'Display',
    name: 'TabPaneTab',
    build: buildTabPaneTab,
    // A fragment of `CoreTabPaneStyle` — `CoreTabItem<W>` is a data value with
    // no Style of its own. The tab reads the strip's per-tab fields and the
    // variant rows; the bar, the band and the panel are the pane's.
    dataSlug: 'tab_pane',
    // `Badge` for the count a tab composes after its label (`CoreTabItem.badge`).
    needs: ['Badge', 'Icon'],
  },
  { section: 'Display', name: 'TabPane', build: buildTabPane, needs: ['TabPaneTab'] },
  { section: 'Display', name: 'Validated', build: buildValidated, needs: ['TextField', 'ValidatorHint'] },
  { section: 'Display', name: 'Form', build: buildForm, needs: ['FormField', 'Button'] },
];
