/// <reference types="@figma/plugin-typings" />

import type { SizingDeclaration } from './sizing-audit';
import {
  VariantIdentityError,
  diffVariantNames,
  parseVariantKey,
  verifyAppendedVariant,
} from './variant-safety';
import { RETIRED_VARIANTS, VARIANT_RENAMES } from './renames';
import {
  Color,
  Dim,
  argbAlpha,
  argbToRgb,
  colorData,
  dimVal,
  familyTokenOf,
  lineBoxAfter,
  roleMetrics,
  textStyleData,
} from './compat/v1';
import iconsJson from './data/icons.json';
import { bestVariantName, setSlotIcon } from './component-props';
import { VarLookup, corners } from './variables';
import { defaultSetLayout } from './set-layout';
import { weightStyle } from './paint';
import type { LabelOpts } from './text-nodes';
import {
  ColorData,
  ShadowData,
  fadeNode,
  flushTintLayers,
  pinAbsolute,
  pinInFlow,
  solid,
  tintLayer,
} from './paint';
import type { PadData } from './box';
import { findComponentByName, mint, stampOwned } from './identity';

// ─── The drawing primitives, measured at the barrel ───────────────────────
//
// Imported under `…Raw` and re-exported below through `measured`, which bills
// each call to a `DrawSpan`. Wrapping HERE rather than at each definition is
// deliberate and load-bearing:
//
//   1. Every one of the ~150 builders reaches these through this barrel and
//      nothing else does — the drawing modules import each other directly, so
//      a wrapper here can never nest inside another wrapper and double-bill.
//      (`grep -l "from './helpers'" src/*.ts` is the check: only top-level
//      commands, no drawing module.)
//   2. It keeps the timing out of `box.ts` / `paint.ts` / `frames.ts` /
//      `text-nodes.ts` / `icon-nodes.ts` entirely, so those files stay about
//      drawing and the accounting lives in one readable place.
//
// The nesting rule the wrappers depend on: a wrapped function's IMPLEMENTATION
// must never reach the barrel. `frames.ts` is the case that tests it — `panel`
// calls `applyChrome` calls `bindSpaceField`, three functions all wrapped here,
// but every one of those inner calls resolves through `./box` / `./paint`
// directly. So the charge lands once, at the outermost call the builder made.
// Adding a `from './helpers'` import to any drawing module would break that
// silently: nothing would fail, the spans would simply start summing past the
// build total and the remainder would clamp to zero.
//
// The cost of that placement: a call that bypasses the barrel is invisible
// here and lands in the line's `미계측` remainder rather than being
// mis-attributed — which is the failure direction to prefer.
import {
  borderData as borderDataRaw,
  fillData as fillDataRaw,
  fillSem as fillSemRaw,
  paintTokenFill as paintTokenFillRaw,
  setBorder as setBorderRaw,
  setShadow as setShadowRaw,
} from './paint';
import {
  addControlBorder as addControlBorderRaw,
  addControlShadow as addControlShadowRaw,
  applySurfaceMaterial as applySurfaceMaterialRaw,
  bindSurfaceShare as bindSurfaceShareRaw,
  setSurfaceRim as setSurfaceRimRaw,
} from './surface-material';
export { kGlassLayerName, kMaterialLayerName, paintsFill } from './surface-material';
export type { SurfaceCorners, SurfaceMaterialOpts, SurfaceRole } from './surface-material';
import {
  bindAxisSize as bindAxisSizeRaw,
  bindBox as bindBoxRaw,
  bindPad as bindPadRaw,
  bindRadiusN as bindRadiusNRaw,
  bindRadiusOrLiteral as bindRadiusOrLiteralRaw,
  bindSize as bindSizeRaw,
  bindSpaceField as bindSpaceFieldRaw,
  bindStrokeAxis as bindStrokeAxisRaw,
} from './box';
import {
  applyChrome as applyChromeRaw,
  applyFormRowChrome as applyFormRowChromeRaw,
  applyPanelCompChrome as applyPanelCompChromeRaw,
  autoFrame as autoFrameRaw,
  indicatorBox as indicatorBoxRaw,
  lockWidth as lockWidthRaw,
  mintPanelComp as mintPanelCompRaw,
  panel as panelRaw,
} from './frames';
import { drainTextStyleAttach, makeLabel as makeLabelRaw, roleDeparture } from './text-nodes';
import { makeIcon as makeIconRaw } from './icon-nodes';
import {
  bindFocusRing as bindFocusRingRaw,
  focusRing as focusRingRaw,
} from './focus-ring';
export { focusOutlineRingColor } from './focus-ring';
export type { FocusRingNodes } from './focus-ring';
import {
  bindSwapProp as bindSwapPropRaw,
  bindTextProp as bindTextPropRaw,
  bindVisibleProp as bindVisiblePropRaw,
  defineProp as definePropRaw,
} from './component-props';
import { instanceOf as instanceOfRaw } from './identity';
import { slotStandIn as slotStandInRaw } from './slot-stand-in';
import { DetailSpan, DrawSpan, recordDetailSpan, recordDrawSpan, recordYield } from './identity';

/**
 * Wraps `fn` so every call is billed to `span`. The returned function has
 * `fn`'s exact signature — derived from it rather than restated, so a change
 * to the wrapped function's parameters cannot leave a stale copy here.
 *
 * `finally` rather than a trailing record: a builder that throws mid-draw
 * (`makeIcon` on a missing `Icon` is the common one) has still spent the
 * time, and generate.ts prints a span line on the failure path too.
 */
function measured<F extends (...args: never[]) => unknown>(span: DrawSpan, fn: F): F {
  return function (...args: never[]): unknown {
    const startedAt = Date.now();
    try {
      return fn(...args);
    } finally {
      recordDrawSpan(span, startedAt);
    }
  } as F;
}

export const bindAxisSize = measured('chrome', bindAxisSizeRaw);
export const bindBox = measured('chrome', bindBoxRaw);
export const bindPad = measured('chrome', bindPadRaw);
export const bindRadiusN = measured('chrome', bindRadiusNRaw);
export const bindRadiusOrLiteral = measured('chrome', bindRadiusOrLiteralRaw);
export const bindSize = measured('chrome', bindSizeRaw);
export const bindSpaceField = measured('chrome', bindSpaceFieldRaw);
export const bindStrokeAxis = measured('chrome', bindStrokeAxisRaw);
export const borderData = measured('chrome', borderDataRaw);
export const fillData = measured('chrome', fillDataRaw);
export const fillSem = measured('chrome', fillSemRaw);
export const paintTokenFill = measured('chrome', paintTokenFillRaw);
export const setBorder = measured('chrome', setBorderRaw);
export const setShadow = measured('chrome', setShadowRaw);
// A surface's fill, routed through its material layers (`surface-material.ts`),
// and what a surface style contributes to a surface or control that draws none.
export const applySurfaceMaterial = measured('chrome', applySurfaceMaterialRaw);
export const addControlBorder = measured('chrome', addControlBorderRaw);
export const addControlShadow = measured('chrome', addControlShadowRaw);
export const bindSurfaceShare = measured('chrome', bindSurfaceShareRaw);
export const setSurfaceRim = measured('chrome', setSurfaceRimRaw);
// The same bucket, reached through the composite spelling. `panel` is
// `autoFrame` + `applyChrome`, and `applyChrome` is up to six of the binds
// above — all called inside `frames.ts`, which imports `box`/`paint`
// directly and so never re-enters a wrapper. Billing the composite is
// therefore one charge for the same work, not a second one on top.
//
// Wrapping these is a correction, not an addition. Without them the span
// under-reported for exactly the builders that use the composite API: two
// builders binding identical padding read differently depending on which
// spelling they reached for, and `panel` alone has 168 call sites. A bucket
// whose value depends on how the caller spelled the call is not measuring
// the thing it is named after.
export const applyChrome = measured('chrome', applyChromeRaw);
export const applyFormRowChrome = measured('chrome', applyFormRowChromeRaw);
export const applyPanelCompChrome = measured('chrome', applyPanelCompChromeRaw);
export const autoFrame = measured('chrome', autoFrameRaw);
export const indicatorBox = measured('chrome', indicatorBoxRaw);
export const lockWidth = measured('chrome', lockWidthRaw);
// Mints a node, but a chrome one — a sub-frame of the member being drawn,
// not the member itself. `node` is reserved for `getOrCreate`, whose cost is
// the mint-by-name lookup over the whole document; conflating a plain
// `createComponent` with that would blur the one span that is supposed to
// isolate the recycle path.
export const mintPanelComp = measured('chrome', mintPanelCompRaw);
export const panel = measured('chrome', panelRaw);
export const makeLabel = measured('text', makeLabelRaw);
export const makeIcon = measured('icon', makeIconRaw);
export const focusRing = measured('ring', focusRingRaw);
export const instanceOf = measured('instance', instanceOfRaw);
// The same bucket: a slot's stand-in IS one composed child instance, and
// `slot-stand-in.ts` reaches `instanceOf` through `./identity`, never through
// here — so the call is billed once, at the builder's call.
export const slotStandIn = measured('instance', slotStandInRaw);
export { kSlotShapes, kSlotStandInComponent, slotStandInDefault } from './slot-stand-in';
export type { SlotShape, SlotStandInShape } from './slot-stand-in';

/**
 * `measured`'s sibling for the property helpers, billed to a `DetailSpan`
 * rather than a `DrawSpan`.
 *
 * Why these five: Button's pass after `finish()` is seven definitions and then
 * up to seven binds per member, each bind reading `componentPropertyReferences`
 * back before writing it — across 972 members, and inside no span at all, so
 * every millisecond of it read as `미계측`. Why here: the same rule as the
 * wrappers above. Builders reach these through this barrel; the property
 * module is imported directly only by drawing modules, which never re-enter a
 * wrapper, so each call is billed once, at the call the builder made.
 *
 * Their own buckets rather than `chrome`, because this is not drawing — a bind
 * changes what a designer can override, not what renders — and two buckets
 * rather than one, because a definition and a bind are different costs and
 * each is sampled for growth on its own (`DetailSpan`).
 *
 * Not reached, and so left in `미계측`: a property call a drawing module makes
 * on its own account. `instance-reach.ts#composeCountBadge` binds its badge's
 * `visible` straight through the property module, once per labelled row of
 * the builders that compose it, and has to — `instance-reach.ts` importing
 * this barrel would close an import cycle (`helpers` → `focus-ring` →
 * `instance-reach` → `helpers`). Its callers invoke it at top level, so the
 * cycle, not double billing, is what keeps it out.
 */
function measuredDetail<F extends (...args: never[]) => unknown>(span: DetailSpan, fn: F): F {
  return function (...args: never[]): unknown {
    const startedAt = Date.now();
    try {
      return fn(...args);
    } finally {
      recordDetailSpan(span, startedAt);
    }
  } as F;
}

export const defineProp = measuredDetail('define', definePropRaw);
export const bindTextProp = measuredDetail('props', bindTextPropRaw);
export const bindVisibleProp = measuredDetail('props', bindVisiblePropRaw);
export const bindSwapProp = measuredDetail('props', bindSwapPropRaw);
// One charge for the ring and its band: `focus-ring.ts` binds both through the
// property module directly, so the pair costs one call here, not three.
export const bindFocusRing = measuredDetail('props', bindFocusRingRaw);

/**
 * Times a read of a laid-out property and bills it to `geom`.
 *
 * Reading `.width` on a node whose auto-layout is dirty makes Figma settle
 * the layout before it can answer, and that settle is the one cost here that
 * plausibly scales with the whole document rather than with the component
 * being drawn — exactly the shape of the recycle-path penalty nobody has
 * explained. It is a remainder-dweller otherwise: the read is a property
 * access, so there is no call for a wrapper to sit on and the only way to
 * measure it is for the reading builder to say where it is.
 *
 * Used at the reads that follow a mutation. A second read of the same
 * unchanged box is answered from the settled layout and costs nothing, so
 * bracketing every `.width` in the file would add calls without adding
 * information.
 */
export function timedGeom<T>(read: () => T): T {
  const startedAt = Date.now();
  try {
    return read();
  } finally {
    recordDrawSpan('geom', startedAt);
  }
}

// Partly a barrel now. `helpers.ts` had 96 exports across nine concerns behind
// dividers that no longer described their contents — one divider named "Figma
// component properties" covered 1082 lines holding component properties, instance-
// subtree reach, AND node identity. Each concern is moving to a module named after
// it; re-exporting here means a call site migrates when it is touched rather than in
// one sweep rewriting 34 files.
export { VarLookup, canonicalCollection, corners } from './variables';
export {
  afterBindsLand,
  clearNodeIndex,
  completePendingMounts,
  findComponentByName,
  indexDocumentComponents,
  installNodeIndex,
  drainResetNodeCost,
  kBulkDetachMinMembers,
  mainComponentIdOf,
  markReassembledOffPage,
  mint,
  mountSet,
  pendingMountCount,
  pendingMountMembers,
  prefersDuplicateWinner,
  reassemblyMode,
  recordDetailSpan,
  resetNode,
  restoreDisassembledSets,
  setReassemblyMode,
  stampOwned,
} from './identity';
export type {
  BuildCost,
  BuildDetail,
  DetailSpan,
  DrawSpan,
  ReassemblyMode,
  ReassemblyReport,
  SetMount,
  SetMountOptions,
  SpanCost,
} from './identity';
import { markStep } from './last-step';
export { markStep } from './last-step';
export {
  bestVariantName,
  drainKeptSwapDefaults,
  drainRetypedProps,
  exposeAll,
  exposeSlot,
  formatRetypedProps,
  freePropName,
  iconMainId,
  iconMainIdAt,
  iconSwapDefault,
  propertyOwner,
  setInstanceBoolNamed,
  setInstanceSwapNamed,
  setInstanceTextNamed,
  setSlotIcon,
} from './component-props';
export { defaultSetLayout, layoutSet, rowSet, vStackSet, wrapSet } from './set-layout';
export {
  assignPaints,
  bindLayerOpacity,
  colorPaint,
  fadeNode,
  fillDataOnNode,
  fillDataOnPaint,
  flushTintLayers,
  gradientPaint,
  kGradientAnchor,
  linearGradientTransform,
  literalPaint,
  paintOpacityNotHeld,
  solid,
  tintLayer,
} from './paint';
export type { ColorData, GradientData, ShadowData, ShadowLayerData } from './paint';
export { weightStyle } from './paint';
export {
  addFocusRing,
  applyForwardedButtonStyle,
  applyForwardedCollapsibleStyle,
  applyForwardedPanelStyle,
  applyForwardedFieldText,
  revealFieldCaret,
  setFieldPlaceholder,
  applyInstanceTextStyle,
  bindInstanceOverlayRadius,
  composeCountBadge,
  expandInstanceLabel,
  focusOutlineBand,
  focusOutlineRing,
  forwardFocusBand,
  forwardFocusOutlineHostRadius,
  hostedDivider,
  kAvatarDefaultShape,
  kAvatarDefaultSize,
  kAvatarRest,
  kBadgeDefaultSize,
  kBadgeDefaultTone,
  kCollapsibleBodyName,
  kCollapsibleHeaderName,
  kCountBadgeDefault,
  kCountBadgeForm,
  kFieldInputName,
  kFieldRowName,
  kFieldValueName,
  kFocusOutlineBandName,
  kFocusOutlineRingName,
  kProgressDefaultSize,
  kProgressDefaultTone,
  namedDescendant,
  ownTextNodes,
  paintPlaceholder,
  pinComposedCorner,
  revealValueOverPlaceholder,
  scaleAlpha,
  suppressFieldChrome,
} from './instance-reach';
export type { FocusOutlineSlot } from './instance-reach';
export {
  ICON_NAMES,
  ICON_KEYS,
  buildIconGlyph,
  glyphPaint,
  kFillableShapes,
  kPreserveGlyphPaint,
  repaintGlyph,
  setIconGlyph,
  sizeStepsOf,
  installGlyphIndex,
  clearGlyphIndex,
  installIconModeIndex,
  clearIconModeIndex,
  heldIconModeIndex,
  refreshIconModeCollection,
  resolveIconModeIndex,
  prepareIconModes,
  alignSlotIconMode,
  iconVariantById,
  drainInexactIconSizes,
  drainSlotIconNotes,
  drainSlotIconWithoutCollection,
  findMisPinnedIconModes,
  findUnboundIconSizes,
} from './icon-nodes';
export {
  CONTENT_COLORS,
  contentToneOf,
  tokenOfColorVariable,
  installContentIndex,
  clearContentIndex,
  heldContentIndex,
  prepareContentColors,
  refreshContentCollections,
  flushContentModes,
  contentFlushLines,
  drainDirectGlyphs,
  drainContentWithoutCollection,
  dropPendingContentGlyphs,
} from './icon-content';
export type {
  ContentColorIndex,
  ContentFlushReport,
  ContentModeSet,
  ContentPin,
  ContentTone,
} from './icon-content';
export type {
  DrawnIcon,
  GlyphPaint,
  IconModeIndex,
  IconModeResolution,
  IconOpts,
  IconStrokeVariable,
  StatedGlyphPaint,
} from './icon-nodes';
export { loadFonts } from './text-nodes';
export type { LabelOpts } from './text-nodes';
export { applyLetterSpacing, drainTextStyleAttach } from './text-nodes';
export type { ChromeOpts } from './frames';
export {
  pinAbsolute,
  pinInFlow,
  pinsSkippedInsideInstance,
  sizePin,
  collectStaleWrapHolders,
  isStaleWrapHolder,
} from './paint';
export {
  drainOffScaleRadii,
  drainOffScaleSizes,
  drainOffScaleSpaces,
  noteOffScaleSize,
} from './box';
export {
  drainUnpinnedInstanceBoxes,
  hideInstanceLabel,
  instanceTextNode,
  pinInstanceBox,
} from './composed-instance';
export type { LogicalPadData, PadData, PhysicalPadData } from './box';

// Shared building blocks for the component generators. Every visual value a
// CoUI `CoreXxxStyle` can carry is bound to a Figma Variable here:
//   color      → Semantic    (color/<name>)
//   padding    → Primitives  (space/<n>)        via bindPad / bindBox
//   gap        → Primitives  (space/<n>)        via bindBox / setBoundVariable('itemSpacing')
//   radius     → Primitives  (radius/<n>)       via bindRadiusN / bindBox
//   border     → Primitives  (stroke/<n>)       via setBorder (strokeWeight bound)
//   size       → Primitives  (size/<n>)         via bindSize (width/height bound)
//   fontFamily → Primitives  (font/family/<name>) via makeLabel / loadFonts
//   fontSize   → Primitives  (font/size/<n>)      via makeLabel
//
// The Figma plugin runtime rejects object/array spread (`...`), so this file
// uses Object.assign / .slice() / explicit loops throughout.

// ─── Registry shape ──────────────────────────────────────────────────────────

export type BuildResult = ComponentSetNode | ComponentNode;

export interface RegistryEntry {
  section: string; // page column heading (Form / Display / Navigation / …)
  name: string; // component (set) name; also the idempotency key
  // `Promise<BuildResult>` is the escape hatch for a builder large enough to
  // report its own sub-progress (`reportSubProgressAndYield` below) — every
  // call site already `await`s this, and `await` on a plain (non-Promise)
  // return value resolves it immediately, so the ~143 synchronous builders
  // are unaffected.
  build: (page: PageNode, lk: VarLookup) => BuildResult | Promise<BuildResult>;
  /// REGISTRY names this builder instantiates and therefore needs already on
  /// the page. `generate.ts` topologically sorts on this before building.
  ///
  /// Why declared rather than inferred from build order: the generation loop
  /// walks sections (Form → Display → Navigation → Overlay → Layout), and a
  /// composition edge does not respect that — `PhoneInput` (Form) instantiates
  /// `Popover` (Overlay), so the parent runs 70 entries before the child
  /// exists. Reordering REGISTRY by hand would fix today's edges and silently
  /// break on the next one, because nothing states the constraint.
  needs?: readonly string[];
  /// The components.json slug whose data states this component's chrome, when it
  /// is not this component's own name.
  ///
  /// Most entries read `slugOfName(name)`. A few widgets share another
  /// component's Core Style instead of declaring one: `ResizableTable` takes a
  /// `CoreTableStyle` and calls `resolveTable`, so `table` is where its chrome is
  /// stated. Without this the derived slug (`resizable_table`) matches no entry
  /// and the fidelity check skips the component — which it did, silently, until
  /// the skip was made to report itself.
  ///
  /// Declared rather than inferred: the sharing lives in the widget's resolver
  /// call, and nothing in the Figma-side data records it.
  dataSlug?: string;
  /// With `dataSlug`: the parent's fields this fragment actually reads, and
  /// nothing else — `'item*'` names every field under that prefix, a bare name
  /// names that field. The fidelity check compares the fragment against this
  /// subset with the prefix stripped (`itemBorderRadius` → `borderRadius`), so
  /// the generic checks find the row's values under the names they look for.
  ///
  /// Why the slug alone is not enough: `command` states the PANEL as well as
  /// the row. Compared against the whole record, `CommandItem` was asked for
  /// the panel's 12px corner while it correctly paints the row's 8px one —
  /// a false miss that made the previous answer "compare it through the
  /// parent's instances" look right, until those instances were counted:
  /// `Command` places 9 of the row's 48 variants, none of them hover / pressed
  /// / disabled. Declared here, the row is checked on its own, all 48.
  ///
  /// `check_figma_registry_parity.sh` compares this list against what the
  /// builder reads through its `.fields` / size-row aliases — a read the list
  /// does not cover is a value the check cannot see.
  dataFields?: readonly string[];
  /// An axis that is fixed BY DEFINITION — a divider's thickness, a progress
  /// track's height, a dot's diameter — declared with its reason. The root
  /// sizing audit (#4805, `selftest-registry-runtime`) classifies every variant
  /// root's width and height as hug / fill-able / fixed box and ratchets the
  /// fixed boxes toward zero; a declared axis is left out of that count and
  /// its `why` is printed in the report instead. A declaration with no reason,
  /// or one no variant actually reads as fixed, fails the harness.
  ///
  /// Declared rather than inferred for the same reason as `needs`: nothing in
  /// the drawn node says WHY an axis is fixed, and the audit cannot tell a
  /// divider's thickness from a forgotten sizing mode. In entry literals this
  /// field goes AFTER `name:` — the registry-parity guard reads
  /// `section: … name: …` without braces in between.
  sizing?: SizingDeclaration;
  /// A builder fixture — a set the plugin draws for its own use, with no CoUI
  /// component behind it. Its name starts with `.`, which Figma reads as "do
  /// not publish": a consumer file never sees it in the assets panel.
  ///
  /// Why it is still an entry: the REGISTRY is what gives a set its identity
  /// (mint-by-name), its content hash, its place in the stale-set listing, and
  /// `needs` ordering — a fixture other builders compose needs all four. What it
  /// does NOT have is a data slug, so every reader that would look one up stands
  /// down on this field instead of reporting a missing record: the Generate
  /// warning, the docs frames, the fidelity sweep.
  ///
  /// `description` is what the set says about itself in the panel. `checkedBy`
  /// names the selftest that asserts what the builder draws — the comparison a
  /// contract would otherwise get from fidelity. `check_figma_registry_parity.sh`
  /// holds the pairing both ways: a `.` name declares this field, and this
  /// field is only on a `.` name. In entry literals it goes AFTER `name:`, for
  /// the same reason `sizing` does.
  ///
  /// `dataFrom` names the OTHER components' records the builder reads — a
  /// fixture has none of its own, so its content hash would otherwise never see
  /// that data move and the set would be reported current after the record it
  /// draws from changed. `figma_registry_names.py --fixture-faults` checks each
  /// slug names a record, because a typo hashes as `null` and stays silent.
  fixture?: { description: string; checkedBy: string; dataFrom?: readonly string[] };
  /// The entry VALIDATES a set a designer owns and draws nothing (`Icon`): it
  /// returns the existing set untouched. Everything that reads "what did this
  /// builder bind" stands down on it — the property cleanup (`unbound-props.ts`)
  /// would otherwise see a set whose glyph chooser no builder bound and report
  /// (or one day remove) a property the designer's own layers use. In entry
  /// literals it goes AFTER `name:`, for the same reason `sizing` does.
  validateOnly?: boolean;
}

// ─── Sub-entry progress + yield, for the rare builder too big to report as ──
// ─── one opaque unit ─────────────────────────────────────────────────────
//
// `generate.ts`'s outer loop reports progress once PER ENTRY, after that
// entry's `build()` returns — fine for the ~143 builders that finish in
// milliseconds, useless for the one (Button, 288 variant combos × icon
// instances + label + focus ring each) that can legitimately run for
// minutes in a real document: the UI has nothing to show for the entire
// span, and — because a Figma plugin's sandbox and its UI iframe share one
// render thread — neither does Figma itself, which is what turns "still
// working" into "looks exactly like frozen."
//
// A builder that wants to be watchable calls `reportSubProgressAndYield`
// periodically from inside its own loop. Two things happen: whatever's
// currently `install`ed hears the call (so `generate.ts` can relay it to the
// UI as `sub: {current, total}`), and — within the time budget below —
// control is actually handed back to the host via a real `setTimeout`, the
// only way a synchronous scene-graph loop can let the browser repaint
// mid-flight. This is why the builder itself must be declared `async`:
// nothing else can create a real yield point.
//
// Module-level rather than a parameter threaded through `RegistryEntry.build`
// for the same reason `drainInexactIconSizes` (icon-nodes.ts) is module-level
// — one caller (`generate.ts`) wants the signal, ~143 builders have nothing
// to say, and a parameter every builder would have to accept and ignore is
// noise. `generate.ts` installs a listener immediately before each `build()`
// call and clears it immediately after (success or catch), so a listener
// never survives past the entry it was installed for.
let subProgressListener: ((current: number, total: number) => void) | null = null;

// How long a loop may draw between two real ticks. Measured (#4038): the
// timer round-trip itself — not the mark, not the listener — cost 132ms a call
// on the host, 972 times over for Button, 128s of a 9,245s run that drew
// nothing. A repaint four times a second is enough for a progress label, and
// a combo draws in 74–119ms, so "every N combos" would starve the UI under
// load and tick needlessly without it; the budget is time. The listener and
// the last-step mark still run on every call — the UI's numbers and the
// footprint an interrupted run leaves are per combo, whether or not the host
// got a turn.
export const kYieldBudgetMs = 250;
// When the last real tick ended. Null before a loop's first call, which ticks
// unconditionally; so does a loop's last call, so the host gets the frame in
// which the set is about to be reassembled.
let lastTickEndedAt: number | null = null;

export function installSubProgressListener(
  fn: ((current: number, total: number) => void) | null,
): void {
  subProgressListener = fn;
  // A new entry starts with no tick behind it, whatever the last one left —
  // `generate.ts` installs before every build, so this is the per-entry
  // reset the `current === 0` rule below repeats for the loop itself.
  lastTickEndedAt = null;
}

export async function reportSubProgressAndYield(current: number, total: number): Promise<void> {
  // The previous combo's labels get their text styles first, while its member
  // is still off the set — the first point every write to them is done (see
  // `text-style-attach.ts`). Ahead of the clock below: the attach bills its own
  // span, and inside `yield` it would read as the timer being slow.
  await drainTextStyleAttach();

  // Billed to `yield`, because this is the one per-combo cost in a big
  // builder that draws nothing. A timer round-trip is nominally free, but
  // the host clamps nested timeouts and the sandbox shares a thread with
  // Figma's own render loop — so "free" is a claim about a browser, not a
  // measurement of this one, and Button pays it 432 times. Measured so the
  // claim can be checked before it is defended.
  //
  // Checked, it came back at 98ms a call, so the call is cut at its two inner
  // boundaries (`recordYield` names the parts). The boundaries are handed over
  // rather than re-read, which keeps the parts summing to the total, and they
  // are recorded in `finally` so a listener that throws still bills what it
  // spent.
  const startedAt = Date.now();
  if (current === 0) lastTickEndedAt = null;
  // Withheld only while the clock says the last tick is recent. A clock that
  // stepped backwards reads as a negative gap, and a negative gap must not
  // starve the host until it catches up.
  const sinceTick = lastTickEndedAt === null ? null : startedAt - lastTickEndedAt;
  const tick =
    current === 0 ||
    current >= total - 1 ||
    sinceTick === null ||
    !(sinceTick >= 0 && sinceTick < kYieldBudgetMs);
  let markedAt: number | null = null;
  let postedAt: number | null = null;
  try {
    // The footprint that outlives the realm — see `last-step.ts`.
    markStep(`sub:${current}/${total}`);
    markedAt = Date.now();
    subProgressListener?.(current, total);
    postedAt = Date.now();
    if (!tick) return;
    // A real event-loop tick — `await`ing a resolved value alone (no timer)
    // does not hand control back to the host the same way; it stays a
    // microtask, which the render thread does not get to interleave with.
    await new Promise<void>((resolve) => setTimeout(resolve, 0));
  } finally {
    const endedAt = Date.now();
    // A tick that was decided but never reached — the listener threw first —
    // is not a host turn and is not counted as one.
    const ticked = tick && postedAt !== null;
    if (ticked) lastTickEndedAt = endedAt;
    recordYield(startedAt, markedAt, postedAt, endedAt, ticked);
  }
}

// The page components used to live on, when they all lived on one.
//
// Nothing is built here any more — #4023 gives each component its own `❖ {Name}`
// page. This name survives as a MIGRATION TARGET: generate locates this page to
// drain and remove it, so a document from before the split keeps its node ids
// (and therefore every instance a designer placed) instead of being rebuilt.
//
// Single source, because a second spelling would make the drain look at a page
// that generate does not write to — and a drain that finds nothing reports
// success.
export const kComponentsPageName = '🧩 Components';

// The name of a mark drawn as a bar — a RECTANGLE whose height is the thickness
// a component states for its mark (the checkbox's indeterminate dash).
//
// Single source: the builder names the node with it and the fidelity readback
// finds the node by it. Two spellings would let a rename leave the readback
// looking for a bar nobody draws, and it would report nothing instead of a miss.
export const kMarkBarName = 'dash';

// The legacy page, if this document predates the per-component split.
export function findComponentsPage(): PageNode | null {
  return (figma.root.children.find((p) => p.name === kComponentsPageName) as PageNode | undefined) ?? null;
}

// ─── Variable lookup ─────────────────────────────────────────────────────────


// Every binding call site in this plugin speaks a collection's logical name
// ("Primitives" / "Semantic") while the library file spells it "Semantic/
// Color"; `canonicalCollection` folds the two together (and strips an
// ordering prefix a file may still carry — see variables.ts).

// Resolves variable objects by `Collection/name` so component bindings don't
// depend on hardcoded IDs. Collection names are canonicalized (see
// `canonicalCollection`) on both the index and the query side. Throwing
// getters (`sem`/`space`/…) fail loud when a token is missing; `*OrNull`
// variants are for optional bindings.

// ─── Identity — mint-by-name (#3737) ─────────────────────────────────────────
//
// "Make it, don't remake it." Every builder's entry point used to be
// `figma.createComponent()` (or a fresh `combineAsVariants`) called *after*
// generate.ts had already deleted whatever it made last time. `mint` /
// `mountSet` are the drop-in replacements: they find the persistent node by
// name and hand back an emptied one to populate, or create it once, the
// first time that name is ever seen. Nothing on the persistent-node path
// below ever calls `.remove()`.

const kPluginDataNamespace = 'coui-token-sync';

// Marks a node as one this plugin minted (a secondary signal — name is
// still primary — for future consumers like #3740/#3744 that need to tell
// "ours" apart from anything else a designer put on this page). Exported
// for the documentation frames (#4039/#4040), which are FRAMEs rather than
// components and so carry no other mark of authorship.

// Every VariableBindableNodeField this node currently has a binding for,
// unbound — read from `boundVariables`, not a fixed field list, so a future
// Figma API addition is covered automatically ("화이트리스트 불필요").
// `fills`/`strokes` bindings are excluded: builders replace those arrays
// wholesale (`node.fills = [...]`), which already discards any old binding.

// Clears a node back to the same blank slate `figma.createComponent()`
// hands a builder, so every existing builder body — which unconditionally
// re-sets every property it cares about — works unchanged whether the node
// is brand new or recycled.
// ─── Figma component properties ──────────────────────────────────────────────
//
// A CoUI widget's composition slots (`child` / `leading` / `title` / …) accept
// arbitrary widgets. Figma's equivalent is a component property: TEXT for a
// slot a caller fills with words, BOOLEAN for one it either shows or doesn't,
// INSTANCE_SWAP for one it fills with another component. Without them a
// generated component is a fixed picture — a designer can edit the copy by
// double-clicking into it, but nothing declares that the copy is a *slot*, and
// nothing lets them swap the icon for a different one.
//
// Properties live on the COMPONENT_SET when there is one, and on the COMPONENT
// when it stands alone — `addComponentProperty` on a set member throws.

// Adds a property and returns its id, or null when this owner already has one
// by that name (a set's members share the owner, so the second variant through
// a loop must reuse rather than re-add).

// Points a node's own field at a property. `characters` for text, `visible`
// for boolean, `mainComponent` for an instance swap — Figma rejects any other
// pairing, which is why the three are separate functions rather than one with
// a field argument a caller could get wrong.
// The `Icon` component variant's node id, for an INSTANCE_SWAP default.
//
// Read off the COMPONENT, never off an instance: `manifest.json` sets
// `documentAccess: "dynamic-page"`, which makes `InstanceNode.mainComponent`
// write-only — reading it throws `Cannot call with documentAccess:
// dynamic-page. Use node.getMainComponentAsync instead`, and a builder is
// synchronous so it cannot await that. The main component is already in hand
// here (the Icon set is a page child), so there is nothing to read back.
//
// An empty string when the glyph is absent: `defineProp` still declares the
// property, so the slot shows in the panel as swappable with no default,
// rather than the whole entry failing over a missing default and leaving a
// half-built component on the page.

// Each adds ONE field to whatever the node already carries, rather than
// replacing the whole record. A node can be the target of two properties at
// once — an optional text slot is driven by a BOOLEAN through `visible` and a
// TEXT through `characters` — and assigning a fresh object for the second one
// dropped the first, leaving a definition in the panel wired to nothing.
//
// Explicit field copy rather than object spread: the plugin runtime rejects
// `...` (see this file's header).




// Turns on a composed instance's optional slot and points its swap at an icon.
//
// The library's convention is a pair per slot: a BOOLEAN named `Show <slot>`
// and an INSTANCE_SWAP named `<Slot>`. Two builders grew their own copies of
// this loop against a slot naming that no longer exists — one looked for a
// BOOLEAN literally named `leading` and a swap named `leading icon` — so the
// patch came out empty, `setProperties` was never called, and Carousel's
// prev/next rendered as two identical glyph-less circles. Nothing failed: an
// empty patch is a legal no-op, and the harness counts the call that never
// happened as a call that had nothing to do.
//
// Matching lives here, once, so a rename in the child's builder breaks one
// place instead of silently emptying every caller's patch. Both halves are
// optional — a slot with no swap still gets revealed, and an unknown slot
// produces no patch at all rather than a wrong one.
//
// Never writes `.visible` on a descendant as a fallback. A node bound to a
// property is driven by that property; assigning around it is the exact way
// the Select trigger lost its chevron once already.

// Surfaces a composed instance's own properties on the parent's panel.
//
// Deferred on purpose. Figma rejects `isExposedInstance = true` on an instance
// with no COMPONENT ancestor ("Instance must be contained within a component or
// component set to be exposed"), and the instance usually is not there yet at
// the moment a helper mints it — the helper returns it, the caller appends it,
// and something further up appends THAT. Six sites wrote the flag where the
// instance was created, and five components failed in the real Figma file
// while the harness reported 143/143 (the double had no accessor, so a plain
// assignment always succeeded).
//
// So callers collect and flush: push during construction, call this once the
// root is assembled. Same shape as `display.ts`'s `SlotPair`, and for the same
// reason — the moment the write is legal is later than the moment it is known.

// An instance of a REGISTRY component already on the page.
//
// Throws rather than returning null: a builder that composes a child needs it,
// and a silent null would produce a component missing a whole region while
// every other signal stayed green. Declare `needs: ['<Name>']` on the REGISTRY
// entry so `topoSortRegistry` builds the child first.
// The variant of `setName` that best matches `prefs`, by name.
//
// Why "best" and not "exact": a child set's axis vocabulary grows. Button had
// `Variant, Size`; it now also has `Selected, Hover, Disabled`. A parent that
// spelled the full name would break on the next axis added, and a parent that
// passed no name at all got the set's FIRST variant — which is how a banner
// whose widget documents an outline action ended up showing a filled primary
// pill. Scoring lets the parent state only the axes it cares about.
//
// A requested axis the child does not have scores nothing, so a renamed or
// removed axis degrades to "ignored" rather than to a wrong match on the axes
// that do still exist. That is deliberate: the alternative — throwing — would
// fail the parent's entry over a child's refactor and leave the parent
// half-drawn on the canvas until the next run blanks it.

// Suppresses a composed field instance's own chrome from a chromeless style.
//
// A component that puts a `TextField` inside its own bordered box owns the single
// visible boundary, and the widgets say so by forwarding a chromeless
// `CoreTextFieldStyle` into the field. On a canvas the composed INSTANCE arrives
// with the field's own border and fill instead, and the result is a field drawn
// inside a field — a second rounded outline sitting inside the first. Both
// `PhoneInput` and `ChipInput` were in that state.
//
// Driven by the style rather than by a literal `transparent`: the values come from
// the const the widget actually forwards, so a designer who gives inner fields a
// hairline gets one here too, and a reader can see WHERE the transparency is
// decided. The alpha test is `argb` 0 — that is what `CoreColor.transparent`
// exports (`opacity` stays 1, and a consumer combines both).
//
// Every write is an ordinary instance override. The walk tolerates finding
// nothing: if `TextField` ever stops drawing its own boundary this leaves the
// instance alone rather than throwing and leaving the host half-drawn.

// Whether a colour leaf is the transparent sentinel — no token, alpha byte 0.

// The text a composed child draws ITSELF — its own subtree, stopping at any
// further-nested instance.
//
// The distinction is the whole reason this is not `findAll(TEXT)`: `Chip`
// composes a `Button` for its close affordance, so a blind walk reaches that
// Button's own label placeholder too and restyles it. A parent's `labelStyle`
// does not address a grandchild's text — `chipStyle.closeButtonStyle` is a
// `CoreButtonStyle` carrying colour and box size and NO typography, and in the
// widget that slot holds an icon rather than text at all. Descending would put a
// size on a node no forwarded style states, which the set-based readback cannot
// tell apart from the correct one.
//
// Walked rather than read off `children` so a child that wraps its label in a
// frame is still reached.
// `Expanded(child: Align(centerStart, child: label))` — the branch a composed
// `Button` takes once a leading or trailing slot is on (`button.dart:358-364`),
// as against the slot-less branch's `Align(alignment ?? center)`.
//
// It matters only on a row STRETCHED past its content: the `Button` component's
// own frame hugs its label, so centre and start are the same picture there. A menu
// or select row filling its panel has the slack, and centred is what it showed —
// labels floating mid-panel in lists both apps left-align, with the trailing mark
// tucked against the words instead of at the far edge.
//
// One door, because three builders make the same statement and a fourth will: the
// label expands, so whatever follows it end-aligns.


// A named descendant of a composed instance.
//
// By name, and that is the least bad of the three ways to reach into `TextField`
// from outside it. Position breaks the moment a slot is added ahead of the one
// wanted; `componentPropertyReferences` would be the real handle but an
// instance's sublayers do not carry it in either test double, so a lookup
// through it would find nothing here and throw on a canvas that is fine. The
// names are `autoFrame`'s own literals in `form.ts` and both doubles copy them
// onto the clone, so this resolves identically in the harnesses and in Figma —
// and a rename over there lands here as one loudly failing entry rather than as
// a segment that quietly stops being centred.

// The two node names inside a composed `TextField`'s input stack. Named here
// because `revealValueOverPlaceholder` below is the only thing that needs them
// and it now serves every consumer, not just the pickers.
// The `field` row inside a `TextField` instance — the node its border, fill and
// inset live on (the instance root is the label column above it).

// The half of "this field has a value" that is layout rather than properties:
// the value into flow so the stack hugs it, the placeholder hidden because the
// widget has none. Both or neither — hiding alone collapses the stack, flowing
// alone leaves two strings.
//
// Walked from each frame rather than filtered by `parent` identity: a test double
// hands children back through a Proxy, so `child.parent === holder` is false
// there while being true in Figma — a comparison that would move nothing in the
// harness and everything on the canvas.
// The placeholder's ink, for a parent that states it. `hintText` is a caller
// string and its colour is a caller field, so a composed field arrives showing
// its OWN placeholder colour — right whenever the two agree and silently wrong
// the moment a parent overrides it.
//
// Paints every TEXT child of the input stack rather than one by name, for the
// reason `revealValueOverPlaceholder` hides them the same way: the placeholder is
// unnamed and the count is the shape assertion. Loud when it finds none — a
// parent that states a placeholder colour and finds no placeholder is a parent
// whose composed field changed shape.


// A forwarded typography slot applied to a composed instance's text.
//
// Where a parent hands a child a whole `CoreTextStyle` — `CoreChipInputStyle`'s
// `chipStyle.labelStyle` reaches the composed `Chip` as `chipStyle:
// resolved.chipStyle` — the child renders at the PARENT's size and weight, not
// at its own size step's. Size / weight / line-height / fill on a text node are
// all overridable inside an instance (children are not), so this is that forward
// expressed in Figma — the same move `bindInstanceRadius` above makes for a
// forwarded radius, and not a second copy of the child's recipe.
//
// Each facet is written only where the style states it, because a nested slot is
// a PARTIAL forward: `defaultChipStyle.merge(chipStyle)` sets some fields and
// leaves the rest to the child's own resolver. Writing an absent facet would
// replace a correct value of the child's with a fallback of ours — the same
// class of bug as the literal it removes, one level down.

// A forwarded `CoreButtonStyle` applied to a composed `Button` instance.
//
// A parent that composes a `Button` hands it a whole style slot —
// `Alert(closeButtonStyle:)`, `Drawer`, `Toast`, `Fab(actionButtonStyle:)`,
// `TextField(featureButtonStyle:)`, `Chip(closeButtonStyle:)`. On the canvas the
// instance arrives with `Button`'s own size-row chrome instead, and the parent's
// forward reaches nothing: an affordance sized for a 12+12 button row rather than
// for the glyph it holds, at the child's corner radius rather than the parent's.
//
// Eight of these were confirmed by audit, in six different builders, each having
// written some subset of the writes by hand. This is the whole subset, once — the
// same reasoning as `hostedDivider`: an operation that takes several writes and is
// applied in several places gets one door, or it gets applied halfway.
//
// Each facet is written only where the forwarded style STATES it, because a
// nested slot is a partial: `defaultCloseButtonStyle.merge(override)` sets some
// fields and leaves the rest to `Button`'s own resolver. Writing an absent facet
// would replace a correct value of the child's with a fallback of ours.


// `Color.opacity × factor` — the plugin-side twin of `CoreColor.scaleAlpha`,
// which is how every resolver in coui_flutter combines a token colour with a
// separately-stated alpha (`focus_outline_style.dart#L85-91` for the ring,
// `progress_style.dart#L87-92` for the track, `skeleton.dart#L229-231` for the
// pulse). Written out rather than spread: the Figma plugin runtime rejects
// `...` in an object literal (see `helpers.ts#solid`).

// The primary ring the composed `FocusOutline` paints when a component is
// focused, as a rectangle positioned just outside the component's own bounds.
//
// This node IS that composed widget's chrome, not a lookalike: `badge.dart`
// wraps its box in `FocusOutline(focused:, focusOutlineStyle:
// resolved.focusOutlineStyle, child: badge)`, and `card.dart` reaches the same
// ring one level down (`Clickable(clickableStyle: resolved.clickableStyle)`,
// whose `focusOutlineStyle` is what `Clickable` hands its own `FocusOutline`).
// Either way the colour below comes from that slot and nowhere else.
//
// It is drawn rather than instantiated because `FocusOutline` WRAPS its child,
// and a Figma instance cannot take appended children — instantiating it would
// put the component inside a box it cannot enter, and surface `FocusOutline`'s
// own slot placeholder on top of the badge. Same call the Fab / Filter /
// NavigationMenu builders make for the same reason.
//
// Absolute rather than a stroke on the component itself: a card's `outlined`
// variant already owns its border, and repainting that border in the focus
// colour would replace information the variant is there to show. Absolute also
// keeps the ring out of the auto-layout it is drawn around, which is why it is
// appended first and switched to `ABSOLUTE` after — Figma rejects the
// assignment on a node whose parent is not (yet) an auto-layout frame.
//
// The ring reuses the component's OWN radius token instead of
// `radius + align`: that sum is not guaranteed to be a step on the radius
// ladder — Badge's pill is `radius/9999`, and `9999 + 4` has no Variable, so
// `lk.radius` would throw `variable not found`, and nothing rolls that throw
// back: the entry is reported as failed and the half-drawn component stays on
// the page until the next run blanks it. At a 4px offset the curvature
// difference is invisible — and so is a component that stopped mid-build,
// which is the more expensive kind of invisible.
// The stroke's alpha is `borderColor.opacity × ringOpacity`, because that is
// the one place the widget combines them: `focus_outline_style.dart#L85-91`
// resolves `(borderColor).scaleAlpha(ringOpacity)` and says in its own comment
// that this is the single site, so a ring painted from `borderColor` alone
// drops a multiplier the data states. Both are 1 today, which is exactly why it
// went unnoticed — the drop is invisible until someone dims the ring in Core
// and only Figma stays bright.
//
// Public and here rather than private to one builder, because two others were
// drawing the ring from its COLOUR alone — `borderData(node, lk, ringColor)` —
// so the stated width, the offset band and `ringOpacity` reached nothing. Both had
// the whole recipe in hand and wrote a third of it, which is exactly the state a
// shared helper exists to make unrepresentable.

// A forwarded panel style applied to a composed panel instance (`Popup`, `Menu`,
// `WindowPanel`, `Drawer` …).
//
// A component that opens a floating surface composes the component that DRAWS that
// surface and forwards a style into it — `Popover(panelStyle:)`,
// `NavigationMenu(panelStyle:)`, `Menubar(menuPanelStyle:)`,
// `Window(panelStyle:)`. On the canvas the instance keeps the child's own inset,
// corner and minimum width, so the parent's forward reaches nothing: a panel at
// `Popup`'s padding rather than the one the parent states.
//
// Five of these were confirmed by audit, in four builders. One helper for the same
// reason `applyForwardedButtonStyle` and `hostedDivider` are one: three or four
// writes applied in several places get applied halfway.
//
// Partial by construction — only what the forwarded style STATES is written, so a
// field the parent leaves null keeps the child's own resolved value instead of a
// fallback invented here.

// A `Divider` instance dropped into a host's own column or row — created,
// parented, stretched, and its inner line stretched with it.
//
// One function because the operation is not one write. `Divider`'s root hugs and
// its line is built at a fixed length (200 unlabelled, 90 per segment), so an
// instance set to FILL stretches the ROOT while the line stays where it was
// built: the rule visibly stops short of the box it separates. Both writes are
// needed and neither is sufficient, which is exactly the shape that gets
// half-applied — of seven call sites, three stretched the instance and left the
// line, and one did neither. That is the "Separator 가 너비가 덜 차있다" report,
// and it named the components those four sites are in.
//
// The colour is guarded rather than passed straight to `fillData`, which clears
// the fills for a null `ColorData` — on a hairline that reads as no rule at all,
// so an absent field must leave the child's own paint alone.
//
// Not a resize: `_DividerLine` is `Container(width: double.infinity, height:
// thickness)`, so the line's length IS its parent's content width. A number
// written at a call site is that width spelled a second time (it was
// `280 − 16 − 16` at one of them) and it goes stale the moment the host's width
// or padding moves.
//
// The RECTANGLE walk tolerates finding nothing: if the child ever stops drawing
// one, the rule keeps its preview length instead of throwing and leaving the
// whole host half-drawn on the page.

// The parts of a forwarded `CoreDividerStyle` that are the LINE's, applied after
// the sizing above so a stated thickness wins over the instance's own.
//
// `indent` / `endIndent` inset the rule from its host's two ends. Zero on both is
// the common case and is bound rather than skipped — an unbound 0 and a stated 0
// look the same on the canvas, and only one says where the number came from.

// The main component's `id` for an INSTANCE_SWAP default, by name.
//
// Same lookup as `instanceOf` — deliberately, because they answer the same
// question and five copies of this had drifted from it. Each of `display.ts`,
// `display-data.ts`, `display-media.ts`, `form-fields.ts` and
// `primitives-data.ts` carried its own page-local version, so `instanceOf` found
// the child through the document index and this did not:
//
//   mainIdOf('TextField', …): not on the page. `instanceOf` looks the same name up
//   the same way, so reaching this without it having thrown first means the two
//   disagree.
//
// That message was written as an impossibility. It printed, because they were two
// implementations of one idea. Now there is one.



// #4021 (B1) — document-wide mint-by-name. The lookup used to be scoped to
// the single 🧩 Components page; component-per-page (B2) needs a node to be
// findable wherever it currently lives, or the first multi-page run would
// re-mint every component under a new key. generate.ts builds the index
// once per run (every page loaded) and installs it here; when no index is
// installed (selftest harness, palette generator) the original same-page
// lookup below is the behavior, unchanged.

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
// Duplicate names warn and first-in-document-order wins: mint-by-name's identity
// model assumes unique names, and G2 guards the REGISTRY side of that assumption.



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

// Single-component builders: reuse the existing `name`d COMPONENT if one
// exists anywhere in the document index (falling back to the given page's
// children when no index is installed), reset to blank first — otherwise
// mint a brand new one. Either way the caller gets back an empty node and
// populates it exactly as before.

// ─── Component properties (#4099 / D-25) ────────────────────────────────────
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

// Variant-set builders. Usage:
//   const mount = mountSet(page, 'Badge', allExpectedVariantNames);
//   for (...) { const comp = mount.getOrCreate('Variant=x, Size=y'); ...populate comp... }
//   const set = mount.finish();
//   layoutSet(set, 520); // caller still applies its own layout after finish()



// ─── Paint + fills/strokes ───────────────────────────────────────────────────

/**
 * "This element at N%" — node opacity over a BOUND fill.
 *
 * The one thing a paint cannot do below alpha 1 (a bound colour overwrites the
 * paint's alpha), a node can: Figma multiplies the whole layer, so a rect whose
 * fill is `Semantic/color/info` at `opacity = 0.1` renders the same pixels a 10%
 * fill would and still SHOWS the token. That is the difference that matters — a
 * literal renders right and reads as a hex, which is the bypass this pipeline
 * exists to remove.
 *
 * Only for a node with nothing inside it that must stay full strength: node
 * opacity dims every descendant, which is the whole reason `tintLayer` exists.
 */

/**
 * The same statement for a node that HAS children: the tint gets its own layer.
 *
 * A container's 10% background cannot be node opacity — the words on top would
 * fade with it — and cannot be a sub-1 bound paint. So it becomes what it already
 * is in both apps: a fill that is not the content's. A rect pinned to the host's
 * bounds, behind everything, bound to the token, faded to the stated alpha.
 *
 * `Card` already draws its surface this way (an `OutlinedContainer` instance
 * pinned behind the content), so this is the shape the repo reaches for when a
 * surface and its content are separate things.
 */

/** Tint layers awaiting their host's final size — see `tintLayer`. */

/**
 * Gives every tint layer the size its host settled at. Called once per REGISTRY
 * entry, after `build` returns — by `generate.ts` and by both harnesses, which is
 * why `check_tint_flush.py` requires the call in each driver: a driver that forgets
 * it draws every tint at the size its frame had before it had any content.
 */

/**
 * Whether a node can hold children AT ALL — the question that decides which of
 * the two routes a sub-1 tint takes.
 *
 * Asked of the TYPE and not of `children.length`, because a builder paints a frame
 * and appends to it afterwards: a count read at paint time would say "no children"
 * about a container that is about to have five, and the tint would fade them.
 */

/**
 * Whether a node lives inside an instance — where a tint LAYER is not available at
 * all: Figma refuses both a new child in an instance subtree and the `constraints`
 * that would pin it.
 *
 * There the node's own opacity is the only expression left, and it is applied
 * knowing what it costs (the node's descendants fade with it). That is a
 * composed part being tinted from outside, so the part is what fades — the
 * alternative is a paint that renders at full strength, which is the defect this
 * whole path exists to remove.
 */


// Solid fill from a Semantic color name.

// Border from a Semantic color name + stroke width bound to a stroke token.

// ─── Shadow ──────────────────────────────────────────────────────────────────

// One layer of a `CoreShadowLayer` list, as `components.json` now carries it.


// Paint a node's elevation from a `CoreShadow` step.
//
// Until this existed nothing in the plugin ever wrote `node.effects`, so every
// card, popup, dialog, drawer, toast and fab on the canvas was flat while its
// Dart Style declared a shadow. That is the failure this whole pass keeps
// finding: the value was correct in Core, no guard was red, and the only way
// to notice was to look at Figma next to the app.
//
// A `CoreShadowLayer` carries geometry and a per-layer opacity but no colour.
// Eight of the eleven components that declare a shadow pair it with a
// `shadowBaseColor` / `shadowColor` field, and Flutter's resolver tints the
// stack with it (`shadowBoxShadow.toValue(base: shadowBase, …)`) — so `base`
// is that field, not a choice made here. Black is the fallback for the three
// with no such field, which is what an untinted `BoxShadow` is.
//
// The colour is bound to its Semantic Variable when it has one, so a shadow
// retints with the theme the same way a fill does. A raw colour is painted
// literally; the alpha it carries is multiplied by the layer's own opacity,
// the same combination `fillData` makes.
//
// ─── Why the binding is conditional on the alpha ────────────────────────────
//
// A shadow's alpha is the whole of what makes it read as a shadow, and on an
// effect there is exactly ONE place to put it. Compare the two Figma types:
//
//   SolidPaint  { color: RGB;  opacity?: number }   ← two slots
//   DropShadowEffect { color: RGBA }                ← one slot, alpha inside
//
// and `VariableBindableEffectField` is `'color' | 'radius' | 'spread' |
// 'offsetX' | 'offsetY'` — there is no `opacity` field to bind or to set
// beside it. So a variable bound to `color` supplies the alpha too, and the
// alpha computed below is discarded. `Semantic/color/shadow` aliases
// `pure-black` / `pure-white` at full opacity, so every shadow with a
// Semantic base rendered SOLID: WindowPanel's two layers are `opacity: 1`
// with the 10% living on `shadowColor`, and both painted at 100%. Popup,
// Dialog, Drawer, DraggablePanel and the picker panels were the same story at
// 4–8%. The two that looked right (Fab, Toast) are the two whose base carries
// no `ref`, so nothing was ever bound over their alpha.
//
// `solid()` above is the same problem already solved on the paint side —
// `setBoundVariableForPaint` then `Object.assign({}, p, { opacity })`, because
// a paint HAS the second slot. An effect does not, so the alpha and the
// binding cannot both be expressed and one has to win.
//
// The alpha wins, and only where the two actually conflict: bind when the
// resolved alpha is 1 (nothing to lose), paint literally when it is not. What
// that costs is the theme retint on the shadows that go literal — `shadow`
// resolves to black in light and white in dark, and the literal keeps the
// light-mode hue. That is a 4–10% black shadow staying black on a dark canvas,
// against the alternative of a 100% opaque one in BOTH modes. Recorded rather
// than hidden: the fix that would cost neither is a variable whose own value
// carries the alpha, which is a token-side change, not a builder-side one.
//
// An empty layer list clears the effects rather than leaving whatever was
// there. `CoreShadow.none` is a decision ("this surface is flat"), and on a
// re-run over a persistent node the previous run's shadow is still attached —
// skipping the empty case would make "none" mean "keep the old one".

// ─── Data-driven color application (coui_core defaults) ──────────────────────

// A color descriptor from components.json: a Semantic variable name + opacity,
// a raw literal (color === null + argb), or transparent/unset.

// A stated colour re-alpha'd by a stated alpha field — `withValues(alpha:)`,
// which REPLACES the channel rather than multiplying it. Returns null for an
// absent colour so a caller hands `fillData`/`textLabelOpts` the same "nothing
// stated" it would have had.
//
// Public and here rather than private to one builder file, because the choice it
// encodes is repo-wide: an alpha that names a COLOUR belongs on that colour, on
// every platform. The alternative — dimming the node — looks identical whenever
// the node holds one painted thing, and stops being identical the moment it
// holds two. Four resolvers and one builder had drifted onto the node.
export function withAlpha(
  cd: ColorData | null,
  alpha: number | { v: number },
): ColorData | null {
  if (cd == null) return null;
  const a = typeof alpha === 'number' ? alpha : alpha.v;
  return { color: cd.color, argb: cd.argb, opacity: a };
}

// Paint a node's fill from a ColorData. null/transparent → no fill. A semantic
// `color` always binds the Variable, and below alpha 1 the alpha moves to a LAYER
// rather than to the paint (see `paintTokenFill`) — a bound colour supplies its own
// alpha and would overwrite the paint's. A raw `argb` paints literally either way
// (RGB + its own alpha byte, combined with `opacity` per the v2 formula), because a
// value with no token has no Variable to keep.

/**
 * A token fill at any alpha, with the token still on the layer.
 *
 * At full strength this is just a bound paint. Below it, the paint cannot carry the
 * alpha (a bound colour overwrites it), so the alpha moves to a LAYER — this node
 * when it cannot hold children, its own tint rect when it can.
 */

/** A node's current uniform corner, so a tint layer follows the box it fills. */


// Border from a ColorData + stroke-token width. null/transparent → no border.
// Union-fix #2 (#3753): previously `if (!cd || cd.color == null) return;`
// silently dropped every raw-literal (`argb`-only, no `color`) border — the
// same shape `fillData` already handled correctly two lines above.
// A `Core…BorderStyle` choice → Figma's dash pattern, applied to a node whose
// stroke is already set.
//
// Four members and only two of them are a pattern: `solid` has none, `none` has
// no stroke at all. The two enums that carry this (`CoreFrameBorderStyle`,
// `CoreOutlinedContainerBorderStyle`) name the same four, and both stated
// `solid` by default — which is how `Frame` came to write a dash pattern
// unconditionally: the pattern was there, the choice was not, so the canvas
// dashed a border the widget draws solid. It only failed to show because that
// builder sets no stroke either; the moment one arrives the dashes would.
//
// `dotted` uses the dash length as its dot length, because that is all Core
// states — a separate dot length would be a number invented here.
export function applyBorderStyle(
  node: SceneNode & MinimalStrokesMixin,
  choice: string,
  dashLength: number,
  dashSpacing: number,
): void {
  if (choice === 'none') {
    node.strokes = [];
    node.dashPattern = [];
    return;
  }
  node.dashPattern = choice === 'dashed' || choice === 'dotted'
    ? [dashLength, dashSpacing]
    : [];
}


// LabelOpts color fields from a ColorData (semantic var, raw literal, or
// fallback). Union-fix #3 (#3753): the raw-literal branch used to hardcode
// `whiteFill: true` regardless of the actual `argb` value — faithful only
// by coincidence (coui_core's one caller of this path happens to be
// literal white). `rawColor` carries the real RGB + alpha instead.
export function labelColor(lk: VarLookup, cd: ColorData | null | undefined): LabelOpts {
  if (cd && cd.color != null) {
    // `argb` travels with the token for the reason `colorData` keeps it: below
    // alpha 1 the paint cannot be bound, and this is the only literal available to
    // paint it with.
    return { size: 0, colorVar: lk.sem(cd.color), opacity: cd.opacity, argb: cd.argb };
  }
  if (cd && cd.argb != null) {
    return { size: 0, rawColor: argbToRgb(cd.argb), opacity: argbAlpha(cd.argb, cd.opacity) };
  }
  return { size: 0, colorVar: lk.sem('on-surface') };
}

// A resolved CoreTextStyle from components.json: fontSize + fontWeight +
// lineHeight (+ own text color, which may be null — the component's
// foreground then applies).
export interface TextStyleData {
  fontSize: number | null;
  fontWeight: number | null;
  lineHeight: number | null;
  color: ColorData | null;
  /** See `NormalizedTextStyle.role` — optional so a hand-built style
   *  (a glyph, mockup copy) still type-checks without one. */
  role?: string | null;
  letterSpacing?: number | null;
  /** See `NormalizedTextStyle.fontFamily` — the role's family. */
  fontFamily?: string | null;
  /** See `NormalizedTextStyle.lineHeightPx` — a fixed line box in px. */
  lineHeightPx?: number | null;
}

// Pretendard's 9 static weights, keyed by the same CSS font-weight numbers
// `CoreFontWeight` uses (packages/coui_core/lib/src/typography/font_weight.dart).
// `loadFonts()` preloads every one of these, so this is an exact lookup, not
// a collapse onto a smaller subset. An unmapped weight (shouldn't occur —
// every fontWeight this plugin sees comes from a `CoreFontWeight` constant)
// falls back to Regular rather than throwing, since it carries no chrome
// risk of its own.


// CoreLineHeight is a unitless multiplier (1.4, 1.6, …); Figma's TextNode
// wants PERCENT (140, 160, …).
function lineHeightPercent(lineHeight: number | null): number | undefined {
  return lineHeight == null ? undefined : lineHeight * 100;
}

// Build LabelOpts (size + style + line-height + color) from a TextStyleData.
// The style's own color wins; when null, `fallbackColor` (e.g. the
// component foreground) is used.
export function textLabelOpts(
  lk: VarLookup,
  ts: TextStyleData,
  fallbackColor?: ColorData | null,
): LabelOpts {
  const cd = ts.color != null ? ts.color : fallbackColor;
  const o = labelColor(lk, cd);
  applyTypography(o, ts);
  return o;
}

// Size, face, line height and the role, written the same way by both opts
// builders.
//
// A field the style leaves unstated is the ROLE's, not a default, so it is
// filled from the scale before anything is written: the label then draws the
// role, and `makeLabel` — which sees only the opts — judges the same numbers
// `applyRole` judged. `textStyleData` already fills every exported style this
// way; this covers a style built by hand (`{ role: 'headlineLarge' }` alone
// would otherwise draw at 14 in Regular and lose its role at the second
// judgement). A role-less style keeps the plain defaults: 14, Regular, 160%.
//
// A code role arrives as the role states it — monospace, on its 21px box. The
// family is the role's own (a family a component overlays is not drawn, see
// `textStyleData`), and the box follows `CoreTextStyle`: a line height stated
// over it without a box replaces it.
function applyTypography(o: LabelOpts, ts: TextStyleData): void {
  const metrics = ts.role == null ? undefined : roleMetrics(ts.role);
  const filled: TextStyleData = {
    ...ts,
    fontSize: ts.fontSize ?? metrics?.fontSize ?? null,
    fontWeight: ts.fontWeight ?? metrics?.fontWeight ?? null,
    lineHeight: ts.lineHeight ?? metrics?.lineHeight ?? null,
    letterSpacing: ts.letterSpacing ?? metrics?.letterSpacing ?? null,
    fontFamily: ts.role == null ? ts.fontFamily ?? null : metrics?.fontFamily ?? null,
    lineHeightPx: lineBoxAfter(ts.lineHeight, ts.lineHeightPx, metrics?.lineHeightPx),
  };
  o.size = filled.fontSize == null ? 14 : filled.fontSize;
  o.style = weightStyle(filled.fontWeight);
  o.lineHeightPercent = lineHeightPercent(filled.lineHeight);
  if (filled.lineHeightPx != null) o.lineHeightPx = filled.lineHeightPx;
  const family = familyTokenOf(filled.fontFamily);
  if (family !== 'sans') o.family = family;
  applyRole(o, filled);
}

// The role and its letter-spacing travel with the metrics so `makeLabel`
// can bind the SEMANTIC typography variables (`font-size/label-large`,
// `letter-spacing/label-large`) instead of the primitive step the number
// happens to sit on. Both opts builders go through here so neither can
// forget the half the other carries.
//
// **A field that departs from the role drops the role** — size, weight, line
// height or tracking; `roleDeparture` (text-nodes.ts) is the one test, and
// `makeLabel` puts it again to the opts it is handed.
//
// Size was the first. The role's variable is what Figma binds `fontSize` to,
// and a bound variable OVERWRITES the literal the builder just set — so a
// style that says "`bodySmall`, but 10px on this rung" rendered at the role's
// own size on every rung, silently, while the number the code stated reached no
// node at all. That is exactly the shape of a size ladder written as a
// per-size `fontSize` overlay on a role-bearing flat default
// (`CoreTextStyle(fontSize: CoreFontSize.s10)` merged onto
// `CoreTextStyle.token(bodySmall)`), which is how Checkbox · RadioGroup · Chip
// state theirs — the canvas drew one size for six rungs until the designer's
// own copy was held next to it.
//
// The other fields fail the same way one step later: a kept role queues the
// role's text style, and attaching it writes the role's weight, line height
// and tracking over the label's. Steps' indicator digit (`labelLarge` at 700)
// came out of the attach at the role's 500, TextField's 140% value text at the
// role's 150%. Nothing written back after the attach can keep the style — the
// reason is on `roleDeparture` — so the role goes before it is queued.
//
// Dropping the role also drops the letter-spacing binding, and for a size
// departure it must: that variable holds PIXELS computed for the role's size
// (−0.14 at 14), so binding it to a 10px label states a ratio nobody chose.
// The role's em ratio stays — `applyTypography` filled it — and is re-applied
// to the size that actually renders, which is what `makeLabel` does with
// `letterSpacingEm`.
function applyRole(o: LabelOpts, ts: TextStyleData): void {
  if (
    ts.role != null &&
    roleDeparture(ts.role, {
      size: dimVal(o.size),
      style: o.style,
      lineHeightPercent: o.lineHeightPercent,
      lineHeightPx: o.lineHeightPx,
      letterSpacingEm: ts.letterSpacing,
      family: o.family ?? 'sans',
    }) == null
  ) {
    o.role = ts.role;
  }
  if (ts.letterSpacing != null) o.letterSpacingEm = ts.letterSpacing;
}

// Like textLabelOpts but `colorData` ALWAYS wins (the style supplies only
// size/weight/line-height). Use when a state — not the typography slot —
// decides the color (e.g. a disabled checkbox/radio/toggle label uses
// disabledForeground).
export function typographyColorOpts(
  lk: VarLookup,
  ts: TextStyleData,
  colorData: ColorData | null,
): LabelOpts {
  const o = labelColor(lk, colorData);
  applyTypography(o, ts);
  return o;
}

// LabelOpts from a ColorData with an explicit size (for glyphs like the
// checkmark, whose size is a dimensional token, not a typography role).
// `sizeScale` (#3754 axis fix) — a glyph's size can trace to `CoreSize`/
// `CoreIconSize` (a dimensional-scale token) even though it's *rendered*
// as a text character; passing `'size'` binds `makeLabel`'s `fontSize`
// field to `Primitives/size/<n>` instead of the default
// `Primitives/font-size/<n>`. Figma doesn't care which named collection a
// bound Variable comes from — `fontSize` is just a numeric node field —
// so this binds the glyph to the scale its value actually traces to
// (checkbox's `checkmarkSize` and alert's `iconStyle.size` both route
// through `CoreSize`/`CoreIconSize` in schema v2's `via` provenance, never
// `CoreFontSize`; binding via `lk.fontSize()` only "worked" because the
// two scales happen to share values at 12/16 — the exact bug this
// parameter fixes).
export function glyphOpts(
  lk: VarLookup,
  cd: ColorData | null,
  size: number | Dim,
  sizeScale?: 'fontSize' | 'size',
): LabelOpts {
  const o = labelColor(lk, cd);
  o.size = size;
  if (sizeScale) o.sizeScale = sizeScale;
  return o;
}

// ─── Text ────────────────────────────────────────────────────────────────────


// h160 (1.6) — the default for ad-hoc/glyph text (icons, mockup copy) that
// carries no `TextStyleData` role to read a real line-height from. It is a
// plain fallback, not any role's value: the scale's own lines are 1.4 (labels,
// titles, headlines, display) and 1.5 (body). Role-driven text
// (`textLabelOpts` / `typographyColorOpts`) always supplies `lineHeightPercent`
// explicitly instead.

// CoUI renders with `CoreFontFamily.sans` (Pretendard, read from the
// font-family/sans token — never hardcoded here).
// ─── Lucide icon nodes ───────────────────────────────────────────────────────

// Path data generated from the vendored Iconify set by `npm run gen:icons`.
// Keyed by kebab-case Lucide name (`'chevron-down'`), the same identity the
// widgets name in camelCase (`LucideIcons.chevronDown`).


// A real Lucide glyph as vector nodes, replacing the text characters the
// builders used to stand in with (`'✕'` for `x`, `'☰'` for `grip-vertical`).
//
// Why this matters beyond looks: a designer who copies a component out of the
// library gets whatever is inside it. A text glyph carries a font dependency
// and a shape that only approximates the icon the code renders — the ✕ that
// stood in for `x` is a different mark at a different weight, and `☰` is not
// `grip-vertical` at all. It also cannot be swapped for the real icon by
// selecting it, because it is a character, not an instance.
//
// Lucide strokes with `currentColor`, which Figma resolves to black on import,
// so every stroke and fill is re-pointed at the requested color afterwards.
// Every glyph name `icons.json` carries — the `Icon` component's variant list.

// Paints one glyph's vectors into an already-obtained node. Used by the `Icon`
// component's builder to fill each variant; use sites go through `makeIcon`,
// which returns an instance of that component instead.


// Node types that HAVE an interior, i.e. the ones `IconOpts.fill` may paint.
//
// A container's "interior" is its whole bounding box, so filling one paints a
// solid rectangle over the mark instead of filling it. That is not a
// hypothetical: `makeIcon` hands `repaintGlyph` the icon INSTANCE as its root, and
// the `<svg>` wrapper frame is a DESCENDANT of that root — so it cleared the
// `node !== root` guard and took the fill. Every "filled" star StarRating drew
// was that square, with the real star painted underneath it in the same colour.
//
// A whitelist rather than a container blacklist because the question is about
// the node, not about the ones we happen to know Figma's SVG import produces:
// whatever `createNodeFromSvg` nests, only a shape has a path to fill.

// Lucide strokes with `currentColor`, which Figma resolves to black on import,
// so every stroke and fill is re-pointed at the requested colour. `findAll`
// covers nested `<g>` wrappers — several Lucide icons group their strokes, so
// the paintable nodes are not always direct children.

// An instance of the `Icon` component, coloured and sized for this use site.
//
// Requires the `Icon` component to be on the page already — every builder that
// calls this declares `needs: ['Icon']`, and `topoSortRegistry` guarantees the
// order. Throwing rather than falling back to inline vectors is deliberate: a
// silent fallback would produce a page where some icons are instances and some
// are loose vectors, and nothing would say which.


// ─── Dimension / box binding ─────────────────────────────────────────────────

// A resolved `CoreEdgeInsets` from components.json — physical `l`/`r` for a
// plain inset, or logical `start`/`end` for one built via
// `CoreEdgeInsets.directional` (reading-direction relative, RTL-aware). The
// two shapes are told apart by *key name*, not by an added `directional`
// flag: a flag a consumer forgets to check still compiles and silently
// flattens a logical inset to a physical one, while a `PadData` whose
// `.l`/`.r` a consumer reads without narrowing fails `tsc --strict` (FR-008;
// see `cross-platform/localization.md` on why the flattening is wrong).




// Figma auto-layout only has physical `paddingLeft`/`paddingRight` — there is
// no reading-direction-relative pair to bind instead, so `start`→left /
// `end`→right resolves here and only here. Every `PadData` consumer passes
// its value straight through to this function rather than reading `.l`/`.r`
// itself, which is what makes "the conversion happens in one place"
// (FR-008 AC-2) something `tsc --strict` verifies rather than a convention
// someone has to remember.


// Resize to (w,h) then bind whichever axis matches a size token (so fixed
// dimensions track the Primitives size scale). Use on absolute/FIXED nodes only
// — never on auto-layout HUG/FILL children.
// Binds ONE axis to a token and leaves the other as plain geometry.
//
// `bindSize` binds both, and that is wrong when only one of the two numbers is
// a design value. A scrollbar's thickness comes from the component's Style; the
// length of the demo viewport it sits in does not — it is a preview constant
// this file chose. Passing both to `bindSize` made the canvas assert
// `Primitives/space/96` as the source of that length, so a designer inspecting
// the node saw a design-system claim the design system never made. The numbers
// happened to sit on the space ladder, which is why the binding landed instead
// of being skipped, and why nothing failed.
//
// It also read as clean to the literal ratchet: that guard looks for a digit
// inside the `bindSize(...)` call text, so a named constant hid it.

// `InstanceNode` included for the reason `bindPad` and `bindRadiusN` above take
// one: a composed child's extent is an ordinary instance override, and a parent
// that forwards a `width` / `height` in a `CoreButtonStyle` states it about the
// instance it composed. `Chip`'s close affordance is the case — its size row
// carries `closeButtonStyle.width`, and without this the canvas showed `Button`'s
// own row width instead.

// ─── Common sub-frames ───────────────────────────────────────────────────────

// Square auto-layout-center indicator box (checkbox / radio glyph holder).

// Horizontal [indicator] gap [label] row component chrome — applied to a
// node the caller already obtained (mint()/mountSet().getOrCreate()), never
// creates one itself, so every call site is identity-aware by construction.

// A bare auto-layout frame (no fill) for grouping — vertical by default.

// Chrome (fill / border / radius / padding / gap) applied to a frame or
// component, every value bound to a Variable. All fields optional.


// Chrome auto-layout frame (hug both axes) for nested groups.

// Chrome auto-layout component (hug both axes) applied to a node the caller
// already obtained — never creates one itself. Use for a SET builder's
// per-variant node from mountSet().getOrCreate().

// mint()-backed panelComp — for a top-level single-component builder's root.
/// Absolutely positions `node` inside `host` and pins it with `constraints`.
///
/// Figma refuses `constraints` on an INSTANCE outright —
///
///   in set_constraints: This property cannot be overridden in an instance
///
/// — and the write throws rather than being ignored. Nothing rolls that throw
/// back: the entry is reported as failed and the canvas keeps whatever the
/// builder drew before it — a half-built component that reads as finished. That
/// is how `TimePicker` came out broken while every harness was green: a plain
/// field on the test double accepted the assignment. Four builders were doing
/// it.
///
/// An instance therefore gets a plain frame around it and the frame carries the
/// pin. The frame is sized to the instance and draws nothing, so the picture is
/// unchanged — it exists only to give the constraints somewhere legal to live.
// `ABSOLUTE` is a departure from an auto-layout FLOW, so it is only legal — and
// only meaningful — under a parent that has one. Figma refuses it outright on a
// child of a `layoutMode: 'NONE'` frame:
//
//   in set_layoutPositioning: Can only set layoutPositioning = ABSOLUTE if the
//   parent node has layoutMode !== NONE
//
// And a NONE frame already positions its children by x / y, so the write it
// refuses is the write that would have changed nothing. Two builders pinned into
// one (`ScrollableClient`'s root, `Slider`'s track box) and both threw there,
// each leaving a failed entry and a half-drawn component on its page.
//
// `constraints` are NOT gated the same way: they are how a child of a plain frame
// follows its parent's edges, which is exactly the case this skips the pin in.
/**
 * Sets `layoutPositioning = 'ABSOLUTE'` when — and only when — Figma will accept
 * it: the parent has an auto-layout flow to depart from, and the node does not
 * live inside an instance. Exported because a few pins are written next to their
 * own `x`/`y`/`constraints` rather than through `pinAbsolute`, and the refusal has
 * to be impossible from every door, not just the main one.
 */

/**
 * Nodes whose absolute pin could not be written, for the build summary.
 *
 * Drained per entry by `generate.ts`, which prints the names beside the component
 * that owns them — a skip nothing prints is the same invisible state this exists to
 * end. For a long time that sentence was here and the drain was not: the module
 * imported this list and never read it, so it grew for the whole session and
 * reported nothing.
 */


/// A frame that exists only to hold an instance's pin — sized to the instance,
/// no fill, no clip, so it changes nothing about how the instance reads.


// Lock an auto-layout frame/component to a fixed width while keeping the other
// axis hugging. Call AFTER children are appended.

// ─── Component-set container layouts ─────────────────────────────────────────

// Default arrangement for a variant set whose builder doesn't pick one.
//
// Why this has to exist: `figma.combineAsVariants` does not arrange anything —
// children keep the x/y they had, and a freshly created component is at (0,0).
// So a set with no layout is every variant stacked on the same spot. That was
// invisible while most sets had a single variant, and became visible the moment
// they got real axes: seven sets went from 1 variant to 3–20 and piled up.
//
// A wrap grid rather than a column: 20 variants in one column is 20 × the
// component's height of scrolling, and the whole reason for the axes is to be
// able to *compare* the variants. Column count is `ceil(sqrt(n))`, which keeps
// the block roughly square whatever `n` is.





// ─── Fonts ───────────────────────────────────────────────────────────────────

// All 9 static Pretendard weights `weightStyle()` can resolve to (mirrors
// `FONT_WEIGHT_STYLES` above — every `CoreFontWeight` value has one).

// Loads every weight the typography scale can reference. This runs before
// `generateComponents()`'s per-builder try/catch (`generate.ts`) — i.e.
// outside that catch — because a run touches 100+ text nodes and there
// is no useful partial success if the font itself is missing.
//
// Fails loud, no quiet fallback: a missing weight aborts the whole run here
// with one actionable message, instead of leaving `weightStyle()` to hand a
// builder a style name Figma never loaded — which throws a far less helpful
// "font not loaded" error deep inside that builder's own try/catch.
