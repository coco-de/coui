/// <reference types="@figma/plugin-typings" />

// Shared drawing operation: writing a parent's `validatorHintStyle` partial onto
// the `ValidatorHint` instance it composed. Validated and InputOtp both compose
// an error hint this way, so the writer lives below both registry builders —
// dependencies point here, never from one builder module into another.
import { VarLookup, applyLetterSpacing, weightStyle } from './helpers';
import { dimVal, textStyleData } from './compat/v1';
import { COMPONENTS } from './data';

const VALIDATED = COMPONENTS.validated;

// ─── Shared: applying a raw-forward partial onto a composed instance ──────────

// `CoreLineHeight` is a unitless multiplier; Figma's `TextNode.lineHeight` wants
// PERCENT. Same conversion `helpers.ts#lineHeightPercent` does, which is not
// exported.
const PERCENT = 100;

// The message text node inside a composed `ValidatorHint`.
//
// Direct children first, descendants only as a fallback: the same ordering
// `form-pickers.ts#instanceTextNode` settled on, and for the same reason — a
// depth-first "first TEXT anywhere" pick starts returning whatever a nested
// subtree grows. ValidatorHint's own children are one `Icon` instance (vectors,
// no text) and this label, so the direct pass answers today; the fallback is
// there so a wrapper frame appearing upstream degrades to "found it deeper"
// instead of null.
//
// Null when the child renames or drops it — the caller then leaves the
// instance alone. Skipping one override is a 12 px label where 13 belonged;
// throwing would fail `Validated`'s entry over a change in `ValidatorHint` and
// leave it half-drawn on the canvas until the next run blanks it — the same
// trade `bestVariantName`'s scoring makes at the top of this file.
function instanceTextNode(inst: InstanceNode): TextNode | null {
  for (const child of inst.children) {
    if (child.type === 'TEXT') return child;
  }
  for (const node of inst.findAll((n) => n.type === 'TEXT')) {
    if (node.type === 'TEXT') return node;
  }
  return null;
}

// The `Icon` instance inside a composed `ValidatorHint`.
function instanceIconNode(inst: InstanceNode): InstanceNode | null {
  for (const child of inst.children) {
    if (child.type === 'INSTANCE') return child;
  }
  return null;
}

// Writes a parent's `validatorHintStyle` onto the `ValidatorHint` it composed.
//
// WHY THIS EXISTS AT ALL. `validatorHintStyle` is a raw-forward partial — the
// parent hands it down and the CHILD's resolver merges it — so the reflex is
// "the child already draws it, nothing to do here". That is true only where the
// two agree, and on one leaf they do not: `Validated` states the message role as
// `bodySmall` while `ValidatorHint`'s own default is `bodyXs`
// (`components.json`), and the typography scale puts those at 13 px and 12 px.
// The widget merges the parent's value in at the top of the chain, so a real
// `Validated` renders 13; the plain instance on the canvas renders 12. One
// pixel, on every composed hint, with nothing anywhere reporting it.
//
// The comment that used to sit in `buildValidated` argued this was unreachable —
// "schema v2's TextLeaf carries only the role's *name* — no resolved size — so
// there is nothing to apply to the instance". That stopped being true when the
// exporter started emitting the typography scale at the document root:
// `compat/v1.ts#textStyleData` looks the role up in it and returns real
// `fontSize` / `fontWeight` / `lineHeight`. The note outlived the gap it
// described, which is the failure mode a stated-but-undrawn value has — it reads
// as settled.
//
// These are ordinary instance overrides, the kind `icon-nodes.ts#repaintGlyph` already
// performs on every icon instance and the kind a designer's double-click
// produces. Deliberately NOT `constraints`, which Figma refuses on an instance
// outright (see `helpers.ts#pinAbsolute` — that write is how TimePicker came
// out half-drawn with every gate green).
//
// Colour is untouched: `validatorHintStyle` carries no colour, so the tone stays
// the hint variant's own.
//
// Exported for the other parents that compose an error hint the same way
// (InputOtp's `errorValidatorHintStyle`) — one writer, so a partial lands on
// the instance identically whichever parent states it.
export function applyValidatorHintStyle(
  hint: InstanceNode,
  lk: VarLookup,
  style: Pick<
    typeof VALIDATED.fields.validatorHintStyle,
    'messageTextStyle' | 'iconStyle' | 'iconLabelGapStyle'
  >,
): void {
  const role = textStyleData(style.messageTextStyle);
  const text = instanceTextNode(hint);
  if (text != null && role.fontSize != null) {
    text.fontName = {
      family: lk.fontFamilyName('sans'),
      style: weightStyle(role.fontWeight),
    };
    text.fontSize = role.fontSize;
    // Bound when the scale has this step, literal otherwise — `makeLabel`'s own
    // fallback, for its reason: an unbound number still renders, a throw here
    // fails the entry and leaves the component half-drawn on the page.
    const sizeVar = lk.fontSizeOrNull(role.fontSize);
    if (sizeVar) text.setBoundVariable('fontSize', sizeVar);
    applyLetterSpacing(text, lk, {
      em: role.letterSpacing,
      size: role.fontSize,
      role: role.role,
    });
    if (role.lineHeight != null) {
      text.lineHeight = { unit: 'PERCENT', value: role.lineHeight * PERCENT };
    }
  }

  // The icon/label gap the PARENT states, so the canvas keeps showing
  // `Validated`'s value if the child's default ever moves off it.
  const gap = dimVal(style.iconLabelGapStyle.size);
  hint.itemSpacing = gap;
  hint.setBoundVariable('itemSpacing', lk.space(gap));

  // Same for the icon — but as a ratio, because the child already fitted this
  // instance to its own size (`makeIcon`), so the write that lands
  // `Validated`'s size is the step BETWEEN the two, not the size itself.
  // Both are `CoreIconSize.size14` today, so the ratio is 1 and this is skipped:
  // the field is stated, drawn, and agrees. The branch exists for the day the
  // child's default moves, which is the only day the two can disagree.
  const icon = instanceIconNode(hint);
  const stated = dimVal(style.iconStyle.size);
  const drawn = dimVal(COMPONENTS.validator_hint.fields.iconStyle.size);
  if (icon != null && drawn > 0 && stated !== drawn) icon.rescale(stated / drawn);
}
