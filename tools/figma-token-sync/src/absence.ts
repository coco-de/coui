/**
 * What a *valueless* Core field must look like on the canvas.
 *
 * `components.json` carries `absent: { field: FieldKind }` for every declared
 * chrome field that reached no value — no `default*`, no variant or size row.
 * That is a decision, not a gap: a `!= null` branch in the resolver decides
 * whether the thing is drawn at all, so `button.boxShadow` carrying nothing
 * means a button is flat.
 *
 * Before this table the builders knew that too, and knew it *separately* —
 * `form.ts` writes `primaryAxisSizingMode = 'AUTO'` at five sites because a
 * button hugs its label. The data and the builder agreed and nothing compared
 * them, so giving the field a width would have left the canvas hugging with
 * every gate still green.
 *
 * The reader deliberately does not carry the Figma word (`'HUG'`): that is emit
 * vocabulary and `core/style-contract.md` keeps Core free of it. So the word
 * lives here, once, next to the assertion that checks it.
 */

/** A `FieldKind` name as emitted by the reader, plus `nested`. */
export type AbsentKind =
  | 'dim'
  | 'color'
  | 'insets'
  | 'radius'
  | 'text'
  | 'gap'
  | 'icon'
  | 'duration'
  | 'choice'
  | 'shadow'
  | 'flag'
  | 'colorList'
  | 'gradient'
  | 'glyph'
  | 'nested';

/**
 * How an absence shows up on the canvas, and whether it can be checked there.
 *
 * `assertion: null` is not an excuse — it records that Figma has no counterpart
 * to look at, so a reader that starts routing the field would not be caught by
 * this axis and needs another one. Writing it down is the point; the ledger
 * being complete is what makes the silent entries visible.
 */
export interface AbsenceRule {
  /** What the canvas must show. Prose, for the failure message. */
  readonly means: string;
  /**
   * The property to read and what it must be, or `null` when Figma models
   * nothing for this kind.
   */
  readonly assertion: AbsenceAssertion | null;
}

export type AbsenceAssertion =
  /** `effects` must be empty — nothing casts a shadow. */
  | { readonly kind: 'no-effects' }
  /** `fills` must be empty or fully transparent. */
  | { readonly kind: 'no-fill' }
  /** `strokes` must be empty, or `strokeWeight` 0. */
  | { readonly kind: 'no-stroke' }
  /** Every corner radius must be 0. */
  | { readonly kind: 'sharp-corners' }
  /** No fixed size on the axis — the frame hugs or fills, never FIXED. */
  | { readonly kind: 'not-fixed-size' }
  /** `paddingLeft/Right/Top/Bottom` must all be 0. */
  | { readonly kind: 'no-padding' }
  /** `itemSpacing` must be 0. */
  | { readonly kind: 'no-spacing' };

export const ABSENCE_RULES: Readonly<Record<AbsentKind, AbsenceRule>> = {
  shadow: {
    means: 'flat — nothing casts a shadow',
    assertion: { kind: 'no-effects' },
  },
  // A colour field covers both fills and strokes, and the kind alone cannot
  // say which role this one plays. Asserting `no-fill` on a field that was a
  // border colour would fail on a node that is legitimately filled by another
  // field, so the check stays out and the meaning is still recorded.
  color: {
    means: 'unpainted — this role contributes no colour',
    assertion: null,
  },
  colorList: {
    means: 'no gradient — the surface is a single colour or none',
    assertion: null,
  },
  // A gradient field (`FieldKind.gradient`) absent is the same statement as an
  // absent colour: the surface keeps whatever solid it states. Figma has no
  // "unstated gradient" to read back — a fill list is either a solid or a ramp,
  // and which one is a decision the field states when it is present — so there
  // is nothing to assert on the node.
  gradient: {
    means: 'no gradient — the surface keeps its solid fill',
    assertion: null,
  },
  // A drawing (`FieldKind.glyph`) absent draws nothing: the slot it would fill
  // stays empty. Figma keeps no marker for an unstated vector either.
  glyph: {
    means: 'no drawing — the slot stays empty',
    assertion: null,
  },
  // `dim` is "a number", not "a size" — `surfaceOpacity`, `dividerThickness`,
  // `rowHeight` and `ratio` are all `double` and none of them is the extent of
  // the component. Reading the kind alone and asserting on the frame's sizing
  // reported seven components as pinned when nothing about them was, so the
  // sizing assertion is keyed by the field's role instead, below, and the kind
  // itself asserts nothing.
  dim: { means: 'no value — the widget decides', assertion: null },
  insets: { means: 'zero inset', assertion: { kind: 'no-padding' } },
  gap: { means: 'no gap between the two siblings', assertion: null },
  radius: { means: 'sharp corners', assertion: { kind: 'sharp-corners' } },
  // Text and icon absence is inheritance: the slot takes whatever the ancestor
  // set. Figma has no "inherited" flag to read — the node simply carries the
  // resolved value — so there is nothing here to compare against.
  text: { means: 'inherits the ancestor text style', assertion: null },
  icon: { means: 'inherits the ancestor icon style', assertion: null },
  // Figma renders one moment. A duration has no counterpart at all, which is
  // the only kind in this table for which that is true of the *concept* rather
  // than of the check.
  duration: { means: 'not representable — the canvas is one frame', assertion: null },
  choice: {
    means: 'the widget picks at build time',
    assertion: null,
  },
  flag: { means: 'the widget picks at build time', assertion: null },
  // The documented parent→child forward: the parent writes only what diverges
  // and the child's resolver fills the rest, so an empty slot is correct and
  // there is no parent decision to check.
  nested: {
    means: "forwarded raw — the child's resolver supplies its own defaults",
    assertion: null,
  },
};

/**
 * The five field names that state the component's own extent.
 *
 * A role the kind cannot carry: every one of these is a `double`, and so are
 * `surfaceOpacity` and `dividerThickness`, which say nothing about how big the
 * frame is. Enumerated rather than pattern-matched on `/Width|Height/` because
 * `viewportWidth`, `panelHeight`, `headerHeight` and `rowHeight` all end in one
 * of those words and are extents of something *else* — an inner viewport, a
 * panel, a row — which the component root is not.
 */
const kExtentFields = new Set([
  'width',
  'height',
  'minWidth',
  'maxWidth',
  'minHeight',
  'maxHeight',
]);

/**
 * Whether this absence can be checked against the canvas at all.
 *
 * Takes the field name as well as the kind because one assertion needs a role
 * the kind does not carry — see [kExtentFields].
 */
export function absenceAssertionFor(
  kind: string,
  field: string,
): AbsenceAssertion | null {
  if (kind === 'dim') {
    return kExtentFields.has(field) ? { kind: 'not-fixed-size' } : null;
  }
  const rule = ABSENCE_RULES[kind as AbsentKind];
  return rule ? rule.assertion : null;
}

/** Prose for a failure message. Unknown kinds read as unknown, not as fine. */
export function absenceMeaning(kind: string): string {
  return ABSENCE_RULES[kind as AbsentKind]?.means ?? `unknown kind '${kind}'`;
}
