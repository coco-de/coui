/// <reference types="@figma/plugin-typings" />

// Text and content substitution primitives. Keeping the existing Label/Swap
// source identities also preserves the filename-keyed state-axis debt records.
import { kCanvasOnlyApiNotes } from '../canvas-only-notes';
import {
  RegistryEntry,
  VarLookup,
  applyFormRowChrome,
  applyPanelCompChrome,
  autoFrame,
  bindAxisSize,
  bindPad,
  bindSwapProp,
  bindVisibleProp,
  borderData,
  defineProp,
  fillData,
  makeLabel,
  mint,
  mountSet,
  panel,
  propertyOwner,
  textLabelOpts,
  typographyColorOpts,
  bindTextProp,
  instanceOf,
  lockWidth,
  setInstanceBoolNamed,
} from '../helpers';
import { IconSlot, iconSlot, kHalf } from '../chrome-preview';
import { Color, TextLeaf, colorData, dimVal, textStyleData } from '../compat/v1';
import { COMPONENTS } from '../data';

const LABEL = COMPONENTS.label;
const TEXT_BLOCK = COMPONENTS.text_block;
const SELECTABLE_TEXT = COMPONENTS.selectable_text;

// ─── Label ───────────────────────────────────────────────────────────────────

// `[icon] gap [text] gap [*]`, exactly the widget's `Row`. The two gaps are
// different values (`iconLabelGapStyle` 6, `labelRequiredGapStyle` 4) and a
// Figma auto-layout carries one spacing, so the text and its required mark
// nest in their own row — which is what the widget's two interleaved `Gap`s
// amount to.
//
// A `State` axis rather than one component, because the export carries two
// complete text styles (`textStyle` / `disabledTextStyle`) plus
// `disabledOpacity`, and the widget picks between them on a `disabled` flag.
// Same shape as `SwitchField`'s `State=Off/On` (form-controls.ts).
//
// The icon takes the label's own colour — the widget wraps the slot in
// `IconTheme(color: effectiveStyle.color)`, so it darkens with the text when
// disabled. `mail` is the widget's own doc example.
//
// The required mark follows the same rule: `requiredColor` while enabled, the
// colour of the state's own text style while disabled (`resolveLabel`), so a
// disabled label never keeps a live-red `*` beside greyed text.
//
// `icon` is `W?`, so it gets both properties: INSTANCE_SWAP on the glyph (any
// component, which is what the slot takes) and BOOLEAN on the cell around it
// (the widget drops the icon AND the gap after it when the slot is null, and
// an auto-layout frame skips a hidden child's spacing the same way). Both are
// defined on the SET and bound per variant — a property lives on the
// COMPONENT_SET when there is one, and until `finish()` runs a variant's
// parent is still the page, so `propertyOwner` would answer with the variant
// and each one would grow its own copy.
function buildLabel(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = LABEL.fields;
  const states: {
    name: string;
    style: TextLeaf;
    markColor: Color | undefined;
    dimmed: boolean;
  }[] = [
    { name: 'default', style: f.textStyle, markColor: f.requiredColor, dimmed: false },
    {
      name: 'disabled',
      style: f.disabledTextStyle,
      markColor: f.disabledTextStyle.color,
      dimmed: true,
    },
  ];
  const mount = mountSet(page, 'Label', states.map((s) => `State=${s.name}`));
  const iconSlots: IconSlot[] = [];
  for (const s of states) {
    const c = mount.getOrCreate(`State=${s.name}`);
    applyFormRowChrome(c, lk, f.iconLabelGapStyle.size);
    const style = textStyleData(s.style);
    const icon = iconSlot(page, lk, {
      name: 'icon',
      glyph: 'mail',
      size: f.iconStyle.size,
      color: style.color,
      owner: 'Label',
      prop: 'icon',
    });
    iconSlots.push(icon);
    c.appendChild(icon.cell);
    const group = autoFrame('text', 'HORIZONTAL');
    group.counterAxisAlignItems = 'CENTER';
    group.setBoundVariable('itemSpacing', lk.space(dimVal(f.labelRequiredGapStyle.size)));
    group.appendChild(makeLabel('이메일', lk, textLabelOpts(lk, style)));
    // `isRequired` mark: the label's typography, the state's mark colour.
    group.appendChild(
      makeLabel('*', lk, typographyColorOpts(lk, style, colorData(s.markColor))),
    );
    c.appendChild(group);
    // The widget's disabled branch wraps the row in `Opacity(disabledOpacity)`.
    if (s.dimmed) c.opacity = dimVal(f.disabledOpacity);
  }
  const set = mount.finish();
  const swapProp = defineProp(set, 'icon', 'INSTANCE_SWAP', iconSlots[0].mainId);
  const showProp = defineProp(set, 'Show icon', 'BOOLEAN', true);
  for (const icon of iconSlots) {
    bindSwapProp(icon.instance, swapProp);
    bindVisibleProp(icon.cell, showProp);
  }
  return set;
}

// ─── TextBlock ───────────────────────────────────────────────────────────────

// Two chrome boxes, each with the text it draws — which is all
// `CoreTextBlockStyle` exports:
//
//   · blockquote — a start-side rule (`blockQuoteBorderColor` /
//     `blockQuoteBorderWidth`) plus `blockQuotePadding`, and the quote's own
//     text (`blockQuoteTextStyle`). That padding is *logical*
//     (`start`/`end`, reading-direction relative), and `bindPad` is the
//     single place `start`→left resolves, since Figma auto-layout has only
//     physical padding.
//   · pre — the inline-code surface (`inlineCodeBackgroundColor` /
//     `inlineCodeRadius` / `inlineCodePadding`) and its text
//     (`inlineCodeTextStyle`).
//
// Each box's text is the slot's role and colour, drawn through
// `textLabelOpts(lk, textStyleData(slot))` so the label takes the role's text
// style and the colour's variable. The elements that draw no box (`p`, the
// headings, …) take their type from `TextBlockStyle` presets built off the
// ambient theme, which are `TextStyle` composition rather than `CoreXxxStyle`
// fields — there is nothing in `text_block.fields` to bind for them, so they
// are not drawn here.
//
// The root stacks the blocks `kTextBlockPreviewGap` apart, and that gap is
// the canvas's own: one `TextBlock` draws one role, so no `CoreTextBlockStyle`
// field states a space between them — on a page it belongs to whatever lays
// them out. 8 is a rung of the space ladder, so it is bound to `space/8`.
//
// The blocks are the designer's (#6577): a title and a paragraph at rest — the
// body block screens use — with the quote and the code span behind toggles.
// The title and the paragraph draw no box, so their type is the preview's
// choice of role (`TextBlockStyle` presets are theme composition, not
// `CoreTextBlockStyle` fields); the six properties are canvas-only, as the
// component's description says (`generate.ts` `kCanvasOnlyApiNotes`) — the
// code draws the same column as one `TextBlock` per element.
const kTextBlockPreviewGap = 8;
// g7-preview-only: the preview column's width — the paragraph wraps in it. One `TextBlock` states no width; a page column does.
const kTextBlockPreviewWidth = 280;
const kTextBlockTitleCopy = '색은 의미에만';
const kTextBlockParagraphCopy =
  '상태와 분류를 알릴 때만 색을 씁니다. 나머지는 무채색으로 정리해 내용이 먼저 보이게 합니다.';
function buildTextBlock(page: PageNode, lk: VarLookup): ComponentNode {
  const f = TEXT_BLOCK.fields;
  const c = mint(page, 'TextBlock');
  // g7-preview-only: the gap between the stacked blocks. `CoreTextBlockStyle` states no spacing between blocks (a page's layout owns it), so this is the preview's own — the designer's copy spaces them 8 apart.
  applyPanelCompChrome(c, 'VERTICAL', lk, { gap: kTextBlockPreviewGap });
  lockWidth(c, kTextBlockPreviewWidth);
  const owner = propertyOwner(c);

  // A block that fills the column and wraps in it, as `Text` does there.
  const line = (copy: string, style: Parameters<typeof textStyleData>[0], name: string): TextNode => {
    const t = makeLabel(copy, lk, textLabelOpts(lk, textStyleData(style)));
    t.name = name;
    t.textAutoResize = 'HEIGHT';
    c.appendChild(t);
    t.layoutSizingHorizontal = 'FILL';
    return t;
  };
  // The inks are the two the exported blocks already wear: the title the code
  // span's `onSurface`, the paragraph the quote's `onSurfaceVariant`.
  // g7-preview-only: the title and paragraph roles — the `h`/`p` presets come from the ambient theme, not a `CoreTextBlockStyle` field.
  const title = line(
    kTextBlockTitleCopy,
    { role: 'titleSmall', color: f.inlineCodeTextStyle.color },
    'title',
  );
  const paragraph = line(
    kTextBlockParagraphCopy,
    { role: 'bodySmall', color: f.blockQuoteTextStyle.color },
    'paragraph',
  );

  const quote = panel('blockquote', 'VERTICAL', lk, {});
  bindPad(quote, lk, f.blockQuotePadding);
  borderData(quote, lk, colorData(f.blockQuoteBorderColor), f.blockQuoteBorderWidth);
  quote.strokeTopWeight = 0;
  quote.strokeRightWeight = 0;
  quote.strokeBottomWeight = 0;
  quote.setBoundVariable('strokeLeftWeight', lk.stroke(dimVal(f.blockQuoteBorderWidth)));
  quote.appendChild(
    makeLabel('인용한 문단이에요.', lk, textLabelOpts(lk, textStyleData(f.blockQuoteTextStyle))),
  );
  c.appendChild(quote);

  const pre = panel('pre', 'HORIZONTAL', lk, { radius: f.inlineCodeRadius });
  bindPad(pre, lk, f.inlineCodePadding);
  fillData(pre, lk, colorData(f.inlineCodeBackgroundColor));
  pre.appendChild(
    makeLabel('인라인 코드', lk, textLabelOpts(lk, textStyleData(f.inlineCodeTextStyle))),
  );
  c.appendChild(pre);

  // Each line carries its words and its toggle; the two references merge on
  // the one node (`addPropRef`).
  bindVisibleProp(title, defineProp(owner, 'Show title', 'BOOLEAN', true));
  bindTextProp(title, defineProp(owner, 'Title', 'TEXT', kTextBlockTitleCopy));
  bindVisibleProp(paragraph, defineProp(owner, 'Show paragraph', 'BOOLEAN', true));
  bindTextProp(paragraph, defineProp(owner, 'Paragraph', 'TEXT', kTextBlockParagraphCopy));
  // Off at rest: the quote and the code span were the old preview's only
  // content; the body block a screen uses is a title and a paragraph.
  bindVisibleProp(quote, defineProp(owner, 'Show quote', 'BOOLEAN', false));
  bindVisibleProp(pre, defineProp(owner, 'Show code', 'BOOLEAN', false));
  quote.visible = false;
  pre.visible = false;
  c.description = kCanvasOnlyApiNotes.TextBlock;
  return c;
}

// ─── SelectableText ──────────────────────────────────────────────────────────

// Text plus the two things selecting it adds: the selection band and the
// caret. The exported fields are bound — `textStyle` on both runs,
// `selectionColor` as
// the fill of the frame wrapping the selected run (so it paints behind that
// text, as the real highlight does). The text colour does not change under
// selection in the widget either, so it stays `textStyle`'s own colour.
//
// The band is the colour exactly as stated: neither resolver multiplies an
// alpha onto it, and `selectable_text.fields.selectionColor` carries
// `opacity: 1`, so the canvas and the app paint the same fill.
//
// ─── The caret ──────────────────────────────────────────────────────────────
//
// `cursorColor` and `cursorWidth` come from the exported Core defaults. The
// colour is independent of the text's colour, as it is for an input cursor.
// `selectable_text.absent` keeps two deferrals with drawable meanings:
//   · `cursorHeight` — "'Auto' is not a number: the framework sizes the caret
//     to the line height". FILL on the counter axis is that, and it is also
//     what the absence walk asserts for the field (`not-fixed-size`) — a fixed
//     extent here would be the lie the absence exists to prevent.
//   · `cursorRadius` — "A square caret is the design", so the corners stay 0.
//
// Hidden by default, behind a BOOLEAN, because `showCursor` defaults to
// `false` on both constructors (`selectable_text.dart`) — a caret painted
// unconditionally would show a state the widget is not in, which is the same
// mistake `FocusOutline`'s `circleBorderRadius` note refuses below. `showCursor`
// is a widget flag rather than exported chrome, and a BOOLEAN property is how
// every other optional element in this file says "the caller turns this on".
function buildSelectableText(page: PageNode, lk: VarLookup): ComponentNode {
  const f = SELECTABLE_TEXT.fields;
  const c = mint(page, 'SelectableText');
  applyPanelCompChrome(c, 'HORIZONTAL', lk, {});
  c.counterAxisAlignItems = 'CENTER';
  const style = textStyleData(f.textStyle);
  c.appendChild(makeLabel('선택할 수 있는 ', lk, textLabelOpts(lk, style)));
  const band = panel('selection', 'HORIZONTAL', lk, {});
  fillData(band, lk, colorData(f.selectionColor));
  band.appendChild(makeLabel('텍스트', lk, textLabelOpts(lk, style)));
  c.appendChild(band);

  const caret = figma.createRectangle();
  caret.name = 'caret';
  // `bindAxisSize` binds ONE axis on purpose (see its note): the width is the
  // stated design value, and the height it is resized to is a placeholder the
  // FILL below replaces — binding it would assert a length Core never stated.
  bindAxisSize(caret, lk, { width: f.cursorWidth, height: f.cursorWidth, bind: 'width' });
  fillData(caret, lk, colorData(f.cursorColor));
  c.appendChild(caret);
  // After `appendChild`: FILL is only valid on an auto-layout child, and
  // setting it on a detached node throws.
  caret.layoutSizingVertical = 'FILL';
  // The node itself starts hidden, not just the property's default — a BOOLEAN
  // default governs instances while the main component keeps whatever the
  // builder left visible, so without this the component's own picture would
  // carry a caret the widget only draws under `showCursor: true`. Same pairing
  // `bindOptionalSlot` (overlay.ts) makes for a slot that is null by default.
  caret.visible = false;
  bindVisibleProp(
    caret,
    defineProp(propertyOwner(c), 'Show cursor', 'BOOLEAN', false),
  );
  return c;
}


const SWAP = COMPONENTS.swap;

// ─── Swap ────────────────────────────────────────────────────────────────────

// Two contents on one clickable surface, cross-faded:
//
// ```text
// root                       // the Clickable surface — clickableStyle.borderRadius
//   └─ stack                 // Stacks(alignment: .center) — both slots, one position
//        ├─ offContent       // Opacity(1 − v)
//        └─ onContent        // Opacity(v)
// ```
//
// BOTH slots are on the canvas in BOTH states, because both are in the widget
// in both states — `_buildContent` always builds the pair and lets opacity
// decide which one reads. The `State` axis moves the opacity between them
// (off: 1/0, on: 0/1) rather than swapping which node exists. Drawing one
// label per state would have said the other slot is absent when checked,
// which is the opposite of what `Stacks` is for: the off content keeps
// occupying its space, so the surface never resizes as it toggles.
//
// The stack is manual placement (`layoutMode = 'NONE'`, both children at the
// same centred position) rather than an instance of the `Stacks` component:
// `Stacks` is a wrapper whose whole job is to hold the caller's children, and
// a Figma instance cannot be given any — an instantiated `Stacks` would sit
// BESIDE this content instead of around it. Same reason the root is not an
// instance of `Clickable`, which the widget wraps this in when `onToggle` is
// non-null: it is a wrapper too, so what is representable is its resting
// chrome, and `clickableStyle` has no background or padding field — an
// unfilled box on `clickableStyle.borderRadius`, hugging its content, is the
// whole of a resting `Clickable`.
//
// `textStyle` is the ambient `DefaultTextStyle` the widget installs over both
// slots, so both labels read it — which is also why each slot gets a TEXT
// property and not an INSTANCE_SWAP. The slots are `W` (required, never null,
// so no BOOLEAN either), and a swap would need a `Text` component in the
// REGISTRY that the owner decided against adding; going that way would also
// orphan `textStyle`, the one field this component has that says anything
// about its contents. Editable copy is the ceiling here, and it is a real one.
//
// Not drawn: `pressedScale` / `focusOutlineStyle` (press and focus states),
// `duration` / `pressDuration` (timings), and `clickableStyle.disabledOpacity`
// — which is not an omission but an unreachable value: `Swap` has no `enabled`
// field and `swap.dart` never hands `Clickable` one, so the widget has no
// disabled state either (its own comment there: a swap with no `onToggle`
// returns bare content because "Clickable's `enabled: false` would paint the
// disabled affordance"). A `Disabled` axis here would show a state the widget
// cannot enter.
function buildSwap(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = SWAP.fields;
  const states = ['off', 'on'];
  const mount = mountSet(page, 'Swap', states.map((s) => `State=${s}`));
  const offNodes: TextNode[] = [];
  const onNodes: TextNode[] = [];
  for (const state of states) {
    const c = mount.getOrCreate(`State=${state}`);
    // The root IS the `Clickable` the widget wraps this in, drawn rather than
    // instantiated: `Clickable` is a wrapper, and a Figma instance cannot be
    // given children, so an instance of it would sit beside this content
    // instead of around it. What is representable is its resting appearance,
    // and that is one value — `clickableStyle.borderRadius` — because the
    // style carries no background and no padding.
    applyPanelCompChrome(c, 'HORIZONTAL', lk, {
      radius: f.clickableStyle.borderRadius.topLeft,
    });
    c.primaryAxisAlignItems = 'CENTER';
    c.counterAxisAlignItems = 'CENTER';

    // `Stacks(alignment: .center)` — manual placement for the same reason.
    const stack = figma.createFrame();
    stack.name = 'stack';
    stack.layoutMode = 'NONE';
    stack.fills = [];
    stack.clipsContent = false;
    const style = textStyleData(f.textStyle);
    const off = makeLabel('꺼짐', lk, textLabelOpts(lk, style));
    off.name = 'offContent';
    const on = makeLabel('켜짐', lk, textLabelOpts(lk, style));
    on.name = 'onContent';
    stack.appendChild(off);
    stack.appendChild(on);
    offNodes.push(off);
    onNodes.push(on);
    off.opacity = state === 'off' ? 1 : 0;
    on.opacity = state === 'off' ? 0 : 1;
    // `alignment: .center` — the stack is the union of both slots and each
    // one is centred in it, so neither position depends on which is opaque.
    const width = Math.max(off.width, on.width);
    const height = Math.max(off.height, on.height);
    stack.resize(width, height);
    for (const slot of [off, on]) {
      slot.x = (width - slot.width) / kHalf;
      slot.y = (height - slot.height) / kHalf;
    }
    c.appendChild(stack);
  }
  const set = mount.finish();
  // Both slots exist in both variants, so one property per slot drives the two
  // nodes that stand for it — the `State` axis moves opacity, not copy.
  const offProp = defineProp(set, 'offContent', 'TEXT', '꺼짐');
  for (const n of offNodes) bindTextProp(n, offProp);
  const onProp = defineProp(set, 'onContent', 'TEXT', '켜짐');
  for (const n of onNodes) bindTextProp(n, onProp);
  return set;
}
export const PRIMITIVES_CHROME: RegistryEntry[] = [
  { section: 'Display', name: 'Label', build: buildLabel, needs: ['Icon'] },
  { section: 'Display', name: 'TextBlock', build: buildTextBlock },
  { section: 'Display', name: 'SelectableText', build: buildSelectableText },
  { section: 'Display', name: 'Swap', build: buildSwap },
];
