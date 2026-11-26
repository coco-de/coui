// Variant identity safety net (#3741 — S-a · S-b).
//
// S-a: a Figma VARIANT's only identity is the string name of its child
// component (`plugin-api.d.ts:9429` excludes 'VARIANT' from the auto-suffixed
// property types, and `variantProperties` is a readonly derived value). If a
// designer renames a variant in the Figma UI, or a future code change drops
// one, name-based reuse can silently miss it. This module never auto-adjusts
// on a mismatch — it reports and throws (`VariantIdentityError`), because the
// alternative (guess-and-fix) risks destroying instance links in files this
// plugin never touches directly.
//
// S-b: `ComponentSetNode.appendChild` type-checks (inherited from
// `ChildrenMixin`) but is not documented as a first-class "add a variant"
// operation. After every append this module reads `variantProperties` back
// and aborts on `null` rather than silently falling back to
// `combineAsVariants` (which would mint a new `key` for the whole set).
//
// Deliberately figma-API-free (no `/// <reference>`, no global `figma.*`
// calls) so the pure logic here can run — and be broken on purpose — under
// plain Node via `npm run selftest`. See scripts/selftest-variant-safety.ts.

export class VariantIdentityError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'VariantIdentityError';
  }
}

// Parses Figma's `"Axis1=Value1, Axis2=Value2"` variant-name convention into
// a map. Throws on a segment with no `=` — a malformed name is itself a
// signal something upstream (a builder, or a manual Figma rename) drifted
// from the convention every builder in this plugin relies on.
export function parseVariantKey(name: string): Record<string, string> {
  const out: Record<string, string> = {};
  for (const raw of name.split(',')) {
    const segment = raw.trim();
    if (!segment) continue;
    const eq = segment.indexOf('=');
    if (eq < 0) {
      throw new VariantIdentityError(
        `malformed variant name segment "${segment}" in "${name}" — expected "Axis=Value"`,
      );
    }
    out[segment.slice(0, eq).trim()] = segment.slice(eq + 1).trim();
  }
  return out;
}

function sameKeys(a: Record<string, string>, b: Record<string, string>): boolean {
  const aKeys = Object.keys(a);
  const bKeys = Object.keys(b);
  if (aKeys.length !== bKeys.length) return false;
  for (const k of aKeys) {
    if (a[k] !== b[k]) return false;
  }
  return true;
}

// The half of S-b that needs no set. A member about to be appended must carry
// a name that parses and that this builder declared — anything else is a name
// flattened by a detach (`Button/primary/xs`) or changed by hand, and the set
// would refuse it or take it under axes nobody asked for. Checked on the loose
// member BEFORE the append, so a bad name fails on its own instead of after it
// has entered a 972-member set and every member has been re-derived around it.
export function verifyLooseVariantName(
  name: string,
  expected: ReadonlySet<string>,
  context: string,
): void {
  parseVariantKey(name);
  if (!expected.has(name)) {
    throw new VariantIdentityError(
      `${context}: "${name}" — a member about to be appended carries a name this ` +
        `builder never declared (flattened by a detach, or renamed by hand). ` +
        `Refusing before it enters the set.`,
    );
  }
}

// The S-b check. `actual` is whatever `child.variantProperties` reads back
// as immediately after `appendChild`/`combineAsVariants` — `null` per the
// typings means Figma did not (yet, or ever) recognize the child as a valid
// variant of the set. Any mismatch aborts; nothing here retries or falls
// back to `combineAsVariants` — that decision belongs to the caller once it
// has decided the whole set cannot be trusted anymore.
export function verifyAppendedVariant(
  actual: Record<string, string> | null | undefined,
  expectedName: string,
  context: string,
): void {
  const expected = parseVariantKey(expectedName);
  if (actual == null) {
    throw new VariantIdentityError(
      `${context}: "${expectedName}" — variantProperties read back null after append. ` +
        `Refusing to fall back to combineAsVariants (that would mint a new key for the ` +
        `whole set). Investigate before retrying.`,
    );
  }
  if (!sameKeys(expected, actual)) {
    throw new VariantIdentityError(
      `${context}: "${expectedName}" — variantProperties read back ` +
        `${JSON.stringify(actual)}, expected ${JSON.stringify(expected)}.`,
    );
  }
}

// The S-a check. `existingNames` are the variant-child names already on the
// set (before this run); `wantedNames` are the names this run's builder is
// about to produce. Names present in `existingNames` but not `wantedNames`
// are NOT deleted by anything in this module — the caller (mountSet) is
// expected to throw before touching the set when this returns any
// `unexplained` entries, per "보고 후 중단 — 자동 적용하지 않는다".
/** One member name a set carries more than once, with how many times. */
export interface DuplicateVariantName {
  name: string;
  count: number;
}

/**
 * Member names a component set carries more than once.
 *
 * Two members claiming the same combination puts the SET into Figma's
 * "existing errors" state, and in that state every property read on it throws
 * (`in get_componentPropertyDefinitions: Component set has existing errors`).
 * So this is not a cosmetic duplication: one such set makes the plugin fail on
 * whatever command reaches it, and the error names the set without saying what
 * is wrong with it.
 *
 * It is not self-healing either, on purpose. `mountSet` keys its recycle map by
 * name, so for each duplicated name it recycles exactly one member and leaves
 * the twin untouched — the module never deletes a persistent node on its own
 * account (see the note above the orphan scan in `identity.ts`). The pair
 * therefore survives every subsequent run, and the copy the builder keeps
 * updating is not necessarily the copy live instances point at.
 *
 * Takes names rather than a `ComponentSetNode` so this module stays
 * Figma-API-free and testable under plain Node, like everything else here.
 */
export function findDuplicateVariantNames(
  memberNames: readonly string[],
): DuplicateVariantName[] {
  const counts = new Map<string, number>();
  for (const name of memberNames) counts.set(name, (counts.get(name) ?? 0) + 1);
  const out: DuplicateVariantName[] = [];
  for (const [name, count] of counts) if (count > 1) out.push({ name, count });
  return out;
}

/**
 * The sentence a caller shows for [findDuplicateVariantNames] output.
 *
 * Says the count first because that is the number a reader acts on, and names
 * a few examples because "96 duplicates" alone does not tell anyone which
 * generation to look at. Deliberately does NOT suggest deleting anything: the
 * two copies are rarely interchangeable — instances pin one of them — and
 * picking for the caller is the guess this module exists to avoid.
 */
export function describeDuplicateVariants(
  setName: string,
  duplicates: readonly DuplicateVariantName[],
): string {
  const total = duplicates.reduce((sum, d) => sum + d.count - 1, 0);
  const sample = duplicates.slice(0, 3).map((d) => `${d.name} (×${d.count})`);
  return (
    `${setName}: ${duplicates.length} member name(s) appear more than once — ` +
    `${total} surplus member(s). Figma marks the set as having errors and every ` +
    `property read on it throws, so any command reaching this set fails. ` +
    `Examples: ${sample.join(' | ')}${duplicates.length > 3 ? ' …' : ''}. ` +
    `Resolve by hand: decide which copy live instances point at, then remove the ` +
    `other. Nothing here removes a member on its own account.`
  );
}

export interface VariantDiff {
  missing: string[]; // wanted, not present yet — fine, these get appended
  unexplained: string[]; // present, no longer wanted, no rename explains it
}

export function diffVariantNames(
  existingNames: readonly string[],
  wantedNames: readonly string[],
  /** (from, to) pairs already applied via applyPendingVariantRenames — an
   *  entry here means the rename already happened in place, so its `from`
   *  should not still be in `existingNames`. Passed through only so the
   *  error message can explain a leftover distinctly from a genuine drop. */
  knownRenames: ReadonlyArray<{ from: string; to: string }>,
): VariantDiff {
  const wanted = new Set(wantedNames);
  const renamedFrom = new Set(knownRenames.map((r) => r.from));
  const missing = wantedNames.filter((n) => !existingNames.includes(n));
  const unexplained = existingNames.filter((n) => !wanted.has(n) && !renamedFrom.has(n));
  return { missing, unexplained };
}

// ─── Is the rename table COMPLETE? ──────────────────────────────────────────
//
// Gaining an axis renames EVERY existing member, so a `Variant × Size ×
// Disabled` set that gains `Focus` needs 24 entries and not one fewer. Nothing
// checked that. `diffVariantNames` cannot: it is handed the names a run's
// builder wants and the names a page already has, and a page in the test loop
// is deleted before every run — so on the only path that exercises this
// mechanism there is no existing set to compare against, and the two halves of
// a half-written table look identical to a complete one.
//
// The failure that leaves behind is not a crash. A member whose rename entry is
// missing is `unexplained` (→ `mountSet` throws, so that entry is named as
// failed in the run log), and a member renamed to a name the builder does not
// produce is WORSE — `diffVariantNames` suppresses it from `unexplained`
// precisely BECAUSE it is some entry's `from`, and `mountSet` deletes nothing,
// so it survives as a silent extra member under a stale name.
//
// This audits the table against the names the builder really produces, which is
// why its caller is the runtime harness (scripts/selftest-registry-runtime.ts)
// rather than this module: only a driven builder knows its member list.
//
// WHAT IT CANNOT SEE: a set that gained an axis and has NO entries at all. With
// no history to compare against, "this component never needed a rename" and
// "someone forgot the whole generation" are the same input here. That case is
// the one `mountSet`'s S-a check does catch on a real page — every old member
// comes back `unexplained` and the component refuses to build. The gap this
// closes is the half-written table, which S-a cannot see (a listed `from`
// suppresses the alarm) and no page in the test loop can reach.
export interface RenameAudit {
  /** Old-axis names a generation of entries must explain, and none does. */
  unexplained: string[];
  /** Entries whose `to` is neither a member the builder produces nor the
   *  `from` of a later generation (a two-hop chain's middle name). */
  dangling: string[];
  /** Generations whose completeness cannot be decided — see below. */
  unprojectable: string[];
}

function axisNames(name: string): string[] {
  return Object.keys(parseVariantKey(name));
}

/** `name` reduced to just `axes`, in `axes` order. `''` if it has none of them. */
function project(name: string, axes: readonly string[]): string {
  const got = parseVariantKey(name);
  return axes
    .filter((a) => got[a] !== undefined)
    .map((a) => `${a}=${got[a]}`)
    .join(', ');
}

export function auditVariantRenames(
  /** Variant names this component's builder produces right now. */
  memberNames: readonly string[],
  /** Every VARIANT_RENAMES entry for this one component. */
  renames: ReadonlyArray<{ from: string; to: string }>,
): RenameAudit {
  const out: RenameAudit = { unexplained: [], dangling: [], unprojectable: [] };
  if (renames.length === 0 || memberNames.length === 0) return out;

  // A component accumulates one GENERATION of entries per axis gain, and they
  // chain: TextField's `Variant=…, Size=…` entries point at names that its
  // later `…, Disabled=…` entries then rename again. Grouping by the axes an
  // entry's `from` carries separates the generations; walking them widest-first
  // walks the chain backwards, each generation's target being the previous
  // one's sources.
  //
  // Grouped by a SORTED key and projected in the `from`'s own order. A Figma
  // variant name lists its axes in the set's declaration order, so projecting
  // alphabetically produced `Disabled=false, Variant=filled` against a table
  // that says `Variant=filled, Disabled=false` — every entry read as missing,
  // and the six it named were the six that were there. Sorting is right for
  // grouping (order must not split one generation in two) and wrong for the
  // comparison, which is against a real name.
  const byAxes = new Map<string, { axes: string[]; entries: { from: string; to: string }[] }>();
  for (const r of renames) {
    const axes = axisNames(r.from);
    const key = [...axes].sort().join('|');
    const bucket = byAxes.get(key);
    if (bucket) bucket.entries.push(r);
    else byAxes.set(key, { axes: axes, entries: [r] });
  }
  const generations = [...byAxes.keys()].sort(
    (a, b) => b.split('|').length - a.split('|').length,
  );

  // Where a `to` is allowed to land: a name the builder produces now, or some
  // other entry's `from` (the middle name of a genuine two-hop chain). Held
  // across generations rather than per-generation, because the table does not
  // chain — every row, whatever old frame its `from` is in, points DIRECTLY at
  // a final member name, which is the shape that makes a row idempotent and
  // one-hop.
  //
  // This was compared against the generation's own `target`, which is the member
  // list only for the FIRST generation and the previous generation's `from`
  // values after that. Against a flat table that accuses every row outside the
  // newest generation of renaming to a name the builder does not produce — 38 of
  // them at once, all pointing at members that were right there. What it claims
  // is unchanged: a `to` nobody produces and nobody picks up is still dangling,
  // which is what a typo'd `to` or a member renamed without its row looks like.
  const landable = new Set<string>([...memberNames, ...renames.map((r) => r.from)]);

  let target = [...memberNames];
  for (const key of generations) {
    const gen = byAxes.get(key) as { axes: string[]; entries: { from: string; to: string }[] };
    const entries = gen.entries;
    const axes = gen.axes;
    for (const r of entries) {
      if (!landable.has(r.to)) out.dangling.push(`${r.from} → ${r.to}`);
    }
    // Enumerating what a generation owes means reconstructing the OLD member
    // list, and the only material available is the CURRENT names — so the
    // reconstruction is a projection back onto the old axes. That inference is
    // sound in exactly one shape: the generation GAINED axes and left the
    // surviving values alone (`Size=xs` → `Size=xs, Ring=false`). Then
    // projecting `Size=xl2, Ring=false` really does yield the name that was on
    // the page, and a missing row for it is a missing row.
    //
    // Three shapes break the inference, and all three read as a table full of
    // holes when the table is complete:
    //
    //   · Axis REPLACEMENT — `Variant` → `Disabled`/`Error`, `Selected` →
    //     `Selection`. The old axis is gone from the current names.
    //   · PARTIAL replacement — MultiAnswerCard's `Selected, Disabled` →
    //     `Enabled, Selected, Hover`. `Selected` survives and `Disabled` does
    //     not, so a projection exists but is half a name. The earlier test asked
    //     whether ANY axis survived and passed this, then demanded rows for
    //     `Selected=false` / `Selected=true` — names no generation ever had.
    //   · VALUE rename — Checkbox's `State=Checked` → `State=checked`, Alert's
    //     `Variant=default` → `Variant=defaultVariant`. Projection puts the NEW
    //     value in the OLD frame and asks for `State=checked`, which was never a
    //     member of anything.
    //   · Axis REORDER — Fab's `Size=…, Open=…, State=…` → `Size=…, State=…,
    //     Open=…`, where the canvas had spelled a designer-added axis last and
    //     the builder composes it in T-16 order. No axis is gained, so EVERY
    //     current member projects to a well-formed old-frame name — including
    //     the ones the same run minted, which the old set never had. A sparse
    //     old set and a half-written table are the same input here.
    //
    // So the condition is not "can I project" but "does the projection land on
    // the names the entries themselves claim were there": every target must
    // carry every axis of the generation, the generation must carry FEWER axes
    // than its targets (a gain, not a reorder), and every entry's own `to`,
    // projected back, must come out as its `from`. When it does not, the
    // generation declines to be enumerated — and says so, because a check that
    // silently declines is indistinguishable from one that passed. The
    // half-written reorder table is still caught, on the page: an old member
    // its row would have renamed is neither a wanted name nor a listed `from`,
    // so `diffVariantNames` reports it and `mountSet` refuses the set.
    const wholeProjection = target.every(
      (n) => axisNames(n).length > 0 && axes.every((a) => parseVariantKey(n)[a] !== undefined),
    );
    const gainedAxes = target.every((n) => axisNames(n).length > axes.length);
    const valuesPreserved = entries.every((r) => project(r.to, axes) === r.from);
    if (!wholeProjection || !gainedAxes || !valuesPreserved) {
      out.unprojectable.push(axes.join(' × '));
      target = entries.map((r) => r.from);
      continue;
    }
    const required = new Set(target.map((n) => project(n, axes)));
    const listed = new Set(entries.map((r) => r.from));
    for (const need of [...required].sort()) {
      if (!listed.has(need)) out.unexplained.push(need);
    }
    target = entries.map((r) => r.from);
  }
  return out;
}
