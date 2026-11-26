/// <reference types="@figma/plugin-typings" />

import { formLabelSizeCells, FORM_LABEL } from '../form-label-sizes';

import {
  mainComponentIdOf as mainIdOf,
  iconMainIdAt,
  kPreserveGlyphPaint,
  setSlotIcon,
  pinAbsolute,
  sizePin,
  RegistryEntry,
  VarLookup,
  addControlShadow,
  applyPanelCompChrome,
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
  corners,
  defineProp,
  exposeAll,
  fillData,
  focusOutlineRing,
  forwardFocusOutlineHostRadius,
  glyphOpts,
  iconMainId,
  iconSwapDefault,
  instanceOf,
  layoutSet,
  lockWidth,
  makeIcon,
  makeLabel,
  mountSet,
  panel,
  rowSet,
  setShadow,
  solid,
  textLabelOpts,
  typographyColorOpts,
  vStackSet,
  hostedDivider,
  suppressFieldChrome,
  paintPlaceholder,
  applyForwardedFieldText,
  kFieldValueName,
  namedDescendant,
  revealFieldCaret,
  applyInstanceTextStyle,
  setInstanceBoolNamed,
  setInstanceTextNamed,
  defaultSetLayout,
  focusOutlineBand,
} from '../helpers';
import { stateAxis } from '../state-axis';
import {
  Color,
  Dim,
  argbAlpha,
  colorData,
  dimVal,
  mergeTextStyleData,
  optField,
  textStyleData,
  type TextLeaf,
} from '../compat/v1';
import { parseVariantKey } from '../variant-safety';
import { COMPONENTS } from '../data';
import { forwardChipCloseBox } from '../chip-composition';
import {
  axisSpecsOf,
  composeVariantName,
  distinctSizeCells,
  enumerateAxisAssignments,
  enumerateAxisCombos,
  restingValueOf,
  sizeRowFor,
} from '../axis-combos';
import { derivedCorner } from '../instance-reach';
import { applyValidatorHintStyle } from '../validator-hint-composition';

const TEXT_FIELD = COMPONENTS.text_field;
const FORM_FIELD = COMPONENTS.form_field;
const FIELDSET = COMPONENTS.fieldset;
const FILE_INPUT = COMPONENTS.file_input;
const INPUT_OTP = COMPONENTS.input_otp;
const FOCUS_OUTLINE = COMPONENTS.focus_outline;
const PHONE_INPUT = COMPONENTS.phone_input;
const FORMATTED_INPUT = COMPONENTS.formatted_input;
const VALIDATOR_HINT = COMPONENTS.validator_hint;
const VALIDATION_BADGE = COMPONENTS.validation_badge;
const CHIP_INPUT = COMPONENTS.chip_input;
// `icon.constants.ambientSize` — the app root's ambient icon size, which an
// `Icon` handed to a caller slot draws at when the widget renders it as handed.
// FormattedInput's `leading` / `trailing` say why they qualify.
const ICON = COMPONENTS.icon;

// ─── Conventions applied across this file ────────────────────────────────────
//
// **Composed children are instances, never redrawn.** Where a component's
// `CoreXxxStyle` forwards a nested child Style (`CoreChipInputStyle.chipStyle`
// → `Chip`, `CoreFormFieldStyle.errorValidatorHintStyle` → `ValidatorHint`),
// the builder instantiates that child (`instanceOf`) instead of painting a
// look-alike box. A redrawn copy does not follow the main component when it
// changes, and the content-hash skip in `generate.ts` means a parent whose own
// recipe is unchanged is never rebuilt — so it would keep painting the old
// child indefinitely. Declaring `needs: ['<Child>']` is what orders the build.
//
// **Slot → property mapping.** A `W`/`W?` contract slot accepts any widget, so
// the Figma answer is an INSTANCE_SWAP: the designer points the slot at any
// component. A slot the builder renders as a *text node* gets a TEXT property
// instead — swapping it would need a `Text` component in the REGISTRY, which
// this design system deliberately does not have (Figma's own mechanism for that
// is the shared Text Style). `List<W>` slots are skipped — Figma has no
// repeated-slot property, a designer adds children directly.
//
// **The property is named after the contract slot, exactly.** `labelWidget` →
// `LabelWidget`, not `Label`; `requiredIndicator` → `RequiredIndicator`. A
// property whose name reads better in the panel but names nothing in the
// contract leaves the slot unreachable *and* unaudited — nothing can tell that
// `Label` was meant to be `labelWidget`, so the slot scores as having no
// property at all. Where a contract also exposes the same content as a plain
// `String` (`FormField.label` beside `labelWidget`), the slot name wins: the
// String and the slot render the same node, and only one of them is the thing
// a designer can put a widget into.
//
// **A slot needs two properties, on two nodes.** `componentPropertyReferences`
// is assigned wholesale by each bind helper, so one node carries exactly one
// reference. An optional slot therefore becomes a hug frame holding the content:
// the frame takes the BOOLEAN ("did a caller pass one"), its single child takes
// the TEXT / INSTANCE_SWAP ("what fills it"). The frame paints nothing and hugs,
// so it costs no pixels. The BOOLEAN is named `<Slot> shown` rather than
// `<Slot>` so the swap keeps the contract's own name.
//
// Properties are defined *after* `mountSet().finish()` so the owner is the
// COMPONENT_SET itself: before the combine, each variant is still a parentless
// COMPONENT and the definitions would land on the members instead. And every
// bind happens after the node is inside the component — Figma rejects a
// reference on a detached node ("Can only set component property references on
// symbol sublayer"), the throw is not rolled back — the entry is reported as
// failed and a half-drawn component is left on the page.
//
// **A set's non-variant property has ONE default.** `componentPropertyDefinitions`
// live on the set, so a TEXT/INSTANCE_SWAP default is shared by every variant —
// an instance of any variant starts out showing that one value. That is a real
// cost where the variants differ (ValidatorHint's four per-type glyphs collapse
// onto the `error` one until a designer swaps them), and it is still the right
// trade: without the property the glyph the builder happened to draw is the only
// thing that slot can ever hold, which is a stronger claim than the contract
// makes. The per-type glyphs remain visible on the variants themselves.
//
// **State axes are independent booleans** (`Disabled=true, Focus=false, …`),
// each value read from that state's own Core field — the widgets combine states
// (hovered AND focused), which one `State=` enum cannot express. Disabled takes
// precedence over hover/focus in the rendering, mirroring the widgets, so some
// disabled corners of the matrix render alike; that is the code's behaviour, not
// a missing axis. A state whose Core value is a visual no-op (`disabledOpacity`
// = 1, `pressedScale` = 1) gets no axis, and neither does one whose chrome lives
// in a composed child (restyling an instance's interior from the parent is the
// fork `instanceOf` exists to remove).
//
// **A wrapper child is composed hidden, not skipped.** Two widgets here wrap the
// whole component in a child that paints nothing in the resting state —
// `FocusOutline(focused: false, …)` (ChipInput, each InputOtp cell) and
// `Popover(trigger: …, content: …)` with the panel closed (PhoneInput). Figma
// has no way to make an instance the *parent* of a component's own content, so
// the instance rides alongside as an absolutely-positioned layer that is hidden
// exactly when the widget paints nothing. It is in the layer tree — a designer
// reads which child put the ring/panel there, and the Figma→code direction can
// see it — and it draws nothing, which is what the code does. Same arrangement
// InputOtp's hidden `TextField` buffer already uses below.
//
// **A chromeless composed `TextField` is NOT expressed here — knowingly.** Four
// composed fields forward a chromeless nested `CoreTextFieldStyle`
// (`CorePhoneInputStyle.chromelessFieldStyle` for both the number field and the
// dropdown search field, `CoreChipInputStyle.chromelessFieldStyle`,
// `CoreFormattedInputStyle.segmentInputStyle` — the last one exported, carrying
// `borderWidth: 0` and a transparent background/border) because the surrounding
// container owns the single visible boundary. None of that reaches the canvas,
// because `TextField` does not paint on its root: `form.ts` leaves that root
// `fills = []` and never gives it strokes, putting the surface fill + the
// variant row's `outline` border + radius on a nested `field` frame instead. Each of
// these three builders used to write `inst.fills = []; inst.strokes = []` on the
// instance root, which read as the forward being honoured and was in fact `[]`
// over `[]` — the instance root arrives already empty, cloned from a main
// component that paints nothing. Removed rather than kept, because dead code
// that looks load-bearing tells the next reader the boundary is handled.
//
// What it is NOT replaced with: reaching through the instance to repaint that
// nested `field` frame. That is the fork `instanceOf` exists to remove (see the
// composition note at the top) — a second copy of `TextField`'s chrome recipe in
// three places, which the content-hash skip in `generate.ts` would then keep
// stale. The forward belongs to `TextField` itself, as a chromeless axis it does
// not have yet; until it does, each composed field shows its own box inside its
// container's boundary. That divergence is this file's honest state, and it is
// not something a clear on a node that never painted was ever closing.

// ─── Local helpers ───────────────────────────────────────────────────────────


// A named layer inside a composed instance — the slot the CHILD builder drew for
// its own `child`. Matched by name rather than by position so a structure change
// upstream leaves the slot alone instead of throwing. (Local by the same
// convention the other builder files follow, not promoted to helpers.ts.)
function instanceFrameSlot(inst: InstanceNode, name: string): FrameNode | null {
  for (const node of inst.findAll((n) => n.name === name)) {
    if (node.type === 'FRAME') return node;
  }
  return null;
}

// A forwarded corner radius on a composed instance. `bindRadiusN` is typed for
// `FrameNode | ComponentNode | RectangleNode`, and an `InstanceNode` is none of
// the three even though it accepts the same four corner fields.
function bindInstanceRadius(inst: InstanceNode, lk: VarLookup, n: number | Dim): void {
  const radius = dimVal(n);
  for (const corner of corners) inst.setBoundVariable(corner, lk.radius(radius));
}

// Forwarded insets and inner gap on a composed instance — the auto-layout half
// of what `bindInstanceRadius` does for corners, and typed here for the same
// reason (`bindPad` takes `FrameNode | ComponentNode`).
//
// These are legal to write on an instance root: Figma permits property overrides
// there and only forbids adding or removing children. So a parent that hands a
// child a whole nested Style can express the parts of it that address the
// child's own box, which is what the forward means — and what the alternative
// (leaving the child on its own size step's values) silently drops.
function bindInstanceBox(
  inst: InstanceNode,
  lk: VarLookup,
  o: {
    pad?: { l: number | Dim; t: number | Dim; r: number | Dim; b: number | Dim };
    gap?: number | Dim;
  },
): void {
  if (o.pad) {
    inst.setBoundVariable('paddingLeft', lk.space(dimVal(o.pad.l)));
    inst.setBoundVariable('paddingRight', lk.space(dimVal(o.pad.r)));
    inst.setBoundVariable('paddingTop', lk.space(dimVal(o.pad.t)));
    inst.setBoundVariable('paddingBottom', lk.space(dimVal(o.pad.b)));
  }
  if (o.gap != null) inst.setBoundVariable('itemSpacing', lk.space(dimVal(o.gap)));
}



// ─── FormField (label + input + helper) ──────────────────────────────────────
// Renamed from Figma's "TextField" (#3742) — that name collided with the
// real `TextField` class once form.ts's data-driven "Input" builder was
// renamed to it. This compound label+child+helper/error shape is exactly
// `FormField` (CoreFormFieldContract): label row + child + description/error.

// Data-driven from coui_core: FORM_FIELD.fields.labelInputGapStyle (the row
// gap) + FORM_FIELD.fields.descriptionTextStyle (helper typography, whose own
// colour is `on-surface-variant`). The error line is not a differently-coloured
// description — `CoreFormFieldStyle.errorValidatorHintStyle` is a nested
// `CoreValidatorHintStyle`, i.e. FormField composes `ValidatorHint` for it — so
// the `Error=true` arm instantiates that component instead of restating its
// accent/icon/gap here (see the composition note at the top of this file).
//
// The label row is likewise a composed `FormLabel` in code
// (`CoreFormFieldStyle.disabledFormLabelStyle` is a nested
// `CoreFormLabelStyle`), but `FormLabel` is a single COMPONENT rather than a
// set: `figma.createComponent()` appends to the current page in Figma, while
// the registry-runtime harness's `figma` double does not, so `instanceOf` there
// cannot see any mint()-built child. Instancing it would make `npm run
// selftest` fail on a page state that only the double has, so the label stays a
// text node here (and carries the `Label` TEXT property below).
//
// `child: W?` is caller-supplied — FormField's own recipe draws nothing there.
// A hand-painted box stood in for it, which made the slot unreachable twice
// over: a frame cannot carry an INSTANCE_SWAP, and a designer reading the canvas
// saw a fixed input rather than a slot. It is a `TextField` instance now — the
// component a caller reaches for first, and the only shape that lets the `Child`
// INSTANCE_SWAP re-point the slot at any other component.
//
// ─── `Disabled` and `Error` are two axes, not one enum ───────────────────────
//
// Two independent booleans, because the widget can be both at once and says so
// outright: the Web twin writes `aria-disabled="true"` and `aria-invalid="true"`
// as two separate `if`s on the same `role="group"`. Nothing gates one on the
// other — `resolveFormField(context, enabled:, formFieldStyle:)` takes `enabled`
// as its ONLY state input, while the error is a render-time branch in the widget
// body (`if (hasError) ValidatorHint.error(…) else Text(description)`). So
// unlike FileInput below — where `handleDragEnter` returns early on `!enabled`
// and the two `Disabled=true` corners collapse onto each other — all four
// corners here are distinct poses, and one three-valued `State=` enum could not
// hold the disabled-and-invalid one at all.
//
// `Disabled=true` repaints exactly one node: `disabledFormLabelStyle.labelStyle`
// states only the `on-surface-subtle` colour, laid over FormLabel's own
// `labelMedium` (13px) in `on-surface-variant`, so the label steps one tier
// quieter and its metrics do not move. The same tint a disabled `TextField`
// and `TextArea` paint on their own labels. The slot's
// other two facets (`requiredColor` = `error`, `requiredIndicatorGapStyle` = 4)
// are the values FormLabel already carries, and this preview draws no required
// `*` to put them on either way. The rest of what disabling does is not pixels:
// `IgnorePointer` (Flutter) / `pointer-events: none` (Web).
//
// What `Disabled=true` deliberately does NOT do is disable the composed
// `TextField`, and `Error=true` does not error-tint it. FormField pushes no
// state into its child: it installs a `FormFieldHandle` /
// `FormFieldHandleScope`, which carries value reporting and validation RESULTS
// up to the field, and the ambient state a `TextField` reads for its own
// error/disabled chrome is `CoreValidationState` — provided by `Validated`,
// which FormField is not. A disabled FormField holding an enabled TextField
// renders a normal-looking input that ignores pointers, and that is the picture
// both platforms draw. (Contrast FileInput, whose composed Button DOES follow
// its own Disabled axis — there the widget writes `onPressed: enabled ?
// handleBrowse : null`.) The error arm used to instance `TextField`'s own
// `Variant=Error`, which read as a forward this component makes and does not:
// it put the error signal on a border FormField never touches, rather than on
// the `ValidatorHint` row that is the whole of what FormField draws for it.
//
// `Error=true` swaps the description row for a `ValidatorHint` instance and
// forwards `errorValidatorHintStyle` onto it. That forward is not cosmetic:
// `messageTextStyle` is `bodySmall` (13) where ValidatorHint's own is
// `bodyXs` (12), so a hint under a FormField renders a step larger than a
// standalone one — and without this forward it would render a pixel small
// here. It states no colour, so `applyInstanceTextStyle` leaves the type's
// `accentColor` alone; `iconLabelGapStyle` (4) rides on the instance root.
//
// `errorValidatorHintStyle.iconStyle.size` is the one facet with no write, and
// nothing is dropped by that: it is 16, which is also ValidatorHint's own
// `iconStyle.size`, so the glyph on the canvas already renders at the forwarded
// size. The reason not to write it anyway is that a rescale is a RELATIVE op:
// `ValidatorHint` has already fitted its glyph to its size, so re-applying a
// rescale by `side / step` to that instance would scale it a second time rather
// than pin it at 16. Should the two values ever diverge, the write is
// `rescale(target / inst.width)` on the icon inside the instance.
function buildFormField(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = FORM_FIELD.fields;
  const gap = dimVal(f.labelInputGapStyle.size);
  const description = textStyleData(f.descriptionTextStyle);
  // The enabled label's metrics live on `FormLabel`, not here: FormField
  // forwards a null-valued `formLabelStyle` on that arm, so the composed
  // child's own `defaultLabelStyle` is what the widget paints. The disabled arm
  // is the one FormField owns outright.
  const labelStyle = textStyleData(FORM_LABEL.fields.labelStyle);
  // The disabled overlay states a colour and no role: the role is the
  // composed `FormLabel`'s to pick from its own size ladder, and a role
  // stated here would pin every size to one rung. So the disabled arm is
  // the enabled label's metrics with the overlay's colour laid on top —
  // the same merge the widget performs.
  const disabledLabelStyle = {
    ...labelStyle,
    color: textStyleData(f.disabledFormLabelStyle.labelStyle).color,
  };
  // The two facets of `errorValidatorHintStyle` that get written onto the
  // composed hint — see the note above for the third.
  const hintMessageStyle = textStyleData(f.errorValidatorHintStyle.messageTextStyle);
  const counterStyle = textStyleData(f.counterTextStyle);
  const hintIconLabelGap = f.errorValidatorHintStyle.iconLabelGapStyle.size;
  const states: { disabled: boolean; error: boolean }[] = [];
  for (const disabled of [false, true]) {
    for (const error of [false, true]) states.push({ disabled, error });
  }
  const nameOf = (s: { disabled: boolean; error: boolean }): string =>
    `Disabled=${s.disabled}, Error=${s.error}`;
  const mount = mountSet(page, 'FormField', states.map(nameOf));
  // The child input's variant is the same on every corner — FormField forwards
  // no state into it (see above), so `Disabled` is pinned to the enabled one
  // rather than tracking this component's own axis.
  const childVariant = bestVariantName(page, 'TextField', {
    Variant: 'Default',
    Size: 'md',
    Disabled: 'false',
  });
  // Collected for the property pass below — the owner only becomes the set
  // once `finish()` has combined the variants.
  const labels: TextNode[] = [];
  const holders: FrameNode[] = [];
  const fields: InstanceNode[] = [];
  // The two wrappers `Show label` / `Show footer` turn off, and the hint
  // instances those properties reveal.
  const headers: FrameNode[] = [];
  const footers: FrameNode[] = [];
  const descriptions: TextNode[] = [];
  const hints: InstanceNode[] = [];
  const labelActions: { holder: FrameNode; instance: InstanceNode }[] = [];
  const counters: TextNode[] = [];
  for (const state of states) {
    const c = mount.getOrCreate(nameOf(state));
    applyPanelCompChrome(c, 'VERTICAL', lk, { gap });
    // The widget states no width — it hugs its parent, and FormField's four Core
    // fields are two gaps and two nested child styles. A Figma COMPONENT still has
    // to be some width to be placed, so the number is the preview's, not the code's.
    // g7-preview-only: FormField demo width, no width field in the code
    lockWidth(c, 260);
    // WHY THE LABEL SITS IN A WRAPPER RATHER THAN DIRECTLY ON THE ROOT.
    //
    // `Show label` has to turn off the label's SPACE, not just its ink. Bound
    // to the text node, hiding it leaves the row it sat in still occupying
    // its height, and the root's `itemSpacing` still puts a gap either side —
    // measured at 22 + 8 = 30px of dead space, which is a form field whose
    // top edge no longer lines up with anything beside it.
    //
    // Figma auto-layout removes a hidden CHILD from the flow, gap included.
    // So the node the property turns off has to be the child of the frame
    // whose spacing is in question — this wrapper — not something one level
    // further in. `Child shown` below already binds to the `child` FRAME for
    // exactly this reason; the label was the one that did not.
    //
    // This also matches what the widget does: `if (hasLabel) [label, Gap]`
    // puts the gap INSIDE the conditional, so no label means no gap there
    // either (`form_field.dart`).
    const header = autoFrame('header', 'HORIZONTAL');
    c.appendChild(header);
    header.layoutSizingHorizontal = 'FILL';
    // `[label] … [action]` pushed apart — the widget's own
    // `mainAxisAlignment: .spaceBetween` (`form_field.dart`), and the
    // gap below is the FLOOR on their separation, not their usual
    // distance.
    header.primaryAxisAlignItems = 'SPACE_BETWEEN';
    header.counterAxisAlignItems = 'CENTER';
    header.itemSpacing = dimVal(f.labelActionGapStyle.size);
    headers.push(header);
    const label = makeLabel(
      '이메일',
      lk,
      textLabelOpts(lk, state.disabled ? disabledLabelStyle : labelStyle),
    );
    header.appendChild(label);
    labels.push(label);
    // `labelAction` — a `W?` slot on the contract, so an INSTANCE_SWAP
    // here, and the default it points at is a component the doc names:
    // `Button(variant: .plain)`, the quiet opener. (A destination is a
    // `Link`, which a designer swaps in.) Holder → BOOLEAN, instance →
    // INSTANCE_SWAP, the same two-node split `child` uses two blocks down
    // (one reference each).
    const actionVariant = bestVariantName(page, 'Button', {
      Variant: 'plain',
      Size: 'sm',
    });
    const actionHolder = autoFrame('labelAction', 'HORIZONTAL');
    actionHolder.counterAxisAlignItems = 'CENTER';
    const actionInstance = instanceOf(page, 'Button', actionVariant);
    actionHolder.appendChild(actionInstance);
    actionHolder.visible = false;
    header.appendChild(actionHolder);
    labelActions.push({ holder: actionHolder, instance: actionInstance });
    // Holder → BOOLEAN, instance → INSTANCE_SWAP: two references need two nodes.
    const holder = autoFrame('child', 'HORIZONTAL');
    c.appendChild(holder);
    holder.layoutSizingHorizontal = 'FILL';
    const field = instanceOf(page, 'TextField', childVariant);
    field.name = 'input';
    holder.appendChild(field);
    field.layoutSizingHorizontal = 'FILL';
    holders.push(holder);
    fields.push(field);
    // The footer — the widget's third block, and a wrapper for the same
    // reason `header` is one: `Show footer` has to remove the row's height
    // and its gap, not just what is drawn in it.
    //
    // The widget builds this as its own `Column([Gap, hint | description])`
    // returning `SizedBox.shrink()` when it has neither an error nor a
    // description (`form_field.dart`) — i.e. the row is already collapsible
    // there, and this is the canvas saying the same thing.
    const footer = autoFrame('footer', 'HORIZONTAL');
    c.appendChild(footer);
    footer.layoutSizingHorizontal = 'FILL';
    // Same shape as `header` above: `[message] … [counter]`.
    footer.primaryAxisAlignItems = 'SPACE_BETWEEN';
    footer.counterAxisAlignItems = 'MIN';
    footer.itemSpacing = dimVal(f.footerGapStyle.size);
    footers.push(footer);
    if (state.error) {
      const hint = instanceOf(page, 'ValidatorHint', 'Variant=error');
      // The nested-slot forward, on the instance the slot names — not a second
      // copy of ValidatorHint's recipe. Written before the append for the same
      // reason the ChipInput chips are: both address the instance's own root /
      // own text, neither is a property reference.
      applyInstanceTextStyle(hint, lk, hintMessageStyle);
      bindInstanceBox(hint, lk, { gap: hintIconLabelGap });
      footer.appendChild(hint);
      hints.push(hint);
    } else {
      const desc = makeLabel(
        '이메일은 외부에 공개되지 않아요.',
        lk,
        textLabelOpts(lk, description),
      );
      footer.appendChild(desc);
      descriptions.push(desc);
    }
    // `counterText` — a `String?`, so a TEXT node, and it carries BOTH
    // references: `Show count` on its visibility and `Count` on its
    // characters. One node can hold two, and splitting them would put the
    // tally in a wrapper that exists for nothing.
    const counter = makeLabel(
      '0 / 20',
      lk,
      textLabelOpts(lk, counterStyle),
    );
    counter.visible = false;
    footer.appendChild(counter);
    counter.layoutSizingHorizontal = 'HUG';
    counter.layoutSizingVertical = 'HUG';
    counters.push(counter);
  }
  const set = mount.finish();
  // `LabelWidget`, not `Label`: the contract's `label` (String) and `labelWidget`
  // (`W?`) render the same node, and the slot is the member a designer can put a
  // widget into — so the slot's name is the one the property carries. It stays a
  // TEXT property rather than a swap because the node is text (see the top of
  // this file), which is also why the label row is not a composed `FormLabel`
  // here: inside an instance the text node is out of reach, and the slot would
  // go back to having no property at all.
  const labelProp = defineProp(set, 'LabelWidget', 'TEXT', '이메일');
  const childProp = defineProp(
    set,
    'Child',
    'INSTANCE_SWAP',
    mainIdOf(page, 'TextField', childVariant),
  );
  // Shown by default — a FormField with no input is not a state the preview
  // should open on, and the widget's `child: null` is reachable by turning it off.
  const childShownProp = defineProp(set, 'Child shown', 'BOOLEAN', true);
  // `label` / `description` are `String?` on the contract, and null is a real
  // value for both — a field with no label, a field with no helper line. These
  // two BOOLEANs are that null, which is what the widget's `if (hasLabel)` and
  // its `!hasError && !hasDescription` early-return spend it as.
  //
  // Default TRUE for both: the preview opens on a field that has a label and a
  // helper line, because that is the shape a form field is usually reached for.
  const showLabelProp = defineProp(set, 'Show label', 'BOOLEAN', true);
  const showFooterProp = defineProp(set, 'Show footer', 'BOOLEAN', true);
  // `description` (contract) — the helper line under the input. It had no
  // property at all, so the copy a designer typed lived on the node and was
  // gone the moment the instance was swapped or the variant changed.
  //
  // Only the non-error members carry it, and that is not an omission: the
  // widget shows the description ONLY when there is no error
  // (`hasDescription = widget.description != null && !hasError`), so on the
  // error members there is no node for it to name. The error line is the
  // composed `ValidatorHint`'s own text, exposed below.
  const helperProp = defineProp(
    set,
    'Helper text',
    'TEXT',
    '이메일은 외부에 공개되지 않아요.',
  );
  for (const label of labels) bindTextProp(label, labelProp);
  for (const holder of holders) bindVisibleProp(holder, childShownProp);
  for (const field of fields) bindSwapProp(field, childProp);
  for (const header of headers) bindVisibleProp(header, showLabelProp);
  for (const footer of footers) bindVisibleProp(footer, showFooterProp);
  for (const desc of descriptions) bindTextProp(desc, helperProp);
  // The error message is `error` (contract), a DIFFERENT string from
  // `description` — the widget picks one or the other, never both. So it is
  // not `Helper text` under another name, and forwarding that property here
  // would state a value the widget does not read.
  //
  // It cannot be a property of THIS set either: the text lives inside a
  // composed `ValidatorHint`, and a TEXT property binds only to a text node
  // in its own component (the same reach limit this file records for the
  // label, which is why the label is not a composed `FormLabel`). Exposing
  // the instance surfaces the child's own `Message` in the panel instead —
  // one place to type the error, rather than a designer opening the nested
  // instance to reach it.
  // `labelAction` / `counterText` — the two slots that were declared on
  // the canvas with nothing behind them (a Properties-panel entry a
  // designer could toggle to no effect). They are contract fields now, so
  // these bind to real nodes.
  //
  // The property NAMES are the ones already on the canvas (`Show
  // labelAction` / `labelAction` / `Show count` / `Count`) rather than the
  // Dart field names. `defineProp` matches by name+type, so keeping them
  // preserves the key — and with it every override on the instances that
  // already carry these properties. A rename would strand all of them and
  // mint a second set.
  const showLabelActionProp = defineProp(
    set,
    'Show labelAction',
    'BOOLEAN',
    false,
  );
  const labelActionProp = defineProp(
    set,
    'labelAction',
    'INSTANCE_SWAP',
    mainIdOf(page, 'Button', bestVariantName(page, 'Button', {
      Variant: 'plain',
      Size: 'sm',
    })),
  );
  const showCountProp = defineProp(set, 'Show count', 'BOOLEAN', false);
  const countProp = defineProp(set, 'Count', 'TEXT', '0 / 20');
  for (const a of labelActions) {
    bindVisibleProp(a.holder, showLabelActionProp);
    bindSwapProp(a.instance, labelActionProp);
  }
  for (const counter of counters) {
    bindVisibleProp(counter, showCountProp);
    bindTextProp(counter, countProp);
  }
  exposeAll(hints);
  // This is the wrapper frame that holds the variants on the page, not the
  // component. How a set is arranged for comparison is a canvas decision that no
  // widget or Core field has an opinion about. 620 fits exactly two 260-wide
  // members per row (24 + 260 + 16 + 260 + 24 = 584), so the wrap lands the four
  // corners as a 2×2 grid: `Error` across, `Disabled` down.
  // g7-preview-only: canvas gallery frame width for the variant set
  layoutSet(set, 620);
  return set;
}

// ─── Fieldset (legend + bordered group) ──────────────────────────────────────

// Data-driven from coui_core. Which box a member draws — padding, corner, edge
// weight, fill, edge colour — is its VARIANT's row (`FIELDSET.variants
// .defaultsByVariant`: `filled` · `outlined` · `plain`), the table both
// resolvers read at the head of the chain; what every variant shares
// (`fieldSpacing`, the legend inset, the description style, the two header
// gaps) is a flat `FIELDSET.fields` default. `plain` states no fill, no edge,
// no corner and no padding, so it draws no box — and takes no cast: a cast
// around nothing floats as a stray shadow, the same gate both resolvers apply
// (`hasBox`).
//
// The tree mirrors the widget's: the box holds a HEADER (the legend, then the
// optional description, `legendDescriptionGapStyle` apart) and a FIELDS column
// (`fieldSpacing` apart), the two set apart by `headerFieldsGapStyle` — tighter
// than the spacing between fields, so the header reads as belonging to what it
// names. The description is a TEXT + BOOLEAN property pair (`description` is
// `W?` on the contract and null is a real value: the BOOLEAN is that null).
//
// `legendTextStyle` drives the legend — `titleSmall` (16) at the role's own
// weight in `on-surface`, read from the style rather than restated beside it.
// `legendPadding` is consumed by the wrapper the Web twin emits (a legend
// `<div>` whose inset is this field, with the `<span>` inside).
//
// Static→variant-set promotion by ADOPTION (2026-09-11, same shape as
// FormLabel's below): the legend's role steps from `titleSmall` (xs/sm/md) to
// `titleMedium` (lg/xl/xl2), `fieldset.sizes.defaultsBySize`, so the set draws
// one `Size=` cell per picture — `md · lg`, derived by `distinctSizeCells`;
// the four repeating cells are retired in `RETIRED_VARIANTS` — × `Enabled`,
// and `Enabled=false` repaints the legend `disabledLegendColor` (a
// `disabled-content` graphics-only ink, an explicit canvas-literal decision
// distinct from the `onSurfaceSubtle` text tier `TextField`/`TextArea` paint
// on their disabled labels, one tier below the enabled label's
// `onSurfaceVariant`, `fieldset_style.dart`). So the
// loose COMPONENT this builder used to mint is adopted as `Size=md,
// Enabled=true` — the state it actually rendered (the flat
// `fields.legendTextStyle` this side used to read is the `md` rung's
// `titleSmall`, and the legend was always drawn in its enabled colour) —
// so its node id/key, and every instance of it, survives.
function buildFieldset(page: PageNode, lk: VarLookup): ComponentSetNode {
  const variantRows = new Map(Object.entries(FIELDSET.variants.defaultsByVariant));
  const sizeRows = new Map(Object.entries(FIELDSET.sizes.defaultsBySize));
  const ladder = FIELDSET.axes.size.members;
  // Two cells, not six — see `distinctSizeCells` (크기 단계 결정 2026-10-01).
  const sizes = distinctSizeCells(sizeRows, ladder, FIELDSET.constants.size.choice);
  const members = enumerateAxisAssignments([
    { axis: 'Variant', values: FIELDSET.axes.variant.members },
    { axis: 'Size', values: sizes.cells },
    { axis: 'Enabled', values: ['true', 'false'] },
  ]);
  const combos = members.map((m) => m.name);
  // The loose COMPONENT a canvas older than the set carries drew the outlined
  // look (a transparent fill inside an edge) — the member `VARIANT_RENAMES`
  // lands every older member on.
  const mount = mountSet(page, 'Fieldset', combos, {
    adoptLooseAs: 'Variant=outlined, Size=md, Enabled=true',
  });
  const f = FIELDSET.fields;
  const descriptionStyle = textStyleData(f.descriptionTextStyle);
  // Collected for the property pass below — the owner only becomes the set once
  // `finish()` has combined the variants.
  const legends: TextNode[] = [];
  const descriptions: TextNode[] = [];
  for (const { name: comboName, values: combo } of members) {
    const vr = variantRows.get(combo['Variant'])!;
    const sz = sizeRowFor(sizeRows, combo['Size'], ladder);
    const enabled = combo['Enabled'] !== 'false';
    const c = mount.getOrCreate(comboName);
    c.layoutMode = 'VERTICAL';
    c.primaryAxisSizingMode = 'AUTO';
    c.counterAxisSizingMode = 'AUTO';
    bindPad(c, lk, { l: vr.padding.l, r: vr.padding.r, t: vr.padding.t, b: vr.padding.b });
    // The box's own spacing is the one between its two children — the header
    // and the fields column. The spacing between fields lives on the column.
    c.setBoundVariable('itemSpacing', lk.space(dimVal(f.headerFieldsGapStyle.size)));
    bindRadiusN(c, lk, vr.borderRadius.topLeft);
    // A content surface when it has a fill — both platforms gate the marker on
    // one. `outlined` and `plain` state the transparent sentinel, so they draw no
    // material (the helper degrades a fill-less surface).
    const fill = colorData(vr.backgroundColor);
    const edge = colorData(vr.borderColor);
    applySurfaceMaterial(c, lk, fill, 'content', { radius: vr.borderRadius.topLeft });
    borderData(c, lk, edge, dimVal(vr.borderWidth) || 1);
    // A box exists when it paints a fill or an edge — the `hasBox` both
    // resolvers compute. A box-less member takes no cast.
    const paints = (cd: typeof fill): boolean =>
      cd != null && (cd.color != null || (cd.argb != null && argbAlpha(cd.argb, cd.opacity) > 0));
    const hasBox = paints(fill) || (dimVal(vr.borderWidth) > 0 && paints(edge));
    // It states no cast, so it takes the one a style contributes — Web marks it
    // on a box, Flutter paints it beside the box (or through the composed
    // container's fallback when filled).
    if (hasBox) addControlShadow(c, lk);
    // The widget wraps itself in `SizedBox(width: .infinity)` — it takes whatever its
    // parent gives it — and "fill" is not a width a COMPONENT can hold (only an
    // instance can be set to FILL). None of Fieldset's Core fields is a width.
    // g7-preview-only: Fieldset demo width, the widget is parent-width
    lockWidth(c, 280);

    // ── Header: the legend, then the description ──
    const header = panel('header', 'VERTICAL', lk, {});
    header.setBoundVariable('itemSpacing', lk.space(dimVal(f.legendDescriptionGapStyle.size)));
    // The legend rides in a wrapper that carries `legendPadding` — the Web twin
    // emits exactly that shape.
    const legendWrap = panel('legend', 'HORIZONTAL', lk, {});
    bindPad(legendWrap, lk, f.legendPadding);
    const legendStyle = textStyleData({
      role: sz.legendTextStyle.role,
      color: enabled ? sz.legendTextStyle.color : f.disabledLegendColor,
    });
    const legend = makeLabel('계정 정보', lk, textLabelOpts(lk, legendStyle));
    legendWrap.appendChild(legend);
    header.appendChild(legendWrap);
    legends.push(legend);
    // The description keeps its colour when disabled: the box's own opacity dims
    // it with the rest of the group, and only the legend is recoloured.
    const description = makeLabel(
      '결제와 영수증에 쓰여요.',
      lk,
      textLabelOpts(lk, descriptionStyle),
    );
    description.name = 'description';
    header.appendChild(description);
    descriptions.push(description);
    c.appendChild(header);

    // ── Fields: the rows are `TextField` instances ──
    // `children: List<W>` is caller-supplied and no Fieldset field describes a
    // row, so the rows are the component a caller actually reaches for — a
    // look-alike would not follow `TextField` when it changes (the content-hash
    // skip means a Fieldset whose own recipe is unchanged is never rebuilt).
    //
    // Two rows, not one: `fieldSpacing` is bound to this column's `itemSpacing`,
    // and with a single child that field would have nothing to separate.
    //
    // The placeholder copy stays at the child's default — a composed instance can
    // only be given that text through `InstanceNode.setProperties`, whose effect
    // the runtime harness cannot observe. A designer sets it from the instance
    // panel, where the composed field's own `Placeholder` property already is.
    const fields = panel('fields', 'VERTICAL', lk, {});
    fields.setBoundVariable('itemSpacing', lk.space(dimVal(f.fieldSpacing)));
    for (let i = 0; i < 2; i++) {
      const row = instanceOf(
        page,
        'TextField',
        bestVariantName(page, 'TextField', { Variant: 'Default', Size: 'md' }),
      );
      row.name = 'field';
      fields.appendChild(row);
      row.layoutSizingHorizontal = 'FILL';
    }
    c.appendChild(fields);
    // Stretch both children across the box — appended before the sizing is set,
    // because FILL is only legal on a child of an auto-layout parent.
    header.layoutSizingHorizontal = 'FILL';
    fields.layoutSizingHorizontal = 'FILL';
  }
  const set = mount.finish();
  // `legend: W?` — rendered as a text node, so it becomes a TEXT property. The
  // `children: List<W>` slot has no Figma counterpart (no repeated-slot
  // property exists); a designer adds field rows to the instance directly.
  const legendProp = defineProp(set, 'Legend', 'TEXT', '계정 정보');
  for (const legend of legends) bindTextProp(legend, legendProp);
  // `description: W?` — the widget draws the line only when it is given, so the
  // BOOLEAN is that null. Default TRUE: the preview opens on the whole anatomy
  // (legend, description, fields), the way FormField's `Show label` /
  // `Show footer` open on a field that has both.
  const showDescriptionProp = defineProp(set, 'Show description', 'BOOLEAN', true);
  const descriptionProp = defineProp(set, 'Description', 'TEXT', '결제와 영수증에 쓰여요.');
  for (const description of descriptions) {
    bindVisibleProp(description, showDescriptionProp);
    bindTextProp(description, descriptionProp);
  }
  rowSet(set);
  return set;
}

// Static→variant-set promotion by ADOPTION (2026-09-11, same shape as
// Fieldset's #4037/C4b above): the loose COMPONENT this builder used to mint
// is adopted as `Size=md, Enabled=true` — the state it actually rendered (the
// flat `fields.labelStyle` this side used to read is the `md` rung's
// `labelMedium`, and the indicator was always drawn at `requiredColor`, never
// `disabledColor`) — so its node id/key, and every instance of it, survives.
//
// `form_label.axes` promotes all six `Size` members, but the ladder states two
// pictures, so the set draws `Size` as the two cells `formLabelSizeCells`
// derives (`md · lg`) × `Enabled` = 4 members. The four cells that repeated a
// picture are retired in `RETIRED_VARIANTS`.
function buildFormLabel(page: PageNode, lk: VarLookup): ComponentSetNode {
  const sizeRows = new Map(Object.entries(FORM_LABEL.sizes.defaultsBySize));
  const ladder = FORM_LABEL.axes.size.members;
  const sizes = formLabelSizeCells();
  const gap = FORM_LABEL.fields.requiredIndicatorGapStyle;
  const members = enumerateAxisAssignments([
    { axis: 'Size', values: sizes.cells },
    { axis: 'Enabled', values: ['true', 'false'] },
  ]);
  const combos = members.map((m) => m.name);
  const mount = mountSet(page, 'FormLabel', combos, {
    adoptLooseAs: 'Size=md, Enabled=true',
  });
  const slots: {
    text: TextNode;
    indicatorHolder: FrameNode;
    indicator: TextNode;
  }[] = [];
  for (const { name: comboName, values: combo } of members) {
    const sz = sizeRowFor(sizeRows, combo['Size'], ladder);
    const enabled = combo['Enabled'] !== 'false';
    const c = mount.getOrCreate(comboName);
    c.layoutMode = 'HORIZONTAL';
    c.primaryAxisSizingMode = 'AUTO';
    c.counterAxisSizingMode = 'AUTO';
    c.counterAxisAlignItems = 'CENTER';
    c.setBoundVariable('itemSpacing', lk.space(dimVal(gap.size)));
    c.fills = [];
    const label = textStyleData({
      role: sz.labelStyle.role,
      color: enabled ? sz.labelStyle.color : FORM_LABEL.fields.disabledColor,
    });
    const text = makeLabel('비밀번호', lk, textLabelOpts(lk, label));
    c.appendChild(text);
    // `requiredIndicator ?? Text('*')`, and the widget renders it only
    // `if (isRequired)` — so the slot needs both properties, and both cannot
    // sit on one node. The holder frame takes the boolean ("is this field
    // required"), the asterisk inside it takes the slot's own name.
    //
    // Hidden at rest: `isRequired` defaults to false on both platforms
    // (`form_label.dart`), so the asterisk shows only when it is switched on.
    // A hidden auto-layout child also drops the gap in front of it, which is
    // what the widget's `if (isRequired) ...[gap, indicator]` does.
    const indicatorHolder = autoFrame('requiredIndicator', 'HORIZONTAL');
    indicatorHolder.visible = false;
    c.appendChild(indicatorHolder);
    const indicatorColor = enabled
      ? FORM_LABEL.fields.requiredColor
      : FORM_LABEL.fields.disabledColor;
    const indicator = makeLabel(
      '*',
      lk,
      typographyColorOpts(lk, label, colorData(indicatorColor)),
    );
    indicatorHolder.appendChild(indicator);
    slots.push({ text, indicatorHolder, indicator });
  }
  const set = mount.finish();
  const labelId = defineProp(set, 'Label', 'TEXT', '비밀번호');
  // Off by default: `isRequired = false` on both platforms.
  const requiredId = defineProp(set, 'Required', 'BOOLEAN', false);
  const requiredIndicatorId = defineProp(set, 'RequiredIndicator', 'TEXT', '*');
  for (const s of slots) {
    bindTextProp(s.text, labelId);
    bindVisibleProp(s.indicatorHolder, requiredId);
    bindTextProp(s.indicator, requiredIndicatorId);
  }
  rowSet(set);
  return set;
}

// ─── FileInput (drop zone) ───────────────────────────────────────────────────

// Data-driven from coui_core FILE_INPUT.fields: padding / itemSpacing /
// borderRadius / borderColor / borderWidth / dashLength / dashSpacing (the
// drop zone's border is dashed — see `dashPattern` below) for the box, iconStyle
// (upload glyph) + subtleIconColor for the icon, labelTextStyle +
// contentColor for the instruction line, hintTextStyle + hintColor for the
// line under the browse button, and fileTextStyle + fileNameColor /
// fileIconStyle + fileIconColor / fileItemSpacing for the selected-file row.
// There is no idle-state `backgroundColor` field on CoreFileInputStyle at all —
// only `dragActiveBackgroundColor` for the drag-over state — so the drop zone is
// explicitly unfilled at rest (`fillData(…, null)`, which clears rather than
// leaves Figma's default white); that absence is a decision the export records
// (`absent.backgroundColor`), not a gap.
//
// The hint and the file row are the last two children of the widget's own
// `Column`, and they went undrawn here. Seven fields (the six named above plus
// `fileItemSpacing`) therefore had no node to land on: the JSON stated
// `labelMedium` for both text lines and the canvas had nothing at 13px, which
// is what the readback reported and what no provenance guard could. Drawing
// them is what consumes those fields — they are not restated here.
//
// `Enabled` axis (the four-axis spelling `file_input.axes` promotes, replacing
// the `Disabled=` one this side first wrote): at `Enabled=false` the widget
// swaps a colour on each of the four content
// nodes — `borderColor` → `disabledBorderColor` on the box, and
// `contentColor` (label) / `hintColor` (hint) / `fileNameColor` (file name)
// all → `disabledContentColor`, with the file glyph's `fileIconColor` →
// `subtleIconColor`. The upload glyph alone does not change: the resolver's
// `iconStyleDisabled` keeps `subtleIconColor`, the tone it already has. While a
// file is dragged over an enabled zone the glyph wears `dragActiveIconColor`
// (primary) together with the icon box and the dashed border.
// `clickableStyle.pressedScale` and
// `clickableStyle.disabledOpacity` are both 1 — no axis, they would render
// identically. `clickableStyle.focusOutlineStyle` draws a ring *outside* the
// component (a separate `FocusOutline` node); the only stroke this preview owns
// is the drop-zone border itself, and repainting that would attribute the ring
// to the wrong node, so there is no `Focus` axis here.
//
// `DragOver` axis: a file being dragged over the zone repaints these and
// `file_input.dart` states them outright (the upload glyph and the icon box
// follow, `dragActiveIconColor` / `dragActiveIconBoxColor`) —
// `borderColor → dragOverBorderColor` (primary, on the same dashed stroke) and
// the container fill → `dragActiveBackgroundColor` (primary at 5 %). Neither
// had a node before: the box was drawn once, in its resting colours, so two
// stated colours had nowhere on the canvas to land and a designer had no way to
// see what a drop target looks like mid-drag. It is a variant axis and not a
// BOOLEAN because a Figma boolean can only show or hide a layer — it cannot
// swap a stroke's colour, and faking it with a translucent overlay would leave
// the resting dashed border visible *under* the drag one, which is a picture
// neither platform draws.
//
// Disabled wins over it, mirroring the widget: `handleDragEnter` returns early
// when `!enabled`, so `_isDragOver` cannot become true on a disabled zone, and
// the border reads `!enabled ? disabled : _isDragOver ? dragOver : idle` with
// the fill guarded by `enabled &&`. The two `Enabled=false` corners therefore
// render alike — that is the code's precedence, not a collapsed axis.
//
// #4037 (C4b) — static→variant-set promotion by ADOPTION. `file_input.axes`
// promotes ONLY `enabled`, and this side appends the `DragOver` pose, so the
// enumeration is 2×2 = 4 and the loose COMPONENT the builder used to mint is
// adopted as `Enabled=true, DragOver=false` — the state it actually rendered (it
// read `borderColor`/`contentColor`, never the `disabled*` pair and never a drag
// colour) — so its node id/key, and every instance of it, survives. The upload
// glyph keeps `subtleIconColor` on both `Enabled` arms at rest: core declares no
// disabled variant of it, and inventing one is exactly the value this builder is
// not free to make up. Mid-drag it reads `dragActiveIconColor`.
//
// The browse affordance IS a node: the widget composes `Button(variant:
// .outline)` inside the column, so this instantiates the `Button` component
// rather than painting a pill that resembles one. Its `Disabled` axis is driven
// from this component's own, mirroring `onPressed: enabled ? handleBrowse :
// null`. Its label is the one the widget draws when the caller states none —
// `browseButtonText ?? localizations.fileInputBrowseButton` — written into the
// instance's `Child` property. Left at Button's own "버튼", the drop zone
// showed a word no FileInput ever renders.
//
// The prompt above it is the same: `label ?? localizations.fileInputDropLabel`.
// Both are the Korean chrome strings (`coui_i10n/chrome/i18n/ko.i18n.json`),
// the locale the canvas is drawn in.
const kFileInputDropLabel = '파일을 여기로 끌어다 놓으세요';
const kFileInputBrowseLabel = '파일 선택';
// `Button`'s label TEXT property.
const kFileInputButtonLabelProp = 'Child';

// Display copy for the widget's last two `Column` children — `hint` (`String?`)
// and one entry of `selectedFiles` (`List<String>?`). Copy, not chrome: the same
// convention `_kValidatorHintText` follows below. Both are caller-supplied and
// both default to null, and the preview shows them filled for the same reason
// FormField opens with its `child` shown — a drop zone that states neither its
// accepted formats nor what a picked file looks like is not the state to open
// on, and every value they are drawn with is FileInput's own.
const kFileInputHint = 'PNG, JPG, PDF · 최대 10MB';
const kFileInputFileName = '2분기 보고서.pdf';
const kFileInputFileGlyph = 'file';

function buildFileInput(page: PageNode, lk: VarLookup): ComponentSetNode {
  const pad = FILE_INPUT.fields.padding;
  const f = FILE_INPUT.fields;
  // The four schema axes first (`file_input.axes` promotes only `enabled`), then
  // this side's `DragOver` pose. `kAxisOrder` lists poses after the four, so
  // `composeVariantName` accepts the pair in exactly this order and no other.
  const combos = enumerateAxisCombos([
    ...axisSpecsOf(FILE_INPUT.axes),
    { axis: 'DragOver' as const, values: ['true', 'false'] },
  ]);
  // The drop-zone glyph is drawn from the `Icon` default, so the bind leaves it
  // at `iconStyle.size` (see `IconOpts.fromVariant`).
  const iconSwap = iconSwapDefault(page, 'FileInput', 'Icon', iconMainId(page));
  const mount = mountSet(page, 'FileInput', combos, {
    adoptLooseAs: 'Enabled=true, DragOver=false',
  });
  const icons: InstanceNode[] = [];
  const fileRows: FrameNode[] = [];
  for (const comboName of combos) {
    const combo = parseVariantKey(comboName);
    const disabled = combo['Enabled'] === 'false';
    // `enabled && _isDragOver` — the widget's own guard, and the reason the two
    // disabled corners render as disabled-idle rather than as a disabled drag.
    const dragging = combo['DragOver'] === 'true' && !disabled;
    // This node is what the widget's `Clickable` wraps — that wrapper owns tap
    // / keyboard activation / cursor / press scale / the focus ring
    // (`clickableStyle`), and contributes no chrome of its own that this
    // preview can draw: `pressedScale` and `disabledOpacity` are both 1, and
    // the ring it draws sits OUTSIDE the drop zone (a separate `FocusOutline`
    // node). So `Clickable` has no node to instantiate here — the drop-zone
    // box below is the whole of what it renders.
    const c = mount.getOrCreate(comboName);
    c.layoutMode = 'VERTICAL';
    c.primaryAxisSizingMode = 'AUTO';
    c.counterAxisSizingMode = 'AUTO';
    c.primaryAxisAlignItems = 'CENTER';
    c.counterAxisAlignItems = 'CENTER';
    bindPad(c, lk, { l: pad.l, r: pad.r, t: pad.t, b: pad.b });
    c.setBoundVariable('itemSpacing', lk.space(dimVal(f.itemSpacing)));
    bindRadiusN(c, lk, f.borderRadius.topLeft);
    // `AnimatedContainer(decoration: BoxDecoration(color: backgroundColor))` —
    // `enabled && _isDragOver ? dragActiveBackgroundColor : backgroundColorIdle`,
    // and idle is `CoreColor.transparent` because the Style declares no
    // `backgroundColor` at all. Written on both arms so the resting zone is
    // explicitly cleared rather than left on whatever fill a fresh Figma frame
    // arrives with. The drag-active fill is a content surface on both
    // platforms, marked only while a fill is painted — the idle zone clears
    // through the same call (a fill-less surface wears no material).
    applySurfaceMaterial(c, lk, dragging ? colorData(f.dragActiveBackgroundColor) : null, 'content', {
      radius: f.borderRadius.topLeft,
    });
    // A disabled zone paints its opaque `disabledBackgroundColor`
    // (`disabledContainer`) and takes no material — the widget's
    // `backgroundColorDisabled` branch bypasses the surface fold — so the fill
    // is stated after the (clearing) call above rather than through it.
    if (disabled) fillData(c, lk, colorData(f.disabledBackgroundColor));
    borderData(
      c,
      lk,
      colorData(
        disabled
          ? f.disabledBorderColor
          : dragging
            ? f.dragOverBorderColor
            : f.borderColor,
      ),
      dimVal(f.borderWidth) || 1,
    );
    // The border is DASHED, and was drawn solid here until this line existed.
    // `file_input.dart` does not put it in the `BoxDecoration` at all — a
    // `CustomPaint(_DashedBorderPainter(dashLength: resolved.dashLength,
    // dashGap: resolved.dashSpacing))` strokes the rounded-rect path — which is
    // why the JSON's two dash fields had nothing on this canvas to land on
    // while the drop zone read as an ordinary bordered box. Figma expresses the
    // same thing on the frame itself: `dashPattern` is [on, off] in px along the
    // stroke, applied to the stroke `borderData` just set.
    //
    // A file over the zone turns the edge SOLID (`_DashedBorderPainter(solid:
    // isDragActive)`, Web `stroke-dasharray: none`) — same colour and width.
    c.dashPattern = dragging ? [] : [dimVal(f.dashLength), dimVal(f.dashSpacing)];
    // iconStyle.size traces to CoreIconSize -> CoreSize, not CoreFontSize —
    // glyphOpts(..., 'size') binds the correct scale (#3754 axis fix).
    // The glyph sits in a circular box (`iconBoxSize` on a side, the fully
    // round `iconBoxBorderRadius`), filled `iconBoxColor` — or
    // `dragActiveIconBoxColor` while a file is dragged over the zone. The
    // widgets stack: icon box → itemSpacing → [text block → actionSpacing →
    // buttons], the text block being title → textSpacing → hint.
    const iconBox = autoFrame('icon box', 'HORIZONTAL');
    iconBox.primaryAxisAlignItems = 'CENTER';
    iconBox.counterAxisAlignItems = 'CENTER';
    bindSize(iconBox, lk, dimVal(f.iconBoxSize), dimVal(f.iconBoxSize));
    bindRadiusN(iconBox, lk, f.iconBoxBorderRadius.topLeft);
    fillData(
      iconBox,
      lk,
      colorData(disabled ? f.disabledIconBoxColor : dragging ? f.dragActiveIconBoxColor : f.iconBoxColor),
    );
    // iconStyle.size traces to CoreIconSize -> CoreSize, not CoreFontSize —
    // glyphOpts(..., 'size') binds the correct scale (#3754 axis fix).
    const icon = makeIcon('upload', lk, {
      ...glyphOpts(
        lk,
        colorData(disabled ? f.disabledContentColor : dragging ? f.dragActiveIconColor : f.subtleIconColor),
        f.iconStyle.size,
        'size',
      ),
      fromVariant: iconSwap.variant,
    });
    iconBox.appendChild(icon);
    c.appendChild(iconBox);
    icons.push(icon);
    const group = autoFrame('content', 'VERTICAL');
    group.counterAxisAlignItems = 'CENTER';
    group.setBoundVariable('itemSpacing', lk.space(dimVal(f.actionSpacing)));
    c.appendChild(group);
    // The group spans the zone, centred in it: the widget's `AnimatedContainer`
    // takes whatever width its host gives and centres the column inside, so a
    // designer's FILL widens the dashed region with the prompt following. The
    // preview width below stays — it is the default size, not the only one (#4805).
    group.layoutSizingHorizontal = 'FILL';
    const textBlock = autoFrame('text', 'VERTICAL');
    textBlock.counterAxisAlignItems = 'CENTER';
    textBlock.setBoundVariable('itemSpacing', lk.space(dimVal(f.textSpacing)));
    group.appendChild(textBlock);
    textBlock.layoutSizingHorizontal = 'FILL';
    const prompt = makeLabel(
      kFileInputDropLabel,
      lk,
      textLabelOpts(
        lk,
        textStyleData(f.labelTextStyle),
        colorData(disabled ? f.disabledContentColor : f.contentColor),
      ),
    );
    textBlock.appendChild(prompt);
    prompt.layoutSizingHorizontal = 'FILL';
    // Stated, the way `docs-frames.ts` states it for its FILL labels — Figma
    // flips a FILL text to HEIGHT auto-resize itself, but the double does not.
    prompt.textAutoResize = 'HEIGHT';
    prompt.textAlignHorizontal = 'CENTER';
    // `if (widget.hint != null) Text(hint, hintTextStyle{Enabled|Disabled})`.
    // `hintColor` is its own tone (a dimmer step than the label's
    // `contentColor`), and disabled collapses onto the shared
    // `disabledContentColor` — which is what the resolver bakes per state.
    const hint = makeLabel(
      kFileInputHint,
      lk,
      textLabelOpts(
        lk,
        textStyleData(f.hintTextStyle),
        colorData(disabled ? f.disabledContentColor : f.hintColor),
      ),
    );
    textBlock.appendChild(hint);
    hint.layoutSizingHorizontal = 'FILL';
    hint.textAutoResize = 'HEIGHT';
    hint.textAlignHorizontal = 'CENTER';
    const browse = instanceOf(
      page,
      'Button',
      // Follows the field's own `Enabled` axis. It used to ask through a
      // `Disabled` key, which Button never had — and `bestVariantName` scores
      // rather than demands, so the key contributed nothing and a disabled
      // field's browse button rendered enabled on every member.
      bestVariantName(page, 'Button', {
        Variant: 'outline',
        Size: 'md',
        State: disabled ? 'disabled' : 'enabled',
      }),
    );
    setInstanceTextNamed(browse, kFileInputButtonLabelProp, kFileInputBrowseLabel);
    group.appendChild(browse);
    // `for (final file in selectedFiles) Row(spacing: fileItemSpacing)[
    //    Icon(fileIconStyle{…}), Text(file, fileTextStyle{…}) ]` — one row,
    // which is the shape one selected file takes. Like the upload glyph above,
    // `fileIconStyle.size` traces to `CoreIconSize -> CoreSize`, so it binds the
    // `'size'` scale rather than the font-size one (#3754 axis fix).
    const fileRow = autoFrame('file', 'HORIZONTAL');
    fileRow.counterAxisAlignItems = 'CENTER';
    fileRow.setBoundVariable('itemSpacing', lk.space(dimVal(f.fileItemSpacing)));
    fileRow.appendChild(
      makeIcon(
        kFileInputFileGlyph,
        lk,
        glyphOpts(
          lk,
          colorData(disabled ? f.disabledContentColor : f.fileIconColor),
          f.fileIconStyle.size,
          'size',
        ),
      ),
    );
    fileRow.appendChild(
      makeLabel(
        kFileInputFileName,
        lk,
        textLabelOpts(
          lk,
          textStyleData(f.fileTextStyle),
          colorData(disabled ? f.disabledContentColor : f.fileNameColor),
        ),
      ),
    );
    c.appendChild(fileRow);
    // Drawn hidden: the zone opens on the state with nothing picked (the
    // widget draws a row per `selectedFiles` entry, so none by default). A
    // hidden child takes no room in the auto layout, which is what makes the
    // zone 224 tall instead of 252.
    fileRow.visible = false;
    fileRows.push(fileRow);
    // After the children, not before — `lockWidth`'s own contract. Called on an
    // empty auto-layout frame it fixes the cross axis against nothing, and the
    // frame then grows from its children instead of holding the stated width.
    // The drop zone has no width in the widget — it hugs, and none of FileInput's
    // 24 Core fields is a width — so how large the dashed region reads is ours.
    // g7-preview-only: FileInput drop-zone demo width, no width field in the code
    lockWidth(c, 320);
  }
  const set = mount.finish();
  // `icon: W?` is filled with an `Icon` instance, so the slot is an
  // INSTANCE_SWAP whose default is the glyph the demo already shows.
  // Read from the Icon COMPONENT, not back off the instance —
  // `InstanceNode.mainComponent` is write-only under
  // `documentAccess: "dynamic-page"` and throws on read, which failed this
  // entry and left a half-drawn FileInput on the page.
  const iconProp = defineProp(set, 'Icon', 'INSTANCE_SWAP', iconSwap.id);
  for (const icon of icons) bindSwapProp(icon, iconProp);
  // `Show file` — canvas-only. The widget has no flag: a file row exists per
  // entry of `selectedFiles`, so the zone with nothing picked is the one whose
  // list is null or empty. The BOOLEAN switches the one row this preview draws
  // on and off; it opens OFF because the file row exists only once a file has
  // been picked (every member above is drawn with that row hidden).
  const showFileProp = defineProp(set, 'Show file', 'BOOLEAN', false);
  for (const row of fileRows) bindVisibleProp(row, showFileProp);
  rowSet(set);
  return set;
}

// ─── InputOtp (segmented boxes) ──────────────────────────────────────────────
// Figma name matches the coui_flutter class `InputOtp` (#3745) — not
// "InputOTP"; renamed in place via src/renames.ts SET_RENAMES.

// Data-driven from coui_core INPUT_OTP.fields: cellSize / cellHeight (a 44 × 52
// box at rest — `cellHeight` follows `cellSize` only when a caller states a
// width and no height) / height (the row, never shorter than the cell — both
// resolvers take the larger) / cellSpacing / borderRadius / borderWidth, the two
// resting looks a cell has by whether it holds a character (backgroundColor /
// borderColor for an empty cell, filledBackgroundColor / filledBorderColor for a
// filled one), the caret (caretColor / caretWidth / caretHeight /
// caretBorderRadius) the active empty cell draws, and the separator bar
// (separatorPadding / separatorColor / separatorWidth / separatorThickness /
// separatorBorderRadius) the widget inserts every `separatorInterval` cells (see
// `kInputOtpSeparatorInterval`). `variants.defaultsByVariant.error` restates
// `error` on every border and on the caret, and that is the whole of what
// `Variant` dispatches on. `textStyle` drives the digit — at rest `titleMedium`
// (18, its own semi-bold) in `on-surface`, and on a larger rung whatever that
// rung's row lays over it (see the `Size` axis below).
//
// `focusBorderColor` defaults to the neutral `outline` on the active cell,
// empty or filled — never `primary`: the caret plus the `FocusOutline` ring are
// the focus signal (#6464). The error row restates `error`.
//
// No composition-slot property: `CoreInputOtpContract` has none — the cells are
// generated from `length`, not passed in. What it does carry is content
// (`errorText`, `obscured`) and those become the four properties at the end.
//
// ─── The `Size` axis ─────────────────────────────────────────────────────────
//
// `CoreInputOtpContract.size` is a `CoreInputOtpSize` (md · lg), a component
// enum rather than `CoreComponentSize`, so the exporter records it under
// `axes.other` and never promotes it to `axes.size` — `axisSpecsOf` gives no
// Size, and the builder adds the axis itself between `Variant` and `State`, the
// way DotIndicator and Progress do. Its rows are `sizes.defaultsBySize`.
//
// Both resolvers put the size row, with the variant row laid over it, at the
// HEAD of the merge chain — `resolveStyleChain(chainHeadFor(size, variant),
// [theme.style, …, widget style])` — and every value is then `merged.X ??
// CoreInputOtpStyle.defaultX`. A size row's value therefore stands in front of
// the field default and behind the variant row, which is what each member reads
// here: the variant row's colour if it states one, then the size row's, then
// the field. `md` states nothing — every value is the field's. `lg` states the
// cell (56 × 64, on the size scale, not the control ladder: neither resolver
// moves the cell with a density) and the row floor (64), the corner (14), the
// caret height (24) and the `headlineSmall` role for the digit (24) at
// semi-bold — a weight overlay over the role's own bold, so the label carries
// no text style (a label whose weight differs from its role is drawn by its
// variable bindings, as every weight overlay is). The widgets pin those digits
// to the desktop typography tier; the canvas has no viewport, so it draws them
// at the desktop size anyway.
// Colours, the dot, the separator bar and the error line do not vary by size.
//
// ─── The `State` axis lives on the container ─────────────────────────────────
//
// `Variant` comes from `axes`; `State` is declared by this builder, exactly as
// Button does it, with `Enabled` filtered out so `State=disabled` is the only
// place "disabled" is said (`axisValueOf` folds it back for the coverage
// gate). It rides on the CONTAINER, not on a cell, because focus and enabled
// are container facts: one `FocusNode` on one hidden `TextField` owns them,
// and `_activeIndex` — which cell wears the ring — is derived from the typed
// length, never chosen per cell. A designer flips the container's `State` and
// the composed cells follow, which is what the widget can render and nothing
// it cannot.
//
// The ladder (`input_otp.dart` / `input_otp_style.dart`), read top-down:
//
//   disabled   → `Opacity(opacity50)` over the cell row; the hidden buffer is
//                `enabled: false`, so no cell can hold focus and every ring is
//                `focused: false`. The error line is a `Column` sibling OUTSIDE
//                that `Opacity` and is not dimmed.
//   focus      → `isActive = _focusNode.hasFocus && index == _activeIndex`:
//                exactly one cell takes `focusedCellContainerStyle` and its
//                ring is visible; the other cells stay at rest.
//   hover      → `_hovered && enabled && !focusNode.hasFocus`: every cell steps
//                its border to `hoveredCellContainerStyle`'s. Hover is a fact
//                of the CONTAINER — one hidden `TextField` spans the row and
//                the cells are `IgnorePointer` — so the cells step together,
//                and a focused control steps no cell at all.
//   resting    → no cell is active, every ring is `focused: false`.
//
// The loose COMPONENT an older build minted is adopted as `Variant=
// defaultVariant, Size=md, State=focus`: its body drew the 40 cells with the
// ring visible and the focus fill on cell 1 unconditionally, and the adoption
// name is what the node ACTUALLY rendered, not what rest should look like.
//
// `Variant=error` and the `Error shown` BOOLEAN below are NOT the same switch,
// because they are not the same input in code: `InputOtp(variant:, errorText:)`
// takes them separately — `variant` picks `defaultsByVariant`, `errorText` is a
// caller-supplied `String?` that appends a line. So the axis retints the resting
// border and the boolean reveals the message, and a designer can have either
// without the other, exactly as a caller can.
//
// ─── Structure: a stack, not a row ───────────────────────────────────────────
//
// The widget is `Stacks[Position.fill(hiddenInput), IgnorePointer(visualRow)]`
// — ONE `TextField` spanning the whole cell row owns the keyboard / autofill /
// caret, and the N visual cells are painted on top of it. That layering is the
// component's actual shape: the stack is an auto-layout frame whose ONE flow
// child is the cell row — so it hugs the row's width, and a hidden separator
// (`Show separator` off) takes its width with it instead of leaving a gap at the
// end — and the buffer is ABSOLUTE inside it, layered under the row rather than
// flowed beside it. The buffer is a real `TextField` instance rather than
// something this file redraws.
//
// The buffer instance is `visible = false`, which is what the widget renders:
// `_kHiddenBufferStyle` paints it with a transparent background, a transparent
// border, transparent value text and no cursor. It is in the layer tree — a
// designer inspecting the component sees that InputOtp is backed by a
// `TextField`, and the Figma→code direction can read that back — but it paints
// nothing, exactly as in code. Its chrome is not stripped field-by-field here:
// the instance follows the `TextField` component, and hiding it is one
// statement instead of a fork of the child's recipe.
//
// `Size=md` on every member, `lg` included: `input_otp.dart` hands the hidden
// `TextField` no `size`, so it is the field's own default whatever rung the
// cells are on. Its extent is not the field's anyway — the instance is resized
// to the cell row below (`Position.fill` under the whole row), 40 on `md` and
// 56 on `lg`.
//
// `FocusOutline` IS composed, one instance per cell — `_buildCell` wraps every
// cell in `FocusOutline(focused: isActive, child: AnimatedContainer(box))`, so a
// ring drawn here by hand would be a second ring implementation, and `input_otp`
// exports no ring colour to draw it with anyway. That is the point of composing:
// the colour and the width come from `FocusOutline`'s own defaults, which is
// exactly where the widget gets them ("Focus-ring colour / width come from
// `FocusOutline`'s own design-system defaults").
//
// It rides above each cell as an ABSOLUTE layer rather than wrapping it, because
// a Figma instance cannot take appended children — so the cell cannot go inside
// the ring. The ring's own `child` slot is resized to the cell instead, which is
// what makes it hug the cell rather than its 160×48 preview placeholder. Only the
// active cell's ring is visible; the other five are `focused: false` in code and
// paint nothing, and hidden is what "paints nothing" looks like on canvas.
//
// The ring takes the CELL's corner, on every rung: the resolver forwards
// `cellFocusOutlineStyle.borderRadius = <the cell's borderRadius>`, and
// `FocusOutline.borderRadius` is `@hostDerived` — its main draws around a
// preview slot of its own. So the instance root takes the cell corner and its
// two drawn layers take what the widget derives from it, the band at `corner +
// align − borderWidth` and the ring at `corner + align`
// (`forwardCellCornerToRing`). Each is bound to its `radius/<n>` step when the
// ladder has one — the way FocusOutline's own preview binds them — and written
// as a number only when it does not: a 14 cell has an 18 ring, which no rung
// carries, and the binding `forwardFocusOutlineHostRadius` does would fail the
// whole entry there. At `md` the band and ring are the radius/10 · radius/12
// FocusOutline's preview already binds (its slot stands in at the same 8), so
// the resting rung keeps following a pinned density or surface style exactly
// as it did.
//
// The active cell's box underneath that ring follows the resolver's own fold:
// `focusBorderColor ?? variantStyle.focusBorderColor ?? <the fill state's
// border>` → `defaultFocusBorderColor`. On `Variant=error` that is the
// `error` token; on `defaultVariant` it is `outline`, and the ring and the
// caret say "focused". Its FILL is `focusBackgroundColor`, whose terminal is
// the empty cell's fill.
//
// The ring's colour is FocusOutline's own default on `defaultVariant` —
// `cellFocusOutlineStyle` only states a `borderColor` when the resolved focus
// border is non-null, which is the error variant alone. So the error member
// retints the composed ring and the default member leaves the instance
// untouched, exactly the two arms the resolver has.
//
// ─── Which cell is filled, and which is active ───────────────────────────────
//
// They are not the same cell, and drawing them as one asserted a state the
// widget cannot render. `_activeIndex` is `_controller.text.length` clamped to
// the last index, so the ring sits on the NEXT empty slot — a cell that is both
// filled and active exists only when all six are, and then the other five carry
// digits too. This preview draws one digit typed: cell 0 filled, cell 1 active.
//
// ─── The obscured dot ────────────────────────────────────────────────────────
//
// `_buildValueWidget` returns EITHER `Text(digit)` or a `Container(shape:
// .circle, width/height: obscuredDotSize)` (10) — the same slot, decided by
// `widget.obscured`. So the dot is drawn as a real ELLIPSE the size the field
// states, in the value glyph's own colour (`obscuredDotColor` is not a field of
// its own: the resolver reads `CoreInputOtpStyle.defaultTextStyle.color!`, so
// the dot and the digit are one colour by construction).
//
// It takes TWO booleans to say "either", not one, and that is a Figma limit
// rather than a choice: a boolean points a node's `visible` at itself, so it can
// hide the dot or hide the digit but not swap them. The alternative — an
// `Obscured` variant axis — would turn this COMPONENT into a COMPONENT_SET,
// which changes the node's identity and detaches every instance a designer has
// already placed (#3737), for a state the field spends none of its time in. So
// `Obscured` reveals the dot, `Digit shown` hides the glyph it replaces, and the
// default (dot off, digit on) is `obscured: false`, the widget's own.
//
// ─── The error message ───────────────────────────────────────────────────────
//
// `errorText != null` wraps the whole stack in a `Column` and appends
// `Padding(errorTextPadding, ValidatorHint.error(message: Text(errorText)))` —
// so the root here is a column and the stack is a child of it. The line is a
// composed `ValidatorHint` instance: the `circle-alert` glyph (14, the partial
// `errorValidatorHintStyle` states), the `error` accent and the message role
// come from the hint, and its `Message` is exposed on this instance.
//
// Hidden, with the `Error shown` BOOLEAN over it, because `errorText` defaults
// to null. What flipping that boolean does NOT do is retint the cells — that is
// the `Variant=error` member's job, read from `defaultsByVariant.error`, the
// same map the widget dispatches.

/// `CoreInputOtpContract.defaultLength` — the cell count a caller who passes no
/// `length` gets, read from the export's `behaviour` (the same constant both
/// widgets default to). Previously this preview drew five, which is not a count
/// the widget produces by default — and then a literal six beside a comment
/// naming the widget const it copied.
const kInputOtpLength = INPUT_OTP.behaviour.length;

/// How many cells this preview shows as filled — `_controller.text.length`, and
/// therefore also `_activeIndex`: the ring sits on the first EMPTY cell. One,
/// so the canvas shows a filled cell, an active cell and four idle ones without
/// claiming a full field.
const kInputOtpTyped = 1;

/// `CoreInputOtpContract.defaultSeparatorInterval`, from the export's
/// `behaviour` — a caller who passes nothing gets a separator every third digit,
/// so the default six-cell field is drawn `000-000` and not `000000`. The
/// widget's own condition is `separatorInterval > 0 && i > 0 && i %
/// separatorInterval == 0`, evaluated before cell `i`, which for this length
/// puts exactly one separator in the middle.
const kInputOtpSeparatorInterval = INPUT_OTP.behaviour.separatorInterval;

/// The character the one filled cell shows, and the message the hidden error
/// line carries. Display copy, not chrome — the same convention
/// `_kValidatorHintText` follows: the character is whatever the controller
/// holds (`String.fromCharCode(_values[index])`) and `errorText` is a
/// caller-supplied `String?`, so both are content a designer replaces — the
/// message through the composed hint's exposed `Message`.
const kInputOtpDigit = '4';
const kInputOtpErrorText = '코드가 맞지 않아요. 다시 입력해 주세요.';

// The ladder's rungs in the order a designer reads them (see the header):
// rest, the zero-diff hover, the focused pose, and `disabled` last because it
// is where the ladder starts and the one nobody clicks through looking for.
const kInputOtpStates = stateAxis(['enabled', 'hover', 'focus', 'disabled']);

type InputOtpState = (typeof kInputOtpStates)[number];

// `CoreOpacity.opacity50` — what `input_otp.dart` wraps the cell row in when
// `enabled` is false, and what the Web resolver writes as `opacity` for the
// same case. A global token, not a `CoreInputOtpStyle` field, so
// `input_otp.fields` carries no key for it and the exporter emits no opacity
// scale to bind; a literal with the token named is the honest form until it
// does.
const kInputOtpDisabledOpacity = 0.5;

/// `CoreInputOtpSize.defaultSize` — the rung a caller who passes no `size` gets,
/// so the rung the loose COMPONENT is adopted under and the one a freshly placed
/// instance rests on. The exporter carries an enum's default only for the
/// Variant axis, so it is spelled here the way DotIndicator and Progress spell
/// theirs: the builder checks it against the exported members, and the runtime
/// harness against the Dart constant, so an enum change fails loudly instead of
/// resting on a member the enumeration no longer produces.
export const kInputOtpRestingSize = 'md';

/// The member a placed instance becomes, pinned top-left by `defaultSetLayout`:
/// the field a caller writes with no argument — the resting variant
/// (`CoreInputOtpVariant.defaultInputOtpVariant`), the resting rung, and no
/// state entered.
const kInputOtpLead = {
  Variant: 'defaultVariant',
  Size: kInputOtpRestingSize,
  State: restingValueOf('State'),
} as const;

// The cell's corner, forwarded into the cell's composed `FocusOutline` (see the
// header's FocusOutline note). The instance root takes the corner itself, bound —
// it is the cell's own, a ladder step. The band and the ring take the widget's
// derivation from it, through `derivedCorner` (the arithmetic `focusRing` and
// `pinComposedCorner` draw with). `pinComposedCorner` itself does not fit: it
// re-rounds a host's own direct `focus ring` FRAME, while a `FocusOutline`
// instance draws both layers as RECTANGLEs under its root.
function forwardCellCornerToRing(ring: InstanceNode, lk: VarLookup, cell: Dim): void {
  const outline = FOCUS_OUTLINE.fields;
  const hostCorner = dimVal(cell);
  const align = dimVal(outline.align);
  bindInstanceRadius(ring, lk, cell);
  writeDerivedCorner(
    focusOutlineBand(ring),
    lk,
    derivedCorner(hostCorner, align - dimVal(outline.borderWidth)),
  );
  writeDerivedCorner(focusOutlineRing(ring), lk, derivedCorner(hostCorner, align));
}

// Bound to the ladder's `radius/<n>` when it has that step — what the layer's
// main binds, so a corner that lands on a step keeps following a pinned density
// or surface style. Off the ladder the binding is lifted and the number written:
// a bound corner would keep drawing the preview's, and a step the ladder lacks
// would fail the whole entry over a number that renders fine unbound.
function writeDerivedCorner(layer: RectangleNode, lk: VarLookup, corner: number): void {
  const step = lk.radiusOrNull(corner);
  if (step != null) {
    for (const field of corners) layer.setBoundVariable(field, step);
    return;
  }
  for (const field of corners) layer.setBoundVariable(field, null);
  layer.cornerRadius = corner;
}

function buildInputOtp(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = INPUT_OTP.fields;
  const size = INPUT_OTP.axes.other.find((o) => o.enum === 'CoreInputOtpSize');
  if (!size) {
    throw new Error(
      'InputOtp: CoreInputOtpSize is gone from the exported axes — the canvas ' +
        'has a Size axis that nothing in the contract now backs.',
    );
  }
  if (size.members.indexOf(kInputOtpRestingSize) < 0) {
    throw new Error(
      `InputOtp: resting size "${kInputOtpRestingSize}" is not a member of ` +
        `CoreInputOtpSize (${size.members.join(' | ')}) — update kInputOtpRestingSize.`,
    );
  }
  const sizeData = new Map(Object.entries(INPUT_OTP.sizes.defaultsBySize));
  const variantData = new Map<string, object>(
    Object.entries(INPUT_OTP.variants.defaultsByVariant),
  );
  // How many separators this length + interval produces, by the widget's own
  // condition — one for the default 6 / 3, and the number the row's gap count
  // below depends on. The same on every rung: `length` and `separatorInterval`
  // are behaviour, not chrome.
  let separatorCount = 0;
  for (let i = 1; i < kInputOtpLength; i++) {
    if (kInputOtpSeparatorInterval > 0 && i % kInputOtpSeparatorInterval === 0) {
      separatorCount += 1;
    }
  }

  // `Variant` comes from the schema, so a variant added in Dart lands on the
  // canvas without touching this file; `Size` from `axes.other` and `State`
  // declared here — see the header. Enumerated once: `.name` goes to `mountSet`
  // and `.values` is read in the loop, so the two cannot drift apart.
  const members = enumerateAxisAssignments([
    ...axisSpecsOf(INPUT_OTP.axes).filter((spec) => spec.axis !== 'Enabled'),
    { axis: 'Size', values: size.members },
    { axis: 'State', values: [...kInputOtpStates] },
  ]);
  const mount = mountSet(
    page,
    'InputOtp',
    members.map((m) => m.name),
    {
      adoptLooseAs: composeVariantName([
        ['Variant', kInputOtpLead.Variant],
        ['Size', kInputOtpLead.Size],
        ['State', 'focus'],
      ]),
    },
  );
  // Collected for the property pass at the end — the owner only becomes the set
  // once `finish()` has combined the variants, and Figma rejects a reference on a
  // node not yet inside the component either way.
  const digits: TextNode[] = [];
  const dots: EllipseNode[] = [];
  const errorHolders: FrameNode[] = [];
  const errorHints: InstanceNode[] = [];
  const separators: FrameNode[] = [];
  for (const { name: comboName, values: combo } of members) {
    const state = combo['State'] as InputOtpState;
    const focused = state === 'focus';
    const hovered = state === 'hover';
    const disabled = state === 'disabled';
    // The rung's row, stated or not — `md` is `{}`, so every value below falls
    // through to the field default exactly as the code's chain head does (see
    // the header). Picked by the member's own axis value, never a literal key.
    const sz = sizeRowFor(sizeData, combo['Size'], size.members);
    const cellSizeDim = optField<Dim>(sz, 'cellSize') ?? f.cellSize;
    // `cellHeight ?? cellSize ?? defaultCellHeight` in both resolvers — a row
    // that states a cell and no height draws its own cell square.
    const cellHeightDim =
      optField<Dim>(sz, 'cellHeight') ?? optField<Dim>(sz, 'cellSize') ?? f.cellHeight;
    const cellSize = dimVal(cellSizeDim);
    const cellHeight = dimVal(cellHeightDim);
    const cellSpacing = dimVal(optField<Dim>(sz, 'cellSpacing') ?? f.cellSpacing);
    // The row is never shorter than its cells — `math.max(height, cellHeight)` in
    // both resolvers.
    const rowHeight = Math.max(dimVal(optField<Dim>(sz, 'height') ?? f.height), cellHeight);
    const cellCorner = (
      optField<typeof f.borderRadius>(sz, 'borderRadius') ?? f.borderRadius
    ).topLeft;
    const dotSize = optField<Dim>(sz, 'obscuredDotSize') ?? f.obscuredDotSize;
    const sepPad =
      optField<typeof f.separatorPadding>(sz, 'separatorPadding') ?? f.separatorPadding;
    // The separator bar — `Container(width: separatorWidth, height:
    // separatorThickness)` inside `Padding(separatorPadding)`; no rung states
    // its own, so each falls through to the field.
    const sepWidth = optField<Dim>(sz, 'separatorWidth') ?? f.separatorWidth;
    const sepThickness = optField<Dim>(sz, 'separatorThickness') ?? f.separatorThickness;
    const sepCorner = (
      optField<typeof f.separatorBorderRadius>(sz, 'separatorBorderRadius') ??
      f.separatorBorderRadius
    ).topLeft;
    // The caret — the active empty cell's insertion mark. `lg` restates its
    // height; the width and corner are the field's.
    const caretWidth = optField<Dim>(sz, 'caretWidth') ?? f.caretWidth;
    const caretHeight = optField<Dim>(sz, 'caretHeight') ?? f.caretHeight;
    const caretCorner = (
      optField<typeof f.caretBorderRadius>(sz, 'caretBorderRadius') ?? f.caretBorderRadius
    ).topLeft;
    // `defaultTextStyle.merge(merged.textStyle)` — the row's role (and the
    // semi-bold `lg` restates) over the field's, which keeps the field's colour.
    const digitStyle = mergeTextStyleData(
      textStyleData(f.textStyle),
      textStyleData(optField<TextLeaf>(sz, 'textStyle')),
    );
    // Every cell, every gap and every separator part is a token this builder
    // binds, so the row's width is known before the children are laid out —
    // still a floor, so a real measurement that disagrees wins below.
    const rowWidthFloor =
      kInputOtpLength * cellSize +
      (kInputOtpLength + separatorCount - 1) * cellSpacing +
      separatorCount * (dimVal(sepPad.l) + dimVal(sepPad.r) + dimVal(sepWidth));
    // The row is looked up by the combo's own axis value, never by a literal
    // key: `axes.variant.members` spells the resting variant `defaultVariant`
    // while the table keys it `default`, so the bridge is the same one
    // RadioGroup uses. `optField` because only the error row carries the two
    // colours — the default row is empty and falls through to the style-level
    // default, exactly the resolver's `?? variantStyle.X ?? default` chain.
    const variantRow =
      variantData.get(combo['Variant']) ?? variantData.get('default') ?? {};
    const rowBorder = optField<Color>(variantRow, 'borderColor');
    const rowFilledBorder = optField<Color>(variantRow, 'filledBorderColor');
    const rowFocusBorder = optField<Color>(variantRow, 'focusBorderColor');
    // The chain head is `defaultsBySize[size].merge(defaultsByVariant[variant])`
    // (`CoreInputOtpStyle.chainHeadFor`) — the VARIANT row lies over the size
    // row, so where both state a colour the variant's wins. Read in that order
    // here: variant row, then size row, then the field default.
    //
    // A cell has two resting looks, by whether it holds a character:
    // `merged.borderColor ?? variantStyle.borderColor ?? defaultBorderColor` for
    // an empty cell, `merged.filledBorderColor ?? variantStyle.filledBorderColor
    // ?? defaultFilledBorderColor` for a filled one.
    const emptyBorder = colorData(
      rowBorder ?? optField<Color>(sz, 'borderColor') ?? f.borderColor,
    );
    const filledBorder = colorData(
      rowFilledBorder ?? optField<Color>(sz, 'filledBorderColor') ?? f.filledBorderColor,
    );
    // `focusBorderColor ?? variantStyle.focusBorderColor ??
    // defaultFocusBorderColor` — the neutral `outline` on the active cell,
    // empty or filled, never `primary`: the caret and the ring say "focused"
    // (#6464). The error row states `error`.
    const focusBorder = colorData(
      rowFocusBorder ?? optField<Color>(sz, 'focusBorderColor') ?? f.focusBorderColor,
    );
    // `merged.hoverBorderColor ?? variantStyle.hoverBorderColor ?? default` —
    // the error row restates `error`, so the pointer never softens it.
    const hoverBorder = colorData(
      optField<Color>(variantRow, 'hoverBorderColor') ??
        optField<Color>(sz, 'hoverBorderColor') ??
        f.hoverBorderColor,
    );
    // `merged.backgroundColor ?? defaultBackgroundColor` for an empty cell,
    // `merged.filledBackgroundColor ?? defaultFilledBackgroundColor` for a
    // filled one; the active empty cell reads `focusBackgroundColor ??
    // backgroundColor ?? defaultFocusBackgroundColor` (the empty fill).
    const restingFillLeaf = optField<Color>(sz, 'backgroundColor');
    const emptyFill = colorData(restingFillLeaf ?? f.backgroundColor);
    const filledFill = colorData(
      optField<Color>(sz, 'filledBackgroundColor') ?? f.filledBackgroundColor,
    );
    const activeFill = colorData(
      optField<Color>(sz, 'focusBackgroundColor') ??
        restingFillLeaf ??
        f.focusBackgroundColor,
    );
    // `merged.caretColor ?? variantStyle.caretColor ?? defaultCaretColor` —
    // `primary`, `error` on the error row.
    const caretColor = colorData(
      optField<Color>(variantRow, 'caretColor') ??
        optField<Color>(sz, 'caretColor') ??
        f.caretColor,
    );
    // One width in every state — `merged.borderWidth ?? defaultBorderWidth` —
    // so the active cell's border does not move the box; Figma's frame stroke
    // is drawn inside.
    const cellBorderWidth = dimVal(optField<Dim>(sz, 'borderWidth') ?? f.borderWidth) || 1;
    // `Column(mainAxisSize: .min, crossAxisAlignment: .start)[stack, errorLine]`
    // — the shape `errorText != null` gives the whole widget. The column hugs and
    // paints nothing; the `Stacks` that layers the buffer under the cells is the
    // frame below, which is where the absolute positioning now lives.
    const c = mount.getOrCreate(comboName);
    c.layoutMode = 'VERTICAL';
    c.primaryAxisSizingMode = 'AUTO';
    c.counterAxisSizingMode = 'AUTO';
    c.counterAxisAlignItems = 'MIN';
    c.itemSpacing = 0;
    c.fills = [];

    // `Stacks[Position.fill(hiddenInput), IgnorePointer(visualRow)]` — sized by
    // its children, as a `Stacks` is: the cell row is the one flow child, so the
    // width HUGS it (an instance with `Show separator` off is narrower by the
    // separator and its gap, as `separatorInterval: 0` is in code), and the
    // height is FIXED at the rung's row floor (`math.max(height, cellHeight)`),
    // the row centred in it. The buffer is pinned ABSOLUTE below, so it layers
    // instead of flowing. `resize` first: it would turn a HUG axis back to FIXED.
    const stack = figma.createFrame();
    stack.name = 'stack';
    stack.fills = [];
    stack.resize(rowWidthFloor, rowHeight);
    stack.layoutMode = 'HORIZONTAL';
    stack.primaryAxisSizingMode = 'AUTO';
    stack.counterAxisSizingMode = 'FIXED';
    stack.counterAxisAlignItems = 'CENTER';
    stack.itemSpacing = 0;
    // The active cell's ring hangs `align` outside its box (below), and every
    // frame between it and the member — this one, `cells`, `seg` — defaults to
    // clipping its content, so the ring was cut off on all three and the
    // focused pose showed no ring at all (#6266). None of them paints anything
    // that needs a clip: the cells are their own boxes, the buffer is hidden.
    stack.clipsContent = false;
    // `Opacity(opacity: CoreOpacity.opacity50)` wraps the STACK, not the
    // column: the error line is a `Column` sibling outside it and stays at
    // full strength when the field is disabled.
    if (disabled) stack.opacity = kInputOtpDisabledOpacity;
    c.appendChild(stack);

    // `TextField(enabled: widget.enabled)` — the buffer follows the container's
    // rung. Hidden either way, so this changes what the layer tree says, not
    // what paints. `Size: 'md'` on every rung — see the header.
    const buffer = instanceOf(
      page,
      'TextField',
      bestVariantName(page, 'TextField', {
        Variant: 'Default',
        Size: 'md',
        Enabled: disabled ? 'false' : 'true',
      }),
    );
    buffer.name = 'hidden input buffer';
    buffer.visible = false;
    // `Position.fill` — ABSOLUTE, so it adds nothing to the hug and the row
    // alone sizes the stack, and STRETCH on both axes, so it follows the stack
    // when an instance hides its separators. Figma refuses absolute positioning
    // on an instance itself, so `pinAbsolute` pins it through a holder the
    // instance FILLs; the holder is renamed so the layer tree still reads the
    // buffer by its own name.
    const bufferPin = pinAbsolute(stack, buffer, 0, 0, {
      horizontal: 'STRETCH',
      vertical: 'STRETCH',
    });
    bufferPin.name = 'Position.fill';

    const row = panel('cells', 'HORIZONTAL', lk, { gap: cellSpacing });
    row.counterAxisAlignItems = 'CENTER';
    // Unclipped for the ring — see `stack` above.
    row.clipsContent = false;
    for (let i = 0; i < kInputOtpLength; i++) {
      // `if (separatorInterval > 0 && i > 0 && i % separatorInterval == 0)
      //    cells.add(_buildSeparator(resolved))` — a sibling of the cells in the
      // same `Row`, so `cellSpacing` falls on both sides of it automatically.
      // It is `Padding(separatorPadding, <the separator bar>)`.
      if (
        kInputOtpSeparatorInterval > 0 &&
        i > 0 &&
        i % kInputOtpSeparatorInterval === 0
      ) {
        const sep = autoFrame('separator', 'HORIZONTAL');
        sep.counterAxisAlignItems = 'CENTER';
        bindPad(sep, lk, { l: sepPad.l, t: sepPad.t, r: sepPad.r, b: sepPad.b });
        // `Container(width: separatorWidth, height: separatorThickness,
        // decoration: BoxDecoration(color: separatorColor, borderRadius:
        // separatorBorderRadius))` — a painted bar, not a glyph (#6464).
        const dash = figma.createRectangle();
        dash.name = 'dash';
        sep.appendChild(dash);
        bindSize(dash, lk, sepWidth, sepThickness);
        bindRadiusN(dash, lk, sepCorner);
        fillData(dash, lk, colorData(f.separatorColor));
        row.appendChild(sep);
        separators.push(sep);
      }
      // `isActive = _focusNode.hasFocus && index == _activeIndex`, and
      // `_activeIndex` is the typed length — so the ring is on the first EMPTY
      // cell, never on a filled one, and only while the field HAS focus: at
      // rest and when disabled no cell is active (see the header).
      const active = focused && i === kInputOtpTyped;
      const filled = i < kInputOtpTyped;
      const seg = figma.createFrame();
      seg.name = 'seg';
      seg.layoutMode = 'HORIZONTAL';
      seg.primaryAxisSizingMode = 'FIXED';
      seg.counterAxisSizingMode = 'FIXED';
      seg.primaryAxisAlignItems = 'CENTER';
      seg.counterAxisAlignItems = 'CENTER';
      // The cell is the ring's host: the ring sits `align` outside this box, so
      // the box must not clip it (`focusRing` does the same to its host). The
      // cell's own fill and stroke are drawn by the frame, not cut by a clip.
      seg.clipsContent = false;
      bindRadiusN(seg, lk, cellCorner);
      // The fill state's look — empty or filled — and, on the active cell,
      // the focus edge. The active cell is the next EMPTY slot (see the
      // header), so its fill arm is the empty one.
      const stateBorder = filled ? filledBorder : emptyBorder;
      fillData(seg, lk, filled ? filledFill : active ? activeFill : emptyFill);
      borderData(
        seg,
        lk,
        active ? focusBorder : hovered ? hoverBorder : stateBorder,
        cellBorderWidth,
      );
      if (filled) {
        // `_buildValueWidget` — one slot, two possible children. The digit is the
        // `obscured: false` arm and the dot the `obscured: true` one; each carries
        // its own BOOLEAN because a Figma boolean cannot swap two nodes (header).
        const digit = makeLabel(kInputOtpDigit, lk, textLabelOpts(lk, digitStyle));
        seg.appendChild(digit);
        digits.push(digit);
        const dot = figma.createEllipse();
        dot.name = 'obscured dot';
        // `Container(decoration: BoxDecoration(color: obscuredDotColor, shape:
        // .circle), width: obscuredDotSize, height: obscuredDotSize)`. An ellipse
        // is the circle — no radius to bind, which is also why the fidelity
        // readback accepts one where a full-round corner is stated. The size is
        // the rung's; the colour is not — the resolver reads
        // `CoreInputOtpStyle.defaultTextStyle.color!`, never the merged style.
        bindSize(dot, lk, dotSize, dotSize);
        fillData(dot, lk, textStyleData(f.textStyle).color);
        dot.visible = false;
        seg.appendChild(dot);
        dots.push(dot);
      }
      if (active && !filled) {
        // `Center(Container(width: caretWidth, height: caretHeight, decoration:
        // BoxDecoration(color: caretColor, borderRadius: caretBorderRadius)))`
        // — the insertion mark the widget draws in the active empty cell. The
        // cell is a centred auto-layout frame, so the caret sits in its middle.
        const caret = figma.createRectangle();
        caret.name = 'caret';
        seg.appendChild(caret);
        bindSize(caret, lk, caretWidth, caretHeight);
        bindRadiusN(caret, lk, caretCorner);
        fillData(caret, lk, caretColor);
      }
      row.appendChild(seg);
      bindSize(seg, lk, cellSizeDim, cellHeightDim);
      // `Position.fill(FocusOutline(focused: isActive, child: <the box>))` — one
      // per cell, because the widget wraps every cell whether or not it is active.
      // `Shape=rectangle` by name — `input_otp.dart` passes no `shape`, and
      // that is the contract's own default. Named rather than left to
      // `instanceOf`'s first-member fallback, which is a coin flip the moment
      // the enum's declaration order changes.
      const ring = instanceOf(page, 'FocusOutline', 'Shape=rectangle');
      ring.name = 'FocusOutline';
      const slot = instanceFrameSlot(ring, 'child');
      if (slot) slot.resize(cellSize, cellHeight);
      // And the instance itself, because a Figma instance does not re-hug when
      // an inner slot is resized (`buildDotIndicator` measured that on the live
      // canvas). The root is the wrapped box now — the cell — and the child's
      // two ring layers hang outside it on STRETCH constraints, so stating the
      // root's size is what carries them onto this cell instead of leaving
      // them at FocusOutline's own preview extent.
      ring.resize(cellSize, cellHeight);
      // `cellFocusOutlineStyle.borderRadius` — the cell's corner, on every cell
      // and every rung (see the header).
      forwardCellCornerToRing(ring, lk, cellCorner);
      // `cellFocusOutlineStyle.borderColor` is the focus border the variant
      // (or a caller) states — never the size row's: `lg`'s `primary` is the
      // active box's stroke, not the ring's. So it is non-null only on a
      // variant whose row states a focus border. A variant without one leaves
      // the instance untouched so FocusOutline's own `focus-ring` default
      // wins, and the width stays the ring's own — the style states none.
      //
      // Painted on the child's ring RECTANGLE, not on the instance root: the
      // root is the cell's own box and carries no stroke, so writing there
      // would draw a second ring flush against the cell beside the real one.
      if (rowFocusBorder) {
        borderData(
          focusOutlineRing(ring),
          lk,
          colorData(rowFocusBorder),
          FOCUS_OUTLINE.fields.borderWidth,
        );
      }
      // The instance is what this consumer gates (`visible = active`), so
      // its INNER layers have to be on — `FocusOutline` rests unfocused
      // now, and a shown instance whose `Focused` is false draws nothing.
      setInstanceBoolNamed(ring, 'Focused', true);
      // STRETCH, as every other focus ring is pinned (`focus-ring.ts`): the ring
      // is the cell's whole box, and a MIN pin left it at its minted size when a
      // designer resized the cell (#4701 — the same shape as Card's surface).
      const ringPin = pinAbsolute(seg, ring, 0, 0, {
        horizontal: 'STRETCH',
        vertical: 'STRETCH',
      });
      ringPin.visible = active;
      // The HOLDER carries the pin, so the holder is what STRETCH measures its
      // insets from — sized to the cell here, because a holder minted at the
      // instance's extent bakes the difference in as a permanent inset.
      sizePin(ringPin, cellSize, rowHeight);
    }
    stack.appendChild(row);
    // Now that the row holds its children, take Figma's own measurement of it if
    // there is one (see `rowWidthFloor`). The stack already hugs it; the buffer's
    // holder spans the same box because the widget's is `Position.fill` under
    // the whole row — one `TextField` owning the keyboard for every cell — and
    // its STRETCH keeps it there when the row narrows.
    const rowWidth = Math.max(rowWidthFloor, row.width);
    sizePin(bufferPin, rowWidth, rowHeight);

    // `Padding(padding: errorTextPadding, child: ValidatorHint.error(message:
    // Text(errorText), validatorHintStyle: errorValidatorHintStyle))` — the
    // second child of the `Column`, present only when `errorText != null`. The
    // hint is a composed instance, not a redrawn icon + label: the
    // `circle-alert` glyph, the `error` accent and the message role are the
    // hint's, and `applyValidatorHintStyle` writes the partial InputOtp states
    // over it (the 14 glyph). The holder carries the BOOLEAN; the message is
    // the hint's own `Message`, exposed on the instance.
    const errorHolder = autoFrame('errorText', 'HORIZONTAL');
    bindPad(errorHolder, lk, {
      l: f.errorTextPadding.l,
      t: f.errorTextPadding.t,
      r: f.errorTextPadding.r,
      b: f.errorTextPadding.b,
    });
    const hint = instanceOf(
      page,
      'ValidatorHint',
      bestVariantName(page, 'ValidatorHint', { Variant: 'error' }),
    );
    // The message role and the glyph–message gap go through the shared
    // writer; the glyph size does not, because the glyph is an `Icon` instance
    // inside the hint instance and Figma refuses a size override there. It is
    // swapped to the `Size=N` step the partial states instead (14), keeping the
    // hint's own `error` tint.
    applyValidatorHintStyle(hint, lk, {
      ...f.errorValidatorHintStyle,
      iconStyle: COMPONENTS.validator_hint.fields.iconStyle,
    });
    setSlotIcon(
      hint,
      'Icon',
      iconMainIdAt(page, dimVal(f.errorValidatorHintStyle.iconStyle.size)),
      'circle-alert',
      kPreserveGlyphPaint,
    );
    setInstanceTextNamed(hint, 'Message', kInputOtpErrorText);
    errorHolder.appendChild(hint);
    errorHolder.visible = false;
    c.appendChild(errorHolder);
    errorHolders.push(errorHolder);
    errorHints.push(hint);
  }
  const set = mount.finish();
  const errorShownProp = defineProp(set, 'Error shown', 'BOOLEAN', false);
  const obscuredProp = defineProp(set, 'Obscured', 'BOOLEAN', false);
  const digitProp = defineProp(set, 'Digit shown', 'BOOLEAN', true);
  // `separatorInterval` is behaviour, not chrome: on = the contract's default
  // interval (`CoreInputOtpContract.defaultSeparatorInterval`, the `000-000`
  // this preview draws), off = `separatorInterval: 0`, the contract's "no
  // separator". Every rung, every state — the widget's condition is the same
  // on all of them. The cells are an auto-layout row, so a hidden separator
  // takes its gap with it, as `Row(spacing:)` does when the child is absent.
  const separatorProp = defineProp(set, 'Show separator', 'BOOLEAN', true);
  for (const holder of errorHolders) bindVisibleProp(holder, errorShownProp);
  // The message is the composed hint's own `Message` — exposed, so a designer
  // edits it on the InputOtp instance without detaching anything.
  exposeAll(errorHints);
  for (const dot of dots) bindVisibleProp(dot, obscuredProp);
  for (const digit of digits) bindVisibleProp(digit, digitProp);
  for (const sep of separators) bindVisibleProp(sep, separatorProp);
  // Sixteen members in one row would run thousands of pixels wide, so the set
  // takes the axis grid: rows by `Size` (the axis that changes a member's
  // height), a band per `Variant`, and `State` across — with the field a caller
  // writes with no argument in the top-left corner Figma hands a new instance.
  defaultSetLayout(set, kInputOtpLead);
  return set;
}

// ─── PhoneInput (country code + number) ──────────────────────────────────────

// The one PAINTED frame inside a composed field instance — the node its chrome
// lives on.
//
// `TextField`'s component root paints nothing; the fill, the stroke and the
// radius live one level in, on the row its `Container(decoration:)` wraps. Found
// by which child is painted rather than by name for the reason
// `form-pickers.ts#paintedFieldRow` gives: writing empty over an already-empty
// root looks done and leaves the real row untouched.
function paintedChildRow(inst: InstanceNode): FrameNode {
  const painted: FrameNode[] = [];
  for (const kid of inst.children) {
    if (kid.type !== 'FRAME') continue;
    const fills = kid.fills;
    const hasPaint =
      (Array.isArray(fills) ? fills.length : 1) > 0 || kid.strokes.length > 0;
    if (hasPaint) painted.push(kid);
  }
  if (painted.length !== 1) {
    throw new Error(
      `paintedChildRow: expected exactly one painted FRAME child on ` +
        `${inst.name}, found ${painted.length}. TextField's inner shape ` +
        'changed — name the row instead of sweeping direct children.',
    );
  }
  return painted[0];
}

// Data-driven from coui_core PHONE_INPUT.fields: countryGapStyle (the dropdown
// row's name <-> dial-code gap, which is its only consumer on either platform —
// an earlier note here called it the selector<->input gap and no code spends it
// there) / flagGapStyle (gap inside the selector — reused below for
// the dial-code<->chevron pair too, since CorePhoneInputStyle has no
// separate token for that pair) / selectorPadding / inputFieldPadding /
// dialCodeTextStyle / chevronColor / backgroundColor / borderColor /
// borderRadius / borderWidth / bodyTextStyle / placeholderColor.
// `chevronIconStyle.size` is present but `null` in the JSON (no default
// value), so the chevron's box stays literal (#3754 OQ-2).
// There is no idle-state background field for the selector trigger itself
// (only `hoverColor` for the hover state), so it stays unfilled — matches
// the real default rather than the old hand-picked `surface-container`.
// `height` (40) is the root's fixed height, which is where the widget states it
// (`SizedBox(height: resolved.height)` wrapping the row) and what the two
// stretching children below measure themselves against.
//
// Three independent state axes, each a value the widget itself swaps:
//   Enabled  — at `false`, the dial code (`disabledDialCodeColor`) and the
//              chevron (`disabledChevronColor`). This is the axis
//              `phone_input.axes` promotes, and its `Enabled=` spelling is the
//              four-axis one — it replaces the `Disabled=` this side first wrote.
//   Hover    — the selector trigger's background, `_hovered ? hoverColor :
//              transparent` (that trigger has no idle fill at all).
//   Focus    — the field border, `_focused ? focusBorderColor : borderColor`.
// Disabled wins over the other two, exactly as the widget does (its hover
// handler returns early when disabled, and a disabled field takes no focus), so
// the four `Enabled=false` corners render alike — that is the behaviour, not a
// collapsed axis. `disabledOpacity` is also declared, and its default is
// `CoreOpacity.opacity100` (1.0) — applying it is a no-op, so the disabled
// combinations deliberately do NOT fade: core says the fade is 1.0, and picking
// a prettier number would be inventing chrome. No axis for it either.
//
// #4037 (C4b) — static→variant-set promotion by ADOPTION. `phone_input.axes`
// promotes ONLY `enabled`, and this side appends the `Hover` / `Focus` poses, so
// the enumeration is 2×2×2 = 8 and the loose COMPONENT this builder used to mint
// is adopted as `Enabled=true, Hover=false, Focus=false` — what it actually
// rendered (it read `chevronColor` and the plain dial code, never a `disabled*`
// field, and drew neither a hover fill nor a focus border), so its node id/key
// and every instance of it survive.
//
// ─── Structure: one bordered container holding trigger | divider | field ─────
//
// The widget's boundary belongs to the OUTER container, not to the number
// field: `Container(decoration: border/bg/radius) > ClipRRect > Row(stretch)[
// _CountrySelectorTrigger, Divider(orientation: .vertical), Flexible >
// Padding(inputFieldPadding) > TextField ]`. This builder used to paint that
// border around the number box alone, leaving the selector sitting outside the
// field — so the chrome now lives on the component root and the row has no
// spacing of its own (`countryGapStyle` is resolved but never read by the
// widget; the separator, not a gap, is what divides the two halves).
//
// Both halves that ARE components are instances:
//   `Divider`   — `Divider(orientation: .vertical, dividerStyle: …)`, whose
//                 colour comes from `separatorColor` (`outline-variant`) —
//                 the same token `CoreDividerStyle.defaultColor` already
//                 carries, so the instance needs no override. It FILLS the
//                 row's height rather than carrying one of its own, because
//                 the widget's `Row(crossAxisAlignment: .stretch)` inside
//                 `SizedBox(height: resolved.height)` is what gives it a
//                 length — the same stretch the selector trigger rides on.
//   `TextField` — the number input. The `Size=md` instance draws at the
//                 TextField floor (40), the same as PhoneInput's own
//                 `height`; in code the field states no floor of its own
//                 (`minHeight: 0`) and takes the row's height. Chromeless
//                 in code
//                 (`CorePhoneInputStyle.chromelessFieldStyle`: transparent
//                 background / border / focus ring, `borderWidth: 0`,
//                 `padding: .zero`) because the outer container owns the single
//                 boundary — and that forward is NOT expressed here; see the
//                 note above `buildPhoneInput`.
//
// One field the old hand-drawn number box read is deliberately no longer read
// on this row: `placeholderColor` is merged into
// `numberFieldStyle.placeholderStyle` and so reaches the placeholder through the
// `TextField` instance. `bodyTextStyle` styles the country NAME inside the
// dropdown popup, which the panel below now draws — using it for the number
// placeholder attributed the popup's typography to the wrong node.
//
// `popoverStyle` (a nested `CorePopoverStyle`) is a real composition edge — the
// widget wraps the whole field in `Popover(trigger: decorated, content:
// _CountryPickerPopup(…))` unconditionally — so a `Popover` instance is in the
// tree, hidden. Hidden because a visible instance renders a trigger AND a panel
// of its own, and this component already draws both: the bordered field IS the
// `trigger:` argument, and the panel below is the `content:`. Two triggers side
// by side, sixteen times over, is the double draw that is worse than not
// composing. A designer toggling the layer on reaches the real `Popover`
// component, which is the whole reason to compose it rather than describe it.
//
// ─── The country picker panel ────────────────────────────────────────────────
//
// `content: _CountryPickerPopup(…)` is PhoneInput's OWN drawing, not `Popup`'s:
// `Column[Padding(itemPadding, TextField(searchFieldStyle)), Divider,
// ConstrainedBox > ListView(_CountryPickerItem)]`, and each item is
// `Padding(symmetric(v: dropdownItemPadding.top, h: dropdownItemPadding.left)) >
// Row[flag(dropdownFlagSize), Gap(dropdownItemGapStyle), Expanded(Text(name,
// bodyTextStyle)), Gap, Text(dialCode, dropdownDialCodeTextStyle)]`. None of it
// was drawn, so the four `dropdown*` fields and `popoverTopOffset` had no node
// on the canvas to land on, `bodyTextStyle` was named in a comment as belonging
// to a popup that did not exist, and `searchFieldStyle` addressed a field
// nothing composed. Drawing the panel is what consumes them — except that
// slot's VALUES, which the export misreports; see the note on the search-field
// instance below.
//
// The panel is a SIBLING of the field in a column, not a child of it: the field
// clips its content (`ClipRRect`) and the panel hangs below that boundary, so a
// child would be clipped away entirely. The column's gap is `popoverTopOffset`,
// which is exactly what that field is — the reflected
// `popoverStyle.placementOffset`, the trigger↔panel distance — so the two
// children are spaced by the widget's own value rather than by a number chosen
// here. Same arrangement `Select` uses for the same widget shape.
//
// Its box chrome comes from `popoverStyle.panelStyle` (padding / radius /
// border / fill / the two shadow layers) because that is the forward the widget
// makes: `Popover` renders this content inside `Popup`'s panel. `popupBorderRadius`
// is not a second radius to read — the resolver reflects it INTO
// `popoverStyle.panelStyle.borderRadius`, and its default is the same
// `radius8` that slot already carries.
//
// `popupMaxWidth` / `popupMaxHeight` ARE written now, and the earlier reason for
// leaving them alone is worth keeping because it was right at the time: they are
// `max` constraint slots on an auto-layout frame, and this repo had one live
// example of a frame property Figma refuses where a double accepted it
// (`constraints` on an INSTANCE, which failed the TimePicker entry twice), so
// they were not written blind. What changed is that both doubles now carry
// `maxWidth` / `maxHeight` with Figma's own `null` default and the runtime
// harness validates the write, so a refusal names this builder in CI instead
// of leaving a half-drawn PhoneInput on a page. A capped panel is also what
// the widget is: the list scrolls inside `ConstrainedBox(maxHeight:)`, and an
// uncapped panel would grow with however many rows a designer pastes in.
//
// Hidden, with the `Dropdown shown` BOOLEAN over it — the panel is portal-mounted
// when the selector is tapped and every variant here is a resting state. A
// BOOLEAN and not a fourth variant axis: the panel is a disjoint node that
// changes nothing about the field, so an axis would redraw all eight field
// combinations a second time to toggle one sibling's visibility.
//
// The selector trigger is deliberately not a `Button`: the widget builds it
// from `MouseRegion` + `GestureDetector` + `Container`, and its content (flag +
// dial code + chevron) is drawn from PhoneInput's own `flagSize` /
// `dialCodeTextStyle` / `chevronColor` fields.

// The country flag's aspect ratio, `phone_input.dart`'s own
// `_kFlagAspectRatio = 4 / 3` (line 9) — the widget states outright that it is
// "the intrinsic aspect ratio of the flag artwork", not a design token, and
// sizes the flag `ImageTheme(width: flagSize * _kFlagAspectRatio, height:
// flagSize)`. Only the HEIGHT is a token (`flagSize`), which is why the box
// below binds that axis and leaves the width as plain geometry.
const kFlagAspectRatio = 4 / 3;

// The flag itself is an IMAGE — `country_flags.CountryFlag.fromCountryCode`
// renders the flag-icons SVG for the caller's country, and this plugin vendors
// only the Lucide set (`src/data/icons.json`), so there is no US flag to draw.
// What IS knowable is the region it occupies, and drawing that region is what
// the canvas was missing: the selector showed `+1` and a chevron with nothing in
// front of them, so a designer read the trigger as two children when the widget
// renders three.
//
// The stand-in fill is the same neutral `primitives-behaviour.ts` paints its
// `ThemeController` palette square with, and for the same reason: the colour
// belongs to the PLACEHOLDER, not to the component. `CorePhoneInputStyle` states
// no flag colour because a flag's colours come from the country, exactly as that
// palette's come from the app's `CoreThemeOption`.
function flagPlaceholderFill(lk: VarLookup): SolidPaint[] {
  // The widget renders an image whose colours come from the country, so neither it
  // nor PhoneInput's Core fields state a flag colour — only the region's height is a
  // token, and that one is bound where the box is built.
  // g7-preview-only: fill of the stand-in box for the country flag artwork
  return [solid(lk.sem('surface-container-high'))];
}

// Three rows of `CoreCountry.all` — display copy, the same convention the
// FileInput hint and the ValidatorHint message follow. `selected` is the one the
// field currently shows — `CorePhoneInputContract.defaultInitialCountry`
// (South Korea, `+82`, #6471), what a field that names no country starts on —
// and its row is drawn first. That one is what `_CountryPickerItem` fills with
// `hoverColor`; the widget paints the selected row and a hovered row with the
// same token (`widget.selected || _hovered ? hoverColor : transparent`), so one
// filled row shows both states at once rather than claiming a second one.
// The number field's hint and sample — the docs example's own copy, and a
// number in the `+82` country the dropdown shows selected.
const kPhoneInputNumberPlaceholder = '전화번호를 입력해 주세요';
const kPhoneInputNumberValue = '010-1234-5678';
// The dial code of `CorePhoneInputContract.defaultInitialCountry` — what the
// trigger shows on a field that names no country.
const kPhoneInputDefaultDialCode = '+82';
// `localizations.searchPlaceholderCountry` (ko).
const kPhoneInputSearchPlaceholder = '국가 검색';

const kPhoneInputCountries: readonly {
  name: string;
  dialCode: string;
  selected: boolean;
}[] = [
  { name: '대한민국', dialCode: kPhoneInputDefaultDialCode, selected: true },
  { name: '미국', dialCode: '+1', selected: false },
  { name: '영국', dialCode: '+44', selected: false },
];

// A field the Dart contract added with the redesign: read through `optField`
// so the builder compiles against the export that carries it, and a stale
// `components.json` fails loudly instead of painting the old value.
function requiredPhoneField<T>(entry: object, key: string): T {
  const v = optField<T>(entry, key);
  if (v == null) {
    throw new Error(
      `phone_input.${key} is missing from components.json — re-run ` +
        '`export_figma_components.dart` so the builder reads the redesigned Core defaults.',
    );
  }
  return v;
}

// The pose a field rests in — enabled, not hovered, not focused. The member
// carrying it leads its set (`rowSet`), because the first member of an
// auto-layout set is what a freshly placed instance holds.
const kRestingFieldPose = { Enabled: 'true', Hover: 'false', Focus: 'false' } as const;

function buildPhoneInput(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = PHONE_INPUT.fields;
  const flagRadius = f.flagBorderRadius;
  const separatorHeight = f.separatorHeight;
  const disabledBackground = f.disabledBackgroundColor;
  const disabledBorder = f.disabledBorderColor;
  const disabledPlaceholder = f.disabledPlaceholderColor;
  const listPad = f.dropdownListPadding;
  const rowRadius = f.dropdownItemBorderRadius;
  const checkIcon = f.dropdownCheckIconStyle;
  const searchIcon = f.searchIconStyle;
  const dialCode = textStyleData(f.dialCodeTextStyle);
  // The four schema axes first (`phone_input.axes` promotes only `enabled`), then
  // this side's two poses in `kAxisOrder`'s own order — `Hover` before `Focus`,
  // which is why the member name reads that way rather than the other. Each
  // pose lists its resting value FIRST: the first member is the set's default
  // (`rowSet`'s lead), and a field nobody points at or types into is neither
  // hovered nor focused. Listing `true` first made every new instance arrive
  // hovered and focused (#6475).
  const combos = enumerateAxisCombos([
    ...axisSpecsOf(PHONE_INPUT.axes),
    { axis: 'Hover' as const, values: ['false', 'true'] },
    { axis: 'Focus' as const, values: ['false', 'true'] },
  ]);
  const mount = mountSet(page, 'PhoneInput', combos, {
    adoptLooseAs: 'Enabled=true, Hover=false, Focus=false',
  });
  const panels: FrameNode[] = [];
  for (const comboName of combos) {
    const combo = parseVariantKey(comboName);
    const s = {
      disabled: combo['Enabled'] === 'false',
      focus: combo['Focus'] === 'true',
      hover: combo['Hover'] === 'true',
    };
    // The root is the `Popover` — a column holding its `trigger:` (the bordered
    // field) and its `content:` (the country panel), spaced by the trigger↔panel
    // offset. It paints nothing itself: the boundary belongs to the field below.
    const c = mount.getOrCreate(comboName);
    c.layoutMode = 'VERTICAL';
    c.primaryAxisSizingMode = 'AUTO';
    c.counterAxisSizingMode = 'AUTO';
    c.counterAxisAlignItems = 'MIN';
    c.fills = [];
    c.setBoundVariable('itemSpacing', lk.space(dimVal(f.popoverTopOffset)));
    // `maxWidth` is not this number under another name: the widget spends it on the
    // inner number field (`ConstrainedBox(maxWidth:)` around that `TextField`), and
    // the field is `Flexible` inside whatever the caller gives the row. Reading it
    // here would put a field-level cap on the whole trigger.
    // g7-preview-only: PhoneInput demo width, the root states none
    lockWidth(c, 280);

    // `Container(decoration: border/bg/radius) > ClipRRect > Row(stretch)` —
    // the widget's `trigger:`. The chrome is this frame's, not the root's.
    const fieldRow = figma.createFrame();
    fieldRow.name = 'field';
    fieldRow.layoutMode = 'HORIZONTAL';
    fieldRow.primaryAxisSizingMode = 'FIXED';
    fieldRow.counterAxisSizingMode = 'AUTO';
    fieldRow.counterAxisAlignItems = 'CENTER';
    // No row spacing: the widget's `Row` has none — the `Divider` below is what
    // separates the two halves, and a gap on either side of it would be chrome
    // the component does not have.
    fieldRow.itemSpacing = 0;
    bindRadiusN(fieldRow, lk, f.borderRadius.topLeft);
    // The bordered field is a content surface on both platforms, and states no
    // cast of its own, so it also takes the one a style contributes.
    applySurfaceMaterial(fieldRow, lk, colorData(s.disabled ? disabledBackground : f.backgroundColor), 'content', {
      radius: f.borderRadius.topLeft,
    });
    addControlShadow(fieldRow, lk);
    // `disabled > focus > hover > rest` — the widget's own ladder: focus outranks
    // the pointer, and a disabled field takes no hover step. The `Hover` pose is
    // this set's own axis, so `Hover=true` is where `hoverBorderColor` lands.
    const fieldBorder = s.disabled
      ? disabledBorder
      : s.focus
        ? f.focusBorderColor
        : s.hover
          ? f.hoverBorderColor
          : f.borderColor;
    borderData(fieldRow, lk, colorData(fieldBorder), dimVal(f.borderWidth) || 1);
    c.appendChild(fieldRow);
    fieldRow.layoutSizingHorizontal = 'FILL';
    // `SizedBox(height: resolved.height)` around the row, and the reason the
    // widget's `Row(crossAxisAlignment: .stretch)` means anything: without a
    // definite height there is nothing for a child to stretch TO. It comes
    // before any child asks to fill that axis — Figma rejects
    // `layoutSizingVertical = 'FILL'` under a parent that hugs, and nothing
    // rolls that throw back — the entry is reported as failed and a half-drawn
    // PhoneInput is left on the page.
    const fieldHeight = dimVal(f.height);
    fieldRow.counterAxisSizingMode = 'FIXED';
    fieldRow.resize(fieldRow.width, fieldHeight);
    // The box is the lg control row (`CorePhoneInputStyle.defaultHeight`), the
    // row of the text field beside it — the row a density moves. A document
    // that predates the density rows keeps the size step.
    const fieldHeightVar = lk.controlHeightOrNull(fieldHeight) ?? lk.sizeOrNull(fieldHeight);
    if (fieldHeightVar) fieldRow.setBoundVariable('height', fieldHeightVar);
    // `ClipRRect` inside the bordered `Container` — the widget clips its content
    // so the trigger's hover fill follows the border's inner curve instead of
    // bleeding a square corner over it. Same statement here, and it is what
    // makes a full-height hover surface safe to draw at all. On this frame and
    // not the root, because the panel below hangs outside that boundary and a
    // clip on the root would erase it.
    fieldRow.clipsContent = true;

    const selPad = f.selectorPadding;
    const code = figma.createFrame();
    code.name = 'code';
    code.layoutMode = 'HORIZONTAL';
    code.primaryAxisSizingMode = 'AUTO';
    code.counterAxisSizingMode = 'AUTO';
    code.counterAxisAlignItems = 'CENTER';
    // `Padding(padding: resolved.selectorPadding)` — start 14 / end 10 by
    // reading order, the inset as stated (`bindPad` resolves the logical sides).
    bindPad(code, lk, selPad);
    code.setBoundVariable('itemSpacing', lk.space(dimVal(f.flagGapStyle.size)));
    // No hover fill on the trigger: the box's own border carries the pointer.
    fillData(code, lk, null);
    // `CountryFlag.fromCountryCode(country.code, ImageTheme(width: flagSize *
    // 4/3, height: flagSize))` — the first of the trigger's three children.
    const flag = figma.createRectangle();
    flag.name = 'flag';
    bindAxisSize(flag, lk, {
      width: dimVal(f.flagSize) * kFlagAspectRatio,
      height: f.flagSize,
      bind: 'height',
    });
    flag.fills = flagPlaceholderFill(lk);
    // `ClipRRect(borderRadius: resolved.flagBorderRadius)` around the flag.
    bindRadiusN(flag, lk, flagRadius.topLeft);
    code.appendChild(flag);
    code.appendChild(
      makeLabel(
        kPhoneInputDefaultDialCode,
        lk,
        s.disabled
          ? typographyColorOpts(lk, dialCode, colorData(f.disabledDialCodeColor))
          : textLabelOpts(lk, dialCode),
      ),
    );
    code.appendChild(
      makeIcon(
        'chevron-down',
        lk,
        glyphOpts(
          lk,
          colorData(s.disabled ? f.disabledChevronColor : f.chevronColor),
          f.chevronIconStyle.size,
        ),
      ),
    );
    fieldRow.appendChild(code);
    // `Row(crossAxisAlignment: .stretch)` — the trigger is a child of that row,
    // so its `Container(decoration: color: background)` spans the field's full
    // height and the hover surface reads as a filled half of the field. Hugging
    // instead left the fill wrapped tight around the text, floating in the
    // middle of a 40px field with a gap above and below it.
    //
    // After the append, not before: a layout-sizing write needs the parent it is
    // sizing against, and Figma rejects it on a node that has none — which the
    // runtime harness reports as this builder throwing, and a real run reports
    // as a failed entry with a half-drawn PhoneInput left on the page.
    code.layoutSizingVertical = 'FILL';

    // A hairline shorter than the row, centred in it: `Center(child: SizedBox(
    // height: resolved.separatorHeight, child: Divider(vertical)))`. Sized mode
    // of `hostedDivider` — the rule has a length of its own here — and the
    // row's `CENTER` counter-axis alignment is the centring.
    const separator = hostedDivider(page, lk, fieldRow, {
      vertical: true,
      color: colorData(f.separatorColor),
      size: { length: separatorHeight, thickness: f.borderWidth },
    });
    separator.name = 'separator';

    const inPad = f.inputFieldPadding;
    const box = figma.createFrame();
    box.name = 'input';
    // A `Padding`, not a box: it paints nothing. `createFrame` starts white, and
    // left that way the wrapper laid an opaque fill over the row's own surface
    // (and over its material) on every member — on the disabled one a white
    // block inside the disabled container.
    box.fills = [];
    box.layoutMode = 'HORIZONTAL';
    box.primaryAxisSizingMode = 'AUTO';
    box.counterAxisSizingMode = 'AUTO';
    box.counterAxisAlignItems = 'CENTER';
    // `Padding(padding: resolved.inputFieldPadding)` — the wrapper the widget
    // puts between the row and the field, not chrome of its own.
    bindPad(box, lk, { start: inPad.start, end: inPad.end, t: inPad.t, b: inPad.b });
    const field = instanceOf(
      page,
      'TextField',
      bestVariantName(page, 'TextField', { Variant: 'Default', Size: 'md' }),
    );
    field.name = 'number field';
    // `hintText` — the number field's own hint. Without it the instance kept
    // TextField's email copy and value, which read as an email field.
    setInstanceTextNamed(field, 'Placeholder', kPhoneInputNumberPlaceholder);
    setInstanceTextNamed(field, 'Value text', kPhoneInputNumberValue);
    box.appendChild(field);
    fieldRow.appendChild(box);
    box.layoutSizingHorizontal = 'FILL';
    field.layoutSizingHorizontal = 'FILL';
    // The composed field is CHROMELESS — the outer `fieldRow` above owns the
    // single visible boundary, and the widget says so by handing this `TextField`
    // `chromelessFieldStyle` (transparent fill and border, zero border width,
    // zero padding, transparent focus ring).
    //
    // Without this the instance arrived with `TextField`'s own border and fill,
    // and the canvas drew a field inside a field — a rounded box with its own
    // outline sitting in the right half of the bordered row, which is exactly
    // what the side-by-side report showed. It is not a `Variant` on `TextField`
    // either: chromelessness here is PhoneInput's statement about its own
    // composition, not one of the field's own looks.
    //
    // The resolved default now arrives through the public nested style slot.
    // Its chromeless values are still the default; app-supplied overrides are
    // applied by the runtime resolver and are not represented by this default
    // component preview.
    suppressFieldChrome(field, lk, f.numberFieldStyle);
    // The number reads at the dial code's size: `defaultNumberFieldStyle` lays
    // `baseTextStyle: bodyLarge` over the chromeless partial, and both widgets
    // draw the value and the hint in it. The instance arrives in `TextField`'s
    // own `md` row typography (bodyMedium) until this reaches it. Typography
    // only — the colours stay the field's, and the placeholder is repainted in
    // PhoneInput's own tone just below.
    applyForwardedFieldText(field, lk, f.numberFieldStyle.baseTextStyle);
    // `ConstrainedBox(constraints: BoxConstraints(maxWidth: resolved.maxWidth))`
    // around this field, and only this field. The note above (on the root's
    // preview width) is right that the cap is not the trigger's — it belongs
    // here, on the `Padding` the ConstrainedBox wraps, which is this frame.
    box.maxWidth = dimVal(f.maxWidth);
    // The hint's ink. The instance arrives with `TextField`'s own placeholder
    // colour, and PhoneInput states its own — one field for BOTH placeholders,
    // this one and the country search below, which is why it is applied twice.
    paintPlaceholder(field, lk, colorData(s.disabled ? disabledPlaceholder : f.placeholderColor));

    // ─── content: _CountryPickerPopup(…) ─────────────────────────────────────
    //
    // The panel box is `Popup`'s chrome, forwarded through
    // `popoverStyle.panelStyle` (see the header); everything inside it is
    // PhoneInput's own drawing.
    const panelStyle = f.popoverStyle.panelStyle;
    const itemPad = f.dropdownItemPadding;
    const dropdown = panel('dropdown', 'VERTICAL', lk, {
      pl: panelStyle.padding.l,
      pr: panelStyle.padding.r,
      pt: panelStyle.padding.t,
      pb: panelStyle.padding.b,
    });
    bindRadiusN(dropdown, lk, panelStyle.borderRadius.topLeft);
    // The composed `Popup`'s box (`Popover` → `Popup` on both platforms), a
    // functional surface that takes the rim — drawn here, so it wears the
    // material here.
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
    // Two layers, tinted by the panel's own `shadowBaseColor` — a dropdown that
    // does not float reads as flush with whatever is behind it.
    setShadow(dropdown, panelStyle.boxShadow, lk, colorData(panelStyle.shadowBaseColor));
    // `ConstrainedBox(constraints: BoxConstraints(maxWidth:, maxHeight:))` around
    // the scrollable list.
    dropdown.maxWidth = dimVal(f.popupMaxWidth);
    dropdown.maxHeight = dimVal(f.popupMaxHeight);
    c.appendChild(dropdown);
    dropdown.layoutSizingHorizontal = 'FILL';
    panels.push(dropdown);

    // `TextField(variant: .plain, prefix: Icon(search), textFieldStyle:
    // searchFieldStyle)` — the item picker's search row: the field's own
    // `padding` insets the glyph and the bare field together, the glyph's gap to
    // the field is the field's row spacing, and the divider below closes it.
    const searchPad = requiredPhoneField<{ l: Dim; r: Dim; t: Dim; b: Dim }>(
      f.searchFieldStyle,
      'padding',
    );
    const searchWrap = panel('search', 'HORIZONTAL', lk, {
      pl: searchPad.l,
      pr: searchPad.r,
      gap: COMPONENTS.text_field.fields.rowSpacing,
    });
    searchWrap.counterAxisAlignItems = 'CENTER';
    dropdown.appendChild(searchWrap);
    searchWrap.layoutSizingHorizontal = 'FILL';
    searchWrap.appendChild(
      makeIcon(
        'search',
        lk,
        glyphOpts(lk, colorData(searchIcon.color), searchIcon.size, 'size'),
      ),
    );
    const search = instanceOf(
      page,
      'TextField',
      bestVariantName(page, 'TextField', { Variant: 'plain', Size: 'md' }),
    );
    search.name = 'search field';
    // `localizations.searchPlaceholderCountry` — the code's own hint.
    setInstanceTextNamed(search, 'Placeholder', kPhoneInputSearchPlaceholder);
    searchWrap.appendChild(search);
    search.layoutSizingHorizontal = 'FILL';
    // The hint is left at `TextField`'s own property default, like FileInput's
    // browse `Button`: it is `localizations.searchPlaceholderCountry` in code,
    // and pre-setting an instance's TEXT property needs
    // `InstanceNode.setProperties`, whose effect the runtime harness cannot
    // observe. A designer sets it from the instance panel, where the composed
    // field's own `Placeholder` property already is.
    //
    // The second of the two placeholders `placeholderColor` states. The Web
    // resolver spells that out — one shared `::placeholder` rule for "number +
    // search input" — so recolouring one and not the other would be half a field.
    paintPlaceholder(search, lk, colorData(f.placeholderColor));

    // `Divider(dividerStyle: resolved.dividerStyle)` between the search field and
    // the list — horizontal here, unlike the vertical one splitting the field
    // above. Its colour is `CoreDividerStyle`'s own default, which is the token
    // `separatorColor` already carries, so the instance needs no override.
    const listDivider = hostedDivider(page, lk, dropdown);
    listDivider.name = 'divider';

    // `ListView.builder(padding: resolved.dropdownListPadding)` — the list's own
    // inset; the panel states none, so the search row and the divider run edge
    // to edge.
    const list = panel('list', 'VERTICAL', lk, {
      pl: listPad.l,
      pr: listPad.r,
      pt: listPad.t,
      pb: listPad.b,
    });
    dropdown.appendChild(list);
    list.layoutSizingHorizontal = 'FILL';

    // `ListView.builder(itemBuilder: _CountryPickerItem)` — three rows of it.
    for (const [index, country] of kPhoneInputCountries.entries()) {
      const item = panel('country', 'HORIZONTAL', lk, {
        pl: itemPad.l,
        pr: itemPad.r,
        pt: itemPad.t,
        pb: itemPad.b,
        gap: f.dropdownItemGapStyle.size,
      });
      item.counterAxisAlignItems = 'CENTER';
      bindRadiusN(item, lk, rowRadius.topLeft);
      // `DecoratedBox(color: _hovered ? hoverColor : transparent)` — the
      // filled row is the one under the pointer (the first, shown hovered);
      // the selected row carries the check alone.
      fillData(item, lk, index === 0 && !country.selected ? colorData(f.hoverColor) : null);
      const itemFlag = figma.createRectangle();
      itemFlag.name = 'flag';
      // `ImageTheme(width: dropdownFlagSize * 4/3, height: dropdownFlagSize)` —
      // the row's own flag size field, which is not the trigger's `flagSize`
      // even where the two values agree.
      bindAxisSize(itemFlag, lk, {
        width: dimVal(f.dropdownFlagSize) * kFlagAspectRatio,
        height: f.dropdownFlagSize,
        bind: 'height',
      });
      itemFlag.fills = flagPlaceholderFill(lk);
      bindRadiusN(itemFlag, lk, flagRadius.topLeft);
      item.appendChild(itemFlag);
      // `Expanded(Text(country.name, style: bodyTextStyle))` — the field whose
      // only consumer is this row. No colour is passed: `defaultBodyTextStyle`
      // is `CoreTextStyle.token(bodySmall)` with none, and the resolver emits it
      // as `.toValue(theme:)` with no `color:` argument, so the words take the
      // ambient text colour. `labelColor`'s own no-colour fallback is what that
      // is on this canvas — reaching for a *named* field with the same value
      // (`chevronColor` is also `on-surface`) would attribute the row's colour to
      // the selector's glyph.
      const name = makeLabel(
        country.name,
        lk,
        textLabelOpts(lk, textStyleData(f.bodyTextStyle)),
      );
      item.appendChild(name);
      // `Gap(gapStyle: resolved.countryGapStyle)` between the name and the dial
      // code. A node, because the row already carries `dropdownItemGapStyle` as
      // its own spacing and a frame has one — two different stated gaps in one
      // row means the second one is a child (the reason `display-data.ts#gapSpacer`
      // exists).
      //
      // The header note above called this field the selector↔input gap. It is
      // not: the only consumer on either platform is this row, between these two
      // words. A field named for the wrong place is worse than an unread one —
      // the name invites the next reader to wire it somewhere the code never
      // spends it.
      const countryGap = figma.createFrame();
      countryGap.name = 'country gap';
      countryGap.layoutMode = 'NONE';
      countryGap.fills = [];
      bindSize(countryGap, lk, f.countryGapStyle.size, f.countryGapStyle.size);
      item.appendChild(countryGap);
      item.appendChild(
        makeLabel(
          country.dialCode,
          lk,
          textLabelOpts(lk, textStyleData(f.dropdownDialCodeTextStyle)),
        ),
      );
      // `if (selected) Icon(LucideIcons.check, iconStyle:
      // resolved.dropdownCheckIconStyle)` — the selection mark, in primary.
      if (country.selected) {
        item.appendChild(
          makeIcon(
            'check',
            lk,
            glyphOpts(lk, colorData(checkIcon.color), checkIcon.size, 'size'),
          ),
        );
      }
      list.appendChild(item);
      item.layoutSizingHorizontal = 'FILL';
      // After the append and after the row fills its parent — `Expanded` on the
      // name is what pushes the dial code to the far end.
      name.layoutSizingHorizontal = 'FILL';
    }
    // Hidden only now, once the rows have been laid out at the panel's width. A
    // hidden node is not laid out: hiding the panel before its rows were added
    // left each country name at the width of an empty row, wrapped one letter
    // per line, and the rows stayed 250+ tall when the panel was shown.
    dropdown.visible = false;

    // `Popover(trigger: decorated, content: _CountryPickerPopup(…))` — the
    // wrapper the widget puts around everything above. ABSOLUTE so the column it
    // cannot be the parent of is not reflowed by it either.
    const popover = instanceOf(page, 'Popover');
    popover.name = 'Popover';
    pinAbsolute(c, popover, 0, 0, { horizontal: 'MIN', vertical: 'MIN' }).visible = false;
  }
  const set = mount.finish();
  // One BOOLEAN on the set, shared by every variant — the panel is the same
  // portal-mounted overlay in all eight resting states.
  const dropdownProp = defineProp(set, 'Dropdown shown', 'BOOLEAN', false);
  for (const p of panels) bindVisibleProp(p, dropdownProp);
  // The resting field leads — an existing set keeps its members where they sat,
  // so the combo order alone would leave its corner on the old first member.
  rowSet(set, kRestingFieldPose);
  return set;
}

// ─── FormattedInput (masked placeholder) ─────────────────────────────────────

// Data-driven from coui_core FORMATTED_INPUT.fields: backgroundColor /
// borderColor / borderRadius / borderWidth / padding for the container.
//
// The widget renders ONE continuous composed `TextField` — `Container(padding,
// bg, border, radius) > Row[ ?leading, Expanded(TextField(textFieldStyle:
// segmentInputStyle, hintText: mask)), ?trailing ]` (DDR-01; the per-segment
// boxes are the mask engine's measurements, not separate input nodes). So the
// masked line is a `TextField` instance here, not a text node painted to look
// like one — a redrawn copy would keep showing the old `TextField` forever,
// because the content-hash skip in `generate.ts` never rebuilds a parent whose
// own recipe is unchanged.
//
// That field is chromeless in code — `segmentInputStyle` is a nested
// `CoreTextFieldStyle` carrying `borderWidth: 0` and a transparent
// background/border, i.e. this container owns the visible boundary — and that
// forward is not expressed on the canvas; see the chromeless note at the top of
// this file for why, and for what it looks like instead.
//
// There is no separator style to read: under DDR-01 the mask's static
// separators are characters inside the one composed field's `hintText`, styled
// by `segmentInputStyle.placeholderStyle`, which states no default of its own
// and reads the composed field's per-size base text style — the canvas does
// show it. `CoreFormattedInputStyle` states no separator colour or role of
// its own, so nothing here is skipped.
//
// `Focus` and `Hover` axes mirror the widget's precedence: disabled wins,
// then focus, then hover, then rest. The
// `focusOutlineStyle` half of that state is a ring drawn outside the container
// by a separate node this preview does not have, so it is not represented.
//
// #4037 (C4b) — static→variant-set promotion by ADOPTION. `formatted_input.axes`
// promotes ONLY `enabled`; its `CoreFormattedInputAutofillHint` enum sits in
// `axes.other`, which is recorded but deliberately NOT promoted (the seed spec's
// §4-2 boundary — `axisSpecsOf` omits it by construction). With this side's
// `Hover` and `Focus` poses appended the enumeration is 2×2×2 = 8. The loose
// COMPONENT this builder used to mint is adopted as the enabled resting pose;
// the previous four variant members are renamed onto `Hover=false` so their
// identities survive. Disabled uses its explicit Core colour fields.
//
// `leading` / `trailing` (`W?`) are the two ends of that `Row`:
// `Row[?leading, Expanded(field), ?trailing]`, each omitted when null. Drawing
// nothing for them left the slots unreachable — a hidden layer inside a main
// component cannot be revealed from an instance unless a boolean property
// governs it, so a `FormattedInput` could never grow an affix at all. Each is a
// hidden hug frame holding an `Icon` instance: the frame carries the BOOLEAN, the
// instance carries the INSTANCE_SWAP that re-points the slot at any component.
// Hidden by default, which is the widget's own default (`null`) and leaves the
// rendered preview unchanged.
//
// The two glyphs are display copy, not chrome — the same convention
// `_kValidatorHintIcon` follows. `calendar` and `circle-check` name what a masked
// field's ends plausibly hold (the `date` factory's mask on one side, a
// validation mark on the other); a caller swaps both. `CoreFormattedInputStyle`
// has no affix icon field at all (#3754 OQ-2), but that does not leave the size
// open: the widget renders both ends as handed (`Row[?leading, Expanded(field),
// ?trailing]` inside the composed `OutlinedContainer` on Flutter, the root
// `<div>`'s children on Web), and nothing on that path mounts an `IconTheme`, so
// an `Icon` passed there draws at the app root's ambient icon size. That is the
// size read here. Their colour is `labelColor`'s shared `on-surface` fallback.
const kFormattedInputLeadingGlyph = 'calendar';
const kFormattedInputTrailingGlyph = 'circle-check';
const kFormattedInputAffixIconSize = ICON.constants.ambientSize;

function buildFormattedInput(page: PageNode, lk: VarLookup): ComponentSetNode {
  const pad = FORMATTED_INPUT.fields.padding;
  const f = FORMATTED_INPUT.fields;
  // The four schema axes first (`formatted_input.axes` promotes only `enabled`),
  // then the hover/focus poses — `kAxisOrder` puts poses after the four. Both
  // list the resting value first, so the first member — the set's default — is
  // the field at rest; `Focus` listed `true` first and every new instance
  // arrived focused (#6475).
  const combos = enumerateAxisCombos([
    ...axisSpecsOf(FORMATTED_INPUT.axes),
    { axis: 'Hover' as const, values: ['false', 'true'] },
    { axis: 'Focus' as const, values: ['false', 'true'] },
  ]);
  // The affix glyphs are drawn from their swap defaults, so the properties'
  // first binds leave them at their own size (see `IconOpts.fromVariant`).
  const leadingSwap = iconSwapDefault(page, 'FormattedInput', 'Leading', iconMainId(page));
  const trailingSwap = iconSwapDefault(page, 'FormattedInput', 'Trailing', iconMainId(page));
  const mount = mountSet(page, 'FormattedInput', combos, {
    adoptLooseAs: 'Enabled=true, Hover=false, Focus=false',
  });
  // Collected for the property pass — the owner is only the set after finish().
  const leadingHolders: FrameNode[] = [];
  const leadingIcons: InstanceNode[] = [];
  const trailingHolders: FrameNode[] = [];
  const trailingIcons: InstanceNode[] = [];
  for (const comboName of combos) {
    const combo = parseVariantKey(comboName);
    const focus = combo['Focus'] === 'true';
    const hover = combo['Hover'] === 'true';
    // `Enabled` is a schema axis here, so the disabled half is a real half
    // of this set rather than a pose someone remembers to draw.
    const enabled = combo['Enabled'] !== 'false';
    const c = mount.getOrCreate(comboName);
    c.layoutMode = 'HORIZONTAL';
    c.primaryAxisSizingMode = 'AUTO';
    c.counterAxisSizingMode = 'AUTO';
    c.counterAxisAlignItems = 'CENTER';
    bindPad(c, lk, { l: pad.l, r: pad.r, t: pad.t, b: pad.b });
    bindRadiusN(c, lk, f.borderRadius.topLeft);
    // `Row(spacing: resolved.contentSpacing)` — the gap between the affixes and
    // the field (hidden affixes take no space).
    bindSpaceField(c, 'itemSpacing', lk, dimVal(f.contentSpacing));
    // Disabled says so in its own two tokens, not by dimming the enabled
    // pair — an alpha is not a forced value in a colour-forcing mode, so a
    // field dimmed that way keeps the enabled palette and reads as enabled
    // there. Disabled also outranks focus: a field that cannot be edited
    // should not claim the focus ring, and the two can coexist.
    fillData(
      c,
      lk,
      colorData(enabled ? f.backgroundColor : f.disabledBackgroundColor),
    );
    borderData(
      c,
      lk,
      colorData(
        !enabled
          ? f.disabledBorderColor
          : focus
            ? f.focusBorderColor
            : hover
              ? f.hoverBorderColor
              : f.borderColor,
      ),
      dimVal(f.borderWidth) || 1,
    );
    // The composed field keeps its own lg row height, so a stroke counted into
    // the hug adds its two edges on top of the 48 row (the box read 50). The
    // border is drawn inside the row, never added to it.
    c.strokesIncludedInLayout = false;
    // The widget states no width — FormattedInput's seven Core fields are box chrome
    // plus the nested segment style — so how wide a masked field reads is ours.
    // g7-preview-only: FormattedInput demo width, no width field in the code
    lockWidth(c, 240);
    // The box is the lg control row (`CoreFormattedInputStyle.defaultHeight`), the
    // row of the text field beside it — the row a density moves. A document that
    // predates the density rows keeps the size step.
    const rowHeight = dimVal(f.height);
        c.resize(c.width, rowHeight);
    const rowHeightVar = lk.controlHeightOrNull(rowHeight) ?? lk.sizeOrNull(rowHeight);
    if (rowHeightVar) c.setBoundVariable('minHeight', rowHeightVar);
    const leading = autoFrame('leading', 'HORIZONTAL');
    leading.counterAxisAlignItems = 'CENTER';
    c.appendChild(leading);
    const leadingIcon = makeIcon(kFormattedInputLeadingGlyph, lk, {
      ...glyphOpts(lk, null, kFormattedInputAffixIconSize, 'size'),
      fromVariant: leadingSwap.variant,
    });
    leading.appendChild(leadingIcon);
    leading.visible = false;
    leadingHolders.push(leading);
    leadingIcons.push(leadingIcon);

    // `TextField(variant: plain, size: lg)` — `CoreFormattedInputStyle.
    // defaultSegmentInputVariant` / `…Size`: the bare field on the lg row. The
    // disabled member is the field's own (`enabled: widget.enabled`).
    const field = instanceOf(
      page,
      'TextField',
      bestVariantName(page, 'TextField', {
        Variant: 'plain',
        Size: 'lg',
        State: enabled ? 'enabled' : 'disabled',
      }),
    );
    field.name = 'masked field';
    c.appendChild(field);
    field.layoutSizingHorizontal = 'FILL';
    // `segmentInputStyle` is chromeless — `borderWidth: 0`, a transparent fill,
    // `padding: .zero` — because FormattedInput draws the box and the field inside
    // it draws none. The `plain` member already draws no box; this clears what it
    // keeps (the disabled fill) and applies the forwarded inset, through the same
    // forwarder `ObjectInput` and `ChipInput` use.
    const segment = f.segmentInputStyle;
    suppressFieldChrome(field, lk, segment);
    // The value sits on the code grid, the mask pattern is set in the body face —
    // see `applyForwardedFieldText`.
    applyForwardedFieldText(
      field,
      lk,
      segment.valueStyle,
      (segment as { placeholderStyle?: Parameters<typeof textStyleData>[0] }).placeholderStyle,
    );
    // The parent owns its disabled ink; the child TextField's own disabled
    // token only happens to match the default. Explicit nested text colors
    // still win, just as in both platform resolvers.
    const valueText = textStyleData(segment.valueStyle);
    const placeholderText = textStyleData(
      (segment as { placeholderStyle?: Parameters<typeof textStyleData>[0] }).placeholderStyle,
    );
    const disabledInk = enabled ? null : colorData(f.disabledForegroundColor);
    const placeholderInk = placeholderText.color ?? disabledInk;
    const valueInk = valueText.color ?? disabledInk;
    if (placeholderInk) paintPlaceholder(field, lk, placeholderInk);
    if (valueInk) {
      applyInstanceTextStyle(namedDescendant(field, kFieldValueName), lk, {
        ...valueText,
        color: valueInk,
      });
    }
    // The focus pose stands the field's caret: the composed field is the enabled
    // member (the box above owns the boundary), and its own `caret` node — width,
    // radius and `cursorColor` from the same `cursor*` fields `segmentInputStyle`
    // carries — is hidden on every member but `focus`. A disabled field has none
    // (`showCursor` is `!readOnly`).
    if (focus && enabled) revealFieldCaret(field);

    const trailing = autoFrame('trailing', 'HORIZONTAL');
    trailing.counterAxisAlignItems = 'CENTER';
    c.appendChild(trailing);
    const trailingIcon = makeIcon(kFormattedInputTrailingGlyph, lk, {
      ...glyphOpts(lk, null, kFormattedInputAffixIconSize, 'size'),
      fromVariant: trailingSwap.variant,
    });
    trailing.appendChild(trailingIcon);
    trailing.visible = false;
    trailingHolders.push(trailing);
    trailingIcons.push(trailingIcon);
  }
  const set = mount.finish();
  const leadingProp = defineProp(set, 'Leading', 'INSTANCE_SWAP', leadingSwap.id);
  const leadingShownProp = defineProp(set, 'Leading shown', 'BOOLEAN', false);
  const trailingProp = defineProp(set, 'Trailing', 'INSTANCE_SWAP', trailingSwap.id);
  const trailingShownProp = defineProp(set, 'Trailing shown', 'BOOLEAN', false);
  for (const holder of leadingHolders) bindVisibleProp(holder, leadingShownProp);
  for (const icon of leadingIcons) bindSwapProp(icon, leadingProp);
  for (const holder of trailingHolders) bindVisibleProp(holder, trailingShownProp);
  for (const icon of trailingIcons) bindSwapProp(icon, trailingProp);
  // The resting field leads, for the reason PhoneInput's does.
  rowSet(set, kRestingFieldPose);
  return set;
}

// ─── ValidatorHint (inline helper line) ──────────────────────────────────────

// Data-driven from coui_core VALIDATOR_HINT: the real `variants.
// defaultsByType` dispatch table has 4 entries (error/warning/info/success —
// each carrying only `accentColor`, applied to both the icon and the
// message text), not the 2 the old hand-picked builder assumed. Following
// the real data per the conversion spec (mirrors what Button did for its
// variant set). messageTextStyle drives the label typography;
// iconLabelGapStyle drives the gap. iconStyle.size traces to CoreIconSize ->
// CoreSize, not CoreFontSize — glyphOpts(..., 'size') binds the correct
// scale (#3754 axis fix). Glyphs/messages are display copy, not chrome —
// picked to match ALERT's existing `_kAlertGlyph` convention.
const _kValidatorHintIcon: Record<string, string> = {
  error: 'circle-alert',
  warning: 'triangle-alert',
  info: 'info',
  success: 'circle-check-big',
  // The unfilled twin of `success`'s mark: in a checklist the two sit in
  // one column and only the glyph changes as a rule is met, so the pair has
  // to share a silhouette. `dot` was the nearest thing already in the set
  // and does not — it reads as a bullet, not as an empty checkbox.
  neutral: 'circle-dashed',
};
const _kValidatorHintText: Record<string, string> = {
  error: '비밀번호가 너무 짧아요.',
  warning: '이 항목을 확인해 주세요.',
  info: '선택 사항이에요. 표시 이름을 추가해 보세요.',
  success: '좋아요!',
  neutral: '8자 이상 입력해 주세요.',
};

// `message: W?` becomes a TEXT property — it is the caller's content by
// contract, and the per-type demo copy below is placeholder text either way.
//
// `icon: W?` becomes an INSTANCE_SWAP. The contract derives a default glyph from
// `type` (circle-alert / triangle-alert / info / circle-check-big) and a set
// carries ONE default per property, so an instance of any type opens on the
// `error` glyph until a designer swaps it — the per-type signal survives on the
// four variants themselves, not on a fresh instance. That is a real cost, and
// smaller than the alternative: with no property the glyph this builder happened
// to draw is the only thing the slot can ever hold, while the contract says it
// holds any widget. No BOOLEAN beside it — `icon: null` is not a hidden state,
// the widget falls back to the type's glyph rather than omitting the node.
function buildValidatorHint(page: PageNode, lk: VarLookup): ComponentSetNode {
  const message = textStyleData(VALIDATOR_HINT.fields.messageTextStyle);
  // The widget's `Gap(gapStyle: resolved.iconLabelGapStyle)` between the icon
  // and the message. Figma's equivalent of a `Gap` child is the row's own
  // `itemSpacing`, which `applyPanelCompChrome`'s `gap` option binds — spelled
  // out rather than passed as `{ gap }` shorthand so the composition is
  // legible at this call site (and to anything scanning it) instead of only
  // inside the helper.
  const iconLabelGap = dimVal(VALIDATOR_HINT.fields.iconLabelGapStyle.size);
  const iconSize = VALIDATOR_HINT.fields.iconStyle.size;
  const types = Object.entries(VALIDATOR_HINT.variants.defaultsByType);
  // The glyph is drawn from the `Icon` default, so the bind leaves it at
  // `iconStyle.size` (see `IconOpts.fromVariant`).
  const iconSwap = iconSwapDefault(page, 'ValidatorHint', 'Icon', iconMainId(page));
  const mount = mountSet(page, 'ValidatorHint', types.map(([name]) => `Variant=${name}`));
  const messages: TextNode[] = [];
  const icons: InstanceNode[] = [];
  for (const [name, t] of types) {
    const accent = colorData(t.accentColor);
    const c = mount.getOrCreate(`Variant=${name}`);
    applyPanelCompChrome(c, 'HORIZONTAL', lk, { gap: iconLabelGap });
    c.counterAxisAlignItems = 'CENTER';
    const icon = makeIcon(_kValidatorHintIcon[name] ?? 'info', lk, {
      ...glyphOpts(lk, accent, iconSize, 'size'),
      fromVariant: iconSwap.variant,
    });
    c.appendChild(icon);
    icons.push(icon);
    const text = makeLabel(_kValidatorHintText[name] || '', lk, typographyColorOpts(lk, message, accent));
    c.appendChild(text);
    messages.push(text);
  }
  const set = mount.finish();
  const first = types[0];
  const messageProp = defineProp(
    set,
    'Message',
    'TEXT',
    first ? _kValidatorHintText[first[0]] || '' : '',
  );
  const iconProp = defineProp(set, 'Icon', 'INSTANCE_SWAP', iconSwap.id);
  for (const text of messages) bindTextProp(text, messageProp);
  for (const icon of icons) bindSwapProp(icon, iconProp);
  vStackSet(set);
  return set;
}

// ─── ValidationBadge (valid / invalid pill) ──────────────────────────────────

// Data-driven from coui_core VALIDATION_BADGE: the real `variants.
// defaultsByState` dispatch table has 3 entries (pending/valid/invalid, each
// with backgroundColor/foregroundColor/borderColor) and `sizes.
// defaultsBySize` has 3 entries (extraSmall/small/medium), not the 2-variant
// single-size shape the old hand-picked builder assumed — following the
// real data per the conversion spec (mirrors Badge's Variant×Size gallery).
// foregroundColor colours both the icon and the label. `iconSize` traces to
// the *space* scale (`CoreSpace.spaceN`), not CoreIconSize/CoreFontSize —
// neither of glyphOpts's two sizeScale options ('fontSize' | 'size', see
// helpers.ts) matches, so this local workaround rebinds the glyph's
// fontSize field to the space scale after makeLabel() creates it (kept
// local to this file per the conversion spec, not added to helpers.ts).
//
// ─── Where each surface colour is read from ──────────────────────────────────
//
// `CoreValidationBadgeStyle` states each per-state surface TWICE, on purpose,
// and the export carries both: nine flat slots (`pendingBackgroundColor`,
// `validLabelTextStyle`, `invalidBorderColor`, …) and the `defaultsByState`
// triplet table. They are not two values — the table's entries *reference the
// flat slots' own `default…` consts*, which the Core file states outright
// ("the named const is the single source and the table is the state dispatch
// over it, so there is no second copy of any value"). The nine are the
// overridable slots; the table is the state dispatch.
//
// The resolver reads the slot FIRST and the table as its fallback
// (`merged.pendingBackgroundColor ?? stateDefaults.backgroundColor`, and the
// per-state foreground now rides inside `merged.<state>LabelTextStyle?.color`),
// so that is the order read here: the flat slot, falling back to the table row
// for any state the switch below does not name. Reading only the table left all
// nine slot names unread by any builder — the same value on the canvas, but
// under a name no designer overriding this component would search for, and
// nothing to distinguish "identical by construction" from "never drawn".
//
// The label's colour and the icon's are ONE value, as in the resolver: it
// resolves `foregroundCore` once and hands it to both `Icon(iconStyle:)` and
// `textStyle`'s `color:` argument, where it wins over whatever colour rode in
// through the typography merge. `<state>LabelTextStyle` states colour only
// (its role would freeze the label across all three sizes, which is why Core
// leaves it null and merges this partial ONTO the per-size role) — but it is
// merged rather than colour-picked, so a role or weight added there later wins
// the way `CoreTextStyle.merge` makes it win.
const _kValidationBadgeIcon: Record<string, string> = {
  pending: 'clock',
  valid: 'check',
  invalid: 'x',
};
const _kValidationBadgeLabel: Record<string, string> = {
  pending: '확인 중', valid: '유효', invalid: '유효하지 않음',
};

// The three overridable slots for one state, or `null` for a state name this
// switch does not know — the caller then falls back to that state's
// `defaultsByState` row, so a fourth state added to Core still renders (from
// the table) instead of throwing and leaving a half-drawn badge on the page.
//
// A switch and not a keyed object because `Object.entries` types the state name
// as `string`, and indexing a JSON-inferred literal type with a plain `string`
// is exactly what `data.ts` documents as not type-checking.
function validationBadgeSlots(state: string): {
  background: ReturnType<typeof colorData>;
  border: ReturnType<typeof colorData>;
  label: ReturnType<typeof textStyleData>;
} | null {
  const f = VALIDATION_BADGE.fields;
  switch (state) {
    case 'pending':
      return {
        background: colorData(f.pendingBackgroundColor),
        border: colorData(f.pendingBorderColor),
        label: textStyleData(f.pendingLabelTextStyle),
      };
    case 'valid':
      return {
        background: colorData(f.validBackgroundColor),
        border: colorData(f.validBorderColor),
        label: textStyleData(f.validLabelTextStyle),
      };
    case 'invalid':
      return {
        background: colorData(f.invalidBackgroundColor),
        border: colorData(f.invalidBorderColor),
        label: textStyleData(f.invalidLabelTextStyle),
      };
    default:
      return null;
  }
}

function buildValidationBadge(page: PageNode, lk: VarLookup): ComponentSetNode {
  const states = Object.entries(VALIDATION_BADGE.variants.defaultsByState);
  const sizes = Object.entries(VALIDATION_BADGE.sizes.defaultsBySize);
  const names: string[] = [];
  for (const [sn] of states) {
    for (const [zn] of sizes) names.push(`Variant=${sn}, Size=${zn}`);
  }
  const mount = mountSet(page, 'ValidationBadge', names);
  for (const [sn, s] of states) {
    const slots = validationBadgeSlots(sn);
    // One value for the glyph and the words, resolved once — see the header.
    const fg = slots?.label.color ?? colorData(s.foregroundColor);
    const background = slots?.background ?? colorData(s.backgroundColor);
    const border = slots?.border ?? colorData(s.borderColor);
    for (const [zn, z] of sizes) {
      const comp = mount.getOrCreate(`Variant=${sn}, Size=${zn}`);
      comp.layoutMode = 'HORIZONTAL';
      comp.primaryAxisSizingMode = 'AUTO';
      comp.counterAxisSizingMode = 'AUTO';
      // The widgets state a fixed `height`; the canvas root stays auto-layout and
      // takes the height as its floor (`minHeight`), which is the same box — the
      // content (a 12px glyph beside one 11-13px line) never reaches it, and
      // the vertical padding the step states is 0.
      const height = dimVal(z.height);
      comp.minHeight = height;
      if (lk.sizeOrNull(height)) comp.setBoundVariable('minHeight', lk.size(height));
      comp.primaryAxisAlignItems = 'CENTER';
      comp.counterAxisAlignItems = 'CENTER';
      bindPad(comp, lk, { l: z.horizontalPadding, r: z.horizontalPadding, t: z.verticalPadding, b: z.verticalPadding });
      comp.setBoundVariable('itemSpacing', lk.space(dimVal(z.iconLabelGapStyle.size)));
      bindRadiusN(comp, lk, z.borderRadius);
      // A content surface on both platforms (`surfaceFor(.content)` folded into
      // the fill on Flutter, the content marker on Web).
      applySurfaceMaterial(comp, lk, background, 'content', { radius: z.borderRadius });
      // The width is passed, not left to `borderData`'s default. The default is
      // the literal 1 and the field is `CoreStrokeWidth.stroke1`, so the canvas
      // looked right while nothing pointed at the token — the shape a value has
      // when it is true by coincidence.
      // The default width is 0 — the badge states itself with a fill, a glyph
      // and a label — and a width of 0 draws no line, so the stroke is drawn
      // only when the field states one.
      if (dimVal(VALIDATION_BADGE.fields.borderWidth) > 0) {
        borderData(comp, lk, border, VALIDATION_BADGE.fields.borderWidth);
      }
      // A vector icon has no `fontSize`, so the local space-scale rebinding
      // this site used to need (the glyph's size traced to `CoreSpace`, which
      // neither of `glyphOpts`'s two sizeScale options covers) is gone with it.
      const icon = makeIcon(_kValidationBadgeIcon[sn] ?? 'dot', lk, glyphOpts(lk, fg, z.iconSize));
      comp.appendChild(icon);
      // `tokens.labelStyle.merge(_stateLabelStyle(merged, state))` then
      // `.toValue(color: foregroundColor)` — the per-size role carries the
      // metrics, the per-state partial merges over it, and the resolved
      // foreground wins the colour.
      const labelStyle = slots
        ? mergeTextStyleData(textStyleData(z.labelStyle), slots.label)
        : textStyleData(z.labelStyle);
      const t = makeLabel(_kValidationBadgeLabel[sn] || sn, lk, typographyColorOpts(lk, labelStyle, fg));
      comp.appendChild(t);
      t.layoutSizingHorizontal = 'HUG';
      t.layoutSizingVertical = 'HUG';
    }
  }
  const set = mount.finish();
  rowSet(set);
  return set;
}

// ─── ChipInput (input box with chips) ────────────────────────────────────────
// The badges' values and the entry line's hint — the docs example's hint, and
// two different values so the pills do not read as one entry twice.
const kChipInputBadges = ['디자인', '개발'] as const;
const kChipInputEntryPlaceholder = '태그를 입력해 주세요';


// Data-driven from coui_core CHIP_INPUT.fields: backgroundColor /
// borderColor / borderWidth / borderRadius / padding / chipSpacing for the
// outer field.
//
// The entry line is a composed `TextField`, not a placeholder label: the
// widget puts `TextField(textFieldStyle: CoreChipInputStyle.chromelessFieldStyle,
// hintText: placeholder)` in the `Wrap` after the chips. It fills the remaining
// row width, which is what `_inlineFieldWidth` computes in code.
// `inputTextStyle` is the typography of text typed INTO that field, which the
// instance now owns, so it is no longer read here. That `chromelessFieldStyle`
// forward — the ChipInput frame owning the single visible boundary — is not
// expressed on the canvas; see the chromeless note at the top of this file.
//
// The pills are `Chip` instances, not redrawn ones. `CoreChipInputStyle`
// forwards a whole nested `CoreChipStyle` (`chipStyle`), so the chip's chrome
// belongs to the `Chip` component; a hand-painted pill here would keep showing
// the old chip forever, because this builder's own recipe hash does not change
// when Chip's does.
//
// The member picked is the one the widget builds: `_buildChip` hands `Chip`
// `CoreChipInputStyle.chipVariant` / `chipEmphasis` / `chipSize`, i.e. the
// `filled` · `low` chip on the `sm` step, unselected (a badge never takes the
// selected state), neutral, `rounded`, and `State` follows the field's own
// `Enabled` (`enabled: widget.enabled`). The member carries the fill
// (`surface-container-high`), the corner (6), the padding (10 × 2), the gap (4)
// and the label (`labelSmall`, `on-surface-variant`; `disabled-content` when
// disabled) from the Chip's own `sm` row — `CoreChipInputStyle.defaultChipStyle`
// no longer restates any of them, which is why this builder does not paint
// over the instance. Requesting every axis the Chip set has matters:
// `bestVariantName` only scores, so an axis left out is settled by enumeration
// order.
//
// The close affordance comes from Chip (`Remove` boolean), and the one place
// the badge does diverge from the `sm` row is forwarded onto it: the two
// `chipStyle.closeButtonStyle` fields (`width` / `height` 16, against the row's
// 18) and `closeIconStyle.size` (12, against 16). `forwardChipCloseBox` owns
// how — it lives beside `buildChip`, whose close cell hugs its glyph so an
// instance can move the box by the glyph's step and the cell's inset, the two
// things an instance may override.
//
// The entry line is a composed `TextField` in its `plain` variant (no box, no
// fill): `CoreChipInputStyle.fieldVariant`. Its start inset (`inputPadding`, 4)
// is a wrapper the widget puts around the field, so the field sits in a frame
// that states it, as PhoneInput's number field does.
//
// The widget wraps that frame in `FocusOutline(focused: _focused,
// focusOutlineStyle: …)`, so a `FocusOutline` instance is in the tree with that
// forwarded style applied to it. The forward is exactly ONE value — the frame's
// own `borderRadius`, which the resolvers state under the caller's slot because
// "the ring has to trace the frame it surrounds, and that is the one value the
// child cannot derive". Every other ring field is deliberately left null so
// `FocusOutline`'s own resolver wins, and the export says the same thing from the
// other side: `chip_input.absent` records `focusOutlineStyle` as `nested`, so
// there is no ring COLOUR here to read. An earlier flat `focusRingColor` field is
// what this slot replaced; writing a colour now would restate a default the child
// already owns. The instance rides above the frame as an ABSOLUTE layer (an
// instance cannot be the frame's parent) sized to the field, and is hidden
// because the state this preview renders is `focused: false`, which draws no ring
// at all.
//
// Focus is still not an axis, and now for a narrower reason than before: the axes
// this set does have come from `chip_input.axes`, which promotes `enabled` and
// nothing else. A `Focus` pose on top would double the member count to toggle one
// hidden sibling's visibility, which is what a layer toggle inside an instance
// already does.
//
// #4037 (C4b) — static→variant-set promotion by ADOPTION. `chip_input.axes`
// promotes ONLY `enabled`, so the enumeration is two combinations and the loose
// COMPONENT this builder used to mint is adopted as `Enabled=true`. `Enabled=false`
// swaps the frame onto `disabledBackgroundColor` / `disabledBorderColor` (the
// widget's own `disabled > focus > hover > rest` pick), the chips onto the
// Chip's `disabled` member, and the entry field onto TextField's disabled one.
function buildChipInput(page: PageNode, lk: VarLookup): ComponentSetNode {
  const pad = CHIP_INPUT.fields.padding;
  const combos = enumerateAxisCombos(axisSpecsOf(CHIP_INPUT.axes));
  const mount = mountSet(page, 'ChipInput', combos, { adoptLooseAs: 'Enabled=true' });
  const f = CHIP_INPUT.fields;
  for (const comboName of combos) {
    const combo = parseVariantKey(comboName);
    const disabled = combo['Enabled'] === 'false';
    const c = mount.getOrCreate(comboName);
    c.layoutMode = 'HORIZONTAL';
    c.primaryAxisSizingMode = 'AUTO';
    c.counterAxisSizingMode = 'AUTO';
    c.counterAxisAlignItems = 'CENTER';
    bindPad(c, lk, { start: pad.start, end: pad.end, t: pad.t, b: pad.b });
    c.setBoundVariable('itemSpacing', lk.space(dimVal(f.chipSpacing)));
    // `BoxConstraints(minHeight: resolved.minHeight)` — the md control row
    // (`CoreChipInputStyle.defaultMinHeight`), the floor a density moves with
    // the text field beside it. The frame still hugs its chips past it.
    const frameRow = lk.controlHeightOrNull(dimVal(f.minHeight));
    if (frameRow) c.setBoundVariable('minHeight', frameRow);
    bindRadiusN(c, lk, f.borderRadius.topLeft);
    // The field is a content surface on both platforms, and states no cast of
    // its own, so it also takes the one a style contributes. Disabled states
    // its own fill (`disabledBackgroundColor`), not an opacity wash.
    applySurfaceMaterial(
      c,
      lk,
      colorData(disabled ? f.disabledBackgroundColor : f.backgroundColor),
      'content',
      { radius: f.borderRadius.topLeft },
    );
    addControlShadow(c, lk);
    borderData(
      c,
      lk,
      colorData(disabled ? f.disabledBorderColor : f.borderColor),
      dimVal(f.borderWidth) || 1,
    );
    // The widget is `width: .infinity`, i.e. as wide as its parent, and `minHeight`
    // (bound above, to the control row) is the only dimension it does state. A COMPONENT cannot itself be
    // "fill", so the canvas needs a number and this one is the preview's.
    // The number is chosen so the entry line is not clipped: beside the two badges
    // it keeps about 150px, over the ~114px its hint takes at `bodyMedium`.
    // g7-preview-only: ChipInput demo width, the widget is parent-width
    lockWidth(c, 320);
    // The member the widget builds for every badge — see the header.
    const chipMember = {
      Color: 'neutral',
      Variant: 'filled',
      Size: 'sm',
      State: disabled ? 'disabled' : 'enabled',
      Selected: 'false',
      Emphasis: 'low',
      Shape: 'rounded',
    };
    const chipVariant = bestVariantName(page, 'Chip', chipMember);
    for (let i = 0; i < kChipInputBadges.length; i++) {
      const badge = instanceOf(page, 'Chip', chipVariant);
      // Each badge is a different value — two chips both reading Chip's own
      // default label looked like a duplicate entry.
      setInstanceTextNamed(badge, 'Child', kChipInputBadges[i]);
      // `Chip(onRemove: …)` — every badge the widget builds is removable, and
      // an enabled chip with a handler draws its close button. A disabled chip
      // draws none whatever the handler is, so the disabled member keeps the
      // property off.
      if (!disabled) {
        setInstanceBoolNamed(badge, 'Remove', true);
        const close = f.chipStyle;
        forwardChipCloseBox(badge, page, lk, {
          glyphSize: close.closeIconStyle.size,
          width: close.closeButtonStyle.width,
          height: close.closeButtonStyle.height,
          member: chipMember,
        });
      }
      c.appendChild(badge);
    }
    // `Padding(padding: resolved.inputPadding)` around the entry field — the
    // gap to the last badge, a wrapper of the widget's and not chrome of the
    // field's own.
    const inPad = f.inputPadding;
    const entry = figma.createFrame();
    entry.name = 'entry';
    entry.fills = [];
    entry.layoutMode = 'HORIZONTAL';
    entry.primaryAxisSizingMode = 'AUTO';
    entry.counterAxisSizingMode = 'AUTO';
    entry.counterAxisAlignItems = 'CENTER';
    bindPad(entry, lk, { start: inPad.start, end: inPad.end, t: inPad.t, b: inPad.b });
    // `TextField(variant: CoreChipInputStyle.fieldVariant, enabled: …)` — the
    // `plain` variant, size `md`.
    const field = instanceOf(
      page,
      'TextField',
      bestVariantName(page, 'TextField', {
        Variant: 'plain',
        Size: 'md',
        Enabled: disabled ? 'false' : 'true',
      }),
    );
    field.name = 'inline entry field';
    // The entry line's own hint, not TextField's email copy.
    setInstanceTextNamed(field, 'Placeholder', kChipInputEntryPlaceholder);
    entry.appendChild(field);
    c.appendChild(entry);
    entry.layoutSizingHorizontal = 'FILL';
    field.layoutSizingHorizontal = 'FILL';
    // `inputTextStyle` — the typography the entry line uses, forwarded onto the
    // composed field's own text. It states a role AND a colour, so both are honoured
    // (unlike a colour-only slot).
    applyInstanceTextStyle(field, lk, textStyleData(CHIP_INPUT.fields.inputTextStyle));
    // The composed field is CHROMELESS — this frame's own border and fill (bound
    // above) are the single visible boundary. The `plain` member already draws no
    // box; the widget also hands the inline `TextField`
    // `CoreChipInputStyle.chromelessFieldStyle`, whose remaining statements (square
    // corner, no inset, no floor, no ring, no wash) the same call applies.
    suppressFieldChrome(field, lk, CHIP_INPUT.constants.chromelessFieldStyle);
    // `inputTextStyle` is the TYPED text's style, and the call above lays its
    // colour (`onSurface`) over the field's placeholder too. The hint is the
    // composed `TextField`'s own: it draws it in the plain row's tone
    // (`enabled ? placeholderColor : disabledForegroundColor`) and the typed
    // text's colour never reaches it — so both members are repainted with that.
    // Repainting only the disabled one left the enabled hint in `onSurface`,
    // where it read as text already typed.
    // The row is the one `CoreChipInputStyle.fieldVariant` names — the same
    // constant the widgets compose the field with — rather than a key spelled here.
    const fieldVariant = CHIP_INPUT.constants.fieldVariant
      .choice as keyof typeof TEXT_FIELD.variants.defaultsByVariant;
    const fieldRow = TEXT_FIELD.variants.defaultsByVariant[fieldVariant];
    paintPlaceholder(
      field,
      lk,
      colorData(disabled ? fieldRow.disabledForegroundColor : fieldRow.placeholderColor),
    );
    // `FocusOutline(focused: _focused, focusOutlineStyle: …)` around the frame.
    // Its `child` slot is resized to the field so the ring hugs it rather than
    // FocusOutline's own preview placeholder; height is the widget's own
    // `BoxConstraints(minHeight: resolved.minHeight)`, since an auto-layout frame's
    // resolved height is Figma's to compute and not readable here.
    // `Shape=rectangle` by name — `chip_input.dart` passes no `shape`, which
    // is the contract's own default, and naming it does not leave the pick to
    // whichever member happens to sort first.
    const ring = instanceOf(page, 'FocusOutline', 'Shape=rectangle');
    ring.name = 'FocusOutline';
    const slot = instanceFrameSlot(ring, 'child');
    if (slot) slot.resize(c.width, dimVal(CHIP_INPUT.fields.minHeight));
    // And the instance itself: an inner slot resize does not re-hug the root,
    // and the root is the wrapped box now, with the child's ring layers
    // hanging outside it on STRETCH constraints.
    ring.resize(c.width, dimVal(CHIP_INPUT.fields.minHeight));
    // The whole of the forward — the radius, and nothing else (see the header).
    // `FocusOutline.borderRadius` is `@hostDerived`, so the host's corner is
    // exactly what this states. The instance root alone would not carry it
    // anywhere visible — under the set's shape the root paints nothing and the
    // ring and band bind their own corners in the main — so the forwarder
    // writes root, ring (host + `align`) and band together from this one
    // value, with FocusOutline's own stated offsets. Today that is 12 / 10,
    // the same corners the child draws for its preview; the point is that a
    // host radius which moves later moves all three with it.
    forwardFocusOutlineHostRadius(ring, lk, CHIP_INPUT.fields.borderRadius.topLeft, {
      align: FOCUS_OUTLINE.fields.align,
      borderWidth: FOCUS_OUTLINE.fields.borderWidth,
    });
    // Same as the OTP cell above: visibility is the instance's, so the
    // inner layers stay on and the instance itself is what hides. Without
    // this, turning the layer on in Figma would reveal an empty wrapper.
    setInstanceBoolNamed(ring, 'Focused', true);
    // STRETCH for the same reason as the OTP cell above (#4701).
    const ringPin = pinAbsolute(c, ring, 0, 0, {
      horizontal: 'STRETCH',
      vertical: 'STRETCH',
    });
    ringPin.visible = false;
    // Sized to the row Figma settled on, with `minHeight` as the floor for the
    // case the height is not resolved yet — the holder is what the STRETCH
    // insets are measured from (#4701).
    sizePin(ringPin, c.width, Math.max(c.height, dimVal(CHIP_INPUT.fields.minHeight)));
  }
  const set = mount.finish();
  rowSet(set);
  return set;
}

// ─── Registry ────────────────────────────────────────────────────────────────

export const FORM_FIELDS: RegistryEntry[] = [
  // FormField instantiates ValidatorHint, which itself needs Icon — the edge is
  // declared one level deep only; `topoSortRegistry` walks the rest. `TextField`
  // is the `child` slot's demo content and its INSTANCE_SWAP default.
  {
    section: 'Form',
    name: 'FormField',
    build: buildFormField,
    needs: ['ValidatorHint', 'TextField', 'Button'],
  },
  // The grouped rows are `TextField` instances — `children: List<W>` is
  // caller-supplied, and the component a caller groups in a fieldset first is a
  // field.
  { section: 'Form', name: 'Fieldset', build: buildFieldset, needs: ['TextField'] },
  { section: 'Form', name: 'FormLabel', build: buildFormLabel },
  // The browse affordance is a real `Button(variant: .outline)` in the widget.
  { section: 'Form', name: 'FileInput', build: buildFileInput, needs: ['Icon', 'Button'] },
  // The hidden keyboard/autofill buffer under the cell row is a `TextField`;
  // every cell is wrapped in a `FocusOutline`.
  {
    section: 'Form',
    name: 'InputOtp',
    build: buildInputOtp,
    needs: ['TextField', 'FocusOutline', 'ValidatorHint'],
  },
  // Trigger | vertical `Divider` | chromeless `TextField`, all inside one
  // bordered container — the widget's own row, one instance per half — and the
  // whole thing wrapped in the country-picker `Popover`.
  {
    section: 'Form',
    name: 'PhoneInput',
    build: buildPhoneInput,
    needs: ['Icon', 'Divider', 'TextField', 'Popover'],
  },
  // `Icon` for the two affix slots the widget's Row leaves open.
  {
    section: 'Form',
    name: 'FormattedInput',
    build: buildFormattedInput,
    needs: ['TextField', 'Icon'],
  },
  { section: 'Form', name: 'ValidatorHint', build: buildValidatorHint, needs: ['Icon'] },
  { section: 'Form', name: 'ValidationBadge', build: buildValidationBadge, needs: ['Icon'] },
  // ChipInput no longer draws its own pills (or their close glyph), so `Icon` is
  // reached through Chip rather than directly; the entry line is a `TextField`,
  // and the frame is wrapped in a `FocusOutline`.
  {
    section: 'Form',
    name: 'ChipInput',
    build: buildChipInput,
    needs: ['Chip', 'TextField', 'FocusOutline'],
  },
];
