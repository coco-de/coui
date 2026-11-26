/// <reference types="@figma/plugin-typings" />

import { Color, Dim, colorData, dimVal, exportedMonoFamily } from './compat/v1';

// Variable lookup — the one place a logical collection/name pair becomes a Figma
// Variable id.
//
// Split out of `helpers.ts`, which had grown to 96 exports across nine concerns
// behind dividers that no longer described their own contents (one divider named
// "Figma component properties" covered 1082 lines holding component properties,
// instance-subtree reach, AND node identity). `helpers.ts` re-exports everything
// here, so no call site changes; new code can import the concern it actually wants.

// ─── Variable lookup ─────────────────────────────────────────────────────────

// Tolerance for `letterSpacingOrNull`'s value comparison. The exporter and
// the plugin compute the same `em × size` product from the same constants,
// but one of them round-trips through JSON (shortest-repr double) and the
// other through `components.json`'s em ratio — equal in every case seen,
// and this absorbs a last-ulp difference without letting a different curve
// value (the steps differ by ≥ 0.05px) through.
const LETTER_SPACING_PX_EPSILON = 1e-6;

// `export_figma_tokens.dart` emits the `Primitives/opacity/<pct>` ladder as OPACITY-
// scoped FLOATs holding the PERCENT (value × 100), because a FLOAT bound to a
// layer's opacity is read as 0–100. Core states an opacity as 0–1, so the lookup
// converts: the key is the percent, the argument is the Core alpha.
const OPACITY_PERCENT_SCALE = 100;

// Tolerance for the "is this alpha a whole percent" check in `opacity`. `0.07 * 100`
// is 7.000000000000001 in IEEE doubles; that float noise must still land on the
// `opacity/7` step, while a value genuinely between two steps (0.125) must not.
const OPACITY_STEP_EPSILON = 1e-6;

/** Only aliases with the same base and numeric opacity in every mode qualify.
 * Inspect values, not names: a suffix alone cannot prove rendered opacity. */
export function composedColorAlias(v: Variable): { baseId: string; alpha: number } | null {
  let result: { baseId: string; alpha: number } | null = null;
  for (const value of Object.values(v.valuesByMode ?? {})) {
    if (typeof value !== 'object' || !('color' in value) || !('opacity' in value)) return null;
    if (!('type' in value.color) || value.color.type !== 'VARIABLE_ALIAS' || typeof value.opacity !== 'number') return null;
    const current = { baseId: value.color.id, alpha: value.opacity / 100 };
    if (!Number.isFinite(current.alpha) || current.alpha < 0 || current.alpha > 1) return null;
    if (result && (result.baseId !== current.baseId || result.alpha !== current.alpha)) return null;
    result = current;
  }
  return result;
}

export const corners: VariableBindableNodeField[] = [
  'topLeftRadius',
  'topRightRadius',
  'bottomLeftRadius',
  'bottomRightRadius',
];

// Every binding call site in this plugin speaks a collection's logical name
// ("Primitives" / "Semantic") while the library file spells it with a space
// after the slash ("Semantic/ Color"). This folds that away so both resolve
// identically — "Semantic/ Color" and "Semantic" are the same collection to
// us. It also strips a leading ordering prefix ("0. ", "1-1. "): the library
// does not number its collections, but a file that still does — one Import
// has not renamed yet, or a token export taken from it — must resolve the
// same rather than lose every binding (`withoutOrderingPrefix`).
//
// `export_figma_tokens.dart` additionally gives Semantic/Color its own
// collection per registered `CoreBrand` ("Semantic/ Color · CoUI",
// "Semantic/ Color · Demo Brand" — brand being an axis independent of
// light/dark, see that file's `_buildBrandCollections`). This strips that
// " · <Brand>" suffix too, so every existing unqualified `Semantic` call
// site keeps resolving without change as long as the exported file
// carries exactly one brand.
//
// A second real brand makes this fold ambiguous, and — this is the part
// worth spelling out because it is not the fix it looks like — passing a
// brand-qualified name to `get`/`tryGet` does NOT disambiguate it. Both
// the index side (this constructor) and the query side (`get`/`tryGet`
// below) run the SAME `canonicalCollection`, so `get('Semantic/ Color ·
// CoUI', 'color/surface')` and `get('Semantic/ Color · Demo Brand',
// 'color/surface')` fold to the identical `Semantic/color/surface`
// key and return the identical (whichever-was-indexed-last) `Variable` —
// verified directly against a real 2-brand `tokens.figma.json` build, not
// assumed. There is no string you can pass through this class's public
// API that reaches the shadowed brand's variable; the constructor has
// already thrown it away by the time any call site runs.
//
// The actual fix, when a second real brand needs to build components, is
// upstream of this class: construct a separate `VarLookup` per brand,
// each fed only that brand's own Semantic/Color collection (plus the
// brand-agnostic ones) — every existing unqualified `sem()`/`get(
// 'Semantic', ...)` call site then resolves correctly with zero changes,
// because the ambiguous collection was never in that instance's `vars` to
// begin with. Nothing wires that filtering in yet.
export function canonicalCollection(name: string): string {
  let n = withoutOrderingPrefix(name);
  n = n.replace(/\/\s+/g, '/');
  n = n.replace(/\s*·\s*.+$/, '');
  if (n === 'Semantic/Color') return 'Semantic';
  return n;
}

// A collection name without its leading ordering prefix ("0. Primitives" →
// "Primitives", "1-1. Semantic/ Color · CoUI" → "Semantic/ Color · CoUI").
// Unlike `canonicalCollection` it keeps the slash spacing and the brand
// suffix, so the result is still a real collection name — Import uses it to
// find a numbered collection the token file now names without the number,
// and renames that one in place instead of creating a second.
export function withoutOrderingPrefix(name: string): string {
  return name.replace(/^\d+(?:-\d+)*\.\s*/, '');
}

/** What Import should do with the file's collections before it upserts. */
export interface CollectionRenamePlan {
  /** Token-file name → the existing collection's current name. */
  rename: Map<string, string>;
  /** Token-file name → every existing name that could be it. None renamed. */
  ambiguous: Map<string, string[]>;
}

// Which existing collection each token-file collection is, when its name in
// the file still carries an ordering prefix. An exact name wins and needs no
// plan. Failing that, the one collection whose name differs only by that
// prefix ("0. Primitives" for "Primitives") is the same collection under its
// old name: Import renames it in place, which keeps its id and its library
// key, so every node bound to its variables — here and in files consuming the
// published library — stays bound. Creating a second, unprefixed collection
// instead would leave every binding on the old one and the panel holding both.
//
// A collection some token-file name matches exactly is never a candidate for
// another, and two candidates for one name are not guessed between — the
// wrong guess moves a whole collection's bindings onto the wrong name.
export function planCollectionRenames(
  existing: readonly string[],
  wanted: readonly string[],
): CollectionRenamePlan {
  const rename = new Map<string, string>();
  const ambiguous = new Map<string, string[]>();
  const taken = new Set(existing.filter((n) => wanted.indexOf(n) >= 0));
  for (const name of wanted) {
    if (taken.has(name)) continue;
    const candidates = existing.filter(
      (n) => !taken.has(n) && n !== name && withoutOrderingPrefix(n) === name,
    );
    if (candidates.length === 1) rename.set(name, candidates[0]);
    else if (candidates.length > 1) ambiguous.set(name, candidates);
  }
  return { rename, ambiguous };
}

// Resolves variable objects by `Collection/name` so component bindings don't
// depend on hardcoded IDs. Collection names are canonicalized (see
// `canonicalCollection`) on both the index and the query side. Throwing
// getters (`sem`/`space`/…) fail loud when a token is missing; `*OrNull`
// variants are for optional bindings.
/** The control ladder (`CoreControlSize`), height → the `control-size/<tier>`
 *  row that names it. Numbers rather than an import because the plugin reads
 *  no Dart; `selftest-control-rows` pins this table against the exporter's
 *  source so the two cannot drift. */
export const CONTROL_ROW_TIERS: Readonly<Record<number, string>> = {
  24: 'xs',
  32: 'sm',
  40: 'md',
  48: 'lg',
  56: 'xl',
  64: 'xl2',
};

/** The `stroke/<key>` spelling of a width.
 *
 * Figma refuses a `.` in a variable name (`createVariable` throws "invalid
 * variable name"), so the hairline `0.5` is `0_5` — the spelling the code names
 * (`stroke0_5`, `--coui-stroke-width-0_5`) and the exporter's variable already
 * use. A whole-number width is unchanged. */
export function strokeKey(n: number): string {
  return String(n).replace('.', '_');
}

export class VarLookup {
  private byKey = new Map<string, Variable>();
  private opacityAliases = new Map<string, Variable>();
  constructor(
    vars: Variable[],
    collById: Map<string, string>,
    private collectionsById: Map<string, VariableCollection> = new Map(),
  ) {
    for (const v of vars) {
      const coll = collById.get(v.variableCollectionId);
      if (coll) this.byKey.set(`${canonicalCollection(coll)}/${v.name}`, v);
    }
  }
  tryGet(coll: string, name: string): Variable | undefined {
    return this.byKey.get(`${canonicalCollection(coll)}/${name}`);
  }
  get(coll: string, name: string): Variable {
    const v = this.byKey.get(`${canonicalCollection(coll)}/${name}`);
    if (!v) throw new Error(`variable not found: ${coll}/${name}`);
    return v;
  }
  sem(name: string): Variable {
    return this.get('Semantic', `color/${name}`);
  }
  /** A paint-only opacity alias. The base token still resolves in the consumer's
   * mode; opacity is part of the COLOR variable, not a faded content layer.
   * Kept in the base collection so its mode follows the same light/dark switch. */
  semWithOpacity(name: string, opacity: number): Variable {
    if (!Number.isFinite(opacity) || opacity < 0 || opacity > 1) {
      throw new Error(`invalid color opacity: ${opacity}`);
    }
    if (opacity === 1) return this.sem(name);
    const base = this.sem(name);
    const derivedName = `${base.name}/opacity/${opacity * 100}`;
    const key = `Semantic/${derivedName}`;
    let derived = this.tryGet('Semantic', derivedName) ?? this.opacityAliases.get(key);
    if (!derived) {
      // dynamic-page forbids the deprecated collection-ID overload even when
      // the ID is valid. Use the collection object loaded by Generate.
      const collection = this.collectionsById.get(base.variableCollectionId);
      if (!collection) throw new Error(`color opacity collection not loaded: ${base.variableCollectionId}`);
      derived = figma.variables.createVariable(derivedName, collection, 'COLOR');
      this.opacityAliases.set(key, derived);
    }
    derived.scopes = ['FRAME_FILL', 'SHAPE_FILL'];
    derived.description = 'CoUI generated paint opacity alias; regenerate from the base color token.';
    for (const modeId of Object.keys(base.valuesByMode)) {
      derived.setValueForMode(modeId, {
        color: figma.variables.createVariableAlias(base),
        opacity: opacity * 100,
      });
    }
    return derived;
  }
  /** The whole-percent step of a Core alpha (0–1) — the `<pct>` of `opacity/<pct>` —
   *  or `undefined` when the alpha falls between two steps. One arithmetic for the
   *  strict and the tolerant lookup below, so they cannot disagree about which
   *  strengths are rungs. */
  private opacityStep(alpha: number): number | undefined {
    const percent = alpha * OPACITY_PERCENT_SCALE;
    const step = Math.round(percent);
    if (!Number.isFinite(alpha) || Math.abs(percent - step) > OPACITY_STEP_EPSILON) return undefined;
    return step;
  }
  /** `Primitives/opacity/<pct>` for a Core opacity (0–1). The ladder is whole
   *  percents, so an alpha that falls between two steps throws instead of binding
   *  the neighbouring step. Takes the Core alpha, not the percent: the percent is
   *  the variable's value, and the node a binding drives reads back as 0–1. */
  opacity(alpha: number): Variable {
    const step = this.opacityStep(alpha);
    if (step === undefined) {
      throw new Error(`opacity: ${alpha} is not a whole percent — the opacity ladder has no such step`);
    }
    return this.get('Primitives', `opacity/${step}`);
  }
  /** The `opacity/<n>` step that holds a strength of [alpha] (0–1), or
   *  `undefined` when the scale has no such step — a strength between steps
   *  (88%, say) is a legitimate thing for a colour to state and has nothing to
   *  bind to, so the caller keeps the literal rather than failing the entry.
   *  Same shape as [spaceOrNull] / [sizeOrNull], for the same reason. */
  /** `Semantic/ Effect` › `opacity/<role>` — the opacity roles
   * (`CoreOpacity.hover` · `.pressed` · `.scrim`), or undefined in a document
   * that has not imported them. */
  stateOpacityOrNull(role: 'hover' | 'pressed' | 'scrim'): Variable | undefined {
    return this.tryGet('Semantic/Effect', `opacity/${role}`);
  }
  opacityOrNull(alpha: number): Variable | undefined {
    const step = this.opacityStep(alpha);
    return step === undefined ? undefined : this.tryGet('Primitives', `opacity/${step}`);
  }
  /** `space/<n>` for spacing — a padding, a gap, an item spacing — from
   *  `Semantic/ Dimension` when the document has it, else the primitive. That
   *  collection holds one mode per density and aliases each step to the one
   *  the density draws, so a gap bound through it follows the density a frame
   *  pins; under the default density every alias is the primitive itself, so
   *  the bind draws the same number. Not for a dimension that merely sits on
   *  the spacing ladder — see [spaceLadder]. */
  space(n: number): Variable {
    return (
      this.tryGet('Semantic/Dimension', `space/${n}`) ??
      this.get('Primitives', `space/${n}`)
    );
  }
  /** [space] when the scale has that step, `undefined` when it does not —
   *  the same shape as [sizeOrNull] / [fontSizeOrNull] and for the same
   *  reason: a component may legitimately state a value the primitive ladder
   *  has no step for (Toggle's 3px thumb inset), and a throw there fails the
   *  whole entry over a number that renders correctly unbound. */
  spaceOrNull(n: number): Variable | undefined {
    return (
      this.tryGet('Semantic/Dimension', `space/${n}`) ??
      this.tryGet('Primitives', `space/${n}`)
    );
  }
  /** The `Primitives/space/<n>` step itself, for a dimension — a minimum
   *  height, a bar's height, a minimum width — that sits on the spacing
   *  ladder but is not spacing. A density does not move it on either
   *  platform, so it must not bind through the density rows [space] reads:
   *  the canvas would shrink a box under `compact` that the code draws the
   *  same size. */
  spaceLadder(n: number): Variable {
    return this.get('Primitives', `space/${n}`);
  }
  /** One field of one layer of a shadow step under each surface style —
   *  `Semantic/ Surface/shadow/<step>/<layer>/<field>`, where `<layer>` is the
   *  layer index or `<index>-mirror` and `<field>` is `x` · `y` · `blur` ·
   *  `color`. `undefined` in a document imported before the rows existed. */
  shadowRowOrNull(step: string, layer: string, field: 'x' | 'y' | 'blur' | 'color'): Variable | undefined {
    return this.tryGet('Semantic/Surface', `shadow/${step}/${layer}/${field}`);
  }
  /** What a surface style gives a surface of [role] (`content` · `functional`)
   *  — `Semantic/ Surface/material/<role>/<field>`: the share of the fill that
   *  shows (a percent, as `opacity/*` holds it), the backdrop blur radius, and
   *  whether the surface refracts (BOOLEAN). `undefined` in a document imported
   *  before the rows existed. */
  materialRowOrNull(role: string, field: 'fill-opacity' | 'backdrop-blur' | 'glass'): Variable | undefined {
    return this.tryGet('Semantic/Surface', `material/${role}/${field}`);
  }
  /** One field of layer [n] of the inset rim a surface style adds —
   *  `Semantic/ Surface/material/rim/<n>/<field>`. `undefined` past the last
   *  layer the export carries, and in a document that predates the rows. */
  materialRimRowOrNull(n: number, field: 'x' | 'y' | 'blur' | 'color'): Variable | undefined {
    return this.tryGet('Semantic/Surface', `material/rim/${n}/${field}`);
  }
  /** The boundary a surface style gives a surface that draws none —
   *  `Semantic/ Surface/material/control-border`, 0 under a style that gives
   *  none. `undefined` in a document that predates the row. */
  controlBorderOrNull(): Variable | undefined {
    return this.tryGet('Semantic/Surface', 'material/control-border');
  }
  /** One field of layer [n] of the cast a surface style gives a control that
   *  casts none — `Semantic/ Surface/material/control-shadow/<n>/<field>`.
   *  `undefined` past the last layer, and in a document that predates the rows. */
  controlShadowRowOrNull(n: number, field: 'x' | 'y' | 'blur' | 'color'): Variable | undefined {
    return this.tryGet('Semantic/Surface', `material/control-shadow/${n}/${field}`);
  }
  /** A control row's height from `Semantic/ Dimension/control-size/<tier>`,
   *  or `undefined` when [n] is not a rung of the control ladder or the
   *  document predates the row. The row a density moves — the caller keeps
   *  the literal height when this is `undefined`, so the box still draws. */
  controlHeightOrNull(n: number): Variable | undefined {
    const tier = CONTROL_ROW_TIERS[n];
    return tier === undefined ? undefined : this.tryGet('Semantic/Dimension', `control-size/${tier}`);
  }
  // `size/<n>` is the independent 24-token dimension ladder
  // (CoUI_Size_Token_Specification §1 — 4–128px, banded intervals);
  // `export_figma_tokens.dart` emits it WIDTH_HEIGHT-scoped alongside
  // `space/<n>` (GAP-scoped). Dimension bindings prefer `size/<n>`; the
  // `space/<n>` fallback covers (a) a document whose Variables predate
  // the size ladder (re-Import refreshes it) and (b) dimension values
  // that only exist on the space ladder (>128px container constraints).
  size(n: number): Variable {
    const v = this.tryGet('Primitives', `size/${n}`);
    if (v) return v;
    return this.get('Primitives', `space/${n}`);
  }
  sizeOrNull(n: number): Variable | undefined {
    const v = this.tryGet('Primitives', `size/${n}`);
    if (v) return v;
    return this.tryGet('Primitives', `space/${n}`);
  }
  /** `icon-size/<n>` from `Component` — the `CoreIconSize` step an icon slot
   *  is drawn at, or `undefined` when [n] is no step or the document predates
   *  the row. The slot then keeps its literal side, so the icon still draws. */
  iconSizeOrNull(n: number): Variable | undefined {
    return this.tryGet('Component', `icon-size/${n}`);
  }
  // `layout/<n>` (WIDTH_HEIGHT-scoped) — a panel or overlay bound: a
  // dialog's max width, a list's scroll ceiling, an inline panel's floor.
  // No fallback onto `space/<n>`: a bound that lands on the space ladder is
  // the exact mis-routing `CoreLayout` exists to end, so a document that
  // lacks the variable should fail here (re-Import creates it) rather than
  // bind the number under the wrong name.
  layout(n: number): Variable {
    return this.get('Primitives', `layout/${n}`);
  }
  /** `radius/<n>` from `Semantic/ Dimension`, else `Semantic/ Surface`, else
   *  the primitive. The density rows alias the style rows, which alias the
   *  primitive the style lands on — so a corner bound here follows both the
   *  density and the style a frame pins, composed in code's order (density
   *  first, then the style). Under the default density and style every alias
   *  is the primitive itself, so the bind draws the same number. A document
   *  imported before either collection existed binds the next tier down. */
  radius(n: number): Variable {
    return (
      this.tryGet('Semantic/Dimension', `radius/${n}`) ??
      this.tryGet('Semantic/Surface', `radius/${n}`) ??
      this.get('Primitives', `radius/${n}`)
    );
  }
  /** `radius/<n>` when the ladder has that step, `undefined` when it does not —
   *  the same lookup as [radius], for a corner derived from another (a focus
   *  ring's `corner + align`) that can land off the ladder. A throw there fails
   *  the whole entry over a number that renders fine unbound. */
  radiusOrNull(n: number): Variable | undefined {
    return (
      this.tryGet('Semantic/Dimension', `radius/${n}`) ??
      this.tryGet('Semantic/Surface', `radius/${n}`) ??
      this.tryGet('Primitives', `radius/${n}`)
    );
  }
  /** `stroke/<n>` — the same two-tier lookup as [radius], for line widths a
   *  surface style may floor. */
  stroke(n: number): Variable {
    const key = `stroke/${strokeKey(n)}`;
    return this.tryGet('Semantic/Surface', key) ?? this.get('Primitives', key);
  }
  /** `stroke/<n>` when the ladder has that step, `undefined` when it does not —
   *  the same shape as [spaceOrNull] / [sizeOrNull], for a line thickness that
   *  may legitimately name a step a document predating the group lacks. A throw
   *  there fails the whole entry over a number that renders fine unbound. */
  strokeOrNull(n: number): Variable | undefined {
    const key = `stroke/${strokeKey(n)}`;
    return this.tryGet('Semantic/Surface', key) ?? this.tryGet('Primitives', key);
  }
  fontSize(n: number): Variable {
    // Live naming (`font/size/16`) first; `font-size/16` covers files
    // imported before the font group was folded.
    const v = this.tryGet('Primitives', `font/size/${n}`);
    if (v) return v;
    return this.get('Primitives', `font-size/${n}`);
  }
  /** A mode of the `Semantic/ Typography` collection by name (`Mobile` ·
   *  `Tablet` · `Desktop`) and the collection object
   *  `setExplicitVariableModeForCollection` takes. A frame pinned to a tier
   *  mirrors `TypographyTierScope(tier:)` in the widget: the collection's own
   *  default is the first mode (Mobile), so an unpinned heading role draws its
   *  mobile size. `undefined` when the document has no such collection or
   *  mode (a file imported before the tier axis existed). */
  typographyTierMode(tier: 'Mobile' | 'Tablet' | 'Desktop'): { collection: VariableCollection; modeId: string } | undefined {
    for (const [key, v] of this.byKey) {
      if (!key.startsWith('Semantic/Typography/')) continue;
      const collection = this.collectionsById.get(v.variableCollectionId);
      const mode = collection?.modes.find((m) => m.name === tier);
      return collection && mode ? { collection, modeId: mode.modeId } : undefined;
    }
    return undefined;
  }
  /** A `Semantic/ Typography` variable by its own name —
   *  `font-size/label-large`, `letter-spacing/label-xl2`. `undefined` when
   *  the document has no such role (a file imported before the role
   *  existed), so a label falls back to the primitive step it always bound.
   *  Semantic first is the point: the primitive `font/size/14` says "14",
   *  the role says "the control label", and only the second one moves when
   *  the design system retunes the role (Button · Menu 개편 §5-4). */
  typographyOrNull(name: string): Variable | undefined {
    return this.tryGet('Semantic/Typography', name);
  }
  /** The size-keyed tracking variable (`letter-spacing/size-14`) for a
   *  label rendering at `size` px whose tracking literal is `px` — the
   *  second tier `makeLabel` reaches for when the label has no role leaf
   *  (a stated field departed from the role and dropped it, see
   *  `roleDeparture`).
   *
   *  Returned ONLY when every mode of the variable holds `px` (within
   *  1e-6). The variable states the optical curve at that size; a label
   *  whose literal is off the curve (a role's em ratio carried onto a
   *  size the curve tracks differently, or an explicit `letterSpacing`)
   *  must keep its literal — binding would overwrite it and change the
   *  picture. Value-compared, so the binding is by construction a no-op
   *  on the render: the literal and the variable agree. `undefined` when
   *  the document has no such step, the same shape as `fontSizeOrNull`. */
  letterSpacingOrNull(size: number, px: number): Variable | undefined {
    const v = this.tryGet('Semantic/Typography', `letter-spacing/size-${size}`);
    if (!v) return undefined;
    const values = Object.values(v.valuesByMode);
    if (values.length === 0) return undefined;
    for (const raw of values) {
      if (typeof raw !== 'number' || Math.abs(raw - px) > LETTER_SPACING_PX_EPSILON) {
        return undefined;
      }
    }
    return v;
  }
  fontSizeOrNull(n: number): Variable | undefined {
    // Same two names as `fontSize` above, same order.
    const v = this.tryGet('Primitives', `font/size/${n}`);
    if (v) return v;
    return this.tryGet('Primitives', `font-size/${n}`);
  }
  fontFamily(role: string): Variable {
    // Legacy files key by role (`font-family/sans`). The live library
    // keys by the family name itself (`font/family/Pretendard`).
    const legacy = this.tryGet('Primitives', `font-family/${role}`);
    if (legacy) return legacy;
    // The mono role is the family the export names, matched exactly. Import
    // never deletes a variable, so a document that moved monospace faces
    // still holds the old one — and "the first family with Mono in its name"
    // would then bind code text to whichever of the two sorts first.
    const monoFamily = role === 'mono' ? exportedMonoFamily() : null;
    if (monoFamily != null) {
      const exact = this.tryGet('Primitives', `font/family/${monoFamily}`);
      if (exact) return exact;
      throw new Error(
        `variable not found: Primitives/font/family/${monoFamily} — run Import ` +
          '(a monospace family the export no longer names is not it)',
      );
    }
    // Otherwise by convention: monospace families self-identify with "Mono"
    // in their name, and the sans role is the one that doesn't. An export
    // naming no monospace family leaves mono to this too, and then two
    // candidates are a question this cannot answer.
    const families: Variable[] = [];
    this.byKey.forEach((v, key) => {
      if (key.startsWith('Primitives/font/family/')) families.push(v);
    });
    const isMono = (v: Variable) => /mono/i.test(v.name);
    const matches = families.filter((v) => (role === 'mono' ? isMono(v) : !isMono(v)));
    if (role === 'mono' && matches.length > 1) {
      throw new Error(
        `${matches.length} monospace families (${matches.map((v) => v.name).join(', ')}) ` +
          'and the export names none — run Import with a current export',
      );
    }
    const match = matches[0];
    if (!match) {
      throw new Error(
        `variable not found: Primitives/font-family/${role} (and no ` +
          `font/family/* variable matches the "${role}" role)`,
      );
    }
    return match;
  }
  // The literal family name (e.g. "Pretendard"), for call sites that need the
  // string up front — `figma.loadFontAsync` / `TextNode.fontName` — not just
  // a bound reference. Primitives is a single-mode ("Value") collection, so
  // the first (only) mode value is the answer. Fails loud on an empty value
  // (`font-family/serif` is deliberately '' — TBD in coui_core) rather than
  // handing a builder a font name that can never load.
  fontFamilyName(name: string): string {
    const v = this.fontFamily(name);
    const raw = Object.values(v.valuesByMode)[0];
    if (typeof raw !== 'string' || raw === '') {
      throw new Error(
        `${v.name} is empty or not a string — coui_core has no ` +
          `family assigned yet (see CoreFontFamily.${name}).`,
      );
    }
    return raw;
  }
}
