/// <reference types="@figma/plugin-typings" />

import contentColorsJson from './data/content-colors.json';
import { solid } from './paint';
import { VarLookup, withoutOrderingPrefix } from './variables';

// The colour a glyph takes from its slot — `Semantic/ Content` and
// `Semantic/ Content Status`.
//
// A glyph's stroke is bound to ONE variable, `content/current`, and the slot
// frame it sits in pins the mode that says which tone that is. A mode is
// inherited by everything under the frame, so the colour survives what the old
// per-variant paint did not: a glyph swapped in from the Properties panel keeps
// whatever the library painted it, and the painted override was lost with it.
// The frame is the place a pin outlives both an icon swapped in and an icon
// deleted and added again (measured, #6008) — which is why the pin goes on the
// parent of the icon instance and not on the instance.
//
// The vocabulary — which tokens are modes, which collection each mode is in —
// is `content-colors.json`, written by `export_figma_tokens.dart` from the same
// list that makes the collections. A mode is named for the colour slot it
// aliases, so this file turns a token into a mode by NAME and states no mode of
// its own.
//
// Painting and pinning are two steps because they happen at two times. The
// stroke is bound where the glyph is drawn (`glyphPaint`, `repaintGlyph`), when
// the icon has no parent yet; the pin needs the parent, so each glyph is noted
// as it is painted and `flushContentModes` pins them once the builder is done —
// the same shape as `flushTintLayers`, called at the same place.

interface ContentColorsDoc {
  colorCollection: string;
  content: { collection: string; variable: string; statusMode: string; modes: string[] };
  status: { collection: string; variable: string; modes: string[] };
}

/** What the export says the content collections are. */
export const CONTENT_COLORS = contentColorsJson as ContentColorsDoc;

/** What a slot pins for one tone of content. */
export interface ContentTone {
  /** The colour token the glyph used to be painted with — the slot name. */
  token: string;
  /** The mode of `Semantic/ Content` to pin. */
  mode: string;
  /** The mode of `Semantic/ Content Status` to pin beside it, for a status tone. */
  statusMode: string | null;
}

const kNeutralModes: ReadonlySet<string> = new Set(
  CONTENT_COLORS.content.modes.filter((m) => m !== CONTENT_COLORS.content.statusMode),
);
const kStatusModes: ReadonlySet<string> = new Set(CONTENT_COLORS.status.modes);

/**
 * The tone a colour token is, or null when the token is not a tone of content
 * (a border, a surface, a fill) — such a glyph keeps its direct paint.
 */
export function contentToneOf(token: string): ContentTone | null {
  if (kNeutralModes.has(token)) return { token, mode: token, statusMode: null };
  if (kStatusModes.has(token)) {
    return { token, mode: CONTENT_COLORS.content.statusMode, statusMode: token };
  }
  return null;
}

/** The slot name a colour variable is — `color/on-primary` → `on-primary`. */
export function tokenOfColorVariable(variable: Variable | null | undefined): string | null {
  const name = variable?.name;
  if (typeof name !== 'string' || !name.startsWith('color/')) return null;
  const token = name.slice('color/'.length);
  return token === '' || token.indexOf('/') >= 0 ? null : token;
}

// ─── The collections, resolved by the prelude ────────────────────────────────

/** One collection and its modes by name. */
export interface ContentModeSet {
  collectionId: string;
  /** The object `setExplicitVariableModeForCollection` takes — the id form is
   *  refused under `documentAccess: "dynamic-page"`. */
  collection: VariableCollection;
  modeIdByName: ReadonlyMap<string, string>;
}

/** What the prelude resolved. */
export interface ContentColorIndex {
  /** `content/current` — what a glyph's stroke is bound to. */
  current: Variable;
  content: ContentModeSet;
  status: ContentModeSet;
}

let contentIndex: ContentColorIndex | null = null;

/** Installs what the prelude resolved. Null drops it: glyphs are then painted
 *  directly, as before, and the run says so. */
export function installContentIndex(index: ContentColorIndex | null): void {
  contentIndex = index;
}

/** Drops the index — for a command that builds without the prelude and so must
 *  not inherit collection objects an earlier run resolved. */
export function clearContentIndex(): void {
  contentIndex = null;
}

/** What is installed right now, or null. */
export function heldContentIndex(): ContentColorIndex | null {
  return contentIndex;
}

function modeSetOf(collection: VariableCollection): ContentModeSet {
  const modeIdByName = new Map<string, string>();
  for (const mode of collection.modes) {
    if (!modeIdByName.has(mode.name)) modeIdByName.set(mode.name, mode.modeId);
  }
  return { collectionId: collection.id, collection, modeIdByName };
}

/**
 * The prelude's whole content step: drops what an earlier run installed,
 * resolves the two collections and the variable, installs them, and says what
 * happened.
 *
 * A function and not inline in `generate.ts`, so the harness runs THE step the
 * plugin runs. Never throws: a file Import has not reached has no content
 * collections, and that is a warning — the glyphs are painted directly, as
 * before, and the entries drawn that way are not stamped current (the next run,
 * after Import, draws them again).
 */
export function prepareContentColors(
  collections: readonly VariableCollection[],
  lk: VarLookup,
  log: string[],
): void {
  installContentIndex(null);
  const named = (name: string): VariableCollection | undefined =>
    collections.find((c) => withoutOrderingPrefix(c.name) === name);
  const content = named(CONTENT_COLORS.content.collection);
  const status = named(CONTENT_COLORS.status.collection);
  const missing: string[] = [];
  if (content === undefined) missing.push(`컬렉션 "${CONTENT_COLORS.content.collection}"`);
  if (status === undefined) missing.push(`컬렉션 "${CONTENT_COLORS.status.collection}"`);
  const current = lk.tryGet(CONTENT_COLORS.content.collection, CONTENT_COLORS.content.variable);
  if (current === undefined) missing.push(`변수 ${CONTENT_COLORS.content.variable}`);
  if (content !== undefined) {
    const have = new Set(content.modes.map((m) => m.name));
    for (const mode of CONTENT_COLORS.content.modes) {
      if (!have.has(mode)) missing.push(`"${content.name}" 모드 ${mode}`);
    }
  }
  if (status !== undefined) {
    const have = new Set(status.modes.map((m) => m.name));
    for (const mode of CONTENT_COLORS.status.modes) {
      if (!have.has(mode)) missing.push(`"${status.name}" 모드 ${mode}`);
    }
  }
  if (missing.length > 0 || content === undefined || status === undefined || current === undefined) {
    log.push(
      `⚠ Icon: 콘텐츠 색을 찾지 못해 글리프를 슬롯 모드 없이 직접 칠한다 — ${missing.join(', ')} 없음. ` +
        '토큰을 다시 Import 한 뒤 Generate 하면 슬롯 프레임의 모드로 칠한다.',
    );
    return;
  }
  installContentIndex({ current, content: modeSetOf(content), status: modeSetOf(status) });
  log.push(
    `Icon: 콘텐츠 색 — "${content.name}" ${content.modes.length}개 모드 · "${status.name}" ` +
      `${status.modes.length}개 모드, 글리프는 슬롯 프레임의 모드로 칠한다.`,
  );
}

/**
 * Re-reads the collection objects under the held ids, once per entry.
 *
 * The same reason the glyph handles are re-imported per entry: an object taken in
 * the prelude has to survive an hour of other entries, and what the run holds
 * across that is an id. Keeps the held object when the lookup answers nothing — a
 * failed refresh must not be what stops the run.
 */
export async function refreshContentCollections(
  getCollection: (id: string) => Promise<VariableCollection | null>,
): Promise<void> {
  const held = contentIndex;
  if (held === null) return;
  const [content, status] = await Promise.all([
    getCollection(held.content.collectionId),
    getCollection(held.status.collectionId),
  ]);
  if (contentIndex !== held) return;
  contentIndex = {
    current: held.current,
    content: content === null ? held.content : { ...held.content, collection: content },
    status: status === null ? held.status : { ...held.status, collection: status },
  };
}

// ─── What the build leaves behind ────────────────────────────────────────────

/** A painted glyph waiting for its slot to pin a mode. */
interface PendingGlyph {
  tone: ContentTone;
  /** Gives the glyph its direct colour back — for a pin Figma refused. */
  paintDirect: () => void;
}

// Keyed by the node, so a glyph painted twice (drawn, then re-stated by a swap)
// pins the colour it ended with.
const pending = new Map<SceneNode, PendingGlyph>();

// What was painted DIRECTLY and why, counted — drained per entry beside the slot
// notes, so a glyph that keeps its own colour is a line in the log and not a
// surprise on the canvas. Keyed by the reason (`on-secondary`, `literal`).
const directGlyphs = new Map<string, number>();
let withoutCollection = false;

/**
 * The paint a glyph gets from the slot — `content/current`, bound — and the tone
 * its slot is to pin; or null when the glyph is to be painted directly (there is
 * no collection, or the token is not a tone of content).
 *
 * A token that has a tone but finds no collection flags the entry
 * (`drainContentWithoutCollection`): it drew what a collection would have
 * replaced, and a stamp would keep it after the next Import.
 */
export function contentPaintOf(
  colorVar: Variable,
): { paint: SolidPaint; tone: ContentTone } | null {
  const token = tokenOfColorVariable(colorVar);
  const tone = token === null ? null : contentToneOf(token);
  if (tone === null) {
    noteDirectGlyph(token ?? 'literal');
    return null;
  }
  const index = contentIndex;
  if (index === null) {
    withoutCollection = true;
    return null;
  }
  return { paint: solid(index.current, 1), tone };
}

/** A glyph painted with a literal or a token that is no tone of content. */
export function noteDirectGlyph(reason: string): void {
  directGlyphs.set(reason, (directGlyphs.get(reason) ?? 0) + 1);
}

/** Notes a glyph for `flushContentModes`. */
export function noteContentGlyph(root: SceneNode, tone: ContentTone, paintDirect: () => void): void {
  pending.set(root, { tone, paintDirect });
}

/** The glyphs painted directly since the last drain, as `reason ×count`, and clears them. */
export function drainDirectGlyphs(): string[] {
  const out = Array.from(directGlyphs, ([reason, n]) => `${reason} ×${n}`);
  directGlyphs.clear();
  return out;
}

/** Whether a glyph was drawn directly because the run holds no collection since
 *  the last drain, and clears it — see `contentPaintOf`. */
export function drainContentWithoutCollection(): boolean {
  const out = withoutCollection;
  withoutCollection = false;
  return out;
}

/** Forgets glyphs noted by a build that threw before its flush. */
export function dropPendingContentGlyphs(): void {
  pending.clear();
}

// ─── Pinning ─────────────────────────────────────────────────────────────────

/** One glyph's pin, for the report. */
export interface ContentPin {
  /** The glyph root — the icon instance, or the holder a composed glyph sits in. */
  glyph: SceneNode;
  /** The node that carries the modes: the slot frame, or the glyph itself. */
  pinnedOn: SceneNode;
  tone: ContentTone;
}

/** What `flushContentModes` did. */
export interface ContentFlushReport {
  /** Glyphs whose colour was pinned. */
  glyphs: number;
  /** Nodes that were written (a slot shared by several glyphs counts once). */
  writes: number;
  /** Glyphs pinned on their slot frame, the rule. */
  onSlot: number;
  /** Glyphs pinned on themselves: no slot frame to pin (detached), or the slot
   *  holds glyphs of different tones. */
  onGlyph: number;
  /** Glyphs given their direct colour back because Figma refused the pin. */
  refused: string[];
  /** Every pin, when asked for. */
  pins: ContentPin[];
}

type ModeCarrier = SceneNode & {
  explicitVariableModes?: { [collectionId: string]: string };
  setExplicitVariableModeForCollection(collection: VariableCollection, modeId: string): void;
};

function carries(node: BaseNode | null): node is ModeCarrier {
  return (
    node !== null &&
    node.type !== 'PAGE' &&
    node.type !== 'DOCUMENT' &&
    typeof (node as { setExplicitVariableModeForCollection?: unknown })
      .setExplicitVariableModeForCollection === 'function'
  );
}

/** The slot frame a glyph is pinned on: a holder frame is its own slot, an icon
 *  instance takes its parent. Null when there is no frame to carry the modes. */
function slotOf(root: SceneNode): SceneNode | null {
  if (root.type !== 'INSTANCE') return root;
  const parent = root.parent as BaseNode | null;
  return carries(parent) ? parent : null;
}

const toneKey = (t: ContentTone): string => `${t.mode}|${t.statusMode ?? ''}`;

/** Writes one tone's modes onto `target`; a mode it already wears is not written again. */
function pin(index: ContentColorIndex, target: ModeCarrier, tone: ContentTone): boolean {
  const worn = target.explicitVariableModes ?? {};
  let wrote = false;
  const write = (set: ContentModeSet, name: string): void => {
    const modeId = set.modeIdByName.get(name);
    if (modeId === undefined) throw new Error(`no mode "${name}" in the collection ${set.collectionId}`);
    if (worn[set.collectionId] === modeId) return;
    target.setExplicitVariableModeForCollection(set.collection, modeId);
    wrote = true;
  };
  write(index.content, tone.mode);
  if (tone.statusMode !== null) write(index.status, tone.statusMode);
  return wrote;
}

/**
 * Pins the tone of every glyph painted since the last flush onto its slot frame.
 *
 * Called once per entry, after `build()` has returned and before anything reads
 * the tree (the redrawn nodes are settled against it, the fingerprint walks it):
 * a glyph's parent is only known then. Walks the glyphs it was told about and
 * nothing else — the build's tree is not searched.
 *
 * A slot that holds glyphs of more than one tone cannot carry both: it takes the
 * tone most of its glyphs have (a tie goes to the glyph that sits first in the
 * frame), and each glyph of another tone pins its own instance — a pin that
 * outlives a swap but not a delete, which is what the slot frame is for. The
 * count of those says how many there were.
 * A pin Figma refuses is not left to read as the first mode: the glyph is given
 * its direct colour back and the entry says so.
 */
export function flushContentModes(options: { pins?: boolean } = {}): ContentFlushReport {
  const report: ContentFlushReport = { glyphs: 0, writes: 0, onSlot: 0, onGlyph: 0, refused: [], pins: [] };
  const batch = Array.from(pending);
  pending.clear();
  const index = contentIndex;
  if (index === null || batch.length === 0) return report;

  const bySlot = new Map<SceneNode, [SceneNode, PendingGlyph][]>();
  const alone: [SceneNode, PendingGlyph][] = [];
  for (const entry of batch) {
    if (entry[0].removed) continue;
    const slot = slotOf(entry[0]);
    if (slot === null) {
      alone.push(entry);
      continue;
    }
    const held = bySlot.get(slot);
    if (held === undefined) bySlot.set(slot, [entry]);
    else held.push(entry);
  }
  const placements: { target: SceneNode; glyphs: [SceneNode, PendingGlyph][]; slot: boolean }[] = [];
  bySlot.forEach((glyphs, slot) => {
    // The tone most of the slot's glyphs have is the slot's; where the count ties,
    // the glyph that sits first in the frame (a leading icon before a trailing one)
    // decides. A glyph of another tone pins itself — the slot cannot carry two.
    const tones = new Map<string, { glyphs: [SceneNode, PendingGlyph][]; first: number }>();
    const order = 'children' in slot ? (slot as unknown as ChildrenMixin).children : [];
    for (const g of glyphs) {
      const key = toneKey(g[1].tone);
      const at = order.indexOf(g[0] as SceneNode);
      const held = tones.get(key);
      if (held === undefined) tones.set(key, { glyphs: [g], first: at < 0 ? Number.MAX_SAFE_INTEGER : at });
      else {
        held.glyphs.push(g);
        if (at >= 0 && at < held.first) held.first = at;
      }
    }
    let winner: { glyphs: [SceneNode, PendingGlyph][]; first: number } | null = null;
    tones.forEach((group) => {
      if (
        winner === null ||
        group.glyphs.length > winner.glyphs.length ||
        (group.glyphs.length === winner.glyphs.length && group.first < winner.first)
      ) {
        winner = group;
      }
    });
    tones.forEach((group) => {
      if (group === winner) placements.push({ target: slot, glyphs: group.glyphs, slot: true });
      else for (const g of group.glyphs) placements.push({ target: g[0], glyphs: [g], slot: false });
    });
  });
  for (const g of alone) placements.push({ target: g[0], glyphs: [g], slot: false });

  for (const { target, glyphs, slot } of placements) {
    const tone = glyphs[0][1].tone;
    try {
      if (!carries(target)) throw new Error(`a ${(target as BaseNode).type} takes no variable mode`);
      if (pin(index, target, tone)) report.writes++;
    } catch (err) {
      for (const [root, entry] of glyphs) {
        report.refused.push(`${root.name} (${tone.token}: ${String(err)})`);
        entry.paintDirect();
      }
      continue;
    }
    for (const [root] of glyphs) {
      report.glyphs++;
      if (slot) report.onSlot++;
      else report.onGlyph++;
      if (options.pins === true) report.pins.push({ glyph: root, pinnedOn: target, tone });
    }
  }
  return report;
}

/** The lines `generate.ts` logs for one entry's flush — empty when nothing is off. */
export function contentFlushLines(entry: string, report: ContentFlushReport, direct: string[]): string[] {
  const lines: string[] = [];
  if (report.refused.length > 0) {
    lines.push(
      `⚠ ${entry}: 슬롯 모드를 Figma 가 거절해 직접 칠했다 — ${report.refused.join('; ')}.`,
    );
  }
  if (direct.length > 0) {
    // Not a warning: a colour that is no tone of content is painted as Core states
    // it. The harness holds the list of which entries may do that
    // (`kDirectGlyphColours`), so one that is not on it fails there.
    lines.push(
      `${entry}: 콘텐츠 모드가 아닌 색의 글리프는 Core 가 정한 색 그대로 직접 칠했다 — ${direct.join(', ')}.`,
    );
  }
  if (report.onGlyph > 0) {
    lines.push(
      `⚠ ${entry}: 슬롯 프레임 하나에 색이 다른 글리프가 함께 있거나 슬롯 프레임이 없어 ` +
        `${report.onGlyph}개 글리프는 아이콘 인스턴스에 모드를 지정했다 (아이콘을 지우고 새로 넣으면 풀린다).`,
    );
  }
  return lines;
}
