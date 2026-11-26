/// <reference types="@figma/plugin-typings" />

import { queueTextStyleAttach } from '../text-nodes';
import { setFieldValue } from '../field-value';

import {
  findComponentByName,
  LabelOpts,
  PadData,
  RegistryEntry,
  ShadowData,
  VarLookup,
  applyForwardedButtonStyle,
  applyPanelCompChrome,
  applySurfaceMaterial,
  autoFrame,
  pinAbsolute,
  bindAxisSize,
  bindPad,
  bindRadiusN,
  bindSize,
  bindTextProp,
  bindVisibleProp,
  borderData,
  defineProp,
  fillData,
  glyphPaint,
  labelColor,
  iconMainIdAt,
  instanceOf,
  lockWidth,
  makeIcon,
  glyphOpts,
  applyLetterSpacing,
  kPreserveGlyphPaint,
  makeLabel,
  mountSet,
  panel,
  setShadow,
  setSlotIcon,
  solid,
  textLabelOpts,
  typographyColorOpts,
  exposeAll,
  applyInstanceTextStyle,
  kFieldValueName,
  namedDescendant,
  hideInstanceLabel,
  instanceTextNode,
  pinInstanceBox,
} from '../helpers';
import { Color, Dim, colorData, dimVal, optField, textStyleData } from '../compat/v1';
import { setInstanceBoolNamed } from '../component-props';
import { parseVariantKey } from '../variant-safety';
import { kAmbientInkKey } from '../paint';
import { COMPONENTS } from '../data';
import {
  AxisName,
  axisSpecsOf,
  composeVariantName,
  enumerateAxisCombos,
  isAxisAtRest,
} from '../axis-combos';

const COLOR_PICKER = COMPONENTS.color_picker;
const DATE_PICKER = COMPONENTS.date_picker;
const TIME_PICKER = COMPONENTS.time_picker;
// The dialog both pickers push in their dialog mode — read only for the member
// it rests on.
const DIALOG = COMPONENTS.dialog;
const CALENDAR = COMPONENTS.calendar;

// Which size step each composed child renders at, read off the widgets rather
// than picked here:
//
//   md — both picker triggers (`Button(variant: …)` with no `size:`, so
//        Button's own `CoreComponentSize.md` default), TimePicker's popover
//        am/pm + action buttons (also no `size:`), and every composed
//        `TextField` (`text_field.dart` declares `size = CoreComponentSize.md`).
//   sm — every Calendar button (nav arrow, header title, date cell) and every
//        ColorPicker popover button (mode tab, eyedropper, Cancel, Save); all
//        of them pass `size: .sm` explicitly.
const kTriggerButtonSize = 'md';
const kCalendarButtonSize = 'sm';
const kPopoverButtonSize = 'sm';
const kFieldSize = 'md';
// `CoreColorPickerContract.defaultModeInputSize` — the picker panel's HEX and
// channel inputs.
const kModeInputSize = 'sm';

// The composed `Button`'s own size row: an icon-only Button needs that size's
// height to stay square. Dot access, not `defaultsBySize['md']`: the axis
// collapse this repo ratchets on is a builder spending one key of *its own*
// dispatch table and losing an axis the canvas would otherwise show; this use
// site genuinely renders at one size, and `Button` itself enumerates all six.
const BUTTON_SM = COMPONENTS.button.sizes.defaultsBySize.sm;
// What a disabled picker's glyph wears. Neither picker states a colour for it:
// both resolvers leave the glyph untinted, so the composed child's own disabled
// foreground applies — the default text field's, for both pickers' trigger.
const TEXT_FIELD_DISABLED_FOREGROUND =
  COMPONENTS.text_field.variants.defaultsByVariant.default.disabledForegroundColor;

// Demo copy for the `W?` slots below. Each is what the widget shows when the
// caller fills the slot with the obvious thing — the DatePicker placeholder
// mirrors its localization default (`placeholderDatePicker`); the ColorPicker
// placeholder is demo copy for its `W?` slot, not a localization string; the
// dialog titles name the prompt they head.
const kColorPickerDialogTitle = '색 선택';
const kColorPickerPlaceholder = '고른 색이 없어요';
// The panel's recent-colours title — the `ko` value of `colorPickerRecentTitle`.
const kColorPickerRecentTitle = '최근 사용';
// The HEX cell caption — `kColorPickerHexLabel` in `core_color_math.dart`, the
// same in every locale.
const kColorPickerHexLabel = 'HEX';
// The draft colour the preview stands at — `_draftHex`. The hex input shows it,
// and the saturation ramp is built from its hue the way the widget builds it
// (`_hue = rgbToHsv(hexToRgb(_draftHex)).h`), so the two agree by construction
// instead of by someone remembering to change both.
const kColorPickerDraftHex = '#6750A4';
// The inline comparison cell's "previous" half — an example colour beside the
// draft, so the two halves read as two colours.
const kColorPickerPreviousHex = '#3488EC';
const kDatePickerPlaceholder = '날짜를 선택해 주세요';
const kDatePickerDialogTitle = '날짜 선택';
const kTimePickerDialogTitle = '시간 선택';
// `label` — DatePicker's own `String?`, null by default, so the property below
// ships switched off. Demo copy rather than a localization default: this slot
// takes the caller's own field name, and the widget has no fallback for it
// (unlike `placeholderDatePicker`).
const kDatePickerLabel = '날짜';
const kDatePickerDescription = '오늘 이후 날짜만 고를 수 있어요.';
// `localizations.timeHour` / `timeMinute` — the captions `_buildSegmentField`
// puts under each segment box. The Korean chrome strings
// (`coui_i10n/chrome/i18n/ko.i18n.json`), the locale the canvas is drawn in.
const kTimeHourCaption = '시';
const kTimeMinuteCaption = '분';
// The example time every TimePicker drawing stands at — 14:30, shown the way
// the widget shows it on a 12-hour clock (`use24HourFormat` falls back to the
// platform's, which is 12-hour by default): the trigger reads
// `_formatDisplayValue` ("오후 02:30" — the Korean locale's
// `clockWithPeriod`, `coui_i10n/chrome/i18n/ko.i18n.json`), the panel's hour segment the 12-hour
// digits, and the am/pm toggle rests on PM. A 24-hour "14" beside an AM/PM
// toggle is a value the widget never draws.
const kTimeExampleHour = '02';
const kTimeExampleMinute = '30';
const kTimeExampleDisplay = '오후 02:30';
// `ToggleGroup` ordinal of PM — the toggle's items are `[AM, PM]`.
const kTimeExamplePeriodOrdinal = '2';

// ─── Optional `W?` slots ─────────────────────────────────────────────────────
//
// A contract slot typed `W?` takes any widget and defaults to null. Without a
// component property the builder's demo content IS the slot: whatever these
// pickers happened to draw is the only thing it could ever hold, and a designer
// reads it as the component rather than as a placeholder.
//
// Each of these slots renders as words (`dialogTitle` heads a prompt,
// `placeholder`/`placeholderWidget` stand in for an unset value), so the
// property is TEXT — swapping would want a `Text` component in the REGISTRY and
// that decision was made the other way. The BOOLEAN beside it is the null: the
// slot ships switched off, exactly as the contract defaults it.

interface SlotRef {
  /** The whole node the slot renders as — carries the BOOLEAN. */
  node: FrameNode;
  /** The copy inside it — carries the TEXT. */
  label: TextNode;
}

// Two nodes rather than one, and that is forced rather than chosen:
// `componentPropertyReferences` is a single object per node, so binding both
// `characters` and `visible` to the same node leaves only whichever ran last —
// the property that lost still shows in the panel and changes nothing when
// edited. The wrapper takes `visible`, the label inside it takes `characters`.
function optionalTextSlot(
  lk: VarLookup,
  name: string,
  text: string,
  opts: LabelOpts,
  // The `Gap` that follows the words INSIDE the same wrapper, when the widget
  // interleaves one and the slot's absence takes it away too — DatePicker's
  // `if (label != null) { …Text(label), Gap(labelBottomGapStyle) }` is both
  // children of one `if`, so a gap left outside would still space the trigger away
  // from the label that is not there.
  trailingGap?: number,
  // The same thing on the other side, for a slot the widget spaces from what
  // comes BEFORE it — DatePicker's `else if (description != null) { …Gap(
  // descriptionTopGapStyle), Text(description) }`, where the gap precedes the
  // words and belongs to the same `if`.
  leadingGap?: number,
): SlotRef {
  const stacked = trailingGap != null || leadingGap != null;
  const box = autoFrame(name, stacked ? 'VERTICAL' : 'HORIZONTAL');
  if (leadingGap != null) {
    const gap = panel('gap', 'HORIZONTAL', lk, {});
    box.appendChild(gap);
    bindSize(gap, lk, leadingGap, leadingGap);
  }
  const label = makeLabel(text, lk, opts);
  box.appendChild(label);
  if (trailingGap != null) {
    const gap = panel('gap', 'HORIZONTAL', lk, {});
    box.appendChild(gap);
    bindSize(gap, lk, trailingGap, trailingGap);
  }
  box.visible = false;
  return { node: box, label };
}

// Binds one slot's pair across every variant that draws it.
//
// Called AFTER `mountSet().finish()` on purpose, twice over: a component
// property belongs to the SET, which does not exist until then, and Figma
// rejects `componentPropertyReferences` on a node that is not inside a
// component yet ("Can only set component property references on symbol
// sublayer") — that throw fails the entry and leaves the component half-built
// on the page, looking finished until the next run blanks it.
function bindOptionalTextSlot(
  refs: readonly SlotRef[],
  showId: string | null,
  textId: string | null,
): void {
  // Declaring is not binding. The ids arrive already defined — a caller whose
  // loop stopped producing refs would leave two properties on the panel that
  // move nothing when edited, and every other signal would stay green (the
  // swappability guard reads the `defineProp` call, not the binding). Loud
  // here, where the failure is named in the run log, rather than quiet, where
  // the component looks right and moves nothing.
  if (refs.length === 0) {
    throw new Error(
      'bindOptionalTextSlot: no nodes to bind — the slot property would be ' +
        'declared and inert. Push a SlotRef for every variant that draws it.',
    );
  }
  for (const ref of refs) {
    bindVisibleProp(ref.node, showId);
    bindTextProp(ref.label, textId);
  }
}

// ─── Composing a registered child ────────────────────────────────────────────

// How many of a variant name's axes are away from rest (`Hover=true`,
// `State=pressed`, …).
//
// What each axis rests at is `axis-combos.ts`'s table, not a rule spelled here.
// Two files used to spell it and both spelled it as "which boolean means off",
// which was right until `Button` put its poses on one `State=` enum — `enabled`
// and `hover` are both "not true", so this counter scored them the same and the
// sort below could hand back a pre-hovered child. The note over that table
// records the rest.
function activeAxisCount(variantName: string): number {
  let n = 0;
  for (const [axis, value] of Object.entries(parseVariantKey(variantName))) {
    if (!isAxisAtRest(axis, value)) n += 1;
  }
  return n;
}

// The name of the variant of `setName` that carries every axis in `want`.
//
// Deliberately not the full variant name spelled out at the call site: a full
// name has to name every axis the child has, so it throws whenever the child's
// axis set changes for reasons that have nothing to do with this component.
// Matching only the axes this use site cares about survives that — which is not
// hypothetical, since `Button` has already traded three boolean pose axes for
// one `State=` enum without a single call site here needing an edit.
//
// Stricter than `bestVariantName` on one point, and that point is the whole
// reason this exists: among the variants that match equally well it returns the
// RESTING one (fewest axes away from rest — see `activeAxisCount`, which reads
// the shared table rather than guessing which value means "off"), so a child's
// hovered or disabled variant is never handed out because it happened to sort
// first.
//
// A caller that WANTS the non-resting row names it in `want` — `buildDatePicker`
// asks for `State=disabled` on its disabled variant, because the widget hands
// its own `enabled` to that child rather than repainting it here.
//
// `undefined` when the child is a single COMPONENT with no axes to match —
// `instanceOf` ignores the name in that case, and raises the "declare
// needs: […]" error when the name is not on the page at all.
function restingVariantName(
  page: PageNode,
  setName: string,
  want: Record<string, string>,
): string | undefined {
  const found = findComponentByName(page, setName);
  const set = found && found.type === 'COMPONENT_SET' ? found : undefined;
  if (!set) return undefined;
  const members = set.children.filter((c): c is ComponentNode => c.type === 'COMPONENT');
  const matches = members.filter((c) => {
    const axes = parseVariantKey(c.name);
    for (const axis of Object.keys(want)) {
      if (axes[axis] !== want[axis]) return false;
    }
    return true;
  });
  if (matches.length === 0) {
    throw new Error(
      `restingVariantName('${setName}', ${JSON.stringify(want)}): no variant carries those ` +
        `axes, so this builder has nothing to compose. Variants present: ` +
        `${members.map((c) => c.name).join(' | ')}`,
    );
  }
  return matches.slice().sort((a, b) => {
    const byAxes = activeAxisCount(a.name) - activeAxisCount(b.name);
    if (byAxes !== 0) return byAxes;
    return a.name < b.name ? -1 : a.name > b.name ? 1 : 0;
  })[0].name;
}

// `instanceTextNode` / `hideInstanceLabel` / `pinInstanceBox` live in
// `composed-instance.ts`, shared with `display-data.ts`'s icon affordances.

// The property names the composed children declare for the copy this file
// writes into them — `Button`'s label, the two that decide what a `TextField`
// reads as, and `Dialog`'s heading. Spelled once each, so a child's rename is
// one line here rather than however many call sites reached for the name.
//
// `Placeholder` is not among them on purpose: the widget behind every field here
// has no placeholder, so its node is hidden and its copy stays the component's
// own default. See `setFieldValue`.
const kButtonLabelProp = 'Child';
const kDialogTitleProp = 'Title';

// And the two frames inside `TextField` a segment has to reach past its
// properties: the stack that holds the placeholder, and the absolute holder the
// value rides in. Spelled here beside the property names for the same reason —
// one line to change when the child's builder renames one.

// Puts copy into a NAMED TEXT property of a composed instance.
//
// Named, never "whichever TEXT property comes first". A child's property list
// belongs to its own builder and it grows in that builder's order, so "first"
// is not a name — `Dialog` declares `Title` AND `Content`, `TextField`
// declares `Placeholder` AND `Value text`, and in both pairs the one that
// happens to sort first is not the one a caller means. Taking the first cost
// every picker its value: the hex, all three RGB channels and both clock
// segments were written to `TextField`'s `Placeholder`, so each field showed
// its value as a *hint*, in the hint's muted `affixColor`, while `Value text`
// kept the literal word `Value`. Nothing reported it — `Placeholder#0:0` is a
// legitimate key, so all fourteen `setProperties` calls succeeded.
//
// Falls back to the instance's first text node only where a platform models no
// component properties at all; writing a node inside an instance is the same
// override `repaintGlyph` already performs on every icon instance.
function setInstanceTextNamed(inst: InstanceNode, name: string, text: string): void {
  const props: ComponentProperties | undefined = inst.componentProperties;
  if (props && typeof inst.setProperties === 'function') {
    for (const key of Object.keys(props)) {
      if (key.split('#')[0].toLowerCase() === name.toLowerCase() && props[key].type === 'TEXT') {
        const patch: { [k: string]: string } = {};
        patch[key] = text;
        inst.setProperties(patch);
        return;
      }
    }
  }
  const node = instanceTextNode(inst);
  if (node) node.characters = text;
}


// The `field` ROW inside a composed `TextField` — the node that actually holds
// its chrome.
//
// `TextField`'s component root paints nothing (`comp.fills = []`); the fill, the
// stroke and the radius all live one level in, on the row the widget's
// `Container(decoration:)` wraps. Reaching for the root instead is the obvious
// move and the one that leaves no trace when it misses: writing empty over empty
// looks done, and the row keeps its surface and its 1px outline border —
// a second rounded box inset in every segment, on a canvas that already drew the
// boundary.
//
// Found by which child is PAINTED rather than by name, and unpainted children
// are skipped: `TextField`'s label holder carries a `visible` component-property
// binding, and a parent that writes on a bound node is writing the override that
// property exists to write — the decoupling that costs a composition its child.
//
// Throws on anything but exactly one, in both directions. A helper that silently
// does nothing when its target moved is the failure this file's own docstrings
// condemn; and more-than-one is the direction this will drift — `TextField`'s
// description / errorText rows are not built yet, and when they are a positional
// sweep would strip them from every segment.
function paintedFieldRow(inst: InstanceNode): FrameNode {
  const painted: FrameNode[] = [];
  for (const kid of inst.children) {
    if (kid.type !== 'FRAME') continue;
    const fills = kid.fills;
    const hasPaint = (Array.isArray(fills) ? fills.length : 1) > 0 || kid.strokes.length > 0;
    if (hasPaint) painted.push(kid);
  }
  if (painted.length !== 1) {
    throw new Error(
      `paintedFieldRow: expected exactly one painted FRAME child on ` +
        `${inst.name}, found ${painted.length}. TextField's inner shape ` +
        'changed — name the row instead of sweeping direct children.',
    );
  }
  return painted[0];
}


// `padding: .zero`, as a bound inset rather than four raw zeros.
//
// Raw assignment would not do it: `TextField` BINDS its row's four insets to
// space Variables, and a plain write leaves the binding in place and the padding
// where it was. So the zero has to arrive as `Primitives/space/0`, which is what
// `CoreEdgeInsets.zero` is.
const kZeroInset: PadData = { l: 0, r: 0, t: 0, b: 0 };

// Re-styles an existing TEXT node from the same `LabelOpts` `makeLabel` consumes.
//
// Needed because the node cannot be re-created: it lives inside an instance, and
// Figma reparents nothing into one. The write itself is the ordinary instance
// override — the same one `appendTimeTrigger` already performs on a composed field's
// label, and the same one a designer's override panel writes by hand.
function restyleText(text: TextNode, lk: VarLookup, o: LabelOpts): void {
  const size = dimVal(o.size);
  text.fontName = { family: lk.fontFamilyName('sans'), style: o.style ?? 'Regular' };
  text.setBoundVariable('fontFamily', lk.fontFamily('sans'));
  text.fontSize = size;
  const sizeVar = o.sizeScale === 'size' ? lk.sizeOrNull(size) : lk.fontSizeOrNull(size);
  // Bound when the step exists, literal otherwise — `makeLabel`'s own rule, and
  // for its reason: a throw is not rolled back — the entry is reported as
  // failed and a half-drawn component is left on the page, which is worse than
  // one unbound number.
  if (sizeVar) text.setBoundVariable('fontSize', sizeVar);
  // The tracking follows the size for the reason `applyLetterSpacing` states:
  // the pixels are a ratio times this size, so a re-size that does not re-write
  // them leaves the previous rung's width on the new rung's letters. The role is
  // dropped for a dimension-ladder glyph, the same exclusion the line above
  // makes for the size variable and `makeLabel` makes for both.
  applyLetterSpacing(text, lk, {
    em: o.letterSpacingEm,
    size: size,
    role: o.sizeScale === 'size' ? null : o.role,
  });
  if (o.lineHeightPercent != null) {
    text.lineHeight = { unit: 'PERCENT', value: o.lineHeightPercent };
  }
  if (o.rawColor) {
    text.fills = [{ type: 'SOLID', color: o.rawColor, opacity: o.opacity ?? 1 }];
  } else if (o.colorVar) {
    text.fills = [solid(o.colorVar, o.opacity ?? 1)];
  }
}

// The whole forwarded `CoreTextFieldStyle` a time segment hands its `TextField`,
// applied to the composed instance.
//
// `_buildSegmentField` states six things about that field, and until now this
// builder honoured three of them. The three it skipped are the ones a reader
// sees first: `textAlign: .center`, `padding: .zero`, and
// `valueStyle: valueTypography.copyWith(color: segmentContentColor)` — the
// value role against `TextField`'s own 14. The digits drew at 14, at the
// left edge of a 72px box, inside a 240px-wide row spilling out of it. Two clock
// segments read as two empty boxes with small grey text loose in the corner.
//
// The row is resized to the segment, and that is the widget's geometry rather
// than a number picked here: the box is `segmentSize` square, its child is
// centred, and the chromeless field has nothing of its own to be — no padding,
// no boundary. Without the resize the 44px line box overflows a 40px row that
// clips, which trades small digits for cropped ones.
//
// Exactly one string draws, and the earlier attempt to draw two is what put a
// ghost on the canvas. `TextField` stacks the placeholder and the value at one
// origin behind a `Visibility(maintainSize: true)`: when a value exists the
// placeholder is *invisible* and only the editable is read. Styling both to 44
// and giving them the same copy — hoping they register — produced digits with a
// second offset copy behind them, because they cannot register: the placeholder
// is the in-flow child (so it centres in the square) while the value rides
// absolute at the stack's origin, and the value's holder had already been
// resized to its 14px height before the restyle made its text 44, so the big
// text drew from a small box's top. Two failures at once, both invisible to a
// gate: the canvas held a component and every value it states was correct.
//
// So the placeholder is hidden and the value comes into flow. The reserved
// space `maintainSize` gives it is not needed here — the segment box is a fixed
// square with both axes centred, so what the stack hugs only has to be the one
// line box that shows.
function applyChromelessSegmentField(
  inst: InstanceNode,
  lk: VarLookup,
  o: { width: number; height: number; value: LabelOpts },
): void {
  const row = paintedFieldRow(inst);
  // `backgroundColor: .transparent, borderColor: .transparent, borderWidth: 0`.
  row.fills = [];
  row.strokes = [];
  bindPad(row, lk, kZeroInset);
  // `Container(alignment: .center)` around it, `textAlign: .center` inside it.
  row.primaryAxisAlignItems = 'CENTER';
  row.counterAxisAlignItems = 'CENTER';
  bindSize(row, lk, o.width, o.height);

  // The value only — the placeholder is already hidden and the value already in
  // flow, both by `setFieldValue`, which every composed field goes through. That
  // is also what deleted the `constraints` this used to set, the override that
  // killed the whole entry twice because Figma refuses it anywhere inside an
  // instance's subtree, not just on the instance itself:
  //
  //   in set_constraints: This property cannot be overridden in an instance
  //
  // A flow child at HUG needs no pin: it is measured after the restyle rather
  // than before it (which is what drew 44px text from a 14px box's top) and it
  // centres because the square centres both axes.
  //
  // Walked from the frame rather than filtered by `parent` identity: a test
  // double hands children back through a Proxy, so `child.parent === holder` is
  // false there while being true in Figma — a comparison that would style
  // nothing in the harness and everything on the canvas.
  const value = namedDescendant(inst, kFieldValueName);
  let styled = 0;
  for (const node of value.children) {
    if (node.type !== 'TEXT') continue;
    restyleText(node, lk, o.value);
    // The layer is the composed `TextField` main's value text, named after its
    // sample copy (`hello@cocode.im`); the segment draws its own digits, so the
    // layer panel should read the slot, not the sample (#6272). Not
    // `kFieldValueName`: that is the holder frame's name, which
    // `namedDescendant` and `setFieldValue` look the field up by.
    node.name = 'digits';
    node.textAlignHorizontal = 'CENTER';
    node.layoutSizingHorizontal = 'FILL';
    // The digits are a composed `TextField`'s label restyled in place, so
    // `makeLabel`'s queue never sees them: queue the admitted role here, the
    // way a composed trigger label is (`queueTextStyleAttach`), so the
    // segment wears the role's text style instead of loose metrics (#6201).
    if (o.value.role != null) queueTextStyleAttach(node, o.value.role);
    styled += 1;
  }
  // Loud for the same reason `setFieldValue` is: digits left at `TextField`'s own
  // 14 in a 72px square are green in every other signal here.
  if (styled !== 1) {
    throw new Error(
      `applyChromelessSegmentField: styled ${styled} text node(s) in ` +
        `'${kFieldValueName}' on ${inst.name}, wanted 1. TextField's input ` +
        'stack changed shape.',
    );
  }
}

// A glyph that has to sit INSIDE a composed instance's box.
//
// Figma refuses to add a child to an instance — an instance mirrors its main's
// subtree, and the API states outright that a node "that cannot be reparented,
// such as children of instances" is off limits. So the glyph rides above the
// instance as an absolutely-positioned sibling inside the host frame. That is
// what lets a `Button(trailing: Icon(…))` trigger and an icon-only button be
// real instances at all instead of hand-drawn boxes that never follow `Button`.
//
// The other route is `Button`'s own trailing slot (its builder exposes a
// BOOLEAN + INSTANCE_SWAP pair for it), and it is the better one — but it means
// writing property ids that another builder owns and that the runtime harness
// cannot exercise, because the harness models component properties on a main
// component and not on an instance. An untested override that resolves to
// `undefined` fails by drawing the wrong glyph, silently, which is the exact
// failure mode this epic keeps paying for. Overlay now, slot when the property
// contract is committed and checkable.
function overlayChild(
  host: FrameNode | ComponentNode,
  node: FrameNode | InstanceNode,
  x: number,
  y: number,
  horizontal: 'MIN' | 'CENTER' | 'MAX',
): void {
  pinAbsolute(host, node, x, y, {
    horizontal: horizontal,
    vertical: 'CENTER',
  });
}

function overlayIcon(
  host: FrameNode | ComponentNode,
  icon: InstanceNode,
  x: number,
  y: number,
  horizontal: 'CENTER' | 'MAX',
): void {
  overlayChild(host, icon, x, y, horizontal);
}

// A composed icon-only `Button` — the widget's `Button(child: Icon(…))` shape,
// which both the calendar's nav arrows and the picker's eyedropper have.
//
// A host frame rather than the bare instance, because of the reparent rule
// above: the Button is the instance, the glyph is its absolutely-positioned
// sibling, and the frame is what holds the two together in one layout slot.
function iconButton(
  page: PageNode,
  lk: VarLookup,
  o: {
    variant: string;
    size: string;
    icon: string;
    iconSize: number;
    colorVar: Variable;
    /** Square side when the caller's layout fixes it (a calendar cell). */
    side?: number;
    /** The forwarded `CoreButtonStyle`'s inset and corner, as the slot states
     *  them — passed whole to `applyForwardedButtonStyle` rather than picked
     *  apart here, so a field the parent leaves null keeps `Button`'s own. */
    pad?: PadData;
    borderRadius?: { topLeft: number | Dim };
  },
): FrameNode {
  const host = panel('icon button', 'HORIZONTAL', lk, {});
  const button = instanceOf(
    page,
    'Button',
    restingVariantName(page, 'Button', { Variant: o.variant, Size: o.size }),
  );
  host.appendChild(button);
  hideInstanceLabel(button);
  applyForwardedButtonStyle(button, lk, { padding: o.pad, borderRadius: o.borderRadius });
  if (o.side != null) pinInstanceBox(button, o.side, o.side);
  const glyph = makeIcon(o.icon, lk, { size: o.iconSize, colorVar: o.colorVar });
  overlayIcon(
    host,
    glyph,
    (button.width - o.iconSize) / 2,
    (button.height - o.iconSize) / 2,
    'CENTER',
  );
  return host;
}

// A composed `TextField` instance for one of the pickers' input slots.
//
// Every one of them takes `TextField`'s own default size (`text_field.dart`
// declares `size = CoreComponentSize.md`; none of the call sites pass `size:`),
// and every one is exposed so the field's own properties — placeholder, prefix
// and suffix slots — reach the parent's panel. A top-level TEXT property on the
// picker could not do that: the copy lives on the child, not on us.
// Instances whose own properties should surface on the picker's panel. Filled
// during construction, flushed by `exposeAll` once the component root exists —
// see that helper for why the write cannot happen here.
//
// Module-level, shared by the three pickers, and that sharing is a hazard: a
// builder that throws after pushing leaves its instances here, and the NEXT
// picker's flush then writes `isExposedInstance` on nodes that belong to a
// half-drawn entry — Figma refuses ("Instance must be contained within a
// component"), that picker fails too, its own list stays unflushed, and the
// third picker falls the same way. ColorPicker's `setSlotIcon` throw took
// DatePicker and TimePicker down exactly like that, in registry order. So each
// builder starts by dropping whatever a failed predecessor left; the
// `length = 0` after every flush is the same guard for the success path.
const pendingExposed: InstanceNode[] = [];

// Every picker's first line — see the note on `pendingExposed`.
function dropStaleExposes(): void {
  pendingExposed.length = 0;
}

// `Variant=defaultVariant`, not `Variant=Default`: the member spelling is
// `CoreTextFieldVariant`'s own source spelling, which avoids the Dart reserved
// word (`defaultVariant` / `error`) — the same shape `Alert` and `Banner` carry
// (`default_`). `enabled` picks that child's `State` rung, because the pickers
// hand their own `enabled` to it (`TextField(… enabled: _isEnabled)`). `State`,
// not `Enabled`: the child's poses live on one enum (see `kTextFieldStates`),
// and `restingVariantName` demands every axis it is given — an `Enabled` key
// would match no member and throw.
function textFieldInstance(
  page: PageNode,
  value: string,
  enabled = true,
  state?: string,
  variant = 'defaultVariant',
  size: string = kFieldSize,
): InstanceNode {
  const field = instanceOf(
    page,
    'TextField',
    restingVariantName(page, 'TextField', {
      Variant: variant,
      Size: size,
      State: state ?? (enabled ? 'enabled' : 'disabled'),
    }),
  );
  setFieldValue(field, value);
  pendingExposed.push(field);
  return field;
}

// A composed `Button` instance that carries a label — mode tabs, dialog
// actions, the am/pm pair.
function labelButton(
  page: PageNode,
  o: { variant: string; size: string; label: string },
): InstanceNode {
  const button = instanceOf(
    page,
    'Button',
    restingVariantName(page, 'Button', { Variant: o.variant, Size: o.size }),
  );
  setInstanceTextNamed(button, kButtonLabelProp, o.label);
  return button;
}

// ─── The popover: a composed wrapper + a drawn panel ─────────────────────────
//
// All three pickers wrap their content in `Popover`, and that edge is composed
// — `appendPopoverWrapper` below puts a real instance in every picker. What
// stays hand-drawn is the PANEL, and only because in Figma a panel and its
// content are one node: an instance mirrors its main's subtree and refuses
// added children, so a `Popover` instance cannot hold the `Calendar` instance,
// the segmented time row, or the colour column.
//
// Replacing the panel with the instance — deleting the drawn version, as the
// composition rule asks — is measurably a wash, not a matter of taste: each
// picker's only instance of its panel's content lives INSIDE that panel, so the
// swap trades one composed child for another. DatePicker's only `Calendar` is
// the one below; TimePicker's only `TextField`s are its hour/minute segments;
// ColorPicker's only `Button`s are its mode tabs, its eyedropper and its
// Cancel/Save pair. Each would trade `Popover` for exactly one of those and
// land a designer on `Popup`'s empty `Content` slot where a calendar used to
// be — the same falsehood the rule exists to remove, pointed the other way.
// Drawing both instead paints the box twice, which is worse than either; hence
// the wrapper is composed hidden and the panel is drawn.
//
// The unblock is now on this side: `Popup` (primitives-chrome.ts) draws
// `children` as a `Content` INSTANCE_SWAP slot, so the panel can be a real
// `Popup` instance — the slot hidden and the picker's column laid over it the
// way `Menu` lays its rows, or, for DatePicker, the slot swapped to the
// registered `Calendar` outright.
//
// What the panel below IS faithful about is where its chrome comes from: it is
// read from the picker's own forwarded `popoverStyle.panelStyle` slot
// (`CorePopupStyle`), which is the single source the widget hands `Popover` at
// the call site. That claim used to be only three-quarters true, and the
// missing quarter is exactly the drift a fork is predicted to grow: `Popup`
// casts `CoreShadow.md` and these panels cast nothing, so every picker's open
// popover sat flush against the page while the app floated it. The shadow is
// read here now, from the same forwarded slot, tinted by its own
// `shadowBaseColor` — the same pair, in the same order, `buildPopup` applies.
//
// `minWidth` is applied when the forwarded slot actually names a step, and
// skipped when it does not. TimePicker forwards `CoreSpace.space128` — the
// same 128 `Popup` binds — while ColorPicker and DatePicker forward 0 with no
// token behind it. Binding the 0 would assert a Primitives step the slot never
// named; skipping the 128 drops one the slot does name, which is the same
// fork-drift as the missing shadow one field over. The `ref` decides, not a
// blanket rule about the three pickers.
//
// `spacing` is read and never applied: all three forward 0, and a 0 gap would
// collapse the column, so the caller's own content gap (`popoverSpacing` /
// `actionRowGapStyle` / `descriptionTopGapStyle`) stands in its place.
function popoverPanel(
  lk: VarLookup,
  name: string,
  panelStyle: {
    backgroundColor: Color;
    borderColor: Color;
    borderWidth: Dim;
    borderRadius: { topLeft: Dim };
    padding: PadData;
    boxShadow: ShadowData;
    shadowBaseColor: Color;
    minWidth: Dim;
  },
  gap: number,
): FrameNode {
  const box = panel(name, 'VERTICAL', lk, { gap });
  // The box is the composed `Popup`'s (`Popover` → `Popup` on both platforms),
  // a functional surface that takes the rim — drawn here, so it wears the
  // material here.
  applySurfaceMaterial(box, lk, colorData(panelStyle.backgroundColor), 'functional', {
    radius: panelStyle.borderRadius.topLeft,
    rim: true,
  });
  borderData(box, lk, colorData(panelStyle.borderColor), dimVal(panelStyle.borderWidth));
  bindRadiusN(box, lk, panelStyle.borderRadius.topLeft);
  bindPad(box, lk, panelStyle.padding);
  setShadow(box, panelStyle.boxShadow, lk, colorData(panelStyle.shadowBaseColor));
  // Bound only when the forwarded slot names a token — see the header. A
  // literal 0 here would be this builder inventing a constraint.
  const minWidthRef = typeof panelStyle.minWidth === 'object' ? panelStyle.minWidth.ref : null;
  if (minWidthRef != null) {
    box.minWidth = dimVal(panelStyle.minWidth);
    box.setBoundVariable('minWidth', lk.spaceLadder(dimVal(panelStyle.minWidth)));
  }
  return box;
}

// The `Popover` wrapper itself, as a real INSTANCE — the composition edge the
// panel above cannot carry.
//
// Two things are true at once and both have to be expressed: the panel is the
// only node that can hold the picker's content, and the wrapper is a real child
// the widget builds. The panel above answers the first (and tracks `Popup`
// through the forwarded `panelStyle` data, shadow included). This answers the
// second.
//
// SIBLING, because Figma reparents nothing into an instance — `Popover`'s
// component owns its own trigger holder and its own `Popup`, and neither this
// picker's trigger nor its panel can move inside them. ABSOLUTE, so the column
// it cannot be the parent of is not reflowed by it. HIDDEN, because `Popover`
// renders a trigger AND a panel and this picker already draws both: visible, it
// would stand a second, generic trigger beside the real one and an empty
// `Popup` behind the populated panel — the double draw that is worse than not
// composing. Invisible it costs the canvas nothing (auto-layout skips hidden
// children) while a designer who toggles the layer reaches the actual
// `Popover`, which is the point of composing it rather than describing it.
//
// Same shape `Select` / `Autocomplete` / `Fab` (form-controls.ts) and
// `PhoneInput` (form-fields.ts) ship for the same wrapper; keeping it identical
// is deliberate, since a picker that omitted it would differ from its four
// siblings for no reason a designer could find.
//
// Deliberately NOT repainted from `popoverStyle.panelStyle`: that forward is
// already consumed by `popoverPanel`, on the node that actually holds the
// content. Asserting it a second time on this instance's nested `Popup` would
// be one value claimed from two places.
function appendPopoverWrapper(page: PageNode, host: ComponentNode): void {
  const popover = instanceOf(page, 'Popover');
  popover.name = 'Popover';
  // The line that failed the ColorPicker and TimePicker entries, leaving both
  // half-drawn — `layoutPositioning` on an instance — while DatePicker, calling
  // this same function, built. Routed through `pinAbsolute` so the pin lands on
  // a holder frame and the outcome stops depending on which component got there
  // first.
  pinAbsolute(host, popover, 0, 0, { horizontal: 'MIN', vertical: 'MIN' }).visible = false;
}

// ─── Gradients (ColorPicker's two ramps) ─────────────────────────────────────
//
// Both of ColorPicker's bands are gradients in the widget, and both were flat
// semantic fills here — the hue slider `secondary`, the saturation/value square
// `primary`. The comment that stood over them said no token "nor any Figma
// Variable" could express a ramp, which is true of a Variable and beside the
// point: a gradient is not a variable, it is a PAINT. `GRADIENT_LINEAR` carries
// its own stop list and `fills` takes it exactly where it takes a `SolidPaint`.
//
// The distinction that matters is what each band asserts. A single `secondary`
// fill does not read as "a spectrum stands here" — it reads as a picker that
// resolved to one colour, and a designer who samples that node gets a design
// token where the hue circle belongs. What genuinely stays data is the DRAFT
// colour (`_draftHex`), which the trigger swatch already stands in for.

// Figma's gradient runs along x in the paint's own space, and
// `gradientTransform` is what maps the node into that space. The identity first
// row reads x and leaves the ramp horizontal — Flutter's `begin: .centerLeft,
// end: .centerRight` — while `[0,1,0]` reads y instead and turns it vertical
// (`begin: .topCenter, end: .bottomCenter`). The second row only has to keep the
// matrix invertible.
const kGradientHorizontal: Transform = [
  [1, 0, 0],
  [0, 1, 0],
];
const kGradientVertical: Transform = [
  [0, 1, 0],
  [-1, 0, 1],
];

// `_HueSlider._hueColors` — the widget's own seven stops, in its own order, in
// Figma's 0..1 channels. Red appears at both ends because the hue axis is a
// circle and the ramp has to close on itself.
const kHueSpectrum: readonly RGBA[] = [
  { r: 1, g: 0, b: 0, a: 1 },
  { r: 1, g: 1, b: 0, a: 1 },
  { r: 0, g: 1, b: 0, a: 1 },
  { r: 0, g: 1, b: 1, a: 1 },
  { r: 0, g: 0, b: 1, a: 1 },
  { r: 1, g: 0, b: 1, a: 1 },
  { r: 1, g: 0, b: 0, a: 1 },
];

// `Colors.transparent` → `Colors.black`, the V-axis veil the widget lays over
// the saturation ramp. Flutter's transparent is transparent BLACK, not an
// unpainted pixel, so the pair shares its RGB and differs only in alpha —
// written out because a `{r:0,g:0,b:0,a:0}` that quietly became white would
// wash the square out and look like a colour-space bug.
const kValueShade: readonly RGBA[] = [
  { r: 0, g: 0, b: 0, a: 0 },
  { r: 0, g: 0, b: 0, a: 1 },
];

const kHueMax = 360;
const kHueSectorsPerCircle = 6;
const kHueSector = kHueMax / kHueSectorsPerCircle;
// Where the green- and blue-max branches start on the hue circle, in sectors.
const kGreenSectorOffset = 2;
const kBlueSectorOffset = 4;
const kByteMax = 255;
const kHexRadix = 16;
const kHexDigitsPerChannel = 2;
// Where each channel's two hex digits start in `RRGGBB`.
const kHexRedAt = 0;
const kHexGreenAt = 2;
const kHexBlueAt = 4;
// A ramp needs two ends. Below that there is nothing to interpolate.
const kMinGradientStops = 2;
// Both edges of one axis — an inset that dodges a border loses it twice.
const kBothSides = 2;
// The scale's fully-round step. A handle is a disc, so its corner is "round",
// not half its size: half of an 18 handle is 9, which is no radius step, and
// binding it throws `variable not found: Primitives/radius/9` and fails the
// entry. Any radius ≥ half the side draws the same circle.
const kHandleRound = 9999;

// A `LinearGradient` whose `stops` Flutter leaves unset spreads its colours
// evenly, which is what both of these do — so the positions come from the count
// rather than from a list this file would have to keep in step with it.
function linearGradient(
  colors: readonly RGBA[],
  transform: Transform,
): GradientPaint {
  // Throws rather than dividing by zero: a one-stop "gradient" is a solid fill
  // wearing a gradient's clothes, and the run log names the loud version as one
  // failing entry instead of an invisible flat band.
  if (colors.length < kMinGradientStops) {
    throw new Error(
      `linearGradient: ${colors.length} stop(s) — a ramp needs at least two. ` +
        'A single colour belongs in `fills` as a SolidPaint.',
    );
  }
  const spans = colors.length - 1;
  return {
    type: 'GRADIENT_LINEAR',
    gradientTransform: transform,
    gradientStops: colors.map((color, at) => ({ position: at / spans, color })),
    visible: true,
    opacity: 1,
    blendMode: 'NORMAL',
  };
}

// `hexToRgb(hex)` — the three channels of `#RRGGBB`, each 0..1 (Figma's
// colour space). Everything the preview shows of the draft colour goes through
// here: the trigger swatch, the R / G / B inputs and the ramp's hue.
function rgbOfHex(hex: string): RGB {
  const raw = hex.replace('#', '');
  const channel = (at: number): number =>
    parseInt(raw.slice(at, at + kHexDigitsPerChannel), kHexRadix) / kByteMax;
  return { r: channel(kHexRedAt), g: channel(kHexGreenAt), b: channel(kHexBlueAt) };
}

// One channel as the widget's RGB input writes it — the 0..255 integer.
function byteOf(channel: number): string {
  return String(Math.round(channel * kByteMax));
}

// `rgbToHsv(hexToRgb(hex)).h` — the one step `_PopoverShellState` takes to seed
// `_hue` from `_draftHex`.
function hueOfHex(hex: string): number {
  const { r, g, b } = rgbOfHex(hex);
  const max = Math.max(r, g, b);
  const delta = max - Math.min(r, g, b);
  // Grey has no hue and `HSVColor` answers 0 for it — the same reason the widget
  // keeps `_hue` in its own field instead of deriving it from the hex on every
  // paint (tapping the white corner would otherwise reset the ramp to red).
  if (delta === 0) return 0;
  const sectors =
    max === r
      ? (g - b) / delta
      : max === g
        ? (b - r) / delta + kGreenSectorOffset
        : (r - g) / delta + kBlueSectorOffset;
  return (sectors * kHueSector + kHueMax) % kHueMax;
}

// The colour the saturation ramp ends at — `HSVColor.fromAHSV(1, hue, 1, 1)
// .toColor()` in the widget, the hue at full saturation and value.
//
// Read off `kHueSpectrum` rather than recomputed. Those seven stops ARE the hue
// circle at s = v = 1, and interpolating between two adjacent primaries is the
// same arithmetic `HSVColor.toColor()` performs inside one of its six sectors.
// So the two bands cannot come to disagree about what a hue looks like, and the
// plugin does not grow a second copy of colour-space maths — `color-generator.ts`
// carries the one hand-port there is, and records why it had to exist.
function hueStopOf(hue: number): RGBA {
  const spans = kHueSpectrum.length - 1;
  const at = (((hue % kHueMax) + kHueMax) % kHueMax) / (kHueMax / spans);
  const first = Math.floor(at);
  const into = at - first;
  const from = kHueSpectrum[first];
  const to = first + 1 < kHueSpectrum.length ? kHueSpectrum[first + 1] : from;
  const mix = (a: number, b: number): number => a + (b - a) * into;
  return { r: mix(from.r, to.r), g: mix(from.g, to.g), b: mix(from.b, to.b), a: 1 };
}

// ─── Pose axes ───────────────────────────────────────────────────────────────

// One POSE axis crossed onto the schema enumeration.
//
// `enumerateAxisCombos(axisSpecsOf(…))` answers the four schema axes and
// nothing else — it is the same function G10 divides its coverage by, which is
// the whole reason no builder rolls its own loop over them. A pose (`Selected` /
// `Error` / `Focus` / `Selection`) is declared by a builder instead, and
// `kAxisOrder` places every pose after the four, so crossing one on is a suffix.
//
// Composed through `composeVariantName` rather than by string concatenation so
// that the T-16 ordering check actually runs on the result: an axis this file
// names that `kAxisOrder` does not know — or a pose that starts sorting before a
// schema axis — throws here, instead of minting a second name for one member and
// leaving `mountSet.finish()` to report an unexplained leftover.
//
// An empty schema side is not a special case: `calendar.axes` promotes nothing
// at all (no variant, no size, no state, `enabled: false`), so there its pose is
// the whole name.
const kBooleanPose = ['false', 'true'] as const;

function withPose(
  combos: readonly string[],
  axis: AxisName,
  values: readonly string[],
): string[] {
  const out: string[] = [];
  for (const combo of combos.length > 0 ? combos : ['']) {
    const base = Object.entries(combo ? parseVariantKey(combo) : {}) as [AxisName, string][];
    for (const value of values) out.push(composeVariantName([...base, [axis, value] as const]));
  }
  return out;
}

// ─── ColorPicker (swatch trigger + popover picker column) ────────────────────
//
// Data-driven from coui_core COLOR_PICKER.fields (no variant/size dispatch on
// CoreColorPickerStyle — every value is a flat default). Two boolean axes, each
// read from the field (or the branch) that supplies it:
//
//   Enabled  — `disabledBorderColor` replaces `borderColor` on the trigger
//              swatch (exactly what `_Swatch(enabled: false)` does), and the
//              popover is not mounted at all: `if (!_isEnabled) return
//              triggerRow;` is the whole disabled build. One swap reaches every
//              border this builder draws, because `borderColor` is the
//              component's single border token.
//   Selected — the current recent colour wears `selectedRingColor` at
//              `recentSwatchSelectedBorderWidth` instead of `borderColor` at
//              `recentSwatchBorderWidth`. It therefore has nothing to say on
//              the disabled half of the matrix, and those two variants render
//              alike — which is the honest picture of an API that accepts the
//              combination.
//
// #4037 (C4b) — `Enabled` is not this builder's to declare: it arrives from
// `color_picker.axes` through `axisSpecsOf`/`enumerateAxisCombos`, the same
// enumerator G10 counts coverage with. That axis set promotes ONLY `enabled` —
// `CoreColorPickerMode` (hsl/hsv/rgb) and `CoreColorPickerPromptMode`
// (popover/dialog) both sit in `axes.other`, recorded but deliberately not
// promoted (the seed spec's §4-2 boundary) — so the schema side is two
// combinations, and `Selected` is a POSE axis this builder crosses onto them
// (`kAxisOrder` places every pose after the four). A loose COMPONENT left by the
// pre-promotion builder is adopted as `Enabled=true, Selected=false`: enabled
// because that body read `borderColor` and never `disabledBorderColor`, and
// unselected because it drew no ring at all.
//
// The trigger is a bare `Row` in code — no box, no background — so this builder
// draws none either. The swatch's fill is a stand-in (the widget paints the
// currently-picked colour, which is data, not a token) and it stays put on the
// disabled half: core declares no disabled swatch TONE, and a colour picker
// whose swatches lie about their colour when disabled would be worse than one
// that does not dim them. The recent grid is the schema's own
// `recentColumns`/`recentSwatchSize`/`recentSwatchSpacing` — 10-wide, 24px
// swatches, 4px apart — read in `pickerPopover` rather than guessed here.
//
// What the disabled swatch does carry is an OPACITY, and it is the one
// multiplier `design-tokens.md` still allows: `_Swatch` wraps itself in
// `Opacity(opacity: enabled ? 1 : CoreClickableStyle.defaultDisabledOpacity)`
// precisely because the fill it dims is an arbitrary user-picked colour with no
// "disabled" substitute to swap in. Painted at full strength here, the disabled
// variant differed from the resting one only in its 1px border colour — a
// difference you have to hunt for, on the axis whose whole job is to look
// unavailable.
// `Presentation` — `CoreColorPickerPromptMode`'s two drawn members: the field
// trigger that opens a popover (`popover`, the contract's `defaultPromptMode`,
// first so the set rests on it) and the panel drawn in place (`inline`). The
// enum's `dialog` is not drawn: neither platform renders a dialog for it.
const kColorPickerPresentations = ['popover', 'inline'] as const;

function buildColorPicker(page: PageNode, lk: VarLookup): ComponentSetNode {
  dropStaleExposes();
  const f = COLOR_PICKER.fields;
  const border = colorData(f.borderColor);
  const disabledBorder = colorData(f.disabledBorderColor);
  const borderWidth = dimVal(f.borderWidth);
  const swatchRadius = dimVal(f.swatchBorderRadius.topLeft);
  const swatchSize = dimVal(f.swatchSize);
  const hexWidth = dimVal(f.hexInputWidth);
  // `CoreClickableStyle.defaultDisabledOpacity`, which is what the widget names.
  // Read through this component's own forwarded `CoreClickableStyle` — the
  // recent-swatch slot is where that class reaches `components.json` for
  // ColorPicker, and it carries the same `CoreOpacity.opacity50` the class
  // default resolves to. The alternative was a literal 0.5, which states the
  // number and loses where it came from.
  const disabledOpacity = dimVal(f.recentSwatchClickableStyle.disabledOpacity);

  const names = withPose(
    withPose(enumerateAxisCombos(axisSpecsOf(COLOR_PICKER.axes)), 'Selected', kBooleanPose),
    'Presentation',
    kColorPickerPresentations,
  );
  const mount = mountSet(page, 'ColorPicker', names, {
    adoptLooseAs: 'Enabled=true, Selected=false, Presentation=popover',
  });
  // Bound after `finish()`: a component property belongs to the SET, and the
  // set does not exist until then — adding it to each member first would put
  // four separate definitions on four members and leave Figma to merge them.
  const hexFields: InstanceNode[] = [];
  const dialogTitles: SlotRef[] = [];
  const placeholders: SlotRef[] = [];
  // One per enabled member — the open panel, hidden until `Open` (bound
  // after `finish()`). A picker rests CLOSED: the widget mounts the panel
  // only while its popover is open, and a canvas that showed every picker
  // with its panel unfolded read as if the panel were part of the field.
  const openPanels: SceneNode[] = [];
  const swatches: SceneNode[] = [];
  const emptySwatches: SceneNode[] = [];

  for (const name of names) {
    const axes = parseVariantKey(name);
    const disabled = axes['Enabled'] === 'false';
    const selected = axes['Selected'] === 'true';
    const inline = axes['Presentation'] === 'inline';
    const comp = mount.getOrCreate(name);
    applyPanelCompChrome(comp, 'VERTICAL', lk, {
      gap: dimVal(f.popoverStyle.placementOffset),
    });
    const swatchBorder = disabled ? disabledBorder : border;

    // trigger — `_TriggerField`: one outlined field (`triggerBackgroundColor` /
    // `triggerBorderColor` at `triggerBorderWidth`, `triggerBorderRadius`,
    // `triggerPadding`, at least `triggerMinWidth` wide) holding the swatch, the
    // picked hex (or the placeholder) and a chevron, `triggerSpacing` apart.
    const trig = panel('trigger', 'HORIZONTAL', lk, {
      gap: f.triggerSpacing,
      radius: f.triggerBorderRadius.topLeft,
    });
    trig.counterAxisAlignItems = 'CENTER';
    fillData(trig, lk, colorData(f.triggerBackgroundColor));
    borderData(trig, lk, colorData(f.triggerBorderColor), dimVal(f.triggerBorderWidth));
    bindPad(trig, lk, f.triggerPadding);
    trig.minWidth = dimVal(f.triggerMinWidth);
    // The fill is the colour the caller picked, not chrome: `_Swatch` paints
    // `_hexToFlutterColor(hex)` off the live hex buffer and Web reads the same
    // buffer, so no `CoreColorPickerStyle` field states it — and none should,
    // since it is the component's value. `absent` lists `swatchButtonStyle`
    // with no default, which is the swatch's click chrome, not its fill.
    // The canvas still needs a colour here or the trigger stops reading as a
    // colour picker, and the widget's one literal on this path is the
    // invalid-input fallback — a validation stand-in, not a resting colour.
    // So the swatch shows the same example colour the hex input beside it
    // reads (`kColorPickerDraftHex`) — a value, not a token: a token here would
    // say the picker's colour is a theme colour, and the hex field would name a
    // different one.
    const sw = panel('swatch', 'HORIZONTAL', lk, { radius: swatchRadius });
    sw.fills = [{ type: 'SOLID', color: rgbOfHex(kColorPickerDraftHex) }];
    borderData(sw, lk, swatchBorder, borderWidth);
    trig.appendChild(sw);
    bindSize(sw, lk, swatchSize, swatchSize);
    // `Selected=false` is the "no colour picked" pose: the trigger shows the
    // empty swatch (no fill, dashed outline) instead of the filled one — a
    // navy fill on a picker with nothing chosen reads as a chosen colour.
    // Those members' two swatch nodes are therefore pinned (filled hidden,
    // empty shown) and left out of the `Swatch` / `Empty swatch` properties,
    // whose set-level defaults cannot differ per member.
    if (selected) swatches.push(sw);
    else sw.visible = false;
    // The empty ("no colour") swatch — `_Swatch(empty: true)`: no fill and a
    // DASHED outline in the same border token, drawn by the widget's own
    // painter from the two dash fields. It ships hidden on `Selected=true` (a
    // picker rests on a colour; the `Empty swatch` property turns it on while
    // `Swatch` turns the filled one off) and shown on `Selected=false`.
    const emptySw = panel('swatch empty', 'HORIZONTAL', lk, { radius: swatchRadius });
    emptySw.fills = [];
    borderData(emptySw, lk, swatchBorder, borderWidth);
    emptySw.dashPattern = [dimVal(f.emptySwatchDashLength), dimVal(f.emptySwatchDashSpacing)];
    trig.appendChild(emptySw);
    bindSize(emptySw, lk, swatchSize, swatchSize);
    // No opacity here: the empty swatch has no fill to dim, and its dashes already
    // take `disabledBorder` (`swatchBorder`) on the disabled half.
    emptySw.visible = !selected;
    if (selected) emptySwatches.push(emptySw);
    // On the node, not on the paint: the widget's `Opacity` wraps the whole
    // `Container`, so its border fades with its fill. A paint-level opacity
    // would dim the fill and leave the border at full strength.
    if (disabled) sw.opacity = disabledOpacity;
    // `TextField(… enabled: _isEnabled)` — the hex input takes the picker's own
    // enabled, so the disabled variant composes that child's disabled row.
    const hex = textFieldInstance(page, kColorPickerDraftHex, !disabled);
    // `showHexInput` / `showLabel` both default to false
    // (`CoreColorPickerContract`), so the slot ships switched off and the
    // BOOLEAN property below is how a designer turns it on — the same shape
    // `TextField` itself uses for its own optional feature button.
    hex.visible = false;
    hexFields.push(hex);
    // The picked hex — `Text(hex, style: triggerValueTextStyle)`, shown while a
    // colour is picked (`Selected=true`); the placeholder takes its seat
    // otherwise. It reads the same example colour as the swatch.
    const hexText = makeLabel(
      kColorPickerDraftHex,
      lk,
      textLabelOpts(lk, textStyleData(f.triggerValueTextStyle), null),
    );
    hexText.name = 'hex';
    trig.appendChild(hexText);
    hexText.layoutSizingHorizontal = 'FILL';
    hexText.visible = selected;
    // `placeholder` — the localized `colorPickerPlaceholder` (or the caller's
    // widget) in `triggerPlaceholderTextStyle`, shown when no colour is picked.
    // Bound to `Show placeholder` (default on) on the `Selected=false` members;
    // a picked colour shows its hex instead, so there it is pinned hidden.
    const ph = optionalTextSlot(
      lk,
      'placeholder',
      kColorPickerPlaceholder,
      textLabelOpts(lk, textStyleData(f.triggerPlaceholderTextStyle), null),
    );
    trig.appendChild(ph.node);
    ph.node.layoutSizingHorizontal = 'FILL';
    ph.node.visible = !selected;
    if (!selected) placeholders.push(ph);
    // `Icon(LucideIcons.chevronDown, iconStyle: triggerChevronIconStyle)`.
    const chevron = makeIcon(
      'chevron-down',
      lk,
      glyphOpts(lk, colorData(f.triggerChevronIconStyle.color), f.triggerChevronIconStyle.size),
    );
    chevron.name = 'chevron';
    trig.appendChild(chevron);
    // The trigger row — `Row(children: [_TriggerField, Gap(swatchGapStyle),
    // SizedBox(width: hexInputWidth, child: TextField)])`: the editable hex
    // input sits beside the field, not inside it.
    const triggerRow = panel('trigger row', 'HORIZONTAL', lk, { gap: f.swatchGapStyle.size });
    triggerRow.counterAxisAlignItems = 'CENTER';
    triggerRow.appendChild(trig);
    triggerRow.appendChild(hex);
    hex.resize(hexWidth, hex.height);
    hex.visible = false;
    comp.appendChild(triggerRow);

    if (inline) {
      // `promptMode: .inline` — no trigger: the panel is drawn in place inside
      // `Popup(popupStyle: inlinePanelStyle)` (no shadow), always open, and a
      // disabled picker keeps it in view but inert. The trigger node stays,
      // hidden, so the members share one layer tree.
      triggerRow.visible = false;
      comp.appendChild(pickerPopover(page, lk, selected, dialogTitles, true, !disabled));
      continue;
    }

    // `if (!_isEnabled) return triggerRow;` — the disabled picker mounts no
    // popover at all, so neither the panel nor the wrapper exists there.
    if (!disabled) {
      const pop = pickerPopover(page, lk, selected, dialogTitles, false);
      comp.appendChild(pop);
      pop.visible = false;
      openPanels.push(pop);
      appendPopoverWrapper(page, comp);
    }
  }

  const set = mount.finish();
  const openId = defineProp(set, 'Open', 'BOOLEAN', false);
  for (const p of openPanels) bindVisibleProp(p, openId);
  // Two properties, not one: a BOOLEAN can only show or hide a node, never
  // swap two, so the filled swatch and its empty twin each get their own.
  const swatchId = defineProp(set, 'Swatch', 'BOOLEAN', true);
  for (const n of swatches) bindVisibleProp(n, swatchId);
  const emptySwatchId = defineProp(set, 'Empty swatch', 'BOOLEAN', false);
  for (const n of emptySwatches) bindVisibleProp(n, emptySwatchId);
  const hexId = defineProp(set, 'Hex input', 'BOOLEAN', false);
  for (const field of hexFields) bindVisibleProp(field, hexId);
  bindOptionalTextSlot(
    dialogTitles,
    defineProp(set, 'Show dialogTitle', 'BOOLEAN', false),
    defineProp(set, 'dialogTitle', 'TEXT', kColorPickerDialogTitle),
  );
  bindOptionalTextSlot(
    placeholders,
    defineProp(set, 'Show placeholder', 'BOOLEAN', true),
    defineProp(set, 'placeholder', 'TEXT', kColorPickerPlaceholder),
  );
  // Now that every instance is inside the set, the exposes are legal.
  exposeAll(pendingExposed);
  pendingExposed.length = 0;
  return set;
}

// `_PopoverShell` — the column the enabled picker mounts as `Popover.content`.
//
// Every section is the widget's, in the widget's order: `_ModeTabs` (three
// `Button`s, the active one `primary` and the rest `ghost`, each `expanded`),
// `_SaturationValueArea`, `_HueSlider`, `_ModeInputs` (three
// label + `TextField` cells), `_RecentColorsGrid`, `_ActionRow` (an
// eyedropper `Button(variant: .outline, child: Icon(pipette))`, then Cancel
// `secondary` and Save `primary` pushed right by a `Spacer`).
//
// `_AlphaSlider` is absent because `showAlpha` defaults to false; each recent
// swatch is a `Clickable` wrapping a plain box, and `Clickable` has no chrome
// node of its own to instantiate.
//
// The two bands are real gradients — see the `Gradients` section above for why
// the flat semantic fills that used to stand in for them were not a stand-in a
// designer could read. The saturation square is the widget's own two-layer
// stack: the white → hue ramp on the frame, and the transparent → black V-axis
// veil as one inset child above it, which is exactly how the widget nests them
// (`Container(border) > DecoratedBox(hue ramp) > DecoratedBox(shade)`) and for
// the reason its comment gives — a shade painted over the border would tint the
// border darker than the sibling hue slider's.
function pickerPopover(
  page: PageNode,
  lk: VarLookup,
  selected: boolean,
  dialogTitles: SlotRef[],
  // `promptMode: .inline` — the panel box is `inlinePanelStyle` (no shadow)
  // and the action row ends with the previous / current comparison cell
  // instead of Cancel / Save.
  inline: boolean,
  // An inline picker's panel stays in view when disabled; its inputs take the
  // picker's `enabled`, as the widgets hand it to each `TextField`.
  enabled = true,
): FrameNode {
  const f = COLOR_PICKER.fields;
  const contentWidth = dimVal(f.popoverWidth);
  const contentGap = dimVal(f.popoverSpacing);
  const bandHeight = dimVal(f.sliderHeight);
  const areaRadius = dimVal(f.saturationValueBorderRadius.topLeft);
  const sliderRadius = dimVal(f.sliderBorderRadius.topLeft);
  const recentRadius = dimVal(f.recentSwatchBorderRadius.topLeft);
  const border = colorData(f.borderColor);
  const handleRing = colorData(f.pickMarkerBorderColor);
  const handleRingWidth = dimVal(f.pickMarkerBorderWidth);
  const hueHandleRing = colorData(f.hueMarkerBorderColor);
  const hueHandleRingWidth = dimVal(f.hueMarkerBorderWidth);
  const pickMarkerSize = dimVal(f.pickMarkerSize);
  const ring = colorData(f.selectedRingColor);
  const borderWidth = dimVal(f.borderWidth);
  const recentSize = dimVal(f.recentSwatchSize);
  const recentGap = dimVal(f.recentSwatchSpacing);
  const recentColumns = dimVal(f.recentColumns);
  const recentBorderWidth = dimVal(f.recentSwatchBorderWidth);
  const ringWidth = dimVal(f.recentSwatchSelectedBorderWidth);
  const inputGap = dimVal(f.modeInputSpacing);
  const inputLabelGap = dimVal(f.modeInputLabelGapStyle.size);
  const actionGap = dimVal(f.actionRowGapStyle.size);
  const modes = ['RGB', 'HSL', 'HSV'];
  // Each channel input reads the draft colour (`_draftHex`), the same value the
  // trigger's hex field and swatch show.
  const draft = rgbOfHex(kColorPickerDraftHex);
  const channels = [
    { label: 'R', value: byteOf(draft.r) },
    { label: 'G', value: byteOf(draft.g) },
    { label: 'B', value: byteOf(draft.b) },
  ];
  const colors = [
    'primary', 'secondary', 'tertiary', 'error', 'success',
    'warning', 'info', 'surface-container', 'primary-container', 'secondary-container',
  ];

  const pop = popoverPanel(
    lk,
    'popover panel',
    inline ? f.inlinePanelStyle : f.popoverStyle.panelStyle,
    contentGap,
  );

  // `?widget.dialogTitle` — the column's FIRST child, ahead of `_ModeTabs`.
  // ColorPicker renders this itself (it has no `Dialog`), so the node is the
  // picker's own and the property can bind to it.
  const title = optionalTextSlot(
    lk,
    'dialogTitle',
    kColorPickerDialogTitle,
    // An arbitrary widget with no CoreColorPickerStyle field behind it — it
    // inherits the panel's ambient content colour, which IS a field
    // (`popoverStyle.panelStyle.contentColor`, what `Popup` paints its rows
    // with).
    textLabelOpts(lk, textStyleData(null), colorData(f.popoverStyle.panelStyle.contentColor)),
  );
  pop.appendChild(title.node);
  dialogTitles.push(title);

  // _ModeTabs — the shared `ToggleGroup`, one segment per mode in
  // `_kPickerModeOrder`; the first (rgb, `defaultPickerMode`) is the chosen
  // face. An INSTANCE of the registered set, its three option labels written
  // into the group's own TEXT properties.
  const tabs = instanceOf(
    page,
    'ToggleGroup',
    // `Width=Fill` — the tabs span the panel (`ToggleGroup(fillWidth: true)`);
    // `Size=sm` — a panel's toggle (`CoreColorPickerContract.defaultModeTabsSize`).
    restingVariantName(page, 'ToggleGroup', {
      Size: 'sm',
      Enabled: 'true',
      Selected: '1',
      Width: 'Fill',
      Orientation: 'Horizontal',
    }),
  );
  for (let i = 0; i < modes.length; i++) {
    setInstanceTextNamed(tabs, `Option ${i + 1} label`, modes[i]);
  }
  // `modeTabsStyle` restates the track one step up — the tabs sit on the
  // panel, which in Dark equals the group's own page-level track. Only the
  // track: every other field is the group's, so the instance takes the one
  // fill override the slot states.
  fillData(tabs, lk, colorData(f.modeTabsStyle.backgroundColor));
  pop.appendChild(tabs);
  tabs.layoutSizingHorizontal = 'FILL';

  // _SaturationValueArea — a square whose side is the popover's own width.
  // `LinearGradient(begin: .centerLeft, end: .centerRight, colors: [white,
  // HSVColor.fromAHSV(1, hue, 1, 1)])`, the hue read off the draft hex.
  const area = panel('saturation-value', 'HORIZONTAL', lk, { radius: areaRadius });
  area.primaryAxisSizingMode = 'FIXED';
  area.counterAxisSizingMode = 'FIXED';
  area.fills = [
    linearGradient(
      [{ r: 1, g: 1, b: 1, a: 1 }, hueStopOf(hueOfHex(kColorPickerDraftHex))],
      kGradientHorizontal,
    ),
  ];
  // No border: the area draws none (`_SaturationValueArea`).
  pop.appendChild(area);
  bindSize(area, lk, contentWidth, contentWidth);
  // The V axis, as a child rather than a second paint on `area`. Two reasons,
  // and the first is the widget's own: its comment records that painting the
  // shade over the border tinted `borderColor` darker than the sibling hue
  // slider's, so it splits the chrome and keeps the gradients inside the border.
  // The second is that a child's z-order is unambiguous — it draws above its
  // parent's fill — while which end of a `fills` array is on top is a fact this
  // builder would be asserting from memory.
  const shade = panel('value shade', 'HORIZONTAL', lk, { radius: areaRadius });
  shade.fills = [linearGradient(kValueShade, kGradientVertical)];
  // Through the one door, like every other pin — see `pinAbsolute`. Directly
  // written, this was the last place a `layoutPositioning` refusal could still
  // fail an entry and leave a half-drawn component behind without naming the
  // node.
  pinAbsolute(area, shade, 0, 0, {
    horizontal: 'STRETCH',
    vertical: 'STRETCH',
  });
  // STRETCH on both axes (passed to `pinAbsolute` above) so the inset stays
  // exactly the border it is dodging when a designer resizes the square, instead
  // of drifting off one edge.
  shade.resize(contentWidth, contentWidth);
  // The picked-point handle: a `pickMarkerSize` disc in the picked colour with the
  // `pickMarkerBorderColor` ring, riding the area at the picked saturation / value.
  const areaHandle = panel('handle', 'HORIZONTAL', lk, { radius: kHandleRound });
  // g7-preview-only: demo fill standing in for the picked colour (data), the same
  // example colour the swatch and the hue handle show — a value, not a token. A
  // token here (it was `primary`) follows the scheme and the brand instead of the
  // pick: near-black in Light, white in Dark. The ring is the style's own.
  areaHandle.fills = [{ type: 'SOLID', color: rgbOfHex(kColorPickerDraftHex) }];
  borderData(areaHandle, lk, handleRing, handleRingWidth);
  setShadow(areaHandle, f.pickMarkerShadow, lk);
  bindSize(areaHandle, lk, pickMarkerSize, pickMarkerSize);
  // g7-preview-only: demo pick position (saturation 64 %, value 70 %) standing in for the caller's picked colour, which is data and no CoreColorPickerStyle field states.
  const areaPick = { x: contentWidth * 0.64, y: contentWidth * 0.3 };
  pinAbsolute(area, areaHandle, areaPick.x - pickMarkerSize / kBothSides, areaPick.y - pickMarkerSize / kBothSides, {
    horizontal: 'MIN',
    vertical: 'MIN',
  });

  // _HueSlider — `LinearGradient(begin: .centerLeft, end: .centerRight,
  // colors: _hueColors)`, the hue circle from red back to red.
  // The hit box is as tall as the handle (`SizedBox(height: max(pickMarkerSize,
  // barHeight))`); the 8px bar is centred in it and the handle rides over the bar.
  const hue = panel('hue slider', 'HORIZONTAL', lk, {});
  hue.primaryAxisSizingMode = 'FIXED';
  hue.counterAxisSizingMode = 'FIXED';
  hue.fills = [];
  pop.appendChild(hue);
  bindSize(hue, lk, contentWidth, Math.max(pickMarkerSize, bandHeight));
  const hueBar = panel('hue bar', 'HORIZONTAL', lk, { radius: sliderRadius });
  hueBar.primaryAxisSizingMode = 'FIXED';
  hueBar.counterAxisSizingMode = 'FIXED';
  hueBar.fills = [linearGradient(kHueSpectrum, kGradientHorizontal)];
  // No border: the bar draws none (`_HueSlider`).
  bindSize(hueBar, lk, contentWidth, bandHeight);
  pinAbsolute(hue, hueBar, 0, (Math.max(pickMarkerSize, bandHeight) - bandHeight) / kBothSides, {
    horizontal: 'STRETCH',
    vertical: 'CENTER',
  });
  // The hue handle is filled with the current colour, like the saturation
  // handle, inside its own `hueMarkerBorderColor` ring (white, 3).
  const hueHandle = panel('handle', 'HORIZONTAL', lk, { radius: kHandleRound });
  // g7-preview-only: demo fill standing in for the current colour (data), the same example colour the swatch shows; the ring is the style's own.
  hueHandle.fills = [{ type: 'SOLID', color: rgbOfHex(kColorPickerDraftHex) }];
  borderData(hueHandle, lk, hueHandleRing, hueHandleRingWidth);
  setShadow(hueHandle, f.pickMarkerShadow, lk);
  bindSize(hueHandle, lk, pickMarkerSize, pickMarkerSize);
  // g7-preview-only: demo hue position (a third along the spectrum) standing in for the draft hue, which is data.
  pinAbsolute(hue, hueHandle, contentWidth * 0.33 - pickMarkerSize / kBothSides, 0, {
    horizontal: 'MIN',
    vertical: 'CENTER',
  });

  // _ModeInputs — one `_ModeInputCell` per channel: centred label, then the
  // channel's own `TextField`.
  const inputs = panel('mode inputs', 'HORIZONTAL', lk, { gap: inputGap });
  // The channel caption is `CoreColorPickerStyle.defaultModeInputLabelStyle`
  // on both platforms — `bodySmall` in `onSurfaceSubtle` — and its metrics and
  // colour both come from that field.
  const captionType = textLabelOpts(lk, textStyleData(f.modeInputLabelStyle), null);
  // The HEX cell heads the row (`_HexInputCell`), `modeHexInputFlex` times a
  // channel cell's share; the three channels split the rest. Figma has no flex
  // weight, so each cell is locked to the width that weight lands it at.
  const hexFlex = dimVal(f.modeHexInputFlex);
  const cellShare = (contentWidth - inputGap * channels.length) / (hexFlex + channels.length);
  const cells = [
    { name: 'cell hex', label: kColorPickerHexLabel, value: kColorPickerDraftHex, width: cellShare * hexFlex },
    ...channels.map((c) => ({ name: 'cell', label: c.label, value: c.value, width: cellShare })),
  ];
  for (const c of cells) {
    const cell = panel(c.name, 'VERTICAL', lk, { gap: inputLabelGap });
    cell.counterAxisAlignItems = 'CENTER';
    const label = makeLabel(c.label, lk, captionType);
    cell.appendChild(label);
    // `size: CoreColorPickerContract.defaultModeInputSize` — the panel's inputs
    // are the `sm` field row.
    const field = textFieldInstance(page, c.value, enabled, undefined, 'defaultVariant', kModeInputSize);
    cell.appendChild(field);
    field.layoutSizingHorizontal = 'FILL';
    inputs.appendChild(cell);
    lockWidth(cell, c.width);
  }
  pop.appendChild(inputs);
  lockWidth(inputs, contentWidth);

  // _RecentColorsGrid — `Wrap(spacing: recentSwatchSpacing, runSpacing:
  // recentSwatchSpacing)` of fixed `recentSwatchSize` squares.
  //
  // A `Wrap` inside the popover column is bounded by the column, so the row
  // BREAKS: ten 24px swatches four apart need 276 and the column is 240, so the
  // widget puts eight on the first run and two on the second. Left unwrapped
  // here the row simply grew past the column and, because every other section is
  // locked to `popoverWidth`, the panel hugged 276 while its contents measured
  // 240 — 36px of empty surface down the right edge of the whole popover, which
  // is what a designer sees before anyone looks at the swatches.
  //
  // `layoutWrap` is Figma's own counterpart and `counterAxisSpacing` is the run
  // gap; the widget passes the same field to both axes.
  const recent = panel('recent colors', 'HORIZONTAL', lk, { gap: recentGap });
  for (let i = 0; i < colors.length && i < recentColumns; i++) {
    const s = panel('color', 'HORIZONTAL', lk, { bg: colors[i], radius: recentRadius });
    recent.appendChild(s);
    bindSize(s, lk, recentSize, recentSize);
    // Only one recent colour can be the selected one — the first, so the two
    // sides of the axis differ in one place a designer can point at.
    const isSelected = selected && i === 0;
    borderData(
      s,
      lk,
      isSelected ? ring : border,
      isSelected ? ringWidth : recentBorderWidth,
    );
  }
  // The section title above the row — the localized `colorPickerRecentTitle`
  // in `recentTitleTextStyle`, `recentTitleGapStyle` above the swatches.
  const recentSection = panel('recent', 'VERTICAL', lk, { gap: f.recentTitleGapStyle.size });
  const recentLabel = makeLabel(
    kColorPickerRecentTitle,
    lk,
    textLabelOpts(lk, textStyleData(f.recentTitleTextStyle), null),
  );
  recentLabel.name = 'recent label';
  recentSection.appendChild(recentLabel);
  recentSection.appendChild(recent);
  pop.appendChild(recentSection);
  // After the children, like every other `lockWidth` here: it fixes the primary
  // axis, which is what gives `layoutWrap` a width to break against.
  lockWidth(recent, contentWidth);

  // _ActionRow — eyedropper on the leading edge, `Spacer()`, then Cancel/Save.
  const actions = panel('actions', 'HORIZONTAL', lk, { gap: actionGap });
  actions.primaryAxisAlignItems = 'SPACE_BETWEEN';
  actions.counterAxisAlignItems = 'CENTER';
  // The eyedropper — `Button(variant: .outline, size: .sm,
  // child: Icon(LucideIcons.pipette))`, and conditional in code: the widget
  // hides it wherever `window.EyeDropper` is absent, which is every native
  // target plus Firefox and Safari.
  //
  // A Button INSTANCE with its label hidden and its box squared off, the same
  // shape the calendar's nav arrows get, carrying `pipette` — the ONLY `Icon(`
  // anywhere in the widget (the sole other match in the directory is a doc
  // comment).
  //
  // It shipped empty once, and the reason was worth recording: `pipette` was
  // not among the names `gen-icons.ts` lists, so the glyph could not be drawn,
  // and substituting a different one would have been the same class of error as
  // handing back a filled pill where an outline button belonged. That note also
  // named the fix — add the name and regenerate — which is what happened; the
  // vendored Lucide set had it all along. A missing glyph is a one-line list
  // entry, not a platform limit.
  //
  // `Stacks` is a different matter and never was blocked on that: ColorPicker's own
  // subtree overlays nothing. Every `Stacks(` under `color_picker/` is inside
  // `_ColorPickingLayerState.build` (`color_picker_internal.dart`) — that is
  // `ColorPickingLayer`, a separate exported widget an app wraps a subtree with
  // so the eyedropper can screenshot it. `ColorPicker` never builds one; it
  // only reads `RecentColorsScope`. So the edge is the parity scan's
  // directory-glob artifact, the same shape the baseline already names for
  // Avatar→AvatarGroup and Tabs→TabPane, and placing nodes here to answer it
  // would assert an overlay the picker does not have. The one node this canvas
  // would genuinely place is the glyph riding on this Button — the blocked call
  // above.
  const eyeDropper = instanceOf(
    page,
    'Button',
    restingVariantName(page, 'Button', {
      Variant: 'ghost',
      Size: kPopoverButtonSize,
    }),
  );
  actions.appendChild(eyeDropper);
  hideInstanceLabel(eyeDropper);
  // `Icon(LucideIcons.pipette, iconStyle: resolved.eyeDropperIconStyle)` — the
  // glyph, swapped to the `Size=N` step that style states (16) rather than
  // the set's default: the swap lands the variant it names, and a rescale
  // after it is refused on an instance descendant.
  //
  // The colour is the host's — `eyeDropperIconStyle` states a size and no
  // colour, so the glyph takes the outline Button's leading tint. That tint is
  // read off the slot before the swap and written back onto every leaf after
  // it: `pipette` has more leaves than the `check` it replaces, and the
  // override carry-over alone reaches only the ones that share a name.
  setSlotIcon(
    eyeDropper,
    'Leading',
    iconMainIdAt(page, dimVal(f.eyeDropperIconStyle.size)),
    'pipette',
    kPreserveGlyphPaint,
  );
  // The slot holder rather than the glyph inside it: `Button`'s leading holder is
  // FIXED on both axes at its size row's icon size, so a glyph that disagrees is
  // centred in the old box instead of resizing it.
  bindSize(
    namedDescendant(eyeDropper, 'leading'),
    lk,
    f.eyeDropperIconStyle.size,
    f.eyeDropperIconStyle.size,
  );
  pendingExposed.push(eyeDropper);
  eyeDropper.resize(dimVal(BUTTON_SM.height), dimVal(BUTTON_SM.height));
  if (inline) {
    // `_CompareCell` — two `compareSwatchSize` halves (the colour before the
    // inline edits, then the current one) in one `compareBorderColor` box at
    // `compareBorderWidth`, `compareBorderRadius`, clipping the halves.
    const compare = panel('compare', 'HORIZONTAL', lk, { radius: f.compareBorderRadius.topLeft });
    borderData(compare, lk, colorData(f.compareBorderColor), dimVal(f.compareBorderWidth));
    compare.clipsContent = true;
    // g7-preview-only: demo previous / current colours standing in for the caller's values, which are data and no CoreColorPickerStyle field states.
    for (const [halfName, hexValue] of [['previous', kColorPickerPreviousHex], ['current', kColorPickerDraftHex]] as const) {
      const half = figma.createRectangle();
      half.name = halfName;
      half.fills = [{ type: 'SOLID', color: rgbOfHex(hexValue) }];
      compare.appendChild(half);
      bindSize(half, lk, f.compareSwatchSize, f.compareSwatchSize);
    }
    actions.appendChild(compare);
  } else {
    const commit = panel('commit', 'HORIZONTAL', lk, { gap: actionGap });
    commit.appendChild(labelButton(page, { variant: 'ghost', size: kPopoverButtonSize, label: '취소' }));
    commit.appendChild(labelButton(page, { variant: 'primary', size: kPopoverButtonSize, label: '저장' }));
    actions.appendChild(commit);
  }
  pop.appendChild(actions);
  lockWidth(actions, contentWidth);
  return pop;
}

// ─── DatePicker trigger ──────────────────────────────────────────────────────
//
// The trigger is a read-only `TextField` in both widgets — `TextField(readOnly:
// true, value: <date>, placeholder: …, textFieldStyle: resolved.triggerStyle,
// suffix: Icon(calendar))`, the TimePicker / Select input look. It is a
// `TextField` INSTANCE here, not a hand-drawn box, so its box (height 40, corner
// 10, the `outline-variant` edge, the `primary` focus edge, the Regular 14
// value) is the field's own `md` row and nothing here restates it.
//
// What the picker itself decides, and so what is written here:
//   - the calendar in the suffix seat, at `trailingIconStyle.size`, in the
//     icon tone (`trailingIconStyle.color`);
//   - the value colour (`contentColor`) — an enabled picker only; a disabled
//     one leaves the field's own disabled tone, as the widgets do;
//   - the error tone: the field's own `error` Variant, which is the edge the
//     widgets reach through the ambient validation state. Only while enabled —
//     disabled outranks the error, so a disabled picker is the disabled field
//     whatever its `errorText`;
//   - the pressed-only state layer (`triggerStyle.stateLayer`): hover and focus
//     show no wash, because the border stepping and the ring already say it;
//   - no caret — `showCursor: false`.
//
// The trigger fills the width its parent gives it (no fixed width).
//
// The field and the `placeholderWidget` overlay get a FRAME of their own. The
// overlay is absolutely positioned, and an absolute node keeps its distance
// from the edges its `constraints` name, so it MOVES when its parent's size
// changes: placed into the picker's `field` column, it would drift down the
// moment the `Error=true` variant appended its message under the trigger. A
// frame that holds only the trigger cannot grow — it hugs an instance whose
// size is fixed, and absolute children are outside its sizing — so a sibling
// added later has nothing to move.
const TEXT_FIELD_MD = COMPONENTS.text_field.sizes.defaultsBySize.md;

/** The composed trigger, and the frame it and any overlay on it live in. */
interface TriggerNodes {
  trigger: InstanceNode;
  /** Where any further overlay on the trigger belongs. */
  row: FrameNode;
}

function appendDateTrigger(
  page: PageNode,
  host: FrameNode,
  lk: VarLookup,
  o: { enabled: boolean; hasError: boolean; value: string },
): TriggerNodes {
  const f = DATE_PICKER.fields;
  const row = panel('trigger', 'HORIZONTAL', lk, {});
  host.appendChild(row);
  row.layoutSizingHorizontal = 'FILL';
  // `Variant=error` only while enabled — `CoreTextFieldVariant.showsErrorChrome`
  // is `hasError && enabled`, and the widgets only tell an enabled field.
  const trigger = textFieldInstance(
    page,
    o.value,
    o.enabled,
    o.enabled ? 'enabled' : 'disabled',
    o.enabled && o.hasError ? 'error' : 'defaultVariant',
  );
  trigger.name = 'trigger';
  // Hover and focus show no wash (`stateLayer` is pressed-only), so the resting
  // member draws none.
  for (const layer of trigger.findAll((n) => n.name === 'state layer')) layer.visible = false;
  row.appendChild(trigger);
  const iconSize = dimVal(f.trailingIconStyle.size);
  setSlotIcon(
    trigger,
    'suffix',
    iconMainIdAt(page, iconSize),
    'calendar',
    glyphPaint(
      lk,
      labelColor(
        lk,
        colorData(o.enabled ? f.trailingIconStyle.color : TEXT_FIELD_DISABLED_FOREGROUND),
      ),
    ),
  );
  bindSize(namedDescendant(trigger, 'suffix'), lk, f.trailingIconStyle.size, f.trailingIconStyle.size);
  // A disabled picker leaves both colours to the field's disabled tone — the
  // calendar too, which the resolvers hand over untinted (`withoutColor`).
  if (o.enabled) {
    applyInstanceTextStyle(
      namedDescendant(trigger, kFieldValueName),
      lk,
      textStyleData({ role: null, color: f.contentColor }),
    );
  }
  return { trigger, row };
}

// `Error` is DatePicker's one own POSE axis, and both halves come from real
// fields: the trigger takes the composed `TextField`'s own `error` Variant (the
// widget's `hasError && enabled` ambient validation state, whose edge is
// `triggerStyle.errorBorderColor`) — its text stays the enabled value colour —
// and the message below is `errorStyle` + `errorColor`, spaced by
// `descriptionTopGapStyle`.
//
// `Enabled` is the schema's, and it arrives the same way TimePicker's does —
// #4037 (C4b): `date_picker.axes` promotes ONLY `enabled` (its `CorePromptMode`
// popover/dialog enum sits in `axes.other`, recorded but deliberately not
// promoted — the seed spec's §4-2 boundary), so the schema side is two
// combinations and `Error` is crossed onto them. The loose COMPONENT the
// pre-promotion builder left is adopted as `Enabled=true, Error=false`, which is
// what it drew.
//
// What `Enabled=false` changes is the composed child, not a field of this
// component's: the widget hands its own `enabled` straight down
// (`TextField(… enabled: _enabled)`), so the disabled variant composes
// `TextField`'s own `disabled` row and gets that component's disabled chrome —
// which is the whole reason the trigger is an instance and not a redrawn box.
// For the value COLOUR that is the decision, not a gap: the composed field owns
// it, and `appendDateTrigger` paints `contentColor` only while enabled so the
// field's own disabled row shows through (both widgets do the same). The error
// and description lines have no disabled counterpart of that kind: they take
// `disabledErrorColor` / `disabledDescriptionColor`, which the widgets state.
//
// Below the field sits the open popover, offset by `popoverStyle
// .placementOffset` and holding a real `Calendar` INSTANCE — the widget's
// `Popover(trigger: triggerButton, content: _buildPopoverCalendar())`, whose
// content is `Calendar(… calendarStyle: widget.resolved.calendarStyle)`. The
// `Selection=Single` variant is the one composed because this preview's trigger
// carries one date and `DatePicker` has no range mode of its own (its value is a
// `DateTime?`); `calendarStyle` is the slot that re-styles it, and it is the
// reason the spec's `focusOutlineStyle` / `selectedColor` / `selectedTextStyle`
// axes live on `Calendar` rather than here — they are the popover calendar's
// cell states, rendered by the component now standing in this panel.
function buildDatePicker(page: PageNode, lk: VarLookup): ComponentSetNode {
  dropStaleExposes();
  const f = DATE_PICKER.fields;
  const names = withPose(
    enumerateAxisCombos(axisSpecsOf(DATE_PICKER.axes)),
    'Error',
    kBooleanPose,
  );
  const mount = mountSet(page, 'DatePicker', names, {
    adoptLooseAs: 'Enabled=true, Error=false',
  });
  const placeholders: SlotRef[] = [];
  const labels: SlotRef[] = [];
  const descriptions: SlotRef[] = [];
  // The open panel per enabled member — see ColorPicker for why it rests
  // hidden behind an `Open` property.
  const openPanels: SceneNode[] = [];
  for (const name of names) {
    const axes = parseVariantKey(name);
    const enabled = axes['Enabled'] !== 'false';
    const hasError = axes['Error'] === 'true';
    const comp = mount.getOrCreate(name);
    applyPanelCompChrome(comp, 'VERTICAL', lk, {
      gap: dimVal(f.popoverStyle.placementOffset),
    });

    // No itemSpacing: the widget's field column is
    // `Column(crossAxisAlignment: .stretch, children: children)` with no
    // `spacing:` at all — every gap in it is an explicit `Gap` child under the
    // same `if` as the thing it spaces (`label` + `labelBottomGapStyle`,
    // `descriptionTopGapStyle` + the error line). Carried as a column spacing, one
    // gap stood in for both and the label below would have been spaced twice: its
    // own 6 plus the column's 6, for 12 the widget never draws.
    const field = panel('field', 'VERTICAL', lk, {});
    // `label` — a `String?`, null by default, so the group ships switched off and
    // the BOOLEAN below is how a designer turns it on. `labelStyle` (labelLarge)
    // is the typography the resolver bakes into `labelTextStyle`; the group also
    // carries the `Gap(labelBottomGapStyle)` that follows it, because the widget
    // adds the two together or neither.
    const lab = optionalTextSlot(
      lk,
      'label',
      kDatePickerLabel,
      textLabelOpts(lk, textStyleData(f.labelStyle), colorData(f.contentColor)),
      dimVal(f.labelBottomGapStyle.size),
    );
    field.appendChild(lab.node);
    labels.push(lab);
    const { trigger, row } = appendDateTrigger(page, field, lk, {
      value: '2026-06-23',
      enabled,
      hasError,
    });
    // `placeholderWidget` — the trigger's `placeholder` when `value == null`
    // (`effectivePlaceholder`, whose own fallback is
    // `Text(localizations.placeholderDatePicker)`). It occupies the composed
    // `TextField`'s placeholder seat, which lives INSIDE the instance, so it
    // rides above it as an absolutely-positioned sibling for the same reason
    // the trailing glyph does — and switched off, because the preview's trigger
    // carries a date and the slot defaults to null. Turning it on puts it
    // exactly where the value it replaces sits: the field's own text inset, in
    // the field's own text role, in `placeholderColor`.
    //
    // Into the trigger's own frame, not the field column, for the reason
    // `appendDateTrigger` records: the column grows when the error line arrives
    // and an absolute child follows its parent's edges. This one is hidden by
    // default, so the drift would have waited for whoever first switched it on.
    const ph = optionalTextSlot(
      lk,
      'placeholderWidget',
      kDatePickerPlaceholder,
      typographyColorOpts(lk, textStyleData(TEXT_FIELD_MD.baseTextStyle), colorData(f.placeholderColor)),
    );
    overlayChild(row, ph.node, dimVal(TEXT_FIELD_MD.padding.l), (trigger.height - ph.node.height) / 2, 'MIN');
    placeholders.push(ph);
    if (hasError) {
      // `Gap(gapStyle: descriptionTopGapStyle)` — the explicit child the widget
      // puts between the trigger and the message, now that the column no longer
      // carries a spacing that stood in for it.
      const errorGap = panel('gap', 'HORIZONTAL', lk, {});
      field.appendChild(errorGap);
      bindSize(errorGap, lk, dimVal(f.descriptionTopGapStyle.size), dimVal(f.descriptionTopGapStyle.size));
      field.appendChild(
        makeLabel(
          '올바른 날짜를 입력해 주세요',
          lk,
          textLabelOpts(lk, textStyleData(f.errorStyle), colorData(enabled ? f.errorColor : f.disabledErrorColor)),
        ),
      );
    }
    if (!hasError) {
      // `else if (description != null)` — the helper line under the trigger, and
      // the `else` is why it is on this variant only: the widget draws the error
      // message OR the description, never both, and the error line above is the
      // other arm. A `String?` defaulting to null, so it ships switched off the
      // way `label` does.
      //
      // `descriptionColor` is the flat slot colour and `descriptionStyle` the role
      // (`bodyXs`) — two fields, and the resolver spends them exactly this way
      // (`descriptionStyle`'s own `.color` would win if it stated one; it does not).
      // A disabled picker takes `disabledDescriptionColor` instead, the way its
      // error line takes `disabledErrorColor`.
      const desc = optionalTextSlot(
        lk,
        'description',
        kDatePickerDescription,
        textLabelOpts(
          lk,
          textStyleData(f.descriptionStyle),
          colorData(enabled ? f.descriptionColor : f.disabledDescriptionColor),
        ),
        undefined,
        dimVal(f.descriptionTopGapStyle.size),
      );
      field.appendChild(desc.node);
      descriptions.push(desc);
    }
    comp.appendChild(field);
    lockWidth(comp, trigger.width);
    field.layoutSizingHorizontal = 'FILL';
    trigger.layoutSizingHorizontal = 'FILL';

    // The disabled picker mounts neither, and that is the widget's control flow
    // rather than a preview economy: `(widget.mode != .dialog && _enabled)
    // ? Popover(trigger: triggerButton, …) : triggerButton` builds no `Popover`
    // at all when disabled, and the dialog arm reaches `showDialog` only through
    // a `handleTap` that `_enabled ? … : null` has already removed. An open panel
    // over a trigger that cannot open it is a state this component has no way to
    // be in — the same reading ColorPicker's `if (!_isEnabled) return triggerRow;`
    // gets one builder up.
    if (enabled) {
      const pop = popoverPanel(
        lk,
        'popover panel',
        f.popoverStyle.panelStyle,
        dimVal(f.descriptionTopGapStyle.size),
      );
      pop.appendChild(
        instanceOf(page, 'Calendar', restingVariantName(page, 'Calendar', { Selection: 'Single' })),
      );
      comp.appendChild(pop);
      pop.visible = false;
      openPanels.push(pop);
      appendPopoverWrapper(page, comp);
      appendPromptDialog(comp, page, kDatePickerDialogTitle);
    }
  }
  const set = mount.finish();
  const openId = defineProp(set, 'Open', 'BOOLEAN', false);
  for (const p of openPanels) bindVisibleProp(p, openId);
  bindOptionalTextSlot(
    placeholders,
    defineProp(set, 'Show placeholderWidget', 'BOOLEAN', false),
    defineProp(set, 'placeholderWidget', 'TEXT', kDatePickerPlaceholder),
  );
  bindOptionalTextSlot(
    descriptions,
    defineProp(set, 'Show description', 'BOOLEAN', false),
    defineProp(set, 'description', 'TEXT', kDatePickerDescription),
  );
  bindOptionalTextSlot(
    labels,
    defineProp(set, 'Show label', 'BOOLEAN', false),
    defineProp(set, 'label', 'TEXT', kDatePickerLabel),
  );
  // Now that every instance is inside the set, the exposes are legal.
  exposeAll(pendingExposed);
  pendingExposed.length = 0;
  return set;
}

// `mode: .dialog` — the other half of `CorePromptMode`, and a real `Dialog`
// INSTANCE rather than a redrawn panel.
//
// Both pickers push it the same way: `showDialog(builder: … Dialog(title:
// dialogTitle, content: <the picker column>, dialogStyle: resolved.dialogStyle))`.
// `dialogStyle` is a whole forwarded `CoreDialogStyle` on `CoreDatePickerStyle`
// — the picker states the dialog's chrome through the child's own Style slot,
// which is what makes this a composition edge and not a resemblance. A hand-
// drawn copy would keep painting last year's Dialog: a parent whose own recipe
// did not change is skipped by the content hash, so it never gets a chance to
// notice the child moved.
//
// ABSOLUTE and HIDDEN, for the reason `appendPopoverWrapper` gives one slot
// over: the two prompt modes are exclusive branches of one `build`, and every
// variant these two sets mount is in the POPOVER one. That is the widgets' own
// default (`mode ?? .popover` in both) and their own control flow —
// `if (resolvedMode == .dialog) return triggerButton;` returns the bare trigger
// and pushes the dialog as a route, while popover mode returns
// `Popover(trigger:, content:)` and builds no dialog at all. Neither picker
// carries a `Mode` axis here (`Error=…` / `Focus=…` are the axes), so a
// visible, in-flow dialog is both halves of that branch rendering at once: a
// second full card stacked under the populated popover panel, complete with
// Dialog's own delete-confirmation body and Cancel/Confirm pair, and — since
// `buildDialog` locks `panelMaxWidth` — 512px of forced width on a picker whose
// trigger is a field. Invisible it costs the canvas nothing (auto-layout skips
// hidden children, and an absolute child is out of the parent's sizing
// altogether) while a designer who toggles the layer reaches the real `Dialog`,
// which is the point of composing it rather than describing it. Named for that
// reason too: a hidden layer's name in the panel is the only handle it has, and
// an instance of a set member inherits the member's variant key (`Actions=…`)
// rather than the component name.
//
// The member is the one `actionsLayout` rests on. Neither picker states
// anything about the actions row — `CoreDatePickerStyle.defaultDialogStyle` is
// empty and `CoreTimePickerStyle.dialogStyle` has no default — so the dialog
// each pushes resolves Dialog's own. Named rather than left to `instanceOf`,
// which on a set returns whichever member sorts first.
//
// `content:` is left as Dialog's own default. The picker fills it with the very
// column drawn above (a `Calendar` instance / the segment row), and Figma
// refuses to add children to an instance — so repeating it is not available,
// and Dialog's default content is what an unfilled slot looks like. The
// instance is exposed so the designer reaches Dialog's own `Title` / `Content`
// from the picker's panel.
//
// That exposure is also the whole story for these two pickers' `dialogTitle`
// slot, and the reason it gets no property of its own here. `dialogTitle` IS
// `Dialog(title:)` — the node that renders it belongs to the composed instance,
// and a picker-level property cannot bind to it: Figma rejects
// `componentPropertyReferences` on an instance sublayer, and inventing a second
// title node outside the panel would put a property in the panel that moves a
// label the dialog does not use. The affordance a designer needs is already
// reachable through the exposed instance; what is missing is only the
// DECLARATION, and closing that needs nested-property forwarding — an
// `InstanceNode.componentPropertyReferences` mapping the child's property key
// to the parent's id, which none of helpers.ts's three binders
// (`bindTextProp` / `bindVisibleProp` / `bindSwapProp`) expose. ColorPicker's
// same-named slot IS bound, because ColorPicker has no `Dialog`: it renders
// `?widget.dialogTitle` itself, at the top of its own popover column.
function appendPromptDialog(host: ComponentNode, page: PageNode, title: string): InstanceNode {
  const dialog = instanceOf(
    page,
    'Dialog',
    restingVariantName(page, 'Dialog', { Actions: DIALOG.fields.actionsLayout.choice }),
  );
  dialog.name = 'Dialog';
  host.appendChild(dialog);
  setInstanceTextNamed(dialog, kDialogTitleProp, title);
  pinAbsolute(host, dialog, 0, 0, { horizontal: 'MIN', vertical: 'MIN' }).visible = false;
  pendingExposed.push(dialog);
  return dialog;
}

// The TimePicker trigger — `TextField(readOnly: true, showCursor: false,
// textFieldStyle: resolved.triggerStyle, suffix: Icon(clock))`, the DatePicker /
// Select input look. The field is a composed `TextField` INSTANCE, so its box
// (height 40, corner 10, the `outline-variant` edge, the `primary` focus edge)
// is the field's own `md` row and nothing here restates it.
//
// What the picker itself decides, and so what is written here:
//   - the clock in the suffix seat, at `trailingIconStyle.size`, in the
//     icon tone (`trailingIconStyle.color`);
//   - the value colour (`contentColor`) — an enabled picker only; a disabled
//     one leaves the field's own disabled tone, as the widget does;
//   - the pressed-only state layer (`triggerStyle.stateLayer`): hover and focus
//     show no wash, because the border stepping and the ring already say it;
//   - no caret — `showCursor: false`, and the field's `focus` member draws one.
//
// The trigger fills the width its parent gives it (no fixed width).
//
// `Focus` puts the CLOSED trigger in the field's `focus` pose (the `primary`
// edge) and draws nothing else: the segment being edited inside the open panel
// is marked by its `primary-container` face and `primary-text` inside border,
// which are part of the panel, not of the pose.
function appendTimeTrigger(
  page: PageNode,
  host: FrameNode,
  lk: VarLookup,
  o: { enabled: boolean; focused: boolean; hasError: boolean },
): InstanceNode {
  const f = TIME_PICKER.fields;
  const state = !o.enabled ? 'disabled' : o.focused ? 'focus' : 'enabled';
  const trigger = textFieldInstance(
    page, kTimeExampleDisplay, o.enabled, state,
    o.enabled && o.hasError ? 'error' : 'defaultVariant',
  );
  trigger.name = 'trigger';
  const ramp = f.triggerStyle.stateLayer;
  const washWeight = o.focused ? ramp.focus : null;
  for (const layer of trigger.findAll((n) => n.name === 'state layer')) {
    layer.visible = washWeight != null && washWeight > 0;
    if (washWeight != null && 'opacity' in layer) layer.opacity = washWeight;
  }
  let hiddenCarets = 0;
  for (const caret of trigger.findAll((n) => n.name === 'caret')) {
    caret.visible = false;
    hiddenCarets += 1;
  }
  if (o.focused && o.enabled && hiddenCarets === 0) {
    throw new Error(
      'TimePicker: the focus trigger has no \'caret\' node to hide — the ' +
        'composed TextField renamed its caret, and the picker would show a ' +
        'cursor `showCursor: false` never paints.',
    );
  }
  host.appendChild(trigger);
  if (o.enabled && o.hasError) {
    // The widget forwards errorText to TextField: reuse its error helper.
    setInstanceBoolNamed(trigger, 'Show description', true);
    setInstanceTextNamed(trigger, 'Description', '올바른 시간을 입력해 주세요');
  }
  const iconSize = dimVal(f.trailingIconStyle.size);
  setSlotIcon(
    trigger,
    'suffix',
    iconMainIdAt(page, iconSize),
    'clock',
    glyphPaint(
      lk,
      labelColor(
        lk,
        colorData(o.enabled ? f.trailingIconStyle.color : TEXT_FIELD_DISABLED_FOREGROUND),
      ),
    ),
  );
  bindSize(namedDescendant(trigger, 'suffix'), lk, f.trailingIconStyle.size, f.trailingIconStyle.size);
  // A disabled picker leaves both colours to the field's disabled tone — the
  // clock too, which the resolvers hand over untinted (`withoutColor`).
  if (o.enabled) {
    applyInstanceTextStyle(
      namedDescendant(trigger, kFieldValueName),
      lk,
      textStyleData({ role: null, color: f.contentColor }),
    );
  }
  return trigger;
}

// TimePicker's POSE axis is `Focus`: the closed trigger in the field's `focus`
// pose (the `primary` edge) — and only that. The segment being edited in the
// open panel wears a `primary-container` face and an inside border, not an
// outer ring, and is always drawn, so `Focus` has nothing to add inside it.
//
// `Enabled` is the schema's axis here, and it arrives exactly as DatePicker's
// does (`time_picker.axes` promotes `enabled` and nothing else; its
// `axes.other` is empty). The loose COMPONENT is adopted as
// `Enabled=true, Focus=false`.
//
// The trigger keeps `triggerBorderWidth` (its own stated border) and stops
// carrying a colour that belongs to a field two levels down.
//
// `triggerHeight` is the trigger's own field and drives the closed trigger.
// Below it is the open popover — the widget's
// `Popover(trigger: triggerButton, content: _TimePickerPopoverContent(…))`,
// which is where `segmentSurfaceColor` / `segmentBorderColor` /
// `segmentBorderRadius` / `segmentSize` / `segmentHeight` actually belong.
function buildTimePicker(page: PageNode, lk: VarLookup): ComponentSetNode {
  dropStaleExposes();
  const f = TIME_PICKER.fields;
  const names = withPose(
    withPose(enumerateAxisCombos(axisSpecsOf(TIME_PICKER.axes)), 'Focus', kBooleanPose),
    'Error',
    kBooleanPose,
  );
  const mount = mountSet(page, 'TimePicker', names, {
    adoptLooseAs: composeVariantName([['Enabled', 'true'], ['Focus', 'false'], ['Error', 'false']]),
  });
  // The open panel per enabled member — see ColorPicker for why it rests
  // hidden behind an `Open` property.
  const openPanels: SceneNode[] = [];
  for (const name of names) {
    const axes = parseVariantKey(name);
    const enabled = axes['Enabled'] !== 'false';
    const focused = axes['Focus'] === 'true';
    const comp = mount.getOrCreate(name);
    applyPanelCompChrome(comp, 'VERTICAL', lk, {
      gap: dimVal(f.popoverStyle.placementOffset),
    });
    const field = panel('field', 'VERTICAL', lk, {});
    const trigger = appendTimeTrigger(page, field, lk, { enabled, focused, hasError: axes['Error'] === 'true' });
    comp.appendChild(field);
    lockWidth(comp, trigger.width);
    field.layoutSizingHorizontal = 'FILL';
    trigger.layoutSizingHorizontal = 'FILL';
    // The panel and the dialog are both unreachable when disabled — the trigger's
    // `onPressed` is the only thing that calls `_popoverController.toggle()` or
    // `_openDialog`, and `widget.enabled ? … : null` has already taken it away. So
    // the disabled half draws the closed trigger and nothing else, which also
    // means `Focus=true` has nothing to say there: the ring lives on a segment
    // inside a panel a disabled field never opens, and a disabled input cannot
    // hold focus in the first place. Those two variants render alike, and that is
    // the honest picture of a matrix that accepts the combination.
    //
    // The `Popover` WRAPPER stays on both halves, because the widget builds it on
    // both: unlike DatePicker's, TimePicker's `Popover(…)` sits outside the
    // enabled check (only its trigger's callback is gated), so the composed edge
    // is there whether or not it can open.
    if (enabled) {
      const pop = timePopover(page, lk);
      comp.appendChild(pop);
      pop.visible = false;
      openPanels.push(pop);
    }
    appendPopoverWrapper(page, comp);
    if (enabled) appendPromptDialog(comp, page, kTimePickerDialogTitle);
  }
  const set = mount.finish();
  const openId = defineProp(set, 'Open', 'BOOLEAN', false);
  for (const p of openPanels) bindVisibleProp(p, openId);
  // Now that every instance is inside the set, the exposes are legal.
  exposeAll(pendingExposed);
  pendingExposed.length = 0;
  return set;
}

// `_TimePickerPopoverContent` — the same column both the popover and the dialog
// mount, so it is drawn once here.
//
//   Row  — `_buildSegmentField` (hour), `_buildSeparator`, `_buildSegmentField`
//          (minute), then `Gap(dialogOuterGapStyle)` and `_AmPmToggle`.
//   Row  — `Button(variant: .ghost)` Cancel and the default-variant Save,
//          spaced by `separatorPadding.left`, pushed to the trailing edge.
//
// A third `second` segment appears only when `showSeconds` is passed (the
// widget declares `showSeconds = false`), and `_AmPmToggle` disappears under a
// 24-hour locale — both are call-site conditions, not chrome, so the preview
// draws the declared default.
//
// Each segment is a `Container(width: segmentSize, height: segmentHeight)` that
// owns the boundary with a deliberately chromeless `TextField` inside it
// (`backgroundColor: .transparent, borderColor: .transparent, borderWidth: 0,
// padding: .zero, textAlign: .center, valueStyle: valueTypography + segment
// content colour`), so the whole of that forward is applied to the composed
// instance — see `applyChromelessSegmentField` for which node carries what.
//
// A segment is a COLUMN, not just that box: `_buildSegmentField` returns
// `Column(spacing: dialogLabelSpacing, [box, Text(label)])`, and the caption is
// the only place `helperTypography` is spent (`resolveTypographyRole(theme,
// helperTypography).copyWith(color: labelColor)` — the role for the metrics, the
// field for the colour). Drawn now: without it the popover showed two unlabelled
// boxes, and a designer had no way to tell the hour from the minute.
function timePopover(page: PageNode, lk: VarLookup): FrameNode {
  const f = TIME_PICKER.fields;
  const segmentWidth = dimVal(f.segmentSize);
  const segmentHeight = dimVal(f.segmentHeight);
  const segmentRadius = dimVal(f.segmentBorderRadius.topLeft);
  const actionGap = dimVal(f.separatorPadding.l);
  const outerGap = dimVal(f.dialogOuterGapStyle.size);
  // `spacing: dialogLabelSpacing` — the same field the am/pm column below uses,
  // because `_buildSegmentField` and `_AmPmToggle` are handed the same one.
  const labelSpacing = dimVal(f.dialogLabelSpacing);

  const pop = popoverPanel(
    lk,
    'popover panel',
    f.popoverStyle.panelStyle,
    dimVal(f.actionRowGapStyle.size),
  );

  const row = panel('segments', 'HORIZONTAL', lk, {});
  // `TypographyTierScope(tier: .desktop)` around this row in both widgets: the
  // digits fill a cell whose size does not follow the tier, so they keep the
  // desktop size at every width. Unpinned, the canvas resolves the value role
  // in the collection's default mode (Mobile) and drew 28 as 20 (#6201).
  const desktop = lk.typographyTierMode('Desktop');
  // Guarded the way `icon-content.ts` guards its slot modes: every Figma frame
  // carries the setter, a scratch double that builds this entry may not.
  if (desktop && typeof row.setExplicitVariableModeForCollection === 'function') {
    row.setExplicitVariableModeForCollection(desktop.collection, desktop.modeId);
  }
  // `crossAxisAlignment: .start` is Figma's own default for a row
  // (`counterAxisAlignItems = 'MIN'`), so nothing is written for it — but it is
  // load-bearing now that a segment is taller than the colon beside it.
  const segments = [
    { value: kTimeExampleHour, caption: kTimeHourCaption },
    { value: kTimeExampleMinute, caption: kTimeMinuteCaption },
  ];
  for (let i = 0; i < segments.length; i++) {
    if (i > 0) row.appendChild(timeSeparator(lk));
    const cell = panel('segment field', 'VERTICAL', lk, { gap: labelSpacing });
    cell.counterAxisAlignItems = 'CENTER';
    const box = panel('segment', 'HORIZONTAL', lk, { radius: segmentRadius });
    box.primaryAxisSizingMode = 'FIXED';
    box.counterAxisSizingMode = 'FIXED';
    box.primaryAxisAlignItems = 'CENTER';
    box.counterAxisAlignItems = 'CENTER';
    // The hour segment is drawn as the one being edited (its focused face and
    // inside border); the others rest. One segment is edited at a time on a
    // real page.
    const edited = i === 0;
    fillData(
      box,
      lk,
      colorData(edited ? f.segmentFocusedSurfaceColor : f.segmentSurfaceColor),
    );
    // The edited segment's border is INSIDE the tile, in place of its resting
    // one: the segments sit next to each other in the popover, so a ring
    // outside one would cover its neighbour or be clipped at the panel edge.
    borderData(
      box,
      lk,
      colorData(edited ? f.segmentFocusedBorderColor : f.segmentBorderColor),
      edited ? f.segmentFocusedBorderWidth : dimVal(f.triggerBorderWidth),
    );
    box.strokeAlign = 'INSIDE';
    cell.appendChild(box);
    bindSize(box, lk, segmentWidth, segmentHeight);
    const value = textFieldInstance(page, segments[i].value);
    box.appendChild(value);
    applyChromelessSegmentField(value, lk, {
      width: segmentWidth,
      height: segmentHeight,
      // `valueStyle: widget.resolved.valueTypography.copyWith(color:
      // widget.resolved.segmentContentColor)` — the role for the metrics, the
      // field for the colour, which is exactly what `typographyColorOpts` is.
      value: typographyColorOpts(
        lk,
        textStyleData(f.valueTypography),
        colorData(edited ? f.segmentFocusedContentColor : f.segmentContentColor),
      ),
    });
    value.layoutSizingHorizontal = 'FILL';
    // `Text(label, style: resolveTypographyRole(theme, helperTypography)
    // .copyWith(color: labelColor))`.
    cell.appendChild(
      makeLabel(
        segments[i].caption,
        lk,
        typographyColorOpts(lk, textStyleData(f.helperTypography), colorData(f.labelColor)),
      ),
    );
    row.appendChild(cell);
  }

  // `Gap(gapStyle: dialogOuterGapStyle)` then `_AmPmToggle` — one vertical
  // `ToggleGroup` (AM above PM) straight in the row. Its two `sm` segments make
  // the tile's 60 (3 + 26 + 2 + 26 + 3), and the row's `crossAxisAlignment:
  // .start` (Figma's default `MIN`, see above) puts its top on the tiles' top.
  const spacer = panel('gap', 'HORIZONTAL', lk, {});
  row.appendChild(spacer);
  bindSize(spacer, lk, outerGap, outerGap);
  const toggle = instanceOf(
    page,
    'ToggleGroup',
    // `Size=sm` (`CoreTimePickerContract.defaultAmPmToggleSize`) ·
    // `Orientation=Vertical` (`defaultAmPmToggleDirection`) — the one column
    // shape the ToggleGroup set draws, at `Width=Hug`. `Hover=false`: the
    // resting pair, stated rather than left to the resting-name sort.
    restingVariantName(page, 'ToggleGroup', {
      Size: 'sm',
      Enabled: 'true',
      Selected: kTimeExamplePeriodOrdinal,
      Width: 'Hug',
      Hover: 'false',
      Orientation: 'Vertical',
    }),
  );
  // `localizations.timeAM` / `timePM` — the Korean chrome strings
  // (`coui_i10n/chrome/i18n/ko.i18n.json`), the locale the canvas is drawn in.
  setInstanceTextNamed(toggle, 'Option 1 label', '오전');
  setInstanceTextNamed(toggle, 'Option 2 label', '오후');
  // Two segments: the third is the group's spare.
  setInstanceBoolNamed(toggle, 'Show option 3', false);
  // `amPmToggleStyle`'s default restates the track one step up — the toggle
  // sits on the panel (see the ColorPicker mode tabs).
  fillData(toggle, lk, colorData(f.amPmToggleStyle.backgroundColor));
  row.appendChild(toggle);
  pop.appendChild(row);

  // `Row(mainAxisAlignment: .end, spacing: separatorPadding.left)`. The
  // trailing alignment only bites once the row has a definite width, and the
  // panel hugs its segment row — so the row is left hugging here rather than
  // filled against a width this builder would have to invent.
  const actions = panel('actions', 'HORIZONTAL', lk, { gap: actionGap });
  actions.primaryAxisAlignItems = 'MAX';
  actions.appendChild(labelButton(page, { variant: 'ghost', size: kTriggerButtonSize, label: '취소' }));
  actions.appendChild(labelButton(page, { variant: 'primary', size: kTriggerButtonSize, label: '저장' }));
  pop.appendChild(actions);
  return pop;
}

// `_buildSeparator` — `Padding(padding: separatorPadding, child: Text(':'))`.
//
// Both halves of that `Text` are fields. The colour is `contentColor` and the
// size comes from `separatorTypography` (`headlineSmall` at medium), which is
// the pair the widget composes: `resolveTypographyRole(theme,
// separatorTypography).copyWith(color: separatorColor)`. `typographyColorOpts` IS that `copyWith` —
// the role supplies size / weight / line-height and the colour field always
// wins over the role's own — so the colon is read here rather than sized.
//
// It has to be READ rather than passed, and a literal is silent when it is
// wrong: a hand-written 14 here draws the colon at under a third of its 44px,
// between two 72px segment boxes, with every gate green. Field coverage counts
// `valueTypography` as reached because the field does arrive in the JSON;
// whether the canvas then honours it is a different question, and the only
// thing that asks it is the fidelity readback. Nor does the literal ratchet
// see it — that guard matches a named `size:` key or one of its listed box
// helpers, and a bare third argument to `glyphOpts` is neither. A role NAME
// reaching a builder while its metrics do not is the defect that once had all
// 218 text styles at 14.
//
// A `glyphOpts` size would be wrong here even at 44: that helper is for a mark
// whose dimension traces to `CoreSize`/`CoreIconSize` (a checkmark, an arrow).
// This colon is type, its size traces to `CoreFontSize` through the role, and
// only the role carries the weight and line-height that go with it.
function timeSeparator(lk: VarLookup): FrameNode {
  const f = TIME_PICKER.fields;
  const box = panel('separator', 'HORIZONTAL', lk, {});
  box.counterAxisAlignItems = 'CENTER';
  bindPad(box, lk, f.separatorPadding);
  box.appendChild(
    makeLabel(
      ':',
      lk,
      typographyColorOpts(lk, textStyleData(f.separatorTypography), colorData(f.separatorColor)),
    ),
  );
  // As tall as a segment tile with the colon centred in it — the widget's
  // `SizedBox(height: segmentHeight, child: Center(...))` (Web: `height:
  // segmentHeight` + `align-items: center`). The row aligns to the top, so a
  // box that hugged the glyph would park the colon at the tiles' upper edge.
  box.counterAxisSizingMode = 'FIXED';
  bindAxisSize(box, lk, { width: box.width, height: dimVal(f.segmentHeight), bind: 'height' });
  box.primaryAxisSizingMode = 'AUTO';
  return box;
}

// ─── Calendar (month grid) ───────────────────────────────────────────────────
//
// Every button in this grid is a `Button` in code, so every one is an instance
// here: nav arrows are `Button(variant: .outline, size: .sm, buttonStyle:
// navButtonStyle, child: Icon(…))`, the header title is
// `Button(variant: .ghost, size: .sm)`, and a date cell is
// `Button(variant: .ghost | .primary, size: .sm, buttonStyle:
// dateCellNormalStyle | dateCellSelectedStyle)`. The forwarded slots
// (`navButtonStyle` / `dateCellStyle`, both `CoreButtonStyle`) supply each
// instance's padding and corner radius — that is where the zeros and the 8
// come from, and it is why the cells hug their label instead of carrying
// Button's own 12px side padding.
//
// `Selection` is the axis, and it has three values because the widget's value
// type does: `CoreCalendarValue` is null, `.single(date)`, or `.range(a, b)`, and
// `_buildDayCell` switches on `calendarValue.lookup(...)` to pick which of its six
// cell branches each date takes.
//
//   None    nothing chosen — every date is the `.none` branch, except today.
//   Single  day 23 wears `selectedColor` behind `selectedTextStyle.color` —
//           exactly the pair `dateCellSelectedStyle` is built from in the resolver
//           (`dateCellDefault.copyWith(backgroundColor: selectedColor,
//           foregroundColor: selectedTextStyle.color)`).
//   Range   `Calendar.range(...)`, which is a TWO-month layout
//           (`_isRange ? _buildRangeLayout : _buildSingleLayout`) whose grids
//           carry the three range branches — `.startRangeSelected` /
//           `.endRangeSelected` (a half-cell band under an endpoint pill) and
//           `.inRange` (a flat full-cell band). Those three are the only place
//           `rangeSelectionColor` / `rangeSelectionTextStyle` /
//           `endpointPillBorderRadius` are spent, so with the axis at two values
//           all three were stated by Core and drawn nowhere.
//
// An axis rather than a fourth value on the old boolean: `Selected=true` and a
// range are not compatible states, and 2×2 would have offered a variant
// ("selected, but also ranged") the value type cannot be in. The two existing
// members are renamed into it — see `VARIANT_RENAMES` in `src/renames.ts`, without
// which `mountSet.finish()` refuses to touch a set whose old names this builder no
// longer produces — the entry fails and leaves the half-built set on the page.
//
// TODAY is not on the axis. `_buildDayCell` reaches `.today` when the lookup is
// `.none` AND the date is `DateTime.now()`, so it is orthogonal to the selection
// and present in every variant whose grid contains today — which for a preview
// fixed at June 2026 is a statement about the preview's copy, the same kind as
// "2026년 6월" and "23" already are.
//
// The calendar draws NO surface of its own, and that is the widget rather than
// an omission: `build` returns `Semantics > IntrinsicWidth > Column` — no
// background, no border, no radius, no padding. The box that used to be here
// (surface fill, outline border, radius 16, 16 all round) had no field behind it
// and was labelled builder-original, which is the softest way to say invented.
//
// It cost more than a wrong outline. `DatePicker` mounts this component inside
// its popover panel, and that panel's 16px `CorePopupStyle` padding is real — so
// the canvas showed the panel, then a 16px moat, then a SECOND rounded bordered
// box holding the grid. Two frames where the app draws one, and the moat between
// them is the padding a reader sees first. A component that paints a surface
// nobody asked for cannot be composed by anything.
//
// Month/year picker fields (`monthCellWidth` / `yearGridSize` /
// `monthGridColumns` / `yearGridColumns` / `yearRowSpacing`) belong to calendar
// modes this single-month preview does not render.
//
// `arrowIconStyle` states a size and no colour, and `navButtonStyle` overrides no
// foreground — so calendar says nothing about what colour this glyph is. What the
// app shows comes from the child instead: the glyph inherits `IconTheme` from the
// `Button` around it (`button.dart` wraps its content in `IconTheme.merge`), so
// both widgets paint Button's own `outline` foreground, on-surface.
//
// The glyph needs a colour named here either way, and that is Figma's constraint
// rather than a choice: an instance refuses appended children, so the glyph rides
// above the Button as an absolutely-positioned sibling and inherits no IconTheme
// to pick a colour up from.
function navButton(page: PageNode, lk: VarLookup, icon: string, side: number): FrameNode {
  const f = CALENDAR.fields;
  return iconButton(page, lk, {
    variant: 'ghost',
    size: kCalendarButtonSize,
    icon,
    iconSize: dimVal(f.arrowIconStyle.size),
    // g7-preview-only: no calendar field states this glyph's colour — `arrowIconStyle` carries only a size and `navButtonStyle` overrides no foreground, so the colour the app shows is the composed Button's own `outline` foreground, which is that child's default and not this parent's to read. The sibling glyph inherits no IconTheme from the instance, so a colour must be named at this call; it names a lower-contrast token than either widget renders, and that gap is recorded here rather than closed by copying Button's value into calendar's builder.
    colorVar: lk.sem('on-surface-variant'),
    side,
    pad: f.navButtonStyle.padding,
    // The corner only if the slot states one. It states none: the arrows are
    // `Button(size: .sm)`, so their corner is that size row's (the control
    // height × 0.25), which the `sm` instance already draws.
    borderRadius: optField<{ topLeft: Dim }>(f.navButtonStyle, 'borderRadius'),
  });
}

// Which of `_DayCellType`'s six branches a date takes — the switch
// `_buildDayCell` performs on `calendarValue.lookup(...)`, spelled as the states
// this preview can be in.
//
// `none` and `today` come from the same `lookup == .none` arm (today wins when the
// date is `DateTime.now()`), the other four from the four non-null lookups.
type DayCellState = 'none' | 'today' | 'selected' | 'inRange' | 'startRange' | 'endRange';

// One date cell in a `Button` branch — `.none`, `.today`, `.selected`, and the
// endpoint pill the two range branches stack over their band.
//
// The `Button`'s variant is the widget's own per-branch choice: `.ghost` for a
// plain date or today (today adds an outline), `.primary` for a selected one or an endpoint.
//
// A cell from a neighbouring month is the same `Button`, wrapped: the only thing
// `fromAnotherMonth` changes is `Opacity(opacity: resolved.fadedOpacity)` around
// the finished cell. Which is why the grid below has no empty slots — see there.
function dayCell(
  page: PageNode,
  lk: VarLookup,
  o: { label: string; state: DayCellState; faded: boolean; side: number },
): InstanceNode {
  const f = CALENDAR.fields;
  const filled = o.state === 'selected' || o.state === 'startRange' || o.state === 'endRange';
  const cell = instanceOf(
    page,
    'Button',
    restingVariantName(page, 'Button', {
      Variant: filled ? 'primary' : 'ghost',
      Size: kCalendarButtonSize,
    }),
  );
  setInstanceTextNamed(cell, kButtonLabelProp, o.label);
  applyForwardedButtonStyle(cell, lk, {
    padding: f.dateCellStyle.padding,
    // An endpoint pill takes `endpointPillBorderRadius` instead of the cell's own
    // corner. Web is where that field lands (`buildRangeEndpointPill` emits it
    // inline on the pill div and nothing else reads it); Flutter resolves it into
    // `ResolvedCalendar` and its pill `Button` carries `dateCellSelectedStyle`'s
    // corner, which is the same 8. Reading the field here puts the number on the
    // node that states it, so an override of either reaches the canvas.
    // A plain cell's corner is the slot's only if it states one — it states
    // none, so the `sm` cell keeps its own size row's.
    borderRadius:
      o.state === 'startRange' || o.state === 'endRange'
        ? f.endpointPillBorderRadius
        : optField<{ topLeft: Dim }>(f.dateCellStyle, 'borderRadius'),
  });
  if (filled) {
    // The parent supplies both of these in code, so they are overridden here
    // rather than left to Button's `primary` variant — same values, but sourced
    // from the field a caller can change.
    fillData(cell, lk, colorData(f.selectedColor));
    const text = instanceTextNode(cell);
    if (text) fillData(text, lk, colorData(f.selectedTextStyle.color));
  }
  // Today's fill stays the cell's own: `todayColor` reaches no value (a constant
  // here would paint over the variant's fill — the field's own doc says so). Its
  // label takes `todayTextStyle` over the cell slot: `bodySmall` at SemiBold in
  // `primary`, the slot both resolvers forward whole as the today `Button`'s
  // `labelStyle`.
  // Every cell takes `cellTextStyle` — the role the widget forwards as the cell
  // `Button`'s `labelStyle`. Unread, so the dates rendered at `Button`'s own row
  // size and the grid's numbers were the wrong size everywhere.
  applyInstanceTextStyle(cell, lk, textStyleData(f.cellTextStyle));
  // A selected date and both range endpoints take `selectedTextStyle` over the
  // cell slot — the widget's `dateCellSelectedStyle.labelStyle` on Flutter, the
  // selected `Button` / endpoint pill label on Web. The slot keeps the cells'
  // `bodySmall` role and raises only the weight (Medium), with `onPrimary`.
  if (filled) applyInstanceTextStyle(cell, lk, textStyleData(f.selectedTextStyle));
  if (o.state === 'today') {
    applyInstanceTextStyle(cell, lk, textStyleData(f.todayTextStyle));
    // Today is a ghost cell marked by a line, not a fill: the widget states
    // `todayBorderColor` / `todayBorderWidth` on the cell `Button`.
    borderData(cell, lk, colorData(f.todayBorderColor), dimVal(f.todayBorderWidth));
  }
  //
  // On the node, which is where `Opacity` sits in the widget — it fades the
  // whole cell, label included, not one of its paints.
  if (o.faded) cell.opacity = dimVal(f.fadedOpacity);
  cell.resize(o.side, o.side);
  return cell;
}

// A range cell — the two branches that are not a bare `Button`.
//
// `.inRange` is a `Clickable` around `Container(color: rangeSelectionColor, child:
// DefaultTextStyle(color: rangeSelectionTextColor, dayText))`: a flat full-cell
// band, deliberately square-cornered, which is what makes a run of them read as
// one continuous strip.
//
// `.startRangeSelected` / `.endRangeSelected` are `Stacks(fit: .passthrough,
// clipBehavior: .none, [Position.fill(left|right: itemSize / 2, band), Button])` —
// the band on the half of the cell the range continues into, the endpoint pill
// drawn over it. Web builds the same two nodes (`rangeStripStart` is
// `absolute top-0 bottom-0 right-0 w-1/2`, so the START band is the TRAILING half
// and the END band the leading one — Flutter's `Position.fill(left: itemSize / 2)`
// says the same thing from the other side).
//
// A plain FRAME with no auto-layout, because a Figma stack IS that: children are
// placed by x / y and paint in append order, so the band goes down first and the
// pill over it, exactly the order the widget's `children` list gives them.
//
// `faded` is threaded through even though this preview's range sits inside one
// month and so never hands it `true`: `if (item.fromAnotherMonth) return
// Opacity(…)` in the widget wraps the FINISHED cell whatever branch it took, so a
// range that crosses a month boundary fades its endpoint like any other date. The
// parameter is the widget's shape rather than this preview's reach.
function rangeCell(
  page: PageNode,
  lk: VarLookup,
  o: { label: string; state: 'inRange' | 'startRange' | 'endRange'; faded: boolean; side: number },
): FrameNode {
  const f = CALENDAR.fields;
  const cell = autoFrame('range cell', 'HORIZONTAL');
  // `clipBehavior: .none` on the Stacks, and it matters: the pill's corner radius
  // is larger than the band's square one, so a clipping frame would shave the
  // pill's rounded edge back to the cell rectangle.
  cell.clipsContent = false;

  if (o.state === 'inRange') {
    // The band IS the cell here — one `Container`, no stack.
    fillData(cell, lk, colorData(f.rangeSelectionColor));
    cell.primaryAxisSizingMode = 'FIXED';
    cell.counterAxisSizingMode = 'FIXED';
    cell.primaryAxisAlignItems = 'CENTER';
    cell.counterAxisAlignItems = 'CENTER';
    cell.resize(o.side, o.side);
    cell.appendChild(
      makeLabel(
        o.label,
        lk,
        // `bodySmall` + `onPrimaryContainer`, both off `rangeSelectionTextStyle` — the
        // role for the metrics and the colour the slot carries, which is the pair
        // `DefaultTextStyle.merge(TextStyle(color: rangeSelectionTextColor))` over
        // `dayText` composes. Web states the same two on `inRangeCell`
        // (`text-bodySmall` + `rangeTextEmit`).
        typographyColorOpts(
          lk,
          textStyleData(f.rangeSelectionTextStyle),
          colorData(f.rangeSelectionTextStyle.color),
        ),
      ),
    );
  } else {
    // A Figma stack is a frame with no auto-layout: children keep the x / y they
    // are given and paint in append order.
    cell.layoutMode = 'NONE';
    cell.resize(o.side, o.side);
    const band = figma.createRectangle();
    band.name = 'range band';
    fillData(band, lk, colorData(f.rangeSelectionColor));
    cell.appendChild(band);
    band.resize(o.side / kBothSides, o.side);
    band.x = o.state === 'startRange' ? o.side / kBothSides : 0;
    band.y = 0;
    const pill = dayCell(page, lk, { label: o.label, state: o.state, faded: false, side: o.side });
    cell.appendChild(pill);
    pill.x = 0;
    pill.y = 0;
  }
  if (o.faded) cell.opacity = dimVal(f.fadedOpacity);
  return cell;
}

// One row of `CoreCalendarGridData(month: 6, year: 2026)` — the month the header
// names, laid out the way the widget lays it out.
//
// The grid is not "the 30 days and then blanks". `CoreCalendarGridData` opens
// with `firstDayOfMonth.weekday % 7` days of the PREVIOUS month and closes with
// however many of the NEXT month it takes to finish the last row, and both sets
// are real cells carrying real numbers — faded, not absent. June 1 2026 is a
// Monday and the row starts on Sunday, so one day of May leads and four of July
// trail: 35 cells, exactly five rows, no gaps.
//
// Spelled out rather than computed from a date library the plugin does not have.
// The month is preview copy — it is what the header says — so what matters is
// that the grid and the header agree, which a hand-written list makes checkable
// in one glance and a `Date` arithmetic helper would not.
interface CalendarCell {
  label: string;
  /** `fromAnotherMonth` — a May or July day sitting in June's grid. */
  faded: boolean;
}

const kCalendarCells: readonly CalendarCell[] = (() => {
  const cells: CalendarCell[] = [{ label: '31', faded: true }];
  const kJuneDays = 30;
  for (let day = 1; day <= kJuneDays; day++) cells.push({ label: String(day), faded: false });
  const kJulyLeadIn = ['1', '2', '3', '4'];
  for (const label of kJulyLeadIn) cells.push({ label, faded: true });
  return cells;
})();

// The month beside it in the range layout, by the same rule. July 1 2026 is a
// Wednesday, so `weekday % 7` is 3 and three June days lead; 3 + 31 = 34 leaves one
// day of August to finish the fifth row.
const kCalendarNextCells: readonly CalendarCell[] = (() => {
  const kJuneLeadIn = ['28', '29', '30'];
  const cells: CalendarCell[] = kJuneLeadIn.map((label) => ({ label, faded: true }));
  const kJulyDays = 31;
  for (let day = 1; day <= kJulyDays; day++) cells.push({ label: String(day), faded: false });
  cells.push({ label: '1', faded: true });
  return cells;
})();

// The date `Selection=Single` picks, and it has to be a June day rather than an
// index: the grid opens on a May cell, so `kCalendarCells[23]` is not the 23rd.
const kCalendarSelectedLabel = '23';

// `Selection=Range` — `CoreCalendarValue.range(June 23, June 26)`, kept inside one
// month and one row (June 23 is `indexInRow` 2, June 26 is 5).
//
// Inside a row on purpose: `_buildDayCell` demotes an endpoint to a plain
// `.selected` when its band would run off the row's edge (`indexInRow == 0` for an
// end, `daysPerWeek - 1` for a start), and a preview that landed on that case would
// draw the demotion while looking like it was drawing the endpoint.
const kCalendarMonthNames = [
  '1월', '2월', '3월', '4월', '5월', '6월',
  '7월', '8월', '9월', '10월', '11월', '12월',
];
// The first year the year pane lists. `_YearGrid` starts at `_yearSelectStart`,
// a runtime cursor, so the preview picks the year its day grid already shows.
const kCalendarYearStart = 2026;
const kCalendarRangeStart = 23;
const kCalendarRangeEnd = 26;

// The day `_buildDayCell` reaches its `.today` branch on — `lookup == .none` and
// `now`. Preview copy, like the month it sits in; chosen away from the range so the
// two states are both visible at once.
const kCalendarTodayLabel = '15';

// Which branch a cell takes, given the selection this variant carries.
//
// Day NUMBERS are matched, real dates are what the widget matches, and the two
// differ in exactly two places — both of which have to answer `none`:
//
//   · a faded cell, whose number belongs to the month next door ('1'…'4' in June's
//     grid are July's, and June's own 1–4 sit four rows above them);
//   · every cell of the range layout's SECOND grid, which is a different month —
//     July 15 is not the June 15 that `DateTime.now()` matched, and reading the
//     label alone drew a second today one grid over.
//
// The first of those guards was already here for the single-date preview. The
// second arrived with the month beside it.
function dayCellState(
  cell: CalendarCell,
  selection: 'None' | 'Single' | 'Range',
  inThisMonth: boolean,
): DayCellState {
  if (cell.faded || !inThisMonth) return 'none';
  if (selection === 'Single' && cell.label === kCalendarSelectedLabel) return 'selected';
  if (selection === 'Range') {
    const day = Number(cell.label);
    if (day === kCalendarRangeStart) return 'startRange';
    if (day === kCalendarRangeEnd) return 'endRange';
    if (day > kCalendarRangeStart && day < kCalendarRangeEnd) return 'inRange';
  }
  return cell.label === kCalendarTodayLabel ? 'today' : 'none';
}

// The seven weekday letters, and the width every row in the grid shares.
//
// Seven cells and NO gaps. The week row is `Row(mainAxisAlignment: .center,
// children: rowItems)` with each item a `SizedBox.square(itemSize)` — there is no
// `spacing:` on it, and the Web twin puts the date rows on its no-gap row class
// (`gridRow`, while `gridRowGapped` is the MONTH grid's). `cellSpacing` is the
// COLUMN's spacing, between rows, which is where this file spends it.
//
// It used to be spent on both axes, and the range is what made that visible: eight
// pixels between adjacent dates break the band into disconnected blocks, and a run
// of `.inRange` cells reads as a continuous strip only because the cells touch.
const kWeekdayLetters: readonly string[] = ['일', '월', '화', '수', '목', '금', '토'];

// One month — `_DateGrid`: `Column(spacing: cellSpacing, [weekdayRow, ...weeks])`.
//
// Its own frame because its rows sit `cellSpacing` (8) apart while the header sits
// `headerGridGapStyle` (16) above it: hung straight off the component column, all
// six rows inherited the 16 and the grid stood half again as tall as the widget's,
// with the weekday letters drifting away from the dates they head.
function monthGrid(
  page: PageNode,
  lk: VarLookup,
  o: {
    cells: readonly CalendarCell[];
    selection: 'None' | 'Single' | 'Range';
    /** False for the second month of the range layout — its dates carry no
     *  selection and no today, both of which live in the month beside it. */
    inThisMonth: boolean;
  },
): FrameNode {
  const f = CALENDAR.fields;
  const cellGap = dimVal(f.cellSpacing);
  const cellSize = dimVal(f.dayCellSize);
  const grid = panel('grid', 'VERTICAL', lk, { gap: cellGap });

  // weekday row — one square per day, same metrics as the dates below it.
  const wd = panel('weekdays', 'HORIZONTAL', lk, {});
  for (const letter of kWeekdayLetters) {
    const cell = panel('wd', 'HORIZONTAL', lk, {});
    cell.primaryAxisAlignItems = 'CENTER';
    cell.appendChild(
      makeLabel(
        letter,
        lk,
        // Two fields, one for each half, because that is how the resolver composes
        // it: `defaultWeekdayTextStyle.merge(merged.weekdayTextStyle).toValue(color:
        // weekdayLabelColor …)` — the ROLE comes from `weekdayTextStyle` and the
        // COLOUR from `weekdayLabelTextStyle`, whose own role is only a carrier for
        // it. Reading the colour slot for both happened to draw the right size
        // (both roles are `labelMedium`) and would have gone on drawing it after
        // either moved.
        typographyColorOpts(
          lk,
          textStyleData(f.weekdayTextStyle),
          colorData(f.weekdayLabelTextStyle.color),
        ),
      ),
    );
    wd.appendChild(cell);
    lockWidth(cell, cellSize);
  }
  grid.appendChild(wd);

  // weeks — the month's cells in rows of seven. Every slot is a cell: the leading
  // and trailing ones belong to the neighbouring months and are faded, which is
  // what the widget does with them and the only place `fadedOpacity` is spent.
  for (let at = 0; at < o.cells.length; at += kWeekdayLetters.length) {
    const week = panel('week', 'HORIZONTAL', lk, {});
    for (const item of o.cells.slice(at, at + kWeekdayLetters.length)) {
      const state = dayCellState(item, o.selection, o.inThisMonth);
      week.appendChild(
        state === 'inRange' || state === 'startRange' || state === 'endRange'
          ? rangeCell(page, lk, { label: item.label, state, faded: item.faded, side: cellSize })
          : dayCell(page, lk, { label: item.label, state, faded: item.faded, side: cellSize }),
      );
    }
    grid.appendChild(week);
  }
  return grid;
}

// The header's month button — `_buildHeaderButton`, a `Button(variant: .ghost,
// size: .sm)` carrying `navButtonStyle`, stretched by its `Expanded`.
function headerTitle(page: PageNode, lk: VarLookup, month: string, side: number): InstanceNode {
  const f = CALENDAR.fields;
  const title = instanceOf(
    page,
    'Button',
    restingVariantName(page, 'Button', { Variant: 'ghost', Size: kCalendarButtonSize }),
  );
  setInstanceTextNamed(title, kButtonLabelProp, month);
  // `headerTextStyle` — the month button's own typography, which the widget
  // forwards through `navButtonStyle.labelStyle`. Unread, so the canvas showed
  // `Button`'s `sm` row size instead of the header role.
  applyInstanceTextStyle(title, lk, textStyleData(f.headerTextStyle));
  applyForwardedButtonStyle(title, lk, {
    padding: f.navButtonStyle.padding,
    // Stated nowhere in the slot — the month button keeps its `sm` row's corner.
    borderRadius: optField<{ topLeft: Dim }>(f.navButtonStyle, 'borderRadius'),
  });
  title.resize(title.width, side);
  return title;
}

// A fixed square / strip of empty space — the widget's own `SizedBox(width: …)`,
// which the range header uses twice to hold the place a nav arrow does not occupy.
function headerSpacer(lk: VarLookup, width: number, height: number): FrameNode {
  const spacer = panel('spacer', 'HORIZONTAL', lk, {});
  bindSize(spacer, lk, width, height);
  return spacer;
}

function buildCalendar(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = CALENDAR.fields;
  const gap = dimVal(f.headerGridGapStyle.size);
  const cellSize = dimVal(f.dayCellSize);
  const gridWidth = cellSize * kWeekdayLetters.length;

  const monthPanes: FrameNode[] = [];
  const yearPanes: FrameNode[] = [];
  const selections: readonly ('None' | 'Single' | 'Range')[] = ['None', 'Single', 'Range'];
  // `calendar.axes` promotes nothing — no variant, no size, no state, and
  // `enabled: false` (its four enums, date-state / selection-mode / value-lookup /
  // view-type, all sit in `axes.other`) — so `enumerateAxisCombos` answers the
  // empty list and `Selection` is the whole name. Routed through `withPose` all
  // the same, because that is where the ordering check lives.
  const names = withPose(
    enumerateAxisCombos(axisSpecsOf(CALENDAR.axes)),
    'Selection',
    selections,
  );
  // A loose COMPONENT named `Calendar` — what a page generated before this axis
  // existed carries — is adopted as `Selection=Single`, because that is what it
  // drew: one month with day 23 filled. Adoption keeps the node's id and `key`,
  // which is what every `Calendar` instance in `buildDatePicker` hangs off; a
  // rebuild would mint a new key and orphan them. (A page already carrying the
  // boolean SET is migrated by the `VARIANT_RENAMES` entries the header above
  // names, which is the other direction the same promotion can arrive from.)
  const mount = mountSet(page, 'Calendar', names, { adoptLooseAs: 'Selection=Single' });
  // Read back off the name rather than looped in parallel with it, so the member
  // this populates is the one `names` asked for — the cast is sound because that
  // value came out of `selections` one statement up.
  for (const name of names) {
    const selection = parseVariantKey(name)['Selection'] as 'None' | 'Single' | 'Range';
    const comp = mount.getOrCreate(name);
    // `IntrinsicWidth(child: Column(children: [header, Gap(headerGridGapStyle),
    // <grids>]))` — the outer Column carries no `spacing:` and has exactly two
    // real children, so its itemSpacing IS that one `Gap`. The rows INSIDE the
    // grid are a different number and get their own frame in `monthGrid`.
    applyPanelCompChrome(comp, 'VERTICAL', lk, { gap });

    if (selection === 'Range') {
      // `_buildRangeLayout` — two months side by side, and a header split in two
      // halves: the left one carries the back arrow and June's title, the right one
      // July's title and the forward arrow. Each half holds the place of the arrow
      // it does not have (`SizedBox(width: dayCellSize)` on the left, `dayCellSize +
      // headerGridGap` on the right), so both titles sit over the middle of their
      // own grid instead of drifting toward the outer edges.
      //
      // Explicit gap frames rather than an itemSpacing: the widget's `Gap`s are
      // interleaved, not uniform — its title and the spacer beside it are adjacent
      // with no gap between them, and one spacing for the row would have inserted
      // one.
      const head = panel('header', 'HORIZONTAL', lk, { gap });
      head.counterAxisAlignItems = 'CENTER';

      // [nav, Gap, title, SizedBox(dayCellSize), Gap] — five children, and the
      // trailing `Gap` belongs to this half rather than to the row that holds both.
      // That is what makes the two titles equal: each half spends one arrow width,
      // one arrow-width spacer and two gaps, so both titles get the grid width minus
      // the same four things (the right half folds its spacer and one gap into the
      // single `dayCellSize + headerGridGap` box the widget writes there). Drop the
      // trailing gap and June's title is one gap wider than July's, over grids that
      // are identical.
      const left = panel('header left', 'HORIZONTAL', lk, {});
      left.counterAxisAlignItems = 'CENTER';
      left.appendChild(navButton(page, lk, 'arrow-left', cellSize));
      left.appendChild(headerSpacer(lk, gap, cellSize));
      const juneTitle = headerTitle(page, lk, '2026년 6월', cellSize);
      left.appendChild(juneTitle);
      left.appendChild(headerSpacer(lk, cellSize, cellSize));
      left.appendChild(headerSpacer(lk, gap, cellSize));
      head.appendChild(left);
      lockWidth(left, gridWidth);
      juneTitle.layoutSizingHorizontal = 'FILL';

      const right = panel('header right', 'HORIZONTAL', lk, {});
      right.counterAxisAlignItems = 'CENTER';
      right.appendChild(headerSpacer(lk, cellSize + gap, cellSize));
      const julyTitle = headerTitle(page, lk, '2026년 7월', cellSize);
      right.appendChild(julyTitle);
      right.appendChild(headerSpacer(lk, gap, cellSize));
      right.appendChild(navButton(page, lk, 'arrow-right', cellSize));
      head.appendChild(right);
      lockWidth(right, gridWidth);
      julyTitle.layoutSizingHorizontal = 'FILL';

      comp.appendChild(head);

      // `Row(mainAxisAlignment: .spaceAround, crossAxisAlignment: .start,
      // [gridA, Gap(headerGridGapStyle), gridB])` — two children and one gap, so
      // the row's itemSpacing is exactly that `Gap`.
      const grids = panel('grids', 'HORIZONTAL', lk, { gap });
      grids.appendChild(
        monthGrid(page, lk, { cells: kCalendarCells, selection, inThisMonth: true }),
      );
      grids.appendChild(
        monthGrid(page, lk, { cells: kCalendarNextCells, selection, inThisMonth: false }),
      );
      comp.appendChild(grids);
      continue;
    }

    // header — [nav] gap [title fills] gap [nav]. The two `Gap(gapStyle:
    // headerGridGapStyle)` the widget interleaves are this row's itemSpacing —
    // the same field the column above uses, which is why one local carries both.
    // Without it the arrows sat flush against "2026년 6월" and the header read as
    // one three-part control instead of three.
    const hd = panel('header', 'HORIZONTAL', lk, { gap });
    hd.counterAxisAlignItems = 'CENTER';
    hd.appendChild(navButton(page, lk, 'arrow-left', cellSize));
    const title = headerTitle(page, lk, '2026년 6월', cellSize);
    hd.appendChild(title);
    hd.appendChild(navButton(page, lk, 'arrow-right', cellSize));
    comp.appendChild(hd);
    lockWidth(hd, gridWidth);
    title.layoutSizingHorizontal = 'FILL';

    comp.appendChild(monthGrid(page, lk, { cells: kCalendarCells, selection, inThisMonth: true }));
    // The other two panes. Tapping the header title swaps the day grid for a
    // month grid and again for a year grid (`_MonthGrid` / `_YearGrid`), and only
    // the day grid was ever drawn — so six fields were stated by Core and had no
    // node anywhere.
    //
    // Hidden regions with their own BOOLEANs rather than a `View` variant axis.
    // The axis would be the tidier model and it is not available cheaply: Figma
    // members carry a value for every axis, so `View` × `Selection` asks for a
    // month grid that is also a date range, which the widget cannot be in. The
    // same shape `Window` uses for its snap bar and `PhoneInput` for its country
    // panel — a disjoint region the widget mounts in place of what is showing.
    monthPanes.push(calendarMonthPane(lk, gridWidth));
    yearPanes.push(calendarYearPane(lk, gridWidth));
    comp.appendChild(monthPanes[monthPanes.length - 1]);
    comp.appendChild(yearPanes[yearPanes.length - 1]);
  }
  const set = mount.finish();
  const monthProp = defineProp(set, 'Show month grid', 'BOOLEAN', false);
  for (const pane of monthPanes) bindVisibleProp(pane, monthProp);
  const yearProp = defineProp(set, 'Show year grid', 'BOOLEAN', false);
  for (const pane of yearPanes) bindVisibleProp(pane, yearProp);
  return set;
}

// `_MonthGrid` — twelve abbreviated month names in `monthGridColumns` columns,
// each cell `monthCellWidth` wide, rows spaced by the same `cellSpacing` the day
// grid uses (the widget's `Column(spacing: cellSpacing)`).
function calendarMonthPane(lk: VarLookup, gridWidth: number): FrameNode {
  const f = CALENDAR.fields;
  const columns = dimVal(f.monthGridColumns);
  const pane = panel('month grid', 'VERTICAL', lk, { gap: f.cellSpacing });
  pane.visible = false;
  const labels = kCalendarMonthNames;
  for (let i = 0; i < labels.length; i += columns) {
    const row = panel('row', 'HORIZONTAL', lk, {});
    row.itemSpacing = 0;
    for (const label of labels.slice(i, i + columns)) {
      const cell = panel('month', 'HORIZONTAL', lk, {});
      cell.primaryAxisAlignItems = 'CENTER';
      cell.counterAxisAlignItems = 'CENTER';
      bindSize(cell, lk, f.monthCellWidth, f.dayCellSize);
      cell.primaryAxisSizingMode = 'FIXED';
      cell.counterAxisSizingMode = 'FIXED';
      const monthLabel = makeLabel(label, lk, textLabelOpts(lk, textStyleData(f.cellTextStyle)));
      // Ink of the ghost `Button` cell the widget draws — see the year pane.
      monthLabel.setPluginData(kAmbientInkKey, '1');
      cell.appendChild(monthLabel);
      row.appendChild(cell);
    }
    pane.appendChild(row);
  }
  lockWidth(pane, gridWidth);
  return pane;
}

// `_YearGrid` — `yearGridSize` consecutive years in `yearGridColumns` columns,
// rows spaced by `yearRowSpacing`. The row gap is this pane's own field and not
// `cellSpacing`: the widget writes a different one here, and reading the month
// grid's would have made the two panes agree where the data says they do not.
function calendarYearPane(lk: VarLookup, gridWidth: number): FrameNode {
  const f = CALENDAR.fields;
  const columns = dimVal(f.yearGridColumns);
  const count = dimVal(f.yearGridSize);
  const pane = panel('year grid', 'VERTICAL', lk, { gap: f.yearRowSpacing });
  pane.visible = false;
  for (let i = 0; i < count; i += columns) {
    const row = panel('row', 'HORIZONTAL', lk, {});
    row.itemSpacing = 0;
    for (let j = i; j < Math.min(i + columns, count); j++) {
      const cell = panel('year', 'HORIZONTAL', lk, {});
      cell.primaryAxisAlignItems = 'CENTER';
      cell.counterAxisAlignItems = 'CENTER';
      bindSize(cell, lk, f.monthCellWidth, f.dayCellSize);
      cell.primaryAxisSizingMode = 'FIXED';
      cell.counterAxisSizingMode = 'FIXED';
      const yearLabel = makeLabel(
        `${kCalendarYearStart + j}`,
        lk,
        textLabelOpts(lk, textStyleData(f.cellTextStyle)),
      );
      // The year is a ghost `Button` cell in the widget, so its ink is that
      // Button's foreground, which no calendar field states. Marked so the
      // alpha readback does not compare it with the 30% dashed-border strength
      // another field states on the same token.
      yearLabel.setPluginData(kAmbientInkKey, '1');
      cell.appendChild(yearLabel);
      row.appendChild(cell);
    }
    pane.appendChild(row);
  }
  lockWidth(pane, gridWidth);
  return pane;
}

// ─── Registry ────────────────────────────────────────────────────────────────

// One line per entry, section then name: the registry-parity guard
// (`check_figma_registry_parity.sh`) collects the covered names by matching
// those two keys together on a single line, so an entry wrapped across lines
// reads to it as a coui_core component with no builder at all. (Wrapping three
// of these is exactly how that guard started reporting Calendar / DatePicker /
// TimePicker as uncovered.)
export const FORM_PICKERS: RegistryEntry[] = [
  { section: 'Form', name: 'ColorPicker', build: buildColorPicker, needs: ['Icon', 'Button', 'TextField', 'Popover', 'ToggleGroup'] },
  { section: 'Form', name: 'DatePicker', build: buildDatePicker, needs: ['Icon', 'TextField', 'Calendar', 'Dialog', 'Popover'] },
  { section: 'Form', name: 'TimePicker', build: buildTimePicker, needs: ['Icon', 'Button', 'TextField', 'ToggleGroup', 'Dialog', 'Popover'] },
  { section: 'Form', name: 'Calendar', build: buildCalendar, needs: ['Icon', 'Button'] },
];
