/// <reference types="@figma/plugin-typings" />

import { Dim, dimVal } from './compat/v1';
import iconsJson from './data/icons.json';
import iconKeysJson from './data/icon-keys.json';
import { VarLookup } from './variables';
import { findComponentByName, mint } from './identity';
import { fadeNode, fillSem, solid } from './paint';
import { bindRadiusN, bindSize } from './box';
import { defaultSetLayout } from './set-layout';
import { onRedrawNodeKept } from './redraw-keep';
import {
  ContentTone,
  clearContentIndex,
  contentPaintOf,
  noteContentGlyph,
  noteDirectGlyph,
} from './icon-content';

const ICONS = iconsJson as Record<string, { body: string; w: number; h: number }>;

/** Lucide glyph name → published component key in `CoUI Icons — Lucide`. */
export const ICON_KEYS = iconKeysJson as Record<string, string>;

function unknownIconMessage(name: string): string {
  // Loud, not silent: an unknown name would otherwise draw an empty frame,
  // which reads on the canvas as "this component has no icon" — the exact
  // failure the icon work removes. `check_figma_icon_names.sh` fails on a
  // literal; this covers the names that only reach here through indirection.
  return (
    `makeIcon: unknown Lucide name '${name}' — add it to ICON_NAMES in ` +
    'scripts/gen-icons.ts and run `npm run gen:icons && npm run gen:icon-keys`.'
  );
}
// The shapes `repaintGlyph` may put a fill on. One list, read by the one
// recolour walk — there used to be two walks (one here, one in
// form-controls.ts), each with its own unguarded `fills.length > 0` branch,
// and each shipped the same solid-square defect independently.
export const kFillableShapes: readonly string[] = [
  'VECTOR',
  'ELLIPSE',
  'RECTANGLE',
  'POLYGON',
  'STAR',
  'LINE',
  'BOOLEAN_OPERATION',
];

// Lucide glyph nodes.
//
// Icons are drawn from path data rather than a font: a font would need the family
// present in the file, and a designer opening the library on a machine without it
// would see tofu where every icon should be. `ICON_NAMES` is the set the data ships,
// and `makeIcon` composes an instance of the `Icon` component for a name in it.
//
// Split out of `helpers.ts` (see the barrel note there).
export interface IconOpts {
  // Rendered box side in px. The path data is authored in a 24-unit box and
  // rescaled — never resized — because resizing a frame moves its bounds
  // without touching the vectors inside it (the icon would sit in a corner of
  // an empty box at the wrong size).
  size: number | Dim;
  // Semantic color slot name, bound as a Variable so theme switching reaches
  // the icon. `rawColor` paints a literal instead, for the few sites whose
  // color comes from a component field with no token behind it.
  colorVar?: Variable;
  rawColor?: RGB;
  opacity?: number;
  /** The token's literal RGB, for a sub-1 `opacity` — see `solid`. */
  argb?: number;
  // Paint the interior too. Lucide draws with `fill="none"`, so a "filled"
  // state (a solid star vs an outlined one) has no existing fill to recolor —
  // without this the two states would be identical shapes in different
  // stroke colors, and "3 of 5 selected" would not read.
  fill?: boolean;
  // The glyph stands in for a caller-supplied picture — a banner thumbnail, a
  // gallery item — and its side is the SLOT's size, not a rung the Icon
  // set's `Size` axis should have. The rescale is the point, so it is not
  // reported as an inexact icon size: that report is for real icons drawn at
  // a size the axis lacks and whose stroke a rescale would change (a dock
  // glyph at 22), and three placeholders on it sent a reader to git to learn
  // nothing had changed. Declared per call, never per glyph name — `image` is also a real
  // icon on the Dock, and that one should still be reported.
  placeholder?: true;
  // The size is off the `CoreIconSize` ladder because the component's Core
  // style states it so, as a named constant with its reason recorded there —
  // the dock's `sm` glyph (`CoreDockStyle.smIconSize`, 22, kept so the five
  // dock sizes taper 20 · 22 · 24 · 28 · 32 instead of repeating a step). The
  // rescale is a known trade the design decided, not drift, and a warning that
  // repeats on every run buries the real ones, so it is not reported. Set by
  // the caller from the exported constant, never per glyph or per literal, so
  // a different off-ladder size on the same component is still reported.
  statedOffLadder?: true;
  // The `Size=N` variant to instance, instead of the step nearest `size`.
  //
  // For an icon that a parent's INSTANCE_SWAP property will bind — a SLOT
  // icon. The first bind of that property puts the property's DEFAULT in place
  // of the instance's main. On a FIXED axis the box goes back to the default's
  // size. On a FILL axis the box stays, but the glyph inside goes back to the
  // default's own size. Either way a main that is not the default loses what
  // was done to it (measured, #5246 / #5247). An icon drawn from the default
  // variant itself is left alone by that bind, so the box, the glyph and the
  // stroke all stay the code's, and the member reads the same loose and
  // assembled. `iconSwapDefault` (component-props.ts) answers which variant
  // that is. Null falls back to the nearest step.
  //
  // What a slot icon is fitted with is `makeIcon`'s second half: on a side that
  // is a `Size` step it is fitted by SIZE alone and takes that step's stroke
  // from its variable mode; off the ladder it is rescaled (see `makeIcon`).
  fromVariant?: ComponentNode | null;
}

/** How `makeIcon` drew one icon. */
export interface DrawnIcon {
  /** The side it was drawn at. */
  side: number;
  /** The id of the `Size=N` variant it was instanced from. */
  mainId: string;
  /** The name of the `Icon` collection mode a slot icon fitted by size alone
   *  carries on the instance; null for every other icon. */
  mode: string | null;
  /**
   * Whether the side was reached by `resize` alone, which leaves the stroke
   * where the variant has it: a slot icon on a `Size` step (which also carries
   * `mode`), or an icon off the ladder whose stroke is the same across its side
   * (which keeps its variant's own pinned mode and carries none). False for an
   * icon at a step and for one rescaled from a step.
   */
  bySize: boolean;
}

// Every icon `makeIcon` drew this run (`DrawnIcon`). `bindSwapProp` reads it to
// tell whether a bind is about to change the main, and `settleIconAfterBind`
// reads it to know how the size is put back (see there). Held weakly, because
// the run makes thousands of them.
const drawnIcons = new WeakMap<InstanceNode, DrawnIcon>();

// A redraw that keeps the old instance in place of the new one carries the
// record across, so a bind settled after the swap reads the side it was drawn at.
onRedrawNodeKept((from, to) => {
  if (from.type !== 'INSTANCE' || to.type !== 'INSTANCE') return;
  const drawn = drawnIcons.get(from);
  if (drawn !== undefined) drawnIcons.set(to, drawn);
});

/** What `makeIcon` recorded for `node`, or undefined for any other instance. */
export function drawnIconOf(node: SceneNode): DrawnIcon | undefined {
  return node.type === 'INSTANCE' ? drawnIcons.get(node) : undefined;
}

export const ICON_NAMES: readonly string[] = Object.keys(ICONS);

export function buildIconGlyph(
  target: ComponentNode,
  name: string,
  lk: VarLookup,
  opts: IconOpts,
): void {
  const icon = ICONS[name];
  if (!icon) throw new Error(unknownIconMessage(name));
  const side = dimVal(opts.size);
  const svg =
    `<svg xmlns="http://www.w3.org/2000/svg" width="${icon.w}" ` +
    `height="${icon.h}" viewBox="0 0 ${icon.w} ${icon.h}">${icon.body}</svg>`;
  const frame = figma.createNodeFromSvg(svg);
  frame.name = name;
  frame.fills = [];
  repaintGlyph(frame, glyphPaint(lk, opts));
  frame.rescale(side / icon.w);
  target.layoutMode = 'NONE';
  target.fills = [];
  target.resize(side, side);
  target.appendChild(frame);
  frame.x = 0;
  frame.y = 0;
}

// ─── The designer-owned `Icon` set ───────────────────────────────────────────
//
// The plugin no longer builds `Icon`. It is authored on `❖ Icon` as a
// COMPONENT_SET with a `Size=N` variant axis and ONE INSTANCE_SWAP property
// that chooses the glyph, and the glyphs themselves live in four separate
// library files. So everything below this line composes rather than draws:
// pick the `Size` step, swap in the library glyph, and let a variable mode of
// the Lucide `Icon` collection supply the stroke weight. The weight is the
// library's rule (a function of the step, floored below 24), so the plugin
// states WHICH step an icon takes its stroke from and never a weight.
//
// Three ways to land on a side, and which one an icon takes is decided by what
// the icon is and where its side falls on the ladder:
//
//   · A slot icon — drawn from the swap default (`IconOpts.fromVariant`) at a
//     side that is a `Size` step — is fitted by SIZE alone (`resize`) and takes
//     that step's stroke through an explicit mode on the instance
//     (`slotModeFor`). The glyph inside the variants sits on SCALE constraints,
//     so it follows the box; `resize` leaves `strokeWeight` alone, and the mode
//     is the only thing that says what the stroke is.
//   · Every other icon is drawn from the `Size` step nearest its side. A side
//     that is a step needs nothing more: the variant's own pinned mode is the
//     step's stroke.
//   · A side that is not a step is also fitted by SIZE alone, keeping the nearest
//     step's pinned mode, when the stroke is the same on both rungs that bracket
//     the side (`strokeHoldsAt`): there is nothing for a rescale to correct, and
//     a rescale would scale the stroke away from the value the collection states
//     for every rung around it. Where the bracketing rungs differ, or nothing
//     brackets the side, or the fit cannot be trusted, the icon is `rescale`d
//     from that step, which scales the box, the glyph AND the stroke and keeps
//     the variable binding — a stroke that is the step's times the ratio, and
//     said so in the run log (`drainInexactIconSizes`). Below the smallest rung
//     the two smallest rungs differing is a library that has not stated its
//     floor, and that is also noted (`noteSlotIcon`), so the entry is left
//     unstamped and the next run redraws it once the library is mended.
//
// (`buildIconGlyph` ABOVE does draw, and does resize. It has no caller left
// once `Icon` became a validator; it is kept because deleting it, `icons.json`
// and `gen-icons.ts` is a separate decision — whether the plugin keeps a way to
// draw icons in a file where the library is not enabled.)

/** The Lucide glyph mains, imported once per run — see `installGlyphIndex`. */
let glyphIndex: ReadonlyMap<string, ComponentNode> | null = null;

/**
 * Installs the glyph mains resolved by `generate.ts`'s async prelude.
 *
 * Builders are synchronous (`build: (page, lk) => BuildResult`) but
 * `importComponentByKeyAsync` is not, so the import cannot happen inside
 * `makeIcon`. Mirrors the `installNodeIndex` / `clearNodeIndex` pair in
 * `identity.ts` for the same reason.
 */
export function installGlyphIndex(m: ReadonlyMap<string, ComponentNode>): void {
  glyphIndex = m;
}

/** Drops the glyph index at the end of a run, so a stale one cannot leak. The
 *  mode index goes with it: both are what the run's async prelude resolved. */
export function clearGlyphIndex(): void {
  glyphIndex = null;
  iconSetCache = null;
  iconModeIndex = null;
  clearContentIndex();
}

// The `Icon` set, its `Size=N` ladder and its swap-property key, resolved once
// per run instead of once per `makeIcon` call.
//
// All three were being re-derived on every call: a document lookup, a regex
// pass over the set's children building and sorting a fresh array, and a read
// of `componentPropertyDefinitions` (a computed getter on a COMPONENT_SET).
// `Button` alone calls `makeIcon` twice per combo — 864 times per run — and
// none of the three answers can change while a run is in flight.
//
// Keyed to the run, not memoised forever: the set is a designer-owned node that
// can be edited between runs, and a cache that outlived the run would serve the
// ladder from before that edit. `clearGlyphIndex` already marks the run's end
// for exactly this class of state, so it clears this too.
let iconSetCache: {
  set: ComponentSetNode;
  variants: { step: number; node: ComponentNode }[];
  swapKey: string;
} | null = null;

/** The run-scoped `Icon` handle — derived on first use, reused after. */
function iconSetResolved(): {
  set: ComponentSetNode;
  variants: { step: number; node: ComponentNode }[];
  swapKey: string;
} {
  // `removed` before trusting it. The run-end clear (`clearGlyphIndex`, called
  // from `generate.ts`) is on the SUCCESS path only, not in a `finally` — so a
  // run that throws leaves this cache populated for the next one, and the next
  // one may open after the designer edited or restored the `Icon` set. Holding
  // `ComponentNode` handles across that is how a cache serves nodes that are
  // no longer in the document.
  //
  // One property read per call against re-deriving the set, its ladder and its
  // property key: the check costs a rounding error of what it protects.
  // The members too, not just the set: a run that rebuilds `Icon` recycles the
  // set node and replaces its variants, so a cache keyed on the set alone
  // would go on instancing members that are no longer in the document.
  if (
    iconSetCache &&
    !iconSetCache.set.removed &&
    !iconSetCache.variants.some((v) => v.node.removed)
  ) {
    return iconSetCache;
  }
  iconSetCache = null;
  const set = iconSet();
  const variants = sizeVariantsOf(set);
  if (variants.length === 0) {
    throw new Error('Icon: the set has no `Size=N` variants to instance.');
  }
  iconSetCache = { set, variants, swapKey: swapPropKeyOf(set) };
  return iconSetCache;
}

// ─── The Lucide `Icon` collection — where a slot icon's stroke comes from ────
//
// The stroke weight of a Lucide glyph is a variable (`stroke-weight`) of the
// library's `Icon` collection, with one MODE per `Size` step, named for the
// step ("10" … "32"). An instance gets its stroke from the mode in force on it:
// a `Size=N` variant pins mode "N" on itself, which is why an icon drawn at a
// step needs nothing more. A slot icon is fitted to its slot by size alone, so
// it keeps the variant it was drawn from — the swap default, whatever its step
// — and says which stroke it wants by carrying an explicit mode of its own,
// named for the SLOT's side (`slotModeFor`).
//
// Finding the collection is async and builders are not, so it is resolved in
// `generate.ts`'s prelude and handed over (`installIconModeIndex`), the way the
// glyph index is. Setting the mode itself is a synchronous write, so it happens
// where the instance is drawn and needs no queue behind the build.
//
// The collection is found through the `stroke-weight` binding of a glyph vector
// inside the `Icon` set, not by name. The file can hold the same library's
// collection twice (an older and a newer import, same key, the newer with
// more modes), and only the one a glyph vector is bound to is the one whose
// modes move the stroke — a name lookup picks either.

/** What the prelude resolved: the collection, and its modes by name. */
export interface IconModeIndex {
  /** The collection's id, for the per-entry refresh (`refreshIconModeCollection`). */
  collectionId: string;
  /** The object `setExplicitVariableModeForCollection` takes. */
  collection: VariableCollection;
  /** Mode id by mode NAME — a mode is named for the `Size` step it supplies. */
  modeIdByName: ReadonlyMap<string, string>;
  /**
   * The stroke weight the collection states in each mode, by mode NAME. Read off
   * the library's `stroke-weight` variable and never computed here: the plugin
   * learns the rule from the collection, and uses it only to ask whether two
   * steps stroke alike (`strokeHoldsAt`). A mode whose value is not a plain
   * number (an alias) has no entry, and a step without one proves nothing.
   */
  strokeByModeName: ReadonlyMap<string, number>;
}

let iconModeIndex: IconModeIndex | null = null;

/** Installs what the async prelude resolved. Null drops it: slot icons are then
 *  fitted the other way (see `slotModeFor`). */
export function installIconModeIndex(index: IconModeIndex | null): void {
  iconModeIndex = index;
}

/** Drops the mode index — for a command that builds without the prelude and so
 *  must not inherit a collection an earlier run resolved. */
export function clearIconModeIndex(): void {
  iconModeIndex = null;
}

/** What is installed right now, or null. Read-only: the harness asks it what the
 *  prelude left behind, which is the only way to see that the prelude installed
 *  anything at all. */
export function heldIconModeIndex(): IconModeIndex | null {
  return iconModeIndex;
}

/**
 * Re-reads the collection object under the held id, once per entry.
 *
 * The same reason the glyph handles are re-imported per entry: a handle taken
 * in the prelude has to survive an hour of other entries, and what the run
 * holds across that is an id, not an object. Keeps the held object when the
 * lookup answers nothing — a failed refresh must not be what stops the run.
 */
export async function refreshIconModeCollection(
  getCollection: (id: string) => Promise<VariableCollection | null>,
): Promise<void> {
  const held = iconModeIndex;
  if (held === null) return;
  const fresh = await getCollection(held.collectionId);
  if (fresh !== null && iconModeIndex === held) {
    iconModeIndex = {
      collectionId: held.collectionId,
      collection: fresh,
      modeIdByName: held.modeIdByName,
      strokeByModeName: held.strokeByModeName,
    };
  }
}

/** The first variable a stroke weight is bound to anywhere under `root`. */
function strokeWeightVariableIdUnder(root: ComponentNode): string | null {
  for (const node of root.findAll(() => true)) {
    const bound = (node as { boundVariables?: { strokeWeight?: { id?: unknown } } })
      .boundVariables;
    const id = bound?.strokeWeight?.id;
    if (typeof id === 'string' && id !== '') return id;
  }
  return null;
}

/** What `resolveIconModeIndex` needs of a resolved variable. */
export interface IconStrokeVariable {
  variableCollectionId: string;
  /** The value in each mode of the collection, by mode id. Only a plain number
   *  is read; an alias or any other kind of value leaves its mode unread. */
  valuesByMode?: { readonly [modeId: string]: unknown };
}

/** What `resolveIconModeIndex` answers: the collection and its modes, or why not. */
export type IconModeResolution<C extends IconModeCollection> =
  | {
      ok: true;
      collection: C;
      collectionId: string;
      /** The variable the collection was found through. */
      variableId: string;
      modeIdByName: Map<string, string>;
      /** The stroke weight stated in each mode that states a plain number, by mode name. */
      strokeByModeName: Map<string, number>;
      /** `Size` steps of the set that have no mode named for them. */
      missingSteps: number[];
      /** `Size` steps whose mode states no plain number for the stroke weight. */
      unreadSteps: number[];
    }
  | { ok: false; reason: string };

/**
 * Finds the `Icon` collection the glyph strokes are bound to.
 *
 * Takes its two lookups as arguments, like `findMisPinnedIconModes`, for the
 * same two reasons: the synchronous variable API is off under this plugin's
 * `documentAccess: "dynamic-page"` manifest, and a function that reaches for a
 * global cannot be driven by the self-test harness.
 *
 * The default variant is asked first, then the rest in ladder order. A glyph
 * vector inside any step binds the same variable, so the order only decides
 * which one answers when a variant has lost its binding.
 */
export async function resolveIconModeIndex<C extends IconModeCollection>(
  set: ComponentSetNode,
  getVariable: (id: string) => Promise<IconStrokeVariable | null>,
  getCollection: (id: string) => Promise<C | null>,
): Promise<IconModeResolution<C>> {
  const variants = sizeVariantsOf(set);
  const asked: ComponentNode[] = [];
  const preferred = set.defaultVariant;
  if (preferred && preferred.type === 'COMPONENT') asked.push(preferred);
  for (const v of variants) if (asked.indexOf(v.node) < 0) asked.push(v.node);
  let variableId: string | null = null;
  for (const variant of asked) {
    variableId = strokeWeightVariableIdUnder(variant);
    if (variableId !== null) break;
  }
  if (variableId === null) {
    return {
      ok: false,
      reason: 'no vector under any `Size=N` variant binds its stroke weight to a variable',
    };
  }
  const variable = await getVariable(variableId);
  if (variable === null) {
    return { ok: false, reason: `the stroke-weight variable ${variableId} did not resolve` };
  }
  const collection = await getCollection(variable.variableCollectionId);
  if (collection === null) {
    return {
      ok: false,
      reason: `the collection ${variable.variableCollectionId} of ${variableId} did not resolve`,
    };
  }
  const modeIdByName = new Map<string, string>();
  const strokeByModeName = new Map<string, number>();
  for (const mode of collection.modes) {
    if (modeIdByName.has(mode.name)) continue;
    modeIdByName.set(mode.name, mode.modeId);
    const stated = variable.valuesByMode?.[mode.modeId];
    if (typeof stated === 'number' && Number.isFinite(stated)) strokeByModeName.set(mode.name, stated);
  }
  const steps = variants.map((v) => v.step);
  return {
    ok: true,
    collection,
    collectionId: variable.variableCollectionId,
    variableId,
    modeIdByName,
    strokeByModeName,
    missingSteps: steps.filter((s) => !modeIdByName.has(String(s))),
    unreadSteps: steps.filter((s) => modeIdByName.has(String(s)) && !strokeByModeName.has(String(s))),
  };
}

/**
 * The prelude's whole mode step: drops what an earlier run installed, resolves
 * the collection of `set`'s glyph strokes, installs it, and says what happened.
 *
 * A function and not inline in `generate.ts`, so the harness runs THE step the
 * plugin runs. Left inline it was a copy the harness played by hand, and the
 * install call could be deleted with `tsc` and every drill still green — the run
 * would then log that it had found the collection and fit every slot icon the
 * other way, with nothing to say so.
 *
 * Never throws: an unresolved collection is a warning, not a stop (like the
 * mode-pin check beside it), because the icons still land at the right size and
 * only the stroke is off — and the line says what the run does instead. The
 * lookups are arguments for the reasons `resolveIconModeIndex` gives.
 *
 * `set` null (the file has no `Icon` set) installs nothing and says nothing: the
 * entry that needs the set fails by name.
 */
export async function prepareIconModes<C extends VariableCollection>(
  set: ComponentSetNode | null,
  getVariable: (id: string) => Promise<IconStrokeVariable | null>,
  getCollection: (id: string) => Promise<C | null>,
  log: string[],
): Promise<void> {
  installIconModeIndex(null);
  if (set === null) return;
  try {
    const modes = await resolveIconModeIndex(set, getVariable, getCollection);
    if (modes.ok) {
      installIconModeIndex({
        collectionId: modes.collectionId,
        collection: modes.collection,
        modeIdByName: modes.modeIdByName,
        strokeByModeName: modes.strokeByModeName,
      });
      log.push(
        `Icon: 슬롯 아이콘 획 모드 — 컬렉션 "${modes.collection.name}" (${modes.collectionId}), ` +
          `모드 ${modes.modeIdByName.size}개.`,
      );
      if (modes.missingSteps.length > 0) {
        log.push(
          `⚠ Icon: 컬렉션에 모드가 없는 Size 단계 ${modes.missingSteps.join(', ')} — ` +
            '그 크기의 슬롯 아이콘은 모드 없이 기본값에서 비례 축소로 그린다.',
        );
      }
      if (modes.unreadSteps.length > 0) {
        log.push(
          `⚠ Icon: stroke-weight 가 숫자로 읽히지 않는 Size 단계 ${modes.unreadSteps.join(', ')} — ` +
            '사다리 밖 크기가 그 단계에 걸리면 획이 같은지 확인할 수 없어 비례 축소로 그린다.',
        );
      }
    } else {
      log.push(
        `⚠ Icon: 획 모드 컬렉션을 찾지 못해 슬롯 아이콘을 모드 없이 그린다 — ${modes.reason}.`,
      );
    }
  } catch (err) {
    log.push(
      `⚠ Icon: 획 모드 컬렉션을 읽다 실패해 슬롯 아이콘을 모드 없이 그린다 — ${String(err)}.`,
    );
  }
}

// What went differently from the rule for an icon that was to be fitted by size
// alone (a slot icon, or an icon off the ladder), drained per entry beside the
// inexact sizes. A set, so that 864 Buttons wearing the same fault say it once;
// each message carries its own identifying numbers.
const slotIconNotes = new Set<string>();

function noteSlotIcon(message: string): void {
  slotIconNotes.add(message);
}

/** The notes since the last drain, and clears them. */
export function drainSlotIconNotes(): string[] {
  const out = Array.from(slotIconNotes);
  slotIconNotes.clear();
  return out;
}

// An icon that was rescaled because the run holds no `Icon` collection: a slot
// icon on a `Size` step, or an icon off the ladder that the collection could have
// shown to keep its stroke. The prelude says that once for the whole run, so
// there is no per-entry note to find it by — and an entry that drew this way is
// not the drawing the rule describes, whatever its hash says. A flag and not a
// note for that reason: it must not print 864 times.
let slotIconWithoutCollection = false;

/**
 * Whether an icon was drawn without a collection since the last drain, and
 * clears it.
 *
 * With `drainSlotIconNotes` this is the whole answer to "did this entry draw an
 * icon off the stroke rule because of the run's or the library's state":
 * the notes name the legs the collection or glyph failed, this names a run that
 * had no collection to begin with. The build loop reads both to decide whether
 * the entry may be stamped current (`stampFor` in `content-hash.ts`).
 */
export function drainSlotIconWithoutCollection(): boolean {
  const out = slotIconWithoutCollection;
  slotIconWithoutCollection = false;
  return out;
}

/**
 * One record per icon drawn at a size other than the one its caller stated,
 * drained per entry: a rescale from a step the `Size` axis has no rung for, or
 * a slot swap whose multiplier no rung cancels (`slotSwapVariantFor`).
 */
const inexactIconSizes: (
  | { kind: 'rescaled'; name: string; side: number; step: number }
  | { kind: 'slot-swap'; name: string; wanted: number; drawn: number; scale: number }
)[] = [];

/**
 * Reports the icons drawn at a size the `Size` axis has no step for and that a
 * rescale had to reach, and clears the list.
 *
 * A side that is no step, and whose bracketing rungs do not stroke alike, is
 * drawn from the nearest step and `rescale`d, which scales the box, the glyph AND
 * the stroke by the same factor. The right panel therefore reads the STEP's
 * number while the icon draws at `side`, and the stroke is the step's stroke
 * times that factor, which is not what a step of its own would carry. A line in
 * the run log is the difference between that being a known trade and being the
 * kind of thing nobody notices for months.
 *
 * A side that is no step but whose bracketing rungs stroke alike is not
 * reported: it was fitted by size alone and wears the stroke every rung around it
 * states (`strokeHoldsAt`), so nothing about it is inexact.
 *
 * The size is off the icon token ladder (`CoreIconSize`). Today that is a glyph
 * sized by its host's geometry rather than by that ladder when the stroke is not
 * constant across it. A slot icon off the ladder is in the same state — it has
 * no mode to take its stroke from (`slotModeFor`). Two kinds are exempt: a
 * placeholder that stands in for a caller's picture, because its rescale is the
 * point, and a size the component's Core style states off the ladder on purpose
 * (`statedOffLadder` — the dock's `smIconSize`), because the design decided it
 * and a warning repeated on every run hides the ones that are not decided.
 */
export function drainInexactIconSizes(): string[] {
  const out = inexactIconSizes.map((r) =>
    r.kind === 'rescaled'
      ? `${r.name} drawn at ${r.side} (no Size=${r.side}; rescaled from ${r.step})`
      : `${r.name} swapped into a slot scaled ×${r.scale.toFixed(3)} draws at ` +
        `${r.drawn.toFixed(2)} where ${r.wanted} is stated (no Size step cancels the scale)`,
  );
  inexactIconSizes.length = 0;
  return out;
}

/** The `Icon` COMPONENT_SET, or a loud error naming who owns it. */
function iconSet(): ComponentSetNode {
  // The document index, not `figma.currentPage`. `Icon` lives on `❖ Icon` and
  // every caller builds on its own page, so the current page is never the one
  // holding it — `Button` died on `makeIcon('check')` two lines after `Icon`
  // finished successfully.
  const found = findComponentByName(figma.currentPage, 'Icon');
  if (!found || found.type !== 'COMPONENT_SET') {
    throw new Error(
      'makeIcon: the `Icon` COMPONENT_SET is not in the document. It is ' +
        'designer-owned and lives on `❖ Icon`; the plugin validates it but no ' +
        'longer builds it, so build order cannot fix this — restore the ' +
        '`❖ Icon` page from Figma version history, or open a document that ' +
        'has it.',
    );
  }
  return found;
}

/**
 * The `Size` steps the set actually offers, ascending.
 *
 * Parsed, never hardcoded: the axis is the designer's to change, and a
 * hardcoded list would silently stop matching the day a step is added or
 * removed — the failure would land as wrong-sized icons, not as an error.
 */
export function sizeVariantsOf(
  set: ComponentSetNode,
): { step: number; node: ComponentNode }[] {
  const out: { step: number; node: ComponentNode }[] = [];
  for (const c of set.children) {
    const m = /^Size=(\d+(?:\.\d+)?)$/.exec(c.name);
    if (c.type === 'COMPONENT' && m) out.push({ step: Number(m[1]), node: c });
  }
  return out.sort((a, b) => a.step - b.step);
}

/** The steps alone, for callers that only need the numbers. */
export function sizeStepsOf(set: ComponentSetNode): number[] {
  return sizeVariantsOf(set).map((v) => v.step);
}

/**
 * The `Size=N` variant whose step is nearest `side`.
 *
 * One function for the two places that choose a step from a stated size —
 * `makeIcon` (an icon the plugin draws itself) and `iconMainIdAt` (an icon a
 * composed child's slot is swapped to). A swap that took the set's default
 * variant instead would give every composed child the default step whatever
 * its Core row says, so both paths choose through here.
 *
 * The matched variant is carried through, never re-found by rebuilding
 * `Size=${step}`: a label the regex accepts but `String(Number(x))` does not
 * reproduce (`Size=24.0`, `Size=016`) would look up nothing and throw an
 * error blaming a race that did not happen.
 */
export function nearestSizeVariantOf(
  set: ComponentSetNode,
  side: number,
): { step: number; node: ComponentNode } {
  const variants = sizeVariantsOf(set);
  if (variants.length === 0) {
    throw new Error('Icon: the set has no `Size=N` variants to instance.');
  }
  return variants.reduce(
    (best, v) => (Math.abs(v.step - side) < Math.abs(best.step - side) ? v : best),
    variants[0],
  );
}

/**
 * The set's single INSTANCE_SWAP property key.
 *
 * Found BY TYPE rather than by the literal `Icon#2336:0`: the `#…` suffix is
 * minted by Figma and changes if the property is recreated, so a literal
 * would break on an edit that looks cosmetic in the UI. `component-props.ts`
 * already uses the `id.split('#')[0]` idiom for the same reason.
 */
function swapPropKeyOf(set: ComponentSetNode): string {
  const defs = set.componentPropertyDefinitions;
  const keys = Object.keys(defs).filter((k) => defs[k].type === 'INSTANCE_SWAP');
  if (keys.length !== 1) {
    throw new Error(
      `Icon: expected exactly one INSTANCE_SWAP property, found ${keys.length}` +
        `${keys.length ? ` [${keys.join(', ')}]` : ''}. The glyph chooser is the ` +
        'one property this module drives; two of them means it cannot tell which.',
    );
  }
  return keys[0];
}

/** The library glyph main for `name`, or a loud error naming what to fix. */
function requireGlyph(name: string): ComponentNode {
  const glyph = glyphIndex ? glyphIndex.get(name) : undefined;
  if (!glyph) {
    throw new Error(
      `makeIcon('${name}'): no library glyph for that name. Either the ` +
        '`CoUI Icons — Lucide` library is not enabled in this file, or the name ' +
        'is missing from src/data/icon-keys.json (`npm run gen:icon-keys`).',
    );
  }
  return glyph;
}

/**
 * Writes one glyph into one `Icon` instance's swap property.
 *
 * ─── Why this is a function and not two `setProperties` calls ────────────────
 *
 * Both swap sites in this module — `makeIcon` on a fresh instance and
 * `setIconGlyph` on a composed child's — write the SAME thing: a glyph handle
 * the run imported once, minutes or hours before this moment. That handle can
 * go stale, and when it does Figma answers `in setProperties: Value for
 * instance swap component property is invalid` — a message that names neither
 * the glyph nor the reason. Two call sites meant two places to get the
 * recovery wrong, so there is one.
 *
 * ─── What goes stale, and why only some glyphs ───────────────────────────────
 *
 * `generate.ts`'s prelude calls `importComponentByKeyAsync` once per name and
 * hands the nodes over via `installGlyphIndex`, because builders are
 * synchronous and that call is not. For a glyph some node in the document
 * already instances, the import resolves to that RESIDENT component and the
 * handle is as durable as the document. For a glyph nothing instances, the
 * import MATERIALIZES a component that is reachable from no page — and this
 * plugin runs under `documentAccess: "dynamic-page"`, where a node not
 * reachable from a loaded page is not kept loaded. A run walks ~148 pages over
 * more than an hour, and by the time an entry near the end asks for that glyph
 * its id resolves to nothing.
 *
 * Measured, not reasoned: importing all 35 shipped keys against the live file
 * returned 33 ids in long-settled blocks and materialized exactly two fresh —
 * `mail` and `heart`. `mail` is drawn by `Fab` and `Label` and by nothing
 * else, and those were exactly the two entries that failed, both on their
 * `mail` write. `Fab` proves it on its own: inside one loop it wrote `upload`
 * (resident) into a menu row and `mail` (materialized) into the next one, same
 * target shape, same property key, milliseconds apart — the first landed and
 * the second threw.
 *
 * The state feeds itself, which is why it appeared to arrive out of nowhere:
 * a run that fails on a glyph leaves no instance of it behind, so the next
 * run has to materialize it again, and fails again.
 *
 * ─── The recovery ───────────────────────────────────────────────────────────
 *
 * Instancing a component is what makes it reachable, and `createInstance` is
 * synchronous — the one repair available from inside a builder. So a rejected
 * write anchors the glyph with a throwaway instance, retries, and drops the
 * anchor: by then the real target holds the glyph and IS the anchor. The
 * throwaway is removed on both paths, so a failed retry leaves nothing on the
 * page (this module has been the source of exactly that debris before).
 *
 * If the retry is refused too, the error says which glyph and why, because
 * Figma's own message says neither and that cost an afternoon.
 */
function writeGlyph(target: InstanceNode, name: string): void {
  const glyph = requireGlyph(name);
  // Through the run-scoped handle — this is called per composed child too, and
  // it was re-deriving the set and its property key every time for an answer
  // that cannot change mid-run.
  const key = iconSetResolved().swapKey;
  try {
    target.setProperties({ [key]: glyph.id });
    return;
  } catch (stale) {
    let anchor: InstanceNode | null = null;
    try {
      anchor = glyph.createInstance();
      target.setProperties({ [key]: glyph.id });
    } catch (retry) {
      // Three facts, because the first version of this message reported only
      // one and the run that hit it could not be read afterwards. It asserted
      // "refused it again after re-anchoring" on both paths, so a failure to
      // ANCHOR — `createInstance` throwing, meaning the retry never happened —
      // produced the same sentence as a failure to retry. The two want
      // opposite fixes, and the log could not tell them apart.
      const anchored = anchor !== null;
      throw new Error(
        `swapGlyph('${name}'): Figma refused the glyph — ${String(stale)}. ` +
          (anchored
            ? `Re-anchoring succeeded and the retry was refused too — ${String(retry)}. ` +
              'So the handle is instanced in this document and Figma still ' +
              'will not take it: the stale-handle reading does NOT explain ' +
              'this one, and the next place to look is the swap property or ' +
              'the glyph itself, not residency.'
            : `Re-anchoring itself failed — ${String(retry)} — so the retry ` +
              'never ran. The handle could not even be instanced, which is ' +
              'what an unloaded component does: it came from this run\'s ' +
              'prelude import, and under `documentAccess: "dynamic-page"` a ' +
              'component no node in the document instances is not kept loaded ' +
              'while a run walks every page. The glyph itself is fine — ' +
              're-importing the same key resolves it.'),
      );
    } finally {
      // Dropped on both paths. On the success path the target now holds the
      // glyph and IS the anchor, so the throwaway has nothing left to keep
      // alive; on the failure path leaving it would be debris (this module
      // has been the source of exactly that before).
      if (anchor) anchor.remove();
    }
  }
}

// ─── Paint after swap — the one recolour walk ────────────────────────────────
//
// A glyph swap re-points an `Icon` at a different library component, and the
// colour the old glyph wore does not reliably come along: Figma carries an
// instance's overrides onto the NEW component's layers only where a layer of
// the same name sits at the same depth. Lucide's leaves happen to share names,
// so a stroke painted onto `house` usually lands on `search` too — and that
// "usually" is the whole defect. A destination glyph with more leaves than the
// one it replaced keeps the library colour on every leaf the carry-over could
// not reach, and a destination the parent states a different colour for keeps
// the old colour on every leaf it did reach. Both render as a finished icon in
// the wrong colour, so neither is visible until the canvas is read against
// Core (Command's back arrow drew `on-surface-variant` over a Core that says
// `on-surface` — the carry-over working exactly as designed).
//
// So nothing is left to the carry-over. Every glyph write in this plugin goes
// through `swapGlyph`, and `swapGlyph` cannot finish without repainting:
// `GlyphPaint` is a required argument and has no "leave it" member.
//
// Reach: the swaps the plugin itself makes. A designer choosing a glyph from
// the Properties panel is a swap the plugin never sees, and there the colour
// still rides the carry-over alone.

/**
 * What a glyph is painted with once it is in place. Two members, no third:
 *
 * - `stated` — the parent says what colour the glyph is (an `iconStyle.color`,
 *   a forwarded foreground). Built with `glyphPaint` from the contract value.
 * - `preserve` — the parent says nothing and the colour belongs to the host
 *   the glyph sits in (a `Button` slot whose leading theme colours it). The
 *   paint the old glyph wore is read BEFORE the swap and written onto every
 *   leaf AFTER it, so a destination with more leaves than the source is still
 *   covered in full.
 */
export type GlyphPaint = StatedGlyphPaint | { readonly kind: 'preserve' };

/** The `stated` member of `GlyphPaint` — see there. */
export interface StatedGlyphPaint {
  readonly kind: 'stated';
  /** What the glyph's leaves are painted with: `content/current` when the glyph
   *  takes its colour from the slot (`content`), the token itself otherwise. At
   *  full strength for a token; a raw literal carries its own alpha. */
  readonly paint: Paint;
  /** Alpha on the glyph's root — a bound colour cannot hold one (`solid`). */
  readonly fade: number;
  /** Paint interiors that have no fill yet — `IconOpts.fill`. */
  readonly addFill: boolean;
  /**
   * Set when `paint` is bound to `content/current` and the glyph's slot is to pin
   * `tone` (`icon-content.ts`). The colour is then not a paint on this glyph but
   * the mode its slot frame wears, so it follows an icon swapped in or added
   * again. `direct` is the token painted straight on, for a pin Figma refuses.
   */
  readonly content?: { readonly tone: ContentTone; readonly direct: () => Paint };
}

/** The host-owned member of `GlyphPaint` — see there. */
export const kPreserveGlyphPaint: GlyphPaint = { kind: 'preserve' };

/** The colour fields `glyphPaint` reads — `IconOpts` and `LabelOpts` both fit. */
export interface GlyphColorOpts {
  colorVar?: Variable;
  rawColor?: RGB;
  opacity?: number;
  fill?: boolean;
}

/**
 * A stated paint from resolved colour options (`glyphOpts` / `labelColor`).
 *
 * A token that is a tone of content paints the glyph with `content/current` and
 * leaves the choice of tone to the slot frame (`content`); every other colour
 * keeps the split it has everywhere else: a token paints at full strength and
 * fades the glyph's root, because a bound colour overwrites any alpha the paint
 * asks for; a literal carries its alpha in the paint.
 */
export function glyphPaint(lk: VarLookup, opts: GlyphColorOpts): StatedGlyphPaint {
  const addFill = opts.fill === true;
  if (opts.rawColor) {
    noteDirectGlyph('literal');
    return {
      kind: 'stated',
      paint: { type: 'SOLID', color: opts.rawColor, opacity: opts.opacity ?? 1 },
      fade: 1,
      addFill,
    };
  }
  const colorVar = opts.colorVar ?? lk.sem('on-surface');
  const fade = opts.opacity ?? 1;
  const slot = contentPaintOf(colorVar);
  if (slot !== null) {
    return {
      kind: 'stated',
      paint: slot.paint,
      fade,
      addFill,
      content: { tone: slot.tone, direct: () => solid(colorVar, 1) },
    };
  }
  return { kind: 'stated', paint: solid(colorVar, 1), fade, addFill };
}

/**
 * Paints every leaf under `root` — the only recolour walk a glyph has.
 *
 * Strokes are re-pointed wherever a node already has one: Lucide strokes its
 * marks. Fills only on genuine shape geometry (`kFillableShapes`), and only
 * where one exists or `addFill` asks for one — an ADDED fill needs a shape to
 * land on, while an EXISTING fill is already whatever the source authored.
 * The gate matters: the nested swap-target inside every `Size=N` step is an
 * INSTANCE with a `fills` array of its own, and repainting IT floods the whole
 * box solid over the stroke-only vectors underneath — a from-scratch generate
 * once rendered every Lucide glyph as a solid square that way, and a second
 * copy of this walk shipped the same square again.
 */
export function repaintGlyph(root: FrameNode | InstanceNode, paint: StatedGlyphPaint): void {
  fadeNode(root, paint.fade);
  paintGlyphLeaves(root, paint.paint, paint.addFill);
  const content = paint.content;
  if (content !== undefined) {
    // The slot is told after the leaves are bound: it pins the mode once the
    // builder is done and the glyph has a parent (`flushContentModes`), and a
    // pin Figma refuses gives the glyph the token back.
    noteContentGlyph(root, content.tone, () => paintGlyphLeaves(root, content.direct(), paint.addFill));
  }
}

/** The recolour walk itself — see `repaintGlyph`. */
function paintGlyphLeaves(root: FrameNode | InstanceNode, paint: Paint, addFill: boolean): void {
  for (const node of [root, ...root.findAll(() => true)]) {
    if ('strokes' in node && node.strokes.length > 0) node.strokes = [paint];
    if (
      node !== root &&
      'fills' in node &&
      Array.isArray(node.fills) &&
      kFillableShapes.indexOf(node.type) >= 0 &&
      (addFill || node.fills.length > 0)
    ) {
      node.fills = [paint];
    }
  }
}

/**
 * The paint the glyph under `target` wears now — read before a `preserve` swap.
 *
 * The first stroke found, falling back to the first fill on real geometry,
 * with its variable binding intact (it is the paint object Figma holds). Loud
 * when there is none: "preserve" over a glyph that wears nothing would quietly
 * become "leave it", the member `GlyphPaint` does not have.
 */
function heldGlyphPaint(target: InstanceNode, name: string): StatedGlyphPaint {
  const nodes = [target, ...target.findAll(() => true)];
  let held: Paint | null = null;
  for (const node of nodes) {
    if ('strokes' in node && node.strokes.length > 0) {
      held = node.strokes[0];
      break;
    }
  }
  if (held == null) {
    for (const node of nodes) {
      if (
        node !== target &&
        'fills' in node &&
        Array.isArray(node.fills) &&
        node.fills.length > 0 &&
        kFillableShapes.indexOf(node.type) >= 0
      ) {
        held = (node.fills as readonly Paint[])[0];
        break;
      }
    }
  }
  if (held == null) {
    throw new Error(
      `swapGlyph('${name}', preserve): the glyph in ${target.name} wears no ` +
        'stroke or fill to carry across the swap. Preserve only means something ' +
        'over a glyph the host already painted — state the colour instead.',
    );
  }
  return { kind: 'stated', paint: held, fade: 1, addFill: false };
}

/**
 * Swaps the glyph and paints it — the one path every glyph write takes.
 *
 * `makeIcon` (a fresh instance) and `setIconGlyph` (a composed child's Icon,
 * which `setSlotIcon` also reaches) both land here, so no swap can finish
 * without its colour being written again (header above).
 */
function swapGlyph(target: InstanceNode, name: string, paint: GlyphPaint): void {
  const settled = paint.kind === 'preserve' ? heldGlyphPaint(target, name) : paint;
  writeGlyph(target, name);
  repaintGlyph(target, settled);
}

/**
 * Points an existing `Icon` instance at a different glyph, and paints it.
 *
 * Needed because a parent's INSTANCE_SWAP slot holds an *Icon*, not a glyph:
 * swapping that slot chooses the size wrapper, and the glyph is a nested
 * override on the Icon it lands on. A caller that only swaps the slot gets the
 * set's own default glyph — which is how two carousel arrows became the same
 * shape. `paint` is required for the reason `swapGlyph` gives.
 */
export function setIconGlyph(icon: InstanceNode, name: string, paint: GlyphPaint): void {
  swapGlyph(icon, name, paint);
}

/** The shape `findMisPinnedIconModes` needs from a resolved collection. */
export interface IconModeCollection {
  name: string;
  modes: readonly { modeId: string; name: string }[];
}

/** What `findMisPinnedIconModes` reports. */
export interface IconModePinReport {
  /** `Size=N` variants pinned to a mode named for another step. */
  misPinned: string[];
  /**
   * Pins on the stroke-weight collection's library that name a mode the
   * collection the glyphs are bound to does not hold — so whether they are the
   * right step cannot be told. Reported rather than skipped: a skipped pin is
   * a pin the check never looked at.
   */
  unchecked: string[];
}

/** The library part of a collection id — `VariableCollectionId:<key>` before
 *  the `/<version>` suffix a file gives each import of the same collection. */
function libraryOf(collectionId: string): string {
  const slash = collectionId.indexOf('/');
  return slash < 0 ? collectionId : collectionId.slice(0, slash);
}

/**
 * Names every `Size=N` variant that pins a collection to a mode NOT named `N`.
 *
 * That mode is what supplies `stroke-weight`. A variant pinned to another
 * step's mode draws the wrong weight while everything else looks right — the
 * size is correct, the binding is intact, the variable resolves. A width
 * census cannot see it and a screenshot barely can, so this is the only check
 * that can catch it.
 *
 * A pin on the stroke-weight collection's library is read in `stroke` — the
 * collection the glyph strokes are bound to (`resolveIconModeIndex`) — and not
 * in the collection its key names. A file holds every import of the library
 * (`…/9:5`, `…/20:12`, …), Figma keys the pin by the oldest, and the value is a
 * mode of the newest: read through its key, every step added since the oldest
 * import resolved to no mode and was silently skipped — six of ten variants
 * (#6279). A pin that `stroke` does not hold either is `unchecked`, not passed.
 *
 * Pins on other libraries (HeroIcons' `Icon`) do not move a Lucide stroke. They
 * are read through `resolve` when it can, and left alone when it cannot.
 *
 * Takes a resolver rather than calling `figma.variables` itself, for two
 * reasons that point the same way: the synchronous variable API is off under
 * this plugin's `documentAccess: "dynamic-page"` manifest (so the caller has
 * to await anyway), and a function that reaches for a global cannot be driven
 * by the self-test harness — which would leave this the one check nobody has
 * ever seen fail.
 */
export async function findMisPinnedIconModes(
  set: ComponentSetNode,
  resolve: (id: string) => Promise<IconModeCollection | null>,
  stroke: { collectionId: string; collection: IconModeCollection } | null,
): Promise<IconModePinReport> {
  const misPinned: string[] = [];
  const unchecked: string[] = [];
  const strokeLibrary = stroke === null ? null : libraryOf(stroke.collectionId);
  for (const child of set.children) {
    const step = /^Size=(\d+(?:\.\d+)?)$/.exec(child.name);
    if (child.type !== 'COMPONENT' || !step) continue;
    const pins = child.explicitVariableModes;
    for (const collectionId of Object.keys(pins)) {
      const modeId = pins[collectionId];
      const onStroke = strokeLibrary !== null && libraryOf(collectionId) === strokeLibrary;
      const collection = onStroke ? stroke!.collection : await resolve(collectionId);
      if (!collection) continue;
      const mode = collection.modes.find((x) => x.modeId === modeId);
      if (!mode) {
        if (onStroke) unchecked.push(`${child.name} → "${collection.name}" mode ${modeId}`);
        continue;
      }
      if (mode.name !== step[1]) {
        misPinned.push(`${child.name} → "${collection.name}" mode "${mode.name}"`);
      }
    }
  }
  return { misPinned, unchecked };
}

/** The shape `findUnboundIconSizes` needs from a resolved variable. */
export interface IconSizeVariable {
  name: string;
}

/**
 * Names every `Size=N` variant whose width or height is not bound to the
 * `icon-size/N` variable of its own step.
 *
 * The step is a token (`CoreIconSize`, exported to the `Component` collection
 * as `icon-size/N`), and the variant root is where the set states it. Typed as
 * a bare number the root still draws the right size, so nothing on the canvas
 * looks wrong — but a token edit no longer reaches the set, and the designer's
 * `⇄` comparison keeps reporting it as unbound. `icon-size/default` does not
 * count for `Size=24` even though it resolves to the same value: it names
 * "what an icon draws at when nothing states one", not the step.
 *
 * Takes a resolver for the same reasons `findMisPinnedIconModes` does: the
 * caller has to await under `documentAccess: "dynamic-page"`, and a function
 * that reaches for a global cannot be driven by the self-test harness.
 */
export async function findUnboundIconSizes(
  set: ComponentSetNode,
  resolve: (id: string) => Promise<IconSizeVariable | null>,
): Promise<string[]> {
  const problems: string[] = [];
  for (const child of set.children) {
    const step = /^Size=(\d+(?:\.\d+)?)$/.exec(child.name);
    if (child.type !== 'COMPONENT' || !step) continue;
    const want = `icon-size/${step[1]}`;
    for (const field of ['width', 'height'] as const) {
      const alias = child.boundVariables?.[field];
      const variable = alias ? await resolve(alias.id) : null;
      if (variable?.name !== want) {
        problems.push(`${child.name} ${field} → ${variable ? `"${variable.name}"` : 'unbound'}`);
      }
    }
  }
  return problems;
}

/** The mode a slot icon carries: its name (the side), and what the write takes. */
interface SlotMode {
  name: string;
  modeId: string;
  collection: VariableCollection;
}

/**
 * The stroke mode a slot icon of `side`, drawn from `from`, is to carry — or
 * null when it is not fitted by size alone and is rescaled instead.
 *
 * Size-only fitting is for an icon that can take its stroke from a mode and
 * whose glyph will follow its box. Each leg of that is checked, and the first
 * that fails sends the icon down the rescale path — drawn from the default and
 * rescaled to its side — and says so where a person can act on it:
 *
 *   · `side` is a `Size` step. Off the ladder there is no mode to name, and
 *     inventing one would put a stroke on the icon that no rule states;
 *   · the run resolved the `Icon` collection (`installIconModeIndex`) — a
 *     command that builds without the prelude has none, and neither does a run
 *     whose prelude could not find it. Said once by the prelude, so it is
 *     flagged here instead of noted (`drainSlotIconWithoutCollection`);
 *   · the collection has a mode named for that step;
 *   · the glyph in `from` sits on SCALE constraints. On CENTER a size-only fit
 *     leaves the glyph at the variant's own size, spilling out of a smaller
 *     box — a file whose library glyphs are still on CENTER would draw every
 *     slot wrong that way, so it is held to the rescale path and told so.
 */
function slotModeFor(
  from: { step: number; node: ComponentNode },
  side: number,
  variants: readonly { step: number }[],
): SlotMode | null {
  // The ladder first: a side off it is rescaled in every run, collection or not,
  // so it says nothing about the run and must not mark one as missing a
  // collection.
  if (!variants.some((v) => v.step === side)) return null;
  const index = iconModeIndex;
  if (index === null) {
    slotIconWithoutCollection = true;
    return null;
  }
  const name = String(side);
  const modeId = index.modeIdByName.get(name);
  if (modeId === undefined) {
    noteSlotIcon(
      `no mode "${name}" in the Icon collection — slot icons of ${name} are rescaled from the ` +
        'default instead of taking the step\'s stroke from a mode',
    );
    return null;
  }
  if (!glyphFollowsBox(from)) {
    noteGlyphOffScale(from.step, 'slot icons drawn from it are rescaled instead');
    return null;
  }
  return { name, modeId, collection: index.collection };
}

/** A glyph on CENTER constraints keeps its own size inside a smaller box, so a
 *  size-only fit from it is refused. `consequence` says what is drawn instead. */
function noteGlyphOffScale(step: number, consequence: string): void {
  noteSlotIcon(
    `the glyph in Size=${step} is not on SCALE constraints, so a size-only fit would leave ` +
      `it at its own size inside a smaller box — ${consequence}`,
  );
}

/** Two stroke weights closer than this are the same: float noise on a stated number. */
const kStrokeEpsilon = 0.001;

/**
 * Whether an icon of `side`, drawn from the nearest step `chosen` and off the
 * `Size` ladder, can be fitted to its side by size alone and still wear the
 * stroke the collection states for it.
 *
 * It can when the stroke is the same on both sides of `side`. That is defined
 * from the `Icon` collection and by nothing else: `side` lies below the smallest
 * rung (the two smallest rungs bracket it) or between two rungs, and the
 * stroke-weight those rungs' modes state is equal. Then `chosen`'s own pinned
 * mode is the stroke at `side` too, and the fit needs no mode of its own and no
 * number from this file. Where the two rungs differ the stroke moves across
 * `side`, and which value to give it is the rule's business, not provable here —
 * the icon is rescaled and reported. Between two rungs that is the rule's own
 * ramp and the rescale follows it, so it is only reported; below the smallest
 * rung the same difference means the library has not stated the floor the
 * smallest rungs share, so it is also noted and the entry is left unstamped
 * (`hashStampFor`). A side above the largest rung has no rung above it to
 * bracket it and is rescaled in every run.
 *
 * The first leg is the ladder alone and says nothing about the run, so it comes
 * first. After it each leg that fails sends the icon down the rescale path and
 * says why where a person can act on it, like `slotModeFor`:
 *
 *   · the run resolved the `Icon` collection — without one nothing can be proved,
 *     and the entry is flagged (`drainSlotIconWithoutCollection`) because it drew
 *     a rescale that a collection would have replaced;
 *   · the collection states a plain-number stroke for both bracketing rungs;
 *   · the glyph in `chosen` sits on SCALE constraints, so the size-only fit moves
 *     it with its box.
 */
function strokeHoldsAt(
  chosen: { step: number; node: ComponentNode },
  side: number,
  variants: readonly { step: number; node: ComponentNode }[],
): boolean {
  const steps = variants.map((v) => v.step);
  let below: number;
  let above: number;
  if (side < steps[0]) {
    if (steps.length < 2) return false;
    below = steps[0];
    above = steps[1];
  } else {
    const k = steps.findIndex((step, i) => i + 1 < steps.length && step < side && side < steps[i + 1]);
    if (k < 0) return false;
    below = steps[k];
    above = steps[k + 1];
  }
  const index = iconModeIndex;
  if (index === null) {
    slotIconWithoutCollection = true;
    return false;
  }
  const strokeBelow = index.strokeByModeName.get(String(below));
  const strokeAbove = index.strokeByModeName.get(String(above));
  if (strokeBelow === undefined || strokeAbove === undefined) {
    noteSlotIcon(
      `the Icon collection states no stroke weight for mode "${below}" or "${above}" — an icon drawn at ` +
        `${side} is rescaled from Size=${chosen.step} instead of keeping the step's stroke`,
    );
    return false;
  }
  if (Math.abs(strokeBelow - strokeAbove) > kStrokeEpsilon) {
    // Below the smallest rung nothing smaller can stroke differently from the
    // two rungs that bracket it, so rungs stated apart there are a library that
    // has not stated that floor yet. The rescale draws the step's stroke scaled
    // down — a weight no collection value says — and an entry stamped current
    // would keep it after the library is mended, which the hash cannot see.
    // Between rungs a stroke that moves is the rule's own ramp, and the rescale
    // follows it exactly, so there it says nothing.
    if (side < steps[0]) {
      noteSlotIcon(
        `the Icon collection states the two smallest modes "${below}" (${strokeBelow}) and "${above}" ` +
          `(${strokeAbove}) apart — an icon drawn at ${side}, below the smallest, is rescaled from ` +
          `Size=${chosen.step} instead of keeping the stroke the two smallest rungs share`,
      );
    }
    return false;
  }
  if (!glyphFollowsBox(chosen)) {
    noteGlyphOffScale(chosen.step, `icons drawn from it off the ladder are rescaled instead`);
    return false;
  }
  return true;
}

/**
 * Draws one icon.
 *
 * The icon is an instance of a `Size=N` variant with the glyph swapped in and
 * painted. What else is done to land it on `opts.size` depends on what it is
 * (header of this section):
 *
 *   · A slot icon on a `Size` step (`fromVariant` given, `slotModeFor` agrees)
 *     is resized to its side and nothing else is scaled. `resize` moves the
 *     box, and the glyph inside — on SCALE constraints — follows it; the stroke
 *     is left exactly as the variant has it, and an explicit mode named for the
 *     side tells the instance which step's stroke it wears. The mode is written
 *     last, after the glyph swap, so nothing that follows can be what undoes it.
 *   · Any other icon is drawn from the nearest step. At that step's own side it
 *     needs nothing more. Off the ladder it is resized to its side and keeps the
 *     step's pinned mode when the stroke is the same across that side
 *     (`strokeHoldsAt`), and is otherwise `rescale`d (box, glyph and stroke
 *     together).
 */
export function makeIcon(name: string, lk: VarLookup, opts: IconOpts): InstanceNode {
  if (!ICONS[name]) throw new Error(unknownIconMessage(name));
  // Asked for BEFORE `createInstance` even though `swapGlyph` asks again: an
  // unknown name has to fail while there is nothing on the page to abandon.
  // Nothing here has an undo, and an instance created before a throw is debris
  // on whichever page the human happened to have open.
  requireGlyph(name);

  const { set, variants } = iconSetResolved();

  const side = dimVal(opts.size);
  const given = opts.fromVariant
    ? variants.find((v) => v.node === opts.fromVariant || v.node.id === opts.fromVariant!.id)
    : undefined;
  const chosen = given ?? nearestSizeVariantOf(set, side);
  const step = chosen.step;
  // Decided before anything is created, for the same reason `requireGlyph` is.
  const slotMode = given === undefined ? null : slotModeFor(given, side, variants);
  // A side the nearest step is not, for an icon that is no slot icon: resized to
  // its side when the stroke is the same around it, rescaled otherwise.
  const offLadderBySize =
    given === undefined && side !== step && strokeHoldsAt(chosen, side, variants);

  const instance = chosen.node.createInstance();
  // The variant's own `explicitVariableModes` come along with the instance, so
  // a variant drawn at its own step already wears that step's stroke.
  //
  // Through `swapGlyph` rather than `setProperties` directly: the glyph handle
  // is the run's, not this call's, and it can be stale by the time an entry
  // near the end of the run asks for it (header there). `Label` died on this
  // exact line, one statement after `createInstance` succeeded — which is what
  // left an orphan `Icon` beside an empty `icon` cell on `❖ Label`.
  //
  // Painted inside the swap, before the fit below: neither `rescale` nor
  // `resize` touches the paint, so the order changes nothing and this write
  // stays on the one path every other glyph write takes.
  swapGlyph(instance, name, glyphPaint(lk, opts));
  if (slotMode === null && !offLadderBySize && side !== step) {
    instance.rescale(side / step);
    // Reported only for a side the `Size` axis has no rung for. A slot icon on
    // a rung that was rescaled anyway has either been told so by `slotModeFor`
    // (the collection lacks the mode, the glyph is on CENTER) or the run has no
    // collection at all, which the prelude said once.
    const offLadder = !variants.some((v) => v.step === side);
    if (!opts.placeholder && !opts.statedOffLadder && offLadder) inexactIconSizes.push({ kind: 'rescaled', name, side, step });
  }
  // The box the slot was sized for, stated outright. Button and Chip slots
  // on the live canvas held a 24px glyph in an 18–20px cell — the instance
  // had kept its step's size — and a slot that measures one thing while its
  // glyph measures another is exactly the drift the slot exists to prevent.
  // For a size-only fit this IS the fit.
  if (Math.abs(instance.width - side) > kDrawnEpsilon || Math.abs(instance.height - side) > kDrawnEpsilon) {
    instance.resize(side, side);
  }
  // An off-ladder size-only fit writes no mode: the variant's own pin is the
  // stroke, and it is the stroke of every rung around this side (`strokeHoldsAt`).
  if (slotMode !== null) {
    instance.setExplicitVariableModeForCollection(slotMode.collection, slotMode.modeId);
  }
  if (slotMode !== null || offLadderBySize) {
    reportGlyphOffSide(instance, side, `Size=${step} drawn at ${side}`);
  }
  drawnIcons.set(instance, {
    side,
    mainId: chosen.node.id,
    mode: slotMode === null ? null : slotMode.name,
    bySize: slotMode !== null || offLadderBySize,
  });
  return instance;
}

/**
 * Says so when the glyph inside a size-fitted icon is not `side` wide.
 *
 * A size-only fit trusts the glyph to follow the box, and the constraint check
 * in `slotModeFor` reads the variant's own glyph, not what the instance ended
 * up with. This reads the result — a glyph that did not follow shows up here
 * as the number it kept, rather than as an icon that looks right at a glance
 * and spills out of its slot.
 */
function reportGlyphOffSide(instance: InstanceNode, side: number, what: string): void {
  const only = instance.children.length === 1 ? instance.children[0] : null;
  if (only === null || only.type !== 'INSTANCE') return;
  if (Math.abs(only.width - side) > kDrawnEpsilon) {
    noteSlotIcon(`${what}: the glyph is ${only.width} wide after the size-only fit, not ${side}`);
  }
}

/** The `Icon` set's `Size=N` variant with node id `id`, or null when `id` is
 *  not one: a remote library node, a bare glyph, or another set's member. */
export function iconVariantById(id: string): ComponentNode | null {
  if (!id) return null;
  const hit = iconSetResolved().variants.find((v) => v.node.id === id);
  return hit ? hit.node : null;
}

/** The step up to which a glyph is taken to sit on CENTER constraints when the
 *  variant does not state its constraints (they are read off the variant
 *  whenever it does). */
const kCenterGlyphMaxStep = 24;

/** The scale factors closer than this to 1 are 1: float noise on a stored factor. */
const kScaleEpsilon = 0.002;

/** Drawn and stated sizes closer than this agree (px). */
const kDrawnEpsilon = 0.01;

/** The constraints of the glyph in `variant`, or null when it does not state any. */
function glyphConstraintsOf(
  variant: { node: ComponentNode },
): { horizontal: string; vertical: string } | null {
  const glyph = variant.node.children.length === 1 ? variant.node.children[0] : null;
  const cons = glyph !== null && 'constraints' in glyph ? glyph.constraints : null;
  if (cons && typeof cons.horizontal === 'string' && typeof cons.vertical === 'string') {
    return { horizontal: cons.horizontal, vertical: cons.vertical };
  }
  return null;
}

/** Whether the glyph in `variant` keeps its own size when the box around it
 *  changes, i.e. sits on CENTER constraints and not SCALE. */
function glyphKeepsOwnSize(variant: { step: number; node: ComponentNode }): boolean {
  const cons = glyphConstraintsOf(variant);
  if (cons !== null) return cons.horizontal !== 'SCALE' && cons.vertical !== 'SCALE';
  return variant.step <= kCenterGlyphMaxStep;
}

/** Whether the glyph in `variant` follows the box around it: SCALE on both axes.
 *  A variant that states no constraints is taken as the library states them —
 *  SCALE — because the check exists to catch a library that says otherwise, and
 *  a node that cannot say is not evidence of that. */
function glyphFollowsBox(variant: { node: ComponentNode }): boolean {
  const cons = glyphConstraintsOf(variant);
  return cons === null || (cons.horizontal === 'SCALE' && cons.vertical === 'SCALE');
}

/** What `slotSwapVariantFor` decided: the variant to swap to, the size the
 *  caller stated, the size that variant draws at on this slot, and whether the
 *  two agree. */
export interface SlotSwapChoice {
  id: string;
  wanted: number;
  drawn: number;
  exact: boolean;
}

/**
 * The `Icon` variant to swap a composed child's slot to, so that the glyph
 * draws at the step the caller NAMED even though the slot carries a scale.
 *
 * A child's slot icon that `makeIcon` could not fit by size alone (a side off
 * the `Size` ladder, or a run or library that cannot take the stroke mode —
 * `slotModeFor`) is drawn from the slot property's default and rescaled to the
 * slot's side (`IconOpts.fromVariant`), because the first bind of the property
 * puts the default back in place of anything else. The rescale is stored on the
 * bound node as its `scaleFactor`, and the node keeps it when an INSTANCE of
 * the child swaps the property to another variant. So a glyph that sits on
 * CENTER constraints draws at its own step TIMES that factor: `Size=16` in a
 * slot scaled to 16/24 draws at 10.667, in a box that is still 16 (measured on
 * the canvas, #5247). A slot icon fitted by size alone stores no scale (its
 * factor is 1), so there is nothing to cancel and the variant the caller named
 * is kept.
 *
 * Nothing on the instance can undo it. Measured on the swapped node inside an
 * instance: `rescale` throws ("cannot be overridden in an instance: size"),
 * `scaleFactor = 1` throws ("symbol-data"), constraints and the glyph's own
 * size are refused or ignored, and `resetOverrides` / `swapComponent` leave the
 * factor where it is. The one knob left is WHICH variant is swapped to.
 *
 * So the variant is chosen to cancel the factor: the CENTER step whose step
 * times `scale` lands on the stated step. When the slot already draws at the
 * stated step (the caller names what the slot was drawn at, the usual case),
 * that is the property's own default again, which is exactly what the child's
 * slot shows with nothing swapped. A SCALE variant ignores the factor (its
 * glyph follows the box), and `scale` 1 has nothing to cancel, so both keep
 * the variant the caller named.
 *
 * When no step cancels the factor (a slot scaled for another size than the
 * caller states) the nearest one is taken and `exact` is false, so the caller
 * can say so instead of drawing a wrong size without a word.
 *
 * Null when `iconId` is not an `Icon` `Size=N` variant of this document.
 */
export function slotSwapVariantFor(iconId: string, scale: number): SlotSwapChoice | null {
  const { variants } = iconSetResolved();
  const named = variants.find((v) => v.node.id === iconId);
  if (!named) return null;
  const wanted = named.step;
  const keep: SlotSwapChoice = { id: iconId, wanted, drawn: wanted, exact: true };
  if (!Number.isFinite(scale) || scale <= 0 || Math.abs(scale - 1) <= kScaleEpsilon) return keep;
  if (!glyphKeepsOwnSize(named)) return keep;
  let best = named;
  let bestError = Math.abs(named.step * scale - wanted);
  for (const v of variants) {
    if (!glyphKeepsOwnSize(v)) continue;
    const error = Math.abs(v.step * scale - wanted);
    if (error < bestError - 1e-9) {
      best = v;
      bestError = error;
    }
  }
  return {
    id: best.node.id,
    wanted,
    drawn: best.step * scale,
    exact: bestError <= kDrawnEpsilon,
  };
}

/** Records a slot swap that could not land on the stated size, for the entry's
 *  log (see `drainInexactIconSizes`). */
export function recordInexactSlotSwap(name: string, choice: SlotSwapChoice, scale: number): void {
  inexactIconSizes.push({
    kind: 'slot-swap',
    name,
    wanted: choice.wanted,
    drawn: choice.drawn,
    scale,
  });
}

/**
 * Puts the stroke mode a composed child's slot icon wears on the step its parent
 * states, once the parent's swap has landed.
 *
 * A child that fits its slot icon by size alone says which stroke it wants by an
 * explicit mode named for ITS slot's side (`slotModeFor`). An instance of the
 * child that swaps the slot to another step (`setSlotIcon`: the parent states
 * the step its own style gives the glyph, which need not be the step the
 * child's slot was drawn at) keeps that mode through the
 * swap — the same persistence that carries it through a bind (measured) — so a
 * 20 glyph would wear the 24 stroke: 1.5 where the rule gives 1.25, while Flutter
 * draws the chevron at the rule. The one place the mode is written is `makeIcon`,
 * which knows the child's side and not the parent's, so the parent's step is
 * written here.
 *
 * Only when the swap stores no scale. A child that rescaled its slot icon wears
 * no mode of its own (the variant's pin supplies the stroke), and the variant the
 * swap lands on is chosen to cancel the stored factor (`slotSwapVariantFor`) —
 * there is nothing to re-point, and a mode written there would multiply the
 * stroke a second time.
 *
 * Written whether or not the node reports a mode of its own. When it wears none
 * it takes the pin of the variant it was swapped to, which is this very step, so
 * the write only says it outright; when the node cannot report the modes it
 * inherited from the child's main component, skipping on "no mode seen" would
 * leave exactly the mismatch this exists for.
 *
 * Figma may refuse a mode override on an instance nested inside an instance. That
 * is said where a person can act on it (a slot-icon note) and not swallowed: the
 * icon then draws at the child's stroke, which nothing else on the canvas reveals.
 */
export function alignSlotIconMode(target: InstanceNode, wantedStep: number, scale: number): void {
  const index = iconModeIndex;
  if (index === null) return;
  if (!Number.isFinite(scale) || Math.abs(scale - 1) > kScaleEpsilon) return;
  const name = String(wantedStep);
  const modeId = index.modeIdByName.get(name);
  if (modeId === undefined) {
    noteSlotIcon(
      `no mode "${name}" in the Icon collection — a slot icon swapped to Size=${name} keeps the ` +
        'stroke mode of the step its child drew it at',
    );
    return;
  }
  const worn = (target.explicitVariableModes as { [collectionId: string]: string } | undefined)?.[
    index.collectionId
  ];
  if (worn === modeId) return;
  try {
    target.setExplicitVariableModeForCollection(index.collection, modeId);
  } catch (err) {
    noteSlotIcon(
      `a slot icon swapped to Size=${name} keeps the stroke mode of the step its child drew it at — ` +
        `Figma refused the mode "${name}" on the composed icon (${String(err)})`,
    );
  }
}

/**
 * Puts a bound icon back at the side `makeIcon` drew it at, once its
 * INSTANCE_SWAP bind has landed.
 *
 * Needed only when the bind changed the main, i.e. when the icon was not
 * drawn from the property's default variant (`IconOpts.fromVariant`). That
 * happens when the default is not a local `Icon` variant (a remote library
 * node, a bare glyph) and so cannot be instanced here, or when the builder
 * moved the default after the icon was drawn. The bind then draws the default:
 * on a FIXED box both box and glyph, on a FILL box the glyph alone (measured,
 * #5247). How the side is put back depends on how the icon was fitted:
 *
 *   · A slot icon fitted by size alone (it carries a stroke mode) gets its SIZE
 *     back and nothing else: `resize` on the axes that are its own. The mode
 *     survives the bind (measured), the stroke is whatever the mode says, and a
 *     `rescale` here would multiply that stroke a second time. The glyph follows
 *     the box (SCALE), so the box is all there is to put back; a FILL axis is
 *     left to its parent and written FILL again, the extent it was resized to
 *     being the one it already has.
 *   · Any other icon is rescaled by `side / glyph`, which brings box and glyph
 *     back together and scales the stroke by the same factor. The glyph sits on
 *     CENTER constraints in a library that has not moved to SCALE, so it keeps
 *     the side the rescale gave it while a FILL box fills back out. An icon
 *     fitted by size alone off the ladder is in this group too: it keeps its
 *     variant's own pinned mode and writes none, and what a bind leaves in place
 *     of the main is not that pin, so there is no mode here for a size-only
 *     settle to rely on.
 *
 * `rescale` and `resize` both turn a FILL axis FIXED (measured for `rescale`),
 * so a FILL axis is written again afterwards.
 *
 * This fixes the picture but not the fingerprint: the member's main still
 * differs from the one it was drawn with while loose.
 */
export function settleIconAfterBind(node: InstanceNode, side: number): void {
  if (node.removed) return;
  // An `Icon` `Size=N` variant holds its glyph as ONE nested instance, and on a
  // FILL box that instance is the only part still at the default's size. A
  // default that is a bare glyph component has its vectors as direct children
  // instead, and the instance box itself is the glyph's extent.
  const only = node.children.length === 1 ? node.children[0] : null;
  const glyph = only !== null && only.type === 'INSTANCE' ? only.width : node.width;
  if (!(glyph > 0) || Math.abs(glyph - side) <= kDrawnEpsilon) return;
  const fillH = node.layoutSizingHorizontal === 'FILL';
  const fillV = node.layoutSizingVertical === 'FILL';
  const drawn = drawnIcons.get(node);
  if (drawn !== undefined && drawn.mode !== null) {
    node.resize(fillH ? node.width : side, fillV ? node.height : side);
  } else {
    node.rescale(side / glyph);
  }
  if (fillH) node.layoutSizingHorizontal = 'FILL';
  if (fillV) node.layoutSizingVertical = 'FILL';
  if (drawn !== undefined && drawn.mode !== null) {
    reportGlyphOffSide(node, side, `slot icon of ${side} after its bind`);
  }
}
