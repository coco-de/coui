/// <reference types="@figma/plugin-typings" />

import { kCanvasOnlyApiNotes } from './canvas-only-notes';
import {
  BuildResult,
  VarLookup,
  canonicalCollection,
  clearNodeIndex,
  RegistryEntry,
  indexDocumentComponents,
  installNodeIndex,
  findComponentsPage,
  findComponentByName,
  kComponentsPageName,
  makeLabel,
  loadFonts,
  pinsSkippedInsideInstance,
  paintOpacityNotHeld,
  collectStaleWrapHolders,
  flushTintLayers,
  ICON_KEYS,
  installGlyphIndex,
  clearGlyphIndex,
  prepareIconModes,
  refreshIconModeCollection,
  drainInexactIconSizes,
  drainSlotIconNotes,
  drainSlotIconWithoutCollection,
  prepareContentColors,
  refreshContentCollections,
  flushContentModes,
  contentFlushLines,
  drainDirectGlyphs,
  drainContentWithoutCollection,
  dropPendingContentGlyphs,
  drainOffScaleRadii,
  drainOffScaleSpaces,
  drainOffScaleSizes,
  drainUnpinnedInstanceBoxes,
  drainKeptSwapDefaults,
  drainRetypedProps,
  formatRetypedProps,
  BuildCost,
  DrawSpan,
  drainResetNodeCost,
  markStep,
  recordDetailSpan,
  restoreDisassembledSets,
  completePendingMounts,
  markReassembledOffPage,
  pendingMountMembers,
  setReassemblyMode,
  findMisPinnedIconModes,
  heldIconModeIndex,
  findUnboundIconSizes,
  installSubProgressListener,
} from './helpers';
import { kSlotStandInPredecessor } from './slot-stand-in';
import type { KeptSwapDefault } from './component-props';
import type { AppendSplit, ReassemblyReport } from './identity';
import { looseMembersOf, peekBuildCost } from './identity';
import {
  RedrawKeepCost,
  abandonRedrawParking,
  reconcileRedrawnMembers,
  resetRedrawFontCache,
  setRedrawKeepsNodes,
} from './redraw-keep';
import {
  formatLastStepRewind,
  markGrowth,
  markLastDone,
  readLastDoneAt,
  readLastStep,
} from './last-step';
import { formatOverlappingSiblings, listOverlappingSiblings } from './overlapping-siblings';
import { GrowthStats, formatGrowth } from './growth';
import { REGISTRY, closeOverNeeds, topoSortRegistry } from './registry';
import { classifyRegistry, formatStaleSets } from './stale-sets';
import { resetUnboundTracking } from './component-props';
import {
  formatSwapDefaultRepairs,
  localCounterpartByKey,
  repairRemoteSwapDefaults,
  type SwapOwnerLike,
  type SwapTargetLike,
} from './swap-default-repair';
import {
  addToUnboundTally,
  emptyUnboundTally,
  formatUnboundSettle,
  formatUnboundTally,
  settleUnboundProps,
} from './unbound-props';
import { formatOrphanNodes, listOrphanNodes } from './orphan-nodes';
import {
  cacheVerdict,
  directPageNameOf,
  formatCacheLine,
  kComponentIndexCacheKey,
  nextComponentIndexCache,
  pageSignature,
  pagesToLoad,
  parseComponentIndexCache,
  resolveCachedIndex,
} from './component-index-cache';
import type { CachedIndexEntry } from './component-index-cache';
import { kHashDataKey, entryContentHashOf, hashStampFor } from './content-hash';
import { kBuildRef, kSharedSourceHash } from './build-hash';
import {
  formatOtherBuildLine,
  judgeOverwrite,
  kGenerationStampKey,
  makeGenerationStamp,
  parseGenerationStamp,
} from './generation-stamp';
import {
  decideRunLock,
  formatRunLockAcquired,
  formatRunLockRefusal,
  formatRunLockTakeover,
  kRunLockDataKey,
  kRunLockTtlMs,
  makeRunLock,
  parseRunLock,
  RunLockRecord,
  RunLockSession,
  withHeartbeat,
} from './run-lock';
import {
  CANONICAL_LIBRARY,
  compareByDocsOrder,
  componentPageNameOf,
  docsOf,
  docsOrderOf,
  isDemotedPageOf,
  kComponentPageNamePrefix,
  pageOrderMoves,
  PageOrderScope,
  pageToReuse,
  withoutPageOrderPrefix,
  plannedPageOrder,
  resolvePlannedPages,
  sectionHeaderPageNameOf,
  hasEntry,
  sectionNameOf,
  slugOfName,
} from './data';
import { renderDocsFrames, resolveCodeFontFamily } from './docs-frames';
import {
  drainTextStyleAttach,
  installTextStyleAttach,
  resetPendingTextStyles,
  sansTargetOf,
  takePendingTextStyles,
} from './text-nodes';
import { isMonoRole } from './compat/v1';
import { loadTextStyleIndex } from './text-styles';
import { drainUnlinkedShadows } from './shadow-style';
import {
  createTextStyleAttacher,
  FacePreload,
  preloadTextStyleFaces,
  TextStyleAttacher,
} from './text-style-attach';
import {
  fingerprintMembers,
  fingerprintNode,
  formatParitySummary,
  kCanvasFingerprintKey,
  parityReport,
  snapshotBeforeOverwrite,
  type SnapshotKind,
  type ParitySetReport,
  type MainComponentCache,
} from './designer-parity';
import iconsJsonRaw from './data/icons.json';
import {
  SET_RENAMES,
  VARIANT_RENAMES,
  STRUCTURAL_MIGRATIONS,
  applyScopedMigrations,
} from './renames';


// The content-hash recipe (`kHashDataKey`, `entryContentHashOf`) lives in
// `./content-hash` — imported here and by `stale-sets.ts`, not defined in
// either. See that file for why: this module used to own the recipe with
// `stale-sets.ts` importing it back, and that back-edge made the recipe's
// evaluation order depend on which of the two a bundler loaded first.
const kCanonicalLibraryDataKey = 'coui-canonical-library';

// A page name from the previous `{Section} / {Name}` scheme.
//
// Four names, not the ten sections that exist now: this pattern describes
// page names a PAST run could have written, and the old scheme only ever
// ran under the four-way fold. `Overlay / Dialog` was never a page. Read by
// the tail's cleanup (drains and removes them) and by the load prelude (a
// document still carrying one needs the full walk — #4803).
const kOldSchemePage = /^(Display|Control|Form|Layout) \/ /;
// #5008 — NFR-007's unit is a run's OWN scope, not "whatever REGISTRY holds
// this week". `formatNfrEReport` only gates a run that is itself scoped to a
// section/component selection (`m.scoped`) against these two — a full run is
// judged against `kFullRunObservationCeilingMs` below instead, never these.
// The redefinition changes which run these apply to, not the numbers: a
// scoped run rebuilding one section is still the unit the 5-minute figure
// was set against.
const kFiveMinutesMs = 5 * 60 * 1000; // NFR-007
// #4038 (C5/R-3) — 2× the budget is the renegotiation trigger for a SCOPED
// run, not a second warning: past this the answer is to split the run
// further by section (the escape hatch below points at the UI that does
// it), never to build less.
const kTenMinutesMs = 2 * kFiveMinutesMs;
// #5008 — a full run (no section/entry scope) is not held to NFR-007 at
// all: rebuilding the whole catalog in one pass is a real, supported use of
// this plugin (the weekly full-catalog refresh), not an escape hatch R-3
// exists to close off, and "split it" is not an answer to a run that was
// already asked to build everything. This ceiling is observation-only — it
// never recommends a split and never blocks anything — so a full run that
// has quietly grown much slower than the last measured baseline (09-18:
// 1665.0s / 27.8min) leaves a line in the log instead of nobody noticing
// until the next time someone happens to time it by hand.
const kFullRunObservationCeilingMs = 40 * 60 * 1000;

// #3740 (A-1b) — warns, never blocks. The canonical document has to stay
// movable: a hard gate would lock the plugin out the moment it moves, and
// people would route around the check — worse than the drift it prevents.
// The stamp is only text inside the document, so it tells a new document
// from a known one but not "the" canonical file (that needs figma.fileKey,
// which Figma gives only to private organization plugins). A file
// that has never seen this stamp gets it silently — that's the normal
// "first run in a fresh document" case, not a mismatch to warn about.
function checkCanonicalLibrary(): string | null {
  const identifier = CANONICAL_LIBRARY.identifier;
  if (!identifier) return null; // record itself not set up yet — nothing to compare
  const stamped = figma.root.getPluginData(kCanonicalLibraryDataKey);
  if (!stamped) {
    figma.root.setPluginData(kCanonicalLibraryDataKey, identifier);
    return null;
  }
  if (stamped === identifier) return null;
  return (
    `⚠ This document is stamped "${stamped}", not the recorded CoUI library ` +
    `"${identifier}" (${CANONICAL_LIBRARY.displayName ?? identifier}) — continuing anyway. ` +
    `See the "Figma 라이브러리" guide on docs_site if this is unexpected.`
  );
}

// How often a big builder's loop leaves its growth footprint in the document
// (`markGrowth`). 25 puts the last one within 25 combos of wherever a realm
// died — the run that stopped at 334/972 would have left 325's.
const kGrowthFootprintEvery = 25;

export interface GenerateProgress {
  index: number;
  total: number;
  name: string;
  elapsedMs: number;
  /** Progress WITHIN this entry's own `build()` — present only while a
   *  builder big enough to report it (currently just Button, see
   *  `helpers.ts`'s `reportSubProgressAndYield`) is still running; absent
   *  once the entry's own `onProgress` fires (that call already carries the
   *  final `elapsedMs`, which supersedes it) and absent for every other
   *  entry, which finishes too fast to be worth reporting mid-build. The
   *  end-of-run text-style attach pass reports the same way, under the name
   *  `텍스트 스타일` with `index === total`. */
  sub?: { current: number; total: number };
  /** Log lines pushed since the previous progress message — the run's log,
   *  streamed. The full log still arrives whole at `done`; this exists for
   *  the run that never gets there. A realm that dies mid-run posts nothing,
   *  and until this the UI showed exactly that: nothing. Absent when no line
   *  was added since the last message. */
  logTail?: string[];
}

// The 144-entry build loop below itself never `await`s anything of its own —
// every builder's `build()` is synchronous scene-graph work, save for the one
// exception (Button, see helpers.ts) that opts into yielding via its own
// `Promise<BuildResult>` return. A Figma plugin's main code and its UI
// iframe share the same render thread, so a purely
// synchronous run blocks the browser from painting anything, `postMessage`
// included, until the whole loop returns: the progress bar's *container*
// appears the instant Generate is clicked (that happens before this loop
// starts), but every `type: 'progress'` message sent during the run gets
// coalesced and only delivered once there's finally a tick to deliver them
// on — which reads as "the box is there, the percentage never moves." A
// `setTimeout(0)` yield after each report hands that tick back. Gated on
// `onProgress` being present so callers that don't want to watch (selftests,
// `verifyIdentityIdempotence`'s replay) don't pay the yield's wall-clock cost.
async function reportProgress(
  onProgress: ((p: GenerateProgress) => void) | undefined,
  p: GenerateProgress,
): Promise<void> {
  if (!onProgress) return;
  onProgress(p);
  await new Promise<void>((resolve) => setTimeout(resolve, 0));
}

// Builds every registered component onto a 🧩 Components page, laid out in
// one column per section.
//
// Mint-by-name (#3737) — this function never removes a persistent
// COMPONENT/COMPONENT_SET. Renamed or reshaped entries are handled
// explicitly up front via src/renames.ts; everything else is found by name
// (mint()/mountSet(), called from inside each builder) and reused in place,
// so `id`/`key` survive a re-run.
//
// Per-entry failure (#3738) — a builder throw takes that entry out of the run
// and leaves the rest alone. Nothing is deleted before a build (mint-by-name),
// and a recycled node left half-mutated by a throwing builder is `resetNode`-d
// to blank the next time its name is minted, so the recovery is the next run
// rather than an undo. See the catch below for why the undo had to go.
//
// Content-hash skip (#3739) — an entry whose build-recipe hash already
// matches what's stamped on its persistent node is left completely
// untouched (not even reset), so a second run with no code/data changes
// reports `skipped` for every entry — the identity-idempotence self-check
// this enables lives in a separate opt-in `verify` command (#3739).
// Section-block order — the docs catalog's curated group order
// (`docs_core/lib/shared/component_catalog.dart`'s `kDocsComponentGroups`),
// not the alphabet. Module-level (not local to `generateComponents`) because
// `listRegistryEntries` below needs the same order the run itself uses —
// two copies of this list is exactly the drift `sectionOfEntry` already
// warns about for the section lookup itself.
export const kPageSectionOrder = [
  'Control',
  'Form',
  'Display',
  'Layout',
  'Navigation',
  'Menu',
  'Overlay',
  'Icon',
  'Text',
  'Infra',
];

// Component-page name → section, derived once from the registry — the page
// name itself no longer carries the section segment (D-27), so callers read
// this instead of parsing names.
//
// Two sources answer it, and the data is preferred. `section` in
// components.json is the fold of coui_flutter's category directories; the
// REGISTRY entry's own `section` is this plugin's declaration. The fold is
// near-identity now, so the two agree by construction wherever the data can
// answer at all.
//
// The fallback exists because the data cannot answer for a component that
// has no directory of its own. Four of them are sub-components living in a
// parent's file (`AvatarBadge` in `display/avatar/avatar.dart`), one is
// infra whose filename spells the slug differently
// (`scrollview_interceptor.dart` vs `scroll_view_interceptor`), and one has
// no widget class at all. All six declare a section right here in the
// REGISTRY.
//
// Module-level for the same reason as `kPageSectionOrder` above:
// `listRegistryEntries` (the UI's component tree) and `generateComponents`
// (the run itself) must resolve a name to the same section, or the tree the
// user checks boxes in disagrees with what the run actually scopes by.
/**
 * `Panel → Avatar · Size=md` for each swap default left on a designer's pick.
 *
 * Named here rather than where it is recorded: a builder is synchronous, and
 * under `documentAccess: "dynamic-page"` a node is looked up by id only through
 * the async call. An id that no longer resolves is printed as the id with that
 * said — the line still names the property, which is what a reader acts on.
 */
async function describeKeptSwapDefaults(kept: readonly KeptSwapDefault[]): Promise<string> {
  const parts: string[] = [];
  for (const k of kept) {
    // Not resolving is its own finding: the default points at a node the
    // document no longer has, which is no one's choice — say so.
    let label = `${k.id}(문서에 없는 노드)`;
    try {
      const node = await figma.getNodeByIdAsync(k.id);
      if (node) {
        const parent = node.parent;
        label = parent && parent.type === 'COMPONENT_SET' ? `${parent.name} · ${node.name}` : node.name;
      }
    } catch {
      // keep the id
    }
    parts.push(`${k.prop} → ${label}`);
  }
  return parts.join(', ');
}

export function sectionOfEntry(e: RegistryEntry): string | null {
  const entrySlug = e.dataSlug ?? slugOfName(e.name);
  const fromData = sectionNameOf(entrySlug);
  if (fromData !== null) return fromData;
  return kPageSectionOrder.includes(e.section) ? e.section : null;
}

/**
 * Runs a page move, loading whatever fonts Figma says it needs first.
 *
 * Moving a page can fail with `unloaded font "…"` for the text on that page
 * — measured on the library file, moving a preview page threw for four
 * Pretendard faces the run had never loaded. The error names the exact
 * `loadFontAsync` call, so this loads those faces and tries again rather than
 * loading every font of every page up front.
 */
async function withPageFontsLoaded(move: () => void): Promise<void> {
  for (let attempt = 0; ; attempt++) {
    try {
      move();
      return;
    } catch (e) {
      const kNeeded = /loadFontAsync\(\{ family: "([^"]+)", style: "([^"]+)" \}\)/g;
      const message = String((e as Error)?.message ?? e);
      const faces: FontName[] = [];
      for (let m = kNeeded.exec(message); m !== null; m = kNeeded.exec(message)) {
        faces.push({ family: m[1], style: m[2] });
      }
      if (faces.length === 0 || attempt >= 8) throw e;
      for (const face of faces) await figma.loadFontAsync(face);
    }
  }
}

/**
 * The `draw` remainder, cut up by the kind of work — `[icon 812.3s/864 ·
 * geom 201.1s/432 · 미계측 170.6s]`.
 *
 * Sorted by cost and printed as `seconds/calls`, because the total alone does
 * not say what to do: 200s spread over 50,000 binds is a different problem,
 * with a different fix, from 200s in 5 layout flushes.
 *
 * Empty buckets are dropped rather than printed as `0.0s/0` — a builder
 * touches maybe four of the eight, and six zeroes per line would bury the two
 * numbers worth reading.
 *
 * `미계측` is what the named spans do not reach, and it is printed even when
 * it is the largest item. That is the honest shape of this line: it started
 * as one remainder called `draw`, and every span added since has been carved
 * out of it. What is left is the next place to look, not an error — so it has
 * to stay visible rather than be folded into the biggest neighbour.
 *
 * `besideMs` is what the second line names (`detach` / `define` / `props` /
 * `tints` / `attach` — `DetailSpan` in identity.ts). Not printed in this bracket, whose
 * bucket list older logs are read against, but named all the same, so it comes
 * off the remainder: left in, `미계측` would count time the next line accounts
 * for.
 */
function drawBreakdown(
  spans: Record<DrawSpan, { ms: number; calls: number }>,
  drawMs: number,
  besideMs: number,
): string {
  const parts: { label: string; ms: number; calls: number }[] = [];
  let named = 0;
  for (const key of Object.keys(spans) as DrawSpan[]) {
    const cost = spans[key];
    // A span with time but no calls is `yield` on a loop whose every call sat
    // inside the budget: reported, never ticked. Its milliseconds are named
    // rather than left to the remainder.
    if (cost.calls === 0 && cost.ms === 0) continue;
    parts.push({ label: key, ms: cost.ms, calls: cost.calls });
    named += cost.ms;
  }
  if (parts.length === 0) return '';
  parts.sort((a, b) => b.ms - a.ms);
  const rendered = parts.map((p) => `${p.label} ${(p.ms / 1000).toFixed(1)}s/${p.calls}`);
  // Clamped at zero: the spans are measured with the same clock as `buildMs`
  // and cannot honestly exceed it, but a few milliseconds of rounding across
  // thousands of calls should not be able to print a negative remainder and
  // make the whole line look broken.
  const unmeasured = Math.max(0, drawMs - named - besideMs);
  rendered.push(`미계측 ${(unmeasured / 1000).toFixed(1)}s`);
  return `[${rendered.join(' · ')}]`;
}

/** The milliseconds `drawBreakdown` takes off the remainder beyond its own bracket. */
function besideMsOf(cost: BuildCost): number {
  const beside = cost.detail.spans;
  return (
    beside.detach.ms +
    beside.define.ms +
    beside.props.ms +
    beside.tints.ms +
    beside.attach.ms +
    beside.stage.ms +
    (cost.keep?.ms ?? 0)
  );
}

/**
 * ` · 유지 kept 12 / replaced 3 (0.4s; children 2 · main 1)` — what the redraw
 * kept of the old inner nodes (`redraw-keep.ts`). `kept` are the old top-level
 * children that stayed, so the overrides on them survived; `replaced` are the
 * ones that went, with why. Empty when nothing was parked, so a line with
 * nothing to keep reads byte for byte as it did before keeping existed.
 */
export function formatKeepCost(keep: RedrawKeepCost | undefined): string {
  if (keep === undefined || keep.kept + keep.replaced === 0) return '';
  const reasons = Object.keys(keep.reasons)
    .sort((a, b) => keep.reasons[b] - keep.reasons[a])
    .map((r) => `${r} ${keep.reasons[r]}`);
  return (
    ` · 유지 kept ${keep.kept} / replaced ${keep.replaced} (${(keep.ms / 1000).toFixed(1)}s` +
    `${reasons.length > 0 ? `; ${reasons.join(' · ')}` : ''})`
  );
}

/**
 * The two `⏱` lines for one slow entry.
 *
 * Line one keeps the shape older logs have, field for field, because those
 * logs are what a new number gets compared against. Only `미계측` moves, and
 * it moves down by exactly what line two names — the regions carved out after
 * line one's shape was fixed (`formatBuildDetail`).
 *
 * Pure, so the arithmetic is checked off-sandbox (selftest-nfr-e-report).
 */
export function formatBuildTiming(name: string, buildMs: number, cost: BuildCost): string[] {
  // `draw` is what is LEFT after the named spans — and it is labelled as a
  // remainder rather than as a measurement, because that is what it is.
  // This used to be called `populate` and computed the same way, which
  // made `reset + populate = build` an arithmetic identity: the two
  // numbers summed to the total even if the reset counter were entirely
  // wrong, so the line could never show a gap. Naming more spans is what
  // makes the remainder mean something — it shrinks as the accounting
  // improves, and what it still holds is what nobody has measured yet.
  const drawMs = buildMs - cost.ms - cost.finishMs;
  const mix = `${cost.recycled} recycled / ${cost.minted} minted`;
  return [
    `⏱ ${name}: build ${(buildMs / 1000).toFixed(1)}s — reset ` +
      `${(cost.ms / 1000).toFixed(1)}s (${cost.calls} node(s), ` +
      `${cost.childRemovals} child removal(s)) · finish ` +
      `${(cost.finishMs / 1000).toFixed(1)}s · draw(나머지) ` +
      `${(drawMs / 1000).toFixed(1)}s ${drawBreakdown(cost.spans, drawMs, besideMsOf(cost))}` +
      ` · ${mix}${formatKeepCost(cost.keep)}`,
    formatBuildDetail('⏱', name, cost),
  ];
}

/**
 * `⏱ Button: 세부 — detach 0.9s · define 0.4s/7 · props 38.8s/6804 · tints 0.1s
 * · attach 12.0s/972 · stage 1.9s/1942 · finish 714.8s (append 700.1s · post 0.2s · layout 14.5s) · yield 95.6s/12
 * (mark 60.1s · post 30.2s · tick 5.3s · 보고 972) · 증가 loop[…] props[…] define[…] attach[…]`.
 *
 * `yield`'s count is the real ticks; `보고` is every call — the listener and
 * the mark ran that many times (`kYieldBudgetMs`, helpers.ts).
 *
 * Every field prints every time, zeros included. Line one drops empty buckets
 * because it is read for its biggest numbers; this line is read across runs by
 * position, and a field that vanishes at zero looks exactly like a field
 * nobody measured.
 *
 * `mark` is the leading glyph — `⏱` on a finished entry, `↯` under a failure's
 * partial breakdown — so a grep for either keeps its line pair together.
 */
export function formatBuildDetail(mark: string, name: string, cost: BuildCost): string {
  const secs = (ms: number): string => `${(ms / 1000).toFixed(1)}s`;
  const d = cost.detail;
  return (
    `${mark} ${name}: 세부 — detach ${secs(d.spans.detach.ms)} · ` +
    `define ${secs(d.spans.define.ms)}/${d.spans.define.calls} · ` +
    `props ${secs(d.spans.props.ms)}/${d.spans.props.calls} · tints ${secs(d.spans.tints.ms)} · ` +
    `attach ${secs(d.spans.attach.ms)}/${d.spans.attach.calls} · ` +
    `stage ${secs(d.spans.stage.ms)}/${d.spans.stage.calls} · ` +
    `finish ${secs(cost.finishMs)} (append ${secs(d.finish.appendMs)} · ` +
    `post ${secs(d.finish.postMs)} · layout ${secs(d.finish.layoutMs)}` +
    `${d.finish.offPage ? ' · 페이지 밖' : ''}) · ` +
    `yield ${secs(cost.spans.yield.ms)}/${cost.spans.yield.calls} ` +
    `(mark ${secs(d.yieldSplit.markMs)} · post ${secs(d.yieldSplit.postMs)} · ` +
    `tick ${secs(d.yieldSplit.tickMs)} · 보고 ${d.yieldSplit.reports}) · ` +
    `증가 ${formatGrowth('loop', d.growth.loop)} ${formatGrowth('props', d.growth.props)} ` +
    `${formatGrowth('define', d.growth.define)} ${formatGrowth('attach', d.growth.attach)} · ` +
    formatAppendSplit(d.appendSplit, d.appendGrowth) +
    formatKeepSplit(cost.keep)
  );
}

/**
 * ` · 유지 분해 (snapshot 120.0s/6210 · apply 900.0s · verify 300.0s/6210 ·
 * 변경 없음 6000 · 정리 40.0s · remap 10.0s · 나머지 3.5s · 줄인 읽기 90000)
 * 유지[972: first100 …]` — the keep time on line one, cut into the steps one
 * member takes (#5009). The six timed parts sum to that time. `변경 없음` counts
 * the read-back nodes that nothing was written over after `apply` read them;
 * `줄인 읽기` the field reads the type table left out, and `필드표 밖` (only
 * when there is one) the types the table was wrong about this run.
 *
 * Empty where nothing was parked — the same rule line one's keep field has —
 * and after `append 분해`, so every field before it sits where it did.
 */
export function formatKeepSplit(keep: RedrawKeepCost | undefined): string {
  if (keep === undefined || keep.split === undefined || keep.kept + keep.replaced === 0) return '';
  const secs = (ms: number): string => `${(ms / 1000).toFixed(1)}s`;
  const k = keep.split;
  const rest = Math.max(0, keep.ms - k.snapshotMs - k.applyMs - k.verifyMs - k.tidyMs - k.remapMs);
  return (
    ` · 유지 분해 (snapshot ${secs(k.snapshotMs)}/${k.snapshotNodes} · apply ${secs(k.applyMs)} · ` +
    `verify ${secs(k.verifyMs)}/${k.verifyNodes} · 변경 없음 ${k.cleanNodes} · ` +
    `정리 ${secs(k.tidyMs)} · remap ${secs(k.remapMs)} · 나머지 ${secs(rest)} · ` +
    `줄인 읽기 ${k.skippedReads}${k.fullReadTypes.length > 0 ? ` · 필드표 밖 ${k.fullReadTypes.join(',')}` : ''}) ` +
    formatGrowth('유지', k.memberGrowth)
  );
}

/**
 * `append 분해 (defer 0.1s/1 · flush 1.2s/972 · 이름 0.0s · appendChild 690.0s/972
 * · vp읽기 9.0s/972 · parked 0.0s/0) append[972: first100 …]` — the `append`
 * inside the finish bracket, cut again (#5009). The six parts sum to that
 * `append`: `defer` is `finish()` itself, the other five its reassembly.
 *
 * Last on the line on purpose: the line is compared across runs by position,
 * and everything before this reads exactly as it did before the cut.
 */
export function formatAppendSplit(a: AppendSplit, growth: GrowthStats): string {
  const secs = (ms: number): string => `${(ms / 1000).toFixed(1)}s`;
  return (
    `append 분해 (defer ${secs(a.deferMs)}/${a.deferCalls} · ` +
    `flush ${secs(a.flushMs)}/${a.flushCalls} · 이름 ${secs(a.checkMs)} · ` +
    `appendChild ${secs(a.appendChildMs)}/${a.appendChildCalls} · ` +
    `vp읽기 ${secs(a.readbackMs)}/${a.readbackCalls} · ` +
    `parked ${secs(a.parkedMs)}/${a.parkedCalls}) ${formatGrowth('append', growth)}`
  );
}

/**
 * Whether a cost carries anything the detail line shows. A failure prints that
 * line on this rather than on its reset: an entry that minted every member and
 * then threw has spent nothing in `reset`, and may still have yielded through
 * its loop, detached a set, defined properties or died inside `finish`.
 */
function hasBuildDetail(cost: BuildCost): boolean {
  const d = cost.detail.spans;
  for (const span of [d.detach, d.define, d.props, d.tints, d.attach, d.stage]) {
    if (span.ms > 0 || span.calls > 0) return true;
  }
  return (
    cost.finishMs > 0 ||
    cost.spans.yield.ms > 0 ||
    cost.spans.yield.calls > 0 ||
    cost.detail.yieldSplit.reports > 0
  );
}

/**
 * The `↯` lines for an entry that threw, from what it had spent by then.
 *
 * Line one is the one this path has always printed — the reset and the draw
 * bracket, its remainder net of line two — and it still prints only when the
 * entry reset something, which is what its head reports. Line two prints
 * whenever there is detail to show (`hasBuildDetail`), reset or not.
 *
 * No Figma calls, so the arithmetic is checked off-sandbox
 * (selftest-nfr-e-report).
 */
export function formatFailureTiming(name: string, spentMs: number, cost: BuildCost): string[] {
  const lines: string[] = [];
  if (cost.ms > 0) {
    lines.push(
      `↯ ${name}: 실패 전 reset ${(cost.ms / 1000).toFixed(1)}s ` +
        `(${cost.calls} node(s)) — 이 비용은 이 엔트리의 것이다 ` +
        drawBreakdown(cost.spans, spentMs - cost.ms - cost.finishMs, besideMsOf(cost)),
    );
  }
  if (cost.ms > 0 || hasBuildDetail(cost)) lines.push(formatBuildDetail('↯', name, cost));
  return lines;
}

/** What the `✎` line names besides the labels. */
export interface AttachOverhead {
  /** The faces the styles draw in, loaded once before the first entry. */
  fontLoadMs: number;
  faces: number;
}

/** Labels that carried a decoration when their style arrived, and how many
 *  needed it written back afterward. */
export interface AttachDecoration {
  before: number;
  restored: number;
}

/**
 * The `✎` line — how many labels got their style and how long that took, then
 * the face preload, then what happened to the labels that carried an underline,
 * then how the per-label cost moved across the run.
 *
 * The seconds are the attaches summed over the entries that drew the labels,
 * plus the preload. The attach used to be one pass with a wall time of its own
 * (752s over 972 labels on one Button run); inside the entries there is no such
 * block, so the head keeps its shape and states the sum instead.
 *
 * The underline segment prints only when some label carried one. A style
 * always clears it (measured on a real Button run — see `attach`'s own
 * note), so `attach` always writes it back; this line just says how many
 * needed that.
 */
export function formatTextStyleAttachLine(
  attached: number,
  queued: number,
  ms: number,
  overhead: AttachOverhead,
  growth: GrowthStats,
  decoration: AttachDecoration = { before: 0, restored: 0 },
): string {
  const secs = (v: number): string => `${(v / 1000).toFixed(1)}s`;
  const underline =
    decoration.before > 0 ? ` · 밑줄 ${decoration.restored}/${decoration.before} 복원` : '';
  return (
    `✎ 텍스트 스타일 ${attached}/${queued} 노드 부착 (${secs(ms)})` +
    ` · 글꼴 로드 ${secs(overhead.fontLoadMs)}/${overhead.faces}종` +
    underline +
    ` · 증가 ${formatGrowth('label', growth)}`
  );
}

/** `parityPhaseMs` by what it was spent on — see `NfrEMeasurement.paritySplit`. */
export interface ParitySplit {
  preMs: number;
  snapshotMs: number;
  stampMs: number;
  parityMs: number;
}

/**
 * Accrues the pre-overwrite block, `startedAt` to `endedAt`, which holds one
 * copy of `snapshotMs`. The copy is its own part and the reads around it are
 * the rest, so the block's milliseconds land in the split exactly once.
 *
 * Returns what the block adds to the phase total. No Figma calls, so the
 * arithmetic is checked off-sandbox (selftest-nfr-e-report).
 */
export function addPreOverwrite(
  split: ParitySplit,
  startedAt: number,
  endedAt: number,
  snapshotMs: number,
): number {
  const blockMs = endedAt - startedAt;
  split.snapshotMs += snapshotMs;
  split.preMs += blockMs - snapshotMs;
  return blockMs;
}

/**
 * Accrues the post-draw block: the fingerprint stamp from `startedAt` to
 * `stampedAt`, then the designer comparison from `parityFrom` to `endedAt`.
 * The `:parity` mark between `stampedAt` and `parityFrom` is in neither part
 * and not in the total (`markStep` in last-step.ts says why). A stamp that
 * threw arrives with `stampedAt` null, and the block bills to `stamp`, the part
 * that was running.
 *
 * Returns what the block adds to the phase total — the parts, summed.
 */
export function addStampAndParity(
  split: ParitySplit,
  startedAt: number,
  stampedAt: number | null,
  parityFrom: number | null,
  endedAt: number,
): number {
  if (stampedAt === null) {
    const stampMs = endedAt - startedAt;
    split.stampMs += stampMs;
    return stampMs;
  }
  const stampMs = stampedAt - startedAt;
  // Unreachable in practice — `markStep` cannot throw — and read as no gap.
  const parityMs = endedAt - (parityFrom ?? stampedAt);
  split.stampMs += stampMs;
  split.parityMs += parityMs;
  return stampMs + parityMs;
}

// The UI's component tree (per-entry checkboxes nested under a section, #4526
// — the section-only scope let checking one section's box drag along every
// sibling in it, which is what happened when `Form` pulled in eleven
// unrelated failures alongside the one component the run actually wanted).
// Reads the SAME section resolution the run itself uses (`sectionOfEntry`),
// so a component the tree shows under `Form` is the one `entryNames: ['X']`
// actually reaches — two independent section answers is the drift this file
// already warns about for the page-placement lookup.
//
// Order is `kPageSectionOrder` first (matching the section blocks the UI
// renders), then declaration order within a section — REGISTRY's own order,
// which is dependency order, not the alphabet (see `topoSortRegistry`
// below), but stable across calls so the UI doesn't reshuffle on every open.
export function listRegistryEntries(): { section: string; name: string }[] {
  return REGISTRY.map((e) => ({ section: sectionOfEntry(e) ?? 'Other', name: e.name })).sort(
    (a, b) => {
      const sectionDelta = kPageSectionOrder.indexOf(a.section) - kPageSectionOrder.indexOf(b.section);
      return sectionDelta !== 0 ? sectionDelta : 0;
    },
  );
}

// #4038 (C5/R-3) — section-scoped run. The 5-minute budget (NFR-007) was
// negotiated when a full run rebuilt one page; 4-axis sets (Button 972) and
// docs frames push a cold full rebuild well past it every time (#5008: the
// budget names a run's own scope, not the size REGISTRY happens to be — a
// full run is measured against a separate, non-gating ceiling instead, see
// `kFullRunObservationCeilingMs`). The escape hatch these options give a
// caller is scope, not feature loss: run one section at a time — untouched
// sections' pages are left exactly as they were (their entries never enter
// the loop), and the per-entry hash still skips anything unchanged inside
// the chosen scope.
//
// #4526 (component tree) — `entryNames` is the finer sibling of `sections`:
// an exact set of REGISTRY names rather than whole sections, so checking one
// component in the UI's tree does not drag its section-mates in with it.
// When both are given, `entryNames` wins outright — it is the more specific
// answer, and a caller that sets both is asking a contradictory question the
// coarser one should not get to silently resolve.
export interface GenerateOptions {
  /** v3 section names to build — the docs catalog's groups (`Control` /
   *  `Form` / `Display` / `Layout` / `Navigation` / `Menu` / `Overlay` /
   *  `Icon` / `Text` / `Infra`). Absent/empty = full run. Ignored when
   *  `entryNames` is given. */
  sections?: readonly string[];
  /** Exact REGISTRY entry names to build — the UI's component tree. Wins
   *  over `sections` when both are present. Absent/empty = fall back to
   *  `sections` (or a full run if that is absent too). */
  entryNames?: readonly string[];
  /** How much of the page list this run may rearrange.
   *
   *  Absent = `true`, which is what a fresh file needs — the sidebar arrives
   *  in catalog order with a header page per section instead of 180-odd pages
   *  in creation order. The plugin's own pages (component pages and section
   *  headers) are put in plan order with the fewest moves; everyone else's
   *  pages — dividers, demoted notes, previews — are never moved themselves.
   *
   *  `false` moves no existing page, so a run cannot undo how someone
   *  arranged the file. Pages this run created are still placed in their
   *  section — they have no arrangement to respect, and `createPage` would
   *  otherwise leave them at the end of the file. A section with pages but no
   *  header gets its header in either case; that header is one of the pages
   *  the run created. */
  reorderPages?: boolean;
  /** Ignore the per-entry content hash and rebuild every entry in scope.
   *
   *  Absent = `false`: an entry whose recipe has not changed is skipped, which
   *  is what makes a normal run cheap and is right almost always — the hash
   *  already covers the whole plugin source, so an edit anywhere invalidates
   *  everything that could have been affected by it.
   *
   *  `true` exists for the case the hash cannot see: the canvas is wrong for a
   *  reason that never went through this code. A member edited by hand, a
   *  half-finished run, a file restored from version history — the recipe is
   *  unchanged, so the hash says "skip" and is telling the truth about the
   *  recipe while the canvas stays wrong. Forcing is how the file gets told to
   *  match the code regardless of what it thinks it already knows. */
  force?: boolean;
  /** 덮어쓰기 전에 손 편집을 보존한다 (`designer-parity.ts`).
   *
   *  Absent = `true`: 다시 그릴 세트의 캔버스 지문이 지난 실행이 남긴 것과
   *  다르면 — 그 사이에 디자이너가 손댔다는 뜻 — `<이름> (이전 · 시각)`
   *  프레임으로 옆에 복제한 뒤 그린다(세트당 하나, 이전 것은 대체). 지문이
   *  같으면 복제하지 않는다.
   *  `false` 는 그 검사와 복제를 통째로 건너뛴다. */
  preserveHandEdits?: boolean;
  /** 지문이 **없는** 세트(이 기능이 들어오기 전에 그려진 것)도 덮어쓰기 전에
   *  복제한다. 지문이 없으면 손이 닿았는지 알 길이 없다 — 보수적으로 전부
   *  보존하면 첫 전체 실행에서 세트 수만큼 프레임이 생기고, 보존하지 않으면
   *  그 실행이 지우는 손 편집을 아무도 못 본다. 어느 쪽이 맞는지는 파일을
   *  아는 사람이 정하므로 옵션이다. Absent = `false`. */
  snapshotUnfingerprinted?: boolean;
  /** 재조립(멤버 되붙이기) 동안 현재 페이지를 다른 페이지로 옮긴다.
   *
   *  가설: 현재 페이지에 있는 세트에 972 멤버를 되붙이면 붙일 때마다 렌더러가
   *  갱신되고, 다른 페이지가 열려 있으면 그 갱신이 빠진다. 아직 측정되지
   *  않았으므로 옵션이다 — 켜고 끈 두 실행의 ⏱ `finish` 를 비교하고, 성능
   *  프로브의 "세트가 현재 페이지일 때 / 아닐 때" 행을 본다. 효과가 0 이면
   *  이 옵션은 지워진다. Absent = `false`. 페이지가 하나뿐인 문서에서는 옮길
   *  곳이 없어 그대로 돈다. */
  reassembleOffPage?: boolean;
  /** 다시 그릴 때 멤버 안쪽 노드를 유지한다(`redraw-keep.ts`) — 디자이너 사본의
   *  인스턴스가 안쪽 레이어에 덮어쓴 값은 노드에 붙어 있어서, 노드를 지우고 새로
   *  만들면 풀린다. Absent = `true`. `false` 는 옛 순서(지우고 다시 만든다). */
  keepInnerNodes?: boolean;
  /** 실행 끝에 이번 실행이 그린 세트들의 디자이너 대조 전체 결과를 받는다 —
   *  로그의 `⇄` 줄은 14 줄에서 잘리지만 이것은 잘리지 않는다. 호출자(플러그인
   *  진입점)가 JSON 봉투로 내려보낸다. 지문/대조 자체는 이 콜백 유무와 무관하게
   *  돈다. */
  onDesignerParity?: (sets: ParitySetReport[]) => void;
}

/**
 * Imports every Lucide glyph main by key.
 *
 * Extracted so the prelude and the per-entry refresh cannot drift: two copies
 * of this loop would be two answers to "which handles does this run hold",
 * and the second answer only shows up an hour into a run.
 *
 * A failed import is collected, never thrown — the prelude runs before the
 * entry loop, so throwing would take the whole run rather than only the
 * entries that draw that glyph.
 */
async function importGlyphs(): Promise<{
  index: Map<string, ComponentNode>;
  failures: string[];
}> {
  const index = new Map<string, ComponentNode>();
  const failures: string[] = [];
  for (const name of Object.keys(ICON_KEYS)) {
    try {
      index.set(name, await figma.importComponentByKeyAsync(ICON_KEYS[name]));
    } catch (err) {
      failures.push(`${name} (${String(err)})`);
    }
  }
  return { index, failures };
}

// ─── Run lock (#4831) — one Generate per file at a time ─────────────────────
//
// The decision is `src/run-lock.ts`; this is the half that touches `figma`.
// Session identity is `figma.currentUser.sessionId` (manifest: `currentuser`)
// and, when that is not available, an id minted once per plugin load — two
// sessions can never share either, and one session's consecutive runs do
// (verify's idempotence replay calls `generateComponents` twice in a row).
const kThisPluginLoad = `load-${Math.random().toString(36).slice(2, 10)}`;
/** Rewrite the heartbeat at most this often — a root plugin-data write syncs
 *  to every client. `touchRunLock` is called at each entry's start and from
 *  the sub-progress listener (`entryProgressListener`) on every combo of a big
 *  builder, so this throttle, not the call rate, sets the write rate: an entry
 *  that draws for 25 minutes writes about fifty times, not once. */
const kRunLockWriteEveryMs = 30_000;
let activeRunLock: RunLockRecord | null = null;
let lastRunLockWriteMs = 0;

interface RunLockStore {
  getPluginData(key: string): string;
  setPluginData(key: string, value: string): void;
}

// The double behind the harnesses has no `root`; a run there proceeds
// unlocked and says so. Real Figma always has one.
function runLockStore(): RunLockStore | null {
  const root = (figma as { root?: unknown }).root as Partial<RunLockStore> | undefined;
  if (!root || typeof root.getPluginData !== 'function' || typeof root.setPluginData !== 'function') {
    return null;
  }
  return root as RunLockStore;
}

function currentRunSession(): RunLockSession {
  let user: User | null = null;
  try {
    // `?? null`: a double without the property reads `undefined`, not `null`.
    user = (figma as { currentUser?: User | null }).currentUser ?? null;
  } catch {
    user = null; // no `currentuser` permission — fall back to the per-load id
  }
  return {
    sessionId: user !== null && user.sessionId !== undefined ? `s${user.sessionId}` : kThisPluginLoad,
    user: user !== null && user.name !== '' ? user.name : '(이름 없음)',
  };
}

function runLockScopeOf(options?: GenerateOptions): string {
  if (options?.entryNames && options.entryNames.length > 0) return options.entryNames.join(', ');
  if (options?.sections && options.sections.length > 0) return options.sections.join(', ');
  return 'all';
}

export function acquireRunLock(options?: GenerateOptions): { refused: boolean; lines: string[] } {
  const store = runLockStore();
  if (store === null) return { refused: false, lines: ['⚠ 실행 잠금: 문서 루트가 없어 잠금 없이 진행한다'] };
  let raw = '';
  try {
    raw = store.getPluginData(kRunLockDataKey);
  } catch (e) {
    return { refused: false, lines: [`⚠ 실행 잠금: 읽기 실패 (${String(e)}) — 잠금 없이 진행한다`] };
  }
  const now = Date.now();
  const me = currentRunSession();
  const decision = decideRunLock(raw, me, now, readLastStep().markedAt);
  const lines: string[] = [];
  if (decision.action === 'refuse') {
    return { refused: true, lines: [formatRunLockRefusal(decision.held, decision.quietMs, kRunLockTtlMs)] };
  }
  if (decision.action === 'takeover') {
    lines.push(formatRunLockTakeover(decision.stale, decision.quietMs, kRunLockTtlMs));
  }
  const record = makeRunLock(me, now, `${kSharedSourceHash} ${kBuildRef}`, runLockScopeOf(options));
  try {
    store.setPluginData(kRunLockDataKey, JSON.stringify(record));
  } catch (e) {
    return { refused: false, lines: [...lines, `⚠ 실행 잠금: 쓰기 실패 (${String(e)}) — 잠금 없이 진행한다`] };
  }
  activeRunLock = record;
  lastRunLockWriteMs = now;
  lines.push(formatRunLockAcquired(record, decision.action === 'resume'));
  return { refused: false, lines };
}

export function touchRunLock(nowMs: number): void {
  if (activeRunLock === null || nowMs - lastRunLockWriteMs < kRunLockWriteEveryMs) return;
  // An attempt counts whether or not the write lands. The sub-progress listener
  // calls this on every combo, so a document that refuses the write must be
  // asked again after the throttle, not again on the next combo.
  lastRunLockWriteMs = nowMs;
  try {
    const store = runLockStore();
    if (store === null) return;
    activeRunLock = withHeartbeat(activeRunLock, nowMs);
    store.setPluginData(kRunLockDataKey, JSON.stringify(activeRunLock));
  } catch {
    // A refused heartbeat is not worth failing the entry over — the TTL absorbs it.
    // It also must not escape: the listener runs inside `reportSubProgressAndYield`,
    // where a throw fails the entry being drawn.
  }
}

// Clears only OUR record. A session that stalled past the TTL may have been
// taken over; clearing then would unlock a run that is still going.
export function releaseRunLock(): void {
  const mine = activeRunLock;
  activeRunLock = null;
  if (mine === null) return;
  const store = runLockStore();
  if (store === null) return;
  try {
    const held = parseRunLock(store.getPluginData(kRunLockDataKey));
    if (held !== null && held.sessionId !== mine.sessionId) return;
    store.setPluginData(kRunLockDataKey, '');
  } catch {
    // The TTL absorbs a lock that could not be cleared.
  }
}

/**
 * What one entry's sub-progress ticks do — `reportSubProgressAndYield` calls it
 * on every combo of a builder that reports (Button, Chip), and `generateComponents`
 * installs it around that entry's `build()`.
 *
 * Three things ride the same tick, none of them with a timer of their own:
 *
 *  - the run-lock heartbeat. Without it the lock record is written only when an
 *    entry starts, so an entry that draws for twenty minutes shows another
 *    session a record twice the TTL old — `decideRunLock` takes the lock over
 *    while the holder is alive, and both sessions then draw into the same
 *    variants. `touchRunLock` throttles to `kRunLockWriteEveryMs`, so calling it
 *    per combo costs one comparison.
 *  - the growth footprint — `last-step.ts` says why it is written into the
 *    document rather than logged. Every `kGrowthFootprintEvery` combos, and on
 *    the last one so a run that completes the loop but dies in `finish` still
 *    leaves the loop's final numbers. One plugin-data write each; at 972 combos
 *    that is 39, billed to `yield`'s `post` part like the relay.
 *  - the progress relay to the UI.
 *
 * The heartbeat is first so a relay that throws cannot skip it.
 */
export function entryProgressListener(args: {
  entryName: string;
  index: number;
  total: number;
  buildStart: number;
  onProgress: ((p: GenerateProgress) => void) | undefined;
}): (current: number, subTotal: number) => void {
  const { entryName, index, total, buildStart, onProgress } = args;
  return (current, subTotal) => {
    touchRunLock(Date.now());
    if (current % kGrowthFootprintEvery === 0 || current === subTotal) {
      markGrowth(formatBuildDetail('↯', `${entryName} @${current}/${subTotal}`, peekBuildCost()));
    }
    onProgress?.({
      index,
      total,
      name: entryName,
      elapsedMs: Date.now() - buildStart,
      sub: { current, total: subTotal },
    });
  };
}

export async function generateComponents(
  onProgressRaw?: (p: GenerateProgress) => void,
  options?: GenerateOptions,
): Promise<string[]> {
  // Read before this run writes a footprint of its own — the next mark would
  // hide a replayed one (#4876, `formatLastStepRewind`).
  const rewind = formatLastStepRewind(readLastStep(), readLastDoneAt());
  const lock = acquireRunLock(options);
  const prelude = rewind === null ? lock.lines : [rewind, ...lock.lines];
  if (lock.refused) return prelude;
  try {
    return await generateComponentsLocked(onProgressRaw, options, prelude);
  } finally {
    releaseRunLock();
  }
}

async function generateComponentsLocked(
  onProgressRaw: ((p: GenerateProgress) => void) | undefined,
  options: GenerateOptions | undefined,
  prelude: readonly string[],
): Promise<string[]> {
  const log: string[] = [...prelude];
  const startedAt = Date.now();
  // #4830 — one `Map`, made fresh for this run and never module-level (a
  // stale answer from a node another run rebuilt would be wrong forever).
  // The post-build fingerprint/parity calls for an entry share it — the
  // loose-fingerprint, the fallback fingerprintNode, and both halves of
  // `parityReport`'s walk all cross the SAME reassembled nodes with nothing
  // in between that could rebind an instance's main component, so resolving
  // each instance once instead of once per walk is safe there. The
  // PRE-build fingerprint (just below) deliberately does NOT share this —
  // see its own comment.
  const mainComponentCache: MainComponentCache = new Map();
  // Every run starts by withholding sets until their binds are done
  // (`identity.ts`, deferred reassembly). A run that had to fall back stays
  // `eager` to its end and says so in its log; the next run tries again.
  setReassemblyMode('deferred');
  // Every progress message carries the log lines added since the one before
  // it (`GenerateProgress.logTail`). Wrapped once here rather than at the
  // call sites, so the cursor lives in one place and a site added later
  // cannot forget it.
  let streamedLines = 0;
  const onProgress = onProgressRaw
    ? (p: GenerateProgress): void => {
        const logTail = log.slice(streamedLines);
        streamedLines = log.length;
        onProgressRaw(logTail.length > 0 ? { ...p, logTail } : p);
      }
    : undefined;

  // Close whatever the user did last into its own undo step, before this run
  // changes anything.
  //
  // Kept now that the per-entry undo is gone, because `commitUndo` still runs
  // before each build and this closes the user's last action into its own step
  // rather than letting this run's first change join it.
  //
  // The undo it originally guarded took "Import Tokens" with it: one run's first
  // entry died on its first line, the pop reached past it into the import, and every
  // later entry then failed on a variable that no longer existed — 143 lines naming
  // 143 ids and no cause. From the outside that reads as "generate deletes my
  // variables", which is what it did.
  figma.commitUndo();

  const libraryWarning = checkCanonicalLibrary();
  if (libraryWarning) log.push(libraryWarning);

  // #4023 (B2) — 컴포넌트당 페이지. The legacy single 🧩 Components page is
  // located (never created — fresh documents go straight to per-component
  // pages) purely as a migration source to drain and remove. Every page is
  // loaded up front: documentAccess "dynamic-page" requires loadAsync
  // before touching `.children` (plugin-api.d.ts:10423), and the rename passes
  // below must see the whole document. (`indexDocumentComponents` loads pages
  // itself — it has to, since the read-only commands call it on their own.)
  const legacyPage = findComponentsPage();
  // #4038 (C5) — NFR-E line item 1 of 3. This loop is O(pages) and B2 turned
  // one page into N+1, so it is the phase most likely to have grown since the
  // 5-minute budget was set. Measured here rather than inferred from the
  // total, because the three line items move for different reasons and a
  // single number cannot say which one did.
  //
  // #4803 — a scoped run whose last index is still true loads only the pages
  // it draws on and the pages its `needs` live on (component-index-cache.ts
  // owns every check and every reason a hit is refused). Anything that needs
  // the whole document forces the full walk: a `force` run, the off-page
  // reassembly option (it sorts every page by its child count), and the two
  // migration sources the tail drains page by page — the legacy single page
  // and the old `{Section} / {Name}` scheme.
  const loadAsyncStart = Date.now();
  const allPages = figma.root.children;
  const { names: preScopedNames } = resolveScopedNames(options);
  const fullLoadReasons: string[] = [];
  if (options?.force) fullLoadReasons.push('강제 재생성');
  if (options?.reassembleOffPage === true) fullLoadReasons.push('reassembleOffPage');
  if (legacyPage) fullLoadReasons.push(`legacy "${kComponentsPageName}" 페이지`);
  if (allPages.some((p) => kOldSchemePage.test(p.name))) fullLoadReasons.push('옛 페이지 이름 체계');
  // `Icon` is read by the prelude's mode-pin check whatever the scope, and the
  // slot stand-in's predecessor by every slot default a builder declares
  // (`slotStandInDefault`) — left unloaded, it reads as absent and the old swap
  // defaults it identifies stay where they are without a word.
  const requiredNames =
    preScopedNames === null
      ? null
      : [...new Set([...preScopedNames, 'Icon', kSlotStandInPredecessor])].sort();
  const storedIndexCache = parseComponentIndexCache(
    figma.root.getPluginData(kComponentIndexCacheKey),
  );
  let indexCacheVerdict = cacheVerdict(storedIndexCache, {
    build: kSharedSourceHash,
    pages: pageSignature(allPages),
    required: requiredNames,
    fullLoadReasons,
  });
  let loadedPages: readonly PageNode[] = allPages;
  let cachedNodeIndex: Map<string, SceneNode> | null = null;
  let cacheResolveMs = 0;
  if (indexCacheVerdict.hit && storedIndexCache !== null && requiredNames !== null) {
    const wanted = pagesToLoad(
      storedIndexCache,
      requiredNames,
      requiredNames.map((name) => componentPageNameOf(name)),
    );
    const hitPages = allPages.filter((p) => wanted.has(p.name));
    for (const p of hitPages) await p.loadAsync();
    const resolveStart = Date.now();
    const resolved = await resolveCachedIndex<SceneNode>(
      storedIndexCache,
      requiredNames,
      async (id) => (await figma.getNodeByIdAsync(id)) as SceneNode | null,
      (node) => ({ type: node.type, name: node.name, page: directPageNameOf(node) }),
    );
    cacheResolveMs = Date.now() - resolveStart;
    if ('miss' in resolved) {
      indexCacheVerdict = { hit: false, reason: resolved.miss };
    } else {
      cachedNodeIndex = resolved.index;
      loadedPages = hitPages;
    }
  }
  if (cachedNodeIndex === null) {
    for (const p of allPages) await p.loadAsync();
    loadedPages = allPages;
  }
  const loadAsyncMs = Date.now() - loadAsyncStart - cacheResolveMs;
  // The pages this run actually loaded — NOT the document's page count. On a
  // cache hit the two differ, and the NFR-E line has to say which it measured.
  const pageCount = loadedPages.length;
  const loadedPageNames = new Set(loadedPages.map((p) => p.name));
  for (const line of formatCacheLine(
    cachedNodeIndex !== null
      ? { hit: true, loaded: loadedPages.length, total: allPages.length }
      : { hit: false, reason: indexCacheVerdict.hit ? '알 수 없음' : indexCacheVerdict.reason },
  )) {
    log.push(line);
  }

  // The gather pass and the shape-conflict report that stood here are gone with
  // the single-page topology they were written for. Both read `page.children`, and
  // there is no single page any more — every component has its own.
  //
  // Neither signal is lost. Gathering existed so a component sitting on a section
  // page from the last run was back where a by-name lookup would find it; the node
  // index below indexes EVERY page, which answers the same need without moving
  // anything. And a name carried by both a COMPONENT and a COMPONENT_SET (a shape
  // change from an earlier run) is a duplicate name, which that index reports by
  // name and page — with the same "nothing is deleted automatically" stance, since
  // a node a designer placed instances of must not vanish because a builder's
  // shape changed.

  // Brand filtering — `canonicalCollection` (variables.ts) folds every
  // "Semantic/Color · <Brand>" suffix away on BOTH the index and the query
  // side, so a document carrying more than one brand's Semantic/Color
  // collection makes `VarLookup`'s fold ambiguous: every unqualified
  // `sem()` call resolves to whichever brand happened to be inserted LAST,
  // and nothing in that class's public API can reach the shadowed one
  // (documented at length in variables.ts, right above `canonicalCollection`
  // — the fix it names is exactly this: filter to one brand BEFORE the
  // index is built, never try to disambiguate after). Generated components
  // draw from CoUI's own palette regardless of what other brands a file
  // happens to carry — a Unibook (or any other) Semantic/Color collection
  // is excluded here, before `vars`/`collById` are ever assembled.
  const kGeneratedBrand = 'CoUI';
  const isOtherBrandSemanticColor = (name: string): boolean => {
    if (canonicalCollection(name) !== 'Semantic') return false;
    const suffix = /\s*·\s*(.+)$/.exec(name);
    return suffix !== null && suffix[1].trim() !== kGeneratedBrand;
  };
  const allCollections = await figma.variables.getLocalVariableCollectionsAsync();
  const otherBrandCollectionIds = new Set(
    allCollections.filter((c) => isOtherBrandSemanticColor(c.name)).map((c) => c.id),
  );
  if (otherBrandCollectionIds.size > 0) {
    log.push(
      `↦ ${otherBrandCollectionIds.size} other-brand Semantic/Color collection(s) ` +
        `excluded — generating from "${kGeneratedBrand}" only.`,
    );
  }
  const collections = allCollections.filter((c) => !otherBrandCollectionIds.has(c.id));
  const collById = new Map<string, string>();
  for (const c of collections) collById.set(c.id, c.name);
  const vars = (await figma.variables.getLocalVariablesAsync()).filter(
    (v) => !otherBrandCollectionIds.has(v.variableCollectionId),
  );

  // Are the handles this document just handed us actually usable?
  //
  // `getLocalVariablesAsync` can return a variable whose id no longer resolves —
  // a collection deleted in this session, an undo that has not settled, a page
  // brought in from another file. Reading `.name` off one of those throws
  // `in get_name: The variable with id "VariableID:…" does not exist`, and so
  // does every `setBoundVariable` that is handed it.
  //
  // Checked HERE because the failure is otherwise unreadable. Every builder finds
  // its variable (the lookup succeeds — the key is in the index) and then dies
  // binding it, each with a different id, so the log is 143 lines that name 143
  // ids and no cause. One run looked exactly like that. The question "are these
  // handles alive" has one answer for the whole document, so it is asked once.
  //
  // Aborts rather than continuing: with dead handles nothing can bind, and a run
  // that fails every entry — leaving a half-drawn component on every page — has
  // already lost. Re-importing the tokens is what fixes it, and that is what
  // the message says.
  let deadHandles = 0;
  let firstDead = '';
  for (const v of vars) {
    try {
      void v.name;
    } catch (e) {
      deadHandles += 1;
      if (!firstDead) firstDead = String(e).slice(0, 160);
    }
  }
  if (deadHandles > 0) {
    log.push(
      `✗ ${deadHandles} of ${vars.length} variable handle(s) this document ` +
        `returned are dead — nothing can bind to them, so no component would ` +
        `build. First: ${firstDead}`,
    );
    log.push(
      '   Run "Import Tokens" on this document (build/tokens.figma.json) and ' +
        'generate again. A collection deleted in this session, or an undo that ' +
        'has not settled, leaves the variable index handing out ids that no ' +
        'longer resolve.',
    );
    return log;
  }
  if (vars.length === 0) {
    log.push(
      '✗ this document has no local variables — run "Import Tokens" first ' +
        '(build/tokens.figma.json). Every builder binds colour, spacing and ' +
        'type through them, so nothing would render.',
    );
    return log;
  }

  const lk = new VarLookup(vars, collById, new Map(collections.map((c) => [c.id, c])));
  resetRedrawFontCache();
  const fonts = await loadFonts(lk);
  if (fonts.monoNote) log.push(`⚠ ${fonts.monoNote}`);
  // Anything queued by an aborted run is not ours to restyle.
  resetPendingTextStyles();
  // #4040 (D2) — resolved once, not per entry: a hundred identical
  // `loadFontAsync` calls for a family that is missing each pay the same
  // failure. A fallback is reported and the run continues (unlike
  // `loadFonts` above, which aborts — Pretendard missing means nothing
  // renders, while a missing mono means code blocks render in Pretendard).
  const codeFont = await resolveCodeFontFamily(lk);
  if (codeFont.note) log.push(`⚠ ${codeFont.note}`);

  // Controlled renames/migrations run before anything below looks a node up
  // by name, so recycled nodes are found under their CURRENT name. Never
  // auto-detected — see src/renames.ts and src/variant-safety.ts for why.
  // Per page (B2): a renamed node now lives on its own component page, not
  // just the legacy one — the passes are name-keyed and idempotent, so
  // running them on every page finds each target exactly once.
  //
  // A scoped run migrates only the selected entries and their `needs`, even
  // when force or a cache miss loads every page. Loading is not permission to
  // rename or delete other components. The resolved scope is the same one the
  // entry loop uses below; a missing cached entry still forces a full load.
  for (const p of loadedPages) {
    for (const line of applyScopedMigrations(p, preScopedNames, {
      sets: SET_RENAMES,
      variants: VARIANT_RENAMES,
      structural: STRUCTURAL_MIGRATIONS,
    })) log.push(`↻ ${line}`);
  }

  // #4021 (B1) — document-wide node index for mint-by-name. Built AFTER the
  // rename/migration passes above (so nodes are indexed under their CURRENT
  // names) and covering every page (dynamic-page: each needs loadAsync
  // before .children — the per-page cost is an NFR-E line item). Duplicate
  // names get a warning and first-in-document-order wins — mint-by-name's
  // whole identity model assumes unique names, and G2 guards the REGISTRY
  // side of that assumption.
  // NFR-E line item 2 of 3 — the walk itself, timed around the shared helper
  // rather than around an inlined copy of it. The duplicate-name warning and the
  // per-page `loadAsync` live inside `indexDocumentComponents` now, because the
  // read-only commands need the same index and a second copy of this loop is how
  // they came to disagree with this one.
  //
  // On a cache hit the index is the cache's, already resolved and checked
  // node by node above; its cost (the per-id resolution) is counted here, as
  // the index it replaces would have been.
  const nodeIndexStart = Date.now();
  const nodeIndex = cachedNodeIndex ?? (await indexDocumentComponents((m) => log.push(m)));
  const nodeIndexMs = Date.now() - nodeIndexStart + cacheResolveMs;
  installNodeIndex(nodeIndex);

  // The glyph prelude — the one async step `makeIcon` cannot take itself.
  //
  // Glyphs live in `CoUI Icons — Lucide`, a separate library file, so reaching
  // one means `importComponentByKeyAsync`. Builders are synchronous
  // (`build: (page, lk) => BuildResult`), so the import has to happen here and
  // be handed over as an index — the same shape as `installNodeIndex` above,
  // and for the same reason.
  //
  // A failed import is collected, never thrown: the prelude runs before the
  // entry loop, so throwing here would take the whole run — every entry, not
  // just the ones that draw that glyph. Collected instead, the components that
  // draw it fail individually and name it, which is what a fix needs.
  const glyphStart = Date.now();
  const { index: glyphIndex, failures: glyphFailures } = await importGlyphs();
  installGlyphIndex(glyphIndex);
  // Anything a previous command left in the accumulator would be attributed to
  // this run's first entry. Commands share a module, so the reset is here
  // rather than trusted to whoever ran last.
  drainInexactIconSizes();
  drainSlotIconNotes();
  drainSlotIconWithoutCollection();
  dropPendingContentGlyphs();
  drainDirectGlyphs();
  drainContentWithoutCollection();
  drainUnpinnedInstanceBoxes();
  drainUnlinkedShadows();
  drainKeptSwapDefaults();
  drainRetypedProps();
  const glyphMs = Date.now() - glyphStart;

  // The mode-pin check (run below, after `prepareIconModes`), here rather than
  // in the `Icon` entry.
  //
  // Each `Size=N` variant pins the remote `Icon` collections to the mode named
  // for its own step, and that mode is what supplies `stroke-weight`. A
  // variant pinned to another step's mode draws the wrong weight while
  // everything else looks right — the size is correct, the binding is intact,
  // the variable resolves. A width census cannot see it and a screenshot
  // barely can, so this is the only place it can be caught.
  //
  // Reading a mode's NAME means resolving its collection, and the synchronous
  // variable API is off under `documentAccess: "dynamic-page"`. The builders
  // are synchronous, so this runs in the prelude, which is not.
  //
  // Warns rather than throws, for the same reason `checkCanonicalLibrary` does:
  // this is a fact about a file the plugin does not own, and refusing to build
  // the whole library over it helps nobody. The icons still land at the right
  // size; only the stroke is off.
  const iconSetForPins = findComponentByName(figma.currentPage, 'Icon');
  if (iconSetForPins && iconSetForPins.type === 'COMPONENT_SET') {
    // The size binding, checked beside the mode pin for the same reasons: the
    // set is the designer's, the canvas looks right either way, and the
    // prelude is the only place that can await a variable lookup. A root typed
    // as a bare number draws the right size but stops following the
    // `icon-size/N` token, so a token edit never reaches the set.
    const unboundSizes = await findUnboundIconSizes(iconSetForPins, (id) =>
      figma.variables.getVariableByIdAsync(id),
    );
    if (unboundSizes.length > 0) {
      log.push(
        `⚠ Icon: ${unboundSizes.length} variant size(s) are not bound to their ` +
          `\`icon-size/N\` variable — ${unboundSizes.join(', ')}. The icons draw at ` +
          'the right size, but a token edit will not reach the set.',
      );
    }
  }
  // The slot icons' stroke: the mode of the Lucide `Icon` collection a slot icon
  // is told to wear (`icon-nodes.ts`, "The Lucide `Icon` collection").
  //
  // Resolved here for the reason the glyph index is — finding the collection is
  // async and builders are not — and found through the `stroke-weight` binding of
  // a glyph vector, not by name: the file can hold the library's collection twice
  // (an older and a newer import), and only the one the glyph is bound to moves
  // the stroke. An unresolved collection is a warning and not a stop, like the
  // mode-pin check below: slot icons are then rescaled from their swap default
  // instead of wearing a mode, and the line says so.
  //
  // The whole step is `prepareIconModes`, called and not inlined: the harness
  // runs that same function, so the install this run depends on is not a copy
  // the drills play by hand.
  await prepareIconModes(
    iconSetForPins && iconSetForPins.type === 'COMPONENT_SET' ? iconSetForPins : null,
    (id) => figma.variables.getVariableByIdAsync(id),
    (id) => figma.variables.getVariableCollectionByIdAsync(id),
    log,
  );
  // The mode-pin check reads the stroke collection `prepareIconModes` just
  // resolved, so it runs after it: a pin is keyed by the library's oldest import
  // and holds a mode of the newest, and only the collection the glyphs are bound
  // to holds every step (#6279).
  if (iconSetForPins && iconSetForPins.type === 'COMPONENT_SET') {
    const held = heldIconModeIndex();
    const pins = await findMisPinnedIconModes(
      iconSetForPins,
      (id) => figma.variables.getVariableCollectionByIdAsync(id),
      held === null ? null : { collectionId: held.collectionId, collection: held.collection },
    );
    if (pins.misPinned.length > 0) {
      log.push(
        `⚠ Icon: ${pins.misPinned.length} variant(s) pin the wrong stroke-weight mode — ` +
          `${pins.misPinned.join(', ')}. Icons at those sizes draw another step's ` +
          'stroke weight; nothing downstream can detect it.',
      );
    }
    if (pins.unchecked.length > 0) {
      log.push(
        `⚠ Icon: ${pins.unchecked.length} stroke-weight mode pin(s) could not be checked — ` +
          `${pins.unchecked.join(', ')}. The collection the glyphs are bound to holds no ` +
          'such mode, so whether these sizes wear their own step cannot be told.',
      );
    }
  }
  // The colour a glyph takes from its slot (`icon-content.ts`): the two content
  // collections, resolved here for the reason the icon collection is. The whole
  // step is `prepareContentColors`, called and not inlined, so the harness runs
  // the step the plugin runs. A file Import has not reached has no such
  // collections: that is a warning, and every glyph is then painted directly.
  prepareContentColors(collections, lk, log);
  if (glyphFailures.length > 0) {
    log.push(
      `⚠ ${glyphFailures.length}/${Object.keys(ICON_KEYS).length} glyph(s) did not ` +
        `import — ${glyphFailures.join(', ')}. Either the \`CoUI Icons — Lucide\` ` +
        'library is not enabled in this file, or those keys rotated ' +
        '(`npm run gen:icon-keys`). Components drawing them will fail by name.',
    );
  } else {
    log.push(`Imported ${glyphIndex.size} glyph(s) in ${(glyphMs / 1000).toFixed(1)}s.`);
  }

  // #4023 (B2/T-13) — placement normalization. The target page for every
  // entry is DERIVED from schema v3's section fold (`❖ {Name}`, D-27 —
  // `componentPageNameOf` in data.ts is the single source verify reads
  // too), never listed: the initial single-page → per-page migration, a
  // scheme rename, a partial failure's re-run, and a hand-moved node all
  // reduce to the same "put it where it belongs" pass, and the audit trail
  // is the move/id log below, not a second list of the same information.
  // RegistryEntry.section is NOT consulted for PLACEMENT — the page name is
  // `❖ {Name}` and carries no section, so placement has no section to get wrong.
  // Ordering the page LIST is a separate question, answered below, and there the
  // declaration is read as a fallback.
  // Section blocks, in the order the sidebar shows them — `kPageSectionOrder`
  // and `sectionOfEntry` are module-level now (see above `listRegistryEntries`),
  // shared with the UI's component tree so the two agree on what section a
  // name is in.
  const targetPageNameOf = componentPageNameOf;
  const sectionByPageName = new Map<string, string>();
  const sectionOfComponentPage = new Map<string, string>();
  // A page's position within its section block — docs_site's curated order
  // (`docs_core/lib/shared/component_catalog.dart`'s flat
  // `kDocsComponentEntries`), not the alphabet. `docsOrderOf` returns `null`
  // for a component the catalog doesn't list (infra/internal), and that has
  // to stay distinct from "position 0": collapsing both to the same sentinel
  // would interleave undocumented pages into the curated block instead of
  // trailing them, which is the placement the ordering pass below relies on.
  const orderOfComponentPage = new Map<string, number | null>();
  for (const e of REGISTRY) {
    const entryPageName = componentPageNameOf(e.name);
    const entrySection = sectionOfEntry(e);
    if (entryPageName !== null && entrySection !== null) {
      sectionOfComponentPage.set(entryPageName, entrySection);
      sectionByPageName.set(entryPageName, entrySection);
    }
    if (entryPageName !== null) {
      const entrySlug = e.dataSlug ?? slugOfName(e.name);
      orderOfComponentPage.set(entryPageName, docsOrderOf(entrySlug));
    }
  }
  const sectionIndexOf = (name: string): number => {
    const section = sectionByPageName.get(componentPageNameOf(name)) ?? null;
    return section === null ? kPageSectionOrder.length : kPageSectionOrder.indexOf(section);
  };
  // Build order is the DEPENDENCY order — `topoSortRegistry`, which puts a child
  // before every parent that composes it.
  //
  // It had become section-then-name byte-order, which reads like a build order and
  // is not one. `Alert` composes an `Icon` instance and `A` sorts before `I`, so the
  // first entry of the run died on `makeIcon('info'): the Icon component is not on
  // the page yet` — the message naming the very mechanism that was no longer
  // running. 34 entries compose a child; every one of them failed, and `Skeleton`
  // alone took twelve down with it.
  //
  // Section and name still order the PAGE LIST — that is a different question,
  // answered by the sort further down. Merging the two answers is what lost this
  // one: `verify.ts` still says "generate.ts builds `topoSortRegistry(REGISTRY)`"
  // and it was reading a sort that ignored `needs` entirely.
  //
  // `sectionScope`/`entryScope` filter AFTER the sort, so a partial run keeps
  // dependency order within its scope. A child outside the chosen scope used
  // to be simply absent — the parent then drew against a child that was not
  // on the page. `closeOverNeeds` (#4038) closes the chosen set over its
  // `needs` edges so that cannot happen, which is what makes C5's "합집합이
  // 전체 실행과 같은 결과" true on a cold document rather than order-dependent.
  //
  // `entryScope` (#4526, the UI's component tree) wins outright when both are
  // given — it is the exact answer, and `sections` is the coarser fallback
  // for a caller that never adopted the tree (there is none left inside this
  // plugin, but the message schema still accepts it).
  // 어느 스코프로 불렸는지 — 아래 로그 한 줄을 고르는 데만 쓴다. 이름 집합
  // 자체는 `resolveScopedNames` 하나가 답한다(실행과 셀프테스트가 같은 해석을
  // 지나야 하므로).
  const byEntryNames = (options?.entryNames?.length ?? 0) > 0;
  const bySections = !byEntryNames && (options?.sections?.length ?? 0) > 0;
  const { names: scopedNames, added: pulledIn } = resolveScopedNames(options);
  const orderedEntries = topoSortRegistry(REGISTRY).filter(
    (e) => scopedNames === null || scopedNames.has(e.name),
  );
  if (pulledIn.length > 0) {
    log.push(
      `+ 의존 ${pulledIn.length}개를 범위에 넣었다 — 고른 것들이 ` +
        `needs 로 가리키는 자식이다 (${pulledIn.slice(0, 8).join(', ')}` +
        `${pulledIn.length > 8 ? ', …' : ''}). 이미 최신이면 내용 해시에서 skip 되고, ` +
        `낡았을 때만 그린다 — 자식이 페이지에 없는 채로 부모를 그리지 않기 위해서다.`,
    );
  }
  // Does the order this run will actually use satisfy `needs`?
  //
  // Asserted rather than assumed, because the assumption is what broke. The
  // harness drives builders through `topoSortRegistry` too — so it always saw a
  // correct order and could not see this at all, while the shipped run used a sort
  // that ignored `needs`. Two orders, one of them checked.
  //
  // Reported, not thrown: a violation means some entries will fail on a child that
  // is not there yet, which the per-entry catch already contains — the run keeps
  // going and each failure costs a half-built component until the next run blanks
  // it. What was missing is the line saying WHY, at the top, instead of 34 entries
  // each naming a different absent child.
  const positionOf = new Map(orderedEntries.map((e, i) => [e.name, i]));
  const outOfOrder: string[] = [];
  for (const e of orderedEntries) {
    for (const needed of e.needs ?? []) {
      const childAt = positionOf.get(needed);
      const parentAt = positionOf.get(e.name);
      // 자식이 범위 밖이면 그 자체가 위반이다. `closeOverNeeds` 뒤로는
      // 일어날 수 없지만, 조용히 넘기면 폐포가 깨진 날 이 검사가 그것을
      // 숨긴다 — 예전에 이 자리가 정확히 그렇게 눈이 멀어 있었다.
      if (childAt === undefined) {
        outOfOrder.push(`${e.name} needs ${needed} (범위 밖)`);
        continue;
      }
      if (parentAt !== undefined && childAt > parentAt) {
        outOfOrder.push(`${e.name} needs ${needed}`);
      }
    }
  }
  if (outOfOrder.length > 0) {
    log.push(
      `✗ build order violates ${outOfOrder.length} dependency/dependencies — ` +
        `every one of these will fail on a child that is not on the page yet: ` +
        `${outOfOrder.slice(0, 6).join(', ')}${outOfOrder.length > 6 ? ', …' : ''}`,
    );
  }
  if (options?.force) {
    log.push(
      `↻ 강제 재생성 — 내용 해시를 무시하고 범위 안의 ${orderedEntries.length}개 엔트리를 ` +
        `전부 다시 그린다(변경 없는 것 포함).`,
    );
  }
  if (byEntryNames) {
    log.push(
      `부분 실행: ${orderedEntries.length}개 컴포넌트 선택 — ${orderedEntries.length}/${REGISTRY.length} ` +
        `엔트리. 나머지 페이지는 이번 실행에서 불변.`,
    );
  } else if (bySections) {
    log.push(
      `부분 실행: ${(options?.sections ?? []).join(', ')} — ${orderedEntries.length}/${REGISTRY.length} ` +
        `엔트리. 나머지 섹션 페이지는 이번 실행에서 불변.`,
    );
  }

  let movedCount = 0;
  let idStableCount = 0;
  // Reused (found or created) target pages, keyed by page name.
  const targetPages = new Map<string, PageNode>();
  for (const p of figma.root.children) targetPages.set(p.name, p);
  const kPageMargin = 120;
  const placeOnPage = (targetPage: PageNode, node: BuildResult): void => {
    if (node.parent !== targetPage) {
      const idBefore = node.id;
      targetPage.appendChild(node);
      movedCount++;
      if (node.id === idBefore) idStableCount++;
      else log.push(`⚠ ${node.name}: node id CHANGED across the page move (${idBefore} → ${node.id})`);
      log.push(`↦ ${node.name} → "${targetPage.name}"`);
    }
    node.x = kPageMargin;
    node.y = kPageMargin;
  };
  // Every component page's canvas background — applied on every touch
  // (found or freshly created), same as the placement normalization a few
  // lines up: a page built before this existed self-heals to the current
  // colour on its next run rather than staying whatever colour it happened
  // to be created with.
  const kPageBackground: readonly Paint[] = [
    { type: 'SOLID', color: { r: 0xed / 255, g: 0xed / 255, b: 0xed / 255 } },
  ];
  // A page name with any leading `NN. ` ordering prefix removed.
  //
  // The section headers on the canvas are numbered (`01. 🎛️ CONTROL`) and
  // `sectionHeaderPageNameOf` returns the bare form (`🎛️ CONTROL`), so an
  // exact-name lookup misses every one of them and `ensurePage` mints a
  // second, empty header for all ten sections — on EVERY run, whatever the
  // scope, because placement normalization is not scoped. Measured: a run
  // that built one component (ValidatorHint) took the file from 188 pages
  // to 198.
  //
  // Same shape, same fix as `withoutOrderingPrefix` in `variables.ts`, which
  // strips the identical prefix from a collection a file still numbers. The number is the designer's ordering and is left
  // alone — this only stops it from hiding the page from us.
  const byBareName = new Map<string, PageNode>();
  // `figma.createPage()` appends, so every page this run makes starts at the
  // end of the file. The ordering pass reads this set to move exactly those
  // pages to their section — without it they read as "already placed".
  const createdPageIds = new Set<string>();
  for (const p of figma.root.children) {
    const bare = withoutPageOrderPrefix(p.name);
    // First occurrence wins, matching `mint`'s own rule for duplicate names.
    if (!byBareName.has(bare)) byBareName.set(bare, p);
  }
  const ensurePage = (pageName: string): PageNode => {
    // The reuse-or-create decision is `pageToReuse` (a pure function, tested
    // in `selftest-page-order`) — this only maps its answer back to a node.
    const reuse = pageToReuse([...targetPages.keys()], pageName);
    const found = reuse === null ? undefined : (targetPages.get(reuse) ?? byBareName.get(withoutPageOrderPrefix(reuse)));
    if (found) {
      found.backgrounds = kPageBackground;
      return found;
    }
    const created = figma.createPage();
    created.name = pageName;
    created.backgrounds = kPageBackground;
    targetPages.set(pageName, created);
    byBareName.set(withoutPageOrderPrefix(pageName), created);
    createdPageIds.add(created.id);
    return created;
  };

  // Per-entry hash recipe: `entryContentHashOf`, imported from ./content-hash —
  // the same function the read-only stale listing compares against.

  let built = 0;
  let skipped = 0;
  let failed = 0;
  // 손 편집 보존 집계 — 실행 끝의 한 줄이 이 둘을 읽는다.
  let snapshots = 0;
  let handEditSnapshots = 0;
  // 레이어에 연결되지 않은 속성의 정리(`unbound-props.ts`) — 이번 실행이 다시 그린
  // 세트의 합계. 꼬리 줄이 이 수를 0 과 대조한다.
  const unboundTally = emptyUnboundTally();
  let setsSettled = 0;
  // 글리프 색의 합계(`icon-content.ts`) — 이번 실행이 슬롯 프레임에 지정한 글리프 수.
  // 0 이면 콘텐츠 컬렉션이 없었거나 다시 그린 엔트리가 없다.
  const contentTally = { glyphs: 0, writes: 0, onGlyph: 0 };
  let unfingerprinted = 0;
  let otherBuildRedraws = 0;
  const paritySets: ParitySetReport[] = [];
  let parityPhaseMs = 0;
  // The same milliseconds by what they were spent on, printed beside the
  // total. The four are slow for unrelated reasons — reading a set to compare
  // it, copying one, reading the fresh build to stamp it, reading a designer
  // frame beside it — and the total cannot say which one a slow run spent.
  const paritySplit: ParitySplit = { preMs: 0, snapshotMs: 0, stampMs: 0, parityMs: 0 };
  // Candidate pages for `reassembleOffPage`, lightest first. Every page is
  // loaded by the prelude above, so `children.length` is readable here. Empty
  // when the option is off — and then no entry ever switches.
  const awayPages: PageNode[] =
    options?.reassembleOffPage === true
      ? figma.root.children.slice().sort((a, b) => a.children.length - b.children.length)
      : [];
  // Names of entries that failed THIS run, read by later entries whose `needs`
  // include one — a parent must not compose over a child the run just refused.
  const failedNames = new Set<string>();
  // There is no companion set for demoted entries. What a parent needs to know
  // is whether the child is in the document, and `nodeIndex` already answers
  // that for every reason a child can be absent — demoted, never built, or
  // skipped earlier in this run because its own child was. A second set would
  // answer it only for the entries this run happened to walk.
  const durations: { name: string; ms: number }[] = [];
  // #4038 (C5) — NFR-E line items 2 and 3. The per-entry total already
  // existed, but it folds the builder and the docs frames together, and
  // those are the two costs the budget renegotiation has to tell apart: a
  // 144-variant set and a Properties table both make an entry slow for
  // reasons that lead to different answers.
  let buildPhaseMs = 0;
  let docsPhaseMs = 0;
  // The single most expensive COMPONENT_SET build — Button (144) is the
  // arithmetic the seed spec argues from, so the measurement should name it
  // rather than leave it to be read off a top-5 list.
  let largestSet: { name: string; variants: number; ms: number } | null = null;
  // What the redraws kept of the old inner nodes, over the run (`redraw-keep.ts`).
  let keptInnerTotal = 0;
  let replacedInnerTotal = 0;
  const total = orderedEntries.length;
  let index = 0;

  // Text styles: the index and every face its styles draw in, loaded once
  // before the first entry and handed to the drains as an attacher
  // (`text-style-attach.ts`). If the read fails no attacher is installed —
  // every drain is then a no-op and each label keeps the node bindings
  // `makeLabel` wrote, the same outcome as a document with no styles.
  type TextStyleRun = { attacher: TextStyleAttacher; faces: FacePreload; preloadMs: number };
  let textStyles: TextStyleRun | null = null;
  const stylePreloadStart = Date.now();
  try {
    const styleIndex = await loadTextStyleIndex();
    const faces = await preloadTextStyleFaces(styleIndex.values());
    const attacher = createTextStyleAttacher(
      styleIndex,
      faces.loaded,
      (startedAt) => recordDetailSpan('attach', startedAt),
      { sans: sansTargetOf(lk), isMonoRole },
    );
    textStyles = { attacher, faces, preloadMs: Date.now() - stylePreloadStart };
    installTextStyleAttach((items) => attacher.attach(items));
  } catch (err) {
    log.push(
      `⚠ 텍스트 스타일을 읽지 못해 이번 실행은 스타일을 붙이지 않는다 — ` +
        `라벨은 노드 바인딩으로 남는다 (${String(err)})`,
    );
  }

  for (const e of orderedEntries) {
    index++;
    // Start every entry with empty accumulators, whatever the previous one did
    // on its way out. They are module-level and cleared only by the drain, so
    // any exit that misses it makes the NEXT entry's `⏱` line read high for a
    // reason nothing in it names — and a misattributed number still looks like
    // a number, which is why this is structural rather than a test. The
    // failure path drains and reports under its own name (see the catch); this
    // is the net under every other way out, including ones added later.
    drainResetNodeCost();
    // Same net for the disassembly closures: `finish()` releases its own, the
    // catch below drains on a throw, and this catches a builder that returned
    // without ever calling `finish()` — its set would otherwise stay in pieces
    // until some LATER entry failed and reassembled it under the wrong name.
    const leftover = restoreDisassembledSets();
    if (leftover.members > 0) {
      log.push(
        `↯ ${e.name} 직전: 앞 엔트리가 분해된 채 두고 나간 세트 ${leftover.sets}개에 ` +
          `멤버 ${leftover.members}개를 되돌렸다 — finish() 없이 끝난 빌더가 있다`,
      );
    }
    // A failed child is not a built child. `needs` orders entries so the child
    // runs first (asserted above), but nothing told a parent that the child it
    // ran after had REFUSED. ColorPicker and TimePicker both compose a
    // TextField; TextField failed S-a and was left untouched; both pickers
    // then reached into the stale set for an axis it does not carry and
    // failed mid-draw — two more ✗ lines, each naming the wrong culprit, and
    // two half-drawn pickers on the canvas. Skipping here leaves the parent
    // whole and says which child it is waiting on.
    const failedNeed = (e.needs ?? []).find((n) => failedNames.has(n));

    if (failedNeed !== undefined) {
      log.push(
        `⏭ ${targetPageNameOf(e.name)}: 건너뜀 — ${failedNeed} 이(가) 이 실행에서 실패해 ` +
          `그 위에 합성할 수 없다. ${failedNeed} 부터 고치면 다음 실행에서 함께 다시 그린다.`,
      );
      // Counted as failed, not skipped: "skipped" means "already current" in
      // this log, and this entry is not.
      failed++;
      failedNames.add(e.name);
      await reportProgress(onProgress, { index, total, name: e.name, elapsedMs: 0 });
      continue;
    }
    const entryStart = Date.now();
    touchRunLock(entryStart);
    const pageName = targetPageNameOf(e.name);
    // A page the designer DEMOTED — same name, `❖` dropped, indented to sit
    // under its section as a note rather than a component page — is an
    // opt-out, not a missing page. Building `❖ Name` next to it would put
    // the component back on the canvas the designer took it off, which is
    // what happened to twenty-one of them. Renaming the page back to
    // `❖ Name` is how it comes back. `isDemotedPageOf` is the one reading of
    // "demoted" — verify's placement grade reads the same function, so an
    // opt-out skipped here cannot be reported there as a missing page (#4026).
    const demoted = figma.root.children.find((p) => isDemotedPageOf(p.name, e.name));
    if (demoted) {
      log.push(
        `↷ ${e.name}: skipped — its page is demoted ("${demoted.name}"). ` +
          `Rename it back to "${pageName}" to build it again.`,
      );
      await reportProgress(onProgress, { index, total, name: e.name, elapsedMs: 0 });
      continue;
    }
    // Same shape as the `failedNeed` gate above, and separate from it because
    // the cause and the remedy are different: nothing broke, someone chose
    // this.
    //
    // The question asked is the one `instanceOf` will ask a moment later — is
    // the child component IN THE DOCUMENT — and not "did this run walk past a
    // demoted page", which is what a run-scoped set of demoted names answers.
    // The two differ exactly when the child is not in this run's entry list,
    // and that is the common case: a PARTIAL run (the designer selects a few
    // components) never reaches the child at all, so a run-scoped set is empty
    // and the gate is blind. `CardImage` went out that way — six components
    // selected, `Basic` not among them, and the failure it printed was
    // "instanceOf('Basic'): not in the document yet. Add `needs: ['Basic']`",
    // advice already followed, about a page the designer had demoted.
    //
    // The index answers this correctly on both paths because it is LIVE: it
    // starts as the document's own components and each entry registers itself
    // as it finishes, so a child built earlier in THIS run is present, a child
    // that exists from a previous run is present, and a child whose page is
    // demoted (those pages hold zero components — measured across all 23) is
    // absent. Skipped parents never register, so the cascade falls out of the
    // same check rather than needing its own bookkeeping.
    const missingNeed = (e.needs ?? []).find((n) => !nodeIndex.has(n));
    if (missingNeed !== undefined) {
      const demotedNeedPage = figma.root.children.find((p) => isDemotedPageOf(p.name, missingNeed));
      log.push(
        demotedNeedPage
          ? `↷ ${pageName}: skipped — ${missingNeed} 의 페이지가 강등되어 있어` +
              `("${demotedNeedPage.name}", 컴포넌트가 캔버스에 없다) 그 위에 합성할 수 ` +
              `없다. "❖ ${missingNeed}" 로 되돌리면 다음 실행에서 함께 그려진다.`
          : `↷ ${pageName}: skipped — ${missingNeed} 가 문서에 없어 그 위에 합성할 수 ` +
              `없다. ${missingNeed} 를 함께 선택해 실행하면 그려진다.`,
      );
      await reportProgress(onProgress, { index, total, name: e.name, elapsedMs: 0 });
      continue;
    }
    // A missing v3 section is REPORTED, not fatal. The section orders pages; the
    // page name is the component's own (D-27). Skipping over it kept thirteen
    // components off the canvas entirely. `sectionIndexOf` already places an
    // unsectioned page after the known blocks.
    const slug = e.dataSlug ?? slugOfName(e.name);
    // Two different absences, and they are not equally serious.
    //
    // No data at all means the fidelity check has nothing to compare the canvas
    // against, so that component's values are unverifiable. The reader enumerates
    // `{category}/{component}/` exactly one level deep, so a widget nested further
    // (`layout/table/resizable_table.dart`) has no entry of its own — unless the
    // REGISTRY says which slug states its chrome (`dataSlug`).
    //
    // A missing SECTION is not reported at all any more. It was, six times a run,
    // and every one of those six declares a section in the REGISTRY that this file
    // now reads — the warning described an absence the code could answer itself.
    // What remains worth saying is when NEITHER source answers, because then the
    // page really does sort after the known blocks.
    //
    // A fixture (`RegistryEntry.fixture`) has no record by definition, so
    // neither absence is news for it; its page sits under the section it
    // declares.
    if (!e.fixture && !hasEntry(slug)) {
      log.push(
        `⚠ ${e.name}: no entry in components.json — built from the builder's own ` +
          `literals, and 충실도 검증 cannot judge them. The reader enumerates ` +
          `{category}/{component}/ one level deep; declare dataSlug if another ` +
          `component's Core Style states this one's chrome.`,
      );
    } else if (!e.fixture && sectionOfEntry(e) === null) {
      log.push(
        `⚠ ${e.name}: no section from either source — built on "${pageName}", ` +
          `ordered after the known sections.`,
      );
    }
    const targetPage = ensurePage(pageName);
    // Every `figma.create*()` call in a builder (and in the shared helpers it
    // composes through — icon slots, labels, focus rings, popover panels…)
    // parents its new node under `figma.currentPage` BY DEFAULT, and nothing
    // guarantees the caller reparents it before the entry throws partway
    // through. `iconSet()`'s own comment already assumed this — "every
    // caller builds on its own page" — but nothing before this line ever
    // made it true, so the entries the user actually had open when they
    // clicked Generate were the ones that quietly caught everyone else's
    // half-built scratch frames (and, for a single-COMPONENT entry whose
    // `mint()` never explicitly reparents either, the WHOLE finished
    // component). `documentAccess: "dynamic-page"` makes `figma.currentPage`
    // read-only — `setCurrentPageAsync` is the one legal way to move it, and
    // it also `loadAsync()`s the target under the hood, so nothing here
    // needs its own load step first.
    await figma.setCurrentPageAsync(targetPage);
    // Re-import the glyph mains for this entry.
    //
    // The prelude's handles do not survive a long run. Under
    // `documentAccess: "dynamic-page"` a component that no node in the
    // document instances is not kept loaded while a run walks every page, and
    // by the time a late entry draws one, over an hour of other entries has
    // passed — two entries an hour apart failed on the same glyph in the same
    // run, which is what a shared handle going bad looks like rather than a
    // glyph being wrong.
    //
    // Unconditional rather than probed: whether an evicted handle reports
    // itself as `removed` is not something this codebase has established, and
    // a probe that cannot see the failure is worse than no probe — it reads as
    // a check that passed. `swapGlyph`'s recovery is the fallback if a handle
    // still goes bad mid-entry, and its message now says which of the two
    // things happened.
    //
    // The cost is not measured yet. The prelude's 35 imports take ~0.3s cold,
    // so the ceiling is ~1% of a full run, but a second import of the same key
    // may be far cheaper than the first. `⏱` reports it per entry, so the next
    // full run answers this rather than an argument here.
    const entryGlyphs = await importGlyphs();
    installGlyphIndex(entryGlyphs.index);
    // The icon-mode collection under the same rule: what the run holds across
    // an hour of entries is its id (`refreshIconModeCollection`). A refresh that
    // fails keeps the object the prelude took — it must not be what fails the run.
    try {
      await refreshIconModeCollection((id) => figma.variables.getVariableCollectionByIdAsync(id));
    } catch {
      // Held object kept.
    }
    // The content collections likewise — they are the same kind of held object.
    try {
      await refreshContentCollections((id) => figma.variables.getVariableCollectionByIdAsync(id));
    } catch {
      // Held objects kept.
    }
    const hash = entryContentHashOf(e);
    const indexed = nodeIndex.get(e.name);
    const existing =
      indexed && (indexed.type === 'COMPONENT' || indexed.type === 'COMPONENT_SET')
        ? (indexed as BuildResult)
        : undefined;

    // `force` skips the skip — see the option's own doc for the case it is
    // for. Checked here rather than by not stamping the hash, so a forced run
    // still records the hash it built and the NEXT run is cheap again.
    if (!options?.force && existing && existing.getPluginData(kHashDataKey) === hash) {
      const staleHolders = collectStaleWrapHolders(existing);
      // A run that died mid-loop leaves the set's members parked beside it
      // (#4831). The hash still matches, so a skip would leave the set as its
      // anchor for good and every composer of it would fail by name — the
      // rebuild is what puts the members back (`mountSet`'s recovery scan).
      const loose = existing.type === 'COMPONENT_SET' ? looseMembersOf(existing) : [];
      if (loose.length > 0) {
        log.push(
          `↻ ${pageName}: hash unchanged but ${loose.length} member(s) still loose beside the set ` +
            `(a run died mid-loop) — rebuilding to reassemble`,
        );
      } else if (staleHolders.length === 0) {
        skipped++;
        placeOnPage(targetPage, existing);
        const count =
          existing.type === 'COMPONENT_SET' ? `${existing.children.length} variants` : '1 component';
        log.push(`⏭ ${pageName}: ${count} (skipped — unchanged)`);
        const elapsedMs = Date.now() - entryStart;
        durations.push({ name: e.name, ms: elapsedMs });
        await reportProgress(onProgress, { index, total, name: e.name, elapsedMs });
        continue;
      } else {
        log.push(
          `↻ ${pageName}: hash unchanged but ${staleHolders.length} pin holder(s) still NONE/undersized — rebuilding`,
        );
      }
    }

    // 손 편집 보존 — 다시 그리기 직전, 지난 실행이 남긴 지문과 지금 캔버스를
    // 대조한다. 지문이 다르면 그 사이에 손이 닿은 것이고, 제자리 재활용은 그
    // 편집을 흔적 없이 지우므로 먼저 옆에 복제한다. 지문이 없으면(이 기능
    // 이전에 그려진 세트) 판단할 수 없어 옵션이 정한다 — 보수적 보존이냐
    // 침묵이냐. 어느 쪽이든 로그가 그 사실을 말한다.
    if (existing && options?.preserveHandEdits !== false) {
      const preStart = Date.now();
      // The copy is timed apart from the reads around it: it duplicates a whole
      // set, so it is the one piece of this block whose cost is the set's size.
      // Both kinds bill here — a redesign snapshot and a backup are the same
      // copy under two names, and a backup's removal of the one it replaces
      // happens inside the same call.
      let snapshotMs = 0;
      try {
        const stored = existing.getPluginData(kCanvasFingerprintKey);
        // 이유가 이름과 역할을 가른다 — 손 편집은 리디자인의 의도라 대조
        // 기준이 되고, 지문 없음은 어제의 생성본이라 백업으로만 남는다.
        let kind: SnapshotKind | null = null;
        if (stored) {
          // Uncached on purpose — this reads `existing` BEFORE this entry's
          // own build runs, and a build can rebind what an icon slot's swap
          // resolves to (`bindSwapProp`). Sharing `mainComponentCache` here
          // would let this pre-build answer for a reused node id outlive the
          // build that changes it, and hand it back stale to the post-build
          // reads below (1685/1950/1956) that intentionally do share it.
          const current = await fingerprintNode(existing);
          // Who drew it last decides what a moved fingerprint means (#4832):
          // this build → a hand; another build → a different serialisation
          // of the same canvas, or a different drawing, and no snapshot.
          const stamp = parseGenerationStamp(existing.getPluginData(kGenerationStampKey));
          const verdict = judgeOverwrite(stored, current, stamp, kSharedSourceHash);
          if (verdict === 'hand-edit') {
            kind = 'hand-edit';
          } else if (verdict === 'other-build' && stamp !== null) {
            otherBuildRedraws++;
            log.push(formatOtherBuildLine(pageName, stamp, kSharedSourceHash));
          }
        } else if (options?.snapshotUnfingerprinted) {
          kind = 'prior';
        } else {
          unfingerprinted++;
        }
        // 판단이 끝나는 즉시 지문을 비운다. 이 아래의 어떤 실패 경로 —
        // 빌더 throw, docs 렌더 실패, 지문 재계산 실패 — 든 세트는 반쯤
        // 지워진 채 남는데, 옛 지문이 남아 있으면 다음 실행이 그 잔해를
        // "손 편집" 으로 읽어 쓰레기 스냅샷을 뜬다. 지문은 성공적으로 다시
        // 그린 뒤에만(아래) 되살아난다.
        existing.setPluginData(kCanvasFingerprintKey, '');
        if (kind) {
          const snapshotStart = Date.now();
          try {
            const snap = await snapshotBeforeOverwrite(existing, targetPage, kind, undefined, mainComponentCache);
            snapshots++;
            const tail =
              (snap.replaced > 0 ? ` · 백업 ${snap.replaced}개 대체` : '') +
              `; 안쪽 자식 컴포넌트는 이 실행에서 이미 다시 그려졌을 수 있다 — ` +
              `보존되는 것은 이 세트 자신의 그림이다)`;
            if (kind === 'hand-edit') {
              handEditSnapshots++;
              log.push(
                `🛡 ${pageName}: 손 편집 감지 — 그 그림을 "${snap.node.name}" 으로 보존했고 ` +
                  `아래 ⇄ 의 기준이 된다 (${snap.members} 멤버${tail}`,
              );
            } else {
              log.push(
                `🛡 ${pageName}: 지문 없음 — 판단할 수 없어 덮어쓰기 전 상태를 ` +
                  `"${snap.node.name}" 으로 백업 (${snap.members} 멤버${tail}` +
                  ` — 어제의 생성본이라 대조 기준은 아니다`,
              );
            }
          } finally {
            snapshotMs = Date.now() - snapshotStart;
          }
        }
      } catch (err) {
        // 보존 실패로 빌드를 막지는 않는다 — 하지만 조용히 넘어가면 이
        // 기능이 있다고 믿은 사람이 편집을 잃는다. 크게 적는다.
        log.push(`⚠ ${pageName}: 손 편집 보존 실패 (${String(err)}) — 그대로 덮어씀`);
      }
      parityPhaseMs += addPreOverwrite(paritySplit, preStart, Date.now(), snapshotMs);
    }

    // 교체 기본값이 로컬 컴포넌트의 원격 사본(같은 key)을 가리키면 로컬로 되돌린다 — 빌더가
    // 그 기본값을 읽기 **전에** (`swap-default-repair.ts`). 손 편집 판정은 위에서 끝났으므로
    // 이 쓰기가 지문에 섞이지 않는다.
    if (existing) {
      try {
        const repairs = await repairRemoteSwapDefaults(
          existing as unknown as SwapOwnerLike,
          async (id) => (await figma.getNodeByIdAsync(id)) as unknown as SwapTargetLike | null,
          (target) =>
            localCounterpartByKey(
              target,
              (name) =>
                (nodeIndex.get(name) ?? null) as unknown as ReturnType<
                  Parameters<typeof localCounterpartByKey>[1]
                >,
            ),
        );
        for (const line of formatSwapDefaultRepairs(repairs)) log.push(line);
      } catch (err) {
        log.push(`⚠ ${pageName}: 교체 기본값 점검 실패 (${String(err)}) — 건너뛰고 그린다`);
      }
    }

    figma.commitUndo();
    // 앞 엔트리가 던지고 떠났다면 그 결선 기록이 남아 있다 — 이 엔트리의 판정에 섞이지 않게.
    resetUnboundTracking();
    let node: BuildResult;
    // The canvas fingerprint read off the loose members before reassembly —
    // null for an entry whose set was not pending at that point (a single
    // component, or a set a lookup completed early), which the stamp walks.
    let looseFingerprint: string | null = null;
    // Whether an icon in this entry was drawn off the stroke rule because of the
    // run's or the library's state (a missing collection or mode, a stroke weight
    // the collection does not state, glyphs not on SCALE, a mode Figma refused).
    // Read where the entry's notes are drained; decides below whether the entry
    // may be stamped current.
    let drawnOffStrokeRule = false;
    const buildStart = Date.now();
    // Only meaningful while onProgress exists — installed unconditionally
    // anyway (cheap) and simply never read otherwise, same as onProgress
    // itself being a no-op when absent.
    installSubProgressListener(
      entryProgressListener({ entryName: e.name, index, total, buildStart, onProgress }),
    );
    try {
      markStep(`${e.name}:build`);
      // Only around the builder: a reset anywhere else (docs frames, the
      // verify commands) has no reconcile after it and removes, as before.
      setRedrawKeepsNodes(options?.keepInnerNodes !== false);
      node = await e.build(targetPage, lk);
      setRedrawKeepsNodes(false);
      markStep(`${e.name}:built`);
      installSubProgressListener(null);
      // Tint layers take their host's settled size here. A container is painted
      // before its content exists, so a size measured during the build is one the
      // frame has already outgrown — see `flushTintLayers`.
      //
      // Billed to `tints`: this is inside `buildMs` but after every span the
      // builder opened has closed, so without one of its own it was remainder.
      markStep(`${e.name}:tints`);
      const tintsStart = Date.now();
      try {
        flushTintLayers();
      } finally {
        recordDetailSpan('tints', tintsStart);
      }
      // The glyphs' colour is pinned on their slot frames here, for the reason the
      // tints are sized here: a glyph is painted before it has a parent, and the
      // frame that carries its mode is only known once the builder is done. Before
      // the redrawn nodes are settled and the fingerprint is read, so both see the
      // tree with its modes (`icon-content.ts`).
      markStep(`${e.name}:content-modes`);
      const contentFlush = flushContentModes();
      contentTally.glyphs += contentFlush.glyphs;
      contentTally.writes += contentFlush.writes;
      contentTally.onGlyph += contentFlush.onGlyph;
      const directGlyphs = drainDirectGlyphs();
      for (const line of contentFlushLines(e.name, contentFlush, directGlyphs)) log.push(line);
      // The labels no yield reached: every label of a builder that never
      // yields, and anything a yielding one drew after its last drain. Inside
      // this try and before the hash and the fingerprint are stamped, so a
      // failed attach fails this entry and no stamp can precede a style
      // (`text-style-attach.ts`).
      markStep(`${e.name}:text-style`);
      await drainTextStyleAttach();
      // The old inner nodes the resets parked are settled against what the
      // builder drew — after the tints and text styles are on the new nodes, so
      // there is nothing left to land on them, and before the fingerprint and
      // the reassembly, so both read the tree that stays and the members are
      // still loose to write into (`redraw-keep.ts`).
      markStep(`${e.name}:keep`);
      await reconcileRedrawnMembers();
      // The members go back into their set here — after every bind and every
      // text style landed on them loose — and the recorded layout is applied.
      // Inside this try and before the hash and the fingerprint, so a set that
      // fails to reassemble fails this entry and no stamp precedes it
      // (`identity.ts`, deferred reassembly).
      // The canvas fingerprint, read while the members are still loose.
      // Walking 972 members inside their set cost 85s (#4038); the same walk
      // over loose members costs what the nodes cost. The value is the same —
      // nothing the collector reads depends on where a member sits — and the
      // harness holds the two equal. Billed to `stamp`, where the walk was.
      const pendingForEntry = pendingMountMembers().filter((p) => p.set === node);
      if (pendingForEntry.length === 1) {
        markStep(`${e.name}:fingerprint:loose`);
        const looseStart = Date.now();
        try {
          looseFingerprint = await fingerprintMembers(pendingForEntry[0].members, mainComponentCache);
        } catch (err) {
          // A failed walk is not a failed build. The stamp path below walks
          // the assembled set when this is null — the pre-#4802 route — and
          // its own catch keeps a built, unstamped set out of `failed`.
          // Letting this throw reach the entry's catch would restore and
          // count as failed a set that only lost its fingerprint.
          looseFingerprint = null;
          log.push(`⚠ ${pageName}: loose 지문 실패 (${String(err)}) — 재조립 뒤에 걷는다`);
        } finally {
          const looseMs = Date.now() - looseStart;
          paritySplit.stampMs += looseMs;
          parityPhaseMs += looseMs;
        }
      }
      markStep(`${e.name}:reassemble`);
      // Optionally with the current page elsewhere for the duration — see
      // `GenerateOptions.reassembleOffPage`. The switch is the caller's
      // because reassembly is synchronous and a page move is not. The page
      // is the lightest one that is not this entry's, chosen once per run:
      // `setCurrentPageAsync` loads its target, and a heavy page would bill
      // its load to every entry's remainder.
      const away = awayPages.find((p) => p !== targetPage) ?? null;
      if (away) await figma.setCurrentPageAsync(away);
      let reassembly: ReassemblyReport = { sets: 0, members: 0, fallbacks: [] };
      // The mark says "this entry's reassembly ran with the page elsewhere".
      // A completion that threw still ran there; one that found nothing to do —
      // the run went eager and `finish()` already reassembled on the target
      // page — did not, and must not claim to have.
      let reassembledAway = false;
      try {
        reassembly = completePendingMounts();
        reassembledAway = away !== null && reassembly.sets > 0;
      } catch (err) {
        reassembledAway = away !== null;
        throw err;
      } finally {
        markReassembledOffPage(reassembledAway);
        // If this switch back throws, the set is whole (the mount completed)
        // but the entry is marked failed and rebuilt next run — and the next
        // entry's own switch puts the page right. Acceptable for an experiment.
        if (away) await figma.setCurrentPageAsync(targetPage);
      }
      if (reassembly.fallbacks.length > 0) {
        log.push(
          `↯ ${e.name}: 스테이징한 속성 참조가 재조립 뒤 남지 않았다 ` +
            `(${reassembly.fallbacks.join(', ')}) — 세트 안에서 다시 썼고, 이 실행의 ` +
            `남은 엔트리는 옛 순서(즉시 재조립)로 간다`,
        );
      }
      // 세트가 다시 조립돼 모든 참조가 제자리에 놓인 지금이 유일한 때다 — 어떤 레이어도
      // 참조하지 않는 속성이 하나라도 남으면 Figma 게시 창이 이 세트를 조용히 뺀다
      // (#5323). 지운 것은 한 줄씩 로그에 남고, 지우지 못한 것은 ⚠ 로 남는다.
      // 설계자 소유 세트를 검증만 하는 엔트리(`Icon`)는 아무것도 결선하지 않았다 — 그 세트의
      // 속성은 설계자의 레이어가 쓰고 있으므로 이 판정의 대상이 아니다.
      if (!e.validateOnly) {
        const settled = settleUnboundProps(node);
        setsSettled += 1;
        addToUnboundTally(unboundTally, settled);
        for (const line of formatUnboundSettle(settled)) log.push(line);
      }
      // The pin skips this entry recorded, next to the component that owns them.
      // The list is module-level and was imported here and never read — it grew for
      // the whole session and printed nothing, which is the invisible state it was
      // written to end. Drained per entry so the names appear beside their owner
      // rather than in one anonymous heap at the end.
      if (pinsSkippedInsideInstance.length > 0) {
        log.push(
          `⚠ ${e.name}: absolute pin skipped inside an instance for ` +
            `${pinsSkippedInsideInstance.splice(0).join(', ')} — Figma refuses the ` +
            `write there, and the node it refuses over is not named in its message.`,
        );
      }
      // Same drain, for a paint whose stated strength the node did not keep after
      // the write and a second try (`assignPaints`), and for a layer whose bound
      // opacity variable did not read back as the strength it was bound for
      // (`bindLayerOpacity` — how a wrong percent scale on the opacity ladder
      // shows). The layer is drawn and bound at a strength other than the stated
      // one — nothing on the canvas says so.
      if (paintOpacityNotHeld.length > 0) {
        log.push(
          `⚠ ${e.name}: paint opacity not held after the write — ` +
            `${paintOpacityNotHeld.splice(0).join(', ')}. The layer renders at the strength ` +
            'Figma kept, not the one the design states.',
        );
      }
      // Same drain, same reason: an icon drawn at a size the `Size` axis has
      // no step for, and whose stroke differs across it, is rescaled, which is
      // visually exact but leaves the right panel reading the STEP's number.
      // Reported per entry so the gap is a line in the log rather than something
      // nobody notices for months.
      const inexactIcons = drainInexactIconSizes();
      if (inexactIcons.length > 0) {
        log.push(`⚠ ${e.name}: icon size off the \`Size\` axis — ${inexactIcons.join(', ')}.`);
      }
      // Same drain, for an icon that was held to the old fit or whose glyph did
      // not follow its box: it draws, at the wrong stroke or size, and nothing on
      // the canvas says why.
      const slotIconNotes = drainSlotIconNotes();
      if (slotIconNotes.length > 0) {
        log.push(`⚠ ${e.name}: icon off the stroke rule — ${slotIconNotes.join('; ')}.`);
      }
      // A run with no collection has nothing to note per entry (the prelude said
      // it once), so the flag is what carries it here.
      const withoutCollection = drainSlotIconWithoutCollection();
      // A glyph painted directly because the file has no content collection, or
      // whose pin Figma refused, is drawn off the content rule for the same reason:
      // the entry is left unstamped and the next run, once Import has been run,
      // draws it again.
      const contentOffRule =
        drainContentWithoutCollection() || contentFlush.refused.length > 0;
      drawnOffStrokeRule = slotIconNotes.length > 0 || withoutCollection || contentOffRule;
      // Same drain, same reason, for spacing: a padding or gap the `space`
      // ladder has no step for is written as a plain number, which renders
      // exactly and binds to nothing — so a token edit will not reach it. The
      // alternative was the throw this replaced, which cost the whole entry.
      const offScale = drainOffScaleSpaces();
      if (offScale.length > 0) {
        log.push(
          `⚠ ${e.name}: spacing off the \`space\` ladder, written unbound — ` +
            `${offScale.join(', ')}.`,
        );
      }
      // And for a corner: a radius the `radius` ladder has no step for is
      // written as a plain number, which renders exactly and binds to nothing.
      const offScaleRadii = drainOffScaleRadii();
      if (offScaleRadii.length > 0) {
        log.push(
          `⚠ ${e.name}: radius off the \`radius\` ladder, written unbound — ` +
            `${offScaleRadii.join(', ')}.`,
        );
      }
      // Same drain, for a box side no `size` step names (a pressed circle two
      // smaller than its rest size): drawn as the number, bound to nothing.
      const offScaleSizes = drainOffScaleSizes();
      if (offScaleSizes.length > 0) {
        log.push(
          `⚠ ${e.name}: size off the \`size\` ladder, written unbound — ${offScaleSizes.join(', ')}.`,
        );
      }
      // Same drain, for a composed instance held at a box it did not keep
      // (#4885). The frame around it takes the asked size either way, so the
      // mismatch is invisible at a glance — this line is where it surfaces.
      const unpinned = drainUnpinnedInstanceBoxes();
      if (unpinned.length > 0) {
        log.push(`⚠ ${e.name}: composed instance off its asked box — ${unpinned.join('; ')}.`);
      }
      // Same drain, for a shadow left as a direct value because the document has
      // no `shadow/<step>` effect style stating those layers. The picture is right
      // either way — what is lost is the link, so an edit to the style would not
      // reach this node, and nothing on the canvas shows that.
      const unlinkedShadows = drainUnlinkedShadows();
      if (unlinkedShadows.length > 0) {
        log.push(
          `⚠ ${e.name}: 그림자를 이펙트 스타일에 연결하지 못했다 — 같은 값의 \`shadow/<step>\` 스타일이 ` +
            `문서에 없어 직접 값으로 남았다: ${unlinkedShadows.join('; ')}.`,
        );
      }
      // Same drain, for a swap default the builder would have moved and did not
      // (`SwapDefault`): the property held something other than the default it
      // supersedes, so someone other than the builder put it there. Not a
      // warning — keeping it is the point — but listed, because nothing on the
      // canvas says this slot still defaults to something else.
      const kept = drainKeptSwapDefaults();
      if (kept.length > 0) {
        log.push(`ℹ ${e.name}: 교체 기본값 유지(빌더가 넣던 값이 아님) — ${await describeKeptSwapDefaults(kept)}.`);
      }
      // A definition `freePropName` removed so a slot's property could change
      // kind. Every removal is a line, the same rule the unbound cleanup keeps.
      for (const line of formatRetypedProps(drainRetypedProps())) log.push(line);
    } catch (err) {
      // Cleared here too — a builder that throws mid-way (Button, after some
      // combos) must not leave its listener installed to fire spuriously
      // under whichever entry succeeds next.
      installSubProgressListener(null);
      // Same for the labels it queued: they belong to a half-drawn entry that
      // rebuilds next run, and a later drain would style them under another
      // entry's span.
      resetPendingTextStyles();
      // And for the old nodes it parked: they stay hidden beside the half-drawn
      // new ones, and the next run parks both and pairs the old ones first.
      setRedrawKeepsNodes(false);
      abandonRedrawParking();
      // No `triggerUndo()` here.
      //
      // It pops ONE undo step, and nothing guarantees that step is this entry's. A
      // builder that throws on its first line changed nothing, so there is no step
      // of its own to pop and the undo reaches back into what came before — the
      // page this entry just ensured, the component the PREVIOUS entry finished, or
      // (before a boundary was added at the top of this function) the token import.
      //
      // It really did all three. One run's log was 143 entries each naming a
      // different variable that "does not exist", because the first failure's undo
      // took the import with it. A later one reported `in get_children: The node
      // with id … does not exist` — a component built successfully minutes earlier,
      // undone by a later entry's failure and still sitting in the live index.
      //
      // What the undo was for is already covered: nothing is deleted before a build
      // (mint-by-name), and a node left half-populated by a throwing builder is
      // `resetNode`-d to blank the next time its name is minted. So the cost of
      // dropping the undo is a half-drawn node on one page until the next run, and
      // the cost of keeping it was other components disappearing.
      log.push(`✗ ${pageName}: ${String(err)} — kept, rebuilt on the next run`);
      // The entry may have drawn icons before it threw. Draining here keeps
      // those records with the entry that produced them instead of letting
      // them surface under whichever entry succeeds next.
      const inexactBeforeFailure = drainInexactIconSizes();
      if (inexactBeforeFailure.length > 0) {
        log.push(
          `⚠ ${e.name}: icon size off the \`Size\` axis — ${inexactBeforeFailure.join(', ')}.`,
        );
      }
      const slotIconNotesBeforeFailure = drainSlotIconNotes();
      if (slotIconNotesBeforeFailure.length > 0) {
        log.push(
          `⚠ ${e.name}: icon off the stroke rule — ${slotIconNotesBeforeFailure.join('; ')}.`,
        );
      }
      // Cleared with the notes: a flag left by a throwing entry would unstamp
      // whichever entry succeeds next.
      drainSlotIconWithoutCollection();
      // The same for the glyphs a throwing build painted and never flushed.
      dropPendingContentGlyphs();
      drainDirectGlyphs();
      drainContentWithoutCollection();
      // Drained on this path too, for the reason the icon drain above gives:
      // otherwise a throwing entry's records surface under whichever entry
      // succeeds next.
      const offScaleBeforeFailure = drainOffScaleSpaces();
      if (offScaleBeforeFailure.length > 0) {
        log.push(
          `⚠ ${e.name}: spacing off the \`space\` ladder, written unbound — ` +
            `${offScaleBeforeFailure.join(', ')}.`,
        );
      }
      const offScaleRadiiBeforeFailure = drainOffScaleRadii();
      if (offScaleRadiiBeforeFailure.length > 0) {
        log.push(
          `⚠ ${e.name}: radius off the \`radius\` ladder, written unbound — ` +
            `${offScaleRadiiBeforeFailure.join(', ')}.`,
        );
      }
      const offScaleSizesBeforeFailure = drainOffScaleSizes();
      if (offScaleSizesBeforeFailure.length > 0) {
        log.push(
          `⚠ ${e.name}: size off the \`size\` ladder, written unbound — ` +
            `${offScaleSizesBeforeFailure.join(', ')}.`,
        );
      }
      const unpinnedBeforeFailure = drainUnpinnedInstanceBoxes();
      if (unpinnedBeforeFailure.length > 0) {
        log.push(
          `⚠ ${e.name}: composed instance off its asked box — ` +
            `${unpinnedBeforeFailure.join('; ')}.`,
        );
      }
      const unlinkedShadowsBeforeFailure = drainUnlinkedShadows();
      if (unlinkedShadowsBeforeFailure.length > 0) {
        log.push(
          `⚠ ${e.name}: 그림자를 이펙트 스타일에 연결하지 못했다 — 같은 값의 \`shadow/<step>\` 스타일이 ` +
            `문서에 없어 직접 값으로 남았다: ${unlinkedShadowsBeforeFailure.join('; ')}.`,
        );
      }
      const keptBeforeFailure = drainKeptSwapDefaults();
      if (keptBeforeFailure.length > 0) {
        log.push(
          `ℹ ${e.name}: 교체 기본값 유지(빌더가 넣던 값이 아님) — ` +
            `${await describeKeptSwapDefaults(keptBeforeFailure)}.`,
        );
      }
      for (const line of formatRetypedProps(drainRetypedProps())) log.push(line);
      failed++;
      failedNames.add(e.name);
      // Drain before leaving, or this entry's reset cost is billed to the NEXT
      // entry that builds. The accumulators are module-level and only cleared
      // by the drain below, which this `continue` skips — so a builder that
      // threw after resetting some members made the next `⏱` line read high
      // for a reason nothing in it named. `Button` is both the entry most
      // likely to throw partway and the entry whose line gets read.
      const abandoned = drainResetNodeCost();
      // The spans ride along. A builder that dies partway has still spent
      // whatever it spent, and on a slow entry that partial breakdown is the
      // most informative thing the failure produces — without it the drain
      // happens anyway (it must, or the cost lands on the next entry) and the
      // numbers are simply thrown away. A `finish()` that threw is billed to
      // `finish`, which only the detail line shows.
      for (const line of formatFailureTiming(e.name, Date.now() - buildStart, abandoned)) {
        log.push(line);
      }
      // A large set is emptied for the duration of its build loop, so a
      // builder that throws in that window leaves it holding one member with
      // the rest on the page. The next run reclaims them by name, but until
      // then the component reads as a single variant where a grid should be —
      // and nothing in the failure says so. Put it back now, on the same run
      // that broke it.
      const reassembled = restoreDisassembledSets();
      if (reassembled.members > 0) {
        log.push(
          `↯ ${e.name}: 분해된 세트 ${reassembled.sets}개에 멤버 ` +
            `${reassembled.members}개를 되돌렸다 — 실패해도 캔버스는 온전하다`,
        );
      }
      await reportProgress(onProgress, {
        index,
        total,
        name: e.name,
        elapsedMs: Date.now() - entryStart,
      });
      continue;
    }
    const buildMs = Date.now() - buildStart;
    buildPhaseMs += buildMs;
    // Recycle-path breakdown, only where it matters. A rebuild over an
    // existing full document has run ~100x slower than the same build into a
    // near-empty one, and the entry total alone cannot say whether the time
    // went into EMPTYING the old content (resetNode) or REPOPULATING it —
    // two different fixes. Logged only for entries slow enough (10s+) that
    // someone will actually be asking, so a fast run's log stays readable.
    const resetCost = drainResetNodeCost();
    if (buildMs > 10_000) {
      for (const line of formatBuildTiming(e.name, buildMs, resetCost)) log.push(line);
    } else if (resetCost.keep !== undefined && resetCost.keep.replaced > 0) {
      // A replaced old node is an override some copy may have lost — said for
      // every entry, not only the slow ones whose ⏱ line carries it.
      log.push(`↺ ${e.name}: 안쪽 노드${formatKeepCost(resetCost.keep)}`);
    }
    if (resetCost.keep !== undefined) {
      keptInnerTotal += resetCost.keep.kept;
      replacedInnerTotal += resetCost.keep.replaced;
    }
    if (node.type === 'COMPONENT_SET') {
      const variants = node.children.length;
      if (largestSet === null || variants > largestSet.variants) {
        largestSet = { name: e.name, variants, ms: buildMs };
      }
    }
    // An entry drawn off the stroke rule is left unstamped (`hashStampFor`): the
    // hash cannot see the library or collection that made it so, and a stamped
    // entry would be skipped after the fault is mended.
    node.setPluginData(kHashDataKey, hashStampFor(hash, drawnOffStrokeRule));
    if (drawnOffStrokeRule) {
      log.push(
        `⚠ ${pageName}: icon drawn off the stroke rule — entry left unstamped, ` +
          'next run rebuilds it (once the library glyphs are on SCALE and the Icon collection ' +
          'has the modes and states the smallest rungs alike)',
      );
    }
    // Next to the hash: who drew it, with which build (#4832). The hash says
    // whether the recipe moved; this says whose recipe.
    node.setPluginData(
      kGenerationStampKey,
      JSON.stringify(makeGenerationStamp(currentRunSession(), kSharedSourceHash, kBuildRef, Date.now())),
    );
    built++;
    // Register it so the entries that compose it can find it — the index is LIVE,
    // not a snapshot of what the last run left.
    //
    // It was built once, before the loop, from what was already on the pages. On a
    // document that starts empty that index is empty, so every child lookup fell
    // through to the caller's own page and found nothing: `Icon` finished
    // successfully and `Button` died on `makeIcon('check')` two lines later. And a
    // page is deleted before every run here, so every run is that run.
    nodeIndex.set(e.name, node);
    placeOnPage(targetPage, node);
    // #4041 (D3) — inspector surfaces, from schema v3 `docs` (한국어 md
    // 우선순위는 export 시점에 이미 해소). (Re)stamped on every rebuild;
    // a docs-only edit re-enters here via the per-entry hash (B3), so a
    // skipped entry's stamp is by definition current.
    // A fixture describes itself — it has no docs page to read one from.
    const docs = e.fixture
      ? { description: e.fixture.description, url: null }
      : docsOf(slugOfName(e.name));
    // Approved canvas-only parts that have no code API say so on the
    // component, so a designer does not look for them in the code.
    const description = docs.description ?? '';
    const canvasOnly = kCanvasOnlyApiNotes[e.name];
    node.description = canvasOnly && !description.includes(canvasOnly)
      ? `${description}\n\n${canvasOnly}`.trim()
      : description;
    node.documentationLinks = docs.url ? [{ uri: docs.url }] : [];
    // #4039 (D1) / #4040 (D2) — the page's other two frames, rendered under
    // the node `placeOnPage` just positioned. BUILT PATH ONLY: a skipped
    // entry above `continue`s before reaching here, so its frames are never
    // touched — that is what keeps NFR-A's second run all-skip and what
    // separates these from the "매회 재생성" `Section /` headings B2 swept.
    let docsFrames: { rowCount: number; blockCount: number };
    const docsStart = Date.now();
    markStep(`${e.name}:docs`);
    try {
      // A fixture has no contract to tabulate and no example to print: its
      // Properties frame would caption a `contracts/` path that does not exist.
      docsFrames = e.fixture
        ? { rowCount: 0, blockCount: 0 }
        : renderDocsFrames(
            targetPage,
            lk,
            e.name,
            { x: node.x, y: node.y, height: node.height },
            codeFont,
          );
    } catch (err) {
      // The component itself is already built — rolling that back over a
      // failed decoration would be the worse trade. But the hash was
      // stamped a few lines up, and leaving it would make this entry claim
      // to be current while its page is half-rendered: every later run
      // would skip straight past the frames that never appeared. Clearing
      // it costs this one entry a rebuild per run until the cause is fixed,
      // which is exactly what an incomplete page should cost.
      node.setPluginData(kHashDataKey, '');
      log.push(
        `⚠ ${pageName}: docs frames not rendered (${String(err)}) — entry left unstamped, ` +
          `next run rebuilds it`,
      );
      docsFrames = { rowCount: 0, blockCount: 0 };
    }
    // Counted on the throwing path too — the time was spent either way, and
    // a phase total that silently drops failures understates the budget.
    docsPhaseMs += Date.now() - docsStart;
    const count =
      node.type === 'COMPONENT_SET' ? `${node.children.length} variants` : '1 component';
    log.push(
      `✓ ${pageName}: ${count}, docs ${docsFrames.rowCount} rows / ${docsFrames.blockCount} blocks`,
    );
    // 지문은 플러그인이 그린 직후의 캔버스에서만 찍는다. 건너뛴 세트에
    // 찍으면 손 편집된 상태가 기준이 되어 다음 덮어쓰기가 그 편집을 "원래
    // 그대로" 로 읽는다 — 보존이 정확히 그 순간에 침묵한다.
    markStep(`${e.name}:stamp`);
    const parityStart = Date.now();
    // Where the stamp ended, and where the comparison began after the
    // `:parity` mark between them — billed to neither, see `markStep`. Null
    // when the stamp threw, so the whole block bills to `stamp`, the part that
    // was running.
    let stampedAt: number | null = null;
    let parityFrom: number | null = null;
    try {
      // Already read loose, before reassembly, for a set that was pending;
      // walked here only for what was not — a single component, or a set
      // completed early by a lookup.
      node.setPluginData(kCanvasFingerprintKey, looseFingerprint ?? (await fingerprintNode(node, mainComponentCache)));
      stampedAt = Date.now();
      markStep(`${e.name}:parity`);
      parityFrom = Date.now();
      // 디자이너 손 사본이 옆에 있으면 값 대조 — 이 줄이 0 차이인 것이
      // "캔버스대로 반영됐다" 의 기계적 정의다. 없으면 그렇다고 한 줄.
      const parity = await parityReport(node, targetPage, mainComponentCache);
      for (const line of parity.lines) log.push(line);
      paritySets.push(parity.report);
    } catch (err) {
      log.push(`⚠ ${pageName}: 지문/대조 실패 (${String(err)})`);
    }
    parityPhaseMs += addStampAndParity(paritySplit, parityStart, stampedAt, parityFrom, Date.now());
    const elapsedMs = Date.now() - entryStart;
    durations.push({ name: e.name, ms: elapsedMs });
    await reportProgress(onProgress, { index, total, name: e.name, elapsedMs });
  }
  installTextStyleAttach(null);
  if (handEditSnapshots > 0) {
    log.push(
      `🛡 손 편집 보존 ${handEditSnapshots}건 — 각 세트 오른쪽의 "(리디자인 · 시각)" ` +
        `프레임이고, 그것이 ⇄ 의 기준이다`,
    );
  }
  if (snapshots - handEditSnapshots > 0) {
    log.push(
      `🛡 백업 ${snapshots - handEditSnapshots}건 — 각 세트 오른쪽의 "(이전 · 시각)" ` +
        `프레임. 지문이 없어 판단할 수 없었을 뿐이라 대조하지 않는다`,
    );
  }
  if (otherBuildRedraws > 0) {
    log.push(
      `↔ 다른 빌드가 그린 세트 ${otherBuildRedraws}건 — 지문은 달랐지만 손 편집이 아니라 다른 빌드의 생성이라 ` +
        `스냅샷 없이 다시 그렸다(↔ 줄 참조). 한 파일은 한 빌드로 — 그 빌드와 커밋을 맞추면 이 줄이 사라진다`,
    );
  }
  for (const line of formatUnboundTally(unboundTally, setsSettled)) log.push(line);
  if (contentTally.glyphs > 0) {
    log.push(
      `Icon: 글리프 ${contentTally.glyphs}개의 색을 슬롯 프레임의 콘텐츠 모드로 지정했다 ` +
        `(모드 쓰기 ${contentTally.writes}회${contentTally.onGlyph > 0 ? `, 글리프 인스턴스에 직접 ${contentTally.onGlyph}개` : ''}).`,
    );
  }
  if (paritySets.length > 0) {
    log.push(formatParitySummary(paritySets));
    options?.onDesignerParity?.(paritySets);
  }
  if (unfingerprinted > 0) {
    log.push(
      `ⓘ 지문이 없어 손 편집 여부를 알 수 없었던 세트 ${unfingerprinted}개 — 이 실행이 ` +
        `지문을 남겼으므로 다음 실행부터는 보존이 동작한다. 그 세트들에 손 편집이 ` +
        `있었다면 이번 실행이 지웠다("지문 없는 세트도 보존" 을 켜면 첫 실행도 보존).`,
    );
  }

  // ─── Source-page disposal (R-1) + page ordering ────────────────────────
  if (movedCount > 0) {
    log.push(`↦ moved ${movedCount} node(s) — id stable ${idStableCount}/${movedCount}`);
  }
  if (legacyPage) {
    if (legacyPage.children.length === 0) {
      // Removing the current page is not allowed — step off it first.
      if (figma.currentPage === legacyPage) {
        const firstTarget = targetPages.get(
          [...targetPages.keys()].filter((n) => n !== legacyPage.name).sort()[0] ?? '',
        );
        if (firstTarget) await figma.setCurrentPageAsync(firstTarget);
      }
      if (figma.currentPage !== legacyPage) {
        legacyPage.remove();
        log.push(`🗑 removed empty legacy "${kComponentsPageName}" page`);
      }
    } else {
      log.push(
        `⚠ legacy "${kComponentsPageName}" page kept — ${legacyPage.children.length} ` +
          `non-registry node(s) remain (never deleted silently): ` +
          legacyPage.children
            .slice(0, 5)
            .map((n) => n.name)
            .join(', ') + (legacyPage.children.length > 5 ? ', …' : ''),
      );
    }
  }
  // File page list: the plugin's own pages — component pages and section
  // headers — read in plan order (section order, then docs_site's curated
  // order); every other page keeps its order among the others.
  // This ordering claim is file-scope only — the library Assets panel sorts
  // on its own (CH-005).
  //
  // #4100 (D-26/D-27) — each section block is preceded by a
  // `🖥️ DISPLAY`-style header page so the 100+ page sidebar reads in
  // blocks (the reference-library organization the user pointed at).
  // Headers are find-or-create by name (mint-by-name, like every page
  // here), hold no components (node index / mint / G1 / G2 never see
  // them), and are only ensured for sections that actually have a
  // component page in this file — a section-scoped partial run on a fresh
  // file doesn't plant headers for sections it never built.
  const pagesBySection = new Map<string, PageNode[]>();
  for (const p of figma.root.children) {
    const section = sectionOfComponentPage.get(p.name);
    if (section === undefined) continue;
    const bucket = pagesBySection.get(section) ?? [];
    bucket.push(p);
    pagesBySection.set(section, bucket);
  }
  // Within a section block: docs_site's curated order first, alphabetical
  // only as the fallback for what the catalog doesn't rank (`compareByDocsOrder`
  // — a pure function so the ranking itself is testable without a `PageNode`).
  const pageOrderCompare = (a: PageNode, b: PageNode): number =>
    compareByDocsOrder(
      orderOfComponentPage.get(a.name) ?? null,
      orderOfComponentPage.get(b.name) ?? null,
      a.name,
      b.name,
    );
  const sortedBySection = new Map<string, readonly string[]>();
  for (const [section, pages] of pagesBySection) {
    sortedBySection.set(
      section,
      [...pages].sort(pageOrderCompare).map((p) => p.name),
    );
  }
  const plan = plannedPageOrder(kPageSectionOrder, sortedBySection);
  // `reorderPages` picks how much may move, never whether new pages are
  // placed: a page this run created belongs in its section either way, and
  // leaving it where `createPage` put it is how new pages piled up at the end
  // of the file. `all` puts every page the plugin owns in plan order; `created`
  // moves only this run's pages.
  const scope: PageOrderScope = (options?.reorderPages ?? true) ? 'all' : 'created';
  // A section that has pages but no header gets one in either scope. Without
  // it a run that leaves the file alone still cannot place a new section's
  // first page (there is no block to put it in), and verify — which runs with
  // `created` — would report the missing header on every run with no way to
  // clear it. Only a header no page answers to is created: an existing one —
  // the canvas numbers them — is not passed through `ensurePage`, which would
  // also repaint its background.
  for (const name of plan) {
    if (name.startsWith(kComponentPageNamePrefix)) continue;
    if (pageToReuse(figma.root.children.map((p) => p.name), name) === null) ensurePage(name);
  }
  const decision = pageOrderMoves(
    figma.root.children.map((p) => ({ id: p.id, name: p.name })),
    plan,
    { scope, created: createdPageIds },
  );
  const pageById = new Map(figma.root.children.map((p) => [p.id, p]));
  for (const move of decision.moves) {
    const page = pageById.get(move.id);
    const anchor = pageById.get(move.anchorId);
    if (!page || !anchor) continue;
    // Off the end first, then into place: the moved page is then always after
    // the target index, so the index means the same thing whether Figma reads
    // it before or after taking the page out — the same-parent case is not
    // documented.
    try {
      await withPageFontsLoaded(() => {
        figma.root.appendChild(page);
        const at = figma.root.children.indexOf(anchor) + (move.side === 'after' ? 1 : 0);
        if (figma.root.children.indexOf(page) !== at) figma.root.insertChild(at, page);
      });
    } catch (e) {
      // Ordering is bookkeeping for the sidebar. A page that cannot be moved
      // is said out loud, and the run goes on to finish what it built.
      log.push(`⚠ 페이지 "${page.name}" 를 옮기지 못했다 — ${(e as Error)?.message ?? e}`);
      continue;
    }
    const anchorLabel = `"${anchor.name}" ${move.side === 'after' ? '뒤' : '앞'}`;
    const why = move.reason === 'header' ? '헤더' : move.reason === 'new' ? '새 페이지' : '순서';
    log.push(`  ↕ "${page.name}" → ${anchorLabel} (${why})`);
  }
  const placedOrder = figma.root.children.map((p) => p.id);
  if (placedOrder.join('\n') !== decision.order.join('\n')) {
    log.push(
      `⚠ 페이지 배치가 계산과 다르다 — 이동 ${decision.moves.length}건을 적용했지만 ` +
        `결과 순서가 예측과 어긋난다. 페이지 순서 정리를 켜고 한 번 더 돌리면 다시 맞춘다.`,
    );
  }
  if (scope === 'all') {
    log.push(
      decision.moves.length === 0
        ? `↕ 페이지 순서: 플러그인 페이지 ${decision.kept}개가 이미 계획 순서다 — 옮긴 페이지 없음.`
        : `↕ 페이지 순서: 플러그인 페이지 ${decision.moves.length}개를 계획 자리로 옮겼다 — ` +
            `${decision.kept}개는 제자리, 디바이더·메모·미리보기 페이지는 건드리지 않음.`,
    );
  } else if (decision.moves.length > 0) {
    log.push(
      `↕ 새로 만든 페이지 ${decision.moves.length}개를 제 섹션 자리에 놓았다 — ` +
        `기존 배치는 그대로(페이지 순서 정리 해제).`,
    );
  }
  if (decision.unresolved.length > 0) {
    log.push(`ⓘ 계획에 있는데 페이지가 없는 항목 ${decision.unresolved.length}개: ${decision.unresolved.join(', ')}`);
  }
  // The old-scheme cleanup below steps onto one of these before removing the
  // page it is standing on.
  const orderedPages: PageNode[] = resolvePlannedPages(
    figma.root.children.map((p) => ({ id: p.id, name: p.name })),
    plan,
  )
    .map((id) => (id == null ? undefined : pageById.get(id)))
    .filter((p): p is PageNode => p !== undefined);

  // D-27 — pages from the previous `{Section} / {Name}` scheme were
  // drained by the placement pass above (their nodes moved to `❖ {Name}`
  // pages, id/key preserved); an EMPTIED old-scheme page is migration
  // debris and is removed like the legacy 🧩 Components page. A non-empty
  // one is kept and reported — nothing is deleted silently.
  // (`kOldSchemePage`, module level — the load prelude reads it too.)
  for (const p of figma.root.children.slice()) {
    if (!kOldSchemePage.test(p.name)) continue;
    if (p.children.length > 0) {
      log.push(
        `⚠ old-scheme page "${p.name}" kept — ${p.children.length} node(s) remain ` +
          `(never deleted silently)`,
      );
      continue;
    }
    if (figma.currentPage === p) {
      // `orderedPages` is empty only when the file has no plugin page — any
      // page that is not this one will do, the point is only to stop
      // standing on it.
      const landing =
        orderedPages[0] ?? figma.root.children.find((other) => other !== p);
      if (landing) await figma.setCurrentPageAsync(landing);
    }
    if (figma.currentPage !== p) {
      p.remove();
      log.push(`🗑 removed emptied old-scheme page "${p.name}"`);
    }
  }

  // ── Text styles ──────────────────────────────────────────────────────
  // Attached inside the entries that drew the labels (`text-style-attach.ts`);
  // what is left here is the account.
  //
  // A label still queued here reached no drain. With an attacher installed
  // that is a path this file does not know about, and it is said out loud;
  // without one (the styles could not be read) it is every label of the run.
  const strandedStyles = takePendingTextStyles().length;
  if (textStyles != null) {
    const st = textStyles.attacher.stats;
    if (st.queued + strandedStyles > 0) {
      log.push(
        formatTextStyleAttachLine(
          st.attached,
          st.queued + strandedStyles,
          textStyles.preloadMs + st.ms,
          { fontLoadMs: textStyles.faces.ms, faces: textStyles.faces.loaded.size },
          st.growth.stats(),
          { before: st.decoratedBefore, restored: st.decorationRestored },
        ),
      );
    }
    if (st.namesNotFound.size > 0) {
      log.push(
        `⚠ 텍스트 스타일 ${st.namesNotFound.size}종을 찾지 못해 그 노드는 예전처럼 ` +
          `노드 바인딩으로 남았다 — "변수로 가져오기"를 먼저 돌리면 생성된다: ` +
          `${[...st.namesNotFound].sort().join(' · ')}`,
      );
    }
    if (st.faceMissing > 0) {
      const failedFaces = [...textStyles.faces.failed.entries()].map(
        ([face, why]) => `${face} (${why})`,
      );
      log.push(
        `⚠ 텍스트 스타일 글꼴 ${textStyles.faces.failed.size}종을 불러오지 못해 라벨 ` +
          `${st.faceMissing}개는 노드 바인딩으로 남았다 — ${failedFaces.join(' · ')}`,
      );
    }
    if (st.decorationRestored > 0) {
      log.push(
        `↻ 텍스트 스타일이 지운 밑줄 ${st.decorationRestored}/${st.decoratedBefore}개를 라벨에 되돌렸다 — ` +
          `스타일이 싣는 textDecoration(NONE)이 빌더가 쓴 값을 덮는 것은 부착이 들어온 때부터 있던 ` +
          `동작이고, 여기서 매번 복원한다`,
      );
    }
    if (st.hangulRuns > 0) {
      log.push(
        `↻ 고정폭 라벨의 한글 구간 ${st.hangulRuns}개를 본문 서체로 다시 칠했다 — 텍스트 스타일이 ` +
          `구간마다 글꼴을 고정폭으로 되돌리므로 붙일 때마다 칠한다`,
      );
    }
    if (st.hangulFailed > 0) {
      log.push(
        `⚠ 고정폭 라벨 ${st.hangulFailed}개의 한글 구간을 본문 서체로 칠하지 못했다 — 스타일은 붙었고 ` +
          `한글만 고정폭에 남았다 (${st.hangulFirstError ?? '원인 없음'})`,
      );
    }
    if (strandedStyles > 0) {
      log.push(`⚠ 어느 드레인에도 닿지 않은 라벨 ${strandedStyles}개 — 스타일 없이 노드 바인딩으로 남았다`);
    }
  } else if (strandedStyles > 0) {
    log.push(`⚠ 텍스트 스타일을 읽지 못해 라벨 ${strandedStyles}개가 노드 바인딩으로 남았다`);
  }

  // What this run LEFT behind, over the whole REGISTRY — not just the scope
  // it walked. A partial run (one section, a few checked components) draws
  // what it was asked to and says `Done`, and nothing in that word says the
  // other sets are still the code from before the merge. Read off the loop's
  // live index while it is still installed: every set the run just stamped
  // is in it, and so is every set it never touched.
  //
  // Wrapped — this summary is extra information, not the run's result. If a
  // node in the live index throws reading `.type` / `getPluginData` (a
  // removed-node alias — the per-entry catch above already logs a real
  // instance of a node "still sitting in the live index" after a later
  // entry's failure undid it), the summary must not take a 71-minute run's
  // whole `log` down with it.
  //
  // A cache-hit run's index holds only the names it read (#4803), so the
  // summary is scoped to them and says so — reading the rest would mean
  // loading their pages, the very cost the hit avoided, and reporting them
  // absent would be false.
  let staleAfterRun: string[];
  const staleEntries =
    cachedNodeIndex !== null && requiredNames !== null
      ? REGISTRY.filter((e) => requiredNames.includes(e.name))
      : REGISTRY;
  try {
    staleAfterRun = formatStaleSets(classifyRegistry((name) => nodeIndex.get(name), staleEntries));
    if (staleEntries !== REGISTRY) {
      staleAfterRun.push(
        `  (캐시 적중 — 이번 범위 ${staleEntries.length}/${REGISTRY.length} 개만 읽었다. ` +
          '전체는 "낡은 세트 보기")',
      );
    }
  } catch (e) {
    staleAfterRun = [`⚠ 낡은 세트 요약 실패 (${String(e)})`];
  }

  // 이번 실행이 흘린 것 — 낡은 세트와 달리 live index 로는 답할 수 없다. 그
  // 인덱스는 빌드 **전**에 만들어졌고 이름→COMPONENT/SET 만 담으므로, 어디에도
  // 붙이지 않은 조각은 거기 처음부터 없다(→ orphan-nodes.ts 헤더). 페이지는
  // 이미 전부 로드돼 있어 이 순회에 로드 왕복은 없다.
  //
  // 자기 마커를 먼저 찍는다. 이건 실행 끝에 새로 생긴 전수 순회이고, 마커가
  // 없으면 여기서 죽은 실행이 "마지막 엔트리를 그리다 죽었다" 로 읽힌다 —
  // `last-step` 이 무로그 사망의 유일한 단서인 동안 그 해상도를 흐리지 않는다.
  // `run:done` 은 여전히 마지막에 찍혀 종료 상태로 남는다.
  //
  // 캐시 적중 실행(#4803)은 로드한 페이지만 훑는다. 흘린 조각은 그리던
  // 페이지에만 떨어지고(orphan-nodes.ts 헤더) 이번 실행이 그린 페이지는 전부
  // 로드돼 있으므로 "이번 실행이 흘린 것" 은 그대로 답한다 — 나머지 페이지를
  // 여기서 로드하면 적중이 아낀 비용을 꼬리에서 도로 치른다.
  markStep('orphan-scan');
  const orphanScanStart = Date.now();
  let orphansAfterRun: string[];
  const orphanScope = cachedNodeIndex !== null ? loadedPageNames : undefined;
  try {
    orphansAfterRun = formatOrphanNodes(await listOrphanNodes(orphanScope));
  } catch (e) {
    // 낡은 세트 요약과 같은 이유로 감쌌다 — 부가 정보이지 실행의 결과가 아니다.
    orphansAfterRun = [`⚠ 고아 노드 요약 실패 (${String(e)})`];
  }
  const orphanScanMs = Date.now() - orphanScanStart;

  // 겹친 형제 — 같은 잔해의 다른 층(#4876). 고아 스캔은 페이지 직계를, 이건
  // 변형 직계를 본다(overlapping-siblings.ts 헤더). 이번 실행이 다시 그린 세트는
  // `resetNode` 가 이미 걷었으므로 여기서 잡히는 것은 이번 실행이 건드리지 않은
  // 세트의 것이다 — 그래서 실행의 결과가 아니라 부가 정보로 감싼다. 자기 마커를
  // 따로 찍는 이유는 고아 스캔과 같다.
  markStep('overlap-scan');
  const overlapScanStart = Date.now();
  let overlapsAfterRun: string[];
  try {
    overlapsAfterRun = formatOverlappingSiblings(await listOverlappingSiblings(orphanScope));
  } catch (e) {
    overlapsAfterRun = [`⚠ 겹친 형제 요약 실패 (${String(e)})`];
  }
  const overlapScanMs = Date.now() - overlapScanStart;

  // #4803 — the index this run ends with, for the next run to trust or refuse.
  // Written from the LIVE index (every set this run drew is registered in it)
  // and the page list as it stands now (this run may have created or
  // reordered pages). A hit carries the entries it never looked at over from
  // the cache it trusted; a full run replaces the cache outright. A handle
  // that no longer resolves is dropped to "unknown" — neither an entry nor
  // absent — so the next run that needs that name misses instead of guessing.
  try {
    const live: [string, CachedIndexEntry | null][] = [];
    for (const [name, node] of nodeIndex) {
      try {
        const page = directPageNameOf(node);
        live.push([name, page === null || node.removed ? null : { id: node.id, page }]);
      } catch {
        live.push([name, null]);
      }
    }
    if (cachedNodeIndex !== null && failed > 0) {
      // A hit run's index holds only the names it declared it would read. An
      // entry that composes a child it never declared in `needs` finds nothing
      // and fails here while a full run would have found it — so a failed hit
      // does not vouch for the cache: it is dropped, and the next run walks
      // the whole document and rewrites it.
      figma.root.setPluginData(kComponentIndexCacheKey, '');
      log.push(
        `⚠ 캐시 적중 실행에서 ${failed}개가 실패해 컴포넌트 인덱스 캐시를 지웠다 — 다음 실행은 전체 로드`,
      );
    } else {
      const nextCache = nextComponentIndexCache(
        cachedNodeIndex !== null && storedIndexCache !== null ? storedIndexCache.entries : null,
        live,
        { build: kSharedSourceHash, pages: pageSignature(figma.root.children) },
      );
      figma.root.setPluginData(kComponentIndexCacheKey, JSON.stringify(nextCache));
    }
  } catch (e) {
    // Extra, like the two summaries above: a run that cannot write its cache
    // costs the next run a full load, not this run its log.
    log.push(`⚠ 컴포넌트 인덱스 캐시를 쓰지 못함 — 다음 실행은 전체 로드 (${String(e)})`);
  }

  // Run-scoped — a stale index would alias freed nodes on the next run.
  clearNodeIndex();
  markStep('run:done');
  // The finish time the next run compares `last-step` against (#4876).
  markLastDone();
  clearGlyphIndex();

  const totalMs = Date.now() - startedAt;
  log.push(
    `Done. ${built} built, ${skipped} skipped (unchanged), ${total} total` +
      (failed ? `, ${failed} failed (see ✗ above)` : '') +
      ` across ${targetPages.size} pages. Total: ${(totalMs / 1000).toFixed(1)}s.`,
  );
  if (keptInnerTotal + replacedInnerTotal > 0) {
    log.push(
      `↺ 다시 그린 멤버의 안쪽 노드: kept ${keptInnerTotal} / replaced ${replacedInnerTotal} — ` +
        '유지된 노드의 인스턴스 덮어쓰기는 남고, 교체된 노드의 것은 풀린다.',
    );
  }
  for (const line of staleAfterRun) log.push(line);
  for (const line of orphansAfterRun) log.push(line);
  for (const line of overlapsAfterRun) log.push(line);
  const slowest = durations
    .slice()
    .sort((a, b) => b.ms - a.ms)
    .slice(0, 5);
  if (slowest.length > 0) {
    log.push(`Slowest: ${slowest.map((d) => `${d.name} (${d.ms}ms)`).join(', ')}`);
  }
  for (const line of formatNfrEReport({
    totalMs,
    scoped: byEntryNames || bySections,
    loadAsyncMs,
    pageCount,
    totalPageCount: allPages.length,
    nodeIndexMs,
    nodeCount: nodeIndex.size,
    orphanScanMs,
    overlapScanMs,
    buildPhaseMs,
    docsPhaseMs,
    parityPhaseMs,
    paritySplit,
    largestSet,
  })) {
    log.push(line);
  }
  return log;
}

// ─── NFR-E 재계측 report (#4038 / C5) ───────────────────────────────────────

/** One run's phase measurements — the three line items C5 names, plus the
 *  total they are shares of. */
export interface NfrEMeasurement {
  totalMs: number;
  /** Whether this run was itself scoped to a section/entry selection
   *  (`GenerateOptions.sections`/`entryNames`), as opposed to a full run of
   *  the whole REGISTRY (#5008). The R-3 verdict below only fires for a
   *  scoped run — a full run's own, non-gating ceiling is
   *  `kFullRunObservationCeilingMs`, checked separately. */
  scoped: boolean;
  /** Line item 1a — `page.loadAsync()` over the pages this run LOADED. */
  loadAsyncMs: number;
  /** Pages actually loaded — the whole document on a full walk, the scope's
   *  pages on a component-index cache hit (#4803). */
  pageCount: number;
  /** The document's page count. Absent or equal to `pageCount` = a full
   *  walk, printed as before; a smaller `pageCount` = a cache hit, printed
   *  as `loaded/total`. */
  totalPageCount?: number;
  /** Line item 1b — B1's document-wide mint-by-name index. */
  nodeIndexMs: number;
  nodeCount: number;
  /** 실행 꼬리의 고아 노드 스캔 — 페이지 전수 순회 하나(로드는 이미 끝나 있다).
   *  측정하지 않은 새 O(pages) 순회는 `totalMs` 만 늘리고 어느 line item 이
   *  늘었는지 말하지 못한다. Absent / 0 = 적지 않는다. */
  orphanScanMs?: number;
  /** 실행 꼬리의 겹친 형제 스캔(#4876) — 세트 변형마다 직계 자식을 읽는 두 번째
   *  꼬리 순회. 같은 이유로 따로 센다. Absent / 0 = 적지 않는다. */
  overlapScanMs?: number;
  /** Builder time only, docs frames excluded. */
  buildPhaseMs: number;
  /** 지문 + 디자이너 대조 읽기 — 그리기가 아니라 읽기라 따로 센다.
   *  Absent = 0 (계측이 없던 호출자). */
  parityPhaseMs?: number;
  /** `parityPhaseMs` 를 무엇에 썼는지로 나눈 것 — 네 조각의 합이 그 총합이다.
   *  사전 지문(덮어쓰기 전 대조) · 스냅샷(덮어쓰기 전 복제 — 리디자인 보존과
   *  백업 둘 다) · 지문 기록(다시 그린 뒤) · 대조(`parityReport`). Absent =
   *  총합만 적는다. */
  paritySplit?: ParitySplit;
  /** Line item 2 — D1/D2 Properties table + Code Examples TextNodes. */
  docsPhaseMs: number;
  /** Line item 3 — the run's most expensive COMPONENT_SET, or null when no
   *  set was built (every entry skipped, or a single-COMPONENT-only scope). */
  largestSet: { name: string; variants: number; ms: number } | null;
}

// Pure so the thresholds and the arithmetic are falsifiable off-sandbox
// (selftest-nfr-e-report). The NUMBERS still have to come from a real Figma
// run — that is the measurement half C5 keeps open, and faking a clock here
// would produce a report that looks like the AC was met when nothing was
// measured. What this function owns is the part that can be wrong without a
// Figma session: which verdict a given total earns, and how the shares read.
export function formatNfrEReport(m: NfrEMeasurement): string[] {
  const pct = (ms: number): string =>
    m.totalMs > 0 ? `${((ms / m.totalMs) * 100).toFixed(0)}%` : '—';
  const secs = (ms: number): string => `${(ms / 1000).toFixed(1)}s`;
  const fromCache = m.totalPageCount !== undefined && m.pageCount < m.totalPageCount;
  const out = [
    '── NFR-E 재계측 (항목별 소요) ──',
    `  loadAsync: ${secs(m.loadAsyncMs)} (${pct(m.loadAsyncMs)}) — ` +
      (fromCache
        ? `${m.pageCount}/${m.totalPageCount} pages (인덱스 캐시 적중) · ` +
          `캐시 인덱스 ${secs(m.nodeIndexMs)} (${pct(m.nodeIndexMs)}, ${m.nodeCount} nodes)`
        : `${m.pageCount} pages · ` +
          `문서 전체 인덱스 ${secs(m.nodeIndexMs)} (${pct(m.nodeIndexMs)}, ${m.nodeCount} nodes)`) +
      (m.orphanScanMs ? ` · 고아 스캔 ${secs(m.orphanScanMs)} (${pct(m.orphanScanMs)})` : '') +
      (m.overlapScanMs ? ` · 겹친 형제 스캔 ${secs(m.overlapScanMs)} (${pct(m.overlapScanMs)})` : ''),
    `  builders: ${secs(m.buildPhaseMs)} (${pct(m.buildPhaseMs)}) · ` +
      `docs frames (TextNode): ${secs(m.docsPhaseMs)} (${pct(m.docsPhaseMs)})` +
      (m.parityPhaseMs
        ? ` · 지문/대조: ${secs(m.parityPhaseMs)} (${pct(m.parityPhaseMs)})` +
          (m.paritySplit
            ? ` [사전 지문 ${secs(m.paritySplit.preMs)} · 스냅샷 ${secs(m.paritySplit.snapshotMs)} · ` +
              `지문 기록 ${secs(m.paritySplit.stampMs)} · 대조 ${secs(m.paritySplit.parityMs)}]`
            : '')
        : ''),
    m.largestSet === null
      ? '  largest variant set: none built this run (all skipped or single COMPONENTs)'
      : `  largest variant set: ${m.largestSet.name} — ${m.largestSet.variants} variants in ` +
        `${secs(m.largestSet.ms)} (${pct(m.largestSet.ms)})`,
  ];
  // R-3 verdict. NFR-007's budget is a scoped run's own unit (#5008) — it
  // gates a section/entry-scoped run only. A full run has no smaller unit to
  // split into by being asked to build everything, so it never sees these
  // two and is judged separately below.
  if (m.scoped) {
    // Two thresholds, two different answers — the 5-minute line is the
    // budget being missed, the 10-minute line is the budget being
    // renegotiated into a further split (never into building less).
    if (m.totalMs > kTenMinutesMs) {
      out.push(
        `⚠ ${secs(m.totalMs)} — 10분(예산 2배) 초과. R-3: 섹션 단위 분할 실행으로 전환하세요 — ` +
          `플러그인 UI 의 섹션 체크박스로 한 섹션씩 실행하면 ` +
          `합집합이 전체 실행과 같은 결과로 수렴합니다 (기능 축소 아님).`,
      );
    } else if (m.totalMs > kFiveMinutesMs) {
      out.push(
        `⚠ Total generation time exceeded the 5-minute NFR-007 budget (${(m.totalMs / 1000).toFixed(0)}s).`,
      );
    }
  } else if (m.totalMs > kFullRunObservationCeilingMs) {
    // Observation only (#5008) — never a split recommendation (there is
    // nothing smaller to split a full run into that is still a full run),
    // never a merge-blocking failure. It exists so a full run that has
    // quietly grown much slower than the last measured baseline leaves a
    // line in this log instead of nobody noticing.
    out.push(
      `ℹ 전량 실행 ${secs(m.totalMs)} — 관찰용 상한(40분) 초과. 예산 위반이 아니라 회귀 탐지용 기록이다 — ` +
        `전량 실행 자체는 지원 대상이며 분할을 권하지 않는다.`,
    );
  }
  return out;
}

// ─── 스코프 이름 해석 (#4038 / C5) ──────────────────────────────────────────

/**
 * 실행이 건드릴 엔트리 이름 집합. `null` 이면 전량이다. 순수.
 *
 * ## 왜 함수로 뽑혀 있나
 *
 * 실행과 셀프테스트가 **같은 해석**을 지나야 하기 때문이다. 이 로직이
 * `generateComponents` 안에 인라인돼 있는 동안, 합집합 동등성을 검사하는
 * 테스트는 자기가 계산한 파티션을 검사할 수밖에 없었다 — 그러면 검사는
 * 개념에 대해서만 참이고, 출하되는 필터가 그것과 갈려도 초록이다. 실제로
 * 갈려 있었다(아래).
 *
 * ## 두 스코프
 *
 * `entryNames`(#4526, UI 컴포넌트 트리)가 둘 다 오면 이긴다 — 정확한 답이고,
 * `sections` 는 트리를 채택하지 않은 호출자를 위한 성긴 fallback 이다.
 *
 * ## 섹션 해석은 `sectionOfEntry` 다
 *
 * raw 데이터 lookup 이 아니다. 둘은 12개 엔트리에서 갈린다 — 자기 디렉터리가
 * 없어 데이터가 답하지 못하고 REGISTRY 가 직접 섹션을 선언하는 것들이다.
 * raw lookup 을 쓰면 그 12개는 **어떤 섹션 실행으로도 도달하지 않아**
 * 합집합이 전체보다 작아지고, 같은 함수로 섹션을 보이는 UI 트리가 약속한
 * 것과도 갈린다.
 */
export function resolveScopedNames(options?: {
  entryNames?: readonly string[];
  sections?: readonly string[];
}): { names: Set<string> | null; added: string[] } {
  const entryScope =
    options?.entryNames && options.entryNames.length > 0 ? new Set(options.entryNames) : null;
  const sectionScope =
    !entryScope && options?.sections && options.sections.length > 0
      ? new Set(options.sections)
      : null;
  const picked =
    entryScope ??
    (sectionScope
      ? new Set(
          REGISTRY.filter((e) => {
            const section = sectionOfEntry(e);
            return section !== null && sectionScope.has(section);
          }).map((e) => e.name),
        )
      : null);
  if (picked === null) return { names: null, added: [] };
  const { closed, added } = closeOverNeeds(picked, REGISTRY);
  return { names: closed, added };
}
