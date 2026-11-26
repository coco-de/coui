/// <reference types="@figma/plugin-typings" />

import {
  VariantIdentityError,
  describeDuplicateVariants,
  diffVariantNames,
  findDuplicateVariantNames,
  verifyAppendedVariant,
  verifyLooseVariantName,
} from './variant-safety';
import { RETIRED_VARIANTS, VARIANT_RENAMES } from './renames';
import { corners } from './variables';
import { defaultSetLayout, installLayoutDeferral } from './set-layout';
import { markStep } from './last-step';
import { GrowthSampler, GrowthStats } from './growth';
import {
  RedrawKeepCost,
  drainRedrawKeepCost,
  installRedrawMemberHook,
  parkForRedraw,
  peekRedrawKeepCost,
} from './redraw-keep';

// Node identity — "make it, don't remake it".
//
// Every builder reaches its component through a by-name lookup that reuses the node
// in place, because a Figma component's KEY is what a designer's placed instances
// point at: recreating a node breaks every instance of it. Everything here exists to
// keep that key: minting, the document-wide index, variant-set mounting, and the
// reset that empties a node without replacing it.
//
// Split out of `helpers.ts`. These lived under a divider that said "Component
// properties" — `mountSet` is not a component property, and a reader looking for
// identity had no reason to open that section.

export function stampOwned(node: BaseNodeMixin): void {
  node.setPluginData('coui-owned', '1');
}

// Which `mountSet(page, setName, …)` call created this loose COMPONENT — read
// by the orphan-recovery scan in `mountSet` below. A combo NAME alone
// (`"Variant=defaultVariant, Size=md, Enabled=true"`) is not a safe key for
// that scan on its own: it is a generic label, not a global identifier, and
// nothing stops two unrelated sets that happen to share an axis vocabulary
// (Variant × Size × Enabled with the same values) from enumerating the exact
// same string — a shared-page test harness surfaced this in minutes, but
// nothing about production rules it out either, it would just take two
// entries with matching axes to hit it. Stamping the owning set's name onto
// every freshly-created member makes the recovery scan's match unambiguous
// regardless of what any OTHER set's members happen to be named.
export const kMountSetDataKey = 'coui-mount-set';

// Above this many members, `mountSet` empties the set for the duration of the
// build loop (see the manoeuvre and its measurements there). Below it the
// per-member penalty is small enough that the two reparents per member, and
// the wider interrupted-run surface they open, are not worth buying: at 50
// members drawing in place measured 20.5ms each, about a second for the set.
export const kBulkDetachMinMembers = 64;

// Sets currently disassembled by the manoeuvre in `mountSet`, each holding the
// closure that puts it back. `finish()` drops its own on the way out; whatever
// is left belongs to a builder that threw between the two, and the caller's
// per-entry catch drains it (`restoreDisassembledSets`). Module-level for the
// same reason the reset-cost accumulators are: builders do not see each other,
// and the run loop is the only place that knows an entry has failed.
let pendingSetRestores: Array<() => number> = [];

/** Reassemble every set a throwing builder left disassembled, returning how
 *  many members went back. Clears the list, so a second call is a no-op and a
 *  later entry cannot inherit an earlier one's pending work. */
export function restoreDisassembledSets(): { sets: number; members: number } {
  const restores = pendingSetRestores;
  pendingSetRestores = [];
  let members = 0;
  let sets = 0;
  for (const restore of restores) {
    const back = restore();
    if (back > 0) {
      sets += 1;
      members += back;
    }
  }
  return { sets, members };
}

// Every VariableBindableNodeField this node currently has a binding for,
// unbound — read from `boundVariables`, not a fixed field list, so a future
// Figma API addition is covered automatically ("화이트리스트 불필요").
// `fills`/`strokes` bindings are excluded: builders replace those arrays
// wholesale (`node.fills = [...]`), which already discards any old binding.
function unbindAllScalarVariables(node: SceneNode): void {
  const withBindings = node as unknown as { boundVariables?: Record<string, unknown> };
  const bound = withBindings.boundVariables;
  if (!bound) return;
  const settable = node as unknown as {
    setBoundVariable: (field: VariableBindableNodeField, value: Variable | null) => void;
  };
  for (const key of Object.keys(bound)) {
    if (key === 'fills' || key === 'strokes') continue;
    try {
      settable.setBoundVariable(key as VariableBindableNodeField, null);
    } catch {
      // Not every key `boundVariables` can report is settable via
      // `setBoundVariable` on every node type (e.g. text-only fields read
      // through a different setter) — skip rather than abort the reset.
    }
  }
}

// Clears a node back to the same blank slate `figma.createComponent()`
// hands a builder, so every existing builder body — which unconditionally
// re-sets every property it cares about — works unchanged whether the node
// is brand new or recycled.
export function mainComponentIdOf(
  page: PageNode,
  name: string,
  variantName?: string,
): string {
  const found = findComponentByName(page, name);
  if (found && found.type === 'COMPONENT') return found.id;
  if (found && found.type === 'COMPONENT_SET') {
    const kids = found.children.filter((c): c is ComponentNode => c.type === 'COMPONENT');
    const pick = variantName ? kids.find((c) => c.name === variantName) : kids[0];
    if (pick) return pick.id;
    throw new Error(
      `mainComponentIdOf('${name}', '${variantName ?? ''}'): the set is there but ` +
        `has no such variant. Variants present: ${kids.map((c) => c.name).join(' | ')}`,
    );
  }
  throw new Error(
    `mainComponentIdOf('${name}'): not in the document yet. Add ` +
      `\`needs: ['${name}']\` to this builder's REGISTRY entry ` +
      '(src/registry.ts topoSortRegistry).',
  );
}

export function instanceOf(
  page: PageNode,
  name: string,
  variantName?: string,
): InstanceNode {
  const found = findComponentByName(page, name);
  if (found && found.type === 'COMPONENT') return found.createInstance();
  if (found && found.type === 'COMPONENT_SET') {
    const kids = found.children.filter((c): c is ComponentNode => c.type === 'COMPONENT');
    const pick = variantName ? kids.find((c) => c.name === variantName) : kids[0];
    if (pick) return pick.createInstance();
    throw new Error(
      `instanceOf('${name}', '${variantName ?? ''}'): the set exists but has no ` +
        `such variant. Variants present: ${kids.map((c) => c.name).join(' | ')}`,
    );
  }
  throw new Error(
    `instanceOf('${name}'): not in the document yet. Add \`needs: ['${name}']\` to ` +
      "this builder's REGISTRY entry (src/registry.ts topoSortRegistry).",
  );
}

// ─── Recycle-path cost accounting ─────────────────────────────────────────
//
// A rebuild OVER an existing full document has run ~100x slower than the
// same build into a near-empty one (Button 576 variants: ~95s fresh vs
// ~2.5h recycled — observed twice, not estimated once). Which half of the
// recycle path pays that — emptying the old content (`resetNode`, below) or
// repopulating it (everything after) — cannot be told from the entry's
// total, and the candidate causes point at different fixes. Accumulated
// here and drained per entry by `generate.ts`, so ONE future slow run
// names the culprit instead of another afternoon of guessing.
let resetNodeMs = 0;
let resetNodeCalls = 0;
let resetNodeChildRemovals = 0;
// How the loop's members were obtained. `recycled` is the population that pays
// the reset cost above; `minted` is the fresh path. Counted because the two
// have different costs and the entry total cannot be split without knowing the
// mix — a run that is 432 recycled and one that is 432 minted read the same in
// every number we had.
let membersRecycled = 0;
let membersMinted = 0;
// `finish()` — `combineAsVariants` on the fresh path, `defaultSetLayout`'s O(N)
// width reads on both. Separated from the loop because it is once-per-entry
// work that was landing in a bucket named for per-combo work.
let setFinishMs = 0;

// ─── Inside `draw` ────────────────────────────────────────────────────────
//
// The three spans above account for ~9% of a slow entry. The other ~91% is
// `draw`, which is a REMAINDER — build minus what is named — and a remainder
// cannot be operated on: it says only that the time went somewhere between
// `getOrCreate` and `finish()`. The buckets below cut that span up by the
// kind of work rather than by the builder, because the candidate causes are
// per-kind: instantiating a component, flushing a layout to answer `.width`,
// and binding a variable fail expensively for three unrelated reasons and
// have three unrelated fixes.
//
// Named after what the call DOES, not where it lives, so a bucket keeps
// meaning when a helper moves file. `chrome` is the one deliberate lump —
// a dozen small binders whose individual costs nobody would act on
// separately; if it comes back big it gets split then, on evidence.
export type DrawSpan =
  /** `mount.getOrCreate` — finding or minting the member. EXCLUSIVE of
   *  `resetNode`, which it calls and which is already its own span above. */
  | 'node'
  /** `instanceOf` — one composed child component. */
  | 'instance'
  /** `makeIcon` — an `Icon` instance plus its glyph swap. */
  | 'icon'
  /** `makeLabel` — one text node, font bind included. */
  | 'text'
  /** pad / size / radius / fill / border / shadow binds, lumped. */
  | 'chrome'
  /** `focusRing`. */
  | 'ring'
  /** Reads of a laid-out property (`.width` / `.height`) and the resizes
   *  around them. Separate from everything else because it is the one span
   *  whose cost plausibly scales with the size of the WHOLE DOCUMENT rather
   *  than with this component — the shape a 100x recycle-path penalty would
   *  have. */
  | 'geom'
  /** `reportSubProgressAndYield`'s real event-loop tick. Measured because it
   *  is the one per-combo cost that is not drawing at all: 432 timer
   *  round-trips is a number worth knowing before it is defended. */
  | 'yield';

export interface SpanCost {
  ms: number;
  calls: number;
}

/** Written explicitly rather than built from a key list — the plugin runtime
 *  is fussy about spread, and eight literals cost less than the helper. */
function zeroSpans(): Record<DrawSpan, SpanCost> {
  return {
    node: { ms: 0, calls: 0 },
    instance: { ms: 0, calls: 0 },
    icon: { ms: 0, calls: 0 },
    text: { ms: 0, calls: 0 },
    chrome: { ms: 0, calls: 0 },
    ring: { ms: 0, calls: 0 },
    geom: { ms: 0, calls: 0 },
    yield: { ms: 0, calls: 0 },
  };
}

let drawSpans: Record<DrawSpan, SpanCost> = zeroSpans();

/**
 * Bills `Date.now() - startedAt` to one span. Call counts ride along because
 * a span's total does not say what to do about it: 200s in 5 calls and 200s
 * in 50,000 calls point at completely different fixes, and the two read
 * identically in a milliseconds-only line.
 *
 * Timed with two `Date.now()` calls per span rather than a sampling counter.
 * The volume is the argument: the heaviest entry measured (Chip, 480 members)
 * takes roughly a dozen instrumented calls per member — ~12k timestamps
 * against a build of 2,460 SECONDS. Even at a microsecond apiece that is
 * ~0.0005% of the span being measured, so the cheaper counter-only treatment
 * would buy nothing and cost the milliseconds that are the whole point.
 */
export function recordDrawSpan(span: DrawSpan, startedAt: number): void {
  const bucket = drawSpans[span];
  bucket.ms += Date.now() - startedAt;
  bucket.calls += 1;
}

// ─── Beside the eight — what the `draw` remainder still held ──────────────
//
// One Button run (972 members, 9,208s) put 7,425s of its 7,571s `draw` into
// `미계측`. The eight spans above were carved out for what drawing a MEMBER
// costs; these are the regions around that work which no span reached — the
// set taken apart before the loop, the property pass after it, the tint flush
// after the build returns. Each comes off the remainder exactly as the eight
// do.
//
// Kept out of `DrawSpan` on purpose. `DrawSpan` is the bracket on line one of
// the `⏱` report, and that line is read against logs from before these
// existed — a new bucket there would land somewhere in a list sorted by cost
// and shift the positions people compare. These print on the second line.
export type DetailSpan =
  /** `mountSet`'s bulk detach — every member moved out of its set before the loop. */
  | 'detach'
  /** `defineProp` — one definition on the set. Its own bucket, apart from the
   *  binds, because it is a different cost with a different shape: a handful of
   *  calls per set, each on the set as a whole, where a bind is one call per
   *  member slot. Billed together, the seven definitions Button makes on its
   *  972-member set were seven of the first hundred per-call samples — enough
   *  to pull the first-window mean up and hide the climb that window is there
   *  to show. */
  | 'define'
  /** `bindTextProp` / `bindVisibleProp` / `bindSwapProp` / `bindFocusRing` —
   *  one call per member slot, billed at the barrel like the draw spans. */
  | 'props'
  /** `flushTintLayers`, once per entry after `build()` returns. */
  | 'tints'
  /** One label's text style (`text-style-attach.ts`), billed per label. Most of
   *  it runs at the head of a yield, inside the gap the `loop` sampler measures,
   *  so it is taken back out of that sample — a combo's sample stays the
   *  drawing of that combo. */
  | 'attach'
  /** One reparent of a member for binding — into the anchored set to take
   *  its property references, and back out to the page when the next member's
   *  bind arrives (`recordPropRef`). Two calls per staged member, on a set that
   *  never holds more than two: this is the cost that replaced a bind inside
   *  the assembled set, so it prints next to `props` where that cost was. */
  | 'stage';

function zeroDetailSpans(): Record<DetailSpan, SpanCost> {
  return {
    detach: { ms: 0, calls: 0 },
    define: { ms: 0, calls: 0 },
    props: { ms: 0, calls: 0 },
    tints: { ms: 0, calls: 0 },
    attach: { ms: 0, calls: 0 },
    stage: { ms: 0, calls: 0 },
  };
}

let detailSpans: Record<DetailSpan, SpanCost> = zeroDetailSpans();

// `yield` and `finish`, each cut at the boundaries inside it. Both totals keep
// their meaning — the parts are the same milliseconds again, so logs from
// before the cut stay comparable — and each is cut because its total came back
// too big to explain from the outside: `yield` at 98ms a call is two orders
// past what a timer round-trip should cost, and `finish` held 714s for putting
// members back and laying the set out.
let yieldMarkMs = 0;
// Calls to `reportSubProgressAndYield`, ticked or not — the listener ran and
// the mark was written on every one. `yield.calls` counts only the real ticks
// (`kYieldBudgetMs` in helpers.ts), so the two read differently on purpose.
let yieldReports = 0;
let yieldPostMs = 0;
let yieldTickMs = 0;
let finishAppendMs = 0;
let finishPostMs = 0;
let finishLayoutMs = 0;
// `append` cut again (#5009). It held 779s of Button's 958s build and was one
// lump: the reference writes flushed on the way in, the name check, the
// `appendChild` loop itself, the `variantProperties` read-back and the parked
// members all billed to one number, so nothing said which of them to go after.
let appendSplit: AppendSplit = zeroAppendSplit();
// One sample per `appendChild` into a pending set — says whether a member costs
// more to put back the fuller the set already is (a climb here is O(N²) over
// the reassembly), or whether 972 appends are simply 972 equal appends.
let appendGrowth = new GrowthSampler();
// Whether this entry's reassembly ran with the current page elsewhere
// (`GenerateOptions.reassembleOffPage`). Recorded so the ⏱ line says which
// of two runs had the option, or the numbers cannot be compared.
let finishOffPage = false;
export function markReassembledOffPage(offPage: boolean): void {
  finishOffPage = finishOffPage || offPage;
}

// Growth — see `growth.ts`. `loop` is one sample per combo with the yield left
// out, `props` one per bind, `define` one per property definition. Together
// they say whether a big set is slow because it is big or because each member
// costs more than the one before it.
let loopGrowth = new GrowthSampler();
let propsGrowth = new GrowthSampler();
let defineGrowth = new GrowthSampler();
let attachGrowth = new GrowthSampler();
// Where the previous yield ended, so the next one can close the combo between
// them. Null outside a yielding loop.
let lastYieldEndedAt: number | null = null;
// `attach` billed since the last yield closed a sample — subtracted from the
// next one, which it would otherwise inflate by the previous combo's labels.
let attachSinceYieldMs = 0;

/** Bills `Date.now() - startedAt` to one detail span — `recordDrawSpan`'s twin. */
export function recordDetailSpan(span: DetailSpan, startedAt: number): void {
  const ms = Date.now() - startedAt;
  const bucket = detailSpans[span];
  bucket.ms += ms;
  bucket.calls += 1;
  // Sampled per call for the three that run more than once per entry. `detach`
  // and `tints` are one call each, which leaves no order to keep.
  if (span === 'props') propsGrowth.add(ms);
  else if (span === 'define') defineGrowth.add(ms);
  else if (span === 'attach') {
    attachGrowth.add(ms);
    attachSinceYieldMs += ms;
  }
}

/**
 * Bills one `reportSubProgressAndYield`: the whole call to `yield`, and the
 * same milliseconds again as `mark` (the `setSharedPluginData` on
 * `figma.root`), `post` (the listener, which ends in `figma.ui.postMessage`)
 * and `tick` (the `setTimeout(0)` itself). The three are slow for unrelated
 * reasons — a document write, a message across the sandbox boundary, the
 * host's timer — so the total alone cannot say which one to go after.
 *
 * Takes the boundaries instead of reading the clock again, so the parts sum to
 * the total by construction. A boundary the call never reached (it threw)
 * arrives null and bills nothing past itself.
 *
 * Also the per-combo sampler's clock. The time from one yield's end to the
 * next one's start IS a combo with the yield left out, and the loop has no
 * other seam to measure at without adding an `await` of its own.
 *
 * `ticked` is whether the call reached the timer. A call inside the budget
 * (`kYieldBudgetMs`) still marks and posts — those milliseconds are billed the
 * same — but it is not a `yield` call: that count is how many times the host
 * got a turn, and it is what the 132ms-a-tick figure was measured against.
 * Every call, ticked or not, is a combo boundary for the sampler.
 */
export function recordYield(
  startedAt: number,
  markedAt: number | null,
  postedAt: number | null,
  endedAt: number,
  ticked = true,
): void {
  const marked = markedAt ?? endedAt;
  const posted = markedAt === null ? endedAt : (postedAt ?? endedAt);
  drawSpans.yield.ms += endedAt - startedAt;
  if (ticked) drawSpans.yield.calls += 1;
  yieldReports += 1;
  yieldMarkMs += marked - startedAt;
  yieldPostMs += posted - marked;
  yieldTickMs += endedAt - posted;
  // Net of the attaches drained at the head of this call — see `attach`.
  if (lastYieldEndedAt !== null) {
    loopGrowth.add(startedAt - lastYieldEndedAt - attachSinceYieldMs);
  }
  attachSinceYieldMs = 0;
  lastYieldEndedAt = endedAt;
}

/**
 * Closes the last combo's sample at `finish()` — the one way out of a yielding
 * loop that is not another yield. A builder that never yielded has nothing
 * open, and this does nothing.
 *
 * The `loop` sampler reads a builder's shape rather than being told it, and the
 * shape it assumes is the one the yielding builders (`buildButton`,
 * `buildChip`) have: the yield is the FIRST statement of each combo, and
 * `finish()` is called right after the loop. Under that shape the gap from one
 * yield's end to the next one's start is exactly one combo's drawing, and the
 * last combo runs from its yield to `finish()`. A builder shaped otherwise
 * still produces numbers, which is why the assumption is written down:
 *
 *   - yield at the bottom of the combo: each sample is one combo's tail plus
 *     the next one's head — the count is right and every sample is shifted;
 *   - work between the loop and `finish()`: all of it lands in the last
 *     combo's sample, which `max` then points at;
 *   - a yielding loop with no `finish()` after it: the last combo is never
 *     closed and the next drain throws it away, so the count comes out one
 *     short.
 */
export function closeComboLoop(at: number): void {
  if (lastYieldEndedAt === null) return;
  // Net of the last combo's attach, drained just before `finish()`.
  loopGrowth.add(at - lastYieldEndedAt - attachSinceYieldMs);
  attachSinceYieldMs = 0;
  lastYieldEndedAt = null;
}

/** `finish()`'s milliseconds, cut at the boundaries its body reached. */
export interface FinishSplit {
  appendMs: number;
  postMs: number;
  layoutMs: number;
  /** The three parts summed — what `BuildCost.finishMs` accrues. */
  totalMs: number;
}

/**
 * Cuts one `finish()` at its boundaries: `appendedAt` (every member back in),
 * `postFrom` (the post-condition starts, after the `:finish:post` mark) and
 * `checkedAt` (the post-condition passed, layout starts). A boundary the body
 * never reached arrives null, and everything from the last one it did reach to
 * `endedAt` bills to the part that was running — so the parts sum to the total
 * on every exit, a throwing one included.
 *
 * The gap from `appendedAt` to `postFrom` is the mark, and it is in no part
 * and not in the total (`markStep` in last-step.ts says why). Nothing else is
 * left out: a total that dropped anything more would stop being the `finish`
 * older logs report.
 *
 * No Figma calls, so the arithmetic is checked off-sandbox
 * (selftest-nfr-e-report).
 */
export function splitFinish(
  startedAt: number,
  appendedAt: number | null,
  postFrom: number | null,
  checkedAt: number | null,
  endedAt: number,
): FinishSplit {
  if (appendedAt === null) {
    const appendMs = endedAt - startedAt;
    return { appendMs, postMs: 0, layoutMs: 0, totalMs: appendMs };
  }
  const appendMs = appendedAt - startedAt;
  // Unreachable in practice — `markStep` cannot throw — and read as a body
  // that got no further than the mark.
  if (postFrom === null) return { appendMs, postMs: 0, layoutMs: 0, totalMs: appendMs };
  const postMs = (checkedAt ?? endedAt) - postFrom;
  const layoutMs = checkedAt === null ? 0 : endedAt - checkedAt;
  return { appendMs, postMs, layoutMs, totalMs: appendMs + postMs + layoutMs };
}

/** `append`'s milliseconds (#5009): `finish()` itself, then the reassembly cut
 *  at the four boundaries inside it. */
export interface AppendSplit {
  /** `finish()` itself — `combineAsVariants` on a first build, registering the
   *  pending mount otherwise. Billed to `append` before the cut existed, so it
   *  stays inside it here. */
  deferMs: number;
  deferCalls: number;
  /** Staged + dirty members' reference writes, and the staged member's move out. */
  flushMs: number;
  /** Members whose references were written here. */
  flushCalls: number;
  /** `verifyLooseVariantName` over the members about to go back in. */
  checkMs: number;
  /** The `appendChild` loop over the builder's members, marks included. */
  appendChildMs: number;
  appendChildCalls: number;
  /** The one-pass `variantProperties` read-back after the last append. */
  readbackMs: number;
  readbackCalls: number;
  /** The rename-explained members the detach parked, put back after the rest. */
  parkedMs: number;
  parkedCalls: number;
}

export function zeroAppendSplit(): AppendSplit {
  return {
    deferMs: 0,
    deferCalls: 0,
    flushMs: 0,
    flushCalls: 0,
    checkMs: 0,
    appendChildMs: 0,
    appendChildCalls: 0,
    readbackMs: 0,
    readbackCalls: 0,
    parkedMs: 0,
    parkedCalls: 0,
  };
}

/**
 * Cuts `append` (`startedAt` → `endedAt`) at the boundaries its body reached:
 * `flushedAt` (references written), `checkedAt` (names checked), `appendedAt`
 * (the builder's members in) and `readAt` (read back). The parked members run
 * from `readAt` to `endedAt`. A boundary the body never reached arrives null,
 * and everything from the last one it did reach to `endedAt` bills to the part
 * that was running — `splitFinish`'s rule, so the five parts sum to the
 * `append` that part of the line already reports, a throwing one included.
 *
 * Returns milliseconds only; the call counts are the caller's to add. No
 * Figma calls, so the arithmetic is checked off-sandbox (selftest-nfr-e-report).
 */
export function splitAppend(
  startedAt: number,
  flushedAt: number | null,
  checkedAt: number | null,
  appendedAt: number | null,
  readAt: number | null,
  endedAt: number,
): { flushMs: number; checkMs: number; appendChildMs: number; readbackMs: number; parkedMs: number } {
  const bounds = [flushedAt, checkedAt, appendedAt, readAt];
  const parts = [0, 0, 0, 0, 0];
  let from = startedAt;
  let i = 0;
  for (; i < bounds.length; i++) {
    const to = bounds[i];
    if (to === null) break;
    parts[i] = to - from;
    from = to;
  }
  parts[i] = endedAt - from;
  return {
    flushMs: parts[0],
    checkMs: parts[1],
    appendChildMs: parts[2],
    readbackMs: parts[3],
    parkedMs: parts[4],
  };
}

/** What the second `⏱` line reads. Every number here is also inside `buildMs`. */
export interface BuildDetail {
  spans: Record<DetailSpan, SpanCost>;
  /** Sums to `BuildCost.finishMs`. */
  finish: { appendMs: number; postMs: number; layoutMs: number; offPage: boolean };
  /** Sums to `BuildCost.spans.yield.ms`. */
  yieldSplit: { markMs: number; postMs: number; tickMs: number; reports: number };
  growth: { loop: GrowthStats; props: GrowthStats; define: GrowthStats; attach: GrowthStats };
  /** Sums to `finish.appendMs` (#5009). */
  appendSplit: AppendSplit;
  /** One sample per `appendChild` of a builder's member back into its set. */
  appendGrowth: GrowthStats;
}

/** One entry's build-cost accumulators, as `drainResetNodeCost` hands them over. */
export interface BuildCost {
  ms: number;
  calls: number;
  childRemovals: number;
  recycled: number;
  minted: number;
  finishMs: number;
  spans: Record<DrawSpan, SpanCost>;
  detail: BuildDetail;
  /** What the redraw kept of the old inner nodes (`redraw-keep.ts`). Absent
   *  where nothing was parked, so a line with nothing kept reads as before. */
  keep?: RedrawKeepCost;
}

/**
 * Reads the build-cost accumulators WITHOUT clearing them — the running
 * entry's numbers so far. `growth` is what makes this worth having mid-loop:
 * the samplers hold order, so a snapshot at combo 300 already says whether
 * combo 300 costs more than combo 1 did. `drainResetNodeCost` is this plus
 * the reset, and the reset is the only difference.
 */
export function peekBuildCost(): BuildCost {
  return {
    ms: resetNodeMs,
    calls: resetNodeCalls,
    childRemovals: resetNodeChildRemovals,
    recycled: membersRecycled,
    minted: membersMinted,
    finishMs: setFinishMs,
    spans: drawSpans,
    detail: {
      spans: detailSpans,
      finish: {
        appendMs: finishAppendMs,
        postMs: finishPostMs,
        layoutMs: finishLayoutMs,
        offPage: finishOffPage,
      },
      yieldSplit: {
        markMs: yieldMarkMs,
        postMs: yieldPostMs,
        tickMs: yieldTickMs,
        reports: yieldReports,
      },
      growth: {
        loop: loopGrowth.stats(),
        props: propsGrowth.stats(),
        define: defineGrowth.stats(),
        attach: attachGrowth.stats(),
      },
      appendSplit,
      appendGrowth: appendGrowth.stats(),
    },
    keep: keepCostOrUndefined(peekRedrawKeepCost()),
  };
}

function keepCostOrUndefined(cost: RedrawKeepCost): RedrawKeepCost | undefined {
  return cost.kept + cost.replaced > 0 ? cost : undefined;
}

/** Reads and clears the build-cost accumulators — one entry's worth. */
export function drainResetNodeCost(): BuildCost {
  const out = peekBuildCost();
  drainRedrawKeepCost();
  resetNodeMs = 0;
  resetNodeCalls = 0;
  resetNodeChildRemovals = 0;
  membersRecycled = 0;
  membersMinted = 0;
  setFinishMs = 0;
  // Replaced, not zeroed in place — `out` holds the old object and a caller
  // that logs after the next entry starts would otherwise read counters that
  // have moved on.
  drawSpans = zeroSpans();
  detailSpans = zeroDetailSpans();
  yieldMarkMs = 0;
  yieldPostMs = 0;
  yieldTickMs = 0;
  yieldReports = 0;
  finishAppendMs = 0;
  finishPostMs = 0;
  finishLayoutMs = 0;
  finishOffPage = false;
  // Replaced, not zeroed — `out` holds the old object (see `drawSpans`).
  appendSplit = zeroAppendSplit();
  appendGrowth = new GrowthSampler();
  loopGrowth = new GrowthSampler();
  propsGrowth = new GrowthSampler();
  defineGrowth = new GrowthSampler();
  attachGrowth = new GrowthSampler();
  // A combo still open here belongs to an entry that is over — a builder that
  // threw mid-loop — and must not close against the next entry's first yield.
  lastYieldEndedAt = null;
  attachSinceYieldMs = 0;
  return out;
}

export function resetNode(node: ComponentNode): void {
  const resetStart = Date.now();
  resetNodeCalls += 1;
  // Component property definitions are NOT reset. They are the node's public
  // surface, and a designer's instance overrides are bound to the key — `title#21`,
  // not `title` — so deleting a definition and minting it again under `title#257`
  // silently drops every override in the file that pointed at the old one. Doing
  // that on every run is the opposite of what mint-by-name is for.
  //
  // This did delete them, on the reasoning that `addComponentProperty` throws on a
  // name already in use and a second run would otherwise throw or accumulate
  // suffixed duplicates. That was true when builders called the raw API. Every one
  // of them now goes through `defineProp`, which finds an existing name+type and
  // returns its key instead of minting — so the clearing has nothing left to
  // prevent, and what it does instead is exactly the loss it was guarding against.
  //
  // A property this builder does not define survives the reset — and is removed
  // after the entry is drawn, if no layer of the set references it
  // (`unbound-props.ts`, called by `generate.ts` once the set is reassembled).
  // Figma's publish dialog silently leaves out a set that declares a property
  // nothing references (#5323), so a stale entry is not the harmless panel
  // clutter it looks like. Deleting here, before the draw, would still be the
  // wrong moment: a property the builder is about to bind again would be
  // minted under a new key and every override pointing at the old one would be
  // dropped. Deleting after, and only what no layer references, loses nothing —
  // an override on a property that drives no layer drives nothing, and the key
  // of every property a layer uses is the one the reset left alone.
  //
  // The children are not removed here either, when the run keeps them
  // (`redraw-keep.ts`): an instance's override on a layer is stored against the
  // main's node, so a child removed and drawn again loses every override placed
  // on it — the ✕ colour a designer set inside a Button, on every Generate.
  // They are hidden in place instead, the builder draws beside them, and the run
  // loop settles the two trees once the entry has drawn. What cannot be hidden,
  // or every child when keeping is off, is removed as before.
  for (const child of parkForRedraw(node)) {
    child.remove();
    resetNodeChildRemovals += 1;
  }
  unbindAllScalarVariables(node);
  node.fills = [];
  node.strokes = [];
  node.opacity = 1;
  node.visible = true;
  node.locked = false;
  node.rotation = 0;
  node.x = 0;
  node.y = 0;
  node.layoutMode = 'NONE';
  node.clipsContent = false;
  node.itemSpacing = 0;
  node.paddingLeft = 0;
  node.paddingRight = 0;
  node.paddingTop = 0;
  node.paddingBottom = 0;
  node.cornerRadius = 0;
  node.topLeftRadius = 0;
  node.topRightRadius = 0;
  node.bottomLeftRadius = 0;
  node.bottomRightRadius = 0;
  node.primaryAxisSizingMode = 'AUTO';
  node.counterAxisSizingMode = 'AUTO';
  node.primaryAxisAlignItems = 'MIN';
  node.counterAxisAlignItems = 'MIN';
  // How the member sits in its parent — the set — is not the builder's to
  // inherit either. A recycled member stays nested in its set, and a grow or
  // stretch left by an earlier generation survives every redraw: in a set laid
  // out as a row (`rowSet`), a member that grows while the row hugs is squeezed
  // to 1px wide. NavigationBarItem's stacked `fill` members sat at 1×64 that
  // way, and only the members minted after that generation drew at their size.
  // Written only when stale, so a member of a set that lays out nothing is
  // never written a field its parent does not use.
  if (node.layoutGrow !== 0) node.layoutGrow = 0;
  if (node.layoutAlign !== 'INHERIT') node.layoutAlign = 'INHERIT';
  stampOwned(node);
  resetNodeMs += Date.now() - resetStart;
}

// #4021 (B1) — document-wide mint-by-name. The lookup used to be scoped to
// the single 🧩 Components page; component-per-page (B2) needs a node to be
// findable wherever it currently lives, or the first multi-page run would
// re-mint every component under a new key. generate.ts builds the index
// once per run (every page loaded) and installs it here; when no index is
// installed (selftest harness, palette generator) the original same-page
// lookup below is the behavior, unchanged.
let documentNodeIndex: ReadonlyMap<string, SceneNode> | null = null;

// Load every page and index every COMPONENT / COMPONENT_SET in the document by
// name. This is what `installNodeIndex` wants fed to it, and every command that
// reads components needs it — not just the one that writes them.
//
// It lives here because it was written once inside the generator, and the two
// read-only commands (fidelity, theme preview) kept their own page-local lookups.
// Under one page per component those lookups resolve to nothing, so both reported
// the honest form of nothing: "No 🧩 Components page. Nothing was checked, which is
// not the same as nothing being wrong." Correct, and useless — the checks that judge
// whether the values are right had no way to run at all.
//
// #4847 — a duplicate's winner used to be purely "whichever page the
// document lists first", which is exactly the ordering a designer's own
// page reshuffle can flip: the FormLabel case had both nodes on the SAME
// `❖ FormLabel` page (rename-the-node was the fix there), but the Command
// case had the real one on `❖ Command` and a leftover on
// `❖ Command (deprecated · 2026-09-08)` — currently first only because that
// page happens to sit earlier in the list. Nothing in the code says it has
// to stay that way.
//
// A page named exactly `❖ {componentName}` is the one component-per-page
// (#4023, D-27) actually assigns that component — every other name (a
// `(deprecated · …)` suffix, a demoted page with no `❖`, a stray second copy
// elsewhere) is not that assignment, whatever order it happens to load in.
// So the winner is decided by that fact FIRST, order second: a canonical
// page beats a non-canonical one regardless of which the walk reaches
// first, and the walk only falls back to first-wins when neither (or both)
// pages are canonical — a case the naming convention has no opinion about.
//
// `snapshotDocument` (verify.ts) grades the exact node this index hands
// generate, so it calls this same function rather than repeating the rule —
// two independent copies of "which duplicate wins" is how that grader once
// scored a node generate never touched (see its own doc comment).
export function isCanonicalComponentPage(pageName: string, componentName: string): boolean {
  return pageName === `❖ ${componentName}`;
}

export function prefersDuplicateWinner(
  componentName: string,
  incumbentPageName: string,
  candidatePageName: string,
): boolean {
  return (
    isCanonicalComponentPage(candidatePageName, componentName) &&
    !isCanonicalComponentPage(incumbentPageName, componentName)
  );
}

// Duplicate names warn; the winner is the canonical `❖ {name}` page when
// exactly one candidate is on one, first-in-document-order otherwise.
// mint-by-name's identity model assumes unique names, and G2 guards the
// REGISTRY side of that assumption.
export async function indexDocumentComponents(
  warn?: (message: string) => void,
  pages: readonly PageNode[] = figma.root.children,
): Promise<Map<string, SceneNode>> {
  const index = new Map<string, SceneNode>();
  const pageOf = new Map<string, string>();
  for (const p of pages) {
    // `documentAccess: dynamic-page` refuses `.children` on an unloaded page.
    await p.loadAsync();
    addPageToIndex(index, pageOf, p.name, p.children, warn);
  }
  return index;
}

// One page's contribution to the index. Pure over structural nodes — the part
// `indexDocumentComponents` does once a page is loaded, and the part the
// component-index-cache selftest drives with plain objects to prove that the
// cache-hit path rebuilds the same answer as this walk.
export function addPageToIndex<N extends { readonly type: string; readonly name: string }>(
  index: Map<string, N>,
  pageOf: Map<string, string>,
  pageName: string,
  children: readonly N[],
  warn?: (message: string) => void,
): void {
  for (const child of children) {
    if (child.type !== 'COMPONENT' && child.type !== 'COMPONENT_SET') continue;
    const seen = index.get(child.name);
    if (seen) {
      const seenPage = pageOf.get(child.name)!;
      if (prefersDuplicateWinner(child.name, seenPage, pageName)) {
        warn?.(
          `⚠ duplicate node name "${child.name}" — "${pageName}" 이 캐논 페이지라 ` +
            `"${seenPage}" 대신 이걸 쓴다(발견 순서와 무관, rename the other one)`,
        );
        index.set(child.name, child);
        pageOf.set(child.name, pageName);
      } else {
        warn?.(
          `⚠ duplicate node name "${child.name}" (also on "${pageName}") — ` +
            `first occurrence wins; mint-by-name assumes unique names`,
        );
      }
      continue;
    }
    index.set(child.name, child);
    pageOf.set(child.name, pageName);
  }
}

export function installNodeIndex(index: ReadonlyMap<string, SceneNode>): void {
  documentNodeIndex = index;
}

export function clearNodeIndex(): void {
  documentNodeIndex = null;
}

// A COMPONENT / COMPONENT_SET by name, from ANYWHERE in the document.
//
// Every child lookup goes through this. One page per component means a composed
// child is never on the caller's page: `Button` builds on `❖ Button` and the `Icon`
// it instances lives on `❖ Icon`. A page-local search finds nothing and says "not on
// the page yet" — which is true, and reads as a build-order problem that it is not.
// 106 entries failed that way with the order already correct.
//
// The index is the document's, and it is LIVE: generate registers each component as
// it finishes, so a child built earlier in the same run is found even on a document
// that started empty. Without that, only a second run would work — and the way this
// library is exercised, every run is a first run.
//
// Falls back to the page when no index is installed, which is how the harnesses and
// any single-page caller keep working.
export function findComponentByName(
  page: PageNode,
  name: string,
): ComponentNode | ComponentSetNode | null {
  // A set whose reassembly is still pending holds its anchor alone, and the
  // caller is about to read `.children`. Finishing it here costs that set its
  // deferral, which is the honest trade: a builder that looks its own set up by
  // name after `finish()` wants the members, not the anchor.
  const pending = pendingByName.get(name);
  if (pending) completePendingMount(pending);
  const indexed = documentNodeIndex?.get(name);
  // Guarded, because an indexed handle can be dead. A node the index points at may
  // have been removed since — by a designer, or (before the per-entry undo was
  // dropped) by a later entry's rollback. Reading `.type` off it throws
  // `The node with id … does not exist`, which surfaces as the CALLER failing over
  // a child it did nothing wrong about.
  let live: ComponentNode | ComponentSetNode | null = null;
  if (indexed) {
    try {
      if (indexed.type === 'COMPONENT' || indexed.type === 'COMPONENT_SET') {
        // `.children` is what a caller reads next; touching it here is what proves
        // the handle resolves rather than merely answering `.type` from a stale
        // record.
        void (indexed as ComponentNode | ComponentSetNode).children.length;
        live = indexed;
      }
    } catch {
      live = null;
    }
  }
  const found =
    live ??
    page.children.find(
      (node): node is ComponentNode | ComponentSetNode =>
        (node.type === 'COMPONENT' || node.type === 'COMPONENT_SET') && node.name === name,
    ) ??
    null;
  // A set another run is rebuilding right now is not a set to compose from —
  // see `refuseMidRebuild`. Our own pending set was completed above, so what
  // this catches is foreign (or the debris of a run that died mid-loop).
  if (found !== null && found.type === 'COMPONENT_SET') refuseMidRebuild(found, name);
  return found;
}

/** The members of `set` that sit loose on its page, stamped as its own — the
 *  state `mountSet` leaves a large set in for the whole build loop (its
 *  anchor inside, everything else parked beside it, `kMountSetDataKey` on
 *  each). Empty for an assembled set. A set with one member and nothing
 *  parked is just a one-member set (Menubar, Scaffold), not a set mid-rebuild. */
export function looseMembersOf(set: ComponentSetNode): ComponentNode[] {
  const page = set.parent;
  if (page === null || !('children' in page)) return [];
  const out: ComponentNode[] = [];
  for (const node of page.children) {
    if (node === set || node.type !== 'COMPONENT') continue;
    if (node.getPluginData(kMountSetDataKey) === set.name) out.push(node);
  }
  return out;
}

// #4831 — a composer that reads a set while ANOTHER run has it disassembled
// sees the anchor alone. `restingVariantName` then fails on "Variants
// present: <one name>", which is loud; `bestVariantName` scores the one
// member it can see and hands it back — primary/xs on every Alert, Banner,
// Toast, Drawer and Fab of the 2026-09-12 run, with nothing in the log.
// Refusing here makes both paths fail the same way, by name, at the moment
// the wrong picture would otherwise be drawn.
function refuseMidRebuild(set: ComponentSetNode, name: string): void {
  const loose = looseMembersOf(set);
  if (loose.length === 0) return;
  const inside = set.children.filter((c) => c.type === 'COMPONENT').length;
  const pageName = set.parent === null ? '?' : set.parent.name;
  throw new Error(
    `findComponentByName('${name}'): the set holds ${inside} member(s) while ${loose.length} of its ` +
      `members sit loose on "${pageName}" — another Generate run is rebuilding it right now, or one ` +
      `died mid-loop. Composing against it would take its anchor for every request (#4831). Wait for ` +
      `that run to finish, or re-run "${name}" so it reassembles.`,
  );
}

// Single-component builders: reuse the existing `name`d COMPONENT if one
// exists anywhere in the document index (falling back to the given page's
// children when no index is installed), reset to blank first — otherwise
// mint a brand new one. Either way the caller gets back an empty node and
// populates it exactly as before.
export function mint(page: PageNode, name: string): ComponentNode {
  const indexed = documentNodeIndex?.get(name);
  if (indexed && indexed.type === 'COMPONENT') {
    resetNode(indexed);
    return indexed;
  }
  const existing = page.children.find(
    (n): n is ComponentNode => n.type === 'COMPONENT' && n.name === name,
  );
  if (existing) {
    resetNode(existing);
    return existing;
  }
  const c = figma.createComponent();
  c.name = name;
  stampOwned(c);
  // `figma.createComponent()` lands on `figma.currentPage`, not necessarily
  // `page` — same reason `mountSet`'s `getOrCreate` reparents its own fresh
  // branch, and the exact gap this function had instead: `page` arrives as
  // an explicit parameter but was never actually used to place the node,
  // leaving a single-component entry's first-ever build wherever
  // `figma.currentPage` happened to be pointed rather than on the page its
  // own name says it belongs to.
  page.appendChild(c);
  return c;
}

//
// Mint-by-name for PROPERTIES: a Figma property key is `${display}#${id}`,
// and `addComponentProperty` always mints a NEW id — calling it on every
// run would stack duplicate panel entries and orphan every instance
// override bound to the previous key. So definitions are found by display
// name first and only added when missing, mirroring how mint()/mountSet()
// treat nodes. Which slot becomes TEXT vs BOOLEAN is the calling builder's
// knowledge (it knows which nodes it actually renders — D-25); the slot
// NAMES come from schema v3 `props.slots` (the contract's `W`/`W?` getters,
// and its `List<W>` ones marked `repeated`), and the selftest sweep asserts
// every swap name is one of them.

// NOTE — the find-or-create `bindTextProp(host, name, textNode)` from the other
// side of this merge is not here. Its job is already done by the pair this file
// keeps: `defineProp` finds an existing definition before adding one (so a key,
// and every instance override bound to it, survives a re-run) and `bindTextProp`
// points a node at the returned id. Every call site in the repo — 49 of them —
// already spells it that way, and two doors onto one property would let a builder
// satisfy whichever one it happened to import.

// The BOOLEAN half went the same way for the same reason: `defineProp` +
// `bindVisibleProp`, which all 91 call sites already spell. The find-or-create
// variant survived the merge as a definition nobody called — two doors onto one
// property, with the unused one still compiling.

// ─── Deferred reassembly ─────────────────────────────────────────────────────
//
// Everything a builder does to a node inside an assembled COMPONENT_SET costs
// in proportion to the set — measured on Button's 972 members, a property bind
// is 1.46s a call and a read between two binds about the same, where the same
// call on a loose member is milliseconds. `mountSet` already takes the members
// OUT for the drawing loop; every builder then calls `finish()` and binds its
// properties with the set back together, which is where 79% of that entry's
// two and a half hours went (#4038, #4798).
//
// So `finish()` no longer puts the members back. It validates, registers the
// set here as PENDING with its anchor alone inside, and returns that anchor
// set — the builder defines its properties on it and binds as before. A bind
// on a loose member stages it: the member goes into the anchored set (two
// members, so the write is cheap under either explanation of the cost — a
// write proportional to set size, or a read that re-derives the set), its
// references are noted, and it goes back to the page when the next member's
// bind arrives. The references are written once per node, on the way out,
// from what the builder said rather than read back and merged. A layout call
// on a pending set records the intent. `completePendingMounts()` — called by
// the run loop after the entry's text styles are attached — appends everything
// in the builder's order, verifies, applies the recorded layout (or the
// default), and reads ONE staged member's references back: if the staging did
// not survive the reparent, every reference is rewritten in place and the run
// falls back to eager reassembly for the entries that follow.
//
// `eager` is the old order kept alive on purpose: `finish()` completes at once
// and binds land in the assembled set. It is the fallback above, and the
// harness draws every builder both ways and compares the trees.

export type ReassemblyMode = 'deferred' | 'eager';
let reassembly: ReassemblyMode = 'deferred';
export function setReassemblyMode(mode: ReassemblyMode): void {
  reassembly = mode;
}
export function reassemblyMode(): ReassemblyMode {
  return reassembly;
}

interface LayoutIntent {
  name: string;
  apply: () => void;
}

// The set's own layout fields, read at `finish()` and again at completion. A
// builder that lays its set out by hand after `finish()` — assigning
// `layoutMode` and paddings on the set rather than calling a `set-layout`
// helper — changes them; the default layout is then not applied over it, which
// is what the old order came to as well (the default ran first, the builder's
// writes won). Sizes are left out: a set in `NONE` follows its members' bounds.
const kLayoutSnapshotFields = [
  'layoutMode',
  'layoutWrap',
  'primaryAxisSizingMode',
  'counterAxisSizingMode',
  'primaryAxisAlignItems',
  'counterAxisAlignItems',
  'itemSpacing',
  'counterAxisSpacing',
  'paddingLeft',
  'paddingRight',
  'paddingTop',
  'paddingBottom',
] as const;
function snapshotLayout(set: ComponentSetNode): string {
  const bag = set as unknown as Record<string, unknown>;
  const out: unknown[] = [];
  for (const field of kLayoutSnapshotFields) out.push(bag[field]);
  return JSON.stringify(out);
}

interface PendingMount {
  setName: string;
  page: PageNode;
  set: ComponentSetNode;
  /** The builder's members in its own order — what goes back in, and in what order. */
  comps: ComponentNode[];
  /** What the bulk detach moved that the loop never asked for (rename-explained members). */
  parked: ComponentNode[];
  /** Every member this mount owns, inside the set or out — the key a bound node resolves through. */
  members: Set<ComponentNode>;
  /** The names the builder declared — what a loose member must still be called to go back in. */
  expected: ReadonlySet<string>;
  /** The member currently inside the set for binding, besides the anchor. */
  staged: ComponentNode | null;
  /** What each bound node's references will be, from the builder's own calls. */
  refs: Map<SceneNode, Record<string, string>>;
  /** Bound nodes whose references have not been written yet, by member. */
  dirty: Map<ComponentNode, SceneNode[]>;
  /** The last node written on a member that then left the set — read back after reassembly. */
  probe: SceneNode | null;
  layout: LayoutIntent | null;
  /** `afterBindsLand` work, in call order — run once every reference is written.
   *  `node` is the node the work is for, if any: a redraw that keeps an old node
   *  in place of the new one points the work at the node that stays. */
  afterBinds: Array<{ node: SceneNode | null; apply: (node: SceneNode | null) => void }>;
  /** `snapshotLayout` at `finish()` — see `kLayoutSnapshotFields`. */
  parkedLayout: string;
  restore: () => number;
}

const pendingMounts: PendingMount[] = [];
const pendingByMember = new Map<ComponentNode, PendingMount>();
const pendingBySet = new Map<ComponentSetNode, PendingMount>();
const pendingByName = new Map<string, PendingMount>();
// Sets whose staged references did not survive, wherever the completion ran —
// a `mountSet` or `findComponentByName` completes a set on its own and has no
// log to write to. Drained into the next `completePendingMounts()` report, so
// the run loop's `↯` line names every fallback, not only the ones it triggered.
let fallbackNames: string[] = [];

/** What `completePendingMounts` did — for the run log. */
export interface ReassemblyReport {
  sets: number;
  members: number;
  /** Sets whose staged references did not survive; rewritten in place, and the run is now `eager`. */
  fallbacks: string[];
}

export function pendingMountCount(): number {
  return pendingMounts.length;
}

/** Every member a pending set will hold once completed — what is inside it
 *  now (the anchor, a staged member), what the builder drew, and what the
 *  detach parked — in one list, so a caller can read them all while the
 *  expensive ones are still loose. Empty when nothing is pending. */
export function pendingMountMembers(): Array<{
  setName: string;
  set: ComponentSetNode;
  members: ComponentNode[];
}> {
  return pendingMounts.map((mount) => {
    const seen = new Set<ComponentNode>();
    const members: ComponentNode[] = [];
    const take = (m: ComponentNode): void => {
      if (m.removed || seen.has(m)) return;
      seen.add(m);
      members.push(m);
    };
    for (const child of mount.set.children) if (child.type === 'COMPONENT') take(child);
    for (const m of mount.comps) take(m);
    for (const m of mount.parked) take(m);
    return { setName: mount.setName, set: mount.set, members };
  });
}

function componentAncestorOf(node: SceneNode): ComponentNode | null {
  let scan: BaseNode | null = node;
  while (scan != null) {
    if (scan.type === 'COMPONENT') return scan;
    if (scan.type === 'COMPONENT_SET' || scan.type === 'PAGE' || scan.type === 'DOCUMENT') return null;
    scan = scan.parent;
  }
  return null;
}

/** The set a loose member of a pending mount belongs to — `propertyOwner`'s
 *  answer for a member whose `parent` is the page for the moment. */
export function pendingOwnerOf(member: ComponentNode): ComponentSetNode | null {
  const mount = pendingByMember.get(member);
  return mount ? mount.set : null;
}

// Explicit copy: the plugin runtime rejects object spread.
function copyRefs(refs: Record<string, string>): Record<string, string> {
  const out: Record<string, string> = {};
  for (const key of Object.keys(refs)) out[key] = refs[key];
  return out;
}

// A member's name flattens the moment it leaves its set (`Variant=a, Size=b`
// comes back as `Set/a/b`), and both the reattach and the orphan scan read
// that name — see the bulk detach in `mountSet`. Read before the move, restore
// after.
function moveToPage(page: PageNode, member: ComponentNode): void {
  const name = member.name;
  page.appendChild(member);
  member.name = name;
}

/** Writes the references noted for `member`'s nodes; returns the last node written. */
function flushMember(mount: PendingMount, member: ComponentNode): SceneNode | null {
  const nodes = mount.dirty.get(member);
  if (!nodes) return null;
  mount.dirty.delete(member);
  let last: SceneNode | null = null;
  for (const node of nodes) {
    const refs = mount.refs.get(node);
    if (!refs) continue;
    node.componentPropertyReferences = copyRefs(refs);
    last = node;
  }
  return last;
}

function unstage(mount: PendingMount): void {
  const member = mount.staged;
  if (!member) return;
  const last = flushMember(mount, member);
  // The probe is a node that was written INSIDE and is about to go OUT and
  // come back — the exact round trip the whole scheme depends on.
  if (last) mount.probe = last;
  const startedAt = Date.now();
  try {
    moveToPage(mount.page, member);
  } finally {
    recordDetailSpan('stage', startedAt);
  }
  mount.staged = null;
}

function stageMember(mount: PendingMount, member: ComponentNode): void {
  if (member.parent === mount.set) return; // the anchor, a member of a set small enough to stay assembled, or already staged
  if (mount.staged) unstage(mount);
  const startedAt = Date.now();
  try {
    mount.set.appendChild(member);
  } finally {
    recordDetailSpan('stage', startedAt);
  }
  mount.staged = member;
}

/**
 * Notes a property reference for a node inside a pending mount's member —
 * staging the member first — and reports whether it did. `false` means the
 * node is not under a pending mount (a standalone component, or a set that
 * has already completed) and the caller writes the reference itself.
 */
export function recordPropRef(node: SceneNode, field: string, propId: string): boolean {
  const member = componentAncestorOf(node);
  if (!member) return false;
  const mount = pendingByMember.get(member);
  if (!mount) return false;
  stageMember(mount, member);
  let refs = mount.refs.get(node);
  if (!refs) {
    refs = {};
    mount.refs.set(node, refs);
  }
  refs[field] = propId;
  let queued = mount.dirty.get(member);
  if (!queued) {
    queued = [];
    mount.dirty.set(member, queued);
  }
  if (queued.indexOf(node) < 0) queued.push(node);
  return true;
}

function forgetPendingMount(mount: PendingMount): void {
  const at = pendingMounts.indexOf(mount);
  if (at >= 0) pendingMounts.splice(at, 1);
  for (const member of mount.members) {
    if (pendingByMember.get(member) === mount) pendingByMember.delete(member);
  }
  if (pendingBySet.get(mount.set) === mount) pendingBySet.delete(mount.set);
  if (pendingByName.get(mount.setName) === mount) pendingByName.delete(mount.setName);
}

function refsSurvived(node: SceneNode, want: Record<string, string>): boolean {
  const got = node.componentPropertyReferences as Record<string, string | undefined> | undefined;
  if (!got) return Object.keys(want).length === 0;
  for (const key of Object.keys(want)) {
    if (got[key] !== want[key]) return false;
  }
  return true;
}

/** Reassembles one pending set. Billed to `finish` — the same append / post /
 *  layout cuts as before, so the ⏱ line keeps its meaning. */
function completePendingMount(mount: PendingMount): { members: number; fallback: boolean } {
  const { setName, set, page } = mount;
  // A set that is gone — the scratch page of a spot-check removed under it,
  // or a designer deleting it mid-run — has nothing to complete, and reading
  // a dead node throws under whichever entry happens to ask next. Forgotten
  // here, net and all, so that entry is never blamed.
  if (set.removed) {
    pendingSetRestores = pendingSetRestores.filter((r) => r !== mount.restore);
    forgetPendingMount(mount);
    return { members: 0, fallback: false };
  }
  const finishStart = Date.now();
  let appendedAt: number | null = null;
  let postFrom: number | null = null;
  let checkedAt: number | null = null;
  // `append`'s own boundaries (#5009) — see `splitAppend`.
  let flushedAt: number | null = null;
  let namesCheckedAt: number | null = null;
  let childrenAppendedAt: number | null = null;
  let readBackAt: number | null = null;
  let flushCalls = 0;
  let appendChildCalls = 0;
  let readbackCalls = 0;
  let parkedCalls = 0;
  let members = 0;
  let fallback = false;
  try {
    markStep(`${setName}:reassemble`);
    // Whatever is still inside takes its references now, while the set is
    // small: the staged member on its way out (which also picks the probe),
    // then the anchor and any member of a set that never came apart. The staged
    // member does go out — it sits second in the set, and the builder's order
    // puts it elsewhere — but the move is billed to `finish`, where the append
    // that follows it is, not to `stage`.
    if (mount.staged) {
      const last = flushMember(mount, mount.staged);
      if (last) mount.probe = last;
      moveToPage(page, mount.staged);
      mount.staged = null;
      flushCalls += 1;
    }
    for (const member of Array.from(mount.dirty.keys())) {
      flushMember(mount, member);
      flushCalls += 1;
    }
    flushedAt = Date.now();
    // Put back everything that is not currently inside the set, in `comps`
    // order so a regenerated set reads the same as a first-ever build. The
    // anchor is already in place and is skipped, as is every member of a set
    // small enough to have stayed assembled throughout.
    //
    // Three passes, not one: the name check that needs no set runs first, on
    // the loose members, so a bad name fails before anything moves; then the
    // appends, writes only; then the `variantProperties` read-back of every
    // member that went in, in one pass after the last write. A read between
    // two writes was what the old loop did 971 times, and if a read after a
    // write is what makes Figma re-derive the set (H2, #4038), that is 971
    // re-derivations where one will do. The failure the read-back catches and
    // the message it throws are unchanged.
    const going: ComponentNode[] = [];
    for (const comp of mount.comps) {
      if (comp.parent === set) continue;
      verifyLooseVariantName(comp.name, mount.expected, setName);
      going.push(comp);
    }
    namesCheckedAt = Date.now();
    for (const comp of going) {
      // Each append timed on its own, the mark every fifty left out of the
      // sample — the sampler asks whether an append costs more into a fuller
      // set, and a mark is not an append.
      const appendStart = Date.now();
      set.appendChild(comp);
      appendGrowth.add(Date.now() - appendStart);
      appendChildCalls += 1;
      members += 1;
      if (members % 50 === 0) markStep(`${setName}:finish:appended:${members}`);
    }
    markStep(`${setName}:finish:appended:${members}:all`);
    childrenAppendedAt = Date.now();
    for (const comp of going) {
      verifyAppendedVariant(comp.variantProperties, comp.name, setName);
      readbackCalls += 1;
    }
    readBackAt = Date.now();
    // Then what the detach moved that the loop never asked for — the
    // rename-explained stale members S-a deliberately left alone. They go back
    // after `comps` so the builder's order still leads and they trail it, which
    // is where they sat before. `verifyAppendedVariant` is not run on them:
    // their name is by definition not one this builder produces, and the check
    // would read that as an axis mismatch and throw over a member the guard has
    // already accepted.
    for (const m of mount.parked) {
      if (m.removed || m.parent === set) continue;
      set.appendChild(m);
      members += 1;
      parkedCalls += 1;
    }
    appendedAt = Date.now();
    markStep(`${setName}:finish:post`);
    postFrom = Date.now();
    // Post-condition, because the failure it catches is invisible on the canvas
    // until someone looks at the set: everything this run took out or drew is
    // supposed to be back inside. Counted against what was moved and drawn,
    // not against the expected list — a set legitimately carrying a stale,
    // rename-explained member has one more child than the builder's list.
    const stranded = mount.comps
      .concat(mount.parked)
      .filter((m) => !m.removed && m.parent !== set);
    if (stranded.length > 0) {
      throw new Error(
        `${setName}: reassembly left ${stranded.length} member(s) outside the set ` +
          `(first: "${stranded[0].name}"). They are loose on "${page.name}" under ` +
          `their variant names and the next run will reclaim them, but this set ` +
          `is not usable until it does.`,
      );
    }
    // Whole again — the failure net is no longer this set's to hold, and the
    // layout gate below must see a set that is no longer pending.
    pendingSetRestores = pendingSetRestores.filter((r) => r !== mount.restore);
    forgetPendingMount(mount);
    // One read inside the assembled set, on purpose: the staged references
    // are the whole bet, and this is the only moment it can be checked. A
    // reference that did not survive means every reference was lost the same
    // way, so all of them are rewritten in place — the old cost, the right
    // canvas — and the run stops staging. Before the `afterBinds` work and the
    // layout, not after: a rewrite is a first bind again, and a first
    // INSTANCE_SWAP bind resizes the instance it lands on (`afterBindsLand`).
    if (mount.probe && !refsSurvived(mount.probe, mount.refs.get(mount.probe) ?? {})) {
      fallback = true;
      fallbackNames.push(setName);
      for (const [node, refs] of Array.from(mount.refs.entries())) {
        node.componentPropertyReferences = copyRefs(refs);
      }
      reassembly = 'eager';
    }
    markStep(`${setName}:finish:layout`);
    checkedAt = Date.now();
    // Every reference is on the canvas now. Then the layout, which measures
    // the members as this work left them.
    for (const after of mount.afterBinds) after.apply(after.node);
    if (mount.layout) {
      mount.layout.apply();
    } else if (snapshotLayout(set) === mount.parkedLayout) {
      // Nothing laid it out — the default, as `finish()` always applied.
      defaultSetLayout(set);
    } else {
      // Laid out by hand after `finish()`; the members flow into that layout.
      markStep(`${setName}:finish:layout:kept`);
    }
    markStep(`${setName}:finish:done`);
    return { members, fallback };
  } finally {
    // A throw above leaves the restore net armed for the run loop's catch, but
    // the mount itself must not be completed twice.
    forgetPendingMount(mount);
    const endedAt = Date.now();
    const split = splitFinish(finishStart, appendedAt, postFrom, checkedAt, endedAt);
    finishAppendMs += split.appendMs;
    // Cut against the same end `splitFinish` gave `append`, so the five parts
    // sum to it on every exit.
    const parts = splitAppend(
      finishStart,
      flushedAt,
      namesCheckedAt,
      childrenAppendedAt,
      readBackAt,
      appendedAt ?? endedAt,
    );
    appendSplit.flushMs += parts.flushMs;
    appendSplit.flushCalls += flushCalls;
    appendSplit.checkMs += parts.checkMs;
    appendSplit.appendChildMs += parts.appendChildMs;
    appendSplit.appendChildCalls += appendChildCalls;
    appendSplit.readbackMs += parts.readbackMs;
    appendSplit.readbackCalls += readbackCalls;
    appendSplit.parkedMs += parts.parkedMs;
    appendSplit.parkedCalls += parkedCalls;
    finishPostMs += split.postMs;
    finishLayoutMs += split.layoutMs;
    setFinishMs += split.totalMs;
  }
}

/** Reassembles every pending set, oldest first. The run loop calls this once
 *  per entry after `build()` and the entry's text-style drain; `mountSet` and
 *  `findComponentByName` call it too, so a builder that mounts a second set or
 *  looks one up by name always sees complete members. */
export function completePendingMounts(): ReassemblyReport {
  const report: ReassemblyReport = { sets: 0, members: 0, fallbacks: [] };
  while (pendingMounts.length > 0) {
    const mount = pendingMounts[0];
    const done = completePendingMount(mount);
    report.sets += 1;
    report.members += done.members;
  }
  // Every fallback since the last report — this call's own and the ones a
  // lookup or a second mount completed on their own.
  report.fallbacks = fallbackNames;
  fallbackNames = [];
  return report;
}

/**
 * Runs `apply` once the property references bound on `set`'s members are
 * written — at once when they already are (`eager`, or a set that has
 * completed), otherwise at completion, before the set is laid out.
 *
 * For work that has to come AFTER a bind. A deferred bind is only noted
 * (`recordPropRef`) and lands when the set completes, so a write on the line
 * below a bind runs before it. Most writes do not care. A size does: the
 * first bind of an INSTANCE_SWAP puts the property's default in place of an
 * instance's main and, on every axis not sized FILL, gives the instance that
 * main's own size (measured in Figma, 2026-10-02). A rescale written before
 * that bind lands is undone by it — every `EmptyState` icon came out at 24
 * that way (#5246).
 */
export function afterBindsLand(set: ComponentSetNode, apply: () => void): void {
  const mount = pendingBySet.get(set);
  if (!mount) {
    apply();
    return;
  }
  mount.afterBinds.push({ node: null, apply: () => apply() });
}

/**
 * `afterBindsLand` keyed by a bound NODE instead of by its set, for a caller
 * that holds only the node (`bindSwapProp`). A node under a pending mount's
 * member queues `apply` on that mount. Anything else (a standalone component,
 * or a set that has completed) had its reference written by the bind call
 * itself, so `apply` runs now.
 */
export function afterNodeBindLands(node: SceneNode, apply: (node: SceneNode) => void): void {
  const member = componentAncestorOf(node);
  const mount = member ? pendingByMember.get(member) : undefined;
  if (!mount) {
    apply(node);
    return;
  }
  // Handed the node rather than closing over it: a redraw that keeps the old
  // node (`redraw-keep.ts`) re-points the entry, and the work lands on the node
  // that stays.
  mount.afterBinds.push({ node, apply: (n) => apply(n ?? node) });
}

// ─── Redraw keep — the pending set's half ────────────────────────────────────
//
// A kept old node takes the new node's place in everything this module noted
// about it: the references a staged member will have written (keyed by node),
// the bound node whose read-back proves the staging, and the work queued for
// after the binds land. The references are then written the way every other
// reference is — with the member staged in the anchored set — because a loose
// member's layers cannot take the set's property ids.
function sameRefs(a: Record<string, string> | null, b: Record<string, string>): boolean {
  const ak = a ? Object.keys(a) : [];
  const bk = Object.keys(b);
  if (ak.length !== bk.length) return false;
  for (const key of bk) if (!a || a[key] !== b[key]) return false;
  return true;
}

function currentRefs(node: SceneNode): Record<string, string> | null {
  let raw: Record<string, string | undefined> | null | undefined;
  try {
    raw = node.componentPropertyReferences as Record<string, string | undefined> | null | undefined;
  } catch {
    return null;
  }
  if (!raw) return null;
  const out: Record<string, string> = {};
  for (const key of Object.keys(raw)) {
    const v = raw[key];
    if (typeof v === 'string') out[key] = v;
  }
  return out;
}

installRedrawMemberHook({
  isPending: (member) => pendingByMember.has(member),
  expensive: (member) => {
    if (pendingByMember.has(member)) return false;
    const parent = member.parent;
    return parent !== null && parent.type === 'COMPONENT_SET' && parent.children.length > kBulkDetachMinMembers;
  },
  remap: (member, pairs, refsByOld) => {
    const mount = pendingByMember.get(member);
    if (!mount) return;
    const queued: SceneNode[] = [];
    for (const [from, to] of pairs) {
      const recorded = mount.refs.get(from);
      if (recorded) mount.refs.delete(from);
      if (mount.probe === from) mount.probe = to;
      // What the new node carries — written on it directly, or noted for it —
      // is what the kept one must carry, and nothing it held from the last run.
      const want: Record<string, string> = copyRefs(refsByOld.get(to) ?? {});
      if (recorded) for (const key of Object.keys(recorded)) want[key] = recorded[key];
      if (recorded || !sameRefs(currentRefs(to), want)) {
        mount.refs.set(to, want);
        queued.push(to);
      }
    }
    for (const [owner, nodes] of Array.from(mount.dirty.entries())) {
      const kept = nodes.filter((n) => !pairs.has(n));
      if (owner === member) {
        for (const n of queued) if (kept.indexOf(n) < 0) kept.push(n);
      }
      mount.dirty.set(owner, kept);
    }
    if (queued.length > 0 && !mount.dirty.has(member)) mount.dirty.set(member, queued.slice());
    for (const after of mount.afterBinds) {
      if (after.node !== null && pairs.has(after.node)) after.node = pairs.get(after.node) ?? after.node;
    }
    if (queued.length > 0) stageMember(mount, member);
  },
});

/**
 * The COMPONENT / COMPONENT_SET a builder is about to mount under `name`, if
 * the document already has one. It is looked up the way `mountSet` and `mint`
 * look it up (the document index, then the page), and it has none of
 * `findComponentByName`'s side effects. It never completes a pending mount and
 * never refuses a set mid-rebuild, because the caller is the builder that owns
 * the set and reads only its property definitions.
 *
 * A dead handle (a node removed since the index was taken) answers null rather
 * than throwing, the same guard `findComponentByName` keeps.
 */
export function existingComponentOrSet(
  page: PageNode,
  name: string,
): ComponentNode | ComponentSetNode | null {
  try {
    const indexed = documentNodeIndex?.get(name);
    if (indexed && (indexed.type === 'COMPONENT' || indexed.type === 'COMPONENT_SET')) {
      if (!indexed.removed) return indexed;
    }
    const onPage = page.children.find(
      (node): node is ComponentNode | ComponentSetNode =>
        (node.type === 'COMPONENT' || node.type === 'COMPONENT_SET') && node.name === name,
    );
    return onPage ?? null;
  } catch {
    return null;
  }
}

// A layout call on a pending set is an intent, applied once the members are
// back. Installed here rather than imported there: `set-layout.ts` is what this
// module imports for the default, and the gate keeps that a one-way street.
installLayoutDeferral((set, name, apply) => {
  const mount = pendingBySet.get(set);
  if (!mount) return false;
  mount.layout = { name, apply };
  return true;
});

// Variant-set builders. Usage:
//   const mount = mountSet(page, 'Badge', allExpectedVariantNames);
//   for (...) { const comp = mount.getOrCreate('Variant=x, Size=y'); ...populate comp... }
//   const set = mount.finish();
//   layoutSet(set, 520); // caller still applies its own layout after finish()
export interface SetMount {
  /** Reused (reset) or freshly-created empty ComponentNode for this exact
   *  variant name. Call once per variant, in any order. */
  getOrCreate(variantName: string): ComponentNode;
  /** Combines/reconciles everything requested via getOrCreate() into the
   *  persistent ComponentSetNode and returns it. Throws VariantIdentityError
   *  (S-a) if the existing set has variant(s) this run no longer wants and
   *  no SET_RENAMES/VARIANT_RENAMES entry explains why — nothing is deleted
   *  in that case, on purpose; the caller must resolve it first. */
  finish(): ComponentSetNode;
}

export interface SetMountOptions {
  /** #4034 (C2) — static→variant-set promotion by ADOPTION. When no set
   *  exists yet but a loose COMPONENT carrying the set's name does, rename
   *  that node to this combination name and feed it through the normal
   *  recycle path (reset → repopulate → combineAsVariants includes it), so
   *  its node id/`key` — and every instance in consuming files — survives
   *  the promotion. remove+rebuild is the key-destroying path this option
   *  exists to make unnecessary. The combination given here is what the
   *  legacy static node ACTUALLY rendered (the builder knows; this
   *  mechanism never guesses from axes defaults). */
  adoptLooseAs?: string;
}

export function mountSet(
  page: PageNode,
  setName: string,
  expectedVariantNames: readonly string[],
  options?: SetMountOptions,
): SetMount {
  // A set still pending from earlier in this builder is completed before a
  // new one is mounted — its members must be home before anything composes
  // them, and two pending sets on one page would share the staging page.
  completePendingMounts();
  // Both directions of the name contract, checked against these.
  const expectedNames = new Set(expectedVariantNames);
  const created = new Set<string>();
  // #4021 (B1) — same document-wide lookup as mint() above.
  const indexed = documentNodeIndex?.get(setName);
  const existing =
    indexed && indexed.type === 'COMPONENT_SET'
      ? indexed
      : page.children.find(
          (n): n is ComponentSetNode => n.type === 'COMPONENT_SET' && n.name === setName,
        );
  const existingByName = new Map<string, ComponentNode>();
  if (existing) {
    // Before the map, because the map is what hides this: keyed by name, it
    // keeps one member per duplicated name and the twin never appears again.
    // The builder then recycles whichever copy sorted last and leaves the
    // other to drift — and the drifting one is not necessarily the copy live
    // instances point at. Refusing here rather than repairing follows the same
    // rule as S-a below: this module does not delete a persistent node on its
    // own account, because the two copies are rarely interchangeable.
    const duplicates = findDuplicateVariantNames(
      existing.children.filter((c) => c.type === 'COMPONENT').map((c) => c.name),
    );
    if (duplicates.length > 0) {
      throw new VariantIdentityError(describeDuplicateVariants(setName, duplicates));
    }
    for (const child of existing.children) {
      if (child.type === 'COMPONENT') existingByName.set(child.name, child);
    }
  }
  if (!existing && options?.adoptLooseAs) {
    const loose =
      indexed && indexed.type === 'COMPONENT'
        ? indexed
        : page.children.find(
            (n): n is ComponentNode => n.type === 'COMPONENT' && n.name === setName,
          );
    if (loose) {
      // Rename FIRST, then seed the recycle map — getOrCreate() will find
      // it under its combination name and reuse it in place, exactly like
      // any other existing variant child.
      loose.name = options.adoptLooseAs;
      existingByName.set(options.adoptLooseAs, loose);
    }
  }
  // Interrupted-run recovery — a builder large enough to run for real
  // minutes (Button: 432 combos) can be killed mid-loop, before `finish()`
  // ever reassembles the set. Every combo `getOrCreate` had already reached is
  // left as a loose `COMPONENT` on `page`, individually named exactly one of
  // `expectedVariantNames` and not recognised by anything above.
  //
  // Two ways to arrive here, and the scan has to cover both. On a first-ever
  // build nothing is a COMPONENT_SET yet, so `existing` is falsy next run. But
  // the bulk-detach below parks an EXISTING set's members on the page for the
  // duration of the loop, so an interruption there strands them while the set
  // itself (holding its anchor) survives — `existing` is truthy and the strays
  // still need claiming. Guarding this scan on `!existing`, as it once was,
  // would leave those 431 members orphaned and mint fresh ones over them,
  // destroying their keys. Without this, the next run cannot tell
  // those apart from "never built" and creates a second fresh one per name
  // instead of reusing them — which does not just repeat the wasted work,
  // it compounds it: each retry leaves its own unclaimed pile next to the
  // last one's, and a page with many more loose top-level children is
  // measurably slower to append to, so every subsequent attempt starts
  // slower than the one before it. (True duplicates across multiple
  // interrupted attempts are not de-duplicated here — mint-by-name never
  // deletes a persistent node on its own account, so an already-orphaned
  // sibling with the same name is left alone, inert, rather than guessed at
  // and removed.) The `kMountSetDataKey` check is load-bearing, not
  // defensive — a combo NAME alone is a generic label two unrelated sets can
  // legitimately share, so matching on name only would occasionally hand
  // this set someone else's member.
  for (const child of page.children) {
    if (
      child.type === 'COMPONENT' &&
      expectedNames.has(child.name) &&
      child.getPluginData(kMountSetDataKey) === setName &&
      !existingByName.has(child.name)
    ) {
      existingByName.set(child.name, child);
    }
  }
  const existingNamesSnapshot = [...existingByName.keys()];

  // S-a, and it runs HERE — before the set is touched, not at finish().
  //
  // Both inputs are already final: the snapshot is taken above and the
  // expected list arrived as an argument, so the answer at finish() is the
  // same answer. Asking late cost something real, though. The bulk detach
  // below empties the set, so a builder whose variant list no longer matches
  // the canvas — Chip, whose canvas carries a five-axis `Color/Selected/
  // Emphasis/State` shape the builder stopped producing — got its 192 members
  // taken out, drew 48 unrelated ones, and only THEN hit the refusal. Nothing
  // was deleted, which is what S-a promises, but the set was left holding one
  // member with 191 lying on the page. Refusing before anything moves keeps
  // "refusing to delete them" and "leaving them where they are" the same
  // sentence, and it fails in seconds instead of after a full draw.
  const relevantRenames = VARIANT_RENAMES.filter((r) => r.component === setName);
  const nameDiff = diffVariantNames(existingNamesSnapshot, expectedVariantNames, relevantRenames);
  if (nameDiff.unexplained.length > 0) {
    // #4035 — a leftover already listed in RETIRED_VARIANTS is a KNOWN dead
    // end (its name encodes something the axes cannot express), so the
    // operator has a documented next step instead of a bare "resolve
    // manually". Generate still refuses to delete it: retiring a variant
    // child destroys its key, which is an explicit, reviewed action
    // (code.ts `retire-*`), never a side effect of generating.
    const retired = RETIRED_VARIANTS.filter(
      (r) => r.component === setName && nameDiff.unexplained.indexOf(r.name) >= 0,
    );
    const retiredNote =
      retired.length > 0
        ? ` [${retired.map((r) => r.name).join(', ')}] are listed in RETIRED_VARIANTS ` +
          `(no destination under the current axis enumeration) — run "Retire phantoms" ` +
          `(dry-run first) to remove them, then rerun Generate.`
        : '';
    throw new VariantIdentityError(
      `${setName}: existing variant(s) [${nameDiff.unexplained.join(', ')}] are no longer ` +
        `produced by this builder and no rename explains why. Refusing to delete them ` +
        `(S-a) — a designer may have renamed one in Figma, or the builder's variant ` +
        `list shrank. Resolve manually (add a VARIANT_RENAMES entry, or delete by hand ` +
        `if truly retired) and rerun.` +
        retiredNote,
    );
  }

  // No separate list of freshly-minted nodes. `finish()` used to need one to
  // clean up scratch components when S-a refused, and to know which nodes to
  // append to an existing set — the first job moved out with the check (which
  // now runs before anything is created) and the second is `comps`, which
  // already holds every member this run touched, minted or recycled, in the
  // builder's own order.
  const comps: ComponentNode[] = [];
  // Every member the bulk detach below took out of the set — NOT just the ones
  // this run will ask for. The two lists differ exactly when the set carries
  // a member whose name is some rename's `from`: S-a lets it through (the
  // rename explains it) and leaves it in place, so it is never in
  // `expectedVariantNames`, never requested by the loop, never in `comps`.
  // Reattaching from `comps` alone would strand it on the page — a member the
  // guard promised to keep, lost by the reassembly that followed. So the
  // detach records what it moved and `finish()` puts THAT back, plus `comps`.
  const parked: ComponentNode[] = [];
  let restoreOnFailure: (() => number) | null = null;

  // Drawing a member while it is still a child of its COMPONENT_SET costs
  // O(set size) per mutation, which makes the whole loop quadratic. Measured
  // on a 432-member set: 108ms to rebuild a member in place, 4.7ms for the
  // same work on a loose component with that set sitting on the same page.
  // Set membership is what costs, not document size — the same rebuild with
  // no large set present at all measured 6.5ms, i.e. marginally slower.
  //
  // So take them out, let the loop draw them loose, and put them back in
  // `finish()`. One member stays behind as an anchor because emptying a set
  // deletes the set. End to end on 432 members: 43.6s -> 11.8s.
  //
  // Identity survives this, which is the only reason it is allowed. Probed
  // before and after the manoeuvre: property definition ids (`Label#3200:0`),
  // the set key, every member key and id, `componentPropertyReferences` on the
  // returned members, and an instance override bound to one of those ids all
  // compare equal — and the definitions stay readable on the set the whole
  // time it is down to its anchor.
  //
  // Member order comes out as `comps` order, the builder's own enumeration,
  // which is also what a first-ever build produces. A set whose order predates
  // this (recycled members kept their old positions, fresh ones appended at
  // the end) is normalised by the first run through here and stays put after.
  if (existing && existing.children.length > kBulkDetachMinMembers) {
    // Billed to `detach`: a plugin-data write, a reparent and a rename per
    // member, over the whole set, before the first combo draws — work that ran
    // outside every span and so read as `draw` remainder.
    const detachStart = Date.now();
    try {
      // Read back by the orphan scan above if this run dies mid-loop. Existing
      // members were never stamped — only freshly minted ones were — so without
      // this the strays would be unrecognisable and their keys lost.
      for (const child of existing.children) {
        if (child.type === 'COMPONENT') child.setPluginData(kMountSetDataKey, setName);
      }
      // The set reflows on every add and remove while it has auto-layout on;
      // parking it for the duration takes another ~22% off the reparent cost.
      // `finish()` restores it unconditionally via `defaultSetLayout`.
      existing.layoutMode = 'NONE';
      for (const child of existing.children.slice(1)) {
        if (child.type !== 'COMPONENT') continue;
        const variantName = child.name;
        page.appendChild(child);
        parked.push(child);
        // Figma flattens a member's name the moment it leaves its set:
        // `Variant=primary, Size=xs, State=hover` comes back out as
        // `Button/primary/xs/hover`. Both halves of this file read that name —
        // `finish()` cannot append a component whose name is not `Prop=Value,
        // …` (the set rejects it), and the orphan scan matches on
        // `expectedNames.has(child.name)` — so a flattened name strands the
        // member twice over: it cannot go back in, and the next run cannot
        // recognise it and mints a fresh node over its key. Put it back now,
        // while every member is still in hand, rather than at reattach time,
        // so an interrupted run leaves names the scan can still read.
        child.name = variantName;
      }
    } finally {
      recordDetailSpan('detach', detachStart);
    }
    // Between here and `finish()` the set is disassembled, and anything the
    // builder throws in that window leaves it that way. The next run's orphan
    // scan does reclaim the members, so no key is lost — but until someone
    // runs it again the component reads on the canvas as a single button
    // where a grid should be, with nothing saying why. Registering the way
    // back means the run that failed is also the run that puts it right.
    if (parked.length > 0) {
      restoreOnFailure = () => {
        if (existing.removed) return 0;
        let back = 0;
        for (const m of parked) {
          if (m.removed || m.parent === existing) continue;
          existing.appendChild(m);
          back += 1;
        }
        defaultSetLayout(existing);
        return back;
      };
      pendingSetRestores.push(restoreOnFailure);
    }
  }

  return {
    getOrCreate(variantName: string): ComponentNode {
      // Billed net of `resetNode`: this calls it, and it is already its own
      // span. Without the subtraction the two would overlap and the spans
      // would sum past the build total, which is the one arithmetic property
      // that makes the remainder below readable.
      const spanStart = Date.now();
      const resetBefore = resetNodeMs;
      try {
        return getOrCreateInner(variantName);
      } finally {
        recordDrawSpan('node', spanStart + (resetNodeMs - resetBefore));
      }
    },

    finish: finishInner,
  };

  function getOrCreateInner(variantName: string): ComponentNode {
    // The declared list is the contract, and this is where it is kept.
    //
    // Almost every builder enumerates its axes TWICE — once to build the name
    // list handed to `mountSet`, once in the loop that draws each member — and
    // nothing connected the two. A pose value added to the loop and not the list
    // produced a member the set was never told about; one added to the list and
    // not the loop produced a name nothing drew. Both were silent: the set came
    // out with the wrong member count and every downstream check (variant safety,
    // fidelity, the rename audit) took that count as the truth.
    //
    // Refusing here turns that divergence into a build error naming the member,
    // which is what `mountSet(page, name, names)` always meant.
    if (!expectedNames.has(variantName)) {
      throw new Error(
        `${setName}: getOrCreate("${variantName}") — that name is not in the list ` +
          `handed to mountSet. The axes are enumerated twice (once for the list, ` +
          `once for this loop) and the two have diverged.`,
      );
    }
    created.add(variantName);
    const found = existingByName.get(variantName);
    if (found) {
      existingByName.delete(variantName);
      membersRecycled += 1;
      resetNode(found);
      // Nothing to move in the common cases: a member parked on `page` by
      // the bulk detach above is already there, and a member of a set small
      // enough to skip that manoeuvre must stay nested inside its set — its
      // parent is the ComponentSetNode, and ripping it out here would empty
      // a set that `finish()`'s `existing` branch never rebuilds from
      // scratch. Only the adoptLooseAs promotion (`!existing`, found.parent
      // is a page — typically the pre-per-component-page legacy 🧩
      // Components page) needs to land on `page` before finish()'s
      // combineAsVariants(comps, page) call, same reason the fresh-node
      // branch below reparents.
      if (!existing && found.parent !== page) page.appendChild(found);
      comps.push(found);
      return found;
    }
    membersMinted += 1;
    const fresh = figma.createComponent();
    // `figma.createComponent()` lands on `figma.currentPage`, not
    // necessarily `page` — whatever page the user has open when they
    // click Generate. `finish()`'s `combineAsVariants(comps, page)`
    // requires every node in `comps` to already share `page`, so a
    // first-ever generation of this component (no `existing` set to
    // reuse) throws "Grouped nodes must be in the same page as the
    // parent" unless it's already on the right page — reparent it here,
    // before any styling, rather than leaving it on whatever page was
    // active.
    page.appendChild(fresh);
    fresh.name = variantName;
    // Read back by the orphan-recovery scan if this run is interrupted
    // before finish() ever combines it — see kMountSetDataKey.
    fresh.setPluginData(kMountSetDataKey, setName);
    comps.push(fresh);
    return fresh;
  }

  function finishInner(): ComponentSetNode {
    // The loop is over the moment this is called, so its last combo closes
    // here — see `closeComboLoop`.
    const finishStart = Date.now();
    closeComboLoop(finishStart);
    markStep(`${setName}:finish:start`);
    // The other direction: a declared name nothing drew. Without this the set is
    // simply short a member and the count reads as intentional.
    const undrawn = expectedVariantNames.filter((n) => !created.has(n));
    if (undrawn.length > 0) {
      throw new Error(
        `${setName}: ${undrawn.length} declared variant(s) were never built — ` +
          `${undrawn.slice(0, 4).join(' | ')}${undrawn.length > 4 ? ' …' : ''}. ` +
          `The name list and the build loop have diverged.`,
      );
    }
    let set: ComponentSetNode;
    if (!existing) {
      if (comps.length === 0) {
        throw new Error(`${setName}: finish() with no members — a set cannot be empty.`);
      }
      // The first member alone makes the set; the rest go in through the same
      // reassembly an existing set gets, so there is one path, not two. (A set
      // is created in `NONE` layout, which is also where reassembly parks it.)
      set = figma.combineAsVariants([comps[0]], page);
      set.name = setName;
      stampOwned(set);
      verifyAppendedVariant(comps[0].variantProperties, comps[0].name, setName);
    } else {
      set = existing;
    }
    // Parked in `NONE` for the wait, whatever the last run left it in — the
    // bulk detach already does this for a large set, and it is what makes a
    // builder's hand-written layout after `finish()` visible at completion:
    // the snapshot below is taken from `NONE`, so any auto-layout a builder
    // assigns differs from it, even one that repeats last run's values.
    if (set.layoutMode !== 'NONE') set.layoutMode = 'NONE';
    const mount: PendingMount = {
      setName,
      page,
      set,
      comps,
      parked,
      members: new Set<ComponentNode>(comps.concat(parked)),
      expected: expectedNames,
      staged: null,
      refs: new Map(),
      dirty: new Map(),
      probe: null,
      layout: null,
      afterBinds: [],
      parkedLayout: snapshotLayout(set),
      restore: () => 0,
    };
    // The detach's net covered the parked members; from here the pending
    // mount covers those AND this run's fresh members, so it takes the net
    // over. On a throw between here and completion the members go home
    // unbound — the entry failed and rebuilds next run — and the set is laid
    // out so the canvas reads as a grid, not a single button.
    if (restoreOnFailure) {
      pendingSetRestores = pendingSetRestores.filter((r) => r !== restoreOnFailure);
      restoreOnFailure = null;
    }
    mount.restore = () => {
      // Forgotten first, whatever the set's state: a mount left registered
      // over a removed set would be completed — over dead nodes — under the
      // next entry that mounts or looks anything up.
      forgetPendingMount(mount);
      mount.staged = null;
      if (set.removed) return 0;
      let back = 0;
      for (const m of comps.concat(parked)) {
        if (m.removed || m.parent === set) continue;
        set.appendChild(m);
        back += 1;
      }
      defaultSetLayout(set);
      return back;
    };
    pendingSetRestores.push(mount.restore);
    pendingMounts.push(mount);
    pendingBySet.set(set, mount);
    pendingByName.set(setName, mount);
    for (const m of mount.members) pendingByMember.set(m, mount);
    // What this took is a set creation on the fresh path and bookkeeping on
    // the other; billed to `append` so the parts still sum to the total.
    const spent = Date.now() - finishStart;
    finishAppendMs += spent;
    setFinishMs += spent;
    appendSplit.deferMs += spent;
    appendSplit.deferCalls += 1;
    markStep(`${setName}:finish:deferred`);
    if (reassembly === 'eager') completePendingMount(mount);
    return set;
  }
}
