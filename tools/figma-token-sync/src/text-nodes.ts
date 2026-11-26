/// <reference types="@figma/plugin-typings" />

import {
  Dim,
  dimVal,
  familyTokenOf,
  monoRoleWeights,
  roleMetrics,
  type RoleMetrics,
} from './compat/v1';
import { VarLookup } from './variables';
import { fadeNode, solid, weightStyle } from './paint';

// Text nodes and the fonts they need loaded first.
//
// `figma.createText()` throws unless the font is already loaded, and the font a label
// wants comes from the type scale — so `loadFonts` runs once per command, before any
// builder, and `makeLabel` binds size/family/weight to Primitives variables rather
// than writing literals.
//
// Split out of `helpers.ts` (see the barrel note there).
export interface LabelOpts {
  size: number | Dim; // font-size (default) or dimensional-size token (px)
  colorVar?: Variable;
  opacity?: number;
  /** The token's literal RGB, for a sub-1 `opacity` — see `solid`. */
  argb?: number;
  style?: string; // Pretendard style ('Thin' | 'ExtraLight' | 'Light' | 'Regular' | 'Medium' | 'SemiBold' | 'Bold' | 'ExtraBold' | 'Black')
  rawColor?: RGB; // theme-independent literal (e.g. a destructive label's literal white)
  lineHeightPercent?: number; // role's CoreLineHeight × 100; omitted → h160 default (ad-hoc/glyph text has no role)
  /** A fixed line box in px (`CoreTextStyle.lineHeightPx` — the code roles'
   *  21px grid). Wins over `lineHeightPercent` and is written as PIXELS. */
  lineHeightPx?: number;
  // Which Primitives scale `size` binds against — see `glyphOpts` for why a
  // text-rendered glyph's size can trace to `size`, not `fontSize` (#3754
  // axis fix). Omitted/`'fontSize'` preserves the original single-scale
  // behavior every non-glyph caller already relies on.
  sizeScale?: 'fontSize' | 'size';
  // Which `Primitives/font-family/<n>` token this text renders AND binds
  // with. Omitted → `'sans'` (Pretendard), what every component builder
  // draws in. A code role's opts carry `'mono'`, and so do the docs frames'
  // code blocks — which pass `'sans'` back when that family failed to load,
  // so the binding can never name a family the node did not actually render
  // with. `makeLabel` falls back the same way when `loadFonts` could not load
  // the mono face asked for. A mono label's Hangul is drawn in the text face
  // (`paintHangulRunsSans`): the monospace face has none.
  family?: string;
  /** Typography role (`labelLarge`) — binds `font-size/<role>` and
   *  `letter-spacing/<role>` from `Semantic/Typography` when the document
   *  has them; the primitive step stays the fallback. */
  role?: string;
  /** Letter spacing as `CoreLetterSpacing`'s em ratio; written in px
   *  (`em × fontSize`, what the semantic variable holds) and bound. */
  letterSpacingEm?: number;
  /** The label sits in a box whose size does not change with the document's
   *  typography mode (an avatar's initials in its fixed diameter). A role
   *  whose size steps with the mode — the display and headline roles, which
   *  are smaller on Mobile and Tablet — is dropped, so the label binds the
   *  primitive size it draws at and keeps it in every mode, the way both
   *  platforms draw it. A role that is the same size in every mode is kept.
   *  See `roleFollowsMode`. */
  fixedSize?: boolean;
}

/**
 * Whether `role`'s size variable holds a different value in some typography
 * mode — read off the document's variable rather than a list of role names,
 * so a role the export starts stepping is caught the day it does.
 *
 * A role with no variable in this document does not follow anything: the
 * label binds the primitive either way.
 */
export function roleFollowsMode(lk: VarLookup, role: string): boolean {
  const v = lk.typographyOrNull(`font-size/${roleLeaf(role)}`);
  if (v == null) return false;
  const values = Object.values(v.valuesByMode ?? {}).map((x) => JSON.stringify(x));
  return new Set(values).size > 1;
}

/** `labelXl2` → `label-xl2`, the leaf the exporter names a role by. */
export function roleLeaf(role: string): string {
  return role.replace(/([a-z0-9])([A-Z])/g, '$1-$2').toLowerCase();
}

/** A field a role's text style states about every label it is attached to. */
export type RoleStatedField = 'size' | 'weight' | 'lineHeight' | 'letterSpacing' | 'family';

/**
 * What a label states about its own typography, in the units a label is drawn
 * in. Every field is optional: one the label does not state follows the role,
 * so it cannot depart from it.
 */
export interface StatedTypography {
  size?: number | null;
  /** The Pretendard face (`'Bold'`) — weight as the canvas draws it. */
  style?: string | null;
  lineHeightPercent?: number | null;
  /** A fixed line box in px; when stated it is the line height compared. */
  lineHeightPx?: number | null;
  /** `CoreLetterSpacing`'s em ratio. */
  letterSpacingEm?: number | null;
  /** The family token drawn (`'sans'` | `'mono'`), compared with the role's
   *  own — a code role's style draws in mono, every other in sans. */
  family?: string | null;
}

/**
 * The first field a label states differently from its role, or null when the
 * role's text style can state the label as drawn.
 *
 * A text style is one bundle — size, weight, line height, tracking and family
 * — and attaching it writes every field of that bundle onto the node. So a
 * label that departs from its role in ANY of them comes out of the attach as
 * the role, not as itself: measured on a scratch canvas with the attach's own
 * calls, a `titleSmall` label drawn a weight off its role came back at the
 * role's weight, and a `bodyMedium` label drawn at 120% came back at the
 * role's own line height. Core draws the overlay; only the canvas lost it.
 *
 * Nothing written after the attach can keep both. Writing the face or the line
 * height back onto a styled node detaches the style (measured, both fields),
 * and the node is left bound to the role's semantic size and tracking
 * variables — the shape the canvas rule names as wrong. Binding a weight
 * variable on top changes nothing that renders. So the only honest outcome is
 * the one a size departure already gets: no role, no style, the node drawn as
 * the builder states it. A text decoration is different — it is per-label,
 * and writing it back keeps the style (`text-style-attach.ts`).
 *
 * What a dropped role costs: the label binds the primitive size step, so it no
 * longer follows the role's per-mode size. Only the display and headline roles
 * change size across modes, and no Core style overlays a weight or line height
 * on one of them; an overlay there would need the role's size variable kept
 * without its style.
 *
 * An unknown role is never a departure: the table decides, and it has no row
 * to decide with.
 *
 * [metrics] is the role's row by default — the code scale, which is what a
 * library label is drawn against. A caller that knows the label draws in
 * another typography mode passes the role's row for that mode
 * (`roleMetricsIn`), so the comparison stays this one function.
 */
export function roleDeparture(
  role: string,
  stated: StatedTypography,
  metrics: RoleMetrics | undefined = roleMetrics(role),
): RoleStatedField | null {
  if (metrics == null) return null;
  if (stated.size != null && metrics.fontSize != null && stated.size !== metrics.fontSize) {
    return 'size';
  }
  if (
    stated.style != null &&
    metrics.fontWeight != null &&
    stated.style !== weightStyle(metrics.fontWeight)
  ) {
    return 'weight';
  }
  if (lineBoxesDiffer(statedLineBox(stated), roleLineBox(metrics))) return 'lineHeight';
  if (
    stated.letterSpacingEm != null &&
    metrics.letterSpacing != null &&
    Math.abs(stated.letterSpacingEm - metrics.letterSpacing) > STATED_EPSILON
  ) {
    return 'letterSpacing';
  }
  if (stated.family != null && stated.family !== familyTokenOf(metrics.fontFamily)) return 'family';
  return null;
}

// A line height in the unit it is stated in: a multiplier role's percent, or a
// fixed box's px. Two of them agree only in the same unit — a 21px box and a
// 150% line are different statements even where they happen to draw alike.
type LineBox = { unit: 'PERCENT' | 'PIXELS'; value: number } | null;

function statedLineBox(stated: StatedTypography): LineBox {
  if (stated.lineHeightPx != null) return { unit: 'PIXELS', value: stated.lineHeightPx };
  if (stated.lineHeightPercent != null) return { unit: 'PERCENT', value: stated.lineHeightPercent };
  return null;
}

function roleLineBox(metrics: { lineHeight: number | null; lineHeightPx?: number | null }): LineBox {
  if (metrics.lineHeightPx != null) return { unit: 'PIXELS', value: metrics.lineHeightPx };
  if (metrics.lineHeight != null) return { unit: 'PERCENT', value: metrics.lineHeight * PERCENT };
  return null;
}

// Either side unstated is not a departure — the unstated side follows the
// other, as a field the label does not state follows its role.
function lineBoxesDiffer(stated: LineBox, role: LineBox): boolean {
  if (stated == null || role == null) return false;
  return stated.unit !== role.unit || Math.abs(stated.value - role.value) > STATED_EPSILON;
}

// `CoreLineHeight` is a unitless multiplier; a label states it in percent.
const PERCENT = 100;
// Both sides of a comparison come from the same exported number, so they are
// equal unless the label states a different value; the tolerance only absorbs
// the float product `1.1 * 100`.
const STATED_EPSILON = 1e-6;

// Nodes whose typography role survived `roleDeparture`, waiting for a text style.
//
// `makeLabel` is synchronous and 186 call sites deep, while attaching a style
// needs `setTextStyleIdAsync` (this manifest is `documentAccess:
// "dynamic-page"`, where the property itself is read-only). Making the label
// path async to reach one await would rewrite every builder. So the label
// records itself here and `drainTextStyleAttach` attaches the queue at a point
// where every write to it is done — the call sites never learn about it, and
// `text-style-attach.ts` says where those points are and why.
//
// Only a role that survives `roleDeparture` in `makeLabel` lands here, and that
// is the whole admission test: the role is kept exactly when every field the
// label states — size, weight, line height, tracking, family — equals the
// role's own, which is exactly when a style, which carries all of them as one
// bundle, can state this label without lying about it. `applyRole` (helpers.ts)
// asks the same question of the style the opts were built from; `makeLabel`
// asks it again of the opts it is handed, because a builder can change them in
// between.
let pendingTextStyleAttach: { node: TextNode; role: string }[] = [];

/** A label whose role has passed admission, including a composed instance's
 *  label that was restyled without calling makeLabel. The entry's normal drain
 *  attaches it after all overrides, before the canvas fingerprint is taken. */
export function queueTextStyleAttach(node: TextNode, role: string): void {
  pendingTextStyleAttach.push({ node, role });
}

/** Start of a run, and after an entry that threw — drops the queued nodes
 *  rather than restyling them under whichever drain runs next. */
export function resetPendingTextStyles(): void {
  pendingTextStyleAttach = [];
}

/** Hand the queue over and clear it — a second call returns nothing. */
export function takePendingTextStyles(): { node: TextNode; role: string }[] {
  const out = pendingTextStyleAttach;
  pendingTextStyleAttach = [];
  return out;
}

// The run's attacher, installed by `generate.ts` around its entry loop. Absent
// everywhere else — the harness drive, the verify commands that build a scratch
// copy — and there a drain leaves the queue alone, which is what those callers
// have always had.
let textStyleAttach: ((items: { node: TextNode; role: string }[]) => Promise<void>) | null = null;

export function installTextStyleAttach(
  fn: ((items: { node: TextNode; role: string }[]) => Promise<void>) | null,
): void {
  textStyleAttach = fn;
}

/**
 * Attaches every queued label's style now. Called only where every write to
 * those labels is done: the yield that opens a combo, just before a yielding
 * builder's `finish()`, and after an entry's `build()` returns.
 */
export async function drainTextStyleAttach(): Promise<void> {
  if (textStyleAttach == null || pendingTextStyleAttach.length === 0) return;
  const items = pendingTextStyleAttach;
  pendingTextStyleAttach = [];
  await textStyleAttach(items);
}

export function makeLabel(text: string, lk: VarLookup, opts: LabelOpts): TextNode {
  const size = dimVal(opts.size);
  const face = opts.style ?? 'Regular';
  // The family actually drawn: a mono face `loadFonts` could not load would
  // throw on `fontName`, and the binding below must name what renders.
  const asked = opts.family ?? 'sans';
  const family = asked === 'mono' && !monoFaceUsable(face) ? 'sans' : asked;
  const t = figma.createText();
  t.fontName = { family: lk.fontFamilyName(family), style: face };
  t.setBoundVariable('fontFamily', lk.fontFamily(family));
  t.characters = text;
  // The monospace face has no Hangul, and Figma draws a missing glyph in a
  // fallback it picks itself — not the text face both platforms fall back to.
  if (family === 'mono' && hasHangul(text)) {
    paintHangulRunsSans(t, sansTargetOf(lk), { face, text });
  }
  t.fontSize = size;
  // Bind when a variable exists for this step; otherwise leave the literal
  // `fontSize` set above. A glyph whose dimension has no counterpart in the
  // target scale must still render, and the miss costs a binding rather than a
  // picture — the glyph draws at the same size either way. A throw is not
  // rolled back: the entry is reported as failed and a half-drawn component is
  // left on the page, which is a steep price for one unbound number.
  //
  // Both branches go through an `…OrNull`: `fontSizeOrNull` tries `font/size/<n>`
  // then `font-size/<n>`, the same two names in the same order as `fontSize`, so
  // the live naming is preferred without the throw. Reaching for `fontSize` here
  // would contradict the sentence above — a miss would fail the entry and leave
  // the component half-drawn rather than leave the literal.
  //
  // Semantic role first (§5-4: a control label reads `font-size/label-*`,
  // not the primitive it happens to equal), then the primitive step. A
  // dimensional-scale glyph (`sizeScale: 'size'`) has no role to bind.
  //
  // The role is judged on what THIS call draws, not on the style the opts were
  // built from: a builder may restate a field after `textLabelOpts` returns —
  // Steps draws the current step's title Bold over its role's own face — and a
  // role kept past that would queue a style that writes the role's face back.
  //
  // A label in a fixed-size box drops a role whose size follows the mode
  // (`fixedSize`): the role's variable would draw it smaller on Mobile than
  // the box both platforms draw it in.
  const role =
    opts.role != null &&
    opts.sizeScale !== 'size' &&
    !(opts.fixedSize === true && roleFollowsMode(lk, opts.role)) &&
    roleDeparture(opts.role, {
      size,
      style: opts.style,
      lineHeightPercent: opts.lineHeightPercent,
      lineHeightPx: opts.lineHeightPx,
      letterSpacingEm: opts.letterSpacingEm,
      family,
    }) == null
      ? opts.role
      : null;
  const leaf = role == null ? null : roleLeaf(role);
  if (role != null) queueTextStyleAttach(t, role);
  const fontSizeVar =
    (leaf == null ? undefined : lk.typographyOrNull(`font-size/${leaf}`)) ??
    (opts.sizeScale === 'size' ? lk.sizeOrNull(size) : lk.fontSizeOrNull(size));
  if (fontSizeVar) t.setBoundVariable('fontSize', fontSizeVar);
  applyLetterSpacing(t, lk, {
    em: opts.letterSpacingEm,
    size: size,
    // The role that survived above — null for a glyph sized on the DIMENSION
    // ladder, which has no type role to bind against, and for a label that
    // departs from its role, which binds none of the role's variables: its
    // tracking falls to the size step, as its size does above.
    role,
  });
  // A literal either way, never a node binding: the attach would only have to
  // clear it again, and a style that states the box binds it on its own layer.
  t.lineHeight =
    opts.lineHeightPx != null
      ? { unit: 'PIXELS', value: opts.lineHeightPx }
      : { unit: 'PERCENT', value: opts.lineHeightPercent ?? DEFAULT_LINE_HEIGHT_PERCENT };
  // A text node holds nothing, so its alpha is the LAYER's — bound at full
  // strength and faded here, which keeps the token on the layer where a literal
  // would have put a hex.
  t.fills = opts.rawColor
    ? [{ type: 'SOLID', color: opts.rawColor, opacity: opts.opacity ?? 1 }]
    : [solid(opts.colorVar!, 1)];
  if (!opts.rawColor) fadeNode(t, opts.opacity ?? 1);
  return t;
}

/**
 * Tracking, written the one way every path has to write it.
 *
 * Core states letter spacing as an em RATIO and multiplies it by whatever size
 * the label ends up at, so the pixels are a function of two things and neither
 * can be assumed. Three paths besides `makeLabel` re-size a text node that
 * already exists — a parent forwarding its stated style onto a composed child's
 * instance, a picker re-styling a label it cannot re-create, a validator hint —
 * and all three wrote the new SIZE and left the old tracking behind. The label
 * then reads at the right size and the wrong width: `Select` set its trigger to
 * 16 and kept the field's −0.14, which is the ratio for 14.
 *
 * Nothing else in the pipeline can see that. The size is right, the role name is
 * right, the colour is right, and the only witness is the canvas.
 *
 * The variable is bound only when the size IS the role's own. A semantic
 * `letter-spacing/<role>` variable holds pixels computed for that role's size;
 * binding it to a label one rung away would replace the ratio with a number
 * chosen for a different size — which is the failure this function exists to
 * stop, arriving through the binding instead of through the literal.
 */
export function applyLetterSpacing(
  t: TextNode,
  lk: VarLookup,
  spec: { em?: number | null; size: number; role?: string | null },
): void {
  if (spec.em == null) {
    // "No ratio stated" reads back as Figma's own untouched default
    // (`PERCENT 0`), not as whatever this node held before. Without this, a
    // node this function styled once (PIXELS, some prior size) and is asked
    // to style again with no ratio keeps the old rung's pixels sitting under
    // the new size — the exact "right size, wrong width" defect this module
    // exists to catch, reappearing through the `em == null` path instead of
    // through a stale caller. `writtenLetterSpacingPx` (fidelity.ts) reads
    // PIXELS as "a builder stated a tracking here"; leaving PIXELS behind
    // would make it lie about this node.
    t.letterSpacing = { unit: 'PERCENT', value: 0 };
    t.setBoundVariable('letterSpacing', null);
    return;
  }
  const px = spec.em * spec.size;
  t.letterSpacing = { unit: 'PIXELS', value: px };
  // Two tiers, the same shape as `fontSizeVar` in `makeLabel`: the role leaf
  // when the label kept its role's own size, else the size-keyed step
  // (`letter-spacing/size-14`). Without the second tier a label whose size
  // departed from its role — which is how every per-size ladder reaches here
  // — had a bound `fontSize` and a literal `letterSpacing` on the same node.
  //
  // The size tier binds only when the variable's value IS the literal just
  // written (`letterSpacingOrNull` compares): a literal off the curve stays a
  // literal, because a bound variable overwrites it and that would move the
  // picture. So a miss here is not a defect to paper over — it is the honest
  // signal that this label's tracking has no token value yet.
  const role = spec.role;
  const leaf = role != null && roleMetrics(role)?.fontSize === spec.size ? roleLeaf(role) : null;
  const v = (leaf == null ? undefined : lk.typographyOrNull(`letter-spacing/${leaf}`)) ??
    lk.letterSpacingOrNull(spec.size, px);
  if (v) t.setBoundVariable('letterSpacing', v);
}

/** What `loadFonts` could not load of the monospace family, for the run log. */
export interface FontLoadReport {
  /** Null when every mono face loaded. */
  monoNote: string | null;
}

/**
 * Loads the text face (all 9 weights — fatal when one is missing) and the
 * monospace faces a code label draws in (non-fatal: a mono label whose face is
 * missing draws in the text face, see `makeLabel`).
 */
export async function loadFonts(lk: VarLookup): Promise<FontLoadReport> {
  const family = lk.fontFamilyName('sans');
  try {
    for (const style of PRETENDARD_STYLES) {
      await figma.loadFontAsync({ family, style });
    }
  } catch (e) {
    throw new Error(
      `"${family}" font unavailable in this Figma environment (${String(e)}). ` +
        `Install all 9 static weights of ${family} (Thin–Black) locally — ` +
        'Figma desktop reads OS-installed fonts, so a missing weight here ' +
        'means it is not installed on this machine — then re-run this command.',
    );
  }
  return { monoNote: await loadMonoFaces(lk) };
}

// The mono faces `loadFonts` loaded this command. Null until it runs — a
// caller that never loads fonts (the harness) draws mono as asked, as it
// always has; an empty set means the family is unusable here.
let monoFaces: Set<string> | null = null;

export function monoFaceUsable(face: string): boolean {
  return monoFaces == null || monoFaces.has(face);
}

// `makeLabel` is synchronous and cannot load a face itself, so the mono faces
// a code label draws in are loaded here, up front, each on its own: one
// missing weight costs that weight, not the family. Only the faces the code
// roles state (and the docs code blocks' Regular) — a weight nobody draws in
// would only add a warning about a face no label asks for.
async function loadMonoFaces(lk: VarLookup): Promise<string | null> {
  monoFaces = new Set<string>();
  let family: string;
  try {
    family = lk.fontFamilyName('mono');
  } catch (e) {
    return `mono labels draw in the text face — no monospace family resolves in this document (${String(e)})`;
  }
  const missing: string[] = [];
  for (const style of new Set([MONO_BASE_STYLE, ...monoRoleWeights().map(weightStyle)])) {
    try {
      await figma.loadFontAsync({ family, style });
      monoFaces.add(style);
    } catch {
      missing.push(style);
    }
  }
  if (missing.length === 0) return null;
  return `mono labels in ${missing.join(' · ')} draw in the text face — "${family}" has no such face in this Figma environment`;
}

// ─── Hangul inside monospace text ───────────────────────────────────────────

/** The text face a mono label's Hangul is painted in, and the variable that
 *  states it — explicit rather than a `VarLookup`, because a consumer file
 *  reaches the variable through its library, not through local variables. */
export interface SansTarget {
  family: string;
  variable: Variable | null;
}

/** The text face of this document, as a `SansTarget`. */
export function sansTargetOf(lk: VarLookup): SansTarget {
  return { family: lk.fontFamilyName('sans'), variable: lk.fontFamily('sans') };
}

// Conjoining Jamo, compatibility Jamo and precomposed syllables. All three sit
// in the BMP, so a UTF-16 index — what `characters` and every range call count
// in — is a character index.
const HANGUL_BLOCKS: readonly (readonly [number, number])[] = [
  [0x1100, 0x11ff],
  [0x3130, 0x318f],
  [0xac00, 0xd7a3],
];

function isHangul(code: number): boolean {
  return HANGUL_BLOCKS.some(([from, to]) => code >= from && code <= to);
}

/** True when [text] holds a Hangul character. */
export function hasHangul(text: string): boolean {
  for (let i = 0; i < text.length; i++) {
    if (isHangul(text.charCodeAt(i))) return true;
  }
  return false;
}

/**
 * The maximal runs of Hangul in [text], as `[start, end)` indices. Characters
 * of different Hangul blocks next to each other are one run.
 */
export function hangulRuns(text: string): [number, number][] {
  const runs: [number, number][] = [];
  let start = -1;
  for (let i = 0; i < text.length; i++) {
    if (isHangul(text.charCodeAt(i))) {
      if (start < 0) start = i;
    } else if (start >= 0) {
      runs.push([start, i]);
      start = -1;
    }
  }
  if (start >= 0) runs.push([start, text.length]);
  return runs;
}

/**
 * Paints every Hangul run of [t] in the text face and binds the run's
 * `fontFamily` to that face's variable. Returns how many ranges it wrote.
 *
 * Both platforms fall back to the text face for a glyph the monospace face
 * lacks; Figma cannot be told a fallback and picks one itself, so the canvas
 * states it range by range. Size, line height and tracking are left alone, so
 * the Hangul stays on the label's own line grid (the code roles' 21px box).
 *
 * Each range keeps its weight: [face] when the caller knows the one face the
 * node draws in, otherwise the face of each styled segment, read back. With
 * [onlyFamily] the segments are always read back, and one in another family
 * (sans already, or a different monospace face) is left as it is.
 *
 * Writes nothing — not even a read of the segments — when the text has no
 * Hangul, so the common case costs one scan of the string.
 */
export function paintHangulRunsSans(
  t: TextNode,
  sans: SansTarget,
  o: { face?: string; text?: string; onlyFamily?: string } = {},
): number {
  const runs = hangulRuns(o.text ?? t.characters);
  if (runs.length === 0) return 0;
  let written = 0;
  for (const [start, end] of runs) {
    for (const seg of faceSegments(t, start, end, o.onlyFamily == null ? o.face : undefined)) {
      if (o.onlyFamily != null && seg.family !== o.onlyFamily) continue;
      t.setRangeFontName(seg.start, seg.end, { family: sans.family, style: textFaceOf(seg.style) });
      if (sans.variable != null) t.setRangeBoundVariable(seg.start, seg.end, 'fontFamily', sans.variable);
      written += 1;
    }
  }
  return written;
}

interface FaceSegment {
  start: number;
  end: number;
  style: string;
  /** The family the segment is drawn in; unknown when the caller named the face. */
  family?: string;
}

function faceSegments(t: TextNode, start: number, end: number, face?: string): FaceSegment[] {
  if (face != null) return [{ start, end, style: face }];
  return t.getStyledTextSegments(['fontName'], start, end).map((seg) => ({
    start: seg.start,
    end: seg.end,
    style: seg.fontName.style,
    family: seg.fontName.family,
  }));
}

/**
 * The text face's name for a weight a monospace face draws in. Families spell
 * a weight differently (`Semi Bold`, `SemiBold`), so the comparison ignores
 * spaces and case; a weight the text face has no name for keeps its own.
 */
export function textFaceOf(style: string): string {
  const key = style.replace(/\s+/g, '').toLowerCase();
  return PRETENDARD_STYLES.find((s) => s.toLowerCase() === key) ?? style;
}

const DEFAULT_LINE_HEIGHT_PERCENT = 160;

// The face a mono label draws in when nothing states a weight — the docs
// code blocks'.
const MONO_BASE_STYLE = 'Regular';

const PRETENDARD_STYLES = [
  'Thin',
  'ExtraLight',
  'Light',
  'Regular',
  'Medium',
  'SemiBold',
  'Bold',
  'ExtraBold',
  'Black',
];
