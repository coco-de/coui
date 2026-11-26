/// <reference types="@figma/plugin-typings" />

import componentsJson from '../data/components.json';

// v1 compatibility shim (#3753) — lets the dimensional helpers in
// `helpers.ts` accept either a bare `number` (what all 91 still-hardcoded
// builders pass today) or a schema v2 `Dim` leaf (what a builder passes
// once it's converted to read a component's data from `data.ts`/
// `components.json`).
//
// Hard constraint (from the issue): the 13 shared helpers
// (`makeLabel`/`panel`/`bindSize`/`bindRadiusN`/…) currently take `number`
// params and are called ~490 times across the builder files. Replacing
// `number` with `Dim` would force a rewrite at every one of those call
// sites. Widening to `number | Dim` instead keeps all of them compiling
// unchanged — `dimVal()` below is the single point that normalizes either
// shape down to the plain px number every helper already knows how to
// bind (via `lk.space(v)` / `lk.radius(v)` / `lk.size(v)` / … — unchanged).

// One leaf value from schema v2's `components.json`
// (`packages/coui_core/bin/figma_reader/emit.dart#emitDim`):
//   { "v": 16.0, "ref": "Primitives/space/16", "via": "CoreSpace.space16" }
//   { "v": 512.0, "ref": null, "via": null }   // no token on the scale
//
// `ref` is the Figma Variable's full `Collection/name` path when the value
// traces to a primitive token, `null` when it doesn't. That "doesn't
// trace" case is *not* recorded anywhere in `components.json` itself —
// `meta` carries no `untokenized` key (verified against the real schema
// v2 doc: `packages/coui_core/bin/figma_reader/schema_v2.dart#BuildResult`
// keeps `untokenizedTotal` as a bare count, and `export_figma_components.
// dart` only ever prints it to stdout/stderr, never embeds it in the JSON
// — that's a distinct concept anyway: a `ref: null` leaf still made it
// into `fields`/`variants`/`sizes` with an untokenized *value*, whereas an
// `UntokenizedField` is a field the reader couldn't route or resolve at
// all, so it's simply absent from the JSON, not present with `ref: null`).
// `via` is a human-readable provenance string for debugging (e.g.
// `"defaultIconGap -> CoreSpace.space20"`) and is never read by this shim
// or by any consumer — present for `check_reader_census` and
// hand-inspection only.
//
// This shim intentionally does not bind via `ref` yet. `dimVal()` only
// extracts `v`, so a `Dim`-carrying builder binds through the exact same
// by-value `lk.space(v)`/`lk.radius(v)`/`lk.size(v)` lookups a hardcoded
// builder already uses — behavior-preserving by construction. Binding
// directly via `ref` (skipping the by-value re-lookup, and correctly
// no-op'ing when `ref` is null) is future work once builders start
// depending on it.
export interface Dim {
  v: number;
  ref: string | null;
  via?: string | null;
}

export function isDim(x: unknown): x is Dim {
  return (
    typeof x === 'object' &&
    x !== null &&
    'v' in (x as Record<string, unknown>) &&
    typeof (x as { v: unknown }).v === 'number'
  );
}

// Single normalization point for every `number | Dim` helper parameter.
export function dimVal(x: number | Dim): number {
  return typeof x === 'number' ? x : x.v;
}

// Same normalization for an optional value — passes `undefined`/`null`
// through unchanged (helpers with optional dimensional params, e.g.
// `ChromeOpts.gap?`, need this instead of forcing a default here).
export function dimValOrNull(x: number | Dim | null | undefined): number | null {
  if (x == null) return null;
  return dimVal(x);
}

// ─── Color union fix (#3753 "부수 정리") ──────────────────────────────────────
//
// Schema v2's Color leaf is `{ ref, argb, opacity, fallbacks }` (`Data
// Architecture — 스키마 v2`), and its consumer rule is one formula:
//   alpha = ((argb >>> 24) / 255) * opacity
//   alpha === 0 → no paint · ref → bind(ref, alpha) · else → solid(rgb, alpha)
// Before this shim, three functions in `helpers.ts` each handled the
// raw-literal (`argb`, no `ref`/`color`) branch of that rule differently:
//   argbToRgb  — dropped the alpha byte entirely (always painted opaque)
//   borderData — `if (!cd || cd.color == null) return;` silently dropped
//                every argb-only border
//   labelColor — hardcoded `whiteFill: true`, ignoring the real argb value
// `argbToRgb` / `argbAlpha` here are the two halves of that one formula —
// every raw-literal color path in helpers.ts now composes both.

const _kColorByte = 255;

// RGB channels only — a Figma `SolidPaint` carries alpha as a separate
// `opacity` field, never inside `color`. Always pair with `argbAlpha()`.
export function argbToRgb(argb: number): RGB {
  return {
    r: ((argb >> 16) & 0xff) / _kColorByte,
    g: ((argb >> 8) & 0xff) / _kColorByte,
    b: (argb & 0xff) / _kColorByte,
  };
}

// `>>> 24` (unsigned shift), not `>> 24` — plain ARGB values with the alpha
// byte set (e.g. `0xFFFFFFFF`) are outside `Int32`'s signed range, and a
// signed shift would produce a negative byte and an out-of-range alpha.
export function argbAlpha(argb: number, opacity?: number | null): number {
  return ((argb >>> 24) / _kColorByte) * (opacity == null ? 1 : opacity);
}

// ─── Generic v2 leaf shapes + adapters to helpers.ts's pre-v2 shapes ──────────
//
// `Dim` above is schema v2's dimensional leaf. `Color` (below) is its
// Color-leaf counterpart (`emit.dart#emitColor`) — always this fixed
// four-key shape, never a union, never a bare `null` (a color *field* can
// be absent from `fields`/`variants`/`sizes`; when present, its value
// always has this shape — `.transparent` included, as `argb: 0`).
export interface Color {
  ref: string | null;
  argb: number;
  opacity: number;
  fallbacks: string[];
}

// Schema v2's TextStyle leaf (`emit.dart#emitText`) — `role` is the stable
// Figma Text Style binding key (present, possibly `null`); every overlay
// field the source actually set is present, everything else is simply
// absent from the object (not `null`) — this codebase never sets more
// than fontSize/fontWeight/color on a builder-consumed style today, but
// the shape carries all six per the exporter's contract.
export interface TextLeaf {
  role: string | null;
  fontSize?: Dim;
  fontWeight?: number;
  letterSpacing?: number;
  lineHeight?: number;
  /** A fixed line box in px (`CoreTextStyle.lineHeightPx`). */
  lineHeightPx?: number;
  fontFamily?: string;
  color?: Color;
}

// The shape `data.ts`'s adapters below hand to `helpers.ts` — deliberately
// *not* imported from there (`helpers.ts` already imports this file; an
// `import type { ColorData } from '../paint'` here would be a circular
// type-only import that compiles fine but reads backwards). Structural
// typing makes the duplication a non-issue: this is satisfied by, and
// satisfies, `paint.ts#ColorData` exactly.
export interface NormalizedColor {
  color: string | null;
  opacity?: number;
  argb?: number;
}

// Adapts a v2 `Color` leaf to the shape every color-consuming helper in
// helpers.ts already knows how to paint (`fillData`/`borderData`/
// `labelColor`/…) — the Color-leaf counterpart to `dimVal()` above.
// `ref` is the Variable's full `Collection/name` path
// (`"Semantic/color/on-surface"`); `NormalizedColor.color` wants the bare
// name `VarLookup.sem()` looks up under `Semantic/color/<name>`, so this
// strips the fixed `"Semantic/color/"` prefix. A `ref: null` leaf (raw ARGB
// construction, or the `.transparent` sentinel) carries no semantic name at
// all — `color: null` plus the raw `argb` is exactly the shape `fillData`'s
// raw-literal branch already handles.
export function colorData(c: Color | null | undefined): NormalizedColor | null {
  if (!c) return null;
  if (c.ref == null) return { color: null, argb: c.argb, opacity: c.opacity };
  // The `argb` is kept for a TOKEN leaf too, and it is not redundant with the ref:
  // it is the only thing that can paint the colour when its alpha is below 1. A
  // bound Figma paint supplies its own alpha and overwrites the paint's, so a 10%
  // tint has to be a literal — and the plugin cannot read a Variable's value back
  // to build one. Dropping it here is why every sub-1 token tint shipped saturated
  // (`Banner` / `Alert` toned variants, `CodeDiff` row tints); `solid` throws now
  // rather than binding, so the loss would be loud instead of invisible.
  return {
    color: semanticNameOf(c.ref),
    argb: c.argb,
    opacity: c.opacity,
  };
}

// The bare name `VarLookup.sem()` looks up under `Semantic/color/<name>`, from a
// leaf's `ref`. One function because two places read a `ref` that way — a colour
// leaf (`colorData`) and a gradient stop, which is a colour leaf in a list and
// reaches its variable by the same route.
export function semanticNameOf(ref: string): string {
  return ref.replace(/^Semantic\/color\//, '');
}

// The shape `textLabelOpts`/`typographyColorOpts` (helpers.ts) already
// know how to bind — see the `NormalizedColor` note above for why this
// isn't imported from `helpers.ts#TextStyleData` directly. `lineHeight` is
// `CoreLineHeight`'s unitless multiplier (1.4, 1.6, …) verbatim —
// `helpers.ts#makeLabel` is what converts it to Figma's PERCENT unit.
export interface NormalizedTextStyle {
  fontSize: number | null;
  fontWeight: number | null;
  lineHeight: number | null;
  color: NormalizedColor | null;
  /** The typography role the style states (`labelLarge`), when it states
   *  one — what `makeLabel` binds the semantic `font-size/<role>` and
   *  `letter-spacing/<role>` variables by. */
  role?: string | null;
  /** `CoreLetterSpacing`'s em ratio (−0.01), from the style or its role. */
  letterSpacing?: number | null;
  /** The ROLE's family (`Geist Mono` for a code role), null for the text
   *  face. Read from the role only — a family a component overlays on its
   *  own style is not drawn on the canvas. */
  fontFamily?: string | null;
  /** A fixed line box in px. When set it wins over `lineHeight`. */
  lineHeightPx?: number | null;
}

/** One role's metrics, as the exporter writes them into `typography`. */
export interface RoleMetrics {
  fontSize: number | null;
  lineHeight: number | null;
  fontWeight: number | null;
  letterSpacing: number | null;
  /** The role's family, null for the text face. Absent in an export that
   *  predates the field, which reads the same as null. */
  fontFamily?: string | null;
  /** A fixed line box in px — the code roles' 21px grid. */
  lineHeightPx?: number | null;
  /** What the role draws in each mode of the `Semantic/ Typography`
   *  collection, keyed by mode name (`Mobile`). Size and tracking are the
   *  only fields that change with the mode. Absent in an export that
   *  predates the field. */
  modes?: Record<string, RoleModeMetrics> | null;
}

/** One role in one typography mode — what the role's `font-size/<role>` and
 *  `letter-spacing/<role>` variables hold there (tracking as an em ratio). */
export interface RoleModeMetrics {
  fontSize: number | null;
  letterSpacing: number | null;
}

// The typography scale, keyed by role. Emitted at the document root by the
// exporter because a role belongs to the scale, not to whichever component
// references it.
const ROLES = (componentsJson as { typography?: Record<string, RoleMetrics> }).typography ?? {};

/**
 * The scale's own metrics for a role name, or undefined when it names none.
 *
 * What a label is measured against before it keeps its role (`roleDeparture`
 * in text-nodes.ts compares every field a role's text style states), what the
 * opts builders fill an unstated field from, and the one question a re-styling
 * path has to ask and cannot answer from the style alone: is the size this
 * text renders at the role's OWN size? A semantic typography variable holds
 * PIXELS computed for the role's size, so binding it to a label rendered at a
 * different rung states a ratio nobody chose.
 */
export function roleMetrics(role: string): RoleMetrics | undefined {
  return ROLES[role];
}

/**
 * A role's metrics as it draws in [mode] — the role's own, with the size and
 * tracking that mode's variables hold. The role's own (the code scale, which
 * is the collection's Desktop mode) when [mode] is null or the export has no
 * row for it; see [roleHasMode] to tell the two apart.
 *
 * The question a consumer file asks: a text style binds its size and tracking
 * to the role's variables, so what it draws is the value in the mode the text
 * resolves, and a file drawn in Mobile gets the smaller display and headline
 * sizes. Read from the export rather than from the document's variables
 * because a consumer file holds only the library's, and only the ones it uses.
 */
export function roleMetricsIn(role: string, mode: string | null): RoleMetrics | undefined {
  const own = ROLES[role];
  if (own == null || mode == null) return own;
  const row = own.modes?.[mode];
  if (row == null) return own;
  return { ...own, fontSize: row.fontSize, letterSpacing: row.letterSpacing };
}

/** True when the export states [role]'s metrics in [mode]. */
export function roleHasMode(role: string, mode: string | null): boolean {
  return mode != null && ROLES[role]?.modes?.[mode] != null;
}

/**
 * True when [role]'s size differs between the typography modes — the
 * display and headline roles. The export's answer to the question
 * `roleFollowsMode` (text-nodes.ts) asks of a document's variables: Import
 * writes those variables from the same table.
 */
export function roleSizeVariesByMode(role: string): boolean {
  const rows = Object.values(ROLES[role]?.modes ?? {});
  return new Set(rows.map((r) => r.fontSize)).size > 1;
}

/**
 * Every role the scale names, in the exporter's order (largest display first,
 * code last) — the same table `roleMetrics` reads, so a caller that has to ask
 * "which role is this?" of a value asks it of the one table, not of a list it
 * keeps itself.
 */
export function roleNames(): string[] {
  return Object.keys(ROLES);
}

/**
 * The monospace family the export names — the one family any role states —
 * or null for an export that names none.
 *
 * Read from the roles rather than written here, because it is the string the
 * document's `font/family/<name>` variable is keyed by: a second copy would
 * pick the wrong variable the day the family changes, and Import never
 * deletes the old one.
 */
export function exportedMonoFamily(): string | null {
  const families = new Set<string>();
  for (const m of Object.values(ROLES)) {
    if (m.fontFamily != null) families.add(m.fontFamily);
  }
  if (families.size > 1) {
    throw new Error(
      `the typography roles name ${families.size} families (${[...families].join(', ')}) — ` +
        'the plugin knows one text face and one monospace face',
    );
  }
  return families.size === 0 ? null : [...families][0];
}

/** The weights the monospace roles draw in — the faces a code label needs. */
export function monoRoleWeights(): number[] {
  const mono = exportedMonoFamily();
  const weights = new Set<number>();
  for (const m of Object.values(ROLES)) {
    if (mono != null && m.fontFamily === mono && m.fontWeight != null) weights.add(m.fontWeight);
  }
  return [...weights].sort((a, b) => a - b);
}

/** True when [role]'s own family is the monospace one (the code roles). */
export function isMonoRole(role: string): boolean {
  const family = ROLES[role]?.fontFamily;
  return family != null && family === exportedMonoFamily();
}

/**
 * The family token (`'sans'` | `'mono'`) a role's family draws with —
 * `LabelOpts.family`'s vocabulary. Null is the text face; a family the export
 * does not name is a throw, not a guess.
 */
export function familyTokenOf(family: string | null | undefined): 'sans' | 'mono' {
  if (family == null) return 'sans';
  if (family === exportedMonoFamily()) return 'mono';
  throw new Error(`"${family}" is neither the text face nor the exported monospace family`);
}

/**
 * The line box after an overlay — `CoreTextStyle`'s rule, so the canvas reads
 * a merge the way the platforms do: a stated box wins; a multiplier stated
 * alone replaces the box beneath it (the newer statement is the one drawn);
 * stating neither keeps [previous].
 */
export function lineBoxAfter(
  lineHeight: number | null | undefined,
  lineHeightPx: number | null | undefined,
  previous: number | null | undefined,
): number | null {
  if (lineHeightPx != null) return lineHeightPx;
  if (lineHeight != null) return null;
  return previous ?? null;
}

export function textStyleData(t: TextLeaf | null | undefined): NormalizedTextStyle {
  // A text style carries its ROLE name and only the fields it overrides —
  // `{"role": "headlineLarge"}` states a role and nothing else. The metrics
  // live on the scale, so they are filled in from there and the style's own
  // values win on top.
  //
  // Before this, every role-only style fell through to `textLabelOpts`'s
  // hardcoded 14, which was ALL 218 of them: `headlineLarge` (32) and
  // `labelSmall` (12) rendered the same size. Nothing caught it — the literal
  // ratchet does not count a fallback inside a helper, the field-coverage
  // guard saw the role key present and called the field reached, and the
  // harness saw a number and bound it. A guard finds a value that is wrong,
  // not a value that is uniformly wrong.
  const role = t?.role != null ? ROLES[t.role] : undefined;
  const size = t?.fontSize == null ? role?.fontSize ?? null : dimVal(t.fontSize);
  return {
    fontSize: size,
    fontWeight: t?.fontWeight ?? role?.fontWeight ?? null,
    lineHeight: t?.lineHeight ?? role?.lineHeight ?? null,
    color: colorData(t?.color),
    role: t?.role ?? null,
    letterSpacing: t?.letterSpacing ?? role?.letterSpacing ?? null,
    // The role's family only: a family the style overlays (a Command
    // shortcut, a formatted value) is not drawn on the canvas, so carrying it
    // here would turn those sets monospace and drop their roles.
    fontFamily: role?.fontFamily ?? null,
    lineHeightPx: lineBoxAfter(t?.lineHeight, t?.lineHeightPx, role?.lineHeightPx),
  };
}

// `CoreTextStyle.merge` — the right side wins on every field it states, and
// leaves the left's where it states nothing. A partial that only some entries
// of a dispatch table carry (a per-state label colour, a per-variant role) is
// merged onto its base this way rather than having one field picked out, so a
// role / weight / line-height added to that partial later lands the way the
// resolver's own merge lands it.
export function mergeTextStyleData(
  base: NormalizedTextStyle,
  over: NormalizedTextStyle,
): NormalizedTextStyle {
  return {
    fontSize: over.fontSize ?? base.fontSize,
    fontWeight: over.fontWeight ?? base.fontWeight,
    lineHeight: over.lineHeight ?? base.lineHeight,
    color: over.color ?? base.color,
    role: over.role ?? base.role,
    letterSpacing: over.letterSpacing ?? base.letterSpacing,
    // The family is the role's (see `textStyleData`), so it moves with the
    // role: a partial naming a role brings that role's family, the text face
    // (null) included.
    fontFamily: over.role != null ? over.fontFamily ?? null : over.fontFamily ?? base.fontFamily ?? null,
    lineHeightPx: lineBoxAfter(over.lineHeight, over.lineHeightPx, base.lineHeightPx),
  };
}

// Reads a field that only *some* entries of a schema v2 dispatch table
// (`variants.defaultsByVariant`/`sizes.defaultsBySize`) carry — e.g.
// button's `outline` variant sets `borderColor`/`borderWidth`, `primary`
// doesn't. TypeScript's JSON-module inference (`resolveJsonModule`) gives
// each dispatch-table entry its own exact literal shape, and a field only
// some entries have isn't visible on the `Object.entries()` union type
// without this — the alternative is scattering `'x' in v ? v.x : undefined`
// at every call site that reads an optional per-variant/per-size override.
export function optField<T>(entry: object, key: string): T | undefined {
  return (entry as Record<string, T>)[key];
}
